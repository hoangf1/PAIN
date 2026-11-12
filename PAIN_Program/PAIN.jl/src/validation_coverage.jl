# Phase 134 (2026-11-05): the chain coverage chart. Each case drawn as a bar over the stages of the program chain it
# runs (its `**Chain span:**` in CASE_RECORDS.md), coloured by what it is compared with (`**Compared
# with:**`), with its recorded verdict. Display only: no criterion or verdict is computed here.

const _COVERAGE_REF_ORDER = (:measurement, :nasa, :verification)
const _COVERAGE_COLOURS = Dict(:measurement => "#1D9E75", :nasa => "#7F77DD", :verification => "#888780")

# Phase 145d (2026-11-10; ISSUE-018's list redone on the cases that keep a verdict, decided by Claude under the author's
# delegation of 2026-11-10). A family is cases that share one comparison or one run. `derived_from` names the case this
# one is computed from: a sum of its levels, a variant with one input changed, or the same points shown another way.
# A derived case is drawn thinner and is not counted as an independent comparison. No verdict is merged.
const CASE_FAMILIES = Dict{String,NamedTuple{(:family, :derived_from),Tuple{String,String}}}(
    "R172428_EXP" => (family="CR-172428 test-article tones against the measurement", derived_from=""),
    "R172428_DB_EXP" => (family="CR-172428 test-article tones against the measurement", derived_from="R172428_EXP"),
    "R172428_DBA_EXP" => (family="CR-172428 test-article tones against the measurement", derived_from="R172428_EXP"),
    # 2026-11-10: parent and variant swapped so the case that keeps the verdict (the shipped path, 135f) is the parent
    "NR_TP1964" => (family="TP-1964 bare cylinder", derived_from="NR_TP1964_XOVER"),       # same bands below 2.5 kHz
    "NR_TP1964_XOVER" => (family="TP-1964 bare cylinder", derived_from=""),
    "PER_FIG7" => (family="Pereira forward flight", derived_from=""),
    "PER_FIG8" => (family="Pereira forward flight", derived_from=""),
    "PER_FIG9" => (family="Pereira forward flight", derived_from="PER_FIG8"),   # Phase 74: equals Fig. 8 within 0.1 dB
    "R996_FIG12" => (family="Report 996 static sound levels", derived_from=""),
    "R996_FIG13A" => (family="Report 996 static sound levels", derived_from=""),
    "R996_FIG14" => (family="Report 996 static sound levels", derived_from=""),
    "T1_APPB" => (family="T1 on CR-172428 App. B's printed field", derived_from=""),
    "T1_MEAS_DAMPING_APPB" => (family="T1 on CR-172428 App. B's printed field", derived_from="T1_APPB"),
    "R172428_ETAT2" => (family="CR-172428 η_T = 2.0 run", derived_from=""),
    "APPB_ETA_N_T2" => (family="CR-172428 η_T = 2.0 run", derived_from="APPB_ETA_N_T2_BAND"),   # swapped 2026-11-10, as above
    "APPB_ETA_N_T2_BAND" => (family="CR-172428 η_T = 2.0 run", derived_from=""),
    "APPB_EPS_N" => (family="CR-172428 App. B per-mode printout", derived_from=""),
    "APPB_ETA_N" => (family="CR-172428 App. B per-mode printout", derived_from=""),
    "APPB_ETA_RPP" => (family="CR-172428 App. B per-mode printout", derived_from=""),
    "R172428_ETA" => (family="CR-172428 App. B per-mode printout", derived_from=""),
    "CYL2D_C1" => (family="CYL2D cabin modes", derived_from=""),
    "CYL2D_PRINTED" => (family="CYL2D cabin modes", derived_from=""),
    "CABIN_FREQ_PRINTED" => (family="CYL2D cabin modes", derived_from=""),
)

