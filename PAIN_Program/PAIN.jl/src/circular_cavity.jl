# Exact acoustic modes of a rigid circular cylinder (closed ends) and Donnell–Mushtari
# shell modes for the bare TP-1964 cylinder (phase 43d). Coupling and NR use the same
# Eqs. (17)–(18) assembly as `noise_reduction_band`, with closed-form full-circle factors.

"""One rigid circular-cavity acoustic mode (m, k radial, q axial)."""
struct CircularAcousticMode
    index::Int
    m::Int                 # circumferential order (≥ 0)
    k::Int                 # radial index of J′_m zero (≥ 1)
    q::Int                 # axial half-waves (≥ 0)
    jprime::Float64        # j′_{m,k}
    f_Hz::Float64
    ε_n::Float64           # closed-form 3-D normalization (∫ φ² dV = V/ε_n)
    cos_family::Bool       # cos(mθ) vs sin(mθ); m=0 → cos only
end

"""Bessel J_n via series (same recurrence as ISO_CYL2D_EXACT / phase 40)."""
function _cav_besselj(n::Int, x::Float64)
    n < 0 && return _cav_besselj(-n, x) * (isodd(-n) ? -1.0 : 1.0)
    x == 0 && return n == 0 ? 1.0 : 0.0
    ax = abs(x)
    term = 1.0
    for k in 1:n
        term *= (ax / 2) / k
    end
    s = term
    for k in 1:80
        term *= -(ax / 2)^2 / (k * (k + n))
        s += term
        abs(term) < 1e-16 * max(abs(s), 1.0) && break
    end
    return (x < 0 && isodd(n)) ? -s : s
end

function _cav_besselj_prime(n::Int, x::Float64)
    x == 0 && return n == 1 ? 0.5 : (n == 0 ? 0.0 : 0.0)
    # J′_n = J_{n-1} - n/x J_n = n/x J_n - J_{n+1}
    return (n / x) * _cav_besselj(n, x) - _cav_besselj(n + 1, x)
end

"""First `n_roots` positive zeros of J′_m (independent of CYL2D; phase-40 finder reused)."""
function besselj_prime_zeros(m::Int, n_roots::Int; x_max::Float64=80.0)
    m ≥ 0 || error("besselj_prime_zeros: m ≥ 0")
    n_roots ≥ 1 || return Float64[]
    roots = Float64[]
    # First zero of J′_0 is ≈ 3.8317; of J′_1 ≈ 1.8412; …
    x = m == 0 ? 2.0 : max(m - 0.5, 0.5)
    dx = 0.15
    while length(roots) < n_roots && x < x_max
        x1 = x + dx
        f0 = _cav_besselj_prime(m, x)
        f1 = _cav_besselj_prime(m, x1)
        if f0 * f1 ≤ 0 && (f0 != 0 || f1 != 0)
            lo, hi = x, x1
            flo, fhi = f0, f1
            z = lo
            for _ in 1:60
                mid = 0.5 * (lo + hi)
                fm = _cav_besselj_prime(m, mid)
                if flo * fm ≤ 0
                    hi, fhi = mid, fm
                else
                    lo, flo = mid, fm
                end
                z = mid
                abs(hi - lo) < 1e-12 && break
            end
            # Newton polish
            for _ in 1:8
                jp = _cav_besselj_prime(m, z)
                # J″ ≈ −(1/x)J′ − (1 − n²/x²)J  → use finite difference
                jpp = (_cav_besselj_prime(m, z + 1e-8) - _cav_besselj_prime(m, z - 1e-8)) / 2e-8
                abs(jpp) < 1e-30 && break
                z -= jp / jpp
            end
            if z > 1e-6 && (isempty(roots) || z - roots[end] > 0.1)
                push!(roots, z)
            end
        end
        x = x1
    end
    return roots
end

