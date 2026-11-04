# Unit tests: src/pain_settings.jl and src/gui_inputs.jl (Phase 127, 2026-11-04). Every run-path constant is a
# `PainSettings` field whose default is the literal it replaced; the GUI writes only changed fields to the project.
@testset "settings: defaults, specs, dict round trip" begin
    s = PainSettings()
    @test pain_settings() == s && c_omega() == 0.232 == C_OMEGA_THIRD_OCTAVE
    # the defaults are the literals the code used before Phase 127
    @test (s.grid_k_max, s.grid_ell_max, s.grid_k_p, s.grid_step_deg) == (16, 10, 8, 10.0)
    @test (s.block_c1, s.block_c2, s.block_c3, s.block_r2_scale, s.block_floor) == (0.3, 0.000224, 0.08, 0.8, 1.0)
    @test (s.num_src_times, s.n_rev_src, s.cyl2d_n_modes, s.n_struct_modes, s.c_cyl2d_mps) == (64, 2, 20, 32, CYL2D_C0)
    @test (s.appd_n_axial, s.appd_n_circ, s.appd_n_floor_max, s.appd_n_keep_shell, s.appd_n_keep_floor) == (10, 12, 5, 5, 3)
    # every field has exactly one GUI spec, and every spec names a field
    keys_ = [x.key for x in PAIN_SETTING_SPECS]
    @test sort(keys_) == sort(collect(fieldnames(PainSettings))) && allunique(keys_)
    @test all(x.kind in (:float, :int, :bool, :choice) for x in PAIN_SETTING_SPECS)
    @test pain_settings_diff(s) == Dict{String,Any}()
    t = pain_settings_from_dict(Dict("block_r2_scale" => 1.0, "tone_model" => "auto", "broadband" => false, "grid_k_max" => "18"))
    @test (t.block_r2_scale, t.tone_model, t.broadband, t.grid_k_max) == (1.0, :auto, false, 18)
    @test pain_settings_diff(t) == Dict{String,Any}("block_r2_scale" => 1.0, "tone_model" => "auto", "broadband" => false, "grid_k_max" => 18)
    @test pain_settings_from_dict(pain_settings_diff(t)) == t
    @test_throws ErrorException pain_settings_from_dict(Dict("block_r3" => 1.0))   # a mistyped name is not dropped
end

