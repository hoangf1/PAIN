# Phase 43 — T1/T2 root causes and bare-cylinder validation (criteria dated 2026-10-23).
# Cases: T1_MEAS_DAMPING (43b), H3_ATTRIB (43c diagnostic), NR_TP1964 / NR_TP1964_REF2 (43d),
# T1_F1A_FILL (43f). 43a changeover is a default-input correction; 43e is a §2.13 note.

# --- helpers -----------------------------------------------------------------

function _iso43_data(parts...)
    return _data_path(parts...)
end

"""η_n = c₀ S α / (4 ω V) from Fig. E-13 α; S = absorbing area S_side + 2 S_e (Eq. 24 / hf path)."""
function _iso43_eta_n_from_e13(fuse::FuselageGeometry; L_c=fuse.L, c0::Real=340.0)
    areas = hf_absorbing_areas(fuse; L_c=L_c)
    path = _iso43_data("cr3813", "e13_absorption_targets.csv")
    cols = _read_csv_numeric(path)
    η = Dict{Float64,Float64}()
    toc = third_octave_centers()
    for i in eachindex(cols[:f_Hz])
        f = float(cols[:f_Hz][i])
        α = float(cols[:alpha_meas][i])
        ω = 2π * f
        ηn = c0 * areas.S * α / (4 * ω * areas.V)
        fc = nearest_third_octave(f, toc)
        η[fc] = ηn
    end
    return (; η_n_band=η, S=areas.S, S_side=areas.S_side, S_e=areas.S_e, V=areas.V,
            S_note="S = S_sidewall + 2 S_e (CR-3813 absorbing area of Eq. 24 / list of symbols S, Se; " *
                   "same as hf_absorbing_areas). Near Eq. (24)/(78) the report uses this absorbing " *
                   "surface, not a separate total-interior figure.")
end

"""η_r′ from e15_structural_loss_measured_all.csv; log-log in f, ends held; keyed by 1/3-oct centres."""
function _iso43_eta_r_from_e15_meas()
    path = _iso43_data("cr3813", "e15_structural_loss_measured_all.csv")
    cols = _read_csv_numeric(path)
    f_s = Float64.(cols[:f_Hz])
    η_s = Float64.(cols[:eta_meas])
    p = sortperm(f_s)
    f_s, η_s = f_s[p], η_s[p]
    η = Dict{Float64,Float64}()
    for fc in third_octave_centers()
        η[fc] = loglog_interp_eta(fc, f_s, η_s)
    end
    return η
end

function _iso43_eta_from_csv_col(path, f_col::Symbol, η_col::Symbol)
    cols = _read_csv_numeric(path)
    f_s = Float64.(cols[f_col])
    η_s = Float64.(cols[η_col])
    p = sortperm(f_s)
    f_s, η_s = f_s[p], η_s[p]
    η = Dict{Float64,Float64}()
    for fc in third_octave_centers()
        η[fc] = loglog_interp_eta(fc, f_s, η_s)
    end
    return η
end

