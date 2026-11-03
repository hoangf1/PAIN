# Phase 101a — the MRP solver on NASA's Merlin IVC deck (CR-172428 App. C) against PAIN's printed structural-mode list
# for that aircraft, the modal file of flight-test run 10 (IMPLEMENTATION_PLAN.md §8aq; criterion fixed 2026-10-30 before
# the run). P case: PAIN's own inputs (the printed MRP deck) and PAIN's own output (the printed list).

const _P101_REPORT = "phase101_flight_run10.md"

"""NASA's MRP deck for the Merlin IVC (`data/cr172428/appC_merlin_mrp_deck.csv`, App. C pp. 204–205)."""
merlin_mrp_deck() = appd_nasa_deck(_r172428_csv("appC_merlin_mrp_deck.csv"))

"""Rows of a transcribed App. C structural-mode list, columns found by header name."""
function _appc_mode_rows(file::AbstractString)
    ls = [l for l in eachline(_r172428_csv(file)) if !startswith(l, "#")]
    h = Dict(k => i for (i, k) in enumerate(split(ls[1], ",")))
    rows = [split(l, ",") for l in ls[2:end]]
    col(k, T) = [parse(T, r[h[k]]) for r in rows]
    return (; mode=col("mode", Int), f_Hz=col("f_Hz", Float64), M=col("M", Int), M_total_kg=col("M_total_kg", Float64),
              types=[r[h["type"]] for r in rows], rows, h)
end

"""101a: each printed mode against the solver mode of the same symmetry and axial order M nearest in frequency.
`file`/`id`: Phase 110 re-runs it on the checked transcription (FLIGHT_MODES_P2, post-hoc)."""
function _run_flight_modes(; file::AbstractString="appC_merlin_structural_modes.csv", id::AbstractString="FLIGHT_MODES")
    c = _appc_mode_rows(file)
    types = c.types
    ms = appd_modes(merlin_mrp_deck(); n_modes=400, n_axial=10, n_circ=14, n_floor_max=5).modes
    table = ValidationTableRow[]; n_ok = 0; nf = 0; dfs = Float64[]
    for i in eachindex(c.mode)
        f = c.f_Hz[i]; sym = types[i] == "S"; M = c.M[i]; m = c.M_total_kg[i]
        cand = [x for x in ms if x.symmetric == sym && x.M_axial == M]
        x = cand[argmin([abs(y.f_Hz - f) for y in cand])]
        df = x.f_Hz / f - 1; dm = x.M_r / m - 1
        ok = abs(df) ≤ 0.02 && abs(dm) ≤ 0.10
        n_ok += ok; nf += abs(df) ≤ 0.02; push!(dfs, abs(df))
        push!(table, ValidationTableRow("mode $(c.mode[i]) ($(types[i]), M = $M) at $(f) Hz: generalized mass " *
                                        "(residual = relative difference; ours $(round(x.f_Hz; digits=2)) Hz)", f, m, x.M_r, dm, ok,
                                        sym ? "symmetric modes" : "antisymmetric modes"))
    end
    n = length(table)
    series = [PlotSeries("PAIN, App. C (printed)", :reference_points, c.f_Hz, c.M_total_kg; panel=1),
              PlotSeries("this code, NASA's MRP deck", :computed_points, c.f_Hz, [r.computed for r in table]; panel=1)]
    pc(x) = round(100x; digits=1)
    return ValidationCaseResult(id, _today_iso(),
        (; criterion="f_r within 2 % and generalized mass within 10 % for ≥ 90 % of the listed modes up to 1 kHz", date="2026-10-30",
           n_ok, n, n_freq=nf, median_df_pct=pc(sort(dfs)[cld(n, 2)])),
        table, series, n_ok ≥ 0.9n ? :met : :not_met,
        "$n_ok/$n listed modes ($(pc(n_ok / n)) %) within 2 % in frequency and 10 % in generalized mass (criterion ≥ 90 %); " *
        "$nf/$n within 2 % in frequency alone (median $(pc(sort(dfs)[cld(n, 2)])) %)",
        "V-CODE", joinpath(_VAL_REPORT_DIR, id == "FLIGHT_MODES" ? _P101_REPORT : "phase110_flight_modes_pass2.md"))
end

"""
Shell and plate normal-displacement parts of a mode's generalized mass (Phase 110): m_s ∫ψ_s² dA over the whole shell and
m_p ∫ψ_p² dA over the floor (L/2 from the axial sin²), with the mode's stored coefficients.
"""
function _mode_mass_parts(st::StructuralMode, g::AbstractAppDInput; nx::Int=2000)
    fuse = FuselageGeometry(g.L, g.a, g.theta0_deg)
    ms, mp = _appd_shell_props(g).ms, _appd_floor_props(g).mf
    Lp = 2g.a * sin(deg2rad(g.theta0_deg))
    acc = 0.0
    for j in 1:nx
        x = -Lp / 2 + Lp * (j - 0.5) / nx
        w = 0.0
        for (C, p) in zip(st.C_floor, st.n_floor)
            w += st.symmetric ? C * cos(p * π * x / Lp) : C * sin(p * π * x / Lp)
        end
        acc += w^2
    end
    return (; shell=trimmed_modal_mass(st, fuse, ms), plate=mp * acc * Lp / nx * g.L / 2)
end

function _iso101_validation_cases()
    return [ValidationCase("FLIGHT_MODES", "MRP solver on NASA's Merlin IVC deck vs PAIN's printed mode list (101a)", "101",
        [_r172428_csv("appC_merlin_mrp_deck.csv"), _r172428_csv("appC_merlin_structural_modes.csv")],
        FigureRef("NASA CR-172428", "App. C pp. 204–205 (deck), 213–216 (modes)", 213),
        "f_r within 2 % and generalized mass within 10 % for ≥ 90 % of the listed modes up to 1 kHz (fixed 2026-10-30, before the run).",
        "2026-10-30", "V-CODE", _run_flight_modes,
        PlotSpec(; xlabel="frequency (Hz)", ylabel="generalized mass (kg)", panel_titles=["FLIGHT_MODES"], error_mode=:relative_pct,
                 error_tol=10.0, xscale=:log10, yscale=:log10), ""),
        ValidationCase("FLIGHT_MODES_P2", "FLIGHT_MODES re-run on the checked App. C transcription (110, post-hoc)", "110",
        [_r172428_csv("appC_merlin_mrp_deck.csv"), _r172428_csv("appC_merlin_structural_modes_checked.csv")],
        FigureRef("NASA CR-172428", "App. C pp. 213–216 (modes, second pass)", 213),
        "FLIGHT_MODES' criterion (fixed 2026-10-30) on the checked transcription; diagnostic, post-hoc (no verdict).",
        "2026-10-30", "V-CODE", () -> _run_flight_modes(; file="appC_merlin_structural_modes_checked.csv", id="FLIGHT_MODES_P2"),
        PlotSpec(; xlabel="frequency (Hz)", ylabel="generalized mass (kg)", panel_titles=["FLIGHT_MODES_P2"], error_mode=:relative_pct,
                 error_tol=10.0, xscale=:log10, yscale=:log10), "")]
end
