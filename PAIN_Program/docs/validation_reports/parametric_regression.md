# Parametric cabin blocks — test-article regression (phase 30d)

**First run 2026-10-22. Record of the shift, no criterion.**

Compares the current cabin chain (`cabin_blocks=:surrogate`, Table D-1 hybrid,
`broadband_model=:surrogate` with `bb_j2_scale` and the absorption curve) with
the parametric chain (`:parametric`, App. D modes, Eqs. 19–23 / I-21 open readings)
on the NASA test-article geometry and Phase III trim, e11 free field, blocking R2.
No parameter was chosen from Fig. E-16 / E-9 / Table D-1. Frozen baselines were
**not** renewed.

## Loss factors (η̄_n, η̄_r′ per band)

| fc [Hz] | η̄_n surrogate | η̄_n parametric | Δη̄_n | η̄_r′ surrogate | η̄_r′ parametric | Δη̄_r′ |
|--------:|--------------:|---------------:|-----:|---------------:|----------------:|------:|
| 200 | 0.2443 | 0.2443 | 0.0 | 1.087 | 1.053 | -0.03343 |
| 400 | 0.04657 | 0.04657 | 0.0 | 0.08713 | 0.1227 | 0.03557 |
| 630 | 0.0197 | 0.0197 | 0.0 | 0.08401 | 0.5049 | 0.4209 |
| 1250 | 0.07294 | 0.07294 | 0.0 | 0.233 | 0.5049 | 0.2719 |
| 1600 | 0.04177 | 0.04177 | 0.0 | 0.233 | 0.5049 | 0.2719 |
| 2000 | 0.01803 | 0.01803 | 0.0 | 0.233 | 0.5049 | 0.2719 |

## Interior SPL H1–H3 (Fig. E-16) and T2 bands (Fig. E-9)

| Quantity | Measured mean [dB] | Surrogate [dB] | Parametric [dB] | Δ (par − sur) [dB] |
|----------|-------------------:|---------------:|----------------:|-------------------:|
| H1 @ 200 Hz | 90.0 | 84.21 | 86.56 | 2.35 |
| H2 @ 400 Hz | 80.0 | 77.66 | 88.27 | 10.61 |
| H3 @ 630 Hz | 65.0 | 78.06 | 68.82 | -9.23 |
| T2 fc=1250 Hz | 51.0 | 55.92 | 39.71 | -16.21 |
| T2 fc=1600 Hz | 46.0 | 53.56 | 36.97 | -16.59 |
| T2 fc=2000 Hz | 41.5 | 51.59 | 36.03 | -15.56 |

## Geometry check (parametric path)

- L = 1.83 m, a = 0.508 m, θ0 = 56.6°
- V = 1.23415 m³ (`cabin_volume`)
- A = 5.55661 m² (`coupling_area`)
- S = 5.3532 m² (absorbing, HF path)
- structural notes: App. D Eqs. (D.17)–(D.26) Ritz; rigid=true; no fitted scale; L=1.83 (text App. E); readings=page_D10
- spectrum notes: PAIN tones (CR-3813 §3.2); tone_model=eq8; crossover=396.9 Hz; both Eq.(8) and Eq.(15)–(16) reported + HF Eqs.(19)–(23) as printed (ᾱ from Eq.24/78; Spbl∝f^{-2.0}; phase 38c). Bands above the Fig. A-2 range omitted (allow_extrapolation=false).

## Baselines

No `data/baselines/*` file was rewritten. If a later full-suite diff appears,
renewal remains a dated author decision (R11).

