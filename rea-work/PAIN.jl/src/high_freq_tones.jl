# CR-3813 §3.2 high-frequency tone formulation, Eqs. (11)–(16), pages 17–21
# (PDF pages 27–31). Transcribed from `docs/specs/cr3813_pages/cr3813_pdf027.png` …
# `pdf031.png`. No parameter is chosen from REPRO_18b / T1 / E-16.

# =============================================================================
# Readings decided (every ambiguity stated; none fitted to comparison data)
# =============================================================================
# 1. Δω and c_ω: band width Δω = c_ω ω_H with c_ω = 0.232 for 1/3-octaves
#    (CR-3813 p. 10; same constant as `C_OMEGA_THIRD_OCTAVE` / 38a). The integrals
#    on p. 19 are over [ω_H − Δω/2, ω_H + Δω/2], i.e. a band centred on the
#    harmonic — not the ISO preferred centre that happens to contain H·BPF.
# 2. Modes "in Δω": resonance ω_n or ω_r inside [ω_H(1 − c_ω/2), ω_H(1 + c_ω/2)].
# 3. η̄_n: arithmetic mean of η_n (Eq. 77, or η_n_bare) over acoustic modes in the
#    band. η̄_r: arithmetic mean of η_r' (Eqs. 79–82, trim when present) over
#    structural modes in the band. Page 17 sets η_r^i + η_r^{i'} ≈ η̄_r; η_r'' of
#    Eq. (83) is pair-dependent and is not folded into η̄_r here (same treatment
#    as the high-frequency average on p. 20, which carries only η̄_n, η̄_r).
# 4. f′: barred f̄' of Eq. (52) with √τ_t on the shell term — the same choice as
#    Eq. (8) / 38a (`coupling_factor`). Printed Eqs. (11)–(15) also show a separate
#    τ_t^H in Q_H; that would double-count with barred f̄'. For the Eq. (15) sum
#    that still has ⟨ε_n f′²⟩ we therefore omit the extra τ_t factor. Printed
#    Eq. (16) has already replaced ⟨ε_n f′²⟩ by j_r^rev and keeps τ_t^H in the
#    prefactor (CR-3813 note that τ_t applies to Eqs. 16, 18, 23) — implemented as
#    printed. Production expected value = Eq. (16).
# 5. E[g] closed form: the arctan expression of p. 19 (before the π limit). The
#    π form E[g] = π ω_H/(2 η̄ Δω) is used when η̄ ω_H ≪ Δω (as the text does for
#    Eqs. 15–16). Numerical check integrates the resonance-local integrand that
#    yields the arctan (see `expected_g_quad`), not the exact g(ω_H/ω) of the
#    definition — that exact integral is not the printed arctan (reading).
# 6. Crossover (Manual card 10): reuse `acoustic_crossover_band` from 38a; override
#    via `PainInputs.crossover_band_Hz` when set.
# =============================================================================

"""g_n(ω_H/ω_n) = [(1 − ω_H²/ω_n²)² + η̄_n²]⁻¹ (p. 17)."""
g_resonance(ωH::Real, ωj::Real, η̄::Real) = 1 / ((1 - (ωH / ωj)^2)^2 + η̄^2)

"""
    expected_g_closed(ωH, η̄, Δω) -> E[g]

Printed closed form (p. 19), before the π approximation:
E[g] = (ω_H / (2 η̄ Δω)) [atan(Δω/(η̄ ω_H)) − atan(−Δω/(η̄ ω_H))].
"""
function expected_g_closed(ωH::Real, η̄::Real, Δω::Real)
    η̄ > 0 && Δω > 0 || return Inf
    a = Δω / (η̄ * ωH)
    return (ωH / (2 * η̄ * Δω)) * (atan(a) - atan(-a))
end

"""π-limit of E[g] when η̄ ω_H ≪ Δω: π ω_H / (2 η̄ Δω) (pp. 19–20)."""
expected_g_pi(ωH::Real, η̄::Real, Δω::Real) = (π * ωH) / (2 * η̄ * Δω)

"""
Numerical integral of the resonance-local integrand that produces the arctan
closed form: with δ = ω − ω_H and (1 − ω_H²/ω²) ≈ 2δ/ω_H,
∫ 1/[(2δ/ω_H)² + η̄²] dω / Δω over [−Δω/2, Δω/2].
"""
function expected_g_quad(ωH::Real, η̄::Real, Δω::Real; N::Int=100_000)
    η̄ > 0 && Δω > 0 || return Inf
    h = Δω / N
    s = 0.0
    for i in 1:N
        δ = -Δω / 2 + (i - 0.5) * h
        s += h / ((2δ / ωH)^2 + η̄^2)
    end
    return s / Δω
end

