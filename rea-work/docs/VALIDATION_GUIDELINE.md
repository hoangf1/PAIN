# PAIN Reimplementation — Validation Guideline

**Purpose.** Document what the recreated tool may claim as *valid*, what is only *code-to-code verified*, and what remains *extrapolated*, before (and as) the Julia recreation is built. Primary sources are the three PDFs in this folder, mapped to `flowchart.md`.

| Document | NASA report | Role |
|----------|-------------|------|
| `Pain Methodology.pdf` | NASA-CR-3813 (Pope, Wilby & Wilby, 1984) | Theory: modes, coupling, trim, Eq. (42)–(43), Appendices C–E |
| `Pain User Manual.pdf` | NASA-CR-172425 (Wilby & Pope, 1985) | Program I/O: CYL2D, MRP, MRPMOD, PAIN; ANOPP grid contract |
| `Pain Validation.pdf` | NASA-CR-172428 (utilization & validation) | Scale-model & flight comparisons; ANOPP limitations; blocking field findings |

**Propeller source change.** Original PAIN consumes **free-field** harmonic amplitudes and phases on a fuselage-skin grid from **ANOPP**. This recreation replaces that auxiliary source with:

1. **CCBlade.jl** — BEMT → sectional lift/drag (loading) along the blade  
2. **AcousticAnalogies.jl** — compact Farassat F1A → free-field pressure time history at each grid observer → Fourier harmonics  

Everything **downstream** of the free-field grid (blocking, structural/acoustic modes, power balance, SPL) follows CR-3813 / the flowchart unless noted.

---

## 1. Validity classes (use these labels everywhere)

| Class | Meaning | Allowed claim |
|-------|---------|---------------|
| **V-EXP** | Compared to experiment in CR-172428 / App. E of CR-3813 | “Agrees with measured data within stated tolerance” |
| **V-CODE** | Reproduced tabulated NASA code outputs (Table C-1, D-1, etc.) | “Matches reference tables within stated tolerance” — *not* experimental proof |
| **V-UNIT** | Analytic / unit checks of local math | “Implementation matches the written equation” |
| **V-ASSUMED** | Physics not uniquely fixed by the papers (e.g. off-line grid extension) | Must be labeled assumed; unit tests only verify code, not physics |
| **X-EXTRAP** | Aircraft application, or the CCBlade/F1A path outside the cases it is checked against | Report as extrapolation; do not claim NASA validation |

---

## 2. Flowchart blocks → evidence → acceptance criteria

### 2.1 Source — Test Article (measured) — flowchart `SRC_TA`

| Item | Spec |
|------|------|
| Input | Digitized Fig. E-11 free-field line (`ℓ = 1`), harmonics H = 1, 2, 3 |
| Check | Two independent digitizations → `δ_dig` amplitude difference |
| Class | **V-EXP** input path (measured exterior), independent of ANOPP / CCBlade |
| Status for recreation | Preferred closed-loop path for PAIN core validation |
| **Open (I-17, theory audit 2026-10-21):** free-field amplitude convention | `spl_dB_to_Pa` converts SPL → Pa as an rms-equivalent amplitude and that value enters Eq. (42) as A. CR-3813 Eqs. (28)–(31) and User Manual card 38 treat A as the Fourier (cosine-peak) amplitude; CR-172428 p. 41 references SPL to ⟨p²⟩. Documentary reading: A = √2 p₀ 10^(SPL/20); the code omits √2 → e11 / Table-8 tones ~3.01 dB low (affects T1, T2 tonal part, REPRO_18b, E12 levels, GEXT_BOUND). F1A path already stores the peak. **Author decision pending** on documentary grounds only; any code change makes affected results post-hoc (plan I-17). |

### 2.2 Grid extension (assumed) — `GEXT`

**Scope (phase 21–22):** GEXT applies to the **e11 validation path only**. The aircraft path runs F1A at all 160 points and does not call `extend_line_to_grid`.

| Item | Spec |
|------|------|
| Function | Cosine falloff + geometric phase delay from line `ℓ = 1` → 160-point free-field grid (**e11 only**) |
| Class | **V-ASSUMED**, unfalsifiable by published data (no off-line measured field; on ℓ = 1 the falloff is cos 0 = 1 and the delay is zero, so neither is identifiable from the line GEXT extends) |
| Unit tests | Falloff at 0° / 45° / 90°, phase sign, axis mapping — **verify code, not physics** |
| On-line check | Fig. E-12 blocked levels test **Eq. (43) + R1/R2 only**, *not* the extension. Run 2026-10-20 (plan 14a, `e12_blocking.md`): 29 of 31 points within δ_dig + 0.5 = 3.41 dB of NASA's predicted curve, two H3 points aft FAIL (recorded); δ_dig = 2.91 dB; measured circles 1–7 dB below (no pass mark) |
| Fitted parameters | None. Form fixed a priori (author attestation; not verifiable from the repository history) |
| Importance bound | Pre-registered in §2.2.1; **run 2026-10-21** (`gext_importance_bound.md`): flat falloff and delay ×2 flip T1 → T1 not claimable |

#### 2.2.1 GEXT importance bound (pre-registered 2026-10-19; variants re-dated 2026-10-21 for cabin inputs = 18a-r, η_T = 0.5)

**What it is.** An importance bound on the e11 path: how far the T1 verdict moves when GEXT moves, with every calibrated cabin parameter held fixed. It is not a validation of GEXT and does not measure circularity. The calibrated parameters were set with nominal GEXT in place and against the same figures T1/T2 compare to, so T1/T2 are **calibrated (in-sample)**; a result that does not flip means the in-sample fit is robust to GEXT, not that the model is validated. Circularity is not measured.

**Geometry gate.** On ℓ = 1, α = θ − φ_p = 0 (the angle from line ℓ = 1; the grid lies at θ_ℓ = φ_p + (ℓ−1)·10°, fixed in 12b, 2026-10-20) and R = R0, so falloff = 1 and delay = 0 there. Neither can be fitted to or checked against the published line, so no in-sample residual check is run. Falloff and delay are unfalsifiable with the published data.

**Variants** (falloff = max(cosⁿ θ, f); all other inputs nominal):

| Group | Runs | Notes |
|-------|------|-------|
| Falloff grid | n ∈ {0.5, 1, 2} × f ∈ {0 (current hard clip), 0.1, 0.3}, plus n = 0 (flat) | 10 runs including nominal (n = 1, f = 0). The floors 0.1 and 0.3 are stated assumptions, not derived. n = 0 is reported at full weight. The grid includes the n × clip corners |
| Delay (falloff nominal) | off, sign flip, ×0.5, ×2 | Delay off removes only the ℓ-dependent phase differences (ϕ0 still varies with k and H), so it is a real variant, not a null control. Exactly null on T2 by construction (the T2 anchor uses amplitudes only) |
| Identity control | n = 1, f = 0, delay ×1 | Must reproduce the nominal exactly |
| Conditional corner | n = 0.5 with delay ×2 | Added only if delay is non-null on T1 |

If sign flip and ×2 are both exactly null on T1, delay moves to the sanity bucket and the exact null is recorded as a code/data finding (phases not reaching the sum, or equal R at all points), not a GEXT finding.

**Held fixed.** Trim masses, tonal η, `bb_j2_scale`, absorption curve, all other §2.10 parameters.

**Statistic.** T1: per-H (H = 1, 2, 3, bands 200, 400, 630 Hz) interior SPL residual against the Fig. E-16 mean; report per-H maximum and RMS and the pooled RMS across H. T2: per-band residual at 1.25, 1.6, 2 kHz, reported to show the offset is band-invariant (not an independent test), together with the analytic prediction 10·log₁₀(mean f²_variant / mean f²_nominal) for the offset.

**Flip predicate (primary criterion).** The existing T1 gate in `validation_reports\t1_tonal.md`: mean ± 4.0 dB OR NASA ±4.0 dB within the envelope, evaluated per H. A flip is any H and any variant changing pass to fail or fail to pass (any-H rule). Also report each H's distance to the nearest gate edge. The E-17 half-width is reported as a secondary predicate if digitized; it does not decide.

**Scope of the result.** Marginal one-at-a-time bound, except the falloff grid and the conditional corner. It is conditional on refraction and scattering being V-ASSUMED; refraction stays out of the falloff test.

**Comparator.** One-at-a-time ±20% on the aggregate trim-mass scale, tonal η, and `bb_j2_scale` (T2 only): marginal, an order-of-magnitude referent, not a second bound. The GEXT spread also contains weak identifiability of the calibrated parameters; no posterior is available, so this confound is stated, not removed.

**If a variant improves the residual.** Report it as a finding. It is not adopted unless relabeled calibrated, and it does not show GEXT is the cause (other errors could be compensating). Follow-up: an exploratory cross-fit (calibrate under variant A, validate under B).

