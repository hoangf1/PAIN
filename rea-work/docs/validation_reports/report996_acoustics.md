# Report 996 Acoustics (phase 27)

Generated 2026-10-21 by `scripts/run_report996_acoustics.jl`.
**Re-run after plan I-01/I-02/I-08 (2026-10-21).** Criterion: VALIDATION_GUIDELINE §2.12 / 23c frozen 2026-10-21.
x_sign=−1 (report behind → AA +X). Thickness off.

## I-08 Fig. 13(a) load scale

RM L51C27 Table I (47-in., β₇₅=15°, M_t=0.75): T=225.0 lb, Q=114.0 lb·ft → C_T=0.0869, C_Q=0.01124; applied to 4-ft model: T_tgt=1043.9 N, Q_tgt=164.6 N·m. Tag `scaled_RM_L51C27` (replaces void fig14proxy).

## x-sign / asymmetry (25k)

A(-0.125)=1291.9 vs A(+0.125)=1508.4 dyne/cm² (meas ~1328 vs ~1009); behind>ahead=false

## Page-12 phase (one measured value)

Δφ(|x/D|=0.125) F1A=103.8° vs report measured 155° / Eq.(2) 165° (candidates ±0.125; exact stations not stated)

23c page-12 phase: |Δφ − 155°| = 51.2° → FAIL (±15°).

## Fig. 14 (scaled to table C_T/C_Q) — residual % vs digitized

| polar | loads | case | mB | A F1A dyne/cm² | meas | residual % | residual dB |
|---|---|---|--:|---:|---:|---:|---:|
| primary | scaled | beta10_B2_Mt0.45 | 2 | 255.4 | 200.9 | 27.1 | 2.08 |
| primary | scaled | beta10_B2_Mt0.45 | 4 | 131.7 | 100.0 | 31.7 | 2.39 |
| primary | scaled | beta10_B2_Mt0.45 | 6 | 68.9 | 50.1 | 37.5 | 2.76 |
| bracket | scaled | beta10_B2_Mt0.45 | 2 | 259.3 | 200.9 | 29.1 | 2.22 |
| bracket | scaled | beta10_B2_Mt0.45 | 4 | 134.4 | 100.0 | 34.4 | 2.57 |
| bracket | scaled | beta10_B2_Mt0.45 | 6 | 70.6 | 50.1 | 40.8 | 2.97 |
| primary | scaled | beta10_B2_Mt0.6 | 2 | 497.5 | 358.2 | 38.9 | 2.85 |
| primary | scaled | beta10_B2_Mt0.6 | 4 | 277.6 | 179.1 | 55.0 | 3.81 |
| primary | scaled | beta10_B2_Mt0.6 | 6 | 156.4 | 79.7 | 96.2 | 5.85 |
| bracket | scaled | beta10_B2_Mt0.6 | 2 | 505.4 | 358.2 | 41.1 | 2.99 |
| bracket | scaled | beta10_B2_Mt0.6 | 4 | 283.4 | 179.1 | 58.3 | 3.99 |
| bracket | scaled | beta10_B2_Mt0.6 | 6 | 160.2 | 79.7 | 101.0 | 6.07 |
| primary | scaled | beta10_B2_Mt0.75 | 2 | 824.6 | 661.0 | 24.8 | 1.92 |
| primary | scaled | beta10_B2_Mt0.75 | 4 | 505.0 | 399.6 | 26.4 | 2.03 |
| primary | scaled | beta10_B2_Mt0.75 | 6 | 316.0 | 229.0 | 38.0 | 2.8 |
| bracket | scaled | beta10_B2_Mt0.75 | 2 | 835.5 | 661.0 | 26.4 | 2.04 |
| bracket | scaled | beta10_B2_Mt0.75 | 4 | 513.8 | 399.6 | 28.6 | 2.18 |
| bracket | scaled | beta10_B2_Mt0.75 | 6 | 322.6 | 229.0 | 40.9 | 2.98 |
| primary | scaled | beta10_B2_Mt0.9 | 2 | 1422.7 | 1297.9 | 9.6 | 0.8 |
| primary | scaled | beta10_B2_Mt0.9 | 4 | 1015.6 | 840.7 | 20.8 | 1.64 |
| primary | scaled | beta10_B2_Mt0.9 | 6 | 759.5 | 547.2 | 38.8 | 2.85 |
| bracket | scaled | beta10_B2_Mt0.9 | 2 | 1448.0 | 1297.9 | 11.6 | 0.95 |
| bracket | scaled | beta10_B2_Mt0.9 | 4 | 1039.3 | 840.7 | 23.6 | 1.84 |
| bracket | scaled | beta10_B2_Mt0.9 | 6 | 781.0 | 547.2 | 42.7 | 3.09 |

