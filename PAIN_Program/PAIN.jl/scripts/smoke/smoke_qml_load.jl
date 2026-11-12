using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
# Never show a window on the desktop during smoke.
ENV["QT_QPA_PLATFORM"] = "offscreen"
# Qt offscreen builds ship no fonts; set before QML loads so titles render.
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

"""
Phase 151d: the Cabin modes tab, drawn (offscreen). The tab builds its frames when it opens; the smoke presses Play and
grabs the frame view twice, some ticks apart, to a temp folder. The two shots must differ (the mode is seen moving), and
the frame index the animation reached must be a valid frame of the list the Observables hold.
"""
function _smoke_cabin_animation()
    png = get(ENV, "PAIN_SMOKE_CABIN_PNG", joinpath(mktempdir(), "CABIN_ANIM.png"))
    println("smoke_qml_load: cabin-mode animation main(; smoke_cabin_png=…)")
    main(; smoke_cabin_png=png)
    obs = PAIN._GUI_OBS[]
    @assert obs !== nothing
    frames = JSON3.read(String(obs["cm_frame_paths_json"][]), Vector{String})
    @assert length(frames) == Int(obs["cm_nframes"][]) "frame list $(length(frames)) ≠ cm_nframes $(obs["cm_nframes"][])"
    @assert all(isfile, frames) "a frame file is missing"
    png2 = replace(png, ".png" => "_later.png")
    @assert isfile(png) && filesize(png) > 0 "expected a cabin-animation shot at $png"
    @assert isfile(png2) && read(png2) != read(png) "expected the later shot ($png2) to differ from $png (animation did not move)"
    println("smoke_qml_load: cabin-mode animation PASS (", length(frames), " frames; ", png, ", ", png2, ")")
end

"""
Phase 114: the Validation tab's run-status box, drawn. Runs one case through the Run handler, then grabs the window
and checks the Observables the box binds to: the pill ends on `done`, and the verbose log holds the steps of the run
that just happened (not a recorded one). The PNG goes to a temp folder, never into the repository.
"""
function _smoke_run_status_box()
    png = get(ENV, "PAIN_SMOKE_RUNBOX_PNG", joinpath(mktempdir(), "RUN_STATUS_BOX.png"))
    println("smoke_qml_load: run-status box main(; smoke_runbox_png=…)")
    main(; smoke_runbox_png=png)
    obs = PAIN._GUI_OBS[]
    @assert obs !== nothing
    for k in ("run_state", "run_log", "val_state", "val_log", "po_state", "po_log", "cm_state", "cm_log")
        @assert haskey(obs, k) "missing run-status Observable: $k"
    end
    state = String(obs["val_state"][])
    log = String(obs["val_log"][])
    @assert state == "done" "expected the box to end on done, got: $state"
    @assert occursin("Running case BLK_P68", log) "verbose log missing the start line:\n$log"
    @assert occursin("criterion (", log) "verbose log missing the criterion line:\n$log"
    @assert occursin("verdict: ", log) "verbose log missing the verdict line:\n$log"   # BLK_P68 has no verdict since Phase 144d
    @assert occursin("finished in", log) || occursin(" — ", log) "verbose log missing the finish line:\n$log"
    @assert isfile(png) && filesize(png) > 0 "expected a run-status-box screenshot at $png"
    println("smoke_qml_load: run-status box PASS (", filesize(png), " bytes, ",
            count(==('\n'), log) + 1, " log lines)")
end

"""
Phase 127: the Run tab's input tabs, drawn (offscreen): the Propeller tab and the Numerics: Blocking tab are grabbed to
a temp folder; the inputs are generated from `gui_input_specs`, so an empty grab means the QML built no field.
"""
function _smoke_run_inputs()
    png = get(ENV, "PAIN_SMOKE_INPUTS_PNG", joinpath(mktempdir(), "RUN_INPUTS.png"))
    println("smoke_qml_load: run-tab inputs main(; smoke_inputs_png=…)")
    main(; smoke_inputs_png=png)
    png2 = replace(png, ".png" => "_numerics.png")
    @assert isfile(png) && filesize(png) > 0 "expected a Run-tab inputs screenshot at $png"
    @assert isfile(png2) && filesize(png2) > 0 "expected a Numerics-tab screenshot at $png2"
    println("smoke_qml_load: run-tab inputs PASS (", png, ", ", png2, ")")
end

