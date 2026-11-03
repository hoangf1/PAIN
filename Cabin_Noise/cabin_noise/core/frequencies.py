"""Frequency grids: 1/3-octave band centres and propeller harmonic lists."""
from __future__ import annotations

import numpy as np

# Preferred nominal labels (IEC 61260) for the exact base-10 centres 1000*10^(n/10).
_NOMINAL = [
    1, 1.25, 1.6, 2, 2.5, 3.15, 4, 5, 6.3, 8,
]


def third_octave_centers(f_min: float = 50.0, f_max: float = 5000.0) -> np.ndarray:
    """Exact base-10 1/3-octave centres whose nominal value lies in [f_min, f_max]."""
    n = np.arange(-30, 14)
    fc = 1000.0 * 10.0 ** (n / 10.0)
    tol = 2.0 ** (1.0 / 12.0)
    return fc[(fc >= f_min / tol) & (fc <= f_max * tol)]


def nominal_label(fc: float) -> str:
    """Nominal label of an exact 1/3-octave centre, e.g. 1995.3 -> '2000'."""
    e = np.floor(np.log10(fc))
    mant = fc / 10.0 ** e
    best = min(_NOMINAL + [10], key=lambda v: abs(np.log10(v / mant)))
    val = best * 10.0 ** e
    return f"{val:g}" if val < 1000 else f"{val / 1000:g}k"


def band_edges(fc: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Lower/upper edges f_c*2^(-1/6), f_c*2^(1/6) (plan A.8)."""
    fc = np.asarray(fc, dtype=float)
    return fc * 2.0 ** (-1.0 / 6.0), fc * 2.0 ** (1.0 / 6.0)


def harmonic_frequencies(blades: int, rpm: float, n_harmonics: int) -> np.ndarray:
    """f_m = m*B*RPM/60, m = 1..N."""
    return np.arange(1, n_harmonics + 1) * blades * rpm / 60.0


def band_index(f: np.ndarray, centers: np.ndarray) -> np.ndarray:
    """Index of the band that contains each frequency, -1 if outside the grid."""
    lo, hi = band_edges(centers)
    f = np.atleast_1d(np.asarray(f, dtype=float))
    idx = np.full(f.shape, -1, dtype=int)
    for i, (a, b) in enumerate(zip(lo, hi)):
        idx[(f >= a) & (f < b)] = i
    return idx
