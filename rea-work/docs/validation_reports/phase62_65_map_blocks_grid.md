# Phases 62–65: map-block cases, the structural animation, unit tests for every function, and the grid axial direction

Criteria fixed 2026-10-23 in `IMPLEMENTATION_PLAN.md` §8i, before any run. First runs 2026-10-23; re-runs and the code
review 2026-10-24. Nothing in this report was fitted to a comparison: every change is a correction of the code or of an
input against the documents (User Manual, CR-3813, the textbook Gutin form), and every result seen before a change is
labelled as such.

## Phase 65 — grid axial direction and z_p

**Finding (Phase 62 input QA, 2026-10-23).** The code built the 160-point grid with z_k = z_p + x₃ and z_p = 0.90 m. The
documents give z_k = z_p − x₃ with x₃ = (πa/18)(k_p − k):

- User Manual pp. 8–9: "(πa/18)·[k_p − 1] cannot exceed z_p", i.e. z₁ = z_p − x₃ ≥ 0.
- CR-3813 App. E p. E-8: z_k = z_p − x₃ᵏ and z_p = 0.662 m; CR-172428 Table 6: z_p = 0.662 m.

The old grid was mirrored about the propeller plane; 0.90 m had no source (initial commit). **Fix:** `grid_points` uses
z = z_p − x₃; the test-article z_p is 0.662 m in `run_pain_pipeline`, the GUI default, the NASA-default table and every
test-article case. z is the cabin axis, the fuselage station (aircraft body x) from the forward end of the cylinder.
`UT_GRID` now checks z of every point by hand (35/35).

**Every recorded number that changed (65b; full snapshot regenerated 2026-10-24 and diffed; no verdict changed):**

| Case | Before (after 44f) | After Phase 65 |
|------|-------------------|----------------|
| T1 H1–H3 | 87.36, 81.02, 75.23 dB | 86.59, 80.02, 76.39 dB (not met; H3 +11.4 dB) |
| REPRO_18b | 89.03, 81.24, 77.06 dB (0/3) | 88.20, 80.43, 78.21 dB (0/3) |
| REPRO_18b_PRE | 85.93, 78.32, 79.57 dB (1/3) | 85.11, 77.61, 81.85 dB (1/3) |
| E18_TONES `:auto` | 91.17, 80.44, 75.24 dB (1/3) | 90.35, 79.63, 76.56 dB (1/3) |
| T2_EQ19 | 0/3; V-CODE 0/13, V-EXP 1/15 | 38.85, 35.94, 34.90 dB; 0/3; 0/13, 1/15 |
| T1_FROM_E12 | 84.99, 79.27, 74.93 dB (1/3) | 84.29, 78.56, 76.39 dB (1/3) |
| T1_MEAS_DAMPING | 98.57, 83.60, 76.20 dB (1/3) | 97.79, 82.46, 77.88 dB (1/3) |
| T1_F1A_FILL | 82.12, 74.59, 66.95 dB (met 3/3, post-hoc) | 81.13, 73.98, 67.32 dB (met 3/3, post-hoc) |
| H3_ATTRIB baseline | 89.03, 81.24, 77.06 dB | 88.20, 80.43, 78.21 dB (ΔH3: η_n +0.38, η_r′ −1.87, both −1.47, E-12 −1.37) |
| LOUDEST_PT test article | 80.4 / 85.5 dB(A) | 80.0 / 84.3 dB(A) |
| GEXT_BOUND | 5/9 | 5/9 (nominal residuals −3.41, +0.02, +11.40 dB) |
| `data/baselines/phase17_baselines.csv` | — | 102 values re-recorded (file header dated) |

Label on each re-record: "grid axial correction 2026-10-23 (code vs User Manual p. 9 / App. E p. E-8; not a fit)".

**Open (Q45).** The aircraft working example `aircraft_scale_hartzell_cabin_full.json` (a = 1.32 m, assumed L = 1.83 m,
z_p = 0.90 m) cannot hold the Manual grid: 16 stations at πa/18 = 0.23 m span 3.45 m, so 80 of 160 points lie off the
cylinder (they did before the sign fix as well). `grid_points` now warns with the count. The cabin length and propeller
station are the aircraft's own inputs; they are not chosen here.

## Phase 62 — a proving case with its own figure on every map block

On 2026-10-23, 12 of the 30 blocks of the `total` map had no case. Each now has one (V-UNIT or input QA); a unit test
(`test/unit/test_validation_map.jl`) fails if any block lacks a runnable case with a figure.

