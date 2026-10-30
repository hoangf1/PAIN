# Phase 34 — validation case registry.
# One implementation per case: GUI, scripts and Pkg.test() call the same `run` function.
# Cases are read-only (fixed inputs, fixed criterion). No tuning from the GUI (CLAUDE.md).

"""One series drawn on a case plot (reference digitized data or computed output)."""
struct PlotSeries
    name::String
    kind::Symbol   # :reference_points | :reference_band | :reference_curve | :computed | :computed_points
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
    error_mode::Symbol   # :absolute | :relative_pct | :db_ratio | :none
    error_ylabel::String
    error_tol::Union{Nothing,Float64}
    error_xlabel::Union{Nothing,String}  # nothing → reuse xlabel (main-panel x)
    # Optional per-panel overrides (empty / missing → fall back to xlabel/ylabel/xlim/ylim).
    panel_xlabels::Vector{String}
    panel_ylabels::Vector{String}
    panel_xlims::Vector{Union{Nothing,NTuple{2,Float64}}}
    panel_ylims::Vector{Union{Nothing,NTuple{2,Float64}}}
end

PlotSpec(; xlabel="", ylabel="", xscale=:identity, yscale=:identity,
         xlim=nothing, ylim=nothing, panel_titles=String[],
         tolerance_band=nothing, error_mode=:absolute, error_ylabel="",
         error_tol=nothing, error_xlabel=nothing,
         panel_xlabels=String[], panel_ylabels=String[],
         panel_xlims=Union{Nothing,NTuple{2,Float64}}[],
         panel_ylims=Union{Nothing,NTuple{2,Float64}}[]) =
    PlotSpec(xlabel, ylabel, xscale, yscale, xlim, ylim, panel_titles, tolerance_band,
             error_mode, error_ylabel, error_tol, error_xlabel,
             panel_xlabels, panel_ylabels, panel_xlims, panel_ylims)

"""Published figure citation for a case."""
struct FigureRef
    document::String
    figure::String
    pdf_page::Union{Nothing,Int}
end

"""Group key for error-panel marker shape (quantity with harmonic/mode/station tokens stripped)."""
function _error_quantity_group(quantity::AbstractString)
    s = String(quantity)
    s = replace(s, r"\bH=?\d+\b" => "")
    s = replace(s, r"\bmode \d+\b" => "")
    s = replace(s, r"\bk=\d+\b" => "")
    s = replace(s, r"\bpair\d+\b" => "")
    s = replace(s, r"\s+" => " ")
    s = strip(s)
    return isempty(s) ? "value" : s
end

"""One row of the comparison table shown in the GUI / report."""
struct ValidationTableRow
    quantity::String
    x::Float64
    reference::Float64
    computed::Float64
    residual::Float64
    within_tolerance::Bool
    group::String
end

"""6-arg constructor: `group` derived from `quantity` (backward compatible)."""
function ValidationTableRow(quantity::AbstractString, x, reference, computed, residual, within_tolerance::Bool)
    q = String(quantity)
    return ValidationTableRow(q, Float64(x), Float64(reference), Float64(computed),
                              Float64(residual), within_tolerance, _error_quantity_group(q))
end

