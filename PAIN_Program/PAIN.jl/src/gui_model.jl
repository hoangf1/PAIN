"""
GUI model: Observables for QML binding. Physics stays in `run_pain_pipeline`.
"""

"""Last validation verdicts by case id (feeds map chip dots after a Run)."""
const _GUI_LAST_VERDICTS = Dict{String,Symbol}()

"""Last case_error_summary by case id (session only; never written by Run / Pkg.test)."""
const _GUI_LAST_ERRORS = Dict{String,NamedTuple}()

validity_for_source(source::Symbol) =
    source === :e11 ? "V-EXP" : "X-EXTRAP"

# --- Phase 114: run-status boxes ------------------------------------------------------------------------------
# A panel's Run button must say what the user is looking at: nothing run yet, a result recorded earlier and read
# from disk, a run in progress, a result this session computed, or one made out of date by an input that moved
# since. `*_state` carries the first four (QML decides the fifth, STALE, from the inputs); `*_log` carries the
# steps. The GUI runs these from `@async` on the cooperative Qt loop, so each log line yields and the window
# repaints while the run is still going.

"""Longest verbose log a panel keeps; older lines are dropped."""
const _GUI_LOG_MAX_LINES = 300

"""Append one timestamped line to a panel's verbose log and let the window repaint."""
function gui_log!(obs::AbstractDict, panel::AbstractString, line::AbstractString)
    key = "$(panel)_log"
    haskey(obs, key) || return nothing
    stamp = Dates.format(Dates.now(), "HH:MM:SS")
    lines = split(String(obs[key][]), '\n'; keepempty=false)
    push!(lines, "[$stamp] $line")
    length(lines) > _GUI_LOG_MAX_LINES && (lines = lines[(end - _GUI_LOG_MAX_LINES + 1):end])
    obs[key][] = join(lines, "\n")
    yield()
    return nothing
end

"""Start a panel's run: clear the log, flip the pill to `running`, return the start time."""
function gui_run_begin!(obs::AbstractDict, panel::AbstractString, what::AbstractString)
    haskey(obs, "$(panel)_state") || return time()
    obs["$(panel)_log"][] = ""
    obs["$(panel)_state"][] = "running"
    gui_log!(obs, panel, what)
    return time()
end

"""Finish a panel's run: flip the pill to `done` / `error` and log how long it took."""
function gui_run_end!(obs::AbstractDict, panel::AbstractString, t0::Real;
                      state::AbstractString="done", note::AbstractString="")
    haskey(obs, "$(panel)_state") || return nothing
    obs["$(panel)_state"][] = String(state)
    secs = round(time() - float(t0); digits=1)
    gui_log!(obs, panel, isempty(note) ? "finished in $(secs) s" : "$(note) — $(secs) s")
    return nothing
end

"""
Pill for a case that is shown but has not been run in this session: `snapshot` when
`case_error_summary.csv` has a recorded result for it, `ready` when it has none.
"""
function gui_mark_snapshot!(obs::AbstractDict, panel::AbstractString, id::AbstractString)
    haskey(obs, "$(panel)_state") || return nothing
    rec = recorded_case_errors()
    r = get(rec, String(id), nothing)
    if r === nothing
        obs["$(panel)_state"][] = "ready"
        obs["$(panel)_log"][] = ""
    else
        obs["$(panel)_state"][] = "snapshot"
        obs["$(panel)_log"][] = "Showing the recorded result for $(id), not a run from this session.\n" *
                                "recorded $(r.run_date): $(r.text)\n" *
                                "Press Run to compute it now."
    end
    return nothing
end

function _refresh_map_json!(obs::AbstractDict)
    obs["map_total_json"][] = validation_map_json("total";
        last=_GUI_LAST_VERDICTS, session_errors=_GUI_LAST_ERRORS)
    return nothing
end

