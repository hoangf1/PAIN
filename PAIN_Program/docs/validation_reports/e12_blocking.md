# Fig. E-12 on-line blocking check (plan phase 14a)

Class: **V-CODE** for Eq. (43) against NASA's predicted curve (same equation, same free-field input); **V-EXP** for the measured curve (recorded, no pass mark). Tests Eq. (43) and the incidence angle only, not GEXT.

Criterion fixed 2026-10-20 (plan 14a, before comparison): Eq. (43) applied to the l = 1 free field reproduces the digitized predicted E-12 curve within δ_dig + 0.5 dB at every point.

Geometry: test cylinder a = 0.508 m, hub r_p = 0.965 m, z_p = 0.662 m, φ_p = 90°, D = 0.762 m, variant R1 (full Eq. 43, as in NASA's PAIN). Free-field input: ANOPP Table 8 (l = 1), the predicted free field NASA fed to Eq. (43). Digitized curves are the mean of two passes; pass A used pixel calibration, pass B a grid overlay, both by eye by the same reader.

## δ_dig (max |A − B| on the E-12 curves)

| Curve | H1 | H2 | H3 |
|---|---|---|---|
| predicted | 1.22 | 2.91 | 1.49 |
| measured | 0.71 | 0.90 | 1.37 |

δ_dig (all) = 2.91 dB; δ_dig (predicted) = 2.91 dB; tolerance for the predicted comparison = δ_dig(predicted) + 0.5 = 3.41 dB.
The E-11 digitization gate (≤ 1.0 dB) is NOT met; the criterion is kept as written (δ_dig + 0.5) and the larger δ_dig is reported.

## Eq. (43) on Table 8 against predicted E-12

| k | X3/D | γ [deg] | ΔL [dB] | H | Table 8 + ΔL | E-12 predicted | diff | within tol |
|---|---|---|---|---|---|---|---|---|
| 2 | 0.698 | 49.3 | 5.77 | 1 | 108.3 | 108.2 | +0.1 | yes |
| 3 | 0.582 | 44.1 | 5.85 | 1 | 113.0 | 113.3 | -0.3 | yes |
| 4 | 0.465 | 37.8 | 5.91 | 1 | 118.5 | 118.5 | +0.0 | yes |
| 4 | 0.465 | 37.8 | 5.91 | 2 | 99.1 | 99.6 | -0.5 | yes |
| 4 | 0.465 | 37.8 | 5.91 | 3 | 79.6 | 82.5 | -2.9 | yes |
| 5 | 0.349 | 30.2 | 5.95 | 1 | 124.0 | 123.6 | +0.5 | yes |
| 5 | 0.349 | 30.2 | 5.95 | 2 | 108.7 | 109.2 | -0.5 | yes |
| 5 | 0.349 | 30.2 | 5.95 | 3 | 93.3 | 94.8 | -1.5 | yes |
| 6 | 0.233 | 21.2 | 5.98 | 1 | 129.1 | 128.7 | +0.4 | yes |
| 6 | 0.233 | 21.2 | 5.98 | 2 | 118.0 | 117.9 | +0.1 | yes |
| 6 | 0.233 | 21.2 | 5.98 | 3 | 106.9 | 106.7 | +0.1 | yes |
| 7 | 0.116 | 11.0 | 5.99 | 1 | 131.7 | 130.2 | +1.5 | yes |
| 7 | 0.116 | 11.0 | 5.99 | 2 | 124.6 | 123.2 | +1.4 | yes |
| 7 | 0.116 | 11.0 | 5.99 | 3 | 117.3 | 116.1 | +1.2 | yes |
| 8 | 0.000 | 0.0 | 6.00 | 1 | 126.6 | 126.4 | +0.2 | yes |
| 8 | 0.000 | 0.0 | 6.00 | 2 | 120.4 | 120.2 | +0.2 | yes |
| 8 | 0.000 | 0.0 | 6.00 | 3 | 114.4 | 114.1 | +0.3 | yes |
| 9 | -0.116 | 11.0 | 5.99 | 1 | 130.9 | 129.9 | +1.0 | yes |
| 9 | -0.116 | 11.0 | 5.99 | 2 | 122.5 | 120.4 | +2.1 | yes |
| 9 | -0.116 | 11.0 | 5.99 | 3 | 114.1 | 110.8 | +3.3 | yes |
| 10 | -0.233 | 21.2 | 5.98 | 1 | 127.8 | 126.7 | +1.1 | yes |
| 10 | -0.233 | 21.2 | 5.98 | 2 | 115.5 | 113.4 | +2.0 | yes |
| 10 | -0.233 | 21.2 | 5.98 | 3 | 103.1 | 98.8 | +4.3 | NO |
| 11 | -0.349 | 30.2 | 5.95 | 1 | 122.7 | 121.5 | +1.3 | yes |
| 11 | -0.349 | 30.2 | 5.95 | 2 | 106.1 | 104.1 | +2.0 | yes |
| 11 | -0.349 | 30.2 | 5.95 | 3 | 89.4 | 85.7 | +3.8 | NO |
| 12 | -0.465 | 37.8 | 5.91 | 1 | 117.4 | 116.4 | +1.0 | yes |
| 12 | -0.465 | 37.8 | 5.91 | 2 | 96.6 | 94.8 | +1.8 | yes |
| 13 | -0.582 | 44.1 | 5.85 | 1 | 112.2 | 111.2 | +1.0 | yes |
| 14 | -0.698 | 49.3 | 5.77 | 1 | 107.9 | 106.5 | +1.3 | yes |
| 15 | -0.814 | 53.6 | 5.67 | 1 | 103.5 | 102.4 | +1.1 | yes |

**Result: 29 of 31 points within 3.41 dB; largest |difference| 4.3 dB.** FAIL (recorded, not tuned)

## Eq. (43) on the digitized E-11 measured line against measured E-12 (V-EXP, no pass mark)

| k | X3/D | H | E-11 measured + ΔL | E-12 measured | diff |
|---|---|---|---|---|---|
| 3 | 0.582 | 1 | 112.6 | 106.2 | +6.4 |
| 4 | 0.465 | 1 | 118.7 | 111.6 | +7.1 |
| 5 | 0.349 | 1 | 123.7 | 117.0 | +6.7 |
| 6 | 0.233 | 1 | 128.7 | 122.3 | +6.4 |
| 7 | 0.116 | 1 | 131.7 | 125.6 | +6.1 |
| 7 | 0.116 | 2 | 123.7 | 118.5 | +5.3 |
| 7 | 0.116 | 3 | 116.7 | 111.9 | +4.9 |
| 8 | 0.000 | 1 | 126.7 | 124.6 | +2.1 |
| 8 | 0.000 | 2 | 120.7 | 118.0 | +2.8 |
| 8 | 0.000 | 3 | 114.7 | 113.4 | +1.3 |
| 9 | -0.116 | 1 | 130.7 | 125.4 | +5.3 |
| 9 | -0.116 | 2 | 121.7 | 115.2 | +6.6 |
| 9 | -0.116 | 3 | 113.7 | 107.1 | +6.7 |
| 10 | -0.233 | 1 | 127.7 | 120.9 | +6.8 |
| 11 | -0.349 | 1 | 122.7 | 116.5 | +6.2 |
| 12 | -0.465 | 1 | 117.7 | 112.0 | +5.7 |
| 13 | -0.582 | 1 | 112.6 | 107.5 | +5.1 |

Measured E-12 values are linear interpolations between the circles (the dashed curve), inside the range of the circles only. NASA reports predicted minus measured of 0–5 dB near the plane of rotation (CR-3813 App. E).

## Digitization notes

- The H2 measured marker at X3/D = 0.69 was read in pass A only; pass B did not cover it (outside the grid crops), so it is not in δ_dig.
- Dashed measured segments without a circle (point_type = end) are used for δ_dig but are not measurements.
- The predicted H2 curve starts where it merges with the dashed curve (X3/D ≈ 0.57–0.60); its start is the least certain point.
