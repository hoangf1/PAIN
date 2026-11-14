# Report 996 CCBlade loads (phase 26)

Generated 2026-11-14 by `scripts/run/run_report996_loads.jl`. Static V=0, `allow_static=true`.
Blade: `blade_form_r996_fig3c.csv`, β from Report 996 Fig. 3(c) (Phase 154, 2026-11-14; re-run post-hoc; the results on `blade_form.csv` are compared in `phase154_r996_blade_angle.md`).
Polars: `polars_phase69_ncrit8.json` (Phase 69: free transition, N_crit 8 fitted to TN 1546) primary + bracket.

| polar | β₇₅ | M_t | B | C_T ccb | C_P ccb | C_T meas | C_P meas | s_T | s_Q | source |
|---|---:|---:|--:|---:|---:|---:|---:|---:|---:|---|
| primary | 10.0 | 0.45 | 2 | 0.0684 | 0.0212 | 0.0706 | 0.0221 | 1.032 | 1.043 | RM_L8H25a |
| bracket | 10.0 | 0.45 | 2 | 0.0632 | 0.024 | 0.0706 | 0.0221 | 1.117 | 0.922 | RM_L8H25a |
| primary | 10.0 | 0.6 | 2 | 0.0695 | 0.022 | 0.0718 | 0.023 | 1.033 | 1.045 | RM_L8H25a |
| bracket | 10.0 | 0.6 | 2 | 0.0643 | 0.0254 | 0.0718 | 0.023 | 1.117 | 0.907 | RM_L8H25a |
| primary | 15.0 | 0.45 | 2 | 0.0786 | 0.0321 | NaN | NaN | NaN | NaN | RM_L8H25a |
| bracket | 15.0 | 0.45 | 2 | 0.0717 | 0.0406 | NaN | NaN | NaN | NaN | RM_L8H25a |
| primary | 15.0 | 0.6 | 2 | 0.0783 | 0.0341 | NaN | 0.0424 | NaN | 1.245 | Fig7_legend_CP |
| bracket | 15.0 | 0.6 | 2 | 0.0715 | 0.0441 | NaN | 0.0424 | NaN | 0.961 | Fig7_legend_CP |
| primary | 20.0 | 0.6 | 2 | 0.073 | 0.045 | 0.1048 | 0.0739 | 1.435 | 1.641 | RM_L8H25a |
| bracket | 20.0 | 0.6 | 2 | 0.0656 | 0.066 | 0.1048 | 0.0739 | 1.599 | 1.12 | RM_L8H25a |
| primary | 8.0 | 0.6 | 2 | 0.0616 | 0.0178 | NaN | 0.0195 | NaN | 1.094 | Fig7_legend_CP |
| bracket | 8.0 | 0.6 | 2 | 0.0571 | 0.0199 | NaN | 0.0195 | NaN | 0.981 | Fig7_legend_CP |
| primary | 10.0 | 0.45 | 2 | 0.0684 | 0.0212 | 0.07 | 0.02324778563656447 | 1.023 | 1.097 | Fig14_table |
| bracket | 10.0 | 0.45 | 2 | 0.0632 | 0.024 | 0.07 | 0.02324778563656447 | 1.108 | 0.97 | Fig14_table |
| primary | 10.0 | 0.6 | 2 | 0.0695 | 0.022 | 0.072 | 0.02638937829015426 | 1.036 | 1.199 | Fig14_table |
| bracket | 10.0 | 0.6 | 2 | 0.0643 | 0.0254 | 0.072 | 0.02638937829015426 | 1.121 | 1.041 | Fig14_table |
| primary | 10.0 | 0.75 | 2 | 0.0701 | 0.0231 | 0.075 | 0.02764601535159018 | 1.07 | 1.198 | Fig14_table |
| bracket | 10.0 | 0.75 | 2 | 0.0649 | 0.0272 | 0.075 | 0.02764601535159018 | 1.157 | 1.018 | Fig14_table |
| primary | 10.0 | 0.9 | 2 | 0.0721 | 0.0248 | 0.08 | 0.03204424506661589 | 1.11 | 1.294 | Fig14_table |
| bracket | 10.0 | 0.9 | 2 | 0.0668 | 0.0295 | 0.08 | 0.03204424506661589 | 1.197 | 1.086 | Fig14_table |

CSV: `data/report996/scale_factors.csv`.
Polar stats primary: clamped_Re=0 clamped_M=0 viterna=20967.