"""Re-parse §2.13 and refresh map / selected-case Observables (map tab open / doc edit)."""
function reload_validation_docs_gui!(obs::AbstractDict)
    reload_validation_docs!()
    _refresh_map_json!(obs)
    sid = String(obs["map_selected"][])
    if !isempty(sid)
        obs["map_detail_json"][] = case_info_json(sid; session_errors=_GUI_LAST_ERRORS)
    end
    vsid = String(obs["val_selected"][])
    if !isempty(vsid)
        obs["val_info_json"][] = case_info_json(vsid; session_errors=_GUI_LAST_ERRORS)
        obs["val_criterion"][] = _criterion_for(vsid)
    end
    obs["val_cases"][] = _format_val_case_list()
    haskey(obs, "coverage_json") && (obs["coverage_json"][] = coverage_json())
    return nothing
end

function _format_tonal(spectrum::InteriorSpectrum)
    join([
        "H=$H  f=$(round(H * spectrum.bpf_Hz; digits=1)) Hz  SPL=$(round(L; digits=2)) dB"
        for (H, L) in enumerate(spectrum.harmonic_SPL_dB)
    ], "\n")
end

function _format_third(spectrum::InteriorSpectrum)
    pairs = sort!(collect(spectrum.third_octave_SPL_dB); by=first)
    isempty(pairs) && return "(no 1/3-octave bands)"
    # Phase 132: a band with no level (the −300 dB floor, e.g. a band with no tone in a tones-only run) says so
    join(["fc=$(round(fc; digits=1)) Hz  " * (spl > _NO_LEVEL_DB ? "SPL=$(round(spl; digits=2)) dB" : "no level")
          for (fc, spl) in pairs], "\n")
end

const _NO_LEVEL_DB = -250.0   # below this a band level is the empty-band floor (−300 dB), not a level

"""SIL text: the mean of the 500–4000 Hz octave levels, or a note when an octave has no level (a tones-only run)."""
function _format_sil(third::AbstractDict)
    has(oc) = any(p -> abs(log2(p.first / oc)) ≤ 0.5 / 3 + 0.2 && p.second > _NO_LEVEL_DB, collect(third))
    all(has, (500.0, 1000.0, 2000.0, 4000.0)) ||
        return "SIL: not given (no level in every 500–4000 Hz octave; tones only)"
    return "SIL=$(round(sil_from_third_octave(third); digits=1)) dB"
end

