"""Cabin absorption, reverberation and the room equation (plan A.6)."""
from __future__ import annotations

import numpy as np

from .atmosphere import Air


def absorption_area(surfaces, f) -> np.ndarray:
    """A(f) = sum S_i alpha_i(f), m^2 Sabine."""
    f = np.asarray(f, dtype=float)
    if not surfaces:
        raise ValueError("cabin has no absorbing surfaces")
    return sum(s.area * s.alpha_at(f) for s in surfaces)


def t60(volume: float, A) -> np.ndarray:
    return 0.161 * volume / np.maximum(np.asarray(A, dtype=float), 1e-9)


def schroeder_frequency(T60: float, volume: float) -> float:
    return 2000.0 * np.sqrt(T60 / volume)


def interior_p2(W, A, air: Air) -> np.ndarray:
    """Reverberant mean-square pressure p^2 = 4 rho c W / A."""
    return 4.0 * air.rho_c * np.asarray(W) / np.maximum(np.asarray(A, dtype=float), 1e-9)
