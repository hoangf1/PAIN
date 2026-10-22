#!/usr/bin/env python
"""Plan step 19g (Fig. D-2 part): digitize the Fig. D-2 mode-1 shell and floor displacement from the page image (CR-3813 PDF page 113)
and compare with the Table D-1 mode-1 coefficients as used by `mrp.jl`.

Criterion fixed 2026-10-20 before the run (IMPLEMENTATION_PLAN.md, phase 19): shape within 5 % of its peak at the digitized points.
Peak = the figure's 1.0 (CR-3813 p. D-10: the maximum normal displacement on plate or shell is assigned 1.0, so shell and floor share
one scale). The shell part of the plot is a line-printer plot with a resolution of one print column; its quantization is reported.
Pure Python (PyMuPDF only). Writes data/fig_d2_mode1_digitized.csv and docs/validation_reports/fig_d2_check.md.
"""
import math, os, sys
from collections import deque
import pymupdf

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
PDF = os.path.join(ROOT, "references", "Pain Methodology.pdf")
DPI = 300
page = pymupdf.open(PDF)[112]
assert "FIGURE D-2" in page.get_text()


def blobs(x0, y0, x1, y1):      # coordinates of the 110-dpi view of the page used for reading the figure
    r = pymupdf.Rect(x0 * 72 / 110, y0 * 72 / 110, x1 * 72 / 110, y1 * 72 / 110)
    pm = page.get_pixmap(dpi=DPI, clip=r, colorspace=pymupdf.csGRAY)
    w, h, s = pm.width, pm.height, pm.samples
    dark = [[s[y * w + x] < 110 for x in range(w)] for y in range(h)]
    seen = [[False] * w for _ in range(h)]
    out = []
    for y in range(h):
        for x in range(w):
            if dark[y][x] and not seen[y][x]:
                q = deque([(x, y)]); seen[y][x] = True; pts = []
                while q:
                    cx, cy = q.popleft(); pts.append((cx, cy))
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            nx, ny = cx + dx, cy + dy
                            if 0 <= nx < w and 0 <= ny < h and dark[ny][nx] and not seen[ny][nx]:
                                seen[ny][nx] = True; q.append((nx, ny))
                xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
                out.append(dict(n=len(pts), cx=sum(xs) / len(xs), cy=sum(ys) / len(ys), bw=max(xs) - min(xs) + 1, bh=max(ys) - min(ys) + 1))
    return out


is_star = lambda b: b["n"] > 230 and b["bw"] > 18 and b["bh"] > 18
is_dot = lambda b: 100 < b["n"] < 200 and b["bw"] < 17 and b["bh"] < 17

# ---------------------------------------------------------------- floor
fl = blobs(280, 580, 560, 860)
stars = sorted([b for b in fl if is_star(b) and 20 < b["bw"] < 28 and 20 < b["bh"] < 28 and 260 < b["n"] < 345 and b["cy"] < 670 and b["cx"] > 70], key=lambda b: b["cx"])
dots = [b for b in fl if is_dot(b) and 670 < b["cy"] < 695 and b["cx"] > 60]
ticks = {round(b["cy"], 1): b for b in fl if b["bw"] > 45 and b["bh"] < 10}     # the two scale ticks "—1.0" and "—0.5"
tick10 = min(ticks); tick05 = max(ticks)
zero = sum(b["cy"] for b in dots) / len(dots)
scale = zero - tick10                                     # pixels per 1.0
half_check = (zero - tick05) / scale                      # should be 0.5
assert len(stars) == 11, len(stars)
floor_v = [(zero - b["cy"]) / scale for b in stars]

# ---------------------------------------------------------------- shell
sh = blobs(590, 190, 700, 900)
cand = [b for b in sh if 260 < b["n"] < 445 and 20 < b["bw"] < 30 and 20 < b["bh"] < 34 and b["cx"] < 200]
sh_dots = [b for b in sh if is_dot(b) and b["cx"] < 200]
# baseline x_b(y) by a straight-line fit through the visible dots (the scan is slightly skewed)
n = len(sh_dots); my = sum(b["cy"] for b in sh_dots) / n; mx = sum(b["cx"] for b in sh_dots) / n
slope = sum((b["cy"] - my) * (b["cx"] - mx) for b in sh_dots) / sum((b["cy"] - my) ** 2 for b in sh_dots)
xb = lambda y: mx + slope * (y - my)
cand.sort(key=lambda b: -b["cy"])
# the "*F = FLOOR LOCATION" label star lies on the baseline and has a shell star at the same height
label_star = None; pool = []
for b in cand:
    twin = [c for c in cand if c is not b and abs(c["cy"] - b["cy"]) < 15]
    if twin and abs(b["cx"] - xb(b["cy"])) < 8 and b["bh"] > 30:
        if 1000 < b["cy"] < 1600: label_star = b      # the F label (the other on-baseline twins are text glyphs at the top)
        continue
    pool.append(b)
