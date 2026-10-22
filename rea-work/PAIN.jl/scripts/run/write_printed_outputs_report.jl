#!/usr/bin/env julia
# Phase 38h: Manual §5.4.3 printed-outputs markdown for the REPRO_18b-r inputs.
# No comparison criterion; does not edit existing validation reports.
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN

paths = default_e11_paths()
p3 = phase3_trim(; η_lining=0.5)
r = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3, bpf_Hz=200.0,
                      blocking=R1, sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends,
                      mech=p3.mech)
out = printed_outputs(r.inputs; bpf_Hz=200.0, n_harmonics=3, broadband=true)
report = joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports",
                  "printed_outputs_REPRO_18b.md")
write_printed_outputs_md(report, out;
    title="Printed outputs (Manual §5.4.3) — REPRO_18b-r inputs")
println("wrote $report")
println("modes_per_band=$(length(out.modes_per_band)) coupling=$(length(out.coupling)) ",
        "top5=$(length(out.top5)) surface_upper=$(length(out.surface_upper))")
