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
    @test allunique(ids) && union(Set(ids), PAIN.TEST_ONLY_CASES) == Set(keys(PAIN.VALIDATION_CASES))   # listed, or test-only (ISSUE-040)
    @test isempty(intersect(Set(ids), PAIN.TEST_ONLY_CASES)) && all(id -> !haskey(PAIN.CASE_INFO, id), PAIN.TEST_ONLY_CASES)
    @test all(id -> haskey(PAIN.VALIDATION_CASES, id), PAIN.TEST_ONLY_CASES) && length(PAIN.TEST_ONLY_CASES) == 43
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
    r = PAIN._as_information_case(mk("UT_GRID", :not_met))
    @test r.verdict === :no_verdict && r.inputs_echo.original_verdict === :not_met && r.inputs_echo.n_ok == 0
    @test occursin("not a pass: not met, 0/1", r.reason) && r.table == [row]
    @test PAIN._as_information_case(mk("R172428_EXP", :not_met)).verdict === :not_met     # a validation case is untouched
    @test PAIN._as_information_case(mk("UT_GRID", :no_verdict)).reason == "0/1"
    # underlying_verdict: the recorded outcome of an information case, else the verdict
    @test PAIN.underlying_verdict(r) === :not_met && PAIN.underlying_verdict(mk("R172428_EXP", :met)) === :met
    # Phase 85: the met cases that keep a verdict compare with measurement (E) or reproduce a PAIN printout (P)
    keep = ["R996_FIG14", "R996_FIG12", "R996_FIG13A", "PER_FIG7", "MRP_APPD", "CYL2D_C1"]
    @test !any(id -> haskey(PAIN.INFORMATION_ONLY_CASES, id), keep)
    @test all(id -> haskey(PAIN.INFORMATION_ONLY_CASES, id), ["UT_GRID", "MRP_INPUT_QA", "BPM_RP1218", "F1A_GUTIN", "ISO_SIL"])
    # Phase 118a: the 14 cases (18 since Phases 121-125) whose compared quantity rests on an input that is not printed or measured carry no verdict,
    # named by the rule; full-input cases on both sides of the map keep theirs
    p118 = ["BBN_CIRC",   # the T1/T2 family and the propeller broadband cases retired in Phase 150e (2026-11-11)
            "AC_C695A_DBA", "AC_C695A_TONES", "AC_C695A_EXT", "AC_C695A_SEAT",   # Phases 121-125 (2026-11-03): assumed 695A blade and cabin section
            "R996_PHASE", "E22_HF_CODE", "NR_TP1964_REF2", "NR_PROP_TP2444",   # Phase 135f (2026-11-10); _BR, _PF and E22_BR retired in Phase 137a
            "NR_TP1964_XOVER_REF2",   # Phase 138b (2026-11-10): NASA's ref. 2 inputs not printed
            "E14_LOSS"]   # ISSUE-037 (2026-11-12): facing side and end-plate backing not printed
    @test all(PAIN.input_incomplete, p118) && !PAIN.input_incomplete("UT_GRID") && !PAIN.input_incomplete("R172428_EXP")
    @test count(PAIN.input_incomplete, keys(PAIN.INFORMATION_ONLY_CASES)) == length(p118)
    @test !any(id -> haskey(PAIN.INFORMATION_ONLY_CASES, id),
               ["R172428_EXP", "NR_TP1964_XOVER", "FLIGHT_MODES", "R996_LOADS", "PER_FIG8"])   # on the chart (Phase 135f)
    r118 = PAIN._as_information_case(mk("BBN_CIRC", :not_met))
    @test r118.verdict === :no_verdict && occursin("the 2026-11-02 input rule (inputs incomplete", r118.reason)
    @test occursin("the 2026-10-29 rule", PAIN._as_information_case(mk("UT_GRID", :not_met)).reason)
    # 2026-11-12: a result reached after a change located with the case's own data names the independence rule
    @test PAIN.independence_rule("R172428_ETA") && !PAIN.independence_rule("UT_GRID") && !PAIN.input_incomplete("R172428_ETA")
    @test occursin("the 2026-11-09 independence rule", PAIN._as_information_case(mk("R172428_ETA", :met)).reason)
    # Phase 86: diagnostic re-runs carry no verdict; the case each re-runs keeps its verdict
    @test all(id -> haskey(PAIN.VALIDATION_CASES, id), keys(PAIN.DIAGNOSTIC_CASES))
    @test isempty(intersect(keys(PAIN.DIAGNOSTIC_CASES), keys(PAIN.INFORMATION_ONLY_CASES)))
    d = PAIN._as_information_case(mk("R172428_CODE_DEFAULT", :not_met))
    @test d.verdict === :no_verdict && PAIN.underlying_verdict(d) === :not_met && startswith(d.reason, "diagnostic: ")
    @test PAIN.no_verdict_by_rule("APPB_ETA_N_BAND") && PAIN.no_verdict_by_rule("UT_GRID") && !PAIN.no_verdict_by_rule("R172428_EXP") && PAIN.no_verdict_by_rule("R172428_CODE")
    @test PAIN._as_information_case(mk("R172428_EXP", :not_met)).verdict === :not_met
    @test startswith(PAIN._as_information_case(mk("R172428_CODE", :not_met)).reason, "diagnostic: ")   # old program form (Phase 136a)
    # Phase 150e (2026-11-11): a retired case is registered nowhere, and each names a report that exists
    @test !isempty(PAIN.RETIRED_CASES) && all(id -> !haskey(PAIN.VALIDATION_CASES, id) && !(id in PAIN.VALIDATION_CASE_ORDER) &&
              !haskey(PAIN.DIAGNOSTIC_CASES, id) && !haskey(PAIN.INFORMATION_ONLY_CASES, id) && !haskey(PAIN.CASE_INFO, id), keys(PAIN.RETIRED_CASES))
    @test all(v -> isempty(v[2]) || isfile(joinpath(PAIN._VAL_REPORT_DIR, v[2])), values(PAIN.RETIRED_CASES))
end
