"""Column-wise trace extraction of a plotted spectrum (Phase 47a).
trace(img_bool, x0px, x1px, y_top, y_bot, f_of_x, L_of_y, exclude=[(x0,x1,y0,y1)...], rule="center"|"top")
Returns a list of (f_Hz, L_dB, L_top_dB, L_bottom_dB) for every column with trace ink, choosing the dark run nearest
the previous one; L_dB is the run centre ("center") or its top ("top").
"""
import numpy as np

def runs(col):
    r, s = [], None
    for i, v in enumerate(col):
        if v and s is None: s = i
        if not v and s is not None: r.append((s, i - 1)); s = None
    if s is not None: r.append((s, len(col) - 1))
    return r

def trace(a, x0, x1, ytop, ybot, f_of_x, L_of_y, exclude=(), rule="center"):
    out = []; prev = None
    for x in range(int(x0), int(x1)):
        col = a[int(ytop):int(ybot), x].copy()
        for (ex0, ex1, ey0, ey1) in exclude:
            if ex0 <= x <= ex1:
                col[max(0, int(ey0 - ytop)):max(0, int(ey1 - ytop))] = False
        rr = runs(col)
        if not rr: continue
        if prev is None:
            r = max(rr, key=lambda r: r[1] - r[0])
        else:
            r = min(rr, key=lambda r: min(abs(r[0] - prev), abs(r[1] - prev)))
        y = (r[0] + r[1]) / 2 if rule == "center" else r[0]
        prev = (r[0] + r[1]) / 2
        out.append((f_of_x(x), L_of_y(y + ytop), L_of_y(r[0] + ytop), L_of_y(r[1] + ytop)))
    return out
