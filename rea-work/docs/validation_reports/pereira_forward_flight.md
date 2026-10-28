# Pereira forward flight (phase 28)

Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.
Generated 2026-10-28 by `scripts/run/run_pereira.jl`.
**Re-run after plan I-01/I-02 (2026-10-28).** Criterion: VALIDATION_GUIDELINE §2.12 / 23d frozen 2026-10-21.
D=0.30 m, B=2, 8000 rpm, V=16 m/s (J=0.4), observers on 1 m arc (`pereira_observers`: φ positive downstream = AA −X), `v_obs=[16,0,0]`.
Geometry: `pereira_fig1b_chord_twist.csv` downsampled to 25 stations; area-mean chord 25.89 mm. **I-10:** paper's 22.85 mm is the 0.75R chord (digitized c/R≈0.152 → 22.9 mm), not an area mean; geometry not rescaled.

## 23d verdict (ScaledLoads, thickness on, Phase 76)

- H1 within ±1.7 dB: 9 / 9
- H2 within ±3 dB: 6 / 9
- ψ₁(φ)−ψ₁(0°) within ±5°: not computed in this pass (Fig.7 fit deferred; levels only).
- Fig.8 vs Fig.9 H1 scatter recorded as reference (I-15 d/e); not corrected.

## Loads vs Table 3

| polar | thick | T N | Q N·m | C_T | C_P | s_T needed | notes |
|---|---|---:|---:|---:|---:|---:|---|
| measured | — | 14.55 | 0.4133 | 0.0825 | 0.0491 | 1 | Table 3 Exp |
| paper BEMT | — | 14.56 | 0.4338 | 0.0826 | 0.0512 | 1 | Table 3 |
| ncrit9 | ton | 14.652 | 0.4277 | 0.0831 | 0.0508 | 0.99 | clamped_Re=0 |
| ncrit9 | toff | 14.652 | 0.4277 | 0.0831 | 0.0508 | 0.99 | clamped_Re=0 |
| ncrit5 | ton | 14.451 | 0.4177 | 0.0819 | 0.0496 | 1.01 | clamped_Re=0 |
| ncrit5 | toff | 14.451 | 0.4177 | 0.0819 | 0.0496 | 1.01 | clamped_Re=0 |
| xtr005 | ton | 13.458 | 0.3989 | 0.0763 | 0.0474 | 1.08 | clamped_Re=0 |
| xtr005 | toff | 13.458 | 0.3989 | 0.0763 | 0.0474 | 1.08 | clamped_Re=0 |

ScaledLoads(14.55, 0.4133) reproduces targets (checked in each run).

## H1–H2 SPL at φ (ScaledLoads, thickness on, Phase 76), vs Fig. 9 Exp

| polar | φ | H | SPL F1A | Fig.9 Exp | Δ dB |
|---|---:|--:|---:|---:|---:|
| ncrit9 | -20.0 | 1 | 81.61 | — |  |
| ncrit9 | -20.0 | 2 | 67.23 | — |  |
| ncrit9 | -10.0 | 1 | 82.87 | — |  |
| ncrit9 | -10.0 | 2 | 69.01 | — |  |
| ncrit9 | 0.0 | 1 | 83.86 | 84.22 | -0.36 |
| ncrit9 | 0.0 | 2 | 70.01 | 70.35 | -0.34 |
| ncrit9 | 10.0 | 1 | 84.47 | — |  |
| ncrit9 | 10.0 | 2 | 70.19 | — |  |
| ncrit9 | 20.0 | 1 | 84.55 | 84.45 | 0.1 |
| ncrit9 | 20.0 | 2 | 69.37 | 65.69 | 3.68 |
| ncrit9 | 30.0 | 1 | 83.97 | — |  |
| ncrit9 | 30.0 | 2 | 67.33 | — |  |
| ncrit9 | 40.0 | 1 | 82.56 | 82.57 | -0.01 |
| ncrit9 | 40.0 | 2 | 63.8 | 65.07 | -1.27 |
| ncrit5 | -20.0 | 1 | 81.61 | — |  |
| ncrit5 | -20.0 | 2 | 67.22 | — |  |
| ncrit5 | -10.0 | 1 | 82.87 | — |  |
| ncrit5 | -10.0 | 2 | 69.0 | — |  |
| ncrit5 | 0.0 | 1 | 83.86 | 84.22 | -0.36 |
| ncrit5 | 0.0 | 2 | 70.0 | 70.35 | -0.35 |
| ncrit5 | 10.0 | 1 | 84.47 | — |  |
| ncrit5 | 10.0 | 2 | 70.18 | — |  |
| ncrit5 | 20.0 | 1 | 84.55 | 84.45 | 0.1 |
| ncrit5 | 20.0 | 2 | 69.36 | 65.69 | 3.67 |
| ncrit5 | 30.0 | 1 | 83.97 | — |  |
| ncrit5 | 30.0 | 2 | 67.33 | — |  |
| ncrit5 | 40.0 | 1 | 82.56 | 82.57 | -0.01 |
| ncrit5 | 40.0 | 2 | 63.8 | 65.07 | -1.27 |
| xtr005 | -20.0 | 1 | 81.61 | — |  |
| xtr005 | -20.0 | 2 | 67.22 | — |  |
| xtr005 | -10.0 | 1 | 82.87 | — |  |
| xtr005 | -10.0 | 2 | 69.0 | — |  |
| xtr005 | 0.0 | 1 | 83.86 | 84.22 | -0.36 |
| xtr005 | 0.0 | 2 | 70.0 | 70.35 | -0.35 |
| xtr005 | 10.0 | 1 | 84.47 | — |  |
| xtr005 | 10.0 | 2 | 70.17 | — |  |
| xtr005 | 20.0 | 1 | 84.54 | 84.45 | 0.09 |
| xtr005 | 20.0 | 2 | 69.34 | 65.69 | 3.65 |
| xtr005 | 30.0 | 1 | 83.96 | — |  |
| xtr005 | 30.0 | 2 | 67.31 | — |  |
| xtr005 | 40.0 | 1 | 82.55 | 82.57 | -0.02 |
| xtr005 | 40.0 | 2 | 63.77 | 65.07 | -1.3 |

Config: `PAIN.jl/examples/pereira_apc9x6_scaled.json`.
