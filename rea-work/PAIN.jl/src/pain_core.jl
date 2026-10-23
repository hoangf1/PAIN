"""
PAIN main — tone transmission through stiffened cylinder + trim
(NASA-CR-3813 §3; flowchart PAIN).

Pipeline per harmonic H:
  blocked grid A_H, φ_H
  → generalized force Ψ_G(r,H) = (Δ⁴/2)[(Σ A ψ cos φ)² + (Σ A ψ sin φ)²]   (Eq. 42)
  → coupling f̄'(n,r), Eq. (52), with τ_t(ω_H) of Eq. (A.22) on the shell term
  → loss factors η_n (Eq. 77, or the bare input), η_r' (Eqs. 79–82), η_r'' (Eq. 83)
  → ⟨p_n²⟩ of Eq. (8) for every cabin mode n = (q, i) and structural mode r, summed over n by Eq. (3)
  → space-average interior SPL

Trim enters as stacks of App. A elements (`TrimStack`), not as a fitted coefficient: τ_t, the conductances
ξ, ξ_e and C_w come from the transfer matrices of `trim_loss.jl`. No parameter in the tone path is tuned
to T1 or T2 (plan phase 17a).
"""

"""
    PainInputs(fuse, prop, structural, acoustic, amplitudes, phases, pts, ΔA; sidewall, endplates, mech,
               m_wall, η_n_bare, C_struc, q_max, allow_extrapolation, ρ0, c0,
               ρ_ext, c_ext, ρ_int, c_int, L_c, d, crossover_band_Hz)

Inputs of the PAIN core. `sidewall`/`endplates` are the App. A trim stacks of the curved wall and of the end plates
(`nothing` for both = bare cabin: τ_t = 1, η_n = `η_n_bare` for every mode, η_r' = η_r). `mech` is the mechanical
trim path of Eq. (A.19) (`nothing` = insulation path only). `m_wall` [kg/m²] is the wall mass of Eqs. (81)–(82)
(`NaN` = the smeared skin, stringer and frame mass of the Phase III article). `C_struc` is the C of Eq. (80),
`q_max` the axial truncation of the cabin modes (`nothing` = ⌈2ω_H L_c/(π c_int)⌉), `allow_extrapolation` lets the
insulation table be continued beyond its digitized range (the result is then X-EXTRAP).

Manual card 2: `ρ0`,`c0` are the single-air entry points — when `ρ_ext`/`c_ext`/`ρ_int`/`c_int` are omitted they
equal `ρ0`,`c0` (bitwise-identical to the pre-38f-1 single-air path). Card 9: `L_c` (default = structure length
`fuse.L`) and offset `d` (default 0). Card 36 rotation sense lives on `prop.rotation_direction`.

Cards 3–6 (38f-2): `bands` = user 1/3-octave centres (≤ 26, standard, ascending); `nothing` = current fixed list
`third_octave_centers()`. Cards 11–18: `η_r_band` / `η_n_band` = per-band overrides (Dict keyed by centre Hz, or a
vector aligned with `bands`). Zero or absent → compute as before (η_r from Eqs. 79–81 then 82 if trim; η_n from
trim Eq. 77 or scalar `η_n_bare`). Non-zero η_r replaces η_r of Eqs. 79–81 before trim; non-zero η_n replaces η_n.

Card 2 term map (CR-3813 symbols ρ₀/c₀ exterior, ρ/c interior when distinguished; else single air):
  exterior (ρ_ext, c_ext): mass-law (mA/4)²τ_ML; η_rad^ext; ρ₀ in τ_R; structural joint acceptance k=ω/c_ext;
    exterior radiation part of η_r′; blocked-field side of Eqs. 19–23.
  interior (ρ_int, c_int): cabin modes ω_n, axial truncation; V and 4c²/V² (Eq. 8); η_n (Eq. 77) and trim
    conductance facing the cavity; η_r″ (Eq. 83); ᾱ / W_diss; η_rad^int; ρ and c₀ in τ_f and the (4ρ c₀/Ā)
    factor of τ_R; cavity energy factor ρ in Eq. 17.
"""
struct PainInputs
    fuse::FuselageGeometry
    prop::PropellerPlacement
    structural::StructuralModes
    acoustic::Cyl2DResult
    # Blocked pressure grid: amplitudes[k,ell,H], phases[k,ell,H]
    amplitudes::Array{Float64,3}
    phases::Array{Float64,3}
    pts
    ΔA::Float64                 # grid cell area Δ² [m²]
    sidewall::Union{Nothing,TrimStack}
    endplates::Union{Nothing,TrimStack}
    mech::Union{Nothing,MechanicalPath}
    m_wall::Float64
    η_n_bare::Float64
    C_struc::Float64
    q_max::Union{Nothing,Int}
    allow_extrapolation::Bool
    ρ0::Float64                 # single-air entry (sets both sides when split omitted)
    c0::Float64
    ρ_ext::Float64
    c_ext::Float64
    ρ_int::Float64
    c_int::Float64
    L_c::Float64                # cavity length [m]; acoustic axial scale (card 9)
    d::Float64                  # structure start relative to cavity start [m] (card 9)
    # Manual card 10: high-frequency crossover band centre [Hz]; `nothing` = estimate
    # (default: band containing f = 4.1 c₀/∛V, card 10 option a / phase 43a;
    #  `:ten_modes` option = lowest 1/3-oct with ≥ 10 acoustic modes, phase 38b).
    crossover_band_Hz::Union{Nothing,Float64}
    # Manual cards 3–6 / 11–18 (38f-2); `nothing` = default list / compute loss factors
    bands::Union{Nothing,Vector{Float64}}
    η_r_band::Union{Nothing,Dict{Float64,Float64}}
    η_n_band::Union{Nothing,Dict{Float64,Float64}}
    # When true, η_r_band overrides are final η_r′ (skip Eq. 82 trim); for measured
    # decay inputs (phase 43b). Default false keeps Manual card 11–14 = pre-trim η_r.
    η_r_band_is_prime::Bool
end

