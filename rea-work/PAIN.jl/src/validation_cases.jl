# Phase 34 — validation case registry.
# One implementation per case: GUI, scripts and Pkg.test() call the same `run` function.
# Cases are read-only (fixed inputs, fixed criterion). No tuning from the GUI (CLAUDE.md).

"""One series drawn on a case plot (reference digitized data or computed output)."""
struct PlotSeries
    name::String
    kind::Symbol   # :reference_points | :reference_band | :reference_curve | :computed
    x::Vector{Float64}
    y::Vector{Float64}
    ylow::Vector{Float64}
    yhigh::Vector{Float64}
    panel::Int
end

function PlotSeries(name::AbstractString, kind::Symbol, x, y;
                    ylow=Float64[], yhigh=Float64[], panel::Int=1)
    return PlotSeries(String(name), kind,
                      collect(Float64, x), collect(Float64, y),
                      collect(Float64, ylow), collect(Float64, yhigh), panel)
end

"""Axis / panel layout mirroring the published figure (34c)."""
struct PlotSpec
    xlabel::String
    ylabel::String
    xscale::Symbol   # :identity | :log10
    yscale::Symbol
    xlim::Union{Nothing,NTuple{2,Float64}}
    ylim::Union{Nothing,NTuple{2,Float64}}
    panel_titles::Vector{String}
    tolerance_band::Union{Nothing,Float64}  # light band around reference (same units as y)
end

PlotSpec(; xlabel="", ylabel="", xscale=:identity, yscale=:identity,
         xlim=nothing, ylim=nothing, panel_titles=String[],
         tolerance_band=nothing) =
    PlotSpec(xlabel, ylabel, xscale, yscale, xlim, ylim, panel_titles, tolerance_band)

"""Published figure citation for a case."""
struct FigureRef
    document::String
    figure::String
    pdf_page::Union{Nothing,Int}
end

"""One row of the comparison table shown in the GUI / report."""
struct ValidationTableRow
    quantity::String
    x::Float64
    reference::Float64
    computed::Float64
    residual::Float64
    within_tolerance::Bool
end

"""Registered validation case (fixed inputs; no GUI edits)."""
struct ValidationCase
    id::String
    title::String
    phase::String
    reference_files::Vector{String}
    figure_ref::FigureRef
    criterion_text::String
    criterion_date::String
    label::String
    run::Function
    plot_spec::PlotSpec
    unavailable_reason::String   # non-empty → listed greyed in the GUI
end

"""Result of `run_validation_case(id)`."""
struct ValidationCaseResult
    id::String
    date::String
    inputs_echo::NamedTuple
    table::Vector{ValidationTableRow}
    series::Vector{PlotSeries}
    verdict::Symbol   # :met | :not_met | :no_verdict
    reason::String
    label::String
    report_path::String
end

# --- helpers ------------------------------------------------------------------------

const _VAL_REPORT_DIR = joinpath(@__DIR__, "..", "..", "docs", "validation_reports")
const _VAL_FIG_DIR = joinpath(_VAL_REPORT_DIR, "figures")

function _data_path(parts...)
    return abspath(joinpath(@__DIR__, "..", "..", "data", parts...))
end

function _missing_refs(files::Vector{String})
    miss = String[]
    for f in files
        isempty(f) && continue
        isfile(f) || push!(miss, f)
    end
    return miss
end

function _verdict_all(ok::Bool, n_ok::Int, n::Int, reason_ok::AbstractString, reason_fail::AbstractString)
    return ok ? (:met, String(reason_ok)) : (:not_met, String(reason_fail))
end

_today_iso() = string(Dates.today())

# --- case runners -------------------------------------------------------------------

