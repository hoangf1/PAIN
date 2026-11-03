#!/usr/bin/env julia
# Display-only Validation-map error snapshot. Runs every registered case and writes
# docs/validation_reports/case_error_summary.csv, then the at-a-glance section at the top of
# docs/VALIDATION_GUIDELINE.md and docs/NO_VERDICT_CASES.md from it. Does not change criteria or verdicts.
# Never open a GUI window.
ENV["QT_QPA_PLATFORM"] = get(ENV, "QT_QPA_PLATFORM", "offscreen")

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN

path = write_case_error_summary()
println("wrote ", path)
println("wrote ", write_validation_scoreboard())   # top-of-file status section of VALIDATION_GUIDELINE.md
println("wrote ", write_no_verdict_cases())       # docs/NO_VERDICT_CASES.md: the cases kept off the map
rec = recorded_case_errors(path)
println("cases=", length(rec))
for id in ("R996_LOADS", "R996_FIG14", "T1", "UNC_COVER", "BBN_CIRC", "POLAR_R996")
    haskey(rec, id) || continue
    s = rec[id]
    println(id, ": ", s.text)
end
