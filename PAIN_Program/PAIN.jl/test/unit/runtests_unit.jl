# Phase 64: unit tests, one file per source module (`test_<module>.jl`). Included by test/runtests.jl
# as one top-level testset per file; can also be run alone:
#   julia --project=. -e 'using Test, PAIN; include("test/unit/runtests_unit.jl")'
using Test, PAIN, LinearAlgebra, Random
const _UNIT_DIR = @__DIR__
# every file a unit test writes goes here (the suite's temp output dir when run from runtests.jl)
const UNIT_OUT = isdefined(Main, :TEST_OUT) ? Main.TEST_OUT : mktempdir()
for f in sort(filter(n -> startswith(n, "test_") && endswith(n, ".jl"), readdir(_UNIT_DIR)))
    if isdefined(Main, :_run_if)
        Main._run_if("Unit tests: $(f[6:end-3])") do
            include(joinpath(_UNIT_DIR, f))
        end
    else
        @testset "Unit tests: $(f[6:end-3])" begin
            include(joinpath(_UNIT_DIR, f))
        end
    end
end
