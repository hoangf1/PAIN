# Open issues

Known problems in the PAIN validation record that are not yet fixed. Each entry: status, what is wrong, evidence, affected cases, and the proposed action. Nothing here changes a recorded verdict until the action is done and dated.

## Index

Two lists, newest first in each. **Not assigned to a phase**: issues to act on or to hold, each waiting for the author's decision on what to do. **Assigned to a phase**: the solution is a phase of `IMPLEMENTATION_PLAN.md` (Phases 135–151); the entries follow in the same order below. Issues 001–014 were recorded first and answered on 2026-11-09; 015–029 were found on 2026-11-09 from the chain coverage chart; 030–033 on 2026-11-10 from the review of the eight not-met cases left on the chart; 034 and 035 on 2026-11-10 during Phase 136; 036 and 037 on 2026-11-10 during Phase 137.

### Not assigned to a phase

| Issue | Subject | Kind | State |
|---|---|---|---|
| 040 | The per-stage file layout and the 44 test-only cases (Phase 150b, 150e rest) | Organisation | open |
| 039 | FLIGHT_MODES: twenty generalized masses differ in the in-plane part, with both signs | Investigation | open |
| 038 | The uncertainty budget's nominal sample is not the pipeline's result (structural mode cut-off) | Tests, code | closed 2026-11-12 |
| 037 | The Phase III trim has guessed inputs; cases that use it may carry a verdict they should not | Input rule, investigation | closed 2026-11-12: E14_LOSS carries no verdict |
| 036 | Twelve source functions have no unit test, so the completeness check fails | Tests | closed 2026-11-12 |
| 035 | The summary file and §0 date from 2026-11-02 and do not show the changes since | Record | closed 2026-11-11 |
| 034 | The shipped program form has no held-out test of all its parts; R172428_ETAT2 changes only the trim damping | Validity, investigation | closed 2026-11-12: answered, a stated limit |
| 033 | CYL2D at 62.6°: this code rejects NASA's grid where NASA's program solved it | Not met, investigation | closed 2026-11-12: NASA's grid is solved; a common factor of 0.3 % stays unexplained |
| 032 | R172428_ETA and E14_LOSS: look for an error in the loss-factor method | Not met, investigation | open (R172428_ETA only since 2026-11-12; E14_LOSS has no verdict, ISSUE-037) |
| 031 | Not-met cases where a published prediction misses the same way: a separate look on the chart | Readability | closed 2026-11-12 |
| 030 | R996_LOADS: the fix needs more measured section data or CFD | Not met | on hold (author 2026-11-10) |

### Assigned to a phase

| Issue | Subject | Kind | Phase |
|---|---|---|---|
| 029 | Which of the 43 chart cases to keep; a rule before any new case | Not met, organisation | 135, 150 (closed 2026-11-11; the test-only move is ISSUE-040) |
| 028 | Files named and grouped by phase number; old paths | Organisation | 150 (paths done; the per-stage move is ISSUE-040) |
| 027 | Source loads: XFOIL drag; measured polars unused as input | Not met | 141 (closed 2026-11-11; continued in 030) |
| 026 | High-frequency NR cases: method limit and assumed inputs | Not met | 137 (closed 2026-11-10) |
| 025 | CYL2D_PRINTED judges a grid rule that was not adopted | Not met | 140 (closed 2026-11-11) |
| 024 | FLIGHT_MODES is two modes short on a file with two misreads | Not met | 142 (closed 2026-11-11: met on the settled file) |
| 023 | E14_LOSS and R172428_ETA: the trim loss term | Not met | 139 (closed 2026-11-11; continued in 032) |
| 022 | Code-against-NASA misses classed as a method limit | Not met | 138 (closed 2026-11-10) |
| 021 | Post-hoc verdicts are not marked on the chart | Readability | 145 (closed 2026-11-11) |
| 020 | Points and error text count rows outside the verdict | Readability | 145 (closed 2026-11-11) |
| 019 | No single current statement of why a case is not met | Not met, readability | 135, 145 (closed 2026-11-11) |
| 018 | 27 not-met rows are about 14 comparisons | Readability | 145, 146 (closed 2026-11-11) |
| 017 | Four not-met verdicts are on a superseded program form | Not met | 136 (closed 2026-11-10) |
| 016 | VALIDATION_GUIDELINE.md is 4,566 lines | Organisation | 148 (closed 2026-11-11) |
| 015 | Retire the block validation map | Organisation | 147 (closed 2026-11-11) |
| 014 | R172428_CODE not met 5/9 | Not met | 136 (closed 2026-11-10) |
| 013 | Case names and abbreviations unexplained | Readability | 146 (closed 2026-11-11) |
| 012 | README treats the GUI as optional | Readability | 149 (closed 2026-11-11) |
| 011 | Cabin-mode animation does not play | Readability | 151 (closed 2026-11-11) |
| 010 | Coverage rows scattered; group by figure | Organisation | 146 (closed 2026-11-11) |
| 009 | R172428_EXP plot labels and comparison target | Readability | 136, 145 (closed 2026-11-11) |
| 008 | BLK_P68 tests R1, predictions use R2 | Not met | 144 (closed 2026-11-11) |
| 007 | E12_BLOCK 29/31; two max errors on record | Not met | 143 (closed 2026-11-11) |
| 006 | R2 and the circular wall have no criterion | Not met | 144 (closed 2026-11-11) |
| 005 | Too many Markdown files | Organisation | 148, 149 (closed 2026-11-11) |
| 004 | Pereira counts differ across the record | Readability, not met | 135, 141 (closed 2026-11-11) |
| 003 | Fig. 13a recorded as FAIL and PASS | Readability | 135 |
| 002 | Report 996 page-12 phase stated three ways | Readability | 135 |
| 001 | Report 996 acoustic verdicts run on loads scaled to the measured loads | Not met | 141 (closed 2026-11-11) |

## Author decisions (2026-11-09 and 2026-11-10)

Asked and answered in the sessions of 2026-11-09 and 2026-11-10. Quoted words are the author's. Each decision is carried into the issue and the phase named.

| # | Question | Decision | Issue | Phase |
|---|---|---|---|---|
| 1 | Do the four cases judged on CR-3813's old program form keep a place on the coverage chart? | No. "if there isnt a weight on the validity of the tool should it still be on the coverage map". They become diagnostics; results kept | 017, 014 | 136 |
| 2 | How is a met verdict shown when the case was not met at its first run? | "this needs to be proven that its not circular somehow on the coverage map or somewhere accessible by the reader". An independence record per case, opened from the chart; no record, no verdict | 021 | 145 |
| 3 | Do the three TP-2444 cases keep a verdict on a trim that is not theirs? | No. "if all inputs arent available then it should not have a verdict"; their further use was left to me (see ISSUE-026) | 026 | 137 |
| 4 | Add the causes "old program form" and "unexplained" to the why-not-met table? | Yes, in plain words, on a page that is easy to search and not filled with text. No letter codes | 019, 016 | 135, 148 |
| 5 | May a re-run of FLIGHT_MODES on a blind second transcription carry the verdict? | Yes | 024 | 142 |
| 6 | Does BLK_P68 stay on the chart? | No. It is the equation written out; it stays as a unit check | 008 | 144 |
| 7 | Add source cases with unscaled loads (Report 996 Figs. 12, 13a, 14; Pereira Figs. 8, 9)? | Yes, with the existing tolerances copied unchanged | 001, 004 | 141 |
| 8 | Build a polar set from the measured TN 1546 sections? | Coverage check first; go on only at half the blade span or more | 027 | 141 |
| 9 | One rule for the chart: a case is shown only if it runs the shipped code, every input is printed or measured, and it is compared with a measurement or with NASA's program output? | Yes, applied to all 43 cases | 015 | 135 |
| 10 | Which phases first after Phase 135? | The not-met cases (136–144), then the chart, then the documents and files | — | — |
| 11 | Retire Cabin_Noise's validation map too? | No, PAIN only for now | 015 | 147 |
| 12 | What supports the band-centre idea for the trim loss term? | 24 or more of R172428_ETA's 32 modes within ±25 %, fixed before any run | 023 | 139 |
| 13 | Use the proposed sorting of the 43 chart cases (ISSUE-029)? | "Yes, use it". 18 stay on the chart, 2 go inside R172428_EXP, 5 are checked first, 15 become diagnostics, 3 are retired | 029 | 135 |
| 14 | Are the cases without a verdict worth keeping, and how to stop useless ones being added? (2026-11-10) | "you should write the list and put somewhere in claudemd to only create test cases that help". The list for the 111 is in ISSUE-029 and was approved the same day ("Approve the list"); the rule is in CLAUDE.md | 029 | 150 |
| 15 | Plan a phase for R996_LOADS? (2026-11-10) | No, on hold: "hold off on creating a phase plan as this requires further cfd/digitization" | 030 | — |
| 16 | Is PER_FIG8's miss a limit of the code? (2026-11-10) | "if we are getting the same results as CFD which is higher fidelity thats just a limitation of the code" | 031 | — |
| 17 | How are R172428_EXP and NR_TP1964_XOVER shown? (2026-11-10) | "should be labeled differently on the coverage map" | 031 | — |
| 18 | R172428_ETA and E14_LOSS after Phase 139 (2026-11-10) | "there must be something wrong with this function methodlogical wise this needs further investigation" | 032 | — |
| 19 | CYL2D_PRINTED's cause (2026-11-10) | "i guess it would be both": approximation in this recreation, and unexplained; a ticket of its own | 033 | 135 |

Still open for the author: the new CLAUDE.md update list (Phase 148a), the plain titles of the cases (Phase 146c), any deletion of a Markdown file (Phase 149a), and the two questions of ISSUE-031. Settled on 2026-11-10 under the author's delegation (`validation_reports/phase135_151_decisions.md`): the unscaled loads are shown as a second line on the existing cases, not as new cases (decision 7, Phase 141c); no further held-out printout exists (Phase 136e); R2 on run 10's printed field stays a unit test (Phase 144a).

## Sources found (2026-11-09)

A web search for reports that could settle open questions of these issues. The list, with what each may give and what to check first, is `IMPLEMENTATION_PLAN.md` §2.5 (D-23 to D-31). Two were then downloaded with the author's go-ahead and read in part the same day: CR-165869, which prints the cabin grid rule that Phase 111 could not find (ISSUE-025), and CR-159668, whose measured blocking data are too scattered to judge a case on (ISSUE-006). The others were not downloaded; what is said about them comes from catalogue records and abstracts. Two findings came from PDFs already in `references/`: TP-2444 p. 8 prints its trim lining (ISSUE-026), and TN 1546 holds 24 sections of which three are digitized (ISSUE-027).

---

## ISSUE-040: The per-stage file layout, and the 44 test-only cases off the GUI list

**Status:** open, not assigned to a phase. Recorded 2026-11-11 while closing Phase 150, by Claude under the author's authority of 2026-11-11. Organisation; no verdict, criterion or result is involved.

**What is left.**
1. Phase 150b: case runners in `src/cases/<stage>.jl` and testsets in `test/cases/<stage>.jl`, one move commit, no edit inside a function, testset counts and R11 baselines equal before and after. The mapping is in `validation_reports/phase150_layout_and_cases.md`; 13 of 26 files span more than one stage, so files are split function by function.
2. The 44 cases ISSUE-029 marks "test": off the GUI list, the records and the CSV, with their tests kept. The registry rule "every registered case is listed" becomes "listed or test-only", and the unit tests that use these cases as stand-ins (MRP_D1, CABIN_GEOM_HAND, UT_GRID and others) are moved to other ids.

**Why not in Phase 150.** Each needs its own full run of the affected testsets (about two hours here) and changes nothing a reader of the chart sees; the retirements, which do, were done first.

## ISSUE-039: FLIGHT_MODES: twenty generalized masses differ from NASA's in the in-plane part

**Status:** open, not assigned to a phase. Recorded 2026-11-11 while closing Phase 142. Investigation. FLIGHT_MODES is met (200/221) and its criterion does not change.

**Decided as a ticket** by Claude under the author's authority of 2026-11-10 and 2026-11-11, following the author's choice for R172428_ETA after Phase 139 (ISSUE-032): the phase's test found no cause, and the search goes on outside it.

**What is known** (`validation_reports/phase142_flight_modes.md`).
- 21 of 221 modes are outside the rule: one in frequency (mode 29, −5.2 %), twenty in generalized mass (10–113 %).
- For the twenty, the shell and plate normal-displacement parts match NASA's printed SHELL W and PLATE W. The difference is in total − shell − plate, the in-plane part.
- The in-plane part is too large in ten modes and too small in ten. One missing term would give one sign.
- 17 of the twenty are symmetric and 17 lie above 680 Hz.
- The pairing rule is not the cause (two near-degenerate modes; swapping makes both worse).
- Mode 41, the earlier example of this difference, was a misread of the page (1802.69 kg printed; this code 1800.91).

**Questions.**
1. Which in-plane terms do Eqs. (D.17)–(D.29) of CR-3813 App. D put into the generalized mass of the floor and of the shell, and does `mrp_appd.jl` have each one? A unit test per term found.
2. Do the twenty have a neighbour of the same symmetry and M within a few per cent in frequency, so that the two solvers mix the same pair differently? Then the difference is a property of near-degenerate pairs, not an error.
3. Peterson and Boyd, J. Sound Vib. 60(1), 45–62 (1978) (D-30, not in the repository): the shell-with-floor theory CR-165869 p. 73 names. A check of the in-plane terms against it is verification, no verdict.

**Rules.** MRP_APPD (32/32) and FLIGHT_MODES must stay met after any change to `src/`; a change rests on a printed equation, not on these twenty numbers.

## ISSUE-038: The uncertainty budget's nominal sample is not the pipeline's result