**T1 claim status** (beside GEXT's grade, which stays V-ASSUMED either way):

| Result | T1 claim status |
|--------|-----------------|
| No variant flips | calibrated (in-sample against E-16/E-17); the in-sample fit is robust to GEXT over the stated bracket; conditional on refraction and scattering being V-ASSUMED |
| Any variant flips | T1 verdict depends on GEXT; not claimable even under the V-ASSUMED refraction and scattering assumptions |
| A variant improves the residual | finding; not adopted unless relabeled calibrated; exploratory cross-fit |

**Code status.** `extend_line_to_grid` has the options `falloff_exponent` (n), `falloff_floor` (f) and `delay_scale` (added 2026-10-19). The defaults (1, 0, 1) reproduce the nominal GEXT exactly; they are not fitted parameters. A code-only test covers the identity control, flat falloff, floor, n = 2, delay off and sign flip, and argument checks. **`Pkg.test()` passed 2026-10-21** (including the GEXT options testset).

**Result (2026-10-21, `gext_importance_bound.md`).** Identity control reproduces 18a-r T1: 81.04, 75.00, 75.29 dB. **Flips:** flat falloff (n = 0) flips H1 PASS→FAIL; delay ×2 flips H2 PASS→FAIL; conditional corner n = 0.5 + delay ×2 also flips. Falloff grid with n ∈ {0.5, 1, 2} does not flip. **T1 claim status: depends on GEXT; not claimable** even under V-ASSUMED refraction/scattering. GEXT stays V-ASSUMED. 32e comparator deferred.

### 2.3 Source — Aircraft (computed) — `SRC_AC` (**ANOPP → CCBlade + AcousticAnalogies**)

| Item | Spec |
|------|------|
| Input | `aircraft.json`: blade geometry, chord/twist/thickness, Cl/Cd polars, rpm, forward speed, fuselage/prop geometry |
| Aero | CCBlade.jl BEMT → `L(r,ψ)`, `D(r,ψ)` (sectional loading) |
| Acoustics | AcousticAnalogies.jl F1A → free-field `p(t)` at 160 grid observers → amplitudes & phases for harmonics H |
| Grid contract | Same geometry as User Manual Fig. 3 / §3: `k = 1…k_max`, `ℓ = 1…10`, typically `k_max = 16` → **160 points**; ANOPP `(x₁,x₂,x₃)` mapping retained for observer placement |
| Class | **X-EXTRAP** for the aircraft application |
| Source-block check | NACA Report 996 (Hubbard & Regier, 1950): CCBlade thrust/torque and F1A pressures vs measured free-space total rms pressures near the propeller tips. Static, loading-only; see `IMPLEMENTATION_PLAN.md` phases 25–27. Forward flight (far field) is checked separately against Pereira et al. (2026), phase 28. Neither covers the aircraft case. Both checks and the production 160-point grid call the same source-evaluation function (plan phase 21), so what is checked is what runs. |
| Smoke test | `scripts/run/run_f1a_smoke.jl` compares peak SPL on the `ℓ = 1` line with ANOPP Table 8 from CR-172428. It is a sanity check, not a validation. |

**Known NASA limitation (CR-172428 §6 / ANOPP section):** ANOPP accuracy degrades by ~4th–5th harmonic; do not treat high-H exterior predictions as truth. F1A tonal methods have analogous limits—document harmonic cutoff in reports.

#### 2.3.1 Reference for the source block: NACA Report 996

NACA Report 996 (Hubbard & Regier, 1950) is the planned experimental reference for the CCBlade → F1A source block (test plan:
`IMPLEMENTATION_PLAN.md` phases 25–27).

**What it can support.** A check of the free-field source block (CCBlade loads → F1A pressure) in the **static, near-field,
loading-only** regime, for the first few harmonics. It does not cover forward flight, thickness noise, a full-scale aircraft, or the
fuselage grid.

**Limits of the report as a reference** (from the text and figures read so far; figures were read at low resolution):

- **No stated measurement uncertainty.** The text read gives the microphone type and a calibration statement but no error bars.
  Chart values must be digitized, which adds reading uncertainty. As with Fig. E-11, a two-pass digitization only shows
  repeatability, not accuracy.
- **The report's own theory is only approximate.** Its Eq. (2) is Gutin's formula with loads concentrated at an effective radius
  R_e that is fitted to the data (0.7R to 0.9R depending on condition). The report states that R_e = 0.9R overestimates all
  pressures by about 40 percent (about 3 dB) in one case. A 3 dB pass criterion is therefore close to the reference's own scatter.
- **Source of C_T and C_Q not confirmed.** Power was measured with a wattmeter plus motor-efficiency charts. Whether the C_T and C_Q
  values on the Fig. 14 table are measured or computed has not been checked. Measured static C_T and C_P from other NACA reports
  (RM L8H25a, RM L51C27) are available in the propeller data folder and are used for the load check instead.
- **Geometry and polars come from a separate data folder, not from the report.** Chord, twist, thickness, and hub radius are in
  `blade_form.csv` (NASA CR-196702 App. B-1, Harris 1996); the report's own Fig. 3 is not in the folder, so agreement is unchecked. Airfoil polars are
  XFOIL results (α −6° to 14°, M 0.2–0.72, Re ≥ 5×10⁵) that do not reach the stalled inboard sections or the low-Re, low-Mach root, so a
  post-stall extension is required. The folder's own BEM with these polars is 12–31% low in static thrust and 5–35% low in torque, so a C_T / C_Q mismatch cannot be blamed on CCBlade alone;
  the plan runs two polar sets and scales loads to measured T and Q to isolate F1A (plan phases 25c, 26, 27). The calibration factors in the second set (k_cl, k_cd)
  were fitted to forward-flight wind-tunnel data, not to Report 996, and are listed in the register in §2.10.
- **The digitized figures give total rms pressure, not harmonics.** Figs. 6, 7, 8 are digitized (one automated pass with QA overlays; about ±1–2 px, tails ±5–10 dyne/cm²;
  27 manual readings). Figs. 12(a),(b), 13(a) and 14(a) (harmonic amplitude vs x/D and vs tip Mach) were digitized from `rea-work\NASA Report 996.pdf` into `data\report996\tr996_fig12_13a_14_digitized.csv` (one automated pass with checked overlays; about ±1–2 px, which is under 1% on the log-scale Fig. 14 and about 1 dyne/cm² on the others). The C_T/C_Q table
  (`tr996_fig14_CT_CQ_table.csv`) was read by eye from the printed table. Fig. 12 and Fig. 14 overlap at x/D = −0.125 and agree to 6% or better, so no tolerance should be set tighter than that. Fig. 6 is B = 4 and the folder has no B = 4 thrust or torque, so Fig. 6 is judged on shape and clearance ratios.
- **Phase has one data point:** 155° measured against 165° from Eq. (2), M_t = 0.75, points equidistant ahead of and behind the plane (report p. 12, checked in `NASA Report 996.pdf`). The 125° value is Eq. (2) only, with no measurement. Everything else is amplitude only.
- **x/D sign and scope.** In the report, positive x/D is ahead of the plane of rotation and negative is behind (the Fig. 14 point x/D = −0.125 is behind). Tests cover tip Mach 0.45 to 0.90; nothing above 0.90 is tested (decision, 2026-10-16).
- **Static case.** Ground reflection was judged negligible by the authors. The PAIN code replaces any forward speed below 1 m/s with
  20 m/s (a guard added because static was thought ill-conditioned). It is not confirmed that CCBlade or AcousticAnalogies need
  this: their current source supports `Vx = 0` (CCBlade has an explicit hover branch; the AcousticAnalogies CCBlade helper has no
  division by `Vx`), though the pinned 1.0.0 versions were not read. It must be tested before any Report 996 result is reported, and
  the speed actually used must be stated with the result.

**Rules for using it:**

1. **No tuning to these cases.** Do not adjust pitch offset, polars, thickness, the Table-8 calibration, or any other parameter to
   reduce the difference on a case that is then reported as a test. If a parameter must be fitted, fit it on one figure (for example
   Fig. 7) and test on a different one (for example Fig. 14), and record the fitted value.
2. **Fix settings before comparing.** Record the settings used, then report the differences as found, including failures.
3. **Pass criteria come from the reference's scatter**, not from what the code achieves. Set them after the figures are digitized and
   before looking at results.
4. **Classification.** If the checks pass with no fitted parameters, report the source block as V-EXP with the limited scope above.
   If any parameter was fitted, report it as calibrated, with the parameter named.

#### 2.3.2 Reference for forward flight: Pereira et al. (2026)

Report 996 is static, so it cannot validate the forward-speed operation the aircraft path actually uses. The second reference is
Pereira, Ragni, Romani, and Casalino, *Aerospace Science and Technology* 177 (2026) 112963: an isolated 0.3 m, 2-blade propeller
(scaled APC 9×6, NACA 4412) at 8,000 RPM and 16 m/s (J = 0.4, tip Mach 0.37) in the TU Delft A-Tunnel, with 7 microphones on an arc
1 m from the hub (φ = −20° to 40°). It compares experiment, a lattice-Boltzmann CFD result, and a BEMT-based compact-source
prediction (plan phase 28).

**What it can support.** Forward flight, far field (1 m is about 3.3 propeller diameters), harmonics 1 and 2, the thrust and
torque of CCBlade at a forward-flight operating point, and the waveform timing of the phase-lock-averaged pressure at φ = 0° (encoder-referenced, Fig. 7). The paper's BEMT-based prediction and its CFD both include thickness noise, so a thickness-on run is comparable, but the measurement does not isolate thickness. No phase between microphones is published (Figs. 8 and 9 are levels). It does not test the near field, so it cannot replace Report 996 for the
fuselage-skin distances, and it does not test the fuselage grid.

**Limits as a reference** (from the paper's text; Figs. 6–9 and Tables 3–4 digitized 2026-10-21, cards C-01–C-04):
- **Stated uncertainty.** Appendix A gives a combined expected uncertainty of ±1.7 dB for the measurement (microphone ±1 dB, geometry
  ±0.6 dB, RPM ±0.1 dB), excluding room reflections, which the authors say can cause cancellation or doubling.
- **Motor noise.** Contaminates the 3rd, 6th, and 7th harmonics. Above the 4th harmonic the three methods disagree by more than 5 dB.
  Use harmonics 1 and 2 for pass/fail and treat higher harmonics as informational.
- **Harmonic 2.** The measured tone is 2.7 dB above the BEMT-based prediction, so the reference's own methods differ by more than
  the fundamental's ±1.7 dB.
- **Microphone angle convention.** φ = 0° is the rotation plane and positive φ is downstream (Fig. 2b). The microphones sit on a 1 m arc.
- **Phase between microphones is available.** Fig. 7 has three panels (φ = 0°, 20°, 40°) of phase-locked pressure against the propeller phase angle for experiment, CFD and the BEMT-based prediction, digitized in `data\pereira\` (first-harmonic phase advances about 19° of the harmonic cycle from 0° to 40° in the experiment, about 22° in the BEMT-based prediction; reading uncertainty about ±2°). The encoder zero relative to a blade is not stated, so compare phase differences between microphones, not absolute phase. This replaces my earlier statement that only φ = 0° is shown. See the plan's phase-validation figure list.
- **Wind-tunnel setup.** The microphones sit outside the jet. The paper's BEMT-based model used a single convective speed (the inflow
  speed) along the whole path from source to microphone and names this as a possible cause of directivity differences. Using
  `v_obs = [Vinf,0,0]` makes the same assumption; that is my reading, not a statement from the paper.
- **Geometry and polars.** Chord and twist are plotted in the paper (Fig. 1) with the data in Grande et al. (2022). The blades were not tripped and the paper's BEMT used natural transition, so the primary polar set is free transition (N_crit 9) with N_crit 5 and forced transition as brackets. Airfoil polars
  are not given (the paper's solver used a potential-flow plus boundary-layer method), so NACA 4412 polars must be generated with a viscous
  airfoil solver (XFOIL or similar) and extended past stall. The Re, Mach, and angle ranges, the transition settings, the extrapolation method, and where the files are
  recorded are specified in `IMPLEMENTATION_PLAN.md` (phase 28, "Pereira NACA 4412 polar specification"). A thrust or torque mismatch cannot be blamed on CCBlade
  alone; run both transition sets (free N_crit = 5 and forced) as a bracket and scale loads to the measured T and Q to isolate F1A. The paper's own BEMT torque is
  about 5% above the measurement. The solver settings (N_crit, x_tr, α_stall, c_d,max, Viterna parameters) are chosen before the comparison and entered in the §2.10 register.

The rules in §2.3.1 apply unchanged: no tuning to these cases, fix settings first, set pass criteria from the reference's scatter.

#### 2.3.3 What the Report 996 and Pereira checks can and cannot claim

**The checks measure accuracy on specific cases. They do not show F1A is "better".** "Better" needs a comparison: the same cases run through at
least one alternative method, with the same loads and the same observers, scored against the same measured data. The Report 996 and Pereira checks
as planned score F1A (CCBlade + AcousticAnalogies) against measurement only, which is the stated purpose: they validate BEMT and F1A, not a choice among methods. Correct as stated: showing "better" requires the alternatives (the report's Eq. (2) Gutin form with an effective radius, a Hanson frequency-domain
method, an ANOPP-style prediction) run on the same data. ANOPP itself will not be run (no comparison with ANOPP is planned), so an ANOPP-style comparator, if wanted, means a
Gutin/Hanson-type frequency-domain method, not ANOPP output.

Three further points limit what even a comparison would show:
1. **Loading-only F1A and Gutin are close relatives.** For a static propeller with compact loads both are linear-acoustics loading-noise formulas; with identical loads they should
   agree in the far field, and differ mainly in near-field geometry, retarded-time handling, and thickness. A small difference between them would mean the formulations agree, not that either matches reality.
2. **Load error can swamp the acoustic-method error.** The data folder's own BEM is 12–35% off in thrust and torque with these polars (§2.3.1), about 1–3 dB. That is why each case is run with loads
   scaled to measured T and Q, and why unscaled and scaled results are reported side by side.
3. **Reference scatter.** Source-to-source spread in the same quantity (for example, C_P at 15° and 20°, Fig. 7 legend vs RM L8H25a: −5% and +11%) is comparable to differences between methods
   that agree within a few dB. A claim of "better" would need a difference larger than that scatter, on cases where the methods actually differ (near field, thickness, forward flight).

**What the Report 996 result says about a larger propeller.** The comparison is non-dimensional: at fixed tip Mach, d/D, x/D, B, blade shape, C_T and C_Q, the near-field loading pressure scales with ρ·a² and does not depend on D, and F1A with the same scaled loads is dimensionally consistent by construction. A pass on a 4-ft propeller therefore supports the same source formulation at the same non-dimensional conditions on a larger propeller (a larger aircraft propeller sits in the same M_t, d/D, x/D range if its tip speed and clearance ratios do). It does not test any other size directly, and it does not cover Reynolds-number effects on the loads (those enter through the polars, which the scaled-load runs bypass), a different blade shape, or a spinner and nacelle in the flow. Check the aircraft's M_t, d/D, x/D and C_T, C_P against the ranges above before using the claim.

**Inter-point phase.** PAIN's generalized force uses the phase between grid points, which Report 996 (one value) and Pereira (one microphone) barely test. **Order (decision 2026-10-16): BBN/Wilby first for phase; Report 996 for amplitude; Pereira second as the forward-flight source check.** A hand check of its Appendix C tables against B × harmonic × hub angular separation already agrees to within about 6–13° at harmonics 1–2, 2–11° up to harmonic 7 for one pair and 11–31° at harmonics 3–5 for another, with B = 3 (see the plan). The BBN data are the pair of NASA Langley reports CR-158919 (static) and CR-159124 (taxi at 40–70 kt), an Aero Commander with 10 flush microphones: its circumferential trace velocities for the three microphones nearest the plane are 0.89–1.07 (static) and 0.97–1.02 (taxi) of the rigid-rotation value, so it tests circumferential phase with a little forward speed from D, rpm, B and geometry alone. It has no propeller chord, twist or airfoil (the companion Mixson et al. 1978 paper has no downloadable text); the plan records partial 9333C blade data (width, thickness and blade angle at six stations, repair minimums) from Hartzell Manual 114-8, with nothing outboard of 40 in and no section shape, the microphones are on a surface with reflections, and coherence is low at many harmonics, so axial phase from it would need an assumed blade and stays X-EXTRAP. A pass on the circumferential pairs would support "F1A phase between points in the rotation plane agrees with measurement, static and at taxi speed", not that the phase output is correct in general; the exact kinematic tests, the sign-convention check and an independent-implementation comparison remain required (plan phase 27).

**Claims the checks can support, if they pass with the rules in §2.3.1:**
- *Static, near field, loading only (Report 996):* "With section loads scaled to measured thrust and torque, the CCBlade + AcousticAnalogies source block reproduces the measured total rms pressure at
  the Report 996 conditions within X dB (cases listed; M_t 0.45–0.90; polar-set bracket Y dB)." Report as **V-EXP, calibrated** (load scaling is a fitted input) and, for the unscaled
  runs, as the end-to-end CCBlade + F1A difference with the polar uncertainty shown.
- *Forward flight, far field (Pereira):* the same statement for harmonics 1–2 at 1 m, within the paper's ±1.7 dB uncertainty if the result lands there.
- *Cross-implementation:* "F1A agrees with Gutin Eq. (2) and a Hanson near-field implementation to within Z dB on identical loads" is **V-CODE-like** (agreement between implementations), not experimental proof.
- *Comparative accuracy, only if the comparison is run:* "On these cases, F1A's error against the data is smaller/larger/similar to Gutin's and Hanson's," stated with the cases and the scatter above. A statement about
  being better in general, for the aircraft application, or than ANOPP is **not supported**.

**Thickness noise.** None of the sources in hand isolates measured thickness noise. Report 996's theory is loading-only; Pereira's data are total tonal noise. The data folder's own Hanson thickness-only result is far below the measured level (mean −16 dB at M_t 0.75, Report 1079, far field),
which suggests thickness is small in the static subsonic cases but does not show it at the near-field distances. The plan therefore runs one thickness-on case per figure as a sensitivity and makes **no thickness-noise validation claim**. Leads found by web search, not opened or read: a Bath near-field propeller paper comparing Farassat-based predictions with near-field measurements
(people.bath.ac.uk/ensmjc/Research/aiaa96.pdf), NASA NTRS 19840006806 and 19800016608 (Farassat linear model vs propeller wind-tunnel data), and Mall & Farassat's thickness-noise code report (NTRS 19760010837). Read them before citing any.

**Near-field Hanson and Gutin as comparators (optional).** Gutin's classic form and the data folder's existing Gutin/Hanson results are far-field (observer distance ≫ propeller radius), so they do not apply at d/D = 0.04–0.33. The report's own Eq. (2) is a near-field-capable Gutin form but needs a fitted effective radius.
A Hanson frequency-domain near-field method (a published near-field extension of Hanson's helicoidal-surface theory; citation to be confirmed before it is quoted) handles finite distance and forward flight. They are worth implementing
as **independent comparators** for the cross-check and the "better" comparison, using the same CCBlade loads, because they share no code with AcousticAnalogies and therefore catch coding errors in the F1A path. They are
not recommended as the production source: they need an effective radius or equivalent load model, have no general arbitrary-motion capability, and would give up the one thing the F1A path offers (the same code for static, forward flight, and thickness). Both lack
quadrupole noise, so results near M_t = 0.9 carry that limitation.

### 2.4 Blocking — Eq. (43) — `BLK` (shared)

Empirical Magliozzi curve (CR-3813 §3.4; flowchart formula):

\[
F(\gamma) = 10^{\,0.3 - 0.000224\,e^{0.08\gamma}}
\qquad
A_H^{\mathrm{blocked}} = F(\gamma)\, \bar{A}_H^{\mathrm{ff}}
\]

Phases: **unchanged** from free-field (CR-3813; CR-172428 §6).

| γ (deg) | Expected ΔL = 20 log₁₀ F(γ) (dB) | Notes from CR-172428 p.68 |
|--------:|----------------------------------:|---------------------------|
| 0 | ≈ 6.0 | “6 dB greater than free field” |
| ≤ 30 | ≈ 6 | “close to 6 dB” |
| 50 | ≈ 5.75 | tabulated narrative |
| 60 | ≈ 5.4 | |
| 70 | ≈ 4.75 | |
| 80 | ≈ 3.3 | |
| 90 | ≈ 0 | “finally to zero at 90°” |

| Criterion | Spec | Class |
|-----------|------|-------|
| Formula fidelity | Match CR-172428 p.68 narrative ΔL within **0.06 dB** | **V-UNIT** / **V-CODE** |
| Variant **R1** | Full Eq. (43) (max ≈ 6 dB) — original programmed model | Default CR-3813 |
| Variant **R2** | \(F_{R2}=\max(1,\,0.8\,F_{R1})\) — max ≈ 4 dB (CR-172428 §5.3.2 “RHS × 0.8”) | Preferred for flight-style comparisons |
| Independent data (amplitude only) | NACA Report 996 Fig. 10 (B = 2, 20° blade angle, M_t 0.60, d/D 0.083): pressure at a flat vertical wall is about twice the free-space value (6 dB, the R1 maximum) and at a circular fuselage-like wall somewhat less (the report uses 1.5×, about 3.5 dB, close to R2's 4 dB). One condition, wall-plane pressure, no phase; not digitized | Check of R1/R2 only; does not test phase unchanged by blocking |
| Physics caveat | Scale-model blocked measurements show **3–4 dB** near prop plane; reflection dissipates **faster** off-plane than Eq. (43) (CR-172428 p.68, §6) | Document; do not “fix” without new data |

### 2.5 Structural modes — `MRP` (MRP + MRPMOD merged)

| Item | Spec |
|------|------|
| Method | Rayleigh–Ritz Fourier shapes → sort, truncate, generalized mass \(M_r\) |
| Verify | Table D-1 first **32** modes within **5%** on frequency (flowchart) | **V-CODE**. The production / hybrid path copies Table D-1 frequencies, so "32/32" is by construction. Registry case `MRP_D1` is a **transcription check with verdict `no_verdict`** (was `met`; changed 2026-10-21). The raw Ritz check (`MRP_RITZ`, `n_spec ≥ 25`) is kept only as a **regression guard of a calibrated fit** (`k_scale`, `edge_factor`, `floor_scale` fitted to the same count), not evidence. Live code **26/32** within 5 % (2026-10-21); `mrp_ritz_vs_d1.md` still records 30/32 (record stale; `mrp.jl` not changed in this work). |
| Not | Experimental modal survey |

### 2.6 Acoustic cabin modes — `CYL2D`

| Item | Spec |
|------|------|
| Method | CR-3813 App. C exactly (phase 15, 2026-10-20): half-cabin finite-difference grid, NY = 10 floor-to-crown intervals, Eqs. (C.1)–(C.6), tangential-gradient rule at the two-exterior-neighbour points nearest π/4 and 3π/4, symmetric and antisymmetric modes solved separately, 20 kept; Φ_G Eq. (C.10), ε_n Eq. (C.11); 3-D modes (q, i) by Eqs. (C.7), (C.9) |
| Verify | **Original (2026-10-20):** Table C-1 at c0 = 341 m/s: 20 frequencies and generalized masses within 0.1 %, symmetry types, Fig. C-3 modes 0–5. **Correction 2026-10-21 (post-hoc):** `TABLE_C1_C0 = 341 m/s` is back-solved from Table C-1's own frequencies (one fitted scale). At c0 = 340 m/s, 0/19 modes are within 0.1 %; at 341, 19/19 — so the absolute-frequency check was partly by construction. **Re-stated criterion (dated 2026-10-20; ratio form 2026-10-21, post-hoc):** frequency *ratios* f_i/f_1 (modes 2–19) within 0.1 % (c0-free); Φ_G, symmetry and Fig. C-3 unchanged. | **V-CODE** |
| Result | Ratio form: worst relative error 0.0003 % (modes 2–19). Φ_G max error 0.002 %, Fig. C-3 0 mismatches (`cyl2d_table_c1.md`). Absolute-frequency numbers at c0 = 341 remain in the older report as history. Errors of an earlier reference transcription (modes 3, 19) corrected |
| Registers | 13a(a): the node window r ≤ 1 + 0.32h … 0.47h gives identical modes (0.31h gives a 4-node second row; 0.48h a 7-node fourth row; both then fail the real-spectrum check). 13a(b): for θ0 = 56.6° the valid NY among 8–14 are 8, 10, 11 (NY = 10 is the paper's); the others have complex eigenvalues. θ0 = 90° has a singular B_E at every NY tried, and θ0 = 40° and 70° had at most one valid NY in 8–14, so `cyl2d_modes_search` can fail; the error names the grid. 13a(d): q_max = ⌈2ω_H L/(π c0)⌉ = 5, 9, 13 at H1–H3; q_max + 2 changes the Eq. (8) sum by 0.000 dB for the Phase III trim and the bare cabin (`q_convergence.md`, repeated in 17a): rule met |

### 2.7 PAIN main — coupling, forces, trim, loss, power balance

| Sub-function | Reference | Validation target | Class |
|--------------|-----------|-------------------|-------|
| Coupling \(f'(n,r)\) + joint acceptance \(j_r^2\) | CR-3813 §3.5–3.6 | Eq. (52) with Eqs. (46)–(49), (53)–(57) implemented (floor term, (−1)^n, √τ_t, no clamp); analytic-limit tests (V-CODE); ε_n now enters Eq. (8); no |f'| > 1 error in the phase 17 runs | **V-CODE (analytic limits only)** |
| Generalized force \(Ψ_G\) Eq. (42) | CR-3813 §3.4 | Δ⁴/2 form implemented (17a); analytic limits, the Eq. (41) double sum and the grid spacing tested (17e, 11 checks); Table D-1 inputs equal an independent digitization (17d, all 32 modes); 19d (2026-10-20): the 160 stated points are used, no mirroring (input grid, Fig. 3, card-36 note, CR-3813 §3.4; the item 7 output wording is unresolved); mirrored-field diagnostics in 18b move H1–H3 by +1.5, −2.1, +3.3 dB (about θ = 0) and +0.7, +3.2, +6.8 dB (about ℓ = 1), not adopted (`grid_mirroring.md`) | **V-UNIT (analytic limits)** |
| Trim transfer matrix | CR-3813 App. A | Figs. E-13, E-14 | In the pipeline since 17a, no fitted parameter. Exact limits (V-UNIT); Eq. (78) with ξ from Eq. (A.16) vs NASA's calculated E-14 curves, 7 of 18 bands within ±25 % at trim loss 0.5 and 1.0, **criterion not met**, not tuned (§2.11.3); E-13 has no calculated curve |
| Loss factors §3.8 | CR-3813 | Figs. E-14, E-15 | In the pipeline since 17a, no fitted parameter. Si/Cin to machine precision, joint acceptances vs direct quadrature, η_n/η_r'/η_r'' limits (V-UNIT); E-15 η_r' recorded with no pass mark. η_r uses C_Mn² unnormalized (shape scaling is not an invariance of the full p², 17i) |
| Power balance \(W_\mathrm{in}=W_\mathrm{diss}\) + modal sum | CR-3813 §3.1 Eqs. (1)–(3), (8), (16) | Eq. (8) summed by Eq. (3) (17a); independent re-implementation (direct form, quadrature coupling, double-sum Ψ_G) agrees to 2e-3 on a bare cabin, scaling laws tested (17h, 17i); 19a (2026-10-20, criteria fixed before the run): Eq. (8) derived from Eqs. (4)–(7); two-resonator model solved exactly, inflow = Eq. (5) W_diss, weak-coupling ⟨p_n²⟩ = Eq. (8) and inflow = Eq. (7), back-reaction loss = Eq. (83) at ω_r, all within 1e-15 (11 of 11 criteria met); 19b: (mA/4)²τ_ML = (ρ0c0A/(2ω_H))² exact. Recorded: Eq. (8) omits the reactive back-reaction (−0.9 dB at ω_r, −4.9 dB at ω_n for the test-article f′ = 0.19; +0.13 dB at 200 Hz) and sums structural modes incoherently (`eq8_two_resonator.md`); 19c (2026-10-20): ε_n(q > 0) = 2 ε_n(q = 0) is Eq. (C.11) as printed (pp. C-6, C-7), factor confirmed by quadrature to 1e-15; the q = 0 node sum differs from an independent quadrature by 0.65–5.4 % (criterion 0.5 % not met, recorded); the alternative ε_n(q > 0) = ε_n(q = 0) shifts the 18b harmonics by −0.10, −2.02, −0.82 dB and does not close the miss (`eps_n_quadrature.md`) | **V-UNIT (derivation, two-resonator conservation)** |

**Theory audit 2026-10-21 (read-only).** A documentary read of CR-3813 / User Manual / CR-172428 against the code found one new open item (free-field amplitude convention, I-17 / §2.1) and one item since fixed (`overall_dBA` band sum, §2.9 / C5). Everything else was consistent with CR-3813 or an already recorded deviation: GEXT V-ASSUMED; joint-acceptance half factor; Eq. (82) limp mass; W phase sign; ε_n quadrature residual; Eq. (8) incoherent/reactive omissions; stale `bb_j2_scale`.

### 2.8 End-to-end SPL tests — flowchart `TEST`

| Test | Metric | Tolerance / reference | Class |
|------|--------|----------------------|-------|
| **T1 — tonal** | Interior SPL, H = 1, 2, 3 | Fig. E-16 (mean/range), E-17 (95% CI), E-18 (V-B loss-factor cap) | **No claim.** **18a-r** (η_T = 0.5, 2026-10-20): 81.04, 75.00, 75.29 dB (`phase20_baseline.md`); H1/H2 pass by the NASA route only, H3 fails. Original 18a (η_T = 0.05): 90.2, 79.3, 83.2 kept as "wrong η_T". 18b-r not met at H3 (+9.1 dB); 19i omitted-term probe **not found** |
| **T2 — broadband** | 1/3-octave | Fig. E-9 mean, **1.25–8 kHz**, **±3.5 dB** (only 1.25–2 kHz is available) | **18a-r:** 52.96 (pass), 50.62, 48.66 dB (fail) against 51.0, 46.0, 41.5; original 18a 62.3, 60.3, 58.5 kept as "wrong η_T". `bb_j2_scale` stale; cannot constrain GEXT (see §2.10) |
| **TS — attribution** | If T1/T2 fail | Substitute Fig. E-7 narrowband bands G1/G2/G3 | Diagnostic |

**CR-172428 findings (report when quoting “validated”):**

1. **Scale-model:** unbiased; error σ ≈ **4 dB** (heavily damped trim; exclude extraneous low-frequency datum).  
2. **Flight (low-freq formulation):** bias **+2.6 to +4.3 dB**; σ **2.4–4.1 dB**.  
3. All of the above findings used **+4 dB** on ANOPP free-field (R2-style), not the original +6 dB.

**User guidance from CR-172428 §6.1:** After R2-style exterior, treat prediction as estimate with ~**3.5 dB** one-sigma band for flight comparisons.

### 2.9 Aircraft application metrics — `APP`

A-weighting, band sum → dB(A), SIL. Class: **X-EXTRAP** when driven by CCBlade/F1A.

**dB(A) fixed 2026-10-21 (C5).** Theory audit C2-2 found `overall_dBA` was tones-only while the docstring and `METHODOLOGY.md` §7 said 1/3-octave energy is included. **Fixed:** `overall_dBA` now energy-sums all 1/3-octave bands A-weighted at band centres (tones are already in the bands — no double count); tones-only remains only for spectra without bands. Aircraft example 83.22 → 83.74 dB(A); synthetic smoke 71.38 → 91.36 dB(A) (HF broadband was previously ignored). METHODOLOGY §7 is now true as written. No validation case criterion was affected.

### 2.10 Test-case guide: what each test does, why it exists, how much it proves

Per-case GUI text (titles, explanations, map/block copy) lives in **§2.13** — single source of truth; both the Validation and Validation map tabs parse it (`valInfo` / `mapDetail` / block `what_it_does` / map `what_is`).

**GUI registry (phases 34–35).** Each row below that has a registry ID can be run from the GUI **Validation** tab (and from
`run_validation_case(id)` / scripts). Plots go to `docs/validation_reports/figures/<id>.png` (with error panel since 2026-10-21).
Cases are read-only. Third tab **"Validation map"** (`src/validation_map.jl`): Map 1 cabin chain, Map 2 aircraft source;
clickable case chips; Validation-tab list ordered by map and block. **Greyed (Run disabled):** none (`R996_FIG8` removed
I-20; `E21_E22_NR` runnable since 38a). **In-process runnable:** `CYL2D_C1`, `MRP_D1`, `MRP_RITZ`, `MRP_APPD`, `BLK_P68`,
`F1A_GUTIN`, `T1`, `T2`, `REPRO_18b`, `E12_BLOCK`, `E11_FREEFIELD`, `UT_GRID`, `E14_LOSS`, `GEXT_BOUND`, `BBN_KIN`, `R996_PHASE`,
`E21_E22_NR` (Eq. 18, η_T = 1.0, η_r′ ≤ 0.15; criterion dated 2026-10-21), `T2_EQ19` (printed Eqs. 19–23; T2
criterion unchanged; first run 2026-10-22), `E18_TONES` (Fig. E-18, η_T = 1.0, η_r′ ≤ 0.15; criterion dated
2026-10-21; first run 2026-10-22), `E15_STRUCT_LOSS` (Fig. E-15 η_r′, V-EXP info, no pass mark; first run 2026-10-22).
**CSV replays** (read recorded `f1a_results.csv` / `scale_factors.csv` / `pereira_results.csv` / `bbn_results.csv`; do not
re-run F1A): `R996_FIG12/13A/14`, `R996_LOADS`, `R996_FIG6/7`, `PER_FIG6–9`, `PER_LOADS`, `BBN_CIRC`, `BBN_LEVELS`, `BBN_LONG`.
All case numbers come from CSVs or transcribed constant tables; page images are display-only. Each §2.13 Explanation ends with
Inputs / Equations / Outputs lines (parsed with newlines for both GUI tabs).

**How to read a PASS.** The class says what was compared. **V-UNIT**: the code matches a written equation. **V-CODE**: the code
reproduces a NASA table or NASA program output. **V-EXP**: the result is compared with a measurement. A V-EXP pass is only as strong as
its independence from tuning: if a parameter was set with the target in view, the pass is a *consistency check* and is labeled
**calibrated** (see the parameter register below).

**Importance** means what happens if the test is wrong or missing. *Critical*: an error silently changes every output. *Important*:
an error changes the cabin result in a specific band or mode. *Minor*: reporting or convenience.

| Test (report) | What it does | Why it is there | Importance | What a PASS proves, and the caveats |
|---------------|--------------|-----------------|------------|-------------------------------------|
| **Blocking Eq. (43)** (`BLK_P68`; `blocking_p68.md`) | Evaluates F(γ) at γ = 0–90° against the values in CR-172428 p.68; checks that R2 gives about 4 dB at γ = 0 | Blocking scales every free-field pressure at the fuselage | Critical | The code matches the written equation (V-UNIT). It evaluates F at given angles, so it does not test how γ is computed from the geometry, and it does not show the equation is physically right (CR-172428 says scale-model blocking is 3–4 dB, off-plane reflection dies faster than Eq. 43). R2 range check kept (met 6/6). |
| **Grid geometry, 160 points** (unit test) | Checks the skin-point coordinates against the User Manual Fig. 3 formulas | Every observer position, γ, and joint-acceptance area comes from this grid | Critical | Coordinates match the manual (V-UNIT). Says nothing about the physics at those points. |
| **Grid extension unit checks** (unit test) | Checks falloff at 0/45/90°, phase sign, axis mapping | Code check for GEXT, which fills the grid from one measured line in the e11 path | Minor | Code does what it was written to do (V-ASSUMED). It does not show the cosine falloff is correct. Used only in the e11 path. |
| **Fig. E-11 digitization** (`e11_delta_dig.md`) | Compares two digitizations of the same figure; passes if max difference ≤ 1.0 dB | Input quality gate for the e11 source | Important | Shows the figure was read repeatably, not that the numbers are right. δmax = 1.0 dB sits exactly at the limit. Both readings use the same method. H = 3 values and all phases come from ANOPP Table 8, not from Fig. E-11 (see register). |
| **CYL2D vs Table C-1 and Fig. C-3** (`CYL2D_C1`; `cyl2d_table_c1.md`) | App. C scheme. **2026-10-21 post-hoc re-statement:** frequency *ratios* f_i/f_1 (modes 2–19) within 0.1 % (c0-free; `TABLE_C1_C0 = 341` was back-solved from the table); Φ_G, symmetry, Fig. C-3 modes 0–5 node by node unchanged. Criterion date "2026-10-20 (ratio form 2026-10-21, post-hoc)" | Cabin modes set the resonances and coupling in the tone calculation | Important | Reproduces NASA's table shape (V-CODE), not an experiment. Absolute frequencies at c0 = 341 were partly by construction. Valid only for grids where B_E is non-singular and the spectrum is real (the paper's NY = 10 is one). |
| **MRP vs Table D-1, hybrid** (`MRP_D1`; `mrp_table_d1.md`) | Asserts the production set copies Table D-1 frequencies/masses | Structural modes set the tone response | Important | **Transcription check, verdict `no_verdict` (2026-10-21).** Residual 0 by construction; tests nothing about the Ritz solver. Do not quote as a pass. |
| **T1 / T2 / REPRO_18b** (registry) | Same gates as the T1/T2/18b rows; GUI/scripts call `run_validation_case`. T1 table shows both gate A (mean ± 4 dB) and gate B (envelope + NASA ± 4 dB). `REPRO_18b` runs **18b-r** inputs (Table 8, R1, η_T = 0.5) → 82.73, 75.73, 77.05 dB (was wrongly e11/R2 before 2026-10-21) | One implementation per case (phases 34–35) | Critical / Important | Same caveats as T1/T2/18b; plots show digitized reference vs computed + error panel. REPRO label: post-hoc (η_T = 0.5; result known from 19f). |
| **MRP raw Ritz vs Table D-1** (`MRP_RITZ`; `mrp_ritz_vs_d1.md`) | Matches Ritz frequencies to D-1 within 5% by greedy nearest-frequency assignment; always `no_verdict` | The only real test of the structural-mode solver | Important | **Calibrated regression guard**, not evidence. Live code **26/32** within 5 % (2026-10-21); report still records 30/32 (stale). Three scales (`k_scale`, `edge`, `floor`) were fitted to maximize this same count. Greedy matching is lenient. Not an experimental modal survey. |
| **Pipeline smoke** (`pipeline_smoke.md`) | Runs the synthetic free-field case through the whole chain | Catches crashes and wiring errors | Minor | The chain runs. Proves nothing about accuracy. |
| **T1 tonal** (`t1_tonal.md`) | Runs the e11 free field through blocking, modes, and the Eq. (8) PAIN core; compares interior SPL for H = 1–3 with Fig. E-16 | The only end-to-end test of the cabin model against measurement | Critical | Since 17a **not calibrated**: no parameter of the tone path is fitted to T1, and the test records the outcome instead of asserting it. The gate passes if the result is within 4 dB of the measured mean, *or* inside the measured envelope and within 4 dB of NASA's PAIN prediction. Envelopes are wide (H1 65–97 dB), and the means are visual digitizations (about ±2 dB). Result 90.2, 79.3, 83.2 dB (H1, H2 pass, H3 fails). H1 depends on a trim resonance (τ_t = 15.6 at 200 Hz), and NASA's own PAIN prediction at H1 was 11 dB below the mean. Conditional on the identifications in the trace table (Phase 17 report §1). Regrade in 18a |
| **T2 broadband** (`t2_third_octave.md`) | Compares 1/3-octave SPL at 1.25, 1.6, and 2 kHz with Fig. E-9, ±3.5 dB | The tonal model puts no energy in these bands; the high-frequency path (Eq. 19) fills them | Important | **Fails** (+11, +14, +17 dB). `bb_j2_scale = 0.5` was fitted earlier so these three bands passed and is stale with τ_t of Eq. (A.22) in the path; the absorption curve and the f⁻² slope are assumptions. Only three bands, nothing above 2 kHz. Replaced in 30b |
| **TS attribution** | If T1/T2 fail, substitutes Fig. E-7 bands to locate the error | Diagnostic | Minor | No script I read runs it. |
| **Trim / loss helper tests** (per `METHODOLOGY.md`) | Phase 16: 337 checks of App. A limits (empty stack, limp mass alone, zero thickness, det = 1, Eq. (A.14), passivity), Fig. A-2 knots, Si/Cin reference values, joint acceptances against quadrature, Eq. (77)–(83) limits. The surrogate E-14/E-15 curve tests were removed (13b) | Trim transmission and loss factors set the resonance peak heights | Important | Exact limits and quadrature only; not checked against laboratory material coupons. The NASA comparison is the E-14 script (`run_trim_loss_check.jl`), 7 of 18 bands, criterion not met. Since 17a `Pkg.test()` runs to the end because the T1/T2 test records instead of asserting |
| **Metrics dB(A) / SIL** (unit test) | Checks IEC 61672 A-weighting table values (100 Hz −19.1, 200 Hz −10.9, 1 kHz 0.0, 4 kHz +1.0 dB, ±0.1) and hand-built-spectrum dB(A); `overall_dBA` energy-sums 1/3-octave bands (fixed C5, 2026-10-21) | Reporting | Minor | The arithmetic is right (V-UNIT). Old `lo < dBA < hi` always-true check replaced in the test audit. |
| **F1A smoke** (`ccblade_f1a_smoke.md`) | Compares peak SPL on the ℓ = 1 line with ANOPP Table 8 | Sanity check that loads → pressure gives sensible levels | Minor | Δ ≈ 0 only because of the Table-8 peak calibration; the raw overprediction is about 5, 9, and 14 dB at H1–H3. Table 8 is ANOPP's prediction, not a measurement. Not a validation. |
| **BBN/Wilby phase check** (planned, plan phase 24) | Circumferential phase between microphone pairs (CR-158919 static, CR-159124 taxi) against B × m × Δψ, and relative in-plane levels of microphones 3–6; longitudinal pairs as X-EXTRAP | The first planned experimental check of the source block, run first for phase | Critical for the aircraft path | Kinematic part has no fitted parameters; microphones sit on a reflecting surface (scattering V-ASSUMED); axial pairs need an assumed blade. Criteria fixed in plan phase 23 first. Not yet run. |
| **Report 996 checks** (plan phases 26–27; I-07 re-run 2026-10-21) | CCBlade C_T / C_P; F1A vs Figs. 6, 7, 12–14 with scaled/unscaled loads | Source-block experimental check | Critical | **23c not met** (scaled ±2 dB 5/24; page-12 phase FAIL). Loads post-hoc label. See §2.3.3 — accuracy at listed cases only, not "better than". |
| **Gutin / Hanson cross-check** (optional, phase 27 / 33a) | F1A vs Report Eq. (2) and a Hanson near-field implementation on identical loads | Coding cross-check; needed only for a "better" claim | Optional | **Not run** (2026-10-21 close-out). No "better than" claim. |
| **Pereira forward-flight check** (planned, plan phase 28) | CCBlade T, Q and F1A harmonics 1–2 at 1 m vs measurement | The only planned check at a forward-flight operating point | Important | Far field only; polars generated here (spec in plan phase 28); ±1.7 dB measurement uncertainty. Not yet run. |

#### 2.10.1 Test audit (2026-10-21)

Findings and fixes from the circular / can't-fail review (phase 35). Valid checks left unchanged: blocking p.68, coupling limits, joint acceptance vs quadrature, App. A limits/passivity, Ψ_G limits, independent Eq. (8) re-implementation, Gutin cross-check, E-14, E-11 δ_dig, E-12.

| Check | Finding | Fix | Label |
|-------|---------|-----|-------|
| A1 CYL2D vs Table C-1 | `TABLE_C1_C0 = 341` back-solved from the table; absolute f check partly by construction | Criterion re-stated as frequency ratios f_i/f_1 (modes 2–19) within 0.1 %; Φ_G / symmetry / Fig. C-3 unchanged | post-hoc (ratio form 2026-10-21) |
| A2 MRP hybrid / raw Ritz | Production 32/32 copies D-1; raw Ritz calibrated; live 26/32 vs report 30/32 | `MRP_D1` → transcription, `no_verdict`; `MRP_RITZ` always `no_verdict` (regression guard); record 26/32, do not "fix" | calibrated / no_verdict |
| A3 Can't-fail dBA / polar | `lo < dBA < hi` always true; polar `… \|\| isfinite(clb)` | IEC 61672 table + hand-built-spectrum dB(A); `clb/cl = k_cl = 0.92264` exactly | — |
| A4 REPRO_18b wrong case | Registry ran e11/R2 (= T1: 81.04, 75.00, 75.29) | Runs 18b-r inputs → 82.73, 75.73, 77.05; not met 2/3 | post-hoc (η_T = 0.5; result known from 19f); was V-CODE |
| A5 T1 table | Only residual to mean shown (ok=true at −9 dB) | Shows both gate A and gate B per harmonic; H1/H2 pass by B, H3 fails | criterion unchanged |
| A6 Free gauges | Fig. C-3 eigenvector sign; BBN kinematic rotation-sense from H1 | Kept, documented as free gauges (no physical content) | not calibration |
| A7 Valid checks | — | Unchanged | — |

**Parameter register: values fitted or chosen with a test target in view.** Any result that depends on these is a consistency check,
not an independent validation.

| Parameter | Where | Set against | Effect |
|-----------|-------|-------------|--------|
| `TABLE_C1_C0` 341 m/s | `cyl2d.jl` / `CYL2D_C1` | Back-solved from Table C-1 frequencies | Absolute frequency comparison was by construction; frequency comparison now uses ratios (2026-10-21) |
| `k_scale` 0.61, `edge_factor` 2.2, `floor_scale` 2.4 | `mrp.jl`, `fit_mrp_to_table_d1` | Table D-1 (the MRP test) | Structural mode frequencies |
| `bb_j2_scale` 0.5 | `pain_core.jl` | Fig. E-9 1.25–2 kHz (T2), fitted before 17a; stale since the broadband path uses τ_t | High-frequency broadband level |
| Trim mass law and `TrimPanel` masses (earlier surrogate) | removed in 17a (2026-10-20) | — | no longer in the code; the App. A code of 16a has no fitted parameter |
| Tonal structural loss factor kept near 0.05 (earlier surrogate) | removed in 17a | — | replaced by Eqs. (79)–(83), no fitted parameter |
| Absorption curve α(f) | `trim_loss.jl` (`absorption_coefficient`) | "Educated fit" | Eq. 19 high-frequency path (T2); replaced in 30b |
| Spectrum slope f⁻², Spbl anchor on H = 3 | `pain_core.jl` | V-ASSUMED | Broadband level (T2) |
| H = 3 free field and all phases from ANOPP Table 8 | `freefield_digitized.jl` | Not measured in Fig. E-11 | e11 source for T1 |
| `broadband_clip_dB` 10 | `freefield_digitized.jl` | Clips measured H1/H2 to ANOPP where they exceed it | e11 source for T1 |
| GEXT cosine falloff and geometric delay | `grid_extension.jl` | None fitted; form fixed a priori (attestation, not verifiable from the repository). Unfalsifiable by published data (§2.2.1) | e11 grid for T1/T2 |
| Table-8 peak calibration scales (0.58, 0.36, 0.21) | `propeller_ccblade.jl` | ANOPP Table 8 | Aircraft path levels |
| `pitch_offset_deg` −5°, `thickness_over_chord` | `aircraft_scale_hartzell.json` | Tuned toward Table 8 per its description | Aircraft path levels |
| Polar calibration `k_cl` 0.92264, `k_cd` 1.81815 (bracket polar set, planned) | `propeller_sizing_and_analysis\...\naca_4-5-08-03\analytical\tables.json` | Fitted to forward-flight wind-tunnel data (RM L9G06a), not to Report 996 | Loads in the Report 996 bracket runs |
| Section polar fits (primary set, k = 1, planned) | `analytical\sections.json` from `polars_forced.json` | Fitted to XFOIL output (forced transition x_tr 0.02), not to any measurement | Loads in the Report 996 primary runs |
| Post-stall extension (Viterna: α_stall, c_d,max, aspect ratio) and Re/Mach clamps (values fixed in the Viterna row below, phase 11) | Report 996 and Pereira polars | Rules chosen **before** the comparison; entered here when fixed | Inboard loads (small effect on near-tip pressure, larger on C_T / C_P) |
| Load scaling to measured T and Q (planned) | `ScaledLoads` in the shared source function | Measured thrust/torque, by design (isolates F1A) | F1A runs labelled "scaled"; **V-EXP, calibrated** |
| NACA 4412 XFOIL settings (fixed 2026-10-20, phase 11): N_crit 9 primary, N_crit 5 and forced x_tr 0.05 brackets; 180 panels; ITER 200; Re 2×10⁴–3×10⁵ (8 values); M 0–0.4 (5 values); α −10° to 20° | `data\pereira
aca4412_xfoil_*.json` | Chosen before the comparison (plan phase 11, 28). Stock Windows XFOIL 6.99 | Pereira loads |
| Report 996 polar gap fill (fixed 2026-10-20, phase 11a): forced x_tr 0.02, 240 panels, Re 3×10⁵ and M 0.1 added to the sibling grid, α −6° to 14° | `data
eport996\polars_forced_merged.json` | Chosen before the comparison. Merged grid mixes XFOIL builds (sibling: Linux double precision; new: Windows 6.99) | Report 996 loads |
| Viterna extension (fixed 2026-10-20, phase 11c): CCBlade 1.0.0 `viterna`, 50 points per side, α_stall = α at max converged c_l, c_d,max = max(max c_d, 1.11 + 0.018/cr75), cr75 0.1251 (Report 996) / 0.1558 (Pereira); Re, M clamped to the set's grid range, bilinear in (log Re, M); non-extendable polars replaced by the nearest usable (Re, M) of the same section | `data\polarsiterna_extension.json` | Rules chosen before the comparison. Stall values: Report 996 median α_stall 7.5°, c_l,max 0.94; Pereira N_crit 9 median 15.0°, 1.37. 143 of 300 Report 996 polars end before a true stall | Inboard loads |

**What can be quoted as validation today.** The blocking formula, the grid geometry, and the cabin-mode solver against Table C-1
(ratio form, 2026-10-21) are code-level checks (V-UNIT / V-CODE). T1 and T2 can be quoted only as recorded results of the untuned
chain (18a-r: H1/H2 NASA route only, H3 fails; T2 1 of 3), not as validation; the one stale fitted parameter (`bb_j2_scale`) is
named in the register. The MRP hybrid transcription (`MRP_D1`) and the calibrated raw Ritz guard (`MRP_RITZ`) should not be quoted
as passes. The F1A smoke test is a sanity check. The source block gets an experimental check only after the Report 996 phases
(§2.3.1). Free-field amplitude convention (I-17) is open.

#### Test-article-specific values reachable from the aircraft path (phase 29a audit, 2026-10-21)

Each row is a hard-coded NASA test-article constant that can reach an aircraft run today. Guard/provenance (29b/29c) wait for [CONFIRM].

| File | Symbol / site | Value | Source |
|------|---------------|-------|--------|
| `trim_loss.jl` | `phase3_trim` defaults `a`, `L`, `theta0_deg` | 0.508 m, `test_article_length()` (default 1.83 m), 56.6° | CR-3813 App. E test article; L via `TEST_ARTICLE_L` (I-22 default 1.83 m, 2026-10-22) |
| `trim_loss.jl` | `phase3_trim` η_lining | 0.5 (Phase III); aircraft register default 0.05 | p. E-24 / register f |
| `trim_loss.jl` | PF-105 / Fig. A-2 insulation table | `data/cr3813/fig_a2_pf105.csv` | App. A |
| `trim_loss.jl` | Phase III sidewall/end stacks, septum 6.58 kg, facing 0.095 kg/m² | as coded | App. E p. E-8 |
| `mrp.jl` | `MRP_T_SKIN`, stringer/frame areas and spacings, E, ν, ρ | 0.00081 m, … | App. D / MRP constants |
| `pain_core.jl` | wall mass fallback from `MRP_*` when `m_wall` NaN | smeared skin | same |
| `pain_core.jl` | `bb_j2_scale` default | 0.5 | stale T2 fit |
| `pain_core.jl` | Spbl H=3 anchor, f⁻² slope, absorption curve | as coded | V-ASSUMED / educated |
| `PAIN.jl` | `run_pain_pipeline` geometry defaults | L=`test_article_length()` (default 1.83), a=0.508, θ0=56.6, r_p=0.965 | test article |
| `geometry.jl` | `TEST_ARTICLE_L` / `test_article_length()` | default **1.83 m** (I-22); App. D follows `test_article_length()` | I-22 decision 2026-10-22; re-record `length_rerecord_before_after.md` (from `length_sensitivity.md`; no length selected from any error) |
| `PAIN.jl` | hybrid Table D-1 modes when `use_table_d1=true` | 32 modes | Table D-1 |
| `cyl2d.jl` / pipeline | CYL2D NY=10, c0=340, ρ0=1.225 | defaults | App. C / register |
| `pain_core.jl` / pipeline | `L_c` default = fuse.L, `d` = 0; `rotation_direction` = +1; `bands` / `η_r_band` / `η_n_band` default `nothing` | card 9 / 36 / 3–6 / 11–18 defaults | Manual §5.4; 38f-1, 38f-2 |
| `printed_outputs.jl` (38h) | Manual §5.4.3 tables from existing APIs; lower-quarter pressures not computed (I-18 note); no criterion | report / GUI only | Manual §5.4.3; plan 38h |
| `trim_loss.jl` | end-plate 1.3 cm aluminium mass path | as coded | App. E |
| `pain_core.jl` | η_n_bare default, C_struc default | 0.05, 3.0 | register g |

### 2.11 Cabin pre-registration (plan phase 13; dated 2026-10-20, before any run of phases 14–18)

Written before the first run of the 14a–18a chain. A value here is changed only with the change dated and the affected result relabelled calibrated with the parameter named (rule 3, §2.3.1). None of these values is tuned to T1 or T2. Each range is a sensitivity run recorded and carried into the uncertainty budget (plan phase 31).

#### 2.11.1 Assumption register for 15a–17a (13a)

| ID | Assumption | Default | Range / alternatives | Source | Bounding check |
|----|-----------|---------|----------------------|--------|----------------|
| a | CYL2D node rule: a node is in the cabin when r ≤ 1 + 0.4h | 0.4h | 0.32h–0.47h gives the same paper grid, row counts and modes (run in 15a: 0.31h gives a 4-node second row, 0.48h a 7-node fourth row; both then fail the real-spectrum check) | Inferred from Fig. C-3 | On other grids run both ends of the window; record the change |
| b | App. C on grids other than the paper's: the (C.4) tangential rule can make B_E singular | NY = 10 | Start at NY = 10, increase by 1 until B_E is non-singular and all eigenvalues are real to 1e-3; accept only if the next valid NY changes the first 20 frequencies by ≤ 1 % | Prototype (some θ0, NY combinations singular) | Record NY. No pseudo-inverse |
| c | Sound speed and density | c0 = 341 m/s for the Table C-1 comparison only; pipeline c0 = 340 m/s, ρ0 = 1.225 kg/m³ (input). **38f-1:** optional split `ρ_ext,c_ext,ρ_int,c_int` (Manual card 2); omitted → both sides = ρ0,c0 (bitwise same path) | none | 341 m/s is the speed implied by Table C-1; Manual §5.4 card 2 | — |
| d | Axial truncation of 3-D modes (V-ASSUMED) | q ≤ ⌈2ω_H L/(π c0)⌉ | Accept when q_max + 2 changes ⟨p²⟩ by ≤ 0.1 dB, else raise q_max | CR-3813 does not state it | Convergence in q at H1–H3 (met under Eq. (8), 17a, `q_convergence.md`) |
| e | Insulation data: Fig. A-2 covers 100–6300 Hz and one material (PF-105, 9.6 kg/m³); Phase III default only | Fig. A-2 table | The aircraft trim is the user's table of λ_m, α, φ, \|W\| per frequency (29d). Outside the table range: error unless the user sets extrapolation; then log-log extension of the end segment, tagged X-EXTRAP and carried into the phase 31 band | CR-3813 App. A | — |
| f | Phase III values CR-3813 does not give (V-ASSUMED): facing/septum loss factor | **0.5 for `phase3_trim` (test article; author decision 2026-10-20)**; **0.05 aircraft-case default** (unchanged; range revisited in phase 31) | Aircraft 0.01–0.10. CR-3813 p. E-24: η_T = 0.5 for Fig. E-16/E-17; 0.5 and 1.0 for E-14/E-15. 18b-r (η_T = 0.5): +3.7, +0.2, +9.1 dB (`phase20_baseline.md`); original 18b at 0.05 kept as "not met, wrong η_T" | CR-3813 p. E-24 | Default changed 2026-10-20; 19i (2026-10-21): omitted D-1 terms |δ| ≤ 0.057 **not found** as H3 cause (`h3_followup.md`) |
| f | G-10 wavespeed | 3200 m/s | 2800–3600 m/s | — | Run and report |
| f | Facing side of each layer | Cabin side | Skin side | — | Alternative run and reported |
| f | Mechanical connections | 9 points + 2 floor-edge lines | Points only; lines only | — | Each alternative run and reported |
| g | η_n of a bare cabin (§3.8.1 says measured; an input) | 0.05 | 0.02–0.10. **38f-2:** optional per-band `η_n_band` / `η_r_band` (Manual cards 11–18); 0/absent → compute as before | — | Sensitivity run |
| g | C of Eq. (80) | 3 | 2–4 (CR-3813 range) | CR-3813 | Sensitivity run |
| h | Areas: A in Eqs. (8) and (52); Ā in Eq. (81); A in Eq. (A.19) | A = L(Lp + 2a(π − θ0)); Ā = 2πaL; A = 2a(π − θ0)L | none | Normalization of Eq. (52); full-circumference coordinates of Eqs. (62)–(65); curved sidewall | — |
| i | η_r'' of Eq. (83) | Applied to every (n, r) pair (its own resonance factor limits it) | Variant restricted to \|ω_r − ω_n\| ≤ η_nω_n/2 ("typically", §3.8.2), reported | CR-3813 §3.8.2 | Both reported |
| j | Plate modal density n = A√3/(2πhc) in Eq. (A.19) | as written | none | V-ASSUMED | — |
| k | Table D-1 shapes, all 32 modes, transcribed from the page scans 2026-10-20 (modes 2 and 16 frequencies corrected); Ritz shapes converted to the Eqs. (46)–(49) convention | as transcribed | — | CR-3813 Table D-1 | Comparison in 17d: equal to `data/cr3813/digitized_table_D1.csv` in all 32 modes. 19g: Fig. D-2 mode-1 shell shape within the print-column quantization (0.026 of the figure's peak 1.0, criterion 0.05 met); floor shape 0.057 from the figure at the outer points (criterion 0.05 **not met**, digitization ±0.005; omitted Table D-1 terms are a possible cause, untested) (`fig_d2_check.md`) |

#### 2.11.2 Pass criteria for the loss and trim comparisons (13b)

Fixed 2026-10-20, before any run of 16a–16b. The user confirmed the proposed criteria on this date.

| Comparison | Class | Criterion |
|------------|-------|-----------|
| Computed band-average η_n against NASA's "calculated" curve of Fig. E-14 | V-CODE (same equations as NASA's own calculation) | Within ±25 % per one-third octave |
| ᾱ from Eq. (24) against the calculated curve of Fig. E-13 | V-CODE | Within ±0.05 |
| Computed η_n, η_r, ᾱ against the measured points of Figs. E-13, E-14, E-15 | V-EXP | Recorded, **no pass mark** (NASA's own calculation and measurement differ, e.g. about 10 dB at H1) |
| Existing tests comparing tuned surrogate curves with E-14/E-15 | — | Removed 2026-10-20 (16b landed) |

The E-12 criteria (14a, now run) and the CYL2D criteria (15a) are stated in their own plan rows, dated 2026-10-20 with this section.

#### 2.11.3 Run definition for the 16a–16b comparisons (fixed 2026-10-20, written before the comparison was run)

The statistic and inputs below were fixed before `scripts/run/run_trim_loss_check.jl` was first run; the numbers in 13b above are unchanged.

| Item | Definition |
|------|------------|
| E-14 statistic (V-CODE) | Eq. (78), η̄_n = 8c0/(4ωV)[ξS + 2ξ_eS_e], evaluated at each one-third-octave band centre 100–5000 Hz (18 bands), with ξ = Re β and ξ_e = Re β_e from Eq. (A.16) |
| E-14 inputs | Phase III stacks of App. E p. E-8 (`phase3_trim`): sidewall = four layers (1.3 cm PF-105 + 0.095 kg/m² facing each, facing on the cabin side) + septum 6.58 kg over 2a(π − θ0)L; end plates = one layer + facing on a rigid backing; wall mass m = 3.23 kg/m² (smeared skin, `MRP_*` constants); S = 2a(π − θ0)L, S_e = V/L, V = `cabin_volume`; c0 = 340 m/s, ρ0 = 1.225 kg/m³. Facing and septum loss factor 0.5 and 1.0, the two values NASA used for its curves (not the register default 0.05, which is for the aircraft case) |
| E-14 target | `data/cr3813/e14_acoustic_loss_calculated.csv`, digitized from the two calculated curves |
| E-14 pass rule | Each band: \|η̄_computed/η̄_NASA − 1\| ≤ 0.25. Reported: bands passing of 18, per trim loss factor. A miss is recorded, not tuned |
| Eq. (77) mode averages | Diagnostic, recorded without a pass mark: mean of η_n over the cabin modes whose frequency falls in the band |
| E-13 | Fig. E-13 holds **measured** points only (no calculated curve), so the ±0.05 criterion of 13b has no target. ᾱ from Eq. (24) is compared with the measured points as V-EXP, no pass mark. Recorded 2026-10-20 |
| Fig. A-2 / App. A | τ_t, C_w, β are checked by the exact limits of 16a (empty stack, limp mass alone, zero thickness, det = 1, passivity Re β ≥ 0); no NASA numbers exist for them |

**Result and status (16a–16b done 2026-10-20).** E-14 (V-CODE): 7 of 18 bands within ±25 % at trim loss 0.5 and 7 of 18 at 1.0; the criterion is not met (`trim_loss_e13_e14_e15.md`; per-band table and the failing bands in the plan, phase 16). Register items e (Fig. A-2 as `data/cr3813/fig_a2_pf105.csv`, range error and flagged extrapolation), f (`phase3_trim` keywords), g (`C` of Eq. 80, bare η_n is an input to 17a) and j (plate modal density in `MechanicalPath`) are implemented. Added V-ASSUMED items: end plates on a rigid backing (mass not stated in CR-3813; it sets ξ_e and so the E-14 result above 600 Hz), wave-impedance phase sign W = |W|e^{+iφ} (checked by Re β ≥ 0), and Fig. A-2 read at six frequencies (|W| at 1000 Hz from the curve, not the marker). The sensitivity runs of the register ranges were made with the Eq. (8) chain on 2026-10-20 (`scripts/checks/probe_t1_levels.jl`, table in `validation_reports/pain_core_eq8_phase17.md` §5): η_n 0.02–0.10 moves H2, H3 by up to 4.5 and 6.7 dB, C 2–4 by ≤ 0.1 dB, lining loss 0.01–0.10 by up to 2.4 dB (H1) and 5.1 dB (H3), the facing side by 2.5 dB at H1; no range brings H3 within 13 dB of the measured mean. Item d (q truncation) is met under Eq. (8). Printed-equation findings carried to 17a: Eqs. (69), (70), (63) are half the mode-normalized joint acceptance for n > 0 (`mode_normalized` option, default as printed); the Eq. (82) limp-mass limit.

#### 2.11.4 Criterion for the PAIN reproduction check (18b; dated 2026-10-20, written before the run)

| Item | Definition |
|------|------------|
| Purpose | Show the chain computes what NASA's PAIN computes (V-CODE), separately from agreement with measurement (18a) |
| Inputs | ANOPP Table 8 free field (`data/cr3813/anopp_table8_spl_dB.csv`, `anopp_table8_phases_deg.csv`) in place of the measured Fig. E-11 line; full Eq. (43) blocking, variant R1; Phase III trim stacks (`phase3_trim`, register defaults); 20 CYL2D modes, 32 Table D-1 modes, q ≤ ⌈2ω_H L/(π c0)⌉; BPF 200 Hz. Off-line grid points by GEXT on Table 8 (17j found no full-grid ANOPP output), so the result is conditional on GEXT (V-ASSUMED, phase 32) |
| Target | `nasa_pain_pred_dB` of `data/cr3813/t1_interior_targets.csv` (NASA PAIN circles of Fig. E-16): 79.0, 75.5, 68.0 dB at H1–H3 |
| Criterion | \|computed − target\| ≤ 2 dB (Fig. E-16 digitization uncertainty) + 2 dB = **4 dB at each harmonic** |
| A miss | A finding on the chain, localized with 17c–17i; not a reason to tune |
| Result (run 2026-10-20) | **Not met, 0 of 3.** R1, Phase III trim: 91.92, 80.01, 84.87 dB, i.e. +12.9, +4.5, +16.9 dB against 79.0, 75.5, 68.0. Diagnostics (not the criterion): R2 90.06, 78.20 (within 4 dB), 83.15; bare cabin 92.22, 83.65, 83.58. At H1 modes 8 (318.7 Hz) and 6 (301.9 Hz) carry 91 % of the sum with τ_t = 15.6. `pain_reproduction_e16.md`, `scripts/checks/probe_modal_contributions.jl`. **Phase 19 (2026-10-20) isolated the largest cause: the registered run used the facing/septum loss factor η_T = 0.05, NASA's text gives η_T = 0.5 for these predictions (p. E-24).** Swapping only that input (whole trim rebuilt): 82.73, 75.73, 77.05 dB, i.e. +3.7, +0.2, +9.1 dB, H1 and H2 within 4 dB, H3 not (η_T = 1.0: +0.3, −0.7, +6.7). Not adopted and not a re-registered pass: the registered result stays "not met". Ruled out as the cause (each swap moves a harmonic by < 3 dB toward NASA, or in the wrong direction): the Eq. (8) algebra and (mA/4)²τ_ML (19a–19b), ε_n for q > 0 (19c: read as printed), mirroring (19d: 160 points, no mirroring), the W phase sign, facing side or septum (19e), the E-14 η_n and E-15 η_r (19f), the unbarred f′ of Eq. (83), Fig. D-2 and Eqs. (D.22)–(D.26) (19g: not on the production path), the η_r normalization (19h, as printed). Open: H3 at +9.1 dB (+6.7 at η_T = 1.0). Reports: `bisect_18b.md`, `tau_t_variants.md`, `eps_n_quadrature.md`, `grid_mirroring.md`, `fig_d2_check.md`, `eta_r_normalization.md` |

#### 2.11.5 Criteria for the input-corrected re-runs 18b-r and 18a-r (dated 2026-10-20, written before the runs)

Decision of the author (2026-10-20): the Phase III trim loss factor of the test article is η_T = 0.5, the value CR-3813 p. E-24 ties to the Fig. E-16/E-17 predictions (1.0 belongs to the E-14/E-15 curves and is not used, because choosing it for the closer fit would be tuning). `phase3_trim` defaults to 0.5; the aircraft register default 0.05 is unchanged and its range 0.01–0.10 is revisited in phase 31 before any aircraft run. The frozen baselines were renewed on the same date (`data/baselines/phase17_baselines.csv`; the 0.05 file is kept as `phase17_baselines_etaT0p05_archive.csv`).

| Item | Definition |
|------|------------|
| Name and honesty label | **18b-r: input correction, result known from 19f** (`bisect_18b.md` gave +3.7, +0.2, +9.1 dB for this input), so it is not a blind test. The original 18b stays in the record as **"not met, wrong η_T (0.05)"** and is re-run by the same script with η_T = 0.05 for the record |
| Inputs | As 18b (§2.11.4) with η_T = 0.5 |
| Criterion | Unchanged: \|computed − target\| ≤ **4 dB at each harmonic** against 79.0, 75.5, 68.0 dB. Reported per harmonic with its margin to the 4 dB limit; a harmonic inside the limit by less than 1 dB is reported as "within the criterion, margin x dB", never as a clean reproduction |
| 18a-r | T1 and T2 re-run with η_T = 0.5 against the criteria of 18a, unchanged: T1 mean ± 4 dB, or inside the measured envelope and within 4 dB of NASA's PAIN (§2.8); T2 within ±3.5 dB of Fig. E-9, 1.25–2 kHz. Same label (input correction, result partly known from 19f). The original 18a numbers stay in the record as "wrong η_T (0.05)" |
| Claims | T1 at H3 stays **no claim** and +9.1 dB is recorded as an open finding. T1 as a whole stays no claim: H1 and H2 within 4 dB of NASA's code do not make the chain a validation. The 19h shell-shape normalization is not adopted (not printed in CR-3813) |
| A miss | Recorded, not tuned. H3 followed by 19i (criteria fixed 2026-10-20 before the run) |
| **19i result (2026-10-21)** | Base = 18b-r (82.73, 75.73, 77.05 dB). Part A H3 top modes 15 (29.8 %), 25 (22.6 %), 17 (21.4 %), 21 (8.1 %). Part B: every ±0.057 plate/shell omitted term on those four modes shifts H3 by ≤ 0.16 dB; **not found** as the cause of the H3 miss. Not adopted. Report `h3_followup.md`. Phase 33 carries H3 as a stated limitation |
| **GUI / registry `REPRO_18b` (fixed 2026-10-21)** | Before phase 35 the registry/GUI case ran `source=:e11, blocking=R2` (= T1: 81.04, 75.00, 75.29 dB). It now runs the registered 18b-r inputs (ANOPP Table 8 free field via GEXT, R1, Phase III trim with η_T = 0.5): **82.73, 75.73, 77.05 dB** = `pain_reproduction_e16.md`; verdict not met (2/3, H3 +9.1 dB). Label **"post-hoc (η_T = 0.5 input correction; result known from 19f)"**, matching this section (was wrongly labelled V-CODE). |

### 2.12 Source pre-registration (phase 23) — **frozen 2026-10-21** (author approval, plan §3.0a / I-06)

Written before any BBN / Report 996 / Pereira comparison run that uses these tolerances for a verdict. Values below are the I-06 freeze (author 2026-10-21). Phase 26 loads were computed before this freeze and are labelled "criteria registered after the loads were computed" whatever the outcome. Re-runs of 24, 27 and 28 after I-01/I-02 use these criteria as pre-registered.

#### 23a BBN circumferential phase (phase 24c)

| Column | Frozen |
|--------|--------|
| ID | 23a |
| data | D-02, D-03, D-04, D-06, D-21 |
| cases | pairs 4-3, 5-3, 4-5 (5-6 reported, flagged); harmonics 1–7; static CR-158919 + taxi 40/55/70 kt CR-159124 |
| quantity | wrap(Δφ_meas − Δφ_F1A) to ±180°; trace-velocity ratio v_tr / (Ω r_hub) |
| statistic | per pair × harmonic residual; coherence &lt; 0.15 low confidence, &lt; 0.05 dropped |
| tolerance | \|residual\| ≤ 15° at H1–2, ≤ 35° at H3–7; trace-velocity ratio within ±0.10 of the measured ratio |
| pass rule | pass if ≥ 80 % of rows with coherence ≥ 0.15 (pairs 4-3, 5-3, 4-5; 5-6 reported only) are within tolerance |
| label if met | V-EXP (circumferential phase, no fitted parameters) |
| label if not met | recorded finding; not tuned |
| date | **frozen 2026-10-21** |

#### 23a′ V-UNIT kinematic (phase 24b)

| Column | Frozen |
|--------|--------|
| ID | 23a′ |
| quantity | Δφ = m·B·Δψ wrapped, hub-centred ring, static |
| tolerance | 0.5° |
| pass rule | all listed separations (13.3°, 11.8°, 10.4°), H1–7; reverse rotation flips sign |
| date | **frozen 2026-10-21** |

#### 23b BBN in-plane levels (phase 24d)

| Column | Frozen |
|--------|--------|
| ID | 23b |
| quantity | relative level of mics 3–6 vs mic 4 (dB) |
| statistic | Δ(SPL_i − SPL_4)_meas − Δ(SPL_i − SPL_4)_F1A |
| tolerance | ±3 dB on (SPL_i − SPL_4) |
| label | reported X-EXTRAP (assumed blade) |
| date | **frozen 2026-10-21** |

#### 23c Report 996 (phases 26–27)

| Column | Frozen |
|--------|--------|
| ID | 23c |
| evidence | Fig. 7 legend C_P vs RM L8H25a −5%/+11%; Fig. 14 vs L8H25a +5%/+15%; Fig. 12 vs 14 ≤ 6%; dig ≈ 0.5% |
| tolerance C_T, C_P | within ±15 % (largest source-to-source spread, Fig. 14 table vs RM L8H25a) |
| tolerance pressure | scaled-load pressure per harmonic and total rms within ±2 dB at ≥ 75 % of in-scope points; unscaled runs informational |
| page-12 phase | within ±15° |
| date | **frozen 2026-10-21** |
| note on 26 | "criteria registered after the loads were computed" |

#### 23d Pereira (phase 28)

| Column | Frozen |
|--------|--------|
| ID | 23d |
| quantity | harmonics 1–2 SPL at 1 m; ψ₁(φ) − ψ₁(0°) |
| tolerance H1 | ±1.7 dB |
| tolerance H2 | ±3 dB |
| phase Δψ₁ | ψ₁(φ) − ψ₁(0°) within ±5° |
| exclusion | a clipped or missing reference cell is excluded, not filled |
| date | **frozen 2026-10-21** |

#### 23e Held-out reservation

| Column | Frozen |
|--------|--------|
| ID | 23e |
| decision | held out of any calibration: E-17, E-10, E-21, E-22 (all) |
| date | **frozen 2026-10-21** |

#### 23f Freeze

**Frozen 2026-10-21** at the I-06 values above (author approval, plan §3.0a). Any change after a comparison run that uses these tolerances makes that result calibrated with the changed parameter named.

**I-07 comparison runs (2026-10-21), using the freeze above (not changing it):**
- **23a′ / 24b:** PASS (`Pkg.test()`).
- **23a / 24c:** FAIL — 26/168 rows (15%) within tolerance (`bbn_phase.md`); registry replay `BBN_CIRC` not met 26/168 (= recorded).
- **23b / 24d:** reported X-EXTRAP in `bbn_phase.md`; `BBN_LEVELS` no verdict (20/32 within ±3 dB, X-EXTRAP).
- **23c / 27:** FAIL — scaled Fig.14 sample 5/24 within ±2 dB; page-12 |Δφ−155°|=51.2° (`report996_acoustics.md`; I-08 L51C27 on Fig.13a). **Registry replays (phase 35):** `R996_FIG14` not met 5/24 (= recorded); `R996_FIG13A` not met 6/14 (= recorded); `R996_FIG12` not met **19/40** (first verdict under the frozen 23c rule; no count was recorded before); `R996_PHASE` reads 155°/165° from `tr996_phase_values.csv` and F1A 103.8° from `f1a_results.csv`.
- **23d / 28:** FAIL on H1 (0/9 within ±1.7 dB vs Fig.9 Exp at 80 dB as read); H2 6/9 within ±3 dB (`pereira_forward_flight.md`). Replays: `PER_FIG9` not met (H1 0/9, H2 6/9); `PER_FIG8` not met (H1 1/7, H2 6/7); `PER_FIG7` not met (Δψ₁ 2/3 within ±5°); `PER_FIG6` / `PER_LOADS` no verdict (no frozen criterion).
- Phase **26** loads keep the post-hoc label "criteria registered after the loads were computed"; registry `R996_LOADS` 6/32 within ±15 % (not met; same post-hoc label).

---


## 2.13 Validation case reference (read by the GUI)

Machine-readable case/map/block text for the Validation and Validation-map tabs. Format: `### Map: id` / `#### Block: id` / `### Case: id` with bold `**Field:**` lines; the GUI parser in `src/validation_map.jl` depends on this layout. Both the Validation tab and the Validation map tab read these fields (`valInfo` / `mapDetail` / block `what_it_does` / map `what_is` / `how_to_read`). Abbreviations used below: ANOPP = NASA Aircraft NOise Prediction Program (free-field source tables); GEXT = assumed grid extension from one measured line to 160 skin points; T1 / T2 = tonal / 1/3-octave interior checks vs App. E; R1 / R2 = blocking Eq. (43) revisions; γ = incidence angle; ℓ = 1 = propeller-azimuth grid line; H1–H3 = blade-passage harmonics 1–3; BPF = blade-passage frequency; η_T = trim loss factor; F1A = Farassat formulation 1A.

### Map: pain
**Title:** PAIN verification — CR-3813 cabin chain
**What this map is:** Checks that the cabin chain computes what CR-3813 writes (V-UNIT: code = printed equation; V-CODE: code = NASA table or NASA PAIN output), then compares the end result with NASA's test-article measurements (in-sample, no claim). A pass here shows the equations are implemented as written; it does not show they are physically right, and none of it covers the aircraft source. Order follows the pipeline: free-field input → skin grid → blocking → structure → cabin acoustics → trim/loss → coupling → code-on-code interior → measured interior.
**How to read it:** Blocks are pipeline stages in order from top to bottom. Chips are checks of that stage. Border colour is the kind of evidence (verification / experiment / calibrated / input QA / X-EXTRAP / deferred). The coloured dot is the last run verdict in this GUI session (green = met, red = not_met, grey = no_verdict, empty ring = not run). Kind tags: runnable = live code; replay = recorded script CSV re-plotted, not re-run; pkgtest = covered by Pkg.test; deferred = not built. The detail panel's error plot is green inside the criterion and red outside. "Replay" means the recorded script output is re-plotted, not re-computed. Each Explanation ends with Inputs / Equations / Outputs lines.

#### Block: P_FF
**Title:** Free field on the fuselage (test article)
**What this stage does:** First stage: the exterior free-field sound-pressure level (SPL) that drives every App. E cabin run. Fig. E-11 is NASA's measured line along grid line ℓ = 1 with the fuselage absent; harmonic 3 (H3) and all phases come from ANOPP Table 8, not from the figure. Code: `freefield_digitized.jl`.
**Code:** freefield_digitized.jl
**Note:** Fig. E-11 measured line; H3 and all phases from ANOPP Table 8

#### Block: P_GRID
**Title:** 160-point grid and extension (GEXT)
**What this stage does:** Builds the 160 fuselage-skin observers (User Manual Fig. 3) and, on the e11 path only, fills 150 of them from the one measured line by an assumed amplitude falloff and geometric delay (GEXT). Comes after free-field input because every later pressure lives on this grid. Code: `geometry.jl`, `grid_extension.jl`.
**Code:** geometry.jl, grid_extension.jl

#### Block: P_BLK
**Title:** Blocking, Eq. (43)
**What this stage does:** Scales free-field amplitude at each skin point by Magliozzi's empirical factor F(γ) so a rigid fuselage "blocks" (reflects) the wave; phases unchanged. Comes after the grid because γ is computed from hub-to-skin geometry. Code: `blocking.jl`.
**Code:** blocking.jl

#### Block: P_MRP
**Title:** Structural modes (Table D-1 / Ritz / App. D)
**What this stage does:** Fuselage structural modal frequencies and shapes that enter the coupling. Production uses the Table D-1 seed; a calibrated Ritz surrogate and the printed App. D solver are checked beside it. Comes before cabin acoustics and coupling. Code: `mrp.jl`, `mrp_appd.jl`.
**Code:** mrp.jl, mrp_appd.jl

#### Block: P_CYL
**Title:** Cabin acoustic modes (App. C)
**What this stage does:** Two-dimensional cabin acoustic modes (frequencies, generalized mass, shapes) from Appendix C. Needed with the structural modes before the Eq. (8) coupling sum. Code: `cyl2d.jl`.
**Code:** cyl2d.jl

#### Block: P_TRIM
**Title:** Trim (App. A) and loss factors (§3.8)
**What this stage does:** Sidewall/end trim transfer matrices and structural/acoustic loss factors that set every modal amplitude. Comes after modes and before the tone/broadband sums. Code: `trim_loss.jl`.
**Code:** trim_loss.jl

#### Block: P_EQ8
**Title:** Coupling f′, Ψ_G, Eq. (8) tone sum + HF Eqs. (15)–(16)
**What this stage does:** Generalized force, joint acceptance Ψ_G, and the tonal mean-square pressure sum Eq. (8) in `pain_core.jl`; high-frequency expected-value Eqs. (11)–(16) and crossover card 10 in `high_freq_tones.jl` (38b). Default `tone_model=:eq8`; `:auto` switches at the crossover band. Last equation stage before interior SPL checks.
**Code:** pain_core.jl, high_freq_tones.jl

#### Block: P_REPRO
**Title:** Interior SPL vs NASA's PAIN program
**What this stage does:** Code-on-code: run this cabin chain on the same free-field/blocking/trim settings NASA used and compare interior tonal SPL with NASA's PAIN circles (Fig. E-16 / E-18). Comes after the equation stages so a miss can be blamed on the chain, not on a missing mode.

#### Block: P_MEAS
**Title:** Interior SPL vs test-article measurement
**What this stage does:** End-to-end checks against measured cabin levels and noise reduction (T1, T2, E-21/E-22). Last on the map because they inherit every upstream assumption (especially GEXT); several are calibrated or not claimable.

### Map: aircraft
**Title:** Aircraft source validation — CCBlade BEMT + F1A
**What this map is:** Checks the aircraft free-field source (CCBlade blade-element momentum theory loads → AcousticAnalogies Farassat F1A pressure) against experiments it was not tuned to. Report 996 covers static near-field amplitude, BBN covers phase between points on a fuselage, Pereira covers forward flight in the far field. None covers a full aircraft cabin, so the aircraft cabin result stays X-EXTRAP. Criteria frozen 2026-10-21 (VALIDATION_GUIDELINE §2.12). Order: geometry → loads → amplitude → phase → forward flight → surface levels → cabin hand-off.
**How to read it:** Blocks are pipeline stages in order from top to bottom. Chips are checks of that stage. Border colour is the kind of evidence (verification / experiment / calibrated / input QA / X-EXTRAP / deferred). The coloured dot is the last run verdict in this GUI session (green = met, red = not_met, grey = no_verdict, empty ring = not run). Kind tags: runnable = live code; replay = recorded script CSV re-plotted, not re-run; pkgtest = covered by Pkg.test; deferred = not built. The detail panel's error plot is green inside the criterion and red outside. "Replay" means the recorded script output is re-plotted, not re-computed. Each Explanation ends with Inputs / Equations / Outputs lines.

#### Block: A_GEO
**Title:** Blade geometry and polars
**What this stage does:** Loads airfoil lift/drag tables and aircraft JSON geometry that CCBlade needs before any thrust or noise. First aircraft stage. Code: `polars.jl`, aircraft JSON.
**Code:** polars.jl, aircraft JSON

#### Block: A_LOADS
**Title:** CCBlade BEMT loads (T, Q)
**What this stage does:** Blade-element momentum theory thrust T and torque Q (coefficients C_T, C_P). Load error swamps acoustic error, so this sits before F1A amplitude checks. Code: `propeller_ccblade.jl`.
**Code:** propeller_ccblade.jl

#### Block: A_AMP
**Title:** F1A amplitude, static near field
**What this stage does:** Farassat F1A harmonic amplitudes in the static near field (Report 996 figures) plus a far-field Gutin coding check. Comes after loads because several cases scale loads to measured T, Q. Code: `propeller_ccblade.jl` (F1A).
**Code:** propeller_ccblade.jl (F1A)

#### Block: A_PHASE
**Title:** F1A phase between points
**What this stage does:** Phase differences between observers (kinematic hub-ring unit test, BBN circumferential/longitudinal, Report 996 one-point phase). Phase enters cabin coupling Ψ_G; checked after amplitude wiring.

#### Block: A_FWD
**Title:** F1A forward flight, far field
**What this stage does:** Pereira et al. 2026 forward-flight spectra, waveform phase, and directivity at 1 m — the only forward-flight experiment set. Comes after static amplitude/phase.

#### Block: A_SURF
**Title:** Levels on a fuselage surface
**What this stage does:** Relative in-plane levels on a fuselage-like microphone ring (BBN Tables 3–4). Surface shape check before any cabin claim.

#### Block: A_CABIN
**Title:** → PAIN cabin chain (Map 1)
**What this stage does:** Hand-off: aircraft free-field on the 160-point grid feeds Map 1. Aircraft cabin SPL stays X-EXTRAP — no aircraft interior measurement is used.
**Note:** Aircraft cabin SPL is X-EXTRAP: no aircraft interior measurement is used

### Case: E11_FREEFIELD
**Title:** Fig. E-11 free-field line
**Map / block:** pain / P_FF
**Category:** input_qa
**Kind:** runnable
**Source:** CR-3813 Fig. E-11, App. E p. E-19 / PDF p.135
**What it tests:** Whether two independent digitizations of NASA's free-field microphone line agree within 1 dB (input quality only).
**Why it is here:** That measured line (with ANOPP Table 8 for H3 and phases) drives every e11 cabin run.
**A pass means:** The figure was read repeatably (digitization scatter δ_dig ≤ 1.0 dB). It does not mean the levels are physically right.
**Not covered:** Physical accuracy of the free-field levels; H3 and all phases come from ANOPP Table 8, not from Fig. E-11.
**Recorded outcome:** met, δmax = 1.0 dB at the limit (e11_delta_dig.md)
**Explanation:** Input QA: Fig. E-11 is sound-pressure level (SPL, dB re 20 µPa) of harmonics H1–H3 measured by NASA with microphones at free-field positions around the model propeller with the fuselage absent, along grid line ℓ = 1 (Fig. E-4), plotted against distance from the propeller plane X/D (forward positive, aft negative). NASA also plotted its ANOPP prediction. This case checks only that two independent digitizations (passes A and B) of that figure agree within 1 dB — not that the levels match physics or ANOPP. Axes: X3/D vs SPL; curves are pass A, pass B, and their mean (the input).
Inputs: Digitized CSVs from `default_e11_paths()` (`e11_freefield_measured_A.csv`, `e11_freefield_measured_B.csv`); geometry for X3/D via `grid_points` on ℓ = 1 (L = test_article_length() = 1.83 m, a = 0.508 m, φ_p = 90°, r_p = 0.965 m, z_p = 0.90 m); D = 0.762 m.
Equations: none (digitization comparison only); helper `delta_dig_dB`.
Outputs: δ_dig [dB] per harmonic and station; verdict uses max δ_dig ≤ 1.0 dB.

### Case: UT_GRID
**Title:** Skin grid vs User Manual Fig. 3 (with figure)
**Map / block:** pain / P_GRID
**Category:** verification
**Kind:** runnable
**Source:** User Manual Fig. 3
**What it tests:** That the 160 fuselage-skin grid points match the User Manual Fig. 3 coordinate and azimuth formulas, with a γ-coloured plot.
**Why it is here:** Every observer, incidence angle γ, and panel area comes from this grid.
**A pass means:** Sampled coordinates and azimuth agree with Fig. 3 formulas within 1e-9 (unit test with visualization).
**Not covered:** Acoustics at the points; GEXT; how γ enters blocking physics.
**Recorded outcome:** runnable unit test with figure (`docs/validation_reports/figures/UT_GRID.png`); Pkg.test "Grid geometry" / "Grid azimuth" remain.
**Explanation:** Unit test with visualization: the PAIN/ANOPP skin grid is 16 axial stations (k) × 10 azimuth lines (ℓ) = 160 points on the unrolled cylinder. Line ℓ = 1 sits at the propeller azimuth φ_p; α = (ℓ−1)·10° is the unsigned angle from that line. Incidence angle γ is the angle between the surface→hub direction and the outward normal (γ = 0 head-on). Figure: axial z vs α, points coloured by γ, with the propeller plane z = z_p and ℓ = 1 marked. Table: Manual Fig. 3 x1, x2, x3, θ at a handful of (k, ℓ). No acoustics.
Inputs: `FuselageGeometry(L=1.83 m, a=0.508 m, θ0=56.6°)`, `PropellerPlacement(r_p=0.965 m, φ_p=90°, z_p=0.90 m)`, `GridSpec()` (k_max=16, ell_max=10, k_p=8) — same family as the e11 path / Manual §5.2.
Equations: User Manual Fig. 3 / §3: x1=(r_p−a)+a(1−cos α), x2=−a sin α, x3=(π a/18)(k_p−k), θ=φ_p+α; γ via `incidence_angle_deg` (CR-3813 §3.4). Code: `grid_points`, `incidence_angle_deg`.
Outputs: x1,x2,x3 [m], θ [deg] vs formulas; figure γ [deg]; verdict on coordinate/azimuth residuals ≤ 1e-9.

### Case: GEXT_BOUND
**Title:** Grid-extension (GEXT) importance bound on T1
**Map / block:** pain / P_GRID
**Category:** calibrated
**Kind:** runnable
**Source:** derived (VALIDATION_GUIDELINE §2.2.1)
**What it tests:** How much the tonal interior check T1 moves when assumed GEXT falloff/delay options change.
**Why it is here:** GEXT fills 150 of 160 points from one measured line; no published data constrain that assumption.
**A pass means:** None — diagnostic with verdict always no_verdict; shows T1 is not claimable when variants flip its gate.
**Not covered:** Cannot validate GEXT (unfalsifiable by published data); amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** no_verdict (diagnostic); variants flip T1 → T1 not claimable (gext_importance_bound.md; amplitude convention fixed 2026-10-21, post-hoc)
**Explanation:** Diagnostic (no pass mark): grid extension (GEXT) copies the measured ℓ = 1 free-field amplitudes onto the other azimuth lines with an assumed cosine-style amplitude falloff and a geometric travel-time phase delay — not a measured distribution. T1 is the end-to-end tonal interior SPL check vs Fig. E-16/E-17. This case re-runs the e11 cabin chain under GEXT option variants and plots how far each harmonic residual to the measured mean moves; when variants flip T1's gate, T1 cannot be claimed. Amplitude convention fixed 2026-10-21 (I-17), post-hoc.
Inputs: `default_e11_paths()` free-field/phase CSVs; `extend_line_to_grid` options `falloff_exponent`, `falloff_floor`, `delay_scale`; cabin via e11 pipe (L = test_article_length(), a = 0.508 m, blocking R2, BPF = 200 Hz); T1 means from `t1_interior_targets.csv`.
Equations: assumed GEXT falloff/delay in `extend_line_to_grid` (V-ASSUMED); cabin chain same as T1 (`run_pain_pipeline` path).
Outputs: T1 residual [dB] per harmonic H1–H3 per variant; verdict always `:no_verdict`.

### Case: BLK_P68
**Title:** Blocking Eq. (43) vs printed p.68 values
**Map / block:** pain / P_BLK
**Category:** verification
**Kind:** runnable
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
**Map / block:** pain / P_BLK
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Fig. E-12, p.136
**What it tests:** Eq. (43) R1 applied to ANOPP Table 8 vs NASA's predicted blocked curve on ℓ = 1.
**Why it is here:** Checks blocking on the measured line before GEXT enters.
**A pass means:** Reproduces NASA's prediction within δ_dig + 0.5 = 3.41 dB.
**Not covered:** GEXT; measured circles on the figure are 1–7 dB lower (no pass mark).
**Recorded outcome:** 29/31, two H3 aft points FAIL (e12_blocking.md)
**Explanation:** Experiment comparison on the prediction curve (V-CODE vs NASA's predicted E-12): "blocked pressure" is the pressure on a rigid cylinder (Fig. E-12). Free-field ANOPP Table 8 SPLs on ℓ = 1 are raised by R1 ΔL(γ) and compared with the digitized NASA predicted curve. Axes: X3/D vs blocked SPL; panels H1–H3. Measured circles are shown for context only.
Inputs: ANOPP Table 8 CSV; `e12_predicted_A/B.csv`; geometry as E11 (a = 0.508 m, r_p = 0.965 m, φ_p = 90°, z_p = 0.90 m, L = 1.83 m); blocking R1; D = 0.762 m.
Equations: Eq. (43) via `delta_L_blocking_dB`; γ via `incidence_angle_deg`; blocked SPL = free-field SPL + ΔL.
Outputs: blocked SPL [dB] H1–H3; verdict |Δ| ≤ 3.41 dB vs digitized NASA prediction.

### Case: MRP_D1
**Title:** MRP Table D-1 seed
**Map / block:** pain / P_MRP
**Category:** input_qa
**Kind:** runnable
**Source:** CR-3813 Table D-1, p.113
**What it tests:** That production structural modes load Table D-1 frequencies exactly (transcription).
**Why it is here:** Production structural modes come from Table D-1, not from the raw Ritz solve.
**A pass means:** Residual 0 by construction — transcription only; verdict always no_verdict.
**Not covered:** Says nothing about the Ritz or App. D solvers.
**Recorded outcome:** by construction, no verdict
**Explanation:** Input QA: production `structural_modes_from_table_d1` copies CR-3813 Table D-1 frequencies and modal masses. Residual is 0 by construction. Always `:no_verdict`. See MRP_RITZ / MRP_APPD for solvers.
Inputs: Constant table `TABLE_D1_FULL` (n_keep = 32); L does not change the seed frequencies.
Equations: none (table load); code `structural_modes_from_table_d1`.
Outputs: mode frequencies f [Hz] equal to Table D-1; verdict `:no_verdict`.

### Case: MRP_RITZ
**Title:** MRP raw Ritz vs Table D-1
**Map / block:** pain / P_MRP
**Category:** calibrated
**Kind:** runnable
**Source:** CR-3813 Table D-1
**What it tests:** Fit quality of the simplified (w-only) Ritz structural surrogate against Table D-1.
**Why it is here:** The only check of the fitted structural surrogate (not Eq. D.25).
**A pass means:** None — calibrated fit (k_scale, edge_factor, floor_scale fitted to this table); always no_verdict.
**Not covered:** Not evidence; Eq. (D.25) not implemented in this path (w-only surrogate).
**Recorded outcome:** 29/32 within 5 % at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; was 26/32 at 1.803 m); always no_verdict (calibrated surrogate)
**Explanation:** Diagnostic / calibrated: raw `structural_modes` uses three scales fitted to Table D-1, not the printed App. D operator. Live count is reported; CLAUDE.md forbids quoting a calibrated path as a pass. Production uses Table D-1 (MRP_D1).
Inputs: `FuselageGeometry(test_article_length(), 0.508, 56.6)`; hybrid=false; n_keep=48; tol_frac=0.05; scales already in code (not re-fit here).
Equations: simplified Donnell/Ritz surrogate in `mrp.jl` (not Eq. D.25).
Outputs: f [Hz] vs Table D-1; fraction within 5 %; verdict always `:no_verdict`.

### Case: MRP_APPD
**Title:** App. D Eqs. (D.17)–(D.26) vs Table D-1
**Map / block:** pain / P_MRP
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Table D-1 / Fig. D-2; App. D pp. D-3…D-10
**What it tests:** Printed App. D structural solver (no fitted scale) vs Table D-1 frequencies.
**Why it is here:** Any geometry other than the test article needs Eqs. (D.17)–(D.26), not the Table D-1 seed.
**A pass means:** ≥ 75 % of the 32 Table D-1 modes within 5 % (count rule fixed 2026-10-22 before any run); no calibration input.
**Not covered:** Fig. D-2 shapes reported without a pass mark; production default remains Table D-1 / fitted surrogate.
**Recorded outcome:** **met**, 27/32 within 5 % (84.4 %); Fig. D-2 max \|Δw\| = 1.4534 (info, no pass mark). First run 2026-10-22 (`mrp_appd_vs_d1.md`)
**Explanation:** Code-on-code (against printed values / NASA solver outputs): implements App. D constraints D.17–D.21, constitutive D.23–D.24, operator D.25, eigenproblem D.22, shapes D.26–D.29 with physical geometry from App. E / Manual §5.2. No parameter fitted to Table D-1. Label V-CODE; first run 2026-10-22.
Inputs: `appd_test_article_geometry()`; n_modes=48, n_axial=7, n_circ=8, n_floor_max=5; tol_frac=0.05; count rule ≥75 % of 32.
Equations: App. D (D.17)–(D.26); code `appd_modes` in `mrp_appd.jl`.
Outputs: f [Hz] vs Table D-1; Fig. D-2 shape residuals (info); verdict on count rule.

### Case: CYL2D_C1
**Title:** CYL2D vs Table C-1 / Fig. C-3
**Map / block:** pain / P_CYL
**Category:** verification
**Kind:** runnable
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

### Case: UT_TRIM
**Title:** Trim / loss (Pkg.test)
**Map / block:** pain / P_TRIM
**Category:** verification
**Kind:** pkgtest
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
**Map / block:** pain / P_TRIM
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Fig. E-14, p.139
**What it tests:** Eq. (78) band-average acoustic loss η̄ vs NASA's calculated Fig. E-14 curves.
**Why it is here:** Only NASA-calculated loss curve available for the acoustic-loss path.
**A pass means:** Within ±25 % of NASA's calculated η̄.
**Not covered:** E-13 has no calculated curve; not tuned when criterion fails.
**Recorded outcome:** 7/18 bands, not met (trim_loss_e13_e14_e15.md)
**Explanation:** Code-on-code (against NASA calculated curve): Eq. (78) band-average loss with App. A trim conductance ξ vs digitized NASA calculated Fig. E-14. Axes: band Hz (log) vs loss factor (log). Recorded 7/18 within ±25 % — often not met; not tuned.
Inputs: `e14_acoustic_loss_calculated.csv`; `phase3_trim(; η_lining=0.5)`; a = 0.508 m, L = 1.83 m, θ0 = 56.6°; c0 = 340 m/s, ρ0 = 1.225.
Equations: Eq. (78) via `acoustic_loss_average`; trim conductance via `trim_conductance`.
Outputs: η̄ [-] per band; verdict ±25 % vs NASA η_T = 0.5 curve.

### Case: E15_STRUCT_LOSS
**Title:** Fig. E-15 η_r′ (struct. loss)
**Map / block:** pain / P_TRIM
**Category:** experiment
**Kind:** runnable
**Source:** CR-3813 Fig. E-15, p.E-25 / PDF p.141
**What it tests:** Total structural loss factor η_r′ of Eq. (82) with Phase III trim vs measured E-15.
**Why it is here:** Measured total structural loss vs frequency (with trim).
**A pass means:** — (V-EXP info; no pass mark, as 16b)
**Not covered:** No frozen pass criterion; quantity is η_r′ (with trim), not bare η_r.
**Recorded outcome:** first run 2026-10-22; 4/8 within tol_frac (info); e15_structural_loss.md (no_verdict)
**Explanation:** Experiment comparison (info only): Fig. E-15 plots measured and predicted total structural loss with trim-loss curves at 0.5 and 1.0 and an upper-limit line at 0.15 — that is η_r′ of Eq. (82), not bare η_r. Uses Phase III trim η_T = 1.0 and η_r_cap = 0.15 (E-18/E-21 setting, p. E-30). Verdict always `:no_verdict`.
Inputs: `e15_structural_loss_targets.csv`; `phase3_trim` with η_lining = 1.0; η_r_cap = 0.15; L = 1.83 m, a = 0.508 m, θ0 = 56.6°.
Equations: Eq. (82) η_r′ in `trim_loss.jl` / structural-loss helpers.
Outputs: η_r′ [-] vs measured; info counts within CSV tol_frac; verdict `:no_verdict`.

### Case: UT_EQ8
**Title:** Eq. (8) coupling + HF tones (Pkg.test)
**Map / block:** pain / P_EQ8
**Category:** verification
**Kind:** pkgtest
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

### Case: REPRO_18b
**Title:** PAIN reproduction (18b-r)
**Map / block:** pain / P_REPRO
**Category:** calibrated
**Kind:** runnable
**Source:** CR-3813 Fig. E-16 NASA PAIN circles, p.142
**What it tests:** Whole cabin chain on ANOPP Table 8 with R1 vs NASA's PAIN interior predictions.
**Why it is here:** Shows whether this chain computes what NASA's program computed (code-on-code).
**A pass means:** Code-to-code agreement within 4 dB per harmonic H1–H3.
**Not covered:** η_T = 0.5 adopted after 19f showed the result (post-hoc); conditional on GEXT; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** 18b-r not met 1/3: 85.90, 78.35, 79.82 dB at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 85.74, 78.74, 80.06 — `length_sensitivity.md` / `pain_reproduction_e16.md`). Phase 38b `:auto` (report only): 85.90, 16.81, 72.24 dB; H3 Δ=+4.24 (I-18 explains H3 = no); `phase38b_high_freq_tones.md`
**Explanation:** Code-on-code (against printed values): run the cabin chain on ANOPP Table 8 with blocking R1 and Phase III trim η_T = 0.5 (NASA's value) and compare interior SPL with NASA's PAIN circles on Fig. E-16 (±4 dB per harmonic). Axes: harmonic band vs SPL; NASA circles vs this code. η_T = 0.5 was adopted after 19f → post-hoc. Conditional on GEXT.
Inputs: `default_e11_paths().anopp_spl`; `phase3_trim(; η_lining=0.5)`; blocking R1; BPF = 200 Hz; n_harmonics = 3; L = 1.83 m; targets `t1_interior_targets.csv` (NASA PAIN column).
Equations: full cabin chain; tone Eq. (8) via `run_pain_pipeline` / `tone_mean_square_pressure`; blocking Eq. (43) R1.
Outputs: interior SPL_H1..H3 [dB]; verdict |Δ| ≤ 4 dB vs NASA PAIN prediction.

### Case: E18_TONES
**Title:** Fig. E-18 tones (η_T=1)
**Map / block:** pain / P_REPRO
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Fig. E-18, p.E-29; e18_interior_pred_eta1.csv
**What it tests:** Tones with η_T = 1.0 and η_r′ ≤ 0.15 vs NASA E-18 prediction.
**Why it is here:** NASA's η_T = 1.0 / capped-η_r′ setting (same as E-21) on the tone path.
**A pass means:** |computed − NASA E-18 prediction| ≤ 4 dB at each of H1–H3 (bands 200, 400, 630 Hz).
**Not covered:** :auto and measured mean/low/high are secondary (V-EXP held out); no parameter from E-18.
**Recorded outcome:** 2/3 within ±4 dB (88.67, 77.78, 77.55 dB) at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 89.02, 78.14, 77.70); not met; e18_tones_eta1.md
**Explanation:** Code-on-code (against NASA prediction): same free-field/blocking/grid as 18b-r but Phase III trim η_T = 1.0 and η_r_cap = 0.15 on the tone path (`tone_model=:eq8`). H1–H3 map to 200, 400, 630 Hz (H3 at 3·BPF = 600 Hz → 630 Hz 1/3-octave band). Criterion dated 2026-10-21 (same ±4 dB as 18b).
Inputs: `default_e11_paths()`; `phase3_trim(; η_lining=1.0)`; η_r_cap = 0.15; BPF = 200 Hz; L = 1.83 m; `e18_interior_pred_eta1.csv`.
Equations: Eq. (8) tones; Eq. (82) capped η_r′; blocking as in pipeline.
Outputs: interior SPL [dB] at 200/400/630 Hz; verdict ≤ 4 dB vs NASA E-18 prediction.

### Case: T1
**Title:** Tonal interior SPL (T1)
**Map / block:** pain / P_MEAS
**Category:** calibrated
**Kind:** runnable
**Source:** CR-3813 Fig. E-16/E-17, p.142
**What it tests:** End-to-end tonal interior SPL on the e11 measured free-field path vs Fig. E-16/E-17.
**Why it is here:** Only end-to-end tonal SPL check against measurement (still not claimable after GEXT_BOUND).
**A pass means:** In-sample consistency (gate A mean ± 4 dB, or gate B envelope + NASA ± 4 dB).
**Not covered:** No claim: GEXT variants flip it; H3 fails; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** 84.21, 77.66, 78.06 dB at L = 1.83 m (H1 fail, H2 pass, H3 fail); t1_tonal.md (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 84.05, 78.01, 78.30)
**Explanation:** Experiment comparison (calibrated / in-sample): e11 free-field → GEXT → blocking R2 → modes → Eq. (8) → interior tonal SPL vs measured Fig. E-16/E-17. Gate A: |got − measured mean| ≤ 4 dB; gate B: inside measured envelope and |got − NASA PAIN| ≤ 4 dB. Axes: 1/3-octave band vs SPL. No claim after GEXT_BOUND.
Inputs: `run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200, blocking=R2)`; η_T = 0.5 default path; `t1_interior_targets.csv`; L = 1.83 m.
Equations: full chain; Eq. (8); GEXT; Eq. (43) R2.
Outputs: SPL_H1..H3 [dB]; verdict on gates A/B (still labeled not claimable).

### Case: T2
**Title:** 1/3-octave (T2)
**Map / block:** pain / P_MEAS
**Category:** calibrated
**Kind:** runnable
**Source:** CR-3813 Fig. E-9, p.132
**What it tests:** Broadband 1/3-octave interior SPL (surrogate path) vs Fig. E-9 at 1.25–2 kHz.
**Why it is here:** Tonal model puts no energy above 1 kHz; this covers three high bands (surrogate).
**A pass means:** In-sample: |got − measured mean| ≤ tol_dB from CSV; bb_j2_scale = 0.5 was fitted earlier (stale).
**Not covered:** Only 1.25–2 kHz; nothing above; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** 55.92, 53.56, 51.59 dB at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 55.97, 53.63, 51.67); t2_third_octave.md
**Explanation:** Experiment comparison (calibrated): surrogate broadband path vs Fig. E-9 means at 1.25, 1.6, 2 kHz. bb_j2_scale = 0.5 fitted earlier → post-hoc. Printed Eqs. (19)–(23) are case T2_EQ19.
Inputs: `run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200, blocking=R2)`; `t2_third_octave_targets.csv`; bb_j2_scale = 0.5; L = 1.83 m.
Equations: surrogate broadband (not printed Eqs. 19–23); `evaluate_T2`.
Outputs: 1/3-octave SPL [dB] at target bands; verdict vs CSV tol_dB.

