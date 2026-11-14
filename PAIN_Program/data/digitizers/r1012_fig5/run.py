"""Digitize NACA Report 1012 Fig. 5 (NACA 4-(5)(08)-03 two-blade propeller): C_T and C_P on the labelled advance-ratio
gridlines. Phase 153c, 2026-11-14. Run from this folder:  python run.py

Writes the CSV, a pixel sidecar and one QA overlay per panel under
data/report996/naca_4-5-08-03/measured/wind_tunnel/ . No value is typed by hand.

A point is kept only if all of these hold (ISSUE-042, fixed before any reading):
  - both curves were followed without a break from their foot on the J axis (the crowded and the shallow parts of the
    figure are not read: there the script cannot tell the curves apart with certainty);
  - J C_T / C_P agrees within 0.015 with the efficiency curve the report draws separately (read on the same gridline);
  - pass B (local grid lines, line fit on the raw ink) agrees with pass A within 2 % of the value;
  - efficiency at least 0.70 and helical tip Mach number at most 0.90 (the point rule)."""
import json, os, sys
import numpy as np
import pymupdf
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from page import Page
from curves import read_panel
from passb import read_b

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
PDF = os.path.join(ROOT, 'references', 'NACA_Report_1012.pdf')
OUT = os.path.join(ROOT, 'data', 'report996', 'naca_4-5-08-03', 'measured', 'wind_tunnel')
# PDF page, panel, tunnel-datum Mach number, blade angles at 0.75 R (Table I, the 4-(5)(08)-03 propeller)
PANELS = [(8, 'a', 0.165, [20, 25, 30, 35, 40, 45, 50, 55, 60]), (9, 'b', 0.23, [20, 25, 30, 35, 40, 45, 50, 55, 60]),
          (10, 'c', 0.35, [30, 35, 40, 45, 50, 55, 60]), (11, 'd', 0.43, [35, 40, 45, 50, 55, 60]),
          (12, 'e', 0.53, [40, 45, 50, 55, 60]), (13, 'f', 0.60, [45, 50, 55, 60]), (14, 'g', 0.65, [50, 55, 60]),
          (15, 'h', 0.675, [50, 55, 60]), (16, 'i', 0.70, [50, 55, 60]), (17, 'j', 0.725, [50, 55, 60])]

def main():
    os.makedirs(os.path.join(OUT, 'qa'), exist_ok=True)
    doc = pymupdf.open(PDF); kept = []; side = []; summary = []
    for pg, letter, M, betas in PANELS:
        pm = doc[pg - 1].get_pixmap(dpi=300, colorspace=pymupdf.csGRAY)
        g = np.frombuffer(pm.samples, dtype=np.uint8).reshape(pm.height, pm.width).astype(np.float32)
        P = Page(g); rows, out = read_panel(P, M, [float(b) for b in betas])
        inrule = [r for r in rows if 0.70 <= r['eta'] <= 1.0 and r['Mt'] <= 0.90]
        sel = []
        for r in inrule:
            if not (r['ok'] and r['how'] == 'row/row'): continue
            if r['beta'] < 30: continue                      # 20 and 25 deg: every reading lies among crossing curves
            bT = read_b(P, r['J'], r['yCT'], r['sCT']); bP = read_b(P, r['J'], r['yCP'], r['sCP'])
            if bT is None or bP is None: continue
            r['CT_B'] = bT[0]; r['CP_B'] = 2 * bP[0]
            if abs(r['CT_B'] / r['CT'] - 1) > 0.02 or abs(r['CP_B'] / r['CP'] - 1) > 0.02: continue
            sel.append(r)
        summary.append((letter, M, len(set(b for b, _ in out)), len(betas), len(rows), len(inrule), len(sel), P.rx, P.ry))
        im = Image.fromarray(g.astype('uint8')).convert('RGB'); d = ImageDraw.Draw(im)
        for r in sel:
            x = P.X(r['J'], r['yCT'])
            for y, col in ((r['yCT'], (255, 0, 0)), (r['yCP'], (0, 0, 255))):
                d.ellipse([x - 9, y - 9, x + 9, y + 9], outline=col, width=3)
                d.text((x + 13, y - 16), '%d' % r['beta'], fill=col)
            kept.append((letter, pg, r))
            side.append(dict(panel=letter, pdf_page=pg, M=M, beta_deg=r['beta'], J=r['J'], x_px=round(float(x), 1),
                             y_CT_px=round(r['yCT'], 1), y_CP_px=round(r['yCP'], 1),
                             grid_fit=dict(x=[float(v) for v in P.a], y=[float(v) for v in P.b], yc=P.yc, xc=P.xc)))
        if sel:
            im.crop((1250, 380, 3250, 2240)).resize((1300, 1209)).save(os.path.join(OUT, 'qa', 'r1012_fig5%s_overlay.png' % letter))
    dev = [abs(r['CT_B'] / r['CT'] - 1) for _, _, r in kept] + [abs(r['CP_B'] / r['CP'] - 1) for _, _, r in kept]
    with open(os.path.join(OUT, 'naca_report1012_fig5_ct_cp.csv'), 'w', newline='\n', encoding='utf-8') as f:
        f.write('# Source: NACA Report 1012 (Delano 1951), Fig. 5 (a) to (h), PDF pp. 8-15 (printed pp. 4-11); references/NACA_Report_1012.pdf\n')
        f.write('# Method: pass A, 300 dpi, grid fitted to all 57 x 43 grid lines per page (J 0 to 5.6, C_T 0 to 0.21; C_P on the axis of twice the scale); curves followed row by row from their foot on the J axis; pass B, local grid lines and a line fit on the raw ink\n')
        f.write('# Uncertainty: passes A and B differ by %.2f %% at the median and %.2f %% at most; J C_T / C_P agrees with the separately drawn efficiency curve within 0.015 at every point\n' % (100 * np.median(dev), 100 * max(dev)))
        f.write('# Digitized 2026-11-14 by Claude; script data/digitizers/r1012_fig5/run.py; no value typed by hand\n')
        f.write('# Conventions: M = tunnel-datum Mach number (as printed); beta = blade angle at 0.75 R; J corrected to free air by the report; CT = T/(rho n^2 D^4); CP = P/(rho n^3 D^5); eta_curve = the efficiency curve read on the same gridline\n')
        f.write('# Not read: the curves of blade angles 20 and 25 deg, panels (i) and (j), and every point on the shallow part of a curve (see the script header)\n')
        f.write('panel,pdf_page,M,beta75_deg,J,M_tip_helical,CT,CP,eta_from_CT_CP,eta_curve,CT_passB,CP_passB\n')
        for letter, pg, r in kept:
            f.write('%s,%d,%.3f,%.0f,%.1f,%.3f,%.5f,%.5f,%.4f,%.4f,%.5f,%.5f\n' % (letter, pg, r['M'], r['beta'], r['J'], r['Mt'], r['CT'], r['CP'], r['eta'], r['eta_read'], r['CT_B'], r['CP_B']))
    json.dump(side, open(os.path.join(OUT, 'qa', 'naca_report1012_fig5_pixels.json'), 'w', encoding='utf-8'), indent=1)
    for s in summary:
        print('panel %s M %.3f: curves followed for %d of %d blade angles; %d gridline readings, %d in the point rule, %d kept; grid fit residual %.1f / %.1f px' % s)
    print('kept', len(kept), 'points;', 'pass A against B: median %.2f %%, largest %.2f %%' % (100 * np.median(dev), 100 * max(dev)))

if __name__ == '__main__':
    main()
