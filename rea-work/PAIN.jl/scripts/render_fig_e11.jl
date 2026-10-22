using Poppler_jll

outdir = joinpath(@__DIR__, "..", "..", "data", "figures")
mkpath(outdir)
pdf = joinpath(@__DIR__, "..", "..", "references", "Pain Methodology.pdf")

# Fig E-11 is page 135; also grab neighbors and E-16 region later
for (label, page) in (("e11", 135), ("e11_prev", 134), ("e11_next", 136))
    prefix = joinpath(outdir, label)
    run(`$(pdftoppm()) -f $page -l $page -png -r 300 $pdf $prefix`)
    println("wrote ", prefix, "-*.png")
end

# Find E-16 / E-17 / E-18 pages for T1 later
for p in 140:169
    out = mktemp() do path, io
        close(io)
        run(`$(pdftotext()) -f $p -l $p -layout $pdf $path`)
        read(path, String)
    end
    if occursin(r"FIGURE\s+E-1[678]|COMPARISON OF PREDICTED AND MEASURED SOUND", out)
        println("HIT page $p")
        for line in split(out, '\n')
            s = strip(line)
            occursin(r"FIGURE\s+E-", s) && println("  ", s)
        end
    end
end
