# ISSUE-048: Report 1377's ground tests, the code against the measured levels at rest (2026-11-23)

Done by Claude at the author's go-ahead of 2026-11-22 ("Yes, start 048"). This is a diagnostic: no verdict, and it is not registered as a case. The rule was written in ISSUE-048 and committed (09d58b7) before any polar, load or level was computed for a ground row. The runner (`PAIN.jl/scripts/run/issue048_ground.jl`) was run once; it is in the commit that records this result and is removed in the next one.

## The question

In flight, the code is a median 7.0 dB above the measured levels for the tapered blade (Phase 156b). Is it as high on the ground, at rest?

- **Yes (D ≥ +4 dB):** the causes shared by flight and ground carry most of the difference: the near field and chordwise loading, the boom and airplane, and the airfoil family.
- **No (D between −2 and +2 dB):** the flight-only causes carry it: forward speed, section Mach above about 0.7, and the outer blade unloading.
- **Otherwise, or if a check of an unprinted input puts D in another band:** not settled.

D is the median of (code − measured) over the tapered blade's ground levels.

## What was run

- **Data:** Report 1377's ground rows (Tables I and II), read in two passes with no disagreement (`data/report1377/tables_I_II_ground.csv`).
  - Tapered blade: a traverse along the axis at 1,030 hp, 13 positions with levels, and power steps of 570 to 1,200 hp at x = +0.125 D, 0 and −0.125 D. That is 25 rows and 99 levels.
  - Rectangular blade: 3 rows at 1,030 hp, 13 levels.
- **Inputs:** those of Phase 156b, at zero forward speed. The blade angle is set so that the computed shaft power equals the printed power. Table II prints no ground pressure, so its rows use standard sea level.
- **Polars:** 104 extra XFOIL polars at the static section Mach and Reynolds numbers (same settings), in `polars_<set>_ground.json`. The flight files are unchanged.

## Result

| | D, median code − measured | Answer band |
|---|---|---|
| Tapered blade, as shipped | **+1.81 dB** (99 levels) | "no": the flight-only causes |
| Check: four-digit sections | +0.79 dB | "no" |
| Check: power −5 % | +1.32 dB | "no" |
| Check: power +5 % | **+2.06 dB** | not settled |
| Rectangular blade (no rule) | +0.81 dB (13 levels) | — |
| In flight, tapered (Phase 156b) | +7.0 dB | — |

**Answer by the rule: not settled.** The power +5 % check puts D at +2.06 dB, 0.06 dB outside the "no" band.

What the numbers show, without a rule:
- Every check puts D between +0.8 and +2.1 dB. None comes near the +4 dB of the "yes" band.
- On the ground the code is about 5 dB closer to the measured levels than in flight, for the same blade, boom and microphone distance.
- 54 of the 99 tapered levels are within ±3 dB (in flight, 22 of 132).

### By harmonic and position (tapered blade)

| | Harmonic 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Ground, median code − measured (dB) | +3.5 | +3.4 | +0.1 | −1.0 | −4.6 |
| Flight, Phase 156b (dB) | +8.6 | +7.7 | +6.6 | +6.2 | +5.2 |
| Ground levels | 25 | 25 | 25 | 18 | 6 |

| Microphone position | Levels | Median code − measured | Within ±3 dB |
|---|---|---|---|
| Ahead of the disk (x > 0) | 37 | +2.1 dB | 25 |
| In the disk plane | 20 | +1.8 dB | 15 |
| Behind the disk (x < 0) | 42 | +0.7 dB | 14 |

- On the ground the code is high on the first two harmonics and low on the fourth and fifth.
- Behind the disk, the computed levels fall off with harmonic order much faster than the measured ones. At x = −0.125 D and 570 hp the fifth harmonic is 25 dB low.

### Thrust

| Rows | Computed / printed static thrust |
|---|---|
| Traverse, 1,030 hp | 1.05–1.07 |
| Power steps, 1,200 hp | 1.16–1.18 |
| Power steps, 960 hp | 1.24–1.36 |
| Power steps, 570–710 hp | 1.63–1.81 |
| Rectangular, 1,030 hp | 1.24–1.25 |