function PainInputs(fuse, prop, structural, acoustic, amplitudes, phases, pts, ΔA::Real;
                    sidewall::Union{Nothing,TrimStack}=nothing,
                    endplates::Union{Nothing,TrimStack}=nothing,
                    mech::Union{Nothing,MechanicalPath}=nothing,
                    m_wall::Real=NaN, η_n_bare::Real=0.05, C_struc::Real=3.0,
                    q_max::Union{Nothing,Integer}=nothing, allow_extrapolation::Bool=false,
                    ρ0::Real=1.225, c0::Real=340.0,
                    ρ_ext::Union{Nothing,Real}=nothing, c_ext::Union{Nothing,Real}=nothing,
                    ρ_int::Union{Nothing,Real}=nothing, c_int::Union{Nothing,Real}=nothing,
                    L_c::Union{Nothing,Real}=nothing, d::Real=0.0,
                    crossover_band_Hz::Union{Nothing,Real}=nothing,
                    bands=nothing, η_r_band=nothing, η_n_band=nothing,
                    η_r_band_is_prime::Bool=false)
    (sidewall === nothing) == (endplates === nothing) ||
        error("PainInputs: give both `sidewall` and `endplates` trim stacks, or neither (bare cabin)")
    mech !== nothing && sidewall === nothing && error("PainInputs: `mech` needs a `sidewall` stack")
    m = isnan(m_wall) ? MRP_RHO_2024 * (MRP_T_SKIN + MRP_A_STRINGER / MRP_D_STRINGER + MRP_A_FRAME / MRP_ELL_FRAME) : float(m_wall)
    xover = crossover_band_Hz === nothing ? nothing : float(crossover_band_Hz)
    ρ0f, c0f = float(ρ0), float(c0)
    ρe = float(something(ρ_ext, ρ0f))
    ce = float(something(c_ext, c0f))
    ρi = float(something(ρ_int, ρ0f))
    ci = float(something(c_int, c0f))
    Lc = float(something(L_c, fuse.L))
    bands_n, ηr_n, ηn_n = normalize_band_card_inputs(bands, η_r_band, η_n_band)
    return PainInputs(fuse, prop, structural, acoustic, amplitudes, phases, pts, float(ΔA),
                      sidewall, endplates, mech, m, float(η_n_bare), float(C_struc),
                      q_max === nothing ? nothing : Int(q_max), allow_extrapolation, ρ0f, c0f,
                      ρe, ce, ρi, ci, Lc, float(d), xover, bands_n, ηr_n, ηn_n,
                      η_r_band_is_prime)
end

"""Trim stacks present (sidewall and end plates)?"""
has_trim(inp::PainInputs) = inp.sidewall !== nothing

"""τ_t(ω) of Eq. (A.22) for the sidewall trim (1 for a bare cabin)."""
sidewall_tau(inp::PainInputs, ω::Real) =
    inp.sidewall === nothing ? 1.0 :
    trim_tau(inp.sidewall, ω; mech=inp.mech, allow_extrapolation=inp.allow_extrapolation)

struct InteriorSpectrum
    bpf_Hz::Float64
    harmonic_SPL_dB::Vector{Float64}   # H = 1..n (production; depends on tone_model)
    third_octave_SPL_dB::Dict{Float64,Float64}
    notes::String
    # Phase 38b: both formulations always reported (Manual output 9(2)).
    harmonic_SPL_eq8_dB::Vector{Float64}
    harmonic_SPL_eq15_dB::Vector{Float64}
    crossover_Hz::Float64
    tone_model::Symbol
end

function InteriorSpectrum(bpf_Hz::Real, harmonic_SPL_dB::Vector{Float64},
                          third_octave_SPL_dB::Dict{Float64,Float64}, notes::AbstractString;
                          harmonic_SPL_eq8_dB::Vector{Float64}=copy(harmonic_SPL_dB),
                          harmonic_SPL_eq15_dB::Vector{Float64}=copy(harmonic_SPL_dB),
                          crossover_Hz::Real=NaN, tone_model::Symbol=:eq8)
    return InteriorSpectrum(float(bpf_Hz), harmonic_SPL_dB, third_octave_SPL_dB, String(notes),
                            harmonic_SPL_eq8_dB, harmonic_SPL_eq15_dB, float(crossover_Hz), tone_model)
end

"""
Axial factor f_qM of CR-3813 Eq. (57), generalized for cavity ≠ structure (Manual card 9).

When L = L_c and d = 0 (printed case): f_qM = (1/L)∫₀ᴸ cos(qπz/L) sin(Mπz/L) dz.

Otherwise (Methodology §3.5: L ≠ L_c → Ref. [3]; Manual: d = structure start from cavity start):
acoustic shape cos(qπ(z−d)/L_c) on the cavity interval [d, d+L_c], structural sin(Mπz/L) on [0, L],
integral over the overlap, normalized by structure length L:

    f_qM = (1/L) ∫_{overlap} cos(q π (z−d)/L_c) sin(M π z/L) dz,
    overlap = [d, d+L_c] ∩ [0, L].

Closed form; the L = L_c, d = 0 branch is the printed Eq. (57) (bitwise same as pre-38f-1).
"""
function axial_coupling(q::Int, M::Int; L::Real=1.0, L_c::Real=L, d::Real=0.0)
    Lf, Lcf, df = float(L), float(L_c), float(d)
    if abs(Lf - Lcf) ≤ 1e-15 * max(Lf, 1.0) && abs(df) ≤ 1e-15 * max(Lf, 1.0)
        M == q && return 0.0
        # M = q already returned; M − q ≠ 0. M = 0 against q > 0: second term uses M − q.
        return (1 / (2π)) * ((1 - cos((M + q) * π)) / (M + q) + (1 - cos((M - q) * π)) / (M - q))
    end
    z0 = max(0.0, df)
    z1 = min(Lf, df + Lcf)
    z1 ≤ z0 && return 0.0
    return _axial_overlap_integral(q, M, Lf, Lcf, df, z0, z1) / Lf
end

