# PAIN recreation: methodology and claims

This document explains the pipeline stage by stage and states, at each stage, what the recreation claims and at what grade.
It replaces `CLAIMS.md`. The evidence and pass criteria are in [`VALIDATION_GUIDELINE.md`](VALIDATION_GUIDELINE.md), the build
order is in [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md), and the diagrams are in [`flowchart.md`](flowchart.md).

## Grades used for every claim

| Grade | Meaning | What it allows you to say |
|-------|---------|---------------------------|
| **V-EXP** | Compared with measurement the parameters were not fitted to | "Agrees with the measured data within the stated tolerance" |
| **calibrated (in-sample)** | Parameters were set against the same figures the result is compared to, and no held-out subset is documented | "Consistent with these figures." A goodness-of-fit, not a validation |
| **V-EXP, calibrated** | Inputs were scaled to measurement, but the compared quantity was held out (the Report 996 scaled-load runs) | "Agrees within X dB given the scaled inputs" |
| **V-CODE** | Reproduces a NASA code table (C-1, D-1) | "Matches the reference table." Not experimental proof |
| **V-UNIT** | Matches a written equation | "Implements the equation" |
| **V-ASSUMED** | Physics the papers do not fix | Must be labelled assumed; unit tests verify code, not physics |
| **X-EXTRAP** | The aircraft application, or CCBlade/F1A outside the cases it is checked against | An extrapolation, with no NASA validation inherited |

## 1. The pipeline at a glance

Propeller noise at the fuselage skin -> blocking by the fuselage -> cabin and structural modes -> interior SPL -> dB(A), SIL.

