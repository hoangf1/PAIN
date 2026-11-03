"""Broadband source: Goody turbulent-boundary-layer wall-pressure spectrum (plan A.4)."""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .atmosphere import Air
from .frequencies import band_edges

P_REF = 20e-6


@dataclass(frozen=True)
class BoundaryLayer:
    q: float
    Re_x: float
    delta: float
    Cf: float
    tau_w: float
    u_tau: float
    Ue: float
    R_T: float


def boundary_layer(atm: Air, V: float, x_n: float) -> BoundaryLayer:
    """Flat-plate turbulent boundary layer at distance x_n from the nose."""
    if V <= 0 or x_n <= 0:
        raise ValueError("TBL needs V > 0 and nose-to-station distance > 0")
    q = 0.5 * atm.rho * V * V
    Re = V * x_n / atm.nu
    delta = 0.37 * x_n * Re ** -0.2
    Cf = 0.0592 * Re ** -0.2
    tau_w = Cf * q
    u_tau = np.sqrt(tau_w / atm.rho)
    Ue = V
    R_T = (delta / Ue) / (atm.nu / u_tau ** 2)
    return BoundaryLayer(q, Re, delta, Cf, tau_w, u_tau, Ue, R_T)


def goody_phi(omega, bl: BoundaryLayer) -> np.ndarray:
    """One-sided wall-pressure spectrum per unit radian frequency, Pa^2 s/rad."""
    wt = np.asarray(omega, dtype=float) * bl.delta / bl.Ue
    shape = 3.0 * wt ** 2 / ((wt ** 0.75 + 0.5) ** 3.7 + (1.1 * bl.R_T ** -0.57 * wt) ** 7)
    return shape * bl.tau_w ** 2 * bl.delta / bl.Ue


def wall_band_pressure2(centers, bl: BoundaryLayer, n_int: int = 64) -> np.ndarray:
    """Band mean-square wall pressure p^2 = int Phi(w) 2 pi df, Pa^2."""
    lo, hi = band_edges(np.asarray(centers, dtype=float))
    out = np.empty(lo.shape)
    for i, (a, b) in enumerate(zip(lo, hi)):
        f = np.geomspace(a, b, n_int)
        out[i] = np.trapezoid(goody_phi(2.0 * np.pi * f, bl) * 2.0 * np.pi, f)
    return out
