# Unit tests: helpers of the isolation and closing cases (src/validation_case_iso43.jl … iso62.jl) (Phase 64).
@testset "iso43: loss-factor inputs, T1 gates, TP-1964 setup" begin
    @test isfile(PAIN._iso43_data("cr3813", "t1_interior_targets.csv"))
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    e13 = PAIN._iso43_eta_n_from_e13(fuse)
    c = PAIN._read_csv_numeric(PAIN._iso43_data("cr3813", "e13_absorption_targets.csv"))
    f1, α1 = c[:f_Hz][1], c[:alpha_meas][1]
    @test e13.η_n_band[PAIN.nearest_third_octave(f1, PAIN.third_octave_centers())] ≈ 340 * e13.S * α1 / (4 * 2π * f1 * e13.V)   # η = c₀Sα/(4ωV)
    @test e13.S ≈ e13.S_side + 2 * e13.S_e
    p = joinpath(UNIT_OUT, "unit_eta.csv"); write(p, "f,eta\n1000,0.01\n100,0.1\n")
    d = PAIN._iso43_eta_from_csv_col(p, :f, :eta); rm(p)
    @test d[1000.0] ≈ 0.01 rtol = 0.02
    @test d[100.0 * 2^(1 / 3) |> PAIN.snap_third_octave_center] ≈ 0.1 * (100 * 2^(1 / 3) / 100)^(-1) rtol = 0.02   # log-log line
    er = PAIN._iso43_eta_r_from_e15_meas()
    @test Set(keys(er)) == Set(PAIN.third_octave_centers()) && all(v -> v > 0, values(er))
    tg = PAIN._iso43_t1_targets()
    @test length(tg.means) == 3 && all(tg.lo .≤ tg.means .≤ tg.hi)
    tab, n = PAIN._iso43_t1_gate_table(tg.means .+ [0.0, 4.5, 3.9], tg.means, tg.lo, tg.hi, tg.nasa)
    @test length(tab) ≥ 3 && n == 2 + ((tg.lo[2] ≤ tg.means[2] + 4.5 ≤ tg.hi[2]) && abs(tg.means[2] + 4.5 - tg.nasa[2]) ≤ 4)
    s = PAIN._iso43_tp1964_setup()
    @test s.m_wall ≈ 2710 * 0.00163 && all(m.f_Hz ≤ 6000 for m in s.structural.modes) && all(a.f_Hz ≤ 6000 for a in s.acoustic)
    @test s.η_n_of(1000.0) > 0 && s.η_r_of(1000.0) > 0
    hi = PAIN.tp1964_hf_inputs(s)
    @test hi.η_r_band_is_prime && hi.η_n_band[1000.0] ≈ s.η_n_of(1000.0) && hi.fuse.theta0_deg == 0.0
end
@testset "iso43/45: runners return their recorded shapes" begin
    r = PAIN._iso43_run_nr_tp1964(:meas)
    @test r isa PAIN.ValidationCaseResult && !isempty(r.table) && all(100 - 1e-9 ≤ t.x ≤ 5000 + 1e-9 for t in r.table)
    x = PAIN._iso45_run_nr_tp1964_xover(:meas)
    @test x isa PAIN.ValidationCaseResult && length(x.table) == length(r.table)
    rep = PAIN._iso43_repro_from_e12()
    @test length(rep) == 3 && all(isfinite, rep)
    co = PAIN._iso43_changeover_report()
    @test co isa NamedTuple
    g = PAIN._iso43_f1a_grid(; n_harmonics=1)
    @test size(g.amplitudes) == (16, 10, 1) && g.source == :ccblade_f1a
    out = PAIN.write_h3_attribution_report(joinpath(UNIT_OUT, "unit_h3.md"))
    @test occursin("# H3 attribution", read(something(out, joinpath(UNIT_OUT, "unit_h3.md")), String))
end
@testset "iso44: CR-172428 App. B field" begin
    @test endswith(replace(PAIN._r172428_csv("x.csv"), '\\' => '/'), "data/cr172428/x.csv")
    rpms = PAIN._r172428_rpms()
    @test !isempty(rpms) && all(r in (3000, 4000, 5000) for r in rpms)
    f = PAIN.r172428_appb_field(first(rpms))
    @test size(f.amps) == (16, 19, 3) && size(f.phases) == (16, 19, 3) && f.n_missing ≥ 0 && all(f.amps .≥ 0)
    lv = PAIN._r172428_levels()
    @test length(lv) == 3 * length(rpms)
    r1 = first(lv)
    @test r1.ours ≈ PAIN.interior_spl(PAIN.r172428_inputs(r1.rpm); bpf_Hz=3 * r1.rpm / 60, n_harmonics=3).harmonic_SPL_dB[r1.H]
