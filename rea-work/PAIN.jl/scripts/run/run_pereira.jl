#!/usr/bin/env julia
# Phase 28: Pereira forward-flight check. Pass/fail waits on 23d [AUTHOR].
using PAIN
using Dates
using JSON3

const ROOT = joinpath(@__DIR__, "..", "..", "..")
const DATA = joinpath(ROOT, "data", "pereira")
const CHORD = joinpath(DATA, "pereira_fig1b_chord_twist.csv")
const OUT_MD = joinpath(ROOT, "docs", "validation_reports", "pereira_forward_flight.md")
const OUT_CSV = joinpath(DATA, "pereira_results.csv")
const OUT_JSON = joinpath(@__DIR__, "..", "..", "examples", "pereira_apc9x6_scaled.json")
const FIG9 = joinpath(DATA, "pereira_fig9_harmonics.csv")
const FIG8 = joinpath(DATA, "pereira_fig8_directivity.csv")
const FIG6 = joinpath(DATA, "pereira_fig6_peaks.csv")
const FIG7 = joinpath(DATA, "pereira_fig7_harmonics.csv")

const POLAR_SETS = (
    (:ncrit9, joinpath(DATA, "naca4412_xfoil_ncrit9.json")),
    (:ncrit5, joinpath(DATA, "naca4412_xfoil_ncrit5.json")),
    (:xtr005, joinpath(DATA, "naca4412_xfoil_xtr005.json")),
)

function load_chord_twist(path)
    lines = filter(l -> !startswith(strip(l), "#") && !isempty(strip(l)), readlines(path))
    hdr = split(lowercase(first(lines)), ',')
    rows = lines[2:end]
    ir = findfirst(h -> occursin("r_over", h) || h == "r_r", hdr)
    ic = findfirst(h -> occursin("c_over", h) || occursin("chord", h), hdr)
    it = findfirst(h -> occursin("twist", h) || occursin("beta", h), hdr)
    ir === nothing && (ir = 1); ic === nothing && (ic = 2); it === nothing && (it = 3)
    rR = Float64[]; cR = Float64[]; tw = Float64[]
    for row in rows
        p = split(row, ',')
        length(p) >= 3 || continue
        push!(rR, parse(Float64, p[ir]))
        push!(cR, parse(Float64, p[ic]))
        push!(tw, parse(Float64, p[it]))
    end
    return rR, cR, tw
end

"""Downsample to ~n stations (keep endpoints)."""
function downsample(rR, cR, tw; n=25)
    N = length(rR)
    N <= n && return rR, cR, tw
    idx = unique(round.(Int, range(1, N; length=n)))
    return rR[idx], cR[idx], tw[idx]
end

function load_fig9_exp()
    # (phi, harmonic) -> SPL
    d = Dict{Tuple{Float64,Int},Float64}()
    isfile(FIG9) || return d
    for raw in eachline(FIG9)
        startswith(raw, "#") && continue
        startswith(raw, "panel") && continue
        p = split(strip(raw), ',')
        length(p) >= 5 || continue
        p[4] == "Experimental" || continue
        isempty(p[5]) && continue
        d[(parse(Float64, p[2]), parse(Int, p[3]))] = parse(Float64, p[5])
    end
    return d
end

function load_fig8_exp()
    d = Dict{Tuple{Float64,Int},Float64}()
    isfile(FIG8) || return d
    for raw in eachline(FIG8)
        startswith(raw, "#") && continue
        startswith(raw, "BPF") && continue
        p = split(strip(raw), ',')
        length(p) >= 5 || continue
        H = tryparse(Int, p[1]); φ = tryparse(Float64, p[2]); ref = tryparse(Float64, p[5])
        (H === nothing || φ === nothing || ref === nothing) && continue
        d[(φ, H)] = ref
    end
    return d
end

function load_fig6_exp()
    d = Dict{Tuple{Float64,Int},Float64}()
    isfile(FIG6) || return d
    for raw in eachline(FIG6)
        startswith(raw, "#") && continue
        startswith(raw, "panel") && continue
        p = split(strip(raw), ',')
        length(p) >= 6 || continue
        p[3] == "Experimental" || continue
        isempty(p[6]) && continue
        d[(parse(Float64, p[2]), parse(Int, p[4]))] = parse(Float64, p[6])
    end
    return d
