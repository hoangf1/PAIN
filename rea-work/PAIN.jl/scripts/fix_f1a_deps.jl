using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
# Runtime aeroacoustics deps; remove Poppler tooling dep
try
    Pkg.rm("Poppler_jll")
catch
end
Pkg.add(["AcousticMetrics", "CCBlade", "AcousticAnalogies", "FFTW", "JSON3"])
println("deps ok")
