"""ISSUE-043 (2026-11-14): read the loaded part of NACA Report 1012 Fig. 5, the points of ISSUE-042's point rule that
run.py could not read. Run from this folder:  python run_loaded.py

Writes naca_report1012_fig5_ct_cp_loaded.csv, a pixel sidecar and overlays (every candidate numbered) under
data/report996/naca_4-5-08-03/measured/wind_tunnel/. The script locates every value; the eye only rejects a candidate
whose curve identity is wrong on the overlay (REJECT below, with the reason). No value is typed by hand."""
import json, os, sys
import numpy as np
import pymupdf
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from page import Page
from curves import assemble, col_cross
from follow import follow, cross
from passb import read_b
from run import PANELS, PDF, OUT

# Curve identity rejected by eye on the overlays (panel, blade angle, J): reason. Filled after looking, before any load.
REJECT = {
    ('b', 30, 1.2): 'curves of neighbouring blade angles cross at this gridline; at 600 dpi the solid line at the 30 deg C_P position may be the 25 deg curve',
    ('b', 35, 1.2): 'read at the same crossing as the 30 deg C_T; identity not confirmed',
    ('b', 40, 1.8): 'the 40 deg C_T and C_P cross on this gridline; which stroke is which cannot be told',
    ('b', 55, 2.4): 'the 55 deg C_T touches the 50 deg C_P on this gridline',
}

def have38():
    s = set()
    for l in open(os.path.join(OUT, 'naca_report1012_fig5_ct_cp.csv'), encoding='utf-8'):
        w = l.split(',')
        if len(w) > 5 and w[0] in 'abcdefghij' and len(w[0]) == 1: s.add((w[0], int(w[3]), float(w[4])))
    return s

