#!/usr/bin/env julia
# Phase 24c–e: BBN/Wilby circumferential phase, in-plane levels, longitudinal (X-EXTRAP).
# Re-run after I-01/I-02; criteria frozen 23a/23b (VALIDATION_GUIDELINE §2.12, 2026-10-21).
# Rotation sense: clockwise_from_rear / upward at fuselage (I-09); opposite sense not run for verdict.
using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN
using Dates
using Printf

const ROOT = joinpath(@__DIR__, "..", "..")
const D158 = joinpath(ROOT, "data", "NASA_CR-158919")
const D159 = joinpath(ROOT, "data", "NASA_CR-159124")
const OUT_MD = joinpath(ROOT, "docs", "validation_reports", "bbn_phase.md")

const PAIRS_VERDICT = ((4, 3), (5, 3), (4, 5))  # 23a; 5-6 reported only
const PAIRS_REPORT = ((4, 3), (5, 3), (4, 5), (5, 6))
const H_MAX = 7

function wrap180(deg)
    return mod(deg + 180, 360) - 180
end

function load_geometry()
    g = Dict{String,String}()
    for raw in eachline(joinpath(D158, "bbn_geometry.csv"))
        startswith(raw, "#") && continue
        startswith(raw, "quantity") && continue
        p = split(strip(raw), ','; limit=4)
        length(p) >= 2 || continue
        g[p[1]] = p[2]
    end
    return (
        hub_x = parse(Float64, g["hub_x_m"]),
        hub_y = parse(Float64, g["hub_y_m"]),
        hub_lat = parse(Float64, get(g, "hub_lateral_offset_m", g["hub_offset_from_skin_m"])),
        rot = get(g, "rotation_direction", "clockwise_from_rear"),
        blade = get(g, "blade_motion_at_fuselage", "upward"),
    )
end

function load_mics()
    rows = NamedTuple[]
    for raw in eachline(joinpath(D158, "bbn_microphones_fig1.csv"))
        startswith(raw, "#") && continue
        startswith(raw, "location") && continue
        p = split(strip(raw), ',')
        length(p) >= 3 || continue
        loc = tryparse(Int, replace(p[1], r"[^0-9].*" => ""))
        loc === nothing && continue
        x = tryparse(Float64, p[2]); y = tryparse(Float64, p[3])
        (x === nothing || y === nothing) && continue
        push!(rows, (loc=loc, x=x, y=y))
    end
    return rows
end

"""Hub-relative AA observers: +X along fuselage, +Y hub→skin, +Z along Fig.1 y."""
function mic_observers(mics, geom; v_obs=zeros(3))
    obs = Observer[]
    idx = Dict{Int,Int}()
    for m in mics
        # Only exterior mics 1–10 for free-field check
        m.loc > 10 && continue
        x_aa = m.x - geom.hub_x
        y_aa = geom.hub_lat
        z_aa = m.y - geom.hub_y
        push!(obs, Observer([x_aa, y_aa, z_aa], Float64.(collect(v_obs)), "mic$(m.loc)"))
        idx[m.loc] = length(obs)
    end
    return obs, idx
end

function load_phase_wide(path)
    # Returns Dict (mic_a, mic_b, H, run) -> (coh, phase_deg)
    d = Dict{NTuple{4,Any},Tuple{Float64,Float64}}()
    run_cols = nothing
    for raw in eachline(path)
        startswith(raw, "#") && continue
        if startswith(raw, "source") || startswith(raw, "mic")
            hdr = split(lowercase(raw), ',')
            # coh_run4_2600rpm, phase_run4_2600rpm_deg, ...
            run_cols = Tuple[]
            for (i, h) in enumerate(hdr)
                m = match(r"coh_run(\d+)", h)
                m === nothing && continue
                rn = parse(Int, m.captures[1])
                push!(run_cols, (rn, i, i + 1))
            end
            continue
        end
        run_cols === nothing && continue
        p = split(strip(raw), ',')
        length(p) < 5 && continue
        a = parse(Int, p[3]); b = parse(Int, p[4]); H = parse(Int, p[5])
        for (rn, ic, ip) in run_cols
            ic > length(p) && continue
            cs = strip(p[ic]); ps = strip(p[ip])
            (cs == "-" || ps == "-" || isempty(cs) || isempty(ps)) && continue
            coh = tryparse(Float64, cs); ph = tryparse(Float64, ps)
            (coh === nothing || ph === nothing) && continue
            d[(a, b, H, rn)] = (coh, ph)
        end
    end
    return d
