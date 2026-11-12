# Unit tests: src/gui_model.jl (Phase 64). The Observable layer behind the QML tabs; every figure the
# tests make goes to UNIT_OUT (`figure_dir`), the Cabin-modes cache is the ignored gui/cache folder.
# Runs use the scale Hartzell project (seconds); the GUI default (Phase 128) is a full-size turboprop (minutes).
const _HZ = joinpath(pkgdir(PAIN), "examples", "aircraft_scale_hartzell.json")
@testset "formatting and card parsing" begin
    @test PAIN.validity_for_source(:aircraft) == "X-EXTRAP" && PAIN.validity_for_source(:e11) == "V-EXP"
    sp = PAIN.InteriorSpectrum(200.0, [80.0, 70.123], Dict(1000.0 => 60.0, 500.0 => 65.0), "n")
    @test PAIN._format_tonal(sp) == "H=1  f=200.0 Hz  SPL=80.0 dB\nH=2  f=400.0 Hz  SPL=70.12 dB"
    @test PAIN._format_third(sp) == "fc=500.0 Hz  SPL=65.0 dB\nfc=1000.0 Hz  SPL=60.0 dB"           # ascending
    @test PAIN._format_third(PAIN.InteriorSpectrum(200.0, [80.0], Dict{Float64,Float64}(), "n")) == "(no 1/3-octave bands)"
    # Phase 132: an empty band (−300 dB floor) prints "no level"; SIL needs a level in every 500–4000 Hz octave
    @test PAIN._format_third(PAIN.InteriorSpectrum(200.0, [80.0], Dict(125.0 => 80.0, 1000.0 => -300.0), "n")) ==
          "fc=125.0 Hz  SPL=80.0 dB
fc=1000.0 Hz  no level"
    tones_only = Dict(125.0 => 100.0, 500.0 => 62.8, 1000.0 => -300.0, 2000.0 => -300.0, 4000.0 => -300.0)
    @test startswith(PAIN._format_sil(tones_only), "SIL: not given")
    full = Dict(500.0 => 60.0, 1000.0 => 56.0, 2000.0 => 52.0, 4000.0 => 48.0)
    @test PAIN._format_sil(full) == "SIL=54.0 dB"                             # (60 + 56 + 52 + 48) / 4, written out
    obs = PAIN.make_gui_observables()   # the GUI default: Cabin_Noise's generic twin turboprop (Phase 128)
    vals = PAIN.gui_values(obs)
    @test vals["num_blades"] == "6" && vals["rpm"] == "1183.33" && vals["tip_radius_m"] == "1.74994" && vals["z_p_m"] == "11.35"
    @test vals["theta0_deg"] == "auto" && vals["anopp_table8_calibrate"] == "false" && obs["project_path"][] == ""
    @test PAIN.gui_base(obs)["propeller"]["num_blades"] == 6 && obs["bpf_text"][] == "BPF = 118.33 Hz"
    # HP_1650 geometry (39 stations from blade_form.csv) at helical tip Mach 0.85, from the field values themselves
    @test length(split(vals["radii_m"], ",")) == 39 && length(split(vals["twist_deg"], ",")) == 39 && length(split(vals["area_over_chord2"], ",")) == 39
    Vf, c0f, Rf, Ωf = parse(Float64, vals["forward_speed_mps"]), parse(Float64, vals["op_c0"]), parse(Float64, vals["tip_radius_m"]), 2π * parse(Float64, vals["rpm"]) / 60
    @test isapprox(hypot(Vf, Ωf * Rf) / c0f, 0.85; atol=1e-4)
    # Phase 133: the blade pitch makes CCBlade absorb the author's 2200 hp (1 hp = 745.69987 W) with forward thrust;
    # the twist alone (pitch 0) windmills (thrust < 0, power < 0)
    su = PAIN._ccblade_setup(PAIN.JSON3.read(PAIN.JSON3.write(PAIN.gui_base(obs))))
    Tq = PAIN.CCBlade.thrusttorque(su.rotor, su.sections, su.outs)
    @test vals["pitch_offset_deg"] == "15.98" && isapprox(Tq[2] * su.Ω, 2200 * 745.69987; rtol=1e-3) && Tq[1] > 0
    # Phase 130: 290 KTAS at 25000 ft ISA (written out here: 1 kt = 1852/3600 m/s; T = 288.15 − 0.0065·7620, γR = 1.4·287.05287)
    @test isapprox(Vf, 290 * 1852 / 3600; atol=0.02) && isapprox(c0f, sqrt(1.4 * 287.05287 * (288.15 - 0.0065 * 7620)); atol=0.01)
    # Phase 130: structure = CR-172428 Table 13 small-body cards (as printed)
    num(k) = parse(Float64, vals[k])
    @test num.(["t_shell_card_m", "m_shell_kg_m2", "Dp_stringers_Nm", "Dp_frames_Nm"]) == [0.00193, 5.34, 1892.0, 43620.0]
    @test num.(["t_floor_card_m", "m_floor_kg_m2", "Dp_floor_beams_Nm", "Dp_floor_supports_Nm"]) == [0.00191, 19.68, 1892.0, 43620.0]
    # D' = E I / l from Table 13's own I and spacing (stringer 3.397e-9 m⁴ at 0.13 m, frame 1.988e-7 m⁴ at 0.33 m)
    @test num("E_Pa") == 7.24e10 && isapprox(num("E_Pa") * 3.397e-9 / 0.13, num("Dp_stringers_Nm"); rtol=1e-3) &&
          isapprox(num("E_Pa") * 1.988e-7 / 0.33, num("Dp_frames_Nm"); rtol=1e-3)
    @test !haskey(vals, "settings.broadband") && !haskey(vals, "bb_alpha") && PAIN.gui_base(obs)["settings"]["broadband"] == false
    # Q111 (2026-11-05): the converged grid, 40 × 19 with the plane at k = 20; every station on the 22.7 m cylinder
    @test (vals["settings.grid_k_max"], vals["settings.grid_k_p"], vals["settings.grid_ell_max"]) == ("40", "20", "19")
    gs = GridSpec(40, 19, 20); zs = [p.z for p in grid_points(FuselageGeometry(22.7, 1.32, 62.6), PropellerPlacement(4.1699, 90.0, 11.35), gs)]
    @test 0 < minimum(zs) && maximum(zs) < 22.7 && isapprox(maximum(zs) - minimum(zs), 39 * π * 1.32 / 18; rtol=1e-12)
    hz = PAIN.gui_values(PAIN.make_gui_observables(; default_project=_HZ))
    @test hz["z_p_m"] == "0.662" && hz["rpm"] == "4000" && hz["num_blades"] == "3"
    lines = split(PAIN._format_val_case_list(), '\n')
    @test length(lines) == length(PAIN.validation_map_case_order())
    @test all(length(split(l, '\t')) == 5 for l in lines)
    @test startswith(PAIN._criterion_for("R172428_EXP"), "criterion ($(PAIN.VALIDATION_CASES["R172428_EXP"].criterion_date)): ") && PAIN._criterion_for("NOPE") == ""
