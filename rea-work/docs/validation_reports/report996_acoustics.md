# Report 996 Acoustics (phase 27)

Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.
Generated 2026-10-28 by `scripts/run/run_report996_acoustics.jl`.
**Re-run after plan I-01/I-02/I-08 (2026-10-28).** Criterion: VALIDATION_GUIDELINE §2.12 / 23c frozen 2026-10-21.
x_sign=−1 (report behind → AA +X). Thickness off. Harmonic A vs measured: A_rms = A_Pa/√2 (Report 996 p.10 rms).

## I-08 Fig. 13(a) load scale

RM L51C27 Table I (47-in., β₇₅=15°, M_t=0.75): T=225.0 lb, Q=114.0 lb·ft → C_T=0.0869, C_Q=0.01124; applied to 4-ft model: T_tgt=1043.9 N, Q_tgt=164.6 N·m. Tag `scaled_RM_L51C27` (replaces void fig14proxy).

## x-sign / asymmetry (25k)

A_rms(-0.125)=1031.7 vs A_rms(+0.125)=1193.4 dyne/cm² (meas ~1328 vs ~1009); behind>ahead=false

## Page-12 phase (one measured value)

Δφ(|x/D|=0.125) F1A=113.6° vs report measured 155° / Eq.(2) 165° (candidates ±0.125; exact stations not stated)

23c page-12 phase: |Δφ − 155°| = 41.4° → FAIL (±15°).

## Fig. 14 (scaled to table C_T/C_Q) — residual % vs digitized

| polar | loads | case | mB | A F1A dyne/cm² | meas | residual % | residual dB |
|---|---|---|--:|---:|---:|---:|---:|
| primary | scaled | beta10_B2_Mt0.45 | 2 | 196.8 | 200.9 | -2.0 | -0.18 |
| primary | scaled | beta10_B2_Mt0.45 | 4 | 104.7 | 100.0 | 4.7 | 0.4 |
| primary | scaled | beta10_B2_Mt0.45 | 6 | 55.8 | 50.1 | 11.5 | 0.94 |
| bracket | scaled | beta10_B2_Mt0.45 | 2 | 199.4 | 200.9 | -0.8 | -0.07 |
| bracket | scaled | beta10_B2_Mt0.45 | 4 | 106.3 | 100.0 | 6.3 | 0.53 |
| bracket | scaled | beta10_B2_Mt0.45 | 6 | 56.8 | 50.1 | 13.5 | 1.1 |
| primary | scaled | beta10_B2_Mt0.6 | 2 | 388.7 | 358.2 | 8.5 | 0.71 |
| primary | scaled | beta10_B2_Mt0.6 | 4 | 224.8 | 179.1 | 25.5 | 1.97 |
| primary | scaled | beta10_B2_Mt0.6 | 6 | 129.7 | 79.7 | 62.8 | 4.23 |
| bracket | scaled | beta10_B2_Mt0.6 | 2 | 394.1 | 358.2 | 10.0 | 0.83 |
| bracket | scaled | beta10_B2_Mt0.6 | 4 | 228.2 | 179.1 | 27.4 | 2.1 |
| bracket | scaled | beta10_B2_Mt0.6 | 6 | 132.0 | 79.7 | 65.6 | 4.38 |
| primary | scaled | beta10_B2_Mt0.75 | 2 | 683.9 | 661.0 | 3.5 | 0.3 |
| primary | scaled | beta10_B2_Mt0.75 | 4 | 442.8 | 399.6 | 10.8 | 0.89 |
| primary | scaled | beta10_B2_Mt0.75 | 6 | 287.6 | 229.0 | 25.6 | 1.98 |
| bracket | scaled | beta10_B2_Mt0.75 | 2 | 693.3 | 661.0 | 4.9 | 0.42 |
| bracket | scaled | beta10_B2_Mt0.75 | 4 | 449.5 | 399.6 | 12.5 | 1.02 |
| bracket | scaled | beta10_B2_Mt0.75 | 6 | 292.6 | 229.0 | 27.8 | 2.13 |
| primary | scaled | beta10_B2_Mt0.9 | 2 | 1154.9 | 1297.9 | -11.0 | -1.01 |
| primary | scaled | beta10_B2_Mt0.9 | 4 | 856.9 | 840.7 | 1.9 | 0.17 |
| primary | scaled | beta10_B2_Mt0.9 | 6 | 650.9 | 547.2 | 19.0 | 1.51 |
| bracket | scaled | beta10_B2_Mt0.9 | 2 | 1171.9 | 1297.9 | -9.7 | -0.89 |
| bracket | scaled | beta10_B2_Mt0.9 | 4 | 872.4 | 840.7 | 3.8 | 0.32 |
| bracket | scaled | beta10_B2_Mt0.9 | 6 | 665.7 | 547.2 | 21.7 | 1.7 |

