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
    @test af(deg2rad(20.0), 1e5, 0.2)[1] ≈ 0.5 && st.viterna_evals == 1           # α clamped to the table edge
    af(deg2rad(1.0), 5e6, 0.2)
    @test st.clamped_Re == 1
    af(deg2rad(1.0), 1e5, 0.5)
    @test st.nearest_polar ≥ 1                                                     # M = 0.5 has no table: nearest
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
