# Unit tests: src/mrp.jl and src/circular_cavity.jl (Phase 64).
@testset "Table D-1 modes and shapes (mrp.jl)" begin
    sm = PAIN.structural_modes_from_table_d1()
    @test length(sm.modes) == 32 && sm.modes[1].f_Hz == 188.52 && sm.modes[1].M_r == 1.13889
    @test length(PAIN.structural_modes_from_table_d1(; n_keep=5).modes) == 5
    row = PAIN.TABLE_D1_FULL[7]
    m7 = PAIN._mode_from_d1_row(row)
    @test m7.index == row[1] && m7.f_Hz == row[2] && m7.C_shell == PAIN._D1_SHAPES[7].C_shell
    # shapes: symmetric even about the bottom centreline, antisymmetric odd (Eqs. 46–49)
    s = first(m for m in sm.modes if m.symmetric); a = first(m for m in sm.modes if !m.symmetric)
    @test PAIN.shell_circumferential(s, 0.7) ≈ PAIN.shell_circumferential(s, 2π - 0.7)
    @test PAIN.shell_circumferential(a, 0.7) ≈ -PAIN.shell_circumferential(a, 2π - 0.7)
    one = PAIN.StructuralMode(1, 100.0, true, 1.0, 2, [0.5], [3], [0.4], [2])
    @test PAIN.shell_circumferential(one, 0.3) ≈ 0.5 * (-1)^3 * cos(0.9)
    @test PAIN.structural_shell_psi(one, 0.25, rad2deg(0.3), 1.0) ≈ sin(2π * 0.25) * 0.5 * (-1)^3 * cos(0.9)
    @test PAIN.structural_shell_psi(one, 1.0, 30.0, 1.0) ≈ 0 atol = 1e-12          # simply supported ends
    @test PAIN.structural_floor_psi(one, 0.25, 0.1, 1.0, 0.8) ≈ sin(π / 2) * 0.4 * cos(2π * 0.1 / 0.8)
    @test PAIN.structural_floor_psi(s, 0.3, 0.2, 1.83, 0.85) ≈ PAIN.structural_floor_psi(s, 0.3, -0.2, 1.83, 0.85)
    @test PAIN.structural_floor_psi(a, 0.3, 0.2, 1.83, 0.85) ≈ -PAIN.structural_floor_psi(a, 0.3, -0.2, 1.83, 0.85)
end
@testset "legacy Ritz (mrp.jl): limits and matching" begin
    E, ρ, t, a, L = 73.1e9, 2780.0, 0.001, 0.5, 1.0
    # n = 0, no bending stiffness: membrane breathing at the ring frequency ω² = E/(ρa²)
    @test PAIN._donnell_omega2(1, 0, L, a, 0.0, ρ * t, E, t) ≈ E / (ρ * a^2) rtol = 1e-12
    D = 1.3
    @test PAIN._floor_omega2(2, 3, 1.0, 0.8, D, 4.0; edge_factor=1.0) ≈ D / 4 * ((2π)^2 + (3π / 0.8)^2)^2   # SS Kirchhoff plate
    @test PAIN._floor_omega2(2, 0, 1.0, 0.8, D, 4.0; edge_factor=1.0) ≈ D / 4 * ((2π)^2 + (π / 1.6)^2)^2
    # matching Table D-1 against itself passes every mode exactly; a 10 % shift passes none at 5 %
    sm = PAIN.structural_modes_from_table_d1()
    np, pairs = PAIN.match_ritz_to_table_d1(sm)
    @test np == 32 && all(p.err == 0 for p in pairs)
    shifted = PAIN.StructuralModes([PAIN.StructuralMode(m.index, 1.1m.f_Hz, m.symmetric, m.M_r, m.M_axial, m.C_shell, m.n_shell, m.C_floor, m.n_floor) for m in sm.modes], sm.L, sm.a, sm.theta0_deg, "")
    @test PAIN.match_ritz_to_table_d1(shifted)[1] == 0
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    r = PAIN.structural_modes(fuse)
    @test length(r.modes) ≤ 48 && issorted([m.f_Hz for m in r.modes]) && all(m.f_Hz > 0 for m in r.modes)
    # the fitter returns a grid point and the npass that point gives (it is a legacy fit, not used by PAIN)
    b = PAIN.fit_mrp_to_table_d1(fuse; scales=0.6:0.05:0.65, edges=2.6:0.1:2.6, floor_scales=1.8:0.1:1.8)
    @test b.k_scale in (0.6, 0.65) && b.edge_factor == 2.6
    @test b.npass == PAIN.match_ritz_to_table_d1(PAIN.structural_modes(fuse; k_scale=b.k_scale, edge_factor=2.6, floor_scale=1.8, n_keep=48, hybrid=false))[1]
