# Unit tests: src/trim_loss.jl (Phase 64). CR-3813 App. A transfer matrices, Eqs. (62)–(83).
@testset "absorption surrogate and Fig. A-2 table" begin
    fs = 10 .^ range(log10(50), log10(10000); length=60)
    αs = PAIN.absorption_coefficient.(fs)
    @test issorted(αs) && all(0.02 .≤ αs .≤ 0.65)
    @test PAIN.absorption_coefficient(200.0) ≈ 0.08
    t = PAIN.pf105_table()
    @test length(t.f_Hz) == 6 && first(t.f_Hz) == 100 && last(t.f_Hz) == 6300
    bad = joinpath(UNIT_OUT, "unit_unsorted_insulation.csv")
    write(bad, "f_Hz,lambda_m,alpha_dB_per_m,phi_deg,W_rayl\n200,1,1,1,1\n100,1,1,1,1\n")
    @test_throws ErrorException PAIN.load_insulation_table(bad)
    rm(bad)
    # interpolation is linear in log f and exact at the nodes
    @test PAIN._interp_logf(100.0, [100.0, 1000.0], [1.0, 3.0]) == 1.0
    @test PAIN._interp_logf(sqrt(1e5), [100.0, 1000.0], [1.0, 3.0]) ≈ 2.0
    @test PAIN._interp_logf(1e4, [100.0, 1000.0], [1.0, 3.0]) ≈ 5.0             # end segment continued
    p = PAIN.insulation_properties(t, t.f_Hz[3])
    @test p.lambda_m ≈ t.lambda_m[3] && p.W_abs ≈ t.W_rayl[3] && p.phi_rad ≈ deg2rad(t.phi_deg[3])
    @test p.alpha_Np_per_m ≈ t.alpha_dB_per_m[3] * log(10) / 20 && !p.extrapolated
    @test_throws ErrorException PAIN.insulation_properties(t, 50.0)
    @test PAIN.insulation_properties(t, 50.0; allow_extrapolation=true).extrapolated
end
@testset "transfer matrices (Eqs. A.10–A.12)" begin
    t = PAIN.pf105_table()
    ω = 2π * 1000
    ins = PAIN.InsulationLayer(0.013, t)
    lm = PAIN.LimpMass(0.2, 0.1)
    Mi, Ml = PAIN.element_matrix(ins, ω), PAIN.element_matrix(lm, ω)
    @test Mi[1, 1] * Mi[2, 2] - Mi[1, 2] * Mi[2, 1] ≈ 1 atol = 1e-10      # reciprocal element: det = cosh² − sinh² = 1
    @test Mi[1, 1] == Mi[2, 2]
    @test Ml == ComplexF64[1 ω^2*0.2*(1+0.1im); 0 1]
    @test PAIN.element_matrix(PAIN.InsulationLayer(0.0, t), ω) ≈ [1 0; 0 1]  # zero thickness = identity
    st = PAIN.TrimStack([ins, lm])
    @test PAIN.stack_matrix(st, ω) ≈ Ml * Mi                                    # skin side first
    @test PAIN.stack_matrix(PAIN.TrimStack(PAIN.TrimElement[]), ω) == [1 0; 0 1]
    M3 = PAIN.stack_matrix(PAIN.phase3_trim().sidewall, ω)
    @test abs(M3[1, 1] * M3[2, 2] - M3[1, 2] * M3[2, 1]) ≈ 1 atol = 1e-8
    @test PAIN.stack_extrapolated(st, 50.0) && !PAIN.stack_extrapolated(st, 1000.0)
    @test !PAIN.stack_extrapolated(PAIN.TrimStack([lm]), 50.0)
    @test PAIN.trim_tau_insulation(PAIN.TrimStack([lm]), ω) ≈ 1.0              # a11 = 1 for a limp mass alone
    @test PAIN.trim_Cw(PAIN.TrimStack([lm]), ω) ≈ -ω^2 * 0.2 * (1 + 0.1im)      # −a12 a22/(1 + a12 a21), a21 = 0
end
@testset "admittance, conductance, passivity" begin
    ω, m = 2π * 500, 3.0
    empty = PAIN.TrimStack(PAIN.TrimElement[])
    Z1 = 1.225 * 340 - im * ω * m
    @test PAIN.trim_admittance(empty, ω, m) ≈ 1.225 * 340 / Z1                # identity stack: β = ρc/Z₁
    @test PAIN.trim_admittance(empty, ω, Inf) == 0                              # rigid backing, no trim
    @test PAIN.trim_conductance(empty, ω, m) ≈ real(1.225 * 340 / Z1)
    p3 = PAIN.phase3_trim()
    for f in (100.0, 250.0, 1000.0, 4000.0, 6300.0)
        @test PAIN.trim_conductance(p3.sidewall, 2π * f, p3.m_wall) ≥ 0      # passive wall absorbs
        @test PAIN.trim_conductance(p3.ends, 2π * f, Inf) ≥ 0
    end
