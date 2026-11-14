"""Phase 154a (2026-11-14): digitize NACA Report 996 Fig. 3(c), the NACA 4-(5)(08)-03 blade form (PDF p. 9, lower left).

Run from this folder:  python dig_r996_fig3c.py
Writes data/report996/naca_4-5-08-03/measured/geometry/tr996_fig3c_blade_form.csv, a pixel sidecar, a QA overlay and a
600 dpi spot check under .../measured/geometry/qa/. No value is typed by hand.

Pass A: the grid fitted to all 15 x 21 grid lines; each curve followed column by column from its seed at r/R 0.31; the
value at each labelled r/R gridline from straight fits to the trace beside the gridline (the gridline's own ink hides
the curve on it).
Pass B, a different method that does not use pass A: start from the CR-196702 table's value at the gridline, take the
nearest stroke, fit a line through the raw ink pixels within 40 px of the gridline, and read it against the two
horizontal grid lines located next to the point (not the page-wide fit).
Axes: r/R 0.30 to 1.00 (0.05 per cell); left axis b/D and h/b 0 to 0.20 (0.01 per cell); beta = 32 + 200 x (left
axis value) deg (right axis 32 to 72 deg)."""
import csv, json, os, sys
import numpy as np
import pymupdf
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'r1012_fig5'))
from grid import peaks, regular

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
PDF = os.path.join(ROOT, 'references', 'NASA Report 996.pdf')
TABLE = os.path.join(ROOT, 'data', 'report996', 'naca_4-5-08-03', 'blade_form.csv')
OUT = os.path.join(ROOT, 'data', 'report996', 'naca_4-5-08-03', 'measured', 'geometry')
CROP = (3400, 6250, 250, 2300)                 # rows, columns of panel (c) on the 600 dpi render of PDF p. 9
SEEDS = {'beta': 0.1655, 'h_over_b': 0.1270, 'b_over_D': 0.0920}     # left-axis value at r/R 0.31, from the figure
# Pass B readings checked by eye on the overlay and rejected (§2.2 step 7); the reason is written into the CSV
PASS_B_FLAG = {('beta', 0.70): 'pass B took the b/D stroke where the two lines cross; pass A kept',
               ('b_over_D', 0.70): 'pass B took the beta stroke where the two lines cross'}
STATIONS = {'beta': [round(0.30 + 0.05 * k, 2) for k in range(15)],
            'h_over_b': [round(0.30 + 0.05 * k, 2) for k in range(14)],
            'b_over_D': [round(0.30 + 0.05 * k, 2) for k in range(14)]}   # the steep fall of b/D and h/b at the tip is not read

def render():
    pm = pymupdf.open(PDF)[8].get_pixmap(dpi=600, colorspace=pymupdf.csGRAY)
    g = np.frombuffer(pm.samples, dtype=np.uint8).reshape(pm.height, pm.width).astype(np.float32)
    y0, y1, x0, x1 = CROP
    return g[y0:y1, x0:x1]

def calibrate(g):
    ink = 255 - g
    px = peaks(ink[400:2400, :].mean(0), prom=8, half=20); py = peaks(ink[:, 300:1700].mean(1), prom=8, half=20)
    Ax, ix, kx, rx = regular(px); Ay, iy, ky, ry = regular(py)
    assert len(kx) == 15 and len(ky) == 21, (len(kx), len(ky))
    return dict(x0=float(kx.min()), px=float(Ax[0]), y0=float(ky.max()), py=float(Ay[0]), rx=rx, ry=ry, kx=kx, ky=ky)

def X(c, rr): return c['x0'] + (rr - 0.30) / 0.05 * c['px']
def Y(c, v): return c['y0'] - v / 0.01 * c['py']
def V(c, y): return (c['y0'] - y) / c['py'] * 0.01

