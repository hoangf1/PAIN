# Unit tests: src/hf_broadband.jl (Phase 64). CR-3813 Eqs. (19)–(24).
@testset "hf_absorbing_areas / hf_trim_areas" begin
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    ar = PAIN.hf_absorbing_areas(fuse)
    θ0 = deg2rad(56.6)
    @test ar.S_side ≈ 2 * 0.508 * (π - θ0) * 1.83 rtol = 1e-12
    @test ar.S_e ≈ PAIN.cabin_volume(fuse) / 1.83 rtol = 1e-12
    @test ar.S ≈ ar.S_side + 2ar.S_e
    inp = PAIN.noise_reduction_test_article_inputs()
    t = PAIN.hf_trim_areas(inp)
    @test t.A_t ≈ PAIN.coupling_area(inp.fuse)
    @test t.A′ == 0.0
    bare = PAIN._with_fields(inp; sidewall=nothing, endplates=nothing, mech=nothing)
    tb = PAIN.hf_trim_areas(bare)
    @test tb.A_t == 0.0
    @test tb.A′ ≈ PAIN.coupling_area(inp.fuse)
end
@testset "hf_structural_band / hf_band_loss_factors / hf_transmission_coeffs / hf_pressure_ratio" begin
    inp = PAIN.noise_reduction_test_article_inputs(; η_lining=1.0)
    fc = 500.0
    b = PAIN.hf_structural_band(inp, fc)
    lo, hi = 2π * fc * (1 - PAIN.C_OMEGA_THIRD_OCTAVE / 2), 2π * fc * (1 + PAIN.C_OMEGA_THIRD_OCTAVE / 2)
    inband = [m for m in inp.structural.modes if lo ≤ 2π * m.f_Hz ≤ hi]
    @test length(b.in_band) == length(inband)
    @test b.n_r ≈ length(inband) / (PAIN.C_OMEGA_THIRD_OCTAVE * 2π * fc) rtol = 1e-12
    j2(m) = PAIN.structural_joint_acceptance(m, 2π * fc; a=inp.fuse.a, L=inp.fuse.L, c0=inp.c_ext)
    @test b.sum_j2sq_below ≈ sum(j2(m)^2 for m in inp.structural.modes if 2π * m.f_Hz < lo) rtol = 1e-12
    lf = PAIN.hf_band_loss_factors(inp, fc, b)
    Abar = PAIN.cylinder_surface_area(inp.fuse.a, inp.fuse.L)
    @test lf.η_rad_ext ≈ 2 * inp.ρ_ext * 2π * fc * Abar / (π * inp.m_wall * inp.c_ext) * b.j2_mean rtol = 1e-12
    tc = PAIN.hf_transmission_coeffs(inp, fc)
    @test tc.τ ≈ tc.τ_f + tc.τ_R rtol = 1e-12
    pr = PAIN.hf_pressure_ratio(inp, fc)
    @test pr.ratio ≈ pr.num / pr.den rtol = 1e-12
    @test pr.NR_dB ≈ 10log10(pr.ratio) rtol = 1e-12
    @test PAIN.hf_broadband_band_p2(inp, fc, 2.0) ≈ 1.0 / pr.ratio rtol = 1e-12      # ⟨p_e²⟩ = ⟨p_bl²⟩/2
    @test PAIN.hf_broadband_band_p2(inp, fc, 0.0) == 0.0
end
@testset "hf_broadband_spectrum" begin
    rp = run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200.0, blocking=R2)
    sp = PAIN.hf_broadband_spectrum(rp.inputs; bpf_Hz=200.0, n_harmonics=5)
    b = PAIN.nearest_third_octave(1600.0, PAIN.resolve_bands(rp.inputs))
    p2 = PAIN.blocked_broadband_band_p2(rp.inputs, b, 200.0)
    @test sp.third_octave_SPL_dB[b] ≈ 10log10(PAIN.hf_broadband_band_p2(rp.inputs, b, p2) / 4e-10 + 1e-30) atol = 1e-9
end
