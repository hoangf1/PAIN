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

**Read by validation chunk.** The validation map's groups are the chunks. Each one is checked on its own, because no single source covers the whole chain. The case records in §2.13 are grouped by chunk in this order. The narrative sections below keep their numbers because other files cite them.

| Chunk (map group) | Blocks | Narrative and criteria | Pre-registration | Case records | `METHODOLOGY.md` |
|---|---|---|---|---|---|
| 1 Aircraft BEMT+F1A (`G_AIR`) | A_GEO, A_LOADS, X_F1A, X_FF, A_AMP, A_PHASE, A_FWD, A_SURF | §2.3 | §2.12 | §2.13 Chunk 1 | §2.3 |
| 2 Free field (`G_FF`) | P_FF, X_SRC | §2.1 | §2.11.1 | §2.13 Chunk 2 | §2.2 |
| 3 Grid and blocking (`G_GRID`) | P_GRID, P_BLK, X_BLK_OUT | §2.2 (grid extension), §2.4 (blocking) | §2.11.1 | §2.13 Chunk 3 | §2.2, §3 |
| 4 Structural modes (`G_MRP`) | X_MRP_IN, P_MRP, X_MRP_OUT | §2.5 | §2.11.1 | §2.13 Chunk 4 | §5 |
| 5 CYL2D (`G_CYL`) | X_CYL_IN, P_CYL, X_CYL_OUT | §2.6 | §2.11.1 | §2.13 Chunk 5 | §4 |
| 6 Trim and loss (`G_TRIM`) | X_TRIM_IN, P_TRIM, X_TRIM_OUT | §2.7 | §2.11.2–2.11.3 | §2.13 Chunk 6 | §6.1 |
| 7 PAIN main (`G_PAIN`) | X_PAIN_IN, P_EQ8, X_OUT | §2.7 | §2.11.1 | §2.13 Chunk 7 | §6.2 |
| 8 Validation comparisons (`G_VAL`) | P_REPRO, P_MEAS, A_CABIN | §2.8, §2.9 | §2.11.4–2.11.5 | §2.13 Chunk 8 | §6.3, §7 |

Settings registers (§2.10) and the closure register of not-met cases (§2.14) cover all chunks.


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
| **Cabin mode animation (phase 36)** | GUI **Cabin modes** tab + `src/mode_animation.jl`: φ_n(x,y)·cos(ωt) on the full section (mirrored App. C grid), Fig. C-3 overlay for modes 0–5, Eq. (C.9) axial factor, optional Table D-1 ψ and f′. Fixed `CYL2D_C1` inputs. **Display only, no claim** — no criterion, no verdict, no tuning; nothing feeds a result. Interpolation is for drawing only (node values unchanged). |

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
`run_validation_case(id)` / scripts). Plots go to `docs/validation_reports/figures/<block folder>/<id>.png`, one folder per validation-map block (`F1A_amplitude/`, `CCBlade_BEMT/`, `Forward_flight/`, …; table `VALIDATION_FIGURE_DIRS` in `validation_plots.jl`; moved 2026-10-27, files only, no result changed), with error panel since 2026-10-21.
Cases are read-only. Third tab **"Validation map"** (`src/validation_map.jl`): single horizontal map `total` (aircraft + e11 + cabin + checks);
stage frames from each group's own blocks only (disjoint layout in §2.13); clickable case chips; Validation-tab list ordered by map and block. **Greyed (Run disabled):** none (`R996_FIG8` removed
I-20; `E21_E22_NR` runnable since 38a). **In-process runnable:** `CYL2D_C1`, `MRP_D1`, `MRP_RITZ`, `MRP_APPD`, `BLK_P68`,
`F1A_GUTIN`, `T1`, `T2`, `REPRO_18b`, `E12_BLOCK`, `E11_FREEFIELD`, `UT_GRID`, `E14_LOSS`, `GEXT_BOUND`, `BBN_KIN`, `R996_PHASE`,
`E21_E22_NR` (Eq. 18, η_T = 1.0, η_r′ ≤ 0.15; criterion dated 2026-10-21), `T2_EQ19` (printed Eqs. 19–23; T2
criterion unchanged; first run 2026-10-22), `E18_TONES` (Fig. E-18, η_T = 1.0, η_r′ ≤ 0.15; criterion dated
2026-10-21; first run 2026-10-22), `E15_STRUCT_LOSS` (Fig. E-15 η_r′, V-EXP info, no pass mark; first run 2026-10-22),
phase-40 `ISO_BLOCKING` / `ISO_FF_CONV` / `ISO_GEXT_LINE` / `ISO_TABLE8` / `ISO_CYL2D_EXACT` / `ISO_JOINT_ACC` /
`ISO_MODAL_DENSITY` / `ISO_BB_BAND` / `ISO_CYL2D_BOUNDARY` / `ISO_SIL` (criteria 2026-10-23; all met;
`ISO_BB_BAND` reference corrected to the closed-form integral and code matched 2026-10-23;
`ISO_RITZ_DONNELL` not registered — Ritz stiffener I not removable via options);
phase-41 `T1_FROM_E12` / `TRIM_CLOSED` / `NR_BAND_HAND` / `HF_MASSLAW` / `BEMT_HAND` / `F1A_INDEP`
(criteria 2026-10-23; analytic five met; `T1_FROM_E12` not met 2/3 — cabin chain implicated);
phase-43 `T1_MEAS_DAMPING` / `T1_F1A_FILL` / `NR_TP1964` / `NR_TP1964_REF2` / `H3_ATTRIB` / `T1_F1A_MEAS_DAMP`
(criteria 2026-10-23; see case entries).
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
eport996\polars_forced_merged.json` | Chosen before the comparison. Merged grid mixes XFOIL builds (sibling: Linux double precision; new: Windows 6.99). 2026-10-22: 1,420 points added to 109 entries that were empty or stopped below α = 8° (same settings, streamed sweeps with restart after a hang; existing points unchanged; 50 thin-section entries still short, listed in the file header); `data/polars/xfoil_regen_2026_10_22.py` | Report 996 loads |
| Report 996 XFOIL settings, Phase 69 (fixed 2026-10-28 before any run): free transition; **N_crit 8, fitted to NACA TN 1546** c_l of 16-506 and 16-509 (author 2026-10-28: calibration allowed because XFOIL is not under test); 16-312 held out; 240 panels; ITER 200; Re 1.5·10⁵–2·10⁶ (8 values); M 0.1–0.9 (9 values); α −6° to 20° | `data/report996/polars_phase69_ncrit8.json`; fit `data/polars/phase69_ncrit_fit.md` | Calibrated to TN 1546, never to Report 996 data. POLAR_FIDELITY's verdict is on 16-312 only. Used by every Report 996 case from 2026-10-28 | Report 996 loads, PROP_BB_* |
| Viterna extension (fixed 2026-10-20, phase 11c): CCBlade 1.0.0 `viterna`, 50 points per side, α_stall = α at max converged c_l, c_d,max = max(max c_d, 1.11 + 0.018/cr75), cr75 0.1251 (Report 996) / 0.1558 (Pereira); Re, M clamped to the set's grid range, bilinear in (log Re, M); non-extendable polars replaced by the nearest usable (Re, M) of the same section | `data\polarsiterna_extension.json` | Rules chosen before the comparison. Stall values: Report 996 median α_stall 7.5°, c_l,max 0.94; Pereira N_crit 9 median 15.0°, 1.37. 143 of 300 Report 996 polars end before a true stall | Inboard loads |

**What can be quoted as validation today.** The blocking formula, the grid geometry, and the cabin-mode solver against Table C-1
(ratio form, 2026-10-21) are code-level checks (V-UNIT / V-CODE). T1 and T2 can be quoted only as recorded results of the untuned
chain (18a-r: H1/H2 NASA route only, H3 fails; T2 1 of 3), not as validation; the one stale fitted parameter (`bb_j2_scale`) is
named in the register. The MRP hybrid transcription (`MRP_D1`) and the calibrated raw Ritz guard (`MRP_RITZ`) should not be quoted
as passes. The F1A smoke test is a sanity check. The source block gets an experimental check only after the Report 996 phases
(§2.3.1). Free-field amplitude convention (I-17) is open.

#### Test-article-specific values reachable from the aircraft path (phase 29a audit, 2026-10-21; guard 29b/29c 2026-10-22)

Each row is a hard-coded NASA test-article constant that can reach an aircraft run. **29b/29c done 2026-10-22:** an aircraft run (`aircraft_json=…`) warns once, fills `result.provenance.nasa_defaults`, and labels the printed-outputs header / GUI status when any of these is used without a user `assumed`/`measured` tag. Cabin JSON keys under `cabin` (and existing 38f card keys) accept plain numbers or `{"value":v,"tag":"measured"|"assumed"|"nasa_default"}`. Validation / `:e11` / `:synthetic` paths are unchanged (no guard).

| File | Symbol / site | Value | Source | Guard (29b) |
|------|---------------|-------|--------|-------------|
| `trim_loss.jl` | `phase3_trim` defaults `a`, `L`, `theta0_deg` | 0.508 m, `test_article_length()` (default 1.83 m), 56.6° | CR-3813 App. E test article; L via `TEST_ARTICLE_L` (I-22 default 1.83 m, 2026-10-22) | yes — when `trim=:phase3` |
| `trim_loss.jl` | `phase3_trim` η_lining | 0.5 (Phase III); aircraft register default 0.05 | p. E-24 / register f | yes — with Phase III path |
| `trim_loss.jl` | PF-105 / Fig. A-2 insulation table | `data/cr3813/fig_a2_pf105.csv` | App. A | yes — with Phase III path |
| `trim_loss.jl` | Phase III sidewall/end stacks, septum 6.58 kg, facing 0.095 kg/m² | as coded | App. E p. E-8 | yes — with Phase III path |
| `mrp.jl` | `MRP_T_SKIN`, stringer/frame areas and spacings, E, ν, ρ | 0.00081 m, … | App. D / MRP constants | yes — via `m_wall` fallback |
| `pain_core.jl` | wall mass fallback from `MRP_*` when `m_wall` NaN | smeared skin | same | yes — `m_wall_kg_m2` / `cabin.m_wall_kg_m2` |
| `pain_core.jl` | `bb_j2_scale` default | 0.5 | stale T2 fit | yes — unless `cabin_blocks=:parametric` / `broadband_model=eq19` or user supplies scale |
| `pain_core.jl` | Spbl H=3 anchor, f⁻² slope, absorption curve | as coded | V-ASSUMED / educated | yes — `spbl_anchor_H`, `bb_alpha`; absorption when surrogate only |
| `PAIN.jl` | `run_pain_pipeline` geometry defaults | L=`test_article_length()` (default 1.83), a=0.508, θ0=56.6, r_p=0.965 | test article | yes — `cabin.L_m` / `a_m` / …; on `:parametric` these are inputs (no hard-coded path after JSON) |
| `geometry.jl` | `TEST_ARTICLE_L` / `test_article_length()` | default **1.83 m** (I-22); App. D follows `test_article_length()` | I-22 decision 2026-10-22; re-record `length_rerecord_before_after.md` (from `length_sensitivity.md`; no length selected from any error) | yes — with `L_m` |
| `PAIN.jl` | hybrid Table D-1 modes when `use_table_d1=true` | 32 modes | Table D-1 | yes — `cabin.structural_solver`; **not** on `cabin_blocks=:parametric` (uses App. D) |
| `mrp_appd.jl` / pipeline | App. D skin/stringer/frame/floor (`MRP_*`) when `:appd` | as coded | App. E / Manual §5.2 | yes — `cabin.t_skin_m` … `rho_struc_kg_m3` (30c) |
| `PAIN.jl` | `cabin_blocks` default | `:auto` → `:parametric` on aircraft, `:surrogate` else | phase 30 | aircraft HF = Eq. 19–23 (I-21 X-EXTRAP); validation paths unchanged |
| `cyl2d.jl` / pipeline | CYL2D NY=10, c0=340, ρ0=1.225 | defaults | App. C / register | yes |
| `pain_core.jl` / pipeline | `L_c` default = fuse.L, `d` = 0; `rotation_direction` = +1; `bands` / `η_r_band` / `η_n_band` default `nothing` | card 9 / 36 / 3–6 / 11–18 defaults | Manual §5.4; 38f-1, 38f-2 | yes |
| `printed_outputs.jl` (38h) | Manual §5.4.3 tables from existing APIs; lower-quarter pressures not computed (I-18 note); no criterion | report / GUI only | Manual §5.4.3; plan 38h | report header echoes 29b/29c labels |
| `trim_loss.jl` | end-plate 1.3 cm aluminium mass path | as coded | App. E | yes — with Phase III path |
| `pain_core.jl` | η_n_bare default, C_struc default | 0.05, 3.0 | register g | yes |

### 2.11 Cabin pre-registration (plan phase 13; dated 2026-10-20, before any run of phases 14–18)

Written before the first run of the 14a–18a chain. A value here is changed only with the change dated and the affected result relabelled calibrated with the parameter named (rule 3, §2.3.1). None of these values is tuned to T1 or T2. Each range is a sensitivity run recorded and carried into the uncertainty budget (plan phase 31). **Phase 31 first run 2026-10-22** (`src/uncertainty.jl`, `UNC_COVER` `:not_met`, reports `uncertainty_budget_testarticle.md` / `uncertainty_aircraft_band.md`): MC N = 4000, seed 20261022, OAT keep > 3 dB; H1 inside P5–P95, H2/H3 miss (margins −5.46 / −8.09 dB); kept `freq_scale`+`eta_t` (test article) / `eta_n_bare` (aircraft); aircraft H1–H3 P5/P50/P95 99.31/101.41/104.21, 58.47/59.07/59.94, 35.45/35.65/36.26; k=−2.09, B=3; phase (i) dominates H2/H3. Nothing widened. The aircraft band is epistemic (not a CI, not a validation).

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
| note (2026-10-22) | Pre-registered 23a FAIL was 26/168 under a reversed pair reading. Pair convention φ_b−φ_a from CR-158919 §3.4/Table 8 found after that result; re-run is post-hoc. Criterion row unchanged. |

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
- **23a / 24c:** Pre-registered FAIL 26/168 (15%) on record (2026-10-21, reversed pair reading). Post-hoc re-run 2026-10-22 with CR-158919 §3.4/Table 8 pair convention: **134/168** (79.8 %, below the 80 % pass rule) → FAIL (`bbn_phase.md`); registry `BBN_CIRC` replays the CSV.
- **23b / 24d:** reported X-EXTRAP in `bbn_phase.md`; `BBN_LEVELS` no verdict (20/32 within ±3 dB, X-EXTRAP).
- **23c / 27:** FAIL — scaled Fig.14 sample 5/24 within ±2 dB; page-12 |Δφ−155°|=51.2° (`report996_acoustics.md`; I-08 L51C27 on Fig.13a). **Registry replays (phase 35):** `R996_FIG14` not met 5/24 (= recorded); `R996_FIG13A` not met 6/14 (= recorded); `R996_FIG12` not met **19/40** (first verdict under the frozen 23c rule; no count was recorded before); `R996_PHASE` reads 155°/165° from `tr996_phase_values.csv` and F1A 103.8° from `f1a_results.csv`. **Polar re-run 2026-10-22 (post-hoc, 23c unchanged):** R996_LOADS 6/32 (unchanged), R996_FIG14 20/24 met (unchanged), R996_FIG13A 8/14 (unchanged), R996_FIG12 21/40 (was 22/40), page-12 phase 109.0° (was 103.8°; FAIL); Fig. 14 table scale factors at M_t 0.75/0.90 move to s_T 1.275/1.316 (from 1.364/1.521); Viterna evaluations per loads run 2511 → 2284.
- **23d / 28:** FAIL on H1 (0/9 within ±1.7 dB vs Fig.9 Exp at 80 dB as read); H2 6/9 within ±3 dB (`pereira_forward_flight.md`). Replays: `PER_FIG9` not met (H1 0/9, H2 6/9); `PER_FIG8` not met (H1 1/7, H2 6/7); `PER_FIG7` not met (Δψ₁ 2/3 within ±5°); `PER_FIG6` / `PER_LOADS` no verdict (no frozen criterion).
- Phase **26** loads keep the post-hoc label "criteria registered after the loads were computed"; registry `R996_LOADS` 6/32 within ±15 % (not met; same post-hoc label).

---


## 2.13 Validation case reference (read by the GUI)

Machine-readable case/map/block text for the Validation and Validation-map tabs. Format: `### Map: id` / `#### Block: id` / `### Case: id` with bold `**Field:**` lines; the GUI parser in `src/validation_map.jl` depends on this layout. Both the Validation tab and the Validation map tab read these fields (`valInfo` / `mapDetail` / block `what_it_does` / map `what_is` / `how_to_read`). Optional per-block layout fields: `**Position:** col,row` (integers, columns left→right), `**Feeds:** id1, id2` (edges; every id must exist), `**Group:**` stage id, `**Role:**` `input`|`function`|`output`|`check`, and once per group `**Group title:**`. Defaults (0,0 / empty feeds / empty group) keep older blocks parseable. Case records follow the map, grouped by chunk (`### Chunk n:` headings, ignored by the parser) in map order, and block by block within a chunk. The order within a block is the chip order on the map. A new case goes under its block, at the position its chip should take. Choose `(col,row)` so stage group rectangles (axis-aligned bounds of each group's own blocks, including check chips) are pairwise disjoint and no block sits inside another group's rectangle; aircraft check blocks sit above/below the Aircraft pipeline so that group's box grows to include them without covering Free field. The GUI shows the single map `total` (aircraft path + e11 path + cabin chain + every check) on a horizontally scrolling canvas; block titles only on the boxes, case chips with verdict dots as before. Abbreviations used below: ANOPP = NASA Aircraft NOise Prediction Program (free-field source tables); GEXT = assumed grid extension from one measured line to 160 skin points; T1 / T2 = tonal / 1/3-octave interior checks vs App. E; R1 / R2 = blocking Eq. (43) revisions; γ = incidence angle; ℓ = 1 = propeller-azimuth grid line; H1–H3 = blade-passage harmonics 1–3; BPF = blade-passage frequency; η_T = trim loss factor; F1A = Farassat formulation 1A.

