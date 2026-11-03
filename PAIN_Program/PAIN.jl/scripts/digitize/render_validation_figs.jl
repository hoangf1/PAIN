using Poppler_jll
outdir = joinpath(@__DIR__, "..", "..", "..", "data", "cr3813", "pages")
mkpath(outdir)
pdf = joinpath(@__DIR__, "..", "..", "..", "references", "Pain Methodology.pdf")
for (label, page) in (("e16", 142), ("e17", 143), ("e18", 145), ("e12", 136), ("e9", 133))
    prefix = joinpath(outdir, label)
    run(`$(pdftoppm()) -f $page -l $page -png -r 250 $pdf $prefix`)
    println("wrote $label page $page")
end
