# Phase 156b: two 3.40 m four-blade propellers in flight against NACA Report 1377 (2026-11-22)

Done by Claude under the author's authority of 2026-11-15 and the go-ahead of 2026-11-22 ("Yes, continue 156b"). The runner (`PAIN.jl/src/cases_r1377_flight.jl`) was run once; it is in commit RUNNER_COMMIT and removed in the next commit (rule of 2026-11-10: a comparison that cannot carry a verdict is not a case). Kept: Tables I and II and the Fig. 2 blade form (`data/report1377/`), their digitizers (`data/digitizers/`), the section generator and XFOIL runner (`data/polars/xfoil_r1377.py`), the sections and the five polar sets, and this report.

## What was fixed before the run

All of it is in ISSUE-046, committed before any polar, load or sound level was computed: rows, tolerance and pass rule on 2026-11-15 (commit 1fd5eda); inputs, root, tip, sections, polar grid, air and observer on 2026-11-22 (commit dbe77df).

- **Compared:** the level of blade-passage harmonics 1–5 at the boom microphone (dB re 20 μPa), 39 flight rows (28 tapered, 11 rectangular), 179 levels.
- **Criterion:** ±3 dB per level; met if at least 75 % of the levels are within it, both propellers together.
- **Input rule:** three inputs the report does not print are checked: the airfoil family (four-digit sections instead of NACA 16-series), the power (±5 %) and the rectangular blade's design lift inboard of r/R 0.60 (the printed slope carried inboard). *If any check moves any compared level by more than 1 dB, the comparison carries no verdict.*
- **Blade angle:** set per row so that the computed shaft power equals the printed power.

One change was made after the inputs were fixed and before any level was seen. On the first attempt the blade-angle solver stopped with an error on rectangular row 3 (520 ft/s): it needs an offset of about +25.3° from Fig. 2's drawn angles, outside the solver's first range of ±25°. The range became −25° to +45°, and the root is taken on the branch where torque rises with blade angle: below about −20° the torque rises again on the braking branch, which is not a propeller state. This is a solver range, not an input of the comparison; no level had been printed or saved.

## Result (one run, 2026-11-22)

| Check of an unprinted input | Largest move of a compared level | Median move |
|---|---|---|
| Four-digit sections instead of NACA 16-series | **11.47 dB** | 0.53 dB |
| Power +5 % | **4.77 dB** | 0.28 dB |
| Power −5 % | **3.07 dB** | 0.28 dB |
| Rectangular blade: design lift inboard on the printed slope | 0.12 dB | 0.03 dB |

**No verdict.** Two checks move a compared level by more than 1 dB (limit fixed beforehand), so the inputs the report does not print weigh on the comparison, and by the rule it carries no verdict whatever its count. It is therefore not registered as a validation case. The count, for the record only: **43 of 179 levels within ±3 dB** (tapered 22/132, rectangular 21/47); not a pass or a fail.

| | Levels | Within ±3 dB | Median code − measured | Smallest | Largest | Median by harmonic H1 … H5 |
|---|---|---|---|---|---|---|
| Tapered | 132 | 22 | +7.0 dB | −6.9 dB | +17.7 dB | +8.6, +7.7, +6.6, +6.2, +5.2 |
| Rectangular | 47 | 21 | +3.0 dB | −4.3 dB | +12.8 dB | +3.8, +2.1, +1.9, +2.6, +6.6 |
| Both | 179 | 43 | +6.2 dB | −6.9 dB | +17.7 dB | +7.0, +6.5, +5.7, +5.3, +5.4 |

## What the numbers show

