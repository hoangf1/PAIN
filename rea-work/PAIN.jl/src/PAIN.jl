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
include("mrp_appd.jl")
include("propeller_ccblade.jl")
include("polars.jl")
include("freefield_digitized.jl")
include("trim_loss.jl")
include("pain_core.jl")
include("aircraft_provenance.jl")
include("uncertainty.jl")
include("mode_animation.jl")
include("noise_reduction.jl")
include("circular_cavity.jl")        # phase 43d: exact circular cavity + Donnell NR
include("high_freq_tones.jl")
include("hf_broadband.jl")
include("metrics.jl")
include("loudest_point.jl")          # phase 42 interior level at the loudest point
include("printed_outputs.jl")
include("validation_report.jl")
include("validation_cases.jl")
include("validation_case_iso40.jl")   # before extras: registry finish calls _iso40_validation_cases
include("validation_case_iso41.jl")   # phase 41 isolation of failing cases
include("validation_case_iso43.jl")   # phase 43 T1/T2 root causes + TP-1964
include("validation_case_iso44.jl")   # phase 44 CR-172428 reproduction (App. A / App. B)
include("validation_case_iso45.jl")   # phase 45 T2 HF path on TP-1964
include("sharp_bridges.jl")          # phase 59 Sharp sound bridges (CR-172490), option
include("bpm_airfoil_noise.jl")      # phase 48 airfoil self-noise (NASA RP-1218)
include("prop_broadband.jl")         # phase 48 propeller broadband at a field point
include("validation_case_iso47.jl")   # phase 47 T2 with the measured TP-2444 exterior
include("validation_case_iso48.jl")   # phase 48 exterior broadband from RP-1218
include("validation_case_iso50.jl")   # phase 50 propeller-field coupling for NR
include("validation_case_iso59.jl")   # phase 59 Sharp sound bridges
include("validation_case_iso61.jl")   # phase 61 CR-3813 reproduction with the pre-correction form
include("validation_case_iso62.jl")   # phase 62 a proving case for every map block
include("validation_case_iso66.jl")   # phase 66 further BEMT / F1A code checks
include("validation_case_iso67.jl")   # phase 67 attribution of the source-block misses
include("validation_case_extras.jl")
include("validation_map.jl")
include("validation_plots.jl")
include("gui_model.jl")
include("gui_main.jl")

