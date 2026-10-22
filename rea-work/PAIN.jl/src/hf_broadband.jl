# CR-3813 §3.3 high-frequency broadband model, Eqs. (19)–(23) as printed
# (pp. 23–25; PDF pages `cr3813_pdf033.png`–`pdf035.png`). No parameter is chosen
# from Fig. E-9, E-21 or E-22.
#
# Open readings (I-21, 2026-10-22): sparse-mode / "resonant below the band" wording,
# and the printed τ_R form, leave the aircraft `:parametric` / `:eq19` result as
# X-EXTRAP with the epistemic band of phase 31 — not a prediction of accuracy.
# See IMPLEMENTATION_PLAN.md I-21 review.

# =============================================================================
# Readings decided (every ambiguity stated; none fitted to comparison data)
# =============================================================================
# 1. Band width: Δω = c_ω ω with c_ω = 0.232 (CR-3813 p. 10; same as 38a/38b).
#    Notation "r < Δω" / text "resonant below the frequency band" read as modes
#    whose resonance lies in the band [ω(1−c_ω/2), ω(1+c_ω/2)] — parallel to
#    "n ∈ Δω" on p. 25 and to `modes_in_tone_band` / 38a. Averaged radiation
#    joint acceptance is defined on the same set ("modes resonant in the band").
# 2. Sparse Table D-1 above ~811 Hz: when no structural mode is resonant in the
#    band, n_r uses the asymptotic branch of `structural_modal_density`; ⟨j²⟩^rev
#    is the mean of `structural_joint_acceptance(st, ω)` over all retained modes
#    at the band-centre ω (k = ω/c0); Σ[j_r²]² = N_eff · ⟨(j²)²⟩ with
#    N_eff = n_r·Δω. Not fitted to E-9.
# 3. Areas (Phase III / App. E): A_t = `coupling_area` (transmitting area with
#    trim; text "only the sidewall contributes" uses the same A as Eqs. 8/17/52);
#    A' = 0 when trim is present (all transmitting surface trimmed). Bare cabin:
#    A_t = 0, A' = coupling_area, τ_t = 1. S (absorbing) = S_sidewall + 2 S_e with
#    S_sidewall = 2a(π−θ0)L and S_e = V/L — same as the E-13/Eq.(24) script
#    (`run_trim_loss_check.jl`); Ā = `cylinder_surface_area` = 2π a L (Eq. 81).
# 4. ᾱ from Eq. (24): ᾱ = 4ωV η̄_n/(c0 S) via `absorption_from_loss_factor`. With
#    trim, η̄_n = Eq. (78) `acoustic_loss_average` (ξ, ξ_e from the Phase III
#    stacks). Bare: η̄_n = η_n_bare. The surrogate `absorption_coefficient` is
#    not used on the `:eq19` path.
# 5. τ_t = Eq. (A.22) `sidewall_tau` (CR-3813: applies to Eqs. 16, 18, 23).
# 6. j_r²(ω)^rev = `structural_joint_acceptance` (§3.6; 16b). Radiation loss
#    factors: Eq. (81) form as printed after Eq. (19),
#    η_rad^ext = 2 ρ0 ω Ā ⟨j²⟩/(π m c0), η_rad^int = 2 ρ ω Ā ⟨j²⟩/(π m c0).
# 7. η̄_r = ⟨η_rad^ext⟩ + ⟨η_r'⟩. η_r' from Eqs. 79–82 (trim when present);
#    η_r'' of Eq. (83) is pair-dependent and is omitted from the band average
#    (same reading as 38b §3). Optional `η_r_cap` as in 38a (default nothing).
# 8. τ_R (p. 24): (2 n_r π² c0 η_rad^ext η_rad^int)/(ρ0 ω η̄_r) · (4 ρ c0 / Ā).
#    τ_f Eq. (20): (32/π) ρ² (Ā/m²) Σ_{r∈Δω} [j_r²(ω)^rev]². τ = τ_f + τ_R.
# 9. Densities (38f-1 card 2): ρ0 → ρ_ext, ρ → ρ_int; c0 exterior in η_rad^ext /
#    τ_R ρ0-denominator / joint-acceptance k; c_int in η_n, ᾱ, η_rad^int, τ_R (4ρc/Ā).
# 10. ⟨p_e²⟩_s,t = ⟨p_bl²⟩/2 (p. 23). Eq. (23) → ⟨p_i²⟩ = ⟨p_e²⟩ / ratio.
# 11. Exterior blocked continuum `blocked_broadband_band_p2` (Spbl ∝ f^{−α}, H=3
#     anchor) is unchanged V-ASSUMED input; only the cabin transmission uses the
#     printed Eqs. (19)–(23). No scale on j², τ, A_t, S or A′.
# =============================================================================

"""Sidewall curved area and one end-plate area (E-14 / Eq. 78 usage).

Cavity length `L_c` (card 9) sets V and the absorbing sidewall/end areas; structure
length `fuse.L` is unchanged for transmitting/`Ā` elsewhere.
"""
function hf_absorbing_areas(fuse::FuselageGeometry; L_c::Real=fuse.L)
    a = fuse.a
    θ0 = deg2rad(fuse.theta0_deg)
    Lc = float(L_c)
    V = cabin_volume(fuse; L_c=Lc)
    S_side = 2a * (π - θ0) * Lc
    S_e = V / Lc
    S = S_side + 2 * S_e
    return (; S, S_side, S_e, V)
