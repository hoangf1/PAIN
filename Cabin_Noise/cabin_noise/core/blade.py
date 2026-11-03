"""Optional blade-geometry source: blade-element momentum loads on radial strips, each strip
a compact rotating force (Farassat compact loading, the same moving-dipole formula as
source_tonal), summed coherently.

Published pieces, no fitted constants:
- Section lift: thin-airfoil theory, cl = 2 pi (alpha - alpha0) / sqrt(1 - M^2) (Prandtl-Glauert),
  alpha0 = -cl_design / (2 pi) for the NACA a = 1.0 mean line (Abbott & von Doenhoff,
  Theory of Wing Sections), limited to +-clmax; constant profile drag cd0.
- Loads: Glauert blade-element momentum, axial induction only (swirl neglected), Prandtl tip
  loss F = (2/pi) acos(exp(-B (R - r) / (2 r sin phi))); per station the induced velocity v
  solves  B 1/2 rho W^2 c (cl cos phi - cd sin phi) = 4 pi rho r F (V + v) v  by bisection.
- Acoustics: strips at radius r_i with thrust T_i and torque Q_i (all blades) through
  rotor_harmonics, phasors added (all strips on the same blade azimuth, no sweep).

Optionally the strip loads are scaled so they integrate to a given thrust and torque (for
example measured performance, or the mission's eta_p P / V and P / Omega); then only the
radial shape comes from the blade element model.
"""
from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

from .source_tonal import rotor_harmonics


@dataclass
class BladeGeometry:
    r_over_R: list = field(default_factory=list)
    c_over_R: list = field(default_factory=list)
    beta_deg: list = field(default_factory=list)     # section pitch of the blade form
    cl_design: list = field(default_factory=list)    # section design lift (sets alpha0)
    beta_set_075: float | None = None                # pitch at 0.75 R; None = blade form as is
    hub_r_over_R: float = 0.2
    clmax: float = 1.0
    cd0: float = 0.01
    n_strips: int = 20

    def stations(self, R: float):
        """Strip mid radii (m), widths (m), chord (m), pitch (rad), alpha0 (rad)."""
        rr = np.asarray(self.r_over_R, dtype=float)
        if rr.size < 2:
            raise ValueError("blade geometry needs at least two stations")
        lo = max(self.hub_r_over_R, rr.min())
        edges = np.linspace(lo, min(1.0, rr.max()), self.n_strips + 1)
        x = 0.5 * (edges[1:] + edges[:-1])
        beta = np.interp(x, rr, self.beta_deg)
        if self.beta_set_075 is not None:
            beta = beta - np.interp(0.75, rr, self.beta_deg) + self.beta_set_075
        cld = np.interp(x, rr, self.cl_design) if len(self.cl_design) else np.zeros_like(x)
        return (x * R, np.diff(edges) * R, np.interp(x, rr, self.c_over_R) * R, np.radians(beta),
                -cld / (2.0 * np.pi))


def _cl_cd(alpha, alpha0, mach, g: BladeGeometry):
    pg = 1.0 / np.sqrt(1.0 - min(mach, 0.95) ** 2)
    cl = np.clip(2.0 * np.pi * (alpha - alpha0) * pg, -g.clmax, g.clmax)
    return cl, g.cd0


def strip_loads(g: BladeGeometry, *, blades: int, R: float, omega: float, V: float, rho: float, c: float):
    """Per-strip radius r (m), thrust dT and torque dQ (N, N m; all blades) from BEMT."""
    r, dr, chord, theta, a0 = g.stations(R)
    dT, dQ = np.zeros_like(r), np.zeros_like(r)
    for i in range(r.size):
        Vt = omega * r[i]

        def parts(v):
            phi = np.arctan2(V + v, Vt)
            W2 = Vt ** 2 + (V + v) ** 2
            cl, cd = _cl_cd(theta[i] - phi, a0[i], np.sqrt(W2) / c, g)
            sphi = max(abs(np.sin(phi)), 1e-6)
            F = 2.0 / np.pi * np.arccos(min(1.0, np.exp(-blades * (R - r[i]) / (2.0 * r[i] * sphi))))
            q = 0.5 * rho * W2 * chord[i] * blades
            elem_T = q * (cl * np.cos(phi) - cd * np.sin(phi))
            elem_Q = q * (cl * np.sin(phi) + cd * np.cos(phi)) * r[i]
            mom_T = 4.0 * np.pi * rho * r[i] * max(F, 1e-6) * (V + v) * v
            return elem_T - mom_T, elem_T, elem_Q

        lo, hi = 0.0, max(Vt * np.tan(min(theta[i] - a0[i], 1.4)) - V, 0.0)
        if parts(lo)[0] <= 0.0 or hi <= 0.0:
            v = 0.0
        else:
            for _ in range(80):
                mid = 0.5 * (lo + hi)
                if parts(mid)[0] > 0.0:
                    lo = mid
                else:
                    hi = mid
            v = 0.5 * (lo + hi)
        _, eT, eQ = parts(v)
        dT[i], dQ[i] = eT * dr[i], eQ * dr[i]
    return r, dT, dQ


def scaled_strip_loads(g: BladeGeometry, *, thrust: float | None = None, torque: float | None = None, **kw):
    r, dT, dQ = strip_loads(g, **kw)
    if thrust is not None:
        if dT.sum() <= 0:
            raise ValueError("blade element model gives no thrust to scale")
        dT = dT * thrust / dT.sum()
    if torque is not None:
        if dQ.sum() <= 0:
            raise ValueError("blade element model gives no torque to scale")
        dQ = dQ * torque / dQ.sum()
    return r, dT, dQ


def strip_harmonics(obs, r, dT, dQ, *, blades: int, omega: float, V: float, c: float, n_harmonics: int,
                    rotation: int = 1, n_tau: int = 2048) -> np.ndarray:
    """Complex rms phasors summed over the radial strips."""
    P = np.zeros(n_harmonics, dtype=complex)
    for ri, Ti, Qi in zip(r, dT, dQ):
        P += rotor_harmonics(obs, blades=blades, R_e=ri, omega=omega, V=V, c=c, thrust=Ti, torque=Qi,
                             n_harmonics=n_harmonics, rotation=rotation, n_tau=n_tau)
    return P
