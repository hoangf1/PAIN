# Phase 87 — NASA's printed per-mode values against this code (2026-10-29)

Criteria fixed 2026-10-29 before the runs (`IMPLEMENTATION_PLAN.md` §8ae). Inputs: `r172428_inputs(rpm)`; references:
`data/cr172428/appB_acoustic_modes.csv` (p. 195), `appB_contributors_4000rpm.csv` (p. 197), `appB_contributors_5000rpm.csv` (p. 202).
Run: `run_validation_case("APPB_EPS_N")`, `"APPB_ETA_N"`, `"APPB_ETA_RPP"`; each case's table holds every row.

| Step | Case | Criterion | Result |
|---|---|---|---|
| 87a | APPB_EPS_N | ≤ 1 % at every mode | **met** 48/48 (ratios 1.0000) |
| 87b | APPB_ETA_N | ≤ 2 % at every mode ≥ 100 Hz | **not met** 11/46 |
| 87c | APPB_ETA_RPP | ≤ 10 % at ≥ 80 % of pairs | **not met** 8/19 |
| 87d | equation table | — | below |

**87b pattern.** Ours/NASA: modes 3–12 (188–346 Hz) 0.56–3.15; 13–24 (359–446 Hz) 0.87–1.30; 25–48 (465–597 Hz)
0.98–1.09. q = 0 modes (4, 6, 12, 15, 21, 28, 31, 40, 46): 1.12, 0.74, 0.62, 1.20, 0.89, 1.02, 1.01, 1.04, 1.03 — no q = 0
pattern. At NASA's printed frequencies instead of ours (0.5 % apart) the ratios change by a few % only. Post-hoc
diagnostic (formed from this table, not a test): trim conductance at the 1/3-octave band centre holding the mode gives
0.86–1.39, rising smoothly within each band and stepping at 355, 447 and 562 Hz.

**87c pattern.** Pair cabin mode 19 (Q2, I4) × structural mode 6 is printed 0.00053 at 4000 rpm H2 (400 Hz) and at
5000 rpm H1 (250 Hz). This code gives 1.01× and 9.5× NASA's: its N is taken at the tone frequency, NASA's is not. With N at
the mode frequency (post-hoc, information) 8/19, the misses then following those of 87b.

**87d — where q enters (CR-3813 and the code).**

| Place | CR-3813 | Code | Same? |
|---|---|---|---|
| Cabin mode shape cos(qπz/L_c) | Eq. (C.7) | `cabin_modes_3d` | yes |
| Frequency | Eq. (C.12) | `cabin_frequency_3d` | yes (CYL2D_C1, App. B list within 0.5 %) |
| Normalization ε_q (2 for q = 0, 1 for q > 0) in ε_n | Eq. (C.11), p. C-7 | `cabin_eps_3d` | yes (87a, 48/48) |
| Axial coupling f_qM, f₀M = 2/(Mπ) for odd M | Eq. (57) | `axial_coupling` | yes (closed form, unit tests); NASA's printed pairs never show q = 0 |
| Axial truncation q_max | User Manual card 9 | `axial_truncation` | NASA's App. B list includes q = 0 with non-zero ε and η, so q = 0 was in NASA's sum |
| η_n of mode (q, i) | Eq. (77) | `acoustic_N` | no: see 87b |

**Outcome (rules fixed before the runs).** No systematic q = 0 or floor-dominated miss: no code changed. Phase 88 runs.

## Phase 89 — η_n per cabin mode (2026-10-29)

Reading H1 and decision fixed 2026-10-29 before the run (`IMPLEMENTATION_PLAN.md` §8af, committed 8bac84b): each cabin
mode's N is Eq. (77) at its own frequency with the trim conductance at its 1/3-octave band centre, used at every tone
(`PainInputs(...; η_n_per_mode=true)`, default false).

| Step | Case | Criterion | Result |
|---|---|---|---|
| 89a | option + tests | N independent of the tone; default unchanged | done |
| 89b | R172428_CODE_ETAN | ±3 dB at ≥ 7 of 9 (R172428_CODE's) | 5/9 (R172428_CODE 4/9): **not adopted** |
| 89c | information, post-hoc | — | η_n 0.86–1.39 of NASA; η_r″ within 10 % at 10/19 pairs (8/19) |

89b levels (dB): 3000 rpm 70.52, 68.96, 60.94; 4000 rpm 102.57, 80.05, 71.87; 5000 rpm 94.29, 94.38, 78.38
(R172428_CODE: 71.07, 69.02, 62.66; 102.45, 80.05, 71.69; 90.35, 94.40, 78.40). First run used a 1 Hz floor on the
rigid mode's frequency; fixed to N = 0 (Eq. (77) at ω = ω_n) and rerun with the same result.

