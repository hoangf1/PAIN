"""Digitize CR-172428 Fig. 14 (free-field propeller noise spectrum, Mic 1, Run 8113, 5000 rpm).
Usage: python dig_cr172428_fig14.py <native_png> <upscale> <rule> <out_prefix>
The page image is turned 90 deg clockwise so frequency runs left to right and level upward.
Search windows are in native (rotated) pixels: level axis near x 590 with inward ticks every 5 dB
(130 at top ... 70), frequency axis drawn separately near y 2060 with upward ticks every 200 Hz (0 ... 2000)."""
import sys, json, os
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from trace_columns import trace
png, up, rule, outp = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
im = Image.open(png).convert("L").rotate(-90, expand=True)
if up != 1:
    im = im.resize((im.width * up, im.height * up), Image.LANCZOS)
a = np.array(im) < 128
s = up
def groups(idx, gap):
    g = []
    for i in idx:
        if g and i - g[-1][-1] <= gap: g[-1].append(i)
        else: g.append([i])
    return [(x[0] + x[-1]) / 2 for x in g]
c = a[300 * s:2000 * s].mean(axis=0)
ax = int(np.argmax(c[550 * s:650 * s])) + 550 * s
xr = ax
while c[xr + 1] > 0.3: xr += 1
lt = groups([i for i in range(400 * s, 2000 * s) if a[i, xr + 4 * s:xr + 16 * s].mean() > 0.5], 3 * s)
ft = groups([j for j in range(700 * s, 2800 * s) if a[2030 * s:2042 * s, j].mean() > 0.6], 3 * s)
assert len(lt) == 13 and len(ft) == 11, (lt, ft)
Lt, Ft = np.arange(130, 69, -5), np.arange(0, 2001, 200)
pl = np.polyfit(lt, Lt, 1); pf = np.polyfit(ft, Ft, 1)
res_L = float(np.max(np.abs(np.polyval(pl, lt) - Lt))); res_f = float(np.max(np.abs(np.polyval(pf, ft) - Ft)))
f_of_x = lambda x: pf[0] * x + pf[1]
L_of_y = lambda y: pl[0] * y + pl[1]
ex = [(2040 * s, 2280 * s, 720 * s, 880 * s)]          # "RUN 8113 / 5000 RPM" label
tr = trace(a, ft[0], ft[-1] + 1, lt[0] - 10 * s, 2025 * s, f_of_x, L_of_y, ex, rule)
# the trace ends near 1981 Hz; columns after the first gap > 5 Hz near the end are the 2000 Hz axis tick
gaps = [i for i in range(1, len(tr)) if tr[i][0] - tr[i - 1][0] > 5 and tr[i][0] > 1900]
if gaps: tr = tr[:gaps[0]]
json.dump(dict(trace=tr, calib=dict(level_ticks=lt, freq_ticks=ft, rule=rule, upscale=up,
          max_tick_residual_dB=res_L, max_tick_residual_Hz=res_f)), open(outp + ".json", "w"))
print("cols", len(tr), "Hz/px", round(pf[0], 4), "dB/px", round(pl[0], 4), "tick residual dB", round(res_L, 3), "Hz", round(res_f, 2))