function ValidationTableRow(quantity::AbstractString, x, reference, computed, residual,
                            within_tolerance::Bool, group::AbstractString)
    return ValidationTableRow(String(quantity), Float64(x), Float64(reference), Float64(computed),
                              Float64(residual), within_tolerance, String(group))
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
    # Rigid mode; absolute frequencies are not a test (c0 back-solved from Table C-1).
    m0 = res.modes[1]
    rok = abs(m0.f_Hz_unit) < 0.01
    n += 1
    n_ok += rok
    push!(table, ValidationTableRow("f mode 0", 0.0, 0.0, m0.f_Hz_unit, m0.f_Hz_unit, rok))
    # c0-free ratios vs first non-rigid mode (Julia index 2); re-stated 2026-10-21 after result known.
    f1_ref = TABLE_C1_FREQ_HZ[2]
    f1_got = res.modes[2].f_Hz_unit
    for i in 3:20
        m = res.modes[i]
        ref = TABLE_C1_FREQ_HZ[i] / f1_ref
        computed = m.f_Hz_unit / f1_got
        ok = abs(computed / ref - 1) ≤ 1e-3
        n += 1
        n_ok += ok
        push!(table, ValidationTableRow("f/f₁ mode $(m.index)", Float64(m.index),
                                        ref, computed, computed - ref, ok))
    end
    for (i, m) in enumerate(res.modes)
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
        "$n_ok/$n within criterion (≤0.1 % f ratios and Φ_G; symmetry equal)",
        "$n_ok/$n within criterion")
    series = [
        PlotSeries("Table C-1 f", :reference_points, modes, ref_f; panel=1),
        PlotSeries("CYL2D f (c0 = 341 m/s, back-solved from Table C-1)", :computed, modes, got_f; panel=1),
        PlotSeries("Table C-1 Φ_G", :reference_points, modes, ref_g; panel=2),
        PlotSeries("CYL2D Φ_G", :computed, modes, got_g; panel=2),
    ]
    return ValidationCaseResult(
        "CYL2D_C1", _today_iso(),
        (; theta0_deg=θ0, NY=NY, c0=c0, n_modes=20, scheme="App. C",
         c0_note="341 m/s back-solved from Table C-1; criterion uses ratios",
         reference_tables=["TABLE_C1_FREQ_HZ", "TABLE_C1_GENMASS", "TABLE_C1_SYMMETRIC", "TABLE_C1_C0"]),
        table, series, verdict, reason, "V-CODE",
        joinpath(_VAL_REPORT_DIR, "cyl2d_table_c1.md"),
    )
end

"""MRP Table D-1 seed frequencies (transcription check — residual 0 by construction)."""
function _run_mrp_d1()
    sm = structural_modes_from_table_d1(; n_keep=32)
    idxs = Float64[r[1] for r in TABLE_D1_FULL]
    ref_f = Float64[r[2] for r in TABLE_D1_FULL]
    got_f = Float64[m.f_Hz for m in sm.modes]
    table = ValidationTableRow[]
    n_ok = 0
    for i in eachindex(ref_f)
        # Seed path loads Table D-1 exactly → residual 0 by construction; not evidence.
        ok = abs(got_f[i] - ref_f[i]) ≤ 1e-12
        n_ok += ok
        push!(table, ValidationTableRow("f_Hz mode $(Int(idxs[i]))", idxs[i],
                                        ref_f[i], got_f[i], got_f[i] - ref_f[i], ok))
    end
    series = [
        PlotSeries("Table D-1", :reference_points, idxs, ref_f; panel=1),
        PlotSeries("MRP seed", :computed, idxs, got_f; panel=1),
    ]
    return ValidationCaseResult(
        "MRP_D1", _today_iso(),
        (; n_keep=32, source="TABLE_D1_FULL", reference_tables=["TABLE_D1_FULL"]),
        table, series, :no_verdict,
        "seed loads Table D-1 → residual 0 by construction; transcription check, not evidence (raw Ritz fit: see mrp_ritz_vs_d1.md)",
        "transcription (by construction)",
        joinpath(_VAL_REPORT_DIR, "fig_d2_check.md"),
    )
end

