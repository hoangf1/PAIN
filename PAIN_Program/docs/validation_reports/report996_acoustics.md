# Report 996 Acoustics (phase 27)

Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.
Generated 2026-11-14 by `scripts/run/run_report996_acoustics.jl`.
Blade: `blade_form_r996_fig3c.csv`, β from Report 996 Fig. 3(c) (Phase 154, 2026-11-14; re-run post-hoc; the results on `blade_form.csv` are compared in `phase154_r996_blade_angle.md`).
**Re-run after plan I-01/I-02/I-08 (2026-11-14).** Criterion: VALIDATION_GUIDELINE §2.12 / 23c frozen 2026-10-21.
x_sign=R996_X_SIGN = +1 (report x/D positive ahead → AA +X, the direction the rotor travels; Phase 72, was −1). Thickness on (Phase 76; A/c² per station from the NACA 16 section contours). Harmonic A vs measured: A_rms = A_Pa/√2 (Report 996 p.10 rms).

## I-08 Fig. 13(a) load scale

RM L51C27 Table I (47-in., β₇₅=15°, M_t=0.75): T=225.0 lb, Q=114.0 lb·ft → C_T=0.0869, C_Q=0.01124; applied to 4-ft model: T_tgt=1043.9 N, Q_tgt=164.6 N·m. Tag `scaled_RM_L51C27` (replaces void fig14proxy).

## x-sign / asymmetry (25k)

A_rms(-0.125)=1126.4 vs A_rms(+0.125)=1102.8 dyne/cm² (meas ~1328 vs ~1009); behind>ahead=true

## Page-12 phase (one measured value)

Δφ(|x/D|=0.125) F1A=112.6° vs report measured 155° / Eq.(2) 165° (candidates ±0.125; exact stations not stated)

23c page-12 phase: |Δφ − 155°| = 42.4° → FAIL (±15°).

## Fig. 14 (scaled to table C_T/C_Q) — residual % vs digitized

| polar | loads | case | mB | A F1A dyne/cm² | meas | residual % | residual dB |
|---|---|---|--:|---:|---:|---:|---:|
| primary | scaled | beta10_B2_Mt0.45 | 2 | 176.3 | 200.9 | -12.2 | -1.13 |
| primary | scaled | beta10_B2_Mt0.45 | 4 | 84.3 | 100.0 | -15.7 | -1.48 |
| primary | scaled | beta10_B2_Mt0.45 | 6 | 41.1 | 50.1 | -18.0 | -1.73 |
| bracket | scaled | beta10_B2_Mt0.45 | 2 | 179.1 | 200.9 | -10.8 | -1.0 |
| bracket | scaled | beta10_B2_Mt0.45 | 4 | 86.0 | 100.0 | -14.0 | -1.31 |
| bracket | scaled | beta10_B2_Mt0.45 | 6 | 42.1 | 50.1 | -16.0 | -1.51 |
| primary | scaled | beta10_B2_Mt0.6 | 2 | 360.0 | 358.2 | 0.5 | 0.04 |
| primary | scaled | beta10_B2_Mt0.6 | 4 | 184.0 | 179.1 | 2.7 | 0.23 |
| primary | scaled | beta10_B2_Mt0.6 | 6 | 95.3 | 79.7 | 19.5 | 1.55 |
| bracket | scaled | beta10_B2_Mt0.6 | 2 | 365.2 | 358.2 | 2.0 | 0.17 |
| bracket | scaled | beta10_B2_Mt0.6 | 4 | 186.7 | 179.1 | 4.3 | 0.36 |
| bracket | scaled | beta10_B2_Mt0.6 | 6 | 97.1 | 79.7 | 21.8 | 1.71 |
| primary | scaled | beta10_B2_Mt0.75 | 2 | 676.0 | 661.0 | 2.3 | 0.2 |
| primary | scaled | beta10_B2_Mt0.75 | 4 | 391.4 | 399.6 | -2.0 | -0.18 |
| primary | scaled | beta10_B2_Mt0.75 | 6 | 226.7 | 229.0 | -1.0 | -0.09 |
| bracket | scaled | beta10_B2_Mt0.75 | 2 | 685.6 | 661.0 | 3.7 | 0.32 |
| bracket | scaled | beta10_B2_Mt0.75 | 4 | 394.9 | 399.6 | -1.2 | -0.1 |
| bracket | scaled | beta10_B2_Mt0.75 | 6 | 228.3 | 229.0 | -0.3 | -0.03 |
| primary | scaled | beta10_B2_Mt0.9 | 2 | 1274.2 | 1297.9 | -1.8 | -0.16 |
| primary | scaled | beta10_B2_Mt0.9 | 4 | 916.3 | 840.7 | 9.0 | 0.75 |
| primary | scaled | beta10_B2_Mt0.9 | 6 | 666.9 | 547.2 | 21.9 | 1.72 |
| bracket | scaled | beta10_B2_Mt0.9 | 2 | 1292.3 | 1297.9 | -0.4 | -0.04 |
| bracket | scaled | beta10_B2_Mt0.9 | 4 | 921.1 | 840.7 | 9.6 | 0.79 |
| bracket | scaled | beta10_B2_Mt0.9 | 6 | 666.1 | 547.2 | 21.7 | 1.71 |

