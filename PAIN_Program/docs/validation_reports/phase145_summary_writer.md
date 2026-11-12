# Phase 145a, 145b: what each number in the summary is (2026-11-11)

Done by Claude under the author's authority of 2026-11-10 and 2026-11-11. This is a display correction. No verdict, criterion, tolerance, reference file or table row changed. The `in_verdict` flag, the "+ n shown, not judged" count, the one-decimal rounding and the "no error size" text were added on 2026-11-10 (`phase135_151_decisions.md`). This closing adds three things:

1. **The rule beside a fractional count.** When a case's criterion asks for a share of its points, the summary now says so: "16/19 in tol (needs ≥ 80 %)". The rule is read from the case's own dated criterion text (`_count_rule`). A criterion that asks for every point adds nothing.
2. **No pseudo-units.** An absolute error without a unit in its label used to print "abs", and "dimensionless" was printed as if it were a unit. Both now print no unit word. The two η_n cases say "loss factor".
3. **Count-only cases say so.** A case with no error size now reads "17/32 within criterion · count only". The short chip on the chart keeps the count alone.

One count changes. `CABIN_FREQ_PRINTED` counted its seen rows: the Merlin list and run 10's pairs, which the case text calls "seen, post-hoc". These rows are now shown but not judged, as `CYL2D_PRINTED`'s already were. The verdict was always on the 47 held-out App. B rows.

## Before and after, cases with a verdict

Only rows whose text moves are listed. The before column is the snapshot of 2026-11-11 (Phase 142).

| Case | Verdict | Before | After |
|---|---|---|---|
| CABIN_FREQ_PRINTED | met | 127/128 in tol · max 0.44 % | **47/47** in tol (+ 81 shown, not judged) · max 0.014 % |
| MRP_APPD | met | 32/32 in tol (+ 33 shown, not judged) | 32/32 in tol (needs ≥ 75 %) (+ 33 shown, not judged) |
| APPB_ETA_RPP | met | 16/19 in tol · max 848.6 % | 16/19 in tol (needs ≥ 80 %) · max 848.6 % |
| FLIGHT_MODES | met | 200/221 in tol | 200/221 in tol (needs ≥ 90 %) |
| R996_FIG10_FLAT | met | 5/5 in tol (+ 5 shown, not judged) | 5/5 in tol (needs ≥ 4 of 5) (+ 5 shown, not judged) |
| R172428_ETAT2 | met | 9/9 in tol | 9/9 in tol (needs ≥ 7 of 9) |
| R996_FIG12 | met | 32/40 in tol | 32/40 in tol (needs ≥ 75 %) |
| R996_FIG13A, R996_FIG14 | met | 14/14, 24/24 in tol | the same, (needs ≥ 75 %) |
| APPB_ETA_N_T2_BAND | met | max 0.0018 abs | max 0.0018 loss factor |
| NR_TP1964_XOVER | not met | 9/18 in tol | 9/18 in tol (needs ≥ 75 %) |
| R172428_ETA | not met | 17/32 within criterion | 17/32 within criterion · count only |

The 848.6 % of `APPB_ETA_RPP` is now read beside its rule: three of 19 pairs may miss by any amount.

**Gate cases.** `T1_APPB` and `T1_MEAS_DAMPING_APPB` have a row per gate, not per tone. Since Phase 135f they carry no verdict, and their summary shows the error size without a count. So no count of gate rows reaches the chart, and no change was needed.

**Not changed.** Panel units that join several quantities ("m³ | m² | m", "N | W | -") belong to cases without a verdict. They name the unit of each panel, and they are left as they are.
