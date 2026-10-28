# Report 996 Acoustics (phase 27)

Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.
Generated 2026-10-28 by `scripts/run/run_report996_acoustics.jl`.
**Re-run after plan I-01/I-02/I-08 (2026-10-28).** Criterion: VALIDATION_GUIDELINE §2.12 / 23c frozen 2026-10-21.
x_sign=R996_X_SIGN = +1 (report x/D positive ahead → AA +X, the direction the rotor travels; Phase 72, was −1). Thickness off. Harmonic A vs measured: A_rms = A_Pa/√2 (Report 996 p.10 rms).

## I-08 Fig. 13(a) load scale

RM L51C27 Table I (47-in., β₇₅=15°, M_t=0.75): T=225.0 lb, Q=114.0 lb·ft → C_T=0.0869, C_Q=0.01124; applied to 4-ft model: T_tgt=1043.9 N, Q_tgt=164.6 N·m. Tag `scaled_RM_L51C27` (replaces void fig14proxy).

## x-sign / asymmetry (25k)

A_rms(-0.125)=1193.4 vs A_rms(+0.125)=1031.7 dyne/cm² (meas ~1328 vs ~1009); behind>ahead=true

## Page-12 phase (one measured value)

Δφ(|x/D|=0.125) F1A=113.6° vs report measured 155° / Eq.(2) 165° (candidates ±0.125; exact stations not stated)

23c page-12 phase: |Δφ − 155°| = 41.4° → FAIL (±15°).

## Fig. 14 (scaled to table C_T/C_Q) — residual % vs digitized

| polar | loads | case | mB | A F1A dyne/cm² | meas | residual % | residual dB |
|---|---|---|--:|---:|---:|---:|---:|
| primary | scaled | beta10_B2_Mt0.45 | 2 | 199.0 | 200.9 | -0.9 | -0.08 |
| primary | scaled | beta10_B2_Mt0.45 | 4 | 104.9 | 100.0 | 4.9 | 0.42 |
| primary | scaled | beta10_B2_Mt0.45 | 6 | 55.9 | 50.1 | 11.5 | 0.95 |
| bracket | scaled | beta10_B2_Mt0.45 | 2 | 201.6 | 200.9 | 0.3 | 0.03 |
| bracket | scaled | beta10_B2_Mt0.45 | 4 | 106.5 | 100.0 | 6.5 | 0.55 |
| bracket | scaled | beta10_B2_Mt0.45 | 6 | 56.9 | 50.1 | 13.5 | 1.1 |
| primary | scaled | beta10_B2_Mt0.6 | 2 | 405.4 | 358.2 | 13.2 | 1.07 |
| primary | scaled | beta10_B2_Mt0.6 | 4 | 229.8 | 179.1 | 28.3 | 2.17 |
| primary | scaled | beta10_B2_Mt0.6 | 6 | 131.2 | 79.7 | 64.6 | 4.33 |
| bracket | scaled | beta10_B2_Mt0.6 | 2 | 410.7 | 358.2 | 14.7 | 1.19 |
| bracket | scaled | beta10_B2_Mt0.6 | 4 | 233.0 | 179.1 | 30.1 | 2.28 |
| bracket | scaled | beta10_B2_Mt0.6 | 6 | 133.3 | 79.7 | 67.3 | 4.47 |
| primary | scaled | beta10_B2_Mt0.75 | 2 | 755.6 | 661.0 | 14.3 | 1.16 |
| primary | scaled | beta10_B2_Mt0.75 | 4 | 484.7 | 399.6 | 21.3 | 1.68 |
| primary | scaled | beta10_B2_Mt0.75 | 6 | 310.8 | 229.0 | 35.7 | 2.65 |
| bracket | scaled | beta10_B2_Mt0.75 | 2 | 765.6 | 661.0 | 15.8 | 1.28 |
| bracket | scaled | beta10_B2_Mt0.75 | 4 | 489.5 | 399.6 | 22.5 | 1.76 |
| bracket | scaled | beta10_B2_Mt0.75 | 6 | 313.9 | 229.0 | 37.1 | 2.74 |
| primary | scaled | beta10_B2_Mt0.9 | 2 | 1401.2 | 1297.9 | 8.0 | 0.66 |
| primary | scaled | beta10_B2_Mt0.9 | 4 | 1085.1 | 840.7 | 29.1 | 2.22 |
| primary | scaled | beta10_B2_Mt0.9 | 6 | 841.3 | 547.2 | 53.7 | 3.74 |
| bracket | scaled | beta10_B2_Mt0.9 | 2 | 1420.3 | 1297.9 | 9.4 | 0.78 |
| bracket | scaled | beta10_B2_Mt0.9 | 4 | 1092.9 | 840.7 | 30.0 | 2.28 |
| bracket | scaled | beta10_B2_Mt0.9 | 6 | 844.9 | 547.2 | 54.4 | 3.77 |

