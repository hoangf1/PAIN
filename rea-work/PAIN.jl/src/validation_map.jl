# Validation map (single total flowchart) + per-case metadata for the GUI "Validation map" tab.
# Texts and map structure come from docs/VALIDATION_GUIDELINE.md §2.13 (single source of truth).

struct CaseInfo
    id::String
    title::String
    category::Symbol      # :verification | :experiment | :calibrated | :input_qa | :extrap | :deferred | :display
    kind::Symbol          # :runnable | :replay | :report | :pkgtest | :deferred
    source::String
    verifies::String
    why::String
    meaning::String
    missing::String
    recorded::String
    explanation::String
    map_id::String
    block_id::String
end

struct MapBlock
    id::String
    title::String
    code::String
    note::String
    what_it_does::String
    cases::Vector{String}
    col::Int
    row::Int
    feeds::Vector{String}
    group::String
    role::String          # input | function | output | check | ""
    group_title::String
end

struct ValidationMap
    id::String
    title::String
    intro::String          # same text as what_is (QML / older callers)
    what_is::String
    how_to_read::String
    blocks::Vector{MapBlock}
end

const CASE_INFO = Dict{String,CaseInfo}()
const VALIDATION_MAPS = ValidationMap[]

const _MISSING_DOC = "(missing in VALIDATION_GUIDELINE.md §2.13)"

"""Resolve path to `docs/VALIDATION_GUIDELINE.md` relative to the package."""
function validation_guideline_path()
    return normpath(joinpath(@__DIR__, "..", "..", "docs", "VALIDATION_GUIDELINE.md"))
end

function _field_value(fields::Dict{String,String}, key::AbstractString; required::Bool=true, id::AbstractString="")
    v = get(fields, key, "")
    if required && isempty(strip(v))
        error("VALIDATION_GUIDELINE.md §2.13: missing or empty **$key:** for $id")
    end
    return v
end

function _parse_bold_fields(body::AbstractString)
    fields = Dict{String,String}()
    last_key = nothing
    for line in eachline(IOBuffer(String(body)))
        m = match(r"^\*\*([^*]+):\*\*\s*(.*)$", line)
        if m !== nothing
            last_key = String(m.captures[1])
            fields[last_key] = String(m.captures[2])
        elseif last_key !== nothing
            # Continuation lines (Inputs:/Equations:/Outputs: under Explanation) keep newlines for QML Text.
            fields[last_key] *= "\n" * String(line)
        end
    end
    # Allow a single-line Explanation that embeds literal \n between the three labelled lines.
    for (k, v) in pairs(fields)
        if occursin("\\n", v)
            fields[k] = replace(v, "\\n" => "\n")
        end
    end
    return fields
end

function _parse_position(s::AbstractString; id::AbstractString="")
    t = strip(String(s))
    isempty(t) && return (0, 0)
    m = match(r"^(-?\d+)\s*,\s*(-?\d+)$", t)
    m === nothing && error("VALIDATION_GUIDELINE.md §2.13: Block $id bad Position: $t (want col,row)")
    return (parse(Int, m.captures[1]), parse(Int, m.captures[2]))
end

function _parse_feeds(s::AbstractString)
    t = strip(String(s))
    isempty(t) && return String[]
    return String[String(strip(p)) for p in split(t, r"\s*,\s*") if !isempty(strip(p))]
end

