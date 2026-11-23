# Report 996 Acoustics (phase 27)

Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.
Generated 2026-11-22 by `scripts/run/run_report996_acoustics.jl`.
Blade: `blade_form_r996_fig3c.csv`, β from Report 996 Fig. 3(c) (Phase 154, 2026-11-14; re-run post-hoc; the results on `blade_form.csv` are compared in `phase154_r996_blade_angle.md`).
Sections: the published NACA 16-series shapes (ISSUE-047, re-run 2026-11-22, post-hoc; the results on the old section files are `f1a_results_pre047.csv`, compared in `issue047_r996_sections.md`).
**Re-run after plan I-01/I-02/I-08 (2026-11-22).** Criterion: VALIDATION_GUIDELINE §2.12 / 23c frozen 2026-10-21.
x_sign=R996_X_SIGN = +1 (report x/D positive ahead → AA +X, the direction the rotor travels; Phase 72, was −1). Thickness on (Phase 76; A/c² per station from the NACA 16 section contours). Harmonic A vs measured: A_rms = A_Pa/√2 (Report 996 p.10 rms).

## I-08 Fig. 13(a) load scale

RM L51C27 Table I (47-in., β₇₅=15°, M_t=0.75): T=225.0 lb, Q=114.0 lb·ft → C_T=0.0869, C_Q=0.01124; applied to 4-ft model: T_tgt=1043.9 N, Q_tgt=164.6 N·m. Tag `scaled_RM_L51C27` (replaces void fig14proxy).

## x-sign / asymmetry (25k)

A_rms(-0.125)=1126.6 vs A_rms(+0.125)=1100.5 dyne/cm² (meas ~1328 vs ~1009); behind>ahead=true

## Page-12 phase (one measured value)

Δφ(|x/D|=0.125) F1A=112.5° vs report measured 155° / Eq.(2) 165° (candidates ±0.125; exact stations not stated)

23c page-12 phase: |Δφ − 155°| = 42.5° → FAIL (±15°).

## Fig. 14 (scaled to table C_T/C_Q) — residual % vs digitized

| polar | loads | case | mB | A F1A dyne/cm² | meas | residual % | residual dB |
|---|---|---|--:|---:|---:|---:|---:|
| primary | scaled | beta10_B2_Mt0.45 | 2 | 175.5 | 200.9 | -12.7 | -1.18 |
| primary | scaled | beta10_B2_Mt0.45 | 4 | 83.8 | 100.0 | -16.2 | -1.53 |
| primary | scaled | beta10_B2_Mt0.45 | 6 | 40.9 | 50.1 | -18.4 | -1.77 |
| bracket | scaled | beta10_B2_Mt0.45 | 2 | 177.9 | 200.9 | -11.5 | -1.06 |
| bracket | scaled | beta10_B2_Mt0.45 | 4 | 85.3 | 100.0 | -14.7 | -1.38 |
| bracket | scaled | beta10_B2_Mt0.45 | 6 | 41.8 | 50.1 | -16.7 | -1.58 |
| primary | scaled | beta10_B2_Mt0.6 | 2 | 357.8 | 358.2 | -0.1 | -0.01 |
| primary | scaled | beta10_B2_Mt0.6 | 4 | 182.9 | 179.1 | 2.1 | 0.18 |
| primary | scaled | beta10_B2_Mt0.6 | 6 | 94.8 | 79.7 | 18.9 | 1.5 |
| bracket | scaled | beta10_B2_Mt0.6 | 2 | 362.7 | 358.2 | 1.3 | 0.11 |
| bracket | scaled | beta10_B2_Mt0.6 | 4 | 185.6 | 179.1 | 3.6 | 0.31 |
| bracket | scaled | beta10_B2_Mt0.6 | 6 | 96.5 | 79.7 | 21.1 | 1.66 |
| primary | scaled | beta10_B2_Mt0.75 | 2 | 677.4 | 661.0 | 2.5 | 0.21 |
| primary | scaled | beta10_B2_Mt0.75 | 4 | 394.4 | 399.6 | -1.3 | -0.11 |
| primary | scaled | beta10_B2_Mt0.75 | 6 | 229.5 | 229.0 | 0.2 | 0.02 |
| bracket | scaled | beta10_B2_Mt0.75 | 2 | 686.7 | 661.0 | 3.9 | 0.33 |
| bracket | scaled | beta10_B2_Mt0.75 | 4 | 397.9 | 399.6 | -0.4 | -0.04 |
| bracket | scaled | beta10_B2_Mt0.75 | 6 | 231.2 | 229.0 | 0.9 | 0.08 |
| primary | scaled | beta10_B2_Mt0.9 | 2 | 1296.4 | 1297.9 | -0.1 | -0.01 |
| primary | scaled | beta10_B2_Mt0.9 | 4 | 994.3 | 840.7 | 18.3 | 1.46 |
| primary | scaled | beta10_B2_Mt0.9 | 6 | 785.5 | 547.2 | 43.6 | 3.14 |
| bracket | scaled | beta10_B2_Mt0.9 | 2 | 1310.7 | 1297.9 | 1.0 | 0.09 |
| bracket | scaled | beta10_B2_Mt0.9 | 4 | 1014.9 | 840.7 | 20.7 | 1.64 |
| bracket | scaled | beta10_B2_Mt0.9 | 6 | 813.9 | 547.2 | 48.7 | 3.45 |

