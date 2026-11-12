# Phase 150b as done: the case files named by subject (2026-11-12)

Decided and done by Claude under the author's authority of 2026-11-11 (ISSUE-040). The plan's per-stage layout would split 13 of the files
function by function; it changes no behaviour, so the files were renamed instead, by what they hold, in place in `src/`
(five of them build paths from their own location). No line inside a function changed; the include order is the same.

| Old name | New name | Holds |
|---|---|---|
| `validation_case_iso40.jl` | `cases_isolation.jl` | isolation checks: free field, grid, blocking, cabin |
| `validation_case_iso41.jl` | `cases_isolation_hand.jl` | hand calculations behind the failing cases |
| `validation_case_iso43.jl` | `cases_tp1964.jl` | TP-1964 bare cylinder, and the T1 root-cause helpers |
| `validation_case_iso44.jl` | `cases_cr172428_test_article.jl` | CR-172428 test article (App. A / App. B) |
| `validation_case_iso45.jl` | `cases_tp1964_crossover.jl` | TP-1964 with PAIN's changeover |
| `validation_case_iso47.jl` | `cases_tp2444.jl` | TP-2444 measured exterior |
| `validation_case_iso48.jl` | `cases_broadband.jl` | propeller broadband (BPM, RP-1218) |
| `validation_case_iso59.jl` | `cases_sound_bridges.jl` | Sharp sound bridges |
| `validation_case_iso61.jl` | `cases_cr3813_high_frequency.jl` | CR-3813 high-frequency noise reduction |
| `validation_case_iso62.jl` | `cases_input_checks.jl` | inputs and plumbing checks |
| `validation_case_iso66.jl` | `cases_bemt_f1a.jl` | BEMT and F1A closed-form checks |
| `validation_case_iso67.jl` | `cases_polars.jl` | section polars and the chordwise check |
| `validation_case_iso80.jl` | `cases_mrp.jl` | App. D structural solver checks |
| `validation_case_iso87.jl` | `cases_appb_per_mode.jl` | NASA's App. B per-mode values |
| `validation_case_iso90.jl` | `cases_wall_reflection.jl` | Eq. (43) blocking against Report 996 Fig. 10 |
| `validation_case_iso94.jl` | `cases_cr172428_eta_t2.jl` | CR-172428 Table 12 (η_T = 2.0) |
| `validation_case_iso96.jl` | `cases_band_centre.jl` | the band-centre η_n rule |
| `validation_case_iso100.jl` | `cases_pf105_deck.jl` | NASA's per-band PF-105 table |
| `validation_case_iso101.jl` | `cases_flight_modes.jl` | Merlin IVC structural modes |
| `validation_case_iso102.jl` | `cases_flight_run10.jl` | flight run 10, H2–H4 |
| `validation_case_iso105.jl` | `cases_cyl2d_printed.jl` | CYL2D against PAIN's printed cabin modes |
| `validation_case_iso106.jl` | `cases_cabin_frequency.jl` | cabin-mode frequency (2-D part at 341 m/s) |
| `validation_case_iso119.jl` | `cases_t1_appb.jl` | T1 on App. B's printed field |
| `validation_case_iso121.jl` | `cases_commander695a.jl` | Commander 695A cabin against CR-178004 |
| `validation_case_merlin_loss.jl` | `cases_flight_loss_factors.jl` | Merlin IVC loss factors (ISSUE-041) |
| `validation_case_extras.jl` | `cases_core.jl` | the original cases and the registry's finish |
