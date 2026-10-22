# Uncertainty aircraft band (phase 31c/31d) — working example 2.64 m diameter

**Phase 31. Pre-registration fixed 2026-10-22 (before this run).**

## Required statements (31f)

- The band is epistemic and not a confidence interval.
- The band excludes scattering and refraction (V-ASSUMED).
- The band is conditional on the transferability allowance.
- Every cabin input except the 2.64 m diameter is assumed.
- The result is not validated and is not NASA's accuracy.
- Report median and percentiles, never the mean; no single dB value without the band.
- Phase is the dominant uncertainty when its bounding-case spread exceeds the Monte Carlo P5–P95 width.

Do not quote the +2.6 to +4.3 dB flight bias or "10 dB" as an error bar for this aircraft.

Cabin inputs tagged assumed (working example; only the 2.64 m diameter is given as measured geometry): L_m, theta0_deg, r_p_m, phi_p_deg, z_p_m, L_c_m, d_m, rotation_direction, rho_kg_m3, c0_mps, eta_n_bare, C_struc, m_wall_kg_m2, NY, bb_alpha, spbl_anchor_H, structural_solver, broadband_model, cabin_blocks, trim, t_skin_m, t_floor_m, A_stringer_m2, d_stringer_m, I_stringer_m4, A_frame_m2, ell_frame_m, I_frame_m4, A_floor_beam_m2, I_floor_beam_m4, E_Pa, nu, rho_struc_kg_m3.

## Budget table (31a)

| Parameter | Nominal | Range / alternatives | Type | Provenance | Basis |
|-----------|--------:|----------------------|------|------------|-------|
| eta_t | 0.05 | not registered: excluded | excluded | excluded | 13a f: lining/facing loss factor — cabin is bare on this path → not applicable |
| C_struc | 3.0 | 2.0–4.0 | continuous | assumed | 13a g / CR-3813 §3.8.2: C of Eq. (80), η_r^struc = C/f_r; range 2–4 |
| eta_n_bare | 0.05 | 0.02–0.1 | continuous | assumed | 13a g: bare-cabin η_n (measured in CR-3813; assumed here); only when untrimmed |
| freq_scale | 1.0 | 0.95–1.05 | continuous | assumed | flowchart 5 % structural-frequency tolerance: one common scale factor on all mode frequencies |
| cyl2d_node_tol | 0.4 | 0.32h, 0.40h, 0.47h | discrete | assumed | 13a a: CYL2D node rule r ≤ 1 + α·h; 0.32h–0.47h gives the same paper grid (15a) |
| q_max_delta | 0.0 | q_default, q_default+2 | discrete | assumed | 13a d: axial truncation q ≤ ⌈2ω_H L/(π c0)⌉; alternatives default and default+2 (convergence check) |
| blocking | 2.0 | R1, R2 | discrete | assumed | Blocking revision R1 vs R2 (Eq. 43); discrete equiprobable |
| facing_side | — | not registered: excluded | excluded | excluded | 13a f trim alternatives — not applicable on bare cabin |
| mech_conn | — | not registered: excluded | excluded | excluded | 13a f trim alternatives — not applicable on bare cabin |
| G10_wavespeed | — | not registered: excluded | excluded | excluded | 13a f G-10 wavespeed — not applicable on bare cabin |
| allow_extrapolation | — | not registered: excluded | excluded | excluded | 13a e insulation extension — not applicable on bare cabin (no insulation table) |
| source_amp_residual | — | not registered: excluded | excluded | excluded | phases 24–28 amplitude residual — not registered: excluded (no range in §2.11) |
| source_polar_bracket | — | not registered: excluded | excluded | excluded | Pereira polar bracket — not registered: excluded (no continuous range in §2.11 for the aircraft budget) |
| pereira_1p7_dB | — | not registered: excluded | excluded | excluded | Pereira ±1.7 dB measurement uncertainty — not registered as a sampled range: excluded from MC; stated as evidence only |
| phase_bbn_residual | — | bounding case only | bounding | assumed | BBN H1 residual gradient ratio — bounding case only (31c), not Monte-Carlo sampled |
| scattering_refraction | — | not registered: excluded | excluded | excluded | Scattering and refraction: V-ASSUMED condition; no range invented (31c) |

