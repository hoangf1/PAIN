# Report 996 CCBlade loads (phase 26)

> **Re-run 2026-10-22 with regenerated polar entries (post-hoc).** `polars_forced_merged.json` gained 1,420 points in 109 entries that were empty or stopped below α = 8° (phase 11 XFOIL settings; only the sweep handling changed; existing points unchanged; 50 entries on the thinnest sections still stop short and are listed in the file header, not filled). The 23c criteria (frozen 2026-10-21) are unchanged. This result was produced after the first recorded result was known, so it is post-hoc; the first recorded report is kept below.


Generated 2026-10-22 by `scripts/run/run_report996_loads.jl`. Static V=0, `allow_static=true`.
Polars: `polars_forced_merged.json` primary + bracket. **Pass/fail waits on 23c [AUTHOR].**

| polar | β₇₅ | M_t | B | C_T ccb | C_P ccb | C_T meas | C_P meas | s_T | s_Q | source |
|---|---:|---:|--:|---:|---:|---:|---:|---:|---:|---|
| primary | 10.0 | 0.45 | 2 | 0.056 | 0.0258 | 0.0706 | 0.0221 | 1.262 | 0.856 | RM_L8H25a |
| bracket | 10.0 | 0.45 | 2 | 0.0515 | 0.0365 | 0.0706 | 0.0221 | 1.371 | 0.606 | RM_L8H25a |
| primary | 10.0 | 0.6 | 2 | 0.0573 | 0.0266 | 0.0718 | 0.023 | 1.254 | 0.863 | RM_L8H25a |
| bracket | 10.0 | 0.6 | 2 | 0.0527 | 0.0376 | 0.0718 | 0.023 | 1.362 | 0.612 | RM_L8H25a |
| primary | 15.0 | 0.45 | 2 | 0.0731 | 0.0425 | NaN | NaN | NaN | NaN | RM_L8H25a |
| bracket | 15.0 | 0.45 | 2 | 0.0668 | 0.0616 | NaN | NaN | NaN | NaN | RM_L8H25a |
| primary | 15.0 | 0.6 | 2 | 0.075 | 0.0438 | NaN | 0.0424 | NaN | 0.968 | Fig7_legend_CP |
| bracket | 15.0 | 0.6 | 2 | 0.0684 | 0.0634 | NaN | 0.0424 | NaN | 0.669 | Fig7_legend_CP |
| primary | 20.0 | 0.6 | 2 | 0.0833 | 0.0596 | 0.1048 | 0.0739 | 1.258 | 1.241 | RM_L8H25a |
| bracket | 20.0 | 0.6 | 2 | 0.0753 | 0.0883 | 0.1048 | 0.0739 | 1.391 | 0.837 | RM_L8H25a |
| primary | 8.0 | 0.6 | 2 | 0.0481 | 0.021 | NaN | 0.0195 | NaN | 0.927 | Fig7_legend_CP |
| bracket | 8.0 | 0.6 | 2 | 0.0443 | 0.0296 | NaN | 0.0195 | NaN | 0.659 | Fig7_legend_CP |
| primary | 10.0 | 0.45 | 2 | 0.056 | 0.0258 | 0.07 | 0.02324778563656447 | 1.251 | 0.901 | Fig14_table |
| bracket | 10.0 | 0.45 | 2 | 0.0515 | 0.0365 | 0.07 | 0.02324778563656447 | 1.359 | 0.637 | Fig14_table |
| primary | 10.0 | 0.6 | 2 | 0.0573 | 0.0266 | 0.072 | 0.02638937829015426 | 1.257 | 0.991 | Fig14_table |
| bracket | 10.0 | 0.6 | 2 | 0.0527 | 0.0376 | 0.072 | 0.02638937829015426 | 1.366 | 0.702 | Fig14_table |
| primary | 10.0 | 0.75 | 2 | 0.0588 | 0.0277 | 0.075 | 0.02764601535159018 | 1.275 | 0.999 | Fig14_table |
| bracket | 10.0 | 0.75 | 2 | 0.0542 | 0.0391 | 0.075 | 0.02764601535159018 | 1.385 | 0.708 | Fig14_table |
| primary | 10.0 | 0.9 | 2 | 0.0608 | 0.0281 | 0.08 | 0.03204424506661589 | 1.316 | 1.139 | Fig14_table |
| bracket | 10.0 | 0.9 | 2 | 0.056 | 0.0393 | 0.08 | 0.03204424506661589 | 1.428 | 0.814 | Fig14_table |

