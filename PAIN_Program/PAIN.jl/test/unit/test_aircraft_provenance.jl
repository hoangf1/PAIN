# Unit tests: src/aircraft_provenance.jl (Phase 64). Tag parsing, NASA-default flags, trim JSON, App. D geometry.
const _KW0 = (; L=1.83, a=0.508, theta0_deg=56.6, r_p=0.965, phi_p_deg=90.0, z_p=0.662, rotation_direction=1,
              η_n_bare=0.05, C_struc=3.0, NY=10, ρ0=1.225, c0=340.0, ρ_ext=nothing, c_ext=nothing,
              ρ_int=nothing, c_int=nothing, L_c=nothing, d=0.0, use_table_d1=true, structural_solver=:table_d1,
              m_wall=NaN, bb_j2_scale=0.5, bb_α=2.0, broadband_model=:surrogate, spbl_anchor_H=3, q_max=nothing,
              allow_extrapolation=false, bands=nothing, η_r_band=nothing, η_n_band=nothing, trim=:auto,
              cabin_blocks=:auto, sidewall_trim_stack=nothing, end_trim_stack=nothing, mech=nothing)

@testset "tagged values" begin
    @test PAIN.parse_tagged_value(3) == (3.0, nothing)
    @test PAIN.parse_tagged_value(Dict("value" => 2.5, "tag" => "Measured")) == (2.5, "measured")
    @test PAIN.parse_tagged_value((; value=1.0, tag="assumed")) == (1.0, "assumed")
    @test_throws ErrorException PAIN.parse_tagged_value(Dict("value" => 2.5, "tag" => "guess"))
    @test_throws ErrorException PAIN.parse_tagged_value("x")
    @test PAIN.resolve_plain_tag(0.508, 0.508) == "nasa_default" && PAIN.resolve_plain_tag(0.5081, 0.508) == "assumed"
    @test PAIN._prov_row("a", 1, "s") == (; name="a", value=1, source="s")
    @test PAIN._input_row("a", 1, "t") == (; name="a", value=1, tag="t")
    @test PAIN._get_tagged(Dict("L" => 2.0), (:L_m, :L)) == (2.0, nothing)
    @test PAIN._get_tagged(nothing, (:L,)) === nothing && PAIN._get_tagged(Dict("x" => 1), (:L,)) === nothing
    @test PAIN._get_tagged_symbol((; trim="Bare"), (:trim,); allowed=(:bare, :phase3)) == (; value=:bare, tag="assumed")
    @test PAIN._get_tagged_symbol((; trim=(; value="phase3", tag="measured")), (:trim,); allowed=(:bare, :phase3)).tag == "measured"
    @test_throws ErrorException PAIN._get_tagged_symbol((; trim="foam"), (:trim,); name="trim", allowed=(:bare, :phase3))
    @test PAIN._dict_get(Dict("k" => 4), :k) == 4 && PAIN._dict_get(Dict("k" => 4), :z, 0) == 0
    @test PAIN.nasa_default_m_wall() ≈ PAIN.MRP_RHO_2024 * (PAIN.MRP_T_SKIN + PAIN.MRP_A_STRINGER / PAIN.MRP_D_STRINGER + PAIN.MRP_A_FRAME / PAIN.MRP_ELL_FRAME)
    @test PAIN.nasa_default_L() == PAIN.test_article_length()
    @test PAIN._nasa_ref_for("z_p_m") == 0.662 && PAIN._nasa_ref_for("E_Pa") == PAIN.MRP_E_2024 && PAIN._nasa_ref_for("nope") === nothing
end
@testset "apply_aircraft_cabin_json" begin
    cfg = (; cabin=Dict("L_m" => 3.0, "a_m" => (; value=0.6, tag="measured"), "z_p_m" => 0.662,
                        "trim" => "bare", "structural_solver" => "appd", "t_skin_m" => 0.001,
                        "allow_extrapolation" => true),
           fuselage=(; L_m=9.9))
    r = PAIN.apply_aircraft_cabin_json(cfg, _KW0)
    k = r.kwargs
    @test k.L == 3.0 && k.a == 0.6 && k.trim == :bare && k.structural_solver == :appd && !k.use_table_d1
    @test k.allow_extrapolation && k.appd_overrides[:t_skin_m] == 0.001
    tags = Dict(x.name => x.tag for x in r.provenance_inputs)
    @test tags["a_m"] == "measured" && tags["L_m"] == "assumed" && tags["z_p_m"] == "nasa_default"   # plain 0.662 = default
    @test "L_m" in r.supplied_names && !("theta0_deg" in r.supplied_names)
    @test PAIN.apply_aircraft_cabin_json((; fuselage=(; L_m=9.9)), _KW0).kwargs.L == 1.83                # documentary fuselage.L_m ignored
