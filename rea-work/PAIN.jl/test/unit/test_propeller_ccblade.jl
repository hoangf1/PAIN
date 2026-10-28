# Unit tests: src/propeller_ccblade.jl (Phase 64). BEMT/F1A wrapper: definitions, exact acoustic
# properties (on-axis zero for steady loading, 1/r far field), guards, and the helper conversions.
const _HARTZELL = joinpath(@__DIR__, "..", "..", "examples", "aircraft_scale_hartzell.json")

@testset "helpers and conversions" begin
    @test PAIN._get((; a=1, b=nothing), :a, 5) == 1
    @test PAIN._get((; a=1, b=nothing), :b, 5) == 5 && PAIN._get((; a=1), :zz, 7) == 7
    @test PAIN._observer_aa(PAIN.FuselageGeometry(1.83, 0.508, 56.6), PAIN.PropellerPlacement(0.965, 90.0, 0.662), (; x1=1.0, x2=2.0, x3=3.0)) == [3.0, 1.0, 2.0]
    cl, cd = PAIN._default_af(0.1, 1e5, 0.2)
    @test cl ≈ 2π * 0.1 && cd ≈ 0.01 + 0.15 * 0.01
    @test PAIN._default_af(1.0, 1e5, 0.2)[1] ≈ 2π * 0.35                         # clamped
    @test PAIN._wrap_phase(3π / 2) ≈ -π / 2 && PAIN._wrap_phase(-π) ≈ -π && PAIN._wrap_phase(0.3) ≈ 0.3
    @test PAIN.total_rms([sqrt(2), sqrt(2)]) ≈ sqrt(2)                              # p_rms = √(Σ A²/2)
    @test PAIN.pressure_coefficient_pc(2.0; ρ=1.2, M_t=0.6, a=340.0) ≈ π^2 * 2 / (1.2 * 0.36 * 340^2)
    @test PAIN.pa_to_dyne_cm2(3.0) == 30.0 && PAIN.dyne_cm2_to_pa(PAIN.pa_to_dyne_cm2(3.7)) ≈ 3.7
    @test PAIN._besselj_int(0, 1.0) ≈ 0.7651976865579666 atol = 1e-14
    @test PAIN._besselj_int(3, 2.0) ≈ 0.1289432494744021 atol = 1e-14
    @test PAIN._besselj_int(-2, 1.5) ≈ PAIN._besselj_int(2, 1.5)                  # |n| (even order)
    t = [(; t=0.0), (; t=1.0), (; t=2.0)]
    @test PAIN._assert_reception_inside_elements(t, [0.5, 1.5], "o") === nothing
    @test_throws ErrorException PAIN._assert_reception_inside_elements(t, [0.5, 2.5], "o")
    @test_throws ErrorException PAIN._assert_reception_inside_elements(t[1:1], [0.5], "o")
end
@testset "observers, synthetic grid, blocking, Table 8 calibration" begin
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    prop = PAIN.PropellerPlacement(0.965, 90.0, 0.662)
    obs, pts = PAIN.grid_observers(fuse, prop, PAIN.GridSpec(); Vinf=20.0)
    @test length(obs) == 160 && obs[5].x == [pts[5].x3, pts[5].x1, pts[5].x2] && obs[5].v == [20.0, 0, 0]
    ho = PAIN.hub_observers(0.5, 1.0; x_over_D=[-0.5, 0.5], d_over_D=0.1, x_sign=-1, azimuth_deg=90.0)
    @test ho[1].x ≈ [0.5, 0.0, 0.6] atol = 1e-12
    @test ho[2].x[1] ≈ -0.5
    @test_throws ErrorException PAIN.hub_observers(0.5, 1.0; x_over_D=[0.0], d_over_D=0.1, x_sign=1, v=[1.0])
    sy = PAIN.synthetic_freefield_grid(fuse, prop; n_harmonics=2)
    sm = PAIN.synthetic_freefield_grid(fuse, PAIN.PropellerPlacement(0.965, 90.0, 0.662, -1); n_harmonics=2)
    @test size(sy.amplitudes) == (16, 10, 2) && sy.source == :synthetic
    k3 = findfirst(p -> p.k == 3 && p.ell == 1, sy.pts)
    @test sm.phases[3, 1, 2] ≈ -sy.phases[3, 1, 2]
    bl = PAIN.apply_blocking(sy, fuse, prop; variant=R2)
    p = sy.pts[k3]
    @test bl.amplitudes[3, 1, 1] ≈ PAIN.blocked_amplitude(sy.amplitudes[3, 1, 1], PAIN.incidence_angle_deg(fuse, prop, p.theta_deg, p.z); variant=R2)
    @test PAIN.apply_table8_calibration(sy, joinpath(UNIT_OUT, "no_such_table8.csv"))[2] == Float64[]
    csv = joinpath(@__DIR__, "..", "..", "..", "data", "cr3813", "anopp_table8_spl_dB.csv")
    cal, sc = PAIN.apply_table8_calibration(sy, csv)
    an = PAIN._read_csv_numeric(csv)
    @test length(sc) == 2 && all(0.1 .≤ sc .≤ 10)
    s_expected = clamp(maximum(PAIN.spl_dB_to_peak_Pa.(an[:SPL_H1_dB])) / maximum(sy.amplitudes[:, 1, 1]), 0.1, 10)
    @test sc[1] ≈ s_expected && cal.amplitudes[:, :, 1] ≈ s_expected .* sy.amplitudes[:, :, 1]
    @test cal.phases == sy.phases
    # ±20 dB clamp: a grid 10⁴ times louder than Table 8 would need s ≈ 10⁻⁴·s_expected; it is held at 0.1
    loud = PAIN.FreeFieldHarmonicGrid(sy.pts, sy.harmonics, 1e4 .* sy.amplitudes, sy.phases, sy.source, sy.notes, sy.bpf_Hz)
    cl, scl = PAIN.apply_table8_calibration(loud, csv)
    @test scl[1] == 0.1 && cl.amplitudes[:, :, 1] ≈ 0.1 .* loud.amplitudes[:, :, 1]