"""CYL2D vs Table C-1 / Fig. C-3 (fast smoke case for 34f)."""
function _run_cyl2d_c1()
    θ0 = 56.6
    NY = 10
    c0 = TABLE_C1_C0
    res = cyl2d_modes(θ0; n_modes=20, NY=NY, c0=c0)
    ref_f = collect(Float64, TABLE_C1_FREQ_HZ)
    ref_g = collect(Float64, TABLE_C1_GENMASS)
    modes = collect(0:length(res.modes)-1)
    got_f = [m.f_Hz_unit for m in res.modes]
    got_g = [m.gen_mass_unit for m in res.modes]
    table = ValidationTableRow[]
    n_ok = 0
    n = 0
    for (i, m) in enumerate(res.modes)
        r = ref_f[i]
        if r == 0
            err = abs(m.f_Hz_unit - r)
            ok = err < 0.01
        else
            err = abs(m.f_Hz_unit - r) / r
            ok = err ≤ 0.001   # 0.1 % as fraction
        end
        n += 1
        n_ok += ok
        push!(table, ValidationTableRow("f_Hz mode $(m.index)", Float64(m.index),
                                        r, m.f_Hz_unit, m.f_Hz_unit - r, ok))
        gref = ref_g[i]
        gerr = abs(m.gen_mass_unit - gref) / gref
        gok = gerr ≤ 0.001
        n += 1
        n_ok += gok
        push!(table, ValidationTableRow("Φ_G mode $(m.index)", Float64(m.index),
                                        gref, m.gen_mass_unit, m.gen_mass_unit - gref, gok))
        sok = m.symmetric == TABLE_C1_SYMMETRIC[i]
        n += 1
        n_ok += sok
        push!(table, ValidationTableRow("symmetry mode $(m.index)", Float64(m.index),
                                        Float64(TABLE_C1_SYMMETRIC[i]), Float64(m.symmetric),
                                        Float64(m.symmetric) - Float64(TABLE_C1_SYMMETRIC[i]), sok))
    end
    all_ok = n_ok == n
    verdict, reason = _verdict_all(all_ok, n_ok, n,
        "$n_ok/$n within criterion (≤0.1 % f and Φ_G; symmetry equal)",
        "$n_ok/$n within criterion")
    series = [
        PlotSeries("Table C-1 f", :reference_points, modes, ref_f; panel=1),
        PlotSeries("CYL2D f", :computed, modes, got_f; panel=1),
        PlotSeries("Table C-1 Φ_G", :reference_points, modes, ref_g; panel=2),
        PlotSeries("CYL2D Φ_G", :computed, modes, got_g; panel=2),
    ]
    return ValidationCaseResult(
        "CYL2D_C1", _today_iso(),
        (; theta0_deg=θ0, NY=NY, c0=c0, n_modes=20, scheme="App. C"),
        table, series, verdict, reason, "V-CODE",
        joinpath(_VAL_REPORT_DIR, "cyl2d_table_c1.md"),
    )
end

"""MRP Table D-1 seed frequencies (production path reuses D-1 — V-CODE circular for seed)."""
function _run_mrp_d1()
    sm = structural_modes_from_table_d1(; n_keep=32)
    idxs = Float64[r[1] for r in TABLE_D1_FULL]
    ref_f = Float64[r[2] for r in TABLE_D1_FULL]
    got_f = Float64[m.f_Hz for m in sm.modes]
    table = ValidationTableRow[]
    n_ok = 0
    for i in eachindex(ref_f)
        # Seed path loads Table D-1 exactly → residual 0 by construction; recorded as V-CODE seed.
        ok = abs(got_f[i] - ref_f[i]) ≤ 1e-12
        n_ok += ok
        push!(table, ValidationTableRow("f_Hz mode $(Int(idxs[i]))", idxs[i],
                                        ref_f[i], got_f[i], got_f[i] - ref_f[i], ok))
    end
    all_ok = n_ok == length(ref_f)
    verdict, reason = _verdict_all(all_ok, n_ok, length(ref_f),
        "seed matches Table D-1 exactly ($n_ok/$(length(ref_f))); raw Ritz is a separate check",
        "$n_ok/$(length(ref_f)) match Table D-1")
    series = [
        PlotSeries("Table D-1", :reference_points, idxs, ref_f; panel=1),
        PlotSeries("MRP seed", :computed, idxs, got_f; panel=1),
    ]
    return ValidationCaseResult(
        "MRP_D1", _today_iso(),
        (; n_keep=32, source="TABLE_D1_FULL"),
        table, series, verdict, reason, "V-CODE",
        joinpath(_VAL_REPORT_DIR, "fig_d2_check.md"),
    )
end