export
    TEST_ARTICLE_L, TEST_ARTICLE_L_DEFAULT,
    test_article_length, test_article_length_overridden,
    set_test_article_length!, reset_test_article_length!, with_test_article_length,
    FuselageGeometry, PropellerPlacement, GridSpec, grid_points,
    incidence_angle_deg,
    blocking_factor, blocked_amplitude, BlockingVariant, R1, R2,
    delta_L_blocking_dB, BLOCKING_P68_CHECKPOINTS,
    extend_line_to_grid,
    cyl2d_modes, cyl2d_modes_search, Cyl2DResult, AcousticMode, TABLE_C1_FREQ_HZ, TABLE_C1_GENMASS, TABLE_C1_SYMMETRIC, TABLE_C1_C0,
    cabin_frequency_3d, cabin_eps_3d, axial_truncation, cabin_modes_3d,
    mode_animation_frames, render_mode_animation, render_mode_frame_pngs, axial_factor,
    FIG_C3_PRINTED_ROWS, CYL2D_C1_DISPLAY_INPUTS, cyl2d_c1_for_display, mode_animation_cache_dir,
    structural_mode_display, coupling_display, render_structural_mode_png,
    structural_mode_frames, render_structural_frame_pngs,
    fill_cabin_modes_gui!,
    scale_acoustic_freq, acoustic_boundary_value,
    structural_modes, structural_modes_from_table_d1, fit_mrp_to_table_d1, match_ritz_to_table_d1,
    StructuralModes, StructuralMode, structural_shell_psi, structural_floor_psi, TABLE_D1_CORE, TABLE_D1_FULL,
    AppDGeometry, appd_test_article_geometry, appd_modes, build_structural_modes,
    APPD_READINGS, donnell_mushtari_frequency_Hz, appd_shell_harmonic_frequency_Hz,
    appd_shell_condensed_frequency_Hz,
    appd_generalized_mass_from_shape, appd_smeared_stringer_frequency_Hz,
    appd_constraint_residuals, appd_max_constraint_residual, appd_mode_orthogonality,
    shell_circumferential,
    coupling_factor, axial_coupling,
    FreeFieldHarmonicGrid, Observer, SourceResult,
    propeller_freefield_grid, synthetic_freefield_grid,
    evaluate_propeller_source, grid_observers, hub_observers, R996_X_SIGN, pereira_observers, airfoil_area_over_chord2, naca4_area_over_chord2, station_area_over_chord2, report996_area_over_chord2, apply_table8_calibration,
    ScaledLoads, load_polar_set, PolarStats, PolarSet, section_polar, station_polars, AIR_MU_PA_S,
    measured_polar_series, interp_no_extrap,
    ccblade_section_operating_points, polar_coverage_recount,
    total_rms, pressure_coefficient_pc, pa_to_dyne_cm2, dyne_cm2_to_pa, blade_form_geometry,
    apply_blocking,
    freefield_from_e11_csv, delta_dig_dB, default_e11_paths, spl_dB_to_Pa, spl_dB_to_peak_Pa, peak_Pa_to_spl_dB,
    PainInputs, InteriorSpectrum, interior_spl, cabin_volume, tone_mean_square_pressure, generalized_force, generalized_force_amplitude,
    apply_rotation_direction_phases!,
    absorption_coefficient,
    C_OMEGA_THIRD_OCTAVE, nr_b, nr_c, nr_ln, nr_arctan, nr_D, nr_brace,
    nr_band_integral_closed, nr_band_integral_quad,
    cylinder_surface_area, coupling_area, mass_law_factor,
    acoustic_modes_in_band, acoustic_crossover_band, apply_η_r_cap,
    volume_crossover_frequency_Hz, volume_crossover_band,
    tp1964_hf_inputs, cabin_interior_points, cabin_quadrature_points, point_tone_p2, point_volume_average, loudest_point,
    trimmed_modal_mass, app_a_modal_mass_per_area, r172428_appb_field, r172428_inputs,
    write_h3_attribution_report,
    w_in_reverberant, noise_reduction_band, noise_reduction_spectrum,
    noise_reduction_test_article_inputs,
    CircularAcousticMode, circular_cavity_modes, besselj_prime_zeros,
    donnell_shell_modes, circular_coupling_factor, circular_acoustic_eps,
    loglog_interp_eta, eta_from_reverberation_csv,
    noise_reduction_band_circular, noise_reduction_spectrum_circular,
    hf_absorbing_areas, hf_trim_areas, hf_structural_band, hf_band_loss_factors,
    hf_transmission_coeffs, hf_pressure_ratio, hf_broadband_band_p2, hf_broadband_spectrum,
    g_resonance, expected_g_closed, expected_g_pi, expected_g_quad,
    tone_Q_H, modes_in_tone_band, band_average_loss_factors,
    tone_expected_value, tone_eq13_sample, resolve_crossover_Hz,
    tone_mean_square_pressure_pair, third_octave_centers, nearest_third_octave,
    standard_third_octave_centers, validate_band_set, resolve_bands, containing_third_octave,
    third_octave_band_edges, snap_third_octave_center, loss_factor_override,
    structural_η_r_prime, acoustic_N, resolve_η_n_band,
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
    parse_tagged_value, apply_aircraft_cabin_json, collect_nasa_defaults_used,
    provenance_header_labels, empty_provenance, NASA_DEFAULTS, nasa_default_m_wall,
    resolve_cabin_blocks, build_appd_geometry, parse_aircraft_trim_json,
    UncertaintyBudgetRow, UncertaintyBudget, UncertaintyChainCache,
    uncertainty_budget, active_budget_rows, nominal_sample,
    build_testarticle_cache, build_aircraft_cache, evaluate_uncertainty_sample,
    oat_sweep, monte_carlo_band, coverage_check, e16_measured_means,
    phase_bounding_cases, bbn_h1_residual_gradient_ratio, bbn_printed_pair_phase,
    uncertainty_report_md, UNC_REQUIRED_STATEMENTS, UNC_MC_N, UNC_MC_SEED,
    main, make_gui_observables, run_pain_gui!,
    PlotSeries, PlotSpec, FigureRef, ValidationTableRow, ValidationCase, ValidationCaseResult,
    VALIDATION_CASES, VALIDATION_CASE_ORDER, list_validation_cases,
    validation_case_runnable, run_validation_case, format_validation_result,
    plot_case, validation_figure_path, validation_figure_dir, VALIDATION_FIGURE_DIRS, validation_source_figure_path,
    case_error_summary, case_error_summary_path, write_case_error_summary, recorded_case_errors,
    VALIDATION_SOURCE_FIGURE_FALLBACKS,
    CaseInfo, MapBlock, ValidationMap, CASE_INFO, VALIDATION_MAPS,
    validation_guideline_path, parse_validation_guideline_section,
    load_validation_docs!, reload_validation_docs!,
    validation_map_json, case_info_json, map_block_info_json, validation_map_case_order,
    validation_map_group_rects, assert_validation_map_groups_disjoint,
    f1a_gutin_h1_comparison,
    run_validation_gui!, run_all_validation_gui!, reload_validation_docs_gui!,
    structural_modes_in_band, modal_tone_contributions, printed_outputs,
    write_printed_outputs_md, format_printed_outputs_text, printed_outputs_gui_json,
    run_printed_outputs_gui!,
    run_cabin_modes_from_qml, set_cabin_mode_from_qml, set_cabin_q_from_qml,
    cabin_modes_step_frame_from_qml, set_cabin_struct_from_qml

