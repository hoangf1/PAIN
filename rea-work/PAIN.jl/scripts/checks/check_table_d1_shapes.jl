#!/usr/bin/env julia
# Plan 17d: transcribed Table D-1 (mrp.jl) against the independent digitization data/cr3813/digitized_table_D1.csv.
# Criteria fixed 2026-10-20 before the run: frequency, total mass, C_Mn, M, N exact to 1e-5 (abs); shell + plate ≤ total (the total also holds stiffener mass; the deficit is reported);
# shell and plate masses against m ∫ψ² dA: spread of the implied area density ≤ 5 % over the modes (exploratory, report only).
using Pkg; Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN, Printf, Statistics
csv = joinpath(@__DIR__, "..", "..", "..", "data", "cr3813", "digitized_table_D1.csv")
rows = [split(l, ",") for l in readlines(csv)[2:end] if !isempty(strip(l))]
modes = Dict{Int,Any}(); global cur = 0
for r in rows
    if !isempty(r[1])
        global cur = parse(Int, r[1])
        modes[cur] = (f=parse(Float64, r[2]), sym=r[3] == "SYMM", M=parse(Float64, r[10]), Ms=parse(Float64, r[11]), Mp=parse(Float64, r[12]), sh=Tuple[], pl=Tuple[])
    end
    isempty(r[6]) || push!(modes[cur].sh, (parse(Int, r[4]), parse(Int, r[5]), parse(Float64, r[6])))
    isempty(r[9]) || push!(modes[cur].pl, (parse(Int, r[7]), parse(Int, r[8]), parse(Float64, r[9])))
end
sm = structural_modes_from_table_d1(; n_keep=32)
io = IOBuffer(); bad = String[]
for i in 1:32
    d = modes[i]; m = sm.modes[i]
    d.f ≈ m.f_Hz || abs(d.f - m.f_Hz) < 1e-5 || push!(bad, "mode $i frequency $(d.f) vs $(m.f_Hz)")
    abs(d.M - m.M_r) < 1e-5 || push!(bad, "mode $i total mass $(d.M) vs $(m.M_r)")
    (d.sym == m.symmetric) || push!(bad, "mode $i symmetry")
    d.Ms + d.Mp ≤ d.M + 1e-5 || push!(bad, "mode $i shell+plate $(d.Ms + d.Mp) vs $(d.M)")
    all(t -> t[1] == m.M_axial, d.sh) || push!(bad, "mode $i shell M")
    all(t -> t[1] == m.M_axial, d.pl) || push!(bad, "mode $i plate M")
    length(d.sh) == length(m.C_shell) || push!(bad, "mode $i shell term count $(length(d.sh)) vs $(length(m.C_shell))")
    length(d.pl) == length(m.C_floor) || push!(bad, "mode $i plate term count $(length(d.pl)) vs $(length(m.C_floor))")
    for (t, C, n) in zip(d.sh, m.C_shell, m.n_shell)
        (t[2] == n && abs(t[3] - C) < 1e-5) || push!(bad, "mode $i shell n=$(t[2]) C=$(t[3]) vs n=$n C=$C")
    end
    for (t, C, n) in zip(d.pl, m.C_floor, m.n_floor)
        (t[2] == n && abs(t[3] - C) < 1e-5) || push!(bad, "mode $i plate n=$(t[2]) C=$(t[3]) vs n=$n C=$C")
    end
end
println("coefficient/frequency/mass comparison: ", isempty(bad) ? "all 32 modes equal" : "$(length(bad)) differences")
foreach(println, bad)
# exploratory: implied area densities
a, L, θ0 = 0.508, 1.803, deg2rad(56.6); Lp = 2a * sin(θ0); N = 4000
ρs = Float64[]; ρp = Float64[]
for (i, m) in enumerate(sm.modes)
    d = modes[i]
    th = range(θ0, 2π - θ0, length=N + 1)
    Is = sum(PAIN.shell_circumferential(m, t)^2 for t in th[1:end-1]) * step(th) * a * (L / 2)
    xs = range(-Lp / 2, Lp / 2, length=N + 1)
    Ip = sum(sum(C * (m.symmetric ? cos(n * π * x / Lp) : sin(n * π * x / Lp)) for (C, n) in zip(m.C_floor, m.n_floor))^2 for x in xs[1:end-1]) * step(xs) * (L / 2)
    push!(ρs, d.Ms / Is); push!(ρp, d.Mp / Ip)
end
@printf("implied shell area density: median %.3f, min %.3f, max %.3f kg/m²\n", median(ρs), minimum(ρs), maximum(ρs))
@printf("implied plate area density: median %.3f, min %.3f, max %.3f kg/m²\n", median(ρp), minimum(ρp), maximum(ρp))
defic = [modes[i].M - modes[i].Ms - modes[i].Mp for i in 1:32]
@printf("total − (shell + plate): min %.5f, max %.5f kg (all ≥ 0: %s)
", minimum(defic), maximum(defic), all(≥(-1e-5), defic))
println("shell ratios: ", round.(ρs; digits=2)); println("plate ratios: ", round.(ρp; digits=2))
