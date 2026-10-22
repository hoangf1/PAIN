"""
    PAIN

Julia recreation of NASA Propeller Aircraft Interior Noise (PAIN).
Propeller free-field source: CCBlade.jl + AcousticAnalogies.jl (replaces ANOPP).
See `docs/VALIDATION_GUIDELINE.md` and `docs/flowchart.md`.
"""
module PAIN

using LinearAlgebra
using JSON3
using FFTW
using CCBlade
using AcousticAnalogies
using AcousticMetrics
using Observables
using QML
using Dates
using CairoMakie

include("geometry.jl")
include("blocking.jl")
include("grid_extension.jl")
include("cyl2d.jl")
include("mrp.jl")
include("propeller_ccblade.jl")
include("polars.jl")
include("freefield_digitized.jl")
include("trim_loss.jl")
include("pain_core.jl")
include("noise_reduction.jl")
include("high_freq_tones.jl")
include("metrics.jl")
include("validation_report.jl")
include("validation_cases.jl")
include("validation_case_extras.jl")
include("validation_map.jl")
include("validation_plots.jl")
include("gui_model.jl")
include("gui_main.jl")

export
    FuselageGeometry, PropellerPlacement, GridSpec, grid_points,
    incidence_angle_deg,
    blocking_factor, blocked_amplitude, BlockingVariant, R1, R2,
    delta_L_blocking_dB, BLOCKING_P68_CHECKPOINTS,
    extend_line_to_grid,
    cyl2d_modes, cyl2d_modes_search, Cyl2DResult, AcousticMode, TABLE_C1_FREQ_HZ, TABLE_C1_GENMASS, TABLE_C1_SYMMETRIC, TABLE_C1_C0,
    cabin_frequency_3d, cabin_eps_3d, axial_truncation, cabin_modes_3d,
    scale_acoustic_freq, acoustic_boundary_value,
    structural_modes, structural_modes_from_table_d1, fit_mrp_to_table_d1, match_ritz_to_table_d1,
    StructuralModes, StructuralMode, structural_shell_psi, structural_floor_psi, TABLE_D1_CORE, TABLE_D1_FULL,
    coupling_factor, axial_coupling,
    FreeFieldHarmonicGrid, Observer, SourceResult,
    propeller_freefield_grid, synthetic_freefield_grid,
    evaluate_propeller_source, grid_observers, hub_observers, apply_table8_calibration,
    ScaledLoads, load_polar_set, PolarStats,
    total_rms, pressure_coefficient_pc, pa_to_dyne_cm2, dyne_cm2_to_pa, blade_form_geometry,
    apply_blocking,
    freefield_from_e11_csv, delta_dig_dB, default_e11_paths, spl_dB_to_Pa, spl_dB_to_peak_Pa, peak_Pa_to_spl_dB,
    PainInputs, InteriorSpectrum, interior_spl, cabin_volume, tone_mean_square_pressure, generalized_force, generalized_force_amplitude,
    absorption_coefficient,
    C_OMEGA_THIRD_OCTAVE, nr_b, nr_c, nr_ln, nr_arctan, nr_D, nr_brace,
    nr_band_integral_closed, nr_band_integral_quad,
    cylinder_surface_area, coupling_area, mass_law_factor,
    acoustic_modes_in_band, acoustic_crossover_band, apply_η_r_cap,
    w_in_reverberant, noise_reduction_band, noise_reduction_spectrum,
    noise_reduction_test_article_inputs,
    g_resonance, expected_g_closed, expected_g_pi, expected_g_quad,
    tone_Q_H, modes_in_tone_band, band_average_loss_factors,
    tone_expected_value, tone_eq13_sample, resolve_crossover_Hz,
    tone_mean_square_pressure_pair, third_octave_centers,
    InsulationTable, load_insulation_table, pf105_table, insulation_properties,
    TrimElement, InsulationLayer, LimpMass, TrimStack, element_matrix, stack_matrix, stack_extrapolated,
    trim_tau_insulation, trim_Cw, trim_admittance, trim_conductance, trim_tau,
    MechanicalPath, coupling_loss_factor_21, trim_tau_mechanical, phase3_trim,
    sine_integral, cin, ring_joint_acceptance, axial_joint_acceptance, structural_joint_acceptance,
    acoustic_loss_modal, acoustic_loss_average, absorption_from_loss_factor,
    structural_loss_vacuo, radiation_loss_factor, structural_loss_total, structural_loss_with_trim, structural_loss_coupled,
    a_weight_dB, sil_dB, overall_dBA, sil_from_third_octave,
    ValidationRecord, write_validation_record,
    run_pain_pipeline, evaluate_T1, evaluate_T2, validate_mrp_table_d1,
    main, make_gui_observables, run_pain_gui!,
    PlotSeries, PlotSpec, FigureRef, ValidationTableRow, ValidationCase, ValidationCaseResult,
    VALIDATION_CASES, VALIDATION_CASE_ORDER, list_validation_cases,
    validation_case_runnable, run_validation_case, format_validation_result,
    plot_case, validation_figure_path, validation_source_figure_path,
    VALIDATION_SOURCE_FIGURE_FALLBACKS,
    CaseInfo, MapBlock, ValidationMap, CASE_INFO, VALIDATION_MAPS,
    validation_guideline_path, parse_validation_guideline_section,
    load_validation_docs!, reload_validation_docs!,
    validation_map_json, case_info_json, validation_map_case_order,
    f1a_gutin_h1_comparison,
    run_validation_gui!, run_all_validation_gui!, reload_validation_docs_gui!