@testset "settings reach the run-path sites" begin
    # blocking: Eq. (43) constants, the R2 factor and the floor
    γ = 30.0
    F1 = blocking_factor(γ; variant=R1)
    @test F1 == 10.0^(0.3 - 0.000224 * exp(0.08 * γ))
    @test with_pain_settings(() -> blocking_factor(γ; variant=R2), PainSettings(block_r2_scale=1.0)) == F1
    @test with_pain_settings(() -> blocking_factor(γ; variant=R1), PainSettings(block_c1=0.0)) == 1.0   # floored
    @test with_pain_settings(() -> blocking_factor(γ; variant=R1), PainSettings(block_c1=0.0, block_floor=0.5)) ≈ F1 / 10^0.3
    # grid: GridSpec() and the step
    g = with_pain_settings(GridSpec, PainSettings(grid_k_max=4, grid_ell_max=3, grid_k_p=2, grid_step_deg=5.0))
    @test (g.k_max, g.ell_max, g.k_p, g.step_deg) == (4, 3, 2, 5.0) && PAIN.grid_divisor(g) == 36.0
    @test PAIN.grid_divisor(GridSpec()) == 18.0 && GridSpec(16, 10, 8).step_deg == 10.0
    fuse = FuselageGeometry(1.83, 0.508, 56.6); prop = PropellerPlacement(0.965, 90.0, 0.662)
    pts = grid_points(fuse, prop, g)
    @test length(pts) == 12 && maximum(p.alpha_deg for p in pts) ≈ 10.0                   # lines at 0°, 5°, 10°
    @test pts[1].x3 ≈ π * 0.508 / 36                                                     # axial step a·5°
    # c_ω and the default polar
    @test with_pain_settings(c_omega, PainSettings(c_omega=0.3)) == 0.3
    @test PAIN._default_af(0.1, 1e5, 0.3) == (2π * 0.1, 0.01 + 0.15 * 0.01)
    @test PAIN._default_af(1.0, 1e5, 0.3)[1] == 2π * 0.35                                  # clamped
    @test with_pain_settings(() -> PAIN._default_af(0.1, 1e5, 0.3), PainSettings(polar_cl_slope=5.0, polar_cd0=0.02)) ==
          (0.5, 0.02 + 0.15 * 0.01)
    # a whole run: R2 factor 1.0 against 0.8 scales every blocked amplitude where R2 is above its floor by 1.25
    r0 = run_pain_pipeline(; source=:synthetic, n_harmonics=2)
    r1 = run_pain_pipeline(; source=:synthetic, n_harmonics=2, settings=PainSettings(block_r2_scale=1.0))
    m = r0.ff.amplitudes .> 0
    ratio = r1.ff.amplitudes[m] ./ r0.ff.amplitudes[m]
    @test all(x -> x ≈ 1.25 || x ≥ 1.0, ratio) && any(x -> x ≈ 1.25, ratio)
    @test r1.spectrum.harmonic_SPL_dB[1] > r0.spectrum.harmonic_SPL_dB[1]
    @test r0.spectrum.harmonic_SPL_dB == run_pain_pipeline(; source=:synthetic, n_harmonics=2, settings=PainSettings()).spectrum.harmonic_SPL_dB
    # broadband off and the tone model reach interior_spl
    r2 = run_pain_pipeline(; source=:synthetic, n_harmonics=2, settings=PainSettings(broadband=false))
    @test occursin("tonal-only", r2.spectrum.notes) && r2.spectrum.harmonic_SPL_dB == r0.spectrum.harmonic_SPL_dB
    @test run_pain_pipeline(; source=:synthetic, n_harmonics=2, settings=PainSettings(tone_model=:auto)).spectrum.tone_model === :auto
    # PainInputs options
    r3 = run_pain_pipeline(; source=:synthetic, n_harmonics=2, settings=PainSettings(q0_coupled=true, c_cyl2d_mps=340.0))
    @test r3.inputs.q0_coupled && r3.inputs.c_cyl2d == 340.0 && !r0.inputs.q0_coupled
    # CYL2D mode count
    @test length(run_pain_pipeline(; source=:synthetic, n_harmonics=1, settings=PainSettings(cyl2d_n_modes=8)).acoustic.modes) <
          length(r0.acoustic.modes)
    # the App. D cutoff cache keys on the settings appd_modes reads
    geo = AppDGeometry(fuse)
    a1 = PAIN.appd_modes_to_cutoff(geo, 300.0)
    a2 = with_pain_settings(() -> PAIN.appd_modes_to_cutoff(geo, 300.0), PainSettings(appd_n_keep_shell=2))
    @test a1 !== a2 && maximum(length(x.n_shell) for x in a2.modes.modes) ≤ 2 < maximum(length(x.n_shell) for x in a1.modes.modes)
    # η_n band floor and the j² fallback read the settings in scope
    @test with_pain_settings(() -> pain_settings().eta_n_band_floor_Hz, PainSettings(eta_n_band_floor_Hz=125.0)) == 125.0
end

