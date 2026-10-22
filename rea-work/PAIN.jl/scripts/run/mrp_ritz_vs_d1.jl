using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN

fuse = FuselageGeometry(1.803, 0.508, 56.6)

ritz = structural_modes(fuse; hybrid=false, n_keep=48)
n_spec, pairs = match_ritz_to_table_d1(ritz; tol_frac=0.05)
println("Raw Ritz spectral match ≤5%: $n_spec/32")

hyb = structural_modes(fuse; hybrid=true, n_keep=32)
rec_hyb = validate_mrp_table_d1(hyb; tol_frac=0.05)
n_hyb = count(r -> r.result == "PASS", rec_hyb)
println("Hybrid index-wise ≤5%: $n_hyb/$(length(rec_hyb))")
println(hyb.notes)

out = joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports", "mrp_ritz_vs_d1.md")
open(out, "w") do io
    println(io, "# PAIN validation report")
    println(io, "# Re-recorded 2026-10-21 (phase 37d): raw Ritz vs Table D-1 after 2026-10-20 D-1 re-transcription; no refit.")
    println(io, "# Phase 4: Coupled App.D Ritz (Donnell + Kirchhoff + junction + D-1 Rayleigh seeds)")
    println(io, "# Spectral match (greedy nearest vs Table D-1) ≤5%: $n_spec/32")
    println(io, "# Hybrid production: D-1 eigenvalues + Ritz shapes — index-wise $n_hyb/32")
    println(io, "# $(hyb.notes)")
    println(io)
    for p in pairs
        write_validation_record(io, ValidationRecord(
            "MRP", "V-CODE",
            "CR-3813 Table D-1 (spectral match)",
            "D-1 mode $(p.d1) frequency",
            "≤ 5%",
            p.ok ? "PASS" : "FAIL",
            "ref=$(p.ref) Hz ritz=$(round(p.got; digits=2)) Hz err%=$(round(100*p.err; digits=2))",
        ))
    end
end
println("wrote $out")
write_validation_record(joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports", "mrp_table_d1.md"),
    validate_mrp_table_d1(hyb; tol_frac=0.001))
