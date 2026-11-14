# ISSUE-043: why the computed forward-flight loads lie higher in advance ratio than Report 1012's (2026-11-14)

Diagnostics only, no verdict; run once by Claude at the author's request ("Yes, look for it"). Nothing in `PAIN.jl` and no input file changed; nothing is adopted. Each variant below changes one input to what Report 1012 itself prints, and is run on the same 61 points (38 falling-side, 23 loaded-side) with the Phase 153 set-up otherwise unchanged. The scripts were run once and not kept (rule of 2026-11-10).

## Answer

**Most of the displacement comes from two inputs in which the code's blade differs from the blade Report 1012 prints in its own Fig. 2. The loads model is not the main cause.**

1. **The blade root.** The code integrates the blade from r/R 0.271, the start of the CR-196702 table (`propeller.yaml` gives a spinner radius of 0.1651 m = 0.271 R, marked there as an approximation from an undimensioned drawing). Report 1012 Fig. 2 marks the spinner at r/R 0.331 (located by script on a 600 dpi render). At high blade angles the sections between 0.271 R and 0.331 R work at large helix angles, so they add mostly torque.

2. **The twist near the tip.** The table (CR-196702 App. B-1, a later tabulation of the NACA blade-form curves) agrees with Fig. 2 within 0.25° from r/R 0.30 to 0.90 (relative to 0.75 R), but beyond it Fig. 2 has less pitch: −0.44° at 0.95 R and −0.84° at the tip.

| Set-up | Points | C_T median | C_P median | Efficiency, code − measured (median) | Shift in J to match C_T (median) | C_T within ±15 % | C_P within ±15 % |
|---|---|---|---|---|---|---|---|
| as shipped (Phase 153 set-up) | loaded side (23) | +11.1 % | +14.6 % | -0.014 | +3.6 % (12 of 23) | 19/23 | 12/23 |
| as shipped (Phase 153 set-up) | falling side (38) | +27.8 % | +29.1 % | -0.010 | +3.1 % (38 of 38) | 5/38 | 5/38 |
| twist from Report 1012 Fig. 2 | loaded side (23) | +9.8 % | +12.6 % | -0.013 | +2.4 % (11 of 23) | 20/23 | 17/23 |
| twist from Report 1012 Fig. 2 | falling side (38) | +20.9 % | +23.2 % | -0.013 | +2.4 % (38 of 38) | 12/38 | 7/38 |
| blade root at the spinner, r/R 0.331 (Fig. 2) | loaded side (23) | +6.0 % | +8.2 % | -0.015 | +1.6 % (10 of 23) | 22/23 | 22/23 |
| blade root at the spinner, r/R 0.331 (Fig. 2) | falling side (38) | +17.7 % | +19.2 % | -0.009 | +2.0 % (38 of 38) | 17/38 | 11/38 |
| both | loaded side (23) | +4.4 % | +6.8 % | -0.014 | +1.0 % (10 of 23) | 22/23 | 22/23 |
| both | falling side (38) | +11.1 % | +13.6 % | -0.011 | +1.4 % (38 of 38) | 22/38 | 22/38 |
| scale reference only: blade angle −0.5° | loaded side (23) | +6.8 % | +8.9 % | -0.012 | +2.5 % (13 of 23) | 23/23 | 21/23 |
| scale reference only: blade angle −0.5° | falling side (38) | +8.2 % | +10.6 % | -0.020 | +0.9 % (38 of 38) | 27/38 | 25/38 |

The ±15 % counts are information, not a verdict (ISSUE-042: no verdict by the input rule; any re-run after this search is post-hoc as well).

**Shift in J by blade angle (median over both sides):**

| Set-up | 40° | 45° | 50° | 55° | 60° |
|---|---|---|---|---|---|
| as shipped (Phase 153 set-up) | +1.8 % | +2.6 % | +2.6 % | +3.5 % | +3.7 % |
| both | +0.9 % | +1.5 % | +1.0 % | +1.5 % | +1.5 % |

With both inputs as Report 1012 prints them, the displacement no longer grows with blade angle: what is left is about 1 % to 1.5 % at every blade angle.

## What is left

