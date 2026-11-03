# Phase 118c — the not-met cases with complete inputs, fewest points first (2026-11-02)

After the input-completeness rule (118a) moved 14 cases off the map, 23 cases are not met and every input they use is
printed or measured. For each: the class of §2.14 (M method as printed, A approximation, I input or data, N NASA's
printout not explained, D test design), the causes the documents name and the phase that tested each, and what is left.
Rule fixed in `IMPLEMENTATION_PLAN.md` §8bh: a cause named by the documents and tested by no phase is run once against
the case's unchanged criterion. Points from the 2026-10-30 snapshot.

| Case | Points | Class | Causes named and where tested | Untested cause |
|---|---|---|---|---|
| E22_BR | 0/4 | M | Table D-1's 32 modes (Phase 83, refuted); NASA's own E-22 prediction is 32–44 dB over the measurement (Phase 61) | none |
| R996_PHASE | 0/1 | A | wiring (F1A_INDEP, 0.02°), polars (Phase 73); Report 996's own Eq. (2) gives 165° against 155° | none |
| E21_E22_NR | 5/35 | N, M | floor sign (Phase 61), NASA's 300 modes (Phase 84) | none |
| NR_PROP_TP2444 | 1/7 | M | Table D-1 modes (Phase 83); trim model above 1 kHz (NASA's statement) | none |
| NR_PROP_TP2444_BR | 1/7 | M | as NR_PROP_TP2444; bridge mapping (Phase 59) | none |
| NR_PROP_TP2444_PF | 1/7 | A | Eq. (66) separable form, 0.4–2 dB (Phase 50a) | none |
| E22_HF_CODE | 1/4 | M | NASA's 300 modes (Phase 83: 6–19 dB below NASA with them) | none |
| APPB_ETA_N | 12/46 | N | trim per band (Phase 100, the default), band-centre rule (Phases 95–96), CYL2D 2-D part at 341 m/s (Phase 106) | none |
| NR_TP1964 | 6/18 | M | negative NR is a property of Eq. (18) (Phase 53) | none |
| NR_TP1964_REF2 | 6/18 | M | as NR_TP1964 | none |
| CYL2D_PRINTED | 57/168 | N | grid rule at both angles (Phases 105, 111: no NY fits 62.6°) | none |
| E14_LOSS | 7/18 | I (probable) | TRIM_CLOSED and TRIM_PASSIVITY hold (Phase 41); **Fig. A-2 digitized at six frequencies only: untested until this phase** | run here: not supported (below) |
| NR_TP1964_XOVER_REF2 | 8/18 | M | as NR_TP1964 | none |
| NR_TP1964_XOVER | 9/18 | M | as NR_TP1964 | none |
| R172428_ETA | 17/32 | N | truncated shapes (Phase 82c), masses and admittances (Phase 82c), Ση″ and Eq. (A.8) variants (Phases 97–98) | none |
| R172428_CODE | 5/9 | N | mode counts (Phase 84b), q = 0 (Phases 88, 92), η_n per mode (Phase 89), band-centre η_n (Phase 96); judged on the fixed CR-3813 tone form | none |
| R172428_EXP | 5/9 | N | as R172428_CODE | none |
| POLAR_FIDELITY | 40/61 (verdict on held-out 16-312) | A | XFOIL fidelity on thicker sections (Phases 67, 69, 73) | none |
| PER_FIG8 | 10/14 | N | loads (Phase 69), observer side (Phase 72), thickness term (Phase 76); installation near the −20° microphone | none the documents allow testing |
| R996_LOADS | 24/32 | A | polar defects (Phase 69), section c_l (Phase 73: ≤ 7.9 % thrust); c_d ≈ 25 % low | none |
| PER_FIG9 | 15/18 | N | as PER_FIG8; Fig. 9 re-read (Phase 74) | none |
| FLIGHT_MODES | 197/221 | N, I | second transcription pass (Phase 110), 5/3 terms (Phase 107) | none |
| E12_BLOCK | 29/31 | I, N | digitization spread δ_dig = 2.91 dB; NASA's E-12 − E-11 step matches Eq. (43) (A3b, 2026-10-28) | none |

**The one run (E14_LOSS on NASA's per-band PF-105 table).** Fixed before the run: E14_LOSS's computation with the App. D
deck's per-band PF-105 table (Phase 100) in place of Fig. A-2's six digitized frequencies, criterion unchanged; the
cause is supported if the count rises by at least 4 bands. Result: 6/18 against 7/18. **Not supported**; the coarse
digitization of Fig. A-2 does not explain E14_LOSS's miss. Record: `phase118_e14_deck.md`.

**What this leaves.** For every full-input case that is not met, no cause the documents name is left untested. The misses
sit in PAIN's method as printed (M), in a stated approximation of this recreation (A), in NASA's printed output in a way
the documents do not explain (N), or in the data's resolution (I). None is claimed as a pass.
