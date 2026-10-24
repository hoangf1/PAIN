# Unit tests: src/high_freq_tones.jl, src/loudest_point.jl, src/freefield_digitized.jl (Phase 64).
@testset "E[g] forms (CR-3813 pp. 17–20)" begin
    @test PAIN.g_resonance(1000.0, 1000.0, 0.05) ≈ 1 / 0.05^2
    @test PAIN.g_resonance(0.0, 1000.0, 0.05) ≈ 1 / (1 + 0.05^2)
    for (ω, η, Δω) in ((2000.0, 0.05, 400.0), (5000.0, 0.2, 1100.0), (800.0, 0.01, 180.0))
        @test PAIN.expected_g_closed(ω, η, Δω) ≈ PAIN.expected_g_quad(ω, η, Δω; N=200_000) rtol = 1e-6
        a = Δω / (η * ω)
        @test PAIN.expected_g_closed(ω, η, Δω) ≈ PAIN.expected_g_pi(ω, η, Δω) * 2atan(a) / π rtol = 1e-12
    end
    @test PAIN.expected_g_closed(2000.0, 1e-6, 400.0) ≈ PAIN.expected_g_pi(2000.0, 1e-6, 400.0) rtol = 1e-4   # η̄ω ≪ Δω
    @test PAIN.expected_g_closed(2000.0, 0.0, 400.0) == Inf && PAIN.expected_g_quad(2000.0, 0.1, 0.0) == Inf
    @test PAIN.tone_Q_H(1.2, 340.0, 4.0, 1.3, 1000.0, 0.5) ≈ 4 * (340 / 1.3)^2 * (1.2 * 340 * 4 / 2000)^2 * 0.5 * 1000.0^6
end
@testset "Eqs. (13)–(16) tone expected value" begin
    rp = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    inp = rp.inputs
    ωH = 2π * 500.0                                   # a band with both acoustic and Table D-1 modes
    band = PAIN.modes_in_tone_band(inp, ωH)
    @test band.Δω ≈ 0.232 * ωH
    @test all(band.lo ≤ m.ωn ≤ band.hi for m in band.ac_list) && all(band.lo ≤ m.ωr ≤ band.hi for m in band.st_list)
    @test !isempty(band.ac_list) && !isempty(band.st_list)
    bare = PAIN._with_fields(inp; sidewall=nothing, endplates=nothing, mech=nothing)
    la = PAIN.band_average_loss_factors(bare, ωH, PAIN.modes_in_tone_band(bare, ωH))
    @test la.η̄_n ≈ bare.η_n_bare
    @test la.η̄_r ≈ sum(PAIN.structural_η_r_prime(bare, m.st, m.ωr) for m in band.st_list) / length(band.st_list)
    ev = PAIN.tone_expected_value(inp, 3, ωH)
    evc = PAIN.tone_expected_value(inp, 3, ωH; use_pi_limit=false)
    κ(η) = 2atan(ev.Δω / (η * ωH)) / π
    @test evc.p2_eq15 ≈ ev.p2_eq15 * κ(ev.η̄_n) * κ(ev.η̄_r) rtol = 1e-9       # Eq. (14) closed E[g] vs π limit of Eq. (15)
    @test ev.p2 == ev.p2_eq16 && ev.n_n ≈ ev.N_n / ev.Δω
    inp4 = PAIN._with_fields(inp; amplitudes=2 .* inp.amplitudes)
    @test PAIN.tone_expected_value(inp4, 3, ωH).p2 ≈ 4ev.p2 rtol = 1e-12
    e0 = PAIN.tone_expected_value(bare, 3, 2π * 5.0)                            # empty band
    @test e0.p2 == 0.0
    @test keys(e0) == keys(ev)
    # Eq. (13) with every resonance at ω_H: g = 1/η̄², product of the sums
    wn = fill(ωH, length(band.ac_list)); wr = fill(ωH, length(band.st_list))
    s13 = PAIN.tone_eq13_sample(inp, 3, ωH, wn, wr)
    @test s13 > 0
    @test PAIN.tone_eq13_sample(inp4, 3, ωH, wn, wr) ≈ 4s13 rtol = 1e-12
    @test_throws ErrorException PAIN.tone_eq13_sample(inp, 3, ωH, wn[1:end-1], wr)
    @test PAIN.resolve_crossover_Hz(inp) == PAIN.acoustic_crossover_band(inp).fc_Hz
    @test PAIN.resolve_crossover_Hz(PAIN._with_fields(inp; crossover_band_Hz=800.0)) == 800.0
    pr = PAIN.tone_mean_square_pressure_pair(inp, 3, ωH; tone_model=:auto, crossover_Hz=400.0)
    @test pr.model == :eq15_16 && pr.p2 == pr.p2_eq15_16
    @test PAIN.tone_mean_square_pressure_pair(inp, 3, ωH; tone_model=:auto, crossover_Hz=2000.0).model == :eq8
    @test PAIN.tone_mean_square_pressure_pair(inp, 3, ωH).p2 == PAIN.tone_mean_square_pressure(inp, 3, ωH)
    @test_throws ErrorException PAIN.tone_mean_square_pressure_pair(inp, 3, ωH; tone_model=:x)
