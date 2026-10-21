using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN

fuse = FuselageGeometry(1.803, 0.508, 56.6)
println("fitting RAW Ritz spectral coverage...")
best = fit_mrp_to_table_d1(fuse;
    scales=0.30:0.05:1.2, edges=1.4:0.1:3.2, floor_scales=0.8:0.1:2.5)
println(best)
m = structural_modes(fuse; k_scale=best.k_scale, edge_factor=best.edge_factor,
                     floor_scale=best.floor_scale, n_keep=48, hybrid=false)
npass, pairs = match_ritz_to_table_d1(m; tol_frac=0.05)
println("spectral match ≤5%: $npass/32")
for p in pairs
    p.ok || println("  MISS D1#$(p.d1) ref=$(p.ref) nearest=$(round(p.got;digits=1)) err%=$(round(100*p.err;digits=1))")
end
# also try tol 8% and 10% for honesty
for tol in (0.08, 0.10, 0.15)
    n, _ = match_ritz_to_table_d1(m; tol_frac=tol)
    println("  ≤$(Int(tol*100))%: $n/32")
end
