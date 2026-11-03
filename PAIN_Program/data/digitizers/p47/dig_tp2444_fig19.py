"""TP-2444 Fig. 19 (space-averaged interior 1/3-octave spectra, model 2, theta_p = 135 deg, 4000 rpm), PDF page 34 (printed 30).
Pass A: read by eye from zoomed crops with 1 dB guide lines at each band centre (values below).
Pass B: ink runs in the band-centre column (+-2 px); two distinct runs where two exist, the pairing nearest the
previous band; at a local peak (valley) of the pass-B centres the top (bottom) of the ink is taken and moved half
a line width inward.
Usage: python dig_tp2444_fig19.py <native_png> <out.json>
Calibration from the 7 level ticks (90...30 dB) and 9 frequency ticks (25 Hz ... 6300 Hz, every third band)."""
import json, sys, itertools
import numpy as np
from PIL import Image
bands = [25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300]
# pass A by eye: (clockwise solid, reversed dashed), dB
A = [(49.9, 49.9), (47.2, 47.7), (46.9, 47.5), (50.2, 50.4), (56.0, 54.2), (49.5, 50.5), (52.6, 53.8), (58.8, 57.8),
     (69.7, 69.7), (91.0, 91.0), (71.0, 70.7), (60.2, 60.9), (76.0, 74.0), (61.2, 59.8), (68.0, 69.0), (57.7, 57.4),
     (56.4, 51.7), (49.4, 47.9), (43.9, 44.4), (39.9, 40.8), (39.7, 39.8), (39.3, 39.3), (39.7, 39.7), (39.9, 39.9), (40.4, 40.4)]
a = np.array(Image.open(sys.argv[1]).convert("L")) < 128
lt = [560.0, 871.0, 1186.0, 1495.0, 1805.5, 2113.0, 2417.5]
ft = [535, 723, 908.5, 1093, 1284, 1466, 1649.5, 1833, 2018.5]
pl = np.polyfit(lt, [90, 80, 70, 60, 50, 40, 30], 1); pf = np.polyfit(np.arange(0, 25, 3), ft, 1)
half_w = 4.5 * abs(pl[0])                       # half the line width (9 px) in dB
def runs(col):
    r, s = [], None
    for i, v in enumerate(col):
        if v and s is None: s = i
        if not v and s is not None: r.append((s, i - 1)); s = None
    return r
def col_runs(k):
    x = int(round(np.polyval(pf, k))); out = []
    for dx in (-2, 0, 2):
        col = a[480:2400, x + dx].copy()
        if x > 1450: col[:220] = False          # legend
        out += [(np.polyval(pl, r0 + 480), np.polyval(pl, r1 + 480)) for r0, r1 in runs(col) if r1 - r0 >= 3]
    return out                                   # (top dB, bottom dB)
m = lambda r: (r[0] + r[1]) / 2
B = []
prev = [50.0, 50.0]                              # both curves start together at 25 Hz
for k in range(len(bands)):
    rs = col_runs(k)
    pairs = [p for p in itertools.permutations(rs, 2) if abs(m(p[0]) - m(p[1])) > 0.3] or [(rs[0], rs[0])]
    row = list(min(pairs, key=lambda p: abs(m(p[0]) - prev[0]) + abs(m(p[1]) - prev[1])))
    prev = [m(row[0]), m(row[1])]
    B.append(row)
cen = np.array([[m(r) for r in row] for row in B])
Bv = cen.copy()
for k in range(1, len(bands) - 1):
    for c in range(2):
        if cen[k, c] > cen[k - 1, c] and cen[k, c] > cen[k + 1, c]: Bv[k, c] = B[k][c][0] - half_w
        if cen[k, c] < cen[k - 1, c] and cen[k, c] < cen[k + 1, c]: Bv[k, c] = B[k][c][1] + half_w
Aa = np.array(A); d = np.abs(Aa - Bv).ravel()
print("A vs B: median", round(float(np.median(d)), 2), "p95", round(float(np.percentile(d, 95)), 2), "max", round(float(d.max()), 2))
for k, fc in enumerate(bands): print(fc, Aa[k], np.round(Bv[k], 1))
json.dump(dict(bands=bands, A=A, B=Bv.round(2).tolist(), dB_per_px=pl[0], half_line_dB=half_w), open(sys.argv[2], "w"))
