# Phase 150: paths, the retired cases, and the file layout (2026-11-11)

Decided by Claude under the author's authority of 2026-11-10 and 2026-11-11 ("you do not need my permission until all phases are done"). No verdict, criterion, tolerance or reference file changed. The 20 cases with a verdict and their counts are unchanged.

## 150c, 150d Paths

- `scripts/retired/` was already gone (Phase 150c, 2026-11-10).
- **`.gitignore` still named `rea-work/`.** So since the folder was renamed, the GUI's frame cache, the website output and the data scratch folder were not ignored. All three now name `PAIN_Program/`. The 16 cache frames that had been committed were untracked; the files stay on disk.
- Two script header comments still said "Run from rea-work\PAIN.jl". Both are fixed.
- The GUI model smoke wrote two case figures into `docs/`. It now writes them to a temp folder (CLAUDE.md step 8).

## 150e The cases without a verdict: 48 retired

The list is ISSUE-029's, approved by the author on 2026-11-10. Each retired case is in `RETIRED_CASES` (`validation_cases.jl`) with its reason and the report that stays.

What retiring removed for each case:
- the case from the registry and the GUI list;
- its record in `CASE_RECORDS.md`;
- its row in `case_error_summary.csv`;
- its figures;
- the tests that assert its old outcome.

A test fails if a retired case is still registered, or if it names a report that does not exist.

| Group | Cases | Runner |
|---|---|---|
| Diagnostic re-runs, refuted (19) | REPRO_18b_PRE, E21_PRE, the six 300-mode re-runs, Q0_REPRO_18b, Q0_E18, Q0_E21, R172428_CODE_ETAN, BAND_REPRO_18b, BAND_E18, R172428_CODE_Q0, R172428_CODE_Q0_ETAN, APPB_PAIRS, APPB_PAIRS_Q0_ETAN, FLIGHT10_FLOOR_SIGN | removed. Four whole files went (`validation_case_iso83`, `_iso92`, `_iso99`, `_iso108`), together with the helper tests that only served them. |
| The T1/T2 family on CR-3813's unprinted off-line field (12) | T1, T1_FROM_E12, T1_MEAS_DAMPING, T1_F1A_FILL, T1_F1A_MEAS_DAMP, H3_ATTRIB, GEXT_BOUND, REPRO_18b, E18_TONES, UNC_COVER, T2, T2_EQ19 | unregistered. The runners stay, because `run_pain.jl`, the frozen-baseline regression (R11) and the REPRO_18b level regression still call them. `write_h3_attribution_report` was removed. |
| Exterior broadband not measured, or an assumed blade (7) | T2_MEAS_EXT, T2_MEAS_EXT_BR, T2_PRED_BB, PROP_BB_FIG14, PROP_BB_FIG17, BBN_LONG, BBN_LEVELS | unregistered; the broadband and BBN code stays |
| Checks that hold by construction, or repeat others (10) | E11_FREEFIELD, FF_E11_MAP, MRP_SHAPE_NORM, CYL2D_WEYL, LOUDEST_PT, SHARP_PANEL_D, PER_FIG6, MRP_RITZ, MRP_COUPLED_LIMITS, R172428_PAIRS | unregistered |

Decisions on the cases the list kept "until" a phase:
- **MRP_COUPLED_LIMITS: retired.** Twelve of its 78 rows miss by design, so rewriting it would mean writing a new case.
- **R172428_PAIRS: retired.** Phase 136 is done.
- **E15_STRUCT_LOSS and R172428_TRIM: kept on the shown list.** They are the evidence for ISSUE-032, which is still open.
- **R996_FIG10_CIRC: kept as information.** That was Phase 144's decision.
- **BPM_RP1218 and SHARP_PANEL_D_SHAPE: kept.** The broadband and sound-bridge code they test still ships.

`scripts/run/length_sensitivity.jl` ran the retired T1/T2 cases by name. It was removed; its report `length_sensitivity.md` stays.

Registry: 147 cases before, 99 now; `CASE_RECORDS.md` holds 102 records (the three package-test entries have no runner).

## Not done in this phase (ISSUE-040)

- **150b, the per-stage layout.** The mapping table (150a) is below. 13 of the 26 case files hold cases from more than one stage, so the move would split files function by function, and `runtests.jl` (3,900 lines) would be split by hand. It changes no behaviour and needs a full suite run of its own.
- **The 44 "test only" cases** (ISSUE-029). They are meant to leave the GUI list and the records and keep their tests. The registry rule "every registered case is listed" changes for them, and many unit tests use them as stand-ins. Until then they stay listed in `NO_VERDICT_CASES.md` as information.

## 150a Mapping, old file → stage file (by where each case's chain span ends)

| File | Lines | Cases | Stage file(s) |
|---|---:|---|---|
| `loudest_point.jl` | 300 | LOUDEST_PT_GRID | interior_tones |
| `validation_case_extras.jl` | 2,662 | 27 cases and the registry | every stage, and registry.jl |
| `validation_case_iso100.jl` | 58 | R172428_TRIM_DECK | damping_trim |
| `validation_case_iso101.jl` | 83 | FLIGHT_MODES | wall_modes |
| `validation_case_iso102.jl` | 96 | FLIGHT10_H234 | interior_tones |
| `validation_case_iso105.jl`, `_iso106.jl` | 72, 61 | CYL2D_PRINTED, CABIN_FREQ_PRINTED | cabin_modes |
| `validation_case_iso119.jl` | 61 | T1_APPB, T1_MEAS_DAMPING_APPB | interior_tones |
| `validation_case_iso121.jl` | 481 | the four AC_C695A cases | skin_field, interior_tones, bands_dba |
| `validation_case_iso40.jl` | 990 | eleven isolation checks | free_field to bands_dba |
| `validation_case_iso41.jl` | 807 | TRIM_CLOSED, NR_BAND_HAND, HF_MASSLAW, BEMT_HAND, F1A_INDEP | blade_loads, free_field, damping_trim, bands_dba |
| `validation_case_iso43.jl`, `_iso45.jl`, `_iso47.jl`, `_iso59.jl`, `_iso61.jl` | 506, 97, 226, 122, 41 | the TP-1964 and TP-2444 cases, SHARP_PANEL_D_SHAPE, E22_HF_CODE | bands_dba |
| `validation_case_iso44.jl` | 365 | the eight R172428 cases | damping_trim, interior_tones, bands_dba |
| `validation_case_iso48.jl` | 135 | BPM_RP1218 | free_field |
| `validation_case_iso62.jl` | 322 | nine input and plumbing checks | free_field to interior_tones |
| `validation_case_iso66.jl`, `_iso67.jl` | 414, 191 | the BEMT and F1A checks, POLAR_FIDELITY, F1A_CHORDWISE | blade_polars, blade_loads, free_field |
| `validation_case_iso80.jl` | 238 | MRP_TRUNC | wall_modes |
| `validation_case_iso87.jl`, `_iso94.jl`, `_iso96.jl` | 121, 76, 109 | the App. B per-mode cases, R172428_ETAT2, the η_n cases | cabin_modes, damping_trim, interior_tones |
| `validation_case_iso90.jl` | 77 | R996_FIG10_FLAT, R996_FIG10_CIRC | skin_field |