end
@testset "mechanical path (Eqs. A.19–A.22) and phase3_trim" begin
    mp = PAIN.MechanicalPath(m_t=1.0, A_t=2.0, h_t=0.001, c_t=3000.0, η_t=0.1, m=4.0, A=2.0, h=0.002, c_l=5000.0, N_points=3)
    ω = 2π * 800
    Zs, Zt = 4 * 0.002 * 5000, 1 * 0.001 * 3000
    η21 = 12 / (sqrt(3) * 2) * (3.0 / ω) * Zs * Zt / (Zs + Zt)^2
    @test PAIN.coupling_loss_factor_21(mp, ω) ≈ η21
    ml = PAIN.MechanicalPath(m_t=1.0, A_t=2.0, h_t=0.001, c_t=3000.0, η_t=0.1, m=4.0, A=2.0, h=0.002, c_l=5000.0, line_length=1.5)
    Ys, Yt = 4 * sqrt(10.0), 1 * sqrt(3.0)
    @test PAIN.coupling_loss_factor_21(ml, ω) ≈ (2 / 3)^0.25 / 2 * sqrt(3 / ω) * Ys * Yt / (Ys + Yt)^2 * 1.5
    @test PAIN.coupling_loss_factor_21(PAIN.MechanicalPath(m_t=1.0, A_t=2.0, h_t=0.001, c_t=3000.0, η_t=0.1, m=4.0, A=2.0, h=0.002, c_l=5000.0), ω) == 0
    @test mp.n_t ≈ 2 * sqrt(3) / (2π * 0.001 * 3000)
    @test PAIN.trim_tau_mechanical(mp, ω) ≈ (1 * 2 * mp.n_t) / (4 * 2 * mp.n_r) * η21 / (η21 + 0.1)
    st = PAIN.TrimStack([PAIN.LimpMass(0.2, 0.1)])
    @test PAIN.trim_tau(st, ω; mech=mp) ≈ 1 + PAIN.trim_tau_mechanical(mp, ω)
    @test PAIN.trim_tau(st, ω) ≈ 1
    p3 = PAIN.phase3_trim(; L=1.83)
    @test p3.A_curved ≈ 2 * 0.508 * (π - deg2rad(56.6)) * 1.83
    @test p3.septum_mass_per_area ≈ 6.58 / p3.A_curved
    @test length(p3.sidewall.elements) == 9 && p3.sidewall.elements[1] isa PAIN.InsulationLayer
    @test PAIN.phase3_trim(; facing_side=:skin).sidewall.elements[1] isa PAIN.LimpMass
    @test_throws ErrorException PAIN.phase3_trim(; facing_side=:middle)
end
@testset "Si, Cin (Abramowitz & Stegun Table 5.1)" begin
    @test PAIN.sine_integral(1.0) ≈ 0.946083070367183 atol = 1e-14
    @test PAIN.sine_integral(10.0) ≈ 1.658347594218874 atol = 1e-13
    @test PAIN.sine_integral(-2.0) ≈ -PAIN.sine_integral(2.0)
    @test PAIN.sine_integral(1e4) ≈ π / 2 atol = 1e-3
    @test PAIN.cin(1.0) ≈ 0.5772156649015329 - 0.3374039229009681 atol = 1e-14       # γ + ln 1 − Ci(1)
    @test PAIN.cin(10.0) ≈ 0.5772156649015329 + log(10) + 0.04545643300445537 atol = 1e-12
    @test PAIN.cin(-3.0) == PAIN.cin(3.0)
    # the two branches meet at x = 4
    @test PAIN._si_cin(4 - 1e-12)[1] ≈ PAIN._si_cin(4.0)[1] atol = 1e-12
    @test PAIN._si_cin(4 - 1e-12)[2] ≈ PAIN._si_cin(4.0)[2] atol = 1e-12
    @test PAIN._sinc_pi(0.0) == 1 && isapprox(PAIN._sinc_pi(1.0), 0; atol=1e-15) && PAIN._sinc_pi(0.5) ≈ 2 / π