def col_runs(ink, x, ylo, yhi, thr=95):
    col = ink[ylo:yhi, x]; d = col > thr; out = []; i = 0
    while i < len(d):
        if d[i]:
            j = i
            while j < len(d) and d[j]: j += 1
            if j - i <= 14:
                w = col[i:j] - 60; out.append(ylo + float((np.arange(i, j) * w).sum() / w.sum()))
            i = j
        else: i += 1
    return out

def trace(g, c, seed):
    ink = 255 - g
    x = int(X(c, 0.31)); y = Y(c, seed)
    y = min(col_runs(ink, x, int(y) - 25, int(y) + 25), key=lambda t: abs(t - y))
    xs, ys, hit = [x], [y], [True]; hx, hy = [x], [y]; miss = 0
    while x < int(X(c, 1.0)) - 3:
        x += 1; k = min(40, len(hx))
        pred = np.polyval(np.polyfit(hx[-k:], hy[-k:], 1), x) if k >= 6 else hy[-1]
        tol = (8.0 if k < 6 else 4.0) + 0.08 * miss          # wider while the slope is not known, and across gaps
        cand = col_runs(ink, x, int(pred) - 14, int(pred) + 14)
        b = min(cand, key=lambda t: abs(t - pred)) if cand else None
        if b is not None and abs(b - pred) < tol:
            xs.append(x); ys.append(b); hit.append(True); hx.append(x); hy.append(b); miss = 0
        else:
            xs.append(x); ys.append(pred); hit.append(False); miss += 1
    return np.array(xs, float), np.array(ys), np.array(hit)

def pass_a(c, xs, ys, hit, rr):
    xg = X(c, rr)
    m = hit & (((xs > xg - 30) & (xs < xg - 5)) | ((xs > xg + 5) & (xs < xg + 30)))
    if rr <= 0.301: m = hit & (xs > xg + 5) & (xs < xg + 40)
    if rr >= 0.999: m = hit & (xs > xg - 40) & (xs < xg - 5)
    A = np.polyfit(xs[m], ys[m], 1)
    return V(c, np.polyval(A, xg)), float(np.polyval(A, xg))

def pass_b(g, c, rr, v_start):
    """independent of pass A: nearest stroke to the table's value, line fit on raw ink, local grid lines"""
    ink = 255 - g
    xg_glob = X(c, rr); k = int(round(xg_glob))
    prof = np.median(ink[int(Y(c, 0.2)):int(Y(c, 0.0)), k - 8:k + 9], axis=0)          # the vertical gridline, located here
    w = np.clip(prof - 20, 0, None); xg = k - 8 + float((np.arange(17) * w).sum() / w.sum())
    y_s = Y(c, v_start); side = (-40, -5) if rr >= 0.999 else ((5, 40) if rr <= 0.301 else None)
    offs = [o for o in range(-40, 41) if 5 <= abs(o)] if side is None else list(range(side[0], side[1] + 1))
    cent = []
    for o in offs:
        x = int(round(xg + o)); r = col_runs(ink, x, int(y_s) - 60, int(y_s) + 60)
        if r: cent.append((o, r))
    # the stroke nearest the start value, followed outwards on both sides
    o0, r0 = min(cent, key=lambda t: abs(t[0]))
    y_near = min(r0, key=lambda t: abs(t - y_s)); pts = []
    for direction in (1, -1):
        last = y_near; seq = sorted([t for t in cent if t[0] * direction > 0], key=lambda t: abs(t[0]))
        for o, r in seq:
            b = min(r, key=lambda t: abs(t - last))
            if abs(b - last) < 6: pts.append((o, b)); last = b
    P = np.array(pts, float)
    pix = []
    for o, yc in P:                                           # raw ink pixels around the stroke
        x = int(round(xg + o))
        for yy in range(int(yc) - 5, int(yc) + 6):
            if ink[yy, x] > 80: pix.append((o, yy, ink[yy, x] - 60))
    Q = np.array(pix, float); wts = Q[:, 2]; m = (Q[:, :2] * wts[:, None]).sum(0) / wts.sum()
    C = ((Q[:, :2] - m) * wts[:, None]).T @ (Q[:, :2] - m); ev, vec = np.linalg.eigh(C); d = vec[:, 1]
    y_at = m[1] + d[1] / d[0] * (0 - m[0])
    # local horizontal grid lines above and below
    strip = [x for x in range(int(xg) - 60, int(xg) + 61) if abs(x - xg) > 6]
    rows = np.median(ink[int(y_at) - 140:int(y_at) + 141, strip], axis=1)
    lines = []
    for j in range(2, len(rows) - 2):
        if rows[j] == rows[j - 2:j + 3].max() and rows[j] > 25:
            ww = np.clip(rows[j - 2:j + 3] - 10, 0, None); lines.append(int(y_at) - 140 + j - 2 + float((np.arange(5) * ww).sum() / ww.sum()))
    above = max([l for l in lines if l <= y_at], default=None); below = min([l for l in lines if l > y_at], default=None)
    i_b = round(V(c, below) / 0.01); i_a = round(V(c, above) / 0.01)
    return 0.01 * (i_b + (i_a - i_b) * (below - y_at) / (below - above))