@testset "GUI input fields and the project builder" begin
    specs = gui_input_specs()
    @test allunique(s.key for s in specs) && allunique(Tuple(s.path) for s in specs)
    @test count(s -> startswith(s.key, "settings."), specs) == length(PAIN_SETTING_SPECS)
    @test all(s -> s.kind in (:float, :int, :bool, :choice, :list, :bandmap, :text, :elements), specs)
    # every App. D structure input of the provenance layer is a field
    @test all(sp -> any(s -> s.key == sp.name, specs), (PAIN.APPD_INPUT_SPECS..., PAIN.APPD_DECK_SPECS...))
    base = PAIN._load_project_dict(joinpath(pkgdir(PAIN), "examples", "aircraft_scale_hartzell.json"))
    vals = gui_field_values(base)
    @test PAIN._same(gui_build_project(base, vals), base)                     # nothing changed → the file as loaded
    @test vals["radii_m"] == "0.085, 0.12, 0.16, 0.2, 0.24, 0.28, 0.32, 0.35, 0.37, 0.378"
    @test vals["settings.block_r2_scale"] == "0.8" && vals["anopp_table8_calibrate"] == "true"
    # a changed field is written; a value equal to the code default is not added; blank optional removes
    v = copy(vals); v["rpm"] = "3000"; v["C_struc"] = "2.5"; v["settings.grid_k_max"] = "16"
    p = gui_build_project(base, v)
    @test p["propeller"]["rpm"] == 3000.0 && p["cabin"]["C_struc"] == 2.5 && !haskey(p, "settings")
    v["settings.tone_model"] = "auto"                                          # "auto" is a value of a setting
    @test gui_build_project(base, v)["settings"] == Dict{String,Any}("tone_model" => "auto")
    v["cabin_blocks"] = "auto"; v["L_c_m"] = ""
    p = gui_build_project(base, v)
    @test !haskey(p["cabin"], "cabin_blocks") && !haskey(p["cabin"], "L_c_m")
    # errors name the field
    v["num_blades"] = "3.5"; v["chord_m"] = "0.1, x"
    err = try gui_build_project(base, v); "" catch e; sprint(showerror, e) end
    @test occursin("Blades B: \"3.5\" is not a whole number", err) && occursin("Station chords: \"x\" is not a number", err)
    # a tagged project keeps its tags; a changed tagged value is written plain
    c = PAIN._load_project_dict(joinpath(pkgdir(PAIN), "examples", "commander695a_cr178004.json"))
    cv = gui_field_values(c)
    @test cv["cabin_blocks"] == "parametric" && cv["trim"] == "bare" && cv["t_skin_m"] == "0.0016"
    @test PAIN._same(gui_build_project(c, cv), c)
    cv["t_skin_m"] = "0.002"
    pc = gui_build_project(c, cv)
    @test pc["cabin"]["t_skin_m"] == 0.002 && pc["cabin"]["ell_frame_m"] == Dict("value" => 0.474, "tag" => "measured")
    # fallbacks and aliases: the value the code would read
    alt = Dict{String,Any}("cabin" => Dict{String,Any}("L" => 2.0), "propeller_placement" => Dict{String,Any}("rotation_direction" => -1),
                           "fuselage" => Dict{String,Any}("L_c_m" => 2.5))
    av = gui_field_values(alt)
    @test av["L_m"] == "2.0" && av["rotation_direction"] == "-1" && av["L_c_m"] == "2.5"
    av["L_c_m"] = ""
    @test PAIN._path_get(gui_build_project(alt, av), ["fuselage", "L_c_m"]) === nothing    # removed where the code reads it
    # trim stack fields
    tv = copy(vals); tv["trim"] = "stack"; tv["trim_sidewall"] = "insulation 0.05\nlimp_mass 1.2 0.1"; tv["trim_mech"] = "true"
    ts = gui_build_project(base, tv)["cabin"]["trim_stack"]
    @test ts["sidewall"]["elements"] == [Dict("type" => "insulation", "thickness_m" => 0.05),
                                         Dict("type" => "limp_mass", "m_kg_m2" => 1.2, "eta" => 0.1)]
    @test ts["mechanical"]["c_t"] == 3200.0 && !haskey(ts, "endplates")
    @test gui_field_values(gui_build_project(base, tv))["trim_sidewall"] == "insulation 0.05\nlimp_mass 1.2 0.1"
    tb = deepcopy(base); get!(Dict{String,Any}, tb, "cabin")["trim"] = "bare"
    @test !haskey(gui_build_project(tb, merge(gui_field_values(tb), Dict("trim" => "stack")))["cabin"], "trim")  # the stack replaces a plain trim
    tv["trim_sidewall"] = "foam 0.05"
    @test_throws ErrorException gui_build_project(base, tv)
    # bands: top level, where the code reads them first; η per band as "band: value" pairs or a list
    bsp = only(filter(s -> s.key == "eta_r_band", specs))
    @test bsp.path == ["eta_r_band"] && bsp.kind === :bandmap
    @test PAIN._parse_field(bsp, "1250: 0.03, 1000: 0.02") == Dict("1000" => 0.02, "1250" => 0.03)
    @test PAIN._value_text(bsp, Dict("1250" => 0.03, "1000" => 0.02)) == "1000: 0.02, 1250: 0.03"
    @test PAIN._parse_field(bsp, "0.02, 0.03") == [0.02, 0.03] && PAIN._parse_field(bsp, "") === nothing
    @test_throws ErrorException PAIN._parse_field(bsp, "1000: x")
    @test_throws ErrorException PAIN._parse_field(bsp, "1000: 0.02: 3")
    bc = Dict{String,Any}("cabin" => Dict{String,Any}("eta_r_band" => Dict("1000" => 0.02), "bands_Hz" => [1000.0]))
    bv = gui_field_values(bc)
    @test bv["eta_r_band"] == "1000: 0.02" && bv["bands_Hz"] == "1000.0"    # read from cabin.* when not at the top level
    bv["eta_r_band"] = ""
    @test PAIN._path_get(gui_build_project(bc, bv), ["cabin", "eta_r_band"]) === nothing
    ub = Dict{String,Any}("η_r_band" => Dict("1000" => 0.02))                  # the code's Greek alias at the top level
    ubv = gui_field_values(ub); @test ubv["eta_r_band"] == "1000: 0.02"
    ubv["eta_r_band"] = ""; @test !haskey(gui_build_project(ub, ubv), "η_r_band")
    bv["eta_r_band"] = "1000: 0.05"
    @test gui_build_project(bc, bv)["eta_r_band"] == Dict("1000" => 0.05)
    @test PAIN._elements_text(PAIN._parse_elements("insulation 0.013\nlimp_mass 6.58", "x")) == "insulation 0.013\nlimp_mass 6.58"
    # parse helpers
    sp = only(filter(s -> s.key == "rotation_direction", specs))
    @test PAIN._parse_field(sp, "-1") == -1 && PAIN._value_text(sp, Dict("value" => 1, "tag" => "assumed")) == "1"
    @test PAIN._untag(Dict("value" => 2.0, "tag" => "measured")) == 2.0 && PAIN._untag(3) == 3
    @test PAIN._gstr(0.1) == "0.1" && PAIN._gstr(3) == "3"
    d = Dict{String,Any}(); PAIN._path_set!(d, ["a", "b"], 1)
    @test PAIN._path_get(d, ["a", "b"]) == 1 && PAIN._effective_get(d, sp) === nothing
    PAIN._path_delete!(d, ["a", "b"]); @test PAIN._path_get(d, ["a", "b"]) === nothing
    @test PAIN._F("k", "G", "L", "", :float, ["x"], "1", "t").optional == false
    # unread keys, the QML spec JSON, BPF readout, run arguments
    @test "grid" in PAIN.gui_unread_keys(base) && "fuselage.L_m" in PAIN.gui_unread_keys(base)
    j = PAIN.JSON3.read(PAIN.gui_inputs_json(vals))
    @test String(j.groups[1].name) == "Run" && any(String(g.name) == "Numerics: Blocking" for g in j.groups)
    @test PAIN.gui_bpf_text(Dict("num_blades" => "2", "rpm" => "2400")) == "BPF = 80.0 Hz" && PAIN.gui_bpf_text(Dict{String,String}()) == ""
    ra = gui_run_args(base, vals)
    @test isfile(ra.path) && ra.kwargs.blocking === R2 && ra.kwargs.n_harmonics == 5 && ra.kwargs.aircraft_json == ra.path
    rm(ra.path)