"""∫_{z0}^{z1} cos(qπ(z−d)/L_c) sin(Mπz/L) dz (indefinite closed form)."""
function _axial_overlap_integral(q::Int, M::Int, L::Float64, L_c::Float64, d::Float64,
                                 z0::Float64, z1::Float64)
    α = q * π / L_c
    β = M * π / L
    # cos(α(z−d)) = cos(αz)cos(αd) + sin(αz)sin(αd)
    cφ, sφ = cos(α * d), sin(α * d)
    return cφ * _int_cos_sin(α, β, z0, z1) + sφ * _int_sin_sin(α, β, z0, z1)
end

function _int_cos_sin(a::Float64, b::Float64, z0::Float64, z1::Float64)
    # ∫ cos(az) sin(bz) dz
    if abs(b) < 1e-15 && abs(a) < 1e-15
        return 0.0
    elseif abs(a) < 1e-15
        return (-cos(b * z1) + cos(b * z0)) / b
    elseif abs(b) < 1e-15
        return 0.0
    elseif abs(a - b) < 1e-14 * max(abs(a), abs(b), 1.0)
        # ∫ cos(az) sin(az) = ∫ sin(2az)/2
        return abs(a) < 1e-15 ? 0.0 : (-cos(2a * z1) + cos(2a * z0)) / (4a)
    elseif abs(a + b) < 1e-14 * max(abs(a), abs(b), 1.0)
        # ∫ cos(az) sin(−az) = −∫ cos sin = +cos(2az)/(4a) with b = −a
        return abs(a) < 1e-15 ? 0.0 : (cos(2a * z1) - cos(2a * z0)) / (4a)
    end
    sp, sm = a + b, b - a
    return 0.5 * ((-cos(sp * z1) + cos(sp * z0)) / sp + (-cos(sm * z1) + cos(sm * z0)) / sm)
end

function _int_sin_sin(a::Float64, b::Float64, z0::Float64, z1::Float64)
    # ∫ sin(az) sin(bz) dz = ∫ [cos((a−b)z) − cos((a+b)z)] / 2
    if abs(a) < 1e-15 && abs(b) < 1e-15
        return 0.0
    elseif abs(a) < 1e-15 || abs(b) < 1e-15
        return 0.0
    elseif abs(a - b) < 1e-14 * max(abs(a), abs(b), 1.0)
        # ∫ sin²(az) = ∫ (1 − cos(2az))/2
        return (z1 - z0) / 2 - (sin(2a * z1) - sin(2a * z0)) / (4a)
    elseif abs(a + b) < 1e-14 * max(abs(a), abs(b), 1.0)
        # ∫ sin(az) sin(−az) = −∫ sin²(az)
        return -((z1 - z0) / 2 - (sin(2a * z1) - sin(2a * z0)) / (4a))
    end
    dm, dp = a - b, a + b
    return 0.5 * ((sin(dm * z1) - sin(dm * z0)) / dm - (sin(dp * z1) - sin(dp * z0)) / dp)
end

"""
Shell integral ∫_{θ0}^{2π−θ0} a ψ_s^r(θ) φ_i(θ) dθ of Eq. (52), evaluated with the
piecewise-constant boundary values of Eq. (53) (both symmetric) and Eq. (54) (both
antisymmetric). Zero when one mode is symmetric and the other antisymmetric.
"""
function coupling_shell_integral(ac::AcousticMode, st::StructuralMode, a::Real)
    ac.symmetric == st.symmetric || return 0.0
    lo, hi = ac.theta_lo_rad, ac.theta_hi_rad
    φ = ac.phi_boundary
    acc = 0.0
    for (C, n) in zip(st.C_shell, st.n_shell)
        c = C * (-1)^n
        for j in eachindex(φ)
            if st.symmetric
                acc += n == 0 ? c * φ[j] * (hi[j] - lo[j]) * a :
                                c * φ[j] * (a / n) * (sin(n * hi[j]) - sin(n * lo[j]))
            else
                n == 0 && continue   # antisymmetric sum starts at n = 1 (Eq. 47)
                acc += c * φ[j] * (a / n) * (cos(n * hi[j]) - cos(n * lo[j]))
            end
        end
    end
    return acc
end

"""
Floor integral ∫_{−Lp/2}^{Lp/2} ψ_p^r(x) φ_i(x) dx of Eq. (52), with the
piecewise-constant boundary values of Eq. (55) (symmetric) and Eq. (56)
(antisymmetric). Zero when the symmetries differ.
"""
function coupling_floor_integral(ac::AcousticMode, st::StructuralMode, a::Real, Lp::Real)
    ac.symmetric == st.symmetric || return 0.0
    lo, hi = a .* ac.x_lo_unit, a .* ac.x_hi_unit
    φ = ac.phi_floor
    acc = 0.0
    for (C, n) in zip(st.C_floor, st.n_floor)
        for j in eachindex(φ)
            if st.symmetric
                acc += n == 0 ? C * φ[j] * (hi[j] - lo[j]) :
                                (Lp / π) * C * φ[j] * (1 / n) * (sin(n * π * hi[j] / Lp) - sin(n * π * lo[j] / Lp))
            else
                n == 0 && continue
                acc += (Lp / π) * C * φ[j] * (1 / n) * (cos(n * π * lo[j] / Lp) - cos(n * π * hi[j] / Lp))
            end
        end
    end
    return acc
end

