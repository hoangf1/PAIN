# Uncertainty budget — test article (phase 31a/31b/31e)

**Phase 31. Pre-registration fixed 2026-10-22 (before this run).**

## Required statements (31f)

These statements apply to the aircraft band (`uncertainty_aircraft_band.md`); this report is the 31e coverage check on the NASA test article (diameter 1.016 m, NASA free field).

- The band is epistemic and not a confidence interval.
- The band excludes scattering and refraction (V-ASSUMED).
- The band is conditional on the transferability allowance.
- Every cabin input except the 2.64 m diameter is assumed.
- The result is not validated and is not NASA's accuracy.
- Report median and percentiles, never the mean; no single dB value without the band.
- Phase is the dominant uncertainty when its bounding-case spread exceeds the Monte Carlo P5–P95 width.

Do not quote the +2.6 to +4.3 dB flight bias or "10 dB" as an error bar for this aircraft.

## Budget table (31a)

| Parameter | Nominal | Range / alternatives | Type | Provenance | Basis |
|-----------|--------:|----------------------|------|------------|-------|
| eta_t | 0.05 | 0.01–0.1 | continuous | assumed | 13a f / plan phase-31 table: lining/facing flexural loss factor (Eq. A.11); aircraft register default 0.05, range 0.01–0.10 |
| C_struc | 3.0 | 2.0–4.0 | continuous | assumed | 13a g / CR-3813 §3.8.2: C of Eq. (80), η_r^struc = C/f_r; range 2–4 |
| eta_n_bare | 0.05 | not registered: excluded | excluded | excluded | 13a g: bare η_n — trimmed path → not applicable |
| freq_scale | 1.0 | 0.95–1.05 | continuous | assumed | flowchart 5 % structural-frequency tolerance: one common scale factor on all mode frequencies |
| cyl2d_node_tol | 0.4 | 0.32h, 0.40h, 0.47h | discrete | assumed | 13a a: CYL2D node rule r ≤ 1 + α·h; 0.32h–0.47h gives the same paper grid (15a) |
| q_max_delta | 0.0 | q_default, q_default+2 | discrete | assumed | 13a d: axial truncation q ≤ ⌈2ω_H L/(π c0)⌉; alternatives default and default+2 (convergence check) |
| blocking | 2.0 | R1, R2 | discrete | assumed | Blocking revision R1 vs R2 (Eq. 43); discrete equiprobable |
| facing_side | 0.0 | cabin, skin | discrete | assumed | 13a f: facing side of each layer — cabin side (0) or skin side (1) |
| mech_conn | 0.0 | points+lines, points, lines | discrete | assumed | 13a f: mechanical connections — 9 points + 2 lines (0), points only (1), lines only (2) |
| G10_wavespeed | 3200.0 | 2800, 3200, 3600 | discrete | assumed | 13a f: G-10 wavespeed 2800–3600 m/s (discrete ends + nominal for sampling) |
| allow_extrapolation | 0.0 | no_ext, X-EXTRAP | discrete | assumed | 13a e: insulation-table extension X-EXTRAP only if the table does not cover a harmonic (flag) |
| scattering_refraction | — | not registered: excluded | excluded | excluded | Scattering and refraction: V-ASSUMED condition; no range invented (31c) |

- Pre-registered 2026-10-22 before any phase-31 run (spec phase31_uncertainty.md).
- Ranges from VALIDATION_GUIDELINE §2.11 / IMPLEMENTATION_PLAN phase 31 loss-factor table.
- Source-side residuals of phases 24–28 apply to the aircraft run only; coverage check uses NASA free field.
- eta_n_bare excluded: cabin is trimmed (Phase III / user trim).
- Source-side residuals of phases 24–28 do not apply to the test-article coverage check.
- NASA's Phase III value η_T = 0.5 (CR-3813 p. E-24, `phase3_trim` default) lies outside the registered 0.01–0.10 range; the pre-registered range is used unchanged.
- Scattering/refraction: V-ASSUMED; no range invented.

## OAT ranking (31b)

Keep if swing in any of H1–H3 exceeds 3.0 dB; others fixed at nominal in 31d.

| Parameter | Swing H1 [dB] | Swing H2 [dB] | Swing H3 [dB] | Max | Keep? |
|-----------|--------------:|--------------:|--------------:|----:|:-----:|
| freq_scale | 1.52 | 5.62 | 1.86 | 5.62 | yes |
| eta_t | 1.49 | 1.53 | 4.86 | 4.86 | yes |
| facing_side | 2.18 | 1.49 | 0.09 | 2.18 | no |
| blocking | 1.52 | 2.1 | 1.45 | 2.1 | no |
| mech_conn | 0.02 | 0.12 | 1.14 | 1.14 | no |
| C_struc | 0.01 | 0.11 | 0.0 | 0.11 | no |
| G10_wavespeed | 0.0 | 0.01 | 0.08 | 0.08 | no |
| q_max_delta | 0.0 | 0.0 | 0.0 | 0.0 | no |
| cyl2d_node_tol | 0.0 | 0.0 | 0.0 | 0.0 | no |
| allow_extrapolation | 0.0 | 0.0 | 0.0 | 0.0 | no |

## Monte Carlo — uniform (primary) (N=4000, seed=20261022)

Kept parameters: freq_scale, eta_t.

