# scripts/

Entry point: `run_gui.jl` (GUI). Run scripts with `julia --project=.` from `PAIN.jl`.

## run/ — write recorded results/reports
- `run_pain.jl`, `run_pain_reproduction.jl` — PAIN core run; REPRO_18b/E-16 reproduction report.
- `run_pereira.jl` — Pereira forward-flight report. `run_bbn_phase.jl`, `bbn_data.jl` — BBN phase report.
- `run_report996_loads.jl`, `run_report996_acoustics.jl`, `report996_setup.jl`, `build_report996_cfg.jl` — TR-996 setup, loads, acoustics reports.
- `run_f1a_smoke.jl`, `f1a_line_reference.jl`, `compare_gext_vs_f1a_grid.jl`, `run_gext_bound.jl` — F1A smoke, line reference, grid comparison, G_ext bound.
- `run_trim_loss_check.jl` — trim/loss (E-13..E-15) report. `e12_blocking.jl` — Fig. E-12 blocking check.
- `mrp_ritz_vs_d1.jl` — Ritz MRP vs Table D-1. `write_cyl2d_report.jl` — CYL2D report.
- `freeze_baselines.jl` — writes `data/baselines/`. `viterna_extension.jl` — polar extension.

## checks/ — one-off checks and probes (each wrote a report in `docs/validation_reports/`)
- `bisect_18b_chain.jl`, `h3_followup.jl`, `check_grid_mirroring.jl`, `check_eps_n_quadrature.jl`, `check_eta_r_normalization.jl`, `check_tau_t_variants.jl`, `check_table_d1_shapes.jl`, `check_fig_d2.py`, `check_two_resonator.py`.
- `probe_*.jl` — diagnostics (modal contributions, Q convergence, static, T1 levels, trim).
- `fit_mrp.jl`, `fit_mrp_kj.jl` — MRP fits kept as calibration provenance only; not used by validation.

## digitize/ — page rendering and transcription helpers
- `render_e16_e9.jl`, `render_fig_e11.jl`, `render_validation_figs.jl`; `write_tr996_fig3_i11.jl` (TR-996 Fig. 3 transcription).

## setup/ — environment helpers
- `add_deps.jl`, `add_gui_deps.jl`, `fix_f1a_deps.jl`, `setup_poppler.jl`.

## smoke/ — `smoke_gui_model.jl`, `smoke_qml_load.jl` (run offscreen).
## devtools/ — optional DaemonMode test accelerator (see its README). `retired/` — superseded scripts.