# chain from the bottom star upward at the line pitch (median spacing of the first rows); text glyphs that satisfy the star filter are skipped
ys = [b["cy"] for b in pool[:12]]
pitch = sorted(ys[i] - ys[i + 1] for i in range(len(ys) - 1))[len(ys) // 2]
sh_stars = [pool[0]]
while True:
    prev = sh_stars[-1]
    nxt = [b for b in pool if abs((prev["cy"] - pitch) - b["cy"]) < 12 and b is not prev]
    if not nxt: break
    sh_stars.append(min(nxt, key=lambda b: abs(b["cx"] - prev["cx"])))
offsets_px = [b["cx"] - xb(b["cy"]) for b in sh_stars]
shell_v = [o / scale for o in offsets_px]
theta_per_px = 5.0 / pitch                                  # 5 degrees per print line, the bottom star is theta = 0
theta_F = (sh_stars[0]["cy"] - label_star["cy"]) * theta_per_px if label_star else float("nan")
steps = sorted(set(round(abs(offsets_px[i + 1] - offsets_px[i])) for i in range(len(offsets_px) - 1)))

# ---------------------------------------------------------------- model: Table D-1 mode 1 (digitized_table_D1.csv = mrp.jl, equal to 1e-5 in 17d)
rows = [l.split(",") for l in open(os.path.join(ROOT, "data", "digitized_table_D1.csv"), encoding="utf-8").read().splitlines()[1:] if l.strip()]
shell_terms, plate_terms = [], []
for i, r in enumerate(rows):
    if i > 0 and r[0]:
        break
    if r[5]: shell_terms.append((float(r[5]), int(r[4])))
    if r[8]: plate_terms.append((float(r[8]), int(r[7])))
assert plate_terms and shell_terms
floor_model = [sum(C * math.cos(nn * math.pi * i / 20) for C, nn in plate_terms) for i in range(11)]     # x = i Lp/20, mrp.jl structural_floor_psi (symmetric)
shell_code = lambda th: sum(C * (-1) ** nn * math.cos(nn * th) for C, nn in shell_terms)               # mrp.jl shell_circumferential (symmetric)
shell_plain = lambda th: sum(C * math.cos(nn * th) for C, nn in shell_terms)                           # without the (-1)^n


def compare(vals, model, label):
    err = [v - m for v, m in zip(vals, model)]
    return max(abs(e) for e in err), err

fl_err, fl_e = compare(floor_v, floor_model, "floor")
nsh = len(shell_v)
res = {}
for lab, f in (("mrp.jl: Σ C (−1)^n cos nθ", shell_code), ("Σ C cos nθ (no (−1)^n)", shell_plain)):
    model = [f(math.radians(5 * k)) for k in range(nsh)]
    res[lab] = compare(shell_v, model, lab)

# ---------------------------------------------------------------- outputs
with open(os.path.join(ROOT, "data", "fig_d2_mode1_digitized.csv"), "w", encoding="utf-8", newline="\n") as fh:
    fh.write("# Fig. D-2 of CR-3813 (PDF page 113, p. D-17): mode 1 (188.51 Hz, symmetric, M = 1), z dependency suppressed. Digitized 2026-10-20 from a 300 dpi render by blob centroid\n")
    fh.write("# (scripts/check_fig_d2.py). Value = displacement in the figure's units (floor: (zero line - star)/(zero line - 1.0 tick); shell: (star column - dot-baseline column)/same scale,\n")
    fh.write("# the figure normalizes plate and shell to one maximum of 1.0, p. D-10). Uncertainty: floor about 0.005; shell one print column (see fig_d2_check.md).\n")
    fh.write("part,index,position,value\n")
    for i, v in enumerate(floor_v): fh.write(f"floor,{i},x=i*Lp/20,{v:.4f}\n")
    for k, v in enumerate(shell_v): fh.write(f"shell,{k},row {k} from the bottom,{v:.4f}\n")

P = lambda ok: "PASS" if ok else "FAIL"
L = []
L.append("# Fig. D-2 mode-1 shape against `mrp.jl` (plan 19g, shape part)\n")
L.append("Generated by `scripts/check_fig_d2.py`. Criterion fixed 2026-10-20 before the run (`IMPLEMENTATION_PLAN.md`, phase 19): shape within 5 % of its peak at the digitized points. Peak = 1.0, the figure's own normalization (CR-3813 p. D-10: \"the maximum normal displacement computed on either plate or shell is assigned the value of 1.0\"; plate and shell share one scale). Data: `data/fig_d2_mode1_digitized.csv`. Model: Table D-1 mode 1 coefficients (equal to `mrp.jl`, 17d).\n")
L.append(f"Scale check: the 0.5 tick sits at {half_check:.3f} of the 1.0 tick height (expect 0.5).\n")
L.append("## Floor (11 stars from the centerline to the side, x = i Lp/20)\n")
L.append("| i | figure | model Σ C cos(nπx/Lp) | difference |\n|---:|---:|---:|---:|")
for i in range(11): L.append(f"| {i} | {floor_v[i]:.3f} | {floor_model[i]:.3f} | {fl_e[i]:+.3f} |")
L.append(f"\nLargest |difference| **{fl_err:.3f}** of the peak (criterion 0.05): **{P(fl_err <= 0.05)}**. Peak of the figure's floor curve {max(floor_v):.3f}; model peak {max(floor_model):.3f}. The digitization uncertainty is about 0.005. The figure is below the model at the outer points (i = 7-10); Table D-1 prints only the largest generalized coordinates of each mode (three plate terms for mode 1; MRPMOD selects the most significant ones), so omitted terms are a possible cause; this was not tested.\n")
L.append("## Shell (stars every 5° from the bottom centerline)\n")
L.append(f"Stars found: {nsh}, one per print line ({pitch:.1f} px = 5° at 300 dpi), rows k = 0..{nsh - 1} ↔ θ = 5k° (the star rows continue to θ = {5 * (nsh - 1)}°, past the top centerline; the mode is symmetric, so the model is evaluated there as well). The \"*F = FLOOR LOCATION\" label star sits at θ = {theta_F:.1f}° on this scale (θ0 = 56.6°), which checks the row calibration. Baseline = straight-line fit through {len(sh_dots)} dots (skew {slope:+.4f} px/px). Step sizes between neighbouring rows (px at 300 dpi): {steps}: the plot is quantized by the print column (steps of about 25–35 px = {30/scale:.3f} of the scale), so a 5 %-of-peak comparison of the shell is resolution-limited by about ±{16/scale:.3f}.\n")
L.append("| Model | largest abs. difference (of peak 1.0) | within 0.05 | as a fraction of the shell's own peak |\n|---|---:|---|---:|")
for lab, (mx_, e) in res.items():
    shp = max(abs(v) for v in shell_v)
    L.append(f"| {lab} | {mx_:.3f} | {P(mx_ <= 0.05)} | {mx_ / shp:.2f} |")
L.append("")
L.append("Shell values (figure) against the `mrp.jl` convention, rows ↔ θ = 5k°:\n")
L.append("| k | θ (°) | figure | mrp.jl | plain Σ C cos nθ |\n|---:|---:|---:|---:|---:|")
for k in range(nsh):
    L.append(f"| {k} | {5 * k} | {shell_v[k]:+.3f} | {shell_code(math.radians(5 * k)):+.3f} | {shell_plain(math.radians(5 * k)):+.3f} |")
L.append("")
L.append("""## Eqs. (D.22)–(D.26) against `mrp.jl`, term by term (CR-3813 pp. D-7 to D-10, read from the page images)

| Equation | Printed | `mrp.jl` (`structural_modes`, the Ritz solver) | Result |
|---|---|---|---|
| (D.22) | [K]{q1} = ω²[M]{q1} | generalized symmetric eigenproblem K v = ω² M v per axial index m and parity | same form |
| (D.17)–(D.21) | compatibility constraints C q = 0 eliminated through E = [I; C2⁻¹C1] | not implemented: the floor–shell junction is a soft spring, k_j = 1e7 N/m² along two lines, not a constraint | **differs** |
| (D.23) | 6×3 constitutive operator on (u, v, w) with k_xs, k_θR, D_xs, D_θR | no u, v degrees of freedom; w-only trial functions Σ C cos nθ (n = 1–10) and cos or sin pπx/Lp (p ≤ 5) | **not implemented** |
| (D.24) | k_xs = k_x + (EA/d)_stringer, k_θR = k_θ + (EA/ℓ)_ring, D_xs = D_x + (EI/d)_stringer, D_θR = D_θ + (EI/ℓ)_ring | the idea is present: t_eq = t_s + A_s/d + A_R/ℓ for the membrane terms and D_s = D_skin + E I_str/d + E I_ring/ℓ for bending; the text after (D.25) says D_xs, D_θR enter only the third diagonal term and the others use the equivalent thickness | **partly** (same smearing, no per-term placement) |
| (D.25) | 3×3 operator [G]ᵀ[D][G] with the off-diagonal u–v–w couplings | a Donnell-type diagonal `_donnell_omega2` = D_s β²/(m a⁴) + E t_eq λ⁴/(m a² β²) + 0.12 E t_eq n²/(m a²(n² + λ²)), times fitted factors k_scale = 0.61, floor_scale = 2.4, edge_factor = 2.2 | **not Eq. (D.25)**: a fitted surrogate (phase 4: 30 of 32 frequencies within 5 %) |
| Normalization (p. D-10) | the maximum normal displacement on plate or shell is 1.0 | Table D-1 coefficients are used as printed; mode 1 plate sum 0.989 at the centerline, consistent with 1.0 | consistent |

The production path does not use the Ritz solver: `run_pain_pipeline` calls `structural_modes_from_table_d1` (use_table_d1 = true), whose frequencies, masses and coefficients equal an independent digitization of Table D-1 (17d). Eqs. (D.22)–(D.26) are therefore not on the 18b path, and the differences above cannot explain the 18b miss.
""")
open(os.path.join(ROOT, "docs", "validation_reports", "fig_d2_check.md"), "w", encoding="utf-8", newline="\n").write("\n".join(L))
print("\n".join(L))
