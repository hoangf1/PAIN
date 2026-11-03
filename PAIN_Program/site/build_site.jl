#!/usr/bin/env julia
# Phase 115: build the methodology website — a read-through, not a copy of the documents.
#
# One page that walks the pipeline stage by stage. Each stage opens with its own flowchart, says what that stage
# does and what it claims (text taken from `docs/METHODOLOGY.md`, not rewritten here), and then shows the
# validation cases that carry a verdict, with their recorded figures. Information cases, unit tests, diagnostics
# and displays are left out: they verify the code, they do not prove the method. The plan, the completed phases,
# the full case register and the README are not on the page — they are linked at the end.
#
# Read-only on the repository: it renders what the documents and the recorded snapshot already say. It runs no
# validation case and writes only under the output directory.
#
#   julia --project=rea-work/PAIN.jl rea-work/site/build_site.jl              # build and open in the browser
#   julia --project=rea-work/PAIN.jl rea-work/site/build_site.jl --no-open    # build only
#   julia --project=rea-work/PAIN.jl rea-work/site/build_site.jl --out DIR    # build somewhere else
ENV["QT_QPA_PLATFORM"] = get(ENV, "QT_QPA_PLATFORM", "offscreen")

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "PAIN.jl"); io=devnull)
using PAIN, Markdown, Dates

const SITE_DIR = @__DIR__
const REA = normpath(joinpath(SITE_DIR, ".."))
const DOCS = joinpath(REA, "docs")
const VENDOR = joinpath(SITE_DIR, "vendor")
const METHOD_MD = joinpath(DOCS, "METHODOLOGY.md")
const FLOW_MD = joinpath(DOCS, "flowchart.md")

# ---- arguments ------------------------------------------------------------------------------------------------
function parse_args(args)
    out = joinpath(SITE_DIR, "out")
    open_browser = true
    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--no-open"
            open_browser = false
        elseif a == "--out"
            i += 1
            i <= length(args) || error("--out needs a directory")
            out = abspath(args[i])
        elseif startswith(a, "--out=")
            out = abspath(split(a, "=", limit=2)[2])
        else
            error("unknown argument: $a (use --no-open, --out DIR)")
        end
        i += 1
    end
    return (out=out, open_browser=open_browser)
end

# ---- markdown helpers -----------------------------------------------------------------------------------------
esc(s) = replace(String(s), "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "\"" => "&quot;")

"""Strip inline markdown so a heading can be slugged and shown in the nav."""
function plain_heading(s::AbstractString)
    t = String(s)
    t = replace(t, r"\[([^\]]*)\]\([^)]*\)" => s"\1")
    t = replace(t, "`" => "")
    t = replace(t, r"\*\*|\*" => "")   # not `_`: headings name identifiers such as BLK_P68
    return strip(t)
end

function slugify(s::AbstractString)
    t = lowercase(plain_heading(s))
    t = replace(t, r"[^\p{L}\p{N}\s\-_]" => "")
    t = replace(t, r"\s+" => "-")
    return strip(t, '-')
end

"""
Underscores inside a word (`A_GEO`, `z_k`) are emphasis to Julia's Markdown parser but plain text on GitHub, where
these documents are written. Park them on a private-use character while parsing and restore them afterwards.
"""
const US = ''
protect_underscores(md::AbstractString) = replace(String(md), r"(?<=\w)_(?=\w)" => US)
restore_underscores(h::AbstractString) = replace(String(h), US => '_')

"""
Julia's Markdown turns `\$`, `{`, `}`, `(` and `)` into HTML entities, which would destroy any LaTeX passing
through it. Lift `\$\$...\$\$` and `\$...\$` out of the source before parsing, then put them back into the
finished HTML as MathJax's own delimiters. A `\$` that never closes on the same line is left alone, so prices and
stray dollars are safe.
"""
function extract_math(md::AbstractString)
    found = String[]
    text = String(md)
    text = replace(text, r"\$\$(.+?)\$\$"s => function (m)
        tex = String(match(r"\$\$(.+?)\$\$"s, m).captures[1])
        push!(found, "\\[" * tex * "\\]")
        return "@@MATH$(length(found) - 1)@@"
    end)
    text = replace(text, r"(?<!\\)\$([^\$\n]+?)(?<!\\)\$" => function (m)
        tex = String(match(r"(?<!\\)\$([^\$\n]+?)(?<!\\)\$", m).captures[1])
        push!(found, "\\(" * tex * "\\)")
        return "@@MATH$(length(found) - 1)@@"
    end)
    return text, found
end

function restore_math(html::AbstractString, found::Vector{String})
    out = String(html)
    for (i, tex) in enumerate(found)
        out = replace(out, "@@MATH$(i - 1)@@" => "<span class=\"math\">" * tex * "</span>")
    end
    return out
end

"""Markdown fragment -> HTML, with the underscore and LaTeX guards a fragment needs."""
function md2html(s::AbstractString)
    text, math = extract_math(String(s))
    html = restore_underscores(Markdown.html(Markdown.parse(protect_underscores(text))))
    return restore_math(html, math)
end

