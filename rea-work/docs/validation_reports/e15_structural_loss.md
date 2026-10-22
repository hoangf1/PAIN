# E-15 total structural loss factor η_r′ (phase 38e, first run)

No pass mark (as recorded in 16b / `IMPLEMENTATION_PLAN.md` §8 row 38e). Label: **V-EXP; Fig. E-15 η_r′ with η_T=1.0 and η_r_cap=0.15; no pass mark; first run 2026-10-22**. No parameter chosen after seeing the numbers.

## Quantity decision (from Fig. E-15)

Caption (p. E-25 / PDF p. 141): **"MEASURED AND PREDICTED TOTAL STRUCTURAL LOSS FACTORS FOR TEST CYLINDER."** Legend shows calculated curves at trim loss factor 0.5 and 1.0, plus a long-dashed **upper-limit** line at 0.15. That is **η_r′ of Eq. (82)** (structural loss **with trim**), not bare η_r. The upper-limit line is NASA's E-18/E-21 η_r′ cap (`η_r_cap=0.15`, CR-3813 p. E-30) — the same setting as 38d.

## Inputs

| Item | Value |
|---|---|
| Geometry | Phase III: a = 0.508 m, L = 1.803 m, θ₀ = 56.6° |
| Trim | `phase3_trim(; η_lining=1.0)` |
| Cap | `η_r_cap=0.15` (E-18/E-21 setting) |
| Modes | Table D-1, 32 modes; at each target f, nearest mode by \|f_r − f\|; loss factors evaluated at the target ω |
| C (Eq. 80) | 3.0 |
| Reference | `data/cr3813/e15_structural_loss_targets.csv` |

## Per-band table (V-EXP info)

| f [Hz] | measured η | computed η_r′ | ratio | within `tol_frac`? |
|-------:|-----------:|--------------:|------:|:------------------:|
| 150 | 0.06 | 0.1500 | 2.500 | no |
| 300 | 0.07 | 0.1500 | 2.143 | no |
| 500 | 0.10 | 0.1269 | 1.269 | yes |
| 800 | 0.06 | 0.1075 | 1.792 | no |
| 1200 | 0.05 | 0.0535 | 1.070 | yes |
| 1500 | 0.04 | 0.0386 | 0.964 | yes |
| 2500 | 0.025 | 0.0147 | 0.589 | yes |
| 4000 | 0.03 | 0.0078 | 0.262 | no |

**Within tol_frac: 4 / 8 (info only). Verdict: `:no_verdict`.**

Bands at 150 and 300 Hz sit on the cap (η_r′ = 0.15) — consistent with the figure's upper-limit line in that region.

## Code / tests

- `structural_loss_total` / `structural_loss_with_trim(...; η_r_cap=0.15)`
- Case `E15_STRUCT_LOSS` in `validation_case_extras.jl`
- Filtered `Pkg.test("PAIN"; test_args=["E-15 structural", "Validation case registry"])`

No change after seeing the comparison.
