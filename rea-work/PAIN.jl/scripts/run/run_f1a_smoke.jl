#!/usr/bin/env julia
# I-07 / I-12: raw CCBlade+F1A vs ANOPP Table 8 on ℓ=1 (X-EXTRAP).
# Re-run after plan I-01/I-02 (2026-10-21). No Table-8 peak calibration (CLAUDE.md).
# Untuned geometry: pitch_offset_deg = 0 (B-5); tuned JSON kept only as "calibrated (Table 8)".
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN

const REPORTS = joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports")
mkpath(REPORTS)
json_tuned = joinpath(@__DIR__, "..", "..", "examples", "aircraft_scale_hartzell.json")

# Untuned copy for the check (B-5 / I-12): pitch_offset = 0, calibrate = false.
txt = read(json_tuned, String)
txt = replace(txt, r"\"pitch_offset_deg\"\s*:\s*[0-9.eE+-]+" => "\"pitch_offset_deg\": 0.0")
if occursin("anopp_table8_calibrate", txt)
    txt = replace(txt, r"\"anopp_table8_calibrate\"\s*:\s*(true|false)" => "\"anopp_table8_calibrate\": false")
else
    txt = replace(txt, r"\}\s*$" => ",\n  \"anopp_table8_calibrate\": false\n}\n")
end
json = joinpath(tempdir(), "aircraft_scale_hartzell_untuned_i12.json")
write(json, txt)

fuse = FuselageGeometry(1.803, 0.508, 56.6)
prop = PropellerPlacement(0.965, 90.0, 0.90)
spec = GridSpec()
records = ValidationRecord[]

header_note = "re-run after plan I-01/I-02 (2026-10-21); raw F1A, pitch_offset_deg=0, anopp_table8_calibrate=false (I-12/B-5)"

try
    t0 = time()
    ff = propeller_freefield_grid(json, fuse, prop, spec; n_harmonics=3, num_src_times=64)
    wall = time() - t0
    anopp = PAIN._read_csv_numeric(joinpath(@__DIR__, "..", "..", "..", "data", "cr3813", "anopp_table8_spl_dB.csv"))
    deltas = Float64[]
    for H in 1:3
        line = [ff.amplitudes[k, 1, H] for k in 1:16]
        spl_f1a = [peak_Pa_to_spl_dB(max(A, 1e-20)) for A in line]
        key = H == 1 ? :SPL_H1_dB : H == 2 ? :SPL_H2_dB : :SPL_H3_dB
        spl_an = anopp[key]
        dpeak = maximum(spl_f1a) - maximum(spl_an)
        push!(deltas, dpeak)
        push!(records, ValidationRecord(
            "SRC_AC", "X-EXTRAP",
            "CCBlade+F1A vs ANOPP Table 8 ℓ=1 (rms SPL via peak_Pa_to_spl_dB); $header_note",
            "H=$H free-field SPL rms (raw, untuned; amplitude convention fixed 2026-10-21, post-hoc)",
            "informational X-EXTRAP; not a pass criterion (I-12: no calibrate-to-Table-8)",
            "REPORTED",
            "F1A_rms=$(round(maximum(spl_f1a); digits=1)) dB ANOPP_rms=$(round(maximum(spl_an); digits=1)) dB delta=$(round(dpeak; digits=1))",
        ))
    end
    push!(records, ValidationRecord(
        "SRC_AC", "X-EXTRAP", "CCBlade+F1A smoke; $header_note",
        "pipeline freefield grid", "informational X-EXTRAP (I-12)",
        "REPORTED",
        "source=$(ff.source) bpf=$(ff.bpf_Hz) maxA=$(maximum(ff.amplitudes)) wall_s=$(round(wall; digits=1)) deltas=$(round.(deltas; digits=1)) dB; $(ff.notes)",
    ))
    println("F1A smoke (raw/untuned, peak→rms SPL) bpf=$(ff.bpf_Hz) deltas=", round.(deltas; digits=1), " wall=", round(wall; digits=1), "s")
catch e
    push!(records, ValidationRecord(
        "SRC_AC", "X-EXTRAP", "CCBlade+F1A smoke; $header_note",
        "pipeline freefield grid", "completes", "FAIL",
        "error=$(sprint(showerror, e))",
    ))
    println("F1A smoke FAILED: ", e)
    Base.showerror(stdout, e)
    println()
end
smoke_path = joinpath(REPORTS, "ccblade_f1a_smoke.md")
write_validation_record(smoke_path, records)
# Prepend post-hoc amplitude-convention note (I-17 / F4).
let body = read(smoke_path, String)
    write(smoke_path, "Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.\n\n" * body)
end
println("wrote ccblade_f1a_smoke.md")
rm(json; force=true)
