# GEXT importance bound (phase 32)

Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)

Generated 2026-10-28 by `scripts/run/run_gext_bound.jl`. Criteria: `VALIDATION_GUIDELINE.md` §2.2.1, re-dated 2026-10-21 for cabin inputs = 18a-r (η_T = 0.5). Flip = any H changing pass↔fail vs nominal (any-H rule).

## 32b Identity control

Nominal T1 H1–H3: 86.59, 80.02, 76.39 dB (amplitude convention fixed 2026-10-21, post-hoc).

| H | SPL dB | d_mean | d_nasa | pass | margin |
|---:|---:|---:|---:|---|---:|
| 1 | 86.59 | -3.41 | +7.59 | PASS | +0.59 |
| 2 | 80.02 | +0.02 | +4.52 | PASS | +3.98 |
| 3 | 76.39 | +11.39 | +8.39 | FAIL | -7.39 |

## 32c Falloff grid

| variant | n | f | H1 | H2 | H3 | d_mean H1–3 | flip |
|---|---:|---:|---:|---:|---:|---|---|
| n=0.5,f=0.0 | 0.5 | 0.0 | 87.20 | 81.11 | 76.99 | -2.80,+1.11,+11.99 | no |
| n=0.5,f=0.1 | 0.5 | 0.1 | 87.22 | 81.14 | 76.97 | -2.78,+1.14,+11.97 | no |
| n=0.5,f=0.3 | 0.5 | 0.3 | 87.26 | 81.22 | 76.95 | -2.74,+1.22,+11.95 | no |
| n=1.0,f=0.0 | 1.0 | 0.0 | 86.59 | 80.02 | 76.39 | -3.41,+0.02,+11.39 | no |
| n=1.0,f=0.1 | 1.0 | 0.1 | 86.61 | 80.07 | 76.37 | -3.39,+0.07,+11.37 | no |
| n=1.0,f=0.3 | 1.0 | 0.3 | 86.66 | 80.25 | 76.30 | -3.34,+0.25,+11.30 | no |
| n=2.0,f=0.0 | 2.0 | 0.0 | 85.63 | 78.60 | 75.50 | -4.37,-1.40,+10.50 | **yes** |
| n=2.0,f=0.1 | 2.0 | 0.1 | 85.66 | 78.71 | 75.44 | -4.34,-1.29,+10.44 | **yes** |
| n=2.0,f=0.3 | 2.0 | 0.3 | 85.78 | 79.32 | 75.43 | -4.22,-0.68,+10.43 | **yes** |
| n=0.0,f=0.0 | 0.0 | 0.0 | 88.22 | 82.96 | 77.78 | -1.78,+2.96,+12.78 | no |

## 32d Delay variants (falloff nominal)

| variant | delay_scale | H1 | H2 | H3 | flip | T2 offset dB |
|---|---:|---:|---:|---:|---|---:|
| delay off | 0 | 87.07 | 77.41 | 75.26 | no | +0.000 |
| sign flip | -1 | 86.69 | 80.01 | 76.33 | no | +0.000 |
| delay ×0.5 | 0.5 | 86.94 | 78.89 | 76.88 | no | +0.000 |
| delay ×2.0 | 2 | 85.22 | 77.20 | 72.27 | **yes** | +0.000 |

Conditional corner n=0.5, delay ×2:

H1–H3 = 85.68, 76.88, 72.46; flip=yes

## 32e Parameter-sensitivity comparator (±20 %)

One-at-a-time over the 13a ranges of η_t (facing/septum via `η_lining`), C of Eq. (80), trim-mass scale, and `bb_j2_scale` (T2 bands only). Order-of-magnitude referent vs GEXT flips — **not** a second bound; no parameter adopted from these runs.

| parameter | value | H1 | H2 | H3 | ΔH1 dB | T2 1.25 kHz Δ dB |
|---|---:|---:|---:|---:|---:|---:|
| η_t | 0.4 | 87.62 | 80.48 | 77.09 | +1.04 | +1.01 |
| η_t | 0.6 | 85.85 | 79.67 | 75.87 | -0.74 | -0.87 |
| C | 2.4 | 86.59 | 80.03 | 76.43 | +0.01 | +0.00 |
| C | 3.6 | 86.58 | 80.02 | 76.36 | -0.01 | +0.00 |
| trim-mass | 0.8 | 89.05 | 79.59 | 75.63 | +2.46 | +0.00 |
| trim-mass | 1.2 | 84.89 | 80.29 | 76.97 | -1.70 | +0.00 |
| bb_j2_scale | 0.4 | 86.59 | 80.02 | 76.39 | +0.00 | -0.97 |
| bb_j2_scale | 0.6 | 86.59 | 80.02 | 76.39 | +0.00 | +0.79 |

Compare ΔH1 magnitudes to GEXT flip sizes in 32c–32d (order-of-magnitude only).

## Claim status

**Any variant flips** → T1 verdict depends on GEXT; not claimable even under V-ASSUMED refraction/scattering.

GEXT grade stays **V-ASSUMED** either way. What this does not show: correctness of GEXT; circularity of the in-sample fit.

