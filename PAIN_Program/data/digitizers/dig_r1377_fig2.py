"""Phase 156b (2026-11-15): digitize NACA Report 1377 Fig. 2, the two propeller blades (PDF p. 7).

Run from this folder:  python dig_r1377_fig2.py
Writes data/report1377/fig2_blade_form.csv, a pixel sidecar and QA overlays under data/report1377/qa/.
No value is typed by hand; the seeds only tell the follower which curve to start on.

Axes of both panels: r/R 0 to 1.0 (0.1 per cell); beta 0 to 50 deg (5 deg per cell); b/D = beta-axis / 500;
h/b = beta-axis / 100; design c_l on the right axis: panel (a) c_l = (beta-axis - 20) / 50, panel (b) (beta-axis - 25) / 50.
Pass A follows each curve both ways from a mid-span seed, pass B inward from a seed near the tip (dashes and crossings are
carried by the local direction); both are read at r/R = 0.30, 0.35, ... 0.95 from a local straight fit."""
import json, os, sys
import numpy as np
import pymupdf
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'r1012_fig5'))
from grid import peaks

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
PDF = os.path.join(ROOT, 'references', 'NACA_Report_1377.pdf')
OUT = os.path.join(ROOT, 'data', 'report1377')
S = 600 / 130
CROP = {'tapered': (60, 575, 95, 500), 'rectangular': (60, 575, 490, 905)}      # panel (a), (b) in 130 dpi page units
# seeds: curve -> (mid-span r/R, beta-axis value there, outer r/R, value there, first station, last station)
SEEDS = {'tapered': {'beta': (0.66, 27.7, 0.94, 18.5, 0.30, 0.95), 'h_over_b': (0.66, 8.7, 0.94, 6.8, 0.30, 0.95),
                     'b_over_D': (0.66, 40.4, 0.94, 32.4, 0.40, 0.95), 'cl_design': (0.66, 44.1, 0.94, 39.2, 0.40, 0.95)},
         'rectangular': {'beta': (0.66, 24.1, 0.94, 13.9, 0.30, 0.95), 'h_over_b': (0.66, 8.8, 0.94, 5.5, 0.30, 0.95),
                         'b_over_D': (0.66, 41.0, 0.94, 42.1, 0.30, 0.95), 'cl_design': (0.66, 49.1, 0.94, 38.7, 0.60, 0.95)}}
CONV = {'beta': lambda v, blade: v, 'h_over_b': lambda v, blade: v / 100, 'b_over_D': lambda v, blade: v / 500,
        'cl_design': lambda v, blade: (v - (20 if blade == 'tapered' else 25)) / 50}

def render(blade):
    pm = pymupdf.open(PDF)[6].get_pixmap(dpi=600, colorspace=pymupdf.csGRAY)
    g = np.frombuffer(pm.samples, dtype=np.uint8).reshape(pm.height, pm.width).astype(np.float32)
    x0, x1, y0, y1 = CROP[blade]
    return g[int(y0 * S):int(y1 * S), int(x0 * S):int(x1 * S)]

def calibrate(g):
    ink = 255 - g
    px = peaks(ink[300:1500, :].mean(0), prom=8, half=25); py = peaks(ink[:, 900:2000].mean(1), prom=8, half=25)
    def run(p, n):                                   # the n consecutive lines on one pitch
        best = None
        for i in range(len(p) - n + 1):
            q = p[i:i + n]; d = np.diff(q)
            if d.max() - d.min() < 12 and (best is None or d.std() < best[0]): best = (d.std(), q)
        A = np.polyfit(np.arange(n), best[1], 1); return A, float(np.abs(np.polyval(A, np.arange(n)) - best[1]).max())
    Ax, rx = run(px[px > 650], 10)                   # r/R 0.1 ... 1.0 (the 0 line carries the axis ticks)
    Ay, ry = run(py, 11)                             # beta 50 ... 0
    return dict(x1=float(Ax[1] + 9 * Ax[0]), px=float(Ax[0]), y0=float(Ay[1] + 10 * Ay[0]), py=float(Ay[0]), rx=rx, ry=ry)

