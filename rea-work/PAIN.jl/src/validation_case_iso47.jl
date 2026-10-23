# Phase 47 — T2 with a measured exterior spectrum of the test article (TP-2444 model 2).
# Criteria fixed 2026-10-23 (IMPLEMENTATION_PLAN.md §8d Phase 47) before any run; the 47b–47d
# implementation decisions were fixed the same day after the 47a digitizing and before any band
# level, noise reduction or interior level was computed (plan, "Implementation decisions").

const _P47_PREF2 = (20e-6)^2

"""
    narrowband_third_octave(f, L, fc; B=5.0, tone_Hz=Float64[], tone_halfwidth_Hz=2B, min_cover=0.4)

1/3-octave band level from a plotted narrowband trace (Phase 47b). The trace (f_Hz, L_dB re 20 µPa,
one value per digitized column) is sampled at bin centres k·B: each bin takes the mean of the
columns within ±B/2. The band holds the bins with centres in [f_c·2^(−1/6), f_c·2^(1/6)).
The total adds every covered bin's mean square. The broadband level fills the tone bins
(within `tone_halfwidth_Hz` of any frequency in `tone_Hz`) with the mean of the kept bins.
Both levels are scaled by bins in band / bins covered when the trace covers only part of the band.
A band with less than `min_cover` coverage returns NaN.
"""
function narrowband_third_octave(f::AbstractVector{<:Real}, L::AbstractVector{<:Real}, fc::Real;
                                 B::Real=5.0, tone_Hz::AbstractVector{<:Real}=Float64[],
                                 tone_halfwidth_Hz::Real=2B, min_cover::Real=0.4)
    lo, hi = fc * 2.0^(-1 / 6), fc * 2.0^(1 / 6)
    ks = ceil(Int, lo / B - 1e-9):(ceil(Int, hi / B - 1e-9) - 1)
    n_bins = length(ks)
    p2_cov = Float64[]; p2_kept = Float64[]; n_tone = 0
    for k in ks
        fk = k * B
        sel = [i for i in eachindex(f) if abs(f[i] - fk) ≤ B / 2]
        isempty(sel) && continue
        p2 = 10.0^(sum(L[sel]) / length(sel) / 10)
        push!(p2_cov, p2)
        if any(t -> abs(fk - t) ≤ tone_halfwidth_Hz, tone_Hz)
            n_tone += 1
        else
            push!(p2_kept, p2)
        end
    end
    n_cov = length(p2_cov)
    cover = n_bins == 0 ? 0.0 : n_cov / n_bins
    if cover < min_cover || isempty(p2_kept)
        return (; fc=float(fc), L_total=NaN, L_bb=NaN, n_bins, n_covered=n_cov, n_tone, cover)
    end
    L_total = 10 * log10(sum(p2_cov) * n_bins / n_cov)
    L_bb = 10 * log10(sum(p2_kept) / length(p2_kept) * n_bins)
    return (; fc=float(fc), L_total, L_bb, n_bins, n_covered=n_cov, n_tone, cover)
end

"""Observed tone peaks: maximum of `L_top` within H·BPF ± 0.15 BPF, H = 1…nH (47a QA rule)."""
function _p47_tone_peaks(f, L_top, bpf::Real, nH::Int)
    out = Float64[]
    for H in 1:nH
        idx = [i for i in eachindex(f) if abs(f[i] - H * bpf) ≤ 0.15 * bpf]
        isempty(idx) || push!(out, f[idx[argmax(L_top[idx])]])
    end
    return out
end

_p47_csv(fig::Symbol, pass::Char) =
    fig === :ext ? _data_path("tp2444", "tp2444_fig17_exterior_pass$(pass).csv") :
    fig === :int ? _data_path("tp2444", "tp2444_fig17_interior_pass$(pass).csv") :
    fig === :f14 ? _data_path("cr172428", "cr172428_fig14_mic1_5000rpm_pass$(pass).csv") :
    error("unknown Phase 47 trace $fig")