"""
A claim is one wall of text in the document. Break it at the bold run-ins the author already wrote
(`**Re-stated 2026-10-21 (post-hoc):**` and the like) and label the `Claim:` lead, so the page can show it as a
callout the reader can collapse. The words are untouched; only where the paragraph breaks changes.
"""
function shape_claims(html::AbstractString)
    return replace(html, r"<p><strong>(Claim[^<]*)</strong>(.*?)</p>"s => function (m)
        mm = match(r"<p><strong>(Claim[^<]*)</strong>(.*?)</p>"s, m)
        lead = String(mm.captures[1])
        body = replace(String(mm.captures[2]), "<strong>" => "</p><p><strong>")
        return "<div class=\"claim\"><p class=\"claim-lead\">$(lead)</p>" *
               "<div class=\"claim-body\"><p>$(body)</p></div></div>"
    end)
end

"""Split a document into sections keyed by their plain heading text, each body ending at the next heading."""
function doc_sections(md::AbstractString)
    out = Dict{String,String}()
    cur = ""
    buf = String[]
    in_fence = false
    for line in split(md, '\n')
        occursin(r"^\s*```", line) && (in_fence = !in_fence)
        m = in_fence ? nothing : match(r"^(#{1,6})\s+(.+?)\s*#*\s*$", line)
        if m === nothing
            push!(buf, String(line))
        else
            isempty(cur) || (out[cur] = join(buf, "\n"))
            cur = plain_heading(m.captures[2])
            empty!(buf)
        end
    end
    isempty(cur) || (out[cur] = join(buf, "\n"))
    return out
end

"""
The parts of a section body that begin `**Marker...**`, keeping only the markers asked for and the document's own
order. Everything else in the section (implementation notes, the long miss analyses) stays in METHODOLOGY.md.
"""
function extract_parts(body::AbstractString, markers)
    chunks = String[]
    cur = String[]
    keep = false
    in_fence = false
    for line in split(body, '\n')
        occursin(r"^\s*```", line) && (in_fence = !in_fence)
        m = in_fence ? nothing : match(r"^\*\*([^*]+)\*\*", line)
        if m !== nothing
            keep && !isempty(cur) && push!(chunks, join(cur, "\n"))
            cur = String[]
            head = lowercase(strip(String(m.captures[1])))
            keep = any(k -> startswith(head, lowercase(k)), markers)
        end
        keep && push!(cur, String(line))
    end
    keep && !isempty(cur) && push!(chunks, join(cur, "\n"))
    return join(chunks, "\n\n")
end

"""The nth fenced mermaid block of a document (1-based)."""
function mermaid_block(md::AbstractString, n::Integer)
    found = 0
    lines = split(md, '\n')
    i = 1
    while i <= length(lines)
        if occursin(r"^\s*```+\s*mermaid\s*$", lines[i])
            found += 1
            j = i + 1
            buf = String[]
            while j <= length(lines) && !occursin(r"^\s*```+\s*$", lines[j])
                push!(buf, String(lines[j]))
                j += 1
            end
            found == n && return join(buf, "\n")
            i = j + 1
        else
            i += 1
        end
    end
    return ""
end

# ---- assets ---------------------------------------------------------------------------------------------------
function asset!(state, src::AbstractString)
    key = abspath(src)
    haskey(state.assets, key) && return state.assets[key]
    isfile(key) || return ""
    name = replace(relpath(key, REA), r"[\\/]" => "_")
    dest = joinpath(state.outdir, "assets", "img", name)
    mkpath(dirname(dest))
    cp(key, dest; force=true)
    rel = "assets/img/" * name
    state.assets[key] = rel
    return rel
end

"""Links and images inside prose lifted from a document: resolve what we can, keep the rest reachable on disk."""
function fix_refs(state, html::AbstractString)
    html = replace(html, r"<img src=\"([^\"]*)\"" => function (m)
        src = match(r"<img src=\"([^\"]*)\"", m).captures[1]
        (startswith(src, "http://") || startswith(src, "https://")) && return m
        rel = asset!(state, normpath(joinpath(DOCS, String(src))))
        return isempty(rel) ? m : "<img loading=\"lazy\" src=\"$(esc(rel))\""
    end)
    return replace(html, r"href=\"([^\"]*)\"" => function (m)
        href = match(r"href=\"([^\"]*)\"", m).captures[1]
        if startswith(href, "http://") || startswith(href, "https://") || startswith(href, "mailto:")
            return "href=\"$(esc(href))\" target=\"_blank\" rel=\"noopener\""
        elseif startswith(href, "#")
            return "href=\"$(esc(href))\" data-internal=\"1\""   # resolved or unwrapped at the end
        end
        file = first(split(href, '#'))
        abs = normpath(joinpath(DOCS, String(file)))
        if isfile(abs)
            rel = replace(relpath(abs, state.outdir), "\\" => "/")
            return "href=\"$(esc(rel))\" class=\"filelink\" target=\"_blank\""
        end
        return "href=\"$(esc(href))\" class=\"deadlink\" title=\"not reachable from the site folder\""
    end)
end