def X(c, r): return c['x1'] - (1.0 - r) / 0.1 * c['px']
def Y(c, v): return c['y0'] - v / 5.0 * c['py']
def V(c, y): return (c['y0'] - y) / c['py'] * 5.0
def R(c, x): return 1.0 - (c['x1'] - x) / c['px'] * 0.1

def col_runs(ink, x, ylo, yhi, thr=95):
    col = ink[ylo:yhi, x]; d = col > thr; out = []; i = 0
    while i < len(d):
        if d[i]:
            j = i
            while j < len(d) and d[j]: j += 1
            if j - i <= 16:
                w = col[i:j] - 60; out.append(ylo + float((np.arange(i, j) * w).sum() / w.sum()))
            i = j
        else: i += 1
    return out

def on_line(c, y):
    """within 3.5 px of a horizontal grid line (their ink passes the threshold too)"""
    i = (c['y0'] - y) / c['py']
    return abs(i - round(i)) * c['py'] < 3.5

def follow(g, c, r0, v0, r_end, max_miss=160):
    ink = 255 - g; step = 1 if r_end > r0 else -1
    x = int(X(c, r0)); y = Y(c, v0)
    for _ in range(60):                               # the seed may fall in a gap of a dashed curve: step on to the first ink
        cand = [t for t in col_runs(ink, x, int(y) - 40, int(y) + 40) if not on_line(c, t)]
        if cand: break
        x += step
    y = min(cand, key=lambda t: abs(t - y))
    hx, hy = [x], [y]; miss = 0
    while (x - X(c, r_end)) * step < 0 and miss < max_miss:
        x += step; k = min(30, len(hx))
        pred = np.polyval(np.polyfit(hx[-k:], hy[-k:], 1), x) if k >= 6 else hy[-1]
        tol = min((8.0 if k < 6 else 4.0) + 0.05 * miss, 9.0)
        cand = [t for t in col_runs(ink, x, int(pred) - 16, int(pred) + 16) if not on_line(c, t) or abs(t - pred) < 2.5]
        b = min(cand, key=lambda t: abs(t - pred)) if cand else None
        if b is not None and abs(b - pred) < tol: hx.append(x); hy.append(b); miss = 0
        else: miss += 1
    return np.array(hx, float), np.array(hy)

def read(c, hx, hy, r):
    xg = X(c, r); m = np.abs(hx - xg) < 34
    onl = np.abs((hx - c['x1']) / c['px'] - np.round((hx - c['x1']) / c['px'])) * c['px'] < 6      # on a vertical grid line
    m &= ~onl
    if m.sum() < 8: return None
    A = np.polyfit(hx[m], hy[m], 1); return float(np.polyval(A, xg))

