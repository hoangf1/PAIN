# Phase 96 — NASA's band-centre η_n rule as the default (IMPLEMENTATION_PLAN.md §8am; 96b criterion fixed 2026-10-30
# before the run). Eq. (77) for each cabin mode at the nominal 1/3-octave centre holding the mode, for both ω and the trim
# conductance (Phase 95: 45/46 App. B modes with NASA's printed admittance).

const _P96_REPORT = "phase95_96_eta_n_band_rule.md"

"""η_n of cabin mode (ac, q) by the code's default rule (`acoustic_N_per_mode`)."""
function _eta_n_default(inp::PainInputs, ac, q::Integer; V::Real=cabin_volume(inp))
    ωn = 2π * cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, q; c0=inp.c_int, c2d=inp.c_cyl2d)
    return ωn > 0 ? acoustic_N_per_mode(inp, ac, q, ωn; V) / ωn^2 : NaN
end

"""η_n by the same rule with NASA's printed admittance (App. B p. 197) at the nominal centre, for the echo."""
function _eta_n_nasa_admittance(inp::PainInputs, ac, q::Integer, tr; V::Real=cabin_volume(inp))
    ωn = 2π * cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, q; c0=inp.c_int, c2d=inp.c_cyl2d)
    fc = max(100.0, nominal_band_centre(ωn / 2π))
    j = findfirst(==(fc), tr[:f_Hz])
    N = acoustic_loss_modal(ac, q, 2π * fc, ωn; a=inp.fuse.a, L=inp.L_c, V, c0=inp.c_int,
                            ξ=tr[:side_adm_re][j], ξ_e=tr[:end_adm_re][j]).N
    return N / ωn^2
end

"""96a (diagnostic, post-hoc): η_n of the App. B cabin modes ≥ 100 Hz by the default rule against p. 195."""
function _run_appb_eta_n_band()
    inp = r172428_inputs(4000); V = cabin_volume(inp)
    ac_tab = _read_csv_numeric_nan(_r172428_csv("appB_acoustic_modes.csv"))
    tr = _read_csv_numeric_nan(_r172428_csv("appB_trim.csv"))
    table = ValidationTableRow[]; xs = Float64[]; ref = Float64[]; got = Float64[]; n2 = 0; n10 = 0; nn = 0
    for k in eachindex(ac_tab[:mode])
        q = Int(ac_tab[:Q][k]); I = Int(ac_tab[:I][k]); ac = _acmode_by_I(inp, I)
        cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, q; c0=inp.c_int, c2d=inp.c_cyl2d) < 100 && continue
        mode = Int(ac_tab[:mode][k]); nasa = ac_tab[:loss_factor][k]
        ours = _eta_n_default(inp, ac, q; V); r = ours / nasa
        n2 += abs(r - 1) ≤ 0.02; n10 += abs(r - 1) ≤ 0.10
        nn += abs(_eta_n_nasa_admittance(inp, ac, q, tr; V) / nasa - 1) ≤ 0.02
        push!(xs, mode); push!(ref, nasa); push!(got, ours)
        push!(table, ValidationTableRow("mode $mode (Q=$q, I=$I)", mode, nasa, ours, ours - nasa, abs(r - 1) ≤ 0.10))
    end
    n = length(xs)
    series = [PlotSeries("NASA App. B p. 195", :reference_points, xs, ref; panel=1),
              PlotSeries("this code, default rule (nominal band centre)", :computed_points, xs, got; panel=1)]
    return ValidationCaseResult("APPB_ETA_N_BAND", _today_iso(),
        (; criterion="none (diagnostic, post-hoc: the rule was read from these values)", date="2026-10-30",
           n, n_2pct=n2, n_10pct=n10, n_2pct_nasa_admittance=nn),
        table, series, :no_verdict,
        "diagnostic, post-hoc (no criterion): $n10/$n modes within ±10 % and $n2/$n within ±2 % with this code's trim " *
        "admittance; $nn/$n within ±2 % with NASA's printed admittance (App. B p. 197)",
        "V-CODE (diagnostic)", joinpath(_VAL_REPORT_DIR, _P96_REPORT))
end

