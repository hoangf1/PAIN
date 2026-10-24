# Phase 64b: every function defined in src/ is named in a test/unit file, or listed below with the reason.
# The inventory comes from Julia's method table (file of each method), so one-line and multi-line
# definitions are all found. A name counts as tested when it appears as a whole word in test/unit/*.jl.

const _UNIT_EXEMPT_FILES = Dict(
    "gui_main.jl" => "QML bindings: they need a running Qt engine; exercised by scripts/smoke/smoke_qml_load.jl",
)
_unit_exempt_name(n) = startswith(n, "_run_") || occursin(r"^_iso\d+_validation_cases$", n)   # covered by run_validation_case

function _unit_inventory()
    byfile = Dict{String,Vector{String}}()
    for n in names(PAIN; all=true)
        s = String(n)
        (startswith(s, "#") || s in ("eval", "include")) && continue
        isdefined(PAIN, n) || continue
        f = getfield(PAIN, n)
        (f isa Function && parentmodule(f) === PAIN) || continue
        for m in methods(f)
            path = String(m.file)
            (endswith(path, ".jl") && occursin("src", path)) || continue
            v = get!(byfile, basename(path), String[])
            s in v || push!(v, s)
        end
    end
    return byfile
end

function _unit_untested()
    text = join((read(joinpath(@__DIR__, f), String) for f in readdir(@__DIR__) if endswith(f, ".jl") && f != basename(@__FILE__)), "\n")
    missing = Tuple{String,String}[]
    for (file, ns) in sort(collect(_unit_inventory()))
        haskey(_UNIT_EXEMPT_FILES, file) && continue
        for n in ns
            _unit_exempt_name(n) && continue
            occursin(Regex("(?<![A-Za-z0-9_!])" * replace(n, "!" => "\\!") * "(?![A-Za-z0-9_!])"), text) || push!(missing, (file, n))
        end
    end
    return missing
end

@testset "every src function has a unit test" begin
    missing = _unit_untested()
    isempty(missing) || @info "functions without a unit test" missing
    @test isempty(missing)
end
