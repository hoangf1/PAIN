# Unit tests: src/pain_core.jl (Phase 64). Closed forms against quadrature, identities and hand values.
_quad(f, a, b; N=20_000) = (h = (b - a) / N; h * sum(f(a + (i - 0.5) * h) for i in 1:N))

@testset "axial integrals against quadrature" begin
    for (a, b) in ((2.0, 3.0), (1.5, 1.5), (1.5, -1.5), (0.0, 2.0), (2.0, 0.0))
        @test PAIN._int_cos_sin(a, b, 0.1, 0.9) ≈ _quad(z -> cos(a * z) * sin(b * z), 0.1, 0.9) atol = 1e-8
        @test PAIN._int_sin_sin(a, b, 0.1, 0.9) ≈ _quad(z -> sin(a * z) * sin(b * z), 0.1, 0.9) atol = 1e-8
    end
    L, Lc, d = 1.83, 1.5, 0.2
    for (q, M) in ((0, 1), (1, 2), (2, 1), (3, 3))
        ref = _quad(z -> cos(q * π * (z - d) / Lc) * sin(M * π * z / L), d, d + Lc)
        @test PAIN._axial_overlap_integral(q, M, L, Lc, d, d, d + Lc) ≈ ref atol = 1e-8
        @test PAIN.axial_coupling(q, M; L, L_c=Lc, d) ≈ ref / L atol = 1e-8
        # printed Eq. (57) branch (L = L_c, d = 0) against quadrature
        @test PAIN.axial_coupling(q, M; L=L) ≈ _quad(z -> cos(q * π * z / L) * sin(M * π * z / L), 0, L) / L atol = 1e-8
    end
    @test PAIN.axial_coupling(0, 1; L=2.0) ≈ 2 / π                              # (1/L)∫ sin(πz/L) dz
    @test PAIN.axial_coupling(1, 1; L=2.0) == 0.0
    @test PAIN.axial_coupling(1, 1; L=1.0, L_c=1.0, d=5.0) == 0.0               # no overlap
end
@testset "coupling integrals and coupling_factor" begin
    inp = PAIN.noise_reduction_test_article_inputs()
    a = inp.fuse.a
    Lp = 2a * sind(inp.fuse.theta0_deg)
    ψs(st, θ) = sum(st.symmetric ? C * (-1)^n * cos(n * θ) : -C * (-1)^n * sin(n * θ) for (C, n) in zip(st.C_shell, st.n_shell))
    ψp(st, x) = sum(st.symmetric ? C * cos(n * π * x / Lp) : C * sin(n * π * x / Lp) for (C, n) in zip(st.C_floor, st.n_floor) if st.symmetric || n > 0; init=0.0)
    ac_s = first(m for m in inp.acoustic.modes if m.symmetric && m.index > 1)
    ac_a = first(m for m in inp.acoustic.modes if !m.symmetric)
    for st in inp.structural.modes[1:6]
        ac = st.symmetric ? ac_s : ac_a
        Is = sum(_quad(θ -> a * ψs(st, θ) * ac.phi_boundary[j], ac.theta_lo_rad[j], ac.theta_hi_rad[j]; N=400) for j in eachindex(ac.phi_boundary))
        @test PAIN.coupling_shell_integral(ac, st, a) ≈ Is rtol = 1e-6
        Ip = sum(_quad(x -> ψp(st, x) * ac.phi_floor[j], a * ac.x_lo_unit[j], a * ac.x_hi_unit[j]; N=400) for j in eachindex(ac.phi_floor))
        @test PAIN.coupling_floor_integral(ac, st, a, Lp) ≈ Ip rtol = 1e-6 atol = 1e-12
        other = st.symmetric ? ac_a : ac_s
        @test PAIN.coupling_shell_integral(other, st, a) == 0.0 && PAIN.coupling_floor_integral(other, st, a, Lp) == 0.0
        fp = PAIN.coupling_factor(ac, st, inp.fuse)
        fm = PAIN.coupling_factor(ac, st, inp.fuse; floor_sign=-1)
        ax = PAIN.axial_coupling(0, st.M_axial; L=inp.fuse.L)
        den = Lp + 2a * (π - deg2rad(inp.fuse.theta0_deg))
        @test fp ≈ ax * (Is + Ip) / den rtol = 1e-6 atol = 1e-12
        @test fp - fm ≈ 2ax * Ip / den rtol = 1e-6 atol = 1e-12
        @test abs(fp) ≤ 1
        @test PAIN.coupling_factor(ac, st, inp.fuse; τ_t=0.25) ≈ ax * (0.5Is + Ip) / den rtol = 1e-6 atol = 1e-12
        @test PAIN.coupling_factor(ac, st, inp) == PAIN.coupling_factor(ac, st, inp.fuse; L_c=inp.L_c, d=inp.d)
    end
    @test_throws ErrorException PAIN.coupling_factor(ac_s, inp.structural.modes[1], inp.fuse; floor_sign=2)
