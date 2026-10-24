# Unit tests: src/uncertainty.jl (Phase 64). Budget table, samplers, evaluator consistency, report template.
@testset "budget and samplers" begin
    b = PAIN.uncertainty_budget(:testarticle)
    names = [r.name for r in b.rows]
    @test allunique(names)
    act = PAIN.active_budget_rows(b)
    @test all(r.type in (:continuous, :discrete) for r in act)
    @test all(r.range_lo ≤ r.nominal ≤ r.range_hi for r in act if r.type === :continuous)
    @test all(r.nominal in r.alternatives for r in act if r.type === :discrete)
    ba = PAIN.uncertainty_budget(:aircraft)
    @test any(r.name == "source_amp_residual" && r.type === :excluded for r in ba.rows)
    @test_throws ErrorException PAIN.uncertainty_budget(:other)
    nom = PAIN.nominal_sample(b)
    @test Set(keys(nom)) == Set(r.name for r in act)
    @test PAIN._blocking_of(1) == R1 && PAIN._blocking_of(2.0) == R2
    rng = PAIN.Random.MersenneTwister(1)
    u = [PAIN._rand_uniform(rng, 2.0, 5.0) for _ in 1:20_000]
    @test all(2 .≤ u .≤ 5)
    @test PAIN.Statistics.mean(u) ≈ 3.5 atol = 0.05
    t = [PAIN._rand_triangular(rng, 0.0, 3.0, 2.0) for _ in 1:40_000]
    @test all(0 .≤ t .≤ 3)
    @test PAIN.Statistics.mean(t) ≈ (0 + 3 + 2) / 3 atol = 0.03   # triangular mean
    @test PAIN._rand_triangular(rng, 1.0, 1.0, 1.0) == 1.0
    cont = first(r for r in act if r.type === :continuous)
    disc = first(r for r in act if r.type === :discrete)
    @test PAIN._sample_row!(rng, disc, :uniform) in disc.alternatives
    @test_throws ErrorException PAIN._sample_row!(rng, cont, :normal)
    s = PAIN._draw_sample(rng, b, [cont.name], :uniform)
    @test all(s[k] == nom[k] for k in keys(nom) if k != cont.name)                   # only the kept row moves
    @test PAIN._spearman([1.0, 2.0, 3.0, 4.0], [10.0, 20.0, 25.0, 99.0]) ≈ 1
    @test PAIN._spearman([1.0, 2.0, 3.0], [3.0, 2.0, 1.0]) ≈ -1
    @test isnan(PAIN._spearman(Float64[], Float64[]))
    mc = (; harm=[(; P5=80.0, P50=82.0, P95=85.0), (; P5=70.0, P50=71.0, P95=72.0)])
    cv = PAIN.coverage_check(mc; measured_means=[84.0, 75.0])
    @test cv.verdict == :not_met && cv.rows[1].inside && cv.rows[1].margin_dB ≈ 1 && cv.rows[2].margin_dB ≈ -3
    @test length(PAIN.e16_measured_means()) == 3
    @test isfinite(PAIN.bbn_h1_residual_gradient_ratio())
end
@testset "chain cache and evaluator" begin
    cache = PAIN.build_testarticle_cache()
    @test cache.num_blades == 3 && cache.trimmed && length(cache.acoustic_by_tol) == 3
    st2 = PAIN._scale_structural(cache.structural0, 1.05)
    @test st2.modes[3].f_Hz ≈ 1.05 * cache.structural0.modes[3].f_Hz
    @test PAIN._scale_structural(cache.structural0, 1.0) === cache.structural0
    b = PAIN.uncertainty_budget(:testarticle)
    nom = PAIN.nominal_sample(b)
    ev = PAIN.evaluate_uncertainty_sample(cache, nom)
    q = PAIN.axial_truncation(2π * 200.0, ev.inp.L_c, ev.inp.c_int) + Int(round(get(nom, "q_max_delta", 0.0)))
    @test ev.H[1] ≈ 10log10(PAIN.tone_mean_square_pressure(ev.inp, 1, 2π * 200.0; q_max=q) / 4e-10 + 1e-30)
    # k = 0 bounding case reproduces the nominal levels (no phase change)
    small = PAIN.UncertaintyBudget(:testarticle, [r for r in b.rows if r.name in ("C_struc", "blocking")], String[])
    pb = PAIN.phase_bounding_cases(cache, b; k_override=0.0)
    @test pb.bbn_residual ≈ pb.nominal && pb.k == 0 && pb.B == 3
    oat = PAIN.oat_sweep(cache, small; n_cont=2)
    @test length(oat) == 2 && issorted([o.swing_dB for o in oat]; rev=true) && all(o.swing_dB ≥ 0 for o in oat)
    m1 = PAIN.monte_carlo_band(cache, small, ["C_struc"]; N=6, seed=3)
    m2 = PAIN.monte_carlo_band(cache, small, ["C_struc"]; N=6, seed=3)
    @test m1.Hmat == m2.Hmat                                                         # seeded
    @test all(h.P5 ≤ h.P50 ≤ h.P95 for h in m1.harm)
    md = PAIN.uncertainty_report_md(; title="unit", budget=small, oat)
    @test all(occursin(s, md) for s in PAIN.UNC_REQUIRED_STATEMENTS) && occursin("## OAT ranking (31b)", md)
end
@testset "aircraft cache input guard" begin
    d = UNIT_OUT
    p = joinpath(d, "unit_noblades.json")
    write(p, "{\"propeller\": {\"rpm\": 4000}}")
    @test_throws ErrorException PAIN.build_aircraft_cache(p)
    rm(p)
    ac = PAIN.build_aircraft_cache(joinpath(@__DIR__, "..", "..", "examples", "aircraft_scale_hartzell.json"); n_harmonics=2)
    @test ac.context == :aircraft && !ac.trimmed && ac.num_blades == 3 && ac.ff.source == :ccblade_f1a
end