### Case: T2_EQ19
**Title:** 1/3-octave Eq.(19) (T2_EQ19)
**Map / block:** pain / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** CR-3813 Fig. E-9, p.132; Eqs. (19)–(23) pp.23–25
**What it tests:** Printed high-frequency broadband Eqs. (19)–(23) vs Fig. E-9.
**Why it is here:** First printed-model run replacing the surrogate / stale bb_j2_scale path.
**A pass means:** Same T2 criterion: |got − Fig. E-9 mean| ≤ 3.5 dB at 1.25, 1.6, 2 kHz (criterion unchanged).
**Not covered:** Spbl ∝ f^−2 anchor remains V-ASSUMED; only three bands; no parameter chosen from E-9/E-21/E-22.
**Recorded outcome:** 0/3 PASS (38.56, 35.81, 34.87 dB vs 51/46/41.5) at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 38.59, 35.87, 34.94); full-band E-21/E-22 V-CODE 1/13, V-EXP 0/15; phase38c_hf_broadband.md
**Explanation:** Experiment comparison: interior 1/3-octave SPL with `broadband_model=:eq19` (printed τ_f, τ_R, ᾱ from Eq. 24/78, A_t/S/A′) vs Fig. E-9. Default `:surrogate` T2 path unchanged. First run not met; no parameter tuned.
Inputs: same e11 geometry/blocking as T2; `broadband_model=:eq19` via T2_EQ19 runner; targets CSV; L = 1.83 m.
Equations: Eqs. (19)–(23) in `hf_broadband.jl`; related Eq. (24)/(78) absorptions.
Outputs: SPL [dB] at 1.25/1.6/2 kHz; verdict ±3.5 dB; E-21/E-22 full-band counts reported only.

