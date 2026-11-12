# PAIN recreation — validation notes of Phases 62–134

Moved word for word from `VALIDATION_GUIDELINE.md` §2.14–§2.56 on 2026-11-11 (Phase 148e), under their old numbers, so a reference to "§2.14" or "§2.40" finds its text here. They are the validation side of the phases in `COMPLETED_PHASES.md`; where the two differ, the phase section there is the record. Append-only: nothing new is written here.

## 2.14 Closure register: every case that is not met, and why (2026-10-24)

*Phase 118a (2026-11-02): T1, T1_FROM_E12, T1_MEAS_DAMPING, T1_F1A_FILL, UNC_COVER, REPRO_18b, E18_TONES, T2_EQ19,
T2_MEAS_EXT, T2_MEAS_EXT_BR, T2_PRED_BB, PROP_BB_FIG14, PROP_BB_FIG17 and BBN_CIRC carry no verdict since then (an input
is not printed or measured, §2.40); their rows below are kept as the record of why they missed. The full-input cases
still not met are re-listed with their tested causes in `validation_reports/phase118_full_input_misses.md`.*

Written after Phases 62–67. Every registered case that is **not met** is listed with the class of its cause and the
evidence. Classes: **M** limitation of PAIN's method as printed (CR-3813 / User Manual); **A** limitation of a
low-fidelity approximation this recreation uses; **I** input or data limitation (digitization, truncated printed tables,
assumed geometry, no measurement); **N** NASA's printed output differs in a way the documents do not explain; **D** the
pre-registered test design. **Superseded 2026-10-28:** code defects were found in the BEMT polar path (plan Phase 69), so the cases marked "Reopened" below were open as code defects until rerun. **Rerun 2026-10-28 (post-hoc):** the defects are fixed (69a, 70 F4) and every reopened case was rerun. None is met yet, and each is re-classed in its row below; again no case is open as a code defect. **Amended 2026-10-28 (Phase 78):** MRP_APPD is open as a code defect (stiffener inertias, floor orthotropy) until 78d. The text that follows is the 2026-10-24 statement: **No case is open as a code defect**: every block passes its isolated code checks (Phases 40,
41, 46, 62, 64, 66) and every code defect found was fixed. "Probable" marks a cause that the documents do not allow testing.

