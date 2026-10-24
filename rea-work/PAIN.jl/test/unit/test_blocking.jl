# Unit tests: src/blocking.jl (Phase 64). Hand values from CR-3813 Eq. (43) and CR-172428 §5.3.2.
@testset "blocking_factor" begin
    @test PAIN.blocking_factor(0.0) ≈ 10^(0.3 - 0.000224) rtol = 1e-14
    @test PAIN.blocking_factor(60.0) ≈ 10^(0.3 - 0.000224 * exp(4.8)) rtol = 1e-14
    @test PAIN.blocking_factor(0.0; variant=PAIN.R2) ≈ 0.8 * 10^(0.3 - 0.000224) rtol = 1e-14
    @test PAIN.blocking_factor(90.0; variant=PAIN.R2) == 1.0          # R2 floor: never below free field
    @test PAIN.blocking_factor(30.0) > PAIN.blocking_factor(80.0)     # decreases toward grazing
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
