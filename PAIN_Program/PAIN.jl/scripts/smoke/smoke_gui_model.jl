using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
# Never show a window if anything under PAIN/QML starts a surface.
ENV["QT_QPA_PLATFORM"] = get(ENV, "QT_QPA_PLATFORM", "offscreen")
if lowercase(ENV["QT_QPA_PLATFORM"]) == "offscreen" && !haskey(ENV, "QT_QPA_FONTDIR")
    for cand in ("C:/Windows/Fonts", "/usr/share/fonts", "/System/Library/Fonts")
        if isdir(cand)
            ENV["QT_QPA_FONTDIR"] = cand
            break
        end
    end
end
using PAIN
using JSON3

@assert make_gui_observables()["bpf_text"][] == "BPF = 118.33 Hz"   # GUI default: Cabin_Noise turboprop with HP_1650 blades at helical Mach 0.85
# The runs below use the scale Hartzell project (seconds; the full-size default takes minutes); 3 harmonics for speed
obs = make_gui_observables(; default_project=joinpath(pkgdir(PAIN), "examples", "aircraft_scale_hartzell.json"))
@assert obs["bpf_text"][] == "BPF = 200.0 Hz"
gui_set_input!(obs, "n_harmonics", "3")
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

# Phase 147 (2026-11-10): the block map is retired; the Coverage tab's JSON holds the nine chain stages and one row
# per case, and the rows with a verdict are exactly the cases `has_verdict` keeps.
@assert !haskey(obs, "map_total_json")
cov = JSON3.read(obs["coverage_json"][])
@assert length(cov.stages) == length(PAIN.CHAIN_STAGES)
@assert Set(String(r.id) for r in cov.rows if String(r.verdict) != "no verdict") ==
        Set(id for id in keys(PAIN.CASE_INFO) if has_verdict(id))
println("smoke_gui_model: coverage JSON ", length(cov.rows), " rows")
# Task F2 — case_info_json from §2.13
blk = JSON3.read(case_info_json("BLK_P68"))
@assert occursin("R2", String(blk.explanation)) "BLK_P68 explanation must mention R2"
@assert haskey(obs, "val_info_json")
PAIN.select_validation_case_from_qml("BLK_P68")
vinfo = JSON3.read(obs["val_info_json"][])
@assert occursin("R2", String(vinfo.explanation))
detail = JSON3.read(case_info_json("R996_FIG14"))
@assert String(detail.id) == "R996_FIG14"
@assert !isempty(String(detail.source))
@assert haskey(detail, :explanation)
replay = run_validation_gui!(obs, "R996_FIG14")
@assert replay !== nothing
@assert replay.verdict === :met  # after A_rms = A/√2 (I-17 / F4 2026-10-21, post-hoc)
png14 = obs["val_plot_path"][]
@assert isfile(png14) && filesize(png14) > 0 "expected non-empty PNG at $png14"
@assert PAIN._GUI_LAST_VERDICTS["R996_FIG14"] === :met
# Phase 38h — Printed outputs Observables for the example (Run-tab) case
@assert haskey(obs, "po_status") && haskey(obs, "po_text") && haskey(obs, "po_json")
po = run_printed_outputs_gui!(obs)
@assert po !== nothing "printed outputs run failed: $(obs["po_status"][])"
@assert startswith(String(obs["po_status"][]), "Done")
po_parsed = JSON3.read(obs["po_json"][])
@assert length(po_parsed.modes_per_band) > 0
@assert length(po_parsed.top5) > 0
@assert Int(po_parsed.n_coupling) > 0
@assert Int(po_parsed.n_psi_G) > 0
@assert Int(po_parsed.n_surface_upper) > 0
# Five largest sorted by rank; shares in [0,1]; sum of shares per H ≤ 1
by_H = Dict{Int,Any}()
for row in po_parsed.top5
    H = Int(row.H)
    push!(get!(() -> Any[], by_H, H), row)
end
for (H, rows) in by_H
    sort!(rows; by=r -> Int(r.rank))
    for (k, row) in enumerate(rows)
        @assert Int(row.rank) == k "H$H top5 not sorted by rank"
        @assert 0 ≤ Float64(row.share) ≤ 1
    end
    @assert sum(Float64(r.share) for r in rows) ≤ 1 + 1e-9
end
@assert occursin("Modes per band", String(obs["po_text"][]))
@assert occursin("lower-quarter", String(po_parsed.surface_lower_note))

# Phase 36 — Cabin modes panel Observables filled (display only; no window)
@assert haskey(obs, "cm_status") && haskey(obs, "cm_frame_path") && haskey(obs, "cm_f")
obs["cm_mode"][] = 0.0
obs["cm_q"][] = 0.0
obs["cm_nframes"][] = 8.0
obs["cm_struct_mode"][] = 1.0
cm = fill_cabin_modes_gui!(obs)
@assert cm !== nothing "cabin modes fill failed: $(obs["cm_status"][])"
@assert startswith(String(obs["cm_status"][]), "Done")
@assert !isempty(String(obs["cm_f"][]))
@assert !isempty(String(obs["cm_Phi_G"][]))
@assert occursin("symmetric", String(obs["cm_symmetry"][]))
@assert isfile(String(obs["cm_frame_path"][])) && filesize(String(obs["cm_frame_path"][])) > 0
@assert isfile(String(obs["cm_peak_path"][]))
@assert String(obs["cm_c0"][]) == string(TABLE_C1_C0)
@assert String(obs["cm_theta0"][]) == "56.6"
@assert String(obs["cm_NY"][]) == "10"
@assert !isempty(String(obs["cm_f_prime"][]))
@assert isfile(String(obs["cm_struct_path"][]))

println("smoke_gui_model PASS (incl. Validation CYL2D_C1 / total map R996_FIG14 / F2 §2.13 / 38h printed outputs / 36 cabin modes)")
