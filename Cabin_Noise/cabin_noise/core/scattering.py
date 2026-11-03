"""Rigid-cylinder surface pressure factor (plan A.3), e^{-j w t} convention.

S(phi) = p_surface / p_inc for a plane wave on an infinite rigid cylinder of radius a.
phi is measured on the surface from the point facing the source (phi = 0 lit side,
phi = pi shadow side).
"""
from __future__ import annotations

import numpy as np
from scipy.special import hankel1


def surface_factor(ka, phi) -> np.ndarray:
    ka = np.atleast_1d(np.asarray(ka, dtype=float))
    phi = np.asarray(phi, dtype=float)
    out = np.empty(np.broadcast(ka, phi).shape, dtype=complex)
    phi_b = np.broadcast_to(phi, out.shape)
    ka_b = np.broadcast_to(ka, out.shape)
    for idx in np.ndindex(out.shape):
        z, ph = ka_b[idx], phi_b[idx]
        N = int(np.ceil(z)) + 20
        n = np.arange(N + 1)
        eps = np.where(n == 0, 1.0, 2.0)
        dH = 0.5 * (hankel1(n - 1, z) - hankel1(n + 1, z))
        # phi_geom (from the propagation direction) = pi - phi
        terms = eps * (1j ** n) * np.cos(n * (np.pi - ph)) / dH
        out[idx] = 2j / (np.pi * z) * terms.sum()
    return out