- A uniform shift of about 1 % to 1.5 % in J, about 0.3° in angle at 0.75 R, in the same direction. Not explained; no further printed input was found that bears on it. Candidates, none tested: the accuracy of the blade-angle setting (not printed), the zero-lift angle of the XFOIL polars, the induced-velocity model.

- The computed efficiency is about 0.01 to 0.015 low in every set-up, so power is still high by more than thrust. Not explained.

- The −0.5° blade-angle run is a scale reference only: it shows that 0.5° of blade angle moves C_T about as much as the two inputs together. It is not a candidate and is not proposed.

## The static cases (information for ISSUE-044)

The same two inputs applied to the static Report 996 loads (RM L8H25a), whose test rig and spinner are not those of Report 1012:

| Blade angle | Tip Mach | Set-up | C_T against measured | C_P against measured |
|---|---|---|---|---|
| 10° | 0.45 | as shipped | -2.4 % | -3.0 % |
| 10° | 0.45 | root at 0.331 | -5.2 % | -5.8 % |
| 10° | 0.45 | Fig. 2 twist | -3.4 % | -4.5 % |
| 10° | 0.45 | both | -6.1 % | -7.3 % |
| 10° | 0.60 | as shipped | -2.6 % | -3.0 % |
| 10° | 0.60 | root at 0.331 | -5.2 % | -5.8 % |
| 10° | 0.60 | Fig. 2 twist | -3.5 % | -4.8 % |
| 10° | 0.60 | both | -6.2 % | -7.7 % |
| 20° | 0.60 | as shipped | -30.4 % | -38.7 % |
| 20° | 0.60 | root at 0.331 | -32.2 % | -40.3 % |
| 20° | 0.60 | Fig. 2 twist | -30.2 % | -39.2 % |
| 20° | 0.60 | both | -32.0 % | -40.9 % |

The static thrust at 10° moves from about −2.5 % to about −6 %. The spinner of the static tests is not printed in the documents in `references/`: Report 996 Fig. 3(c) marks none, and its Fig. 4 shows the propeller on a small hub at the top of a pole. Report 996 Fig. 3(c) draws the β line straight to the tip like Report 1012 Fig. 2 (seen by eye, not read). Whether these cases should change is left to ISSUE-044.

## Report 1012 Fig. 2 against the code's blade table (blade angle)

Read by script: grid calibrated on its 14 × 21 grid lines (residual 1.3 / 2.3 px at 600 dpi), the β line followed column by column from r/R 0.30 to the tip and read beside each gridline; the trace was checked by eye on the overlay. One cell is 2° of β (125 px), so 0.016° per pixel.

| r/R | Fig. 2 β | Table β | Fig. 2 relative to 0.75 R | Table relative to 0.75 R | Difference |
|---|---|---|---|---|---|
| 0.30 | 66.07 | 65.90 | +23.22 | +23.26 | -0.04 |
| 0.35 | 62.90 | 62.71 | +20.05 | +20.07 | -0.02 |
| 0.40 | 59.78 | 59.68 | +16.93 | +17.04 | -0.11 |
| 0.45 | 56.80 | 56.79 | +13.95 | +14.15 | -0.20 |
| 0.50 | 54.02 | 54.05 | +11.17 | +11.41 | -0.24 |
| 0.55 | 51.45 | 51.48 | +8.60 | +8.84 | -0.23 |
| 0.60 | 49.05 | 49.04 | +6.20 | +6.40 | -0.20 |
| 0.65 | 46.75 | 46.76 | +3.90 | +4.12 | -0.22 |
| 0.70 | 44.72 | 44.63 | +1.87 | +1.99 | -0.12 |
| 0.75 | 42.85 | 42.64 | +0.00 | +0.00 | +0.00 |
| 0.80 | 41.05 | 40.82 | -1.80 | -1.82 | +0.02 |
| 0.85 | 39.30 | 39.14 | -3.55 | -3.50 | -0.05 |
| 0.90 | 37.65 | 37.61 | -5.20 | -5.03 | -0.17 |
| 0.95 | 36.00 | 36.23 | -6.85 | -6.41 | -0.44 |
| 1.00 | 34.38 | 35.01 | -8.47 | -7.63 | -0.84 |
