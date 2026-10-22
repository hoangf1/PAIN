#!/usr/bin/env julia
# Sensitivity diagnostic (plan 17a): the T1 tone levels over the ranges of the assumption register
# (`VALIDATION_GUIDELINE.md` §2.11.1: g = η_n of a bare cabin 0.02–0.10, C of Eq. 80 2–4, f = Phase III trim values).
# Every run uses the registered CR-3813 chain; nothing here is chosen to improve T1 or T2, and the output is the
# input to the uncertainty plan (phase 30), not a fit.
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN

function run(label; kw...)
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2, kw...)
    println(rpad(label, 34), " SPL H1–H3 = ", round.(r.spectrum.harmonic_SPL_dB; digits=1))
end

run("phase3 trim (default)")
run("bare, η_n = 0.05"; trim=:bare)
for η in (0.02, 0.10)
    run("bare, η_n = $η"; trim=:bare, η_n_bare=η)
end
for C in (2.0, 4.0)
    run("phase3, C = $C"; C_struc=C)
end
for ηl in (0.01, 0.10)
    p3 = phase3_trim(; η_lining=ηl)
    run("phase3, lining η = $ηl"; sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends, mech=p3.mech)
end
for (lab, p3) in (("facing on skin side", phase3_trim(; facing_side=:skin)),
                  ("G-10 wavespeed 2800", phase3_trim(; G10_wavespeed=2800.0)),
                  ("G-10 wavespeed 3600", phase3_trim(; G10_wavespeed=3600.0)),
                  ("points only (no floor-edge lines)", phase3_trim(; n_lines=0)),
                  ("lines only (no point connections)", phase3_trim(; N_points=0)))
    run("phase3, $lab"; sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends, mech=p3.mech)
end