### Case: E21_E22_NR
**Title:** Figs. E-21 / E-22 NR
**Map / block:** pain / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** CR-3813 Figs. E-21, E-22, p.149
**What it tests:** Cabin noise reduction NR vs NASA E-21 prediction and E-22 measured confidence limits.
**Why it is here:** Held out of any calibration (23e); first runnable NR check (38a).
**A pass means:** |NR−NASA|≤3 dB at ≥75% of counted bands and NR inside E-22 95% at ≥75% (criterion dated 2026-10-21).
**Not covered:** 80–160 Hz excluded (end-plate V-ASSUMED); counts below crossover only.
**Recorded outcome:** first run 2026-10-21; V-CODE / V-EXP counts below crossover not met (`e21_e22_noise_reduction.md`); held out of calibration (23e).
**Explanation:** Experiment comparison: noise reduction NR = 10 log10(⟨p_e²⟩/⟨p_i²⟩) from Eqs. (17)–(18) with Phase III trim η_T = 1.0 and η_r_cap = 0.15 (p. E-30). Compared with NASA E-21 prediction and E-22 95 % limits. Axes: band Hz vs NR [dB].
Inputs: `noise_reduction_test_article_inputs(; η_lining=1.0)`; η_r_cap = 0.15; CSVs `e21_noise_reduction_range.csv`, `e22_noise_reduction_ci.csv`; L = 1.83 m.
Equations: Eqs. (17)–(18) via `noise_reduction_band` / `noise_reduction_spectrum`.
Outputs: NR(band) [dB]; verdict on NASA and E-22 fraction rules.

