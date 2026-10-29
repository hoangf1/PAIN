# Phases 83–84 — NASA's 300-mode set in the high-frequency path, the reproductions and E-21

Generated 2026-10-29. Criteria fixed 2026-10-29 before the runs (`IMPLEMENTATION_PLAN.md` §8aa). Structural modes: the App. D
solver on NASA's MRP deck (`nasa_deck_modes()`, 300 modes to 3.7 kHz; CR-172428 Table 6) in place of Table D-1's 32 (to 811 Hz).

## E22_HF_DECK (V-CODE): NR against NASA's E-22 prediction, within 3 dB in at least 75 % of bands

| Band (Hz) | NASA (dB) | 300 modes (dB) | Table D-1 (dB) | Resonant modes |
|---|---|---|---|---|
| 1250 | 52.0 | 46.32 | 59.67 | 42 |
| 1600 | 59.5 | 45.79 | 61.60 | 68 |
| 2000 | 69.0 | 50.77 | 62.46 | 39 |
| 2500 | 69.0 | 50.49 | 63.43 | 40 |

Not met, 0/4. Measured mean (E-22): 19.5, 26.0, 25.5, 32.0 dB.

## T2_EQ19_DECK (V-EXP): interior SPL against Fig. E-9, within 3.5 dB at every band

| Band (Hz) | E-9 (dB) | 300 modes (dB) | Table D-1 (dB) |
|---|---|---|---|
| 1250 | 51.0 | 54.89 | 38.85 |
| 1600 | 46.0 | 54.18 | 35.94 |
| 2000 | 41.5 | 48.96 | 34.90 |

Not met, 0/3.

## REPRO_18b_DECK (V-CODE): tones against E-16's NASA prediction, within 4 dB at H1–H3

| Harmonic | NASA (dB) | 300 modes (dB) | Table D-1 (dB) |
|---|---|---|---|
| H1 | 79.0 | 88.15 | 88.20 |
| H2 | 75.5 | 80.58 | 80.43 |
| H3 | 68.0 | 78.33 | 78.21 |

Not met, 0/3.

**Conclusion.** The mode set does not explain the code-to-NASA differences. As fixed before the runs, production keeps Table D-1
and no other mode count is tried.

## Phase 84 (criteria fixed 2026-10-29 before the runs, plan §8ab)

### R172428_CODE_DECK / R172428_EXP_DECK: CR-172428 reproduction, 300 modes

| rpm | H | NASA (dB) | measured (dB) | 300 modes (dB) | 32 modes (dB) |
|---|---|---|---|---|---|
| 3000 | 1–3 | — | — | 70.84, 68.60, 61.66 | 71.07, 69.02, 62.66 |
| 4000 | 1–3 | — | — | 102.41, 79.91, 71.94 | 102.45, 80.05, 71.69 |
| 5000 | 1–3 | — | — | 90.15, 94.49, 80.58 | 90.35, 94.40, 78.40 |

NASA's and the measured values are those of R172428_CODE / R172428_EXP (App. B, Tables 5 and 10). Counts: 4/9 within ±3 dB of NASA,
3/9 within ±4 dB of the measurement, the same as with 32 modes. Not met.

### E21_PRE_DECK: E-21 NR, pre-correction form, 300 modes

1/4 counted bands within ±3 dB of NASA (as E21_PRE). The counted bands lie below the 400 Hz ten-mode crossover, where Table D-1
already has every resonant mode; they move < 0.4 dB. Not met.

**Conclusion.** NASA's mode counts are not the cause of the CR-172428 or E-21 differences; production keeps Table D-1.