end
# Phase 114: the run-status boxes. `*_state` is the pill a Run button shows and `*_log` the verbose record of the
# run behind it. These assert the states a user distinguishes: a recorded result read from disk, a run in progress,
# and a result this session computed — with the steps of that run, not of a previous one, in the log.
@testset "run-status state and verbose log" begin
    obs = PAIN.make_gui_observables(; default_project=_HZ)
    for p in ("run", "val", "po", "cm")
        @test obs["$(p)_state"][] == "ready" && obs["$(p)_log"][] == ""
    end

    # gui_log! timestamps each line, keeps order, and never drops the newest
    PAIN.gui_log!(obs, "val", "first")
    PAIN.gui_log!(obs, "val", "second")
    lines = split(obs["val_log"][], '\n')
    @test length(lines) == 2
    @test occursin("first", lines[1]) && occursin("second", lines[2])
    @test occursin(r"^\[\d\d:\d\d:\d\d\] ", lines[1])

    # the log is capped, and the cap keeps the end (what just happened), not the start
    for i in 1:(PAIN._GUI_LOG_MAX_LINES + 20)
        PAIN.gui_log!(obs, "val", "line $i")
    end
    kept = split(obs["val_log"][], '\n')
    @test length(kept) == PAIN._GUI_LOG_MAX_LINES
    @test occursin("line $(PAIN._GUI_LOG_MAX_LINES + 20)", kept[end])
    @test !occursin("first", obs["val_log"][])

    # begin clears the log and raises the pill; end lowers it and times the run
    t0 = PAIN.gui_run_begin!(obs, "po", "starting")
    @test obs["po_state"][] == "running" && occursin("starting", obs["po_log"][])
    @test !occursin("line 1", obs["po_log"][])
    PAIN.gui_run_end!(obs, "po", t0; note="all done")
    @test obs["po_state"][] == "done" && occursin("all done", obs["po_log"][])
    PAIN.gui_run_end!(obs, "po", t0; state="error", note="stopped")
    @test obs["po_state"][] == "error"

    # a case shown but not run in this session is RECORDED, and says so with its recorded date
    PAIN.gui_mark_snapshot!(obs, "val", "BLK_P68")
    rec = PAIN.recorded_case_errors()["BLK_P68"]
    @test obs["val_state"][] == "snapshot"
    @test occursin("not a run from this session", obs["val_log"][])
    @test occursin(String(rec.run_date), obs["val_log"][]) && occursin(String(rec.text), obs["val_log"][])
    # a case with no recorded result cannot claim to be showing one
    PAIN.gui_mark_snapshot!(obs, "val", "NO_SUCH_CASE_AT_ALL")
    @test obs["val_state"][] == "ready" && obs["val_log"][] == ""

    # a real run leaves the pill on done and the steps of *this* run in the log
    PAIN.gui_log!(obs, "val", "stale line from before the run")
    r = PAIN.run_validation_gui!(obs, "BLK_P68"; figure_dir=UNIT_OUT)
    @test r !== nothing && obs["val_state"][] == "done"
    log = obs["val_log"][]
    @test !occursin("stale line from before the run", log)                 # begin cleared it
    @test occursin("Running case BLK_P68", log)
    @test occursin("criterion ($(PAIN.VALIDATION_CASES["BLK_P68"].criterion_date))", log)
    @test occursin("verdict: $(r.verdict)", log)
    @test occursin("BLK_P68 $(r.verdict)", log)                            # the finish line

    # a failed run says error, not done, and gives the reason
    @test PAIN.run_validation_gui!(obs, "NO_SUCH"; figure_dir=UNIT_OUT) === nothing
    @test obs["val_state"][] == "error" && occursin("error: ", obs["val_log"][])

    # Run all keeps one cumulative log instead of clearing it per case (track = false)
    obs2 = PAIN.make_gui_observables(; default_project=_HZ)
    t1 = PAIN.gui_run_begin!(obs2, "val", "Run all: 2 cases")
    PAIN.run_validation_gui!(obs2, "BLK_P68"; figure_dir=UNIT_OUT, track=false)
    @test obs2["val_state"][] == "running"                                  # the nested run did not end it
    @test occursin("Run all: 2 cases", obs2["val_log"][])                   # nor clear it
    @test occursin("verdict: ", obs2["val_log"][])
    PAIN.gui_run_end!(obs2, "val", t1; note="ran 1 case")
    @test obs2["val_state"][] == "done"
