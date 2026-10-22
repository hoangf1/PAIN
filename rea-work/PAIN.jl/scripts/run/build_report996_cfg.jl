#!/usr/bin/env julia
# Phase 25b: write Report 996 aircraft JSON from blade_form.csv (β₇₅ target, B, rpm from M_t).
using PAIN
using JSON3

const ROOT = joinpath(@__DIR__, "..", "..", "..")
const BF = joinpath(ROOT, "data", "report996", "naca_4-5-08-03", "blade_form.csv")
const OUTDIR = joinpath(@__DIR__, "..", "..", "examples")

function rpm_from_Mt(Mt; D=1.2192, a=340.3)
    # M_t = Ω R / a = (rpm·2π/60)·(D/2) / a → rpm = M_t · a · 60 / (π D)
    return Mt * a * 60 / (π * D)
end

function write_cfg(; beta75, Mt, B, name)
    g = blade_form_geometry(BF; D=1.2192, beta75_target_deg=Float64(beta75))
    # tip thickness from last station (for thickness-on sensitivity); production default 0
    t_over_c = 0.0
    cfg = Dict(
        "description" => "Report 996 NACA 4-(5)(08)-03; β75=$(beta75)°; Mt=$(Mt); B=$(B); from blade_form.csv (25b)",
        "propeller" => Dict(
            "num_blades" => B,
            "tip_radius_m" => g.R,
            "hub_radius_m" => g.radii_m[1],
            "rpm" => rpm_from_Mt(Mt; D=g.D),
            "thickness_over_chord" => t_over_c,
            "pitch_offset_deg" => 0.0,
            "radii_m" => collect(g.radii_m),
            "chord_m" => collect(g.chord_m),
            "twist_deg" => collect(g.twist_deg),
        ),
        "operating_point" => Dict(
            "forward_speed_mps" => 0.0,
            "rho_kg_m3" => 1.225,
            "c0_mps" => 340.3,
        ),
        "anopp_table8_calibrate" => false,
        "notes" => "allow_static=true required; polar via load_polar_set; D=$(g.D) m",
    )
    path = joinpath(OUTDIR, name)
    open(path, "w") do io
        JSON3.pretty(io, cfg)
    end
    println("wrote ", path)
    return path
end

mkpath(OUTDIR)
# Core cases for phases 26–27
write_cfg(beta75=10, Mt=0.60, B=2, name="report996_b2_beta10_Mt060.json")
write_cfg(beta75=15, Mt=0.60, B=2, name="report996_b2_beta15_Mt060.json")
write_cfg(beta75=20, Mt=0.60, B=2, name="report996_b2_beta20_Mt060.json")
write_cfg(beta75=10, Mt=0.45, B=2, name="report996_b2_beta10_Mt045.json")
write_cfg(beta75=10, Mt=0.75, B=2, name="report996_b2_beta10_Mt075.json")
write_cfg(beta75=10, Mt=0.90, B=2, name="report996_b2_beta10_Mt090.json")
write_cfg(beta75=15, Mt=0.75, B=2, name="report996_b2_beta15_Mt075.json")
write_cfg(beta75=10, Mt=0.60, B=4, name="report996_b4_beta10_Mt060.json")
println("done")