end
@testset "generalized force (Eq. 42) and joint acceptance" begin
    inp = PAIN.noise_reduction_test_article_inputs()
    st = inp.structural.modes[1]
    amps = ones(16, 10, 1); ph = zeros(16, 10, 1)
    ψsum = sum(PAIN.structural_shell_psi(st, p.z, p.theta_deg, inp.fuse.L) for p in inp.pts)
    sc, ss = PAIN.generalized_force_sums(st, 1, amps, ph, inp.pts, inp.fuse)
    @test sc ≈ ψsum
    @test ss ≈ 0 atol = 1e-12
    Ψ = PAIN.generalized_force(st, 1, amps, ph, inp.pts, inp.fuse; ΔA=inp.ΔA)
    @test Ψ ≈ inp.ΔA^2 / 2 * ψsum^2
    @test PAIN.generalized_force_amplitude(st, 1, amps, ph, inp.pts, inp.fuse; ΔA=inp.ΔA) ≈ sqrt(2Ψ)
    # a common phase shift leaves Ψ_G unchanged; doubling the amplitudes multiplies it by 4
    @test PAIN.generalized_force(st, 1, amps, ph .+ 0.7, inp.pts, inp.fuse; ΔA=inp.ΔA) ≈ Ψ
    @test PAIN.generalized_force(st, 1, 2amps, ph, inp.pts, inp.fuse; ΔA=inp.ΔA) ≈ 4Ψ
    A2 = fill(2.0, 2, 2, 1)
    @test PAIN.joint_acceptance(0.5, A2, 1, 0.1) ≈ 0.25 / (4 * 0.4^2)          # Ψ²/(⟨A²⟩ area²)
    @test PAIN.joint_acceptance(100.0, A2, 1, 0.1) == 1.0                       # clamped
end
@testset "tone_mean_square_pressure scaling" begin
    rp = run_pain_pipeline(; source=:e11, n_harmonics=2, bpf_Hz=200.0, blocking=R2)
    inp = rp.inputs
    p1 = PAIN.tone_mean_square_pressure(inp, 1, 2π * 200.0)
    inp2 = PAIN._with_fields(inp; amplitudes=2 .* inp.amplitudes)
    @test PAIN.tone_mean_square_pressure(inp2, 1, 2π * 200.0) ≈ 4p1 rtol = 1e-12     # ⟨p²⟩ ∝ Ψ_G ∝ A²
    s = PAIN.interior_spl(inp; bpf_Hz=200.0, n_harmonics=2, broadband=false)
    @test s.harmonic_SPL_eq8_dB[1] ≈ 10log10(p1 / 4e-10 + 1e-30) atol = 1e-9
    @test occursin("tonal-only", s.notes)
    @test_throws ErrorException PAIN.interior_spl(inp; bpf_Hz=200.0, broadband_model=:bad)
    sb = PAIN.interior_spl(inp; bpf_Hz=200.0, n_harmonics=2, broadband_model=:eq19)
    @test haskey(sb.third_octave_SPL_dB, 2000.0 * 2^(1 / 3) |> PAIN.snap_third_octave_center)
end
@testset "volume, rotation phases, trim switches" begin
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    θ0 = deg2rad(56.6)
    @test PAIN.cabin_volume(fuse) ≈ 0.508^2 * 1.83 * (π - θ0 + cos(θ0) * sin(θ0))
    # equals the circle area minus the segment below the floor, times L
    seg = 0.508^2 / 2 * (2θ0 - sin(2θ0))
    @test PAIN.cabin_volume(fuse) ≈ (π * 0.508^2 - seg) * 1.83 rtol = 1e-12
    @test PAIN.cabin_volume(fuse; L_c=1.0) ≈ PAIN.cabin_volume(fuse) / 1.83
    ph = [0.1, -0.2]
    @test PAIN.apply_rotation_direction_phases!(copy(ph), 1) == ph
    @test PAIN.apply_rotation_direction_phases!(copy(ph), -1) == -ph
    @test_throws ErrorException PAIN.apply_rotation_direction_phases!(copy(ph), 0)
    inp = PAIN.noise_reduction_test_article_inputs()
    bare = PAIN._with_fields(inp; sidewall=nothing, endplates=nothing, mech=nothing)
    @test PAIN.has_trim(inp) && !PAIN.has_trim(bare)
    @test PAIN.sidewall_tau(bare, 1000.0) == 1.0
    @test PAIN.sidewall_tau(inp, 2π * 1000) ≈ PAIN.trim_tau(inp.sidewall, 2π * 1000; mech=inp.mech, allow_extrapolation=true)
