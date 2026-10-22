# Task — test-article length sensitivity (L = 1.803 m vs 1.83 m), post-hoc, report only

Repo `D:\code\PAIN\rea-work\PAIN.jl`. Read `D:\code\PAIN\CLAUDE.md` and `rea-work/docs/IMPLEMENTATION_PLAN.md` ("I-22 check"). The Methodology prints the test-article length as 1.803 m (71 in.) in the
Table D-1 title and 1.83 m (72 in.) in App. D text, App. E and the validation report. This task measures how much the recorded results depend on that choice. **It does not choose a length and changes no
recorded result, default, criterion or reference file.** Everything produced is labelled "post-hoc sensitivity, 2026-10-22; no length selected on the basis of any error". No commit. Never open a GUI window.
Do not write IMPLEMENTATION_PLAN entries (the reviewer does); update README / flowchart / METHODOLOGY / VALIDATION_GUIDELINE briefly for what you add. Do not edit reference/digitized CSVs or existing validation
reports (new ones only). Do not touch regenerated figure PDFs. Leave no helper scripts in the repo except the one named below.

## What to build
1. A single override for the test-article length used by the cases that today hard-code `1.803` (`validation_case_extras.jl`, `noise_reduction.jl`, `trim_loss.jl` `phase3_trim`, `PAIN.jl` pipeline default,
   `mrp.jl` table-D-1 seeds, `gui_model.jl`, the App. D test-article geometry): e.g. a module-level `TEST_ARTICLE_L = Ref(1.803)` read through one accessor `test_article_length()`, with default 1.803 so that
   **every existing output is bit-identical** (verify by running the Validation case registry testset unchanged). The App. D solver keeps its own default 1.83 unless the override is set (then it follows the override).
   Also make the cavity length L_c default follow it. Do not change the Table D-1 data, its seeds' numbers, or any criterion.
2. `scripts/run/length_sensitivity.jl`: for every runnable validation case whose result depends on the test-article geometry (REPRO_18b, T1, T2, T2_EQ19, E21_E22_NR, E18_TONES, E15_STRUCT_LOSS, MRP_RITZ, MRP_APPD,
   E-13/E-14 trim-loss cases, CYL2D_C1 if it uses L, and any other case that reads the length — decide by search, list them), run under L = 1.803 and L = 1.83 and write
   `docs/validation_reports/length_sensitivity.md`: per case the headline numbers and verdict at each length, the difference, and whether the verdict changes. Keep the override scoped to the run (restore the default
   afterwards even on error).
3. A V-UNIT testset "Length override": default 1.803 gives identical numbers to the unmodified path (compare a few computed values exactly); setting 1.83 changes cabin volume proportionally; the override is restored.

Run only that testset and "Validation case registry" via `Pkg.test("PAIN"; test_args=[...])`; run the sensitivity script once. Do not run the full suite. Report: cases found and run, and the table of verdicts at both lengths.
