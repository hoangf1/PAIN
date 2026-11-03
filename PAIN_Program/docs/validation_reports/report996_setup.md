# Report 996 setup (phase 25k)

> **Re-run 2026-10-22 with regenerated polar entries (post-hoc).** `polars_forced_merged.json` gained 1,420 points in 109 entries that were empty or stopped below α = 8° (phase 11 XFOIL settings; only the sweep handling changed; existing points unchanged; 50 entries on the thinnest sections still stop short and are listed in the file header, not filled). The 23c criteria (frozen 2026-10-21) are unchanged. This result was produced after the first recorded result was known, so it is post-hoc; the first recorded report is kept below.


Generated 2026-10-22 by `scripts/run/report996_setup.jl`.

## 25a static probe

See prior `report996_setup.md` / `probe_static.jl` results (finite at V=0 with `allow_static=true`; continuity |A(0)−A(1)|/A(1)≈0.23).

## x-sign / Fig. 13(a) asymmetry

Convention: `x_sign=-1` so report “behind” (negative x/D) maps to AA +X.
Case: β₇₅=15°, M_t=0.75, d/D=0.083, H1, CCBlade loads (unscaled).

| side | x/D | A_H1 Pa | A_H1 dyne/cm² |
|---|---:|---:|---:|
| behind | -0.125 | 113.13 | 1131.3 |
| ahead | +0.125 | 128.69 | 1286.9 |

behind > ahead: **false** (Fig. 13(a) measured ~1328 vs ~1009 dyne/cm²).
Absolute levels remain far above measured (near-field F1A at d/D=0.083); pass/fail waits on 23c [AUTHOR].

## Blade-angle shift (25b)

β(r) = β₇₅,target + (β_design(r) − 42.64°); design β₇₅ from `blade_form.csv`.

## Polar coverage (25c)

Forced-transition merged polar (`polars_forced_merged.json`): clamped_Re=713, clamped_M=65, viterna_evals=283, nearest_polar=648.

## Harmonic count for total-rms convergence (25k)

At behind x/D=−0.125: adding harmonic n changes total SPL by < 0.1 dB starting at **n = 6** (of 12 computed).

## Related

- Acoustics matrix: `report996_acoustics.md` / `f1a_results.csv`
- Loads: `report996_loads.md`
- Fig. 3 digitization (C-12): `data/report996/tr996_fig3_blade_form.csv`

---

## First recorded (2026-10-21), superseded by the re-run above

Generated 2026-10-21 by `scripts/run/report996_setup.jl`.

### 25a static probe

See prior `report996_setup.md` / `probe_static.jl` results (finite at V=0 with `allow_static=true`; continuity |A(0)−A(1)|/A(1)≈0.23).

### x-sign / Fig. 13(a) asymmetry

Convention: `x_sign=-1` so report “behind” (negative x/D) maps to AA +X.
Case: β₇₅=15°, M_t=0.75, d/D=0.083, H1, CCBlade loads (unscaled).

| side | x/D | A_H1 Pa | A_H1 dyne/cm² |
|---|---:|---:|---:|
| behind | -0.125 | 88.66 | 886.6 |
| ahead | +0.125 | 101.35 | 1013.5 |

behind > ahead: **false** (Fig. 13(a) measured ~1328 vs ~1009 dyne/cm²).
Absolute levels remain far above measured (near-field F1A at d/D=0.083); pass/fail waits on 23c [AUTHOR].

### Blade-angle shift (25b)

β(r) = β₇₅,target + (β_design(r) − 42.64°); design β₇₅ from `blade_form.csv`.

### Polar coverage (25c)

Forced-transition merged polar (`polars_forced_merged.json`): clamped_Re=729, clamped_M=65, viterna_evals=394, nearest_polar=664.

### Harmonic count for total-rms convergence (25k)

At behind x/D=−0.125: adding harmonic n changes total SPL by < 0.1 dB starting at **n = 6** (of 12 computed).

### Related

- Acoustics matrix: `report996_acoustics.md` / `f1a_results.csv`
- Loads: `report996_loads.md`
- Fig. 3 digitization (C-12): `data/report996/tr996_fig3_blade_form.csv`