# Phase 146c (2026-11-11, decided by Claude under the author's authority of 2026-11-10 and 2026-11-11): a plain title per
# case with a verdict, in words, each read against the case's criterion text: what is compared, with what, and where it is
# printed. No phase tags and no letter codes. Shown title first, ID in brackets.
const PLAIN_TITLES = Dict{String,String}(
    "R996_LOADS" => "Propeller thrust and power coefficients against measurement (NACA RM L8H25a)",
    "PER_FIG7" => "Propeller tone phase shift in forward flight against Pereira's measurement (Fig. 7)",
    "PER_FIG8" => "Propeller tone levels in forward flight against Pereira's measurement (Fig. 8)",
    "R996_FIG12" => "Static propeller tone levels along the axis against measurement (Report 996, Fig. 12)",
    "R996_FIG13A" => "Static first propeller tone along the axis against measurement (Report 996, Fig. 13a)",
    "R996_FIG14" => "Static propeller tone levels against tip Mach number, against measurement (Report 996, Fig. 14a)",
    "R996_FIG10_FLAT" => "Level increase at a flat wall beside a propeller against measurement (Report 996, Fig. 10)",
    "R172428_EXP" => "Cabin tone levels of the test article against the measured space averages (CR-172428)",
    "R172428_ETAT2" => "Cabin tone levels with trim loss factor 2.0 against NASA's printed prediction (CR-172428, Table 12)",
    "NR_TP1964_XOVER" => "Noise reduction of a bare cylinder against measurement (TP-1964, Fig. 8)",
    "FLIGHT_MODES" => "Structural modes of the flight aircraft against NASA's printed mode list (CR-172428, App. C)",
    "MRP_APPD" => "Fuselage structural modes against NASA's printed Table D-1 (CR-3813)",
    "R172428_ETA" => "Structural-mode loss factors against NASA's printout (CR-172428, App. B)",
    "APPB_EPS_N" => "Cabin-mode factor ε_n against NASA's printout (CR-172428, App. B)",
    "CABIN_FREQ_PRINTED" => "Cabin acoustic mode frequencies against NASA's printed list (CR-172428, App. B)",
    "CYL2D_C1" => "Cabin acoustic modes of the floored cylinder against NASA's Table C-1 (CR-3813)",
    "CYL2D_PRINTED" => "Cabin acoustic modes of two more aircraft against NASA's printed lists (CR-172428, App. C)",
    "APPB_ETA_N_T2_BAND" => "Cabin-mode loss factors with trim loss factor 2.0 against NASA's printout (CR-172428, p. 85)",
    "APPB_ETA_RPP" => "Loss factors of structure–cabin mode pairs against NASA's printout (CR-172428, App. B)",
)

"""Plain title of a case (Phase 146c): `PLAIN_TITLES`, else the registry title with a trailing phase tag such as "(44e)"
removed."""
function case_plain_title(id::AbstractString)
    haskey(PLAIN_TITLES, id) && return PLAIN_TITLES[id]
    t = haskey(CASE_INFO, id) ? CASE_INFO[id].title : haskey(VALIDATION_CASES, id) ? VALIDATION_CASES[id].title : String(id)
    return strip(replace(t, r"\s*\((?:\d+[a-z]?(?:[/,–-]\s*\d*[a-z]?)*)(?:,\s*post-hoc)?\)\s*$" => ""))
end

"""Family and parent of `id` (Phase 145d): `(family, derived_from)`, both `""` for a case in no family."""
case_family(id::AbstractString) = get(CASE_FAMILIES, String(id), (family="", derived_from=""))

"""
    coverage_rows(; rec=recorded_case_errors(), verdict_only=false) -> Vector{NamedTuple}

One row per documented case: `id, title, from, to` (indices into `CHAIN_STAGES`), `reference` (`:measurement`, `:nasa`,
`:verification`), `verdict` (`"met"`, `"not met"` or `"no verdict"`, by `has_verdict`) and `points`
(`"n/N"` rows within the criterion, `""` when the snapshot has none). Sorted by first stage, last stage, reference, id.
`verdict_only` keeps the cases with a verdict. `figure` (Phase 146a, 2026-11-10) is the case's source figure from its
`FigureRef` ("document, figure, PDF p. n"), `""` for a case not in the registry.
"""
function coverage_rows(; rec::AbstractDict=recorded_case_errors(), verdict_only::Bool=false)
    rows = NamedTuple[]
    for (id, info) in CASE_INFO
        info.span_from == 0 && continue
        on = has_verdict(id; rec)
        verdict_only && !on && continue
        r = get(rec, id, nothing)
        push!(rows, (; id, title=case_plain_title(id), from=info.span_from, to=info.span_to, reference=info.reference,
                     figure=_coverage_figure(id), method_limit=on && method_limit(id),   # Phase 137c
                     family=case_family(id).family, derived_from=case_family(id).derived_from,   # Phase 145d
                     verdict=on ? replace(r.verdict, "_" => " ") : "no verdict",
                     points=(r === nothing || r.n_rows == 0) ? "" : "$(r.n_within)/$(r.n_rows)"))
    end
    sort!(rows; by=r -> (r.from, r.to, findfirst(==(r.reference), _COVERAGE_REF_ORDER), r.id))
    return rows
