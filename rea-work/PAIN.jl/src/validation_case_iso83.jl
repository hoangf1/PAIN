# Phase 83 — the not-met cases with the fewest points. The high-frequency path and the reproduction ran on Table D-1's
# 32 modes (to 811 Hz); NASA ran PAIN with MRP's 300 modes for this article (CR-172428 Table 6). These cases rerun the
# originals with the App. D solver's 300 modes on NASA's MRP deck (`nasa_deck_modes`), everything else unchanged.
# Criteria are the originals', fixed 2026-10-29 (IMPLEMENTATION_PLAN.md §8aa) before any run.

const _P83_REPORT = "phase83_deck_modes.md"

_with_deck_modes(inp::PainInputs) = _with_fields(inp; structural=nasa_deck_modes())

"""83b: Eqs. (19)–(23) on NASA's 300 modes against E-22's NASA prediction (criterion of E22_HF_CODE)."""
function _run_e22_hf_deck()
    e22 = _read_csv_numeric_nan(_data_path("cr3813", "e22_noise_reduction_ci.csv"))
    deck = noise_reduction_test_article_inputs(; η_lining=1.0, structural_set=:deck)
    d1 = noise_reduction_test_article_inputs(; η_lining=1.0)
    table = ValidationTableRow[]; n_ok = 0; xs = Float64[]; ref = Float64[]; got = Float64[]; old = Float64[]; meas = Float64[]
    n_res = Int[]
    for i in eachindex(e22[:band_Hz])
        fc = e22[:band_Hz][i]; p = e22[:nasa_pred_dB][i]
        (1250.0 ≤ fc ≤ 2500.0 && isfinite(p)) || continue
        pr = hf_pressure_ratio(deck, fc; η_r_cap=0.15)
        g = pr.NR_dB
        ok = abs(g - p) ≤ 3.0; n_ok += ok
        push!(xs, fc); push!(ref, p); push!(got, g); push!(meas, e22[:measured_mean_dB][i])
        push!(old, hf_pressure_ratio(d1, fc; η_r_cap=0.15).NR_dB); push!(n_res, length(pr.band.in_band))
        push!(table, ValidationTableRow("NR fc=$(round(Int, fc)) vs NASA", fc, p, g, g - p, ok))
    end
    n = length(xs)
    series = [PlotSeries("NASA prediction (E-22)", :reference_points, xs, ref; panel=1),
              PlotSeries("measured mean (E-22)", :measured_points, xs, meas; panel=1),
              PlotSeries("this code, NASA's 300 modes", :computed, xs, got; panel=1),
              PlotSeries("this code, Table D-1 32 modes (E22_HF_CODE)", :computed, xs, old; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("E22_HF_DECK", _today_iso(),
        (; criterion="|Δ| ≤ 3 dB of NASA's prediction in ≥ 75 % of bands 1250–2500 Hz", date="2026-10-29",
           n_modes=NASA_MRP_N_MODES, resonant_modes_per_band=n_res, code=r2(got), table_d1=r2(old), nasa=ref, measured=meas,
           n_ok, n),
        table, series, n > 0 && n_ok / n ≥ 0.75 - 1e-12 ? :met : :not_met,
        "$n_ok/$n bands within ±3 dB of NASA with NASA's 300 modes (code − NASA $(r2(got .- ref)) dB; " *
        "Table D-1 32 modes: $(r2(old .- ref)) dB)",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P83_REPORT))
end

"""83c: T2_EQ19 on NASA's 300 modes against Fig. E-9 (criterion of T2_EQ19)."""
function _run_t2_eq19_deck()
    targets = _data_path("cr3813", "t2_third_octave_targets.csv")
    isfile(targets) || (targets = _data_path("cr3813", "t2_third_octave_targets_B.csv"))   # as T2_EQ19
    r = run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200.0, blocking=R2)
    nh = min(5, size(r.inputs.amplitudes, 3))
    spec = interior_spl(_with_deck_modes(r.inputs); bpf_Hz=200.0, n_harmonics=nh, broadband=true, broadband_model=:eq19)
    spec0 = interior_spl(r.inputs; bpf_Hz=200.0, n_harmonics=nh, broadband=true, broadband_model=:eq19)
    cols = _read_csv_numeric(targets)
    table = ValidationTableRow[]; n_ok = 0; xs = Float64[]; meas = Float64[]; got = Float64[]; old = Float64[]
    for i in eachindex(cols[:fc_Hz])
        fc = cols[:fc_Hz][i]; m = cols[:measured_mean_SPL_dB][i]; tol = cols[:tol_dB][i]
        b = nearest_third_octave(fc, collect(keys(spec.third_octave_SPL_dB)))
        g = get(spec.third_octave_SPL_dB, b, NaN); g0 = get(spec0.third_octave_SPL_dB, b, NaN)
        ok = isfinite(g) && abs(g - m) ≤ tol; n_ok += ok
        push!(xs, fc); push!(meas, m); push!(got, g); push!(old, g0)
        push!(table, ValidationTableRow("1/3-oct fc=$(round(fc; digits=0))", fc, m, g, g - m, ok))
    end
    series = [PlotSeries("measured mean (E-9)", :reference_points, xs, meas; panel=1),
              PlotSeries("Eqs. 19–23, NASA's 300 modes", :computed, xs, got; panel=1),
              PlotSeries("Eqs. 19–23, Table D-1 32 modes (T2_EQ19)", :computed, xs, old; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("T2_EQ19_DECK", _today_iso(),
        (; criterion="|got − Fig. E-9 mean| ≤ tol_dB (3.5 dB) at every band (T2_EQ19's)", date="2026-10-29",
           n_modes=NASA_MRP_N_MODES, got=r2(got), table_d1=r2(old), measured=meas, n_ok, n=length(xs)),
        table, series, n_ok == length(xs) && !isempty(xs) ? :met : :not_met,
        "$n_ok/$(length(xs)) bands within tolerance with NASA's 300 modes: $(r2(got)) dB vs E-9 $(meas) " *
        "(Table D-1 32 modes: $(r2(old)))",
        "V-EXP", joinpath(_VAL_REPORT_DIR, _P83_REPORT))
end

"""83e: REPRO_18b on NASA's 300 modes against E-16's NASA prediction (criterion of REPRO_18b)."""
function _run_repro_18b_deck()
    targets = _data_path("cr3813", "t1_interior_targets.csv")
    paths = default_e11_paths()
    p3 = phase3_trim(; η_lining=0.5)
    r = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3, bpf_Hz=200.0,
                          blocking=R1, sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends, mech=p3.mech)
    got = interior_spl(_with_deck_modes(r.inputs); bpf_Hz=200.0, n_harmonics=3, broadband=false).harmonic_SPL_dB
    old = r.spectrum.harmonic_SPL_dB
    cols = _read_csv_numeric(targets)
    table = ValidationTableRow[]; n_ok = 0; xs = Float64[]; nasa = Float64[]
    for i in eachindex(cols[:harmonic])
        H = Int(round(cols[:harmonic][i])); H ≤ 3 || continue
        ref = cols[:nasa_pain_pred_dB][i]; band = cols[:band_Hz][i]
        ok = abs(got[H] - ref) ≤ 4.0; n_ok += ok
        push!(xs, band); push!(nasa, ref)
        push!(table, ValidationTableRow("vs NASA PAIN H=$H (300 modes)", band, ref, got[H], got[H] - ref, ok))
    end
    series = [PlotSeries("NASA PAIN (E-16)", :reference_points, xs, nasa; panel=1),
              PlotSeries("NASA's 300 modes", :computed, xs, got[1:3]; panel=1),
              PlotSeries("Table D-1 32 modes (REPRO_18b)", :computed, xs, old[1:3]; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("REPRO_18b_DECK", _today_iso(),
        (; criterion="|Δ| ≤ 4 dB at H1–H3 vs E-16 NASA prediction (REPRO_18b's)", date="2026-10-29",
           n_modes=NASA_MRP_N_MODES, got=r2(got[1:3]), table_d1=r2(old[1:3]), nasa, n_ok),
        table, series, n_ok == 3 ? :met : :not_met,
        "$n_ok/3 within ±4 dB with NASA's 300 modes: $(r2(got[1:3])) dB vs NASA $(nasa) (Table D-1 32 modes: $(r2(old[1:3])))",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P83_REPORT))
end

function _iso83_validation_cases()
    mk(id, title, files, fig, crit, run, ylab, tol, vc) = ValidationCase(id, title, "83", files, fig, crit, "2026-10-29", vc, run,
        PlotSpec(; xlabel="band (Hz)", ylabel=ylab, xscale=:log10, panel_titles=[id], error_mode=:absolute, error_tol=tol), "")
    return [
        mk("E22_HF_DECK", "High-frequency NR on NASA's 300 modes vs NASA's E-22 prediction (83b)",
           [_data_path("cr3813", "e22_noise_reduction_ci.csv"), _data_path("cr3813", "um_mrp_input_deck.csv")],
           FigureRef("CR-3813", "Fig. E-22", 150),
           "|Δ| ≤ 3 dB of NASA's prediction in ≥ 75 % of the bands 1250–2500 Hz (E22_HF_CODE's).", _run_e22_hf_deck,
           "NR (dB)", 3.0, "V-CODE"),
        mk("T2_EQ19_DECK", "T2 with Eqs. (19)–(23) on NASA's 300 modes vs Fig. E-9 (83c)",
           [_data_path("cr3813", "t2_third_octave_targets.csv"), _data_path("cr3813", "um_mrp_input_deck.csv")],
           FigureRef("CR-3813", "Fig. E-9", 132),
           "|got − Fig. E-9 mean| ≤ 3.5 dB at 1.25, 1.6, 2 kHz (T2_EQ19's).", _run_t2_eq19_deck, "SPL (dB)", 3.5, "V-EXP"),
        mk("REPRO_18b_DECK", "REPRO_18b on NASA's 300 modes vs E-16's NASA prediction (83e)",
           [_data_path("cr3813", "t1_interior_targets.csv"), _data_path("cr3813", "um_mrp_input_deck.csv")],
           FigureRef("CR-3813", "Fig. E-16 NASA PAIN pred", 142),
           "|Δ| ≤ 4 dB at H1–H3 against E-16's NASA prediction (REPRO_18b's).", _run_repro_18b_deck, "SPL (dB)", 4.0, "V-CODE"),
    ]
end