| Harmonic | P5 [dB] | P50 [dB] | P95 [dB] | width P95−P5 |
|----------|--------:|---------:|---------:|-------------:|
| H1 | 88.95 | 89.87 | 91.06 | 2.11 |
| H2 | 85.46 | 91.3 | 92.86 | 7.39 |
| H3 | 73.09 | 74.78 | 77.59 | 4.5 |

### 1/3-octave bands (P5 / P50 / P95)

| fc [Hz] | P5 | P50 | P95 |
|--------:|---:|----:|----:|
| 62 | — | — | — |
| 79 | — | — | — |
| 99 | — | — | — |
| 125 | — | — | — |
| 157 | — | — | — |
| 198 | 88.95 | 89.87 | 91.06 |
| 250 | — | — | — |
| 315 | — | — | — |
| 397 | 85.46 | 91.3 | 92.86 |
| 500 | — | — | — |
| 630 | 73.09 | 74.78 | 77.59 |
| 794 | — | — | — |
| 1000 | 56.13 | 58.26 | 63.15 |
| 1260 | 42.93 | 44.77 | 49.69 |
| 1587 | 41.52 | 43.71 | 49.08 |
| 2000 | 43.31 | 45.98 | 51.93 |
| 2520 | 42.71 | 45.52 | 51.67 |
| 3175 | 41.19 | 44.11 | 50.46 |
| 4000 | 39.38 | 42.41 | 48.95 |
| 5040 | 37.4 | 40.52 | 47.26 |

Values below −200 dB (no energy in that band) are shown as —.

### Spearman rank correlations (parameter vs H1–H3)

| Parameter | ρ(H1) | ρ(H2) | ρ(H3) |
|-----------|------:|------:|------:|
| freq_scale | -0.698 | 0.441 | 0.429 |
| eta_t | -0.663 | -0.349 | -0.899 |

## Monte Carlo — triangular (mode = nominal) (N=4000, seed=20261022)

Kept parameters: freq_scale, eta_t.

| Harmonic | P5 [dB] | P50 [dB] | P95 [dB] | width P95−P5 |
|----------|--------:|---------:|---------:|-------------:|
| H1 | 89.16 | 89.81 | 90.65 | 1.49 |
| H2 | 86.82 | 91.94 | 92.81 | 6.0 |
| H3 | 73.56 | 74.82 | 76.56 | 3.0 |

### 1/3-octave bands (P5 / P50 / P95)

| fc [Hz] | P5 | P50 | P95 |
|--------:|---:|----:|----:|
| 62 | — | — | — |
| 79 | — | — | — |
| 99 | — | — | — |
| 125 | — | — | — |
| 157 | — | — | — |
| 198 | 89.16 | 89.81 | 90.65 |
| 250 | — | — | — |
| 315 | — | — | — |
| 397 | 86.82 | 91.94 | 92.81 |
| 500 | — | — | — |
| 630 | 73.56 | 74.82 | 76.56 |
| 794 | — | — | — |
| 1000 | 56.62 | 58.51 | 61.55 |
| 1260 | 43.33 | 45.01 | 48.04 |
| 1587 | 42.0 | 43.97 | 47.32 |
| 2000 | 43.92 | 46.27 | 50.03 |
| 2520 | 43.35 | 45.82 | 49.71 |
| 3175 | 41.85 | 44.42 | 48.44 |
| 4000 | 40.07 | 42.73 | 46.88 |
| 5040 | 38.1 | 40.85 | 45.12 |

Values below −200 dB (no energy in that band) are shown as —.

### Spearman rank correlations (parameter vs H1–H3)

| Parameter | ρ(H1) | ρ(H2) | ρ(H3) |
|-----------|------:|------:|------:|
| freq_scale | -0.697 | 0.278 | 0.442 |
| eta_t | -0.664 | -0.398 | -0.891 |

## Distribution-family sensitivity

| Harmonic | ΔP5 (tri−uni) | ΔP50 | ΔP95 |
|----------|-------------:|-----:|-----:|
| H1 | 0.2 | -0.06 | -0.41 |
| H2 | 1.35 | 0.64 | -0.05 |
| H3 | 0.47 | 0.04 | -1.03 |

## 31e coverage check (test article, untuned parametric, NASA free field)

Criterion (pre-registered 2026-10-22): P5–P95 of the primary Monte Carlo contains the measured E-16 mean at each of H1, H2, H3. Verdict `:met` only if all three. No E-16 envelope floor; no tuned value; nothing widened on failure.

**Verdict: `not_met`** — V-EXP vs measured E-16 means; first run 2026-10-22; pre-registered

| Harmonic | Measured mean [dB] | P5 | P50 | P95 | Inside? | Margin to nearest edge [dB] |
|----------|-------------------:|---:|----:|----:|:-------:|----------------------------:|
| H1 | 90.0 | 88.95 | 89.87 | 91.06 | yes | 1.05 |
| H2 | 80.0 | 85.46 | 91.3 | 92.86 | no | -5.46 |
| H3 | 65.0 | 73.09 | 74.78 | 77.59 | no | -8.09 |

Failure recorded: the budget is missing a contributor or the ranges are too narrow. Nothing was widened in this run; any later revised ranges are post-hoc and must be labelled so.

## Runtime

Wall time: 783.6 s.

