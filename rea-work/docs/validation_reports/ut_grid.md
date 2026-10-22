# UT_GRID — skin grid vs User Manual Fig. 3

**Date:** 2026-10-22  
**Label:** Unit test with visualization  
**Criterion:** computed `x1`, `x2`, `x3`, and `θ` at sample `(k, ℓ)` points match User Manual Fig. 3 formulas within `1e-9`.

Runnable case `_run_ut_grid` in `validation_case_extras.jl`. Figure: `docs/validation_reports/figures/UT_GRID.png` (160 points on the unrolled cylinder, coloured by incidence angle γ; propeller plane and ℓ = 1 marked). Existing Pkg.test suites "Grid geometry" and "Grid azimuth" are unchanged.
