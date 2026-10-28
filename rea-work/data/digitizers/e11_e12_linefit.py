"""Plan A3b (registered 2026-10-28): NASA's predicted lines in CR-3813 Fig. E-11 (free field, PDF p. 135) and
Fig. E-12 (blocked, PDF p. 136), read from pixels the same way for both figures, so that E-12 minus E-11 can be
compared with Eq. (43)'s Delta L at the same X3/D. Diagnostic only: no criterion, nothing in the code is changed.

Method (pass A, pixels). Render each page at 300 dpi (grey, dark < 128). Calibration from tick marks detected in
the render: X from the top and bottom x ticks, interpolated in height (the E-12 scan is sheared by about 12 px
between top and bottom); dB from the left ticks of each panel. Each predicted line is a polyline. Seeds (rough
vertices, read by eye) only place a search band: for each segment, dark runs are found along the normal of the
seed segment within +/- W px at 25 points between 15 % and 85 % of its length, the run nearest the seed is kept,
a line is fitted by total least squares, outliers beyond 2.5 px are dropped and the fit repeated. A curve value at
X is the fitted line of the segment that covers X. A corner is the intersection of two fitted lines whose
directions differ by more than 25 deg.

Run from rea-work: python data/digitizers/e11_e12_linefit.py  -> data/cr3813/e11_pred/e11_e12_predicted_linefit.csv
"""
import csv, math, sys
import numpy as np
import fitz

PDF = 'references/Pain Methodology.pdf'
D_M, A_M = 0.762, 0.508
STEP = math.pi * A_M / 18 / D_M                          # station spacing in X3/D
STATIONS = {8 - n: round(n * STEP, 4) for n in range(-8, 8)}   # k -> X3/D (k_p = 8)

FIG = {
    'E11': dict(page=134,
                xt_top=([1, .5, 0, -.5, -1], [638.0, 925.5, 1213.0, 1503.0, 1789.5]), y_top=337,
                xt_bot=([1, .5, 0, -.5, -1], [630.5, 924.5, 1211.0, 1499.5, 1782.5]), y_bot=2640,
                yt={1: ([130, 120, 110, 100], [528, 721.5, 913, 1102.5]),
                    2: ([120, 110, 100, 90], [1296.5, 1491.5, 1680.5, 1867.5]),
                    3: ([110, 100, 90], [2063, 2256, 2447])}),
    'E12': dict(page=135,
                xt_top=([1, .5, 0, -.5, -1], [618.5, 909.0, 1196.0, 1487.0, 1774.5]), y_top=365,
                xt_bot=([1, 0, -.5, -1], [598.0, 1184.0, 1473.5, 1757.5]), y_bot=2678,
                yt={1: ([130, 120, 110, 100], [559, 753.5, 945.5, 1136]),
                    2: ([120, 110, 100, 90], [1330.5, 1525.5, 1715.5, 1902.5]),
                    3: ([110, 100, 90], [2099, 2293, 2484])}),
}

# Seeds: rough vertices (X3/D, dB) read by eye. E-11 from the 1 dB station overlay (e11_pred_grid.py A);
# E-12 from the existing pass-A digitization (data/cr3813/e12/e12_predicted_A.csv).
SEEDS = {
    ('E11', 1): [(0.815, 97.9), (0.698, 102.4), (0.582, 106.9), (0.466, 113.3), (0.349, 118.4), (0.233, 123.0),
                 (0.116, 125.8), (0.0, 121.0), (-0.116, 124.6), (-0.233, 122.4), (-0.349, 117.0), (-0.466, 111.4),
                 (-0.582, 106.7), (-0.698, 101.9), (-0.815, 99.0)],
    ('E11', 2): [(0.466, 92.5), (0.349, 101.0), (0.233, 112.5), (0.116, 118.0), (0.0, 114.1), (-0.116, 116.0),
                 (-0.233, 109.8), (-0.349, 99.8), (-0.466, 90.2)],
    ('E11', 3): [(0.349, 87.3), (0.233, 99.4), (0.116, 111.0), (0.0, 108.2), (-0.116, 107.8), (-0.233, 95.5),
                 (-0.340, 83.8)],
}