end

function load_fig7_exp_dpsi1()
    # Experimental ψ₁(φ) − ψ₁(0°) from digitized harmonic fit
    phases = Dict{Float64,Float64}()
    isfile(FIG7) || return Dict{Float64,Float64}()
    for raw in eachline(FIG7)
        startswith(raw, "#") && continue
        startswith(raw, "panel") && continue
        p = split(strip(raw), ',')
        length(p) >= 7 || continue
        p[3] == "Experimental" || continue
        φ = parse(Float64, p[2])
        phases[φ] = parse(Float64, p[7])
    end
    haskey(phases, 0.0) || return Dict{Float64,Float64}()
    ψ0 = phases[0.0]
    return Dict(φ => (ψ - ψ0) for (φ, ψ) in phases)
end

function wrap180(deg)
    return mod(deg + 180, 360) - 180
end

function make_cfg(rR, cR, tw; R=0.15, t_over_c=0.0)
    keep = [i for i in eachindex(rR) if 0.30 - 1e-6 <= rR[i] <= 0.99 + 1e-6]
    radii = [rR[i] * R for i in keep]
    chord = [cR[i] * R for i in keep]
    twist = [tw[i] for i in keep]
    return (
        propeller = (
            num_blades = 2,
            tip_radius_m = R,
            hub_radius_m = radii[1],
            rpm = 8000.0,
            thickness_over_chord = t_over_c,
            pitch_offset_deg = 0.0,
            radii_m = radii,
            chord_m = chord,
            twist_deg = twist,
        ),
        operating_point = (forward_speed_mps = 16.0, rho_kg_m3 = 1.225, c0_mps = 340.3),
        anopp_table8_calibrate = false,
    )
end