"""T1 tonal vs Fig. E-16 / E-17 (e11 path; no claim per phase 32/33)."""
function _run_t1()
    targets = _data_path("cr3813", "t1_interior_targets.csv")
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    cols = _read_csv_numeric(targets)
    bands = Float64[haskey(cols, :band_Hz) ? cols[:band_Hz][i] : i * 200.0 for i in eachindex(cols[:harmonic])]
    mean_v = Float64[cols[:measured_mean_SPL_dB][i] for i in eachindex(cols[:harmonic])]
    lo = Float64[cols[:measured_low_dB][i] for i in eachindex(cols[:harmonic])]
    hi = Float64[cols[:measured_high_dB][i] for i in eachindex(cols[:harmonic])]
    nasa = Float64[cols[:nasa_pain_pred_dB][i] for i in eachindex(cols[:harmonic])]
    tol = 4.0
    got = Float64[]
    table = ValidationTableRow[]
    n_ok = 0
    gate_parts = String[]
    for i in eachindex(cols[:harmonic])
        H = Int(round(cols[:harmonic][i]))
        H > length(r.spectrum.harmonic_SPL_dB) && continue
        g = r.spectrum.harmonic_SPL_dB[H]
        push!(got, g)
        ok_A = abs(g - mean_v[i]) ≤ tol
        ok_B = (lo[i] ≤ g ≤ hi[i]) && abs(g - nasa[i]) ≤ tol
        ok = ok_A || ok_B
        n_ok += ok
        push!(table, ValidationTableRow("H$H vs measured mean (gate A: ±4 dB)", bands[i],
                                        mean_v[i], g, g - mean_v[i], ok_A))
        push!(table, ValidationTableRow("H$H vs NASA PAIN, inside envelope (gate B)", bands[i],
                                        nasa[i], g, g - nasa[i], ok_B))
        push!(gate_parts, ok_A ? "H$H A" : (ok_B ? "H$H B" : "H$H fail"))
    end
    while length(got) < length(bands)
        push!(got, NaN)
    end
    all_ok = n_ok == length(got) && !isempty(got)
    reason = join(gate_parts, ", ") * (all_ok ?
        " — T1 still no claim: GEXT flips (phase 32)" :
        " — T1 not claimable (GEXT bound)")
    series = [
        PlotSeries("measured mean", :reference_points, bands, mean_v; panel=1),
        PlotSeries("measured range", :reference_band, bands, mean_v; ylow=lo, yhigh=hi, panel=1),
        PlotSeries("NASA PAIN pred", :reference_points, bands, nasa; panel=1),
        PlotSeries("PAIN H1–H3", :computed, bands[1:length(got)], got; panel=1),
    ]
    return ValidationCaseResult(
        "T1", _today_iso(),
        (; source=:e11, bpf_Hz=200.0, blocking=:R2, n_harmonics=3, η_T=0.5, csv=targets),
        table, series, all_ok ? :met : :not_met,
        reason * " (amplitude convention fixed 2026-10-21, post-hoc)",
        "calibrated (in-sample; amplitude convention fixed 2026-10-21, post-hoc)",
        joinpath(_VAL_REPORT_DIR, "phase20_baseline.md"),
    )
end

"""18b-r reproduction vs NASA PAIN predictions on Fig. E-16 (±4 dB)."""
function _run_repro_18b()
    targets = _data_path("cr3813", "t1_interior_targets.csv")
    paths = default_e11_paths()
    p3 = phase3_trim(; η_lining=0.5)
    r = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3, bpf_Hz=200.0,
                          blocking=R1, sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends,
                          mech=p3.mech)
    cols = _read_csv_numeric(targets)
    bands = Float64[haskey(cols, :band_Hz) ? cols[:band_Hz][i] : i * 200.0 for i in eachindex(cols[:harmonic])]
    nasa = Float64[cols[:nasa_pain_pred_dB][i] for i in eachindex(cols[:harmonic])]
    tol = 4.0
    table = ValidationTableRow[]
    got = Float64[]
    n_ok = 0
    margins = String[]
    for i in eachindex(cols[:harmonic])
        H = Int(round(cols[:harmonic][i]))
        H > length(r.spectrum.harmonic_SPL_dB) && continue
        g = r.spectrum.harmonic_SPL_dB[H]
        push!(got, g)
        d = g - nasa[i]
        ok = abs(d) ≤ tol
        n_ok += ok
        push!(margins, "H$H margin=$(round(tol - abs(d); digits=2)) dB (Δ=$(round(d; digits=2)))")
        push!(table, ValidationTableRow("vs NASA PAIN H=$H", bands[i], nasa[i], g, d, ok))
    end
    all_ok = n_ok == length(got) && !isempty(got)
    series = [
        PlotSeries("NASA PAIN pred", :reference_points, bands[1:length(got)], nasa[1:length(got)]; panel=1),
        PlotSeries("reproduction", :computed, bands[1:length(got)], got; panel=1),
    ]
    return ValidationCaseResult(
        "REPRO_18b", _today_iso(),
        (; free_field="ANOPP Table 8 (GEXT)", blocking=:R1, η_T=0.5, trim=:phase3,
         criterion="|Δ|≤4 dB vs NASA PAIN pred", date="2026-10-20", csv=targets),
        table, series, all_ok ? :met : :not_met,
        "$n_ok/$(length(got)) within ±4 dB of NASA PAIN prediction; " * join(margins, "; ") *
        " (amplitude convention fixed 2026-10-21, post-hoc)",
        "post-hoc (η_T = 0.5 input correction; result known from 19f; amplitude convention fixed 2026-10-21, post-hoc)",
        joinpath(_VAL_REPORT_DIR, "pain_reproduction_e16.md"),
    )