"""Full-grid F1A of the test-article propeller (same JSON as compare_gext_vs_f1a_grid.jl)."""
function _iso43_f1a_grid(; n_harmonics::Int=3)
    # @__DIR__ = .../PAIN.jl/src → examples live in .../PAIN.jl/examples
    json = normpath(joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json"))
    isfile(json) || error("F1A fill: missing aircraft JSON at $json")
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    return propeller_freefield_grid(json, fuse, prop, GridSpec(); n_harmonics=n_harmonics, num_src_times=32)
end

function _iso43_t1_gate_table(got::Vector{Float64}, means, lo, hi, nasa; tol=4.0)
    table = ValidationTableRow[]
    n_ok = 0
    for i in 1:min(3, length(got))
        g = got[i]
        ok_A = abs(g - means[i]) ≤ tol
        ok_B = (lo[i] ≤ g ≤ hi[i]) && abs(g - nasa[i]) ≤ tol
        ok = ok_A || ok_B
        n_ok += ok
        push!(table, ValidationTableRow("H$i vs measured mean (gate A: ±4 dB)", Float64(i * 200),
                                        means[i], g, g - means[i], ok_A))
        push!(table, ValidationTableRow("H$i vs NASA PAIN, inside envelope (gate B)", Float64(i * 200),
                                        nasa[i], g, g - nasa[i], ok_B))
    end
    return table, n_ok
end

function _iso43_t1_targets()
    cols = _read_csv_numeric(_iso43_data("cr3813", "t1_interior_targets.csv"))
    means = Float64[cols[:measured_mean_SPL_dB][i] for i in 1:3]
    lo = Float64[cols[:measured_low_dB][i] for i in 1:3]
    hi = Float64[cols[:measured_high_dB][i] for i in 1:3]
    nasa = Float64[cols[:nasa_pain_pred_dB][i] for i in 1:3]
    return (; means, lo, hi, nasa)
end

# --- 43b T1_MEAS_DAMPING -----------------------------------------------------

function _run_t1_meas_damping()
    tg = _iso43_t1_targets()
    L = test_article_length()
    fuse = FuselageGeometry(L, 0.508, 56.6)
    ηpack = _iso43_eta_n_from_e13(fuse; c0=340.0)
    η_r = _iso43_eta_r_from_e15_meas()
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2,
                          η_n_band=ηpack.η_n_band, η_r_band=η_r,
                          η_r_band_is_prime=true)
    got = Float64.(r.spectrum.harmonic_SPL_dB[1:3])
    table, n_ok = _iso43_t1_gate_table(got, tg.means, tg.lo, tg.hi, tg.nasa)
    toc = third_octave_centers()
    fc200 = nearest_third_octave(200.0, toc)
    fc400 = nearest_third_octave(400.0, toc)
    fc600 = nearest_third_octave(600.0, toc)
    ηn_used = (get(ηpack.η_n_band, fc200, NaN), get(ηpack.η_n_band, fc400, NaN),
               get(ηpack.η_n_band, fc600, NaN))
    ηr_used = (get(η_r, fc200, NaN), get(η_r, fc400, NaN), get(η_r, fc600, NaN))
    # η values used are inputs: echoed below, not table rows (rows are criterion checks only).
    xs = [200.0, 400.0, 600.0]
    series = [
        PlotSeries("E-16 measured mean", :reference_points, xs, tg.means; panel=1),
        PlotSeries("T1_MEAS_DAMPING", :computed, xs, got; panel=1),
        PlotSeries("gate ±4 dB", :reference_band, xs, tg.means;
                   ylow=tg.means .- 4, yhigh=tg.means .+ 4, panel=1),
    ]
    all_ok = n_ok == 3
    return ValidationCaseResult(
        "T1_MEAS_DAMPING", _today_iso(),
        (; criterion="T1 gate unchanged (±4 dB of measured mean, H1–H3)", date="2026-10-23",
         S=ηpack.S, S_note=ηpack.S_note, V=ηpack.V,
         η_n_200=ηn_used[1], η_n_400=ηn_used[2], η_n_600=ηn_used[3],
         η_r_200=ηr_used[1], η_r_400=ηr_used[2], η_r_600=ηr_used[3],
         H1_H3=got),
        table, series, all_ok ? :met : :not_met,
        "$n_ok/3 within T1 gate; H1–H3 = $(round.(got; digits=2)) dB; " *
        "η_n(200/400/600)=$(round.(ηn_used; digits=4)); " *
        "η_r′=$(round.(ηr_used; digits=4)); S=$(round(ηpack.S; digits=3)) m²",
        "V-EXP (measured damping)", "",
    )
end

# --- 43c H3 attribution (diagnostic) -----------------------------------------

const _H3_LABELS = ["baseline REPRO_18b", "η_n := E-14 calc (η_T=0.5)", "η_r′ := E-15 calc (η_T=0.5)",
                    "both η_n + η_r′", "ℓ=1 := measured E-12 (as T1_FROM_E12)"]