def main():
    os.makedirs(os.path.join(OUT, 'qa'), exist_ok=True)
    g = render(); c = calibrate(g)
    tab = list(csv.DictReader(open(TABLE)))
    tr = np.array([float(q['r_over_R']) for q in tab])
    tcol = {'beta': np.array([(float(q['beta_deg']) - 32) / 200 for q in tab]),
            'h_over_b': np.array([float(q['t_over_c']) for q in tab]),
            'b_over_D': np.array([float(q['c_over_R']) / 2 for q in tab])}
    res = {}; traces = {}
    for name, seed in SEEDS.items():
        xs, ys, hit = trace(g, c, seed); traces[name] = (xs, ys)
        for rr in STATIONS[name]:
            vA, yA = pass_a(c, xs, ys, hit, rr)
            vB = pass_b(g, c, rr, float(np.interp(rr, tr, tcol[name])))
            res[(name, rr)] = (vA, vB, yA)
    im = Image.fromarray(g.astype('uint8')).convert('RGB'); d = ImageDraw.Draw(im)
    col = {'beta': (255, 0, 0), 'h_over_b': (0, 150, 0), 'b_over_D': (0, 0, 255)}
    for name, (xs, ys) in traces.items(): d.line(list(zip(xs + 6, ys)), fill=col[name], width=1)
    for (name, rr), (vA, vB, yA) in res.items():
        x = X(c, rr); d.ellipse([x - 9, yA - 9, x + 9, yA + 9], outline=col[name], width=3)
    im.resize((im.width // 2, im.height // 2)).save(os.path.join(OUT, 'qa', 'tr996_fig3c_overlay.png'))
    dev = {n: max(abs(res[(n, rr)][0] - res[(n, rr)][1]) for rr in STATIONS[n] if (n, rr) not in PASS_B_FLAG) for n in SEEDS}
    with open(os.path.join(OUT, 'tr996_fig3c_blade_form.csv'), 'w', newline='\n', encoding='utf-8') as f:
        f.write('# Source: NACA Report 996 (Hicks, Hubbard 1947), Fig. 3(c) NACA 4-(5)(08)-03 propeller, PDF p. 9 (printed p. 5); references/NASA Report 996.pdf\n')
        f.write('# Method: script, 600 dpi; grid fitted to all 15 x 21 grid lines (residual %.1f / %.1f px; one cell 0.05 r/R = %.1f px, 0.01 = %.1f px). Pass A: curve followed column by column, read beside each gridline. Pass B: independent, from the table value, line fit on raw ink, local grid lines\n' % (c['rx'], c['ry'], c['px'], c['py']))
        f.write('# Uncertainty: passes A and B differ by at most %.2f deg in beta, %.4f in h/b, %.4f in b/D (delta_dig, without the flagged pass-B readings); one pixel is %.3f deg of beta. beta_deg is pass A\n' % (200 * dev['beta'], dev['h_over_b'], dev['b_over_D'], 200 * 0.01 / c['py']))
        f.write('# Digitized 2026-11-14 by Claude; script data/digitizers/dig_r996_fig3c.py; no value typed by hand. Phase 154a\n')
        f.write('# Conventions: r/R blade station; beta_deg section blade angle at the design setting (right axis of the figure); b/D blade width over diameter; h/b thickness over width. The fall of b/D and h/b at the tip (r/R > 0.95) is not read\n')
        f.write('r_over_R,beta_deg,beta_deg_passB,h_over_b,h_over_b_passB,b_over_D,b_over_D_passB,note\n')
        for rr in STATIONS['beta']:
            row = [rr, 32 + 200 * res[('beta', rr)][0], 32 + 200 * res[('beta', rr)][1]]
            for n in ('h_over_b', 'b_over_D'):
                row += list(res[(n, rr)][:2]) if (n, rr) in res else [float('nan'), float('nan')]
            note = '; '.join(PASS_B_FLAG[(n, rr)] for n in ('beta', 'h_over_b', 'b_over_D') if (n, rr) in PASS_B_FLAG) or '-'
            f.write('%.2f,%.3f,%.3f,%s,%s\n' % (row[0], row[1], row[2], ','.join('-' if np.isnan(v) else '%.4f' % v for v in row[3:]), note))
    json.dump({'crop_rows_cols': CROP, 'calibration': {k: (float(v) if not hasattr(v, 'tolist') else v.tolist()) for k, v in c.items()},
               'points': [{'curve': n, 'r_over_R': rr, 'y_px_passA': round(res[(n, rr)][2], 1), 'x_px': round(X(c, rr), 1)} for (n, rr) in res]},
              open(os.path.join(OUT, 'qa', 'tr996_fig3c_pixels.json'), 'w', encoding='utf-8'), indent=1)
    pm = pymupdf.open(PDF)[8].get_pixmap(dpi=600); full = Image.frombytes('RGB', (pm.width, pm.height), pm.samples); tiles = []
    for n, rr in (('beta', 0.95), ('beta', 0.60), ('h_over_b', 0.80)):
        x = X(c, rr) + CROP[2]; y = res[(n, rr)][2] + CROP[0]; dd = ImageDraw.Draw(full)
        dd.line([x - 40, y, x - 14, y], fill=(255, 0, 0), width=2); dd.line([x + 14, y, x + 40, y], fill=(255, 0, 0), width=2)
        tiles.append(full.crop((int(x) - 150, int(y) - 150, int(x) + 150, int(y) + 150)))
    m = Image.new('RGB', (900, 300), 'white')
    for i, t in enumerate(tiles): m.paste(t, (300 * i, 0))
    m.save(os.path.join(OUT, 'qa', 'tr996_fig3c_spot_check_600dpi.png'))
    print('calibration residual %.2f / %.2f px; delta_dig beta %.3f deg, h/b %.4f, b/D %.4f' % (c['rx'], c['ry'], 200 * dev['beta'], dev['h_over_b'], dev['b_over_D']))
    print('r/R   beta A   beta B   table  |  h/b A   table  |  b/D A   table')
    for rr in STATIONS['beta']:
        line = '%.2f  %6.2f  %6.2f  %6.2f' % (rr, 32 + 200 * res[('beta', rr)][0], 32 + 200 * res[('beta', rr)][1], 32 + 200 * np.interp(rr, tr, tcol['beta']))
        for n in ('h_over_b', 'b_over_D'):
            line += '  |  %.4f  %.4f' % (res[(n, rr)][0], np.interp(rr, tr, tcol[n])) if (n, rr) in res else '  |    -       -   '
        print(line)

if __name__ == '__main__':
    main()
