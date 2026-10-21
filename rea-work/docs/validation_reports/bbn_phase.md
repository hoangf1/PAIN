# BBN / Wilby phase check (phase 24) — status 2026-10-21

## Done
- **24a** Data CSVs + `bbn_geometry.csv` (rotation **not printed** → both signs); `scripts/bbn_data.jl` loader.
- **C-14 / D-09** Hartzell Manual 114-8 downloaded (`rea-work/Hartzell_114-8.pdf`); Table III 9333C-3 typed and checked → `data/NASA_CR-158919/hartzell_9333C_table3.csv`. Tip beyond 40 in: **not found**.
- Example configs `examples/bbn_aerocommander_tipA.json`, `tipB.json` (assumed tip tapers; OCR/PDF stations for chord minima).

## Severe blocker — 24b / 24c inter-observer phase

Probe `scripts/_probe_bbn_kin.jl` (hub-centred ring, static, `num_src_times=128`):

| sep ° | H | Δφ F1A ° | m·B·Δψ ° | err ° |
|------:|--:|--------:|--------:|------:|
| 13.3 | 1 | −12.5 | 39.9 | −52 |
| 13.3 | 2 | −13.9 | 79.8 | −94 |
| 13.3 | 3 | −4.7 | 119.7 | −124 |

Per-observer FFT phases from `evaluate_propeller_source` do **not** reproduce the exact kinematic relation. Likely cause: AcousticAnalogies `noise`/`combine` builds an independent time window per observer, so absolute phase is not comparable across observers.

**Author action:** add a common-time-base phase path (shared reception clock or cross-spectrum of synchronized pressures) inside or beside `evaluate_propeller_source`, then re-enable the 24b `@test_broken` and run 24c.

## Blocked on author
- **23a / 23a′ / 23b** tolerances still **[AUTHOR]** — even after the time-base fix, pass/fail needs the freeze (23f).

## Not run
- 24c circumferential comparison, 24d levels, 24e longitudinal (X-EXTRAP).
