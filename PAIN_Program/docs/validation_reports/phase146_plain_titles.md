# Phase 146c: plain titles of the cases with a verdict (2026-11-11)

Decided by Claude under the author's authority of 2026-11-10 and 2026-11-11 ("you do not need my permission until all phases are done"). The plan asked the author to read this list before it was merged; the author gave that authority on 2026-11-11. No case, criterion or verdict changed.

Each title says what is compared, with what, and where it is printed. Each was read against the case's criterion text. There are no phase tags and no letter codes. In §0 the title comes first and the ID follows in brackets. The coverage chart keeps the IDs on its axis, where a 90-character title would not fit, and the table under the chart gives the titles. The list is `PLAIN_TITLES` in `validation_coverage.jl`. Cases without a verdict keep their registry title, with any trailing phase tag removed.

| ID | Plain title | Old title |
|---|---|---|
| R996_LOADS | Propeller thrust and power coefficients against measurement (NACA RM L8H25a) | Report 996 CCBlade loads |
| PER_FIG7 | Propeller tone phase shift in forward flight against Pereira's measurement (Fig. 7) | Pereira Fig. 7 waveform |
| PER_FIG8 | Propeller tone levels in forward flight against Pereira's measurement (Fig. 8) | Pereira Fig. 8 directivity |
| R996_FIG12 | Static propeller tone levels along the axis against measurement (Report 996, Fig. 12) | Report 996 Fig. 12(a)(b) |
| R996_FIG13A | Static first propeller tone along the axis against measurement (Report 996, Fig. 13a) | Report 996 Fig. 13(a) |
| R996_FIG14 | Static propeller tone levels against tip Mach number, against measurement (Report 996, Fig. 14a) | Report 996 Fig. 14(a) |
| R996_FIG10_FLAT | Level increase at a flat wall beside a propeller against measurement (Report 996, Fig. 10) | Eq. (43) blocking vs Report 996 Fig. 10 flat wall (90b) |
| R172428_EXP | Cabin tone levels of the test article against the measured space averages (CR-172428) | CR-172428 reproduction vs measured space averages (44e) |
| R172428_ETAT2 | Cabin tone levels with trim loss factor 2.0 against NASA's printed prediction (CR-172428, Table 12) | CR-172428 η_T = 2.0 run: default form vs NASA's Table 12 (94a) |
| NR_TP1964_XOVER | Noise reduction of a bare cylinder against measurement (TP-1964, Fig. 8) | TP-1964 bare-cylinder NR with PAIN's changeover to Eqs. (19)–(23) (45a) |
| FLIGHT_MODES | Structural modes of the flight aircraft against NASA's printed mode list (CR-172428, App. C) | MRP solver on NASA's Merlin IVC deck vs PAIN's printed mode list (101a) |
| MRP_APPD | Fuselage structural modes against NASA's printed Table D-1 (CR-3813) | App. D Eqs. (D.17)–(D.26) vs Table D-1 |
| R172428_ETA | Structural-mode loss factors against NASA's printout (CR-172428, App. B) | CR-172428 structural loss factors η_r′ vs App. B (44c/44d) |
| APPB_EPS_N | Cabin-mode factor ε_n against NASA's printout (CR-172428, App. B) | Cabin-mode ε_n vs NASA's App. B printout (87a) |
| CABIN_FREQ_PRINTED | Cabin acoustic mode frequencies against NASA's printed list (CR-172428, App. B) | Cabin-mode frequencies with CYL2D's 2-D part at 341 m/s vs PAIN's printed lists (106) |
| CYL2D_C1 | Cabin acoustic modes of the floored cylinder against NASA's Table C-1 (CR-3813) | CYL2D vs Table C-1 / Fig. C-3 |
| CYL2D_PRINTED | Cabin acoustic modes of two more aircraft against NASA's printed lists (CR-172428, App. C) | CYL2D grid rule vs PAIN's printed cabin modes of three CR-172428 aircraft (105) |
| APPB_ETA_N_T2_BAND | Cabin-mode loss factors with trim loss factor 2.0 against NASA's printout (CR-172428, p. 85) | Cabin-mode η_n at η_T = 2.0 by the band-centre rule vs CR-172428 p. 85 (96b) |
| APPB_ETA_RPP | Loss factors of structure–cabin mode pairs against NASA's printout (CR-172428, App. B) | Per-pair η_r″ vs NASA's App. B printout (87c) |
| E14_LOSS | Cabin band-average loss factor against NASA's calculated curves (CR-3813, Fig. E-14) | Fig. E-14 loss factor |

`CYL2D_PRINTED` says "two more aircraft": its verdict is on the two held-out aircraft, and the Merlin list is shown but not judged (Phase 145a).

**Test (146e).** A case with a verdict that has no source figure or no plain title fails `test_validation_coverage.jl`, and so does a title with a phase tag. The order by figure is drawn by the GUI's Coverage tab ("Order by source figure", 146b), which no Julia test reaches; the GUI smoke scripts load that tab, and the order itself is not tested.
