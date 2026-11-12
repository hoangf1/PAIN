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

### Case: BEMT_HAND
**Title:** CCBlade wrapper vs hand BEM (41e)
**Map / block:** total / A_LOADS
**Category:** verification
**Kind:** runnable
**Chain span:** Blade and polars → Blade loads
**Compared with:** verification
**Source:** CCBlade residual (F=1); phase 41e criterion 2026-10-23
**What it tests:** Project BEMT wrapper thrust/torque for constant-chord, constant-twist blade with cl = 2π α, cd = 0, tip loss off, against a hand blade-element/momentum solution written in the case.
**Why it is here:** Isolates BEMT integration for failing R996_LOADS.
**A pass means:** T and Q within 1 %.
**Not covered:** Real XFOIL polars; Prandtl tip loss (off here); experimental loads.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (the BEMT wrapper against a hand BEM). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 2/2 (first run 2026-10-23)
**Explanation:** Isolated analytic check: hand residual matches CCBlade `residual_and_outputs` with F = 1; trapz pad at hub/tip as `thrusttorque`; compared via `evaluate_propeller_source(...; use_tip_correction=false)`.
Inputs: Rtip = 1 m, Rhub = 0.2 m, B = 2, chord = 0.1 m, twist = 15°, Vinf = 20 m/s, rpm = 1200.
Equations: BEM induction residual (CCBlade form); hand trapz.
Outputs: T [N], Q [N·m]; verdict within 1 %.

### Case: BEMT_MOMENTUM
**Title:** BEMT: momentum = blade element at every station (66a)
**Map / block:** total / A_LOADS
**Category:** verification
**Kind:** runnable
**Chain span:** Blade and polars → Blade loads
**Compared with:** verification
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Our CCBlade wrapper's converged sections: blade-element thrust and torque per unit span against the momentum values, at every station of three operating points.
**Why it is here:** Shows the wrapper's sections are converged solutions of the BEM equations as we set them up (stations, inflow, rpm), not only that integrated loads look plausible.
**A pass means:** Relative difference ≤ 1e-8 at every station.
**Not covered:** Polar accuracy; the empirical (k < −2/3) region; experiment.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (BEM momentum = blade element: identity of the converged solution). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 72/72 stations, worst 1.1e-11 (first run 2026-10-24; `phase66_bemt_f1a.md`)
**Explanation:** CCBlade applies the tip/hub loss to the loads and reports u, v rescaled by an effective G; the identity is checked with the raw induction a = k/(1−k), a′ = k′/(1+k′) from the section outputs, B N′ = 4πrρV²F a(1+a), B T′ = 4πrρV(1+a)Ωr F a′, and in CCBlade's G form B N′ = 4πrρ(V+u)u, B T′ = 4πrρ(V+u)v (reading fixed before the run).
Inputs: Hartzell example at 20 m/s / 4000 rpm and 40 m/s / 3000 rpm; Report 996 blade β₇₅ = 15°, M_t = 0.6, 20 m/s.
Equations: BEM momentum balance
Outputs: per-station relative difference

### Case: BEMT_HAND_TIP
**Title:** BEMT: hand BEM with tip loss, drag, nonlinear polar (66b)
**Map / block:** total / A_LOADS
**Category:** verification
**Kind:** runnable
**Chain span:** Blade and polars → Blade loads
**Compared with:** verification
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Our wrapper's T and Q against a hand BEM written in the case (Prandtl tip and hub loss in the textbook form, c_d ≠ 0, c_l = 2πα − 4α³), solved by bisection on φ without CCBlade code.
**Why it is here:** Extends BEMT_HAND (linear lift, no drag, no tip loss) to the features the production path uses.
**A pass means:** T and Q within 1 %.
**Not covered:** Experimental loads; Mach/Reynolds effects in the polar.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (the BEMT wrapper against a hand BEM). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 4/4 (re-run 2026-10-24 after a fix of the hand reference; the first run, 0/4, bisected across the k = 1 pole near the tip — a sign change of the residual that is not a root; `phase66_bemt_f1a.md`)
**Explanation:** With the pole excluded the hand solution equals the wrapper to five digits at both speeds, and CCBlade's φ zeroes the hand residual at every station (|R| ≤ 6e-13). The wrapper and CCBlade were not changed.
Inputs: Hartzell blade (10 stations) at 20 and 40 m/s, 4000 rpm.
Equations: BEM residual sin φ/(1+a) − V/(Ωr)·cos φ/(1−a′) = 0
Outputs: T [N], Q [N m]

### Case: BEMT_INTEGRALS
**Title:** BEMT: integrals, Froude bound, station spacing (66c)
**Map / block:** total / A_LOADS
**Category:** verification
**Kind:** runnable
**Chain span:** Blade and polars → Blade loads
**Compared with:** verification
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** B∫N′dr = T and P = ΩQ from our own trapezoid; propulsive efficiency against the Froude ideal η_i; T when the station spacing is halved.
**Why it is here:** Checks how we integrate and report the loads, and that the station count we use is converged.
**A pass means:** Integrals within 1e-10; η ≤ η_i; ΔT < 0.5 % on halving the spacing.
**Not covered:** Absolute accuracy of the loads.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (integrals, the Froude bound and station convergence: internal consistency). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 7/7 (first run 2026-10-24; `phase66_bemt_f1a.md`; information rows kept out of the count): η = 0.593 ≤ 0.919 (Hartzell), 0.626 ≤ 0.774 (Report 996); ΔT = −0.07 % (20 → 39 stations). Information: the thrust F1A radiates with AcousticAnalogies' midpoint spans is 0.997 (Hartzell) and 1.0004 (Report 996) of CCBlade's trapezoid T
**Explanation:** η = TV/(ΩQ); η_i = 2/(1 + √(1 + T/(½ρV²A))) (actuator disk). The span-weight difference is a property of the two packages' quadratures as we combine them, 0.3 % here.
Inputs: Hartzell and Report 996 blades at 20 m/s.
Equations: trapezoid with zero hub/tip loads; Froude
Outputs: T, P, η, ΔT

### Case: BEMT_SIMILARITY
**Title:** BEMT: C_T, C_P unchanged at fixed J (66d)
**Map / block:** total / A_LOADS
**Category:** verification
**Kind:** runnable
**Chain span:** Blade and polars → Blade loads
**Compared with:** verification
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** C_T and C_P of our wrapper when rpm and V scale together (×0.5, ×2, ×3) with a Re- and M-independent polar.
**Why it is here:** Non-dimensional consistency of the wrapper's coefficients (n, D definitions, unit handling).
**A pass means:** Within 1e-6 relative.
**Not covered:** Reynolds and Mach effects (real polars break similarity).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (coefficients at fixed J: similarity identity). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 6/6 (first run 2026-10-24; `phase66_bemt_f1a.md`)
**Explanation:** With c_l, c_d independent of Re and M the BEM equations depend on J = V/(nD) only.
Inputs: Hartzell blade, J = 20/(66.7 × 0.762).
Equations: C_T = T/(ρn²D⁴), C_P = 2πQ/(ρn²D⁵)
Outputs: C_T, C_P

