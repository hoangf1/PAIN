For every code change update all documents:
rea-work\README.md
rea-work\docs\flowchart.md
rea-work\docs\IMPLEMENTATION_PLAN.md
Once task is completed mark as done and move the completed phase to the bottom of rea-work\docs\COMPLETED_PHASES.md with the rest of the other phases (its queue row to that file's §3); IMPLEMENTATION_PLAN.md keeps only the rules, the open queue and the references.
rea-work\docs\METHODOLOGY.md
rea-work\docs\VALIDATION_GUIDELINE.md
Cases without a verdict (information, verification, diagnostic re-runs, displays) stay off the validation map; rea-work\docs\NO_VERDICT_CASES.md lists them and is regenerated with §0 (scripts\run\write_case_error_summary.jl or regenerate_case_figures.jl).

No calibration that makes a test pass by construction: never fit, scale, tune, select or clip any parameter, input, polar, option, sign or digitized value using the data a test case is compared against, and never compare a calibrated path with the data it was calibrated to; pass criteria are fixed and dated before the comparison, and any value chosen after seeing a result makes that result post-hoc (calibrated), not a pass.

A validation case is meaningful, and may carry a met / not-met verdict, only if it (E) compares with experimental data, or (P) checks that the code works exactly like PAIN: given PAIN's own inputs (from PAIN's sources: CR-3813, the User Manual, CR-172428 and the reports they cite for their data) or experimental inputs, it reproduces what PAIN printed. A check against anything else (an analytic limit, a law, a different method or report, a property of a printed table, internal consistency) is verification: it may stay as an information case (no verdict) or a unit test, never a verdict on the validation map (rule 2026-10-29, Phase 82; list in PAIN.jl\src\validation_cases.jl INFORMATION_ONLY_CASES).

Code changes delegated to Cursor (scripts\cursor-exec.ps1, write mode) must be checked before they are accepted or built on. After every Cursor run:
1. Diff: snapshot the files before the run and review every changed file against it; revert or redo any edit outside the files the task names.
2. Rules: confirm no criterion, tolerance, reference/digitized data file, recorded result or fitted parameter changed unless the task named it, and that any re-stated check carries a dated post-hoc label (rule above).
3. Run: run the affected checks yourself and read the output; do not rely on Cursor's report. Code in PAIN.jl\src or test: `julia --project=. -e "using Pkg; Pkg.test()"` from rea-work\PAIN.jl. GUI code: scripts\smoke\smoke_gui_model.jl and scripts\smoke\smoke_qml_load.jl, plus a look at the window.
4. Numbers: spot-check the numbers Cursor reports against the recorded reports in rea-work\docs\validation_reports.
5. Docs: confirm the five documents above were updated for the change.
6. Substance: for every new or changed test, confirm it would fail if the behaviour were wrong (no test that compares a function with itself or passes by construction); for physics changes, confirm the change has the intended physical effect.
7. Labels: check that every user-facing label, unit and verdict text says what the number is (criterion vs no criterion, units from the case's own definition).
8. Interrupted run: if a Cursor run stops early, review its partial edits like a finished run, then re-send with "resume from the edits in the tree".
9. Before commit: run /code-review on the diff and fix or explicitly skip each finding; no stray helper scripts, regenerated figures, or machine-specific paths remain; tests write only to the temp output dir.
A failed check is fixed (or the task re-sent to Cursor with the failure) before the next task starts; one Cursor writer at a time, and "one writer" counts every agent on the checkout, including other Claude sessions.