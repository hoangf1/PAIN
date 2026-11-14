# Phase 152: the search for R996_LOADS's section data, and a scan of every case on the coverage chart (2026-11-14)

Done by Claude, under the author's authority of 2026-11-14 ("if its not the exact data then just say inputs couldnt be found and move on"). No criterion, tolerance, reference file or verdict changed.

## 1. ISSUE-030: the inputs could not be found

`R996_LOADS` needs measured lift and drag of the blade's own sections (NACA 16-series, design lift 0.13–0.50, thickness 13.4 % at the root falling to 0 at the tip) at the section Mach numbers of the static runs. Searched 2026-11-14:

| Source | What it holds | Why it is not the data |
|---|---|---|
| NACA TN 1546 (in `references/`) | 24 sections, 6–30 % thick, Mach 0.3 to about 0.8 | Nothing under 6 % thick (the outer 15 % of the blade) and nothing below Mach 0.3 (the inner span at tip Mach 0.45). All 24 together cover 30–76 % of the span (Phase 141d) |
| NACA TN 976, Stack (NTRS 19930081766) | The first 16-series tests: 16-009, 16-106, 16-109, 16-509, 16-521, 16-530, 16-709, 16-1009, from Mach 0.25, same tunnel | The same thickness limit; no section the blade's tip or root needs that TN 1546 lacks |
| NASA CR, Korkan: airfoil data banks for Clark-Y, NACA 4-digit and 16-series (NTRS 19860021221) | A look-up program for 4–21 % thick sections, Mach 0.3–1.6 | A fit that extrapolates beyond the measurements: not measured data |
| NACA RM L9G06a (NTRS 19930085929) and NACA Report 1012 (NTRS 19930092067) | Thrust, power and efficiency of this same blade in forward flight | Propeller loads, not section data: a new test of the loads (ISSUE-042, Phase 153), not a fix of this one |
| CFD polars of higher fidelity than XFOIL | — | Not available here; none is published for these sections |

**Decision.** The exact data does not exist in the published record, so ISSUE-030 is closed as *inputs could not be found*. A polar set that is measured on part of the span and XFOIL on the rest would need a join chosen by this recreation, which is not the data either. `R996_LOADS` stays not met 24/32, with its cause as recorded (XFOIL's section drag about 25 % low).

## 2. The scan: every case with a verdict

| Case | Now | What is left | Action |
|---|---|---|---|
| `R996_LOADS` | not met 24/32 | measured section data that is not published | none possible (above) |
| `PER_FIG8` | not met 10/14 | nothing: Pereira's CFD misses the same gate (12/14) | text corrected (this phase) |
| `R172428_EXP` | not met 5/9 | nothing: NASA's PAIN printout misses the same gate (5/9) and this code matches that printout | text corrected (this phase) |
| `NR_TP1964_XOVER` | not met 9/18 | nothing: the misses are the Eq. (18) bands, a property of PAIN's equation | text corrected (this phase) |
| `CYL2D_PRINTED` | not met 63/116 | one common factor of 1.00305 at 62.6° that no printed input gives | none: choosing a radius or sound speed from the result would be tuning (ISSUE-033) |
| The 14 met cases | met | — | none |

The three "chart label (ISSUE-031)" entries in the why-not-met table were out of date: that ticket closed on 2026-11-12. They now say that nothing is left.

## 3. The scan: the cases without a verdict

- **Diagnostic re-runs (16), post-hoc (1):** each names the case that carries its verdict. Nothing to fix.
- **Inputs not printed (11):** the missing inputs are the Aero Commander and 695A blades, the 695A cabin section and stiffeners, TP-2444's lining table, the Phase III trim's facing side, and NASA's unprinted routines. None was found in the sources searched on 2026-11-09 and 2026-11-14.
- **No criterion (8), information (2):** displays and unit checks.

## 4. What the chart lacks, and what was found for it

The blade loads have one test against measurement, and it is static (`R996_LOADS`). Forward-flight loads are shown only at Pereira's one condition, without a criterion (`PER_LOADS`). NACA Report 1012 prints thrust and power coefficients of the Report 996 blade against advance ratio for blade angles 20° to 60°: every input printed, compared with measurement, and no polar in this repository was built from it. That is Phase 153 (ISSUE-042).

No further source was found for the other gaps (a full chain from blade to cabin with every input printed; the cabin bands and dB(A) against measurement with a printed lining).
