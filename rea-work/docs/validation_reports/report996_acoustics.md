# Report 996 Acoustics (phase 27)

> **Re-run 2026-10-22 with regenerated polar entries (post-hoc).** `polars_forced_merged.json` gained 1,420 points in 109 entries that were empty or stopped below α = 8° (phase 11 XFOIL settings; only the sweep handling changed; existing points unchanged; 50 entries on the thinnest sections still stop short and are listed in the file header, not filled). The 23c criteria (frozen 2026-10-21) are unchanged. This result was produced after the first recorded result was known, so it is post-hoc; the first recorded report is kept below.


Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.
Generated 2026-10-22 by `scripts/run/run_report996_acoustics.jl`.
**Re-run after plan I-01/I-02/I-08 (2026-10-22).** Criterion: VALIDATION_GUIDELINE §2.12 / 23c frozen 2026-10-21.
x_sign=−1 (report behind → AA +X). Thickness off. Harmonic A vs measured: A_rms = A_Pa/√2 (Report 996 p.10 rms).

## I-08 Fig. 13(a) load scale

RM L51C27 Table I (47-in., β₇₅=15°, M_t=0.75): T=225.0 lb, Q=114.0 lb·ft → C_T=0.0869, C_Q=0.01124; applied to 4-ft model: T_tgt=1043.9 N, Q_tgt=164.6 N·m. Tag `scaled_RM_L51C27` (replaces void fig14proxy).

## x-sign / asymmetry (25k)

A_rms(-0.125)=971.6 vs A_rms(+0.125)=1128.9 dyne/cm² (meas ~1328 vs ~1009); behind>ahead=false

## Page-12 phase (one measured value)

Δφ(|x/D|=0.125) F1A=109.0° vs report measured 155° / Eq.(2) 165° (candidates ±0.125; exact stations not stated)

23c page-12 phase: |Δφ − 155°| = 46.0° → FAIL (±15°).

## Fig. 14 (scaled to table C_T/C_Q) — residual % vs digitized

| polar | loads | case | mB | A F1A dyne/cm² | meas | residual % | residual dB |
|---|---|---|--:|---:|---:|---:|---:|
| primary | scaled | beta10_B2_Mt0.45 | 2 | 180.6 | 200.9 | -10.1 | -0.93 |
| primary | scaled | beta10_B2_Mt0.45 | 4 | 93.1 | 100.0 | -6.9 | -0.62 |
| primary | scaled | beta10_B2_Mt0.45 | 6 | 48.7 | 50.1 | -2.8 | -0.25 |
| bracket | scaled | beta10_B2_Mt0.45 | 2 | 183.3 | 200.9 | -8.7 | -0.79 |
| bracket | scaled | beta10_B2_Mt0.45 | 4 | 95.0 | 100.0 | -5.0 | -0.44 |
| bracket | scaled | beta10_B2_Mt0.45 | 6 | 49.9 | 50.1 | -0.4 | -0.04 |
| primary | scaled | beta10_B2_Mt0.6 | 2 | 351.8 | 358.2 | -1.8 | -0.16 |
| primary | scaled | beta10_B2_Mt0.6 | 4 | 196.3 | 179.1 | 9.6 | 0.8 |
| primary | scaled | beta10_B2_Mt0.6 | 6 | 110.6 | 79.7 | 38.7 | 2.84 |
| bracket | scaled | beta10_B2_Mt0.6 | 2 | 357.4 | 358.2 | -0.2 | -0.02 |
| bracket | scaled | beta10_B2_Mt0.6 | 4 | 200.4 | 179.1 | 11.9 | 0.98 |
| bracket | scaled | beta10_B2_Mt0.6 | 6 | 113.3 | 79.7 | 42.2 | 3.06 |
| primary | scaled | beta10_B2_Mt0.75 | 2 | 611.7 | 661.0 | -7.5 | -0.67 |
| primary | scaled | beta10_B2_Mt0.75 | 4 | 382.1 | 399.6 | -4.4 | -0.39 |
| primary | scaled | beta10_B2_Mt0.75 | 6 | 242.1 | 229.0 | 5.7 | 0.48 |
| bracket | scaled | beta10_B2_Mt0.75 | 2 | 621.5 | 661.0 | -6.0 | -0.54 |
| bracket | scaled | beta10_B2_Mt0.75 | 4 | 390.1 | 399.6 | -2.4 | -0.21 |
| bracket | scaled | beta10_B2_Mt0.75 | 6 | 248.0 | 229.0 | 8.3 | 0.69 |
| primary | scaled | beta10_B2_Mt0.9 | 2 | 1007.1 | 1297.9 | -22.4 | -2.2 |
| primary | scaled | beta10_B2_Mt0.9 | 4 | 713.6 | 840.7 | -15.1 | -1.42 |
| primary | scaled | beta10_B2_Mt0.9 | 6 | 523.8 | 547.2 | -4.3 | -0.38 |
| bracket | scaled | beta10_B2_Mt0.9 | 2 | 1022.8 | 1297.9 | -21.2 | -2.07 |
| bracket | scaled | beta10_B2_Mt0.9 | 4 | 728.1 | 840.7 | -13.4 | -1.25 |
| bracket | scaled | beta10_B2_Mt0.9 | 6 | 536.6 | 547.2 | -1.9 | -0.17 |

