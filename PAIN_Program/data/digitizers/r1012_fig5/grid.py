"""Grid calibration for NACA Report 1012 Fig. 5 panels (300 dpi renders): the regular grid lines from ink profiles."""
import numpy as np

def peaks(p, prom=10.0, half=12):
    """sub-pixel centres of local maxima that stand `prom` above the local median"""
    out = []
    for i in range(half, len(p) - half):
        w = p[i - half:i + half + 1]
        if p[i] == w.max() and p[i] - np.median(w) > prom and (not out or i - out[-1] > half):
            lo, hi = i - 3, i + 4; base = np.median(w)
            ww = np.clip(p[lo:hi] - base, 0, None)
            out.append(float((np.arange(lo, hi) * ww).sum() / ww.sum()))
    return np.array(out)

def regular(p):
    """keep the lines on one regular pitch; return (fit, index, kept, max residual)"""
    p = p[np.isfinite(p)]
    pitch = np.median(np.diff(p)); k = len(p) // 2
    idx = np.round((p - p[k]) / pitch); keep = np.abs((p - p[k]) / pitch - idx) < 0.2
    for _ in range(3):
        A = np.polyfit(idx[keep], p[keep], 1)
        idx = np.round((p - A[1]) / A[0]); keep = np.abs(p - np.polyval(A, idx)) < 0.15 * A[0]
    A = np.polyfit(idx[keep], p[keep], 1)
    res = p[keep] - np.polyval(A, idx[keep])
    return A, idx[keep], p[keep], float(np.abs(res).max())

def band(g, rows=None, cols=None):
    ink = 255 - g
    if rows is not None: return regular(_clip(peaks(ink[rows[0]:rows[1], :].mean(0)), 250, 3350))
    return regular(_clip(peaks(ink[:, cols[0]:cols[1]].mean(1)), 150, 2550))

def _clip(p, lo, hi):
    return p[(p > lo) & (p < hi)]
