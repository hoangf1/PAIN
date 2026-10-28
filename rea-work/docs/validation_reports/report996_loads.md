# Report 996 CCBlade loads (phase 26)

Generated 2026-10-28 by `scripts/run/run_report996_loads.jl`. Static V=0, `allow_static=true`.
Polars: `polars_phase69_ncrit8.json` (Phase 69: free transition, N_crit 8 fitted to TN 1546) primary + bracket.

| polar | β₇₅ | M_t | B | C_T ccb | C_P ccb | C_T meas | C_P meas | s_T | s_Q | source |
|---|---:|---:|--:|---:|---:|---:|---:|---:|---:|---|
| primary | 10.0 | 0.45 | 2 | 0.0689 | 0.0214 | 0.0706 | 0.0221 | 1.025 | 1.031 | RM_L8H25a |
| bracket | 10.0 | 0.45 | 2 | 0.0637 | 0.0243 | 0.0706 | 0.0221 | 1.108 | 0.91 | RM_L8H25a |
| primary | 10.0 | 0.6 | 2 | 0.0699 | 0.0223 | 0.0718 | 0.023 | 1.027 | 1.03 | RM_L8H25a |
| bracket | 10.0 | 0.6 | 2 | 0.0646 | 0.0258 | 0.0718 | 0.023 | 1.111 | 0.892 | RM_L8H25a |
| primary | 15.0 | 0.45 | 2 | 0.0788 | 0.0323 | NaN | NaN | NaN | NaN | RM_L8H25a |
| bracket | 15.0 | 0.45 | 2 | 0.0718 | 0.041 | NaN | NaN | NaN | NaN | RM_L8H25a |
| primary | 15.0 | 0.6 | 2 | 0.0786 | 0.0343 | NaN | 0.0424 | NaN | 1.235 | Fig7_legend_CP |
| bracket | 15.0 | 0.6 | 2 | 0.0718 | 0.0445 | NaN | 0.0424 | NaN | 0.952 | Fig7_legend_CP |
| primary | 20.0 | 0.6 | 2 | 0.0729 | 0.0453 | 0.1048 | 0.0739 | 1.437 | 1.631 | RM_L8H25a |
| bracket | 20.0 | 0.6 | 2 | 0.0654 | 0.0665 | 0.1048 | 0.0739 | 1.601 | 1.111 | RM_L8H25a |
| primary | 8.0 | 0.6 | 2 | 0.062 | 0.018 | NaN | 0.0195 | NaN | 1.081 | Fig7_legend_CP |
| bracket | 8.0 | 0.6 | 2 | 0.0576 | 0.0201 | NaN | 0.0195 | NaN | 0.968 | Fig7_legend_CP |
| primary | 10.0 | 0.45 | 2 | 0.0689 | 0.0214 | 0.07 | 0.02324778563656447 | 1.016 | 1.085 | Fig14_table |
| bracket | 10.0 | 0.45 | 2 | 0.0637 | 0.0243 | 0.07 | 0.02324778563656447 | 1.098 | 0.957 | Fig14_table |
| primary | 10.0 | 0.6 | 2 | 0.0699 | 0.0223 | 0.072 | 0.02638937829015426 | 1.029 | 1.182 | Fig14_table |
| bracket | 10.0 | 0.6 | 2 | 0.0646 | 0.0258 | 0.072 | 0.02638937829015426 | 1.114 | 1.023 | Fig14_table |
| primary | 10.0 | 0.75 | 2 | 0.0705 | 0.0234 | 0.075 | 0.02764601535159018 | 1.064 | 1.183 | Fig14_table |
| bracket | 10.0 | 0.75 | 2 | 0.0652 | 0.0276 | 0.075 | 0.02764601535159018 | 1.15 | 1.002 | Fig14_table |
| primary | 10.0 | 0.9 | 2 | 0.0725 | 0.0251 | 0.08 | 0.03204424506661589 | 1.103 | 1.277 | Fig14_table |
| bracket | 10.0 | 0.9 | 2 | 0.0672 | 0.03 | 0.08 | 0.03204424506661589 | 1.19 | 1.068 | Fig14_table |

CSV: `data/report996/scale_factors.csv`.
Polar stats primary: clamped_Re=0 clamped_M=0 viterna=21114.