23c scaled pressure (Fig.14 sample): 20/24 within ±2 dB (83.0%; need ≥75%).

## Fig. 13(a) first harmonic vs x/D (M_t=0.75, β=15°)

| polar | loads | x/D | A F1A | meas | residual % | residual dB |
|---|---|---:|---:|---:|---:|---:|
| primary | scaled_RM_L51C27 | -0.5 | 303.3 | 501.2 | -39.5 | -4.36 |
| primary | scaled_RM_L51C27 | -0.25 | 745.0 | 1001.8 | -25.6 | -2.57 |
| primary | scaled_RM_L51C27 | -0.125 | 971.6 | 1327.9 | -26.8 | -2.71 |
| primary | scaled_RM_L51C27 | 0.0 | 727.3 | 762.9 | -4.7 | -0.42 |
| primary | scaled_RM_L51C27 | 0.125 | 1128.9 | 1008.5 | 11.9 | 0.98 |
| primary | scaled_RM_L51C27 | 0.25 | 897.5 | 835.3 | 7.4 | 0.62 |
| primary | scaled_RM_L51C27 | 0.5 | 421.6 | 355.4 | 18.6 | 1.48 |
| bracket | scaled_RM_L51C27 | -0.5 | 305.3 | 501.2 | -39.1 | -4.31 |
| bracket | scaled_RM_L51C27 | -0.25 | 750.8 | 1001.8 | -25.1 | -2.5 |
| bracket | scaled_RM_L51C27 | -0.125 | 980.7 | 1327.9 | -26.1 | -2.63 |
| bracket | scaled_RM_L51C27 | 0.0 | 726.5 | 762.9 | -4.8 | -0.42 |
| bracket | scaled_RM_L51C27 | 0.125 | 1138.7 | 1008.5 | 12.9 | 1.06 |
| bracket | scaled_RM_L51C27 | 0.25 | 903.6 | 835.3 | 8.2 | 0.68 |
| bracket | scaled_RM_L51C27 | 0.5 | 423.8 | 355.4 | 19.2 | 1.53 |

23c scaled pressure (Fig.13a sample): 8/14 within ±2 dB.

## Fig. 12(a)/(b) harmonics vs x/D (β=10°, primary/scaled)