end

function load_levels_table3()
    # location -> Dict(run => SPL)
    d = Dict{Int,Dict{Int,Float64}}()
    hdr = nothing
    for raw in eachline(joinpath(D158, "bbn_levels_table3.csv"))
        startswith(raw, "#") && continue
        if startswith(raw, "location")
            hdr = split(raw, ',')
            continue
        end
        hdr === nothing && continue
        p = split(strip(raw), ',')
        loc = tryparse(Int, replace(p[1], r"[^0-9].*" => ""))
        loc === nothing && continue
        dd = Dict{Int,Float64}()
        for (i, h) in enumerate(hdr)
            m = match(r"run(\d+)", lowercase(h))
            m === nothing && continue
            i > length(p) && continue
            v = tryparse(Float64, replace(p[i], r"[^0-9.\-].*" => ""))
            v === nothing && continue
            dd[parse(Int, m.captures[1])] = v
        end
        d[loc] = dd
    end
    return d
end

function load_trace_table8()
    # (pair_str, run) -> m/s
    d = Dict{Tuple{String,Int},Float64}()
    hdr = nothing
    for raw in eachline(joinpath(D158, "bbn_trace_velocity_table8.csv"))
        startswith(raw, "#") && continue
        if startswith(raw, "pair")
            hdr = split(lowercase(raw), ',')
            continue
        end
        hdr === nothing && continue
        p = split(strip(raw), ',')
        pair = p[1]
        for (i, h) in enumerate(hdr)
            m = match(r"run(\d+)", h)
            m === nothing && continue
            i > length(p) && continue
            v = tryparse(Float64, p[i])
            v === nothing && continue
            d[(pair, parse(Int, m.captures[1]))] = v
        end
    end
    return d
end

function rpm_for_run(run)
    # BBN run → nominal rpm from Table 1
    map = Dict(1=>2100, 2=>2400, 3=>2600, 4=>2600, 5=>2100, 6=>2100, 7=>1700, 8=>1700)
    return get(map, run, 2100)
end

function set_rpm!(cfg, rpm)
    p = cfg.propeller
    return (
        propeller = (
            num_blades = p.num_blades,
            tip_radius_m = p.tip_radius_m,
            hub_radius_m = p.hub_radius_m,
            rpm = Float64(rpm),
            thickness_over_chord = p.thickness_over_chord,
            pitch_offset_deg = p.pitch_offset_deg,
            radii_m = collect(p.radii_m),
            chord_m = collect(p.chord_m),
            twist_deg = collect(p.twist_deg),
        ),
        operating_point = cfg.operating_point,
        anopp_table8_calibrate = false,
    )
end

