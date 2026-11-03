import sys, csv, fitz
sys.path.insert(0, 'data/digitizers')
from e12_common import to_px
tag = sys.argv[1]
d = fitz.open('references/Pain Methodology.pdf'); p = d[135]
k = 72/300
for kind, col in (('measured', (1, 0, 0)), ('predicted', (0, 0.6, 0))):
    for r in csv.DictReader(l for l in open(f'data/cr3813/e12/e12_{kind}_{tag}.csv') if not l.startswith('#')):
        px, py = to_px(int(r['harmonic']), float(r['X3_over_D']), float(r['SPL_dB']))
        p.draw_circle(fitz.Point(px*k, py*k), 2.2, color=col, width=0.8)
p.get_pixmap(dpi=300).save(f'data/cr3813/e12/qa_overlay_{tag}.png')
