"""Cabin absorption and reverberation (Sabine), seat statistic (Schroeder)."""
from __future__ import annotations

import numpy as np

def seat_stat_db(percentile: float) -> float:
    """Reverberant p^2 is exponentially distributed (Schroeder 1962): the seat at the given
    percentile is 10 log10(ln(1 / (1 - P))) above the room average (95 %: ln 20, 4.8 dB)."""
    if not 50.0 <= percentile < 100.0:
        raise ValueError("seat percentile must be in [50, 100)")
    return float(10.0 * np.log10(np.log(1.0 / (1.0 - percentile / 100.0))))


STAT_95 = seat_stat_db(95.0)


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
