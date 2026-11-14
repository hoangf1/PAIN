"""Row-by-row follower for the steep curves (C_T, C_P where they fall towards the J axis) of Report 1012 Fig. 5."""
import numpy as np
from page import Page, THR

def row_runs(P, y, xlo, xhi, maxlen=9):
    row = P.ink[y, xlo:xhi]; d = row > THR; out = []; i = 0; n = len(d)
    while i < n:
        if d[i]:
            j = i
            while j < n and d[j]: j += 1
            if j - i <= maxlen:
                w = row[i:j] - 40.0; out.append((xlo + float((np.arange(i, j) * w).sum() / w.sum()), j - i))
            i = j
        else: i += 1
    return out

def trace(P, vmin=0.0, vmax=0.21, Jmin=0.0, Jmax=5.6, minlen=50, gap=45):
    xm = 0.5 * (P.xl + P.xr)
    yt = int(P.Y(vmax, xm)) + 3; yb = int(P.Y(vmin, xm)) - 3
    gy = [P.Y(0.005 * i, xm) for i in range(43)]
    live = []; done = []
    for y in range(yt, yb):
        yg = min(abs(y - (g + P.b[2] * 0)) for g in gy)
        if yg < 4.5: continue                                     # on a horizontal grid line (skew up to 5 px across the page)
        xlo = int(P.X(Jmin, y)) - 4; xhi = int(P.X(Jmax, y)) + 5
        runs = []
        for x, ln in row_runs(P, y, xlo, xhi):
            j = (x - P.a[0] - P.a[2] * (y - P.yc)) / P.a[1]
            if abs(j - round(j)) * P.a[1] < 3.2: continue            # a vertical grid line
            runs.append(x)
        runs = np.array(runs)
        for t in live:
            xs, ys = t['x'], t['y']
            k = min(len(xs), 25)
            if k >= 6:
                A = np.polyfit(ys[-k:], xs[-k:], 1); pred = np.polyval(A, y)
            else: pred = xs[-1] + t.get('s0', 0.0) * (y - ys[-1])
            tol = 1.6 + 0.06 * (y - ys[-1])
            if len(runs):
                i = int(np.argmin(np.abs(runs - pred)))
                if abs(runs[i] - pred) < tol:
                    xs.append(float(runs[i])); ys.append(y); t['hit'] = True; t.setdefault('claimed', []).append(i); t['last_i'] = i
                    continue
            t['hit'] = False
        claimed = set(t.get('last_i') for t in live if t.get('hit'))
        for i, x in enumerate(runs):
            if i not in claimed: live.append(dict(x=[float(x)], y=[y], hit=True))
        keep = []
        for t in live:
            if y - t['y'][-1] > gap:
                if len(t['x']) >= minlen: done.append(t)
            else: keep.append(t)
        live = keep
    done += [t for t in live if len(t['x']) >= minlen]
    out = []
    for t in done:
        x = np.array(t['x']); y = np.array(t['y'], float)
        out.append(dict(x=x, y=y, fill=len(x) / (y[-1] - y[0] + 1)))
    # drop duplicates (two traces that share most points)
    out.sort(key=lambda t: -len(t['x'])); uniq = []
    for t in out:
        dup = False
        for u in uniq:
            yy = np.intersect1d(t['y'], u['y'])
            if len(yy) > 0.6 * len(t['y']):
                xt = np.interp(yy, t['y'], t['x']); xu = np.interp(yy, u['y'], u['x'])
                if np.mean(np.abs(xt - xu) < 1.0) > 0.8: dup = True; break
        if not dup: uniq.append(t)
    return uniq
