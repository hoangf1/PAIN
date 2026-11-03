# Phase 45 — T2's high-frequency path (Eqs. 19–23) on the TP-1964 bare cylinder.
# Criteria pre-registered 2026-10-23 before any run (IMPLEMENTATION_PLAN.md §8c, commit 9ffb107).

"""
    tp1964_hf_inputs(setup) -> PainInputs

The TP-1964 bare cylinder as a PAIN cabin for Eqs. (19)–(23): no floor (θ₀ = 0, so V = πR²L,
S = 2πRL + 2πR², A′ = Ā = 2πRL), no trim, Donnell shell modes, surface mass ρt, and the measured
band loss factors (η = 2.2/(f T₆₀), η_r′ taken as the measured total). The acoustic-mode and
propeller fields are not used by Eqs. (19)–(23) and are left empty.
"""
function tp1964_hf_inputs(setup)
    fuse = FuselageGeometry(setup.L, setup.R, 0.0)
    prop = PropellerPlacement(setup.R + 0.5, 90.0, setup.L / 2)
    pts = grid_points(fuse, prop, GridSpec())
    acoustic = Cyl2DResult(0.0, AcousticMode[], "not used by Eqs. (19)–(23)", 10, 0.1, setup.c0)
    toc = third_octave_centers()
    η_n = Dict(fc => setup.η_n_of(fc) for fc in toc)
    η_r = Dict(fc => setup.η_r_of(fc) for fc in toc)
    return PainInputs(fuse, prop, setup.structural, acoustic, zeros(16, 10, 1), zeros(16, 10, 1), pts,
                      (π * setup.R / 18)^2; m_wall=setup.m_wall, c0=setup.c0, L_c=setup.L,
                      η_n_band=η_n, η_r_band=η_r, η_r_band_is_prime=true)
end

function _iso45_run_nr_tp1964_xover(vs::Symbol)
    setup = _iso43_tp1964_setup()
    inp = tp1964_hf_inputs(setup)
    xo = volume_crossover_band(inp)
    fig = _read_csv_numeric_nan(_iso43_data("tp1964", "tp1964_fig8_noise_reduction.csv"))
    bands = Float64[]; ref = Float64[]
    for i in eachindex(fig[:f_Hz])
        f = float(fig[:f_Hz][i])
        (100.0 - 1e-9 ≤ f ≤ 5000.0 + 1e-9) || continue
        v = vs === :meas ? fig[:nr_meas_dB][i] : fig[:nr_pred_ref2_dB][i]
        isfinite(v) || continue
        push!(bands, f); push!(ref, v)
    end
    # changeover band: the band of the figure's list that contains f (nominal centres; the band
    # list of `volume_crossover_band` uses exact centres, e.g. 2520 for the nominal 2500 Hz band)
    xfc = something(containing_third_octave(xo.f_Hz, bands), xo.fc_Hz)
    tol = vs === :meas ? 5.0 : 3.0
    table = ValidationTableRow[]
    got = Float64[]
    n_ok = 0; n_hi = 0; ok_hi = 0
    for (i, fc) in enumerate(bands)
        above = fc ≥ xfc - 1e-9
        g = if above
            hf_pressure_ratio(inp, fc).NR_dB
        else
            noise_reduction_band_circular(fc, setup.structural, setup.acoustic; R=setup.R, L=setup.L,
                                          m_wall=setup.m_wall, η_n=setup.η_n_of(fc), η_r=setup.η_r_of(fc),
                                          c_int=setup.c0, c_ext=setup.c0).NR_dB
        end
        ok = isfinite(g) && abs(g - ref[i]) ≤ tol
        n_ok += ok
        if above
            n_hi += 1; ok_hi += ok
        end
        push!(got, g)
        push!(table, ValidationTableRow("NR fc=$(round(Int, fc))$(above ? " (Eq. 19)" : " (Eq. 18)")", fc,
                                        ref[i], g, g - ref[i], ok))
    end
    n = length(bands)
    frac = n_ok / max(n, 1)
    id = vs === :meas ? "NR_TP1964_XOVER" : "NR_TP1964_XOVER_REF2"
    label = vs === :meas ? "V-EXP" : "V-CODE"
    series = [PlotSeries(vs === :meas ? "measured Fig. 8" : "NASA pred. ref. 2", :reference_points, bands, ref; panel=1),
              PlotSeries("PAIN Eq. (18) / Eqs. (19)–(23)", :computed, bands, got; panel=1)]
    return ValidationCaseResult(id, _today_iso(),
        (; criterion="within ±$(tol) dB in ≥ 75 % of bands 100–5000 Hz", date="2026-10-23",
           changeover_f_Hz=xo.f_Hz, changeover_band_Hz=xfc, n_ok, n, frac, n_above=n_hi, ok_above=ok_hi),
        table, series, frac ≥ 0.75 - 1e-12 ? :met : :not_met,
        "$n_ok/$n ($(round(100 * frac; digits=1)) %) within ±$(tol) dB; at/above the changeover band " *
        "$(round(Int, xfc)) Hz (f = $(round(xo.f_Hz; digits=0)) Hz): $ok_hi/$n_hi", label, "")
end

_run_nr_tp1964_xover() = _iso45_run_nr_tp1964_xover(:meas)
_run_nr_tp1964_xover_ref2() = _iso45_run_nr_tp1964_xover(:pred)

function _iso45_validation_cases()
    files = [_iso43_data("tp1964", "tp1964_fig8_noise_reduction.csv"),
             _iso43_data("tp1964", "tp1964_fig17_reverberation.csv")]
    return [
        ValidationCase("NR_TP1964_XOVER", "TP-1964 bare-cylinder NR with PAIN's changeover to Eqs. (19)–(23) (45a)", "45",
            files, FigureRef("NASA TP-1964", "Fig. 8 measured", 22),
            "Within ±5 dB in ≥ 75 % of 1/3-octave bands 100–5000 Hz vs measured.",
            "2026-10-23", "V-EXP", _run_nr_tp1964_xover,
            PlotSpec(; xlabel="band (Hz)", ylabel="NR (dB)", xscale=:log10,
                     panel_titles=["NR_TP1964_XOVER"], error_mode=:absolute, error_tol=5.0), ""),
        ValidationCase("NR_TP1964_XOVER_REF2", "TP-1964 NR with changeover vs NASA ref. 2 (45b)", "45",
            files, FigureRef("NASA TP-1964", "Fig. 8 predicted (ref. 2)", 22),
            "Within ±3 dB in ≥ 75 % of 1/3-octave bands 100–5000 Hz vs NASA predicted curve.",
            "2026-10-23", "V-CODE", _run_nr_tp1964_xover_ref2,
            PlotSpec(; xlabel="band (Hz)", ylabel="NR (dB)", xscale=:log10,
                     panel_titles=["NR_TP1964_XOVER_REF2"], error_mode=:absolute, error_tol=3.0), ""),
    ]
end