end

"""T2 1/3-octave vs Fig. E-9 (stale bb_j2_scale; no claim)."""
function _run_t2()
    targets = _data_path("cr3813", "t2_third_octave_targets.csv")
    isfile(targets) || (targets = _data_path("cr3813", "t2_third_octave_targets_B.csv"))
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
        (; source=:e11, bpf_Hz=200.0, bands="1.25–2 kHz (targets CSV)", bb_j2_scale=0.5,
         csv=targets),
        table, series, all_ok ? :met : :not_met,
        "$n_ok/$(length(fcs)) PASS; T2 carries stale bb_j2_scale (no claim) (amplitude convention fixed 2026-10-21, post-hoc). " *
        "Phase 47/55 (2026-10-23): fed the measured TP-2444 exterior, this surrogate cabin path gives 38.6 dB at 1250 Hz " *
        "and the printed Eqs. (19)–(23) 21.6 dB, against E-9's 51.0; the modelled exterior is 17 dB above the measured one",
        "calibrated (in-sample; amplitude convention fixed 2026-10-21, post-hoc)",
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
        "CYL2D_C1", "Cabin acoustic modes (CYL2D) vs Table C-1 / Fig. C-3", "15",
        String[],
        FigureRef("CR-3813", "Table C-1 / Fig. C-3", nothing),
        "Frequency ratios f_i/f_1 of modes 2–19 within 0.1 % of Table C-1 (independent of sound speed c0; c0 = 341 m/s is back-solved from the table, so absolute frequencies are not a test); rigid mode < 0.01 Hz; generalized mass Φ_G within 0.1 %; symmetry equal. Fig. C-3 node values are checked in Pkg.test. Ratio form re-stated 2026-10-21 after the result was known.",
        "2026-10-20 (ratio form 2026-10-21, post-hoc)", "V-CODE", _run_cyl2d_c1,
        PlotSpec(; xlabel="mode number", ylabel="frequency (Hz) / Φ_G",
                 panel_titles=["frequency vs mode", "Φ_G vs mode"],
                 tolerance_band=nothing,
                 error_mode=:relative_pct, error_tol=0.1),
        "",
    ))

    push!(cases, ValidationCase(
        "MRP_D1", "Structural mode frequencies from Table D-1 seed (transcription)", "15",
        String[],
        FigureRef("CR-3813", "Table D-1 / Fig. D-2", 113),
        "Production seed frequencies equal Table D-1 (exact load): a transcription check, no verdict. Raw Ritz vs D-1 is a calibrated fit (MRP_RITZ), not evidence.",
        "2026-10-20", "transcription (by construction)", _run_mrp_d1,
        PlotSpec(; xlabel="mode number", ylabel="frequency (Hz)",
                 panel_titles=["frequency vs mode"],
                 error_mode=:absolute, error_ylabel="Hz"),
        "",
    ))

    push!(cases, ValidationCase(
        "T1", "Tonal interior sound-pressure level vs Fig. E-16 / E-17", "18",
        [_data_path("cr3813", "t1_interior_targets.csv")],
        FigureRef("CR-3813", "Fig. E-16 / E-17", 142),
        "Harmonics H1–H3: |computed − measured mean| ≤ 4 dB (gate A), or inside the measured envelope and |computed − NASA PAIN prediction| ≤ 4 dB (gate B). Label: calibrated (in-sample); T1 not claimable after the grid-extension (GEXT) importance bound (phase 32). (amplitude convention fixed 2026-10-21, post-hoc)",
        "2026-10-20", "calibrated (in-sample; amplitude convention fixed 2026-10-21, post-hoc)", _run_t1,
        PlotSpec(; xlabel="1/3-octave band (Hz)", ylabel="SPL (dB)",
                 xscale=:log10, xlim=(160.0, 2000.0),
                 panel_titles=["Fig. E-16 interior SPL"], tolerance_band=4.0,
                 error_tol=4.0),
        "",
    ))

    push!(cases, ValidationCase(
        "T2", "1/3-octave interior sound-pressure level vs Fig. E-9 / E-10 (surrogate)", "18",
        filter(isfile, [_data_path("cr3813", "t2_third_octave_targets.csv"), _data_path("cr3813", "t2_third_octave_targets_B.csv")]),
        FigureRef("CR-3813", "Fig. E-9 / E-10", 132),
        "Bands listed in the targets CSV: |computed − measured mean| ≤ tol_dB from that CSV. Uses stale broadband scale bb_j2_scale = 0.5; no claim. (amplitude convention fixed 2026-10-21, post-hoc)",
        "2026-10-20", "calibrated (in-sample; amplitude convention fixed 2026-10-21, post-hoc)", _run_t2,
        PlotSpec(; xlabel="1/3-octave band (Hz)", ylabel="SPL (dB)",
                 xscale=:log10, xlim=(1000.0, 2600.0),
                 panel_titles=["Fig. E-9"],
                 error_mode=:absolute, error_tol=3.5),
        "",
    ))

    push!(cases, ValidationCase(
        "REPRO_18b", "Cabin-chain reproduction vs NASA PAIN predictions (18b-r)", "18",
        [_data_path("cr3813", "t1_interior_targets.csv")],
        FigureRef("CR-3813", "Fig. E-16 NASA PAIN pred", 142),
        "|computed − NASA PAIN prediction| ≤ 4 dB at harmonics H1–H3 (registered 2026-10-20). (amplitude convention fixed 2026-10-21, post-hoc)",
        "2026-10-20", "post-hoc (η_T = 0.5 input correction; result known from 19f; amplitude convention fixed 2026-10-21, post-hoc)", _run_repro_18b,
        PlotSpec(; xlabel="harmonic band (Hz)", ylabel="SPL (dB)",
                 xscale=:log10, panel_titles=["vs NASA PAIN"], tolerance_band=4.0,
                 error_tol=4.0),
        "",
    ))

    # Filled by `_finish_validation_registry!` in validation_case_extras.jl after extra runners load.
    return cases