CSV: `data/report996/scale_factors.csv`.
Polar stats primary: clamped_Re=7388 clamped_M=312 viterna=2284.

---

## First recorded (2026-10-21), superseded by the re-run above

Generated 2026-10-21 by `scripts/run/run_report996_loads.jl`. Static V=0, `allow_static=true`.
Polars: `polars_forced_merged.json` primary + bracket. **Pass/fail waits on 23c [AUTHOR].**

| polar | β₇₅ | M_t | B | C_T ccb | C_P ccb | C_T meas | C_P meas | s_T | s_Q | source |
|---|---:|---:|--:|---:|---:|---:|---:|---:|---:|---|
| primary | 10.0 | 0.45 | 2 | 0.056 | 0.0258 | 0.0706 | 0.0221 | 1.262 | 0.856 | RM_L8H25a |
| bracket | 10.0 | 0.45 | 2 | 0.0515 | 0.0365 | 0.0706 | 0.0221 | 1.371 | 0.606 | RM_L8H25a |
| primary | 10.0 | 0.6 | 2 | 0.0573 | 0.0266 | 0.0718 | 0.023 | 1.254 | 0.863 | RM_L8H25a |
| bracket | 10.0 | 0.6 | 2 | 0.0527 | 0.0376 | 0.0718 | 0.023 | 1.362 | 0.612 | RM_L8H25a |
| primary | 15.0 | 0.45 | 2 | 0.0731 | 0.0425 | NaN | NaN | NaN | NaN | RM_L8H25a |
| bracket | 15.0 | 0.45 | 2 | 0.0668 | 0.0616 | NaN | NaN | NaN | NaN | RM_L8H25a |
| primary | 15.0 | 0.6 | 2 | 0.075 | 0.0438 | NaN | 0.0424 | NaN | 0.968 | Fig7_legend_CP |
| bracket | 15.0 | 0.6 | 2 | 0.0684 | 0.0634 | NaN | 0.0424 | NaN | 0.669 | Fig7_legend_CP |
| primary | 20.0 | 0.6 | 2 | 0.0833 | 0.0596 | 0.1048 | 0.0739 | 1.258 | 1.241 | RM_L8H25a |
| bracket | 20.0 | 0.6 | 2 | 0.0753 | 0.0883 | 0.1048 | 0.0739 | 1.391 | 0.837 | RM_L8H25a |
| primary | 8.0 | 0.6 | 2 | 0.0481 | 0.021 | NaN | 0.0195 | NaN | 0.927 | Fig7_legend_CP |
| bracket | 8.0 | 0.6 | 2 | 0.0443 | 0.0296 | NaN | 0.0195 | NaN | 0.659 | Fig7_legend_CP |
| primary | 10.0 | 0.45 | 2 | 0.056 | 0.0258 | 0.07 | 0.02324778563656447 | 1.251 | 0.901 | Fig14_table |
| bracket | 10.0 | 0.45 | 2 | 0.0515 | 0.0365 | 0.07 | 0.02324778563656447 | 1.359 | 0.637 | Fig14_table |
| primary | 10.0 | 0.6 | 2 | 0.0573 | 0.0266 | 0.072 | 0.02638937829015426 | 1.257 | 0.991 | Fig14_table |
| bracket | 10.0 | 0.6 | 2 | 0.0527 | 0.0376 | 0.072 | 0.02638937829015426 | 1.366 | 0.702 | Fig14_table |
| primary | 10.0 | 0.75 | 2 | 0.055 | 0.0256 | 0.075 | 0.02764601535159018 | 1.364 | 1.078 | Fig14_table |
| bracket | 10.0 | 0.75 | 2 | 0.0503 | 0.0361 | 0.075 | 0.02764601535159018 | 1.491 | 0.766 | Fig14_table |
| primary | 10.0 | 0.9 | 2 | 0.0526 | 0.0234 | 0.08 | 0.03204424506661589 | 1.521 | 1.372 | Fig14_table |
| bracket | 10.0 | 0.9 | 2 | 0.0484 | 0.0325 | 0.08 | 0.03204424506661589 | 1.653 | 0.985 | Fig14_table |

CSV: `data/report996/scale_factors.csv`.
Polar stats primary: clamped_Re=7405 clamped_M=312 viterna=2511.
