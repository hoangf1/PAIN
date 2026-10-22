# Wall-time wrapper: julia --project=. scripts/devtools/time_pkg_test.jl [filter…]
using Pkg
t0 = time()
if isempty(ARGS)
    Pkg.test("PAIN")
else
    Pkg.test("PAIN"; test_args=copy(ARGS))
end
dt = time() - t0
println()
println("WALL_TIME_S=", round(dt; digits=2))
