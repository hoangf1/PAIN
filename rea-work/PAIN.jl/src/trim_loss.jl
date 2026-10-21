"""
Trim transfer + loss factors (CR-3813 App. A / §3.8 / Figs. E-13–E-15).

App. E Phase-III stack (methodology E-8):
  - Fiberglass 9.61 kg/m³, 4×1.3 cm on curved wall (5.1 cm), vinyl face 0.22 kg/m²/layer
  - Septum: NEMA G-10 0.079 cm floor-to-floor + vinyl over upper 120°; total septum ≈6.58 kg
  - Hard-mounted to floor, soft-mounted to frames

The PAIN core uses the App. A transfer-matrix functions below the surrogate marker (phase 16, called from phase 17a).
The tuned surrogates `TrimPanel`, `trim_T_fc`, `acoustic_loss_factor` and `structural_loss_factor` were removed in 17a.
`absorption_coefficient` stays as the surrogate of the high-frequency path until 29b.
"""

"""
Band-average absorption α(f) — Fig. E-13 / Sabine architecture for trim cabin.

Educated fit to App. E fiberglass+trim: rises through mid-band, saturates ~0.4–0.6.
Used by Eq. (19)/(24) HF path and η_a = α c S / (4 ω V) high-frequency limit.
"""
function absorption_coefficient(f_Hz::Real)
    f = max(float(f_Hz), 50.0)
    # Smooth rise: ~0.08 @ 200 Hz → ~0.35 @ 1 kHz → ~0.55 @ 2–4 kHz
    x = log10(f / 200)
    α = 0.08 + 0.28 * (1 - exp(-1.2 * max(x, 0))) + 0.12 * (1 - exp(-0.4 * max(x - 0.7, 0)))
    return clamp(α, 0.02, 0.65)
end

# =====================================================================================
# CR-3813 App. A trim transfer matrices and §3.8 loss factors (plan phase 16).
#
# Everything below is written from the printed equations and has no fitted parameter (the
# earlier tuned surrogates were removed in phase 17a). Time convention e^{-iωt} (v = −iωw, Eq. A.9 → A.10).
# =====================================================================================

const _TRIM_DATA_DIR = normpath(joinpath(@__DIR__, "..", "..", "data"))
const NP_PER_DB = log(10) / 20            # 1 dB = 0.11513 Np
"""Sign of the phase of the wave impedance, W = |W| exp(i·W_PHASE_SIGN·φ) (assumption; checked by passivity of Re β in the tests)."""
const W_PHASE_SIGN = 1

# --- Fig. A-2 insulation data ----------------------------------------------------------------

"""
Acoustical properties of one insulation material per frequency (Fig. A-2 form): wavelength λ_m,
attenuation α, phase φ and magnitude |W| of the wave impedance.
"""
struct InsulationTable
    name::String
    density::Float64            # kg/m³
    f_Hz::Vector{Float64}
    lambda_m::Vector{Float64}
    alpha_dB_per_m::Vector{Float64}
    phi_deg::Vector{Float64}
    W_rayl::Vector{Float64}
    source::String
end

function load_insulation_table(path::AbstractString; name::String="PF-105", density::Float64=9.6)
    c = _read_csv_numeric(path)
    f = c[:f_Hz]
    issorted(f) || error("insulation table $path: f_Hz must be increasing")
    return InsulationTable(name, density, f, c[:lambda_m], c[:alpha_dB_per_m], c[:phi_deg], c[:W_rayl], String(path))
end

"""Fig. A-2 (Owens-Corning PF-105, 9.6 kg/m³), digitized at its six marked frequencies, 100–6300 Hz (`data/fig_a2_pf105.csv`)."""
pf105_table() = load_insulation_table(joinpath(_TRIM_DATA_DIR, "fig_a2_pf105.csv"))

function _interp_logf(f::Float64, fs::Vector{Float64}, ys::AbstractVector{Float64})
    x = log10(f)
    xs = log10.(fs)
    i = clamp(searchsortedlast(xs, x), 1, length(xs) - 1)
    t = (x - xs[i]) / (xs[i+1] - xs[i])
    return (1 - t) * ys[i] + t * ys[i+1]       # t outside [0, 1] extends the end segment
end