23c scaled pressure (Fig.14 sample): 14/24 within ±2 dB (58.0%; need ≥75%).

## Fig. 13(a) first harmonic vs x/D (M_t=0.75, β=15°)

| polar | loads | x/D | A F1A | meas | residual % | residual dB |
|---|---|---:|---:|---:|---:|---:|
| primary | scaled_RM_L51C27 | -0.5 | 436.1 | 501.2 | -13.0 | -1.21 |
| primary | scaled_RM_L51C27 | -0.25 | 939.1 | 1001.8 | -6.3 | -0.56 |
| primary | scaled_RM_L51C27 | -0.125 | 1193.4 | 1327.9 | -10.1 | -0.93 |
| primary | scaled_RM_L51C27 | 0.0 | 729.3 | 762.9 | -4.4 | -0.39 |
| primary | scaled_RM_L51C27 | 0.125 | 1031.7 | 1008.5 | 2.3 | 0.2 |
| primary | scaled_RM_L51C27 | 0.25 | 784.0 | 835.3 | -6.1 | -0.55 |
| primary | scaled_RM_L51C27 | 0.5 | 316.4 | 355.4 | -11.0 | -1.01 |
| bracket | scaled_RM_L51C27 | -0.5 | 439.3 | 501.2 | -12.4 | -1.15 |
| bracket | scaled_RM_L51C27 | -0.25 | 947.3 | 1001.8 | -5.4 | -0.49 |
| bracket | scaled_RM_L51C27 | -0.125 | 1205.5 | 1327.9 | -9.2 | -0.84 |
| bracket | scaled_RM_L51C27 | 0.0 | 725.2 | 762.9 | -4.9 | -0.44 |
| bracket | scaled_RM_L51C27 | 0.125 | 1042.4 | 1008.5 | 3.4 | 0.29 |
| bracket | scaled_RM_L51C27 | 0.25 | 791.5 | 835.3 | -5.2 | -0.47 |
| bracket | scaled_RM_L51C27 | 0.5 | 319.4 | 355.4 | -10.1 | -0.93 |

23c scaled pressure (Fig.13a sample): 14/14 within ±2 dB.

## Fig. 12(a)/(b) harmonics vs x/D (β=10°, primary/scaled)