end

hf_absorbing_areas(inp::PainInputs) = hf_absorbing_areas(inp.fuse; L_c=inp.L_c)

"""
Trim / bare transmitting areas for Eqs. (19)–(23).

With trim: A_t = coupling area, A′ = 0. Bare: A_t = 0, A′ = coupling area.
"""
function hf_trim_areas(inp::PainInputs)
    A = coupling_area(inp.fuse)
    if has_trim(inp)
        return (; A_t=A, A′=0.0, A)
    else
        return (; A_t=0.0, A′=A, A)
    end
end

"""
Structural modes resonant in the 1/3-octave about `fc`, plus band averages for
Eqs. (19)–(20) (readings §1–§2).
"""
function hf_structural_band(inp::PainInputs, fc::Real; c_ω::Real=C_OMEGA_THIRD_OCTAVE)
    ω = 2π * fc
    Δω = c_ω * ω
    lo = ω * (1 - c_ω / 2)
    hi = ω * (1 + c_ω / 2)
    a, L, c_ext = inp.fuse.a, inp.fuse.L, inp.c_ext
    in_band = NamedTuple[]
    j2s = Float64[]
    for st in inp.structural.modes
        ωr = 2π * st.f_Hz
        j2 = structural_joint_acceptance(st, ω; a, L, c0=c_ext)
        if lo ≤ ωr ≤ hi
            push!(in_band, (; st, ωr, j2))
            push!(j2s, j2)
        end
    end
    if !isempty(j2s)
        n_r = length(j2s) / Δω
        j2_mean = sum(j2s) / length(j2s)
        sum_j2sq = sum(x -> x^2, j2s)
        j2sq_mean = sum_j2sq / length(j2s)
        return (; ω, Δω, lo, hi, n_r, j2_mean, sum_j2sq, j2sq_mean, in_band, asymptotic=false)
    end
    # Sparse / above Table D-1: asymptotic density + all-mode ⟨j²⟩ at band ω
    n_r = structural_modal_density(inp.structural, float(fc))
    all_j2 = Float64[structural_joint_acceptance(st, ω; a, L, c0=c_ext) for st in inp.structural.modes]
    if isempty(all_j2)
        j2_mean = 2.5e-4
        j2sq_mean = j2_mean^2
    else
        j2_mean = sum(all_j2) / length(all_j2)
        j2sq_mean = sum(x -> x^2, all_j2) / length(all_j2)
    end
    N_eff = max(n_r * Δω, 0.0)
    sum_j2sq = N_eff * j2sq_mean
    return (; ω, Δω, lo, hi, n_r, j2_mean, sum_j2sq, j2sq_mean, in_band, asymptotic=true)
end

