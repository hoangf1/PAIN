# Phases 87–88 — the differences from NASA's corrected program (IMPLEMENTATION_PLAN.md §8ae; criteria fixed 2026-10-29
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
    f = cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, q; c0=inp.c_int)
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
    ωn = 2π * cabin_frequency_3d(ac, a, inp.L_c, q; c0=inp.c_int); ωr = 2π * st.f_Hz
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

const _P88_REPORT = "phase88_q0_held_out.md"

"""88a: REPRO_18b_PRE (all three App. A changes reverted) with the q = 0 cabin modes uncoupled, against E-16's NASA prediction."""
function _run_q0_repro_18b()
    cols = _read_csv_numeric(_data_path("cr3813", "t1_interior_targets.csv"))
    paths = default_e11_paths(); p3 = phase3_trim(; η_lining=0.5)
    r = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3, bpf_Hz=200.0,
                          blocking=R1, sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends, mech=p3.mech)
    pre = _pre_correction_form(r.inputs)
    got = interior_spl(_with_fields(pre; q0_coupled=false); bpf_Hz=200.0, n_harmonics=3, broadband=false).harmonic_SPL_dB
    base = interior_spl(pre; bpf_Hz=200.0, n_harmonics=3, broadband=false).harmonic_SPL_dB
    table = ValidationTableRow[]; n_ok = 0; xs = Float64[]; nasa = Float64[]
    for i in eachindex(cols[:harmonic])
        H = Int(round(cols[:harmonic][i])); H ≤ 3 || continue
        ref = cols[:nasa_pain_pred_dB][i]; band = cols[:band_Hz][i]
        ok = abs(got[H] - ref) ≤ 4.0; n_ok += ok
        push!(xs, band); push!(nasa, ref)
        push!(table, ValidationTableRow("vs NASA PAIN H=$H (pre-correction form, q = 0 uncoupled)", band, ref, got[H], got[H] - ref, ok))
    end
    series = [PlotSeries("NASA PAIN (E-16)", :reference_points, xs, nasa; panel=1),
              PlotSeries("pre-correction form, q = 0 uncoupled", :computed, xs, got[1:3]; panel=1),
              PlotSeries("pre-correction form (REPRO_18b_PRE)", :computed, xs, base[1:3]; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("Q0_REPRO_18b", _today_iso(),
        (; criterion="|Δ| ≤ 4 dB at H1–H3 vs E-16 NASA prediction (REPRO_18b's)", date="2026-10-29",
           got=r2(got[1:3]), q0_coupled=r2(base[1:3]), nasa, n_ok),
        table, series, n_ok == 3 ? :met : :not_met,
        "$n_ok/3 within ±4 dB with q = 0 uncoupled: $(r2(got[1:3])) dB vs NASA $(nasa) (q = 0 coupled: $(r2(base[1:3])))",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P88_REPORT))
end

"""88b: E18_TONES's run in the pre-correction form with the q = 0 cabin modes uncoupled, against E-18's NASA prediction."""
function _run_q0_e18()
    cols = _read_csv_numeric_nan(_data_path("cr3813", "e18_interior_pred_eta1.csv"))
    nasa_of = Dict(cols[:band_Hz][i] => cols[:nasa_pred_dB][i] for i in eachindex(cols[:band_Hz]))
    paths = default_e11_paths(); p3 = phase3_trim(; η_lining=1.0)
    r = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3, bpf_Hz=200.0,
                          blocking=R1, sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends, mech=p3.mech)
    pre = _pre_correction_form(r.inputs)
    spl(inp) = interior_spl(inp; bpf_Hz=200.0, n_harmonics=3, broadband=false, tone_model=:eq8, η_r_cap=0.15).harmonic_SPL_dB
    got = spl(_with_fields(pre; q0_coupled=false)); base = spl(pre)
    table = ValidationTableRow[]; n_ok = 0; xs = Float64[]; ref = Float64[]
    for (H, band) in ((1, 200.0), (2, 400.0), (3, 630.0))
        nasa = get(nasa_of, band, NaN); isfinite(nasa) || continue
        ok = abs(got[H] - nasa) ≤ 4.0; n_ok += ok
        push!(xs, band); push!(ref, nasa)
        push!(table, ValidationTableRow("vs NASA E-18 H=$H (pre-correction form, q = 0 uncoupled)", band, nasa, got[H], got[H] - nasa, ok))
    end
    n = length(xs)
    series = [PlotSeries("NASA E-18 pred", :reference_points, xs, ref; panel=1),
              PlotSeries("pre-correction form, q = 0 uncoupled", :computed, xs, got[1:n]; panel=1),
              PlotSeries("pre-correction form, q = 0 coupled", :computed, xs, base[1:n]; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("Q0_E18", _today_iso(),
        (; criterion="|Δ| ≤ 4 dB vs NASA E-18 prediction per harmonic (E18_TONES's)", date="2026-10-29",
           got=r2(got[1:n]), q0_coupled=r2(base[1:n]), nasa=ref, n_ok, n),
        table, series, n > 0 && n_ok == n ? :met : :not_met,
        "$n_ok/$n within ±4 dB with q = 0 uncoupled: $(r2(got[1:n])) dB vs NASA $(ref) (q = 0 coupled: $(r2(base[1:n])))",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P88_REPORT))
end

"""88c: E21_PRE with the q = 0 cabin modes uncoupled, against E-21's NASA prediction (E21_PRE's counted bands)."""
function _run_q0_e21()
    e21 = _read_csv_numeric_nan(_data_path("cr3813", "e21_noise_reduction_range.csv"))
    bands = Float64.(e21[:band_Hz]); nasa = Float64.(e21[:nasa_pred_dB])
    excluded = Set([80.0, 100.0, 125.0, 160.0])
    pre = _pre_correction_form(noise_reduction_test_article_inputs(; η_lining=1.0))
    q0 = noise_reduction_spectrum(_with_fields(pre; q0_coupled=false); bands, η_r_cap=0.15)
    base = noise_reduction_spectrum(pre; bands, η_r_cap=0.15)
    table = ValidationTableRow[]; n_ok = 0; n = 0; xs = Float64[]; ref = Float64[]; g1 = Float64[]; g0 = Float64[]
    for i in eachindex(bands)
        fc = bands[i]; isfinite(nasa[i]) || continue
        g = q0.rows[i].NR_dB
        counted = !(fc in excluded) && !q0.rows[i].above_crossover
        ok = abs(g - nasa[i]) ≤ 3.0
        counted && (n += 1; n_ok += ok)
        push!(xs, fc); push!(ref, nasa[i]); push!(g1, g); push!(g0, base.rows[i].NR_dB)
        push!(table, ValidationTableRow("NR fc=$(round(Int, fc))" * (counted ? "" : " (not counted)"), fc, nasa[i], g, g - nasa[i],
                                        ok, counted ? "counted" : "not counted"))
    end
    series = [PlotSeries("NASA prediction (E-21)", :reference_points, xs, ref; panel=1),
              PlotSeries("pre-correction form, q = 0 uncoupled", :computed, xs, g1; panel=1),
              PlotSeries("pre-correction form (E21_PRE)", :computed, xs, g0; panel=1)]
    return ValidationCaseResult("Q0_E21", _today_iso(),
        (; criterion="|Δ| ≤ 3 dB of NASA's prediction in ≥ 75 % of counted bands (E21_PRE's)", date="2026-10-29", n_ok, n),
        table, series, n > 0 && n_ok / n ≥ 0.75 - 1e-12 ? :met : :not_met,
        "$n_ok/$n counted bands within ±3 dB of NASA with q = 0 uncoupled (pre-correction form)",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P88_REPORT))
