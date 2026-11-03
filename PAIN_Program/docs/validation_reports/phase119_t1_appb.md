# Phase 119 — the T1 family on CR-172428 App. B's printed field (2026-11-02)

Form and criterion fixed in `IMPLEMENTATION_PLAN.md` §8bi (commit 84dbb27) before any run. Cases `T1_APPB` and
`T1_MEAS_DAMPING_APPB` (`validation_case_iso119.jl`). T1's cabin as it ships, with E-11's line + GEXT replaced by the
blocked field PAIN used for the same article, propeller and rpm (CR-172428 App. B printed pp. 193–195, 4000 rpm, H1–H3,
all 16 × 19 points, both quarters as printed, no blocking applied). T1's gate unchanged (2026-10-20): each of H1–H3
within ±4 dB of the E-16 measured mean (gate A), or inside the envelope and within ±4 dB of NASA's E-16 prediction
(gate B); met if all three.

| Case | Field | H1 (dB) | H2 (dB) | H3 (dB) | Gate | Verdict |
|---|---|---|---|---|---|---|
| E-16 measured mean (envelope) | — | 90.0 (65–97) | 80.0 (62–87) | 65.0 (50–74) | — | — |
| NASA's E-16 prediction | not printed | 79.0 | 75.5 | 68.0 | — | — |
| `T1_APPB` | App. B | 88.51 | 75.32 | 65.36 | H1 A, H2 B only, H3 A | **met** 3/3 |
| `T1_MEAS_DAMPING_APPB` | App. B | 90.06 | 78.74 | 65.80 | A, A, A | **met** 3/3 |
| `T1` (no verdict since 118a) | E-11 + GEXT | 86.95 | 79.21 | 77.00 | A, A, fail | — |
| `T1_MEAS_DAMPING` (no verdict since 118a) | E-11 + GEXT | 88.08 | 82.28 | 78.63 | A, A, fail | — |

**Reading.**
- With the printed field, H3 falls from 77–79 dB to 65.4–65.8 dB, within 1 dB of the measured mean. The H3 excess of the T1
  family was the GEXT off-line field (as §2.14 attributed), not the cabin.
- `T1_MEAS_DAMPING_APPB` meets on the measured mean at all three harmonics (largest difference −1.26 dB at H2).
- `T1_APPB`'s H2 is 4.68 dB under the measured mean and passes only through gate B (0.18 dB from NASA's prediction).
  Gate B is part of T1's registered criterion; it compares with NASA's E-16 prediction, whose own field is not printed.

**Not held out in full.** CR-172428's measured 4000 rpm levels (90.3 / 80.3 / 65.2 dB) are E-16's means, and
R172428_EXP has already set App. B's field against them with CR-172428's cabin. New here is CR-3813's own cabin on that
field; no parameter was chosen in this phase. Check: with its own inputs, `interior_spl` reproduces the pipeline's T1
levels exactly (86.946 / 79.209 / 77.002 dB), so the swap changes only the field.
