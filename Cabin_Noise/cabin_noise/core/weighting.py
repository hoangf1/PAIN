"""A/C frequency weighting and energetic sums (plan A.8)."""
from __future__ import annotations

import numpy as np

P_REF = 20e-6


def a_weight(f) -> np.ndarray:
    f2 = np.asarray(f, dtype=float) ** 2
    ra = 12194.0 ** 2 * f2 ** 2 / ((f2 + 20.6 ** 2) * np.sqrt((f2 + 107.7 ** 2) * (f2 + 737.9 ** 2))
                                   * (f2 + 12194.0 ** 2))
    return 20.0 * np.log10(ra) + 2.00


def c_weight(f) -> np.ndarray:
    f2 = np.asarray(f, dtype=float) ** 2
    rc = 12194.0 ** 2 * f2 / ((f2 + 20.6 ** 2) * (f2 + 12194.0 ** 2))
    return 20.0 * np.log10(rc) + 0.06


def db(p2) -> np.ndarray:
    return 10.0 * np.log10(np.maximum(np.asarray(p2, dtype=float), 1e-30) / P_REF ** 2)


def p2_from_db(L) -> np.ndarray:
    return P_REF ** 2 * 10.0 ** (np.asarray(L, dtype=float) / 10.0)


def energetic_sum(levels, axis=None) -> np.ndarray:
    L = np.asarray(levels, dtype=float)
    return 10.0 * np.log10(np.sum(10.0 ** (L / 10.0), axis=axis))


def totals(band_levels, centers) -> dict:
    """OASPL, dBA, dBC of a 1/3-octave band spectrum."""
    L = np.asarray(band_levels, dtype=float)
    return {
        "OASPL": float(energetic_sum(L)),
        "dBA": float(energetic_sum(L + a_weight(centers))),
        "dBC": float(energetic_sum(L + c_weight(centers))),
    }
