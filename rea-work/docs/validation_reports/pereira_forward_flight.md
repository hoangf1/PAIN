# Pereira forward flight (phase 28)

Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.
Generated 2026-10-21 by `scripts/run/run_pereira.jl`.
**Re-run after plan I-01/I-02 (2026-10-21).** Criterion: VALIDATION_GUIDELINE §2.12 / 23d frozen 2026-10-21.
D=0.30 m, B=2, 8000 rpm, V=16 m/s (J=0.4), observers on 1 m arc, `v_obs=[16,0,0]`.
Geometry: `pereira_fig1b_chord_twist.csv` downsampled to 25 stations; area-mean chord 25.89 mm. **I-10:** paper's 22.85 mm is the 0.75R chord (digitized c/R≈0.152 → 22.9 mm), not an area mean; geometry not rescaled.

## 23d verdict (ScaledLoads, thickness off)

- H1 within ±1.7 dB: 3 / 9
- H2 within ±3 dB: 6 / 9
- ψ₁(φ)−ψ₁(0°) within ±5°: not computed in this pass (Fig.7 fit deferred; levels only).
- Fig.8 vs Fig.9 H1 scatter recorded as reference (I-15 d/e); not corrected.

## Loads vs Table 3

| polar | thick | T N | Q N·m | C_T | C_P | s_T needed | notes |
|---|---|---:|---:|---:|---:|---:|---|
| measured | — | 14.55 | 0.4133 | 0.0825 | 0.0491 | 1 | Table 3 Exp |
| paper BEMT | — | 14.56 | 0.4338 | 0.0826 | 0.0512 | 1 | Table 3 |
| ncrit9 | toff | 5.733 | 0.2711 | 0.0325 | 0.0322 | 2.54 | clamped_Re=1044 |
| ncrit9 | ton | 5.733 | 0.2711 | 0.0325 | 0.0322 | 2.54 | clamped_Re=1044 |
| ncrit5 | toff | 9.59 | 0.3608 | 0.0544 | 0.0428 | 1.52 | clamped_Re=1064 |
| ncrit5 | ton | 9.59 | 0.3608 | 0.0544 | 0.0428 | 1.52 | clamped_Re=1064 |
| xtr005 | toff | 10.822 | 0.3623 | 0.0614 | 0.043 | 1.34 | clamped_Re=1064 |
| xtr005 | ton | 10.822 | 0.3623 | 0.0614 | 0.043 | 1.34 | clamped_Re=1064 |

ScaledLoads(14.55, 0.4133) reproduces targets (checked in each run).

## H1–H2 SPL at φ (ScaledLoads, thickness off), vs Fig. 9 Exp

| polar | φ | H | SPL F1A | Fig.9 Exp | Δ dB |
|---|---:|--:|---:|---:|---:|
| ncrit9 | -20.0 | 1 | 84.57 | — |  |
| ncrit9 | -20.0 | 2 | 68.95 | — |  |
| ncrit9 | -10.0 | 1 | 84.25 | — |  |
| ncrit9 | -10.0 | 2 | 69.3 | — |  |
| ncrit9 | 0.0 | 1 | 83.24 | 80.0 | 3.24 |
| ncrit9 | 0.0 | 2 | 68.34 | 69.0 | -0.66 |
| ncrit9 | 10.0 | 1 | 81.59 | — |  |
| ncrit9 | 10.0 | 2 | 66.15 | — |  |
| ncrit9 | 20.0 | 1 | 79.42 | 80.0 | -0.58 |
| ncrit9 | 20.0 | 2 | 62.79 | 64.0 | -1.21 |
| ncrit9 | 30.0 | 1 | 76.88 | — |  |
| ncrit9 | 30.0 | 2 | 58.43 | — |  |
| ncrit9 | 40.0 | 1 | 74.08 | 80.0 | -5.92 |
| ncrit9 | 40.0 | 2 | 53.27 | 64.5 | -11.23 |
| ncrit5 | -20.0 | 1 | 84.62 | — |  |
| ncrit5 | -20.0 | 2 | 69.04 | — |  |
| ncrit5 | -10.0 | 1 | 84.28 | — |  |
| ncrit5 | -10.0 | 2 | 69.33 | — |  |
| ncrit5 | 0.0 | 1 | 83.22 | 80.0 | 3.22 |
| ncrit5 | 0.0 | 2 | 68.3 | 69.0 | -0.7 |
| ncrit5 | 10.0 | 1 | 81.53 | — |  |
| ncrit5 | 10.0 | 2 | 66.01 | — |  |
| ncrit5 | 20.0 | 1 | 79.32 | 80.0 | -0.68 |
| ncrit5 | 20.0 | 2 | 62.55 | 64.0 | -1.45 |
| ncrit5 | 30.0 | 1 | 76.77 | — |  |
| ncrit5 | 30.0 | 2 | 58.16 | — |  |
| ncrit5 | 40.0 | 1 | 74.01 | 80.0 | -5.99 |
| ncrit5 | 40.0 | 2 | 53.12 | 64.5 | -11.38 |
| xtr005 | -20.0 | 1 | 84.65 | — |  |
| xtr005 | -20.0 | 2 | 69.07 | — |  |
| xtr005 | -10.0 | 1 | 84.29 | — |  |
| xtr005 | -10.0 | 2 | 69.34 | — |  |
| xtr005 | 0.0 | 1 | 83.22 | 80.0 | 3.22 |
| xtr005 | 0.0 | 2 | 68.28 | 69.0 | -0.72 |
| xtr005 | 10.0 | 1 | 81.51 | — |  |
| xtr005 | 10.0 | 2 | 65.95 | — |  |
| xtr005 | 20.0 | 1 | 79.28 | 80.0 | -0.72 |
| xtr005 | 20.0 | 2 | 62.44 | 64.0 | -1.56 |
| xtr005 | 30.0 | 1 | 76.73 | — |  |
| xtr005 | 30.0 | 2 | 58.04 | — |  |
| xtr005 | 40.0 | 1 | 73.98 | 80.0 | -6.02 |
| xtr005 | 40.0 | 2 | 53.06 | 64.5 | -11.44 |

Config: `PAIN.jl/examples/pereira_apc9x6_scaled.json`.