"""
    run_pain_pipeline(; source=:aircraft | :e11 | :synthetic, trim=:auto, ...)

End-to-end: free-field → blocking → CYL2D + MRP → interior SPL (Eq. 8 chain).

**User source (phase 33g):** `:aircraft` (BEMT + F1A) is the only user option in the GUI.
`:e11` and `:synthetic` remain callable for T1/T2, smoke tests and `Pkg.test()` only.

Cabin treatment (`trim`): `:bare` (τ_t = 1, η_n = `η_n_bare`), `:phase3` (the App. E Phase III stacks of
`phase3_trim`, test article only), or `:auto` (`:phase3` for `source=:e11`, `:bare` otherwise). Giving
`sidewall_trim_stack` and `end_trim_stack` (and optionally `mech`) overrides it with the user's stacks.
`C_struc` is the C of Eq. (80), `q_max` the axial truncation of the cabin modes, `NY` the CYL2D grid,
`allow_extrapolation` continues the insulation table beyond Fig. A-2 (X-EXTRAP).
"""
function run_pain_pipeline(;
        L::Float64=1.803,
        a::Float64=0.508,
        theta0_deg::Float64=56.6,
        r_p::Float64=0.965,  # a+0.457 User Manual grid; tip clearance ≈0.076 m @ Rtip=0.381
        phi_p_deg::Float64=90.0,
        z_p::Float64=0.90,
        aircraft_json::Union{Nothing,String}=nothing,
        source::Symbol=:aircraft,
        use_synthetic::Bool=false,   # legacy: true + no aircraft_json → :synthetic (tests)
        use_table_d1::Bool=true,
        blocking::BlockingVariant=R2,
        n_harmonics::Int=5,
        bpf_Hz::Float64=150.0,
        e11_amp_csv::Union{Nothing,String}=nothing,
        e11_phase_csv::Union{Nothing,String}=nothing,
        trim::Symbol=:auto,
        sidewall_trim_stack::Union{Nothing,TrimStack}=nothing,
        end_trim_stack::Union{Nothing,TrimStack}=nothing,
        mech::Union{Nothing,MechanicalPath}=nothing,
        η_n_bare::Float64=0.05,
        C_struc::Float64=3.0,
        q_max::Union{Nothing,Int}=nothing,
        NY::Int=10,
        allow_extrapolation::Bool=false)
    trim in (:auto, :bare, :phase3) || error("trim must be :auto, :bare or :phase3")
    fuse = FuselageGeometry(L, a, theta0_deg)
    prop = PropellerPlacement(r_p, phi_p_deg, z_p)
    spec = GridSpec()

    # Resolve source. User path is :aircraft. :e11 / :synthetic stay for validation scripts and tests
    # (phase 33g); the GUI does not offer them.
    src = source
    if aircraft_json !== nothing
        src = :aircraft
    elseif use_synthetic && source !== :e11
        src = :synthetic
    end

    paths = default_e11_paths()
    if src === :e11
        amp = something(e11_amp_csv, paths.A)
        ph = something(e11_phase_csv, paths.phases)
        nH = min(n_harmonics, 3)
        ff = freefield_from_e11_csv(amp, ph, fuse, prop, spec;
                                    bpf_Hz=bpf_Hz, n_harmonics=nH,
                                    anopp_spl_csv=paths.anopp_spl,
                                    broadband_clip_dB=10.0)
    elseif src === :aircraft
        aircraft_json === nothing && error("source=:aircraft requires aircraft_json")
        ff = propeller_freefield_grid(aircraft_json, fuse, prop, spec; n_harmonics=n_harmonics)
    else
        ff = synthetic_freefield_grid(fuse, prop, spec; n_harmonics=n_harmonics, bpf_Hz=bpf_Hz)
    end
    bl = apply_blocking(ff, fuse, prop; variant=blocking)

    acoustic = cyl2d_modes(theta0_deg; n_modes=20, NY=NY)
    structural = use_table_d1 ?
        structural_modes_from_table_d1(; L=L, a=a, theta0_deg=theta0_deg, n_keep=32) :
        structural_modes(fuse; n_keep=32)

    ΔA = (π * a / 18)^2  # User Manual grid spacing scale
    trim_used = trim === :auto ? (src === :e11 ? :phase3 : :bare) : trim
    sidewall = end_stack = mech_used = nothing
    m_wall = NaN
    if sidewall_trim_stack !== nothing || end_trim_stack !== nothing
        sidewall, end_stack, mech_used = sidewall_trim_stack, end_trim_stack, mech
        trim_used = :custom
    elseif trim_used === :phase3
        p3 = phase3_trim(; a=a, L=L, theta0_deg=theta0_deg)
        sidewall, end_stack, mech_used, m_wall = p3.sidewall, p3.ends, p3.mech, p3.m_wall
    end
    inp = PainInputs(fuse, prop, structural, acoustic,
                     bl.amplitudes, bl.phases, bl.pts, ΔA;
                     sidewall=sidewall, endplates=end_stack, mech=mech_used, m_wall=m_wall,
                     η_n_bare=η_n_bare, C_struc=C_struc, q_max=q_max,
                     allow_extrapolation=allow_extrapolation)
    spec_out = interior_spl(inp; bpf_Hz=bl.bpf_Hz, n_harmonics=min(n_harmonics, size(bl.amplitudes, 3)))
    return (; fuse, prop, ff=bl, acoustic, structural, spectrum=spec_out, source=src,
              trim=trim_used, inputs=inp)
