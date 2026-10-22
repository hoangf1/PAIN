#!/usr/bin/env julia
# Phase 31a/31b/31e — uncertainty budget, OAT ranking, coverage on the test article.
# Pre-registration fixed 2026-10-22 (before this run). Do not widen ranges on failure.
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN

const REPORT = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports",
                                 "uncertainty_budget_testarticle.md"))

function main()
    t0 = time()
    println("31a–31e test-article uncertainty (parametric, NASA free field)…")
    budget = uncertainty_budget(:testarticle; trimmed=true)
    cache = build_testarticle_cache()
    println("  OAT ranking…")
    oat = oat_sweep(cache, budget)
    kept = [r.name for r in oat if r.keep]
    println("  kept: ", isempty(kept) ? "(none — all at nominal)" : join(kept, ", "))
    println("  Monte Carlo uniform N=$(UNC_MC_N) seed=$(UNC_MC_SEED)…")
    mc_u = monte_carlo_band(cache, budget, kept; N=UNC_MC_N, seed=UNC_MC_SEED,
                            family=:uniform, want_bands=true)
    println("  Monte Carlo triangular…")
    mc_t = monte_carlo_band(cache, budget, kept; N=UNC_MC_N, seed=UNC_MC_SEED,
                            family=:triangular, want_bands=true)
    means = e16_measured_means()
    cov = coverage_check(mc_u; measured_means=means)
    println("  31e verdict: ", cov.verdict)
    dt = time() - t0
    md = uncertainty_report_md(;
        title="Uncertainty budget — test article (phase 31a/31b/31e)",
        budget, oat, mc_uniform=mc_u, mc_triangular=mc_t, coverage=cov,
        runtime_s=dt)
    mkpath(dirname(REPORT))
    open(REPORT, "w") do io
        write(io, md)
    end
    println("Wrote ", REPORT, " in ", round(dt; digits=1), " s")
    return cov.verdict
end

main()