23c scaled pressure (Fig.14 sample): 20/24 within ±2 dB (83.0%; need ≥75%).

## Fig. 13(a) first harmonic vs x/D (M_t=0.75, β=15°)

| polar | loads | x/D | A F1A | meas | residual % | residual dB |
|---|---|---:|---:|---:|---:|---:|
| primary | scaled_RM_L51C27 | -0.5 | 316.4 | 501.2 | -36.9 | -3.99 |
| primary | scaled_RM_L51C27 | -0.25 | 784.0 | 1001.8 | -21.7 | -2.13 |
| primary | scaled_RM_L51C27 | -0.125 | 1031.7 | 1327.9 | -22.3 | -2.19 |
| primary | scaled_RM_L51C27 | 0.0 | 729.3 | 762.9 | -4.4 | -0.39 |
| primary | scaled_RM_L51C27 | 0.125 | 1193.4 | 1008.5 | 18.3 | 1.46 |
| primary | scaled_RM_L51C27 | 0.25 | 939.1 | 835.3 | 12.4 | 1.02 |
| primary | scaled_RM_L51C27 | 0.5 | 436.1 | 355.4 | 22.7 | 1.78 |
| bracket | scaled_RM_L51C27 | -0.5 | 319.4 | 501.2 | -36.3 | -3.91 |
| bracket | scaled_RM_L51C27 | -0.25 | 791.5 | 1001.8 | -21.0 | -2.05 |
| bracket | scaled_RM_L51C27 | -0.125 | 1042.4 | 1327.9 | -21.5 | -2.1 |
| bracket | scaled_RM_L51C27 | 0.0 | 725.2 | 762.9 | -4.9 | -0.44 |
| bracket | scaled_RM_L51C27 | 0.125 | 1205.5 | 1008.5 | 19.5 | 1.55 |
| bracket | scaled_RM_L51C27 | 0.25 | 947.3 | 835.3 | 13.4 | 1.09 |
| bracket | scaled_RM_L51C27 | 0.5 | 439.3 | 355.4 | 23.6 | 1.84 |

23c scaled pressure (Fig.13a sample): 8/14 within ±2 dB.

## Fig. 12(a)/(b) harmonics vs x/D (β=10°, primary/scaled)

