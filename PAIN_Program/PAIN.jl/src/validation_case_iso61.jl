# Phase 61 — is the code the same as PAIN as NASA ran it for CR-3813? CR-3813's printed outputs predate
# NASA's correction of the Eq. (52) floor-term sign (CR-172428 p. 178); `floor_sign = −1` runs that form.
# Criteria fixed 2026-10-23 (COMPLETED_PHASES.md §8h) before any run.

const _P61_REPORT = "phase61_cr3813_reproduction.md"
# Phase 150e (2026-11-11): REPRO_18b_PRE and E21_PRE retired (refuted, Phases 61, 83, 84); report kept.

function _run_e22_hf_code()
    e22 = _read_csv_numeric_nan(_data_path("cr3813", "e22_noise_reduction_ci.csv"))
    inp = noise_reduction_test_article_inputs(; η_lining=1.0)
    table = ValidationTableRow[]; n_ok = 0; xs = Float64[]; ref = Float64[]; got = Float64[]; meas = Float64[]
    for i in eachindex(e22[:band_Hz])
        fc = e22[:band_Hz][i]; p = e22[:nasa_pred_dB][i]
        (1250.0 ≤ fc ≤ 2500.0 && isfinite(p)) || continue
        g = hf_pressure_ratio(inp, fc; η_r_cap=0.15).NR_dB
        ok = abs(g - p) ≤ 3.0; n_ok += ok
        push!(xs, fc); push!(ref, p); push!(got, g); push!(meas, e22[:measured_mean_dB][i])
        push!(table, ValidationTableRow("NR fc=$(round(Int, fc)) vs NASA", fc, p, g, g - p, ok))
    end
    n = length(xs)
    series = [PlotSeries("NASA prediction (E-22)", :reference_points, xs, ref; panel=1),
              PlotSeries("measured mean (E-22)", :measured_points, xs, meas; panel=1),
              PlotSeries("this code, Eqs. 19–23", :computed, xs, got; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("E22_HF_CODE", _today_iso(),
        (; criterion="|Δ| ≤ 3 dB of NASA's prediction in ≥ 75 % of bands 1250–2500 Hz", date="2026-10-23",
           code=r2(got), nasa=ref, measured=meas, nasa_minus_measured=r2(ref .- meas), n_ok, n),
        table, series, n_ok / max(n, 1) ≥ 0.75 - 1e-12 ? :met : :not_met,
        "$n_ok/$n bands within ±3 dB of NASA (code − NASA $(r2(got .- ref)) dB); NASA − measured $(r2(ref .- meas)) dB",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P61_REPORT))
end

function _iso61_validation_cases()
    mk(id, title, files, fig, crit, run, ylab, tol) = ValidationCase(id, title, "61", files, fig, crit, "2026-10-23", "V-CODE", run,
        PlotSpec(; xlabel="band (Hz)", ylabel=ylab, xscale=:log10, panel_titles=[id], error_mode=:absolute, error_tol=tol), "")
    return [
        mk("E22_HF_CODE", "High-frequency NR, this code vs NASA's E-22 prediction (61d)",
           [_data_path("cr3813", "e22_noise_reduction_ci.csv")], FigureRef("CR-3813", "Fig. E-22", 150),
           "|Δ| ≤ 3 dB of NASA's prediction in ≥ 75 % of the bands 1250–2500 Hz.", _run_e22_hf_code, "NR (dB)", 3.0),
    ]
end