"""
    insulation_properties(table, f_Hz; allow_extrapolation=false)
        -> (lambda_m, alpha_Np_per_m, phi_rad, W_abs, extrapolated)

Linear interpolation in log f of log λ, log α, log |W| and φ. Outside the digitized range
an error unless `allow_extrapolation`; the end segment is then continued in the same variables and
`extrapolated = true` (the result is X-EXTRAP and must be carried as such).
"""
function insulation_properties(t::InsulationTable, f_Hz::Real; allow_extrapolation::Bool=false)
    f = float(f_Hz)
    f > 0 || error("insulation_properties: f must be positive")
    out = f < first(t.f_Hz) || f > last(t.f_Hz)
    out && !allow_extrapolation &&
        error("insulation table $(t.name) covers $(first(t.f_Hz))–$(last(t.f_Hz)) Hz (Fig. A-2); $(f) Hz is outside. " *
              "Pass allow_extrapolation=true to extend the end segment (X-EXTRAP).")
    λ = 10^_interp_logf(f, t.f_Hz, log10.(t.lambda_m))
    α_dB = 10^_interp_logf(f, t.f_Hz, log10.(t.alpha_dB_per_m))
    W = 10^_interp_logf(f, t.f_Hz, log10.(t.W_rayl))
    φ = _interp_logf(f, t.f_Hz, t.phi_deg)
    return (lambda_m=λ, alpha_Np_per_m=α_dB * NP_PER_DB, phi_rad=deg2rad(φ), W_abs=W, extrapolated=out)
end

# --- trim elements and the transfer matrix --------------------------------------------------

abstract type TrimElement end

"""Layer of insulation of thickness `thickness` [m], Eq. (A.10)."""
struct InsulationLayer <: TrimElement
    thickness::Float64
    material::InsulationTable
end

"""Limp mass `m` [kg/m²] with loss factor `η` (flexure), Eq. (A.11)."""
struct LimpMass <: TrimElement
    m::Float64
    η::Float64
    label::String
end
LimpMass(m::Real, η::Real) = LimpMass(float(m), float(η), "limp mass")

"""Trim elements ordered skin side first (element 1 touches the skin, Eq. A.12)."""
struct TrimStack
    elements::Vector{TrimElement}
    name::String
end
TrimStack(elements::AbstractVector{<:TrimElement}) = TrimStack(collect(TrimElement, elements), "")

"""Insulation matrix of Eq. (A.10): `[C  iωWS; −iS/(ωW)  C]`, γ = α − ik, W = |W|e^{iφ}."""
function element_matrix(el::InsulationLayer, ω::Real; allow_extrapolation::Bool=false)
    p = insulation_properties(el.material, ω / 2π; allow_extrapolation)
    k = 2π / p.lambda_m
    x = complex(p.alpha_Np_per_m, -k) * el.thickness
    C, S = cosh(x), sinh(x)
    W = p.W_abs * cis(W_PHASE_SIGN * p.phi_rad)
    return ComplexF64[C im*ω*W*S; -im*S/(ω*W) C]
end

"""Limp-mass matrix of Eq. (A.11): `[1  ω²m(1 + iη); 0  1]`."""
element_matrix(el::LimpMass, ω::Real; kw...) = ComplexF64[1 ω^2 * el.m * (1 + im * el.η); 0 1]

"""Cascade `M_n ⋯ M_2 M_1` of Eq. (A.12); the empty stack is the identity."""
function stack_matrix(st::TrimStack, ω::Real; allow_extrapolation::Bool=false)
    M = ComplexF64[1 0; 0 1]
    for el in st.elements
        M = element_matrix(el, ω; allow_extrapolation) * M
    end
    return M
end

"""True when any insulation layer of the stack needs frequency `f_Hz` outside its digitized range."""
function stack_extrapolated(st::TrimStack, f_Hz::Real)
    for el in st.elements
        el isa InsulationLayer || continue
        (f_Hz < first(el.material.f_Hz) || f_Hz > last(el.material.f_Hz)) && return true
    end
    return false
end

"""Insulation-path transmission of Eqs. (A.6)/(A.14): |a11|⁻²."""
trim_tau_insulation(st::TrimStack, ω::Real; kw...) = 1 / abs2(stack_matrix(st, ω; kw...)[1, 1])

"""C_w of Eq. (A.8): −a12 a22/(1 + a12 a21). Complex, with the units of a12 (Pa/m)."""
function trim_Cw(st::TrimStack, ω::Real; kw...)
    M = stack_matrix(st, ω; kw...)
    return -M[1, 2] * M[2, 2] / (1 + M[1, 2] * M[2, 1])
end

