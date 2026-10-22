# MRP_APPD — App. D Eqs. (D.17)–(D.26) vs Table D-1 (phase 38g, first run)

Label: **V-CODE (vs NASA's solver outputs), first run of the printed App. D formulation 2026-10-22**.

Criterion (fixed **2026-10-22 before any run**; not changed): ≥ **75 % of the 32** Table D-1 modes within **5 %**; no calibration input. Fig. D-2 mode-1 shape reported **without** a pass mark. A miss is recorded as a miss. Nothing was changed after seeing this comparison.

## Verdict

**`:met` — 27 / 32 within 5 % (84.4 %); threshold ceil(0.75×32) = 24.** No parameter fitted to Table D-1 / Fig. D-2.

Fig. D-2 (info only): max |Δw| = **1.4534** over 49 digitized points (no pass mark).

## Equations as implemented

Printed forms from CR-3813 Appendix D (PDF pp. 99–106 / report pp. D-3…D-12), transcribed into `src/mrp_appd.jl`:

| Eq. | Role | Implementation |
|---|---|---|
| (D.2)–(D.3) | Axial `sin(Mπx/L)`; circ. `cos/sin nθ` (θ from bottom) | Trial fields per `(M, n)` and floor `(M, p)` |
| (D.4) / (D.17) | Rigid junction: `u_s=u_p`, `w_s sinθ₁+v_s cosθ₁=v_p`, `w_s cosθ₁−v_s sinθ₁=w_p`, rotation continuity | Constraint matrix `C q = 0` |
| (D.18)–(D.21) | Partition / eliminate dependent DOFs via `[E]` | SVD nullspace of `C` (≡ columns of `[E]`) |
| (D.22) | `[K]{q₁}=ω²[M]{q₁}` | `eigen(Symmetric(Kr), Symmetric(Mr))` |
| (D.23)–(D.24) | Constitutive with `k_xs`, `k_θR`, `D_xs`, `D_θR` | Smeared areas/inertias; asterisk (`*`) terms **omitted** |
| (D.25) + p. D-10 | Shell operator; thickness rule | Membrane `k` from `t_eq`; bending off-diag from `D(t_eq)`; third diagonal `D_xs`, `D_θR` from actual-skin `D` + `EI/d`, `EI/ℓ` |
| (D.26)–(D.29) | Mode shapes `ψ` | `C_n ≡ W_Mn`; `shell_circumferential` applies `Σ C (−1)^n cos/sin` |
| (D.31) | Generalized mass `∫ ρ (u²+v²+w²) dA` | Rayleigh `qᵀ M q` after peak-normalisation (p. D-10: max \|w\| = 1) |

## Readings decided (before Table D-1 run)

From `APPD_READINGS` / printed text:

| Reading | Decision | Why |
|---|---|---|
| Attachment | `:rigid` (all four of D.4) | App. E p. E-3 floor “bolt to skin”; hinged would drop the rotation line (p. D-4) |
| Asterisk terms in (D.23) | omitted | p. D-8: vanish when stiffener eccentricities `z_s`, `z_r` are zero (Mikulas comparison); App. D smearing does not re-introduce them |
| (D.25) thickness rule | `:page_D10` | Membrane from `t_eq`; third-diagonal `D_xs`/`D_θR` from actual skin + (D.24) |
| θ origin | bottom centerline | (D.3)/(D.26); junctions at ±θ₀ |
| Length | **1.83 m** | App. E p. E-1 prints 1.83 m (72 in.); program/`mrp.jl` uses 1.803 — **text wins** (spec) |
| Material | `MRP_E_2024`, `MRP_NU_2024`, `MRP_RHO_2024` | App. E “2024-T3 aluminum”; E, ν, ρ from Manual §5.2 / existing constants (no separate printed E in App. D) |
| Constraint reduction | nullspace of `C` | Equivalent to (D.20) after independent/dependent partition |
| Arc coupling n↔n′ | omitted (diagonal only) | Leading Peterson diagonal; junction coupling via (D.17) only |

## Inputs (test article)

| Quantity | Value | Source |
|---|---|---|
| L | 1.83 m | App. E p. E-1 |
| a | 0.508 m | App. E Fig. E-2 (diameter 1.016 m) |
| θ₀ | 56.6° | App. E p. E-3 |
| t_skin | 0.00081 m | App. E p. E-1 / `MRP_T_SKIN` |
| A_stringer, d, I | `MRP_A_STRINGER`, `MRP_D_STRINGER`, `MRP_I_STRINGER` | App. E dimensions → existing constants |
| A_frame, ℓ, I | `MRP_A_FRAME`, `MRP_ELL_FRAME` (0.2 m), `MRP_I_FRAME` | App. E p. E-1 |
| Floor beams | `MRP_A_FLOOR_BEAM`, `MRP_I_FLOOR_BEAM` | App. E Fig. E-2 |
| E, ν, ρ | 73.1e9 Pa, 0.33, 2780 kg/m³ | Manual §5.2 / `MRP_*` |

Solver call for this run: `appd_modes(g; n_modes=48, n_axial=7, n_circ=8, n_floor_max=5)`. Default production path unchanged (`structural_solver=:table_d1`).

## V-UNIT (before this comparison)

Filtered `Pkg.test("PAIN"; test_args=["App. D structural solver 38g", "Validation case registry"])`:

1. Unstiffened closed cylinder vs Donnell–Mushtari / Soedel–Leissa SP-288 §2.1.2 (condensed App. D 3×3 within **1 %**; full 3×3 within **15 %**).
2. Stiffeners raise frequency; smeared analytic (D_xs + t_eq) within **15 %**; large-radius limit lowers frequency.
3. Generalized-mass consistency (w-shape integral vs Rayleigh M_r band) and mass-matrix orthogonality ≤ **1e-8**.
4. Constraint residuals (D.17) ≤ **1e-8**.
5. Surrogate / Table D-1 default path unchanged (`MRP_RITZ` match count ≥ 25; `build_structural_modes(...; :table_d1)` identical to D-1).

**Result: 43 / 43 V-UNIT pass; registry 1210 pass.**

## Table D-1 comparison (once, after V-UNIT)

Greedy nearest-frequency match (`match_ritz_to_table_d1`; same helper as `MRP_RITZ`).

| D-1 # | NASA f [Hz] | App. D f [Hz] | Δ % | within 5 %? |
|------:|------------:|--------------:|----:|:-----------:|
| 1 | 188.52 | 197.11 | +4.56 | yes |
| 2 | 208.24 | 207.05 | −0.57 | yes |
| 3 | 217.88 | 214.38 | −1.61 | yes |
| 4 | 231.01 | 225.24 | −2.50 | yes |
| 5 | 293.25 | 292.43 | −0.28 | yes |
| 6 | 301.93 | 287.33 | −4.83 | yes |
| 7 | 303.67 | 316.75 | +4.31 | yes |
| 8 | 318.73 | 341.25 | +7.07 | **no** |
| 9 | 346.71 | 344.48 | −0.64 | yes |
| 10 | 434.31 | 437.81 | +0.81 | yes |
| 11 | 441.78 | 441.72 | −0.01 | yes |
| 12 | 470.53 | 480.13 | +2.04 | yes |
| 13 | 502.23 | 493.76 | −1.69 | yes |
| 14 | 528.78 | 528.16 | −0.12 | yes |
| 15 | 555.05 | 567.35 | +2.22 | yes |
| 16 | 558.43 | 570.82 | +2.22 | yes |
| 17 | 560.65 | 576.62 | +2.85 | yes |
| 18 | 572.86 | 586.14 | +2.32 | yes |
| 19 | 591.88 | 602.22 | +1.75 | yes |
| 20 | 607.50 | 610.03 | +0.42 | yes |
| 21 | 626.01 | 621.97 | −0.64 | yes |
| 22 | 632.02 | 631.78 | −0.04 | yes |
| 23 | 636.15 | 652.22 | +2.53 | yes |
| 24 | 641.20 | 663.41 | +3.46 | yes |
| 25 | 648.70 | 675.49 | +4.13 | yes |
| 26 | 663.30 | 681.96 | +2.81 | yes |
| 27 | 716.23 | 696.80 | −2.71 | yes |
| 28 | 717.33 | 686.47 | −4.30 | yes |
| 29 | 738.44 | 524.99 | −28.91 | **no** |
| 30 | 761.91 | 519.31 | −31.84 | **no** |
| 31 | 779.76 | 487.83 | −37.44 | **no** |
| 32 | 811.04 | 452.90 | −44.16 | **no** |

**Count: 27 / 32 within 5 % → `:met`.**

Misses: mode 8 (+7.07 %); modes 29–32 (greedy match attached lower computed frequencies — recorded, not retuned).

## Fig. D-2 mode 1 (no pass mark)

Digitized CSV `data/cr3813/fig_d2_mode1_digitized.csv` (floor index → x = i·L_p/20; shell row k → θ = 5k°). Compared to the App. D mode matched to D-1 mode 1. **max |Δw| = 1.4534** over 49 points — reported only; not part of the verdict.

## Code / registry

- `src/mrp_appd.jl` — `appd_modes`, `build_structural_modes(...; structural_solver=:appd)`
- Case `MRP_APPD` in `validation_case_extras.jl`
- `mrp.jl` defaults untouched; production remains Table D-1

No change after seeing this comparison.
