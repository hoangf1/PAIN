# PAIN recreation (CCBlade.jl + AcousticAnalogies.jl)

Julia reimplementation of NASA **Propeller Aircraft Interior Noise (PAIN)**: propeller noise at the
fuselage skin -> blocking by the fuselage -> cabin and structure modes -> interior SPL.

Other docs: [validation guideline](docs/VALIDATION_GUIDELINE.md), [methodology and claims](docs/METHODOLOGY.md) ([chunk layout](docs/METHODOLOGY_STRUCTURE.md)),
[plan](docs/IMPLEMENTATION_PLAN.md) ([completed phases](docs/COMPLETED_PHASES.md)), [cases without a verdict](docs/NO_VERDICT_CASES.md), [notebooks](notebooks/README.md), [flowcharts](docs/flowchart.md).

## How it fits together

PAIN needs the free-field pressure (amplitude and phase, per harmonic) at 160 points on the fuselage skin.
In use there is one source, BEMT + F1A. NASA's measured data are a validation test only, not a user option:

| Source | Where the 160 points come from | Used for |
|--------|--------------------------------|----------|
| BEMT + F1A (the only user option) | CCBlade computes blade loads, AcousticAnalogies (F1A) computes the pressure at the grid points. | Your own propeller and aircraft |
| NASA measured data, `:e11` (validation test only) | NASA's measured data, **Fig. E-11**, which exists only along one line of the grid (l = 1). The **grid extension (GEXT)** fills in the other points with an assumed cosine falloff and phase delay. | Checking the cabin model against NASA's published results (tests T1, T2) |

GEXT exists only because the NASA paper measured one line. The aircraft source does not use it.
`extend_line_to_grid` has three importance-bound options (`falloff_exponent`, `falloff_floor`, `delay_scale`) for the GEXT sensitivity run ([guideline §2.2.1](docs/VALIDATION_GUIDELINE.md)). The defaults are the nominal GEXT; they are not fitted parameters and must not be tuned to the T1/T2 figures.
**Current state (phases 21–22 done 2026-10-21):** the aircraft path runs F1A at all 160 grid points through `evaluate_propeller_source` (no GEXT). GEXT remains on the e11 validation path only. Report 996 and Pereira checks call the same shared function with different observer lists.

After the source, the cabin stages are identical for the user source and the validation test: blocking (Eq. 43) -> CYL2D acoustic modes + MRP structural modes -> PAIN core -> interior SPL.
The [flowcharts](docs/flowchart.md) show the total program overview (diagram 1), the NASA validation path (diagram 2), the aircraft validation path (diagram 3), the shared cabin model (diagram 4) and the GUI `total` validation map (section 5).

## Status