23c scaled pressure (Fig.14 sample): 24/24 within ±2 dB (100.0%; need ≥75%).

## Fig. 13(a) first harmonic vs x/D (M_t=0.75, β=15°)

| polar | loads | x/D | A F1A | meas | residual % | residual dB |
|---|---|---:|---:|---:|---:|---:|
| primary | scaled_RM_L51C27 | -0.5 | 416.7 | 501.2 | -16.9 | -1.6 |
| primary | scaled_RM_L51C27 | -0.25 | 891.2 | 1001.8 | -11.0 | -1.02 |
| primary | scaled_RM_L51C27 | -0.125 | 1126.4 | 1327.9 | -15.2 | -1.43 |
| primary | scaled_RM_L51C27 | 0.0 | 735.5 | 762.9 | -3.6 | -0.32 |
| primary | scaled_RM_L51C27 | 0.125 | 1102.8 | 1008.5 | 9.3 | 0.78 |
| primary | scaled_RM_L51C27 | 0.25 | 838.3 | 835.3 | 0.4 | 0.03 |
| primary | scaled_RM_L51C27 | 0.5 | 342.4 | 355.4 | -3.7 | -0.32 |
| bracket | scaled_RM_L51C27 | -0.5 | 419.8 | 501.2 | -16.2 | -1.54 |
| bracket | scaled_RM_L51C27 | -0.25 | 899.2 | 1001.8 | -10.2 | -0.94 |
| bracket | scaled_RM_L51C27 | -0.125 | 1138.0 | 1327.9 | -14.3 | -1.34 |
| bracket | scaled_RM_L51C27 | 0.0 | 731.3 | 762.9 | -4.1 | -0.37 |
| bracket | scaled_RM_L51C27 | 0.125 | 1113.5 | 1008.5 | 10.4 | 0.86 |
| bracket | scaled_RM_L51C27 | 0.25 | 845.8 | 835.3 | 1.3 | 0.11 |
| bracket | scaled_RM_L51C27 | 0.5 | 345.4 | 355.4 | -2.8 | -0.25 |

23c scaled pressure (Fig.13a sample): 14/14 within ±2 dB.

## Fig. 12(a)/(b) harmonics vs x/D (β=10°, primary/scaled)

