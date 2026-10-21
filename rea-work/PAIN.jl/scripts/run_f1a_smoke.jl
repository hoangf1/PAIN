#!/usr/bin/env julia
# Phase 6: CCBlade + F1A smoke; compare ℓ=1 peaks to ANOPP Table 8 (X-EXTRAP).
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN

const REPORTS = joinpath(@__DIR__, "..", "..", "docs", "validation_reports")
mkpath(REPORTS)
json = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")

# r_p = a + 0.457 from User Manual methodology grid (not a+0.05 tip-gap only)
fuse = FuselageGeometry(1.803, 0.508, 56.6)
prop = PropellerPlacement(0.965, 90.0, 0.90)
spec = GridSpec()
records = ValidationRecord[]

try
    ff = propeller_freefield_grid(json, fuse, prop, spec; n_harmonics=3, num_src_times=64)
    pref = 20e-6
    anopp = PAIN._read_csv_numeric(joinpath(@__DIR__, "..", "..", "data", "anopp_table8_spl_dB.csv"))
    deltas = Float64[]
    for H in 1:3
        line = [ff.amplitudes[k, 1, H] for k in 1:16]
        spl_f1a = [20 * log10(max(A, 1e-20) / pref) for A in line]
        key = H == 1 ? :SPL_H1_dB : H == 2 ? :SPL_H2_dB : :SPL_H3_dB
        spl_an = anopp[key]
        dpeak = maximum(spl_f1a) - maximum(spl_an)
        push!(deltas, dpeak)
        push!(records, ValidationRecord(
            "SRC_AC", "X-EXTRAP",
            "CCBlade+F1A vs ANOPP Table 8 ℓ=1 (peak SPL)",
            "H=$H peak free-field SPL",
            "informational; sane if |delta|≲15 dB after c0/frame fixes",
            abs(dpeak) ≤ 15 ? "PASS" : "FAIL",
            "F1A_peak=$(round(maximum(spl_f1a); digits=1)) dB ANOPP_peak=$(round(maximum(spl_an); digits=1)) dB delta=$(round(dpeak; digits=1))",
        ))
    end
    ok = all(abs(d) ≤ 15 for d in deltas)
    push!(records, ValidationRecord(
        "SRC_AC", "X-EXTRAP", "CCBlade+F1A smoke",
        "pipeline freefield grid", "finite amps; asound=c0; AA (x3,x1,x2); r_p=0.965",
        ok ? "PASS" : "FAIL",
        "source=$(ff.source) bpf=$(ff.bpf_Hz) maxA=$(maximum(ff.amplitudes)) mean_delta_peak=$(round(sum(deltas)/3; digits=1)) dB; $(ff.notes)",
    ))
    println("F1A smoke OK bpf=$(ff.bpf_Hz) deltas=", round.(deltas; digits=1))
catch e
    push!(records, ValidationRecord(
        "SRC_AC", "X-EXTRAP", "CCBlade+F1A smoke",
        "pipeline freefield grid", "completes", "FAIL",
        "error=$(sprint(showerror, e))",
    ))
    println("F1A smoke FAILED: ", e)
    Base.showerror(stdout, e)
    println()
end
write_validation_record(joinpath(REPORTS, "ccblade_f1a_smoke.md"), records)
println("wrote ccblade_f1a_smoke.md")