"""T1 tonal vs Fig. E-16 / E-17 (e11 path; no claim per phase 32/33)."""
function _run_t1()
    targets = _data_path("t1_interior_targets.csv")
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    recs = evaluate_T1(r.spectrum; targets_csv=targets)
    cols = _read_csv_numeric(targets)
    bands = Float64[haskey(cols, :band_Hz) ? cols[:band_Hz][i] : i * 200.0 for i in eachindex(cols[:harmonic])]
    mean_v = Float64[cols[:measured_mean_SPL_dB][i] for i in eachindex(cols[:harmonic])]
    lo = Float64[cols[:measured_low_dB][i] for i in eachindex(cols[:harmonic])]
    hi = Float64[cols[:measured_high_dB][i] for i in eachindex(cols[:harmonic])]
    nasa = Float64[cols[:nasa_pain_pred_dB][i] for i in eachindex(cols[:harmonic])]
    got = Float64[]
    table = ValidationTableRow[]
    n_ok = 0
    for (i, rec) in enumerate(recs)
        H = Int(round(cols[:harmonic][i]))
        g = r.spectrum.harmonic_SPL_dB[H]
        push!(got, g)
        ok = rec.result == "PASS"
        n_ok += ok
        push!(table, ValidationTableRow("interior SPL H=$H", bands[i], mean_v[i], g, g - mean_v[i], ok))
    end
    # Pad got to length of bands if evaluate skipped a harmonic
    while length(got) < length(bands)
        push!(got, NaN)
    end
    all_ok = n_ok == length(recs) && !isempty(recs)
    reason = all_ok ?
        "$n_ok/$(length(recs)) PASS (T1 still no claim: GEXT flips — phase 32)" :
        "$n_ok/$(length(recs)) PASS; T1 not claimable (GEXT bound)"
    series = [
        PlotSeries("measured mean", :reference_points, bands, mean_v; panel=1),
        PlotSeries("measured range", :reference_band, bands, mean_v; ylow=lo, yhigh=hi, panel=1),
        PlotSeries("NASA PAIN pred", :reference_points, bands, nasa; panel=1),
        PlotSeries("PAIN H1–H3", :computed, bands[1:length(got)], got; panel=1),
    ]
    return ValidationCaseResult(
        "T1", _today_iso(),
        (; source=:e11, bpf_Hz=200.0, blocking=:R2, n_harmonics=3, η_T=0.5),
        table, series, all_ok ? :met : :not_met, reason, "calibrated (in-sample)",
        joinpath(_VAL_REPORT_DIR, "phase20_baseline.md"),
    )
end

"""18b-r reproduction vs NASA PAIN predictions on Fig. E-16 (±4 dB)."""
function _run_repro_18b()
    targets = _data_path("t1_interior_targets.csv")
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    cols = _read_csv_numeric(targets)
    bands = Float64[haskey(cols, :band_Hz) ? cols[:band_Hz][i] : i * 200.0 for i in eachindex(cols[:harmonic])]
    nasa = Float64[cols[:nasa_pain_pred_dB][i] for i in eachindex(cols[:harmonic])]
    tol = 4.0
    table = ValidationTableRow[]
    got = Float64[]
    n_ok = 0
    for i in eachindex(cols[:harmonic])
        H = Int(round(cols[:harmonic][i]))
        H > length(r.spectrum.harmonic_SPL_dB) && continue
        g = r.spectrum.harmonic_SPL_dB[H]
        push!(got, g)
        ok = abs(g - nasa[i]) ≤ tol
        n_ok += ok
        push!(table, ValidationTableRow("vs NASA PAIN H=$H", bands[i], nasa[i], g, g - nasa[i], ok))
    end
    # Criterion: 2 of 3 within 4 dB was the recorded 18b-r outcome; gate is 3/3 for :met
    all_ok = n_ok == length(got) && !isempty(got)
    series = [
        PlotSeries("NASA PAIN pred", :reference_points, bands[1:length(got)], nasa[1:length(got)]; panel=1),
        PlotSeries("±4 dB band", :reference_band, bands[1:length(got)], nasa[1:length(got)];
                   ylow=nasa[1:length(got)] .- tol, yhigh=nasa[1:length(got)] .+ tol, panel=1),
        PlotSeries("reproduction", :computed, bands[1:length(got)], got; panel=1),
    ]
    return ValidationCaseResult(
        "REPRO_18b", _today_iso(),
        (; source=:e11, bpf_Hz=200.0, blocking=:R2, criterion="|Δ|≤4 dB vs NASA PAIN pred", date="2026-10-20"),
        table, series, all_ok ? :met : :not_met,
        "$n_ok/$(length(got)) within ±4 dB of NASA PAIN prediction",
        "V-CODE",
        joinpath(_VAL_REPORT_DIR, "pain_reproduction_e16.md"),
    )
