Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)

# GEXT importance bound (phase 32)

Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)

Generated 2026-10-22 by `scripts/run/run_gext_bound.jl`. Criteria: `VALIDATION_GUIDELINE.md` §2.2.1, re-dated 2026-10-21 for cabin inputs = 18a-r (η_T = 0.5). Flip = any H changing pass↔fail vs nominal (any-H rule).

## 32b Identity control

Nominal T1 H1–H3: 84.21, 77.66, 78.06 dB (amplitude convention fixed 2026-10-21, post-hoc).

| H | SPL dB | d_mean | d_nasa | pass | margin |
|---:|---:|---:|---:|---|---:|
| 1 | 84.21 | -5.79 | +5.21 | FAIL | -1.79 |
| 2 | 77.66 | -2.34 | +2.16 | PASS | +1.66 |
| 3 | 78.06 | +13.06 | +10.06 | FAIL | -9.06 |

## 32c Falloff grid

| variant | n | f | H1 | H2 | H3 | d_mean H1–3 | flip |
|---|---:|---:|---:|---:|---:|---|---|
| n=0.5,f=0.0 | 0.5 | 0.0 | 84.74 | 78.22 | 78.76 | -5.26,-1.78,+13.76 | no |
| n=0.5,f=0.1 | 0.5 | 0.1 | 84.80 | 78.25 | 78.79 | -5.20,-1.75,+13.79 | no |
| n=0.5,f=0.3 | 0.5 | 0.3 | 84.92 | 78.29 | 78.85 | -5.08,-1.71,+13.85 | no |
| n=1.0,f=0.0 | 1.0 | 0.0 | 84.21 | 77.66 | 78.06 | -5.79,-2.34,+13.06 | no |
| n=1.0,f=0.1 | 1.0 | 0.1 | 84.27 | 77.68 | 78.09 | -5.73,-2.32,+13.09 | no |
| n=1.0,f=0.3 | 1.0 | 0.3 | 84.43 | 77.75 | 78.21 | -5.57,-2.25,+13.21 | no |
| n=2.0,f=0.0 | 2.0 | 0.0 | 83.44 | 76.84 | 77.08 | -6.56,-3.16,+12.08 | no |
| n=2.0,f=0.1 | 2.0 | 0.1 | 83.52 | 76.88 | 77.14 | -6.48,-3.12,+12.14 | no |
| n=2.0,f=0.3 | 2.0 | 0.3 | 83.74 | 77.03 | 77.36 | -6.26,-2.97,+12.36 | no |
| n=0.0,f=0.0 | 0.0 | 0.0 | 86.19 | 79.29 | 80.12 | -3.81,-0.71,+15.12 | **yes** |

## 32d Delay variants (falloff nominal)

| variant | delay_scale | H1 | H2 | H3 | flip | T2 offset dB |
|---|---:|---:|---:|---:|---|---:|
| delay off | 0 | 84.02 | 78.88 | 75.13 | no | +0.000 |
| sign flip | -1 | 84.21 | 77.60 | 78.05 | no | +0.000 |
| delay ×0.5 | 0.5 | 84.09 | 78.62 | 77.16 | no | +0.000 |
| delay ×2.0 | 2 | 83.90 | 74.11 | 75.26 | no | +0.000 |

Conditional corner n=0.5, delay ×2:

H1–H3 = 84.67, 73.98, 75.42; flip=no

## 32e Parameter-sensitivity comparator (±20 %)

One-at-a-time over the 13a ranges of η_t (facing/septum via `η_lining`), C of Eq. (80), trim-mass scale, and `bb_j2_scale` (T2 bands only). Order-of-magnitude referent vs GEXT flips — **not** a second bound; no parameter adopted from these runs.

| parameter | value | H1 | H2 | H3 | ΔH1 dB | T2 1.25 kHz Δ dB |
|---|---:|---:|---:|---:|---:|---:|
| η_t | 0.4 | 85.66 | 78.10 | 78.86 | +1.45 | +1.01 |
| η_t | 0.6 | 83.06 | 77.32 | 77.42 | -1.15 | -0.87 |
| C | 2.4 | 84.22 | 77.66 | 78.09 | +0.01 | +0.00 |
| C | 3.6 | 84.20 | 77.65 | 78.03 | -0.01 | +0.00 |
| trim-mass | 0.8 | 85.68 | 77.27 | 77.40 | +1.47 | +0.00 |
| trim-mass | 1.2 | 83.29 | 77.89 | 78.50 | -0.92 | +0.00 |
| bb_j2_scale | 0.4 | 84.21 | 77.66 | 78.06 | +0.00 | -0.97 |
| bb_j2_scale | 0.6 | 84.21 | 77.66 | 78.06 | +0.00 | +0.79 |

Compare ΔH1 magnitudes to GEXT flip sizes in 32c–32d (order-of-magnitude only).

## Claim status

**Any variant flips** → T1 verdict depends on GEXT; not claimable even under V-ASSUMED refraction/scattering.

GEXT grade stays **V-ASSUMED** either way. What this does not show: correctness of GEXT; circularity of the in-sample fit.

