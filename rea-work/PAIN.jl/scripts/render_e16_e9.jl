# Temporary Poppler for figure renders only — not a runtime PAIN dep
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.add("Poppler_jll")
using Poppler_jll

outdir = joinpath(@__DIR__, "..", "..", "data", "figures")
mkpath(outdir)
pdf = joinpath(@__DIR__, "..", "..", "references", "Pain Methodology.pdf")
for (label, page) in (("e16", 142), ("e17", 143), ("e9", 133), ("e14", 139), ("e15", 141))
    prefix = joinpath(outdir, label)
    run(`$(pdftoppm()) -f $page -l $page -png -r 250 $pdf $prefix`)
    println("wrote $label page $page")
end
