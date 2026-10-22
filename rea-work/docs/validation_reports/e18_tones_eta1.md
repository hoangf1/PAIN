# E-18 tones — η_T = 1.0, η_r′ ≤ 0.15 (phase 38d, first run)

Criterion dated **2026-10-21** in `IMPLEMENTATION_PLAN.md` §8 row 38d (before this run): \|computed − NASA E-18 prediction\| ≤ 4 dB per harmonic that has a NASA value. No parameter chosen from E-18. Label: **V-CODE vs NASA E-18 prediction; V-EXP shown, held out; first run 2026-10-22**.

## Inputs (NASA CR-3813 p. E-29/E-30; same chain as 18b-r)

| Item | Value |
|---|---|
| Free field | ANOPP Table 8 (GEXT off ℓ = 1) |
| Blocking | R1 |
| Trim | `phase3_trim(; η_lining=1.0)` |
| η_r′ cap | `η_r_cap=0.15` (38a option; confirmed on the tone path: pressure with cap ≠ uncapped) |
| Production tone model | `tone_model=:eq8` (default) |
| BPF / harmonics | 200 Hz; H = 1, 2, 3 |
| Reference | `data/cr3813/e18_interior_pred_eta1.csv` |

## Harmonic → band mapping

| Harmonic | Frequency | CSV / ISO 1/3-octave band | NASA `nasa_pred_dB` |
|---:|---:|---:|---:|
| H1 | 1·BPF = 200 Hz | **200 Hz** | 88.0 |
| H2 | 2·BPF = 400 Hz | **400 Hz** | 75.0 |
| H3 | 3·BPF = 600 Hz | **630 Hz** | 67.0 |

H3 at 600 Hz falls in the 630 Hz 1/3-octave band (`nearest_third_octave(600)`); NASA's E-18 H3 near 600 Hz is the value stored on that band in the CSV. CSV also has NASA predictions at 800 and 1000 Hz (not H1–H3; not in the verdict).

## Per-harmonic table (production `:eq8`)

| H | band Hz | NASA pred | got (:eq8) | Δ (dB) | \|Δ\| ≤ 4? |
|--:|--------:|----------:|-----------:|-------:|:----------:|
| 1 | 200 | 88.0 | 89.02 | +1.02 | yes |
| 2 | 400 | 75.0 | 78.14 | +3.14 | yes |
| 3 | 630 | 67.0 | 77.70 | +10.70 | no |

**Count: 2 / 3. Verdict: `:not_met`.**

## Secondary (not in verdict)

| H | band Hz | `:auto` (dB) | measured mean | low–high |
|--:|--------:|-------------:|--------------:|----------|
| 1 | 200 | 89.02 | 90.0 | 89.5–90.5 |
| 2 | 400 | 13.24 | 80.0 | 79.5–80.5 |
| 3 | 630 | 67.44 | — | — |

V-EXP measured mean/range held out (no pass mark). `:auto` is the 38b crossover path with the same η_r_cap.

## Code / tests

- Cap forwarding: `interior_spl(...; η_r_cap)` → `tone_mean_square_pressure_pair` (tone path)
- Case `E18_TONES` in `validation_case_extras.jl`
- Filtered `Pkg.test("PAIN"; test_args=["E-18 tones", "Validation case registry"])`

No change after seeing the comparison.