"""
    make_gui_observables(; default_project) -> Dict{String,Observable}

Input/output Observables. Wrap with `JuliaPropertyMap` in `launch_gui`. The Run tab's inputs are the fields of
`gui_input_specs`, filled from `default_project` (Phase 127); the run is the aircraft pipeline only (phase 33g).
"""
function make_gui_observables(; default_project::AbstractString=gui_default_project_path())
    base = _load_project_dict(default_project)
    vals = gui_field_values(base)
    obs = Dict{String,Observable}(
        # Phase 127: every input is a GUI field (gui_inputs.jl); the project file is only an optional Open / Save
        "project_path" => Observable(""),            # file last opened or saved ("" = the built-in default project)
        "project_base_json" => Observable(JSON3.write(base)),
        "input_values_json" => Observable(JSON3.write(vals)),
        "inputs_json" => Observable(gui_inputs_json(vals)),
        "bpf_text" => Observable(gui_bpf_text(vals)),
        "project_note" => Observable(_gui_project_note(default_project, base)),
        "status" => Observable("Ready. Set the inputs and press Run."),
        "busy" => Observable(false),
        # Phase 114 — run-status boxes. `*_state` drives the pill a panel shows (ready / snapshot / running /
        # done / error); `*_log` is the verbose line-by-line record of the run the box can expand.
        "run_state" => Observable("ready"),
        "run_log" => Observable(""),
        "val_state" => Observable("ready"),
        "val_log" => Observable(""),
        "po_state" => Observable("ready"),
        "po_log" => Observable(""),
        "cm_state" => Observable("ready"),
        "cm_log" => Observable(""),
        "smoke_ms" => Observable(0.0),
        "validity_tag" => Observable(""),
        "tonal_text" => Observable(""),
        "third_text" => Observable(""),
        "t1_text" => Observable(""),
        "t2_text" => Observable(""),
        "dBA_text" => Observable(""),
        "sil_text" => Observable(""),
        "notes" => Observable(""),
        "source_out" => Observable(""),
        # Phase 34 — Validation tab (read-only cases)
        "val_cases" => Observable(_format_val_case_list()),
        "val_selected" => Observable("CYL2D_C1"),
        "val_runnable" => Observable(true),
        "val_plot_path" => Observable(""),
        "val_source_path" => Observable(""),
        "val_result_text" => Observable("Select a case and press Run."),
        "val_status" => Observable("Ready."),
        "val_criterion" => Observable(_criterion_for("CYL2D_C1")),
        "val_info_json" => Observable(case_info_json("CYL2D_C1"; session_errors=_GUI_LAST_ERRORS)),
        "val_report_path" => Observable(""),
        # Task C — Validation map tab (single total flowchart)
        "map_total_json" => Observable(validation_map_json("total";
            last=_GUI_LAST_VERDICTS, session_errors=_GUI_LAST_ERRORS)),
        "map_selected" => Observable(""),
        "map_selected_block" => Observable(""),
        "map_detail_json" => Observable("{}"),
        "map_content_width" => Observable(0.0),
        "map_view_width" => Observable(0.0),
        "smoke_map_png" => Observable(""),
        "smoke_runbox_png" => Observable(""),   # Phase 114: offscreen shot of the Validation tab run-status box
        "smoke_inputs_png" => Observable(""),   # Phase 127: offscreen shots of the Run tab's input tabs
        "smoke_coverage_png" => Observable(""), # Phase 134: offscreen shot of the Coverage tab
        # Phase 134 — Coverage tab: every case's chain span, reference and recorded verdict (display only)
        "coverage_json" => Observable(coverage_json()),
        # Phase 38h — Manual §5.4.3 printed outputs (read-only)
        "po_status" => Observable("Ready. Press Run / Refresh for the current Run-tab case."),
        "po_text" => Observable(""),
        "po_json" => Observable("{}"),
        "po_report_path" => Observable(""),
        # Phase 36 — Cabin modes panel (display only; fixed CYL2D_C1 inputs)
        "cm_status" => Observable("Ready. Select mode and press Refresh."),
        "cm_mode" => Observable(0.0),
        "cm_q" => Observable(0.0),
        "cm_speed" => Observable(1.0),
        "cm_playing" => Observable(false),
        "cm_frame_index" => Observable(0.0),
        "cm_nframes" => Observable(24.0),
        "cm_f" => Observable(""),
        "cm_Phi_G" => Observable(""),
        "cm_symmetry" => Observable(""),
        "cm_fig_c3" => Observable(""),
        "cm_c0" => Observable(string(CYL2D_C1_DISPLAY_INPUTS.c0)),
        "cm_theta0" => Observable(string(CYL2D_C1_DISPLAY_INPUTS.theta0_deg)),
        "cm_NY" => Observable(string(CYL2D_C1_DISPLAY_INPUTS.NY)),
        "cm_frame_path" => Observable(""),
        "cm_peak_path" => Observable(""),
        "cm_gif_path" => Observable(""),
        "cm_frame_paths_json" => Observable("[]"),
        "cm_axial_note" => Observable(""),
        "cm_struct_mode" => Observable(1.0),
        "cm_struct_path" => Observable(""),
        "cm_struct_frame_paths_json" => Observable("[]"),
        "cm_f_prime" => Observable(""),
        "cm_note" => Observable("display only — interpolated for drawing; no criterion"),
    )
    return obs
end

function _gui_project_note(path::AbstractString, proj::AbstractDict)
    note = "Project: " * (normpath(path) == gui_default_project_path() ? "built-in default ($(basename(path)))" : path)
    unread = gui_unread_keys(proj)
    isempty(unread) || (note *= ". Keys in the file that the code does not read: " * join(unread, ", "))
    return note
end

gui_values(obs::AbstractDict) = JSON3.read(obs["input_values_json"][], Dict{String,String})
gui_base(obs::AbstractDict) = JSON3.read(obs["project_base_json"][], Dict{String,Any})

"""One field edited in the GUI (text as typed)."""
function gui_set_input!(obs::AbstractDict, key::AbstractString, text::AbstractString)
    vals = gui_values(obs)
    any(s -> s.key == key, gui_input_specs()) || error("unknown GUI input \"$key\"")
    vals[String(key)] = String(text)
    obs["input_values_json"][] = JSON3.write(vals)
    obs["bpf_text"][] = gui_bpf_text(vals)
    return nothing