- At part power the code gives 60–80 % more thrust than printed. A level-only check cannot explain that.
- On the 13 traverse rows, where thrust is within 10 %, D is +1.91 dB (52 levels): the same as on all rows.

### Sensitivity

A check moves a compared level by at most 2.5 dB (four-digit sections), 1.1 dB (power ±5 %), or 0.24 dB (pressure ±3 %, rectangular rows). On 12 of the 28 rows no check moves a level by more than 1 dB.

## What this means for ISSUE-048

- By the rule, the ground test does not settle the question.
- The numbers lean one way: the code is much closer at rest than in flight, under every check. That points to the flight-only causes (forward speed, high section Mach, outer unloading), not the shared ones. It is not established.
- Two findings were not asked about. They are recorded here, with no rule and nothing tested:
  - At part power the computed static thrust is 1.6–1.8 times the printed thrust.
  - Behind the disk the computed higher harmonics fall off much faster than the measured ones.
- **Not modelled:** a ground reflection. It would raise the measured levels and so lower D.
- **Closed the same day.** Both tickets were closed as "inputs could not be found" (ISSUES.md, 2026-11-23). There is no second microphone distance. The printed power is a setting from the engine maker's power curves (TN 3417 p. 4), and neither report lists a thrust instrument.

## Every row

Levels in dB re 20 μPa; "–" where the report prints none. The blade-angle offset is from Fig. 2's drawn angles.

