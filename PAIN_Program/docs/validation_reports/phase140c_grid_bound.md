# Phase 140c: how much the cabin-mode grid moves the interior tones (bound, no verdict)

Form fixed 2026-11-10, before the run. Decided by Claude under the author's delegation of 2026-11-10.

- **Aircraft:** the GUI's default project (`examples/aircraft_generic_twin_turboprop.json`, the generic twin turboprop: 2.64 m cabin, the small-diameter case of ISSUE-025), run as the GUI runs it (tones only).
- **Grids:** CYL2D on NY = 8, 10 and 12 intervals, each with the earlier node rule at 0.40h, 0.45h and 0.55h (`cyl2d_grid_rule = threshold`), nine grids; plus the shipped grid (the printed rule of Phase 140, for reference, not in the spread). Where a grid has no App. C solution the next solvable one is used, and the table says so.
- **Reported:** the interior level of each tone harmonic for every grid, and the spread (largest minus smallest) over the nine grids per harmonic.
- **Use:** if the largest spread is above 1 dB, 140d states it as an uncertainty of the aircraft path. No grid is chosen from this run, and nothing here is a verdict.

## Result (run 2026-11-10)

Floor angle θ₀ = 62.6°; BPF 118.3 Hz. Shipped grid (printed rule): NY 12.

| Grid (NY asked → used, node rule) | H1 (dB) | H2 (dB) | H3 (dB) | H4 (dB) | H5 (dB) |
|---|---|---|---|---|---|
| shipped (printed rule, NY 12) | 102.69 | 91.32 | 86.85 | 64.06 | 58.08 |
| 8 → 8, 0.40h | 102.41 | 88.79 | 82.77 | 64.24 | 57.59 |
| 8 → 8, 0.45h | 102.41 | 88.79 | 82.77 | 64.24 | 57.59 |
| 8 → 9, 0.55h | 102.79 | 88.73 | 77.31 | 62.65 | 55.35 |
| 10 → 13, 0.40h | 102.51 | 91.85 | 82.44 | 63.85 | 60.78 |
| 10 → 12, 0.45h | 102.63 | 90.82 | 87.18 | 64.15 | 58.35 |
| 10 → 10, 0.55h | 102.96 | 89.03 | 80.58 | 61.69 | 61.60 |
| 12 → 13, 0.40h | 102.51 | 91.85 | 82.44 | 63.85 | 60.78 |
| 12 → 12, 0.45h | 102.63 | 90.82 | 87.18 | 64.15 | 58.35 |
| 12 → 12, 0.55h | 102.81 | 88.94 | 81.98 | 66.45 | 55.33 |
| **spread over the nine grids** | **0.55** | **3.12** | **9.87** | **4.76** | **6.27** |

Largest spread: 9.87 dB (H3). Above 1 dB, so 140d applies: the grid is an uncertainty of the aircraft path.