end

"""Open a project file: its values fill the fields; values it does not give show the code defaults."""
function gui_open_project!(obs::AbstractDict, path::AbstractString)
    p = String(strip(path))
    isfile(p) || error("project file not found: $p")
    base = _load_project_dict(p)
    vals = gui_field_values(base)
    obs["project_base_json"][] = JSON3.write(base)
    obs["input_values_json"][] = JSON3.write(vals)
    obs["inputs_json"][] = gui_inputs_json(vals)
    obs["bpf_text"][] = gui_bpf_text(vals)
    obs["project_path"][] = p
    obs["project_note"][] = _gui_project_note(p, base)
    return nothing
end

"""Back to the built-in default project."""
function gui_reset_project!(obs::AbstractDict)
    gui_open_project!(obs, gui_default_project_path())
    obs["project_path"][] = ""
    return nothing
end

"""Save the fields as a project file (the aircraft JSON format, with `run` and `settings`)."""
function gui_save_project!(obs::AbstractDict, path::AbstractString)
    p = String(strip(path))
    isempty(p) && error("give a file name to save the project to")
    proj = gui_build_project(gui_base(obs), gui_values(obs))
    open(io -> JSON3.pretty(io, JSON3.write(proj)), p, "w")
    obs["project_base_json"][] = JSON3.write(proj)
    obs["project_path"][] = p
    obs["project_note"][] = _gui_project_note(p, proj)
    return nothing
end

function _format_val_case_list()
    # Map → block order, then the cases on no block; last column says where the case is listed (caseIdFromRow uses col 0).
    lines = String[]
    for id in validation_map_case_order()
        c = VALIDATION_CASES[id]
        grey = isempty(c.unavailable_reason) ? "" : " [unavailable]"
        place = on_validation_map(id) ? "on the validation map" : "no verdict (NO_VERDICT_CASES.md)"
        push!(lines, "$(c.id)\t$(c.title)\tphase $(c.phase)\t$(c.label)$(grey)\t$(place)")
    end
    return join(lines, "\n")
end

function _criterion_for(id::AbstractString)
    haskey(VALIDATION_CASES, id) || return ""
    c = VALIDATION_CASES[id]
    return "criterion ($(c.criterion_date)): $(c.criterion_text)"
end

"""
    run_validation_gui!(obs, id)

Run one registered case, write its PNG, and push results into Validation-tab Observables.
Long cases may be called from a `@async` wrapper by the QML side. `figure_dir` (tests) writes the
PNG there instead of `docs/validation_reports/figures`.
"""
function run_validation_gui!(obs::AbstractDict, id::AbstractString; figure_dir::Union{Nothing,AbstractString}=nothing,
                             track::Bool=true)
    obs["val_status"][] = "Running $id…"
    t0 = track ? gui_run_begin!(obs, "val", "Running case $id") : time()
    track || gui_log!(obs, "val", "running $id")
    obs["busy"][] = true
    try
        haskey(VALIDATION_CASES, id) || error("unknown case: $id")
        case = VALIDATION_CASES[id]
        obs["val_selected"][] = String(id)
        obs["val_criterion"][] = _criterion_for(id)
        obs["val_info_json"][] = case_info_json(id; session_errors=_GUI_LAST_ERRORS)
        gui_log!(obs, "val", "criterion ($(case.criterion_date)): $(case.criterion_text)")
        gui_log!(obs, "val", "computing (the panel does not update again until the case returns)")
        result = run_validation_case(id)
        gui_log!(obs, "val", "verdict: $(result.verdict) — $(result.reason)")
        gui_log!(obs, "val", "drawing the figure from this run")
        png = plot_case(result, case.plot_spec;
                        path=figure_dir === nothing ? nothing : joinpath(figure_dir, "$(id).png"))
        gui_log!(obs, "val", "figure: $(png)")
        src = validation_source_figure_path(id)
        # Clear then set so QML Image reloads even when the path string is unchanged.
        obs["val_plot_path"][] = ""
        obs["val_plot_path"][] = png
        obs["val_source_path"][] = isfile(src) ? src : ""
        obs["val_result_text"][] = format_validation_result(result)
        obs["val_report_path"][] = result.report_path
        obs["val_status"][] = "Done $id: $(result.verdict) — $(result.reason)"
        _GUI_LAST_VERDICTS[String(id)] = result.verdict
        _GUI_LAST_ERRORS[String(id)] = case_error_summary(result, case.plot_spec)
        obs["val_info_json"][] = case_info_json(id; session_errors=_GUI_LAST_ERRORS)
        if String(obs["map_selected"][]) == String(id)
            obs["map_detail_json"][] = case_info_json(id; session_errors=_GUI_LAST_ERRORS)
        end
        _refresh_map_json!(obs)
        track && gui_run_end!(obs, "val", t0; note="$id $(result.verdict)")
        return result
    catch e
        obs["val_status"][] = "Error ($id): $(sprint(showerror, e))"
        obs["val_result_text"][] = sprint(showerror, e)
        gui_log!(obs, "val", "error: $(sprint(showerror, e))")
        track && gui_run_end!(obs, "val", t0; state="error", note="stopped")
        return nothing
    finally
        obs["busy"][] = false
    end
