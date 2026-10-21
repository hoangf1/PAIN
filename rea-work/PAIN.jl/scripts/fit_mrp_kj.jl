using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN

function main()
    fuse = FuselageGeometry(1.803, 0.508, 56.6)
    best = (npass=0, err=Inf, ks=0.0, ef=0.0, fs=0.0, kj=0.0)
    # Fine grid around 30/32 hit
    for ks in 0.60:0.01:0.72, ef in 1.8:0.1:2.6, fs in 2.0:0.05:2.5, kj in (1.0e7, 1.2e7, 1.4e7, 1.6e7)
        m = structural_modes(fuse; k_scale=ks, edge_factor=ef, floor_scale=fs, k_j=kj,
                             n_keep=48, hybrid=false)
        npass, pairs = PAIN.match_ritz_to_table_d1(m)
        err = sum(p.err^2 for p in pairs)
        if npass > best.npass || (npass == best.npass && err < best.err)
            best = (npass=npass, err=err, ks=ks, ef=ef, fs=fs, kj=kj)
            println("new best npass=$npass ks=$ks ef=$ef fs=$fs kj=$kj err=$(round(err; digits=5))")
        end
    end
    println("FINAL ", best)

    m = structural_modes(fuse; k_scale=best.ks, edge_factor=best.ef, floor_scale=best.fs,
                         k_j=best.kj, n_keep=48, hybrid=false)
    _, pairs = PAIN.match_ritz_to_table_d1(m)
    for p in pairs
        status = p.ok ? "PASS" : "FAIL"
        println("$status D1#$(p.d1) ref=$(p.ref) got=$(round(p.got; digits=2)) err%=$(round(100 * p.err; digits=2))")
    end
end

main()