"""
    trim_admittance(stack, ω, m_wall; ρ0, c0) -> β

Eq. (A.16) with the structural impedance of Eq. (A.17), Z₁ = ρ0c0 − iωm. `m_wall = Inf` is the rigid
backing limit β = iωρ0c0 a21/a11 (used for the end plates, whose mass CR-3813 does not give).
"""
function trim_admittance(st::TrimStack, ω::Real, m_wall::Real; ρ0::Real=1.225, c0::Real=340.0, kw...)
    M = stack_matrix(st, ω; kw...)
    a11, a12, a21, a22 = M[1, 1], M[1, 2], M[2, 1], M[2, 2]
    isinf(m_wall) && return im * ω * ρ0 * c0 * a21 / a11
    Z1 = ρ0 * c0 - im * ω * m_wall
    return ρ0 * c0 * (-ω^2 * a21 * Z1 + im * ω * a22) / (im * ω * a11 * Z1 + a12)
end

"""Conductance ξ = Re β looking from the cabin into the wall treatment (Eq. A.15 text)."""
trim_conductance(st::TrimStack, ω::Real, m_wall::Real; kw...) = real(trim_admittance(st, ω, m_wall; kw...))

# --- mechanical (structure-borne) path, Eqs. (A.19)–(A.21) -----------------------------------

"""
Inputs of the mechanical vibration path from skin to trim, Eqs. (A.19)–(A.21). Subscript `t`: trim lining; no subscript:
skin (`h` thickness, `c_l` dilatational wavespeed). The modal densities are those of a flat plate,
n = A√3/(2π h c) per rad/s (assumption j of the register, V-ASSUMED), unless given.
"""
Base.@kwdef struct MechanicalPath
    m_t::Float64; A_t::Float64; h_t::Float64; c_t::Float64; η_t::Float64
    m::Float64;   A::Float64;   h::Float64;   c_l::Float64
    N_points::Int = 0
    line_length::Float64 = 0.0
    n_t::Float64 = A_t * sqrt(3) / (2π * h_t * c_t)
    n_r::Float64 = A * sqrt(3) / (2π * h * c_l)
end

"""Coupling loss factor η21, trim to skin: N point connections (A.20) plus line supports (A.21, per unit length × `line_length`)."""
function coupling_loss_factor_21(mp::MechanicalPath, ω::Real)
    Zs, Zt = mp.m * mp.h * mp.c_l, mp.m_t * mp.h_t * mp.c_t
    pts = mp.N_points == 0 ? 0.0 :
          4mp.N_points / (sqrt(3) * mp.A_t) * (mp.h_t * mp.c_t / ω) * (Zs * Zt) / (Zs + Zt)^2
    Ys, Yt = mp.m * sqrt(mp.h * mp.c_l), mp.m_t * sqrt(mp.h_t * mp.c_t)
    line = mp.line_length == 0 ? 0.0 :
           (2 / 3)^0.25 / mp.A_t * sqrt(mp.h_t * mp.c_t / ω) * (Ys * Yt) / (Ys + Yt)^2 * mp.line_length
    return pts + line
end

"""Mechanical-path transmission τ_t^m of Eq. (A.19)."""
function trim_tau_mechanical(mp::MechanicalPath, ω::Real)
    η21 = coupling_loss_factor_21(mp, ω)
    return (mp.m_t * mp.A_t * mp.n_t) / (mp.m * mp.A * mp.n_r) * η21 / (η21 + mp.η_t)
end

"""τ_t = |a11|⁻² + τ_t^m, Eq. (A.22) (`mech = nothing`: insulation path only)."""
function trim_tau(st::TrimStack, ω::Real; mech::Union{Nothing,MechanicalPath}=nothing, kw...)
    return trim_tau_insulation(st, ω; kw...) + (mech === nothing ? 0.0 : trim_tau_mechanical(mech, ω))
end

# --- Phase III stacks (App. E, p. E-8) ------------------------------------------------------

