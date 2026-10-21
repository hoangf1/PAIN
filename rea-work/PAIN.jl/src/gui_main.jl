# QML entry point. Call `main()` to launch the desktop GUI.

const _GUI_OBS = Ref{Any}(nothing)

"""QML Run button → Julia pipeline (registered with `@qmlfunction`)."""
function run_pain_from_qml()
    obs = _GUI_OBS[]
    obs === nothing && return nothing
    run_pain_gui!(obs)
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

    qml_file = joinpath(@__DIR__, "..", "gui", "main.qml")
    isfile(qml_file) || error("missing QML file: $qml_file")
    println("Loading GUI: ", qml_file)
    loadqml(qml_file; pain=props)
    exec()
    return 0
end