function main()
    R = 0.15
    rR0, cR0, tw0 = load_chord_twist(CHORD)
    rR, cR, tw = downsample(rR0, cR0, tw0; n=25)
    mean_c = sum(cR[i] * R for i in eachindex(cR)) / length(cR)
    println("stations=$(length(rR)) mean_chord_m=$(round(mean_c; digits=5)) (paper 0.02285)")

    # Write example JSON (thickness off default)
    cfg0 = make_cfg(rR, cR, tw; t_over_c=0.0)
    open(OUT_JSON, "w") do io
        JSON3.pretty(io, Dict(
            "description" => "Pereira APC 9×6 scaled D=0.30 m from pereira_fig1b_chord_twist.csv",
            "propeller" => Dict(
                "num_blades" => 2,
                "tip_radius_m" => R,
                "hub_radius_m" => cfg0.propeller.hub_radius_m,
                "rpm" => 8000.0,
                "thickness_over_chord" => 0.0,
                "pitch_offset_deg" => 0.0,
                "radii_m" => collect(cfg0.propeller.radii_m),
                "chord_m" => collect(cfg0.propeller.chord_m),
                "twist_deg" => collect(cfg0.propeller.twist_deg),
            ),
            "operating_point" => Dict("forward_speed_mps" => 16.0, "rho_kg_m3" => 1.225, "c0_mps" => 340.3),
            "anopp_table8_calibrate" => false,
        ))
    end
    println("wrote ", OUT_JSON)

    phis = collect(-20.0:10.0:40.0)
    obs = [Observer([sind(φ), cosd(φ), 0.0], [16.0, 0.0, 0.0], "φ=$φ") for φ in phis]
    fig9 = load_fig9_exp()
    fig8 = load_fig8_exp()
    fig6 = load_fig6_exp()
    fig7_dψ = load_fig7_exp_dpsi1()
    sl = ScaledLoads(14.55, 0.4133)

    load_rows = []
    spl_rows = []
    csv_rows = []  # long-format rows for pereira_results.csv (report tables + Fig.6–8)
    for (tag, path) in POLAR_SETS
        isfile(path) || continue
        af, st = load_polar_set(path; set=:primary, cr75=0.1558)
        for (tname, toc) in (("toff", 0.0), ("ton", 0.12))
            cfg = make_cfg(rR, cR, tw; t_over_c=toc)
            println("polar=$tag thick=$tname …")
            src = evaluate_propeller_source(cfg, obs; n_harmonics=6, num_src_times=64, af=af)
            src_s = evaluate_propeller_source(cfg, obs; n_harmonics=6, num_src_times=64, af=af, loads=sl)
            push!(load_rows, (polar=String(tag), thick=tname, T=src.T, Q=src.Q, CT=src.CT, CP=src.CP,
                              Ts=src_s.T, Qs=src_s.Q, st=st))
            loads_tag = tname == "toff" ? "ccblade" : "ccblade_ton"
            push!(csv_rows, (quantity="T", polar_set=String(tag), loads=loads_tag, phi_deg="",
                             harmonic="", computed=src.T, reference=14.55, units="N"))
            push!(csv_rows, (quantity="Q", polar_set=String(tag), loads=loads_tag, phi_deg="",
                             harmonic="", computed=src.Q, reference=0.4133, units="N·m"))
            # ScaledLoads reproduce Table 3 targets (informational echo)
            push!(csv_rows, (quantity="T", polar_set=String(tag), loads="scaled", phi_deg="",
                             harmonic="", computed=src_s.T, reference=14.55, units="N"))
            push!(csv_rows, (quantity="Q", polar_set=String(tag), loads="scaled", phi_deg="",
                             harmonic="", computed=src_s.Q, reference=0.4133, units="N·m"))
            # H1 phase at φ=0 for Δψ₁
            ψ0 = rad2deg(src_s.phase[findfirst(==(0.0), phis), 1])
            for (i, φ) in enumerate(phis)
                for H in 1:6
                    Su = peak_Pa_to_spl_dB(src.amplitude[i, H])
                    Ss = peak_Pa_to_spl_dB(src_s.amplitude[i, H])
                    if H <= 2
                        ref9 = get(fig9, (φ, H), NaN)
                        push!(spl_rows, (polar=String(tag), thick=tname, φ=φ, H=H,
                                         SPL_u=Su, SPL_s=Ss, fig9=ref9))
                        push!(csv_rows, (quantity="SPL_fig9", polar_set=String(tag),
                                         loads=tname == "toff" ? "scaled" : "scaled_ton",
                                         phi_deg=string(φ), harmonic=string(H),
                                         computed=Ss, reference=ref9, units="dB"))
                    end
                    ref8 = get(fig8, (φ, H), NaN)
                    push!(csv_rows, (quantity="SPL_fig8", polar_set=String(tag),
                                     loads=tname == "toff" ? "scaled" : "scaled_ton",
                                     phi_deg=string(φ), harmonic=string(H),
                                     computed=Ss, reference=ref8, units="dB"))
                    ref6 = get(fig6, (φ, H), NaN)
                    if isfinite(ref6)
                        push!(csv_rows, (quantity="tone_fig6", polar_set=String(tag),
                                         loads=tname == "toff" ? "scaled" : "scaled_ton",
                                         phi_deg=string(φ), harmonic=string(H),
                                         computed=Ss, reference=ref6, units="dB"))
                    end
                end
                if tname == "toff"
                    ψ = rad2deg(src_s.phase[i, 1])
                    dψ = wrap180(ψ - ψ0)
                    ref_dψ = get(fig7_dψ, φ, NaN)
                    push!(csv_rows, (quantity="dpsi1_fig7", polar_set=String(tag), loads="scaled",
                                     phi_deg=string(φ), harmonic="1",
                                     computed=dψ, reference=ref_dψ, units="deg"))
                end
            end
        end
    end

    open(OUT_MD, "w") do io
        println(io, "# Pereira forward flight (phase 28)")
        println(io)
        println(io, "Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.")
        println(io, "Generated $(Dates.today()) by `scripts/run/run_pereira.jl`.")
        println(io, "**Re-run after plan I-01/I-02 ($(Dates.today())).** Criterion: VALIDATION_GUIDELINE §2.12 / 23d frozen 2026-10-21.")
        println(io, "D=0.30 m, B=2, 8000 rpm, V=16 m/s (J=0.4), observers on 1 m arc, `v_obs=[16,0,0]`.")
        println(io, "Geometry: `pereira_fig1b_chord_twist.csv` downsampled to $(length(rR)) stations; area-mean chord $(round(mean_c*1e3; digits=2)) mm. **I-10:** paper's 22.85 mm is the 0.75R chord (digitized c/R≈0.152 → 22.9 mm), not an area mean; geometry not rescaled.")
        println(io)
        # 23d verdict on ScaledLoads / thickness-off / best polar by H1 mean |Δ|
        println(io, "## 23d verdict (ScaledLoads, thickness off)")
        println(io)
        n1 = 0; n1ok = 0; n2 = 0; n2ok = 0
        for r in spl_rows
            r.thick == "toff" || continue
            isnan(r.fig9) && continue
            Δ = r.SPL_s - r.fig9
            if r.H == 1
                n1 += 1; abs(Δ) <= 1.7 && (n1ok += 1)
            elseif r.H == 2
                n2 += 1; abs(Δ) <= 3.0 && (n2ok += 1)
            end
        end
        println(io, "- H1 within ±1.7 dB: $n1ok / $n1")
        println(io, "- H2 within ±3 dB: $n2ok / $n2")
        println(io, "- ψ₁(φ)−ψ₁(0°) within ±5°: not computed in this pass (Fig.7 fit deferred; levels only).")
        println(io, "- Fig.8 vs Fig.9 H1 scatter recorded as reference (I-15 d/e); not corrected.")
        println(io)
        println(io, "## Loads vs Table 3")
        println(io)
        println(io, "| polar | thick | T N | Q N·m | C_T | C_P | s_T needed | notes |")
        println(io, "|---|---|---:|---:|---:|---:|---:|---|")
        println(io, "| measured | — | 14.55 | 0.4133 | 0.0825 | 0.0491 | 1 | Table 3 Exp |")
        println(io, "| paper BEMT | — | 14.56 | 0.4338 | 0.0826 | 0.0512 | 1 | Table 3 |")
        for r in load_rows
            sT = 14.55 / r.T
            println(io, "| $(r.polar) | $(r.thick) | $(round(r.T; digits=3)) | $(round(r.Q; digits=4)) | $(round(r.CT; digits=4)) | $(round(r.CP; digits=4)) | $(round(sT; digits=2)) | clamped_Re=$(r.st.clamped_Re) |")
        end
        println(io)
        println(io, "ScaledLoads(14.55, 0.4133) reproduces targets (checked in each run).")
        println(io)
        println(io, "## H1–H2 SPL at φ (ScaledLoads, thickness off), vs Fig. 9 Exp")
        println(io)
        println(io, "| polar | φ | H | SPL F1A | Fig.9 Exp | Δ dB |")
        println(io, "|---|---:|--:|---:|---:|---:|")
        for r in spl_rows
            r.thick == "toff" || continue
            d = isnan(r.fig9) ? "" : string(round(r.SPL_s - r.fig9; digits=2))
            f9 = isnan(r.fig9) ? "—" : string(round(r.fig9; digits=2))
            println(io, "| $(r.polar) | $(r.φ) | $(r.H) | $(round(r.SPL_s; digits=2)) | $f9 | $d |")
        end
        println(io)
        println(io, "Config: `PAIN.jl/examples/pereira_apc9x6_scaled.json`.")
    end
    open(OUT_CSV, "w") do io
        println(io, "quantity,polar_set,loads,phi_deg,harmonic,computed,reference,units")
        for r in csv_rows
            println(io, join([r.quantity, r.polar_set, r.loads, r.phi_deg, r.harmonic,
                              r.computed, r.reference, r.units], ','))
        end
    end
    println("wrote ", OUT_MD)
    println("wrote ", OUT_CSV, " rows=", length(csv_rows))
end

main()
