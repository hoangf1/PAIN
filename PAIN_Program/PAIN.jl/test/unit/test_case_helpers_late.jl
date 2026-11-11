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
    @test (r1.rpm, r1.H, r1.nasa, r1.measured) == (3000, 1, 63.3, 81.0)          # App. B / Table 10 and Table 5, as transcribed
    # the levels are the tone sum as CR-3813 prints it (R172428_CODE, Phase 93), not the code's default form (Phases 93–96)
    inp = PAIN.r172428_inputs(r1.rpm)
    spl(i) = PAIN.interior_spl(i; bpf_Hz=3 * r1.rpm / 60, n_harmonics=3).harmonic_SPL_dB[r1.H]
    @test r1.ours ≈ spl(PAIN._with_fields(inp; q0_coupled=true, η_n_per_mode=false, η_n_band_omega=true))
    @test abs(r1.ours - spl(inp)) > 1                                                # the pin matters: the default form differs
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
@testset "iso90: Report 996 Fig. 10 helpers (phase 90)" begin
    d = PAIN._r996_fig10()
    @test sort(collect(keys(d))) == ["circular_wall", "flat_wall", "free_space"]
    @test length(d["free_space"]) == 11 && length(d["flat_wall"]) == 5 && length(d["circular_wall"]) == 5
    @test PAIN._r996_fig10_gamma_deg(0.0) == 0.0
    @test PAIN._r996_fig10_gamma_deg(-0.25) ≈ rad2deg(atan(0.25 / 0.583)) && PAIN._r996_fig10_gamma_deg(0.25) == PAIN._r996_fig10_gamma_deg(-0.25)
end
@testset "iso92/94: App. B printed pairs, pair terms, Table 12" begin
    @test abs(PAIN._dB_re20μPa(4e-10)) < 1e-12 && PAIN._dB_re20μPa(4e-8) ≈ 20
    pp = PAIN._appb_printed_pairs()
    @test length(pp) == 25 && count(r -> r.rpm == 4000, pp) == 15                   # 5 pairs at 4000 rpm H1–H3, 5000 rpm H1–H2
    @test pp[1] == (rpm=4000, H=1, Q=2, I=0, st=13, η_r_hash=0.0, p2=1.5586e-2)        # p. 207, first row
    on = PAIN._r172428_pair_terms(4000, 1); off = PAIN._r172428_pair_terms(4000, 1; q0_coupled=false)
    @test any(t -> t.q == 0 && t.p2 > 0, on) && all(t -> t.q != 0 || t.p2 == 0, off)  # Eq. (57) q = 0 coupling switch
    t12 = PAIN._r172428_table12()
    @test length(t12[:rpm]) == 12 && (t12[:rpm][1], t12[:H][1], t12[:nasa_pred_dB][1], t12[:measured_dB][1]) == (3000, 1, 62.1, 81.0)
end
@testset "iso96/99: η_n band-centre rule, pre-correction band form" begin
    inp = PAIN.r172428_inputs(4000); V = PAIN.cabin_volume(inp)
    ac = PAIN._acmode_by_I(inp, 1)
    ωn = 2π * PAIN.cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, 1; c0=inp.c_int, c2d=inp.c_cyl2d)
    fc = max(100.0, PAIN.nominal_band_centre(ωn / 2π))
    ξ = PAIN.trim_conductance(inp.sidewall, 2π * fc, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int)
    ξe = PAIN.trim_conductance(inp.endplates, 2π * fc, Inf; ρ0=inp.ρ_int, c0=inp.c_int)
    tr(s, e) = Dict(:f_Hz => [fc], :side_adm_re => [s], :end_adm_re => [e])
    η(s, e) = PAIN._eta_n_nasa_admittance(inp, ac, 1, tr(s, e); V)
    @test η(ξ, ξe) ≈ PAIN._eta_n_default(inp, ac, 1; V) rtol = 1e-12                  # same admittance → same η_n
    @test η(0.0, 0.0) == 0 && η(2ξ, 0.0) ≈ 2η(ξ, 0.0) && η(ξ, ξe) > η(ξ, 0.0)         # Eq. (77) linear in ξ, ξ_e
    b = PAIN._pre_correction_band(PAIN._with_fields(inp; floor_sign=1.0, η_r_trimmed_area=true, η_n_per_mode=false,
                                                    η_n_band_omega=false))
    @test b.floor_sign == -1.0 && !b.η_r_trimmed_area && b.q0_coupled && b.η_n_per_mode && b.η_n_band_omega