def load(fig):
    f = FIG[fig]
    p = fitz.open(PDF)[f['page']]
    pm = p.get_pixmap(dpi=300, colorspace=fitz.csGRAY)
    img = np.frombuffer(pm.samples, dtype=np.uint8).reshape(pm.h, pm.w)
    ct = np.polyfit(*f['xt_top'], 1); cb = np.polyfit(*f['xt_bot'], 1)
    yfit = {h: np.polyfit(v, y, 1) for h, (v, y) in f['yt'].items()}
    def to_px(h, X, dB):
        py = float(np.polyval(yfit[h], dB))
        t = (py - f['y_top']) / (f['y_bot'] - f['y_top'])
        return (1 - t) * float(np.polyval(ct, X)) + t * float(np.polyval(cb, X)), py
    def to_xd(h, px, py):
        dB = (py - yfit[h][1]) / yfit[h][0]
        t = (py - f['y_top']) / (f['y_bot'] - f['y_top'])
        c = (1 - t) * ct + t * cb
        return (px - c[1]) / c[0], dB
    return img < 128, to_px, to_xd


def fit_segment(dark, p0, p1, W=14):
    p0, p1 = np.array(p0), np.array(p1)
    u = (p1 - p0) / np.linalg.norm(p1 - p0); n = np.array([-u[1], u[0]])
    pts = []
    for t in np.linspace(0.15, 0.85, 25):
        c = p0 + t * (p1 - p0)
        s = np.arange(-W, W + 1)
        xy = np.rint(c[None, :] + s[:, None] * n[None, :]).astype(int)
        ok = (xy[:, 1] >= 0) & (xy[:, 1] < dark.shape[0]) & (xy[:, 0] >= 0) & (xy[:, 0] < dark.shape[1])
        v = np.zeros(len(s), bool); v[ok] = dark[xy[ok, 1], xy[ok, 0]]
        runs, i = [], 0
        while i < len(s):
            if v[i]:
                j = i
                while j + 1 < len(s) and v[j + 1]: j += 1
                runs.append((s[i] + s[j]) / 2); i = j + 1
            else:
                i += 1
        if runs:
            pts.append(c + min(runs, key=abs) * n)
    P = np.array(pts)
    for _ in range(3):
        m = P.mean(0); _, _, vt = np.linalg.svd(P - m); d = vt[0]
        r = np.abs((P - m) @ np.array([-d[1], d[0]]))
        keep = r < 2.5
        if keep.all() or keep.sum() < 6: break
        P = P[keep]
    return m, d, len(P)


def trace(fig, h, seeds):
    dark, to_px, to_xd = load(fig)
    px = [to_px(h, X, dB) for X, dB in seeds]
    segs = [fit_segment(dark, px[i], px[i + 1]) for i in range(len(px) - 1)]
    def line_at_x(seg, X):                      # dB on a fitted pixel line at X3/D (solve by bisection on px)
        m, d, _ = seg
        lo, hi = -400.0, 400.0
        for _ in range(60):
            mid = (lo + hi) / 2; q = m + mid * d
            Xq, _ = to_xd(h, *q)
            if (Xq - X) * (to_xd(h, *(m + hi * d))[0] - X) > 0: hi = mid
            else: lo = mid
        return to_xd(h, *(m + lo * d))[1]
    corners = []
    for i in range(len(segs) - 1):
        (m1, d1, _), (m2, d2, _) = segs[i], segs[i + 1]
        ang = math.degrees(math.acos(min(1, abs(float(d1 @ d2)))))
        if ang > 25:
            A = np.column_stack([d1, -d2]); ts = np.linalg.solve(A, m2 - m1)
            corners.append(to_xd(h, *(m1 + ts[0] * d1)) + (ang,))
    Xs = [X for X, _ in seeds]
    def value(X):
        for i in range(len(Xs) - 1):
            if min(Xs[i], Xs[i + 1]) - 1e-9 <= X <= max(Xs[i], Xs[i + 1]) + 1e-9:
                return line_at_x(segs[i], X)    # the fitted line of the seed interval that covers X
        return None
    return segs, corners, value, Xs