### Map: total
**Title:** Whole program: aircraft source → grid → blocking → cabin chain → interior SPL, with every validation check
**What this map is:** One left-to-right flowchart of the whole program. Two free-field sources meet at Source select: (1) aircraft CCBlade BEMT → F1A, (2) the e11 measured line / ANOPP Table 8. Shared hand-off: 160-point grid → Blocking Eq. 43 → PAIN main, with Structural modes, CYL2D, and Trim/loss feeding the cabin chain in parallel. Output is Interior SPL; validation chips sit on check blocks that branch from stage outputs. A pass on a chip means that stage's stated check; aircraft cabin SPL stays X-EXTRAP.
**How to read it:** Stages are labelled groups (rounded frames; each frame bounds only that stage's blocks). Inside each stage: input → function → output (titles only). Aircraft checks sit above/below the BEMT→F1A chain inside the Aircraft group; Free field is the next column so frames do not overlap. Solid arrows follow **Feeds**; dotted arrows from outputs to check chips. Border colour on a chip is the evidence kind; the coloured dot is the last run verdict in this GUI session (green = met, red = not_met, grey = no_verdict, empty ring = not run). Under the title, a short error line (display only) shows `k/n · max|err| U` (or `no verdict · max|err| U` when the case has no pass mark), with the result source date on a second tiny line; the detail panel keeps the full max/median text (`_row_error`; unit `%`, `dB`, or the text inside the last `(...)` of `error_ylabel` / else `ylabel`, else `abs`). `:none` cases with a met/not_met verdict and a non-empty table show `n_within/n_rows within criterion` instead. It is not a criterion. Click a block for what_it_does / code; click a chip for the case detail. Scroll horizontally and vertically; zoom / fit if shown. Kind tags: runnable / replay / pkgtest / deferred. Each Explanation ends with Inputs / Equations / Outputs lines.

#### Block: A_GEO
**Title:** Aircraft inputs
**What this stage does:** Loads airfoil lift/drag tables and aircraft JSON geometry that CCBlade needs before any thrust or noise. First aircraft stage. Code: `polars.jl`, aircraft JSON.
**Code:** polars.jl, aircraft JSON
**Group:** G_AIR
**Group title:** Aircraft BEMT+F1A
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
**What this stage does:** Hand-off note: aircraft free-field on the 160-point grid feeds the cabin chain. Aircraft cabin SPL stays X-EXTRAP — no aircraft interior measurement is used.
**Note:** Aircraft cabin SPL is X-EXTRAP: no aircraft interior measurement is used; epistemic uncertainty band (phase 31) is not a validation
**Group:** G_VAL
**Role:** check
**Position:** 12,5
**Feeds:**

### Chunk 1: Aircraft BEMT+F1A (`G_AIR`)

Blocks in map order: `A_GEO` Aircraft inputs → `A_LOADS` CCBlade BEMT → `X_F1A` F1A source → `X_FF` Free field p → `A_AMP` F1A amplitude → `A_PHASE` F1A phase → `A_FWD` Forward flight → `A_SURF` Surface levels. Cases are listed block by block, in the order the map shows them.

### Case: UT_POLAR
**Title:** Polar loader (Pkg.test)
**Map / block:** total / A_GEO
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

### Case: POLAR_R996
**Title:** Report 996 polars (display)
**Map / block:** total / A_GEO
**Category:** display
**Kind:** runnable
**Source:** `polars_forced_merged.json` via `load_polar_set`; Viterna via CCBlade.viterna; TN 1546 measured overlay via `measured_polar_series`; section ops from CCBlade (same path as `evaluate_propeller_source`)
**What it tests:** Nothing — display of the XFOIL/Viterna polars, TN 1546 measured overlay, Mach gap to tip, and where R996_LOADS / FIG12 / FIG13A / FIG14 blade sections operate (Mach, α, Re).
**Why it is here:** The Validation tab shows BEMT/F1A results that use the polars, not the polars; many runs sat outside the forced-transition grid (Mach ≤ 0.72, α −6°–14°, Re from 3×10⁵). Since 2026-10-28 the case shows the Phase 69 set (free transition, N_crit 8; Mach 0.1–0.9, α −6°–20°, Re 1.5×10⁵–2×10⁶; XFOIL converges poorly at M 0.9).
**A pass means:** display only (verdict always `:no_verdict`; no criterion).
**Not covered:** Not a load or acoustic check; measured data are display only (BEMT does not read them); Re in the coverage panel uses μ_air = 1.78×10⁻⁵ for display (production CCBlade still uses default μ = 1).
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
**Source:** NACA TN 1546 Fig. 3(j), 3(n), 3(o) (digitized 2026-10-22); `polars_forced_merged.json`; criterion 2026-10-24, before the comparison
**What it tests:** The XFOIL section polars the Report 996 cases use, against the measured c_l of the three exactly matching sections (16-312, 16-506, 16-509) at the TN 1546 angles and the XFOIL Mach grid (0.4–0.72), XFOIL at the TN 1546 Reynolds number.
**Why it is here:** The code checks of BEMT and F1A pass, yet the Report 996 loads and acoustics miss; this tests whether the section polars are the cause.
**A pass means:** |Δc_l| ≤ 0.05 at ≥ 75 % of the matched points.
**Not covered:** The other blade sections (no measured data); c_d (shown, no criterion); wall-interference corrections (TN 1546 is uncorrected).
**Recorded outcome:** **not met**, 9/60 (15 %) (first run 2026-10-24; `phase67_source_attribution.md`). XFOIL is 0.15–0.35 below the measured c_l at low α on all three sections and at every Mach number; the gap closes toward the high-α end. Post-hoc consistency (2026-10-24): the BEMT thrust of the Report 996 cases is 25–32 % below the measured thrust (scale factors s_T = 1.25–1.32, 7 of 10 primary cases), the direction and size a low c_l gives. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** free transition, N_crit 8 fitted to 16-506/16-509 (69b), Phase 69 grid at the TN 1546 Re(M) and M. Verdict now on the held-out 16-312 only: **not met, 13/26** (50 %). 16-506 13/15 and 16-509 14/20 are shown as N_crit fit points with no verdict. The Phase 67 explanation (forced transition) holds for most of the gap; the rest is the 12 %-thick section.
**Explanation:** Input fidelity, not code: the polars are XFOIL with forced transition. The Report 996 source misses are therefore a documented limitation of the section-data approximation (XFOIL), not of the BEMT or F1A implementation, which pass their closed-form checks (Phases 41, 64, 66). No polar or load was changed.
Inputs: TN 1546 Re(M) = 0.85·10⁶ + 1.15·10⁶ (M − 0.3)/0.5 (TN 1546 p. 5 range; reading fixed before the comparison); XFOIL tables at 1·10⁶ and 2·10⁶, linear in log Re; no extrapolation in α.
Equations: —
Outputs: Δc_l per (section, M, α).

### Case: R996_LOADS
**Title:** Report 996 CCBlade loads
**Map / block:** total / A_LOADS
**Category:** calibrated
**Kind:** replay
**Source:** RM L8H25a, Report 996 Fig. 14 table, Fig. 7 legend
**What it tests:** CCBlade BEMT thrust and torque coefficients C_T, C_P vs measured.
**Why it is here:** Load error swamps acoustic error.
**A pass means:** C_T, C_P within ±15 % (23c).
**Not covered:** Criteria registered after the loads were computed (post-hoc); polars XFOIL + Viterna.
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
**Source:** CCBlade residual (F=1); phase 41e criterion 2026-10-23
**What it tests:** Project BEMT wrapper thrust/torque for constant-chord, constant-twist blade with cl = 2π α, cd = 0, tip loss off, against a hand blade-element/momentum solution written in the case.
**Why it is here:** Isolates BEMT integration for failing R996_LOADS.
**A pass means:** T and Q within 1 %.
**Not covered:** Real XFOIL polars; Prandtl tip loss (off here); experimental loads.
**Recorded outcome:** **met**, 2/2 (first run 2026-10-23)
**Explanation:** Isolated analytic check: hand residual matches CCBlade `residual_and_outputs` with F = 1; trapz pad at hub/tip as `thrusttorque`; compared via `evaluate_propeller_source(...; use_tip_correction=false)`.
Inputs: Rtip = 1 m, Rhub = 0.2 m, B = 2, chord = 0.1 m, twist = 15°, Vinf = 20 m/s, rpm = 1200.
Equations: BEM induction residual (CCBlade form); hand trapz.
Outputs: T [N], Q [N·m]; verdict within 1 %.

### Case: BEMT_MOMENTUM
**Title:** BEMT: momentum = blade element at every station (66a)
**Map / block:** total / A_LOADS
**Category:** verification
**Kind:** runnable
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Our CCBlade wrapper's converged sections: blade-element thrust and torque per unit span against the momentum values, at every station of three operating points.
**Why it is here:** Shows the wrapper's sections are converged solutions of the BEM equations as we set them up (stations, inflow, rpm), not only that integrated loads look plausible.
**A pass means:** Relative difference ≤ 1e-8 at every station.
**Not covered:** Polar accuracy; the empirical (k < −2/3) region; experiment.
**Recorded outcome:** **met**, 72/72 stations, worst 1.1e-11 (first run 2026-10-24; `phase66_bemt_f1a.md`)
**Explanation:** CCBlade applies the tip/hub loss to the loads and reports u, v rescaled by an effective G; the identity is checked with the raw induction a = k/(1−k), a′ = k′/(1+k′) from the section outputs, B N′ = 4πrρV²F a(1+a), B T′ = 4πrρV(1+a)Ωr F a′, and in CCBlade's G form B N′ = 4πrρ(V+u)u, B T′ = 4πrρ(V+u)v (reading fixed before the run).
Inputs: Hartzell example at 20 m/s / 4000 rpm and 40 m/s / 3000 rpm; Report 996 blade β₇₅ = 15°, M_t = 0.6, 20 m/s.
Equations: BEM momentum balance
Outputs: per-station relative difference

### Case: BEMT_HAND_TIP
**Title:** BEMT: hand BEM with tip loss, drag, nonlinear polar (66b)
**Map / block:** total / A_LOADS
**Category:** verification
**Kind:** runnable
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Our wrapper's T and Q against a hand BEM written in the case (Prandtl tip and hub loss in the textbook form, c_d ≠ 0, c_l = 2πα − 4α³), solved by bisection on φ without CCBlade code.
**Why it is here:** Extends BEMT_HAND (linear lift, no drag, no tip loss) to the features the production path uses.
**A pass means:** T and Q within 1 %.
**Not covered:** Experimental loads; Mach/Reynolds effects in the polar.
**Recorded outcome:** **met**, 4/4 (re-run 2026-10-24 after a fix of the hand reference; the first run, 0/4, bisected across the k = 1 pole near the tip — a sign change of the residual that is not a root; `phase66_bemt_f1a.md`)
**Explanation:** With the pole excluded the hand solution equals the wrapper to five digits at both speeds, and CCBlade's φ zeroes the hand residual at every station (|R| ≤ 6e-13). The wrapper and CCBlade were not changed.
Inputs: Hartzell blade (10 stations) at 20 and 40 m/s, 4000 rpm.
Equations: BEM residual sin φ/(1+a) − V/(Ωr)·cos φ/(1−a′) = 0
Outputs: T [N], Q [N m]

### Case: BEMT_INTEGRALS
**Title:** BEMT: integrals, Froude bound, station spacing (66c)
**Map / block:** total / A_LOADS
**Category:** verification
**Kind:** runnable
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** B∫N′dr = T and P = ΩQ from our own trapezoid; propulsive efficiency against the Froude ideal η_i; T when the station spacing is halved.
**Why it is here:** Checks how we integrate and report the loads, and that the station count we use is converged.
**A pass means:** Integrals within 1e-10; η ≤ η_i; ΔT < 0.5 % on halving the spacing.
**Not covered:** Absolute accuracy of the loads.
**Recorded outcome:** **met**, 7/7 (first run 2026-10-24; `phase66_bemt_f1a.md`; information rows kept out of the count): η = 0.593 ≤ 0.919 (Hartzell), 0.626 ≤ 0.774 (Report 996); ΔT = −0.07 % (20 → 39 stations). Information: the thrust F1A radiates with AcousticAnalogies' midpoint spans is 0.997 (Hartzell) and 1.0004 (Report 996) of CCBlade's trapezoid T
**Explanation:** η = TV/(ΩQ); η_i = 2/(1 + √(1 + T/(½ρV²A))) (actuator disk). The span-weight difference is a property of the two packages' quadratures as we combine them, 0.3 % here.
Inputs: Hartzell and Report 996 blades at 20 m/s.
Equations: trapezoid with zero hub/tip loads; Froude
Outputs: T, P, η, ΔT

### Case: BEMT_SIMILARITY
**Title:** BEMT: C_T, C_P unchanged at fixed J (66d)
**Map / block:** total / A_LOADS
**Category:** verification
**Kind:** runnable
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** C_T and C_P of our wrapper when rpm and V scale together (×0.5, ×2, ×3) with a Re- and M-independent polar.
**Why it is here:** Non-dimensional consistency of the wrapper's coefficients (n, D definitions, unit handling).
**A pass means:** Within 1e-6 relative.
**Not covered:** Reynolds and Mach effects (real polars break similarity).
**Recorded outcome:** **met**, 6/6 (first run 2026-10-24; `phase66_bemt_f1a.md`)
**Explanation:** With c_l, c_d independent of Re and M the BEM equations depend on J = V/(nD) only.
Inputs: Hartzell blade, J = 20/(66.7 × 0.762).
Equations: C_T = T/(ρn²D⁴), C_P = 2πQ/(ρn²D⁵)
Outputs: C_T, C_P

### Case: F1A_INDEP
**Title:** Independent Farassat 1A vs AcousticAnalogies (41f)
**Map / block:** total / X_F1A
**Category:** verification
**Kind:** runnable
**Source:** Farassat 1A loading; Report 996 Fig. 12 / page-12 observers; phase 41f criterion 2026-10-23
**What it tests:** Same CCBlade section loads through an independent time-domain compact-source F1A (plain Julia, thickness off) vs `evaluate_propeller_source` at x/D = −0.125 and the ±0.125 phase pair.
**Why it is here:** Isolates AcousticAnalogies wiring for failing R996_FIG12/13A, R996_PHASE, BBN_CIRC, PER_FIG7/8/9.
**A pass means:** Amplitude within 0.5 dB; phase within 2°.
**Not covered:** Experimental agreement; thickness noise; real Report 996 polars (linear cl = 2π α used to isolate F1A).
**Recorded outcome:** **met**, 3/3 (max |ΔdB| ≈ 0.005, |Δφ| ≈ 0.02°) (first run 2026-10-23)
**Explanation:** Code-on-code: independent retarded-time Farassat 1A loading dipole written in the case; identical Np, Tp from CCBlade; compared to AcousticAnalogies path.
Inputs: Fig. 12-like β = 10°, M_t = 0.75, B = 2; observers x/D = ±0.125, d/D = 0.083.
Equations: Farassat 1A loading; FFT harmonics as in `evaluate_propeller_source`.
Outputs: ΔdB, Δφ [deg]; verdict 0.5 dB / 2°.

### Case: F1A_PLANE_PEAK
**Title:** F1A free field: H1 peak on the propeller line (62)
**Map / block:** total / X_FF
**Category:** verification
**Kind:** runnable
**Source:** User Manual Fig. 3 grid; phase 62 criterion 2026-10-23
**What it tests:** Where the F1A free field of the aircraft example puts its largest H1 amplitude on the 160-point grid.
**Why it is here:** Gives the F1A block a check with its own figure (amplitude vs k on each ℓ line); a sign or axis error in the observer mapping moves the peak off the propeller line.
**A pass means:** The H1 maximum lies on ℓ = 1 within ±1 station of k_p.
**Not covered:** Absolute level (F1A_GUTIN, R996_*); phase.
**Recorded outcome:** **met**, 1/1 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`)
**Explanation:** Code check on the source block: the loudest point of the free field is the grid point closest to the propeller plane.
Inputs: examples/aircraft_scale_hartzell.json, H = 1–2.
Equations: —
Outputs: argmax (k, ℓ) of A_H1; plot of A_H1(k) per ℓ.

### Case: ISO_TABLE8
**Title:** apply_table8_calibration identity
**Map / block:** total / X_FF
**Category:** verification
**Kind:** runnable
**Source:** phase 40d criterion 2026-10-23
**What it tests:** That `apply_table8_calibration` is the identity when ℓ = 1 peaks already equal the Table-8 peaks.
**Why it is here:** Calibration helper was untested in isolation.
**A pass means:** ≤ 1e-12 relative on all amplitudes; scales = 1.
**Not covered:** Non-identity scaling behaviour (clamped ±20 dB path).
**Recorded outcome:** **met**, 483/483 (first run 2026-10-23)
**Explanation:** Isolated analytic check: grid filled with Table-8 peak amplitudes; after calibration every point and every scale must match the input within 1e-12.
Inputs: ANOPP Table 8 SPL CSV; synthetic grid at Table-8 peaks.
Equations: scale = peak_Table8 / peak_ℓ1 (identity ⇒ 1).
Outputs: amplitudes and scales; verdict ≤ 1e-12.

### Case: F1A_GUTIN
**Title:** F1A vs Gutin (far field)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Source:** Gutin far-field closed form
**What it tests:** F1A loading-noise wiring vs Gutin's closed form on identical loads (far field).
**Why it is here:** Catches coding errors in the F1A path before any experiment.
**A pass means:** F1A = Gutin within 1 dB on identical loads (V-CODE-like).
**Not covered:** Not experimental; far field only; thickness off.
**Recorded outcome:** **met**, Δ = 0.03 dB (re-run 2026-10-24 after a code-on-code fix of the Gutin reference; criterion unchanged). Earlier record Δ = 0.31 dB (2026-10-21/23) compared F1A with a wrong closed form and is withdrawn.
**Explanation:** Code-on-code: Farassat F1A (AcousticAnalogies.jl) vs Gutin's far-field loading-noise tone in the rotor plane, on the same BEMT loads. Fix of 2026-10-24 (found by the Phase 64 unit test of the independent F1A): the reference used (mBΩ/(2πc₀r))(Q/R_tip)·J_mB(mB·M_tip), which is low by √2·M against Gutin's p_rms = (mBΩ/(2√2πc₀r))·Qc₀/(ΩR²)·J_mB(mBΩR/c₀) (Goldstein; Hubbard RP-1258) and was evaluated at the tip radius; the two errors nearly cancelled for this rotor, so the old 0.31 dB agreement was accidental. A single-radius rotating source, Gutin's exact setting, gives the independent F1A of F1A_INDEP = Gutin within 0.03 %. The reference now sums Gutin annulus by annulus over the BEMT sections (trapezoid weights of `thrusttorque`; Σ dQ = Q to 1e-15).
Inputs: examples/aircraft_scale_hartzell.json made static, thickness off; observer at 100 R_tip in the rotor plane; first harmonic H1.
Equations: F1A (AcousticAnalogies); Gutin per annulus; comparison in `_run_f1a_gutin`.
Outputs: SPL [dB]; verdict |Δ| ≤ 1 dB.

### Case: R996_FIG14
**Title:** Report 996 Fig. 14(a)
**Map / block:** total / A_AMP
**Category:** experiment
**Kind:** replay
**Source:** NACA Report 996 Fig. 14(a), p.16
**What it tests:** F1A harmonic amplitude vs tip Mach M_t at fuselage-like distance.
**Why it is here:** Static near-field amplitude check.
**A pass means:** Scaled-load harmonic within ±2 dB at ≥ 75 % of points (23c).
**Not covered:** Loads scaled to measured T, Q (calibrated input); static only; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** met 20/24 within ±2 dB (report996_acoustics.md; amplitude convention fixed 2026-10-21, post-hoc) **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** 20/24 (unchanged count; max error 4.4 dB, was 3.1); still met. **Re-run 2026-10-28 (Phase 72, observer fore/aft convention, post-hoc: the earlier results were known; the convention is taken from the source documents, nothing chosen from the residuals):** **not met, 14/24** (was met 20/24). Fig. 14 is at x/D = −0.125, behind the plane; computed behind now: H2 8/8, H4 4/8, H6 2/8, the higher harmonics too loud. The earlier pass was computed ahead of the plane. **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** **met, 24/24** (was 14/24; max error 1.9 dB, median 0.69 dB).
**Explanation:** Replay of a recorded result: static near-field harmonic amplitude vs M_t (Fig. 14(a)). Loads scaled to measured T, Q. After I-17: 20/24 within ±2 dB → met (≥75 %). Post-hoc label on the amplitude-convention re-record.
Inputs: recorded `f1a_results.csv` from Report 996 acoustics script; scaled-load path.
Equations: F1A (replayed); criterion 20 log10(A_rms/meas).
Outputs: pressure [dyne/cm²] / SPL error [dB]; verdict ≥75 % within ±2 dB.

### Case: R996_FIG12
**Title:** Report 996 Fig. 12(a)(b)
**Map / block:** total / A_AMP
**Category:** experiment
**Kind:** replay
**Source:** Report 996 Fig. 12(a)(b), p.13
**What it tests:** F1A harmonic amplitude vs x/D (axial near-field shape).
**Why it is here:** Axial shape of the near field.
**A pass means:** Scaled-load harmonic within ±2 dB at ≥ 75 % of points (23c).
**Not covered:** Loads scaled to measured T, Q (calibrated input); static only; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** not_met 21/40 within ±2 dB (re-run 2026-10-22 with regenerated polar entries, post-hoc; first recorded 22/40) (report996_acoustics.md; amplitude convention fixed 2026-10-21, post-hoc). Isolation case F1A_INDEP (41f); isolation passes: remaining miss attributed to model fidelity (method), not code. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** **28/40** within ±2 dB (70 %; need ≥ 75 %), was 21/40; still not met. H6 4/10 is the weakest harmonic. **Re-run 2026-10-28 (Phase 72, observer fore/aft convention, post-hoc: the earlier results were known; the convention is taken from the source documents, nothing chosen from the residuals):** **13/40** (was 28/40). Report 996 p. 6 defines positive x/D as ahead; the scripts had put the behind microphones ahead. With the documented sign the model is too loud behind and too quiet ahead at mB ≥ 4 for β = 10° (H2 7/10, H4 5/10, H6 0/10, H8 1/10). Report 996 says its own Eq. (2) with R_e = 0.8R overestimates by about 40 %. The earlier 28/40 depended on the mirrored observers. **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** **met, 32/40** (was 13/40; H2 8/10, H4 9/10, H6 7/10, H8 8/10; max error 3.5 dB, median 0.96 dB).
**Explanation:** Replay of a recorded result: axial near-field harmonics vs x/D. After I-17: 22/40 within ±2 dB (not met; need ≥75 %); polar re-run 2026-10-22 (post-hoc): 21/40. Scaled loads; amplitude-convention fix post-hoc.
Inputs: recorded `f1a_results.csv`.
Equations: F1A (replayed).
Outputs: pressure vs x/D; verdict ≥75 % within ±2 dB.

### Case: R996_FIG13A
**Title:** Report 996 Fig. 13(a)
**Map / block:** total / A_AMP
**Category:** experiment
**Kind:** replay
**Source:** Report 996 Fig. 13(a), p.15
**What it tests:** F1A first harmonic vs x/D with RM L51C27 load scale (ahead/behind asymmetry).
**Why it is here:** Ahead/behind asymmetry check.
**A pass means:** Scaled-load harmonic within ±2 dB at ≥ 75 % of points (23c).
**Not covered:** Loads scaled to RM L51C27 T, Q (calibrated input); static only; amplitude convention fixed 2026-10-21, post-hoc.
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
**Map / block:** total / A_AMP
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

### Case: F1A_GUTIN_ANGLES
**Title:** F1A vs Gutin off the rotor plane, thrust and torque (66e)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Our F1A path (BEMT loads → AcousticAnalogies → FFT) against Gutin summed annulus by annulus with thrust and torque, at θ = 30°–150° from the flight direction, static, 100 R_tip: H1 level and phase relative to θ = 90°.
**Why it is here:** F1A_GUTIN checks the rotor plane only, where thrust does not radiate; off the plane the thrust term and its sign enter.
**A pass means:** Within 0.5 dB and 5° at each of five angles.
**Not covered:** Near field; flight (66f); thickness (66g).
**Recorded outcome:** **not met**, 4/5 (first run 2026-10-24; `phase66_bemt_f1a.md`): levels within 0.26 dB at all five angles; phase at θ = 60° 165.4° against 180° (14.6° off), others within 3.5°. Post-hoc: at 60° the thrust and torque terms cancel to 0.057 of their sum (a near-null), and at 400 R_tip the 60° phase is 176.3° (3.7° off)
**Explanation:** Frame from the AcousticAnalogies source (rotor translates along +X): θ from +X, Gutin bracket −dT cos θ + dQ c₀/(ΩR²), sections weighted by AcousticAnalogies' spans (readings fixed before the run). The 60° miss is a near-null where the residual phase is set by the O(1/r²) near-field remainder at 100 R; it moves toward 180° with distance. Criterion unchanged.
Inputs: Hartzell example, static, thickness off.
Equations: Gutin per annulus
Outputs: H1 SPL [dB], phase [deg]

### Case: F1A_GW_FLIGHT
**Title:** F1A vs Garrick–Watkins in flight (66f)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Our F1A path in forward flight (observers moving with the propeller) against the Garrick–Watkins tone on the same BEMT loads, M_x = 0.1 and 0.2, θ = 60°, 90°, 120°, 100 R_tip.
**Why it is here:** Report 996 and Pereira are flight cases; Gutin covers only static rotors.
**A pass means:** Within 1 dB at every point.
**Not covered:** Non-uniform inflow; installation effects.
**Recorded outcome:** **met**, 6/6, worst 0.07 dB (first run 2026-10-24; `phase66_bemt_f1a.md`)
**Explanation:** Garrick–Watkins (x positive forward): p_rms = (mBΩ/(2√2πc₀S₀))|−dT(M_x + x/S₀)/β² + dQ c₀/(ΩR²)| J_mB(mBΩRy/(c₀S₀)), S₀ = √(x² + β²y²); reduces to Gutin at M_x = 0 (reading fixed before the run).
Inputs: Hartzell example at 34 and 68 m/s, 4000 rpm.
Equations: Garrick–Watkins per annulus
Outputs: H1 SPL [dB]

### Case: F1A_THICKNESS
**Title:** F1A thickness noise vs the compact far field (66g)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Our F1A thickness noise alone (loads scaled to zero, t/c = 0.12) against the compact far-field monopole form, H1–H3, θ = 60°, 90°, 120°, static.
**Why it is here:** No other case checks the thickness term (the production default is loading only).
**A pass means:** Within 1 dB at every point.
**Not covered:** Non-compact chord effects at high harmonics (Hanson's chordwise factors → 1 in the compact limit).
**Recorded outcome:** **met**, 9/9, worst 0.002 dB (first run 2026-10-24; `phase66_bemt_f1a.md`)
**Explanation:** Peak amplitude ρ₀(mBΩ)²B ΣA_i Δr_i J_mB(mBΩr_i sin θ/c₀)/(2πr), A = (t/c)c² (AcousticAnalogies' area_over_chord2), from ρ₀/(4πr) ∂²/∂t²[V/(1−M_r)]; Hanson's far field in the compact-chord limit.
Inputs: Hartzell blade, static.
Equations: compact monopole far field
Outputs: SPL [dB] per harmonic

### Case: F1A_PROPERTIES
**Title:** F1A exact properties and convergence (66h)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
**Source:** closed form / identity (plan §8j Phase 66; criterion and readings 2026-10-24, before any run)
**What it tests:** Blade-count scaling on identical prescribed loads (B = 4 H1 = 2 × B = 2 H2 at 4Ω), 1/r in the far field, and convergence in source time step and blade stations.
**Why it is here:** Shows our F1A set-up (blade replication, reception window, sampling, station count) is consistent and converged.
**A pass means:** B scaling and 1/r within 1 %; < 0.1 dB between successive halvings.
**Not covered:** Absolute level (66e–66g, F1A_GUTIN).
**Recorded outcome:** **met**, 5/5 (first run 2026-10-24; `phase66_bemt_f1a.md`): ratios 2.000, 2.000, 2.0002; 64 → 128 source times −4e-6 dB; 20 → 39 stations 0.025 dB
**Explanation:** The blade-count check feeds the same CCBlade section loads to a 2- and a 4-blade rotor through `_f1a_harmonics` (the production F1A step), because BEMT loads change with B (reading fixed before the run).
Inputs: Hartzell example, static.
Equations: coherent sum of identical blades; spherical spreading
Outputs: ratios, dB changes

### Case: F1A_CHORDWISE
**Title:** F1A near field: compact vs chordwise loading at Report 996 geometry (67b)
**Map / block:** total / A_AMP
**Category:** verification
**Kind:** runnable
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
**Map / block:** total / A_PHASE
**Category:** experiment
**Kind:** replay
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
**Source:** Report 996 p.12 text
**What it tests:** F1A phase ahead/behind vs the one measured value 155°.
**Why it is here:** Only measured phase in Report 996.
**A pass means:** within ±15° of 155° (23c).
**Not covered:** One data point; stations ±0.125 used as candidates (report does not name them).
**Recorded outcome:** FAIL 109.0° vs 155° (±15°) after the 2026-10-22 polar re-run (post-hoc; first recorded 103.8°); tr996_phase_values.csv + f1a_results.csv. Isolation case F1A_INDEP (41f); isolation passes: remaining miss attributed to model fidelity (method), not code. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** F1A 113.6° vs 155° (±15°), was 109.0°; still FAIL. **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** still FAIL, error 42° (was 41°).
**Explanation:** Replay of a recorded result: one measured phase 155° (p. 12). Comparison uses ±0.125 x/D as candidates; F1A gives 109.0° (103.8° before the polar re-run). Fails ±15° (23c). Nothing tuned.
Inputs: recorded `tr996_phase_values.csv`, `f1a_results.csv`.
Equations: F1A phase (replayed).
Outputs: phase difference [deg]; verdict within ±15° of 155°.

### Case: PER_FIG6
**Title:** Pereira Fig. 6 spectra
**Map / block:** total / A_FWD
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
**Map / block:** total / A_FWD
**Category:** experiment
**Kind:** replay
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
**Title:** Pereira Fig. 8 directivity
**Map / block:** total / A_FWD
**Category:** experiment
**Kind:** replay
**Source:** Pereira et al. 2026 Fig. 8
**What it tests:** F1A forward-flight directivity at 1 m.
**Why it is here:** Only forward-flight directivity under 23d.
**A pass means:** H1 within ±1.7 dB and H2 within ±3 dB at every microphone (23d).
**Not covered:** Harmonics above H2 (removed from the case 2026-10-28, author). **Why only H1 and H2:** they carry the propeller's loading and thickness noise, which is what the source block predicts. Above H2 the measurement is not the propeller: Pereira reports motor noise at the 3rd and 6th BPF, the measured H3–H6 sit flat at 40–50 dB while every prediction (ours, Pereira's BEMT, their CFD) falls with harmonic, and the paper reports disagreements above 6 dB for all methods there. A comparison above H2 would test the motor, not the code. Far field only; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** replay of pereira_results.csv (amplitude convention fixed 2026-10-21, post-hoc). Isolation case F1A_INDEP (41f); isolation passes: remaining miss attributed to model fidelity (method), not code. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** H1 3/7, H2 3/7 (6/37 over all rows, was 7/37); not met. **Re-run 2026-10-28 (Phase 72, observer fore/aft convention, post-hoc: the earlier results were known; the convention is taken from the source documents, nothing chosen from the residuals):** H1 **5/7** (was 3/7), H2 3/7. With φ positive downstream (Pereira Fig. 2b) the H1 directivity matches Pereira's own BEMT curve within 0.8 dB at all seven angles. **Re-run 2026-10-28 (Phase 76, thickness noise on, post-hoc: the loading-only results were known; the only new input is the section area from the airfoil coordinates, nothing chosen from the residuals):** H1 **6/7**, H2 **4/7** (was 5/7, 3/7); not met (median error 3.7 dB over all rows, was 7.0).
**Explanation:** Replay of a recorded result: directivity at 1 m vs Fig. 8 (H1 ±1.7 dB, H2 ±3 dB). Amplitude convention fixed 2026-10-21, post-hoc.
Inputs: recorded `pereira_results.csv`, `pereira_fig8_directivity.csv`.
Equations: F1A (replayed).
Outputs: SPL [dB] vs φ; verdict on H1/H2 tolerances.

### Case: PER_FIG9
**Title:** Pereira Fig. 9 harmonics
**Map / block:** total / A_FWD
**Category:** experiment
**Kind:** replay
**Source:** Pereira et al. 2026 Fig. 9
**What it tests:** F1A forward-flight harmonics at 1 m vs Fig. 9 Exp.
**Why it is here:** Only forward-flight harmonic bar check under 23d.
**A pass means:** H1 ±1.7 dB, H2 ±3 dB (23d).
**Not covered:** Motor noise above H2; far field only; amplitude convention fixed 2026-10-21, post-hoc.
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
**Source:** NASA RP-1218 App. D Tables D2 and D3 (printed output of NASA's prediction code); criterion fixed 2026-10-23
**What it tests:** The Julia port of the Brooks–Pope–Marcolini airfoil self-noise model (TBL-TE pressure and suction side, separation, LBL-VS, tip vortex) against NASA's own printed code output for two test cases.
**Why it is here:** Phase 48 predicts the propeller exterior broadband from this model.
**A pass means:** Within 1 dB at ≥ 90 % of the printed points.
**Not covered:** Trailing-edge bluntness noise (not ported); the rotor application.
**Recorded outcome:** **met**, 270/270 (max 0.19 dB; first run 2026-10-23).
**Explanation:** Code-on-code. `bpm_spectrum` is run with the App. D inputs.
Inputs: `data/rp1218/rp1218_tableD2.csv`, `rp1218_tableD3.csv`.
Equations: RP-1218 Eqs. 2–67, App. B directivity.
Outputs: 1/3-octave SPL per mechanism [dB].

### Case: PROP_BB_FIG14
**Title:** Propeller broadband (BPM) vs CR-172428 Fig. 14 free field, 5000 rpm (48c)
**Map / block:** total / A_SURF
**Category:** experiment
**Kind:** runnable
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
**Source:** CR-3813 Fig. E-11, App. E p. E-19 / PDF p.135
**What it tests:** Whether two independent digitizations of NASA's free-field microphone line agree within 1 dB (input quality only).
**Why it is here:** That measured line (with ANOPP Table 8 for H3 and phases) drives every e11 cabin run.
**A pass means:** The figure was read repeatably (digitization scatter δ_dig ≤ 1.0 dB). It does not mean the levels are physically right.
**Not covered:** Physical accuracy of the free-field levels; H3 and all phases come from ANOPP Table 8, not from Fig. E-11.
**Recorded outcome:** met, δmax = 1.0 dB at the limit (e11_delta_dig.md)
**Explanation:** Input QA: Fig. E-11 is sound-pressure level (SPL, dB re 20 µPa) of harmonics H1–H3 measured by NASA with microphones at free-field positions around the model propeller with the fuselage absent, along grid line ℓ = 1 (Fig. E-4), plotted against distance from the propeller plane X/D (forward positive, aft negative). NASA also plotted its ANOPP prediction. This case checks only that two independent digitizations (passes A and B) of that figure agree within 1 dB — not that the levels match physics or ANOPP. Axes: X3/D vs SPL; curves are pass A, pass B, and their mean (the input).
Inputs: Digitized CSVs from `default_e11_paths()` (`e11_freefield_measured_A.csv`, `e11_freefield_measured_B.csv`); geometry for X3/D via `grid_points` on ℓ = 1 (L = test_article_length() = 1.83 m, a = 0.508 m, φ_p = 90°, r_p = 0.965 m, z_p = 0.662 m since Phase 65); D = 0.762 m.
Equations: none (digitization comparison only); helper `delta_dig_dB`.
Outputs: δ_dig [dB] per harmonic and station; verdict uses max δ_dig ≤ 1.0 dB.

### Case: ISO_FF_CONV
**Title:** Free-field SPL↔Pa and e11 ℓ=1 loader
**Map / block:** total / P_FF
**Category:** verification
**Kind:** runnable
**Source:** I-17 amplitude convention; Fig. E-11 / Table 8 CSVs; phase 40b criterion 2026-10-23
**What it tests:** SPL → peak Pa → SPL round-trip after I-17, and the ℓ = 1 line of `freefield_from_e11_csv` against a hand conversion of the CSV.
**Why it is here:** Conversions and the e11 loader had no isolated check (audit NONE).
**A pass means:** ≤ 1e-12 relative on every conversion and ℓ = 1 amplitude/phase row.
**Not covered:** Off-line GEXT values; broadband clip policy beyond matching the loader's written rule.
**Recorded outcome:** **met**, 111/111 (first run 2026-10-23)
**Explanation:** Isolated analytic check: hand formulas A = √2·20μPa·10^(SPL/20) and the inverse; ℓ = 1 from the loader vs the same hand conversion of the digitized CSV (with the loader's ANOPP H≥3 / clip rule written in the case).
Inputs: synthetic SPL values; `default_e11_paths()` amp/phase/ANOPP CSVs; test-article geometry.
Equations: I-17 peak convention; `spl_dB_to_peak_Pa` / `peak_Pa_to_spl_dB` / `freefield_from_e11_csv`.
Outputs: Pa and dB; verdict ≤ 1e-12 relative.

### Case: SRC_PASSTHROUGH
**Title:** Source select: the chosen field reaches the cabin unchanged (62)
**Map / block:** total / X_SRC
**Category:** verification
**Kind:** runnable
**Source:** PAIN.jl `run_pain_pipeline`; phase 62 criterion 2026-10-23
**What it tests:** The amplitudes and phases stored in PainInputs against the blocked source grid, for :e11, :synthetic and (since 2026-10-28, Phase 70 F7) :aircraft, the F1A field of the working example.
**Why it is here:** Gives the source-select block a check with its own figure; a transposed or re-indexed grid would pass every downstream check silently.
**A pass means:** PainInputs amplitudes and phases identical to the blocked source grid.
**Not covered:** The physics of any source.
**Recorded outcome:** **met**, 2/2 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`) **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** **met, 3/3**: the aircraft-path row (`aircraft_scale_hartzell.json`, 2 harmonics, R2) was added to the E-11 and synthetic rows (Phase 70); bit-exact (0.0 Pa).
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
**Source:** CR-3813 Fig. E-11 (ℓ = 1 measured line); phase 62 criterion 2026-10-23
**What it tests:** The digitized e11 free field after grid extension (GEXT): every off-line amplitude against the ℓ = 1 amplitude at the same k.
**Why it is here:** Gives the free-field block a check with its own figure; the extension must not create a louder point than the measured line it starts from.
**A pass means:** Every off-line amplitude ≤ the ℓ = 1 amplitude at the same k (48 (H, k) pairs). **Holds by construction (Phase 70 F1, 2026-10-28):** GEXT multiplies the ℓ = 1 amplitude by max(cos α, floor) ≤ 1, so this case checks the plumbing and draws the figure. It is not evidence about GEXT, which GEXT_BOUND and ISO_GEXT_LINE cover.
**Not covered:** Whether GEXT is right (phase 32 importance bound); phases.
**Recorded outcome:** **met**, 48/48 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`)
**Explanation:** Monotonicity check of the GEXT field: the source is on the propeller line, so amplitude falls off around the cylinder.
Inputs: default_e11_paths(), H = 1–3.
Equations: GEXT (`extend_line_to_grid`)
Outputs: A(k, ℓ) / A(k, 1) per H.

### Case: UT_GRID
**Title:** Skin grid vs User Manual Fig. 3 (with figure)
**Map / block:** total / P_GRID
**Category:** verification
**Kind:** runnable
**Source:** User Manual Fig. 3
**What it tests:** That the 160 fuselage-skin grid points match the User Manual Fig. 3 coordinate and azimuth formulas, with a γ-coloured plot.
**Why it is here:** Every observer, incidence angle γ, and panel area comes from this grid.
**A pass means:** Sampled coordinates and azimuth agree with Fig. 3 formulas within 1e-9 (unit test with visualization).
**Not covered:** Acoustics at the points; GEXT; how γ enters blocking physics.
**Recorded outcome:** runnable unit test with figure (`docs/validation_reports/figures/UT_GRID.png`); Pkg.test "Grid geometry" / "Grid azimuth" remain. Error-panel x label is sample index (`PlotSpec.error_xlabel`), not axial z. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** the grid z of every point is now checked against z_k = z_p − x₃ by hand: **met** 35/35 (was 28/28 without the z rows).
**Explanation:** Unit test with visualization: the PAIN/ANOPP skin grid is 16 axial stations (k) × 10 azimuth lines (ℓ) = 160 points on the unrolled cylinder. Line ℓ = 1 sits at the propeller azimuth φ_p; α = (ℓ−1)·10° is the unsigned angle from that line. Incidence angle γ is the angle between the surface→hub direction and the outward normal (γ = 0 head-on). Figure: axial z vs α, points coloured by γ, with the propeller plane z = z_p and ℓ = 1 marked. Table: Manual Fig. 3 x1, x2, x3, θ at a handful of (k, ℓ); error panel x is the sample index, not z. No acoustics.
Inputs: `FuselageGeometry(L=1.83 m, a=0.508 m, θ0=56.6°)`, `PropellerPlacement(r_p=0.965 m, φ_p=90°, z_p=0.662 m)` (since Phase 65), `GridSpec()` (k_max=16, ell_max=10, k_p=8) — same family as the e11 path / Manual §5.2.
Equations: User Manual Fig. 3 / §3: x1=(r_p−a)+a(1−cos α), x2=−a sin α, x3=(π a/18)(k_p−k), θ=φ_p+α; γ via `incidence_angle_deg` (CR-3813 §3.4). Code: `grid_points`, `incidence_angle_deg`.
Outputs: x1,x2,x3 [m], θ [deg] vs formulas; figure γ [deg]; verdict on coordinate/azimuth residuals ≤ 1e-9.

### Case: GEXT_BOUND
**Title:** Grid-extension (GEXT) importance bound on T1
**Map / block:** total / P_GRID
**Category:** calibrated
**Kind:** runnable
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
**Source:** phase 40c criterion 2026-10-23
**What it tests:** On ℓ = 1 the extension returns its input (falloff 1, delay 0) for every harmonic and option set.
**Why it is here:** On-line identity is the only GEXT check with a reference; off-line stays V-ASSUMED.
**A pass means:** ≤ 1e-12 on ℓ = 1 amplitudes and phases for all exercised options.
**Not covered:** Off-line falloff/delay physics (no reference).
**Recorded outcome:** **met**, 480/480 (first run 2026-10-23)
**Explanation:** Isolated analytic check: synthetic line amplitudes/phases; for each importance-bound option set, every ℓ = 1 point must equal the line input.
Inputs: synthetic line_amps/phases; `grid_points`; option sets (n, floor, delay_scale).
Equations: GEXT on-line identity (α = 0 ⇒ falloff = 1, R = R0 ⇒ delay = 0).
Outputs: A, φ on ℓ = 1; verdict ≤ 1e-12.

### Case: BLK_P68
**Title:** Blocking Eq. (43) vs printed p.68 values
**Map / block:** total / P_BLK
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
**Map / block:** total / P_BLK
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Fig. E-12, p.136
**What it tests:** Eq. (43) R1 applied to ANOPP Table 8 vs NASA's predicted blocked curve on ℓ = 1.
**Why it is here:** Checks blocking on the measured line before GEXT enters.
**A pass means:** Reproduces NASA's prediction within δ_dig + 0.5 = 3.41 dB.
**Not covered:** GEXT; measured circles on the figure are 1–7 dB lower (no pass mark).
**Recorded outcome:** 29/31, two H3 aft points FAIL (e12_blocking.md). **Diagnostic 2026-10-28 (A3b, post-hoc, no verdict; `e12_a3b_linefit.md`):** with both NASA predicted lines read from pixels, Fig. E-11's line equals Table 8 within 1.2 dB, NASA's step E-12 − E-11 is 4.5–7.5 dB at H1/H2 (Eq. 43: 5.7–6.0), and Table 8 + ΔL is within ±1.7 dB of the pixel-read E-12 line at 27 of 28 stations. The one large miss is H3 k10 (+4.9 dB), where NASA's drawn line implies a 2.3 dB step that Eq. (43) cannot give. The verdict stays as recorded.
**Explanation:** Experiment comparison on the prediction curve (V-CODE vs NASA's predicted E-12): "blocked pressure" is the pressure on a rigid cylinder (Fig. E-12). Free-field ANOPP Table 8 SPLs on ℓ = 1 are raised by R1 ΔL(γ) and compared with the digitized NASA predicted curve. Axes: X3/D vs blocked SPL; panels H1–H3. Measured circles are shown for context only.
Inputs: ANOPP Table 8 CSV; `e12_predicted_A/B.csv`; geometry as E11 (a = 0.508 m, r_p = 0.965 m, φ_p = 90°, z_p = 0.662 m since Phase 65, L = 1.83 m); blocking R1; D = 0.762 m.
Equations: Eq. (43) via `delta_L_blocking_dB`; γ via `incidence_angle_deg`; blocked SPL = free-field SPL + ΔL.
Outputs: blocked SPL [dB] H1–H3; verdict |Δ| ≤ 3.41 dB vs digitized NASA prediction.

### Case: ISO_BLOCKING
**Title:** apply_blocking full grid vs F(γ)·A
**Map / block:** total / P_BLK
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Eq. (43); phase 40a criterion 2026-10-23
**What it tests:** That `apply_blocking` on all 160 points equals F(γ)·A from `blocking_factor` and the geometry's γ, with phases unchanged.
**Why it is here:** Isolates full-grid blocking from the cabin chain (BLK_P68 only checks F at given γ).
**A pass means:** Max relative difference ≤ 1e-12 on amplitudes and phases (V-UNIT).
**Not covered:** Physical correctness of Eq. (43); γ from geometry is used but not separately gated here.
**Recorded outcome:** **met**, 960/960 (first run 2026-10-23)
**Explanation:** Isolated analytic check: synthetic free-field amplitudes/phases on the 160-point grid; reference is F(γ)·A with γ from `incidence_angle_deg` and F from `blocking_factor` (same Eq. 43, not `apply_blocking`). Phases must be identical to the input.
Inputs: synthetic A, φ on `grid_points` (test-article geometry); variant R1.
Equations: Eq. (43) via `blocking_factor`; `apply_blocking` under test.
Outputs: A_bl, φ_bl; verdict every row ≤ 1e-12 relative (phases absolute near zero).

### Case: BLK_GAIN_MAP
**Title:** Blocked pressures: gain within 0–6.02 dB (62)
**Map / block:** total / X_BLK_OUT
**Category:** verification
**Kind:** runnable
**Source:** CR-172428 Eq. (43) (R1) and CR-3813 Eq. (43) as used (R2); phase 62 criterion 2026-10-23
**What it tests:** The blocked/free gain ΔL at every grid point for both blocking variants.
**Why it is here:** Gives the blocking output a check with its own figure (ΔL vs incidence γ); a rigid surface at most doubles the pressure, so 0 ≤ ΔL ≤ 20 log10 2.
**A pass means:** 0 ≤ ΔL ≤ 6.02 dB at every grid point for R1 and R2.
**Not covered:** Diffraction around the cylinder; which variant NASA used (R2 is the production default).
**Recorded outcome:** **not met**, 1/2 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`): R2 within the bound; R1 reaches −49.3 dB at the grid points with γ > 90° (Eq. 43 as printed in CR-172428 goes negative there)
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
**Source:** CR-3813 App. E pp. E-1–E-8 (`data/cr3813/appE_article_inputs.csv`, page and printed digits per value); phase 62 criterion 2026-10-23
**What it tests:** Every structural and propeller-placement value the code uses for the test article against the printed value, rounded to the printed digits.
**Why it is here:** Gives the structural input block a check with its own figure; input transcription errors are invisible to code-on-code checks. This case found the grid axial-sign and z_p errors fixed in Phase 65.
**A pass means:** Every code value equals the printed value to its printed digits.
**Not covered:** Values CR-3813 does not print (V-ASSUMED register items).
**Recorded outcome:** **met**, 13/13 (2026-10-23, after Phase 65; `phase62_65_map_blocks_grid.md`). Before Phase 65 the z_p row failed (0.90 m in code, 0.662 m printed on p. E-8).
**Explanation:** Input QA against the printed page. Not a fit: the printed value is the reference and nothing is chosen from a result.
Inputs: appE_article_inputs.csv; MRP_* constants; PropellerPlacement used by the cases.
Equations: —
Outputs: code / printed per quantity.

