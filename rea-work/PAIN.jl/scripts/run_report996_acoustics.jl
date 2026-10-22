#!/usr/bin/env julia
# Phase 27: F1A vs Report 996 pressures (expanded matrix). Verdict against frozen 23c (2026-10-21).
using PAIN
using Dates

const ROOT = joinpath(@__DIR__, "..", "..")
const DATA = joinpath(ROOT, "data", "report996")
const BF = joinpath(DATA, "naca_4-5-08-03", "blade_form.csv")
const POLAR = joinpath(DATA, "polars_forced_merged.json")
const SCALES = joinpath(DATA, "scale_factors.csv")
const DIG = joinpath(DATA, "tr996_fig12_13a_14_digitized.csv")
const L51 = joinpath(DATA, "naca_4-5-08-03", "measured", "noise", "naca_rm_l51c27_table1_thrust_torque.csv")
const OUT_MD = joinpath(ROOT, "docs", "validation_reports", "report996_acoustics.md")
const OUT_CSV = joinpath(DATA, "f1a_results.csv")

function rpm_from_Mt(Mt; D=1.2192, a=340.3)
    return Mt * a * 60 / (π * D)
end

"""I-08: RM L51C27 Table I → C_T, C_Q on the 47-in. diameter, applied to the 4-ft model at the same M_t."""
function l51c27_scaled_loads(Mt; beta75=15.0, ρ=1.225, a=340.3, D_model=1.2192)
    D47 = 47 * 0.0254
    T_lb = NaN; Q_lbft = NaN
    for raw in eachline(L51)
        startswith(raw, "report") && continue
        startswith(raw, "#") && continue
        p = split(strip(raw), ',')
        length(p) >= 8 || continue
        parse(Float64, p[5]) == beta75 || continue
        abs(parse(Float64, p[6]) - Mt) < 0.02 || continue
        isempty(p[7]) && continue
        T_lb = parse(Float64, p[7])
        Q_lbft = parse(Float64, p[8])
        break
    end
    (isfinite(T_lb) && isfinite(Q_lbft)) || return nothing
    T_N = T_lb * 4.448221615
    Q_Nm = Q_lbft * 1.3558179483314004
    n47 = Mt * a / (π * D47)
    CT = T_N / (ρ * n47^2 * D47^4)
    CQ = Q_Nm / (ρ * n47^2 * D47^5)
    n = Mt * a / (π * D_model)
    T_tgt = CT * ρ * n^2 * D_model^4
    Q_tgt = CQ * ρ * n^2 * D_model^5
    return (T_tgt=T_tgt, Q_tgt=Q_tgt, CT=CT, CQ=CQ, T_lb=T_lb, Q_lbft=Q_lbft)
end

function make_cfg(; beta75, Mt, B)
    g = blade_form_geometry(BF; D=1.2192, beta75_target_deg=Float64(beta75))
    return (
        propeller = (
            num_blades = B,
            tip_radius_m = g.R,
            hub_radius_m = g.radii_m[1],
            rpm = rpm_from_Mt(Mt),
            thickness_over_chord = 0.0,
            pitch_offset_deg = 0.0,
            radii_m = collect(g.radii_m),
            chord_m = collect(g.chord_m),
            twist_deg = collect(g.twist_deg),
        ),
        operating_point = (forward_speed_mps = 0.0, rho_kg_m3 = 1.225, c0_mps = 340.3),
        anopp_table8_calibrate = false,
    )
end

function load_scale(polar_set, beta75, Mt, B, source)
    isfile(SCALES) || return (NaN, NaN)
    for raw in eachline(SCALES)
        startswith(raw, "case") && continue
        p = split(strip(raw), ',')
        length(p) >= 16 || continue
        String(p[2]) == String(polar_set) || continue
        parse(Float64, p[3]) == beta75 || continue
        parse(Float64, p[4]) == Mt || continue
        parse(Int, p[5]) == B || continue
        String(p[16]) == source || continue
        sT = try parse(Float64, p[14]) catch; NaN end
        sQ = try parse(Float64, p[15]) catch; NaN end
        return (sT, sQ)
    end
    return (NaN, NaN)
