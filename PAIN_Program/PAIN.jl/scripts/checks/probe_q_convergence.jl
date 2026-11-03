#!/usr/bin/env julia
# Register 13a(d): convergence of the Eq. (8) tone ⟨p²⟩ in the axial cabin-mode index q at H1–H3 (e11 case, Phase III trim).
# Rule: accept q_max = ⌈2ω_H L/(π c0)⌉ when q_max + 2 changes ⟨p²⟩ by ≤ 0.1 dB, else raise q_max.
# Re-run of the 15b probe with Eq. (8) in place of the surrogate sum (plan 17a). Diagnostic, not a validation result.
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN

io = IOBuffer()
println(io, "# Axial-index convergence of the Eq. (8) tone sum (phase 17a, diagnostic)\n")
println(io, "Rule 13a(d): accept q_max = ⌈2ω_H L/(π c0)⌉ when q_max + 2 changes ⟨p²⟩ by ≤ 0.1 dB, else raise q_max. Eq. (8) with the App. A trim chain, no tuning.\n")
for trim in (:phase3, :bare)
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2, trim=trim)
    inp, fuse = r.inputs, r.fuse
    println(io, "## trim = `$trim`\n")
    println(io, "| H | f_H (Hz) | q_max | SPL(q=0) dB | SPL(q_max) dB | SPL(q_max+2) dB | Δ(q_max+2 − q_max) dB | rule |")
    println(io, "|---|---|---|---|---|---|---|---|")
    for H in 1:3
        ωH = 2π * H * r.ff.bpf_Hz
        qm = axial_truncation(ωH, fuse.L, inp.c0)
        spl(q) = 10 * log10(tone_mean_square_pressure(inp, H, ωH; q_max=q) / (20e-6)^2 + 1e-30)
        s0, s1, s2 = spl(0), spl(qm), spl(qm + 2)
        ok = abs(s2 - s1) ≤ 0.1
        println(io, "| $H | $(H * r.ff.bpf_Hz) | $qm | $(round(s0; digits=2)) | $(round(s1; digits=2)) | $(round(s2; digits=2)) | $(round(s2 - s1; digits=3)) | $(ok ? "met" : "NOT met") |")
    end
    println(io)
end
out = joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports", "q_convergence.md")
write(out, String(take!(io)))
println(read(out, String))