end
@testset "evaluate_propeller_source: definitions and exact properties" begin
    cfg = PAIN._load_aircraft_json(_HARTZELL)
    R = Float64(cfg.propeller.tip_radius_m)
    # hover (V = 0), thickness off, observers at rest: the signal is periodic in the blade passage
    stat = joinpath(UNIT_OUT, "unit_hartzell_static.json")
    write(stat, replace(read(_HARTZELL, String), r"\"forward_speed_mps\"\s*:\s*[0-9.eE+-]+" => "\"forward_speed_mps\": 0.0"))
    cs = PAIN._load_aircraft_json(stat); rm(stat)
    plane = PAIN.Observer([0.0, 20R, 0.0], zeros(3), "plane")
    axis = PAIN.Observer([20R, 0.0, 0.0], zeros(3), "axis")
    far = PAIN.Observer([0.0, 40R, 0.0], zeros(3), "plane2")
    s = PAIN.evaluate_propeller_source(cs, [plane, axis, far]; n_harmonics=2, num_src_times=64, allow_static=true)
    # steady loading: every source point is equidistant from an on-axis observer → no harmonic (J_mB(0) = 0)
    @test s.amplitude[2, 1] ≤ 1e-3 * s.amplitude[1, 1]
    @test s.amplitude[1, 1] / s.amplitude[3, 1] ≈ 2 rtol = 0.02                       # 1/r in the far field
    n = cfg.propeller.rpm / 60; D = 2R
    @test s.CT ≈ s.T / (1.225 * n^2 * D^4)
    @test s.CP ≈ 2π * s.CQ
    @test s.bpf_Hz ≈ 3 * 4000 / 60
    # Gutin: in the rotor plane only the torque radiates (thrust term ∝ cos θ = 0)
    sq = PAIN.evaluate_propeller_source(cs, [plane]; n_harmonics=1, loads=PAIN.ScaledLoads(s.T, 0.5s.Q), allow_static=true)
    st = PAIN.evaluate_propeller_source(cs, [plane]; n_harmonics=1, loads=PAIN.ScaledLoads(2s.T, s.Q), allow_static=true)
    @test sq.T ≈ s.T && sq.Q ≈ 0.5s.Q && st.echo.s_T ≈ 2
    @test sq.amplitude[1, 1] / s.amplitude[1, 1] ≈ 0.5 rtol = 0.02
    @test st.amplitude[1, 1] / s.amplitude[1, 1] ≈ 1 rtol = 0.02
    @test_throws ErrorException PAIN.evaluate_propeller_source(cs, [plane]; loads=:other)
    @test_throws ErrorException PAIN.evaluate_propeller_source(cs, [plane]; n_rev_src=0)
    @test_throws ErrorException PAIN.evaluate_propeller_source(cs, [plane]; force_short_source=true, allow_static=true)
    op = PAIN.ccblade_section_operating_points(cfg)
    @test op.r_over_R ≈ op.r_m ./ R && op.Vinf == 20.0
    W = hypot.(20.0, 4000 * 2π / 60 .* op.r_m)
    @test op.Mach ≈ W ./ 340 && op.Re ≈ 1.225 .* W .* op.chord_m ./ 1.78e-5
    # Phase 69 defect 5: the Re CCBlade hands the polar is ρWc/μ with the air viscosity (it was ρWc/1)
    seen = Float64[]
    rec(α, Re, M) = (push!(seen, Re); PAIN._default_af(α, Re, M))
    PAIN.ccblade_section_operating_points(cfg; af=rec)
    @test minimum(seen) > 1e4 && minimum(seen) ≥ 0.5 * minimum(op.Re) && maximum(seen) ≤ 2 * maximum(op.Re)
    # per-station polars: a vector is used station by station; a multi-section PolarSet needs station_t_over_c
    n = length(op.r_m)
    flat = [(α, Re, M) -> (k * α, 0.01) for k in range(5.0, 6.0; length=n)]
    @test length(PAIN._station_afs(flat, cfg.propeller, n)) == n
    @test_throws ErrorException PAIN._station_afs(flat[1:end-1], cfg.propeller, n)
    @test PAIN._station_afs(nothing, cfg.propeller, 2) == [PAIN._default_af, PAIN._default_af]
    # Phase 69a3: explicit per-station A/c² for the thickness term; otherwise thickness_over_chord everywhere
    @test PAIN._station_area_over_chord2((; thickness_over_chord=0.1), 0.1, 3) == [0.1, 0.1, 0.1]
    @test PAIN._station_area_over_chord2((; area_over_chord2=[0.07, 0.05]), 0.1, 2) == [0.07, 0.05]
    @test_throws ErrorException PAIN._station_area_over_chord2((; area_over_chord2=[0.07]), 0.1, 2)
    # Gutin far-field rotor-plane tone on the same loads (F1A_GUTIN)
    g = PAIN.f1a_gutin_h1_comparison(; aircraft_json=_HARTZELL)
    @test g.ok && abs(g.delta_dB) ≤ 1.0
