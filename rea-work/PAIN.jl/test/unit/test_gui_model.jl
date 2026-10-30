# Unit tests: src/gui_model.jl (Phase 64). The Observable layer behind the QML tabs; every figure the
# tests make goes to UNIT_OUT (`figure_dir`), the Cabin-modes cache is the ignored gui/cache folder.
@testset "formatting and card parsing" begin
    @test PAIN.validity_for_source(:aircraft) == "X-EXTRAP" && PAIN.validity_for_source(:e11) == "V-EXP"
    sp = PAIN.InteriorSpectrum(200.0, [80.0, 70.123], Dict(1000.0 => 60.0, 500.0 => 65.0), "n")
    @test PAIN._format_tonal(sp) == "H=1  f=200.0 Hz  SPL=80.0 dB\nH=2  f=400.0 Hz  SPL=70.12 dB"
    @test PAIN._format_third(sp) == "fc=500.0 Hz  SPL=65.0 dB\nfc=1000.0 Hz  SPL=60.0 dB"           # ascending
    @test PAIN._format_third(PAIN.InteriorSpectrum(200.0, [80.0], Dict{Float64,Float64}(), "n")) == "(no 1/3-octave bands)"
    obs = PAIN.make_gui_observables()
    @test obs["source"][] == "aircraft" && obs["z_p"][] == 0.662 && isfile(obs["aircraft_json"][])
    @test PAIN._parse_band_card_observables(obs) == (nothing, nothing, nothing)
    obs["bands_Hz"][] = "[1000, 1250]"; obs["eta_r_band"][] = "{\"1000\": 0.02}"
    b, ηr, ηn = PAIN._parse_band_card_observables(obs)
    @test collect(b) == [1000, 1250] && ηr[Symbol("1000")] == 0.02 && ηn === nothing
    lines = split(PAIN._format_val_case_list(), '\n')
    @test length(lines) == length(PAIN.validation_map_case_order())
    @test all(length(split(l, '\t')) == 5 for l in lines)
    @test startswith(PAIN._criterion_for("T1"), "criterion (2026-10-20): ") && PAIN._criterion_for("NOPE") == ""
end
# Phase 102: the run-status boxes. `*_state` is the pill a Run button shows and `*_log` the verbose record of the
# run behind it. These assert the states a user distinguishes: a recorded result read from disk, a run in progress,
# and a result this session computed — with the steps of that run, not of a previous one, in the log.
@testset "run-status state and verbose log" begin
    obs = PAIN.make_gui_observables()
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
    obs2 = PAIN.make_gui_observables()
    t1 = PAIN.gui_run_begin!(obs2, "val", "Run all: 2 cases")
    PAIN.run_validation_gui!(obs2, "BLK_P68"; figure_dir=UNIT_OUT, track=false)
    @test obs2["val_state"][] == "running"                                  # the nested run did not end it
    @test occursin("Run all: 2 cases", obs2["val_log"][])                   # nor clear it
    @test occursin("verdict: ", obs2["val_log"][])
    PAIN.gui_run_end!(obs2, "val", t1; note="ran 1 case")
    @test obs2["val_state"][] == "done"
end
@testset "validation tab and map refresh" begin
    obs = PAIN.make_gui_observables()
    r = PAIN.run_validation_gui!(obs, "BLK_P68"; figure_dir=UNIT_OUT)
    @test r !== nothing && obs["val_selected"][] == "BLK_P68" && obs["val_plot_path"][] == joinpath(UNIT_OUT, "BLK_P68.png")
    @test isfile(obs["val_plot_path"][]) && startswith(obs["val_status"][], "Done BLK_P68") && !obs["busy"][]
    @test PAIN._GUI_LAST_VERDICTS["BLK_P68"] == r.verdict
    m = PAIN.JSON3.read(obs["map_total_json"][])
    chip = first(c for b in m.blocks for c in b.cases if c.id == "BLK_P68")
    @test chip.last == String(r.verdict) && chip.error_source == "run"                      # map refreshed after the run
    @test PAIN.run_validation_gui!(obs, "NO_SUCH"; figure_dir=UNIT_OUT) === nothing && startswith(obs["val_status"][], "Error (NO_SUCH)")
    obs["map_selected"][] = "T1"
    PAIN.reload_validation_docs_gui!(obs)
    @test PAIN.JSON3.read(obs["map_detail_json"][]).id == "T1" && obs["val_criterion"][] == PAIN._criterion_for("BLK_P68")
    PAIN._refresh_map_json!(obs)
    @test PAIN.JSON3.read(obs["map_total_json"][]).id == "total"
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
    obs = PAIN.make_gui_observables()
    obs["n_harmonics"][] = 2.0
    @test PAIN.run_pain_gui!(obs)
    @test obs["validity_tag"][] == "X-EXTRAP" && obs["source_out"][] == "aircraft" && startswith(obs["status"][], "Done (X-EXTRAP)")
    @test occursin("H=2", obs["tonal_text"][]) && startswith(obs["dBA_text"][], "dB(A)=") && occursin("Validation-tab", obs["t1_text"][])
    obs["source"][] = "e11"                                                                 # E-11 is a verification input
    @test !PAIN.run_pain_gui!(obs) && occursin("aircraft pipeline only", obs["status"][]) && obs["validity_tag"][] == ""
    @test PAIN.run_printed_outputs_gui!(obs) === nothing && occursin("aircraft pipeline only", obs["po_status"][])
    obs["source"][] = "aircraft"
    out = PAIN.run_printed_outputs_gui!(obs)
    @test out !== nothing && PAIN.JSON3.read(obs["po_json"][]).n_harmonics == 2 && startswith(obs["po_status"][], "Done.")
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
