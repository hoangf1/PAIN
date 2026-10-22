#!/usr/bin/env julia
# Phase 21i: new 160-point F1A grid vs extend_line_to_grid of the new ℓ=1 line (diagnostic).
using Pkg; Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN, Printf, Dates, Statistics

json = joinpath(@__DIR__, "..", "..", "examples", "aircraft_scale_hartzell.json")
fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
prop = PropellerPlacement(0.965, 90.0, 0.90)
spec = GridSpec()
t0 = time()
ff = propeller_freefield_grid(json, fuse, prop, spec; n_harmonics=3, num_src_times=32)
wall = time() - t0
pts = ff.pts
nH = 3
line_a = ff.amplitudes[:, 1, :]
line_p = ff.phases[:, 1, :]
ωH = [2π * H * ff.bpf_Hz for H in 1:nH]
gext_a, gext_p = extend_line_to_grid(line_a, line_p, pts; omega_H=ωH)
pref = 20e-6
io = IOBuffer()
println(io, "# GEXT vs full-grid F1A (phase 21i diagnostic)\n")
println(io, "Generated $(Dates.today()) by `scripts/run/compare_gext_vs_f1a_grid.jl`. **Re-run after plan I-01/I-02 ($(Dates.today())).** Same Table-8 calibration on both; only the off-line fill differs. Wall time full-grid (nH=3, nsrc=32): $(round(wall; digits=1)) s.\n")
println(io, "| H | max \\|ΔSPL\\| dB (144 off-line) | RMS ΔSPL dB | max \\|Δphase\\| rad |\n|---:|---:|---:|---:|")
for H in 1:nH
    dspl = Float64[]; dph = Float64[]
    for p in pts
        p.ell == 1 && continue
        A = ff.amplitudes[p.k, p.ell, H]; Ag = gext_a[p.k, p.ell, H]
        push!(dspl, 20 * log10(max(A, 1e-30) / max(Ag, 1e-30)))
        push!(dph, abs(mod(ff.phases[p.k, p.ell, H] - gext_p[p.k, p.ell, H] + π, 2π) - π))
    end
    @printf(io, "| %d | %.2f | %.2f | %.3f |\n", H, maximum(abs, dspl), sqrt(mean(dspl .^ 2)), maximum(dph))
end
println(io, "\n## ΔSPL at H1 (k × ℓ), dB\n")
print(io, "| k \\ ℓ |")
for ell in 1:10; print(io, " $ell |"); end
println(io)
print(io, "|---:|"); for _ in 1:10; print(io, "---:|"); end; println(io)
for k in 1:16
    print(io, "| $k |")
    for ell in 1:10
        A = ff.amplitudes[k, ell, 1]; Ag = gext_a[k, ell, 1]
        d = 20 * log10(max(A, 1e-30) / max(Ag, 1e-30))
        @printf(io, " %+.1f |", d)
    end
    println(io)
end
println(io, "\nNo pass mark. Shows how much the assumed cosine falloff contributed.\n")
out = joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports", "gext_vs_f1a_grid.md")
write(out, String(take!(io)))
println("wrote $out wall=$(round(wall;digits=1))s")