end

function load_digitized()
    rows = NamedTuple[]
    isfile(DIG) || return rows
    for raw in eachline(DIG)
        startswith(raw, "figure") && continue
        startswith(raw, "#") && continue
        p = split(strip(raw), ',')
        length(p) >= 10 || continue
        push!(rows, (
            figure=parse(Int, p[1]), panel=p[2], quantity=p[3],
            M_t=parse(Float64, p[4]), beta=parse(Float64, p[5]),
            x_over_D=parse(Float64, p[6]), mB=parse(Int, p[7]),
            value=parse(Float64, p[8]), units=p[9],
            in_scope=(length(p) < 11 || lowercase(p[11]) == "true"),
        ))
    end
    return rows
end

function push_result!(results; figure, case, polar_set, loads, x_over_D, d_over_D,
                      harmonic, A_Pa, phase_rad, p_rms, p_c, meas=NaN, residual_pct=NaN)
    # A_Pa = cosine-peak Fourier amplitude; measured Report 996 pressures are rms (p.10).
    A_rms = isnan(A_Pa) ? NaN : A_Pa / sqrt(2)
    push!(results, (
        figure=figure, case=case, polar_set=polar_set, loads=loads,
        x_over_D=x_over_D, d_over_D=d_over_D, harmonic=harmonic,
        A_Pa=A_Pa, A_rms_Pa=A_rms, phase_rad=phase_rad, p_rms_total_Pa=p_rms, p_c=p_c,
        meas_dyne_cm2=meas, residual_pct=residual_pct,
    ))
end

