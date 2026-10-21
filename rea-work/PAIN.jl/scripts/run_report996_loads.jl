#!/usr/bin/env julia
# Phase 26: CCBlade C_T / C_P vs Report 996 static targets; write scale_factors.csv.
# Pass/fail vs 23c stays [AUTHOR]; this script records numbers only.
using PAIN
using JSON3
using Dates

const ROOT = joinpath(@__DIR__, "..", "..")
const DATA = joinpath(ROOT, "data", "report996")
const BF = joinpath(DATA, "naca_4-5-08-03", "blade_form.csv")
const POLAR = joinpath(DATA, "polars_forced_merged.json")
const OUT_MD = joinpath(ROOT, "docs", "validation_reports", "report996_loads.md")
const OUT_CSV = joinpath(DATA, "scale_factors.csv")

function rpm_from_Mt(Mt; D=1.2192, a=340.3)
    return Mt * a * 60 / (π * D)
end

function make_cfg(; beta75, Mt, B, D=1.2192)
    g = blade_form_geometry(BF; D=D, beta75_target_deg=Float64(beta75))
    return (
        propeller = (
            num_blades = B,
            tip_radius_m = g.R,
            hub_radius_m = g.radii_m[1],
            rpm = rpm_from_Mt(Mt; D=D),
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

# Measured C_T / C_P targets (phase 26 list). Sources named per row.
# RM L8H25a / Fig.7 legend / Fig.14 table — values from IMPLEMENTATION_PLAN.
const CASES = [
    # beta75, Mt, B, CT_meas, CP_meas, source
    (10.0, 0.45, 2, 0.0706, 0.0221, "RM_L8H25a"),
    (10.0, 0.60, 2, 0.0718, 0.0230, "RM_L8H25a"),
    (15.0, 0.45, 2, NaN, NaN, "RM_L8H25a"),  # filled if CSV has it
    (15.0, 0.60, 2, NaN, 0.0424, "Fig7_legend_CP"),
    (20.0, 0.60, 2, 0.1048, 0.0739, "RM_L8H25a"),
    (8.0, 0.60, 2, NaN, 0.0195, "Fig7_legend_CP"),
    (10.0, 0.45, 2, 0.070, 2π * 0.0037, "Fig14_table"),
    (10.0, 0.60, 2, 0.072, 2π * 0.0042, "Fig14_table"),
    (10.0, 0.75, 2, 0.075, 2π * 0.0044, "Fig14_table"),
    (10.0, 0.90, 2, 0.080, 2π * 0.0051, "Fig14_table"),
]

function run_one(af, polar_set, beta75, Mt, B)
    cfg = make_cfg(; beta75, Mt, B)
    # Dummy observer (loads only)
    R = cfg.propeller.tip_radius_m
    D = 2R
    obs = hub_observers(R, D; x_over_D=[0.0], d_over_D=0.083, x_sign=-1.0)
    src = evaluate_propeller_source(cfg, obs; n_harmonics=1, num_src_times=16,
                                    af=af, allow_static=true)
    return src
end

function main()
    af_p, st_p = load_polar_set(POLAR; set=:primary)
    af_b, st_b = load_polar_set(POLAR; set=:bracket)
    rows = []
    for (beta75, Mt, B, CT_m, CP_m, source) in CASES
        for (pset, af) in ((:primary, af_p), (:bracket, af_b))
            println("case β=$(beta75) Mt=$(Mt) B=$(B) polar=$(pset)…")
            src = run_one(af, pset, beta75, Mt, B)
            ρ = 1.225
            n = src.echo.rpm / 60
            D = 2 * src.echo.Rtip
            T_meas = isnan(CT_m) ? NaN : CT_m * ρ * n^2 * D^4
            # C_P = P/(ρ n³ D⁵); Q = P/Ω = P/(2π n) → C_Q = C_P/(2π); Q = C_Q ρ n² D⁵
            Q_meas = isnan(CP_m) ? NaN : (CP_m / (2π)) * ρ * n^2 * D^5
            s_T = isnan(T_meas) || src.T == 0 ? NaN : T_meas / src.T
            s_Q = isnan(Q_meas) || src.Q == 0 ? NaN : Q_meas / src.Q
            push!(rows, (
                polar_set=String(pset), beta75_deg=beta75, M_t=Mt, B=B,
                T_ccb_N=src.T, Q_ccb_Nm=src.Q, CT_ccb=src.CT, CP_ccb=src.CP,
                T_meas_N=T_meas, Q_meas_Nm=Q_meas, CT_meas=CT_m, CP_meas=CP_m,
                s_T=s_T, s_Q=s_Q, source_of_measured=source,
            ))
        end
    end

    open(OUT_CSV, "w") do io
        println(io, "case,polar_set,beta75_deg,M_t,B,T_ccb_N,Q_ccb_Nm,CT_ccb,CP_ccb,T_meas_N,Q_meas_Nm,CT_meas,CP_meas,s_T,s_Q,source_of_measured")
        for (i, r) in enumerate(rows)
            println(io, join([
                i, r.polar_set, r.beta75_deg, r.M_t, r.B,
                r.T_ccb_N, r.Q_ccb_Nm, r.CT_ccb, r.CP_ccb,
                r.T_meas_N, r.Q_meas_Nm, r.CT_meas, r.CP_meas,
                r.s_T, r.s_Q, r.source_of_measured,
            ], ','))
        end
    end

    open(OUT_MD, "w") do io
        println(io, "# Report 996 CCBlade loads (phase 26)")
        println(io)
        println(io, "Generated $(Dates.today()) by `scripts/run_report996_loads.jl`. Static V=0, `allow_static=true`.")
        println(io, "Polars: `polars_forced_merged.json` primary + bracket. **Pass/fail waits on 23c [AUTHOR].**")
        println(io)
        println(io, "| polar | β₇₅ | M_t | B | C_T ccb | C_P ccb | C_T meas | C_P meas | s_T | s_Q | source |")
        println(io, "|---|---:|---:|--:|---:|---:|---:|---:|---:|---:|---|")
        for r in rows
            println(io, "| $(r.polar_set) | $(r.beta75_deg) | $(r.M_t) | $(r.B) | $(round(r.CT_ccb; digits=4)) | $(round(r.CP_ccb; digits=4)) | $(r.CT_meas) | $(r.CP_meas) | $(round(r.s_T; digits=3)) | $(round(r.s_Q; digits=3)) | $(r.source_of_measured) |")
        end
        println(io)
        println(io, "CSV: `data/report996/scale_factors.csv`.")
        println(io, "Polar stats primary: clamped_Re=$(st_p.clamped_Re) clamped_M=$(st_p.clamped_M) viterna=$(st_p.viterna_evals).")
    end
    println("wrote ", OUT_CSV, " and ", OUT_MD)
end

main()
