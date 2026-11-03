#!/usr/bin/env julia
# Phase 80f (IMPLEMENTATION_PLAN.md §8x), report only, no verdict: each of the 16 App. D inputs of the 2.64 m working
# example (`examples/aircraft_scale_hartzell_cabin_full.json`, parametric path) varied by ±20 % one at a time; change of
# the 32 lowest structural frequencies and of the H1–H3 interior levels. Nothing is chosen from the result; defaults,
# criteria and records are not changed. Writes docs/validation_reports/phase80_mrp_sensitivity.md.
ENV["QT_QPA_PLATFORM"] = get(ENV, "QT_QPA_PLATFORM", "offscreen")
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN, JSON3, Dates, Printf

const EXAMPLE = joinpath(@__DIR__, "..", "..", "examples", "aircraft_scale_hartzell_cabin_full.json")
const INPUTS = ["t_skin_m", "t_floor_m", "A_stringer_m2", "d_stringer_m", "I_stringer_m4", "A_frame_m2", "ell_frame_m",
                "I_frame_m4", "A_floor_beam_m2", "I_floor_beam_m4", "E_Pa", "nu", "rho_struc_kg_m3", "L_m", "a_m", "theta0_deg"]

function run_case(cfg, dir, tag)
    path = joinpath(dir, "cfg_$tag.json")
    open(io -> JSON3.write(io, cfg), path, "w")
    r = run_pain_pipeline(; source=:aircraft, aircraft_json=path, n_harmonics=3)
    return [m.f_Hz for m in r.structural.modes[1:32]], r.spectrum.harmonic_SPL_dB[1:3]
end

function main()
    base = JSON3.read(read(EXAMPLE, String), Dict{String,Any})
    dir = mktempdir()
    f0, h0 = run_case(base, dir, "base")
    rows = String[]
    for name in INPUTS, s in (0.8, 1.2)
        cfg = deepcopy(base)
        c = cfg["cabin"][name]
        v0 = Float64(c isa AbstractDict ? c["value"] : c)
        c isa AbstractDict ? (c["value"] = s * v0) : (cfg["cabin"][name] = s * v0)
        f, h = try
            run_case(cfg, dir, "$(name)_$s")
        catch e
            push!(rows, "| `$name` | ×$s | failed: $(sprint(showerror, e)[1:min(80, end)]) | | | | |")
            continue
        end
        df = 100 .* (f ./ f0 .- 1)
        push!(rows, @sprintf("| `%s` | ×%.1f | %+.2f | %+.2f | %+.2f | %+.2f | %+.2f |", name, s,
                             df[1], sum(abs, df) / 32, h[1] - h0[1], h[2] - h0[2], h[3] - h0[3]))
        println(rows[end])
    end
    out = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports", "phase80_mrp_sensitivity.md"))
    open(out, "w") do io
        println(io, "# Phase 80f: App. D input sensitivity for a new fuselage (report only, no verdict)\n")
        println(io, "Generated $(Dates.today()) by `scripts/run/phase80_mrp_sensitivity.jl`. Fuselage: the 2.64 m working example ",
                "(`aircraft_scale_hartzell_cabin_full.json`, parametric path, App. D solver with NASA's floor form and series ",
                "limits). Each input ×0.8 and ×1.2, one at a time. Nothing is chosen from these numbers.\n")
        println(io, @sprintf("Baseline: lowest structural mode %.1f Hz; interior H1, H2, H3 = %.2f, %.2f, %.2f dB.\n", f0[1], h0...))
        println(io, "| Input | Factor | Δf mode 1 (%) | mean \\|Δf\\| of 32 modes (%) | ΔH1 (dB) | ΔH2 (dB) | ΔH3 (dB) |")
        println(io, "|---|---|---|---|---|---|---|")
        foreach(r -> println(io, r), rows)
        println(io, "\n`L_m`, `a_m` and `theta0_deg` also move the acoustic modes, the grid and the propeller clearance, so their ",
                "level changes are not structural alone.")
    end
    println("wrote ", out)
end

main()