end

"""T2 1/3-octave vs Fig. E-9 (stale bb_j2_scale; no claim)."""
function _run_t2()
    targets = _data_path("t2_third_octave_targets.csv")
    isfile(targets) || (targets = _data_path("t2_third_octave_targets_B.csv"))
    r = run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200.0, blocking=R2)
    recs = evaluate_T2(r.spectrum; targets_csv=targets)
    cols = _read_csv_numeric(targets)
    fcs = Float64[cols[:fc_Hz][i] for i in eachindex(cols[:fc_Hz])]
    mean_v = Float64[cols[:measured_mean_SPL_dB][i] for i in eachindex(cols[:fc_Hz])]
    tols = Float64[cols[:tol_dB][i] for i in eachindex(cols[:fc_Hz])]
    got = Float64[]
    table = ValidationTableRow[]
    n_ok = 0
    third = r.spectrum.third_octave_SPL_dB
    for i in eachindex(fcs)
        b = nearest_third_octave(fcs[i], collect(keys(third)))
        g = get(third, b, NaN)
        push!(got, g)
        ok = isfinite(g) && abs(g - mean_v[i]) ≤ tols[i]
        n_ok += ok
        push!(table, ValidationTableRow("1/3-oct fc=$(round(fcs[i]; digits=0))", fcs[i],
                                        mean_v[i], g, g - mean_v[i], ok))
    end
    all_ok = n_ok == length(fcs) && !isempty(fcs)
    series = [
        PlotSeries("measured mean", :reference_points, fcs, mean_v; panel=1),
        PlotSeries("±tol", :reference_band, fcs, mean_v;
                   ylow=mean_v .- tols, yhigh=mean_v .+ tols, panel=1),
        PlotSeries("PAIN 1/3-oct", :computed, fcs, got; panel=1),
    ]
    return ValidationCaseResult(
        "T2", _today_iso(),
        (; source=:e11, bpf_Hz=200.0, bands="1.25–2 kHz (targets CSV)", bb_j2_scale=0.5),
        table, series, all_ok ? :met : :not_met,
        "$n_ok/$(length(fcs)) PASS; T2 carries stale bb_j2_scale (no claim)",
        "calibrated (in-sample)",
        joinpath(_VAL_REPORT_DIR, "phase20_baseline.md"),
    )
end

"""Unavailable / deferred placeholder result (greyed in GUI)."""
function _run_unavailable(id::AbstractString, reason::AbstractString, label::AbstractString, report::AbstractString)
    return ValidationCaseResult(
        String(id), _today_iso(), (;),
        ValidationTableRow[], PlotSeries[],
        :no_verdict, String(reason), String(label), String(report),
    )
end

# --- registry -----------------------------------------------------------------------