end
@testset "NASA-default list and labels (29b)" begin
    rows = [PAIN._input_row("a_m", 0.508, "assumed"), PAIN._input_row("C_struc", 3.0, "nasa_default")]
    used = PAIN.collect_nasa_defaults_used(; L=2.0, a=0.508, theta0_deg=56.6, r_p=0.965, phi_p_deg=90.0, z_p=0.662,
        rotation_direction=1, η_n_bare=0.05, C_struc=3.0, NY=10, ρ0=1.225, c0=340.0, L_c=2.0, d=0.0,
        m_wall_resolved=1.0, m_wall_was_fallback=true, structural_solver=:appd, use_table_d1=false,
        bb_j2_scale=0.5, bb_α=2.0, broadband_model=:eq19, spbl_anchor_H=3, trim_used=:bare, sidewall_is_phase3=false,
        supplied=Set(["a_m", "C_struc"]), input_rows=rows)
    names = [u.name for u in used]
    @test !("a_m" in names)                         # tagged assumed: omitted although equal to the default
    @test "C_struc" in names && "theta0_deg" in names && "z_p_m" in names
    @test !("L_m" in names)                         # 2.0 ≠ default
    @test "L_c_m" in names && "m_wall_kg_m2" in names && "t_skin_m" in names
    @test !("absorption_curve" in names)            # broadband :eq19 does not use the surrogate α
    @test PAIN.warn_nasa_defaults!(NamedTuple[]) === nothing
    @test_logs (:warn, r"NASA test-article defaults") PAIN.warn_nasa_defaults!(used)
    lab = PAIN.provenance_header_labels((; nasa_defaults=used, inputs=rows))
    @test startswith(lab.uses_defaults, "uses NASA test-article defaults: ") && occursin("C_struc", lab.nasa_article)
    @test PAIN.provenance_header_labels(PAIN.empty_provenance()) == (; uses_defaults="", nasa_article="")
end
@testset "cabin blocks, App. D geometry, trim JSON" begin
    @test PAIN.resolve_cabin_blocks(:auto, :aircraft) == :parametric && PAIN.resolve_cabin_blocks(:auto, :e11) == :surrogate
    @test PAIN.resolve_cabin_blocks(:surrogate, :aircraft) == :surrogate
    @test_throws ErrorException PAIN.resolve_cabin_blocks(:x, :aircraft)
    g = PAIN.build_appd_geometry(PAIN.FuselageGeometry(3.0, 0.7, 50.0), Dict(:t_skin_m => 0.002))
    @test g.L == 3.0 && g.a == 0.7 && g.t_skin == 0.002 && g.E == PAIN.MRP_E_2024
    @test PAIN._looks_like_trim_stack(Dict("sidewall" => Dict())) && PAIN._looks_like_trim_stack((; elements=[]))
    @test !PAIN._looks_like_trim_stack("bare") && !PAIN._looks_like_trim_stack(Dict("value" => "bare"))
    @test !PAIN._looks_like_trim_stack(nothing)
    tbl, tag, rows = PAIN._resolve_insulation_table(nothing)
    @test tag == "nasa_default" && length(tbl.f_Hz) == 6 && isempty(rows)
    t2, tag2, rows2 = PAIN._resolve_insulation_table(Dict("path" => "fig_a2_pf105.csv", "tag" => "measured"))
    @test tag2 == "measured" && rows2[1].name == "insulation_table" && t2.f_Hz == tbl.f_Hz
    @test_throws ErrorException PAIN._resolve_insulation_table(Dict("path" => "no_such.csv"))
    @test PAIN._parse_trim_element(Dict("type" => "insulation", "thickness_m" => 0.02), tbl).thickness == 0.02
    lm = PAIN._parse_trim_element(Dict("type" => "septum", "m_kg_m2" => 1.5), tbl)
    @test lm.m == 1.5 && lm.η == 0.05
    @test_throws ErrorException PAIN._parse_trim_element(Dict("type" => "foam"), tbl)
    @test_throws ErrorException PAIN._parse_trim_element(Dict("type" => "insulation"), tbl)
    st = PAIN._parse_stack_elements(Dict("elements" => [Dict("type" => "layer", "thickness" => 0.01)], "name" => "w"), tbl)
    @test st.name == "w" && length(st.elements) == 1
    @test_throws ErrorException PAIN._parse_stack_elements(Dict(), tbl)
    pj = PAIN.parse_aircraft_trim_json(Dict("sidewall" => Dict("elements" => [Dict("type" => "insulation", "thickness_m" => 0.013),
                                                                          Dict("type" => "limp_mass", "m_kg_m2" => 0.5, "eta" => 0.3)]),
                                            "mechanical" => Dict("N_points" => 4), "tag" => "measured");
                                       cabin_a=0.5, cabin_L=2.0, cabin_theta0_deg=60.0)
    @test length(pj.sidewall.elements) == 2 && pj.sidewall.elements[2].η == 0.3
    @test pj.mech.N_points == 4 && pj.mech.A_t ≈ 2 * 0.5 * (π - deg2rad(60)) * 2.0
    @test length(pj.ends.elements) == 1 && pj.tag == "measured"
    @test_throws ErrorException PAIN.parse_aircraft_trim_json(Dict("x" => 1); cabin_a=0.5, cabin_L=2.0, cabin_theta0_deg=60.0)
end