end
@testset "validation tab and coverage refresh" begin
    obs = PAIN.make_gui_observables(; default_project=_HZ)
    r = PAIN.run_validation_gui!(obs, "BLK_P68"; figure_dir=UNIT_OUT)
    @test r !== nothing && obs["val_selected"][] == "BLK_P68" && obs["val_plot_path"][] == joinpath(UNIT_OUT, "BLK_P68.png")
    @test isfile(obs["val_plot_path"][]) && startswith(obs["val_status"][], "Done BLK_P68") && !obs["busy"][]
    @test PAIN._GUI_LAST_VERDICTS["BLK_P68"] == r.verdict
    @test !haskey(obs, "map_total_json")                                                     # the map was retired (Phase 147)
    @test PAIN.JSON3.read(obs["val_info_json"][]).error_source == "run"                       # the case text shows this run
    @test PAIN.run_validation_gui!(obs, "NO_SUCH"; figure_dir=UNIT_OUT) === nothing && startswith(obs["val_status"][], "Error (NO_SUCH)")
    obs["coverage_json"][] = "{}"
    PAIN.reload_validation_docs_gui!(obs)
    @test PAIN.JSON3.read(obs["val_info_json"][]).id == "BLK_P68" && obs["val_criterion"][] == PAIN._criterion_for("BLK_P68")
    @test !isempty(PAIN.JSON3.read(obs["coverage_json"][]).rows)                              # the Coverage tab re-read §2.13
    saved = copy(PAIN.VALIDATION_CASE_ORDER)
    try                                                                                     # run-all over a two-case order
        empty!(PAIN.VALIDATION_CASE_ORDER); append!(PAIN.VALIDATION_CASE_ORDER, ["MRP_D1", "CABIN_GEOM_HAND"])
        @test PAIN.run_all_validation_gui!(obs; figure_dir=UNIT_OUT)
        @test obs["val_status"][] == "Run all finished (2 runnable cases)." && isfile(joinpath(UNIT_OUT, "CABIN_GEOM_HAND.png"))
    finally
        empty!(PAIN.VALIDATION_CASE_ORDER); append!(PAIN.VALIDATION_CASE_ORDER, saved)
    end
