# Phase 106 — cabin-mode frequencies with CYL2D's 2-D part at 341 m/s (2026-10-30)

Plan `IMPLEMENTATION_PLAN.md` §8av (now in `COMPLETED_PHASES.md`); criterion fixed 2026-10-30 (commit 25f7acb). Code-on-code
fix: `cabin_frequency_3d(mode, a, L, q; c0, c2d=CYL2D_C0)` takes the 2-D part at CYL2D's 341 m/s and the axial part at the
deck's c; `PainInputs.c_cyl2d` (default 341; `nothing` = the old form, both parts at c_int).

**CABIN_FREQ_PRINTED (P): met.** App. B p. 185 (held out): 47/47 printed cabin frequencies within 0.02 Hz / 0.02 %;
the form before Phase 106 reproduces 6/47. Seen, post-hoc: the Merlin list and run 10's printed pairs, 80/81 (the miss is
run 10's Q4 I3, printed 219.4 where the glyph may be 218.4; this code 218.4).

**Baselines (R11, author's go-ahead 2026-10-30).** `phase17_baselines.csv` renewed: 6 of 157 values (the tone SPLs, by
0.02–0.50 dB). `scripts/run/freeze_baselines.jl` had not followed the Phase 93 test form (`_cr3813_tone_form`,
η_r_trimmed_area = false) and is now brought to it.

**Knock-on, labelled post-hoc** (with Phase 107's term change in the same tree; original results stay on record):

| Case | Before | After |
|---|---|---|
| APPB_ETA_RPP (P) | not met, 12/19 | **met, 16/19** |
| APPB_ETA_N (P) | not met, 16/46 | not met, 12/46 |
| R172428_CODE (P) | not met, 4/9 | not met, 5/9 |
| R172428_EXP (E) | not met, 5/9 | not met, 5/9 |
| R172428_ETA (P) | not met, 17/32 | not met, 17/32 |
| R172428_ETAT2 (P) | met, 9/9 (largest 2.09 dB) | met, 9/9 (largest 1.73 dB) |
| APPB_ETA_N_T2 / _BAND (P) | met, 3/3 | met, 3/3 |
| R172428_CODE_Q0 (diagnostic) | held-out 2/3 (3000 H3 +3.09 dB) | 3/3 (+1.79 dB) |
| R172428_CODE_DEFAULT (diagnostic) | 8/9 | 9/9 (largest 1.19 dB) |
| APPB_PAIRS / _Q0_ETAN (diagnostic) | 15/25, 16/25 within ±2 dB | 21/25, 22/25 |
| FLIGHT10_H234 (diagnostic) | 97.13 / 89.37 / 81.34 dB | 97.34 / 89.22 / 82.28 (106 alone); 97.33 / 89.00 / 82.86 (with 107) |

The Phase 92 pair offsets that the 0.6 % cabin-frequency difference explained (e.g. 4000 rpm H3 Q2I8 × 22, −9.7 dB) are
the main source of the APPB_PAIRS change. The 3000 rpm H3 gap of the code's default form is +1.19 dB.
