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
    @test Set(r.id for r in vrows) == Set(id for id in keys(PAIN.CASE_INFO) if PAIN.on_validation_map(id; rec))
    @test all(r -> r.verdict == "no verdict", filter(r -> !PAIN.on_validation_map(r.id; rec), all_rows))
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
    @test count(l -> startswith(l, "| ") && !startswith(l, "| Chain span"), split(md, '\n')) == nv
    @test occursin("chain_coverage_verdict.png", md)
    pv, pa = PAIN.write_coverage_figures(joinpath(UNIT_OUT, "coverage"); rec)
    png_height(p) = Int(ntoh(reinterpret(UInt32, read(p)[21:24])[1]))   # IHDR height
    @test isfile(pv) && isfile(pa) && png_height(pa) > png_height(pv) > 0   # every case: more rows than the verdict cases
    @test PAIN.JSON3.read(PAIN.case_info_json("NOPE"; recorded_errors=Dict{String,NamedTuple}())).compared_with == ""
end
