# Unit tests: src/validation_coverage.jl (Phase 134, 2026-11-05). Every documented case has a chain span and a
# reference; no case with a verdict is a verification; the rows, JSON, §0 table and figures follow §2.13.
@testset "chain coverage rows (Phase 134)" begin
    rec = PAIN.recorded_case_errors()
    all_rows = PAIN.coverage_rows(; rec)
    @test length(all_rows) == length(PAIN.CASE_INFO)                         # every §2.13 case carries a chain span
    @test all(r -> 1 <= r.from <= r.to <= length(PAIN.CHAIN_STAGES), all_rows)
    @test all(r -> r.reference in (:measurement, :nasa, :verification), all_rows)
    # Rule (CLAUDE.md): only a comparison with measurement or NASA's printed prediction may carry a verdict.
    vrows = PAIN.coverage_rows(; rec, verdict_only=true)
    @test !isempty(vrows) && all(r -> r.verdict in ("met", "not met"), vrows)
    bad = [r.id for r in vrows if r.reference === :verification]
    isempty(bad) || @info "verdict cases marked verification" bad
    @test isempty(bad)
    @test Set(r.id for r in vrows) == Set(id for id in keys(PAIN.CASE_INFO) if PAIN.has_verdict(id; rec))
    @test all(r -> r.verdict == "no verdict", filter(r -> !PAIN.has_verdict(r.id; rec), all_rows))
    # Spot checks against the §2.13 text: the 695A dB(A) case runs the whole chain, R172428_EXP starts at the skin.
    byid = Dict(r.id => r for r in all_rows)
    @test (byid["AC_C695A_DBA"].from, byid["AC_C695A_DBA"].to, byid["AC_C695A_DBA"].reference) ==
          (1, length(PAIN.CHAIN_STAGES), :measurement)
    @test (PAIN.CHAIN_STAGES[byid["R172428_EXP"].from], PAIN.CHAIN_STAGES[byid["R172428_EXP"].to]) ==
          ("Skin field", "Interior tones") && byid["R172428_EXP"].reference === :measurement
    @test byid["BLK_P68"].reference === :nasa
    # Sorted by first stage, then last stage.
    @test issorted([(r.from, r.to) for r in all_rows])
end
@testset "chain coverage JSON, §0 table and figures (Phase 134)" begin
    rec = PAIN.recorded_case_errors()
    j = PAIN.JSON3.read(PAIN.coverage_json(; rec))
    @test collect(j.stages) == collect(PAIN.CHAIN_STAGES) && length(j.references) == 3
    @test length(j.rows) == length(PAIN.CASE_INFO) && all(r -> 0 <= r.from <= r.to <= 8, j.rows)   # 0-based for QML
    jv = PAIN.JSON3.read(PAIN.coverage_json(; rec, verdict_only=true))
    nv = length(PAIN.coverage_rows(; rec, verdict_only=true))
    @test length(jv.rows) == nv
    md = PAIN.coverage_markdown(; rec)
    @test count(l -> startswith(l, "| ") && occursin(" → ", l), split(md, '\n')) == nv   # the chart table; the cause table follows
    @test occursin("chain_coverage_verdict.png", md)
    pv, pa = PAIN.write_coverage_figures(joinpath(UNIT_OUT, "coverage"); rec)
    png_height(p) = Int(ntoh(reinterpret(UInt32, read(p)[21:24])[1]))   # IHDR height
    @test isfile(pv) && isfile(pa) && png_height(pa) > png_height(pv) > 0   # every case: more rows than the verdict cases
    @test PAIN.JSON3.read(PAIN.case_info_json("NOPE"; recorded_errors=Dict{String,NamedTuple}())).compared_with == ""
end
@testset "every verdict case has a source figure and a title (Phase 146e)" begin
    rec = PAIN.recorded_case_errors()
    vrows = PAIN.coverage_rows(; rec, verdict_only=true)
    nofig = [r.id for r in vrows if isempty(r.figure) || isempty(r.title)]
    isempty(nofig) || @info "verdict cases without a source figure or title" nofig
    @test isempty(nofig)
    @test PAIN._coverage_figure("NOPE") == ""
    @test PAIN._coverage_figure("R172428_EXP") == "NASA CR-172428, Table 5 / Table 10, PDF p. 89"
    @test occursin("\"figure\":\"NASA CR-172428, Table 5 / Table 10, PDF p. 89\"", PAIN.coverage_json(; rec))