"""
Closed-form cavity volume normalization ε_n for φ = J_m(j′_{m,k} r/R) · Θ(mθ) · Z(q,x)
with ∫_V φ² dV = V / ε_n, V = π R² L.

Θ = cos(mθ) or sin (ε_θ = 2−δ_{m0} for the 0..2π integral of Θ² / (2π) form used here).
Z = cos(qπx/L) (closed ends; ε_q = 2 for q=0, 1 else — same as cabin_eps_3d).
Radial: ∫_0^R J_m²(α r/R) r dr = (R²/2)(1 − m²/α²) J_m(α)² for α = j′_{m,k} ≠ 0.
"""
function circular_acoustic_eps(m::Int, jprime::Float64, q::Int)
    α = jprime
    I_θ = m == 0 ? 2π : π
    I_z_over_L = q == 0 ? 1.0 : 0.5
    if α == 0
        # Plane-wave family m=0, α=0: φ = Z(q,x); ∫_0^R r dr = R²/2 → I_r = 1/2
        m == 0 || error("α=0 only for m=0")
        return π / (0.5 * I_θ * I_z_over_L)  # = 1 (q=0) or 2 (q>0)
    end
    # φ = [J_m(α r/R)/J_m(α)] Θ(mθ) Z(q,x); ∫φ² = V/ε with V = π R² L
    I_r = 0.5 * (1 - (m / α)^2)
    return π / (I_r * I_θ * I_z_over_L)
end

"""
    circular_cavity_modes(R, L; c0=343, f_max_Hz=6000, m_max=20, k_max=12, q_max=40)

Exact rigid circular-cylinder acoustic modes up to `f_max_Hz`:
f = c₀/(2π) √((j′_{m,k}/R)² + (qπ/L)²). Both cos and sin families for m≥1.
"""
function circular_cavity_modes(R::Real, L::Real;
                               c0::Real=343.0, f_max_Hz::Real=6000.0,
                               m_max::Int=20, k_max::Int=12, q_max::Int=40)
    R = float(R); L = float(L); c0 = float(c0)
    modes = CircularAcousticMode[]
    idx = 0
    # m=0, α=0 (J′_0(0)=0): axial organ-pipe family f = c₀ q/(2L). Skip q=0 (f=0 rigid).
    for q in 1:q_max
        f = c0 * q / (2 * L)
        f > f_max_Hz && continue
        ε = circular_acoustic_eps(0, 0.0, q)
        idx += 1
        push!(modes, CircularAcousticMode(idx, 0, 0, q, 0.0, f, ε, true))
    end
    for m in 0:m_max
        roots = besselj_prime_zeros(m, k_max)
        for (k, jp) in enumerate(roots)
            for q in 0:q_max
                f = c0 / (2π) * sqrt((jp / R)^2 + (q * π / L)^2)
                f > f_max_Hz && continue
                ε = circular_acoustic_eps(m, jp, q)
                if m == 0
                    idx += 1
                    push!(modes, CircularAcousticMode(idx, m, k, q, jp, f, ε, true))
                else
                    idx += 1
                    push!(modes, CircularAcousticMode(idx, m, k, q, jp, f, ε, true))
                    idx += 1
                    push!(modes, CircularAcousticMode(idx, m, k, q, jp, f, ε, false))
                end
            end
        end
    end
    sort!(modes; by=m -> m.f_Hz)
    for (i, m) in enumerate(modes)
        modes[i] = CircularAcousticMode(i, m.m, m.k, m.q, m.jprime, m.f_Hz, m.ε_n, m.cos_family)
    end
    return modes
end

