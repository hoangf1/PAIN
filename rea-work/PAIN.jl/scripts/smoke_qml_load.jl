using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN
# Phase 34f: QML loads Run + Validation tabs (no display interaction required).
@assert haskey(VALIDATION_CASES, "CYL2D_C1")
@assert length(list_validation_cases()) == length(VALIDATION_CASE_ORDER)
println("smoke_qml_load: calling main(; smoke_ms=1000)")
main(; smoke_ms=1000)
println("smoke_qml_load PASS")
