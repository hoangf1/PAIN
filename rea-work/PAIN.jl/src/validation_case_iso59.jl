# Phase 59 — Sharp sound bridges (NASA CR-172490) in Eq. (23): the source check and the three comparisons.
# Criteria and mapping fixed 2026-10-23 (IMPLEMENTATION_PLAN.md §8g Phase 59) before any run.

const _P59_REPORT = "phase59_60_bridges_modes.md"

function _run_sharp_panel_d()
    t = _read_csv_numeric_nan(_data_path("cr172490", "cr172490_fig15_panelD.csv"))
    m = 2780.0 * 0.0016                                   # 1.6 mm aluminium (Fig. A-7)
    d = 0.0826                                            # 82.6 mm cavity (Fig. A-7)
    table = ValidationTableRow[]; got = Float64[]; n_ok = 0
    for (i, f) in enumerate(t[:f_Hz])
        g = sharp_double_panel_TL(m, m, d, f; ΔTL_M=12.0)
        ok = abs(g - t[:TL_0Pa_dB][i]) ≤ 1.0
        n_ok += ok; push!(got, g)
        push!(table, ValidationTableRow("TL f=$(round(Int, f))", f, t[:TL_0Pa_dB][i], g, g - t[:TL_0Pa_dB][i], ok, "TL"))
    end
    n = length(got); frac = n_ok / n
    # diagnostic (post-hoc, no criterion): ΔTL_M read from the figure, the high-frequency offset over the mass law
    ml = t[:mass_law_dB]
    dTL_fig = sum(t[:TL_0Pa_dB][i] - ml[i] for i in eachindex(ml) if isfinite(ml[i]) && t[:f_Hz][i] ≥ 500) /
              count(i -> isfinite(ml[i]) && t[:f_Hz][i] ≥ 500, eachindex(ml))
    diag = [sharp_double_panel_TL(m, m, d, f; ΔTL_M=dTL_fig) - t[:TL_0Pa_dB][i] for (i, f) in enumerate(t[:f_Hz])]
    series = [PlotSeries("CR-172490 Fig. 15 (Panel D, 0 Pa)", :reference_points, t[:f_Hz], t[:TL_0Pa_dB]; panel=1),
              PlotSeries("Sharp construction, ΔTL_M = 12 dB", :computed, t[:f_Hz], got; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("SHARP_PANEL_D", _today_iso(),
        (; criterion="within 1 dB at ≥ 90 % of the points 50–2000 Hz", date="2026-10-23", f0_Hz=r2(sharp_f0(m, m, d)),
           n_ok, n, frac, dTL_M_from_figure_posthoc=r2(dTL_fig), max_dev_with_figure_dTL_posthoc=r2(maximum(abs, diag))),
        table, series, frac ≥ 0.9 ? :met : :not_met,
        "$n_ok/$n within 1 dB with ΔTL_M = 12 dB as stated; f₀ = $(round(sharp_f0(m, m, d); digits=1)) Hz (stated 142). " *
        "Post-hoc: the figure implies ΔTL_M = $(round(dTL_fig; digits=1)) dB, with which the construction is within $(round(maximum(abs, diag); digits=2)) dB",
        "V-UNIT", joinpath(_VAL_REPORT_DIR, _P59_REPORT))
end

function _run_nr_prop_tp2444_br()
    fcs = [_p47_fc(k) for k in _P47C_K]
    ext, _ = p47_band_levels(:ext, fcs)
    intr, _ = p47_band_levels(:int, fcs)
    inp = r172428_inputs(4000)
    xo = volume_crossover_band(inp)
    table = ValidationTableRow[]; meas = Float64[]; got = Float64[]; n_ok = 0
    for (i, fc) in enumerate(fcs)
        m = ext[i].L_bb - intr[i].L_bb
        g = noise_reduction_band(inp, fc; crossover_fc=xo.fc_Hz, hf_model=:eq19, bridges=true).NR_dB
        ok = abs(g - m) ≤ 5.0; n_ok += ok
        push!(meas, m); push!(got, g)
        push!(table, ValidationTableRow("NR fc=$(round(Int, fc))", fc, m, g, g - m, ok))
    end
    n = length(fcs)
    series = [PlotSeries("measured NR (TP-2444 Fig. 17)", :reference_points, fcs, meas; panel=1),
              PlotSeries("model with Sharp bridges (Eq. 23 bands only)", :computed, fcs, got; panel=1)]
    return ValidationCaseResult("NR_PROP_TP2444_BR", _today_iso(),
        (; criterion="within ±5 dB in ≥ 75 % of bands 315–1250 Hz", date="2026-10-23", NR_model=round.(got; digits=2),
           NR_meas=round.(meas; digits=2), n_ok, n, bridge=bridge_tau(inp, 1259.92)),
        table, series, n_ok / n ≥ 0.75 - 1e-12 ? :met : :not_met,
        "$n_ok/$n bands within ±5 dB (bridges act in the Eq. 23 band, 1260 Hz)", "V-EXP (extension)",
        joinpath(_VAL_REPORT_DIR, _P59_REPORT))
end

function _run_e22_br()
    e22 = _read_csv_numeric_nan(_data_path("cr3813", "e22_noise_reduction_ci.csv"))
    inp = noise_reduction_test_article_inputs(; η_lining=1.0)
    table = ValidationTableRow[]; xs = Float64[]; mid = Float64[]; got = Float64[]; got0 = Float64[]; n_ok = 0; n = 0
    for i in eachindex(e22[:band_Hz])
        fc = e22[:band_Hz][i]
        1250.0 ≤ fc ≤ 2500.0 || continue
        lo, hi = e22[:low_dB][i], e22[:high_dB][i]
        (isfinite(lo) && isfinite(hi)) || continue
        g = hf_pressure_ratio(inp, fc; η_r_cap=0.15, bridges=true).NR_dB
        g0 = hf_pressure_ratio(inp, fc; η_r_cap=0.15).NR_dB
        ok = lo ≤ g ≤ hi; n += 1; n_ok += ok
        push!(xs, fc); push!(mid, e22[:measured_mean_dB][i]); push!(got, g); push!(got0, g0)
        push!(table, ValidationTableRow("NR fc=$(round(Int, fc)) [$(lo), $(hi)]", fc, e22[:measured_mean_dB][i], g,
                                        g - e22[:measured_mean_dB][i], ok))
    end
    series = [PlotSeries("E-22 measured mean", :reference_points, xs, mid; panel=1),
              PlotSeries("Eqs. 19–23 with Sharp bridges", :computed, xs, got; panel=1),
              PlotSeries("Eqs. 19–23 as printed", :computed, xs, got0; panel=1)]
    return ValidationCaseResult("E22_BR", _today_iso(),
        (; criterion="inside the E-22 95 % interval in ≥ 75 % of bands 1250–2500 Hz", date="2026-10-23",
           NR_bridges=round.(got; digits=2), NR_printed=round.(got0; digits=2), n_ok, n),
        table, series, n > 0 && n_ok / n ≥ 0.75 - 1e-12 ? :met : :not_met,
        "$n_ok/$n bands inside the E-22 interval with bridges (printed Eqs. 19–23: $(round.(got0; digits=1)) dB)",
        "V-EXP (extension)", joinpath(_VAL_REPORT_DIR, _P59_REPORT))
end

function _run_t2_meas_ext_br()
    cols = _read_csv_numeric(_data_path("cr3813", "t2_third_octave_targets.csv"))
    e9 = Dict(cols[:fc_Hz][i] => cols[:measured_mean_SPL_dB][i] for i in eachindex(cols[:fc_Hz]))
    r = run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200.0, blocking=R2)
    inp = r.inputs; bands = resolve_bands(inp)
    ext = p47_band_levels(:ext, [_p47_fc(1)])[1][1]
    S = _p47_fig14_slope().S
    L_ext = Dict(1250.0 => ext.L_bb, 1600.0 => ext.L_bb + S / 2, 2000.0 => ext.L_bb + S)
    table = ValidationTableRow[]; got = Float64[]; fcs = [1250.0, 1600.0, 2000.0]; ok1250 = false
    for fc in fcs
        p2 = hf_broadband_band_p2(inp, nearest_third_octave(fc, bands), _P47_PREF2 * 10^(L_ext[fc] / 10); bridges=true)
        g = 10 * log10(p2 / _P47_PREF2)
        ok = abs(g - e9[fc]) ≤ 3.5
        fc == 1250.0 && (ok1250 = ok)
        push!(got, g)
        push!(table, ValidationTableRow("interior fc=$(round(Int, fc))" * (fc == 1250.0 ? "" : " (extrapolated exterior)"),
                                        fc, e9[fc], g, g - e9[fc], ok))
    end
    series = [PlotSeries("Fig. E-9 measured mean", :reference_points, fcs, [e9[f] for f in fcs]; panel=1),
              PlotSeries("T2 Eqs. 19–23 + Sharp bridges, measured exterior", :computed, fcs, got; panel=1)]
    return ValidationCaseResult("T2_MEAS_EXT_BR", _today_iso(),
        (; criterion="1250 Hz within ±3.5 dB of E-9 (51.0 dB)", date="2026-10-23", interior_dB=round.(got; digits=2),
           bridge=bridge_tau(inp, 1259.92)),
        table, series, ok1250 ? :met : :not_met,
        "1250 Hz: $(round(got[1]; digits=2)) dB vs 51.0 (±3.5) with Sharp bridges; 1600/2000 Hz (extrapolated): " *
        "$(round(got[2]; digits=2)), $(round(got[3]; digits=2)) dB", "V-EXP (extension)",
        joinpath(_VAL_REPORT_DIR, _P59_REPORT))
end

"""Least-squares slope (dB per octave) of `y` against log2 of `f`."""
function _p81_slope_per_octave(f::AbstractVector, y::AbstractVector)
    x = log2.(f); xm = sum(x) / length(x); ym = sum(y) / length(y)
    return sum((x .- xm) .* (y .- ym)) / sum((x .- xm) .^ 2)
end

# Phase 81c (criterion fixed 2026-10-29 before the run): what the Fig. 5 construction fixes, independent of the rounded
# ΔTL_M and of the mass-law offset: the slopes of its three segments against those of the digitized Fig. 15 curve.
const _P81_SHARP_SEGMENTS = (("below f₀ (mass law, 6 dB/octave)", 63.0, 125.0),
                             ("rise f₀ to f_b (18 dB/octave)", 160.0, 250.0),
                             ("above f_b (mass law + ΔTL_M, 6 dB/octave)", 500.0, 1000.0))

function _run_sharp_panel_d_shape()
    t = _read_csv_numeric_nan(_data_path("cr172490", "cr172490_fig15_panelD.csv"))
    m = 2780.0 * 0.0016; d = 0.0826
    table = ValidationTableRow[]; xs = Float64[]; sf = Float64[]; sc = Float64[]
    for (i, (name, lo, hi)) in enumerate(_P81_SHARP_SEGMENTS)
        sel = [k for k in eachindex(t[:f_Hz]) if lo ≤ t[:f_Hz][k] ≤ hi && isfinite(t[:TL_0Pa_dB][k])]
        f = t[:f_Hz][sel]
        fig = _p81_slope_per_octave(f, t[:TL_0Pa_dB][sel])
        con = _p81_slope_per_octave(f, [sharp_double_panel_TL(m, m, d, x; ΔTL_M=12.0) for x in f])
        ok = abs(fig - con) ≤ 1.5
        push!(table, ValidationTableRow("slope $name, dB/octave", i, fig, con, con - fig, ok, "segment slope"))
        push!(xs, i); push!(sf, fig); push!(sc, con)
    end
    n_ok = count(r -> r.within_tolerance, table)
    series = [PlotSeries("CR-172490 Fig. 15, digitized curve", :reference_points, xs, sf; panel=1),
              PlotSeries("Sharp construction (Eqs. 5, 22; Fig. 5)", :computed_points, xs, sc; panel=1)]
    return ValidationCaseResult("SHARP_PANEL_D_SHAPE", _today_iso(),
        (; criterion="each segment slope within ±1.5 dB/octave of the figure's", date="2026-10-29",
           slopes_figure=round.(sf; digits=2), slopes_construction=round.(sc; digits=2)),
        table, series, n_ok == 3 ? :met : :not_met,
        "$n_ok/3 segment slopes within ±1.5 dB/octave (figure $(join(round.(sf; digits=1), ", ")); construction " *
        "$(join(round.(sc; digits=1), ", ")) dB/octave)", "V-UNIT", joinpath(_VAL_REPORT_DIR, _P59_REPORT))
end

function _iso59_validation_cases()
    mk(id, title, files, fig, crit, label, run, ylab, tol) = ValidationCase(id, title, "59", files, fig, crit, "2026-10-23", label, run,
        PlotSpec(; xlabel="1/3-octave band (Hz)", ylabel=ylab, xscale=:log10, panel_titles=[id], error_mode=:absolute, error_tol=tol), "")
    return [
        mk("SHARP_PANEL_D", "Sharp double-panel construction vs CR-172490 Fig. 15, Panel D (59a)",
           [_data_path("cr172490", "cr172490_fig15_panelD.csv")], FigureRef("NASA CR-172490", "Fig. 15", 45),
           "Within 1 dB of the digitized predicted curve at ≥ 90 % of the points 50–2000 Hz, ΔTL_M = 12 dB as stated.",
           "V-UNIT", _run_sharp_panel_d, "TL (dB)", 1.0),
        ValidationCase("SHARP_PANEL_D_SHAPE", "Sharp construction segment slopes vs CR-172490 Fig. 15, Panel D (81c)", "81",
            [_data_path("cr172490", "cr172490_fig15_panelD.csv")], FigureRef("NASA CR-172490", "Fig. 15", 45),
            "Each segment slope of the construction (below f₀ 63–125 Hz, rise 160–250 Hz, above f_b 500–1000 Hz; least-squares dB/octave) within ±1.5 dB/octave of the digitized figure.",
            "2026-10-29", "V-UNIT", _run_sharp_panel_d_shape,
            PlotSpec(; xlabel="segment (1 below f₀, 2 rise, 3 above f_b)", ylabel="slope (dB/octave)",
                     panel_titles=["segment slopes"], error_mode=:absolute, error_tol=1.5,
                     error_ylabel="construction − figure (dB/octave)"), ""),
        mk("NR_PROP_TP2444_BR", "TP-2444 NR with Sharp sound bridges in Eq. (23) (59c)",
           [_data_path("tp2444", "tp2444_fig17_exterior_passA.csv"), _data_path("tp2444", "tp2444_fig17_interior_passA.csv")],
           FigureRef("NASA TP-2444", "Fig. 17", 32), "Within ±5 dB in ≥ 75 % of the broadband bands 315–1250 Hz (as 47c).",
           "V-EXP (extension)", _run_nr_prop_tp2444_br, "NR (dB)", 5.0),
        mk("E22_BR", "E-22 reverberant NR with Sharp sound bridges, 1250–2500 Hz (59d)",
           [_data_path("cr3813", "e22_noise_reduction_ci.csv")], FigureRef("CR-3813", "Fig. E-22", 150),
           "Inside the E-22 95 % interval in ≥ 75 % of the bands 1250–2500 Hz.", "V-EXP (extension)", _run_e22_br, "NR (dB)", 3.0),
        mk("T2_MEAS_EXT_BR", "T2 with the measured exterior and Sharp sound bridges (59e)",
           [_data_path("tp2444", "tp2444_fig17_exterior_passA.csv"), _data_path("cr3813", "t2_third_octave_targets.csv")],
           FigureRef("CR-3813", "Fig. E-9", 132), "1250 Hz interior within ±3.5 dB of E-9 (51.0 dB); 1600/2000 Hz extrapolated.",
           "V-EXP (extension)", _run_t2_meas_ext_br, "SPL (dB)", 3.5),
    ]
end
