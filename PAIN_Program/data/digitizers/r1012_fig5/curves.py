"""Assemble the C_T and C_P curves of one Fig. 5 panel and read them on the advance-ratio gridlines.

Steep parts: the row-by-row follower (trace.py). Shallow parts: column strokes beside each gridline, chained to the
steep part by value and slope. Blade angle: order of the curves' feet on the J axis (Table I lists the angles)."""
import numpy as np
from page import Page, THR
from trace import trace

OFFS = (-12, -11, -10, -9, -8, -7, -6, -5, 5, 6, 7, 8, 9, 10, 11, 12)

def col_runs(P, x, y0, y1):
    xi = int(round(x)); col = P.ink[y0:y1, xi]; d = col > THR; out = []; i = 0; n = len(d)
    while i < n:
        if d[i]:
            j = i
            while j < n and d[j]: j += 1
            if j - i <= 9:
                w = col[i:j] - 40.0; out.append(y0 + float((np.arange(i, j) * w).sum() / w.sum()))
            i = j
        else: i += 1
    return out

def col_cross(P, J):
    """shallow strokes (|slope| <= 1.6 px/px) through gridline J: list of (v, dv/dJ, n, y)"""
    xm = P.X(J, 1300.0); y0 = max(int(P.Y(0.21, xm)) - 6, 5); y1 = int(P.Y(0.0, xm)) + 6
    xg = P.X(J, 0.5 * (y0 + y1)); pts = {o: col_runs(P, xg + o, y0, y1) for o in OFFS}
    cand = []
    for ol in OFFS[:4]:
        for orr in OFFS[-4:]:
            for ya in pts[ol]:
                for yb in pts[orr]:
                    s = (yb - ya) / (orr - ol)
                    if abs(s) > 1.6: continue
                    sup = []
                    for o in OFFS:
                        yp = ya + s * (o - ol)
                        if pts[o]:
                            b = min(pts[o], key=lambda t: abs(t - yp))
                            if abs(b - yp) < 1.5: sup.append((o, b))
                    nl = sum(1 for t in sup if t[0] < 0); nr = len(sup) - nl
                    if len(sup) >= 9 and nl >= 3 and nr >= 3:
                        oo = np.array([t[0] for t in sup], float); yy = np.array([t[1] for t in sup])
                        A = np.polyfit(oo, yy, 1); res = float(np.abs(np.polyval(A, oo) - yy).max())
                        if res <= 1.3: cand.append((len(sup), res, float(A[1]), float(A[0])))
    cand.sort(key=lambda c: (-c[0], c[1])); found = []
    for n, res, y, s in cand:
        i = (y - P.b[0] - P.b[2] * (xg - P.xc)) / P.b[1]
        if abs(i - round(i)) * abs(P.b[1]) < 2.5 and abs(s - P.b[2]) < 0.12: continue      # a horizontal grid line
        if any(abs(y - f[3]) < 3.5 and abs(s - f[4]) < 0.5 for f in found): continue
        x = P.X(J, y); Jv, v = P.value(x, y)
        dvdJ = (s * (0.005 / P.b[1])) / (0.1 / P.a[1])            # px slope -> dv/dJ
        hit = 0; tot = 0
        for o in range(-30, 31):
            if abs(o) < 5: continue
            xx = int(round(x + o)); yy = y + s * o; r = 3
            tot += 1; hit += P.ink[int(round(yy)) - r:int(round(yy)) + r + 1, xx].max() > 90
        found.append((v, dvdJ, n, y, s, hit / tot))
    return found

def trace_at(P, t, J):
    """where a steep trace crosses gridline J: (v, dv/dJ, y) or None"""
    xs, ys = t['x'], t['y']; f = xs - np.array([P.X(J, y) for y in ys])
    k = np.where(np.sign(f[:-1]) * np.sign(f[1:]) <= 0)[0]
    if len(k) == 0: return None
    k = k[0]
    if ys[k + 1] - ys[k] > 40: return None
    lo = max(0, k - 12); hi = min(len(xs), k + 14)
    A = np.polyfit(ys[lo:hi], xs[lo:hi], 1)                       # x = A0 y + A1 (steep: well conditioned)
    y = ys[k]
    for _ in range(3): y = (P.X(J, y) - A[1]) / A[0]
    Jv, v = P.value(P.X(J, y), y)
    dvdJ = ((1.0 / A[0]) * (0.005 / P.b[1])) / (0.1 / P.a[1])
    return v, dvdJ, y