end

"""
    evaluate_T1(spectrum; targets_csv=...) -> Vector{ValidationRecord}

Compare tonal H=1..3 interior SPL to digitized Fig. E-16/E-17 mean ± range.
"""
function evaluate_T1(spectrum::InteriorSpectrum;
                     targets_csv::AbstractString=joinpath(dirname(default_e11_paths().A), "t1_interior_targets.csv"))
    cols = _read_csv_numeric(targets_csv)
    records = ValidationRecord[]
    for i in eachindex(cols[:harmonic])
        H = Int(round(cols[:harmonic][i]))
        H > length(spectrum.harmonic_SPL_dB) && continue
        got = spectrum.harmonic_SPL_dB[H]
        mean = cols[:measured_mean_SPL_dB][i]
        # Primary: mean ± 4 dB (CR-172428 σ ≈ 4 dB). Secondary: inside measured
        # envelope AND within 4 dB of NASA PAIN prediction on E-16 (code-to-code).
        tol = 4.0
        lo_env = cols[:measured_low_dB][i]
        hi_env = cols[:measured_high_dB][i]
        nasa = cols[:nasa_pain_pred_dB][i]
        ok_mean = abs(got - mean) ≤ tol
        ok_nasa = (lo_env ≤ got ≤ hi_env) && abs(got - nasa) ≤ tol
        ok = ok_mean || ok_nasa
        band = haskey(cols, :band_Hz) ? Int(round(cols[:band_Hz][i])) : Int(round(H * spectrum.bpf_Hz))
        gate = ok_mean ? "mean±$(tol)" : (ok_nasa ? "NASA±$(tol)+env" : "FAIL")
        push!(records, ValidationRecord(
            "T1", "V-EXP",
            "Fig.E-16 re-digitized ($targets_csv)",
            "interior SPL H=$H @ $(band) Hz band",
            "mean ± $(tol) dB or NASA±$(tol) in env $(lo_env)-$(hi_env)",
            ok ? "PASS" : "FAIL",
            "got=$(round(got; digits=2)) dB; d_mean=$(round(got - mean; digits=2)); d_nasa=$(round(got - nasa; digits=2)); gate=$(gate)",
        ))
    end
    return records
