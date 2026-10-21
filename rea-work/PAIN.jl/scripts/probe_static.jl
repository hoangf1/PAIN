#!/usr/bin/env julia
# Phase 25a: probe CCBlade+F1A at Vinf=0 with allow_static=true (no 20 m/s guard).
using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN, Printf, Dates, JSON3

json_path = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
raw = JSON3.read(read(json_path, String))
Rtip = Float64(raw.propeller.tip_radius_m)
D = 2Rtip
R = Rtip
# Printed x/D = −0.125 is behind the plane; AA ahead ≈ −X → x_sign=-1 with positive |x/D|
obs = hub_observers(R, D; x_over_D=[0.125], d_over_D=0.083, x_sign=-1.0, azimuth_deg=0.0)

io = IOBuffer()
println(io, "# Report 996 setup — static probe (phase 25a)\n")
println(io, "Generated $(Dates.today()) by `scripts/probe_static.jl`. Observer: hub, x/D=−0.125 (behind), d/D=0.083, `allow_static=true`.\n")
println(io, "| Vinf m/s | T N | Q N·m | A_H1 Pa | substituted | V used |")
println(io, "|---:|---:|---:|---:|:---:|---:|")

results = []
scratch = joinpath(@__DIR__, "..", "..", "data", "_scratch")
mkpath(scratch)
for Vinf in (0.0, 1.0, 5.0, 20.0)
    txt = read(json_path, String)
    txt2 = replace(txt, r"\"forward_speed_mps\"\s*:\s*[0-9.eE+-]+" => "\"forward_speed_mps\": $Vinf")
    tmp = joinpath(scratch, "probe_static_tmp.json")
    write(tmp, txt2)
    cfg = PAIN._load_aircraft_json(tmp)
    src = evaluate_propeller_source(cfg, obs; n_harmonics=3, num_src_times=64,
                                    loads=:ccblade, allow_static=true)
    push!(results, (Vinf=Vinf, T=src.T, Q=src.Q, A1=src.amplitude[1, 1],
                    sub=src.echo.vinf_substituted, Vused=src.echo.Vinf))
    @printf(io, "| %.1f | %.4f | %.5f | %.6e | %s | %.1f |\n",
            Vinf, src.T, src.Q, src.amplitude[1, 1], src.echo.vinf_substituted, src.echo.Vinf)
    @printf("Vinf=%g T=%.3f Q=%.4f A1=%.4e sub=%s\n", Vinf, src.T, src.Q, src.amplitude[1, 1], src.echo.vinf_substituted)
end

A0, A1v = results[1].A1, results[2].A1
cont = abs(A0 - A1v) / max(A1v, eps())
println(io, "\nContinuity |A(0)−A(1)|/A(1) = $(round(cont; sigdigits=4)).")
println(io, "Finite at V=0: $(all(isfinite.([A0, results[1].T, results[1].Q]))).")
println(io, "\n## Decision\n")
if isfinite(A0) && isfinite(results[1].T) && !results[1].sub
    println(io, "Static works with `allow_static=true`. Default path still substitutes Vinf<1→20 m/s with `@warn` until the guard is removed. **Report 996 / Pereira static-adjacent runs must pass `allow_static=true`.**")
else
    println(io, "Static probe failed; use smallest working speed and state it with every Report 996 result.")
end
println(io, "\nRemaining 25k items (blade-angle shift, polar coverage, rms harmonics, x-sign asymmetry) appended as later steps complete.\n")

out = joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "report996_setup.md")
write(out, String(take!(io)))
println("wrote $out")
