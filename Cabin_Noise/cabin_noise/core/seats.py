"""Seat-to-seat variation (plan A.7).

Above the Schroeder frequency the reverberant p^2 is exponentially distributed, so the
95th / 99th percentile seat is L + 10 log10(ln 20) / L + 10 log10(ln 100). Below it a
rigid-wall box gives the spatial shape G(x), normalised by its volume average, while the
level itself still comes from the room equation.

Cabin coordinates: x along the cabin from its forward wall, y across from the
propeller-side sidewall (y = 0), z up from the floor.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

STAT_95 = 10.0 * np.log10(np.log(20.0))
STAT_99 = 10.0 * np.log10(np.log(100.0))


@dataclass(frozen=True)
class Box:
    Lx: float
    Ly: float
    Lz: float

    @property
    def volume(self) -> float:
        return self.Lx * self.Ly * self.Lz


@dataclass(frozen=True)
class SidewallPatch:
    """Prop-plane patch on the y = 0 wall: x in x_c +- w/2, z in z_c +- h/2."""
    x_c: float
    width: float
    z_c: float
    height: float


def box_modes(box: Box, c0: float, f_max: float):
    """Mode indices (M, 3) and natural frequencies (M,) up to f_max (always includes 0,0,0)."""
    nmax = [int(np.floor(2.0 * f_max * L / c0)) for L in (box.Lx, box.Ly, box.Lz)]
    gx, gy, gz = np.meshgrid(*[np.arange(n + 1) for n in nmax], indexing="ij")
    idx = np.stack([gx.ravel(), gy.ravel(), gz.ravel()], axis=1)
    fn = 0.5 * c0 * np.sqrt((idx[:, 0] / box.Lx) ** 2 + (idx[:, 1] / box.Ly) ** 2 + (idx[:, 2] / box.Lz) ** 2)
    keep = fn <= max(f_max, 0.0)
    return idx[keep], fn[keep]


def mode_shapes(idx, box: Box, pts) -> np.ndarray:
    pts = np.atleast_2d(np.asarray(pts, dtype=float))
    L = np.array([box.Lx, box.Ly, box.Lz])
    arg = np.pi * pts[:, None, :] * idx[None, :, :] / L[None, None, :]
    return np.prod(np.cos(arg), axis=2)                     # (P, M)


def _interval_mean(n, L, a, b):
    k = n * np.pi / L
    with np.errstate(divide="ignore", invalid="ignore"):
        m = (np.sin(k * b) - np.sin(k * a)) / (k * (b - a))
    return np.where(n == 0, 1.0, m)


def patch_mean(idx, box: Box, patch: SidewallPatch) -> np.ndarray:
    """Mean of psi_n over the patch (y = 0, so the y factor is 1)."""
    xa = max(patch.x_c - patch.width / 2, 0.0)
    xb = min(patch.x_c + patch.width / 2, box.Lx)
    za = max(patch.z_c - patch.height / 2, 0.0)
    zb = min(patch.z_c + patch.height / 2, box.Lz)
    if xb <= xa or zb <= za:
        raise ValueError("prop-plane patch lies outside the cabin box")
    return _interval_mean(idx[:, 0], box.Lx, xa, xb) * _interval_mean(idx[:, 2], box.Lz, za, zb)


def modal_coefficients(f: float, box: Box, c0: float, T60: float, patch: SidewallPatch):
    idx, fn = box_modes(box, c0, 2.0 * f)
    eta = 2.2 / (f * T60)
    coef = patch_mean(idx, box, patch) / (fn ** 2 - f ** 2 + 1j * eta * f * fn)
    return idx, coef


def relative_level(f: float, pts, box: Box, c0: float, T60: float, patch: SidewallPatch) -> np.ndarray:
    """10 log10(G(x)/<G>) at the points, dB; <G> is the analytic volume average."""
    idx, coef = modal_coefficients(f, box, c0, T60, patch)
    G = np.abs(mode_shapes(idx, box, pts) @ coef) ** 2
    norm = np.prod(np.where(idx == 0, 1.0, 0.5), axis=1)    # <psi_n^2> over the box
    G_mean = np.sum(np.abs(coef) ** 2 * norm)
    return 10.0 * np.log10(np.maximum(G, 1e-300) / G_mean)


def seat_offsets(freqs, f_s: float, pts, box: Box, c0: float, T60_of_f, patch: SidewallPatch,
                 n_band: int = 1, band_lo=None, band_hi=None) -> np.ndarray:
    """Per-seat offset from the room-average level, dB, shape (seats, freqs).

    Below f_s: box-mode shape (averaged in p^2 over n_band log-spaced frequencies when
    band edges are given). At or above f_s: the 95th-percentile statistic for every seat.
    """
    freqs = np.atleast_1d(np.asarray(freqs, dtype=float))
    pts = np.atleast_2d(pts)
    out = np.full((pts.shape[0], freqs.size), STAT_95)
    for j, f in enumerate(freqs):
        if f >= f_s:
            continue
        if band_lo is not None and n_band > 1:
            fs = np.geomspace(band_lo[j], band_hi[j], n_band)
        else:
            fs = [f]
        g = np.mean([10.0 ** (relative_level(ff, pts, box, c0, float(T60_of_f(ff)), patch) / 10.0)
                     for ff in fs], axis=0)
        out[:, j] = 10.0 * np.log10(g)
    return out