"""
Coupling factor f̄'(n,r), CR-3813 Eq. (52) with Eqs. (46)–(49), (53)–(57):

    f̄' = f_qM / (Lp + 2a(π−θ0)) · [ √τ_t ∫ a ψ_s φ dθ − ∫ ψ_p φ dx ]

`τ_t` is the sidewall trim transmission coefficient at the harmonic (τ_t = 1 bare,
which gives f' of Eq. 45). Cabin modes are the q = 0 modes of CYL2D. The bound
|f'| ≤ 1 (CR-3813 §3.1) follows from the max-normalized modes; no clamp is applied
and a violation raises an error, because it means a mode normalization or mode-shape
defect that must be fixed, not hidden.
"""
function coupling_factor(ac::AcousticMode, st::StructuralMode,
                         fuse::FuselageGeometry; τ_t::Float64=1.0, q::Int=0,
                         L_c::Real=fuse.L, d::Real=0.0)
    a = fuse.a
    θ0 = deg2rad(fuse.theta0_deg)
    Lp = 2a * sin(θ0)
    Is = coupling_shell_integral(ac, st, a)
    Ip = coupling_floor_integral(ac, st, a, Lp)
    f = axial_coupling(q, st.M_axial; L=fuse.L, L_c, d) *
        (sqrt(τ_t) * Is - Ip) / (Lp + 2a * (π - θ0))
    abs(f) <= 1 + 1e-6 ||
        error("f'(n,r) = $f exceeds 1 for acoustic mode $(ac.index), structural mode $(st.index): mode normalization or shape defect")
    return f
end

coupling_factor(ac::AcousticMode, st::StructuralMode, inp::PainInputs; τ_t::Float64=1.0, q::Int=0) =
    coupling_factor(ac, st, inp.fuse; τ_t, q, L_c=inp.L_c, d=inp.d)

"""Sums S_c = Σ A cos φ ψ^r(x_m), S_s = Σ A sin φ ψ^r(x_m) of Eq. (42), over the whole grid.

Blade-passage phase sense (Manual card 36) is applied when the free-field grid is built
(`grid_points` azimuth and phase sign); Eq. (42) uses the stored φ_H as given.
"""
function generalized_force_sums(st::StructuralMode, H::Int,
                                amps::Array{Float64,3}, phases::Array{Float64,3},
                                pts, fuse::FuselageGeometry)
    sc = 0.0
    ss = 0.0
    for p in pts
        A = amps[p.k, p.ell, H]
        ϕ = phases[p.k, p.ell, H]
        ψ = structural_shell_psi(st, p.z, p.theta_deg, fuse.L)
        sc += A * cos(ϕ) * ψ
        ss += A * sin(ϕ) * ψ
    end
    return sc, ss
end

"""
    generalized_force(st, H, amps, phases, pts, fuse; ΔA) -> Ψ_G(r, H)

CR-3813 Eq. (42): Ψ_G = (Δ⁴/2)[(Σ A ψ cos φ)² + (Σ A ψ sin φ)²], Δ⁴ = ΔA². Units Pa² m⁴ for A in Pa
and ψ dimensionless. (Before phase 17a this function returned the amplitude Δ²|Σ A e^{iφ} ψ|,
which is √(2Ψ_G); that quantity is `generalized_force_amplitude`.)
"""
function generalized_force(st::StructuralMode, H::Int,
                           amps::Array{Float64,3}, phases::Array{Float64,3},
                           pts, fuse::FuselageGeometry; ΔA::Float64)
    sc, ss = generalized_force_sums(st, H, amps, phases, pts, fuse)
    return ΔA^2 / 2 * (sc^2 + ss^2)
end

"""|Δ² Σ A e^{iφ} ψ| = √(2 Ψ_G) (the force amplitude on the mode)."""
function generalized_force_amplitude(st::StructuralMode, H::Int,
                                     amps::Array{Float64,3}, phases::Array{Float64,3},
                                     pts, fuse::FuselageGeometry; ΔA::Float64)
    sc, ss = generalized_force_sums(st, H, amps, phases, pts, fuse)
    return ΔA * hypot(sc, ss)
end

"""
Joint acceptance j_r² surrogate for tonal cospectrum (CR-3813 §3.5–3.6).
Normalized |Ψ_G|² / (⟨A²⟩ Area²); used as a 0–1 weight when requested.
Default tone sum uses Ψ_G directly (discrete Eq. 42) without re-multiplying j_r².
"""
function joint_acceptance(Ψ::Float64, amps::Array{Float64,3}, H::Int, ΔA::Float64)
    p2 = 0.0
    n = 0
    for k in axes(amps, 1), ℓ in axes(amps, 2)
        A = amps[k, ℓ, H]
        p2 += A * A
        n += 1
    end
    p2 = p2 / max(n, 1)
    area = n * ΔA
    j2 = (Ψ^2) / (max(p2, 1e-30) * max(area, 1e-12)^2)
    return clamp(j2, 0.0, 1.0)
end

