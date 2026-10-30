# Phase 91d: run every notebook in this folder through Pluto, headless, and fail if any cell errors.
# Each notebook runs from a temp copy (Pluto may rewrite a file it opens), so nothing in the repository changes.
#
#   julia --project=rea-work/notebooks rea-work/notebooks/check_notebooks.jl
using Pluto

ENV["PAIN_JL"] = normpath(joinpath(@__DIR__, "..", "PAIN.jl"))
ENV["QT_QPA_PLATFORM"] = get(ENV, "QT_QPA_PLATFORM", "offscreen")
session = Pluto.ServerSession()
session.options.server.disable_writing_notebook_files = true
failed = String[]
for f in sort(filter(n -> occursin(r"^\d\d_.*\.jl$", n), readdir(@__DIR__)))
    tmp = joinpath(mktempdir(), f)
    cp(joinpath(@__DIR__, f), tmp)
    nb = Pluto.SessionActions.open(session, tmp; run_async=false)
    bad = [c for c in nb.cells if c.errored]
    for c in bad
        println(f, ": cell errored:\n", first(c.code, 120), "\n=> ", first(string(c.output.body), 400))
    end
    println(f, ": ", length(nb.cells), " cells, ", length(bad), " errors")
    isempty(bad) || push!(failed, f)
    Pluto.SessionActions.shutdown(session, nb; async=false)
end
isempty(failed) || error("notebooks with errors: " * join(failed, ", "))
println("all notebooks ran without errors")
