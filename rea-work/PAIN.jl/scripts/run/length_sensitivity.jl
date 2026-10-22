#!/usr/bin/env julia
# Post-hoc sensitivity, 2026-10-22: test-article length 1.803 m vs 1.83 m.
# No length selected on the basis of any error. Defaults, criteria, reference
# data and existing reports are not changed. Writes a new report only.
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN
using Dates

const L_SHORT = 1.803   # Table D-1 title caption typo (71 in.)
const L_LONG = 1.83     # I-22 / App. D body / App. E / validation report (72 in.)

# Runnable registry cases whose computed result depends on the test-article length
# (search of FuselageGeometry / phase3_trim / run_pain_pipeline / appd / noise_reduction
# defaults). CYL2D_C1 is 2-D cross-section only (no L) — listed as searched, not run.
# E11_FREEFIELD / E12_BLOCK build a FuselageGeometry but grid X3/D and ΔL do not use L.
const CASES_DEPEND = [
    "REPRO_18b",
    "T1",
    "T2",
    "T2_EQ19",
    "E21_E22_NR",
    "E18_TONES",
    "E15_STRUCT_LOSS",
    "E14_LOSS",
    "MRP_RITZ",
    "MRP_APPD",
    "GEXT_BOUND",
]
const CASES_SEARCHED_NO_L = ["CYL2D_C1", "E11_FREEFIELD", "E12_BLOCK", "MRP_D1"]

"""Pull a short headline from a case result (reason + a few computed values)."""
function _headline(r::ValidationCaseResult)
    vals = String[]
    n = min(6, length(r.table))
    for i in 1:n
        row = r.table[i]
        push!(vals, "$(row.quantity)=$(round(row.computed; sigdigits=6))")
    end
    more = length(r.table) > n ? " …(+$(length(r.table)-n))" : ""
    head = isempty(vals) ? "(no table rows)" : join(vals, "; ") * more
    return "verdict=$(r.verdict); $(r.reason); $head"
end

function _run_at(L::Float64, id::AbstractString)
    return with_test_article_length(L) do
        run_validation_case(id)
    end
end

function main()
    reset_test_article_length!()
    L_default = test_article_length()
    @assert !test_article_length_overridden()

    results = Dict{String,NamedTuple}()
    for id in CASES_DEPEND
        println("=== $id @ L=$L_SHORT ===")
        r_short = _run_at(L_SHORT, id)
        println("=== $id @ L=$L_LONG ===")
        r_long = _run_at(L_LONG, id)
        # Ensure restore between cases
        @assert test_article_length() == L_default
        @assert !test_article_length_overridden()
        Δ_verdict = r_short.verdict != r_long.verdict
        # Pairwise residual differences on shared table rows (by index)
        n = min(length(r_short.table), length(r_long.table))
        diffs = Float64[]
        for i in 1:n
            push!(diffs, r_long.table[i].computed - r_short.table[i].computed)
        end
        max_abs = isempty(diffs) ? NaN : maximum(abs, diffs)
        results[id] = (;
            short=r_short, long=r_long, Δ_verdict, max_abs_diff=max_abs, diffs)
        println("  short=$(r_short.verdict) long=$(r_long.verdict) Δ_verdict=$Δ_verdict max|Δ|=$max_abs")
    end

    report = abspath(joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports",
                              "length_sensitivity.md"))
    open(report, "w") do io
        println(io, "# Test-article length sensitivity (1.803 m vs 1.83 m)")
        println(io)
        println(io, "**Post-hoc sensitivity, 2026-10-22; no length selected on the basis of any error.**")
        println(io)
        println(io, "Source text of CR-3813 is internally inconsistent by 1 in.: Table D-1 title /")
        println(io, "App. D example list print **1.803 m (71 in.)**; App. D body, App. E and the")
        println(io, "validation report print **1.83 m (72 in.)**. This report measures how much the")
        println(io, "recorded validation results move under that choice. Defaults, criteria,")
        println(io, "reference/digitized files and existing validation reports are unchanged.")
        println(io, "Program default at generation time: $(L_default) m.")
        println(io)
        println(io, "## Cases")
        println(io)
        println(io, "**Run (result depends on L):** ", join(CASES_DEPEND, ", "))
        println(io)
        println(io, "**Searched, not run (no L dependence in the computed quantities):** ",
                join(CASES_SEARCHED_NO_L, ", "))
        println(io)
        println(io, "| Case | Verdict @ 1.803 m | Verdict @ 1.83 m | Verdict changes? | max \\|Δ computed\\| |")
        println(io, "|------|-------------------|------------------|------------------|---------------------|")
        for id in CASES_DEPEND
            r = results[id]
            mad = isnan(r.max_abs_diff) ? "—" : string(round(r.max_abs_diff; sigdigits=5))
            println(io, "| `$id` | `$(r.short.verdict)` | `$(r.long.verdict)` | ",
                    r.Δ_verdict ? "**yes**" : "no", " | ", mad, " |")
        end
        println(io)
        println(io, "## Per-case detail")
        println(io)
        for id in CASES_DEPEND
            r = results[id]
            println(io, "### `$id`")
            println(io)
            println(io, "- **L = 1.803 m:** ", _headline(r.short))
            println(io)
            println(io, "- **L = 1.83 m:** ", _headline(r.long))
            println(io)
            println(io, "- **Difference:** max \\|computed(1.83) − computed(1.803)\\| on paired table rows = ",
                    isnan(r.max_abs_diff) ? "—" : string(r.max_abs_diff),
                    "; verdict changes: ", r.Δ_verdict ? "yes" : "no")
            println(io)
            if !isempty(r.diffs)
                println(io, "| quantity | computed @ 1.803 | computed @ 1.83 | Δ |")
                println(io, "|----------|------------------|-----------------|---|")
                n = min(length(r.short.table), length(r.long.table))
                for i in 1:n
                    a = r.short.table[i]
                    b = r.long.table[i]
                    println(io, "| ", a.quantity, " | ", a.computed, " | ", b.computed, " | ",
                            b.computed - a.computed, " |")
                end
                println(io)
            end
        end
        println(io, "## Restore check")
        println(io)
        println(io, "After every case, `test_article_length()` == $L_default and the override flag is clear.")
        println(io, "Final: L=$(test_article_length()), overridden=$(test_article_length_overridden()).")
        println(io)
        println(io, "Generated $(Dates.now()) by `PAIN.jl/scripts/run/length_sensitivity.jl`.")
    end
    println("wrote $report")
    println("Final L=$(test_article_length()) overridden=$(test_article_length_overridden())")
    return results
end

main()
