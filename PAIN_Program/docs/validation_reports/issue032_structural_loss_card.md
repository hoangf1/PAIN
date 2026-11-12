# ISSUE-032: the structural loss factor from the input cards (2026-11-12)

Found and fixed by Claude under the author's authority of 2026-11-11 ("fix all the issues"; "make decisions logically like i do"). No criterion, tolerance or reference file changed.

## What was wrong

CR-3813 Eq. (79) defines the structural loss factor as a sum, η_r = η_r^struc + η_r^rad. It says (p. 42) that "η_r^struc is either a measured value or an estimate", and gives Eq. (80), C/f, as the estimate to use when no measured value exists. Eq. (81) is the external radiation loss η_r^rad, computed from the mode's joint acceptance. The User Manual's printed output (§5.4.3) lists the input structural loss factors η^struc and the external radiation loss factors η^rad as separate items. So the per-band values of cards 12–14 are η_r^struc, and radiation is still added.

This code let a card value replace the whole of Eqs. (79)–(81), so the radiation loss was dropped whenever a deck gave structural loss factors. CR-172428's runs give them (2/f per band). For modes with little shell motion radiation is small, so they agreed with NASA. For shell modes above about 470 Hz radiation is most of η_r, so this code's η_r′ came out at 0.51–0.80 of NASA's. That was the pattern ISSUE-032 described.

## How it was found, stated so the reader can weigh it

The equations as coded were checked first, term by term against the pages: Eq. (82), Eq. (A.8) for C_w, the element matrices (A.10) and (A.11), and the change to subroutine ETASTR on CR-172428 p. 178 that scales the trim terms by the shell mass share. All four match. Each mode's η_r′ was then split into its parts. That showed the shell modes coming out below η_r alone, so a diagnostic re-ran the cards as η_r^struc with radiation added. It reproduced NASA's printed η_r′ at all 32 modes within 6 %. Only after that was the reading checked against CR-3813 p. 42 and User Manual §5.4.3, which support it.

So the place was found with App. B, the case's own data. That is why `R172428_ETA` carries **no verdict** after the fix, by the author's independence rule (ISSUE-021: a verdict reached after a change located with the compared data has none). Its first run, not met 17/32, stays on record; after the fix it is 32/32, post-hoc.

## Effect on other results (re-run 2026-11-12, post-hoc, criteria unchanged)

| Result | Before | After |
|---|---|---|
| R172428_ETA, η_r′ against App. B | not met 17/32 | 32/32 within ±25 % (all within 6 %); no verdict |
| R172428_CODE_DEFAULT, the shipped tones against NASA's printout (diagnostic) | largest 1.19 dB | 8 of 9 tones closer to NASA's print; 5000 rpm H3 moves from −0.76 to −1.88 dB |
| R172428_EXP | not met 5/9 | not met 5/9 |
| R172428_ETAT2 | met 9/9 | met 9/9 |
| FLIGHT10_H234, H2–H4 (diagnostic) | 94.60 / 87.44 / 83.89 dB | 94.21 / 86.29 / 82.64 dB (PAIN prints 96.59 / 88.06 / 83.92) |

The full list of moved values is the regenerated `case_error_summary.csv` (2026-11-12) against its previous version. The Phase 17 baselines and the uncertainty budget do not use card loss factors, and they did not move.

## Held-out check still open

CR-172428 App. C prints a LOSS FACTOR column for the Merlin IVC's 221 structural modes, which nobody here has transcribed. Its deck gives the same kind of card values. A blind transcription, with a criterion fixed before the comparison, would test the fix on an aircraft it was not found on. That is ISSUE-041.

The diagnostic scripts were run once and not kept (rule of 2026-11-10). The fix and its unit test are in `pain_core.jl` (`structural_η_r_prime`) and `test_pain_core.jl`.
