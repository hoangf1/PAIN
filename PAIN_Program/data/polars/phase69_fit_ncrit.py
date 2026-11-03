"""Phase 69b: choose N_crit by the rule fixed 2026-10-28 (IMPLEMENTATION_PLAN.md section 8m) and score the held-out section.

Rule: one N_crit from 1..12; smallest RMS(XFOIL c_l - TN 1546 c_l) over the converged matched points of 16-506 and 16-509;
a tie goes to the higher N_crit; if the best value is 1 or 12 it is recorded as "N_crit cannot close the gap".
Held out: 16-312, scored with |dc_l| <= 0.05 at >= 75 % of its matched (XFOIL-converged) points, the POLAR_FIDELITY criterion.

    python data/polars/phase69_fit_ncrit.py data/polars/phase69_tn1546_ncrit.json > data/polars/phase69_ncrit_fit.md
"""
import json, math, sys

FIT = ("n16_506", "n16_509")
HOLD = "n16_312"

d = json.load(open(sys.argv[1]))
pts = d["points"]
runs = d["runs"]


def xfoil_cl(N, p):
    r = runs.get(f"{N}|{p['section']}|{float(p['mach']):.2f}")
    if not r:
        return None
    for a, cl, _ in r["rows"]:
        if abs(a - float(p["alpha_deg"])) < 1e-3:
            return cl
    return None


Ns = sorted({int(k.split("|")[0]) for k in runs})
print("# Phase 69b N_crit fit to NACA TN 1546\n")
print(f"Source: `{sys.argv[1]}` ({d['header']['generated']}). Rule fixed 2026-10-28 before the run.\n")
print("| N_crit | fit points converged | RMS fit (16-506, 16-509) | mean dc_l fit | held-out 16-312 within 0.05 |")
print("|---|---|---|---|---|")
best = None
rows = {}
for N in Ns:
    f = [(xfoil_cl(N, p), float(p["cl_meas"])) for p in pts if p["section"] in FIT]
    f = [(x, m) for x, m in f if x is not None]
    h = [(xfoil_cl(N, p), float(p["cl_meas"])) for p in pts if p["section"] == HOLD]
    hc = [(x, m) for x, m in h if x is not None]
    nf = sum(1 for p in pts if p["section"] in FIT)
    rms = math.sqrt(sum((x - m) ** 2 for x, m in f) / len(f)) if f else float("inf")
    mean = sum(x - m for x, m in f) / len(f) if f else float("nan")
    ok = sum(1 for x, m in hc if abs(x - m) <= 0.05)
    rows[N] = (rms, ok, len(hc))
    print(f"| {N} | {len(f)}/{nf} | {rms:.4f} | {mean:+.4f} | {ok}/{len(h)} ({len(hc)} converged) |")
    if best is None or rms < rows[best][0] - 1e-12 or (abs(rms - rows[best][0]) <= 1e-12 and N > best):
        best = N
rms, ok, nh = rows[best]
edge = best in (min(Ns), max(Ns))
print(f"\n**Chosen N_crit = {best}** (RMS {rms:.4f})." + (" **At the edge of the range: N_crit cannot close the gap.**" if edge else ""))
frac = ok / nh if nh else 0.0
print(f"\n**Held-out 16-312:** {ok}/{nh} within |dc_l| <= 0.05 ({100 * frac:.1f} %; criterion >= 75 %): "
      + ("**met**" if frac >= 0.75 else "**not met**") + ". Matched points are those where XFOIL converged, as in POLAR_FIDELITY.")
print("\nPOLAR_FIDELITY on 16-506 and 16-509 is calibrated by this fit and carries no verdict.")