end
@testset "loudest point (Phase 42)" begin
    rp = run_pain_pipeline(; source=:e11, n_harmonics=2, bpf_Hz=200.0, blocking=R2)
    inp = PAIN._with_fields(rp.inputs; q_max=2)
    @test PAIN._cyl2d_NY(inp) == 10
    ip = PAIN.cabin_interior_points(inp; n_axial=9)
    @test sort(ip.X) ≈ sort(-ip.X) && sum(ip.wz) ≈ 1 && ip.z[end] ≈ inp.L_c
    @test all(hypot.(ip.X, ip.Y) .< inp.fuse.a)
    qp = PAIN.cabin_quadrature_points(inp; n_axial=9)
    @test sum(qp.wnode) ≈ 1 / inp.acoustic.modes[1].eps_n rtol = 1e-9              # Φ_G of the rigid mode / A_cab
    ac_a = first(m for m in inp.acoustic.modes if !m.symmetric)
    (m1, n1) = first(k for k in keys(ac_a.phi_nodes) if k[1] > 0)
    @test PAIN._phi_node_full(ac_a, -m1, n1) == -ac_a.phi_nodes[(m1, n1)]
    @test PAIN._phi_node_full(ac_a, 0, n1) == 0.0
    @test_throws ErrorException PAIN._phi_node_full(inp.acoustic.modes[1], 999, 0)
    @test PAIN.point_volume_average([1.0 3.0; 5.0 7.0], (; wz=[0.5, 0.5])) ≈ 4.0
    @test PAIN.point_volume_average([1.0 3.0; 5.0 7.0], (; wz=[0.5, 0.5], wnode=[0.25, 0.75])) ≈ 0.25 * 2 + 0.75 * 6
    # one acoustic mode, q = 0: the Φ_G-weighted average of |A φ_i|² is |A|²/ε_n, i.e. Eq. (8) exactly
    # (the multi-mode average carries discrete cross terms; its 1 % criterion is case LOUDEST_PT)
    one = PAIN.Cyl2DResult((f === :modes ? [inp.acoustic.modes[3]] : getfield(inp.acoustic, f) for f in fieldnames(PAIN.Cyl2DResult))...)
    i1 = PAIN._with_fields(inp; acoustic=one, q_max=0)
    qp1 = PAIN.cabin_quadrature_points(i1; n_axial=5)
    @test PAIN.point_volume_average(PAIN.point_tone_p2(i1, 1, 2π * 200.0; pts=qp1), qp1) ≈ PAIN.tone_mean_square_pressure(i1, 1, 2π * 200.0) rtol = 1e-9
    lp = PAIN.loudest_point(inp; bpf_Hz=200.0, n_harmonics=2, n_axial=9, broadband=false)
    @test lp.dBA_max ≥ lp.dBA_avg - 1e-9
    @test lp.dBA_max ≈ 10log10(maximum(lp.total_A) / 4e-10)
    w = PAIN._with_fields(inp; η_n_bare=0.123)
    @test w.η_n_bare == 0.123 && w.fuse === inp.fuse && w.amplitudes === inp.amplitudes
