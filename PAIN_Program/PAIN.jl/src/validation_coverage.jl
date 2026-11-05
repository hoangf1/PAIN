# Phase 134 (2026-11-05): the chain coverage chart. Each case drawn as a bar over the stages of the program chain it
# runs (its `**Chain span:**` in VALIDATION_GUIDELINE.md §2.13), coloured by what it is compared with (`**Compared
# with:**`), with its recorded verdict. Display only: no criterion or verdict is computed here.

const _COVERAGE_REF_ORDER = (:measurement, :nasa, :verification)
const _COVERAGE_COLOURS = Dict(:measurement => "#1D9E75", :nasa => "#7F77DD", :verification => "#888780")

"""
    coverage_rows(; rec=recorded_case_errors(), verdict_only=false) -> Vector{NamedTuple}

One row per documented case: `id, title, from, to` (indices into `CHAIN_STAGES`), `reference` (`:measurement`, `:nasa`,
`:verification`), `verdict` (`"met"`, `"not met"` or `"no verdict"`, as on the validation map) and `points`
(`"n/N"` rows within the criterion, `""` when the snapshot has none). Sorted by first stage, last stage, reference, id.
`verdict_only` keeps the cases on the validation map.
"""
function coverage_rows(; rec::AbstractDict=recorded_case_errors(), verdict_only::Bool=false)
    rows = NamedTuple[]
    for (id, info) in CASE_INFO
        info.span_from == 0 && continue
        on = on_validation_map(id; rec)
        verdict_only && !on && continue
        r = get(rec, id, nothing)
        push!(rows, (; id, title=info.title, from=info.span_from, to=info.span_to, reference=info.reference,
                     verdict=on ? replace(r.verdict, "_" => " ") : "no verdict",
                     points=(r === nothing || r.n_rows == 0) ? "" : "$(r.n_within)/$(r.n_rows)"))
    end
    sort!(rows; by=r -> (r.from, r.to, findfirst(==(r.reference), _COVERAGE_REF_ORDER), r.id))
    return rows
end

"""`coverage_rows` as JSON for the GUI's Coverage tab: `stages`, `references` (key, label, colour) and `rows`."""
function coverage_json(; verdict_only::Bool=false, rec::AbstractDict=recorded_case_errors())
    rows = [Dict("id" => r.id, "title" => r.title, "from" => r.from - 1, "to" => r.to - 1,
                 "reference" => String(r.reference), "verdict" => r.verdict, "points" => r.points)
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
              xgridvisible=false, ygridvisible=false, limits=((0.5, ns + 2.4), (0.3, n + 0.7)))
    vlines!(ax, 0.5:1:(ns + 0.5); color=(:gray, 0.35), linewidth=0.5)
    for (i, r) in enumerate(rows)
        c = parse(Makie.Colors.Colorant, _COVERAGE_COLOURS[r.reference])
        pale = r.verdict == "no verdict"
        poly!(ax, Rect(r.from - 0.45, i - 0.32, r.to - r.from + 0.9, 0.64);
              color=(c, pale ? 0.25 : 0.85), strokecolor=c, strokewidth=pale ? 0.8 : 0.0,
              linestyle=pale ? :dash : :solid)
        text!(ax, ns + 0.6, i; text=r.verdict * (isempty(r.points) ? "" : " " * r.points), align=(:left, :center),
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
          "without a verdict, not a pass)."; fontsize=11, color=:gray30, tellwidth=false)
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
    println(io, "![Chain coverage](validation_reports/figures/coverage/chain_coverage_verdict.png)\n")
    println(io, "| Chain span | Compared with | Case | Verdict | Points |\n|---|---|---|---|---|")
    for r in rows
        println(io, "| ", CHAIN_STAGES[r.from], " → ", CHAIN_STAGES[r.to], " | ", reference_label(r.reference), " | `",
                r.id, "` ", _md_cell(r.title), " | ", r.verdict, " | ", r.points, " |")
    end
    println(io)
    return String(take!(io))
end

"""Write both coverage figures (cases with a verdict; every case) into `dir`. Returns the two paths."""
function write_coverage_figures(dir::AbstractString=coverage_figure_dir(); rec::AbstractDict=recorded_case_errors())
    return (plot_coverage_chart(joinpath(dir, "chain_coverage_verdict.png"); rec, verdict_only=true),
            plot_coverage_chart(joinpath(dir, "chain_coverage_all.png"); rec, verdict_only=false))
end
