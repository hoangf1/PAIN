# QML entry point. Call `main()` to launch the desktop GUI.

const _GUI_OBS = Ref{Any}(nothing)

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

"""
    main()
    main(args; smoke_ms=0)

Launch the PAIN desktop GUI. Blocks until the window is closed.

```julia
using PAIN
main()
```

`smoke_ms > 0` auto-quits after that many milliseconds (for smoke tests).
"""
function main(args=ARGS; smoke_ms::Real=0)
    ENV["QT_QUICK_CONTROLS_STYLE"] = get(ENV, "QT_QUICK_CONTROLS_STYLE", "Fusion")

    obs = make_gui_observables()
    smoke_ms > 0 && (obs["smoke_ms"][] = Float64(smoke_ms))
    _GUI_OBS[] = obs

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

    qml_file = joinpath(@__DIR__, "..", "gui", "main.qml")
    isfile(qml_file) || error("missing QML file: $qml_file")
    println("Loading GUI: ", qml_file)
    loadqml(qml_file; pain=props)
    exec()
    return 0
end