function _run_h3_attrib()
    # REPRO_18b conditions: ANOPP Table 8, R1, Phase III η_T=0.5, no η_r cap, GEXT
    paths = default_e11_paths()
    p3 = phase3_trim(; η_lining=0.5)
    base = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3,
                             bpf_Hz=200.0, blocking=R1,
                             sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends, mech=p3.mech)
    base_spl = Float64.(base.spectrum.harmonic_SPL_dB[1:3])

    η_n_nasa = _iso43_eta_from_csv_col(_iso43_data("cr3813", "e14_acoustic_loss_calculated.csv"),
                                       :f_Hz, :eta_calc_trim0p5)
    η_r_nasa = _iso43_eta_from_csv_col(_iso43_data("cr3813", "e15_structural_loss_calculated.csv"),
                                       :f_Hz, :eta_calc_trim0p5)

    function _spl_with(; η_n_band=nothing, η_r_band=nothing, from_e12::Bool=false)
        if from_e12
            # Same cabin as T1_FROM_E12 but REPRO free-field/blocking base replaced on ℓ=1
            r_e12 = run_validation_case("T1_FROM_E12")
            # Use a dedicated rebuild: measured E-12 on REPRO pipeline geometry
            return _iso43_repro_from_e12()
        end
        r = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3,
                              bpf_Hz=200.0, blocking=R1,
                              sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends, mech=p3.mech,
                              η_n_band=η_n_band, η_r_band=η_r_band)
        return Float64.(r.spectrum.harmonic_SPL_dB[1:3])
    end

    s_ηn = _spl_with(; η_n_band=η_n_nasa)
    s_ηr = _spl_with(; η_r_band=η_r_nasa)
    s_both = _spl_with(; η_n_band=η_n_nasa, η_r_band=η_r_nasa)
    s_e12 = _iso43_repro_from_e12()

    labels = _H3_LABELS
    spls = [base_spl, s_ηn, s_ηr, s_both, s_e12]
    table = ValidationTableRow[]
    for (lab, s) in zip(labels, spls)
        for H in 1:3
            d = s[H] - base_spl[H]
            push!(table, ValidationTableRow("$lab H$H", Float64(H), base_spl[H], s[H], d, true))
        end
    end
    xs = [1.0, 2.0, 3.0]
    series = [
        PlotSeries("baseline", :reference_points, xs, base_spl; panel=1),
        PlotSeries("η_n E-14", :computed, xs, s_ηn; panel=1),
        PlotSeries("η_r′ E-15", :computed, xs, s_ηr; panel=1),
        PlotSeries("both", :computed, xs, s_both; panel=1),
        PlotSeries("E-12 ℓ=1", :computed, xs, s_e12; panel=1),
    ]
    return ValidationCaseResult(
        "H3_ATTRIB", _today_iso(),
        (; criterion="none (diagnostic)", date="2026-10-23",
         baseline=base_spl, eta_n=s_ηn, eta_r=s_ηr, both=s_both, e12=s_e12),
        table, series, :no_verdict,
        "diagnostic; baseline H1–H3=$(round.(base_spl; digits=2)); " *
        "ΔH3: η_n=$(round(s_ηn[3]-base_spl[3]; digits=2)), " *
        "η_r=$(round(s_ηr[3]-base_spl[3]; digits=2)), " *
        "both=$(round(s_both[3]-base_spl[3]; digits=2)), " *
        "E12=$(round(s_e12[3]-base_spl[3]; digits=2))",
        "diagnostic", "",
    )
end