"""
Donnell–Mushtari simply-supported shell modes for a uniform closed cylinder
(m = 1..M_axial, n = 0..N_circ) up to `f_max_Hz`. Generalized mass of the uniform
shell for w = sin(mπx/L) cos(nθ) [or sin]: M_r = ρ t ∫∫ w² a dθ dx = ρ t (π a L)/2
(n=0: ρ t (2π a L)/2 = ρ t π a L).
"""
function donnell_shell_modes(R::Real, L::Real, t::Real, E::Real, ν::Real, ρ::Real;
                             f_max_Hz::Real=6000.0, m_max::Int=40, n_max::Int=40)
    R = float(R); L = float(L); t = float(t)
    modes = StructuralMode[]
    idx = 0
    for m in 1:m_max
        for n in 0:n_max
            f = donnell_mushtari_frequency_Hz(m, n, L, R, t, E, ν, ρ)
            f > f_max_Hz && continue
            # M_r = ρ t ∫_0^L ∫_0^{2π} w² a dθ dx; w = sin(mπx/L) * {cos nθ or 1}
            Mr = if n == 0
                ρ * t * π * R * L          # ∫ sin² = L/2, ∫ dθ = 2π → ρ t a (L/2) 2π
            else
                ρ * t * (π * R * L) / 2    # ∫ cos² = π, ∫ sin² = L/2
            end
            # Symmetric family (cos nθ); antisymmetric (sin) for n≥1 — same f, same M_r
            idx += 1
            push!(modes, StructuralMode(idx, f, true, Mr, m, [1.0], [n], Float64[], Int[]))
            if n ≥ 1
                idx += 1
                push!(modes, StructuralMode(idx, f, false, Mr, m, [1.0], [n], Float64[], Int[]))
            end
        end
    end
    sort!(modes; by=m -> m.f_Hz)
    for (i, m) in enumerate(modes)
        modes[i] = StructuralMode(i, m.f_Hz, m.symmetric, m.M_r, m.M_axial,
                                  m.C_shell, m.n_shell, m.C_floor, m.n_floor)
    end
    return StructuralModes(modes, L, R, 0.0, "Donnell–Mushtari SS bare cylinder (43d)")
end

"""
Coupling factor f̄' for a full circle (no floor): surface integral of structural
mode shape × acoustic mode at r = R, normalized by circumference 2πR (Eq. 52
denominator with θ₀ = 0, L_p = 0).

Closed form for cos/cos (and sin/sin): non-zero only when circumferential orders
match and symmetries agree; axial factor f_{qM} of `axial_coupling`.
"""
function circular_coupling_factor(ac::CircularAcousticMode, st::StructuralMode,
                                 R::Real, L::Real; τ_t::Float64=1.0)
    n_shell = isempty(st.n_shell) ? -1 : st.n_shell[1]
    n_shell == ac.m || return 0.0
    ac.cos_family == st.symmetric || return 0.0
    # Wall acoustic amplitude = 1 (J normalized out of ε); structural C = 1
    # ∫_0^{2π} cos(mθ) cos(nθ) R dθ = π R (1+δ_{m0}) when m=n
    # Denominator A_c = 2π R (full circumference)
    # Circumferential part of f: √τ_t * I_θ / (2π R)
    I_θ = ac.m == 0 ? 2π * R : π * R
    circ = sqrt(τ_t) * I_θ / (2π * R)
    ax = axial_coupling(ac.q, st.M_axial; L=L, L_c=L, d=0.0)
    f = ax * circ
    abs(f) ≤ 1 + 1e-6 ||
        error("circular_coupling_factor: |f|=$f > 1 (ac=$(ac.index), st=$(st.index))")
    return f
end

"""Log-log interpolate η(f) from (f,η) samples; end values held outside the span."""
function loglog_interp_eta(f_Hz::Real, f_s::AbstractVector{<:Real}, η_s::AbstractVector{<:Real})
    f = float(f_Hz)
    isempty(f_s) && error("loglog_interp_eta: empty samples")
    if f ≤ f_s[1]
        return float(η_s[1])
    elseif f ≥ f_s[end]
        return float(η_s[end])
    end
    i = searchsortedlast(f_s, f)
    i = clamp(i, 1, length(f_s) - 1)
    lf0, lf1 = log(f_s[i]), log(f_s[i + 1])
    le0, le1 = log(max(η_s[i], 1e-30)), log(max(η_s[i + 1], 1e-30))
    t = (log(f) - lf0) / (lf1 - lf0)
    return exp(le0 + t * (le1 - le0))
end

"""η = 2.2/(f T60) from a reverberation CSV (kind filter); log-log interp, ends held."""
function eta_from_reverberation_csv(path::AbstractString, kind::AbstractString, f_Hz::Real)
    rows = _read_csv_mixed_kind_eta(path, kind)
    return loglog_interp_eta(f_Hz, rows.f, rows.η)
end

