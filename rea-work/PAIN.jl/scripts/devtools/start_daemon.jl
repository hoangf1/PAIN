# Start DaemonMode with Revise + PAIN preloaded (shared Main).
# Invoked by start_daemon.ps1. Not a PAIN.jl dependency — uses this tools env.
using Pkg

const DEVTOOLS = @__DIR__
const PAIN_ROOT = abspath(joinpath(DEVTOOLS, "..", ".."))

Pkg.activate(DEVTOOLS)
using Revise
using DaemonMode

Pkg.activate(PAIN_ROOT)
using PAIN
using Test
using JSON3

println("PAIN loaded from ", PAIN_ROOT)
println("Revise is loaded; src/ edits are picked up on the next client run.")
println("Starting DaemonMode.serve(shared=true) on port ", DaemonMode.PORT, " …")
flush(stdout)
# shared=true: client scripts run in Main where PAIN is already loaded.
# async=false: single sync accept loop (more reliable under redirected stdout on Windows).
serve(DaemonMode.PORT, true; async=false)
