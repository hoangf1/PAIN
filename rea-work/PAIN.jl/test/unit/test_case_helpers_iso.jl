# Unit tests: independent-reference helpers of the isolation cases (src/validation_case_iso40.jl,
# src/validation_case_iso41.jl) (Phase 64). These references must themselves be right, so each is
# checked against a tabulated value, an exact solution or a second route.
@testset "iso40: Bessel, J′ zeros, quadrature" begin
    @test PAIN._iso_besselj(0, 1.0) ≈ 0.7651976865579666 atol = 1e-14            # A&S Table 9.1
    @test PAIN._iso_besselj(2, 3.0) ≈ 0.4860912605858911 atol = 1e-14
    @test PAIN._iso_besselj(-3, 2.0) ≈ -PAIN._iso_besselj(3, 2.0)
    @test PAIN._iso_besselj_prime(0, 1.3) ≈ -PAIN._iso_besselj(1, 1.3) atol = 1e-14
    @test PAIN._iso_besselj_prime(1, 0.0) == 0.5
    @test PAIN._iso_jprime_zeros(1, 2) ≈ [1.8411837813, 5.3314427735] atol = 1e-8
    @test PAIN._iso_jprime_zeros(0, 1) ≈ [3.8317059702] atol = 1e-8
    @test_throws ErrorException PAIN._iso_jprime_zeros(-1, 1)
    f = PAIN._iso_circle_mode_freqs(340.0, 6)
    @test f[1] == 0 && f[2] ≈ f[3] ≈ 340 * 1.8411837813 / 2π && f[4] ≈ 340 * 3.0542369282 / 2π && f[6] ≈ 340 * 3.8317059702 / 2π
    @test PAIN._iso_simpson(sin, 0.0, Float64(π)) ≈ 2 atol = 1e-9
    @test PAIN._iso_simpson(x -> x^2, 0.0, 1.0) ≈ 1 / 3 atol = 1e-12
    @test PAIN._iso_ring_quad(0, 1e-6, :psi; N=50) ≈ 1 atol = 1e-6                  # rigid ring, kζ → 0
    @test PAIN._iso_ring_quad(3, 2.5, :psi; N=300) ≈ PAIN.ring_joint_acceptance(3, 2.5, :psi; mode_normalized=true) atol = 3e-3
    @test PAIN._iso_axial_quad(2, 9.0; N=300) ≈ PAIN.axial_joint_acceptance(2, 9.0; mode_normalized=true) atol = 3e-3
    st = PAIN.structural_modes_from_table_d1().modes[2]
    ω = 2π * 600
    @test PAIN._iso_joint_acceptance_quad(st, ω; a=0.508, L=1.83, printed=true) ≈ PAIN.structural_joint_acceptance(st, ω; a=0.508, L=1.83) rtol = 0.02
    # band integral of S(f) = S_a (f_a/f)^α · 2π over exact 1/3-octave edges, against quadrature
    for α in (1.0, 2.0, 2.7)
        fc = 1600.0
        q = PAIN._iso_simpson(f -> 3.0 * (600 / f)^α * 2π, fc * 2^(-1 / 6), fc * 2^(1 / 6))
        @test PAIN._iso_bb_band_integral(3.0, 600.0, fc, α) ≈ q rtol = 1e-9
    end
end
@testset "iso41: hand NR brace, closed trim product, E-12 reader" begin
    for args in ((1000.0, 0.232, 950.0, 0.05, 1080.0, 0.02), (400.0, 0.232, 700.0, 0.01, 480.0, 0.04))
        h = PAIN._iso41_hand_nr_brace(args...)
        t = PAIN.nr_brace(args...)
        @test h.brace ≈ t.brace rtol = 1e-12
        @test h.D_nr ≈ t.D_nr rtol = 1e-12
        @test h.brace / h.D_nr ≈ PAIN.nr_band_integral_quad(args...; N=200_000) rtol = 1e-5   # and both equal the integral
    end
    tbl = PAIN.pf105_table()
    ω = 2π * 800
    M = PAIN._iso41_closed_two_layer(ω, 0.02, tbl, 0.5, 0.1)
    @test M ≈ PAIN.stack_matrix(PAIN.TrimStack([PAIN.InsulationLayer(0.02, tbl), PAIN.LimpMass(0.5, 0.1)]), ω)
    c = PAIN._iso41_e12_measured_curve()
    @test haskey(c, 1) && issorted(first.(c[1]))
    x = (c[1][1][1] + c[1][2][1]) / 2
    @test PAIN._iso41_e12_interp(c[1], x) ≈ (c[1][1][2] + c[1][2][2]) / 2 && isnan(PAIN._iso41_e12_interp(c[1], -1e9))
