# Block validation audit (2026-10-23)

Author request: every code block of the pipeline gets its own validation case that tests it **in isolation** (its inputs supplied by the test, its output compared with an independent reference), so that a miss at the end of the chain can be attributed to one block instead of to a chain of unknowns; failing experimental cases get an isolation test that shows the function works as intended (a remaining experimental miss is then model fidelity, not a code error); and the final level is reported as dB(A) at the loudest interior point.

Method: read-only inventory of every physics function in `PAIN.jl/src` (geometry, blocking, grid extension, free-field conversion, propeller source, polars, CYL2D, MRP/App. D, trim and loss, PAIN core, noise reduction, high-frequency tones and broadband, metrics), mapped to its unit testsets and validation cases. Status classes:

- **VERIFIED**: an isolated test against an analytic result or an independent source passes.
- **PASS-EXP**: an isolated experimental check passes.
- **FAIL**: the case that exercises it is not met.
- **INCONCLUSIVE**: no verdict, display only, or the only reference is from the same report (NASA's own table or calculation).
- **NONE**: exercised only through the end-to-end chain.

## Status by block

| Block | Functions | Status | Gap |
|-------|-----------|--------|-----|
| Grid and incidence | `grid_points`, `incidence_angle_deg` | VERIFIED (UT_GRID 28/28) | none |
| Blocking Eq. (43) | `blocking_factor`, `delta_L_blocking_dB`, `blocked_amplitude` | VERIFIED (BLK_P68 6/6) | `apply_blocking` on the full grid only through the chain |
| Grid extension (GEXT) | `extend_line_to_grid` | INCONCLUSIVE (V-ASSUMED) | on-line identity testable; off-line field has no reference |
| Free-field input | `spl_dB_to_Pa`, `spl_dB_to_peak_Pa`, `peak_Pa_to_spl_dB`, `freefield_from_e11_csv`, `apply_table8_calibration` | NONE / INCONCLUSIVE | conversions and loader not tested on their own |
| Propeller source (F1A) | `evaluate_propeller_source`, `f1a_gutin_h1_comparison`, conversions | VERIFIED (Gutin, kinematic phase); FAIL (Report 996 Figs. 12/13a, phase; BBN_CIRC; Pereira) | no independent near-field check with the same loads |
| BEMT loads | `ccblade_section_operating_points`, CCBlade call | FAIL (R996_LOADS 6/32) | no isolated check of the BEMT integration against a hand calculation |
| Polars | `load_polar_set`, Viterna | VERIFIED (knots, 25i); INCONCLUSIVE (display) | input-data questions are author decisions (TN 1546 above M 0.72; forced transition) |
| Cavity modes (CYL2D, App. C) | `cyl2d_modes`, `acoustic_boundary_value`, `cabin_modes_3d` | INCONCLUSIVE (CYL2D_C1 against App. C tables of the same report) | no check against an exact solution |
| 3-D cabin modes | `cabin_frequency_3d`, `cabin_eps_3d`, `axial_truncation` | VERIFIED | none |
| Structural modes (MRP, App. D) | `structural_modes` (Ritz), `structural_modes_from_table_d1`, `appd_modes`, `build_structural_modes` | VERIFIED (App. D vs Donnell ≤1 %); INCONCLUSIVE (Ritz fitted to Table D-1; App. D vs Table D-1 27/32) | raw Ritz not tested against a closed form |
| Trim (App. A) | `element_matrix`, `stack_matrix`, `trim_tau*`, `trim_Cw`, `trim_conductance`, `phase3_trim` | VERIFIED (limits); FAIL (E14_LOSS 7/18) | no closed-form check of a full Phase III-type stack |
| Loss factors (§3.8) | joint acceptances, `acoustic_loss_*`, `structural_loss_*` | VERIFIED (formulas); FAIL / INCONCLUSIVE against E-14 / E-15 | `structural_joint_acceptance` only self-consistency |
| PAIN core, tones Eq. (8) | `coupling_factor`, `axial_coupling`, `generalized_force*`, `tone_mean_square_pressure`, `cabin_volume` | VERIFIED (analytic limits, independent re-implementation); FAIL end to end (T1, REPRO_18b, E18_TONES) | none at block level |
| Broadband (surrogate) | `blocked_broadband_band_p2`, `broadband_cabin_p2`, `structural_modal_density`, `band_joint_acceptance`, `absorption_coefficient` | NONE / FAIL (T2) | band integral, modal count and band joint acceptance untested |
| Noise reduction Eqs. (17)–(18) | `nr_*`, `noise_reduction_band`, `noise_reduction_spectrum` | VERIFIED (integral, Eq. 17 = 18); FAIL (E21_E22_NR) | no hand-computed band check |
| High-frequency tones Eqs. (11)–(16) | `expected_g_*`, `tone_expected_value` | VERIFIED (limits); FAIL (E18_TONES) | none at block level |
| High-frequency broadband Eqs. (19)–(23) | `hf_transmission_coeffs`, `hf_broadband_band_p2` | VERIFIED (limits); FAIL (T2_EQ19) | no single-layer mass-law check |
| Metrics | `a_weight_dB`, `overall_dBA` | VERIFIED | `sil_*` only finite-value checks |
| Output level | `overall_dBA` of `interior_spl` | space average only | **no loudest-point level** |

## Where the end-to-end misses can come from

| Failing case | Blocks on its chain | Isolation test that attributes it (phase) |
|--------------|---------------------|-------------------------------------------|
| T1, REPRO_18b, E18_TONES | free field, GEXT, blocking, CYL2D, modes, trim, loss, Eq. (8) | cabin chain from measured blocked pressures (41a); CYL2D exact (40e); Ritz closed form (40f); trim stack closed form (41b) |
| E14_LOSS, E15 | trim, loss factors | trim stack closed form (41b) |
| T2, T2_EQ19 | broadband helpers, HF Eqs. (19)–(23) | band integral and modal count (40h, 40i); mass-law layer (41d) |
| E21_E22_NR | noise reduction | hand-computed band (41c) |
| R996_LOADS | polars, BEMT | BEMT hand calculation (41e) |
| R996_FIG12/13A, R996_PHASE, BBN_CIRC, PER_FIG7/8/9 | loads, F1A | independent F1A implementation with the same loads (41f) |
| UNC_COVER | whole parametric chain | attributed through the above; no single block |

Plan: phases 39–42 in `IMPLEMENTATION_PLAN.md` §8. Criteria are dated 2026-10-23, before any of these tests is run.

## Status after phases 40–45 (updated 2026-10-23)

The table above is the audit record of 2026-10-23. This section records what each block has now; case details are in `VALIDATION_GUIDELINE.md` §2.13, and results after the 44f sign fix are post-hoc where they had been seen before.

| Block | Isolated check now | Result |
|-------|--------------------|--------|
| Free-field input | ISO_FF_CONV, ISO_TABLE8 (40) | met |
| Grid extension (GEXT) | ISO_GEXT_LINE (40); off-line field compared with F1A (T1_F1A_FILL, 43f) | on-line identity met; off-line field remains V-ASSUMED |
| Blocking on the full grid | ISO_BLOCKING (40); App. B L = 10 row vs Table 8 (44a) | met; NASA's increase is 3.6–4.1 dB, position-dependent (not a flat 4 dB) |
| CYL2D | ISO_CYL2D_EXACT, ISO_CYL2D_BOUNDARY (40); App. B acoustic modes (44b) | met; ε exact and frequencies within 0.9 % of NASA's printout |
| Structural modes | Ritz closed form (40f, not met); App. B shell masses (44) | Table D-1 shapes reproduce App. B "SHELL W" (median 0.19 %, max 3.8 %) |
| Trim (App. A) | TRIM_CLOSED (41b); R172428_TRIM (44, diagnostic) | met; NASA's printed trim factor within 0.15 dB at 250–1000 Hz |
| Loss factors | E15_STRUCT_LOSS; R172428_ETA (44c/d) | App. A η_r′ within 13 % of NASA for modes 1–12; 17/32 within ±25 % (not met) |
| PAIN core Eq. (8) | T1_FROM_E12 (41a); R172428_CODE / R172428_PAIRS (44) | two code fixes found against NASA's printout: Eq. (83) bare f′, and the Eq. (52) floor-term sign (44f). 12 of 15 printed modal pairs within ±3.7 dB; R172428_CODE 4/9 (not met); open: (0,1) × mode 8 (Q22) |
| Noise reduction Eqs. (17)–(18) | NR_BAND_HAND (41c); NR_TP1964 (43d) | hand band met; TP-1964 6/18 (not met: modal Eq. 18 above ~1 kHz) |
| High-frequency broadband Eqs. (19)–(23) | HF_MASSLAW (41d); NR_TP1964_XOVER (45) | met (mass law); TP-1964 with the changeover 9/18, Eq. (19) bands 4/4 within ±2.5 dB |
| Broadband helpers | ISO_BB_BAND, ISO_MODAL_DENSITY (40) | met (band integral fixed in 40i) |
| BEMT, F1A | BEMT_HAND, F1A_INDEP (41) | met |
| Output level | LOUDEST_PT (42) | loudest-point dB(A) reported; the pre-registered 1 % average check is not met with interior nodes only (wall antinodes left out) |

**Phases 48–58 (2026-10-23):**
- **Exterior.** The exterior self-noise model (BPM) is verified against NASA's printed outputs.
- **Noise reduction.** The propeller-field coupling explains most of the 47c low-frequency gap.
- **High frequency.** PAIN's trim model is documented by NASA as valid to about 1 kHz. No in-theory input correction closes T2's gap, and no verifiable bridge model was available.
- **T1.** T1's H3 excess comes from the e11 off-line field.
- **Code fixes.** One reading defect was fixed: the Eq. (20) τ_f sum.
- **Tests.** The never-executed functions now have tests.

**Phase 47 (2026-10-23):** T2's cabin path was run with a measured exterior: TP-2444 Fig. 17, this article at 4000 rpm.
- `T2_MEAS_EXT` and `NR_PROP_TP2444` are both not met.
- The measured exterior, interior and E-9 agree with each other.
- The high-frequency noise reduction (Eqs. 19–23) of the trimmed article is 15–27 dB too high, and NASA's printed E-21/E-22 predictions show the same.
- The T2 block that fails is therefore identified: the trimmed-wall transmission above about 1 kHz. See `t2_measured_exterior.md`.

**Phase 46 (2026-10-23):** the five functions on the T1/T2 paths that had no isolated check now have one, all met (`broadband_cabin_p2`, `tone_expected_value`, `hf_structural_band`, `hf_band_loss_factors`, `coupling_loss_factor_21`). So do the T1/T2-path functions that the full-suite coverage run showed were never executed (`tone_Q_H`, the α = 1 branch of `blocked_broadband_band_p2`, `w_in_reverberant`). Never executed by the suite but off the T1/T2 paths: the aircraft trim JSON parsing (`parse_aircraft_trim_json` and helpers), `build_aircraft_cache` and `_rand_triangular` (uncertainty), `fit_mrp_to_table_d1`, `appd_constraint_residuals`, `scale_acoustic_freq`, `hf_broadband_spectrum`. Registry builders also show as unexecuted, because they run when the package loads.

**Remaining gaps (corrected 2026-10-23):** the q = 0 coupling difference against NASA (Q22). T2's exterior input was thought unmeasured (43e), but NASA TP-2444 Fig. 17 is a measured exterior and interior spectrum of this article at 4000 rpm (to 1.5 kHz); plan Phases 47–48.
