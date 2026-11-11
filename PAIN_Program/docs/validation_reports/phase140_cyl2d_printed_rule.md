# Phase 140: CYL2D's grid rule as NASA printed it (2026-11-10)

Decided by Claude under the author's delegation of 2026-11-10 ([CONFIRM] step 140a″). The basis is the document, not a comparison.

## The rule (CR-165869, report pp. 60–62)
- Grid: NK = Integral Part[7(1 + cos θ₀)] intervals from floor to crown, h = a(1 + cos θ₀)/NK.
- Cabin points: every point inside the circle; on each grid row, the nearer to the wall of the last point inside and the first point outside; the same on each grid column (upper arc, and the lower arc beside the floor where X > a sin θ₀).

## 140a′: the rule against the code's earlier rule (r ≤ 1 + 0.4h, NY = 10), half-cabin nodes, no run

| θ₀ | NK | earlier rule on NK | printed rule | nodes that differ |
|---|---|---|---|---|
| 50° | 11 | 78 | 79 | (7, 3): 0.4h leaves it out; 0.45h and 0.5h agree |
| 56.6° | 10 | 68 | 68 | none |
| 62.6° | 10 | 74 | 74 | none |
| 73.7° | 8 | 55 | 55 | none |

So at the test article's angle the printed rule is the earlier grid exactly, and CYL2D_C1, APPB_EPS_N and CABIN_FREQ_PRINTED cannot move. The earlier draft of this table in `phase136_144_preparation.md` (three nodes differing) read the rule as an intersection of row and column limits; the page says each test adds a point, so the cabin is the union. That draft is superseded.

**User Manual §5.1, re-read 2026-11-11.** CYL2D's only input card is the floor angle; the modes are computed for a = 1 m and q = 0; "Appendix C of Ref. [2] may be consulted" for the calculation. No grid size or node rule is printed, so nothing contradicts CR-165869: a grid fixed by the floor angle alone is what its rule gives. The manual lists the IMSL routines CYL2D calls (EIGRF, LINV2F, VMULFF, VSRTR, VSRTU): EIGRF returns the eigenvalues of a real general matrix, complex pairs included, and the manual does not say what is done with them (ISSUE-033, question 1).

## 140a″: adopted
`pain_settings().cyl2d_grid_rule = :printed` (default) in `src/cyl2d.jl`; `:threshold` keeps the earlier rule with `cyl2d_node_tol`. A grid size of 0 (the new default of the pipeline and of `cyl2d_modes`) means the printed NK. The uncertainty budget's node-rule row still samples the earlier rule's 0.32h–0.47h window explicitly (`rule = :threshold`); with the printed rule there is no node choice left.

Re-runs after the change, criteria unchanged:

| Case | Before | After |
|---|---|---|
| CYL2D_C1 | met 59/59 | met 59/59 |
| APPB_EPS_N | met 48/48 | met 48/48 |
| CABIN_FREQ_PRINTED | met 47/47 | met 47/47 |
| CYL2D_PRINTED | not met (rule "0.45h, NY = 10 else the next grid"), 57/168 | **not met** on the shipped rule |

CYL2D_PRINTED on the shipped rule (run 2026-11-10; both printed lists were seen before, so the run is labelled as made after a documented rule was adopted; the result stands):
- narrow body (73.7°, NK = 8): ε(0,0) 0.97539 against 0.9754; 61/61 2-D frequencies within 0.1 %; types 61/61;
- small diameter (62.6°, NK = 10): this code's App. C eigenproblem fails its own real-eigenvalue check on NASA's grid (largest |Im|/|Re| 0.0012 against the 0.001 of Q60), so the next solvable grid, NY = 12, is used: 0/53 within 0.1 %, types 37/53;
- Merlin IVC (50°, NK = 11, seen): 51/51.

The case is back on the chart (it runs the shipped code). Its cause record: the real-eigenvalue check of this recreation rejects NASA's 62.6° grid. The check's threshold is not changed here: it would be chosen after seeing this result.