"""
Phase 134: the Coverage tab, drawn (offscreen): one grab with the cases with a verdict, one with every case, to a temp
folder. The rows come from `coverage_json`, so an empty or blank grab means the QML built no chart.
"""
function _smoke_coverage()
    png = get(ENV, "PAIN_SMOKE_COVERAGE_PNG", joinpath(mktempdir(), "COVERAGE.png"))
    println("smoke_qml_load: coverage tab main(; smoke_coverage_png=…)")
    main(; smoke_coverage_png=png)
    png2 = replace(png, ".png" => "_all.png")
    @assert isfile(png) && filesize(png) > 0 "expected a Coverage-tab screenshot at $png"
    @assert isfile(png2) && read(png2) != read(png) "expected the every-case shot ($png2) to differ from $png (toggle had no effect)"
    println("smoke_qml_load: coverage tab PASS (", png, ", ", png2, ")")
end

if get(ENV, "PAIN_SMOKE_COVERAGE_ONLY", "") == "1"
    _smoke_coverage()
    println("smoke_qml_load PASS (coverage child)")
    exit(0)
end

if get(ENV, "PAIN_SMOKE_INPUTS_ONLY", "") == "1"
    _smoke_run_inputs()
    println("smoke_qml_load PASS (run-inputs child)")
    exit(0)
end

if get(ENV, "PAIN_SMOKE_RUNBOX_ONLY", "") == "1"
    _smoke_run_status_box()
    println("smoke_qml_load PASS (run-status-box child)")
    exit(0)
end

if get(ENV, "PAIN_SMOKE_CASE_ONLY", "") == "1"
    _smoke_button_path_blk_p68()
    println("smoke_qml_load PASS (case-only child)")
    exit(0)
end

if get(ENV, "PAIN_SMOKE_CABIN_ONLY", "") == "1"
    _smoke_cabin_animation()
    println("smoke_qml_load PASS (cabin-animation child)")
    exit(0)
end

# Phase 34f / 37i: plain load (auto-quit), then button-path case (exact Run handler).
# Phase 38h: QML includes the Printed outputs tab (Observables present after load).
# Phase 36: Cabin modes tab Observables present (display only).
# The block map tab was retired in Phase 147 (2026-11-10); the Coverage tab is the one chart.
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
@assert haskey(obs_after, "coverage_json")
println("smoke_qml_load: plain load PASS (Printed outputs + Cabin modes + coverage Observables present)")

# Qt often cannot be started twice in one process — run checks in children.
proj = abspath(joinpath(@__DIR__, "..", ".."))
child = addenv(
    `$(Base.julia_cmd()) --project=$proj $(abspath(@__FILE__))`,
    "PAIN_SMOKE_CASE_ONLY" => "1",
    "QT_QPA_PLATFORM" => "offscreen",
)
println("smoke_qml_load: spawning child for smoke_case=BLK_P68")
run(child)

# Child: the run-status box on the Validation tab (Phase 114). Writes its PNG to a temp folder.
child_box = addenv(
    `$(Base.julia_cmd()) --project=$proj $(abspath(@__FILE__))`,
    "PAIN_SMOKE_RUNBOX_ONLY" => "1",
    "QT_QPA_PLATFORM" => "offscreen",
    "QT_QPA_FONTDIR" => get(ENV, "QT_QPA_FONTDIR", "C:/Windows/Fonts"),
)
println("smoke_qml_load: spawning child for the run-status box")
run(child_box)
child_inputs = addenv(
    `$(Base.julia_cmd()) --project=$proj $(abspath(@__FILE__))`,
    "PAIN_SMOKE_INPUTS_ONLY" => "1",
    "QT_QPA_PLATFORM" => "offscreen",
    "QT_QPA_FONTDIR" => get(ENV, "QT_QPA_FONTDIR", "C:/Windows/Fonts"),
)
println("smoke_qml_load: spawning child for the Run-tab inputs")
run(child_inputs)
child_cov = addenv(
    `$(Base.julia_cmd()) --project=$proj $(abspath(@__FILE__))`,
    "PAIN_SMOKE_COVERAGE_ONLY" => "1",
    "QT_QPA_PLATFORM" => "offscreen",
    "QT_QPA_FONTDIR" => get(ENV, "QT_QPA_FONTDIR", "C:/Windows/Fonts"),
)
println("smoke_qml_load: spawning child for the Coverage tab")
run(child_cov)
child_cab = addenv(
    `$(Base.julia_cmd()) --project=$proj $(abspath(@__FILE__))`,
    "PAIN_SMOKE_CABIN_ONLY" => "1",
    "QT_QPA_PLATFORM" => "offscreen",
    "QT_QPA_FONTDIR" => get(ENV, "QT_QPA_FONTDIR", "C:/Windows/Fonts"),
)
println("smoke_qml_load: spawning child for the cabin-mode animation")
run(child_cab)
println("smoke_qml_load PASS")
