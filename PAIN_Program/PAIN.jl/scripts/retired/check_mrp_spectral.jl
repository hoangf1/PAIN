using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN
f = FuselageGeometry(1.803, 0.508, 56.6)
r = structural_modes(f; hybrid=false, n_keep=48)
n, pairs = match_ritz_to_table_d1(r; tol_frac=0.05)
println("spectral $n/32")
for p in pairs
    p.ok || println("  miss $(p.d1) ref=$(p.ref) got=$(round(p.got;digits=1)) err%=$(round(100*p.err;digits=1))")
end
h = structural_modes(f; hybrid=true, n_keep=32)
println("hybrid ", count(x -> x.result == "PASS", validate_mrp_table_d1(h; tol_frac=0.05)), "/32")