| Block | Status |
|-------|--------|
| Blocking Eq. (43) R1/R2 | **Done** <= 0.06 dB |
| Grid + assumed extension | **Done** (e11 path). Grid azimuth fixed 2026-10-20 (12b): line l = 1 at the propeller azimuth phi_p, upper quarter, theta_l = phi_p + (l-1)·10°; incidence gamma measured from the surface-to-hub direction (0 at l = 1, k = k_p). Results from before this date used the bottom of the fuselage and are void |
| Cabin pre-registration (phase 13) | **Done 2026-10-20** (documentation only, no code change). Assumption register for 15a-17a and the loss/trim pass criteria are dated in [`VALIDATION_GUIDELINE.md` §2.11](docs/VALIDATION_GUIDELINE.md). Cabin phase 17 is partly done (2026-10-20); phase 18 is next |
| Fig. E-12 blocking check (phase 14a) | **Done 2026-10-20** (no `src/` change). Eq. (43) on ANOPP Table 8 reproduces NASA's predicted E-12 curve at 29 of 31 points within delta_dig + 0.5 = 3.41 dB; FAIL at H3 aft (+4.3, +3.8 dB), recorded. delta_dig = 2.91 dB (E-11 gate of 1 dB not met). Prediction is 1-7 dB above the measured circles. Report `docs/validation_reports/e12_blocking.md`; script `PAIN.jl/scripts/run/e12_blocking.jl` |
| CYL2D (phase 15, App. C) | **Done 2026-10-20; criterion re-stated 2026-10-21 (post-hoc).** App. C as written. `TABLE_C1_C0 = 341 m/s` is back-solved from Table C-1 (absolute-f check was partly by construction). **Ratio form:** f_i/f_1 (modes 2–19) within 0.1 % (c0-free; worst 0.0003 %); Φ_G, symmetry, Fig. C-3 unchanged. Three-dimensional modes (q, i) and q-convergence as before (`q_convergence.md`) |
| MRP | **Done**; Fig. D-2 mode 1: shell within print quantization, floor 0.057 vs 0.05 (19g); production/`MRP_D1` = Table D-1 transcription (`no_verdict`); raw Ritz/`MRP_RITZ` calibrated guard — live **29/32** within 5 % at L = 1.83 m (I-22 re-record); **38g** printed App. D / `MRP_APPD`: **27/32** within 5 % → met (criterion ≥75 % of 32 fixed 2026-10-22; `mrp_appd_vs_d1.md`) |
| Coupling f'(n,r) | Implements CR-3813 Eq. (52) (shell and floor terms, no clamp; an out-of-range value raises an error); Table D-1 shapes for all 32 modes; its tests pass. No |f'| > 1 error occurred in the phase 17 runs |
| PAIN core, Eq. (8) (phase 17) | **Phase 17 done 2026-10-20**; phase 19 diagnostics done; **η_T = 0.5 adopted for Phase III** (author 2026-10-20, phase 20); **19i done 2026-10-21**: H3 modal breakdown at η_T = 0.5 (modes 15/25/17/21); omitted D-1 terms \|δ\| ≤ 0.057 **not found** as the H3 cause (`docs/validation_reports/h3_followup.md`). 18b-r: +3.7, +0.2, +9.1 dB (2 of 3 within 4 dB). Eq. (8) derivation and conservation closed in 19a–19b (`eq8_two_resonator.md`); other candidates ruled out in 19c–19h. `tone_mean_square_pressure` is Eq. (8) summed by Eq. (3); broadband HF: printed Eqs. (19)–(23) via `broadband_model=:eq19` (38c); default still surrogate. Baselines: `data/baselines/phase17_baselines.csv`. Trace: `docs/validation_reports/pain_core_eq8_phase17.md` |
| Phase 38 modules (2026-10-22) | `src/noise_reduction.jl` (Eqs. 17–18, E21_E22_NR: below-crossover 1/4 and 0/4, not met), `src/high_freq_tones.jl` (Eqs. 11–16, `tone_model`; I-18 rule not met, H3 +4.31 dB), `src/hf_broadband.jl` (Eqs. 19–23, T2_EQ19 0/3), E18_TONES (2/3, not met), E15_STRUCT_LOSS (info). **38f-1:** Manual cards 2/9/36 — `ρ_ext,c_ext,ρ_int,c_int`, cavity `L_c`/`d`, `rotation_direction` ±1; defaults bit-identical (`phase38f1_card_inputs.md`). **38f-2:** cards 3–6 user band set; cards 11–18 per-band `η_r_band` / `η_n_band` (`phase38f2_card_inputs.md`). **38h:** Manual §5.4.3 printed outputs — `src/printed_outputs.jl` + GUI tab + example `printed_outputs_REPRO_18b.md` (no comparison criterion). |
| Phase 29b/29c (2026-10-22) | Aircraft NASA-default guard + provenance tags: `src/aircraft_provenance.jl`; `cabin` JSON keys (plain or `{value,tag}`); `result.provenance.nasa_defaults` / `.inputs`; printed-outputs header + GUI status labels. Example `examples/aircraft_scale_hartzell_cabin_full.json`. Validation / `:e11` / `:synthetic` bit-identical. |
| Phase 30 (2026-10-22) | Parametric cabin blocks: `cabin_blocks=:parametric` (aircraft default) = App. D modes + Eqs. 19–23 (I-21 X-EXTRAP); `:surrogate` = Table D-1 + absorption/`bb_j2_scale`. Trim/App. D JSON keys; regression `parametric_regression.md` (shift record, no criterion). Validation/e11/synthetic bit-identical. |
| Phase 31 (2026-10-22) | Epistemic uncertainty budget (`src/uncertainty.jl`): OAT keep >3 dB, MC N=4000 seed 20261022. **31e `UNC_COVER` `:not_met`** — H1 P5/P50/P95 88.95/89.87/91.06 vs mean 90 (inside, +1.05 dB); H2 85.46/91.3/92.86 vs 80 (miss −5.46); H3 73.09/74.78/77.59 vs 65 (miss −8.09); kept `freq_scale`, `eta_t`. Aircraft band (kept `eta_n_bare`): H1 99.31/101.41/104.21, H2 58.47/59.07/59.94, H3 35.45/35.65/36.26 (MC unchanged after I-19); k=+0.094 after pair-convention fix; phase (i) spreads 0.36/0.46/0.22 dB — does not dominate H1–H3. Triangular narrower than uniform (~0.5–1 dB). Reports `uncertainty_budget_testarticle.md`, `uncertainty_aircraft_band.md`. Not a CI. |
| L = 1.83 m default (I-22, 2026-10-22, post-hoc) | `TEST_ARTICLE_L` / `test_article_length()` default **1.83 m** (App. D body / App. E; Table D-1 title 1.803 m = caption typo). Affected reports/baselines re-recorded; before/after: `docs/validation_reports/length_rerecord_before_after.md` (from `length_sensitivity.md`). **No verdict flips.** Criteria/reference unchanged; no length selected from any error. |
| Fig. E-11 SRC_TA | **Done** delta_dig <= 1 dB (repeatability of reading only) |
| **T1 tonal vs E-16** | At L = 1.83 m (I-22): 84.21, 77.66, 78.06 dB — H1 fail, H2 pass, H3 fail; **no claim**. GEXT importance bound: flat falloff and delay ×2 flip the T1 gate → **T1 depends on GEXT, not claimable** (`gext_importance_bound.md`) |
| **T2 1/3-oct vs E-9** | **Surrogate (default)** at L = 1.83 m: 55.92, 53.56, 51.59 dB (0/3); `bb_j2_scale` = 0.5 stale. **Printed Eq. (19) (`T2_EQ19`):** 38.56, 35.81, 34.87 dB — **0/3** within ±3.5 dB (`phase38c_hf_broadband.md`). **No claim** |
| **PAIN reproduction vs NASA (18b-r)** | **Not met, 1 of 3** at L = 1.83 m (I-22): 85.90, 78.35, 79.82 dB = +6.9, +2.8, +11.8 vs 79.0, 75.5, 68.0. Report `pain_reproduction_e16.md`; before/after `length_rerecord_before_after.md` |
| Trim / loss (phase 16, App. A + section 3.8) | **Done 2026-10-20.** Written from the printed equations, no fitted parameter: App. A transfer matrices (A.10)-(A.12), tau_t (A.22), C_w, beta (A.16), mechanical path (A.19)-(A.21), Phase III stacks; Si/Cin, joint acceptances (63)-(73), eta_n (77), eta_r (79)-(81), eta_r' (82), eta_r'' (83). Fig. A-2 digitized in `data/cr3813/fig_a2_pf105.csv`. Eq. (78) against NASA's calculated Fig. E-14 curves: **7 of 18 bands within +-25 %** at trim loss 0.5 and at 1.0 (criterion not met, recorded, not tuned); Fig. E-13 has no calculated curve. Printed-equation findings (factor 2 in Eqs. 69-70, the Eq. 82 limp-mass limit) in the [plan](docs/IMPLEMENTATION_PLAN.md). In the pipeline since 17a (2026-10-20). Report: `docs/validation_reports/trim_loss_e13_e14_e15.md` (`julia --project=. scripts/run/run_trim_loss_check.jl`) |
| CCBlade -> F1A | **Done** (phase 21 + **I-01/I-02 fix 2026-10-21**): all 160 points via `evaluate_propeller_source`, no GEXT; source span = 2 revolutions; phase referenced to absolute observer time. Table-8 peak calibration optional post-step (never compared to Table 8 when on — I-12/B-5). Class **X-EXTRAP** |
| Report 996 / Pereira / BBN | **I-07 re-runs done 2026-10-21** against §2.12 freeze. Smoke raw Table-8 peaks −4.2/−5.3/−5.8 dB. BBN 24b **PASS**; 24c 23a pre-registered **FAIL** 26/168; **I-19** post-hoc pair convention (CR-158919 §3.4/Table 8, 2026-10-22) → **134/168** still FAIL. Report 996: I-08 L51C27 scale on Fig.13a; 23c scaled pressure 5/24 within ±2 dB, page-12 phase **FAIL**. **Polar re-run 2026-10-22 (post-hoc):** 109 truncated XFOIL entries regenerated (1,420 points; 50 thin-section entries still short); R996_FIG12 21/40 (was 22/40), phase 109.0° (was 103.8°), other counts unchanged. Pereira 23d H1 0/9 within ±1.7 dB (Fig.9 H1=80 dB accepted as read). Loads still valid (phase 26 post-hoc label). **Display-only** `POLAR_R996` / `POLAR_PER`: XFOIL/Viterna polars + TN 1546 / Report 824 measured overlay + section Mach–α coverage (no criterion); `POLAR_R996` panel 4 colours TN 1546 / XFOIL by α |
| dB(A) / SIL | **Done**; `overall_dBA` energy-sums A-weighted 1/3-octave bands (**fixed C5, 2026-10-21**; was tones-only); **ISO_SIL** (40k) hand SIL ≤ 1e-9 dB |
| Phase 40 isolated analytics (2026-10-23) | **Done** V-UNIT: `ISO_BLOCKING`, `ISO_FF_CONV`, `ISO_GEXT_LINE`, `ISO_TABLE8`, `ISO_CYL2D_EXACT`, `ISO_JOINT_ACC`, `ISO_MODAL_DENSITY`, `ISO_BB_BAND`, `ISO_CYL2D_BOUNDARY`, `ISO_SIL` all **met**. **40i:** reference is the closed-form ∫ Spbl·2π df (α = 2 and 1.5); `blocked_broadband_band_p2` fixed to that integral (was Spbl(fc)·0.232·2π·fc rectangle; T2-path Δ ≈ −0.008 dB at α = 2, not re-recorded). **40f skipped:** Ritz cannot drop stringer/frame I via options (no `ISO_RITZ_DONNELL`). **40l:** `absorption_coefficient` noted as fitted `:surrogate` only |
| Phase 41 isolation of failing cases (2026-10-23) | **Done.** `TRIM_CLOSED`, `NR_BAND_HAND`, `HF_MASSLAW`, `BEMT_HAND`, `F1A_INDEP` **met**. `T1_FROM_E12` **not_met** 2/3 (H1–H3 = 81.66, 75.29, 77.89 vs T1 84.21, 77.66, 78.06) → cabin chain implicated. Where isolation passes, experimental misses labelled model fidelity (method), not code. Optional `use_tip_correction` on BEMT wrapper (default on). |
| Phase 42 loudest point (2026-10-23) | **Done (criteria fixed 2026-10-23).** Tone pressure at interior CYL2D nodes × 21 axial stations from the same Eq. (8) terms; overall dB(A) at the loudest point. Test article 79.1 dB(A) space average, 83.7 dB(A) loudest point (80.4 / 85.5 after 44f, post-hoc); aircraft example 93.8 / 98.4 dB(A) (X-EXTRAP). `LOUDEST_PT` **not_met**: the 1 % average check fails because the pre-registered point set excludes the wall nodes (0.83–0.94; all-node quadrature 0.99–1.03, post-hoc). |
| Closure register (2026-10-24) | `docs/VALIDATION_GUIDELINE.md` §2.14 lists every case that is not met with its cause class (method as printed, low-fidelity approximation, input/data, NASA output not explained by the documents, test design). **No open code defect.** |
| Phase 67 why the source cases miss (2026-10-24) | **Done.** Report: `docs/validation_reports/phase67_source_attribution.md`. `POLAR_FIDELITY` not met 9/60: XFOIL (forced transition) c_l is 0.15–0.35 below NACA TN 1546's measured c_l for the three exactly matching sections; the Report 996 BEMT thrust is 25–32 % below measured, consistent. `F1A_CHORDWISE`: spreading the load over the chord changes the near-field tones by ≤ 0.27 dB, so compactness is not the cause. The source misses are a limitation of the section polars, not of the code. **Withdrawn 2026-10-28:** the polar path has code defects (one section at every Report 996 station; CCBlade given μ = 1, so the lowest Re table was always used), plan Phase 69. |
| Phase 69 polar audit, loader fix and XFOIL rerun (2026-10-28) | **Done.** Per-station section polars, bilinear (log Re, M) lookup, Viterna past the converged angles, and μ in CCBlade (`src/polars.jl`, `src/propeller_ccblade.jl`). Report 996 polars rerun with free transition, N_crit 8 fitted to TN 1546 (`data/report996/polars_phase69_ncrit8.json`). Rerun, post-hoc: R996_LOADS 24/32 (was 6/32), R996_FIG12 28/40 (was 21/40), Pereira thrust +0.7 %. No case verdict changed. Steps: `docs/IMPLEMENTATION_PLAN.md` §8m; XFOIL inputs and outputs: `docs/METHODOLOGY.md` §2.4. |
| Phase 73 Report 996 section-polar fidelity (2026-10-28) | **Done. 73e decided 2026-10-28: TN 1546 c_d level not adopted** (chosen only after its effect on Report 996 torque was seen, so it could not count as a pass; production keeps XFOIL c_d; torque misses stay class A). Section c_l at the measured XFOIL − TN 1546 level moves thrust ≤ 7.9 % and the scaled-load levels ≤ 0.19 dB: not the cause. XFOIL c_d is about 25 % below TN 1546 and accounts for about half the torque gap (`docs/validation_reports/phase73_polar_sensitivity.md`). |
| Phase 76 thickness noise in the experimental source comparisons (2026-10-28) | **Done.** The Report 996 and Pereira measurements contain thickness noise; the runs were loading-only. Thickness term on, A/c² per station from the section coordinates (no fitting). Post-hoc: R996_FIG14 met 24/24 (was 14/24), R996_FIG12 met 32/40 (was 13/40), PER_FIG7 met 3/3; totals 44 met, 42 not met. |
| Phases 97–98 (2026-10-30) | **Done (diagnostics, no code change).** Tracing PF-105's attenuation in Fig. A-2 between its marked points failed its QA; the structural loss factor η_r′ is 1.4–2.1× low in its trim term above 470 Hz, and masses, band centre, an included coupling loss and Eq. (A.8) variants are ruled out. Likely cause: PF-105 properties not readable from the figure. |
| Phases 95–96 (2026-10-30) | **Done.** NASA's cabin-mode damping η_n is Eq. (77) at the nominal 1/3-octave centre holding each mode, for ω and the trim conductance (read from App. B: 45/46 modes with NASA's admittance); now the default (`η_n_band_omega`). Held out: APPB_ETA_N_T2_BAND met 3/3, R172428_ETAT2 still met 9/9. Remaining η_n gap (up to 29 % at 188–218 Hz) is this code's trim conductance at the 200 Hz resonance. |
| Phases 93–94 (2026-10-29) | **Done.** Defaults are now NASA's latest program (CR-172428, September 1984): App. A Eq. (82), q = 0 cabin modes uncoupled, η_n per cabin mode in the tone paths (the noise-reduction path keeps η_n at the band centre). Held-out test on NASA's η_T = 2.0 run (Table 12): R172428_ETAT2 met 9/9 within ±3 dB (largest 1.7 dB), APPB_ETA_N_T2 met 3/3. `_pre_correction_form` / `_cr3813_tone_form` give the older forms. T1_F1A_FILL is now not met (3/6). |
| Phase 92 (2026-10-29) | **Done (diagnostics).** This code's Eq. (8) mode pairs against NASA's printed largest contributors (APPB_PAIRS): NASA's run behaves as if the q = 0 cabin modes add nothing and η_n belongs to each mode; with both, the nine CR-172428 levels are within ±2.4 dB (post-hoc). The held-out q = 0 test missed by 0.09 dB. No verdict; Phase 93 made both the default. |
| Phase 91 notebooks (2026-10-29) | **Done.** Two Pluto notebooks in `notebooks/`: the program step by step on the test article, and how to read a validation case. How to open and check them: `notebooks/README.md`. |
| Phase 90 (2026-10-29) | **Done.** Eq. (43) blocking against a measurement for the first time: NACA Report 996 Fig. 10 flat wall, R996_FIG10_FLAT met 5/5 within ±1.5 dB; circular wall shown as information. |
| Phases 87–89 (2026-10-29) | **Done.** NASA's App. B per-mode values: ε_n met 48/48, η_n not met 11/46, η_r″ not met 8/19 (`APPB_*`, on the map). The q = 0 hypothesis refuted on CR-3813's runs (2/3, 1/3, 1/4); η_n per mode (`η_n_per_mode`) 5/9 on CR-172428, not adopted. Diagnostics listed in `docs/NO_VERDICT_CASES.md`. |
| Phase 86 map and plan reorganisation (2026-10-29) | **Done.** The validation map (`docs/VALIDATION_GUIDELINE.md` §0, GUI Validation map tab) shows only the 41 cases with a verdict (8 met, 33 not met); the 76 without one, including eight diagnostic re-runs, are listed in `docs/NO_VERDICT_CASES.md`. Completed phases moved from `docs/IMPLEMENTATION_PLAN.md` to `docs/COMPLETED_PHASES.md`. |
| Phase 85 met-case audit (2026-10-29) | **Done.** The meaningfulness rule applied to the 47 met cases (`VALIDATION_GUIDELINE.md` §2.18): 5 compare with measurement and 3 reproduce PAIN printouts (BLK_P68, MRP_APPD, CYL2D_C1) and keep met; 39 verification checks are information cases (no verdict, outcome kept, still asserted by the tests). Error-panel x labels of five Phase 66 cases corrected. |
| Phase 84 next-tier audit (2026-10-29) | **Done.** Not-met cases with at most a third of their points (`VALIDATION_GUIDELINE.md` §2.17). NASA's mode counts (CR-172428 Table 6) were the one untested input: our acoustic list already equals NASA's printed one, and the 300 structural modes give R172428_CODE_DECK 4/9, R172428_EXP_DECK 3/9 and E21_PRE_DECK 1/4, the same counts as the 32-mode runs. Refuted; production keeps Table D-1. |
| Phase 83 fewest-points audit (2026-10-29) | **Done.** The nine 0-point not-met cases audited (`VALIDATION_GUIDELINE.md` §2.16). The one untested cause, Table D-1's 32 modes in the high-frequency path, was run with NASA's 300 MRP-deck modes against the original criteria: E22_HF_DECK 0/4, T2_EQ19_DECK 0/3, REPRO_18b_DECK 0/3. It is refuted and production keeps Table D-1. T2 (fitted to the E-9 data it is compared with) is an information case. UNC_COVER's H3 excess is re-stated as PAIN's: without GEXT the code matches NASA's H3 within 0.4 dB. |
| Phase 82 meaningfulness audit (2026-10-29) | **Done.** Rule (author, also in `CLAUDE.md`): a case carries a verdict only if it compares with measurement or reproduces what PAIN printed from PAIN's own inputs. Of the 43 not-met cases, 26 compare with measurement and 10 with PAIN's printed output (kept); 7 compare with something else and are information cases now (LOUDEST_PT, BLK_GAIN_MAP, MRP_SHAPE_NORM, CYL2D_WEYL, MRP_COUPLED_LIMITS, F1A_GUTIN_ANGLES, SHARP_PANEL_D; no verdict, outcome kept, not a pass). 82c: NASA's full MRP-deck modes in the CR-172428 reproduction change nothing (R172428_ETA 17/32, levels < 1 dB), so truncation is not the cause; masses, trim admittance and the App. A program changes match NASA, and R172428_ETA is re-classed N. `VALIDATION_GUIDELINE.md` §2.15. |
| Q60 CYL2D for other floors; Q62 validation status at a glance (2026-10-29) | **Done.** Production CYL2D uses the next solvable grid when NY = 10 has no App. C solution for the floor angle (`cyl2d_modes_solvable`, Q60, 2026-10-29): NY = 10 is unchanged for θ0 = 56.6°; for θ0 = 45.3° (the 2.64 m example × 0.8) NY 10 and 11 give complex eigenvalues among the 20 kept modes and NY = 12 is used, with a warning. Over θ0 = 30°–80° the first solvable grid from NY 10 is within 3.3–6.6 % of NY = 60 (θ0 = 56.6°, NY 10: 4.9 %), so the fallback grid has the same discretization error class as the paper's; information, no criterion (probe 2026-10-29). `VALIDATION_GUIDELINE.md` now opens with §0: the validation map as a Mermaid flowchart coloured by verdicts, group totals, the not-met cases with the fewest points first, and per group every case with its verdict and points (generated by `write_validation_scoreboard`, rerun by `write_case_error_summary.jl`). |
| Phase 81 PAIN main block (2026-10-29) | **Done.** ISO_MODAL_DENSITY: 2 rows had passed at the 1e-6 joint-acceptance floor (both sides clamped); with a band-matched pressure every band is above the floor, met 12/12 (post-hoc). HF_MASSLAW: info row out of the chip. SHARP_PANEL_D: class N (the figure lies 10.2 dB over its mass line, the text and Eq. (25) with the Fig. A-7 lattice give about 12 dB); new SHARP_PANEL_D_SHAPE met 3/3. LOUDEST_PT: new LOUDEST_PT_GRID met 3/3, the all-node average equals Eq. (8) within 0.07 % at NY = 40; check (a) stays not met (test design). Display: information rows are grey in every error panel (were green); `regenerate_case_figures.jl` re-reads the case records before drawing (it used the precompiled copy, which put new cases' figures in the figures root). |
| Phase 80 MRP validation (2026-10-29) | **Done.** NASA's own MRP input deck for the test article is printed in the User Manual (pp. 42–43); read by `appd_nasa_deck()` (`data/cr3813/um_mrp_input_deck.csv`). On it the App. D solver reproduces Table D-1: **MRP_APPD met, 32/32**, frequencies within 0.012 %, shapes in Table D-1's order, generalized masses median 0.11 % (was 2/32 on inputs derived from App. E sections). Needed for that: NASA's floor form (no cross terms between floor terms; `floor_cross_terms=true` gives the exact Ritz energy), M_r as the full integral, shapes normalized over the whole shell. New cases: `MRP_COUPLED_LIMITS` (not met 66/78: NASA's floor form puts floor modes 2–3 of the near-rigid-shell limit 50–78 % low, class M) and `MRP_TRUNC` (met 32/32; the printed 5 + 3 terms reproduce MRP_SHAPE_NORM's peaks). Default series M 1–10, ns 0–12, np 0–5 (NASA's deck); np > 8 refused. A new fuselage may give PAIN's card values (`t_shell_card_m`, `m_shell_kg_m2`, `Dp_stringers_Nm`, `Dp_frames_Nm`, `t_floor_card_m`, `m_floor_kg_m2`, `Dp_floor_beams_Nm`, `Dp_floor_supports_Nm` in `cabin`); input warnings for thin-shell and smearing limits. Sensitivity report `phase80_mrp_sensitivity.md`. Knock-on: UNC_COVER 0/3 (margins −3.67, −6.84, −12.88 dB). |
| Phase 79 CYL2D (2026-10-28) | **Done. Production NY = 10 kept (decided 2026-10-28):** App. C prints NY = 10, CYL2D_C1 reproduces NASA there 59/59, and the ≤ 4.9 % grid error is a stated limitation. 79c: new case CYL2D_GRID_CONV (no verdict): the paper's NY = 10 grid is at most 4.9 % from a converged NY = 60 grid. 79d: CYL2D_WEYL against Weyl with the surface term (post-hoc) is 4/5, and the converged grid matches within 6 %, so the 1500 Hz excess is the NY = 10 grid. 79b: the App. C matrix is non-symmetric at the curved wall, so refined grids have complex pairs high in the spectrum; only the kept modes now have to be real, so the floored section refines (NY 40–60 agree within 0.3 %; the paper's NY = 10 is up to 4.1 % high on mode 2), production unchanged. Information rows (labelled "(info") now stay in the table and figure but leave the map chip count: ISO_CYL2D_EXACT reads 11/11 like its verdict (was 12/21), T1_FROM_E12 1/3 (was 7/9). Planned: locate the App. C stencil asymmetry that prevents refining the floored grid (79b), a converged-reference case CYL2D_GRID_CONV with its own figure (79c), Weyl with the surface term (79d). |
| Phase 78 structural modes (2026-10-28) | **Done; MRP_APPD recorded not met (2/32).** 78d-4 found six code-consistency defects in the App. D solver from Fig. D-1 and pp. D-1–D-4 and fixed them (returned shapes in App. D's convention, θ from the top and floor upward; shell over the whole circumference, since the test article is a closed cylinder with an interior floor; spurious n = 0 modes; a frequency dedup that dropped modes; antisymmetric floor sway; floor membrane shear coupling). MRP_APPD stays 2/32 (10 shape partners, was 7): the symmetric floor modes match in shape but not frequency and most antisymmetric modes have no partner; how the floor beams act is not documented in App. D, so the gap is recorded as an input limitation. Knock-on: UNC_COVER 0/3 (margins −4.06, −5.41, −13.23 dB; was 1/3). 78e: the seven MRP_SHAPE_NORM excesses are in the printed table (transcription checked twice). 78f: MRP_D1 and MRP_RITZ are off the map (kept as registered checks and unit tests). Earlier: MRP_APPD pairs by shape (MAC ≥ 0.9) with the floor beams about the floor mid-plane; 78d corrected the stiffener inertias and made the floor orthotropic; the old 27/32 came from frequency-only matching (`docs/IMPLEMENTATION_PLAN.md` §8v). |
| Phase 77 POLAR_FIDELITY as an equivalent angle (2026-10-28) | **Done.** The figure adds one panel per section with the XFOIL − TN 1546 offset as an equivalent angle of attack, Δα = Δc_l/(2π/√(1−M²)) (display only; criterion Δc_l ≤ 0.05 unchanged, which is 0.42° at M 0.4 and 0.32° at M 0.72). No percentage: near zero lift it grows without bound. |
| Phase 75 stale validation figures (2026-10-28) | **Done.** `scripts/run/regenerate_case_figures.jl <ids>` reruns cases offscreen, saves their figures through the GUI's `plot_case` and updates only their rows of `case_error_summary.csv`; selecting a case whose saved figure is older than its recorded result says so in the status line ("press Run to redraw it"). Each phase that re-records a case regenerates its figure. |
| Phase 74 Pereira PER_FIG8 / PER_FIG9 (2026-10-28) | **74a–74c done.** Fig. 9 re-read exactly from the PDF vector graphics: the old H1 = 80 dB was a misreading; Fig. 9 now equals Fig. 8 within 0.1 dB, and PER_FIG9 H1 is 9/9 (was 0/9). Remaining H2 misses at φ = −20°, +20°, +30° are the size of Pereira's own CFD misses (class N). |
| Phase 72 observer fore/aft convention (2026-10-28) | **Done.** AcousticAnalogies' +X is ahead of the propeller; the Report 996 scripts (`x_sign = −1`) and the Pereira script (x = +sin φ) had their microphones on the wrong side of the plane, and the Pereira Fig. 7 phase had the opposite sign. Now `R996_X_SIGN` and `pereira_observers` (`src/propeller_ccblade.jl`). Rerun, post-hoc: R996_FIG13A met 14/14 (was 8/14), R996_FIG12 13/40 (was 28/40), R996_FIG14 14/24 (was met), PER_FIG8 H1 5/7. Plan §8p. |
| Phase 71 audit of the remaining map blocks (2026-10-28) | **Done.** z_p fixed in four report scripts and the reports regenerated; CYL2D_WEYL reclassed (D, M); E-12 asymmetry (A3b): with NASA's E-11 and E-12 predicted lines read from pixels, Eq. (43) matches NASA's step within ±1.5 dB at H1/H2, so no term is missing; the earlier fore/aft pattern was the by-eye E-12 digitization (`docs/validation_reports/e12_a3b_linefit.md`). |
| Phase 70 free-field block audit (2026-10-28) | **Done** (F1–F4, F7 applied; SRC_PASSTHROUGH aircraft row met 3/3; PROP_BB_* rerun, still not met). Findings F1–F7 in `docs/IMPLEMENTATION_PLAN.md` §8n (FF_E11_MAP passes by construction; ISO_TABLE8 tests the identity only; PROP_BB_* placement and polar inputs). |
| Phase 66 BEMT / F1A code checks (2026-10-24) | **Done.** Report: `docs/validation_reports/phase66_bemt_f1a.md`. Seven of eight met: momentum = blade element at every station (1e-11), hand BEM with tip loss/drag/nonlinear polar (5 digits, after a fix of the hand reference), integrals and Froude bound, similarity, Garrick–Watkins in flight (0.07 dB), thickness noise (0.002 dB), blade-count/1/r/convergence. Not met: `F1A_GUTIN_ANGLES` 4/5 (levels within 0.26 dB at all angles; the θ = 60° phase is a near-null, 14.6° off at 100 R_tip, 3.7° at 400 R_tip). CCBlade and AcousticAnalogies unchanged; the checks target how this project uses them. |
| Phases 62–65 (2026-10-23/24) | **Done.** Report: `docs/validation_reports/phase62_65_map_blocks_grid.md`.
- **65 (grid axial direction):** the grid now follows the User Manual (pp. 8–9) and CR-3813 App. E (p. E-8): z_k = z_p − (πa/18)(k_p − k), with z_p = 0.662 m for the test article. The code had the grid mirrored about the propeller plane and z_p = 0.90 m (no source). Re-recorded values are labelled "grid axial correction 2026-10-23 (code vs User Manual p. 9 / App. E p. E-8; not a fit)"; REPRO_18b moves to 88.20, 80.43, 78.21 dB and T1 to 86.59, 80.02, 76.39 dB; no verdict changes. The aircraft working example (diameter 2.64 m, assumed cabin length 1.83 m) has half its grid off the cabin; the run now warns (Q45, closed: a demonstration input, not used by any validation case).
- **62 (map coverage):** every block of the Validation map now has a runnable case with its own figure; 12 new cases (`F1A_PLANE_PEAK` … `AC_CABIN_DEMO`), 9 met, 3 not met (`BLK_GAIN_MAP`: R1 goes negative behind the cylinder; `MRP_SHAPE_NORM`: Table D-1 shapes peak up to 1.245; `CYL2D_WEYL`: the App. C grid at NY = 10 over-counts modes above kh ≈ 1).
- **63:** the structural mode animates with the acoustic frames in the Cabin modes tab.
- **64:** `PAIN.jl/test/unit/`: one test file per source module, every function in `src/` named (a completeness test fails otherwise). The tests found and fixed: the Gutin reference of `F1A_GUTIN` (low by √2·M; F1A now agrees with the exact annulus-by-annulus Gutin within 0.03 dB), `PropellerPlacement` accepting a rotation sense other than ±1, string band keys in loss-factor cards, Dict-shaped aircraft cabins losing their symbol/bool fields, the empty-band return of `tone_expected_value` missing fields, the noise-reduction dummy grid with swapped axes (unused by Eq. 18), a Float32-literal slip in an independent quadrature (no caller), and Phase 62 reason texts that read as a pass on failing cases (eight in all).
- The GUI Run tab now refuses the e11/synthetic sources: they verify PAIN and run as Validation-tab cases. |
| T2 high-frequency gap: a limitation of the method (2026-10-23) | NASA's printed PAIN noise reduction for the CR-3813 article (E-22) exceeds the measurement by 32–44 dB at 1250–2500 Hz.
- The code reproduces NASA's corrected program (CR-172428) closely.
- Against CR-3813's printed runs it is within 2–8 dB at high frequency. Phase 61 shows the remaining differences are not explained by the documents; NASA's floor-sign correction does not account for them.
- The T2 gap is recorded as a limitation of PAIN's high-frequency trim model, within that stated difference, not a code defect (`docs/validation_reports/phase61_cr3813_reproduction.md`). |
| Phases 59–60 (2026-10-23) | **Closed.** Report: `docs/validation_reports/phase59_60_bridges_modes.md`.
- **59:** Sharp's sound-bridge model, from NASA CR-172490 (found on NTRS), is added as an option.
  - With the documented connections it closes about 7 dB of T2's roughly 30 dB high-frequency gap: the T2 interior at 1250 Hz moves from 21.6 to 28.4 dB, against 51.0 dB.
  - The source check `SHARP_PANEL_D` is 3/13 (the source's own ΔTL_M is ambiguous).
- **60:** the App. D mode extension above 811 Hz fails its consistency check and is not adopted. |
| Phases 50–58 (2026-10-23) | **Closed.** Report: `docs/validation_reports/phase50_58_closeout.md`.
- **50:** propeller-field coupling moves the 315–800 Hz NR to within −3…+7 dB (from 18–26 dB low); `NR_PROP_TP2444_PF` 2/7.
- **51:** not run (no verifiable official-source bridge model).
- **52:** T1's H3 excess is the e11 off-line field, not the cabin.
- **53:** negative NR is a property of the equation; `sparse_guard` option added.
- **54:** Q22 closed.
- **55:** surrogate stays, labelled calibrated.
- **56:** the Ritz solver is not Donnell–Mushtari (40f not met).
- **57:** tests added for the never-executed functions.
- **58:** leftovers done. |
| Phase 48 exterior broadband from RP-1218 (2026-10-23) | **Done.**
- `BPM_RP1218` met: NASA's airfoil self-noise code is ported and reproduces its printed output, 270/270 points within 1 dB.
- The propeller broadband prediction (assumed blade) is 3–15 dB below the measured floors: `PROP_BB_FIG14` 3/9, `PROP_BB_FIG17` 2/7.
- `T2_PRED_BB` not met, because of the cabin path.
- Report: `docs/validation_reports/phase48_exterior_broadband.md`. |
| Phase 49 trim and high-frequency inputs (2026-10-23) | **Done.**
- τ_t hand check met.
- No measured trim transmission loss exists in the documents. NASA states the trim model over-estimates the sidewall treatment and is valid to about 1 kHz.
- Eq. (20) now sums the modes below the band, as printed (effect ≤ 0.3 dB).
- No input correction closes T2's gap.
- Report: `docs/validation_reports/phase49_trim_hf_inputs.md`. |
| Phase 47 T2 with the measured TP-2444 exterior (2026-10-23) | **Not met** (criteria fixed before the run).
- TP-2444 Fig. 17 (this article, 4000 rpm) is digitized into `data/tp2444/`; CR-172428 Fig. 14 into `data/cr172428/`.
- `NR_PROP_TP2444` 1/7: measured NR 30–36 dB; the model gives 5–17 dB below 1 kHz and 49 dB at 1260 Hz.
- `T2_MEAS_EXT`: the measured exterior gives 21.3 dB inside against E-9's 51.0 dB.
- The measurements agree with each other. PAIN's printed high-frequency noise reduction is the gap, and NASA's own E-21/E-22 predictions show it too.
- Report: `docs/validation_reports/t2_measured_exterior.md`. |
| Phase 46 isolated checks (2026-10-23) | **Done.** Isolated checks for the five T1/T2 functions that had none (`broadband_cabin_p2`, `tone_expected_value`, `hf_structural_band`, `hf_band_loss_factors`, `coupling_loss_factor_21`) and for the T1/T2-path functions the coverage run never executed: 37/37 met. |
| Phase 45 T2 HF path on TP-1964 (2026-10-23) | **Done (pre-registered 2026-10-23).** `NR_TP1964_XOVER` **not_met** 9/18 (Eq. (18) below the 2500 Hz changeover band, Eqs. (19)–(23) above); the four Eq. (19) bands agree within ±2.5 dB of measured. T2's exterior input remains unmeasured. |
| Phase 44f floor-term sign (2026-10-23) | **Done (code-on-code fix; results after it post-hoc).** NASA's printed η_r″ (App. B p. 207) implies the bare coupling |I_s + I_p| for 8 of 9 pairs (within 2.5 %); App. A records the MRP sign misreading in this term. Eq. (52) floor term now enters with a plus on the raw Table D-1 coefficients. T1 87.36 / 81.02 / 75.23 dB (H1, H2 inside, H3 +10 dB); **T1_F1A_FILL met 3/3, post-hoc**; R172428_CODE 4/9, R172428_EXP 3/9; 12 of NASA's 15 printed pairs within ±3.7 dB. Open: (0,1) × mode 8 at H1 (Q22). |
| Phase 44 CR-172428 reproduction (2026-10-23) | **Done except open item 44f (criteria fixed 2026-10-23, unchanged).** NASA's printed App. B blocked field (9 pages, 16 × 19, H1–H3, 3000/4000/5000 rpm), mode lists, trim and predictions transcribed to `data/cr172428/`. App. A η_r′ correction (`η_r_trimmed_area`) implemented. Code fix found on the way: Eq. (83) uses the bare f′ (T1 now 84.24, 77.63, 77.80 dB; baselines re-recorded). `R172428_CODE` **not_met** 3/9 within ±3 dB of NASA's printed predictions; `R172428_EXP` **not_met** 1/9 (NASA's own 5/9); `R172428_ETA` **not_met** 17/32; `R172428_TRIM` / `R172428_PAIRS` diagnostics. NASA's own PAIN misses T1's H3 by +6.1 dB. |
| Phase 43 T1/T2 root causes + TP-1964 (2026-10-23) | **Done (criteria fixed 2026-10-23, unchanged).** **43a:** Manual card 10 volume crossover default (f ≈ 1299.6 Hz → band 1260 Hz); ten-mode rule kept as option; `:auto` post-hoc re-runs (old kept). **43b** `T1_MEAS_DAMPING` **not_met** 2/3 (93.78, 80.06, 79.41). **43c** H3 attribution diagnostic (`h3_attribution.md`). **43d** `NR_TP1964` **not_met** 6/18; `NR_TP1964_REF2` **not_met** 6/18 (after the same-day mode-window fix; first run 5/18 and 4/18 with NR = +Inf at 100–160 Hz). **43e:** no measured exterior broadband found → T2 Not covered + NR_TP1964 as HF path. **43f** `T1_F1A_FILL` **not_met** 2/3 (79.61, 71.19, 71.30); diagnostic F1A+meas damp 90.00, 73.46, 72.60. |

**Status after phase 44 (2026-10-23) / 43–31:** Phase 44 `R172428_*` cases on the Validation map (criteria fixed 2026-10-23). Prior: Phase 43; Phase 41 isolation; Phase 40 `ISO_*`; `E18_TONES` / `E15_STRUCT_LOSS` / `MRP_APPD`; **29b/29c** guard + provenance; **Phase 30** `:parametric`; **Phase 31** 31e `:not_met`.

Source-block data: Report 996 in `data/report996/`; Pereira in `data/pereira/`; CR-3813 test-article CSVs and pages in `data/cr3813/` (see `data/README.md`); TP-1964 bare-cylinder NR in `data/tp1964/`; BBN phase Figs. 18–20 in `data/NASA_CR-159124/`. Scripts live under `PAIN.jl/scripts/{run,checks,digitize,setup,smoke}/` (`scripts/README.md`). Details in the [plan](docs/IMPLEMENTATION_PLAN.md).

The cabin path checked against NASA data is: digitized Fig. E-11 -> GEXT -> blocking R2 -> hybrid Table D-1 MRP + CYL2D -> PAIN core.
T1 and T2 are recorded results of the untuned CR-3813 chain (T2 keeps one stale fitted parameter, `bb_j2_scale`), not independent validation; which test proves what, and which parameters were fitted,
is in [`docs/VALIDATION_GUIDELINE.md`](docs/VALIDATION_GUIDELINE.md) section 2.10. The aircraft path is not validated against measurements.

## Running it (Windows PowerShell)

Open **PowerShell** (not the Julia prompt). Run the commands **one block at a time**, and wait for each to finish
before pasting the next. Lines starting with `#` are comments, not commands.

### Step 0 - Check that Julia is installed

```powershell
Get-Command julia
```

- If it prints a table with `julia.exe` and a path, Julia is installed. Go to Step 1. (A Microsoft Store / winget install puts
  it at `C:\Users\<you>\AppData\Local\Microsoft\WindowsApps\julia.exe`, which is on PATH; that is the expected result.)
- If it says `The term 'julia' is not recognized`, Julia is not installed (or not on your PATH). Install it:

  ```powershell
  winget install julia -s msstore
  ```

  Then **close PowerShell and open a new one**, and run `Get-Command julia` again. The old README pointed at
  `%LOCALAPPDATA%\Programs\Julia-1.13.1\bin\julia.exe`; that path only exists if you installed that exact version there.
- If Julia is installed but `Get-Command julia` still fails, find it with this and note the path it prints:

  ```powershell
  Get-ChildItem "$env:LOCALAPPDATA", "$env:ProgramFiles" -Recurse -Filter julia.exe -ErrorAction SilentlyContinue | Select-Object -First 5 FullName
  ```

  Then tell PowerShell where it is, using your path in place of `C:\path\to\julia.exe`. This lasts until you close
  that PowerShell window, and lets every command below work unchanged:

  ```powershell
  function julia { & "C:\path\to\julia.exe" @args }
  ```

Check that it works (this should print a version number):

```powershell
julia --version
```

The lock file was made with Julia 1.13.1. Another version still works but may re-resolve packages.

### Step 1 - Go to the project folder

```powershell
cd C:\Users\FrancisHoang\git\PAIN\rea-work\PAIN.jl
```

Do not run these from `git\PAIN` or `rea-work`; there is a separate `Project.toml` in `git\PAIN` that is not this project.

### Step 2 - Install the Julia packages (first time only)

```powershell
julia --project=. -e "using Pkg; Pkg.instantiate()"
```

This downloads and compiles many packages (including Qt for the GUI), so it can take several minutes and needs internet.
It is done when the PowerShell prompt returns without an `ERROR`.

### Step 3 - Run the tests

```powershell
julia --project=. -e "using Pkg; Pkg.test()"
```

Expected: a test summary ending with all tests passed. The suite writes reports and figures only under a temp dir (`TEST_OUT`), so it leaves the git tree clean. The last top-level testsets are the unit tests of `PAIN.jl/test/unit/` (one per source module, titles `Unit tests: <module>`; Phase 64).

To run only some top-level testsets (substring match on the title, case-insensitive):

```powershell
julia --project=. -e "using Pkg; Pkg.test(`"PAIN`"; test_args=[`"CYL2D`", `"Validation case registry`"])"
```

Titles and typical times: [`PAIN.jl/test/README.md`](PAIN.jl/test/README.md). Optional persistent Julia (DaemonMode, own env under `PAIN.jl/scripts/devtools/`): [`PAIN.jl/scripts/devtools/README.md`](PAIN.jl/scripts/devtools/README.md). No change to assertions or `src/` (task P1, 2026-10-22).

### Step 4 - Run the full pipeline and validation checks

```powershell
julia --project=. scripts/run/run_pain.jl
```

Prints the interior tone levels, the T1/T2 checks, and a summary of PASS/FAIL lines. It writes reports to
`docs\validation_reports\`. It ends with an error message if any check fails; read the summary above it.

### Step 5 - Run the CCBlade + F1A smoke test (aircraft source)

```powershell
julia --project=. scripts/run/run_f1a_smoke.jl
```

Compares the propeller noise on the l = 1 line with ANOPP Table 8 and writes `docs\validation_reports\ccblade_f1a_smoke.md`.

### Step 6 - Open the GUI (optional)

```powershell
julia --project=. scripts/run_gui.jl
```

Tabs (phases 34–36, 38h). Cases are read-only: fixed inputs and criteria; not a calibration tool (CLAUDE.md).

**Run tab:** source = `aircraft` only (BEMT + F1A; needs an aircraft JSON, e.g. `examples\aircraft_scale_hartzell.json`). `e11` / `synthetic` stay for scripts and `Pkg.test()`, not the GUI.

**Validation tab:** list ordered by validation map and block. Pick a case → **Run** (or **Run all**). Selection updates Julia `val_selected` / `val_runnable`. Inputs are an echo; criterion text/date and verdict are fixed. Comparison plot (with error panel; grey points and no tolerance band for a no-verdict case; optional `error_xlabel` when that panel's x differs from the main panel, e.g. `UT_GRID`) → `docs/validation_reports/figures/<block folder>/<case_id>.png`, one folder per validation-map block (e.g. `F1A_amplitude/R996_FIG14.png`, `Forward_flight/PER_FIG7.png`). Until Run: "Press Run to draw the comparison plot". **E21_E22_NR** (38a), **E18_TONES** (38d), **E15_STRUCT_LOSS** (38e) runnable; long source cases replay recorded CSVs. **POLAR_R996** / **POLAR_PER** are display-only (`:no_verdict`) polar and coverage plots on Aircraft inputs (measured airfoil overlays from `data/airfoil_measured/` are display only).

**Validation map tab:** one horizontal `total` flowchart (aircraft BEMT+F1A + e11 free field + grid/blocking + modes + PAIN main + checks). Stage group frames bound each stage's own blocks only (aircraft checks above/below the BEMT→F1A chain; Free field in the next columns so frames do not overlap). Each map row is as tall as its tallest block with its chips (`validation_map_row_y`, one full-width chip per line), so no block or chip covers another (fixed 2026-10-28; checked block by block in `assert_validation_map_groups_disjoint`). Solid **Feeds** arrows and dotted branches to case chips. Each chip shows a short display-only error line plus a tiny source date (`k/n · X U max` or `no verdict · X U max`; full text in the detail panel; absolute units from the last `(...)` in `error_ylabel`/`ylabel`; `:none`+met/not_met → `n/n within criterion`; snapshot in `docs/validation_reports/case_error_summary.csv`). Scroll horizontally and vertically (Shift+wheel sideways; Ctrl+wheel zoom; Fit). Click a block for what_it_does / code; click a chip for case detail → **Run** / **Open report**. Layout and copy from [`VALIDATION_GUIDELINE.md` §2.13](docs/VALIDATION_GUIDELINE.md) (`Position` / `Feeds` / `Group` / `Role`). Offscreen smoke shots: `VALIDATION_MAP_TOTAL.png` (left, zoom 1) and `VALIDATION_MAP_TOTAL_right.png`. `UT_GRID` is a runnable unit test with a γ-coloured 160-point grid figure.

**Cabin modes tab (phase 36):** own tab (cheaper than embedding in the Validation map `CYL2D_C1` detail). Mode 0–19, axial q, play/pause/speed, Refresh. Shows f, Φ_G, symmetry; for modes 0–5 the printed Fig. C-3 one-decimal values; optional Table D-1 structural ψ and f′. Fixed `CYL2D_C1` inputs (c0, θ0, NY) — not editable. **Display only — no criterion, no verdict, no tuning**; frames are interpolated for drawing (node values unchanged). PNGs/GIFs under `PAIN.jl/gui/cache/mode_anim/` (not validation figures).

## Using PAIN from the Julia prompt (optional)

This is a different place from PowerShell. In PowerShell, type this to open the Julia prompt (it shows `julia>`):

```powershell
julia --project=.
```

Then paste the lines below at the `julia>` prompt. They are Julia code and will fail in PowerShell. Type `exit()` to leave.

```julia
using PAIN
r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
evaluate_T1(r.spectrum)   # expect PASS
evaluate_T2(r.spectrum)   # expect PASS (1.25-2 kHz)
```

## If something fails

| What you see | What to do |
|--------------|------------|
| `The term 'julia' is not recognized` | Go back to Step 0. |
| `Project.toml` not found, or a package is missing | You are in the wrong folder. Run Step 1 again. |
| Error while installing `QML` / Qt | Copy the first `ERROR` line and report it. The GUI is optional, but the install must finish for the other commands. |
| `run_pain.jl` ends with "one or more validation gates failed" | The pipeline ran, but a check did not pass. Read the PASS/FAIL summary just above that line. |