"""
    run_pain_pipeline(; source=:aircraft | :e11 | :synthetic, trim=:auto,
                      cabin_blocks=:auto, ...)

End-to-end: free-field → blocking → CYL2D + MRP → interior SPL (Eq. 8 chain).

**User source (phase 33g):** `:aircraft` (BEMT + F1A) is the only user option in the GUI.
`:e11` and `:synthetic` remain callable for T1/T2, smoke tests and `Pkg.test()` only.

Cabin treatment (`trim`): `:bare` (τ_t = 1, η_n = `η_n_bare`), `:phase3` (the App. E Phase III stacks of
`phase3_trim`, test article only), or `:auto` (`:phase3` for `source=:e11`, `:bare` otherwise). Giving
`sidewall_trim_stack` and `end_trim_stack` (and optionally `mech`) overrides it with the user's stacks.
`C_struc` is the C of Eq. (80), `q_max` the axial truncation of the cabin modes, `NY` the CYL2D grid,
`allow_extrapolation` continues the insulation table beyond Fig. A-2 (X-EXTRAP).

**cabin_blocks (phase 30):** `:parametric` | `:surrogate` | `:auto`.
`:auto` → `:parametric` on `source=:aircraft`, `:surrogate` otherwise (validation/e11/synthetic
bit-identical). `:parametric` selects `broadband_model=:eq19` (Eqs. 19–23; open readings I-21 →
X-EXTRAP with phase-31 epistemic band, not a prediction of accuracy), `structural_solver=:appd`
(App. D modes from user geometry / skin / stringer / frame / floor), and no η_r cap / no
absorption curve / no `bb_j2_scale` unless the JSON asks for them. `:surrogate` keeps the
current Table D-1 + absorption/`bb_j2_scale` path.
"""
function run_pain_pipeline(;
        L::Float64=test_article_length(),
        a::Float64=0.508,
        theta0_deg::Float64=56.6,
        r_p::Float64=0.965,  # a+0.457 User Manual grid; tip clearance ≈0.076 m @ Rtip=0.381
        phi_p_deg::Float64=90.0,
        z_p::Float64=0.662,  # CR-3813 App. E p. E-8 / CR-172428 Table 6 (Phase 65; was 0.90 m)
        rotation_direction::Int=1,
        aircraft_json::Union{Nothing,String}=nothing,
        source::Symbol=:aircraft,
        use_synthetic::Bool=false,   # legacy: true + no aircraft_json → :synthetic (tests)
        use_table_d1::Bool=true,
        structural_solver::Symbol=:table_d1,
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
        allow_extrapolation::Bool=false,
        ρ0::Float64=1.225,
        c0::Float64=340.0,
        ρ_ext::Union{Nothing,Float64}=nothing,
        c_ext::Union{Nothing,Float64}=nothing,
        ρ_int::Union{Nothing,Float64}=nothing,
        c_int::Union{Nothing,Float64}=nothing,
        L_c::Union{Nothing,Float64}=nothing,
        d::Float64=0.0,
        bands=nothing,
        η_r_band=nothing,
        η_n_band=nothing,
        m_wall::Float64=NaN,
        bb_j2_scale::Float64=0.5,
        bb_α::Float64=2.0,
        broadband_model::Symbol=:surrogate,
        spbl_anchor_H::Int=3,
        cabin_blocks::Symbol=:auto,
        appd_overrides::Dict{Symbol,Float64}=Dict{Symbol,Float64}(),
        grid_fill::Symbol=:gext,
        f1a_pattern_amps::Union{Nothing,Array{Float64,3}}=nothing,
        f1a_pattern_phases::Union{Nothing,Array{Float64,3}}=nothing,
        tone_model::Symbol=:eq8,
        η_r_band_is_prime::Bool=false,
        η_r_trimmed_area::Bool=false)
    trim in (:auto, :bare, :phase3, :custom) ||
        error("trim must be :auto, :bare, :phase3 or :custom")

    # Resolve source. User path is :aircraft. :e11 / :synthetic stay for validation scripts and tests
    # (phase 33g); the GUI does not offer them.
    src = source
    cfg = nothing
    prov_inputs = NamedTuple[]
    supplied = Set{String}()
    if aircraft_json !== nothing
        src = :aircraft
        cfg = _load_aircraft_json(aircraft_json)
        # Phase 29b/29c/30: cabin provenance + 38f card keys (geometry L/a/θ0 only from cabin.*)
        applied = apply_aircraft_cabin_json(cfg, (;
            L, a, theta0_deg, r_p, phi_p_deg, z_p, rotation_direction,
            η_n_bare, C_struc, NY, ρ0, c0, ρ_ext, c_ext, ρ_int, c_int,
            L_c, d, use_table_d1, structural_solver, m_wall,
            bb_j2_scale, bb_α, broadband_model, spbl_anchor_H, q_max, allow_extrapolation,
            bands, η_r_band, η_n_band, trim, cabin_blocks,
            sidewall_trim_stack, end_trim_stack, mech))
        kw = applied.kwargs
        L = kw.L; a = kw.a; theta0_deg = kw.theta0_deg
        r_p = kw.r_p; phi_p_deg = kw.phi_p_deg; z_p = kw.z_p
        rotation_direction = kw.rotation_direction
        η_n_bare = kw.η_n_bare; C_struc = kw.C_struc; NY = kw.NY
        ρ0 = kw.ρ0; c0 = kw.c0
        ρ_ext = kw.ρ_ext; c_ext = kw.c_ext; ρ_int = kw.ρ_int; c_int = kw.c_int
        L_c = kw.L_c; d = kw.d
        use_table_d1 = kw.use_table_d1; structural_solver = kw.structural_solver
        m_wall = kw.m_wall
        bb_j2_scale = kw.bb_j2_scale; bb_α = kw.bb_α
        broadband_model = kw.broadband_model; spbl_anchor_H = kw.spbl_anchor_H
        q_max = kw.q_max; allow_extrapolation = kw.allow_extrapolation
        bands = kw.bands; η_r_band = kw.η_r_band; η_n_band = kw.η_n_band
        trim = kw.trim
        cabin_blocks = kw.cabin_blocks
        sidewall_trim_stack = kw.sidewall_trim_stack
        end_trim_stack = kw.end_trim_stack
        mech = kw.mech
        appd_overrides = kw.appd_overrides
        prov_inputs = applied.provenance_inputs
        supplied = applied.supplied_names
    elseif use_synthetic && source !== :e11
        src = :synthetic
    end

    # Phase 30b/30c: resolve cabin_blocks and apply parametric defaults when not JSON-supplied
    blocks = resolve_cabin_blocks(cabin_blocks, src)
    if blocks === :parametric
        if !("structural_solver" in supplied)
            structural_solver = :appd
            use_table_d1 = false
        end
        if !("broadband_model" in supplied)
            broadband_model = :eq19
        end
        # No η_r cap on the parametric path (callers may still pass η_r_cap into
        # printed_outputs / noise_reduction separately; interior_spl default is nothing).
    end

    fuse = FuselageGeometry(L, a, theta0_deg)
    prop = PropellerPlacement(r_p, phi_p_deg, z_p, rotation_direction)
    spec = GridSpec()

    paths = default_e11_paths()
    if src === :e11
        amp = something(e11_amp_csv, paths.A)
        ph = something(e11_phase_csv, paths.phases)
        nH = min(n_harmonics, 3)
        ff = freefield_from_e11_csv(amp, ph, fuse, prop, spec;
                                    bpf_Hz=bpf_Hz, n_harmonics=nH,
                                    anopp_spl_csv=paths.anopp_spl,
                                    broadband_clip_dB=10.0,
                                    grid_fill=grid_fill,
                                    f1a_pattern_amps=f1a_pattern_amps,
                                    f1a_pattern_phases=f1a_pattern_phases)
    elseif src === :aircraft
        aircraft_json === nothing && error("source=:aircraft requires aircraft_json")
        ff = propeller_freefield_grid(aircraft_json, fuse, prop, spec; n_harmonics=n_harmonics)
    else
        ff = synthetic_freefield_grid(fuse, prop, spec; n_harmonics=n_harmonics, bpf_Hz=bpf_Hz)
    end
    bl = apply_blocking(ff, fuse, prop; variant=blocking)

    # CYL2D: aircraft/user c0 and θ0 (no hard-coded path constants beyond the NY default)
    acoustic = cyl2d_modes(theta0_deg; n_modes=20, NY=NY, c0=c0)
    # Default structural path unchanged for :surrogate: Table D-1 when use_table_d1.
    # :parametric / structural_solver=:appd → App. D with aircraft geometry (30c).
    solver = structural_solver
    if solver === :table_d1 && !use_table_d1
        solver = :ritz
    end
    appd_g = (solver === :appd) ? build_appd_geometry(fuse, appd_overrides) : nothing
    structural = build_structural_modes(fuse; structural_solver=solver, n_keep=32,
                                        appd_geometry=appd_g)

    ΔA = (π * a / 18)^2  # User Manual grid spacing scale (from fuse.a)
    trim_used = trim === :auto ? (src === :e11 ? :phase3 : :bare) : trim
    sidewall = end_stack = mech_used = nothing
    m_wall_eff = m_wall
    m_wall_from_phase3 = false
    if sidewall_trim_stack !== nothing || end_trim_stack !== nothing
        sidewall, end_stack, mech_used = sidewall_trim_stack, end_trim_stack, mech
        trim_used = :custom
    elseif trim_used === :phase3
        p3 = phase3_trim(; a=a, L=L, theta0_deg=theta0_deg)
        sidewall, end_stack, mech_used = p3.sidewall, p3.ends, p3.mech
        if isnan(m_wall_eff)
            m_wall_eff = p3.m_wall
            m_wall_from_phase3 = true
        end
    elseif trim_used === :custom
        error("trim=:custom requires sidewall_trim_stack / end_trim_stack")
    end
    m_wall_was_fallback = isnan(m_wall_eff)  # PainInputs will fill from MRP_*
    inp = PainInputs(fuse, prop, structural, acoustic,
                     bl.amplitudes, bl.phases, bl.pts, ΔA;
                     sidewall=sidewall, endplates=end_stack, mech=mech_used, m_wall=m_wall_eff,
                     η_n_bare=η_n_bare, C_struc=C_struc, q_max=q_max,
                     allow_extrapolation=allow_extrapolation,
                     ρ0=ρ0, c0=c0, ρ_ext=ρ_ext, c_ext=c_ext, ρ_int=ρ_int, c_int=c_int,
                     L_c=L_c, d=d, bands=bands, η_r_band=η_r_band, η_n_band=η_n_band,
                     η_r_band_is_prime=η_r_band_is_prime, η_r_trimmed_area=η_r_trimmed_area)
    # Parametric HF path: Eqs. 19–23 (I-21 open readings → X-EXTRAP); η_r_cap=nothing
    spec_out = interior_spl(inp; bpf_Hz=bl.bpf_Hz,
                            n_harmonics=min(n_harmonics, size(bl.amplitudes, 3)),
                            bb_j2_scale=bb_j2_scale, bb_α=bb_α,
                            spbl_anchor_H=spbl_anchor_H, broadband_model=broadband_model,
                            η_r_cap=nothing, tone_model=tone_model)

    provenance = empty_provenance()
    if src === :aircraft
        nasa_defs = collect_nasa_defaults_used(;
            L, a, theta0_deg, r_p, phi_p_deg, z_p, rotation_direction,
            η_n_bare, C_struc, NY, ρ0, c0, L_c=inp.L_c, d,
            m_wall_resolved=inp.m_wall,
            m_wall_was_fallback=(m_wall_was_fallback || m_wall_from_phase3),
            structural_solver=solver, use_table_d1,
            bb_j2_scale, bb_α, broadband_model, spbl_anchor_H,
            trim_used, sidewall_is_phase3=(trim_used === :phase3),
            cabin_blocks=blocks, appd_overrides,
            supplied, input_rows=prov_inputs)
        warn_nasa_defaults!(nasa_defs)
        provenance = (; nasa_defaults=nasa_defs, inputs=prov_inputs, cabin_blocks=blocks)
    end

    return (; fuse, prop, ff=bl, acoustic, structural, spectrum=spec_out, source=src,
              trim=trim_used, inputs=inp, provenance, cabin_blocks=blocks)
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
