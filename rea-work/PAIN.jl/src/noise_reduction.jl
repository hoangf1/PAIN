# CR-3813 §3.3 noise reduction for a reverberant (diffuse) exterior field.
# Equations (17)–(18) and the ln/arctan/D_nr helpers as printed on pp. 21–23
# (PDF pages 31–33). No parameter is chosen from E-21/E-22.

"""b_j, c_j of CR-3813 p. 22 for acoustic (n) or structural (r) resonator."""
nr_b(ωj::Real) = -2 * ωj^2
nr_c(ωj::Real, ηj::Real) = ωj^4 * (1 + ηj^2)

"""
    nr_ln(ω, c_ω, b_j, c_j) -> ln_j

CR-3813 p. 22: ln of the ratio of |ω⁴(1±c_ω/2)⁴ + b_j ω²(1±c_ω/2)² + c_j| at the
upper and lower band edges.
"""
function nr_ln(ω::Real, c_ω::Real, b_j::Real, c_j::Real)
    up = 1 + c_ω / 2
    dn = 1 - c_ω / 2
    num = abs(up^4 * ω^4 + b_j * up^2 * ω^2 + c_j)
    den = abs(dn^4 * ω^4 + b_j * dn^2 * ω^2 + c_j)
    return log(num / max(den, floatmin(Float64)))
end

"""
    nr_arctan(ω, c_ω, ω_j, η_j) -> arctan_j

CR-3813 p. 22. For j = r use η_j = η_r' + η_r''; for j = n use η_j = η_n.
"""
function nr_arctan(ω::Real, c_ω::Real, ω_j::Real, η_j::Real)
    η_j == 0 && return 0.0   # η→0: both arguments → ±Inf with equal magnitude → difference → 0 at leading order; finite limit handled by the paired form
    d = 4 * η_j * ω_j^2
    return atan(((2 + c_ω)^2 * ω^2 - 4 * ω_j^2) / d) -
           atan(((2 - c_ω)^2 * ω^2 - 4 * ω_j^2) / d)
end

"""D_nr = (c_r − c_n)² + (b_n − b_r)(b_n c_r − b_r c_n) (p. 22)."""
nr_D(b_n::Real, c_n::Real, b_r::Real, c_r::Real) =
    (c_r - c_n)^2 + (b_n - b_r) * (b_n * c_r - b_r * c_n)

"""
    nr_brace(ω, c_ω, ω_n, η_n, ω_r, η_r) -> (; brace, D_nr, ln_n, ln_r, arctan_n, arctan_r, …)

Printed `{…}_nr` of Eqs. (17)–(18) and D_nr. `η_r` here is η_r' + η_r''.
"""
function nr_brace(ω::Real, c_ω::Real, ω_n::Real, η_n::Real, ω_r::Real, η_r::Real)
    b_n, b_r = nr_b(ω_n), nr_b(ω_r)
    c_n, c_r = nr_c(ω_n, η_n), nr_c(ω_r, η_r)
    D = nr_D(b_n, c_n, b_r, c_r)
    ln_n = nr_ln(ω, c_ω, b_n, c_n)
    ln_r = nr_ln(ω, c_ω, b_r, c_r)
    at_n = nr_arctan(ω, c_ω, ω_n, η_n)
    at_r = nr_arctan(ω, c_ω, ω_r, η_r)
    brace = ((c_r - c_n) / 4) * ln_n +
            ((2 * c_n * (b_r - b_n) - b_n * (c_r - c_n)) / (4 * η_n * ω_n^2)) * at_n +
            ((c_n - c_r) / 4) * ln_r +
            ((2 * c_r * (b_n - b_r) - b_r * (c_n - c_r)) / (4 * η_r * ω_r^2)) * at_r
    return (; brace, D_nr=D, ln_n, ln_r, arctan_n=at_n, arctan_r=at_r, b_n, c_n, b_r, c_r)
end