"""
    phase3_trim(; a, L, theta0_deg, material, η_lining, facing_side, septum_mass, G10_wavespeed) -> NamedTuple

The Phase III trim of App. E p. E-8. Curved wall: four 1.3 cm layers of 9.61 kg/m³ fiberglass, each with a vinyl facing
(0.22 kg/m² per layer minus the 0.013 m × 9.61 kg/m³ of fiberglass = 0.095 kg/m²), and the septum (6.58 kg over the curved trim area
2a(π − θ0)L). End plates: one layer plus facing. The facing/septum loss factor `η_lining` defaults to NASA's η_T = 0.5 for the Phase III predictions
(CR-3813 p. E-24; default changed from 0.05 on 2026-10-20 by the author's decision, plan 19; the aircraft register default 0.05 stays
in `VALIDATION_GUIDELINE.md` register f and is revisited in phase 31, `phase3_trim` being the test article only). Values CR-3813 does not give (V-ASSUMED, register f): which side the facing is on (`:cabin` default), the G-10 dilatational wavespeed, nine point connections plus two floor-edge lines.
"""
function phase3_trim(; a::Real=0.508, L::Real=1.803, theta0_deg::Real=56.6,
                     material::InsulationTable=pf105_table(),
                     η_lining::Real=0.5, facing_side::Symbol=:cabin,
                     septum_mass::Real=6.58, layer_thickness::Real=0.013, n_layers::Int=4,
                     facing_mass::Real=0.095, G10_thickness::Real=0.00079, G10_wavespeed::Real=3200.0,
                     N_points::Int=9, n_lines::Int=2,
                     E::Real=MRP_E_2024, ν::Real=MRP_NU_2024, ρ::Real=MRP_RHO_2024)
    facing_side in (:cabin, :skin) || error("facing_side must be :cabin or :skin")
    θ0 = deg2rad(theta0_deg)
    A_curved = 2a * (π - θ0) * L
    facing = LimpMass(facing_mass, η_lining, "vinyl facing")
    els = TrimElement[]
    for _ in 1:n_layers
        ins = InsulationLayer(layer_thickness, material)
        facing_side === :cabin ? push!(els, ins, facing) : push!(els, facing, ins)
    end
    septum = LimpMass(septum_mass / A_curved, η_lining, "septum")
    push!(els, septum)
    sidewall = TrimStack(els, "Phase III curved wall")
    ends = TrimStack(TrimElement[InsulationLayer(layer_thickness, material),
                                 LimpMass(facing_mass, η_lining, "vinyl facing")], "Phase III end plate")
    t_eq = MRP_T_SKIN + MRP_A_STRINGER / MRP_D_STRINGER + MRP_A_FRAME / MRP_ELL_FRAME
    m_wall = ρ * t_eq
    mech = MechanicalPath(m_t=septum.m, A_t=A_curved, h_t=G10_thickness, c_t=G10_wavespeed, η_t=η_lining,
                          m=m_wall, A=A_curved, h=MRP_T_SKIN, c_l=sqrt(E / (ρ * (1 - ν^2))),
                          N_points=N_points, line_length=n_lines * L)
    return (; sidewall, ends, mech, m_wall, A_curved, septum_mass_per_area=septum.m)
end

# --- special functions: Si and Cin to machine precision -------------------------------------

"""
    sine_integral(x) -> Si(x), cin(x) -> Cin(x) = ∫₀ˣ (1 − cos t)/t dt = γ + ln x − Ci(x)

Power series for |x| < 4, the Lentz continued fraction for E₁(ix) beyond, both iterated to machine precision.
Si is odd, Cin even.
"""
function _si_cin(x::Float64)
    x == 0 && return (0.0, 0.0)
    if x < 4
        x2 = x^2
        t = x; si = x
        c = x2 / 2; cin = c / 2
        for k in 1:200
            t *= -x2 / ((2k) * (2k + 1)); dsi = t / (2k + 1)
            c *= -x2 / ((2k + 1) * (2k + 2)); dcin = c / (2k + 2)
            si += dsi; cin += dcin
            abs(dsi) ≤ eps() * abs(si) && abs(dcin) ≤ eps() * abs(cin) && break
        end
        return (si, cin)
    end
    b = complex(1.0, x)
    c = 1 / 1e-300
    d = h = 1 / b
    for i in 2:100_000
        an = -float(i - 1)^2
        b += 2
        d = 1 / (an * d + b)
        c = b + an / c
        del = c * d
        h *= del
        abs(real(del) - 1) + abs(imag(del)) ≤ eps() && break
    end
    h = complex(cos(x), -sin(x)) * h
    ci = -real(h)
    si = π / 2 + imag(h)
    return (si, 0.5772156649015329 + log(x) - ci)
end
sine_integral(x::Real) = (s = _si_cin(abs(float(x)))[1]; x < 0 ? -s : s)
cin(x::Real) = _si_cin(abs(float(x)))[2]

