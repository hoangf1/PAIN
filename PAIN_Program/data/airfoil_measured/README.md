# Measured airfoil section data (digitized 2026-10-22)

Wind-tunnel section data for the airfoil-polar display and for the high-Mach polar gap (the XFOIL grid of `data/report996/polars_forced_merged.json` stops at M = 0.72; Report 996 tip Mach is 0.75–0.90). These are independent airfoil measurements, not the propeller noise or load data the source cases are compared against. Sources and checksums of the PDFs: `rea-work/references/SOURCES.md`.

## Files

| File | Content |
|------|---------|
| `tn1546_fig3_cl_cd_vs_mach.csv` | NACA TN 1546 Fig. 3(j) NACA 16-312 (PDF p. 30), 3(n) NACA 16-506 (p. 34), 3(o) NACA 16-509 (p. 35): c_l and c_d against M at constant α, sampled every 0.01 in M along each curve. Columns: `airfoil, figure, pdf_page, alpha_deg, quantity, mach, value, sample, assignment` |
| `tr824_naca4412_cl_alpha.csv` | NACA Report 824 p. 141, NACA 4412 smooth, Re 3, 6, 9 ×10⁶: c_l against α (data markers) |
| `tr824_naca4412_cd_cl.csv` | Same page: c_d against c_l (data markers) |
| `tools/` | `render_pages.py` (300-dpi renders into `tools/work/`, not kept), `trace.py` + `configs/` (TN 1546 curves), `tr824.py`, `tr824_L.py`, `tr824_R.py` (TR 824 markers), `grid.py` (grid-line detection) |
| `qa/` | Overlays of every traced curve and marker, spot-check tiles and results, calibration residuals |
| `CHECKSUMS.txt` | SHA-256 of the CSVs |

Reproduce (from `tools/`): `python render_pages.py`, then `python trace.py configs/cfg_3j_cl.json work/out` (and the other five configs), `python tr824_L.py`, `python tr824_R.py`. The re-run reproduces the recorded samples exactly (checked 2026-10-22).

## Method

- **Axes.** Fitted to the printed grid lines (detected by line projection); largest residual of a detected line against the fit 2.7 px, about 0.004 in c_l or 0.0002 in c_d (`qa/tn1546_calibration_residual_px.json`).
- **TN 1546 curves.** Each curve is given as hand-read waypoints; the tracer follows that guide and snaps to the nearest ink within a few pixels, with the grid lines masked. `sample` says where each value comes from: `ink` (on the drawn line), `interp` (between two ink points across a dash gap of at most 45 px), `guide` (no ink found, usually because the curve runs along a grid line or at the axis: hand-read value). The guides set which line is followed, never the value where ink exists.
- **TR 824 markers.** Approximate marker positions read by eye, refined to sub-pixel by ring-template matching restricted to the expected marker shape (circle 3×10⁶, square 6×10⁶, diamond 9×10⁶), as in `data/report996/tools/digitize_tr996.py`. Standard-roughness (△) and split-flap (▽) runs are not digitized. Below α ≈ 9° the three Reynolds numbers coincide within the marker size and are recorded once as `all`. Two 9×10⁶ points of c_d(c_l) are hidden behind the 6×10⁶ square and take its position (`note=overlap`).
- **Second check.** The scans are black and white, so an ink-threshold sweep changes nothing; instead, 18 points (three per TN 1546 panel) were read by eye from fresh, unannotated crops and compared with the traced values: largest difference 0.0034 in c_l and 0.0002 in c_d, inside TN 1546's stated accuracy (c_l ±0.005, c_d ±0.0005, α ±0.1°, p. 5). `qa/tn1546_spot_check.json`.

## Which curve is which angle (`assignment`)

The figures tell the curves apart only by dash pattern, and several cross. Each curve is labelled with how its angle was established:

- `order`: c_l curves, separated and in α order at M = 0.3.
- `range`: c_d curve whose Mach range matches that angle's own c_m subplot and c_l curve (TN 1546 plots one c_m panel per angle, in legend order), or whose line style is unique (solid −0.23°, short dash 1.77°).
- `inferred`: two curves cross; the continuation through the crossing follows slope and dash style, and agrees with the ranges. Fig. 3(j) c_l 11.77°/9.77° (c_m ranges: 11.77° ends at M 0.45, 9.77° at 0.55) and their c_d (the stalled 0.041 curve is taken as 11.77°; its c_d range, to 0.555, does not match the c_m range); 3(n) c_d −4.23°/−2.23° (cross at M 0.55); 3(o) c_d 5.77°/−4.23° (cross at M 0.55).
- `uncertain`: Fig. 3(j) c_d curves of −4.23°, 3.77°, −2.23°, 1.77° and −0.23°, assigned by drag ordering at M = 0.3 (drag rising with distance from the low-drag c_l). That rule does not hold on Fig. 3(n), so these labels are not confirmed.

## Not digitized, or cut short

- Fig. 3(j) c_d 5.77°: coincides with 7.77° along c_d = 0.015 and cannot be separated; omitted.
- Fig. 3(j) c_d drag rise: −0.23° and −2.23° merge at M ≈ 0.748, c_d ≈ 0.015, and −4.23°, 1.77° and −2.23° converge near c_d 0.02–0.033. Each curve stops where its branch is still unambiguous (−4.23° at M 0.72, −2.23° at 0.74, 1.77° at 0.73, −0.23° at 0.75). The shared upper branch, to c_d ≈ 0.048 at M 0.775, is not assigned.
- Fig. 3(o) c_d −2.23° stops at M 0.757, where it joins −0.23°.
- Near-vertical lift-break drops are recorded only up to the last Mach where the curve is single-valued.
- c_m panels: read only for the Mach ranges used in the assignments above, not digitized.

## Conditions of the data

TN 1546: Langley 24-inch high-speed tunnel, 5-inch chord, Re about 0.85–2×10⁶ over M 0.3–0.8, **not corrected for tunnel-wall interference** (the report estimates about 2 % on M at supercritical speeds, p. 6), data near choking omitted by the authors. TR 824: Langley two-dimensional low-turbulence tunnels, 24-inch chord. Digitization uncertainty is about half a line width: c_l ±0.003, c_d ±0.0002 (TN 1546); marker centres ±1 px, about c_l ±0.003, c_d ±0.00003, α ±0.05° (TR 824).
