using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
Pkg.add(["CCBlade", "AcousticAnalogies", "FFTW", "JSON3", "SparseArrays"])
println("deps ok")
