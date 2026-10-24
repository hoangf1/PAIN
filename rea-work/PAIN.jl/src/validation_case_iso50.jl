# Phase 50 — propeller-field coupling for the broadband noise reduction below the changeover.
# Criteria fixed 2026-10-23 (IMPLEMENTATION_PLAN.md §8e Phase 50); implementation decisions fixed the
# same day before any comparison with the TP-2444 noise reduction.

"""
    propeller_field_band_nr(inp, fc; bpf_Hz=200.0, n_freq=11, k_ref=8, L_ref=10) -> NamedTuple

Noise reduction of a 1/3-octave band under propeller excitation from the tone path's own field coupling:
Eq. (8) with the blocked field of harmonic H = clamp(round(fc/bpf), 1, H_max), energy-averaged over
`n_freq` log-spaced frequencies across the band, referred to the blocked mean square A²/2 at the grid
point (k_ref, L_ref): k_p = 8 is the propeller plane, and L = 10 is grid line ℓ = 1 in the App. B array layout
(L = ℓ + 9, θ = 90°, the line nearest the propeller; CR-172428 p. 82). The broadband field is assumed to have the spatial shape of that harmonic (V-ASSUMED).
"""
function propeller_field_band_nr(inp::PainInputs, fc::Real; bpf_Hz::Real=200.0, n_freq::Int=11,
                                 k_ref::Int=8, L_ref::Int=10)
    size(inp.amplitudes, 2) == 19 ||
        error("propeller_field_band_nr: needs the 16 × 19 App. B field layout (L = ℓ + 9); got $(size(inp.amplitudes))")
    H = clamp(round(Int, fc / bpf_Hz), 1, size(inp.amplitudes, 3))
    lo, hi = fc * 2.0^(-1 / 6), fc * 2.0^(1 / 6)
    fs = [lo * (hi / lo)^((j - 0.5) / n_freq) for j in 1:n_freq]
    p2 = sum(f -> tone_mean_square_pressure(inp, H, 2π * f), fs) / n_freq
    p2_ref = inp.amplitudes[k_ref, L_ref, H]^2 / 2
    return (; NR_dB=10 * log10(p2_ref / p2), H, p2, p2_ref, fs)
end

function _run_nr_prop_tp2444_pf()
    fcs = [_p47_fc(k) for k in _P47C_K]
    ext, _ = p47_band_levels(:ext, fcs)
    intr, _ = p47_band_levels(:int, fcs)
    inp = r172428_inputs(4000)
    table = ValidationTableRow[]; meas = Float64[]; got = Float64[]; Hs = Int[]
    n_ok = 0
    for (i, fc) in enumerate(fcs)
        m = ext[i].L_bb - intr[i].L_bb
        r = propeller_field_band_nr(inp, fc)
        ok = abs(r.NR_dB - m) ≤ 5.0
        n_ok += ok
        push!(meas, m); push!(got, r.NR_dB); push!(Hs, r.H)
        push!(table, ValidationTableRow("NR fc=$(round(Int, fc)) (Eq. 8, H$(r.H) field shape)", fc, m, r.NR_dB, r.NR_dB - m, ok))
    end
    n = length(fcs); frac = n_ok / n
    series = [PlotSeries("measured NR (TP-2444 Fig. 17, broadband)", :reference_points, fcs, meas; panel=1),
              PlotSeries("model, propeller-field coupling (Eq. 8 band average)", :computed, fcs, got; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("NR_PROP_TP2444_PF", _today_iso(),
        (; criterion="within ±5 dB in ≥ 75 % of broadband 1/3-octave bands 315–1250 Hz", date="2026-10-23",
           bands_Hz=r2(fcs), NR_meas=r2(meas), NR_model=r2(got), harmonic_shape=Hs, n_ok, n, frac),
        table, series, frac ≥ 0.75 - 1e-12 ? :met : :not_met,
        "$n_ok/$n bands within ±5 dB (propeller-field coupling; field shape of the nearest printed harmonic, V-ASSUMED)",
        "V-EXP", joinpath(_VAL_REPORT_DIR, "phase50_propeller_field_nr.md"))
end

function _iso50_validation_cases()
    return [
        ValidationCase("NR_PROP_TP2444_PF", "TP-2444 NR with propeller-field coupling (Eq. 8 band average) (50b)", "50",
            [_data_path("tp2444", "tp2444_fig17_exterior_passA.csv"), _data_path("tp2444", "tp2444_fig17_interior_passA.csv"),
             _r172428_csv("appB_4000rpm_H1.csv")],
            FigureRef("NASA TP-2444", "Fig. 17", 32),
            "Within ±5 dB in ≥ 75 % of the broadband 1/3-octave bands 315–1250 Hz (as 47c).",
            "2026-10-23", "V-EXP", _run_nr_prop_tp2444_pf,
            PlotSpec(; xlabel="band (Hz)", ylabel="NR (dB)", xscale=:log10, panel_titles=["NR_PROP_TP2444_PF"],
                     error_mode=:absolute, error_tol=5.0), ""),
    ]
end