"""Internal links whose target is not on this page become plain text; the rest keep working."""
function resolve_internal(html::AbstractString, ids::Set{String})
    return replace(html, r"<a href=\"#([^\"]*)\" data-internal=\"1\">(.*?)</a>"s => function (m)
        mm = match(r"<a href=\"#([^\"]*)\" data-internal=\"1\">(.*?)</a>"s, m)
        target, text = mm.captures[1], mm.captures[2]
        return target in ids ? "<a href=\"#$(target)\">$(text)</a>" : text
    end)
end

# ---- the stage diagrams, generated from the validation map ------------------------------------------------------
_mlabel(s) = replace(String(s), "\"" => "'")

"""
One mermaid flowchart for a stage, built from `VALIDATION_GUIDELINE.md` §2.13 — the same fields the GUI map reads,
so the picture cannot drift from the map. Chain blocks in Feeds order, check blocks dashed off the block they
branch from, each labelled with how many of its cases are met.
"""
function stage_diagram(blocks, rec, group_ids::Set{String}, title_of::Dict{String,String})
    isempty(blocks) && return ""
    io = IOBuffer()
    write(io, "flowchart LR\n")
    own = Set(b.id for b in blocks)
    for b in blocks
        label = _mlabel(b.title)
        if b.role == "check"
            on = [c for c in b.cases if PAIN.on_validation_map(c; rec)]
            met = count(c -> rec[c].verdict == "met", on)
            label *= "<br/><small>$(met) met · $(length(on) - met) not met</small>"
        end
        shape = b.role == "input" ? ("([\"", "\"])") :
                b.role == "output" ? ("[\"", "\"]") : ("[\"", "\"]")
        write(io, "  ", b.id, shape[1], label, shape[2], "\n")
    end
    external = String[]
    for b in blocks, f in b.feeds
        if f in own
            target = only(x for x in blocks if x.id == f)
            write(io, "  ", b.id, target.role == "check" ? " -.-> " : " --> ", f, "\n")
        elseif haskey(title_of, f) && !(f in external)
            push!(external, f)
            write(io, "  ", f, "[\"", _mlabel(title_of[f]), "\"]:::ext\n")
            write(io, "  ", b.id, " --> ", f, "\n")
        end
    end
    write(io, "  classDef ext fill:#f2f4f7,stroke:#aab3bf,color:#5b6b7c,stroke-dasharray:3 3\n")
    for b in blocks
        cls = b.role == "input" ? "inp" : b.role == "output" ? "outp" : b.role == "check" ? "chk" : "fn"
        write(io, "  class ", b.id, " ", cls, "\n")
    end
    write(io, "  classDef inp fill:#eef4fd,stroke:#5b8fd6\n")
    write(io, "  classDef fn fill:#ffffff,stroke:#44506080\n")
    write(io, "  classDef outp fill:#eef7f0,stroke:#4a8f5b\n")
    write(io, "  classDef chk fill:#fdf6ea,stroke:#c08a3e\n")
    return String(take!(io))
end

diagram_html(src, caption) = isempty(src) ? "" :
    "<figure class=\"diagram\"><pre class=\"mermaid\">$(esc(src))</pre>" *
    "<figcaption>$(esc(caption))</figcaption></figure>"

# ---- the page's sections --------------------------------------------------------------------------------------
"""
A stage of the read-through: the map groups it covers, the METHODOLOGY sections its prose comes from, and which
bold parts of those sections to show. Everything else in those sections stays in the document.
"""
struct Stage
    id::String
    title::String
    lead::String
    groups::Vector{String}            # map group ids
    prose::Vector{Pair{String,Vector{String}}}   # METHODOLOGY heading => bold markers to keep
end

const PARTS = ["Validation chunk", "What it does", "Key equation", "Chain", "Claim"]

const STAGES = Stage[
    Stage("source", "Stage 1 — The free-field source",
          "Where the sound starts: blade loads to the pressure at 160 points on the fuselage skin.",
          ["G_AIR", "G_FF"],
          ["2.3 Airfoil BEMT+F1A" => PARTS,
           "2.2 NASA measured data (validation test only)" => PARTS]),
    Stage("blocking", "Stage 2 — Blocking, Eq. (43)",
          "The fuselage reflects the incoming sound, so the skin pressure is above the free field.",
          ["G_GRID"],
          ["3. Stage 2: blocking (Eq. 43)" => PARTS]),
    Stage("cyl2d", "Stage 3 — Cabin acoustic modes (CYL2D)",
          "The cross-section eigenproblem that gives the cabin its acoustic modes.",
          ["G_CYL"],
          ["4. Stage 3: cabin acoustic modes (CYL2D)" => PARTS]),
    Stage("mrp", "Stage 4 — Structural modes (MRP)",
          "The shell-and-floor modes the exterior pressure drives.",
          ["G_MRP"],
          ["5. Stage 4: structural modes (MRP)" => PARTS]),
    Stage("trim", "Stage 5 — Trim and loss",
          "What the sidewall treatment transmits and what the structure and cabin absorb.",
          ["G_TRIM"],
          ["6.1 Trim and loss" => PARTS]),
    Stage("painmain", "Stage 6 — PAIN main",
          "Coupling the two mode sets and summing the tones: Eq. (8).",
          ["G_PAIN"],
          ["6.2 PAIN main (coupling, Eq. 8, broadband)" => PARTS]),
    Stage("endtoend", "Stage 7 — Interior SPL, end to end",
          "The whole chain run against what NASA printed and what was measured. This is where PAIN's functionality stands or falls.",
          ["G_VAL"],
          ["6.3 End-to-end comparisons" => PARTS]),
    Stage("metrics", "Stage 8 — Metrics",
          "A-weighting and SIL on the interior spectrum.",
          String[],
          ["7. Stage 6: metrics" => PARTS]),
]