23c scaled pressure (Fig.14 sample): 22/24 within ±2 dB (92.0%; need ≥75%).

## Fig. 13(a) first harmonic vs x/D (M_t=0.75, β=15°)

| polar | loads | x/D | A F1A | meas | residual % | residual dB |
|---|---|---:|---:|---:|---:|---:|
| primary | scaled_RM_L51C27 | -0.5 | 417.1 | 501.2 | -16.8 | -1.59 |
| primary | scaled_RM_L51C27 | -0.25 | 892.2 | 1001.8 | -10.9 | -1.01 |
| primary | scaled_RM_L51C27 | -0.125 | 1126.6 | 1327.9 | -15.2 | -1.43 |
| primary | scaled_RM_L51C27 | 0.0 | 735.6 | 762.9 | -3.6 | -0.32 |
| primary | scaled_RM_L51C27 | 0.125 | 1100.5 | 1008.5 | 9.1 | 0.76 |
| primary | scaled_RM_L51C27 | 0.25 | 837.6 | 835.3 | 0.3 | 0.02 |
| primary | scaled_RM_L51C27 | 0.5 | 342.0 | 355.4 | -3.8 | -0.33 |
| bracket | scaled_RM_L51C27 | -0.5 | 420.3 | 501.2 | -16.1 | -1.53 |
| bracket | scaled_RM_L51C27 | -0.25 | 900.3 | 1001.8 | -10.1 | -0.93 |
| bracket | scaled_RM_L51C27 | -0.125 | 1138.1 | 1327.9 | -14.3 | -1.34 |
| bracket | scaled_RM_L51C27 | 0.0 | 731.7 | 762.9 | -4.1 | -0.36 |
| bracket | scaled_RM_L51C27 | 0.125 | 1111.1 | 1008.5 | 10.2 | 0.84 |
| bracket | scaled_RM_L51C27 | 0.25 | 845.0 | 835.3 | 1.2 | 0.1 |
| bracket | scaled_RM_L51C27 | 0.5 | 345.0 | 355.4 | -2.9 | -0.26 |

23c scaled pressure (Fig.13a sample): 14/14 within ±2 dB.

## Fig. 12(a)/(b) harmonics vs x/D (β=10°, primary/scaled)

