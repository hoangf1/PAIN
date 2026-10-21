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
    # Long cases (996 / Pereira / BBN) run async so the UI status line can update.
    @async begin
        try
            run_validation_gui!(obs, String(id))
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
    obs["val_selected"][] = String(id)
    obs["val_criterion"][] = _criterion_for(id)
    src = validation_source_figure_path(id)
    obs["val_source_path"][] = isfile(src) ? src : ""
    png = validation_figure_path(id)
    obs["val_plot_path"][] = isfile(png) ? png : ""
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
    @qmlfunction open_validation_report_from_qml

    qml_file = joinpath(@__DIR__, "..", "gui", "main.qml")
    isfile(qml_file) || error("missing QML file: $qml_file")
    println("Loading GUI: ", qml_file)
    loadqml(qml_file; pain=props)
    exec()
    return 0
end