"""Verdict-bearing cases of a stage, in map order, with the block they hang from."""
function stage_cases(blocks, rec)
    out = Tuple{String,String}[]
    for b in blocks, cid in b.cases
        PAIN.on_validation_map(cid; rec) || continue
        push!(out, (cid, b.title))
    end
    return out
end

function case_card(state, cid, block_title, rec)
    c = PAIN.VALIDATION_CASES[cid]
    v = String(rec[cid].verdict)
    fig = asset!(state, PAIN.validation_figure_path(cid))
    return """
    <article class="card" id="case-$(esc(cid))">
      <div class="card-head">
        <code class="case-id">$(esc(cid))</code>
        <span class="chip chip-$(esc(v))">$(esc(replace(v, "_" => " ")))</span>
        <span class="grade">$(esc(block_title))</span>
      </div>
      <h4 class="case-title">$(esc(c.title))</h4>
      <dl class="case-fields">
        <dt>Criterion</dt><dd>$(esc(c.criterion_text))<span class="dim"> — fixed $(esc(c.criterion_date))</span></dd>
        <dt>Recorded</dt><dd>$(esc(rec[cid].text))<span class="dim"> · run $(esc(String(rec[cid].run_date)))</span></dd>
      </dl>
      $(isempty(fig) ? "" : "<figure class=\"case-fig\"><img loading=\"lazy\" src=\"$(esc(fig))\" alt=\"figure recorded for $(esc(cid))\"></figure>")
    </article>
    """
end

function render_stage(state, st::Stage, mblocks, rec, title_of, method)
    blocks = [b for b in mblocks if b.group in st.groups]
    cases = stage_cases(blocks, rec)
    met = count(c -> rec[c[1]].verdict == "met", cases)

    prose = IOBuffer()
    for (heading, markers) in st.prose
        body = get(method, heading, "")
        isempty(body) && (@warn "METHODOLOGY section not found" heading; continue)
        part = extract_parts(body, markers)
        isempty(strip(part)) && continue
        write(prose, shape_claims(fix_refs(state, md2html(part))))
    end

    diag = diagram_html(stage_diagram(blocks, rec, Set(st.groups), title_of),
                        "generated from VALIDATION_GUIDELINE.md §2.13 — the fields the GUI map reads")

    cards = isempty(cases) ? """
      <p class="note">No case here carries a verdict. The checks on these blocks compare with another method, an
      identity or a property of a printed table, so under the rule above they are verification, not validation.
      The evidence for this stage sits on the check blocks of the stages it feeds.</p>
      """ : "<div class=\"cards\">" * join([case_card(state, cid, bt, rec) for (cid, bt) in cases], "\n") * "</div>"

    body = """
    <section class="stage" id="$(st.id)">
      <header class="stage-head">
        <h2 class="stage-title">$(esc(st.title))</h2>
        <p class="stage-lead">$(esc(st.lead))</p>
        $(isempty(cases) ? "" : """<p class="scoreline"><b>$(length(cases))</b> case$(length(cases) == 1 ? "" : "s") with a verdict ·
           <span class="ok">$(met) met</span> · <span class="miss">$(length(cases) - met) not met</span></p>""")
      </header>
      $(diag)
      <div class="prose">$(String(take!(prose)))</div>
      $(cards)
    </section>
    """
    return (body=body, n=length(cases), met=met)
end

