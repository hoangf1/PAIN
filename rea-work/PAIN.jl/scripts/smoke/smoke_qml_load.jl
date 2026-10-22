using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
# Never show a window on the desktop during smoke.
ENV["QT_QPA_PLATFORM"] = "offscreen"
# Qt offscreen builds ship no fonts; set before QML loads so map titles render.
if !haskey(ENV, "QT_QPA_FONTDIR")
    for cand in ("C:/Windows/Fonts", "/usr/share/fonts", "/System/Library/Fonts")
        if isdir(cand)
            ENV["QT_QPA_FONTDIR"] = cand
            break
        end
    end
end
using PAIN
using JSON3

@assert haskey(VALIDATION_CASES, "CYL2D_C1")
@assert length(list_validation_cases()) == length(VALIDATION_CASE_ORDER)

function _smoke_button_path_blk_p68()
    png = validation_figure_path("BLK_P68")
    t0 = time()
    println("smoke_qml_load: button path main(; smoke_case=\"BLK_P68\")")
    main(; smoke_case="BLK_P68")
    obs = PAIN._GUI_OBS[]
    @assert obs !== nothing "_GUI_OBS missing after main"
    st = String(obs["val_status"][])
    println("val_status=", st)
    @assert startswith(st, "Done BLK_P68") "expected status starting with Done BLK_P68, got: $st"
    @assert isfile(png) "expected PNG at $png"
    @assert mtime(png) >= t0 - 1.0 "PNG mtime $(mtime(png)) not after start $t0"
    println("smoke_qml_load: button path PASS")
end

function _smoke_map_canvas()
    png = get(ENV, "PAIN_SMOKE_MAP_PNG", "")
    println("smoke_qml_load: map canvas main(; smoke_map_png=…)")
    # Group layout check (model data) before QML; same geometry as the canvas frames.
    assert_validation_map_groups_disjoint("total")
    if isempty(png)
        main(; smoke_ms=2000)
    else
        # zoom-1 left + right grabs need time for two Timer → grabToImage cycles
        main(; smoke_ms=4500, smoke_map_png=png)
    end
    obs = PAIN._GUI_OBS[]
    @assert obs !== nothing
    @assert haskey(obs, "map_total_json")
    parsed = JSON3.read(obs["map_total_json"][])
    @assert String(parsed.id) == "total"
    @assert length(parsed.blocks) > 0
    cw = Float64(obs["map_content_width"][])
    vw = Float64(obs["map_view_width"][])
    println("map_content_width=", cw, " map_view_width=", vw)
    # Content must exceed the view so horizontal scrolling is possible.
    # If QML never reported sizes (cw==0), fall back to layout span from JSON.
    if cw > 0 && vw > 0
        @assert cw > vw "expected map content wider than view (cw=$cw vw=$vw)"
    else
        max_col = maximum(Int(b.col) for b in parsed.blocks)
        @assert max_col >= 8 "total map columns too few for horizontal scroll (max_col=$max_col)"
        println("smoke_qml_load: map size Observables unset; accepted max_col=", max_col)
    end
    if !isempty(png)
        @assert isfile(png) "expected VALIDATION_MAP_TOTAL at $png"
        @assert filesize(png) > 0
        right = replace(png, "VALIDATION_MAP_TOTAL.png" => "VALIDATION_MAP_TOTAL_right.png")
        @assert isfile(right) "expected VALIDATION_MAP_TOTAL_right at $right"
        @assert filesize(right) > 0
        println("smoke_qml_load: screenshot OK ", png, " bytes=", filesize(png),
                " right=", right, " bytes=", filesize(right))
    end
    println("smoke_qml_load: map canvas PASS")
end

if get(ENV, "PAIN_SMOKE_CASE_ONLY", "") == "1"
    _smoke_button_path_blk_p68()
    println("smoke_qml_load PASS (case-only child)")
    exit(0)
end

if get(ENV, "PAIN_SMOKE_MAP_ONLY", "") == "1"
    _smoke_map_canvas()
    println("smoke_qml_load PASS (map-only child)")
    exit(0)
end

# Phase 34f / 37i: plain load (auto-quit), then button-path case (exact Run handler).
# Phase 38h: QML includes the Printed outputs tab (Observables present after load).
# Phase 36: Cabin modes tab Observables present (display only).
# Total map: offscreen screenshot + content width > view width (horizontal scroll).
println("smoke_qml_load: calling main(; smoke_ms=1000)")
main(; smoke_ms=1000)
obs_after = PAIN._GUI_OBS[]
@assert obs_after !== nothing
@assert haskey(obs_after, "po_status") && haskey(obs_after, "po_text") && haskey(obs_after, "po_json")
@assert occursin("Ready", String(obs_after["po_status"][])) ||
        occursin("Done", String(obs_after["po_status"][])) ||
        occursin("printed", lowercase(String(obs_after["po_status"][])))
@assert haskey(obs_after, "cm_status") && haskey(obs_after, "cm_mode") && haskey(obs_after, "cm_frame_path")
@assert haskey(obs_after, "cm_f") && haskey(obs_after, "cm_Phi_G") && haskey(obs_after, "cm_symmetry")
@assert haskey(obs_after, "cm_c0") && haskey(obs_after, "cm_theta0") && haskey(obs_after, "cm_NY")
@assert occursin("Ready", String(obs_after["cm_status"][])) ||
        occursin("Done", String(obs_after["cm_status"][]))
@assert haskey(obs_after, "map_total_json")
map_parsed = JSON3.read(obs_after["map_total_json"][])
@assert String(map_parsed.id) == "total"
@assert length(map_parsed.blocks) > 0
println("smoke_qml_load: plain load PASS (Printed outputs + Cabin modes + total map Observables present)")

# Qt often cannot be started twice in one process — run checks in children.
proj = abspath(joinpath(@__DIR__, "..", ".."))
child = addenv(
    `$(Base.julia_cmd()) --project=$proj $(abspath(@__FILE__))`,
    "PAIN_SMOKE_CASE_ONLY" => "1",
    "QT_QPA_PLATFORM" => "offscreen",
)
println("smoke_qml_load: spawning child for smoke_case=BLK_P68")
run(child)

# Child: map canvas load + horizontal scroll + screenshot.
map_shot = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports",
                              "figures", "VALIDATION_MAP_TOTAL.png"))
mkpath(dirname(map_shot))
child_map = addenv(
    `$(Base.julia_cmd()) --project=$proj $(abspath(@__FILE__))`,
    "PAIN_SMOKE_MAP_ONLY" => "1",
    "PAIN_SMOKE_MAP_PNG" => map_shot,
    "QT_QPA_PLATFORM" => "offscreen",
    "QT_QPA_FONTDIR" => get(ENV, "QT_QPA_FONTDIR", "C:/Windows/Fonts"),
)
println("smoke_qml_load: spawning child for total map canvas / VALIDATION_MAP_TOTAL.png")
run(child_map)
println("smoke_qml_load PASS")
