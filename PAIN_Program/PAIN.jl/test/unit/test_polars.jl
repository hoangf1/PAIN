# Unit tests: src/polars.jl (Phase 64). Polar lookup on a hand-made table; measured overlays.
@testset "interp_no_extrap / _nearest_grid" begin
    @test PAIN.interp_no_extrap([0.0, 1.0, 2.0], [0.0, 10.0, 0.0], 0.5) ≈ 5.0
    @test PAIN.interp_no_extrap([2.0, 0.0, 1.0], [0.0, 0.0, 10.0], 1.5) ≈ 5.0    # unsorted input
    @test PAIN.interp_no_extrap([0.0, 1.0], [1.0, 2.0], 1.5) === nothing         # never extrapolates
    @test PAIN.interp_no_extrap([0.0, 1.0], [1.0, 2.0], -0.1) === nothing
    @test PAIN.interp_no_extrap(Float64[], Float64[], 0.0) === nothing
    @test PAIN.interp_no_extrap([1.0], [7.0], 1.0) == 7.0
    @test_throws ErrorException PAIN.interp_no_extrap([0.0, 1.0], [1.0], 0.5)
    @test PAIN._nearest_grid(0.42, [0.2, 0.4, 0.6]) == 0.4
    @test_throws ErrorException PAIN._nearest_grid(1.0, Float64[])
end
@testset "load_polar_set / _polar_tables / Viterna" begin
    p = joinpath(UNIT_OUT, "unit_polars.json")
    write(p, """{"Res":[100000,1000000],"Ms":[0.2,0.5],"polars":{
      "s|100000|0.2":[[5,0.5,0.012],[-5,-0.5,0.01],[0,0,0.008]],
      "s|1000000|0.2":[[-5,-0.6,0.008],[0,0,0.006],[5,0.6,0.009]]}}""")
    af, st = PAIN.load_polar_set(p)
    cl, cd = af(deg2rad(2.5), 1e5, 0.2)
    @test cl ≈ 0.25 && cd ≈ 0.010                                                 # linear in α
    @test af(deg2rad(2.5), 1e6, 0.2)[1] ≈ 0.3
    @test af(deg2rad(20.0), 1e5, 0.2)[1] ≈ 0.5 && st.viterna_evals == 1           # no cr75: end value held
    af(deg2rad(1.0), 5e6, 0.2)
    @test st.clamped_Re == 1
    af(deg2rad(1.0), 1e5, 0.5)
    @test st.nearest_polar ≥ 1                                                     # M = 0.5 has no table: nearest
    # Phase 69 defect 2: bilinear in log Re (the old loader returned the nearest table, 0.25 or 0.30)
    @test af(deg2rad(2.5), sqrt(1e5 * 1e6), 0.2)[1] ≈ 0.275
    afb, _ = PAIN.load_polar_set(p; set=:bracket)
    @test afb(deg2rad(2.5), 1e5, 0.2)[1] ≈ 0.92264 * 0.25 && afb(deg2rad(2.5), 1e5, 0.2)[2] ≈ 1.81815 * 0.010
    @test_throws ErrorException PAIN.load_polar_set(p; set=:other)
    t = PAIN._polar_tables(p)
    @test t.sections == ["s"] && t.Res == [1e5, 1e6]
    @test first.(t.tables[("s", 1e5, 0.2)]) == [-5.0, 0.0, 5.0]                   # sorted by α
    rm(p)
    pts = [(Float64(a), 2π * deg2rad(a), 0.01) for a in -6:2:12]
    α, cle, cde = PAIN._viterna_extension_curve(pts, 0.1)
    @test !isempty(α) && all((α .< -6) .| (α .> 12)) && all(isfinite, cle) && all(cde .> 0)
    @test PAIN._viterna_extension_curve(pts[1:2], 0.1) == (Float64[], Float64[], Float64[])