end

"""Run every runnable registered case sequentially (skips greyed)."""
function run_all_validation_gui!(obs::AbstractDict; figure_dir::Union{Nothing,AbstractString}=nothing)
    runnable = [c for c in list_validation_cases() if isempty(c.unavailable_reason)]
    t0 = gui_run_begin!(obs, "val", "Run all: $(length(runnable)) runnable cases, one after another")
    n = 0
    for c in runnable
        n += 1
        gui_log!(obs, "val", "($n/$(length(runnable))) $(c.id)")
        run_validation_gui!(obs, c.id; figure_dir, track=false)
    end
    obs["val_status"][] = "Run all finished ($n runnable cases)."
    gui_run_end!(obs, "val", t0; note="ran $n cases")
    return true
end

"""
    run_printed_outputs_gui!(obs)

Build the current Run-tab case, fill Manual §5.4.3 printed-output Observables
(read-only tables). Same cooperative `@async` path as Validation Run (37i).
"""
function run_printed_outputs_gui!(obs::AbstractDict)
    obs["busy"][] = true
    obs["po_status"][] = "Running printed outputs…"
    t0 = gui_run_begin!(obs, "po", "Building the Manual §5.4.3 printed outputs for the current Run-tab case")
    try
        args = gui_run_args(gui_base(obs), gui_values(obs))
        gui_log!(obs, "po", "running the pipeline (blocking $(args.kwargs.blocking), $(args.kwargs.n_harmonics) harmonics)")
        result = try
            run_pain_pipeline(; args.kwargs...)
        finally
            rm(args.path; force=true)
        end
        gui_log!(obs, "po", "collecting the printed tables")
        st = pain_settings_from_dict(get(args.project, "settings", Dict{String,Any}()))
        # the run's own BPF (B·rpm/60), and the run's settings (c_ω and the rest) for the tables
        out = with_pain_settings(st) do
            printed_outputs(result.inputs; bpf_Hz=result.ff.bpf_Hz, n_harmonics=args.kwargs.n_harmonics)
        end
        obs["po_text"][] = format_printed_outputs_text(out)
        obs["po_json"][] = printed_outputs_gui_json(out)
        obs["po_report_path"][] = ""
        po_st = "Done. modes=$(length(out.modes_per_band)) bands; " *
            "top5=$(length(out.top5)); coupling=$(length(out.coupling)); " *
            "surface_upper=$(length(out.surface_upper))."
        if hasproperty(result, :provenance)
            labels = provenance_header_labels(result.provenance)
            !isempty(labels.uses_defaults) && (po_st *= " — " * labels.uses_defaults)
        end
        obs["po_status"][] = po_st
        gui_run_end!(obs, "po", t0; note="printed outputs built")
        return out
    catch e
        obs["po_status"][] = "Error: $(sprint(showerror, e))"
        obs["po_text"][] = sprint(showerror, e)
        obs["po_json"][] = "{}"
        gui_log!(obs, "po", "error: $(sprint(showerror, e))")
        gui_run_end!(obs, "po", t0; state="error", note="stopped")
        return nothing
    finally
        obs["busy"][] = false
    end
