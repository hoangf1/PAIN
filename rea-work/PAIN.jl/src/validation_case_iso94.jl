# Phase 94 — the Phase 93 default form against a PAIN run no earlier phase used: CR-172428 Table 12 and p. 85, Table 6
# inputs with the trim panel loss factor η_T = 2.0 (IMPLEMENTATION_PLAN.md §8ak; criteria fixed 2026-10-29 before any
# run). P cases: NASA's inputs, NASA's printed outputs, the code as it ships.

const _P94_REPORT = "phase94_table12_eta_T2.md"

_r172428_table12() = _read_csv_numeric_nan(_r172428_csv("table12_eta_T2_predictions.csv"))

"""94a: H1–H3 at 3000/4000/5000 rpm with η_T = 2.0 (default form) against Table 12."""
function _run_r172428_etat2()
    t = _r172428_table12()
    table = ValidationTableRow[]; xs = Float64[]; nasa = Float64[]; ours = Float64[]; meas = Float64[]; n_ok = 0
    for rpm in (3000, 4000, 5000)
        spl = interior_spl(r172428_inputs(rpm; η_T=2.0); bpf_Hz=3rpm / 60, n_harmonics=3).harmonic_SPL_dB
        for H in 1:3
            i = findfirst(k -> t[:rpm][k] == rpm && t[:H][k] == H, eachindex(t[:rpm]))
            ref = t[:nasa_pred_dB][i]; d = spl[H] - ref; ok = abs(d) ≤ 3.0; n_ok += ok
            push!(xs, H * 3rpm / 60); push!(nasa, ref); push!(ours, spl[H]); push!(meas, t[:measured_dB][i])
            push!(table, ValidationTableRow("$rpm rpm H$H", H * 3rpm / 60, ref, spl[H], d, ok))
        end
    end
    series = [PlotSeries("NASA PAIN, η_T = 2.0 (CR-172428 Table 12)", :reference_points, xs, nasa; panel=1),
              PlotSeries("measured (Table 12)", :measured_points, xs, meas; panel=1),
              PlotSeries("this code (default form), η_T = 2.0", :computed_points, xs, ours; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("R172428_ETAT2", _today_iso(),
        (; criterion="±3 dB of Table 12 at ≥ 7 of 9 points", date="2026-10-29", ours=r2(ours), nasa, n_ok, n=9),
        table, series, n_ok ≥ 7 ? :met : :not_met,
        "$n_ok/9 within ±3 dB of NASA's η_T = 2.0 prediction; ours $(r2(ours)) dB vs NASA $(nasa)",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P94_REPORT))
end

"""94b: η_n of App. B cabin modes 6, 7, 8 with η_T = 2.0 (Eq. 77 at the mode frequency, as APPB_ETA_N) against p. 85."""
function _run_appb_eta_n_t2()
    t = _r172428_table12()
    ac_tab = _read_csv_numeric_nan(_r172428_csv("appB_acoustic_modes.csv"))
    inp = r172428_inputs(4000; η_T=2.0); V = cabin_volume(inp)
    table = ValidationTableRow[]; xs = Float64[]; ref = Float64[]; got = Float64[]; band = Float64[]; n_ok = 0
    for k in eachindex(t[:H])
        t[:H][k] == 0 || continue
        mode = Int(t[:eta_n_mode][k]); j = findfirst(==(mode), Int.(ac_tab[:mode]))
        q = Int(ac_tab[:Q][j]); I = Int(ac_tab[:I][j]); ac = _acmode_by_I(inp, I)
        ours = _eta_n_at_mode(inp, ac, q; V)
        ωn = 2π * cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, q; c0=inp.c_int)
        nasa = t[:eta_n][k]; ok = abs(ours / nasa - 1) ≤ 0.10; n_ok += ok
        push!(xs, mode); push!(ref, nasa); push!(got, ours); push!(band, acoustic_N_per_mode(inp, ac, q, ωn; V) / ωn^2)
        push!(table, ValidationTableRow("mode $mode (Q=$q, I=$I)", mode, nasa, ours, ours - nasa, ok))
    end
    series = [PlotSeries("NASA, η_T = 2.0 (CR-172428 p. 85)", :reference_points, xs, ref; panel=1),
              PlotSeries("this code, Eq. (77) at the mode frequency", :computed_points, xs, got; panel=1)]
    r3 = x -> round.(x; digits=4)
    return ValidationCaseResult("APPB_ETA_N_T2", _today_iso(),
        (; criterion="|η_n/NASA − 1| ≤ 10 % at modes 6, 7, 8", date="2026-10-29", ours=r3(got), nasa=ref,
           band_centre=r3(band), n_ok, n=length(xs)),
        table, series, n_ok == length(xs) ? :met : :not_met,
        "$n_ok/$(length(xs)) within ±10 %: ours $(r3(got)) vs NASA $(ref) (trim at the band centre, as the tone sum uses " *
        "it, information: $(r3(band)))", "V-CODE", joinpath(_VAL_REPORT_DIR, _P94_REPORT))
end

function _iso94_validation_cases()
    csv = _r172428_csv("table12_eta_T2_predictions.csv")
    fig = FigureRef("NASA CR-172428", "Table 12 / Fig. 35, p. 85", 86)
    return [
        ValidationCase("R172428_ETAT2", "CR-172428 η_T = 2.0 run: default form vs NASA's Table 12 (94a)", "94", [csv], fig,
            "±3 dB of NASA's Table 12 prediction at ≥ 7 of 9 points (fixed 2026-10-29, before any run).", "2026-10-29",
            "V-CODE", _run_r172428_etat2,
            PlotSpec(; xlabel="tone frequency (Hz)", ylabel="interior SPL (dB)", panel_titles=["R172428_ETAT2"],
                     error_mode=:absolute, error_tol=3.0), ""),
        ValidationCase("APPB_ETA_N_T2", "Cabin-mode η_n at η_T = 2.0 vs CR-172428 p. 85 (94b)", "94",
            [csv, _r172428_csv("appB_acoustic_modes.csv")], fig,
            "|η_n/NASA − 1| ≤ 10 % at App. B modes 6, 7 and 8 (fixed 2026-10-29, before any run).", "2026-10-29",
            "V-CODE", _run_appb_eta_n_t2,
            PlotSpec(; xlabel="App. B cabin mode number", ylabel="η_n", panel_titles=["APPB_ETA_N_T2"],
                     error_mode=:relative_pct, error_tol=10.0, error_ylabel="ours/NASA − 1 (%)"), ""),
    ]
end
