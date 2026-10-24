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
| 4. Structural modes (MRP) | Rayleigh-Ritz shell and floor modes | Hybrid transcription (`no_verdict`); raw solver calibrated (26/32 live) | [§5](#5-stage-4--structural-modes-mrp) |
| 5. PAIN core | Coupling, generalized force, trim, loss, power balance, reverberant NR (Eq. 18), HF tone Eqs. (15)–(16), high-frequency broadband Eqs. (19)–(23) | T1/T2 recorded; E-21/E-22 NR (38a); HF tones (38b); printed HF broadband (38c) `T2_EQ19` first run not met; `E18_TONES` (38d) 2/3 not met; `E15_STRUCT_LOSS` (38e) η_r′ info; default T2 still surrogate/`bb_j2_scale` | [§6](#6-stage-5--pain-core-and-the-end-to-end-tests) |
| 6. Metrics | A-weighting, SIL | V-UNIT arithmetic; aircraft values extrapolated | [§7](#7-stage-6--metrics) |

The user supplies a propeller and aircraft and gets the BEMT + F1A source. The NASA measured line is a validation test input, not a user option: it exists only to check stages 2–5 against NASA's published results. The cabin stages are the same in both cases. The diagrams are `flowchart.md` diagram 2 (NASA validation), diagram 3 (aircraft
validation) and diagram 4 (shared cabin model).

## 2. Stage 1: free-field source at the 160 skin points

PAIN needs the free-field pressure amplitude and phase, per harmonic, at 160 points on the fuselage skin (the interface is
`VALIDATION_GUIDELINE.md` §5). Phases pass through blocking unchanged, and the generalized force uses the phase between points.

### 2.1 One user source, one validation input

**The grid (User Manual pp. 8–9; CR-3813 App. E p. E-8).** k = 1…16 along the fuselage, ℓ = 1…10 around it from the propeller azimuth: x₁ = (r_p − a) + a(1 − cos α_ℓ), x₂ = −a sin α_ℓ, x₃ = (πa/18)(k_p − k), with α_ℓ = (ℓ − 1)·10°, and the fuselage station z_k = z_p − x₃ (z is the cabin axis, the aircraft body x axis, from the forward end of the cylinder). For the test article z_p = 0.662 m (App. E). Fixed 2026-10-23 (plan Phase 65): the code had z_k = z_p + x₃ with z_p = 0.90 m, a grid mirrored about the propeller plane.

The original PAIN took this grid from ANOPP. In this recreation the only user option is CCBlade + F1A (BEMT + F1A, for your own
propeller). NASA's measured Fig. E-11 line is not an option: it is the input of a validation test that checks the cabin model
against NASA's published results. No comparison with ANOPP is planned.

### 2.2 NASA measured data (validation test only)

1. **Digitized Fig. E-11.** The measured free-field line (l = 1) for harmonics H = 1, 2, 3, digitized twice; the two readings
   agree within δ_dig ≤ 1.0 dB. **Claim: V-EXP input, for the repeatability of the reading only.** H = 3 and all phases come
   from ANOPP Table 8, not from Fig. E-11, and measured H1/H2 are clipped to ANOPP where they exceed it (`broadband_clip_dB` 10).
   **Open (I-17, 2026-10-21):** `spl_dB_to_Pa` converts published dB to Pa as an rms-equivalent amplitude and feeds that into
   Eq. (42) as A; documentary reading of CR-3813 / User Manual / CR-172428 is that A is the Fourier cosine-peak amplitude
   (A = √2 p_rms). Omitting √2 leaves e11 / Table-8 tones ~3.01 dB low. Author decision pending; any fix is post-hoc.
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
Display-only cases `POLAR_R996` / `POLAR_PER` plot those polars, digitized TN 1546 / Report 824 section overlays from `data/airfoil_measured/` (not read by BEMT), and where the Report 996 / Pereira section operating points sit relative to the polar grid (no criterion, no verdict). `POLAR_R996` panel 4 (c_l vs Mach) uses one colour per α for TN 1546 curves and matching XFOIL markers.

**Status of the code (phases 21–22 done; I-01/I-02 fix + I-07 re-runs 2026-10-21).** The aircraft path runs F1A at all 160 grid points through one shared source function (`evaluate_propeller_source`), used by the production grid and by every validation case. GEXT stays on the e11 path only. **I-01:** source time span is two revolutions (`n_rev_src=2`) with a reception-inside-elements guard. **I-02:** harmonic phase is `angle(c) − ω_H·t₀` (BBN 24b V-UNIT passes at 0.5°). Optional Table-8 peak calibration remains post-step and is never compared with Table 8 when enabled (I-12/B-5). Raw smoke vs Table 8 (untuned geometry): peak deltas −4.2/−5.3/−5.8 dB (X-EXTRAP). Source-check verdicts against §2.12: BBN 24c **FAIL** (15% within tol); Report 996 scaled pressure **FAIL** (≥75% within ±2 dB not met) and page-12 phase **FAIL**; Pereira 23d H1 **FAIL** (0/9 within ±1.7 dB; Fig.9 H1 bars at 80 dB accepted as read, I-15 d).

**Claim today: X-EXTRAP.** Source-check verdicts wait on I-07 re-runs against the frozen §2.12 criteria (2026-10-21).

**Planned checks of the source block (all through the shared function; criteria fixed first, plan phase 23):**

| Order | Check | Plan phase | What it tests | What a pass would support |
|-------|-------|------------|---------------|---------------------------|
| 1 | **BBN/Wilby**, CR-158919 static and CR-159124 taxi (Aero Commander, 10 flush microphones) | 16 | Circumferential phase between microphone pairs against B × m × Δψ; relative in-plane levels of microphones 3–6 | "F1A phase between points in the rotation plane agrees with measurement, static and at taxi speed" (V-EXP, no fitted parameters). The longitudinal pairs need an assumed blade and stay X-EXTRAP |
| 2 | **NACA Report 996**, static, near field | 17–19 | CCBlade C_T and C_P; F1A total rms pressure and per-harmonic amplitude, loads scaled to measured thrust and torque, M_t 0.45–0.90 only | "With section loads scaled to measured thrust and torque, the source block reproduces the measured pressure within X dB at the listed cases" (V-EXP, calibrated). It supports the same non-dimensional conditions on a larger propeller, not other sizes, Reynolds effects, other blade shapes or a spinner and nacelle |
| 3 | **Gutin / Hanson cross-check** | 19 | Agreement between independent implementations on identical loads | V-CODE-like, not experiment. A "better than" claim needs those methods run on the same cases. **Gutin done (2026-10-24):** F1A = Gutin within 0.03 dB on the Hartzell rotor; the independent F1A of `F1A_INDEP` = Gutin within 0.03 % for a single-radius source; exact unit tests: no harmonic on the rotor axis, in-plane radiation from torque only. **Phase 66 (2026-10-24):** off-plane Gutin with thrust (levels within 0.26 dB, one near-null phase not met), Garrick–Watkins in flight (0.07 dB), thickness vs the compact far field (Hanson's compact limit, 0.002 dB), blade-count, 1/r and convergence — all on our use of the packages, which are unchanged |
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

**Claim: V-CODE (ratio form).** Against Table C-1, `TABLE_C1_C0 = 341 m/s` is the speed the printed frequencies imply (back-solved
from the table). The original absolute-frequency check at that c0 (all 20 within 0.001 %, Φ_G within 0.002 %, criterion 0.1 % fixed
2026-10-20) was therefore partly by construction: at c0 = 340 m/s, 0/19 modes meet 0.1 %. **Re-stated 2026-10-21 (post-hoc):**
frequency *ratios* f_i/f_1 (modes 2–19) within 0.1 % (c0-free; worst 0.0003 %); Φ_G, symmetry and Fig. C-3 modes 0–5 unchanged.
This reproduces NASA's table shape, not an experiment. Two transcription errors in the earlier reference values were corrected
(modes 3 and 19), and the mode 5 mass reads 0.49815 on the page scan. Two points are inferences and are V-ASSUMED: the node rule
above, and, for the boundary integrals, the ends of the first and last wall and floor segments placed at θ0 and the floor edge
(the segments cover the whole transmitting surface). App. C holds only on grids where B_E is non-singular and the spectrum is real:
for θ0 = 56.6° that is NY = 8, 10 and 11 among 8–14 (NY = 10 is the paper's grid); `cyl2d_modes_search` applies the 1 %
next-valid-grid rule for other floors.

Three-dimensional modes n = (q, i) use Eq. (C.7) for the frequency and Eq. (C.9) for the shape; the axial count q ≤ ⌈2ω_H L_c/(π c_int)⌉
is V-ASSUMED (cavity length L_c and interior sound speed; defaults L_c = structure L, c_int = c0). ε_n for q > 0 is twice the q = 0 value (∫cos² dz = L_c/2). This is Eq. (C.11) as printed (CR-3813 pp. C-6, C-7: ε_q = 2 for q = 0, 1 for q > 0; read from the page images in plan 19c, 2026-10-20), no longer an interpretation. The factor 2 is confirmed by quadrature to 1e-15; the q = 0 value itself (the Eq. (C.10) node sum with C(j) weights) differs from an independent quadrature of the true cabin by 0.65 % to 5.4 % over modes 0–9, so the 0.5 % criterion of 19c is not met, a property of the printed discretization, recorded and not corrected (`eps_n_quadrature.md`). Reading ε_n(q > 0) = ε_n(q = 0) instead moves H1–H3 of the 18b run by −0.10, −2.02, −0.82 dB and does not close the miss (`eps_n_quadrature.md`; not adopted). Under Eq. (8) the q > 0 modes raise
H2 by 6.7 dB and H3 by 7.7 dB (Phase III trim), and the 0.1 dB convergence rule is met at q_max = 5, 9, 13 for H1–H3 (0.000 dB, `q_convergence.md`, diagnostic only).

**Cabin mode animation (phase 36, display only).** `mode_animation.jl` builds full-section frames φ_n(x,y)·cos(ω t) from `cyl2d_modes` (half-cabin mirrored; antisymmetric modes change sign across the centreline), with fixed symmetric colour limits, nodal contours, floor/wall outline, and optional Eq. (C.9) axial factor. Modes 0–5 can show the printed Fig. C-3 one-decimal values beside the plot. The GUI **Cabin modes** tab (own tab; fixed `CYL2D_C1` inputs c0/θ0/NY) has mode and q selectors, play/pause/speed, and optional Table D-1 structural ψ + f′ (36d). Interpolation is for drawing only; node values are unchanged. **No criterion, no verdict, no tuning** — nothing in the animation feeds a result.

## 5. Stage 4: structural modes (MRP)

A Rayleigh-Ritz model with Fourier shapes, sorted and truncated, giving the generalized masses.

- **Eqs. (D.22)–(D.26) (19g, 2026-10-20):** the raw Ritz solver in `mrp.jl` is not an implementation of them: it has no u, v degrees of freedom, replaces the compatibility constraints (D.17)–(D.21) by soft junction springs and uses a Donnell-type diagonal with three fitted scales in place of the (D.25) operator; the smearing of (D.24) is present in spirit. The production path does not use it (`fig_d2_check.md`). Fig. D-2 mode 1 against the Table D-1 coefficients: shell within the print quantization (0.026 of the peak), floor 0.057 against a 0.05 criterion (not met).
- **Printed App. D solver (`mrp_appd.jl`, 38g, 2026-10-22):** implements constraints (D.17)–(D.21), constitutive (D.23)–(D.24), operator (D.25), eigenproblem (D.22), and shapes (D.26)–(D.29) with physical geometry/material from App. E / Manual §5.2 — no fitted scale. Selected with `structural_solver=:appd`; default remains Table D-1. Registry `MRP_APPD`: ≥ 75 % of 32 modes within 5 % (count rule fixed 2026-10-22 before any run); Fig. D-2 reported without a pass mark. **First run: 27/32 within 5 % → `:met`** (`mrp_appd_vs_d1.md`). Test-article length (I-22, 2026-10-22): program default **1.83 m** (`test_article_length()` / `TEST_ARTICLE_L`); Table D-1 title 1.803 m read as caption typo. Affected results re-recorded post-hoc; before/after `length_rerecord_before_after.md` (from `length_sensitivity.md`; no length selected from any error).
- **Production (hybrid) path:** frequencies and masses come from NASA Table D-1 with Ritz shapes, so its 32/32 match with D-1
  is **by construction**. Registry `MRP_D1` is a transcription check with verdict `no_verdict` (2026-10-21; was `met`). Do not
  quote it as a pass.
- **Raw Ritz solver:** three scales (`k_scale`, `edge_factor`, `floor_scale`) were fitted to maximise the count within 5 %, by
  greedy matching. Live code **29/32** within 5 % at L = 1.83 m (I-22 re-record 2026-10-22; was 26/32 at 1.803 m). Registry `MRP_RITZ` is always `no_verdict` — a calibrated regression guard, not evidence. **Claim: V-CODE
  (partial), calibrated.** It is not an experimental modal survey.

## 6. Stage 5: PAIN core and the end-to-end tests

**Sub-functions.**

| Sub-function | Grade |
|--------------|-------|
| Coupling and joint acceptance | Coupling f' follows CR-3813 Eq. (52) with Eqs. (46)–(49) and (53)–(57), including the floor term, the (−1)^n shell factor and √τ_t on the shell term; bare it is Eq. (45). **38f-1 (card 9):** when L ≠ L_c or d ≠ 0, the axial factor is (1/L)∫_{overlap} cos(qπ(z−d)/L_c) sin(Mπz/L) dz over [d, d+L_c] ∩ [0, L] (Methodology §3.5 points to Ref. [3] for L ≠ L_c; Manual defines d). Defaults L_c = L, d = 0 recover Eq. (57) exactly. No clamp: |f'| > 1 raises an error. Table D-1 shapes transcribed (17d). Analytic-limit tests (V-CODE); ε_n enters Eq. (8) |
| Generalized force Ψ_G, Eq. (42) (Δ⁴/2 form), using the blocked amplitude and phase at the 160 points | Analytic limits and the Eq. (41) double sum tested (17e, V-UNIT); the Table D-1 inputs equal NASA's (17d), and decided in 19d (2026-10-20): the 160 stated points are used, not mirrored (the input grid, Fig. 3, the card-36 note and CR-3813 §3.4 give one side only; the item 7 output wording "above and below θ = 0" is unresolved and gives no instruction to mirror). A mirrored field would move the 18b harmonics by +1.5, −2.1, +3.3 dB (about θ = 0) or +0.7, +3.2, +6.8 dB (about the ℓ = 1 line), neither closes the miss; `grid_mirroring.md`. **38f-1 (card 36):** `rotation_direction` +1 = CCW in +z as Fig. 3 (default); −1 = CW — flips grid azimuth θ_ℓ = φ_p ± α and blade-passage phase sign; does **not** mirror onto the lower quarter |

| Trim model: the App. A transfer matrices (A.10)–(A.22) from the printed equations, no fitted parameter, are in the pipeline since 17a (τ_t only inside f̄' in Eq. 8; τ_t also in the broadband path). V-UNIT limits and V-CODE against NASA's calculated Fig. E-14 (7 of 18 bands within ±25 %, criterion not met); Fig. A-2 and the V-ASSUMED trim inputs are in the register. The insulation path gives τ_t > 1 below about 250 Hz for the Phase III stack (trim resonance), which H1 depends on | V-UNIT / V-CODE (criterion not met); no calibration in the tone path |
| Loss factors (§3.8): Eqs. (63)–(83) from the printed equations, no fitted parameters, are in the pipeline since 17a (η_n of Eq. 77 with ξ, ξ_e at ω_H, or the bare input; η_r' at ω_r; η_r'' for every pair). The printed joint acceptances for n > 0 are half the mode-normalized value and the Eq. (82) limp-mass limit differs from the loaded-mass result (both recorded in the plan); η_r uses C_Mn² unnormalized, so p² is not invariant under a shape scaling (17i). Case `E15_STRUCT_LOSS` (38e) reports η_r′ vs Fig. E-15 measured targets with η_T = 1.0 and η_r_cap = 0.15 (V-EXP info, no pass mark) | V-UNIT / V-CODE; E-15 V-EXP info (38e); no calibration in the tone path |
| Power balance (modal sum, Eq. (8) form, no explicit W_in = W_diss) | Independent re-implementation of Eq. (8) (direct form, quadrature coupling, double-sum Ψ_G) agrees to 2e-3 on a bare cabin (17h, V-UNIT); conservation check done in 19a (2026-10-20, V-UNIT): Eq. (8) follows from Eqs. (4)–(7) and the j_r² definition with no extra factor; in a two-resonator model (one cabin mode, one structural mode, hysteretic losses) solved exactly, the wall inflow equals Eq. (5) W_diss and, with the back-reaction removed, ⟨p_n²⟩ equals Eq. (8) and the inflow Eq. (7), all to about 1e-15; the back-reaction gives Eq. (83) exactly at ω = ω_r. Two properties of Eq. (8) recorded (not errors of the code, NASA uses the same form): it drops the reactive frequency shift of the back-reaction (at the test-article coupling −0.9 dB at ω_r and −4.9 dB at ω_n, +0.13 dB at 200 Hz), and it sums the structural modes incoherently (a coherent tone sum differs by up to ±5 dB in the illustrative case) (`eq8_two_resonator.md`) |
| High-frequency tone expected value (Eqs. 11–16, §3.2): \(E[g]=\pi\omega_H/(2\bar\eta\Delta\omega)\), \(n_n,n_r\), Eq. (16) with \(j_r^{\mathrm{rev}}\); crossover card 10; `tone_model=:eq8` default / `:auto` | V-UNIT (E[\(g\)] closed=quad, Eq. 13 MC); REPRO_18b `:auto` recorded 2026-10-22 — I-18 “explains H3” not met (`phase38b_high_freq_tones.md`); default path unchanged |
| Reverberant noise reduction (Eqs. 17–18, §3.3): modal inflow and ⟨p_i²⟩/⟨p_e²⟩ with ⟨p_e²⟩ = ⟨p_bl²⟩/2, j_r²^rev, barred f̄', optional η_r′ cap (NASA E-21: 0.15); crossover band; `hf_model=:eq19` uses printed Eqs. (19)–(23) at/above crossover | V-UNIT helpers; V-CODE / V-EXP held-out on E-21/E-22 (38a, criterion dated 2026-10-21); full-band with Eq. 19 reported in 38c |
| High-frequency broadband printed Eqs. (19)–(23) (`hf_broadband.jl`, 38c): τ_f, τ_R, ᾱ from Eq. 24/78, A_t/S/A′, τ_t of Eq. (A.22); selector `broadband_model=:eq19`. Validation/e11 default stays `:surrogate` (τ_t, Spbl H=3 f⁻², `bb_j2_scale` = 0.5 stale). **Aircraft default (phase 30):** `cabin_blocks=:parametric` → `:eq19` (I-21 open readings → X-EXTRAP). **38f-1 (card 2):** ρ₀/c₀ → exterior, ρ/c → interior as printed on pp. 24–25 | Printed path: V-EXP `T2_EQ19` 0/3 vs E-9 (not met). Surrogate: calibrated (stale). Aircraft parametric: X-EXTRAP (I-21) |
| Noise reduction, reverberant exterior field, Eqs. (17)–(18) (`noise_reduction.jl`, 38a): modal inflow with the closed-form band integral {…}_nr/D_nr (p. 22), c_ω = 0.232, barred f′, `structural_joint_acceptance` as j²_rev, η_r′ cap option (0.15 = NASA's E-18/E-21 setting, default none); NR = −10 log₁₀(Eq. 18) with ⟨p_e²⟩ = ⟨p_bl²⟩/2. Crossover band (≥ 10 three-dimensional acoustic modes in the band) 400 Hz for the test article. Case `E21_E22_NR`: below-crossover counts V-CODE 1 of 4, V-EXP 0 of 4 → not met (first run 2026-10-22; 80–160 Hz excluded, V-ASSUMED). Tone model of 38b (`high_freq_tones.jl`, `tone_model=:eq8` default / `:eq15_16` / `:auto`): see `phase38b_high_freq_tones.md`. |
| Manual cards 2, 9, 36 inputs (38f-1) | Separate exterior/interior air (`ρ_ext,c_ext,ρ_int,c_int`; `ρ0,c0` still set both when omitted); cavity length L_c and offset d (V ∝ L_c; axial coupling over overlap); rotation_direction ±1 on `PropellerPlacement`. Defaults reproduce prior outputs exactly. Term map and V-UNIT: `phase38f1_card_inputs.md` | V-UNIT (input plumbing; no comparison criterion) |
| Manual cards 3–6 / 11–18 inputs (38f-2) | User 1/3-octave band set (`bands`, ≤ 26 standard centres, ascending; default = fixed `third_octave_centers()`). Per-band `η_r_band` / `η_n_band` (Dict or vector aligned with `bands`); 0/absent → compute as before (η_r Eqs. 79–81 then trim 82; η_n from trim or `η_n_bare`). Non-zero η_r replaces Eqs. 79–81 for every mode/tone in that band; lookup uses containing band (edges via c_ω). Defaults unchanged. Report: `phase38f2_card_inputs.md` | V-UNIT (input plumbing; no comparison criterion) |
| Manual §5.4.3 printed outputs (38h) | `printed_outputs(inp)` / `write_printed_outputs_md`: modes per band (acoustic + structural, crossover flagged), coupling f′(n,r) with shell/floor parts, Ψ_G(r,H), five largest Eq. (8) (n,r) contributions, tone + 1/3-octave interior spectrum, upper-quarter surface A/φ (lower quarter: not computed — I-18). Read from existing APIs only; no result change; no criterion. GUI **Printed outputs** tab. Example: `printed_outputs_REPRO_18b.md` | V-UNIT (tables vs helpers / tone totals); no comparison criterion |

**T1, tonal interior SPL, H = 1–3, against Fig. E-16 (mean and range; E-17 95% CI and E-18 as references).** The gate passes
within 4.0 dB of the measured mean, or inside the measured envelope and within 4.0 dB of NASA's PAIN prediction.
**Claim: none.** **18a-r** (η_T = 0.5, author decision 2026-10-20; `phase20_baseline.md`): H1 81.04, H2 75.00, H3 75.29 dB — H1 and H2 pass by the NASA route only (means 90.0, 80.0; NASA PAIN 79.0, 75.5), H3 fails (mean 65.0, NASA 68.0). The original 18a numbers at η_T = 0.05 (90.2, 79.3, 83.2) stay in the record as "wrong η_T". **18b-r** (R1, Table 8, η_T = 0.5): 82.73, 75.73, 77.05 dB = +3.7, +0.2, +9.1 dB against NASA 79.0, 75.5, 68.0; criterion (4 dB) **not met, 2 of 3**. Original 18b at 0.05 (91.9, 80.0, 84.9) kept as "not met, wrong η_T". **E-18 / `E18_TONES` (38d, first run 2026-10-22):** same 18b-r free-field/blocking with η_T = 1.0 and η_r_cap = 0.15 vs NASA E-18 prediction (88.0, 75.0, 67.0 at 200/400/630 Hz): 89.02, 78.14, 77.70 dB — **2/3** within ±4 dB, **not met** (`e18_tones_eta1.md`); V-EXP measured held out. **19i (2026-10-21):** H3 at η_T = 0.5 is carried by structural modes 15, 25, 17, 21; omitted Table D-1 terms of size |δ| ≤ 0.057 do **not** move H3 by ≥ 3 dB toward NASA (**not found**); `h3_followup.md`. Phase 33 carries H3 as a stated limitation. Conditional on the trace-table identifications (`pain_core_eq8_phase17.md`); 19a–19b rule out the Eq. (8) algebra and (mA/4)²τ_ML. The envelopes are wide (H1 spans 65–97 dB) and the means are visual digitizations (about ±2 dB).

**T2, broadband 1/3-octave SPL against Fig. E-9, ±3.5 dB.** Only 1.25–2 kHz is available (the figure ends near 2 kHz).
**Claim: none.** **Surrogate default** **18a-r** (η_T = 0.5): 52.96 (pass), 50.62, 48.66 dB against 51.0, 46.0, 41.5; `bb_j2_scale` = 0.5 stale. **Printed Eqs. (19)–(23)** (`T2_EQ19`, 38c first run 2026-10-22): 38.59, 35.87, 34.94 dB — **0/3** within ±3.5 dB (`phase38c_hf_broadband.md`); not tuned. T2 depends on GEXT only
through the grid-mean H = 3 amplitude², which `bb_j2_scale` absorbs, so **T2 cannot constrain GEXT**.

**Findings from CR-172428 to quote with any "validated" statement.** Scale model: unbiased, σ about 4 dB. Flight: bias +2.6 to
+4.3 dB, σ 2.4–4.1 dB. All of these used +4 dB (R2-style) on the ANOPP free field, not the original +6 dB. After an R2-style
exterior, treat the prediction as an estimate with about 3.5 dB one-sigma for flight comparisons.

## 7. Stage 6: metrics

A-weighting and 1/3-octave band summation give dB(A) and SIL, with a ±3.5 dB band. **Claim: V-UNIT for the arithmetic.** The
aircraft values inherit the X-EXTRAP grade of the source and are reported with the uncertainty band, as an extrapolation.

**Fixed 2026-10-21 (C5).** Theory audit C2-2 found `overall_dBA` was tones-only while this section said the 1/3-octave energy is
included. Code now energy-sums all 1/3-octave bands A-weighted at band centres (tones already sit in those bands — no double
count); tones-only remains only for spectra without bands. Aircraft example 83.22 → 83.74 dB(A); synthetic smoke 71.38 →
91.36 dB(A). This section is now true as written.

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
- Provenance tag per input: measured | assumed | nasa_default (29c done 2026-10-22)

**29b/29c (2026-10-22).** Aircraft JSON `cabin` (and 38f card keys) may give plain numbers or `{"value":v,"tag":…}`. Plain numbers that match a §2.10 NASA default are tagged `nasa_default`; others `assumed`. An aircraft run that still uses any test-article default warns once, sets `result.provenance.nasa_defaults`, and labels the printed-outputs header / GUI status (`uses NASA test-article defaults: …`; `NASA test article inputs used for: …, not the aircraft`). Fully specified example: `PAIN.jl/examples/aircraft_scale_hartzell_cabin_full.json`. Validation / `:e11` / `:synthetic` paths are bit-identical (no guard).

**Phase 30 (2026-10-22) — parametric cabin blocks.** Selector `cabin_blocks=:parametric|:surrogate` (`:auto` → `:parametric` on `source=:aircraft`, `:surrogate` otherwise). `:parametric` uses App. D modes from the user geometry/skin/stringer/frame/floor (`structural_solver=:appd`), trim stacks from JSON when supplied (same `TrimStack`/`InsulationTable` objects as Phase III), and HF Eqs. (19)–(23) (`broadband_model=:eq19`: ᾱ from Eq. (24)/(78), average radiation loss factors Eqs. (84)–(85)); no η_r cap, no absorption curve, no `bb_j2_scale`. **Eq. 19–23 carries the open readings recorded as I-21** — the aircraft result is X-EXTRAP with the epistemic band of phase 31, not a prediction of accuracy. `:surrogate` keeps Table D-1 + absorption/`bb_j2_scale`. Test-article regression (no criterion): `scripts/run/parametric_regression.jl` → `docs/validation_reports/parametric_regression.md`.

**Phase 31 (2026-10-22) — epistemic uncertainty band.** Pre-registered before any run (`docs/specs/phase31_uncertainty.md`). OAT keep > 3 dB; MC N = 4000, seed 20261022, uniform primary + triangular; P5/P50/P95, never the mean. **31e `UNC_COVER` `:not_met`:** kept `freq_scale`, `eta_t`; uniform P5/P50/P95 H1 88.95/89.87/91.06 vs measured 90 (inside, margin +1.05 dB), H2 85.46/91.3/92.86 vs 80 (miss −5.46), H3 73.09/74.78/77.59 vs 65 (miss −8.09); nothing widened. **Aircraft band:** kept `eta_n_bare`; uniform H1 99.31/101.41/104.21, H2 58.47/59.07/59.94, H3 35.45/35.65/36.26; k = −2.09, B = 3; phase (i) spreads 2.45/3.7/2.08 dB — dominates H2 and H3, not H1; triangular narrower by ~0.2–0.6 dB on the edges. Runtimes ~784 s (test article) / ~727 s (aircraft). **31f:** test-article report points the Required statements at the aircraft band file; empty 1/3-octave cells print —. Code: `src/uncertainty.jl`; reports `uncertainty_budget_testarticle.md`, `uncertainty_aircraft_band.md`.

## 9. Claim register

| Claim | Grade | Evidence |
|-------|-------|----------|
| Blocking Eq. (43) R1 matches CR-172428 p.68 within 0.06 dB; R2 maximum about 4 dB | V-UNIT | `validation_reports/blocking_p68.md` |
| `apply_blocking` full grid = F(γ)·A, phases unchanged (40a `ISO_BLOCKING`) | V-UNIT | first run 2026-10-23, met |
| Free-field SPL↔peak Pa (I-17) and e11 ℓ=1 loader (40b `ISO_FF_CONV`); Table-8 cal identity (40d `ISO_TABLE8`) | V-UNIT | first run 2026-10-23, met |
| 160-point grid geometry matches the User Manual contract | V-UNIT | tests |
| GEXT cosine falloff and geometric delay implement the flowchart | V-ASSUMED, unfalsifiable by published data; no fitted parameters, form attested a priori | unit tests; **phase 32:** any variant flips T1 → **T1 not claimable** (`gext_importance_bound.md`) |
| GEXT on ℓ=1 is identity for every option (40c `ISO_GEXT_LINE`); off-line stays V-ASSUMED | V-UNIT | first run 2026-10-23, met |
| CYL2D (App. C scheme): frequency ratios f_i/f_1 (modes 2–19) within 0.1 % of Table C-1 (c0-free; post-hoc re-statement 2026-10-21); Φ_G / symmetry / Fig. C-3 unchanged. Absolute-f check at c0 = 341 was partly by construction | V-CODE | `cyl2d_table_c1.md` |
| CYL2D vs exact circle J′ zeros at θ0=0° (40e `ISO_CYL2D_EXACT`); boundary/list (40j `ISO_CYL2D_BOUNDARY`) | V-UNIT | first run 2026-10-23, met (max \|e\| NY20 0.966 %) |
| Raw Ritz vs closed-form Donnell with stiffeners/floor removed (40f) | not registered — `structural_modes` always smears `MRP_I_STRINGER`/`MRP_I_FRAME` into Ds; no option zeros them | plan §8b note |
| `structural_joint_acceptance` vs quadrature (40g); modal density / band JA (40h); broadband band integral (40i); SIL (40k) | V-UNIT | 2026-10-23: all met; 40i reference = closed-form ∫ over exact 1/3-oct edges (α = 2, 1.5); code fixed to that integral (was band-centre rectangle) |
| Map-block cases of Phase 62 (12, one per block that had none; criteria 2026-10-23) | V-UNIT / input QA | first run 2026-10-23: 9 met; `BLK_GAIN_MAP` (R1 below 0 dB at γ > 90°), `MRP_SHAPE_NORM` (Table D-1 shapes peak up to 1.245), `CYL2D_WEYL` (App. C grid at NY = 10 over-counts modes above kh ≈ 1; post-hoc diagnosis) not met |
| Closure: every not-met case has a cause class (VALIDATION_GUIDELINE §2.14) | register | 2026-10-24: no open code defect; remaining misses are method-as-printed, low-fidelity approximation, input/data, or NASA output not explained by the documents |
| Cause of the source-block experimental misses (Phase 67; criteria 2026-10-24) | V-EXP (input) / diagnostic | 2026-10-24: XFOIL section c_l 0.15–0.35 below NACA TN 1546 measured (9/60 within 0.05, not met); BEMT thrust 25–32 % below Report 996 measured, consistent; compact-chord F1A changes near-field tones ≤ 0.27 dB. Limitation of the section-polar approximation, not of the code. Pereira: no measured section data at its Reynolds number, not testable |
| BEMT and F1A as used here against closed forms and identities (Phase 66; criteria 2026-10-24) | V-UNIT | 2026-10-24: 7/8 met; `F1A_GUTIN_ANGLES` not met at one near-null phase (θ = 60°, 100 R_tip). Code verification only; experiment unchanged (X-EXTRAP) |
| Every function in `src/` has a unit test (`test/unit/`, Phase 64; hand values, limits, independent routes) | V-UNIT | 2026-10-24: all pass; completeness test lists none missing; eight code defects found and fixed (report `phase62_65_map_blocks_grid.md`) |
| `absorption_coefficient` (40l) | fitted surrogate for `:surrogate` only; no isolated analytic case | docstring + map note |
| Phase 41 isolation: `TRIM_CLOSED`, `NR_BAND_HAND`, `HF_MASSLAW`, `BEMT_HAND`, `F1A_INDEP` | V-UNIT / V-CODE | first run 2026-10-23, all met; experimental misses with these isolations → model fidelity |
| `T1_FROM_E12` (41a): cabin tones from measured E-12 blocked pressures | V-UNIT (T1 gate) | first run 2026-10-23, **not_met** 2/3 (H3); cabin chain implicated |
| Phase 43a: Manual card 10 volume crossover default (f = 4.1 c₀/∛V); ten-mode option kept | input correction | post-hoc `:auto` re-runs 2026-10-23 (old ten-mode values kept); production `:eq8` unchanged |
| `T1_MEAS_DAMPING` (43b): T1 with measured η_n (E-13) and η_r′ (E-15) | V-EXP (T1 gate) | first run 2026-10-23, **not_met** 2/3 (93.78, 80.06, 79.41) |
| `H3_ATTRIB` (43c): NASA-value swaps on REPRO_18b | diagnostic | first run 2026-10-23; `h3_attribution.md` |
| `NR_TP1964` / `NR_TP1964_REF2` (43d): bare cylinder Eqs. (17)–(18) | V-EXP / V-CODE | **not_met** 6/18 and 6/18 (2026-10-23, after removing a 4× band mode window that gave NR = +Inf at 100–160 Hz; first run 5/18 and 4/18) |
| T2 exterior broadband (43e) | V-ASSUMED | none found in CR-3813 / CR-172428 / TP-1964 / CR-172384; HF path → NR_TP1964. **Found 2026-10-23: TP-2444 Fig. 17** (this article's exterior and interior narrowband spectra, 4000 rpm) → Phase 47 |
| `T1_F1A_FILL` (43f): T1 with F1A-relative off-line fill | V-EXP (T1 gate) | first run 2026-10-23, **not_met** 2/3 (79.61, 71.19, 71.30); after the Eq. (83) fix 79.65, 71.17, 71.06 |
| T2 high-frequency gap, attribution (2026-10-23) | code vs NASA / NASA vs measured | The code reproduces NASA's corrected program (CR-172428). Against CR-3813's printed E-22 prediction it is within 2–8 dB at 1250–2500 Hz (Phase 61: not explained by the documents); NASA's prediction is 32–44 dB above the measurement. Recorded as a **limitation of the PAIN methodology** within that stated difference (trim model valid to about 1 kHz, CR-172428 p. 152), not a code defect |
| `floor_sign` (61, input; default +1 = NASA's corrected Eq. 52; −1 = the pre-correction program of CR-3813's runs) and `REPRO_18b_PRE` / `E21_PRE` / `E22_HF_CODE` | V-CODE | not_met 1/3, 1/4, 1/4 (2026-10-23); the pre-correction sign does not reproduce CR-3813's runs |
| Sharp sound bridges (59, option `bridges`, off by default; extension beyond CR-3813, NASA CR-172490 §2.3): τ_B = τ_ML(m_s + m_t)·10^(−ΔTL_M/10) in parallel with τ_t·τ in Eq. (23) | V-UNIT (59a not met 3/13; 59b met) / V-EXP | `NR_PROP_TP2444_BR` 1/7, `E22_BR` 0/4, `T2_MEAS_EXT_BR` 28.4 vs 51.0 dB (2026-10-23) |
| App. D modes above Table D-1 (60a) | consistency | not met (App. D/asymptotic 2.32 at 1 kHz, 0.19 at 2 kHz); not adopted |
| `NR_PROP_TP2444_PF` (50b): NR under propeller excitation from Eq. (8) with the App. B field shape, band average, referred to the blocked level next to the propeller | V-EXP | not_met 2/7 (2026-10-23); 315–800 Hz within −3…+7 dB; 1000–1260 Hz above the 32-mode set |
| Eq. (66) diffuse acceptance vs exact 2-D diffuse field (50a) | V-UNIT | not met as written (0.4–2 dB high: separable approximation) |
| `sparse_guard` (53b, option, off by default): sparse HF bands with low in-band ⟨j²⟩ take the asymptotic branch | option | 400 Hz E-21 inputs 41.3 → 32.9 dB |
| `structural_modes(; include_floor, include_stiffeners)` (56, options, on by default) | V-UNIT | 40f not met: bare-shell Ritz 29–479 % above Donnell–Mushtari (empirical ring term, fitted k_scale) |
| `BPM_RP1218` (48a): airfoil self-noise, NASA RP-1218 §5 (TBL-TE, separation, LBL-VS, tip; no bluntness) | V-UNIT | met 270/270 against App. D Tables D2/D3 (max 0.19 dB) |
| `PROP_BB_FIG14` / `PROP_BB_FIG17` (48c): blade-segment BPM sum (RP-1218 App. C) with an assumed NACA 16-series blade, against the measured broadband floors | V-EXP (X-EXTRAP) | not_met 3/9 and 2/7 (2026-10-23); BPM 3–15 dB low |
| `T2_PRED_BB` (48d): BPM exterior → T2 Eqs. (19)–(23) → E-9 | V-EXP (X-EXTRAP) | not_met 0/3 (18 dB against 41.5–51 dB; the cabin path) |
| Phase 49 trim / HF inputs: τ_t of Eq. (A.22) by hand; Eq. (20) τ_f sums the modes resonant **below** the band (CR-3813 p. 24; corrected 2026-10-23 from the in-band sum, effect ≤ 0.3 dB); A′ = 0 per p. E-9 / E-35 | V-UNIT / documentary | met (10/10); NASA: the trim model over-estimates the sidewall treatment and is valid to about 1 kHz (CR-3813 p. E-35/E-39, CR-172428 p. 152) |
| `NR_PROP_TP2444` (47c): measured propeller-noise NR of the article (TP-2444 Fig. 17, 1/3-octave, tones removed, B = 5 Hz assumed) vs Eq. (18) / Eqs. (19)–(23) with the CR-172428 App. B trim | V-EXP | **not_met** 1/7 (2026-10-23): measured 30–36 dB; model 5–17 dB below 1 kHz, 49 dB at 1260 Hz |
| `T2_MEAS_EXT` (47d): T2's Eq. (19)–(23) path fed with the measured exterior (85.4 dB at 1250 Hz) vs E-9 | V-EXP | **not_met** (2026-10-23): 21.3 dB vs 51.0. Measured data consistent (85.4 − 33.9 = 51.5); PAIN's HF NR is 15–27 dB too high, as in NASA's E-21/E-22 predictions |
| Narrowband → 1/3-octave conversion (47b, `narrowband_third_octave`) | V-UNIT | met: exact on synthetic spectra (2026-10-23) |
| Phase 46 isolated checks: `broadband_cabin_p2`, `tone_expected_value` (Eqs. 14–16), `hf_structural_band` / `hf_band_loss_factors` (Eqs. 19–24, 81), `coupling_loss_factor_21` (A.20–A.21), `tone_Q_H`, α = 1 band integral, `w_in_reverberant` | V-UNIT | met 37/37 (2026-10-23) |
| `NR_TP1964_XOVER` / `_REF2` (45): TP-1964 NR with PAIN's changeover (Eq. 18 below, Eqs. 19–23 at/above 2500 Hz) | V-EXP / V-CODE | **not_met** 9/18 and 8/18; Eq. (19) bands 4/4 within ±2.5 dB of measured |
| `LOUDEST_PT` (42): Eq. (8) at interior points (coherent over acoustic modes, mean square over structural modes), overall dB(A) at the loudest point | V-UNIT (derived output; X-EXTRAP for aircraft) | **not_met** (a) 0.83–0.94 with interior nodes only; (b), (c) met; test article 79.1 / 83.7 dB(A) |
| CR-172428 App. A η_r′ (44c): Eq. (82) with m̄_r = m M_r / M_r^X, M_r^X = shell bending generalized mass (GMASS(IR,2)) | model correction, option `η_r_trimmed_area` (on for the R172428 cases; off = CR-3813 printed Eq. (82)) | V-UNIT met (reduces to m when M_r^X = M_r); M_r^X within 3.8 % of App. B (median 0.19 %) |
| Eq. (52) floor term with a plus on the raw Table D-1/MRP plate coefficients (NASA's corrected program; CR-172428 App. A item 2, App. B ETA R# 8/9 within 2.5 %) | code-on-code fix 2026-10-23 (production; 44f) | T1 87.36, 81.02, 75.23 dB; T1_F1A_FILL met 3/3 **post-hoc**; Phase 17 baselines re-recorded |
| Eq. (83) η_r″ with the bare f′(n,r) (CR-3813 p. 43) instead of the trim-weighted f̄′ | code-on-code fix 2026-10-23 (production) | T1 84.24, 77.63, 77.80 dB; verdicts unchanged; Phase 17 baselines re-recorded |
| `R172428_CODE` (44d): this code on NASA's printed CR-172428 inputs vs NASA's printed predictions | V-CODE | first run 2026-10-23, **not_met** 3/9 within ±3 dB |
| `R172428_EXP` (44e): the same vs measured Table 5 | V-EXP | first run 2026-10-23, **not_met** 1/9 within ±4 dB (NASA's own predictions 5/9) |
| `R172428_ETA` (44c/44d): η_r′ of 32 modes vs App. B | V-CODE | **not_met** 17/32 within ±25 % (modes 1–12 within 13 %) |
| `R172428_TRIM`, `R172428_PAIRS`: trim block and top modal pairs vs App. B | diagnostic | trim factor within 0.15 dB 250–1000 Hz; floor/antisymmetric pairs differ (open item 44f) |
| Table D-1 (32 modes) hybrid production path | transcription / `no_verdict` (was circular "met"); Fig. D-2 mode-1 shape: shell met, floor not met (19g) | `mrp_table_d1.md`, `fig_d2_check.md` |
| Raw Ritz coverage of D-1 | V-CODE (partial), calibrated; live 26/32 within 5 % (2026-10-21); report records 30/32 (stale); always `no_verdict` | `mrp_ritz_vs_d1.md` |
| Fig. E-11 dual digitization δ_dig ≤ 1.0 dB | V-EXP input (repeatability only) | `e11_delta_dig.md` |
| T1 tonal interior SPL H = 1–3 against Fig. E-16 | No claim: untuned chain (17a, 2026-10-20) gives H1 90.2, H2 79.3 (within 4 dB of the mean) and H3 83.2 dB (fails); recorded, regrade in 18a | `t1_tonal.md` |
| T2 1/3-octave 1.25–2 kHz against Fig. E-9 (±3.5 dB) | No claim: fails by 11–17 dB on the untuned chain; the stale `bb_j2_scale` is a calibrated parameter; cannot constrain GEXT | `t2_third_octave.md` |
| CCBlade + F1A all-160 grid (shared `evaluate_propeller_source`) | X-EXTRAP (aircraft path). Optional Table-8 peak calibration kept as post-step only (**33b**): raw F1A does **not** match Report 996 / Table 8 within frozen tolerances, so calibration is not dropped and is never compared with Table 8 when enabled (I-12) | `ccblade_f1a_smoke.md`, `report996_acoustics.md`, `gext_vs_f1a_grid.md` |
| Eq. (8) tone pressure with the App. A trim and §3.8 losses in the pipeline (17a) | V-UNIT (analytic limits, scaling laws, independent re-implementation to 2e-3); conservation check done (19a, exact to 1e-15 in a two-resonator model); 18b reproduction of NASA's PAIN predictions fails (0 of 3); not validation | `pain_core_eq8_phase17.md`, tests |
| PAIN reproduction against NASA's predictions, Fig. E-16 circles, ANOPP Table 8 input (18b / 18b-r) | Original 18b (η_T = 0.05): **not met** (+12.9, +4.5, +16.9 dB). **18b-r** (η_T = 0.5): 82.73, 75.73, 77.05 dB = +3.7, +0.2, +9.1; **not met, 2 of 3**. Registry `REPRO_18b` now runs 18b-r inputs (fixed 2026-10-21; was wrongly e11/R2). Label: **post-hoc (η_T = 0.5 input correction; result known from 19f)**; conditional on GEXT | `pain_reproduction_e16.md` |
| App. A trim and §3.8 loss factors as written (16a–16b), in the pipeline since 17a | V-UNIT (limits, quadrature) and V-CODE against Fig. E-14 calculated: 7 of 18 bands within ±25 %, criterion not met, not tuned; V-EXP against E-13/E-14/E-15 measured recorded with no pass mark | `trim_loss_e13_e14_e15.md`, tests |
| dB(A) ±3.5 dB band helper | reporting (V-UNIT arithmetic); **fixed 2026-10-21 (C5):** energy-sums A-weighted 1/3-octave bands (was tones-only; METHODOLOGY §7 now matches code) | `overall_dBA` |
| Free-field amplitude convention (rms vs Fourier peak) | **Open (I-17, 2026-10-21):** documentary reading A = √2 p_rms; code omits √2 on e11/Table-8 path. Author decision pending | plan I-17; `VALIDATION_GUIDELINE.md` §2.1 |
| BBN/Wilby circumferential phase | 24b PASS; 23a pre-registered FAIL 26/168 (reversed pair reading) on record; I-19 post-hoc φ_b−φ_a from CR-158919 §3.4/Table 8 → 134/168 still FAIL; CR-159124 convention unresolved (pair 8-9) | `bbn_phase.md` |
| Report 996 loads / F1A (Figs. 14, 13a, 7) + 25k | I-07 re-run; I-08 L51C27 on Fig.13a; behind>ahead false after fix; 23c scaled ±2 dB FAIL (5/24); page-12 phase FAIL (103.8° vs 155°; 109.0° after the 2026-10-22 polar re-run, post-hoc) | `report996_loads.md`, `report996_acoustics.md`, `report996_setup.md` |
| Pereira forward-flight (3 polars, ScaledLoads) | 23d **FAIL** on H1 (0/9 within ±1.7 dB vs Fig.9 Exp at 80 dB as read); H2 6/9 within ±3 dB; best unscaled `xtr005` s_T≈1.34 | `pereira_forward_flight.md` |
| Source-block summary (phase 33a/c) | BBN 24b PASS / 24c FAIL; Report 996 23c FAIL (scaled ±2 dB, page-12 phase); Pereira 23d FAIL H1; Gutin cross-check **done** (`F1A_GUTIN`: F1A vs Gutin summed annulus by annulus over the BEMT loads, Δ = 0.03 dB; reference corrected 2026-10-24, the earlier 0.31 dB used a closed form low by √2·M and is withdrawn); Phase 66 (2026-10-24): off-plane Gutin, Garrick–Watkins in flight and compact thickness noise met except one near-null phase; BEMT momentum identity, hand BEM with tip loss, integrals, similarity met (`phase66_bemt_f1a.md`). Aircraft free field stays **X-EXTRAP** | this register; `VALIDATION_GUIDELINE.md` §2.3.3 |
| GUI Validation tab (phase 34) + Validation map tab (phase 35 → total) | Shows registered cases only (fixed inputs, fixed criterion, dated). Not a calibration tool; no editable case inputs. Same `run_validation_case` as scripts/`Pkg.test()` (the suite writes its reports and figures to a temp dir and checks it left tracked docs/data unchanged, 2026-10-23). Plots: reference as digitized + computed + error panel; PNG under `docs/validation_reports/figures/`. One map `total` in `validation_map.jl` (aircraft + e11 + cabin + checks; `Position`/`Feeds`/`Group`/`Role`; horizontal canvas; group frames from own blocks only, pairwise disjoint). Case chips show a short display-only error line + source date (`k/n · X U max` / `no verdict · X U max`; full text in detail; absolute unit from last `(...)` in `error_ylabel`/`ylabel`; `:none`+met/not_met → `n/n within criterion`; snapshot CSV). Case/map/block copy from `VALIDATION_GUIDELINE.md` §2.13 (both tabs; each Explanation ends with Inputs / Equations / Outputs). `UT_GRID` runnable with γ-coloured grid figure. Runnable include `E18_TONES` / `E15_STRUCT_LOSS` (38d–38e); R996_FIG8 removed | `src/validation_cases.jl`, `validation_map.jl`, `validation_plots.jl`, GUI tabs |
| Cabin modes animation (phase 36) | Display only: full-section mode frames from `cyl2d_modes`, Fig. C-3 overlay, Eq. (C.9) axial factor, optional structural ψ / f′. Own GUI tab; fixed `CYL2D_C1` inputs. No criterion, no verdict, no tuning | `src/mode_animation.jl`, Cabin modes tab |
| CR-3813 E-21/E-22 digitization (C-05) | Pass B dual hand; δ_dig = 1.00 dB PASS | `e21_noise_reduction_range.csv`, `_B2.csv`, `e22_noise_reduction_ci.csv` |
| CR-3813 E-16…E-18, E-9/E-10 pass B (C-07–C-10) | Digitized 2026-10-21; pass A targets frozen | `t1_interior_targets_B.csv`, `e17_interior_ci.csv`, `e18_interior_pred_eta1.csv`, `t2_third_octave_targets_B.csv`, `e10_interior_ci.csv` |

**Pre-registration (phase 13, 2026-10-20).** The assumptions of the CR-3813 cabin chain (15a–17a) and the pass criteria for the loss and trim comparisons (Fig. E-14 calculated within ±25 %, Fig. E-13 within ±0.05, measured curves recorded with no pass mark) are fixed before any run in `VALIDATION_GUIDELINE.md` §2.11. A later change makes the affected result calibrated with the parameter named.

**Validation map (phase 35 → total, 2026-10-22).** One flowchart `total` in `src/validation_map.jl` (also drawn in `flowchart.md` §1 / §5) organises every registry case on a left-to-right stage canvas (input / function / output / check). Stage group frames are computed from each group's own blocks only and §2.13 `(col,row)` keeps those frames pairwise disjoint (aircraft checks above/below the pipeline; Free field in later columns). Earlier Map 1 / Map 2 pages are replaced in the GUI:

1. **Aircraft BEMT+F1A → Free field → Grid and blocking → PAIN main → Interior SPL**, with Structural modes / CYL2D / Trim and loss in parallel into PAIN main. Case chips branch from stage outputs (same case ids as before). A cabin-chain pass shows equations match printed tables / NASA PAIN / in-sample measurement; it does **not** validate the aircraft source.
2. **Aircraft source checks** (loads, F1A amplitude/phase, forward flight, surface levels) sit on the aircraft stage. Report 996 = static near-field amplitude; BBN = phase on a fuselage; Pereira = forward flight far field. Aircraft cabin SPL stays **X-EXTRAP**. The map is not a calibration tool.

## 10. What this recreation does not claim

- That F1A is better than Gutin, Hanson or ANOPP-style methods. The planned checks score CCBlade + F1A against measurement only;
  a "better" claim needs the other methods run on the same cases and data (`VALIDATION_GUIDELINE.md` §2.3.3).
- That T1 or T2 validate the cabin model or GEXT. Both are in-sample. Circularity is not measured; the GEXT bound is an
  importance bound only.
- That any GEXT or cabin result is free of refraction and scattering effects. Both stay V-ASSUMED, so every claim is
  conditional on them.
- Full Peterson shell-floor Fourier matrices: addressed in 38g by `mrp_appd.jl` (printed App. D); the calibrated `mrp.jl`
  surrogate still uses diagonal Donnell/Kirchhoff + junction springs and remains the non-default path only.
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

Preferred cabin path (calibrated): `data/cr3813/e11_freefield_measured_A.csv` (with the ANOPP phase and H3 cleanup) -> GEXT -> blocking R2
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
| Diagrams (overview/total, NASA validation, aircraft validation, cabin model, validation map) | `flowchart.md` |
| How to run it | `../README.md` |
| Testset titles / filter / typical times (P1) | `PAIN.jl/test/README.md` |
| Persistent Julia for checks (DaemonMode; not a PAIN dep) | `PAIN.jl/scripts/devtools/README.md` |
| Validation reports | `validation_reports/` |
| Digitized data and READMEs with uncertainties | `../data/` (`cr3813/` for E-11/T1/T2/E-14/E-15/…, `report996/`, `pereira/`; see `data/README.md`) |
| Scripts by purpose (R1) | `PAIN.jl/scripts/{run,checks,digitize,setup,smoke}/` (`scripts/README.md`) |
| Case registry + runners | `PAIN.jl/src/validation_cases.jl`, `validation_case_extras.jl` |
| Validation map (CASE_INFO, map `total`) + GUI map tab | `PAIN.jl/src/validation_map.jl` |
| Case plots (error panel, source page) | `PAIN.jl/src/validation_plots.jl`; figures under `validation_reports/figures/`; optional `PlotSpec.error_xlabel` when error-panel x ≠ main-panel x (`UT_GRID`) |