end

"""89b: R172428_CODE with η_n per cabin mode (trim per 1/3-octave band), the Phase 89 reading H1; diagnostic."""
_run_r172428_code_etan() = _run_r172428_vs(:code; η_n_per_mode=true)

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
        mk("APPB_ETA_N", "Cabin-mode η_n vs NASA's App. B printout (87b)", "87", [ac],
           FigureRef("NASA CR-172428", "App. B p. 195", 195),
           "|η_n/NASA − 1| ≤ 2 % at every printed cabin mode at or above 100 Hz (fixed 2026-10-29, before the run).",
           _run_appb_eta_n, "App. B cabin mode number", "η_n", rel(2.0)),
        mk("APPB_ETA_RPP", "Per-pair η_r″ vs NASA's App. B printout (87c)", "87", [ac; pairs],
           FigureRef("NASA CR-172428", "App. B pp. 197, 202", 207),
           "|η_r″/NASA − 1| ≤ 10 % at ≥ 80 % of the printed pairs with η_r″ ≥ 1e-4 (fixed 2026-10-29, before the run).",
           _run_appb_eta_rpp, "printed pair (4000 rpm, then 5000 rpm)", "η_r″", rel(10.0)),
        mk("Q0_REPRO_18b", "q = 0 uncoupled, pre-correction form, vs E-16's NASA prediction (88a)", "88",
           [_data_path("cr3813", "t1_interior_targets.csv")], FigureRef("CR-3813", "Fig. E-16 NASA PAIN pred", 142),
           "|Δ| ≤ 4 dB at H1–H3 against E-16's NASA prediction (REPRO_18b's; fixed 2026-10-29, before the run).",
           _run_q0_repro_18b, "band (Hz)", "SPL (dB)", abs3(4.0)),
        mk("Q0_E18", "q = 0 uncoupled, pre-correction form, vs E-18's NASA prediction (88b)", "88",
           [_data_path("cr3813", "e18_interior_pred_eta1.csv")], FigureRef("CR-3813", "Fig. E-18", 145),
           "|Δ| ≤ 4 dB per harmonic against E-18's NASA prediction (E18_TONES's; fixed 2026-10-29, before the run).",
           _run_q0_e18, "band (Hz)", "SPL (dB)", abs3(4.0)),
        mk("Q0_E21", "q = 0 uncoupled, pre-correction form, vs E-21's NASA prediction (88c)", "88",
           [_data_path("cr3813", "e21_noise_reduction_range.csv")], FigureRef("CR-3813", "Fig. E-21", 149),
           "|Δ| ≤ 3 dB of NASA's prediction in ≥ 75 % of the counted bands (E21_PRE's; fixed 2026-10-29, before the run).",
           _run_q0_e21, "band (Hz)", "NR (dB)", abs3(3.0)),
        mk("R172428_CODE_ETAN", "CR-172428 reproduction with η_n per cabin mode vs NASA's printed predictions (89b)", "89",
           [_r172428_csv("appB_predictions.csv"), ac], FigureRef("NASA CR-172428", "App. B pp. 196–212 / Table 10", 206),
           "±3 dB of NASA's printed prediction at ≥ 7 of 9 points (R172428_CODE's; decision fixed 2026-10-29, before the run).",
           _run_r172428_code_etan, "tone frequency (Hz)", "SPL (dB)", abs3(3.0)),
    ]
end
