# Phase 119 — the T1 family on CR-172428 App. B's printed field (IMPLEMENTATION_PLAN.md §8bi; form and criterion fixed
# 2026-11-02 before any run). App. B prints the blocked field PAIN used for the same article, propeller and rpm (4000 rpm,
# H1–H3, 16 × 19 points); here it replaces E-11's line + GEXT, the input Phase 118a found unprinted. CR-3813's cabin as
# T1 and T1_MEAS_DAMPING ship; T1's gate unchanged. Not held out in full: R172428_EXP already set App. B's field against
# the same measurement (CR-172428's 4000 rpm levels are E-16's means) with CR-172428's cabin.

const _P119_RPM = 4000

"""`inp` with its field replaced by CR-172428 App. B's printed blocked field (both quarters as printed; no blocking)."""
function t1_appb_inputs(inp::PainInputs; rpm::Integer=_P119_RPM)
    f = r172428_appb_field(rpm; z_p=inp.prop.z_p)
    return _with_fields(inp; amplitudes=f.amps, phases=f.phases, pts=f.pts, ΔA=(π * inp.fuse.a / 18)^2)
end

function _p119_result(id, base::PainInputs, label)
    tg = _iso43_t1_targets()
    got = Float64.(interior_spl(t1_appb_inputs(base); bpf_Hz=200.0, n_harmonics=3).harmonic_SPL_dB[1:3])
    table, n_ok = _iso43_t1_gate_table(got, tg.means, tg.lo, tg.hi, tg.nasa)
    xs = [200.0, 400.0, 600.0]
    series = [PlotSeries("E-16 measured mean", :reference_points, xs, tg.means; panel=1),
              PlotSeries("measured range", :reference_band, xs, tg.means; ylow=tg.lo, yhigh=tg.hi, panel=1),
              PlotSeries("NASA PAIN pred (E-16)", :reference_points, xs, tg.nasa; panel=1),
              PlotSeries("$id (App. B field)", :computed, xs, got; panel=1)]
    return ValidationCaseResult(id, _today_iso(),
        (; criterion="T1 gate unchanged (gate A ±4 dB of E-16 mean, or gate B inside envelope and ±4 dB of NASA), H1–H3",
           date="2026-10-20", field="CR-172428 App. B, 4000 rpm (printed blocked field)", H1_H3=round.(got; digits=2), n_ok),
        table, series, n_ok == 3 ? :met : :not_met,
        "$n_ok/3 within T1's gate on App. B's printed field; H1–H3 = $(round.(got; digits=2)) dB vs E-16 means $(tg.means)",
        label, joinpath(_VAL_REPORT_DIR, "phase119_t1_appb.md"))
end

_run_t1_appb() = _p119_result("T1_APPB",
    run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2).inputs,
    "V-EXP (App. B field; field and measurement seen together in R172428_EXP)")

function _run_t1_meas_damping_appb()
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    ηpack = _iso43_eta_n_from_e13(fuse; c0=340.0)
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2,
                          η_n_band=ηpack.η_n_band, η_r_band=_iso43_eta_r_from_e15_meas(), η_r_band_is_prime=true)
    return _p119_result("T1_MEAS_DAMPING_APPB", r.inputs,
        "V-EXP (App. B field, measured damping; field and measurement seen together in R172428_EXP)")
end

function _iso119_validation_cases()
    t1 = _data_path("cr3813", "t1_interior_targets.csv")
    appb = [_r172428_csv("appB_$(_P119_RPM)rpm_H$H.csv") for H in 1:3]
    crit = "T1 gate unchanged (fixed 2026-10-20): H1–H3 each within ±4 dB of the E-16 measured mean (gate A), or inside " *
           "the measured envelope and within ±4 dB of NASA's E-16 prediction (gate B); met if all three (form fixed 2026-11-02)."
    spec(id) = PlotSpec(; xlabel="harmonic band (Hz)", ylabel="interior SPL (dB)", panel_titles=[id],
                        error_mode=:absolute, error_tol=4.0)
    fig = FigureRef("CR-3813 / CR-172428", "Fig. E-16; App. B pp. 193–195 (field)", 142)
    return [
        ValidationCase("T1_APPB", "T1 on CR-172428 App. B's printed field (119)", "119", [t1; appb], fig, crit,
                       "2026-11-02", "V-EXP", _run_t1_appb, spec("T1_APPB"), ""),
        ValidationCase("T1_MEAS_DAMPING_APPB", "T1 with measured damping on App. B's printed field (119)", "119",
                       [t1; appb; _data_path("cr3813", "e13_absorption_targets.csv");
                        _data_path("cr3813", "e15_structural_loss_measured_all.csv")], fig, crit,
                       "2026-11-02", "V-EXP", _run_t1_meas_damping_appb, spec("T1_MEAS_DAMPING_APPB"), ""),
    ]
end
