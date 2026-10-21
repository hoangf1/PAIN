# Pereira forward flight (phase 28)

Generated 2026-10-21 by `scripts/run_pereira.jl`.
**Re-run after plan I-01/I-02 (2026-10-21).** Criterion: VALIDATION_GUIDELINE §2.12 / 23d frozen 2026-10-21.
D=0.30 m, B=2, 8000 rpm, V=16 m/s (J=0.4), observers on 1 m arc, `v_obs=[16,0,0]`.
Geometry: `pereira_fig1b_chord_twist.csv` downsampled to 25 stations; area-mean chord 25.89 mm. **I-10:** paper's 22.85 mm is the 0.75R chord (digitized c/R≈0.152 → 22.9 mm), not an area mean; geometry not rescaled.

## 23d verdict (ScaledLoads, thickness off)

- H1 within ±1.7 dB: 0 / 9
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
| ncrit9 | -20.0 | 1 | 87.58 | — |  |
| ncrit9 | -20.0 | 2 | 71.96 | — |  |
| ncrit9 | -10.0 | 1 | 87.26 | — |  |
| ncrit9 | -10.0 | 2 | 72.31 | — |  |
| ncrit9 | 0.0 | 1 | 86.25 | 80.0 | 6.25 |
| ncrit9 | 0.0 | 2 | 71.36 | 69.0 | 2.36 |
| ncrit9 | 10.0 | 1 | 84.6 | — |  |
| ncrit9 | 10.0 | 2 | 69.16 | — |  |
| ncrit9 | 20.0 | 1 | 82.43 | 80.0 | 2.43 |
| ncrit9 | 20.0 | 2 | 65.8 | 64.0 | 1.8 |
| ncrit9 | 30.0 | 1 | 79.9 | — |  |
| ncrit9 | 30.0 | 2 | 61.44 | — |  |
| ncrit9 | 40.0 | 1 | 77.1 | 80.0 | -2.9 |
| ncrit9 | 40.0 | 2 | 56.28 | 64.5 | -8.22 |
| ncrit5 | -20.0 | 1 | 87.64 | — |  |
| ncrit5 | -20.0 | 2 | 72.05 | — |  |
| ncrit5 | -10.0 | 1 | 87.29 | — |  |
| ncrit5 | -10.0 | 2 | 72.34 | — |  |
| ncrit5 | 0.0 | 1 | 86.23 | 80.0 | 6.23 |
| ncrit5 | 0.0 | 2 | 71.31 | 69.0 | 2.31 |
| ncrit5 | 10.0 | 1 | 84.54 | — |  |
| ncrit5 | 10.0 | 2 | 69.02 | — |  |
| ncrit5 | 20.0 | 1 | 82.33 | 80.0 | 2.33 |
| ncrit5 | 20.0 | 2 | 65.57 | 64.0 | 1.57 |
| ncrit5 | 30.0 | 1 | 79.78 | — |  |
| ncrit5 | 30.0 | 2 | 61.17 | — |  |
| ncrit5 | 40.0 | 1 | 77.02 | 80.0 | -2.98 |
| ncrit5 | 40.0 | 2 | 56.13 | 64.5 | -8.37 |
| xtr005 | -20.0 | 1 | 87.66 | — |  |
| xtr005 | -20.0 | 2 | 72.08 | — |  |
| xtr005 | -10.0 | 1 | 87.3 | — |  |
| xtr005 | -10.0 | 2 | 72.35 | — |  |
| xtr005 | 0.0 | 1 | 86.23 | 80.0 | 6.23 |
| xtr005 | 0.0 | 2 | 71.29 | 69.0 | 2.29 |
| xtr005 | 10.0 | 1 | 84.52 | — |  |
| xtr005 | 10.0 | 2 | 68.96 | — |  |
| xtr005 | 20.0 | 1 | 82.29 | 80.0 | 2.29 |
| xtr005 | 20.0 | 2 | 65.45 | 64.0 | 1.45 |
| xtr005 | 30.0 | 1 | 79.74 | — |  |
| xtr005 | 30.0 | 2 | 61.05 | — |  |
| xtr005 | 40.0 | 1 | 76.99 | 80.0 | -3.01 |
| xtr005 | 40.0 | 2 | 56.07 | 64.5 | -8.43 |

Config: `PAIN.jl/examples/pereira_apc9x6_scaled.json`.
