# Phase 90 — Eq. (43) blocking against NACA Report 996 Fig. 10 (2026-10-29)

Criteria fixed 2026-10-29 before Fig. 10 was digitized (`IMPLEMENTATION_PLAN.md` §8ag, committed 4778383).

**90a digitization.** `data/digitizers/dig_r996_fig10.py` (400 dpi; 17 vertical and 10 horizontal gridlines found from the
pixel darkness; x fit residual 0.0014 x/D, y fit 2.0 dynes/cm²; each marker centre = midpoint of the rows where its ink
extent is at least half its widest, read with 14 and 18 px half-windows). QA: two reads within 10 dynes/cm² at every
marker (worst 10.0). A first pass with a dark-pixel centroid failed (the square markers are drawn lighter than the
threshold), and a 16/22 px pair failed the QA at the flat-wall peak (17.4); the 14/18 pair passed. Output:
`data/report996/tr996_fig10_reflecting_walls.csv`.

| x/D | free space | flat wall | circular wall | flat − free (dB) | circular − free (dB) | γ (°) | R1 (dB) | R2 (dB) |
|---|---|---|---|---|---|---|---|---|
| −0.25 | 740.3 | 1251.5 | 800.0 | 4.56 | 0.67 | 23.2 | 5.97 | 4.03 |
| −0.125 | 829.9 | 1669.4 | 1154.5 | 6.07 | 2.87 | 12.1 | 5.99 | 4.05 |
| 0 | 773.9 | 1545.0 | 1258.3 | 6.00 | 4.22 | 0 | 6.00 | 4.06 |
| 0.125 | 650.7 | 1339.8 | 1081.1 | 6.27 | 4.41 | 12.1 | 5.99 | 4.05 |
| 0.25 | 430.6 | 997.8 | 759.0 | 7.30 | 4.92 | 23.2 | 5.97 | 4.03 |

**90b** R996_FIG10_FLAT: criterion ±1.5 dB at ≥ 4 of 5 → **met**, 5/5 (largest |Δ| 1.41 dB at x/D = −0.25).
**90c** R996_FIG10_CIRC: information (radius not stated).

**Limits.** γ ≤ 23°, so only the near-normal end of Eq. (43) is tested; total pressure, not per harmonic; Eq. (43) is
Magliozzi's fit (J. Aircraft 1980), whose data are not in hand.
