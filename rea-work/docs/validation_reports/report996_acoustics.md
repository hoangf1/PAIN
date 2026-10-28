# Report 996 Acoustics (phase 27)

Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.
Generated 2026-10-28 by `scripts/run/run_report996_acoustics.jl`.
**Re-run after plan I-01/I-02/I-08 (2026-10-28).** Criterion: VALIDATION_GUIDELINE §2.12 / 23c frozen 2026-10-21.
x_sign=R996_X_SIGN = +1 (report x/D positive ahead → AA +X, the direction the rotor travels; Phase 72, was −1). Thickness on (Phase 76; A/c² per station from the NACA 16 section contours). Harmonic A vs measured: A_rms = A_Pa/√2 (Report 996 p.10 rms).

## I-08 Fig. 13(a) load scale

RM L51C27 Table I (47-in., β₇₅=15°, M_t=0.75): T=225.0 lb, Q=114.0 lb·ft → C_T=0.0869, C_Q=0.01124; applied to 4-ft model: T_tgt=1043.9 N, Q_tgt=164.6 N·m. Tag `scaled_RM_L51C27` (replaces void fig14proxy).

## x-sign / asymmetry (25k)

A_rms(-0.125)=1130.4 vs A_rms(+0.125)=1106.7 dyne/cm² (meas ~1328 vs ~1009); behind>ahead=true

## Page-12 phase (one measured value)

Δφ(|x/D|=0.125) F1A=112.8° vs report measured 155° / Eq.(2) 165° (candidates ±0.125; exact stations not stated)

23c page-12 phase: |Δφ − 155°| = 42.2° → FAIL (±15°).

## Fig. 14 (scaled to table C_T/C_Q) — residual % vs digitized

| polar | loads | case | mB | A F1A dyne/cm² | meas | residual % | residual dB |
|---|---|---|--:|---:|---:|---:|---:|
| primary | scaled | beta10_B2_Mt0.45 | 2 | 178.1 | 200.9 | -11.4 | -1.05 |
| primary | scaled | beta10_B2_Mt0.45 | 4 | 85.7 | 100.0 | -14.3 | -1.34 |
| primary | scaled | beta10_B2_Mt0.45 | 6 | 42.0 | 50.1 | -16.1 | -1.52 |
| bracket | scaled | beta10_B2_Mt0.45 | 2 | 180.6 | 200.9 | -10.1 | -0.93 |
| bracket | scaled | beta10_B2_Mt0.45 | 4 | 87.2 | 100.0 | -12.8 | -1.19 |
| bracket | scaled | beta10_B2_Mt0.45 | 6 | 43.0 | 50.1 | -14.2 | -1.33 |
| primary | scaled | beta10_B2_Mt0.6 | 2 | 363.9 | 358.2 | 1.6 | 0.14 |
| primary | scaled | beta10_B2_Mt0.6 | 4 | 187.2 | 179.1 | 4.5 | 0.38 |
| primary | scaled | beta10_B2_Mt0.6 | 6 | 97.7 | 79.7 | 22.6 | 1.77 |
| bracket | scaled | beta10_B2_Mt0.6 | 2 | 369.2 | 358.2 | 3.1 | 0.26 |
| bracket | scaled | beta10_B2_Mt0.6 | 4 | 190.0 | 179.1 | 6.1 | 0.51 |
| bracket | scaled | beta10_B2_Mt0.6 | 6 | 99.5 | 79.7 | 24.9 | 1.93 |
| primary | scaled | beta10_B2_Mt0.75 | 2 | 682.7 | 661.0 | 3.3 | 0.28 |
| primary | scaled | beta10_B2_Mt0.75 | 4 | 397.6 | 399.6 | -0.5 | -0.04 |
| primary | scaled | beta10_B2_Mt0.75 | 6 | 231.8 | 229.0 | 1.2 | 0.1 |
| bracket | scaled | beta10_B2_Mt0.75 | 2 | 692.5 | 661.0 | 4.8 | 0.4 |
| bracket | scaled | beta10_B2_Mt0.75 | 4 | 401.3 | 399.6 | 0.4 | 0.04 |
| bracket | scaled | beta10_B2_Mt0.75 | 6 | 233.5 | 229.0 | 2.0 | 0.17 |
| primary | scaled | beta10_B2_Mt0.9 | 2 | 1286.8 | 1297.9 | -0.9 | -0.07 |
| primary | scaled | beta10_B2_Mt0.9 | 4 | 929.8 | 840.7 | 10.6 | 0.87 |
| primary | scaled | beta10_B2_Mt0.9 | 6 | 680.1 | 547.2 | 24.3 | 1.89 |
| bracket | scaled | beta10_B2_Mt0.9 | 2 | 1305.6 | 1297.9 | 0.6 | 0.05 |
| bracket | scaled | beta10_B2_Mt0.9 | 4 | 935.0 | 840.7 | 11.2 | 0.92 |
| bracket | scaled | beta10_B2_Mt0.9 | 6 | 679.3 | 547.2 | 24.1 | 1.88 |

