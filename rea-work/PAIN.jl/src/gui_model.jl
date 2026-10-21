"""
GUI model: Observables for QML binding. Physics stays in `run_pain_pipeline`.
"""

validity_for_source(source::Symbol) =
    source === :e11 ? "V-EXP" : "X-EXTRAP"

function _format_records(records::Vector{ValidationRecord})
    isempty(records) && return "(none)"
    join(["$(r.result)  $(r.metric)  --  $(r.notes)" for r in records], "\n")
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

"""
    make_gui_observables(; default_aircraft_json) -> Dict{String,Observable}

Input/output Observables. Wrap with `JuliaPropertyMap` in `launch_gui`.
"""
function make_gui_observables(;
        default_aircraft_json::AbstractString=joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json"))
    return Dict{String,Observable}(
        "source" => Observable("e11"),
        "blocking" => Observable("R2"),
        "L" => Observable(1.803),
        "a" => Observable(0.508),
        "theta0_deg" => Observable(56.6),
        "r_p" => Observable(0.965),
        "phi_p_deg" => Observable(90.0),
        "z_p" => Observable(0.90),
        "n_harmonics" => Observable(3.0),
        "bpf_Hz" => Observable(200.0),
        "aircraft_json" => Observable(abspath(default_aircraft_json)),
        "C_struc" => Observable(3.0),        # C of Eq. (80), CR-3813 range 2-4
        "eta_n_bare" => Observable(0.05),    # η_n of a bare cabin (input, register g)
        "trim" => Observable("auto"),        # auto | bare | phase3
        "status" => Observable("Ready. Choose source and press Run."),
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
    )
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

        common = (
            L=L, a=a, theta0_deg=theta0,
            r_p=r_p, phi_p_deg=phi_p, z_p=z_p,
            source=src, blocking=blk,
            n_harmonics=nH, bpf_Hz=bpf,
            C_struc=Cs, η_n_bare=ηn, trim=trim,
            use_synthetic=(src === :synthetic),
        )
        result = if src === :aircraft
            isfile(json_path) || error("aircraft JSON not found: $json_path")
            run_pain_pipeline(; common..., aircraft_json=json_path)
        else
            run_pain_pipeline(; common...)
        end

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

        if result.source === :e11
            t1 = evaluate_T1(spec)
            t2 = evaluate_T2(spec)
            obs["t1_text"][] = _format_records(t1)
            obs["t2_text"][] = _format_records(t2)
            n1 = count(r -> r.result == "PASS", t1)
            n2 = count(r -> r.result == "PASS", t2)
            obs["status"][] = "Done ($tag). T1 $n1/$(length(t1)) PASS · T2 $n2/$(length(t2)) PASS"
        else
            obs["t1_text"][] = "(T1/T2 gates apply to source=e11 only)"
            obs["t2_text"][] = "(T1/T2 gates apply to source=e11 only)"
            obs["status"][] = "Done ($tag). source=$(result.source)"
        end
        return true
    catch e
        obs["status"][] = "Error: $(sprint(showerror, e))"
        obs["validity_tag"][] = ""
        return false
    finally
        obs["busy"][] = false
    end
end
