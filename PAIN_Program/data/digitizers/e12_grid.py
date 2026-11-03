"""Grid overlay for pass B: lines every 0.1 X3/D (labelled every 0.2) and every 2 dB (labelled every 4), per panel."""
import sys, fitz
sys.path.insert(0, 'data/digitizers')
from e12_common import to_px
d = fitz.open('references/Pain Methodology.pdf'); p = d[135]; k = 72/300
rng = {1: (98, 134), 2: (82, 128), 3: (78, 120)}
for h, (lo, hi) in rng.items():
    for i in range(-10, 9):
        X = i/10
        x0, y0 = to_px(h, X, lo); x1, y1 = to_px(h, X, hi)
        p.draw_line(fitz.Point(x0*k, y0*k), fitz.Point(x1*k, y1*k), color=(0.2, 0.4, 1), width=0.25 if i % 2 else 0.5)
        if i % 2 == 0: p.insert_text(fitz.Point(x1*k-6, y1*k-2), f"{X:g}", fontsize=6, color=(0.2, 0.4, 1))
    for v in range(lo, hi+1, 2):
        xa, ya = to_px(h, 0.95, v); xb, yb = to_px(h, -1.0, v)
        p.draw_line(fitz.Point(xa*k, ya*k), fitz.Point(xb*k, yb*k), color=(0.2, 0.4, 1), width=0.25 if v % 4 else 0.5)
        if v % 4 == 0: p.insert_text(fitz.Point(xb*k+1, yb*k-1), str(v), fontsize=6, color=(0.2, 0.4, 1))
d_ = {1: fitz.Rect(150, 75, 440, 285), 2: fitz.Rect(150, 285, 440, 470), 3: fitz.Rect(150, 465, 440, 650)}
for h, r in d_.items():
    p.get_pixmap(dpi=200, clip=r).save(f'data/cr3813/e12/qa_grid_panel{h}.png')