- **The checks move most where the loads are least certain.** The large moves come from a few rows, tapered rows at part power or the highest propeller speed (rows 9, 11, 28: computed thrust 27–52 % of the printed thrust). There a small change of section or power changes the blade's loading a lot. On 26 of the 39 rows no check moves a level by more than 1 dB.
- **The code is high, also where its thrust is right.** On the 117 levels of rows whose computed thrust is within 10 % of the printed thrust (Tables I and II print it), the code is a median 6.3 dB above the measured level, and 24 of the 117 are within ±3 dB. So the difference is not only the blade-angle setting.
- **Thrust at the printed power.** Code / printed: median 1.04, from 0.26 to 1.28. It is low (0.86–0.90) at the lowest speed (M∞ 0.21–0.22), high (1.04–1.10) at about 1,000 hp and M∞ 0.5, and lowest (0.26–0.52) on four tapered rows at part power (550–600 hp) or the highest propeller speed (row 9).
- **Cause not established.** Candidates, none tested (testing them now would be choosing after the result): the near field at 0.53 m from the blade tip (0.655 D from the axis), where the level falls fast with distance and the chordwise distribution of the load matters; the microphone boom and the airplane, which the report treats as free space; XFOIL's polars at section Mach numbers up to 0.89; the airfoil family. Ticket: ISSUE-048. Nothing was changed after the run.

## Polars

XFOIL 6.99, Phase 69 settings unchanged. 82 polars per tapered set and 87 per rectangular set, each on the (Re, M) points that bracket what its section meets. Timeouts (an angle XFOIL does not converge within 60 s) were refilled by the restart rule. The thinnest polars are the tip sections at M 0.8–0.9 (15 to 49 of 53 angles), outside of which the loader holds or extends the curve as in every other case.

## Not covered

Static rows; rows with printed helical tip Mach above 0.90 (the polar grid ends at M 0.9); the airplane, exhaust and blade deflection (stated limits of ISSUE-046).

## Every row

Levels in dB re 20 μPa; "–" where the report prints none. The blade-angle offset is from Fig. 2's drawn angles. The last column is the largest move of a compared level of that row under any of the checks.

