# Phase 135f: the chart rule applied to the 43 cases that carry a verdict

Written 2026-11-10. The rule (author, 2026-11-09): a case is on the coverage chart only if it runs the shipped code, every input that enters its compared quantity is printed or measured, and it is compared with a measurement or with NASA's program output. The sorting is the one the author approved on 2026-11-09 (ISSUE-029, "Yes, use it"). The verdict and counts below are read from `case_error_summary.csv` (generated 2026-11-02); all 43 case names exist there and their verdicts agree with ISSUE-029. The columns "shipped code" and "inputs complete" come from the case texts in VALIDATION_GUIDELINE §2.13 and the phase reports; they have not been re-derived from the runners. A row that the code contradicts goes back to the author before any flag changes. The flags in `src/validation_cases.jl` change in the phase that owns each case.

Totals: 18 stay on the chart (11 met, 7 not met), 2 move inside a parent case, 5 are checked first, 15 become diagnostics, 3 are retired.

| Case | Now (summary) | Runs the shipped code | Inputs complete | Compared with | Outcome |
|---|---|---|---|---|---|
| R996_LOADS | not met 24/32 | yes | yes (blade and polars printed) | measurement | keep |
| R996_FIG12 | met 32/40 | yes | yes | measurement | keep, needs independence record |
| R996_FIG13A | met 14/14 | yes | yes | measurement | keep, needs independence record |
| R996_FIG14 | met 24/24 | yes | yes | measurement | keep, needs independence record |
| PER_FIG7 | met 3/3 | yes | yes | measurement | keep |
| PER_FIG8 | not met 10/14 | yes | yes | measurement | keep |
| PER_FIG9 | not met 15/18 | yes | yes | measurement | check: probable duplicate of PER_FIG8 (settled here, see below) |
| POLAR_FIDELITY | not met 40/61 (verdict rows 13/26) | yes | yes | measurement | diagnostic: tests an input, not the tool |
| R996_PHASE | not met 0/1 | yes | no: the two measurement stations are not stated | measurement | diagnostic |
| R996_FIG10_FLAT | met 5/5 | no: runs R1 blocking, the default is R2 | yes | measurement | check in Phase 144 |
| E12_BLOCK | not met 29/31 | no: R1 blocking | yes | hand-read curve (spread 2.91 dB against 3.41 dB tolerance) | diagnostic |
| BLK_P68 | met 6/6 | yes | yes | the equation written out | unit check (decided) |
| R172428_EXP | not met 5/9 | yes | yes | measurement | keep |
| R172428_DB_EXP | not met 1/3 | yes | yes | measurement | row of R172428_EXP |
| R172428_DBA_EXP | not met 1/3 | yes | yes | measurement | row of R172428_EXP |
| R172428_ETAT2 | met 9/9 | yes | yes | NASA's program output | keep |
| T1_APPB | met 4/6 rows | yes | yes | measurement and NASA's prediction | check: same field as R172428_EXP (settled here, see below) |
| T1_MEAS_DAMPING_APPB | met 5/6 rows | no: measured damping in place of the tool's model | yes | measurement | diagnostic |
| R172428_CODE | not met 5/9 | no: old program form | yes | NASA's program output | diagnostic (decided) |
| R172428_DB_CODE | not met 0/3 | no: old program form | yes | NASA's program output | diagnostic (decided) |
| R172428_DBA_CODE | not met 0/3 | no: old program form | yes | NASA's program output | diagnostic (decided) |
| NR_TP1964_XOVER | not met 9/18 | yes | yes | measurement | keep |
| NR_TP1964 | not met 6/18 | no: without the changeover | yes | measurement | diagnostic |
| NR_TP1964_REF2 | not met 6/18 | no: without the changeover | not established (NASA's inputs) | NASA's program output | diagnostic |
| NR_TP1964_XOVER_REF2 | not met 8/18 | yes | not established (NASA's inputs) | NASA's program output | check in Phase 138 |
| E21_E22_NR | not met 5/35 | no | yes | NASA's output before its corrections | diagnostic |
| E22_HF_CODE | not met 1/4 | yes | no: NASA's routine is not printed | NASA's program output | diagnostic |
| E22_BR | not met 0/4 | no: sound bridges are not the default | no: assumed | measurement | retire |
| NR_PROP_TP2444_BR | not met 1/7 | no: an addition | no: assumed | measurement | retire |
| NR_PROP_TP2444_PF | not met 1/7 | no: an addition | no: assumed | measurement | retire |
| NR_PROP_TP2444 | not met 1/7 | yes | no: wrong trim (TP-2444 prints its own) | measurement | diagnostic until Phase 137a′ |
| MRP_APPD | met 32/32 | yes | yes | NASA's program output | keep, needs independence record |
| FLIGHT_MODES | not met 197/221 | yes | reference file is partial | measurement | keep, re-run in Phase 142 |
| CYL2D_C1 | met 59/59 | yes | yes | NASA's printed modes | keep |
| APPB_EPS_N | met 48/48 | yes | yes | NASA's printed modes | keep |
| CABIN_FREQ_PRINTED | met 127/128 | yes | yes | NASA's printed modes | keep |
| CYL2D_PRINTED | not met 57/168 | no: a grid rule the code does not use | yes | NASA's printed modes | diagnostic now; back after Phase 140 |
| APPB_ETA_N | not met 12/46 | no: old program form | yes | NASA's program output | diagnostic (decided) |
| APPB_ETA_N_T2 | met 3/3 | not established (may be the form before the band-centre rule) | yes | NASA's program output | check (settled here, see below) |
| APPB_ETA_N_T2_BAND | met 3/3 | yes | yes | NASA's program output | keep |
| APPB_ETA_RPP | met 16/19 | yes | yes | NASA's program output | keep, needs independence record |
| R172428_ETA | not met 17/32 | yes | yes | NASA's program output | keep |
| E14_LOSS | not met 7/18 | yes | yes | NASA's calculated curve | keep for now (Phase 139) |

## The three rows this step settles (read 2026-11-10; no run, no code changed)

- **PER_FIG9: yes, a duplicate.** In `pereira_results.csv` the six Fig. 9 reference values (H1 and H2 at 0°, 20°, 40°) differ from the Fig. 8 values at the same angles by 0.01 to 0.15 dB (largest +0.15 dB at 20°, H1). The tolerances are 1.7 and 3 dB. The same measurement, so the case is a row of PER_FIG8, not a bar. The flag changes in Phase 141 ([CONFIRM]).
- **T1_APPB: yes, the same measurement and field.** The runner's own label reads "field and measurement seen together in R172428_EXP"; it runs the shipped pipeline on the printed field at 4000 rpm with the T1 gate (±4 dB of the measured mean, or inside the envelope and ±4 dB of NASA's prediction). A variant of R172428_EXP's 4000 rpm points, so by the rule on new cases it is a row of that case. `T1_MEAS_DAMPING_APPB` is already a diagnostic.
- **APPB_ETA_N_T2: not the shipped form.** The verdict rows use η_n with the trim evaluated at the mode frequency (the form of Phase 93); the band-centre value that the shipped tone sum uses is printed in the same text as "information". The shipped rule is the verdict of `APPB_ETA_N_T2_BAND`. So `APPB_ETA_N_T2` becomes a diagnostic.

Effect on the chart: the sorting of ISSUE-029 had 18 bars. With PER_FIG9 and T1_APPB gone to rows and APPB_ETA_N_T2 a diagnostic, the counts are unchanged (those three were among the "check" rows, not the 18). The 18 bars stay 11 met and 7 not met; the diagnostics become 16, the cases inside a parent become 4 (the two dB rows, PER_FIG9, T1_APPB) and the "check" rows fall from 5 to 2 (R996_FIG10_FLAT in Phase 144, NR_TP1964_XOVER_REF2 in Phase 138): 18 + 4 + 2 + 16 + 3 = 43.

**Open:** the flag changes themselves (`src/validation_cases.jl`), which wait for [CONFIRM] in the phase that owns each case.