end

"""A case's source figure as one line: document, figure and PDF page (Phase 146a)."""
function _coverage_figure(id::AbstractString)
    haskey(VALIDATION_CASES, id) || return ""
    f = VALIDATION_CASES[id].figure_ref
    return f.document * ", " * f.figure * (f.pdf_page === nothing ? "" : ", PDF p. $(f.pdf_page)")
end

"""`coverage_rows` as JSON for the GUI's Coverage tab: `stages`, `references` (key, label, colour) and `rows`."""
function coverage_json(; verdict_only::Bool=false, rec::AbstractDict=recorded_case_errors())
    rows = [Dict("id" => r.id, "title" => r.title, "from" => r.from - 1, "to" => r.to - 1,
                 "reference" => String(r.reference), "verdict" => r.verdict, "points" => r.points, "figure" => r.figure,
                 "method_limit" => r.method_limit, "family" => r.family, "derived_from" => r.derived_from)
            for r in coverage_rows(; rec, verdict_only)]
    refs = [Dict("key" => String(k), "label" => reference_label(k), "colour" => _COVERAGE_COLOURS[k])
            for k in _COVERAGE_REF_ORDER]
    return JSON3.write(Dict("stages" => collect(CHAIN_STAGES), "references" => refs, "rows" => rows))
end

"""
    plot_coverage_chart(path; rec=recorded_case_errors(), verdict_only=true) -> String

The chain coverage chart as a PNG: one row per case, its bar spanning its chain stages, coloured by what it is compared
with; cases without a verdict drawn pale. The verdict and points are printed at the right. Returns `path`.
"""
function plot_coverage_chart(path::AbstractString; rec::AbstractDict=recorded_case_errors(), verdict_only::Bool=true)
    rows = coverage_rows(; rec, verdict_only)
    n = length(rows); ns = length(CHAIN_STAGES)
    fig = Figure(size=(1250, 120 + 17 * max(n, 1)), fontsize=12)
    ax = Axis(fig[1, 1]; yreversed=true, xaxisposition=:top, xticks=(1:ns, collect(CHAIN_STAGES)),
              xticklabelrotation=0.0, xticklabelsize=11, yticks=(1:n, [r.id for r in rows]), yticklabelsize=10,
              xgridvisible=false, ygridvisible=false, limits=((0.5, ns + 2.9), (0.3, n + 0.7)))
    vlines!(ax, 0.5:1:(ns + 0.5); color=(:gray, 0.35), linewidth=0.5)
    for (i, r) in enumerate(rows)
        c = parse(Makie.Colors.Colorant, _COVERAGE_COLOURS[r.reference])
        pale = r.verdict == "no verdict"
        h = isempty(r.derived_from) ? 0.64 : 0.36                 # Phase 145d: a derived case is drawn thinner
        # ISSUE-031 (2026-11-12): a not-met bar whose gate a published prediction also misses is drawn half as strong
        # with a black outline, apart from the bars this code alone misses
        ml = r.method_limit
        poly!(ax, Rect(r.from - 0.45, i - h / 2, r.to - r.from + 0.9, h);
              color=(c, pale ? 0.25 : ml ? 0.45 : 0.85), strokecolor=ml ? :black : c, strokewidth=pale ? 0.8 : ml ? 1.6 : 0.0,
              linestyle=pale ? :dash : :solid)
        text!(ax, ns + 0.6, i; text=r.verdict * (isempty(r.points) ? "" : " " * r.points) *
                                    (ml ? " · prediction misses too" : ""), align=(:left, :center),
              fontsize=10, color=r.verdict == "met" ? :darkgreen : (r.verdict == "not met" ? :firebrick : :gray40))
    end
    hideydecorations!(ax; ticklabels=false)
    refs = [k for k in _COVERAGE_REF_ORDER if any(r -> r.reference === k, rows)]
    elems = Any[PolyElement(color=(parse(Makie.Colors.Colorant, _COVERAGE_COLOURS[k]), 0.85)) for k in refs]
    labels = [reference_label(k) for k in refs]
    if !verdict_only
        push!(elems, PolyElement(color=(:gray, 0.25), strokecolor=:gray, strokewidth=0.8, linestyle=:dash))
        push!(labels, "no verdict (pale, dashed)")
    end
    Legend(fig[2, 1], elems, labels, "Compared with"; orientation=:horizontal, framevisible=false, titleposition=:left)
    Label(fig[3, 1], "Right: recorded verdict; n/N = rows within the case's own criterion (recorded snapshot; for a case " *
          "without a verdict, not a pass).
Black outline: a published prediction (PAIN's printout or a higher-fidelity " *
          "method) misses the same gate. Thin bar: computed from another case (a sum or a variant)."; fontsize=11,
          color=:gray30, tellwidth=false)
    mkpath(dirname(path))
    save(path, fig)
    return String(path)
end

"""Folder of the coverage figures referenced from §0 and `NO_VERDICT_CASES.md`."""
coverage_figure_dir() = normpath(joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "figures", "coverage"))