### Case: F1A_INDEP
**Title:** Independent Farassat 1A vs AcousticAnalogies (41f)
**Map / block:** total / X_F1A
**Category:** verification
**Kind:** runnable
**Chain span:** Blade loads → Free field
**Compared with:** verification
**Source:** Farassat 1A loading; Report 996 Fig. 12 / page-12 observers; phase 41f criterion 2026-10-23
**What it tests:** Same CCBlade section loads through an independent time-domain compact-source F1A (plain Julia, thickness off) vs `evaluate_propeller_source` at x/D = −0.125 and the ±0.125 phase pair.
**Why it is here:** Isolates AcousticAnalogies wiring for failing R996_FIG12/13A, R996_PHASE, BBN_CIRC, PER_FIG7/8/9.
**A pass means:** Amplitude within 0.5 dB; phase within 2°.
**Not covered:** Experimental agreement; thickness noise; real Report 996 polars (linear cl = 2π α used to isolate F1A).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (an independent F1A implementation is another code, not a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 3/3 (max |ΔdB| ≈ 0.005, |Δφ| ≈ 0.02°) (first run 2026-10-23)
**Explanation:** Code-on-code: independent retarded-time Farassat 1A loading dipole written in the case; identical Np, Tp from CCBlade; compared to AcousticAnalogies path.
Inputs: Fig. 12-like β = 10°, M_t = 0.75, B = 2; observers x/D = ±0.125, d/D = 0.083.
Equations: Farassat 1A loading; FFT harmonics as in `evaluate_propeller_source`.
Outputs: ΔdB, Δφ [deg]; verdict 0.5 dB / 2°.

### Case: F1A_PLANE_PEAK
**Title:** F1A free field: H1 peak on the propeller line (62)
**Map / block:** total / X_FF
**Category:** verification
**Kind:** runnable
**Chain span:** Blade loads → Free field
**Compared with:** verification
**Source:** User Manual Fig. 3 grid; phase 62 criterion 2026-10-23
**What it tests:** Where the F1A free field of the aircraft example puts its largest H1 amplitude on the 160-point grid.
**Why it is here:** Gives the F1A block a check with its own figure (amplitude vs k on each ℓ line); a sign or axis error in the observer mapping moves the peak off the propeller line.
**A pass means:** The H1 maximum lies on ℓ = 1 within ±1 station of k_p.
**Not covered:** Absolute level (F1A_GUTIN, R996_*); phase.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (where the peak lies is a property of the field, not a PAIN output or a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 1/1 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`)
**Explanation:** Code check on the source block: the loudest point of the free field is the grid point closest to the propeller plane.
Inputs: examples/aircraft_scale_hartzell.json, H = 1–2.
Equations: —
Outputs: argmax (k, ℓ) of A_H1; plot of A_H1(k) per ℓ.

### Case: ISO_TABLE8
**Title:** apply_table8_calibration identity
**Map / block:** total / X_FF
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Free field
**Compared with:** verification
**Source:** phase 40d criterion 2026-10-23
**What it tests:** That `apply_table8_calibration` is the identity when ℓ = 1 peaks already equal the Table-8 peaks.
**Why it is here:** Calibration helper was untested in isolation.
**A pass means:** ≤ 1e-12 relative on all amplitudes; scales = 1.
**Not covered:** Non-identity scaling behaviour (clamped ±20 dB path).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (the Table 8 calibration is the identity on its own peaks: identity). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 483/483 (first run 2026-10-23)
**Explanation:** Isolated analytic check: grid filled with Table-8 peak amplitudes; after calibration every point and every scale must match the input within 1e-12.
Inputs: ANOPP Table 8 SPL CSV; synthetic grid at Table-8 peaks.
Equations: scale = peak_Table8 / peak_ℓ1 (identity ⇒ 1).
Outputs: amplitudes and scales; verdict ≤ 1e-12.

### Case: F1A_GUTIN
**Title:** F1A vs Gutin (far field)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Chain span:** Blade loads → Free field
**Compared with:** verification
**Source:** Gutin far-field closed form
**What it tests:** F1A loading-noise wiring vs Gutin's closed form on identical loads (far field).
**Why it is here:** Catches coding errors in the F1A path before any experiment.
**A pass means:** F1A = Gutin within 1 dB on identical loads (V-CODE-like).
**Not covered:** Not experimental; far field only; thickness off.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (Gutin's far-field formula is a different method, not a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, Δ = 0.03 dB (re-run 2026-10-24 after a code-on-code fix of the Gutin reference; criterion unchanged). Earlier record Δ = 0.31 dB (2026-10-21/23) compared F1A with a wrong closed form and is withdrawn.
**Explanation:** Code-on-code: Farassat F1A (AcousticAnalogies.jl) vs Gutin's far-field loading-noise tone in the rotor plane, on the same BEMT loads. Fix of 2026-10-24 (found by the Phase 64 unit test of the independent F1A): the reference used (mBΩ/(2πc₀r))(Q/R_tip)·J_mB(mB·M_tip), which is low by √2·M against Gutin's p_rms = (mBΩ/(2√2πc₀r))·Qc₀/(ΩR²)·J_mB(mBΩR/c₀) (Goldstein; Hubbard RP-1258) and was evaluated at the tip radius; the two errors nearly cancelled for this rotor, so the old 0.31 dB agreement was accidental. A single-radius rotating source, Gutin's exact setting, gives the independent F1A of F1A_INDEP = Gutin within 0.03 %. The reference now sums Gutin annulus by annulus over the BEMT sections (trapezoid weights of `thrusttorque`; Σ dQ = Q to 1e-15).
Inputs: examples/aircraft_scale_hartzell.json made static, thickness off; observer at 100 R_tip in the rotor plane; first harmonic H1.
Equations: F1A (AcousticAnalogies); Gutin per annulus; comparison in `_run_f1a_gutin`.
Outputs: SPL [dB]; verdict |Δ| ≤ 1 dB.

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

### Case: F1A_GUTIN_ANGLES
**Title:** F1A vs Gutin off the rotor plane, thrust and torque (66e)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Chain span:** Blade loads → Free field
**Compared with:** verification
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Our F1A path (BEMT loads → AcousticAnalogies → FFT) against Gutin summed annulus by annulus with thrust and torque, at θ = 30°–150° from the flight direction, static, 100 R_tip: H1 level and phase relative to θ = 90°.
**Why it is here:** F1A_GUTIN checks the rotor plane only, where thrust does not radiate; off the plane the thrust term and its sign enter.
**A pass means:** Within 0.5 dB and 5° at each of five angles.
**Not covered:** Near field; flight (66f); thickness (66g).
**Recorded outcome:** **Information since Phase 82 (2026-10-29): no verdict.** Not a validation case under the meaningfulness rule (Gutin's far-field formula is a different method, not a measurement; R996_FIG12/FIG14 compare F1A with measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **not met**, 4/5 (first run 2026-10-24; `phase66_bemt_f1a.md`): levels within 0.26 dB at all five angles; phase at θ = 60° 165.4° against 180° (14.6° off), others within 3.5°. Post-hoc: at 60° the thrust and torque terms cancel to 0.057 of their sum (a near-null), and at 400 R_tip the 60° phase is 176.3° (3.7° off)
**Explanation:** Frame from the AcousticAnalogies source (rotor translates along +X): θ from +X, Gutin bracket −dT cos θ + dQ c₀/(ΩR²), sections weighted by AcousticAnalogies' spans (readings fixed before the run). The 60° miss is a near-null where the residual phase is set by the O(1/r²) near-field remainder at 100 R; it moves toward 180° with distance. Criterion unchanged.
Inputs: Hartzell example, static, thickness off.
Equations: Gutin per annulus
Outputs: H1 SPL [dB], phase [deg]

### Case: F1A_GW_FLIGHT
**Title:** F1A vs Garrick–Watkins in flight (66f)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Chain span:** Blade loads → Free field
**Compared with:** verification
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Our F1A path in forward flight (observers moving with the propeller) against the Garrick–Watkins tone on the same BEMT loads, M_x = 0.1 and 0.2, θ = 60°, 90°, 120°, 100 R_tip.
**Why it is here:** Report 996 and Pereira are flight cases; Gutin covers only static rotors.
**A pass means:** Within 1 dB at every point.
**Not covered:** Non-uniform inflow; installation effects.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (Garrick–Watkins is a different method, not a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 6/6, worst 0.07 dB (first run 2026-10-24; `phase66_bemt_f1a.md`)
**Explanation:** Garrick–Watkins (x positive forward): p_rms = (mBΩ/(2√2πc₀S₀))|−dT(M_x + x/S₀)/β² + dQ c₀/(ΩR²)| J_mB(mBΩRy/(c₀S₀)), S₀ = √(x² + β²y²); reduces to Gutin at M_x = 0 (reading fixed before the run).
Inputs: Hartzell example at 34 and 68 m/s, 4000 rpm.
Equations: Garrick–Watkins per annulus
Outputs: H1 SPL [dB]

### Case: F1A_THICKNESS
**Title:** F1A thickness noise vs the compact far field (66g)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Chain span:** Blade loads → Free field
**Compared with:** verification
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Our F1A thickness noise alone (loads scaled to zero, t/c = 0.12) against the compact far-field monopole form, H1–H3, θ = 60°, 90°, 120°, static.
**Why it is here:** No other case checks the thickness term (the production default is loading only).
**A pass means:** Within 1 dB at every point.
**Not covered:** Non-compact chord effects at high harmonics (Hanson's chordwise factors → 1 in the compact limit).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (the compact monopole form is a different method, not a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 9/9, worst 0.002 dB (first run 2026-10-24; `phase66_bemt_f1a.md`)
**Explanation:** Peak amplitude ρ₀(mBΩ)²B ΣA_i Δr_i J_mB(mBΩr_i sin θ/c₀)/(2πr), A = (t/c)c² (AcousticAnalogies' area_over_chord2), from ρ₀/(4πr) ∂²/∂t²[V/(1−M_r)]; Hanson's far field in the compact-chord limit.
Inputs: Hartzell blade, static.
Equations: compact monopole far field
Outputs: SPL [dB] per harmonic

### Case: F1A_PROPERTIES
**Title:** F1A exact properties and convergence (66h)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Chain span:** Blade loads → Free field
**Compared with:** verification
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Blade-count scaling on identical prescribed loads (B = 4 H1 = 2 × B = 2 H2 at 4Ω), 1/r in the far field, and convergence in source time step and blade stations.
**Why it is here:** Shows our F1A set-up (blade replication, reception window, sampling, station count) is consistent and converged.
**A pass means:** B scaling and 1/r within 1 %; < 0.1 dB between successive halvings.
**Not covered:** Absolute level (66e–66g, F1A_GUTIN).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (blade-count and 1/r scaling and convergence: internal consistency). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 5/5 (first run 2026-10-24; `phase66_bemt_f1a.md`): ratios 2.000, 2.000, 2.0002; 64 → 128 source times −4e-6 dB; 20 → 39 stations 0.025 dB
**Explanation:** The blade-count check feeds the same CCBlade section loads to a 2- and a 4-blade rotor through `_f1a_harmonics` (the production F1A step), because BEMT loads change with B (reading fixed before the run).
Inputs: Hartzell example, static.
Equations: coherent sum of identical blades; spherical spreading
Outputs: ratios, dB changes

### Case: F1A_CHORDWISE
**Title:** F1A near field: compact vs chordwise loading at Report 996 geometry (67b)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Chain span:** Blade loads → Free field
**Compared with:** verification
**Source:** independent F1A (F1A_INDEP kinematics) with chordwise load points; rule 2026-10-24, before the run
**What it tests:** At the Report 996 Fig. 14 microphone geometry (d/D = 0.083, x/D = −0.125 … 0.5, B = 2, β₇₅ = 10°, M_t 0.45–0.90, static), the tone with each section's load spread over the chord (thin-airfoil loading, 8 points along the chord line at the section pitch) against the same load at the quarter chord.
**Why it is here:** The microphones are under two chords from the tip; the compact-chord F1A is verified only in the far field, so this tests whether compactness explains the near-field misses.
**A pass means:** Diagnostic: a point where |chordwise − compact| > 2 dB would be outside the compact-chord claim.
**Not covered:** Chordwise thickness distribution; unsteady loading; the loads themselves (POLAR_FIDELITY).
**Recorded outcome:** no verdict (diagnostic): 0/60 points beyond 2 dB, largest 0.27 dB (first run 2026-10-24; `phase67_source_attribution.md`). The compact-chord approximation does not explain the Report 996 near-field misses.
**Explanation:** With one chord point the routine reproduces the F1A_INDEP implementation (7.5e-5); spreading the load over the chord changes H1–H3 by 0.02–0.27 dB at this geometry.
Inputs: Report 996 blade, BEMT loads (clamped-linear polar; the loads are the same for both arrangements), AcousticAnalogies spans.
Equations: F1A loading term at each chord point.
Outputs: chordwise − compact [dB] per harmonic and x/D.

### Case: BBN_KIN
**Title:** BBN kinematic Δφ
**Map / block:** total / A_PHASE
**Category:** verification
**Kind:** runnable
**Chain span:** Blade loads → Free field
**Compared with:** verification
**Source:** kinematics (23a′)
**What it tests:** F1A phase difference on a hub ring equals m·B·Δψ within 0.5°.
**Why it is here:** Phase between grid points drives joint acceptance Ψ_G.
**A pass means:** Δφ = m·B·Δψ within 0.5°; reverse rotation flips sign.
**Not covered:** Sign convention is a free gauge; no measurement.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (the phase step m·B·Δψ is kinematics, not a PAIN output or a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: PASS
**Explanation:** Unit test: kinematic check that F1A phase difference on a hub ring equals m·B·Δψ within 0.5°, and reverse rotation flips the sign. Coding check of phase wiring for Ψ_G — no measurement.
Inputs: synthetic hub-ring observers; blade count B; harmonics m; rotation ±1 (runner `_run_bbn_kin`).
Equations: rigid-rotation kinematic Δφ = m·B·Δψ; F1A phase extraction.
Outputs: Δφ [deg]; verdict |Δφ − m·B·Δψ| ≤ 0.5°.

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

### Case: BBN_LONG
**Title:** BBN longitudinal phase
**Map / block:** total / A_PHASE
**Category:** extrap
**Kind:** replay
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** CR-159124 Figs. 19, 20
**What it tests:** F1A axial (longitudinal) phase pairs.
**Why it is here:** Axial phase beside circumferential.
**A pass means:** — (X-EXTRAP)
**Not covered:** Assumed blade (no chord/twist data).
**Recorded outcome:** X-EXTRAP; replay of bbn_results.csv
**Explanation:** Replay of a recorded result: axial phase from CR-159124 Figs. 19–20. X-EXTRAP: BBN blade chord, twist and airfoil are not published, so an assumed blade is used.
Inputs: recorded `bbn_results.csv`.
Equations: F1A phase (replayed).
Outputs: phase [deg]; no pass rule (X-EXTRAP).

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

### Case: PER_FIG6
**Title:** Pereira Fig. 6 spectra
**Map / block:** total / A_FWD
**Category:** experiment
**Kind:** replay
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** Pereira et al. 2026 Fig. 6
**What it tests:** F1A tones vs digitized Fig. 6 peaks (informational).
**Why it is here:** Only forward-flight spectral figure (23d does not cover it).
**A pass means:** Informational (23d does not cover Fig. 6).
**Not covered:** Motor noise above H2; far field only; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** replay of pereira_results.csv (amplitude convention fixed 2026-10-21, post-hoc)
**Explanation:** Replay of a recorded result: forward-flight spectra vs digitized Pereira Fig. 6 peaks. Informational. Motor noise above H2; far field only. Amplitude convention fixed 2026-10-21, post-hoc.
Inputs: recorded `pereira_results.csv`, `pereira_fig6_peaks.csv`.
Equations: F1A (replayed).
Outputs: SPL [dB] vs BPF harmonic; no 23d pass rule.

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

### Case: BBN_LEVELS
**Title:** BBN relative levels
**Map / block:** total / A_SURF
**Category:** extrap
**Kind:** replay
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** CR-158919 Tables 3, 4
**What it tests:** Relative in-plane levels of microphones 3–6 vs mic 4.
**Why it is here:** In-plane level shape on a fuselage-like ring.
**A pass means:** ±3 dB on SPL_i − SPL_4 (23b) — reported X-EXTRAP.
**Not covered:** Assumed blade.
**Recorded outcome:** X-EXTRAP; replay of bbn_results.csv
**Explanation:** Replay of a recorded result: relative levels SPL_i − SPL_4 (Tables 3–4, ±3 dB). X-EXTRAP for the same unpublished-blade reason as BBN_LONG.
Inputs: recorded `bbn_results.csv`, `bbn_levels_table3.csv`.
Equations: F1A levels (replayed); criterion 23b.
Outputs: relative level [dB]; reported X-EXTRAP.

### Case: BPM_RP1218
**Title:** Airfoil self-noise (BPM) vs NASA's printed code output, RP-1218 Tables D2/D3 (48a)
**Map / block:** total / A_SURF
**Category:** verification
**Kind:** runnable
**Chain span:** Blade and polars → Free field
**Compared with:** verification
**Source:** NASA RP-1218 App. D Tables D2 and D3 (printed output of NASA's prediction code); criterion fixed 2026-10-23
**What it tests:** The Julia port of the Brooks–Pope–Marcolini airfoil self-noise model (TBL-TE pressure and suction side, separation, LBL-VS, tip vortex) against NASA's own printed code output for two test cases.
**Why it is here:** Phase 48 predicts the propeller exterior broadband from this model.
**A pass means:** Within 1 dB at ≥ 90 % of the printed points.
**Not covered:** Trailing-edge bluntness noise (not ported); the rotor application.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (NASA's BPM code is not PAIN, and RP-1218's tables are its output, not a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 270/270 (max 0.19 dB; first run 2026-10-23).
**Explanation:** Code-on-code. `bpm_spectrum` is run with the App. D inputs.
Inputs: `data/rp1218/rp1218_tableD2.csv`, `rp1218_tableD3.csv`.
Equations: RP-1218 Eqs. 2–67, App. B directivity.
Outputs: 1/3-octave SPL per mechanism [dB].

### Case: PROP_BB_FIG14
**Title:** Propeller broadband (BPM) vs CR-172428 Fig. 14 free field, 5000 rpm (48c)
**Map / block:** total / A_SURF
**Category:** experiment
**Kind:** runnable
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** CR-172428 Fig. 14 (microphone 1, run 8113), digitized in Phase 47; criterion and decisions fixed 2026-10-23
**What it tests:** The blade-segment BPM sum (RP-1218 App. C procedure) at microphone 1 against the measured broadband floor.
**Why it is here:** A physics prediction of the exterior broadband would replace T2's assumed f⁻² extrapolation.
**A pass means:** Within ±5 dB in ≥ 75 % of the bands 315–2000 Hz.
**Not covered:** The real blade (proprietary; the NACA 4-(5)(08)-03 planform is a stand-in); inflow-turbulence noise; the observer is in the near field.
**Recorded outcome:** **not_met**, 3/9 (2026-10-23); BPM is 3–10 dB low. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** 3/9 (unchanged count; max error 9.8 dB, was 12; median 7.5 dB, was 9.2); not met.
**Explanation:** Experiment comparison. `propeller_broadband_spectrum` with `p48_propeller_cfg(5000)`.
Inputs: Fig. 14 pass A; assumed blade; 23.8 m/s.
Equations: RP-1218 §5 and App. C.
Outputs: 1/3-octave SPL [dB].

### Case: PROP_BB_FIG17
**Title:** Propeller broadband (BPM) vs TP-2444 Fig. 17 exterior, 4000 rpm (48c)
**Map / block:** total / A_SURF
**Category:** experiment
**Kind:** runnable
**Chain span:** Blade and polars → Free field
**Compared with:** measurement
**Source:** TP-2444 Fig. 17 exterior, digitized in Phase 47; criterion and decisions fixed 2026-10-23
**What it tests:** As PROP_BB_FIG14, at the fuselage surface in the propeller plane, 4000 rpm.
**Why it is here:** This is the exterior that T2's cabin path receives.
**A pass means:** Within ±5 dB in ≥ 75 % of the bands 315–1250 Hz.
**Not covered:** As PROP_BB_FIG14; the microphone position is not stated (V-ASSUMED).
**Recorded outcome:** **not_met**, 2/7 (2026-10-23); 1000 and 1250 Hz within 3.6 and 3.1 dB, 315–800 Hz 7–15 dB low. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** 2/7 (unchanged); not met.
**Explanation:** Experiment comparison. As PROP_BB_FIG14 at 4000 rpm.
Inputs: Fig. 17 exterior pass A.
Equations: RP-1218 §5 and App. C.
Outputs: 1/3-octave SPL [dB].

### Chunk 2: Free field (`G_FF`)

Blocks in map order: `P_FF` e11 free field → `X_SRC` Source select. Cases are listed block by block, in the order the map shows them.

### Case: E11_FREEFIELD
**Title:** Fig. E-11 free-field line
**Map / block:** total / P_FF
**Category:** input_qa
**Kind:** runnable
**Chain span:** Free field → Free field
**Compared with:** verification
**Source:** CR-3813 Fig. E-11, App. E p. E-19 / PDF p.135
**What it tests:** Whether two independent digitizations of NASA's free-field microphone line agree within 1 dB (input quality only).
**Why it is here:** That measured line (with ANOPP Table 8 for H3 and phases) drives every e11 cabin run.
**A pass means:** The figure was read repeatably (digitization scatter δ_dig ≤ 1.0 dB). It does not mean the levels are physically right.
**Not covered:** Physical accuracy of the free-field levels; H3 and all phases come from ANOPP Table 8, not from Fig. E-11.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (two digitizations of Fig. E-11 against each other: input repeatability, not the code). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: met, δmax = 1.0 dB at the limit (e11_delta_dig.md)
**Explanation:** Input QA: Fig. E-11 is sound-pressure level (SPL, dB re 20 µPa) of harmonics H1–H3 measured by NASA with microphones at free-field positions around the model propeller with the fuselage absent, along grid line ℓ = 1 (Fig. E-4), plotted against distance from the propeller plane X/D (forward positive, aft negative). NASA also plotted its ANOPP prediction. This case checks only that two independent digitizations (passes A and B) of that figure agree within 1 dB — not that the levels match physics or ANOPP. Axes: X3/D vs SPL; curves are pass A, pass B, and their mean (the input).
Inputs: Digitized CSVs from `default_e11_paths()` (`e11_freefield_measured_A.csv`, `e11_freefield_measured_B.csv`); geometry for X3/D via `grid_points` on ℓ = 1 (L = test_article_length() = 1.83 m, a = 0.508 m, φ_p = 90°, r_p = 0.965 m, z_p = 0.662 m since Phase 65); D = 0.762 m.
Equations: none (digitization comparison only); helper `delta_dig_dB`.
Outputs: δ_dig [dB] per harmonic and station; verdict uses max δ_dig ≤ 1.0 dB.

### Case: ISO_FF_CONV
**Title:** Free-field SPL↔Pa and e11 ℓ=1 loader
**Map / block:** total / P_FF
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Free field
**Compared with:** verification
**Source:** I-17 amplitude convention; Fig. E-11 / Table 8 CSVs; phase 40b criterion 2026-10-23
**What it tests:** SPL → peak Pa → SPL round-trip after I-17, and the ℓ = 1 line of `freefield_from_e11_csv` against a hand conversion of the CSV.
**Why it is here:** Conversions and the e11 loader had no isolated check (audit NONE).
**A pass means:** ≤ 1e-12 relative on every conversion and ℓ = 1 amplitude/phase row.
**Not covered:** Off-line GEXT values; broadband clip policy beyond matching the loader's written rule.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (SPL↔Pa round trip and loader against a hand conversion: identity). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 111/111 (first run 2026-10-23)
**Explanation:** Isolated analytic check: hand formulas A = √2·20μPa·10^(SPL/20) and the inverse; ℓ = 1 from the loader vs the same hand conversion of the digitized CSV (with the loader's ANOPP H≥3 / clip rule written in the case).
Inputs: synthetic SPL values; `default_e11_paths()` amp/phase/ANOPP CSVs; test-article geometry.
Equations: I-17 peak convention; `spl_dB_to_peak_Pa` / `peak_Pa_to_spl_dB` / `freefield_from_e11_csv`.
Outputs: Pa and dB; verdict ≤ 1e-12 relative.

### Case: SRC_PASSTHROUGH
**Title:** Source select: the chosen field reaches the cabin unchanged (62)
**Map / block:** total / X_SRC
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Skin field
**Compared with:** verification
**Source:** PAIN.jl `run_pain_pipeline`; phase 62 criterion 2026-10-23
**What it tests:** The amplitudes and phases stored in PainInputs against the blocked source grid, for :e11, :synthetic and (since 2026-10-28, Phase 70 F7) :aircraft, the F1A field of the working example.
**Why it is here:** Gives the source-select block a check with its own figure; a transposed or re-indexed grid would pass every downstream check silently.
**A pass means:** PainInputs amplitudes and phases identical to the blocked source grid.
**Not covered:** The physics of any source.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (the stored inputs against the source grid: plumbing identity). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 2/2 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`) **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** **met, 3/3**: the aircraft-path row (`aircraft_scale_hartzell.json`, 2 harmonics, R2) was added to the E-11 and synthetic rows (Phase 70); bit-exact (0.0 Pa).
**Explanation:** Plumbing check: what the cabin chain reads is what the source block produced (bit-identical).
Inputs: :e11 and :synthetic (H = 1–3), :aircraft with `examples/aircraft_scale_hartzell.json` (H = 1–2), blocking R2.
Equations: —
Outputs: max |Δ| of amplitude and phase arrays.

### Chunk 3: Grid and blocking (`G_GRID`)

Blocks in map order: `P_GRID` 160-point grid → `P_BLK` Blocking Eq. 43 → `X_BLK_OUT` Blocked pressures. Cases are listed block by block, in the order the map shows them.

### Case: FF_E11_MAP
**Title:** e11 free field: decay away from the measured line (62)
**Map / block:** total / P_GRID
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Skin field
**Compared with:** verification
**Source:** CR-3813 Fig. E-11 (ℓ = 1 measured line); phase 62 criterion 2026-10-23
**What it tests:** The digitized e11 free field after grid extension (GEXT): every off-line amplitude against the ℓ = 1 amplitude at the same k.
**Why it is here:** Gives the free-field block a check with its own figure; the extension must not create a louder point than the measured line it starts from.
**A pass means:** Every off-line amplitude ≤ the ℓ = 1 amplitude at the same k (48 (H, k) pairs). **Holds by construction (Phase 70 F1, 2026-10-28):** GEXT multiplies the ℓ = 1 amplitude by max(cos α, floor) ≤ 1, so this case checks the plumbing and draws the figure. It is not evidence about GEXT, which GEXT_BOUND and ISO_GEXT_LINE cover.
**Not covered:** Whether GEXT is right (phase 32 importance bound); phases.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (holds by construction (GEXT multiplies by ≤ 1)). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 48/48 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`)
**Explanation:** Monotonicity check of the GEXT field: the source is on the propeller line, so amplitude falls off around the cylinder.
Inputs: default_e11_paths(), H = 1–3.
Equations: GEXT (`extend_line_to_grid`)
Outputs: A(k, ℓ) / A(k, 1) per H.

### Case: UT_GRID
**Title:** Skin grid vs User Manual Fig. 3 (with figure)
**Map / block:** total / P_GRID
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Skin field
**Compared with:** verification
**Source:** User Manual Fig. 3
**What it tests:** That the 160 fuselage-skin grid points match the User Manual Fig. 3 coordinate and azimuth formulas, with a γ-coloured plot.
**Why it is here:** Every observer, incidence angle γ, and panel area comes from this grid.
**A pass means:** Sampled coordinates and azimuth agree with Fig. 3 formulas within 1e-9 (unit test with visualization).
**Not covered:** Acoustics at the points; GEXT; how γ enters blocking physics.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (grid coordinates against the User Manual's formulas: an input check, not a PAIN output). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: runnable unit test with figure (`docs/validation_reports/figures/UT_GRID.png`); Pkg.test "Grid geometry" / "Grid azimuth" remain. Error-panel x label is sample index (`PlotSpec.error_xlabel`), not axial z. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** the grid z of every point is now checked against z_k = z_p − x₃ by hand: **met** 35/35 (was 28/28 without the z rows).
**Explanation:** Unit test with visualization: the PAIN/ANOPP skin grid is 16 axial stations (k) × 10 azimuth lines (ℓ) = 160 points on the unrolled cylinder. Line ℓ = 1 sits at the propeller azimuth φ_p; α = (ℓ−1)·10° is the unsigned angle from that line. Incidence angle γ is the angle between the surface→hub direction and the outward normal (γ = 0 head-on). Figure: axial z vs α, points coloured by γ, with the propeller plane z = z_p and ℓ = 1 marked. Table: Manual Fig. 3 x1, x2, x3, θ at a handful of (k, ℓ); error panel x is the sample index, not z. No acoustics.
Inputs: `FuselageGeometry(L=1.83 m, a=0.508 m, θ0=56.6°)`, `PropellerPlacement(r_p=0.965 m, φ_p=90°, z_p=0.662 m)` (since Phase 65), `GridSpec()` (k_max=16, ell_max=10, k_p=8) — same family as the e11 path / Manual §5.2.
Equations: User Manual Fig. 3 / §3: x1=(r_p−a)+a(1−cos α), x2=−a sin α, x3=(π a/18)(k_p−k), θ=φ_p+α; γ via `incidence_angle_deg` (CR-3813 §3.4). Code: `grid_points`, `incidence_angle_deg`.
Outputs: x1,x2,x3 [m], θ [deg] vs formulas; figure γ [deg]; verdict on coordinate/azimuth residuals ≤ 1e-9.

### Case: GEXT_BOUND
**Title:** Grid-extension (GEXT) importance bound on T1
**Map / block:** total / P_GRID
**Category:** calibrated
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** verification
**Source:** derived (VALIDATION_GUIDELINE §2.2.1)
**What it tests:** How much the tonal interior check T1 moves when assumed GEXT falloff/delay options change.
**Why it is here:** GEXT fills 150 of 160 points from one measured line; no published data constrain that assumption.
**A pass means:** None — diagnostic with verdict always no_verdict; shows T1 is not claimable when variants flip its gate.
**Not covered:** Cannot validate GEXT (unfalsifiable by published data); amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** no_verdict (diagnostic); variants flip T1 → T1 not claimable (gext_importance_bound.md; amplitude convention fixed 2026-10-21, post-hoc) **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 5/9 variant points inside the band (no criterion). **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 5/9 variant points inside the band unchanged; nominal residuals −3.41, +0.02, +11.40 dB.
**Explanation:** Diagnostic (no pass mark): grid extension (GEXT) copies the measured ℓ = 1 free-field amplitudes onto the other azimuth lines with an assumed cosine-style amplitude falloff and a geometric travel-time phase delay — not a measured distribution. T1 is the end-to-end tonal interior SPL check vs Fig. E-16/E-17. This case re-runs the e11 cabin chain under GEXT option variants and plots how far each harmonic residual to the measured mean moves; when variants flip T1's gate, T1 cannot be claimed. Amplitude convention fixed 2026-10-21 (I-17), post-hoc.
Inputs: `default_e11_paths()` free-field/phase CSVs; `extend_line_to_grid` options `falloff_exponent`, `falloff_floor`, `delay_scale`; cabin via e11 pipe (L = test_article_length(), a = 0.508 m, blocking R2, BPF = 200 Hz); T1 means from `t1_interior_targets.csv`.
Equations: assumed GEXT falloff/delay in `extend_line_to_grid` (V-ASSUMED); cabin chain same as T1 (`run_pain_pipeline` path).
Outputs: T1 residual [dB] per harmonic H1–H3 per variant; verdict always `:no_verdict`.

### Case: ISO_GEXT_LINE
**Title:** extend_line_to_grid identity on ℓ = 1
**Map / block:** total / P_GRID
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Skin field
**Compared with:** verification
**Source:** phase 40c criterion 2026-10-23
**What it tests:** On ℓ = 1 the extension returns its input (falloff 1, delay 0) for every harmonic and option set.
**Why it is here:** On-line identity is the only GEXT check with a reference; off-line stays V-ASSUMED.
**A pass means:** ≤ 1e-12 on ℓ = 1 amplitudes and phases for all exercised options.
**Not covered:** Off-line falloff/delay physics (no reference).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (grid extension returns its input on ℓ = 1: identity). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 480/480 (first run 2026-10-23)
**Explanation:** Isolated analytic check: synthetic line amplitudes/phases; for each importance-bound option set, every ℓ = 1 point must equal the line input.
Inputs: synthetic line_amps/phases; `grid_points`; option sets (n, floor, delay_scale).
Equations: GEXT on-line identity (α = 0 ⇒ falloff = 1, R = R0 ⇒ delay = 0).
Outputs: A, φ on ℓ = 1; verdict ≤ 1e-12.

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

### Case: ISO_BLOCKING
**Title:** apply_blocking full grid vs F(γ)·A
**Map / block:** total / P_BLK
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Skin field
**Compared with:** verification
**Source:** CR-3813 Eq. (43); phase 40a criterion 2026-10-23
**What it tests:** That `apply_blocking` on all 160 points equals F(γ)·A from `blocking_factor` and the geometry's γ, with phases unchanged.
**Why it is here:** Isolates full-grid blocking from the cabin chain (BLK_P68 only checks F at given γ).
**A pass means:** Max relative difference ≤ 1e-12 on amplitudes and phases (V-UNIT).
**Not covered:** Physical correctness of Eq. (43); γ from geometry is used but not separately gated here.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (full-grid blocking against the same Eq. (43) factor: identity). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 960/960 (first run 2026-10-23)
**Explanation:** Isolated analytic check: synthetic free-field amplitudes/phases on the 160-point grid; reference is F(γ)·A with γ from `incidence_angle_deg` and F from `blocking_factor` (same Eq. 43, not `apply_blocking`). Phases must be identical to the input.
Inputs: synthetic A, φ on `grid_points` (test-article geometry); variant R1.
Equations: Eq. (43) via `blocking_factor`; `apply_blocking` under test.
Outputs: A_bl, φ_bl; verdict every row ≤ 1e-12 relative (phases absolute near zero).

### Case: BLK_GAIN_MAP
**Title:** Blocked pressures: gain within 0–6.02 dB (62)
**Map / block:** total / X_BLK_OUT
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Skin field
**Compared with:** verification
**Source:** CR-172428 Eq. (43) (R1) and CR-3813 Eq. (43) as used (R2); phase 62 criterion 2026-10-23
**What it tests:** The blocked/free gain ΔL at every grid point for both blocking variants.
**Why it is here:** Gives the blocking output a check with its own figure (ΔL vs incidence γ); a rigid surface at most doubles the pressure, so 0 ≤ ΔL ≤ 20 log10 2.
**A pass means:** 0 ≤ ΔL ≤ 6.02 dB at every grid point for R1 and R2.
**Not covered:** Diffraction around the cylinder; which variant NASA used (R2 is the production default).
**Recorded outcome:** **Information since Phase 82 (2026-10-29): no verdict.** Not a validation case under the meaningfulness rule (a 0–6.02 dB gain range is a property of Eq. (43), not a PAIN output or a measurement; E12_BLOCK compares the blocked field with measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **not met**, 1/2 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`): R2 within the bound; R1 reaches −49.3 dB at the grid points with γ > 90° (Eq. 43 as printed in CR-172428 goes negative there)
**Explanation:** The production variant R2 satisfies the physical bound. R1 is kept as the printed alternative; the case records that it leaves the bound behind the cylinder, which is why R2 is the default. No change made.
Inputs: e11 field, H = 1; γ from `incidence_angle_deg`.
Equations: Eq. (43) R1 / R2
Outputs: ΔL(γ) per variant.