### Case: MRP_D1
**Title:** MRP Table D-1 seed
**Map / block:** total / P_MRP
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
**Map / block:** total / P_MRP
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
**Map / block:** total / P_MRP
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Table D-1 / Fig. D-2; App. D pp. D-3…D-10
**What it tests:** Printed App. D structural solver (no fitted scale) vs Table D-1 frequencies.
**Why it is here:** Any geometry other than the test article needs Eqs. (D.17)–(D.26), not the Table D-1 seed.
**A pass means:** ≥ 75 % of the 32 Table D-1 modes within 5 % of the solver mode of the same identity (symmetry, axial m, dominant shell and floor orders; identity matching fixed 2026-10-28, count rule 2026-10-22); no calibration input.
**Not covered:** Fig. D-2 shapes reported without a pass mark; production default remains Table D-1 / fitted surrogate.
**Recorded outcome:** **met**, 27/32 within 5 % (84.4 %); Fig. D-2 max \|Δw\| = 1.4534 (info, no pass mark). First run 2026-10-22 (`mrp_appd_vs_d1.md`). **Audit 2026-10-28 (Phase 78):** this pass is an artifact of frequency-only matching (the solver has 61 modes below 820 Hz against Table D-1's 32); matched by mode identity the solver gives 2/32 within 5 %, 20–70 % low. The criterion moves to identity matching in Phase 78a. **Re-run 2026-10-28 (Phase 78a, identity criterion fixed before its first run):** **not met, 2/32** (19 Table D-1 modes have no solver mode of the same identity; frequency-only count 31/32, information). Isolation (78b): the shell and floor operators are exact against closed forms; the stiffener inertias drop the channel flanges (frames and floor beams 3.7× too soft) and the floor stiffness is isotropic. Fix plan 78c.
**Explanation:** Code-on-code (against printed values / NASA solver outputs): implements App. D constraints D.17–D.21, constitutive D.23–D.24, operator D.25, eigenproblem D.22, shapes D.26–D.29 with physical geometry from App. E / Manual §5.2. No parameter fitted to Table D-1. Label V-CODE; first run 2026-10-22.
Inputs: `appd_test_article_geometry()`; n_modes=48, n_axial=7, n_circ=8, n_floor_max=5; tol_frac=0.05; count rule ≥75 % of 32.
Equations: App. D (D.17)–(D.26); code `appd_modes` in `mrp_appd.jl`.
Outputs: f [Hz] vs Table D-1; Fig. D-2 shape residuals (info); verdict on count rule.

### Case: MRP_SHAPE_NORM
**Title:** Table D-1 shapes: max-normalized (62)
**Map / block:** total / X_MRP_OUT
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Table D-1 and p. D-10 (shapes normalized to unit maximum displacement); phase 62 criterion 2026-10-23
**What it tests:** max |ψ| over the shell and floor of each of the 32 Table D-1 shapes as transcribed.
**Why it is here:** Gives the structural output block a check with its own figure; the coupling bound |f′| ≤ 1 rests on max-normalized shapes.
**A pass means:** max |ψ| ≤ 1 + 1e-6 for every mode.
**Not covered:** Whether the printed coefficients are complete (Table D-1 prints the largest terms only).
**Recorded outcome:** **not met**, 19/32 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`): 13 shapes reach max |ψ| up to 1.245
**Explanation:** Table D-1 prints only the largest Fourier coefficients of each mode, so the truncated sum need not peak at exactly 1. The coupling factor checks |f′| ≤ 1 on every pair it uses and none exceeds it. Recorded as a property of the printed table; no coefficient was rescaled.
Inputs: TABLE_D1_FULL / _D1_SHAPES.
Equations: Eqs. (46)–(49)
Outputs: max |ψ| per mode.

### Chunk 5: CYL2D (`G_CYL`)

Blocks in map order: `X_CYL_IN` Cabin geometry → `P_CYL` CYL2D → `X_CYL_OUT` Modes Φ_G. Cases are listed block by block, in the order the map shows them.

### Case: CABIN_GEOM_HAND
**Title:** Cabin geometry by hand (62)
**Map / block:** total / X_CYL_IN
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 App. C/D geometry (Fig. D-1); phase 62 criterion 2026-10-23
**What it tests:** Cabin volume, coupling area, absorbing area and floor width against the hand formulas.
**Why it is here:** Gives the cabin geometry input block a check with its own figure (the cross-section drawn from the same numbers).
**A pass means:** Each within 1e-12 of the hand formula.
**Not covered:** Whether the test article is a cylinder with a flat floor (it is, App. E).
**Recorded outcome:** **met**, 4/4 (first run 2026-10-23; re-run 2026-10-24 after the code review replaced the floor-width row, which compared 2a sin θ0 with itself, by the floor width the App. D plate uses; `phase62_65_map_blocks_grid.md`)
**Explanation:** Hand formulas: V = a²L(π − θ0 + cosθ0 sinθ0), A = L(Lp + 2a(π − θ0)), S = S_side + 2V/L, Lp = 2a sinθ0.
Inputs: a = 0.508 m, L = 1.83 m, θ0 = 56.6°.
Equations: App. C Eq. (C.11) area
Outputs: V, A, S, Lp.

### Case: CYL2D_C1
**Title:** CYL2D vs Table C-1 / Fig. C-3
**Map / block:** total / P_CYL
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

### Case: ISO_CYL2D_EXACT
**Title:** cyl2d_modes vs exact circle J′ zeros
**Map / block:** total / P_CYL
**Category:** verification
**Kind:** runnable
**Source:** Neumann circular duct; phase 40e criterion 2026-10-23
**What it tests:** Floorless circular section (θ0 = 0°) against f = c·j′_{m,s}/(2πa) from independent J′ zeros.
**Why it is here:** CYL2D_C1 only compares to App. C tables of the same report.
**A pass means:** First 10 modes within 2 % at NY = 20, and max relative error at NY = 20 smaller than at NY = 10.
**Not covered:** Floored cabin (θ0 = 56.6°); Φ_G / shapes.
**Recorded outcome:** **met**, max |e| NY20 = 0.966 %, NY10 = 6.676 % (first run 2026-10-23)
**Explanation:** Isolated analytic check: θ0 = 0° makes the floor width zero (floor at y = −1, wall-tangent). Reference frequencies from scan+bisection zeros of J′_m (series Bessel written in the case). NY = 10 and NY = 20 both reported; pass uses the 2026-10-23 gate.
Inputs: θ0 = 0°, c0 = 340 m/s, a = 1 (unit), n_modes = 10, NY = 10 and 20.
Equations: f = c0·j′/(2π); `cyl2d_modes`.
Outputs: f [Hz]; verdict on 2 % @ NY20 and error improvement.

### Case: ISO_CYL2D_BOUNDARY
**Title:** acoustic_boundary_value and cabin_modes_3d list
**Map / block:** total / P_CYL
**Category:** verification
**Kind:** runnable
**Source:** App. C; phase 40j criterion 2026-10-23
**What it tests:** Boundary φ reconstructed from stored node values; (q, i) list complete and sorted.
**Why it is here:** Boundary interpolation and 3-D mode enumeration had no isolated gate.
**A pass means:** ≤ 1e-9 on reconstructed φ; list length/completeness/sort exact; f matches Eq. (C.7)/(C.12).
**Not covered:** Absolute CYL2D eigenvalues (see ISO_CYL2D_EXACT / CYL2D_C1).
**Recorded outcome:** **met**, 173/173 (first run 2026-10-23)
**Explanation:** Isolated analytic check: at each stored wall angle, `acoustic_boundary_value` must return the stored φ; `cabin_modes_3d` must list every (q,i) once, sorted by frequency, with f from the printed formula written in the case.
Inputs: `cyl2d_modes(56.6°; NY=10)`; a = 0.508 m, L = test_article_length(), q_max = 3.
Equations: linear interpolate in θ; f_n = (c0/2π)√(λ_i/a² + (qπ/L)²).
Outputs: φ, f; verdict ≤ 1e-9 / exact list.

### Case: CYL2D_WEYL
**Title:** Cabin mode count vs Weyl's law (62)
**Map / block:** total / X_CYL_OUT
**Category:** verification
**Kind:** runnable
**Source:** Weyl's law (leading term 4πVf³/(3c³)); phase 62 criterion 2026-10-23
**What it tests:** The cumulative number of 3-D cabin modes (CYL2D × axial, NY = 10, 120 cross-section modes) below f, at 500–1500 Hz.
**Why it is here:** Gives the cabin-mode output block a check with its own figure; a mode count far from Weyl means missing or spurious modes.
**A pass means:** Within 25 % of the Weyl leading term at every listed frequency.
**Not covered:** Mode shapes; the 2-D modes above the 20 PAIN uses.
**Recorded outcome:** **not met**, 0/5 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`): N/W = 1.71, 1.59, 1.49, 1.56, 1.87. Post-hoc: with the Neumann surface term N/W = 0.99, 1.07, 1.10, 1.21, 1.51
**Explanation:** Post-hoc diagnosis (2026-10-24, after the result): the App. C 5-point grid at NY = 10 has h = 0.2a, and its eigenvalues fall below the exact ones as kh grows (near-circle limit θ0 = 2°: k-th FD mode / k-th exact J′ zero = 0.98 at kh = 0.4, 0.80 at kh = 2.4, 0.73 at kh = 2.9; NY = 20: 0.93 at kh = 1.5). Frequencies computed too low put more modes below each f, which is the overcount that grows with f. This is a resolution limit of the App. C grid as printed (Fig. C-3 uses NY = 10), recorded as such; the criterion is unchanged.
Inputs: θ0 = 56.6°, NY = 10, n_modes = 120, a = 0.508 m, L = 1.83 m.
Equations: Weyl N(f) = 4πVf³/(3c³) (+ Sf²/(4c²), post-hoc)
Outputs: N(f) and W(f).

