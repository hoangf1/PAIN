# Unit tests: src/cyl2d.jl (Phase 64). CR-3813 App. C finite differences.
@testset "grid helpers" begin
    lo, hi = PAIN._segment_limits([0.0, 1.0, 3.0])
    @test lo == [0.0, 0.5, 2.0] && hi == [0.5, 2.0, 3.0]
    θ0 = deg2rad(56.6)
    g = PAIN._build_grid(θ0, 10)
    @test g.h ≈ (1 + cos(θ0)) / 10 && g.yfloor ≈ -cos(θ0)
    # Fig. C-3 row counts, crown row first (App. C, NY = 10)
    @test reverse([count(g.incab[:, n+1]) for n in 0:10]) == [3, 5, 6, 6, 7, 7, 7, 7, 7, 7, 6]
    @test PAIN._in(g, -2, 3) == PAIN._in(g, 2, 3) && !PAIN._in(g, 0, -1) && !PAIN._in(g, 0, 11) && !PAIN._in(g, 99, 0)
    @test PAIN._θnode(g, 0, 10) ≈ π atol = 1e-12
    @test PAIN._θnode(g, 0, 0) ≈ 0 atol = 1e-12
    @test PAIN._θnode(g, 1, 0) ≈ atan(g.h, cos(θ0))
end
@testset "cyl2d_modes: near-circle limit and normalization" begin
    # θ0 → 0 is a full circle: k a = zeros of J′ₙ (1.8412 n=1, 3.0542 n=2, 3.8317 n=0) — analytic, independent
    r = PAIN.cyl2d_modes(2.0; NY=20, n_modes=6)
    ka = [sqrt(m.lambda_unit) for m in r.modes]
    @test ka[1] ≈ 0 atol = 1e-3
    @test ka[2] ≈ 1.8412 rtol = 0.02
    @test ka[3] ≈ 1.8412 rtol = 0.02                 # degenerate cos/sin pair
    @test ka[4] ≈ 3.0542 rtol = 0.02
    @test ka[5] ≈ 3.0542 rtol = 0.02
    @test ka[6] ≈ 3.8317 rtol = 0.02
    @test r.modes[2].symmetric != r.modes[3].symmetric
    # rigid-body mode: Φ_G (Eq. C.10, trapezoid weights) ≈ cabin area, so ε₀ ≈ 1
    c = PAIN.cyl2d_modes(56.6)
    @test c.modes[1].eps_n ≈ 1 atol = 0.02
    @test all(maximum(abs, m.phi_boundary) ≤ 1 + 1e-12 for m in c.modes)          # max-normalized
    @test issorted([m.f_Hz_unit for m in c.modes])
    @test c.modes[2].f_Hz_unit ≈ 340 / (2π) * sqrt(c.modes[2].lambda_unit)
    @test PAIN.cyl2d_modes(56.6; c0=680.0).modes[2].f_Hz_unit ≈ 2c.modes[2].f_Hz_unit
    @test_throws ErrorException PAIN.cyl2d_modes(56.6; NY=10, n_modes=500)
    r1, ch, NY2 = PAIN.cyl2d_modes_search(56.6; n_modes=10, max_change=0.05)
    @test ch ≤ 0.05 && NY2 > r1.NY
    @test_throws ErrorException PAIN.cyl2d_modes_search(56.6; n_modes=10, max_change=1e-9)
    # _solve_parity: antisymmetric modes vanish on the centreline
    m_a = first(m for m in c.modes if !m.symmetric)
    @test all(v == 0 for ((mm, n), v) in m_a.phi_nodes if mm == 0)
    @test PAIN._solve_parity(PAIN._build_grid(deg2rad(56.6), 10), true, 5).λ[1] ≈ 0 atol = 1e-8
end
@testset "boundary values, scaling and 3-D modes" begin
    c = PAIN.cyl2d_modes(56.6)
    m = c.modes[4]
    @test PAIN.acoustic_boundary_value(m, m.theta_boundary_deg[3]) ≈ m.phi_boundary[3] atol = 1e-9
    @test PAIN.acoustic_boundary_value(m, 0.0) == m.phi_boundary[1]                 # clamped below θ0
    mid = (m.theta_boundary_deg[3] + m.theta_boundary_deg[4]) / 2
    @test PAIN.acoustic_boundary_value(m, mid) ≈ (m.phi_boundary[3] + m.phi_boundary[4]) / 2 atol = 1e-9
    @test PAIN.scale_acoustic_freq(300.0, 0.5) == 600.0
    a, L = 0.508, 1.83
    @test PAIN.cabin_frequency_3d(m, a, L, 0) ≈ m.f_Hz_unit / a rtol = 1e-12
    @test PAIN.cabin_frequency_3d(m, a, L, 2) ≈ hypot(m.f_Hz_unit / a, 2 * 340 / (2L)) rtol = 1e-12
    @test PAIN.cabin_eps_3d(m, 0) == m.eps_n && PAIN.cabin_eps_3d(m, 3) == 2m.eps_n
    @test PAIN.axial_truncation(2π * 200, 1.83, 340.0) == ceil(Int, 4 * 200 * 1.83 / 340)
    m3 = PAIN.cabin_modes_3d(c, a, L, 2)
    @test length(m3) == 3 * length(c.modes) && issorted([x.f_Hz for x in m3])
    @test count(x -> x.q == 1, m3) == length(c.modes)
end
