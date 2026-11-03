# Phase 99 — did the program that produced CR-3813's printed runs already use the band-centre η_n of Phase 95?
# (IMPLEMENTATION_PLAN.md §8ao; criteria and decision fixed 2026-10-30 before the run.) Pre-correction form (floor sign
# −1, printed Eq. (82), q = 0 coupled) with η_n per mode by the band rule, against CR-3813's E-16 and E-18 NASA
# predictions, which played no part in reading the rule. Diagnostics: no verdict, outcomes recorded.

const _P99_REPORT = "phase99_band_rule_cr3813.md"

"""The pre-correction form with η_n per cabin mode at the nominal band centre (Phase 96 rule)."""
_pre_correction_band(inp::PainInputs) = _with_fields(_pre_correction_form(inp); η_n_per_mode=true, η_n_band_omega=true)

"""99a (H1–H3, η_lining 0.5, E-16) and 99b (E-18, η_lining 1.0, η_r′ capped at 0.15 as E18_TONES)."""
function _run_band_cr3813(which::Symbol)
    e16 = which === :e16
    paths = default_e11_paths(); p3 = phase3_trim(; η_lining=e16 ? 0.5 : 1.0)
    r = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3, bpf_Hz=200.0,
                          blocking=R1, sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends, mech=p3.mech)
    kw = e16 ? (; broadband=false) : (; broadband=false, tone_model=:eq8, η_r_cap=0.15)
    spl(inp) = interior_spl(inp; bpf_Hz=200.0, n_harmonics=3, kw...).harmonic_SPL_dB
    got = spl(_pre_correction_band(r.inputs)); base = spl(_pre_correction_form(r.inputs))
    refs = if e16
        cols = _read_csv_numeric(_data_path("cr3813", "t1_interior_targets.csv"))
        [(Int(round(cols[:harmonic][i])), cols[:band_Hz][i], cols[:nasa_pain_pred_dB][i]) for i in eachindex(cols[:harmonic]) if cols[:harmonic][i] ≤ 3]
    else
        cols = _read_csv_numeric_nan(_data_path("cr3813", "e18_interior_pred_eta1.csv"))
        nasa_of = Dict(cols[:band_Hz][i] => cols[:nasa_pred_dB][i] for i in eachindex(cols[:band_Hz]))
        [(H, b, nasa_of[b]) for (H, b) in ((1, 200.0), (2, 400.0), (3, 630.0)) if isfinite(get(nasa_of, b, NaN))]
    end
    table = ValidationTableRow[]; n_ok = 0; xs = Float64[]; ref = Float64[]
    for (H, band, nasa) in refs
        ok = abs(got[H] - nasa) ≤ 4.0; n_ok += ok
        push!(xs, band); push!(ref, nasa)
        push!(table, ValidationTableRow("vs NASA $(e16 ? "E-16" : "E-18") H=$H (pre-correction form, band-centre η_n)", band, nasa, got[H], got[H] - nasa, ok))
    end
    n = length(xs); r2 = x -> round.(x; digits=2)
    series = [PlotSeries("NASA PAIN ($(e16 ? "E-16" : "E-18"))", :reference_points, xs, ref; panel=1),
              PlotSeries("pre-correction form, band-centre η_n", :computed, xs, got[1:n]; panel=1),
              PlotSeries("pre-correction form, η_n at the tone", :computed, xs, base[1:n]; panel=1)]
    id = e16 ? "BAND_REPRO_18b" : "BAND_E18"
    return ValidationCaseResult(id, _today_iso(),
        (; criterion="|Δ| ≤ 4 dB per harmonic vs $(e16 ? "E-16" : "E-18")'s NASA prediction", date="2026-10-30",
           got=r2(got[1:n]), tone_eta_n=r2(base[1:n]), nasa=ref, n_ok, n),
        table, series, n > 0 && n_ok == n ? :met : :not_met,
        "$n_ok/$n within ±4 dB with the band-centre η_n: $(r2(got[1:n])) dB vs NASA $(ref) (η_n at the tone: $(r2(base[1:n])))",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P99_REPORT))
end

function _iso99_validation_cases()
    mk(id, title, file, fig, crit, run) = ValidationCase(id, title, "99", [file], fig, crit, "2026-10-30", "V-CODE", run,
        PlotSpec(; xlabel="band (Hz)", ylabel="SPL (dB)", panel_titles=[id], error_mode=:absolute, error_tol=4.0, xscale=:log10), "")
    return [
        mk("BAND_REPRO_18b", "Band-centre η_n, pre-correction form, vs E-16's NASA prediction (99a)",
           _data_path("cr3813", "t1_interior_targets.csv"), FigureRef("CR-3813", "Fig. E-16 NASA PAIN pred", 142),
           "|Δ| ≤ 4 dB at H1–H3 against E-16's NASA prediction (REPRO_18b's; fixed 2026-10-30, before the run).",
           () -> _run_band_cr3813(:e16)),
        mk("BAND_E18", "Band-centre η_n, pre-correction form, vs E-18's NASA prediction (99b)",
           _data_path("cr3813", "e18_interior_pred_eta1.csv"), FigureRef("CR-3813", "Fig. E-18", 145),
           "|Δ| ≤ 4 dB per harmonic against E-18's NASA prediction (E18_TONES's; fixed 2026-10-30, before the run).",
           () -> _run_band_cr3813(:e18)),
    ]
end
