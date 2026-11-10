# Per-case metadata from §2.13 for the GUI (Validation and Coverage tabs). The block map these records once drew was
# retired in Phase 147 (2026-11-10); the blocks stay as figure folders and as the Validation tab's case order.
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
    span_from::Int        # Phase 134: CHAIN_STAGES index of the stage the case's given input enters at
    span_to::Int          # … and of the stage of the quantity it compares
    reference::Symbol     # :measurement | :nasa (NASA's printed prediction) | :verification
end

"""The program chain, in order: the stages a case's `**Chain span:**` names (Phase 134), labels as written in §2.13."""
const CHAIN_STAGES = ("Blade and polars", "Blade loads", "Free field", "Skin field", "Wall modes", "Cabin modes",
                      "Damping and trim", "Interior tones", "Bands and dB(A)")
const CASE_REFERENCES = ("measurement" => :measurement, "NASA's printed prediction" => :nasa, "verification" => :verification)
reference_label(r::Symbol) = only(k for (k, v) in CASE_REFERENCES if v === r)

function _parse_chain_span(s::AbstractString; id::AbstractString="")
    p = split(strip(String(s)), r"\s*(?:→|->)\s*")
    length(p) == 2 || error("VALIDATION_GUIDELINE.md §2.13: Case $id bad Chain span: $s (want <stage> → <stage>)")
    idx = map(p) do t
        i = findfirst(==(lowercase(strip(t))), lowercase.(CHAIN_STAGES))
        i === nothing && error("VALIDATION_GUIDELINE.md §2.13: Case $id unknown chain stage: $t")
        i
    end
    idx[1] <= idx[2] || error("VALIDATION_GUIDELINE.md §2.13: Case $id Chain span runs backwards: $s")
    return idx[1], idx[2]
end

function _parse_reference(s::AbstractString; id::AbstractString="")
    i = findfirst(p -> p.first == strip(String(s)), CASE_REFERENCES)
    i === nothing && error("VALIDATION_GUIDELINE.md §2.13: Case $id bad Compared with: $s " *
                           "(want measurement, NASA's printed prediction or verification)")
    return CASE_REFERENCES[i].second
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
                _parse_chain_span(_field_value(fields, "Chain span"; id="Case: $id"); id)...,
                _parse_reference(_field_value(fields, "Compared with"; id="Case: $id"); id),
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
        # "Map / block: none / <block>" keeps a registered case off the map (Phase 78f); the block names its figure folder.
        info.map_id == "none" && continue
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

"""
    has_verdict(id; rec=recorded_case_errors()) -> Bool

A case carries a verdict (and is drawn on the coverage chart by default) only when its recorded verdict (the snapshot
`case_error_summary.csv`) is met or not met and no rule takes it off (author 2026-10-29: "all no verdicts should be
placed elsewhere"). Information cases, diagnostic re-runs, cases with no criterion, Pkg.test-only and unrun cases are
listed in `docs/NO_VERDICT_CASES.md` and in the Validation tab. Phase 147a (2026-11-10): renamed from
`on_validation_map` when the block map was retired; the old name is kept as an alias.
"""
function has_verdict(id::AbstractString; rec::AbstractDict=recorded_case_errors())
    no_verdict_by_rule(id) && return false
    r = get(rec, String(id), nothing)
    return r !== nothing && r.verdict in ("met", "not_met")
end

"""Old name of [`has_verdict`](@ref) (the block validation map was retired in Phase 147, 2026-11-10)."""
const on_validation_map = has_verdict

"""Soft lookup for GUI: missing CASE_INFO → placeholder fields, no crash."""
function _case_info_or_missing(id::AbstractString)
    if haskey(CASE_INFO, id)
        return CASE_INFO[id]
    end
    return CaseInfo(
        String(id), _MISSING_DOC, :deferred, :deferred,
        _MISSING_DOC, _MISSING_DOC, _MISSING_DOC, _MISSING_DOC,
        _MISSING_DOC, _MISSING_DOC, _MISSING_DOC, "", "", 0, 0, :verification,
    )
end

"""JSON of CaseInfo + criterion (if registered) + source image path + error summary when present."""
function case_info_json(id::AbstractString;
                        session_errors::Dict{String,NamedTuple}=Dict{String,NamedTuple}(),
                        recorded_errors::Union{Nothing,Dict{String,NamedTuple}}=nothing)
    info = _case_info_or_missing(id)
    recorded = recorded_errors === nothing ? recorded_case_errors() : recorded_errors
    err = _case_error_json_fields(id; session=session_errors, recorded=recorded)
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
        "chain_span" => info.span_from == 0 ? "" : CHAIN_STAGES[info.span_from] * " → " * CHAIN_STAGES[info.span_to],
        "compared_with" => info.span_from == 0 ? "" : reference_label(info.reference),
        "criterion_text" => "",
        "criterion_date" => "",
        "source_image" => "",
        "in_registry" => haskey(VALIDATION_CASES, id),
        "detail_kind" => "case",
        "error" => err.error,
        "error_chip" => err.error_chip,
        "error_source" => err.error_source,
        "error_snapshot" => err.error_snapshot,
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

"""Registry ids in §2.13 block order (excludes UT_* / non-registry nodes), then the registry ids placed on no block
(`Map / block: none`) in registry order, so the Validation tab lists every registered case. The blocks are no longer
drawn (Phase 147, 2026-11-10); they keep the case order and the figure folders."""
function validation_map_case_order()
    out = String[]
    for m in VALIDATION_MAPS
        for b in m.blocks
            for id in b.cases
                haskey(VALIDATION_CASES, id) && push!(out, id)
            end
        end
    end
    seen = Set(out)
    append!(out, [id for id in VALIDATION_CASE_ORDER if !(id in seen)])
    return out
end

# Module-load fill from the guideline (raises if §2.13 is incomplete).
load_validation_docs!()