### Case: UT_POLAR
**Title:** Polar loader (Pkg.test)
**Map / block:** aircraft / A_GEO
**Category:** verification
**Kind:** pkgtest
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

### Case: R996_LOADS
**Title:** Report 996 CCBlade loads
**Map / block:** aircraft / A_LOADS
**Category:** calibrated
**Kind:** replay
**Source:** RM L8H25a, Report 996 Fig. 14 table, Fig. 7 legend
**What it tests:** CCBlade BEMT thrust and torque coefficients C_T, C_P vs measured.
**Why it is here:** Load error swamps acoustic error.
**A pass means:** C_T, C_P within ±15 % (23c).
**Not covered:** Criteria registered after the loads were computed (post-hoc); polars XFOIL + Viterna.
**Recorded outcome:** 6/32 within ±15 % (not met); post-hoc label; scale_factors.csv / report996_loads.md
**Explanation:** Replay of a recorded result: CCBlade C_T, C_P vs RM L8H25a / Fig. 14 table / Fig. 7 legend (±15 %, 23c). Recorded 6/32. Criterion registered after the loads → post-hoc. Not tuned.
Inputs: recorded `scale_factors.csv` from the Report 996 loads script; aircraft/polar set used in that run (see report996_loads.md).
Equations: BEMT in CCBlade via `propeller_ccblade.jl` (recorded outputs replayed).
Outputs: C_T, C_P [-]; verdict |ratio−1| ≤ 0.15 (replay).