"""Parse §2.13 from the guideline Markdown. Returns (maps, cases)."""
function parse_validation_guideline_section(md::AbstractString)
    # Isolate §2.13 body (from heading to next ## or end).
    m213 = match(r"(?ms)^## 2\.13 Validation case reference[^\n]*\n(.*?)(?=^## |\z)", md)
    m213 === nothing && error("VALIDATION_GUIDELINE.md: missing section '## 2.13 Validation case reference'")
    body = String(m213.captures[1])

    maps = ValidationMap[]
    cases = Dict{String,CaseInfo}()
    case_order = String[]  # document order
    cur_map_id = ""
    cur_map_fields = Dict{String,String}()
    cur_blocks = MapBlock[]

    function flush_map!()
        isempty(cur_map_id) && return
        title = _field_value(cur_map_fields, "Title"; id="Map: $cur_map_id")
        what = _field_value(cur_map_fields, "What this map is"; id="Map: $cur_map_id")
        how = _field_value(cur_map_fields, "How to read it"; id="Map: $cur_map_id")
        push!(maps, ValidationMap(cur_map_id, title, what, what, how, copy(cur_blocks)))
        empty!(cur_blocks)
        empty!(cur_map_fields)
        cur_map_id = ""
        return nothing
    end

    function finish_block!(bid, bfields)
        title = _field_value(bfields, "Title"; id="Block: $bid")
        what = _field_value(bfields, "What this stage does"; id="Block: $bid")
        code = get(bfields, "Code", "")
        note = get(bfields, "Note", "")
        col, row = _parse_position(get(bfields, "Position", "0,0"); id=bid)
        feeds = _parse_feeds(get(bfields, "Feeds", ""))
        group = strip(get(bfields, "Group", ""))
        role = strip(get(bfields, "Role", ""))
        group_title = strip(get(bfields, "Group title", ""))
        if !isempty(role) && !(role in ("input", "function", "output", "check"))
            error("VALIDATION_GUIDELINE.md §2.13: Block $bid bad Role: $role")
        end
        push!(cur_blocks, MapBlock(bid, title, code, note, what, String[], col, row, feeds, group, role, group_title))
        return nothing
    end

    # Split on ### Map: / #### Block: / ### Case:
    parts = split(body, r"(?m)(?=^#{3,4} )")
    for part in parts
        isempty(strip(part)) && continue
        if (mm = match(r"(?ms)^### Map:\s*(\S+)\s*\n(.*)$", part)) !== nothing
            flush_map!()
            cur_map_id = String(mm.captures[1])
            cur_map_fields = _parse_bold_fields(mm.captures[2])
            empty!(cur_blocks)
        elseif (mm = match(r"(?ms)^#### Block:\s*(\S+)\s*\n(.*)$", part)) !== nothing
            isempty(cur_map_id) && error("VALIDATION_GUIDELINE.md §2.13: Block $(mm.captures[1]) before any Map")
            finish_block!(String(mm.captures[1]), _parse_bold_fields(mm.captures[2]))
        elseif (mm = match(r"(?ms)^### Case:\s*(\S+)\s*\n(.*)$", part)) !== nothing
            id = String(mm.captures[1])
            fields = _parse_bold_fields(mm.captures[2])
            title = _field_value(fields, "Title"; id="Case: $id")
            map_block = _field_value(fields, "Map / block"; id="Case: $id")
            parts_mb = split(map_block, r"\s*/\s*"; limit=2)
            length(parts_mb) == 2 || error("VALIDATION_GUIDELINE.md §2.13: Case $id bad Map / block: $map_block")
            map_id = String(strip(parts_mb[1]))
            block_id = String(strip(parts_mb[2]))
            cat = Symbol(_field_value(fields, "Category"; id="Case: $id"))
            kind = Symbol(_field_value(fields, "Kind"; id="Case: $id"))
            cat in (:verification, :experiment, :calibrated, :input_qa, :extrap, :deferred, :display) ||
                error("VALIDATION_GUIDELINE.md §2.13: Case $id bad Category: $cat")
            kind in (:runnable, :replay, :report, :pkgtest, :deferred) ||
                error("VALIDATION_GUIDELINE.md §2.13: Case $id bad Kind: $kind")
            cases[id] = CaseInfo(
                id, title, cat, kind,
                _field_value(fields, "Source"; id="Case: $id"),
                _field_value(fields, "What it tests"; id="Case: $id"),
                _field_value(fields, "Why it is here"; id="Case: $id"),
                _field_value(fields, "A pass means"; id="Case: $id"),
                _field_value(fields, "Not covered"; id="Case: $id"),
                _field_value(fields, "Recorded outcome"; id="Case: $id"),
                _field_value(fields, "Explanation"; id="Case: $id"),
                map_id, block_id,
            )
            push!(case_order, id)
        end
    end
    flush_map!()

    # Attach cases to blocks in document order.
    block_index = Dict{Tuple{String,String},MapBlock}()
    for m in maps
        for b in m.blocks
            block_index[(m.id, b.id)] = b
        end
    end
    for id in case_order
        info = cases[id]
        key = (info.map_id, info.block_id)
        haskey(block_index, key) ||
            error("VALIDATION_GUIDELINE.md §2.13: Case $id Map / block $(info.map_id) / $(info.block_id) not found")
        push!(block_index[key].cases, id)
    end

    # Validate Feeds targets + acyclicity + reachability when any block declares Feeds/Position.
    for m in maps
        ids = Set(b.id for b in m.blocks)
        by_id = Dict(b.id => b for b in m.blocks)
        has_layout = any(!isempty(b.feeds) || b.col != 0 || b.row != 0 || !isempty(b.group) for b in m.blocks)
        has_layout || continue
        for b in m.blocks
            for f in b.feeds
                f in ids || error("VALIDATION_GUIDELINE.md §2.13: Map $(m.id) Block $(b.id) Feeds unknown id: $f")
            end
        end
        # Cycle detection (DFS).
        WHITE, GRAY, BLACK = 0, 1, 2
        color = Dict(id => WHITE for id in ids)
        function visit(u)
            color[u] = GRAY
            for v in by_id[u].feeds
                color[v] == GRAY && error("VALIDATION_GUIDELINE.md §2.13: Map $(m.id) cycle at $u → $v")
                color[v] == WHITE && visit(v)
            end
            color[u] = BLACK
            return nothing
        end
        for id in ids
            color[id] == WHITE && visit(id)
        end
        # Reachability from roots (no incoming Feeds).
        incoming = Dict(id => 0 for id in ids)
        for b in m.blocks
            for f in b.feeds
                incoming[f] = get(incoming, f, 0) + 1
            end
        end
        roots = [id for id in ids if incoming[id] == 0]
        isempty(roots) && error("VALIDATION_GUIDELINE.md §2.13: Map $(m.id) has no root blocks")
        seen = Set{String}()
        stack = copy(roots)
        while !isempty(stack)
            u = pop!(stack)
            u in seen && continue
            push!(seen, u)
            for v in by_id[u].feeds
                push!(stack, v)
            end
        end
        missing = setdiff(ids, seen)
        isempty(missing) || error("VALIDATION_GUIDELINE.md §2.13: Map $(m.id) unreachable blocks: $(join(sort!(collect(missing)), ", "))")
    end

    return maps, cases
