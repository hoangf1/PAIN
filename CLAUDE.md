## Current focus: Cabin_Noise (low-fidelity cabin noise tool)

Work happens in Cabin_Noise\ unless the task names PAIN_Program. PAIN_Program (the PAIN recreation, formerly rea-work) is paused; leave it untouched.

For every Cabin_Noise code change update:
Cabin_Noise\README.md
Cabin_Noise\projectPlan.md (the "Implementation notes" section: milestone status and every deviation from the plan text)
Cabin_Noise\cabin_noise\data\validation\cases.yaml when a case, quantity or criterion is added (criteria are dated and fixed before any comparison)
Cabin_Noise\docs\latex after any Cabin_Noise .md change (`python scripts/md_to_latex.py`, `--mmdc` when a Mermaid diagram changed)

A Cabin_Noise validation case may carry a met / not-met verdict only if it compares with experimental data (V4-V7: NASA TM-85722, CR-178004), run from a project file built only from the report's stated inputs. Analytic limits, laws and internal consistency (V0a-V3) are verification: "check ok / failed", never a verdict.

Checks for Cabin_Noise (step 3 below), from Cabin_Noise\ with its .venv:
- Core or tests: `.venv/Scripts/python -m pytest -q`
- GUI: `.venv/Scripts/python scripts/smoke_gui.py`, plus a look at the window

## Rules for all code in this repo

No calibration that makes a test pass by construction: never fit, scale, tune, select or clip any parameter, input, polar, option, sign or digitized value using the data a test case is compared against, and never compare a calibrated path with the data it was calibrated to; pass criteria are fixed and dated before the comparison, and any value chosen after seeing a result makes that result post-hoc (calibrated), not a pass.

Add a test or a validation case only if it helps (author 2026-11-10): it must answer a question that no existing test or case answers, and it must fail if the behaviour were wrong. A validation case, in addition, runs the code as shipped, has every input printed or measured, can carry a verdict under its project's rule, has an outcome that cannot be told in advance from the existing cases, and rests on data whose own scatter or reading error is clearly smaller than the tolerance. A variant or a sum of an existing case is a row of that case, not a new case. A diagnostic that answers one question is a script whose result goes in a report: it is not registered as a case and gets no test that asserts its outcome, and once the question is answered its runner is removed and the report kept. Do not add a file, document section or figure that repeats what another already holds.

Before a code change is accepted or built on, whoever made it (any agent or session):
1. Diff: review every changed file; revert any edit outside the files the task names.
2. Rules: confirm no criterion, tolerance, reference/digitized data file, recorded result or fitted parameter changed unless the task named it, and that any re-stated check carries a dated post-hoc label (rule above).
3. Run: run the affected checks (listed per project) and read the output.
4. Numbers: spot-check reported numbers against the recorded results (Cabin_Noise: the README / projectPlan notes; PAIN: PAIN_Program\docs\validation_reports).
5. Docs: confirm the project's documents listed here were updated for the change.
6. Substance: for every new or changed test, confirm it would fail if the behaviour were wrong (no test that compares a function with itself or passes by construction); for physics changes, confirm the change has the intended physical effect.
7. Labels: check that every user-facing label, unit and verdict text says what the number is (criterion vs no criterion, units from the case's own definition).
8. Before commit: run /code-review on the diff and fix or explicitly skip each finding; no stray helper scripts, regenerated figures, or machine-specific paths remain; tests write only to the temp output dir.
A failed check is fixed before the next task starts; one writer at a time on the checkout, counting every agent and Claude session.

## PAIN_Program (paused)

For every PAIN code change update all documents:
PAIN_Program\README.md
PAIN_Program\docs\flowchart.md
PAIN_Program\docs\IMPLEMENTATION_PLAN.md
Once task is completed mark as done and move the completed phase to the bottom of PAIN_Program\docs\COMPLETED_PHASES.md with the rest of the other phases (its queue row to that file's §3); IMPLEMENTATION_PLAN.md keeps only the rules, the open queue and the references.
PAIN_Program\docs\METHODOLOGY.md
PAIN_Program\docs\VALIDATION_GUIDELINE.md
Cases without a verdict (information, verification, diagnostic re-runs, displays) stay off the validation map; PAIN_Program\docs\NO_VERDICT_CASES.md lists them and is regenerated with §0 (scripts\run\write_case_error_summary.jl or regenerate_case_figures.jl).

A PAIN validation case is meaningful, and may carry a met / not-met verdict, only if it (E) compares with experimental data, or (P) checks that the code works exactly like PAIN: given PAIN's own inputs (from PAIN's sources: CR-3813, the User Manual, CR-172428 and the reports they cite for their data) or experimental inputs, it reproduces what PAIN printed. A check against anything else (an analytic limit, a law, a different method or report, a property of a printed table, internal consistency) is verification: it may stay as an information case (no verdict) or a unit test, never a verdict on the validation map (rule 2026-10-29, Phase 82; list in PAIN.jl\src\validation_cases.jl INFORMATION_ONLY_CASES). A case that runs a program form or option that is not what the tool ships (for example CR-3813's printed form) has no verdict and stays off the coverage map, whatever its result (author 2026-11-09; wording approved 2026-11-10, Phase 136c; list in DIAGNOSTIC_CASES).

PAIN checks (step 3): code in PAIN.jl\src or test: the affected testsets of `julia --project=. -e "using Pkg; Pkg.test()"` from PAIN_Program\PAIN.jl. GUI code: scripts\smoke\smoke_gui_model.jl and scripts\smoke\smoke_qml_load.jl, plus a look at the window.
