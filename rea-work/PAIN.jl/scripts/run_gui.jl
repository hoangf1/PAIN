#!/usr/bin/env julia
# Convenience launcher — same as `using PAIN; main()`
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()
using PAIN
main()
