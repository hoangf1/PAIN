# Pereira forward flight (phase 28)

Generated 2026-10-21 by `scripts/run_pereira.jl`.
D=0.30 m, B=2, 8000 rpm, V=16 m/s (J=0.4), observers on 1 m arc, `v_obs=[16,0,0]`.
Geometry: `pereira_fig1b_chord_twist.csv` downsampled to 25 stations; mean chord 25.89 mm (paper 22.85 mm).
**Pass/fail waits on 23d [AUTHOR].**

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
Best unscaled polar: `xtr005` (T≈10.8 N, s_T≈1.34). Free-transition `ncrit9` under-predicts most (T≈5.7 N). Thickness on/off does not change loads (thickness is F1A-only).

**Fig. 9 dig note:** Exp H1 at φ=40° = 100.0 dB is a clipped-axis artifact in `pereira_fig9_harmonics.csv` — do not use that cell for residuals.

## H1–H2 SPL at φ (ScaledLoads, thickness off), vs Fig. 9 Exp

| polar | φ | H | SPL F1A | Fig.9 Exp | Δ dB |
|---|---:|--:|---:|---:|---:|
| ncrit9 | -20.0 | 1 | 87.68 | — |  |
| ncrit9 | -20.0 | 2 | 72.97 | — |  |
| ncrit9 | -10.0 | 1 | 87.53 | — |  |
| ncrit9 | -10.0 | 2 | 72.85 | — |  |
| ncrit9 | 0.0 | 1 | 86.68 | 88.95 | -2.27 |
| ncrit9 | 0.0 | 2 | 71.18 | 83.68 | -12.5 |
| ncrit9 | 10.0 | 1 | 85.16 | — |  |
| ncrit9 | 10.0 | 2 | 67.87 | — |  |
| ncrit9 | 20.0 | 1 | 83.01 | 85.53 | -2.52 |
| ncrit9 | 20.0 | 2 | 62.69 | 71.58 | -8.89 |
| ncrit9 | 30.0 | 1 | 80.55 | — |  |
| ncrit9 | 30.0 | 2 | 56.09 | — |  |
| ncrit9 | 40.0 | 1 | 77.7 | 100.0 | -22.3 |
| ncrit9 | 40.0 | 2 | 46.44 | 86.14 | -39.7 |
| ncrit5 | -20.0 | 1 | 87.73 | — |  |
| ncrit5 | -20.0 | 2 | 73.1 | — |  |
| ncrit5 | -10.0 | 1 | 87.55 | — |  |
| ncrit5 | -10.0 | 2 | 72.92 | — |  |
| ncrit5 | 0.0 | 1 | 86.67 | 88.95 | -2.28 |
| ncrit5 | 0.0 | 2 | 71.14 | 83.68 | -12.54 |
| ncrit5 | 10.0 | 1 | 85.09 | — |  |
| ncrit5 | 10.0 | 2 | 67.63 | — |  |
| ncrit5 | 20.0 | 1 | 82.98 | 85.53 | -2.55 |
| ncrit5 | 20.0 | 2 | 62.51 | 71.58 | -9.07 |
| ncrit5 | 30.0 | 1 | 80.45 | — |  |
| ncrit5 | 30.0 | 2 | 54.99 | — |  |
| ncrit5 | 40.0 | 1 | 77.59 | 100.0 | -22.41 |
| ncrit5 | 40.0 | 2 | 44.55 | 86.14 | -41.59 |
| xtr005 | -20.0 | 1 | 87.75 | — |  |
| xtr005 | -20.0 | 2 | 73.14 | — |  |
| xtr005 | -10.0 | 1 | 87.56 | — |  |
| xtr005 | -10.0 | 2 | 72.94 | — |  |
| xtr005 | 0.0 | 1 | 86.66 | 88.95 | -2.29 |
| xtr005 | 0.0 | 2 | 71.12 | 83.68 | -12.56 |
| xtr005 | 10.0 | 1 | 85.07 | — |  |
| xtr005 | 10.0 | 2 | 67.51 | — |  |
| xtr005 | 20.0 | 1 | 82.94 | 85.53 | -2.59 |
| xtr005 | 20.0 | 2 | 62.25 | 71.58 | -9.33 |
| xtr005 | 30.0 | 1 | 80.38 | — |  |
| xtr005 | 30.0 | 2 | 54.38 | — |  |
| xtr005 | 40.0 | 1 | 77.58 | 100.0 | -22.42 |
| xtr005 | 40.0 | 2 | 43.23 | 86.14 | -42.91 |

Config: `PAIN.jl/examples/pereira_apc9x6_scaled.json`.