23c scaled pressure (Fig.14 sample): 5/24 within ±2 dB (21.0%; need ≥75%).

## Fig. 13(a) first harmonic vs x/D (M_t=0.75, β=15°)

| polar | loads | x/D | A F1A | meas | residual % | residual dB |
|---|---|---:|---:|---:|---:|---:|
| primary | scaled_RM_L51C27 | -0.5 | 411.8 | 501.2 | -17.8 | -1.71 |
| primary | scaled_RM_L51C27 | -0.25 | 998.7 | 1001.8 | -0.3 | -0.03 |
| primary | scaled_RM_L51C27 | -0.125 | 1291.9 | 1327.9 | -2.7 | -0.24 |
| primary | scaled_RM_L51C27 | 0.0 | 1019.3 | 762.9 | 33.6 | 2.52 |
| primary | scaled_RM_L51C27 | 0.125 | 1508.4 | 1008.5 | 49.6 | 3.5 |
| primary | scaled_RM_L51C27 | 0.25 | 1210.0 | 835.3 | 44.9 | 3.22 |
| primary | scaled_RM_L51C27 | 0.5 | 576.4 | 355.4 | 62.2 | 4.2 |
| bracket | scaled_RM_L51C27 | -0.5 | 414.7 | 501.2 | -17.3 | -1.65 |
| bracket | scaled_RM_L51C27 | -0.25 | 1007.1 | 1001.8 | 0.5 | 0.05 |
| bracket | scaled_RM_L51C27 | -0.125 | 1304.7 | 1327.9 | -1.7 | -0.15 |
| bracket | scaled_RM_L51C27 | 0.0 | 1017.9 | 762.9 | 33.4 | 2.5 |
| bracket | scaled_RM_L51C27 | 0.125 | 1522.7 | 1008.5 | 51.0 | 3.58 |
| bracket | scaled_RM_L51C27 | 0.25 | 1219.1 | 835.3 | 45.9 | 3.28 |
| bracket | scaled_RM_L51C27 | 0.5 | 579.6 | 355.4 | 63.1 | 4.25 |

23c scaled pressure (Fig.13a sample): 6/14 within ±2 dB.

## Fig. 12(a)/(b) harmonics vs x/D (β=10°, primary/scaled)