| Propeller | Row | x/D | M∞ | Power (hp) | Blade-angle offset (deg) | Thrust, code / printed (lb) | Measured H1–H5 (dB) | Code H1–H5 (dB) | Largest check move (dB) |
|---|---|---|---|---|---|---|---|---|---|
| tapered | 1 | -0.125 | 0.22 | 1030 | 9.08 | 1810 / 2040 | 123.5, 117.5, 112.0, 107.8, 104.0 | 129.0, 120.4, 112.1, 104.3, 97.1 | 1.65 |
| tapered | 2 | -0.125 | 0.35 | 1030 | 13.37 | 1335 / 1275 | 118.3, 111.7, 107.5, 107.0, 102.0 | 128.2, 119.9, 112.4, 105.9, 100.1 | 0.59 |
| tapered | 3 | -0.125 | 0.36 | 1030 | 13.79 | 1303 / 1240 | 120.7, 113.7, –, –, – | 128.3, 120.2, 112.9, 106.6, 101.1 | 0.58 |
| tapered | 4 | -0.125 | 0.49 | 1030 | 21.92 | 986 / 908 | 118.3, 113.5, 108.2, 109.3, 105.5 | 127.8, 119.1, 111.5, 105.3, 99.8 | 0.58 |
| tapered | 5 | -0.125 | 0.50 | 1050 | 20.97 | 993 / 914 | 117.7, 112.7, 110.1, 109.7, 106.5 | 128.3, 120.6, 114.3, 109.3, 105.0 | 0.57 |
| tapered | 6 | -0.125 | 0.50 | 1050 | 19.65 | 992 / 914 | 117.2, 114.2, 111.5, –, – | 128.5, 121.8, 116.9, 113.1, 109.8 | 0.54 |
| tapered | 7 | -0.125 | 0.50 | 1050 | 18.21 | 912 / 914 | 117.9, 115.3, 113.7, 113.5, – | 129.6, 125.2, 121.8, 118.8, 116.0 | 2.76 |
| tapered | 8 | -0.125 | 0.49 | 1050 | 16.98 | 800 / 924 | 118.0, 116.0, 117.0, 116.2, 115.0 | 131.1, 128.3, 125.6, 122.9, 120.2 | 5.27 |
| tapered | 9 | -0.125 | 0.49 | 1050 | 14.31 | 251 / 924 | 119.0, 118.2, 119.5, 118.8, 116.7 | 136.2, 135.9, 134.5, 132.7, 130.7 | 11.47 |
| tapered | 11 | -0.125 | 0.49 | 600 | 16.65 | 284 / 545 | –, 112.4, 110.9, 108.8, 105.9 | 128.0, 125.4, 122.0, 118.3, 114.3 | 7.85 |
| tapered | 12 | -0.125 | 0.49 | 900 | 18.34 | 734 / 800 | –, 111.5, 109.5, 108.5, 110.5 | 128.4, 123.8, 119.8, 116.0, 112.2 | 4.20 |
| tapered | 13 | -0.125 | 0.49 | 1400 | 20.63 | 1326 / 1280 | 119.9, 115.7, 112.5, 110.5, 106.5 | 131.5, 124.9, 119.3, 114.6, 110.7 | 0.57 |
| tapered | 18 | +0.000 | 0.22 | 1020 | 9.18 | 1805 / 2050 | 124.8, 121.1, 117.6, 113.8, 109.5 | 129.1, 123.5, 118.1, 112.9, 107.9 | 1.18 |
| tapered | 19 | +0.000 | 0.22 | 1020 | 8.81 | 1822 / 2030 | 123.8, 119.6, 115.7, 110.0, 108.2 | 129.0, 123.3, 117.9, 112.7, 107.5 | 0.57 |
| tapered | 20 | +0.000 | 0.33 | 1020 | 12.36 | 1403 / 1100 | 123.6, 119.5, 116.1, 112.8, 109.0 | 129.2, 124.3, 119.7, 115.4, 111.1 | 0.53 |
| tapered | 21 | +0.000 | 0.49 | 1020 | 21.59 | 991 / 908 | 121.6, 118.3, 114.9, 111.9, 109.7 | 130.5, 126.1, 122.0, 118.1, 114.1 | 0.52 |
| tapered | 22 | +0.000 | 0.49 | 1030 | 20.42 | 1000 / 915 | 122.5, 120.1, 117.3, 114.6, 110.3 | 130.8, 127.2, 123.9, 120.8, 117.5 | 0.53 |
| tapered | 23 | +0.000 | 0.50 | 1040 | 19.32 | 999 / 910 | 123.3, 121.5, 120.1, 118.2, 115.0 | 131.1, 128.7, 126.7, 124.6, 122.4 | 0.55 |
| tapered | 24 | +0.000 | 0.50 | 1050 | 18.30 | 980 / 915 | 124.3, 123.3, 122.5, 121.3, 119.1 | 131.8, 130.6, 129.5, 128.3, 127.0 | 2.97 |
| tapered | 28 | +0.000 | 0.50 | 600 | 16.31 | 160 / 540 | 120.7, 120.5, 119.3, 117.0, 113.6 | 133.8, 133.3, 131.7, 129.5, 127.1 | 6.00 |
| tapered | 29 | +0.000 | 0.50 | 1000 | 18.57 | 866 / 870 | 121.6, 120.6, 119.3, 116.8, 114.1 | 132.2, 130.3, 128.2, 126.0, 123.7 | 1.82 |
| tapered | 33 | +0.125 | 0.21 | 1030 | 8.39 | 1870 / 2170 | 125.7, 121.3, 115.8, 112.7, 108.2 | 130.0, 123.8, 117.5, 111.2, 104.9 | 0.44 |
| tapered | 34 | +0.125 | 0.35 | 1030 | 12.81 | 1352 / 1295 | 124.7, 120.7, 116.9, 112.7, 110.9 | 130.1, 125.0, 119.8, 114.6, 109.4 | 0.49 |
| tapered | 35 | +0.125 | 0.50 | 1030 | 21.96 | 978 / 900 | 123.5, 119.4, 114.6, 109.1, 104.5 | 131.1, 125.9, 120.6, 115.4, 110.0 | 0.49 |
| tapered | 36 | +0.125 | 0.50 | 1000 | 20.54 | 950 / 912 | 124.3, 118.1, 116.7, 112.9, 108.0 | 131.3, 127.2, 123.0, 118.7, 114.3 | 0.51 |
| tapered | 37 | +0.125 | 0.50 | 1050 | 19.39 | 996 / 920 | 125.3, 122.5, 119.3, 115.0, 111.5 | 132.1, 129.0, 125.8, 122.6, 119.2 | 0.52 |
| tapered | 42 | +0.125 | 0.51 | 550 | 16.78 | 127 / 490 | 122.2, 120.2, 117.6, 113.6, 109.8 | 132.4, 130.6, 127.7, 124.3, 120.7 | 4.01 |
| tapered | 43 | +0.125 | 0.50 | 900 | 17.59 | 560 / 775 | 123.4, 120.7, 117.5, 113.5, 109.9 | 133.5, 131.4, 128.6, 125.5, 122.2 | 2.78 |
| rectangular | 1 | -0.125 | 0.21 | 1030 | 11.43 | 1900 / 2160 | 125.0, 119.0, 113.5, 109.0, – | 128.7, 120.0, 111.8, 104.7, 98.5 | 1.01 |
| rectangular | 2 | -0.125 | 0.34 | 1040 | 15.58 | 1408 / 1340 | 123.5, 117.8, 112.5, 109.5, 107.0 | 127.7, 119.5, 113.3, 108.9, 104.8 | 0.60 |
| rectangular | 3 | -0.125 | 0.50 | 1030 | 25.13 | 995 / 915 | 120.5, 115.6, 109.5, 107.5, – | 127.0, 118.6, 113.7, 110.1, 106.3 | 0.62 |
| rectangular | 4 | -0.125 | 0.49 | 1050 | 23.41 | 1028 / 942 | 120.5, 116.0, 112.0, 109.5, – | 127.4, 120.5, 117.1, 114.6, 111.7 | 0.61 |
| rectangular | 5 | -0.125 | 0.49 | 1060 | 22.41 | 1018 / 946 | 121.5, 116.5, 112.5, 108.0, – | 127.7, 122.3, 120.4, 118.8, 116.7 | 0.60 |
| rectangular | 11 | +0.000 | 0.25 | 1048 | 13.34 | 1717 / 1830 | 129.5, 125.0, 120.0, 115.5, – | 129.0, 123.9, 119.2, 114.8, 110.4 | 0.80 |
| rectangular | 12 | +0.000 | 0.35 | 1048 | 16.65 | 1366 / 1310 | 128.0, 124.0, 119.5, 114.5, – | 129.3, 125.0, 121.4, 117.9, 114.2 | 0.64 |
| rectangular | 13 | +0.000 | 0.49 | 1080 | 22.83 | 1036 / 955 | 126.5, 123.5, 120.5, 115.5, 111.0 | 131.2, 129.1, 127.6, 125.8, 123.8 | 0.68 |
| rectangular | 18 | +0.125 | 0.21 | 1040 | 11.77 | 1892 / 2180 | 129.5, 124.5, 120.0, 115.0, – | 130.0, 124.0, 117.9, 111.8, 105.7 | 0.70 |
| rectangular | 19 | +0.125 | 0.35 | 1035 | 16.37 | 1367 / 1300 | 128.0, 123.0, 119.0, 113.5, – | 130.1, 125.1, 120.3, 115.4, 110.4 | 0.66 |
| rectangular | 20 | +0.125 | 0.50 | 1070 | 23.16 | 1011 / 950 | 128.5, 125.5, 122.0, 117.5, 114.0 | 132.3, 129.5, 126.7, 123.7, 120.6 | 0.73 |