end

@testset "GUI project open / save / defaults" begin
    obs = make_gui_observables()
    @test occursin("built-in default", obs["project_note"][]) && isempty(PAIN.gui_unread_keys(PAIN.gui_base(obs)))
    hzp = joinpath(pkgdir(PAIN), "examples", "aircraft_scale_hartzell.json")
    @test occursin("does not read", PAIN._gui_project_note(hzp, PAIN._load_project_dict(hzp)))
    gui_set_input!(obs, "rpm", "2400"); gui_set_input!(obs, "num_blades", "4")
    @test PAIN.gui_values(obs)["rpm"] == "2400" && obs["bpf_text"][] == "BPF = 160.0 Hz"
    @test_throws ErrorException gui_set_input!(obs, "no_such_field", "1")
    f = joinpath(UNIT_OUT, "p127_project.json")
    gui_save_project!(obs, f)
    @test isfile(f) && PAIN._load_project_dict(f)["propeller"]["rpm"] == 2400.0 && obs["project_path"][] == f
    gui_reset_project!(obs)
    @test PAIN.gui_values(obs)["rpm"] == "1181" && obs["project_path"][] == ""
    gui_open_project!(obs, f)
    # JSON3.pretty writes 2400.0 as 2400
    @test PAIN.gui_values(obs)["rpm"] == "2400" && PAIN.gui_values(obs)["num_blades"] == "4" && obs["project_path"][] == f
    @test_throws ErrorException gui_open_project!(obs, joinpath(UNIT_OUT, "missing.json"))
    @test_throws ErrorException gui_save_project!(obs, " ")
end