end
@testset "Bessel functions and J′ zeros (circular_cavity.jl)" begin
    @test PAIN._cav_besselj(0, 1.0) ≈ 0.7651976865579666 atol = 1e-14            # A&S Table 9.1
    @test PAIN._cav_besselj(1, 2.5) ≈ 0.4970941024642741 atol = 1e-14
    @test PAIN._cav_besselj(5, 3.0) ≈ 0.0430284348770477 atol = 1e-14
    @test PAIN._cav_besselj(-1, 2.5) ≈ -PAIN._cav_besselj(1, 2.5)
    @test PAIN._cav_besselj(0, 0.0) == 1 && PAIN._cav_besselj(2, 0.0) == 0
    @test PAIN._cav_besselj_prime(0, 1.3) ≈ -PAIN._cav_besselj(1, 1.3) atol = 1e-14
    @test PAIN._cav_besselj_prime(3, 2.2) ≈ (PAIN._cav_besselj(3, 2.2 + 1e-6) - PAIN._cav_besselj(3, 2.2 - 1e-6)) / 2e-6 atol = 1e-8
    @test PAIN._cav_besselj_prime(1, 0.0) == 0.5
    @test PAIN.besselj_prime_zeros(0, 3) ≈ [3.8317059702, 7.0155866698, 10.1734681351] atol = 1e-9
    @test PAIN.besselj_prime_zeros(1, 2) ≈ [1.8411837813, 5.3314427735] atol = 1e-9
    @test PAIN.besselj_prime_zeros(2, 1) ≈ [3.0542369282] atol = 1e-9
    @test isempty(PAIN.besselj_prime_zeros(1, 0))
    @test_throws ErrorException PAIN.besselj_prime_zeros(-1, 2)
end
@testset "circular cavity modes, normalization, coupling" begin
    # ε against quadrature of ∫φ² dV with φ = J_m(αr/R)/J_m(α) Θ Z, V = πR²L
    for (m, q) in ((0, 0), (1, 0), (2, 1), (3, 2))
        α = PAIN.besselj_prime_zeros(m, 1)[1]
        N = 4000; h = 1 / N
        Ir = h * sum((PAIN._cav_besselj(m, α * ((i - 0.5) * h)) / PAIN._cav_besselj(m, α))^2 * (i - 0.5) * h for i in 1:N)
        Iθ = m == 0 ? 2π : π
        Iz = q == 0 ? 1.0 : 0.5
        @test PAIN.circular_acoustic_eps(m, α, q) ≈ π / (Ir * Iθ * Iz) rtol = 1e-6
    end
    @test PAIN.circular_acoustic_eps(0, 0.0, 0) == 1 && PAIN.circular_acoustic_eps(0, 0.0, 3) == 2
    @test_throws ErrorException PAIN.circular_acoustic_eps(1, 0.0, 0)
    R, L = 0.254, 1.2
    md = PAIN.circular_cavity_modes(R, L; f_max_Hz=2000.0)
    @test issorted([m.f_Hz for m in md]) && all(m.f_Hz ≤ 2000 for m in md)
    @test md[1].f_Hz ≈ 343 / (2L) && md[1].m == 0 && md[1].k == 0                 # organ-pipe q = 1
    for m in md
        m.k > 0 && @test m.f_Hz ≈ 343 / 2π * sqrt((m.jprime / R)^2 + (m.q * π / L)^2) rtol = 1e-12
    end
    @test count(m -> m.m ≥ 1 && m.cos_family, md) == count(m -> m.m ≥ 1 && !m.cos_family, md)
    ac0 = first(m for m in md if m.m == 0 && m.q == 0 && m.k == 1)
    ac2 = first(m for m in md if m.m == 2 && m.q == 0 && m.cos_family)
    st0 = PAIN.StructuralMode(1, 500.0, true, 1.0, 1, [1.0], [0], Float64[], Int[])
    st2 = PAIN.StructuralMode(2, 500.0, true, 1.0, 1, [1.0], [2], Float64[], Int[])
    @test PAIN.circular_coupling_factor(ac0, st0, R, L) ≈ 2 / π                   # (1/L)∫sin = 2/π, full circle
    @test PAIN.circular_coupling_factor(ac2, st2, R, L) ≈ 1 / π                   # ∫cos² over 2πR = 1/2
    @test PAIN.circular_coupling_factor(ac2, st2, R, L; τ_t=0.25) ≈ 0.5 / π
    @test PAIN.circular_coupling_factor(ac0, st2, R, L) == 0
    st2a = PAIN.StructuralMode(3, 500.0, false, 1.0, 1, [1.0], [2], Float64[], Int[])
    @test PAIN.circular_coupling_factor(ac2, st2a, R, L) == 0
