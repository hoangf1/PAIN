#!/usr/bin/env julia
# Phase 75a (IMPLEMENTATION_PLAN.md §8s): rerun validation cases offscreen, save each figure to its map-block folder
# through the same `plot_case` path the GUI Run button uses, and update those cases' rows of
# docs/validation_reports/case_error_summary.csv (other rows untouched). Display only: criteria and verdicts are
# whatever the case computes. Each updated row carries its own run_date; the file's "# generated" header keeps the
# date of the last full snapshot (`write_case_error_summary.jl`). Never opens a GUI window.
#
#   julia --project=. scripts/run/regenerate_case_figures.jl MRP_APPD UNC_COVER   # given cases
#   julia --project=. scripts/run/regenerate_case_figures.jl --all                # every registered case (slow)
ENV["QT_QPA_PLATFORM"] = get(ENV, "QT_QPA_PLATFORM", "offscreen")

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN
using Dates

function main(args)
    PAIN.reload_validation_docs!()   # case records (map block → figure folder) as the docs stand now, not as precompiled
    ids = args == ["--all"] ? collect(PAIN.VALIDATION_CASE_ORDER) : args
    isempty(ids) && error("give case ids or --all")
    for id in ids
        haskey(PAIN.VALIDATION_CASES, id) || error("unknown case: $id")
    end
    path = PAIN.case_error_summary_path()
    lines = readlines(path)
    for id in ids
        case = PAIN.VALIDATION_CASES[id]
        result = PAIN.run_validation_case(id)
        png = PAIN.plot_case(result, case.plot_spec)
        s = PAIN.case_error_summary(result, case.plot_spec)
        max_s = isfinite(s.max_abs) ? PAIN._fmt_err_sig(s.max_abs) : ""
        med_s = isfinite(s.median_abs) ? PAIN._fmt_err_sig(s.median_abs) : ""
        q(x) = "\"" * replace(x, "\"" => "\"\"") * "\""
        row = join((id, string(Dates.today()), result.date, String(result.verdict), s.n_within, s.n_rows,
                    max_s, med_s, q(s.unit), q(s.text)), ",")
        k = findfirst(l -> startswith(l, id * ","), lines)
        k === nothing ? push!(lines, row) : (lines[k] = row)
        println(row, "\n  figure: ", png)
    end
    write(path, join(lines, "\n") * "\n")
    println("updated ", path)
end

main(ARGS)
