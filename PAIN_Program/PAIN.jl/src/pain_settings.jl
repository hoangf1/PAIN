# Phase 127 (2026-11-04): every constant on the run path as a named setting.
#
# Author 2026-11-04: "i dont like there being any constants hidden inside pain ... if there are any constants then make it
# available for change in the gui". Each field below was a literal in the code; its default is that literal, so a run with
# `PainSettings()` is the run before Phase 127, bit for bit. The GUI edits them; `run_pain_pipeline(; settings)` scopes
# them over one run (`with(PAIN_SETTINGS => s)`), and every site reads `pain_settings()`.
#
# Not settings (fixed definitions, changing them relabels the scale rather than the physics): p_ref = 20 µPa, the
# A-weighting curve, the nominal and exact 1/3-octave centres; numerical guards (1e-30 in log10, 1e-12 divisors);
# NASA's printed tables used as data (Table D-1, Table C-1, the PF-105 table).

using Base.ScopedValues: ScopedValue, with

"""
    PainSettings

Constants of the PAIN run path, defaults equal to the values they replaced (Phase 127). Groups: grid (User Manual §3),
propeller source (CCBlade + F1A), blocking (CR-3813 Eq. 43, CR-172428 §5.3.2), CYL2D (App. C), App. D structural solver
(Phase 123 cutoff rule, card 8 series limits), coupling and damping options, tones and broadband. `PAIN_SETTING_SPECS`
gives each field's label, unit and source.
"""
Base.@kwdef struct PainSettings
    # Grid (User Manual §3: 16 × 10 points, propeller plane at k = 8, 10° steps; ΔA = (πa/18)²)
    grid_k_max::Int = 16
    grid_ell_max::Int = 10
    grid_k_p::Int = 8
    grid_step_deg::Float64 = 10.0
    # Propeller source (CCBlade BEMT + AcousticAnalogies F1A)
    num_src_times::Int = 64
    n_rev_src::Int = 2
    static_v_min_mps::Float64 = 1.0
    static_v_sub_mps::Float64 = 20.0
    tip_correction::Bool = true
    polar_cl_slope::Float64 = 2π
    polar_alpha_max_rad::Float64 = 0.35
    polar_cd0::Float64 = 0.01
    polar_cd2::Float64 = 0.15
    # Blocking, Eq. (43): F = 10^(c1 − c2·e^(c3 γ)); R2 multiplies by r2_scale; F not below floor
    block_c1::Float64 = 0.3
    block_c2::Float64 = 0.000224
    block_c3::Float64 = 0.08
    block_r2_scale::Float64 = 0.8
    block_floor::Float64 = 1.0
    # CYL2D (App. C)
    cyl2d_n_modes::Int = 20
    cyl2d_node_tol::Float64 = 0.4
    cyl2d_ny_extra::Int = 10
    c_cyl2d_mps::Float64 = 341.0
    # App. D structural modes (card 8 series limits; Phase 123 cutoff rule)
    n_struct_modes::Int = 32
    appd_cut_factor::Float64 = 2.0
    appd_cut_round_Hz::Float64 = 100.0
    appd_n_axial::Int = 10
    appd_n_circ::Int = 12
    appd_n_floor_max::Int = 5
    appd_conv_frac::Float64 = 0.01
    appd_conv_min::Int = 2
    appd_max_terms::Int = 640
    appd_n_keep_shell::Int = 5
    appd_n_keep_floor::Int = 3
    appd_floor_cross_terms::Bool = false
    # Coupling and damping options (PainInputs)
    q0_coupled::Bool = false
    eta_n_per_mode::Bool = true
    eta_n_band_omega::Bool = true
    eta_n_band_floor_Hz::Float64 = 100.0
    eta_r_trimmed_area::Bool = true
    eta_r_band_is_prime::Bool = false
    floor_sign::Float64 = 1.0
    trim_band_centre::Bool = false
    crossover_band_Hz::Float64 = 0.0     # 0 = Eq. (24) crossover
    eta_r_cap::Float64 = 0.0             # 0 = no cap
    c_omega::Float64 = 0.232
    # Tones and broadband
    tone_model::Symbol = :eq8
    broadband::Bool = true
    bb_start_Hz::Float64 = 1000.0
    bb_tone_skip::Float64 = 1.15
    j2_fallback::Float64 = 2.5e-4
    j2_min::Float64 = 1e-6
    surr_bw_rel::Float64 = 0.2316
    surr_n_coef::Float64 = 0.015
    surr_n_fref_Hz::Float64 = 500.0
    surr_df_min_Hz::Float64 = 1.0
    surr_nref_modes::Float64 = 3.0
    surr_nref_fc_Hz::Float64 = 1500.0
    surr_chi_min::Float64 = 0.25
    surr_chi_max::Float64 = 4.0
