# Cabin_Noise: verification of the paper pipeline

**Date:** 2026-11-02. **Tests:** `pytest` runs 45 tests.

Every block is checked against something outside its own code path:
- its paper's own equations, solved another way;
- a published table;
- a physical identity.

METHOD.md lists the methods and sources.

| Check | Against | Result |
|---|---|---|
| V0a: Gutin closed form | direct quadrature of the rotating-dipole integral it is derived from | 1e-12 dB |
| Gutin far field | independent time-domain moving-force solution (Lowson 1965), `tests/independent.py` | 0.1 dB |
| V1: CR-132602 eq. (46) | 0-90 deg integral of eq. (45) | 1e-9 dB |
| V2: CR-132602 eq. (52) | numeric solution of the report's power balance, eq. (47) | 1e-14 dB (also shows the 2/eps of eq. (53) is a misprint) |
| Pipeline NR | eq. (52) / single-wall form written out | 1e-12 dB |
| Openings | TM-85722 eq. (1) written out | 1e-12 dB |
| V3: insertion loss | TM-85722 IL = dTL + dABS | 0.33 dB (the "1 +" term) |
| Goody | the source's asymptotic slopes (w^2, about w^-0.7, w^-5) | pass |
| Diffuse wall factor | Monte Carlo of random plane waves at a rigid wall (Waterhouse) | 2.0 within 10 % |
| Seat statistic | 95th percentile of an exponential sample | 0.05 dB |
| ISA, Sutherland, IEC 61672 A / C, Sabine | published tables / constants | pass |
| End to end | default case recomputed independently (tone, 1 kHz band, totals) | 0.01-0.05 dB |
| Validation map | every case under exactly one block; consistent edges | pass |

Run: `.venv/Scripts/python -m pytest -q` (all) and `.venv/Scripts/python scripts/smoke_gui.py` (GUI).
