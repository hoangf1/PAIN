# Phase 38c — CR-3813 §3.3 high-frequency broadband Eqs. (19)–(23) (first run)

Criterion for T2: unchanged from `IMPLEMENTATION_PLAN.md` / `VALIDATION_GUIDELINE.md` (±3.5 dB, 1.25–2 kHz vs Fig. E-9), dated before this run. No parameter (including any scale on j², τ, A_t, S, A′) chosen from Fig. E-9, E-21 or E-22. Label: **V-EXP; printed Eq. (19)–(23), first run 2026-10-22; T2 criterion unchanged**.

## Equations as implemented

Source pages: `docs/specs/cr3813_pages/cr3813_pdf033.png`–`pdf036.png` (printed pp. 23–26). Code: `src/hf_broadband.jl`.

| Symbol / equation | Implementation | Reading / decision |
|---|---|---|
| Band width \(c_\omega=0.232\) | `C_OMEGA_THIRD_OCTAVE` | CR-3813 p. 10; same as 38a/38b |
| Modes in \(\Delta\omega\) | Resonance in \([\omega(1\pm c_\omega/2)]\) | Notation “\(r<\Delta\omega\)” / text “resonant below the band” read as modes **in** the band (parallel to \(n\in\Delta\omega\); same as `modes_in_tone_band`) |
| Sparse Table D-1 (\(f\gtrsim 811\,\mathrm{Hz}\)) | Asymptotic `structural_modal_density`; \(\langle j^2\rangle\) = mean of `structural_joint_acceptance(st,ω)` over all retained modes at band-centre \(\omega\); \(\sum[j^2]^2=N_\mathrm{eff}\langle(j^2)^2\rangle\), \(N_\mathrm{eff}=n_r\Delta\omega\) | Not fitted to E-9 |
| \(A_t\), \(A'\) | Trim: \(A_t=\)`coupling_area`, \(A'=0\). Bare: \(A_t=0\), \(A'=\)`coupling_area` | Phase III all transmitting surface trimmed; same \(A\) as Eqs. 8/17/52 |
| \(S\) (absorbing) | \(S_\mathrm{side}+2S_e\), \(S_\mathrm{side}=2a(\pi-\theta_0)L\), \(S_e=V/L\) | Same as E-13 / Eq. (24) script |
| \(\bar A\) | `cylinder_surface_area` \(=2\pi a L\) | Eq. (81) / p. 21 |
| \(\bar\alpha\) Eq. (24) | `absorption_from_loss_factor` from \(\bar\eta_n\) | Trim: Eq. (78) `acoustic_loss_average`; bare: \(\eta_{n,\mathrm{bare}}\). Surrogate `absorption_coefficient` **not** used on `:eq19` |
| \(\tau_t\) | `sidewall_tau` Eq. (A.22) | Applies to Eqs. 16, 18, 23 |
| \(j_r^2(\omega)^\mathrm{rev}\) | `structural_joint_acceptance` | §3.6; 16b |
| \(\eta_\mathrm{rad}^\mathrm{ext/int}\) | Eq. (81) form after Eq. (19): \(2\rho\omega\bar A\langle j^2\rangle/(\pi m c_0)\) | \(\rho=\rho_0\) (single air density in `PainInputs`) |
| \(\bar\eta_r\) | \(\langle\eta_\mathrm{rad}^\mathrm{ext}\rangle+\langle\eta_r'\rangle\) | \(\eta_r''\) omitted (pair-dependent; same as 38b §3) |
| \(\tau_f\) Eq. (20) | \((32/\pi)\rho^2(\bar A/m^2)\sum[j_r^2]^2\) | As printed |
| \(\tau_R\) (p. 24) | \((2 n_r \pi^2 c_0\eta_\mathrm{rad}^\mathrm{ext}\eta_\mathrm{rad}^\mathrm{int})/(\rho_0\omega\bar\eta_r)\cdot(4\rho c_0/\bar A)\) | As transcribed from p. 24 |
| \(\tau=\tau_f+\tau_R\); Eq. (23) | `hf_pressure_ratio` | NR \(=10\log_{10}(\langle p_e^2\rangle/\langle p_i^2\rangle)\) |
| \(\langle p_e^2\rangle=\langle p_{bl}^2\rangle/2\) | `hf_broadband_band_p2` | p. 23 |
| Exterior continuum | `blocked_broadband_band_p2` (Spbl \(\propto f^{-\alpha}\), H=3 anchor) | Unchanged V-ASSUMED input; only cabin transmission is printed |
| Selector | `interior_spl(...; broadband_model=:surrogate\|:eq19)` | Default `:surrogate` unchanged (keeps `bb_j2_scale`) |

## Tests run (V-UNIT before comparison)

Filtered `Pkg.test("PAIN"; test_args=["HF broadband Eqs", "Validation case registry"])`:

1. Closed-form Eq. (20)–(23) stack (hand values) — pass  
2. \(\bar\eta_r\to\infty\Rightarrow\tau_R\to 0\); \(p^2\) positive finite on 1–4 kHz 1/3-octaves — pass  
3. Default `:surrogate` reproduces current T2 / pipeline spectrum exactly — pass  
4. `T2_EQ19` case runs; table/series non-empty — pass  
5. Validation case registry (includes `T2_EQ19` CASE_INFO / map block) — pass  

## T2 vs Fig. E-9 (printed Eq. 19–23)

Inputs: e11 free-field, R2 blocking, Phase III trim (\(\eta_T=0.5\)), `broadband_model=:eq19`. Same targets CSV and ±3.5 dB as T2.

| band Hz | measured mean | got (Eq. 19) | Δ (dB) | \|Δ\| ≤ 3.5? |
|--------:|-------------:|-------------:|-------:|:-----------:|
| 1250 | 51.0 | 38.59 | −12.41 | no |
| 1600 | 46.0 | 35.87 | −10.13 | no |
| 2000 | 41.5 | 34.94 | −6.56 | no |

**Count: 0 / 3 PASS. Verdict: `:not_met`.** Recorded, not tuned.

## Full-band E-21 / E-22 (Eq. 18 below crossover; Eq. 19 at/above)

Inputs as NASA p. E-30: Phase III \(\eta_T=1.0\), \(\eta_r'\le 0.15\). Crossover **400 Hz** (unchanged). Bands 80, 100, 125, 160 Hz excluded (end-plate V-ASSUMED). Thresholds dated 2026-10-21 in row 38a (≥75 % \|Δ\|≤3 dB vs NASA; ≥75 % inside E-22); **report only**.

| band Hz | model | NR (dB) | NASA | \|Δ\| | inside E-22? | counted? |
|--------:|:-----:|--------:|-----:|------:|:------------:|:--------:|
| 63 | Eq.18 | 58.55 | 16.0 | 42.55 | no | yes |
| 80 | Eq.18 | 54.31 | 10.5 | 43.81 | no | no |
| 100 | Eq.18 | 49.85 | — | — | no | no |
| 125 | Eq.18 | 45.03 | 23.5 | 21.53 | no | no |
| 160 | Eq.18 | 34.50 | 27.5 | 7.00 | no | no |
| 200 | Eq.18 | 23.05 | 24.5 | 1.45 | no | yes |
| 250 | Eq.18 | 20.83 | 27.0 | 6.17 | no | yes |
| 315 | Eq.18 | 14.06 | 23.5 | 9.44 | no | yes |
| 400 | Eq.19 | 100.66 | 21.5 | 79.16 | no | yes |
| 500 | Eq.19 | 27.40 | 16.0 | 11.40 | no | yes |
| 630 | Eq.19 | 37.60 | 13.0 | 24.60 | no | yes |
| 800 | Eq.19 | 42.49 | 17.0 | 25.49 | no | yes |
| 1000 | Eq.19 | 55.10 | 24.5 | 30.60 | no | yes |
| 1250 | Eq.19 | 59.81 | — | — | no | yes |
| 1600 | Eq.19 | 61.63 | 51.5 | 10.13 | no | yes |
| 2000 | Eq.19 | 62.43 | 59.0 | 3.43 | no | yes |
| 2500 | Eq.19 | 63.36 | 68.5 | 5.14 | no | yes |
| 3150 | Eq.19 | 64.63 | 68.5 | 3.87 | no | yes |
| 4000 | Eq.19 | 66.03 | — | — | no | yes |
| 5000 | Eq.19 | 67.39 | — | — | no | yes |

| Check | Count | Threshold | Result |
|---|---|---|---|
| V-CODE \|NR − NASA\| ≤ 3 dB (excl. 80–160; with NASA value) | **1 / 13** (200 Hz) | ≥ 75 % | not met |
| V-EXP inside E-22 95 % (same exclusions) | **0 / 15** | ≥ 75 % | not met |

**Full-band verdict (report only): not met.** Observation (not acted on): at the crossover band (400 Hz) Eq. (19) NR jumps to ~101 dB (very small \(\tau\)); not tuned.

## Code

- `src/hf_broadband.jl` (new): Eqs. (19)–(23), `hf_broadband_band_p2`, helpers  
- `interior_spl(...; broadband_model=:surrogate|:eq19)` — default `:surrogate` unchanged  
- `noise_reduction_band` / `noise_reduction_spectrum(...; hf_model=:none|:eq19)`  
- Case `T2_EQ19` in the registry  

No change after seeing the comparison.