end
@testset "broadband helpers" begin
    rp = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    inp = rp.inputs
    # adjacent exact 1/3-octave bands add up to the integral over their union (closed form, α = 2)
    fc = 1000.0
    p_lo = PAIN.blocked_broadband_band_p2(inp, fc, 200.0)
    p_hi = PAIN.blocked_broadband_band_p2(inp, fc * 2^(1 / 3), 200.0)
    A3 = inp.amplitudes[:, :, 3]
    S = sum(abs2, A3) / length(A3) / (0.232 * 2π * 600)
    f1, f2 = fc * 2^(-1 / 6), fc * 2^(1 / 2)
    @test p_lo + p_hi ≈ S * 600^2 * 2π * (1 / f1 - 1 / f2) rtol = 1e-12
    @test PAIN.blocked_broadband_band_p2(inp, fc, 200.0; α=1.0) ≈ PAIN.blocked_broadband_band_p2(inp, fc, 200.0; α=1.0 + 1e-7) rtol = 1e-5
    sm = inp.structural
    df = 0.2316 * 500
    n = count(m -> 500 - df / 2 ≤ m.f_Hz ≤ 500 + df / 2, sm.modes)
    @test n ≥ 1 && PAIN.structural_modal_density(sm, 500.0) ≈ n / (2π * df)
    @test PAIN.structural_modal_density(sm, 20.0) ≈ 0.015 * sm.a * sm.L * (20 / 500) / 2π    # fallback, no mode in band
    @test PAIN.band_joint_acceptance(inp, 20.0) == 2.5e-4
    @test 1e-6 ≤ PAIN.band_joint_acceptance(inp, 500.0) ≤ 1
    # Phase 81b: the 1e-6 floor engages when the raw band mean is below it (pressure with no projection: all zero)
    z = PAIN.PainInputs(inp.fuse, inp.prop, inp.structural, inp.acoustic, zero(inp.amplitudes), inp.phases, inp.pts, inp.ΔA)
    @test PAIN.band_joint_acceptance(z, 500.0) == 1e-6
    @test PAIN.broadband_cabin_p2(inp, 2000.0, 0.0) == 0.0
    @test PAIN.broadband_cabin_p2(inp, 2000.0, 2.0) ≈ 2PAIN.broadband_cabin_p2(inp, 2000.0, 1.0)
end
@testset "band sets and loss-factor cards (Manual cards 3–6, 11–18)" begin
    c = PAIN.third_octave_centers()
    @test length(c) == 22 && 1000.0 in c && all(c[2:end] ./ c[1:end-1] .≈ 2^(1 / 3))
    @test length(PAIN.standard_third_octave_centers()) == 37
    @test PAIN.third_octave_band_edges(1000.0) == (lo=1000 * (1 - 0.116), hi=1000 * (1 + 0.116))
    @test PAIN.snap_third_octave_center(1012.0) == 1000.0 && PAIN.snap_third_octave_center(1100.0) === nothing
    @test PAIN.validate_band_set([1000, 1250, 1600]) ≈ [1000, 1000 * 2^(1 / 3), 1000 * 2^(2 / 3)]
    @test_throws ErrorException PAIN.validate_band_set(Float64[])
    @test_throws ErrorException PAIN.validate_band_set(fill(1000.0, 27))
    @test_throws ErrorException PAIN.validate_band_set([1100.0])
    @test_throws ErrorException PAIN.validate_band_set([1250.0, 1000.0])
    @test PAIN.containing_third_octave(1100.0, [1000.0, 1259.9]) == 1000.0
    @test PAIN.containing_third_octave(50.0, [63.0, 80.0]) === nothing
    @test PAIN._η_key_hz("1000") == 1000.0 && PAIN._η_key_hz(500) == 500.0
    d = PAIN._normalize_η_dict(Dict("1000" => 0.02, 500.0 => 0.0), nothing; label="x")
    @test d == Dict(1000.0 => 0.02)                                             # zero = compute, dropped
    @test PAIN._normalize_η_dict(Dict(1000.0 => 0.0), nothing; label="x") === nothing
    @test_throws ErrorException PAIN._normalize_η_dict(Dict(1000.0 => -0.1), nothing; label="x")
    @test_throws ErrorException PAIN._normalize_η_dict([0.1], nothing; label="x")
    @test_throws ErrorException PAIN._normalize_η_dict([0.1, 0.2], [1000.0]; label="x")
    @test_throws ErrorException PAIN._normalize_η_dict("bad", nothing; label="x")
    b, ηr, ηn = PAIN.normalize_band_card_inputs([1000.0, 1250.0], [0.03, 0.0], nothing)
    @test b[1] == 1000.0 && ηr == Dict(1000.0 => 0.03) && ηn === nothing
    @test PAIN.loss_factor_override(ηr, 1050.0, b) == 0.03
    @test PAIN.loss_factor_override(ηr, 1250.0, b) === nothing                   # band present, value 0 → compute
    @test PAIN.loss_factor_override(nothing, 1000.0, b) === nothing
