# Task — make 1.83 m the single test-article length (decision I-22, 2026-10-22), re-record affected results post-hoc

Repo `D:\code\PAIN\rea-work\PAIN.jl`. Read `D:\code\PAIN\CLAUDE.md` and `rea-work/docs/IMPLEMENTATION_PLAN.md` ("I-22 decision", "I-22 length sensitivity"); the override `TEST_ARTICLE_L` / `test_article_length()` exists in `geometry.jl`.
**Change the default to 1.83 m.** The App. D solver, Table D-1 seeds (`mrp.jl`), `phase3_trim`, cabin volume, pipeline defaults, NR inputs, GUI `L`/`L_c`, `examples/*.json` that carry `L_m = 1.803` for the **test article**
(leave aircraft-scale examples such as the Hartzell one alone: they are not the test article), and the docs (`VALIDATION_GUIDELINE` parameter tables that say 1.803 m, README, METHODOLOGY, flowchart) all follow 1.83 m.
The Table D-1 data (frequencies, shapes) are NASA's printed numbers and do not change; its title says 1.803 m (caption typo, see plan) — note that in the data README / the CSV header comment only.
No criterion, tolerance, reference CSV or digitized data changes. No parameter is adjusted toward any comparison. **Recorded results are re-recorded by regenerating them with the new length** (reports in `docs/validation_reports`,
frozen baselines `data/baselines/phase17_baselines.csv` and friends, test expectations that hard-code old numbers): every regenerated report/baseline/test constant gets a header line
"Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)". Keep the old values in the new file `docs/validation_reports/length_rerecord_before_after.md`
(case, quantity, before at 1.803 m, after at 1.83 m, verdict before/after), built from `length_sensitivity.md` plus the baselines you regenerate. Verdict flips, if any, are reported prominently; do not undo them.
No commit. Never open a GUI window. Do not write IMPLEMENTATION_PLAN entries (the reviewer does). Update README / flowchart / METHODOLOGY / VALIDATION_GUIDELINE. Leave no helper scripts in the repo.
Tests: update expectations that hard-code old numbers only where the length is the cause (state each), run the full set of affected testsets and "Validation case registry" via `Pkg.test("PAIN"; test_args=[...])`; the reviewer runs the full suite.
The length-override testset ("Length override") must keep passing (it tests the override, adjust only what the new default requires).
Report: files changed, re-recorded baselines/reports, the before/after table, any verdict flips.
