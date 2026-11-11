# Phase 143: E12_BLOCK, one implementation, and the two third-harmonic aft points read from pixels (2026-11-11)

Done by Claude under the author's authority of 2026-11-10 and 2026-11-11. E12_BLOCK carries no verdict since Phase 135f: it runs the R1 blocking, not the shipped R2. Its tolerance (3.41 dB), its 31 points and its reference files are unchanged.

## 143a, 143b One implementation, one set of numbers

The report script (`scripts/run/e12_blocking.jl`) and the case runner (`_run_e12_block`) now use one function for the reference curve, the mean of digitization passes A and B, which is what the criterion of 2026-10-20 says. Before, the runner read pass A alone.

| | Reference curve | Within 3.41 dB | Largest difference | Median |
|---|---|---|---|---|
| runner before (summary file of 2026-11-02) | pass A | 29 of 31 | 4.0 dB | 0.99 dB |
| report script (`e12_blocking.md`) | mean of A and B | 29 of 31 | 4.3 dB | — |
| **runner now (re-run 2026-11-11)** | **mean of A and B** | **29 of 31** | **4.3 dB** | **1.1 dB** |

The re-run is dated as a re-run. The count did not move. The record now holds one largest difference, 4.3 dB.

## 143c The two failing points, read from pixels

Both failing points are on the third harmonic, aft of the propeller plane. NASA's predicted line of Fig. E-12 was fitted to its pixels (300 dpi, the method and calibration of `data/digitizers/e11_e12_linefit.py`, Phase A3b), once seeded from pass A's vertices and once from pass B's. The fit follows the drawn line between the vertices; the by-eye value is a straight chord between two vertices.

| Station | X3/D | Table 8 + ΔL of Eq. (43) | NASA's line, by eye (mean of A and B) | NASA's line, pixels (seeds A / B) | Difference, by eye | Difference, pixels |
|---|---|---|---|---|---|---|
| k = 9 | −0.116 | 114.09 dB | 110.84 dB | 112.42 / 111.33 dB | +3.25 dB | +1.7 / +2.8 dB |
| k = 10 | −0.233 | 103.08 dB | 98.78 dB | 98.19 / 98.14 dB | **+4.29 dB** | **+4.9 / +4.9 dB** |
| k = 11 | −0.349 | 89.45 dB | 85.69 dB | 88.24 / 88.38 dB | **+3.76 dB** | +1.2 / +1.1 dB |

- **k = 11 is a reading error.** The line falls about 20 dB between k = 10 and the end of the curve. The by-eye passes joined two vertices with a straight chord; the pixels lie 2.6 dB above that chord at k = 11. Read from pixels, the point is within the tolerance.
- **k = 10 is not.** Both seedings give 98.2 dB, 0.6 dB below the by-eye value, so the difference grows to 4.9 dB. The two seedings agree within 0.05 dB, so this is not reading scatter.

## 143d What k = 10 means

At k = 10 NASA's own drawn step from the free field (Fig. E-11) to the blocked field (Fig. E-12) is 2.3 dB (Phase A3b), where Eq. (43) gives 5.98 dB. At the first and second harmonics the drawn step matches Eq. (43) within about 1.5 dB at every station. So one point of NASA's drawn third-harmonic line differs from NASA's own equation, and the documents do not say why. It is recorded as that: NASA's printed curve, not explained by the documents. No term is added to the code and the tolerance is not changed.

With the pixel values as the reference the count would be 30 of 31. This is stated for information: the case's reference files are the two by-eye passes, they are not replaced, and the case has no verdict.

The pixel reading was a one-off script, run once and not kept (rule of 2026-11-10); it only calls the functions of `e11_e12_linefit.py`.
