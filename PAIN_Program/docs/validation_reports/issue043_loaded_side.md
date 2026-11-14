# ISSUE-043: the loaded side of NACA Report 1012 Fig. 5 (2026-11-14)

Diagnostic, no verdict. Run once by Claude at the author's request ("can you read it"). The question and its decision rule were committed (d51ccef) before any loaded-side point was read; the 23 points were committed (7a64b25) before any load was computed there. The loads set-up is Phase 153's, unchanged (blade form, primary polar set `polars_phase69_ncrit8.json`, standard sea-level stagnation air, tunnel Mach taken as free-stream Mach). The script was run once and not kept (rule of 2026-11-10).

## Answer: **present on the loaded side too**

| Points | Count | C_T median difference | C_P median difference | Efficiency, measured → code (median) | Reynolds ±20 % moves a value by up to | Advance-ratio shift to match C_T (median, where defined) |
|---|---|---|---|---|---|---|
| Loaded side (new) | 23 | +11.1 % | +14.6 % | 0.919 → 0.900 | 6.5 % | +3.6 % (12 of 23) |
| Falling part (Phase 153) | 38 | +27.8 % | +29.1 % | 0.913 → 0.897 | 24.1 % | +3.1 % (38 of 38) |

Decision rule (fixed beforehand): both medians within ±7.5 % → confined to the falling part; both above +7.5 % → present on the loaded side too; otherwise mixed.

## What it shows

- **The code is high on the loaded side too**, by about half as much in relative terms as on the falling part. On the loaded side the curves are flatter, so the same displacement gives a smaller relative difference.
- **The displacement is the same on both sides.** Where it is defined, the code gives the measured C_T at an advance ratio a median 3.6 % higher on the loaded side and 3.1 % on the falling part. So the computed curves are displaced as a whole, not distorted near zero thrust.
- **It is not the unprinted air state.** On the loaded side a ±20 % change of the Reynolds number moves a value by 6.5 % at most and by under 2.5 % at 21 of the 23 points.
- **Power is high by more than thrust,** so the computed efficiency is lower: 0.900 against 0.919 at the median, up to 0.035 lower at 60°.
- **Two points are low:** 40° at J 1.2 (−12.8 % C_T) and 55° at J 2.2 (−3.0 % C_T), each the most heavily loaded of the points read on its curve.
- For information only, not a verdict: within ±15 %, C_T 19/23 and C_P 12/23.

**What this does not establish:** the cause. The candidates of ISSUE-043 remain (the reference line of the printed blade angle; blade twist under load; the zero-lift angle of the XFOIL polars; the tunnel Mach correction). Nothing was changed after the run; choosing a blade-angle offset from this result would be tuning.

## Every new point