function _make_registry()
    cases = ValidationCase[]

    push!(cases, ValidationCase(
        "CYL2D_C1", "CYL2D vs Table C-1 / Fig. C-3", "15",
        String[],
        FigureRef("CR-3813", "Table C-1 / Fig. C-3", nothing),
        "All 20 frequencies and Φ_G within 0.1 % of Table C-1 (c0 = 341 m/s, NY = 10); symmetry equal; Fig. C-3 modes 0–5 match printed one-decimal nodes.",
        "2026-10-20", "V-CODE", _run_cyl2d_c1,
        PlotSpec(; xlabel="mode number", ylabel="frequency (Hz) / Φ_G",
                 panel_titles=["frequency vs mode", "Φ_G vs mode"],
                 tolerance_band=nothing),
        "",
    ))

    push!(cases, ValidationCase(
        "MRP_D1", "MRP Table D-1 seed frequencies", "15",
        String[],
        FigureRef("CR-3813", "Table D-1 / Fig. D-2", 113),
        "Production seed frequencies equal Table D-1 (exact load). Raw Ritz ≤5 % is a separate V-CODE check.",
        "2026-10-20", "V-CODE", _run_mrp_d1,
        PlotSpec(; xlabel="mode number", ylabel="frequency (Hz)",
                 panel_titles=["frequency vs mode"]),
        "",
    ))

    push!(cases, ValidationCase(
        "T1", "Tonal interior SPL vs Fig. E-16 / E-17", "18",
        [_data_path("t1_interior_targets.csv")],
        FigureRef("CR-3813", "Fig. E-16 / E-17", 142),
        "H1–H3: |got − measured mean| ≤ 4 dB, or inside measured envelope and |got − NASA PAIN| ≤ 4 dB. Label: calibrated (in-sample); T1 not claimable after GEXT bound (phase 32).",
        "2026-10-20", "calibrated (in-sample)", _run_t1,
        PlotSpec(; xlabel="1/3-octave band (Hz)", ylabel="SPL (dB)",
                 xscale=:log10, xlim=(160.0, 2000.0),
                 panel_titles=["Fig. E-16 interior SPL"], tolerance_band=4.0),
        "",
    ))

    push!(cases, ValidationCase(
        "T2", "1/3-octave vs Fig. E-9 / E-10", "18",
        filter(isfile, [_data_path("t2_third_octave_targets.csv"), _data_path("t2_third_octave_targets_B.csv")]),
        FigureRef("CR-3813", "Fig. E-9 / E-10", 132),
        "Bands in targets CSV: |got − measured mean| ≤ tol_dB. Stale bb_j2_scale = 0.5; no claim.",
        "2026-10-20", "calibrated (in-sample)", _run_t2,
        PlotSpec(; xlabel="1/3-octave band (Hz)", ylabel="SPL (dB)",
                 xscale=:log10, xlim=(125.0, 2000.0),
                 panel_titles=["Fig. E-9"]),
        "",
    ))

    push!(cases, ValidationCase(
        "REPRO_18b", "PAIN reproduction vs NASA predictions (18b-r)", "18",
        [_data_path("t1_interior_targets.csv")],
        FigureRef("CR-3813", "Fig. E-16 NASA PAIN pred", 142),
        "|got − NASA PAIN prediction| ≤ 4 dB at H1–H3 (registered 2026-10-20).",
        "2026-10-20", "V-CODE", _run_repro_18b,
        PlotSpec(; xlabel="harmonic band (Hz)", ylabel="SPL (dB)",
                 xscale=:log10, panel_titles=["vs NASA PAIN"], tolerance_band=4.0),
        "",
    ))

    # Remaining cases from the 34c table: registered with plot_spec; run returns no_verdict
    # until a dedicated case function extracts the script core (or data is missing).
    deferred = [
        ("E12_BLOCK", "Fig. E-12 blocked SPL", "14", "CR-3813", "Fig. E-12", 136,
         "Eq. (43) on Table 8 vs E-12; core still in scripts/e12_blocking.jl",
         "V-CODE",
         PlotSpec(; xlabel="X3/D", ylabel="blocked SPL (dB)", panel_titles=["H1", "H2", "H3"])),
        ("E11_FREEFIELD", "Fig. E-11 free-field line", "12", "CR-3813", "Fig. E-11", 135,
         "e11 input line vs measured passes; core in freefield_digitized path",
         "V-ASSUMED",
         PlotSpec(; xlabel="X3/D", ylabel="free-field SPL (dB)", panel_titles=["H1", "H2", "H3"])),
        ("E14_LOSS", "Fig. E-14 loss factor", "16", "CR-3813", "Fig. E-14", 139,
         "Eq. (77) band averages; see trim_loss report",
         "V-CODE",
         PlotSpec(; xlabel="band (Hz)", ylabel="loss factor", xscale=:log10, yscale=:log10,
                  xlim=(10.0, 10000.0), ylim=(0.001, 1.0), panel_titles=["η"])),
        ("E21_E22_NR", "Figs. E-21 / E-22 noise reduction", "31e", "CR-3813", "Figs. E-21, E-22", 149,
         "Deferred with phase 31 (B-4); optional test-article coverage",
         "no verdict",
         PlotSpec(; xlabel="band (Hz)", ylabel="NR (dB)", xscale=:log10, xlim=(63.0, 4000.0),
                  panel_titles=["E-21 / E-22"])),
        ("GEXT_BOUND", "GEXT importance bound (T1 residual)", "32", "—", "derived (no figure)", nothing,
         "See gext_importance_bound.md; T1 not claimable",
         "V-ASSUMED",
         PlotSpec(; xlabel="variant", ylabel="T1 residual (dB)", panel_titles=["H1", "H2", "H3"])),
        ("BBN_KIN", "BBN kinematic Δφ (24b)", "24", "—", "V-UNIT", nothing,
         "See bbn_phase.md; 24b PASS recorded",
         "V-UNIT",
         PlotSpec(; xlabel="harmonic", ylabel="Δφ (deg)", panel_titles=["m·B·Δψ"])),
        ("BBN_CIRC", "BBN circumferential phase (24c)", "24", "CR-158919 / CR-159124", "App. C/D, Fig. 18", 86,
         "23a FAIL recorded (26/168); case function not yet extracted from run_bbn_phase.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="harmonic", ylabel="phase (deg)", panel_titles=["per pair"])),
        ("BBN_LEVELS", "BBN relative levels (24d)", "24", "CR-158919", "Tables 3, 4", nothing,
         "Core still in run_bbn_phase.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="microphone", ylabel="relative level (dB)", panel_titles=["levels"])),
        ("BBN_LONG", "BBN longitudinal phase (24e)", "24", "CR-159124", "Figs. 19, 20", 56,
         "X-EXTRAP (assumed tip); core in run_bbn_phase.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="frequency (Hz)", ylabel="phase (π rad)", panel_titles=["Fig. 19", "Fig. 20"])),
        ("R996_LOADS", "Report 996 CCBlade loads (26)", "26", "RM L8H25a / Report 996", "Figs. 10, 11; Fig. 7 legend", nothing,
         "Criteria registered after loads (I-06); core in run_report996_loads.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="M_t", ylabel="C_T / C_P", panel_titles=["C_T", "C_P"])),
        ("R996_FIG6", "Report 996 Fig. 6", "27", "NACA Report 996", "Fig. 6", 11,
         "23c FAIL; core in run_report996_acoustics.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="x/D", ylabel="total rms (dyne/cm²)", panel_titles=["per d/D"])),
        ("R996_FIG7", "Report 996 Fig. 7", "27", "NACA Report 996", "Fig. 7", 11,
         "23c FAIL; core in run_report996_acoustics.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="x/D", ylabel="p_c/C_P", panel_titles=["per β₇₅"])),
        ("R996_FIG8", "Report 996 Fig. 8", "27", "NACA Report 996", "Fig. 8", 11,
         "Optional multi-C_P sweep deferred",
         "X-EXTRAP",
         PlotSpec(; xlabel="C_P", ylabel="p_c", panel_titles=["Fig. 8"])),
        ("R996_FIG12", "Report 996 Fig. 12(a)(b)", "27", "NACA Report 996", "Fig. 12", 13,
         "23c FAIL; core in run_report996_acoustics.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="x/D", ylabel="harmonic pressure", panel_titles=["Fig. 12(a)", "Fig. 12(b)"])),
        ("R996_FIG13A", "Report 996 Fig. 13(a)", "27", "NACA Report 996", "Fig. 13(a)", 15,
         "I-08 L51C27 scale; 23c FAIL",
         "X-EXTRAP",
         PlotSpec(; xlabel="x/D", ylabel="first-harmonic pressure", panel_titles=["Fig. 13(a)"])),
        ("R996_FIG14", "Report 996 Fig. 14(a)", "27", "NACA Report 996", "Fig. 14(a)", 16,
         "23c FAIL; core in run_report996_acoustics.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="M_t", ylabel="harmonic pressure", yscale=:log10, panel_titles=["Fig. 14(a)"])),
        ("R996_PHASE", "Report 996 page-12 phase", "27", "NACA Report 996", "p. 12 text", 12,
         "Measured 155°; F1A FAIL (103.8°)",
         "X-EXTRAP",
         PlotSpec(; xlabel="case", ylabel="phase difference (deg)", panel_titles=["page 12"])),
        ("PER_LOADS", "Pereira Table 3 loads", "28", "Pereira et al. (2026)", "Table 3", 5,
         "Loads OK; core in run_pereira.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="quantity", ylabel="T / Q", panel_titles=["Table 3"])),
        ("PER_FIG6", "Pereira Fig. 6 spectra", "28", "Pereira et al. (2026)", "Fig. 6", 7,
         "Core in run_pereira.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="frequency (Hz)", ylabel="SPL (dB)", xscale=:log10,
                  panel_titles=["φ=0°", "φ=20°", "φ=40°"])),
        ("PER_FIG7", "Pereira Fig. 7 waveform", "28", "Pereira et al. (2026)", "Fig. 7", 8,
         "Core in run_pereira.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="propeller phase (deg)", ylabel="p′ (Pa)", panel_titles=["three panels"])),
        ("PER_FIG8", "Pereira Fig. 8 directivity", "28", "Pereira et al. (2026)", "Fig. 8", 9,
         "Core in run_pereira.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="φ (deg)", ylabel="SPL (dB)", panel_titles=["H1–H6"])),
        ("PER_FIG9", "Pereira Fig. 9 harmonics", "28", "Pereira et al. (2026)", "Fig. 9", 10,
         "23d H1 FAIL 0/9; core in run_pereira.jl",
         "X-EXTRAP",
         PlotSpec(; xlabel="BPF harmonic", ylabel="SPL (dB)",
                  panel_titles=["φ=0°", "φ=20°", "φ=40°"])),
    ]
    for (id, title, phase, doc, fig, page, reason, label, spec) in deferred
        push!(cases, ValidationCase(
            id, title, phase, String[],
            FigureRef(doc, fig, page),
            "Criterion as frozen in VALIDATION_GUIDELINE.md §2.12 / phase reports (see reason).",
            "2026-10-21", label,
            (() -> _run_unavailable(id, reason, label, joinpath(_VAL_REPORT_DIR, "README.md"))),
            spec, reason,
        ))
    end
    return Dict(c.id => c for c in cases)
end

const VALIDATION_CASES = _make_registry()

"""Ordered list of case ids (registry insertion order via sorted keys would scramble; use fixed order)."""
const VALIDATION_CASE_ORDER = [
    "CYL2D_C1", "MRP_D1", "T1", "T2", "REPRO_18b",
    "E12_BLOCK", "E11_FREEFIELD", "E14_LOSS", "E21_E22_NR", "GEXT_BOUND",
    "BBN_KIN", "BBN_CIRC", "BBN_LEVELS", "BBN_LONG",
    "R996_LOADS", "R996_FIG6", "R996_FIG7", "R996_FIG8", "R996_FIG12", "R996_FIG13A", "R996_FIG14", "R996_PHASE",
    "PER_LOADS", "PER_FIG6", "PER_FIG7", "PER_FIG8", "PER_FIG9",
]

function list_validation_cases()
    return [VALIDATION_CASES[id] for id in VALIDATION_CASE_ORDER if haskey(VALIDATION_CASES, id)]
end

"""
    run_validation_case(id) -> ValidationCaseResult

Run the registered case. Inputs are fixed; missing reference files yield `:no_verdict`.
"""
function run_validation_case(id::AbstractString)
    haskey(VALIDATION_CASES, id) || error("unknown validation case id: $id")
    case = VALIDATION_CASES[id]
    if !isempty(case.unavailable_reason) && case.id ∉ ("CYL2D_C1", "MRP_D1", "T1", "T2", "REPRO_18b")
        return case.run()
    end
    miss = _missing_refs(case.reference_files)
    if !isempty(miss)
        return ValidationCaseResult(
            case.id, _today_iso(), (; missing=miss),
            ValidationTableRow[], PlotSeries[],
            :no_verdict, "missing reference: " * join(miss, ", "), case.label,
            "",
        )
    end
    return case.run()
end

"""Format a case result as plain text for the GUI results pane."""
function format_validation_result(r::ValidationCaseResult)
    io = IOBuffer()
    println(io, "id: ", r.id)
    println(io, "date: ", r.date)
    println(io, "label: ", r.label)
    println(io, "verdict: ", r.verdict)
    println(io, "reason: ", r.reason)
    println(io, "report: ", r.report_path)
    println(io, "inputs: ", r.inputs_echo)
    println(io)
    println(io, "quantity\tx\treference\tcomputed\tresidual\tok")
    for row in r.table
        println(io, row.quantity, '\t', row.x, '\t', row.reference, '\t',
                row.computed, '\t', row.residual, '\t', row.within_tolerance)
    end
    return String(take!(io))
end
