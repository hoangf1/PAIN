# Task 38g — CR-3813 Appendix D structural solver (Eqs. D.17–D.26), new module, no fitted scale

Repo `D:\code\PAIN\rea-work\PAIN.jl`. Read `D:\code\PAIN\CLAUDE.md`, `rea-work/docs/IMPLEMENTATION_PLAN.md` §8 Phase 38 row 38g, the "Plan for 38f–38h" paragraph (**criterion fixed
2026-10-22 before any run; do not change it**), the 19g/37d records (METHODOLOGY "Eqs. (D.22)–(D.26)" bullet; `validation_reports/fig_d2_check.md`, `mrp_ritz_vs_d1.md`) and `src/mrp.jl` (the
existing raw Ritz solver, a fitted surrogate seeded by Table D-1 shapes: **leave it and its defaults untouched**).
Source: `rea-work/references/Pain Methodology.pdf`, Appendix D (find the pages with `pdftotext` or the Poppler helper; Table D-1 is `data/cr3813/digitized_table_D1.csv`, Fig. D-2 shape
`data/cr3813/fig_d2_mode1_digitized.csv`). Read the printed equations yourself and transcribe them into code comments as printed: the displacement fields u, v, w, the compatibility /
continuity constraints (D.17)–(D.21) at the stiffener/skin junctions, the energy expressions and the eigenproblem (D.22)–(D.26) as printed. State every reading you decided and why.

## Rules (no calibration)
No parameter, scale, spring constant, mode seed or option is chosen, fitted or tuned using Table D-1, Fig. D-2 or any NASA/measured number. Inputs are the physical geometry and material
properties of the test article **as stated in Appendix D / CR-3813** (skin thickness, stringer and frame cross-sections, spacing, E, ρ, ν) — take them from the text and cite the page; where the
program already holds them (`MRP_*` constants) reuse them, and where the text and the constants differ say so and use the text. The comparison with Table D-1 is made **once, after the
unit tests pass, and nothing is changed afterwards**; a miss is recorded as a miss.

## Code
- New `src/mrp_appd.jl` (include/export; do not edit `mrp.jl` behaviour): `appd_modes(geometry; n_modes, ...)` returning frequencies, generalized masses M_r and the shape data the program needs
  (same fields the downstream code reads from a `StructuralMode`/mode set, so a mode set from the new solver can be passed as `inp.structural` without other changes), and a selector wherever
  the structural mode set is built for the test article (default stays the current Table-D-1-seeded surrogate; new value e.g. `structural_solver=:appd`). Any geometry (radius, length, thickness,
  stiffener layout) is an input; the test article is the example.
- New case `MRP_APPD` in the validation registry (follow `MRP_RITZ` / `E15_STRUCT_LOSS`): lists, per Table D-1 mode, the computed frequency, NASA frequency, percent difference and whether
  within 5 %; verdict `:met` if **at least 75 % of the 32 modes** are within 5 % **and** no calibration input was used (the count rule is fixed here, 2026-10-22, before any run; the 5 % is the plan row's);
  Fig. D-2 mode-1 shape compared at the digitized points, reported **without** a pass mark. Label "V-CODE (vs NASA's solver outputs), first run of the printed App. D formulation 2026-10-22".

## Tests (V-UNIT, before the Table D-1 comparison)
1. Unstiffened closed circular cylindrical shell: lowest frequencies for several (m, n) against the closed-form Donnell–Mushtari / Flügge result (give the formula and its source in the test;
   tolerance stated, e.g. 1 %); simply supported ends.
2. Flat-plate / large-radius limit and ring-stiffened or stringer-stiffened limit: added stiffness raises frequencies in the expected direction; a smeared-stiffener analytic estimate agrees within
   the tolerance you state.
3. Generalized-mass normalization: ∫ ρ_s φ² dA over the shape equals M_r for the returned shapes; orthogonality of distinct modes (1e-8).
4. Compatibility constraints (D.17)–(D.21) are satisfied by the returned fields at the junctions to 1e-8.
5. The surrogate default path is unchanged (existing `MRP_RITZ` numbers and all Registry results identical).
Run only the new testset and "Validation case registry" via `Pkg.test("PAIN"; test_args=[...])`; do not run the full suite. No commit. Never open a GUI window. Do not write IMPLEMENTATION_PLAN entries
(the reviewer does); update README / flowchart / METHODOLOGY / VALIDATION_GUIDELINE (new case in the registry list). Do not edit reference/digitized CSVs or existing validation reports (new ones only).
Do not touch regenerated figure PDFs. Leave no helper scripts in the repo.
Report: the equations as implemented and every reading decided, the input values with their page citations, the unit-test results, and — once, after the tests — the 32-mode table, the count and the verdict.