def main():
    os.makedirs(os.path.join(OUT, 'qa'), exist_ok=True)
    rows = []; side = {}
    for blade in ('tapered', 'rectangular'):
        g = render(blade); c = calibrate(g); side[blade] = dict(calibration=c, crop_130dpi=CROP[blade])
        im = Image.fromarray(g.astype('uint8')).convert('RGB'); d = ImageDraw.Draw(im)
        col = {'beta': (255, 0, 0), 'h_over_b': (0, 150, 0), 'b_over_D': (0, 0, 255), 'cl_design': (200, 0, 200)}
        res = {}
        for name, (ri, vi, ro, vo, s0, s1) in SEEDS[blade].items():
            ox, oy = follow(g, c, ri, vi, 0.96); ix, iy = follow(g, c, ri, vi, s0 - 0.02)     # pass A: both ways from a mid-span seed
            ax = np.concatenate([ix[::-1], ox[1:]]); ay = np.concatenate([iy[::-1], oy[1:]])
            bx, by = follow(g, c, ro, vo, s0 - 0.02)                                          # pass B: inward from the tip
            d.line(list(zip(ax + 7, ay)), fill=col[name], width=1)
            for k in range(int(round((s1 - s0) / 0.05)) + 1):
                r = round(s0 + 0.05 * k, 2); ya = read(c, ax, ay, r); yb = read(c, bx, by, r)
                if ya is None: continue
                res[(name, r)] = (CONV[name](V(c, ya), blade), None if yb is None else CONV[name](V(c, yb), blade))
                d.ellipse([X(c, r) - 9, ya - 9, X(c, r) + 9, ya + 9], outline=col[name], width=3)
        im.resize((im.width // 2, im.height // 2)).save(os.path.join(OUT, 'qa', 'fig2_%s_overlay.png' % blade))
        for r in [round(0.30 + 0.05 * k, 2) for k in range(14)]:
            rows.append((blade, r, [res.get((n, r), (None, None)) for n in ('b_over_D', 'h_over_b', 'beta', 'cl_design')]))
        dev = {n: max([abs(a - b) for (m, r), (a, b) in res.items() if m == n and b is not None] or [float('nan')]) for n in SEEDS[blade]}
        side[blade]['delta_dig'] = dev
        # 2026-11-22 (Phase 156b): the blade root of the case (ISSUE-046) needs the innermost radius at which Fig. 2 prints
        # each curve. Follow every curve inward from mid-span until its ink ends (gaps up to 40 px, a dash gap, are bridged;
        # a longer gap ends it); each end is marked on the overlay (black ring).
        ends = {}
        for name in SEEDS[blade]:
            ri, vi = SEEDS[blade][name][:2]
            ex, ey = follow(g, c, ri, vi, 0.10, max_miss=40)
            ends[name] = dict(r_over_R=round(R(c, float(ex.min())), 4), value=round(CONV[name](V(c, float(ey[ex.argmin()])), blade), 4))
            d.ellipse([ex.min() - 14, ey[ex.argmin()] - 14, ex.min() + 14, ey[ex.argmin()] + 14], outline=(0, 0, 0), width=4)
        side[blade]['inner_ends'] = ends
        print(blade, 'grid residual %.1f / %.1f px; pass A against B, largest:' % (c['rx'], c['ry']), {k: round(v, 4) for k, v in dev.items()})
    f = lambda v: '-' if v is None else '%.4f' % v
    with open(os.path.join(OUT, 'fig2_blade_form.csv'), 'w', newline='\n', encoding='utf-8') as fo:
        fo.write('# Source: NACA Report 1377 (Kurbjun, Vogeley 1958), Fig. 2 (a) tapered and (b) rectangular blade (Hamilton Standard 6547A-6, TN 3417), PDF p. 7 (printed p. 3); references/NACA_Report_1377.pdf\n')
        fo.write('# Method: script, 600 dpi; grid fitted to the 10 x 11 grid lines of each panel; pass A follows each curve both ways from mid-span, pass B inward from the tip; read at r/R 0.30 ... 0.95 from a local straight fit\n')
        fo.write('# Uncertainty: largest difference of the passes per curve is in qa/fig2_pixels.json (delta_dig); one pixel is 0.031 deg of beta, 0.00006 of b/D, 0.0003 of h/b, 0.0006 of c_l\n')
        fo.write('# Digitized 2026-11-15 by Claude; script data/digitizers/dig_r1377_fig2.py; no value typed by hand. Phase 156b\n')
        fo.write('# Conventions: b/D blade width over diameter; h/b thickness over width; beta_deg blade angle as drawn; cl_design section design lift coefficient. "-" = not read at that radius (c_l inboard of r/R 0.40 tapered, 0.60 rectangular, where the rectangular curve meets the top border at 0.50; b/D inboard of 0.40 tapered, where its curve ends at 0.35). Where each curve ends inboard: qa/fig2_pixels.json inner_ends (2026-11-22).\n')
        fo.write('# Panel (a) also has an unlabelled solid line from r/R 0.23 to 0.50 near b/D 0.08, not read here. Inboard parts of some curves are dashed in the print.\n')
        fo.write('blade,r_over_R,b_over_D,h_over_b,beta_deg,cl_design,b_over_D_passB,h_over_b_passB,beta_deg_passB,cl_design_passB\n')
        for blade, r, v in rows:
            fo.write('%s,%.2f,%s,%s\n' % (blade, r, ','.join(f(x[0]) for x in v), ','.join(f(x[1]) for x in v)))
    json.dump(side, open(os.path.join(OUT, 'qa', 'fig2_pixels.json'), 'w', encoding='utf-8'), indent=1)

if __name__ == '__main__':
    main()