end

"""Load §2.13 into CASE_INFO and VALIDATION_MAPS. Raises on missing required fields."""
function load_validation_docs!(path::AbstractString=validation_guideline_path())
    isfile(path) || error("VALIDATION_GUIDELINE.md not found at $path")
    md = read(path, String)
    maps, cases = parse_validation_guideline_section(md)
    empty!(CASE_INFO)
    empty!(VALIDATION_MAPS)
    for (id, info) in cases
        CASE_INFO[id] = info
    end
    append!(VALIDATION_MAPS, maps)
    return nothing
end

"""Re-parse §2.13 so an edited .md shows in the GUI without restart."""
function reload_validation_docs!()
    load_validation_docs!()
    return nothing
end

function _map_by_id(map_id::AbstractString)
    for m in VALIDATION_MAPS
        m.id == map_id && return m
    end
    error("unknown validation map id: $map_id")
end

"""Soft lookup for GUI: missing CASE_INFO → placeholder fields, no crash."""
function _case_info_or_missing(id::AbstractString)
    if haskey(CASE_INFO, id)
        return CASE_INFO[id]
    end
    return CaseInfo(
        String(id), _MISSING_DOC, :deferred, :deferred,
        _MISSING_DOC, _MISSING_DOC, _MISSING_DOC, _MISSING_DOC,
        _MISSING_DOC, _MISSING_DOC, _MISSING_DOC, "", "",
    )
end