# --- joint acceptances, Eqs. (62)–(73) ---------------------------------------------------------

_sinc_pi(x) = abs(x) < 1e-8 ? 1.0 : sin(π * x) / (π * x)

"""
I₁, I₂, I₃ of Eqs. (71)–(73) for `n` waves around a length 2πa (half-integers allowed, for the axial mode) and `ka`.
I₁ is printed as 1/(4πn k(2πa)) = 1/(8π² n ka). I₃ is evaluated as (n − ka) sinc²(n − ka)/(2(n + ka)), identical to the printed form and finite at ka = n.
"""
function _joint_I123(n::Real, ka::Real)
    ka ≤ 1e-12 && return (0.0, 0.0, 0.0)           # integer n ≥ 1: all three vanish as ka → 0
    sp, cp = _si_cin(2π * (n + ka))
    sm_abs, cm = _si_cin(abs(2π * (n - ka)))
    sm = n - ka < 0 ? -sm_abs : sm_abs
    I1 = (cp - cm) / (8π^2 * n * ka)
    I2 = (sp - sm) / (4π * ka)
    I3 = (n - ka) * _sinc_pi(n - ka)^2 / (2 * (n + ka))
    return (I1, I2, I3)
end

"""
    ring_joint_acceptance(n, ka, kind; mode_normalized=false) -> j_n²(ω, ψ|φ)

Eqs. (65), (69), (70) for the cosine (`:psi`) and sine (`:phi`) circumferential mode of order `n`. As printed, the n > 0 forms are half of the
joint acceptance normalized by the mode's own mean square (found 2026-10-20 by direct quadrature: j²ψ = 2(I₂+I₃−I₁), j²φ = 2(I₁+I₂+I₃)
while the n = 0 form, Eq. 65, is the full value). `mode_normalized = true` returns the doubled n > 0 forms; the default is the printed text.
"""
function ring_joint_acceptance(n::Integer, ka::Real, kind::Symbol; mode_normalized::Bool=false)
    kind in (:psi, :phi) || error("kind must be :psi or :phi")
    if n == 0
        kind === :phi && error("a sine mode has n ≥ 1")
        x = 2π * ka
        x < 1e-3 && return 1 - x^2 / 36
        return sine_integral(x) / (π * ka) - (1 - cos(x)) / (2π^2 * ka^2)
    end
    I1, I2, I3 = _joint_I123(n, ka)
    j = kind === :psi ? I2 + I3 - I1 : I1 + I2 + I3
    return mode_normalized ? 2j : j
end

"""Axial joint acceptance j_M²(ω) of Eq. (63) for sin(Mπz/L): the ring formulas with n = M/2 and ka → kL/(2π) (L = 2πa_eff)."""
function axial_joint_acceptance(M::Integer, kL::Real; mode_normalized::Bool=false)
    I1, I2, I3 = _joint_I123(M / 2, kL / 2π)
    j = I1 + I2 + I3
    return mode_normalized ? 2j : j
end

"""
    structural_joint_acceptance(mode, ω; a, L, c0, mode_normalized=false) -> j_r²(ω)

Eq. (66): j_M² (axial, Eq. 63) × j_N² (circumferential, Eq. 67 for symmetric modes with n = 0, 1, …; Eq. 68 for anti-symmetric with n = 1, …),
using the shell coefficients C_Mn of the mode.
"""
function structural_joint_acceptance(mode::StructuralMode, ω::Real; a::Real, L::Real, c0::Real=340.0,
                                     mode_normalized::Bool=false)
    k = ω / c0
    jM = axial_joint_acceptance(mode.M_axial, k * L; mode_normalized)
    jN = 0.0
    for (C, n) in zip(mode.C_shell, mode.n_shell)
        if mode.symmetric
            jN += C^2 * ring_joint_acceptance(n, k * a, :psi; mode_normalized)
        elseif n ≥ 1
            jN += C^2 * ring_joint_acceptance(n, k * a, :phi; mode_normalized)
        end
    end
    return jM * jN
end

# --- loss factors, §3.8 -----------------------------------------------------------------------