- Pre-registered 2026-10-22 before any phase-31 run (spec phase31_uncertainty.md).
- Ranges from VALIDATION_GUIDELINE §2.11 / IMPLEMENTATION_PLAN phase 31 loss-factor table.
- Source-side residuals of phases 24–28 apply to the aircraft run only; coverage check uses NASA free field.
- eta_t excluded: cabin untrimmed (bare); lining loss factor does not enter.
- Trim-stack / insulation rows excluded: cabin is bare.
- Source residuals: amplitude/polar/Pereira ±1.7 dB marked not registered: excluded; phase via 31c bounding cases.
- Scattering/refraction: V-ASSUMED; no range invented.

## OAT ranking (31b)

Keep if swing in any of H1–H3 exceeds 3.0 dB; others fixed at nominal in 31d.

| Parameter | Swing H1 [dB] | Swing H2 [dB] | Swing H3 [dB] | Max | Keep? |
|-----------|--------------:|--------------:|--------------:|----:|:-----:|
| eta_n_bare | 5.47 | 1.68 | 0.98 | 5.47 | yes |
| freq_scale | 2.93 | 0.32 | 0.16 | 2.93 | no |
| blocking | 2.0 | 1.79 | 1.95 | 2.0 | no |
| C_struc | 0.49 | 0.0 | 0.0 | 0.49 | no |
| q_max_delta | 0.0 | 0.0 | 0.0 | 0.0 | no |
| cyl2d_node_tol | 0.0 | 0.0 | 0.0 | 0.0 | no |

## Monte Carlo — uniform (primary) (N=4000, seed=20261022)

Kept parameters: eta_n_bare.

| Harmonic | P5 [dB] | P50 [dB] | P95 [dB] | width P95−P5 |
|----------|--------:|---------:|---------:|-------------:|
| H1 | 99.31 | 101.41 | 104.21 | 4.9 |
| H2 | 58.47 | 59.07 | 59.94 | 1.46 |
| H3 | 35.45 | 35.65 | 36.26 | 0.81 |

### 1/3-octave bands (P5 / P50 / P95)

| fc [Hz] | P5 | P50 | P95 |
|--------:|---:|----:|----:|
| 62 | — | — | — |
| 79 | — | — | — |
| 99 | — | — | — |
| 125 | — | — | — |
| 157 | — | — | — |
| 198 | 99.31 | 101.41 | 104.21 |
| 250 | — | — | — |
| 315 | — | — | — |
| 397 | 58.47 | 59.07 | 59.94 |
| 500 | — | — | — |
| 630 | 35.45 | 35.65 | 36.26 |
| 794 | — | — | — |
| 1000 | 50.89 | 52.97 | 56.91 |
| 1260 | 47.02 | 49.1 | 53.04 |
| 1587 | 43.12 | 45.2 | 49.15 |
| 2000 | 39.19 | 41.28 | 45.23 |
| 2520 | 35.26 | 37.34 | 41.3 |
| 3175 | 31.3 | 33.39 | 37.34 |
| 4000 | 27.34 | 29.42 | 33.38 |
| 5040 | 23.36 | 25.45 | 29.4 |
| 6350 | 19.38 | 21.46 | 25.42 |
| 8000 | 15.39 | 17.47 | 21.43 |

Values below −200 dB (no energy in that band) are shown as —.

### Spearman rank correlations (parameter vs H1–H3)

| Parameter | ρ(H1) | ρ(H2) | ρ(H3) |
|-----------|------:|------:|------:|
| eta_n_bare | -1.0 | -1.0 | -1.0 |