23c scaled pressure (Fig.14 sample): 24/24 within ±2 dB (100.0%; need ≥75%).

## Fig. 13(a) first harmonic vs x/D (M_t=0.75, β=15°)

| polar | loads | x/D | A F1A | meas | residual % | residual dB |
|---|---|---:|---:|---:|---:|---:|
| primary | scaled_RM_L51C27 | -0.5 | 417.2 | 501.2 | -16.8 | -1.59 |
| primary | scaled_RM_L51C27 | -0.25 | 893.0 | 1001.8 | -10.9 | -1.0 |
| primary | scaled_RM_L51C27 | -0.125 | 1130.4 | 1327.9 | -14.9 | -1.4 |
| primary | scaled_RM_L51C27 | 0.0 | 736.2 | 762.9 | -3.5 | -0.31 |
| primary | scaled_RM_L51C27 | 0.125 | 1106.7 | 1008.5 | 9.7 | 0.81 |
| primary | scaled_RM_L51C27 | 0.25 | 840.2 | 835.3 | 0.6 | 0.05 |
| primary | scaled_RM_L51C27 | 0.5 | 342.9 | 355.4 | -3.5 | -0.31 |
| bracket | scaled_RM_L51C27 | -0.5 | 420.4 | 501.2 | -16.1 | -1.53 |
| bracket | scaled_RM_L51C27 | -0.25 | 901.2 | 1001.8 | -10.0 | -0.92 |
| bracket | scaled_RM_L51C27 | -0.125 | 1142.2 | 1327.9 | -14.0 | -1.31 |
| bracket | scaled_RM_L51C27 | 0.0 | 732.0 | 762.9 | -4.1 | -0.36 |
| bracket | scaled_RM_L51C27 | 0.125 | 1117.7 | 1008.5 | 10.8 | 0.89 |
| bracket | scaled_RM_L51C27 | 0.25 | 847.8 | 835.3 | 1.5 | 0.13 |
| bracket | scaled_RM_L51C27 | 0.5 | 345.9 | 355.4 | -2.7 | -0.23 |

23c scaled pressure (Fig.13a sample): 14/14 within ±2 dB.

## Fig. 12(a)/(b) harmonics vs x/D (β=10°, primary/scaled)