end

"""Settings of the current run (`PainSettings()` outside a scoped run)."""
const PAIN_SETTINGS = ScopedValue(PainSettings())

pain_settings() = PAIN_SETTINGS[]

"""c_ω of the current run (CR-3813 p. 10; 0.232 by default)."""
c_omega() = PAIN_SETTINGS[].c_omega

"""
    with_pain_settings(f, s::PainSettings)

Run `f()` with `s` as the settings of every site on the run path.
"""
with_pain_settings(f, s::PainSettings) = with(f, PAIN_SETTINGS => s)

"""
    pain_settings_from_dict(d) -> PainSettings

Fields from a Dict (string or symbol keys; a JSON object); missing keys keep the default. Unknown keys error, so a
mistyped name in a project file is not silently dropped.
"""
function pain_settings_from_dict(d)
    base = PainSettings()
    kw = Dict{Symbol,Any}()
    names = fieldnames(PainSettings)
    for (k, v) in pairs(d)
        s = Symbol(k)
        s in names || error("unknown PAIN setting \"$k\" (known: $(join(names, ", ")))")
        T = fieldtype(PainSettings, s)
        kw[s] = T === Symbol ? Symbol(String(v)) :
                T === Bool ? (v isa Bool ? v : v in ("true", "1", 1)) :
                T === Int ? Int(v isa AbstractString ? parse(Float64, v) : v) :
                Float64(v isa AbstractString ? parse(Float64, v) : v)
    end
    return PainSettings(; (f => get(kw, f, getfield(base, f)) for f in names)...)
end

"""Fields of `s` that differ from the defaults, as a Dict (for a project file)."""
function pain_settings_diff(s::PainSettings)
    base = PainSettings()
    return Dict{String,Any}(String(f) => (getfield(s, f) isa Symbol ? String(getfield(s, f)) : getfield(s, f))
                            for f in fieldnames(PainSettings) if getfield(s, f) != getfield(base, f))
end

