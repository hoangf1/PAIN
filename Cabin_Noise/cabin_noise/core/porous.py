"""Delany-Bazley porous-layer model (plan A.5), e^{+j w t} convention."""
from __future__ import annotations

import numpy as np


def delany_bazley(f, sigma: float, rho0: float, c0: float):
    """Characteristic impedance Z_c and wavenumber k_c of a fibrous layer.

    Returns (Z_c, k_c, X) with X = rho0 f / sigma; the fit is valid for X in ~0.01..1.
    """
    f = np.asarray(f, dtype=float)
    X = rho0 * f / sigma
    Zc = rho0 * c0 * (1.0 + 0.0571 * X ** -0.754 - 1j * 0.087 * X ** -0.732)
    kc = (2.0 * np.pi * f / c0) * (1.0 + 0.0978 * X ** -0.700 - 1j * 0.189 * X ** -0.595)
    return Zc, kc, X


def limp_frame(Zc, kc, f, rho0: float, bulk_density: float):
    """Limp-frame equivalent fluid from a rigid-frame one (Panneton 2007, JASA 122, EL217):
    rho_eq = Zc kc / w and K = w Zc / kc (e^{+j w t}); the frame moves with the air, so
    rho_limp = (rho_t rho_eq - rho0^2) / (rho_t + rho_eq - 2 rho0), rho_t = bulk_density + rho0
    (porosity taken as 1, fibrous blanket). Returns the limp Zc, kc."""
    w = 2.0 * np.pi * np.asarray(f, dtype=float)
    rho_eq = Zc * kc / w
    K = w * Zc / kc
    rho_t = bulk_density + rho0
    rho_l = (rho_t * rho_eq - rho0 ** 2) / (rho_t + rho_eq - 2.0 * rho0)
    k = w * np.sqrt(rho_l / K)
    k = np.where(k.real < 0, -k, k)                   # forward wave: Re k > 0 (then Im k <= 0, decaying)
    return w * rho_l / k, k                           # Zc = w rho / k = sqrt(rho K) on the same branch


def effective_density(Zc, kc, f):
    """rho = Zc kc / w of an equivalent fluid."""
    return Zc * kc / (2.0 * np.pi * np.asarray(f, dtype=float))