| fig | loads | x/D | mB | A F1A | meas | residual % |
|---|---|---:|--:|---:|---:|---:|
| fig12a | scaled | -0.25 | 2 | 585.9 | 600.4 | -2.4 |
| fig12a | scaled | -0.25 | 4 | 277.1 | 251.1 | 10.4 |
| fig12a | scaled | -0.25 | 6 | 132.1 | 101.9 | 29.7 |
| fig12a | scaled | -0.25 | 8 | 63.9 | 68.8 | -7.1 |
| fig12a | scaled | -0.125 | 2 | 682.7 | 621.8 | 9.8 |
| fig12a | scaled | -0.125 | 4 | 397.6 | 400.1 | -0.6 |
| fig12a | scaled | -0.125 | 6 | 231.8 | 234.0 | -0.9 |
| fig12a | scaled | -0.125 | 8 | 136.0 | 158.4 | -14.1 |
| fig12a | scaled | 0.0 | 2 | 297.7 | 400.0 | -25.6 |
| fig12a | scaled | 0.0 | 4 | 236.4 | 321.0 | -26.3 |
| fig12a | scaled | 0.0 | 6 | 189.9 | 213.5 | -11.1 |
| fig12a | scaled | 0.0 | 8 | 157.7 | 181.0 | -12.9 |
| fig12a | scaled | 0.125 | 2 | 765.8 | 661.1 | 15.8 |
| fig12a | scaled | 0.125 | 4 | 541.2 | 592.0 | -8.6 |
| fig12a | scaled | 0.125 | 6 | 376.6 | 404.4 | -6.9 |
| fig12a | scaled | 0.125 | 8 | 262.8 | 233.1 | 12.7 |
| fig12a | scaled | 0.25 | 2 | 630.6 | 562.9 | 12.0 |
| fig12a | scaled | 0.25 | 4 | 348.1 | 384.0 | -9.3 |
| fig12a | scaled | 0.25 | 6 | 191.4 | 224.6 | -14.8 |
| fig12a | scaled | 0.25 | 8 | 106.4 | 154.8 | -31.3 |
| fig12b | scaled | -0.25 | 2 | 1139.3 | 906.0 | 25.7 |
| fig12b | scaled | -0.25 | 4 | 715.2 | 656.7 | 8.9 |
| fig12b | scaled | -0.25 | 6 | 460.0 | 308.3 | 49.2 |
| fig12b | scaled | -0.25 | 8 | 303.9 | 256.7 | 18.4 |
| fig12b | scaled | -0.125 | 2 | 1286.8 | 1301.4 | -1.1 |
| fig12b | scaled | -0.125 | 4 | 929.8 | 852.1 | 9.1 |
| fig12b | scaled | -0.125 | 6 | 680.1 | 554.0 | 22.8 |
| fig12b | scaled | -0.125 | 8 | 508.4 | 503.7 | 0.9 |
| fig12b | scaled | 0.0 | 2 | 578.4 | 798.1 | -27.5 |
| fig12b | scaled | 0.0 | 4 | 545.8 | 579.6 | -5.8 |
| fig12b | scaled | 0.0 | 6 | 507.8 | 679.7 | -25.3 |
| fig12b | scaled | 0.0 | 8 | 483.1 | 626.0 | -22.8 |
| fig12b | scaled | 0.125 | 2 | 1297.2 | 1146.0 | 13.2 |
| fig12b | scaled | 0.125 | 4 | 1065.1 | 993.9 | 7.2 |
| fig12b | scaled | 0.125 | 6 | 879.6 | 896.2 | -1.9 |
| fig12b | scaled | 0.125 | 8 | 734.8 | 647.3 | 13.5 |
| fig12b | scaled | 0.25 | 2 | 1104.6 | 992.5 | 11.3 |
| fig12b | scaled | 0.25 | 4 | 757.6 | 791.8 | -4.3 |
| fig12b | scaled | 0.25 | 6 | 530.7 | 590.7 | -10.2 |
| fig12b | scaled | 0.25 | 8 | 379.1 | 390.3 | -2.9 |

## Fig. 7 p_c/C_P (β=15°, M_t=0.60, C_P legend=0.0424)

| polar | loads | x/D | p_c/C_P |
|---|---|---:|---:|
| primary | scaled | -0.5 | 0.0739 |
| primary | scaled | -0.25 | 0.1967 |
| primary | scaled | -0.125 | 0.2785 |
| primary | scaled | 0.0 | 0.1383 |
| primary | scaled | 0.125 | 0.3343 |
| primary | scaled | 0.25 | 0.2223 |
| primary | scaled | 0.5 | 0.0778 |
| bracket | scaled | -0.5 | 0.0752 |
| bracket | scaled | -0.25 | 0.1993 |
| bracket | scaled | -0.125 | 0.2835 |
| bracket | scaled | 0.0 | 0.1475 |
| bracket | scaled | 0.125 | 0.3377 |
| bracket | scaled | 0.25 | 0.2234 |
| bracket | scaled | 0.5 | 0.0779 |

## Fig. 6 tip-clearance ratios (B=4, unscaled; ratio of max total-rms to d/D=0.083)

| d/D | p_rms max Pa | ratio to 0.083 |
|---:|---:|---:|
| 0.042 | 72.6 | 1.502 |
| 0.083 | 48.4 | 1.0 |
| 0.167 | 22.9 | 0.474 |
| 0.333 | 8.5 | 0.175 |

CSV: `data/report996/f1a_results.csv`.