"""
    acoustic_loss_modal(mode, q, ω, ω_n; a, L, V, c0, ξ, ξ_e) -> (; N, η_n)

Eq. (77) for the cabin mode n = (q, i) with trim: η_n = ωc0ε_n/(ω_n²V) {ξ (L/2) ε_q a Σ_j φ_i²(j)(θ2j − θ1j) + 2ξ_e a² Φ_G(i)}. `N = η_n ω_n²` is the
form that stays finite at ω_n = 0 (the rigid-body mode); `η_n = N/ω_n²` is `Inf` there. ε_n is the 3-D normalization (`cabin_eps_3d`), ε_q = 2 for q = 0, 1 otherwise.
"""
function acoustic_loss_modal(mode::AcousticMode, q::Int, ω::Real, ω_n::Real;
                             a::Real, L::Real, V::Real, c0::Real=340.0, ξ::Real, ξ_e::Real)
    εq = q == 0 ? 2.0 : 1.0
    wall = sum(mode.phi_boundary .^ 2 .* (mode.theta_hi_rad .- mode.theta_lo_rad))
    N = ω * c0 * cabin_eps_3d(mode, q) / V * (ξ * (L / 2) * εq * a * wall + 2ξ_e * a^2 * mode.gen_mass_unit)
    return (; N, η_n=ω_n == 0 ? Inf : N / ω_n^2)
end

"""Average acoustic loss factor at high frequency, Eq. (78): 8c0/(4ωV) [ξS + 2ξ_e S_e]."""
acoustic_loss_average(ω::Real; V::Real, S::Real, S_e::Real, ξ::Real, ξ_e::Real, c0::Real=340.0) =
    8c0 / (4ω * V) * (ξ * S + 2ξ_e * S_e)

"""ᾱ from η̄_n = ᾱc0S/(4ωV) (Eq. 24 form, p. 25): ᾱ = 4ωVη̄_n/(c0 S) with `S` the absorbing area."""
absorption_from_loss_factor(η̄::Real, ω::Real; V::Real, S::Real, c0::Real=340.0) = 4ω * V * η̄ / (c0 * S)

"""C/f_r of Eq. (80), C typically 2–4 (register g: 3)."""
structural_loss_vacuo(f_r::Real; C::Real=3.0) = C / f_r

"""External radiation loss factor of Eq. (81): 2ρ0ωĀ/(πmc0) j_r²(ω)."""
radiation_loss_factor(j2::Real, ω::Real; Abar::Real, m::Real, ρ0::Real=1.225, c0::Real=340.0) =
    2ρ0 * ω * Abar / (π * m * c0) * j2

"""η_r = η_r^struc + η_r^rad (Eqs. 79–81) at ω = ω_r, `C` of Eq. (80)."""
function structural_loss_total(mode::StructuralMode, ω_r::Real; a::Real, L::Real, m::Real, C::Real=3.0,
                               ρ0::Real=1.225, c0::Real=340.0, Abar::Real=2π * a * L, mode_normalized::Bool=false)
    j2 = structural_joint_acceptance(mode, ω_r; a, L, c0, mode_normalized)
    return structural_loss_vacuo(ω_r / 2π; C) + radiation_loss_factor(j2, ω_r; Abar, m, ρ0, c0)
end

"""
    structural_loss_with_trim(η_r, ω_r, m, C_w) -> η_r'

Eq. (82): η_r' = {|C_w|²/(m²ω_r⁴) − 2 C_w^I η_r/(mω_r²) + η_r²}^{1/2}, C_w from Eq. (A.8) at ω_r. An error if the radicand is not positive.
"""
function structural_loss_with_trim(η_r::Real, ω_r::Real, m::Real, Cw::Complex)
    v = abs2(Cw) / (m^2 * ω_r^4) - 2imag(Cw) * η_r / (m * ω_r^2) + η_r^2
    v > 0 || error("η_r'² = $v ≤ 0 (Eq. 82); the loss factor is undefined")
    return sqrt(v)
end

"""
    structural_loss_coupled(N, ω_n, ω_r, f_coupling, ε_n, M_r, V, A; ρ0, c0) -> η_r''

Eq. (83), written with N = η_nω_n² so that it stays finite at ω_n = 0:
η_r'' = ρ0c0²A²ε_n f'²/(M_r V) · N / [(ω_n² − ω_r²)² + N²].
"""
function structural_loss_coupled(N::Real, ω_n::Real, ω_r::Real, f_coupling::Real, ε_n::Real, M_r::Real,
                                 V::Real, A::Real; ρ0::Real=1.225, c0::Real=340.0)
    return ρ0 * c0^2 * A^2 * ε_n * f_coupling^2 / (M_r * V) * N / ((ω_n^2 - ω_r^2)^2 + N^2)
end