| Case | Class | Cause and evidence |
|------|-------|--------------------|
| MRP_APPD (2/32, shape-paired) | **Closed 2026-10-29 (Phase 80): met, 32/32 on NASA's deck** (was I, input: floor stiffener model; the deck in the User Manual documents it) | code defects fixed in Phases 78d (stiffener inertias, orthotropic floor) and 78d-4 (shape convention, full-circumference shell, null functions, dedup, floor sway and membrane coupling); operators exact against closed forms; the symmetric floor modes match in shape but not frequency and most antisymmetric modes have no partner. App. D does not say how the floor beams and supports act ("classical plate theory"), so no reading is fixed by the documents |
| E12_BLOCK (29/31) | I, N | the two H3 aft points fail inside the E-12 digitization spread (δ_dig = 2.91 dB). **Re-classed 2026-10-28 (A3b):** read from pixels, NASA's own E-12 − E-11 step matches Eq. (43) within ±1.5 dB at H1/H2 with no fore/aft trend, so no Eq. (43) term is missing. The fore/aft pattern was the by-eye digitization of steep slopes (I, as classed). H3 k10, where NASA's drawn line implies a 2.3 dB step, is not explained by the documents (N) |
| E14_LOSS (7/18) | **unexplained** (was I, probable; re-classed 2026-11-10, Phases 118 and 139) | TRIM_CLOSED and TRIM_PASSIVITY pass. The six-frequency reading of Fig. A-2 is not the cause: with NASA's per-band PF-105 table the count is 6/18 (Phase 118). Evaluating the loss at the band centre is not the cause either (Phase 139, `phase139b_band_centre.md`). Open: ISSUE-032 |
| LOUDEST_PT (a) | D; **information since Phase 82** (§2.15) | the pre-registered interior point set omits the wall nodes; with all nodes the ratio is 0.99–1.01 (post-hoc); on the converged grid NY = 40 the all-node average equals Eq. (8) within 0.07 % (LOUDEST_PT_GRID, met, 2026-10-29) |
| REPRO_18b, E18_TONES, E21_E22_NR, REPRO_18b_PRE, E21_PRE, E22_HF_CODE | N; **REPRO_18b_PRE and E21_PRE diagnostics since Phase 86** (§2.19) | CR-3813's printed runs predate NASA's corrections; neither sign of the floor term reproduces them (Phase 61); the corrected program (CR-172428) is reproduced within 0.4 dB at H3. REPRO_18b_PRE reverts all three CR-172428 App. A changes, and NASA's 300-mode set moves the tones < 0.2 dB (REPRO_18b_DECK, Phase 83, 2026-10-29) |
| R172428_CODE, R172428_EXP | N | **Phase 88 (2026-10-29): the q = 0 hypothesis refuted on CR-3813's runs (§2.21).** largest contributor (0,1) × mode 8 at H1; q = 0 modes absent from NASA's printed pairs, not explained by the documents (Q22, Phase 54). **Phase 84b (2026-10-29):** not the mode counts: our acoustic list equals NASA's printed App. B list, and NASA's 300 structural modes give the same 4/9 and 3/9 (levels move ≤ 2.2 dB) |
| R172428_ETA (17/32) | **N** (was I, probable; re-classed 2026-10-29, Phase 82c) | modes 1–12 within 13 %. Not the truncated shapes: with NASA's full MRP-deck modes (82c, pre-registered) the count is the same 17/32 and the levels of R172428_CODE/EXP move < 1 dB. Not the inputs of Eq. (82): the generalized masses (total and shell) match App. B within 1 %, the trim admittance App. B p. 197 within 2 % to 1 kHz, and the ETASTR changes (App. A p. 178) are what the code does. Not η_r″: adding Σ η_r″ (Eq. 83) overshoots modes 1–12 by up to 100×. NASA's printed loss factor of the trim-damped modes above 500 Hz is 1.3–2× this code's, mode by mode, which the documents do not explain |
| T1, T1_FROM_E12, T1_MEAS_DAMPING, UNC_COVER | I; **H3 part re-stated M (Phase 83a, 2026-10-29)** | the H3 excess is the e11 off-line (GEXT) field, an assumed extension (Phase 52, GEXT_BOUND); the cabin matches NASA at H3. **Re-stated 2026-10-29 (Phase 83a):** with NASA's printed App. B field and no extension, R172428_EXP at 4000 rpm gives H3 71.7 dB, NASA's own prediction is 71.3 dB (CR-172428 Table 10) and the measurement 65.2 dB: the code reproduces NASA at H3 within 0.4 dB, and the excess over the measurement that remains without GEXT is PAIN's (M); GEXT accounts for the rest of T1's H3 excess |
| T2 | A; **information since Phase 83d** (§2.16) | the default broadband path is a calibrated surrogate (`bb_j2_scale`, fitted to Fig. E-9), labelled as such (Phase 55); it is compared with the data it was fitted to, so it carries no verdict (2026-10-29) |
| T2_EQ19, T2_MEAS_EXT, T2_PRED_BB, NR_PROP_TP2444, NR_PROP_TP2444_BR, E22_BR, T2_MEAS_EXT_BR | M | PAIN's high-frequency trim noise reduction exceeds the measurement; NASA's own E-22 prediction is 32–44 dB above measured and the code is within 2–8 dB of NASA (Phases 47, 49, 59, 61); NASA states the trim model holds to about 1 kHz. **Phase 83 (2026-10-29):** the one untested cause, Table D-1's 32 modes (no resonant mode above 811 Hz), is refuted: with NASA's 300 MRP-deck modes the code is 6–19 dB below NASA's E-22 prediction (E22_HF_DECK 0/4; it was within 2–8 dB) and T2_EQ19 moves 4–8 dB over E-9 (T2_EQ19_DECK 0/3); the class stays M |
| NR_PROP_TP2444_PF | A | the separable form of Eq. (66) used for the propeller field (Phase 50a, 0.4–2 dB) |
| NR_TP1964, NR_TP1964_REF2, NR_TP1964_XOVER, NR_TP1964_XOVER_REF2 | M | the misses are Eq. (18) bands, where negative NR is a property of the equation (CR-159363 p. 138, Phase 53); the Eq. (19) bands agree within ±2.5 dB |
| PROP_BB_FIG14, PROP_BB_FIG17 | A, I | BPM self-noise only (no inflow turbulence), assumed blade geometry; the BPM port itself reproduces NASA's printed output 270/270 (Phase 48). **Reopened 2026-10-28:** the BEMT behind them used the Report 996 polar file with one section and μ = 1 (plan Phases 69, 70 F4). **Closed 2026-10-28:** rerun with the fixed loader: 3/9 and 2/7, unchanged counts (FIG14 median 7.5 dB, was 9.2), so the miss is the BPM-only source model, as first classed |
| SHARP_PANEL_D | **N** (was I); **information since Phase 82** (§2.15) | the source's figure lies 10.2 dB over its mass line while its text and Eq. (25) with the Fig. A-7 lattice give about 12 dB (Phase 81c); the construction's slopes match the figure (SHARP_PANEL_D_SHAPE, met) |
| BLK_GAIN_MAP | M; **information since Phase 82** (§2.15) | R1 is CR-172428 Eq. (43) as printed, negative behind the cylinder; the default R2 stays within 0–6.02 dB |
| MRP_SHAPE_NORM | I; **information since Phase 82** (§2.15) | Table D-1 prints only the largest Fourier coefficients of each mode; quantified 2026-10-29 (MRP_TRUNC): the solver's shapes cut to the printed 5 + 3 terms reproduce the printed peaks |
| MRP_COUPLED_LIMITS (66/78) | **M**; **information since Phase 82** (§2.15) | NASA's floor form omits the cross terms between floor terms of different parity; it is how Table D-1 was computed, so production keeps it (author 2026-10-29: the same function as PAIN); `floor_cross_terms=true` gives the exact Ritz energy |
| CYL2D_WEYL | D, M; **information since Phase 82** (§2.15) | **Amended 2026-10-28 (Phase 71 A4):** the criterion compares with the Weyl leading term only, but a rigid-walled cavity's surface term is positive and large at low kh. With it (post-hoc) the ratio is 0.99, 1.07, 1.10, 1.21, so the first four frequencies are a test-design miss (D). The fifth (1.51) remains: the App. C 5-point grid at NY = 10 (as printed) computes high modes too low (near-circle check, post-hoc diagnosis) (M) |
| F1A_GUTIN_ANGLES (4/5) | A; **information since Phase 82** (§2.15) | far-field Gutin reference at a near-null (θ = 60°: terms cancel to 5.7 %); at 400 R_tip the phase is within 3.7° (post-hoc) |
| POLAR_FIDELITY, R996_LOADS, R996_PHASE (R996_FIG13A met since Phase 72; R996_FIG12 and R996_FIG14 met since Phase 76, thickness noise on) | A | XFOIL (forced transition) c_l 0.15–0.35 below NACA TN 1546 measured; BEMT thrust 25–32 % below Report 996 measured; the compact-chord F1A is not the cause (≤ 0.27 dB) (Phase 67). **Reopened 2026-10-28:** code defects in the polar path (one section at every station, μ = 1 in CCBlade, no Re/M interpolation, no stall), plan Phase 69. **Closed 2026-10-28:** rerun on the free-transition N_crit 8 set with the fixed loader (post-hoc): R996_LOADS 24/32 (was 6/32), FIG12 28/40 (was 21/40), FIG13A 8/14, PHASE 113.6° vs 155°. POLAR_FIDELITY held-out 16-312 13/26. **Phase 72 (2026-10-28, post-hoc):** with the observers on the documented side of the plane, FIG13A is met (14/14), FIG12 13/40 and FIG14 14/24 (was met). All the rest still not met: XFOIL section fidelity on the thicker sections (the held-out miss) and the loads that follow from it, class A. **Phase 73 (2026-10-28, bound, no verdict):** a c_l shift at the measured XFOIL − TN 1546 level moves thrust ≤ 7.9 % and the scaled-load levels ≤ 0.19 dB, so the section c_l is not the cause; XFOIL's c_d is about 25 % below TN 1546's and accounts for about half the torque gap. Still class A |
| BBN_CIRC | I | assumed blade geometry for the Aero Commander (X-EXTRAP); low coherence pairs |
| PER_FIG8, PER_FIG9 (PER_FIG7 met since Phase 76) | N (since Phase 74; was I, probable) | XFOIL NACA 4412 polars at Pereira's Reynolds number, where no measured section data exist in the documents (TR 824 is 3–9·10⁶); motor noise above H2. **Reopened 2026-10-28:** the BEMT read the lowest-Re polar table (2·10⁴) because CCBlade got μ = 1 (plan Phase 69). **Closed 2026-10-28:** with μ fixed, thrust is 14.65 N vs 14.55 N measured (+0.7 %) and torque +3.5 %, yet FIG7 2/3, FIG8 H1/H2 3/7 each, and FIG9 3/9 and 6/9 stay as before. So the miss is not the loads: the acoustic model (I, as first classed). **Phase 72 (2026-10-28):** with φ positive downstream as in Pereira Fig. 2b, our H1 directivity matches Pereira's own BEMT within 0.8 dB; FIG8 H1 5/7, FIG9 H1 0/9 (Fig. 9's measured H1 is about 4 dB below Fig. 8's at the same angles), FIG7 1/3. **Phase 76 (2026-10-28):** with the thickness term on (Pereira's own method includes it), FIG7 is met (3/3), FIG8 H1 6/7 and H2 4/7; FIG9 unchanged, its H1 miss is the Fig. 8/Fig. 9 inconsistency (I-04, Phase 74). **Phase 74 (2026-10-28):** the inconsistency was a misreading of Fig. 9 (H1 read as 80 dB); re-read from the PDF vectors, Fig. 9 equals Fig. 8 within 0.1 dB and FIG9 H1 is 9/9. What remains is H2 at φ = 20° (+3.7 dB in both cases), at −20° and +30° (FIG8 −3.2 and +3.0) and H1 at −20° (−2.0): the size of Pereira's CFD misses at the same angles (H2: 3.9, 3.1, 1.2, 0.2, 2.6, 1.9, 2.4 dB), and the measured H2 is not monotonic in φ. Class N (installation or measurement: open-jet nozzle 0.04 m behind the −20° microphone; the documents do not allow a test) |

**Statement.** As code, the recreation implements CR-3813 / the User Manual and drives CCBlade.jl and AcousticAnalogies.jl
correctly in every block (isolated checks met; open code defects: none). Every remaining experimental or code-on-NASA miss is
classed above as a limitation of the method as printed, of a low-fidelity approximation, of the inputs, or of NASA's printed
output; none is claimed as a pass.

## 2.15 Meaningfulness audit of the not-met cases (Phase 82, 2026-10-29)

**Rule (author 2026-10-29; `CLAUDE.md`).** A validation case is meaningful, and may carry a verdict, only if it **(E)** compares
with experimental data, or **(P)** checks that the code works exactly like PAIN: given PAIN's own inputs (from PAIN's sources or
experiment) it reproduces what PAIN printed. A check against anything else is verification: an information case (no verdict) or
a unit test. The 43 not-met cases of the 2026-10-29 snapshot:

