using Poppler_jll

pdf = raw"D:\code\PAIN\rea-work\Pain Methodology.pdf"

# Page count via pdfinfo
info = mktemp() do path, io
    close(io)
    run(pipeline(`$(pdfinfo()) $pdf`; stdout=path))
    read(path, String)
end
println(info)
npages = parse(Int, match(r"Pages:\s+(\d+)", info).captures[1])
println("npages=$npages")

hits = Int[]
for p in 1:npages
    out = mktemp() do path, io
        close(io)
        run(`$(pdftotext()) -f $p -l $p -layout $pdf $path`)
        read(path, String)
    end
    if occursin(r"FIGURE\s+E-11|Fig\.?\s*E-11|FREE-FIELD\s+SOUND\s+LEVELS\s+FOR\s+TEST", out)
        push!(hits, p)
        println("HIT page $p")
        for line in split(out, '\n')
            s = strip(line)
            isempty(s) && continue
            if occursin(r"FIGURE|E-11|FREE-FIELD|First Harmonic|Second Harmonic|Third Harmonic|Measured|Predicted|Distance", s)
                println("  ", s)
            end
        end
    end
end
println("hits=$(hits)")
