# Unit tests: src/blocking.jl (Phase 64). Hand values from CR-3813 Eq. (43) and CR-172428 §5.3.2.
@testset "blocking_factor" begin
    @test PAIN.blocking_factor(0.0) ≈ 10^(0.3 - 0.000224) rtol = 1e-14
    @test PAIN.blocking_factor(60.0) ≈ 10^(0.3 - 0.000224 * exp(4.8)) rtol = 1e-14
    @test PAIN.blocking_factor(0.0; variant=PAIN.R2) ≈ 0.8 * 10^(0.3 - 0.000224) rtol = 1e-14
    @test PAIN.blocking_factor(90.0; variant=PAIN.R2) == 1.0          # R2 floor: never below free field
    @test PAIN.blocking_factor(30.0) > PAIN.blocking_factor(80.0)     # decreases toward grazing
    # Q95 (Phase 118d): past 90° the printed formula falls below 1 (0.43 at 100°, 0.0034 at 117.8°); R1 holds F = 1 there
    F_printed(γ) = 10^(0.3 - 0.000224 * exp(0.08γ))
    @test F_printed(100.0) < 0.5 && F_printed(117.8) < 0.01           # what the unclamped formula would give
    @test PAIN.blocking_factor(100.0) == 1.0 && PAIN.blocking_factor(117.8) == 1.0 && PAIN.blocking_factor(179.0) == 1.0
    @test PAIN.blocking_factor(89.0) ≈ F_printed(89.0) rtol = 1e-14                    # unchanged below 90°
    @test PAIN.blocking_factor(89.0) > 1.0
end
@testset "delta_L_blocking_dB" begin
    for (γ, dL) in PAIN.BLOCKING_P68_CHECKPOINTS
        @test abs(PAIN.delta_L_blocking_dB(γ) - dL) ≤ 0.06               # CR-172428 p. 68 narrative values
    end
    @test PAIN.delta_L_blocking_dB(0.0; variant=PAIN.R2) ≈ 20log10(0.8 * 10^(0.3 - 0.000224)) rtol = 1e-12
end
@testset "blocked_amplitude" begin
    @test PAIN.blocked_amplitude(2.5, 40.0) ≈ 2.5 * PAIN.blocking_factor(40.0) rtol = 1e-14
    @test PAIN.blocked_amplitude(0.0, 10.0) == 0.0
end