end

# Populated at the end of validation_case_extras.jl
const VALIDATION_CASES = Dict{String,ValidationCase}()
const VALIDATION_CASE_ORDER = String[]

function list_validation_cases()
    return [VALIDATION_CASES[id] for id in VALIDATION_CASE_ORDER if haskey(VALIDATION_CASES, id)]
end

"""True when the GUI should enable Run (not greyed)."""
function validation_case_runnable(id::AbstractString)
    haskey(VALIDATION_CASES, id) || return false
    return isempty(VALIDATION_CASES[id].unavailable_reason)
end

"""
Cases that are not validation cases under the meaningfulness rule (Phase 82, author 2026-10-29; `CLAUDE.md`): a verdict
needs a comparison with experimental data, or a check that the code works exactly like PAIN given PAIN's own inputs.
These compare with something else, so they run unchanged but carry no verdict (information); the outcome they
recorded is kept in `inputs_echo.original_verdict` and in the reason text. Never a pass.
"""
const INFORMATION_ONLY_CASES = Dict(
    "LOUDEST_PT" => "the point form against Eq. (8) is an internal consistency check",
    "BLK_GAIN_MAP" => "a 0–6.02 dB gain range is a property of Eq. (43), not a PAIN output or a measurement",
    "MRP_SHAPE_NORM" => "it tests a property of NASA's printed Table D-1, not this code",
    "CYL2D_WEYL" => "Weyl's law is an asymptotic mode count, not a PAIN output or a measurement",
    "MRP_COUPLED_LIMITS" => "analytic limits of the Ritz energy; PAIN's floor form is not that energy",
    "F1A_GUTIN_ANGLES" => "Gutin's far-field formula is a different method, not a measurement",
    "SHARP_PANEL_D" => "CR-172490's design figure is neither PAIN nor a measurement",
    # Phase 83d (2026-10-29): a path calibrated to the data it is compared with (CLAUDE.md); T2_EQ19 is the printed-method T2
    "T2" => "its broadband path uses `bb_j2_scale`, fitted to Fig. E-9, and is compared with Fig. E-9; T2_EQ19 carries the printed-method T2",
    # Phase 85 (Q63, 2026-10-29): the met cases audited with the same rule. Each compares with an identity, a hand or closed
    # form, a property, another method or code, or checks inputs rather than reproducing a PAIN output: verification.
    "E11_FREEFIELD" => "two digitizations of Fig. E-11 against each other: input repeatability, not the code",
    "ISO_FF_CONV" => "SPL↔Pa round trip and loader against a hand conversion: identity",
    "ISO_TABLE8" => "the Table 8 calibration is the identity on its own peaks: identity",
    "UT_GRID" => "grid coordinates against the User Manual's formulas: an input check, not a PAIN output",
    "ISO_GEXT_LINE" => "grid extension returns its input on ℓ = 1: identity",
    "ISO_BLOCKING" => "full-grid blocking against the same Eq. (43) factor: identity",
    "MRP_TRUNC" => "a property of the solver's shapes (unit maximum), not a PAIN output or a measurement",
    "ISO_CYL2D_EXACT" => "an analytic circular duct, not a PAIN output or a measurement",
    "ISO_CYL2D_BOUNDARY" => "boundary values and mode list against the code's own nodes: internal consistency",
    "TRIM_CLOSED" => "the trim stack against a closed-form transfer matrix: hand form",
    "ISO_JOINT_ACC" => "joint acceptance against numerical quadrature of the same integral",
    "ISO_MODAL_DENSITY" => "modal density against a count of the same modes: internal consistency",
    "ISO_BB_BAND" => "band integral against its closed form",
    "ISO_SIL" => "SIL against a hand evaluation",
    "LOUDEST_PT_GRID" => "the point form against Eq. (8): internal consistency",
    "NR_BAND_HAND" => "one NR band against a hand evaluation of Eqs. (17)–(18)",
    "HF_MASSLAW" => "HF transmission against a hand evaluation of Eq. (20)",
    "BPM_RP1218" => "NASA's BPM code is not PAIN, and RP-1218's tables are its output, not a measurement",
    "SHARP_PANEL_D_SHAPE" => "CR-172490's design figure is neither PAIN nor a measurement",
    "F1A_PLANE_PEAK" => "where the peak lies is a property of the field, not a PAIN output or a measurement",
    "FF_E11_MAP" => "holds by construction (GEXT multiplies by ≤ 1)",
    "SRC_PASSTHROUGH" => "the stored inputs against the source grid: plumbing identity",
    "MRP_INPUT_QA" => "structural inputs against App. E's printed values: an input check, not a PAIN output",
    "CABIN_GEOM_HAND" => "cabin geometry against hand formulas",
    "TRIM_INPUT_QA" => "trim inputs against App. E's printed values: an input check, not a PAIN output",
    "TRIM_PASSIVITY" => "passivity is a physical bound, not a PAIN output or a measurement",
    "PAIN_INPUT_ECHO" => "resolved inputs against the User Manual's formulas: an input check, not a PAIN output",
    "AC_CABIN_DEMO" => "the dB(A) sum against its own bands: arithmetic",
    "BEMT_MOMENTUM" => "BEM momentum = blade element: identity of the converged solution",
    "BEMT_HAND_TIP" => "the BEMT wrapper against a hand BEM",
    "BEMT_INTEGRALS" => "integrals, the Froude bound and station convergence: internal consistency",
    "BEMT_SIMILARITY" => "coefficients at fixed J: similarity identity",
    "F1A_GW_FLIGHT" => "Garrick–Watkins is a different method, not a measurement",
    "F1A_THICKNESS" => "the compact monopole form is a different method, not a measurement",
    "F1A_PROPERTIES" => "blade-count and 1/r scaling and convergence: internal consistency",
    "BEMT_HAND" => "the BEMT wrapper against a hand BEM",
    "F1A_GUTIN" => "Gutin's far-field formula is a different method, not a measurement",
    "F1A_INDEP" => "an independent F1A implementation is another code, not a measurement",
    "BBN_KIN" => "the phase step m·B·Δψ is kinematics, not a PAIN output or a measurement",
)

