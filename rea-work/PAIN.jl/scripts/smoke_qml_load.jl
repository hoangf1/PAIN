using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN
println("smoke_qml_load: calling main(; smoke_ms=1000)")
main(; smoke_ms=1000)
println("smoke_qml_load PASS")