"""Q_H of p. 17: (4 c0²/V²)(mA/4)² τ_ML τ_t ω_H⁶, with (mA/4)²τ_ML = (ρ0 c0 A/(2ω_H))²."""
function tone_Q_H(ρ0::Real, c0::Real, A::Real, V::Real, ωH::Real, τ_t::Real)
    mA4_τ = mass_law_factor(ρ0, c0, A, ωH)   # (mA/4)² τ_ML
    return 4 * (c0 / V)^2 * mA4_τ * τ_t * ωH^6
end

"""Collect acoustic / structural modes whose resonance lies in the Δω band about ω_H."""
function modes_in_tone_band(inp::PainInputs, ωH::Real; c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                            q_max::Union{Nothing,Int}=nothing)
    lo = ωH * (1 - c_ω / 2)
    hi = ωH * (1 + c_ω / 2)
    a, L_c, c_int = inp.fuse.a, inp.L_c, inp.c_int
    qtop = something(q_max, inp.q_max, axial_truncation(hi, L_c, c_int))
    ac_list = NamedTuple[]
    for q in 0:qtop, ac in inp.acoustic.modes
        ωn = 2π * cabin_frequency_3d(ac, a, L_c, q; c0=c_int)
        (lo ≤ ωn ≤ hi) && push!(ac_list, (; ac, q, ωn, εn=cabin_eps_3d(ac, q)))
    end
    st_list = NamedTuple[]
    for st in inp.structural.modes
        ωr = 2π * st.f_Hz
        (lo ≤ ωr ≤ hi) && push!(st_list, (; st, ωr))
    end
    return (; ac_list, st_list, lo, hi, Δω=c_ω * ωH, qtop)
end

