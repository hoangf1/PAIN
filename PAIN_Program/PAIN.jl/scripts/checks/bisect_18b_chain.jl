#!/usr/bin/env julia
# Plan 19f: bisect the 18b chain. Rerun 18b, then swap one block at a time for NASA's own quantity (or the alternative reading of 19c, 19d).
# Criterion fixed 2026-10-20 before the run (IMPLEMENTATION_PLAN.md, phase 19): 18b criterion unchanged (4 dB); a block is implicated when
# its swap moves a harmonic ≥ 3 dB toward NASA; shifts recorded per harmonic. Nothing is tuned; no `src/` change. The tone sum below is a
# local copy of `tone_mean_square_pressure` with switches (checked equal to PAIN's at the base setting).
using Pkg; Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN, Printf
const P = PAIN
paths = default_e11_paths()
tg = P._read_csv_numeric(joinpath(dirname(paths.A), "t1_interior_targets.csv"))
nasa = tg[:nasa_pain_pred_dB][1:3]
r0 = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3, bpf_Hz=200.0, blocking=R1, trim=:phase3)
inp0 = r0.inputs
s_pain = r0.spectrum.harmonic_SPL_dB

function loglog_interp(f, fs, ys)
    x = log10(f); xs = log10.(fs); i = clamp(searchsortedlast(xs, x), 1, length(xs) - 1)
    t = clamp((x - xs[i]) / (xs[i+1] - xs[i]), 0, 1)
    return 10^((1 - t) * log10(ys[i]) + t * log10(ys[i+1]))
end
e14 = P._read_csv_numeric(joinpath(@__DIR__, "..", "..", "..", "data", "cr3813", "e14_acoustic_loss_calculated.csv"))
e15 = P._read_csv_numeric(joinpath(@__DIR__, "..", "..", "..", "data", "cr3813", "e15_structural_loss_targets.csv"))

Base.@kwdef struct Opt
    eps_alt::Bool = false
    tau_one::Bool = false            # τ_t = 1 inside f̄' (Eq. 8): sidewall transmission removed
    unbarred_eta2::Bool = false      # η_r'' of Eq. (83) with f' (τ_t = 1) as printed, f̄' elsewhere
    eta_n_fn = nothing               # f_Hz -> η_n (all modes), replaces Eq. (77)
    eta_r_fn = nothing               # f_Hz -> η_r', replaces Eqs. (79)-(82)
    mirror = nothing                 # θ_deg -> θ_deg of an added mirrored point
    eta_r_tot = nothing              # (mode, ω_r) -> η_r of Eqs. (79)-(81) before the trim, replaces `structural_loss_total` (19h)
end

function gen_force(st, H, inp, mirror)
    sc = 0.0; ss = 0.0
    for p in inp.pts, θ in (mirror === nothing ? (p.theta_deg,) : (p.theta_deg, mirror(p.theta_deg)))
        A = inp.amplitudes[p.k, p.ell, H]; ϕ = inp.phases[p.k, p.ell, H]
        ψ = P.structural_shell_psi(st, p.z, θ, inp.fuse.L)
        sc += A * cos(ϕ) * ψ; ss += A * sin(ϕ) * ψ
    end
    return inp.ΔA^2 / 2 * (sc^2 + ss^2)
end