end
@testset "free-field digitized line (Fig. E-11)" begin
    @test PAIN.spl_dB_to_Pa(94.0) ≈ 20e-6 * 10^(94 / 20) atol = 1e-4
    @test PAIN.spl_dB_to_Pa(94.0) ≈ 1.0024 atol = 1e-4
    @test PAIN.spl_dB_to_peak_Pa(80.0) ≈ sqrt(2) * PAIN.spl_dB_to_Pa(80.0)
    @test PAIN.peak_Pa_to_spl_dB(PAIN.spl_dB_to_peak_Pa(87.3)) ≈ 87.3 atol = 1e-9   # cosine-peak ↔ rms SPL
    d = UNIT_OUT
    pa, pb = joinpath(d, "unit_e11_A.csv"), joinpath(d, "unit_e11_B.csv")
    write(pa, "# c\nk,SPL_H1_dB,SPL_H2_dB,SPL_H3_dB,note\n1,90,80,70,x\n2,91,81,71,y\n")
    write(pb, "k,SPL_H1_dB,SPL_H2_dB,SPL_H3_dB\n1,90.5,80,70\n2,91,79.2,71.1\n")
    c = PAIN._read_csv_numeric(pa)
    @test c[:SPL_H2_dB] == [80.0, 81.0] && !haskey(c, :note)                      # text column dropped
    δ, δH = PAIN.delta_dig_dB(pa, pb)
    @test δ ≈ 1.8 atol = 1e-12
    @test δH[1] ≈ 0.5 atol = 1e-12
    @test δH[3] ≈ 0.1 atol = 1e-12
    @test PAIN.delta_dig_dB(pa, pa)[1] == 0
    rm(pa); rm(pb)
    p = PAIN.default_e11_paths()
    @test all(isfile, (p.A, p.B, p.phases, p.anopp_spl))
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    prop = PAIN.PropellerPlacement(0.965, 90.0, 0.662)
    ff = PAIN.freefield_from_e11_csv(p.A, p.phases, fuse, prop)
    m = PAIN._read_csv_numeric(p.A); ph = PAIN._read_csv_numeric(p.phases)
    k1 = Int(m[:k][1])
    @test ff.amplitudes[k1, 1, 1] ≈ PAIN.spl_dB_to_peak_Pa(m[:SPL_H1_dB][1])
    @test ff.phases[k1, 1, 1] ≈ deg2rad(ph[:phase_H1_deg][findfirst(==(float(k1)), ph[:k])])
    fa = PAIN.freefield_from_e11_csv(p.A, p.phases, fuse, prop; anopp_spl_csv=p.anopp_spl)
    an = PAIN._read_csv_numeric(p.anopp_spl)
    @test fa.amplitudes[k1, 1, 3] ≈ PAIN.spl_dB_to_peak_Pa(an[:SPL_H3_dB][findfirst(==(float(k1)), an[:k])])   # H3 from Table 8
    fm = PAIN.freefield_from_e11_csv(p.A, p.phases, fuse, PAIN.PropellerPlacement(0.965, 90.0, 0.662, -1))
    @test fm.phases[k1, 1, 2] ≈ -ff.phases[k1, 1, 2]
    @test_throws ErrorException PAIN.freefield_from_e11_csv(p.A, p.phases, fuse, prop; grid_fill=:bad)
    @test_throws ErrorException PAIN.freefield_from_e11_csv(p.A, p.phases, fuse, prop; grid_fill=:f1a_relative)
end