end

"""
    fill_cabin_modes_gui!(obs)

Build display-only cabin mode frames for the Cabin modes tab (fixed CYL2D_C1
inputs). Writes PNG/GIF under `gui/cache/mode_anim` (not validation figures).
Same cooperative `@async` path as Validation Run (37i) when called from QML.
Optional 36d: structural ψ PNG and f′ for the selected structural mode.
"""
function fill_cabin_modes_gui!(obs::AbstractDict)
    obs["busy"][] = true
    obs["cm_status"][] = "Building cabin mode frames…"
    t0 = gui_run_begin!(obs, "cm", "Rendering the cabin and structural mode frames")
    try
        mode = Int(round(Float64(obs["cm_mode"][])))
        q = Int(round(Float64(obs["cm_q"][])))
        nframes = Int(round(Float64(obs["cm_nframes"][])))
        nframes = clamp(nframes, 4, 48)
        mode = clamp(mode, 0, 19)
        q = clamp(q, 0, 20)
        obs["cm_mode"][] = Float64(mode)
        obs["cm_q"][] = Float64(q)
        obs["cm_nframes"][] = Float64(nframes)

        inp = CYL2D_C1_DISPLAY_INPUTS
        obs["cm_c0"][] = string(inp.c0)
        obs["cm_theta0"][] = string(inp.theta0_deg)
        obs["cm_NY"][] = string(inp.NY)

        gui_log!(obs, "cm", "solving CYL2D for the display inputs")
        cy = cyl2d_c1_for_display()
        gui_log!(obs, "cm", "building $(nframes) frames of cabin mode $(mode) (q=$(q))")
        fr = mode_animation_frames(cy, mode; nframes=nframes, grid=61)
        cache = mode_animation_cache_dir()
        stem = joinpath(cache, "mode_$(lpad(mode, 2, '0'))_q$(q)")
        paths = render_mode_animation(stem * ".gif", fr; format=:gif, axial_q=q,
                                      L=test_article_length())
        frame_pngs = render_mode_frame_pngs(joinpath(cache, "frames_m$(mode)"), fr;
                                            prefix="f")
        obs["cm_f"][] = string(round(fr.f_Hz; digits=4))
        obs["cm_Phi_G"][] = string(round(fr.Φ_G; digits=5))
        obs["cm_symmetry"][] = fr.symmetric ? "symmetric" : "antisymmetric"
        obs["cm_fig_c3"][] = fr.fig_c3 === nothing ? "" : _fig_c3_text(fr.fig_c3)
        obs["cm_peak_path"][] = paths.png_path
        obs["cm_gif_path"][] = paths.gif_path
        obs["cm_frame_paths_json"][] = JSON3.write(frame_pngs)
        obs["cm_frame_index"][] = 0.0
        obs["cm_frame_path"][] = isempty(frame_pngs) ? paths.png_path : frame_pngs[1]
        af0 = axial_factor(q, test_article_length())(0.0)
        afL = axial_factor(q, test_article_length())(test_article_length())
        obs["cm_axial_note"][] = "Eq. (C.9) q=$q: cos(qπz/L) at z=0 → $(round(af0; digits=4)), " *
            "z=L → $(round(afL; digits=4))"
        obs["cm_note"][] = fr.note

        gui_log!(obs, "cm", "rendering the structural mode shape and f′")
        # 36d — structural shape + f′ (display only)
        st_idx = clamp(Int(round(Float64(obs["cm_struct_mode"][]))), 1, 32)
        obs["cm_struct_mode"][] = Float64(st_idx)
        fuse = FuselageGeometry(test_article_length(), 0.508, inp.theta0_deg)
        st = structural_modes_from_table_d1(; L=fuse.L, a=fuse.a,
                                            theta0_deg=fuse.theta0_deg).modes[st_idx]
        # Phase 63: the structural mode animates with the acoustic frames (same frame count and timer)
        sfr = structural_mode_frames(st, fuse; nframes=nframes)
        spaths = render_structural_frame_pngs(joinpath(cache, "frames_s$(st_idx)"), sfr; prefix="s")
        obs["cm_struct_frame_paths_json"][] = JSON3.write(spaths)
        obs["cm_struct_path"][] = spaths[1]
        cd = coupling_display(cy.modes[mode + 1], st, fuse; q=q)
        obs["cm_f_prime"][] = "f′(n=$(cd.acoustic_index), r=$(cd.structural_index), q=$q) = " *
            string(round(cd.f_prime; digits=6))

        obs["cm_status"][] = "Done mode $mode (q=$q): f=$(obs["cm_f"][]), " *
            "$(obs["cm_symmetry"][]), $(nframes) frames."
        gui_run_end!(obs, "cm", t0; note="mode $mode (q=$q), $(nframes) frames")
        return fr
    catch e
        obs["cm_status"][] = "Error: $(sprint(showerror, e))"
        gui_log!(obs, "cm", "error: $(sprint(showerror, e))")
        gui_run_end!(obs, "cm", t0; state="error", note="stopped")
        return nothing
    finally
        obs["busy"][] = false
    end