### Case: PER_LOADS
**Title:** Pereira Table 3 loads
**Map / block:** aircraft / A_LOADS
**Category:** experiment
**Kind:** replay
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

### Case: F1A_GUTIN
**Title:** F1A vs Gutin (far field)
**Map / block:** aircraft / A_AMP
**Category:** verification
**Kind:** runnable
**Source:** Gutin far-field closed form
**What it tests:** F1A loading-noise wiring vs Gutin's closed form on identical loads (far field).
**Why it is here:** Catches coding errors in the F1A path before any experiment.
**A pass means:** F1A = Gutin within 1 dB on identical loads (V-CODE-like).
**Not covered:** Not experimental; far field only; thickness off.
**Recorded outcome:** Pkg.test pass
**Explanation:** Code-on-code (against printed values / closed form): Farassat F1A (AcousticAnalogies.jl) vs Gutin 1936 far-field loading-noise tone in the rotor plane from thrust and torque alone. Same loads → agree within 1 dB shows F1A is wired correctly.
Inputs: synthetic identical loads; static; thickness off; observer at 100 R_tip in the rotor plane; first harmonic H1.
Equations: F1A (AcousticAnalogies); Gutin closed form; comparison in `_run_f1a_gutin`.
Outputs: SPL [dB]; verdict |Δ| ≤ 1 dB.

