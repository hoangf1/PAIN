"""Follow a Fig. 5 curve beyond where the row-by-row trace stopped (ISSUE-043, 2026-11-14).

The trace of curves.py runs row by row from the curve's foot on the J axis and stops at the first crossing or label.
This follower starts at the trace's upper end and steps along the curve's own direction: at each 3 px step it looks
across the curve for the ink nearest the predicted position (curve ink is darker than the grid lines) and carries
through dashes and crossings by extrapolating its direction over up to 45 px."""
import numpy as np

CURVE = 128.0        # curve ink; the grid lines peak near 105-125 of 255

def _sample(ink, x, y):
    x0 = int(np.floor(x)); y0 = int(np.floor(y)); fx = x - x0; fy = y - y0
    a = ink[y0, x0]; b = ink[y0, x0 + 1]; c = ink[y0 + 1, x0]; d = ink[y0 + 1, x0 + 1]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy

def follow(P, xs, ys, step=3.0, look=5.0, maxgap=45.0, maxlen=4000):
    """xs, ys: the trace, top (smallest y) first. Returns the continuation as arrays (from the trace's top end on)."""
    ink = P.ink
    k = min(30, len(xs))
    q = np.array([xs[:k], ys[:k]], float).T                  # topmost part of the trace
    c = q.mean(0); u, s, vt = np.linalg.svd(q - c); d = vt[0]
    if d[1] > 0: d = -d                                       # upward (towards smaller y)
    p = np.array([xs[0], ys[0]], float)
    path = [p.copy()]; hist = [p.copy()]; gap = 0.0
    xmin = P.X(0.0, p[1]) + 4; ymin = P.Y(0.21, p[0]) + 4
    while len(path) < maxlen:
        qn = p + step * d; n = np.array([-d[1], d[0]])
        offs = np.arange(-look, look + 0.01, 0.5)
        prof = np.array([_sample(ink, *(qn + o * n)) for o in offs])
        best = None
        for i in range(1, len(offs) - 1):
            if prof[i] >= CURVE and prof[i] >= prof[i - 1] and prof[i] >= prof[i + 1]:
                if best is None or abs(offs[i]) < abs(offs[best]): best = i
        if best is not None:
            lo = max(0, best - 4); hi = min(len(offs), best + 5)
            w = np.clip(prof[lo:hi] - 100.0, 0, None); off = float((offs[lo:hi] * w).sum() / w.sum())
            p = qn + off * n; gap = 0.0; hist.append(p.copy())
            h = np.array(hist[-12:])                          # direction from the last ~36 px of accepted points
            if len(h) >= 4:
                c = h.mean(0); u, s, vt = np.linalg.svd(h - c); dn = vt[0]
                if np.dot(dn, d) < 0: dn = -dn
                d = 0.6 * d + 0.4 * dn; d /= np.linalg.norm(d)
        else:
            p = qn; gap += step
            if gap > maxgap: break
        if p[0] < xmin or p[1] < ymin: break
        path.append(p.copy())
    path = np.array(path)
    # drop the extrapolated tail after the last accepted point
    last = hist[-1]; i = int(np.argmin(np.hypot(path[:, 0] - last[0], path[:, 1] - last[1])))
    return path[:i + 1, 0], path[:i + 1, 1]

def cross(P, px, py, J):
    """first crossing of the followed path with gridline J: (y, slope dy/dx in px) or None"""
    f = px - np.array([P.X(J, y) for y in py])
    k = np.where(np.sign(f[:-1]) * np.sign(f[1:]) <= 0)[0]
    if len(k) == 0: return None
    k = k[0]; lo = max(0, k - 5); hi = min(len(px), k + 7)
    X = px[lo:hi]; Y = py[lo:hi]
    if np.ptp(X) > np.ptp(Y):
        A = np.polyfit(X, Y, 1); x = P.X(J, np.polyval(A, X.mean()))
        for _ in range(3): x = P.X(J, np.polyval(A, x))
        return float(np.polyval(A, x)), float(A[0])
    A = np.polyfit(Y, X, 1); y = Y.mean()
    for _ in range(3): y = (P.X(J, y) - A[1]) / A[0]
    return float(y), float(1.0 / A[0]) if A[0] != 0 else 1e6
