using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN
include(joinpath(@__DIR__, "..", "test", "fig_c3_values.jl"))

# App. C scheme (phase 15a). Criteria fixed 2026-10-20 before the comparison:
# all 20 frequencies and generalized masses within 0.1 % of Table C-1 (c0 = 341 m/s, the speed
# implied by the table), symmetry types equal, Fig. C-3 modes 0–5 equal to the printed one-decimal values.
res = cyl2d_modes(56.6; n_modes=20, NY=10, c0=TABLE_C1_C0)
ref = TABLE_C1_FREQ_HZ
records = ValidationRecord[]
for (i, m) in enumerate(res.modes)
    r = ref[i]
    if r == 0
        err = abs(m.f_Hz_unit - r)
        ok = err < 0.01
        tol = "< 0.01 Hz (rigid)"
    else
        err = 100 * abs(m.f_Hz_unit - r) / r
        ok = err ≤ 0.1
        tol = "≤ 0.1 %"
    end
    push!(records, ValidationRecord(
        "CYL2D", "V-CODE", "CR-3813 Table C-1 θ0=56.6° (App. C scheme, NY=10)",
        "mode $(m.index) f_Hz (a=1 m)", tol, ok ? "PASS" : "FAIL",
        "got=$(round(m.f_Hz_unit; digits=3)) ref=$r err=$(round(err; digits=4))",
    ))
    gref = TABLE_C1_GENMASS[i]
    gerr = 100 * abs(m.gen_mass_unit - gref) / gref
    push!(records, ValidationRecord(
        "CYL2D", "V-CODE", "CR-3813 Table C-1 θ0=56.6° (App. C scheme, NY=10)",
        "mode $(m.index) generalized mass Φ_G", "≤ 0.1 %", gerr ≤ 0.1 ? "PASS" : "FAIL",
        "got=$(round(m.gen_mass_unit; digits=5)) ref=$gref err=$(round(gerr; digits=4))",
    ))
    push!(records, ValidationRecord(
        "CYL2D", "V-CODE", "CR-3813 Table C-1 θ0=56.6° (App. C scheme, NY=10)",
        "mode $(m.index) symmetry", "equal", m.symmetric == TABLE_C1_SYMMETRIC[i] ? "PASS" : "FAIL",
        "got=$(m.symmetric ? "SYM" : "ANTI") ref=$(TABLE_C1_SYMMETRIC[i] ? "SYM" : "ANTI")",
    ))
end
mm = fig_c3_mismatches(res)
push!(records, ValidationRecord(
    "CYL2D", "V-CODE", "CR-3813 Fig. C-3 modes 0–5", "grid values, one decimal", "equal at all 6 × 68 nodes",
    isempty(mm) ? "PASS" : "FAIL", "$(length(mm)) mismatches"))
out = joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "cyl2d_table_c1.md")
mkpath(dirname(out))
write_validation_record(out, records)
npass = count(r -> r.result == "PASS", records)
println("CYL2D Table C-1 / Fig. C-3: $npass/$(length(records)) PASS → $out")
