"""NACA Report 1012 Fig. 5: one page (panel) with its grid calibration.

The grid is calibrated per page from the regular grid lines found in three bands (the scans are skewed by a few px).
Axes (all ten panels): J 0 to 5.6, 0.1 per cell; left axis C_T 0 to 0.21, 0.005 per cell; C_P = 2 x the C_T axis;
efficiency = the C_T axis / 0.05 (1.0 at the C_T = 0.05 line)."""
import numpy as np
from grid import band

THR = 70.0           # ink threshold; the horizontal grid lines pass it too and are removed by position

class Page:
    def __init__(self, g):
        """g: the 300 dpi grey render of the page, as a float array (0 black .. 255 white)"""
        self.g = g; self.ink = 255 - self.g
        g = self.g
        rb = ((450, 900), (1000, 1500), (1700, 2150)); cb = ((800, 1400), (1600, 2200), (2500, 3050))
        V = [band(g, rows=r) for r in rb]; H = [band(g, cols=c) for c in cb]
        # anchor: the frame is the run of 57 consecutive vertical (43 horizontal) regular lines
        def run(t, n):
            A, idx, k, res = t
            idx = idx - idx.min(); best = None; i = 0
            while i < len(idx):
                j = i
                while j + 1 < len(idx) and idx[j + 1] == idx[j] + 1: j += 1
                if best is None or j - i > best[1] - best[0]: best = (i, j)
                i = j + 1
            assert best[1] - best[0] + 1 == n, (best, n, len(idx))
            return k[best[0]], k[best[1]]
        self.xl, self.xr = run(V[1], 57); self.yt, self.yb = run(H[1], 43)
        xl = [run(v, 57)[0] for v in V]; yb = [run(h, 43)[1] for h in H]
        # x(j, y) = a0 + a1 j + a2 (y - yc) ; y(i, x) = b0 + b1 i + b2 (x - xc); j, i counted from the frame
        self.yc = 1300.0; self.xc = 1900.0
        rows = []; rhs = []
        for n, ((A, idx, k, res), r) in enumerate(zip(V, rb)):
            j = np.round((k - xl[n]) / A[0])
            ok = (j >= 0) & (j <= 56)
            for jj, kk in zip(j[ok], k[ok]): rows.append((1.0, jj, 0.5 * (r[0] + r[1]) - self.yc)); rhs.append(kk)
        self.a, *_ = np.linalg.lstsq(np.array(rows), np.array(rhs), rcond=None)
        self.rx = float(np.abs(np.array(rows) @ self.a - np.array(rhs)).max())
        rows = []; rhs = []
        for n, ((A, idx, k, res), c) in enumerate(zip(H, cb)):
            i = np.round((yb[n] - k) / A[0])
            ok = (i >= 0) & (i <= 42)
            for ii, kk in zip(i[ok], k[ok]): rows.append((1.0, ii, 0.5 * (c[0] + c[1]) - self.xc)); rhs.append(kk)
        self.b, *_ = np.linalg.lstsq(np.array(rows), np.array(rhs), rcond=None)
        self.ry = float(np.abs(np.array(rows) @ self.b - np.array(rhs)).max())

    def X(self, J, y):
        return self.a[0] + self.a[1] * (J / 0.1) + self.a[2] * (y - self.yc)

    def Y(self, v, x):
        return self.b[0] + self.b[1] * (v / 0.005) + self.b[2] * (x - self.xc)

    def value(self, x, y):
        """pixel -> (J, C_T-axis value); two linear equations"""
        # x = a0 + a1 j + a2 (y - yc); y = b0 + b1 i + b2 (x - xc)
        j = (x - self.a[0] - self.a[2] * (y - self.yc)) / self.a[1]
        i = (y - self.b[0] - self.b[2] * (x - self.xc)) / self.b[1]
        return 0.1 * j, 0.005 * i
