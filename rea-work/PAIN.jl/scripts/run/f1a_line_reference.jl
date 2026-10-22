#!/usr/bin/env julia
# Plan step 21b: equivalence reference for the phase-21 refactor (script only, no src/ change).
# Runs current propeller_freefield_grid on aircraft_scale_hartzell.json once calibrated and once
# with anopp_table8_calibrate=false; writes ℓ=1 amplitudes/phases to data/baselines/f1a_line_reference.csv.
using Pkg; Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN, Dates, JSON3, Printf

json_path = joinpath(@__DIR__, "..", "..", "examples", "aircraft_scale_hartzell.json")
n_harmonics = 3
num_src_times = 32   # match planned 21g test budget; stated in CSV header

cfg0 = JSON3.read(read(json_path, String))
fuse = FuselageGeometry(Float64(cfg0.fuselage.L_m), Float64(cfg0.fuselage.a_m), Float64(cfg0.fuselage.theta0_deg))
prop = PropellerPlacement(Float64(cfg0.propeller_placement.r_p_m),
                          Float64(cfg0.propeller_placement.phi_p_deg),
                          Float64(cfg0.propeller_placement.z_p_m))
spec = GridSpec(Int(cfg0.grid.k_max), Int(cfg0.grid.ell_max), Int(cfg0.grid.k_p))

function run_one(calibrate::Bool)
    tmp = joinpath(tempdir(), "f1a_line_ref_$(calibrate ? "cal" : "raw").json")
    txt = read(json_path, String)
    # Inject / replace the calibrate flag without a full JSON rewrite.
    if occursin("anopp_table8_calibrate", txt)
        txt = replace(txt, r"\"anopp_table8_calibrate\"\s*:\s*(true|false)" =>
                            "\"anopp_table8_calibrate\": $(calibrate)")
    else
        txt = replace(txt, r"\}\s*$" => ",\n  \"anopp_table8_calibrate\": $(calibrate)\n}\n")
    end
    write(tmp, txt)
    ff = propeller_freefield_grid(tmp, fuse, prop, spec; n_harmonics, num_src_times)
    rm(tmp; force=true)
    return ff
end

out = joinpath(@__DIR__, "..", "..", "..", "data", "baselines", "f1a_line_reference.csv")
mkpath(dirname(out))
open(out, "w") do io
    println(io, "# f1a_line_reference.csv — phase 21b equivalence reference (ℓ = 1 only)")
    println(io, "# Date: ", Dates.today())
    println(io, "# Script: scripts/run/f1a_line_reference.jl")
    println(io, "# JSON: examples/aircraft_scale_hartzell.json")
    println(io, "# n_harmonics=$n_harmonics; num_src_times=$num_src_times")
    println(io, "# Notes: current code path is ℓ=1 + GEXT; this file stores the ℓ=1 line before/after Table-8 calibration.")
    println(io, "calibrated,k,H,amp_Pa,phase_rad")
    for (cal, label) in ((true, "true"), (false, "false"))
        ff = run_one(cal)
        for k in 1:size(ff.amplitudes, 1), H in 1:n_harmonics
            @printf(io, "%s,%d,%d,%.16e,%.16e\n", label, k, H, ff.amplitudes[k, 1, H], ff.phases[k, 1, H])
        end
        println("done calibrate=$cal notes=$(ff.notes)")
    end
end
println("wrote $out")