### Case: R996_FIG14
**Title:** Report 996 Fig. 14(a)
**Map / block:** aircraft / A_AMP
**Category:** experiment
**Kind:** replay
**Source:** NACA Report 996 Fig. 14(a), p.16
**What it tests:** F1A harmonic amplitude vs tip Mach M_t at fuselage-like distance.
**Why it is here:** Static near-field amplitude check.
**A pass means:** Scaled-load harmonic within ±2 dB at ≥ 75 % of points (23c).
**Not covered:** Loads scaled to measured T, Q (calibrated input); static only; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** met 20/24 within ±2 dB (report996_acoustics.md; amplitude convention fixed 2026-10-21, post-hoc)
**Explanation:** Replay of a recorded result: static near-field harmonic amplitude vs M_t (Fig. 14(a)). Loads scaled to measured T, Q. After I-17: 20/24 within ±2 dB → met (≥75 %). Post-hoc label on the amplitude-convention re-record.
Inputs: recorded `f1a_results.csv` from Report 996 acoustics script; scaled-load path.
Equations: F1A (replayed); criterion 20 log10(A_rms/meas).
Outputs: pressure [dyne/cm²] / SPL error [dB]; verdict ≥75 % within ±2 dB.

### Case: R996_FIG12
**Title:** Report 996 Fig. 12(a)(b)
**Map / block:** aircraft / A_AMP
**Category:** experiment
**Kind:** replay
**Source:** Report 996 Fig. 12(a)(b), p.13
**What it tests:** F1A harmonic amplitude vs x/D (axial near-field shape).
**Why it is here:** Axial shape of the near field.
**A pass means:** Scaled-load harmonic within ±2 dB at ≥ 75 % of points (23c).
**Not covered:** Loads scaled to measured T, Q (calibrated input); static only; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** not_met 22/40 within ±2 dB (report996_acoustics.md; amplitude convention fixed 2026-10-21, post-hoc)
**Explanation:** Replay of a recorded result: axial near-field harmonics vs x/D. After I-17: 22/40 within ±2 dB (not met; need ≥75 %). Scaled loads; amplitude-convention fix post-hoc.
Inputs: recorded `f1a_results.csv`.
Equations: F1A (replayed).
Outputs: pressure vs x/D; verdict ≥75 % within ±2 dB.

