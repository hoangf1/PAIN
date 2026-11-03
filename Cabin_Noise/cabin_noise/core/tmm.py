"""Plane-wave transfer-matrix sidewall transmission (plan A.5), e^{+j w t} convention.

Layers are ordered exterior -> cabin (skin first). The same fluid (cabin air) is used on
both faces: for a mass-controlled wall the transmitted power depends on the blocked
pressure, so tau computed with cabin rho*c times p_inc^2/(rho*c)_cabin gives the
transmitted power directly (see pipeline).
"""
from __future__ import annotations

import numpy as np

from .atmosphere import Air
from .frequencies import log_subfrequencies
from .materials import AirGap, Panel, PorousLayer, PorousTable
from .porous import delany_bazley

THETA_MAX_DEG = 78.0


def panel_impedance(p: Panel, f, theta, radius: float | None, c0: float):
    """Z_p = j w m [1 - kappa (f_r/f)^2 - (f/f_c)^2 sin^4(theta) (1 + j eta)], |Z_p| >= w m eta.

    kappa = 1 for the curved skin (membrane stiffness of a cylinder of the fuselage
    radius), 0 otherwise. The curvature term is added to the bracket rather than
    multiplying it (plan A.5 deviation, see projectPlan.md "Implementation notes").
    """
    f = np.asarray(f, dtype=float)
    w = 2.0 * np.pi * f
    m = p.mass
    fc = p.coincidence(c0)
    s4 = np.sin(theta) ** 4
    bracket = 1.0 - (f / fc) ** 2 * s4 * (1.0 + 1j * p.eta)
    if p.curved and radius:
        bracket = bracket - (p.ring_frequency(radius) / f) ** 2
    Z = 1j * w * m * bracket
    f11 = p.bay_frequency()
    if f11 > 0:
        # bay below its fundamental acts as a spring: single-mode stiffness s = rho h w11^2
        Z = Z - 1j * p.rho * p.h * (2 * np.pi * f11) ** 2 / w
    floor = w * m * p.eta
    mag = np.abs(Z)
    small = mag < floor
    if np.any(small):
        Z = np.where(small, np.where(mag > 0, Z / np.where(mag > 0, mag, 1.0), 1.0) * floor, Z)
    return Z


def layer_matrix(layer, f, theta, air: Air, radius: float | None):
    """2x2 transfer matrix of one layer as a tuple (T11, T12, T21, T22) of arrays."""
    f = np.asarray(f, dtype=float)
    one = np.ones(np.broadcast(f, theta).shape, dtype=complex)
    if isinstance(layer, Panel):
        Z = panel_impedance(layer, f, theta, radius, air.c) * one
        return one, Z, 0.0 * one, one
    w = 2.0 * np.pi * f
    k0 = w / air.c
    if isinstance(layer, PorousLayer):
        Zc, kc, _ = delany_bazley(f, layer.sigma, air.rho, air.c)
    elif isinstance(layer, PorousTable):
        Zc, kc = layer.properties(f)
    elif isinstance(layer, AirGap):
        Zc, kc = air.rho_c + 0j, k0 + 0j
    else:
        raise TypeError(f"unknown layer {layer!r}")
    kz = np.sqrt(kc ** 2 - (k0 * np.sin(theta)) ** 2 + 0j)
    kz = np.where(np.abs(kz) < 1e-12, 1e-12, kz)
    kd = kz * layer.d
    zr = Zc * kc / kz
    return np.cos(kd) * one, 1j * zr * np.sin(kd) * one, 1j * np.sin(kd) / zr * one, np.cos(kd) * one


def stack_matrix(layers, f, theta, air: Air, radius: float | None):
    if not layers:
        raise ValueError("sidewall stack is empty")
    T = layer_matrix(layers[0], f, theta, air, radius)
    for lay in layers[1:]:
        B = layer_matrix(lay, f, theta, air, radius)
        T = (T[0] * B[0] + T[1] * B[2], T[0] * B[1] + T[1] * B[3],
             T[2] * B[0] + T[3] * B[2], T[2] * B[1] + T[3] * B[3])
    return T


def tau(layers, f, theta, air: Air, radius: float | None = None) -> np.ndarray:
    """Plane-wave power transmission coefficient tau(f, theta)."""
    T11, T12, T21, T22 = stack_matrix(layers, f, theta, air, radius)
    Z0 = air.rho_c
    ct = np.cos(theta)
    return np.abs(2.0 / (T11 + T12 * ct / Z0 + T21 * Z0 / ct + T22)) ** 2


def _gauss_theta(n: int, theta_max_deg: float = THETA_MAX_DEG):
    x, w = np.polynomial.legendre.leggauss(n)
    tm = np.radians(theta_max_deg)
    th = 0.5 * tm * (x + 1.0)
    return th, 0.5 * tm * w


def tau_diffuse(layers, f, air: Air, radius: float | None = None, n_theta: int = 60) -> np.ndarray:
    """Diffuse-field average over 0..78 deg with sin*cos weighting (Gauss-Legendre)."""
    f = np.atleast_1d(np.asarray(f, dtype=float))
    th, w = _gauss_theta(n_theta)
    t = tau(layers, f[..., None], th, air, radius)
    wt = w * np.sin(th) * np.cos(th)
    return (t * wt).sum(axis=-1) / wt.sum()


def tau_band(layers, centers, air: Air, radius: float | None = None,
             n_theta: int = 60, n_sub: int = 10) -> np.ndarray:
    """Band-averaged diffuse tau: mean of tau_d over n_sub log-spaced frequencies per band."""
    fs = log_subfrequencies(np.asarray(centers, dtype=float), n_sub)
    return tau_diffuse(layers, fs, air, radius, n_theta).mean(axis=-1)


def composite(taus, areas) -> np.ndarray:
    """Area-weighted composite tau = sum(S_i tau_i) / sum(S_i)."""
    areas = np.asarray(areas, dtype=float)
    num = sum(a * np.asarray(t) for a, t in zip(areas, taus))
    return num / areas.sum()


def tl(t) -> np.ndarray:
    return -10.0 * np.log10(np.maximum(np.asarray(t, dtype=float), 1e-30))


def mass_air_mass_f0(m1: float, m2: float, d: float, air: Air) -> float:
    return np.sqrt(air.rho * air.c ** 2 * (m1 + m2) / (d * m1 * m2)) / (2.0 * np.pi)