"""REPRO_18b cabin with ℓ=1 blocked levels from measured E-12 (same coverage rule as T1_FROM_E12)."""
function _iso43_repro_from_e12()
    L = test_article_length()
    fuse = FuselageGeometry(L, 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    spec = GridSpec()
    paths = default_e11_paths()
    bpf, nH, D = 200.0, 3, 0.762
    p3 = phase3_trim(; η_lining=0.5)
    ff = freefield_from_e11_csv(paths.anopp_spl, paths.phases, fuse, prop, spec;
                                bpf_Hz=bpf, n_harmonics=nH, anopp_spl_csv=paths.anopp_spl)
    bl = apply_blocking(ff, fuse, prop; variant=R1)
    e12 = PAIN._iso41_e12_measured_curve()
    line_amps = zeros(spec.k_max, nH)
    line_phases = zeros(spec.k_max, nH)
    for p in bl.pts
        p.ell == 1 || continue
        xD = p.x3 / D
        for H in 1:nH
            line_phases[p.k, H] = bl.phases[p.k, p.ell, H]
            ref_pts = get(e12, H, Tuple{Float64,Float64}[])
            spl = PAIN._iso41_e12_interp(ref_pts, xD)
            line_amps[p.k, H] = isfinite(spl) ? spl_dB_to_peak_Pa(spl) : bl.amplitudes[p.k, p.ell, H]
        end
    end
    ωH = [2π * H * bpf for H in 1:nH]
    amps, phases = extend_line_to_grid(line_amps, line_phases, bl.pts; omega_H=ωH)
    acoustic = cyl2d_modes(56.6; n_modes=20, NY=10)
    structural = structural_modes_from_table_d1(; n_keep=32)
    ΔA = (π * 0.508 / 18)^2
    inp = PainInputs(fuse, prop, structural, acoustic, amps, phases, bl.pts, ΔA;
                     sidewall=p3.sidewall, endplates=p3.ends, mech=p3.mech, m_wall=p3.m_wall)
    spec_out = interior_spl(inp; bpf_Hz=bpf, n_harmonics=nH)
    return Float64.(spec_out.harmonic_SPL_dB[1:3])
end

# --- 43d NR_TP1964 -----------------------------------------------------------

function _iso43_tp1964_setup()
    R, L = 0.252, 1.193
    t, E, ν, ρ = 0.00163, 6.89e10, 0.3, 2710.0
    c0 = 343.0
    m_wall = ρ * t
    # Modes through 6 kHz (criterion bands to 5 kHz); every mode enters each band sum.
    structural = donnell_shell_modes(R, L, t, E, ν, ρ; f_max_Hz=6000.0, m_max=30, n_max=30)
    acoustic = circular_cavity_modes(R, L; c0=c0, f_max_Hz=6000.0, m_max=16, k_max=10, q_max=30)
    rev = _iso43_data("tp1964", "tp1964_fig17_reverberation.csv")
    η_n_of = fc -> eta_from_reverberation_csv(rev, "acoustic", fc)
    η_r_of = fc -> eta_from_reverberation_csv(rev, "structural", fc)
    return (; R, L, t, E, ν, ρ, c0, m_wall, structural, acoustic, η_n_of, η_r_of)
end

function _iso43_run_nr_tp1964(vs::Symbol)
    # vs = :meas → V-EXP ±5 dB ≥75% of 100–5000 Hz; :pred → V-CODE ±3 dB ≥75%
    setup = _iso43_tp1964_setup()
    fig = _read_csv_numeric_nan(_iso43_data("tp1964", "tp1964_fig8_noise_reduction.csv"))
    bands = Float64[]
    ref = Float64[]
    for i in eachindex(fig[:f_Hz])
        f = float(fig[:f_Hz][i])
        (100.0 - 1e-9 ≤ f ≤ 5000.0 + 1e-9) || continue
        v = vs === :meas ? fig[:nr_meas_dB][i] : fig[:nr_pred_ref2_dB][i]
        (v isa Real && isfinite(float(v))) || continue
        push!(bands, f)
        push!(ref, float(v))
    end
    spec = noise_reduction_spectrum_circular(setup.structural, setup.acoustic, bands;
                                             R=setup.R, L=setup.L, m_wall=setup.m_wall,
                                             η_n_of=setup.η_n_of, η_r_of=setup.η_r_of,
                                             c_int=setup.c0, c_ext=setup.c0)
    tol = vs === :meas ? 5.0 : 3.0
    table = ValidationTableRow[]
    n_ok = 0
    got = Float64[]
    for (i, fc) in enumerate(bands)
        g = spec.rows[i].NR_dB
        # No modal coupling → Eq. (18) ratio = 0 → NR = +Inf (count as fail; residual capped for tables)
        g_tab = isfinite(g) ? g : (g > 0 ? 200.0 : -200.0)
        push!(got, g_tab)
        d = g_tab - ref[i]
        ok = isfinite(g) && abs(g - ref[i]) ≤ tol
        n_ok += ok
        push!(table, ValidationTableRow("NR fc=$(round(Int,fc))", fc, ref[i], g_tab, d, ok))
    end
    n = length(bands)
    frac = n_ok / max(n, 1)
    met = frac ≥ 0.75 - 1e-12
    id = vs === :meas ? "NR_TP1964" : "NR_TP1964_REF2"
    label = vs === :meas ? "V-EXP" : "V-CODE"
    all_f = Float64.(fig[:f_Hz])
    all_meas = Float64[x isa Real && isfinite(float(x)) ? float(x) : NaN for x in fig[:nr_meas_dB]]
    all_pred = Float64[x isa Real && isfinite(float(x)) ? float(x) : NaN for x in fig[:nr_pred_ref2_dB]]
    series = [
        PlotSeries("measured Fig.8", :reference_points, all_f, all_meas; panel=1),
        PlotSeries("NASA pred ref.2", :reference_curve, all_f, all_pred; panel=1),
        PlotSeries("PAIN Eq.(18)", :computed, bands, got; panel=1),
    ]
    return ValidationCaseResult(
        id, _today_iso(),
        (; criterion=vs === :meas ?
            "within ±5 dB in ≥75% of bands 100–5000 Hz vs measured" :
            "within ±3 dB in ≥75% of bands 100–5000 Hz vs NASA ref.2",
         date="2026-10-23", R=setup.R, L=setup.L, t=setup.t, n_ok, n, frac,
         n_struct=length(setup.structural.modes), n_ac=length(setup.acoustic)),
        table, series, met ? :met : :not_met,
        "$n_ok/$n ($(round(100*frac; digits=1))%) within ±$(tol) dB ($label)",
        label, "",
    )
end

_run_nr_tp1964() = _iso43_run_nr_tp1964(:meas)
_run_nr_tp1964_ref2() = _iso43_run_nr_tp1964(:pred)

# --- 43f T1_F1A_FILL ---------------------------------------------------------

function _run_t1_f1a_fill()
    tg = _iso43_t1_targets()
    ff_f1a = _iso43_f1a_grid(; n_harmonics=3)
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2,
                          grid_fill=:f1a_relative,
                          f1a_pattern_amps=ff_f1a.amplitudes,
                          f1a_pattern_phases=ff_f1a.phases)
    got = Float64.(r.spectrum.harmonic_SPL_dB[1:3])
    r_t1 = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    t1 = Float64.(r_t1.spectrum.harmonic_SPL_dB[1:3])
    table, n_ok = _iso43_t1_gate_table(got, tg.means, tg.lo, tg.hi, tg.nasa)
    # T1 (GEXT) levels are echoed in the inputs and plotted, not counted as criterion rows.
    xs = [200.0, 400.0, 600.0]
    series = [
        PlotSeries("E-16 mean", :reference_points, xs, tg.means; panel=1),
        PlotSeries("T1_F1A_FILL", :computed, xs, got; panel=1),
        PlotSeries("T1 GEXT", :computed_points, xs, t1; panel=1),
        PlotSeries("gate ±4 dB", :reference_band, xs, tg.means;
                   ylow=tg.means .- 4, yhigh=tg.means .+ 4, panel=1),
    ]
    return ValidationCaseResult(
        "T1_F1A_FILL", _today_iso(),
        (; criterion="T1 gate unchanged", date="2026-10-23",
         H1_H3=got, H1_H3_T1=t1, fill="F1A-relative off-line"),
        table, series, n_ok == 3 ? :met : :not_met,
        "$n_ok/3 within T1 gate; H1–H3 = $(round.(got; digits=2)) (T1 = $(round.(t1; digits=2)))",
        "V-EXP (F1A-shaped off-line field)", "",
    )