| Block | Case | Result | Note |
|-------|------|--------|------|
| X_F1A | F1A_PLANE_PEAK | met 1/1 | H1 peak at (k = 8, ℓ = 1) |
| X_FF | FF_E11_MAP | met 48/48 | GEXT never exceeds the measured line |
| X_SRC | SRC_PASSTHROUGH | met 2/2 | bit-identical |
| X_BLK_OUT | BLK_GAIN_MAP | **not met** 1/2 | R2 within 0–6.02 dB; R1 (CR-172428 Eq. 43 as printed) reaches −49.3 dB at γ > 90°, which is why R2 is the default |
| X_MRP_IN | MRP_INPUT_QA | met 13/13 | after Phase 65 (z_p row failed before) |
| X_MRP_OUT | MRP_SHAPE_NORM | **not met** 19/32 | Table D-1 prints only the largest coefficients; 13 truncated shapes peak up to 1.245. No pair used exceeds \|f′\| ≤ 1 (checked on every call) |
| X_CYL_IN | CABIN_GEOM_HAND | met 4/4 | floor-width row fixed by the review (it compared an expression with itself) |
| X_CYL_OUT | CYL2D_WEYL | **not met** 0/5 | N/W = 1.71, 1.59, 1.49, 1.56, 1.87 |
| X_TRIM_IN | TRIM_INPUT_QA | met 7/7 | |
| X_TRIM_OUT | TRIM_PASSIVITY | met 17/17 | |
| X_PAIN_IN | PAIN_INPUT_ECHO | met 5/5 | m_wall now from the printed App. E dimensions (review) |
| A_CABIN | AC_CABIN_DEMO | met 1/1 | 91.6 dB(A), X-EXTRAP; IEC rows moved to the echo (review); see Q45 |

**CYL2D_WEYL diagnosis (post-hoc, 2026-10-24, after the result; criterion unchanged).** The App. C 5-point grid at NY = 10
has h = 0.2a. In the near-circle limit (θ₀ = 2°) the k-th CYL2D mode against the k-th exact J′ zero is 0.98 at kh = 0.4,
0.80 at kh = 2.4 and 0.73 at kh = 2.9; at NY = 20 mode 60 is 0.93 (kh = 1.5). Frequencies computed too low put extra modes
below each f, the overcount that grows with f. With the Neumann surface term the ratio is 0.99–1.51. A resolution limit
of App. C as printed (Fig. C-3 uses NY = 10), not a code defect.

## Phase 63 — the structural mode animates

`structural_mode_frames` deforms the cross-section at z = L/2 by ψ cos(2πk/n) (shell radially, floor vertically) and
scales the shell ψ field by the same cosine; the Cabin modes tab steps it with the acoustic frames (same count, same
timer). Unit tests: frames move, quarter period is the undeformed section, half period flips the field, the step wraps at
n and updates both images. `smoke_gui_model.jl` and `smoke_qml_load.jl` pass offscreen (2026-10-24).

## Phase 64 — a unit test for every function

`PAIN.jl/test/unit/`: 25 files, one per source module (helpers of the validation cases grouped), included by
`runtests.jl` as `Unit tests: <module>`; `test_zz_completeness.jl` lists every function in `src/` from the method table
and fails if one is not named in a unit test (`gui_main.jl` QML bindings exempt, covered by the smoke scripts). Tests use
hand values, published tables (A&S Si/Cin, Bessel, J′ zeros; RP-1218 D2/D3), exact limits (ring frequency, near-circle
cavity, static dipole, on-axis rotor) and independent routes (quadrature against closed forms, resultant identities).
All pass (2026-10-24).

**Defects the unit tests found and fixed** (code-on-code; none is a fit):

| Defect | Effect | Fix |
|--------|--------|-----|
| `f1a_gutin_h1_comparison` used (mBΩ/(2πc₀r))(Q/R_tip)J_mB(mB M_tip) | the F1A_GUTIN reference was low by √2·M; the old 0.31 dB agreement came from evaluating J_mB at the tip | Gutin's p_rms = (mBΩ/(2√2πc₀r))·Qc₀/(ΩR²)·J_mB(mBΩR/c₀) summed annulus by annulus (Σ dQ = Q). F1A_GUTIN re-run: Δ = 0.03 dB. Independent F1A of a single-radius source = Gutin within 0.03 % |
| `PropellerPlacement` default constructor | a rotation sense of 2 was accepted | inner constructor checks ±1 |
| `_η_key_hz` | string band keys of a JSON loss-factor card threw | `parse(Float64, …)` |
| `apply_aircraft_cabin_json` with a Dict cabin | symbol/bool fields (trim, structural_solver, allow_extrapolation, band cards) silently ignored | all reads through `_dict_get` |
| `tone_expected_value` empty band | returned fewer fields than the normal return | same fields |
| `noise_reduction_test_article_inputs` | dummy grid had axes swapped (unused by Eq. 18) | [k, ℓ, H] |
| `_iso_simpson` (independent quadrature) | `4f1` is the Float32 literal 40 (no caller) | `4 * f1` |
| Phase 62 reasons | failing cases read as passes | "criterion not met — …" prefix |

Also from this work: the GUI Run tab runs the aircraft pipeline only (E-11 and synthetic inputs verify PAIN and run as
Validation-tab cases); `run_validation_gui!` takes `figure_dir` so tests do not rewrite tracked figures.