end
@testset "NASA's own printout on the same gate (Phases 136f, 137c)" begin
    # hand count from the data files (2026-11-10): NASA App. B / Table 10 within ±4 dB of measured at 5 of 9 tones;
    # TP-1964 Fig. 8 ref. 2 within ±5 dB of measured in 12 of 18 bands 100–5000 Hz (under 75 %)
    g = PAIN.nasa_printout_on_gate("R172428_EXP")
    @test (g.n_ok, g.n, g.met) == (5, 9, false)
    t = PAIN.nasa_printout_on_gate("NR_TP1964")
    @test (t.n_ok, t.n, t.met) == (12, 18, false) && PAIN.nasa_printout_on_gate("NR_TP1964_XOVER") == t
    # H1–H3 sums per rpm, NASA − measured (hand sums 2026-11-10): dB −12.7, +1.2, −8.3; dB(A) −7.2, +0.8, −4.8
    for id in ("R172428_DBA_EXP", "R172428_DB_EXP")
        s = PAIN.nasa_printout_on_gate(id)
        @test (s.n_ok, s.n, s.met) == (1, 3, false)
    end
    @test PAIN.nasa_printout_on_gate("T1") === nothing && !PAIN.method_limit("T1") && PAIN.method_limit("R172428_EXP")
    rec = PAIN.recorded_case_errors()
    @test occursin("misses too: method limit", PAIN.why_not_met_markdown(; rec))
    rows = PAIN.coverage_rows(; rec)
    @test only(r for r in rows if r.id == "R172428_EXP").method_limit
    @test !any(r -> r.method_limit, filter(r -> r.verdict == "no verdict", rows))     # the mark is for verdict cases only
    @test count(r -> r.method_limit, rows) == 2     # R172428_EXP, NR_TP1964_XOVER: the others carry no verdict (135f)
end
@testset "families and derived cases (Phase 145d)" begin
    @test all(id -> haskey(PAIN.VALIDATION_CASES, id), keys(PAIN.CASE_FAMILIES))            # no stale or misspelt ids
    for (id, f) in PAIN.CASE_FAMILIES
        isempty(f.derived_from) && continue
        p = PAIN.case_family(f.derived_from)
        @test p.family == f.family && isempty(p.derived_from)       # a parent is in the same family and is not derived
    end
    @test PAIN.case_family("NOPE") == (family="", derived_from="")
    rec = PAIN.recorded_case_errors()
    rows = PAIN.coverage_rows(; rec, verdict_only=true)
    all_rows = PAIN.coverage_rows(; rec)
    dba = only(r for r in all_rows if r.id == "R172428_DBA_EXP")
    @test dba.derived_from == "R172428_EXP" && dba.verdict == "no verdict"        # a sum: no verdict of its own (135f)
    @test all(r -> isempty(r.derived_from), rows)                 # fails if a derived case regains a verdict
    @test occursin("$(length(rows)) cases with a verdict, $(length(rows)) independent comparisons",
                   PAIN.coverage_markdown(; rec))
    @test count(r -> r.family == "Report 996 static sound levels", rows) == 3
end
@testset "cause record per not-met case (Phase 145e)" begin
    rec = PAIN.recorded_case_errors()
    notmet = [id for (id, r) in rec if r.verdict == "not_met" && !PAIN.no_verdict_by_rule(id)]
    missing_cause = [id for id in notmet if PAIN.case_cause(id) === nothing]
    isempty(missing_cause) || @info "not-met cases without a cause record" missing_cause
    @test isempty(missing_cause)                                                  # every not-met case on the chart says why
    @test all(c -> c.kind in PAIN.CAUSE_KINDS, values(PAIN.CASE_CAUSES))
    @test all(c -> isfile(joinpath(PAIN._VAL_REPORT_DIR, c.source)), values(PAIN.CASE_CAUSES))   # each cites a report that exists
    md = PAIN.why_not_met_markdown(; rec)
    @test all(id -> occursin("| `$id` |", md), notmet) && !occursin("no cause recorded", md)
    fake = merge(rec, Dict("NO_SUCH_CASE" => rec[first(notmet)]))
    @test occursin("no cause recorded", PAIN.why_not_met_markdown(; rec=fake))     # a case without a record shows it
end
