# Length re-record before/after (I-22, 2026-10-22, post-hoc)

Default test-article length changed from **1.803 m** to **1.83 m** (I-22 decision from source text, not from any error).
Criteria, tolerances, and reference/digitized data unchanged. Full paired tables: `length_sensitivity.md`.

## Verdict flips

**None.** Every length-dependent case keeps the same verdict at 1.803 m and 1.83 m.

| Case | Verdict @ 1.803 m (before) | Verdict @ 1.83 m (after) | Verdict changes? |
|------|----------------------------|--------------------------|------------------|
| `REPRO_18b` | `not_met` | `not_met` | no |
| `T1` | `not_met` | `not_met` | no |
| `T2` | `not_met` | `not_met` | no |
| `T2_EQ19` | `not_met` | `not_met` | no |
| `E21_E22_NR` | `not_met` | `not_met` | no |
| `E18_TONES` | `not_met` | `not_met` | no |
| `E15_STRUCT_LOSS` | `no_verdict` | `no_verdict` | no |
| `E14_LOSS` | `not_met` | `not_met` | no |
| `MRP_RITZ` | `no_verdict` | `no_verdict` | no |
| `MRP_APPD` | `met` | `met` | no |
| `GEXT_BOUND` | `no_verdict` | `no_verdict` | no |

## Key quantities (case, quantity, before @ 1.803 m, after @ 1.83 m)

| Case | Quantity | before @ 1.803 m | after @ 1.83 m | Δ |
|------|----------|------------------|----------------|---|
| `REPRO_18b` | vs NASA PAIN H=1 | 85.7399 | 85.9024 | +0.1625 |
| `REPRO_18b` | vs NASA PAIN H=2 | 78.7400 | 78.3484 | −0.3916 |
| `REPRO_18b` | vs NASA PAIN H=3 | 80.0648 | 79.8177 | −0.2471 |
| `T1` | H1 SPL | 84.0500 | 84.2102 | +0.1602 |
| `T1` | H2 SPL | 78.0087 | 77.6557 | −0.3530 |
| `T1` | H3 SPL | 78.3036 | 78.0594 | −0.2442 |
| `T2` | 1/3-oct 1250 Hz | 55.9664 | 55.9168 | −0.0496 |
| `T2` | 1/3-oct 1600 Hz | 53.6320 | 53.5588 | −0.0733 |
| `T2` | 1/3-oct 2000 Hz | 51.6674 | 51.5851 | −0.0824 |
| `T2_EQ19` | 1/3-oct 1250 Hz | 38.5891 | 38.5590 | −0.0301 |
| `T2_EQ19` | 1/3-oct 1600 Hz | 35.8660 | 35.8119 | −0.0541 |
| `T2_EQ19` | 1/3-oct 2000 Hz | 34.9407 | 34.8743 | −0.0665 |
| `E18_TONES` | H1 | 89.0239 | 88.6743 | −0.3495 |
| `E18_TONES` | H2 | 78.1404 | 77.7801 | −0.3604 |
| `E18_TONES` | H3 | 77.7016 | 77.5530 | −0.1487 |
| `E21_E22_NR` | max \|Δ\| on table | — | — | 0.9491 (largest move) |
| `MRP_RITZ` | n within 5 % / 32 | 26 | 29 | +3 |
| `MRP_APPD` | n within 5 % / 32 | 24 | 27 | +3 |
| `MRP_APPD` | Fig. D-2 max \|Δw\| | 1.4507 | 1.4534 | +0.0027 |
| `phase38b` | `:auto` H1 / H2 / H3 | 85.74 / 16.89 / 72.31 | 85.90 / 16.81 / 72.24 | (see report) |

## Phase 17 baselines (`data/baselines/phase17_baselines.csv`)

Re-frozen 2026-10-22 at L = 1.83 m. Header: `Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)`.

| name | before @ 1.803 m | after @ 1.83 m | Δ |
|------|------------------|----------------|---|
| `spl_bare_H1` | 93.60561796 | 92.99090643 | −0.6147 |
| `psiG_H1_mode1` | 0.1753714208 | 0.1764143506 | +0.001043 |

(Full CSV re-recorded; all keys regenerated with the new default length.)

## Source

Built from `length_sensitivity.md` (2026-10-22 post-hoc sensitivity) plus regenerated `phase17_baselines.csv` / validation reports at L = 1.83 m.
