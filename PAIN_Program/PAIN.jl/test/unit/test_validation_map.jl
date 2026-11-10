# Unit tests: src/validation_map.jl (Phase 64). The §2.13 parser on a synthetic document (each error path),
# then the real guideline: every map block holds at least one case with its own figure (Phase 62).
const _MD_OK = """
## 2.13 Validation case reference
### Map: m1
**Title:** M
**What this map is:** W
**How to read it:** H
#### Block: A
**Title:** a
**What this stage does:** x
**Position:** 0,0
**Feeds:** B
**Group:** g1
**Role:** input
**Group title:** G one
#### Block: B
**Title:** b
**What this stage does:** y
**Position:** 1,0
### Case: C1
**Title:** c
**Map / block:** m1 / B
**Category:** verification
**Kind:** runnable
**Chain span:** Skin field → Interior tones
**Compared with:** verification
**Source:** s
**What it tests:** t
**Why it is here:** w
**A pass means:** p
**Not covered:** n
**Recorded outcome:** r
**Explanation:** e line1
Inputs: foo
## 3 Next
"""

@testset "field helpers" begin
    f = PAIN._parse_bold_fields("**A:** one\ncont\n**B:** x\\ny")
    @test f["A"] == "one\ncont" && f["B"] == "x\ny"                                # continuation lines and literal \n
    @test PAIN._field_value(f, "A") == "one\ncont" && PAIN._field_value(f, "Z"; required=false) == ""
    @test_throws ErrorException PAIN._field_value(f, "Z"; id="x")
    @test PAIN._parse_position("3, -1") == (3, -1) && PAIN._parse_position("") == (0, 0)
    @test_throws ErrorException PAIN._parse_position("3;1")
    @test PAIN._parse_feeds(" A, B ,C") == ["A", "B", "C"] && isempty(PAIN._parse_feeds(""))
    @test isfile(PAIN.validation_guideline_path())
end
@testset "parse_validation_guideline_section on a synthetic §2.13" begin
    maps, cases = PAIN.parse_validation_guideline_section(_MD_OK)
    @test length(maps) == 1 && [b.id for b in maps[1].blocks] == ["A", "B"]
    @test maps[1].blocks[2].cases == ["C1"] && maps[1].blocks[1].feeds == ["B"] && maps[1].blocks[1].group_title == "G one"
    @test cases["C1"].explanation == "e line1\nInputs: foo" && cases["C1"].category == :verification
    bad(old, new) = replace(_MD_OK, old => new)
    @test_throws ErrorException PAIN.parse_validation_guideline_section("## 2.1 other\n")
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("**Category:** verification", "**Category:** opinion"))
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("**Kind:** runnable", "**Kind:** maybe"))
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("**Map / block:** m1 / B", "**Map / block:** m1 / Z"))
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("**Feeds:** B", "**Feeds:** Q"))
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("**Position:** 1,0", "**Position:** 1,0\n**Feeds:** A"))   # cycle
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("**Role:** input", "**Role:** boss"))
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("**Source:** s\n", ""))
    # Phase 134: the chain span runs forwards over known stages; the reference is one of the three labels; both required.
    @test (cases["C1"].span_from, cases["C1"].span_to, cases["C1"].reference) == (4, 8, :verification)
    @test PAIN.parse_validation_guideline_section(bad("Skin field → Interior tones", "skin field -> interior tones"))[2]["C1"].span_to == 8
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("Skin field → Interior tones", "Wall modes"))
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("Skin field → Interior tones", "Interior tones → Skin field"))
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("Skin field → Interior tones", "Skin field → Cockpit"))
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("**Compared with:** verification", "**Compared with:** a hunch"))
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("**Chain span:** Skin field → Interior tones\n", ""))
    @test_throws ErrorException PAIN.parse_validation_guideline_section(bad("**Compared with:** verification\n", ""))
end
@testset "load / lookup / JSON on the real guideline" begin
    p = joinpath(UNIT_OUT, "unit_guideline.md")
    write(p, _MD_OK)
    try
        PAIN.load_validation_docs!(p)
        @test length(PAIN.VALIDATION_MAPS) == 1 && haskey(PAIN.CASE_INFO, "C1")
    finally
        rm(p); PAIN.reload_validation_docs!()                                         # restore the real docs
    end
    @test_throws ErrorException PAIN.load_validation_docs!(joinpath(UNIT_OUT, "absent.md"))
    @test PAIN._map_by_id("total").id == "total"
    @test_throws ErrorException PAIN._map_by_id("nope")
    @test PAIN._case_info_or_missing("NOPE").title == PAIN._MISSING_DOC && PAIN._case_info_or_missing("T1").id == "T1"
    ci = PAIN.JSON3.read(PAIN.case_info_json("T1"; recorded_errors=Dict{String,NamedTuple}()))
    @test ci.in_registry && ci.criterion_text == PAIN.VALIDATION_CASES["T1"].criterion_text
    order = PAIN.validation_map_case_order()
    @test all(haskey(PAIN.VALIDATION_CASES, id) for id in order)
    @test sort(order) == sort(PAIN.VALIDATION_CASE_ORDER) && "MRP_D1" in order          # off-block cases too (Validation tab)
    # Phase 147a (2026-11-10): `has_verdict` is the rule the coverage chart uses; the old name is an alias
    @test PAIN.on_validation_map === PAIN.has_verdict
    rec = PAIN.recorded_case_errors()
    @test !PAIN.has_verdict("T1"; rec=Dict{String,NamedTuple}())                          # no snapshot, no verdict
    @test !any(id -> PAIN.has_verdict(id; rec), keys(PAIN.DIAGNOSTIC_CASES))
    @test !any(id -> PAIN.has_verdict(id; rec), keys(PAIN.INFORMATION_ONLY_CASES))
    @test any(id -> PAIN.has_verdict(id; rec), keys(PAIN.CASE_INFO))
end
