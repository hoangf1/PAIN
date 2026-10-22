using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using Poppler_jll
using PAIN

run(`$(pdftoppm()) -f 132 -l 132 -png -r 250 $(raw"D:\code\PAIN\rea-work\Pain Methodology.pdf") $(raw"D:\code\PAIN\rea-work\data\figures\e9")`)
println("rendered e9")

r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
println("SPL=", round.(r.spectrum.harmonic_SPL_dB; digits=2))
println(r.ff.notes)
for rec in evaluate_T1(r.spectrum)
    println(rec.result, " | ", rec.metric, " | ", rec.notes)
end
