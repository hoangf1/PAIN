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