| fig | loads | x/D | mB | A F1A | meas | residual % |
|---|---|---:|--:|---:|---:|---:|
| fig12a | scaled | -0.25 | 2 | 522.1 | 600.4 | -13.0 |
| fig12a | scaled | -0.25 | 4 | 255.4 | 251.1 | 1.7 |
| fig12a | scaled | -0.25 | 6 | 128.0 | 101.9 | 25.6 |
| fig12a | scaled | -0.25 | 8 | 65.8 | 68.8 | -4.4 |
| fig12a | scaled | -0.125 | 2 | 611.7 | 621.8 | -1.6 |
| fig12a | scaled | -0.125 | 4 | 382.1 | 400.1 | -4.5 |
| fig12a | scaled | -0.125 | 6 | 242.1 | 234.0 | 3.4 |
| fig12a | scaled | -0.125 | 8 | 156.1 | 158.4 | -1.5 |
| fig12a | scaled | 0.0 | 2 | 279.3 | 400.0 | -30.2 |
| fig12a | scaled | 0.0 | 4 | 184.0 | 321.0 | -42.7 |
| fig12a | scaled | 0.0 | 6 | 118.7 | 213.5 | -44.4 |
| fig12a | scaled | 0.0 | 8 | 79.4 | 181.0 | -56.1 |
| fig12a | scaled | 0.125 | 2 | 682.5 | 661.1 | 3.2 |
| fig12a | scaled | 0.125 | 4 | 421.4 | 592.0 | -28.8 |
| fig12a | scaled | 0.125 | 6 | 262.6 | 404.4 | -35.1 |
| fig12a | scaled | 0.125 | 8 | 167.2 | 233.1 | -28.3 |
| fig12a | scaled | 0.25 | 2 | 589.2 | 562.9 | 4.7 |
| fig12a | scaled | 0.25 | 4 | 288.9 | 384.0 | -24.8 |
| fig12a | scaled | 0.25 | 6 | 143.8 | 224.6 | -36.0 |
| fig12a | scaled | 0.25 | 8 | 73.4 | 154.8 | -52.6 |
| fig12b | scaled | -0.25 | 2 | 897.5 | 906.0 | -0.9 |
| fig12b | scaled | -0.25 | 4 | 537.4 | 656.7 | -18.2 |
| fig12b | scaled | -0.25 | 6 | 340.2 | 308.3 | 10.3 |
| fig12b | scaled | -0.25 | 8 | 223.7 | 256.7 | -12.9 |
| fig12b | scaled | -0.125 | 2 | 1007.1 | 1301.4 | -22.6 |
| fig12b | scaled | -0.125 | 4 | 713.6 | 852.1 | -16.3 |
| fig12b | scaled | -0.125 | 6 | 523.8 | 554.0 | -5.5 |
| fig12b | scaled | -0.125 | 8 | 395.6 | 503.7 | -21.5 |
| fig12b | scaled | 0.0 | 2 | 548.2 | 798.1 | -31.3 |
| fig12b | scaled | 0.0 | 4 | 430.5 | 579.6 | -25.7 |
| fig12b | scaled | 0.0 | 6 | 327.2 | 679.7 | -51.9 |
| fig12b | scaled | 0.0 | 8 | 255.1 | 626.0 | -59.2 |
| fig12b | scaled | 0.125 | 2 | 1249.3 | 1146.0 | 9.0 |
| fig12b | scaled | 0.125 | 4 | 920.3 | 993.9 | -7.4 |
| fig12b | scaled | 0.125 | 6 | 683.0 | 896.2 | -23.8 |
| fig12b | scaled | 0.125 | 8 | 518.2 | 647.3 | -19.9 |
| fig12b | scaled | 0.25 | 2 | 1120.9 | 992.5 | 12.9 |
| fig12b | scaled | 0.25 | 4 | 701.9 | 791.8 | -11.4 |
| fig12b | scaled | 0.25 | 6 | 448.9 | 590.7 | -24.0 |
| fig12b | scaled | 0.25 | 8 | 295.5 | 390.3 | -24.3 |

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

---