def main():
    done = have38(); doc = pymupdf.open(PDF); cands = []; side = []
    for pg, letter, M, betas in PANELS:
        pm = doc[pg - 1].get_pixmap(dpi=300, colorspace=pymupdf.csGRAY)
        g = np.frombuffer(pm.samples, dtype=np.uint8).reshape(pm.height, pm.width).astype(np.float32)
        P = Page(g); out, pairs, T = assemble(P, [float(b) for b in betas], Mach=M)
        paths = {}
        for t in T:
            if 'beta' not in t or t['beta'] < 30: continue
            fx, fy = follow(P, t['x'], t['y'])
            px = np.concatenate([fx[::-1], t['x'][1:]]); py = np.concatenate([fy[::-1], t['y'][1:]])   # top end first
            paths[(t['beta'], t['name'])] = (px, py)
        im = Image.fromarray(g.astype('uint8')).convert('RGB'); d = ImageDraw.Draw(im)
        for (b, name), (px, py) in paths.items():
            col = (255, 0, 0) if name == 'CT' else (0, 0, 255)
            d.line(list(zip(px + 7, py)), fill=col + (0,), width=1)
        for b in sorted(set(k[0] for k in paths)):
            if (b, 'CT') not in paths or (b, 'CP') not in paths: continue
            for k in range(1, 29):
                J = round(0.2 * k, 1)
                if (letter, int(b), J) in done: continue
                cT = cross(P, *paths[(b, 'CT')], J); cP = cross(P, *paths[(b, 'CP')], J)
                if cT is None or cP is None or abs(cT[0] - cP[0]) < 5: continue
                inner = all(np.any(qx < P.X(J, c[0]) - 8) and np.any(qx > P.X(J, c[0]) + 8)
                            for (qx, qy), c in ((paths[(b, 'CT')], cT), (paths[(b, 'CP')], cP)))   # ink on both sides of the gridline
                x = P.X(J, cT[0]); CT = P.value(x, cT[0])[1]; CP = 2 * P.value(P.X(J, cP[0]), cP[0])[1]
                if CT <= 0.004 or CP <= 0: continue
                eta = J * CT / CP; Mt = M * np.sqrt(1 + (np.pi / J) ** 2)
                if not (0.70 <= eta <= 1.0 and Mt <= 0.90): continue
                er = [v / 0.05 for (v, s, n, y, spx, cov) in col_cross(P, J) if abs(y - cT[0]) > 3 and abs(y - cP[0]) > 3]
                near = min(er, key=lambda e: abs(e - eta)) if er else float('nan')
                bT = read_b(P, J, cT[0], cT[1]); bP = read_b(P, J, cP[0], cP[1])
                r = dict(panel=letter, page=pg, M=M, beta=int(b), J=J, CT=CT, CP=CP, eta=eta, eta_curve=near, Mt=Mt,
                         CT_B=bT[0] if bT else float('nan'), CP_B=2 * bP[0] if bP else float('nan'), yCT=cT[0], yCP=cP[0], x=x)
                r['n'] = len(cands) + 1
                r['eta_ok'] = bool(er) and abs(near - eta) <= 0.015
                r['B_ok'] = bool(bT and bP) and abs(r['CT_B'] / CT - 1) <= 0.02 and abs(r['CP_B'] / CP - 1) <= 0.02
                r['reject'] = REJECT.get((letter, int(b), J), '') or ('' if inner else 'the curve ends within 8 px of the gridline')
                cands.append(r)
                ok = r['eta_ok'] and r['B_ok'] and not r['reject']
                for y, col in ((r['yCT'], (255, 0, 0)), (r['yCP'], (0, 0, 255))):
                    if ok: d.ellipse([x - 9, y - 9, x + 9, y + 9], outline=col, width=3)
                    else: d.line([x - 7, y - 7, x + 7, y + 7], fill=col, width=3); d.line([x - 7, y + 7, x + 7, y - 7], fill=col, width=3)
                    d.text((x + 12, y - 16), '#%d %d' % (r['n'], b), fill=col)
        im.crop((700, 380, 3320, 2240)).save(os.path.join(OUT, 'qa', 'r1012_fig5%s_loaded_overlay.png' % letter))
    keep = [r for r in cands if r['eta_ok'] and r['B_ok'] and not r['reject']]
    dev = [abs(r['CT_B'] / r['CT'] - 1) for r in keep] + [abs(r['CP_B'] / r['CP'] - 1) for r in keep]
    with open(os.path.join(OUT, 'naca_report1012_fig5_ct_cp_loaded.csv'), 'w', newline='\n', encoding='utf-8') as f:
        f.write('# Source: NACA Report 1012 (Delano 1951), Fig. 5, PDF pp. 8-17; references/NACA_Report_1012.pdf. The loaded part: points of ISSUE-042\'s point rule not in naca_report1012_fig5_ct_cp.csv\n')
        f.write('# Method: as naca_report1012_fig5_ct_cp.csv, and each curve followed beyond the row trace along its own direction (follow.py); curve identity checked by eye on the overlays (rejections listed in run_loaded.py)\n')
        f.write('# Uncertainty: passes A and B differ by %.2f %% at the median and %.2f %% at most; J C_T / C_P agrees with the separately drawn efficiency curve within 0.015 at every point\n' % (100 * np.median(dev) if dev else 0, 100 * max(dev) if dev else 0))
        f.write('# Digitized 2026-11-14 by Claude for ISSUE-043 (a diagnostic, no verdict); script data/digitizers/r1012_fig5/run_loaded.py; no value typed by hand\n')
        f.write('# Conventions: as naca_report1012_fig5_ct_cp.csv\n')
        f.write('panel,pdf_page,M,beta75_deg,J,M_tip_helical,CT,CP,eta_from_CT_CP,eta_curve,CT_passB,CP_passB\n')
        for r in keep:
            f.write('%s,%d,%.3f,%d,%.1f,%.3f,%.5f,%.5f,%.4f,%.4f,%.5f,%.5f\n' % (r['panel'], r['page'], r['M'], r['beta'], r['J'], r['Mt'], r['CT'], r['CP'], r['eta'], r['eta_curve'], r['CT_B'], r['CP_B']))
    json.dump([{k: (round(v, 2) if isinstance(v, float) else v) for k, v in r.items()} for r in cands],
              open(os.path.join(OUT, 'qa', 'naca_report1012_fig5_loaded_pixels.json'), 'w', encoding='utf-8'), indent=1,
              default=lambda v: v.item() if hasattr(v, 'item') else str(v))
    for r in cands:
        print('#%d %s M %.3f b%d J%.1f CT %.4f CP %.4f eta %.3f curve %.3f B %+.1f/%+.1f %% %s%s%s' % (
            r['n'], r['panel'], r['M'], r['beta'], r['J'], r['CT'], r['CP'], r['eta'], r['eta_curve'],
            100 * (r['CT_B'] / r['CT'] - 1), 100 * (r['CP_B'] / r['CP'] - 1),
            '' if r['eta_ok'] else ' eta-X', '' if r['B_ok'] else ' B-X', (' REJ ' + r['reject']) if r['reject'] else ''))
    print('candidates', len(cands), 'kept', len(keep))

if __name__ == '__main__':
    main()