| Class | Cases | Outcome |
|---|---|---|
| E (26) | E22_BR, R996_PHASE, T2, T2_EQ19, T2_MEAS_EXT, T2_MEAS_EXT_BR, T2_PRED_BB, UNC_COVER, E21_E22_NR, NR_PROP_TP2444, NR_PROP_TP2444_BR, NR_PROP_TP2444_PF, T1_MEAS_DAMPING, PROP_BB_FIG17, PROP_BB_FIG14, NR_TP1964, R172428_EXP, T1, T1_FROM_E12, NR_TP1964_XOVER, POLAR_FIDELITY, PER_FIG8, PER_FIG9, R996_LOADS, BBN_CIRC, E12_BLOCK | meaningful; verdict and §2.14 class kept |
| P (10) | REPRO_18b, E21_PRE, E22_HF_CODE, E18_TONES, REPRO_18b_PRE, R172428_CODE, R172428_ETA, E14_LOSS (NASA's calculated Eq. (78) curve), NR_TP1964_REF2, NR_TP1964_XOVER_REF2 (NASA's prediction with the CR-159363 equations PAIN adopts) | meaningful; verdict kept. The one cause still untested, R172428_ETA's truncated shapes, was tested in 82c: refuted, re-classed N (§2.14) |
| X (7) | LOUDEST_PT, BLK_GAIN_MAP, MRP_SHAPE_NORM, CYL2D_WEYL, MRP_COUPLED_LIMITS, F1A_GUTIN_ANGLES, SHARP_PANEL_D | not validation cases: information since Phase 82 (`INFORMATION_ONLY_CASES`): no verdict, run and table unchanged, the earlier outcome kept in the record and in `original_verdict`; never a pass |

Met cases were not audited here (Phase 82 covers the not-met list the author asked for); a met case that fails the rule is
not a validation pass either, and is listed for audit in the plan (Q63). **Done 2026-10-29 (Phase 85, §2.18).**

## 2.16 The not-met cases with the fewest points: audit and solutions (Phase 83, 2026-10-29)

The nine cases at 0 points in §0, audited for a cause the documents still allow testing (plan §8aa, criteria dated before the
runs). Each untested cause was run once against the original case's criterion.

| Case | Class | Cause tested in Phase 83 | Result |
|---|---|---|---|
| T2_EQ19, T2_MEAS_EXT, T2_MEAS_EXT_BR, T2_PRED_BB, E22_BR | E (M) | Eqs. (19)–(23) ran on Table D-1's 32 modes (to 811 Hz): no resonant mode in any band 1250–2500 Hz, an asymptotic density instead. NASA ran PAIN with 300 MRP modes (CR-172428 Table 6); the App. D solver on NASA's deck gives them (39–68 resonant per band) | **Refuted.** E22_HF_DECK 0/4: the code goes from within 2–8 dB of NASA's E-22 prediction to 6–19 dB below it. T2_EQ19_DECK 0/3: 4–8 dB over E-9 (it was 6–12 dB under). Table D-1 kept; class M stays |
| T2 | not meaningful | `bb_j2_scale` was fitted to Fig. E-9 and T2 is compared with Fig. E-9 | **Information** (83d); T2_EQ19 is the printed-method T2 |
| REPRO_18b | P (N) | the mode set, the one input left after REPRO_18b_PRE reverted all three App. A program changes | **Refuted.** REPRO_18b_DECK 0/3; the tones move < 0.2 dB |
| UNC_COVER | E | none: the GEXT attribution was checked against NASA's own field | **Re-stated** (§2.14): without GEXT the code reproduces NASA's H3 within 0.4 dB at 4000 rpm (71.7 vs 71.3 dB), 6.5 dB over the measurement: PAIN's (M) |
| R996_PHASE | E (A) | none left: F1A_INDEP rules out the wiring (0.02°) and Phase 73 the polars; Report 996's own Eq. (2) gives 165° against the measured 155° | unchanged |

**What this leaves.** For the 0-point cases no documented input or program form is left untested. The code reproduces NASA's
corrected program where NASA printed it (CR-172428 at H3 within 0.4 dB). The remaining misses against measurement sit in
PAIN's method (M) or in NASA's printed CR-3813 runs (N).

## 2.17 The next tier of not-met cases (Phase 84, 2026-10-29)

The not-met cases with at most a third of their points, after the 0-point cases of §2.16 (plan §8ab, criteria dated before the
runs).

| Case | Class | Cause tested in Phase 84 | Result |
|---|---|---|---|
| R172428_CODE (4/9), R172428_EXP (3/9) | N | NASA's mode counts (CR-172428 Table 6: 300 structural, 400 acoustic). The acoustic list already equals NASA's printed one (48 modes to 597 Hz, in order, within 0.5 %); the structural count was run with the 300 deck modes | **Refuted.** R172428_CODE_DECK 4/9, R172428_EXP_DECK 3/9, levels within 2.2 dB of the 32-mode runs |
| E21_PRE (1/4 counted), E21_E22_NR | N, M | NASA's 300 structural modes in the Eq. (18) path | **Refuted.** E21_PRE_DECK 1/4; the counted bands lie below the 400 Hz crossover, where Table D-1 has every mode |
| E22_HF_CODE, NR_PROP_TP2444, NR_PROP_TP2444_BR | M | none left (Phase 83) | unchanged |
| T1, T1_FROM_E12, T1_MEAS_DAMPING | M (H3) | none left (Phase 83 re-statement) | unchanged |
| NR_PROP_TP2444_PF, PROP_BB_FIG17, PROP_BB_FIG14 | A, I | none: stated approximations (Eq. (66) separable form; BPM self-noise only) | unchanged |
| E18_TONES, REPRO_18b_PRE | N | none left (Phases 61, 83) | unchanged |
| NR_TP1964, NR_TP1964_REF2 | M | none: negative NR is a property of Eq. (18) (Phase 53) | unchanged |