## First recorded (2026-10-21), superseded by the re-run above

Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.
Generated 2026-10-21 by `scripts/run/run_report996_acoustics.jl`.
**Re-run after plan I-01/I-02/I-08 (2026-10-21).** Criterion: VALIDATION_GUIDELINE §2.12 / 23c frozen 2026-10-21.
x_sign=−1 (report behind → AA +X). Thickness off. Harmonic A vs measured: A_rms = A_Pa/√2 (Report 996 p.10 rms).

### I-08 Fig. 13(a) load scale

RM L51C27 Table I (47-in., β₇₅=15°, M_t=0.75): T=225.0 lb, Q=114.0 lb·ft → C_T=0.0869, C_Q=0.01124; applied to 4-ft model: T_tgt=1043.9 N, Q_tgt=164.6 N·m. Tag `scaled_RM_L51C27` (replaces void fig14proxy).

### x-sign / asymmetry (25k)

A_rms(-0.125)=913.5 vs A_rms(+0.125)=1066.6 dyne/cm² (meas ~1328 vs ~1009); behind>ahead=false

### Page-12 phase (one measured value)

Δφ(|x/D|=0.125) F1A=103.8° vs report measured 155° / Eq.(2) 165° (candidates ±0.125; exact stations not stated)

23c page-12 phase: |Δφ − 155°| = 51.2° → FAIL (±15°).

### Fig. 14 (scaled to table C_T/C_Q) — residual % vs digitized

| polar | loads | case | mB | A F1A dyne/cm² | meas | residual % | residual dB |
|---|---|---|--:|---:|---:|---:|---:|
| primary | scaled | beta10_B2_Mt0.45 | 2 | 180.6 | 200.9 | -10.1 | -0.93 |
| primary | scaled | beta10_B2_Mt0.45 | 4 | 93.1 | 100.0 | -6.9 | -0.62 |
| primary | scaled | beta10_B2_Mt0.45 | 6 | 48.7 | 50.1 | -2.8 | -0.25 |
| bracket | scaled | beta10_B2_Mt0.45 | 2 | 183.3 | 200.9 | -8.7 | -0.79 |
| bracket | scaled | beta10_B2_Mt0.45 | 4 | 95.0 | 100.0 | -5.0 | -0.44 |
| bracket | scaled | beta10_B2_Mt0.45 | 6 | 49.9 | 50.1 | -0.4 | -0.04 |
| primary | scaled | beta10_B2_Mt0.6 | 2 | 351.8 | 358.2 | -1.8 | -0.16 |
| primary | scaled | beta10_B2_Mt0.6 | 4 | 196.3 | 179.1 | 9.6 | 0.8 |
| primary | scaled | beta10_B2_Mt0.6 | 6 | 110.6 | 79.7 | 38.7 | 2.84 |
| bracket | scaled | beta10_B2_Mt0.6 | 2 | 357.4 | 358.2 | -0.2 | -0.02 |
| bracket | scaled | beta10_B2_Mt0.6 | 4 | 200.4 | 179.1 | 11.9 | 0.98 |
| bracket | scaled | beta10_B2_Mt0.6 | 6 | 113.3 | 79.7 | 42.2 | 3.06 |
| primary | scaled | beta10_B2_Mt0.75 | 2 | 583.1 | 661.0 | -11.8 | -1.09 |
| primary | scaled | beta10_B2_Mt0.75 | 4 | 357.1 | 399.6 | -10.6 | -0.98 |
| primary | scaled | beta10_B2_Mt0.75 | 6 | 223.5 | 229.0 | -2.4 | -0.21 |
| bracket | scaled | beta10_B2_Mt0.75 | 2 | 590.8 | 661.0 | -10.6 | -0.97 |
| bracket | scaled | beta10_B2_Mt0.75 | 4 | 363.3 | 399.6 | -9.1 | -0.83 |
| bracket | scaled | beta10_B2_Mt0.75 | 6 | 228.1 | 229.0 | -0.4 | -0.03 |
| primary | scaled | beta10_B2_Mt0.9 | 2 | 1006.0 | 1297.9 | -22.5 | -2.21 |
| primary | scaled | beta10_B2_Mt0.9 | 4 | 718.1 | 840.7 | -14.6 | -1.37 |
| primary | scaled | beta10_B2_Mt0.9 | 6 | 537.0 | 547.2 | -1.9 | -0.16 |
| bracket | scaled | beta10_B2_Mt0.9 | 2 | 1023.9 | 1297.9 | -21.1 | -2.06 |
| bracket | scaled | beta10_B2_Mt0.9 | 4 | 734.9 | 840.7 | -12.6 | -1.17 |
| bracket | scaled | beta10_B2_Mt0.9 | 6 | 552.2 | 547.2 | 0.9 | 0.08 |

