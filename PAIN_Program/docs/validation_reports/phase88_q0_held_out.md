# Phase 88 — the q = 0 hypothesis on CR-3813's printed runs (2026-10-29)

Hypothesis H0, held-out set and decision fixed 2026-10-29 before the runs (`IMPLEMENTATION_PLAN.md` §8ae): NASA's program
gave the q = 0 cabin modes no structural coupling (f₀M = 0). Runs: pre-correction form (all three CR-172428 App. A changes
reverted) with `q0_coupled = false`. Diagnostics (no verdict, off the map); outcomes recorded as run.

| Step | Case | Criterion | Result | q = 0 coupled (as before) |
|---|---|---|---|---|
| 88a | Q0_REPRO_18b | ±4 dB at H1–H3 vs E-16 NASA (79.0, 75.5, 68.0) | 2/3: 75.86, 75.99, 80.93 dB | 85.11, 77.61, 81.85 dB |
| 88b | Q0_E18 | ±4 dB per harmonic vs E-18 NASA (88.0, 75.0, 67.0) | 1/3: 83.70, 75.44, 78.23 dB | 87.88, 77.06, 79.31 dB |
| 88c | Q0_E21 | ±3 dB in ≥ 75 % of counted bands vs E-21 NASA | 1/4 | 1/4 (E21_PRE) |

**Decision (fixed before the runs: supported only if all three are met).** H0 is **refuted**. It moves E-16 H1 toward
NASA and E-18 H1 away from it, and leaves H3 11–13 dB high in both. No variant of H0 is tried. `q0_coupled` stays a
diagnostic input (default true).