function main()
    af_p, _ = load_polar_set(POLAR; set=:primary)
    af_b, _ = load_polar_set(POLAR; set=:bracket)
    ρ, a_sound = 1.225, 340.3
    dig = load_digitized()
    results = []

    # --- Fig. 14: B=2, β=10°, d/D=0.083, x/D=-0.125, mB=2,4,6 vs M_t ---
    println("Fig.14 …")
    for Mt in (0.45, 0.60, 0.75, 0.90)
        for (pset, af) in ((:primary, af_p), (:bracket, af_b))
            cfg = make_cfg(; beta75=10.0, Mt=Mt, B=2)
            R = cfg.propeller.tip_radius_m; D = 2R
            obs = hub_observers(R, D; x_over_D=[-0.125], d_over_D=0.083, x_sign=-1.0)
            src0 = evaluate_propeller_source(cfg, obs; n_harmonics=8, num_src_times=64,
                                             af=af, allow_static=true)
            sT, sQ = load_scale(pset, 10.0, Mt, 2, "Fig14_table")
            src = src0
            loads_tag = "ccblade"
            if isfinite(sT) && isfinite(sQ)
                src = evaluate_propeller_source(cfg, obs; n_harmonics=8, num_src_times=64,
                    af=af, allow_static=true, loads=ScaledLoads(src0.T * sT, src0.Q * sQ))
                loads_tag = "scaled"
            end
            prms = total_rms(src.amplitude[1, :])
            pc = pressure_coefficient_pc(prms; ρ=ρ, M_t=Mt, a=a_sound)
            for (H, mB) in ((1, 2), (2, 4), (3, 6))
                A = src.amplitude[1, H]
                # Measured Report 996 amplitudes are rms (p.10); compare A/√2.
                A_dyne = pa_to_dyne_cm2(A / sqrt(2))
                meas = NaN
                for d in dig
                    d.figure == 14 && d.in_scope && abs(d.M_t - Mt) < 0.02 && d.mB == mB || continue
                    meas = d.value; break
                end
                res = isnan(meas) ? NaN : 100 * (A_dyne - meas) / meas
                push_result!(results; figure="fig14", case="beta10_B2_Mt$(Mt)",
                    polar_set=String(pset), loads=loads_tag, x_over_D=-0.125, d_over_D=0.083,
                    harmonic=mB, A_Pa=A, phase_rad=src.phase[1, H], p_rms=prms, p_c=pc,
                    meas=meas, residual_pct=res)
            end
        end
    end

    # --- Fig. 13a: β=15°, M_t=0.75, d/D=0.083, first harmonic vs x/D ---
    # I-08: scale with RM L51C27 Table I coefficients (47-in → 4-ft), not Fig.14 β=10° proxy.
    println("Fig.13a …")
    Mt13, beta75_13 = 0.75, 15.0
    l51 = l51c27_scaled_loads(Mt13; beta75=beta75_13)
    xDs = [-0.5, -0.25, -0.125, 0.0, 0.125, 0.25, 0.5]
    for (pset, af) in ((:primary, af_p), (:bracket, af_b))
        cfg = make_cfg(; beta75=beta75_13, Mt=Mt13, B=2)
        R = cfg.propeller.tip_radius_m; D = 2R
        obs = hub_observers(R, D; x_over_D=xDs, d_over_D=0.083, x_sign=-1.0)
        src0 = evaluate_propeller_source(cfg, obs; n_harmonics=4, num_src_times=64,
                                         af=af, allow_static=true)
        src = src0; loads_tag = "ccblade"
        if l51 !== nothing
            src = evaluate_propeller_source(cfg, obs; n_harmonics=4, num_src_times=64,
                af=af, allow_static=true, loads=ScaledLoads(l51.T_tgt, l51.Q_tgt))
            loads_tag = "scaled_RM_L51C27"
        end
        for (i, xd) in enumerate(xDs)
            A = src.amplitude[i, 1]
            A_dyne = pa_to_dyne_cm2(A / sqrt(2))  # rms vs Report 996 measured rms
            meas = NaN
            for d in dig
                d.figure == 13 && d.in_scope || continue
                abs(d.x_over_D - xd) < 0.05 || continue
                meas = d.value; break
            end
            res = isnan(meas) ? NaN : 100 * (A_dyne - meas) / meas
            push_result!(results; figure="fig13a", case="beta15_Mt075",
                polar_set=String(pset), loads=loads_tag, x_over_D=xd, d_over_D=0.083,
                harmonic=2, A_Pa=A, phase_rad=src.phase[i, 1], p_rms=NaN, p_c=NaN,
                meas=meas, residual_pct=res)
        end
    end

    # --- Fig. 12(a)/(b): β=10°, d/D=0.083, mB=2,4,6,8 vs x/D at M_t=0.75 and 0.90 ---
    println("Fig.12 …")
    xDs12 = [-0.25, -0.125, 0.0, 0.125, 0.25]
    for (Mt, ftag) in ((0.75, "fig12a"), (0.90, "fig12b"))
        for (pset, af) in ((:primary, af_p),)
            cfg = make_cfg(; beta75=10.0, Mt=Mt, B=2)
            R = cfg.propeller.tip_radius_m; D = 2R
            obs = hub_observers(R, D; x_over_D=xDs12, d_over_D=0.083, x_sign=-1.0)
            src0 = evaluate_propeller_source(cfg, obs; n_harmonics=8, num_src_times=64,
                                             af=af, allow_static=true)
            sT, sQ = load_scale(pset, 10.0, Mt, 2, "Fig14_table")
            src = src0; loads_tag = "ccblade"
            if isfinite(sT) && isfinite(sQ)
                src = evaluate_propeller_source(cfg, obs; n_harmonics=8, num_src_times=64,
                    af=af, allow_static=true, loads=ScaledLoads(src0.T * sT, src0.Q * sQ))
                loads_tag = "scaled"
            end
            for (i, xd) in enumerate(xDs12)
                for (H, mB) in ((1, 2), (2, 4), (3, 6), (4, 8))
                    A = src.amplitude[i, H]
                    A_dyne = pa_to_dyne_cm2(A / sqrt(2))  # rms vs Report 996 measured rms
                    meas = NaN
                    for d in dig
                        d.figure == 12 && d.in_scope || continue
                        abs(d.M_t - Mt) < 0.02 || continue
                        abs(d.x_over_D - xd) < 0.03 || continue
                        d.mB == mB || continue
                        meas = d.value; break
                    end
                    res = isnan(meas) ? NaN : 100 * (A_dyne - meas) / meas
                    push_result!(results; figure=ftag, case="beta10_Mt$(Mt)",
                        polar_set=String(pset), loads=loads_tag, x_over_D=xd, d_over_D=0.083,
                        harmonic=mB, A_Pa=A, phase_rad=src.phase[i, H], p_rms=NaN, p_c=NaN,
                        meas=meas, residual_pct=res)
                end
            end
        end
    end

    # --- Fig. 7 smoke: β=15°, Mt=0.60, p_c/CP shape at selected x/D ---
    println("Fig.7 …")
    Mt, beta75, CP_leg = 0.60, 15.0, 0.0424
    xDs7 = [-0.5, -0.25, -0.125, 0.0, 0.125, 0.25, 0.5]
    for (pset, af) in ((:primary, af_p), (:bracket, af_b))
        cfg = make_cfg(; beta75, Mt, B=2)
        R = cfg.propeller.tip_radius_m; D = 2R
        obs = hub_observers(R, D; x_over_D=xDs7, d_over_D=0.083, x_sign=-1.0)
        src0 = evaluate_propeller_source(cfg, obs; n_harmonics=10, num_src_times=64,
                                         af=af, allow_static=true)
        sT, sQ = load_scale(pset, 10.0, Mt, 2, "RM_L8H25a")
        src = src0; loads_tag = "ccblade"
        if isfinite(sT) && isfinite(sQ)
            src = evaluate_propeller_source(cfg, obs; n_harmonics=10, num_src_times=64,
                af=af, allow_static=true, loads=ScaledLoads(src0.T * sT, src0.Q * sQ))
            loads_tag = "scaled"
        end
        for (i, xd) in enumerate(xDs7)
            prms = total_rms(src.amplitude[i, :])
            pc = pressure_coefficient_pc(prms; ρ=ρ, M_t=Mt, a=a_sound)
            push_result!(results; figure="fig7", case="beta15_Mt060",
                polar_set=String(pset), loads=loads_tag, x_over_D=xd, d_over_D=0.083,
                harmonic=0, A_Pa=NaN, phase_rad=NaN, p_rms=prms, p_c=pc / CP_leg,
                meas=NaN, residual_pct=NaN)
        end
    end

    # --- Fig. 6 informational: B=4 tip-clearance ratios (no measured B=4 T/Q) ---
    println("Fig.6 …")
    Mt, beta75 = 0.60, 10.0
    xDs6 = [-0.25, -0.125, 0.0, 0.125, 0.25]
    dDs = [0.042, 0.083, 0.167, 0.333]
    cfg = make_cfg(; beta75, Mt, B=4)
    R = cfg.propeller.tip_radius_m; D = 2R
    fig6_prms = Float64[]
    for dD in dDs
        obs = hub_observers(R, D; x_over_D=xDs6, d_over_D=dD, x_sign=-1.0)
        src = evaluate_propeller_source(cfg, obs; n_harmonics=8, num_src_times=64,
                                        af=af_p, allow_static=true)
        push!(fig6_prms, maximum(total_rms(src.amplitude[i, :]) for i in eachindex(xDs6)))
    end
    ref6 = fig6_prms[findfirst(==(0.083), dDs)]
    for (dD, prms_max) in zip(dDs, fig6_prms)
        push_result!(results; figure="fig6", case="B4_beta10_Mt060",
            polar_set="primary", loads="ccblade_unscaled", x_over_D=0.0, d_over_D=dD,
            harmonic=0, A_Pa=NaN, phase_rad=NaN, p_rms=prms_max, p_c=prms_max / ref6,
            meas=NaN, residual_pct=NaN)
    end

    # --- 25k: behind vs ahead asymmetry at Fig.13a points ---
    behind = filter(r -> r.figure == "fig13a" && r.polar_set == "primary" && r.loads != "ccblade" && r.x_over_D ≈ -0.125, results)
    ahead = filter(r -> r.figure == "fig13a" && r.polar_set == "primary" && r.loads != "ccblade" && r.x_over_D ≈ 0.125, results)
    asym_note = "n/a"
    if !isempty(behind) && !isempty(ahead)
        asym_note = "A_rms(-0.125)=$(round(pa_to_dyne_cm2(behind[1].A_rms_Pa); digits=1)) vs A_rms(+0.125)=$(round(pa_to_dyne_cm2(ahead[1].A_rms_Pa); digits=1)) dyne/cm² (meas ~1328 vs ~1009); behind>ahead=$(behind[1].A_Pa > ahead[1].A_Pa)"
    end

    # --- Page-12 phase: Δφ between equidistant ahead/behind (candidates x/D=±0.125) ---
    # Report: 155° measured, 165° Eq.(2) at M_t=0.75. Use Fig.13a primary scaled phases.
    phase_note = "n/a"
    if !isempty(behind) && !isempty(ahead)
        dφ = abs(behind[1].phase_rad - ahead[1].phase_rad)
        dφ = min(dφ, 2π - dφ)  # principal
        dφ_deg = dφ * 180 / π
        phase_note = "Δφ(|x/D|=0.125) F1A=$(round(dφ_deg; digits=1))° vs report measured 155° / Eq.(2) 165° (candidates ±0.125; exact stations not stated)"
    end

    open(OUT_CSV, "w") do io
        println(io, "figure,case,polar_set,loads,x_over_D,d_over_D,harmonic,A_Pa,A_rms_Pa,phase_rad,p_rms_total_Pa,p_c,meas_dyne_cm2,residual_pct")
        for r in results
            println(io, join([r.figure, r.case, r.polar_set, r.loads, r.x_over_D, r.d_over_D,
                r.harmonic, r.A_Pa, r.A_rms_Pa, r.phase_rad, r.p_rms_total_Pa, r.p_c, r.meas_dyne_cm2, r.residual_pct], ','))
        end
    end

    open(OUT_MD, "w") do io
        println(io, "# Report 996 Acoustics (phase 27)")
        println(io)
        println(io, "Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.")
        println(io, "Generated $(Dates.today()) by `scripts/run_report996_acoustics.jl`.")
        println(io, "**Re-run after plan I-01/I-02/I-08 ($(Dates.today())).** Criterion: VALIDATION_GUIDELINE §2.12 / 23c frozen 2026-10-21.")
        println(io, "x_sign=−1 (report behind → AA +X). Thickness off. Harmonic A vs measured: A_rms = A_Pa/√2 (Report 996 p.10 rms).")
        println(io)
        if l51 !== nothing
            println(io, "## I-08 Fig. 13(a) load scale")
            println(io)
            println(io, "RM L51C27 Table I (47-in., β₇₅=15°, M_t=$(Mt13)): T=$(l51.T_lb) lb, Q=$(l51.Q_lbft) lb·ft → C_T=$(round(l51.CT; digits=4)), C_Q=$(round(l51.CQ; digits=5)); applied to 4-ft model: T_tgt=$(round(l51.T_tgt; digits=1)) N, Q_tgt=$(round(l51.Q_tgt; digits=1)) N·m. Tag `scaled_RM_L51C27` (replaces void fig14proxy).")
            println(io)
        end
        println(io, "## x-sign / asymmetry (25k)")
        println(io)
        println(io, asym_note)
        println(io)
        println(io, "## Page-12 phase (one measured value)")
        println(io)
        println(io, phase_note)
        # 23c: page-12 phase within ±15° of measured 155°
        if !isempty(behind) && !isempty(ahead)
            dφ = abs(behind[1].phase_rad - ahead[1].phase_rad)
            dφ = min(dφ, 2π - dφ)
            dφ_deg = dφ * 180 / π
            phase_ok = abs(dφ_deg - 155.0) <= 15.0
            println(io)
            println(io, "23c page-12 phase: |Δφ − 155°| = $(round(abs(dφ_deg - 155); digits=1))° → $(phase_ok ? "PASS" : "FAIL") (±15°).")
        end
        println(io)
        println(io, "## Fig. 14 (scaled to table C_T/C_Q) — residual % vs digitized")
        println(io)
        println(io, "| polar | loads | case | mB | A F1A dyne/cm² | meas | residual % | residual dB |")
        println(io, "|---|---|---|--:|---:|---:|---:|---:|")
        n_in = 0; n_ok = 0
        for r in results
            r.figure == "fig14" || continue
            rdb = isnan(r.residual_pct) ? NaN : 20 * log10(max(1 + r.residual_pct / 100, 1e-30))
            println(io, "| $(r.polar_set) | $(r.loads) | $(r.case) | $(r.harmonic) | $(round(pa_to_dyne_cm2(r.A_rms_Pa); digits=1)) | $(r.meas_dyne_cm2) | $(round(r.residual_pct; digits=1)) | $(round(rdb; digits=2)) |")
            if r.loads == "scaled" && isfinite(rdb)
                n_in += 1
                abs(rdb) <= 2.0 && (n_ok += 1)
            end
        end
        frac14 = n_in == 0 ? NaN : n_ok / n_in
        println(io)
        println(io, "23c scaled pressure (Fig.14 sample): $(n_ok)/$(n_in) within ±2 dB ($(round(100 * frac14; digits=0))%; need ≥75%).")
        println(io)
        println(io, "## Fig. 13(a) first harmonic vs x/D (M_t=0.75, β=15°)")
        println(io)
        println(io, "| polar | loads | x/D | A F1A | meas | residual % | residual dB |")
        println(io, "|---|---|---:|---:|---:|---:|---:|")
        n13 = 0; n13ok = 0
        for r in results
            r.figure == "fig13a" || continue
            rdb = isnan(r.residual_pct) ? NaN : 20 * log10(max(1 + r.residual_pct / 100, 1e-30))
            println(io, "| $(r.polar_set) | $(r.loads) | $(r.x_over_D) | $(round(pa_to_dyne_cm2(r.A_rms_Pa); digits=1)) | $(r.meas_dyne_cm2) | $(round(r.residual_pct; digits=1)) | $(round(rdb; digits=2)) |")
            if startswith(r.loads, "scaled") && isfinite(rdb)
                n13 += 1
                abs(rdb) <= 2.0 && (n13ok += 1)
            end
        end
        println(io)
        println(io, "23c scaled pressure (Fig.13a sample): $(n13ok)/$(n13) within ±2 dB.")
        println(io)
        println(io, "## Fig. 12(a)/(b) harmonics vs x/D (β=10°, primary/scaled)")
        println(io)
        println(io, "| fig | loads | x/D | mB | A F1A | meas | residual % |")
        println(io, "|---|---|---:|--:|---:|---:|---:|")
        for r in results
            startswith(r.figure, "fig12") || continue
            println(io, "| $(r.figure) | $(r.loads) | $(r.x_over_D) | $(r.harmonic) | $(round(pa_to_dyne_cm2(r.A_rms_Pa); digits=1)) | $(r.meas_dyne_cm2) | $(round(r.residual_pct; digits=1)) |")
        end
        println(io)
        println(io, "## Fig. 7 p_c/C_P (β=15°, M_t=0.60, C_P legend=0.0424)")
        println(io)
        println(io, "| polar | loads | x/D | p_c/C_P |")
        println(io, "|---|---|---:|---:|")
        for r in results
            r.figure == "fig7" || continue
            println(io, "| $(r.polar_set) | $(r.loads) | $(r.x_over_D) | $(round(r.p_c; digits=4)) |")
        end
        println(io)
        println(io, "## Fig. 6 tip-clearance ratios (B=4, unscaled; ratio of max total-rms to d/D=0.083)")
        println(io)
        println(io, "| d/D | p_rms max Pa | ratio to 0.083 |")
        println(io, "|---:|---:|---:|")
        for r in results
            r.figure == "fig6" || continue
            println(io, "| $(r.d_over_D) | $(round(r.p_rms_total_Pa; digits=1)) | $(round(r.p_c; digits=3)) |")
        end
        println(io)
        println(io, "CSV: `data/report996/f1a_results.csv`.")
    end
    println("wrote ", OUT_CSV, " rows=", length(results))
    println("asym: ", asym_note)
end

main()
