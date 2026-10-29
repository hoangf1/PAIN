# Unit tests: src/validation_cases.jl, src/validation_report.jl and the evaluators in src/PAIN.jl (Phase 64).
@testset "registry helpers" begin
    @test PAIN._error_quantity_group("SPL H2") == "SPL" && PAIN._error_quantity_group("mode 3 f_Hz") == "f_Hz"
    @test PAIN._error_quantity_group("phase pair2 k=4") == "phase" && PAIN._error_quantity_group("H1") == "value"
    r = PAIN.ValidationTableRow("SPL H1", 1, 80, 81, 1, true)
    @test r.group == "SPL" && r.x === 1.0 && PAIN.ValidationTableRow("q", 1, 2, 3, 4, false, "g").group == "g"
    @test endswith(replace(PAIN._data_path("cr3813", "x.csv"), '\\' => '/'), "data/cr3813/x.csv")
    f = joinpath(UNIT_OUT, "unit_present.txt"); write(f, "x")
    @test PAIN._missing_refs([f, "", joinpath(UNIT_OUT, "absent.txt")]) == [joinpath(UNIT_OUT, "absent.txt")]
    rm(f)
    @test PAIN._verdict_all(true, 3, 3, "ok", "no") == (:met, "ok") && PAIN._verdict_all(false, 1, 3, "ok", "no") == (:not_met, "no")
    @test occursin(r"^\d{4}-\d{2}-\d{2}$", PAIN._today_iso())
    ids = [c.id for c in PAIN.list_validation_cases()]
    @test allunique(ids) && Set(ids) == Set(keys(PAIN.VALIDATION_CASES))              # every registered case is ordered
    @test [c.id for c in PAIN._make_registry()] == ["CYL2D_C1", "MRP_D1", "T1", "T2", "REPRO_18b"]
    @test !PAIN.validation_case_runnable("NO_SUCH_CASE") && PAIN.validation_case_runnable("CYL2D_C1")
    @test_throws ErrorException PAIN.run_validation_case("NO_SUCH_CASE")
    u = PAIN._run_unavailable("X", "deferred", "lbl", "rep.md")
    @test u.verdict == :no_verdict && u.reason == "deferred" && isempty(u.table)
    # missing reference file → no verdict (temporary registry entry, removed afterwards)
    c0 = PAIN.VALIDATION_CASES["MRP_D1"]
    tmp = PAIN.ValidationCase("UNIT_MISSING", "t", "64", [joinpath(UNIT_OUT, "absent.csv")], c0.figure_ref,
                              "none", "2026-10-24", "unit", () -> error("must not run"), c0.plot_spec, "")
    PAIN.VALIDATION_CASES["UNIT_MISSING"] = tmp
    try
        rm_ = PAIN.run_validation_case("UNIT_MISSING")
        @test rm_.verdict == :no_verdict && startswith(rm_.reason, "missing reference")
    finally
        delete!(PAIN.VALIDATION_CASES, "UNIT_MISSING")
    end
    res = PAIN.run_validation_case("MRP_D1")
    txt = PAIN.format_validation_result(res)
    @test occursin("id: MRP_D1", txt) && occursin("quantity\tx\treference", txt) && count('\n', txt) ≥ length(res.table) + 8
