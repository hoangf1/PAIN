#!/usr/bin/env julia
# Phase 31c/31d — phase bounding + Monte Carlo band on the aircraft working example.
# Pre-registration fixed 2026-10-22 (before this run). Epistemic band, not a CI.
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN

const REPORT = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports",
                                 "uncertainty_aircraft_band.md"))
const AC_JSON = normpath(joinpath(@__DIR__, "..", "..", "examples",
                                  "aircraft_scale_hartzell_cabin_full.json"))

function main()
    t0 = time()
    println("31c–31d aircraft epistemic band (", AC_JSON, ")…")
    isfile(AC_JSON) || error("missing aircraft JSON: $AC_JSON")
    budget = uncertainty_budget(:aircraft; trimmed=false)
    cache = build_aircraft_cache(AC_JSON)
    # Provenance tags: every cabin input except diameter is assumed (29c working example)
    prov = String[]
    r_echo = run_pain_pipeline(; source=:aircraft, aircraft_json=AC_JSON, n_harmonics=3)
    if hasproperty(r_echo.provenance, :inputs)
        for row in r_echo.provenance.inputs
            tag = String(row.tag)
            name = String(row.name)
            tag == "assumed" && push!(prov, name)
        end
    end
    println("  OAT ranking…")
    oat = oat_sweep(cache, budget)
    kept = [r.name for r in oat if r.keep]
    println("  kept: ", isempty(kept) ? "(none — all at nominal)" : join(kept, ", "))
    println("  Phase bounding cases (31c)…")
    phase = phase_bounding_cases(cache, budget)
    println("  Monte Carlo uniform N=$(UNC_MC_N)…")
    mc_u = monte_carlo_band(cache, budget, kept; N=UNC_MC_N, seed=UNC_MC_SEED,
                            family=:uniform, want_bands=true)
    println("  Monte Carlo triangular…")
    mc_t = monte_carlo_band(cache, budget, kept; N=UNC_MC_N, seed=UNC_MC_SEED,
                            family=:triangular, want_bands=true)
    dt = time() - t0
    md = uncertainty_report_md(;
        title="Uncertainty aircraft band (phase 31c/31d) — working example 2.64 m diameter",
        budget, oat, mc_uniform=mc_u, mc_triangular=mc_t, phase=phase,
        provenance_tags=prov, runtime_s=dt)
    mkpath(dirname(REPORT))
    open(REPORT, "w") do io
        write(io, md)
    end
    println("Wrote ", REPORT, " in ", round(dt; digits=1), " s")
    return nothing
end

main()
