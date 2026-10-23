# Phases 50–58: propeller-field noise reduction, the sound-bridge question, and the open items

Run 2026-10-23 at the author's request ("keep implementing the phases until they are all closed out"). Criteria fixed 2026-10-23 in `IMPLEMENTATION_PLAN.md` §8e and §8f (commit fa84652), before any of these was run. Testset: "Propeller-field NR and open items (phases 50, 53, 56, 57)", 28/28.

## Phase 50: propeller-field coupling for the noise reduction below the changeover

### 50a (Ψ_G machinery against the diffuse j_r²): not met as written, 2/5 within 1 dB

Random-incidence plane waves (3000, first run) were applied on a full-cylinder grid (60 × 120) and passed through the tone path's `generalized_force`. The result was compared with the mode-normalised diffuse j_r² of Eq. (66).

| Mode (M, n, sym), f | Monte Carlo / Eq. (66) |
|---------------------|------------------------|
| (1, 0, s), 300 Hz | −1.14 dB |
| (2, 3, s), 600 Hz | −0.42 dB |
| (3, 4, a), 1000 Hz | −1.44 dB |
| (1, 6, s), 1250 Hz | −2.05 dB |
| (4, 2, s), 800 Hz | −1.12 dB |

A rerun with 12 000 waves gave −1.46 and −1.75 dB for two of the modes (diagnostic only). The offset is stable and systematic, so it is not sampling noise. CR-3813 Eq. (66) multiplies the axial and circumferential acceptances, a separable approximation to the 2-D diffuse correlation sin(kr)/(kr). The exact 2-D value is 0.4–2 dB lower. The Ψ_G machinery itself is consistent; the printed approximation accounts for the difference.

### 50b `NR_PROP_TP2444_PF`: not met, 2/7

Model: Eq. (8) on `r172428_inputs(4000)` with the App. B field shape of the nearest printed harmonic. It is averaged over 11 frequencies in each band and referred to the blocked level at the grid point in the propeller plane on line ℓ = 1 (array index L = 10).

The first run used array index 1 for line ℓ = 1 and gave −Inf. That was a coding error against the written decision (the App. B layout is L = ℓ + 9). It was fixed before any valid comparison.

| Band (Hz) | Measured NR | Diffuse model (47c) | Propeller field (50b) |
|-----------|-------------|---------------------|-----------------------|
| 315 | 36.0 | 16.6 | 42.0 |
| 400 | 31.8 | 13.5 | 37.7 |
| 500 | 33.0 | 7.5 | 29.6 |
| 630 | 30.0 | 5.0 | 36.8 |
| 800 | 32.3 | 8.7 | 37.2 |
| 1000 | 32.0 | 34.0 | 63.6 |
| 1260 | 33.9 | 49.1 | 83.1 |

**Reading.**
- **315–800 Hz.** The propeller-field coupling moves the model from 18–26 dB too low to −3.4…+6.8 dB of the measurement. The gap 47c found below 1 kHz therefore came mostly from using the diffuse coupling for propeller excitation.
- **1000 and 1260 Hz.** These bands are above the top of the 32 Table D-1 modes (811 Hz), where Eq. (8) has no resonant structural mode. They do not test the method.

## Phase 51: sound-bridge path in Eq. (23), not run

**Condition.** The condition held: the T2 gap is about 30 dB after Phases 49, 48 and 50.

**Why not run.** 51a requires the source paper's worked example (Sharp 1978 or Fahy, point and line connections) within 1 dB. Neither is available from an official source; the NTRS searches on 2026-10-23 found double-wall papers without connection models or worked examples. An unverified model would not meet the phase's own first step, so it was not implemented.

**What PAIN already has.** A bridge-type path is part of the theory: the trim mechanical path of App. A (Eqs. A.19–A.21, `trim_tau_mechanical`), included in τ_t. For the T2 inputs it is the larger of τ_t's two parts at 1260 Hz (−22.4 dB). Even so, Eq. (23) multiplies τ_t by the wall's τ, so no path bypasses the product.

## Phase 52: T1 H3 miss

- **52a.** With NASA's own printed exterior field (CR-172428 App. B, 4000 rpm), our H3 is 71.69 dB against NASA's printed 71.3 dB, and the measured value is 65.2 dB. The cabin chain reproduces NASA, and NASA's own H3 is 6 dB above the measurement. With the e11 field (T1), H3 is 75.23 dB against NASA's E-16 prediction of 68.0 dB. With the F1A off-line fill (T1_F1A_FILL, post-hoc) it is 66.95 dB. The H3 excess in T1 therefore comes from the exterior field off the measured line (the grid extension, Phase 32), not from the cabin.
- **52b.** Documented input alternatives, H1/H2/H3 in dB (measured 90/80/65):

  | Alternative | H1 | H2 | H3 |
  |-------------|----|----|----|
  | production | 87.36 | 81.02 | 75.23 |
  | blocking R1 | 89.20 | 82.35 | 77.06 |
  | η_T = 1.0 | 85.40 | 79.81 | 73.40 |
  | η_T = 1.0 + η_r′ cap 0.15 | 89.50 | 80.18 | 73.40 |
  | cap alone | 90.71 | 81.48 | 75.23 |

  None brings H3 within ±4 dB.
- **52c.** No documented correction exists, so T1 is unchanged (not met at H3).

## Phase 53: negative and runaway noise reduction

