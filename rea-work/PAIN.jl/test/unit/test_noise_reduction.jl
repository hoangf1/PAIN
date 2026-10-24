# Unit tests: src/noise_reduction.jl (Phase 64). CR-3813 §3.3, Eqs. (17)–(18), pp. 21–23.
@testset "nr_b / nr_c / nr_D / nr_ln / nr_arctan" begin
    ωj, ηj, u = 900.0, 0.07, 7.3e5
    # u² + b u + c = (ω_j² − u)² + (η ω_j²)² (the resonance denominator in u = ω²)
    @test u^2 + PAIN.nr_b(ωj) * u + PAIN.nr_c(ωj, ηj) ≈ (ωj^2 - u)^2 + (ηj * ωj^2)^2 rtol = 1e-12
    # D_nr is the resultant of the two quadratics: Π over roots of poly_n of poly_r(root)
    bn, cn, br, cr = PAIN.nr_b(800.0), PAIN.nr_c(800.0, 0.05), PAIN.nr_b(1100.0), PAIN.nr_c(1100.0, 0.02)
    disc = sqrt(complex(bn^2 - 4cn))
    roots = ((-bn + disc) / 2, (-bn - disc) / 2)
    @test real(prod(r^2 + br * r + cr for r in roots)) ≈ PAIN.nr_D(bn, cn, br, cr) rtol = 1e-9
    ω, cω = 1000.0, 0.232
    up, dn = 1 + cω / 2, 1 - cω / 2
    poly(w) = w^4 + bn * w^2 + cn
    @test PAIN.nr_ln(ω, cω, bn, cn) ≈ log(poly(up * ω) / poly(dn * ω)) rtol = 1e-12
    @test PAIN.nr_arctan(ω, cω, 800.0, 0.0) == 0.0
    # d/dω' of atan((ω'² − ω_j²)/(η ω_j²)) integrated over the band: hand form with 2ω' edges
    at = atan(((up * ω)^2 - 800.0^2) / (0.05 * 800.0^2)) - atan(((dn * ω)^2 - 800.0^2) / (0.05 * 800.0^2))
    @test PAIN.nr_arctan(ω, cω, 800.0, 0.05) ≈ at rtol = 1e-12
end
@testset "nr_brace / nr_band_integral_closed against quadrature" begin
    for (ω, ωn, ηn, ωr, ηr) in ((1000.0, 950.0, 0.05, 1080.0, 0.02), (3000.0, 2000.0, 0.1, 3100.0, 0.3),
                                (500.0, 700.0, 0.01, 480.0, 0.04))
        cl = PAIN.nr_band_integral_closed(ω, 0.232, ωn, ηn, ωr, ηr)
        qd = PAIN.nr_band_integral_quad(ω, 0.232, ωn, ηn, ωr, ηr; N=200_000)
        @test cl ≈ qd rtol = 1e-5
        t = PAIN.nr_brace(ω, 0.232, ωn, ηn, ωr, ηr)
        @test t.brace / t.D_nr == cl
        @test t.b_n == PAIN.nr_b(ωn) && t.c_r == PAIN.nr_c(ωr, ηr)
    end
end
@testset "areas and mass-law factor" begin
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    θ0 = deg2rad(56.6)
    @test PAIN.coupling_area(fuse) ≈ 1.83 * (2 * 0.508 * sin(θ0) + 2 * 0.508 * (π - θ0)) rtol = 1e-12
    @test PAIN.cylinder_surface_area(0.508, 1.83) ≈ 2π * 0.508 * 1.83
    # (mA/4)² τ_ML with τ_ML = (2ρc/(mω))²: m cancels
    m, A, ω = 9.0, 4.2, 2π * 300
    @test PAIN.mass_law_factor(1.2, 343.0, A, ω) ≈ (m * A / 4)^2 * (2 * 1.2 * 343 / (m * ω))^2 rtol = 1e-12
