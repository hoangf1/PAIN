# Phase 69b N_crit fit to NACA TN 1546

Source: `data/polars/issue047_tn1546_ncrit.json` (ISSUE-047: the published 16-series sections, in `data/report996/xfoil_sections` since 2026-11-22) (2026-11-22). Rule fixed 2026-10-28 before the run.

| N_crit | fit points converged | RMS fit (16-506, 16-509) | mean dc_l fit | held-out 16-312 within 0.05 |
|---|---|---|---|---|
| 1 | 37/41 | 0.0600 | +0.0198 | 16/27 (25 converged) |
| 2 | 40/41 | 0.0603 | +0.0232 | 18/27 (27 converged) |
| 3 | 40/41 | 0.0584 | +0.0281 | 17/27 (25 converged) |
| 4 | 38/41 | 0.0575 | +0.0328 | 20/27 (26 converged) |
| 5 | 40/41 | 0.0565 | +0.0347 | 22/27 (27 converged) |
| 6 | 35/41 | 0.0576 | +0.0424 | 21/27 (27 converged) |
| 7 | 37/41 | 0.0561 | +0.0443 | 19/27 (26 converged) |
| 8 | 37/41 | 0.0551 | +0.0436 | 19/27 (26 converged) |
| 9 | 36/41 | 0.0560 | +0.0442 | 18/27 (27 converged) |
| 10 | 33/41 | 0.0561 | +0.0439 | 16/27 (26 converged) |
| 11 | 30/41 | 0.0595 | +0.0519 | 14/27 (25 converged) |
| 12 | 26/41 | 0.0589 | +0.0469 | 13/27 (24 converged) |

**Chosen N_crit = 8** (RMS 0.0551).

**Held-out 16-312:** 19/26 within |dc_l| <= 0.05 (73.1 %; criterion >= 75 %): **not met**. Matched points are those where XFOIL converged, as in POLAR_FIDELITY.

POLAR_FIDELITY on 16-506 and 16-509 is calibrated by this fit and carries no verdict.