| Blade | Row | x/D | Power (hp) | Offset (deg) | Thrust, code / printed (lb) | Measured H1–H5 | Code H1–H5 |
|---|---|---|---|---|---|---|---|
| tapered | 4 | +0.075 | 1030 | −1.23 | 2991 / 2800 | 128.6, 122.6, 116.7, 110.0, 109.3 | 132.1, 125.5, 118.6, 111.6, 104.6 |
| tapered | 5 | +0.060 | 1030 | −0.74 | 2932 / 2800 | 128.9, 121.5, 116.5, 112.7, – | 131.8, 125.3, 118.6, 111.7, 104.9 |
| tapered | 6 | +0.045 | 1030 | −0.74 | 2932 / 2800 | 128.7, 122.3, 117.1, 112.9, – | 131.4, 125.1, 118.5, 111.9, 105.2 |
| tapered | 7 | +0.030 | 1030 | −1.23 | 2991 / 2800 | 127.2, 122.0, 116.3, 111.3, 109.9 | 131.1, 124.9, 118.4, 112.0, 105.5 |
| tapered | 8 | +0.015 | 1030 | −1.23 | 2991 / 2800 | 127.5, 121.0, 116.3, 111.3, 108.0 | 130.7, 124.4, 118.0, 111.6, 105.2 |
| tapered | 9 | 0 | 1030 | −1.23 | 2991 / 2800 | 127.1, 120.3, 115.6, –, – | 130.4, 123.9, 117.4, 111.0, 104.7 |
| tapered | 10 | −0.015 | 1030 | −1.23 | 2991 / 2800 | 131.9, 124.5, 120.5, 114.5, – | 130.2, 123.4, 116.7, 110.2, 103.8 |
| tapered | 11 | −0.030 | 1030 | −1.23 | 2991 / 2800 | 126.7, 120.3, 114.9, 109.9, – | 130.2, 123.0, 116.0, 109.3, 102.8 |
| tapered | 12 | −0.045 | 1030 | −0.74 | 2932 / 2800 | 126.5, 118.1, 115.1, 109.2, – | 130.3, 122.7, 115.3, 108.2, 101.4 |
| tapered | 13 | −0.060 | 1030 | −0.74 | 2932 / 2800 | 126.7, 120.5, 115.1, 109.5, – | 130.5, 122.4, 114.6, 107.2, 100.1 |
| tapered | 14 | −0.075 | 1030 | −0.74 | 2932 / 2800 | 126.8, 118.0, 116.0, 108.5, – | 130.6, 122.2, 113.9, 106.1, 98.6 |
| tapered | 16 | −0.104 | 1030 | −0.74 | 2932 / 2800 | 126.5, 116.1, 116.3, –, – | 130.8, 121.6, 112.6, 103.9, 95.6 |
| tapered | 17 | −0.125 | 1030 | −0.74 | 2932 / 2800 | 126.1, 115.5, 116.8, –, – | 130.8, 121.1, 111.5, 102.2, 93.3 |
| tapered | 18 | +0.125 | 570 | −6.23 | 2690 / 1490 | 126.1, 116.2, 110.8, –, – | 128.9, 119.8, 110.6, 101.4, 92.3 |
| tapered | 19 | +0.125 | 710 | −5.81 | 3023 / 1850 | 128.0, 119.8, 113.8, –, – | 130.7, 122.3, 113.8, 105.2, 96.6 |
| tapered | 20 | +0.125 | 960 | −3.01 | 3108 / 2500 | 128.6, 120.8, 116.0, 110.0, – | 132.4, 124.7, 116.8, 108.8, 100.8 |
| tapered | 21 | +0.125 | 1200 | −3.46 | 3595 / 3100 | 130.5, 124.7, 120.5, 115.0, – | 134.5, 128.2, 121.7, 115.2, 108.6 |
| tapered | 22 | 0 | 570 | −6.02 | 2665 / 1490 | 122.1, 113.2, 109.5, –, – | 124.4, 116.8, 109.6, 102.7, 95.8 |
| tapered | 23 | 0 | 710 | −6.20 | 3081 / 1850 | 125.0, 117.0, 113.0, 108.0, – | 126.6, 119.8, 113.3, 107.0, 100.6 |
| tapered | 24 | 0 | 960 | −3.26 | 3150 / 2500 | 127.8, 121.5, 117.7, 112.0, 110.5 | 129.6, 123.1, 116.8, 110.5, 104.3 |
| tapered | 25 | 0 | 1200 | −3.87 | 3663 / 3100 | 129.9, 123.9, 120.1, 115.3, 113.5 | 132.1, 127.0, 122.0, 117.1, 112.1 |
| tapered | 26 | −0.125 | 570 | −5.61 | 2616 / 1490 | 119.9, 109.0, 110.0, 104.7, 104.5 | 126.2, 114.0, 101.9, 90.3, 79.4 |
| tapered | 27 | −0.125 | 710 | −6.24 | 3088 / 1850 | 123.5, 113.5, 113.5, –, – | 128.4, 117.0, 105.8, 95.3, 85.9 |
| tapered | 28 | −0.125 | 960 | −4.72 | 3405 / 2500 | 127.2, 120.0, 117.5, 109.0, – | 131.3, 121.4, 111.7, 102.6, 94.1 |
| tapered | 29 | −0.125 | 1200 | −3.75 | 3642 / 3100 | 129.9, 123.0, 120.0, 113.5, – | 133.4, 124.9, 116.8, 109.2, 102.1 |
| rectangular | 1 | +0.125 | 1030 | −0.35 | 3498 / 2800 | 131.5, 125.5, 118.0, 111.0, 112.0 | 133.5, 126.3, 118.9, 111.4, 103.8 |
| rectangular | 2 | 0 | 1030 | −0.27 | 3484 / 2800 | 129.5, 123.0, 118.5, 113.0, – | 130.4, 124.4, 118.7, 112.9, 107.2 |
| rectangular | 3 | −0.125 | 1030 | −0.27 | 3484 / 2800 | 129.0, 120.0, 119.0, 108.0, – | 131.5, 121.4, 111.6, 102.6, 94.6 |

Tapered rows 1–3 (x = +0.125, +0.104, +0.089 D) were lost to extraneous noise, as the report says; row 15 (−0.089 D) has no printed level.