## Monte Carlo — triangular (mode = nominal) (N=4000, seed=20261022)

Kept parameters: eta_n_bare.

| Harmonic | P5 [dB] | P50 [dB] | P95 [dB] | width P95−P5 |
|----------|--------:|---------:|---------:|-------------:|
| H1 | 99.81 | 101.72 | 103.59 | 3.78 |
| H2 | 58.62 | 59.15 | 59.71 | 1.09 |
| H3 | 35.49 | 35.69 | 36.06 | 0.57 |

### 1/3-octave bands (P5 / P50 / P95)

| fc [Hz] | P5 | P50 | P95 |
|--------:|---:|----:|----:|
| 62 | — | — | — |
| 79 | — | — | — |
| 99 | — | — | — |
| 125 | — | — | — |
| 157 | — | — | — |
| 198 | 99.81 | 101.72 | 103.59 |
| 250 | — | — | — |
| 315 | — | — | — |
| 397 | 58.62 | 59.15 | 59.71 |
| 500 | — | — | — |
| 630 | 35.49 | 35.69 | 36.06 |
| 794 | — | — | — |
| 1000 | 51.36 | 53.31 | 55.81 |
| 1260 | 47.49 | 49.44 | 51.95 |
| 1587 | 43.59 | 45.54 | 48.05 |
| 2000 | 39.67 | 41.62 | 44.13 |
| 2520 | 35.73 | 37.68 | 40.19 |
| 3175 | 31.78 | 33.73 | 36.24 |
| 4000 | 27.81 | 29.76 | 32.27 |
| 5040 | 23.83 | 25.79 | 28.3 |
| 6350 | 19.85 | 21.8 | 24.32 |
| 8000 | 15.86 | 17.82 | 20.33 |

Values below −200 dB (no energy in that band) are shown as —.

### Spearman rank correlations (parameter vs H1–H3)

| Parameter | ρ(H1) | ρ(H2) | ρ(H3) |
|-----------|------:|------:|------:|
| eta_n_bare | -1.0 | -1.0 | -1.0 |

## Distribution-family sensitivity

| Harmonic | ΔP5 (tri−uni) | ΔP50 | ΔP95 |
|----------|-------------:|-----:|-----:|
| H1 | 0.51 | 0.31 | -0.62 |
| H2 | 0.15 | 0.09 | -0.23 |
| H3 | 0.04 | 0.04 | -0.2 |

## Phase bounding cases (31c)

Scattering/refraction: V-ASSUMED; no range invented.

(i) BBN H1 residual expressed as a ratio to the predicted circumferential phase difference, applied per observer as k·H·B·Δψ; defined 2026-10-22 before the aircraft band run.

k (BBN H1 residual/f1a median) = 0.0944; B (blade count) = 3.

Case (ii) fully random phase is the extreme only (seed UNC_MC_SEED); phase-dominance uses case (i).

| Harmonic | Nominal [dB] | (i) BBN residual [dB] | (ii) Random [dB] | Spread (i) vs nom [dB] | Spread (ii) vs nom [dB] |
|----------|-------------:|---------------------:|----------------:|-----------------------:|------------------------:|
| H1 | 102.08 | 101.72 | 97.91 | 0.36 | 4.17 |
| H2 | 59.25 | 58.79 | 56.72 | 0.46 | 2.53 |
| H3 | 35.75 | 35.96 | 34.52 | 0.22 | 1.22 |

### Phase-dominance rule (case (i) bounding)

- H1: case (i) spread 0.36 dB ≤ MC width 4.9 dB → phase does not dominate.
- H2: case (i) spread 0.46 dB ≤ MC width 1.46 dB → phase does not dominate.
- H3: case (i) spread 0.22 dB ≤ MC width 0.81 dB → phase does not dominate.

## Runtime

Wall time: 708.8 s.

