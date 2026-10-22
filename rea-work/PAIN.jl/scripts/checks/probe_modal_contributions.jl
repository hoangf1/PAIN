#!/usr/bin/env julia
# Diagnostic for a miss of the 18b reproduction check: which structural modes carry the Eq. (8) tone sum at H1–H3
# (registered 18b inputs). Localization only; nothing is tuned.
using Pkg; Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN, Printf
paths = default_e11_paths()
r = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3, bpf_Hz=200.0, blocking=R1, trim=:phase3)
inp = r.inputs
function with_modes(ms)
    PainInputs(inp.fuse, inp.prop, StructuralModes(ms, inp.structural.L, inp.structural.a, inp.structural.theta0_deg, ""),
               inp.acoustic, inp.amplitudes, inp.phases, inp.pts, inp.ΔA; sidewall=inp.sidewall, endplates=inp.endplates,
               mech=inp.mech, m_wall=inp.m_wall, η_n_bare=inp.η_n_bare, C_struc=inp.C_struc, ρ0=inp.ρ0, c0=inp.c0)
end
for H in 1:3
    ωH = 2π * 200H
    tot = tone_mean_square_pressure(inp, H, ωH)
    parts = [(tone_mean_square_pressure(with_modes([m]), H, ωH), m) for m in inp.structural.modes]
    sort!(parts; by=first, rev=true)
    @printf("H%d total %.2f dB; τ_t = %.3g\n", H, 10log10(tot / 20e-6^2), PAIN.sidewall_tau(inp, ωH))
    for (p, m) in parts[1:4]
        @printf("   mode %2d f=%6.1f Hz %s M_r=%.2f  share %.1f %%  alone %.2f dB\n", m.index, m.f_Hz, m.symmetric ? "S" : "A", m.M_r, 100p / tot, 10log10(p / 20e-6^2))
    end
end