"""JSON for one flowchart: map + per-case chip fields (id, title, category, kind, recorded, last, runnable)."""
function validation_map_json(map_id::AbstractString; last::Dict{String,Symbol}=Dict{String,Symbol}())
    m = _map_by_id(map_id)
    blocks = []
    for b in m.blocks
        cases = []
        for id in b.cases
            info = _case_info_or_missing(id)
            last_sym = get(last, id, :not_run)
            runnable = if info.kind === :pkgtest || info.kind === :deferred
                false
            elseif haskey(VALIDATION_CASES, id)
                validation_case_runnable(id)
            else
                false
            end
            push!(cases, Dict(
                "id" => id,
                "title" => info.title,
                "category" => String(info.category),
                "kind" => String(info.kind),
                "recorded" => info.recorded,
                "last" => String(last_sym),
                "runnable" => runnable,
            ))
        end
        push!(blocks, Dict(
            "id" => b.id,
            "title" => b.title,
            "code" => b.code,
            "note" => b.note,
            "what_it_does" => b.what_it_does,
            "cases" => cases,
            "col" => b.col,
            "row" => b.row,
            "feeds" => b.feeds,
            "group" => b.group,
            "role" => b.role,
            "group_title" => b.group_title,
        ))
    end
    # Group metadata for QML stage frames (title from first block that declares Group title).
    groups = Dict{String,Dict{String,Any}}()
    for b in m.blocks
        isempty(b.group) && continue
        g = get!(groups, b.group) do
            Dict{String,Any}("id" => b.group, "title" => "", "block_ids" => String[])
        end
        push!(g["block_ids"], b.id)
        if !isempty(b.group_title)
            g["title"] = b.group_title
        end
    end
    group_list = [groups[k] for k in sort!(collect(keys(groups)))]
    return JSON3.write(Dict(
        "id" => m.id,
        "title" => m.title,
        "intro" => m.intro,
        "what_is" => m.what_is,
        "how_to_read" => m.how_to_read,
        "blocks" => blocks,
        "groups" => group_list,
    ))
end

"""JSON of CaseInfo + criterion (if registered) + source image path when present."""
function case_info_json(id::AbstractString)
    info = _case_info_or_missing(id)
    d = Dict{String,Any}(
        "id" => info.id,
        "title" => info.title,
        "category" => String(info.category),
        "kind" => String(info.kind),
        "source" => info.source,
        "verifies" => info.verifies,
        "why" => info.why,
        "meaning" => info.meaning,
        "missing" => info.missing,
        "recorded" => info.recorded,
        "explanation" => info.explanation,
        "criterion_text" => "",
        "criterion_date" => "",
        "source_image" => "",
        "in_registry" => haskey(VALIDATION_CASES, id),
        "detail_kind" => "case",
    )
    if haskey(VALIDATION_CASES, id)
        c = VALIDATION_CASES[id]
        d["criterion_text"] = c.criterion_text
        d["criterion_date"] = c.criterion_date
    end
    src = validation_source_figure_path(id)
    if isfile(src)
        d["source_image"] = src
    end
    return JSON3.write(d)
end

"""JSON for a map block detail panel (title, what_it_does, code, role)."""
function map_block_info_json(map_id::AbstractString, block_id::AbstractString)
    m = _map_by_id(map_id)
    for b in m.blocks
        if b.id == block_id
            return JSON3.write(Dict(
                "detail_kind" => "block",
                "id" => b.id,
                "title" => b.title,
                "code" => b.code,
                "note" => b.note,
                "what_it_does" => b.what_it_does,
                "role" => b.role,
                "group" => b.group,
                "group_title" => b.group_title,
                "col" => b.col,
                "row" => b.row,
                "feeds" => b.feeds,
                "cases" => b.cases,
            ))
        end
    end
    return JSON3.write(Dict(
        "detail_kind" => "block",
        "id" => String(block_id),
        "title" => _MISSING_DOC,
        "code" => "",
        "note" => "",
        "what_it_does" => _MISSING_DOC,
        "role" => "",
        "group" => "",
        "group_title" => "",
        "col" => 0,
        "row" => 0,
        "feeds" => String[],
        "cases" => String[],
    ))
end

"""Registry ids in map → block order (excludes UT_* / non-registry nodes)."""
function validation_map_case_order()
    out = String[]
    for m in VALIDATION_MAPS
        for b in m.blocks
            for id in b.cases
                haskey(VALIDATION_CASES, id) && push!(out, id)
            end
        end
    end
    return out