function tone_p2(inp, H, ωH, o::Opt)
    fuse = inp.fuse; a, L = fuse.a, fuse.L
    θ0 = deg2rad(fuse.theta0_deg); Lp = 2a * sin(θ0); A = L * (Lp + 2a * (π - θ0))
    V = P.cabin_volume(fuse); ρ0, c0 = inp.ρ0, inp.c0; ext = inp.allow_extrapolation
    qtop = something(inp.q_max, P.axial_truncation(ωH, L, c0))
    trimmed = P.has_trim(inp)
    τ_t = o.tau_one ? 1.0 : P.sidewall_tau(inp, ωH)
    ξ = trimmed ? P.trim_conductance(inp.sidewall, ωH, inp.m_wall; ρ0, c0, allow_extrapolation=ext) : 0.0
    ξe = trimmed ? P.trim_conductance(inp.endplates, ωH, Inf; ρ0, c0, allow_extrapolation=ext) : 0.0
    nst = length(inp.structural.modes)
    Ψ = [gen_force(st, H, inp, o.mirror) for st in inp.structural.modes]
    ωr = [2π * st.f_Hz for st in inp.structural.modes]
    ηrp = Vector{Float64}(undef, nst)
    for (j, st) in enumerate(inp.structural.modes)
        if o.eta_r_fn !== nothing
            ηrp[j] = o.eta_r_fn(ωr[j] / 2π)
        else
            ηr = o.eta_r_tot !== nothing ? o.eta_r_tot(st, ωr[j]) : P.structural_loss_total(st, ωr[j]; a, L, m=inp.m_wall, C=inp.C_struc, ρ0, c0)
            ηrp[j] = trimmed ? P.structural_loss_with_trim(ηr, ωr[j], inp.m_wall, P.trim_Cw(inp.sidewall, ωr[j]; allow_extrapolation=ext)) : ηr
        end
    end
    eps3(ac, q) = o.eps_alt ? ac.eps_n : P.cabin_eps_3d(ac, q)
    pref = (c0 / V)^2 * (ρ0 * c0 * A)^2 * ωH^4
    p2 = 0.0
    for q in 0:qtop, ac in inp.acoustic.modes
        ωn = 2π * P.cabin_frequency_3d(ac, a, L, q; c0)
        εn = eps3(ac, q)
        N = o.eta_n_fn !== nothing ? o.eta_n_fn(ωH / 2π) * ωn^2 :
            trimmed ? P.acoustic_loss_modal(ac, q, ωH, ωn; a, L, V, c0, ξ, ξ_e=ξe).N : inp.η_n_bare * ωn^2
        Dn = (ωn^2 - ωH^2)^2 + N^2
        for (j, st) in enumerate(inp.structural.modes)
            f = P.coupling_factor(ac, st, fuse; τ_t, q)
            f == 0 && continue
            f2 = o.unbarred_eta2 ? P.coupling_factor(ac, st, fuse; τ_t=1.0, q) : f
            ηrpp = P.structural_loss_coupled(N, ωn, ωr[j], f2, εn, st.M_r, V, A; ρ0, c0)
            Dr = (ωr[j]^2 - ωH^2)^2 + ((ηrp[j] + ηrpp) * ωr[j]^2)^2
            p2 += pref * εn * f^2 * Ψ[j] / (st.M_r^2 * Dn * Dr)
        end
    end
    return p2
end
spl(inp, o) = [10log10(tone_p2(inp, H, 2π * H * 200.0, o) / (20e-6)^2 + 1e-30) for H in 1:3]

function with_trim(inp, p3)
    P.PainInputs(inp.fuse, inp.prop, inp.structural, inp.acoustic, inp.amplitudes, inp.phases, inp.pts, inp.ΔA;
                 sidewall=p3.sidewall, endplates=p3.ends, mech=p3.mech, m_wall=p3.m_wall, η_n_bare=inp.η_n_bare,
                 C_struc=inp.C_struc, q_max=inp.q_max, allow_extrapolation=inp.allow_extrapolation, ρ0=inp.ρ0, c0=inp.c0)
end
p3_05 = phase3_trim(; η_lining=0.5); p3_10 = phase3_trim(; η_lining=1.0)
inp05 = with_trim(inp0, p3_05); inp10 = with_trim(inp0, p3_10)
η14_05(f) = loglog_interp(f, e14[:f_Hz], e14[:eta_calc_trim0p5])
η15(f) = loglog_interp(f, e15[:f_Hz], e15[:eta_meas])
θ0mirror(θ) = -θ

