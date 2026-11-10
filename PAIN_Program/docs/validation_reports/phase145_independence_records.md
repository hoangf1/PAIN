# Phase 145c: independence records of the verdicts reached after a change (2026-11-10)

Author, 2026-11-09: "this needs to be proven that its not circular somehow on the coverage map or somewhere accessible by the reader". For each case below, the record lists every change between its first run and the current result, what each change rests on, and whether the compared data was used to choose it. Read from the case records in VALIDATION_GUIDELINE §2.13 and the phase reports named. Decided by Claude under the author's delegation of 2026-11-10 (the author was to read the seven records first; they were away).

Rule: all answers "no" → the verdict stands. Any "yes", or a change with no stated basis → no verdict.

| Case | First run | Now | Change | Rests on | Compared data used to choose it? |
|---|---|---|---|---|---|
| R996_FIG14 | met 20/24 (2026-10-21) | met 24/24 | amplitude convention (37b) | the sources' peak / rms definitions (I-17) | no |
| | | | polar set and loader fixes (Phase 69) | code defects: one section per blade, μ = 1, no Re/Mach interpolation; N_crit fitted to NACA TN 1546 section data, not to Report 996 | no |
| | | | observer behind or ahead of the plane (Phase 72) | Report 996 p. 6: positive x/D is ahead | no (the change made Fig. 14 worse, 20 → 14/24) |
| | | | thickness noise on (Phase 76) | section area from the airfoil coordinates | no |
| R996_FIG12 | not met 22/40 | met 32/40 | the same four changes | the same | no |
| R996_FIG13A | not met 8/14 | met 14/14 | the same four changes | the same | no |
| PER_FIG7 | not met 2/3 | met 3/3 | Phases 69, 72, 76 as above | the same; thrust within 1 % of the measured value before Phase 76 | no |
| APPB_ETA_RPP | not met 8/19 (2026-10-29) | met 16/19 | NASA's per-band PF-105 deck table (Phase 100) | selected by NASA's printed trim admittances (R172428_TRIM_DECK, 84/84), not by η_r″ | no |
| | | | 2-D cabin-mode part at 341 m/s (Phase 106) | criterion fixed 2026-10-30 on App. B p. 185's printed frequencies (held out, 47/47); η_r″ moved as a knock-on | no |
| MRP_APPD | met 27/32 by frequency only (2026-10-22) | met 32/32 | pairing by mode identity, then by shape (Phases 78a, 78d-3) | each made the test stricter (the case fell to 2/32) | no |
| | | | stiffener inertias, orthotropic floor, shape convention (Phase 78d) | code defects against App. E's sections and closed forms | no |
| | | | NASA's own MRP input deck (Phase 80) | User Manual pp. 42–43, NASA's printed input | no |
| R996_LOADS | not met 6/32 | not met 24/32 | polar set and loader fixes (Phase 69) | code defects; N_crit fitted to TN 1546, not to Report 996 | no |

**Outcome.** Every answer is "no", so the seven verdicts stand. They remain post-hoc in the sense of CLAUDE.md (the earlier results were known when each change was made), and the chart and §0 say so through this record. One caution is kept: the observer convention of Phase 72 was found while the results were being looked at, although its basis is the report's own page.