function main()
    geom = load_geometry()
    mics = load_mics()
    phase_data = load_phase_wide(joinpath(D158, "bbn_phase_coherence_CR158919_appendixC.csv"))
    levels = load_levels_table3()
    traces = load_trace_table8()
    tipA = joinpath(@__DIR__, "..", "examples", "bbn_aerocommander_tipA.json")
    tipB = joinpath(@__DIR__, "..", "examples", "bbn_aerocommander_tipB.json")
    tips = (("tipA", tipA), ("tipB", tipB))

    # Static runs used in App. C headers: 4,2,5,7
    static_runs = (4, 2, 5, 7)
    ΩR_note = "R=1.18 m; tip beyond 40 in assumed (24f)"

    rows24c = []
    rows24d = []
    src_cache = Dict{Tuple{String,Int},Any}()

    for (tip, jpath) in tips
        cfg0 = PAIN._load_aircraft_json(jpath)
        for run in static_runs
            rpm = rpm_for_run(run)
            cfg = set_rpm!(cfg0, rpm)
            obs, idx = mic_observers(mics, geom)
            println("24c/d tip=$tip run=$run rpm=$rpm n_obs=$(length(obs))…")
            src = evaluate_propeller_source(cfg, obs; n_harmonics=H_MAX,
                                            num_src_times=64, allow_static=true)
            src_cache[(tip, run)] = (src, idx, rpm)
            Ω = rpm * 2π / 60
            # Circumferential phase residuals
            for (a, b) in PAIRS_REPORT
                haskey(idx, a) && haskey(idx, b) || continue
                ia, ib = idx[a], idx[b]
                for H in 1:H_MAX
                    key = (a, b, H, run)
                    haskey(phase_data, key) || continue
                    coh, φm = phase_data[key]
                    dφ_f1a = wrap180(rad2deg(src.phase[ia, H] - src.phase[ib, H]))
                    # Measured App. C is phase of a relative to b as printed (pair a-b)
                    resid = wrap180(φm - dφ_f1a)
                    tol = H <= 2 ? 15.0 : 35.0
                    within = abs(resid) <= tol
                    flagged = !((a, b) in PAIRS_VERDICT)
                    push!(rows24c, (
                        tip=tip, run=run, pair="$a-$b", H=H, coh=coh,
                        φ_meas=φm, φ_f1a=dφ_f1a, resid=resid, tol=tol,
                        within=within, flagged=flagged,
                    ))
                end
                # Trace-velocity ratio vs Table 8 (circumferential)
                pair_s = "$a-$b"
                # Also try "$b-$a" / common order in table (4-3, 5-3, 5-4)
                for ps in (pair_s, "$b-$a", replace(pair_s, "-" => ""))
                    haskey(traces, (ps, run)) || continue
                    v_meas = traces[(ps, run)]
                    # F1A kinematic estimate: v = Ω · r_mean · (Δφ_rad / (H·B·Δψ_rad)) … use phase slope
                    # Simpler: rigid-body circumferential trace = Ω * r_hub_path; report ratio to measured
                    r_mean = 0.5 * (hypot(obs[ia].x[2], obs[ia].x[3]) + hypot(obs[ib].x[2], obs[ib].x[3]))
                    v_rigid = Ω * r_mean
                    ratio_meas = v_meas / v_rigid
                    # From F1A Δφ at H1: v_tr ≈ Ω r * (Δφ_F1A / (B Δψ)) with Δψ from geometry
                    ψa = atan(obs[ia].x[3], obs[ia].x[2])
                    ψb = atan(obs[ib].x[3], obs[ib].x[2])
                    Δψ = abs(wrap180(rad2deg(ψa - ψb))) * π / 180
                    dφ1 = abs(src.phase[ia, 1] - src.phase[ib, 1])
                    dφ1 = min(dφ1, 2π - dφ1)
                    v_f1a = Δψ > 0 ? Ω * r_mean * (dφ1 / (1 * 3 * Δψ)) : NaN
                    ratio_f1a = v_f1a / v_rigid
                    push!(rows24c, (
                        tip=tip, run=run, pair=ps, H=0, coh=1.0,
                        φ_meas=ratio_meas, φ_f1a=ratio_f1a, resid=ratio_f1a - ratio_meas,
                        tol=0.10, within=abs(ratio_f1a - ratio_meas) <= 0.10, flagged=false,
                    ))
                    break
                end
            end
            # 24d in-plane relative levels vs mic 4
            for loc in (3, 4, 5, 6)
                haskey(idx, loc) && haskey(levels, loc) && haskey(levels[loc], run) || continue
                haskey(levels, 4) && haskey(levels[4], run) || continue
                ia = idx[loc]; i4 = idx[4]
                # Use H1 amplitude as tone proxy for overall blade-passage tone table
                spl_f = 20 * log10(src.amplitude[ia, 1] / 20e-6 + 1e-30)
                spl4_f = 20 * log10(src.amplitude[i4, 1] / 20e-6 + 1e-30)
                d_f = spl_f - spl4_f
                d_m = levels[loc][run] - levels[4][run]
                resid = d_m - d_f
                push!(rows24d, (
                    tip=tip, run=run, loc=loc, d_meas=d_m, d_f1a=d_f, resid=resid,
                    within=abs(resid) <= 3.0,
                ))
            end
        end
    end

    # 24e longitudinal pairs (X-EXTRAP) — sample at static run 4 tip A using Fig.19 freqs near BPF
    rows24e = []
    fig19 = joinpath(D159, "bbn_phase_vs_freq_fig19_longitudinal.csv")
    if isfile(fig19) && haskey(src_cache, ("tipA", 4))
        src, idx, rpm = src_cache[("tipA", 4)]
        bpf = 3 * rpm / 60
        for raw in eachline(fig19)
            startswith(raw, "#") && continue
            startswith(raw, "figure") && continue
            p = split(strip(raw), ',')
            length(p) >= 6 || continue
            pair = p[3]; f = parse(Float64, p[5]); φ = parse(Float64, p[6])
            # Nearest harmonic
            H = clamp(round(Int, f / bpf), 1, H_MAX)
            m = match(r"(\d+)-(\d+)", pair)
            m === nothing && continue
            a = parse(Int, m.captures[1]); b = parse(Int, m.captures[2])
            haskey(idx, a) && haskey(idx, b) || continue
            dφ = wrap180(rad2deg(src.phase[idx[a], H] - src.phase[idx[b], H]))
            push!(rows24e, (pair=pair, f=f, H=H, φ_meas_rad=φ, φ_f1a_deg=dφ,
                            resid=wrap180(rad2deg(φ) - dφ)))
        end
    end

    # 23a verdict
    verdict_rows = filter(r -> r.H >= 1 && !r.flagged && r.coh >= 0.15, rows24c)
    n_ok = count(r -> r.within, verdict_rows)
    n_tot = length(verdict_rows)
    frac = n_tot == 0 ? 0.0 : n_ok / n_tot
    pass23a = frac >= 0.80

    open(OUT_MD, "w") do io
        println(io, "# BBN / Wilby phase check (phase 24)")
        println(io)
        println(io, "Generated $(Dates.today()) by `scripts/run_bbn_phase.jl`.")
        println(io, "**Re-run after plan I-01/I-02/I-09 ($(Dates.today())).** Criteria: VALIDATION_GUIDELINE §2.12 / 23a–23b frozen 2026-10-21.")
        println(io)
        println(io, "## Geometry and sense (I-09)")
        println(io)
        println(io, "- hub_x_m=$(geom.hub_x), hub_y_m=$(geom.hub_y), hub_lateral_offset_m=$(geom.hub_lat)")
        println(io, "- rotation_direction=$(geom.rot); blade_motion_at_fuselage=$(geom.blade)")
        println(io, "- AA observers: X=x_fuselage, Y=hub→skin ($(geom.hub_lat) m), Z=y_fig1−hub_y; `positive_x_rotation=true` (package default). Opposite sense not run for the verdict.")
        println(io, "- $ΩR_note")
        println(io)
        println(io, "## 24b V-UNIT")
        println(io)
        println(io, "Covered by `Pkg.test()` set \"BBN kinematics (24b, V-UNIT)\": Δφ = m·B·Δψ within 0.5° (23a′); reverse observer sense flips sign.")
        println(io)
        println(io, "## 24c Circumferential phase (23a)")
        println(io)
        @printf(io, "Rows with coh ≥ 0.15 on pairs 4-3, 5-3, 4-5: **%d / %d** within tolerance (%.0f%%; need ≥80%%) → **%s**.\n\n",
                n_ok, n_tot, 100 * frac, pass23a ? "PASS" : "FAIL")
        println(io, "| tip | run | pair | H | coh | φ_meas° | φ_F1A° | resid° | tol° | within |")
        println(io, "|---|--:|---|--:|---:|---:|---:|---:|---:|:---:|")
        for r in rows24c
            r.H >= 1 || continue
            r.flagged && continue
            @printf(io, "| %s | %d | %s | %d | %.2f | %.1f | %.1f | %.1f | %.0f | %s |\n",
                    r.tip, r.run, r.pair, r.H, r.coh, r.φ_meas, r.φ_f1a, r.resid, r.tol,
                    r.within ? "Y" : "N")
        end
        println(io)
        println(io, "### Trace-velocity ratio (23a, ±0.10 of measured ratio)")
        println(io)
        println(io, "| tip | run | pair | ratio_meas | ratio_F1A | Δ | within |")
        println(io, "|---|--:|---|---:|---:|---:|:---:|")
        for r in rows24c
            r.H == 0 || continue
            @printf(io, "| %s | %d | %s | %.3f | %.3f | %.3f | %s |\n",
                    r.tip, r.run, r.pair, r.φ_meas, r.φ_f1a, r.resid, r.within ? "Y" : "N")
        end
        println(io)
        println(io, "## 24d In-plane relative levels (23b, X-EXTRAP)")
        println(io)
        println(io, "Relative SPL of mics 3–6 vs mic 4; F1A from H1 amplitude; assumed blade. Tolerance ±3 dB.")
        println(io)
        println(io, "| tip | run | loc | Δmeas dB | ΔF1A dB | resid dB | within |")
        println(io, "|---|--:|--:|---:|---:|---:|:---:|")
        for r in rows24d
            @printf(io, "| %s | %d | %d | %.1f | %.1f | %.1f | %s |\n",
                    r.tip, r.run, r.loc, r.d_meas, r.d_f1a, r.resid, r.within ? "Y" : "N")
        end
        n4 = count(r -> r.within, rows24d)
        println(io)
        println(io, "Within ±3 dB: $n4 / $(length(rows24d)) (reported X-EXTRAP).")
        println(io)
        println(io, "## 24e Longitudinal pairs (X-EXTRAP)")
        println(io)
        println(io, "Fig. 19 digitized phase vs F1A at nearest BPF harmonic (tipA, run 4). Not a validation claim.")
        println(io)
        if isempty(rows24e)
            println(io, "(no rows — Fig.19 missing or mic index gap)")
        else
            println(io, "| pair | f Hz | H | φ_meas rad | φ_F1A° | resid° |")
            println(io, "|---|---:|--:|---:|---:|---:|")
            for r in rows24e[1:min(end, 40)]
                @printf(io, "| %s | %.0f | %d | %.3f | %.1f | %.1f |\n",
                        r.pair, r.f, r.H, r.φ_meas_rad, r.φ_f1a_deg, r.resid)
            end
        end
        println(io)
        println(io, "## 24f Tip geometry")
        println(io)
        println(io, "Hartzell tip beyond 40 in **not found**; tipA = linear taper to 0.5× chord, tipB = elliptic (assumed). Every 24e/24c tip-sensitivity row is labelled assumed.")
        println(io)
        println(io, "What this does **not** show: fuselage scattering/reflection (V-ASSUMED); general phase correctness off the rotation-plane circumferential set.")
    end
    println("wrote $OUT_MD  23a=$(pass23a ? "PASS" : "FAIL") ($n_ok/$n_tot)")
end

main()
