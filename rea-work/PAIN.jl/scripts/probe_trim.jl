#!/usr/bin/env julia
# Sensitivity diagnostic (plan 17a): App. A trim quantities of the Phase III stacks at the T1 tone frequencies.
# Prints τ_t (Eq. A.22, insulation and mechanical paths), ξ, ξ_e (Eq. A.16) and η̄_n (Eq. 78). No fitted parameter;
# not a validation result.
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN

fuse = FuselageGeometry(1.803, 0.508, 56.6)
V = cabin_volume(fuse)
S = 2 * fuse.a * (π - deg2rad(fuse.theta0_deg)) * fuse.L
S_e = V / fuse.L
for ηlin in (0.05, 0.5, 1.0)
    p3 = phase3_trim(; η_lining=ηlin)
    println("trim loss factor η_lining = $ηlin")
    for f in (200.0, 400.0, 600.0, 1250.0, 1600.0, 2000.0)
        ω = 2π * f
        τi = trim_tau_insulation(p3.sidewall, ω)
        τ = trim_tau(p3.sidewall, ω; mech=p3.mech)
        ξ = trim_conductance(p3.sidewall, ω, p3.m_wall)
        ξe = trim_conductance(p3.ends, ω, Inf)
        ηbar = acoustic_loss_average(ω; V, S, S_e, ξ, ξ_e=ξe)
        println("  f=$f  τ_t(ins)=$(round(τi; sigdigits=3))  τ_t(total)=$(round(τ; sigdigits=3))  ξ=$(round(ξ; sigdigits=3))  ξ_e=$(round(ξe; sigdigits=3))  η̄_n=$(round(ηbar; sigdigits=3))")
    end
end
