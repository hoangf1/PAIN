# Phase 48 — the exterior broadband predicted from physics (NASA RP-1218), and T2 fully predictive.
# Criteria fixed 2026-10-23 (IMPLEMENTATION_PLAN.md §8d Phase 48) before any run; 48b–48d implementation
# decisions fixed the same day before any comparison with Fig. 14, Fig. 17 or E-9.

const _P48_AF = Ref{Any}(nothing)
function _p48_af()
    _P48_AF[] === nothing && (_P48_AF[] = load_polar_set(_data_path(splitpath(_R996_POLAR_PATH)...); set=:primary)[1])
    return _P48_AF[]
end
const _P48_OBS_FIG14 = (0.457, 0.0, -0.254)   # CR-172428 Fig. 9, microphone 1 (5000 rpm)
const _P48_OBS_FIG17 = (0.457, 0.0, 0.0)      # TP-2444 Fig. 17 exterior: fuselage surface, propeller plane (V-ASSUMED)

function _run_bpm_rp1218()
    table = ValidationTableRow[]
    n_ok = 0; n = 0
    xs = Float64[]; ref = Float64[]; got = Float64[]
    cases = (("D2", "rp1218_tableD2.csv",
              [(; c=0.3048, L=0.4572, r=1.22, Θ=90.0, Φ=90.0, α=1.516, U=71.3, trip=:untripped)], (; lbl=true, tip=false)),
             ("D3", "rp1218_tableD3.csv",
              [(; c=0.1524, L=0.0305, r=1.22, Θ=90.0, Φ=90.0, α=5.4, U=71.3, trip=:tripped, α_tip=7.7, rounded=true)
               for _ in 1:10], (; lbl=false, tip=true)))
    for (name, file, segs, opt) in cases
        t = _read_csv_numeric_nan(_data_path("rp1218", file))
        s = bpm_spectrum(segs; freqs=t[:f_Hz], lbl=opt.lbl, tip=opt.tip)
        cols = [(:tbl_pressure_dB, s.p), (:tbl_suction_dB, s.s), (:separation_dB, s.α), (:total_dB, s.total)]
        opt.lbl && push!(cols, (:laminar_dB, s.lbl))
        opt.tip && push!(cols, (:tip_dB, s.tip))
        for (col, ours) in cols, i in eachindex(t[:f_Hz])
            r = t[col][i]
            ok = abs(ours[i] - r) ≤ 1.0
            n += 1; n_ok += ok
            push!(table, ValidationTableRow("$name $(col) f=$(round(Int, t[:f_Hz][i]))", t[:f_Hz][i], r, ours[i], ours[i] - r, ok,
                                            "$name $(replace(String(col), "_dB" => ""))"))
            if col === :total_dB
                push!(xs, t[:f_Hz][i]); push!(ref, r); push!(got, ours[i])
            end
        end
    end
    frac = n_ok / n
    series = [PlotSeries("RP-1218 Tables D2, D3 total", :reference_points, xs, ref; panel=1),
              PlotSeries("bpm_spectrum total", :computed, xs, got; panel=1)]
    return ValidationCaseResult("BPM_RP1218", _today_iso(),
        (; criterion="within 1 dB of the printed code output at ≥ 90 % of points", date="2026-10-23", n_ok, n, frac),
        table, series, frac ≥ 0.9 ? :met : :not_met,
        "$n_ok/$n points within 1 dB of RP-1218 App. D Tables D2/D3 (max |Δ| $(round(maximum(abs(t.residual) for t in table); digits=2)) dB)",
        "V-UNIT", joinpath(_VAL_REPORT_DIR, "phase48_exterior_broadband.md"))
end

"""48b exterior broadband band levels [dB] at the nominal 1/3-octave centres `fcs`."""
function p48_exterior_bands(rpm::Real, obs, fcs)
    s = propeller_broadband_spectrum(p48_propeller_cfg(rpm), _p48_af(), obs; freqs=fcs)
    return s
end

