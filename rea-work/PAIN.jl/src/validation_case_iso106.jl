# Phase 106 — cabin-mode frequencies with CYL2D's 2-D part at 341 m/s and the axial part at the deck's c, against the
# cabin modes PAIN printed (IMPLEMENTATION_PLAN.md §8av; criterion fixed 2026-10-30). Held out: CR-172428 App. B p. 185
# (48 modes; two rows were seen in Phase 103). Recorded alongside, seen (post-hoc): the Merlin list (App. C p. 212) and
# run 10's printed cabin frequencies (App. D pp. 235–236).

const _P106_REPORT = "phase106_cabin_freq_printed.md"

function _run_cabin_freq_printed()
    table = ValidationTableRow[]; n_ok = 0; n = 0; n_old = 0
    ok(ours, ref) = abs(ours - ref) ≤ max(0.02, 2e-4 * ref)
    # held out: App. B (test article, 4000 rpm deck: c = 343 m/s, L_c = 1.829 m, a = 0.508 m, θ₀ = 56.6°, NY = 10)
    inp = r172428_inputs(4000)
    c = _read_csv_numeric_nan(_r172428_csv("appB_acoustic_modes.csv"))
    xs = Float64[]; ref = Float64[]; got = Float64[]
    for k in eachindex(c[:mode])
        f = c[:f_Hz][k]; f > 0 || continue
        q, I = Int(c[:Q][k]), Int(c[:I][k]); ac = _acmode_by_I(inp, I)
        ours = cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, q; c0=inp.c_int, c2d=inp.c_cyl2d)
        old = cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, q; c0=inp.c_int, c2d=inp.c_int)
        g = ok(ours, f); n_ok += g; n += 1; n_old += ok(old, f)
        push!(xs, c[:mode][k]); push!(ref, f); push!(got, ours)
        push!(table, ValidationTableRow("App. B mode $(Int(c[:mode][k])) (Q=$q, I=$I) (Hz)", c[:mode][k], f, ours, ours - f, g, "App. B (held out)"))
    end
    # seen (post-hoc): the Merlin list, its L_c from the printed (1, 0) row, and run 10's printed cabin modes
    m_ok = 0; m_n = 0
    ac50 = cyl2d_modes(50.0; n_modes=20, NY=11, c0=343.0, node_tol=0.45)          # NASA's printed Merlin grid (Phase 105)
    mrows = [split(l, ",") for l in eachline(_r172428_csv("appC_merlin_acoustic_modes.csv")) if !startswith(l, "#")][2:end]
    Δ = only(parse(Float64, r[2]) for r in mrows if r[4] == "1" && r[5] == "0"); Lc_c = 343.0 / (2Δ)
    for (lab, Lc, rows) in (("App. C Merlin list", Lc_c, [(parse(Int, r[4]), parse(Int, r[5]), parse(Float64, r[2])) for r in mrows]),
                            ("run 10 printed pairs", 7.89, unique([(parse(Int, r[6]), parse(Int, r[7]), parse(Float64, r[5]))
                                for r in (split(l, ",") for l in eachline(_r172428_csv("appD_run10_pairs.csv")) if !startswith(l, "#"))
                                if r[1] != "H"])))
        for (q, I, f) in rows
            f > 0 || continue
            ours = cabin_frequency_3d(only(m for m in ac50.modes if m.index == I), 0.84, Lc, q; c0=343.0)
            tol = lab == "run 10 printed pairs" ? 0.051 : max(0.02, 2e-4 * f)         # run 10 prints 0.1 Hz
            g = abs(ours - f) ≤ tol; m_ok += g; m_n += 1
            push!(table, ValidationTableRow("$lab (Q=$q, I=$I) (Hz)", I, f, ours, ours - f, g, "$lab (seen, post-hoc)"))
        end
    end
    series = [PlotSeries("PAIN, App. B p. 185", :reference_points, xs, ref; panel=1),
              PlotSeries("this code (2-D part at 341 m/s)", :computed_points, xs, got; panel=1)]
    return ValidationCaseResult("CABIN_FREQ_PRINTED", _today_iso(),
        (; criterion="|ours − printed| ≤ 0.02 Hz or 0.02 % (the larger) at every printed App. B cabin mode with f > 0",
           date="2026-10-30", n_ok, n, n_old, m_ok, m_n),
        table, series, n > 0 && n_ok == n ? :met : :not_met,
        "App. B: $n_ok/$n printed cabin frequencies reproduced (2-D part at 341 m/s; $n_old/$n with both parts at 343 m/s, " *
        "the form before Phase 106); seen, post-hoc: Merlin list and run 10 $m_ok/$m_n",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P106_REPORT))
end

function _iso106_validation_cases()
    return [ValidationCase("CABIN_FREQ_PRINTED", "Cabin-mode frequencies with CYL2D's 2-D part at 341 m/s vs PAIN's printed lists (106)", "106",
        [_r172428_csv("appB_acoustic_modes.csv"), _r172428_csv("appC_merlin_acoustic_modes.csv"), _r172428_csv("appD_run10_pairs.csv")],
        FigureRef("NASA CR-172428", "App. B p. 185 (held out); App. C p. 212, App. D pp. 235–236 (seen)", 185),
        "|ours − printed| ≤ 0.02 Hz or 0.02 % (the larger) at every printed App. B cabin mode with f > 0 (fixed 2026-10-30).",
        "2026-10-30", "V-CODE", _run_cabin_freq_printed,
        PlotSpec(; xlabel="App. B mode number", ylabel="cabin-mode frequency (Hz)", panel_titles=["CABIN_FREQ_PRINTED"],
                 error_mode=:relative_pct, error_tol=0.02), "")]
end
