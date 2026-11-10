# Markdown inventory of PAIN_Program (Phase 149a, 2026-11-10)

Generated from `git ls-files`: path, lines, date of the last commit that touched it, and its first heading as its purpose. Nothing is proposed for deletion here: that needs the author's approval and a check of what each file duplicates, which a heading does not show. `docs/validation_reports/` (90 files) is kept in place by rule and is not listed.

| File | Lines | Last change | Purpose (first heading) |
|---|---:|---|---|
| `PAIN.jl/scripts/README.md` | 28 | 2026-11-02 | scripts/ |
| `PAIN.jl/scripts/devtools/README.md` | 51 | 2026-11-02 | PAIN.jl developer tools (DaemonMode) |
| `PAIN.jl/test/README.md` | 59 | 2026-11-02 | PAIN.jl tests |
| `README.md` | 359 | 2026-11-05 | PAIN recreation (CCBlade.jl + AcousticAnalogies.jl) |
| `data/NASA_CR-158919/README.md` | 46 | 2026-11-02 | NASA CR-158919 (BBN, static Aero Commander tests): digitized data |
| `data/NASA_CR-159124/README.md` | 43 | 2026-11-02 | NASA CR-159124 (BBN, taxi tests): digitized data |
| `data/README.md` | 19 | 2026-11-02 | data/ |
| `data/airfoil_measured/README.md` | 45 | 2026-11-02 | Measured airfoil section data (digitized 2026-10-22) |
| `data/pereira/README.md` | 21 | 2026-11-02 | Pereira et al. (2026) digitized data |
| `data/polars/README.md` | 22 | 2026-11-02 | XFOIL polars (phase 11) |
| `data/polars/phase69_ncrit_fit.md` | 25 | 2026-11-02 | Phase 69b N_crit fit to NACA TN 1546 |
| `data/report996/MEASURED_NOTES.md` | 103 | 2026-11-02 | NACA 4-(5)(08)-03 static-test and noise figures: digitisation notes |
| `data/report996/naca_4-5-08-03/measured/NOTES.md` | 103 | 2026-11-02 | NACA 4-(5)(08)-03 static-test and noise figures: digitisation notes |
| `data/russell/README.md` | 13 | 2026-11-02 | Russell & Sekula (2017) SUI Endurance (T-Motor 15x5) blade geometry |
| `data/tp1964/README.md` | 28 | 2026-11-02 | NASA TP-1964 bare-cylinder noise-reduction data |
| `data/tp2444/README.md` | 54 | 2026-11-02 | NASA TP-2444 and CR-172428 Fig. 14 spectra (Phase 47) |
| `docs/COMPLETED_PHASES.md` | 3415 | 2026-11-05 | PAIN Recreation — Completed phases |
| `docs/IMPLEMENTATION_PLAN.md` | 760 | 2026-11-10 | PAIN Recreation — Plans & Phased Implementation |
| `docs/INPUTS_AND_SETTINGS.md` | 127 | 2026-11-05 | PAIN inputs and settings (Phase 127, 2026-11-04) |
| `docs/ISSUES.md` | 1175 | 2026-11-10 | Open issues |
| `docs/METHODOLOGY.md` | 960 | 2026-11-05 | PAIN recreation: methodology and claims |
| `docs/METHODOLOGY_STRUCTURE.md` | 87 | 2026-11-02 | Structure of a validation chunk in METHODOLOGY.md |
| `docs/NO_VERDICT_CASES.md` | 145 | 2026-11-05 | Cases without a verdict (not on the validation map) |
| `docs/VALIDATION_GUIDELINE.md` | 4567 | 2026-11-09 | PAIN Reimplementation — Validation Guideline |
| `docs/WALKTHROUGH.md` | 166 | 2026-11-02 | Walk-through: the program, and how to read a validation case |
| `docs/extracted/methodology.md` | 6926 | 2026-11-02 | (no heading) |
| `docs/extracted/user_manual.md` | 2322 | 2026-11-02 | (no heading) |
| `docs/extracted/validation.md` | 14145 | 2026-11-02 | (no heading) |
| `docs/flowchart.md` | 408 | 2026-11-05 | PAIN recreation flowcharts |
| `docs/specs/38a_noise_reduction.md` | 69 | 2026-11-02 | Equations (transcribed from the page images in |
| `docs/specs/38b_high_freq_tones.md` | 39 | 2026-11-02 | Task 38b — CR-3813 §3.2 high-frequency tone formulation (Eqs. 11–16) and the crossover band |
| `docs/specs/38c_hf_broadband.md` | 38 | 2026-11-02 | Task 38c — CR-3813 §3.3 high-frequency broadband model, Eqs. (19)–(23) as printed |
| `docs/specs/38de_e18_e15.md` | 31 | 2026-11-02 | Tasks 38d and 38e — E-18 tone case and E-15 structural loss case (do 38d first, then 38e; one report each) |
| `docs/specs/38f1_card_inputs_geometry.md` | 30 | 2026-11-02 | Task 38f-1 — Manual cards: separate exterior/interior air (ρ, c), cavity length L_c and offset d, rotation dir |
| `docs/specs/38f2_card_inputs_bands.md` | 24 | 2026-11-02 | Task 38f-2 — Manual cards: user 1/3-octave band set, per-band structural and bare acoustic loss-factor input |
| `docs/specs/38g_appd_structural_solver.md` | 37 | 2026-11-02 | Task 38g — CR-3813 Appendix D structural solver (Eqs. D.17–D.26), new module, no fitted scale |
| `docs/specs/38h_printed_outputs.md` | 29 | 2026-11-02 | Task 38h — Manual printed outputs (§5.4.3): report file and read-only GUI page |
| `docs/specs/L183_default.md` | 15 | 2026-11-02 | Task — make 1.83 m the single test-article length (decision I-22, 2026-10-22), re-record affected results post |
| `docs/specs/L_sensitivity.md` | 21 | 2026-11-02 | Task — test-article length sensitivity (L = 1.803 m vs 1.83 m), post-hoc, report only |
| `docs/specs/R1_directory_reorg.md` | 56 | 2026-11-02 | Task R1 — directory reorganization (author: "I would like the directory sorted out better") |
| `docs/specs/case_explanations.md` | 36 | 2026-11-02 | Task — plain-language reason and context for every validation case (+ a figure for UT_GRID) |
| `docs/specs/phase29bc_guard_provenance.md` | 20 | 2026-11-02 | Task — Phase 29b (guard) and 29c (provenance tags) for the aircraft path (the author said go on 2026-10-22: "c |
| `docs/specs/phase30_parametric_blocks.md` | 17 | 2026-11-02 | Task — Phase 30: parametric cabin blocks on the aircraft path (30a–30d) (author: "continue until no more phase |
| `docs/specs/phase31_uncertainty.md` | 19 | 2026-11-02 | Task — Phase 31: uncertainty plan for the aircraft cabin result (31a–31f) (author: "continue until no more pha |
| `docs/specs/phase36_mode_animation.md` | 18 | 2026-11-02 | Task — Phase 36: cabin mode animation (display only), steps 36a, 36b, 36c, 36e (36d optional structural view:  |
| `docs/specs/total_flowchart.md` | 31 | 2026-11-02 | Task — one total flowchart in the Validation map tab (aircraft path + PAIN path + all validation comparisons), |
| `references/SOURCES.md` | 60 | 2026-11-10 | Reference sources added 2026-10-22 |
| `site/README.md` | 109 | 2026-11-02 | The methodology website |
