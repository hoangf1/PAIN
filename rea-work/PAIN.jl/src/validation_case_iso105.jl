# Phase 105 — CYL2D's grid rule at any floor angle, against the acoustic-mode lists PAIN printed for CR-172428's
# small-diameter (θ₀ = 62.6°) and narrow-body (θ₀ = 73.7°) aircraft (IMPLEMENTATION_PLAN.md §8au; criterion fixed
# 2026-10-30 before these lists were transcribed). The Merlin list (50°, Phase 103) is recorded alongside, post-hoc.

const _P105_REPORT = "phase105_cyl2d_printed.md"
const _CYL2D_C_PRINTED = 341.0   # CYL2D's own sound speed (Table C-1; Phase 103 D3)

"""
Printed 2-D cabin frequencies of one App. C list: per row with I > 0, f_2D = √(f² − (QΔ)²) with Δ the list's axial
spacing (least squares through its (Q, 0) rows); the printed ε of (0, 0), or half of the (Q ≥ 1, 0) value where (0, 0) is
not printed (Eq. C.11: ε doubles for Q ≥ 1).
"""
function _printed_2d_list(file::AbstractString)
    rows = [split(l, ",") for l in eachline(_r172428_csv(file)) if !startswith(l, "#")][2:end]
    rec = [(; mode=parse(Int, r[1]), f=parse(Float64, r[2]), symm=r[3] == "1", Q=parse(Int, r[4]), I=parse(Int, r[5]),
              eps=parse(Float64, r[7])) for r in rows]
    q0 = [r for r in rec if r.I == 0 && r.Q > 0]
    Δ = sum(r.f * r.Q for r in q0) / sum(r.Q^2 for r in q0)
    r00 = findfirst(r -> r.Q == 0 && r.I == 0, rec)
    eps00 = r00 === nothing ? q0[1].eps / 2 : rec[r00].eps
    pts = [(; r.mode, r.Q, r.I, r.symm, f2d=sqrt(r.f^2 - (r.Q * Δ)^2)) for r in rec if r.I > 0]
    return (; Δ, eps00, eps00_printed=r00 !== nothing, pts)
end

function _run_cyl2d_printed()
    lists = (("small diameter", "appC_smalldia_acoustic_modes.csv", 62.6, 1.145, true),
             ("narrow body", "appC_narrowbody_acoustic_modes.csv", 73.7, 1.875, true),
             ("Merlin IVC (seen, post-hoc)", "appC_merlin_acoustic_modes.csv", 50.0, 0.84, false))
    table = ValidationTableRow[]; series = PlotSeries[]; met = true; notes = String[]
    for (k, (name, file, θ0, a, held)) in enumerate(lists)
        p = _printed_2d_list(file)
        cy = cyl2d_modes_solvable(θ0; n_modes=20, NY=10, c0=_CYL2D_C_PRINTED, node_tol=0.45)   # the rule under test
        f = Dict(m.index => m.f_Hz_unit / a for m in cy.modes); sy = Dict(m.index => m.symmetric for m in cy.modes)
        e0 = cy.modes[1].eps_n
        ok_e = abs(e0 / p.eps00 - 1) ≤ 2e-4
        push!(table, ValidationTableRow("$name: ε(0,0)$(p.eps00_printed ? "" : " (printed ε(1,0)/2)")", 0, p.eps00, e0,
                                        e0 - p.eps00, ok_e, name))
        nf = 0; nok = 0; ns = 0
        for q in p.pts
            haskey(f, q.I) || continue
            okf = abs(f[q.I] / q.f2d - 1) ≤ 1e-3; oks = sy[q.I] == q.symm
            nf += 1; nok += okf; ns += oks
            push!(table, ValidationTableRow("$name: mode $(q.mode) (Q=$(q.Q), I=$(q.I)) 2-D frequency (Hz)", q.I, q.f2d, f[q.I],
                                            f[q.I] - q.f2d, okf && oks, name))
        end
        held && (met &= ok_e && nok == nf && ns == nf)
        push!(notes, "$name (θ₀ $(θ0)°, NY $(cy.NY)): ε $(round(e0; digits=5)) vs $(round(p.eps00; digits=5)); " *
                     "2-D f $nok/$nf within 0.1 %; types $ns/$nf")
        push!(series, PlotSeries("PAIN, $name", :reference_points, Float64[q.I for q in p.pts], [q.f2d for q in p.pts]; panel=k))
        push!(series, PlotSeries("CYL2D, $name", :computed_points, Float64[q.I for q in p.pts], [get(f, q.I, NaN) for q in p.pts]; panel=k))
    end
    return ValidationCaseResult("CYL2D_PRINTED", _today_iso(),
        (; criterion="per held-out aircraft: ε(0,0) within 0.02 %, every printed 2-D frequency within 0.1 % at 341 m/s / a, " *
                     "every mode type equal; met if both aircraft pass", date="2026-10-30", node_tol=0.45, c=_CYL2D_C_PRINTED),
        table, series, met ? :met : :not_met, join(notes, "; "), "V-CODE", joinpath(_VAL_REPORT_DIR, _P105_REPORT))
end

function _iso105_validation_cases()
    return [ValidationCase("CYL2D_PRINTED", "CYL2D grid rule vs PAIN's printed cabin modes of three CR-172428 aircraft (105)", "105",
        [_r172428_csv("appC_smalldia_acoustic_modes.csv"), _r172428_csv("appC_narrowbody_acoustic_modes.csv"),
         _r172428_csv("appC_merlin_acoustic_modes.csv")],
        FigureRef("NASA CR-172428", "App. C pp. 212, 221, 225 (acoustic modes), 210 (decks)", 221),
        "Per held-out aircraft (62.6°, 73.7°): ε(0,0) within 0.02 %, every printed 2-D frequency within 0.1 % of CYL2D at " *
        "341 m/s / a, every mode type equal; met if both pass (fixed 2026-10-30 before the lists were transcribed).",
        "2026-10-30", "V-CODE", _run_cyl2d_printed,
        PlotSpec(; xlabel="2-D mode order I", ylabel="2-D frequency (Hz)",
                 panel_titles=["small diameter (62.6°)", "narrow body (73.7°)", "Merlin IVC (50°, seen)"],
                 error_mode=:relative_pct, error_tol=0.1), "")]
end
