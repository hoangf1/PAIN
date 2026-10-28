# Phase 69b N_crit fit to NACA TN 1546

Source: `data/polars/phase69_tn1546_ncrit.json` (2026-10-28). Rule fixed 2026-10-28 before the run.

| N_crit | fit points converged | RMS fit (16-506, 16-509) | mean dc_l fit | held-out 16-312 within 0.05 |
|---|---|---|---|---|
| 1 | 39/41 | 0.0900 | -0.0633 | 11/27 (26 converged) |
| 2 | 40/41 | 0.0870 | -0.0561 | 13/27 (25 converged) |
| 3 | 41/41 | 0.0810 | -0.0450 | 10/27 (23 converged) |
| 4 | 38/41 | 0.0650 | -0.0389 | 12/27 (25 converged) |
| 5 | 39/41 | 0.0538 | -0.0345 | 13/27 (27 converged) |
| 6 | 40/41 | 0.0539 | -0.0327 | 12/27 (26 converged) |
| 7 | 39/41 | 0.0504 | -0.0295 | 11/27 (26 converged) |
| 8 | 34/41 | 0.0390 | -0.0207 | 13/27 (26 converged) |
| 9 | 35/41 | 0.0458 | -0.0217 | 12/27 (26 converged) |
| 10 | 35/41 | 0.0454 | -0.0196 | 12/27 (26 converged) |
| 11 | 28/41 | 0.0499 | -0.0200 | 16/27 (25 converged) |
| 12 | 32/41 | 0.0543 | -0.0200 | 15/27 (25 converged) |

**Chosen N_crit = 8** (RMS 0.0390).

**Held-out 16-312:** 13/26 within |dc_l| <= 0.05 (50.0 %; criterion >= 75 %): **not met**. Matched points are those where XFOIL converged, as in POLAR_FIDELITY.

POLAR_FIDELITY on 16-506 and 16-509 is calibrated by this fit and carries no verdict.