| fig | loads | x/D | mB | A F1A | meas | residual % |
|---|---|---:|--:|---:|---:|---:|
| fig12a | scaled | -0.25 | 2 | 710.2 | 600.4 | 18.3 |
| fig12a | scaled | -0.25 | 4 | 339.7 | 251.1 | 35.3 |
| fig12a | scaled | -0.25 | 6 | 167.7 | 101.9 | 64.6 |
| fig12a | scaled | -0.25 | 8 | 85.4 | 68.8 | 24.2 |
| fig12a | scaled | -0.125 | 2 | 824.6 | 621.8 | 32.6 |
| fig12a | scaled | -0.125 | 4 | 505.0 | 400.1 | 26.2 |
| fig12a | scaled | -0.125 | 6 | 316.0 | 234.0 | 35.1 |
| fig12a | scaled | -0.125 | 8 | 202.8 | 158.4 | 28.0 |
| fig12a | scaled | 0.0 | 2 | 393.3 | 400.0 | -1.7 |
| fig12a | scaled | 0.0 | 4 | 246.5 | 321.0 | -23.2 |
| fig12a | scaled | 0.0 | 6 | 152.3 | 213.5 | -28.7 |
| fig12a | scaled | 0.0 | 8 | 98.6 | 181.0 | -45.5 |
| fig12a | scaled | 0.125 | 2 | 924.4 | 661.1 | 39.8 |
| fig12a | scaled | 0.125 | 4 | 557.9 | 592.0 | -5.8 |
| fig12a | scaled | 0.125 | 6 | 342.6 | 404.4 | -15.3 |
| fig12a | scaled | 0.125 | 8 | 216.7 | 233.1 | -7.0 |
| fig12a | scaled | 0.25 | 2 | 804.9 | 562.9 | 43.0 |
| fig12a | scaled | 0.25 | 4 | 384.8 | 384.0 | 0.2 |
| fig12a | scaled | 0.25 | 6 | 188.0 | 224.6 | -16.3 |
| fig12a | scaled | 0.25 | 8 | 94.9 | 154.8 | -38.7 |
| fig12b | scaled | -0.25 | 2 | 1248.3 | 906.0 | 37.8 |
| fig12b | scaled | -0.25 | 4 | 752.8 | 656.7 | 14.6 |
| fig12b | scaled | -0.25 | 6 | 486.2 | 308.3 | 57.7 |
| fig12b | scaled | -0.25 | 8 | 327.0 | 256.7 | 27.4 |
| fig12b | scaled | -0.125 | 2 | 1422.7 | 1301.4 | 9.3 |
| fig12b | scaled | -0.125 | 4 | 1015.6 | 852.1 | 19.2 |
| fig12b | scaled | -0.125 | 6 | 759.5 | 554.0 | 37.1 |
| fig12b | scaled | -0.125 | 8 | 586.1 | 503.7 | 16.4 |
| fig12b | scaled | 0.0 | 2 | 775.5 | 798.1 | -2.8 |
| fig12b | scaled | 0.0 | 4 | 583.1 | 579.6 | 0.6 |
| fig12b | scaled | 0.0 | 6 | 439.3 | 679.7 | -35.4 |
| fig12b | scaled | 0.0 | 8 | 348.4 | 626.0 | -44.3 |
| fig12b | scaled | 0.125 | 2 | 1767.4 | 1146.0 | 54.2 |
| fig12b | scaled | 0.125 | 4 | 1298.7 | 993.9 | 30.7 |
| fig12b | scaled | 0.125 | 6 | 975.4 | 896.2 | 8.8 |
| fig12b | scaled | 0.125 | 8 | 754.6 | 647.3 | 16.6 |
| fig12b | scaled | 0.25 | 2 | 1564.7 | 992.5 | 57.7 |
| fig12b | scaled | 0.25 | 4 | 976.0 | 791.8 | 23.3 |
| fig12b | scaled | 0.25 | 6 | 632.0 | 590.7 | 7.0 |
| fig12b | scaled | 0.25 | 8 | 425.0 | 390.3 | 8.9 |

## Fig. 7 p_c/C_P (β=15°, M_t=0.60, C_P legend=0.0424)

| polar | loads | x/D | p_c/C_P |
|---|---|---:|---:|
| primary | scaled | -0.5 | 0.0786 |
| primary | scaled | -0.25 | 0.2215 |
| primary | scaled | -0.125 | 0.3214 |
| primary | scaled | 0.0 | 0.1323 |
| primary | scaled | 0.125 | 0.3322 |
| primary | scaled | 0.25 | 0.2324 |
| primary | scaled | 0.5 | 0.0878 |
| bracket | scaled | -0.5 | 0.0786 |
| bracket | scaled | -0.25 | 0.2222 |
| bracket | scaled | -0.125 | 0.324 |
| bracket | scaled | 0.0 | 0.135 |
| bracket | scaled | 0.125 | 0.335 |
| bracket | scaled | 0.25 | 0.2333 |
| bracket | scaled | 0.5 | 0.088 |

## Fig. 6 tip-clearance ratios (B=4, unscaled; ratio of max total-rms to d/D=0.083)

| d/D | p_rms max Pa | ratio to 0.083 |
|---:|---:|---:|
| 0.042 | 42.7 | 1.517 |
| 0.083 | 28.2 | 1.0 |
| 0.167 | 13.5 | 0.479 |
| 0.333 | 5.8 | 0.207 |

CSV: `data/report996/f1a_results.csv`.
