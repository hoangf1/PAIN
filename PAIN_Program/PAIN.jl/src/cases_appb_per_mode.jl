# Phases 87–88 — the differences from NASA's corrected program (COMPLETED_PHASES.md §8ae; criteria fixed 2026-10-29
# before any run). 87: NASA's printed per-mode values of CR-172428 App. B (cabin-mode ε_n and η_n, p. 195; per-pair η_r″,
# pp. 197/202) against this code's on CR-172428's inputs (P cases). 88: the q = 0 hypothesis (NASA's program left the
# q = 0 cabin modes uncoupled) on CR-3813's printed runs, which played no part in forming it (diagnostics).

const _P87_REPORT = "phase87_appb_per_mode.md"

"""Cabin mode of `inp` with 2-D index `I` (CYL2D order, as App. B's I column)."""
_acmode_by_I(inp::PainInputs, I::Integer) = inp.acoustic.modes[findfirst(m -> m.index == I, inp.acoustic.modes)]

"""
η_n of cabin mode (ac, q) at its own frequency with the trim of `inp` (Eq. 77), as App. B prints it; `NaN` below 100 Hz,
where the Fig. A-2 insulation table has no data.
"""
function _eta_n_at_mode(inp::PainInputs, ac, q::Integer; V::Real=cabin_volume(inp))
    f = cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, q; c0=inp.c_int, c2d=inp.c_cyl2d)
    f < 100 && return NaN
    ω = 2π * f
    ξ = trim_conductance(inp.sidewall, ω, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int)
    ξe = trim_conductance(inp.endplates, ω, Inf; ρ0=inp.ρ_int, c0=inp.c_int)
    return acoustic_N(inp, ac, q, f, ω; ξ, ξ_e=ξe, V) / ω^2
end

"""87a, 87b: ε_n or η_n of the 48 cabin modes App. B prints, matched by (Q, I); `which` = :eps or :eta."""
function _run_appb_acmode(which::Symbol)
    inp = r172428_inputs(4000)
    ac_tab = _read_csv_numeric_nan(_r172428_csv("appB_acoustic_modes.csv"))
    V = cabin_volume(inp)
    tol = which === :eps ? 0.01 : 0.02
    table = ValidationTableRow[]; xs = Float64[]; ref = Float64[]; got = Float64[]; n_ok = 0; skipped = Int[]
    for k in eachindex(ac_tab[:mode])
        mode = Int(ac_tab[:mode][k]); q = Int(ac_tab[:Q][k]); ac = _acmode_by_I(inp, Int(ac_tab[:I][k]))
        nasa = which === :eps ? ac_tab[:epsilon][k] : ac_tab[:loss_factor][k]
        ours = which === :eps ? cabin_eps_3d(ac, q) : _eta_n_at_mode(inp, ac, q; V)
        (isfinite(ours) && nasa > 0) || (push!(skipped, mode); continue)
        ok = abs(ours / nasa - 1) ≤ tol; n_ok += ok
        push!(xs, mode); push!(ref, nasa); push!(got, ours)
        push!(table, ValidationTableRow("mode $mode (Q=$q, I=$(Int(ac_tab[:I][k])))", mode, nasa, ours, ours - nasa, ok))
    end
    n = length(xs)
    name = which === :eps ? "ε_n" : "η_n"
    id = which === :eps ? "APPB_EPS_N" : "APPB_ETA_N"
    series = [PlotSeries("NASA, App. B p. 195", :reference_points, xs, ref; panel=1),
              PlotSeries("this code", :computed_points, xs, got; panel=1)]
    return ValidationCaseResult(id, _today_iso(),
        (; criterion="|ours/NASA − 1| ≤ $(round(Int, 100tol)) % at every mode", date="2026-10-29", n_ok, n, skipped),
        table, series, n > 0 && n_ok == n ? :met : :not_met,
        "$n_ok/$n cabin modes with $name within $(round(Int, 100tol)) % of NASA's printed value" *
        (isempty(skipped) ? "" : "; modes $(join(skipped, ", ")) not compared (below 100 Hz or printed 0)"),
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P87_REPORT))
end

_run_appb_eps_n() = _run_appb_acmode(:eps)
_run_appb_eta_n() = _run_appb_acmode(:eta)

"""
η_r″ term of Eq. (83) for one cabin mode (ac, q) and structural mode `st`, as `tone_mean_square_pressure` forms it:
the bare f′ (τ = 1) and N at the tone frequency `f_H`.
"""
function _eta_r_pp_pair(inp::PainInputs, ac, q::Integer, st, f_H::Real; V::Real=cabin_volume(inp))
    a, L = inp.fuse.a, inp.fuse.L; θ0 = deg2rad(inp.fuse.theta0_deg)
    A = L * (2a * sin(θ0) + 2a * (π - θ0))
    ωH = 2π * f_H
    ωn = 2π * cabin_frequency_3d(ac, a, inp.L_c, q; c0=inp.c_int, c2d=inp.c_cyl2d); ωr = 2π * st.f_Hz
    ξ = trim_conductance(inp.sidewall, ωH, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int)
    ξe = trim_conductance(inp.endplates, ωH, Inf; ρ0=inp.ρ_int, c0=inp.c_int)
    N = acoustic_N(inp, ac, q, f_H, ωn; ξ, ξ_e=ξe, V)
    fp = coupling_factor(ac, st, inp; τ_t=1.0, q)
    return inp.ρ_int * inp.c_int^2 * A^2 * cabin_eps_3d(ac, q) * fp^2 / (st.M_r * V) * N / ((ωn^2 - ωr^2)^2 + N^2)