end
@testset "evaluate_T1 / evaluate_T2 / validate_mrp_table_d1 / write_validation_record" begin
    tg = PAIN._read_csv_numeric(joinpath(dirname(PAIN.default_e11_paths().A), "t1_interior_targets.csv"))
    sp = PAIN.InteriorSpectrum(200.0, collect(tg[:measured_mean_SPL_dB]), Dict{Float64,Float64}(), "u")
    @test all(r.result == "PASS" for r in PAIN.evaluate_T1(sp))
    off = PAIN.InteriorSpectrum(200.0, tg[:measured_mean_SPL_dB] .+ 4.01, Dict{Float64,Float64}(), "u")
    for (i, r) in enumerate(PAIN.evaluate_T1(off))                                 # gate A fails just past 4 dB
        gB = tg[:measured_low_dB][i] ≤ off.harmonic_SPL_dB[i] ≤ tg[:measured_high_dB][i] && abs(off.harmonic_SPL_dB[i] - tg[:nasa_pain_pred_dB][i]) ≤ 4
        @test r.result == (gB ? "PASS" : "FAIL")
    end
    t2 = PAIN._read_csv_numeric(joinpath(dirname(PAIN.default_e11_paths().A), "t2_third_octave_targets.csv"))
    sp2 = PAIN.InteriorSpectrum(200.0, [80.0], Dict(t2[:fc_Hz][i] => t2[:measured_mean_SPL_dB][i] for i in eachindex(t2[:fc_Hz])), "u")
    @test all(r.result == "PASS" for r in PAIN.evaluate_T2(sp2))
    sp3 = PAIN.InteriorSpectrum(200.0, [80.0], Dict(t2[:fc_Hz][i] => t2[:measured_mean_SPL_dB][i] + t2[:tol_dB][i] + 0.01 for i in eachindex(t2[:fc_Hz])), "u")
    @test all(r.result == "FAIL" for r in PAIN.evaluate_T2(sp3))
    sm = PAIN.structural_modes_from_table_d1()
    @test all(r.result == "PASS" for r in PAIN.validate_mrp_table_d1(sm))
    shifted = PAIN.StructuralModes([PAIN.StructuralMode(m.index, 1.06m.f_Hz, m.symmetric, m.M_r, m.M_axial, m.C_shell, m.n_shell, m.C_floor, m.n_floor) for m in sm.modes], sm.L, sm.a, sm.theta0_deg, "")
    @test all(r.result == "FAIL" for r in PAIN.validate_mrp_table_d1(shifted))
    p = joinpath(UNIT_OUT, "unit_record.md")
    PAIN.write_validation_record(p, PAIN.validate_mrp_table_d1(sm)[1:2]; header="H")
    s = read(p, String); rm(p)
    @test startswith(s, "H\n\n# PAIN validation report") && count("result: PASS", s) == 2
end

@testset "information-only cases (Phase 82 meaningfulness rule)" begin
    @test all(id -> haskey(PAIN.VALIDATION_CASES, id), keys(PAIN.INFORMATION_ONLY_CASES))   # no stale or misspelt ids
    row = PAIN.ValidationTableRow("x", 1.0, 1.0, 2.0, 1.0, false)
    mk(id, v) = PAIN.ValidationCaseResult(id, "2026-10-29", (; n_ok=0), [row], PAIN.PlotSeries[], v, "0/1", "V-UNIT", "")
    r = PAIN._as_information_case(mk("CYL2D_WEYL", :not_met))
    @test r.verdict === :no_verdict && r.inputs_echo.original_verdict === :not_met && r.inputs_echo.n_ok == 0
    @test occursin("not a pass: not met, 0/1", r.reason) && r.table == [row]
    @test PAIN._as_information_case(mk("T1", :not_met)).verdict === :not_met               # a validation case is untouched
    @test PAIN._as_information_case(mk("CYL2D_WEYL", :no_verdict)).reason == "0/1"
    # underlying_verdict: the recorded outcome of an information case, else the verdict
    @test PAIN.underlying_verdict(r) === :not_met && PAIN.underlying_verdict(mk("T1", :met)) === :met
    # Phase 85: the met cases that keep a verdict compare with measurement (E) or reproduce a PAIN printout (P)
    keep = ["T1_F1A_FILL", "R996_FIG14", "R996_FIG12", "R996_FIG13A", "PER_FIG7", "BLK_P68", "MRP_APPD", "CYL2D_C1"]
    @test !any(id -> haskey(PAIN.INFORMATION_ONLY_CASES, id), keep)
    @test all(id -> haskey(PAIN.INFORMATION_ONLY_CASES, id), ["UT_GRID", "MRP_INPUT_QA", "BPM_RP1218", "F1A_GUTIN", "ISO_SIL"])
end
