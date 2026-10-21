using Poppler_jll
outdir = raw"D:\code\PAIN\rea-work\data\figures"
mkpath(outdir)
pdf = raw"D:\code\PAIN\rea-work\Pain Methodology.pdf"
for (label, page) in (("e16", 142), ("e17", 143), ("e18", 145), ("e12", 136), ("e9", 133))
    prefix = joinpath(outdir, label)
    run(`$(pdftoppm()) -f $page -l $page -png -r 250 $pdf $prefix`)
    println("wrote $label page $page")
end