end

"""87c: η_r″ of every printed pair with η_r″ ≥ 1e-4 (4000 and 5000 rpm lists) against this code's."""
function _run_appb_eta_rpp()
    table = ValidationTableRow[]; xs = Float64[]; ref = Float64[]; got = Float64[]; n_ok = 0; k = 0
    for (rpm, file) in ((4000, "appB_contributors_4000rpm.csv"), (5000, "appB_contributors_5000rpm.csv"))
        inp = r172428_inputs(rpm); V = cabin_volume(inp)
        c = _read_csv_numeric_nan(_r172428_csv(file))
        for i in eachindex(c[:H])
            nasa = c[:eta_r_hash][i]
            nasa < 1e-4 && continue            # printed to one significant digit
            q = Int(c[:Q][i]); r = Int(c[:st_mode][i])
            ours = _eta_r_pp_pair(inp, _acmode_by_I(inp, Int(c[:I][i])), q, inp.structural.modes[r], c[:f_Hz][i]; V)
            ok = abs(ours / nasa - 1) ≤ 0.10; n_ok += ok; k += 1
            push!(xs, k); push!(ref, nasa); push!(got, ours)
            push!(table, ValidationTableRow("$rpm rpm H$(Int(c[:H][i])): cabin mode $(Int(c[:ac_mode][i])) × structural mode $r",
                                            k, nasa, ours, ours - nasa, ok))
        end
    end
    series = [PlotSeries("NASA ETA R#, App. B pp. 197/202", :reference_points, xs, ref; panel=1),
              PlotSeries("this code", :computed_points, xs, got; panel=1)]
    return ValidationCaseResult("APPB_ETA_RPP", _today_iso(),
        (; criterion="|ours/NASA − 1| ≤ 10 % at ≥ 80 % of the printed pairs with η_r″ ≥ 1e-4", date="2026-10-29", n_ok, n=k),
        table, series, k > 0 && n_ok / k ≥ 0.8 - 1e-12 ? :met : :not_met,
        "$n_ok/$k printed pairs with η_r″ within 10 % of NASA's",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P87_REPORT))
end

# Phase 150e (2026-11-11): Q0_REPRO_18b, Q0_E18, Q0_E21 and R172428_CODE_ETAN retired (refuted, Phases 88, 89); reports kept.

function _iso87_validation_cases()
    ac = _r172428_csv("appB_acoustic_modes.csv")
    pairs = [_r172428_csv("appB_contributors_4000rpm.csv"), _r172428_csv("appB_contributors_5000rpm.csv")]
    mk(id, title, ph, files, fig, crit, run, xlab, ylab, spec_kw) = ValidationCase(id, title, ph, files, fig, crit, "2026-10-29",
        "V-CODE", run, PlotSpec(; xlabel=xlab, ylabel=ylab, panel_titles=[id], spec_kw...), "")
    rel(tol) = (; error_mode=:relative_pct, error_tol=tol, error_ylabel="ours/NASA − 1 (%)")
    abs3(tol) = (; error_mode=:absolute, error_tol=tol, xscale=:log10)
    return [
        mk("APPB_EPS_N", "Cabin-mode ε_n vs NASA's App. B printout (87a)", "87", [ac],
           FigureRef("NASA CR-172428", "App. B p. 195", 195),
           "|ε_n/NASA − 1| ≤ 1 % at every printed cabin mode (fixed 2026-10-29, before the run).", _run_appb_eps_n,
           "App. B cabin mode number", "ε_n", rel(1.0)),
        mk("APPB_ETA_N", "Cabin-mode η_n vs NASA's App. B printout (87b; CR-3813 printed damping form)", "87", [ac],
           FigureRef("NASA CR-172428", "App. B p. 195", 195),
           "|η_n/NASA − 1| ≤ 2 % at every printed cabin mode at or above 100 Hz (fixed 2026-10-29, before the run).",
           _run_appb_eta_n, "App. B cabin mode number", "η_n", rel(2.0)),
        mk("APPB_ETA_RPP", "Per-pair η_r″ vs NASA's App. B printout (87c)", "87", [ac; pairs],
           FigureRef("NASA CR-172428", "App. B pp. 197, 202", 207),
           "|η_r″/NASA − 1| ≤ 10 % at ≥ 80 % of the printed pairs with η_r″ ≥ 1e-4 (fixed 2026-10-29, before the run).",
           _run_appb_eta_rpp, "printed pair (4000 rpm, then 5000 rpm)", "η_r″", rel(10.0)),
    ]
end