"""
    nr_band_integral_closed(ω, c_ω, ω_n, η_n, ω_r, η_r) -> brace / D_nr

Closed form of ∫_{ω(1−c_ω/2)}^{ω(1+c_ω/2)} ω'³ / [poly_n(ω'²) poly_r(ω'²)] dω'
with poly_j(u) = u² + b_j u + c_j = (ω_j² − ω'²)² + (η_j ω_j²)² (derived from Eqs. 5–7/17).
"""
function nr_band_integral_closed(ω::Real, c_ω::Real, ω_n::Real, η_n::Real, ω_r::Real, η_r::Real)
    t = nr_brace(ω, c_ω, ω_n, η_n, ω_r, η_r)
    return t.brace / t.D_nr
end

"""
Numerical band integral of the product of the two resonance denominators
(same integrand as `nr_band_integral_closed`).
"""
function nr_band_integral_quad(ω::Real, c_ω::Real, ω_n::Real, η_n::Real, ω_r::Real, η_r::Real;
                               N::Int=50_000)
    lo = ω * (1 - c_ω / 2)
    hi = ω * (1 + c_ω / 2)
    h = (hi - lo) / N
    s = 0.0
    Nn = η_n * ω_n^2
    Nr = η_r * ω_r^2
    for i in 1:N
        w = lo + (i - 0.5) * h
        pn = (w^2 - ω_n^2)^2 + Nn^2
        pr = (w^2 - ω_r^2)^2 + Nr^2
        s += h * w^3 / (pn * pr)
    end
    return s
end

"""Complete-cylinder surface area Ā = 2π a L (CR-3813 p. 21 / Eq. 81 usage)."""
cylinder_surface_area(a::Real, L::Real) = 2π * a * L

"""Coupling (transmitting) area A = L(Lp + 2a(π − θ0)), same as the tone path."""
function coupling_area(fuse::FuselageGeometry)
    a, L = fuse.a, fuse.L
    θ0 = deg2rad(fuse.theta0_deg)
    Lp = 2a * sin(θ0)
    return L * (Lp + 2a * (π - θ0))
end

"""(mA/4)² τ_ML = (ρ0 c0 A / (2ω))² — phase 19b identity; reuse, do not re-derive."""
mass_law_factor(ρ0::Real, c0::Real, A::Real, ω::Real) = (ρ0 * c0 * A / (2 * ω))^2

"""
    acoustic_modes_in_band(inp, fc; c_ω=C_OMEGA_THIRD_OCTAVE) -> Int

Count of 3-D acoustic modes (q, i) with resonance inside
[ω(1−c_ω/2), ω(1+c_ω/2)], q = 0…q_max for the band's upper edge (CYL2D × axial).
"""
function acoustic_modes_in_band(inp::PainInputs, fc::Real; c_ω::Real=C_OMEGA_THIRD_OCTAVE)
    ω = 2π * fc
    lo = ω * (1 - c_ω / 2)
    hi = ω * (1 + c_ω / 2)
    a, L_c, c_int = inp.fuse.a, inp.L_c, inp.c_int
    qtop = something(inp.q_max, axial_truncation(hi, L_c, c_int))
    n = 0
    for q in 0:qtop, ac in inp.acoustic.modes
        ωn = 2π * cabin_frequency_3d(ac, a, L_c, q; c0=c_int)
        (lo ≤ ωn ≤ hi) && (n += 1)
    end
    return n
end

"""
    acoustic_crossover_band(inp; bands, c_ω, n_min=10) -> (; fc_Hz, n_modes, band_index)

Lowest 1/3-octave band whose count of 3-D acoustic modes in the band is ≥ `n_min`
(CR-3813 §3.3 / phase 38b rule, fixed before any run).
"""
function acoustic_crossover_band(inp::PainInputs;
                                 bands::Union{Nothing,AbstractVector{<:Real}}=nothing,
                                 c_ω::Real=C_OMEGA_THIRD_OCTAVE, n_min::Int=10)
    bs = bands === nothing ? resolve_bands(inp) : bands
    for (i, fc) in enumerate(bs)
        n = acoustic_modes_in_band(inp, fc; c_ω)
        n ≥ n_min && return (; fc_Hz=float(fc), n_modes=n, band_index=i)
    end
    return (; fc_Hz=NaN, n_modes=0, band_index=0)
end

