"""Digitize TP-2444 Fig. 17 (exterior and interior narrowband spectra, model 2, 4000 rpm).
Usage: python dig_tp2444_fig17.py <png> <scale> <rule> <out_prefix>
scale = pixels per 300-dpi pixel (1 for the native image, 2 for a 600-dpi render).
Axis calibration from the tick marks found in the image (inside ticks right of the left axis,
ticks above the bottom axes)."""
import sys, json
import numpy as np
from PIL import Image
sys.path.insert(0, __import__("os").path.dirname(__file__))
from trace_columns import trace

png, scale, rule, outp = sys.argv[1], float(sys.argv[2]), sys.argv[3], sys.argv[4]
a = np.array(Image.open(png).convert("L")) < 128
s = scale

def groups(idx, gap):
    g = []
    for i in idx:
        if g and i - g[-1][-1] <= gap: g[-1].append(i)
        else: g.append([i])
    return [(x[0] + x[-1]) / 2 for x in g]

# left axis column: the longest dark vertical run in x < 0.4 width
cols = a.mean(axis=0)
axis_x = int(np.argmax(cols[: int(0.4 * a.shape[1])]))
# axis is several px wide: find its right edge
xr = axis_x
while a[:, xr + 1].mean() > 0.2: xr += 1
yt = groups([i for i in range(int(300 * s), int(2700 * s)) if a[i, xr + int(3 * s):xr + int(27 * s)].mean() > 0.6], int(2 * s))
# bottom axes: long horizontal rows
rows = a.mean(axis=1)
hrows = groups([i for i in range(a.shape[0]) if rows[i] > 0.35], int(3 * s))
ext_bottom, int_bottom = [r for r in hrows if r > 1000 * s][:2]
def xt_near(rowc):
    r0 = int(rowc - 30 * s); r1 = int(rowc - 6 * s)
    return groups([j for j in range(int(600 * s), int(2300 * s)) if a[r0:r1, j].mean() > 0.6], int(2 * s))
xt = [x for x in xt_near(ext_bottom) if x > axis_x - 5 * s]
# x ticks: 0, 500, 1000, 1500 Hz
x0px, x1500 = xt[0], xt[-1]
f_of_x = lambda x: (x - x0px) * 1500.0 / (x1500 - x0px)
ext_ticks = [y for y in yt if y < ext_bottom + 5 * s]       # 130 ... 60 dB (8 ticks)
int_ticks = [y for y in yt if y > ext_bottom + 50 * s]      # 100 ... 20 dB (5 ticks)
assert len(ext_ticks) == 8 and len(int_ticks) == 5, (ext_ticks, int_ticks)
pe = np.polyfit(ext_ticks, [130, 120, 110, 100, 90, 80, 70, 60], 1)
pi = np.polyfit(int_ticks, [100, 80, 60, 40, 20], 1)
Le = lambda y: pe[0] * y + pe[1]
Li = lambda y: pi[0] * y + pi[1]
# label boxes ("Exterior spectrum", "Interior spectrum") excluded
ex_lab = [(1540 * s, 1925 * s, 935 * s, 1005 * s)]
in_lab = [(1540 * s, 1925 * s, 2190 * s, 2260 * s)]
X0 = xr + int(4 * s); X1 = int(x1500)
ext = trace(a, X0, X1, ext_ticks[0] - 10 * s, ext_bottom - 3 * s, f_of_x, Le, ex_lab, rule)
inn = trace(a, X0, X1, int_ticks[0] - 10 * s, int_bottom - 3 * s, f_of_x, Li, in_lab, rule)
json.dump(dict(ext=ext, int=inn, calib=dict(x0px=x0px, x1500=x1500, ext_ticks=ext_ticks, int_ticks=int_ticks,
          axis_x=axis_x, rule=rule, scale=scale)), open(outp + ".json", "w"))
print("cols ext", len(ext), "int", len(inn), "x0", x0px, "x1500", x1500, "dB/px ext", round(pe[0], 4), "int", round(pi[0], 4))
