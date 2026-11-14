# Forward-flight thrust and power of the NACA 4-(5)(08)-03 two-blade propeller (NACA Report 1012)

| File | Source | Content | Method | Uncertainty |
|---|---|---|---|---|
| `naca_report1012_fig5_ct_cp.csv` | NACA Report 1012 Fig. 5 (a)–(h), PDF pp. 8–15 (printed pp. 4–11) | C_T and C_P at 38 points: tunnel Mach 0.165–0.675, blade angle 30°–60°, on the labelled advance-ratio gridlines | `data/digitizers/r1012_fig5/run.py`, 300 dpi; pass A follows each curve from its foot on the J axis; pass B reads again with local grid lines and a line fit on the raw ink | passes differ 0.06 % at the median, 0.80 % at most; J·C_T/C_P agrees with the report's own efficiency curve within 0.015 at every point |

`qa/` holds one overlay per panel (red: C_T, blue: C_P, labelled with the blade angle), the pixel sidecar and a 600 dpi spot check of three points (panel a 60° J 4.0 C_P; panel d 50° J 2.6 C_T; panel g 55° J 3.4 C_P: each mark lies on its curve at the gridline).

**Not read.** Of the 72 gridline points inside the point rule on the curves the script could follow at all, 38 were kept. Left out, by readability alone and before any load was computed: blade angles 20° and 25° (every reading lies among crossing curves); the shallow part of every curve at low advance ratio (there the script cannot tell the crossing curves apart with certainty; one such reading was found on the tip-Mach curve by eye); panels (i) and (j) (no point inside the rule). So the kept points lie on the falling part of each curve, at and above the advance ratio of best efficiency.