end
@testset "iso47/48/50: narrowband → 1/3-octave, propeller-field NR" begin
    fq = collect(0.0:5.0:3000.0)
    flat = fill(60.0, length(fq))
    b = PAIN.narrowband_third_octave(fq, flat, 1000.0)
    nb = length(ceil(Int, 1000 * 2^(-1 / 6) / 5 - 1e-9):(ceil(Int, 1000 * 2^(1 / 6) / 5 - 1e-9) - 1))
    @test b.n_bins == nb
    @test b.L_total ≈ 60 + 10log10(nb) atol = 1e-9
    @test b.L_bb ≈ b.L_total atol = 1e-9   # flat: no tone
    tone = copy(flat); tone[findfirst(==(1000.0), fq)] = 90.0
    bt = PAIN.narrowband_third_octave(fq, tone, 1000.0; tone_Hz=[1000.0])
    @test bt.L_total > b.L_total + 5
    @test bt.L_bb ≈ b.L_bb atol = 1e-9                  # tone removed from the broadband part
    @test isnan(PAIN.narrowband_third_octave(fq[1:10], flat[1:10], 1000.0).L_total)  # no coverage
    @test PAIN._p47_tone_peaks([95.0, 100.0, 105.0, 190.0, 205.0], [1.0, 3.0, 2.0, 9.0, 4.0], 100.0, 2) == [100.0, 190.0]
    @test isfile(PAIN._p47_csv(:ext, 'A')) && isfile(PAIN._p47_csv(:f14, 'B'))
    @test_throws ErrorException PAIN._p47_csv(:other, 'A')
    @test PAIN._p47_fc(0) == 1000.0 && PAIN._p47_fc(-3) ≈ 500.0
    rows, pk = PAIN.p47_band_levels(:f14, [1000.0])
    @test length(rows) == 1 && length(pk) ≤ 8
    sl = PAIN._p47_fig14_slope()
    @test sl.S ≈ sl.rows[3].L_bb - sl.rows[1].L_bb
    inp = PAIN.r172428_inputs(4000)
    @test PAIN._p47_model_nr(inp, 2000.0).NR_dB == PAIN.noise_reduction_band(inp, 2000.0; crossover_fc=PAIN.volume_crossover_band(inp).fc_Hz, hf_model=:eq19).NR_dB
    @test PAIN.has_trim(PAIN._p47_phase3_inputs(inp))
    obs = (0.457, 0.0, -0.254)
    @test PAIN.p48_exterior_bands(5000, obs, [1000.0]).total == PAIN.propeller_broadband_spectrum(PAIN.p48_propeller_cfg(5000), PAIN._p48_af(), obs; freqs=[1000.0]).total
    fl = PAIN._p48_run_floor("UNIT_FLOOR", :f14, 5000, obs, 1:2)
    @test length(fl.table) == 2
    nr = PAIN.propeller_field_band_nr(inp, 400.0; n_freq=3)
    @test nr.p2 ≈ sum(f -> PAIN.tone_mean_square_pressure(inp, nr.H, 2π * f), nr.fs) / 3 && nr.NR_dB ≈ 10log10(nr.p2_ref / nr.p2)
    @test_throws ErrorException PAIN.propeller_field_band_nr(PAIN.noise_reduction_test_article_inputs(), 400.0)
end
@testset "iso62: printed-value comparison helpers" begin
    @test isfile(PAIN._p62_example("aircraft_scale_hartzell.json"))
    P = PAIN._p62_printed()
    @test P["cylinder_length"] == (1.83, 3, "E-1") && P["floor_angle_deg"][1] == 56.6
    @test PAIN._p62_round(0.66249, 3) == 0.662 && PAIN._p62_round(0.0, 3) == 0.0
    ok = PAIN._p62_compare("UNIT", [("cylinder_length", 1.8304), ("diameter", 1.016)], "unit")
    bad = PAIN._p62_compare("UNIT", [("cylinder_length", 1.803)], "unit")
    @test ok.verdict == :met && bad.verdict == :not_met && startswith(bad.reason, "criterion not met")
    r = PAIN._p62_result("UNIT", PAIN.ValidationTableRow[], PAIN.PlotSeries[], true, "fine", (; x=1))
    @test r.verdict == :met && r.reason == "fine" && r.inputs_echo.date == "2026-10-23"
end
@testset "iso87: App. B per-mode helpers (phases 87–89)" begin
    inp = PAIN.r172428_inputs(4000)
    @test PAIN._acmode_by_I(inp, 2).index == 2
    ac = PAIN._acmode_by_I(inp, 1)
    @test isnan(PAIN._eta_n_at_mode(inp, inp.acoustic.modes[1], 1))                 # 93.8 Hz, below the Fig. A-2 table
    η = PAIN._eta_n_at_mode(inp, ac, 1)                                               # 218 Hz
    ωn = 2π * PAIN.cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, 1; c0=inp.c_int)
    @test η > 0 && η ≈ PAIN.acoustic_N(inp, ac, 1, ωn / 2π, ωn;
        ξ=PAIN.trim_conductance(inp.sidewall, ωn, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int),
        ξ_e=PAIN.trim_conductance(inp.endplates, ωn, Inf; ρ0=inp.ρ_int, c0=inp.c_int), V=PAIN.cabin_volume(inp)) / ωn^2
    st = inp.structural.modes[6]; a19 = PAIN._acmode_by_I(inp, 4)                     # App. B pair 19 (Q2, I4) × 6
    a = PAIN._eta_r_pp_pair(inp, a19, 2, st, 250.0); b = PAIN._eta_r_pp_pair(inp, a19, 2, st, 400.0)
    @test a > 0 && b > 0 && a != b                                                    # N taken at the tone frequency
end
