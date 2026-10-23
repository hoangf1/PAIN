For every code change update all documents:
rea-work\README.md
rea-work\docs\flowchart.md
rea-work\docs\IMPLEMENTATION_PLAN.md
Once task is completed mark as done and move the completed phase to the bottom with the rest of the other phases.
rea-work\docs\METHODOLOGY.md
rea-work\docs\VALIDATION_GUIDELINE.md

No calibration that makes a test pass by construction: never fit, scale, tune, select or clip any parameter, input, polar, option, sign or digitized value using the data a test case is compared against, and never compare a calibrated path with the data it was calibrated to; pass criteria are fixed and dated before the comparison, and any value chosen after seeing a result makes that result post-hoc (calibrated), not a pass.

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