"""96b (P, held out): η_n of App. B modes 6, 7, 8 at η_T = 2.0 by the default rule against CR-172428 p. 85."""
function _run_appb_eta_n_t2_band()
    t = _r172428_table12()
    ac_tab = _read_csv_numeric_nan(_r172428_csv("appB_acoustic_modes.csv"))
    inp = r172428_inputs(4000; η_T=2.0); V = cabin_volume(inp)
    table = ValidationTableRow[]; xs = Float64[]; ref = Float64[]; got = Float64[]; n_ok = 0
    for k in eachindex(t[:H])
        t[:H][k] == 0 || continue
        mode = Int(t[:eta_n_mode][k]); j = findfirst(==(mode), Int.(ac_tab[:mode]))
        q = Int(ac_tab[:Q][j]); I = Int(ac_tab[:I][j]); ac = _acmode_by_I(inp, I)
        ours = _eta_n_default(inp, ac, q; V); nasa = t[:eta_n][k]
        ok = abs(ours / nasa - 1) ≤ 0.10; n_ok += ok
        push!(xs, mode); push!(ref, nasa); push!(got, ours)
        push!(table, ValidationTableRow("mode $mode (Q=$q, I=$I)", mode, nasa, ours, ours - nasa, ok))
    end
    series = [PlotSeries("NASA, η_T = 2.0 (CR-172428 p. 85)", :reference_points, xs, ref; panel=1),
              PlotSeries("this code, default rule", :computed_points, xs, got; panel=1)]
    r4 = x -> round.(x; digits=4)
    return ValidationCaseResult("APPB_ETA_N_T2_BAND", _today_iso(),
        (; criterion="|η_n/NASA − 1| ≤ 10 % at modes 6, 7, 8", date="2026-10-30", ours=r4(got), nasa=ref, n_ok, n=length(xs)),
        table, series, n_ok == length(xs) ? :met : :not_met,
        "$n_ok/$(length(xs)) within ±10 %: ours $(r4(got)) vs NASA $(ref)", "V-CODE", joinpath(_VAL_REPORT_DIR, _P96_REPORT))
end

"""96d (diagnostic, post-hoc): R172428_CODE's nine points with the code as it ships."""
function _run_r172428_code_default()
    lv = _r172428_levels(; q0_coupled=false, η_n_per_mode=true, η_n_band_omega=true)
    table = [ValidationTableRow("$(r.rpm) rpm H$(r.H)", r.f_Hz, r.nasa, r.ours, r.ours - r.nasa, abs(r.ours - r.nasa) ≤ 3.0) for r in lv]
    xs = [r.f_Hz for r in lv]
    series = [PlotSeries("NASA PAIN (CR-172428 App. B / Table 10)", :reference_points, xs, [r.nasa for r in lv]; panel=1),
              PlotSeries("this code as it ships (Phase 96 default)", :computed_points, xs, [r.ours for r in lv]; panel=1)]
    n3 = count(r -> r.within_tolerance, table)
    return ValidationCaseResult("R172428_CODE_DEFAULT", _today_iso(),
        (; criterion="none (diagnostic, post-hoc: the default form was inferred from these points)", date="2026-10-30",
           ours=[r.ours for r in lv], nasa=[r.nasa for r in lv]),
        table, series, :no_verdict,
        "diagnostic, post-hoc (no criterion): $n3/9 within ±3 dB, largest |Δ| $(round(maximum(abs(r.ours - r.nasa) for r in lv); digits=2)) dB; " *
        join(["$(r.rpm):H$(r.H) $(round(r.ours; digits=2))" for r in lv], ", "),
        "V-CODE (diagnostic)", joinpath(_VAL_REPORT_DIR, _P96_REPORT))
end

function _iso96_validation_cases()
    ac = _r172428_csv("appB_acoustic_modes.csv")
    t12 = _r172428_csv("table12_eta_T2_predictions.csv")
    mk(id, title, files, fig, crit, run, xlab, ylab, mode, tol) = ValidationCase(id, title, "96", files, fig, crit, "2026-10-30",
        "V-CODE", run, PlotSpec(; xlabel=xlab, ylabel=ylab, panel_titles=[id], error_mode=mode, error_tol=tol), "")
    return [
        mk("APPB_ETA_N_BAND", "Cabin-mode η_n by the band-centre rule vs App. B (96a, post-hoc)", [ac, _r172428_csv("appB_trim.csv")],
           FigureRef("NASA CR-172428", "App. B pp. 195, 197", 195), "None (diagnostic, post-hoc).", _run_appb_eta_n_band,
           "App. B cabin mode number", "η_n", :absolute, nothing),
        mk("APPB_ETA_N_T2_BAND", "Cabin-mode η_n at η_T = 2.0 by the band-centre rule vs CR-172428 p. 85 (96b)", [t12, ac],
           FigureRef("NASA CR-172428", "p. 85", 85),
           "|η_n/NASA − 1| ≤ 10 % at App. B modes 6, 7 and 8 (fixed 2026-10-30, before the run).", _run_appb_eta_n_t2_band,
           "App. B cabin mode number", "η_n", :absolute, nothing),
        mk("R172428_CODE_DEFAULT", "CR-172428 reproduction with the code as it ships (96d, post-hoc)",
           [_r172428_csv("appB_predictions.csv"), ac], FigureRef("NASA CR-172428", "App. B pp. 196–212 / Table 10", 206),
           "None (diagnostic, post-hoc).", _run_r172428_code_default, "tone frequency (Hz)", "SPL (dB)", :absolute, 3.0),
    ]
end