"""
    tone_mean_square_pressure(inp, H, ωH; q_max=nothing) -> ⟨p²⟩_H [Pa²]

Space-average interior mean-square pressure of harmonic H, CR-3813 Eq. (8) summed over the cabin modes by Eq. (3):

    ⟨p²⟩_H = Σ_n (4c0²/V²)(mA/4)²τ_ML ω_H⁶ ε_n/ω_n⁴ Σ_r f̄'²Ψ_G/(M_r²ω_r⁴)
             / {[(1 − ω_H²/ω_n²)² + η_n²][(1 − ω_H²/ω_r²)² + (η_r' + η_r'')²]}

with (mA/4)²τ_ML = (ρ0 c0 A/(2ω_H))² (A the transmitting area, `L(Lp + 2a(π − θ0))`), Ψ_G of Eq. (42)
(including Δ⁴/2), and τ_t only inside f̄' (Eq. 52, √τ_t on the shell term; CR-3813 note under Eq. 7). The two
resonance denominators are multiplied out so that the rigid-body cabin mode (ω_n = 0, i = 0) is the finite limit
ε_n ω_H⁶ / [(ω_n² − ω_H²)² + N²] with N = η_n ω_n², Eq. (77) in its ω_n-free form. η_n: Eq. (77) with ξ, ξ_e from the trim
at ω_H (`η_n_bare` ω_n² when there is no trim); η_r' from Eqs. (79)–(82) at ω_r; η_r'' from Eq. (83) for every (n, r)
pair (register item i). Cabin modes are n = (q, i), q = 0…q_max (V-ASSUMED truncation).
"""
function tone_mean_square_pressure(inp::PainInputs, H::Int, ωH::Float64;
                                    q_max::Union{Nothing,Int}=nothing,
                                    η_r_cap::Union{Nothing,Float64}=nothing)
    fuse = inp.fuse
    a, L = fuse.a, fuse.L
    L_c = inp.L_c
    θ0 = deg2rad(fuse.theta0_deg)
    Lp = 2a * sin(θ0)
    A = L * (Lp + 2a * (π - θ0))   # transmitting structure area (length L)
    V = cabin_volume(inp)          # cavity volume ∝ L_c
    # Card 2 map: mass-law exterior; 4c²/V² and cabin modes / η_n / η_r'' interior
    ρ_ext, c_ext = inp.ρ_ext, inp.c_ext
    ρ_int, c_int = inp.ρ_int, inp.c_int
    ext = inp.allow_extrapolation
    qtop = something(q_max, inp.q_max, axial_truncation(ωH, L_c, c_int))

    trimmed = has_trim(inp)
    τ_t = sidewall_tau(inp, ωH)
    ξ = trimmed ? trim_conductance(inp.sidewall, ωH, inp.m_wall; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0
    ξe = trimmed ? trim_conductance(inp.endplates, ωH, Inf; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0

    # per structural mode: Ψ_G, ω_r, η_r' (radiation uses exterior air; card 11–14 η_r override)
    nst = length(inp.structural.modes)
    Ψ = Vector{Float64}(undef, nst)
    ωr = Vector{Float64}(undef, nst)
    ηrp = Vector{Float64}(undef, nst)
    for (j, st) in enumerate(inp.structural.modes)
        Ψ[j] = generalized_force(st, H, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA)
        ωr[j] = 2π * st.f_Hz
        ηrp[j] = structural_η_r_prime(inp, st, ωr[j]; η_r_cap)
    end

    # (c_int/V)² · (ρ_ext c_ext A)² ω_H⁴  ≡  4 c_int²/V² · (ρ_ext c_ext A/(2ω_H))² · ω_H⁶ / ω_H² …
    pref = (c_int / V)^2 * (ρ_ext * c_ext * A)^2 * ωH^4
    fH = ωH / 2π
    p2 = 0.0
    for q in 0:qtop, ac in inp.acoustic.modes
        ωn = 2π * cabin_frequency_3d(ac, a, L_c, q; c0=c_int)
        εn = cabin_eps_3d(ac, q)
        N = acoustic_N(inp, ac, q, fH, ωn; ξ, ξ_e=ξe, V)
        Dn = (ωn^2 - ωH^2)^2 + N^2
        for (j, st) in enumerate(inp.structural.modes)
            f = coupling_factor(ac, st, inp; τ_t, q)
            f == 0 && continue
            ηrpp = structural_loss_coupled(N, ωn, ωr[j], f, εn, st.M_r, V, A; ρ0=ρ_int, c0=c_int)
            Dr = (ωr[j]^2 - ωH^2)^2 + ((ηrp[j] + ηrpp) * ωr[j]^2)^2
            p2 += pref * εn * f^2 * Ψ[j] / (st.M_r^2 * Dn * Dr)
        end
    end
    return p2
end

"""
Cabin (cavity) volume. CR-3813 App. C: V = a² L_c (π − θ₀ + cosθ₀ sinθ₀).
`L_c` defaults to the structure length `fuse.L` (card 9 default L_c = L).
"""
function cabin_volume(fuse::FuselageGeometry; L_c::Real=fuse.L)
    θ0 = deg2rad(fuse.theta0_deg)
    a = fuse.a
    return a^2 * float(L_c) * (π - θ0 + cos(θ0) * sin(θ0))
end

cabin_volume(inp::PainInputs) = cabin_volume(inp.fuse; L_c=inp.L_c)

"""
Apply Manual card 36 rotation sense to a free-field phase array built for +1 (Fig. 3).
Negates every φ_H (blade-passage phase). Azimuth of `pts` must already match
`prop.rotation_direction` via `grid_points`. No-op when direction is +1.
"""
function apply_rotation_direction_phases!(phases::AbstractArray{<:Real}, rotation_direction::Integer)
    abs(Int(rotation_direction)) == 1 ||
        error("rotation_direction must be ±1, got $rotation_direction")
    if Int(rotation_direction) == -1
        phases .*= -1
    end
    return phases
end

"""
Band-limited blocked mean-square pressure ⟨p²⟩_bl for a 1/3-oct band.

Uses spatial-mean |A|² of the highest available tone as an anchor at H·BPF,
then a power-law continuum Spbl(f)∝f^{-α} (CR-3813 HF notes: broadband fills
above the first few BPFs). **V-ASSUMED** slope until closed vs exterior spectra.

Anchor density: Spbl_a = ⟨|A|²⟩ / (c_ω·2π·f_anchor) with c_ω = 0.232 (CR-3813
p. 10; same constant as `C_OMEGA_THIRD_OCTAVE`). Band integral (code-on-code
fix 2026-10-23, Phase 40i): ∫_{f1}^{f2} Spbl_a (f_anchor/f)^α · 2π df with
exact 1/3-octave edges f1 = fc·2^{-1/6}, f2 = fc·2^{1/6} (closed form; α = 1
uses the log branch). Replaces the prior Spbl(fc)·c_ω·2π·fc rectangle.
"""
function blocked_broadband_band_p2(inp::PainInputs, fc::Float64, bpf_Hz::Float64;
                                   α::Float64=2.0, spbl_anchor_H::Int=3)
    nH = size(inp.amplitudes, 3)
    nH < 1 && return 0.0
    H_anchor = min(nH, max(1, spbl_anchor_H))
    f_anchor = H_anchor * bpf_Hz
    # Spatial mean of blocked tone amplitude²
    A = inp.amplitudes[:, :, H_anchor]
    p2_tone = sum(abs2, A) / length(A)
    # Spread tone power into continuum density; one-third-oct Δω/ω = 0.232 (anchor only)
    cw = 0.232
    Δω_a = cw * 2π * f_anchor
    Spbl_a = p2_tone / max(Δω_a, 1e-12)   # (Pa²)/ (rad/s)
    f1 = fc * 2.0^(-1 / 6)
    f2 = fc * 2.0^(1 / 6)
    if abs(α - 1.0) < 1e-14
        return Spbl_a * f_anchor * 2π * log(f2 / f1)
    end
    return Spbl_a * f_anchor^α * 2π * (f2^(1 - α) - f1^(1 - α)) / (1 - α)
end

"""
Structural modal density n(ω) [modes / (rad/s)] from retained MRP modes
in a one-third-octave band about fc (Eq. 19 architecture).
"""
function structural_modal_density(modes::StructuralModes, fc::Float64)
    # Third-octave: Δf/f ≈ 0.2316 → Δω = 2π Δf
    df = 0.2316 * fc
    lo, hi = fc - df / 2, fc + df / 2
    n_modes = count(m -> lo ≤ m.f_Hz ≤ hi, modes.modes)
    # Below first resonance / sparse bands: use asymptotic plate+shell estimate
    if n_modes < 1
        a, L = modes.a, modes.L
        # Asymptotic cylinder+floor modal density (order-of-magnitude, modes/Hz)
        n_Hz = 0.015 * (a * L) * (fc / 500)   # rises slowly
        return n_Hz / (2π)
    end
    Δω = 2π * max(df, 1.0)
    return n_modes / Δω
end

"""
Average joint acceptance ⟨j²⟩_rev in band — discrete Eq.42 / §3.6 surrogate
from blocked grid and structural mode shapes resonant near fc.
"""
function band_joint_acceptance(inp::PainInputs, fc::Float64; H_anchor::Int=3)
    H = clamp(H_anchor, 1, size(inp.amplitudes, 3))
    df = 0.2316 * fc
    lo, hi = fc - df / 2, fc + df / 2
    js = Float64[]
    for st in inp.structural.modes
        (lo ≤ st.f_Hz ≤ hi) || continue
        Ψ = generalized_force_amplitude(st, H, inp.amplitudes, inp.phases, inp.pts, inp.fuse; ΔA=inp.ΔA)
        push!(js, joint_acceptance(Ψ, inp.amplitudes, H, inp.ΔA))
    end
    isempty(js) && return 2.5e-4   # diffuse-band fallback (educated, below unity)
    return clamp(sum(js) / length(js), 1e-6, 1.0)
end

"""
High-frequency cabin ⟨p²⟩ — CR-3813 Eq. (19)→(23) with trim.

All-trim form (A'=0):
  ⟨p²⟩_e = [4 τ_t A_fc / (α S)] ⟨p²⟩_bl ⟨j²⟩_rev ⋅ χ(nω)

τ_t is Eq. (A.22) at the band centre (CR-3813: it applies to Eqs. 16, 18 and 23). The rest of this path
(α(f) curve, χ, `j2_scale`, the H = 3 anchor) is still a surrogate, replaced in phase 29b.

⟨j²⟩_rev from blocked-grid joint acceptance of modes resonant in the band.
χ(nω) = n(ω)/n_ref raises response with structural modal density (Eq.19 sum).
`j2_scale` absorbs Spbl-anchor overcount (H=3 tone → continuum); default
fitted so Fig. E-9 1.25–2 kHz stay within ±3.5 dB.
"""
function broadband_cabin_p2(inp::PainInputs, fc::Float64, p2_bl::Float64;
                            j2_scale::Float64=1.0)
    p2_bl ≤ 0 && return 0.0
    a, L = inp.fuse.a, inp.fuse.L
    A_fc = π * a * L
    S = 2π * a * L + 2π * a^2          # sidewall + two ends
    ω = 2π * fc
    τ_t = sidewall_tau(inp, ω)
    α = max(absorption_coefficient(fc), 1e-3)
    j2 = band_joint_acceptance(inp, fc)
    nω = structural_modal_density(inp.structural, fc)
    # Reference modal density ~ a few modes per 1/3-oct near 1.5 kHz
    n_ref = 3.0 / (2π * 0.2316 * 1500)  # ~ modes/(rad/s)
    χ = clamp(nω / max(n_ref, 1e-12), 0.25, 4.0)
    # Spbl from H=3 tone overcounts continuum → j2_scale ~ O(0.1–1)
    return p2_bl * (4 * τ_t * A_fc / max(α * S, 1e-9)) * j2 * χ * j2_scale
end

"""
    interior_spl(inp; bpf_Hz, n_harmonics=10, broadband=true, tone_model=:eq8,
                 broadband_model=:surrogate) -> InteriorSpectrum

Tonal SPL for propeller harmonics, plus HF broadband into 1/3-oct (T2).

`tone_model`: `:eq8` (default — unchanged production), `:eq15_16` (high-frequency
expected value only), or `:auto` (Eq. 8 below the crossover band, Eqs. 15–16 at and
above; Manual output 9(3)). Both formulations are always stored on the spectrum.

`broadband_model`: `:surrogate` (default — existing `broadband_cabin_p2` with
`bb_j2_scale`; outputs unchanged) or `:eq19` (printed Eqs. 19–23; no j² scale).
"""
function interior_spl(inp::PainInputs; bpf_Hz::Float64, n_harmonics::Int=10,
                      broadband::Bool=true, bb_α::Float64=2.0, bb_j2_scale::Float64=0.5,
                      spbl_anchor_H::Int=3,
                      tone_model::Symbol=:eq8,
                      broadband_model::Symbol=:surrogate,
                      η_r_cap::Union{Nothing,Float64}=nothing)
    broadband_model in (:surrogate, :eq19) ||
        error("broadband_model must be :surrogate or :eq19 (got $broadband_model)")
    nH = min(n_harmonics, size(inp.amplitudes, 3))
    spl = zeros(Float64, nH)
    spl8 = zeros(Float64, nH)
    spl15 = zeros(Float64, nH)
    pref = 20e-6
    xover = resolve_crossover_Hz(inp)
    for H in 1:nH
        ωH = 2π * H * bpf_Hz
        pair = tone_mean_square_pressure_pair(inp, H, ωH; tone_model, crossover_Hz=xover, η_r_cap)
        spl[H] = 10 * log10(pair.p2 / pref^2 + 1e-30)
        spl8[H] = 10 * log10(pair.p2_eq8 / pref^2 + 1e-30)
        spl15[H] = 10 * log10(pair.p2_eq15_16 / pref^2 + 1e-30)
    end
    bands = resolve_bands(inp)
    band_p2 = Dict{Float64,Float64}(b => 0.0 for b in bands)
    for H in 1:nH
        f = H * bpf_Hz
        b = nearest_third_octave(f, bands)
        band_p2[b] += pref^2 * 10^(spl[H] / 10)
    end
    notes = "PAIN tones (CR-3813 §3.2); tone_model=$tone_model; crossover=$(round(xover; digits=1)) Hz; both Eq.(8) and Eq.(15)–(16) reported"
    if broadband
        f_last = nH * bpf_Hz
        for b in bands
            b < 1000 && continue
            b ≤ f_last * 1.15 && continue
            if has_trim(inp) && !inp.allow_extrapolation && stack_extrapolated(inp.sidewall, b)
                delete!(band_p2, b)   # outside the Fig. A-2 range and no extrapolation allowed: no value
                continue
            end
            p2_bl = blocked_broadband_band_p2(inp, b, bpf_Hz; α=bb_α, spbl_anchor_H=spbl_anchor_H)
            p2_i = if broadband_model === :eq19
                hf_broadband_band_p2(inp, b, p2_bl; η_r_cap)
            else
                broadband_cabin_p2(inp, b, p2_bl; j2_scale=bb_j2_scale)
            end
            band_p2[b] += p2_i
        end
        if broadband_model === :eq19
            notes *= " + HF Eqs.(19)–(23) as printed (ᾱ from Eq.24/78; Spbl∝f^{-$(bb_α)}; phase 38c)."
        else
            notes *= " + HF Eq.19 modal-density with τ_t of Eq. (A.22) (surrogate α_abs, Spbl∝f^{-$(bb_α)}; phase 29b)."
        end
        has_trim(inp) && !inp.allow_extrapolation &&
            (notes *= " Bands above the Fig. A-2 range omitted (allow_extrapolation=false).")
    else
        notes *= " tonal-only (no HF broadband)."
    end
    band_spl = Dict(b => 10 * log10(p2 / pref^2 + 1e-30) for (b, p2) in band_p2)
    return InteriorSpectrum(bpf_Hz, spl, band_spl, notes;
                            harmonic_SPL_eq8_dB=spl8, harmonic_SPL_eq15_dB=spl15,
                            crossover_Hz=xover, tone_model=tone_model)
end

# ---------------------------------------------------------------------------------------------
# Manual cards 3–6 / 11–18 (38f-2): band set + per-band loss-factor overrides
# ---------------------------------------------------------------------------------------------

"""One-third-octave relative bandwidth c_ω (CR-3813 p. 10). Defined here so card 3–6 helpers
can use it; `noise_reduction.jl` reuses the same constant."""
const C_OMEGA_THIRD_OCTAVE = 0.232

"""Default production 1/3-octave centres: 63 Hz … 8 kHz (geometric, f₀ = 1000 Hz)."""
function third_octave_centers()
    f0 = 1000.0
    ks = -12:9
    return [f0 * 2.0^(k / 3) for k in ks]
end

"""Master list of standard geometric 1/3-octave centres used to validate card 3–6 inputs."""
function standard_third_octave_centers(; k_min::Int=-20, k_max::Int=16)
    return [1000.0 * 2.0^(k / 3) for k in k_min:k_max]
end

function nearest_third_octave(f::Real, bands::Vector{Float64})
    bands[argmin(abs.(bands .- float(f)))]
end

"""1/3-octave band edges about centre `fc` [Hz] using CR-3813 c_ω (relative half-width c_ω/2)."""
function third_octave_band_edges(fc::Real; c_ω::Real=C_OMEGA_THIRD_OCTAVE)
    f = float(fc)
    return (lo=f * (1 - c_ω / 2), hi=f * (1 + c_ω / 2))
end

"""
Snap `f` to the nearest standard geometric 1/3-octave centre, or `nothing` if not standard
(relative mismatch > 2 %).
"""
function snap_third_octave_center(f::Real; rtol::Float64=0.02)
    std = standard_third_octave_centers()
    i = argmin(abs.(std .- float(f)))
    c = std[i]
    return abs(c - float(f)) ≤ rtol * max(c, float(f), 1.0) ? c : nothing
end

"""
Validate and normalize a user band set (Manual cards 3–6): ≤ 26 centres, each a standard
1/3-octave centre, strictly ascending. Returns snapped geometric centres.
"""
function validate_band_set(bands::AbstractVector{<:Real})
    isempty(bands) && error("bands: empty set (Manual cards 3–6 require NI ≥ 1)")
    length(bands) > 26 && error("bands: NI=$(length(bands)) exceeds Manual maximum of 26")
    out = Float64[]
    prev = -Inf
    for (i, raw) in enumerate(bands)
        c = snap_third_octave_center(raw)
        c === nothing && error("bands: entry $i ($(raw) Hz) is not a standard 1/3-octave centre")
        c ≤ prev && error("bands: must be strictly ascending (got $(prev) then $(c) Hz at entry $i)")
        push!(out, c)
        prev = c
    end
    return out
end

"""Active band list for an inputs object (`nothing` → production default)."""
resolve_bands(inp::PainInputs) = inp.bands === nothing ? third_octave_centers() : inp.bands

"""
Band centre among `bands` whose 1/3-octave edges contain `f_Hz`, or `nothing` if none.
Manual lookup for a tone/mode frequency that is not itself a centre (edges via c_ω).
"""
function containing_third_octave(f_Hz::Real, bands::AbstractVector{<:Real};
                                 c_ω::Real=C_OMEGA_THIRD_OCTAVE)
    f = float(f_Hz)
    for fc in bands
        e = third_octave_band_edges(fc; c_ω)
        (e.lo ≤ f ≤ e.hi) && return float(fc)
    end
    return nothing
end

"""
Normalize cards 3–6 / 11–18 kwargs → (`bands`, `η_r_band`, `η_n_band`) stored on `PainInputs`.
Vectors for η are paired with `bands` (required). Dict keys are snapped to standard centres.
Zero entries are dropped (Manual: 0 → compute).
"""
function normalize_band_card_inputs(bands, η_r_band, η_n_band)
    bands_n = bands === nothing ? nothing : validate_band_set(bands)
    ηr = _normalize_η_dict(η_r_band, bands_n; label="η_r_band")
    ηn = _normalize_η_dict(η_n_band, bands_n; label="η_n_band")
    return bands_n, ηr, ηn
end

_η_key_hz(k) = k isa Real ? float(k) : float(String(k))

function _normalize_η_dict(η, bands_n; label::AbstractString)
    η === nothing && return nothing
    if η isa AbstractDict
        d = Dict{Float64,Float64}()
        for (k, v) in η
            c = snap_third_octave_center(_η_key_hz(k))
            c === nothing && error("$label: key $(k) Hz is not a standard 1/3-octave centre")
            fv = float(v)
            (isfinite(fv) && fv != 0) || continue
            fv < 0 && error("$label: negative loss factor $fv at $(c) Hz")
            d[c] = fv
        end
        return isempty(d) ? nothing : d
    elseif η isa AbstractVector
        bands_n === nothing &&
            error("$label: vector form requires `bands` (same length, Manual cards 3–6 order)")
        length(η) == length(bands_n) ||
            error("$label: length $(length(η)) ≠ bands length $(length(bands_n))")
        d = Dict{Float64,Float64}()
        for (i, v) in enumerate(η)
            fv = float(v)
            (isfinite(fv) && fv != 0) || continue
            fv < 0 && error("$label: negative loss factor $fv at band $(bands_n[i]) Hz")
            d[bands_n[i]] = fv
        end
        return isempty(d) ? nothing : d
    else
        error("$label: expected nothing, Dict, or Vector (got $(typeof(η)))")
    end
end

"""
Per-band override at frequency `f_Hz`: containing-band lookup; 0/absent → `nothing` (compute).
"""
function loss_factor_override(η_dict::Union{Nothing,Dict{Float64,Float64}}, f_Hz::Real,
                             bands::AbstractVector{<:Real}; c_ω::Real=C_OMEGA_THIRD_OCTAVE)
    η_dict === nothing && return nothing
    fc = containing_third_octave(f_Hz, bands; c_ω)
    fc === nothing && return nothing
    v = get(η_dict, fc, 0.0)
    return (isfinite(v) && v != 0) ? float(v) : nothing
end

loss_factor_override(inp::PainInputs, which::Symbol, f_Hz::Real; c_ω::Real=C_OMEGA_THIRD_OCTAVE) =
    loss_factor_override(which === :η_r ? inp.η_r_band : inp.η_n_band, f_Hz, resolve_bands(inp); c_ω)

"""
η_r of Eqs. (79)–(81) for mode `st`, then η_r′ (Eq. 82) when trim is present.
Card 11–14 non-zero override replaces Eqs. 79–81; trim / η_r_cap still apply.
"""
function structural_η_r_prime(inp::PainInputs, st::StructuralMode, ωr::Real;
                              η_r_cap::Union{Nothing,Float64}=nothing,
                              Abar::Union{Nothing,Real}=nothing)
    fuse = inp.fuse
    a, L = fuse.a, fuse.L
    Ab = Abar === nothing ? cylinder_surface_area(a, L) : float(Abar)
    ov = loss_factor_override(inp, :η_r, st.f_Hz)
    if ov !== nothing && inp.η_r_band_is_prime
        # Measured / card total η_r′ (phase 43b): do not re-apply Eq. (82) trim.
        return apply_η_r_cap(ov, η_r_cap)
    end
    ηr = ov !== nothing ? ov :
         structural_loss_total(st, ωr; a, L, m=inp.m_wall, C=inp.C_struc,
                               ρ0=inp.ρ_ext, c0=inp.c_ext, Abar=Ab)
    if has_trim(inp)
        return structural_loss_with_trim(ηr, ωr, inp.m_wall,
                                         trim_Cw(inp.sidewall, ωr; allow_extrapolation=inp.allow_extrapolation);
                                         η_r_cap)
    else
        return apply_η_r_cap(ηr, η_r_cap)
    end
end

"""
N = η_n ω_n² for cabin mode (ac, q) at lookup frequency `f_Hz` (tone or band centre).
Card 16–18 non-zero override replaces η_n; else trim Eq. (77) or `η_n_bare`.
"""
function acoustic_N(inp::PainInputs, ac, q::Integer, f_Hz::Real, ωn::Real;
                    ξ::Real=0.0, ξ_e::Real=0.0, V::Union{Nothing,Real}=nothing)
    ov = loss_factor_override(inp, :η_n, f_Hz)
    if ov !== nothing
        return ov * ωn^2
    end
    if has_trim(inp)
        Vol = V === nothing ? cabin_volume(inp) : float(V)
        return acoustic_loss_modal(ac, q, 2π * f_Hz, ωn; a=inp.fuse.a, L=inp.L_c, V=Vol,
                                   c0=inp.c_int, ξ, ξ_e).N
    else
        return inp.η_n_bare * ωn^2
    end
end

"""Band-average η_n at centre `fc` [Hz]: card override or trim / bare as before."""
function resolve_η_n_band(inp::PainInputs, fc::Real; ξ::Real=0.0, ξ_e::Real=0.0,
                          V::Real, S::Real, S_e::Real)
    ov = loss_factor_override(inp, :η_n, fc)
    ov !== nothing && return ov
    if has_trim(inp)
        return acoustic_loss_average(2π * fc; V, S, S_e, ξ, ξ_e, c0=inp.c_int)
    else
        return inp.η_n_bare
    end
end