end
@testset "η_r′, η_n, App. A modal mass" begin
    inp = PAIN.noise_reduction_test_article_inputs()
    bare = PAIN._with_fields(inp; sidewall=nothing, endplates=nothing, mech=nothing)
    st = inp.structural.modes[2]
    ωr = 2π * st.f_Hz
    Ab = PAIN.cylinder_surface_area(inp.fuse.a, inp.fuse.L)
    tot = PAIN.structural_loss_total(st, ωr; a=inp.fuse.a, L=inp.fuse.L, m=inp.m_wall, C=inp.C_struc, ρ0=inp.ρ_ext, c0=inp.c_ext, Abar=Ab)
    @test PAIN.structural_η_r_prime(bare, st, ωr) ≈ tot
    @test PAIN.structural_η_r_prime(bare, st, ωr; η_r_cap=tot / 2) ≈ tot / 2
    fc = PAIN.containing_third_octave(st.f_Hz, PAIN.third_octave_centers())
    ov = PAIN._with_fields(inp; η_r_band=Dict(fc => 0.2), η_r_band_is_prime=true)
    @test PAIN.structural_η_r_prime(ov, st, ωr) == 0.2                          # measured η_r′: no Eq. 82
    @test PAIN.structural_η_r_prime(ov, st, ωr; η_r_cap=0.15) == 0.15
    @test PAIN.structural_η_r_prime(inp, st, ωr) > tot                           # trim adds damping (Eq. 82)
    # single-term shell shape C₀ = 1, n = 0: ∫ψ² dθ = 2π, so M_r^X = m · 2π · a L / 2
    one = PAIN.StructuralMode(1, 300.0, true, 2.0, 1, [1.0], [0], Float64[], Int[])
    @test PAIN.trimmed_modal_mass(one, inp.fuse, 10.0) ≈ 10 * 2π * inp.fuse.a * inp.fuse.L / 2 rtol = 1e-12
    @test PAIN.app_a_modal_mass_per_area(one, inp.fuse, 10.0) ≈ 10 * 2.0 / PAIN.trimmed_modal_mass(one, inp.fuse, 10.0)
    @test PAIN.app_a_modal_mass_per_area(PAIN.StructuralMode(1, 300.0, true, 2.0, 1, [0.0], [0], Float64[], Int[]), inp.fuse, 10.0) == Inf
    ac = inp.acoustic.modes[2]
    @test PAIN.acoustic_N(bare, ac, 0, 500.0, 2000.0) ≈ bare.η_n_bare * 2000.0^2
    on = PAIN._with_fields(bare; η_n_band=Dict(500.0 => 0.3))
    @test PAIN.acoustic_N(on, ac, 0, 500.0, 2000.0) ≈ 0.3 * 2000.0^2
    @test PAIN.resolve_η_n_band(bare, 500.0; V=1.0, S=1.0, S_e=1.0) == bare.η_n_bare
    @test PAIN.resolve_η_n_band(on, 500.0; V=1.0, S=1.0, S_e=1.0) == 0.3
    @test PAIN.resolve_η_n_band(inp, 500.0; V=1.0, S=2.0, S_e=0.5, ξ=0.1, ξ_e=0.2) ≈
          PAIN.acoustic_loss_average(2π * 500; V=1.0, S=2.0, S_e=0.5, ξ=0.1, ξ_e=0.2, c0=inp.c_int)
end
@testset "acoustic_N_per_mode (Phase 89 option)" begin
    inp = PAIN.r172428_inputs(4000)
    ac = inp.acoustic.modes[3]; V = PAIN.cabin_volume(inp)
    ωn = 2π * PAIN.cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, 0; c0=inp.c_int)
    fc = PAIN.nearest_third_octave(ωn / 2π, PAIN.third_octave_centers())
    ξ = PAIN.trim_conductance(inp.sidewall, 2π * fc, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int)
    ξe = PAIN.trim_conductance(inp.endplates, 2π * fc, Inf; ρ0=inp.ρ_int, c0=inp.c_int)
    @test PAIN.acoustic_N_per_mode(inp, ac, 0, ωn; V) ≈ PAIN.acoustic_N(inp, ac, 0, ωn / 2π, ωn; ξ, ξ_e=ξe, V) rtol = 1e-12
    @test PAIN.acoustic_N_per_mode(inp, inp.acoustic.modes[1], 0, 0.0; V) == 0.0     # rigid mode: N = η ω_n² = 0
end