23c scaled pressure (Fig.14 sample): 20/24 within ±2 dB (83.0%; need ≥75%).

### Fig. 13(a) first harmonic vs x/D (M_t=0.75, β=15°)

| polar | loads | x/D | A F1A | meas | residual % | residual dB |
|---|---|---:|---:|---:|---:|---:|
| primary | scaled_RM_L51C27 | -0.5 | 291.2 | 501.2 | -41.9 | -4.72 |
| primary | scaled_RM_L51C27 | -0.25 | 706.2 | 1001.8 | -29.5 | -3.04 |
| primary | scaled_RM_L51C27 | -0.125 | 913.5 | 1327.9 | -31.2 | -3.25 |
| primary | scaled_RM_L51C27 | 0.0 | 720.8 | 762.9 | -5.5 | -0.49 |
| primary | scaled_RM_L51C27 | 0.125 | 1066.6 | 1008.5 | 5.8 | 0.49 |
| primary | scaled_RM_L51C27 | 0.25 | 855.6 | 835.3 | 2.4 | 0.21 |
| primary | scaled_RM_L51C27 | 0.5 | 407.6 | 355.4 | 14.7 | 1.19 |
| bracket | scaled_RM_L51C27 | -0.5 | 293.3 | 501.2 | -41.5 | -4.66 |
| bracket | scaled_RM_L51C27 | -0.25 | 712.1 | 1001.8 | -28.9 | -2.96 |
| bracket | scaled_RM_L51C27 | -0.125 | 922.6 | 1327.9 | -30.5 | -3.16 |
| bracket | scaled_RM_L51C27 | 0.0 | 719.8 | 762.9 | -5.7 | -0.51 |
| bracket | scaled_RM_L51C27 | 0.125 | 1076.7 | 1008.5 | 6.8 | 0.57 |
| bracket | scaled_RM_L51C27 | 0.25 | 862.0 | 835.3 | 3.2 | 0.27 |
| bracket | scaled_RM_L51C27 | 0.5 | 409.9 | 355.4 | 15.3 | 1.24 |

23c scaled pressure (Fig.13a sample): 8/14 within ±2 dB.

### Fig. 12(a)/(b) harmonics vs x/D (β=10°, primary/scaled)

