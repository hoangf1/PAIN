"""
GUI model: Observables for QML binding. Physics stays in `run_pain_pipeline`.
"""

"""Last validation verdicts by case id (feeds map chip dots after a Run)."""
const _GUI_LAST_VERDICTS = Dict{String,Symbol}()

"""Last case_error_summary by case id (session only; never written by Run / Pkg.test)."""
const _GUI_LAST_ERRORS = Dict{String,NamedTuple}()

"""The Run tab runs the aircraft pipeline only (phase 33g): E-11 and synthetic sources verify PAIN (Validation tab)."""
const _GUI_SOURCE_MSG = "the Run tab runs the aircraft pipeline only; e11 / synthetic are PAIN verification inputs (Validation tab cases)"

validity_for_source(source::Symbol) =
    source === :e11 ? "V-EXP" : "X-EXTRAP"

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
    join(["fc=$(round(fc; digits=1)) Hz  SPL=$(round(spl; digits=2)) dB" for (fc, spl) in pairs], "\n")
end

"""Parse optional card 3–6 / 11–18 Observables (JSON text; empty → defaults)."""
function _parse_band_card_observables(obs::AbstractDict)
    function _parse_opt(key)
        s = strip(String(obs[key][]))
        isempty(s) && return nothing
        return JSON3.read(s)
    end
    return _parse_opt("bands_Hz"), _parse_opt("eta_r_band"), _parse_opt("eta_n_band")
end

