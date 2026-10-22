# Validation maps (two flowcharts) + per-case metadata for the GUI "Validation map" tab.
# Texts and map structure come from docs/VALIDATION_GUIDELINE.md §2.13 (single source of truth).

struct CaseInfo
    id::String
    title::String
    category::Symbol      # :verification | :experiment | :calibrated | :input_qa | :extrap | :deferred
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
    for line in eachline(IOBuffer(String(body)))
        m = match(r"^\*\*([^*]+):\*\*\s*(.*)$", line)
        m === nothing && continue
        fields[String(m.captures[1])] = String(m.captures[2])
    end
    return fields
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
        push!(cur_blocks, MapBlock(bid, title, code, note, what, String[]))
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
            cat in (:verification, :experiment, :calibrated, :input_qa, :extrap, :deferred) ||
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
        ))
    end
    return JSON3.write(Dict(
        "id" => m.id,
        "title" => m.title,
        "intro" => m.intro,
        "what_is" => m.what_is,
        "how_to_read" => m.how_to_read,
        "blocks" => blocks,
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

# Module-load fill from the guideline (raises if §2.13 is incomplete).
load_validation_docs!()