end
@testset "iso100/101: App. D PF-105 admittances, Merlin MRP deck, App. C mode list, mass parts" begin
    dk = PAIN._appb_admittance_rows(:deck); fg = PAIN._appb_admittance_rows(:fig_a2)
    @test length(dk) == 4 * 21 && first(dk).f == 50 && length(fg) == 4 * 18 && first(fg).f == 100   # Fig. A-2 starts at 100 Hz
    @test dk[1].q == "sidewall Re β" && dk[1].nasa == 0.073537 && dk[4].q == "end-cap Im β" && dk[4].nasa == -0.017163  # p. 197
    inp = PAIN.r172428_inputs(4000; insulation=:deck)
    @test dk[1].ours ≈ real(PAIN.trim_admittance(inp.sidewall, 2π * 50, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int))
    @test dk[1].rel ≈ dk[1].ours / dk[1].nasa - 1
    g = PAIN.merlin_mrp_deck()                                                        # App. C pp. 204–205
    @test (g.L, g.a, g.theta0_deg, g.t_shell, g.m_shell, g.m_floor) == (9.27, 0.84, 50.0, 0.00164, 4.54, 13.66)
    @test g.Dp_stringers == 2712.0 && g.Dp_floor_beams == 1.57e5
    c = PAIN._appc_mode_rows("appC_merlin_structural_modes.csv")
    @test length(c.mode) == 221 && (c.mode[1], c.f_Hz[1], c.types[1], c.M[1], c.M_total_kg[1]) == (1, 39.60, "S", 1, 137.89)
    @test c.types[2] == "A" && c.f_Hz[2] == 56.82
    # ψ_s = cos 2θ (∫ψ² dθ = π) and a uniform floor (ψ_p = 1), then a cos(πx/L_p) floor (mean square ½)
    Lp = 2 * 0.84 * sind(50)
    m1 = PAIN._mode_mass_parts(PAIN.StructuralMode(1, 100.0, true, 1.0, 1, [1.0], [2], [1.0], [0]), g)
    @test m1.shell ≈ 4.54 * π * 0.84 * 9.27 / 2 rtol = 1e-6
    @test m1.plate ≈ 13.66 * Lp * 9.27 / 2 rtol = 1e-9
    m2 = PAIN._mode_mass_parts(PAIN.StructuralMode(1, 100.0, true, 1.0, 1, Float64[], Int[], [1.0], [1]), g)
    @test m2.shell == 0
    @test m2.plate ≈ m1.plate / 2 rtol = 1e-6
end
@testset "iso102/105/108: flight run 10 field and inputs, printed 2-D lists, run 10 pair η_r″" begin
    f = PAIN.r172428_flight10_field()
    @test size(f.amps) == (16, 19, 4) && all(iszero, f.amps[:, :, 1])               # H1 cut off in the scan
    @test f.amps[1, 1, 2] ≈ sqrt(2) * 20e-6 * 10^(108.9 / 20) && f.phases[1, 1, 2] ≈ deg2rad(-150.3)   # App. D p. 231, L 1, k 1
    p1 = f.pts[1]; p10 = f.pts[10]
    @test (p1.k, p1.ell, p1.theta_deg, p1.alpha_deg) == (1, 1, -15.0, 90.0) && p1.x3 ≈ 1.12 - 0.094
    @test (p10.ell, p10.theta_deg, p10.alpha_deg) == (10, 75.0, 0.0)                 # propeller line at L = 10
    inp = PAIN.r172428_flight10_inputs()
    @test (inp.fuse.L, inp.fuse.a, inp.fuse.theta0_deg, inp.m_wall, inp.L_c) == (9.27, 0.84, 50.0, 4.54, 7.89)
    @test (inp.ρ_ext, inp.c_ext, inp.ρ_int, inp.c_int) == (1.1012, 334.08, 1.204, 343.0)
    @test inp.floor_sign == -1.0 && !inp.trim_band_centre && length(inp.acoustic.modes) == 20
    alt = PAIN._with_fields(inp; floor_sign=1.0)
    k = PAIN.r172428_flight10_inputs(; trim_band_centre=true, floor_sign=1.0)
    @test k.trim_band_centre && k.floor_sign == 1.0
    a = PAIN._run10_pair_eta(inp, 2, 4, 3, 39); b = PAIN._run10_pair_eta(alt, 2, 4, 3, 39)   # App. D, H2 row 1
    @test a > 0 && b > 0 && a != b                                                    # η_r″ carries the floor term
    @test isnan(PAIN._run10_pair_eta(inp, 2, 99, 3, 39))                             # pair not in the sum
    s = PAIN._printed_2d_list("appC_smalldia_acoustic_modes.csv")
    @test s.Δ ≈ 14.91 rtol = 0.01                                                     # (1, 0) printed at 14.91 Hz
    @test s.eps00 == 0.96858 && s.eps00_printed                                       # ε(0, 0) printed
    @test all(r -> r.I > 0, s.pts) && first(s.pts).Q == 0 && first(s.pts).f2d == 83.88   # Q = 0: f_2D is the printed f
    n = PAIN._printed_2d_list("appC_narrowbody_acoustic_modes.csv")
    @test !n.eps00_printed && n.eps00 ≈ 1.9508 / 2                                    # Eq. (C.11): half the (Q ≥ 1, 0) ε
end