| fig | loads | x/D | mB | A F1A | meas | residual % |
|---|---|---:|--:|---:|---:|---:|
| fig12a | scaled | -0.25 | 2 | 582.4 | 600.4 | -3.0 |
| fig12a | scaled | -0.25 | 4 | 274.1 | 251.1 | 9.2 |
| fig12a | scaled | -0.25 | 6 | 130.0 | 101.9 | 27.6 |
| fig12a | scaled | -0.25 | 8 | 62.5 | 68.8 | -9.2 |
| fig12a | scaled | -0.125 | 2 | 676.0 | 621.8 | 8.7 |
| fig12a | scaled | -0.125 | 4 | 391.4 | 400.1 | -2.2 |
| fig12a | scaled | -0.125 | 6 | 226.7 | 234.0 | -3.1 |
| fig12a | scaled | -0.125 | 8 | 132.0 | 158.4 | -16.6 |
| fig12a | scaled | 0.0 | 2 | 297.5 | 400.0 | -25.6 |
| fig12a | scaled | 0.0 | 4 | 235.6 | 321.0 | -26.6 |
| fig12a | scaled | 0.0 | 6 | 189.0 | 213.5 | -11.5 |
| fig12a | scaled | 0.0 | 8 | 157.0 | 181.0 | -13.3 |
| fig12a | scaled | 0.125 | 2 | 759.0 | 661.1 | 14.8 |
| fig12a | scaled | 0.125 | 4 | 534.9 | 592.0 | -9.6 |
| fig12a | scaled | 0.125 | 6 | 371.4 | 404.4 | -8.1 |
| fig12a | scaled | 0.125 | 8 | 258.7 | 233.1 | 11.0 |
| fig12a | scaled | 0.25 | 2 | 627.0 | 562.9 | 11.4 |
| fig12a | scaled | 0.25 | 4 | 345.1 | 384.0 | -10.1 |
| fig12a | scaled | 0.25 | 6 | 189.3 | 224.6 | -15.7 |
| fig12a | scaled | 0.25 | 8 | 105.0 | 154.8 | -32.2 |
| fig12b | scaled | -0.25 | 2 | 1132.5 | 906.0 | 25.0 |
| fig12b | scaled | -0.25 | 4 | 707.6 | 656.7 | 7.7 |
| fig12b | scaled | -0.25 | 6 | 452.9 | 308.3 | 46.9 |
| fig12b | scaled | -0.25 | 8 | 297.8 | 256.7 | 16.0 |
| fig12b | scaled | -0.125 | 2 | 1274.2 | 1301.4 | -2.1 |
| fig12b | scaled | -0.125 | 4 | 916.3 | 852.1 | 7.5 |
| fig12b | scaled | -0.125 | 6 | 666.9 | 554.0 | 20.4 |
| fig12b | scaled | -0.125 | 8 | 496.2 | 503.7 | -1.5 |
| fig12b | scaled | 0.0 | 2 | 578.1 | 798.1 | -27.6 |
| fig12b | scaled | 0.0 | 4 | 543.7 | 579.6 | -6.2 |
| fig12b | scaled | 0.0 | 6 | 505.0 | 679.7 | -25.7 |
| fig12b | scaled | 0.0 | 8 | 480.0 | 626.0 | -23.3 |
| fig12b | scaled | 0.125 | 2 | 1284.5 | 1146.0 | 12.1 |
| fig12b | scaled | 0.125 | 4 | 1052.3 | 993.9 | 5.9 |
| fig12b | scaled | 0.125 | 6 | 867.3 | 896.2 | -3.2 |
| fig12b | scaled | 0.125 | 8 | 723.5 | 647.3 | 11.8 |
| fig12b | scaled | 0.25 | 2 | 1097.8 | 992.5 | 10.6 |
| fig12b | scaled | 0.25 | 4 | 750.5 | 791.8 | -5.2 |
| fig12b | scaled | 0.25 | 6 | 524.3 | 590.7 | -11.2 |
| fig12b | scaled | 0.25 | 8 | 373.7 | 390.3 | -4.3 |

## Fig. 7 p_c/C_P (β=15°, M_t=0.60, C_P legend=0.0424)

| polar | loads | x/D | p_c/C_P |
|---|---|---:|---:|
| primary | scaled | -0.5 | 0.0741 |
| primary | scaled | -0.25 | 0.1968 |
| primary | scaled | -0.125 | 0.278 |
| primary | scaled | 0.0 | 0.1385 |
| primary | scaled | 0.125 | 0.3336 |
| primary | scaled | 0.25 | 0.2223 |
| primary | scaled | 0.5 | 0.0778 |
| bracket | scaled | -0.5 | 0.0753 |
| bracket | scaled | -0.25 | 0.1993 |
| bracket | scaled | -0.125 | 0.2828 |
| bracket | scaled | 0.0 | 0.148 |
| bracket | scaled | 0.125 | 0.3368 |
| bracket | scaled | 0.25 | 0.2233 |
| bracket | scaled | 0.5 | 0.078 |

## Fig. 6 tip-clearance ratios (B=4, unscaled; ratio of max total-rms to d/D=0.083)

| d/D | p_rms max Pa | ratio to 0.083 |
|---:|---:|---:|
| 0.042 | 71.4 | 1.501 |
| 0.083 | 47.5 | 1.0 |
| 0.167 | 22.6 | 0.475 |
| 0.333 | 8.4 | 0.176 |

CSV: `data/report996/f1a_results.csv`.