"""
Diagnostic runs (author 2026-10-29: "these diagnostics shouldnt be included in a validation map"): a re-run of another
case with one program form or input set changed to test a documented cause of that case's miss. The case they re-run
carries the verdict; the diagnostic answers whether the cause holds, so it carries no verdict and stays off the map.
Its recorded outcome is kept in `inputs_echo.original_verdict`, like an information case. The rule is by kind, applied
to every such re-run whatever its outcome.
"""
const DIAGNOSTIC_CASES = Dict(
    "REPRO_18b_PRE" => "re-runs REPRO_18b with the pre-correction Eq. (52) floor sign (Phase 61b): refuted",
    "E21_PRE" => "re-runs the E-21 NASA comparison with the pre-correction Eq. (52) floor sign (Phase 61c): refuted",
    "REPRO_18b_DECK" => "re-runs REPRO_18b_PRE on NASA's 300 MRP-deck modes (Phase 83e): refuted",
    "E21_PRE_DECK" => "re-runs E21_PRE on NASA's 300 MRP-deck modes (Phase 84c): refuted",
    "E22_HF_DECK" => "re-runs E22_HF_CODE on NASA's 300 MRP-deck modes (Phase 83b): refuted",
    "T2_EQ19_DECK" => "re-runs T2_EQ19 on NASA's 300 MRP-deck modes (Phase 83c): refuted",
    "R172428_CODE_DECK" => "re-runs R172428_CODE on NASA's 300 MRP-deck modes (Phase 84b): refuted",
    "R172428_EXP_DECK" => "re-runs R172428_EXP on NASA's 300 MRP-deck modes (Phase 84b): refuted",
    # Phase 88 (2026-10-29): the q = 0 hypothesis on CR-3813's printed runs, held out
    "Q0_REPRO_18b" => "re-runs REPRO_18b_PRE with the q = 0 cabin modes uncoupled (Phase 88a)",
    "Q0_E18" => "re-runs E18_TONES in the pre-correction form with the q = 0 cabin modes uncoupled (Phase 88b)",
    "Q0_E21" => "re-runs E21_PRE with the q = 0 cabin modes uncoupled (Phase 88c)",
    "R172428_CODE_ETAN" => "re-runs R172428_CODE with η_n per cabin mode, trim per 1/3-octave band (Phase 89b)",
    # Phase 92 (2026-10-29): NASA's printed mode-pair contributions; q = 0 off on the held-out 3000 rpm points
    "APPB_PAIRS" => "sets this code's Eq. (8) pair terms against NASA's printed largest contributors (Phase 92a)",
    "APPB_PAIRS_Q0_ETAN" => "re-runs APPB_PAIRS with q = 0 off and η_n per cabin mode, post-hoc (Phase 92c)",
    "R172428_CODE_Q0" => "re-runs R172428_CODE with the q = 0 cabin modes uncoupled; 3000 rpm held out (Phase 92b)",
    "R172428_CODE_Q0_ETAN" => "re-runs R172428_CODE with q = 0 off and η_n per cabin mode, post-hoc (Phase 92c)",
    # Phase 96 (2026-10-30): the band-centre η_n rule read from App. B (post-hoc on those values)
    "APPB_ETA_N_BAND" => "sets the default η_n rule against the App. B values it was read from, post-hoc (Phase 96a)",
    "R172428_CODE_DEFAULT" => "re-runs R172428_CODE with the code as it ships, post-hoc (Phase 96d)",
    # Phase 99 (2026-10-30): the band-centre η_n in the program behind CR-3813's printed runs, held out
    "BAND_REPRO_18b" => "re-runs REPRO_18b_PRE with the band-centre η_n of Phase 95 (Phase 99a)",
    "BAND_E18" => "re-runs E18_TONES in the pre-correction form with the band-centre η_n (Phase 99b)",
    # Phase 100 (2026-10-30): NASA's per-band PF-105 table against the App. B admittances (selects the insulation input)
    "R172428_TRIM_DECK" => "sets NASA's App. D PF-105 deck table against App. B's trim admittances; selects the input (Phase 100a)",
    # Phase 102 (2026-10-30): flight run 10, H2–H4; FLIGHT_MODES not met, so no verdict
    "FLIGHT10_H234" => "sets the code as it ships and the trim per band against PAIN's printed run 10 levels (Phase 102)",
    "FLIGHT_MODES_P2" => "re-runs FLIGHT_MODES on the checked (second-pass) App. C transcription (Phase 110, post-hoc)",
    "FLIGHT10_FLOOR_SIGN" => "tests on the printed H1/H5 pairs whether run 10 used the pre-correction floor-term sign (Phase 108)",
)