end

# Layout constants must match gui/main.qml (mapCellW/H, mapPad, block 148×44, chip rows).
const _MAP_CELL_W = 168
const _MAP_CELL_H = 118
const _MAP_PAD = 28
const _MAP_BLOCK_W = 148
const _MAP_BLOCK_H = 44
const _MAP_GRP_PAD_X = 10
const _MAP_GRP_PAD_TOP = 22
const _MAP_GRP_PAD_BOT = 10

"""Chip stack height under a title box (Flow ≈2 chips/row, 30 px/row) — same as QML `blockChipExtra`."""
function _map_block_chip_extra(n_cases::Integer)
    n_cases <= 0 && return 0
    rows = cld(n_cases, 2)
    return 4 + rows * 30
end

"""
Axis-aligned stage-group rectangles from map model data (own blocks only, including check chips).
Matches QML `groupBounds`. Returns `Dict(group_id => (x, y, w, h))`.
"""
function validation_map_group_rects(map_id::AbstractString="total")
    m = _map_by_id(map_id)
    rects = Dict{String,NamedTuple{(:x, :y, :w, :h),NTuple{4,Float64}}}()
    by_group = Dict{String,Vector{MapBlock}}()
    for b in m.blocks
        isempty(b.group) && continue
        push!(get!(() -> MapBlock[], by_group, b.group), b)
    end
    for (gid, blks) in by_group
        min_x = Inf
        min_y = Inf
        max_x = -Inf
        max_y = -Inf
        for b in blks
            x = Float64(_MAP_PAD + b.col * _MAP_CELL_W)
            y = Float64(_MAP_PAD + b.row * _MAP_CELL_H)
            extra = Float64(_map_block_chip_extra(length(b.cases)))
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x + _MAP_BLOCK_W)
            max_y = max(max_y, y + _MAP_BLOCK_H + extra)
        end
        rects[gid] = (
            x = min_x - _MAP_GRP_PAD_X,
            y = min_y - _MAP_GRP_PAD_TOP,
            w = max(40.0, (max_x + _MAP_GRP_PAD_X) - (min_x - _MAP_GRP_PAD_X)),
            h = max(40.0, (max_y + _MAP_GRP_PAD_BOT) - (min_y - _MAP_GRP_PAD_TOP)),
        )
    end
    return rects
end

"""True if two axis-aligned rects `(x,y,w,h)` have empty interior intersection (edges may touch)."""
function _map_rects_disjoint(a, b)
    return (a.x + a.w <= b.x) || (b.x + b.w <= a.x) ||
           (a.y + a.h <= b.y) || (b.y + b.h <= a.y)
end

"""Assert every stage group rectangle is pairwise disjoint (smoke / layout check)."""
function assert_validation_map_groups_disjoint(map_id::AbstractString="total")
    rects = validation_map_group_rects(map_id)
    ids = sort!(collect(keys(rects)))
    for i in 1:length(ids)
        for j in (i + 1):length(ids)
            a, b = rects[ids[i]], rects[ids[j]]
            _map_rects_disjoint(a, b) || error(
                "validation map group rectangles overlap: $(ids[i])=$a vs $(ids[j])=$b")
        end
    end
    # No block of another group may lie inside a group's rectangle.
    m = _map_by_id(map_id)
    for b in m.blocks
        isempty(b.group) && continue
        bx = Float64(_MAP_PAD + b.col * _MAP_CELL_W)
        by = Float64(_MAP_PAD + b.row * _MAP_CELL_H)
        cx, cy = bx + _MAP_BLOCK_W / 2, by + _MAP_BLOCK_H / 2
        for (gid, r) in rects
            gid == b.group && continue
            inside = (r.x < cx < r.x + r.w) && (r.y < cy < r.y + r.h)
            inside && error("block $(b.id) (group $(b.group)) lies inside group rectangle $gid=$r")
        end
    end
    return rects
end

# Module-load fill from the guideline (raises if §2.13 is incomplete).
load_validation_docs!()
