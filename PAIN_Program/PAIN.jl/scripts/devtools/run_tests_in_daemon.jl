# Include test/runtests.jl with the current ARGS as the testset filter.
# Usage via daemon:
#   .\scripts\devtools\run_in_daemon.ps1 scripts\devtools\run_tests_in_daemon.jl
#   .\scripts\devtools\run_in_daemon.ps1 scripts\devtools\run_tests_in_daemon.jl CYL2D
#   .\scripts\devtools\run_in_daemon.ps1 scripts\devtools\run_tests_in_daemon.jl CYL2D "Validation case registry"
#
# run_in_daemon.ps1 escapes spaces in filters as <|> (DaemonMode wire format
# cannot preserve spaces). Decode here before include.

for i in eachindex(ARGS)
    ARGS[i] = replace(ARGS[i], "<|>" => " ")
end

const RUNTESTS = abspath(joinpath(@__DIR__, "..", "..", "test", "runtests.jl"))
isfile(RUNTESTS) || error("missing $RUNTESTS (pwd=$(pwd()), @__DIR__=$(@__DIR__))")

println("run_tests_in_daemon: filter ARGS = ", isempty(ARGS) ? "(none — all)" : join(ARGS, ", "))
include(RUNTESTS)
