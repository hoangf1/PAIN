# QML entry point. Call `main()` to launch the desktop GUI.

const _GUI_OBS = Ref{Any}(nothing)
const _GUI_CLOSED = Ref(false)

"""QML window Closing / smoke quit → unblock `_exec_until_gui_closed`."""
function mark_gui_closed_from_qml()
    _GUI_CLOSED[] = true
    return nothing
end

"""QML Run button → Julia pipeline (registered with `@qmlfunction`)."""
function run_pain_from_qml()
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    run_pain_gui!(obs)
    return nothing
end

"""QML Validation tab: run one case by id string."""
function run_validation_from_qml(id::AbstractString)
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    sid = String(strip(String(id)))
    isempty(sid) && (sid = String(obs["val_selected"][]))
    isempty(sid) && return nothing
    if !validation_case_runnable(sid)
        obs["val_status"][] = "$sid is unavailable (greyed)."
        return nothing
    end
    # Prefer @async on the Julia thread that services QML; yield so the UI can paint "Running…".
    # Requires a cooperative Qt loop (`_exec_until_gui_closed`); blocking `exec()` never runs these tasks.
    @async begin
        try
            yield()
            run_validation_gui!(obs, sid)
        catch e
            obs["val_status"][] = "Error: $(sprint(showerror, e))"
            obs["busy"][] = false
        end
    end
    return nothing
end

function run_all_validation_from_qml()
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    @async begin
        try
            yield()
            run_all_validation_gui!(obs)
        catch e
            obs["val_status"][] = "Error: $(sprint(showerror, e))"
            obs["busy"][] = false
        end
    end
    return nothing
end

function select_validation_case_from_qml(id::AbstractString)
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    sid = String(strip(String(id)))
    isempty(sid) && return nothing
    obs["val_selected"][] = sid
    obs["val_runnable"][] = validation_case_runnable(sid)
    obs["val_criterion"][] = _criterion_for(sid)
    obs["val_info_json"][] = case_info_json(sid)
    src = validation_source_figure_path(sid)
    obs["val_source_path"][] = isfile(src) ? src : ""
    png = validation_figure_path(sid)
    # Clear then set so a prior case's plot is not mistaken for this selection.
    obs["val_plot_path"][] = ""
    if isfile(png)
        obs["val_plot_path"][] = png
    end
    obs["val_status"][] = validation_case_runnable(sid) ?
        "Selected $sid — press Run." :
        "Selected $sid — unavailable (greyed)."
    return nothing
end

"""QML Validation map tab: select a case chip (registry or UT_*)."""
function select_map_case_from_qml(id::AbstractString)
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    sid = String(strip(String(id)))
    isempty(sid) && return nothing
    obs["map_selected"][] = sid
    obs["map_detail_json"][] = case_info_json(sid)
    if haskey(VALIDATION_CASES, sid)
        select_validation_case_from_qml(sid)
    end
    return nothing
end

"""QML Validation map tab opened: re-parse §2.13 so an edited .md shows without restart."""
function reload_validation_docs_from_qml()
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    reload_validation_docs_gui!(obs)
    return nothing
end

function open_validation_report_from_qml()
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    path = String(obs["val_report_path"][])
    isempty(path) && return nothing
    isfile(path) || return nothing
    if Sys.iswindows()
        run(`cmd /c start "" $path`; wait=false)
    elseif Sys.isapple()
        run(`open $path`; wait=false)
    else
        run(`xdg-open $path`; wait=false)
    end
    return nothing
end

"""QML Printed outputs tab: Run / Refresh (cooperative `@async`, same as Validation)."""
function run_printed_outputs_from_qml()
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    @async begin
        try
            yield()
            run_printed_outputs_gui!(obs)
        catch e
            obs["po_status"][] = "Error: $(sprint(showerror, e))"
            obs["busy"][] = false
        end
    end
    return nothing
end

"""QML Cabin modes tab: Refresh (cooperative `@async`, same as Validation / 37i)."""
function run_cabin_modes_from_qml()
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    @async begin
        try
            yield()
            fill_cabin_modes_gui!(obs)
        catch e
            obs["cm_status"][] = "Error: $(sprint(showerror, e))"
            obs["busy"][] = false
        end
    end
    return nothing
