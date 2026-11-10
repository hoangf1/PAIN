# Phase 138: the inputs behind NASA's ref. 2 curve of TP-1964 Fig. 8 (2026-11-10)

Read 2026-11-10 by Claude under the author's delegation of 2026-11-10. Nothing was run. No criterion or number changed. One registry change follows from the decision table of 138b, fixed in the plan on 2026-11-09 before this reading.

## 138a: NASA's inputs against this code's

TP-1964 p. 7 says its predicted curve "is from reference 2", which is CR-159363 (Phase I).

| Input | NASA (CR-159363) | Where | This code (`NR_TP1964_REF2`, `NR_TP1964_XOVER_REF2`) |
|---|---|---|---|
| Loss factors | Table 3, band averages per 1/3-octave band. Acoustic η_n is 0.143 at 50–63 Hz, 0.155 at 200 Hz, 0.0011–0.0097 above 315 Hz; structural η_r is 0.0013–0.0045 | PDF p. 101; the rule is on p. 103: a resonant mode takes its band's value | TP-1964 Fig. 17 reverberation times, nine points, η = 2.2/(f T60) |
| Equation per band | Eq. (10) from 40 to 1250 Hz; Eq. (17), the high-frequency form, from 1600 Hz | PDF pp. 137–138 | Eq. (18) in every band (`NR_TP1964_XOVER_REF2`: Eq. (19) above its changeover) |
| Lengths | cylinder 1.1938 m (47 in), cavity 1.2192 m (48 in), from Curve 2 on | PDF p. 138 | both 1.193 m |
| Closely coupled modes | moved apart "so that there is no modal overlap" (Curve 3), no amount given | PDF pp. 140–142 | as computed |
| Radiation damping, 630–1250 Hz | raised for the acoustically fast modes (Curve 3), no value given | PDF p. 141 | band-average radiation loss factor |
| Structural mode (1,1) | excluded (Fig. 34), argued from the soft suspension | PDF pp. 145–146 | included |

## Which NASA curve TP-1964 plots

TP-1964 Fig. 8's predicted points (`data/tp1964/tp1964_fig8_noise_reduction.csv`), set against the bands CR-159363 prints in full:

- **They match** at 125 Hz (29.8 against 29.98 dB), 200 Hz (42.5 against 42.55 dB) and 315 Hz (14.2 against 14.73 dB).
- **They do not match the Curve 3 printouts** at 400 Hz (11.8 against 2.24 dB) or 500 Hz (13.2 against 6.38 dB). The printouts at those bands are dominated by the (1,1) structural mode (p. 145).
- **They do not match Curve 2** at 1000 Hz (2.1 against −11.83 dB).

So TP-1964 plots the final prediction of CR-159363 Fig. 34. That prediction excludes the (1,1) mode, moves the coupled modes apart and raises the radiation damping.

## 138b: decision

**Case (ii).** The inputs of the compared curve are not printed as numbers: the mode spacing, the radiation damping and the choice of modes. NASA chose them while comparing with the measurement it plots beside the curve (pp. 140–146). Under the input rule of Phase 118a, `NR_TP1964_REF2` (already without a verdict since Phase 135f) and `NR_TP1964_XOVER_REF2` carry no verdict. Their recorded outcomes stay on record and are not passes.

- **138c (band by band)** is for case (iii), equal inputs, so it does not run.
- **The printed loss factors and lengths could be fed in.** They are printed and differ from this code's. A re-run with them would still be compared with a curve that rests on the unprinted choices, so it is not made.
