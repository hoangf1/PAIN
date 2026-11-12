# PAIN recreation — case records

One record per validation case: what it tests, its chain span, what it is compared with, its criterion, its recorded outcome. Moved here word for word from `VALIDATION_GUIDELINE.md` §2.13 on 2026-11-11 (Phase 148b); the criteria themselves stay in `VALIDATION_GUIDELINE.md`. The GUI, the website and `src/validation_map.jl` read this file: keep the `### Map:` / `#### Block:` / `### Case:` layout.

## 2.13 Validation case reference (read by the GUI)

Machine-readable case text for the Validation and Coverage tabs. Format: `### Map: id` / `#### Block: id` / `### Case: id` with bold `**Field:**` lines; the parser in `src/validation_map.jl` depends on this layout. Every case also gives (Phase 134, 2026-11-05) `**Chain span:** <first stage> → <last stage>`, the part of the program chain it runs: the stage its given input enters at and the stage of the quantity it compares, from Blade and polars, Blade loads, Free field, Skin field, Wall modes, Cabin modes, Damping and trim, Interior tones, Bands and dB(A); and `**Compared with:**` `measurement` | `NASA's printed prediction` (what NASA's program printed for the same inputs) | `verification` (an analytic limit, law, hand formula, another method or report, input check or display). The chain coverage chart (§0, the GUI's Coverage tab) is drawn from these two fields. **Block map retired (Phase 147, 2026-11-10, decided by Claude under the author's delegation of 2026-11-10):** the GUI no longer draws the `total` map, so the block layout fields (`**Position:**`, `**Feeds:**`, `**Group:**`, `**Role:**`, `**Group title:**`) are no longer read for drawing. The `### Map:` and `#### Block:` records stay for two uses only, until Phase 148 moves the case records to data files: a case's block gives its figure folder (`docs/validation_reports/figures/<folder>/`) and the case order in the Validation tab. A new case goes under the block whose figure folder it should use. Abbreviations used below: ANOPP = NASA Aircraft NOise Prediction Program (free-field source tables); GEXT = assumed grid extension from one measured line to 160 skin points; T1 / T2 = tonal / 1/3-octave interior checks vs App. E; R1 / R2 = blocking Eq. (43) revisions; γ = incidence angle; ℓ = 1 = propeller-azimuth grid line; H1–H3 = blade-passage harmonics 1–3; BPF = blade-passage frequency; η_T = trim loss factor; F1A = Farassat formulation 1A.

### Map: total
**Title:** Whole program: aircraft source → grid → blocking → cabin chain → interior SPL, with every validation check
**What this map is:** Retired (Phase 147, 2026-11-10). The blocks below are kept as figure folders and as the Validation tab's case order; the chain coverage chart (§0) is the one view.
**How to read it:** Not drawn since Phase 147 (2026-11-10). Each Explanation ends with Inputs / Equations / Outputs lines.

#### Block: A_GEO
**Title:** Aircraft inputs
**What this stage does:** Loads airfoil lift/drag tables and aircraft JSON geometry that CCBlade needs before any thrust or noise. First aircraft stage. Code: `polars.jl`, aircraft JSON.
**Code:** polars.jl, aircraft JSON
**Group:** G_AIR
**Group title:** Airfoil BEMT+F1A
**Role:** input
**Position:** 0,2
**Feeds:** A_LOADS

#### Block: A_LOADS
**Title:** CCBlade BEMT
**What this stage does:** Blade-element momentum theory thrust T and torque Q (coefficients C_T, C_P). Load error swamps acoustic error, so this sits before F1A amplitude checks. Code: `propeller_ccblade.jl`.
**Code:** propeller_ccblade.jl
**Note:** BEMT_HAND (41e): hand BEM vs wrapper, tip loss off, cl=2πα cd=0
**Group:** G_AIR
**Role:** function
**Position:** 1,2
**Feeds:** X_F1A

#### Block: X_F1A
**Title:** F1A source
**What this stage does:** Farassat F1A turns BEMT section loads into free-field pressure at observers. Code: `propeller_ccblade.jl` (F1A).
**Code:** propeller_ccblade.jl (F1A)
**Group:** G_AIR
**Role:** function
**Position:** 2,2
**Feeds:** X_FF

#### Block: X_FF
**Title:** Free field p
**What this stage does:** Aircraft free-field pressures (amplitude and phase per harmonic) handed to Source select and to the aircraft source checks.
**Group:** G_AIR
**Role:** output
**Position:** 3,2
**Feeds:** X_SRC, A_AMP, A_PHASE, A_FWD, A_SURF

#### Block: A_AMP
**Title:** F1A amplitude
**What this stage does:** Farassat F1A harmonic amplitudes in the static near field (Report 996 figures) plus a far-field Gutin coding check. Comes after loads because several cases scale loads to measured T, Q. Code: `propeller_ccblade.jl` (F1A).
**Code:** propeller_ccblade.jl (F1A)
**Note:** F1A_INDEP (41f): independent Farassat 1A vs AcousticAnalogies on identical loads
**Group:** G_AIR
**Role:** check
**Position:** 1,0
**Feeds:**

#### Block: A_PHASE
**Title:** F1A phase
**What this stage does:** Phase differences between observers (kinematic hub-ring unit test, BBN circumferential/longitudinal, Report 996 one-point phase). Phase enters cabin coupling Ψ_G; checked after amplitude wiring.
**Group:** G_AIR
**Role:** check
**Position:** 1,4
**Feeds:**

#### Block: A_FWD
**Title:** Forward flight
**What this stage does:** Pereira et al. 2026 forward-flight spectra, waveform phase, and directivity at 1 m — the only forward-flight experiment set. Comes after static amplitude/phase.
**Group:** G_AIR
**Role:** check
**Position:** 2,0
**Feeds:**

#### Block: A_SURF
**Title:** Surface levels
**What this stage does:** Relative in-plane levels on a fuselage-like microphone ring (BBN Tables 3–4). Surface shape check before any cabin claim.
**Group:** G_AIR
**Role:** check
**Position:** 2,4
**Feeds:**

#### Block: P_FF
**Title:** e11 free field
**What this stage does:** Exterior free-field SPL that drives every App. E cabin run. Fig. E-11 is NASA's measured line along grid line ℓ = 1 with the fuselage absent; harmonic 3 (H3) and all phases come from ANOPP Table 8, not from the figure. Code: `freefield_digitized.jl`.
**Code:** freefield_digitized.jl
**Note:** Fig. E-11 measured line; H3 and all phases from ANOPP Table 8; ISO_FF_CONV / ISO_TABLE8 (phase 40)
**Group:** G_FF
**Group title:** Free field
**Role:** input
**Position:** 5,1
**Feeds:** X_SRC

#### Block: X_SRC
**Title:** Source select
**What this stage does:** Chooses the free-field driver for the cabin chain: aircraft F1A grid or e11 measured line / ANOPP Table 8. Hand-off into the shared 160-point grid.
**Group:** G_FF
**Role:** function
**Position:** 5,2
**Feeds:** P_GRID

#### Block: P_GRID
**Title:** 160-point grid
**What this stage does:** Builds the 160 fuselage-skin observers (User Manual Fig. 3) and, on the e11 path only, fills 150 of them from the one measured line by an assumed amplitude falloff and geometric delay (GEXT). Comes after free-field input because every later pressure lives on this grid. Code: `geometry.jl`, `grid_extension.jl`.
**Code:** geometry.jl, grid_extension.jl
**Note:** ISO_GEXT_LINE (40c): on-line identity; off-line GEXT stays V-ASSUMED
**Group:** G_GRID
**Group title:** Grid and blocking
**Role:** function
**Position:** 6,2
**Feeds:** P_BLK

#### Block: P_BLK
**Title:** Blocking Eq. 43
**What this stage does:** Scales free-field amplitude at each skin point by Magliozzi's empirical factor F(γ) so a rigid fuselage "blocks" (reflects) the wave; phases unchanged. Comes after the grid because γ is computed from hub-to-skin geometry. Code: `blocking.jl`.
**Code:** blocking.jl
**Note:** ISO_BLOCKING (40a): full-grid apply_blocking vs F(γ)·A
**Group:** G_GRID
**Role:** function
**Position:** 7,2
**Feeds:** X_BLK_OUT

#### Block: X_BLK_OUT
**Title:** Blocked pressures
**What this stage does:** Blocked skin pressures (amplitude after Eq. 43; phases unchanged) handed to PAIN main.
**Group:** G_GRID
**Role:** output
**Position:** 8,2
**Feeds:** X_PAIN_IN

#### Block: X_MRP_IN
**Title:** Structure inputs
**What this stage does:** Fuselage geometry and material inputs for the structural modal solve / Table D-1 seed.
**Group:** G_MRP
**Group title:** Structural modes
**Role:** input
**Position:** 6,5
**Feeds:** P_MRP

#### Block: P_MRP
**Title:** Structural modes
**What this stage does:** Fuselage structural modal frequencies and shapes that enter the coupling. Production uses the Table D-1 seed; a calibrated Ritz surrogate and the printed App. D solver are checked beside it. Comes before cabin acoustics and coupling. Code: `mrp.jl`, `mrp_appd.jl`.
**Code:** mrp.jl, mrp_appd.jl
**Note:** Phase 40f ISO_RITZ_DONNELL not registered: `structural_modes` always smears stringer/frame I into Ds (no option zeros MRP_I_*); cannot remove stiffeners without solver physics changes
**Group:** G_MRP
**Role:** function
**Position:** 7,5
**Feeds:** X_MRP_OUT

#### Block: X_MRP_OUT
**Title:** Modes f_r, ψ_r
**What this stage does:** Structural modal frequencies, masses and shapes handed to PAIN main.
**Group:** G_MRP
**Role:** output
**Position:** 8,5
**Feeds:** X_PAIN_IN

#### Block: X_CYL_IN
**Title:** Cabin geometry
**What this stage does:** Floor angle, cavity length and radius for Appendix C cabin acoustic modes.
**Group:** G_CYL
**Group title:** CYL2D
**Role:** input
**Position:** 6,7
**Feeds:** P_CYL

#### Block: P_CYL
**Title:** CYL2D
**What this stage does:** Two-dimensional cabin acoustic modes (frequencies, generalized mass, shapes) from Appendix C. Needed with the structural modes before the Eq. (8) coupling sum. Code: `cyl2d.jl`.
**Code:** cyl2d.jl
**Note:** ISO_CYL2D_EXACT (40e, θ0=0° vs J′ zeros); ISO_CYL2D_BOUNDARY (40j)
**Group:** G_CYL
**Role:** function
**Position:** 7,7
**Feeds:** X_CYL_OUT

#### Block: X_CYL_OUT
**Title:** Modes Φ_G
**What this stage does:** Cabin acoustic modal frequencies, generalized mass and shapes handed to PAIN main.
**Group:** G_CYL
**Role:** output
**Position:** 8,7
**Feeds:** X_PAIN_IN

#### Block: X_TRIM_IN
**Title:** Trim stack
**What this stage does:** Sidewall/end trim stack definition and loss-factor inputs before App. A / §3.8.
**Group:** G_TRIM
**Group title:** Trim and loss
**Role:** input
**Position:** 6,9
**Feeds:** P_TRIM

#### Block: P_TRIM
**Title:** Trim and loss
**What this stage does:** Sidewall/end trim transfer matrices and structural/acoustic loss factors that set every modal amplitude. Comes after modes and before the tone/broadband sums. Code: `trim_loss.jl`.
**Code:** trim_loss.jl
**Note:** ISO_JOINT_ACC (40g); TRIM_CLOSED (41b). `absorption_coefficient` is a fitted surrogate used only by `:surrogate` (40l; no isolated case)
**Group:** G_TRIM
**Role:** function
**Position:** 7,9
**Feeds:** X_TRIM_OUT

#### Block: X_TRIM_OUT
**Title:** τ, η
**What this stage does:** Trim transfer results and loss factors handed to PAIN main.
**Group:** G_TRIM
**Role:** output
**Position:** 8,9
**Feeds:** X_PAIN_IN

#### Block: X_PAIN_IN
**Title:** Cabin inputs
**What this stage does:** Blocked pressures, structural modes, cabin modes, trim and loss factors collected for the coupling / tone / HF sums.
**Group:** G_PAIN
**Group title:** PAIN main
**Role:** input
**Position:** 9,2
**Feeds:** P_EQ8

#### Block: P_EQ8
**Title:** Coupling / Eq. 8
**What this stage does:** Generalized force, joint acceptance Ψ_G, and the tonal mean-square pressure sum Eq. (8) in `pain_core.jl`; high-frequency expected-value Eqs. (11)–(16) and crossover card 10 in `high_freq_tones.jl` (38b). Default `tone_model=:eq8`; `:auto` switches at the crossover band (default rule = Manual card 10 volume formula, phase 43a; ten-mode count remains `rule=:ten_modes`). Last equation stage before interior SPL checks.
**Code:** pain_core.jl, high_freq_tones.jl
**Note:** Uncertainty (phase 31): epistemic band on cabin inputs — not a CI. ISO_MODAL_DENSITY / ISO_BB_BAND (40h–40i); NR_BAND_HAND / HF_MASSLAW (41c–41d). `absorption_coefficient` fitted surrogate for `:surrogate` only (40l)
**Group:** G_PAIN
**Role:** function
**Position:** 10,2
**Feeds:** X_OUT

#### Block: X_OUT
**Title:** Interior SPL
**What this stage does:** Interior tonal and 1/3-octave SPL from the cabin chain; feeds the vs-NASA-PAIN and vs-measurement comparisons. Aircraft cabin use stays X-EXTRAP.
**Note:** ISO_SIL (40k): hand SIL from a known band spectrum
**Group:** G_PAIN
**Role:** output
**Position:** 11,2
**Feeds:** P_REPRO, P_MEAS, A_CABIN

#### Block: P_REPRO
**Title:** vs NASA PAIN
**What this stage does:** Code-on-code: run this cabin chain on the same free-field/blocking/trim settings NASA used and compare interior tonal SPL with NASA's PAIN circles (Fig. E-16 / E-18). Comes after the equation stages so a miss can be blamed on the chain, not on a missing mode.
**Note:** Phase 44: R172428_CODE runs the chain on NASA's own printed CR-172428 inputs (App. B blocked field, Table 6, App. B trim) against NASA's printed predictions; R172428_PAIRS compares the top modal contributions.
**Group:** G_VAL
**Group title:** Validation comparisons
**Role:** check
**Position:** 12,1
**Feeds:**

#### Block: P_MEAS
**Title:** vs measurement
**What this stage does:** End-to-end checks against measured cabin levels and noise reduction (T1, T2, E-21/E-22). Last on the map because they inherit every upstream assumption (especially GEXT); several are calibrated or not claimable.
**Note:** Uncertainty (phase 31): UNC_COVER is the epistemic P5–P95 coverage check vs E-16 means — not NASA accuracy and not a CI. T1_FROM_E12 (41a): measured E-12 blocked pressures into the cabin chain. Phase 43: T1_MEAS_DAMPING / T1_F1A_FILL / NR_TP1964 / NR_TP1964_REF2 / H3_ATTRIB. Phase 44: R172428_EXP (NASA's inputs vs measured CR-172428 Table 5)
**Group:** G_VAL
**Role:** check
**Position:** 12,3
**Feeds:**

#### Block: A_CABIN
**Title:** Aircraft cabin
**What this stage does:** Hand-off note: aircraft free-field on the 160-point grid feeds the cabin chain. Aircraft cabin SPL stays X-EXTRAP. Since Phase 121 (2026-11-03) one aircraft interior measurement is compared, as information: the Commander 695A cabin dB(A) of CR-178004 flight 3 (`AC_C695A_DBA`, no verdict: its blade and cabin section are assumed).
**Note:** Aircraft cabin SPL is X-EXTRAP; the Commander 695A comparison (AC_C695A_DBA) is information, not a validation; epistemic uncertainty band (phase 31) is not a validation
**Group:** G_VAL
**Role:** check
**Position:** 12,5
**Feeds:**

### Chunk 1: Airfoil BEMT+F1A (`G_AIR`)

Blocks in map order: `A_GEO` Aircraft inputs → `A_LOADS` CCBlade BEMT → `X_F1A` F1A source → `X_FF` Free field p → `A_AMP` F1A amplitude → `A_PHASE` F1A phase → `A_FWD` Forward flight → `A_SURF` Surface levels. Cases are listed block by block, in the order the map shows them.

### Case: UT_POLAR
**Title:** Polar loader (Pkg.test)
**Map / block:** total / A_GEO
**Category:** verification
**Kind:** pkgtest
**Chain span:** Blade and polars → Blade and polars
**Compared with:** verification
**Source:** XFOIL polars, tables.json
**What it tests:** That `polars.jl` reads polar knots and applies bracket factors k_cl / k_cd.
**Why it is here:** CCBlade loads depend on the polars.
**A pass means:** Loader reads knots and applies the bracket factors.
**Not covered:** k_cl, k_cd were fitted to RM L9G06a (register), not to Report 996. No GUI figure — table/loader unit check only.
**Recorded outcome:** Pkg.test pass ("Polar loader")
**Explanation:** Unit test (Pkg.test only, no figure): polar file loader. Bracket factors were fitted to other data (register).
Inputs: polar tables in package data / aircraft JSON as used by Pkg.test.
Equations: none (loader); code `polars.jl`.
Outputs: Pkg.test assertions only; no registry verdict.

### Case: POLAR_R996
**Title:** Report 996 polars (display)
**Map / block:** total / A_GEO
**Category:** display
**Kind:** runnable
**Chain span:** Blade and polars → Blade and polars
**Compared with:** verification
**Source:** `polars_forced_merged.json` via `load_polar_set`; Viterna via CCBlade.viterna; TN 1546 measured overlay via `measured_polar_series`; section ops from CCBlade (same path as `evaluate_propeller_source`)
**What it tests:** Nothing — display of the XFOIL/Viterna polars, TN 1546 measured overlay, Mach gap to tip, and where R996_LOADS / FIG12 / FIG13A / FIG14 blade sections operate (Mach, α, Re).
**Why it is here:** The Validation tab shows BEMT/F1A results that use the polars, not the polars; many runs sat outside the forced-transition grid (Mach ≤ 0.72, α −6°–14°, Re from 3×10⁵). Since 2026-10-28 the case shows the Phase 69 set (free transition, N_crit 8; Mach 0.1–0.9, α −6°–20°, Re 1.5×10⁵–2×10⁶; XFOIL converges poorly at M 0.9).
**A pass means:** display only (verdict always `:no_verdict`; no criterion).
**Not covered:** Not a load or acoustic check; measured data are display only (BEMT does not read them); Re in the coverage panel uses μ_air = 1.78×10⁻⁵ for display (production CCBlade still uses default μ = 1). The polar set (`polars_phase69_ncrit8.json`) has N_crit 8 fitted to TN 1546 sections 16-506 and 16-509 (Phase 69b), so it is tied to measured section data through that fit (note of 2026-11-10, Phase 141a).
**Recorded outcome:** display only; figures `POLAR_R996.png`
**Explanation:** Display only: panels 1–2 show c_l, c_d vs α for section n16_506 (NACA 16-506; exact TN 1546 match nearest 0.75 R, blade-form station ≈0.87 R) at the Re nearest the median outer-blade operating Re, one XFOIL series per Mach, Viterna extension dashed, and TN 1546 markers at M = 0.4, 0.55, 0.65, 0.72 (c_d rows with `assignment=uncertain` skipped). Axes limited to the operating α band. Panel 3: α vs local Mach with the polar domain box; inside points steel blue, outside red. Panel 4: c_l vs Mach at TN 1546 α — one colour per α for both the measured dashed curve and the XFOIL filled markers (≤0.9 since 2026-10-28); compact legend `α=…°: line=TN 1546, dots=XFOIL`; band 0.72–0.90 = tested tip Mach. Table: per-run outside counts, PolarStats lookup counts (each section evaluation counts once, so blended stations count twice), and informational c_l (XFOIL − TN 1546) at each overlaid (α, M), linear in M between grid tables.
Inputs: `data/report996/polars_forced_merged.json` primary/bracket via `load_polar_set`; blade form `naca_4-5-08-03/blade_form.csv`; `data/airfoil_measured/tn1546_fig3_cl_cd_vs_mach.csv` (display overlay only); same (β₇₅, M_t, B) configs as the Report 996 load/acoustic cases.
Equations: CCBlade BEMT section solve (`ccblade_section_operating_points`); Viterna (`CCBlade.viterna`); no new aero model.
Outputs: four panels + table; verdict `:no_verdict`.

### Case: POLAR_PER
**Title:** Pereira polars (display)
**Map / block:** total / A_GEO
**Category:** display
**Kind:** runnable
**Chain span:** Blade and polars → Blade and polars
**Compared with:** verification
**Source:** `naca4412_xfoil_ncrit9.json` (plus ncrit5 / xtr005); Report 824 NACA 4412 via `measured_polar_series`; section ops from CCBlade (same path as `evaluate_propeller_source`)
**What it tests:** Nothing — display of the Pereira XFOIL polars, Report 824 measured overlay, and where PER_LOADS / PER_FIG* blade sections operate.
**Why it is here:** Same gap as POLAR_R996 for the forward-flight polar set.
**A pass means:** display only (verdict always `:no_verdict`; no criterion).
**Not covered:** Not a thrust or SPL check; measured data are display only (BEMT does not read them); Report 824 is Re 3–9×10⁶ while Pereira operates near 1.4×10⁵.
**Recorded outcome:** display only; figures `POLAR_PER.png`
**Explanation:** Display only: panels 1–2 show NACA 4412 c_l, c_d vs α at the Re nearest the median outer-blade Re (ncrit9 all Mach; ncrit5/xtr005 at one mid Mach) with Report 824 c_l(α) markers on panel 1. Panel 3: α vs local Mach for the three polar-set runs behind PER_LOADS / PER_FIG*; inside steel blue, outside red. Panel 4: c_d vs c_l (XFOIL + Report 824 markers) — simpler honest option vs remapping c_d through c_l(α) at mismatched Re. Title notes the Re mismatch. Table: per-run outside counts and PolarStats.
Inputs: `data/pereira/naca4412_xfoil_*.json` via `load_polar_set`; geometry from `pereira_fig1b_chord_twist.csv` (same downsample as the Pereira script); `data/airfoil_measured/tr824_naca4412_cl_alpha.csv` and `tr824_naca4412_cd_cl.csv` (display overlay only).
Equations: CCBlade BEMT section solve; no new aero model.
Outputs: four panels + table; verdict `:no_verdict`.

### Case: POLAR_FIDELITY
**Title:** Section polars: XFOIL vs NACA TN 1546 measured c_l (67a)
**Map / block:** total / A_GEO
**Category:** experiment
**Kind:** runnable
**Chain span:** Blade and polars → Blade and polars
**Compared with:** measurement
**Source:** NACA TN 1546 Fig. 3(j), 3(n), 3(o) (digitized 2026-10-22); `polars_forced_merged.json`; criterion 2026-10-24, before the comparison
**What it tests:** The XFOIL section polars the Report 996 cases use, against the measured c_l of the three exactly matching sections (16-312, 16-506, 16-509) at the TN 1546 angles and the XFOIL Mach grid (0.4–0.72), XFOIL at the TN 1546 Reynolds number.
**Why it is here:** The code checks of BEMT and F1A pass, yet the Report 996 loads and acoustics miss; this tests whether the section polars are the cause.
**A pass means:** |Δc_l| ≤ 0.05 at ≥ 75 % of the matched points.
**Not covered:** The other blade sections (no measured data); c_d (shown, no criterion); wall-interference corrections (TN 1546 is uncorrected). The polar set (`polars_phase69_ncrit8.json`) has N_crit 8 fitted to TN 1546 sections 16-506 and 16-509 (Phase 69b), so it is tied to measured section data through that fit (note of 2026-11-10, Phase 141a).
**Recorded outcome:** **not met**, 9/60 (15 %) (first run 2026-10-24; `phase67_source_attribution.md`). XFOIL is 0.15–0.35 below the measured c_l at low α on all three sections and at every Mach number; the gap closes toward the high-α end. Post-hoc consistency (2026-10-24): the BEMT thrust of the Report 996 cases is 25–32 % below the measured thrust (scale factors s_T = 1.25–1.32, 7 of 10 primary cases), the direction and size a low c_l gives. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** free transition, N_crit 8 fitted to 16-506/16-509 (69b), Phase 69 grid at the TN 1546 Re(M) and M. Verdict now on the held-out 16-312 only: **not met, 13/26** (50 %). 16-506 13/15 and 16-509 14/20 are shown as N_crit fit points with no verdict. The Phase 67 explanation (forced transition) holds for most of the gap; the rest is the 12 %-thick section. **Display 2026-10-28 (Phase 77, author; verdict and criterion unchanged):** three more panels show each offset as an equivalent angle of attack, Δα = Δc_l/(2π/√(1−M²)) (Prandtl–Glauert slope, theory, not fitted): the 0.05 criterion is 0.42° at M 0.4 and 0.32° at M 0.72. No percentage is shown: 13 of the matched c_l lie within ±0.2 of zero lift, where a percentage error grows without bound.
**Explanation:** Input fidelity, not code: the polars are XFOIL with forced transition. The Report 996 source misses are therefore a documented limitation of the section-data approximation (XFOIL), not of the BEMT or F1A implementation, which pass their closed-form checks (Phases 41, 64, 66). No polar or load was changed.
Inputs: TN 1546 Re(M) = 0.85·10⁶ + 1.15·10⁶ (M − 0.3)/0.5 (TN 1546 p. 5 range; reading fixed before the comparison); XFOIL tables at 1·10⁶ and 2·10⁶, linear in log Re; no extrapolation in α.
Equations: —
Outputs: Δc_l per (section, M, α).

### Case: R996_LOADS
**Title:** Report 996 CCBlade loads
**Map / block:** total / A_LOADS
**Category:** calibrated
**Kind:** replay
**Chain span:** Blade and polars → Blade loads
**Compared with:** measurement
**Source:** RM L8H25a, Report 996 Fig. 14 table, Fig. 7 legend
**What it tests:** CCBlade BEMT thrust and torque coefficients C_T, C_P vs measured.
**Why it is here:** Load error swamps acoustic error.
**A pass means:** C_T, C_P within ±15 % (23c).
**Not covered:** Criteria registered after the loads were computed (post-hoc); polars XFOIL + Viterna. The polar set (`polars_phase69_ncrit8.json`) has N_crit 8 fitted to TN 1546 sections 16-506 and 16-509 (Phase 69b), so it is tied to measured section data through that fit (note of 2026-11-10, Phase 141a).
**Recorded outcome:** 6/32 within ±15 % (not met); post-hoc label; scale_factors.csv / report996_loads.md. Isolation case BEMT_HAND (41e); isolation passes: remaining miss attributed to model fidelity (method), not code. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** **24/32** within ±15 % (C_T 11/14, C_P 13/18), was 6/32; still not met. The change comes from the Phase 69 polar set and the loader fixes (69a: per-station section blend, log-Re/Mach interpolation, μ in CCBlade).
**Explanation:** Replay of a recorded result: CCBlade C_T, C_P vs RM L8H25a / Fig. 14 table / Fig. 7 legend (±15 %, 23c). Recorded 6/32. Criterion registered after the loads → post-hoc. Not tuned.
Inputs: recorded `scale_factors.csv` from the Report 996 loads script; aircraft/polar set used in that run (see report996_loads.md).
Equations: BEMT in CCBlade via `propeller_ccblade.jl` (recorded outputs replayed).
Outputs: C_T, C_P [-]; verdict |ratio−1| ≤ 0.15 (replay).

### Case: PER_LOADS
**Title:** Pereira Table 3 loads
**Map / block:** total / A_LOADS
**Category:** experiment
**Kind:** replay
**Chain span:** Blade and polars → Blade loads
**Compared with:** measurement
**Source:** Pereira et al. 2026, Table 3
**What it tests:** CCBlade T, Q in forward flight vs Pereira Table 3.
**Why it is here:** Forward-flight loads beside the acoustic Pereira cases.
**A pass means:** Informational (no load tolerance in frozen 23d).
**Not covered:** —
**Recorded outcome:** no_verdict (23d has no load tolerance); replay of pereira_results.csv
**Explanation:** Replay of a recorded result: CCBlade thrust T [N] and torque Q [N·m] vs Pereira Table 3. No verdict — 23d covers harmonic levels and phase only.
Inputs: recorded `pereira_results.csv` / `pereira_tables3_4.csv` from the Pereira script.
Equations: BEMT (replayed); not re-solved in the GUI case.
Outputs: T, Q; verdict `:no_verdict`.

### Case: R996_FIG14
**Title:** Report 996 Fig. 14(a) — loads scaled to measured thrust and torque
**Map / block:** total / A_AMP
**Category:** experiment
**Kind:** replay
**Chain span:** Blade loads → Free field
**Compared with:** measurement
**Source:** NACA Report 996 Fig. 14(a), p.16
**What it tests:** F1A harmonic amplitude vs tip Mach M_t at fuselage-like distance.
**Why it is here:** Static near-field amplitude check.
**A pass means:** Scaled-load harmonic within ±2 dB at ≥ 75 % of points (23c).
**Not covered:** Loads scaled to measured T, Q (calibrated input); static only; amplitude convention fixed 2026-10-21, post-hoc. The polar set (`polars_phase69_ncrit8.json`) has N_crit 8 fitted to TN 1546 sections 16-506 and 16-509 (Phase 69b), so it is tied to measured section data through that fit (note of 2026-11-10, Phase 141a).
**Recorded outcome:** met 20/24 within ±2 dB (report996_acoustics.md; amplitude convention fixed 2026-10-21, post-hoc) **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** 20/24 (unchanged count; max error 4.4 dB, was 3.1); still met. **Re-run 2026-10-28 (Phase 72, observer fore/aft convention, post-hoc: the earlier results were known; the convention is taken from the source documents, nothing chosen from the residuals):** **not met, 14/24** (was met 20/24). Fig. 14 is at x/D = −0.125, behind the plane; computed behind now: H2 8/8, H4 4/8, H6 2/8, the higher harmonics too loud. The earlier pass was computed ahead of the plane. **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** **met, 24/24** (was 14/24; max error 1.9 dB, median 0.69 dB).
**Explanation:** Replay of a recorded result: static near-field harmonic amplitude vs M_t (Fig. 14(a)). Loads scaled to measured T, Q. After I-17: 20/24 within ±2 dB → met (≥75 %). Post-hoc label on the amplitude-convention re-record.
Inputs: recorded `f1a_results.csv` from Report 996 acoustics script; scaled-load path.
Equations: F1A (replayed); criterion 20 log10(A_rms/meas).
Outputs: pressure [dyne/cm²] / SPL error [dB]; verdict ≥75 % within ±2 dB.

### Case: R996_FIG12
**Title:** Report 996 Fig. 12(a)(b) — loads scaled to measured thrust and torque
**Map / block:** total / A_AMP
**Category:** experiment
**Kind:** replay
**Chain span:** Blade loads → Free field
**Compared with:** measurement
**Source:** Report 996 Fig. 12(a)(b), p.13
**What it tests:** F1A harmonic amplitude vs x/D (axial near-field shape).
**Why it is here:** Axial shape of the near field.
**A pass means:** Scaled-load harmonic within ±2 dB at ≥ 75 % of points (23c).
**Not covered:** Loads scaled to measured T, Q (calibrated input); static only; amplitude convention fixed 2026-10-21, post-hoc. The polar set (`polars_phase69_ncrit8.json`) has N_crit 8 fitted to TN 1546 sections 16-506 and 16-509 (Phase 69b), so it is tied to measured section data through that fit (note of 2026-11-10, Phase 141a).
**Recorded outcome:** not_met 21/40 within ±2 dB (re-run 2026-10-22 with regenerated polar entries, post-hoc; first recorded 22/40) (report996_acoustics.md; amplitude convention fixed 2026-10-21, post-hoc). Isolation case F1A_INDEP (41f); isolation passes: remaining miss attributed to model fidelity (method), not code. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** **28/40** within ±2 dB (70 %; need ≥ 75 %), was 21/40; still not met. H6 4/10 is the weakest harmonic. **Re-run 2026-10-28 (Phase 72, observer fore/aft convention, post-hoc: the earlier results were known; the convention is taken from the source documents, nothing chosen from the residuals):** **13/40** (was 28/40). Report 996 p. 6 defines positive x/D as ahead; the scripts had put the behind microphones ahead. With the documented sign the model is too loud behind and too quiet ahead at mB ≥ 4 for β = 10° (H2 7/10, H4 5/10, H6 0/10, H8 1/10). Report 996 says its own Eq. (2) with R_e = 0.8R overestimates by about 40 %. The earlier 28/40 depended on the mirrored observers. **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** **met, 32/40** (was 13/40; H2 8/10, H4 9/10, H6 7/10, H8 8/10; max error 3.5 dB, median 0.96 dB).
**Explanation:** Replay of a recorded result: axial near-field harmonics vs x/D. After I-17: 22/40 within ±2 dB (not met; need ≥75 %); polar re-run 2026-10-22 (post-hoc): 21/40. Scaled loads; amplitude-convention fix post-hoc.
Inputs: recorded `f1a_results.csv`.
Equations: F1A (replayed).
Outputs: pressure vs x/D; verdict ≥75 % within ±2 dB.

### Case: R996_FIG13A
**Title:** Report 996 Fig. 13(a) — loads scaled to measured thrust and torque
**Map / block:** total / A_AMP
**Category:** experiment
**Kind:** replay
**Chain span:** Blade loads → Free field
**Compared with:** measurement
**Source:** Report 996 Fig. 13(a), p.15
**What it tests:** F1A first harmonic vs x/D with RM L51C27 load scale (ahead/behind asymmetry).
**Why it is here:** Ahead/behind asymmetry check.
**A pass means:** Scaled-load harmonic within ±2 dB at ≥ 75 % of points (23c).
**Not covered:** Loads scaled to RM L51C27 T, Q (calibrated input); static only; amplitude convention fixed 2026-10-21, post-hoc. The polar set (`polars_phase69_ncrit8.json`) has N_crit 8 fitted to TN 1546 sections 16-506 and 16-509 (Phase 69b), so it is tied to measured section data through that fit (note of 2026-11-10, Phase 141a).
**Recorded outcome:** not_met 8/14 within ±2 dB (report996_acoustics.md; amplitude convention fixed 2026-10-21, post-hoc). Isolation case F1A_INDEP (41f); isolation passes: remaining miss attributed to model fidelity (method), not code. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** 8/14 (unchanged count; max error 4.0 dB, was 4.4); still not met. **Re-run 2026-10-28 (Phase 72, observer fore/aft convention, post-hoc: the earlier results were known; the convention is taken from the source documents, nothing chosen from the residuals):** **met, 14/14** (was 8/14): the behind/ahead asymmetry (measured 1328 behind vs 1009 ahead dyne/cm²) is now reproduced (1193 vs 1032). **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** met, 14/14 (max error 1.6 dB, was 1.2).
**Explanation:** Replay of a recorded result: first-harmonic amplitude vs x/D with L51C27 scale. After I-17: 8/14 within ±2 dB (not met). Amplitude-convention fix post-hoc.
Inputs: recorded `f1a_results.csv` (L51C27 scale).
Equations: F1A (replayed).
Outputs: H1 pressure vs x/D; verdict ≥75 % within ±2 dB.

### Case: R996_FIG6
**Title:** Report 996 Fig. 6
**Map / block:** total / A_AMP
**Category:** experiment
**Kind:** replay
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** Report 996 Fig. 6, p.11
**What it tests:** F1A total rms vs x/D for B = 4 blades (tip-clearance trend).
**Why it is here:** Tip-clearance trend with four blades.
**A pass means:** Shape and clearance ratios only (no B = 4 loads) — informational.
**Not covered:** no measured T, Q for B = 4. The polar set (`polars_phase69_ncrit8.json`) has N_crit 8 fitted to TN 1546 sections 16-506 and 16-509 (Phase 69b), so it is tied to measured section data through that fit (note of 2026-11-10, Phase 141a).
**Recorded outcome:** informational (no B = 4 loads); replay of f1a_results.csv
**Explanation:** Replay of a recorded result: total rms pressure vs x/D for B = 4. Plotted, no verdict: no measured T, Q for B = 4. Frozen 23c not applied.
Inputs: recorded `f1a_results.csv`, `tr996_fig6_tip_clearance_pressure_vs_xD.csv`.
Equations: F1A (replayed).
Outputs: total rms [dyne/cm²]; no pass rule.

### Case: R996_FIG7
**Title:** Report 996 Fig. 7
**Map / block:** total / A_AMP
**Category:** experiment
**Kind:** replay
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** Report 996 Fig. 7, p.11
**What it tests:** Blade-loading trend p_c/C_P vs x/D.
**Why it is here:** Blade-loading trend beside Fig. 6.
**A pass means:** Informational (script does not apply 23c to Fig. 7).
**Not covered:** — The polar set (`polars_phase69_ncrit8.json`) has N_crit 8 fitted to TN 1546 sections 16-506 and 16-509 (Phase 69b), so it is tied to measured section data through that fit (note of 2026-11-10, Phase 141a).
**Recorded outcome:** informational (script does not apply 23c); replay of f1a_results.csv
**Explanation:** Replay of a recorded result: p_c/C_P vs x/D (Fig. 7). Informational — acoustics script does not apply frozen 23c to Fig. 7.
Inputs: recorded `f1a_results.csv`, `tr996_fig7_blade_loading_pc_over_CP_vs_xD.csv`.
Equations: F1A (replayed).
Outputs: p_c/C_P [-]; no pass rule.

### Case: BBN_CIRC
**Title:** BBN circumferential phase
**Map / block:** total / A_PHASE
**Category:** experiment
**Kind:** replay
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** NASA CR-158919 App. C, CR-159124
**What it tests:** F1A circumferential phase between fuselage microphones.
**Why it is here:** First experimental phase check.
**A pass means:** ≥ 80 % of coh≥0.15 rows within 15°/35° (23a).
**Not covered:** Reflecting surface; low coherence; CR-159124 pair convention unresolved (Table 9 pair 8-9).
**Recorded outcome:** Pre-registered FAIL 26/168 (2026-10-21) on record; post-hoc re-run FAIL 134/168 (2026-10-22); replay of bbn_results.csv. Isolation case F1A_INDEP (41f); isolation passes: remaining miss attributed to model fidelity (method), not code.
**Explanation:** Replay of a recorded result under frozen 23a. Pre-registered FAIL 26/168 used a reversed pair reading. Pair convention φ_b−φ_a from CR-158919 §3.4 (B/A) and Table 8 was found 2026-10-22 after that result; the re-run (134/168, still FAIL) is labelled post-hoc. Criterion 23a unchanged.
Inputs: recorded `bbn_results.csv` from BBN script.
Equations: F1A phase (replayed); criterion 23a.
Outputs: phase [deg]; verdict on 80 % within 15°/35°.

### Case: R996_PHASE
**Title:** Report 996 page-12 phase
**Map / block:** total / A_PHASE
**Category:** experiment
**Kind:** replay
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** Report 996 p.12 text
**What it tests:** F1A phase ahead/behind vs the one measured value 155°.
**Why it is here:** Only measured phase in Report 996.
**A pass means:** within ±15° of 155° (23c).
**Not covered:** One data point; stations ±0.125 used as candidates (report does not name them). The polar set (`polars_phase69_ncrit8.json`) has N_crit 8 fitted to TN 1546 sections 16-506 and 16-509 (Phase 69b), so it is tied to measured section data through that fit (note of 2026-11-10, Phase 141a).
**Recorded outcome:** [older values in this paragraph are superseded; current 112.8°, |Δφ − 155°| = 42.2°, `report996_acoustics.md` 2026-10-28] FAIL 109.0° vs 155° (±15°) after the 2026-10-22 polar re-run (post-hoc; first recorded 103.8°); tr996_phase_values.csv + f1a_results.csv. Isolation case F1A_INDEP (41f); isolation passes: remaining miss attributed to model fidelity (method), not code. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** F1A 113.6° vs 155° (±15°), was 109.0°; still FAIL. **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** still FAIL, error 42° (was 41°).
**Explanation:** Replay of a recorded result: one measured phase 155° (p. 12). Comparison uses ±0.125 x/D as candidates; F1A gives 109.0° (103.8° before the polar re-run). Fails ±15° (23c). Nothing tuned.
Inputs: recorded `tr996_phase_values.csv`, `f1a_results.csv`.
Equations: F1A phase (replayed).
Outputs: phase difference [deg]; verdict within ±15° of 155°.

### Case: PER_FIG7
**Title:** Pereira Fig. 7 waveform — loads scaled to measured thrust and torque
**Map / block:** total / A_FWD
**Category:** experiment
**Kind:** replay
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** Pereira et al. 2026 Fig. 7
**What it tests:** F1A first-harmonic phase shift Δψ₁ vs Fig. 7.
**Why it is here:** Only forward-flight waveform/phase figure under 23d.
**A pass means:** Δψ₁ ±5° (23d).
**Not covered:** Motor noise above H2; far field only.
**Recorded outcome:** replay of pereira_results.csv. Isolation case F1A_INDEP (41f); isolation passes: remaining miss attributed to model fidelity (method), not code. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** 2/3 within ±5° (max error 18°, was 14°); not met. Thrust is now within 1 % of the measured value (69d), so this miss is not from the loads. **Re-run 2026-10-28 (Phase 72, observer fore/aft convention, post-hoc: the earlier results were known; the convention is taken from the source documents, nothing chosen from the residuals):** **1/3** (was 2/3): Δψ₁ +5.5° and +7.3° at φ = 20° and 40° against +11.9° and +19.3°, with the phase sign of the Fig. 7 fit (p = A cos(kBθ − ψ)) matched to ours (Δψ = −Δφ). Pereira's own BEMT gives +7.6° and +22.4°. **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** **met, 3/3** (was 1/3; max error 3.4°).
**Explanation:** Replay of a recorded result: Δψ₁(φ) = ψ₁(φ)−ψ₁(0°) vs Fig. 7 (±5°, 23d). Far field; motor noise above H2.
Inputs: recorded `pereira_results.csv`, `pereira_fig7_harmonics.csv`.
Equations: F1A phase (replayed).
Outputs: Δψ₁ [deg]; verdict ±5°.

### Case: PER_FIG8
**Title:** Pereira Fig. 8 directivity — loads scaled to measured thrust and torque
**Map / block:** total / A_FWD
**Category:** experiment
**Kind:** replay
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** Pereira et al. 2026 Fig. 8
**What it tests:** F1A forward-flight directivity at 1 m.
**Why it is here:** Only forward-flight directivity under 23d.
**A pass means:** H1 within ±1.7 dB and H2 within ±3 dB at every microphone (23d).
**Not covered:** Harmonics above H2 (removed from the case 2026-10-28, author). Loads are scaled to Table 3's measured thrust and torque; as computed they are 0.7 % (thrust) and 3.5 % (torque) above it (`pereira_results.csv`, N_crit 9), so an unscaled line would lie on the scaled one and is not drawn (Phase 141c, 2026-11-11). **Why only H1 and H2:** they carry the propeller's loading and thickness noise, which is what the source block predicts. Above H2 the measurement is not the propeller: Pereira reports motor noise at the 3rd and 6th BPF, the measured H3–H6 sit flat at 40–50 dB while every prediction (ours, Pereira's BEMT, their CFD) falls with harmonic, and the paper reports disagreements above 6 dB for all methods there. A comparison above H2 would test the motor, not the code. Far field only; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** replay of pereira_results.csv (amplitude convention fixed 2026-10-21, post-hoc). Isolation case F1A_INDEP (41f); isolation passes: remaining miss attributed to model fidelity (method), not code. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** H1 3/7, H2 3/7 (6/37 over all rows, was 7/37); not met. **Re-run 2026-10-28 (Phase 72, observer fore/aft convention, post-hoc: the earlier results were known; the convention is taken from the source documents, nothing chosen from the residuals):** H1 **5/7** (was 3/7), H2 3/7. With φ positive downstream (Pereira Fig. 2b) the H1 directivity matches Pereira's own BEMT curve within 0.8 dB at all seven angles. **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** H1 **6/7**, H2 **4/7** (was 5/7, 3/7); not met (median error 3.7 dB over all rows, was 7.0).
**Explanation:** Replay of a recorded result: directivity at 1 m vs Fig. 8 (H1 ±1.7 dB, H2 ±3 dB). Amplitude convention fixed 2026-10-21, post-hoc.
Inputs: recorded `pereira_results.csv`, `pereira_fig8_directivity.csv`.
Equations: F1A (replayed).
Outputs: SPL [dB] vs φ; verdict on H1/H2 tolerances.

### Case: PER_FIG9
**Title:** Pereira Fig. 9 harmonics — loads scaled to measured thrust and torque
**Map / block:** total / A_FWD
**Category:** experiment
**Kind:** replay
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** Pereira et al. 2026 Fig. 9
**What it tests:** F1A forward-flight harmonics at 1 m vs Fig. 9 Exp.
**Why it is here:** Only forward-flight harmonic bar check under 23d.
**A pass means:** H1 ±1.7 dB, H2 ±3 dB (23d).
**Not covered:** Motor noise above H2; far field only; amplitude convention fixed 2026-10-21, post-hoc. Loads are scaled to Table 3's measured thrust and torque; as computed they are 0.7 % (thrust) and 3.5 % (torque) above it (`pereira_results.csv`, N_crit 9), so an unscaled line would lie on the scaled one and is not drawn (Phase 141c, 2026-11-11).
**Recorded outcome:** not_met H1 3/9, H2 6/9; pereira_results.csv (amplitude convention fixed 2026-10-21, post-hoc). Isolation case F1A_INDEP (41f); isolation passes: remaining miss attributed to model fidelity (method), not code. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** H1 3/9, H2 6/9 (unchanged); not met. **Re-run 2026-10-28 (Phase 72, observer fore/aft convention, post-hoc: the earlier results were known; the convention is taken from the source documents, nothing chosen from the residuals):** H1 **0/9** (was 3/9), H2 6/9. The computed H1 is 2.9–4.7 dB above the Fig. 9 bars (80 dB at every angle), while Pereira's Fig. 8 measured H1 at the same angles is 82.5–85.1 dB, so the two figures' measured H1 differ by about 4 dB (open digitization issue I-04). **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** H1 0/9, H2 6/9 (unchanged; Fig. 9's measured H1 is about 4 dB below Fig. 8's, I-04); not met. **Re-run 2026-10-28 (Phase 74a, reference re-digitized, post-hoc):** Fig. 9 re-read from the PDF vector graphics (`dig_pereira_fig9_vector.py`; every ΔSPL bar agrees with the SPL bars within 0.5 dB). The old H1 = 80 dB for all series was a misreading; the measured H1 is 84.22, 84.45, 82.57 dB at φ = 0°, 20°, 40°, equal to Fig. 8 within 0.1 dB. **H1 9/9** (was 0/9; within 0.36 dB), H2 6/9 (misses only at φ = 20°, +3.7 dB, the same point as PER_FIG8); not met.
**Explanation:** Replay of a recorded result: harmonics at 1 m vs Fig. 9. After I-17: H1 3/9 within ±1.7 dB, H2 6/9 within ±3 dB (not met on H1). Amplitude convention fixed 2026-10-21, post-hoc.
Inputs: recorded `pereira_results.csv`, `pereira_fig9_harmonics.csv`.
Equations: F1A (replayed).
Outputs: SPL [dB]; verdict on H1/H2 counts.

### Chunk 2: Free field (`G_FF`)

Blocks in map order: `P_FF` e11 free field → `X_SRC` Source select. Cases are listed block by block, in the order the map shows them.

### Chunk 3: Grid and blocking (`G_GRID`)

Blocks in map order: `P_GRID` 160-point grid → `P_BLK` Blocking Eq. 43 → `X_BLK_OUT` Blocked pressures. Cases are listed block by block, in the order the map shows them.

### Case: BLK_P68
**Title:** Blocking Eq. (43) vs printed p.68 values
**Map / block:** total / P_BLK
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Skin field
**Compared with:** NASA's printed prediction
**Source:** NASA-CR-172428 p.68; CR-3813 Eq. (43)
**What it tests:** That `blocking.jl` reproduces the printed F(γ) / ΔL values on CR-172428 p.68 (code-on-code, not an experiment).
**Why it is here:** Blocking scales every free-field pressure on the skin before the cabin chain.
**A pass means:** Code matches the written equation within 0.06 dB at the p.68 checkpoints (V-UNIT).
**Not covered:** How γ is computed from geometry; physical correctness (scale-model blocking is 3–4 dB near the plane).
**Recorded outcome:** PASS (blocking_p68.md)
**Explanation:** Code-on-code (against printed values): ANOPP/PAIN gives propeller pressure in free space; a rigid fuselage reflects ("blocks") the wave, so skin pressure is larger than free-field. Eq. (43) scales free-field amplitude by Magliozzi's empirical F(γ); phases unchanged. γ = incidence angle between the hub→skin line and the outward normal (0° = head-on, ~+6 dB; 90° = grazing, 0 dB). cos γ uses hub (r, φ, z_p) and skin (a, θ, z) as in CR-3813 §3.4. "P68" values are a printed table of that equation, not a test. R1 = full Eq. (43); R2 = 0.8× amplitude ratio floored at 1 (~4 dB max). Figure: γ vs ΔL with p.68 points and R1/R2 curves.
Inputs: Checkpoint table `BLOCKING_P68_CHECKPOINTS` (γ = 0–90°); variants R1/R2; no geometry (γ given).
Equations: Eq. (43) F(γ)=10^[0.3−0.000224 e^(0.08γ)]; ΔL=20 log10 F; R2 per CR-172428 §5.3.2. Code: `blocking_factor`, `delta_L_blocking_dB`.
Outputs: ΔL [dB] vs p.68; verdict |Δ| ≤ 0.06 dB on all R1 checkpoints.

### Case: E12_BLOCK
**Title:** Fig. E-12 blocked SPL
**Map / block:** total / P_BLK
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Skin field
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-12, p.136
**What it tests:** Eq. (43) R1 applied to ANOPP Table 8 vs NASA's predicted blocked curve on ℓ = 1.
**Why it is here:** Checks blocking on the measured line before GEXT enters.
**A pass means:** Reproduces NASA's prediction within δ_dig + 0.5 = 3.41 dB.
**Not covered:** GEXT; measured circles on the figure are 1–7 dB lower (no pass mark).
**Recorded outcome:** 29/31, two H3 aft points FAIL (e12_blocking.md). **Diagnostic 2026-10-28 (A3b, post-hoc, no verdict; `e12_a3b_linefit.md`):** with both NASA predicted lines read from pixels, Fig. E-11's line equals Table 8 within 1.2 dB, NASA's step E-12 − E-11 is 4.5–7.5 dB at H1/H2 (Eq. 43: 5.7–6.0), and Table 8 + ΔL is within ±1.7 dB of the pixel-read E-12 line at 27 of 28 stations. The one large miss is H3 k10 (+4.9 dB), where NASA's drawn line implies a 2.3 dB step that Eq. (43) cannot give. The verdict stays as recorded. **Phase 143 (2026-11-11, re-run, no verdict since 135f):** the runner now uses the mean of passes A and B, as the criterion says: 29/31, largest 4.3 dB, median 1.1 dB (one number on record). Read from pixels (`phase143_e12_h3_aft.md`): k = 11 is a by-eye chord error (+1.2 dB from pixels, inside the tolerance); k = 10 stays +4.9 dB, where NASA's drawn step (2.3 dB) is smaller than Eq. (43)'s 5.98 dB: NASA's printed curve, not explained by the documents.
**Explanation:** Experiment comparison on the prediction curve (V-CODE vs NASA's predicted E-12): "blocked pressure" is the pressure on a rigid cylinder (Fig. E-12). Free-field ANOPP Table 8 SPLs on ℓ = 1 are raised by R1 ΔL(γ) and compared with the digitized NASA predicted curve. Axes: X3/D vs blocked SPL; panels H1–H3. Measured circles are shown for context only.
Inputs: ANOPP Table 8 CSV; `e12_predicted_A/B.csv`; geometry as E11 (a = 0.508 m, r_p = 0.965 m, φ_p = 90°, z_p = 0.662 m since Phase 65, L = 1.83 m); blocking R1; D = 0.762 m.
Equations: Eq. (43) via `delta_L_blocking_dB`; γ via `incidence_angle_deg`; blocked SPL = free-field SPL + ΔL.
Outputs: blocked SPL [dB] H1–H3; verdict |Δ| ≤ 3.41 dB vs digitized NASA prediction.

### Chunk 4: Structural modes (`G_MRP`)

Blocks in map order: `X_MRP_IN` Structure inputs → `P_MRP` Structural modes → `X_MRP_OUT` Modes f_r, ψ_r. Cases are listed block by block, in the order the map shows them.

### Case: MRP_APPD
**Title:** App. D Eqs. (D.17)–(D.26) vs Table D-1
**Map / block:** total / P_MRP
**Category:** verification
**Kind:** runnable
**Chain span:** Wall modes → Wall modes
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Table D-1 / Fig. D-2; App. D pp. D-3…D-10
**What it tests:** Printed App. D structural solver (no fitted scale) vs Table D-1 frequencies.
**Why it is here:** Any geometry other than the test article needs Eqs. (D.17)–(D.26), not the Table D-1 seed.
**A pass means:** ≥ 75 % of the 32 Table D-1 modes within 5 % of their shape partner: the solver mode of the same symmetry and axial index with the highest MAC ≥ 0.9 against the Table D-1 shape rebuilt from its printed coefficients (shape pairing fixed 2026-10-28, author; count rule 2026-10-22); no calibration input.
**Not covered:** Fig. D-2 shapes reported without a pass mark; production default remains Table D-1 / fitted surrogate.
**Recorded outcome:** **met, 32/32** (current, 2026-10-29, Phase 80; re-run post-hoc: the earlier results were known, nothing chosen or fitted). On NASA's own MRP input deck (User Manual pp. 42–43, `data/cr3813/um_mrp_input_deck.csv`) with the deck's series limits and NASA's floor form (no cross terms between floor terms), the solver reproduces Table D-1: all 32 frequencies within 0.012 %, every mode paired by shape in Table D-1's own order, generalized masses median 0.11 % (max 3.9 %, from NASA normalizing on its printed output grid), Fig. D-2 mode 1 within 0.027. The same solver on the inputs derived from the App. E sections gives 2/32 (information): the derived frame and floor rigidities differ from the deck (frames 4,992 vs 12,007 N·m; floor 6,147 / 13,024 vs 8,630 / 5,426 N·m; L 1.83 vs 1.8034 m). The "class I, floor stiffener model undocumented" record of 2026-10-28 is withdrawn: the deck documents it. Superseded record: **not met, 2/32** (2026-10-28, Phase 78d-4; median |Δf| 9.5 %, max 51 %). History: first run 2026-10-22 recorded **met**, 27/32 within 5 % (84.4 %) by frequency-only matching; Fig. D-2 max \|Δw\| = 1.4534 (info, no pass mark). First run 2026-10-22 (`mrp_appd_vs_d1.md`). **Audit 2026-10-28 (Phase 78):** this pass is an artifact of frequency-only matching (the solver has 61 modes below 820 Hz against Table D-1's 32); matched by mode identity the solver gives 2/32 within 5 %, 20–70 % low. The criterion moves to identity matching in Phase 78a. **Re-run 2026-10-28 (Phase 78a, identity criterion fixed before its first run):** **not met, 2/32** (19 Table D-1 modes have no solver mode of the same identity; frequency-only count 31/32, information). Isolation (78b): the shell and floor operators are exact against closed forms; the stiffener inertias drop the channel flanges (frames and floor beams 3.7× too soft) and the floor stiffness is isotropic. Fix plan 78c. **Re-run 2026-10-28 (Phase 78d F1–F2, inputs corrected from App. E, post-hoc):** still **not met, 2/32**; lowest solver mode 170.8 Hz (was 115; Table D-1 188.5), 39 modes below 820 Hz (was 61; Table D-1 32). Remaining leads in 78d-2. **Re-run 2026-10-28 (Phase 78d-3, author: pairing by shape, MAC ≥ 0.9; floor beams about the floor mid-plane, V1; post-hoc):** **not met, 2/32**; 7 of 32 Table D-1 modes have a solver mode of the same shape, 25 have none (identity 4/32, frequency-only 15/32, information). Next: junction constraints and the antisymmetric family (78d-3 c). **Re-run 2026-10-28 (Phase 78d-4, App. D consistency fixes J1–J6 from Fig. D-1 and pp. D-1–D-4, not fitted; post-hoc):** the returned shapes are converted to App. D's convention (θ from the top, floor upward), the shell spans the whole circumference (closed cylinder with an interior floor), the identically-zero n = 0 functions and the frequency dedup are removed, and the antisymmetric floor gets its uniform sway term and the membrane shear coupling. **Not met, 2/32** (median |Δf| 9.5 %, max 51 %); 10 Table D-1 modes have a shape partner (was 7), hinged 12 (information). The symmetric floor-dominated modes match in shape (MAC 0.98–1.00) but not in frequency; 14 of the 16 antisymmetric modes and the m = 1 floor modes have no partner. The floor frequencies depend on how the floor beams and supports act, which App. D leaves at "classical plate theory": recorded as an input limitation (§2.14 class I); no further solver change without a documentary basis.
**Explanation:** Code-on-code (against printed values / NASA solver outputs): implements App. D constraints D.17–D.21, constitutive D.23–D.24, operator D.25, eigenproblem D.22, shapes D.26–D.29 with physical geometry from App. E / Manual §5.2. No parameter fitted to Table D-1. Label V-CODE; first run 2026-10-22.
Inputs: `appd_nasa_deck()` (NASA's MRP deck, User Manual pp. 42–43, from 2026-10-29; was `appd_test_article_geometry()`); n_modes=80, M 1–10, ns 0–12, np 0–5 (the deck's card 8; was 7, 8, 5); `floor_cross_terms=false` (NASA's form); tol_frac=0.05; MAC ≥ 0.9 shape pairing (`match_modes_by_shape`); count rule ≥75 % of 32.
Equations: App. D (D.17)–(D.26); code `appd_modes` in `mrp_appd.jl`.
Outputs: f [Hz] vs Table D-1; M_r vs Table D-1 TOTAL MASS (info); Fig. D-2 shape residuals (info); the count on derived App. E inputs (info); verdict on count rule.

### Chunk 5: CYL2D (`G_CYL`)

Blocks in map order: `X_CYL_IN` Cabin geometry → `P_CYL` CYL2D → `X_CYL_OUT` Modes Φ_G. Cases are listed block by block, in the order the map shows them.

### Case: CYL2D_C1
**Title:** CYL2D vs Table C-1 / Fig. C-3
**Map / block:** total / P_CYL
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Cabin modes
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Table C-1, Fig. C-3
**What it tests:** Appendix C cabin acoustic mode scheme (ratios, Φ_G, symmetry, Fig. C-3 nodes).
**Why it is here:** Cabin modes set resonances and coupling into Eq. (8).
**A pass means:** App. C implemented as written: ratios, generalized mass Φ_G, symmetry, Fig. C-3 nodes.
**Not covered:** c0 = 341 m/s back-solved from the table; absolute frequencies partly by construction; not an experiment.
**Recorded outcome:** met (cyl2d_table_c1.md)
**Explanation:** Code-on-code (against printed values): `cyl2d_modes` implements App. C. Frequency ratios f_i/f_1 (c0-free), Φ_G, symmetry vs Table C-1; Fig. C-3 nodes in Pkg.test. Sound speed c0 = 341 m/s was back-solved from the table. Not an experiment.
Inputs: θ0 = 56.6°, NY = 10, c0 = TABLE_C1_C0 = 341 m/s, n_modes = 20.
Equations: App. C scheme in `cyl2d.jl` (`cyl2d_modes`).
Outputs: f [Hz], f/f1 [-], Φ_G [-], symmetry flags; verdict on ratios ≤0.1 %, Φ_G ≤0.1 %, symmetry equal.

### Chunk 6: Trim and loss (`G_TRIM`)

Blocks in map order: `X_TRIM_IN` Trim stack → `P_TRIM` Trim and loss → `X_TRIM_OUT` τ, η. Cases are listed block by block, in the order the map shows them.

### Case: UT_TRIM
**Title:** Trim / loss (Pkg.test)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** pkgtest
**Chain span:** Damping and trim → Damping and trim
**Compared with:** verification
**Source:** CR-3813 App. A, §3.8
**What it tests:** Trim transfer matrices, joint acceptance, and loss-factor helpers in `trim_loss.jl`.
**Why it is here:** Trim and losses set every modal amplitude in the cabin chain.
**A pass means:** Exact limits, det = 1, passivity, quadrature agreement in Pkg.test.
**Not covered:** No NASA coupon numbers for τ_t; curve check is E14_LOSS. No GUI figure — algebraic unit checks, not a spatial field (cheap plot would not add information).
**Recorded outcome:** Pkg.test pass ("App. A trim", "Loss factors")
**Explanation:** Unit test (Pkg.test only, no figure): App. A trim matrices and §3.8 loss helpers. Covered by Pkg.test titles "App. A trim" and "Loss factors". NASA curve comparison is E14_LOSS / E15_STRUCT_LOSS.
Inputs: not run in the GUI registry; exercised in Pkg.test with synthetic stacks / App. A limits.
Equations: App. A (A.10)–(A.22), Eqs. (63)–(83) helpers in `trim_loss.jl`.
Outputs: matrix determinants, passivity, quadrature residuals in Pkg.test; no registry verdict.

### Case: E14_LOSS
**Title:** Fig. E-14 loss factor
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Damping and trim → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-14, p.139
**What it tests:** Eq. (78) band-average acoustic loss η̄ vs NASA's calculated Fig. E-14 curves.
**Why it is here:** Only NASA-calculated loss curve available for the acoustic-loss path.
**A pass means:** Within ±25 % of NASA's calculated η̄.
**Not covered:** E-13 has no calculated curve; not tuned when criterion fails.
**Recorded outcome:** 7/18 bands, not met (trim_loss_e13_e14_e15.md). Isolation case TRIM_CLOSED (41b); isolation passes: remaining miss attributed to model fidelity (method), not code. **No verdict since 2026-11-12 (ISSUE-037, input rule):** the side the facing sits on and the end-plate backing are not printed, and the loss factor moves with them by up to 8.5 % and 43 %; the outcome 7/18 is kept on record.
**Explanation:** Code-on-code (against NASA calculated curve): Eq. (78) band-average loss with App. A trim conductance ξ vs digitized NASA calculated Fig. E-14. Axes: band Hz (log) vs loss factor (log). Recorded 7/18 within ±25 % — often not met; not tuned.
Inputs: `e14_acoustic_loss_calculated.csv`; `phase3_trim(; η_lining=0.5)`; a = 0.508 m, L = 1.83 m, θ0 = 56.6°; c0 = 340 m/s, ρ0 = 1.225.
Equations: Eq. (78) via `acoustic_loss_average`; trim conductance via `trim_conductance`.
Outputs: η̄ [-] per band; verdict ±25 % vs NASA η_T = 0.5 curve.

### Case: E15_STRUCT_LOSS
**Title:** Fig. E-15 η_r′ (struct. loss)
**Map / block:** total / P_TRIM
**Category:** experiment
**Kind:** runnable
**Chain span:** Wall modes → Damping and trim
**Compared with:** measurement
**Source:** CR-3813 Fig. E-15, p.E-25 / PDF p.141
**What it tests:** Total structural loss factor η_r′ of Eq. (82) with Phase III trim vs measured E-15.
**Why it is here:** Measured total structural loss vs frequency (with trim).
**A pass means:** — (V-EXP info; no pass mark, as 16b)
**Not covered:** No frozen pass criterion; quantity is η_r′ (with trim), not bare η_r.
**Recorded outcome:** first run 2026-10-22; 4/8 within tol_frac (info); e15_structural_loss.md (no_verdict). Isolation case TRIM_CLOSED (41b); isolation passes: remaining miss attributed to model fidelity (method), not code.
**Explanation:** Experiment comparison (info only): Fig. E-15 plots measured and predicted total structural loss with trim-loss curves at 0.5 and 1.0 and an upper-limit line at 0.15 — that is η_r′ of Eq. (82), not bare η_r. Uses Phase III trim η_T = 1.0 and η_r_cap = 0.15 (E-18/E-21 setting, p. E-30). Verdict always `:no_verdict`.
Inputs: `e15_structural_loss_targets.csv`; `phase3_trim` with η_lining = 1.0; η_r_cap = 0.15; L = 1.83 m, a = 0.508 m, θ0 = 56.6°.
Equations: Eq. (82) η_r′ in `trim_loss.jl` / structural-loss helpers.
Outputs: η_r′ [-] vs measured; info counts within CSV tol_frac; verdict `:no_verdict`.

### Case: R172428_ETA
**Title:** CR-172428 structural loss factors η_r′ vs App. B (44c/44d)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Wall modes → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** NASA CR-172428 App. B p. 194 (η_r′ of the first 32 structural modes); sub-criterion of 44d dated 2026-10-23
**What it tests:** η_r′ of Eq. (82) with the App. A trimmed-area modal mass (m̄_r = m M_r / M_r^X, M_r^X = shell bending generalized mass, ETASTR GMASS(IR,2)) and Table 6 inputs, mode by mode, against NASA's printed list.
**Why it is here:** The η_r′ correction is the documented change between CR-3813 and CR-172428; this checks that it is implemented as NASA programmed it.
**A pass means:** η_r′ of each listed mode within ±25 % of App. B. Diagnostic hypothesis of Phase 139b (fixed by the author 2026-11-09, before any run; entered here 2026-11-10 before the run): Eq. (82) with ω and the trim conductance at the nominal 1/3-octave centre holding each mode is supported if at least 24 of the 32 modes are then within ±25 %. The criterion above does not change.
**Not covered:** Modes above 811 Hz.
**Recorded outcome:** **not_met**, 17/32 within ±25 % (first run 2026-10-23). Modes 1–12 agree within 13 % (several within 1 %); modes 13–32 are 30–50 % low. Without the App. A correction, the floor modes come out 10–180 times too high. Our M_r^X matches App. B's printed "SHELL W": median 0.19 %, at most 3.8 % over the 21 modes above 0.05 kg (Table D-1 prints five shell terms per mode) (unit test). **Re-run 2026-11-12 after the ISSUE-032 fix (post-hoc):** 32/32 within ±25 % (all within 6 %): a card η_r is η_r^struc only and Eq. (81)'s radiation loss is added (CR-3813 p. 42; User Manual §5.4.3). **No verdict since then:** the error was located by comparing with App. B, this case's data (independence rule); first run not met 17/32 (`issue032_structural_loss_card.md`).
**Explanation:** `app_a_modal_mass_per_area`, `trimmed_modal_mass` in `pain_core.jl`; enabled by `PainInputs(...; η_r_trimmed_area=true)` (default false = CR-3813 printed Eq. (82)).
Inputs: Table D-1 modes; Table 6; App. B trim.
Equations: Eq. (82) with m̄_r (CR-172428 p. 177).
Outputs: η_r′ per mode, relative difference.

### Case: R172428_TRIM
**Title:** CR-172428 trim factor / admittance vs App. B (diagnostic)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Damping and trim → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** NASA CR-172428 App. B p. 197; no criterion (the comparison was first made 2026-10-23 without one fixed beforehand)
**What it tests:** The trim transfer-matrix model (`trim_tau`, `trim_admittance`) with NASA's printed trim inputs, against NASA's printed trim factor and admittances, 100–5000 Hz.
**Why it is here:** An independent code check of the trim block on a different stack than CR-3813's Phase III trim.
**A pass means:** No criterion (always `:no_verdict`).
**Not covered:** Bands below 50 Hz (since Phase 100 the deck table runs from 50 Hz; Fig. A-2 starts at 100 Hz).
**Recorded outcome:** diagnostic: trim factor within 0.15 dB of NASA at 250–1000 Hz, 1.65 dB at the 200 Hz trim resonance, up to 2.1 dB at 1.25–5 kHz; sidewall admittance within a few percent away from the resonance (first run 2026-10-23). With NASA's per-band deck table (Phase 100, 2026-10-30): trim factor within 0.001 dB at all 18 bands 100–5000 Hz, 200 Hz included.
**Explanation:** Sidewall stack `[InsulationLayer(0.0508, PF105), LimpMass(1.456, 0.13)]`, end cap `[InsulationLayer(0.0127, PF105), LimpMass(0, 1)]`, m_wall = 3.113 kg/m².
Inputs: App. B p. 197.
Equations: App. A trim matrices.
Outputs: trim factor [dB] and admittance per band.

### Chunk 7: PAIN main (`G_PAIN`)

Blocks in map order: `X_PAIN_IN` Cabin inputs → `P_EQ8` Coupling / Eq. 8 → `X_OUT` Interior SPL. Cases are listed block by block, in the order the map shows them.

### Case: UT_EQ8
**Title:** Eq. (8) coupling + HF tones (Pkg.test)
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** pkgtest
**Chain span:** Interior tones → Interior tones
**Compared with:** verification
**Source:** CR-3813 Eqs. (8), (11)–(16), (41)–(42), (52)
**What it tests:** Core coupling, Ψ_G, tone sum, and high-frequency tone expected-value path.
**Why it is here:** Every tonal SPL goes through this sum; 38b adds the high-frequency expected value.
**A pass means:** Analytic limits, scaling laws, independent re-implementation within 2e-3; E[g] closed=quad 1e-8; default `:eq8` matches baselines.
**Not covered:** No NASA Ψ_G or p² numbers for V-UNIT; REPRO_18b `:auto` is a recorded comparison, not this pkgtest. No GUI figure — scalar/analytic unit checks (not a spatial field).
**Recorded outcome:** Pkg.test pass ("Generalized force", "Eq. (8) tone pressure", "High-frequency tones Eqs. (11)–(16) (38b)")
**Explanation:** Unit test (Pkg.test only, no figure): coupling f′, joint acceptance Ψ_G, Eq. (8) tone mean-square pressure, and 38b Eqs. (11)–(16). Default production remains `tone_model=:eq8`.
Inputs: synthetic / baseline cases inside Pkg.test; not a registry GUI run.
Equations: Eqs. (8), (11)–(16), (41)–(42), (52) in `pain_core.jl`, `high_freq_tones.jl`.
Outputs: Pkg.test residuals only; no registry verdict.

### Chunk 8: Validation comparisons (`G_VAL`)

Blocks in map order: `P_REPRO` vs NASA PAIN → `P_MEAS` vs measurement → `A_CABIN` Aircraft cabin. Cases are listed block by block, in the order the map shows them.

### Case: NR_TP1964_XOVER_REF2
**Title:** TP-1964 NR with changeover vs NASA ref. 2 (45b)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** NASA's printed prediction
**Source:** NASA TP-1964 Fig. 8 predicted curve (ref. 2); criterion pre-registered 2026-10-23 (plan §8c)
**What it tests:** As NR_TP1964_XOVER, against NASA's predicted curve.
**Why it is here:** It is a code comparison for the same path.
**A pass means:** Within ±3 dB in ≥ 75 % of the bands 100–5000 Hz.
**Not covered:** As NR_TP1964_XOVER. NASA's curve is CR-159363's final Phase I prediction (Fig. 34, PDF pp. 140–146), and three of its inputs are not printed as numbers: the (1,1) structural mode left out, the closely coupled modes moved apart (no amount given) and the radiation damping raised at 630–1250 Hz (no value given). No verdict under the input rule (Phase 138b, 2026-11-10; `validation_reports/phase138_ref2_inputs.md`).
**Recorded outcome:** **not_met**, 8/18 (first run 7/18 with the band-matching error); the Eq. (19) bands 3/4 within ±3 dB.
**Explanation:** Shared with NR_TP1964_XOVER.
Inputs: as NR_TP1964_XOVER.
Equations: as NR_TP1964_XOVER.
Outputs: NR per band [dB].

### Case: E22_HF_CODE
**Title:** High-frequency NR, this code vs NASA's E-22 prediction (61d)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-22 NASA prediction and measured mean; criterion fixed 2026-10-23
**What it tests:** Eqs. (19)–(23) against NASA's printed high-frequency NR, next to the measurement.
**Why it is here:** It is the evidence behind attributing T2's high-frequency gap to the method.
**A pass means:** |Δ| ≤ 3 dB of NASA in ≥ 75 % of the bands 1250–2500 Hz.
**Not covered:** NASA's 1983 high-frequency routine is not printed.
**Recorded outcome:** **not_met**, 1/4 (2026-10-23): code − NASA +7.7, +2.1, −6.5, −5.6 dB; NASA − measured +32.5, +33.5, +43.5, +37.0 dB. Phase 93 default form (2026-10-29): not met, 1/4.
**Explanation:** Code-on-code. `hf_pressure_ratio`, E-21 inputs.
Inputs: E-22 data; E-21 inputs.
Equations: Eqs. (19)–(23).
Outputs: NR [dB].

### Case: R172428_CODE
**Title:** CR-172428 reproduction: NASA's inputs vs NASA's printed predictions (44d; CR-3813 printed form)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** NASA CR-172428 App. B (blocked field pp. 198–210, predictions p. 206) and Table 10; criterion dated 2026-10-23 before any transcription or run
**What it tests:** This code's cabin chain run on NASA's own inputs, compared with what NASA's program printed for the same inputs. Inputs: the printed App. B blocked pressure field on the 16 × 19 grid PAIN used (as input, so no GEXT and no blocking model), Table 6 and the App. B trim page, the App. A η_r′ correction.
**Why it is here:** It is the cleanest code-on-code test of the cabin chain on the test article. CR-3813's own E-17/E-18 runs came from the program before NASA's App. A corrections.
**A pass means:** Within ±3 dB of NASA's printed prediction at ≥ 7 of the 9 points (3000/4000/5000 rpm, H1–H3).
**Not covered:** NASA used 300 structural and 400 acoustic modes; this run uses the 32 Table D-1 modes (the same first 32 as App. B) and 20 CYL2D cross-section modes. Phases of rows at the page edge are missing (p. 198 L = 1–2 and L = 3 k = 16, p. 200 L = 1, p. 204 L = 1, p. 208 L = 1); those cells are left out (amplitudes 30–40 dB below the peak).
**Recorded outcome:** **not_met**, 3/9 within ±3 dB (first run 2026-10-23). Ours − NASA: 3000 rpm +5.0 / +2.8 / +1.1 dB; 4000 rpm +8.6 / −3.5 / +2.6 dB; 5000 rpm +3.1 / +7.6 / +3.5 dB. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 4/9 within ±3 dB (3000: 71.07 / 69.02 / 62.66; 4000: 102.45 / 80.05 / 71.69; 5000: 90.35 / 94.40 / 78.40 dB). The 4000 rpm H2 and H3 now agree with NASA (+1.9, +0.4 dB); H1 is dominated by the (0,1) × mode 8 pair (open item Q22). **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** not met, 5/9 (was 4/9).
**Explanation:** `r172428_inputs(rpm)`: L = 1.803 m, L_c = 1.829 m, shell mass 3.113 kg/m², r_p = 0.9652 m, z_p = 0.662 m, rotation +1; bare η_r = 2/f per band; sidewall trim of PF105 0.0508 m with a 1.456 kg/m² panel and η = 0.13, end caps of PF105 0.0127 m with no panel; no mechanical path; c₀ = 343 m/s (from the printed axial mode 93.78 Hz = c₀/2L_c); `η_r_trimmed_area = true`. The field is `data/cr172428/appB_<rpm>rpm_H<H>.csv`.
Inputs: App. B blocked field; Table 6; App. B p. 197 trim.
Equations: Eq. (8) on the 16 × 19 grid; App. A Eq. (82) with m̄_r; Eq. (83) with the bare f′.
Outputs: 9 interior tone levels [dB] next to NASA's printed values; verdict vs ±3 dB at ≥ 7/9.

### Case: R172428_DBA_CODE
**Title:** CR-172428 tonal dB(A): NASA's inputs vs NASA's printed predictions (124; CR-3813 printed form)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** NASA's printed prediction
**Source:** NASA CR-172428 App. B p. 206 and Table 10 (NASA's printed predictions, H1–H3 at 3000/4000/5000 rpm); criterion fixed 2026-11-04 before the first run (Phase 124)
**What it tests:** The tonal dB(A), the A-weighted energy sum of H1–H3 (A-weight at each tone's frequency), of R172428_CODE's run (NASA's inputs, CR-3813 tone sum) against the same sum of NASA's printed prediction. Author 2026-11-04: "i just need a dba comparison against pains own output and an experimental".
**Why it is here:** It is the only dB(A) that can be compared with what NASA's PAIN printed: CR-172428 prints PAIN's predicted interior tones for the test article; for the Commander 695A no PAIN output exists.
**A pass means:** Within ±3 dB(A) of NASA's printed sum at each of the 3 rpm (±3 dB copied unchanged from R172428_CODE). Disclosure: the H1–H3 levels were seen in R172428_CODE (2026-10-23 onward); the dB(A) sums were not computed before this case.
**Not covered:** H4+ (NASA prints them at 4000 rpm only) and broadband; the mode truncation of R172428_CODE.
**Recorded outcome:** **not_met**, 0/3 (first run 2026-11-04). This code − NASA PAIN: 3000 rpm +3.2 (64.2 vs 61.0), 4000 rpm +12.4 (94.2 vs 81.8), 5000 rpm +4.2 dB(A) (92.6 vs 88.4); the 4000 rpm H1 of the CR-3813 tone sum is 13 dB over NASA's. Post-hoc, no verdict: the code's default form (R172428_DBA_EXP's run) is within 0.9 dB(A) of NASA's printout at all 3 rpm (61.9 / 82.0 / 88.7); that form was inferred from these printouts (Phase 93), so the agreement is not independent.
**Explanation:** `_run_r172428_dba(:code)` and `tonal_dBA` in `validation_case_iso44.jl`, on `_r172428_levels` (shared with R172428_CODE).
Inputs: as R172428_CODE; `data/cr172428/appB_predictions.csv`.
Equations: as R172428_CODE; dB(A) = 10 log₁₀ Σ_H 10^((L_H + A(f_H))/10).
Outputs: 3 tonal dB(A) [dB(A)] next to NASA's; verdict vs ±3 dB(A) at each rpm.

### Case: R172428_DB_CODE
**Title:** CR-172428 tonal dB (unweighted): NASA's inputs vs NASA's printed predictions (124; CR-3813 printed form)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** NASA's printed prediction
**Source:** As R172428_DBA_CODE; criterion fixed 2026-11-04 before its first run (Phase 124; author 2026-11-04: "i think you need both")
**What it tests:** The unweighted interior tonal level, the energy sum of H1–H3 in dB re 20 µPa, of R172428_CODE's run against the same sum of NASA's printed prediction.
**Why it is here:** The dB twin of R172428_DBA_CODE: the interior level without the A-weight, which de-emphasizes H1.
**A pass means:** Within ±3 dB of NASA's printed sum at each of the 3 rpm (±3 dB copied unchanged from R172428_CODE). Disclosure: the H1–H3 levels and this phase's dB(A) sums were seen first.
**Not covered:** As R172428_DBA_CODE.
**Recorded outcome:** **not_met**, 0/3 (first run 2026-11-04). This code − NASA PAIN: 3000 rpm +4.8 (73.4 vs 68.6), 4000 rpm +13.0 (105.0 vs 91.9), 5000 rpm +4.3 dB (96.7 vs 92.5). Post-hoc, no verdict: the default form is within 0.7 dB of NASA's sum (69.3 / 92.0 / 92.7; inferred from these printouts in Phase 93).
**Explanation:** `_run_r172428_dba(:code; weighted=false)` in `validation_case_iso44.jl`.
Inputs: as R172428_CODE.
Equations: as R172428_CODE; L = 10 log₁₀ Σ_H 10^(L_H/10).
Outputs: 3 tonal levels [dB] next to NASA's; verdict vs ±3 dB at each rpm.

### Case: E21_E22_NR
**Title:** Figs. E-21 / E-22 NR
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** measurement
**Source:** CR-3813 Figs. E-21, E-22, p.149
**What it tests:** Cabin noise reduction NR vs NASA E-21 prediction and E-22 measured confidence limits.
**Why it is here:** Held out of any calibration (23e); first runnable NR check (38a).
**A pass means:** |NR−NASA|≤3 dB at ≥75% of counted bands and NR inside E-22 95% at ≥75% (criterion dated 2026-10-21).
**Not covered:** 80–160 Hz excluded (end-plate V-ASSUMED); counts below crossover only.
**Recorded outcome:** first run 2026-10-21; V-CODE / V-EXP counts below crossover not met (`e21_e22_noise_reduction.md`); held out of calibration (23e). Isolation case NR_BAND_HAND (41c); isolation passes: remaining miss attributed to model fidelity (method), not code. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** V-CODE 0/4, V-EXP 1/4, E-21 range 3/4 (E-21/E-22 are pre-correction runs). Phase 93 default form (2026-10-29): not met, 5/35.
**Explanation:** Experiment comparison: noise reduction NR = 10 log10(⟨p_e²⟩/⟨p_i²⟩) from Eqs. (17)–(18) with Phase III trim η_T = 1.0 and η_r_cap = 0.15 (p. E-30). Compared with NASA E-21 prediction and E-22 95 % limits. Axes: band Hz vs NR [dB].
Inputs: `noise_reduction_test_article_inputs(; η_lining=1.0)`; η_r_cap = 0.15; CSVs `e21_noise_reduction_range.csv`, `e22_noise_reduction_ci.csv`; L = 1.83 m.
Equations: Eqs. (17)–(18) via `noise_reduction_band` / `noise_reduction_spectrum`.
Outputs: NR(band) [dB]; verdict on NASA and E-22 fraction rules.

### Case: T1_APPB
**Title:** T1 on CR-172428 App. B's printed field (119)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** measurement
**Source:** CR-3813 Fig. E-16 (measured mean and envelope; NASA's prediction for gate B); CR-172428 App. B printed pp. 193–195 (blocked field, 4000 rpm, H1–H3); form and criterion fixed 2026-11-02 (plan §8bi, commit 84dbb27)
**What it tests:** T1's cabin as it ships (CR-3813's cabin, Phase III trim η_T = 0.5, Table D-1 modes) driven by the blocked field PAIN used for the same article, propeller and rpm, printed at all 16 × 19 points, in place of E-11's line + GEXT.
**Why it is here:** Phase 118a took T1 off the map because its off-line field is GEXT's assumption; App. B is the one printed field for this article and condition (Phase 118b).
**A pass means:** T1's gate unchanged (2026-10-20): each of H1–H3 within ±4 dB of the E-16 measured mean (gate A), or inside the envelope and within ±4 dB of NASA's E-16 prediction (gate B).
**Not covered:** Not held out in full: CR-172428's 4000 rpm measurements are E-16's means, and R172428_EXP has set App. B's field against them with CR-172428's cabin. Gate B compares with NASA's E-16 prediction, whose own field is not printed.
**Recorded outcome:** **met** 3/3 (first run 2026-11-02): H1–H3 = 88.51, 75.32, 65.36 dB against 90.0, 80.0, 65.0 dB; H1 and H3 by gate A (−1.49, +0.36 dB); H2 by gate B only (−4.68 dB from the measured mean, −0.18 dB from NASA's 75.5 dB). On E-11 + GEXT (T1, no verdict) H3 is 77.0 dB.
**Explanation:** `_run_t1_appb` in `validation_case_iso119.jl`: `t1_appb_inputs(inp)` swaps amplitudes, phases, points and ΔA for App. B's (`r172428_appb_field(4000)`, both quarters as printed, no blocking applied); everything else is T1's.
Inputs: `data/cr172428/appB_4000rpm_H1–H3.csv`; `t1_interior_targets.csv`; T1's cabin and trim.
Equations: Eq. (8), (42).
Outputs: H1–H3 [dB]; verdict on T1's gate.

### Case: T1_MEAS_DAMPING_APPB
**Title:** T1 with measured damping on App. B's printed field (119)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** measurement
**Source:** as T1_APPB, with CR-3813 Figs. E-13 / E-15 (measured η_n, η_r′); form and criterion fixed 2026-11-02 (plan §8bi, commit 84dbb27)
**What it tests:** T1_MEAS_DAMPING's inputs (measured η_n from E-13, measured η_r′ from E-15) on App. B's printed field.
**Why it is here:** As T1_APPB, with the damping model replaced by the measurements.
**A pass means:** T1's gate unchanged, as T1_APPB.
**Not covered:** As T1_APPB.
**Recorded outcome:** **met** 3/3 (first run 2026-11-02): H1–H3 = 90.06, 78.74, 65.80 dB, all three by gate A (+0.06, −1.26, +0.80 dB from the measured mean). On E-11 + GEXT (T1_MEAS_DAMPING, no verdict) H3 is 78.6 dB.
**Explanation:** `_run_t1_meas_damping_appb` in `validation_case_iso119.jl`.
Inputs: as T1_APPB plus `e13_absorption_targets.csv`, `e15_structural_loss_measured_all.csv`.
Equations: Eq. (8); η_n from p. E-21; measured η_r′ override.
Outputs: H1–H3 [dB]; verdict on T1's gate.

### Case: NR_TP1964
**Title:** TP-1964 bare-cylinder NR vs measured (43d)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** measurement
**Source:** NASA TP-1964 Fig. 8 measured; Figs. 8/17 digitized; criterion dated 2026-10-23
**What it tests:** Eqs. (17)–(18) noise reduction of an independent bare closed cylinder (Donnell shell + exact circular cavity; η from measured T₆₀) vs measured NR.
**Why it is here:** Independent V-EXP of the high-frequency transmission path (no CR-3813 trim/floor); supports T2 when exterior broadband is unmeasured (43e).
**A pass means:** Within ±5 dB in ≥ 75 % of 1/3-octave bands 100–5000 Hz vs measured.
**Not covered:** Floored/trimmed cabin; propeller exterior field; Eq. (18) used to 5 kHz without the high-frequency crossover (modal formula only).
**Recorded outcome:** **not_met**, 6/18 (33.3%) within ±5 dB (2026-10-23; first run 2026-10-23 had NR = +Inf at 100–160 Hz from a 4× band mode window (code defect, fixed the same day: every computed mode enters each band sum; criteria unchanged); first run 5/18). Computed NR is 3–11 dB below measured at 1–3.15 kHz (negative NR) and 13.6 dB high at 5 kHz.
**Explanation:** Bare aluminium cylinder R = 0.252 m, L = 1.193 m, t = 1.63 mm; Donnell–Mushtari SS modes; exact Bessel cavity modes; full-circle coupling; η_n / η_r from Fig. 17 (η = 2.2/(f T₆₀), log-log). Compared to Fig. 8 measured.
Inputs: `tp1964_fig8_noise_reduction.csv`; `tp1964_fig17_reverberation.csv`; `circular_cavity.jl`.
Equations: Eqs. (17)–(18) via `noise_reduction_band_circular`.
Outputs: NR(band) [dB]; fraction within ±5 dB; verdict.

### Case: NR_TP1964_REF2
**Title:** TP-1964 bare-cylinder NR vs NASA pred. (43d)
**Map / block:** total / P_MEAS
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** NASA's printed prediction
**Source:** NASA TP-1964 Fig. 8 predicted (ref. 2); criterion dated 2026-10-23
**What it tests:** Same bare-cylinder NR computation vs NASA's printed predicted curve on Fig. 8 (V-CODE).
**Why it is here:** Code-on-code check of the circular NR path against NASA's Phase I prediction on the same figure.
**A pass means:** Within ±3 dB in ≥ 75 % of bands 100–5000 Hz vs NASA ref. 2.
**Not covered:** Same geometry limits as NR_TP1964; not a measurement comparison. NASA's curve is CR-159363's final Phase I prediction (Fig. 34, PDF pp. 140–146), and three of its inputs are not printed as numbers: the (1,1) structural mode left out, the closely coupled modes moved apart (no amount given) and the radiation damping raised at 630–1250 Hz (no value given). No verdict under the input rule (Phase 138b, 2026-11-10; `validation_reports/phase138_ref2_inputs.md`).
**Recorded outcome:** **not_met**, 6/18 (33.3%) within ±3 dB (2026-10-23; first run 2026-10-23 had NR = +Inf at 100–160 Hz from a 4× band mode window (code defect, fixed the same day: every computed mode enters each band sum; criteria unchanged); first run 4/18)
**Explanation:** Identical computation to NR_TP1964; reference column is Fig. 8 dashed (NASA CR-159363 Phase I / ref. 2).
Inputs: same CSVs as NR_TP1964.
Equations: Eqs. (17)–(18) via `noise_reduction_band_circular`.
Outputs: NR(band) [dB]; fraction within ±3 dB; verdict.

### Case: NR_TP1964_XOVER
**Title:** TP-1964 bare-cylinder NR with PAIN's changeover to Eqs. (19)–(23) (45a)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** measurement
**Source:** NASA TP-1964 Fig. 8 (measured NR) and Fig. 17 (reverberation → η); criterion pre-registered 2026-10-23 before any run (plan §8c, commit 9ffb107)
**What it tests:** The high-frequency cabin path used by T2, Eqs. (19)–(23), on an independent experiment. Eq. (18) is used below the card-10 changeover band (f = 4.1 c₀/∛V = 2269 Hz, in the 2500 Hz band) and Eqs. (19)–(23) at and above it; same inputs as NR_TP1964.
**Why it is here:** T2 cannot be checked end to end (no measured exterior broadband of the test article, 43e); this tests its cabin transmission block.
**A pass means:** Within ±5 dB of the measured NR in ≥ 75 % of the 1/3-octave bands 100–5000 Hz.
**Not covered:** Floored or trimmed cabins at high frequency; the exterior broadband input of T2.
**Recorded outcome:** **not_met**, 9/18 within ±5 dB. The four Eq. (19) bands (2.5–5 kHz) are all within ±2.5 dB (4.1, 3.6, 8.0, 12.8 dB against 6.0, 4.5, 6.9, 10.3 measured); the misses are Eq. (18) bands (1–2 kHz NR negative, 100–315 Hz). The first run of the same day (8/18) left the 2500 Hz band on Eq. (18) because of a band-centre matching error (2520 vs 2500 Hz); it was fixed per the written rule, with the criterion unchanged.
**Explanation:** `tp1964_hf_inputs` builds the bare cylinder as a PAIN cabin (θ₀ = 0, no trim, Donnell modes, measured η); `hf_pressure_ratio` gives Eq. (23).
Inputs: TP-1964 Figs. 8 and 17; geometry as NR_TP1964.
Equations: Eq. (18) below, Eqs. (19)–(23) at/above the changeover.
Outputs: NR per band [dB].

### Case: NR_PROP_TP2444
**Title:** TP-2444 model 2: measured propeller-noise NR vs model (47c)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** measurement
**Source:** NASA TP-2444 Fig. 17 (exterior and interior narrowband spectra of this test article, 4000 rpm), digitized 2026-10-23; criterion fixed 2026-10-23 before any run (plan Phase 47)
**What it tests:** The noise reduction of the test article under propeller excitation. Measured: exterior minus interior broadband 1/3-octave level, tones removed, B = 5 Hz assumed. Model: Eq. (18) below the card-10 changeover (1260 Hz band) and Eqs. (19)–(23) at and above it, with the CR-172428 App. B trim.
**Why it is here:** It is the first test of the cabin transmission with this article's own measured exterior and interior.
**A pass means:** Within ±5 dB in ≥ 75 % of the broadband bands 315–1250 Hz.
**Not covered:** TP-2444 p. 8 prints the lining (four 13 mm fiberglass layers of 0.27 kg/m² with a 0.05 mm vinyl film, a 0.81 mm epoxy-fiberglass finish sheet, floor bare) but not the fiberglass's acoustic table. CR-172428 §3.1.2 p. 16 gives one for the same cylinder (PF-105), but its weight does not match: 9.61 kg/m³ × 12.7 mm is 0.12 kg/m² per layer, about 0.19 with the film, against TP-2444's 0.27; CR-172428 also has a 120° vinyl patch TP-2444 does not mention. So CR-172428's lining is not taken as TP-2444's (author 2026-11-10: "Yes, not valid"), and the run is on a lining that is not this test's. Fig. 17 is one "typical" sample, its microphone and propeller angle not stated, compared with a cabin-average model. B = 5 Hz is assumed (the same B reads both traces).
**Recorded outcome:** **not_met**, 1/7 (2026-10-23). Measured NR is 30.0–36.0 dB in every band. The model gives 16.6, 13.5, 7.5, 5.0 and 8.7 dB at 315–800 Hz, 34.0 dB at 1000 Hz and 49.1 dB at 1260 Hz. The Phase III trim, reported with no criterion, gives 10.9–55.7 dB. Phase 93 default form (2026-10-29): not met, 1/7.
**Explanation:** Experiment comparison. `narrowband_third_octave` converts the digitized traces (pass A). `noise_reduction_band` on `r172428_inputs(4000)` gives the model.
Inputs: `data/tp2444/tp2444_fig17_*_passA.csv`; CR-172428 article and App. B trim.
Equations: Eq. (18); Eqs. (19)–(23); 1/3-octave energy sum.
Outputs: NR per band [dB].

### Case: R172428_EXP
**Title:** CR-172428 reproduction vs measured space averages (44e)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** measurement
**Source:** NASA CR-172428 Table 5 (via Table 10); criterion dated 2026-10-23
**What it tests:** The same 9 predictions as R172428_CODE against the measured space-average levels (196 microphones).
**Why it is here:** It tests the model, not only the code, using NASA's own inputs. NASA's printed predictions themselves miss the measurement at 3000 rpm H1 (−17.7 dB) and 5000 rpm H1 (−13.8 dB).
**A pass means:** Within ±4 dB of the measured space average at each of the 9 points.
**Not covered:** Same mode truncation as R172428_CODE.
**Recorded outcome:** **not_met**, 1/9 within ±4 dB (first run 2026-10-23); NASA's own predictions meet the same gate at 5/9. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 3/9 within ±4 dB. Phase 93 default form (2026-10-29): not met, 4/9. Phase 96 default (2026-10-30): not met, 5/9.
**Explanation:** Uses `_r172428_levels()` (shared with R172428_CODE).
Inputs: as R172428_CODE; measured Table 5 levels.
Equations: as R172428_CODE.
Outputs: 9 levels [dB] vs measured; verdict vs ±4 dB at each point.

### Case: R172428_DBA_EXP
**Title:** CR-172428 tonal dB(A) vs measured space averages (124)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** measurement
**Source:** NASA CR-172428 Table 5 via Table 10 (measured space-average tones, 196 microphones); criterion fixed 2026-11-04 before the first run (Phase 124)
**What it tests:** The tonal dB(A) (A-weighted energy sum of H1–H3) of R172428_EXP's run (NASA's inputs, the code's default form) against the same sum of the measured space average; NASA PAIN's printed sum is shown alongside.
**Why it is here:** The dB(A) comparison with experiment on NASA's own inputs (author 2026-11-04).
**A pass means:** Within ±4 dB(A) of the measured sum at each of the 3 rpm (±4 dB copied unchanged from R172428_EXP). Disclosure: the H1–H3 levels were seen in R172428_EXP; the dB(A) sums were not computed before this case.
**Not covered:** As R172428_DBA_CODE.
**Recorded outcome:** **not_met**, 1/3 (first run 2026-11-04). This code − measured: 3000 rpm −6.4 (61.9 vs 68.3), 4000 rpm +1.0 (82.0 vs 81.0), 5000 rpm −4.6 dB(A) (88.7 vs 93.2). NASA's own printout − measured: −7.2 / +0.8 / −4.8 dB(A), so NASA's PAIN would also meet this gate at 1/3.
**Explanation:** `_run_r172428_dba(:exp)` in `validation_case_iso44.jl`.
Inputs: as R172428_EXP.
Equations: as R172428_DBA_CODE.
Outputs: 3 tonal dB(A) [dB(A)] vs measured; verdict vs ±4 dB(A) at each rpm.

### Case: R172428_DB_EXP
**Title:** CR-172428 tonal dB (unweighted) vs measured space averages (124)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** measurement
**Source:** As R172428_DBA_EXP; criterion fixed 2026-11-04 before its first run (Phase 124)
**What it tests:** The unweighted interior tonal level (energy sum of H1–H3) of R172428_EXP's run against the same sum of the measured space average; NASA PAIN's sum shown alongside.
**Why it is here:** The dB twin of R172428_DBA_EXP (author 2026-11-04: "i think you need both").
**A pass means:** Within ±4 dB of the measured sum at each of the 3 rpm (±4 dB copied unchanged from R172428_EXP). Disclosure: the H1–H3 levels and this phase's dB(A) sums were seen first.
**Not covered:** As R172428_DBA_CODE.
**Recorded outcome:** **not_met**, 1/3 (first run 2026-11-04). This code − measured: 3000 rpm −12.0 (69.3 vs 81.3), 4000 rpm +1.3 (92.0 vs 90.7), 5000 rpm −8.0 dB (92.7 vs 100.8). NASA's own printout − measured: −12.7 / +1.2 / −8.3 dB (1/3 on the same gate); the misses are H1's (3000 and 5000 rpm), which NASA's PAIN misses by the same amount.
**Explanation:** `_run_r172428_dba(:exp; weighted=false)` in `validation_case_iso44.jl`.
Inputs: as R172428_EXP.
Equations: as R172428_DB_CODE.
Outputs: 3 tonal levels [dB] vs measured; verdict vs ±4 dB at each rpm.

### Case: AC_C695A_DBA
**Title:** Commander 695A cabin dB(A) vs CR-178004 flight 3 (121)
**Map / block:** total / A_CABIN
**Category:** experiment
**Kind:** runnable
**Chain span:** Blade and polars → Bands and dB(A)
**Compared with:** measurement
**Source:** NASA CR-178004 (Wilby, McDaniel & Wilby 1985): App. E Tables E.3 and E.6 (flight 3, bare cabin, mics 3 and 6, 1/3-octave 25–5000 Hz), Table 4 (conditions, rpm, shaft power), secs. 2.1–2.4 (aircraft); form fixed 2026-11-03 before the first run (Phase 121)
**What it tests:** PAIN's aircraft path, end to end, on a real aircraft: the overall cabin dB(A) it predicts for the Commander 695A at each of Table 4's 18 flight-3 conditions against the measured cabin dB(A). Inputs: the printed ones (3 blades, D = 2.69 m, tip clearance 0.36 m, skin 1.6 mm, frame spacing 0.474 m, propeller 56.5 in aft of the cabin front, both propellers counter-clockwise from the rear, Table 4's altitude, airspeed, OAT, cabin altitude, rpm and power per engine) and assumed ones (`examples/commander695a_cr178004.json`: Aero Commander tip-A blade scaled to 2.69 m, circular section a = 0.725 m, auto θ₀ = 50°, L = 5.33 m, test-article stiffener sections, η_n = 0.05). Pitch is set per engine so the CCBlade torque equals the printed power / Ω; one run per engine, band levels added in energy.
**Why it is here:** The aircraft cabin block had no aircraft measurement (author 2026-11-03: "you really only need the inputs and then checking the final dba outputs").
**A pass means:** No verdict (input-completeness rule, Phase 118: the blade, cabin section and stiffener sections are not printed). Recorded against the form fixed 2026-11-03: the measured dB(A) inside PAIN's stated ±3.5 dB (1σ, `overall_dBA`) band at ≥ 68 % of the 36 points (18 conditions × mics 3 and 6), dB(A) over 63–5000 Hz for both, A-weighting at PAIN's band centres.
**Not covered:** Sources PAIN does not model (turbulent boundary layer, engine and structure-borne paths, cabin systems); flight 4 (treated: PAIN has no input for the 2-in fiberglass batts); a verdict. Disclosure: Cabin_Noise's own V8 (a different program, reverted 2026-11-03) had run on the same measurements before this form was written (it predicted high, mean +6.5 dB); no PAIN input was chosen from it.
**Recorded outcome:** No verdict (information). First run 2026-11-03 (superseded by the rerun below): 0/36 within ±3.5 dB; PAIN − measured = −18.2 to −12.9 dB, mean −15.4 dB (PAIN 78.5–84.7 dB(A), measured 92.2–100.4 dB(A)). Post-hoc look at the bands (condition 1, mic 3, no change made): the BPF and 2×BPF tones are 6 dB under the measured bands (100.5 vs 106.5 dB at 79 Hz); the measured dB(A) is set by broadband at 250 Hz–2 kHz (85–91 dB(A) per band), where PAIN has only its tones below 1 kHz and its propeller-driven Eq. (19) broadband, 13–24 dB under the measurement, above. Record: `validation_reports/phase121_c695a_dba.md`. **Rerun after the Phase 123 mode fix (2026-11-04, post-hoc; the fix was found from the exterior/interior split, not fitted):** 35/36 within ±3.5 dB; PAIN − measured −1.6 to +3.8 dB, mean +0.7 dB(A). Partly compensation: H2 is about 8 dB high, H1 5.5 dB low, and the 250 Hz–2 kHz broadband is still missing. Record: `validation_reports/phase123_c695a_exterior.md`.
**Explanation:** `_run_ac_c695a_dba` in `validation_case_iso121.jl`: `c695a_conditions` (Table 4), `c695a_operating_point` (ISA pressure, OAT, IAS = EAS; cabin air at the printed cabin altitude and 293.15 K), `c695a_pitch_for_power`, `c695a_condition_spectrum` (port rotation +1, starboard −1), `c695a_measured_dBA`.
Inputs: `data/cr178004/table4_flight3_conditions.csv`, `data/cr178004/appE_flight3_interior_third_octave.csv`, `examples/commander695a_cr178004.json`; H = 1–10.
Equations: the aircraft chain (CCBlade, F1A, Eq. (43), App. C/D, Eq. (8), Eqs. (19)–(23)); overall_dBA's sum.
Outputs: overall dB(A) per condition and mic [dB(A)].

### Case: AC_C695A_TONES
**Title:** Commander 695A cabin tones vs CR-178004 App. B (122)
**Map / block:** total / A_CABIN
**Category:** experiment
**Kind:** runnable
**Chain span:** Blade and polars → Interior tones
**Compared with:** measurement
**Source:** NASA CR-178004 App. B Tables B.7, B.8 (mic 3) and B.16, B.17 (mic 6), flight 3: each engine's cabin harmonics 1–3; Table 4; form fixed 2026-11-03 before the first run (Phase 122)
**What it tests:** Only what PAIN models: the propeller tones in the cabin. The AC_C695A_DBA runs (one per engine, pitch for the printed power) give each engine's cabin H1–H3; App. B prints each engine's component at mics 3 and 6 for the conditions where the two propellers turn at different rpm or one is off (1–4, 9–12, 17, 18), so the tones are compared engine by engine, without the broadband PAIN leaves out. 108 points.
**Why it is here:** AC_C695A_DBA's overall dB(A) mixes PAIN's propeller tones with broadband PAIN does not model (author 2026-11-03: compare only what PAIN models).
**A pass means:** No verdict (input-completeness rule, Phase 118: the blade, cabin section and stiffener sections are assumed). Recorded against the form fixed 2026-11-03: each level within ±4 dB (T1's gate width, 2026-10-20) at ≥ 68 % of the points. PAIN's level is the cabin space average; App. B's is at the microphone.
**Not covered:** The rotation sign of each engine in PAIN's convention (port +1, starboard −1 assumed; in PAIN the sign also sets which quarter of the fuselage the grid covers); conditions with both propellers at the same rpm (tones not separable). Disclosure: the App. B values were seen when they were transcribed for Cabin_Noise's V7 (2026-11-02), whose different program predicted them high (mean +17.9 dB); no PAIN input was chosen from them.
**Recorded outcome:** No verdict (information). First run 2026-11-03: 27/108 within ±4 dB; PAIN − measured = −18.3 to +12.2 dB, mean −6.7 dB (H1 −5.7, H2 −7.4, H3 −7.0 dB; port engine −8.8, starboard −4.6 dB). Post-hoc diagnostic (no change to the case): with the two rotation signs swapped, 30/108 and the same mean −6.7 dB; the port/starboard difference follows the sign, the overall shortfall does not. Record: `validation_reports/phase122_c695a_tones.md`. **Rerun after the Phase 123 mode fix (2026-11-04, post-hoc):** 32/108 within ±4 dB; PAIN − measured −17.1 to +22.1 dB, mean +2.0 dB (H1 −5.5, H2 +8.2, H3 +3.4 dB).
**Explanation:** `_run_ac_c695a_tones` in `validation_case_iso121.jl`: `c695a_measured_tones`, `c695a_condition_spectrum` (each engine's `harmonics_dB`).
Inputs: `data/cr178004/appB_flight3_cabin_harmonics.csv`, `data/cr178004/table4_flight3_conditions.csv`, `examples/commander695a_cr178004.json`.
Equations: the aircraft chain (CCBlade, F1A, Eq. (43), App. C/D, Eq. (8)).
Outputs: cabin tone level per condition, mic, engine and harmonic [dB].

### Case: AC_C695A_EXT
**Title:** Commander 695A exterior tones vs CR-178004 App. A (123)
**Map / block:** total / A_CABIN
**Category:** experiment
**Kind:** runnable
**Chain span:** Blade and polars → Skin field
**Compared with:** measurement
**Source:** NASA CR-178004 App. A Tables A.1 (port), A.2 (starboard), flight 3: the near propeller's H1–H3 at a flush microphone 7.5 cm forward of the propeller plane (Table 8); Table 4; form fixed 2026-11-03 before the first run (Phase 123)
**What it tests:** The source alone: PAIN's blocked field on grid line ℓ = 1 (the propeller azimuth), interpolated in dB between k_p and k_p − 1 to 7.5 cm forward, from the AC_C695A_DBA runs, against the measured surface tones. 101 points (port 11 and starboard 12 shut down; port 15 H1 illegible).
**Why it is here:** It splits AC_C695A_DBA's gap into source and transmission (author 2026-11-03: "yes find the cause and fix it").
**A pass means:** No verdict (input-completeness rule, Phase 118: the blade is assumed). Recorded against the form fixed 2026-11-03: each tone within ±4 dB (T1's gate width) at ≥ 68 % of the points.
**Not covered:** Thickness noise (the assumed blade has t/c = 0); the microphone sits about 5 cm below the spinner centre line, PAIN's line ℓ = 1 at the propeller azimuth.
**Recorded outcome:** No verdict (information). First run 2026-11-03 (before the Phase 123 mode fix, which does not change the exterior field): 53/101 within ±4 dB; PAIN − measured −2.0 to +8.8 dB, mean +4.0 dB (H1 +6.5, H2 +3.3, H3 +2.2 dB). The source is high, not low, so the cabin shortfall was in transmission: it led to the App. D mode-truncation fix (32 modes ended at 105 Hz on the 5.33 m cabin).
**Explanation:** `_run_ac_c695a_ext`, `c695a_flush_mic_dB`, `c695a_measured_exterior` in `validation_case_iso121.jl`.
Inputs: `data/cr178004/appA_flight3_exterior_harmonics.csv` (copied unchanged from Cabin_Noise V5), `data/cr178004/table4_flight3_conditions.csv`, `examples/commander695a_cr178004.json`.
Equations: CCBlade, F1A, Eq. (43) blocking.
Outputs: exterior tone level per condition, engine and harmonic [dB].

### Case: AC_C695A_SEAT
**Title:** Commander 695A cabin tones at the mic seats vs CR-178004 App. B (125)
**Map / block:** total / A_CABIN
**Category:** experiment
**Kind:** runnable
**Chain span:** Blade and polars → Interior tones
**Compared with:** measurement
**Source:** NASA CR-178004 App. B Tables B.7, B.8, B.16, B.17 (flight 3, each engine's H1–H3 at mics 3 and 6); Table 7 (mic locations); Table 4; form fixed 2026-11-04 before the first run (Phase 125)
**What it tests:** The like-for-like quantity: mics 3 and 6 are in the propeller plane at seated ear height (Table 7), while AC_C695A_TONES compares PAIN's cabin space average. Here PAIN's Eq. (8) point form (`point_tone_p2`, Phase 42) gives each engine's H1–H3 at the interior node nearest the seat: z = 1.435 m (station 117 − 60.5 in), |X| = 0.45 m, 1.0 m above PAIN's floor. 108 points, as AC_C695A_TONES.
**Why it is here:** Author 2026-11-04 ("Yes, add it") after the diagnostic showed PAIN's H1 at the seat 3–7 dB above its own space average.
**A pass means:** No verdict (input-completeness rule, Phase 118). Recorded against AC_C695A_TONES' form: within ±4 dB at ≥ 68 % of the points. Disclosure: the seat position values were those of the 2026-11-03/04 condition-1 diagnostics, chosen before any seat level was seen; condition 1's seat levels were then seen.
**Not covered:** PAIN's point field is left–right symmetric (each structural mode drives cabin modes of one symmetry only), so the near and far mic get the same PAIN level; PAIN's cabin is circular (a = 0.725 m, 1.19 m high) where the real one is 1.45 m high, so the ear height is taken from PAIN's floor.
**Recorded outcome:** No verdict (information). First run 2026-11-04: 43/108 within ±4 dB (space average: 32/108); PAIN − measured mean −0.2 / +9.3 / +7.3 dB at H1 / H2 / H3 (port +4.1 dB H2, starboard +14.4 dB H2); the seat is +5.3 / +1.1 / +3.8 dB above the space average. Post-hoc diagnostic (condition 1, no change): NASA's lower-quarter grid (I-18) evens the two engines but raises the port H2 by about 8 dB, so it is not the cause of the high H2. Record: `validation_reports/phase125_c695a_seat.md`.
**Explanation:** `_run_ac_c695a_seat`, `c695a_seat_dB` in `validation_case_iso121.jl`; `c695a_condition_spectrum(row; seat=true)`.
Inputs: as AC_C695A_TONES.
Equations: the aircraft chain; Eq. (8) point form (coherent over cabin modes, mean square over structural modes).
Outputs: cabin tone level at the mic seat per condition, mic, engine and harmonic [dB].

### Case: APPB_EPS_N
**Title:** Cabin-mode ε_n vs NASA's App. B printout (87a)
**Map / block:** total / P_CYL
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Cabin modes
**Compared with:** NASA's printed prediction
**Source:** NASA CR-172428 App. B p. 195 (ε of the first 48 of the 400 cabin modes PAIN used); criterion fixed 2026-10-29 before the run (plan §8ae)
**What it tests:** The normalization ε_n of Eq. (C.11) with ε_q (2 for q = 0, 1 for q > 0), from `cabin_eps_3d`, for each printed (Q, I) mode.
**Why it is here:** ε_n scales every term of Eq. (8); App. B prints NASA's value, so this reproduces a PAIN output (P). The q = 0 modes are a third of the list.
**A pass means:** |ε_n/NASA − 1| ≤ 1 % at every printed mode.
**Not covered:** Modes above the 48th (597 Hz).
**Recorded outcome:** **met**, 48/48 (first run 2026-10-29); every ratio is 1.0000 to the printed 5 digits, q = 0 modes included. The normalization is not the cause of the q = 0 difference.
**Explanation:** P case. `cabin_eps_3d(ac, q)` on `r172428_inputs(4000)`.
Inputs: App. B p. 195; CYL2D modes of CR-172428's cabin.
Equations: Eq. (C.11).
Outputs: ε_n per mode, ratio to NASA.

### Case: APPB_ETA_N
**Title:** Cabin-mode η_n vs NASA's App. B printout (87b; CR-3813 printed damping form)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** NASA CR-172428 App. B p. 195 (η of the first 48 cabin modes, with the Table 6 trim); criterion fixed 2026-10-29 before the run (plan §8ae)
**What it tests:** The cabin-mode loss factor η_n of Eq. (77) with the sidewall and end-plate trim conductance at the mode's own frequency, against NASA's printed value.
**Why it is here:** η_n sets the cabin-mode damping N of Eq. (8) and Eq. (83); App. B prints NASA's (P).
**A pass means:** |η_n/NASA − 1| ≤ 2 % at every printed mode at or above 100 Hz.
**Not covered:** Modes 1 (0 Hz) and 2 (93.8 Hz): the Fig. A-2 insulation table starts at 100 Hz.
**Recorded outcome:** **not_met**, 11/46 (first run 2026-10-29). Above about 470 Hz within 5 %; below, 0.56–3.1× NASA's, with no q = 0 pattern (q = 0 modes 0.62–1.20×). Not the 0.5 % frequency difference (at NASA's printed frequencies the ratios are the same within a few %). **Diagnostic, post-hoc (2026-10-29, formed from this table, so not a test):** with the trim conductance taken at the centre of the 1/3-octave band holding the mode the ratios are 0.86–1.39, smooth within each band and stepping at the band edges (355, 447, 562 Hz). This is the lead of Phase 89 (plan §8af), to be tested on printouts that played no part in it. With NASA's per-band PF-105 deck table (Phase 100, 2026-10-30): not met, 16/46. **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** not met, 12/46 (was 16/46).
**Explanation:** P case. `_eta_n_at_mode` = `acoustic_N` at the mode frequency with ξ, ξ_e at that frequency.
Inputs: App. B p. 195; Table 6 trim (PF105 lining); CR-172428 cabin.
Equations: Eq. (77).
Outputs: η_n per mode, ratio to NASA.

### Case: APPB_ETA_RPP
**Title:** Per-pair η_r″ vs NASA's App. B printout (87c)
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Chain span:** Damping and trim → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** NASA CR-172428 App. B pp. 197, 202 (ETA R# of the five largest pairs per harmonic, 4000 and 5000 rpm); criterion fixed 2026-10-29 before the run (plan §8ae)
**What it tests:** The acoustic loss η_r″ of Eq. (83) for each printed cabin × structural pair, as `tone_mean_square_pressure` forms it (bare f′, N at the tone frequency), against NASA's printed value.
**Why it is here:** η_r″ is the radiation damping of each structural mode into the cabin; App. B prints NASA's (P).
**A pass means:** |η_r″/NASA − 1| ≤ 10 % at ≥ 80 % of the printed pairs with η_r″ ≥ 1e-4.
**Not covered:** Pairs printed below 1e-4 (one significant digit).
**Recorded outcome:** **not_met**, 8/19 (first run 2026-10-29). The pair cabin mode 19 × structural mode 6 is printed 0.00053 at both 4000 and 5000 rpm (H2 and H1, 400 and 250 Hz), so NASA's η_r″ does not depend on the tone; ours does (1.01× at 400 Hz, 9.5× at 250 Hz), because N is taken at the tone frequency. With the deck table (Phase 100, 2026-10-30): not met, 12/19. With N at the mode frequency (post-hoc, information) 8/19 as well; the misses then follow the η_n misses of APPB_ETA_N (44f reproduced NASA's η_r″ within 5 % with NASA's own η_n). **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** met, 16/19 (was not met, 12/19).
**Explanation:** P case. `_eta_r_pp_pair` on `r172428_inputs(rpm)`.
Inputs: App. B pp. 195, 197, 202; CR-172428 inputs.
Equations: Eq. (83).
Outputs: η_r″ per pair, ratio to NASA.

### Case: R996_FIG10_FLAT
**Title:** Eq. (43) blocking vs Report 996 Fig. 10 flat wall (90b)
**Map / block:** total / P_BLK
**Category:** experiment
**Kind:** runnable
**Chain span:** Free field → Skin field
**Compared with:** measurement
**Source:** NACA Report 996 Fig. 10 (PDF p. 12), digitized 2026-10-29 by `data/digitizers/dig_r996_fig10.py` (`data/report996/tr996_fig10_reflecting_walls.csv`); criterion fixed 2026-10-29 before digitizing (plan §8ag)
**What it tests:** PAIN's blocking factor, Eq. (43) R1, against the measured increase of the total rms pressure at a flat wall over the free-space value, at the five x/D where both are measured (−0.25 … 0.25), with γ = atan(|x/D| / (0.5 + d/D)), d/D = 0.083.
**Why it is here:** The only comparison of Eq. (43) with a measurement; the blocking block had a reproduction of NASA's printed values (BLK_P68) and the E-12 check against NASA's prediction.
**A pass means:** |20 log₁₀ F_R1 − 20 log₁₀(p_flat/p_free)| ≤ 1.5 dB at ≥ 4 of the 5 points.
**Not covered:** γ spans only 0–23°, where F is close to 2: the near-normal doubling is tested, not the fall-off toward grazing incidence. Total pressure (all harmonics), not per harmonic. Eq. (43) is Magliozzi's curve fitted to prop-fan fuselage data (J. Aircraft 1980, not in hand); whether Report 996 was among its data is not known.
**Recorded outcome:** **met**, 5/5 (first run 2026-10-29): measured 4.56, 6.07, 6.00, 6.27, 7.30 dB against R1 5.97–6.00 dB. R2 (CR-172428's revision, information) 4.03–4.06 dB, 2 dB under the flat-wall measurement.
**Explanation:** E case. `_run_r996_fig10("flat_wall")` in `validation_case_iso90.jl`; `delta_L_blocking_dB`.
Inputs: Fig. 10 free-space and flat-wall p̄; d/D = 0.083.
Equations: Eq. (43); γ as CR-3813 p. 31 for a plane wall.
Outputs: wall increase [dB], measured and R1, per x/D.

### Case: R996_FIG10_CIRC
**Title:** Eq. (43) blocking vs Report 996 Fig. 10 circular wall, information (90c)
**Map / block:** total / P_BLK
**Category:** experiment
**Kind:** runnable
**Chain span:** Free field → Skin field
**Compared with:** measurement
**Source:** NACA Report 996 Fig. 10, digitized 2026-10-29 (as R996_FIG10_FLAT); information by the plan (§8ag, 2026-10-29)
**What it tests:** Eq. (43) against the measured increase at the circular (fuselage-like) wall. On the cylinder's generator line nearest the hub γ is as for the flat wall, so Eq. (43) predicts the same increase whatever the radius.
**Why it is here:** Shows what Eq. (43) leaves out: the wall's curvature.
**A pass means:** No criterion: Eq. (43) has no curvature term, so it predicts the same increase whatever the radius (wording of 2026-11-10, Phase 144c; Report 996 pp. 5–6 do not state the radius either).
**Not covered:** As R996_FIG10_FLAT.
**Recorded outcome:** no verdict (2026-10-29): measured 0.67, 2.87, 4.22, 4.41, 4.92 dB against R1 about 6.0 dB and R2 about 4.05 dB; R2 is the closer (within 1 dB at three points), in line with CR-172428's reason for R2 (a fuselage scatters less than a flat wall).
**Explanation:** Information. `_run_r996_fig10("circular_wall")`.
Inputs: Fig. 10 free-space and circular-wall p̄.
Equations: Eq. (43).
Outputs: wall increase [dB].

### Case: R172428_ETAT2
**Title:** CR-172428 η_T = 2.0 run: default form vs NASA's Table 12 (94a)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-172428 Table 12 (p. 86), Fig. 35 (`data/cr172428/table12_eta_T2_predictions.csv`); criterion fixed 2026-10-29 before any run (plan §8ak, commit 8387c80)
**What it tests:** The code as it ships (Phase 93 default form: App. A corrections, q = 0 off, η_n per mode) with NASA's Table 6 inputs and the trim panel loss factor η_T = 2.0, against NASA's second printed run, at 3000/4000/5000 rpm H1–H3.
**Why it is here:** A PAIN run no earlier phase used: tests the program form inferred in Phase 92 on new inputs and outputs (P).
**A pass means:** Within ±3 dB of Table 12 at ≥ 7 of 9 points.
**Not covered:** Same test article as the η_T = 0.13 run the form was inferred from, so held out in inputs and outputs but not independent of the article.
**Recorded outcome:** **met**, 9/9 (first run 2026-10-29): 62.31, 66.72, 58.12; 91.68, 75.13, 69.09; 92.64, 88.74, 74.95 dB against 62.1, 65.5, 56.9; 91.2, 73.8, 67.4; 92.9, 89.6, 74.0 (largest |Δ| 1.69 dB). Phase 96 default (2026-10-30): met, 9/9. Phase 100 deck table (2026-10-30, held out): met, 9/9, largest |Δ| 2.12 dB. **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** met, 9/9, largest 1.73 dB.
**Explanation:** P case. `_run_r172428_etat2` in `validation_case_iso94.jl`.
Inputs: `r172428_inputs(rpm; η_T=2.0)`.
Equations: Eq. (8) in the default form.
Outputs: SPL [dB].

### Case: APPB_ETA_N_T2
**Title:** Cabin-mode η_n at η_T = 2.0 vs CR-172428 p. 85 (94b)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** CR-172428 p. 85 text (η_n of App. B modes 6, 7, 8 at η_T = 2); criterion fixed 2026-10-29 before any run (plan §8ak)
**What it tests:** Eq. (77) η_n at each mode's frequency with η_T = 2.0, as APPB_ETA_N, against the three values NASA prints.
**Why it is here:** NASA's printed η_n for a second trim setting (P), held out.
**A pass means:** Within ±10 % at all three modes.
**Not covered:** Three modes (237–271 Hz), all near the trim resonance of the η_T = 0.13 case.
**Recorded outcome:** **met**, 3/3 (first run 2026-10-29): 0.0877, 0.0782, 0.0829 against 0.088, 0.077, 0.081. With the trim at the band centre, as the tone sum uses it (information): 0.0852, 0.0798, 0.0899. With the deck table (Phase 100, held out): met, 0.0876, 0.0779, 0.0827. **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** met, 3/3: 0.0884, 0.0787, 0.0833.
**Explanation:** P case. `_run_appb_eta_n_t2` in `validation_case_iso94.jl`.
Inputs: `r172428_inputs(4000; η_T=2.0)`.
Equations: Eq. (77).
Outputs: η_n.

### Case: APPB_ETA_N_BAND
**Title:** Cabin-mode η_n by the band-centre rule vs App. B (96a, post-hoc)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** CR-172428 App. B pp. 195, 197; plan §8am, 2026-10-30
**What it tests:** η_n of the 46 App. B cabin modes ≥ 100 Hz by the default rule (Eq. (77) at the nominal 1/3-octave centre holding the mode, for ω and ξ), with this code's trim admittance; the count with NASA's printed admittance is echoed.
**Why it is here:** Shows how far the rule read in Phase 95 carries with this code's own trim model.
**A pass means:** No criterion (diagnostic, post-hoc: the rule was read from these values).
**Not covered:** Modes below 100 Hz (outside Fig. A-2).
**Recorded outcome:** no verdict (2026-10-30): 42/46 within ±10 %, 0/46 within ±2 %; 45/46 within ±2 % with NASA's admittance. With the deck table (Phase 100): 45/46 within ±10 %, 44/46 within ±2 %. **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** 46/46 within 10 %, 43/46 within 2 %.
**Explanation:** `_run_appb_eta_n_band` in `validation_case_iso96.jl`.
Inputs: `r172428_inputs(4000)`.
Equations: Eq. (77).
Outputs: η_n.

### Case: APPB_ETA_N_T2_BAND
**Title:** Cabin-mode η_n at η_T = 2.0 by the band-centre rule vs CR-172428 p. 85 (96b)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** CR-172428 p. 85; criterion fixed 2026-10-30 before the run (plan §8am, commit fae2cb7)
**What it tests:** η_n of App. B modes 6, 7, 8 at η_T = 2.0 by the default rule, against the three values NASA prints.
**Why it is here:** Held-out check of the Phase 95 rule: the η_T = 2.0 values played no part in reading it (P).
**A pass means:** Within ±10 % at all three modes.
**Not covered:** Three modes (237–271 Hz).
**Recorded outcome:** **met**, 3/3 (first run 2026-10-30): 0.0894, 0.0779, 0.0827 against 0.088, 0.077, 0.081. With the deck table (Phase 100, held out): met, 0.0887, 0.0776, 0.0822. **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** met, 3/3: 0.0898, 0.0783, 0.0827.
**Explanation:** P case. `_run_appb_eta_n_t2_band`.
Inputs: `r172428_inputs(4000; η_T=2.0)`.
Equations: Eq. (77).
Outputs: η_n.

### Case: R172428_CODE_DEFAULT
**Title:** CR-172428 reproduction with the code as it ships (96d, post-hoc)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-172428 Table 10 / App. B p. 206; plan §8am
**What it tests:** R172428_CODE's nine points with the defaults of Phase 96 (App. A corrections, q = 0 uncoupled, band-centre η_n).
**Why it is here:** How close the code as it ships comes to the run its defaults were inferred from.
**A pass means:** No criterion (diagnostic, post-hoc).
**Not covered:** The defaults were inferred from these points.
**Recorded outcome:** no verdict (2026-10-30): 8/9 within ±3 dB; 3000 rpm H3 63.03 dB against 59.5. **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** 9/9 within ±3 dB, largest 1.19 dB.
**Explanation:** `_run_r172428_code_default`.
Inputs: `r172428_inputs(rpm)`, defaults.
Equations: Eq. (8).
Outputs: SPL [dB].

### Case: FLIGHT_MODES
**Title:** MRP solver on NASA's Merlin IVC deck vs PAIN's printed mode list (101a)
**Map / block:** total / P_MRP
**Category:** verification
**Kind:** runnable
**Chain span:** Wall modes → Wall modes
**Compared with:** NASA's printed prediction
**Source:** CR-172428 App. C pp. 204–205 (NASA's MRP deck) and pp. 213–216 (PAIN's structural-mode list); criterion fixed 2026-10-30 before the run (plan §8aq, commit b404020)
**What it tests:** The App. D structural solver on a second aircraft (business aircraft of Table 13, the flight-test fuselage), from NASA's printed deck, against PAIN's printed frequencies and generalized masses.
**Why it is here:** Reproduces PAIN's output from PAIN's inputs on a fuselage other than the test article.
**A pass means:** f_r within 2 % and generalized mass within 10 % for ≥ 90 % of the listed modes up to 1 kHz, each printed mode paired with the solver mode of the same symmetry and axial order nearest in frequency.
**Not covered:** Modes 47–52, 111–121, 182–185 and 243–250 (cut off at the page bottoms of the scan); mode shapes (not printed). The outcome of the re-run could be told from Phase 110's 199/221; the verdict rests on the reference file being settled against the page, not on the count being new.
**Recorded outcome:** **met**, 200/221 (90.5 %) (re-run 2026-11-11, Phase 142, on the settled transcription; criterion unchanged; it carries the verdict by the author's decision of 2026-11-09): frequencies 220/221 within 2 %. First run 2026-10-30: not met, 197/221, on the first-pass file, which had three misreads (mode 41's total 1002.69 for 1802.69, mode 174's total, mode 230's M); it stays on record. Of the 21 modes outside the rule, one misses in frequency (mode 29, −5.2 %) and 20 in mass, by 10–113 %, in the in-plane part (ISSUE-039). Report: `validation_reports/phase142_flight_modes.md`.
**Explanation:** `_run_flight_modes` in `validation_case_iso101.jl`; `merlin_mrp_deck()`.
Inputs: `data/cr172428/appC_merlin_mrp_deck.csv`, `data/cr172428/appC_merlin_structural_modes_checked.csv` (three transcription passes; the third blind, Phase 142).
Equations: App. D Eqs. (D.17)–(D.29).
Outputs: f_r [Hz], generalized mass [kg].

### Case: FLIGHT_ETA
**Title:** Structural-mode loss factors of the flight aircraft against PAIN's printout (CR-172428, App. C)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Wall modes → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** CR-172428 App. C pp. 213–216 (PAIN's printed LOSS FACTOR column of the Merlin IVC's 221 modes), App. C pp. 204–205 (NASA's MRP deck) and App. D pp. 229–237 (run 10's deck); criterion fixed 2026-11-12 and committed (d0f6a07) before the column was read (ISSUE-041)
**What it tests:** η_r′ of Eq. (82) for each listed Merlin mode, from run 10's printed deck (η_r = 2/f per band, PF-105 0.055 m trim with 1.95 kg/m² and η = 2.0), each printed mode paired with the solver mode of the same symmetry and axial order nearest in frequency (FLIGHT_MODES' rule).
**Why it is here:** The held-out test of the ISSUE-032 fix (a card structural loss factor is η_r^struc; the radiation loss is added), on an aircraft and a deck the fix was not found on.
**A pass means:** η_r′ within ±25 % of PAIN's printed loss factor for ≥ 75 % of the listed modes.
**Not covered:** Modes 47–52, 111–121, 182–185 and 243–250 (cut off in the scan). Mode 1 (39.6 Hz) lies below the trim table's 50 Hz start and uses its end-segment extrapolation.
**Recorded outcome:** **met**, 218/221 (first run 2026-11-12): median |difference| 8.3 %, largest 29.7 %; this code is 0.92 of PAIN's value at the median. The form before the fix gives 64/221 on the same modes (`issue041_merlin_loss_factors.md`).
**Explanation:** `_run_flight_eta` in `validation_case_merlin_loss.jl`; `r172428_flight10_inputs()`.
Inputs: `data/cr172428/appC_merlin_loss_factors.csv` (two passes; 8 against 0 settled by glyph shape against the page's known digits), `data/cr172428/appC_merlin_structural_modes_checked.csv`.
Equations: Eqs. (79)–(82), (A.8).
Outputs: η_r′ (loss factor).

### Case: CYL2D_PRINTED
**Title:** CYL2D grid rule vs PAIN's printed cabin modes of three CR-172428 aircraft (105)
**Map / block:** total / P_CYL
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Cabin modes
**Compared with:** NASA's printed prediction
**Source:** CR-172428 App. C pp. 210 (decks), 212, 221, 225 (acoustic-mode lists); criterion fixed 2026-10-30 before the two held-out lists were transcribed (plan §8au, commit 25f7acb)
**What it tests:** CYL2D with the node rule 0.45h and NY = 10 else the next grid that solves, at the small-diameter (62.6°) and narrow-body (73.7°) floor angles, against the 2-D frequencies, ε(0,0) and mode types PAIN printed.
**Why it is here:** CYL2D's only input is θ₀; reproduces PAIN's output from PAIN's input at floor angles other than the test article's.
**A pass means:** For each held-out aircraft, ε(0,0) within 0.02 %, every printed 2-D frequency within 0.1 % of CYL2D's at 341 m/s / a, every type equal; met if both pass.
**Not covered:** Modes between the printed blocks; the narrow body's ε(0,0) is not printed (ε(1,0)/2 used); the Merlin list (50°) is recorded alongside, post-hoc.
**Recorded outcome:** **not met** (first run 2026-10-30): the rule gives NY = 12 at both angles; 2-D frequencies 0/53 and 5/61 within 0.1 %; Merlin (seen) 51/51. Diagnostic: NASA's narrow-body grid is NY = 8; no grid fits the small-diameter list (best 2 %). **Re-run 2026-11-12 (ISSUE-033, post-hoc; NASA's 62.6° grid solved on the real parts):** not met. Small diameter: ε(0,0) 0.96858 as printed, types 53/53, every frequency 0.30–0.31 % low (0/53 within 0.1 %); narrow body 61/61; summary 63/116 (`issue033_cyl2d_small_diameter.md`).
**Explanation:** `_run_cyl2d_printed` in `validation_case_iso105.jl`.
Inputs: `data/cr172428/appC_smalldia_acoustic_modes.csv`, `appC_narrowbody_acoustic_modes.csv`, `appC_merlin_acoustic_modes.csv`.
Equations: App. C Eqs. (C.1)–(C.12).
Outputs: 2-D frequency [Hz], ε(0,0).

### Case: CABIN_FREQ_PRINTED
**Title:** Cabin-mode frequencies with CYL2D's 2-D part at 341 m/s vs PAIN's printed lists (106)
**Map / block:** total / P_CYL
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Cabin modes
**Compared with:** NASA's printed prediction
**Source:** CR-172428 App. B p. 185 (held out), App. C p. 212 and App. D pp. 235–236 (seen); criterion fixed 2026-10-30 (plan §8av, commit 25f7acb)
**What it tests:** f_n = √[(f_2D at 341 m/s / a)² + (q c/2L_c)²]: CYL2D's 2-D frequency at its own 341 m/s and the axial term at the deck's c, against the cabin-mode frequencies PAIN printed.
**Why it is here:** Reproduces PAIN's printed cabin modes from PAIN's inputs; before Phase 106 the code put both parts at the deck's c (0.6 % high).
**A pass means:** |ours − printed| ≤ 0.02 Hz or 0.02 % (the larger) at every printed App. B cabin mode with f > 0.
**Not covered:** The Merlin list and run 10's printed pairs are recorded alongside, seen (post-hoc).
**Recorded outcome:** **met** (first run 2026-10-30): 47/47 (6/47 with both parts at 343 m/s, the form before Phase 106); seen, post-hoc: 80/81 (the miss, run 10's Q4 I3, prints 219.4 where the glyph may be 218.4). **Display (2026-11-11, Phase 145a):** the seen rows are shown, not judged, so the summary reads 47/47 (+ 81 shown, not judged); before, it counted all 128 rows (127/128). The verdict was always on the 47.
**Explanation:** `_run_cabin_freq_printed` in `validation_case_iso106.jl`; `cabin_frequency_3d(...; c2d=CYL2D_C0)`.
Inputs: `data/cr172428/appB_acoustic_modes.csv`, `appC_merlin_acoustic_modes.csv`, `appD_run10_pairs.csv`.
Equations: App. C Eqs. (C.7), (C.12).
Outputs: cabin-mode frequency [Hz].

### Case: FLIGHT10_H234
**Title:** CR-172428 flight run 10, H2–H4: as shipped and trim per band vs PAIN (102)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-172428 App. D pp. 229–237 (deck, field, printed levels); what is compared fixed 2026-10-30 before the run (plan §8ar, commit f00c03f)
**What it tests:** Run 10 from PAIN's printed deck and field, H2–H4 (H1 and H5 fields are cut off in the scan), with the code as it ships and with the trim of tones and modes at the band centre (`trim_band_centre`).
**Why it is here:** The flight tones lie off band centres, so they test whether PAIN takes the trim per band (diagnostic).
**A pass means:** No verdict (FLIGHT_MODES not met); per tone, which form is closer to PAIN's printed level is recorded.
**Not covered:** H1 and H5; the mode list of NASA's file (lowest 400 used); CYL2D at NY = 11 (assumption).
**Recorded outcome:** no verdict (2026-10-30): as shipped 98.30 / 89.76 / 79.19 dB, trim per band 98.68 / 89.77 / 79.17 dB, PAIN 96.59 / 88.06 / 83.92 dB; the trim per band is closer at 0/3 (not supported). **Re-run after Phase 104 (2026-10-30, post-hoc; θ as printed, from the bottom):** as shipped 96.80 / 88.85 / 80.67 dB, trim per band 97.14 / 88.87 / 80.64 dB; still 0/3. **After Phase 105 (post-hoc; NASA's printed Merlin grid, NY = 11, 0.45h):** 97.13 / 89.37 / 81.34 dB, trim per band 97.47 / 89.40 / 81.31 dB; 0/3. **After Phases 106–107 (post-hoc):** 97.33 / 89.00 / 82.86 dB, trim per band 97.66 / 89.02 / 82.80 dB; 0/3. **After Phase 108 (post-hoc; run 10's pre-correction floor sign):** 94.60 / 87.44 / 83.89 dB, trim per band 94.99 / 87.47 / 83.91 dB; closer at 3/3 (by ≤ 0.4 dB).
**Explanation:** `r172428_flight10_inputs()` and `_run_flight10_h234` in `validation_case_iso102.jl`.
Inputs: `data/cr172428/appD_run10_H{2,3,4}.csv`, `merlin_mrp_deck()`, App. D deck values.
Equations: Eq. (8).
Outputs: SPL [dB re 20 μPa].

