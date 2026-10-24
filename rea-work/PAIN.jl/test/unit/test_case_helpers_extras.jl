# Unit tests: helpers in src/validation_case_extras.jl (Phase 64). The case runners themselves run in
# runtests.jl; these test the readers, converters and series builders they are made of.
@testset "readers and converters" begin
    @test PAIN._csv_split_row("a,\"b,c\",\"d\"\"e\",") == ["a", "b,c", "d\"e", ""]
    p = joinpath(UNIT_OUT, "unit_rows.csv")
    write(p, "# c\nx,y\n1,\"2,5\"\n\n3,4\n")
    hdr, rows = PAIN._read_csv_rows(p)
    @test hdr == ["x", "y"] && rows == [["1", "2,5"], ["3", "4"]]
    write(p, "# only comments\n")
    @test PAIN._read_csv_rows(p) == (String[], Vector{String}[])
    write(p, "H,x,y\n1,3,30\n1,1,10\n2,1,5\n")
    c = PAIN._e12_readcurve(p); rm(p)
    @test c[1] == [(1.0, 10.0), (3.0, 30.0)] && c[2] == [(1.0, 5.0)]                # sorted by x
    @test PAIN._e12_interp(c[1], 2.0) ≈ 20 && isnan(PAIN._e12_interp(c[1], 4.0)) && isnan(PAIN._e12_interp(Tuple{Float64,Float64}[], 1.0))
    @test PAIN._wrap180(190.0) ≈ -170 && PAIN._wrap180(-180.0) ≈ -180 && PAIN._wrap180(540.0) ≈ -180
    @test PAIN.bbn_printed_pair_phase(10.0, -20.0) ≈ -30 && PAIN.bbn_printed_pair_phase(-170.0, 170.0) ≈ -20   # φ_b − φ_a, wrapped
    @test PAIN._rpm_from_Mt(0.6) ≈ 0.6 * 340.3 * 60 / (π * 1.2192)                    # M_t = πnD/a
    @test isfile(PAIN._bbn_csv_path()) && isfile(PAIN._pereira_csv_path())
    pc = PAIN.polar_coverage_recount([(; Mach=0.3, alpha_deg=2.0), (; Mach=0.8, alpha_deg=2.0), (; Mach=0.5, alpha_deg=20.0)];
                                     M_lo=0.2, M_hi=0.72, α_lo=-5.0, α_hi=15.0)
    @test pc == (n_out_M=1, n_out_α=1, n=3)
end
@testset "Report 996 / Pereira configurations" begin
    cfg = PAIN._r996_cfg(; beta75=15.0, Mt=0.6, B=2)
    @test cfg.propeller.num_blades == 2 && cfg.propeller.rpm ≈ PAIN._rpm_from_Mt(0.6)
    @test cfg.propeller.tip_radius_m ≈ 1.2192 / 2 && cfg.operating_point.forward_speed_mps == 0.0
    i75 = argmin(abs.(cfg.propeller.radii_m ./ cfg.propeller.tip_radius_m .- 0.75))
    @test cfg.propeller.twist_deg[i75] ≈ 15.0 atol = 0.5                                # β(0.75R) set to β₇₅
    runs = PAIN._r996_display_runs()
    keys_ = [(r.beta75, r.Mt, r.B, r.polar_set) for r in runs]
    @test allunique(keys_) && (10.0, 0.75, 2, :primary) in keys_ && (20.0, 0.6, 2, :bracket) in keys_
    pcfg = PAIN._pereira_cfg_from_csv()
    @test pcfg.propeller.num_blades == 2 && length(pcfg.propeller.radii_m) ≤ 25 && issorted(pcfg.propeller.radii_m)
    @test !pcfg.anopp_table8_calibrate
end
@testset "polar series builders" begin
    tables = Dict(("s", 1e5, 0.2) => [(-5.0, -0.5, 0.01), (0.0, 0.0, 0.008), (5.0, 0.5, 0.012)],
                  ("s", 1e5, 0.4) => [(-4.0, -0.4, 0.01), (0.0, 0.0, 0.009), (4.0, 0.45, 0.02)])
    @test PAIN._polar_pts(tables, "s", 1e5, 0.2 + 1e-12) === tables[("s", 1e5, 0.2)]     # float-tolerant key
    @test PAIN._polar_pts(tables, "s", 1e5, 0.3) === nothing
    @test PAIN._xfoil_cl_at_alpha(tables[("s", 1e5, 0.2)], 2.5) ≈ 0.25
    @test PAIN._xfoil_cl_at_alpha(tables[("s", 1e5, 0.2)], 9.0) === nothing && PAIN._xfoil_cl_at_alpha(nothing, 1.0) === nothing
    b = PAIN._coverage_box_series(0.2, 0.7, -5.0, 15.0; panel=3)
    @test b.x == [0.2, 0.7, 0.7, 0.2, 0.2] && b.y == [-5, -5, 15, 15, -5] && b.panel == 3   # closed rectangle
    ser = PAIN.PlotSeries[]
    PAIN._append_polar_curve_series!(ser, tables, "s", 1e5, [0.2, 0.4, 0.9]; panel_cl=1, panel_cd=2, tag_prefix="X")
    @test length(ser) == 4 && ser[1].panel == 1 && ser[2].panel == 2 && ser[1].y == [-0.5, 0.0, 0.5]   # M = 0.9 absent: skipped
    ser2 = PAIN.PlotSeries[]
    PAIN._append_viterna_series!(ser2, Dict(("s", 1e5, 0.2) => [(Float64(a), 2π * deg2rad(a), 0.01) for a in -6:2:12]), "s", 1e5, [0.2], 0.1; panel_cl=1, panel_cd=2)
    @test length(ser2) == 2 && all(x -> x < -6 || x > 12, ser2[1].x) && startswith(ser2[1].name, "Viterna ext. M=0.2")
end
@testset "registry assembly" begin
    n0 = length(PAIN.VALIDATION_CASE_ORDER)
    PAIN._finish_validation_registry!()                                                 # rebuild is idempotent
    @test length(PAIN.VALIDATION_CASE_ORDER) == n0 && allunique(PAIN.VALIDATION_CASE_ORDER)
    @test all(haskey(PAIN.VALIDATION_CASES, id) for id in PAIN.VALIDATION_CASE_ORDER)
    @test "F1A_PLANE_PEAK" in PAIN.VALIDATION_CASE_ORDER && "BEMT_HAND" in PAIN.VALIDATION_CASE_ORDER
end