end
@testset "joint acceptances against 2-D quadrature of the diffuse-field definition" begin
    # j² = (1/ℓ²) ∫∫ sinc(k|u−u'|) ψ(u)ψ(u') du du' / ⟨ψ²⟩ on an unrolled length ℓ
    function jq(ψ, ℓ, k; N=500)
        h = ℓ / N; u = [(i - 0.5) * h for i in 1:N]
        ms = sum(ψ.(u) .^ 2) / N
        s = 0.0
        for x in u, y in u
            r = k * abs(x - y)
            s += (r < 1e-12 ? 1.0 : sin(r) / r) * ψ(x) * ψ(y)
        end
        return s * h^2 / ℓ^2 / ms
    end
    a = 0.508
    for (n, ka) in ((0, 0.7), (0, 3.0), (2, 1.5), (3, 3.2), (4, 2.0))
        k = ka / a
        @test PAIN.ring_joint_acceptance(n, ka, :psi; mode_normalized=true) ≈ jq(u -> cos(n * u / a), 2π * a, k) atol = 3e-3
        n ≥ 1 && @test PAIN.ring_joint_acceptance(n, ka, :phi; mode_normalized=true) ≈ jq(u -> sin(n * u / a), 2π * a, k) atol = 3e-3
    end
    @test PAIN.ring_joint_acceptance(2, 1.5, :psi) ≈ PAIN.ring_joint_acceptance(2, 1.5, :psi; mode_normalized=true) / 2
    @test PAIN.ring_joint_acceptance(0, 1e-5, :psi) ≈ 1 atol = 1e-8
    @test_throws ErrorException PAIN.ring_joint_acceptance(0, 1.0, :phi)
    @test_throws ErrorException PAIN.ring_joint_acceptance(1, 1.0, :x)
    L = 1.83
    for (M, kL) in ((1, 2.0), (3, 9.0), (2, 12.0))
        @test PAIN.axial_joint_acceptance(M, kL; mode_normalized=true) ≈ jq(z -> sin(M * π * z / L), L, kL / L) atol = 3e-3
    end
    @test PAIN._joint_I123(2, 0.0) == (0.0, 0.0, 0.0)
    I1, I2, I3 = PAIN._joint_I123(2, 2.0)
    @test I3 == 0.0                                                               # (n − ka) factor
end
@testset "loss factors (Eqs. 77–83)" begin
    inp = PAIN.noise_reduction_test_article_inputs()
    ac = inp.acoustic.modes[3]
    a, L, V, ω = inp.fuse.a, inp.L_c, PAIN.cabin_volume(inp), 2π * 400
    wall = sum(ac.phi_boundary .^ 2 .* (ac.theta_hi_rad .- ac.theta_lo_rad))
    r = PAIN.acoustic_loss_modal(ac, 0, ω, 2000.0; a, L, V, c0=340.0, ξ=0.1, ξ_e=0.0)
    @test r.N ≈ ω * 340 * PAIN.cabin_eps_3d(ac, 0) / V * 0.1 * (L / 2) * 2 * a * wall
    @test r.η_n ≈ r.N / 2000.0^2
    r2 = PAIN.acoustic_loss_modal(ac, 1, ω, 0.0; a, L, V, c0=340.0, ξ=0.1, ξ_e=0.3)
    @test r2.η_n == Inf && r2.N > 0
    @test PAIN.acoustic_loss_modal(ac, 1, ω, 1.0; a, L, V, c0=340.0, ξ=0.2, ξ_e=0.6).N ≈ 2r2.N   # linear in ξ, ξ_e
    η̄ = PAIN.acoustic_loss_average(ω; V=2.0, S=5.0, S_e=0.5, ξ=0.1, ξ_e=0.2)
    @test η̄ ≈ 8 * 340 / (4ω * 2) * (0.5 + 0.2)
    @test PAIN.absorption_from_loss_factor(η̄, ω; V=2.0, S=5.0) * 340 * 5 / (4ω * 2) ≈ η̄  # inverse of η̄ = ᾱcS/(4ωV)
    @test PAIN.structural_loss_vacuo(300.0) == 0.01
    @test PAIN.radiation_loss_factor(0.5, 1000.0; Abar=6.0, m=3.0) ≈ 2 * 1.225 * 1000 * 6 / (π * 3 * 340) * 0.5
    # Eq. (82) radicand = |C_w/(mω²) − iη_r|² (passivity form)
    Cw, m, ωr, ηr = complex(-2e5, 3e4), 3.0, 2π * 300, 0.02
    @test PAIN.structural_loss_with_trim(ηr, ωr, m, Cw) ≈ abs(Cw / (m * ωr^2) - im * ηr)
    @test PAIN.structural_loss_with_trim(ηr, ωr, m, 0.0im) ≈ ηr
    @test PAIN.structural_loss_with_trim(ηr, ωr, m, Cw; η_r_cap=0.01) == 0.01
    @test_throws ErrorException PAIN.structural_loss_with_trim(ηr, ωr, m, complex(0.0, ηr * m * ωr^2))
    # Eq. (83) at ω_n = ω_r: ρc²A²εf²/(M V N)
    @test PAIN.structural_loss_coupled(50.0, 900.0, 900.0, 0.3, 2.0, 1.5, 2.0, 4.0) ≈ 1.225 * 340^2 * 16 * 2 * 0.09 / (1.5 * 2) / 50
    @test PAIN.structural_loss_coupled(50.0, 900.0, 950.0, 0.3, 2.0, 1.5, 2.0, 4.0) < PAIN.structural_loss_coupled(50.0, 900.0, 900.0, 0.3, 2.0, 1.5, 2.0, 4.0)
end
