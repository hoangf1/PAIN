# E-21 / E-22 noise reduction — phase 38a (first run)

Criterion dated **2026-10-21** in `IMPLEMENTATION_PLAN.md` §8 row 38a (before this run). No parameter chosen from E-21/E-22. Label: **V-CODE (vs NASA) / V-EXP held out (vs E-22); first run 2026-10-21**.

## Equations as implemented

Source pages: `docs/specs/cr3813_pages/cr3813_pdf031.png`–`pdf033.png` (printed pp. 21–23), checked against the 38a spec transcription.

| Symbol / equation | Implementation | Reading / decision |
|---|---|---|
| \(c_\omega = 0.232\) | `C_OMEGA_THIRD_OCTAVE` | CR-3813 p. 10, 1/3-octaves |
| \(b_j, c_j, \ln_j, \arctan_j, D_{nr}, \{\ldots\}_{nr}\) | `nr_b`, `nr_c`, `nr_ln`, `nr_arctan`, `nr_D`, `nr_brace` | As printed p. 22 |
| Band integral of resonance product | `nr_band_integral_closed` = \(\{\ldots\}_{nr}/D_{nr}\) = \(\int_{\omega(1-c_\omega/2)}^{\omega(1+c_\omega/2)} \omega'^3/[\mathrm{poly}_n\mathrm{poly}_r]\,d\omega'\) | Derived from Eqs. 5–7/17; V-UNIT vs quadrature to 1e-6 |
| Eq. (17) \(W_\mathrm{in}\) | `w_in_reverberant` | Prefactor \(\langle p_{bl}^2\rangle/(c_\omega\omega)\cdot(2\pi\bar A^2)/(\rho V)\cdot(mA/4)^2\tau_{ML}\); curly \((2/\pi)\omega^2\omega_n^2/D_{nr}\cdot\{\ldots\}_{nr}\). No free \(\eta_n\) outside the brace (as printed; tone Eq. 7 carries \(\eta_n/\omega_n^2\)). |
| Eq. (18) \(\langle p_i^2\rangle/\langle p_e^2\rangle\) | `noise_reduction_band` | Prefactor \(8/(c_\omega\omega)\cdot\bar A^2/V^2\cdot(mA/4)^2\tau_{ML}\,c_0^2\,\omega^3\); sum over all \(n=(q,i)\) and Table D-1 \(r\) |
| \((mA/4)^2\tau_{ML}\) | `mass_law_factor` = \((\rho_0 c_0 A/(2\omega))^2\) | Phase 19b identity; reused |
| \(\bar A\) | `cylinder_surface_area` = \(2\pi a L\) | Complete cylinder (p. 21 / Eq. 81 usage) |
| \(A\) | `coupling_area` = \(L(L_p+2a(\pi-\theta_0))\) | Same as tone path |
| \(\bar f'(n,r)\) | `coupling_factor` (barred, \(\sqrt{\tau_t}\) on shell) | Printed Eq. 18 uses barred form; same function as Eq. 8. (19g/bisect: unbarred \(f'\) in Eq. 83 was a diagnostic only — not used here.) |
| \(j_r^2(\omega)^\mathrm{rev}\) | `structural_joint_acceptance` | Diffuse \(\sin(k\xi)/(k\xi)\), §3.6; checked vs quadrature in 16b |
| \(\langle p_e^2\rangle=\langle p_{bl}^2\rangle/2\) | NR = \(-10\log_{10}\)(Eq. 18) | p. 23 |
| \(\eta_n\) | Eq. (77) with Phase III trim at band centre | As tone path |
| \(\eta_r'\) | Eq. (82) at \(\omega_r\), optional `η_r_cap` | Default `nothing` = no cap (tone unchanged); E-21 uses `0.15` (p. E-30) |
| \(\eta_r''\) | Eq. (83) with barred \(f'\) | As printed |
| End-plate allowance [7] | Not applied | 80–160 Hz reported, excluded from both pass counts (V-ASSUMED) |
| Crossover | `acoustic_crossover_band`: lowest 1/3-oct with ≥10 3-D acoustic modes in-band | 38b rule, fixed before run; Eq. 18 above it marked “above crossover” |

**Eq. (17) ↔ Eq. (18) link.** Algebraically, printed Eq. (18)’s one-term contribution equals \(W_\mathrm{in}\) (Eq. 17) converted by \(\langle p_n^2\rangle = W_\mathrm{in}\,\rho c_0^2\omega/(V\omega_n^2)\) and \(\langle p_e^2\rangle=\langle p_{bl}^2\rangle/2\). That conversion omits Eq. (5)’s free \(\eta_n\) because printed Eq. (17) also omits the free \(\eta_n/\omega_n^2\) that tone Eq. (7) carries; the V-UNIT check uses this printed-form link (rtol 1e-9).

**Insulation table.** Fig. A-2 starts at 100 Hz; E-21 includes 63 Hz. `allow_extrapolation=true` on the NR test-article inputs (X-EXTRAP for the table outside 100–6300 Hz).

## Inputs (NASA p. E-30)

- Geometry: Phase III test article (\(a=0.508\), \(L=1.803\), \(\theta_0=56.6^\circ\))
- Trim: `phase3_trim(; η_lining=1.0)`, `η_r_cap=0.15`
- Modes: CYL2D 20 cross-section × \(q\le q_\max\) (upper band edge); Table D-1, 32 structural

## Crossover band

**400 Hz** (12 three-dimensional acoustic modes in-band). Bands at and above 400 Hz are reported but excluded from the 38a counts (high-frequency model needed — 38c).

## Per-band NR (dB)

| band Hz | Eq.(18) | NASA (E-21) | \|Δ\| | E-22 95% lo–hi | inside E-22? | counted in 38a? |
|--------:|--------:|------------:|-----:|----------------|:--------------:|:---------------:|
| 63 | 58.55 | 16.0 | 42.55 | 11.0–14.0 | no | yes |
| 80 | 54.31 | 10.5 | 43.81 | 12.5–14.5 | no | no (end-plate) |
| 100 | 49.85 | — | — | 13.0–15.0 | no | no (end-plate) |
| 125 | 45.03 | 23.5 | 21.53 | 22.5–24.5 | no | no (end-plate) |
| 160 | 34.50 | 27.5 | 7.00 | 14.5–16.5 | no | no (end-plate) |
| 200 | 23.05 | 24.5 | 1.45 | 13.5–16.0 | no | yes |
| 250 | 20.83 | 27.0 | 6.17 | 13.0–15.0 | no | yes |
| 315 | 14.06 | 23.5 | 9.44 | 16.5–18.5 | no | yes |
| 400 | 19.70 | 21.5 | 1.80 | 17.0–19.0 | no | no (crossover+) |
| 500 | 14.97 | 16.0 | 1.03 | 18.5–20.5 | no | no (crossover+) |
| 630 | 14.66 | 13.0 | 1.66 | 18.0–20.5 | no | no (crossover+) |
| 800 | 23.23 | 17.0 | 6.23 | 19.0–21.5 | no | no (crossover+) |
| 1000 | 42.26 | 24.5 | 17.76 | 19.5–21.5 | no | no (crossover+) |
| ≥1250 | … | … | large | … | no | no (crossover+; HF model) |

## Counts and verdict

| Check | Count | Threshold | Result |
|---|---|---|---|
| V-CODE \|NR − NASA\| ≤ 3 dB (below crossover, excl. 80–160, with NASA value) | **1 / 4** (200 Hz) | ≥ 75 % | not met |
| V-EXP inside E-22 95 % (same bands) | **0 / 4** | ≥ 75 % | not met |
| E-21 min–max range (secondary) | 2 / 4 | reported only | — |

**Verdict: `:not_met`.** Reason string: V-CODE 1/4; V-EXP 0/4; crossover = 400 Hz; excluded 80, 100, 125, 160 Hz.

No change after seeing the comparison. Misses at 63 Hz are consistent with the missing end-plate allowance (V-ASSUMED). Misses above the crossover await the printed high-frequency model (38c).

## Code / tests

- `src/noise_reduction.jl` (new); `η_r_cap` on `structural_loss_with_trim` / `tone_mean_square_pressure`
- Case `E21_E22_NR` runnable in `validation_case_extras.jl`
- Testset `Noise reduction Eqs. (17)–(18) (38a)` + Validation case registry (filtered `Pkg.test`)
