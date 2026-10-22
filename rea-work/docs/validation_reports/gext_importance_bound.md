# GEXT importance bound (phase 32)

Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.

Generated 2026-10-21 by `scripts/run/run_gext_bound.jl`. Criteria: `VALIDATION_GUIDELINE.md` §2.2.1, re-dated 2026-10-21 for cabin inputs = 18a-r (η_T = 0.5). Flip = any H changing pass↔fail vs nominal (any-H rule).

## 32b Identity control

Nominal T1 H1–H3: 84.05, 78.01, 78.30 dB (amplitude convention fixed 2026-10-21, post-hoc).

| H | SPL dB | d_mean | d_nasa | pass | margin |
|---:|---:|---:|---:|---|---:|
| 1 | 84.05 | -5.95 | +5.05 | FAIL | -1.95 |
| 2 | 78.01 | -1.99 | +2.51 | PASS | +2.01 |
| 3 | 78.30 | +13.30 | +10.30 | FAIL | -9.30 |

## 32c Falloff grid

| variant | n | f | H1 | H2 | H3 | d_mean H1–3 | flip |
|---|---:|---:|---:|---:|---:|---|---|
| n=0.5,f=0.0 | 0.5 | 0.0 | 84.57 | 78.55 | 78.99 | -5.43,-1.45,+13.99 | no |
| n=0.5,f=0.1 | 0.5 | 0.1 | 84.63 | 78.57 | 79.02 | -5.37,-1.43,+14.02 | no |
| n=0.5,f=0.3 | 0.5 | 0.3 | 84.76 | 78.61 | 79.08 | -5.24,-1.39,+14.08 | no |
| n=1.0,f=0.0 | 1.0 | 0.0 | 84.05 | 78.01 | 78.30 | -5.95,-1.99,+13.30 | no |
| n=1.0,f=0.1 | 1.0 | 0.1 | 84.11 | 78.03 | 78.33 | -5.89,-1.97,+13.33 | no |
| n=1.0,f=0.3 | 1.0 | 0.3 | 84.28 | 78.10 | 78.44 | -5.72,-1.90,+13.44 | no |
| n=2.0,f=0.0 | 2.0 | 0.0 | 83.29 | 77.22 | 77.34 | -6.71,-2.78,+12.34 | no |
| n=2.0,f=0.1 | 2.0 | 0.1 | 83.37 | 77.25 | 77.39 | -6.63,-2.75,+12.39 | no |
| n=2.0,f=0.3 | 2.0 | 0.3 | 83.60 | 77.37 | 77.60 | -6.40,-2.63,+12.60 | no |
| n=0.0,f=0.0 | 0.0 | 0.0 | 86.04 | 79.55 | 80.31 | -3.96,-0.45,+15.31 | **yes** |

## 32d Delay variants (falloff nominal)

| variant | delay_scale | H1 | H2 | H3 | flip | T2 offset dB |
|---|---:|---:|---:|---:|---|---:|
| delay off | 0 | 83.83 | 79.36 | 75.44 | no | +0.000 |
| sign flip | -1 | 84.05 | 77.95 | 78.29 | no | +0.000 |
| delay ×0.5 | 0.5 | 83.91 | 79.06 | 77.45 | no | +0.000 |
| delay ×2.0 | 2 | 83.78 | 74.42 | 75.51 | no | +0.000 |

Conditional corner n=0.5, delay ×2:

H1–H3 = 84.55, 74.30, 75.66; flip=no

## 32e Parameter-sensitivity comparator (±20 %)

One-at-a-time over the 13a ranges of η_t (facing/septum via `η_lining`), C of Eq. (80), trim-mass scale, and `bb_j2_scale` (T2 bands only). Order-of-magnitude referent vs GEXT flips — **not** a second bound; no parameter adopted from these runs.

| parameter | value | H1 | H2 | H3 | ΔH1 dB | T2 1.25 kHz Δ dB |
|---|---:|---:|---:|---:|---:|---:|
| η_t | 0.4 | 85.44 | 78.50 | 79.17 | +1.39 | +1.01 |
| η_t | 0.6 | 82.95 | 77.65 | 77.62 | -1.10 | -0.86 |
| C | 2.4 | 84.06 | 78.01 | 78.33 | +0.01 | +0.00 |
| C | 3.6 | 84.04 | 78.00 | 78.27 | -0.01 | +0.00 |
| trim-mass | 0.8 | 85.52 | 77.61 | 77.63 | +1.47 | +0.00 |
| trim-mass | 1.2 | 83.12 | 78.25 | 78.76 | -0.93 | +0.00 |
| bb_j2_scale | 0.4 | 84.05 | 78.01 | 78.30 | +0.00 | -0.97 |
| bb_j2_scale | 0.6 | 84.05 | 78.01 | 78.30 | +0.00 | +0.79 |

Compare ΔH1 magnitudes to GEXT flip sizes in 32c–32d (order-of-magnitude only).

## Claim status

**Any variant flips** → T1 verdict depends on GEXT; not claimable even under V-ASSUMED refraction/scattering.

GEXT grade stays **V-ASSUMED** either way. What this does not show: correctness of GEXT; circularity of the in-sample fit.