end

"""
    run_pain_gui!(obs::AbstractDict)

Single `run()` for the QML button. Reads input Observables, calls
`run_pain_pipeline`, pushes results into output Observables.
"""
function run_pain_gui!(obs::AbstractDict)
    obs["busy"][] = true
    obs["status"][] = "Running…"
    t0 = gui_run_begin!(obs, "run", "Running the aircraft pipeline")
    try
        args = gui_run_args(gui_base(obs), gui_values(obs))
        kw = args.kwargs
        gui_log!(obs, "run", "blocking $(kw.blocking), $(kw.n_harmonics) harmonics; $(gui_bpf_text(gui_values(obs)))")
        nset = count(k -> k != "broadband", keys(get(args.project, "settings", Dict())))   # broadband: forced off (Phase 130)
        nset > 0 && gui_log!(obs, "run", "$nset numerics setting(s) differ from the defaults")
        gui_log!(obs, "run", "BEMT → F1A → grid → blocking → modes → Eq. (8) — this is the slow part")
        result = try
            run_pain_pipeline(; kw...)
        finally
            rm(args.path; force=true)
        end
        gui_log!(obs, "run", "pipeline done; computing dB(A) and SIL")

        tag = validity_for_source(result.source)
        spec = result.spectrum
        obs["validity_tag"][] = tag
        obs["source_out"][] = String(result.source)
        obs["tonal_text"][] = _format_tonal(spec)
        obs["third_text"][] = _format_third(spec)
        obs["notes"][] = spec.notes

        dBA, lo, hi = overall_dBA(spec)
        obs["dBA_text"][] =
            "dB(A)=$(round(dBA; digits=1))  [$(round(lo; digits=1)), $(round(hi; digits=1))] (±3.5 dB)"
        obs["sil_text"][] = _format_sil(spec.third_octave_SPL_dB)

        # T1/T2 compare the NASA test article with E-16 / E-9: Validation-tab cases, not this run
        obs["t1_text"][] = "(T1/T2 are Validation-tab cases on the NASA test article)"
        obs["t2_text"][] = "(T1/T2 are Validation-tab cases on the NASA test article)"
        st = "Done ($tag). source=$(result.source)"
        if hasproperty(result, :provenance)
            labels = provenance_header_labels(result.provenance)
            !isempty(labels.uses_defaults) && (st *= " — " * labels.uses_defaults)
            !isempty(labels.nasa_article) && (st *= " — " * labels.nasa_article)
        end
        obs["status"][] = st
        gui_run_end!(obs, "run", t0; note="interior spectrum ready ($tag)")
        return true
    catch e
        obs["status"][] = "Error: $(sprint(showerror, e))"
        obs["validity_tag"][] = ""
        gui_log!(obs, "run", "error: $(sprint(showerror, e))")
        gui_run_end!(obs, "run", t0; state="error", note="stopped")
        return false
    finally
        obs["busy"][] = false
    end
end
