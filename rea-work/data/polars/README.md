# XFOIL polars (phase 11)

Generated 2026-10-20 with `xfoil_polars.py` (Python 3, standard library; stock Windows XFOIL 6.99). Settings and results: `docs/IMPLEMENTATION_PLAN.md` (Phase 11, completed section) and the `VALIDATION_GUIDELINE.md` §2.10 register.

- `python data/polars/xfoil_polars.py report996` writes `data/report996/polars_forced_merged.json` from `data/report996/polars_forced_sibling.json` and `data/report996/xfoil_sections/*.dat`.
- `python data/polars/xfoil_polars.py pereira ncrit9|ncrit5|xtr005` writes `data/pereira/naca4412_xfoil_<setting>.json`.
- `julia --project=. scripts/run/viterna_extension.jl` (from `PAIN.jl`) writes `viterna_extension.json`.
- `run_*.log`: generator output. Each JSON has a `header` with XFOIL version, panels, transition setting, grids, non-converged points, date and script.

Cautions: XFOIL hangs past stall on thin sections (60 s limit; partial output kept), and the merged Report 996 grid mixes two XFOIL builds.

## Phase 69 (2026-10-28): free transition

`xfoil_phase69.py` (same session and acceptance rule as `xfoil_polars.py`; free transition):

- `tn1546 phase69_tn1546_points.csv phase69_tn1546_ncrit.json` runs the 68 TN 1546 matched points (16-312, 16-506, 16-509) at the TN 1546 Re(M) for N_crit 1–12. `phase69_fit_ncrit.py` applies the rule fixed 2026-10-28 and writes `phase69_ncrit_fit.md`: N_crit 8; held-out 16-312 not met.
- `grid 8 ../report996/polars_phase69_ncrit8.json` writes the Report 996 set used by the cases from 2026-10-28: 10 sections × Re 1.5·10⁵–2·10⁶ (8) × M 0.1–0.9 (9) × α −6° to 20°.
- `fill 8 ../report996/polars_phase69_ncrit8.json` re-sweeps every polar whose sweep hung, with the 2026-10-22 restart rule; existing points are kept and still-missing angles stay listed. Many first-pass hangs came from CPU load (the 60 s limit is wall-clock).
- Logs: `run_phase69_tn1546.log`, `run_phase69_grid.log`, `run_phase69_fill.log`.

The forced-transition set `../report996/polars_forced_merged.json` is kept unchanged as the pre-Phase-69 record.
