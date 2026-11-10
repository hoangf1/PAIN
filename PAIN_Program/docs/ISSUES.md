# Open issues

Known problems in the PAIN validation record that are not yet fixed. Each entry: status, what is wrong, evidence, affected cases, and the proposed action. Nothing here changes a recorded verdict until the action is done and dated.

---

## ISSUE-001: Report 996 acoustic verdicts are scaled to measured loads and inherit the polar set

**Status:** open. Recorded 2026-11-09.

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

---

## ISSUE-004: Pereira Fig. 7, 8 and 9 verdicts are recorded with three different counts, and the scaled loads inherit the ISSUE-001 problem

**Status:** open. Recorded 2026-11-09. The verdict counts disagree across the record; no verdict has been changed.

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

---

## ISSUE-005: Too many Markdown files; documentation is duplicated and hard to keep in step

**Status:** open. Recorded 2026-11-09. Inventory only; no file has been moved, merged or deleted.

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

---

## ISSUE-006: R2 blocking variant needs its own validation case and criterion; the circular wall needs its own criterion

**Status:** open. Recorded 2026-11-09. No verdict changed. No code or criterion has been changed.

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

---

## ISSUE-007: E12_BLOCK not met (29/31): Eq. (43) R1 is 3.8–4.3 dB above NASA's predicted H3 aft points, and the record gives two different max errors

**Status:** open. Recorded 2026-11-09. Verdict stays **not met** as recorded (2026-10-20 run, criterion 3.41 dB). No code, criterion or recorded result has been changed.

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

---

## ISSUE-008: BLK_P68 tests only R1, but the predictions use R2 by default; the R2 curve has no criterion

**Status:** open. Recorded 2026-11-09. Raised by the user ("why is there an r2 if we only compare against r1, and if it is valid for r1, why use r2 for predictions"). No code, criterion or recorded result has been changed.

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

---

## ISSUE-009: R172428_EXP plot labels and comparison target (NASA points vs measured)

**Status:** open. Recorded 2026-11-09. Labelling and documentation only. The recorded verdict (not met, 5/9 within ±4 dB, max |err| 18.0 dB) is not changed. No code, criterion or recorded result has been changed.

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


---

## ISSUE-010: Coverage tab and chart are sorted by chain stage, so cases from one figure are scattered; group them by figure and relation

**Status:** open. Recorded 2026-11-09. Presentation only. No verdict, criterion or recorded result changes. No code changed.

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

---

## ISSUE-011: Cabin mode and structural mode animations cannot be seen in the GUI; import a library animator

**Status:** open. Recorded 2026-11-09. Display only. No verdict, criterion or recorded result changes. No code changed.

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

---

## ISSUE-012: README treats opening the GUI as optional and carries verbose tab text

**Status:** open. Recorded 2026-11-09. Documentation only. No verdict, criterion or recorded result changes. No code changed.

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

---

## ISSUE-013: Validation case names and document abbreviations are not explained where they are used (T1, T2, T1_MEAS_DAMPING, T2_EQ19 and similar)

**Status:** open. Recorded 2026-11-09. Documentation and labelling only. No verdict, criterion or recorded result changes. No code changed.

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

---

## ISSUE-014: R172428_CODE is not met (5/9 within ±3 dB of NASA's printed prediction): find the cause in PAIN's code

**Status:** open. Recorded 2026-11-09. Investigation only. No criterion, tolerance, reference data, recorded result or verdict changes. No code changed until a cause is found and its fix is dated and reviewed.

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
