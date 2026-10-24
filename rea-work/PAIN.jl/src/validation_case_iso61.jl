# Phase 61 — is the code the same as PAIN as NASA ran it for CR-3813? CR-3813's printed outputs predate
# NASA's correction of the Eq. (52) floor-term sign (CR-172428 p. 178); `floor_sign = −1` runs that form.
# Criteria fixed 2026-10-23 (IMPLEMENTATION_PLAN.md §8h) before any run.

const _P61_REPORT = "phase61_cr3813_reproduction.md"

function _run_repro_18b_pre()
    targets = _data_path("cr3813", "t1_interior_targets.csv")
    paths = default_e11_paths()
    p3 = phase3_trim(; η_lining=0.5)
    r = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3, bpf_Hz=200.0,
                          blocking=R1, sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends, mech=p3.mech)
    pre = interior_spl(_with_fields(r.inputs; floor_sign=-1.0); bpf_Hz=200.0, n_harmonics=3, broadband=false).harmonic_SPL_dB
    post = r.spectrum.harmonic_SPL_dB
    cols = _read_csv_numeric(targets)
    table = ValidationTableRow[]; n_ok = 0; xs = Float64[]; nasa = Float64[]
    for i in eachindex(cols[:harmonic])
        H = Int(round(cols[:harmonic][i])); H ≤ 3 || continue
        ref = cols[:nasa_pain_pred_dB][i]; band = cols[:band_Hz][i]
        ok = abs(pre[H] - ref) ≤ 4.0; n_ok += ok
        push!(xs, band); push!(nasa, ref)
        push!(table, ValidationTableRow("vs NASA PAIN H=$H (pre-correction form)", band, ref, pre[H], pre[H] - ref, ok))
    end
    series = [PlotSeries("NASA PAIN (E-16)", :reference_points, xs, nasa; panel=1),
              PlotSeries("pre-correction form (floor_sign = −1)", :computed, xs, pre[1:3]; panel=1),
              PlotSeries("corrected form (REPRO_18b)", :computed, xs, post[1:3]; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("REPRO_18b_PRE", _today_iso(),
        (; criterion="|Δ| ≤ 4 dB at H1–H3 vs E-16 NASA prediction", date="2026-10-23", pre=r2(pre[1:3]), corrected=r2(post[1:3]),
           nasa=nasa, n_ok),
        table, series, n_ok == 3 ? :met : :not_met,
        "$n_ok/3 within ±4 dB with NASA's pre-correction floor sign: $(r2(pre[1:3])) dB vs NASA $(nasa) (corrected form: $(r2(post[1:3])))",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P61_REPORT))
end

function _run_e21_pre()
    e21 = _read_csv_numeric_nan(_data_path("cr3813", "e21_noise_reduction_range.csv"))
    bands = Float64.(e21[:band_Hz]); nasa = Float64.(e21[:nasa_pred_dB])
    excluded = Set([80.0, 100.0, 125.0, 160.0])
    base = noise_reduction_test_article_inputs(; η_lining=1.0)
    pre = noise_reduction_spectrum(_with_fields(base; floor_sign=-1.0); bands, η_r_cap=0.15)
    post = noise_reduction_spectrum(base; bands, η_r_cap=0.15)
    table = ValidationTableRow[]; n_ok = 0; n = 0
    xs = Float64[]; ref = Float64[]; g_pre = Float64[]; g_post = Float64[]
    for i in eachindex(bands)
        fc = bands[i]
        isfinite(nasa[i]) || continue
        gp, g0 = pre.rows[i].NR_dB, post.rows[i].NR_dB
        counted = !(fc in excluded) && !pre.rows[i].above_crossover
        ok = abs(gp - nasa[i]) ≤ 3.0
        if counted
            n += 1; n_ok += ok
        end
        push!(xs, fc); push!(ref, nasa[i]); push!(g_pre, gp); push!(g_post, g0)
        push!(table, ValidationTableRow("NR fc=$(round(Int, fc))" * (counted ? "" : " (not counted)"), fc, nasa[i], gp, gp - nasa[i],
                                        ok, counted ? "counted" : "not counted"))
    end
    series = [PlotSeries("NASA prediction (E-21)", :reference_points, xs, ref; panel=1),
              PlotSeries("pre-correction form", :computed, xs, g_pre; panel=1),
              PlotSeries("corrected form", :computed, xs, g_post; panel=1)]
    return ValidationCaseResult("E21_PRE", _today_iso(),
        (; criterion="|Δ| ≤ 3 dB of NASA's prediction in ≥ 75 % of counted bands (38a)", date="2026-10-23",
           n_ok, n, crossover_Hz=pre.crossover.fc_Hz),
        table, series, n > 0 && n_ok / n ≥ 0.75 - 1e-12 ? :met : :not_met,
        "$n_ok/$n counted bands within ±3 dB of NASA with the pre-correction floor sign (crossover $(round(Int, pre.crossover.fc_Hz)) Hz, ten-mode rule as 38a)",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P61_REPORT))
end

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
              PlotSeries("measured mean (E-22)", :reference_points, xs, meas; panel=1),
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
        mk("REPRO_18b_PRE", "REPRO_18b with NASA's pre-correction Eq. (52) floor sign (61b)",
           [_data_path("cr3813", "t1_interior_targets.csv")], FigureRef("CR-3813", "Fig. E-16 NASA PAIN pred", 142),
           "|Δ| ≤ 4 dB at H1–H3 against E-16's NASA prediction.", _run_repro_18b_pre, "SPL (dB)", 4.0),
        mk("E21_PRE", "E-21 NASA NR with NASA's pre-correction Eq. (52) floor sign (61c)",
           [_data_path("cr3813", "e21_noise_reduction_range.csv")], FigureRef("CR-3813", "Fig. E-21", 149),
           "|Δ| ≤ 3 dB of NASA's prediction in ≥ 75 % of the counted bands (38a).", _run_e21_pre, "NR (dB)", 3.0),
        mk("E22_HF_CODE", "High-frequency NR, this code vs NASA's E-22 prediction (61d)",
           [_data_path("cr3813", "e22_noise_reduction_ci.csv")], FigureRef("CR-3813", "Fig. E-22", 150),
           "|Δ| ≤ 3 dB of NASA's prediction in ≥ 75 % of the bands 1250–2500 Hz.", _run_e22_hf_code, "NR (dB)", 3.0),
    ]
end
