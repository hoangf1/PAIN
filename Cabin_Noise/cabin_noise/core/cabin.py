"""Cabin absorption and reverberation (Sabine), seat statistic (Schroeder)."""
from __future__ import annotations

import numpy as np

# reverberant p^2 is exponentially distributed (Schroeder 1962): the 95th-percentile seat is
# 10 log10(ln 20) = 4.8 dB above the room average
STAT_95 = 10.0 * np.log10(np.log(20.0))


def absorption_area(surfaces, f) -> np.ndarray:
    """A(f) = sum S_i alpha_i(f), m^2 Sabine."""
    f = np.asarray(f, dtype=float)
    if not surfaces:
        raise ValueError("cabin has no absorbing surfaces")
    return sum(s.area * s.alpha_at(f) for s in surfaces)


def t60(volume: float, A) -> np.ndarray:
    """Sabine: T60 = 0.161 V / A."""
    return 0.161 * volume / np.maximum(np.asarray(A, dtype=float), 1e-9)


def schroeder_frequency(T60: float, volume: float) -> float:
    return 2000.0 * np.sqrt(T60 / volume)
