# GEXT importance bound (phase 32)

Generated 2026-10-21 by `scripts/run_gext_bound.jl`. Criteria: `VALIDATION_GUIDELINE.md` §2.2.1, re-dated 2026-10-21 for cabin inputs = 18a-r (η_T = 0.5). Flip = any H changing pass↔fail vs nominal (any-H rule).

## 32b Identity control

Nominal T1 H1–H3: 81.04, 75.00, 75.29 dB (phase20_baseline 81.04, 75.00, 75.29).

| H | SPL dB | d_mean | d_nasa | pass | margin |
|---:|---:|---:|---:|---|---:|
| 1 | 81.04 | -8.96 | +2.04 | PASS | +1.96 |
| 2 | 75.00 | -5.00 | -0.50 | PASS | +3.50 |
| 3 | 75.29 | +10.29 | +7.29 | FAIL | -6.29 |

## 32c Falloff grid

| variant | n | f | H1 | H2 | H3 | d_mean H1–3 | flip |
|---|---:|---:|---:|---:|---:|---|---|
| n=0.5,f=0.0 | 0.5 | 0.0 | 81.56 | 75.54 | 75.98 | -8.44,-4.46,+10.98 | no |
| n=0.5,f=0.1 | 0.5 | 0.1 | 81.62 | 75.56 | 76.01 | -8.38,-4.44,+11.01 | no |
| n=0.5,f=0.3 | 0.5 | 0.3 | 81.75 | 75.60 | 76.07 | -8.25,-4.40,+11.07 | no |
| n=1.0,f=0.0 | 1.0 | 0.0 | 81.04 | 75.00 | 75.29 | -8.96,-5.00,+10.29 | no |
| n=1.0,f=0.1 | 1.0 | 0.1 | 81.10 | 75.02 | 75.32 | -8.90,-4.98,+10.32 | no |
| n=1.0,f=0.3 | 1.0 | 0.3 | 81.27 | 75.09 | 75.43 | -8.73,-4.91,+10.43 | no |
| n=2.0,f=0.0 | 2.0 | 0.0 | 80.28 | 74.21 | 74.33 | -9.72,-5.79,+9.33 | no |
| n=2.0,f=0.1 | 2.0 | 0.1 | 80.36 | 74.24 | 74.38 | -9.64,-5.76,+9.38 | no |
| n=2.0,f=0.3 | 2.0 | 0.3 | 80.59 | 74.36 | 74.59 | -9.41,-5.64,+9.59 | no |
| n=0.0,f=0.0 | 0.0 | 0.0 | 83.03 | 76.54 | 77.30 | -6.97,-3.46,+12.30 | **yes** |

## 32d Delay variants (falloff nominal)

| variant | delay_scale | H1 | H2 | H3 | flip | T2 offset dB |
|---|---:|---:|---:|---:|---|---:|
| delay off | 0 | 80.82 | 76.35 | 72.43 | no | +0.000 |
| sign flip | -1 | 81.04 | 74.94 | 75.28 | no | +0.000 |
| delay ×0.5 | 0.5 | 80.90 | 76.05 | 74.44 | no | +0.000 |
| delay ×2.0 | 2 | 80.77 | 71.41 | 72.50 | **yes** | +0.000 |

Conditional corner n=0.5, delay ×2:

H1–H3 = 81.54, 71.29, 72.65; flip=yes

## 32e Parameter-sensitivity comparator (±20 %)

One-at-a-time on η_t (facing/septum), C of Eq. (80), trim-mass scale, `bb_j2_scale` (T2 only). Order-of-magnitude referent, not a second bound. Deferred in this run if rebuilding trim stacks is heavy; recorded as planned.

## Claim status

**Any variant flips** → T1 verdict depends on GEXT; not claimable even under V-ASSUMED refraction/scattering.

GEXT grade stays **V-ASSUMED** either way. What this does not show: correctness of GEXT; circularity of the in-sample fit.