end

"""43b+43f diagnostic (no criterion): measured damping + F1A fill."""
function _run_t1_f1a_meas_damping_diag()
    tg = _iso43_t1_targets()
    L = test_article_length()
    fuse = FuselageGeometry(L, 0.508, 56.6)
    ηpack = _iso43_eta_n_from_e13(fuse; c0=340.0)
    η_r = _iso43_eta_r_from_e15_meas()
    ff_f1a = _iso43_f1a_grid(; n_harmonics=3)
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2,
                          η_n_band=ηpack.η_n_band, η_r_band=η_r,
                          η_r_band_is_prime=true,
                          grid_fill=:f1a_relative,
                          f1a_pattern_amps=ff_f1a.amplitudes,
                          f1a_pattern_phases=ff_f1a.phases)
    got = Float64.(r.spectrum.harmonic_SPL_dB[1:3])
    table = ValidationTableRow[]
    for H in 1:3
        push!(table, ValidationTableRow("H$H (diagnostic)", Float64(H),
                                        tg.means[H], got[H], got[H] - tg.means[H], true))
    end
    return ValidationCaseResult(
        "T1_F1A_MEAS_DAMP", _today_iso(),
        (; criterion="none (diagnostic 43b+43f)", date="2026-10-23", H1_H3=got),
        table,
        [PlotSeries("E-16 mean", :reference_points, [200.0,400.0,600.0], tg.means; panel=1),
         PlotSeries("F1A+meas damp", :computed, [200.0,400.0,600.0], got; panel=1)],
        :no_verdict,
        "diagnostic H1–H3 = $(round.(got; digits=2)) dB (no criterion)",
        "diagnostic", "",
    )
