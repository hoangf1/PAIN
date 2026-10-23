"""Phase 47a QA: agreement of two independent digitizing passes and tone-peak positions.
qa(A.json, B.json, key, bpf_Hz, n_harm) -> dict; key: 'trace' (Fig. 14) or 'ext' / 'int' (Fig. 17).
Both passes are averaged into 1 Hz bins; points below 20 Hz are left out. 'broadband' leaves out H*BPF +- 10 Hz.
Tone peaks: maximum of the top of the ink (pass A) within H*BPF +- 0.15 BPF."""
import json
import numpy as np

def _load(p, key, col):
    t = np.array(json.load(open(p))[key])[:, [0, col]]
    out = {}
    for f, L in zip(np.floor(t[:, 0]).astype(int), t[:, 1]): out.setdefault(int(f), []).append(L)
    return {f: float(np.mean(v)) for f, v in out.items()}

def qa(A, B, key, bpf, nh):
    a, b = _load(A, key, 1), _load(B, key, 1)
    common = sorted(set(a) & set(b))
    fr = np.array(common, float); d = np.abs(np.array([a[f] - b[f] for f in common]))
    tone = np.zeros(len(fr), bool)
    for h in range(1, nh + 1): tone |= np.abs(fr - h * bpf) <= 10
    lo = fr >= 20
    st = lambda m: dict(n=int(m.sum()), median=round(float(np.median(d[m])), 3), p95=round(float(np.percentile(d[m], 95)), 3))
    at, bt = _load(A, key, 2), _load(B, key, 2)
    peaks = []
    for h in range(1, nh + 1):
        w = [f for f in at if abs(f - h * bpf) <= 0.15 * bpf]
        if w:
            fp = max(w, key=lambda f: at[f])
            peaks.append(dict(H=h, nominal_Hz=h * bpf, peak_Hz=fp, offset_Hz=fp - h * bpf,
                              top_A_dB=round(at[fp], 1), top_B_dB=round(bt.get(fp, float("nan")), 1)))
    return dict(all=st(lo), broadband=st(lo & ~tone), peaks=peaks)

def qa_csv(A_csv, B_csv, bpf, nh, union=True):
    """Phase 58a (post-hoc restatement, 2026-10-23): the broadband-point statistics from the committed CSVs,
    leaving out ±10 Hz around H*BPF and, with `union`, also around the observed tone peak (as 47b)."""
    def load(p, col):
        out = {}
        for line in open(p):
            if line.startswith('#') or line.startswith('f_Hz'): continue
            v = [float(x) for x in line.split(',')]
            out.setdefault(int(np.floor(v[0])), []).append(v[col])
        return {f: float(np.mean(x)) for f, x in out.items()}
    a, b = load(A_csv, 1), load(B_csv, 1)
    at = load(A_csv, 2)
    peaks = []
    for h in range(1, nh + 1):
        w = [f for f in at if abs(f - h * bpf) <= 0.15 * bpf]
        if w: peaks.append(max(w, key=lambda f: at[f]))
    common = sorted(set(a) & set(b))
    fr = np.array(common, float); d = np.abs(np.array([a[f] - b[f] for f in common]))
    tone = np.zeros(len(fr), bool)
    for t in [h * bpf for h in range(1, nh + 1)] + (peaks if union else []):
        tone |= np.abs(fr - t) <= 10
    m = (fr >= 20) & ~tone
    return dict(n=int(m.sum()), median=round(float(np.median(d[m])), 3), p95=round(float(np.percentile(d[m], 95)), 3))


if __name__ == "__main__":
    import sys
    print(json.dumps(qa(sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4]), int(sys.argv[5])), indent=1))