- **53a.** TP-1964 Eq. (18) gives NR < 0 at 1–2 kHz. This is a property of the equation: CR-159363 p. 138 reports NASA's own prediction with the same model going negative at 1000 Hz (−5.3 dB) and 1250 Hz (−10.2 dB) for a 1.22 m cylinder. The code matches the hand Eq. (18) within 1e-9 (`NR_BAND_HAND`, 41c).
- **53b.** The 400 Hz band with the E-21 inputs (Eqs. 19–23) dropped from 100.4 dB to 41.3 dB after the Phase 49 Eq. (20) reading correction; the runaway came from τ_f summing only two poorly radiating in-band modes. A guard (`sparse_guard`, off by default) is added. It moves a sparse band whose in-band ⟨j²⟩ is below the all-mode mean to the asymptotic branch, giving 32.9 dB at 400 Hz. Well-populated bands are unchanged (tested at 1000 Hz).

## Phase 54: Q22 (q = 0 coupling in NASA's program)

CR-172428 pp. 177–181 prints only the changes NASA made to the program. Those lines use `FQM(IQ,M)`, but not how it is formed, and the full PAIN source is not in any of the documents.

**Q22 is closed as "not explained by the documents".** No change is made.

## Phase 55: T2's calibrated surrogate, decided

**Decision (2026-10-23, under the author's authority to decide):** keep `broadband_cabin_p2` with `bb_j2_scale = 0.5` as the production default, labelled calibrated (no claim).

Reasons:
- Neither cabin path is validated above 1 kHz (Phases 47–49).
- T2 is 0/3 either way.
- Switching would change the frozen Phase 17 baselines and every aircraft broadband output, with no gain in validity.

The T2 case text now states that its closeness to E-9 rests on compensating errors (the exterior 17 dB high, the cabin path too). No verdict or number changed.

## Phase 56: 40f, the Ritz solver in isolation

- **56a: met.** `structural_modes` gains `include_floor` and `include_stiffeners` switches, on by default. The default outputs are identical, and `MRP_RITZ` is unchanged.
- **56b: not met.** With stiffeners and floor removed (θ₀ = 0, `hybrid = false`), the first 10 bare-shell frequencies are 29–479 % above closed-form Donnell–Mushtari with the default `k_scale` = 0.61. With `k_scale` = 1 (diagnostic) they are 65–641 % above. The solver's shell term carries an empirical ring term (0.12·Et/(m a²)·n²/(n² + λ²)) and a fitted stiffness scale, so it is not a Donnell–Mushtari shell. This agrees with `MRP_RITZ` being recorded as a calibrated fit; production uses Table D-1, and the App. D solver (`appd_modes`) is separate.

## Phase 57: the never-executed functions now have tests

Each test is checked against a hand value or an independent route:
- **`parse_aircraft_trim_json`:** gives the same τ as the stack built by hand; mechanical path, area and default end plate as specified.
- **`_rand_triangular`:** the sample mean equals (lo + hi + mode)/3 within 0.01, and every sample lies within the bounds.
- **`fit_mrp_to_table_d1`:** on a one-point grid it returns that point and its own match count.
- **`appd_constraint_residuals`:** an App. D eigenvector satisfies Eq. (D.4) to 1e-8, while an arbitrary vector does not.
- **`scale_acoustic_freq`:** equals the q = 0 cabin frequency from the mode eigenvalue.
- **`hf_broadband_spectrum`:** its 1.25 kHz band equals Eqs. (19)–(23) applied to the blocked broadband level.
- **`build_aircraft_cache`:** not given a separate test. It runs the full aircraft pipeline, which the Aircraft provenance 29b/29c tests exercise, and the uncertainty phase-31 runs call it through `uncertainty_aircraft_band.jl`.

## Phase 58: leftovers

- **58a.** The 47a broadband QA, restated post-hoc with the union of nominal and observed tone windows. Median / p95:

  | Trace | Union mask | Recorded (nominal mask) |
  |-------|------------|-------------------------|
  | Fig. 17 exterior | 0.588 / 1.620 dB | 0.596 / 1.734 dB |
  | Fig. 17 interior | 0.605 / 2.313 dB | 0.622 / 2.676 dB |
  | Fig. 14 | 0.82 / 2.83 dB | 0.83 / 3.69 dB |

  The 47a verdict as written is unchanged.
- **58b.** CR-172428 Fig. 16 (phase spectra, the same run 8113) puts the harmonics at H·250 Hz on its tick scale within about 7 Hz. That confirms that Fig. 14's separately drawn axis is offset from its trace (the mean offset of H1–H7 is 15.0 Hz).
  - **Sensitivity** (data left as calibrated): a +15 Hz shift changes Fig. 14's broadband band levels by ≤ 1.1 dB except +3.3 dB at 315 Hz, and the 1250→2000 Hz slope from +0.32 to −0.09 dB.
  - **No 47 verdict changes.**
  - **PROP_BB_FIG14** would lose its 315 Hz band (2/9 instead of 3/9).
- **58c.** The Phase III alternative in 47c with the mechanical-path wall mass set to the article's shell (3.113 instead of 3.228 kg/m²) changes NR by ≤ 0.2 dB.
- **58d.** The 37e/37g items were already done in Phase 37 and verified 2026-10-23 by rendering R996_FIG14: blank legend entries are not drawn (`_legend_kw`), log axes use round ticks (`_apply_log_ticks!`), and the BBN_CIRC and R996_PHASE explanations are in §2.13. Their stale "Pending" status is corrected.
