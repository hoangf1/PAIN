# Phase 92 — NASA's printed mode-pair contributions (2026-10-29)

Plan `IMPLEMENTATION_PLAN.md` §8ai (moved to `COMPLETED_PHASES.md`), committed fa7cfbe before 92b ran. All runs are
diagnostics: no verdict, off the map, defaults unchanged. Author 2026-10-29: tuning is fine "since thats diagnostics".

**92a — pair terms (run before the plan entry; recorded as found).** CR-172428 App. B prints the five largest acoustic ×
structural terms of Eq. (8) at 4000 rpm H1–H3 (p. 207) and 5000 rpm H1–H2 (p. 212). `tone_mean_square_pressure(...; terms)`
returns this code's terms; `APPB_PAIRS` matches them by (Q, I, structural mode). Pair terms in dB re 20 μPa, ours − NASA:

| Tone | Printed pairs (Q I × st: ours − NASA, dB) | q = 0 share of this code's tone |
|---|---|---|
| 4000 H1 (200 Hz) | Q2I0×13 −1.85; Q1I1×12 −1.91; Q2I0×6 −1.83; Q2I0×1 −0.09; Q2I0×2 +0.19 | 92.4 % |
| 4000 H2 (400 Hz) | Q2I3×8 +1.31; Q2I4×6 −0.64; Q1I3×12 +0.74; Q2I3×21 +2.46; Q2I3×9 +1.72 | 5.7 % |
| 4000 H3 (600 Hz) | Q2I8×22 −9.75; Q3I6×20 +3.71; Q1I9×25 −0.03; Q2I8×17 −6.43; Q1I9×19 +3.11 | 2.3 % |
| 5000 H1 (250 Hz) | Q2I4×6 −0.66; Q1I2×4 −0.44; Q3I0×4 −5.58; Q2I2×6 −4.17; Q2I1×8 −0.31 | 75.9 % |
| 5000 H2 (500 Hz) | Q5I1×12 −0.04; Q4I3×21 −0.11; Q1I6×20 −2.86; Q1I6×16 −2.28; Q1I6×12 −2.08 | 69.4 % |

15 of 25 within ±2 dB. NASA prints no q = 0 pair at any tone; in this code a q = 0 pair is the largest at 4000 H1
(Q0 I1 × structural mode 8, 5.55 Pa² against NASA's whole tone, 0.59 Pa²), 5000 H1 and 5000 H2. So in NASA's run each
q = 0 term is below the fifth printed one, at least 25 dB under this code's at 4000 H1. CR-172428 App. A (p. 177) shows
the program reads `FQM(IQ,M)` in TONE and NRED but not how FQM is filled; the documents do not say why q = 0 drops out.

**92b — q = 0 off, 3000 rpm held out (criterion fixed before the run: ±3 dB at all three).**

| Point | NASA (Table 10) | q = 0 off | Δ | q = 0 on (R172428_CODE) |
|---|---|---|---|---|
| 3000 H1 | 63.3 | 63.40 | +0.10 | 71.07 |
| 3000 H2 | 66.2 | 66.89 | +0.69 | 69.02 |
| 3000 H3 | 59.5 | 62.59 | +3.09 | 62.66 |

**Not supported** (2/3; H3 misses by 0.09 dB). Recorded as R172428_CODE_Q0 (diagnostic, outcome not met). H3 hardly
depends on q = 0 (62.66 → 62.59 dB). The 4000/5000 rpm points with q = 0 off (post-hoc, seen in 92a): 91.26, 79.80, 71.59;
84.18, 89.26, 78.07 dB against 91.69, 78.19, 71.30; 86.4, 91.1, 75.7; 8 of 9 within ±3 dB overall, against 4/9 with q = 0 on.

**92c — post-hoc (formed after 92a): q = 0 off and η_n per mode (Phase 89 option) together.** R172428_CODE_Q0_ETAN:
63.55, 67.02, 60.85; 91.19, 79.74, 71.77; 85.85, 89.24, 78.04 dB — all nine within ±2.4 dB of NASA (largest +2.34 at
5000 H3). APPB_PAIRS_Q0_ETAN: 16 of 25 pairs within ±2 dB; the per-pair η_r″ then follows NASA's (e.g. Q2I4 × 6 at 250 Hz:
0.00057 against 0.00053; Q2I2 × 6: 0.0143 against 0.0132). The pairs still off:

| Pair | ours − NASA | Accounts for it |
|---|---|---|
| 5000 H2 Q1I6 × 12, 16, 20 | −2.1 to −2.9 dB | cabin mode at 510.0 Hz here, 507.1 Hz in App. B (0.6 %); at 500 Hz with η_n 0.015 the Eq. (8) denominator (ω_n² − ω_H²)² + N² is 1.8× larger at 510.0 Hz: −2.5 dB |
| 4000 H3 Q2I8 × 22, × 17 | −9.7, −6.3 dB | cabin mode at 603.4 Hz here, 600.3 Hz in App. B, against a 600 Hz tone: the same denominator is 3.3× larger (−5.2 dB) |
| 5000 H1 Q3I0 × 4 | −6.4 dB | η_r″ 0.0078 here against NASA's 0.0034; not resolved |
| 4000 H3 Q3I6 × 20, Q1I9 × 19 | +3.8, +3.5 dB | η_r″ of Q1I9 × 19 is half NASA's (0.027 against 0.055); not resolved |

**Reading.** NASA's CR-172428 run behaves as if (i) the q = 0 cabin modes add nothing and (ii) η_n is a property of each
cabin mode, not of the tone. With both, this code is within 2.4 dB of every printed level; the rest is cabin-mode
frequencies about 0.5 % from NASA's near the tones and two pairs. Both are inferred from NASA's output (reverse
engineering), not documented, and neither carries a verdict: 92b, the one test fixed before the run, missed by 0.09 dB.
Phase 88 found q = 0 off does not reproduce CR-3813's earlier (pre-correction) runs, so if (i) holds it belongs to the
program NASA ran for CR-172428. Phase 92 left the defaults as CR-3813 prints them; Phase 93 (same day, author's
request) made `q0_coupled = false`, `η_n_per_mode = true` the defaults, and Phase 94 tested that form on held-out data
(`phase94_table12_eta_T2.md`).