| fig | loads | x/D | mB | A F1A | meas | residual % |
|---|---|---:|--:|---:|---:|---:|
| fig12a | scaled | -0.25 | 2 | 583.2 | 600.4 | -2.9 |
| fig12a | scaled | -0.25 | 4 | 275.8 | 251.1 | 9.8 |
| fig12a | scaled | -0.25 | 6 | 131.3 | 101.9 | 28.9 |
| fig12a | scaled | -0.25 | 8 | 63.4 | 68.8 | -7.9 |
| fig12a | scaled | -0.125 | 2 | 677.4 | 621.8 | 8.9 |
| fig12a | scaled | -0.125 | 4 | 394.4 | 400.1 | -1.4 |
| fig12a | scaled | -0.125 | 6 | 229.5 | 234.0 | -1.9 |
| fig12a | scaled | -0.125 | 8 | 134.4 | 158.4 | -15.2 |
| fig12a | scaled | 0.0 | 2 | 297.4 | 400.0 | -25.7 |
| fig12a | scaled | 0.0 | 4 | 236.2 | 321.0 | -26.4 |
| fig12a | scaled | 0.0 | 6 | 188.7 | 213.5 | -11.6 |
| fig12a | scaled | 0.0 | 8 | 155.8 | 181.0 | -13.9 |
| fig12a | scaled | 0.125 | 2 | 757.6 | 661.1 | 14.6 |
| fig12a | scaled | 0.125 | 4 | 533.3 | 592.0 | -9.9 |
| fig12a | scaled | 0.125 | 6 | 369.7 | 404.4 | -8.6 |
| fig12a | scaled | 0.125 | 8 | 257.0 | 233.1 | 10.3 |
| fig12a | scaled | 0.25 | 2 | 625.9 | 562.9 | 11.2 |
| fig12a | scaled | 0.25 | 4 | 344.1 | 384.0 | -10.4 |
| fig12a | scaled | 0.25 | 6 | 188.5 | 224.6 | -16.1 |
| fig12a | scaled | 0.25 | 8 | 104.4 | 154.8 | -32.6 |
| fig12b | scaled | -0.25 | 2 | 1139.5 | 906.0 | 25.8 |
| fig12b | scaled | -0.25 | 4 | 749.8 | 656.7 | 14.2 |
| fig12b | scaled | -0.25 | 6 | 511.8 | 308.3 | 66.0 |
| fig12b | scaled | -0.25 | 8 | 360.5 | 256.7 | 40.4 |
| fig12b | scaled | -0.125 | 2 | 1296.4 | 1301.4 | -0.4 |
| fig12b | scaled | -0.125 | 4 | 994.3 | 852.1 | 16.7 |
| fig12b | scaled | -0.125 | 6 | 785.5 | 554.0 | 41.8 |
| fig12b | scaled | -0.125 | 8 | 639.5 | 503.7 | 27.0 |
| fig12b | scaled | 0.0 | 2 | 596.3 | 798.1 | -25.3 |
| fig12b | scaled | 0.0 | 4 | 662.7 | 579.6 | 14.3 |
| fig12b | scaled | 0.0 | 6 | 684.5 | 679.7 | 0.7 |
| fig12b | scaled | 0.0 | 8 | 693.0 | 626.0 | 10.7 |
| fig12b | scaled | 0.125 | 2 | 1310.5 | 1146.0 | 14.4 |
| fig12b | scaled | 0.125 | 4 | 1082.2 | 993.9 | 8.9 |
| fig12b | scaled | 0.125 | 6 | 896.7 | 896.2 | 0.1 |
| fig12b | scaled | 0.125 | 8 | 751.4 | 647.3 | 16.1 |
| fig12b | scaled | 0.25 | 2 | 1107.3 | 992.5 | 11.6 |
| fig12b | scaled | 0.25 | 4 | 754.2 | 791.8 | -4.8 |
| fig12b | scaled | 0.25 | 6 | 522.4 | 590.7 | -11.6 |
| fig12b | scaled | 0.25 | 8 | 368.7 | 390.3 | -5.5 |

## Fig. 7 p_c/C_P (β=15°, M_t=0.60, C_P legend=0.0424)

| polar | loads | x/D | p_c/C_P |
|---|---|---:|---:|
| primary | scaled | -0.5 | 0.0757 |
| primary | scaled | -0.25 | 0.2009 |
| primary | scaled | -0.125 | 0.2844 |
| primary | scaled | 0.0 | 0.1433 |
| primary | scaled | 0.125 | 0.3383 |
| primary | scaled | 0.25 | 0.2253 |
| primary | scaled | 0.5 | 0.0789 |
| bracket | scaled | -0.5 | 0.0771 |
| bracket | scaled | -0.25 | 0.204 |
| bracket | scaled | -0.125 | 0.2905 |
| bracket | scaled | 0.0 | 0.1569 |
| bracket | scaled | 0.125 | 0.3422 |
| bracket | scaled | 0.25 | 0.2266 |
| bracket | scaled | 0.5 | 0.0791 |

## Fig. 6 tip-clearance ratios (B=4, unscaled; ratio of max total-rms to d/D=0.083)

| d/D | p_rms max Pa | ratio to 0.083 |
|---:|---:|---:|
| 0.042 | 73.2 | 1.503 |
| 0.083 | 48.7 | 1.0 |
| 0.167 | 23.0 | 0.473 |
| 0.333 | 8.5 | 0.175 |

CSV: `data/report996/f1a_results.csv`.
