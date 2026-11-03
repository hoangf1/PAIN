#!/usr/bin/env julia
# Plan 17k: freeze regression baselines of the Phase 17 checks (17d–17i) in data/baselines/phase17_baselines.csv.
# Run only to create or deliberately renew the file; `Pkg.test()` compares against it (rtol 1e-6). Renewing it is a dated decision.
using Pkg; Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN, Printf
out = joinpath(@__DIR__, "..", "..", "..", "data", "baselines", "phase17_baselines.csv")
io = IOBuffer()
println(io, "# Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)")
println(io, "# Phase 17 regression baselines (prior: 2026-10-21 amplitude-convention I-17/F4; 2026-10-20 eta_T=0.5). e11 source, R2 blocking, BPF 200 Hz, 3 harmonics. name,value")
println(io, "name,value")
for trim in (:bare, :phase3)
    # The form the test pins (Phase 93): printed Eq. (82) and the CR-3813 tone sum (`_cr3813_tone_form`); until 2026-10-30
    # this script used the defaults and no longer matched the test.
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2, trim=trim, η_r_trimmed_area=false)
    inp = r.inputs
    spl17 = interior_spl(PAIN._cr3813_tone_form(inp); bpf_Hz=200.0, n_harmonics=3, broadband=false).harmonic_SPL_dB
    for H in 1:3
        @printf(io, "spl_%s_H%d,%.10g\n", trim, H, spl17[H])
        trim === :bare || continue
        for (j, st) in enumerate(inp.structural.modes)
            @printf(io, "psiG_H%d_mode%d,%.10g\n", H, j, generalized_force(st, H, inp.amplitudes, inp.phases, inp.pts, inp.fuse; ΔA=inp.ΔA))
        end
    end
    if trim === :phase3
        for (k, f) in enumerate((1250.0, 1600.0, 2000.0))
            @printf(io, "band_%d,%.10g\n", Int(f), r.spectrum.third_octave_SPL_dB[PAIN.nearest_third_octave(f, collect(keys(r.spectrum.third_octave_SPL_dB)))])
        end
        for H in 1:3
            @printf(io, "tau_t_H%d,%.10g\n", H, PAIN.sidewall_tau(inp, 2π * 200H))
        end
    else
        fm = maximum(abs(coupling_factor(ac, st, inp.fuse)) for ac in inp.acoustic.modes, st in inp.structural.modes)
        @printf(io, "max_abs_fprime,%.10g\n", fm)
        for ac in inp.acoustic.modes[1:6], (j, st) in enumerate(inp.structural.modes[1:8])
            @printf(io, "fprime_n%d_r%d,%.10g\n", ac.index, j, coupling_factor(ac, st, inp.fuse))
        end
    end
end
write(out, String(take!(io))); println("wrote $out")
