# Phases 93–94 — NASA's latest program form as the default; held-out test on CR-172428 Table 12 (2026-10-29)

Plan `IMPLEMENTATION_PLAN.md` §8aj, §8ak (moved to `COMPLETED_PHASES.md`); Phase 94 criteria committed in 8387c80
before any run. Author 2026-10-29: "whatever makes it match the outputs hopefully thats the latest release".

**Documents.** CR-3813 is dated July 1984, CR-172428 (Pope, "Propeller Aircraft Interior Noise Model Utilization Study
and Validation") September 1984. CR-172428 is the latest PAIN document in hand.

**Phase 93 — defaults.** `PainInputs` and `run_pain_pipeline` now default to the program NASA ran for CR-172428:
`η_r_trimmed_area = true` (App. A Eq. (82) correction; the floor sign and the R2 blocking limit were already default),
`q0_coupled = false` and `η_n_per_mode = true` (Phase 92, inferred from NASA's printed output, not documented).
`tone_acoustic_N` gives every tone path (Eq. (8), the point field of LOUDEST_PT, Eqs. (15)–(16)) the same η_n.
`_pre_correction_form` (floor sign −1, printed Eq. (82), CR-3813 tone sum) runs the cases that reproduce CR-3813's
printed runs; R172428_CODE keeps CR-3813's tone sum (`_cr3813_tone_form`) because the default form was inferred from
its points. Two single-mode checks built on a q = 0 mode (LOUDEST_PT (c), NR_BAND_HAND) drive that mode explicitly.

**Phase 94 — held out.** CR-172428 pp. 85–86 print a second PAIN run of the test article with the trim panel loss factor
η_T = 2.0 (Table 12) and η_n of three cabin modes at that setting. No earlier phase used them.

| Point | NASA Table 12 | this code (default form) | Δ |
|---|---|---|---|
| 3000 H1 | 62.1 | 62.31 | +0.21 |
| 3000 H2 | 65.5 | 66.72 | +1.22 |
| 3000 H3 | 56.9 | 58.12 | +1.22 |
| 4000 H1 | 91.2 | 91.68 | +0.48 |
| 4000 H2 | 73.8 | 75.13 | +1.33 |
| 4000 H3 | 67.4 | 69.09 | +1.69 |
| 5000 H1 | 92.9 | 92.64 | −0.26 |
| 5000 H2 | 89.6 | 88.74 | −0.86 |
| 5000 H3 | 74.0 | 74.95 | +0.95 |

**94a R172428_ETAT2: met**, 9/9 within ±3 dB (criterion ≥ 7/9). **94b APPB_ETA_N_T2: met**, η_n 0.0877, 0.0782, 0.0829
against 0.088, 0.077, 0.081 (criterion ±10 % at all three). Caveat: same test article as the η_T = 0.13 run the form
was inferred from; held out in inputs and outputs, not independent of the article.

**Cases whose recorded result changed with the defaults** (criteria unchanged; outcomes re-recorded 2026-10-29):

| Case | Before (CR-3813 tone sum, printed Eq. (82)) | Phase 93 default form |
|---|---|---|
| REPRO_18b | not met 0/3 (max 10.0) | not met 1/3 (max 11.0) |
| E18_TONES | not met 3/10 (max 9.6) | not met 2/10 (max 10.0) |
| T1 | not met 2/6 (max 11.0) | not met 3/6 (max 12.0) |
| T1_FROM_E12 | not met 1/3 (max 11.0) | not met 1/3 (max 12.0) |
| T2_EQ19 | not met 0/19 (max 40.0) | not met 4/19 (max 57.0) |
| E21_E22_NR | not met 5/35 (max 59.0) | not met 5/35 (max 60.0) |
| T1_MEAS_DAMPING | not met 1/6 (max 19.0) | not met 2/6 (max 12.0) |
| NR_PROP_TP2444 | not met 1/7 (max 25.0) | not met 1/7 (max 24.0) |
| T2_MEAS_EXT | not met 0/4 (max 30.0) | not met 0/4 (max 25.0) |
| T2_PRED_BB | not met 0/3 (max 32.0) | not met 0/3 (max 26.0) |
| NR_PROP_TP2444_PF | not met 2/7 (max 49.0) | not met 1/7 (max 50.0) |
| NR_PROP_TP2444_BR | not met 1/7 (max 25.0) | not met 1/7 (max 24.0) |
| E22_BR | not met 0/4 (max 33.0) | not met 0/4 (max 32.0) |
| T2_MEAS_EXT_BR | not met 0/3 (max 23.0) | not met 0/3 (max 21.0) |
| E22_HF_CODE | not met 1/4 (max 7.7) | not met 1/4 (max 9.5) |
| T1_F1A_FILL | met 4/6 (max 8.9) | not met 3/6 (max 6.6) |
| R172428_EXP | not met 3/9 (max 12.0) | not met 4/9 (max 17.0) |

T1_F1A_FILL goes from met (4/6) to not met (3/6). No criterion or input was changed to recover it.