"""Band levels of one digitized trace: Fig. 17 exterior/interior (BPF 200 Hz, 4000 rpm) or Fig. 14 (BPF 250 Hz, 5000 rpm)."""
function p47_band_levels(fig::Symbol, fcs::AbstractVector{<:Real}; pass::Char='A', B::Real=5.0)
    c = _read_csv_numeric_nan(_p47_csv(fig, pass))
    bpf, nH = fig === :f14 ? (250.0, 8) : (200.0, 7)
    peaks = _p47_tone_peaks(c[:f_Hz], c[:L_top_dB], bpf, nH)
    tones = vcat([H * bpf for H in 1:nH], peaks)
    return [narrowband_third_octave(c[:f_Hz], c[:L_dB], fc; B, tone_Hz=tones) for fc in fcs], peaks
end

const _P47C_K = -5:1                                         # 315 … 1250 Hz (exact 1000·2^(k/3))
_p47_fc(k) = 1000.0 * 2.0^(k / 3)

"""Model noise reduction of the TP-2444 model 2 article (= CR-172428 article) in band `fc` (47c)."""
function _p47_model_nr(inp::PainInputs, fc::Real)
    xo = volume_crossover_band(inp)
    return noise_reduction_band(inp, fc; crossover_fc=xo.fc_Hz, hf_model=:eq19)
end

function _p47_phase3_inputs(inp::PainInputs)
    p3 = phase3_trim(; a=inp.fuse.a, L=inp.fuse.L, theta0_deg=inp.fuse.theta0_deg, η_lining=1.0)
    return _with_fields(inp; sidewall=p3.sidewall, endplates=p3.ends, mech=p3.mech)
end