end

function set_cabin_mode_from_qml(mode)
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    obs["cm_mode"][] = Float64(clamp(Int(round(Float64(mode))), 0, 19))
    return nothing
end

function set_cabin_q_from_qml(q)
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    obs["cm_q"][] = Float64(clamp(Int(round(Float64(q))), 0, 20))
    return nothing
end

function set_cabin_struct_from_qml(r)
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    obs["cm_struct_mode"][] = Float64(clamp(Int(round(Float64(r))), 1, 32))
    return nothing
end

"""Advance / set the displayed frame index (play Timer or scrubber)."""
function cabin_modes_step_frame_from_qml(delta)
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    n = max(1, Int(round(Float64(obs["cm_nframes"][]))))
    idx = Int(round(Float64(obs["cm_frame_index"][])))
    idx = mod(idx + Int(round(Float64(delta))), n)
    obs["cm_frame_index"][] = Float64(idx)
    try
        paths = JSON3.read(String(obs["cm_frame_paths_json"][]), Vector{String})
        if 1 ≤ idx + 1 ≤ length(paths)
            obs["cm_frame_path"][] = paths[idx + 1]
        end
    catch
    end
    return nothing
end

"""
Cooperative Qt event loop so Julia `@async` tasks (Validation Run buttons) can run.

QML.jl docs: `exec()` fills the window but blocks the main process; `exec_async()` is
similar but "will not block the main process" and "polls the QML interface periodically
for events, using a timer in the Julia event loop." Stock `exec_async()` waits on a nested
REPL (REPL use). For `main()` we use the same `process_events` + `sleep` poll until the
window closes (Closing / smoke Timers call `mark_gui_closed_from_qml`).
"""
function _exec_until_gui_closed()
    _GUI_CLOSED[] = false
    while !_GUI_CLOSED[]
        QML.process_eventloop_updates()
        QML.process_events()
        sleep(0.015)
    end
    QML.quit(QML.get_qmlengine())
    QML.quit()
    QML.cleanup()
    QML.process_events()
    return
end

"""
    main()
    main(args; smoke_ms=0, smoke_case="")

Launch the PAIN desktop GUI. Blocks until the window is closed.

```julia
using PAIN
main()
```

`smoke_ms > 0` auto-quits after that many milliseconds (for smoke tests).
`smoke_case` non-empty: after load, QML calls `run_validation_from_qml` (same as the Run
button), waits until Done, then quits (for button-path smoke tests).
"""
function main(args=ARGS; smoke_ms::Real=0, smoke_case::AbstractString="")
    ENV["QT_QUICK_CONTROLS_STYLE"] = get(ENV, "QT_QUICK_CONTROLS_STYLE", "Fusion")

    obs = make_gui_observables()
    smoke_ms > 0 && (obs["smoke_ms"][] = Float64(smoke_ms))
    obs["smoke_case"] = Observable(String(smoke_case))
    _GUI_OBS[] = obs
    _GUI_CLOSED[] = false

    props = JuliaPropertyMap()
    for (k, v) in obs
        props[k] = v
    end

    @qmlfunction run_pain_from_qml
    @qmlfunction run_validation_from_qml
    @qmlfunction run_all_validation_from_qml
    @qmlfunction select_validation_case_from_qml
    @qmlfunction select_map_case_from_qml
    @qmlfunction reload_validation_docs_from_qml
    @qmlfunction open_validation_report_from_qml
    @qmlfunction run_printed_outputs_from_qml
    @qmlfunction run_cabin_modes_from_qml
    @qmlfunction set_cabin_mode_from_qml
    @qmlfunction set_cabin_q_from_qml
    @qmlfunction set_cabin_struct_from_qml
    @qmlfunction cabin_modes_step_frame_from_qml
    @qmlfunction mark_gui_closed_from_qml

    qml_file = joinpath(@__DIR__, "..", "gui", "main.qml")
    isfile(qml_file) || error("missing QML file: $qml_file")
    println("Loading GUI: ", qml_file)
    loadqml(qml_file; pain=props)
    _exec_until_gui_closed()
    return 0
end
