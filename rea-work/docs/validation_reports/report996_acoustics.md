# Report 996 Acoustics (phase 27)

Generated 2026-10-21 by `scripts/run_report996_acoustics.jl`.
**Pass/fail waits on 23c [AUTHOR].** x_sign=−1 (report behind → AA +X).

## x-sign / asymmetry (25k)

A(-0.125)=253935.2 vs A(+0.125)=51285.9 dyne/cm² (meas ~1328 vs ~1009); behind>ahead=true

## Page-12 phase (one measured value)

Δφ(|x/D|=0.125) F1A=177.5° vs report measured 155° / Eq.(2) 165° (candidates ±0.125; exact stations not stated)

## Fig. 14 (scaled to table C_T/C_Q) — residual % vs digitized

| polar | loads | case | mB | A F1A dyne/cm² | meas | residual % |
|---|---|---|--:|---:|---:|---:|
| primary | scaled | beta10_B2_Mt0.45 | 2 | 4765.8 | 200.9 | 2272.2 |
| primary | scaled | beta10_B2_Mt0.45 | 4 | 3847.6 | 100.0 | 3747.6 |
| primary | scaled | beta10_B2_Mt0.45 | 6 | 2629.2 | 50.1 | 5147.9 |
| bracket | scaled | beta10_B2_Mt0.45 | 2 | 4932.6 | 200.9 | 2355.3 |
| bracket | scaled | beta10_B2_Mt0.45 | 4 | 3980.1 | 100.0 | 3880.1 |
| bracket | scaled | beta10_B2_Mt0.45 | 6 | 2721.9 | 50.1 | 5332.9 |
| primary | scaled | beta10_B2_Mt0.6 | 2 | 24245.3 | 358.2 | 6668.7 |
| primary | scaled | beta10_B2_Mt0.6 | 4 | 17578.9 | 179.1 | 9715.1 |
| primary | scaled | beta10_B2_Mt0.6 | 6 | 12080.9 | 79.7 | 15058.0 |
| bracket | scaled | beta10_B2_Mt0.6 | 2 | 24726.2 | 358.2 | 6802.9 |
| bracket | scaled | beta10_B2_Mt0.6 | 4 | 17920.4 | 179.1 | 9905.8 |
| bracket | scaled | beta10_B2_Mt0.6 | 6 | 12317.7 | 79.7 | 15355.1 |
| primary | scaled | beta10_B2_Mt0.75 | 2 | 109929.6 | 661.0 | 16530.8 |
| primary | scaled | beta10_B2_Mt0.75 | 4 | 74539.6 | 399.6 | 18553.6 |
| primary | scaled | beta10_B2_Mt0.75 | 6 | 50589.1 | 229.0 | 21991.3 |
| bracket | scaled | beta10_B2_Mt0.75 | 2 | 111654.8 | 661.0 | 16791.8 |
| bracket | scaled | beta10_B2_Mt0.75 | 4 | 75743.8 | 399.6 | 18854.9 |
| bracket | scaled | beta10_B2_Mt0.75 | 6 | 51416.9 | 229.0 | 22352.8 |
| primary | scaled | beta10_B2_Mt0.9 | 2 | 334162.6 | 1297.9 | 25646.4 |
| primary | scaled | beta10_B2_Mt0.9 | 4 | 204690.3 | 840.7 | 24247.6 |
| primary | scaled | beta10_B2_Mt0.9 | 6 | 136338.6 | 547.2 | 24815.7 |
| bracket | scaled | beta10_B2_Mt0.9 | 2 | 353454.6 | 1297.9 | 27132.8 |
| bracket | scaled | beta10_B2_Mt0.9 | 4 | 216586.6 | 840.7 | 25662.6 |
| bracket | scaled | beta10_B2_Mt0.9 | 6 | 144300.1 | 547.2 | 26270.6 |

## Fig. 13(a) first harmonic vs x/D (M_t=0.75, β=15°)

| polar | loads | x/D | A F1A | meas | residual % |
|---|---|---:|---:|---:|---:|
| primary | scaled_fig14proxy | -0.5 | 370.2 | 501.2 | -26.1 |
| primary | scaled_fig14proxy | -0.25 | 6237.9 | 1001.8 | 522.7 |
| primary | scaled_fig14proxy | -0.125 | 253935.2 | 1327.9 | 19023.1 |
| primary | scaled_fig14proxy | 0.0 | 257501.0 | 762.9 | 33652.9 |
| primary | scaled_fig14proxy | 0.125 | 51285.9 | 1008.5 | 4985.4 |
| primary | scaled_fig14proxy | 0.25 | 7422.2 | 835.3 | 788.6 |
| primary | scaled_fig14proxy | 0.5 | 429.9 | 355.4 | 21.0 |
| bracket | scaled_fig14proxy | -0.5 | 364.9 | 501.2 | -27.2 |
| bracket | scaled_fig14proxy | -0.25 | 5998.5 | 1001.8 | 498.8 |
| bracket | scaled_fig14proxy | -0.125 | 248216.1 | 1327.9 | 18592.4 |
| bracket | scaled_fig14proxy | 0.0 | 243635.7 | 762.9 | 31835.5 |
| bracket | scaled_fig14proxy | 0.125 | 59127.1 | 1008.5 | 5762.9 |
| bracket | scaled_fig14proxy | 0.25 | 7453.5 | 835.3 | 792.3 |
| bracket | scaled_fig14proxy | 0.5 | 443.2 | 355.4 | 24.7 |

## Fig. 12(a)/(b) harmonics vs x/D (β=10°, primary/scaled)

