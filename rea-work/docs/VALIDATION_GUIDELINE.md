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
| Smoke test | `scripts/run_f1a_smoke.jl` compares peak SPL on the `ℓ = 1` line with ANOPP Table 8 from CR-172428. It is a sanity check, not a validation. |

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
| Verify | Table D-1 first **32** modes within **5%** on frequency (flowchart) | **V-CODE**. The production mode set reuses the D-1 frequencies, so its 32/32 is circular; the raw Ritz solver matches 30/32 after three scales were fitted to D-1 (see §2.10). |
| Not | Experimental modal survey |

### 2.6 Acoustic cabin modes — `CYL2D`

| Item | Spec |
|------|------|
| Method | CR-3813 App. C exactly (phase 15, 2026-10-20): half-cabin finite-difference grid, NY = 10 floor-to-crown intervals, Eqs. (C.1)–(C.6), tangential-gradient rule at the two-exterior-neighbour points nearest π/4 and 3π/4, symmetric and antisymmetric modes solved separately, 20 kept; Φ_G Eq. (C.10), ε_n Eq. (C.11); 3-D modes (q, i) by Eqs. (C.7), (C.9) |
| Verify | Table C-1 (c0 = 341 m/s): 20 frequencies and generalized masses within 0.1 %, symmetry types, Fig. C-3 modes 0–5 equal to the printed one-decimal values (criteria fixed 2026-10-20 before the run) | **V-CODE** |
| Result | All pass (61/61 in `cyl2d_table_c1.md`): max frequency error 0.001 %, max Φ_G error 0.002 %, 0 Fig. C-3 mismatches. Errors of an earlier reference transcription (modes 3, 19) corrected |
| Registers | 13a(a): the node window r ≤ 1 + 0.32h … 0.47h gives identical modes (0.31h gives a 4-node second row; 0.48h a 7-node fourth row; both then fail the real-spectrum check). 13a(b): for θ0 = 56.6° the valid NY among 8–14 are 8, 10, 11 (NY = 10 is the paper's); the others have complex eigenvalues. θ0 = 90° has a singular B_E at every NY tried, and θ0 = 40° and 70° had at most one valid NY in 8–14, so `cyl2d_modes_search` can fail; the error names the grid. 13a(d): q_max = ⌈2ω_H L/(π c0)⌉ = 5, 9, 13 at H1–H3; q_max + 2 changes the Eq. (8) sum by 0.000 dB for the Phase III trim and the bare cabin (`q_convergence.md`, repeated in 17a): rule met |

### 2.7 PAIN main — coupling, forces, trim, loss, power balance

| Sub-function | Reference | Validation target | Class |
|--------------|-----------|-------------------|-------|
| Coupling \(f'(n,r)\) + joint acceptance \(j_r^2\) | CR-3813 §3.5–3.6 | Eq. (52) with Eqs. (46)–(49), (53)–(57) implemented (floor term, (−1)^n, √τ_t, no clamp); analytic-limit tests (V-CODE); ε_n now enters Eq. (8); no |f'| > 1 error in the phase 17 runs | **V-CODE (analytic limits only)** |
| Generalized force \(Ψ_G\) Eq. (42) | CR-3813 §3.4 | Δ⁴/2 form implemented (17a); analytic limits, the Eq. (41) double sum and the grid spacing tested (17e, 11 checks); Table D-1 inputs equal an independent digitization (17d, all 32 modes); 19d (2026-10-20): the 160 stated points are used, no mirroring (input grid, Fig. 3, card-36 note, CR-3813 §3.4; the item 7 output wording is unresolved); mirrored-field diagnostics in 18b move H1–H3 by +1.5, −2.1, +3.3 dB (about θ = 0) and +0.7, +3.2, +6.8 dB (about ℓ = 1), not adopted (`grid_mirroring.md`) | **V-UNIT (analytic limits)** |
| Trim transfer matrix | CR-3813 App. A | Figs. E-13, E-14 | In the pipeline since 17a, no fitted parameter. Exact limits (V-UNIT); Eq. (78) with ξ from Eq. (A.16) vs NASA's calculated E-14 curves, 7 of 18 bands within ±25 % at trim loss 0.5 and 1.0, **criterion not met**, not tuned (§2.11.3); E-13 has no calculated curve |
| Loss factors §3.8 | CR-3813 | Figs. E-14, E-15 | In the pipeline since 17a, no fitted parameter. Si/Cin to machine precision, joint acceptances vs direct quadrature, η_n/η_r'/η_r'' limits (V-UNIT); E-15 η_r' recorded with no pass mark. η_r uses C_Mn² unnormalized (shape scaling is not an invariance of the full p², 17i) |
| Power balance \(W_\mathrm{in}=W_\mathrm{diss}\) + modal sum | CR-3813 §3.1 Eqs. (1)–(3), (8), (16) | Eq. (8) summed by Eq. (3) (17a); independent re-implementation (direct form, quadrature coupling, double-sum Ψ_G) agrees to 2e-3 on a bare cabin, scaling laws tested (17h, 17i); 19a (2026-10-20, criteria fixed before the run): Eq. (8) derived from Eqs. (4)–(7); two-resonator model solved exactly, inflow = Eq. (5) W_diss, weak-coupling ⟨p_n²⟩ = Eq. (8) and inflow = Eq. (7), back-reaction loss = Eq. (83) at ω_r, all within 1e-15 (11 of 11 criteria met); 19b: (mA/4)²τ_ML = (ρ0c0A/(2ω_H))² exact. Recorded: Eq. (8) omits the reactive back-reaction (−0.9 dB at ω_r, −4.9 dB at ω_n for the test-article f′ = 0.19; +0.13 dB at 200 Hz) and sums structural modes incoherently (`eq8_two_resonator.md`); 19c (2026-10-20): ε_n(q > 0) = 2 ε_n(q = 0) is Eq. (C.11) as printed (pp. C-6, C-7), factor confirmed by quadrature to 1e-15; the q = 0 node sum differs from an independent quadrature by 0.65–5.4 % (criterion 0.5 % not met, recorded); the alternative ε_n(q > 0) = ε_n(q = 0) shifts the 18b harmonics by −0.10, −2.02, −0.82 dB and does not close the miss (`eps_n_quadrature.md`) | **V-UNIT (derivation, two-resonator conservation)** |

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

### 2.10 Test-case guide: what each test does, why it exists, how much it proves

**GUI registry (phase 34).** Each row below that has a registry ID can be run from the GUI **Validation** tab (and from
`run_validation_case(id)` / scripts). Plots go to `docs/validation_reports/figures/<id>.png`. Cases are read-only. IDs in use:
`CYL2D_C1`, `MRP_D1`, `T1`, `T2`, `REPRO_18b` (runnable); `E12_BLOCK`, `E11_FREEFIELD`, `E14_LOSS`, `E21_E22_NR`, `GEXT_BOUND`,
`BBN_KIN`, `BBN_CIRC`, `BBN_LEVELS`, `BBN_LONG`, `R996_*`, `PER_*` (listed; greyed until the script core is moved into the registry).

**How to read a PASS.** The class says what was compared. **V-UNIT**: the code matches a written equation. **V-CODE**: the code
reproduces a NASA table or NASA program output. **V-EXP**: the result is compared with a measurement. A V-EXP pass is only as strong as
its independence from tuning: if a parameter was set with the target in view, the pass is a *consistency check* and is labeled
**calibrated** (see the parameter register below).

**Importance** means what happens if the test is wrong or missing. *Critical*: an error silently changes every output. *Important*:
an error changes the cabin result in a specific band or mode. *Minor*: reporting or convenience.

| Test (report) | What it does | Why it is there | Importance | What a PASS proves, and the caveats |
|---------------|--------------|-----------------|------------|-------------------------------------|
| **Blocking Eq. (43)** (`blocking_p68.md`) | Evaluates F(γ) at γ = 0–90° against the values in CR-172428 p.68; checks that R2 gives about 4 dB at γ = 0 | Blocking scales every free-field pressure at the fuselage | Critical | The code matches the written equation (V-UNIT). It evaluates F at given angles, so it does not test how γ is computed from the geometry, and it does not show the equation is physically right (CR-172428 says scale-model blocking is 3–4 dB, off-plane reflection dies faster than Eq. 43). The R2 check is a loose 3.9–4.2 dB range. |
| **Grid geometry, 160 points** (unit test) | Checks the skin-point coordinates against the User Manual Fig. 3 formulas | Every observer position, γ, and joint-acceptance area comes from this grid | Critical | Coordinates match the manual (V-UNIT). Says nothing about the physics at those points. |
| **Grid extension unit checks** (unit test) | Checks falloff at 0/45/90°, phase sign, axis mapping | Code check for GEXT, which fills the grid from one measured line in the e11 path | Minor | Code does what it was written to do (V-ASSUMED). It does not show the cosine falloff is correct. Used only in the e11 path. |
| **Fig. E-11 digitization** (`e11_delta_dig.md`) | Compares two digitizations of the same figure; passes if max difference ≤ 1.0 dB | Input quality gate for the e11 source | Important | Shows the figure was read repeatably, not that the numbers are right. δmax = 1.0 dB sits exactly at the limit. Both readings use the same method. H = 3 values and all phases come from ANOPP Table 8, not from Fig. E-11 (see register). |
| **CYL2D vs Table C-1 and Fig. C-3** (`CYL2D_C1`; `cyl2d_table_c1.md`) | App. C scheme: compares all 20 frequencies and generalized masses with Table C-1 at 0.1 % (c0 = 341 m/s), the symmetry types, and the Fig. C-3 modes 0–5 node by node | Cabin modes set the resonances and coupling in the tone calculation | Important | Reproduces NASA's table (V-CODE), not an experiment. A pass shows the equations of App. C were implemented as written; the node rule r ≤ 1 + 0.4h and the tangential-gradient points are inferences that the table and figure confirm. Valid only for grids where B_E is non-singular and the spectrum is real (the paper's NY = 10 is one). |
| **MRP vs Table D-1, hybrid 32/32** (`MRP_D1`; `mrp_table_d1.md`, `run_pain.jl`) | Compares the production mode set with Table D-1 at 0.1% | Structural modes set the tone response | Important | **Circular.** The production modes take their frequencies and masses from Table D-1, so this passes by construction and tests nothing about the Ritz solver. |
| **T1 / T2 / REPRO_18b** (registry) | Same gates as the T1/T2/18b rows; GUI/scripts call `run_validation_case` | One implementation per case (phase 34) | Critical / Important | Same caveats as T1/T2/18b; plots show digitized reference vs computed. |
| **MRP raw Ritz vs Table D-1** (`mrp_ritz_vs_d1.md`) | Matches Ritz frequencies to D-1 within 5% by greedy nearest-frequency assignment | The only real test of the structural-mode solver | Important | 30/32 pass (modes 2 and 9 miss). Three scales (`k_scale`, `edge`, `floor`) were fitted to maximize this same count, so it is calibrated. Greedy matching is lenient. Not an experimental modal survey. |
| **Pipeline smoke** (`pipeline_smoke.md`) | Runs the synthetic free-field case through the whole chain | Catches crashes and wiring errors | Minor | The chain runs. Proves nothing about accuracy. |
| **T1 tonal** (`t1_tonal.md`) | Runs the e11 free field through blocking, modes, and the Eq. (8) PAIN core; compares interior SPL for H = 1–3 with Fig. E-16 | The only end-to-end test of the cabin model against measurement | Critical | Since 17a **not calibrated**: no parameter of the tone path is fitted to T1, and the test records the outcome instead of asserting it. The gate passes if the result is within 4 dB of the measured mean, *or* inside the measured envelope and within 4 dB of NASA's PAIN prediction. Envelopes are wide (H1 65–97 dB), and the means are visual digitizations (about ±2 dB). Result 90.2, 79.3, 83.2 dB (H1, H2 pass, H3 fails). H1 depends on a trim resonance (τ_t = 15.6 at 200 Hz), and NASA's own PAIN prediction at H1 was 11 dB below the mean. Conditional on the identifications in the trace table (Phase 17 report §1). Regrade in 18a |
| **T2 broadband** (`t2_third_octave.md`) | Compares 1/3-octave SPL at 1.25, 1.6, and 2 kHz with Fig. E-9, ±3.5 dB | The tonal model puts no energy in these bands; the high-frequency path (Eq. 19) fills them | Important | **Fails** (+11, +14, +17 dB). `bb_j2_scale = 0.5` was fitted earlier so these three bands passed and is stale with τ_t of Eq. (A.22) in the path; the absorption curve and the f⁻² slope are assumptions. Only three bands, nothing above 2 kHz. Replaced in 30b |
| **TS attribution** | If T1/T2 fail, substitutes Fig. E-7 bands to locate the error | Diagnostic | Minor | No script I read runs it. |
| **Trim / loss helper tests** (per `METHODOLOGY.md`) | Phase 16: 337 checks of App. A limits (empty stack, limp mass alone, zero thickness, det = 1, Eq. (A.14), passivity), Fig. A-2 knots, Si/Cin reference values, joint acceptances against quadrature, Eq. (77)–(83) limits. The surrogate E-14/E-15 curve tests were removed (13b) | Trim transmission and loss factors set the resonance peak heights | Important | Exact limits and quadrature only; not checked against laboratory material coupons. The NASA comparison is the E-14 script (`run_trim_loss_check.jl`), 7 of 18 bands, criterion not met. Since 17a `Pkg.test()` runs to the end because the T1/T2 test records instead of asserting |
| **Metrics dB(A) / SIL** (unit test) | Checks A-weighting and band-sum math | Reporting | Minor | The arithmetic is right (V-UNIT). |
| **F1A smoke** (`ccblade_f1a_smoke.md`) | Compares peak SPL on the ℓ = 1 line with ANOPP Table 8 | Sanity check that loads → pressure gives sensible levels | Minor | Δ ≈ 0 only because of the Table-8 peak calibration; the raw overprediction is about 5, 9, and 14 dB at H1–H3. Table 8 is ANOPP's prediction, not a measurement. Not a validation. |
| **BBN/Wilby phase check** (planned, plan phase 24) | Circumferential phase between microphone pairs (CR-158919 static, CR-159124 taxi) against B × m × Δψ, and relative in-plane levels of microphones 3–6; longitudinal pairs as X-EXTRAP | The first planned experimental check of the source block, run first for phase | Critical for the aircraft path | Kinematic part has no fitted parameters; microphones sit on a reflecting surface (scattering V-ASSUMED); axial pairs need an assumed blade. Criteria fixed in plan phase 23 first. Not yet run. |
| **Report 996 checks** (plan phases 26–27; I-07 re-run 2026-10-21) | CCBlade C_T / C_P; F1A vs Figs. 6, 7, 12–14 with scaled/unscaled loads | Source-block experimental check | Critical | **23c not met** (scaled ±2 dB 5/24; page-12 phase FAIL). Loads post-hoc label. See §2.3.3 — accuracy at listed cases only, not "better than". |
| **Gutin / Hanson cross-check** (optional, phase 27 / 33a) | F1A vs Report Eq. (2) and a Hanson near-field implementation on identical loads | Coding cross-check; needed only for a "better" claim | Optional | **Not run** (2026-10-21 close-out). No "better than" claim. |
| **Pereira forward-flight check** (planned, plan phase 28) | CCBlade T, Q and F1A harmonics 1–2 at 1 m vs measurement | The only planned check at a forward-flight operating point | Important | Far field only; polars generated here (spec in plan phase 28); ±1.7 dB measurement uncertainty. Not yet run. |

**Parameter register: values fitted or chosen with a test target in view.** Any result that depends on these is a consistency check,
not an independent validation.

| Parameter | Where | Set against | Effect |
|-----------|-------|-------------|--------|
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

**What can be quoted as validation today.** The blocking formula, the grid geometry, and the cabin-mode solver against Table C-1 are
code-level checks (V-UNIT / V-CODE). T1 and T2 can be quoted only as recorded results of the untuned chain (18a-r: H1/H2 NASA route only, H3 fails; T2 1 of 3), not as validation; the one stale
fitted parameter (`bb_j2_scale`) is named in the register. The MRP 32/32 result should not be quoted. The F1A smoke test is a sanity check. The source block gets an experimental
check only after the Report 996 phases (§2.3.1).

#### Test-article-specific values reachable from the aircraft path (phase 29a audit, 2026-10-21)

Each row is a hard-coded NASA test-article constant that can reach an aircraft run today. Guard/provenance (29b/29c) wait for [CONFIRM].

| File | Symbol / site | Value | Source |
|------|---------------|-------|--------|
| `trim_loss.jl` | `phase3_trim` defaults `a`, `L`, `theta0_deg` | 0.508 m, 1.803 m, 56.6° | CR-3813 App. E test article |
| `trim_loss.jl` | `phase3_trim` η_lining | 0.5 (Phase III); aircraft register default 0.05 | p. E-24 / register f |
| `trim_loss.jl` | PF-105 / Fig. A-2 insulation table | `data/fig_a2_pf105.csv` | App. A |
| `trim_loss.jl` | Phase III sidewall/end stacks, septum 6.58 kg, facing 0.095 kg/m² | as coded | App. E p. E-8 |
| `mrp.jl` | `MRP_T_SKIN`, stringer/frame areas and spacings, E, ν, ρ | 0.00081 m, … | App. D / MRP constants |
| `pain_core.jl` | wall mass fallback from `MRP_*` when `m_wall` NaN | smeared skin | same |
| `pain_core.jl` | `bb_j2_scale` default | 0.5 | stale T2 fit |
| `pain_core.jl` | Spbl H=3 anchor, f⁻² slope, absorption curve | as coded | V-ASSUMED / educated |
| `PAIN.jl` | `run_pain_pipeline` geometry defaults | L=1.803, a=0.508, θ0=56.6, r_p=0.965 | test article |
| `PAIN.jl` | hybrid Table D-1 modes when `use_table_d1=true` | 32 modes | Table D-1 |
| `cyl2d.jl` / pipeline | CYL2D NY=10, c0=340, ρ0=1.225 | defaults | App. C / register |
| `trim_loss.jl` | end-plate 1.3 cm aluminium mass path | as coded | App. E |
| `pain_core.jl` | η_n_bare default, C_struc default | 0.05, 3.0 | register g |

### 2.11 Cabin pre-registration (plan phase 13; dated 2026-10-20, before any run of phases 14–18)

Written before the first run of the 14a–18a chain. A value here is changed only with the change dated and the affected result relabelled calibrated with the parameter named (rule 3, §2.3.1). None of these values is tuned to T1 or T2. Each range is a sensitivity run recorded and carried into the uncertainty budget (plan phase 31).

#### 2.11.1 Assumption register for 15a–17a (13a)

| ID | Assumption | Default | Range / alternatives | Source | Bounding check |
|----|-----------|---------|----------------------|--------|----------------|
| a | CYL2D node rule: a node is in the cabin when r ≤ 1 + 0.4h | 0.4h | 0.32h–0.47h gives the same paper grid, row counts and modes (run in 15a: 0.31h gives a 4-node second row, 0.48h a 7-node fourth row; both then fail the real-spectrum check) | Inferred from Fig. C-3 | On other grids run both ends of the window; record the change |
| b | App. C on grids other than the paper's: the (C.4) tangential rule can make B_E singular | NY = 10 | Start at NY = 10, increase by 1 until B_E is non-singular and all eigenvalues are real to 1e-3; accept only if the next valid NY changes the first 20 frequencies by ≤ 1 % | Prototype (some θ0, NY combinations singular) | Record NY. No pseudo-inverse |
| c | Sound speed and density | c0 = 341 m/s for the Table C-1 comparison only; pipeline c0 = 340 m/s, ρ0 = 1.225 kg/m³ (input) | none | 341 m/s is the speed implied by Table C-1 | — |
| d | Axial truncation of 3-D modes (V-ASSUMED) | q ≤ ⌈2ω_H L/(π c0)⌉ | Accept when q_max + 2 changes ⟨p²⟩ by ≤ 0.1 dB, else raise q_max | CR-3813 does not state it | Convergence in q at H1–H3 (met under Eq. (8), 17a, `q_convergence.md`) |
| e | Insulation data: Fig. A-2 covers 100–6300 Hz and one material (PF-105, 9.6 kg/m³); Phase III default only | Fig. A-2 table | The aircraft trim is the user's table of λ_m, α, φ, \|W\| per frequency (29d). Outside the table range: error unless the user sets extrapolation; then log-log extension of the end segment, tagged X-EXTRAP and carried into the phase 31 band | CR-3813 App. A | — |
| f | Phase III values CR-3813 does not give (V-ASSUMED): facing/septum loss factor | **0.5 for `phase3_trim` (test article; author decision 2026-10-20)**; **0.05 aircraft-case default** (unchanged; range revisited in phase 31) | Aircraft 0.01–0.10. CR-3813 p. E-24: η_T = 0.5 for Fig. E-16/E-17; 0.5 and 1.0 for E-14/E-15. 18b-r (η_T = 0.5): +3.7, +0.2, +9.1 dB (`phase20_baseline.md`); original 18b at 0.05 kept as "not met, wrong η_T" | CR-3813 p. E-24 | Default changed 2026-10-20; 19i (2026-10-21): omitted D-1 terms |δ| ≤ 0.057 **not found** as H3 cause (`h3_followup.md`) |
| f | G-10 wavespeed | 3200 m/s | 2800–3600 m/s | — | Run and report |
| f | Facing side of each layer | Cabin side | Skin side | — | Alternative run and reported |
| f | Mechanical connections | 9 points + 2 floor-edge lines | Points only; lines only | — | Each alternative run and reported |
| g | η_n of a bare cabin (§3.8.1 says measured; an input) | 0.05 | 0.02–0.10 | — | Sensitivity run |
| g | C of Eq. (80) | 3 | 2–4 (CR-3813 range) | CR-3813 | Sensitivity run |
| h | Areas: A in Eqs. (8) and (52); Ā in Eq. (81); A in Eq. (A.19) | A = L(Lp + 2a(π − θ0)); Ā = 2πaL; A = 2a(π − θ0)L | none | Normalization of Eq. (52); full-circumference coordinates of Eqs. (62)–(65); curved sidewall | — |
| i | η_r'' of Eq. (83) | Applied to every (n, r) pair (its own resonance factor limits it) | Variant restricted to \|ω_r − ω_n\| ≤ η_nω_n/2 ("typically", §3.8.2), reported | CR-3813 §3.8.2 | Both reported |
| j | Plate modal density n = A√3/(2πhc) in Eq. (A.19) | as written | none | V-ASSUMED | — |
| k | Table D-1 shapes, all 32 modes, transcribed from the page scans 2026-10-20 (modes 2 and 16 frequencies corrected); Ritz shapes converted to the Eqs. (46)–(49) convention | as transcribed | — | CR-3813 Table D-1 | Comparison in 17d: equal to `data/digitized_table_D1.csv` in all 32 modes. 19g: Fig. D-2 mode-1 shell shape within the print-column quantization (0.026 of the figure's peak 1.0, criterion 0.05 met); floor shape 0.057 from the figure at the outer points (criterion 0.05 **not met**, digitization ±0.005; omitted Table D-1 terms are a possible cause, untested) (`fig_d2_check.md`) |

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

The statistic and inputs below were fixed before `scripts/run_trim_loss_check.jl` was first run; the numbers in 13b above are unchanged.

| Item | Definition |
|------|------------|
| E-14 statistic (V-CODE) | Eq. (78), η̄_n = 8c0/(4ωV)[ξS + 2ξ_eS_e], evaluated at each one-third-octave band centre 100–5000 Hz (18 bands), with ξ = Re β and ξ_e = Re β_e from Eq. (A.16) |
| E-14 inputs | Phase III stacks of App. E p. E-8 (`phase3_trim`): sidewall = four layers (1.3 cm PF-105 + 0.095 kg/m² facing each, facing on the cabin side) + septum 6.58 kg over 2a(π − θ0)L; end plates = one layer + facing on a rigid backing; wall mass m = 3.23 kg/m² (smeared skin, `MRP_*` constants); S = 2a(π − θ0)L, S_e = V/L, V = `cabin_volume`; c0 = 340 m/s, ρ0 = 1.225 kg/m³. Facing and septum loss factor 0.5 and 1.0, the two values NASA used for its curves (not the register default 0.05, which is for the aircraft case) |
| E-14 target | `data/e14_acoustic_loss_calculated.csv`, digitized from the two calculated curves |
| E-14 pass rule | Each band: \|η̄_computed/η̄_NASA − 1\| ≤ 0.25. Reported: bands passing of 18, per trim loss factor. A miss is recorded, not tuned |
| Eq. (77) mode averages | Diagnostic, recorded without a pass mark: mean of η_n over the cabin modes whose frequency falls in the band |
| E-13 | Fig. E-13 holds **measured** points only (no calculated curve), so the ±0.05 criterion of 13b has no target. ᾱ from Eq. (24) is compared with the measured points as V-EXP, no pass mark. Recorded 2026-10-20 |
| Fig. A-2 / App. A | τ_t, C_w, β are checked by the exact limits of 16a (empty stack, limp mass alone, zero thickness, det = 1, passivity Re β ≥ 0); no NASA numbers exist for them |

**Result and status (16a–16b done 2026-10-20).** E-14 (V-CODE): 7 of 18 bands within ±25 % at trim loss 0.5 and 7 of 18 at 1.0; the criterion is not met (`trim_loss_e13_e14_e15.md`; per-band table and the failing bands in the plan, phase 16). Register items e (Fig. A-2 as `data/fig_a2_pf105.csv`, range error and flagged extrapolation), f (`phase3_trim` keywords), g (`C` of Eq. 80, bare η_n is an input to 17a) and j (plate modal density in `MechanicalPath`) are implemented. Added V-ASSUMED items: end plates on a rigid backing (mass not stated in CR-3813; it sets ξ_e and so the E-14 result above 600 Hz), wave-impedance phase sign W = |W|e^{+iφ} (checked by Re β ≥ 0), and Fig. A-2 read at six frequencies (|W| at 1000 Hz from the curve, not the marker). The sensitivity runs of the register ranges were made with the Eq. (8) chain on 2026-10-20 (`scripts/probe_t1_levels.jl`, table in `validation_reports/pain_core_eq8_phase17.md` §5): η_n 0.02–0.10 moves H2, H3 by up to 4.5 and 6.7 dB, C 2–4 by ≤ 0.1 dB, lining loss 0.01–0.10 by up to 2.4 dB (H1) and 5.1 dB (H3), the facing side by 2.5 dB at H1; no range brings H3 within 13 dB of the measured mean. Item d (q truncation) is met under Eq. (8). Printed-equation findings carried to 17a: Eqs. (69), (70), (63) are half the mode-normalized joint acceptance for n > 0 (`mode_normalized` option, default as printed); the Eq. (82) limp-mass limit.

#### 2.11.4 Criterion for the PAIN reproduction check (18b; dated 2026-10-20, written before the run)

| Item | Definition |
|------|------------|
| Purpose | Show the chain computes what NASA's PAIN computes (V-CODE), separately from agreement with measurement (18a) |
| Inputs | ANOPP Table 8 free field (`data/anopp_table8_spl_dB.csv`, `anopp_table8_phases_deg.csv`) in place of the measured Fig. E-11 line; full Eq. (43) blocking, variant R1; Phase III trim stacks (`phase3_trim`, register defaults); 20 CYL2D modes, 32 Table D-1 modes, q ≤ ⌈2ω_H L/(π c0)⌉; BPF 200 Hz. Off-line grid points by GEXT on Table 8 (17j found no full-grid ANOPP output), so the result is conditional on GEXT (V-ASSUMED, phase 32) |
| Target | `nasa_pain_pred_dB` of `data/t1_interior_targets.csv` (NASA PAIN circles of Fig. E-16): 79.0, 75.5, 68.0 dB at H1–H3 |
| Criterion | \|computed − target\| ≤ 2 dB (Fig. E-16 digitization uncertainty) + 2 dB = **4 dB at each harmonic** |
| A miss | A finding on the chain, localized with 17c–17i; not a reason to tune |
| Result (run 2026-10-20) | **Not met, 0 of 3.** R1, Phase III trim: 91.92, 80.01, 84.87 dB, i.e. +12.9, +4.5, +16.9 dB against 79.0, 75.5, 68.0. Diagnostics (not the criterion): R2 90.06, 78.20 (within 4 dB), 83.15; bare cabin 92.22, 83.65, 83.58. At H1 modes 8 (318.7 Hz) and 6 (301.9 Hz) carry 91 % of the sum with τ_t = 15.6. `pain_reproduction_e16.md`, `scripts/probe_modal_contributions.jl`. **Phase 19 (2026-10-20) isolated the largest cause: the registered run used the facing/septum loss factor η_T = 0.05, NASA's text gives η_T = 0.5 for these predictions (p. E-24).** Swapping only that input (whole trim rebuilt): 82.73, 75.73, 77.05 dB, i.e. +3.7, +0.2, +9.1 dB, H1 and H2 within 4 dB, H3 not (η_T = 1.0: +0.3, −0.7, +6.7). Not adopted and not a re-registered pass: the registered result stays "not met". Ruled out as the cause (each swap moves a harmonic by < 3 dB toward NASA, or in the wrong direction): the Eq. (8) algebra and (mA/4)²τ_ML (19a–19b), ε_n for q > 0 (19c: read as printed), mirroring (19d: 160 points, no mirroring), the W phase sign, facing side or septum (19e), the E-14 η_n and E-15 η_r (19f), the unbarred f′ of Eq. (83), Fig. D-2 and Eqs. (D.22)–(D.26) (19g: not on the production path), the η_r normalization (19h, as printed). Open: H3 at +9.1 dB (+6.7 at η_T = 1.0). Reports: `bisect_18b.md`, `tau_t_variants.md`, `eps_n_quadrature.md`, `grid_mirroring.md`, `fig_d2_check.md`, `eta_r_normalization.md` |

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
- **23a / 24c:** FAIL — 26/168 rows (15%) within tolerance (`bbn_phase.md`).
- **23b / 24d:** reported X-EXTRAP in `bbn_phase.md`.
- **23c / 27:** FAIL — scaled Fig.14 sample 5/24 within ±2 dB; page-12 |Δφ−155°|=51.2° (`report996_acoustics.md`; I-08 L51C27 on Fig.13a).
- **23d / 28:** FAIL on H1 (0/9 within ±1.7 dB vs Fig.9 Exp at 80 dB as read); H2 6/9 within ±3 dB (`pereira_forward_flight.md`).
- Phase **26** loads keep the post-hoc label "criteria registered after the loads were computed".

---

## 3. What “valid recreation” means for this project

A recreation is **pipeline-valid** only if:

1. **Blocking** matches Eq. (43) within **0.06 dB** (R1) and R2 scaling is explicit.  
2. **CYL2D / MRP** match Table C-1 / D-1 within flowchart tolerances (**V-CODE**).  
3. **PAIN core** with **measured / digitized free-field** (Fig. E-11 path) reproduces App. E tonal tests within the published scatter (**V-EXP**).  
4. **CCBlade + AcousticAnalogies** is treated as an **alternate free-field generator**; its outputs are **X-EXTRAP** for the aircraft application (phase 33 close-out 2026-10-21: BBN 24c, Report 996 23c and Pereira 23d did not meet frozen tolerances; Gutin/Hanson optional cross-check not run). See §2.3.3.

Do **not** claim that replacing ANOPP with CCBlade/F1A inherits NASA’s exterior-noise validation. Claim inheritance only for the **transmission / cabin** model after the free-field grid interface.

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
