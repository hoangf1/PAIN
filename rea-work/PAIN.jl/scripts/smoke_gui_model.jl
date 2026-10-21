using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN

obs = make_gui_observables()
obs["source"][] = "e11"
obs["n_harmonics"][] = 3.0
obs["bpf_Hz"][] = 200.0
ok = run_pain_gui!(obs)
println("ok=", ok)
println("status=", obs["status"][])
println("tag=", obs["validity_tag"][])
@assert ok
@assert obs["validity_tag"][] == "V-EXP"
@assert occursin("PASS", obs["t1_text"][])
println("smoke_gui_model PASS")
