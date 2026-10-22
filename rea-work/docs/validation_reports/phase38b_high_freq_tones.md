Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)

# Phase 38b — CR-3813 §3.2 high-frequency tone formulation (Eqs. 11–16)

First run 2026-10-22; **re-recorded at L = 1.83 m (I-22, post-hoc)**. Criteria fixed in `IMPLEMENTATION_PLAN.md` §8 row 38b and issue I-18 (**dated 2026-10-21, before any run; not changed**). No parameter chosen from REPRO_18b / T1 / E-16. No mirroring adopted after seeing the result. Earlier 1.803 m values: `length_sensitivity.md`.

## Crossover band (test article)

| Quantity | Value |
|----------|-------|
| Centre frequency | **396.85 Hz** |
| Acoustic modes in band | **11** |
| Rule | Lowest 1/3-oct with ≥ 10 three-dimensional acoustic modes |

## REPRO_18b with `tone_model=:auto` (18b-r inputs; one run)

Inputs: ANOPP Table 8 + GEXT, R1, Phase III trim η_T=0.5, BPF = 200 Hz, L=1.83 m. NASA (Fig. E-16): 79.0, 75.5, 68.0 dB. Criterion: |Δ| ≤ 4 dB.

| H | f (Hz) | Eq. (8) dB | Eq. (15)–(16) dB | Production (`:auto`) | Model used | Δ vs NASA | |Δ| ≤ 4 |
|---|--------|------------|------------------|----------------------|------------|-----------|----------|
| 1 | 200 | 85.90 | 68.21 | **85.90** | `:eq8` | +6.90 | no |
| 2 | 400 | 78.35 | 16.81 | **16.81** | `:eq15_16` | -58.69 | no |
| 3 | 600 | 79.82 | 72.24 | **72.24** | `:eq15_16` | +4.24 | no |

### I-18 “explains H3” rule (dated 2026-10-21)

| Check | Value |
|-------|-------|
| Eq. (8) H3 | 79.82 dB → |Δ| = 11.82 dB |
| `:auto` H3 | 72.24 dB → |Δ| = **4.24 dB** |
| **Explains H3?** | **No** |

Mirroring (I-18) is **not** adopted.
