"""Checks of an eye transcription against the print's own redundancy: amplitude mirror (L <-> 20 - L) and the
lower-quarter phase rule phase(10 - j) = phase(10 + j) + H f_j, with f_j taken from the fully printed H2-H4 fields."""
import csv, importlib, sys
import numpy as np
import os
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'cr172428') + os.sep

def rule_steps():
    f = {}
    for H in (2, 3, 4):
        rows = list(csv.DictReader(l for l in open(R + 'appD_run10_H%d.csv' % H, encoding='utf-8') if not l.startswith('#')))
        ph = {(int(r['L']), int(r['k'])): float(r['phase_deg']) for r in rows}
        for j in range(1, 10):
            d = np.median([(ph[(10 - j, k)] - ph[(10 + j, k)]) % 360 for k in range(1, 17)])
            # unwrap: f_j = (d + 360 m) / H, the m that makes f_j continuous and increasing (0 < f_j < 25 deg x 8)
            cands = [(d + 360 * m) / H for m in range(0, H + 1)]
            f.setdefault(j, []).append(cands)
    out = {}
    for j in range(1, 10):
        # the f_j value common to the three harmonics
        best = None
        for c2 in f[j][0]:
            for c3 in f[j][1]:
                for c4 in f[j][2]:
                    s = np.std([c2, c3, c4])
                    if best is None or s < best[0]: best = (s, np.mean([c2, c3, c4]))
        out[j] = best[1]
    return out

def check(mod, H):
    m = importlib.import_module(mod)
    A = {L: [float(x) for x in s.split()] for L, s in m.AMP.items()}
    P = {L: [float(x) for x in s.split()] for L, s in m.PH.items()}
    assert all(len(v) == 16 for v in A.values()) and all(len(v) == 16 for v in P.values())
    f = rule_steps()
    bad = []
    for j in range(1, 10):
        if 10 - j in A:
            for k in range(16):
                if A[10 - j][k] != A[10 + j][k]: bad.append(('amp', 10 + j, 10 - j, k + 1, A[10 + j][k], A[10 - j][k]))
        if 10 - j in P:
            for k in range(16):
                d = (P[10 - j][k] - P[10 + j][k] - H * f[j] + 180) % 360 - 180
                if abs(d) > 0.3: bad.append(('phase', 10 + j, 10 - j, k + 1, P[10 + j][k], P[10 - j][k], round(d, 2)))
    return f, bad

if __name__ == '__main__':
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    f, bad = check(sys.argv[1], int(sys.argv[2]))
    print('rule steps f_j (deg):', {j: round(v, 2) for j, v in f.items()})
    print('disagreements:', len(bad))
    for b in bad: print('  ', b)
