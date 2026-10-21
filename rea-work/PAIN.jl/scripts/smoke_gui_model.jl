using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN

obs = make_gui_observables()
# phase 33g: GUI default is aircraft; smoke uses a short aircraft JSON path
json = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
@assert isfile(json)
obs["source"][] = "aircraft"
obs["aircraft_json"][] = abspath(json)
obs["n_harmonics"][] = 3.0
obs["bpf_Hz"][] = 150.0
ok = run_pain_gui!(obs)
println("ok=", ok)
println("status=", obs["status"][])
println("tag=", obs["validity_tag"][])
@assert ok
@assert obs["validity_tag"][] == "X-EXTRAP"
@assert obs["source_out"][] == "aircraft"

# Phase 34f: Validation tab list holds every registry entry; CYL2D_C1 runs through GUI helper.
listed = String.(split(obs["val_cases"][], '\n'; keepempty=false))
@assert length(listed) == length(VALIDATION_CASE_ORDER) "got $(length(listed)) lines, expected $(length(VALIDATION_CASE_ORDER))"
for id in VALIDATION_CASE_ORDER
    @assert any(startswith(line, id * "\t") for line in listed) "missing $id in val_cases"
end
direct = run_validation_case("CYL2D_C1")
gui_result = run_validation_gui!(obs, "CYL2D_C1")
@assert gui_result !== nothing
@assert gui_result.verdict === direct.verdict
@assert length(gui_result.table) == length(direct.table)
for (a, b) in zip(gui_result.table, direct.table)
    @assert a.computed ≈ b.computed rtol=1e-9 atol=0
    @assert a.reference ≈ b.reference rtol=1e-9 atol=0
end
png = obs["val_plot_path"][]
@assert isfile(png) && filesize(png) > 0 "expected non-empty PNG at $png"
println("smoke_gui_model PASS (incl. Validation CYL2D_C1)")