def main():
    e12 = {}
    for r in csv.DictReader(l for l in open('data/cr3813/e12/e12_predicted_A.csv') if not l.startswith('#')):
        e12.setdefault(int(r['harmonic']), []).append((float(r['X3_over_D']), float(r['SPL_dB'])))
    for h in e12: SEEDS[('E12', h)] = sorted(e12[h], reverse=True)
    rows = []
    for h in (1, 2, 3):
        out = {}
        for fig in ('E11', 'E12'):
            segs, corners, value, Xs = trace(fig, h, SEEDS[(fig, h)])
            out[fig] = (value, Xs)
            print(f"H{h} {fig}: points kept per segment {[s[2] for s in segs]}")
            for X, dB, ang in corners:
                print(f"   corner X3/D {X:+.3f} ({X / STEP:+.2f} stations) {dB:.1f} dB, angle {ang:.0f} deg")
        lo = max(min(out['E11'][1]), min(out['E12'][1])); hi = min(max(out['E11'][1]), max(out['E12'][1]))
        for k, X in sorted(STATIONS.items()):
            if lo <= X <= hi:
                a = out['E11'][0](X); b = out['E12'][0](X)
                rows.append(dict(harmonic=h, k=k, X3_over_D=X, E11_pred_dB=round(a, 2), E12_pred_dB=round(b, 2),
                                 E12_minus_E11_dB=round(b - a, 2)))
    path = 'data/cr3813/e11_pred/e11_e12_predicted_linefit.csv'
    with open(path, 'w', newline='') as f:
        f.write('# Plan A3b (2026-10-28), diagnostic: NASA predicted lines of CR-3813 Figs. E-11 and E-12 read from pixels\n')
        f.write('# with one calibration method (data/digitizers/e11_e12_linefit.py), evaluated at the grid stations (k_p = 8).\n')
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
    write_report(rows)
    print('wrote', path)


def write_report(rows):
    """docs/validation_reports/e12_a3b_linefit.md: E-11 predicted vs Table 8, E-12 - E-11 vs Delta L, and
    Table 8 + Delta L vs the pixel-read E-12 line, beside the recorded by-eye comparison (e12_blocking.md)."""
    import re
    rec = {}
    for l in open('docs/validation_reports/e12_blocking.md', encoding='utf-8'):
        m = re.match(r"\| (\d+) \| [-\d.]+ \| [\d.]+ \| ([\d.]+) \| (\d) \| ([\d.]+) \| ([\d.]+) \| ([-+\d.]+) \|", l)
        if m:
            rec[(int(m[3]), int(m[1]))] = dict(dL=float(m[2]), ours=float(m[4]), e12_eye=float(m[5]), diff_eye=float(m[6]))
    eye = {(h, k): dB for (fig, h), pts in SEEDS.items() if fig == 'E11'
           for X, dB in pts for k, Xs in STATIONS.items() if abs(Xs - X) < 0.006}
    L = ["# A3b: NASA's predicted E-11 and E-12 lines read from pixels (diagnostic, 2026-10-28)", "",
         "Registered 2026-10-28 before any reading (IMPLEMENTATION_PLAN §8o A3b). No criterion; E12_BLOCK's recorded "
         "verdict and criterion are unchanged. Generated by `data/digitizers/e11_e12_linefit.py`.", "",
         "Method: both figures calibrated from tick marks detected in a 300 dpi render (E-12's frame is sheared by about "
         "12 px top to bottom, corrected); each predicted line fitted segment by segment to its pixels. Pass B for E-11 is "
         "a by-eye reading on a 1 dB station grid (`e11_pred_grid.py A`), used as the fit seeds.", "",
         "| H | k | X3/D | Table 8 | E-11 pred (pixels) | E-11 pred (eye) | E-12 pred (pixels) | E-12 − E-11 | ΔL Eq. 43 | Table 8 + ΔL − E-12, eye (recorded) | same, pixels |",
         "|---|---|---|---|---|---|---|---|---|---|---|"]
    dmax, n_in, worst = 0.0, 0, (0, None)
    for r in rows:
        h, k = r['harmonic'], r['k']; c = rec.get((h, k))
        if not c: continue
        t8 = c['ours'] - c['dL']; pix = c['ours'] - r['E12_pred_dB']; e = eye.get((h, k))
        if e is not None: dmax = max(dmax, abs(e - r['E11_pred_dB']))
        if abs(pix) > abs(worst[0]): worst = (pix, (h, k))
        L.append(f"| {h} | {k} | {r['X3_over_D']:+.3f} | {t8:.1f} | {r['E11_pred_dB']:.1f} | "
                 f"{'' if e is None else f'{e:.1f}'} | {r['E12_pred_dB']:.1f} | {r['E12_minus_E11_dB']:.1f} | {c['dL']:.2f} | "
                 f"{c['diff_eye']:+.1f} | {pix:+.1f} |")
    L += ["", f"δ_dig of the E-11 predicted line (pixels vs eye, at the stations above): {dmax:.1f} dB. "
          f"Largest |Table 8 + ΔL − E-12 (pixels)|: {abs(worst[0]):.1f} dB at H{worst[1][0]} k{worst[1][1]}.", ""]
    open('docs/validation_reports/e12_a3b_linefit.md', 'w', encoding='utf-8', newline='\n').write("\n".join(L))


if __name__ == '__main__':
    main()