### Chunk 4: Structural modes (`G_MRP`)

Blocks in map order: `X_MRP_IN` Structure inputs → `P_MRP` Structural modes → `X_MRP_OUT` Modes f_r, ψ_r. Cases are listed block by block, in the order the map shows them.

### Case: MRP_INPUT_QA
**Title:** Structure inputs vs CR-3813 App. E (62)
**Map / block:** total / X_MRP_IN
**Category:** input_qa
**Kind:** runnable
**Chain span:** Wall modes → Wall modes
**Compared with:** verification
**Source:** CR-3813 App. E pp. E-1–E-8 (`data/cr3813/appE_article_inputs.csv`, page and printed digits per value); phase 62 criterion 2026-10-23
**What it tests:** Every structural and propeller-placement value the code uses for the test article against the printed value, rounded to the printed digits.
**Why it is here:** Gives the structural input block a check with its own figure; input transcription errors are invisible to code-on-code checks. This case found the grid axial-sign and z_p errors fixed in Phase 65.
**A pass means:** Every code value equals the printed value to its printed digits.
**Not covered:** Values CR-3813 does not print (V-ASSUMED register items).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (structural inputs against App. E's printed values: an input check, not a PAIN output). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 13/13 (2026-10-23, after Phase 65; `phase62_65_map_blocks_grid.md`). Before Phase 65 the z_p row failed (0.90 m in code, 0.662 m printed on p. E-8).
**Explanation:** Input QA against the printed page. Not a fit: the printed value is the reference and nothing is chosen from a result.
Inputs: appE_article_inputs.csv; MRP_* constants; PropellerPlacement used by the cases.
Equations: —
Outputs: code / printed per quantity.

### Case: MRP_D1
**Title:** MRP Table D-1 seed
**Map / block:** none / P_MRP
**Category:** input_qa
**Kind:** runnable
**Chain span:** Wall modes → Wall modes
**Compared with:** verification
**Source:** CR-3813 Table D-1, p.113
**What it tests:** That production structural modes load Table D-1 frequencies exactly (transcription).
**Why it is here:** Production structural modes come from Table D-1, not from the raw Ritz solve.
**A pass means:** Residual 0 by construction — transcription only; verdict always no_verdict.
**Not covered:** Says nothing about the Ritz or App. D solvers.
**Recorded outcome:** by construction, no verdict **Off the map 2026-10-28 (Phase 78f, author):** no verdict is possible (MRP_D1 is 0 by construction; MRP_RITZ is a calibrated fit to Table D-1), so the case is kept as a registered regression check and unit test but no longer shown on the Validation map ("none / P_MRP"; P_MRP keeps its figure folder).
**Explanation:** Input QA: production `structural_modes_from_table_d1` copies CR-3813 Table D-1 frequencies and modal masses. Residual is 0 by construction. Always `:no_verdict`. See MRP_RITZ / MRP_APPD for solvers.
Inputs: Constant table `TABLE_D1_FULL` (n_keep = 32); L does not change the seed frequencies.
Equations: none (table load); code `structural_modes_from_table_d1`.
Outputs: mode frequencies f [Hz] equal to Table D-1; verdict `:no_verdict`.

### Case: MRP_RITZ
**Title:** MRP raw Ritz vs Table D-1
**Map / block:** none / P_MRP
**Category:** calibrated
**Kind:** runnable
**Chain span:** Wall modes → Wall modes
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Table D-1
**What it tests:** Fit quality of the simplified (w-only) Ritz structural surrogate against Table D-1.
**Why it is here:** The only check of the fitted structural surrogate (not Eq. D.25).
**A pass means:** None — calibrated fit (k_scale, edge_factor, floor_scale fitted to this table); always no_verdict.
**Not covered:** Not evidence; Eq. (D.25) not implemented in this path (w-only surrogate).
**Recorded outcome:** 29/32 within 5 % at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; was 26/32 at 1.803 m); always no_verdict (calibrated surrogate) **Off the map 2026-10-28 (Phase 78f, author):** no verdict is possible (MRP_D1 is 0 by construction; MRP_RITZ is a calibrated fit to Table D-1), so the case is kept as a registered regression check and unit test but no longer shown on the Validation map ("none / P_MRP"; P_MRP keeps its figure folder).
**Explanation:** Diagnostic / calibrated: raw `structural_modes` uses three scales fitted to Table D-1, not the printed App. D operator. Live count is reported; CLAUDE.md forbids quoting a calibrated path as a pass. Production uses Table D-1 (MRP_D1).
Inputs: `FuselageGeometry(test_article_length(), 0.508, 56.6)`; hybrid=false; n_keep=48; tol_frac=0.05; scales already in code (not re-fit here).
Equations: simplified Donnell/Ritz surrogate in `mrp.jl` (not Eq. D.25).
Outputs: f [Hz] vs Table D-1; fraction within 5 %; verdict always `:no_verdict`.

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