end
@testset "Donnell shell modes, η helpers, circular NR" begin
    E, ν, ρ, t, R, L = 73.1e9, 0.33, 2780.0, 1e-6, 0.254, 1.2
    @test PAIN.donnell_mushtari_frequency_Hz(1, 0, L, R, t, E, ν, ρ) ≈ sqrt(E / ρ) / (2π * R) rtol = 1e-6   # ring frequency
    sh = PAIN.donnell_shell_modes(R, L, 0.0008, E, ν, ρ; f_max_Hz=1500.0)
    @test issorted([m.f_Hz for m in sh.modes]) && all(m.f_Hz ≤ 1500 for m in sh.modes)
    for m in sh.modes
        @test m.f_Hz ≈ PAIN.donnell_mushtari_frequency_Hz(m.M_axial, m.n_shell[1], L, R, 0.0008, E, ν, ρ)
        @test m.M_r ≈ ρ * 0.0008 * π * R * L / (m.n_shell[1] == 0 ? 1 : 2)
    end
    @test PAIN.loglog_interp_eta(10.0, [100.0, 1000.0], [0.1, 0.01]) == 0.1
    @test PAIN.loglog_interp_eta(1e4, [100.0, 1000.0], [0.1, 0.01]) == 0.01
    @test PAIN.loglog_interp_eta(sqrt(1e5), [100.0, 1000.0], [0.1, 0.01]) ≈ sqrt(0.001)
    @test_throws ErrorException PAIN.loglog_interp_eta(1.0, Float64[], Float64[])
    p = joinpath(UNIT_OUT, "unit_reverb.csv")
    write(p, "# test\nkind,f_Hz,T60_s,eta\nshell,1000,0.1,0.02\nshell,100,1.0,0.2\ncavity,100,2.0,0.01\n")
    rows = PAIN._read_csv_mixed_kind_eta(p, "shell")
    @test rows.f == [100.0, 1000.0] && rows.η == [0.2, 0.02]
    @test PAIN.eta_from_reverberation_csv(p, "cavity", 500.0) == 0.01
    @test_throws ErrorException PAIN._read_csv_mixed_kind_eta(p, "floor")
    rm(p)
    ac = PAIN.circular_cavity_modes(R, L; f_max_Hz=1500.0)
    nr1 = PAIN.noise_reduction_band_circular(500.0, sh, ac; R, L, m_wall=2.2, η_n=0.02, η_r=0.01)
    nr2 = PAIN.noise_reduction_band_circular(500.0, sh, ac; R, L, m_wall=2.2, η_n=0.02, η_r=0.01, ρ_ext=2 * 1.225)
    @test nr2.ratio ≈ 4nr1.ratio rtol = 1e-12                                       # (mA/4)²τ_ML ∝ ρ_ext²
    @test nr1.NR_dB ≈ -10log10(nr1.ratio) && nr1.V ≈ π * R^2 * L
    sp = PAIN.noise_reduction_spectrum_circular(sh, ac, [500.0]; R, L, m_wall=2.2, η_n_of=f -> 0.02, η_r_of=f -> 0.01)
    @test sp.rows[1].ratio == nr1.ratio
end