"""
    coverage_markdown(; rec=recorded_case_errors()) -> String

The §0 chain coverage section: the figure of the cases with a verdict and, per span, which cases cover it and what they
are compared with. Built from §2.13 and the snapshot only.
"""
function coverage_markdown(; rec::AbstractDict=recorded_case_errors())
    rows = coverage_rows(; rec, verdict_only=true)
    io = IOBuffer()
    println(io, "### Chain coverage (cases with a verdict)\n")
    println(io, "Each bar spans the part of the program chain a case runs: from the stage its given input enters at to the ",
            "stage of the quantity it compares (`**Chain span:**`, §2.13); its colour is what it is compared with ",
            "(`**Compared with:**`). The cases without a verdict are drawn in `NO_VERDICT_CASES.md`; the GUI's Coverage ",
            "tab shows both.\n")
    nind = count(r -> isempty(r.derived_from), rows)
    nfam = length(unique(r.family for r in rows if !isempty(r.family)))
    println(io, "**", length(rows), " cases with a verdict, ", nind, " independent comparisons**",
            nind == length(rows) ? " (the sums and variants of a case carry no verdict since Phase 135f)" :
            " ($(length(rows) - nind) computed from another case, drawn thinner)",
            "; met ", count(r -> r.verdict == "met", rows), ", not met ", count(r -> r.verdict == "not met", rows),
            " (of these, ", count(r -> r.method_limit, rows), " where a published prediction misses the same gate: black outline)",
            ". ", nfam, " families group the cases that share one run or one printout (Phase 145d; GUI Coverage tab, ",
            "\"Order by source figure\").\n")
    println(io, "![Chain coverage](validation_reports/figures/coverage/chain_coverage_verdict.png)\n")
    println(io, "| Chain span | Compared with | Case | Verdict | Points |\n|---|---|---|---|---|")
    for r in rows
        println(io, "| ", CHAIN_STAGES[r.from], " → ", CHAIN_STAGES[r.to], " | ", reference_label(r.reference), " | ",
                _md_cell(r.title), " (`", r.id, "`) | ", r.verdict, r.method_limit ? " (a published prediction misses too)" : "", " | ",
                r.points, " |")
    end
    println(io)
    print(io, why_not_met_markdown(; rec))   # Phase 145e
    return String(take!(io))
end

"""Write both coverage figures (cases with a verdict; every case) into `dir`. Returns the two paths."""
function write_coverage_figures(dir::AbstractString=coverage_figure_dir(); rec::AbstractDict=recorded_case_errors())
    return (plot_coverage_chart(joinpath(dir, "chain_coverage_verdict.png"); rec, verdict_only=true),
            plot_coverage_chart(joinpath(dir, "chain_coverage_all.png"); rec, verdict_only=false))
end
