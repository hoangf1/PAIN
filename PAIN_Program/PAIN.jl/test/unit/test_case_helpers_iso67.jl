# Unit tests: Phase 67 helpers (src/validation_case_iso67.jl).
@testset "TN 1546 Reynolds number and XFOIL lookup" begin
    # Phase 77: equivalent Δα = Δc_l/(2π/√(1−M²)): one degree of thin-airfoil lift at M = 0 gives 1°; factor 0.8 at M 0.6
    @test PAIN._p67_equiv_dalpha_deg(2π * deg2rad(1.0), 0.0) ≈ 1.0
    @test PAIN._p67_equiv_dalpha_deg(2π * deg2rad(1.0), 0.6) ≈ 0.8
    @test isapprox(PAIN._p67_equiv_dalpha_deg(0.05, 0.72), 0.3164; atol=1e-4) && PAIN._p67_equiv_dalpha_deg(-0.05, 0.4) < 0
    @test PAIN._p67_tn1546_Re(0.3) ≈ 0.85e6 && PAIN._p67_tn1546_Re(0.8) ≈ 2.0e6 && PAIN._p67_tn1546_Re(0.55) ≈ 1.425e6
    tables = Dict(("s", 1e6, 0.4) => [(-2.0, -0.2, 0.01), (2.0, 0.2, 0.01)], ("s", 2e6, 0.4) => [(-2.0, -0.1, 0.01), (2.0, 0.3, 0.01)])
    @test PAIN._p67_xfoil_cl(tables, [1e6, 2e6], "s", 0.0, 0.4, 1e6) ≈ 0.0
    @test PAIN._p67_xfoil_cl(tables, [1e6, 2e6], "s", 0.0, 0.4, sqrt(2) * 1e6) ≈ 0.05      # halfway in log Re
    @test PAIN._p67_xfoil_cl(tables, [1e6, 2e6], "s", 5.0, 0.4, 1.5e6) === nothing           # α outside: no extrapolation
    # Phase 69: linear in M between grid Mach numbers (the TN 1546 M = 0.55 lies between grid 0.5 and 0.6)
    tm = Dict(("s", 1e6, 0.5) => [(-2.0, -0.2, 0.01), (2.0, 0.2, 0.01)], ("s", 1e6, 0.6) => [(-2.0, -0.4, 0.01), (2.0, 0.4, 0.01)])
    @test PAIN._p67_xfoil_cl(tm, [1e6], "s", 1.0, 0.55, 1e6) ≈ 0.15
    @test PAIN._p67_xfoil_cl(tm, [1e6], "s", 1.0, 0.7, 1e6) === nothing                      # M outside the grid: nothing
    r = PAIN._p67_result("U", PAIN.ValidationTableRow[], PAIN.PlotSeries[], true, "x", (;); verdict=:no_verdict)
    @test r.verdict == :no_verdict && r.label == "diagnostic"
end
@testset "chordwise F1A: one point = the compact independent F1A; static force limit" begin
    cfg = PAIN._r996_cfg(; beta75=10.0, Mt=0.6, B=2)
    su = PAIN._ccblade_setup(cfg; allow_static=true)
    obs = PAIN.hub_observers(su.Rtip, 2su.Rtip; x_over_D=[0.25], d_over_D=0.083, x_sign=1)
    dr = PAIN._p66_dr(su.r, su.Rhub, su.Rtip); Np = [o.Np for o in su.outs]; Tp = [o.Tp for o in su.outs]
    a1, _ = PAIN._p67_f1a_chordwise(su.r, su.chord, su.theta, Np, Tp, dr, su.B, su.Ω, su.c0, obs; nc=1)
    ai, _, _ = PAIN._iso41_independent_f1a(su.r, Np, Tp, dr, su.B, su.Ω, 1.225, su.c0, obs; n_harmonics=3)
    @test a1 ≈ ai rtol = 1e-3
    # zero chord: chordwise and compact coincide exactly
    a8, _ = PAIN._p67_f1a_chordwise(su.r, zero(su.chord), su.theta, Np, Tp, dr, su.B, su.Ω, su.c0, obs; nc=8)
    @test a8 ≈ a1 rtol = 1e-9
end
@testset "Phase 80 references (App. D solver verification)" begin
    # Leissa SS-C-SS-C square plate: λ = ω a² √(ρh/D) = 28.95
    f = PAIN._p80_clamped_plate_Hz(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1, true; nmodes=2)
    @test isapprox(2π * f[1], 28.951; rtol=1e-3) && f[2] > f[1]
    fo = PAIN._p80_clamped_plate_Hz(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1, false; nmodes=1)
    @test fo[1] > f[1]                                   # the first odd mode lies above the first even one
    d = appd_nasa_deck()
    fs = PAIN._p80_shell_alone_Hz(d, 1, true; n_circ=6)
    @test issorted(fs) && minimum(abs.(fs ./ PAIN.appd_shell_harmonic_frequency_Hz(1, 3, d) .- 1)) < 1e-12
    m = StructuralMode(1, 100.0, true, 1.0, 1, [0.6, -0.3, 0.1], [2, 3, 5], [1.0, 0.2], [0, 1])
    t = PAIN._p80_truncate(m, 2, 1)
    @test t.n_shell == [2, 3] && t.n_floor == [0]
    @test PAIN._p80_dense_peak(StructuralMode(1, 1.0, true, 1.0, 1, Float64[], Int[], [0.8], [0]), 56.6, 0.508) ≈ 0.8
end
@testset "Phase 81 slope helper" begin
    f = [100.0, 200.0, 400.0]
    @test PAIN._p81_slope_per_octave(f, [10.0, 16.0, 22.0]) ≈ 6.0
    @test PAIN._p81_slope_per_octave(f, [10.0, 28.0, 46.0]) ≈ 18.0
    @test PAIN._p81_slope_per_octave([100.0, 141.42, 200.0], [0.0, 3.0, 6.0]) ≈ 6.0 rtol = 1e-4
end