# ---- page furniture ---------------------------------------------------------------------------------------------
const CSS = raw"""
:root{
  --bg:#ffffff; --fg:#1b2430; --dim:#5e6c7c; --line:#e1e7ed; --soft:#f6f9fb; --soft2:#edf2f7;
  --accent:#1f6feb; --met:#1a7f52; --miss:#b4301f; --code:#f2f5f8; --sidebar:270px;
}
:root[data-theme="dark"]{
  --bg:#11161c; --fg:#e6edf3; --dim:#9fb0c0; --line:#263039; --soft:#171d24; --soft2:#1d252e;
  --accent:#6ea8ff; --met:#49c08a; --miss:#f08a7a; --code:#1a212a;
}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;background:var(--bg);color:var(--fg);
  font:16px/1.7 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif}
a{color:var(--accent);text-decoration:none} a:hover{text-decoration:underline}
code{background:var(--code);padding:.1em .35em;border-radius:4px;font-size:.88em;
  font-family:"Cascadia Mono",Consolas,monospace}
pre{background:var(--code);padding:.8rem 1rem;border-radius:8px;overflow:auto;font-size:.85em}

#shell{display:flex;min-height:100vh}
#sidebar{width:var(--sidebar);flex:0 0 var(--sidebar);border-right:1px solid var(--line);background:var(--soft);
  position:sticky;top:0;height:100vh;overflow-y:auto;padding:1.2rem 1rem 3rem}
#content{flex:1;min-width:0;padding:2.5rem clamp(1rem,4vw,3rem) 6rem;max-width:960px}
.brand{font-weight:700;font-size:1.05rem;margin:0 0 .15rem}
.brand small{display:block;font-weight:400;font-size:.76rem;color:var(--dim)}
#navlist{list-style:none;margin:1rem 0 0;padding:0;font-size:.9rem}
#navlist a{display:block;padding:.3rem .55rem;border-radius:6px;color:var(--fg)}
#navlist a:hover{background:var(--soft2);text-decoration:none}
#navlist a.active{background:var(--accent);color:#fff}
#themebtn{margin-top:1rem;width:100%;padding:.4rem;font-size:.8rem;border:1px solid var(--line);
  border-radius:6px;background:var(--bg);color:var(--dim);cursor:pointer}

h1.page-title{font-size:2.1rem;letter-spacing:-.02em;margin:0 0 .3rem}
.page-sub{color:var(--dim);margin:0 0 2rem;font-size:1.02rem}
.stage{border-top:1px solid var(--line);padding-top:2.2rem;margin-top:3rem;scroll-margin-top:1rem}
.stage-title{font-size:1.5rem;letter-spacing:-.01em;margin:0 0 .25rem}
.stage-lead{color:var(--dim);margin:.1rem 0 .5rem;max-width:62ch}
.scoreline{font-size:.86rem;color:var(--dim);margin:.3rem 0 0}
.scoreline .ok{color:var(--met);font-weight:600} .scoreline .miss{color:var(--miss);font-weight:600}
.prose{max-width:74ch}
.prose p{margin:.75rem 0}
.prose ul{margin:.6rem 0;padding-left:1.3rem}
.prose h1,.prose h2,.prose h3{font-size:1.05rem;margin:1.4rem 0 .4rem}
.intro{max-width:74ch}
.note{background:var(--soft);border-left:3px solid var(--accent);padding:.75rem 1rem;border-radius:0 8px 8px 0;
  font-size:.93rem;max-width:74ch}
table{border-collapse:collapse;margin:1rem 0;font-size:.88rem;display:block;overflow-x:auto;max-width:100%}
th,td{border:1px solid var(--line);padding:.4rem .6rem;text-align:left;vertical-align:top}
th{background:var(--soft2);font-weight:650}
tr:nth-child(even) td{background:var(--soft)}
a.deadlink{color:var(--dim);text-decoration:underline dotted;cursor:help}
a.filelink::after{content:"\2197";font-size:.7em;vertical-align:super;opacity:.6}

.diagram{margin:1.4rem 0;padding:1rem;border:1px solid var(--line);border-radius:10px;background:var(--soft);
  overflow-x:auto}
.diagram figcaption{color:var(--dim);font-size:.74rem;margin-top:.5rem}
.diagram pre.mermaid{background:none;padding:0;text-align:center}

.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(340px,1fr));gap:1rem;margin:1.5rem 0 0}
.card{border:1px solid var(--line);border-radius:12px;padding:.85rem 1rem;background:var(--soft);
  scroll-margin-top:1rem}
.card-head{display:flex;align-items:center;gap:.5rem;flex-wrap:wrap}
.case-id{background:var(--bg);border:1px solid var(--line);font-size:.8rem}
.grade{color:var(--dim);font-size:.73rem;margin-left:auto}
.case-title{font-size:.95rem;margin:.45rem 0 .5rem;line-height:1.45;font-weight:600}
.chip{font-size:.7rem;font-weight:650;padding:.1rem .5rem;border-radius:999px;border:1px solid currentColor}
.chip-met{color:var(--met)} .chip-not_met{color:var(--miss)}
.case-fields{margin:0;font-size:.82rem;display:grid;grid-template-columns:auto 1fr;gap:.2rem .7rem}
.case-fields dt{color:var(--dim);white-space:nowrap}
.case-fields dd{margin:0}
.case-fig{margin:.75rem 0 0}
.case-fig img{width:100%;border:1px solid var(--line);border-radius:8px;background:#fff;cursor:zoom-in}
.case-fig img:hover{border-color:var(--accent)}

/* claims: a callout, broken at the author's own run-ins, collapsed when long */
.claim{border:1px solid var(--line);border-left:3px solid var(--accent);border-radius:0 10px 10px 0;
  background:var(--soft);padding:.8rem 1rem;margin:1.2rem 0}
.claim-lead{margin:0 0 .4rem;font-weight:700;font-size:.95rem;letter-spacing:.01em}
.claim-body{position:relative}
.claim-body p{margin:.55rem 0}
.claim-body p:first-child{margin-top:0}
.claim-body.collapsed{max-height:10.5em;overflow:hidden}
.claim-body.collapsed::after{content:"";position:absolute;left:0;right:0;bottom:0;height:3.2em;
  background:linear-gradient(to bottom,transparent,var(--soft))}
.claim-more{margin-top:.5rem;font-size:.82rem;background:none;border:0;padding:0;color:var(--accent);
  cursor:pointer;font-family:inherit}
.claim-more:hover{text-decoration:underline}

/* equations */
.math{overflow-x:auto;max-width:100%}
mjx-container[display="true"]{margin:.8rem 0 !important;overflow-x:auto;overflow-y:hidden}

/* lightbox */
.diagram svg{cursor:zoom-in}
#lightbox{position:fixed;inset:0;z-index:999;background:rgba(10,14,20,.92);display:flex;align-items:center;
  justify-content:center;padding:2.5rem;cursor:zoom-out}
#lightbox[hidden]{display:none}
#lb-stage{max-width:96vw;max-height:88vh;display:flex;align-items:center;justify-content:center}
#lb-stage img{max-width:96vw;max-height:88vh;object-fit:contain;background:#fff;border-radius:6px}
#lb-stage svg{max-width:96vw;max-height:88vh;height:auto;background:#fff;border-radius:6px;padding:1rem}
#lb-cap{position:absolute;bottom:1rem;left:0;right:0;text-align:center;color:#dfe6ee;font-size:.82rem;
  padding:0 2rem}
#lb-close{position:absolute;top:1rem;right:1.2rem;background:none;border:0;color:#dfe6ee;font-size:2rem;
  line-height:1;cursor:pointer;padding:.2rem .5rem}
#lb-close:hover{color:#fff}
.dim{color:var(--dim)}
.sources{font-size:.9rem}

@media (max-width:900px){
  #shell{display:block}
  #sidebar{position:static;width:auto;height:auto;border-right:0;border-bottom:1px solid var(--line)}
  #content{padding:1.2rem 1rem 4rem}
}
@media print{#sidebar{display:none}}
"""