**What this leaves.** In this tier, too, no documented input or program form is left untested; the misses are classed M, A, I or N
as in §2.14.

## 2.18 Meaningfulness audit of the met cases (Phase 85, 2026-10-29)

The 47 met cases of the 2026-10-29 snapshot, audited with the rule of §2.15 (`CLAUDE.md`). A P case must reproduce something PAIN
printed from PAIN's inputs; a check of the inputs themselves against PAIN's sources (App. E values, the User Manual's grid and
card formulas) supports the P cases but reproduces no output, so it is verification.

| Class | Cases | Outcome |
|---|---|---|
| E (5) | T1_F1A_FILL (Fig. E-16), R996_FIG14, R996_FIG12, R996_FIG13A (Report 996 measured), PER_FIG7 (Pereira measured) | meaningful; met kept. The Report 996 cases scale the loads to the measured T and Q (a calibrated input, labelled since 23c) and compare with the measured noise, not with T and Q |
| P (3) | BLK_P68 (CR-172428 p. 68 printed blocking values), MRP_APPD (Table D-1, MRP's printed output from NASA's deck), CYL2D_C1 (Table C-1, CYL2D's printed output) | meaningful; met kept |
| X (39) | AC_CABIN_DEMO, BBN_KIN, BEMT_HAND, BEMT_HAND_TIP, BEMT_INTEGRALS, BEMT_MOMENTUM, BEMT_SIMILARITY, BPM_RP1218, CABIN_GEOM_HAND, E11_FREEFIELD, F1A_GUTIN, F1A_GW_FLIGHT, F1A_INDEP, F1A_PLANE_PEAK, F1A_PROPERTIES, F1A_THICKNESS, FF_E11_MAP, HF_MASSLAW, ISO_BB_BAND, ISO_BLOCKING, ISO_CYL2D_BOUNDARY, ISO_CYL2D_EXACT, ISO_FF_CONV, ISO_GEXT_LINE, ISO_JOINT_ACC, ISO_MODAL_DENSITY, ISO_SIL, ISO_TABLE8, LOUDEST_PT_GRID, MRP_INPUT_QA, MRP_TRUNC, NR_BAND_HAND, PAIN_INPUT_ECHO, SHARP_PANEL_D_SHAPE, SRC_PASSTHROUGH, TRIM_CLOSED, TRIM_INPUT_QA, TRIM_PASSIVITY, UT_GRID | information since Phase 85 (`INFORMATION_ONLY_CASES`): no verdict, run and table unchanged, the earlier outcome kept in the record and in `original_verdict`; never a pass. Each reason is in the case record |

**Figures (2026-10-29).** The error panels of BEMT_MOMENTUM, BEMT_HAND_TIP, BEMT_INTEGRALS, F1A_GW_FLIGHT and F1A_THICKNESS now label their x with what the table x encodes (operating point, θ + 1000 M_x, θ + 1000 × harmonic), not the main panel's axis.

**Consequence.** After Phases 82 and 85, 8 cases carry a met verdict on the map; the verification checks still run (and their
tests still assert that each check holds, through `underlying_verdict`), but no block is shown as validated by them.

## 2.19 Map holds only cases with a verdict; diagnostics (Phase 86, 2026-10-29)

Author 2026-10-29: "these diognostics shouldnt be included in a validation map and all no verdicts should be placed
elsewhere". Two changes, both by kind and applied whatever the outcome:

| Change | Cases | Effect |
|---|---|---|
| Diagnostic re-runs (`DIAGNOSTIC_CASES`): a re-run of another case with one program form or input set changed to test a documented cause of its miss | REPRO_18b_PRE, E21_PRE (Phase 61: the pre-correction floor sign), REPRO_18b_DECK, E21_PRE_DECK, E22_HF_DECK, T2_EQ19_DECK, R172428_CODE_DECK, R172428_EXP_DECK (Phases 83–84: NASA's 300 MRP-deck modes) | no verdict; the case each re-runs keeps its verdict (REPRO_18b, E21_E22_NR, E22_HF_CODE, T2_EQ19, R172428_CODE, R172428_EXP); every cause tested was refuted, as recorded |
| Map membership (`on_validation_map`) | every case whose recorded verdict is not met or met | the map (§0 and the GUI's Validation map tab, both retired in Phase 147 for the coverage chart, which applies the same rule) showed only these; the others are listed by kind in `NO_VERDICT_CASES.md` (generated with §0) and still run in the Validation tab and the tests |

No criterion, tolerance, reference file or recorded number changed; the diagnostics' tests assert their recorded outcomes
through `underlying_verdict`. After the change the map holds 41 cases: 8 met, 33 not met. Not changed: re-runs with
measured inputs that isolate a block (T1_FROM_E12, T1_MEAS_DAMPING, T2_MEAS_EXT) compare with measurement and keep their
verdicts, and so do the cases that add a model beyond PAIN (the `_BR` sound-bridge cases, NR_PROP_TP2444_PF); both are
listed in §2.14.

## 2.20 Planned: the open differences from NASA's corrected program (Phases 87–88, criteria fixed 2026-10-29)

Before any run: Phase 87 compares NASA's printed per-mode values (App. B: ε_n, η_n, η_r″) with this code's (P cases with a
verdict); a systematic miss is a documented cause and is fixed. Phase 88, only if 87 finds none, tests the q = 0 hypothesis
(NASA's program left the q = 0 cabin modes uncoupled) on CR-3813's printed runs, which played no part in forming it
(diagnostics, off the map). Criteria and decision rules: `IMPLEMENTATION_PLAN.md` §8ae.

## 2.21 Results of Phases 87–88 (2026-10-29)

| Case | Class | Result |
|---|---|---|
| APPB_EPS_N (P) | 87a | **met** 48/48: NASA's ε_n reproduced exactly, q = 0 modes included |
| APPB_ETA_N (P) | 87b | **not met** 11/46: within 5 % above 470 Hz, 0.56–3.1× below; no q = 0 or floor pattern |
| APPB_ETA_RPP (P) | 87c | **not met** 8/19: NASA's η_r″ does not change with the tone (pair 19 × 6 printed 0.00053 at 250 and 400 Hz), ours does |
| R172428_CODE_ETAN (diagnostic) | 89 | 5/9 (was 4/9): η_n per cabin mode with the trim per 1/3-octave band **not adopted** (decision: ≥ 7/9). Information, post-hoc: η_r″ then within 10 % at 10/19 pairs (8/19) |
| Q0_REPRO_18b, Q0_E18, Q0_E21 (diagnostics) | 88 | 2/3, 1/3, 1/4: **the q = 0 hypothesis is refuted** (pre-registered decision: all three needed). H3 stays 11–13 dB high with or without it |

Under the outcome rules fixed before the runs, 87 found no systematic q = 0 or floor miss, so no code changed, and 88 ran
and refuted H0. The 87b and 87c tables show a different pattern, not foreseen by the plan: NASA's η_n steps at the 1/3-octave
band edges (trim taken per band) and NASA's η_r″ is a property of the mode pair, not of the tone. Phase 89 tested that
reading on NASA's printed levels, which played no part in forming it: 5/9, not adopted. The q = 0, floor-mode and η_n
differences from NASA's corrected program stay unexplained by the documents (R172428_CODE, class N).

## 2.22 Phase 90: Eq. (43) against a measured reflecting wall (2026-10-29)

R996_FIG10_FLAT (E) is **met**, 5/5 within ±1.5 dB: at a flat wall Report 996 measured about the doubling Eq. (43) R1 gives
near normal incidence (γ ≤ 23°). The circular wall (information) measured 0.7–4.9 dB, under R1's 6 dB; NASA's R2 (4 dB) is
closer there and 2 dB under the flat wall. Eq. (43) has no term for curvature. Caveat: Magliozzi's fit data are not in hand.

## 2.23 Walk-through and the methodology website (Phase 91, 2026-10-29; replaced by Phases 113–114, 2026-10-30)

`docs/WALKTHROUGH.md` §2 runs a case and shows its criterion, verdict and table; it changes no case and adds none.
`PAIN.jl/scripts/run/write_walkthrough.jl` regenerates it, with its figures, from a live run.

`site/build_site.jl` builds the methodology website: a read-through of the pipeline, one section per stage. Each
stage opens with a flowchart generated from the `Position` / `Feeds` / `Group` / `Role` fields of §2.13 above — the
same fields the GUI map reads, so the diagrams cannot drift from it — then the stage's *Validation chunk*, *What it
does*, *Chain* and *Claim* parts lifted from `METHODOLOGY.md`, then a card per case: criterion and the date that
criterion was fixed, both copied from the case record, the verdict and error line from the recorded snapshot
(`case_error_summary.csv`, with that row's run date), and the recorded figure.

**Only cases carrying a verdict are on the page** (48 of the register as of 2026-10-30, the same set the map shows).
Information cases, unit tests, diagnostics and displays are left out by design: under the rule of 2026-10-29 they
cannot carry a verdict, so they verify the code rather than the method. They remain here in §2.13 and in
`NO_VERDICT_CASES.md`, and a stage whose blocks hold none says so in place of its cards. The build runs no case and
computes nothing, so it cannot change a verdict.

The Phase 91 Pluto notebooks (`notebooks/`) and their `check_notebooks.jl` were retired on 2026-10-30; the two
walk-throughs they held are `WALKTHROUGH.md` parts 1 and 2.

## 2.24 Phase 92: NASA's printed mode pairs (2026-10-29, diagnostics)

Set pair by pair against CR-172428's printed largest contributors, this code agrees at 15 of 25 pairs within ±2 dB, but its
q = 0 cabin modes, which NASA never lists, carry 70–92 % of three tones. The held-out test of "q = 0 adds nothing"
(3000 rpm, fixed before the run) missed by 0.09 dB at H3 (R172428_CODE_Q0, not met). Post-hoc, q = 0 off with η_n per
mode puts all nine printed levels within ±2.4 dB (R172428_CODE_Q0_ETAN). Inferred from NASA's output, not documented: no
verdict; Phase 93 then made both the default (§2.25). Record: `validation_reports/phase92_appb_pairs.md`.

## 2.25 Phases 93–94: NASA's latest program as the default; held-out Table 12 (2026-10-29)

The code now defaults to the program NASA ran for CR-172428 (September 1984, the latest PAIN document): its documented
App. A corrections and the two behaviours inferred in Phase 92 (q = 0 cabin modes uncoupled, η_n per cabin mode). On a
PAIN run no phase had used, CR-172428 Table 12 (η_T = 2.0), it is within ±1.7 dB at all nine points (R172428_ETAT2,
**met**) and reproduces the three printed η_n within 2 % (APPB_ETA_N_T2, **met**); criteria fixed before the run.
R172428_CODE keeps CR-3813's tone sum and its not-met verdict. Changed recorded results:
`validation_reports/phase94_table12_eta_T2.md`.

## 2.26 Phases 95–96: NASA's band-centre η_n rule (2026-10-30)

NASA's printed cabin-mode η_n follow Eq. (77) evaluated at the nominal 1/3-octave centre holding each mode, for both ω
and the trim conductance (45/46 App. B modes with NASA's admittance). This is now the default. On held-out NASA output
it reproduces the three η_n of the η_T = 2.0 run (APPB_ETA_N_T2_BAND, **met**), and Table 12 stays **met** 9/9. The
remaining η_n differences (up to 29 % at 188–218 Hz) follow this code's trim conductance at the 200 Hz trim resonance.
Record: `validation_reports/phase95_96_eta_n_band_rule.md`.

## 2.27 Phases 97–98: the remaining damping gaps (2026-10-30, diagnostics)

The η_r′ gap (R172428_ETA, 17/32) is the trim term of Eq. (82), 1.4–2.1× low above 470 Hz; the modal masses, the band
centre, an included Σ η_r″ and alternative forms of Eq. (A.8) are ruled out. Together with the η_n gap near the 200 Hz
trim resonance it points to the PF-105 properties between the marked frequencies of Fig. A-2, which a trace of the
figure could not resolve (QA failed). No code change.

## 2.28 Phase 99: the band-centre η_n in CR-3813's program (2026-10-30)

Refuted on held-out data: with the band-centre η_n the pre-correction form moves by at most 0.6 dB against E-16 and E-18
(BAND_REPRO_18b 1/3, BAND_E18 2/3). The H3 excess of 11–14 dB over those predictions is not from the damping rule.
Record: `validation_reports/phase99_band_rule_cr3813.md`.

## 2.29 Phase 100: NASA's per-band PF-105 table (2026-10-30)

CR-172428 App. D prints NASA's PF-105 input per 1/3-octave band (50–5000 Hz). Both predictions fixed before the run hold
(R172428_TRIM_DECK): the App. B admittances are reproduced at 84/84 values and the trim factor within 0.001 dB, including
the 200 Hz trim resonance and NASA's λ typo at 1600 Hz. The held-out R172428_ETAT2 and APPB_ETA_N_T2_BAND stay met. The
CR-172428 inputs now take this table by default. The earlier η_n gap near 200 Hz is closed (APPB_ETA_N_BAND 45/46 within
10 %); R172428_ETA's gap above 470 Hz remains. Record: `validation_reports/phase100_pf105_deck.md`.

## 2.30 Phase 101: CR-172428 flight run 10 (2026-10-30)

CR-172428 prints PAIN's complete flight-test run 10. The MRP solver on NASA's Merlin IVC deck reproduces PAIN's
printed frequencies (219/221 within 2 %) but not enough generalized masses (FLIGHT_MODES not met, 197/221). The scan
cuts the bottom phase rows of the H1 and H5 fields, so the run itself was not reproduced and the trim per band (101d)
stays untested. Record: `validation_reports/phase101_flight_run10.md`.

## 2.31 Phase 102: flight run 10, H2–H4 (2026-10-30, diagnostic)

From PAIN's printed deck and field, the code as it ships is within 1.7 dB of PAIN's printed run 10 levels at H2 and H3
and 4.7 dB low at H4 (FLIGHT10_H234, no verdict). Taking the trim at the band centre moves them by at most 0.4 dB, so
the trim per band is not supported. Record: `validation_reports/phase102_flight_run10_h234.md`.

## 2.32 Phase 103: flight run 10, H4 diagnosis (2026-10-30, diagnostic) and the criteria planned from it

Five findings (`validation_reports/phase103_run10_h4_diagnosis.md`, generated by `scripts/checks/diag_run10_h4.jl`): run
10's printed θ is from the bottom centreline and Phase 102's input flipped it; NASA's CYL2D grid at θ₀ = 50° is NY = 11
with the node rule r ≤ 1 + th, t = 0.43–0.50 (the code uses 0.40); PAIN keeps CYL2D's 2-D frequencies at 341 m/s and adds
the axial term at card 2's c; MRPMOD hands PAIN 5 shell / 3 floor terms (the solver path passes 8 / 5); NASA's run-10
η_r″ follow the floor term subtracted, App. B's added (open). With the first four applied in the script's process, run
10 is +0.74 / +0.94 / −1.06 dB from PAIN at H2–H4 (post-hoc). No code, case or default changed.

Criteria fixed 2026-10-30 for the planned phases (`IMPLEMENTATION_PLAN.md` §8au, §8av, §8ax), before the data they use
are transcribed or computed:
- **CYL2D_PRINTED** (P, CYL2D; Phase 105): for CR-172428's small-diameter (θ₀ ≈ 62.6°) and narrow-body (≈ 73.7°) aircraft,
  PAIN's printed acoustic-mode lists (App. C pp. 221 and 225; θ₀ and a from the decks on p. 210), with the node rule t = 0.45 and NY = 10 else the next grid that
  solves: ε(0,0) within 0.02 %; every 2-D frequency from a legible (Q, I) row within 0.1 % of CYL2D's at 341 m/s / a;
  every mode type equal. Met if all hold for both aircraft.
- **CABIN_FREQ_PRINTED** (P, CYL2D; Phase 106): App. B p. 185's 48 printed cabin modes within 0.02 Hz or 0.02 % (the
  larger), with the 2-D part at 341 m/s and the axial part at 343 m/s. Met if all are.
- **H_pre** (diagnostic; Phase 108): the 10 H1/H5 printed η_r″ of run 10; supported if ≥ 7/10 lie within [0.4, 2.5]×
  NASA's with the floor term subtracted and more than with it added; refuted in the mirror case; otherwise undecided.

## 2.33 Phase 104: run 10's field angle as printed (2026-10-30)

Code-on-code fix of a NASA run's input (Phase 103, D1): run 10's printed θ is read from the bottom centreline and the
propeller sits at 75°. The deck's six printed H2–H4 field cards land on L = 9 + ℓ with the printed phase and 3.9–4.0 dB
above the free field (App. A item 3), a unit test. FLIGHT10_H234 (no verdict) re-run post-hoc: 96.80 / 88.85 / 80.67 dB
against PAIN's 96.59 / 88.06 / 83.92 dB.

## 2.34 Phase 105: CYL2D's grid rule (2026-10-30, not met)

CYL2D_PRINTED (P) is not met: the rule "0.45h, NY = 10 else the next grid that solves" gives NY = 12 at the
small-diameter (62.6°) and narrow-body (73.7°) floor angles, where NASA printed other grids. NASA's narrow-body grid is
NY = 8 (0.40h–0.55h); no App. C grid reproduces the small-diameter list. The rule is not adopted; defaults are
unchanged. Record: `validation_reports/phase105_cyl2d_printed.md`.

## 2.35 Phases 106–107: PAIN's cabin-mode frequency and MRPMOD's term budget (2026-10-30)

Phase 106: CYL2D's 2-D frequencies are taken at its own 341 m/s and the axial term at the deck's c, as PAIN prints them;
CABIN_FREQ_PRINTED (P) is met (App. B 47/47, held out). Phase 107: the solver path keeps MRPMOD's 5 shell / 3 floor terms.
Recorded results that moved are marked "After Phase 106 (post-hoc)" in their records; the first runs stay on record.
APPB_ETA_RPP is now met (16/19). Records: `validation_reports/phase106_cabin_freq_printed.md`, `validation_reports/phase107_mrpmod_terms.md`.

## 2.36 Phases 108–109: run 10's floor sign and residuals (2026-10-30, diagnostics)

FLIGHT10_FLOOR_SIGN (diagnostic): on the 10 held-out H1/H5 pairs, run 10's printed η_r″ follow the pre-correction floor
sign (8/10 against 5/10), so run 10 is reproduced with that sign as an input of NASA's run; App. B and every user path keep
the corrected sign. FLIGHT10_H234 is then −1.99 / −0.62 / −0.03 dB from PAIN at H2–H4 (post-hoc, no verdict). Records:
`validation_reports/phase108_run10_floor_sign.md`, `validation_reports/phase109_run10_residuals.md`.

## 2.37 Phase 110: FLIGHT_MODES second pass (2026-10-30)

The checked transcription of App. C's Merlin mode list corrects two first-pass misreads; FLIGHT_MODES re-run on it
(FLIGHT_MODES_P2, post-hoc) is 199/221 (90.0 %). FLIGHT_MODES' first-pass verdict (not met) stays. The shell and plate
normal-displacement parts of the generalized mass match NASA's printed SHELL W and PLATE W; the total-mass misses are in
the in-plane part. Record: `validation_reports/phase110_flight_modes_pass2.md`.

## 2.38 Phase 111: NASA's CYL2D grid rule (2026-10-30, closed)

The documents do not say how CYL2D chooses its grid (CR-3813 App. C: h = δa, no rule for δ or NY; User Manual §5.1: θ₀ is
the only input). Closed as not explained by the documents; CYL2D grids at floor angles other than 56.6° remain a stated
difference from PAIN (CYL2D_PRINTED not met).

## 2.39 Phase 117: run 10's η_r″ at 0.65× NASA's (2026-11-02, diagnostic)

Tests fixed in `IMPLEMENTATION_PLAN.md` §8bg (commit 001b34f) before any factor was computed; no case and no verdict (a
script, `scripts/checks/diag_run10_eta_rpp.jl`). On the 24 printed pairs the ratio is a pair-independent 0.65 (Spearman ρ
with the resonance share 0.00): not the generalized mass (this code's M_r equals App. C's printed total, median 1.000; no
printed mass kind meets H_M) and not the cabin damping. The candidate read afterwards, f′ divided by the length over the
cavity when L > L_c, is post-hoc; the author kept the 38f-1
normalization by L (Q99, 2026-11-02), so run 10's 0.65 stays a recorded difference. On the way, `axial_coupling`'s sign of the cavity offset d
was fixed to Manual card 9 and CR-159363 Eq. (25), with a unit test against Eq. (25) as printed; every recorded case has
d = 0, so no recorded value moves. Record: `validation_reports/phase117_run10_eta_rpp.md`.

## 2.40 Phase 118: input completeness, the missing inputs, the full-input misses, Q95 (2026-11-02)

Rule and per-case table fixed in `IMPLEMENTATION_PLAN.md` §8bh (commits 1834084, d673393) before any case was moved or
re-run.

**118a. Input-completeness rule.** A case keeps a verdict only if every input that enters its compared quantity is
printed or measured in the source it is compared with (or the reports that source cites for its data), or computed by
this code from such inputs. Applied by kind to the 51 cases with a verdict: 14 fail and carry no verdict since
(`INFORMATION_ONLY_CASES`, reason "inputs incomplete: …"; listed apart in `NO_VERDICT_CASES.md`):

| Failing input | Cases |
|---|---|
| E-11's ℓ = 1 line extended by GEXT (PAIN's own grid field for CR-3813's runs is not printed) | REPRO_18b, E18_TONES, T1, T1_MEAS_DAMPING, UNC_COVER, T1_FROM_E12 (E-12 line) |
| F1A or BPM on an assumed blade (the test propeller's geometry is proprietary) | T1_F1A_FILL, T2_PRED_BB, PROP_BB_FIG14, PROP_BB_FIG17 |
| assumed exterior broadband shape or extrapolated exterior | T2_EQ19, T2_MEAS_EXT, T2_MEAS_EXT_BR |
| assumed Aero Commander blade geometry | BBN_CIRC |

All 14 were not met; no met case failed the rule, and the other 37 verdicts are unchanged (re-run 2026-11-02). Their runs,
tables and recorded outcomes stay (`original_verdict`); none is a pass. The map now holds 37 cases: 14 met, 23 not met.

**118b. The missing inputs** (`validation_reports/phase118_input_search.md`). Found: CR-172428 App. B's blocked field for
the same article, propeller and rpm at all 16 × 19 points (H1–H3), a printed field for the T1 family, used in Phase 119 (§2.41). Not printed: the field of CR-3813's own runs, the test-propeller blade, the full Aero Commander blade, and the
test article's exterior broadband above 1250 Hz.

**118c. The 23 full-input misses** (`validation_reports/phase118_full_input_misses.md`). Every cause the documents name
was already tested except E14_LOSS's coarse Fig. A-2 digitization. Run once against E14_LOSS's criterion with NASA's
per-band PF-105 table (`phase118_e14_deck.md`): 6/18 against 7/18, not supported.

**118d. Q95: Eq. (43) past γ = 90°.** R1 is held at F = 1 past 90° (CR-3813 p. 31: the amplitudes "are increased";
CR-172428 p. 68: the increase falls "finally to zero at 90°"). No case with a verdict moves: BLK_P68, E12_BLOCK and
R996_FIG10_FLAT see no γ > 90°, and the CR-172428 cases use App. B's blocked field as printed. The no-verdict R1 runs move
by ≤ 0.3 dB in their medians (REPRO_18b, E18_TONES, Q0_REPRO_18b, Q0_E18, BAND_REPRO_18b, REPRO_18b_DECK);
BLK_GAIN_MAP now holds on the grid (2/2).

**118f. Unit-test gaps (verification, no verdict).** Unit-test gaps found while running Phase 118's tests (both failures pre-date 118, verified on d673393). (1) `test_case_helpers_late.jl` iso44 compared `_r172428_levels()` (pinned to CR-3813's tone form, R172428_CODE, Phase 93) with `interior_spl` of the default form (q = 0 off, η_n per mode since Phases 93–96): the test was stale, the case is not; it now compares the same form and checks that the default form differs. (2) 21 functions added in Phases 92–110 had no unit test; each now has a hand-value or limit test that fails if the function is wrong (five mutants checked). No criterion, recorded result, default or data file changed. The map and `NO_VERDICT_CASES.md` are unchanged.

## 2.41 Phase 119: the T1 family on CR-172428 App. B's printed field (2026-11-02)

Form and criterion fixed in `IMPLEMENTATION_PLAN.md` §8bi (commit 84dbb27) before any run. T1's cabin as it ships, with
E-11's line + GEXT replaced by the blocked field PAIN used for the same article, propeller and rpm (App. B printed
pp. 193–195, 4000 rpm, 16 × 19 points, no blocking applied); T1's gate unchanged (2026-10-20).

| Case | H1 / H2 / H3 (dB) | Gates | Verdict |
|---|---|---|---|
| E-16 measured mean | 90.0 / 80.0 / 65.0 | — | — |
| `T1_APPB` | 88.51 / 75.32 / 65.36 | A, B only, A | **met** 3/3 |
| `T1_MEAS_DAMPING_APPB` | 90.06 / 78.74 / 65.80 | A, A, A | **met** 3/3 |
| `T1` on E-11 + GEXT (no verdict since 118a) | 86.95 / 79.21 / 77.00 | A, A, fail | — |

With the printed field the T1 family's H3 excess disappears (77–79 → 65.4–65.8 dB), as §2.14 attributed it to the GEXT
field. T1_APPB's H2 is 4.7 dB under the measured mean and passes through gate B (0.2 dB from NASA's E-16 prediction),
which is part of T1's registered criterion. Not held out in full: CR-172428's measured 4000 rpm levels are E-16's means,
and R172428_EXP had set App. B's field against them with CR-172428's cabin. UNC_COVER and T1_FROM_E12 were not re-run
(their designs rest on the E-11 field and the E-12 line). Record: `validation_reports/phase119_t1_appb.md`.

## 2.42 Phase 120: the auto floor angle (2026-11-03, no comparison)

No case, criterion or recorded result changed. The GUI's auto θ₀ takes the printed aircraft nearest in radius; for a
2.5–2.7 m fuselage that is CR-172428's small-diameter 62.6°, where CYL2D_PRINTED records how far the default grid is from
NASA's printed list (2-D orders 1–4 within 1.1 %, higher orders 1.7–3.4 %; diagnostic). Method: `METHODOLOGY.md` §4.

## 2.43 Phase 121: Commander 695A cabin dB(A) against CR-178004 (2026-11-03, information)

The aircraft cabin block's first comparison with an aircraft interior measurement. PAIN run from the Commander 695A's
printed inputs plus assumed blade, cabin section and stiffener sections (case `AC_C695A_DBA`, form fixed 2026-11-03
before the run; no verdict under the Phase 118 input rule). PAIN is 12.9–18.2 dB(A) under the measured cabin levels at
all 36 points (mean −15.4 dB). The tones at BPF and 2×BPF are about 6 dB low; most of the gap is broadband at 250 Hz–2 kHz
that PAIN does not model (only the propeller drives its cabin; its broadband starts at 1 kHz). Record:
`validation_reports/phase121_c695a_dba.md`.

## 2.44 Phase 122: Commander 695A cabin tones against CR-178004 App. B (2026-11-03, information)

The tones alone, which is what PAIN models (case `AC_C695A_TONES`, form fixed 2026-11-03 before the run; no verdict).
Each engine's cabin H1–H3 against App. B's printed component at mics 3 and 6: 27/108 within ±4 dB, PAIN low by 6.7 dB on
average (H1 −5.7, H2 −7.4, H3 −7.0 dB). So of AC_C695A_DBA's −15 dB(A), about 6–7 dB is PAIN's propeller tones being low
and the rest is the broadband PAIN does not model. The assumed rotation signs move the port/starboard split but not the
mean (post-hoc diagnostic). Record: `validation_reports/phase122_c695a_tones.md`.

## 2.45 Phase 123: the 695A source, and App. D modes up to the tones (2026-11-04)

The exterior tones (`AC_C695A_EXT`, information) are 4.0 dB *above* CR-178004 App. A's flush microphone, so the
cabin shortfall of Phases 121–122 was transmission. Cause: the aircraft pipeline kept the 32 lowest App. D modes
(105 Hz on the 5.33 m cabin). Since Phase 123 it keeps every mode up to twice the highest tone, with the series
converged (`appd_modes_to_cutoff`, rule fixed before use). Reruns are post-hoc: AC_C695A_DBA 35/36, mean +0.7 dB(A);
AC_C695A_TONES mean +2.0 dB. Record: `validation_reports/phase123_c695a_exterior.md`.

## 2.46 Phase 124: interior dB and dB(A) against NASA PAIN and the measurement (2026-11-04)

On CR-172428's test article, the H1–H3 energy sums (dB and dB(A)): the frozen CR-3813 tone sum misses NASA's printout
(0/3 each); against the measurement the code meets 1/3, as NASA's own printout does. The code as it ships is within
0.9 dB(A) of NASA's sums, which is not independent (Phase 93 took that form from these printouts). Record:
`validation_reports/phase124_r172428_dba.md`.

## 2.47 Phase 125: the 695A tones at the mic seats (2026-11-04, information)

The mics are in the propeller plane, so `AC_C695A_SEAT` compares PAIN's Eq. (8) point form at that seat with App. B:
43/108 within ±4 dB (space average: 32/108); PAIN − measured mean −0.2 / +9.3 / +7.3 dB at H1 / H2 / H3 (port +4.1 dB H2, starboard +14.4 dB H2); the seat is +5.3 / +1.1 / +3.8 dB above the space average. At the seat H1 agrees on average; H2 and H3 are high. Record: `validation_reports/phase125_c695a_seat.md`.

## 2.48 Phase 126: the H1 shortfall is PAIN's method; I-18 closed (2026-11-04, diagnostics)

No case added and no criterion changed. On CR-172428's test article this code is within 0.2 dB of NASA's printed
PAIN H1 (0.34 dB on the held-out η_T = 2.0 run, R172428_ETAT2), and NASA's PAIN is 14–18 dB under the measured H1 at
3000 and 5000 rpm, so R172428_EXP's H1 misses are the method's. The 695A H1 shortfall (AC_C695A_TONES, _SEAT) is
consistent with this, not proved (NASA never ran PAIN on the 695A). I-18 closed: the lower-quarter grid breaks the
match with both NASA runs, so the 160-point grid stays. Record: `validation_reports/phase126_h1_method_and_i18.md`.

## 2.49 Phase 127: inputs and run-path constants as GUI fields (2026-11-04)

No case, criterion, reference or recorded result changed. The run-path constants are `PainSettings` fields whose
defaults are the literals they replaced; validation cases run with the defaults, so every case is computed as before (the
default Hartzell, e11 and 695A runs are bit-identical). A GUI setting changed from its default makes that run a
user variant, not a case: the Validation tab never takes GUI settings. Choosing a setting by its effect on a compared
case would be calibration (CLAUDE.md) and is not offered. Inventory: `INPUTS_AND_SETTINGS.md`.

## 2.56 Phase 134: chain span and reference of every case (2026-11-05)

Every §2.13 case gains `**Chain span:**` and `**Compared with:**` (format note above). They describe each case; they
are not criteria. No case, criterion, tolerance, reference data or recorded result changed, and no verdict moved on or off
the map. Three verdict cases that compare with NASA's printed output for the same inputs (BLK_P68, NR_TP1964_REF2,
NR_TP1964_XOVER_REF2) are labelled "NASA's printed prediction", their verdicts as already ruled; H3_ATTRIB is labelled
verification (it attributes a difference, with no verdict). A unit test checks that no case with a verdict is labelled
verification.

## 2.55 Phase 133: GUI default blade pitch (2026-11-05)

The GUI default's blade pitch is set so CCBlade absorbs the author's stated 2200 hp; it is an input taken from that
power alone, compared with nothing. The default stays X-EXTRAP and is not a case; no case, criterion, reference or
recorded result changed.

## 2.54 Phase 132: audit (2026-11-05)

No case, criterion, reference or recorded result changed. The 695A grid runs are a diagnostic of an information case
(rule fixed before the runs); AC_C695A_TONES stays as recorded (32/108).

## 2.53 Phase 131: GUI default grid (2026-11-05)

Numerics of the GUI default only (X-EXTRAP, compared with nothing, not a case). The convergence rule was fixed in Q111
before the runs; no case, criterion, reference or recorded result changed; the cases keep the 16 × 10 grid.

## 2.52 Phase 130: GUI default inputs, wall mass, tones only (2026-11-04)

No case, criterion, reference or recorded result changed. The wall-mass change acts only when a project gives structure
inputs and no wall mass; no validation case does (the Commander 695A and Hartzell full-cabin projects give m). The GUI
default stays X-EXTRAP, compared with nothing, not a case. Table 13's small-body values are printed inputs of another
aircraft, used unscaled; nothing was chosen by its effect on a result. The settings check of §8bt (COMPLETED_PHASES)
is verification: each setting runs and acts where it applies; it is not a verdict.

## 2.51 Phase 129: GUI default blades (2026-11-04)

The default project's propeller is now HP_1650 at helical tip Mach 0.85. Still X-EXTRAP, compared with nothing, not a case; no criterion or record changed.

## 2.50 Phase 128: the GUI default project (2026-11-04)

The GUI default is Cabin_Noise's generic twin turboprop (X-EXTRAP), compared with nothing: it is not a case and has no
verdict. No case, criterion, reference or recorded result changed. The cases and tests that ran the old default
(scale Hartzell) still run it, from its own file.