"""True for a case that carries no verdict by rule: an information case or a diagnostic run."""
no_verdict_by_rule(id::AbstractString) = haskey(INFORMATION_ONLY_CASES, id) || haskey(DIAGNOSTIC_CASES, id)

"""Verdict of the check itself: an information or diagnostic case's recorded outcome (`original_verdict`), else its verdict."""
underlying_verdict(r::ValidationCaseResult) = get(r.inputs_echo, :original_verdict, r.verdict)

"""Turn a verdict-bearing result of an `INFORMATION_ONLY_CASES` or `DIAGNOSTIC_CASES` case into a result with no verdict."""
function _as_information_case(r::ValidationCaseResult)
    info = get(INFORMATION_ONLY_CASES, r.id, nothing)
    diag = get(DIAGNOSTIC_CASES, r.id, nothing)
    (info === nothing && diag === nothing || r.verdict === :no_verdict) && return r
    head = info !== nothing ? "information: not a validation case under the 2026-10-29 rule ($info)" :
           "diagnostic: $diag; the case it re-runs carries the verdict"
    reason = "$head; recorded outcome unchanged, not a pass: $(replace(String(r.verdict), "_" => " ")), $(r.reason)"
    return ValidationCaseResult(r.id, r.date, merge(r.inputs_echo, (; original_verdict=r.verdict)), r.table, r.series,
                                :no_verdict, reason, r.label, r.report_path)
end

"""
    run_validation_case(id) -> ValidationCaseResult

Run the registered case. Inputs are fixed; missing reference files yield `:no_verdict`; an
`INFORMATION_ONLY_CASES` or `DIAGNOSTIC_CASES` case returns no verdict (Phases 82, 86).
Greyed cases (`unavailable_reason` non-empty) still return their stub result if Run is forced.
"""
function run_validation_case(id::AbstractString)
    haskey(VALIDATION_CASES, id) || error("unknown validation case id: $id")
    case = VALIDATION_CASES[id]
    if !isempty(case.unavailable_reason)
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
    return _as_information_case(case.run())
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