end

# --- 43a post-hoc re-run recorder (not a gated case; used by testset) ---------

function _iso43_changeover_report()
    L = test_article_length()
    fuse = FuselageGeometry(L, 0.508, 56.6)
    # Build a bare inputs for volume / ten-mode
    r0 = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, trim=:phase3)
    inp = r0.inputs
    f_vol = volume_crossover_frequency_Hz(inp)
    xvol = acoustic_crossover_band(inp; rule=:volume)
    xten = acoustic_crossover_band(inp; rule=:ten_modes)
    # :auto under old (ten-mode) vs new (volume) crossover
    function auto_spl(rule)
        x = acoustic_crossover_band(inp; rule=rule).fc_Hz
        # force via PainInputs crossover_band_Hz
        inp2 = PainInputs(inp.fuse, inp.prop, inp.structural, inp.acoustic,
                          inp.amplitudes, inp.phases, inp.pts, inp.ΔA;
                          sidewall=inp.sidewall, endplates=inp.endplates, mech=inp.mech,
                          m_wall=inp.m_wall, crossover_band_Hz=x)
        spec = interior_spl(inp2; bpf_Hz=200.0, n_harmonics=3, broadband=false, tone_model=:auto)
        return Float64.(spec.harmonic_SPL_dB[1:3]), x
    end
    # T1 path (R2)
    r_t1 = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    t1_eq8 = Float64.(r_t1.spectrum.harmonic_SPL_dB[1:3])
    paths = default_e11_paths()
    p3 = phase3_trim(; η_lining=0.5)
    r18 = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3,
                            bpf_Hz=200.0, blocking=R1,
                            sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends, mech=p3.mech)
    function auto_on(r; rule)
        x = acoustic_crossover_band(r.inputs; rule=rule).fc_Hz
        inp2 = PainInputs(r.inputs.fuse, r.inputs.prop, r.inputs.structural, r.inputs.acoustic,
                          r.inputs.amplitudes, r.inputs.phases, r.inputs.pts, r.inputs.ΔA;
                          sidewall=r.inputs.sidewall, endplates=r.inputs.endplates, mech=r.inputs.mech,
                          m_wall=r.inputs.m_wall, crossover_band_Hz=x)
        return Float64.(interior_spl(inp2; bpf_Hz=200.0, n_harmonics=3, broadband=false,
                                     tone_model=:auto).harmonic_SPL_dB[1:3]), x
    end
    t1_old, x_t1_old = auto_on(r_t1; rule=:ten_modes)
    t1_new, x_t1_new = auto_on(r_t1; rule=:volume)
    r18_old, x18_old = auto_on(r18; rule=:ten_modes)
    r18_new, x18_new = auto_on(r18; rule=:volume)
    # E18 with η_T=1, cap 0.15
    p3b = phase3_trim(; η_lining=1.0)
    r_e18 = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3,
                              bpf_Hz=200.0, blocking=R1,
                              sidewall_trim_stack=p3b.sidewall, end_trim_stack=p3b.ends, mech=p3b.mech)
    function e18_auto(rule)
        x = acoustic_crossover_band(r_e18.inputs; rule=rule).fc_Hz
        inp2 = PainInputs(r_e18.inputs.fuse, r_e18.inputs.prop, r_e18.inputs.structural, r_e18.inputs.acoustic,
                          r_e18.inputs.amplitudes, r_e18.inputs.phases, r_e18.inputs.pts, r_e18.inputs.ΔA;
                          sidewall=r_e18.inputs.sidewall, endplates=r_e18.inputs.endplates,
                          mech=r_e18.inputs.mech, m_wall=r_e18.inputs.m_wall, crossover_band_Hz=x)
        return Float64.(interior_spl(inp2; bpf_Hz=200.0, n_harmonics=3, broadband=false,
                                     tone_model=:auto, η_r_cap=0.15).harmonic_SPL_dB[1:3]), x
    end
    e18_old, xe_old = e18_auto(:ten_modes)
    e18_new, xe_new = e18_auto(:volume)
    return (; f_Hz=f_vol, band_Hz=xvol.fc_Hz, ten_modes_Hz=xten.fc_Hz, ten_n=xten.n_modes,
            t1_eq8, t1_auto_old=t1_old, t1_auto_new=t1_new, x_t1_old, x_t1_new,
            repro_auto_old=r18_old, repro_auto_new=r18_new, x18_old, x18_new,
            e18_auto_old=e18_old, e18_auto_new=e18_new, xe_old, xe_new)
