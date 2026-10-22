using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
# Never show a window on the desktop during smoke.
ENV["QT_QPA_PLATFORM"] = "offscreen"
using PAIN

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

if get(ENV, "PAIN_SMOKE_CASE_ONLY", "") == "1"
    _smoke_button_path_blk_p68()
    println("smoke_qml_load PASS (case-only child)")
    exit(0)
end

# Phase 34f / 37i: plain load (auto-quit), then button-path case (exact Run handler).
println("smoke_qml_load: calling main(; smoke_ms=1000)")
main(; smoke_ms=1000)
println("smoke_qml_load: plain load PASS")

# Qt often cannot be started twice in one process — run the button-path check in a child.
proj = abspath(joinpath(@__DIR__, ".."))
child = addenv(
    `$(Base.julia_cmd()) --project=$proj $(abspath(@__FILE__))`,
    "PAIN_SMOKE_CASE_ONLY" => "1",
    "QT_QPA_PLATFORM" => "offscreen",
)
println("smoke_qml_load: spawning child for smoke_case=BLK_P68")
run(child)
println("smoke_qml_load PASS")