**Status:** closed 2026-11-12 (Claude, under the author's authority of 2026-11-11, "fix all the issues"): the cause was confirmed by the fix. `appd_cut_frequency` is the one cut-off rule for the pipeline and for `build_testarticle_cache`; the testset passes 55/55 (was 52/55). No case uses the budget (UNC_COVER retired in Phase 150e); its report carries a dated note. Was: open, not assigned to a phase. Recorded 2026-11-11 while closing Phase 140. No criterion, tolerance or data file is involved; no case with a verdict uses the budget.

**Decided as a ticket** by Claude under the author's authority of 2026-11-10 ("make the same logical choices ive made"), following the author's "Open a ticket" for the failing completeness check (ISSUE-036): the failure is outside the phase being closed.

**What is wrong.** The testset "Uncertainty budget (phase 31, V-UNIT)" (`test/runtests.jl`) fails 3 of 57 checks: the budget's nominal sample with η_T = 0.5 should equal `run_pain_pipeline(source = :e11, cabin_blocks = :parametric)` within 1e-6 dB and gives 86.977 / 83.065 / 75.426 dB against 86.996 / 83.093 / 75.627 dB at H1–H3.

**Cause (found, not fixed).** Not Phase 140: the cabin modes of the two paths are equal to the last digit (checked 2026-11-11). Since Phase 123 (2026-11-03) the pipeline keeps the App. D structural modes up to twice the highest tone (here 1200 Hz), while `build_testarticle_cache` (`src/uncertainty.jl`) still asks for the 32 lowest (`n_keep = 32`, no cut-off). The difference grows with the harmonic, as a missing set of higher modes would. The cause is read from the code; it has not been confirmed by a run with the cut-off added.

**Action.** Give the two uncertainty caches the pipeline's cut-off rule (one shared helper), re-run the testset, and state in the budget's report that its band was computed on 32 modes before that date. `UNC_COVER` carries no verdict (Phase 118a), so no verdict can move; its recorded numbers are re-run and dated.

## ISSUE-037: The Phase III trim has guessed inputs; cases that use it may carry a verdict they should not

**Status:** closed 2026-11-12 (Claude, under the author's authority of 2026-11-11 ("fix all the issues"; "make decisions logically like i do")).

**Result (one diagnostic run, 2026-11-12; script not kept, rule of 2026-11-10).** `E14_LOSS` compares the band-average loss factor built from the trim's sidewall and end-plate conductances. Each guessed input was changed alone and the loss factor compared with the shipped one:

| Guessed input | Changed to | Largest change of the loss factor | Count within ±25 % |
|---|---|---|---|
| as shipped | | | 7/18 |
| side the facing sits on | skin side | 8.5 % | 5/18 |
| end-plate backing | the wall mass, not rigid | 43 % | 7/18 |
| both | | 44 % | 5/18 |
| G-10 wavespeed | 2000 m/s | 0 | 7/18 |
| mechanical connections | 18 screws, 4 lines | 0 | 7/18 |

The facing/septum loss factor is not guessed here: it is the 0.5 of the curve the case compares with (CR-3813 p. E-24). Two inputs that are not printed move the compared quantity by a third of the tolerance and by more than the tolerance. So by the input rule (Phase 118a; author: "if all inputs arent available then it should not have a verdict") **`E14_LOSS` carries no verdict since 2026-11-12**; its recorded outcome (7/18) is kept. No variant passes, so nothing was chosen to pass. `E15_STRUCT_LOSS` has no criterion and no verdict; `GEXT_BOUND` and `H3_ATTRIB` were retired in Phase 150e. The chart has 19 cases with a verdict: 13 met, 6 not met.

Was: open, not assigned to a phase. Recorded 2026-11-10 during Phase 137a′. Record only: no case, flag or number has been changed.

**Author (2026-11-10).** Found while checking TP-2444's lining; the author asked for a ticket instead of following it inside Phase 137 ("write as issue ticket").

**What is wrong.** `phase3_trim` (`PAIN.jl/src/trim_loss.jl`) builds the CR-3813 Phase III trim. METHODOLOGY §10 ("What this recreation does not claim", register f) lists four of its inputs as V-ASSUMED: the facing/septum loss factor, the G-10 wavespeed, the mechanical connections (nine screws as a uniform lattice, the floor mounting as two lines, soft mounts treated as rigid; see `phase137b_e22_bridges.md`) and the end-plate backing. The input rule of Phase 118a takes the verdict from a case whose compared quantity rests on an input that is not printed or measured. Phase 137a′ applied it to `NR_PROP_TP2444`; it has not been applied to the other users of this trim.

**Who uses it.** Cases that call `phase3_trim` (directly or through `noise_reduction_test_article_inputs`) and can still carry a verdict, according to `no_verdict_by_rule` on 2026-11-10:

| Case | On the chart? | To check |
|---|---|---|
| `E14_LOSS` | yes (not met 7/18) | whether the loss factor it compares uses the facing/septum loss factor or the mechanical path (`_run_e14_loss`, η_lining = 0.5 from CR-3813 p. E-24) |
| `E15_STRUCT_LOSS` | to check | same, for the structural loss factor (`_run_e15_struct_loss`, η_lining = 1.0) |
| `GEXT_BOUND` | to check | whether the trim enters its compared quantity at all |
| `H3_ATTRIB` | to check | same |

Cases already without a verdict that use it (`E18_TONES`, `T1`, `T1_FROM_E12`, `T2`, `E21_E22_NR` and others) are not affected. The CR-172428 cases (`r172428_inputs`) use NASA's App. D deck trim (PF-105 deck table, 50.8 mm, 1.456 kg/m², η_T from the deck, no mechanical path), whose values are printed, and are not affected either.

**Action.** For each case in the table: list which of the four guessed inputs enter its compared quantity (by reading the code path, or by one diagnostic run that changes the input and shows whether the result moves; a diagnostic is not a case and gets no test). A case whose compared quantity moves with a guessed input loses its verdict by the 118a rule, with its recorded outcome kept; a case whose quantity does not depend on them keeps its verdict and says so in its text. Author's decision, dated, before any flag changes.

## ISSUE-036: Twelve source functions have no unit test, so the completeness check fails

**Status:** closed 2026-11-12 (Claude, under the author's authority of 2026-11-11): `test/unit/test_issue036_gaps.jl` tests the twelve (hand values, limits, error paths; 25 checks); `open_mode_window` (Phase 151) is exempt by name with its reason, since it starts a GUI process and its command is tested. The completeness check passes. Was: open, not assigned to a phase. Recorded 2026-11-10 during Phase 137a. Tests only: no criterion, tolerance, data file or recorded result is involved.

**Author (2026-11-10).** Asked whether to fix it inside Phase 137 or ticket it: "Open a ticket".

**What is wrong.** `test/unit/test_zz_completeness.jl` ("every src function has a unit test") fails: 12 functions are not named in any unit test. It fails the same way on `cf49c38` with the Phase 137a changes stashed, so the cause is earlier work, not Phase 137a. Where git shows when they came in: `plot_coverage_chart`, `_parse_chain_span`, `_parse_reference` with Phase 134 (2026-11-05); `_e12_mean_curve`, `_r996_unscaled_line`, `_shade_trim_range!` with the overnight Phases 136–147 (`787b414`, 2026-11-10). The others were added the same way, as one-line definitions:

| File | Functions |
|---|---|
| `cyl2d.jl` | `_cyl2d_default_NY`, `cyl2d_printed_NK` |
| `gui_inputs.jl` | `gui_default_project_path` |
| `validation_case_extras.jl` | `_e12_mean_curve`, `_r996_unscaled_line` |
| `validation_causes.jl` | `_nasa_gate_cell` |
| `validation_coverage.jl` | `coverage_figure_dir`, `plot_coverage_chart` |
| `validation_map.jl` | `_parse_chain_span`, `_parse_reference`, `reference_label` |
| `validation_plots.jl` | `_shade_trim_range!` |

**Action.** For each one, a unit test that would fail if it were wrong (a hand value, a limit or an error path), or, where a test would only repeat another (CLAUDE.md, "Add a test ... only if it helps"), a dated entry in the check's exemption list with the reason. Then the check passes again.

## ISSUE-035: The summary file and §0 date from 2026-11-02 and do not show the changes since

**Status:** closed 2026-11-11: `write_case_error_summary.jl` was run during Phase 142, so `case_error_summary.csv`, §0, NO_VERDICT_CASES.md and the coverage figures show the state of that day (147 cases). Recorded 2026-11-10 during Phase 136. Record only: re-running changes no criterion, tolerance or reference file.

**Author (2026-11-10).** Asked whether to regenerate it inside Phase 136: "whichever option does not take time away and just bring this up as a new issue ticket".

**What is wrong.** `validation_reports/case_error_summary.csv` was last written on 2026-11-02 (`PAIN.jl/scripts/run/write_case_error_summary.jl`); §0 of VALIDATION_GUIDELINE.md and NO_VERDICT_CASES.md are written from the same run. Since then:
- Phases 135f and 136a moved cases off the chart by rule (for example R172428_CODE, R172428_DB_CODE, R172428_DBA_CODE, APPB_ETA_N). The file still records them as not met; the chart and the why-not-met table already read the rule from the code, so they show no verdict.
- Phase 140 adopted NASA's printed grid rule; CYL2D_PRINTED's 57/168 in the file is from the old rule.
- Phase 136e found no other complete PAIN run in CR-172428; §0 does not say so yet.
- §0 still gives 18 independent comparisons; the chart gives 20 (Phase 135, family fix).
- **Regenerated 2026-11-11** (during Phase 142): `case_error_summary.csv`, §0, NO_VERDICT_CASES.md and the coverage figures, by `write_case_error_summary.jl`.
- Phase 137a (2026-11-10) retired `NR_PROP_TP2444_BR`, `NR_PROP_TP2444_PF` and `E22_BR`; the file, §0 and NO_VERDICT_CASES.md still list them until the writer is run.

**Action.** One full run of the writer, in the background. Each number that moves is recorded with its date, its before and after, and "post-hoc" where the earlier result was known. A case moved off the chart by rule keeps its earlier outcome as its recorded outcome, under "no verdict".

**Not done yet.** Nothing has been run.

---

## ISSUE-034: The shipped program form has no held-out test of all its parts; R172428_ETAT2 changes only the trim damping

**Status:** closed 2026-11-12 as answered (Claude, under the author's authority of 2026-11-11 ("fix all the issues"; "make decisions logically like i do")): the three questions have answers from the record, and what is left is a stated limit, not an open task.

**Answers.**
1. `FLIGHT10_H234` cannot carry a verdict. No pass criterion was fixed before its first run (its record: "what is compared fixed 2026-10-30", and "A pass means: No verdict"), and it was re-run four times after changes, one of which (run 10's floor-term sign, Phase 108) was read from run 10's own printed pairs. A criterion written now would be post-hoc. It stays shown as information: the shipped form on a second printout, within 2.0 dB at H2–H4.
2. No other printout exists in the documents: CR-172428 prints one complete scale-model run, the η_T = 2.0 table and flight run 10 (Phase 136e); CR-3813's runs predate NASA's correction; the User Manual prints no sample output.
3. The q = 0 and band-centre re-runs of CR-3813's runs were on the pre-correction program, so they say nothing about the shipped form (they were retired in Phase 150e; reports kept).

**What stands.** The shipped form's q = 0 choice has no held-out test. METHODOLOGY says so (limits register, 2026-11-12). A held-out test needs a PAIN printout that is not in the documents; if one is found, it is a new case with its criterion fixed first.

Was: open, not assigned to a phase. Recorded 2026-11-10 during Phase 136b. Investigation. No criterion, tolerance or verdict changes; R172428_ETAT2 keeps its verdict.

**Author (2026-11-10).** "the test carries a verdict but an issue ticket needs to be created to encompass the full form independently".

**What is wrong.** The form the code ships with for CR-172428's tones (q = 0 cabin modes uncoupled, η_n per cabin mode, the band-centre rule; Phases 89–96) was read from NASA's App. B printout, and its run on those nine points (`R172428_CODE_DEFAULT`, 9/9 within 1.2 dB) is post-hoc. Its held-out tests are:
- `R172428_ETAT2` (Table 12, p. 85; met 9/9, max 1.7 dB): the same scale-model inputs with only the trim loss factor changed to η_T = 2.0.
- `APPB_ETA_N_T2_BAND` (p. 85; met 3/3): the band-centre η_n rule at three modes.

Both change only the damping. Nothing held out tests the q = 0 choice or the form as a whole on other inputs.

**Already on record.**
- Phase 136e: CR-172428 prints no other complete PAIN run for the scale model.
- `FLIGHT10_H234` (Phase 102): the shipped form against PAIN's printed flight run 10, H2–H4, 6/6 within its tolerance (max 2.0 dB). It is the only other printout run on the shipped form, and it carries no verdict while FLIGHT_MODES is not met (Phase 142).
- The q = 0 and band-centre re-runs of CR-3813's printed runs (`Q0_REPRO_18b`, `Q0_E18`, `Q0_E21`, `BAND_REPRO_18b`, `BAND_E18`; Phases 88, 99) are on the pre-correction program, not the shipped one; they missed (for example 2/3, 1/3, 3/16).

**Questions to answer.**
1. Phase 142 settled FLIGHT_MODES on 2026-11-11 (met, 200/221). Can `FLIGHT10_H234` now carry a verdict as the held-out test of the full form? Its criterion and date need checking against the rule (fixed before its first run, or post-hoc).
2. Is there another PAIN printout outside CR-172428 (CR-3813, the User Manual, the reports they cite) run with the corrected program, inputs and interior levels both printed?
3. What do the CR-3813 re-runs above say about the q = 0 choice, given that they run the pre-correction program?

**Not done yet.** Nothing has been run.

---

## ISSUE-033: CYL2D at 62.6°: this code rejects NASA's grid where NASA's program solved it

**Status:** closed 2026-11-12 (Claude, under the author's authority of 2026-11-11; report `validation_reports/issue033_cyl2d_small_diameter.md`). The diagnostic of question 3 was run: on NASA's 10-interval grid, with the real parts taken, ε(0,0) is NASA's 0.96858, all 53 mode types are NASA's, and every frequency is 0.30–0.31 % low. So the check was what kept the code off NASA's grid. Since NASA's program has no such rejection (User Manual §5.1, EIGRF) and printed modes for this grid, the code now uses the real parts on NASA's printed grid; the 0.001 threshold is unchanged and still applies to every other grid. `CYL2D_PRINTED` stays not met (0.30 % against 0.1 %); the common factor is not explained by the documents, and no input was chosen from it. Was: open, not assigned to a phase. Recorded 2026-11-10. Investigation. No criterion, tolerance, threshold or verdict changes.

**Author (2026-11-10).** On CYL2D_PRINTED's cause: "i guess it would be both create a new issue ticket for this case since our code isnt relating to nasas in this aspect". The cause record (Phase 135d) is "approximation in this recreation", with the unexplained part stated in its sentence.

**What is wrong.** On NASA's printed grid rule (CR-165869 pp. 60–61, adopted in Phase 140) CYL2D reproduces PAIN's printed cabin modes for the narrow body (73.7°, 61/61 within 0.1 %) and the Merlin IVC (50°, 51/51). For the small-diameter aircraft (62.6°, a = 1.145 m, NASA's grid of 10 intervals) it does not run on NASA's grid at all:
- App. C's one-sided curved-wall rows (Eq. C.2) make the matrix non-symmetric, so some eigenvalues come in complex pairs (Phase 79b diagnosis).
- This recreation added a check in Phase 79b (2026-10-28): the kept modes must be real within |Im|/|Re| ≤ 0.001, or the grid is rejected (`src/cyl2d.jl`, `_solve_parity`). At 62.6° the worst kept mode is 0.0012.
- The code then falls back to the next grid that solves, 12 intervals (Q60, 2026-10-29). On it: 0/53 frequencies within 0.1 %, mode types 37/53 (`validation_reports/phase140_cyl2d_printed_rule.md`).
- NASA's program printed modes for this grid (CR-172428 App. C, deck p. 210), so it solved it. The documents do not say how it treated complex eigenvalues.

**Why it matters beyond the case.** The GUI's automatic floor angle picks 62.6° for a 2.5–2.7 m fuselage (Phase 120), so every prediction in that size class runs on the fallback grid, not NASA's.

**Already on record.** Phase 105: no App. C grid tried reproduced the small-diameter list (best about 2 %). So accepting NASA's grid may not be enough on its own.

**Questions to answer.**
1. Does CR-3813 App. C or the User Manual §5.1 say how complex or nearly-real eigenvalues are handled (real part, a symmetrised matrix, another solver)? **User Manual §5.1 re-read 2026-11-11 (Phase 140 closing):** it names the IMSL routine EIGRF (eigenvalues of a real general matrix, so complex pairs are returned as such) and VSRTR / VSRTU (sorting), and says nothing on complex values. CR-3813 App. C is still to be re-read for this.
2. Is this code's curved-wall row at 62.6° the same as App. C's, node by node? The asymmetry comes from those rows.
3. A one-question diagnostic (a script and a report, no case, no verdict, post-hoc since the list was seen): on NASA's 10-interval grid at 62.6°, take the real parts despite the check and set them against NASA's list. If they match, the check is the whole cause; if not, something else in the scheme differs.

**Rules.** The 0.001 threshold is not changed because of this result: a threshold chosen after seeing it would make the case pass by construction. A change needs a basis in the documents (question 1) and is dated before CYL2D_PRINTED is re-run.

**Not done yet.** Nothing has been run.

---

## ISSUE-032: R172428_ETA and E14_LOSS: the loss factors disagree with NASA's by up to a factor of two; look for an error in the method

**Status:** open, not assigned to a phase. Recorded 2026-11-10. Investigation. No criterion, tolerance or verdict changes. Follows ISSUE-023, whose phase (139) ended with no cause found.

**Author (2026-11-10).** "there must be something wrong with this function methodlogical wise this needs further investigation".

**How large the misses are** (`validation_reports/phase139b_band_centre.md`, Phase 139a):

| Case | Where it agrees | Where it misses |
|---|---|---|
| R172428_ETA (structural loss factor of Eq. (82), ±25 %, 17/32) | Every mode up to 470 Hz (modes 1–11, any shell share): within 12 %; above 470 Hz, the modes with almost no shell motion (shell-bending share under 0.05; modes 18, 23, 24, 26): within 6 % | Every other mode above 470 Hz: 0.51–0.80 times NASA's value. Shell modes 6, 8 and 9 (share 0.54–0.77) are 0.88–0.94 below 470 Hz, so the miss follows frequency as well as shell share |
| E14_LOSS (band-average acoustic loss of Eq. (78), ±25 %, 7/18) | 400–500 Hz | 1.1–1.7 times NASA at 630–1250 Hz (2.29 at 200 Hz); 0.47–0.68 times above 1600 Hz |

The two patterns are not the same, so one cause for both is not shown.

**Ruled out so far.** Modal masses (within 1 %), the trim admittance (App. B p. 197, within 2 % to 1 kHz), truncated mode shapes, an included Σ η_r″ and the other forms of Eq. (A.8) (VALIDATION_GUIDELINE §2.27); NASA's per-band PF-105 table in place of Fig. A-2 (Phase 118, §2.29); evaluating ω and the trim at the band centre (Phase 139b: 15/32, not supported).

**What points at the method.** The same trim model gives NASA's cabin-mode loss η_n (`APPB_ETA_N_BAND` 46/46 within 10 %). So the trim admittance is right where it enters Eq. (77) and low where it enters Eq. (82), above 470 Hz, wherever the mode has shell motion.

**Leads not yet tested.**
1. Eq. (82) and Eq. (78) as coded, term by term, against the report the trim model comes from: CR-165869 §3.1 Eq. (28) (PDF pp. 43–44, the loss factor from the wall conductance) and §3.7 (PDF p. 83). A transcription, area or unit error in the shell term, or a frequency dependence of the trim term that is wrong above about 470 Hz, would each give part of what the curves show; the pattern has both parts.
2. The shell term's integral: over which area it runs (trimmed sidewall only, or the whole shell) and with which mode-shape normalisation, against CR-172428 App. A.
3. A second NASA data set before any change: CR-172428 App. C prints a LOSS FACTOR column for the Merlin IVC structural modes (PDF p. 223 on). If the same shell-share pattern shows there, the cause is in this code's equation, not in one input set.
4. E14_LOSS: which modes enter each band of Eq. (78)'s average, and how they are counted, against CR-3813's definition.

**Rules.** A finding comes from the documents, not from the effect of a change on the two cases. If a code change follows, both cases are re-run with unchanged criteria and labelled post-hoc; the held-out check is lead 3, with its criterion dated before it is compared.

**Not done yet.** Nothing has been run.

---

## ISSUE-031: Not-met cases where a published prediction misses the same way: R172428_EXP, NR_TP1964_XOVER and PER_FIG8 should look different on the coverage chart

**Status:** closed 2026-11-12 (Claude, under the author's authority of 2026-11-11 ("fix all the issues"; "make decisions logically like i do")). Verdicts unchanged: a case that misses its gate stays not met.

**Rule (written 2026-11-12, before Pereira's CFD was put on the gate).** A not-met case is marked when a published prediction of the same quantity at the same points, put on the case's own tolerance and rule, also misses, and that prediction is either PAIN's own printed output or a method of higher fidelity (`published_prediction_on_gate`, `method_limit` in `validation_causes.jl`).

**The two questions, decided as the author's words of 2026-11-10 lead.**
1. NR_TP1964_XOVER: **no mark.** Its NASA curve is CR-159363's earlier model with three choices not printed, this code does not reproduce it, and it scores better (12/18) than this code (9/18). The author's "limitation of the code itself" holds only where the code reproduces the prediction. The table still shows the curve's count, with "no mark".
2. PER_FIG8: **marked.** Pereira's CFD, computed from the digitized Fig. 8 on the same gate: H1 7/7 within ±1.7 dB, H2 5/7 within ±3 dB (−3.9 dB at −20°, −3.1 dB at −10°), so 12/14: it misses too. This code: 10/14. The author: "if we are getting the same results as CFD which is higher fidelity thats just a limitation of the code".

**On the chart.** A marked bar is drawn half as strong with a black outline, and its text reads "prediction misses too". The status page counts these apart (2 of the 6 not-met cases: R172428_EXP, PER_FIG8). The "why not met" table names the prediction it used.

Was: open, not assigned to a phase. Recorded 2026-11-10. Labels. No verdict changes: a case that misses its gate stays not met.

**Author (2026-11-10).** On R172428_EXP and NR_TP1964_XOVER: "This really explains the limitation of the code itself and should be labeled differently on the coverage map". On PER_FIG8: "if we are getting the same results as CFD which is higher fidelity thats just a limitation of the code".

**Today.** Since Phase 137c a not-met bar whose gate NASA's printout also misses has " · method limit" added to its text (`method_limit` in `src/validation_causes.jl`; the bar text in `src/validation_coverage.jl`). It is drawn like any other not-met bar.

| Case | This code against the measurement | This code against the published prediction | The published prediction against the measurement | What it shows |
|---|---|---|---|---|
| R172428_EXP | 5/9 within ±4 dB, worst 18.0 dB | Shipped form against NASA's printout: `R172428_CODE_DEFAULT` 9/9, largest 1.19 dB (post-hoc, no verdict); held-out `R172428_ETAT2` met 9/9, largest 1.73 dB | NASA's printout 5/9 on the same gate; 14–18 dB under the measured H1 at 3000 and 5000 rpm | The code works like PAIN and PAIN misses the measurement. A clean method limit |
| NR_TP1964_XOVER | 9/18 within ±5 dB, worst 17.0 dB | `NR_TP1964_XOVER_REF2` 8/18, worst 10.0 dB, no verdict: NASA's curve is CR-159363's Phase I prediction with three choices not printed as numbers (mode (1,1) left out, coupled modes moved apart, radiation damping raised; `phase138_ref2_inputs.md`) | NASA's curve 12/18 | Not clean. The NASA curve is an earlier model with hand-made choices, not PAIN as shipped; it does better than this code (12 against 9), and this code does not reproduce it |
| PER_FIG8 | 10/14, worst 3.7 dB | No NASA program. This code's H1 directivity is within 0.8 dB of Pereira's own blade-element prediction (Phase 72) | Pereira's CFD ("Numerical" in Fig. 8, digitized in `data/pereira/pereira_fig8_directivity.csv`) misses at the same angles by similar amounts (H2: 3.9, 3.1, 1.2, 0.2, 2.6, 1.9, 2.4 dB, VALIDATION_GUIDELINE §2.14) | A limit shared with a method of higher fidelity; the record also names the set-up (the open-jet nozzle 0.04 m behind the −20° microphone) |

**Is PER_FIG8 circular?** No, but it tests less than its title says. Its loads are scaled to Pereira's measured thrust and torque (Table 3; s_T 0.99–1.08), and it is compared with a different measurement, the sound at the microphones. So it tests the acoustic step given the measured loads, not the blade-element loads or the polars. The scaling is small: unscaled, thrust is +0.7 % and torque +3.5 % from Table 3 (Phase 69); 0.7 % of thrust is about 0.06 dB of level. The label "loads scaled to measured thrust and torque" is Phase 141a; the unscaled second line is the open Pereira part of 141c.

**Proposed action.**
1. A separate state on the chart for "not met: the published prediction misses the same way", drawn apart from not-met bars that this code alone misses (own colour or hatch, own count in the totals). The verdict text stays "not met".
2. Beside such a bar, the code-against-prediction result, so the reader sees whether the code reproduces the prediction.
3. The mark's rule widened from "NASA's printout" to "a published prediction of the same quantity at the same points", which brings in Pereira's CFD. The rule is written and dated before it is applied to any case.

**Open questions for the author.**
- NR_TP1964_XOVER: keep the mark, or a weaker label ("NASA's earlier prediction also misses"), since the code does not reproduce that curve?
- PER_FIG8: the CFD misses are taken from the case text; the rule of step 3 needs them computed from the digitized file and set against the same ±1.7 dB and ±3 dB gates.

**Not done yet.** Nothing changed.

---

## ISSUE-030: R996_LOADS (24/32) misses because XFOIL's section drag is low; the fix needs more measured section data or CFD

**Status:** on hold, not assigned to a phase (author 2026-11-10: "hold off on creating a phase plan as this requires further cfd/digitization"). Recorded 2026-11-10. No criterion, tolerance or verdict changes.

**What is wrong.** `R996_LOADS` is not met: 24/32 within ±15 % (thrust 11/14, power 13/18), worst 39 %. Section lift is not the cause: a lift shift of the size measured moves thrust by at most 7.9 % (Phase 73). XFOIL's drag is about 25 % below NACA TN 1546's measured drag and accounts for about half the torque gap (ISSUE-027). It is the only not-met case on the chart that traces to the polars.

**What was tried.** Coverage of the blade by TN 1546's measured sections (Phase 141d, `validation_reports/phase141d_tn1546_coverage.md`): 0.30, 0.53, 0.67 and 0.72–0.76 of the span at tip Mach 0.45, 0.60, 0.75 and 0.90. The three digitized sections have design lift 0.3 and 0.5 only; the blade's inner and tip sections run 0.13–0.3.

**What it needs before a phase can be planned.**
1. Digitizing TN 1546 Figs. 3(b), 3(c), 3(d), 3(f) and 3(g) (design lift 0.1 and 0.2, 6–15 % thick) by the procedure of `IMPLEMENTATION_PLAN.md` §2.2; or
2. Section polars from a CFD solver of higher fidelity than XFOIL, with every setting fixed and dated before any load is computed;
3. Optionally NACA RM L9G06a (D-26, not in the repository): forward-flight thrust and power of the same blade, a loads check no polar set was built from.

**Cautions.** R996_LOADS's history is already post-hoc; whether a re-run on new polars carries the verdict is decided and dated before it is run. A CFD or interpolation setting chosen by its effect on the loads would be calibration (CLAUDE.md). Phase 141e (measured-polar set) waits on this issue.

**Not done yet.** Nothing has been digitized or run.

---

## ISSUE-029: Which of the 43 chart cases are worth keeping, and a rule before any new case is added

**Status:** closed 2026-11-11 by Phase 150 (`COMPLETED_PHASES.md` §8cn; `phase150_layout_and_cases.md`): 48 cases retired as listed; the move of the 44 test-only cases off the GUI list is ISSUE-040. Recorded 2026-11-09. Raised by the author ("i created many validation cases that arent met and arent useful im not even sure if i should be keeping those cases"). The sorting below was approved by the author on 2026-11-09 ("Yes, use it"). It comes from the case records; nothing has been moved yet. Solution: Phase 135f, then the phase that owns each case.

**Summary.** Sorted by the chart rule decided on 2026-11-09 (runs the shipped code; every input printed or measured; compared with a measurement or with NASA's program output), 18 of the 43 cases weigh on the tool's validity, 2 more are sums that belong inside one of them, 5 need one fact checked, and 18 do not. Of the 27 not-met rows, 7 stay on the chart. So most of the red on the chart today is not about the tool.

**Sorting (approved 2026-11-09; from the case texts, so each row is still checked against the code in Phase 135f, and a row the code contradicts goes back to the author).**

| Case | Now | Proposal | Why |
|---|---|---|---|
| R996_LOADS | not met 24/32 | Keep | the only test of the blade loads against measurement |
| R996_FIG12, R996_FIG13A, R996_FIG14 | met | Keep | the sound model given the measured loads; each needs its independence record (ISSUE-021) |
| PER_FIG7 | met 3/3 | Keep | the only forward-flight waveform timing |
| PER_FIG8 | not met 10/14 | Keep | forward-flight levels at seven angles |
| PER_FIG9 | not met 15/18 | Check | Phase 74 found it equal to Fig. 8 within 0.1 dB at the shared angles; probably a duplicate |
| POLAR_FIDELITY | not met 13/26 | Diagnostic | tests the section data fed to the Report 996 cases: an input, not the tool |
| R996_PHASE | not met 0/1 | Diagnostic | one value; the report does not state the two stations it was measured between, and its own theory misses it by 10° |
| R996_FIG10_FLAT | met 5/5 | Check (Phase 144) | runs the R1 blocking; the tool's default is R2, whose result on the same data is on record (about 2 dB under) |
| E12_BLOCK | not met 29/31 | Diagnostic | runs R1 against a hand-read curve whose reading spread (2.91 dB) is nearly the tolerance (3.41 dB) |
| BLK_P68 | met 6/6 | Unit check (decided) | the equation written out |
| R172428_EXP | not met 5/9 | Keep | the main cabin case against measurement; its misses are H1 at 3000 and 5000 rpm, where NASA's PAIN misses by the same amount |
| R172428_DB_EXP, R172428_DBA_EXP | not met 1/3 | Keep inside R172428_EXP | the dB and dB(A) sums the author asked for; rows of the parent, not bars of their own |
| R172428_ETAT2 | met 9/9 | Keep | the held-out proof that the shipped form reproduces PAIN |
| T1_APPB | met | Check | the same measurement and field as R172428_EXP's 4000 rpm points, with CR-3813's cabin inputs; one tone passes only through the gate that compares with NASA's prediction |
| T1_MEAS_DAMPING_APPB | met | Diagnostic | puts measured damping in place of the tool's damping model |
| R172428_CODE, R172428_DB_CODE, R172428_DBA_CODE | not met | Diagnostic (decided) | old program form |
| NR_TP1964_XOVER | not met 9/18 | Keep | the shipped path on an independent measured cylinder |
| NR_TP1964 | not met 6/18 | Diagnostic | the same cylinder without the changeover, which is not how the tool runs |
| NR_TP1964_REF2 | not met 6/18 | Diagnostic | as above, and the inputs behind NASA's curve are not established |
| NR_TP1964_XOVER_REF2 | not met 8/18 | Information (Phase 138 done) | CR-159363's curve rests on three choices not printed as numbers |
| E21_E22_NR | not met 5/35 | Diagnostic | its NASA curve comes from the program before NASA's corrections; its measured part lies above the range NASA gives for the trim model |
| E22_HF_CODE | not met 1/4 | Diagnostic | compared with the output of a routine NASA did not print |
| E22_BR, NR_PROP_TP2444_BR, NR_PROP_TP2444_PF | not met | Retire | additions that are not part of the shipped tool, on assumed inputs |
| NR_PROP_TP2444 | not met 1/7 | Information (Phase 137a′ done) | its lining's acoustic table is not printed; CR-172428's PF-105 does not match TP-2444's weight |
| MRP_APPD | met 32/32 | Keep | needs its independence record |
| FLIGHT_MODES | met 200/221 (Phase 142; first run not met 197/221) | Keep | reference file settled by a blind third transcription |
| CYL2D_C1, APPB_EPS_N, CABIN_FREQ_PRINTED | met | Keep | PAIN's own printed cabin modes |
| CYL2D_PRINTED | not met (57/168 on the old rule) | On the chart since Phase 140 (done) | tests a grid rule the code does not use; CR-165869 prints the rule (ISSUE-025) |
| APPB_ETA_N | not met 12/46 | Diagnostic (decided) | old program form |
| APPB_ETA_N_T2 | met 3/3 | Check | may run the form of Phase 93, before the band-centre rule became the default |
| APPB_ETA_N_T2_BAND | met 3/3 | Keep | the shipped damping rule on a held-out printout |
| APPB_ETA_RPP | met 16/19 | Keep | needs its independence record |
| R172428_ETA | not met 17/32 | Keep | unexplained; Phase 139 done, ISSUE-032 open |
| E14_LOSS | not met 7/18 | Keep | unexplained; Phase 139 found its error pattern differs from R172428_ETA's, so it tells something that case does not |

**What the chart would hold.** 18 bars: 11 met (six of them waiting on an independence record) and 7 not met (R996_LOADS, PER_FIG8, R172428_EXP, NR_TP1964_XOVER, FLIGHT_MODES, R172428_ETA, E14_LOSS). Each of the seven has an open phase or a stated limit of PAIN's method.

**What "diagnostic" and "retire" mean here.**
- *Diagnostic:* off the chart; its report and recorded result stay; it is listed on one page with the question it answered.
- *Retire:* the same, and it is no longer run or shown in the GUI's case list. Whether its runner and tests are then removed is part of Phase 150.
- The 111 cases that already have no verdict are sorted case by case below. The author approved that list on 2026-11-10; the removal itself is Phase 150.

**The 111 cases without a verdict, case by case (approved by the author on 2026-11-10: "Approve the list").** Author: "are the no verdict cases worth having still too" and "you should write the list". Sorted from `NO_VERDICT_CASES.md` and the case texts; nothing has been moved. Four outcomes:
- *Test:* worth having because it catches a broken function. It stays in the test suite only: no GUI entry, no figure, no record in the guideline.
- *Show:* worth looking at. It stays visible as information on a short list of its own, apart from the chart.
- *Until:* kept only until the open phase that uses it closes, then decided there.
- *Retire:* its question is answered or its inputs can never be completed. The runner and the tests that assert its old outcome go; its report in `docs/validation_reports/` stays.

Totals: 44 test, 14 show, 6 until, 47 retire.

*Diagnostic re-runs (24): 1 test, 3 show, 20 retire.*

| Proposal | Cases | Why |
|---|---|---|
| Show | `R172428_CODE_DEFAULT`, `APPB_ETA_N_BAND`, `FLIGHT10_H234` | the shipped code against NASA's own printouts (the main test-article run, the cabin damping list, flight run 10); each is post-hoc and says so |
| Test | `R172428_TRIM_DECK` | NASA's printed trim table reproduces NASA's printed admittances 84/84: a check of an input the cases rely on |
| Retire | `REPRO_18b_PRE`, `E21_PRE`, `E21_PRE_DECK`, `REPRO_18b_DECK` | the pre-correction floor sign and the 300-mode set on CR-3813's runs: refuted (Phases 61, 83, 84) |
| Retire | `E22_HF_DECK`, `T2_EQ19_DECK`, `R172428_CODE_DECK`, `R172428_EXP_DECK` | NASA's 300 modes as the cause of a miss: refuted (Phases 83, 84) |
| Retire | `Q0_REPRO_18b`, `Q0_E18`, `Q0_E21`, `BAND_REPRO_18b`, `BAND_E18` | q = 0 and the band-centre rule on CR-3813's runs: refuted (Phases 88, 99) |
| Retire | `R172428_CODE_ETAN`, `R172428_CODE_Q0`, `R172428_CODE_Q0_ETAN`, `APPB_PAIRS`, `APPB_PAIRS_Q0_ETAN` | steps on the way to the shipped form; `R172428_CODE_DEFAULT` shows where they ended |
| Retire | `FLIGHT10_FLOOR_SIGN` | answered (Phase 108); its result is an input of `FLIGHT10_H234` |
| Retire | `FLIGHT_MODES_P2` | became the FLIGHT_MODES re-run of Phase 142; retired 2026-11-11 |

*Checks of the code against a formula, an identity or another method (47): 37 test, 3 until, 7 retire.*

| Proposal | Cases | Why |
|---|---|---|
| Test | `BEMT_HAND`, `BEMT_MOMENTUM`, `BEMT_HAND_TIP`, `BEMT_INTEGRALS`, `BEMT_SIMILARITY` | the blade-load code against hand calculations and identities |
| Test | `F1A_INDEP`, `F1A_PLANE_PEAK`, `F1A_GUTIN`, `F1A_GUTIN_ANGLES`, `F1A_GW_FLIGHT`, `F1A_THICKNESS`, `F1A_PROPERTIES`, `BBN_KIN` | the sound model against a second implementation, closed forms and the kinematic phase step |
| Test | `ISO_TABLE8`, `ISO_FF_CONV`, `SRC_PASSTHROUGH`, `UT_GRID`, `ISO_GEXT_LINE`, `ISO_BLOCKING`, `BLK_GAIN_MAP` | the free field, the grid and the blocking: conversions, plumbing, the grid formulas, the blocking factor and its bound |
| Test | `MRP_INPUT_QA`, `MRP_TRUNC`, `CABIN_GEOM_HAND`, `ISO_CYL2D_EXACT`, `ISO_CYL2D_BOUNDARY` | structure inputs against the printed values, mode-shape normalization, cabin geometry, the cabin solver against the exact circle |
| Test | `TRIM_INPUT_QA`, `ISO_JOINT_ACC`, `TRIM_CLOSED`, `TRIM_PASSIVITY`, `PAIN_INPUT_ECHO` | trim inputs, the trim stack against its closed form, passivity, resolved inputs |
| Test | `ISO_MODAL_DENSITY`, `ISO_BB_BAND`, `NR_BAND_HAND`, `HF_MASSLAW`, `ISO_SIL`, `LOUDEST_PT_GRID`, `AC_CABIN_DEMO` | the cabin equations against hand evaluations and sums |
| Until Phase 150 | `BPM_RP1218` | tests the broadband self-noise code; it stays only if that code stays (the GUI has been tones only since Phase 130) |
| Until Phase 150 | `SHARP_PANEL_D_SHAPE` | tests the sound-bridge option; it stays only if the option stays |
| Until Phase 150 | `MRP_COUPLED_LIMITS` | 12 of 78 rows miss by design (NASA's floor form is not the exact energy); rewritten for the form it holds for, or retired |
| Retire | `E11_FREEFIELD` | two digitizations against each other: a data check, recorded in the data file's header |
| Retire | `FF_E11_MAP` | holds by construction, which CLAUDE.md step 6 does not allow as a test |
| Retire | `MRP_SHAPE_NORM` | tests a property of NASA's printed table, not this code |
| Retire | `CYL2D_WEYL`, `LOUDEST_PT` | missed through their own design; `ISO_CYL2D_EXACT`, `CYL2D_GRID_CONV` and `LOUDEST_PT_GRID` cover the same ground |
| Retire | `SHARP_PANEL_D` | a design figure that is neither PAIN nor a measurement, for an option that is not the default |
| Retire | `T2` | a fitted path compared with the data it was fitted to |

*Inputs not printed or measured (18): 5 show, 13 retire.*

| Proposal | Cases | Why |
|---|---|---|
| Show | `AC_C695A_DBA`, `AC_C695A_TONES`, `AC_C695A_EXT`, `AC_C695A_SEAT` | the only comparison with a real aircraft cabin and the only cases that run the whole chain; blade and cabin section assumed, so no verdict |
| Show | `BBN_CIRC` | the only measured phase between points on a fuselage; blade assumed |
| Retire | `REPRO_18b`, `E18_TONES`, `UNC_COVER`, `T1`, `T1_FROM_E12`, `T1_MEAS_DAMPING`, `T1_F1A_FILL` | CR-3813's runs on an off-line field that is not printed and never will be; `T1_APPB` on the printed field has replaced them. The frozen-baseline regression test of rule R11 is a separate test and stays |
| Retire | `T2_EQ19`, `T2_MEAS_EXT`, `T2_MEAS_EXT_BR`, `T2_PRED_BB` | the test article's exterior broadband is not measured above 1250 Hz |
| Retire | `PROP_BB_FIG14`, `PROP_BB_FIG17` | broadband on an assumed blade |

*Displays and records with no criterion (19): 3 test, 6 show, 3 until, 7 retire.*

| Proposal | Cases | Why |
|---|---|---|
| Show | `POLAR_R996`, `POLAR_PER`, `PER_LOADS`, `R996_FIG6`, `R996_FIG7` | the section data the source cases run on, Pereira's loads beside the measured ones, and the Report 996 trends with distance and loading |
| Show, until Phase 144 | `R996_FIG10_CIRC` | then a line on `R996_FIG10_FLAT` |
| Test | `F1A_CHORDWISE`, `CYL2D_GRID_CONV`, `MRP_D1` | the size of the compact-chord approximation, the cabin grid against a converged grid, the printed mode table as loaded |
| Until Phase 139 | `E15_STRUCT_LOSS`, `R172428_TRIM` | the measured structural loss and the trim block against NASA's printout: both are evidence for the trim-loss question |
| Until Phase 136 | `R172428_PAIRS` | used to state the share of the largest mode pair |
| Retire | `GEXT_BOUND`, `H3_ATTRIB`, `T1_F1A_MEAS_DAMP` | belong to the retired T1 family |
| Retire | `BBN_LONG`, `BBN_LEVELS`, `PER_FIG6` | no criterion and an assumed blade (BBN); spectra that Figs. 8 and 9 already cover (Pereira) |
| Retire | `MRP_RITZ` | the fitted surrogate that the App. D solver replaced; goes with the surrogate |

*Already tests only (3):* `UT_POLAR`, `UT_TRIM`, `UT_EQ8` stay as they are.

**A rule before any new case is added (written into CLAUDE.md on 2026-11-10 at the author's instruction, in general form for tests and cases).** A case is registered only if all four hold:
1. it passes the chart rule;
2. it answers a question no kept case answers;
3. its outcome cannot be told in advance from the kept cases;
4. the data's own scatter or reading error is clearly smaller than the tolerance.

Applied to the cases the open phases proposed:

| Proposed case | Phase | Passes? | Proposal |
|---|---|---|---|
| Five unscaled-load acoustic cases | 141c | No (3): the load error of R996_LOADS passes into the level | a second line on the existing scaled cases, no verdict; the author's earlier "add" to be confirmed or withdrawn |
| Loads on measured section polars | 141e | No (1): an input variant | diagnostic |
| Forward-flight loads, RM L9G06a | 141f | Yes, if the report is obtained | one case |
| TP-2444 on its own trim | 137a′ | Yes, if every input is printed | one case, replacing three |
| One more complete PAIN printout | 136e | Yes, if one exists | one case |
| R2 against flight run 10's printed field | 144a | Only for cards not yet compared | otherwise a unit test, as today |
| R2 or R1 against CR-159668's semicylinder | 144e | No (4): the report calls its own data scattered with no clear trend | no case; used as a document |
| R2 at the flat wall; the circular wall | 144b | No (3): the numbers are on record | information lines on R996_FIG10_FLAT |

**Not done yet.** No case has been moved, retired or added. The approval of 2026-11-09 covers the 43-case sorting. The rule for new tests and cases is in CLAUDE.md since 2026-11-10. The list for the 111 cases without a verdict was approved on 2026-11-10. Both lists come from the case texts: a row the code contradicts goes back to the author before it is acted on.

---

## ISSUE-028: Source, test and script files are named and grouped by phase number, and old paths remain

**Status:** partly closed 2026-11-11 by Phase 150: old paths fixed (`.gitignore`, script comments); the per-stage layout is ISSUE-040. Recorded 2026-11-09. Code organisation. No behaviour changes. Solution: Phase 150.

**Evidence.**
- **Case files named by phase.** 29 files from `src/validation_case_iso40.jl` to `validation_case_iso121.jl`, and test helpers `test/unit/test_case_helpers_iso66.jl`, `_iso67`, `_iso119`, `_iso121`, `_late`. To find R172428_EXP one has to know it was Phase 44.
- **One file for the rest.** `src/validation_case_extras.jl` is 2,604 lines: E11, E12, E14, GEXT, BBN, Report 996, Pereira, polars and the registry.
- **One test file.** `test/runtests.jl` is 3,935 lines.
- **Retired scripts are tracked.** `scripts/retired/` holds 12 files, among them `debug_f1a_scale.jl` and `debug_f1a_scale2.jl` to `debug_f1a_scale5.jl`. CLAUDE.md step 8: no stray helper scripts.
- **Old paths.** 137 mentions of `rea-work` across the Markdown, Julia and QML files (the folder is `PAIN_Program`), and `C:\Users\FrancisHoang\git\PAIN\rea-work` in `IMPLEMENTATION_PLAN.md` (R7, §2, §3 Run) and `README.md`. CLAUDE.md step 8: no machine-specific paths.
- **Phase tags in what the user sees.** Case titles end in "(44d)", "(124)", "(96a, post-hoc)"; GUI text reads "(36d / 63)".
- **Comments point at moved sections.** `IMPLEMENTATION_PLAN.md §8b` in `runtests.jl` and `src/`; those sections are in COMPLETED_PHASES.md since 2026-10-29.

**Proposed action.**
1. Case runners in one folder, one file per chain stage, named as the chart names the stages: `src/cases/blade_polars.jl`, `blade_loads.jl`, `free_field.jl`, `skin_field.jl`, `wall_modes.jl`, `cabin_modes.jl`, `damping_trim.jl`, `interior_tones.jl`, `bands_dba.jl`, and `registry.jl`. A case goes where its span ends.
2. `test/runtests.jl` becomes an include list; the testsets move to `test/cases/<stage>.jl` with the same names.
3. A mapping table (old file and line range → new file) committed with the move. The move is one commit with no edit inside any function; testset counts before and after are recorded and must be equal.
4. Delete `scripts/retired/` (git history keeps it).
5. Replace `rea-work` with `PAIN_Program` and the absolute paths with repository-relative ones. Check every `data\…` and `references\…` path in the plan against the tree.
6. Phase tags leave titles and GUI text (with ISSUE-013); they stay in the case record as a field.

**Rules that apply.** Rule R1 of the plan: no change under `src/` without the author's confirmation; this phase is marked [CONFIRM]. Line endings as R6. Frozen baselines (R11) must compare equal after the move.

**Not done yet.** No file has been moved.

---

## ISSUE-027: The source chain's two not-met cases come down to XFOIL's drag; measured section polars are in the repository and are used only as a check

**Status:** closed 2026-11-11 by Phase 141 (`COMPLETED_PHASES.md` §8ce): the coverage check was run (141d); building the measured-polar set waits on more section data and is carried by ISSUE-030 (on hold). Recorded 2026-11-09.

**Evidence.**
- `POLAR_FIDELITY`: not met 13/26 on the held-out NACA 16-312 section (|Δc_l| ≤ 0.05 at ≥ 75 %).
- `R996_LOADS`: not met 24/32 within ±15 % (C_T 11/14, C_P 13/18); worst 39 %.
- Phase 73 (bound): a c_l shift at the measured XFOIL − TN 1546 level moves thrust ≤ 7.9 %, "so the section c_l is not the cause; XFOIL's c_d is about 25 % below TN 1546's and accounts for about half the torque gap". c_d is "shown, no criterion" in POLAR_FIDELITY.
- TN 1546's measured c_l and c_d against Mach for 16-312, 16-506 and 16-509 are in `data/airfoil_measured/`. The blade is a NACA 16-series design (4-(5)(08)-03: design c_l 0.5, 8 % thick at 0.7R).
- ISSUE-001: N_crit = 8 was fitted to 16-506 and 16-509, so the XFOIL set is already tied to this data, but through a fit.

**Proposal.** A second polar set for the Report 996 blade built from the measured TN 1546 sections directly (interpolated in thickness and Mach where the blade's sections fall inside the measured range; XFOIL kept outside it and marked), with no fitted parameter. `R996_LOADS` is then re-run on it with ±15 % unchanged.

**Why this is not calibration, and where it could become one.** The polars are measured section data, taken from a different report than the loads they are compared with, and nothing is chosen by its effect on the loads. It becomes calibration if the interpolation rule, the range limits or the Reynolds correction are adjusted after the loads are seen. So the rule is written and dated first, the fraction of blade span covered by measured data is reported, and the first result stands whatever it is.

**Open questions.**
- The measured sections are 6, 9 and 12 % thick; the blade runs from 13.4 % at the root to 8 % at 0.7R and thinner outboard. How much of the span falls inside the measured range? To be computed from `blade_form.csv` before deciding; if it is under half the span the proposal is dropped.
- The result is known in direction (more drag gives more torque). Is the re-run a verdict or post-hoc? Proposed: post-hoc for `R996_LOADS` (its history is already post-hoc); the new set is judged on its own first run.

**Not done yet.** Nothing has been built or run.

**Decision (author, 2026-11-09).** Coverage check first; go on only if at least half the blade span is inside the measured range. **Found in the repository's own source:** NACA TN 1546 covers 24 sections with thickness from 6 to 30 % (search summary of the NTRS record; to confirm in the PDF's Table I); only three are digitized here. Sections thinner than 6 % are outside it. **Source found:** NACA RM L9G06a (D-26), forward-flight tests of this blade at Mach 0.175 to 0.925; a loads case on it would test any polar set on data it was not built from.

**Caution (2026-11-09 later).** A loads case on the measured polars and a forward-flight loads case (RM L9G06a) are each a new case. Under the rule for new cases of ISSUE-029 only the forward-flight one qualifies (a condition no kept case covers); the measured-polar run is a diagnostic of an input.

---

## ISSUE-026: The high-frequency noise-reduction cases miss because of the method, three of them run on assumed inputs, and the chart shows none of this

**Status:** closed 2026-11-10 by Phase 137 (`COMPLETED_PHASES.md` §8ca): the three cases on additions are retired, `NR_PROP_TP2444` stays information with the missing input named, the method-limit mark and the 1 kHz range are on the chart and plots. Recorded 2026-11-09.

**Summary.** `E22_BR` (0/4), `NR_PROP_TP2444` (1/7), `NR_PROP_TP2444_BR` (1/7), `NR_PROP_TP2444_PF` (1/7), `E21_E22_NR` (5/35) and `E22_HF_CODE` (1/4) are six of the nine not-met cases with the fewest points. The record's explanation is that PAIN itself misses here. Two things follow that the record has not acted on.

**Evidence.**
- **PAIN's own miss.** `E22_HF_CODE`: NASA − measured is +32.5, +33.5, +43.5, +37.0 dB at 1250–2500 Hz. `E22_BR`: "NASA's own high-frequency NR test, which PAIN as printed misses by about 30–40 dB". NASA states the trim model holds to about 1 kHz (§2.14). A faithful recreation cannot meet these gates.
- **Assumed inputs.** `NR_PROP_TP2444` "Not covered": "The TP-2444 fiberglass trim has no printed properties (the App. B trim is used); the microphone positions are not stated; B is assumed." `NR_PROP_TP2444_BR`: "Connections not documented for this article (V-ASSUMED)". `NR_PROP_TP2444_PF`: "The broadband field shape is taken from the nearest printed harmonic (V-ASSUMED)".
- **The rule.** Phase 118a (§2.40): "A case keeps a verdict only if every input that enters its compared quantity is printed or measured in the source it is compared with … Applied by kind". It took 14 cases off the map. The three TP-2444 cases were kept.
- **Two of the cases test a model that is not PAIN.** `_BR` adds Sharp's sound bridges and `_PF` a propeller-field coupling; §2.19 keeps them as "cases that add a model beyond PAIN". They are not (P), and as (E) they test an extension the code does not use by default.

**Proposed action.**
1. Apply the Phase 118a rule to `NR_PROP_TP2444`, `NR_PROP_TP2444_BR` and `NR_PROP_TP2444_PF`, by kind: the trim is an input of the compared NR and is not printed for this article. They become information cases with their runs, tables and recorded outcomes kept. All three are not met, so no pass is lost. Author's decision, dated.
2. `E22_BR`: check the bridge inputs against CR-172490 for the CR-3813 article in the same way. If the connections are assumed, it follows the same rule.
3. For every measurement case where NASA printed its own prediction, a generated column "NASA's printout on the same gate" (E-22: NASA is 32–44 dB over the measured mean; R172428_DB_EXP and _DBA_EXP: NASA meets 1/3; R172428_EXP: from Table 10). A row where NASA's PAIN misses the gate too is marked "method limit" on the chart. This needs no new verdict case (see ISSUE-009).
4. State in METHODOLOGY, once, the frequency above which the trim model is outside NASA's stated range, and mark bands above it on every NR plot.

**Not done yet.** No case has been moved or marked.

**Decision (author, 2026-11-09).** "yes if all inputs arent available then it should not have a verdict … there might not be a use case for these anymore you decide on that". All three TP-2444 cases lose their verdict.

**What I decided on their use, and one finding that changes the picture.** `references/NASA_TP_2444.pdf` p. 8 does print the lining of the stiffened model: three layers of fiberglass between the ring frames and a fourth over the frames, each 0.27 kg/m² and nominally 13 mm thick with a 0.05 mm vinyl film on one side; a finish trim of 0.81 mm epoxy-fiberglass sheet; the skin lined around the whole circumference and the floor bare. So the case text's "no printed properties" is too strong. What p. 8 does not give is the acoustic material table the App. A trim model needs.
- `NR_PROP_TP2444`: kept, without a verdict, until Phase 137 has checked whether the trim can be built from the printed values alone. If it can, it is registered again as a new case with complete inputs and a criterion fixed first; if not, it stays information.
- `NR_PROP_TP2444_BR` and `NR_PROP_TP2444_PF`: retired as cases. They test two additions that are not part of the shipped tool, on inputs that are assumed. Their recorded outcomes stay in the phase reports.
- `E22_BR`: goes through the chart rule in Phase 135f (the sound bridges are not the shipped default).

**Done 2026-11-10 (Phase 137a).** `NR_PROP_TP2444_BR`, `NR_PROP_TP2444_PF` and `E22_BR` are retired as cases (author 2026-11-10: "Yes, delete them"): code, tests and §2.13 entries removed; their recorded outcomes stay in the phase reports. Open: 137a′.

**Done 2026-11-10 (Phase 137a′).** TP-2444 does not name its fiberglass. CR-172428 §3.1.2 p. 16 describes the same cylinder's lining as PF-105, with the same layout, film and finish sheet, but 9.61 kg/m³ × 12.7 mm is 0.12 kg/m² per layer (about 0.19 with the film) against TP-2444's 0.27, and it adds a 120° vinyl patch. Author: CR-172428 may be used "only … if its valid", then "Yes, not valid". `NR_PROP_TP2444` stays information with no new case; its case text names the conflict in place of "no printed properties".

**Read 2026-11-09: CR-165869 pp. 2–3** describe the linings of the Langley models of the same series: 0.0127 m (0.50 in.) PF-105 fiberglass covered with a 0.0000508 m (0.002 in.) vinyl film, and lead vinyl of 2.44 kg/m². TP-2444 p. 8 gives the same layer thickness (13 mm), the same film (0.05 mm) and the same lead-vinyl weight, without naming the fiberglass in the text read so far. If TP-2444 names PF-105 anywhere, its trim is the material the trim model already has a table for, and the missing input of `NR_PROP_TP2444` is found. To check in Phase 137a′; one thing does not fit yet: TP-2444 gives 0.27 kg/m² per layer, and 13 mm of PF-105 at 9.6 kg/m³ is 0.12 kg/m² before the film (my arithmetic).

---

## ISSUE-025: CYL2D_PRINTED's not-met verdict is on a grid rule that was never adopted; the shipped grid's difference from NASA's lists has no case

**Status:** closed 2026-11-11 by Phase 140 (`COMPLETED_PHASES.md` §8cd): NASA's printed grid rule is the shipped rule, CYL2D_PRINTED tests the shipped code and is back on the chart (not met; cause in ISSUE-033), and the grid bound is stated as an uncertainty. Recorded 2026-11-09.

**Evidence.**
- The case tests "the node rule 0.45h and NY = 10 else the next grid that solves". Result: NY = 12 at both floor angles, 2-D frequencies 0/53 and 5/61 within 0.1 %. §2.34: "The rule is not adopted; defaults are unchanged."
- The code ships the rule 0.40h (§2.32). No case states what the shipped grid gives against the two printed lists. Phase 120 has it in words: at 62.6°, 2-D orders 1–4 within 1.1 %, higher orders 1.7–3.4 %.
- Diagnostic on record: NASA's narrow-body grid is NY = 8 (0.40h–0.55h); no App. C grid reproduces the small-diameter list (best 2 %). Phase 111 closed the question: the documents give no rule for the grid.
- The GUI's auto θ₀ picks 62.6° for a 2.5–2.7 m fuselage (Phase 120), which is the angle with the worst match.
- The tolerance is 0.1 %. Nobody has recorded what a 2–3 % cabin-mode frequency difference does to an interior tone level.

**Proposed action.**
1. Label the case with what it tests: "candidate grid rule (not adopted)", form field as in ISSUE-017.
2. Add an information row, no verdict: the shipped grid against the two printed lists, per 2-D order (the Phase 120 numbers, from a run).
3. A bound, no verdict, form fixed before the run: for the small-diameter aircraft, interior tone levels with NY = 8, 10 and 12 and node rules 0.40h, 0.45h and 0.55h. Report the spread per harmonic. It says whether the unexplained grid matters at the dB(A) level.
4. If the spread is above 1 dB, state it as an uncertainty of the aircraft path in METHODOLOGY §CYL2D and in the GUI's uncertainty band inputs. No grid is chosen from the comparison.

**Not done yet.** Nothing has been run.

**Decision (author, 2026-11-09), from the chart rule of ISSUE-015.** CYL2D_PRINTED tests a grid rule the code does not use, so it leaves the coverage chart; steps 2 to 4 stand. **Source found:** CR-165869 (D-23) covers "cabin acoustics with floor partition" and may state how the grid was chosen, which Phase 111 could not find in CR-3813 or the User Manual.

**Read 2026-11-09: CR-165869 pp. 60–61 print a grid rule.** Downloaded to `references/NASA_CR_165869.pdf`. Phase 111 closed this question as "not explained by the documents"; this report was not among them.
- Spacing: "The approximate grid spacing chosen is a/7. The exact grid spacing is h = Ga = a (1 + cos θ₀) / Integral Part[7 (1 + cos θ₀)]", so the number of intervals from floor to crown is NK = Integral Part[7 (1 + cos θ₀)].
- Boundary: on each grid line the last point inside the cylinder and the first point outside are compared, and "If the outside point is closest, then it must be included as part of the cylinder." The same is done along the other direction.

| Floor angle θ₀ | 7 (1 + cos θ₀) | NK by the rule | NASA's grid on record | This code (`cyl2d.jl`) |
|---|---|---|---|---|
| 50° (Merlin) | 11.50 | 11 | NY = 11, node rule 0.43h–0.50h (Phase 103) | NY = 10, 0.40h |
| 56.6° (test article) | 10.85 | 10 | NY = 10 (Fig. C-3) | NY = 10, 0.40h |
| 62.6° (small diameter) | 10.22 | 10 | not reproduced by any grid tried (Phase 105) | NY = 10, 0.40h |
| 73.7° (narrow body) | 8.96 | 8 | NY = 8, node rule 0.40h–0.55h (Phase 105) | NY = 10, 0.40h |

The third column is arithmetic done today, not a run. The rule gives the NY that the earlier diagnostics found for all three aircraft where one was found, and its boundary test (nearest of the two points, about 0.5h) lies inside both ranges those diagnostics gave. It is a rule from a document, not a fit. Caveats: CR-165869 is the 1982 report, three years before the User Manual; the nearest-point test is not the same as a radial threshold of 0.5h; 62.6° already has NY = 10 in this code and still misses, so the boundary rule would have to explain it.

**What follows.** CYL2D_PRINTED's cause changes from "not explained by the documents" to "the code does not use the documented grid rule at floor angles other than 56.6°". Phase 140 is rewritten: adopt the printed rule (a code change, to be confirmed), then run CYL2D_PRINTED once more on its unchanged criterion. With the rule adopted the case tests the shipped code and returns to the chart.

---

## ISSUE-024: FLIGHT_MODES misses its rule by two modes, and its reference file has two known misreads

**Status:** closed 2026-11-11 by Phase 142 (`COMPLETED_PHASES.md` §8cf): a blind third transcription settled the reference file (mode 41's total is 1802.69), and the one re-run on it is met, 200/221. The first run (not met, 197/221) stays on record. The remaining mass differences are ISSUE-039. Recorded 2026-11-09.

**Evidence.**
- Rule: f_r within 2 % and generalized mass within 10 % for ≥ 90 % of the listed modes. First run: 197/221 = 89.1 %. 90 % of 221 is 198.9, so 199 are needed.
- `FLIGHT_MODES_P2` (Phase 110): on the checked transcription ("four cells re-read; mode 230's M and mode 174's total corrected") the count is 199/221 = 90.0 %. Recorded as post-hoc, no verdict.
- Phase 101 planned two transcription passes and ran one. `IMPLEMENTATION_PLAN.md` rule R9: a digitization that was not checked is not valid reference data.
- What is a real difference: frequencies 219/221 within 2 %; the shell and plate normal-displacement parts of the generalized mass match NASA's printed SHELL W and PLATE W (221/221 and 218/221 within 10 %); about 20 total masses differ by 10–80 %, "mostly floor-heavy or near-degenerate modes", and the difference is in the in-plane part.

**The problem with both readings.** The first-pass verdict rests on a file with two errors in it. The second pass cannot take the verdict over as it stands: the four cells were re-read after the first run had shown which rows failed, so the correction was not blind.

**Proposed action.**
1. A full second transcription of App. C pp. 213–216 (all 221 rows, frequency and mass columns), made without the code's output or the first pass in view, then compared cell by cell with both existing files. Every disagreement is settled against the PDF and listed.
2. FLIGHT_MODES is re-run once on the settled file, with its criterion unchanged, and recorded as a re-run on corrected reference data with the date. Whether that re-run carries the verdict is the author's decision, taken before the re-run. Proposed: yes, because the correction is made against the source page and not against the result.
3. The in-plane generalized mass: compare the in-plane part mode by mode with (NASA's total − SHELL W − PLATE W) for the 20 modes. Check which in-plane terms App. D's Eqs. (D.17)–(D.29) put into the generalized mass for the floor (u and v of the plate) against `mrp_appd.jl`. A unit test per term found.
4. Pairing: the rule pairs each printed mode with the solver mode "of the same symmetry and axial order nearest in frequency". For near-degenerate pairs, report how many of the 20 swap partners under a 0.5 % frequency change.

**Not done yet.** No transcription has been made.

**Decision (author, 2026-11-09).** Yes: one re-run on a blind second transcription carries the verdict; the 197/221 stays on record as the run on the faulty file. **Sources found:** CR-165869 (D-23) for the stiffened shell with floor; Peterson and Boyd, J. Sound Vib., 1978 (D-30), the Rayleigh–Ritz study of a cylinder with an interior floor that the later literature names as the first such model, as an independent check of the floor terms (verification only).

**Read 2026-11-09: CR-165869 p. 73.** "the theory developed by Peterson and Boyd [8] which includes the full cylinder with floor, is far superior for present needs and will be integrated into the model in the future." Reference [8] is J. Sound Vib. 60(1), 45–62 (1978). So CR-3813's App. D shell-with-floor model descends from that paper, and the in-plane terms of the generalized mass can be checked against it term by term (Phase 142d).

---

## ISSUE-023: E14_LOSS (7/18) and R172428_ETA (17/32) point at the same trim term, and the one cause tested for it was refuted

**Status:** closed 2026-11-11 by Phase 139 (`COMPLETED_PHASES.md` §8cc): the band-centre idea is not supported (15 of 32 against the 24 fixed beforehand); both cases are unexplained. The search for the cause continues in ISSUE-032. Recorded 2026-11-09.

**Summary.** Both cases compare a trim-controlled loss factor with NASA's calculated values and both are low where the trim dominates. The cause on record ("I, probable: Fig. A-2 digitized at six frequencies") was tested in Phase 118 and not supported. No cause is left standing, and the two cases have not been looked at together.

**Evidence.**
- `E14_LOSS`: Eq. (78) band-average acoustic loss against NASA's calculated Fig. E-14 curve, ±25 %. 7/18, median error 39 %, max 130 %. With NASA's per-band PF-105 table in place of Fig. A-2: 6/18 (`phase118_e14_deck.md`).
- `R172428_ETA`: η_r′ of Eq. (82), ±25 %. Modes 1–12 within 13 %; modes 13–32 are 30–50 % low. §2.27: "the trim term of Eq. (82), 1.4–2.1× low above 470 Hz". Ruled out: modal masses (within 1 %), trim admittance (App. B p. 197, within 2 % to 1 kHz), truncated shapes, an included Σ η_r″, other forms of Eq. (A.8). §2.29: with NASA's PF-105 table "R172428_ETA's gap above 470 Hz remains".
- The cabin-mode loss η_n is reproduced with the same trim model once the band-centre rule is used (`APPB_ETA_N_BAND` 46/46 within 10 %). So the trim admittance is right where it enters Eq. (77), and low where it enters Eq. (82).
- The two cases use different articles and trims (E14: CR-3813 Phase III trim, η_T = 0.5; ETA: CR-172428 Table 6), so a shared cause would be in the equations' form, not in an input.

**Investigation plan.**
1. Put the band-centre rule question to Eq. (82) and Eq. (78): NASA evaluates η_n at the 1/3-octave centre (Phases 95–96). Whether the same holds for η_r′ and η̄ has not been tested. Hypothesis, with its threshold fixed and dated before the run: with ω and the trim conductance at the band centre, R172428_ETA's count rises from 17/32 by a stated margin. It is tested on R172428_ETA's unchanged criterion, as a diagnostic.
2. Held-out check before any default changes: the η_r′ NASA prints for the η_T = 2.0 run (CR-172428 p. 85, if η_r′ is printed there) or for flight run 10's deck. Criterion written and dated first.
3. Compare the ratio (this code / NASA) of R172428_ETA mode by mode against frequency and against the mode's floor share. A step at the band edges points at the band rule; a smooth trend in frequency points at the trim impedance model of App. A.
4. E14_LOSS: the same ratio per band, on the same axes. If the two ratio curves agree, record one cause for both.
5. If nothing survives, both are class U (ISSUE-019), with the ratio curves in the report.

**Not done yet.** Nothing has been run.

**Decision (author, 2026-11-09).** The band-centre idea counts as supported at 24 or more of R172428_ETA's 32 modes within ±25 %. Fixed today, before any run. **Source found:** NASA CR-165869 (Pope and Wilby, 1982; D-23), "Phase II: Models for Sidewall Trim, Stiffened Structures, and Cabin Acoustics with Floor Partition": the report in which the trim model behind Eqs. (77), (78) and (82) was developed. Not in the repository, not read.

---

## ISSUE-022: Three code-against-NASA cases are not met and are classed as a method limit, which cannot explain a difference from NASA's own program

**Status:** closed 2026-11-10 by Phase 138 (`COMPLETED_PHASES.md` §8cb): the three cases carry no verdict under the input rule, so no cause class is needed (`phase138_ref2_inputs.md`). Recorded 2026-11-09.

**Summary.** `NR_TP1964_REF2` (6/18 within ±3 dB), `NR_TP1964_XOVER_REF2` (8/18) and `E22_HF_CODE` (1/4) compare this code with NASA's printed predictions. Their recorded cause is M: "negative NR is a property of Eq. (18)" and "PAIN's high-frequency trim noise reduction exceeds the measurement". Both statements are about the method against measurement. If NASA's curve came from the same equations, the method is on both sides of the comparison and cancels. What is left is the inputs NASA used, the program NASA used, or this code.

**Evidence.**
- `NR_TP1964_REF2`: "Identical computation to NR_TP1964; reference column is Fig. 8 dashed (NASA CR-159363 Phase I / ref. 2)". The inputs are this project's reading of TP-1964 (Donnell shell, exact circular cavity, η from the measured T₆₀ of Fig. 17). No record shows that ref. 2's prediction used those inputs. `references/NASA_CR_159363.pdf` is in the repository.
- `NR_TP1964_XOVER_REF2`: the four Eq. (19) bands are 3/4 within ±3 dB; the misses are Eq. (18) bands (1–2 kHz, 100–315 Hz).
- `E22_HF_CODE`: code − NASA +7.7, +2.1, −6.5, −5.6 dB. "Not covered: NASA's 1983 high-frequency routine is not printed." With NASA's 300 modes the code is 6–19 dB below NASA (E22_HF_DECK, Phase 83).
- Class M in `phase118_full_input_misses.md` for all three; class N for E22_HF_CODE in §2.14.
- Phase 118a's rule: a case keeps a verdict only if every input is printed or measured in the source it is compared with. Whether NASA's ref. 2 inputs are printed has not been checked.

**Investigation plan.**
1. Read CR-159363 for the Phase I prediction of the TP-1964 cylinder: structural and acoustic loss factors, mode sets, band rule, whether Eq. (18) was used to 5 kHz. List each input beside this code's.
2. If an input differs and is printed, the case is re-run with NASA's printed input. That is an input correction against the source document, not a fit; the criterion stays; the result is a dated re-run.
3. If the inputs are not printed, the two REF2 cases fail the Phase 118a rule and carry no verdict (applied by kind, as 118a was).
4. For the bands that still miss with NASA's inputs: band by band, the terms of Eq. (18) (resonant modes in band, joint acceptance, loss factors) against any intermediate value CR-159363 prints.
5. `E22_HF_CODE`: the same question for Eqs. (19)–(23). The documents do not print the routine, so the likely end is class U with the sign pattern recorded (+ at 1250–1600 Hz, − at 2000–2500 Hz).

**Not done yet.** CR-159363 has not been read for these inputs.

---

## ISSUE-021: A verdict reached after a post-hoc change looks the same on the chart as a first-run verdict

**Status:** closed 2026-11-11 by Phase 145 (`COMPLETED_PHASES.md` §8ci; `phase145_summary_writer.md`, `phase145_independence_records.md`). Recorded 2026-11-09. Labels. No verdict changes. Solution: Phase 145. Related: ISSUE-001.

**Summary.** CLAUDE.md: "any value chosen after seeing a result makes that result post-hoc (calibrated), not a pass." The case texts keep this distinction; §0, the CSV and the chart drop it.

**Evidence (met cases, 16 on the chart).**

| Case | First run | Now | What changed in between |
|---|---|---|---|
| APPB_ETA_RPP | not met 8/19 (2026-10-29) | met 16/19 | Phase 100 deck table, then Phase 106 (2-D cabin-mode part at 341 m/s), recorded as "post-hoc" |
| R996_FIG14 | not met 5/24 | met 24/24 | amplitude convention (37b), polars (Phase 69), observer side (Phase 72), thickness term (Phase 76) |
| R996_FIG12 | not met 19/40 | met 32/40 | the same |
| R996_FIG13A | not met 6/14 | met 14/14 | the same; met since Phase 72 |
| PER_FIG7 | not met 2/3 | met 3/3 | Phase 76 thickness term |
| MRP_APPD | not met 2/32 | met 32/32 | Phases 78d and 80: stiffener inertias, orthotropic floor, shape convention, then NASA's deck from the User Manual |
| T1_APPB, T1_MEAS_DAMPING_APPB | met (first run 2026-11-02) | met | case text: "Not held out in full" |

Among the not-met cases the same holds for R172428_CODE (3/9 → 5/9), R996_LOADS (6/32 → 24/32; `**Category:** calibrated`) and APPB_ETA_N (11/46 → 16/46 → 12/46).

Each change above was a documented defect fix or a documented input, not a fit, and each is dated in its case text. The point is that the reader of the chart cannot tell which met verdicts are first-run results (for example R172428_ETAT2, APPB_ETA_N_T2, APPB_EPS_N, R996_FIG10_FLAT) and which were reached after the result had been seen.

**Proposed action.**
1. Two fields per case, written from the case text: `first_run` (date, verdict, count) and `changes_since` (list of phases).
2. The chart marks a verdict reached after a change (hatched bar or a "†"); §0 gains a "First run" column.
3. Decision for the author: is a met verdict that was not met at first run shown as "met" or as "met (post-hoc)"? Under the CLAUDE.md sentence above it is the second. Proposed: "met (post-hoc)", counted apart from first-run met in §0's totals.

**Not done yet.** No field or mark has been added.

**Decision (author, 2026-11-09).** "this needs to be proven that its not circular somehow on the coverage map or somewhere accessible by the reader". So no label alone. Each verdict that was reached after a change gets an independence record: every change between the first run and the current result, the document or independent check each change rests on, and a yes or no to "was the compared data used to choose it". A case whose record cannot show independence carries no verdict. The record opens from the chart row and is listed on the short validation page (Phase 145c).

---

## ISSUE-020: The Points and Error columns count rows that are not in the verdict, and some labels do not say what the number is

**Status:** closed 2026-11-11 by Phase 145 (`COMPLETED_PHASES.md` §8ci; `phase145_summary_writer.md`, `phase145_independence_records.md`). Recorded 2026-11-09. Labels (CLAUDE.md step 7). No verdict changes. Solution: Phase 145.

**Evidence** (`case_error_summary.csv`, §0).
- **Rows outside the verdict are counted.** `POLAR_FIDELITY` shows 40/61; the verdict is on the held-out 16-312 section, 13/26. The other 27/35 are the two sections N_crit was fitted to. `CYL2D_PRINTED` shows 57/168; the two held-out aircraft are 0/53 and 5/61, and 51 of the 57 are the Merlin list, which the case text calls "seen" and "post-hoc".
- **Rows are not points.** `T1_APPB` shows "met 4/6, max |err| 9.5 dB" and `T1_MEAS_DAMPING_APPB` "met 5/6, max |err| 11.0 dB"; the case text says met 3/3 (three tones, each through gate A or gate B). The table has a row per gate.
- **A met case with a very large error.** `APPB_ETA_RPP`: "met 16/19, max |err| 850 %". The criterion is ≥ 80 % of pairs within 10 %, so three pairs may miss by any amount. The line is true and reads as a mistake.
- **Missing or broken numbers.** `R172428_ETA`: "17/32 within criterion", no error size. `R172428_TRIM_DECK`: "max |err| NaN  · med NaN". `LOUDEST_PT`, `UNC_COVER`: no error.
- **Units that are not units.** "dimensionless", "abs", "stations", "m³ | m² | m", "dB | deg", "N | W | -".
- **Rounding.** Two significant figures turn 42.2° into "42.0 deg" and 12.4 dB(A) into "12.0 dB(A)".

**Proposed action.**
1. `ValidationTableRow` gets an `in_verdict` flag; the summary counts and takes the worst error over those rows only, and says "+ n shown, not judged" for the rest.
2. A case with gates reports tones through the gate, not rows.
3. The error line states the rule beside the count where the rule is a fraction ("16/19, needs 80 %").
4. Fix the NaN text; give every case an error size or the words "no error size (count only)".
5. Units from the case's own definition; a ratio is written "ratio", an absolute difference of a loss factor "(loss factor)".
6. Round to one decimal, not two significant figures.

**Rule that applies.** The numbers in the CSV change (40/61 becomes 13/26 and so on) with no verdict changing. The change is recorded as a display correction with before and after for every row that moves.

**Not done yet.** Nothing changed.

---

## ISSUE-019: There is no single current statement of why each case is not met; the three that exist disagree

**Status:** closed 2026-11-11 by Phase 145 (`COMPLETED_PHASES.md` §8ci; `phase145_summary_writer.md`, `phase145_independence_records.md`). Recorded 2026-11-09. Documentation. No verdict changes. Solution: Phases 135 and 145.

**Summary.** The cause of a not-met case is written in §2.14 (2026-10-24, amended four times), in `validation_reports/phase118_full_input_misses.md` (points from the 2026-10-30 snapshot) and inside each case's "Recorded outcome". They differ, and four current not-met cases are in none of the tables.

**Evidence.**
- **Missing.** `R172428_DB_CODE`, `R172428_DBA_CODE`, `R172428_DB_EXP`, `R172428_DBA_EXP` (Phase 124, 2026-11-04) have no cause class anywhere. §2.14 has no row for CYL2D_PRINTED, FLIGHT_MODES or APPB_ETA_N.
- **No longer verdict cases but still listed.** §2.14 lists 14 cases that Phase 118a took off the map (T1, T2_EQ19, BBN_CIRC and others) and seven that Phase 82 made information.
- **Contradictions.** `E22_HF_CODE`: class N in §2.14, class M in the Phase 118 table. `E14_LOSS`: "I (probable)" in §2.14 and in the Phase 118 table, whose own note says the one test of that cause was "Not supported" (6/18 against 7/18 with NASA's per-band PF-105 table); the case text says "attributed to model fidelity (method)". So E14_LOSS has three stated causes and the only tested one was refuted.
- **A class that cannot be the cause.** For a case compared with NASA's printed prediction, class M ("PAIN's method as printed") explains a miss against measurement, not a difference between this code and NASA's program running the same method. `NR_TP1964_REF2`, `NR_TP1964_XOVER_REF2` and `E22_HF_CODE` carry M (ISSUE-022).
- **"Untested cause: none" in every row** of the Phase 118 table, while ISSUE-017 shows four rows whose cause is known and three (ISSUE-022, ISSUE-023) whose cause is not.

**Proposed action.**
1. One `cause` record per not-met case, in the case data: class, one sentence, the phases that tested it, what is left. Written once in Phase 135 from the existing record, each sentence citing its report.
2. Two more causes beside the five on record: *old program form* (judged on a program form that is not the shipped default, ISSUE-017) and *unexplained* (no documented cause survives its test). "Unexplained" is honest where "method" or "input, probable" is not.
3. The "why not met" table of the short validation page (ISSUE-016) is generated from these records, with the chart. §2.14 becomes history.
4. A test that fails if a not-met case has no `cause` record.

**Proposed causes for the 27, from the record (to be checked in Phase 135, not adopted here).**

| Cause | Cases |
|---|---|
| Old program form | R172428_CODE, R172428_DB_CODE, R172428_DBA_CODE, APPB_ETA_N |
| PAIN's method misses the measurement (NASA's own printout misses the same way) | E22_BR, E21_E22_NR (N and M on record), NR_PROP_TP2444, NR_PROP_TP2444_BR, R172428_EXP, R172428_DB_EXP, R172428_DBA_EXP, NR_TP1964, NR_TP1964_XOVER |
| Approximation in this recreation | POLAR_FIDELITY, R996_LOADS, R996_PHASE, NR_PROP_TP2444_PF |
| NASA's printout or the measurement, not explained by the documents | CYL2D_PRINTED, R172428_ETA, PER_FIG8, PER_FIG9 |
| Reference data | FLIGHT_MODES (ISSUE-024), E12_BLOCK (ISSUE-007) |
| Unexplained | E14_LOSS, NR_TP1964_REF2, NR_TP1964_XOVER_REF2, E22_HF_CODE |

**Not done yet.** No cause record has been written.

**Decision (author, 2026-11-09).** Yes to the two new causes, with plain names and no letters. The names used from here on: *old program form*; *PAIN's method misses the measurement*; *approximation in this recreation*; *reference data*; *NASA's printout or the measurement, not explained by the documents*; *unexplained (no documented cause survived its test)*. The letter classes in the tables above are kept only as the record's existing labels.

---

## ISSUE-018: 27 not-met rows are about 14 separate comparisons; variants and sums of one comparison each count as a case

**Status:** closed 2026-11-11 by Phases 145 and 146: one family per comparison, 20 cases with a verdict and 20 independent comparisons. Phase 145d done 2026-11-11: families and parents in `CASE_FAMILIES`. Recorded 2026-11-09. Presentation only. No verdict changes. Solution: Phases 145 and 146.

**Summary.** The chart and §0 count every registered variant as its own case. A reader sees 16 not-met rows in "Validation comparisons" and takes them for 16 failures.

**Evidence (families among the 27 not-met cases).**

| Family | Cases | What they share |
|---|---|---|
| CR-172428 interior tones | R172428_CODE, R172428_DB_CODE, R172428_DBA_CODE | the dB and dB(A) cases are energy sums of R172428_CODE's nine levels (`_run_r172428_dba` on `_r172428_levels`) |
| The same against measurement | R172428_EXP, R172428_DB_EXP, R172428_DBA_EXP | sums of R172428_EXP's nine levels |
| TP-1964 bare cylinder | NR_TP1964, NR_TP1964_REF2, NR_TP1964_XOVER, NR_TP1964_XOVER_REF2 | one computation, with and without the changeover, each against the measured curve and NASA's curve of Fig. 8 |
| TP-2444 propeller-noise NR | NR_PROP_TP2444, NR_PROP_TP2444_PF, NR_PROP_TP2444_BR | one measured NR; three models (PAIN as printed; two additions that are not PAIN) |
| Fig. E-22 high-frequency NR | E22_HF_CODE, E22_BR, E21_E22_NR (its E-22 part) | Eqs. (19)–(23) on the E-21 inputs |
| Pereira levels | PER_FIG8, PER_FIG9 | Phase 74: Fig. 9 equals Fig. 8 within 0.1 dB at the shared angles; both miss H2 at φ = 20° by +3.7 dB |
| Source loads | POLAR_FIDELITY, R996_LOADS | §2.14 gives one cause for both |

Single cases: R996_PHASE, E12_BLOCK, CYL2D_PRINTED, FLIGHT_MODES, E14_LOSS, R172428_ETA, APPB_ETA_N.

**Proposed action.**
1. A `family` field per case and a `derived_from` field where one case is computed from another's output.
2. The chart draws a family as one group with its members inside it. §0 states both counts: cases and independent comparisons.
3. A derived case (a sum, a re-run against a second curve) is drawn smaller, so the eye counts the parents.
4. No case is removed and no verdict is merged.

**Not done yet.** No field has been added. The family list above is from the case texts and needs your check.

**Note (2026-11-09).** The chart rule of ISSUE-015 removes several of these rows before any grouping: the two `_CODE` sums, the TP-2444 family and the sound-bridge variants. The family list is redone on what remains (Phase 145d).

---

## ISSUE-017: Four not-met verdicts are on a program form the code no longer runs by default; the default form reproduces the same NASA printouts

**Status:** closed 2026-11-10 by Phase 136 (`COMPLETED_PHASES.md` §8bz): the case is a diagnostic on the old program form, its title names the form, and its reason names the shipped-form cases; the shipped form's held-out test of all its parts is ISSUE-034. Was: open. Recorded 2026-11-09. Labelling and classification. No verdict, criterion or recorded result changes. Solution: Phase 136. Corrects the premise of ISSUE-014.

**Summary.** `R172428_CODE` (5/9), `R172428_DB_CODE` (0/3), `R172428_DBA_CODE` (0/3) and `APPB_ETA_N` (12/46) are judged on the form each was first registered with. That form was replaced as the default by Phases 93, 96 and 100 because NASA's printouts showed the CR-172428 program ran differently. On the chart they read as "the code does not reproduce NASA's PAIN". The record says the opposite for the code as it ships. These four are a seventh of the 27 not-met cases, and two of the four cases with 0 points.

**Evidence.**

| Not-met case (form it is judged on) | Same printout, code as it ships (post-hoc, no verdict) | Held-out check of the shipped form |
|---|---|---|
| `R172428_CODE` 5/9, max 13.0 dB (CR-3813 tone sum: q = 0 coupled, η_n at the mode frequency) | `R172428_CODE_DEFAULT` 9/9, largest 1.19 dB | `R172428_ETAT2` **met** 9/9, largest 1.73 dB (Table 12, η_T = 2.0; criterion fixed before the run) |
| `R172428_DB_CODE` 0/3, max 13.0 dB | within 0.7 dB at all 3 rpm | none for the sums |
| `R172428_DBA_CODE` 0/3, max 12.4 dB(A) | within 0.9 dB(A) at all 3 rpm | none for the sums |
| `APPB_ETA_N` 12/46 (η_n at the mode's own frequency) | `APPB_ETA_N_BAND` 46/46 within 10 %, 43/46 within 2 % (band-centre rule) | `APPB_ETA_N_T2_BAND` **met** 3/3; `APPB_ETA_N_T2` **met** 3/3 |

- §2.25: "R172428_CODE keeps CR-3813's tone sum and its not-met verdict."
- The shipped form cannot take over the verdict on the same printouts: it was read from them (Phase 92), which is why its results are post-hoc. That part of the record is right.
- `R172428_DBA_EXP` and `R172428_DB_EXP` already run the default form (their case text says so), so the `_CODE` and `_EXP` twins do not run the same code.

**Why it matters.** The question the chart is read for is "does this code work like PAIN?". For the cabin chain on the test article the held-out answer is yes (`R172428_ETAT2`). The four rows above answer a different question: "does CR-3813's printed form reproduce CR-172428's printout?" The answer to that is no, and it is a finding about NASA's two documents.

**Proposed action.**
1. Add a `form` field to these four cases ("CR-3813 printed form; not the shipped default") and show it on the chart row and in the title.
2. Show each with its pair: the default-form result beside it, labelled post-hoc, and the held-out case that tests the default form.
3. Decision for the author, by kind and dated: does a case that runs a superseded program form stay a verdict case, or is it a diagnostic (the Phase 86 kind: "a re-run with one program form changed")? All four are not met, so no met case is lost either way. Proposed: they stay on the chart with the `form` label; the verdict is true for what it tests.
4. Look for one more NASA printout the default form has not been set against, so the sums have a held-out check too. Candidates on record: flight run 10's printed levels (FLIGHT10_H234 is post-hoc after Phases 104 and 108, so no longer clean); CR-172428's other aircraft, if a complete run is printed. If none exists, say so.

**Not done yet.** No label has been added.

**Decision (author, 2026-11-09).** "if there isnt a weight on the validity of the tool should it still be on the coverage map": no. The four old-form cases leave the coverage chart and are kept as diagnostics with their results. The chart shows the cases that test the shipped form (R172428_ETAT2, APPB_ETA_N_T2, APPB_ETA_N_T2_BAND). Step 3 above is closed; steps 1 and 2 apply to the diagnostics list.

---

## ISSUE-016: VALIDATION_GUIDELINE.md is 4,566 lines and mixes four jobs; rebuild it around the coverage chart

**Status:** closed 2026-11-11 by Phase 148 (`COMPLETED_PHASES.md` §8cl): `VALIDATION.md` (status page), `CASE_RECORDS.md` (case records), `VALIDATION_HISTORY.md` (phase notes); the guideline keeps the criteria. Recorded 2026-11-09. Raised by the user ("i dont like my validation guideline either its lengthy and ive only been looking at the coverage map"). Documentation only. No verdict, criterion or recorded result changes. Solution: Phase 148.

**Summary.** One file is the generated status page, the pre-registered criteria, the machine-readable case records the GUI parses, and a diary of phases. The part that is read (the chart and its table) is 50 lines of it.

**Evidence.**

| Part | Lines | What it is |
|---|---|---|
| §0 status (generated) | 3–293 | the chart, the chain table, the not-met table; also the block map and eight per-group tables that repeat the same rows (ISSUE-015) |
| §1 – §2.12 | 295–947 | validity classes, sources, the criteria as pre-registered (dated; must not change) |
| §2.13 case records | 948–4024 | 154 cases × about 18 lines, parsed by `src/validation_map.jl`; two thirds of the file |
| §2.14 – §2.56 | 4025–4490 | one section per phase from 62 to 134; the same phases are in COMPLETED_PHASES.md |
| §3 – §7 | 4491–4566 | definitions, runner notes, references |

- **The diary is out of order and out of date.** After §2.49 the sections run §2.56, 2.55, 2.54, 2.53, 2.52, 2.51, 2.50. §2.14 is headed "every case that is not met, and why (2026-10-24)" and carries four later amendments in one paragraph ("Superseded", "Rerun", "Amended", then "The text that follows is the 2026-10-24 statement"). The case totals differ by section: "41 cases: 8 met, 33 not met" (§2.19), "48" (§2.23), "37 cases: 14 met, 23 not met" (§2.40); §0 has 43 (16 met, 27 not met).
- **Stale numbers outside the generated part.** §1.1 gives `AC_C695A_DBA` as "0/36 within ±3.5 dB"; the record since Phase 123 is 35/36 (`case_error_summary.csv`, 2026-11-04).
- **Case records hold their own history.** A "Recorded outcome" field can hold four dated results in one paragraph (R172428_CODE: 3/9, 4/9, 5/9; APPB_ETA_N: 11/46, 16/46, 12/46). The current value has to be found by reading to the end.
- **Headings.** "## 2.13" to "## 2.56" are level-2 headings under "## 2."; the file's outline does not nest.

**Proposed action.** Four files, each with one job; no fact kept in two places.
1. **`VALIDATION.md` (new, generated, about 200 lines).** The chart, one row per verdict case (title, span, compared with, verdict, points, cause class), the not-met table with a one-line cause each (ISSUE-019). This is the page to read.
2. **Case records as data.** One record per case in a data file (`data/validation/cases.toml` or one file per chain stage), read by the GUI in place of the Markdown parse. Fields as today plus `figure`, `family`, `form`, `first_run`, `cause` (ISSUES 010, 017, 018, 019, 021). "Recorded outcome" becomes `current` (one result, dated) and `history` (a list).
3. **`CRITERIA.md`.** §1 to §2.12 unchanged in wording, with every criterion's date. Append-only.
4. **History.** §2.14 to §2.56 are checked against COMPLETED_PHASES.md section by section; what is missing there is moved, the rest is deleted from the guideline.

**Rules that apply.**
- Step 2 moves text that the GUI and the site parse. It is a code change: the same 154 cases must load before and after, with the same verdicts and counts (`case_error_summary.csv` unchanged byte for byte apart from its date line).
- No criterion text or date changes in the move. A diff of the criteria before and after must be empty.
- CLAUDE.md names VALIDATION_GUIDELINE.md in its update list. The new list is yours to approve before any file is split.

**Open questions.**
- Keep the name `VALIDATION_GUIDELINE.md` for the criteria file, so old references still resolve? Proposed: yes; the short page takes the new name.
- TOML or YAML for the records? Proposed: TOML (Julia reads it without a new package; Cabin_Noise's `cases.yaml` is a separate project).

**Not done yet.** No file has been split.

**Decision (author, 2026-11-09).** The short page must be one a reader can find things on: mostly the chart and tables, little text, and no letter codes ("like i said i dont like abbreviations but yes there needs to be an accessible page not filled with text that makes it easier for the reader to find").

---

## ISSUE-015: Retire the block validation map; the chain coverage chart is the view that is used

**Status:** closed 2026-11-11 by Phase 147 (`COMPLETED_PHASES.md` §8ck): the map tab and §0's map are gone; the block records remain only as figure folders and the case order. Recorded 2026-11-09. Raised by the user ("i also dont see the point in using the validation map anymore"; "ive only been looking at the coverage map"). Presentation only. No verdict, criterion or recorded result changes. No code changed. Solution: Phase 147.

**Summary.** The project draws the same 43 verdict cases twice: on the block validation map (§0's Mermaid flowchart, the GUI's Validation map tab) and on the chain coverage chart (Phase 134, the GUI's Coverage tab). Only the chart is read. The map costs code, tests and document text on every change, and it misplaces cases.

**Evidence.**
- **It misplaces cases.** `NR_TP1964_REF2` sits in the block "vs measurement" (`**Map / block:** total / P_MEAS`) and is compared with NASA's printed prediction; §0's not-met table repeats "vs measurement" for it. `APPB_ETA_RPP` sits in "Coupling / Eq. 8" (group PAIN main) with the chain span Damping and trim → Damping and trim. A block has one place for a case; a case spans several stages.
- **Most of it is empty.** 16 of the 28 blocks hold no case with a verdict and are drawn grey (§0, `class … none`).
- **What it costs.** `src/validation_map.jl`: `MapBlock`, `ValidationMap`, `validation_map_json`, `map_block_info_json` and the layout code from line 521 to the end (cell sizes, group rectangles, the disjoint check), about a third of its 639 lines. `gui/main.qml`: the Validation map page (from line 1133) and its helpers (from line 222). §2.13: the `### Map:` and 28 `#### Block:` records (lines 952–1212) and a `**Map / block:**` line in each of 154 cases. `test/unit/test_validation_map.jl`, both smoke scripts, and the map text in README, METHODOLOGY, flowchart and WALKTHROUGH.
- **What depends on it.** `site/build_site.jl` builds each stage's diagram from the blocks' `Position` / `Feeds` / `Group` fields (lines 247–300) and lists cases in map order. `on_validation_map` is the test for "has a verdict" used by the scoreboard, the site and `NO_VERDICT_CASES.md`. The case parser (`CaseInfo`, `**Chain span:**`, `**Compared with:**`) lives in the same file and is what the chart reads.

**Proposed action.**
1. Remove the Validation map tab and §0's Mermaid map and per-group tables. §0 keeps the chart, the chain table and the not-met table.
2. Keep the case parser and the coverage code. Rename `on_validation_map` to `has_verdict` (same rule, same result).
3. Replace the `Block` column of the not-met table with `Chain span` and `Compared with`, which the chart already uses.
4. The website groups its cards by the nine chain stages instead of map groups; each stage's diagram is drawn from the stage list.
5. Delete the `### Map:` / `#### Block:` records and the `**Map / block:**` field once nothing reads them. The parser test changes from "every block exists" to "every case has a span and a reference".

**Open questions.**
- Does the same apply to Cabin_Noise's map (`cabin_noise/gui/validation_map.py`, `data/validation/map.yaml`, `tests/test_validation_map.py`)? Proposed: ask first; this issue is PAIN only.
- The Validation tab orders its case list by map order today. Proposed: order by chain span, then by figure (ISSUE-010).

**Not done yet.** Nothing has been removed.

**Decisions (author, 2026-11-09).** PAIN only; Cabin_Noise keeps its map for now. The coverage chart gets a rule, applied to all 43 cases (Phase 135f): a case is on the chart only if it weighs on the validity of the tool as shipped, meaning it runs the shipped code, every input is printed or measured, and it is compared with a measurement or with NASA's program output.

---

## ISSUE-014: R172428_CODE is not met (5/9 within ±3 dB of NASA's printed prediction): find the cause in PAIN's code

**Status:** closed 2026-11-10 by Phase 136 (`COMPLETED_PHASES.md` §8bz): the case is a diagnostic on the old program form, its title names the form, and its reason names the shipped-form cases; the shipped form's held-out test of all its parts is ISSUE-034. Was: open. Recorded 2026-11-09. Investigation only. No criterion, tolerance, reference data, recorded result or verdict changes. No code changed until a cause is found and its fix is dated and reviewed.

**Problem.** R172428_CODE runs PAIN's cabin chain on NASA's own printed CR-172428 inputs (App. B blocked field, Table 6, App. B trim) and compares the nine interior tone levels (3000/4000/5000 rpm, H1–H3) with NASA's printed predictions. The criterion, fixed 2026-10-23 before any run, is ±3 dB at ≥ 7 of 9 points. The current record is 5/9 within tolerance, max |err| 13.0 dB, median 2.8 dB (`docs/validation_reports/case_error_summary.csv` line 118). The case is not met. Because the inputs are NASA's own, a miss here is a code miss, not an input miss. The gap is large (up to 13 dB at a point) and the case should be explained, not just recorded.

**How the record got here (read before investigating).**
- First run (2026-10-23): **3/9**. Ours − NASA: 3000 rpm +5.0 / +2.8 / +1.1; 4000 rpm +8.6 / −3.5 / +2.6; 5000 rpm +3.1 / +7.6 / +3.5 dB (`docs/VALIDATION_GUIDELINE.md`, Case: R172428_CODE).
- Phase 44f (2026-10-23, Eq. (52) floor-term sign): **4/9**. Recorded as post-hoc. Chosen after seeing the nine points, so it is a knock-on, not a pass.
- Phase 106 (2026-10-30, 2-D cabin-mode part at 341 m/s): **5/9**. Recorded as post-hoc. Also found while looking at the same case.
- So the current 5/9 is the result after two post-hoc code changes. Neither is a verdict change. Both moved the same nine points that the case judges, and they are not independent checks.
- Tried and not adopted: q = 0 excluded (Phases 88, 92; Q22: would give 8/9, diagnostic only, no documentary basis); 300 structural modes (`R172428_CODE_DECK`, 4/9); per-mode η_n (`R172428_CODE_ETAN`, 5/9, not adopted); band-centre η_n (Phase 96); the default form (`R172428_CODE_DEFAULT`, 9/9, but it is post-hoc and the form was inferred from a different case).

**Evidence that points at the code, not the inputs.**
- The inputs are NASA's printed values, so every input-side change was already tested (`docs/validation_reports/phase118_full_input_misses.md`: R172428_CODE judged on the fixed CR-3813 tone form, no input miss found).
- The misses are not one sign or one band. H1 at 3000 and 5000 rpm and H3 at 4000 rpm are the largest; the 4000 rpm H2/H3 agree within 2 dB after the Phase 44f change.
- The largest single contributor is the (0,1) × mode 8 pair at H1, which is an open item (Q22) with no documentary explanation (`docs/COMPLETED_PHASES.md` Q22).

**Affected cases.**
- R172428_CODE (the case in question; not met, 5/9).
- Cases that share its chain and inputs and would move with it: R172428_CODE_DECK, R172428_CODE_ETAN, R172428_CODE_DEFAULT, R172428_CODE_Q0 (diagnostics), R172428_DB_CODE and R172428_DBA_CODE (not met, 0/3 each, dB and dB(A) sums of the same levels), R172428_EXP (not met, 5/9), R172428_ETA (not met, 17/32; the η_r′ part of the chain).

**Investigation plan.**
1. **Localise by stage.** For each of the nine points, split the chain into its stages (blocked field, modal coupling per mode, modal radiation/transmission into the cabin, tone sum) and compare each stage with the matching stage in NASA's App. B tables where NASA prints them (App. B p. 206 and the per-mode pair tables `appB_contributors_*rpm.csv`). The first stage whose value departs from NASA's printed value is the candidate cause. Use only the printed NASA values; do not tune to the nine final levels.
2. **Test the candidate on a different reference, not on the nine points.** Any cause found must be checked on a held-out printed quantity: the per-mode pair values at 5000 rpm (already used as held out in Phase 44f, state which points are used) or the Table 12 / E-series cases in `docs/validation_reports/phase94_table12_eta_T2.md`. The pass criterion for that check is written and dated before the run.
3. **Record every hypothesis, including those that fail.** Each one gets a row: what is changed, the criterion date, the result on the held-out check, and whether it is post-hoc. Do not change the R172428_CODE criterion (±3 dB, ≥ 7/9) to make a result pass.
4. **Check for a documentary basis.** For any change to a formula or sign, cite the equation in CR-3813 or CR-172428 that supports it (the Q22 review found CR-3813 Eq. (57) and CR-159363 Eq. 25 both give f₀M = 2/(Mπ) ≠ 0, so the documents do not yet explain NASA's q = 0 output). A change without a documentary basis is a candidate only.

**Rules that apply.**
- Pass criteria are fixed and dated before the comparison. A value chosen after seeing the R172428_CODE result makes that result post-hoc.
- A change that moves R172428_CODE's nine points is not a validation of R172428_CODE. It needs a held-out check (step 2).
- A physics change needs its intended physical effect shown, and the affected cases listed above re-run and reported.
- Documentation changes follow the PAIN document list in CLAUDE.md. Code changes need `julia --project=. -e "using Pkg; Pkg.test()"` from `PAIN_Program\PAIN.jl` (affected testsets).

**Open questions.**
- Is the 5/9 count (after the post-hoc knock-ons) to be the recorded verdict, or should the record show the first-run 3/9 as the pre-registered result? Proposed: keep 5/9 as the current recorded verdict with its post-hoc label; the investigation does not change it.
- Is the (0,1) × mode 8 H1 pair the cause, or a symptom? Proposed: decide after step 1 with the stage comparison.

**Not done yet.** No stage comparison has been run and no hypothesis has been tested under this ticket.

**Correction and solution (2026-11-09) → Phase 136.** The cause of this not-met is on record, and it is not an unexplained code miss; see ISSUE-017.
- R172428_CODE is judged on the CR-3813 tone form (q = 0 cabin modes coupled, η_n at each mode's own frequency). NASA's CR-172428 program did not run that form. `R172428_CODE_DEFAULT` is not "tried and not adopted": Phases 93 and 96 made it the code's default. It reproduces the nine points at 9/9, largest 1.19 dB, post-hoc because the form was read from these printouts.
- The form was then tested on a NASA run no phase had used (Table 12, η_T = 2.0): `R172428_ETAT2` met 9/9, largest 1.73 dB, criterion fixed before the run.
- So the stage localisation of this ticket has an answer already for the frozen form (the q = 0 pairs and η_n). What is left to do is presentation (ISSUE-017) and, if wanted, one more held-out NASA printout for the default form.
- **Open questions.** Keep 5/9 with its post-hoc label. The (0,1) × mode 8 pair at H1 is consistent with the q = 0 finding of Phase 92 (q = 0 cabin modes carry 70–92 % of three tones and NASA lists none); Phase 136 states this pair's share with q = 0 on and off, from the existing `R172428_PAIRS` output.

**Decision (author, 2026-11-09).** See ISSUE-017: R172428_CODE leaves the coverage chart.

---

## ISSUE-013: Validation case names and document abbreviations are not explained where they are used (T1, T2, T1_MEAS_DAMPING, T2_EQ19 and similar)

**Status:** closed 2026-11-11 by Phase 146 (`COMPLETED_PHASES.md` §8cj; `phase146_plain_titles.md`). Recorded 2026-11-09. Documentation and labelling only. No verdict, criterion or recorded result changes. No code changed.

**Problem.** Short labels such as `T1`, `T2`, `T1_APPB`, `T1_MEAS_DAMPING`, `T2_EQ19`, `T2_MEAS_EXT`, `E12_BLOCK`, `R996_FIG14` and `APPB_ETA_N_T2_BAND` are used in the GUI, the validation map, the coverage tab, the case IDs and the documents without a definition at the point of use. The reader has to search `docs/METHODOLOGY.md` and `docs/VALIDATION_GUIDELINE.md` to learn what each one is, and even the author cannot read some of them without searching. For example, `T1` is the whole-chain cabin noise check against measurement, `T2` is the high-frequency (broadband) check, and `T1_MEAS_DAMPING` is `T1` run with measured damping.

**Evidence.**
- `PAIN.jl/src/validation_cases.jl` defines the case IDs; the codes above appear there (`T1`, `T2` seven times each; `T2_EQ19` four times; `T1_MEAS_DAMPING`, `T1_FROM_E12`, `T1_F1A_FILL`, `T2_PRED_BB`, `T2_MEAS_EXT`, `T2_MEAS_EXT_BR`, `T2_EQ19_DECK`).
- `docs/VALIDATION_GUIDELINE.md` and `docs/METHODOLOGY.md` use the same codes in tables and sentences (for example the §2.2.1 `GEXT_BOUND` row says "a variant flips T1, so T1 is not claimable") without giving the expansion where the code first appears.
- The GUI validation map and coverage tab show the case IDs as chip and row labels.
- Prefixes such as `E12`, `E18`, `E21`, `E22`, `R996`, `R172428`, `PER`, `APPB` and `CYL2D` are not expanded in the case list either.

**Wanted.**
1. Every abbreviation used as a case ID, block name or document heading is expanded once, where it first appears in each document, with a one-line meaning (for example "T1 — whole-chain cabin noise against measurement, CR-172428 Table 12 / NASA E-series data"). The source of the expansion is the document section that defines the check.
2. A glossary table (one place only) lists every case-ID prefix and every suffix pattern (`_MEAS_`, `_EQ19`, `_BLOCK`, `_FIG`, `_EXP`, `_CODE`, `_DECK`, `_DB`, `_ETA`), with what each one means and where it is defined. The glossary lives in `docs/METHODOLOGY.md` and is linked from `docs/VALIDATION_GUIDELINE.md`.
3. The GUI shows the one-line meaning next to each case ID on the validation map chip detail and on the coverage tab row tooltip, taken from the case's own §2.13 fields, not a separate list.
4. Case IDs stay unchanged. Only labels and documentation change, so no test, recorded CSV or verdict count moves.
5. **Readable case names.** Every validation case gets a plain-English title (for example `T1` → "Whole cabin noise, full chain, against measurement"; `T1_MEAS_DAMPING` → "Same, with measured cabin damping"; `T2_EQ19` → "High-frequency broadband, Eq. (19) path, against printed NASA result"). The title is shown in the GUI validation map, the coverage tab and the chain chart in place of the bare ID, with the ID in brackets or a tooltip.
6. **Names in the documents.** Each case's §2.13 entry gets the same title as its heading, so the documents and the GUI use one name per case.
7. **Test and file names.** Test testsets and report file names that use an unclear abbreviation are listed with a proposed plain name in the note for this ticket. They are renamed only in a separate step, after the list is agreed, and only with a mapping table from old name to new name so that nothing is lost.

**Proposed approach.**
- Build the glossary from the existing §2.13 `**Source:**` and `**Chain span:**` text first, then check each expansion against the section it cites.
- Expand each abbreviation where it first appears in `METHODOLOGY.md`, `VALIDATION_GUIDELINE.md` and `README.md`.
- Draft the plain titles for all cases with a verdict first (the 43 on the map), then the cases without one. Each title is checked against the case's own criterion text, not written from memory.
- Add a test that fails if a case ID in `validation_cases.jl` has no glossary entry for its prefix, or no title.

**Rules that apply.**
- Expansions and titles must cite the section that defines the check. An expansion or title written from memory is not accepted.
- Case IDs, criteria and recorded results do not change. Titles are labels only. Renaming a case ID or a test file is a separate step with a mapping table; it is not done under this ticket until the user agrees the list.
- Documentation changes are PAIN changes, so the PAIN document list in CLAUDE.md applies (README, flowchart, IMPLEMENTATION_PLAN, METHODOLOGY, VALIDATION_GUIDELINE, COMPLETED_PHASES row).
- GUI label changes need `scripts\smoke\smoke_gui_model.jl` and `scripts\smoke\smoke_qml_load.jl`, and a look at the window.

**Open questions.**
- Should the glossary also cover the Cabin_Noise project's abbreviations, or stay PAIN only? Proposed: PAIN only; Cabin_Noise is a separate project.
- Should the plain titles (wanted 5) replace the ID in the GUI, or sit beside it? Proposed: the title first, the ID in brackets; the ID stays the key everywhere else.
- Which renames of IDs and test names (wanted 7) does the user approve? Proposed: none until the list of proposed names is reviewed.

**Not done yet.** No glossary has been written and no label has changed.

**Answers (2026-11-09) → Phase 146.** PAIN only. Title first, ID in brackets. No case ID is renamed: the IDs are keys in `case_error_summary.csv`, the tests and 90 reports. Titles lose their phase tags ("(44d)", "(124)"), which mean nothing to a reader. Source and test file names are handled in Phase 150 with a mapping table.

---

## ISSUE-012: README treats opening the GUI as optional and carries verbose tab text

**Status:** closed 2026-11-11 by Phases 148 and 149 (`COMPLETED_PHASES.md` §8cl, §8cm). Recorded 2026-11-09. Documentation only. No verdict, criterion or recorded result changes. No code changed.

**Problem.** Opening the GUI is the main way to use PAIN, not an optional step, but `PAIN_Program/README.md` labels it "(optional)" and then repeats long paragraphs about every tab. Those paragraphs are too verbose for a README and duplicate `docs/INPUTS_AND_SETTINGS.md` and `docs/VALIDATION_GUIDELINE.md` §2.13.

**Evidence.**
- `PAIN_Program/README.md` line 12: the table of contents link reads "Open the methodology website (optional)".
- `PAIN_Program/README.md` line 299: "### Step 7 - Open the GUI (optional)", followed by the `run_gui.jl` command at line 302.
- `PAIN_Program/README.md` lines 324–330: four long paragraphs (Run tab, Validation tab, Validation map tab, Cabin modes tab) with field lists, file paths, colour and layout detail, and the phase history of each tab.

**Wanted.**
1. Remove "(optional)" from the GUI step and the table of contents entry, and present the GUI as the way to run PAIN, with the command first.
2. Replace the four long tab paragraphs (lines 324–330) with a short list of what the GUI does and a link to `docs/INPUTS_AND_SETTINGS.md` and `docs/VALIDATION_GUIDELINE.md` §2.13. No phase numbers in the README.
3. The methodology website step (Step 6) is not changed by this ticket unless the user asks for it.

**Proposed approach.**
- Edit `PAIN_Program/README.md` only: the GUI step, the table of contents line, and lines 324–330.
- Check that every link that remains in the README resolves to an existing file.

**Rules that apply.**
- Documentation only. The verdict counts and validation map in the README and VALIDATION_GUIDELINE do not change.
- The README is a PAIN document, so the PAIN document list in CLAUDE.md applies (README, flowchart, IMPLEMENTATION_PLAN, METHODOLOGY, VALIDATION_GUIDELINE, COMPLETED_PHASES row) for the change that is made under this ticket. Only the README text is named here, so the other documents stay as they are unless the change touches them.

**Open questions.**
- Should the Step 6 website step also stop being optional? Proposed: ask the user first; this ticket does not change it.

**Not done yet.** The README has not been edited.

**Answer (2026-11-09) → Phase 149.** The website step stays optional: the site is a read-through that runs nothing, and the GUI is how PAIN is run. The four tab paragraphs go; what replaces them is a five-line list and two links.

---

## ISSUE-011: Cabin mode and structural mode animations cannot be seen in the GUI; import a library animator

**Status:** closed 2026-11-11 by Phase 151 (`COMPLETED_PHASES.md` §8co; `phase151_cabin_animation.md`): the animation plays in the tab, and in a window of its own (GLMakie). Recorded 2026-11-09. Display only. No verdict, criterion or recorded result changes. No code changed.

**Problem.** The cabin mode animations (CYL2D App. C mode shapes on the Cabin modes tab, and the structural mode ψ animated with them) do not play in the GUI, so the user cannot see them. The animation is built as offscreen PNG frames and a GIF under `gui/cache/mode_anim/`, and the tab shows only "Press Refresh to build frames" until Refresh has run. The frames are stepped by a timer in QML, and the playback path has not yet been traced to the point where it fails.

**What is there now.**
- `PAIN.jl/src/gui_model.jl` lines 417–474: the cabin mode run builds `mode_animation_frames` (61-point grid, 4–48 frames), writes a GIF (`cm_gif_path`) and PNG frames (`frames_m<mode>`) to `gui/cache/mode_anim/`.
- `PAIN.jl/gui/main.qml` line 2003: the CYL2D App. C animation note ("Interpolation for drawing only; node values unchanged").
- `PAIN.jl/gui/main.qml` lines 2070 (signature that resets the frames), 2142 ("Press Refresh to build frames") and 2172 ("Structural mode ψ, animated with the frames above (36d / 63)").
- `PAIN.jl/src/PAIN.jl` lines 96–99 export `mode_animation_frames`, `render_mode_animation`, `render_mode_frame_pngs`, `structural_mode_frames`, `render_structural_frame_pngs`.

**Wanted.**
1. The Cabin modes tab plays the cabin mode animation and the structural mode ψ animation in the window, with play, pause and speed controls, without needing the user to open a file in `gui/cache/`.
2. Each frame is drawn from the same interpolated node values as today, so the animation shows the same mode shape. Frame interpolation stays display only.
3. The GIF and PNG export stays available for reports, but it is no longer the way the GUI shows the animation.

**Proposed approach.**
- Import a library animator for the QML side (for example a Qt Quick animation package or an `AnimatedImage` / timeline-driven component) instead of the timer-stepped PNG frames. The library choice is open: pick one, say which, and note its version and licence in the note.
- Feed the animator the frame data the Julia side already builds (`mode_animation_frames`, `structural_mode_frames`), so the Julia numerics are not changed.
- Add a test that fails if the Cabin modes tab has no playable animation for a built mode, and a test that the frame count and node values match `mode_animation_frames`.

**Rules that apply.**
- Display only: no criterion, no verdict, no tuning. The tab label stays "no criterion, no verdict".
- The GUI change needs `scripts\smoke\smoke_gui_model.jl` and `scripts\smoke\smoke_qml_load.jl`, and a look at the window (the animation must be seen moving, not only loaded).
- If the README or `docs/INPUTS_AND_SETTINGS.md` text about the Cabin modes tab changes, the PAIN document list in CLAUDE.md applies.

**Open questions.**
- Which library animator to import (QML-only, or a Julia-side package that writes frames the GUI reads)? Proposed: QML-only, so the Julia side is unchanged.
- Keep the PNG/GIF cache as an export, or remove it? Proposed: keep it as an export only.

**Not done yet.** No library has been imported and no code has changed.

**Trace and solution (2026-11-09) → Phase 151.** Read from the code; the window was not run.
- **How it plays today.** A QML `Timer` (`main.qml`, Cabin modes page) calls `Julia.cabin_modes_step_frame_from_qml(1)` every 40–120 ms. Each call changes `pain.cm_frame_path`, and an `Image` with `asynchronous: true` and `cache: false` loads that PNG from disk. The timer runs only when `pain.cm_playing` is true and a frame path exists, and a frame path exists only after Refresh. Three places can fail: nothing is built until Refresh; the play flag; and an asynchronous disk load per frame, which can show a blank between frames.
- **Answer to "which library".** None needs importing. Qt Quick's own `AnimatedImage` plays the GIF the Julia side already writes (`cm_gif_path`), with `playing`, `paused`, `speed` and `currentFrame`. The Julia numerics and the export are untouched.
- **To check first.** That the Qt build QML.jl ships has the GIF image plugin. If it does not, the fallback is the PNG frames preloaded once into a `Repeater` and shown by index, with no disk load per tick.
- **Also.** Build the frames when the tab is opened, so the first view is not an empty panel.

---

## ISSUE-010: Coverage tab and chart are sorted by chain stage, so cases from one figure are scattered; group them by figure and relation

**Status:** closed 2026-11-11 by Phase 146 (`COMPLETED_PHASES.md` §8cj; `phase146_plain_titles.md`). Recorded 2026-11-09. Presentation only. No verdict, criterion or recorded result changes. No code changed.

**Problem.** To check one figure, the reader has to open many separate cases. The Coverage tab (`PAIN.jl/gui/main.qml`, Coverage page from about line 2193) and the chain coverage chart (`PAIN.jl/src/validation_coverage.jl`) order rows by first stage, last stage, comparison type and then case ID (line 21). Cases from the same source figure end up in different places. R172428 is an example: its EXP, CODE, DECK, DBA, DB and ETA cases are spread across the chart by chain span.

**What is there now.**
- `CaseInfo` (`PAIN.jl/src/validation_map.jl` lines 4–17) holds `source` (free text), `reference` (`:measurement`, `:nasa`, `:verification`), and the chain span. It has no figure field.
- `ValidationCase` has a `FigureRef(document, figure, pdf_page)` (`PAIN.jl/src/validation_cases.jl` line 56), for example `FigureRef("NASA CR-172428", "Table 5 / Table 10", 89)`. Many cases have one, but the coverage code does not use it.
- The coverage colour is set by `Compared with` (`docs/VALIDATION_GUIDELINE.md` §2.13). Purple = NASA's printed prediction, teal = measurement, grey = verification.

**Wanted.**
1. **Group by source figure.** Each row carries its document and figure (for example "CR-172428 Table 5 / Table 10"), and rows are grouped under a header per figure, so one figure's cases sit together.
2. **Group by relation within a figure.** Inside each figure group, order rows by comparison (measurement, NASA's prediction, verification), then by chain span. The colour already shows the relation; the grouping makes the relation readable as well.
3. **Make it readable at a glance.** A toggle in the GUI between "by chain stage" (current) and "by figure". The chart PNG gets a figure-group label at the left of each group.
4. **Tooltip.** The row tooltip shows the figure reference and PDF page, so the reader can find the source without opening the case.

**Proposed approach.**
- Add a `figure` field to `CaseInfo`, read from §2.13 (one new `**Figure:**` line per case, or a parse of the existing `**Source:**` text). Decide which, and say which in the note. The `**Source:**` text is free-form and cannot be relied on for grouping, so a structured line is preferred.
- Extend `coverage_rows` (sort key: figure, reference, span, ID) and `coverage_json` (add `figure`, `pdf_page`) in `validation_coverage.jl`.
- Add the grouping toggle and headers in `main.qml`.
- Add a test that fails if a case with a verdict has no figure field, and a test that the sort is by figure then relation.

**Rules that apply.**
- This changes the presentation of verdicts, not the verdicts. The recorded verdicts and counts are the same before and after.
- Adding the `**Figure:**` line is a §2.13 documentation change. Run `python scripts/md_to_latex.py` afterwards if Cabin_Noise docs change; this is a PAIN change, so the PAIN document list in CLAUDE.md applies (README, flowchart, IMPLEMENTATION_PLAN, METHODOLOGY, VALIDATION_GUIDELINE, COMPLETED_PHASES row).
- The GUI change needs `scripts\smoke\smoke_gui_model.jl` and `scripts\smoke\smoke_qml_load.jl`, and a look at the window.

**Open questions.**
- For cases with more than one figure (for example a case that uses both CR-3813 and CR-172428), should they appear under each figure or under the first one only? Proposed: under each, with the row marked as shared.
- Should verification cases (no figure in the source) form their own "no figure" group? Proposed: yes.

**Not done yet.** No field has been added and no code has changed.

**Answers (2026-11-09) → Phase 146.** A case that uses two figures is listed under its first figure only, with the second in the tooltip; listing it twice would count it twice. Verification cases form one "no source figure" group. The figure is a structured field in the case record (ISSUE-016 moves the records out of Markdown), not a parse of the free `**Source:**` text. Grouping by figure also answers ISSUE-018 (variants of one comparison shown as one group).

---

## ISSUE-009: R172428_EXP plot labels and comparison target (NASA points vs measured)

**Status:** closed 2026-11-11 by Phase 145 (`COMPLETED_PHASES.md` §8ci; `phase145_summary_writer.md`, `phase145_independence_records.md`). Recorded 2026-11-09. Labelling and documentation only. The recorded verdict (not met, 5/9 within ±4 dB, max |err| 18.0 dB) is not changed. No code, criterion or recorded result has been changed.

**Figure.** CR-172428 Table 5 with Table 10 (App. B), page 89 in the report. The plot has nine points: 3000, 4000 and 5000 rpm at H1–H3. It shows three series: NASA's printed prediction, the measured space average, and this code.

### What the reader sees
- The error axis reads `computed − reference`. It has no unit and does not say which series is the reference.
- The NASA points look like the comparison target, but the verdict is against the measured points.
- The "this code" points on the EXP plot use a different form from the "this code" points on the R172428_CODE plot.

### Evidence
- `PAIN.jl/src/validation_case_iso44.jl`, `_run_r172428_vs` (lines 104–141). For EXP, `q0_coupled = false` and `η_n_band_omega = true` (line 106). CODE uses the CR-3813 tone-sum form.
- The EXP error is computed against `r.measured` (line 111). The NASA series is drawn but not used in the criterion.
- `PAIN.jl/src/validation_case_iso44.jl` lines 296–305: `PlotSpec` has no `error_ylabel`.
- `PAIN.jl/src/validation_plots.jl` lines 9–17: an empty `error_ylabel` with `:absolute` error mode gives the bare label `computed − reference`.
- `docs/VALIDATION_GUIDELINE.md` lines 3377–3390 (R172428_EXP): NASA's printed prediction misses the measurement at 3000 rpm H1 (−17.7 dB) and 5000 rpm H1 (−13.8 dB).
- `docs/validation_reports/case_error_summary.csv` lines 118–119: R172428_CODE 5/9, max 13.0 dB, med 2.8 dB (vs NASA); R172428_EXP 5/9, max 18.0 dB, med 2.1 dB (vs measured).
- The case numbers were not re-run in this ticket.

### Affected cases
- R172428_EXP (not met, 5/9), the case in question.
- R172428_EXP_DECK (`PAIN.jl/src/validation_case_iso83.jl`, lines 140–141 and 168–170), same plot pattern on NASA's 300 modes.
- R172428_CODE (vs NASA, 5/9): the axis label is shared, so it needs the same fix.

### Proposed changes (labels)
1. Set `error_ylabel` on R172428_EXP, R172428_EXP_DECK, R172428_CODE and R172428_CODE_DECK to name both series and the unit, for example `this code − measured space average (dB)` and `this code − NASA printed prediction (dB)`.
2. Relabel the measured and NASA series so the reader can tell which one is the criterion. The NASA series is shown for reference.
3. Check the rendered table headers for `ValidationTableRow` (fields `reference` and `computed`). Replace the bare field names with the series names and unit if they show. Not checked in this ticket.
4. Update the R172428_EXP entry in `docs/VALIDATION_GUIDELINE.md` (around line 3377) with the labels once they change.

### Open question: is R172428_EXP's comparison target the right one?
This is raised as a question. No change is made.
- Proposal A: reclassify R172428_EXP's `Compared with` from `measurement` (teal) to `NASA's printed prediction` (purple), since this code is based on NASA. **Not accepted as written.** The criterion is fixed against the measured space average, and the case tests the model against experiment. Changing it after seeing the result is post-hoc. R172428_CODE already is the code-on-code test (purple). Also "the same amount" is not established: this code vs NASA is max 13.0 dB; this code vs measurement is max 18.0 dB; NASA vs measurement is given at two points only.
- Proposal B: relabel R172428_EXP as "no verdict / limitation" because NASA misses the measurement. **Not accepted as written.** It removes a recorded not-met after seeing it fail, which is post-hoc. "NASA can't keep up" is not shown at all nine points.

### Recommended option
1. Keep R172428_EXP as recorded (not met, 5/9). Add a dated limitation note to its text: NASA's printed predictions also miss the measurement at 3000 rpm H1 and 5000 rpm H1.
2. Add a new experimental case, for example `R172428_NASA_EXP`: NASA's printed prediction against the measured space average at the same nine points, with the same ±4 dB criterion. Fix the criterion and its date before the first run, and register it in `data/validation/cases.yaml`. It has a verdict, because it compares with experimental data. It shows how far NASA misses, point by point.
3. Read the results side by side. R172428_CODE gives this code vs NASA (max 13.0 dB). R172428_NASA_EXP gives NASA vs measured. If NASA misses by about as much as this code, the miss comes from the shared NASA inputs and model, and the limitation goes in the text. If NASA is much closer, the code adds error of its own, and the case says so.
4. Changing the comparison of R172428_EXP is not part of this option. It needs a separate dated decision by the project owner.

**Not done yet.** Labels are not changed, the new case is not added, and the difference between the two "this code" forms is not checked numerically.

**Answers and solution (2026-11-09) → Phases 136 and 145.**
- **Labels** (steps 1 to 4): Phase 145. `main.qml` holds no literal "reference" or "computed" header, so the table headers come from the model side; they are traced in that phase.
- **R172428_NASA_EXP should not be a verdict case.** It would test NASA's program against the measurement, which is neither (E) nor (P) for this code. Part of its outcome is also on record already: NASA's printout meets R172428_DB_EXP's and R172428_DBA_EXP's gates at 1/3, and is 14–18 dB under the measured H1 at 3000 and 5000 rpm (Phase 126). Proposed instead: a generated column "NASA's own printout on the same gate" beside every measurement case for which NASA printed a prediction (ISSUE-026). It shows, case by case, whether a miss is the method's or this code's, and it needs no criterion.

---

## ISSUE-008: BLK_P68 tests only R1, but the predictions use R2 by default; the R2 curve has no criterion

**Status:** closed 2026-11-11 by Phase 144 (`COMPLETED_PHASES.md` §8ch): `BLK_P68` is a unit check of Eq. (43), off the chart; R2 stays information, its default reason is in METHODOLOGY §Blocking. Recorded 2026-11-09. Raised by the user ("why is there an r2 if we only compare against r1, and if it is valid for r1, why use r2 for predictions"). No code, criterion or recorded result has been changed.

**Summary.** `BLK_P68` compares Eq. (43) R1 with six narrative ΔL values from CR-172428 p. 68 (tolerance 0.06 dB). The same function also computes R2 (0.8 × F, floored at 1, CR-172428 §5.3.2) and plots it as a reference curve labelled `R2`. Nothing compares R2 with any data. Yet R2 is the default blocking variant for the pipeline and for most chain cases, so the predictions use the one variant the blocking case does not test. The 0.8 factor is therefore untested in the record.

**Answers to the two questions.**
- *Why the `r2` variable:* it is the R2 array from the same loop. It is drawn on the BLK_P68 plot as information only (`PlotSeries("R2", :reference_curve, …)`); it does not enter the verdict. This is the same pattern as ISSUE-006.
- *Why predictions use R2:* the code default is R2 (`PAIN.jl/src/PAIN.jl` line 241, `blocking::BlockingVariant=R2`; GUI default `R2` in `gui_inputs.jl` line 52). COMPLETED_PHASES.md line 2379 describes R2 as "already the pipeline default". The record does not show a dated decision to switch from R1 to R2, and the only check of Eq. (43) is on R1. So R1 is the verified variant and R2 is the variant used.

**Evidence.**
- `PAIN.jl/src/validation_case_extras.jl` lines 396–397: `r1` and `r2` both computed; lines 404–405: checkpoints compared with R1 only; line 415: R2 plotted.
- `PAIN.jl/src/blocking.jl` lines 10–15: R1 is "original programmed PAIN"; R2 = max(1, 0.8 · F_R1). Lines 41–49: `BLOCKING_P68_CHECKPOINTS` is six points read from the "narrative" text, at γ = 0, 50, 60, 70, 80, 90°.
- `PAIN.jl/src/pain_settings.jl` line 175: `block_r2_scale` (0.8) is a settings field; no case compares it with data.
- Chain cases that run with R2: `validation_cases.jl` lines 252, 294, 350; `validation_case_iso43.jl` lines 104, 327; `validation_case_iso119.jl` lines 33, 39; `validation_case_extras.jl` line 1381. R1 is used by `E12_BLOCK` (`validation_case_extras.jl` line 44), `validation_case_iso40.jl` line 184 and `validation_case_iso43.jl` line 220.
- Classification: `docs/VALIDATION_GUIDELINE.md` lines 2020–2027 (BLK_P68) say "verification", "code-on-code (not an experiment)", "the P68 values are a printed table of that equation, not a test". The same entry is a met verdict on the map (VALIDATION_GUIDELINE.md line 223; `case_error_summary.csv` line 9: 6/6, max |err| 0.056 dB).
- `docs/METHODOLOGY.md` line 823 states "R2 maximum about 4 dB" against the BLK_P68 V-UNIT row, which does not test R2.

**Affected cases.** BLK_P68 (R1 met 6/6; R2 information only, no criterion). Every chain case that runs on the default R2 blocking, which inherits an untested 0.8 factor.

**Proposed action.**
1. **Classification.** CLAUDE.md (PAIN rule 2026-10-29, Phase 82) says a check against a property of a printed table is verification, "never a verdict on the validation map". BLK_P68 is self-described as verification. Either move it to `INFORMATION_ONLY_CASES` (`PAIN.jl/src/validation_cases.jl`) or write down why it meets the (P) test. Changing its verdict needs your approval first.
2. **R2 criterion.** Register a criterion for R2 with data that can test the 0.8 factor, fixed and dated before any comparison. ISSUE-006 proposes `R996_FIG10_FLAT_R2` on the measured Fig. 10 increase; that is one candidate. Without a registered criterion, R2 stays information.
3. **Default.** Decide, in writing with a date, whether predictions should use R1 (the verified variant) or R2 (the revised variant, with the 0.8 factor untested). If the default changes, it is a physics change: a separate task, re-run of the chain cases with a post-hoc label, and the affected verdicts re-recorded.
4. **Docs.** Correct `METHODOLOGY.md` line 823 so the R2 figure is labelled as information, and update `VALIDATION_GUIDELINE.md` (BLK_P68 entry and line 223) to match step 1.

**Not done yet.** No criterion has been registered for R2, the default has not been reviewed, and BLK_P68's classification has not been changed.

**Answers and solution (2026-11-09) → Phase 144.**
- **Why predictions use R2.** R2 is CR-172428 §5.3.2's revision, and Phase 93 (§2.25) made "the program NASA ran for CR-172428" the default. Flight run 10's printed field shows the 4 dB of R2 (see ISSUE-006). The decision exists; what is missing is one dated sentence in METHODOLOGY §Blocking that says so.
- **BLK_P68's class.** Phase 85 ruled it P (CR-172428 p. 68 printed values) and Phase 134 labelled it "NASA's printed prediction". Its own case text still says "verification … not a test". One of the two has to change, and that is your call: proposed, keep the Phase 85 ruling and correct the case text, because p. 68's values are NASA's statement of what the program gives.
- **Default.** Keep R2. Changing to R1 would undo Phase 93 on the strength of a comparison already seen.

**Decision (author, 2026-11-09).** BLK_P68 leaves the coverage chart and stays as a unit check: its six values are the equation written out, not program output or a measurement. This reverses the proposal in the paragraph above (to keep the Phase 85 ruling).

---

## ISSUE-007: E12_BLOCK not met (29/31): Eq. (43) R1 is 3.8–4.3 dB above NASA's predicted H3 aft points, and the record gives two different max errors

**Status:** closed 2026-11-11 by Phase 143 (`COMPLETED_PHASES.md` §8cg): one mean curve, one largest error (4.3 dB); k = 11 is a reading error, k = 10 is NASA's drawn line, not explained by the documents (`phase143_e12_h3_aft.md`). The case carries no verdict since Phase 135f. Recorded 2026-11-09.

**Summary.** `E12_BLOCK` compares Eq. (43) R1 on ANOPP Table 8 (ℓ = 1 free field) plus ΔL, at the grid points of the test cylinder, against NASA's digitized predicted Fig. E-12 blocked SPL. 29 of 31 points are within δ_dig + 0.5 = 3.41 dB. The two failures are both on the H3 panel, aft of the plane of rotation: X3/D = −0.233 (k = 10, +4.3 dB) and X3/D = −0.349 (k = 11, +3.8 dB). In both, Eq. (43) predicts more blocked level than NASA's predicted curve shows. The cause is not established.

**Evidence.**
- `PAIN.jl/src/validation_case_extras.jl` lines 34–93 (`_run_e12_block`): ΔL from `delta_L_blocking_dB(…; variant=R1)` at ℓ = 1 grid points; reference is `e12_predicted_A.csv` only (line 36); `tol = 3.41` fixed in code (line 55); verdict `:met` only if all 31 points pass (line 89).
- `docs/validation_reports/e12_blocking.md` lines 7 and 16–17: report says the digitized curves are "the mean of two passes", but the code reads pass A only. δ_dig (predicted) = 2.91 dB at H2. The E-11 digitization gate (≤ 1.0 dB) is **not met**; the criterion was kept and the larger δ_dig reported.
- Same report, lines 55 and 45–48: "29 of 31 within 3.41 dB; largest |difference| 4.3 dB", with the two H3 aft failures at +4.3 and +3.8 dB. All other points are within +2.1 dB.
- `docs/validation_reports/e12_a3b_linefit.md` (diagnostic, 2026-10-28, no criterion): NASA's E-12 − E-11 step at H1/H2 matches ΔL within about ±1.5 dB. At H3 k10 the pixel-read step is 2.3 dB against ΔL = 5.98 dB, and the pixel residual is +4.9 dB (the largest in that table). H3 k11 is not in the A3b table.
- `docs/VALIDATION_GUIDELINE.md` line 4042 (class): E12_BLOCK (29/31) is classed **I, N**. Re-classed 2026-10-28: the fore/aft pattern is read as by-eye digitization of steep slopes (I), but H3 k10 "is not explained by the documents" (N).
- Measured curve (V-EXP, no pass mark): Eq. (43) on the digitized E-11 line is 5–7 dB above the measured E-12 circles at H1, and 1–7 dB overall (`e12_blocking.md` lines 57–79). NASA reports predicted minus measured of 0–5 dB near the plane of rotation.
- **Number conflict:** `docs/validation_reports/case_error_summary.csv` line 10 and `VALIDATION_GUIDELINE.md` lines 192 and 224 give **max |err| 4.0 dB, median 0.99 dB** (csv dated 2026-11-02). `e12_blocking.md` gives max **4.3 dB** (H3 k10). The two cannot both describe the same reference curve; the likely difference is the choice of digitization pass (A only vs mean), which the code and report disagree on.

**Affected cases.** E12_BLOCK (not met 29/31). Other cases that use Eq. (43) are not checked in this ticket.

**Proposed action.**
1. Find out which pass feeds the registry verdict. Either make the code read the mean of A and B as the report says, or correct the report. Any such change is a re-run and must be dated and labelled as a re-run, not a new pass.
2. Reconcile the max error (4.0 vs 4.3 dB) and median from one run; replace the figure in `case_error_summary.csv`, `VALIDATION_GUIDELINE.md` lines 192 and 224, and `e12_blocking.md` with the one value and date.
3. Resolve the H3 k10/k11 aft residual by digitization only: re-read the H3 aft segment from pixels (as A3b did for k10) and add k11 to A3b. Do not change the 3.41 dB tolerance or drop points to make the verdict pass.
4. Record the 3.41 dB tolerance's origin. It is δ_dig + 0.5, and δ_dig comes from the same predicted digitization being compared. State this in the report, and check the 2026-10-20 registration covers it.
5. If the re-read confirms NASA's H3 aft curve has a smaller step than Eq. (43), log it as an Eq. (43) limitation (N) with a dated note. Do not add a term or a correction factor without a new registered case.

**Not done yet.** No re-run has been made, the pass used by the code has not been checked against the report, and the 4.0 / 4.3 dB figures have not been reconciled.

**Answers and solution (2026-11-09) → Phase 143.**
- **Which pass.** There are two implementations. `scripts/run/e12_blocking.jl` compares with the mean of passes A and B (lines 51–60) and writes the report: largest difference 4.3 dB. The case runner `_run_e12_block` (`validation_case_extras.jl` line 57) compares with pass A only and draws pass B: largest difference 4.0 dB. Both give 29/31 at 3.41 dB.
- **Which is the registered one.** The criterion of 2026-10-20 (plan 14a) is the script's text: "Digitized curves are the mean of two passes". The runner departs from it.
- **Fix.** One function for the mean curve, used by the script and the runner; the runner is re-run and dated as a re-run. The count is expected to stay 29/31 but is not assumed. Then steps 3 to 5 as written (re-read the H3 aft segment from pixels in both passes, k = 10 and k = 11).

---

## ISSUE-006: R2 blocking variant needs its own validation case and criterion; the circular wall needs its own criterion

**Status:** closed 2026-11-11 by Phase 144 (`COMPLETED_PHASES.md` §8ch): no case for R2 (run 10's field stays a unit test; the Fig. 10 R2 rows are shown, not judged); the circular wall is information. CR-159668 Fig. 21 prints the fit that Eq. (43) is, and gives no support for R2's 4 dB (`phase144_blocking_r2.md`). Recorded 2026-11-09.

**Summary.** `_run_r996_fig10` in `validation_case_iso90.jl` computes two blocking variants for both walls: R1 (Eq. 43) and R2 (0.8 × Eq. 43, CR-172428 §5.3.2). The only verdict, `R996_FIG10_FLAT`, uses R1. R2 is plotted and reported as "information" with no criterion, so it is not validated against the Fig. 10 measurements. The variable named `r2` in that file is this R2 array, not a wall radius. Two gaps follow:
- **R2 needs its own validation case and its own criterion**, registered and dated before any comparison. It is not covered by the R1 verdict.
- **The circular wall (`R996_FIG10_CIRC`) needs its own criterion.** Its reason text says it is information because "the circular wall's radius is not stated". The source comment (lines 4–6) says γ on the generator line nearest the hub is the same for any radius, so the radius does not enter the calculation and is not the real constraint.

**Evidence.**
- `PAIN.jl/src/validation_case_iso90.jl` line 33: `g2 = delta_L_blocking_dB(γ; variant=R2)`; line 35 stores it; line 43 plots it as information; line 46 sets the verdict from `g1` (R1) only.
- Lines 4–6: γ, and so F, are the same for the circular wall whatever its radius.
- Line 47: the circular reason string reads "the circular wall's radius is not stated"; line 69 gives "No criterion (the circular wall's radius is not stated)".
- `docs/validation_reports/phase90_r996_fig10_blocking.md` line 21 repeats "radius not stated".
- Recorded flat-wall R2 values, information only: 4.03–4.06 dB against the measured 4.56–7.30 dB (`VALIDATION_GUIDELINE.md` line 3677).
- `docs/NO_VERDICT_CASES.md` line 127: `R996_FIG10_CIRC`, 1/5 rows within the band (not a pass), max |err| 5.3 dB, median 1.8 dB, no criterion.
- `PAIN.jl/test/runtests.jl` lines 3280–3290: the test runs both cases and checks the flat/circular split; it does not test R2 at either wall.

**Affected cases.** R996_FIG10_FLAT (R1 verdict met 5/5; R2 shown as information). R996_FIG10_CIRC (information, no criterion).

**Proposed action.**
1. **R2 validation case.** Add a separate case (for example `R996_FIG10_FLAT_R2`) that compares the R2 variant with the measured flat-wall increase at the same five x/D points. Register its criterion, with date and reason, before the comparison is run. Its result is reported on its own; it does not change the R1 verdict.
2. **Circular-wall criterion.** Register a criterion for `R996_FIG10_CIRC` (for example Eq. 43 R1 against the measured circular-wall increase), fixed and dated before the comparison. Its γ is the same as the flat wall's, so the case tests Eq. (43) on a second measured data set rather than a new geometry input. Do not use the radius as a reason to withhold it.
3. Correct the circular reason text (`validation_case_iso90.jl` line 47 and line 69) to match the registered criterion. This is a code change and needs its own task.
4. Keep the R2 line on the plot only if it is labelled with its own case ID and criterion once step 1 is done.
5. Update `docs/VALIDATION_GUIDELINE.md` (the R996_FIG10_CIRC entry, around line 3683), `docs/validation_reports/phase90_r996_fig10_blocking.md` and `docs/NO_VERDICT_CASES.md` when each case gets its criterion and status.

**Not done yet.** No criterion has been registered for R2 or for the circular wall, and the reason text has not been changed.

**Answers and solution (2026-11-09) → Phase 144.**
- **Neither Fig. 10 case can carry a first-run verdict now.** The R2 flat-wall values are on record (4.03–4.06 dB against 4.56–7.30 measured; §2.22: "2 dB under the flat wall"), and so are the circular-wall numbers (1/5, max 5.3 dB). A criterion written today is written after the result. Both cases can be registered with a disclosure, as Phase 124 did, but their outcome is known, so they are recorded as post-hoc, not as a pass or a fail of R2.
- **Where R2 is checked as NASA programmed it.** Phase 104 (§2.33): the six printed H2–H4 field cards of flight run 10 sit 3.9–4.0 dB above the free field, which is R2's maximum (20 log₁₀ 1.6 = 4.08 dB). That is a unit test today. Phase 144 proposes it as the (P) case for R2: PAIN's own printed blocked field against R2 on PAIN's printed free field, criterion fixed before the remaining cards are compared.
- **Circular reason text.** "radius not stated" is replaced by the real reason: Eq. (43) has no curvature term, and the measured circular-wall increase (0.7–4.9 dB) is below both R1 and the flat wall.

**Source found (2026-11-09).** NASA CR-159668 (Magliozzi and Brooks, 1979; D-24): pressure amplitude and phase measured at 21 microphones on a rigid semicylinder beside a model prop-fan, with and without the cylinder; its abstract gives "6 dB at 90 deg incidence decreasing to no effect at grazing incidence". This is very likely the measurement behind Eq. (43) that §2.22 says is "not in hand". If the report tabulates the values, it is a measured test of R1 and R2 on a curved wall that has not been compared with anything here, so a criterion can still be fixed first (Phase 144a). Not downloaded or read.

**Read 2026-11-09: CR-159668, "Pressure Doubling Effects" (report pp. 13–15).** Downloaded to `references/NASA_CR_159668.pdf`.
- The measured doubling is in Table VI and Fig. 21: semicylinder at 0.8 D against the same positions with no cylinder, averaged over ten harmonics and three speeds at each of 21 microphones, against incidence angle.
- The report's own words on it: "There is much scatter in this data", "no clear trend is shown by the data", and "The curve shown in Figure 21 was derived by an exponential curve fit passing through 0 dB at 0 degrees and through 6 dB at 60 degrees."
- The cluster of points beyond 60° is read by the authors as the full 6 dB.

**What follows.** This should not become a validation case: the scatter is as large as the 0 to 6 dB effect, so a verdict on it would be a verdict on the scatter. Its use is as a document: it shows where the shape of the blocking curve comes from (a fit pinned at two points), and it gives no support for a 4 dB maximum; R2 rests on CR-172428 §5.3.2 alone. Phase 144e is changed from a new case to this note.

---

## ISSUE-005: Too many Markdown files; documentation is duplicated and hard to keep in step

**Status:** closed 2026-11-11 by Phases 148 and 149 (`COMPLETED_PHASES.md` §8cl, §8cm). Recorded 2026-11-09. Inventory only; no file has been moved, merged or deleted.

**Summary.** The repository holds a very large number of Markdown files. Many cover the same content, and each code change must update several of them, so the documents drift apart. ISSUE-002 and ISSUE-004 are examples: the same Pereira and Report 996 numbers appear in several files, and they now disagree.

**Evidence.**
- `PAIN_Program`: 138 `.md` files (file search found 138; 38 not listed in the first 100 results). These include one validation report per phase in `docs/validation_reports/` (roughly 100 files named `phaseNN_*.md`), per-phase specs in `docs/specs/`, data-folder READMEs and notes, and `docs/extracted/` text extractions.
- `Cabin_Noise`: 7 `.md` files at the top level and under `references/`, plus LaTeX copies of each in `docs/latex/`. `CLAUDE.md` requires regenerating those copies after every `.md` change.
- Overlapping topics: `docs/METHODOLOGY.md` and `docs/METHODOLOGY_STRUCTURE.md`; `docs/COMPLETED_PHASES.md`, `docs/IMPLEMENTATION_PLAN.md` and `docs/flowchart.md` all track phase status.
- `CLAUDE.md` (PAIN rules) requires each PAIN code change to update at least `README.md`, `flowchart.md`, `IMPLEMENTATION_PLAN.md`, `METHODOLOGY.md` and `VALIDATION_GUIDELINE.md`, plus the `COMPLETED_PHASES.md` row. That is five or more files per change.
- Recorded results live in the per-phase reports. CLAUDE.md step 4 spot-checks numbers against those reports, so the reports are evidence, not just notes.

**Affected documents.** Whole documentation set in `PAIN_Program/docs/`, `PAIN_Program/docs/validation_reports/`, `PAIN_Program/data/*/`, and `Cabin_Noise/` (including `docs/latex/`).

**Proposed action.**
1. Inventory every `.md` file with its purpose, last update, and what it duplicates.
2. Classify each as keep (single source of truth), merge (fold into a topic doc), archive (keep the recorded result, move to an `archive/` folder with a dated note), or delete (no content unique to it).
3. Keep the per-phase validation reports as the evidence record: archive them, do not delete them, because the verdicts in `VALIDATION_GUIDELINE.md` and `case_error_summary.csv` point to them.
4. Make one file the source for each fact (for example, phase status in one place, linked from the others) so a change updates one file.
5. Shrink the CLAUDE.md update lists to match the files that remain. CLAUDE.md is the project's rule file, so any change to it needs your approval.
6. Regenerate `Cabin_Noise/docs/latex` only after the `.md` set is final.

**Not done yet.** No inventory has been made and no file has been changed. Deleting or moving any validation report needs your confirmation first.

**Solution (2026-11-09) → Phases 148 and 149.** Proposed answers: the per-phase reports stay where they are (`docs/validation_reports/`, 90 files) as the evidence record, so no link breaks; the phase diaries leave VALIDATION_GUIDELINE (ISSUE-016); phase status lives in COMPLETED_PHASES only. The shorter CLAUDE.md update list is drafted in Phase 148 and waits for your approval.

---

## ISSUE-004: Pereira Fig. 7, 8 and 9 verdicts are recorded with three different counts, and the scaled loads inherit the ISSUE-001 problem

**Status:** closed 2026-11-11 by Phases 135 and 141 (`COMPLETED_PHASES.md` §8ce): the counts agree, the titles name the scaled loads, and no unscaled Pereira line is drawn because the computed loads are within 0.7 % and 3.5 % of the measured ones. Recorded 2026-11-09.

**Summary.** The Pereira forward-flight cases (PER_FIG7, PER_FIG8, PER_FIG9) are reported with different results in different documents. The 23d criterion is frozen, but the recorded counts do not come from one run. The verdict path also uses loads scaled to Pereira's measured Table 3 thrust and torque, which is the same calibration pattern as ISSUE-001.

**Evidence.**
- `docs/validation_reports/pereira_forward_flight.md` (re-run 2026-10-28, criterion 23d): H1 within ±1.7 dB **9/9**; H2 within ±3 dB **6/9**; ψ₁(φ)−ψ₁(0°) **not computed** ("Fig.7 fit deferred; levels only", line 13).
- `docs/VALIDATION_GUIDELINE.md` §23d recorded result (line 942): H1 **0/9** FAIL; H2 6/9; `PER_FIG8` not met (H1 1/7, H2 6/7); `PER_FIG7` **not met** (Δψ₁ 2/3 within ±5°).
- `docs/VALIDATION_GUIDELINE.md` registry table (lines 120–122, 188–190) and the verdict table (lines 206–208): `PER_FIG7` **met 3/3** (max 3.4°); `PER_FIG8` not met 10/14; `PER_FIG9` not met 15/18.
- `docs/ISSUES.md` ISSUE-001 table: `PER_FIG7/8/9` met 3/3; not met 10/14, 15/18.
- The 23d counts in §23d do not add up to the registry counts: H1 0/9 plus H2 6/9 is 6/18, not 15/18; and PER_FIG7 cannot be both met 3/3 and not met on Δψ₁ 2/3, since the report says Δψ₁ was not computed.
- Verdict path is **ScaledLoads**: `s_T` 0.99–1.08 (`pereira_forward_flight.md` lines 22–27), scaled so the loads reproduce Table 3 measured T and Q (line 29). This is a scaling to measured loads of the kind described in ISSUE-001.
- Polar variant: the report lists `ncrit9`, `ncrit5` and `xtr005` (lines 22–27, 49–76). It does not say which variant feeds the registry verdict. ISSUE-001 names the N_crit = 8 set as the one used by the Report 996 cases. The SPL spread between variants is about 0.01 dB at H1, so polar choice matters mainly through the loads scale.

**Affected cases.** PER_FIG7 (met 3/3 in one place, not met in another), PER_FIG8 (10/14 and H1 1/7 / H2 6/7), PER_FIG9 (15/18 and H1 0/9 / H1 9/9 in the report).

**Proposed action.**
1. Re-run PER_FIG7, PER_FIG8 and PER_FIG9 from one code state, and record one count per case with its date.
2. Use one source for the recorded verdict; retire the other counts with a dated supersession note. Do not change the 23d tolerances (±1.7 dB, ±3 dB, ±5°).
3. Record which polar variant feeds the registry verdict, and label the ScaledLoads path as "scaled to measured Table 3 T/Q" in the case text.
4. Add an unscaled Pereira replay (loads straight from CCBlade, no `s_T`) with its criterion fixed and dated before it is run, as ISSUE-001 proposes for Report 996.
5. Compute Δψ₁ for Fig. 7 or remove the claim that PER_FIG7 has a phase verdict.

**Not done yet.** No re-run has been made, and the registry counts have not been reconciled with §23d.

**Answers and solution (2026-11-09) → Phases 135 and 141.**
- **Counts.** The current record agrees with itself: `case_error_summary.csv` (2026-11-02) PER_FIG9 15/18 is H1 9/9 plus H2 6/9, the figures of `pereira_forward_flight.md` (re-run 2026-10-28); PER_FIG8 10/14 is H1 6/7 plus H2 4/7 (§2.14, Phase 76); PER_FIG7 3/3. The §23d line (H1 0/9, PER_FIG7 2/3) is the state before Phase 74 (Fig. 9 re-read from the PDF vectors) and Phase 76 (thickness term). It needs a "superseded" note, not a re-run.
- **Polar variant.** The registry verdicts keep the rows with `polar_set == "ncrit9"` and `loads == "scaled"` (`validation_case_extras.jl` lines 986–988, 1040, 1078). So the verdict is N_crit 9 on scaled loads; N_crit 5 and x_tr 0.05 are shown only.
- **Fig. 7.** PER_FIG7's Δψ₁ is computed: the replay reads it from `data/pereira/pereira_results.csv`. Line 13 of the report ("not computed in this pass") is stale text of the script and is corrected with the script (Phase 135).
- **Unscaled replay.** With the Phase 69 loader fix the unscaled thrust is +0.7 % and torque +3.5 % from Table 3, so the unscaled result should be close; it is still added (Phase 141) so the chart has one source-chain case that carries the load error.

**Decision (author, 2026-11-09).** Unscaled Pereira cases are added with 23d's tolerances copied unchanged (Phase 141c).

---

## ISSUE-003: Report 996 Fig. 13a scaled 23c verdict is recorded as both FAIL and PASS

**Status:** open. Recorded 2026-11-09. Documentation conflict only; the current record is 14/14 pass, but the older FAIL row has not been marked as superseded.

**Summary.** `COMPLETED_PHASES.md` (phase 27) still reads "23c scaled ±2 dB **FAIL** (5/24)" for Fig. 13a. The 2026-10-28 re-run in `report996_acoustics.md` (line 72) gives 14/14 within ±2 dB. Both are about the scaled Fig. 13a load path, so the older FAIL is not visibly superseded.

**Evidence.**
- `docs/COMPLETED_PHASES.md` row 27: "23c scaled ±2 dB **FAIL** (5/24)" for the I-07 + I-08 re-run of 2026-10-21.
- `docs/validation_reports/report996_acoustics.md` line 72: "23c scaled pressure (Fig.13a sample): 14/14 within ±2 dB."
- The Fig. 13a path uses the `scaled_RM_L51C27` load scale (see ISSUE-001), so the 14/14 result inherits the scaling caveat.

**Affected cases.** R996_FIG13A.

**Proposed action.**
1. Mark the 5/24 FAIL as superseded by the 2026-10-28 re-run, with the date and the reason (sample size or load scale changed), in `COMPLETED_PHASES.md`.
2. Keep the scaling caveat from ISSUE-001 on the 14/14 result.
3. Do not change the ±2 dB criterion or the recorded sample.

**Not done yet.** The supersession note has not been written.

**Answer and solution (2026-11-09) → Phase 135.** There is no FAIL / PASS conflict for Fig. 13a. The 5/24 is Fig. 14's count: VALIDATION_GUIDELINE line 941 reads "scaled Fig.14 sample 5/24 within ±2 dB", and Fig. 14 has 24 points, Fig. 13a has 14. COMPLETED_PHASES row 27 puts "Fig.13a `scaled_RM_L51C27`" and "(5/24)" in one sentence, which reads as one result. Fig. 13a's own history is 6/14 (Phase 35 replay), 8/14 (2026-10-22 and Phase 69), 14/14 (Phase 72, observers on the documented side). The fix is to split row 27 into one clause per figure. Nothing is re-run.

---

## ISSUE-002: Report 996 page-12 phase value is stated three different ways

**Status:** open. Recorded 2026-11-09. Documentation conflict only; no verdict has been changed.

**Summary.** The page-12 (Fig. 12) phase check for Report 996 is recorded with three different computed phase values, so the reported miss from the 155° reference is not consistent across the record.

**Evidence.**
- `docs/COMPLETED_PHASES.md` row 27: page-12 phase **FAIL (103.8° vs 155°)**, from the I-07 + I-08 re-run of 2026-10-21.
- `docs/validation_reports/report996_acoustics.md` line 20 (re-run 2026-10-28, criterion VALIDATION_GUIDELINE §2.12 / 23c, frozen 2026-10-21): |Δφ − 155°| = 42.2° → FAIL (±15°). This implies a phase of about 112.8° (or 197.2°), not 103.8°.
- `docs/ISSUES.md` ISSUE-001 table, R996_PHASE: **not met (109°)**.
- `docs/VALIDATION_GUIDELINE.md` line 941 (23c / 27, polar re-run 2026-10-22): page-12 |Δφ−155°| = 51.2° (which matches 103.8°, not 42.2°), and phase **109.0° (was 103.8°)**. The same paragraph therefore gives two different Δφ values for two different phase values.

**Affected cases.** R996_PHASE (page-12 phase). Fig. 12 phase check (23c).

**Proposed action.**
1. Re-run the page-12 phase once from the current code and record the single phase value and Δφ it gives.
2. Replace the 103.8° and 109° figures in `COMPLETED_PHASES.md` and this file with that value, and add the run date.
3. Confirm the 155° reference and ±15° criterion match VALIDATION_GUIDELINE §2.12; do not change either.

**Not done yet.** No re-run has been made. The stated values have not been reconciled.

**Answer and solution (2026-11-09) → Phase 135.** The four values are four runs, not a conflict. No re-run is needed to choose between them.

| Run | Phase value | \|Δφ − 155°\| | Where |
|---|---|---|---|
| 2026-10-21 (I-07 + I-08) | 103.8° (superseded; Phase 135a) | 51.2° | COMPLETED_PHASES row 27; VALIDATION_GUIDELINE line 941 |
| 2026-10-22 (polar re-run, post-hoc) | 109.0° (superseded; Phase 135a) | 46.0° (155 − 109.0) | VALIDATION_GUIDELINE line 941 |
| 2026-10-28 (Phase 69 re-run, post-hoc) | 113.6° | 41.4° (155 − 113.6) | VALIDATION_GUIDELINE §2.14 |
| 2026-10-28 (current: x-sign of Phase 72, thickness of Phase 76) | 112.8° | 42.2° | `report996_acoustics.md` line 20; `case_error_summary.csv` (2026-11-02) prints it as 42.0 |

The current recorded value is 112.8° (miss 42.2°, not met). The 109° in ISSUE-001's table is the 2026-10-22 value. The fix is a "superseded by the 2026-10-28 run" note beside each older value, and one rounding rule in the summary writer (42.2 is printed as 42.0, Phase 145).

---

## ISSUE-001: Report 996 acoustic verdicts are scaled to measured loads and inherit the polar set

**Status:** closed 2026-11-11 by Phase 141 (`COMPLETED_PHASES.md` §8ce): the three cases are labelled "loads scaled to measured thrust and torque", and the unscaled result is drawn on each as a second line without a verdict. Recorded 2026-11-09.

**Summary.** The Report 996 acoustic cases (R996_FIG12, R996_FIG13A, R996_FIG14) run on CCBlade loads that are multiplied up to the measured thrust and torque before the acoustics are computed. Their met verdicts therefore do not test the section polars, and R996_FIG14 is compared against the same table its scale factors come from. The cases still list the Phase 69 polar set as their input, so the polar error is present in the chain but cancelled before the comparison.

**Evidence.**
- `PAIN.jl/src/validation_case_extras.jl` (around lines 687–694): the R996_FIG14, R996_FIG12 and R996_FIG13A replays read scaled loads; R996_FIG13A uses the `scaled_RM_L51C27` load scale.
- `data/report996/scale_factors.csv`: each row gives `s_T = T_meas / T_ccb` and `s_Q = Q_meas / Q_ccb`. The `T_meas` / `Q_meas` columns come from the RM L8H25a measurements.
- `docs/validation_reports/report996_acoustics.md` (section "Fig. 14 (scaled to table C_T/C_Q)"): the Fig. 14 scaling is to the table's C_T / C_Q.
- `docs/VALIDATION_GUIDELINE.md` line 919 and the R996_FIG14 entry: after the Phase 69 polar change, R996_FIG14 stayed 20/24 (unchanged), and R996_FIG12 moved only 22/40 → 21/40, while the loads themselves changed.
- Scale factors at M_t 0.75 / 0.90 moved from 1.364 / 1.521 to 1.275 / 1.316 after the polar re-run, so the scaling does absorb polar changes.

**Affected cases.**

| Case | Chain | Verdict | Issue |
|---|---|---|---|
| R996_FIG14 | → Free field | met 24/24 | scaled to the same Fig. 14 table it is compared with (calibrated path, post-hoc) |
| R996_FIG12 | → Free field | met 32/40 | scaled loads; verdict does not test the polars |
| R996_FIG13A | Blade loads → Free field | met 14/14 | scaled with RM L51C27 load scale; verdict does not test the polars |
| R996_PHASE | → Free field | not met (109°) | reads the polar-set phase; not scaled |
| PER_FIG7 / 8 / 9 | → Free field | met 3/3; not met 10/14, 15/18 | Pereira uses one section; polar-affected through defects 2–3 only |

**Related.** The N_crit = 8 polar set used by these cases was fitted to TN 1546 sections 16-506 and 16-509 (Phase 69b, `polars_phase69_ncrit8.json`). The same settings produce POLAR_FIDELITY's comparison. This is a calibration link: the downstream cases use a setting tuned to measured section data.

**Proposed action.**
1. Mark R996_FIG12, R996_FIG13A and R996_FIG14 in the case text and the chain table as "scaled to measured loads; does not test the polars", with a post-hoc label on the met verdicts.
2. Add an unscaled acoustic replay (CCBlade loads fed straight into the F1A chain, no `s_T` / `s_Q`) so the chain has a verdict that carries the polar error. Its criterion must be fixed and dated before it is run.
3. Note the N_crit calibration link in METHODOLOGY.md and VALIDATION_GUIDELINE.md.
4. Update `docs/validation_reports/case_error_summary.csv` only if a verdict changes.

**Not done yet.** No code, criterion or recorded result has been changed for this issue. Step 2 needs its criterion registered first.

**Answers and solution (2026-11-09) → Phase 141.** Read from the record and the code; nothing was run.
- **Correction to the summary.** R996_FIG14's loads are scaled to the Fig. 14 table's C_T and C_Q; the comparison is with Fig. 14's measured harmonic pressures. The scaled quantity (load) is not the compared quantity (pressure), so this is the "V-EXP, calibrated input" class of `IMPLEMENTATION_PLAN.md` §1 and of §2.18 (Phase 85), not a calibrated path compared with its own fit data. What the three met verdicts show is narrower than the chart suggests: F1A gives the measured pressures when it is given the measured loads. They say nothing about BEMT or the polars.
- **Step 1 (label).** Each of the three gets "loads scaled to measured thrust and torque" in its title and on its coverage row, and its chain span starts at Blade loads, not Blade and polars (R996_FIG13A already does). No verdict moves.
- **Step 2 (unscaled replay).** Three new cases (`R996_FIG12_UNSCALED`, `R996_FIG13A_UNSCALED`, `R996_FIG14_UNSCALED`) with 23c's rule copied unchanged. `report996_acoustics.md` holds no unscaled Fig. 12 / 13a / 14 residuals (only Fig. 6), so a first run is still possible; `data/report996/f1a_results.csv` must be checked for unscaled rows first, and if any were ever reported the cases are post-hoc and carry no verdict.
- **Step 3 (N_crit link).** One sentence in METHODOLOGY and in the case text of every case that reads `polars_phase69_ncrit8.json`.

**Decision (author, 2026-11-09).** Add the unscaled-load cases with the existing tolerances copied unchanged (Phase 141c). **Source found:** NACA RM L9G06a (D-26) has forward-flight thrust and power for this same blade; it is not in this repository and could give a loads case that no polar set here was fitted to.

**Caution on the new cases (author, 2026-11-09 later: "i created many validation cases that arent met and arent useful").** The five unscaled cases would very likely be five more not-met rows: the loads are up to 39 % off (R996_LOADS), and a load error passes almost straight into the level. They would say again what R996_LOADS already says. Proposed instead, for the author to confirm against the earlier decision: no new cases; each existing scaled case shows its unscaled result as a second line, without a verdict (ISSUE-029, the rule for new cases).