s_base = spl(inp0, Opt())
chk = maximum(abs.(s_base .- s_pain))
rows = [
 ("0. registered 18b (η_lining 0.05)", inp0, Opt()),
 ("1a. NASA trim loss factor η_T = 0.5 (E-16 predictions), whole trim rebuilt", inp05, Opt()),
 ("1b. η_T = 1.0 (second E-14/E-15 curve)", inp10, Opt()),
 ("2. η_n from the E-14 calculated curve (η_T = 0.5 column) at ω_H, all modes", inp0, Opt(eta_n_fn=η14_05)),
 ("3. η_r' from the E-15 measured points (interpolated; no calculated curve is digitized)", inp0, Opt(eta_r_fn=η15)),
 ("4. ε_n(q > 0) = ε_n(q = 0) (19c alternative)", inp0, Opt(eps_alt=true)),
 ("5. field mirrored about θ = 0 (19d alternative)", inp0, Opt(mirror=θ0mirror)),
 ("6. τ_t = 1 in f̄'", inp0, Opt(tau_one=true)),
 ("7. η_r'' of Eq. (83) with the unbarred f' (19a item iii)", inp0, Opt(unbarred_eta2=true)),
 ("8. η_T = 0.5 and η_n from E-14 (η_T = 0.5 column)", inp05, Opt(eta_n_fn=η14_05)),
 ("9. η_T = 0.5, η_n from E-14, η_r' from E-15 measured", inp05, Opt(eta_n_fn=η14_05, eta_r_fn=η15)),
 ("10. η_T = 0.5 and τ_t = 1", inp05, Opt(tau_one=true)),
 ("11. η_T = 0.5 and unbarred f' in Eq. (83)", inp05, Opt(unbarred_eta2=true)),
]
res = [(l, spl(i, o)) for (l, i, o) in rows]
base = res[1][2]
io = IOBuffer()
println(io, "# Bisection of the 18b chain (plan 19f)\n")
println(io, "Generated by `scripts/checks/bisect_18b_chain.jl`. Criterion fixed 2026-10-20 before the run (`IMPLEMENTATION_PLAN.md`, phase 19): the 18b criterion is unchanged (|computed − NASA PAIN| ≤ 4 dB at each harmonic); a block is **implicated** when its swap moves a harmonic ≥ 3 dB toward NASA's PAIN prediction; shifts are recorded per harmonic. Nothing is tuned and nothing in `src/` changed: the tone sum is a local copy of `tone_mean_square_pressure` with switches, equal to PAIN's at the base setting to $(@sprintf("%.1e", chk)) dB.\n")
println(io, "Inputs as 18b (R1 blocking, ANOPP Table 8, GEXT off the ℓ = 1 line, Phase III stacks); NASA PAIN predictions (Fig. E-16 circles): $(nasa[1]), $(nasa[2]), $(nasa[3]) dB.\n")
println(io, "Blocks already equal to NASA's and not swapped: Table C-1 cabin modes (15a, within 0.002 %), Table D-1 structural modes (17d, equal to an independent digitization).\n")
println(io, "| Swap | H1 dB | H2 dB | H3 dB | shift H1, H2, H3 (dB) | vs NASA (dB) | within 4 dB | implicated (≥ 3 dB toward NASA) |\n|---|---:|---:|---:|---|---|---:|---|")
for (l, s) in res
    d = s .- base; vn = s .- nasa
    imp = [abs(s[H] - nasa[H]) <= abs(base[H] - nasa[H]) - 3 for H in 1:3]
    @printf(io, "| %s | %.2f | %.2f | %.2f | %+.2f, %+.2f, %+.2f | %+.1f, %+.1f, %+.1f | %d of 3 | %s |\n", l, s..., d..., vn..., count(abs.(vn) .<= 4),
            l == res[1][1] ? "(base)" : (any(imp) ? "**" * join(["H$H" for H in 1:3 if imp[H]], ", ") * "**" : "no"))
end
println(io, "\nSwap 3 uses digitized measured E-15 points as a stand-in for NASA's calculated η_r, which is not digitized; a hit there would be a pointer, not a reproduction.")
if abspath(PROGRAM_FILE) == @__FILE__
    out = joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports", "bisect_18b.md")
    write(out, String(take!(io))); println(read(out, String))
end