function _run_nr_prop_tp2444()
    fcs = [_p47_fc(k) for k in _P47C_K]
    ext, pk_e = p47_band_levels(:ext, fcs)
    intr, pk_i = p47_band_levels(:int, fcs)
    extB, _ = p47_band_levels(:ext, fcs; pass='B')
    intB, _ = p47_band_levels(:int, fcs; pass='B')
    inp = r172428_inputs(4000)
    inp3 = _p47_phase3_inputs(inp)
    xo = volume_crossover_band(inp)
    tol = 5.0
    table = ValidationTableRow[]
    meas = Float64[]; got = Float64[]; got3 = Float64[]; measB = Float64[]
    n_ok = 0; n_strict = 0; ok_strict = 0
    for (i, fc) in enumerate(fcs)
        m = ext[i].L_bb - intr[i].L_bb
        nr = _p47_model_nr(inp, fc)
        g = nr.NR_dB
        g3 = _p47_model_nr(inp3, fc).NR_dB
        ok = isfinite(g) && isfinite(m) && abs(g - m) ≤ tol
        n_ok += ok
        tone_free = !any(H -> fc * 2.0^(-1 / 6) ≤ 200.0H < fc * 2.0^(1 / 6), 1:7)
        if tone_free
            n_strict += 1; ok_strict += ok
        end
        push!(meas, m); push!(got, g); push!(got3, g3); push!(measB, extB[i].L_bb - intB[i].L_bb)
        push!(table, ValidationTableRow("NR fc=$(round(Int, fc))$(nr.hf_model === :eq19 ? " (Eq. 19)" : " (Eq. 18)")" *
                                        (tone_free ? "" : " [band holds a tone; broadband level]"),
                                        fc, m, g, g - m, ok))
    end
    n = length(fcs)
    frac = n_ok / n
    series = [PlotSeries("measured NR (TP-2444 Fig. 17, broadband)", :reference_points, fcs, meas; panel=1),
              PlotSeries("model, CR-172428 App. B trim", :computed, fcs, got; panel=1),
              PlotSeries("model, Phase III trim (no criterion)", :computed, fcs, got3; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("NR_PROP_TP2444", _today_iso(),
        (; criterion="within ±5 dB in ≥ 75 % of broadband 1/3-octave bands 315–1250 Hz", date="2026-10-23",
           bands_Hz=r2(fcs), L_ext_bb=r2([b.L_bb for b in ext]), L_int_bb=r2([b.L_bb for b in intr]),
           NR_meas=r2(meas), NR_meas_passB=r2(measB), NR_model=r2(got), NR_model_phase3=r2(got3),
           changeover_band_Hz=xo.fc_Hz, changeover_f_Hz=xo.f_Hz,
           tone_peaks_ext_Hz=pk_e, tone_peaks_int_Hz=pk_i,
           n_ok, n, frac, strict_n=n_strict, strict_ok=ok_strict, B_Hz=5.0),
        table, series, frac ≥ 0.75 - 1e-12 ? :met : :not_met,
        "$n_ok/$n bands within ±5 dB (CR-172428 App. B trim, card-10 changeover $(round(Int, xo.fc_Hz)) Hz); " *
        "tone-free bands only (315, 500 Hz): $ok_strict/$n_strict. Phase III trim reported, no criterion",
        "V-EXP", joinpath(_VAL_REPORT_DIR, "t2_measured_exterior.md"))
end

"""Fig. 14 broadband slope S = L_bb(2000) − L_bb(1250) (5000 rpm, pass A) and the band rows used."""
function _p47_fig14_slope(; pass::Char='A', B::Real=5.0)
    b, pk = p47_band_levels(:f14, [_p47_fc(1), _p47_fc(2), _p47_fc(3)]; pass, B)
    return (; S=b[3].L_bb - b[1].L_bb, rows=b, peaks=pk)
end

function _run_t2_meas_ext()
    targets = _data_path("cr3813", "t2_third_octave_targets.csv")
    cols = _read_csv_numeric(targets)
    e9 = Dict(cols[:fc_Hz][i] => (cols[:measured_mean_SPL_dB][i], cols[:tol_dB][i]) for i in eachindex(cols[:fc_Hz]))
    r = run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200.0, blocking=R2)
    inp = r.inputs
    bands = resolve_bands(inp)
    f1250 = _p47_fc(1)
    ext = p47_band_levels(:ext, [f1250])[1][1]
    extB = p47_band_levels(:ext, [f1250]; pass='B')[1][1]
    intr = p47_band_levels(:int, [f1250])[1][1]
    sl = _p47_fig14_slope()
    slB = _p47_fig14_slope(; pass='B')
    L_ext = Dict(1250.0 => ext.L_bb, 1600.0 => ext.L_bb + sl.S / 2, 2000.0 => ext.L_bb + sl.S)
    interior(Lx, fc) = 10 * log10(hf_broadband_band_p2(inp, nearest_third_octave(fc, bands),
                                                       _P47_PREF2 * 10^(Lx / 10)) / _P47_PREF2)
    table = ValidationTableRow[]
    got = Float64[]; ref = Float64[]; fcs = [1250.0, 1600.0, 2000.0]
    ok1250 = false
    for fc in fcs
        g = interior(L_ext[fc], fc)
        m, tol = e9[fc]
        ok = isfinite(g) && abs(g - m) ≤ tol
        fc == 1250.0 && (ok1250 = ok)
        push!(got, g); push!(ref, m)
        push!(table, ValidationTableRow("interior fc=$(round(Int, fc)) vs E-9" *
                                        (fc == 1250.0 ? " (measured exterior)" : " (extrapolated exterior)"),
                                        fc, m, g, g - m, ok))
    end
    # secondary: the 1250 Hz interior against TP-2444 Fig. 17's own interior trace (same run), ±3.5 dB
    g2 = got[1]
    push!(table, ValidationTableRow("interior fc=1250 vs TP-2444 Fig. 17 interior (secondary)", 1250.0,
                                    intr.L_bb, g2, g2 - intr.L_bb, abs(g2 - intr.L_bb) ≤ 3.5))
    # sensitivity: B = 2.5 and 10 Hz shift the exterior band level and so the interior level dB for dB
    sens = Dict(Bs => p47_band_levels(:ext, [f1250]; B=Bs)[1][1].L_bb - ext.L_bb for Bs in (2.5, 10.0))
    # information only, added after the first run (post-hoc): the same exterior through the production
    # T2 surrogate (`broadband_cabin_p2`, calibrated bb_j2_scale = 0.5), which is not Eqs. (19)–(23)
    surrogate = 10 * log10(broadband_cabin_p2(inp, nearest_third_octave(f1250, bands),
                                              _P47_PREF2 * 10^(ext.L_bb / 10); j2_scale=0.5) / _P47_PREF2)
    # and T2's own modelled blocked broadband level in the band (Spbl ∝ f^−2 anchored on the H3 tone)
    modelled_bl = 10 * log10(blocked_broadband_band_p2(inp, nearest_third_octave(f1250, bands), 200.0) / _P47_PREF2)
    # 47e consistency loop (no criterion): E-9 interior + model NR of the article vs the measured/extrapolated exterior
    inp_a = r172428_inputs(4000)
    loop = [(; fc, ext=L_ext[fc], e9_plus_nr=e9[fc][1] + _p47_model_nr(inp_a, nearest_third_octave(fc, resolve_bands(inp_a))).NR_dB)
            for fc in fcs]
    series = [PlotSeries("Fig. E-9 measured mean", :reference_points, fcs, ref; panel=1),
              PlotSeries("±3.5 dB", :reference_band, fcs, ref; ylow=ref .- 3.5, yhigh=ref .+ 3.5, panel=1),
              PlotSeries("T2 Eqs. 19–23 with TP-2444 exterior (1600/2000 extrapolated)", :computed, fcs, got; panel=1)]
    r2 = x -> round(x; digits=2)
    return ValidationCaseResult("T2_MEAS_EXT", _today_iso(),
        (; criterion="1250 Hz interior within ±3.5 dB of Fig. E-9 (51.0 dB); 1600/2000 Hz same gate, extrapolated exterior",
           date="2026-10-23", L_ext_1250_bb=r2(ext.L_bb), L_ext_1250_total=r2(ext.L_total),
           L_ext_1250_bb_passB=r2(extB.L_bb), fig14_slope_dB=r2(sl.S), fig14_slope_passB_dB=r2(slB.S),
           fig14_cover_2000=r2(sl.rows[3].cover), L_int_fig17_1250_bb=r2(intr.L_bb),
           interior_dB=r2.(got), interior_total_ext_1250=r2(interior(ext.L_total, 1250.0)),
           B_sensitivity_dB=Dict(k => r2(v) for (k, v) in sens),
           surrogate_interior_1250_posthoc=r2(surrogate), t2_modelled_blocked_1250_posthoc=r2(modelled_bl),
           loop_47e=[(; fc=l.fc, ext=r2(l.ext), e9_plus_nr=r2(l.e9_plus_nr), diff=r2(l.e9_plus_nr - l.ext)) for l in loop],
           csv=targets),
        table, series, ok1250 ? :met : :not_met,
        "1250 Hz: $(r2(got[1])) dB vs E-9 51.0 (±3.5) from the measured exterior $(r2(ext.L_bb)) dB (broadband, B = 5 Hz assumed); " *
        "1600/2000 Hz (extrapolated exterior, Fig. 14 slope $(r2(sl.S)) dB): $(r2(got[2])), $(r2(got[3])) dB vs 46.0, 41.5. " *
        "Secondary vs Fig. 17 interior $(r2(intr.L_bb)) dB",
        "V-EXP", joinpath(_VAL_REPORT_DIR, "t2_measured_exterior.md"))
end

function _iso47_validation_cases()
    f17 = [_data_path("tp2444", "tp2444_fig17_exterior_passA.csv"), _data_path("tp2444", "tp2444_fig17_interior_passA.csv")]
    return [
        ValidationCase("NR_PROP_TP2444", "TP-2444 model 2: measured propeller-noise NR vs model (47c)", "47",
            vcat(f17, [_r172428_csv("appB_trim.csv")]), FigureRef("NASA TP-2444", "Fig. 17", 32),
            "Within ±5 dB in ≥ 75 % of the broadband 1/3-octave bands 315–1250 Hz (tones removed, B = 5 Hz assumed).",
            "2026-10-23", "V-EXP", _run_nr_prop_tp2444,
            PlotSpec(; xlabel="band (Hz)", ylabel="NR (dB)", xscale=:log10,
                     panel_titles=["NR_PROP_TP2444"], error_mode=:absolute, error_tol=5.0), ""),
        ValidationCase("T2_MEAS_EXT", "T2 with the measured TP-2444 exterior spectrum (47d)", "47",
            vcat(f17, [_data_path("cr172428", "cr172428_fig14_mic1_5000rpm_passA.csv"),
                       _data_path("cr3813", "t2_third_octave_targets.csv")]),
            FigureRef("CR-3813", "Fig. E-9", 132),
            "1250 Hz interior within ±3.5 dB of Fig. E-9 (51.0 dB) from the measured exterior; 1600/2000 Hz same gate, " *
            "labelled extrapolated exterior; secondary: Fig. 17 interior ±3.5 dB.",
            "2026-10-23", "V-EXP", _run_t2_meas_ext,
            PlotSpec(; xlabel="1/3-octave band (Hz)", ylabel="SPL (dB)", xscale=:log10, xlim=(1000.0, 2600.0),
                     panel_titles=["T2_MEAS_EXT"], error_mode=:absolute, error_tol=3.5), ""),
    ]
end
