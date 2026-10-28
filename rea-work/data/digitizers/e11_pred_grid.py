"""QA overlays for digitizing the Fig. E-11 *predicted* (solid) line (plan A3b, registered 2026-10-28).
mode A: a vertical line at every grid station (labelled k) and horizontal lines every 1 dB (labelled every 5);
mode B: lines every 0.1 X3/D and every 2 dB, as e12_grid.py. Writes data/cr3813/e11_pred/qa_<mode>_panel<h>.png.
Run from rea-work: python data/digitizers/e11_pred_grid.py A|B"""
import sys
sys.path.insert(0, 'data/digitizers')
import fitz
from e11_common import to_px, page, STATIONS
mode = sys.argv[1]
d, p = page()
k = 72 / 300
rng = {1: (96, 132), 2: (86, 124), 3: (80, 114)}
blue = (0.2, 0.4, 1)
for h, (lo, hi) in rng.items():
    xs = [(s, f"k{8 - round(s * 18 * 0.762 / (3.141592653589793 * 0.508))}") for s in STATIONS] if mode == 'A' \
        else [(i / 10, f"{i / 10:g}") for i in range(-10, 10)]
    for j, (X, lab) in enumerate(xs):
        x0, y0 = to_px(h, X, lo); x1, y1 = to_px(h, X, hi)
        p.draw_line(fitz.Point(x0 * k, y0 * k), fitz.Point(x1 * k, y1 * k), color=blue, width=0.3)
        if mode == 'A' or j % 2 == 0:
            p.insert_text(fitz.Point(x1 * k - 5, y1 * k - 2), lab, fontsize=5, color=blue)
    step = 1 if mode == 'A' else 2
    for v in range(lo, hi + 1, step):
        major = v % (5 if mode == 'A' else 4) == 0
        xa, ya = to_px(h, 0.98, v); xb, yb = to_px(h, -1.0, v)
        p.draw_line(fitz.Point(xa * k, ya * k), fitz.Point(xb * k, yb * k), color=blue, width=0.45 if major else 0.15)
        if major:
            p.insert_text(fitz.Point(xb * k + 1, yb * k - 1), str(v), fontsize=5, color=blue)
clip = {1: (90, 300), 2: (305, 470), 3: (480, 640)}
for h, (y0, y1) in clip.items():
    p.get_pixmap(dpi=260, clip=fitz.Rect(130, y0, 445, y1)).save(f'data/cr3813/e11_pred/qa_{mode}_panel{h}.png')
print('wrote', mode)