end
@testset "run tab, printed outputs and cabin modes" begin
    obs = PAIN.make_gui_observables(; default_project=_HZ)
    PAIN.gui_set_input!(obs, "n_harmonics", "2")
    @test PAIN.run_pain_gui!(obs)
    @test obs["validity_tag"][] == "X-EXTRAP" && obs["source_out"][] == "aircraft" && startswith(obs["status"][], "Done (X-EXTRAP)")
    @test occursin("H=2", obs["tonal_text"][]) && startswith(obs["dBA_text"][], "dB(A)=") && occursin("Validation-tab", obs["t1_text"][])
    PAIN.gui_set_input!(obs, "rpm", "fast")                                                 # Phase 127: a bad field stops the run
    @test !PAIN.run_pain_gui!(obs) && occursin("Shaft speed: \"fast\" is not a number", obs["status"][]) && obs["validity_tag"][] == ""
    @test PAIN.run_printed_outputs_gui!(obs) === nothing && occursin("Shaft speed", obs["po_status"][])
    PAIN.gui_set_input!(obs, "rpm", "4000")
    out = PAIN.run_printed_outputs_gui!(obs)
    @test out !== nothing && PAIN.JSON3.read(obs["po_json"][]).n_harmonics == 2 && startswith(obs["po_status"][], "Done.")
    @test PAIN.JSON3.read(obs["po_json"][]).bpf_Hz == 200.0                                 # the run's own BPF (was the 150 Hz field)
    obs["cm_mode"][] = 3.0; obs["cm_nframes"][] = 4.0; obs["cm_struct_mode"][] = 2.0
    fr = PAIN.fill_cabin_modes_gui!(obs)
    @test fr !== nothing && fr.mode == 3 && startswith(obs["cm_status"][], "Done mode 3")
    fp = PAIN.JSON3.read(obs["cm_frame_paths_json"][]); sp = PAIN.JSON3.read(obs["cm_struct_frame_paths_json"][])
    @test length(fp) == 4 && length(sp) == 4 && all(isfile, sp) && obs["cm_struct_path"][] == sp[1]   # Phase 63: same frame count
    @test startswith(obs["cm_f_prime"][], "f′(n=3, r=2, q=0)")
    # Phase 63: a step moves the acoustic and the structural frame together and wraps at nframes
    saved = PAIN._GUI_OBS[]
    try
        PAIN._GUI_OBS[] = obs
        PAIN.cabin_modes_step_frame_from_qml(1)
        @test obs["cm_frame_index"][] == 1 && obs["cm_struct_path"][] == sp[2] && obs["cm_frame_path"][] == fp[2]
        PAIN.cabin_modes_step_frame_from_qml(3)
        @test obs["cm_frame_index"][] == 0 && obs["cm_struct_path"][] == sp[1]          # 4 frames: periodic
        @test read(sp[1]) != read(sp[2])                                                # the frames differ
    finally
        PAIN._GUI_OBS[] = saved
    end
    obs["cm_mode"][] = 99.0
    PAIN.fill_cabin_modes_gui!(obs)
    @test obs["cm_mode"][] == 19.0                                                          # clamped to the 20 modes
end

# Phase 120 (2026-11-03): θ₀ "auto" in the GUI means the auto floor angle for the current radius (Phase 127: a field)
@testset "auto floor angle in the GUI" begin
    obs = PAIN.make_gui_observables(; default_project=_HZ)
    base, vals = PAIN.gui_base(obs), PAIN.gui_values(obs)
    @test vals["theta0_deg"] == "auto"
    @test !haskey(get(PAIN.gui_build_project(base, vals), "cabin", Dict()), "theta0_deg")   # a = 0.508 m: 56.6°, the default
    vals["a_m"] = "1.25"
    @test PAIN.gui_build_project(base, vals)["cabin"]["theta0_deg"] == 62.6
    vals["a_m"] = "1.6"
    @test PAIN.gui_build_project(base, vals)["cabin"]["theta0_deg"] == 73.7
    vals["theta0_deg"] = "50"
    @test PAIN.gui_build_project(base, vals)["cabin"]["theta0_deg"] == 50.0
    vals["theta0_deg"] = "flat"
    @test_throws ErrorException PAIN.gui_build_project(base, vals)
end
