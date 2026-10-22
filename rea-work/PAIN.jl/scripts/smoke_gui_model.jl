using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
# Never show a window if anything under PAIN/QML starts a surface.
ENV["QT_QPA_PLATFORM"] = get(ENV, "QT_QPA_PLATFORM", "offscreen")
using PAIN
using JSON3

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
@assert haskey(obs, "val_runnable")
PAIN._GUI_OBS[] = obs
PAIN.select_validation_case_from_qml("MRP_D1")
@assert obs["val_selected"][] == "MRP_D1" && obs["val_runnable"][]
# Selection stays keyed by case id after a run (highlight root-cause fix).
direct = run_validation_case("CYL2D_C1")
gui_result = run_validation_gui!(obs, "CYL2D_C1")
@assert gui_result !== nothing
@assert obs["val_selected"][] == "CYL2D_C1"
@assert gui_result.verdict === direct.verdict
@assert length(gui_result.table) == length(direct.table)
for (a, b) in zip(gui_result.table, direct.table)
    @assert a.computed ≈ b.computed rtol=1e-9 atol=0
    @assert a.reference ≈ b.reference rtol=1e-9 atol=0
end
png = obs["val_plot_path"][]
@assert isfile(png) && filesize(png) > 0 "expected non-empty PNG at $png"
gext = run_validation_case("GEXT_BOUND")
@assert gext.verdict === :no_verdict
@assert occursin("diagnostic", gext.reason)

# Task C — Validation map JSONs + select/run R996_FIG14
for mid in ("pain", "aircraft")
    key = mid == "pain" ? "map_pain_json" : "map_aircraft_json"
    @assert haskey(obs, key)
    parsed = JSON3.read(obs[key][])
    @assert String(parsed.id) == mid
    @assert length(parsed.blocks) > 0
    @assert haskey(parsed, :how_to_read) && !isempty(String(parsed.how_to_read))
end
# Task F2 — case_info_json from §2.13
blk = JSON3.read(case_info_json("BLK_P68"))
@assert occursin("R2", String(blk.explanation)) "BLK_P68 explanation must mention R2"
@assert haskey(obs, "val_info_json")
PAIN.select_validation_case_from_qml("BLK_P68")
vinfo = JSON3.read(obs["val_info_json"][])
@assert occursin("R2", String(vinfo.explanation))
PAIN.select_map_case_from_qml("R996_FIG14")
@assert obs["map_selected"][] == "R996_FIG14"
detail = JSON3.read(obs["map_detail_json"][])
@assert String(detail.id) == "R996_FIG14"
@assert !isempty(String(detail.source))
@assert haskey(detail, :explanation)
replay = run_validation_gui!(obs, "R996_FIG14")
@assert replay !== nothing
@assert replay.verdict === :met  # after A_rms = A/√2 (I-17 / F4 2026-10-21, post-hoc)
png14 = obs["val_plot_path"][]
@assert isfile(png14) && filesize(png14) > 0 "expected non-empty PNG at $png14"
let
    air_after = JSON3.read(obs["map_aircraft_json"][])
    chip14 = nothing
    for b in air_after.blocks
        for c in b.cases
            if String(c.id) == "R996_FIG14"
                chip14 = c
            end
        end
    end
    @assert chip14 !== nothing "R996_FIG14 missing from aircraft map JSON after run"
    @assert String(chip14.last) == "met" "expected last=met, got $(chip14.last)"
end
println("smoke_gui_model PASS (incl. Validation CYL2D_C1 / map R996_FIG14 / F2 §2.13)")