end
@testset "acoustic_modes_in_band / crossover bands" begin
    inp = PAIN.noise_reduction_test_article_inputs()
    ac = inp.acoustic.modes[3]
    f3 = PAIN.cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, 1; c0=inp.c_int)
    @test PAIN.acoustic_modes_in_band(inp, f3; c_ω=1e-9) ≥ 1                  # a resonance at the centre is counted
    @test PAIN.acoustic_modes_in_band(inp, 5.0; c_ω=0.232) == 0                # nothing below the first mode
    @test PAIN.acoustic_modes_in_band(inp, 2000.0; c_ω=0.4) ≥ PAIN.acoustic_modes_in_band(inp, 2000.0; c_ω=0.2)
    V = PAIN.cabin_volume(inp)
    @test PAIN.volume_crossover_frequency_Hz(inp) ≈ 4.1 * inp.c_int / cbrt(V)
    @test PAIN.volume_crossover_frequency_Hz(inp; c0=300.0) ≈ 4.1 * 300 / cbrt(V)
    vb = PAIN.volume_crossover_band(inp)
    e = PAIN.third_octave_band_edges(vb.fc_Hz)
    @test vb.rule == :volume && e.lo ≤ vb.f_Hz ≤ e.hi
    @test PAIN.acoustic_crossover_band(inp).fc_Hz == vb.fc_Hz                # default is card 10 option a
    tm = PAIN.acoustic_crossover_band(inp; rule=:ten_modes)
    bs = PAIN.resolve_bands(inp)
    @test tm.n_modes ≥ 10
    @test tm.band_index == 1 || PAIN.acoustic_modes_in_band(inp, bs[tm.band_index - 1]) < 10   # lowest such band
    @test_throws ErrorException PAIN.acoustic_crossover_band(inp; rule=:other)
    @test PAIN.apply_η_r_cap(0.3, 0.15) == 0.15 && PAIN.apply_η_r_cap(0.1, 0.15) == 0.1 && PAIN.apply_η_r_cap(0.3, nothing) == 0.3
end
@testset "w_in_reverberant (Eq. 17) vs noise_reduction_band (Eq. 18)" begin
    inp = PAIN.noise_reduction_test_article_inputs()
    fc = 400.0
    w = PAIN.w_in_reverberant(inp, fc; p_bl2=1.0)
    nr = PAIN.noise_reduction_band(inp, fc)
    @test w.W_in ≈ sum(c.term for c in w.contributions) rtol = 1e-12
    # term-wise, Eq. 18 / Eq. 17 = 2ρc²ω/(V ω_n²) (the two printed prefactors; ⟨p_e²⟩ = ⟨p_bl²⟩/2)
    ratio = 0.0
    for c in w.contributions
        ac = inp.acoustic.modes[findfirst(m -> m.index == c.i, inp.acoustic.modes)]
        ωn = 2π * PAIN.cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, c.q; c0=inp.c_int)
        ratio += c.term * 2 * inp.ρ_int * inp.c_int^2 * w.ω / (w.V * ωn^2)
    end
    @test nr.ratio ≈ ratio rtol = 1e-9
    @test PAIN.w_in_reverberant(inp, fc; p_bl2=3.0).W_in ≈ 3w.W_in rtol = 1e-12
    @test nr.NR_dB ≈ -10log10(nr.ratio) && nr.hf_model == :eq18
    @test_throws ErrorException PAIN.noise_reduction_band(inp, fc; hf_model=:bad)
    hi = PAIN.noise_reduction_band(inp, 4000.0; hf_model=:eq19, crossover_fc=1000.0)
    @test hi.hf_model == :eq19 && hi.ratio ≈ 1 / hi.eq23_ratio
    @test hi.NR_dB ≈ PAIN.hf_pressure_ratio(inp, 4000.0).NR_dB
    sp = PAIN.noise_reduction_spectrum(inp; bands=[250.0, 400.0])
    @test length(sp.rows) == 2
    @test sp.rows[2].ratio ≈ nr.ratio rtol = 1e-12
end