### Case: R996_FIG13A
**Title:** Report 996 Fig. 13(a)
**Map / block:** aircraft / A_AMP
**Category:** experiment
**Kind:** replay
**Source:** Report 996 Fig. 13(a), p.15
**What it tests:** F1A first harmonic vs x/D with RM L51C27 load scale (ahead/behind asymmetry).
**Why it is here:** Ahead/behind asymmetry check.
**A pass means:** Scaled-load harmonic within ±2 dB at ≥ 75 % of points (23c).
**Not covered:** Loads scaled to RM L51C27 T, Q (calibrated input); static only; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** not_met 8/14 within ±2 dB (report996_acoustics.md; amplitude convention fixed 2026-10-21, post-hoc)
**Explanation:** Replay of a recorded result: first-harmonic amplitude vs x/D with L51C27 scale. After I-17: 8/14 within ±2 dB (not met). Amplitude-convention fix post-hoc.
Inputs: recorded `f1a_results.csv` (L51C27 scale).
Equations: F1A (replayed).
Outputs: H1 pressure vs x/D; verdict ≥75 % within ±2 dB.

### Case: R996_FIG6
**Title:** Report 996 Fig. 6
**Map / block:** aircraft / A_AMP
**Category:** experiment
**Kind:** replay
**Source:** Report 996 Fig. 6, p.11
**What it tests:** F1A total rms vs x/D for B = 4 blades (tip-clearance trend).
**Why it is here:** Tip-clearance trend with four blades.
**A pass means:** Shape and clearance ratios only (no B = 4 loads) — informational.
**Not covered:** no measured T, Q for B = 4.
**Recorded outcome:** informational (no B = 4 loads); replay of f1a_results.csv
**Explanation:** Replay of a recorded result: total rms pressure vs x/D for B = 4. Plotted, no verdict: no measured T, Q for B = 4. Frozen 23c not applied.
Inputs: recorded `f1a_results.csv`, `tr996_fig6_tip_clearance_pressure_vs_xD.csv`.
Equations: F1A (replayed).
Outputs: total rms [dyne/cm²]; no pass rule.

### Case: R996_FIG7
**Title:** Report 996 Fig. 7
**Map / block:** aircraft / A_AMP
**Category:** experiment
**Kind:** replay
**Source:** Report 996 Fig. 7, p.11
**What it tests:** Blade-loading trend p_c/C_P vs x/D.
**Why it is here:** Blade-loading trend beside Fig. 6.
**A pass means:** Informational (script does not apply 23c to Fig. 7).
**Not covered:** —
**Recorded outcome:** informational (script does not apply 23c); replay of f1a_results.csv
**Explanation:** Replay of a recorded result: p_c/C_P vs x/D (Fig. 7). Informational — acoustics script does not apply frozen 23c to Fig. 7.
Inputs: recorded `f1a_results.csv`, `tr996_fig7_blade_loading_pc_over_CP_vs_xD.csv`.
Equations: F1A (replayed).
Outputs: p_c/C_P [-]; no pass rule.

### Case: BBN_KIN
**Title:** BBN kinematic Δφ
**Map / block:** aircraft / A_PHASE
**Category:** verification
**Kind:** runnable
**Source:** kinematics (23a′)
**What it tests:** F1A phase difference on a hub ring equals m·B·Δψ within 0.5°.
**Why it is here:** Phase between grid points drives joint acceptance Ψ_G.
**A pass means:** Δφ = m·B·Δψ within 0.5°; reverse rotation flips sign.
**Not covered:** Sign convention is a free gauge; no measurement.
**Recorded outcome:** PASS
**Explanation:** Unit test: kinematic check that F1A phase difference on a hub ring equals m·B·Δψ within 0.5°, and reverse rotation flips the sign. Coding check of phase wiring for Ψ_G — no measurement.
Inputs: synthetic hub-ring observers; blade count B; harmonics m; rotation ±1 (runner `_run_bbn_kin`).
Equations: rigid-rotation kinematic Δφ = m·B·Δψ; F1A phase extraction.
Outputs: Δφ [deg]; verdict |Δφ − m·B·Δψ| ≤ 0.5°.

### Case: BBN_CIRC
**Title:** BBN circumferential phase
**Map / block:** aircraft / A_PHASE
**Category:** experiment
**Kind:** replay
**Source:** NASA CR-158919 App. C, CR-159124
**What it tests:** F1A circumferential phase between fuselage microphones.
**Why it is here:** First experimental phase check.
**A pass means:** ≥ 80 % of coh≥0.15 rows within 15°/35° (23a).
**Not covered:** Reflecting surface; low coherence; reference-mic sign not stated in the source.
**Recorded outcome:** FAIL 26/168 within tolerance; replay of bbn_results.csv
**Explanation:** Replay of a recorded result: circumferential phase (CR-158919 App. C / CR-159124) under frozen 23a. Fails 26/168 (15 %). Measured phases often opposite sign to F1A; source does not name the reference mic, so the sign is not fixed from the papers. Verdict stays.
Inputs: recorded `bbn_results.csv` from BBN script.
Equations: F1A phase (replayed); criterion 23a.
Outputs: phase [deg]; verdict on 80 % within 15°/35°.

### Case: BBN_LONG
**Title:** BBN longitudinal phase
**Map / block:** aircraft / A_PHASE
**Category:** extrap
**Kind:** replay
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
**Map / block:** aircraft / A_PHASE
**Category:** experiment
**Kind:** replay
**Source:** Report 996 p.12 text
**What it tests:** F1A phase ahead/behind vs the one measured value 155°.
**Why it is here:** Only measured phase in Report 996.
**A pass means:** within ±15° of 155° (23c).
**Not covered:** One data point; stations ±0.125 used as candidates (report does not name them).
**Recorded outcome:** FAIL 103.8° vs 155° (±15°); tr996_phase_values.csv + f1a_results.csv
**Explanation:** Replay of a recorded result: one measured phase 155° (p. 12). Comparison uses ±0.125 x/D as candidates; F1A gives 103.8°. Fails ±15° (23c). Nothing tuned.
Inputs: recorded `tr996_phase_values.csv`, `f1a_results.csv`.
Equations: F1A phase (replayed).
Outputs: phase difference [deg]; verdict within ±15° of 155°.

### Case: PER_FIG6
**Title:** Pereira Fig. 6 spectra
**Map / block:** aircraft / A_FWD
**Category:** experiment
**Kind:** replay
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
**Title:** Pereira Fig. 7 waveform
**Map / block:** aircraft / A_FWD
**Category:** experiment
**Kind:** replay
**Source:** Pereira et al. 2026 Fig. 7
**What it tests:** F1A first-harmonic phase shift Δψ₁ vs Fig. 7.
**Why it is here:** Only forward-flight waveform/phase figure under 23d.
**A pass means:** Δψ₁ ±5° (23d).
**Not covered:** Motor noise above H2; far field only.
**Recorded outcome:** replay of pereira_results.csv
**Explanation:** Replay of a recorded result: Δψ₁(φ) = ψ₁(φ)−ψ₁(0°) vs Fig. 7 (±5°, 23d). Far field; motor noise above H2.
Inputs: recorded `pereira_results.csv`, `pereira_fig7_harmonics.csv`.
Equations: F1A phase (replayed).
Outputs: Δψ₁ [deg]; verdict ±5°.

### Case: PER_FIG8
**Title:** Pereira Fig. 8 directivity
**Map / block:** aircraft / A_FWD
**Category:** experiment
**Kind:** replay
**Source:** Pereira et al. 2026 Fig. 8
**What it tests:** F1A forward-flight directivity at 1 m.
**Why it is here:** Only forward-flight directivity under 23d.
**A pass means:** H1 ±1.7 dB, H2 ±3 dB (23d); H3+ informational.
**Not covered:** Motor noise above H2; far field only; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** replay of pereira_results.csv (amplitude convention fixed 2026-10-21, post-hoc)
**Explanation:** Replay of a recorded result: directivity at 1 m vs Fig. 8 (H1 ±1.7 dB, H2 ±3 dB). Amplitude convention fixed 2026-10-21, post-hoc.
Inputs: recorded `pereira_results.csv`, `pereira_fig8_directivity.csv`.
Equations: F1A (replayed).
Outputs: SPL [dB] vs φ; verdict on H1/H2 tolerances.

### Case: PER_FIG9
**Title:** Pereira Fig. 9 harmonics
**Map / block:** aircraft / A_FWD
**Category:** experiment
**Kind:** replay
**Source:** Pereira et al. 2026 Fig. 9
**What it tests:** F1A forward-flight harmonics at 1 m vs Fig. 9 Exp.
**Why it is here:** Only forward-flight harmonic bar check under 23d.
**A pass means:** H1 ±1.7 dB, H2 ±3 dB (23d).
**Not covered:** Motor noise above H2; far field only; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** not_met H1 3/9, H2 6/9; pereira_results.csv (amplitude convention fixed 2026-10-21, post-hoc)
**Explanation:** Replay of a recorded result: harmonics at 1 m vs Fig. 9. After I-17: H1 3/9 within ±1.7 dB, H2 6/9 within ±3 dB (not met on H1). Amplitude convention fixed 2026-10-21, post-hoc.
Inputs: recorded `pereira_results.csv`, `pereira_fig9_harmonics.csv`.
Equations: F1A (replayed).
Outputs: SPL [dB]; verdict on H1/H2 counts.

### Case: BBN_LEVELS
**Title:** BBN relative levels
**Map / block:** aircraft / A_SURF
**Category:** extrap
**Kind:** replay
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

---
## 3. What “valid recreation” means for this project

A recreation is **pipeline-valid** only if:

1. **Blocking** matches Eq. (43) within **0.06 dB** (R1) and R2 scaling is explicit.  
2. **CYL2D / MRP** match Table C-1 / D-1 within flowchart tolerances (**V-CODE**).  
3. **PAIN core** with **measured / digitized free-field** (Fig. E-11 path) reproduces App. E tonal tests within the published scatter (**V-EXP**).  
4. **CCBlade + AcousticAnalogies** is treated as an **alternate free-field generator**; its outputs are **X-EXTRAP** for the aircraft application (phase 33 close-out 2026-10-21: BBN 24c, Report 996 23c and Pereira 23d did not meet frozen tolerances; Gutin/Hanson optional cross-check not run). See §2.3.3.

Do **not** claim that replacing ANOPP with CCBlade/F1A inherits NASA’s exterior-noise validation. Claim inheritance only for the **transmission / cabin** model after the free-field grid interface.

---

## 3.1 Test runner notes (P1, 2026-10-22)

`Pkg.test("PAIN"; test_args=[…])` selects top-level testsets by case-insensitive title substring. Empty args run the full suite. This is a developer convenience only: **no assertion, tolerance, reference file or recorded result changes.** Titles and measured times: `PAIN.jl/test/README.md`. Optional DaemonMode under `PAIN.jl/scripts/devtools/` (separate Project.toml; Revise loaded in the daemon).

## 3.2 Directory layout (R1, 2026-10-22)

CR-3813 digitized inputs live under `data/cr3813/`; validation/report scripts under `PAIN.jl/scripts/{run,checks,digitize,setup,smoke}/` (`run_gui.jl` remains at `scripts/run_gui.jl`). See `data/README.md` and `PAIN.jl/scripts/README.md`. **Moves and path edits only** — no change to pass criteria, tolerances or recorded numeric results.

---

## 4. Implementation order (validation-first)

Aligned with `flowchart.md`:

1. **Blocking** Eq. (43) + incidence geometry + R1/R2 — unit tests vs p.68  
2. **Grid geometry** (User Manual Fig. 3) + assumed extension unit tests  
3. **CYL2D** → Table C-1  
4. **MRP/MRPMOD** → Table D-1 (5%)  
5. **PAIN core** (coupling, \(Ψ_G\), trim, loss, power balance) with **digitized / table free-field** inputs  
6. Run **T1 / T2** (and TS if needed) — document pass/fail  
7. **CCBlade → AcousticAnalogies → grid** adapter — mark **X-EXTRAP**; source block checked against NACA Report 996 and Pereira et al. (plan phases 25–28), through the same shared source function  
8. Aircraft dB(A)/SIL post-processing — **X-EXTRAP**

---

## 5. Interface contract (ANOPP → Julia stack)

Free-field grid file / struct (per harmonic H, per point `(k,ℓ)`):

| Field | Meaning |
|-------|---------|
| `x, y, z` | Fuselage-skin point (PAIN / ANOPP coordinates) |
| `A_ff[H]` | Free-field pressure amplitude (Pa) |
| `ϕ_ff[H]` | Free-field phase (rad) |
| `γ` | Incidence angle (deg) for blocking |
| `A_bl[H]`, `ϕ_bl[H]` | After Eq. (43); `ϕ_bl = ϕ_ff` |

Producer may be: digitized Fig. E-11 + extension | ANOPP dump | **CCBlade + AcousticAnalogies**.

---

## 6. Reporting template (required in test outputs)

```
block: <flowchart id>
class: V-EXP | V-CODE | V-UNIT | V-ASSUMED | X-EXTRAP
reference: <PDF + page/figure/table>
metric: <what was compared>
tolerance: <number>
result: PASS | FAIL | N/A
notes: <R1/R2, harmonic cutoff, digitization δ_dig, …>
```

---

## 7. References (local)

- `Pain Methodology.pdf` — NASA-CR-3813  
- `Pain User Manual.pdf` — NASA-CR-172425  
- `Pain Validation.pdf` — NASA-CR-172428  
- `flowchart.md` — recreation architecture & test gates (separate validation and aircraft paths)  
- Extracted text: `docs/extracted/*.md`  
- CCBlade + AcousticAnalogies: [CCBlade example](https://openmdao.github.io/AcousticAnalogies.jl/stable/ccblade_example/)
