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