end

# --- registry ----------------------------------------------------------------

function _iso43_validation_cases()
    return [
        ValidationCase("T1_MEAS_DAMPING", "T1 with measured η_n (E-13) and η_r′ (E-15) (43b)", "43",
            [_iso43_data("cr3813", "e13_absorption_targets.csv"),
             _iso43_data("cr3813", "e15_structural_loss_measured_all.csv"),
             _iso43_data("cr3813", "t1_interior_targets.csv")],
            FigureRef("CR-3813", "Fig. E-13 / E-15 / E-16", 138),
            "T1 gate unchanged (±4 dB of measured E-16 mean, H1–H3).",
            "2026-10-23", "V-EXP", _run_t1_meas_damping,
            PlotSpec(; xlabel="harmonic band (Hz)", ylabel="interior SPL (dB)",
                     panel_titles=["T1_MEAS_DAMPING"], error_mode=:absolute, error_tol=4.0), ""),
        ValidationCase("H3_ATTRIB", "H3 attribution swaps on REPRO_18b (43c diagnostic)", "43",
            [_iso43_data("cr3813", "e14_acoustic_loss_calculated.csv"),
             _iso43_data("cr3813", "e15_structural_loss_calculated.csv")],
            FigureRef("CR-3813", "Figs. E-14 / E-15 / E-12", 139),
            "No criterion (diagnostic); shift of H1–H3 per NASA-value swap.",
            "2026-10-23", "diagnostic", _run_h3_attrib,
            PlotSpec(; xlabel="harmonic", ylabel="SPL (dB)",
                     panel_titles=["H3_ATTRIB"], error_mode=:none), ""),
        ValidationCase("NR_TP1964", "TP-1964 bare-cylinder NR vs measured (43d)", "43",
            [_iso43_data("tp1964", "tp1964_fig8_noise_reduction.csv"),
             _iso43_data("tp1964", "tp1964_fig17_reverberation.csv")],
            FigureRef("NASA TP-1964", "Fig. 8 measured", 22),
            "Within ±5 dB in ≥ 75 % of 1/3-octave bands 100–5000 Hz vs measured.",
            "2026-10-23", "V-EXP", _run_nr_tp1964,
            PlotSpec(; xlabel="band (Hz)", ylabel="NR (dB)", xscale=:log10,
                     panel_titles=["NR_TP1964"], error_mode=:absolute, error_tol=5.0), ""),
        ValidationCase("NR_TP1964_REF2", "TP-1964 bare-cylinder NR vs NASA ref.2 (43d)", "43",
            [_iso43_data("tp1964", "tp1964_fig8_noise_reduction.csv"),
             _iso43_data("tp1964", "tp1964_fig17_reverberation.csv")],
            FigureRef("NASA TP-1964", "Fig. 8 predicted (ref. 2)", 22),
            "Within ±3 dB in ≥ 75 % of 1/3-octave bands 100–5000 Hz vs NASA predicted curve.",
            "2026-10-23", "V-CODE", _run_nr_tp1964_ref2,
            PlotSpec(; xlabel="band (Hz)", ylabel="NR (dB)", xscale=:log10,
                     panel_titles=["NR_TP1964_REF2"], error_mode=:absolute, error_tol=3.0), ""),
        ValidationCase("T1_F1A_FILL", "T1 with F1A-relative off-line free field (43f)", "43",
            [_iso43_data("cr3813", "t1_interior_targets.csv")],
            FigureRef("CR-3813", "Fig. E-16", 142),
            "T1 gate unchanged (±4 dB of measured mean, H1–H3).",
            "2026-10-23", "V-EXP", _run_t1_f1a_fill,
            PlotSpec(; xlabel="harmonic band (Hz)", ylabel="interior SPL (dB)",
                     panel_titles=["T1_F1A_FILL"], error_mode=:absolute, error_tol=4.0), ""),
        ValidationCase("T1_F1A_MEAS_DAMP", "T1 F1A fill + measured damping (43b+43f diagnostic)", "43",
            [_iso43_data("cr3813", "t1_interior_targets.csv"),
             _iso43_data("cr3813", "e13_absorption_targets.csv"),
             _iso43_data("cr3813", "e15_structural_loss_measured_all.csv")],
            FigureRef("CR-3813", "Fig. E-16", 142),
            "No criterion (diagnostic combination of 43b and 43f).",
            "2026-10-23", "diagnostic", _run_t1_f1a_meas_damping_diag,
            PlotSpec(; xlabel="harmonic band (Hz)", ylabel="interior SPL (dB)",
                     panel_titles=["T1_F1A_MEAS_DAMP"], error_mode=:none), ""),
    ]
