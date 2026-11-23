# Report 996 CCBlade loads (phase 26)

Generated 2026-11-22 by `scripts/run/run_report996_loads.jl`. Static V=0, `allow_static=true`.
Blade: `blade_form_r996_fig3c.csv`, β from Report 996 Fig. 3(c) (Phase 154, 2026-11-14; re-run post-hoc; the results on `blade_form.csv` are compared in `phase154_r996_blade_angle.md`).
Polars: `polars_phase69_ncrit8.json` (Phase 69: free transition, N_crit 8 fitted to TN 1546) primary + bracket, on the published NACA 16-series sections (ISSUE-047, re-run 2026-11-22, post-hoc; the results on the old section files are `scale_factors_pre047.csv`).

| polar | β₇₅ | M_t | B | C_T ccb | C_P ccb | C_T meas | C_P meas | s_T | s_Q | source |
|---|---:|---:|--:|---:|---:|---:|---:|---:|---:|---|
| primary | 10.0 | 0.45 | 2 | 0.0708 | 0.022 | 0.0706 | 0.0221 | 0.997 | 1.003 | RM_L8H25a |
| bracket | 10.0 | 0.45 | 2 | 0.0657 | 0.0248 | 0.0706 | 0.0221 | 1.075 | 0.893 | RM_L8H25a |
| primary | 10.0 | 0.6 | 2 | 0.0725 | 0.0226 | 0.0718 | 0.023 | 0.991 | 1.016 | RM_L8H25a |
| bracket | 10.0 | 0.6 | 2 | 0.0671 | 0.0254 | 0.0718 | 0.023 | 1.07 | 0.906 | RM_L8H25a |
| primary | 15.0 | 0.45 | 2 | 0.0819 | 0.034 | NaN | NaN | NaN | NaN | RM_L8H25a |
| bracket | 15.0 | 0.45 | 2 | 0.0745 | 0.0429 | NaN | NaN | NaN | NaN | RM_L8H25a |
| primary | 15.0 | 0.6 | 2 | 0.0831 | 0.0361 | NaN | 0.0424 | NaN | 1.173 | Fig7_legend_CP |
| bracket | 15.0 | 0.6 | 2 | 0.0759 | 0.0466 | NaN | 0.0424 | NaN | 0.909 | Fig7_legend_CP |
| primary | 20.0 | 0.6 | 2 | 0.0803 | 0.0512 | 0.1048 | 0.0739 | 1.305 | 1.444 | RM_L8H25a |
| bracket | 20.0 | 0.6 | 2 | 0.0721 | 0.0747 | 0.1048 | 0.0739 | 1.453 | 0.99 | RM_L8H25a |
| primary | 8.0 | 0.6 | 2 | 0.0641 | 0.0187 | NaN | 0.0195 | NaN | 1.045 | Fig7_legend_CP |
| bracket | 8.0 | 0.6 | 2 | 0.0594 | 0.0205 | NaN | 0.0195 | NaN | 0.951 | Fig7_legend_CP |
| primary | 10.0 | 0.45 | 2 | 0.0708 | 0.022 | 0.07 | 0.02324778563656447 | 0.988 | 1.055 | Fig14_table |
| bracket | 10.0 | 0.45 | 2 | 0.0657 | 0.0248 | 0.07 | 0.02324778563656447 | 1.066 | 0.939 | Fig14_table |
| primary | 10.0 | 0.6 | 2 | 0.0725 | 0.0226 | 0.072 | 0.02638937829015426 | 0.994 | 1.165 | Fig14_table |
| bracket | 10.0 | 0.6 | 2 | 0.0671 | 0.0254 | 0.072 | 0.02638937829015426 | 1.073 | 1.04 | Fig14_table |
| primary | 10.0 | 0.75 | 2 | 0.0728 | 0.0241 | 0.075 | 0.02764601535159018 | 1.03 | 1.147 | Fig14_table |
| bracket | 10.0 | 0.75 | 2 | 0.0673 | 0.0281 | 0.075 | 0.02764601535159018 | 1.114 | 0.982 | Fig14_table |
| primary | 10.0 | 0.9 | 2 | 0.0761 | 0.0372 | 0.08 | 0.03204424506661589 | 1.052 | 0.861 | Fig14_table |
| bracket | 10.0 | 0.9 | 2 | 0.0704 | 0.0509 | 0.08 | 0.03204424506661589 | 1.137 | 0.629 | Fig14_table |

CSV: `data/report996/scale_factors.csv`.
Polar stats primary: clamped_Re=0 clamped_M=0 viterna=20380.