| Panel | Mach | Blade angle | J | C_T measured | C_T code | Difference | C_P measured | C_P code | Difference | Efficiency measured | Efficiency code | Reynolds ±20 % | d ln C_T / d ln J (code) | Shift in J to match C_T |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| a | 0.165 | 40 | 1.2 | 0.0954 | 0.0832 | -12.8 % | 0.1612 | 0.1342 | -16.7 % | 0.710 | 0.743 | 0.7 % | 1.07 | – |
| a | 0.165 | 40 | 1.6 | 0.0742 | 0.0817 | +10.1 % | 0.1300 | 0.1453 | +11.8 % | 0.913 | 0.900 | 0.8 % | -0.88 | – |
| a | 0.165 | 40 | 1.8 | 0.0540 | 0.0592 | +9.7 % | 0.1049 | 0.1159 | +10.5 % | 0.926 | 0.919 | 6.5 % | -5.69 | +1.6 % |
| a | 0.165 | 45 | 2.0 | 0.0738 | 0.0857 | +16.1 % | 0.1603 | 0.1878 | +17.2 % | 0.922 | 0.913 | 1.7 % | -1.74 | +4.6 % |
| a | 0.165 | 50 | 2.0 | 0.1007 | 0.1059 | +5.1 % | 0.2361 | 0.2512 | +6.4 % | 0.853 | 0.843 | 0.9 % | 0.14 | – |
| a | 0.165 | 50 | 2.4 | 0.0795 | 0.0931 | +17.2 % | 0.2075 | 0.2456 | +18.3 % | 0.919 | 0.910 | 1.9 % | -2.12 | +4.5 % |
| a | 0.165 | 55 | 2.2 | 0.1102 | 0.1068 | -3.0 % | 0.3181 | 0.2979 | -6.3 % | 0.762 | 0.789 | 1.1 % | 1.01 | +4.2 % |
| a | 0.165 | 55 | 2.4 | 0.1072 | 0.1122 | +4.6 % | 0.3135 | 0.3195 | +1.9 % | 0.821 | 0.843 | 0.9 % | 0.25 | – |
| a | 0.165 | 55 | 2.6 | 0.0994 | 0.1085 | +9.2 % | 0.2949 | 0.3221 | +9.3 % | 0.876 | 0.876 | 0.8 % | -0.57 | – |
| a | 0.165 | 60 | 3.6 | 0.0933 | 0.1052 | +12.7 % | 0.3714 | 0.4304 | +15.9 % | 0.905 | 0.880 | 4.6 % | -3.78 | +3.0 % |
| b | 0.230 | 55 | 2.8 | 0.0934 | 0.1069 | +14.4 % | 0.2835 | 0.3327 | +17.3 % | 0.923 | 0.900 | 1.8 % | 0.13 | – |
| c | 0.350 | 45 | 2.0 | 0.0796 | 0.0866 | +8.7 % | 0.1693 | 0.1891 | +11.7 % | 0.940 | 0.916 | 1.7 % | -0.98 | – |
| c | 0.350 | 45 | 2.2 | 0.0573 | 0.0658 | +14.7 % | 0.1333 | 0.1551 | +16.3 % | 0.946 | 0.933 | 1.4 % | -5.53 | +2.3 % |
| c | 0.350 | 50 | 2.4 | 0.0849 | 0.0943 | +11.1 % | 0.2200 | 0.2472 | +12.4 % | 0.926 | 0.916 | 2.3 % | -0.74 | – |
| c | 0.350 | 50 | 2.6 | 0.0678 | 0.0772 | +13.9 % | 0.1862 | 0.2162 | +16.1 % | 0.946 | 0.928 | 1.7 % | -4.79 | +2.5 % |
| c | 0.350 | 60 | 3.0 | 0.1204 | 0.1328 | +10.3 % | 0.4088 | 0.4665 | +14.1 % | 0.883 | 0.854 | 0.5 % | 0.06 | – |
| c | 0.350 | 60 | 3.2 | 0.1148 | 0.1266 | +10.2 % | 0.4038 | 0.4628 | +14.6 % | 0.910 | 0.875 | 0.9 % | -1.23 | +13.0 % |
| c | 0.350 | 60 | 3.4 | 0.1075 | 0.1191 | +10.8 % | 0.3966 | 0.4552 | +14.8 % | 0.921 | 0.889 | 1.6 % | -0.11 | – |
| c | 0.350 | 60 | 3.6 | 0.0985 | 0.1162 | +18.0 % | 0.3843 | 0.4645 | +20.9 % | 0.923 | 0.901 | 1.9 % | -2.07 | +5.3 % |
| d | 0.430 | 45 | 2.2 | 0.0620 | 0.0694 | +11.9 % | 0.1451 | 0.1637 | +12.8 % | 0.940 | 0.933 | 0.6 % | -5.67 | +1.9 % |
| d | 0.430 | 60 | 3.4 | 0.1069 | 0.1200 | +12.3 % | 0.3984 | 0.4586 | +15.1 % | 0.912 | 0.889 | 1.4 % | -0.52 | – |
| d | 0.430 | 60 | 3.6 | 0.0998 | 0.1178 | +18.0 % | 0.3881 | 0.4699 | +21.1 % | 0.926 | 0.902 | 1.8 % | -1.75 | +5.7 % |
| d | 0.430 | 60 | 3.8 | 0.0879 | 0.1001 | +13.9 % | 0.3635 | 0.4214 | +15.9 % | 0.919 | 0.903 | 1.0 % | -3.78 | +3.1 % |