end

"""
    write_h3_attribution_report(path=docs/validation_reports/h3_attribution.md) -> path

Runs `H3_ATTRIB` and writes its table as Markdown. Not called by the case or the test suite
(the suite must not modify tracked docs); run it by hand to refresh the recorded report.
"""
function write_h3_attribution_report(path::AbstractString=joinpath(_VAL_REPORT_DIR, "h3_attribution.md"))
    r = run_validation_case("H3_ATTRIB")
    e = r.inputs_echo
    labels = _H3_LABELS
    spls = [e.baseline, e.eta_n, e.eta_r, e.both, e.e12]
    open(path, "w") do io
        println(io, "# H3 attribution on REPRO_18b (phase 43c)
")
        println(io, "Diagnostic only — no criterion. E-17 conditions: η_T = 0.5, no η_r′ cap, R1,")
        println(io, "ANOPP Table 8 + GEXT. Swaps use NASA's printed intermediate values (no tuning).
")
        println(io, "| swap | H1 [dB] | H2 [dB] | H3 [dB] | ΔH1 | ΔH2 | ΔH3 |")
        println(io, "|---|---:|---:|---:|---:|---:|---:|")
        for (lab, s) in zip(labels, spls)
            d = s .- e.baseline
            println(io, "| $lab | $(round(s[1]; digits=2)) | $(round(s[2]; digits=2)) | $(round(s[3]; digits=2)) | " *
                        "$(round(d[1]; digits=2)) | $(round(d[2]; digits=2)) | $(round(d[3]; digits=2)) |")
        end
        println(io, "
Generated $(_today_iso()).")
    end
    return path
end
