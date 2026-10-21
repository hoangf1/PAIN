using Poppler_jll
pdf = raw"D:\code\PAIN\rea-work\Pain Methodology.pdf"
info = mktemp() do path, io
    close(io)
    run(pipeline(`$(pdfinfo()) $pdf`; stdout=path))
    read(path, String)
end
npages = parse(Int, match(r"Pages:\s+(\d+)", info).captures[1])
for p in 120:150
    out = mktemp() do path, io
        close(io)
        run(`$(pdftotext()) -f $p -l $p -layout $pdf $path`)
        read(path, String)
    end
    if occursin(r"FIGURE\s+E-9|Fig\.?\s*E-9", out)
        println("HIT page $p")
        for line in split(out, '\n')
            s = strip(line)
            occursin(r"FIGURE|E-9|SPACE-AVERAGE|RANGE", s) && println("  ", s)
        end
    end
end
