# Unit tests: src/grid_extension.jl and src/metrics.jl (Phase 64).
@testset "extend_line_to_grid" begin
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    pts = PAIN.grid_points(fuse, PAIN.PropellerPlacement(0.965, 90.0, 0.662))
    la = [Float64(k) for k in 1:16, H in 1:2]; lp = fill(0.3, 16, 2)
    A, P = PAIN.extend_line_to_grid(la, lp, pts)
    @test A[5, 1, 1] == 5.0                                    # ℓ = 1 unchanged
    @test A[5, 4, 2] ≈ 5.0 * cosd(30) rtol = 1e-12             # cos falloff at 30°
    @test A[5, 10, 1] ≈ 5.0 * cosd(90) atol = 1e-12
    @test all(P .== 0.3)                                       # no ω_H → phases copied
    A0, _ = PAIN.extend_line_to_grid(la, lp, pts; falloff_exponent=0.0)
    @test all(A0[:, :, 1] .≈ la[:, 1])                         # n = 0: flat
    Af, _ = PAIN.extend_line_to_grid(la, lp, pts; falloff_floor=0.5)
    @test Af[5, 10, 1] ≈ 2.5 rtol = 1e-12
    _, Pd = PAIN.extend_line_to_grid(la, lp, pts; omega_H=[2π * 200, 2π * 400], c0=340.0)
    p = first(q for q in pts if q.k == 5 && q.ell == 6)
    p1 = first(q for q in pts if q.k == 5 && q.ell == 1)
    @test Pd[5, 6, 1] ≈ 0.3 - 2π * 200 * (hypot(p.x1, p.x2, p.x3) - hypot(p1.x1, p1.x2, p1.x3)) / 340 rtol = 1e-12
    @test_throws ArgumentError PAIN.extend_line_to_grid(la, lp, pts; falloff_exponent=-1.0)
    @test_throws ArgumentError PAIN.extend_line_to_grid(la, lp, pts; falloff_floor=1.5)
end
@testset "a_weight_dB" begin
    # IEC 61672 tabulated A-weighting at nominal centres (0.1 dB table rounding)
    for (f, A) in ((63.0, -26.2), (125.0, -16.1), (250.0, -8.6), (500.0, -3.2), (1000.0, 0.0), (2000.0, 1.2), (4000.0, 1.0))
        @test abs(PAIN.a_weight_dB(f) - A) ≤ 0.1
    end
end
@testset "sil_dB / sil_from_third_octave" begin
    @test PAIN.sil_dB(Dict(500.0 => 60.0, 1000.0 => 62.0, 2000.0 => 58.0, 4000.0 => 52.0)) ≈ 58.0
    # three equal 1/3-octave bands per octave add 10 log10 3
    third = Dict(f => 50.0 for f in (397.0, 500.0, 630.0, 794.0, 1000.0, 1260.0, 1587.0, 2000.0, 2520.0, 3175.0, 4000.0, 5040.0))
    @test PAIN.sil_from_third_octave(third) ≈ 50 + 10log10(3) atol = 1e-9
end
@testset "overall_dBA" begin
    sp = PAIN.InteriorSpectrum(200.0, [80.0, 70.0], Dict{Float64,Float64}(), "t")
    hand = 10log10(10^((80 + PAIN.a_weight_dB(200.0)) / 10) + 10^((70 + PAIN.a_weight_dB(400.0)) / 10))
    @test PAIN.overall_dBA(sp)[1] ≈ hand atol = 1e-9          # tonal path (no bands)
    sp2 = PAIN.InteriorSpectrum(200.0, [80.0], Dict(1000.0 => 60.0, 2000.0 => 60.0), "t")
    @test PAIN.overall_dBA(sp2)[1] ≈ 10log10(10^((60 + PAIN.a_weight_dB(1000.0)) / 10) + 10^((60 + PAIN.a_weight_dB(2000.0)) / 10)) atol = 1e-9
    @test PAIN.overall_dBA(sp2; uncertainty_1sigma_dB=2.0)[3] - PAIN.overall_dBA(sp2)[1] ≈ 2.0
end