"""Average η_n / η_r' over modes in the harmonic's Δω band (readings §3)."""
function band_average_loss_factors(inp::PainInputs, ωH::Real, band;
                                   η_r_cap::Union{Nothing,Float64}=nothing)
    fuse = inp.fuse
    a, L = fuse.a, fuse.L
    L_c = inp.L_c
    ρ_ext, c_ext = inp.ρ_ext, inp.c_ext
    ρ_int, c_int = inp.ρ_int, inp.c_int
    V = cabin_volume(inp)
    A = coupling_area(fuse)
    ext = inp.allow_extrapolation
    trimmed = has_trim(inp)
    ξ = trimmed ? trim_conductance(inp.sidewall, ωH, inp.m_wall; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0
    ξe = trimmed ? trim_conductance(inp.endplates, ωH, Inf; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0

    ηn_vals = Float64[]
    for m in band.ac_list
        if trimmed
            N = acoustic_loss_modal(m.ac, m.q, ωH, m.ωn; a, L=L_c, V, c0=c_int, ξ, ξ_e=ξe).N
            η = m.ωn == 0 ? NaN : N / m.ωn^2
        else
            η = inp.η_n_bare
        end
        isfinite(η) && η > 0 && push!(ηn_vals, η)
    end
    ηr_vals = Float64[]
    for m in band.st_list
        ηr = structural_loss_total(m.st, m.ωr; a, L, m=inp.m_wall, C=inp.C_struc, ρ0=ρ_ext, c0=c_ext)
        ηrp = trimmed ?
            structural_loss_with_trim(ηr, m.ωr, inp.m_wall,
                                      trim_Cw(inp.sidewall, m.ωr; allow_extrapolation=ext);
                                      η_r_cap) :
            apply_η_r_cap(ηr, η_r_cap)
        push!(ηr_vals, ηrp)
    end
    η̄_n = isempty(ηn_vals) ? NaN : sum(ηn_vals) / length(ηn_vals)
    η̄_r = isempty(ηr_vals) ? NaN : sum(ηr_vals) / length(ηr_vals)
    return (; η̄_n, η̄_r, ηn_vals, ηr_vals)
end

"""
    tone_expected_value(inp, H, ωH; …) -> NamedTuple

CR-3813 Eqs. (14)–(16): expected value of the high-frequency tone ⟨p_i²⟩.
Returns ⟨p²⟩ from Eq. (16), mode counts, η̄, E[g], and the Eq. (15) form that
still carries ⟨ε_n f̄′²⟩ (barred, no extra τ_t — reading §4).
"""
function tone_expected_value(inp::PainInputs, H::Int, ωH::Float64;
                             c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                             q_max::Union{Nothing,Int}=nothing,
                             η_r_cap::Union{Nothing,Float64}=nothing,
                             use_pi_limit::Bool=true)
    fuse = inp.fuse
    a, L = fuse.a, fuse.L
    ρ_ext, c_ext = inp.ρ_ext, inp.c_ext
    ρ_int, c_int = inp.ρ_int, inp.c_int
    V = cabin_volume(inp)
    A = coupling_area(fuse)
    τ_t = sidewall_tau(inp, ωH)
    band = modes_in_tone_band(inp, ωH; c_ω, q_max)
    N_n = length(band.ac_list)
    N_r = length(band.st_list)
    Δω = band.Δω
    losses = band_average_loss_factors(inp, ωH, band; η_r_cap)
    η̄_n, η̄_r = losses.η̄_n, losses.η̄_r

    # Empty band → no high-frequency contribution
    if N_n == 0 || N_r == 0 || !(isfinite(η̄_n) && isfinite(η̄_r) && η̄_n > 0 && η̄_r > 0)
        return (; p2=0.0, p2_eq15=0.0, N_n, N_r, η̄_n, η̄_r,
                E_g_n=NaN, E_g_r=NaN, n_n=0.0, n_r=0.0, Δω, τ_t, c_ω, use_pi_limit)
    end

    E_g_n = use_pi_limit ? expected_g_pi(ωH, η̄_n, Δω) : expected_g_closed(ωH, η̄_n, Δω)
    E_g_r = use_pi_limit ? expected_g_pi(ωH, η̄_r, Δω) : expected_g_closed(ωH, η̄_r, Δω)
    n_n = N_n / Δω
    n_r = N_r / Δω

    # --- Eq. (15) with barred f̄' and no extra τ_t (reading §4) ---
    # E = (π² c_int²/V²)(n_r n_n)/(η̄_r η̄_n) (mA/4)²τ_ML(ext) · [(1/N_r) Σ_r Ψ_G ⟨ε_n f̄′²⟩ / M_r²]
    # When use_pi_limit=false, replace π²/(η̄_r η̄_n) path by E[g_n]E[g_r] via Eq. (14):
    #   (Q_H/ω_H^8) E[g_n] E[g_r] Σ_n Σ_r ε_n f̄′² Ψ_G/M_r²
    # with Q_H built without the printed τ_t (barred f̄' already carries √τ_t).
    mA4_τML = mass_law_factor(ρ_ext, c_ext, A, ωH)   # (mA/4)² τ_ML, no τ_t
    sum_r_15 = 0.0
    for mr in band.st_list
        Ψ = generalized_force(mr.st, H, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA)
        # ⟨ε_n f̄′²⟩_Δω = (1/N_n) Σ_n ε_n f̄′²(n,r)
        s_nf = 0.0
        for mn in band.ac_list
            f = coupling_factor(mn.ac, mr.st, inp; τ_t, q=mn.q)   # barred
            s_nf += mn.εn * f^2
        end
        avg_εf2 = s_nf / N_n
        sum_r_15 += Ψ * avg_εf2 / mr.st.M_r^2
    end
    sum_r_15 /= N_r
    if use_pi_limit
        # Eq. (15) prefactor without the printed τ_t^H (barred f̄')
        p2_eq15 = (π^2 * c_int^2 / V^2) * (n_r * n_n) / (η̄_r * η̄_n) * mA4_τML * sum_r_15
    else
        Q_H = 4 * (c_int / V)^2 * mA4_τML * ωH^6   # no τ_t; barred f̄'
        # Σ_n Σ_r ε_n f̄′² Ψ_G/M_r² = N_n N_r · (1/N_r) Σ_r Ψ_G ⟨ε_n f̄′²⟩/M_r²
        p2_eq15 = (Q_H / ωH^8) * E_g_n * E_g_r * (N_n * N_r) * sum_r_15
    end

    # --- Eq. (16) as printed: τ_t in the prefactor, j_r^rev replaces ⟨ε_n f′²⟩ ---
    # E = (ω_H²/(c_int V)) (n_r τ_ML τ_t)/(η̄_r η̄_n) (mA/4)² [(1/N_r) Σ_r Ψ_G j_r^rev / M_r²]
    sum_r_16 = 0.0
    for mr in band.st_list
        Ψ = generalized_force(mr.st, H, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA)
        j2 = structural_joint_acceptance(mr.st, ωH; a, L, c0=c_ext)
        sum_r_16 += Ψ * j2 / mr.st.M_r^2
    end
    sum_r_16 /= N_r
    p2_16 = (ωH^2 / (c_int * V)) * (n_r * τ_t) / (η̄_r * η̄_n) * mA4_τML * sum_r_16

    return (; p2=p2_16, p2_eq15, p2_eq16=p2_16, N_n, N_r, η̄_n, η̄_r,
            E_g_n, E_g_r, n_n, n_r, Δω, τ_t, c_ω, use_pi_limit, sum_r_15, sum_r_16)
end

"""
    tone_eq13_sample(inp, H, ωH, ωn_draw, ωr_draw; …) -> p²

One draw of Eq. (13): resonances fixed to the drawn values, g_n/g_r from η̄,
sums over modes in the band. Used for the Monte-Carlo V-UNIT check.
"""
function tone_eq13_sample(inp::PainInputs, H::Int, ωH::Float64,
                          ωn_draw::AbstractVector{<:Real}, ωr_draw::AbstractVector{<:Real};
                          c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                          q_max::Union{Nothing,Int}=nothing,
                          η_r_cap::Union{Nothing,Float64}=nothing)
    fuse = inp.fuse
    ρ_ext, c_ext = inp.ρ_ext, inp.c_ext
    c_int = inp.c_int
    V = cabin_volume(inp)
    A = coupling_area(fuse)
    τ_t = sidewall_tau(inp, ωH)
    band = modes_in_tone_band(inp, ωH; c_ω, q_max)
    N_n, N_r = length(band.ac_list), length(band.st_list)
    (N_n == 0 || N_r == 0) && return 0.0
    length(ωn_draw) == N_n || error("ωn_draw length $(length(ωn_draw)) ≠ N_n=$N_n")
    length(ωr_draw) == N_r || error("ωr_draw length $(length(ωr_draw)) ≠ N_r=$N_r")
    losses = band_average_loss_factors(inp, ωH, band; η_r_cap)
    η̄_n, η̄_r = losses.η̄_n, losses.η̄_r
    # Q_H without printed τ_t (barred f̄'); Eq. (13) as used with Eq. (8) convention
    Q_H = 4 * (c_int / V)^2 * mass_law_factor(ρ_ext, c_ext, A, ωH) * ωH^6
    s = 0.0
    for (i, mn) in enumerate(band.ac_list)
        gn = g_resonance(ωH, ωn_draw[i], η̄_n)
        for (j, mr) in enumerate(band.st_list)
            f = coupling_factor(mn.ac, mr.st, inp; τ_t, q=mn.q)
            f == 0 && continue
            gr = g_resonance(ωH, ωr_draw[j], η̄_r)
            Ψ = generalized_force(mr.st, H, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA)
            s += mn.εn * gn * f^2 * gr * Ψ / mr.st.M_r^2
        end
    end
    return (Q_H / ωH^8) * s
end

"""
    resolve_crossover_Hz(inp; bands, c_ω) -> Float64

Manual card 10: use `inp.crossover_band_Hz` when set, else `acoustic_crossover_band`.
"""
function resolve_crossover_Hz(inp::PainInputs;
                              bands::AbstractVector{<:Real}=third_octave_centers(),
                              c_ω::Real=C_OMEGA_THIRD_OCTAVE)
    inp.crossover_band_Hz !== nothing && return float(inp.crossover_band_Hz)
    return acoustic_crossover_band(inp; bands, c_ω).fc_Hz
end

"""
    tone_mean_square_pressure_pair(inp, H, ωH; …) -> (; p2_eq8, p2_eq15_16, p2, model)

Both formulations always; `p2` is the production value for `tone_model`:
`:eq8` (default) → Eq. (8); `:eq15_16` → Eq. (16); `:auto` → Eq. (8) below the
crossover band centre and Eq. (16) at/above it.
"""
function tone_mean_square_pressure_pair(inp::PainInputs, H::Int, ωH::Float64;
                                        q_max::Union{Nothing,Int}=nothing,
                                        η_r_cap::Union{Nothing,Float64}=nothing,
                                        tone_model::Symbol=:eq8,
                                        c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                                        crossover_Hz::Union{Nothing,Float64}=nothing)
    tone_model in (:eq8, :eq15_16, :auto) ||
        error("tone_model must be :eq8, :eq15_16, or :auto; got $tone_model")
    p2_8 = tone_mean_square_pressure(inp, H, ωH; q_max, η_r_cap)
    ev = tone_expected_value(inp, H, ωH; c_ω, q_max, η_r_cap)
    p2_hf = ev.p2
    xover = crossover_Hz === nothing ? resolve_crossover_Hz(inp; c_ω) : crossover_Hz
    fH = ωH / 2π
    if tone_model === :eq8
        p2, used = p2_8, :eq8
    elseif tone_model === :eq15_16
        p2, used = p2_hf, :eq15_16
    else
        # :auto — Manual output 9(3): Eq. (8) below crossover, Eqs. (15)–(16) at/above
        if isfinite(xover) && fH ≥ xover
            p2, used = p2_hf, :eq15_16
        else
            p2, used = p2_8, :eq8
        end
    end
    return (; p2_eq8=p2_8, p2_eq15_16=p2_hf, p2, model=used, crossover_Hz=xover,
            N_n=ev.N_n, N_r=ev.N_r, η̄_n=ev.η̄_n, η̄_r=ev.η̄_r, E_g_n=ev.E_g_n, E_g_r=ev.E_g_r)
end