| fig | loads | x/D | mB | A F1A | meas | residual % |
|---|---|---:|--:|---:|---:|---:|
| fig12a | scaled | -0.25 | 2 | 502.2 | 600.4 | -16.4 |
| fig12a | scaled | -0.25 | 4 | 240.2 | 251.1 | -4.4 |
| fig12a | scaled | -0.25 | 6 | 118.6 | 101.9 | 16.4 |
| fig12a | scaled | -0.25 | 8 | 60.4 | 68.8 | -12.2 |
| fig12a | scaled | -0.125 | 2 | 583.1 | 621.8 | -6.2 |
| fig12a | scaled | -0.125 | 4 | 357.1 | 400.1 | -10.7 |
| fig12a | scaled | -0.125 | 6 | 223.5 | 234.0 | -4.5 |
| fig12a | scaled | -0.125 | 8 | 143.4 | 158.4 | -9.5 |
| fig12a | scaled | 0.0 | 2 | 278.1 | 400.0 | -30.5 |
| fig12a | scaled | 0.0 | 4 | 174.3 | 321.0 | -45.7 |
| fig12a | scaled | 0.0 | 6 | 107.7 | 213.5 | -49.6 |
| fig12a | scaled | 0.0 | 8 | 69.7 | 181.0 | -61.5 |
| fig12a | scaled | 0.125 | 2 | 653.6 | 661.1 | -1.1 |
| fig12a | scaled | 0.125 | 4 | 394.5 | 592.0 | -33.4 |
| fig12a | scaled | 0.125 | 6 | 242.3 | 404.4 | -40.1 |
| fig12a | scaled | 0.125 | 8 | 153.2 | 233.1 | -34.3 |
| fig12a | scaled | 0.25 | 2 | 569.2 | 562.9 | 1.1 |
| fig12a | scaled | 0.25 | 4 | 272.1 | 384.0 | -29.1 |
| fig12a | scaled | 0.25 | 6 | 132.9 | 224.6 | -40.8 |
| fig12a | scaled | 0.25 | 8 | 67.1 | 154.8 | -56.6 |
| fig12b | scaled | -0.25 | 2 | 882.7 | 906.0 | -2.6 |
| fig12b | scaled | -0.25 | 4 | 532.3 | 656.7 | -18.9 |
| fig12b | scaled | -0.25 | 6 | 343.8 | 308.3 | 11.5 |
| fig12b | scaled | -0.25 | 8 | 231.3 | 256.7 | -9.9 |
| fig12b | scaled | -0.125 | 2 | 1006.0 | 1301.4 | -22.7 |
| fig12b | scaled | -0.125 | 4 | 718.1 | 852.1 | -15.7 |
| fig12b | scaled | -0.125 | 6 | 537.0 | 554.0 | -3.1 |
| fig12b | scaled | -0.125 | 8 | 414.4 | 503.7 | -17.7 |
| fig12b | scaled | 0.0 | 2 | 548.4 | 798.1 | -31.3 |
| fig12b | scaled | 0.0 | 4 | 412.3 | 579.6 | -28.9 |
| fig12b | scaled | 0.0 | 6 | 310.6 | 679.7 | -54.3 |
| fig12b | scaled | 0.0 | 8 | 246.3 | 626.0 | -60.6 |
| fig12b | scaled | 0.125 | 2 | 1249.8 | 1146.0 | 9.1 |
| fig12b | scaled | 0.125 | 4 | 918.3 | 993.9 | -7.6 |
| fig12b | scaled | 0.125 | 6 | 689.7 | 896.2 | -23.0 |
| fig12b | scaled | 0.125 | 8 | 533.6 | 647.3 | -17.6 |
| fig12b | scaled | 0.25 | 2 | 1106.4 | 992.5 | 11.5 |
| fig12b | scaled | 0.25 | 4 | 690.1 | 791.8 | -12.8 |
| fig12b | scaled | 0.25 | 6 | 446.9 | 590.7 | -24.3 |
| fig12b | scaled | 0.25 | 8 | 300.5 | 390.3 | -23.0 |

### Fig. 7 p_c/C_P (β=15°, M_t=0.60, C_P legend=0.0424)

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

### Fig. 6 tip-clearance ratios (B=4, unscaled; ratio of max total-rms to d/D=0.083)

| d/D | p_rms max Pa | ratio to 0.083 |
|---:|---:|---:|
| 0.042 | 42.7 | 1.517 |
| 0.083 | 28.2 | 1.0 |
| 0.167 | 13.5 | 0.479 |
| 0.333 | 5.8 | 0.207 |

CSV: `data/report996/f1a_results.csv`.
