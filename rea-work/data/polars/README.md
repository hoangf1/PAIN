# XFOIL polars (phase 11)

Generated 2026-10-20 with `xfoil_polars.py` (Python 3, standard library; stock Windows XFOIL 6.99). Settings and results: `docs/IMPLEMENTATION_PLAN.md` (Phase 11, completed section) and the `VALIDATION_GUIDELINE.md` §2.10 register.

- `python data/polars/xfoil_polars.py report996` writes `data/report996/polars_forced_merged.json` from `data/report996/polars_forced_sibling.json` and `data/report996/xfoil_sections/*.dat`.
- `python data/polars/xfoil_polars.py pereira ncrit9|ncrit5|xtr005` writes `data/pereira/naca4412_xfoil_<setting>.json`.
- `julia --project=. scripts/run/viterna_extension.jl` (from `PAIN.jl`) writes `viterna_extension.json`.
- `run_*.log`: generator output. Each JSON has a `header` with XFOIL version, panels, transition setting, grids, non-converged points, date and script.

Cautions: XFOIL hangs past stall on thin sections (60 s limit; partial output kept), and the merged Report 996 grid mixes two XFOIL builds.
