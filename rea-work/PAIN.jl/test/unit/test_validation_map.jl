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
    m = PAIN._map_by_id("total")
    j = PAIN.JSON3.read(PAIN.validation_map_json("total"; recorded_errors=Dict{String,NamedTuple}()))
    @test length(j.blocks) == length(m.blocks) && j.chip_row_h == PAIN.VALIDATION_MAP_CHIP_ROW_H
    @test all(c.id in m.blocks[i].cases for (i, b) in enumerate(j.blocks) for c in b.cases)
    ci = PAIN.JSON3.read(PAIN.case_info_json("T1"; recorded_errors=Dict{String,NamedTuple}()))
    @test ci.in_registry && ci.criterion_text == PAIN.VALIDATION_CASES["T1"].criterion_text
    bj = PAIN.JSON3.read(PAIN.map_block_info_json("total", m.blocks[1].id))
    @test bj.id == m.blocks[1].id && bj.detail_kind == "block"
    @test PAIN.JSON3.read(PAIN.map_block_info_json("total", "NO_BLOCK")).title == PAIN._MISSING_DOC
    order = PAIN.validation_map_case_order()
    @test all(haskey(PAIN.VALIDATION_CASES, id) for id in order)
    @test PAIN._map_block_chip_extra(0) == 0 && PAIN._map_block_chip_extra(3) == 4 + 3 * PAIN.VALIDATION_MAP_CHIP_ROW_H
    # Row tops: a row holding a block with many chips pushes the next row below that block's chips.
    MB(id, row, n) = (; id, col=0, row, cases=["C$k" for k in 1:n])
    ry = PAIN.validation_map_row_y((; blocks=[MB("a", 0, 5), MB("b", 1, 0)]))
    @test ry[2] >= ry[1] + PAIN._MAP_BLOCK_H + PAIN._map_block_chip_extra(5)
    @test ry == PAIN.validation_map_row_y((; blocks=[MB("a", 0, 0), MB("b", 1, 0)])) .+ [0, PAIN._MAP_BLOCK_H + PAIN._map_block_chip_extra(5) + PAIN._MAP_ROW_GAP - PAIN._MAP_CELL_H]
    @test j.row_y == PAIN.validation_map_row_y(m)
    br = PAIN._map_block_rect(MB("a", 0, 5), ry)
    @test br.y == ry[1] && br.h == PAIN._MAP_BLOCK_H + PAIN._map_block_chip_extra(5) && br.w == PAIN._MAP_BLOCK_W
    @test PAIN._map_block_rect((; col=2, row=1, cases=String[]), ry).x == PAIN._MAP_PAD + 2 * PAIN._MAP_CELL_W
    # The old fixed 118 px grid let tall blocks reach the next row in the same column; the row_y layout must not.
    @test any(!PAIN._map_rects_disjoint(
                  (; x=a.col, y=PAIN._MAP_PAD + a.row * PAIN._MAP_CELL_H, w=1, h=PAIN._MAP_BLOCK_H + PAIN._map_block_chip_extra(length(a.cases))),
                  (; x=b.col, y=PAIN._MAP_PAD + b.row * PAIN._MAP_CELL_H, w=1, h=PAIN._MAP_BLOCK_H + PAIN._map_block_chip_extra(length(b.cases))))
              for a in m.blocks for b in m.blocks if a !== b && a.col == b.col)
    @test PAIN._map_rects_disjoint((; x=0, y=0, w=1, h=1), (; x=1, y=0, w=1, h=1))      # touching edges
    @test !PAIN._map_rects_disjoint((; x=0, y=0, w=2, h=2), (; x=1, y=1, w=1, h=1))
    @test !isempty(PAIN.validation_map_group_rects("total"))
    @test PAIN.assert_validation_map_groups_disjoint("total") isa AbstractDict           # no overlap error
end
@testset "every map block shows a case with its own figure (Phase 62, criterion 2026-10-23)" begin
    m = PAIN._map_by_id("total")
    nofig = String[]
    for b in m.blocks
        ok = any(id -> haskey(PAIN.VALIDATION_CASES, id) && PAIN.validation_case_runnable(id) &&
                       PAIN._case_info_or_missing(id).kind in (:runnable, :replay), b.cases)
        ok || push!(nofig, b.id)
    end
    isempty(nofig) || @info "map blocks without a runnable case with a figure" nofig
    @test isempty(nofig)
end