function _read_csv_mixed_kind_eta(path::AbstractString, kind::AbstractString)
    f = Float64[]; η = Float64[]
    for line in eachline(path)
        startswith(line, "#") && continue
        isempty(strip(line)) && continue
        startswith(line, "kind") && continue
        parts = split(line, ',')
        length(parts) ≥ 4 || continue
        parts[1] == kind || continue
        push!(f, parse(Float64, parts[2]))
        push!(η, parse(Float64, parts[4]))
    end
    isempty(f) && error("no $kind rows in $path")
    p = sortperm(f)
    return (; f=f[p], η=η[p])
end

"""
    noise_reduction_band_circular(fc, structural, acoustic; R, L, m_wall, η_n, η_r, …)

Eq. (18) for a bare full-circle cylinder with exact circular acoustic modes and
Donnell shell modes. `η_n` / `η_r` are band scalars (measured decay). Does not
alter `noise_reduction_band` for existing (floored) cases.
"""
function noise_reduction_band_circular(fc::Real,
                                       structural::StructuralModes,
                                       acoustic::Vector{CircularAcousticMode};
                                       R::Real, L::Real,
                                       m_wall::Real,
                                       η_n::Real, η_r::Real,
                                       ρ_ext::Real=1.225, c_ext::Real=343.0,
                                       ρ_int::Real=1.225, c_int::Real=343.0,
                                       c_ω::Real=C_OMEGA_THIRD_OCTAVE,
                                       η_r_cap::Union{Nothing,Float64}=nothing)
    R = float(R); L = float(L)
    ω = 2π * float(fc)
    A = 2π * R * L                 # full cylinder transmitting / coupling area
    Abar = A
    V = π * R^2 * L
    mA4_τ = mass_law_factor(ρ_ext, c_ext, A, ω)
    # Eq. (18) prefactor (same as noise_reduction_band)
    pref = 8 / (c_ω * ω) * (Abar / V)^2 * mA4_τ * c_int^2 * ω^3
    ηn = float(η_n)
    # Sum over every computed mode (no band window): below the first resonant pair the
    # band is carried by off-resonance (mass/stiffness) coupling, which a window would drop
    # (ratio = 0, NR = Inf). The f = 0 rigid mode is excluded (ω_n = 0).
    ac_use = filter(ac -> ac.f_Hz > 0, acoustic)
    st_use = structural.modes
    ratio = 0.0
    for ac in ac_use
        ωn = 2π * ac.f_Hz
        εn = ac.ε_n
        N = ηn * ωn^2
        for st in st_use
            f̄ = circular_coupling_factor(ac, st, R, L; τ_t=1.0)
            f̄ == 0 && continue
            ωr = 2π * st.f_Hz
            ηrp = apply_η_r_cap(float(η_r), η_r_cap)
            j2 = structural_joint_acceptance(st, ω; a=R, L=L, c0=c_ext)
            ηrpp = structural_loss_coupled(N, ωn, ωr, f̄, εn, st.M_r, V, A;
                                           ρ0=ρ_int, c0=c_int)
            ηrt = ηrp + ηrpp
            t = nr_brace(ω, c_ω, ωn, ηn, ωr, ηrt)
            ratio += pref * εn * j2 * f̄^2 / (st.M_r^2 * t.D_nr) * t.brace
        end
    end
    NR = ratio > 0 ? -10 * log10(ratio) : Inf
    return (; ratio, NR_dB=NR, fc_Hz=float(fc), V, A, Abar, η_n=ηn, η_r=float(η_r),
            n_ac=length(ac_use), n_st=length(st_use))
end

function noise_reduction_spectrum_circular(structural::StructuralModes,
                                           acoustic::Vector{CircularAcousticMode},
                                           bands::AbstractVector{<:Real};
                                           R::Real, L::Real, m_wall::Real,
                                           η_n_of, η_r_of, kwargs...)
    rows = [noise_reduction_band_circular(fc, structural, acoustic;
                                          R=R, L=L, m_wall=m_wall,
                                          η_n=η_n_of(fc), η_r=η_r_of(fc), kwargs...)
            for fc in bands]
    return (; bands=float.(collect(bands)), rows)
end