"""
    make_gui_observables(; default_aircraft_json) -> Dict{String,Observable}

Input/output Observables. Wrap with `JuliaPropertyMap` in `launch_gui`.
"""
function make_gui_observables(;
        default_aircraft_json::AbstractString=joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json"))
    return Dict{String,Observable}(
        "source" => Observable("aircraft"),  # phase 33g: only user source; e11/synthetic are validation-only
        "blocking" => Observable("R2"),
        "L" => Observable(test_article_length()),
        "a" => Observable(0.508),
        "theta0_deg" => Observable(56.6),
        "r_p" => Observable(0.965),
        "phi_p_deg" => Observable(90.0),
        "z_p" => Observable(0.662),
        "n_harmonics" => Observable(5.0),
        "bpf_Hz" => Observable(150.0),
        "aircraft_json" => Observable(abspath(default_aircraft_json)),
        "C_struc" => Observable(3.0),        # C of Eq. (80), CR-3813 range 2-4
        "eta_n_bare" => Observable(0.05),    # η_n of a bare cabin (input, register g)
        "trim" => Observable("auto"),        # auto | bare | phase3
        # Manual cards 2, 9, 36 (38f-1); defaults = single-air / L_c=L / +1
        "rho0" => Observable(1.225),
        "c0" => Observable(340.0),
        "rho_ext" => Observable(1.225),
        "rho_int" => Observable(1.225),
        "c_ext" => Observable(340.0),
        "c_int" => Observable(340.0),
        "L_c" => Observable(test_article_length()),
        "d_cavity" => Observable(0.0),
        "rotation_direction" => Observable(1.0),
        # Manual cards 3–6 / 11–18 (38f-2); empty string = defaults (compute / full band list)
        "bands_Hz" => Observable(""),
        "eta_r_band" => Observable(""),
        "eta_n_band" => Observable(""),
        "status" => Observable("Ready. Choose aircraft JSON and press Run."),
        "busy" => Observable(false),
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
function run_validation_gui!(obs::AbstractDict, id::AbstractString; figure_dir::Union{Nothing,AbstractString}=nothing)
    obs["val_status"][] = "Running $id…"
    obs["busy"][] = true
    try
        haskey(VALIDATION_CASES, id) || error("unknown case: $id")
        case = VALIDATION_CASES[id]
        obs["val_selected"][] = String(id)
        obs["val_criterion"][] = _criterion_for(id)
        obs["val_info_json"][] = case_info_json(id; session_errors=_GUI_LAST_ERRORS)
        result = run_validation_case(id)
        png = plot_case(result, case.plot_spec;
                        path=figure_dir === nothing ? nothing : joinpath(figure_dir, "$(id).png"))
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
        return result
    catch e
        obs["val_status"][] = "Error ($id): $(sprint(showerror, e))"
        obs["val_result_text"][] = sprint(showerror, e)
        return nothing
    finally
        obs["busy"][] = false
    end
end

"""Run every runnable registered case sequentially (skips greyed)."""
function run_all_validation_gui!(obs::AbstractDict; figure_dir::Union{Nothing,AbstractString}=nothing)
    n = 0
    for c in list_validation_cases()
        isempty(c.unavailable_reason) || continue
        run_validation_gui!(obs, c.id; figure_dir)
        n += 1
    end
    obs["val_status"][] = "Run all finished ($n runnable cases)."
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
    try
        src = Symbol(String(obs["source"][]))
        src === :aircraft || error(_GUI_SOURCE_MSG)
        blk = uppercase(String(obs["blocking"][])) == "R1" ? R1 : R2
        L = Float64(obs["L"][])
        a = Float64(obs["a"][])
        theta0 = Float64(obs["theta0_deg"][])
        r_p = Float64(obs["r_p"][])
        phi_p = Float64(obs["phi_p_deg"][])
        z_p = Float64(obs["z_p"][])
        nH = Int(round(Float64(obs["n_harmonics"][])))
        bpf = Float64(obs["bpf_Hz"][])
        Cs = Float64(obs["C_struc"][])
        ηn = Float64(obs["eta_n_bare"][])
        trim = Symbol(String(obs["trim"][]))
        json_path = String(obs["aircraft_json"][])
        ρ0 = Float64(obs["rho0"][])
        c0 = Float64(obs["c0"][])
        ρ_ext = Float64(obs["rho_ext"][])
        ρ_int = Float64(obs["rho_int"][])
        c_ext = Float64(obs["c_ext"][])
        c_int = Float64(obs["c_int"][])
        L_c = Float64(obs["L_c"][])
        d_cav = Float64(obs["d_cavity"][])
        rot = Int(round(Float64(obs["rotation_direction"][])))
        bands_kw, ηr_kw, ηn_kw = _parse_band_card_observables(obs)

        common = (
            L=L, a=a, theta0_deg=theta0,
            r_p=r_p, phi_p_deg=phi_p, z_p=z_p,
            rotation_direction=rot,
            source=src, blocking=blk,
            n_harmonics=nH, bpf_Hz=bpf,
            C_struc=Cs, η_n_bare=ηn, trim=trim,
            ρ0=ρ0, c0=c0, ρ_ext=ρ_ext, ρ_int=ρ_int, c_ext=c_ext, c_int=c_int,
            L_c=L_c, d=d_cav,
            bands=bands_kw, η_r_band=ηr_kw, η_n_band=ηn_kw,
        )
        isfile(json_path) || error("aircraft JSON not found: $json_path")
        result = run_pain_pipeline(; common..., aircraft_json=json_path)
        out = printed_outputs(result.inputs; bpf_Hz=bpf, n_harmonics=nH)
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
        return out
    catch e
        obs["po_status"][] = "Error: $(sprint(showerror, e))"
        obs["po_text"][] = sprint(showerror, e)
        obs["po_json"][] = "{}"
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

        cy = cyl2d_c1_for_display()
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
        return fr
    catch e
        obs["cm_status"][] = "Error: $(sprint(showerror, e))"
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
    try
        src = Symbol(String(obs["source"][]))
        src === :aircraft || error(_GUI_SOURCE_MSG)
        blk = uppercase(String(obs["blocking"][])) == "R1" ? R1 : R2
        L = Float64(obs["L"][])
        a = Float64(obs["a"][])
        theta0 = Float64(obs["theta0_deg"][])
        r_p = Float64(obs["r_p"][])
        phi_p = Float64(obs["phi_p_deg"][])
        z_p = Float64(obs["z_p"][])
        nH = Int(round(Float64(obs["n_harmonics"][])))
        bpf = Float64(obs["bpf_Hz"][])
        Cs = Float64(obs["C_struc"][])
        ηn = Float64(obs["eta_n_bare"][])
        trim = Symbol(String(obs["trim"][]))
        json_path = String(obs["aircraft_json"][])
        ρ0 = Float64(obs["rho0"][])
        c0 = Float64(obs["c0"][])
        ρ_ext = Float64(obs["rho_ext"][])
        ρ_int = Float64(obs["rho_int"][])
        c_ext = Float64(obs["c_ext"][])
        c_int = Float64(obs["c_int"][])
        L_c = Float64(obs["L_c"][])
        d_cav = Float64(obs["d_cavity"][])
        rot = Int(round(Float64(obs["rotation_direction"][])))
        bands_kw, ηr_kw, ηn_kw = _parse_band_card_observables(obs)

        common = (
            L=L, a=a, theta0_deg=theta0,
            r_p=r_p, phi_p_deg=phi_p, z_p=z_p,
            rotation_direction=rot,
            source=src, blocking=blk,
            n_harmonics=nH, bpf_Hz=bpf,
            C_struc=Cs, η_n_bare=ηn, trim=trim,
            ρ0=ρ0, c0=c0, ρ_ext=ρ_ext, ρ_int=ρ_int, c_ext=c_ext, c_int=c_int,
            L_c=L_c, d=d_cav,
            bands=bands_kw, η_r_band=ηr_kw, η_n_band=ηn_kw,
        )
        isfile(json_path) || error("aircraft JSON not found: $json_path")
        result = run_pain_pipeline(; common..., aircraft_json=json_path)

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
        sil = sil_from_third_octave(spec.third_octave_SPL_dB)
        obs["sil_text"][] = "SIL=$(round(sil; digits=1)) dB"

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
        return true
    catch e
        obs["status"][] = "Error: $(sprint(showerror, e))"
        obs["validity_tag"][] = ""
        return false
    finally
        obs["busy"][] = false
    end
end
