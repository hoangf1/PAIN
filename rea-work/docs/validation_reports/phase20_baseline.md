# Phase 20 baseline, before the aircraft-source change (recorded 2026-10-20)

Taken after phases 12–19 and after the author's decision on the Phase III trim loss factor (η_T = 0.5, `phase3_trim` default; aircraft register default 0.05 unchanged), so that it reflects the corrected input and the corrected grid azimuth (12b). Source code: the aircraft path still runs F1A on the ℓ = 1 line only and applies GEXT (`_ccblade_f1a_grid`); phase 21 changes that. Wall times are for a cold `julia` start on the author's machine (they include package loading), so they are an upper bound on the F1A work.

## 1. `Pkg.test()`

**1758 of 1758 checks pass** (wall time 42.6 s). The phase 17 regression baselines (`data/baselines/phase17_baselines.csv`) were renewed on the same date for η_T = 0.5; the 0.05 file is kept as `phase17_baselines_etaT0p05_archive.csv`.

## 2. e11 path, T1 and T2 (`scripts/run_pain.jl`, `run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)`)

Phase III trim with η_T = 0.5. Criteria unchanged from 18a. Label: **18a-r, input correction, result partly known from 19f**; the η_T = 0.05 numbers of 18a stay in the record as "wrong η_T".

| Test | 18a (η_T = 0.05) | 18a-r (η_T = 0.5) | Target | Gate result 18a-r |
|---|---:|---:|---|---|
| T1 H1, 200 Hz | 90.24 dB | **81.04 dB** | mean 90.0; NASA PAIN 79.0 | PASS by the NASA route only (d_nasa +2.0; 9.0 dB below the measured mean) |
| T1 H2, 400 Hz | 79.30 dB | **75.00 dB** | mean 80.0; NASA PAIN 75.5 | PASS by the NASA route only (d_nasa −0.5; 5.0 dB below the mean) |
| T1 H3, 600 Hz | 83.15 dB | **75.29 dB** | mean 65.0; NASA PAIN 68.0 | **FAIL** (+10.3 dB on the mean, +7.3 on NASA) |
| T2 1250 Hz | 62.25 dB | **52.96 dB** | Fig. E-9 mean 51.0 ± 3.5 | PASS (+2.0) |
| T2 1600 Hz | 60.34 dB | **50.62 dB** | 46.0 ± 3.5 | FAIL (+4.6) |
| T2 2000 Hz | 58.48 dB | **48.66 dB** | 41.5 ± 3.5 | FAIL (+7.2) |

Reading: the chain now follows NASA's own PAIN predictions at H1 and H2 but no longer sits within 4 dB of the measured mean (NASA's own predictions are 11 and 4.5 dB below it as well, Fig. E-16). T1 stays **no claim**; H3 is open (plan 19i). T2 still carries the stale `bb_j2_scale` = 0.5 from an earlier fit, so its 1 of 3 pass is not a claim (30b replaces it). Other outputs of the same run: Table C-1 / D-1 checks unchanged (CYL2D within 0.3 % in the driver's c0 = 340 m/s comparison, 32/32 Table D-1 seed), δ_dig = 1.0 dB.

## 3. 18b-r (`scripts/run_pain_reproduction.jl`, `pain_reproduction_e16.md`)

R1 blocking, Table 8, η_T = 0.5: 82.73, 75.73, 77.05 dB = +3.7 (within the criterion, margin 0.3 dB), +0.2, +9.1 dB against 79.0, 75.5, 68.0: criterion (4 dB at each harmonic) **not met, 2 of 3**. The original 18b (η_T = 0.05): 91.92, 80.01, 84.87 dB, 0 of 3.

## 4. F1A smoke (`scripts/run_f1a_smoke.jl`, `ccblade_f1a_smoke.md`)

l = 1 peak free-field SPL after the Table-8 peak calibration: 125.7, 118.6, 111.3 dB against ANOPP Table 8 125.7, 118.6, 111.3 (deltas 0.0, 0.0, −0.0; agreement is by construction of the calibration, X-EXTRAP, a sanity check). Wall time 17.9 s for the l = 1-only F1A run, the reference for the cost comparison of phase 21 (about 10× or more expected for 160 observers).

Aircraft example (`examples/aircraft_scale_hartzell.json`, X-EXTRAP, bare cabin, not NASA-validated): interior SPL 85.0, 77.9, 76.7 dB at H1–H3, overall 78.7 dB(A) (unchanged by η_T, which acts on the Phase III trim only).