| fig | loads | x/D | mB | A F1A | meas | residual % |
|---|---|---:|--:|---:|---:|---:|
| fig12a | scaled | -0.25 | 2 | 571.0 | 600.4 | -4.9 |
| fig12a | scaled | -0.25 | 4 | 291.1 | 251.1 | 15.9 |
| fig12a | scaled | -0.25 | 6 | 150.1 | 101.9 | 47.3 |
| fig12a | scaled | -0.25 | 8 | 78.6 | 68.8 | 14.2 |
| fig12a | scaled | -0.125 | 2 | 683.9 | 621.8 | 10.0 |
| fig12a | scaled | -0.125 | 4 | 442.8 | 400.1 | 10.7 |
| fig12a | scaled | -0.125 | 6 | 287.6 | 234.0 | 22.9 |
| fig12a | scaled | -0.125 | 8 | 188.7 | 158.4 | 19.1 |
| fig12a | scaled | 0.0 | 2 | 281.3 | 400.0 | -29.7 |
| fig12a | scaled | 0.0 | 4 | 196.6 | 321.0 | -38.8 |
| fig12a | scaled | 0.0 | 6 | 134.5 | 213.5 | -37.0 |
| fig12a | scaled | 0.0 | 8 | 94.6 | 181.0 | -47.7 |
| fig12a | scaled | 0.125 | 2 | 755.6 | 661.1 | 14.3 |
| fig12a | scaled | 0.125 | 4 | 484.7 | 592.0 | -18.1 |
| fig12a | scaled | 0.125 | 6 | 310.8 | 404.4 | -23.2 |
| fig12a | scaled | 0.125 | 8 | 201.8 | 233.1 | -13.4 |
| fig12a | scaled | 0.25 | 2 | 638.5 | 562.9 | 13.4 |
| fig12a | scaled | 0.25 | 4 | 326.7 | 384.0 | -14.9 |
| fig12a | scaled | 0.25 | 6 | 167.8 | 224.6 | -25.3 |
| fig12a | scaled | 0.25 | 8 | 87.6 | 154.8 | -43.4 |
| fig12b | scaled | -0.25 | 2 | 999.3 | 906.0 | 10.3 |
| fig12b | scaled | -0.25 | 4 | 629.9 | 656.7 | -4.1 |
| fig12b | scaled | -0.25 | 6 | 413.1 | 308.3 | 34.0 |
| fig12b | scaled | -0.25 | 8 | 278.4 | 256.7 | 8.4 |
| fig12b | scaled | -0.125 | 2 | 1154.9 | 1301.4 | -11.3 |
| fig12b | scaled | -0.125 | 4 | 856.9 | 852.1 | 0.6 |
| fig12b | scaled | -0.125 | 6 | 650.9 | 554.0 | 17.5 |
| fig12b | scaled | -0.125 | 8 | 504.1 | 503.7 | 0.1 |
| fig12b | scaled | 0.0 | 2 | 551.8 | 798.1 | -30.9 |
| fig12b | scaled | 0.0 | 4 | 474.8 | 579.6 | -18.1 |
| fig12b | scaled | 0.0 | 6 | 394.4 | 679.7 | -42.0 |
| fig12b | scaled | 0.0 | 8 | 333.0 | 626.0 | -46.8 |
| fig12b | scaled | 0.125 | 2 | 1401.2 | 1146.0 | 22.3 |
| fig12b | scaled | 0.125 | 4 | 1085.1 | 993.9 | 9.2 |
| fig12b | scaled | 0.125 | 6 | 841.3 | 896.2 | -6.1 |
| fig12b | scaled | 0.125 | 8 | 661.9 | 647.3 | 2.3 |
| fig12b | scaled | 0.25 | 2 | 1223.7 | 992.5 | 23.3 |
| fig12b | scaled | 0.25 | 4 | 810.1 | 791.8 | 2.3 |
| fig12b | scaled | 0.25 | 6 | 543.0 | 590.7 | -8.1 |
| fig12b | scaled | 0.25 | 8 | 371.5 | 390.3 | -4.8 |

## Fig. 7 p_c/C_P (β=15°, M_t=0.60, C_P legend=0.0424)

| polar | loads | x/D | p_c/C_P |
|---|---|---:|---:|
| primary | scaled | -0.5 | 0.0712 |
| primary | scaled | -0.25 | 0.2039 |
| primary | scaled | -0.125 | 0.3004 |
| primary | scaled | 0.0 | 0.1249 |
| primary | scaled | 0.125 | 0.3104 |
| primary | scaled | 0.25 | 0.214 |
| primary | scaled | 0.5 | 0.0798 |
| bracket | scaled | -0.5 | 0.0714 |
| bracket | scaled | -0.25 | 0.2051 |
| bracket | scaled | -0.125 | 0.304 |
| bracket | scaled | 0.0 | 0.135 |
| bracket | scaled | 0.125 | 0.3151 |
| bracket | scaled | 0.25 | 0.2164 |
| bracket | scaled | 0.5 | 0.0808 |

## Fig. 6 tip-clearance ratios (B=4, unscaled; ratio of max total-rms to d/D=0.083)

| d/D | p_rms max Pa | ratio to 0.083 |
|---:|---:|---:|
| 0.042 | 60.0 | 1.541 |
| 0.083 | 38.9 | 1.0 |
| 0.167 | 17.7 | 0.455 |
| 0.333 | 7.4 | 0.189 |

CSV: `data/report996/f1a_results.csv`.