"""
GUI metadata of every `PainSettings` field: (key, group, label, unit, kind, choices, tip). `kind` is :float, :int,
:bool or :choice. Defaults come from `PainSettings()`; `test_pain_settings` checks that every field is listed.
"""
const PAIN_SETTING_SPECS = [
    # Grid
    (key=:grid_k_max, group="Grid", label="Axial stations k_max", unit="", kind=:int, choices=String[],
     tip="Number of axial grid stations (User Manual §3: 16)."),
    (key=:grid_ell_max, group="Grid", label="Circumferential lines ℓ_max", unit="", kind=:int, choices=String[],
     tip="Number of circumferential lines on the quarter nearest the propeller (User Manual §3: 10)."),
    (key=:grid_k_p, group="Grid", label="Propeller-plane station k_p", unit="", kind=:int, choices=String[],
     tip="Axial station in the propeller plane (User Manual §3: 8)."),
    (key=:grid_step_deg, group="Grid", label="Grid step", unit="deg", kind=:float, choices=String[],
     tip="Angular step between lines; the axial step is a × the same angle, so ΔA = (a·step)² (User Manual: 10°, πa/18)."),
    # Source
    (key=:num_src_times, group="Source", label="Source times per blade passage", unit="", kind=:int, choices=String[],
     tip="F1A source time samples per blade-passage period (64)."),
    (key=:n_rev_src, group="Source", label="Source span", unit="rev", kind=:int, choices=String[],
     tip="Revolutions of source time history; the reception window is one blade passage (plan I-01: 2)."),
    (key=:static_v_min_mps, group="Source", label="Static guard: V below", unit="m/s", kind=:float, choices=String[],
     tip="Flight speeds below this are replaced (BEMT has no static solution here; plan 25a: 1 m/s)."),
    (key=:static_v_sub_mps, group="Source", label="Static guard: V used", unit="m/s", kind=:float, choices=String[],
     tip="Speed used in place of a speed below the guard (20 m/s)."),
    (key=:tip_correction, group="Source", label="Prandtl tip/hub loss", unit="", kind=:bool, choices=String[],
     tip="CCBlade Prandtl tip and hub loss factor (on)."),
    (key=:polar_cl_slope, group="Source", label="Default polar: lift slope", unit="1/rad", kind=:float, choices=String[],
     tip="Lift slope of the default linear polar, used where no polar file is given (2π)."),
    (key=:polar_alpha_max_rad, group="Source", label="Default polar: α clamp", unit="rad", kind=:float, choices=String[],
     tip="Angle of attack clamp of the default polar (±0.35 rad)."),
    (key=:polar_cd0, group="Source", label="Default polar: c_d0", unit="", kind=:float, choices=String[],
     tip="Zero-lift drag of the default polar (0.01)."),
    (key=:polar_cd2, group="Source", label="Default polar: c_d2", unit="1/rad²", kind=:float, choices=String[],
     tip="Drag rise of the default polar, c_d = c_d0 + c_d2 α² (0.15)."),
    # Blocking
    (key=:block_c1, group="Blocking", label="Eq. 43 constant c1", unit="", kind=:float, choices=String[],
     tip="F(γ) = 10^(c1 − c2·e^(c3·γ)) (CR-3813 Eq. 43: 0.3)."),
    (key=:block_c2, group="Blocking", label="Eq. 43 constant c2", unit="", kind=:float, choices=String[],
     tip="CR-3813 Eq. 43: 0.000224."),
    (key=:block_c3, group="Blocking", label="Eq. 43 constant c3", unit="1/deg", kind=:float, choices=String[],
     tip="CR-3813 Eq. 43: 0.08."),
    (key=:block_r2_scale, group="Blocking", label="R2 amplitude factor", unit="", kind=:float, choices=String[],
     tip="R2 multiplies the Eq. 43 amplitude ratio by this (CR-172428 §5.3.2: 0.8)."),
    (key=:block_floor, group="Blocking", label="Minimum F", unit="", kind=:float, choices=String[],
     tip="F is not taken below this (1: no attenuation, Q95)."),
    # CYL2D
    (key=:cyl2d_n_modes, group="Cabin modes", label="CYL2D modes per parity", unit="", kind=:int, choices=String[],
     tip="2-D cabin modes solved per symmetry class (20)."),
    (key=:cyl2d_node_tol, group="Cabin modes", label="CYL2D node tolerance", unit="cell", kind=:float, choices=String[],
     tip="Fraction of a cell within which a node counts as on the boundary (App. C grid: 0.4)."),
    (key=:cyl2d_ny_extra, group="Cabin modes", label="CYL2D: extra NY tried", unit="", kind=:int, choices=String[],
     tip="When NY has no App. C solution for θ0, grids up to NY + this are tried (Q60: 10)."),
    (key=:c_cyl2d_mps, group="Cabin modes", label="Speed of 2-D mode part", unit="m/s", kind=:float, choices=String[],
     tip="Sound speed of the 2-D part of every cabin-mode frequency (CYL2D's 341 m/s, Phase 106)."),
    # App. D
    (key=:n_struct_modes, group="Structural modes", label="Structural modes kept (min)", unit="", kind=:int, choices=String[],
     tip="Lowest structural modes always kept (32)."),
    (key=:appd_cut_factor, group="Structural modes", label="App. D cutoff / highest tone", unit="", kind=:float, choices=String[],
     tip="App. D modes are kept up to this × the highest tone (Phase 123: 2)."),
    (key=:appd_cut_round_Hz, group="Structural modes", label="App. D cutoff rounding", unit="Hz", kind=:float, choices=String[],
     tip="The cutoff is rounded up to a multiple of this (100 Hz)."),
    (key=:appd_n_axial, group="Structural modes", label="App. D axial terms M", unit="", kind=:int, choices=String[],
     tip="Starting axial series limit (User Manual card 8: 10)."),
    (key=:appd_n_circ, group="Structural modes", label="App. D shell terms n", unit="", kind=:int, choices=String[],
     tip="Starting circumferential series limit (card 8: 12)."),
    (key=:appd_n_floor_max, group="Structural modes", label="App. D floor terms", unit="", kind=:int, choices=String[],
     tip="Floor series limit (card 8: 5)."),
    (key=:appd_conv_frac, group="Structural modes", label="App. D convergence fraction", unit="", kind=:float, choices=String[],
     tip="Series limits double until doubling adds at most this fraction of the modes below the cutoff (0.01)."),
    (key=:appd_conv_min, group="Structural modes", label="App. D convergence minimum", unit="modes", kind=:int, choices=String[],
     tip="…or at most this many modes (2)."),
    (key=:appd_max_terms, group="Structural modes", label="App. D series limit cap", unit="", kind=:int, choices=String[],
     tip="Stop with an error past this many series terms (640)."),
    (key=:appd_n_keep_shell, group="Structural modes", label="Shell terms kept per mode", unit="", kind=:int, choices=String[],
     tip="MRPMOD's term budget for a mode's shell shape (Phase 107: 5)."),
    (key=:appd_n_keep_floor, group="Structural modes", label="Floor terms kept per mode", unit="", kind=:int, choices=String[],
     tip="MRPMOD's term budget for a mode's floor shape (Phase 107: 3)."),
    (key=:appd_floor_cross_terms, group="Structural modes", label="Floor cross terms", unit="", kind=:bool, choices=String[],
     tip="Keep the floor cross terms between parities (off: NASA's program, reproduces Table D-1)."),
    # Coupling and damping
    (key=:q0_coupled, group="Coupling", label="Couple q = 0 cabin modes", unit="", kind=:bool, choices=String[],
     tip="Include the axially uniform cabin modes in the tone sum (CR-3813's printed form; off: NASA's CR-172428 output)."),
    (key=:eta_n_per_mode, group="Coupling", label="η_n per cabin mode", unit="", kind=:bool, choices=String[],
     tip="Cabin loss factor as a property of the mode (Phase 93 default: on)."),
    (key=:eta_n_band_omega, group="Coupling", label="η_n at the band centre", unit="", kind=:bool, choices=String[],
     tip="Evaluate Eq. 77 at the nominal 1/3-octave centre holding the mode (Phase 96 default: on)."),
    (key=:eta_n_band_floor_Hz, group="Coupling", label="Lowest η_n band", unit="Hz", kind=:float, choices=String[],
     tip="Modes below this band use its trim conductance (100 Hz)."),
    (key=:eta_r_trimmed_area, group="Coupling", label="η_r over the trimmed area", unit="", kind=:bool, choices=String[],
     tip="Eq. 82's C_w over the trimmed sidewall area (on)."),
    (key=:eta_r_band_is_prime, group="Coupling", label="Per-band η_r is η_r′", unit="", kind=:bool, choices=String[],
     tip="Read per-band η_r overrides as η_r′ rather than the total (off)."),
    (key=:floor_sign, group="Coupling", label="Floor term sign", unit="±1", kind=:float, choices=String[],
     tip="Sign of the floor term in the structural mode shape (+1)."),
    (key=:trim_band_centre, group="Coupling", label="Trim at the band centre", unit="", kind=:bool, choices=String[],
     tip="Evaluate the trim of a tone or mode at its nominal 1/3-octave centre (Phase 102 option: off)."),
    (key=:crossover_band_Hz, group="Coupling", label="Crossover band (0 = Eq. 24)", unit="Hz", kind=:float, choices=String[],
     tip="Band from which the high-frequency forms apply; 0 uses the Eq. 24 crossover."),
    (key=:eta_r_cap, group="Coupling", label="η_r cap (0 = none)", unit="", kind=:float, choices=String[],
     tip="Upper limit on the structural loss factor; 0 = no cap."),
    (key=:c_omega, group="Coupling", label="Band width c_ω", unit="Δω/ω", kind=:float, choices=String[],
     tip="Relative bandwidth of a 1/3-octave band (CR-3813 p. 10: 0.232)."),
    # Tones and broadband
    (key=:tone_model, group="Tones and broadband", label="Tone model", unit="", kind=:choice, choices=["eq8", "eq15_16", "auto"],
     tip="Eq. 8 (default), Eqs. 15–16 (high-frequency expected value), or auto (Eq. 8 below the crossover)."),
    (key=:broadband, group="Tones and broadband", label="High-frequency broadband", unit="", kind=:bool, choices=String[],
     tip="Add the high-frequency broadband bands (on)."),
    (key=:bb_start_Hz, group="Tones and broadband", label="Broadband from", unit="Hz", kind=:float, choices=String[],
     tip="Lowest band given broadband (1000 Hz)."),
    (key=:bb_tone_skip, group="Tones and broadband", label="Broadband above last tone ×", unit="", kind=:float, choices=String[],
     tip="Bands at or below this × the highest tone get no broadband (1.15)."),
    (key=:j2_fallback, group="Tones and broadband", label="⟨j²⟩ with no mode", unit="", kind=:float, choices=String[],
     tip="Joint acceptance used when a band has no structural mode (2.5e-4)."),
    (key=:j2_min, group="Tones and broadband", label="⟨j²⟩ lower limit", unit="", kind=:float, choices=String[],
     tip="Surrogate broadband: lower clamp of the band joint acceptance (1e-6)."),
    (key=:surr_bw_rel, group="Tones and broadband", label="Surrogate band width", unit="Δf/f", kind=:float, choices=String[],
     tip="Surrogate broadband: band width for modal counts (0.2316)."),
    (key=:surr_n_coef, group="Tones and broadband", label="Surrogate density coefficient", unit="modes/(Hz m²)", kind=:float, choices=String[],
     tip="Asymptotic modal density n = coef·aL·(f/f_ref) in bands with no mode (0.015)."),
    (key=:surr_n_fref_Hz, group="Tones and broadband", label="Surrogate density f_ref", unit="Hz", kind=:float, choices=String[],
     tip="Reference frequency of the asymptotic density (500 Hz)."),
    (key=:surr_df_min_Hz, group="Tones and broadband", label="Surrogate minimum Δf", unit="Hz", kind=:float, choices=String[],
     tip="Smallest band width in the modal density (1 Hz)."),
    (key=:surr_nref_modes, group="Tones and broadband", label="Surrogate n_ref modes", unit="", kind=:float, choices=String[],
     tip="Reference modal density: this many modes per band… (3)."),
    (key=:surr_nref_fc_Hz, group="Tones and broadband", label="Surrogate n_ref band", unit="Hz", kind=:float, choices=String[],
     tip="…in the band at this centre (1500 Hz)."),
    (key=:surr_chi_min, group="Tones and broadband", label="Surrogate χ minimum", unit="", kind=:float, choices=String[],
     tip="Lower clamp of the density ratio χ (0.25)."),
    (key=:surr_chi_max, group="Tones and broadband", label="Surrogate χ maximum", unit="", kind=:float, choices=String[],
     tip="Upper clamp of the density ratio χ (4)."),
]
