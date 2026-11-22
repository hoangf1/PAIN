#!/usr/bin/env julia
# Convenience launcher — same as `using PAIN; main()`.
# No Pkg.instantiate here: it cost ~3.5 s on every start (2026-11-21). Install once with the README's setup step.
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."); io=devnull)
using PAIN
main()
