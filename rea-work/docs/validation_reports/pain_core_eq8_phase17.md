# Phase 17 — Eq. (8) tone pressure and PAIN-core verification (run 2026-10-20)

Verification against the written equations of CR-3813, analytic limits and an independent re-implementation. **Not validation:** NASA publishes no Ψ_G, p² or power-balance numbers. Code: `src/pain_core.jl`, `src/PAIN.jl`, `src/trim_loss.jl`; tests in `test/runtests.jl`; diagnostics `scripts/checks/probe_q_convergence.jl`, `probe_trim.jl`, `probe_t1_levels.jl`.

Equation numbers and the printed forms of Eqs. (7), (8), (41) and (42) were read from the page images (PDF pages 25 and 41, printed pp. 15 and 31) on 2026-10-20.

## 1. Equation trace for the PAIN core (17c, table written; step completed after phase 18)

| Item | CR-3813 | Code | Verdict |
|------|---------|------|---------|
| Power balance W_in = W_diss, Eqs. (1)–(2) | §3.1 | not evaluated; Eq. (8) is the closed form | not checked (17h conservation open) |
| Sum over cabin modes, Eq. (3) | §3.1 | `tone_mean_square_pressure`: sum over n = (q, i), q = 0…q_max, i = 0…19 (the rigid-body mode i = 0 as the ω_n → 0 limit) | matches |
| Inflowing power, Eq. (7) | p. 15 | not used (Eq. 8 follows from Eqs. 1, 5, 7) | not evaluated |
| Tone pressure, Eq. (8) | p. 15 | `(c0/V)² (ρ0 c0 A)² ω_H⁴ ε_n f̄'² Ψ_G / (M_r² D_n D_r)`, D_n = (ω_n² − ω_H²)² + N², D_r = (ω_r² − ω_H²)² + ((η_r' + η_r'')ω_r²)². The two resonance denominators are Eq. (8)'s multiplied out | **matches** as printed, with three identifications: (mA/4)²τ_ML = (ρ0c0A/(2ω_H))² (confirmed in plan 19b, 2026-10-20: exact with τ_ML = (2ρc0/(ωm))² of p. 11, m cancels; `eq8_two_resonator.md`); A = L(Lp + 2a(π − θ0)); η_n evaluated at ω_H (Eq. 77 has ω in it) |
| Ψ_G, Eqs. (41)–(42) | p. 31 | `generalized_force`: (Δ⁴/2)[(Σ A ψ cos φ)² + (Σ A ψ sin φ)²], Δ⁴ = ΔA². The earlier code returned Δ²\|Σ A e^{iφ} ψ\| = √(2Ψ_G) | **matches** now (test: equals the double sum of Eq. 41). Open: the PAIN printout lists grid points "both above and below θ = 0" (CR-172425 §5.4.3 item 7); the code sums the 160 stated points only. **Decided in plan 19d (2026-10-20): no mirroring** (the input grid, Fig. 3, the card-36 note and CR-3813 §3.4 give one side only; the item 7 wording is an output listing and stays unresolved); mirrored diagnostics in `grid_mirroring.md` |
| Coupling f̄'(n,r), Eqs. (45), (52)–(57) | pp. 32–34 | `coupling_factor`, τ_t of Eq. (A.22) at ω_H | matches (17f) |
| τ_t in Eq. (8) | note under Eq. (7) | only inside f̄' (√τ_t on the shell term); the T⁴ double count of the earlier surrogate is gone | matches |
| η_n, Eq. (77) | §3.8.1 | `acoustic_loss_modal`, ξ and ξ_e from Eq. (A.16) at ω_H; bare cabin: `η_n_bare` ω_n² | matches (ω_H evaluation is an interpretation) |
| η_r (79)–(81), η_r' (82), η_r'' (83) | §3.8.2 | `structural_loss_total`, `structural_loss_with_trim` (C_w at ω_r), `structural_loss_coupled` (every (n, r) pair, register i) | matches as printed (printed n > 0 joint acceptances are half the mode-normalized value, recorded in 16b) |
| ε_n, Eq. (C.11); q > 0 | App. C | `cabin_eps_3d`: twice the q = 0 value for q > 0 | **matches Eq. (C.11) as printed** (plan 19c, 2026-10-20): pp. C-6/C-7 read from the page images give ∫φ²dV = (L/2) ε_q Σφ²h²C(j), ε_q = 2 for q = 0 and 1 for q > 0, ε_n = 2[π − θ0 + cosθ0 sinθ0]/(Φ_G ε_q), so q > 0 is exactly twice q = 0; quadrature confirms the factor 2 to 1e-15 (`eps_n_quadrature.md`). Not an interpretation; the earlier V-ASSUMED tag is withdrawn |
| Broadband, Eqs. (16)–(24) | §3.3 | τ_t of Eq. (A.22) replaces the T² of the surrogate; α(f), χ, `bb_j2_scale`, H = 3 anchor unchanged | surrogate, phase 29b |

## 2. Results of the verification steps

| Step | Result |
|------|--------|
| 17a | Done. 38 new test checks in four testsets (`Pkg.test()` passes). Eq. (8) replaces the surrogate; the T⁴ trim count is removed; `PainInputs` carries trim stacks, `m_wall`, `η_n_bare`, `C_struc`, `q_max`, `allow_extrapolation`. |
| 17b | Done. Broadband uses τ_t of Eq. (A.22). Bands above Fig. A-2 (6.3 kHz, e.g. the 8 kHz band) are omitted unless `allow_extrapolation=true`. |
| 17d | **Open.** The 32 shapes are transcribed (88 shape tests). An exploratory check, fitting M_r ≈ m_s ∫ψ_s² dA + m_p ∫ψ_p² dA with two free masses, left residuals up to 56 % (fitted m_s 4.66, m_p 3.77 kg/m²). It had no pre-fixed tolerance, so it counts as exploratory only; it does not show an error in the transcription, because the shell and plate generalized-mass columns of Table D-1 and the Eqs. (D.22)–(D.26) normalization are not in the repository. Needs those columns and Fig. D-2. |
| 17e | Done (11 checks): closed form for uniform A and ψ; two equal points π apart cancel; a global phase shift changes nothing; Eq. (42) equals the double sum (41); amplitude ×2 gives Ψ_G ×4 (the force amplitude √(2Ψ_G) ×2; the plan's "doubling A doubles Ψ_G" holds for the amplitude, not for Ψ_G); antisymmetric ψ against a symmetric loading gives 0; Δ = πa/18 on the grid and the axial sum against its integral (rtol 5e-3). |
| 17f | Done. Count of \|f'\| > 1 errors in the runs of this phase (e11 bare and Phase III trim, q up to 13, synthetic, aircraft): **0**. |
| 17g | Done. D = (ω0² − ω²)² + (ηω0²)²: peak value, half-power width, and the finite ω_n → 0 limit; a cabin of the rigid-body mode alone gives a finite positive p². |
| 17h | **Partly done.** Independent re-implementation: Eq. (8) in its direct (not multiplied-out) form, f̄' by midpoint quadrature (20 000 points) of Eq. (52), Ψ_G from the double sum of Eq. (41), against the code on a bare cabin without the rigid-body mode: agree to rtol 2e-3 (test). Open: the W_in = W_diss conservation check with coupled resonators (the relation between Eqs. (7) and (8) was not derived here). |
| 17i | Done. p² ∝ amplitude²; zero amplitude gives 0; global phase shift changes nothing; f̄' = 0 gives 0; scaling a cabin mode shape (ε_n ∝ 1/s², φ ∝ s) leaves p² unchanged, with and without trim; scaling a structural shape (M_r ∝ s²) leaves f̄'²Ψ_G/M_r² and η_r'' unchanged. **Finding:** the radiation loss η_r of Eqs. (79)–(81) uses C_Mn² unnormalized (j_r² ∝ s²), so the full p² is not invariant under a shape scaling; the Table D-1 coefficients are taken as already normalized. |
| 17j | Done: **no reference output exists.** CR-172425 §5.4.3 lists the printed quantities without numbers and §6 gives control cards and input only; Table D-1 remains the only example output (modes). Searched the extracted text of CR-172425 and CR-172428 (OCR quality limits the search); no ANOPP free field at all 160 points was found; `data/cr3813/anopp_table8_*.csv` covers ℓ = 1 only. 18b uses GEXT on Table 8 and is conditional on it. |
| 17k | Open (after phase 18). |

## 3. Axial truncation (register d), Eq. (8), `q_convergence.md`

q_max = 5, 9, 13 at H1–H3; q_max + 2 changes the tone SPL by 0.000 dB at every harmonic for both the Phase III trim and the bare cabin: rule met. Adding the q > 0 modes raises H2 by 6.7 dB (trim) and 4.0 dB (bare) and H3 by 7.7 dB and 3.4 dB over q = 0.

## 4. T1/T2 with the untuned chain (recorded, not tuned; regrade in 18a)

e11 source, R2 blocking, Phase III trim (`trim=:phase3`), `η_n` from Eq. (77), C = 3, nothing fitted to T1 or T2 in the tone path.

| Quantity | Result | Target | Gate |
|----------|--------|--------|------|
| T1 H1 (200 Hz) | 90.24 dB | mean 90.0, NASA PAIN 79.0 | PASS (mean ± 4) |
| T1 H2 (400 Hz) | 79.30 dB | mean 80.0, NASA PAIN 75.5 | PASS (mean ± 4) |
| T1 H3 (630 Hz) | 83.15 dB | mean 65.0, NASA PAIN 68.0 | FAIL (+18.2 dB) |
| T2 1.25 / 1.6 / 2 kHz | 62.25 / 60.34 / 58.48 dB | 51.0 / 46.0 / 41.5 | FAIL (+11.3, +14.3, +17.0 dB) |

T2 still carries `bb_j2_scale` = 0.5 from an earlier fit (a calibrated parameter, now stale) and the surrogate α(f), χ and f⁻² slope; the broadband path is replaced in 29b. At H1 the sidewall trim's τ_t (insulation plus mechanical path) is 15.6 at 200 Hz for the register default lining loss 0.05, a trim resonance (16a found τ_t > 1 at 100–200 Hz), so H1 depends on it strongly. The H1 and H2 passes are not validation: the result is conditional on the identifications in section 1 and on the open 17h conservation check.

## 5. Sensitivity over the register ranges (`probe_t1_levels.jl`; H1–H3 SPL, dB; nothing chosen to improve T1/T2)

| Run | H1 | H2 | H3 |
|-----|---:|---:|---:|
| Phase III trim (default) | 90.2 | 79.3 | 83.2 |
| bare, η_n = 0.05 | 90.6 | 83.3 | 81.9 |
| bare, η_n = 0.02 | 90.9 | 85.5 | 85.4 |
| bare, η_n = 0.10 | 89.5 | 81.0 | 78.7 |
| Phase III, C = 2 / 4 | 90.2 / 90.2 | 79.3 / 79.3 | 83.2 / 83.1 |
| Phase III, lining loss 0.01 | 91.3 | 82.2 | 86.4 |
| Phase III, lining loss 0.10 | 88.9 | 78.3 | 81.3 |
| Phase III, facing on the skin side | 92.7 | 79.5 | 82.5 |
| Phase III, G-10 wavespeed 2800 / 3600 m/s | 90.2 / 90.2 | 79.4 / 79.3 | 83.2 / 83.1 |
| Phase III, points only (no floor-edge lines) | 90.2 | 78.0 | 81.9 |
| Phase III, lines only (no point connections) | 90.2 | 79.1 | 83.0 |

No register range brings H3 within 13 dB of the measured mean (65.0 dB; the lowest value is the bare cabin with η_n = 0.10, 78.7 dB). These are the inputs to the uncertainty budget (phase 30).