def assemble(P, betas, verbose=False, Mach=0.0):
    T = trace(P)
    feet = []
    for t in T:
        J0, v0 = P.value(t['x'][0], t['y'][0]); J1, v1 = P.value(t['x'][-1], t['y'][-1])
        t['J0'], t['v0'], t['J1'], t['v1'] = J0, v0, J1, v1
        if v1 < 0.008 and v0 - v1 > 0.03 and abs(J1 - J0) > 0.12: feet.append(t)       # reaches the axis, not an efficiency drop
    feet.sort(key=lambda t: t['J1'])
    # pair C_T (dashed, lower fill, smaller J at the axis) with C_P (solid) per blade angle
    pairs = []; i = 0
    while i + 1 < len(feet):
        a, b = feet[i], feet[i + 1]
        if b['J1'] - a['J1'] < 0.12 and a['fill'] < b['fill']:
            pairs.append((a, b)); i += 2
        else: i += 1
    if verbose:
        for t in feet: print('foot J %.3f  from J %.2f v %.3f  fill %.2f len %d' % (t['J1'], t['J0'], t['v0'], t['fill'], len(t['x'])))
        print(len(pairs), 'pairs for', len(betas), 'blade angles')
    cols = {}
    def cc(J):
        k = round(J, 1)
        if k not in cols: cols[k] = col_cross(P, k)
        return cols[k]
    out = {}
    # blade angle of a pair: the printed label sits at the curves' foot; feet read from the figure (C_T = 0), all panels
    FOOT = {20: 1.00, 25: 1.22, 30: 1.48, 35: 1.79, 40: 2.10, 45: 2.52, 50: 3.03, 55: 3.66, 60: 4.52}
    assigned = []
    if len(pairs) == len(betas): assigned = list(zip(betas, pairs)); pairs_left = []
    else: pairs_left = pairs
    for (ta, tb) in pairs_left:
        d = sorted((abs(ta['J1'] - FOOT[int(b)]), b) for b in betas)
        if d[0][0] <= (0.10 if d[0][1] < 60 else 0.16) and (len(d) == 1 or d[1][0] > 0.14): assigned.append((d[0][1], (ta, tb)))
        elif verbose: print('pair at foot J %.3f not assigned' % ta['J1'])
    if verbose: print('assigned', [(b, round(p[0]['J1'], 3)) for b, p in assigned])
    for beta, (ta, tb) in assigned:
        for name, t in (('CT', ta), ('CP', tb)):
            pts = {}
            Js = [round(0.1 * k, 1) for k in range(1, 57)]
            for J in Js:
                r = trace_at(P, t, J)
                if r is not None: pts[J] = dict(v=r[0], s=r[1], y=r[2], how='row')
            if not pts: continue
            J = min(pts); cur = pts[J]
            while J > 0.25:                                           # chain to lower J through the shallow part
                best = None
                for step, tol in ((0.1, 0.0018), (0.2, 0.004)):
                    Jn = round(J - step, 1)
                    if Jn < 0.15: continue
                    for (v, s, n, y, spx, cov) in cc(Jn):
                        if abs(v - (0.11 + Mach * np.sqrt(1 + (np.pi / Jn) ** 2) / 20.0)) < 0.002: continue   # the tip Mach number curve
                        e = abs(v - cur['v'] + 0.5 * step * (cur['s'] + s))   # trapezoid rule: exact for a parabola
                        if e < tol and (best is None or e < best[0]): best = (e, v, s, y, Jn, cov)
                    if best is not None: break
                if best is None: break
                Jn = best[4]; pts[Jn] = dict(v=best[1], s=best[2], y=best[3], how='col', cov=best[5]); J = Jn; cur = pts[Jn]
            out[(beta, name)] = pts
    return out, pairs, T

def read_panel(P, M, betas, eta_tol=0.015):
    """rows on the labelled gridlines (J = 0.2 k): C_T, C_P, efficiency from them, and the efficiency curve read there"""
    out, pairs, T = assemble(P, betas, Mach=M)
    rows = []
    for beta in sorted(set(b for b, _ in out)):
        ct = out.get((beta, 'CT'), {}); cp = out.get((beta, 'CP'), {})
        for k in range(1, 29):
            J = round(0.2 * k, 1)
            if J not in ct or J not in cp: continue
            CT = ct[J]['v']; CP = 2 * cp[J]['v']
            if CT <= 0 or CP <= 0: continue
            eta = J * CT / CP; Mt = M * np.sqrt(1 + (np.pi / J) ** 2)
            er = [v / 0.05 for (v, s, n, y, spx, cov) in col_cross(P, J) if abs(y - ct[J]['y']) > 3 and abs(y - cp[J]['y']) > 3]
            near = min(er, key=lambda e: abs(e - eta)) if er else float('nan')
            px = lambda dvdJ: dvdJ * (0.1 / P.a[1]) / (0.005 / P.b[1])
            if abs(ct[J]['y'] - cp[J]['y']) < 5: continue                 # both chains on one stroke: not two curves
            rows.append(dict(M=M, beta=beta, J=J, CT=CT, CP=CP, eta=eta, eta_read=near, Mt=Mt, yCT=ct[J]['y'], yCP=cp[J]['y'],
                             sCT=px(ct[J]['s']), sCP=px(cp[J]['s']), covCT=ct[J].get('cov', -1.0), covCP=cp[J].get('cov', -1.0),
                             how=ct[J]['how'] + '/' + cp[J]['how'], ok=bool(er) and abs(near - eta) <= eta_tol))
    return rows, out
