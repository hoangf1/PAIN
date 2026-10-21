using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN

# Phase 34a: computational core lives in run_validation_case("CYL2D_C1"); this script
# still writes the report (R8) from the shared case result.
result = run_validation_case("CYL2D_C1")
plot_case(result, VALIDATION_CASES["CYL2D_C1"].plot_spec)

records = ValidationRecord[]
for row in result.table
    push!(records, ValidationRecord(
        "CYL2D", result.label,
        "CR-3813 Table C-1 θ0=56.6° (App. C scheme, NY=10)",
        row.quantity,
        row.within_tolerance ? "within criterion" : "outside criterion",
        row.within_tolerance ? "PASS" : "FAIL",
        "ref=$(row.reference) got=$(row.computed) residual=$(row.residual)",
    ))
end
out = joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "cyl2d_table_c1.md")
mkpath(dirname(out))
write_validation_record(out, records)
npass = count(r -> r.result == "PASS", records)
println("CYL2D_C1: $(result.verdict) — $(result.reason)")
println("CYL2D Table C-1: $npass/$(length(records)) PASS → $out")
