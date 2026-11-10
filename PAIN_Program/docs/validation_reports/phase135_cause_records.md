# Phase 135d: one cause record for each of the 27 not-met cases (proposal, awaiting the author's check)

Drafted 2026-11-10 from ISSUE-019's table, VALIDATION_GUIDELINE §2.14 and §2.15, `phase118_full_input_misses.md` and `case_error_summary.csv` (2026-11-02). Nothing is written into a case record yet: the author checks the cause given to each case first (Phase 135d). Where the three existing sources disagree, the row says so.

Causes, in plain words: *old program form*; *PAIN's method misses the measurement*; *approximation in this recreation*; *reference data*; *NASA's printout or the measurement, not explained by the documents*; *unexplained (no documented cause survived its test)*.

| Case | Points | Cause | One sentence | Tested in | What is left |
|---|---|---|---|---|---|
| R172428_CODE | 5/9 | old program form | Run on the CR-3813 form of the program, not the shipped form (ISSUE-017). | Phases 61, 84, 88; §2.14 | Re-run on the shipped form (Phase 136) |
| R172428_DB_CODE | 0/3 | old program form | Same form as R172428_CODE; no cause was written for it (Phase 124). | none | Phase 136 |
| R172428_DBA_CODE | 0/3 | old program form | Same form as R172428_CODE. | none | Phase 136 |
| APPB_ETA_N | 12/46 | old program form | Uses the superseded cabin-damping form (ISSUE-017). | Phases 100, 106 | Phase 136 |
| R172428_EXP | 5/9 | PAIN's method misses the measurement | NASA's own printout misses the measurement the same way (largest pair: mode 8 with the first cabin mode at H1). | Phases 54, 84b, 88; §2.14 | Share of the largest pair (Phase 136) |
| R172428_DB_EXP | 1/3 | PAIN's method misses the measurement | Same as R172428_EXP, in dB. | none specific | Phase 136 |
| R172428_DBA_EXP | 1/3 | PAIN's method misses the measurement | Same as R172428_EXP, in dB(A). | none specific | Phase 136 |
| E22_BR | 0/4 | PAIN's method misses the measurement | High-frequency trim noise reduction exceeds the measurement; NASA's own prediction does too. | Phases 47, 49, 59, 61, 83 | Option is not the default: leaves the chart (Phase 137) |
| E21_E22_NR | 5/35 | PAIN's method misses the measurement | Both classes N and M are on record; the one tested cause (NASA's 300 modes) was refuted. | Phases 61, 83, 88 | Phase 137 |
| NR_PROP_TP2444 | 1/7 | PAIN's method misses the measurement | NASA states the trim model holds to about 1 kHz. | Phases 47, 49, 59, 83 | Inputs: lining is printed in TP-2444 (Phase 137) |
| NR_PROP_TP2444_BR | 1/7 | PAIN's method misses the measurement | As above, with sound bridges added (not the shipped tool). | same | Retired as a case (Phase 137) |
| NR_PROP_TP2444_PF | 1/7 | approximation in this recreation | The separable form of Eq. (66) for the propeller field, 0.4–2 dB (Phase 50a). | Phase 50a | Retired as a case (Phase 137) |
| NR_TP1964 | 6/18 | PAIN's method misses the measurement | The misses are the Eq. (18) bands, where a negative noise reduction is a property of the equation (CR-159363 p. 138). | Phase 53 | Changeover check (Phase 138) |
| NR_TP1964_XOVER | 9/18 | PAIN's method misses the measurement | Same; the Eq. (19) bands agree within 2.5 dB. | Phase 53 | Phase 138 |
| NR_TP1964_REF2 | 6/18 | unexplained | Compares with NASA's own prediction, so the method is on both sides; "method" cannot explain it (ISSUE-022). | none | Read CR-159363 Phase I inputs (Phase 138) |
| NR_TP1964_XOVER_REF2 | 8/18 | unexplained | Same; 3 of 4 Eq. (19) bands are within 3 dB. | none | Phase 138 |
| E22_HF_CODE | 1/4 | unexplained | NASA's 1983 high-frequency routine is not printed; the sources disagree (class N in §2.14, M in the Phase 118 table). | Phase 83 | Phase 138 |
| E14_LOSS | 7/18 | unexplained | Three causes on record; the only one tested (NASA's per-band table) was refuted. | Phase 118 | Trim-loss investigation (Phase 139) |
| R172428_ETA | 17/32 | NASA's printout or the measurement, not explained by the documents | Mode shapes, masses, trim admittance and the Eq. (82) inputs were each tested and match. | Phase 82c | Phase 139 |
| CYL2D_PRINTED | 57/168 | NASA's printout or the measurement, not explained by the documents | NASA's grid rule is not what the code uses; CR-165869 pp. 60–61 prints it (ISSUE-025). | Phases 71, 85 | Adopt the grid rule (Phase 140) |
| FLIGHT_MODES | 197/221 | reference data | The reference file is a partial transcription; in-plane mass differs (ISSUE-024). | not recorded here (ISSUE-024) | Phase 142 |
| E12_BLOCK | 29/31 | reference data | The two H3 aft misses lie inside the digitization spread of 2.91 dB; the runner and the registered criterion differ (ISSUE-007). | Phase A3b | One implementation (Phase 143) |
| POLAR_FIDELITY | 40/61 | approximation in this recreation | XFOIL lift is 0.15–0.35 below NACA TN 1546 measured. | Phase 67, 69 | Measured polars (Phase 141) |
| R996_LOADS | 24/32 | approximation in this recreation | Thrust is below the measured value by the polar fidelity; the compact-chord approximation is not the cause (≤ 0.27 dB). | Phases 67, 69 | Phase 141 |
| R996_PHASE | 0/1 | approximation in this recreation | Phase 112.8° against the one measured 155°; same polars. | Phases 69, 72, 76 | Phase 141 |
| PER_FIG8 | 10/14 | NASA's printout or the measurement, not explained by the documents | XFOIL polars at Pereira's Reynolds number, no measured section data; thrust is within 1 %. | Phases 69, 72, 74, 76 | Phase 141 |
| PER_FIG9 | 15/18 | NASA's printout or the measurement, not explained by the documents | Same as PER_FIG8 (the 2026-10-28 record puts the H2 misses at φ = 20°). | same | Phase 141 |

**Disagreements the author should look at**
- PER_FIG8 and PER_FIG9 are placed under "not explained" following ISSUE-019, while §2.14 says the cause is an input (no measured polars). If "reference data" is the better name, say so.
- POLAR_FIDELITY, R996_LOADS and R996_PHASE: ISSUE-019 says approximation in this recreation; the only tested cause is the XFOIL polar, which Phase 141 tests with measured polars.
- Points for POLAR_FIDELITY (40/61) and CYL2D_PRINTED (57/168) count rows outside the verdict (ISSUE-020, Phase 145).
