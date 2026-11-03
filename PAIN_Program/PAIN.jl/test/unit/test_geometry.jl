# Unit tests: src/geometry.jl (Phase 64). Hand values from the User Manual pp. 8–9 grid relations.
@testset "test_article_length / override" begin
    L0 = PAIN.test_article_length()
    @test L0 == PAIN.TEST_ARTICLE_L_DEFAULT == 1.83
    @test !PAIN.test_article_length_overridden()
    @test PAIN.with_test_article_length(() -> PAIN.test_article_length(), 1.803) == 1.803
    @test PAIN.test_article_length() == L0 && !PAIN.test_article_length_overridden()   # restored
    @test PAIN.set_test_article_length!(1.9) == 1.9 && PAIN.test_article_length_overridden()
    @test PAIN.reset_test_article_length!() == 1.83 && !PAIN.test_article_length_overridden()
    @test_throws ErrorException PAIN.with_test_article_length(() -> error("x"), 1.7)
    @test PAIN.test_article_length() == 1.83                                         # restored after an error
end
@testset "PropellerPlacement" begin
    p = PAIN.PropellerPlacement(0.965, 90, 0.662)
    @test p.rotation_direction == 1 && p.z_p == 0.662
    @test PAIN.PropellerPlacement(1.0, 90.0, 0.5, -1).rotation_direction == -1
    @test_throws ErrorException PAIN.PropellerPlacement(1.0, 90.0, 0.5, 2)
end
@testset "grid_points" begin
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    prop = PAIN.PropellerPlacement(0.965, 90.0, 0.662)
    pts = PAIN.grid_points(fuse, prop, PAIN.GridSpec())
    @test length(pts) == 160
    Δ = π * 0.508 / 18
    for p in pts
        α = (p.ell - 1) * π / 18
        @test p.x1 ≈ (0.965 - 0.508) + 0.508 * (1 - cos(α)) atol = 1e-12
        @test p.x2 ≈ -0.508 * sin(α) atol = 1e-12
        @test p.x3 ≈ Δ * (8 - p.k) atol = 1e-12
        @test p.z ≈ 0.662 - Δ * (8 - p.k) atol = 1e-12        # z_k = z_p − x₃ (Manual p. 9)
        @test p.theta_deg ≈ 90 + rad2deg(α) atol = 1e-10
        @test 0 ≤ p.z ≤ fuse.L                                 # the grid lies on the cylinder
    end
    @test_logs PAIN.grid_points(fuse, prop, PAIN.GridSpec())                          # on the cylinder: no warning
    # a grid longer than the cabin (a = 1.32 m: 15 × πa/18 = 3.45 m > L) warns with the count off the cylinder
    @test_logs (:warn, r"80 of 160 grid points lie off the cylinder") PAIN.grid_points(PAIN.FuselageGeometry(1.83, 1.32, 56.6), PAIN.PropellerPlacement(1.777, 90.0, 0.90))
    pm = PAIN.grid_points(fuse, PAIN.PropellerPlacement(0.965, 90.0, 0.662, -1))
    @test pm[2].theta_deg ≈ 90 - 10 atol = 1e-10
    @test pm[2].x2 ≈ 0.508 * sind(10) atol = 1e-12
end
@testset "incidence_angle_deg" begin
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    prop = PAIN.PropellerPlacement(0.965, 90.0, 0.662)
    @test PAIN.incidence_angle_deg(fuse, prop, 90.0, 0.662) ≈ 0 atol = 1e-6          # normal incidence below the hub
    # axial offset d on ℓ = 1: tan γ = d / (r_p − a)
    @test PAIN.incidence_angle_deg(fuse, prop, 90.0, 0.662 + 0.457) ≈ 45.0 atol = 1e-9
    @test PAIN.incidence_angle_deg(fuse, prop, 90.0, 0.2) ≈ PAIN.incidence_angle_deg(fuse, prop, 90.0, 1.124) atol = 1e-9  # symmetric
end
