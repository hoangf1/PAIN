# ISSUE-047: how far the published NACA 16-series sections move the Report 996 results (2026-11-22)

Done by Claude at the author's go-ahead of 2026-11-22 ("Yes, measure it"). This is a diagnostic. No verdict changed. No recorded result, polar file or section file used by a case was replaced. What was measured was written in ISSUE-047 before any run.

## What was run

1. The ten Report 996 section contours were regenerated from the published definitions (16-series thickness and the a = 1.0 mean line; `xfoil_r1377.contour`, 161 points like the old files). They reproduce the named thickness and design camber exactly.
2. The Phase 69 XFOIL grid and fill pass were run unchanged (N_crit 8, 240 panels, same grid and acceptance rule); only the section folder changed.
3. The TN 1546 N_crit runs (1–12) and the Phase 69b fit rule were run unchanged on the new 16-312, 16-506 and 16-509.
4. The Report 996 loads, scaled acoustics and unscaled acoustics generators were run four times, with only the polar file and the section folder changed. The run on the old inputs reproduces the recorded `scale_factors.csv`, `f1a_results.csv` and `f1a_results_unscaled.csv` exactly.
5. The other cases on this polar file were run on old and new polars.

The run scripts were scratch copies with redirected paths and are not kept. After the re-run (below) the sections and polars are the files the cases read; the fit table is `data/polars/issue047_ncrit_fit.md`.

## The section data

| Section | Median c_l change | 95 % of \|c_l change\| below | Median c_d change |
|---|---|---|---|
| 16-101 | −0.024 | 0.060 | +1.6 % |
| 16-213 | +0.011 | 0.064 | +2.1 % |
| 16-312 | +0.039 | 0.108 | +2.8 % |
| 16-405 | +0.051 | 0.101 | +3.1 % |
| 16-410 | +0.011 | 0.070 | +3.4 % |
| 16-411 | +0.035 | 0.082 | +1.9 % |
| 16-506 | +0.070 | 0.155 | +5.1 % |
| 16-507 | +0.041 | 0.130 | +6.5 % |
| 16-508 | +0.038 | 0.105 | +4.6 % |
| 16-509 | +0.066 | 0.156 | +6.4 % |

Points converged in both sets, all Reynolds and Mach numbers, α −6° to 20°.

- **16-508** has the right thickness and camber in the old file too. It differs only at the trailing edge: the old file closes it, while the published 16-series form leaves it open by 0.16 % of the chord. That alone moves c_l by about +0.04.
- **16-507** is 7.4 % thick in the old file, not 7 %.
- ISSUE-047's plan called both files "matching" and proposed them as a control. That was wrong: their changes are real differences from the published shape, not run-to-run noise.

**N_crit fit:** the rule still chooses **N_crit 8** (RMS 0.055 on 16-506 and 16-509; was 0.039). The held-out 16-312 is **19/26** within 0.05 (was 13/26), below the fit rule's 75 % mark (POLAR_FIDELITY is an information case: no verdict).

## The cases

| Case | Recorded count | On the new sections | Largest level change | What moves |
|---|---|---|---|---|
| R996_LOADS (all within ±15 %) | 24/32 | 27/32 | — | C_T +3.5 to +10 %; C_P 0 to +14 %, and +50 % (primary) or +73 % (bracket polars) at tip Mach 0.9 |
| R996_FIG14 (≥ 75 % within ±2 dB) | 24/24 | 22/24 | +1.7 dB | tip Mach 0.9 only |
| R996_FIG12 | 32/40 | 31/40 | +3.2 dB | Fig. 12(b), tip Mach 0.9, harmonics 4–8 |
| R996_FIG13A | 14/14 | 14/14 | 0.02 dB | — |
| R996_PHASE (155° measured) | 112.6° | 112.5° | — | — |
| POLAR_FIDELITY (held-out 16-312) | 13/26 | 20/27 | — | c_l rises toward TN 1546 |
| PROP_BB_FIG14 | 3/9 | 3/9 | 0.5 dB | — |
| PROP_BB_FIG17 | 2/7 | 2/7 | 0.9 dB | — |
| T2_PRED_BB | 0/3 | 0/3 | 0.7 dB | — |

New sections (polars and thickness area together). Counts on the new sections are information only: they would be post-hoc, since the recorded results are known.

- **Split by input:** the section thickness area alone moves the compared levels by at most 0.16 dB (median 0.03 dB). The polars carry the rest.
- **Scaled levels** (the cases' own form): 9 of 78 compared levels move by more than 1 dB, all at tip Mach 0.9. The median move is 0.05 dB.
- **Unscaled second line** (no verdict): 15 of 59 move by more than 1 dB, up to +5.2 dB, again at tip Mach 0.9. The median move is 0.43 dB.
- **No case would change its verdict.** R996_LOADS stays not met (its criterion needs every row). FIG14 and FIG12 stay met (92 % and 78 %). POLAR_FIDELITY, an information case, reaches 74 % (20/27).

## What this means for the decision (the author's)

- Below tip Mach 0.9 the wrong section files hardly matter to the cases' compared levels: the scaled loads absorb most of the lift change.
- At tip Mach 0.9 they move levels by up to 3.2 dB (scaled) and 5.2 dB (unscaled), and power by 50–73 %. There the outer sections are near drag rise, where a small change in shape moves c_d a great deal.
- The choice:
  - **Re-run** R996_LOADS, FIG12, FIG14, POLAR_FIDELITY and the dependent cases on the published sections, labelled post-hoc. The polars are ready.
  - **Keep** the records, and state in each record that the tip Mach 0.9 rows rest on section files that differ from the published shapes, by the amounts above.

## Decision and re-run (2026-11-22)

The author chose the re-run ("go for it", on the recommendation to re-run, as in Phase 154). Done the same day:

- `data/report996/xfoil_sections` and `polars_phase69_ncrit8.json` now hold the published sections and their polars.
- The old files are `xfoil_sections_pre047` and `polars_phase69_ncrit8_pre047.json`; the old results are the three `*_pre047.csv`.
- The regenerated `scale_factors.csv`, `f1a_results.csv` and `f1a_results_unscaled.csv` equal the measurement run above exactly.
- The cases were re-run with post-hoc labels in their records, and their counts are the ones in the table above.
- **No verdict changed.**