function _p48_run_floor(id::String, fig::Symbol, rpm::Int, obs, ks)
    nominal = [315.0, 400, 500, 630, 800, 1000, 1250, 1600, 2000][1:length(ks)]
    exact = [_p47_fc(k) for k in ks]
    meas = [b.L_bb for b in p47_band_levels(fig, exact)[1]]
    s = p48_exterior_bands(rpm, obs, nominal)
    table = ValidationTableRow[]
    n_ok = 0
    for i in eachindex(nominal)
        ok = isfinite(meas[i]) && abs(s.total[i] - meas[i]) ≤ 5.0
        n_ok += ok
        push!(table, ValidationTableRow("band $(round(Int, nominal[i])) Hz", nominal[i], meas[i], s.total[i], s.total[i] - meas[i], ok))
    end
    n = length(nominal); frac = n_ok / n
    series = [PlotSeries("measured broadband (47b, tones removed)", :reference_points, nominal, meas; panel=1),
              PlotSeries("BPM blade-segment sum (V-ASSUMED blade)", :computed, nominal, s.total; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult(id, _today_iso(),
        (; criterion="within ±5 dB in ≥ 75 % of 1/3-octave bands", date="2026-10-23", rpm, observer_m=obs,
           measured=r2(meas), total=r2(s.total), tbl_suction=r2(s.s), separation=r2(s.α), lbl=r2(s.lbl), tip=r2(s.tip),
           n_ok, n, frac),
        table, series, frac ≥ 0.75 - 1e-12 ? :met : :not_met,
        "$n_ok/$n bands within ±5 dB (blade V-ASSUMED; observer within 0.3 m of the tip, X-EXTRAP)",
        "V-EXP (X-EXTRAP)", joinpath(_VAL_REPORT_DIR, "phase48_exterior_broadband.md"))
end

_run_prop_bb_fig14() = _p48_run_floor("PROP_BB_FIG14", :f14, 5000, _P48_OBS_FIG14, -5:3)
_run_prop_bb_fig17() = _p48_run_floor("PROP_BB_FIG17", :ext, 4000, _P48_OBS_FIG17, -5:1)

function _run_t2_pred_bb()
    cols = _read_csv_numeric(_data_path("cr3813", "t2_third_octave_targets.csv"))
    fcs = Float64.(cols[:fc_Hz]); e9 = Float64.(cols[:measured_mean_SPL_dB]); tols = Float64.(cols[:tol_dB])
    s = p48_exterior_bands(4000, _P48_OBS_FIG17, fcs)
    r = run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200.0, blocking=R2)
    inp = r.inputs; bands = resolve_bands(inp)
    table = ValidationTableRow[]; got = Float64[]; n_ok = 0
    for (i, fc) in enumerate(fcs)
        p2 = hf_broadband_band_p2(inp, nearest_third_octave(fc, bands), _P47_PREF2 * 10^(s.total[i] / 10))
        g = 10 * log10(p2 / _P47_PREF2)
        ok = abs(g - e9[i]) ≤ tols[i]; n_ok += ok
        push!(got, g)
        push!(table, ValidationTableRow("interior fc=$(round(Int, fc)) vs E-9", fc, e9[i], g, g - e9[i], ok))
    end
    series = [PlotSeries("Fig. E-9 measured mean", :reference_points, fcs, e9; panel=1),
              PlotSeries("BPM exterior → T2 Eqs. 19–23", :computed, fcs, got; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("T2_PRED_BB", _today_iso(),
        (; criterion="T2 gate: ±3.5 dB of E-9 at 1250, 1600, 2000 Hz", date="2026-10-23",
           exterior_dB=r2(s.total), interior_dB=r2(got), n_ok),
        table, series, n_ok == length(fcs) ? :met : :not_met,
        "$n_ok/$(length(fcs)) bands within ±3.5 dB; exterior $(r2(s.total)) dB → interior $(r2(got)) dB vs $(e9)",
        "V-EXP (X-EXTRAP)", joinpath(_VAL_REPORT_DIR, "phase48_exterior_broadband.md"))
end

function _iso48_validation_cases()
    return [
        ValidationCase("BPM_RP1218", "Airfoil self-noise (BPM) vs NASA's printed code output, RP-1218 Tables D2/D3 (48a)", "48",
            [_data_path("rp1218", "rp1218_tableD2.csv"), _data_path("rp1218", "rp1218_tableD3.csv")],
            FigureRef("NASA RP-1218", "App. D Tables D2, D3", 122),
            "Within 1 dB of the printed code output at ≥ 90 % of the points.", "2026-10-23", "V-UNIT", _run_bpm_rp1218,
            PlotSpec(; xlabel="frequency (Hz)", ylabel="SPL (dB)", xscale=:log10, panel_titles=["BPM_RP1218"],
                     error_mode=:absolute, error_tol=1.0), ""),
        ValidationCase("PROP_BB_FIG14", "Propeller broadband (BPM) vs CR-172428 Fig. 14 free field, 5000 rpm (48c)", "48",
            [_data_path("cr172428", "cr172428_fig14_mic1_5000rpm_passA.csv")], FigureRef("NASA CR-172428", "Fig. 14", 38),
            "Within ±5 dB in ≥ 75 % of the 1/3-octave bands 315–2000 Hz (broadband floor, tones removed).",
            "2026-10-23", "V-EXP (X-EXTRAP)", _run_prop_bb_fig14,
            PlotSpec(; xlabel="band (Hz)", ylabel="SPL (dB)", xscale=:log10, panel_titles=["PROP_BB_FIG14"],
                     error_mode=:absolute, error_tol=5.0), ""),
        ValidationCase("PROP_BB_FIG17", "Propeller broadband (BPM) vs TP-2444 Fig. 17 exterior, 4000 rpm (48c)", "48",
            [_data_path("tp2444", "tp2444_fig17_exterior_passA.csv")], FigureRef("NASA TP-2444", "Fig. 17", 32),
            "Within ±5 dB in ≥ 75 % of the 1/3-octave bands 315–1250 Hz (broadband floor, tones removed).",
            "2026-10-23", "V-EXP (X-EXTRAP)", _run_prop_bb_fig17,
            PlotSpec(; xlabel="band (Hz)", ylabel="SPL (dB)", xscale=:log10, panel_titles=["PROP_BB_FIG17"],
                     error_mode=:absolute, error_tol=5.0), ""),
        ValidationCase("T2_PRED_BB", "T2 fully predictive: BPM exterior → T2 cabin path → E-9 (48d)", "48",
            [_data_path("cr3813", "t2_third_octave_targets.csv")], FigureRef("CR-3813", "Fig. E-9", 132),
            "T2's gate: ±3.5 dB of the E-9 measured mean at 1250, 1600 and 2000 Hz.", "2026-10-23", "V-EXP (X-EXTRAP)",
            _run_t2_pred_bb,
            PlotSpec(; xlabel="1/3-octave band (Hz)", ylabel="SPL (dB)", xscale=:log10, xlim=(1000.0, 2600.0),
                     panel_titles=["T2_PRED_BB"], error_mode=:absolute, error_tol=3.5), ""),
    ]
end
