using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
# Let the registry supply correct UUIDs
Pkg.add(["Observables", "QML"])
deps = Pkg.project().dependencies
for name in ("Observables", "QML")
    uuid = deps[name]
    info = Pkg.dependencies()[uuid]
    println(name, " => ", info.version, "  uuid=", uuid)
end