end
@testset "iso41: hand BEM against CCBlade" begin
    r, chord, θ, Rhub, Rtip, ρ, B = 0.6, 0.1, deg2rad(15.0), 0.2, 1.0, 1.225, 2
    Vx, Vy = 20.0, 1200 * 2π / 60 * r
    s = PAIN._iso41_hand_bem_solve_phi(r, chord, θ, Rhub, Rtip, Vx, Vy, ρ, B)
    @test abs(s.R) ≤ 1e-8                                                           # converged residual
    rotor = PAIN.CCBlade.Rotor(Rhub, Rtip, B; tip=nothing)
    sec = PAIN.CCBlade.Section(r, chord, θ, (α, Re, M) -> (2π * α, 0.0))
    out = PAIN.CCBlade.solve(rotor, sec, PAIN.CCBlade.OperatingPoint(Vx, Vy, ρ))
    @test s.Np ≈ out.Np rtol = 1e-6
    @test s.Tp ≈ out.Tp rtol = 1e-6
    h = PAIN._iso41_hand_bem_section(0.3, r, chord, θ, Rhub, Rtip, 0.0, Vy, ρ, B)      # hover branch
    @test h.R ≈ sign(0.3) - (2π * (θ - 0.3) * cos(0.3)) * (B * chord / (2π * r)) / (4 * sin(0.3)^2)
end
@testset "iso41: independent F1A against exact solutions" begin
    c0 = 340.0
    # static point force: p = f·r̂ / (4π r²) (near-field dipole, exact)
    x = [0.0, 3.0, 4.0]; f = (0.0, 2.0, 0.0)
    @test PAIN._iso41_f1a_loading_p(x, (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), f, (0.0, 0.0, 0.0), c0) ≈ 2 * 0.6 / (4π * 25) rtol = 1e-12
    # force rate at rest: p = ḟ·r̂ / (4π c₀ r) (far-field dipole term)
    @test PAIN._iso41_f1a_loading_p(x, (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (0.0, 5.0, 0.0), c0) ≈ 5 * 0.6 / (4π * c0 * 5) rtol = 1e-12
    # single-radius rotating torque force = Gutin's setting: p_rms = (mBΩ/(2√2πc₀r)) Qc₀/(ΩR²) J_mB(mBΩR/c₀)
    B, Ω, re, Δr, Tp = 3, 4000 * 2π / 60, 0.30, 0.01, 50.0
    obs = [PAIN.Observer([0.0, 30.0, 0.0], zeros(3), "plane"), PAIN.Observer([30.0, 0.0, 0.0], zeros(3), "axis")]
    amp, ph, bpf = PAIN._iso41_independent_f1a([re], [0.0], [Tp], [Δr], B, Ω, 1.225, c0, obs; n_harmonics=2, num_src_times=128)
    Q = B * Tp * Δr * re
    for m in 1:2
        g = sqrt(2) * (m * B * Ω / (2sqrt(2) * π * c0 * 30.0)) * (Q * c0 / (Ω * re^2)) * abs(PAIN._besselj_int(m * B, m * B * Ω * re / c0))
        @test amp[1, m] ≈ g rtol = 1e-3
    end
    @test amp[2, 1] ≤ 1e-6 * amp[1, 1] && bpf ≈ B * Ω / 2π                            # nothing on the axis
end