end
@testset "propeller_freefield_grid / blade_form_geometry / _scale_outputs" begin
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    prop = PAIN.PropellerPlacement(0.965, 90.0, 0.662)
    ff = PAIN.propeller_freefield_grid(_HARTZELL, fuse, prop; n_harmonics=2, num_src_times=32)
    @test size(ff.amplitudes) == (16, 10, 2) && ff.source == :ccblade_f1a && occursin("Table8", ff.notes)
    @test all(ff.amplitudes .≥ 0)
    bf = PAIN.blade_form_geometry(joinpath(@__DIR__, "..", "..", "..", "data", "report996", "naca_4-5-08-03", "blade_form.csv");
                                  beta75_target_deg=15.0)
    @test maximum(bf.radii_m) ≤ 0.995 * bf.R + 1e-12
    @test bf.twist_deg .+ 42.64 .- 15.0 ≈ [PAIN._read_csv_numeric(joinpath(@__DIR__, "..", "..", "..", "data", "report996", "naca_4-5-08-03", "blade_form.csv"))[:beta_deg][i] for i in 1:length(bf.twist_deg)] atol = 1e-9
    @test_throws Exception PAIN.blade_form_geometry(_HARTZELL)
    o0 = (; Np=[1.0, 2.0], Tp=[3.0, 4.0])
    o = PAIN._scale_outputs(o0, 2.0, 3.0)
    @test o.Np == [2.0, 4.0] && o.Tp == [9.0, 12.0] && o0.Np == [1.0, 2.0]          # copy, not in place
end
@testset "observer fore/aft convention (Phase 72)" begin
    # AA +X is ahead (the rotor travels along +X): Report 996 x/D positive ahead → +X; Pereira φ positive downstream → −X
    o = hub_observers(0.2, 0.4; x_over_D=[-0.125, 0.125], d_over_D=0.083, x_sign=R996_X_SIGN)
    @test o[1].x[1] < 0 < o[2].x[1]
    po = pereira_observers([-20.0, 0.0, 40.0]; r=1.0, V=16.0)
    @test po[1].x[1] > 0 && po[3].x[1] < 0 && po[2].x[1] == 0
    @test all(p -> hypot(p.x...) ≈ 1.0 && p.v == [16.0, 0.0, 0.0], po)
    # physics (Gutin): a static propeller is louder behind the plane than ahead of it; with x_sign = −1 this fails
    cfg = PAIN._r996_cfg(; beta75=10.0, Mt=0.6, B=2)
    su = PAIN._ccblade_setup(cfg; allow_static=true)
    ob = hub_observers(su.Rtip, 2su.Rtip; x_over_D=[-0.5, 0.5], d_over_D=0.5, x_sign=R996_X_SIGN)
    s = evaluate_propeller_source(cfg, ob; n_harmonics=1, num_src_times=32, allow_static=true)
    @test s.amplitude[1, 1] > 1.2 * s.amplitude[2, 1]          # ≈ 1.5 with the right sign, ≈ 0.66 with the old one
end