### Case: MRP_COUPLED_LIMITS
**Title:** App. D coupled solve: vanishing floor and near-rigid shell limits (80a)
**Map / block:** total / P_MRP
**Category:** verification
**Kind:** runnable
**Chain span:** Wall modes → Wall modes
**Compared with:** verification
**Source:** closed forms: the stiffened shell alone (App. D shell operator per harmonic) and the SS-C-SS-C orthotropic plate (Levy solution, Leissa); Phase 80a, criteria fixed 2026-10-29 before the first run
**What it tests:** The coupled shell + floor + junction solve in its two limits. A floor scaled to 1e-4 must leave the shell's modes; a shell 1e4 times stiffer must leave the floor as a plate clamped on both long edges.
**Why it is here:** Each part of `mrp_appd.jl` had its own closed-form check, but the coupled solve had none (Phase 80 plan).
**A pass means:** Vanishing floor: the 10 lowest shell-dominated modes per (M, parity), M = 1–3, within 1 % of the shell alone. Near-rigid shell: the 3 lowest floor-bending modes per (M, parity), M = 1–3, within 2 % of the clamped plate. Production input and series (NASA's deck), NASA's floor form.
**Not covered:** Intermediate stiffness ratios (80c, an independent solver, was not built; see the plan).
**Recorded outcome:** **Information since Phase 82 (2026-10-29): no verdict.** Not a validation case under the meaningfulness rule (analytic limits of the Ritz energy, and PAIN's floor form is not that energy (it misses because the code works like PAIN); MRP_APPD reproduces Table D-1 32/32). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **not met, 66/78** (first run 2026-10-29): vanishing floor 60/60 (max 0.07 %); near-rigid shell 6/18 with NASA's floor form: the first floor mode per (M, parity) is within 0.7 %, the second and third are 50–78 % low. With the floor cross terms (information rows) all within 2 % except the third antisymmetric mode, +3.3 % (NASA's 5-term floor series). Class **M** (limitation of PAIN's method as printed): NASA's floor form keeps only the diagonal of each spanwise term although cos(pπy/Lp) of different parity are not orthogonal on the floor width; this is how NASA computed Table D-1 (MRP_APPD reproduces it only with that form). The spurious second floor mode of this limit is the Table D-1 family #2, 4, 7, 11, 24 (symmetric, floor term p = 1 dominant), which the exact Ritz energy moves to above 1 kHz. Post-hoc amendment 2026-10-29: in the vanishing-floor limit a test-only floor-mass factor (1e-4) was added after the first run, because the scaled floor kept its own modes at full frequency and one sat on a shell mode (896 Hz) and split it.
**Explanation:** `_appd_family` with test-only factors `shell_kscale`, `floor_mscale` (production 1); references `_p80_shell_alone_Hz` and `_p80_clamped_plate_Hz` (validated against Leissa's square SS-C-SS-C λ = 28.95).
Inputs: `appd_nasa_deck()`; floor ×1e-4 (t, mass, D′) and floor mass ×1e-4 more; shell stiffness ×1e4; ns 0–12, np 0–5.
Equations: App. D (D.17)–(D.26); Levy plate D_y d⁴Y/dy⁴ − 2Hμ² d²Y/dy² + D_x μ⁴ Y = m ω² Y.
Outputs: frequencies per limit against the references; error in %.

### Case: MRP_SHAPE_NORM
**Title:** Table D-1 shapes: max-normalized (62)
**Map / block:** total / X_MRP_OUT
**Category:** verification
**Kind:** runnable
**Chain span:** Wall modes → Wall modes
**Compared with:** verification
**Source:** CR-3813 Table D-1 and p. D-10 (shapes normalized to unit maximum displacement); phase 62 criterion 2026-10-23
**What it tests:** max |ψ| over the shell and floor of each of the 32 Table D-1 shapes as transcribed.
**Why it is here:** Gives the structural output block a check with its own figure; the coupling bound |f′| ≤ 1 rests on max-normalized shapes.
**A pass means:** max |ψ| ≤ 1 + 1e-6 for every mode.
**Not covered:** Whether the printed coefficients are complete (Table D-1 prints the largest terms only).
**Recorded outcome:** **Information since Phase 82 (2026-10-29): no verdict.** Not a validation case under the meaningfulness rule (it tests a property of NASA's printed Table D-1, not this code; MRP_TRUNC checks the solver against the printed shapes). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **not met**, 19/32 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`): 13 shapes reach max |ψ| up to 1.245 **Transcription check 2026-10-28 (Phase 78e, two readings: the page scans of pp. D-13–D-16 and the PDF's OCR layer):** the coefficients of modes 4, 7, 11, 16, 21, 24 and 27 equal the printed values (the OCR layer misreads mode 21's .20494 as .20194; the scan reads .20494). The excess is in the printed table itself, which lists the five largest shell and three largest plate terms of each mode: recorded as a data limitation of the truncated print (§2.14 class I); criterion unchanged.
**Explanation:** Quantified 2026-10-29 (Phase 80d, `MRP_TRUNC`): the solver on NASA's deck reproduces Table D-1, and its full shapes peak at exactly 1; cut to the 5 shell + 3 floor terms Table D-1 prints, they peak at 0.77–1.23, mode by mode within 0.02 of the printed table's own peaks (largest 1.228 vs 1.254). Table D-1 prints only the largest Fourier coefficients of each mode, so the truncated sum need not peak at exactly 1. The coupling factor checks |f′| ≤ 1 on every pair it uses and none exceeds it. Recorded as a property of the printed table; no coefficient was rescaled.
Inputs: TABLE_D1_FULL / _D1_SHAPES.
Equations: Eqs. (46)–(49)
Outputs: max |ψ| per mode.

### Case: MRP_TRUNC
**Title:** App. D solver shapes: unit maximum, and the Table D-1 print truncation (80d)
**Map / block:** total / X_MRP_OUT
**Category:** verification
**Kind:** runnable
**Chain span:** Wall modes → Wall modes
**Compared with:** verification
**Source:** CR-3813 p. D-10 (shapes normalized to unit maximum displacement), Table D-1 (5 shell + 3 plate terms printed); NASA's MRP deck; Phase 80d, criteria fixed 2026-10-29 before the first run
**What it tests:** (1) The solver's full shapes (NASA's deck, the 32 lowest modes) peak at 1 over the whole shell and the floor, checked on a dense grid independent of the solver's own peak search. (2) Diagnostic: the same shapes cut to the printed 5 + 3 terms, against the printed table's own peaks.
**Why it is here:** The shape output of the structural block had only the printed-table check (MRP_SHAPE_NORM), which tests the print, not the solver.
**A pass means:** max |w| = 1 within 1e-6 for all 32 full shapes. The truncation reading of MRP_SHAPE_NORM counts as supported if the cut shapes exceed 1 in at least a third of the modes and the largest lies in [1.05, 1.5] (rule fixed before the run).
**Not covered:** NASA's own peak search on its 36-point output grid (its printed coefficients are up to 2.3 % larger than a continuous maximum gives).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (a property of the solver's shapes (unit maximum), not a PAIN output or a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met, 32/32** (first run 2026-10-29; largest deviation 1.9e-8). Diagnostic: cut to 5 + 3 terms, 16/32 exceed 1, largest 1.228 (printed 1.254): **supported**; the cut solver shapes match the printed peaks mode by mode within about 0.02.
**Explanation:** Normalization over the whole shell (until 2026-10-29 over the cabin arc only, which scaled Table D-1 mode 14, peaking below the floor, 1.26× too large). `_appd_shape_peak` (grid + golden section) in the solver; `_p80_dense_peak` (200,001-point grid via `shell_circumferential`) in the check.
Inputs: `appd_nasa_deck()`, ns 0–12, np 0–5, NASA's floor form.
Equations: (D.26)–(D.29); p. D-10 normalization.
Outputs: max |w| per mode for the full shape, the 5 + 3 cut and the printed table.

### Chunk 5: CYL2D (`G_CYL`)

Blocks in map order: `X_CYL_IN` Cabin geometry → `P_CYL` CYL2D → `X_CYL_OUT` Modes Φ_G. Cases are listed block by block, in the order the map shows them.

### Case: CABIN_GEOM_HAND
**Title:** Cabin geometry by hand (62)
**Map / block:** total / X_CYL_IN
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Cabin modes
**Compared with:** verification
**Source:** CR-3813 App. C/D geometry (Fig. D-1); phase 62 criterion 2026-10-23
**What it tests:** Cabin volume, coupling area, absorbing area and floor width against the hand formulas.
**Why it is here:** Gives the cabin geometry input block a check with its own figure (the cross-section drawn from the same numbers).
**A pass means:** Each within 1e-12 of the hand formula.
**Not covered:** Whether the test article is a cylinder with a flat floor (it is, App. E).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (cabin geometry against hand formulas). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 4/4 (first run 2026-10-23; re-run 2026-10-24 after the code review replaced the floor-width row, which compared 2a sin θ0 with itself, by the floor width the App. D plate uses; `phase62_65_map_blocks_grid.md`)
**Explanation:** Hand formulas: V = a²L(π − θ0 + cosθ0 sinθ0), A = L(Lp + 2a(π − θ0)), S = S_side + 2V/L, Lp = 2a sinθ0.
Inputs: a = 0.508 m, L = 1.83 m, θ0 = 56.6°.
Equations: App. C Eq. (C.11) area
Outputs: V, A, S, Lp.

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

### Case: ISO_CYL2D_EXACT
**Title:** cyl2d_modes vs exact circle J′ zeros
**Map / block:** total / P_CYL
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Cabin modes
**Compared with:** verification
**Source:** Neumann circular duct; phase 40e criterion 2026-10-23
**What it tests:** Floorless circular section (θ0 = 0°) against f = c·j′_{m,s}/(2πa) from independent J′ zeros.
**Why it is here:** CYL2D_C1 only compares to App. C tables of the same report.
**A pass means:** First 10 modes within 2 % at NY = 20, and max relative error at NY = 20 smaller than at NY = 10.
**Not covered:** Floored cabin (θ0 = 56.6°); Φ_G / shapes.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (an analytic circular duct, not a PAIN output or a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, max |e| NY20 = 0.966 %, NY10 = 6.676 % (first run 2026-10-23) **Map chip 2026-10-28 (Phase 79a, display only):** the NY = 10 rows are labelled "(info, production grid)" and stay in the table and figure but leave the chip count, which now reads 11/11 like the verdict (it read 12/21 because nine information rows were counted as failures).
**Explanation:** Isolated analytic check: θ0 = 0° makes the floor width zero (floor at y = −1, wall-tangent). Reference frequencies from scan+bisection zeros of J′_m (series Bessel written in the case). NY = 10 and NY = 20 both reported; pass uses the 2026-10-23 gate.
Inputs: θ0 = 0°, c0 = 340 m/s, a = 1 (unit), n_modes = 10, NY = 10 and 20.
Equations: f = c0·j′/(2π); `cyl2d_modes`.
Outputs: f [Hz]; verdict on 2 % @ NY20 and error improvement.

### Case: ISO_CYL2D_BOUNDARY
**Title:** acoustic_boundary_value and cabin_modes_3d list
**Map / block:** total / P_CYL
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Cabin modes
**Compared with:** verification
**Source:** App. C; phase 40j criterion 2026-10-23
**What it tests:** Boundary φ reconstructed from stored node values; (q, i) list complete and sorted.
**Why it is here:** Boundary interpolation and 3-D mode enumeration had no isolated gate.
**A pass means:** ≤ 1e-9 on reconstructed φ; list length/completeness/sort exact; f matches Eq. (C.7)/(C.12).
**Not covered:** Absolute CYL2D eigenvalues (see ISO_CYL2D_EXACT / CYL2D_C1).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (boundary values and mode list against the code's own nodes: internal consistency). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 173/173 (first run 2026-10-23)
**Explanation:** Isolated analytic check: at each stored wall angle, `acoustic_boundary_value` must return the stored φ; `cabin_modes_3d` must list every (q,i) once, sorted by frequency, with f from the printed formula written in the case.
Inputs: `cyl2d_modes(56.6°; NY=10)`; a = 0.508 m, L = test_article_length(), q_max = 3.
Equations: linear interpolate in θ; f_n = (c0/2π)√(λ_i/a² + (qπ/L)²).
Outputs: φ, f; verdict ≤ 1e-9 / exact list.

### Case: CYL2D_WEYL
**Title:** Cabin mode count vs Weyl's law (62)
**Map / block:** total / X_CYL_OUT
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Cabin modes
**Compared with:** verification
**Source:** Weyl's law with the rigid-wall (Neumann) surface term, 4πVf³/(3c³) + πSf²/(4c²); criterion 2026-10-28 (Phase 79d, post-hoc); first criterion (leading term) 2026-10-23
**What it tests:** The cumulative number of 3-D cabin modes (CYL2D × axial) below f at 500–1500 Hz on the production grid (NY = 10, 120 cross-section modes); the converged grid (NY = 40) as information.
**Why it is here:** Gives the cabin-mode output block a check with its own figure; a mode count far from Weyl means missing or spurious modes.
**A pass means:** The production count is within 25 % of Weyl's law with the surface term at every listed frequency (criterion dated 2026-10-28 after the counts were known, so a pass would be post-hoc; first run 2026-10-23: within 25 % of the leading term).
**Not covered:** Mode shapes; the 2-D modes above the 20 PAIN uses.
**Recorded outcome:** **Information since Phase 82 (2026-10-29): no verdict.** Not a validation case under the meaningfulness rule (Weyl's law is an asymptotic mode count, not a PAIN output or a measurement; CYL2D_C1 reproduces NASA's Table C-1). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **not met**, 0/5 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`): N/W = 1.71, 1.59, 1.49, 1.56, 1.87. Post-hoc: with the Neumann surface term N/W = 0.99, 1.07, 1.10, 1.21, 1.51 **Phase 79b (2026-10-28):** refined App. C grids now solve (only the kept modes must be real), so the NY = 10 count can be compared with a converged grid (79c–79d, planned); this record is unchanged until then. **Re-run 2026-10-28 (Phase 79d, criterion with the surface term, post-hoc):** **not met, 4/5** (NY 10: N/W = 0.99, 1.07, 1.10, 1.21, 1.51; the 1500 Hz count fails). The converged grid NY = 40 (information) gives 0.99, 1.06, 1.03, 1.02, 1.02: the excess at 1250–1500 Hz is the NY = 10 grid, not missing physics.
**Explanation:** Post-hoc diagnosis (2026-10-24, after the result): the App. C 5-point grid at NY = 10 has h = 0.2a, and its eigenvalues fall below the exact ones as kh grows (near-circle limit θ0 = 2°: k-th FD mode / k-th exact J′ zero = 0.98 at kh = 0.4, 0.80 at kh = 2.4, 0.73 at kh = 2.9; NY = 20: 0.93 at kh = 1.5). Frequencies computed too low put more modes below each f, which is the overcount that grows with f. This is a resolution limit of the App. C grid as printed (Fig. C-3 uses NY = 10), recorded as such; the criterion is unchanged.
Inputs: θ0 = 56.6°, NY = 10 (n_modes = 120) and NY = 40 (n_modes = 52, information), a = 0.508 m, L = 1.83 m, q_max from 1600 Hz.
Equations: Weyl N(f) = 4πVf³/(3c³) + πSf²/(4c²), S = curved wall + floor + two ends; leading term alone as information.
Outputs: N(f) for NY 10 and NY 40; both Weyl curves.

### Case: CYL2D_GRID_CONV
**Title:** CYL2D production grid (NY 10) vs converged grid (79c)
**Map / block:** total / X_CYL_OUT
**Category:** verification
**Kind:** runnable
**Chain span:** Cabin modes → Cabin modes
**Compared with:** verification
**Source:** CR-3813 App. C Fig. C-3 (NY = 10 grid); Phase 79c, 2026-10-28 (author: a separate figure for the grid error)
**What it tests:** The per-mode error of the App. C NY = 10 grid on the real floored section (θ0 = 56.6°) against a converged NY = 60 grid, modes paired by parity and order; NY = 40 against NY = 60 shows that the reference has converged.
**Why it is here:** CYL2D_C1 reproduces NASA's Table C-1 on NY = 10, but that says nothing about how far NY = 10 is from the continuous cabin; refined grids became solvable in Phase 79b.
**A pass means:** No criterion (information, no verdict): the error is the discretization error of the paper's grid.
**Not covered:** Mode shapes and generalized masses; whether production should move to a finer grid (decided 2026-10-28: production stays NY = 10, the grid App. C prints and NASA ran; this error is a stated limitation of the cabin modes).
**Recorded outcome:** **no verdict** (first run 2026-10-28): 19 modes, NY = 10 at most 4.94 % from NY = 60; NY 40 against NY 60 at most 0.21 %.
**Explanation:** Same `cyl2d_modes` on three grids (Phase 79b guard: only the kept modes must be real). Rows "NY40 vs NY60 (info)" stay out of the chip roll-up.
Inputs: θ0 = 56.6°, NY = 10, 40, 60, n_modes = 20 per grid, c = 340 m/s, a = 1 m.
Equations: App. C (C.3)–(C.6).
Outputs: f per mode on each grid; error of NY 10 (and NY 40, information) against NY 60 in %.

### Chunk 6: Trim and loss (`G_TRIM`)

Blocks in map order: `X_TRIM_IN` Trim stack → `P_TRIM` Trim and loss → `X_TRIM_OUT` τ, η. Cases are listed block by block, in the order the map shows them.

### Case: TRIM_INPUT_QA
**Title:** Phase III trim vs CR-3813 p. E-9 (62)
**Map / block:** total / X_TRIM_IN
**Category:** input_qa
**Kind:** runnable
**Chain span:** Damping and trim → Damping and trim
**Compared with:** verification
**Source:** CR-3813 App. E p. E-8/E-9 (`appE_article_inputs.csv`); phase 62 criterion 2026-10-23
**What it tests:** Every Phase III trim value the code uses (layer count and thickness, fiberglass density, facing and septum masses) against the printed value.
**Why it is here:** Gives the trim input block a check with its own figure.
**A pass means:** Every code value equals the printed value to its printed digits.
**Not covered:** Values CR-3813 does not give (facing side, G-10 wavespeed, connection count: register f).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (trim inputs against App. E's printed values: an input check, not a PAIN output). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 7/7 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`)
**Explanation:** Input QA against the printed page; nothing chosen from a result.
Inputs: phase3_trim() defaults; appE_article_inputs.csv.
Equations: —
Outputs: code / printed per quantity.

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
**Recorded outcome:** 7/18 bands, not met (trim_loss_e13_e14_e15.md). Isolation case TRIM_CLOSED (41b); isolation passes: remaining miss attributed to model fidelity (method), not code.
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

### Case: ISO_JOINT_ACC
**Title:** structural_joint_acceptance vs quadrature
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Wall modes → Damping and trim
**Compared with:** verification
**Source:** CR-3813 Eqs. (63)–(73); phase 40g criterion 2026-10-23
**What it tests:** `structural_joint_acceptance` against direct numerical quadrature of the joint-acceptance integral for three Table D-1 modes.
**Why it is here:** Previously only self-consistency / coarse unit-test quadrature.
**A pass means:** ≤ 1e-4 relative (mode-normalized and printed forms).
**Not covered:** End-to-end η_r vs Fig. E-15.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (joint acceptance against numerical quadrature of the same integral). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 6/6, max rel ≈ 2.7e-5 (first run 2026-10-23)
**Explanation:** Isolated analytic check: independent ring and axial sinc-kernel quadratures written in the case; product compared to `structural_joint_acceptance` at ω = ω_r for three modes.
Inputs: Table D-1 modes 1, 4, 8; a = 0.508 m, L = test_article_length(), c0 = 340 m/s.
Equations: Eqs. (63)–(73) via quadrature; code `structural_joint_acceptance`.
Outputs: j²; verdict ≤ 1e-4 relative.

### Case: TRIM_CLOSED
**Title:** Two-layer trim vs closed-form transfer matrix (41b)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Damping and trim → Damping and trim
**Compared with:** verification
**Source:** CR-3813 App. A; Fig. A-2; phase 41b criterion 2026-10-23
**What it tests:** `trim_tau` / `trim_conductance` of limp septum on a porous layer against the closed-form 2×2 product written in the case.
**Why it is here:** Isolates App. A stack algebra for failing E14_LOSS / E15.
**A pass means:** ≤ 1e-9 relative at the six Fig. A-2 frequencies.
**Not covered:** Full Phase III multi-layer stack; mechanical path.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (the trim stack against a closed-form transfer matrix: hand form). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 12/12 (first run 2026-10-23)
**Explanation:** Isolated analytic check: M = M_limp·M_ins written from Eqs. (A.10)–(A.11) in the case (independent of `stack_matrix`); τ = |a11|⁻² and ξ = Re β compared to `trim_tau` / `trim_conductance`.
Inputs: PF-105 Fig. A-2 table; thick = 0.051 m; m_sept = 0.5 kg/m²; η = 0.05; m_wall = 5 kg/m².
Equations: App. A (A.10)–(A.16).
Outputs: τ, ξ; verdict ≤ 1e-9 relative.

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
**Recorded outcome:** **not_met**, 17/32 within ±25 % (first run 2026-10-23). Modes 1–12 agree within 13 % (several within 1 %); modes 13–32 are 30–50 % low. Without the App. A correction, the floor modes come out 10–180 times too high. Our M_r^X matches App. B's printed "SHELL W": median 0.19 %, at most 3.8 % over the 21 modes above 0.05 kg (Table D-1 prints five shell terms per mode) (unit test).
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

### Case: TRIM_PASSIVITY
**Title:** Phase III trim is passive: ξ ≥ 0, η_n ≥ 0 (62)
**Map / block:** total / X_TRIM_OUT
**Category:** verification
**Kind:** runnable
**Chain span:** Damping and trim → Damping and trim
**Compared with:** verification
**Source:** CR-3813 App. A (energy: a passive wall absorbs); phase 62 criterion 2026-10-23
**What it tests:** The wall conductance ξ, the end-plate conductance, η_n of Eq. (77) and τ_t of Eq. (A.22) at every 1/3-octave band 100–6300 Hz.
**Why it is here:** Gives the trim output block a check with its own figure (τ_t and ξ vs f); a sign error in the transfer matrices shows up as negative absorption.
**A pass means:** ξ ≥ 0 and η_n ≥ 0 at every band, τ_t > 0.
**Not covered:** The size of τ_t (no measured trim transmission for the article).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (passivity is a physical bound, not a PAIN output or a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 17/17 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`)
**Explanation:** Physical bound on the App. A outputs; independent of any measurement.
Inputs: phase3_trim(), m_wall smeared; bands 100–6300 Hz.
Equations: Eqs. (A.10)–(A.22), (77)
Outputs: ξ, ξ_e, η_n, τ_t per band.

### Chunk 7: PAIN main (`G_PAIN`)

Blocks in map order: `X_PAIN_IN` Cabin inputs → `P_EQ8` Coupling / Eq. 8 → `X_OUT` Interior SPL. Cases are listed block by block, in the order the map shows them.

### Case: PAIN_INPUT_ECHO
**Title:** Resolved cabin inputs vs their documented formulas (62)
**Map / block:** total / X_PAIN_IN
**Category:** verification
**Kind:** runnable
**Chain span:** Interior tones → Interior tones
**Compared with:** verification
**Source:** User Manual cards 2, 9 and the grid relation (pp. 8–9); PainInputs docstring; phase 62 criterion 2026-10-23
**What it tests:** The inputs the PAIN core resolves for the T1 run (grid cell area, wall mass, cavity length, interior sound speed and density) against the formulas the documents give.
**Why it is here:** Gives the PAIN input block a check with its own figure; defaults resolved in the wrong place change every result without an error.
**A pass means:** Each within 1e-12 relative.
**Not covered:** Whether the documented defaults are right for an aircraft (X-EXTRAP).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (resolved inputs against the User Manual's formulas: an input check, not a PAIN output). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 5/5 (first run 2026-10-23; re-run 2026-10-24 with m_wall built from the printed App. E dimensions instead of the MRP_* constants PainInputs uses, code review; `phase62_65_map_blocks_grid.md`)
**Explanation:** Echo check: ΔA = (πa/18)², m_wall = ρ(t + A_s/d_s + A_f/ℓ_f), L_c = L, c_int = c0 = 340 m/s, ρ_int = ρ0 = 1.225 kg/m³.
Inputs: T1 pipeline inputs.
Equations: card 2, 9 rules; ΔA of the grid
Outputs: code / documented per quantity.

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

### Case: ISO_MODAL_DENSITY
**Title:** structural_modal_density and band_joint_acceptance
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Chain span:** Wall modes → Wall modes
**Compared with:** verification
**Source:** phase 40h criterion 2026-10-23
**What it tests:** Modal density equals the count of modes in each 1/3-octave band / Δω; band-average joint acceptance matches an independent discrete average.
**Why it is here:** Broadband helpers were untested in isolation (audit NONE).
**A pass means:** Count exact; band JA ≤ 1e-6 relative.
**Not covered:** Asymptotic fallback when a band is empty; experimental broadband levels.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (modal density against a count of the same modes: internal consistency). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 12/12 (first run 2026-10-23) **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** met 12/12 unchanged (round-off only). **Phase 81b (2026-10-29, post-hoc re-record):** in the 250 Hz and 397 Hz bands the raw band joint acceptance was below the code's 1e-6 floor and the reference applied the same floor, so 2 of the 12 rows passed by construction. A row at the floor now counts as not met; the pre-registered redesign (1 + the band modes' shapes) gave **10/12** (those bands hold floor-dominated modes, shell coefficients ~0.01); amended the same day, post-hoc, to a pressure matched to the band (|Σψ|, phase 0 or π): **met, 12/12**, every band ⟨j²⟩ between 2.9e-5 and 0.07, max residual 1e-15.
**Explanation:** Isolated analytic check: for bands that contain Table D-1 modes, `structural_modal_density` must equal n_count/Δω; `band_joint_acceptance` must equal the mean of j² from Eq. 42 sums and the j² formula written in the case (mode-shaped blocked field; reference applies the same 1e-6 clamp floor as the function).
Inputs: Table D-1 modes; blocked grid A = 1 + ψ_1; test-article geometry.
Equations: third-octave Δf/f = 0.2316; discrete Ψ and j² as in §3.5–3.6.
Outputs: n(ω), ⟨j²⟩; verdict count exact / ≤ 1e-6.

### Case: ISO_BB_BAND
**Title:** blocked_broadband_band_p2 vs closed-form band integral
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Chain span:** Bands and dB(A) → Bands and dB(A)
**Compared with:** verification
**Source:** phase 40i criterion 2026-10-23
**What it tests:** Band integral of S ∝ f^(−α) over exact 1/3-octave limits against the closed form (not the band-centre rectangle).
**Why it is here:** Band integral helper was untested (and previously compared to the same rectangle the code used, so it passed by construction).
**A pass means:** ≤ 1e-9 relative.
**Not covered:** Cabin broadband ⟨p²⟩ path / Fig. E-9.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (band integral against its closed form). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 8/8 (reference corrected 2026-10-23; code fixed to the exact integral the same day — code-on-code). First registration had compared the rectangle to itself (4/4, void as evidence).
**Explanation:** Isolated analytic check: Spbl_a from the H = 3 tone spatial mean spread by Δω_a = 0.232·2π·f_a (same anchor as `blocked_broadband_band_p2` in `pain_core.jl`); reference = ∫_{f1}^{f2} Spbl_a (f_a/f)^α · 2π df with f1 = fc·2^(−1/6), f2 = fc·2^(1/6) (α = 1 uses the log form). Compared to `blocked_broadband_band_p2` after the 2026-10-23 integral fix (was Spbl(fc)·0.232·2π·fc).
Inputs: synthetic blocked amplitudes; α ∈ {2.0, 1.5}; bpf = 200 Hz; fc ∈ {1000,1250,1600,2000} Hz.
Equations: closed-form power-law band integral; code `blocked_broadband_band_p2`.
Outputs: ⟨p²⟩_bl [Pa²]; verdict ≤ 1e-9 relative. Dependent recorded results that multiply this ⟨p²⟩_bl (T2 / T2_EQ19 / parametric HF bands, default α = 2) shift by −0.0082 dB at 1.25/1.6/2 kHz — not re-recorded here.

### Case: NR_BAND_HAND
**Title:** One-band NR vs hand Eqs. (17)–(18) (41c)
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Chain span:** Bands and dB(A) → Bands and dB(A)
**Compared with:** verification
**Source:** CR-3813 Eqs. (17)–(18); phase 41c criterion 2026-10-23
**What it tests:** One band of `noise_reduction_band` (one structural mode, one acoustic mode, stated η) against a hand evaluation of Eq. (18) with brace arithmetic written in the case.
**Why it is here:** Isolates the NR band assembly for failing E21_E22_NR.
**A pass means:** ≤ 1e-9 dB.
**Not covered:** Full multi-mode spectrum; HF Eqs. (19)–(23).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (one NR band against a hand evaluation of Eqs. (17)–(18)). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, residual 0 dB (first run 2026-10-23)
**Explanation:** Isolated analytic check: brace/ln/arctan/D_nr written in the case (not `nr_*`); same η_n / η_r′+η_r'' path as the function; compared to `noise_reduction_band`.
Inputs: bare cabin; fc = 400 Hz; η_n_band = 0.05; η_r_band = 0.08; q_max = 0; one mode each.
Equations: Eq. (18) hand brace; code `noise_reduction_band`.
Outputs: NR [dB]; verdict ≤ 1e-9 dB.

### Case: HF_MASSLAW
**Title:** hf_transmission_coeffs vs hand Eq. (20) (41d)
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Chain span:** Bands and dB(A) → Bands and dB(A)
**Compared with:** verification
**Source:** CR-3813 Eq. (20) / p. 24; phase 41d criterion 2026-10-23
**What it tests:** `hf_transmission_coeffs` against the documented field-incidence Eq. (20) τ_f plus the printed τ_R (not the normal-incidence mass law). It uses one limp wall mode in the band (τ_R) and one below it (τ_f). Eq. (20) sums the modes resonant below the band (CR-3813 p. 24); the in-band reading was corrected on 2026-10-23 (Phase 49).
**Why it is here:** Isolates HF transmission for failing T2 / T2_EQ19.
**A pass means:** ≤ 1e-9 relative.
**Not covered:** Normal-incidence τ = 1/(1+(ωm/2ρc)²) — the function documents field-incidence Eq. (20).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (HF transmission against a hand evaluation of Eq. (20)). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 3/3 (first run 2026-10-23; re-run 2026-10-23 after the Phase 49 correction, met) **Phase 81a (2026-10-29, display only):** the normal-incidence comparison row is labelled "(info)", so the map chip no longer shows its 250 % difference beside the pass.
**Explanation:** Isolated analytic check: hand Eq. (20) and printed τ_R at fc = 1000 Hz against `hf_transmission_coeffs`.
Inputs: bare cabin; m_wall = 8 kg/m²; one mode at 1000 Hz and one at 700 Hz.
Equations: Eq. (20); printed τ_R; code `hf_transmission_coeffs`.
Outputs: τ_f, τ_R, τ; verdict ≤ 1e-9 relative.

### Case: SHARP_PANEL_D
**Title:** Sharp double-panel construction vs CR-172490 Fig. 15, Panel D (59a)
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Chain span:** Bands and dB(A) → Bands and dB(A)
**Compared with:** verification
**Source:** NASA CR-172490 Fig. 15 and Fig. A-7; criterion fixed 2026-10-23
**What it tests:** The Sharp double-panel construction (Eqs. 5, 22, 23, 25; Fig. 5) against the source's own predicted curve for its Panel D.
**Why it is here:** It checks the bridge model's implementation before the model is used in Eq. (23).
**A pass means:** Within 1 dB at ≥ 90 % of the points 50–2000 Hz with ΔTL_M = 12 dB as stated.
**Not covered:** The source states ΔTL_M only approximately ("on the order of 12 dB"); the figure implies 10.2 dB.
**Recorded outcome:** **Information since Phase 82 (2026-10-29): no verdict.** Not a validation case under the meaningfulness rule (CR-172490's design figure is neither PAIN nor a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **not_met**, 3/13 (2026-10-23); the mass law is about 1 dB under the figure and the bridged line about 1.3 dB over it. **Phase 81c (2026-10-29):** class **N**. Fig. A-7 places the point connectors on support blocks at the longeron/frame crossings (longeron pitch 190 mm); Eq. (25) with e = 0.19 m and f_c = 7.9 kHz gives ΔTL_M = 12.6 dB, consistent with the text's "on the order of 12 dB", while the figure's curve lies 10.2 dB over its own mass line. No documented input reproduces the figure; 10.2 dB taken from it would be calibration. What the construction fixes is checked separately by `SHARP_PANEL_D_SHAPE` (met).
**Explanation:** Code-on-source. `sharp_double_panel_TL`.
Inputs: `data/cr172490/cr172490_fig15_panelD.csv`.
Equations: CR-172490 Eqs. (5), (22), (23), (25).
Outputs: TL [dB].

### Case: SHARP_PANEL_D_SHAPE
**Title:** Sharp construction segment slopes vs CR-172490 Fig. 15, Panel D (81c)
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Chain span:** Bands and dB(A) → Bands and dB(A)
**Compared with:** verification
**Source:** NASA CR-172490 Fig. 5 (construction) and Fig. 15 (Panel D); criterion fixed 2026-10-29 before the run
**What it tests:** The slopes of the three segments of the Fig. 5 construction (mass law below f₀, the 18 dB/octave rise, mass law + ΔTL_M above f_b) against the digitized Fig. 15 curve, each a least-squares slope in dB/octave.
**Why it is here:** SHARP_PANEL_D cannot pass because the source's figure and its stated ΔTL_M disagree (class N); the slopes are what the construction itself fixes, independent of ΔTL_M and of the mass-law offset.
**A pass means:** Each segment slope of the construction (63–125 Hz, 160–250 Hz, 500–1000 Hz) within ±1.5 dB/octave of the figure's.
**Not covered:** The absolute level (SHARP_PANEL_D).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (CR-172490's design figure is neither PAIN nor a measurement). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met, 3/3** (first run 2026-10-29): figure 5.9, 17.9, 5.8 dB/octave; construction 6.0, 18.0, 6.0.
**Explanation:** `_run_sharp_panel_d_shape` in `validation_case_iso59.jl`; the construction's slopes come from `sharp_double_panel_TL` at the figure's band centres, so a wrong segment slope in the code fails the check.
Inputs: `data/cr172490/cr172490_fig15_panelD.csv`; Panel D 1.6 mm aluminium skins, 82.6 mm cavity, ΔTL_M = 12 dB.
Equations: CR-172490 Eqs. (5), (22); Fig. 5.
Outputs: slope per segment [dB/octave].

### Case: ISO_SIL
**Title:** sil_dB / sil_from_third_octave hand spectrum
**Map / block:** total / X_OUT
**Category:** verification
**Kind:** runnable
**Chain span:** Bands and dB(A) → Bands and dB(A)
**Compared with:** verification
**Source:** phase 40k criterion 2026-10-23
**What it tests:** Hand-computed SIL from a known octave / 1/3-octave spectrum.
**Why it is here:** SIL helpers had only finite-value checks.
**A pass means:** ≤ 1e-9 dB.
**Not covered:** A-weighting / overall dB(A) (separate unit tests).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (SIL against a hand evaluation). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 2/2 (first run 2026-10-23)
**Explanation:** Isolated analytic check: SIL = mean of 500/1000/2000/4000 Hz octave SPLs; 1/3-octave path energy-sums bands into those octaves then averages — both formulas written in the case.
Inputs: stated octave and 1/3-octave dicts.
Equations: `sil_dB`, `sil_from_third_octave`.
Outputs: SIL [dB]; verdict ≤ 1e-9 dB.

### Case: LOUDEST_PT
**Title:** Interior level at the loudest point (42)
**Map / block:** total / X_OUT
**Category:** verification
**Kind:** runnable
**Chain span:** Interior tones → Interior tones
**Compared with:** verification
**Source:** CR-3813 Eq. (8) and App. C (Eqs. C.9–C.11); criteria fixed 2026-10-23 (plan Phase 42)
**What it tests:** The point form of Eq. (8). Acoustic modes add coherently at each interior point for every structural mode, and structural modes add in mean square. The checks: the volume average of the point values against the space average; the loudest point at or above the average; a single acoustic mode reproducing φ².
**Why it is here:** PAIN reports a space average; the loudest point is what a passenger hears at the worst seat. It is a derived output with no experimental criterion (the E-16 means are space averages).
**A pass means:** (a) the interior-node average is within 1 % of Eq. (8) for H1–H3; (b) loudest-point dB(A) ≥ space-average dB(A); (c) one mode alone gives ⟨p²⟩ ∝ φ_i² (spread ≤ 1e-9).
**Not covered:** Measured point levels; broadband at points (taken as diffuse, space-average level everywhere); tones above the changeover under `:auto` (taken as diffuse). The loudest-point position depends on the sign convention of antisymmetric modes (open item 44f).
**Recorded outcome:** **Information since Phase 82 (2026-10-29): no verdict.** Not a validation case under the meaningfulness rule (the point form against Eq. (8) is an internal consistency check; check (a)'s converged form is LOUDEST_PT_GRID). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **not_met** (first run 2026-10-23): (a) not met: 0.938 / 0.877 / 0.834. The point set excludes wall and floor nodes, where rigid-wall modes have antinodes; the ε_n normalization is exact over all nodes (ε·Φ_G/A = 1.000). (b) met: +4.6 dB. (c) met: 7e-16. Supplementary, labelled post-hoc: all nodes with the Eq. (C.10) weights give 1.027 / 1.004 / 0.986, the residual being the discrete orthogonality of the CYL2D eigenvectors. Test article: space average 79.1 dB(A), loudest point 83.7 dB(A) at X = −0.39 m, Y = −0.20 m, z = 0.92 m. Aircraft example (`aircraft_scale_hartzell.json`, X-EXTRAP): 93.8 dB(A) average, 98.4 dB(A) at the loudest point (z = 0, the forward end). **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** (a) 0.936 / 0.886 / 0.901 (all-node 1.011 / 0.995 / 0.978); test article 80.4 dB(A) average, 85.5 dB(A) at the loudest point. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** test article 80.0 dB(A) space average, 84.3 dB(A) loudest point (was 80.4 / 85.5); (a) not met unchanged. **Phase 81d (2026-10-29):** on the converged grid NY = 40 the all-node Eq. (C.10)-weighted average equals Eq. (8) within 0.07 % (`LOUDEST_PT_GRID`, met), while the interior-node ratio is 0.98 / 0.98 / 0.97: the point form is right, and check (a) misses because its pre-registered point set leaves out the wall and floor nodes (class D, test design).
**Explanation:** `cabin_interior_points`, `point_tone_p2`, `loudest_point` in `loudest_point.jl`; `cabin_quadrature_points` for the supplementary check.
Inputs: T1 test-article inputs; aircraft example.
Equations: Eq. (8) at points; φ_n = cos(qπz/L_c) φ_i(node) (Eq. C.9).
Outputs: point tone levels, loudest-point and space-average dB(A), position.

### Case: LOUDEST_PT_GRID
**Title:** Point form of Eq. (8) on the converged CYL2D grid, NY = 40 (81d)
**Map / block:** total / X_OUT
**Category:** verification
**Kind:** runnable
**Chain span:** Interior tones → Interior tones
**Compared with:** verification
**Source:** CR-3813 Eq. (8) and App. C (Eqs. C.9–C.11); criterion fixed 2026-10-29 before the run
**What it tests:** The volume average of the point values of Eq. (8), over all CYL2D nodes with the Eq. (C.10) weights, against Eq. (8) itself, on the converged grid NY = 40 (79b).
**Why it is here:** LOUDEST_PT check (a) misses because of its point set (wall and floor nodes left out); this checks the point form itself.
**A pass means:** Within 1 % of Eq. (8) for H1–H3.
**Not covered:** The production grid NY = 10 (LOUDEST_PT); measured point levels.
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (the point form against Eq. (8): internal consistency). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met, 3/3** (first run 2026-10-29): 1.0004, 1.0001, 0.9993; interior nodes only (information) 0.982, 0.976, 0.965.
**Explanation:** `_run_loudest_pt_grid` in `loudest_point.jl`: the T1 test-article pipeline with `NY = 40`, `cabin_quadrature_points`, `point_tone_p2`, `point_volume_average`.
Inputs: T1 test-article inputs (e11 source, R2 blocking, BPF 200 Hz), NY = 40.
Equations: Eq. (8) at points; φ_n = cos(qπz/L_c) φ_i(node) (Eq. C.9); weights Eq. (C.10).
Outputs: volume average / Eq. (8) per harmonic.

### Chunk 8: Validation comparisons (`G_VAL`)

Blocks in map order: `P_REPRO` vs NASA PAIN → `P_MEAS` vs measurement → `A_CABIN` Aircraft cabin. Cases are listed block by block, in the order the map shows them.

### Case: REPRO_18b
**Title:** PAIN reproduction (18b-r)
**Map / block:** total / P_REPRO
**Category:** calibrated
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-16 NASA PAIN circles, p.142
**What it tests:** Whole cabin chain on ANOPP Table 8 with R1 vs NASA's PAIN interior predictions.
**Why it is here:** Shows whether this chain computes what NASA's program computed (code-on-code).
**A pass means:** Code-to-code agreement within 4 dB per harmonic H1–H3.
**Not covered:** η_T = 0.5 adopted after 19f showed the result (post-hoc); conditional on GEXT; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** 18b-r not met 1/3: 85.90, 78.35, 79.82 dB at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 85.74, 78.74, 80.06 — `length_sensitivity.md` / `pain_reproduction_e16.md`). Phase 38b `:auto` (report only, ten-mode crossover): 85.90, 16.81, 72.24 dB; H3 Δ=+4.24 (I-18 explains H3 = no); `phase38b_high_freq_tones.md`. **43a post-hoc re-run (2026-10-23):** Manual card 10 volume crossover default (f≈1299.6 Hz → band 1260 Hz); `:auto` H1–H3 = 85.90, 78.35, 79.82 dB (= `:eq8`; old ten-mode `:auto` kept above). Isolation case T1_FROM_E12 (41a) also not met (2/3, H3 fails) → cabin chain implicated, not source/blocking alone. **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 85.93, 78.32, 79.57 dB; 1/3, verdict unchanged. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 0/3 (89.03, 81.24, 77.06 dB). REPRO_18b compares with NASA's pre-correction CR-3813 run, which used the other sign. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 0/3 (88.20, 80.43, 78.21 dB; was 89.03, 81.24, 77.06). Phase 93 default form (2026-10-29): not met, 1/3. Phase 96 default (2026-10-30): not met, 1/3.
**Explanation:** Code-on-code (against printed values): run the cabin chain on ANOPP Table 8 with blocking R1 and Phase III trim η_T = 0.5 (NASA's value) and compare interior SPL with NASA's PAIN circles on Fig. E-16 (±4 dB per harmonic). Axes: harmonic band vs SPL; NASA circles vs this code. η_T = 0.5 was adopted after 19f → post-hoc. Conditional on GEXT.
Inputs: `default_e11_paths().anopp_spl`; `phase3_trim(; η_lining=0.5)`; blocking R1; BPF = 200 Hz; n_harmonics = 3; L = 1.83 m; targets `t1_interior_targets.csv` (NASA PAIN column).
Equations: full cabin chain; tone Eq. (8) via `run_pain_pipeline` / `tone_mean_square_pressure`; blocking Eq. (43) R1.
Outputs: interior SPL_H1..H3 [dB]; verdict |Δ| ≤ 4 dB vs NASA PAIN prediction.

### Case: E18_TONES
**Title:** Fig. E-18 tones (η_T=1)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-18, p.E-29; e18_interior_pred_eta1.csv
**What it tests:** Tones with η_T = 1.0 and η_r′ ≤ 0.15 vs NASA E-18 prediction.
**Why it is here:** NASA's η_T = 1.0 / capped-η_r′ setting (same as E-21) on the tone path.
**A pass means:** |computed − NASA E-18 prediction| ≤ 4 dB at each of H1–H3 (bands 200, 400, 630 Hz).
**Not covered:** :auto and measured mean/low/high are secondary (V-EXP held out); no parameter from E-18.
**Recorded outcome:** 2/3 within ±4 dB (88.67, 77.78, 77.55 dB) at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 89.02, 78.14, 77.70); not met; e18_tones_eta1.md. **43a post-hoc re-run (2026-10-23):** volume crossover default; production `:eq8` unchanged 88.67, 77.78, 77.55; `:auto` old (ten-mode) 88.67, 13.18, 67.39 → new (volume) 88.67, 77.78, 77.55. **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 2/3 unchanged; `:auto` secondary 88.69, 77.76, 77.33 dB. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 1/3; `:auto` secondary 91.17, 80.44, 75.24 dB (E-18 is also a pre-correction run). **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 1/3 unchanged; `:auto` secondary 90.35, 79.63, 76.56 dB (was 91.17, 80.44, 75.24). Phase 93 default form (2026-10-29): not met, 2/10. Phase 96 default (2026-10-30): not met, 2/10.
**Explanation:** Code-on-code (against NASA prediction): same free-field/blocking/grid as 18b-r but Phase III trim η_T = 1.0 and η_r_cap = 0.15 on the tone path (`tone_model=:eq8`). H1–H3 map to 200, 400, 630 Hz (H3 at 3·BPF = 600 Hz → 630 Hz 1/3-octave band). Criterion dated 2026-10-21 (same ±4 dB as 18b).
Inputs: `default_e11_paths()`; `phase3_trim(; η_lining=1.0)`; η_r_cap = 0.15; BPF = 200 Hz; L = 1.83 m; `e18_interior_pred_eta1.csv`.
Equations: Eq. (8) tones; Eq. (82) capped η_r′; blocking as in pipeline.
Outputs: interior SPL [dB] at 200/400/630 Hz; verdict ≤ 4 dB vs NASA E-18 prediction.

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

### Case: REPRO_18b_PRE
**Title:** REPRO_18b with NASA's pre-correction Eq. (52) floor sign (61b)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-16 NASA prediction; CR-172428 p. 178; criterion fixed 2026-10-23
**What it tests:** The tone chain with the floor-term sign of NASA's program before its CR-172428 correction, against CR-3813's printed prediction.
**Why it is here:** CR-3813's runs predate the correction; this tests whether that explains REPRO_18b's 6–10 dB.
**A pass means:** |Δ| ≤ 4 dB at H1–H3.
**Not covered:** Other undocumented differences in NASA's 1983 runs.
**Recorded outcome:** **Diagnostic since Phase 86 (2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It re-runs another case with one program form or input set changed to test a documented cause of that case's miss; the case it re-runs carries the verdict. The run and its table are unchanged; the outcome before, kept as a record and not a pass: **not_met**, 1/3 (2026-10-23): 85.93, 78.32, 79.57 dB against 79.0, 75.5, 68.0 dB (corrected form 89.03, 81.24, 77.06). **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 1/3 unchanged (85.11, 77.61, 81.85 dB; corrected form 88.20, 80.43, 78.21).
**Explanation:** Code-on-code. `floor_sign = −1`.
Inputs: As REPRO_18b.
Equations: Eq. (8), Eq. (52).
Outputs: SPL H1–H3 [dB].

### Case: E21_PRE
**Title:** E-21 NASA NR with NASA's pre-correction Eq. (52) floor sign (61c)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-21 NASA prediction; criterion fixed 2026-10-23
**What it tests:** Eq. (18) with the pre-correction floor sign against NASA's printed NR prediction.
**Why it is here:** It is the same question for the noise-reduction path.
**A pass means:** |Δ| ≤ 3 dB in ≥ 75 % of the counted bands (38a).
**Not covered:** As REPRO_18b_PRE.
**Recorded outcome:** **Diagnostic since Phase 86 (2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It re-runs another case with one program form or input set changed to test a documented cause of that case's miss; the case it re-runs carries the verdict. The run and its table are unchanged; the outcome before, kept as a record and not a pass: **not_met**, 1/4 (2026-10-23); 400–630 Hz within 0.6–1.9 dB (not counted); 800–1000 Hz 6–18 dB above NASA.
**Explanation:** Code-on-code. `floor_sign = −1`, E-21 inputs.
Inputs: E-21 inputs.
Equations: Eq. (18), Eq. (52).
Outputs: NR [dB].

### Case: E21_PRE_DECK
**Title:** E-21 NR, pre-correction form, on NASA's 300 modes vs NASA's E-21 prediction (84c)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-21 NASA prediction; NASA's MRP deck; CR-172428 Table 6; criterion fixed 2026-10-29 before the run (plan §8ab)
**What it tests:** E21_PRE (pre-correction floor sign, Phase III η_T = 1.0, η_r′ ≤ 0.15) with NASA's 300 structural modes in place of Table D-1's 32.
**Why it is here:** Table D-1's modes stop at 811 Hz; the mode set was untested in the Eq. (18) path (Phase 84a).
**A pass means:** |NR − NASA's E-21 prediction| ≤ 3 dB in ≥ 75 % of the counted bands (E21_PRE's criterion).
**Not covered:** The end-plate allowance of ref. [7] (80–160 Hz, not counted).
**Recorded outcome:** **Diagnostic since Phase 86 (2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It re-runs another case with one program form or input set changed to test a documented cause of that case's miss; the case it re-runs carries the verdict. The run and its table are unchanged; the outcome before, kept as a record and not a pass: **not_met**, 1/4 counted bands (2026-10-29, first run), the same as E21_PRE. The counted bands are those below E21_PRE's ten-mode crossover (400 Hz), where Table D-1 already has every mode, so they move < 0.4 dB; the 84a audit row expected the Eq. (18) bands to reach 1260 Hz, which holds for the volume crossover, not E21_PRE's (corrected 2026-10-29 after the run). Above the crossover the 300 modes lower NR by up to 27 dB (not counted).
**Explanation:** Code-on-code; `noise_reduction_spectrum` on `noise_reduction_test_article_inputs(; structural_set=:deck)` with `floor_sign = −1`.
Inputs: as E21_PRE; `nasa_deck_modes()`.
Equations: Eqs. (17)–(18) below the crossover, (19)–(23) above.
Outputs: NR [dB] per band, with the Table D-1 run beside it.

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

### Case: E22_HF_DECK
**Title:** High-frequency NR on NASA's 300 modes vs NASA's E-22 prediction (83b)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-22 NASA prediction; NASA's MRP deck (User Manual pp. 42–43); CR-172428 Table 6 (300 structural modes); criterion fixed 2026-10-29 before the run (plan §8aa)
**What it tests:** E22_HF_CODE with the structural modes NASA ran PAIN with: the App. D solver on NASA's deck, 300 modes to 3.7 kHz, in place of Table D-1's 32 (to 811 Hz). Every other input as E22_HF_CODE.
**Why it is here:** With Table D-1 no structural mode is resonant at 1250–2500 Hz, so Eqs. (19)–(23) fall back to an asymptotic density; this was the one untested cause of the code-to-NASA difference (Phase 83a).
**A pass means:** |Δ| ≤ 3 dB of NASA's prediction in ≥ 75 % of the bands 1250–2500 Hz (E22_HF_CODE's criterion).
**Not covered:** NASA's 1983 high-frequency routine is not printed; CR-3813 does not state its own mode count for E-22.
**Recorded outcome:** **Diagnostic since Phase 86 (2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It re-runs another case with one program form or input set changed to test a documented cause of that case's miss; the case it re-runs carries the verdict. The run and its table are unchanged; the outcome before, kept as a record and not a pass: **not_met**, 0/4 (2026-10-29, first run): code − NASA −5.7, −13.7, −18.2, −18.5 dB (Table D-1: +7.7, +2.1, −6.5, −5.6); 39–68 modes resonant per band. The resonant modes lower NR by 12–19 dB, past NASA's curve, so the mode set does not explain the difference; as fixed before the run, no other count is tried and the high-frequency cases keep Table D-1.
**Explanation:** Code-on-code. `hf_pressure_ratio` on `noise_reduction_test_article_inputs(; structural_set=:deck)`.
Inputs: E-22 data; E-21 inputs; `nasa_deck_modes()`.
Equations: Eqs. (19)–(23).
Outputs: NR [dB], with the Table D-1 run beside it.

### Case: REPRO_18b_DECK
**Title:** REPRO_18b on NASA's 300 modes vs E-16's NASA prediction (83e)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-16 NASA PAIN circles; NASA's MRP deck; CR-172428 Table 6; criterion fixed 2026-10-29 before the run (plan §8aa)
**What it tests:** REPRO_18b with NASA's 300 deck modes in place of Table D-1's 32; everything else as REPRO_18b.
**Why it is here:** REPRO_18b_PRE already reverts all three CR-172428 App. A program changes; the mode set was the one input left (Phase 83a).
**A pass means:** |Δ| ≤ 4 dB at H1–H3 against E-16's NASA prediction (REPRO_18b's criterion).
**Not covered:** CR-3813 does not state the mode count of its E-16 run.
**Recorded outcome:** **Diagnostic since Phase 86 (2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It re-runs another case with one program form or input set changed to test a documented cause of that case's miss; the case it re-runs carries the verdict. The run and its table are unchanged; the outcome before, kept as a record and not a pass: **not_met**, 0/3 (2026-10-29, first run): 88.15, 80.58, 78.33 dB against NASA's 79.0, 75.5, 68.0 (Table D-1: 88.20, 80.43, 78.21). The tones move < 0.2 dB, so the mode set is not the cause. **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** 0/3 (88.57 / 79.58 / 78.91 dB).
**Explanation:** Code-on-code. Tones of Eq. (8) via `interior_spl` on the REPRO_18b inputs with `nasa_deck_modes()`.
Inputs: as REPRO_18b; `nasa_deck_modes()`.
Equations: full cabin chain, Eq. (8).
Outputs: SPL H1–H3 [dB], with the Table D-1 run beside it.

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

### Case: R172428_CODE_DECK
**Title:** CR-172428 reproduction on NASA's 300 modes vs NASA's printed predictions (84b)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** NASA CR-172428 App. B / Table 10 (NASA's predictions), Table 6 (300 structural modes); NASA's MRP deck; criterion fixed 2026-10-29 before the run (plan §8ab)
**What it tests:** R172428_CODE with NASA's 300 structural modes (`nasa_deck_modes()`) in place of 32; everything else as R172428_CODE.
**Why it is here:** NASA's corrected-program runs used 300 structural and 400 acoustic modes; our acoustic list equals NASA's printed one, so the structural count was the one mode input left (Phase 84a).
**A pass means:** ±3 dB of NASA's printed prediction at ≥ 7 of 9 points (R172428_CODE's criterion).
**Not covered:** NASA's modes above Table D-1 are not printed, so the deck solve stands in for them.
**Recorded outcome:** **Diagnostic since Phase 86 (2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It re-runs another case with one program form or input set changed to test a documented cause of that case's miss; the case it re-runs carries the verdict. The run and its table are unchanged; the outcome before, kept as a record and not a pass: **not_met**, 4/9 (2026-10-29, first run), the same count as R172428_CODE: 3000 rpm 70.84, 68.60, 61.66; 4000 rpm 102.41, 79.91, 71.94; 5000 rpm 90.15, 94.49, 80.58 dB (Table D-1: 71.07, 69.02, 62.66; 102.45, 80.05, 71.69; 90.35, 94.40, 78.40). The levels move ≤ 2.2 dB, so the mode count is not the cause. **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** 4/9.
**Explanation:** Code-on-code; `r172428_inputs(rpm; structural=:nasa300)`, tones of Eq. (8).
Inputs: as R172428_CODE; `nasa_deck_modes()`.
Equations: full cabin chain, Eq. (8).
Outputs: SPL H1–H3 at 3000/4000/5000 rpm [dB].

### Case: R172428_PAIRS
**Title:** CR-172428 top modal contributions vs App. B (diagnostic)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** NASA CR-172428 App. B p. 207 (five largest acoustic × structural contributions per harmonic, 4000 rpm); no criterion
**What it tests:** Our mean-square contribution for each pair NASA printed, as a ratio in dB, plus our own largest pair per harmonic.
**Why it is here:** It localizes the R172428_CODE difference to individual mode pairs.
**A pass means:** No criterion (always `:no_verdict`).
**Not covered:** 3000 and 5000 rpm (not transcribed).
**Recorded outcome:** diagnostic (2026-10-23): pairs with shell-dominated modes agree within 0.4–2.5 dB (e.g. (2,0)×6 −0.6 dB, (2,3)×21 −0.4 dB). Pairs with floor-dominated modes 1 and 2 are 10–12 dB low. Our largest H1 pair, (0,1) × mode 8 (antisymmetric), does not appear in NASA's list at all. Open item: the floor/antisymmetric coupling path. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 12 of NASA's 15 printed pairs within ±3.7 dB (was 4 within ±3 dB); the bare f′ implied by NASA's printed η_r″ matches |I_s + I_p| within 1.1 % for 9 of 10 further pairs at 5000 rpm (out of sample); remaining outliers H3 (2,8)×22 −9.7, (2,8)×17 −6.4 dB, and our H1 pair (0,1) × mode 8 (5.6 Pa²), absent from NASA's list. Our largest pairs at 4000 and 5000 rpm all have q = 0 cabin modes, and NASA's printed lists have none; dropping q = 0 (a diagnostic, not adopted: Eq. 57 and Ref. [3] give f₀M ≠ 0) would make R172428_CODE 8/9 (plan Q22).
**Explanation:** `modal_tone_contributions` on `r172428_inputs(4000)`.
Inputs: `appB_contributors_4000rpm.csv`.
Equations: Eq. (8) per pair.
Outputs: per-pair ratio [dB].

---

### Case: UNC_COVER
**Title:** Uncertainty coverage vs E-16 means (31e)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** measurement
**Source:** CR-3813 Fig. E-16 measured means; phase 31 pre-registration 2026-10-22
**What it tests:** Whether the untuned parametric cabin Monte Carlo P5–P95 band (NASA free field, a-priori ranges) contains the measured E-16 mean at H1–H3.
**Why it is here:** Coverage check on the test article before trusting the aircraft epistemic band; can fail without widening ranges in this run.
**A pass means:** Measured mean at each of H1, H2, H3 lies inside the primary (uniform) MC P5–P95; `:met` only if all three.
**Not covered:** Not a confidence interval; no E-16 envelope floor; no tuned value; scattering/refraction excluded (V-ASSUMED); aircraft source residuals not in this check.
**Recorded outcome:** `:not_met` — H1 P5/P50/P95 88.95/89.87/91.06 vs mean 90 (inside, margin +1.05 dB); H2 85.46/91.3/92.86 vs 80 (miss −5.46); H3 73.09/74.78/77.59 vs 65 (miss −8.09); kept `freq_scale`, `eta_t`; `uncertainty_budget_testarticle.md` (first run 2026-10-22) **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 0/3 within criterion (H1 margin −0.86 dB, was +1.05; H2 −5.45, H3 −8.09); verdict unchanged (not_met). **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 0/3 (margins −0.81, −5.87, −10.24 dB). **Phase 78d knock-on (2026-10-28, App. D stiffener inputs corrected; post-hoc):** 1/3 (margins +0.19, −2.09, −18.47 dB); verdict unchanged (not met). **Phase 78d-3 knock-on (2026-10-28, floor beams about the floor mid-plane; post-hoc):** 1/3 (margins +0.52, −0.11, −18.36 dB); not met. **Phase 78d-4 knock-on (2026-10-28, App. D consistency fixes J1–J6; post-hoc):** 0/3 (margins H1 −4.06, H2 −5.41, H3 −13.23 dB; band medians 95.3, 87.7, 80.2 dB against the measured 90, 80, 65); not met. **Phase 80 knock-on (2026-10-29, App. D solver on NASA's series limits, whole-shell normalization, exact M_r; post-hoc):** 0/3 (margins H1 −3.67, H2 −6.84, H3 −12.88 dB); not met.
**Explanation:** Experiment comparison (V-EXP vs measured E-16 means; first run 2026-10-22; pre-registered): untuned `:parametric` chain on the NASA test article with the phase-31 a-priori budget; OAT keep (>3 dB); primary Monte Carlo N=4000 seed 20261022; plot P5–P95 band with measured means. Failure means a missing contributor or ranges too narrow — do not widen here.
Inputs: `cabin_blocks=:parametric`, `source=:e11`, Phase III trim path with η_t in 0.01–0.10 (nominal 0.05), C 2–4, freq scale 0.95–1.05, discrete CYL2D/q_max/blocking/trim alternatives; `t1_interior_targets.csv` measured means 90/80/65 dB; L = 1.83 m.
Equations: App. D modes + Eq. (8) tones; App. A trim; no E-16 envelope in the band.
Outputs: P5/P50/P95 [dB] per H1–H3; per-harmonic inside/margin; verdict `:met`|`:not_met`.

### Case: T1
**Title:** Tonal interior SPL (T1)
**Map / block:** total / P_MEAS
**Category:** calibrated
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** measurement
**Source:** CR-3813 Fig. E-16/E-17, p.142
**What it tests:** End-to-end tonal interior SPL on the e11 measured free-field path vs Fig. E-16/E-17.
**Why it is here:** Only end-to-end tonal SPL check against measurement (still not claimable after GEXT_BOUND).
**A pass means:** In-sample consistency (gate A mean ± 4 dB, or gate B envelope + NASA ± 4 dB).
**Not covered:** No claim: GEXT variants flip it; H3 fails; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** 84.21, 77.66, 78.06 dB at L = 1.83 m (H1 fail, H2 pass, H3 fail); t1_tonal.md (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 84.05, 78.01, 78.30). **43a post-hoc re-run (2026-10-23):** volume crossover default; production `:eq8` unchanged 84.21, 77.66, 78.06; `:auto` old (ten-mode) 84.21, 16.22, 70.54 → new (volume) 84.21, 77.66, 78.06. Isolation case T1_FROM_E12 (41a) also not met (2/3, H3 fails) → cabin chain implicated, not source/blocking alone. Related: T1_MEAS_DAMPING (43b), T1_F1A_FILL (43f). **Phase 44 knock-on (2026-10-23, code-on-code fix of Eq. (83): η_r″ uses the bare f′):** 84.24, 77.63, 77.80 dB; verdict unchanged. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 87.36, 81.02, 75.23 dB; H1 and H2 now within the gate, H3 fails (+10.2 dB); verdict not_met. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 86.59, 80.02, 76.39 dB (was 87.36, 81.02, 75.23); H1 and H2 within the gate, H3 fails (+11.4 dB); verdict not_met. Phase 93 default form (2026-10-29): not met, 3/6.
**Explanation:** Experiment comparison (calibrated / in-sample): e11 free-field → GEXT → blocking R2 → modes → Eq. (8) → interior tonal SPL vs measured Fig. E-16/E-17. Gate A: |got − measured mean| ≤ 4 dB; gate B: inside measured envelope and |got − NASA PAIN| ≤ 4 dB. Axes: 1/3-octave band vs SPL. No claim after GEXT_BOUND.
Inputs: `run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200, blocking=R2)`; η_T = 0.5 default path; `t1_interior_targets.csv`; L = 1.83 m.
Equations: full chain; Eq. (8); GEXT; Eq. (43) R2.
Outputs: SPL_H1..H3 [dB]; verdict on gates A/B (still labeled not claimable).

### Case: T2
**Title:** 1/3-octave (T2)
**Map / block:** total / P_MEAS
**Category:** calibrated
**Kind:** runnable
**Chain span:** Free field → Bands and dB(A)
**Compared with:** measurement
**Source:** CR-3813 Fig. E-9, p.132
**What it tests:** Broadband 1/3-octave interior SPL (surrogate path) vs Fig. E-9 at 1.25–2 kHz.
**Why it is here:** Tonal model puts no energy above 1 kHz; this covers three high bands (surrogate).
**A pass means:** In-sample: |got − measured mean| ≤ tol_dB from CSV; bb_j2_scale = 0.5 was fitted earlier (stale).
**Not covered:** Only 1.25–2 kHz; nothing above; amplitude convention fixed 2026-10-21, post-hoc. The exterior broadband input is modelled (V-ASSUMED). Phase 47 (2026-10-23) found a measured exterior for this article: the modelled one is 17 dB above it, and with the measured exterior this path gives 38.6 dB (Eqs. 19–23: 21.6 dB) against 51.0 dB at 1250 Hz. The surrogate's closeness to E-9 therefore rests on compensating errors. Phase 55 decision (2026-10-23): it stays the production default, labelled calibrated, because neither cabin path is validated above 1 kHz and switching would change the frozen baselines.
**Recorded outcome:** **Information since Phase 83d (2026-10-29): no verdict.** Not a validation case under the meaningfulness rule: its broadband path uses `bb_j2_scale`, fitted to Fig. E-9, and is compared with Fig. E-9; T2_EQ19 is the printed-method T2. The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: 55.92, 53.56, 51.59 dB at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 55.97, 53.63, 51.67); t2_third_octave.md. Isolation case HF_MASSLAW (41d); isolation passes: remaining miss attributed to model fidelity (method), not code.
**Explanation:** Experiment comparison (calibrated): surrogate broadband path vs Fig. E-9 means at 1.25, 1.6, 2 kHz. bb_j2_scale = 0.5 fitted earlier → post-hoc. Printed Eqs. (19)–(23) are case T2_EQ19.
Inputs: `run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200, blocking=R2)`; `t2_third_octave_targets.csv`; bb_j2_scale = 0.5; L = 1.83 m.
Equations: surrogate broadband (not printed Eqs. 19–23); `evaluate_T2`.
Outputs: 1/3-octave SPL [dB] at target bands; verdict vs CSV tol_dB.

### Case: T2_EQ19
**Title:** 1/3-octave Eq.(19) (T2_EQ19)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Free field → Bands and dB(A)
**Compared with:** measurement
**Source:** CR-3813 Fig. E-9, p.132; Eqs. (19)–(23) pp.23–25
**What it tests:** Printed high-frequency broadband Eqs. (19)–(23) vs Fig. E-9.
**Why it is here:** First printed-model run replacing the surrogate / stale bb_j2_scale path.
**A pass means:** Same T2 criterion: |got − Fig. E-9 mean| ≤ 3.5 dB at 1.25, 1.6, 2 kHz (criterion unchanged).
**Not covered:** Spbl ∝ f^−2 anchor remains V-ASSUMED; only three bands; no parameter chosen from E-9/E-21/E-22. Exterior broadband not measured for this article; the input is assumed (V-ASSUMED); the high-frequency transmission path is validated by NR_TP1964 (phase 43e, 2026-10-23).
**Recorded outcome:** 0/3 PASS (38.56, 35.81, 34.87 dB vs 51/46/41.5) at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 38.59, 35.87, 34.94); full-band E-21/E-22 V-CODE 1/13, V-EXP 0/15; phase38c_hf_broadband.md. Isolation case HF_MASSLAW (41d); isolation passes: remaining miss attributed to model fidelity (method), not code. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 0/3; full band V-CODE 0/13, V-EXP 1/15. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 0/3 (38.85, 35.94, 34.90 dB); full band V-CODE 0/13, V-EXP 1/15 unchanged. Phase 93 default form (2026-10-29): not met, 4/19.
**Explanation:** Experiment comparison: interior 1/3-octave SPL with `broadband_model=:eq19` (printed τ_f, τ_R, ᾱ from Eq. 24/78, A_t/S/A′) vs Fig. E-9. Default `:surrogate` T2 path unchanged. First run not met; no parameter tuned.
Inputs: same e11 geometry/blocking as T2; `broadband_model=:eq19` via T2_EQ19 runner; targets CSV; L = 1.83 m.
Equations: Eqs. (19)–(23) in `hf_broadband.jl`; related Eq. (24)/(78) absorptions.
Outputs: SPL [dB] at 1.25/1.6/2 kHz; verdict ±3.5 dB; E-21/E-22 full-band counts reported only.

### Case: T2_EQ19_DECK
**Title:** T2 with Eqs. (19)–(23) on NASA's 300 modes vs Fig. E-9 (83c)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Free field → Bands and dB(A)
**Compared with:** measurement
**Source:** CR-3813 Fig. E-9, p. 132; NASA's MRP deck; CR-172428 Table 6; criterion fixed 2026-10-29 before the run (plan §8aa)
**What it tests:** T2_EQ19 with NASA's 300 deck modes in place of Table D-1's 32; everything else as T2_EQ19.
**Why it is here:** Same cause as E22_HF_DECK, on the measurement (Phase 83a).
**A pass means:** |got − Fig. E-9 mean| ≤ 3.5 dB at 1.25, 1.6, 2 kHz (T2_EQ19's criterion).
**Not covered:** The exterior blocked continuum stays V-ASSUMED, as in T2_EQ19.
**Recorded outcome:** **Diagnostic since Phase 86 (2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It re-runs another case with one program form or input set changed to test a documented cause of that case's miss; the case it re-runs carries the verdict. The run and its table are unchanged; the outcome before, kept as a record and not a pass: **not_met**, 0/3 (2026-10-29, first run): 54.89, 54.18, 48.96 dB against 51.0, 46.0, 41.5 (Table D-1: 38.85, 35.94, 34.90). With the modes the prediction is 4–8 dB over the measurement instead of 6–12 dB under it; not met, and not adopted (the outcome rule of §8aa ties adoption to E22_HF_DECK).
**Explanation:** Experiment comparison; `interior_spl(...; broadband_model=:eq19)` on the T2_EQ19 inputs with `nasa_deck_modes()`.
Inputs: as T2_EQ19; `nasa_deck_modes()`.
Equations: Eqs. (19)–(23).
Outputs: SPL [dB] at 1.25/1.6/2 kHz, with the Table D-1 run beside it.

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

### Case: T1_FROM_E12
**Title:** T1 from measured E-12 blocked pressures (41a)
**Map / block:** total / P_MEAS
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** measurement
**Source:** CR-3813 Fig. E-12 measured blocked SPL; T1 gate; phase 41a criterion 2026-10-23
**What it tests:** Cabin tonal H1–H3 when ℓ = 1 uses measured E-12 blocked levels (phases from ANOPP Table 8; off-line GEXT as T1; blocking off) against the unchanged T1 gate.
**Why it is here:** Isolates the cabin chain from predicted free field + blocking for the failing T1 / REPRO_18b cases.
**A pass means:** Same T1 gate (±4 dB of measured E-16 mean, or gate B); a pass with T1 failing would attribute T1 to source/blocking.
**Not covered:** E-12 does not cover all ℓ = 1 stations/harmonics (H3 span ≈ [−0.21, 0.22] X3/D); uncovered ℓ = 1 stations keep T1-blocked amplitudes (stated).
**Recorded outcome:** **not_met**, 2/3 (H1–H3 = 81.66, 75.29, 77.89 dB; T1 = 84.21, 77.66, 78.06); H3 fails — cabin chain implicated (first run 2026-10-23) **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 81.70, 75.26, 77.64 dB (T1 84.24, 77.63, 77.80); 2/3 unchanged. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 1/3 (84.99, 79.27, 74.93 dB). **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 1/3 unchanged (84.29, 78.56, 76.39 dB; was 84.99, 79.27, 74.93). **Map chip 2026-10-28 (Phase 79a, display only):** the three "T1 recorded path" rows and the three E-12 coverage notes are information rows ("(info)") and leave the chip count, which now reads 1/3 like the verdict (it read 7/9). Phase 93 default form (2026-10-29): not met, 1/3.
**Explanation:** Isolation: replace predicted free field + blocking on ℓ = 1 with Fig. E-12 measured blocked SPL (digitization A) where covered; phases = ANOPP Table 8; GEXT off-line as T1; Phase III η_T = 0.5. Criterion unchanged from T1.
Inputs: `e12_measured_A.csv`; Table-8 phases; T1 geometry/trim; `t1_interior_targets.csv`.
Equations: Eq. (8) cabin chain; GEXT; no Eq. (43) on the E-12-covered line.
Outputs: H1–H3 [dB]; verdict on T1 gate.

### Case: T1_MEAS_DAMPING
**Title:** T1 with measured η_n / η_r′ (43b)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** measurement
**Source:** CR-3813 Figs. E-13 / E-15 / E-16; η_n = c₀ S α/(4 ω V) p. E-21; criterion = T1 gate, dated 2026-10-23
**What it tests:** T1 cabin tones with measured acoustic absorption (E-13 → η_n) and measured structural decay (E-15 all points → η_r′), everything else as T1.
**Why it is here:** Separates the App. A / §3.8 damping model from the rest of the T1 miss.
**A pass means:** Same T1 gate (±4 dB of measured E-16 mean at each of H1–H3).
**Not covered:** Damping model itself (replaced by measured); GEXT and source path unchanged from T1.
**Recorded outcome:** **not_met**, 2/3 (H1–H3 = 93.78, 80.06, 79.41 dB); η_n(200/400/600) = 0.0399, 0.0100, 0.0138; η_r′ = 0.0711, 0.0974, 0.0842; S = 5.353 m² (S_side + 2 S_e, Eq. 24 / hf_absorbing_areas); first run 2026-10-23 **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 93.75, 80.05, 79.16 dB; 2/3 unchanged. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 1/3 (98.57, 83.60, 76.20 dB). **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 1/3 unchanged (97.79, 82.46, 77.88 dB; was 98.57, 83.60, 76.20). Phase 93 default form (2026-10-29): not met, 2/6.
**Explanation:** T1 exactly except per-band η_n from Fig. E-13 α via η_n = c₀ S α/(4 ω V) and η_r′ from e15_structural_loss_measured_all.csv (log-log in f, ends held) through η_n_band / η_r_band with η_r_band_is_prime. S = sidewall + 2 end absorbing areas (same as hf_absorbing_areas; report near Eq. 24/78).
Inputs: `e13_absorption_targets.csv`; `e15_structural_loss_measured_all.csv`; T1 geometry/trim/GEXT/R2; `t1_interior_targets.csv`.
Equations: Eq. (8); η_n from p. E-21; measured η_r′ override.
Outputs: H1–H3 [dB]; η at 200/400/600 Hz; verdict on T1 gate.

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

### Case: H3_ATTRIB
**Title:** H3 attribution on REPRO_18b (43c diagnostic)
**Map / block:** total / P_MEAS
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** verification
**Source:** CR-3813 Figs. E-14 / E-15 / E-12; REPRO_18b conditions; no criterion (diagnostic), 2026-10-23
**What it tests:** Shift of H1–H3 when one REPRO_18b block at a time is replaced by NASA's printed intermediate value (η_n E-14 calc, η_r′ E-15 calc, both, or ℓ=1 from measured E-12).
**Why it is here:** Attributes the REPRO_18b / T1 H3 miss without tuning.
**A pass means:** No criterion (always `:no_verdict`); table of shifts recorded.
**Not covered:** Not a validation of any single block; swaps use NASA's printed curves only.
**Recorded outcome:** diagnostic; baseline 85.90, 78.35, 79.82; ΔH3: η_n +0.45, η_r′ −1.70, both −1.24, E-12 −1.39 (`h3_attribution.md`); first run 2026-10-23 **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** baseline 85.93, 78.32, 79.57 dB; ΔH3: η_n +0.45, η_r′ −1.67, both −1.19, E-12 −1.41 dB. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** baseline 89.03, 81.24, 77.06 dB; ΔH3: η_n +0.06, η_r′ −1.76, both −1.70, E-12 −1.65 dB. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** baseline 88.20, 80.43, 78.21 dB; ΔH3: η_n +0.38, η_r′ −1.87, both −1.47, E-12 −1.37 dB.
**Explanation:** REPRO_18b (η_T = 0.5, no η_r′ cap, R1, ANOPP Table 8 + GEXT); four swaps with NASA E-14/E-15 calculated (η_T=0.5) and measured E-12 on ℓ=1.
Inputs: `e14_acoustic_loss_calculated.csv`; `e15_structural_loss_calculated.csv`; E-12 measured curve; REPRO pipeline.
Equations: Eq. (8) with per-band loss overrides or E-12 line replacement.
Outputs: H1–H3 and Δ per swap; report `h3_attribution.md`; verdict `:no_verdict`.

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

### Case: T1_F1A_FILL
**Title:** T1 with F1A-relative off-line free field (43f)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** measurement
**Source:** CR-3813 Fig. E-16; F1A relative pattern as `compare_gext_vs_f1a_grid.jl`; T1 gate unchanged, dated 2026-10-23
**What it tests:** T1 with ℓ = 1 kept as ANOPP Table-8/e11 line and off-line points filled by the relative F1A pattern of the same propeller (not GEXT).
**Why it is here:** Replaces the V-ASSUMED GEXT falloff with a physics-based off-line field independent of E-16.
**A pass means:** Same T1 gate (±4 dB of measured mean, H1–H3).
**Not covered:** F1A absolute levels (only relative pattern); measured off-line free field.
**Recorded outcome:** **not_met**, 2/3 (H1–H3 = 79.61, 71.19, 71.30 dB; T1 GEXT = 84.21, 77.66, 78.06); first run 2026-10-23 **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 79.65, 71.17, 71.06 dB (T1 84.24, 77.63, 77.80); 2/3 unchanged. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** **met** 3/3 (82.12, 74.59, 66.95 dB), **post-hoc**: the sign was fixed after T1-family results had been seen, so this is not a pre-registered pass. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** met 3/3 unchanged (81.13, 73.98, 67.32 dB; was 82.12, 74.59, 66.95); still post-hoc. Phase 93 default form (2026-10-29): not met, 3/6.
**Explanation:** `grid_fill=:f1a_relative` on the e11 path (default remains `:gext`): A(k,ℓ)=A(k,1)·A_F1A(k,ℓ)/A_F1A(k,1), φ += Δφ_F1A; F1A from `aircraft_scale_hartzell.json` / `propeller_freefield_grid`.
Inputs: e11/Table-8 line; F1A full grid; `t1_interior_targets.csv`.
Equations: Eq. (8); F1A-relative fill in `freefield_digitized.jl`.
Outputs: H1–H3 [dB] next to T1; verdict on T1 gate.

### Case: T1_F1A_MEAS_DAMP
**Title:** T1 F1A fill + measured damping (43b+43f diagnostic)
**Map / block:** total / P_MEAS
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** measurement
**Source:** combination of 43b and 43f; no criterion (diagnostic), 2026-10-23
**What it tests:** Diagnostic only: T1 with both measured η_n/η_r′ and F1A-relative off-line fill.
**Why it is here:** Joint effect of the two T1 root-cause swaps; not a gated claim.
**A pass means:** No criterion (always `:no_verdict`).
**Not covered:** Same as 43b and 43f separately.
**Recorded outcome:** diagnostic H1–H3 = 90.00, 73.46, 72.60 dB (first run 2026-10-23) **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 89.95, 73.45, 72.41 dB. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 94.08, 77.29, 67.78 dB.
**Explanation:** Measured damping overrides of T1_MEAS_DAMPING plus `grid_fill=:f1a_relative` of T1_F1A_FILL.
Inputs: E-13 / E-15 measured; F1A pattern; T1 geometry.
Equations: Eq. (8); measured η; F1A-relative fill.
Outputs: H1–H3 [dB]; verdict `:no_verdict`.

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

### Case: T2_MEAS_EXT
**Title:** T2 with the measured TP-2444 exterior spectrum (47d)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** measurement
**Source:** NASA TP-2444 Fig. 17 (exterior, 4000 rpm), CR-172428 Fig. 14 (slope to 2 kHz), CR-3813 Fig. E-9; criterion fixed 2026-10-23 before any run (plan Phase 47)
**What it tests:** T2's cabin path, Eqs. (19)–(23) with the T2 inputs, fed with the measured exterior band level instead of the modelled one.
**Why it is here:** T2 could not be checked end to end until a measured exterior of the article was found.
**A pass means:** The 1250 Hz interior within ±3.5 dB of Fig. E-9 (51.0 dB). 1600 and 2000 Hz use the same gate, labelled extrapolated exterior.
**Not covered:** The microphone is taken as the blocked surface pressure (position not stated); B = 5 Hz is assumed; the 1600/2000 Hz exterior is extrapolated.
**Recorded outcome:** **not_met** (2026-10-23). Phase 93 default form (2026-10-29): not met, 0/4.
- The measured exterior is 85.4 dB at 1250 Hz. It gives an interior of 21.3 dB against 51.0 dB.
- 1600 and 2000 Hz give 19.7 and 19.9 dB against 46.0 and 41.5 dB.
- The secondary comparison, against the Fig. 17 interior (51.5 dB), is not met.
- The measured data agree with each other: 85.4 − 33.9 = 51.5 dB.
- PAIN's high-frequency noise reduction is too high, and NASA's E-21/E-22 predictions show the same.
- Post-hoc information: the production surrogate gives 38.6 dB, and T2's modelled exterior is 102.7 dB.
**Explanation:** Experiment comparison. p_bl² from the measured band level goes into `hf_broadband_band_p2` with the T2 pipeline inputs.
Inputs: `data/tp2444/tp2444_fig17_exterior_passA.csv`; `data/cr172428/cr172428_fig14_mic1_5000rpm_passA.csv`; E-9 targets.
Equations: Eqs. (19)–(23); 1/3-octave energy sum.
Outputs: interior SPL at 1250/1600/2000 Hz [dB].

### Case: T2_PRED_BB
**Title:** T2 fully predictive: BPM exterior → T2 cabin path → E-9 (48d)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Blade and polars → Bands and dB(A)
**Compared with:** measurement
**Source:** CR-3813 Fig. E-9; criterion fixed 2026-10-23
**What it tests:** T2 with no measured input: the BPM exterior at the Fig. 17 point through T2's Eqs. (19)–(23).
**Why it is here:** It is the end-to-end predictive form of T2.
**A pass means:** ±3.5 dB of E-9 at 1250, 1600 and 2000 Hz.
**Not covered:** As PROP_BB_FIG17.
**Recorded outcome:** **not_met**, 0/3 (2026-10-23): 18.4, 17.4 and 17.9 dB against 51.0, 46.0 and 41.5 dB. The cabin path's noise reduction is the cause. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** 0/3, interior 19.5, 18.9, 19.8 dB vs 51.0, 46.0, 41.5 dB; not met. The cabin path's noise reduction is still the cause. Phase 93 default form (2026-10-29): not met, 0/3.
**Explanation:** Experiment comparison. `hf_broadband_band_p2` with the T2 pipeline inputs.
Inputs: The 48b exterior; T2 inputs.
Equations: Eqs. (19)–(23).
Outputs: interior SPL [dB].

### Case: T2_MEAS_EXT_BR
**Title:** T2 with the measured exterior and Sharp sound bridges (59e)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** measurement
**Source:** CR-3813 Fig. E-9; TP-2444 Fig. 17; NASA CR-172490; criterion fixed 2026-10-23
**What it tests:** 47d with the bridge option.
**Why it is here:** It is T2 with the one documented extension that adds a path around the trim.
**A pass means:** 1250 Hz interior within ±3.5 dB of E-9 (51.0 dB).
**Not covered:** As T2_MEAS_EXT; the connections are V-ASSUMED.
**Recorded outcome:** **not_met** (2026-10-23): 28.4, 27.6 and 28.4 dB against 51.0, 46.0 and 41.5 dB (21.6 dB without bridges). Phase 93 default form (2026-10-29): not met, 0/3.
**Explanation:** Experiment comparison. `hf_broadband_band_p2(...; bridges=true)`.
Inputs: As T2_MEAS_EXT.
Equations: Eqs. (19)–(23) + τ_B.
Outputs: interior SPL [dB].

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

### Case: R172428_EXP_DECK
**Title:** CR-172428 reproduction on NASA's 300 modes vs measured space averages (84b)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** measurement
**Source:** NASA CR-172428 Table 5 (measured space averages), Table 6 (300 structural modes); NASA's MRP deck; criterion fixed 2026-10-29 before the run (plan §8ab)
**What it tests:** R172428_EXP with NASA's 300 structural modes in place of 32; everything else as R172428_EXP.
**Why it is here:** As R172428_CODE_DECK, against the measurement.
**A pass means:** ±4 dB of the measured space average at each of the 9 points (R172428_EXP's criterion).
**Not covered:** As R172428_CODE_DECK.
**Recorded outcome:** **Diagnostic since Phase 86 (2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It re-runs another case with one program form or input set changed to test a documented cause of that case's miss; the case it re-runs carries the verdict. The run and its table are unchanged; the outcome before, kept as a record and not a pass: **not_met**, 3/9 (2026-10-29, first run), the same count as R172428_EXP: 3000 rpm 70.84, 68.60, 61.66; 4000 rpm 102.41, 79.91, 71.94; 5000 rpm 90.15, 94.49, 80.58 dB (Table D-1: 71.07, 69.02, 62.66; 102.45, 80.05, 71.69; 90.35, 94.40, 78.40). **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** 5/9.
**Explanation:** Experiment comparison; `r172428_inputs(rpm; structural=:nasa300)`.
Inputs: as R172428_EXP; `nasa_deck_modes()`.
Equations: full cabin chain, Eq. (8).
Outputs: SPL H1–H3 at 3000/4000/5000 rpm [dB].

### Case: AC_CABIN_DEMO
**Title:** Aircraft cabin example: overall dB(A) (62)
**Map / block:** total / A_CABIN
**Category:** display
**Kind:** runnable
**Chain span:** Blade and polars → Bands and dB(A)
**Compared with:** verification
**Source:** PAIN.jl examples/aircraft_scale_hartzell_cabin_full.json; IEC 61672 A-weighting; phase 62 criterion 2026-10-23
**What it tests:** The aircraft example's interior band spectrum, its A-weighted version and the overall dB(A) the program reports.
**Why it is here:** Gives the aircraft cabin hand-off block a case with its own figure. The number is X-EXTRAP: there is no aircraft interior measurement.
**A pass means:** Overall dB(A) equals the energy sum of the A-weighted bands within 1e-9 dB (arithmetic only).
**Not covered:** Any claim about the aircraft level (no measurement; the uncertainty band of phase 31 is not a validation).
**Recorded outcome:** **Information since Phase 85 (2026-10-29): no verdict.** Verification, not a validation case under the meaningfulness rule (the dB(A) sum against its own bands: arithmetic). The run and its table are unchanged; the outcome before the rule, kept as a record and not a pass: **met**, 1/1 (2026-10-24; `phase62_65_map_blocks_grid.md`): 91.6 dB(A) (X-EXTRAP, not validated). The first run listed eight IEC A-weight rows as passing table rows (9/9); they carry no criterion and moved to the inputs echo on 2026-10-24 (code review). The example's grid has 80 of 160 points off its assumed 1.83 m cabin (a = 1.32 m): Q45, closed (demonstration only) **Phase 78d-4 knock-on (2026-10-28):** the App. D modes of the parametric cabin changed (J1–J6); the energy-sum check is unchanged (met, 1/1) and the figure was regenerated.
**Explanation:** Display of the aircraft result with an arithmetic check of the overall level; the A-weights are printed against the IEC table as information.
Inputs: aircraft_scale_hartzell_cabin_full.json (cabin and trim from the JSON), H = 1–3.
Equations: overall_dBA, a_weight_dB
Outputs: band SPL, A-weighted SPL, overall dB(A).

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

### Case: Q0_REPRO_18b
**Title:** q = 0 uncoupled, pre-correction form, vs E-16's NASA prediction (88a)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-16 NASA prediction; hypothesis and criterion fixed 2026-10-29 before the run (plan §8ae)
**What it tests:** REPRO_18b_PRE (all three CR-172428 App. A changes reverted) with `q0_coupled = false`: the q = 0 cabin modes get no structural coupling.
**Why it is here:** Held-out test of the q = 0 hypothesis: CR-3813's runs played no part in forming it, and none of the App. A changes concerns q = 0.
**A pass means:** |Δ| ≤ 4 dB at H1–H3 (REPRO_18b's).
**Not covered:** Other undocumented differences in NASA's 1983 runs.
**Recorded outcome:** **Diagnostic (Phase 88, 2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It tests the q = 0 hypothesis on a CR-3813 run that played no part in forming it; the case it re-runs carries the verdict. The outcome, a record and not a pass: not met, 2/3 (2026-10-29): 75.86, 75.99, 80.93 dB against NASA 79.0, 75.5, 68.0 (q = 0 coupled: 85.11, 77.61, 81.85). H3 stays 13 dB high.
**Explanation:** Diagnostic. `_with_fields(inputs; floor_sign=-1.0, q0_coupled=false)`.
Inputs: As REPRO_18b.
Equations: Eq. (8) with f₀M = 0.
Outputs: SPL H1–H3 [dB].

### Case: Q0_E18
**Title:** q = 0 uncoupled, pre-correction form, vs E-18's NASA prediction (88b)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-18 NASA prediction; hypothesis and criterion fixed 2026-10-29 before the run (plan §8ae)
**What it tests:** E18_TONES's run (η_T = 1.0, η_r′ ≤ 0.15) in the pre-correction form with the q = 0 cabin modes uncoupled.
**Why it is here:** Second held-out run for the q = 0 hypothesis.
**A pass means:** |Δ| ≤ 4 dB per harmonic (E18_TONES's).
**Not covered:** As Q0_REPRO_18b.
**Recorded outcome:** **Diagnostic (Phase 88, 2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It tests the q = 0 hypothesis on a CR-3813 run that played no part in forming it; the case it re-runs carries the verdict. The outcome, a record and not a pass: not met, 1/3 (2026-10-29): 83.70, 75.44, 78.23 dB against NASA 88.0, 75.0, 67.0 (q = 0 coupled: 87.88, 77.06, 79.31). H1 moves away from NASA.
**Explanation:** Diagnostic. As E18_TONES with `floor_sign = −1`, `q0_coupled = false`.
Inputs: As E18_TONES.
Equations: Eq. (8) with f₀M = 0.
Outputs: SPL H1–H3 [dB].

### Case: Q0_E21
**Title:** q = 0 uncoupled, pre-correction form, vs E-21's NASA prediction (88c)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Bands and dB(A)
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-21 NASA prediction; hypothesis and criterion fixed 2026-10-29 before the run (plan §8ae)
**What it tests:** E21_PRE with the q = 0 cabin modes uncoupled.
**Why it is here:** Third held-out run for the q = 0 hypothesis.
**A pass means:** |Δ| ≤ 3 dB in ≥ 75 % of the counted bands (E21_PRE's).
**Not covered:** As Q0_REPRO_18b.
**Recorded outcome:** **Diagnostic (Phase 88, 2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). It tests the q = 0 hypothesis on a CR-3813 run that played no part in forming it; the case it re-runs carries the verdict. The outcome, a record and not a pass: not met, 1/4 counted bands (2026-10-29), as E21_PRE.
**Explanation:** Diagnostic. `noise_reduction_spectrum` with `floor_sign = −1`, `q0_coupled = false`.
Inputs: As E21_PRE.
Equations: Eqs. (17)–(18) with f₀M = 0.
Outputs: NR [dB] per band.

### Case: R172428_CODE_ETAN
**Title:** CR-172428 reproduction with η_n per cabin mode vs NASA's printed predictions (89b)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** NASA CR-172428 App. B and Table 10; reading H1 from App. B pp. 195, 197, 202; decision fixed 2026-10-29 before the run (plan §8af)
**What it tests:** R172428_CODE with `η_n_per_mode = true`: each cabin mode's N is Eq. (77) at its own frequency with the trim conductance at the centre of its 1/3-octave band, the same at every tone.
**Why it is here:** Tests whether the per-mode loss factor App. B shows (87b, 87c) explains the reproduction's misses; the reading was formed from the per-mode tables, not from these levels.
**A pass means:** ±3 dB of NASA's printed prediction at ≥ 7 of 9 points (R172428_CODE's).
**Not covered:** H1 reproduces NASA's η_n only to 0.86–1.39 (post-hoc), so it is at most part of NASA's form.
**Recorded outcome:** **Diagnostic (Phase 89, 2026-10-29): no verdict, off the map** (`DIAGNOSTIC_CASES`). The outcome, a record and not a pass: not met, 5/9 (R172428_CODE: 4/9). Levels move ≤ 3.9 dB (5000 rpm H1 90.35 → 94.29 dB). Per the decision fixed before the run, H1 is not adopted and stays an option. First run used a 1 Hz floor for the rigid mode's frequency (N ≠ 0, contrary to Eq. (77) at ω = ω_n); fixed to N = 0 and rerun: same 5/9, levels unchanged to 0.01 dB.
**Explanation:** Diagnostic. `_run_r172428_vs(:code; η_n_per_mode=true)`; `acoustic_N_per_mode` in `pain_core.jl`.
Inputs: As R172428_CODE.
Equations: Eq. (8) and Eq. (83) with N from Eq. (77) per mode.
Outputs: 9 interior tone levels [dB].

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

### Case: APPB_PAIRS
**Title:** This code's Eq. (8) pair terms vs NASA's printed largest contributors (92a)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-172428 App. B pp. 207, 212 (`appB_contributors_4000rpm.csv`, `appB_contributors_5000rpm.csv`); plan §8ai, 2026-10-29
**What it tests:** The 25 acoustic × structural pair terms NASA prints (five largest at 4000 rpm H1–H3, 5000 rpm H1–H2) against this code's same pairs, in dB re 20 μPa; the share of this code's tone total from q = 0 cabin modes.
**Why it is here:** Locates which pairs of Eq. (8) differ from NASA's run.
**A pass means:** No criterion (diagnostic); ±2 dB is a reading band.
**Not covered:** Only NASA's five largest pairs per tone are printed.
**Recorded outcome:** no verdict (2026-10-29): 15/25 within ±2 dB; q = 0 share 92.4 % (4000 H1), 75.9 % (5000 H1), 69.4 % (5000 H2); NASA prints no q = 0 pair. With the deck table (Phase 100): 15/25; q = 0 share 95.4 %, 75.7 %, 69.9 %. **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** 21/25 within ±2 dB (was 15/25).
**Explanation:** `_run_appb_pairs` in `validation_case_iso92.jl`; `tone_mean_square_pressure(...; terms)`.
Inputs: `r172428_inputs(rpm)`.
Equations: Eq. (8) per pair.
Outputs: pair term [dB re 20 μPa].

### Case: APPB_PAIRS_Q0_ETAN
**Title:** Pair terms with q = 0 off and η_n per mode vs NASA's printed contributors (92c, post-hoc)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** as APPB_PAIRS; options chosen after APPB_PAIRS was seen (post-hoc)
**What it tests:** APPB_PAIRS with `q0_coupled = false` and `η_n_per_mode = true`.
**Why it is here:** Shows which pairs remain off once both inferred differences are applied.
**A pass means:** No criterion (diagnostic, post-hoc).
**Not covered:** As APPB_PAIRS.
**Recorded outcome:** no verdict (2026-10-29): 16/25 within ±2 dB; the remaining large ones follow cabin-mode frequencies 0.5 % from NASA's near the tone (report). **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** 22/25 (was 16/25).
**Explanation:** `_run_appb_pairs(; q0_coupled=false, η_n_per_mode=true)`.
Inputs: as APPB_PAIRS.
Equations: Eq. (8) per pair.
Outputs: pair term [dB re 20 μPa].

### Case: R172428_CODE_Q0
**Title:** CR-172428 reproduction with q = 0 off; 3000 rpm held out (92b)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-172428 Table 10 / App. B p. 206; criterion fixed 2026-10-29 before the run (plan §8ai, commit fa7cfbe)
**What it tests:** R172428_CODE's nine points with the q = 0 cabin modes uncoupled; the criterion counts the 3000 rpm points only, which were not run with q = 0 off before the criterion was fixed.
**Why it is here:** Tests the q = 0 reading of APPB_PAIRS on points that did not form it.
**A pass means:** ±3 dB of NASA's printed prediction at each of 3000 rpm H1–H3 (the outcome is recorded; the case carries no verdict).
**Not covered:** The 4000/5000 rpm points are post-hoc.
**Recorded outcome:** not met, 2/3 (2026-10-29): 63.40, 66.89, 62.59 dB against 63.3, 66.2, 59.5 (H3 +3.09 dB); all nine 8/9 within ±3 dB. **After Phase 106 (2026-10-30, post-hoc; 2-D cabin-mode part at 341 m/s):** held-out 3/3 (3000 rpm H3 +1.79 dB; was 2/3, +3.09).
**Explanation:** `_run_r172428_code_q0()`.
Inputs: `r172428_inputs(rpm)`, `q0_coupled = false`.
Equations: Eq. (8).
Outputs: SPL [dB].

### Case: R172428_CODE_Q0_ETAN
**Title:** CR-172428 reproduction with q = 0 off and η_n per mode (92c, post-hoc)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** as R172428_CODE_Q0; combination formed after APPB_PAIRS (post-hoc)
**What it tests:** R172428_CODE with both inferred differences.
**Why it is here:** How close this code comes to NASA's printed levels once the two differences found in NASA's output are applied.
**A pass means:** No criterion (diagnostic, post-hoc).
**Not covered:** Neither difference is documented by NASA.
**Recorded outcome:** no verdict (2026-10-29): all nine within ±2.4 dB (largest +2.34 dB, 5000 rpm H3).
**Explanation:** `_run_r172428_code_q0(; η_n_per_mode=true)`.
Inputs: `r172428_inputs(rpm)`, `q0_coupled = false`, `η_n_per_mode = true`.
Equations: Eq. (8).
Outputs: SPL [dB].

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

### Case: BAND_REPRO_18b
**Title:** Band-centre η_n, pre-correction form, vs E-16's NASA prediction (99a)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-16 NASA prediction; criterion and decision fixed 2026-10-30 before the run (plan §8ao, commit 8f02a4a)
**What it tests:** Whether the program behind CR-3813's printed runs already evaluated η_n at the nominal band centre (Phase 95), in the pre-correction form with q = 0 coupled.
**Why it is here:** Held-out test of the Phase 95 rule on the earlier program (diagnostic).
**A pass means:** ±4 dB per harmonic against E-16's NASA prediction (outcome recorded; the case carries no verdict).
**Not covered:** The exterior field is the digitized E-11 data with the assumed grid extension.
**Recorded outcome:** not met, 1/3 (2026-10-30): 84.56, 77.60, 81.58 dB against 79.0, 75.5, 68.0 (η_n at the tone: 85.11, 77.61, 81.85).
**Explanation:** `_run_band_cr3813` in `validation_case_iso99.jl`.
Inputs: Phase III trim, E-11 field, R1 blocking.
Equations: Eq. (8).
Outputs: SPL [dB].

### Case: BAND_E18
**Title:** Band-centre η_n, pre-correction form, vs E-18's NASA prediction (99b)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Free field → Interior tones
**Compared with:** NASA's printed prediction
**Source:** CR-3813 Fig. E-18 NASA prediction; criterion and decision fixed 2026-10-30 before the run (plan §8ao, commit 8f02a4a)
**What it tests:** Whether the program behind CR-3813's printed runs already evaluated η_n at the nominal band centre (Phase 95), in the pre-correction form with q = 0 coupled.
**Why it is here:** Held-out test of the Phase 95 rule on the earlier program (diagnostic).
**A pass means:** ±4 dB per harmonic against E-18's NASA prediction (outcome recorded; the case carries no verdict).
**Not covered:** The exterior field is the digitized E-11 data with the assumed grid extension.
**Recorded outcome:** not met, 2/3 (2026-10-30): 87.63, 77.05, 78.96 dB against 88.0, 75.0, 67.0 (η_n at the tone: 87.88, 77.06, 79.31).
**Explanation:** `_run_band_cr3813` in `validation_case_iso99.jl`.
Inputs: Phase III trim, E-11 field, R1 blocking.
Equations: Eq. (8).
Outputs: SPL [dB].

### Case: R172428_TRIM_DECK
**Title:** NASA's per-band PF-105 table (App. D deck) vs App. B trim admittances (100a)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Chain span:** Damping and trim → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** CR-172428 App. D p. 229 (input deck, cards 22–33) and App. B p. 197; predictions fixed 2026-10-30 before the run (plan §8ap, commit 1ddabd9)
**What it tests:** Whether NASA's App. B runs used the per-band PF-105 table printed in the App. D input deck, as printed (λ = 0.01 m at 1600 Hz included).
**Why it is here:** It selects the insulation input of the CR-172428 reproductions (diagnostic; the held-out verdicts are R172428_ETAT2 and APPB_ETA_N_T2_BAND).
**A pass means:** Predictions: sidewall Re β at 200 Hz within 10 % and end-cap Im β at 1600 Hz within 15 % of App. B (outcome recorded; the case carries no verdict).
**Not covered:** Whether NASA used the same table in CR-3813's runs (that deck is not printed).
**Recorded outcome:** no verdict, both predictions hold (2026-10-30): +2.7 % and +1.7 %; 84/84 admittance values within ±10 % at 50–5000 Hz (Fig. A-2 markers: 49/72).
**Explanation:** `_run_r172428_trim_deck` in `validation_case_iso100.jl`.
Inputs: App. D deck table, App. B trim (Table 6).
Equations: App. A Eqs. (A.10)–(A.22).
Outputs: trim admittance β [-].

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
**Recorded outcome:** **not met** (first run 2026-10-30): the rule gives NY = 12 at both angles; 2-D frequencies 0/53 and 5/61 within 0.1 %; Merlin (seen) 51/51. Diagnostic: NASA's narrow-body grid is NY = 8; no grid fits the small-diameter list (best 2 %).
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

### Case: FLIGHT10_FLOOR_SIGN
**Title:** Run 10's floor-term sign on the printed H1/H5 pairs (108)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Chain span:** Wall modes → Damping and trim
**Compared with:** NASA's printed prediction
**Source:** CR-172428 App. D pp. 235–236 (printed pairs); test fixed 2026-10-30 before any H1/H5 pair was computed (plan §8ax, commit 25f7acb)
**What it tests:** Whether NASA's run 10 used the pre-correction Eq. (52) floor sign (H_pre), on the 10 printed H1/H5 pairs, whose η_r″ do not depend on the field.
**Why it is here:** Phase 103 found run 10's H2–H4 η_r″ follow the floor term subtracted while App. B's follow it added (diagnostic).
**A pass means:** No verdict; H_pre supported if ≥ 7/10 within [0.4, 2.5]× NASA's with the floor term subtracted and more than with it added, refuted in the mirror case.
**Not covered:** H2–H4 pairs (seen in Phase 103).
**Recorded outcome:** no verdict (2026-10-30): 8/10 subtracted, 5/10 added; H_pre supported.
**Explanation:** `_run_flight10_floor_sign` in `validation_case_iso108.jl`.
Inputs: `data/cr172428/appD_run10_pairs.csv`, `r172428_flight10_inputs()`.
Equations: Eqs. (52), (83).
Outputs: η_r″ ratio [-].

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

