### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 740ecce7-4406-5223-82bb-7be425366131
md"""
# Reading the validation cases

Every check of this recreation is a registered *case*: fixed inputs, a reference, and a criterion written down (with its
date) before the case was first run. This notebook shows how to run one, read its result, and where the case sits.

**What carries a verdict.** A case may be *met* or *not met* only if it compares with an experiment (E), or checks that
the code does exactly what PAIN did on PAIN's own inputs (P) (`CLAUDE.md`, rule of 2026-10-29). Everything else (hand
checks, identities, other methods, diagnostics) runs and is recorded but carries no verdict. The validation map
(`docs/VALIDATION_GUIDELINE.md` §0) shows only the cases with a verdict; the others are listed in
`docs/NO_VERDICT_CASES.md`.
"""

# ╔═╡ 1a49d0b8-70f7-524a-8a4c-9e64586c537f
begin
    import Pkg
    # Use the PAIN package environment (this turns off Pluto's own package manager for this notebook).
    # PAIN_JL lets the headless check run a copy of this notebook from a temp folder.
    Pkg.activate(get(ENV, "PAIN_JL", joinpath(@__DIR__, "..", "PAIN.jl")); io=devnull)
    using PAIN, CairoMakie, Printf
end

# ╔═╡ dfc271e6-dc85-5c3a-94ed-d30c00ea81f8
let
    rec = recorded_case_errors()
    on = [id for id in VALIDATION_CASE_ORDER if on_validation_map(id; rec)]
    met = count(id -> rec[id].verdict == "met", on)
    md"From the recorded snapshot: **$(length(VALIDATION_CASE_ORDER))** registered cases; **$(length(on))** on the map ($met met, $(length(on) - met) not met); $(length(VALIDATION_CASE_ORDER) - length(on)) without a verdict."
end

# ╔═╡ 3182cd15-08eb-588a-88db-4f1809f54e4a
md"""
## Run one case

Pick a case id. `R172428_CODE` runs NASA's own inputs for the test article (CR-172428 App. B) and compares with what
NASA's program printed: a P case. `APPB_EPS_N` compares one intermediate value per cabin mode with NASA's printout.
`R996_FIG10_FLAT` compares the blocking model with a measured wall (E).
"""

# ╔═╡ f7237b49-d4d6-5c54-9d21-99840b5d2091
case_id = "R172428_CODE"

# ╔═╡ 79fec961-d98a-5a4a-9df9-3257b4bbded1
begin
    case = VALIDATION_CASES[case_id]
    result = run_validation_case(case_id)
    Markdown.parse("""
    **$(case.title)**

    *Criterion ($(case.criterion_date)):* $(case.criterion_text)

    *Verdict:* **$(replace(String(result.verdict), "_" => " "))** — $(result.reason)
    """)
end

# ╔═╡ f6140d56-b181-5371-968a-97308c357493
md"""
## Its table

One row per compared point: the reference value, this code's value, the difference, and whether it is within the
criterion.
"""

# ╔═╡ 74634bac-ccfa-5c63-b16a-6fe98b195fc8
let
    rows = ["| $(r.quantity) | $(@sprintf("%.4g", r.reference)) | $(@sprintf("%.4g", r.computed)) | $(@sprintf("%+.3g", r.residual)) | $(r.within_tolerance ? "yes" : "no") |"
            for r in result.table]
    Markdown.parse("| point | reference | this code | difference | within |\n|---|---|---|---|---|\n" * join(rows, "\n"))
end

# ╔═╡ 2b12909f-822e-5562-bdb1-116ad7b1625c
let
    fig = Figure(size=(800, 340))
    ax = Axis(fig[1, 1]; xlabel=case.plot_spec.xlabel, ylabel=case.plot_spec.ylabel, title=case_id)
    for s in result.series
        if s.kind in (:reference_points, :measured_points, :computed_points)
            scatter!(ax, s.x, s.y; label=s.name)
        else
            scatterlines!(ax, s.x, s.y; label=s.name)
        end
    end
    Legend(fig[1, 2], ax)
    fig
end

# ╔═╡ 9788329c-9237-568d-8dce-aa0910948a62
md"""
## A diagnostic

A diagnostic re-runs a case with one thing changed, to test a possible cause of its miss. It carries no verdict, but its
outcome is kept: `underlying_verdict` returns it. `R172428_CODE_ETAN` re-runs R172428_CODE with each cabin mode's loss
factor taken per mode (Phase 89); it reached 5 of 9 points, short of the 7 needed, so the change was not adopted.
"""

# ╔═╡ 35796615-a6b5-55dc-a82e-b300acb0b5d0
let
    d = run_validation_case("R172428_CODE_ETAN")
    md"`R172428_CODE_ETAN`: verdict **$(d.verdict)**, the check itself **$(PAIN.underlying_verdict(d))**, $(count(r -> r.within_tolerance, d.table)) of $(length(d.table)) points within ±3 dB."
end

# ╔═╡ dcade71c-d3a9-56e0-b127-9a9756cbfd16
md"""
## Where to read more

* `docs/VALIDATION_GUIDELINE.md` §2.13: the record of every case (what it tests, why, its recorded outcome).
* §2.14: why each not-met case misses (classes M, A, I, N, D).
* `docs/COMPLETED_PHASES.md`: how each check was planned, with its criteria dated before the run.
"""

# ╔═╡ Cell order:
# ╟═740ecce7-4406-5223-82bb-7be425366131
# ╠═1a49d0b8-70f7-524a-8a4c-9e64586c537f
# ╠═dfc271e6-dc85-5c3a-94ed-d30c00ea81f8
# ╟═3182cd15-08eb-588a-88db-4f1809f54e4a
# ╠═f7237b49-d4d6-5c54-9d21-99840b5d2091
# ╠═79fec961-d98a-5a4a-9df9-3257b4bbded1
# ╟═f6140d56-b181-5371-968a-97308c357493
# ╠═74634bac-ccfa-5c63-b16a-6fe98b195fc8
# ╠═2b12909f-822e-5562-bdb1-116ad7b1625c
# ╟═9788329c-9237-568d-8dce-aa0910948a62
# ╠═35796615-a6b5-55dc-a82e-b300acb0b5d0
# ╟═dcade71c-d3a9-56e0-b127-9a9756cbfd16