"""Apply the optional NASA η_r' cap (E-18/E-21: 0.15); `nothing` = no cap."""
apply_η_r_cap(η_r′::Real, η_r_cap::Union{Nothing,Float64}) =
    η_r_cap === nothing ? float(η_r′) : min(float(η_r′), η_r_cap)

"""
    w_in_reverberant(inp, fc; ⟨p_bl²⟩=1, η_r_cap=nothing, c_ω=…) -> (; W_in, contributions)

Eq. (17): modal inflow for a reverberant blocked field of mean-square ⟨p_bl²⟩ in the band.
`coupling_factor` supplies the barred f̄'(n,r) (Eq. 52 with √τ_t); `structural_joint_acceptance`
is the reverberant j_r²(ω) of §3.6 (diffuse sin(kξ)/(kξ), checked in 16b).
"""
function w_in_reverberant(inp::PainInputs, fc::Real;
                          p_bl2::Real=1.0,
                          η_r_cap::Union{Nothing,Float64}=nothing,
                          c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                          q_max::Union{Nothing,Int}=nothing)
    fuse = inp.fuse
    a, L = fuse.a, fuse.L
    L_c = inp.L_c
    ρ_ext, c_ext = inp.ρ_ext, inp.c_ext
    ρ_int, c_int = inp.ρ_int, inp.c_int
    ω = 2π * fc
    A = coupling_area(fuse)
    Abar = cylinder_surface_area(a, L)
    V = cabin_volume(inp)
    ext = inp.allow_extrapolation
    trimmed = has_trim(inp)
    τ_t = sidewall_tau(inp, ω)
    ξ = trimmed ? trim_conductance(inp.sidewall, ω, inp.m_wall; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0
    ξe = trimmed ? trim_conductance(inp.endplates, ω, Inf; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0
    mA4_τ = mass_law_factor(ρ_ext, c_ext, A, ω)
    hi = ω * (1 + c_ω / 2)
    qtop = something(q_max, inp.q_max, axial_truncation(hi, L_c, c_int))

    # per structural mode: ω_r, η_r', j_r²^rev(ω)
    nst = length(inp.structural.modes)
    ωr = Vector{Float64}(undef, nst)
    ηrp = Vector{Float64}(undef, nst)
    j2 = Vector{Float64}(undef, nst)
    f_band = ω / 2π
    for (j, st) in enumerate(inp.structural.modes)
        ωr[j] = 2π * st.f_Hz
        ηrp[j] = structural_η_r_prime(inp, st, ωr[j]; η_r_cap, Abar)
        j2[j] = structural_joint_acceptance(st, ω; a, L, c0=c_ext)
    end

    # Prefactor of Eq. (17): ⟨p_bl²⟩/(c_ω ω) · (2π Ā²)/(ρ_int V) · (mA/4)² τ_ML(ρ_ext,c_ext)
    pref = p_bl2 / (c_ω * ω) * (2π * Abar^2) / (ρ_int * V) * mA4_τ
    W = 0.0
    contribs = NamedTuple[]
    for q in 0:qtop, ac in inp.acoustic.modes
        ωn = 2π * cabin_frequency_3d(ac, a, L_c, q; c0=c_int)
        ωn == 0 && continue   # rigid-body: η_n undefined / Inf; no band contribution in the closed form
        εn = cabin_eps_3d(ac, q)
        N = acoustic_N(inp, ac, q, f_band, ωn; ξ, ξ_e=ξe, V)
        ηn = N / ωn^2
        for (j, st) in enumerate(inp.structural.modes)
            f = coupling_factor(ac, st, inp; τ_t, q)   # barred f̄'
            f == 0 && continue
            ηrpp = structural_loss_coupled(N, ωn, ωr[j], f, εn, st.M_r, V, A; ρ0=ρ_int, c0=c_int)
            ηrt = ηrp[j] + ηrpp
            t = nr_brace(ω, c_ω, ωn, ηn, ωr[j], ηrt)
            # { (2/π) ω² ω_n² / D_nr · […] }
            curly = (2 / π) * ω^2 * ωn^2 / t.D_nr * t.brace
            term = pref * εn * j2[j] * f^2 / st.M_r^2 * curly
            W += term
            push!(contribs, (; q, i=ac.index, r=st.index, term, η_n=ηn, η_r′=ηrp[j], η_r″=ηrpp, f̄′=f, j2=j2[j]))
        end
    end
    return (; W_in=W, contributions=contribs, pref, A, Abar, V, ω, τ_t)
end

"""
    noise_reduction_band(inp, fc; η_r_cap=nothing, c_ω=…, hf_model=:none) -> NamedTuple

Eq. (18): ⟨p_i²⟩/⟨p_e²⟩ for one 1/3-octave band, with ⟨p_e²⟩ = ⟨p_bl²⟩/2 (p. 23).
NR(band) = 10 log10(⟨p_e²⟩/⟨p_i²⟩) = −10 log10(Eq. 18).

`hf_model`: `:none` (default — always Eq. 18) or `:eq19` (printed Eqs. 19–23 when
`fc` is at/above the crossover; Eq. 18 below). Default behaviour unchanged.
"""
function noise_reduction_band(inp::PainInputs, fc::Real;
                              η_r_cap::Union{Nothing,Float64}=nothing,
                              c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                              q_max::Union{Nothing,Int}=nothing,
                              crossover_fc::Union{Nothing,Float64}=nothing,
                              hf_model::Symbol=:none)
    hf_model in (:none, :eq19) || error("hf_model must be :none or :eq19 (got $hf_model)")
    xover = crossover_fc === nothing ? acoustic_crossover_band(inp; c_ω).fc_Hz : crossover_fc
    above = isfinite(xover) && fc ≥ xover - 1e-9
    n_in_band = acoustic_modes_in_band(inp, fc; c_ω)

    if hf_model === :eq19 && above
        pr = hf_pressure_ratio(inp, fc; c_ω, η_r_cap)
        # Eq. 23 gives ⟨p_e²⟩/⟨p_i²⟩; Eq. 18 stores ⟨p_i²⟩/⟨p_e²⟩ as `ratio`
        ratio_i_over_e = pr.ratio > 0 && isfinite(pr.ratio) ? 1 / pr.ratio : Inf
        return (; ratio=ratio_i_over_e, NR_dB=pr.NR_dB, n_modes_in_band=n_in_band,
                above_crossover=above, crossover_fc_Hz=xover, fc_Hz=float(fc),
                pref=NaN, A=pr.A_t + pr.A′, Abar=pr.Abar, V=pr.losses.areas.V, ω=pr.ω,
                τ_t=pr.τ_t, η_r_cap, hf_model=:eq19, eq23_ratio=pr.ratio)
    end

    fuse = inp.fuse
    a, L = fuse.a, fuse.L
    L_c = inp.L_c
    ρ_ext, c_ext = inp.ρ_ext, inp.c_ext
    ρ_int, c_int = inp.ρ_int, inp.c_int
    ω = 2π * fc
    A = coupling_area(fuse)
    Abar = cylinder_surface_area(a, L)
    V = cabin_volume(inp)
    ext = inp.allow_extrapolation
    trimmed = has_trim(inp)
    τ_t = sidewall_tau(inp, ω)
    ξ = trimmed ? trim_conductance(inp.sidewall, ω, inp.m_wall; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0
    ξe = trimmed ? trim_conductance(inp.endplates, ω, Inf; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0
    mA4_τ = mass_law_factor(ρ_ext, c_ext, A, ω)
    hi = ω * (1 + c_ω / 2)
    qtop = something(q_max, inp.q_max, axial_truncation(hi, L_c, c_int))

    nst = length(inp.structural.modes)
    ωr = Vector{Float64}(undef, nst)
    ηrp = Vector{Float64}(undef, nst)
    j2 = Vector{Float64}(undef, nst)
    f_band = ω / 2π
    for (j, st) in enumerate(inp.structural.modes)
        ωr[j] = 2π * st.f_Hz
        ηrp[j] = structural_η_r_prime(inp, st, ωr[j]; η_r_cap, Abar)
        j2[j] = structural_joint_acceptance(st, ω; a, L, c0=c_ext)
    end

    # Eq. (18) prefactor: 8/(c_ω ω) · Ā²/V² · (mA/4)² τ_ML(ext) · c_int² · ω³
    pref = 8 / (c_ω * ω) * (Abar / V)^2 * mA4_τ * c_int^2 * ω^3
    ratio = 0.0
    for q in 0:qtop, ac in inp.acoustic.modes
        ωn = 2π * cabin_frequency_3d(ac, a, L_c, q; c0=c_int)
        ωn == 0 && continue
        εn = cabin_eps_3d(ac, q)
        N = acoustic_N(inp, ac, q, f_band, ωn; ξ, ξ_e=ξe, V)
        ηn = N / ωn^2
        for (j, st) in enumerate(inp.structural.modes)
            f = coupling_factor(ac, st, inp; τ_t, q)   # barred f̄' as printed in Eq. 18
            f == 0 && continue
            ηrpp = structural_loss_coupled(N, ωn, ωr[j], f, εn, st.M_r, V, A; ρ0=ρ_int, c0=c_int)
            ηrt = ηrp[j] + ηrpp
            t = nr_brace(ω, c_ω, ωn, ηn, ωr[j], ηrt)
            ratio += pref * εn * j2[j] * f^2 / (st.M_r^2 * t.D_nr) * t.brace
        end
    end
    # NR = 10 log10(⟨p_e²⟩/⟨p_i²⟩) = −10 log10(ratio); guard non-positive
    NR = ratio > 0 ? -10 * log10(ratio) : Inf
    return (; ratio, NR_dB=NR, n_modes_in_band=n_in_band, above_crossover=above,
            crossover_fc_Hz=xover, fc_Hz=float(fc), pref, A, Abar, V, ω, τ_t, η_r_cap,
            hf_model=:eq18)
end

"""
    noise_reduction_spectrum(inp; bands, η_r_cap, c_ω, hf_model=:none) -> NamedTuple

Eq. (18) for every band in `bands` (default 1/3-octave centres). Reports the crossover
band; values at and above it are marked `above_crossover`. With `hf_model=:eq19`, bands
at/above crossover use printed Eqs. (19)–(23) instead (38c).
"""
function noise_reduction_spectrum(inp::PainInputs;
                                  bands::Union{Nothing,AbstractVector{<:Real}}=nothing,
                                  η_r_cap::Union{Nothing,Float64}=nothing,
                                  c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                                  hf_model::Symbol=:none)
    bs = bands === nothing ? resolve_bands(inp) : float.(collect(bands))
    xover = acoustic_crossover_band(inp; bands=bs, c_ω)
    rows = [noise_reduction_band(inp, fc; η_r_cap, c_ω, crossover_fc=xover.fc_Hz, hf_model)
            for fc in bs]
    return (; bands=bs, rows, crossover=xover, η_r_cap, c_ω, hf_model)
end

"""
Build Phase-III test-article `PainInputs` for noise-reduction (no propeller grid needed:
Eq. 18 uses j_r²^rev, not Ψ_G). Dummy unit amplitudes satisfy the struct.
"""
function noise_reduction_test_article_inputs(; η_lining::Real=1.0,
                                             NY::Int=10, n_modes::Int=20)
    fuse = FuselageGeometry(1.803, 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.90)
    acoustic = cyl2d_modes(56.6; n_modes, NY)
    structural = structural_modes_from_table_d1(; n_keep=32)
    pts = grid_points(fuse, prop, GridSpec())
    # Dummy blocked field (unused by Eq. 18; required by PainInputs)
    amps = ones(Float64, 10, 16, 1)
    phases = zeros(Float64, 10, 16, 1)
    ΔA = (π * 0.508 / 18)^2
    p3 = phase3_trim(; a=0.508, L=1.803, theta0_deg=56.6, η_lining)
    # allow_extrapolation: E-21 bands include 63 Hz (below Fig. A-2's 100 Hz); NASA's PAIN
    # produced values there — flag X-EXTRAP for the insulation table outside 100–6300 Hz.
    inp = PainInputs(fuse, prop, structural, acoustic, amps, phases, pts, ΔA;
                     sidewall=p3.sidewall, endplates=p3.ends, mech=p3.mech, m_wall=p3.m_wall,
                     allow_extrapolation=true)
    return inp
end