const JS = raw"""
(function(){
  var root=document.documentElement, saved=null;
  try{saved=localStorage.getItem("pain-site-theme")}catch(e){}
  if(saved){root.setAttribute("data-theme",saved);}
  else if(window.matchMedia&&window.matchMedia("(prefers-color-scheme: dark)").matches){
    root.setAttribute("data-theme","dark");
  } else {root.setAttribute("data-theme","light");}
  document.getElementById("themebtn").onclick=function(){
    var next=root.getAttribute("data-theme")==="dark"?"light":"dark";
    root.setAttribute("data-theme",next);
    try{localStorage.setItem("pain-site-theme",next)}catch(e){}
    if(window.mermaid){location.reload();}
  };

  var links={},targets=[];
  [].slice.call(document.querySelectorAll("#navlist a")).forEach(function(a){
    var id=a.getAttribute("href").slice(1); links[id]=a;
    var el=document.getElementById(id); if(el) targets.push(el);
  });
  var current=null;
  var obs=new IntersectionObserver(function(es){
    es.forEach(function(en){
      if(!en.isIntersecting) return;
      var a=links[en.target.id]; if(!a||a===current) return;
      if(current) current.classList.remove("active");
      a.classList.add("active"); current=a;
    });
  },{rootMargin:"0px 0px -75% 0px",threshold:0});
  targets.forEach(function(t){obs.observe(t);});

  // Figures load lazily and diagrams render asynchronously, so the page grows after the browser has jumped to
  // #hash. Land on the target again once both have settled.
  function reanchor(){
    if(!location.hash) return;
    var el=document.getElementById(decodeURIComponent(location.hash.slice(1)));
    if(el) el.scrollIntoView({behavior:"auto",block:"start"});
  }
  window.addEventListener("load",function(){setTimeout(reanchor,0);});
  window.addEventListener("hashchange",function(){setTimeout(reanchor,0);});

  // Long claims collapse; the button only appears when there is something hidden.
  [].slice.call(document.querySelectorAll(".claim-body")).forEach(function(b){
    if(b.scrollHeight<=b.clientHeight+8 && b.scrollHeight<190) return;
    b.classList.add("collapsed");
    var btn=document.createElement("button");
    btn.className="claim-more"; btn.type="button"; btn.textContent="Show the whole claim";
    btn.onclick=function(){
      var open=b.classList.toggle("collapsed");
      btn.textContent=open?"Show the whole claim":"Show less";
    };
    b.parentNode.appendChild(btn);
  });

  // Click a figure or a diagram to fill the window with it.
  var lb=document.getElementById("lightbox"),
      stage=document.getElementById("lb-stage"),
      cap=document.getElementById("lb-cap");
  function openLb(node,caption){
    stage.innerHTML=""; stage.appendChild(node);
    cap.textContent=caption||"";
    lb.hidden=false; document.body.style.overflow="hidden";
  }
  function closeLb(){lb.hidden=true; stage.innerHTML=""; document.body.style.overflow="";}
  lb.addEventListener("click",closeLb);
  document.getElementById("lb-close").addEventListener("click",closeLb);
  document.addEventListener("keydown",function(e){if(e.key==="Escape"&&!lb.hidden) closeLb();});
  document.addEventListener("click",function(e){
    var img=e.target.closest&&e.target.closest(".case-fig img, .prose img");
    if(img){
      var c=img.closest("figure"), t=c&&c.querySelector("figcaption");
      var big=new Image(); big.src=img.currentSrc||img.src; big.alt=img.alt||"";
      openLb(big, t?t.textContent:img.alt);
      return;
    }
    var fig=e.target.closest&&e.target.closest(".diagram");
    if(fig&&fig.querySelector("svg")){
      var clone=fig.querySelector("svg").cloneNode(true);
      clone.removeAttribute("style"); clone.setAttribute("width","100%");
      var fc=fig.querySelector("figcaption");
      openLb(clone, fc?fc.textContent:"");
    }
  });

  if(window.mermaid){
    var dark=root.getAttribute("data-theme")==="dark";
    window.mermaid.initialize({startOnLoad:false,theme:dark?"dark":"default",securityLevel:"loose",
                               flowchart:{useMaxWidth:true}});
    window.mermaid.run({querySelector:"pre.mermaid"}).then(reanchor).catch(function(e){console.error(e);});
  } else {
    [].slice.call(document.querySelectorAll("pre.mermaid")).forEach(function(p){
      p.insertAdjacentHTML("beforebegin",
        '<p class="dim">Diagram not rendered: assets/mermaid.min.js is missing. Its source follows.</p>');
    });
  }
})();
"""

