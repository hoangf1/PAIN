"""Pass B: each pass-A value read again with its own calibration and its own estimator.
Calibration: the two horizontal grid lines that bracket the point, located next to the point (not the page-wide fit).
Estimator: a total-least-squares line through the raw ink pixels of the stroke near the gridline (pass A used run centres)."""
import numpy as np
from page import Page

def local_grid(P, x, y):
    """rows of the horizontal grid lines near (x, y): per-row median of the ink over a 70 px wide strip beside the gridline"""
    xi = int(round(x)); y0 = int(y) - 75; y1 = int(y) + 76
    cols = [c for c in range(xi - 38, xi + 39) if abs(c - xi) > 5]
    prof = np.median(P.ink[y0:y1, cols], axis=1)
    lines = []
    i0 = (y - P.b[0] - P.b[2] * (x - P.xc)) / P.b[1]
    for i in (np.floor(i0) - 1, np.floor(i0), np.floor(i0) + 1, np.floor(i0) + 2):
        yg = P.b[0] + P.b[1] * i + P.b[2] * (x - P.xc); k = int(round(yg)) - y0
        if k - 5 < 0 or k + 6 > len(prof): continue
        w = np.clip(prof[k - 5:k + 6] - 25.0, 0, None)
        if w.sum() < 60: continue
        lines.append((i, y0 + float((np.arange(k - 5, k + 6) * w).sum() / w.sum())))
    return lines

def stroke(P, J, yA, slope_hint):
    """TLS line through the stroke's ink pixels within 20 px of the gridline; returns y on the gridline"""
    xg = P.X(J, yA); pts = []; wts = []
    th = np.arctan(slope_hint); c, s = np.cos(th), np.sin(th)
    L = 22.0 + 5.0 / max(abs(c), 0.08)                      # steep strokes: reach past the gridline's own ink
    for dx in range(-int(L * abs(c)) - 4, int(L * abs(c)) + 5):
        if abs(dx) <= 4: continue
        for dy in range(-int(L * abs(s)) - 6, int(L * abs(s)) + 7):
            along = dx * c + dy * s; perp = -dx * s + dy * c
            if abs(along) > L or abs(perp) > 3.2: continue
            xx = int(round(xg)) + dx; yy = int(round(yA)) + dy
            v = P.ink[yy, xx]
            i = (yy - P.b[0] - P.b[2] * (xx - P.xc)) / P.b[1]
            if abs(i - round(i)) * abs(P.b[1]) < 3.0 and abs(slope_hint) > 0.25: continue      # on a horizontal grid line
            if v > 80: pts.append((xx, yy)); wts.append(v - 60.0)
    if len(pts) < 25: return None
    Q = np.array(pts, float); w = np.array(wts); m = (Q * w[:, None]).sum(0) / w.sum()
    C = ((Q - m) * w[:, None]).T @ (Q - m); ev, evec = np.linalg.eigh(C); d = evec[:, 1]
    if abs(d[0]) < 1e-6:
        return None
    sl = d[1] / d[0]
    return float(m[1] + sl * (xg - m[0]))

def read_b(P, J, yA, slope_px):
    yB = stroke(P, J, yA, slope_px)
    if yB is None: return None
    x = P.X(J, yB); g = local_grid(P, x, yB)
    lo = [t for t in g if t[1] >= yB]; hi = [t for t in g if t[1] <= yB]
    if not lo or not hi: return None
    a = min(lo, key=lambda t: t[1]); b = max(hi, key=lambda t: t[1])
    if a[0] == b[0]: return 0.005 * a[0], yB
    return 0.005 * (a[0] + (b[0] - a[0]) * (a[1] - yB) / (a[1] - b[1])), yB