| fig | loads | x/D | mB | A F1A | meas | residual % |
|---|---|---:|--:|---:|---:|---:|
| fig12a | scaled | -0.25 | 2 | 638.5 | 600.4 | 6.3 |
| fig12a | scaled | -0.25 | 4 | 326.7 | 251.1 | 30.1 |
| fig12a | scaled | -0.25 | 6 | 167.8 | 101.9 | 64.7 |
| fig12a | scaled | -0.25 | 8 | 87.6 | 68.8 | 27.3 |
| fig12a | scaled | -0.125 | 2 | 755.6 | 621.8 | 21.5 |
| fig12a | scaled | -0.125 | 4 | 484.7 | 400.1 | 21.1 |
| fig12a | scaled | -0.125 | 6 | 310.8 | 234.0 | 32.8 |
| fig12a | scaled | -0.125 | 8 | 201.8 | 158.4 | 27.4 |
| fig12a | scaled | 0.0 | 2 | 281.3 | 400.0 | -29.7 |
| fig12a | scaled | 0.0 | 4 | 196.6 | 321.0 | -38.8 |
| fig12a | scaled | 0.0 | 6 | 134.5 | 213.5 | -37.0 |
| fig12a | scaled | 0.0 | 8 | 94.6 | 181.0 | -47.7 |
| fig12a | scaled | 0.125 | 2 | 683.9 | 661.1 | 3.4 |
| fig12a | scaled | 0.125 | 4 | 442.8 | 592.0 | -25.2 |
| fig12a | scaled | 0.125 | 6 | 287.6 | 404.4 | -28.9 |
| fig12a | scaled | 0.125 | 8 | 188.7 | 233.1 | -19.0 |
| fig12a | scaled | 0.25 | 2 | 571.0 | 562.9 | 1.4 |
| fig12a | scaled | 0.25 | 4 | 291.1 | 384.0 | -24.2 |
| fig12a | scaled | 0.25 | 6 | 150.1 | 224.6 | -33.2 |
| fig12a | scaled | 0.25 | 8 | 78.6 | 154.8 | -49.2 |
| fig12b | scaled | -0.25 | 2 | 1223.7 | 906.0 | 35.1 |
| fig12b | scaled | -0.25 | 4 | 810.1 | 656.7 | 23.4 |
| fig12b | scaled | -0.25 | 6 | 543.0 | 308.3 | 76.1 |
| fig12b | scaled | -0.25 | 8 | 371.5 | 256.7 | 44.7 |
| fig12b | scaled | -0.125 | 2 | 1401.2 | 1301.4 | 7.7 |
| fig12b | scaled | -0.125 | 4 | 1085.1 | 852.1 | 27.3 |
| fig12b | scaled | -0.125 | 6 | 841.3 | 554.0 | 51.9 |
| fig12b | scaled | -0.125 | 8 | 661.9 | 503.7 | 31.4 |
| fig12b | scaled | 0.0 | 2 | 551.8 | 798.1 | -30.9 |
| fig12b | scaled | 0.0 | 4 | 474.8 | 579.6 | -18.1 |
| fig12b | scaled | 0.0 | 6 | 394.4 | 679.7 | -42.0 |
| fig12b | scaled | 0.0 | 8 | 333.0 | 626.0 | -46.8 |
| fig12b | scaled | 0.125 | 2 | 1154.9 | 1146.0 | 0.8 |
| fig12b | scaled | 0.125 | 4 | 856.9 | 993.9 | -13.8 |
| fig12b | scaled | 0.125 | 6 | 650.9 | 896.2 | -27.4 |
| fig12b | scaled | 0.125 | 8 | 504.1 | 647.3 | -22.1 |
| fig12b | scaled | 0.25 | 2 | 999.3 | 992.5 | 0.7 |
| fig12b | scaled | 0.25 | 4 | 629.9 | 791.8 | -20.4 |
| fig12b | scaled | 0.25 | 6 | 413.1 | 590.7 | -30.1 |
| fig12b | scaled | 0.25 | 8 | 278.4 | 390.3 | -28.7 |

## Fig. 7 p_c/C_P (β=15°, M_t=0.60, C_P legend=0.0424)

| polar | loads | x/D | p_c/C_P |
|---|---|---:|---:|
| primary | scaled | -0.5 | 0.0798 |
| primary | scaled | -0.25 | 0.214 |
| primary | scaled | -0.125 | 0.3104 |
| primary | scaled | 0.0 | 0.1249 |
| primary | scaled | 0.125 | 0.3004 |
| primary | scaled | 0.25 | 0.2039 |
| primary | scaled | 0.5 | 0.0712 |
| bracket | scaled | -0.5 | 0.0808 |
| bracket | scaled | -0.25 | 0.2164 |
| bracket | scaled | -0.125 | 0.3151 |
| bracket | scaled | 0.0 | 0.135 |
| bracket | scaled | 0.125 | 0.304 |
| bracket | scaled | 0.25 | 0.2051 |
| bracket | scaled | 0.5 | 0.0714 |

## Fig. 6 tip-clearance ratios (B=4, unscaled; ratio of max total-rms to d/D=0.083)

| d/D | p_rms max Pa | ratio to 0.083 |
|---:|---:|---:|
| 0.042 | 60.0 | 1.541 |
| 0.083 | 38.9 | 1.0 |
| 0.167 | 17.7 | 0.455 |
| 0.333 | 7.4 | 0.189 |

CSV: `data/report996/f1a_results.csv`.