# ---- build ------------------------------------------------------------------------------------------------------
function build(opts)
    outdir = opts.out
    mkpath(joinpath(outdir, "assets", "img"))
    state = (outdir=outdir, assets=Dict{String,String}())

    PAIN.reload_validation_docs!()
    rec = PAIN.recorded_case_errors()
    total = only(m for m in PAIN.VALIDATION_MAPS if m.id == "total")
    title_of = Dict(b.id => b.title for b in total.blocks)
    method = doc_sections(read(METHOD_MD, String))
    flow = read(FLOW_MD, String)

    snapshot = ""
    p = PAIN.case_error_summary_path()
    if isfile(p)
        mm = match(r"generated (\d{4}-\d{2}-\d{2})", first(readlines(p)))
        mm === nothing || (snapshot = String(mm.captures[1]))
    end

    # --- opening: what this is, the grades, the rule, the whole pipeline
    # The grades table and the verdict rule both sit under "Grades used for every claim"; everything after the
    # table there is a running phase log, which belongs in the document and not on a read-through.
    grades_body = get(method, "Grades used for every claim", "")
    table_lines = String[]
    rule = ""
    for line in split(grades_body, '\n')
        if startswith(line, "**")
            if isempty(rule) && startswith(line, "**Which checks carry a verdict")
                cut = findfirst("information cases or unit tests.", line)
                rule = cut === nothing ? String(line) : String(line[1:cut[end]])
            end
        elseif isempty(rule)
            push!(table_lines, String(line))
        end
    end
    grades = fix_refs(state, md2html(join(table_lines, "\n")))
    isempty(rule) && @warn "verdict rule not found in METHODOLOGY.md"
    glance = fix_refs(state, md2html(get(method, "1. The pipeline at a glance", "")))

    all_cases = [c for b in total.blocks for c in b.cases if PAIN.on_validation_map(c; rec)]
    n_met = count(c -> rec[c].verdict == "met", all_cases)

    io = IOBuffer()
    write(io, """
    <h1 class="page-title">PAIN, recreated — the method and what proves it</h1>
    <p class="page-sub">A read-through of the pipeline: what each stage does, and the validation cases that carry a
    verdict on it. $(length(all_cases)) cases, $(n_met) met and $(length(all_cases) - n_met) not met$(isempty(snapshot) ? "" : ", from the snapshot of $(snapshot)").</p>

    <section class="stage" id="start" style="border-top:0;margin-top:0;padding-top:0">
      <div class="intro">
      <div class="note"><b>What counts as proof here.</b>
      $(md2html(rule))
      <p>Only those cases are on this page. The identities, hand checks, independent re-implementations,
      diagnostics and displays — about two thirds of the register — verify that the code does what it says; they
      cannot show that the method matches reality, so they are left to the full case register.</p></div>
      $(grades)
      </div>
    </section>

    <section class="stage" id="pipeline">
      <header class="stage-head">
        <h2 class="stage-title">The pipeline at a glance</h2>
        <p class="stage-lead">Propeller noise at the skin → blocking → cabin and structural modes → interior SPL.</p>
      </header>
      $(diagram_html(mermaid_block(flow, 1), "the whole program (flowchart.md §1)"))
      <div class="prose">$(glance)</div>
    </section>
    """)

    navs = [("start", "What counts as proof"), ("pipeline", "The pipeline at a glance")]
    for st in STAGES
        r = render_stage(state, st, total.blocks, rec, title_of, method)
        write(io, r.body)
        push!(navs, (st.id, st.title))
        println("  ", rpad(st.id, 10), r.n, " verdict cases (", r.met, " met)")
    end

    closing = fix_refs(state, md2html(get(method, "10. What this recreation does not claim", "")))
    conditions = fix_refs(state, md2html(get(method, "11. Conditions that apply to every claim", "")))
    write(io, """
    <section class="stage" id="limits">
      <header class="stage-head">
        <h2 class="stage-title">What this does not claim</h2>
        <p class="stage-lead">The limits that travel with every number above.</p>
      </header>
      <div class="prose">$(closing)$(conditions)</div>
    </section>

    <section class="stage" id="more">
      <header class="stage-head">
        <h2 class="stage-title">The full detail</h2>
        <p class="stage-lead">This page is the read-through. Everything behind it stays in the repository.</p>
      </header>
      <div class="prose sources">
        <table>
          <tr><th>For</th><th>Read</th></tr>
          <tr><td>Every case record, its criterion and why each miss misses</td><td><code>docs/VALIDATION_GUIDELINE.md</code> §2.13, §2.14</td></tr>
          <tr><td>The cases with no verdict, and why each carries none</td><td><code>docs/NO_VERDICT_CASES.md</code></td></tr>
          <tr><td>The full methodology, with implementation notes</td><td><code>docs/METHODOLOGY.md</code></td></tr>
          <tr><td>The program run stage by stage on the test article</td><td><code>docs/WALKTHROUGH.md</code></td></tr>
          <tr><td>All the diagrams</td><td><code>docs/flowchart.md</code></td></tr>
          <tr><td>How each check was planned, with its criteria dated before the run</td><td><code>docs/COMPLETED_PHASES.md</code></td></tr>
          <tr><td>Installing and running the program and the GUI</td><td><code>README.md</code></td></tr>
        </table>
        <p class="dim">Built $(Dates.format(now(), "yyyy-mm-dd HH:MM")) by <code>site/build_site.jl</code>. Nothing on this
        page was computed by the build: the verdicts and figures are the recorded snapshot, and the prose is lifted
        from the documents above.</p>
      </div>
    </section>
    """)

    html_body = String(take!(io))
    ids = Set{String}(m.captures[1] for m in eachmatch(r"id=\"([^\"]+)\"", html_body))
    html_body = resolve_internal(html_body, ids)

    nav = join(["<li><a href=\"#$(id)\">$(esc(t))</a></li>" for (id, t) in navs], "\n")

    mermaid_rel = ""
    vend = joinpath(VENDOR, "mermaid.min.js")
    if isfile(vend)
        cp(vend, joinpath(outdir, "assets", "mermaid.min.js"); force=true)
        mermaid_rel = "assets/mermaid.min.js"
    else
        @warn "vendor/mermaid.min.js missing; diagrams will show their source" path=vend
    end

    mathjax_rel = ""
    mj = joinpath(VENDOR, "mathjax-tex-svg.js")
    if isfile(mj)
        cp(mj, joinpath(outdir, "assets", "mathjax-tex-svg.js"); force=true)
        mathjax_rel = "assets/mathjax-tex-svg.js"
    else
        @warn "vendor/mathjax-tex-svg.js missing; equations will show their LaTeX" path=mj
    end

    html = """
    <!doctype html>
    <html lang="en" data-theme="light">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>PAIN recreation — method and validation</title>
    <style>$(CSS)</style>
    </head>
    <body>
    <div id="shell">
      <nav id="sidebar">
        <p class="brand">PAIN recreated<small>method &amp; validation</small></p>
        <ul id="navlist">
    $(nav)
        <li><a href="#limits">What this does not claim</a></li>
        <li><a href="#more">The full detail</a></li>
        </ul>
        <button id="themebtn" type="button">Light / dark</button>
      </nav>
      <main id="content">
    $(html_body)  </main>
    </div>
    <div id="lightbox" hidden>
      <button id="lb-close" type="button" aria-label="close">&times;</button>
      <div id="lb-stage"></div>
      <div id="lb-cap"></div>
    </div>
    $(isempty(mathjax_rel) ? "" : "<script>window.MathJax={options:{renderActions:{addMenu:[]}},svg:{fontCache:'global'}};</script><script id=\"MathJax-script\" src=\"$(mathjax_rel)\"></script>")
    $(isempty(mermaid_rel) ? "" : "<script src=\"$(mermaid_rel)\"></script>")
    <script>$(JS)</script>
    </body>
    </html>
    """

    index = joinpath(outdir, "index.html")
    write(index, html)
    println("wrote ", index, " (", round(filesize(index) / 1024; digits=1), " KB, ",
            length(state.assets), " figures, ", length(all_cases), " cases)")
    return index
end

function open_in_browser(path::AbstractString)
    try
        if Sys.iswindows()
            run(`cmd /c start "" $(replace(path, "/" => "\\"))`)
        elseif Sys.isapple()
            run(`open $path`)
        else
            run(`xdg-open $path`)
        end
    catch err
        @warn "could not open a browser; open the file by hand" path err
    end
    return nothing
end

function main(args)
    opts = parse_args(args)
    println("building the methodology read-through into ", opts.out)
    index = build(opts)
    opts.open_browser && open_in_browser(index)
    return index
end

main(ARGS)
