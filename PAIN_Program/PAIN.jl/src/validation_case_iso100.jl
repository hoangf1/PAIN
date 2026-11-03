# Phase 100 — NASA's per-band PF-105 input table (CR-172428 App. D deck, cards 22–33) against the trim admittances App. B
# p. 197 prints (IMPLEMENTATION_PLAN.md §8ap; predictions fixed 2026-10-30 before the run). Diagnostic: it decides which
# insulation table `r172428_inputs` takes; the held-out verdicts are R172428_ETAT2 and APPB_ETA_N_T2_BAND.

const _P100_REPORT = "phase100_pf105_deck.md"

"""Sidewall and end-cap admittance at App. B's bands with the given insulation table; counts within 10 %."""
function _appb_admittance_rows(insulation::Symbol)
    c = _read_csv_numeric_nan(_r172428_csv("appB_trim.csv"))
    inp = r172428_inputs(4000; insulation)
    f0 = first((insulation === :deck ? pf105_deck_table() : pf105_table()).f_Hz)
    rows = NamedTuple[]
    for i in eachindex(c[:f_Hz])
        f = c[:f_Hz][i]
        f < f0 && continue
        ω = 2π * f
        β = trim_admittance(inp.sidewall, ω, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int)
        βe = trim_admittance(inp.endplates, ω, Inf; ρ0=inp.ρ_int, c0=inp.c_int)
        for (q, ours, nasa) in (("sidewall Re β", real(β), c[:side_adm_re][i]), ("sidewall Im β", imag(β), c[:side_adm_im][i]),
                                ("end-cap Re β", real(βe), c[:end_adm_re][i]), ("end-cap Im β", imag(βe), c[:end_adm_im][i]))
            push!(rows, (; q, f, ours, nasa, rel=ours / nasa - 1))
        end
    end
    return rows
end

"""100a (diagnostic): the deck table against App. B p. 197, with the two predictions fixed before the run."""
function _run_r172428_trim_deck()
    deck = _appb_admittance_rows(:deck); fig = _appb_admittance_rows(:fig_a2)
    table = [ValidationTableRow("$(r.q) at $(Int(r.f)) Hz (deck table; residual = relative difference)", r.f, r.nasa, r.ours,
                                r.rel, abs(r.rel) ≤ 0.10) for r in deck]
    pick(rows, q, f) = only(r for r in rows if r.q == q && r.f == f)
    p1 = pick(deck, "sidewall Re β", 200.0); p2 = pick(deck, "end-cap Im β", 1600.0)
    ok1 = abs(p1.rel) ≤ 0.10; ok2 = abs(p2.rel) ≤ 0.15
    nd = count(r -> abs(r.rel) ≤ 0.10, deck); nf = count(r -> abs(r.rel) ≤ 0.10, fig)
    side(rows) = [r for r in rows if r.q == "sidewall Re β"]
    series = [PlotSeries("NASA App. B p. 197, sidewall Re β", :reference_points, [r.f for r in side(deck)], [r.nasa for r in side(deck)]; panel=1),
              PlotSeries("deck table (App. D)", :computed, [r.f for r in side(deck)], [r.ours for r in side(deck)]; panel=1),
              PlotSeries("Fig. A-2 markers, interpolated", :computed, [r.f for r in side(fig)], [r.ours for r in side(fig)]; panel=1)]
    pc(x) = round(100x; digits=1)
    return ValidationCaseResult("R172428_TRIM_DECK", _today_iso(),
        (; criterion="predictions: sidewall Re β at 200 Hz within 10 %, end-cap Im β at 1600 Hz within 15 % (fixed 2026-10-30)",
           date="2026-10-30", p200=pc(p1.rel), p1600=pc(p2.rel), n_deck=nd, of_deck=length(deck), n_fig=nf, of_fig=length(fig)),
        table, series, :no_verdict,
        "diagnostic (H_deck $(ok1 && ok2 ? "supported" : "not supported")): sidewall Re β at 200 Hz $(pc(p1.rel)) %, end-cap Im β at " *
        "1600 Hz $(pc(p2.rel)) %; $nd/$(length(deck)) admittance values within ±10 % with the deck table " *
        "($nf/$(length(fig)) with the Fig. A-2 markers, 100–5000 Hz)",
        "V-CODE (diagnostic)", joinpath(_VAL_REPORT_DIR, _P100_REPORT))
end

function _iso100_validation_cases()
    return [ValidationCase("R172428_TRIM_DECK", "NASA's per-band PF-105 table (App. D deck) vs App. B trim admittances (100a)", "100",
        [_r172428_csv("appD_pf105_deck.csv"), _r172428_csv("appB_trim.csv")], FigureRef("NASA CR-172428", "App. D p. 229 deck; App. B p. 197", 197),
        "Predictions (fixed 2026-10-30, before the run): sidewall Re β at 200 Hz within 10 % and end-cap Im β at 1600 Hz within 15 % of App. B. Diagnostic, no verdict.",
        "2026-10-30", "V-CODE", _run_r172428_trim_deck,
        PlotSpec(; xlabel="frequency (Hz)", ylabel="sidewall Re β", panel_titles=["R172428_TRIM_DECK"], error_mode=:relative,
                 error_tol=0.10, xscale=:log10), "")]
end