end
@testset "per-section polars, Mach interpolation, Viterna (Phase 69 defects 1-3)" begin
    p = joinpath(UNIT_OUT, "unit_polars_multi.json")
    rows(k) = "[" * join(("[$a,$(k * deg2rad(a)),0.01]" for a in -6:2:12), ",") * "]"
    # Two sections: 16-506 (t/c 0.06) with c_l slope 4/rad, 16-510 (t/c 0.10) with 6/rad; M 0.2 and 0.4.
    write(p, """{"Res":[1000000],"Ms":[0.2,0.4],"polars":{
      "n16_506|1000000|0.2":$(rows(4.0)), "n16_506|1000000|0.4":$(rows(5.0)),
      "n16_510|1000000|0.2":$(rows(6.0)), "n16_510|1000000|0.4":$(rows(7.0))}}""")
    ps, st = PAIN.load_polar_set(p)
    @test ps.sections == ["n16_506", "n16_510"] && ps.t_over_c == [0.06, 0.10]
    @test_throws ErrorException ps(0.1, 1e6, 0.2)                  # a multi-section set needs a thickness
    a = deg2rad(4.0)
    @test PAIN.section_polar(ps, 0.06)(a, 1e6, 0.2)[1] ≈ 4.0 * a      # each station its own section
    @test PAIN.section_polar(ps, 0.10)(a, 1e6, 0.2)[1] ≈ 6.0 * a
    @test PAIN.section_polar(ps, 0.08)(a, 1e6, 0.2)[1] ≈ 5.0 * a      # linear in t/c
    @test PAIN.section_polar(ps, 0.20)(a, 1e6, 0.2)[1] ≈ 6.0 * a      # clamped to the thickest
    @test PAIN.section_polar(ps, 0.06)(a, 1e6, 0.3)[1] ≈ 4.5 * a      # linear in M
    afs = PAIN.station_polars(ps, [0.06, 0.10])
    @test afs[1](a, 1e6, 0.2)[1] ≈ 4.0 * a && afs[2](a, 1e6, 0.2)[1] ≈ 6.0 * a
    @test PAIN._section_t_over_c("n16_213") == 0.13 && PAIN._section_t_over_c("naca4412") === nothing
    @test PAIN._bracket([1.0, 2.0, 4.0], 3.0) == (2, 0.5) && PAIN._bracket([1.0], 9.0) == (1, 0.0)
    t = ps.tables[("n16_506", 1e6, 0.2)]
    st0 = PAIN.PolarStats()
    @test PAIN._eval_table(t, 3.0, st0)[1] ≈ 4.0 * deg2rad(3.0) && st0.viterna_evals == 0   # linear between knots
    @test PAIN._eval_table(t, 30.0, st0)[1] ≈ 4.0 * deg2rad(12.0) && st0.viterna_evals == 1 # end held, counted
    @test PAIN._table_or_nearest(ps, "n16_510", 1e6, 0.4) === ps.tables[("n16_510", 1e6, 0.4)]
    @test PAIN._eval_section(ps, "n16_510", a, 1e6, 0.3)[1] ≈ 6.5 * a
    # Viterna past the converged span (old loader held c_l = 6·12° at every larger α)
    pv, sv = PAIN.load_polar_set(p; cr75=0.1)
    clv, cdv = PAIN.section_polar(pv, 0.10)(deg2rad(40.0), 1e6, 0.2)
    @test clv != 6.0 * deg2rad(12.0) && cdv > 0.1 && sv.viterna_evals ≥ 1
    @test PAIN.section_polar(pv, 0.10)(a, 1e6, 0.2)[1] ≈ 6.0 * a     # inside the span unchanged
    # A missing (Re, M) table falls back to the same section, never to another one
    write(p, """{"Res":[1000000],"Ms":[0.2,0.4],"polars":{
      "n16_506|1000000|0.2":$(rows(4.0)), "n16_510|1000000|0.2":$(rows(6.0)), "n16_510|1000000|0.4":$(rows(7.0))}}""")
    pm, sm = PAIN.load_polar_set(p)
    @test PAIN.section_polar(pm, 0.06)(a, 1e6, 0.4)[1] ≈ 4.0 * a && sm.nearest_polar ≥ 1
    write(p, """{"Res":[1000000],"Ms":[0.2],"polars":{"n16_506|1000000|0.2":$(rows(4.0)), "foil|1000000|0.2":$(rows(5.0))}}""")
    @test_throws ErrorException PAIN.load_polar_set(p)            # thickness of "foil" unknown
    rm(p)
end
@testset "measured overlays (display only)" begin
    dir = PAIN._AIRFOIL_MEASURED_DIR
    tr = PAIN._load_tr824_naca4412(dir)
    @test !isempty(tr.cl_alpha) && !isempty(tr.cd_cl)
    @test PAIN._load_tr824_naca4412(joinpath(UNIT_OUT, "no_such_dir")) === nothing
    cu = PAIN._load_tn1546_curves(joinpath(dir, "tn1546_fig3_cl_cd_vs_mach.csv"))
    @test all(issorted(c.mach) for c in values(cu))
    s = PAIN.measured_polar_series("naca4412")
    @test Set(x.kind for x in s) == Set([:cl_alpha, :cd_cl])
    tn = PAIN.measured_polar_series("n16_312")
    @test any(x.kind == :cl_cd_at_M for x in tn) && any(x.kind == :cl_vs_M for x in tn)
    for x in tn
        x.kind == :cl_cd_at_M && @test x.Mach in (0.4, 0.55, 0.65, 0.72)
        x.kind == :cl_vs_M && @test minimum(x.mach) ≥ 0.3 - 1e-12
    end
    @test isempty(PAIN.measured_polar_series("unknown_section"))
end