| Stage | What it does | Grade today | Detail |
|-------|--------------|-------------|--------|
| 1a. Free field, NASA measured data (validation test only, not a user option) | Digitized Fig. E-11 line, extended to 160 points by GEXT, used only to test the cabin model | Input V-EXP (repeatability only); GEXT V-ASSUMED | [§2.2](#22-nasa-measured-path-e11) |
| 1b. Free field, BEMT + F1A (the only user option) | CCBlade loads -> AcousticAnalogies F1A at the observers | X-EXTRAP | [§2.3](#23-aircraft-path-ccblade--f1a) |
| 2. Blocking (Eq. 43) | Raises the free-field pressure for reflection at the fuselage | V-UNIT / V-CODE | [§3](#3-stage-2--blocking-eq-43) |
| 3. Cabin acoustic modes (CYL2D) | 2-D finite-difference cross-section eigensolver | V-CODE | [§4](#4-stage-3--cabin-acoustic-modes-cyl2d) |
| 4. Structural modes (MRP) | Rayleigh-Ritz shell and floor modes | Hybrid circular; raw solver calibrated | [§5](#5-stage-4--structural-modes-mrp) |
| 5. PAIN core | Coupling, generalized force, trim, loss, power balance, high-frequency broadband | T1/T2 recorded results of the untuned chain (T2 keeps one stale fitted parameter) | [§6](#6-stage-5--pain-core-and-the-end-to-end-tests) |
| 6. Metrics | A-weighting, SIL | V-UNIT arithmetic; aircraft values extrapolated | [§7](#7-stage-6--metrics) |

The user supplies a propeller and aircraft and gets the BEMT + F1A source. The NASA measured line is a validation test input, not a user option: it exists only to check stages 2–5 against NASA's published results. The cabin stages are the same in both cases. The diagrams are `flowchart.md` diagram 2 (NASA validation), diagram 3 (aircraft
validation) and diagram 4 (shared cabin model).

## 2. Stage 1: free-field source at the 160 skin points

PAIN needs the free-field pressure amplitude and phase, per harmonic, at 160 points on the fuselage skin (the interface is
`VALIDATION_GUIDELINE.md` §5). Phases pass through blocking unchanged, and the generalized force uses the phase between points.

### 2.1 One user source, one validation input

The original PAIN took this grid from ANOPP. In this recreation the only user option is CCBlade + F1A (BEMT + F1A, for your own
propeller). NASA's measured Fig. E-11 line is not an option: it is the input of a validation test that checks the cabin model
against NASA's published results. No comparison with ANOPP is planned.

### 2.2 NASA measured data (validation test only)

1. **Digitized Fig. E-11.** The measured free-field line (l = 1) for harmonics H = 1, 2, 3, digitized twice; the two readings
   agree within δ_dig ≤ 1.0 dB. **Claim: V-EXP input, for the repeatability of the reading only.** H = 3 and all phases come
   from ANOPP Table 8, not from Fig. E-11, and measured H1/H2 are clipped to ANOPP where they exceed it (`broadband_clip_dB` 10).
2. **Grid extension (GEXT).** The paper measured one line, so the other points are filled with a cosine falloff in peripheral
   angle and a geometric phase delay from the path-length difference. **Claim: V-ASSUMED, unfalsifiable by published data.**
   On l = 1 the angle is 0 and the path length equals the reference, so the falloff is constant at 1 and the delay is 0 on the
   only measured line; neither can be fitted to, or checked against, it. No parameter is fitted; the form was fixed a priori
   (author attestation, not verifiable from the repository). The unit tests verify the code (falloff at 0°, 45°, 90°, phase
   sign, axis mapping), not the physics. GEXT is used in this path only.
3. **GEXT importance bound (planned, plan phase 32).** Varies the falloff exponent, a floor and the delay with every calibrated
   cabin parameter held fixed, and reports whether any variant flips the T1 verdict. It measures importance, not correctness and
   not circularity. The specification and the T1 claim-status table are in `VALIDATION_GUIDELINE.md` §2.2.1 and in §8 below.

### 2.3 BEMT + F1A (the user source)

**Method.** CCBlade (blade-element momentum) computes the section lift and drag along the blade. AcousticAnalogies (Farassat F1A)
computes the free-field pressure time history at each observer, and a DC-removed FFT gives the harmonic amplitudes and phases
(peak amplitude 2|X|/n). The default is loading-only (`thickness_over_chord = 0`). `asound` must be passed as the sound speed
(CCBlade's default of 1.0 m/s breaks F1A). Observers use AcousticAnalogies' (x3, x1, x2) ordering with the User Manual
r_p = a + 0.457. Airfoil polars come from XFOIL with a Viterna post-stall extension (plan phase 11).

**Status of the code (phases 21–22 done; I-01/I-02 fix + I-07 re-runs 2026-10-21).** The aircraft path runs F1A at all 160 grid points through one shared source function (`evaluate_propeller_source`), used by the production grid and by every validation case. GEXT stays on the e11 path only. **I-01:** source time span is two revolutions (`n_rev_src=2`) with a reception-inside-elements guard. **I-02:** harmonic phase is `angle(c) − ω_H·t₀` (BBN 24b V-UNIT passes at 0.5°). Optional Table-8 peak calibration remains post-step and is never compared with Table 8 when enabled (I-12/B-5). Raw smoke vs Table 8 (untuned geometry): peak deltas −4.2/−5.3/−5.8 dB (X-EXTRAP). Source-check verdicts against §2.12: BBN 24c **FAIL** (15% within tol); Report 996 scaled pressure **FAIL** (≥75% within ±2 dB not met) and page-12 phase **FAIL**; Pereira 23d H1 **FAIL** (0/9 within ±1.7 dB; Fig.9 H1 bars at 80 dB accepted as read, I-15 d).

**Claim today: X-EXTRAP.** Source-check verdicts wait on I-07 re-runs against the frozen §2.12 criteria (2026-10-21).

**Planned checks of the source block (all through the shared function; criteria fixed first, plan phase 23):**

| Order | Check | Plan phase | What it tests | What a pass would support |
|-------|-------|------------|---------------|---------------------------|
| 1 | **BBN/Wilby**, CR-158919 static and CR-159124 taxi (Aero Commander, 10 flush microphones) | 16 | Circumferential phase between microphone pairs against B × m × Δψ; relative in-plane levels of microphones 3–6 | "F1A phase between points in the rotation plane agrees with measurement, static and at taxi speed" (V-EXP, no fitted parameters). The longitudinal pairs need an assumed blade and stay X-EXTRAP |
| 2 | **NACA Report 996**, static, near field | 17–19 | CCBlade C_T and C_P; F1A total rms pressure and per-harmonic amplitude, loads scaled to measured thrust and torque, M_t 0.45–0.90 only | "With section loads scaled to measured thrust and torque, the source block reproduces the measured pressure within X dB at the listed cases" (V-EXP, calibrated). It supports the same non-dimensional conditions on a larger propeller, not other sizes, Reynolds effects, other blade shapes or a spinner and nacelle |
| 3 | **Gutin / Hanson cross-check** | 19 | Agreement between independent implementations on identical loads | V-CODE-like, not experiment. A "better than" claim needs those methods run on the same cases |
| 4 | **Pereira et al. 2026**, forward flight | 20 | CCBlade T and Q, F1A harmonics 1–2 at 1 m, phase-locked waveform at φ = 0° | The same statement within the paper's ±1.7 dB, far field only |

**What these checks do not support.** Thickness noise (no source isolates it, so one thickness-on case per figure is run as a
sensitivity only), any statement that F1A is better than other methods in general or for the aircraft application, and
fuselage scattering and reflection, which stay V-ASSUMED. The aircraft path stays X-EXTRAP until a check supports more.

## 3. Stage 2: blocking (Eq. 43)

Blocked amplitude = F(γ) × free-field amplitude, with F(γ) = 10^(0.3 − 0.000224·e^(0.08γ)) (about 6 dB at γ = 0 and 0 dB at 90°).
R2 limits the maximum to about 4 dB. Phases are unchanged.

**Claim: V-UNIT / V-CODE.** The implementation matches the CR-172428 p.68 narrative within 0.06 dB (R1; R2 maximum about 4 dB).
Caveat from the same report: scale-model blocked measurements show 3–4 dB near the propeller plane and the reflection dies away
faster off-plane than Eq. (43). The Fig. E-12 check (blocked level on the l = 1 line) tests Eq. (43) with R1/R2 only, not GEXT. Run 2026-10-20 (14a, `e12_blocking.md`): Eq. (43) on ANOPP Table 8 reproduces NASA's predicted E-12 curve at 29 of 31 points within δ_dig + 0.5 = 3.41 dB (V-CODE; two H3 points aft of the plane fail by 4.3 and 3.8 dB, recorded); the prediction is 1–7 dB above the measured circles (V-EXP, no pass mark). δ_dig = 2.91 dB, so the 1 dB digitization gate of E-11 is not met for E-12.

## 4. Stage 3: cabin acoustic modes (CYL2D)

A 2-D finite-difference cross-section eigensolver for a given floor angle, implemented exactly as CR-3813 Appendix C (phase 15,
2026-10-20): half-cabin grid (X ≥ 0) with the floor on a grid line and NY = 10 intervals from floor to crown; a node is in the
cabin when r ≤ 1 + 0.4h (inferred from the Fig. C-3 row counts; the window 0.32h–0.47h gives identical modes); Eq. (C.1) at every
cabin node; Eq. (C.2) at every boundary node with θ set to 0 below θ0; the two missing equations from a zero tangential gradient
at the two-exterior-neighbour boundary points closest to θ = π/4 and 3π/4; Eqs. (C.3)–(C.6) with symmetric and antisymmetric modes
solved separately, merged and ranked, the first 20 kept. Φ_G follows Eq. (C.10) and ε_n Eq. (C.11). A singular B_E, or a grid whose
eigenvalues are not real to 1e-3, raises an error naming the grid; no pseudo-inverse is used.

**Claim: V-CODE.** Against Table C-1 (c0 = 341 m/s, the speed the printed frequencies imply) all 20 frequencies agree within 0.001 % and
the generalized masses within 0.002 % (criterion fixed before the run: 0.1 %), the symmetry types agree, and Fig. C-3 modes 0–5
reproduce the printed one-decimal values at every node. This reproduces NASA's table, not an experiment. Two transcription errors in
the earlier reference values were corrected (modes 3 and 19), and the mode 5 mass reads 0.49815 on the page scan. Two points
are inferences and are V-ASSUMED: the node rule above, and, for the boundary integrals, the ends of the first and last wall and floor
segments placed at θ0 and the floor edge (the segments cover the whole transmitting surface). App. C holds only on grids where B_E is
non-singular and the spectrum is real: for θ0 = 56.6° that is NY = 8, 10 and 11 among 8–14 (NY = 10 is the paper's grid);
`cyl2d_modes_search` applies the 1 % next-valid-grid rule for other floors.

Three-dimensional modes n = (q, i) use Eq. (C.7) for the frequency and Eq. (C.9) for the shape; the axial count q ≤ ⌈2ω_H L/(π c0)⌉
is V-ASSUMED. ε_n for q > 0 is twice the q = 0 value (∫cos² dz = L/2). This is Eq. (C.11) as printed (CR-3813 pp. C-6, C-7: ε_q = 2 for q = 0, 1 for q > 0; read from the page images in plan 19c, 2026-10-20), no longer an interpretation. The factor 2 is confirmed by quadrature to 1e-15; the q = 0 value itself (the Eq. (C.10) node sum with C(j) weights) differs from an independent quadrature of the true cabin by 0.65 % to 5.4 % over modes 0–9, so the 0.5 % criterion of 19c is not met, a property of the printed discretization, recorded and not corrected (`eps_n_quadrature.md`). Reading ε_n(q > 0) = ε_n(q = 0) instead moves H1–H3 of the 18b run by −0.10, −2.02, −0.82 dB and does not close the miss (`eps_n_quadrature.md`; not adopted). Under Eq. (8) the q > 0 modes raise
H2 by 6.7 dB and H3 by 7.7 dB (Phase III trim), and the 0.1 dB convergence rule is met at q_max = 5, 9, 13 for H1–H3 (0.000 dB, `q_convergence.md`, diagnostic only).

## 5. Stage 4: structural modes (MRP)

A Rayleigh-Ritz model with Fourier shapes, sorted and truncated, giving the generalized masses.

- **Eqs. (D.22)–(D.26) (19g, 2026-10-20):** the raw Ritz solver is not an implementation of them: it has no u, v degrees of freedom, replaces the compatibility constraints (D.17)–(D.21) by soft junction springs and uses a Donnell-type diagonal with three fitted scales in place of the (D.25) operator; the smearing of (D.24) is present in spirit. The production path does not use it (`fig_d2_check.md`). Fig. D-2 mode 1 against the Table D-1 coefficients: shell within the print quantization (0.026 of the peak), floor 0.057 against a 0.05 criterion (not met).
- **Production (hybrid) path:** frequencies and masses come from NASA Table D-1 with Ritz shapes, so its 32/32 match with D-1
  is **circular** and tests nothing about the solver. Do not quote it.
- **Raw Ritz solver:** matches 30 of 32 modes within 5% (modes 2 and 9 miss) after three scales (`k_scale`, `edge_factor`,
  `floor_scale`) were fitted to maximise that same count, by greedy matching. **Claim: V-CODE (partial), calibrated.** It is
  not an experimental modal survey.

## 6. Stage 5: PAIN core and the end-to-end tests

**Sub-functions.**

| Sub-function | Grade |
|--------------|-------|
| Coupling and joint acceptance | Coupling f' follows CR-3813 Eq. (52) with Eqs. (46)–(49) and (53)–(57), including the floor term, the (−1)^n shell factor and √τ_t on the shell term; bare it is Eq. (45). No clamp: |f'| > 1 raises an error (none occurred in the phase 17 runs). Table D-1 shapes for all 32 modes are transcribed from the page scans; the transcription equals an independent digitization of Table D-1 in all 32 modes (17d; frequencies, total masses, every C_Mn, M and N). Analytic-limit tests (V-CODE), and ε_n now enters Eq. (8) |
| Generalized force Ψ_G, Eq. (42) (Δ⁴/2 form), using the blocked amplitude and phase at the 160 points | Analytic limits and the Eq. (41) double sum tested (17e, V-UNIT); the Table D-1 inputs equal NASA's (17d), and decided in 19d (2026-10-20): the 160 stated points are used, not mirrored (the input grid, Fig. 3, the card-36 note and CR-3813 §3.4 give one side only; the item 7 output wording "above and below θ = 0" is unresolved and gives no instruction to mirror). A mirrored field would move the 18b harmonics by +1.5, −2.1, +3.3 dB (about θ = 0) or +0.7, +3.2, +6.8 dB (about the ℓ = 1 line), neither closes the miss; `grid_mirroring.md` |
| Trim model: the App. A transfer matrices (A.10)–(A.22) from the printed equations, no fitted parameter, are in the pipeline since 17a (τ_t only inside f̄' in Eq. 8; τ_t also in the broadband path). V-UNIT limits and V-CODE against NASA's calculated Fig. E-14 (7 of 18 bands within ±25 %, criterion not met); Fig. A-2 and the V-ASSUMED trim inputs are in the register. The insulation path gives τ_t > 1 below about 250 Hz for the Phase III stack (trim resonance), which H1 depends on | V-UNIT / V-CODE (criterion not met); no calibration in the tone path |
| Loss factors (§3.8): Eqs. (63)–(83) from the printed equations, no fitted parameters, are in the pipeline since 17a (η_n of Eq. 77 with ξ, ξ_e at ω_H, or the bare input; η_r' at ω_r; η_r'' for every pair). The printed joint acceptances for n > 0 are half the mode-normalized value and the Eq. (82) limp-mass limit differs from the loaded-mass result (both recorded in the plan); η_r uses C_Mn² unnormalized, so p² is not invariant under a shape scaling (17i) | V-UNIT / V-CODE; no calibration in the tone path |
| Power balance (modal sum, Eq. (8) form, no explicit W_in = W_diss) | Independent re-implementation of Eq. (8) (direct form, quadrature coupling, double-sum Ψ_G) agrees to 2e-3 on a bare cabin (17h, V-UNIT); conservation check done in 19a (2026-10-20, V-UNIT): Eq. (8) follows from Eqs. (4)–(7) and the j_r² definition with no extra factor; in a two-resonator model (one cabin mode, one structural mode, hysteretic losses) solved exactly, the wall inflow equals Eq. (5) W_diss and, with the back-reaction removed, ⟨p_n²⟩ equals Eq. (8) and the inflow Eq. (7), all to about 1e-15; the back-reaction gives Eq. (83) exactly at ω = ω_r. Two properties of Eq. (8) recorded (not errors of the code, NASA uses the same form): it drops the reactive frequency shift of the back-reaction (at the test-article coupling −0.9 dB at ω_r and −4.9 dB at ω_n, +0.13 dB at 200 Hz), and it sums the structural modes incoherently (a coherent tone sum differs by up to ±5 dB in the illustrative case) (`eq8_two_resonator.md`) |
| High-frequency broadband (Eq. 19) with τ_t of Eq. (A.22) (17b), Spbl anchored on the grid-mean H = 3 blocked amplitude², f⁻² slope, `bb_j2_scale` = 0.5 (from an earlier fit, now stale), fitted absorption | calibrated (in-sample, parameter stale) with V-ASSUMED slope and anchor |

**T1, tonal interior SPL, H = 1–3, against Fig. E-16 (mean and range; E-17 95% CI and E-18 as references).** The gate passes
within 4.0 dB of the measured mean, or inside the measured envelope and within 4.0 dB of NASA's PAIN prediction.
**Claim: none.** **18a-r** (η_T = 0.5, author decision 2026-10-20; `phase20_baseline.md`): H1 81.04, H2 75.00, H3 75.29 dB — H1 and H2 pass by the NASA route only (means 90.0, 80.0; NASA PAIN 79.0, 75.5), H3 fails (mean 65.0, NASA 68.0). The original 18a numbers at η_T = 0.05 (90.2, 79.3, 83.2) stay in the record as "wrong η_T". **18b-r** (R1, Table 8, η_T = 0.5): 82.73, 75.73, 77.05 dB = +3.7, +0.2, +9.1 dB against NASA 79.0, 75.5, 68.0; criterion (4 dB) **not met, 2 of 3**. Original 18b at 0.05 (91.9, 80.0, 84.9) kept as "not met, wrong η_T". **19i (2026-10-21):** H3 at η_T = 0.5 is carried by structural modes 15, 25, 17, 21; omitted Table D-1 terms of size |δ| ≤ 0.057 do **not** move H3 by ≥ 3 dB toward NASA (**not found**); `h3_followup.md`. Phase 33 carries H3 as a stated limitation. Conditional on the trace-table identifications (`pain_core_eq8_phase17.md`); 19a–19b rule out the Eq. (8) algebra and (mA/4)²τ_ML. The envelopes are wide (H1 spans 65–97 dB) and the means are visual digitizations (about ±2 dB).

**T2, broadband 1/3-octave SPL against Fig. E-9, ±3.5 dB.** Only 1.25–2 kHz is available (the figure ends near 2 kHz).
**Claim: none.** **18a-r** (η_T = 0.5): 52.96 (pass), 50.62, 48.66 dB against 51.0, 46.0, 41.5; original 18a (62.3, 60.3, 58.5) kept as "wrong η_T". `bb_j2_scale` = 0.5 remains a stale fitted parameter; the high-frequency path is still a surrogate (30b). T2 depends on GEXT only
through the grid-mean H = 3 amplitude², which `bb_j2_scale` absorbs, so **T2 cannot constrain GEXT**.

**Findings from CR-172428 to quote with any "validated" statement.** Scale model: unbiased, σ about 4 dB. Flight: bias +2.6 to
+4.3 dB, σ 2.4–4.1 dB. All of these used +4 dB (R2-style) on the ANOPP free field, not the original +6 dB. After an R2-style
exterior, treat the prediction as an estimate with about 3.5 dB one-sigma for flight comparisons.

## 7. Stage 6: metrics

A-weighting and 1/3-octave band summation give dB(A) and SIL, with a ±3.5 dB band. **Claim: V-UNIT for the arithmetic.** The
aircraft values inherit the X-EXTRAP grade of the source and are reported with the uncertainty band, as an extrapolation.

## 8. GEXT importance bound and the T1 claim status

Run 2026-10-21 (`gext_importance_bound.md`); pre-registration `VALIDATION_GUIDELINE.md` §2.2.1. The GEXT grade (V-ASSUMED, unfalsifiable by
published data) does not depend on the result. **Result: any-variant flips** (flat falloff n = 0 flips H1; delay ×2 flips H2). Therefore **T1 is not claimable** even under V-ASSUMED refraction and scattering. Identity control matched 18a-r (81.04, 75.00, 75.29 dB). Falloff n ∈ {0.5, 1, 2} did not flip. This measures importance only; circularity is not measured.

## 8.1 Aircraft cabin required inputs (phase 29d draft)

User-supplied for any aircraft run (working example diameter 2.64 m is not a fixed constant). Template for D-20 / `examples/aircraft_cabin_<name>.json`:

- Fuselage geometry: L, a (or diameter), θ₀, cabin volume if not implied
- Propeller placement: r_p, φ_p, z_p
- Skin, stringers, frames (thicknesses, spacings, material E, ν, ρ) for MRP / wall mass
- Floor geometry and beams
- Trim stack: layer order, thicknesses, limp masses, loss factors; insulation table λ_m, α, φ, |W| vs frequency (Fig. A-2 form); mechanical connections
- End-plate mass and trim
- Bare-cabin η_n if untrimmed; C of Eq. (80)
- Provenance tag per input: measured | assumed | nasa_default (29c, [CONFIRM])

Until 29b/29c land, an aircraft run may silently use the test-article defaults listed in `VALIDATION_GUIDELINE.md` §2.10 (29a audit).

## 9. Claim register

| Claim | Grade | Evidence |
|-------|-------|----------|
| Blocking Eq. (43) R1 matches CR-172428 p.68 within 0.06 dB; R2 maximum about 4 dB | V-UNIT | `validation_reports/blocking_p68.md` |
| 160-point grid geometry matches the User Manual contract | V-UNIT | tests |
| GEXT cosine falloff and geometric delay implement the flowchart | V-ASSUMED, unfalsifiable by published data; no fitted parameters, form attested a priori | unit tests; **phase 32:** any variant flips T1 → **T1 not claimable** (`gext_importance_bound.md`) |
| CYL2D (App. C scheme): all 20 frequencies and generalized masses within 0.1 % of Table C-1, Fig. C-3 modes 0–5 equal | V-CODE | `cyl2d_table_c1.md` |
| Table D-1 (32 modes) hybrid production path | V-CODE, circular; Fig. D-2 mode-1 shape: shell met, floor not met (19g) | `mrp_table_d1.md`, `fig_d2_check.md` |
| Raw Ritz coverage of D-1, 30/32 within 5% | V-CODE (partial), calibrated | `mrp_ritz_vs_d1.md` |
| Fig. E-11 dual digitization δ_dig ≤ 1.0 dB | V-EXP input (repeatability only) | `e11_delta_dig.md` |
| T1 tonal interior SPL H = 1–3 against Fig. E-16 | No claim: untuned chain (17a, 2026-10-20) gives H1 90.2, H2 79.3 (within 4 dB of the mean) and H3 83.2 dB (fails); recorded, regrade in 18a | `t1_tonal.md` |
| T2 1/3-octave 1.25–2 kHz against Fig. E-9 (±3.5 dB) | No claim: fails by 11–17 dB on the untuned chain; the stale `bb_j2_scale` is a calibrated parameter; cannot constrain GEXT | `t2_third_octave.md` |
| CCBlade + F1A all-160 grid (shared `evaluate_propeller_source`) | X-EXTRAP (aircraft path). Optional Table-8 peak calibration kept as post-step only (**33b**): raw F1A does **not** match Report 996 / Table 8 within frozen tolerances, so calibration is not dropped and is never compared with Table 8 when enabled (I-12) | `ccblade_f1a_smoke.md`, `report996_acoustics.md`, `gext_vs_f1a_grid.md` |
| Eq. (8) tone pressure with the App. A trim and §3.8 losses in the pipeline (17a) | V-UNIT (analytic limits, scaling laws, independent re-implementation to 2e-3); conservation check done (19a, exact to 1e-15 in a two-resonator model); 18b reproduction of NASA's PAIN predictions fails (0 of 3); not validation | `pain_core_eq8_phase17.md`, tests |
| PAIN reproduction against NASA's predictions, Fig. E-16 circles, ANOPP Table 8 input (18b) | V-CODE, criterion 4 dB per harmonic dated 2026-10-20 before the run: **not met** (+12.9, +4.5, +16.9 dB); conditional on GEXT | `pain_reproduction_e16.md` |
| App. A trim and §3.8 loss factors as written (16a–16b), in the pipeline since 17a | V-UNIT (limits, quadrature) and V-CODE against Fig. E-14 calculated: 7 of 18 bands within ±25 %, criterion not met, not tuned; V-EXP against E-13/E-14/E-15 measured recorded with no pass mark | `trim_loss_e13_e14_e15.md`, tests |
| dB(A) ±3.5 dB band helper | reporting (V-UNIT arithmetic) | `overall_dBA` |
| BBN/Wilby circumferential phase | 24b PASS; 24c 23a FAIL (26/168, 15%); F1A |Δφ| tracks m·B·Δψ, measured signs often opposite — finding, not tuned (I-09 sense fixed) | `bbn_phase.md` |
| Report 996 loads / F1A (Figs. 14, 13a, 7) + 25k | I-07 re-run; I-08 L51C27 on Fig.13a; behind>ahead false after fix; 23c scaled ±2 dB FAIL (5/24); page-12 phase FAIL (103.8° vs 155°) | `report996_loads.md`, `report996_acoustics.md`, `report996_setup.md` |
| Pereira forward-flight (3 polars, ScaledLoads) | 23d **FAIL** on H1 (0/9 within ±1.7 dB vs Fig.9 Exp at 80 dB as read); H2 6/9 within ±3 dB; best unscaled `xtr005` s_T≈1.34 | `pereira_forward_flight.md` |
| Source-block summary (phase 33a/c) | BBN 24b PASS / 24c FAIL; Report 996 23c FAIL (scaled ±2 dB, page-12 phase); Pereira 23d FAIL H1; Gutin/Hanson cross-check **not run** (optional §2.3.3). Aircraft free field stays **X-EXTRAP** | this register; `VALIDATION_GUIDELINE.md` §2.3.3 |
| GUI Validation tab (phase 34) | Shows registered cases only (fixed inputs, fixed criterion, dated). Not a calibration tool; no editable case inputs. Same `run_validation_case` as scripts/`Pkg.test()`. Plots: reference as digitized + computed; PNG under `docs/validation_reports/figures/` | `src/validation_cases.jl`, `src/validation_plots.jl`, GUI Validation tab |
| CR-3813 E-21/E-22 digitization (C-05) | Pass B dual hand; δ_dig = 1.00 dB PASS | `e21_noise_reduction_range.csv`, `_B2.csv`, `e22_noise_reduction_ci.csv` |
| CR-3813 E-16…E-18, E-9/E-10 pass B (C-07–C-10) | Digitized 2026-10-21; pass A targets frozen | `t1_interior_targets_B.csv`, `e17_interior_ci.csv`, `e18_interior_pred_eta1.csv`, `t2_third_octave_targets_B.csv`, `e10_interior_ci.csv` |

**Pre-registration (phase 13, 2026-10-20).** The assumptions of the CR-3813 cabin chain (15a–17a) and the pass criteria for the loss and trim comparisons (Fig. E-14 calculated within ±25 %, Fig. E-13 within ±0.05, measured curves recorded with no pass mark) are fixed before any run in `VALIDATION_GUIDELINE.md` §2.11. A later change makes the affected result calibrated with the parameter named.

## 10. What this recreation does not claim

- That F1A is better than Gutin, Hanson or ANOPP-style methods. The planned checks score CCBlade + F1A against measurement only;
  a "better" claim needs the other methods run on the same cases and data (`VALIDATION_GUIDELINE.md` §2.3.3).
- That T1 or T2 validate the cabin model or GEXT. Both are in-sample. Circularity is not measured; the GEXT bound is an
  importance bound only.
- That any GEXT or cabin result is free of refraction and scattering effects. Both stay V-ASSUMED, so every claim is
  conditional on them.
- Full Peterson shell-floor Fourier matrices from the App. D OCR: the model uses diagonal Donnell/Kirchhoff terms, junction
  springs and D-1 shape Rayleigh seeds, so raw Ritz coverage is incomplete (D-1 modes 2 and 9).
- CCBlade/F1A as a validated replacement for ANOPP. Source checks (BBN 24c, Report 996 23c, Pereira 23d) did not meet
  frozen §2.12 tolerances (2026-10-21). The optional Table-8 peak calibration is an X-EXTRAP post-step only and must never
  be compared with Table 8 when enabled (`anopp_table8_calibrate: false` for raw checks).
- T2 above 2 kHz: Figs. E-9 and E-10 end near 2 kHz, so there are no measured means for 2.5–8 kHz.
- The App. A multilayer transfer matrix against laboratory material coupons: the masses come from the App. E text and the insulation
  data from Fig. A-2 digitized at six frequencies (±1 % of full scale); the Phase III facing/septum loss factor, the G-10 wavespeed, the mechanical connections and the end-plate backing are V-ASSUMED (register f).
- Inheritance of NASA validation by the aircraft CCBlade path without a source check that supports it.
- That the GUI Validation tab is a place to tune cases. Cases are registered and read-only; changing inputs after a result exists makes that result post-hoc (CLAUDE.md / plan R2–R3).

## 11. Conditions that apply to every claim

- **Parameters fitted or chosen with a target in view** are listed in the parameter register (`VALIDATION_GUIDELINE.md` §2.10).
  Any result that depends on them is a consistency check, not an independent validation.
- **Rules for every comparison:** no tuning to the cases; fix settings and pass criteria before comparing (plan phase 23);
  calibrated checks are labelled as such.
- **Refraction and fuselage scattering and reflection** are V-ASSUMED and kept out of the falloff and source tests.

## 12. Preferred cabin path and code notes

Preferred cabin path (calibrated): `data/e11_freefield_measured_A.csv` (with the ANOPP phase and H3 cleanup) -> GEXT -> blocking R2
-> Table D-1 hybrid MRP + CYL2D -> PAIN core with per-harmonic T(ω)/η and Eq. 19 high-frequency broadband -> T1/T2.

- Always pass `asound = c0` into `CCBlade.OperatingPoint` (the package default is 1.0 m/s).
- F1A observers are `[x3, x1, x2]` with `r_p = a + 0.457`.
- FFT: DC-removed, peak amplitude 2|X|/n, `df = 1/(n·dt)`.
- `extend_line_to_grid` has `falloff_exponent`, `falloff_floor` and `delay_scale` for the importance bound. The defaults are
  the nominal GEXT; they are not fitted parameters and must not be tuned to T1/T2.

## 13. Where things are

| Need | File |
|------|------|
| Evidence, tolerances, parameter register, reporting template | `VALIDATION_GUIDELINE.md` |
| Build order, phase checklist, data inventory | `IMPLEMENTATION_PLAN.md` |
| Diagrams (NASA validation, aircraft validation, cabin model) | `flowchart.md` |
| How to run it | `../README.md` |
| Validation reports | `validation_reports/` |
| Digitized data and READMEs with uncertainties | `../data/` (`report996/`, `pereira/`, `e11_*`, `t1_*`, `e14_*`, `e15_*`) |