end

"""
    evaluate_T2(spectrum; targets_csv=...) -> Vector{ValidationRecord}

1/3-octave gate vs Fig. E-9 mean ± tol (flowchart T2, 1.25–8 kHz).
"""
function evaluate_T2(spectrum::InteriorSpectrum;
                     targets_csv::AbstractString=joinpath(dirname(default_e11_paths().A), "t2_third_octave_targets.csv"))
    cols = _read_csv_numeric(targets_csv)
    records = ValidationRecord[]
    third = spectrum.third_octave_SPL_dB
    for i in eachindex(cols[:fc_Hz])
        fc = cols[:fc_Hz][i]
        mean = cols[:measured_mean_SPL_dB][i]
        tol = cols[:tol_dB][i]
        # nearest available band
        b = nearest_third_octave(fc, collect(keys(third)))
        got = get(third, b, NaN)
        ok = isfinite(got) && abs(got - mean) ≤ tol
        push!(records, ValidationRecord(
            "T2", "V-EXP, calibrated (bb_j2_scale, stale)",
            "Fig.E-9 digitized targets ($targets_csv)",
            "1/3-oct SPL fc=$(round(fc; digits=0)) Hz", "mean ± $(tol) dB",
            ok ? "PASS" : "FAIL",
            "got=$(round(got; digits=2)) dB mean=$(mean) band=$(round(b; digits=1))",
        ))
    end
    return records
end

"""Compare structural mode frequencies to Table D-1 (V-CODE)."""
function validate_mrp_table_d1(modes::StructuralModes; tol_frac::Float64=0.05,
                               label::AbstractString="V-CODE")
    records = ValidationRecord[]
    n = min(length(modes.modes), length(TABLE_D1_FULL))
    for i in 1:n
        ref = TABLE_D1_FULL[i][2]
        got = modes.modes[i].f_Hz
        err = abs(got - ref) / max(ref, 1e-9)
        ok = err ≤ tol_frac
        push!(records, ValidationRecord(
            "MRP", String(label),
            "CR-3813 Table D-1",
            "mode $i frequency", "≤ $(100 * tol_frac)%",
            ok ? "PASS" : "FAIL",
            "got=$(round(got; digits=2)) Hz ref=$ref Hz err%=$(round(100 * err; digits=2))",
        ))
    end
    return records
end

end # module