| fig | loads | x/D | mB | A F1A | meas | residual % |
|---|---|---:|--:|---:|---:|---:|
| fig12a | scaled | -0.25 | 2 | 4155.9 | 600.4 | 592.2 |
| fig12a | scaled | -0.25 | 4 | 2259.4 | 251.1 | 799.8 |
| fig12a | scaled | -0.25 | 6 | 1961.8 | 101.9 | 1825.2 |
| fig12a | scaled | -0.25 | 8 | 1318.4 | 68.8 | 1816.2 |
| fig12a | scaled | -0.125 | 2 | 109929.6 | 621.8 | 17579.3 |
| fig12a | scaled | -0.125 | 4 | 74539.6 | 400.1 | 18530.3 |
| fig12a | scaled | -0.125 | 6 | 50589.1 | 234.0 | 21519.3 |
| fig12a | scaled | -0.125 | 8 | 38134.4 | 158.4 | 23974.8 |
| fig12a | scaled | 0.0 | 2 | 88598.7 | 400.0 | 22049.7 |
| fig12a | scaled | 0.0 | 4 | 57245.4 | 321.0 | 17733.5 |
| fig12a | scaled | 0.0 | 6 | 38036.8 | 213.5 | 17715.8 |
| fig12a | scaled | 0.0 | 8 | 28861.0 | 181.0 | 15845.3 |
| fig12a | scaled | 0.125 | 2 | 34890.4 | 661.1 | 5177.6 |
| fig12a | scaled | 0.125 | 4 | 23645.4 | 592.0 | 3894.2 |
| fig12a | scaled | 0.125 | 6 | 16620.1 | 404.4 | 4009.8 |
| fig12a | scaled | 0.125 | 8 | 12385.0 | 233.1 | 5213.2 |
| fig12a | scaled | 0.25 | 2 | 2640.1 | 562.9 | 369.0 |
| fig12a | scaled | 0.25 | 4 | 2661.2 | 384.0 | 593.0 |
| fig12a | scaled | 0.25 | 6 | 1374.6 | 224.6 | 512.0 |
| fig12a | scaled | 0.25 | 8 | 1149.8 | 154.8 | 642.8 |
| fig12b | scaled | -0.25 | 2 | 35456.2 | 906.0 | 3813.5 |
| fig12b | scaled | -0.25 | 4 | 23940.8 | 656.7 | 3545.6 |
| fig12b | scaled | -0.25 | 6 | 15716.4 | 308.3 | 4997.8 |
| fig12b | scaled | -0.25 | 8 | 11504.1 | 256.7 | 4381.5 |
| fig12b | scaled | -0.125 | 2 | 334162.6 | 1301.4 | 25577.2 |
| fig12b | scaled | -0.125 | 4 | 204690.3 | 852.1 | 23921.9 |
| fig12b | scaled | -0.125 | 6 | 136338.6 | 554.0 | 24509.8 |
| fig12b | scaled | -0.125 | 8 | 102414.7 | 503.7 | 20232.5 |
| fig12b | scaled | 0.0 | 2 | 1.0070091e6 | 798.1 | 126075.8 |
| fig12b | scaled | 0.0 | 4 | 605392.4 | 579.6 | 104350.0 |
| fig12b | scaled | 0.0 | 6 | 406662.8 | 679.7 | 59729.8 |
| fig12b | scaled | 0.0 | 8 | 306715.4 | 626.0 | 48896.1 |
| fig12b | scaled | 0.125 | 2 | 443561.7 | 1146.0 | 38605.2 |
| fig12b | scaled | 0.125 | 4 | 274218.7 | 993.9 | 27490.2 |
| fig12b | scaled | 0.125 | 6 | 183771.8 | 896.2 | 20405.7 |
| fig12b | scaled | 0.125 | 8 | 137905.5 | 647.3 | 21204.7 |
| fig12b | scaled | 0.25 | 2 | 50643.0 | 992.5 | 5002.6 |
| fig12b | scaled | 0.25 | 4 | 33580.1 | 791.8 | 4141.0 |
| fig12b | scaled | 0.25 | 6 | 22759.1 | 590.7 | 3752.9 |
| fig12b | scaled | 0.25 | 8 | 16565.4 | 390.3 | 4144.3 |

## Fig. 7 p_c/C_P (β=15°, M_t=0.60, C_P legend=0.0424)

| polar | loads | x/D | p_c/C_P |
|---|---|---:|---:|
| primary | scaled | -0.5 | 0.1915 |
| primary | scaled | -0.25 | 0.9131 |
| primary | scaled | -0.125 | 26.3229 |
| primary | scaled | 0.0 | 73.1838 |
| primary | scaled | 0.125 | 1.7462 |
| primary | scaled | 0.25 | 4.5557 |
| primary | scaled | 0.5 | 0.1317 |
| bracket | scaled | -0.5 | 0.1908 |
| bracket | scaled | -0.25 | 0.988 |
| bracket | scaled | -0.125 | 26.5966 |
| bracket | scaled | 0.0 | 69.8853 |
| bracket | scaled | 0.125 | 2.9595 |
| bracket | scaled | 0.25 | 4.629 |
| bracket | scaled | 0.5 | 0.1309 |

## Fig. 6 tip-clearance ratios (B=4, unscaled; ratio of max total-rms to d/D=0.083)

| d/D | p_rms max Pa | ratio to 0.083 |
|---:|---:|---:|
| 0.042 | 37430.0 | 32.113 |
| 0.083 | 1165.6 | 1.0 |
| 0.167 | 313.5 | 0.269 |
| 0.333 | 49.9 | 0.043 |

CSV: `data/report996/f1a_results.csv`.