### Chunk 6: Trim and loss (`G_TRIM`)

Blocks in map order: `X_TRIM_IN` Trim stack → `P_TRIM` Trim and loss → `X_TRIM_OUT` τ, η. Cases are listed block by block, in the order the map shows them.

### Case: TRIM_INPUT_QA
**Title:** Phase III trim vs CR-3813 p. E-9 (62)
**Map / block:** total / X_TRIM_IN
**Category:** input_qa
**Kind:** runnable
**Source:** CR-3813 App. E p. E-8/E-9 (`appE_article_inputs.csv`); phase 62 criterion 2026-10-23
**What it tests:** Every Phase III trim value the code uses (layer count and thickness, fiberglass density, facing and septum masses) against the printed value.
**Why it is here:** Gives the trim input block a check with its own figure.
**A pass means:** Every code value equals the printed value to its printed digits.
**Not covered:** Values CR-3813 does not give (facing side, G-10 wavespeed, connection count: register f).
**Recorded outcome:** **met**, 7/7 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`)
**Explanation:** Input QA against the printed page; nothing chosen from a result.
Inputs: phase3_trim() defaults; appE_article_inputs.csv.
Equations: —
Outputs: code / printed per quantity.

### Case: UT_TRIM
**Title:** Trim / loss (Pkg.test)
**Map / block:** total / P_TRIM
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
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
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
**Source:** CR-3813 Eqs. (63)–(73); phase 40g criterion 2026-10-23
**What it tests:** `structural_joint_acceptance` against direct numerical quadrature of the joint-acceptance integral for three Table D-1 modes.
**Why it is here:** Previously only self-consistency / coarse unit-test quadrature.
**A pass means:** ≤ 1e-4 relative (mode-normalized and printed forms).
**Not covered:** End-to-end η_r vs Fig. E-15.
**Recorded outcome:** **met**, 6/6, max rel ≈ 2.7e-5 (first run 2026-10-23)
**Explanation:** Isolated analytic check: independent ring and axial sinc-kernel quadratures written in the case; product compared to `structural_joint_acceptance` at ω = ω_r for three modes.
Inputs: Table D-1 modes 1, 4, 8; a = 0.508 m, L = test_article_length(), c0 = 340 m/s.
Equations: Eqs. (63)–(73) via quadrature; code `structural_joint_acceptance`.
Outputs: j²; verdict ≤ 1e-4 relative.

### Case: TRIM_CLOSED
**Title:** Two-layer trim vs closed-form transfer matrix (41b)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 App. A; Fig. A-2; phase 41b criterion 2026-10-23
**What it tests:** `trim_tau` / `trim_conductance` of limp septum on a porous layer against the closed-form 2×2 product written in the case.
**Why it is here:** Isolates App. A stack algebra for failing E14_LOSS / E15.
**A pass means:** ≤ 1e-9 relative at the six Fig. A-2 frequencies.
**Not covered:** Full Phase III multi-layer stack; mechanical path.
**Recorded outcome:** **met**, 12/12 (first run 2026-10-23)
**Explanation:** Isolated analytic check: M = M_limp·M_ins written from Eqs. (A.10)–(A.11) in the case (independent of `stack_matrix`); τ = |a11|⁻² and ξ = Re β compared to `trim_tau` / `trim_conductance`.
Inputs: PF-105 Fig. A-2 table; thick = 0.051 m; m_sept = 0.5 kg/m²; η = 0.05; m_wall = 5 kg/m².
Equations: App. A (A.10)–(A.16).
Outputs: τ, ξ; verdict ≤ 1e-9 relative.

### Case: R172428_ETA
**Title:** CR-172428 structural loss factors η_r′ vs App. B (44c/44d)
**Map / block:** total / P_TRIM
**Category:** verification
**Kind:** runnable
**Source:** NASA CR-172428 App. B p. 194 (η_r′ of the first 32 structural modes); sub-criterion of 44d dated 2026-10-23
**What it tests:** η_r′ of Eq. (82) with the App. A trimmed-area modal mass (m̄_r = m M_r / M_r^X, M_r^X = shell bending generalized mass, ETASTR GMASS(IR,2)) and Table 6 inputs, mode by mode, against NASA's printed list.
**Why it is here:** The η_r′ correction is the documented change between CR-3813 and CR-172428; this checks that it is implemented as NASA programmed it.
**A pass means:** η_r′ of each listed mode within ±25 % of App. B.
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
**Source:** NASA CR-172428 App. B p. 197; no criterion (the comparison was first made 2026-10-23 without one fixed beforehand)
**What it tests:** The trim transfer-matrix model (`trim_tau`, `trim_admittance`) with NASA's printed trim inputs, against NASA's printed trim factor and admittances, 100–5000 Hz.
**Why it is here:** An independent code check of the trim block on a different stack than CR-3813's Phase III trim.
**A pass means:** No criterion (always `:no_verdict`).
**Not covered:** Bands below 100 Hz (outside the PF105 table of Fig. A-2).
**Recorded outcome:** diagnostic: trim factor within 0.15 dB of NASA at 250–1000 Hz, 1.65 dB at the 200 Hz trim resonance, up to 2.1 dB at 1.25–5 kHz; sidewall admittance within a few percent away from the resonance (first run 2026-10-23).
**Explanation:** Sidewall stack `[InsulationLayer(0.0508, PF105), LimpMass(1.456, 0.13)]`, end cap `[InsulationLayer(0.0127, PF105), LimpMass(0, 1)]`, m_wall = 3.113 kg/m².
Inputs: App. B p. 197.
Equations: App. A trim matrices.
Outputs: trim factor [dB] and admittance per band.

### Case: TRIM_PASSIVITY
**Title:** Phase III trim is passive: ξ ≥ 0, η_n ≥ 0 (62)
**Map / block:** total / X_TRIM_OUT
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 App. A (energy: a passive wall absorbs); phase 62 criterion 2026-10-23
**What it tests:** The wall conductance ξ, the end-plate conductance, η_n of Eq. (77) and τ_t of Eq. (A.22) at every 1/3-octave band 100–6300 Hz.
**Why it is here:** Gives the trim output block a check with its own figure (τ_t and ξ vs f); a sign error in the transfer matrices shows up as negative absorption.
**A pass means:** ξ ≥ 0 and η_n ≥ 0 at every band, τ_t > 0.
**Not covered:** The size of τ_t (no measured trim transmission for the article).
**Recorded outcome:** **met**, 17/17 (first run 2026-10-23; `phase62_65_map_blocks_grid.md`)
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
**Source:** User Manual cards 2, 9 and the grid relation (pp. 8–9); PainInputs docstring; phase 62 criterion 2026-10-23
**What it tests:** The inputs the PAIN core resolves for the T1 run (grid cell area, wall mass, cavity length, interior sound speed and density) against the formulas the documents give.
**Why it is here:** Gives the PAIN input block a check with its own figure; defaults resolved in the wrong place change every result without an error.
**A pass means:** Each within 1e-12 relative.
**Not covered:** Whether the documented defaults are right for an aircraft (X-EXTRAP).
**Recorded outcome:** **met**, 5/5 (first run 2026-10-23; re-run 2026-10-24 with m_wall built from the printed App. E dimensions instead of the MRP_* constants PainInputs uses, code review; `phase62_65_map_blocks_grid.md`)
**Explanation:** Echo check: ΔA = (πa/18)², m_wall = ρ(t + A_s/d_s + A_f/ℓ_f), L_c = L, c_int = c0 = 340 m/s, ρ_int = ρ0 = 1.225 kg/m³.
Inputs: T1 pipeline inputs.
Equations: card 2, 9 rules; ΔA of the grid
Outputs: code / documented per quantity.

### Case: UT_EQ8
**Title:** Eq. (8) coupling + HF tones (Pkg.test)
**Map / block:** total / P_EQ8
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

### Case: ISO_MODAL_DENSITY
**Title:** structural_modal_density and band_joint_acceptance
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Source:** phase 40h criterion 2026-10-23
**What it tests:** Modal density equals the count of modes in each 1/3-octave band / Δω; band-average joint acceptance matches an independent discrete average.
**Why it is here:** Broadband helpers were untested in isolation (audit NONE).
**A pass means:** Count exact; band JA ≤ 1e-6 relative.
**Not covered:** Asymptotic fallback when a band is empty; experimental broadband levels.
**Recorded outcome:** **met**, 12/12 (first run 2026-10-23) **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** met 12/12 unchanged (round-off only).
**Explanation:** Isolated analytic check: for bands that contain Table D-1 modes, `structural_modal_density` must equal n_count/Δω; `band_joint_acceptance` must equal the mean of j² from Eq. 42 sums and the j² formula written in the case (mode-shaped blocked field; reference applies the same 1e-6 clamp floor as the function).
Inputs: Table D-1 modes; blocked grid A = 1 + ψ_1; test-article geometry.
Equations: third-octave Δf/f = 0.2316; discrete Ψ and j² as in §3.5–3.6.
Outputs: n(ω), ⟨j²⟩; verdict count exact / ≤ 1e-6.

### Case: ISO_BB_BAND
**Title:** blocked_broadband_band_p2 vs closed-form band integral
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Source:** phase 40i criterion 2026-10-23
**What it tests:** Band integral of S ∝ f^(−α) over exact 1/3-octave limits against the closed form (not the band-centre rectangle).
**Why it is here:** Band integral helper was untested (and previously compared to the same rectangle the code used, so it passed by construction).
**A pass means:** ≤ 1e-9 relative.
**Not covered:** Cabin broadband ⟨p²⟩ path / Fig. E-9.
**Recorded outcome:** **met**, 8/8 (reference corrected 2026-10-23; code fixed to the exact integral the same day — code-on-code). First registration had compared the rectangle to itself (4/4, void as evidence).
**Explanation:** Isolated analytic check: Spbl_a from the H = 3 tone spatial mean spread by Δω_a = 0.232·2π·f_a (same anchor as `blocked_broadband_band_p2` in `pain_core.jl`); reference = ∫_{f1}^{f2} Spbl_a (f_a/f)^α · 2π df with f1 = fc·2^(−1/6), f2 = fc·2^(1/6) (α = 1 uses the log form). Compared to `blocked_broadband_band_p2` after the 2026-10-23 integral fix (was Spbl(fc)·0.232·2π·fc).
Inputs: synthetic blocked amplitudes; α ∈ {2.0, 1.5}; bpf = 200 Hz; fc ∈ {1000,1250,1600,2000} Hz.
Equations: closed-form power-law band integral; code `blocked_broadband_band_p2`.
Outputs: ⟨p²⟩_bl [Pa²]; verdict ≤ 1e-9 relative. Dependent recorded results that multiply this ⟨p²⟩_bl (T2 / T2_EQ19 / parametric HF bands, default α = 2) shift by −0.0082 dB at 1.25/1.6/2 kHz — not re-recorded here.

### Case: NR_BAND_HAND
**Title:** One-band NR vs hand Eqs. (17)–(18) (41c)
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Eqs. (17)–(18); phase 41c criterion 2026-10-23
**What it tests:** One band of `noise_reduction_band` (one structural mode, one acoustic mode, stated η) against a hand evaluation of Eq. (18) with brace arithmetic written in the case.
**Why it is here:** Isolates the NR band assembly for failing E21_E22_NR.
**A pass means:** ≤ 1e-9 dB.
**Not covered:** Full multi-mode spectrum; HF Eqs. (19)–(23).
**Recorded outcome:** **met**, residual 0 dB (first run 2026-10-23)
**Explanation:** Isolated analytic check: brace/ln/arctan/D_nr written in the case (not `nr_*`); same η_n / η_r′+η_r'' path as the function; compared to `noise_reduction_band`.
Inputs: bare cabin; fc = 400 Hz; η_n_band = 0.05; η_r_band = 0.08; q_max = 0; one mode each.
Equations: Eq. (18) hand brace; code `noise_reduction_band`.
Outputs: NR [dB]; verdict ≤ 1e-9 dB.

### Case: HF_MASSLAW
**Title:** hf_transmission_coeffs vs hand Eq. (20) (41d)
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Eq. (20) / p. 24; phase 41d criterion 2026-10-23
**What it tests:** `hf_transmission_coeffs` against the documented field-incidence Eq. (20) τ_f plus the printed τ_R (not the normal-incidence mass law). It uses one limp wall mode in the band (τ_R) and one below it (τ_f). Eq. (20) sums the modes resonant below the band (CR-3813 p. 24); the in-band reading was corrected on 2026-10-23 (Phase 49).
**Why it is here:** Isolates HF transmission for failing T2 / T2_EQ19.
**A pass means:** ≤ 1e-9 relative.
**Not covered:** Normal-incidence τ = 1/(1+(ωm/2ρc)²) — the function documents field-incidence Eq. (20).
**Recorded outcome:** **met**, 3/3 (first run 2026-10-23; re-run 2026-10-23 after the Phase 49 correction, met)
**Explanation:** Isolated analytic check: hand Eq. (20) and printed τ_R at fc = 1000 Hz against `hf_transmission_coeffs`.
Inputs: bare cabin; m_wall = 8 kg/m²; one mode at 1000 Hz and one at 700 Hz.
Equations: Eq. (20); printed τ_R; code `hf_transmission_coeffs`.
Outputs: τ_f, τ_R, τ; verdict ≤ 1e-9 relative.

### Case: SHARP_PANEL_D
**Title:** Sharp double-panel construction vs CR-172490 Fig. 15, Panel D (59a)
**Map / block:** total / P_EQ8
**Category:** verification
**Kind:** runnable
**Source:** NASA CR-172490 Fig. 15 and Fig. A-7; criterion fixed 2026-10-23
**What it tests:** The Sharp double-panel construction (Eqs. 5, 22, 23, 25; Fig. 5) against the source's own predicted curve for its Panel D.
**Why it is here:** It checks the bridge model's implementation before the model is used in Eq. (23).
**A pass means:** Within 1 dB at ≥ 90 % of the points 50–2000 Hz with ΔTL_M = 12 dB as stated.
**Not covered:** The source states ΔTL_M only approximately ("on the order of 12 dB"); the figure implies 10.2 dB.
**Recorded outcome:** **not_met**, 3/13 (2026-10-23); the mass law is about 1 dB under the figure and the bridged line about 1.3 dB over it.
**Explanation:** Code-on-source. `sharp_double_panel_TL`.
Inputs: `data/cr172490/cr172490_fig15_panelD.csv`.
Equations: CR-172490 Eqs. (5), (22), (23), (25).
Outputs: TL [dB].

### Case: ISO_SIL
**Title:** sil_dB / sil_from_third_octave hand spectrum
**Map / block:** total / X_OUT
**Category:** verification
**Kind:** runnable
**Source:** phase 40k criterion 2026-10-23
**What it tests:** Hand-computed SIL from a known octave / 1/3-octave spectrum.
**Why it is here:** SIL helpers had only finite-value checks.
**A pass means:** ≤ 1e-9 dB.
**Not covered:** A-weighting / overall dB(A) (separate unit tests).
**Recorded outcome:** **met**, 2/2 (first run 2026-10-23)
**Explanation:** Isolated analytic check: SIL = mean of 500/1000/2000/4000 Hz octave SPLs; 1/3-octave path energy-sums bands into those octaves then averages — both formulas written in the case.
Inputs: stated octave and 1/3-octave dicts.
Equations: `sil_dB`, `sil_from_third_octave`.
Outputs: SIL [dB]; verdict ≤ 1e-9 dB.

### Case: LOUDEST_PT
**Title:** Interior level at the loudest point (42)
**Map / block:** total / X_OUT
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Eq. (8) and App. C (Eqs. C.9–C.11); criteria fixed 2026-10-23 (plan Phase 42)
**What it tests:** The point form of Eq. (8). Acoustic modes add coherently at each interior point for every structural mode, and structural modes add in mean square. The checks: the volume average of the point values against the space average; the loudest point at or above the average; a single acoustic mode reproducing φ².
**Why it is here:** PAIN reports a space average; the loudest point is what a passenger hears at the worst seat. It is a derived output with no experimental criterion (the E-16 means are space averages).
**A pass means:** (a) the interior-node average is within 1 % of Eq. (8) for H1–H3; (b) loudest-point dB(A) ≥ space-average dB(A); (c) one mode alone gives ⟨p²⟩ ∝ φ_i² (spread ≤ 1e-9).
**Not covered:** Measured point levels; broadband at points (taken as diffuse, space-average level everywhere); tones above the changeover under `:auto` (taken as diffuse). The loudest-point position depends on the sign convention of antisymmetric modes (open item 44f).
**Recorded outcome:** **not_met** (first run 2026-10-23): (a) not met: 0.938 / 0.877 / 0.834. The point set excludes wall and floor nodes, where rigid-wall modes have antinodes; the ε_n normalization is exact over all nodes (ε·Φ_G/A = 1.000). (b) met: +4.6 dB. (c) met: 7e-16. Supplementary, labelled post-hoc: all nodes with the Eq. (C.10) weights give 1.027 / 1.004 / 0.986, the residual being the discrete orthogonality of the CYL2D eigenvectors. Test article: space average 79.1 dB(A), loudest point 83.7 dB(A) at X = −0.39 m, Y = −0.20 m, z = 0.92 m. Aircraft example (`aircraft_scale_hartzell.json`, X-EXTRAP): 93.8 dB(A) average, 98.4 dB(A) at the loudest point (z = 0, the forward end). **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** (a) 0.936 / 0.886 / 0.901 (all-node 1.011 / 0.995 / 0.978); test article 80.4 dB(A) average, 85.5 dB(A) at the loudest point. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** test article 80.0 dB(A) space average, 84.3 dB(A) loudest point (was 80.4 / 85.5); (a) not met unchanged.
**Explanation:** `cabin_interior_points`, `point_tone_p2`, `loudest_point` in `loudest_point.jl`; `cabin_quadrature_points` for the supplementary check.
Inputs: T1 test-article inputs; aircraft example.
Equations: Eq. (8) at points; φ_n = cos(qπz/L_c) φ_i(node) (Eq. C.9).
Outputs: point tone levels, loudest-point and space-average dB(A), position.

### Chunk 8: Validation comparisons (`G_VAL`)

Blocks in map order: `P_REPRO` vs NASA PAIN → `P_MEAS` vs measurement → `A_CABIN` Aircraft cabin. Cases are listed block by block, in the order the map shows them.

### Case: REPRO_18b
**Title:** PAIN reproduction (18b-r)
**Map / block:** total / P_REPRO
**Category:** calibrated
**Kind:** runnable
**Source:** CR-3813 Fig. E-16 NASA PAIN circles, p.142
**What it tests:** Whole cabin chain on ANOPP Table 8 with R1 vs NASA's PAIN interior predictions.
**Why it is here:** Shows whether this chain computes what NASA's program computed (code-on-code).
**A pass means:** Code-to-code agreement within 4 dB per harmonic H1–H3.
**Not covered:** η_T = 0.5 adopted after 19f showed the result (post-hoc); conditional on GEXT; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** 18b-r not met 1/3: 85.90, 78.35, 79.82 dB at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 85.74, 78.74, 80.06 — `length_sensitivity.md` / `pain_reproduction_e16.md`). Phase 38b `:auto` (report only, ten-mode crossover): 85.90, 16.81, 72.24 dB; H3 Δ=+4.24 (I-18 explains H3 = no); `phase38b_high_freq_tones.md`. **43a post-hoc re-run (2026-10-23):** Manual card 10 volume crossover default (f≈1299.6 Hz → band 1260 Hz); `:auto` H1–H3 = 85.90, 78.35, 79.82 dB (= `:eq8`; old ten-mode `:auto` kept above). Isolation case T1_FROM_E12 (41a) also not met (2/3, H3 fails) → cabin chain implicated, not source/blocking alone. **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 85.93, 78.32, 79.57 dB; 1/3, verdict unchanged. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 0/3 (89.03, 81.24, 77.06 dB). REPRO_18b compares with NASA's pre-correction CR-3813 run, which used the other sign. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 0/3 (88.20, 80.43, 78.21 dB; was 89.03, 81.24, 77.06).
**Explanation:** Code-on-code (against printed values): run the cabin chain on ANOPP Table 8 with blocking R1 and Phase III trim η_T = 0.5 (NASA's value) and compare interior SPL with NASA's PAIN circles on Fig. E-16 (±4 dB per harmonic). Axes: harmonic band vs SPL; NASA circles vs this code. η_T = 0.5 was adopted after 19f → post-hoc. Conditional on GEXT.
Inputs: `default_e11_paths().anopp_spl`; `phase3_trim(; η_lining=0.5)`; blocking R1; BPF = 200 Hz; n_harmonics = 3; L = 1.83 m; targets `t1_interior_targets.csv` (NASA PAIN column).
Equations: full cabin chain; tone Eq. (8) via `run_pain_pipeline` / `tone_mean_square_pressure`; blocking Eq. (43) R1.
Outputs: interior SPL_H1..H3 [dB]; verdict |Δ| ≤ 4 dB vs NASA PAIN prediction.

### Case: E18_TONES
**Title:** Fig. E-18 tones (η_T=1)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Fig. E-18, p.E-29; e18_interior_pred_eta1.csv
**What it tests:** Tones with η_T = 1.0 and η_r′ ≤ 0.15 vs NASA E-18 prediction.
**Why it is here:** NASA's η_T = 1.0 / capped-η_r′ setting (same as E-21) on the tone path.
**A pass means:** |computed − NASA E-18 prediction| ≤ 4 dB at each of H1–H3 (bands 200, 400, 630 Hz).
**Not covered:** :auto and measured mean/low/high are secondary (V-EXP held out); no parameter from E-18.
**Recorded outcome:** 2/3 within ±4 dB (88.67, 77.78, 77.55 dB) at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 89.02, 78.14, 77.70); not met; e18_tones_eta1.md. **43a post-hoc re-run (2026-10-23):** volume crossover default; production `:eq8` unchanged 88.67, 77.78, 77.55; `:auto` old (ten-mode) 88.67, 13.18, 67.39 → new (volume) 88.67, 77.78, 77.55. **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 2/3 unchanged; `:auto` secondary 88.69, 77.76, 77.33 dB. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 1/3; `:auto` secondary 91.17, 80.44, 75.24 dB (E-18 is also a pre-correction run). **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 1/3 unchanged; `:auto` secondary 90.35, 79.63, 76.56 dB (was 91.17, 80.44, 75.24).
**Explanation:** Code-on-code (against NASA prediction): same free-field/blocking/grid as 18b-r but Phase III trim η_T = 1.0 and η_r_cap = 0.15 on the tone path (`tone_model=:eq8`). H1–H3 map to 200, 400, 630 Hz (H3 at 3·BPF = 600 Hz → 630 Hz 1/3-octave band). Criterion dated 2026-10-21 (same ±4 dB as 18b).
Inputs: `default_e11_paths()`; `phase3_trim(; η_lining=1.0)`; η_r_cap = 0.15; BPF = 200 Hz; L = 1.83 m; `e18_interior_pred_eta1.csv`.
Equations: Eq. (8) tones; Eq. (82) capped η_r′; blocking as in pipeline.
Outputs: interior SPL [dB] at 200/400/630 Hz; verdict ≤ 4 dB vs NASA E-18 prediction.

### Case: NR_TP1964_XOVER_REF2
**Title:** TP-1964 NR with changeover vs NASA ref. 2 (45b)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Source:** NASA TP-1964 Fig. 8 predicted curve (ref. 2); criterion pre-registered 2026-10-23 (plan §8c)
**What it tests:** As NR_TP1964_XOVER, against NASA's predicted curve.
**Why it is here:** It is a code comparison for the same path.
**A pass means:** Within ±3 dB in ≥ 75 % of the bands 100–5000 Hz.
**Not covered:** As NR_TP1964_XOVER.
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
**Source:** CR-3813 Fig. E-16 NASA prediction; CR-172428 p. 178; criterion fixed 2026-10-23
**What it tests:** The tone chain with the floor-term sign of NASA's program before its CR-172428 correction, against CR-3813's printed prediction.
**Why it is here:** CR-3813's runs predate the correction; this tests whether that explains REPRO_18b's 6–10 dB.
**A pass means:** |Δ| ≤ 4 dB at H1–H3.
**Not covered:** Other undocumented differences in NASA's 1983 runs.
**Recorded outcome:** **not_met**, 1/3 (2026-10-23): 85.93, 78.32, 79.57 dB against 79.0, 75.5, 68.0 dB (corrected form 89.03, 81.24, 77.06). **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 1/3 unchanged (85.11, 77.61, 81.85 dB; corrected form 88.20, 80.43, 78.21).
**Explanation:** Code-on-code. `floor_sign = −1`.
Inputs: As REPRO_18b.
Equations: Eq. (8), Eq. (52).
Outputs: SPL H1–H3 [dB].

### Case: E21_PRE
**Title:** E-21 NASA NR with NASA's pre-correction Eq. (52) floor sign (61c)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Fig. E-21 NASA prediction; criterion fixed 2026-10-23
**What it tests:** Eq. (18) with the pre-correction floor sign against NASA's printed NR prediction.
**Why it is here:** It is the same question for the noise-reduction path.
**A pass means:** |Δ| ≤ 3 dB in ≥ 75 % of the counted bands (38a).
**Not covered:** As REPRO_18b_PRE.
**Recorded outcome:** **not_met**, 1/4 (2026-10-23); 400–630 Hz within 0.6–1.9 dB (not counted); 800–1000 Hz 6–18 dB above NASA.
**Explanation:** Code-on-code. `floor_sign = −1`, E-21 inputs.
Inputs: E-21 inputs.
Equations: Eq. (18), Eq. (52).
Outputs: NR [dB].

### Case: E22_HF_CODE
**Title:** High-frequency NR, this code vs NASA's E-22 prediction (61d)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Fig. E-22 NASA prediction and measured mean; criterion fixed 2026-10-23
**What it tests:** Eqs. (19)–(23) against NASA's printed high-frequency NR, next to the measurement.
**Why it is here:** It is the evidence behind attributing T2's high-frequency gap to the method.
**A pass means:** |Δ| ≤ 3 dB of NASA in ≥ 75 % of the bands 1250–2500 Hz.
**Not covered:** NASA's 1983 high-frequency routine is not printed.
**Recorded outcome:** **not_met**, 1/4 (2026-10-23): code − NASA +7.7, +2.1, −6.5, −5.6 dB; NASA − measured +32.5, +33.5, +43.5, +37.0 dB.
**Explanation:** Code-on-code. `hf_pressure_ratio`, E-21 inputs.
Inputs: E-22 data; E-21 inputs.
Equations: Eqs. (19)–(23).
Outputs: NR [dB].

### Case: R172428_CODE
**Title:** CR-172428 reproduction: NASA's inputs vs NASA's printed predictions (44d)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
**Source:** NASA CR-172428 App. B (blocked field pp. 198–210, predictions p. 206) and Table 10; criterion dated 2026-10-23 before any transcription or run
**What it tests:** This code's cabin chain run on NASA's own inputs, compared with what NASA's program printed for the same inputs. Inputs: the printed App. B blocked pressure field on the 16 × 19 grid PAIN used (as input, so no GEXT and no blocking model), Table 6 and the App. B trim page, the App. A η_r′ correction.
**Why it is here:** It is the cleanest code-on-code test of the cabin chain on the test article. CR-3813's own E-17/E-18 runs came from the program before NASA's App. A corrections.
**A pass means:** Within ±3 dB of NASA's printed prediction at ≥ 7 of the 9 points (3000/4000/5000 rpm, H1–H3).
**Not covered:** NASA used 300 structural and 400 acoustic modes; this run uses the 32 Table D-1 modes (the same first 32 as App. B) and 20 CYL2D cross-section modes. Phases of rows at the page edge are missing (p. 198 L = 1–2 and L = 3 k = 16, p. 200 L = 1, p. 204 L = 1, p. 208 L = 1); those cells are left out (amplitudes 30–40 dB below the peak).
**Recorded outcome:** **not_met**, 3/9 within ±3 dB (first run 2026-10-23). Ours − NASA: 3000 rpm +5.0 / +2.8 / +1.1 dB; 4000 rpm +8.6 / −3.5 / +2.6 dB; 5000 rpm +3.1 / +7.6 / +3.5 dB. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 4/9 within ±3 dB (3000: 71.07 / 69.02 / 62.66; 4000: 102.45 / 80.05 / 71.69; 5000: 90.35 / 94.40 / 78.40 dB). The 4000 rpm H2 and H3 now agree with NASA (+1.9, +0.4 dB); H1 is dominated by the (0,1) × mode 8 pair (open item Q22).
**Explanation:** `r172428_inputs(rpm)`: L = 1.803 m, L_c = 1.829 m, shell mass 3.113 kg/m², r_p = 0.9652 m, z_p = 0.662 m, rotation +1; bare η_r = 2/f per band; sidewall trim of PF105 0.0508 m with a 1.456 kg/m² panel and η = 0.13, end caps of PF105 0.0127 m with no panel; no mechanical path; c₀ = 343 m/s (from the printed axial mode 93.78 Hz = c₀/2L_c); `η_r_trimmed_area = true`. The field is `data/cr172428/appB_<rpm>rpm_H<H>.csv`.
Inputs: App. B blocked field; Table 6; App. B p. 197 trim.
Equations: Eq. (8) on the 16 × 19 grid; App. A Eq. (82) with m̄_r; Eq. (83) with the bare f′.
Outputs: 9 interior tone levels [dB] next to NASA's printed values; verdict vs ±3 dB at ≥ 7/9.

### Case: R172428_PAIRS
**Title:** CR-172428 top modal contributions vs App. B (diagnostic)
**Map / block:** total / P_REPRO
**Category:** verification
**Kind:** runnable
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
**Source:** CR-3813 Fig. E-16 measured means; phase 31 pre-registration 2026-10-22
**What it tests:** Whether the untuned parametric cabin Monte Carlo P5–P95 band (NASA free field, a-priori ranges) contains the measured E-16 mean at H1–H3.
**Why it is here:** Coverage check on the test article before trusting the aircraft epistemic band; can fail without widening ranges in this run.
**A pass means:** Measured mean at each of H1, H2, H3 lies inside the primary (uniform) MC P5–P95; `:met` only if all three.
**Not covered:** Not a confidence interval; no E-16 envelope floor; no tuned value; scattering/refraction excluded (V-ASSUMED); aircraft source residuals not in this check.
**Recorded outcome:** `:not_met` — H1 P5/P50/P95 88.95/89.87/91.06 vs mean 90 (inside, margin +1.05 dB); H2 85.46/91.3/92.86 vs 80 (miss −5.46); H3 73.09/74.78/77.59 vs 65 (miss −8.09); kept `freq_scale`, `eta_t`; `uncertainty_budget_testarticle.md` (first run 2026-10-22) **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 0/3 within criterion (H1 margin −0.86 dB, was +1.05; H2 −5.45, H3 −8.09); verdict unchanged (not_met). **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 0/3 (margins −0.81, −5.87, −10.24 dB).
**Explanation:** Experiment comparison (V-EXP vs measured E-16 means; first run 2026-10-22; pre-registered): untuned `:parametric` chain on the NASA test article with the phase-31 a-priori budget; OAT keep (>3 dB); primary Monte Carlo N=4000 seed 20261022; plot P5–P95 band with measured means. Failure means a missing contributor or ranges too narrow — do not widen here.
Inputs: `cabin_blocks=:parametric`, `source=:e11`, Phase III trim path with η_t in 0.01–0.10 (nominal 0.05), C 2–4, freq scale 0.95–1.05, discrete CYL2D/q_max/blocking/trim alternatives; `t1_interior_targets.csv` measured means 90/80/65 dB; L = 1.83 m.
Equations: App. D modes + Eq. (8) tones; App. A trim; no E-16 envelope in the band.
Outputs: P5/P50/P95 [dB] per H1–H3; per-harmonic inside/margin; verdict `:met`|`:not_met`.

### Case: T1
**Title:** Tonal interior SPL (T1)
**Map / block:** total / P_MEAS
**Category:** calibrated
**Kind:** runnable
**Source:** CR-3813 Fig. E-16/E-17, p.142
**What it tests:** End-to-end tonal interior SPL on the e11 measured free-field path vs Fig. E-16/E-17.
**Why it is here:** Only end-to-end tonal SPL check against measurement (still not claimable after GEXT_BOUND).
**A pass means:** In-sample consistency (gate A mean ± 4 dB, or gate B envelope + NASA ± 4 dB).
**Not covered:** No claim: GEXT variants flip it; H3 fails; amplitude convention fixed 2026-10-21, post-hoc.
**Recorded outcome:** 84.21, 77.66, 78.06 dB at L = 1.83 m (H1 fail, H2 pass, H3 fail); t1_tonal.md (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 84.05, 78.01, 78.30). **43a post-hoc re-run (2026-10-23):** volume crossover default; production `:eq8` unchanged 84.21, 77.66, 78.06; `:auto` old (ten-mode) 84.21, 16.22, 70.54 → new (volume) 84.21, 77.66, 78.06. Isolation case T1_FROM_E12 (41a) also not met (2/3, H3 fails) → cabin chain implicated, not source/blocking alone. Related: T1_MEAS_DAMPING (43b), T1_F1A_FILL (43f). **Phase 44 knock-on (2026-10-23, code-on-code fix of Eq. (83): η_r″ uses the bare f′):** 84.24, 77.63, 77.80 dB; verdict unchanged. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 87.36, 81.02, 75.23 dB; H1 and H2 now within the gate, H3 fails (+10.2 dB); verdict not_met. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 86.59, 80.02, 76.39 dB (was 87.36, 81.02, 75.23); H1 and H2 within the gate, H3 fails (+11.4 dB); verdict not_met.
**Explanation:** Experiment comparison (calibrated / in-sample): e11 free-field → GEXT → blocking R2 → modes → Eq. (8) → interior tonal SPL vs measured Fig. E-16/E-17. Gate A: |got − measured mean| ≤ 4 dB; gate B: inside measured envelope and |got − NASA PAIN| ≤ 4 dB. Axes: 1/3-octave band vs SPL. No claim after GEXT_BOUND.
Inputs: `run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200, blocking=R2)`; η_T = 0.5 default path; `t1_interior_targets.csv`; L = 1.83 m.
Equations: full chain; Eq. (8); GEXT; Eq. (43) R2.
Outputs: SPL_H1..H3 [dB]; verdict on gates A/B (still labeled not claimable).

### Case: T2
**Title:** 1/3-octave (T2)
**Map / block:** total / P_MEAS
**Category:** calibrated
**Kind:** runnable
**Source:** CR-3813 Fig. E-9, p.132
**What it tests:** Broadband 1/3-octave interior SPL (surrogate path) vs Fig. E-9 at 1.25–2 kHz.
**Why it is here:** Tonal model puts no energy above 1 kHz; this covers three high bands (surrogate).
**A pass means:** In-sample: |got − measured mean| ≤ tol_dB from CSV; bb_j2_scale = 0.5 was fitted earlier (stale).
**Not covered:** Only 1.25–2 kHz; nothing above; amplitude convention fixed 2026-10-21, post-hoc. The exterior broadband input is modelled (V-ASSUMED). Phase 47 (2026-10-23) found a measured exterior for this article: the modelled one is 17 dB above it, and with the measured exterior this path gives 38.6 dB (Eqs. 19–23: 21.6 dB) against 51.0 dB at 1250 Hz. The surrogate's closeness to E-9 therefore rests on compensating errors. Phase 55 decision (2026-10-23): it stays the production default, labelled calibrated, because neither cabin path is validated above 1 kHz and switching would change the frozen baselines.
**Recorded outcome:** 55.92, 53.56, 51.59 dB at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 55.97, 53.63, 51.67); t2_third_octave.md. Isolation case HF_MASSLAW (41d); isolation passes: remaining miss attributed to model fidelity (method), not code.
**Explanation:** Experiment comparison (calibrated): surrogate broadband path vs Fig. E-9 means at 1.25, 1.6, 2 kHz. bb_j2_scale = 0.5 fitted earlier → post-hoc. Printed Eqs. (19)–(23) are case T2_EQ19.
Inputs: `run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200, blocking=R2)`; `t2_third_octave_targets.csv`; bb_j2_scale = 0.5; L = 1.83 m.
Equations: surrogate broadband (not printed Eqs. 19–23); `evaluate_T2`.
Outputs: 1/3-octave SPL [dB] at target bands; verdict vs CSV tol_dB.

### Case: T2_EQ19
**Title:** 1/3-octave Eq.(19) (T2_EQ19)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** CR-3813 Fig. E-9, p.132; Eqs. (19)–(23) pp.23–25
**What it tests:** Printed high-frequency broadband Eqs. (19)–(23) vs Fig. E-9.
**Why it is here:** First printed-model run replacing the surrogate / stale bb_j2_scale path.
**A pass means:** Same T2 criterion: |got − Fig. E-9 mean| ≤ 3.5 dB at 1.25, 1.6, 2 kHz (criterion unchanged).
**Not covered:** Spbl ∝ f^−2 anchor remains V-ASSUMED; only three bands; no parameter chosen from E-9/E-21/E-22. Exterior broadband not measured for this article; the input is assumed (V-ASSUMED); the high-frequency transmission path is validated by NR_TP1964 (phase 43e, 2026-10-23).
**Recorded outcome:** 0/3 PASS (38.56, 35.81, 34.87 dB vs 51/46/41.5) at L = 1.83 m (I-22 re-record 2026-10-22, post-hoc; earlier 1.803 m: 38.59, 35.87, 34.94); full-band E-21/E-22 V-CODE 1/13, V-EXP 0/15; phase38c_hf_broadband.md. Isolation case HF_MASSLAW (41d); isolation passes: remaining miss attributed to model fidelity (method), not code. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 0/3; full band V-CODE 0/13, V-EXP 1/15. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 0/3 (38.85, 35.94, 34.90 dB); full band V-CODE 0/13, V-EXP 1/15 unchanged.
**Explanation:** Experiment comparison: interior 1/3-octave SPL with `broadband_model=:eq19` (printed τ_f, τ_R, ᾱ from Eq. 24/78, A_t/S/A′) vs Fig. E-9. Default `:surrogate` T2 path unchanged. First run not met; no parameter tuned.
Inputs: same e11 geometry/blocking as T2; `broadband_model=:eq19` via T2_EQ19 runner; targets CSV; L = 1.83 m.
Equations: Eqs. (19)–(23) in `hf_broadband.jl`; related Eq. (24)/(78) absorptions.
Outputs: SPL [dB] at 1.25/1.6/2 kHz; verdict ±3.5 dB; E-21/E-22 full-band counts reported only.

### Case: E21_E22_NR
**Title:** Figs. E-21 / E-22 NR
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** CR-3813 Figs. E-21, E-22, p.149
**What it tests:** Cabin noise reduction NR vs NASA E-21 prediction and E-22 measured confidence limits.
**Why it is here:** Held out of any calibration (23e); first runnable NR check (38a).
**A pass means:** |NR−NASA|≤3 dB at ≥75% of counted bands and NR inside E-22 95% at ≥75% (criterion dated 2026-10-21).
**Not covered:** 80–160 Hz excluded (end-plate V-ASSUMED); counts below crossover only.
**Recorded outcome:** first run 2026-10-21; V-CODE / V-EXP counts below crossover not met (`e21_e22_noise_reduction.md`); held out of calibration (23e). Isolation case NR_BAND_HAND (41c); isolation passes: remaining miss attributed to model fidelity (method), not code. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** V-CODE 0/4, V-EXP 1/4, E-21 range 3/4 (E-21/E-22 are pre-correction runs).
**Explanation:** Experiment comparison: noise reduction NR = 10 log10(⟨p_e²⟩/⟨p_i²⟩) from Eqs. (17)–(18) with Phase III trim η_T = 1.0 and η_r_cap = 0.15 (p. E-30). Compared with NASA E-21 prediction and E-22 95 % limits. Axes: band Hz vs NR [dB].
Inputs: `noise_reduction_test_article_inputs(; η_lining=1.0)`; η_r_cap = 0.15; CSVs `e21_noise_reduction_range.csv`, `e22_noise_reduction_ci.csv`; L = 1.83 m.
Equations: Eqs. (17)–(18) via `noise_reduction_band` / `noise_reduction_spectrum`.
Outputs: NR(band) [dB]; verdict on NASA and E-22 fraction rules.

### Case: T1_FROM_E12
**Title:** T1 from measured E-12 blocked pressures (41a)
**Map / block:** total / P_MEAS
**Category:** verification
**Kind:** runnable
**Source:** CR-3813 Fig. E-12 measured blocked SPL; T1 gate; phase 41a criterion 2026-10-23
**What it tests:** Cabin tonal H1–H3 when ℓ = 1 uses measured E-12 blocked levels (phases from ANOPP Table 8; off-line GEXT as T1; blocking off) against the unchanged T1 gate.
**Why it is here:** Isolates the cabin chain from predicted free field + blocking for the failing T1 / REPRO_18b cases.
**A pass means:** Same T1 gate (±4 dB of measured E-16 mean, or gate B); a pass with T1 failing would attribute T1 to source/blocking.
**Not covered:** E-12 does not cover all ℓ = 1 stations/harmonics (H3 span ≈ [−0.21, 0.22] X3/D); uncovered ℓ = 1 stations keep T1-blocked amplitudes (stated).
**Recorded outcome:** **not_met**, 2/3 (H1–H3 = 81.66, 75.29, 77.89 dB; T1 = 84.21, 77.66, 78.06); H3 fails — cabin chain implicated (first run 2026-10-23) **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 81.70, 75.26, 77.64 dB (T1 84.24, 77.63, 77.80); 2/3 unchanged. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 1/3 (84.99, 79.27, 74.93 dB). **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 1/3 unchanged (84.29, 78.56, 76.39 dB; was 84.99, 79.27, 74.93).
**Explanation:** Isolation: replace predicted free field + blocking on ℓ = 1 with Fig. E-12 measured blocked SPL (digitization A) where covered; phases = ANOPP Table 8; GEXT off-line as T1; Phase III η_T = 0.5. Criterion unchanged from T1.
Inputs: `e12_measured_A.csv`; Table-8 phases; T1 geometry/trim; `t1_interior_targets.csv`.
Equations: Eq. (8) cabin chain; GEXT; no Eq. (43) on the E-12-covered line.
Outputs: H1–H3 [dB]; verdict on T1 gate.

### Case: T1_MEAS_DAMPING
**Title:** T1 with measured η_n / η_r′ (43b)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** CR-3813 Figs. E-13 / E-15 / E-16; η_n = c₀ S α/(4 ω V) p. E-21; criterion = T1 gate, dated 2026-10-23
**What it tests:** T1 cabin tones with measured acoustic absorption (E-13 → η_n) and measured structural decay (E-15 all points → η_r′), everything else as T1.
**Why it is here:** Separates the App. A / §3.8 damping model from the rest of the T1 miss.
**A pass means:** Same T1 gate (±4 dB of measured E-16 mean at each of H1–H3).
**Not covered:** Damping model itself (replaced by measured); GEXT and source path unchanged from T1.
**Recorded outcome:** **not_met**, 2/3 (H1–H3 = 93.78, 80.06, 79.41 dB); η_n(200/400/600) = 0.0399, 0.0100, 0.0138; η_r′ = 0.0711, 0.0974, 0.0842; S = 5.353 m² (S_side + 2 S_e, Eq. 24 / hf_absorbing_areas); first run 2026-10-23 **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 93.75, 80.05, 79.16 dB; 2/3 unchanged. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 1/3 (98.57, 83.60, 76.20 dB). **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** 1/3 unchanged (97.79, 82.46, 77.88 dB; was 98.57, 83.60, 76.20).
**Explanation:** T1 exactly except per-band η_n from Fig. E-13 α via η_n = c₀ S α/(4 ω V) and η_r′ from e15_structural_loss_measured_all.csv (log-log in f, ends held) through η_n_band / η_r_band with η_r_band_is_prime. S = sidewall + 2 end absorbing areas (same as hf_absorbing_areas; report near Eq. 24/78).
Inputs: `e13_absorption_targets.csv`; `e15_structural_loss_measured_all.csv`; T1 geometry/trim/GEXT/R2; `t1_interior_targets.csv`.
Equations: Eq. (8); η_n from p. E-21; measured η_r′ override.
Outputs: H1–H3 [dB]; η at 200/400/600 Hz; verdict on T1 gate.

### Case: H3_ATTRIB
**Title:** H3 attribution on REPRO_18b (43c diagnostic)
**Map / block:** total / P_MEAS
**Category:** verification
**Kind:** runnable
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
**Source:** NASA TP-1964 Fig. 8 predicted (ref. 2); criterion dated 2026-10-23
**What it tests:** Same bare-cylinder NR computation vs NASA's printed predicted curve on Fig. 8 (V-CODE).
**Why it is here:** Code-on-code check of the circular NR path against NASA's Phase I prediction on the same figure.
**A pass means:** Within ±3 dB in ≥ 75 % of bands 100–5000 Hz vs NASA ref. 2.
**Not covered:** Same geometry limits as NR_TP1964; not a measurement comparison.
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
**Source:** CR-3813 Fig. E-16; F1A relative pattern as `compare_gext_vs_f1a_grid.jl`; T1 gate unchanged, dated 2026-10-23
**What it tests:** T1 with ℓ = 1 kept as ANOPP Table-8/e11 line and off-line points filled by the relative F1A pattern of the same propeller (not GEXT).
**Why it is here:** Replaces the V-ASSUMED GEXT falloff with a physics-based off-line field independent of E-16.
**A pass means:** Same T1 gate (±4 dB of measured mean, H1–H3).
**Not covered:** F1A absolute levels (only relative pattern); measured off-line free field.
**Recorded outcome:** **not_met**, 2/3 (H1–H3 = 79.61, 71.19, 71.30 dB; T1 GEXT = 84.21, 77.66, 78.06); first run 2026-10-23 **Phase 44 knock-on (2026-10-23, Eq. (83) bare f′):** 79.65, 71.17, 71.06 dB (T1 84.24, 77.63, 77.80); 2/3 unchanged. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** **met** 3/3 (82.12, 74.59, 66.95 dB), **post-hoc**: the sign was fixed after T1-family results had been seen, so this is not a pre-registered pass. **Phase 65 knock-on (2026-10-24, grid axial correction: code vs User Manual p. 9 / App. E p. E-8, z_k = z_p − x₃, z_p = 0.662 m; not a fit):** met 3/3 unchanged (81.13, 73.98, 67.32 dB; was 82.12, 74.59, 66.95); still post-hoc.
**Explanation:** `grid_fill=:f1a_relative` on the e11 path (default remains `:gext`): A(k,ℓ)=A(k,1)·A_F1A(k,ℓ)/A_F1A(k,1), φ += Δφ_F1A; F1A from `aircraft_scale_hartzell.json` / `propeller_freefield_grid`.
Inputs: e11/Table-8 line; F1A full grid; `t1_interior_targets.csv`.
Equations: Eq. (8); F1A-relative fill in `freefield_digitized.jl`.
Outputs: H1–H3 [dB] next to T1; verdict on T1 gate.

### Case: T1_F1A_MEAS_DAMP
**Title:** T1 F1A fill + measured damping (43b+43f diagnostic)
**Map / block:** total / P_MEAS
**Category:** verification
**Kind:** runnable
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
**Source:** NASA TP-2444 Fig. 17 (exterior and interior narrowband spectra of this test article, 4000 rpm), digitized 2026-10-23; criterion fixed 2026-10-23 before any run (plan Phase 47)
**What it tests:** The noise reduction of the test article under propeller excitation. Measured: exterior minus interior broadband 1/3-octave level, tones removed, B = 5 Hz assumed. Model: Eq. (18) below the card-10 changeover (1260 Hz band) and Eqs. (19)–(23) at and above it, with the CR-172428 App. B trim.
**Why it is here:** It is the first test of the cabin transmission with this article's own measured exterior and interior.
**A pass means:** Within ±5 dB in ≥ 75 % of the broadband bands 315–1250 Hz.
**Not covered:** The TP-2444 fiberglass trim has no printed properties (the App. B trim is used); the microphone positions are not stated; B is assumed.
**Recorded outcome:** **not_met**, 1/7 (2026-10-23). Measured NR is 30.0–36.0 dB in every band. The model gives 16.6, 13.5, 7.5, 5.0 and 8.7 dB at 315–800 Hz, 34.0 dB at 1000 Hz and 49.1 dB at 1260 Hz. The Phase III trim, reported with no criterion, gives 10.9–55.7 dB.
**Explanation:** Experiment comparison. `narrowband_third_octave` converts the digitized traces (pass A). `noise_reduction_band` on `r172428_inputs(4000)` gives the model.
Inputs: `data/tp2444/tp2444_fig17_*_passA.csv`; CR-172428 article and App. B trim.
Equations: Eq. (18); Eqs. (19)–(23); 1/3-octave energy sum.
Outputs: NR per band [dB].

### Case: T2_MEAS_EXT
**Title:** T2 with the measured TP-2444 exterior spectrum (47d)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** NASA TP-2444 Fig. 17 (exterior, 4000 rpm), CR-172428 Fig. 14 (slope to 2 kHz), CR-3813 Fig. E-9; criterion fixed 2026-10-23 before any run (plan Phase 47)
**What it tests:** T2's cabin path, Eqs. (19)–(23) with the T2 inputs, fed with the measured exterior band level instead of the modelled one.
**Why it is here:** T2 could not be checked end to end until a measured exterior of the article was found.
**A pass means:** The 1250 Hz interior within ±3.5 dB of Fig. E-9 (51.0 dB). 1600 and 2000 Hz use the same gate, labelled extrapolated exterior.
**Not covered:** The microphone is taken as the blocked surface pressure (position not stated); B = 5 Hz is assumed; the 1600/2000 Hz exterior is extrapolated.
**Recorded outcome:** **not_met** (2026-10-23).
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
**Source:** CR-3813 Fig. E-9; criterion fixed 2026-10-23
**What it tests:** T2 with no measured input: the BPM exterior at the Fig. 17 point through T2's Eqs. (19)–(23).
**Why it is here:** It is the end-to-end predictive form of T2.
**A pass means:** ±3.5 dB of E-9 at 1250, 1600 and 2000 Hz.
**Not covered:** As PROP_BB_FIG17.
**Recorded outcome:** **not_met**, 0/3 (2026-10-23): 18.4, 17.4 and 17.9 dB against 51.0, 46.0 and 41.5 dB. The cabin path's noise reduction is the cause. **Re-run 2026-10-28 (Phase 69, post-hoc: the earlier results were known; no criterion, tolerance or input was chosen from them):** 0/3, interior 19.5, 18.9, 19.8 dB vs 51.0, 46.0, 41.5 dB; not met. The cabin path's noise reduction is still the cause.
**Explanation:** Experiment comparison. `hf_broadband_band_p2` with the T2 pipeline inputs.
Inputs: The 48b exterior; T2 inputs.
Equations: Eqs. (19)–(23).
Outputs: interior SPL [dB].

### Case: NR_PROP_TP2444_PF
**Title:** TP-2444 NR with propeller-field coupling (Eq. 8 band average) (50b)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** TP-2444 Fig. 17 (Phase 47 digitizing), CR-172428 App. B field; criterion and decisions fixed 2026-10-23
**What it tests:** NR of the test article under propeller excitation with the coupling computed from the propeller's own blocked field (Eq. 8, as the tone path), instead of the diffuse coupling of Eq. (18).
**Why it is here:** 47c found Eq. (18) 18–26 dB low below 1 kHz under propeller excitation.
**A pass means:** Within ±5 dB in ≥ 75 % of the broadband bands 315–1250 Hz (as 47c).
**Not covered:** The broadband field shape is taken from the nearest printed harmonic (V-ASSUMED); bands above 811 Hz have no resonant structural mode in the 32-mode set.
**Recorded outcome:** **not_met**, 2/7 (2026-10-23). 315–800 Hz: 42.0, 37.7, 29.6, 36.8, 37.2 dB against 36.0, 31.8, 33.0, 30.0, 32.3 measured; 1000/1260 Hz: 63.6, 83.1 dB.
**Explanation:** Experiment comparison. `propeller_field_band_nr` with `r172428_inputs(4000)`.
Inputs: TP-2444 Fig. 17 pass A; App. B field.
Equations: Eq. (8), band average.
Outputs: NR per band [dB].

### Case: NR_PROP_TP2444_BR
**Title:** TP-2444 NR with Sharp sound bridges in Eq. (23) (59c)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** TP-2444 Fig. 17; NASA CR-172490; criterion fixed 2026-10-23
**What it tests:** 47c with the bridge option in the Eq. (23) bands.
**Why it is here:** It is the extension's test on this article.
**A pass means:** Within ±5 dB in ≥ 75 % of the bands 315–1250 Hz.
**Not covered:** Connections not documented for this article (V-ASSUMED); bridges act only at and above the changeover.
**Recorded outcome:** **not_met**, 1/7 (2026-10-23); 1260 Hz 42.8 dB against 33.9 dB measured (49.0 without bridges).
**Explanation:** Experiment comparison. `noise_reduction_band(...; bridges=true)`.
Inputs: As 47c.
Equations: Eqs. (18), (19)–(23) + τ_B.
Outputs: NR [dB].

### Case: E22_BR
**Title:** E-22 reverberant NR with Sharp sound bridges, 1250–2500 Hz (59d)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** CR-3813 Fig. E-22; NASA CR-172490; criterion fixed 2026-10-23
**What it tests:** Eqs. (19)–(23) with bridges against the measured reverberant NR of the CR-3813 article.
**Why it is here:** This is NASA's own high-frequency NR test, which PAIN as printed misses by about 30–40 dB.
**A pass means:** Inside the E-22 95 % interval in ≥ 75 % of the bands 1250–2500 Hz.
**Not covered:** End-plate transmission (CR-3813 p. E-35) is outside the sidewall model.
**Recorded outcome:** **not_met**, 0/4 (2026-10-23); about 53 dB against 19.5–32 dB (about 61 dB without bridges).
**Explanation:** Experiment comparison. `hf_pressure_ratio(...; bridges=true)`, E-21 inputs.
Inputs: E-22 data; E-21 inputs.
Equations: Eqs. (19)–(23) + τ_B.
Outputs: NR [dB].

### Case: T2_MEAS_EXT_BR
**Title:** T2 with the measured exterior and Sharp sound bridges (59e)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** CR-3813 Fig. E-9; TP-2444 Fig. 17; NASA CR-172490; criterion fixed 2026-10-23
**What it tests:** 47d with the bridge option.
**Why it is here:** It is T2 with the one documented extension that adds a path around the trim.
**A pass means:** 1250 Hz interior within ±3.5 dB of E-9 (51.0 dB).
**Not covered:** As T2_MEAS_EXT; the connections are V-ASSUMED.
**Recorded outcome:** **not_met** (2026-10-23): 28.4, 27.6 and 28.4 dB against 51.0, 46.0 and 41.5 dB (21.6 dB without bridges).
**Explanation:** Experiment comparison. `hf_broadband_band_p2(...; bridges=true)`.
Inputs: As T2_MEAS_EXT.
Equations: Eqs. (19)–(23) + τ_B.
Outputs: interior SPL [dB].

### Case: R172428_EXP
**Title:** CR-172428 reproduction vs measured space averages (44e)
**Map / block:** total / P_MEAS
**Category:** experiment
**Kind:** runnable
**Source:** NASA CR-172428 Table 5 (via Table 10); criterion dated 2026-10-23
**What it tests:** The same 9 predictions as R172428_CODE against the measured space-average levels (196 microphones).
**Why it is here:** It tests the model, not only the code, using NASA's own inputs. NASA's printed predictions themselves miss the measurement at 3000 rpm H1 (−17.7 dB) and 5000 rpm H1 (−13.8 dB).
**A pass means:** Within ±4 dB of the measured space average at each of the 9 points.
**Not covered:** Same mode truncation as R172428_CODE.
**Recorded outcome:** **not_met**, 1/9 within ±4 dB (first run 2026-10-23); NASA's own predictions meet the same gate at 5/9. **Phase 44f knock-on (2026-10-23, Eq. (52) floor-term sign of NASA's corrected program; post-hoc):** 3/9 within ±4 dB.
**Explanation:** Uses `_r172428_levels()` (shared with R172428_CODE).
Inputs: as R172428_CODE; measured Table 5 levels.
Equations: as R172428_CODE.
Outputs: 9 levels [dB] vs measured; verdict vs ±4 dB at each point.

### Case: AC_CABIN_DEMO
**Title:** Aircraft cabin example: overall dB(A) (62)
**Map / block:** total / A_CABIN
**Category:** display
**Kind:** runnable
**Source:** PAIN.jl examples/aircraft_scale_hartzell_cabin_full.json; IEC 61672 A-weighting; phase 62 criterion 2026-10-23
**What it tests:** The aircraft example's interior band spectrum, its A-weighted version and the overall dB(A) the program reports.
**Why it is here:** Gives the aircraft cabin hand-off block a case with its own figure. The number is X-EXTRAP: there is no aircraft interior measurement.
**A pass means:** Overall dB(A) equals the energy sum of the A-weighted bands within 1e-9 dB (arithmetic only).
**Not covered:** Any claim about the aircraft level (no measurement; the uncertainty band of phase 31 is not a validation).
**Recorded outcome:** **met**, 1/1 (2026-10-24; `phase62_65_map_blocks_grid.md`): 91.6 dB(A) (X-EXTRAP, not validated). The first run listed eight IEC A-weight rows as passing table rows (9/9); they carry no criterion and moved to the inputs echo on 2026-10-24 (code review). The example's grid has 80 of 160 points off its assumed 1.83 m cabin (a = 1.32 m): Q45, closed (demonstration only)
**Explanation:** Display of the aircraft result with an arithmetic check of the overall level; the A-weights are printed against the IEC table as information.
Inputs: aircraft_scale_hartzell_cabin_full.json (cabin and trim from the JSON), H = 1–3.
Equations: overall_dBA, a_weight_dB
Outputs: band SPL, A-weighted SPL, overall dB(A).

## 2.14 Closure register: every case that is not met, and why (2026-10-24)

Written after Phases 62–67. Every registered case that is **not met** is listed with the class of its cause and the
evidence. Classes: **M** limitation of PAIN's method as printed (CR-3813 / User Manual); **A** limitation of a
low-fidelity approximation this recreation uses; **I** input or data limitation (digitization, truncated printed tables,
assumed geometry, no measurement); **N** NASA's printed output differs in a way the documents do not explain; **D** the
pre-registered test design. **Superseded 2026-10-28:** code defects were found in the BEMT polar path (plan Phase 69), so the cases marked "Reopened" below were open as code defects until rerun. **Rerun 2026-10-28 (post-hoc):** the defects are fixed (69a, 70 F4) and every reopened case was rerun. None is met yet, and each is re-classed in its row below; again no case is open as a code defect. **Amended 2026-10-28 (Phase 78):** MRP_APPD is open as a code defect (stiffener inertias, floor orthotropy) until 78d. The text that follows is the 2026-10-24 statement: **No case is open as a code defect**: every block passes its isolated code checks (Phases 40,
41, 46, 62, 64, 66) and every code defect found was fixed. "Probable" marks a cause that the documents do not allow testing.

| Case | Class | Cause and evidence |
|------|-------|--------------------|
| MRP_APPD (2/32, identity-matched) | **open code defect** | the App. D solver is 20–70 % low; its operators are exact against closed forms, but the stiffener inertias drop the channel flanges and the floor stiffness is isotropic (Phase 78b); the 2026-10-22 pass came from frequency-only matching. Fix plan 78c |
| E12_BLOCK (29/31) | I, N | the two H3 aft points fail inside the E-12 digitization spread (δ_dig = 2.91 dB). **Re-classed 2026-10-28 (A3b):** read from pixels, NASA's own E-12 − E-11 step matches Eq. (43) within ±1.5 dB at H1/H2 with no fore/aft trend, so no Eq. (43) term is missing. The fore/aft pattern was the by-eye digitization of steep slopes (I, as classed). H3 k10, where NASA's drawn line implies a 2.3 dB step, is not explained by the documents (N) |
| E14_LOSS (7/18) | I (probable) | TRIM_CLOSED and TRIM_PASSIVITY pass; Fig. A-2 is digitized at six frequencies only |
| LOUDEST_PT (a) | D | the pre-registered interior point set omits the wall nodes; with all nodes the ratio is 0.99–1.01 (post-hoc) |
| REPRO_18b, E18_TONES, E21_E22_NR, REPRO_18b_PRE, E21_PRE, E22_HF_CODE | N | CR-3813's printed runs predate NASA's corrections; neither sign of the floor term reproduces them (Phase 61); the corrected program (CR-172428) is reproduced within 0.4 dB at H3 |
| R172428_CODE, R172428_EXP | N | largest contributor (0,1) × mode 8 at H1; q = 0 modes absent from NASA's printed pairs, not explained by the documents (Q22, Phase 54) |
| R172428_ETA (17/32) | I (probable) | modes 1–12 within 13 %; modes 13–32 use Table D-1 shapes truncated to five shell terms (see MRP_SHAPE_NORM) |
| T1, T1_FROM_E12, T1_MEAS_DAMPING, UNC_COVER | I | the H3 excess is the e11 off-line (GEXT) field, an assumed extension (Phase 52, GEXT_BOUND); the cabin matches NASA at H3 |
| T2 | A | the default broadband path is a calibrated surrogate (`bb_j2_scale`), labelled as such (Phase 55) |
| T2_EQ19, T2_MEAS_EXT, T2_PRED_BB, NR_PROP_TP2444, NR_PROP_TP2444_BR, E22_BR, T2_MEAS_EXT_BR | M | PAIN's high-frequency trim noise reduction exceeds the measurement; NASA's own E-22 prediction is 32–44 dB above measured and the code is within 2–8 dB of NASA (Phases 47, 49, 59, 61); NASA states the trim model holds to about 1 kHz |
| NR_PROP_TP2444_PF | A | the separable form of Eq. (66) used for the propeller field (Phase 50a, 0.4–2 dB) |
| NR_TP1964, NR_TP1964_REF2, NR_TP1964_XOVER, NR_TP1964_XOVER_REF2 | M | the misses are Eq. (18) bands, where negative NR is a property of the equation (CR-159363 p. 138, Phase 53); the Eq. (19) bands agree within ±2.5 dB |
| PROP_BB_FIG14, PROP_BB_FIG17 | A, I | BPM self-noise only (no inflow turbulence), assumed blade geometry; the BPM port itself reproduces NASA's printed output 270/270 (Phase 48). **Reopened 2026-10-28:** the BEMT behind them used the Report 996 polar file with one section and μ = 1 (plan Phases 69, 70 F4). **Closed 2026-10-28:** rerun with the fixed loader: 3/9 and 2/7, unchanged counts (FIG14 median 7.5 dB, was 9.2), so the miss is the BPM-only source model, as first classed |
| SHARP_PANEL_D | I | the source's ΔTL_M is ambiguous (Phase 59) |
| BLK_GAIN_MAP | M | R1 is CR-172428 Eq. (43) as printed, negative behind the cylinder; the default R2 stays within 0–6.02 dB |
| MRP_SHAPE_NORM | I | Table D-1 prints only the largest Fourier coefficients of each mode |
| CYL2D_WEYL | D, M | **Amended 2026-10-28 (Phase 71 A4):** the criterion compares with the Weyl leading term only, but a rigid-walled cavity's surface term is positive and large at low kh. With it (post-hoc) the ratio is 0.99, 1.07, 1.10, 1.21, so the first four frequencies are a test-design miss (D). The fifth (1.51) remains: the App. C 5-point grid at NY = 10 (as printed) computes high modes too low (near-circle check, post-hoc diagnosis) (M) |
| F1A_GUTIN_ANGLES (4/5) | A | far-field Gutin reference at a near-null (θ = 60°: terms cancel to 5.7 %); at 400 R_tip the phase is within 3.7° (post-hoc) |
| POLAR_FIDELITY, R996_LOADS, R996_PHASE (R996_FIG13A met since Phase 72; R996_FIG12 and R996_FIG14 met since Phase 76, thickness noise on) | A | XFOIL (forced transition) c_l 0.15–0.35 below NACA TN 1546 measured; BEMT thrust 25–32 % below Report 996 measured; the compact-chord F1A is not the cause (≤ 0.27 dB) (Phase 67). **Reopened 2026-10-28:** code defects in the polar path (one section at every station, μ = 1 in CCBlade, no Re/M interpolation, no stall), plan Phase 69. **Closed 2026-10-28:** rerun on the free-transition N_crit 8 set with the fixed loader (post-hoc): R996_LOADS 24/32 (was 6/32), FIG12 28/40 (was 21/40), FIG13A 8/14, PHASE 113.6° vs 155°. POLAR_FIDELITY held-out 16-312 13/26. **Phase 72 (2026-10-28, post-hoc):** with the observers on the documented side of the plane, FIG13A is met (14/14), FIG12 13/40 and FIG14 14/24 (was met). All the rest still not met: XFOIL section fidelity on the thicker sections (the held-out miss) and the loads that follow from it, class A. **Phase 73 (2026-10-28, bound, no verdict):** a c_l shift at the measured XFOIL − TN 1546 level moves thrust ≤ 7.9 % and the scaled-load levels ≤ 0.19 dB, so the section c_l is not the cause; XFOIL's c_d is about 25 % below TN 1546's and accounts for about half the torque gap. Still class A |
| BBN_CIRC | I | assumed blade geometry for the Aero Commander (X-EXTRAP); low coherence pairs |
| PER_FIG8, PER_FIG9 (PER_FIG7 met since Phase 76) | N (since Phase 74; was I, probable) | XFOIL NACA 4412 polars at Pereira's Reynolds number, where no measured section data exist in the documents (TR 824 is 3–9·10⁶); motor noise above H2. **Reopened 2026-10-28:** the BEMT read the lowest-Re polar table (2·10⁴) because CCBlade got μ = 1 (plan Phase 69). **Closed 2026-10-28:** with μ fixed, thrust is 14.65 N vs 14.55 N measured (+0.7 %) and torque +3.5 %, yet FIG7 2/3, FIG8 H1/H2 3/7 each, and FIG9 3/9 and 6/9 stay as before. So the miss is not the loads: the acoustic model (I, as first classed). **Phase 72 (2026-10-28):** with φ positive downstream as in Pereira Fig. 2b, our H1 directivity matches Pereira's own BEMT within 0.8 dB; FIG8 H1 5/7, FIG9 H1 0/9 (Fig. 9's measured H1 is about 4 dB below Fig. 8's at the same angles), FIG7 1/3. **Phase 76 (2026-10-28):** with the thickness term on (Pereira's own method includes it), FIG7 is met (3/3), FIG8 H1 6/7 and H2 4/7; FIG9 unchanged, its H1 miss is the Fig. 8/Fig. 9 inconsistency (I-04, Phase 74). **Phase 74 (2026-10-28):** the inconsistency was a misreading of Fig. 9 (H1 read as 80 dB); re-read from the PDF vectors, Fig. 9 equals Fig. 8 within 0.1 dB and FIG9 H1 is 9/9. What remains is H2 at φ = 20° (+3.7 dB in both cases), at −20° and +30° (FIG8 −3.2 and +3.0) and H1 at −20° (−2.0): the size of Pereira's CFD misses at the same angles (H2: 3.9, 3.1, 1.2, 0.2, 2.6, 1.9, 2.4 dB), and the measured H2 is not monotonic in φ. Class N (installation or measurement: open-jet nozzle 0.04 m behind the −20° microphone; the documents do not allow a test) |

**Statement.** As code, the recreation implements CR-3813 / the User Manual and drives CCBlade.jl and AcousticAnalogies.jl
correctly in every block (isolated checks met; open code defects: none). Every remaining experimental or code-on-NASA miss is
classed above as a limitation of the method as printed, of a low-fidelity approximation, of the inputs, or of NASA's printed
output; none is claimed as a pass.

## 3. What “valid recreation” means for this project

A recreation is **pipeline-valid** only if:

1. **Blocking** matches Eq. (43) within **0.06 dB** (R1) and R2 scaling is explicit.  
2. **CYL2D / MRP** match Table C-1 / D-1 within flowchart tolerances (**V-CODE**).  
3. **PAIN core** with **measured / digitized free-field** (Fig. E-11 path) reproduces App. E tonal tests within the published scatter (**V-EXP**).  
4. **CCBlade + AcousticAnalogies** is treated as an **alternate free-field generator**; its outputs are **X-EXTRAP** for the aircraft application (phase 33 close-out 2026-10-21: BBN 24c, Report 996 23c and Pereira 23d did not meet frozen tolerances; Gutin/Hanson optional cross-check not run). See §2.3.3.

Do **not** claim that replacing ANOPP with CCBlade/F1A inherits NASA’s exterior-noise validation. Claim inheritance only for the **transmission / cabin** model after the free-field grid interface.

---

## 3.1 Test runner notes (P1, 2026-10-22)

`Pkg.test("PAIN"; test_args=[…])` selects top-level testsets by case-insensitive title substring. Empty args run the full suite. This is a developer convenience only: **no assertion, tolerance, reference file or recorded result changes.** Titles and measured times: `PAIN.jl/test/README.md`. Optional DaemonMode under `PAIN.jl/scripts/devtools/` (separate Project.toml; Revise loaded in the daemon). The suite writes validation reports and case figures only to a temp dir (`TEST_OUT` in `test/runtests.jl`), not under `docs/validation_reports/`; a final “Suite leaves tree clean” check asserts no tracked `docs/` or `data/` file is modified.

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