"""
Band-average η̄_n (Eq. 78 or η_n_bare), η̄_r′ (Eqs. 79–82), and η_rad from ⟨j²⟩.
"""
function hf_band_loss_factors(inp::PainInputs, fc::Real, band;
                              η_r_cap::Union{Nothing,Float64}=nothing)
    fuse = inp.fuse
    a, L = fuse.a, fuse.L
    ρ_ext, c_ext = inp.ρ_ext, inp.c_ext
    ρ_int, c_int = inp.ρ_int, inp.c_int
    ω = band.ω
    Abar = cylinder_surface_area(a, L)
    areas = hf_absorbing_areas(inp)
    ext = inp.allow_extrapolation
    trimmed = has_trim(inp)
    m = inp.m_wall

    ξ = trimmed ? trim_conductance(inp.sidewall, ω, m; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0
    ξe = trimmed ? trim_conductance(inp.endplates, ω, Inf; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0
    η̄_n = resolve_η_n_band(inp, fc; ξ, ξ_e=ξe, V=areas.V, S=areas.S_side, S_e=areas.S_e)
    ᾱ = absorption_from_loss_factor(η̄_n, ω; V=areas.V, S=areas.S, c0=c_int)

    # η_rad from band-average joint acceptance (printed after Eq. 19): ρ0 exterior, ρ interior
    η_rad_ext = radiation_loss_factor(band.j2_mean, ω; Abar, m, ρ0=ρ_ext, c0=c_ext)
    η_rad_int = radiation_loss_factor(band.j2_mean, ω; Abar, m, ρ0=ρ_int, c0=c_int)

    # ⟨η_r'⟩ over modes used for the j² average
    st_list = if !isempty(band.in_band)
        [m.st for m in band.in_band]
    else
        collect(inp.structural.modes)
    end
    ηrp_vals = Float64[]
    for st in st_list
        ωr = 2π * st.f_Hz
        push!(ηrp_vals, structural_η_r_prime(inp, st, ωr; η_r_cap, Abar))
    end
    η̄_r′ = isempty(ηrp_vals) ? 0.0 : sum(ηrp_vals) / length(ηrp_vals)
    # η̄_r = η_rad^ext + η_r' (+ η_r'' omitted — reading §7)
    η̄_r = η_rad_ext + η̄_r′
    return (; η̄_n, ᾱ, η_rad_ext, η_rad_int, η̄_r′, η̄_r, areas)
end

"""
    hf_transmission_coeffs(inp, fc; …) -> NamedTuple

τ_f (Eq. 20), τ_R (p. 24), τ = τ_f + τ_R, plus the band averages used.
"""
function hf_transmission_coeffs(inp::PainInputs, fc::Real;
                                c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                                η_r_cap::Union{Nothing,Float64}=nothing)
    band = hf_structural_band(inp, fc; c_ω)
    losses = hf_band_loss_factors(inp, fc, band; η_r_cap)
    ρ_ext, c_ext = inp.ρ_ext, inp.c_ext
    ρ_int, c_int = inp.ρ_int, inp.c_int
    m = inp.m_wall
    Abar = cylinder_surface_area(inp.fuse.a, inp.fuse.L)
    ω = band.ω
    # Eq. (20): τ_f = (32/π) ρ² (Ā/m²) Σ [j_r²]^2  — ρ = interior
    τ_f = (32 / π) * ρ_int^2 * (Abar / m^2) * band.sum_j2sq
    # τ_R = (2 n_r π² c0 η_rad^ext η_rad^int)/(ρ0 ω η̄_r) · (4 ρ c0 / Ā)
    # printed: ρ0,c0 in the first factor exterior; ρ,c0 in (4ρc/Ā) interior (c_int)
    η̄_r = max(losses.η̄_r, floatmin(Float64))
    τ_R = (2 * band.n_r * π^2 * c_ext * losses.η_rad_ext * losses.η_rad_int) /
          (ρ_ext * ω * η̄_r) * (4 * ρ_int * c_int / Abar)
    τ = τ_f + τ_R
    return (; τ_f, τ_R, τ, band, losses, Abar, ω, ρ0=ρ_ext, c0=c_ext, ρ=ρ_int, m)
end

"""
    hf_pressure_ratio(inp, fc; …) -> NamedTuple

Eq. (23): ⟨p_e²⟩/⟨p_i²⟩ = (ᾱ S + [τ_f + τ_R (η̄_r/η_rad^ext)] A′) / (τ_t τ A_t + τ A′),
with τ = τ_f + τ_R. NR_dB = 10 log10(ratio).
"""
function hf_pressure_ratio(inp::PainInputs, fc::Real;
                           c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                           η_r_cap::Union{Nothing,Float64}=nothing)
    tc = hf_transmission_coeffs(inp, fc; c_ω, η_r_cap)
    areas_t = hf_trim_areas(inp)
    A_t, A′ = areas_t.A_t, areas_t.A′
    S = tc.losses.areas.S
    ᾱ = tc.losses.ᾱ
    τ_t = sidewall_tau(inp, tc.ω)
    τ_f, τ_R, τ = tc.τ_f, tc.τ_R, tc.τ
    η_rad = max(tc.losses.η_rad_ext, floatmin(Float64))
    num = ᾱ * S + (τ_f + τ_R * (tc.losses.η̄_r / η_rad)) * A′
    den = τ_t * τ * A_t + τ * A′
    ratio = den > 0 ? num / den : Inf
    NR = ratio > 0 && isfinite(ratio) ? 10 * log10(ratio) : Inf
    return (; ratio, NR_dB=NR, τ_t, τ_f, τ_R, τ, A_t, A′, S, ᾱ, num, den, tc...)
end

"""
    hf_broadband_band_p2(inp, fc, p2_bl; …) -> Float64

Interior band ⟨p_i²⟩ from blocked ⟨p_bl²⟩ via Eqs. (19)–(23):
⟨p_e²⟩ = ⟨p_bl²⟩/2, ⟨p_i²⟩ = ⟨p_e²⟩ / (Eq. 23 ratio).
"""
function hf_broadband_band_p2(inp::PainInputs, fc::Real, p2_bl::Real;
                              c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                              η_r_cap::Union{Nothing,Float64}=nothing)
    p2_bl ≤ 0 && return 0.0
    pr = hf_pressure_ratio(inp, fc; c_ω, η_r_cap)
    p_e2 = p2_bl / 2
    pr.ratio > 0 && isfinite(pr.ratio) || return 0.0
    return p_e2 / pr.ratio
end

"""
    hf_broadband_spectrum(inp; bpf_Hz, n_harmonics, …) -> InteriorSpectrum

Same 1/3-octave layout as `interior_spl`'s broadband path, but cabin transmission
is printed Eq. (19)–(23). Tones still use the default Eq. (8) path.
"""
function hf_broadband_spectrum(inp::PainInputs; bpf_Hz::Float64, n_harmonics::Int=10,
                               bb_α::Float64=2.0,
                               tone_model::Symbol=:eq8,
                               η_r_cap::Union{Nothing,Float64}=nothing)
    return interior_spl(inp; bpf_Hz, n_harmonics, broadband=true, bb_α,
                        bb_j2_scale=0.5, tone_model, broadband_model=:eq19,
                        η_r_cap)
end
