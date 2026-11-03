"""Guided curve tracer for scanned NACA plots (TN 1546 Fig. 3 / TR 824).

Each curve is given as hand-read waypoints (absolute pixel coordinates of the
300-dpi page render). Along the piecewise-linear guide, the tracer snaps to the
nearest ink run (grid lines masked) within +-win px; samples with no ink are
kept as guide values and flagged. Output: per-curve samples on a Mach grid and
a colour overlay for QA.
Usage: python trace.py config.json out_prefix
"""
import json, sys
import numpy as np
from PIL import Image, ImageDraw

cfg = json.load(open(sys.argv[1]))
out = sys.argv[2]
img = Image.open(cfg["image"]).convert("L")
g = np.array(img).astype(float)
dark = g < cfg.get("thr", 150)

def lin(p0, p1):
    (a0, v0), (a1, v1) = p0, p1
    k = (v1 - v0) / (a1 - a0)
    return (lambda px: v0 + k * (px - a0)), (lambda v: a0 + (v - v0) / k)

results = {}
over = Image.open(cfg["image"]).convert("RGB")
dr = ImageDraw.Draw(over)
colors = [(230, 25, 75), (60, 180, 75), (0, 130, 200), (245, 130, 48), (145, 30, 180),
          (70, 200, 200), (240, 50, 230), (128, 128, 0), (0, 0, 128), (170, 110, 40)]

for pan in cfg["panels"]:
    xv, vx = lin(*pan["xcal"])   # px -> M, M -> px
    yv, vy = lin(*pan["ycal"])   # px -> value, value -> px
    m = dark.copy()
    for gy in pan["grid_rows"]:
        m[int(round(gy)) - 3:int(round(gy)) + 4, :] = False
    for gx in pan["grid_cols"]:
        m[:, int(round(gx)) - 3:int(round(gx)) + 4] = False
    win = pan.get("win", 7)
    for ci, cur in enumerate(pan["curves"]):
        if "wpd" in cur:   # waypoints in data units (M, value)
            cur["wp"] = [[vx(M), vy(v)] for M, v in cur["wpd"]]
        wp = np.array(cur["wp"], float)
        xs = np.arange(wp[0, 0], wp[-1, 0] + 1)
        guide = np.interp(xs, wp[:, 0], wp[:, 1])
        ys, src = [], []
        for x, gy in zip(xs.astype(int), guide):
            w = cur.get("win", win)
            col = m[int(gy) - w:int(gy) + w + 1, x - 1:x + 2].any(axis=1)
            idx = np.where(col)[0]
            if idx.size:
                # runs; take run whose centre is nearest the guide
                runs = np.split(idx, np.where(np.diff(idx) > 1)[0] + 1)
                cs = [r.mean() + int(gy) - w for r in runs]
                c = min(cs, key=lambda c: abs(c - gy))
                ys.append(c); src.append("ink")
            else:
                ys.append(gy); src.append("guide")
        ys = np.array(ys)
        # dash gaps: interpolate between neighbouring ink samples (gap <= max_gap px)
        src = np.array(src, dtype=object)
        ink = np.where(src == "ink")[0]
        max_gap = pan.get("max_gap", 45)
        for i in np.where(src == "guide")[0]:
            lo, hi = ink[ink < i], ink[ink > i]
            if lo.size and hi.size and xs[hi[0]] - xs[lo[-1]] <= max_gap:
                ys[i] = np.interp(xs[i], [xs[lo[-1]], xs[hi[0]]], [ys[lo[-1]], ys[hi[0]]])
                src[i] = "interp"
        col = colors[ci % len(colors)]
        for x, y, s in zip(xs, ys, src):
            if s == "guide":
                dr.point((x, y), fill=(255, 200, 0))
            else:
                dr.point((x, y), fill=col)
        for x, y in wp:
            dr.ellipse((x - 4, y - 4, x + 4, y + 4), outline=col, width=2)
        # sample on the Mach grid
        Ms = np.round(np.arange(np.ceil(xv(xs[0]) / 0.01 - 0.2) * 0.01, xv(xs[-1]) + 1e-9, 0.01), 3)
        rows = []
        for M in Ms:
            px = vx(M)
            sel = np.abs(xs - px) <= 2
            if not sel.any():
                continue
            ss = list(src[sel])
            yy = np.median(ys[sel])
            tag = max(("ink", "interp", "guide"), key=ss.count)
            rows.append((float(M), float(yv(yy)), tag))
        results.setdefault(pan["name"], {})[cur["label"]] = rows
over.save(out + "_overlay.png")
json.dump(results, open(out + "_samples.json", "w"), indent=1)
for p, d in results.items():
    for lab, rows in d.items():
        ng = sum(r[2] == "guide" for r in rows)
        ni = sum(r[2] == "interp" for r in rows)
        print(p, lab, len(rows), "samples", ni, "interp", ng, "guide", "M", rows[0][0], "-", rows[-1][0])
