"""
CR-3813 Appendix D structural solver (Eqs. D.17–D.26) — no fitted scale.

Printed forms (pp. D-3…D-10; PDF pp. 99–106) are transcribed in comments at the
operators. Readings decided before any Table D-1 comparison are listed in
`APPD_READINGS` and in the validation report.

`mrp.jl` (Table-D-1-seeded surrogate) is untouched; this module is selected with
`structural_solver=:appd`.
"""

# ---------------------------------------------------------------------------
# Readings decided from the printed text (2026-10-22, before Table D-1 run)
# ---------------------------------------------------------------------------
const APPD_READINGS = (
    # Attachment: App. E p. E-3 — floor "bolt to skin" → rigid (D.4) all four
    # equations; hinged would drop the rotation line (p. D-4).
    attachment = :rigid,
    # Asterisk (*) terms in (D.23): omitted. Text (p. D-8) says they vanish when
    # stiffener eccentricities zs, zr are zero (Mikulas comparison). App. D's
    # smearing (D.24)+(D.25) does not re-introduce eccentricity operators.
    asterisk_terms = false,
    # Stiffener placement in (D.25) per p. D-10: membrane kx,kθ from equivalent
    # thickness t; bending Dx,Dθ from t_eq except the third diagonal of (D.25),
    # which uses Dxs, DθR from (D.24) with Dx,Dθ of the actual skin.
    d25_thickness_rule = :page_D10,
    # θ in (D.3)/(D.26) from the bottom centerline; floor angle θ0 = 56.6°
    # (App. E p. E-3 / Fig. D-1). Junctions at ±θ0.
    theta_origin = :bottom_centerline,
    # Length: App. E p. E-1 / I-22 decision 2026-10-22: 1.83 m (72 in.).
    # Table D-1 title 1.803 m is a caption typo.
    L_source = "App. E p. E-1 / I-22: 1.83 m (test_article_length)",
    # Material: App. E p. E-3 "2024-T3 aluminum"; E, ν, ρ from Manual §5.2 /
    # existing MRP_* (no separate printed E in App. D).
    material_source = "MRP_E_2024 / MRP_NU_2024 / MRP_RHO_2024 (Manual §5.2)",
    # Constraint reduction: nullspace of [C] (Eq. D.17) ≡ [E] of (D.20) after
    # column partition into independent/dependent sets.
    constraint_reduction = :nullspace_of_C,
)

"""Inputs the App. D solver accepts: `AppDGeometry` (stiffener sections, smeared by (D.24)) or `AppDDeck` (PAIN's own
SHELL / PLATE cards, smeared properties given directly)."""
abstract type AbstractAppDInput end

"""Geometry / material inputs for the App. D solver (any fuselage, not only the test article)."""
struct AppDGeometry <: AbstractAppDInput
    L::Float64                 # length [m]
    a::Float64                 # radius [m]
    theta0_deg::Float64        # floor angle [deg]
    t_skin::Float64            # skin thickness [m]
    t_floor::Float64           # floor plate thickness [m]
    A_stringer::Float64        # stringer area [m²]
    d_stringer::Float64        # stringer spacing (arc) [m]
    I_stringer::Float64        # stringer bending inertia [m⁴]
    A_frame::Float64           # ring-frame area [m²]
    ell_frame::Float64         # ring spacing [m]
    I_frame::Float64           # ring bending inertia [m⁴]
    A_floor_beam::Float64      # transverse floor-support area [m²]
    I_floor_beam::Float64      # floor-beam bending inertia [m⁴]
    E::Float64
    ν::Float64
    ρ::Float64
end

"""
Test-article geometry from CR-3813 App. E (pp. E-1…E-3) + Manual §5.2 material.
Areas / inertias reuse `MRP_*` (derived from the same printed dimensions).
L follows `test_article_length()` (I-22 default 1.83 m; override for sensitivity).
"""
function appd_test_article_geometry()
    L = test_article_length()
    return AppDGeometry(
        L,
        0.508,                 # diameter 1.016 m (App. E Fig. E-2)
        56.6,                  # App. E p. E-3
        MRP_T_SKIN,            # 0.00081 m (App. E p. E-1)
        MRP_T_SKIN,
        MRP_A_STRINGER,        # (0.00953+0.0112)*0.00051
        MRP_D_STRINGER,        # 0.508*(20π/180) — 18 stringers @ 20°
        MRP_I_STRINGER,
        MRP_A_FRAME,           # (2*0.017+0.038)*0.00081 channel
        MRP_ELL_FRAME,         # 0.2 m (App. E p. E-1)
        MRP_I_FRAME,
        MRP_A_FLOOR_BEAM,
        MRP_I_FLOOR_BEAM,
        MRP_E_2024,
        MRP_NU_2024,
        MRP_RHO_2024,
    )
end

function AppDGeometry(fuse::FuselageGeometry;
                      t_skin::Float64=MRP_T_SKIN,
                      t_floor::Float64=MRP_T_SKIN,
                      A_stringer::Float64=MRP_A_STRINGER,
                      d_stringer::Float64=MRP_D_STRINGER,
                      I_stringer::Float64=MRP_I_STRINGER,
                      A_frame::Float64=MRP_A_FRAME,
                      ell_frame::Float64=MRP_ELL_FRAME,
                      I_frame::Float64=MRP_I_FRAME,
                      A_floor_beam::Float64=MRP_A_FLOOR_BEAM,
                      I_floor_beam::Float64=MRP_I_FLOOR_BEAM,
                      E::Float64=MRP_E_2024,
                      ν::Float64=MRP_NU_2024,
                      ρ::Float64=MRP_RHO_2024)
    return AppDGeometry(fuse.L, fuse.a, fuse.theta0_deg, t_skin, t_floor,
                        A_stringer, d_stringer, I_stringer,
                        A_frame, ell_frame, I_frame,
                        A_floor_beam, I_floor_beam, E, ν, ρ)
end

"""
PAIN's own MRP input (User Manual cards 7-15, printed pp. 18-22): smeared shell and floor properties as the program
reads them. Shell: E, ν, thickness t (with smeared stiffener areas), mass per area (with smeared stiffener masses),
additional bending rigidities D′ of the stringers and of the frames (stiffener E I / spacing, I about the shell centre
line); floor: the same with D′ of the longitudinal floor beams and of the transverse floor supports. Isotropic sheet
(Ex = Eθ on both cards of the test-article deck). `n_axial`, `n_circ`, `n_floor_max` are the deck's series limits
(card 8). Phase 80, 2026-10-29.
"""
struct AppDDeck <: AbstractAppDInput
    L::Float64
    a::Float64
    theta0_deg::Float64
    E_shell::Float64
    ν_shell::Float64
    t_shell::Float64
    m_shell::Float64
    Dp_stringers::Float64
    Dp_frames::Float64
    E_floor::Float64
    ν_floor::Float64
    t_floor::Float64
    m_floor::Float64
    Dp_floor_beams::Float64
    Dp_floor_supports::Float64
    n_axial::Int
    n_circ::Int
    n_floor_max::Int
end

"""NASA's MRP deck for the test article (`data/cr3813/um_mrp_input_deck.csv`, User Manual pp. 42-43)."""
function appd_nasa_deck(path::AbstractString=normpath(joinpath(@__DIR__, "..", "..", "data", "cr3813", "um_mrp_input_deck.csv")))
    v = Dict{Tuple{String,String},Float64}()
    for l in eachline(path)
        (isempty(l) || startswith(l, "#") || startswith(l, "part,")) && continue
        f = split(l, ",")
        v[(String(f[1]), String(f[2]))] = parse(Float64, f[3])
    end
    for part in ("shell", "plate")
        e2 = part == "shell" ? "Etheta" : "Ey"
        n2 = part == "shell" ? "nu_theta" : "nu_y"
        (v[(part, "Ex")] == v[(part, e2)] && v[(part, "nu_x")] == v[(part, n2)]) ||
            error("appd_nasa_deck: orthotropic sheet on the $part card is not supported")
    end
    v[("general", "M_first")] == 1 && v[("general", "ns_first")] == 0 && v[("general", "np_first")] == 0 ||
        error("appd_nasa_deck: series must start at M = 1, ns = 0, np = 0")
    return AppDDeck(v[("shell", "length")], v[("shell", "radius")], v[("general", "theta0_deg")],
        v[("shell", "Ex")], v[("shell", "nu_x")], v[("shell", "t")], v[("shell", "mass_per_area")],
        v[("shell", "Dprime_stringers")], v[("shell", "Dprime_frames")],
        v[("plate", "Ex")], v[("plate", "nu_x")], v[("plate", "t")], v[("plate", "mass_per_area")],
        v[("plate", "Dprime_long_beams")], v[("plate", "Dprime_transverse_supports")],
        Int(v[("general", "M_last")]), Int(v[("general", "ns_last")]), Int(v[("general", "np_last")]))
end

# ---------------------------------------------------------------------------
# Constitutive scalars — (D.24) and p. D-10 thickness rule
# ---------------------------------------------------------------------------
"""
Skin membrane / bending from equivalent or actual thickness (p. D-10):
  kx = kθ = E t / (1−ν²),   Dx = Dθ = E t³ / (12(1−ν²)).
"""
function _appd_kD(E, ν, t)
    k = E * t / (1 - ν^2)
    D = E * t^3 / (12 * (1 - ν^2))
    return k, D
end

function _appd_shell_props(g::AppDGeometry)
    t_eq = g.t_skin + g.A_stringer / max(g.d_stringer, 1e-12) +
           g.A_frame / max(g.ell_frame, 1e-12)                          # (D.26) text
    k_eq, D_eq = _appd_kD(g.E, g.ν, t_eq)
    _, D_skin = _appd_kD(g.E, g.ν, g.t_skin)
    # (D.24) bending augmentation with actual-skin D (p. D-10 third-diagonal rule)
    D_xs = D_skin + g.E * g.I_stringer / max(g.d_stringer, 1e-12)
    D_θR = D_skin + g.E * g.I_frame / max(g.ell_frame, 1e-12)
    G = g.E / (2 * (1 + g.ν))
    Gt = G * t_eq
    Gt3 = G * t_eq^3 / 12
    ms = g.ρ * t_eq
    return (; t_eq, k_eq, D_eq, D_xs, D_θR, Gt, Gt3, ms, ν=g.ν, a=g.a, E=g.E, ρ=g.ρ)
end

function _appd_floor_props(g::AppDGeometry)
    Lp = 2 * g.a * sin(deg2rad(g.theta0_deg))
    t_eq_f = g.t_floor + g.A_floor_beam / max(g.ell_frame, 1e-12)
    k_f, D_f_skin = _appd_kD(g.E, g.ν, t_eq_f)
    # Phase 78d F2 (reading fixed 2026-10-28 before the run): orthotropic floor. The two longitudinal floor beams
    # stiffen bending along x, the floor supports at each frame (App. E Fig. E-3) along y; the coupling (twisting)
    # term is the plate's own, H = D_plate. Until 2026-10-28 both were summed into one isotropic Df.
    Dx = D_f_skin + 2 * g.E * g.I_floor_beam / max(Lp, 1e-12)
    Dy = D_f_skin + g.E * g.I_floor_beam / max(g.ell_frame, 1e-12)
    H = D_f_skin
    G = g.E / (2 * (1 + g.ν))
    mf = g.ρ * t_eq_f
    return (; Lp, t_eq_f, k_f, Dx, Dy, H, Gt=G * t_eq_f, Gt3=G * t_eq_f^3 / 12, mf, ν=g.ν)
end

# PAIN's cards give the smeared thickness and mass directly; the sheet's own bending rigidity is computed from the card
# thickness (the only thickness the program reads) and the cards' D′ are added to it (Phase 80 reading, 2026-10-29).
function _appd_shell_props(d::AppDDeck)
    t = d.t_shell
    k, D = _appd_kD(d.E_shell, d.ν_shell, t)
    G = d.E_shell / (2 * (1 + d.ν_shell))
    return (; t_eq=t, k_eq=k, D_eq=D, D_xs=D + d.Dp_stringers, D_θR=D + d.Dp_frames, Gt=G * t, Gt3=G * t^3 / 12,
            ms=d.m_shell, ν=d.ν_shell, a=d.a, E=d.E_shell, ρ=d.m_shell / t)
end

function _appd_floor_props(d::AppDDeck)
    Lp = 2 * d.a * sin(deg2rad(d.theta0_deg))
    t = d.t_floor
    k, D = _appd_kD(d.E_floor, d.ν_floor, t)
    G = d.E_floor / (2 * (1 + d.ν_floor))
    return (; Lp, t_eq_f=t, k_f=k, Dx=D + d.Dp_floor_beams, Dy=D + d.Dp_floor_supports, H=D, Gt=G * t,
            Gt3=G * t^3 / 12, mf=d.m_floor, ν=d.ν_floor)
end

# ---------------------------------------------------------------------------
# Closed-form Donnell–Mushtari (unit-test reference) — Leissa SP-288 / Soedel
# ---------------------------------------------------------------------------
"""
Donnell–Mushtari frequency (Hz) for a simply-supported closed circular cylindrical
shell, bending + membrane, in-plane inertia neglected (Soedel / Leissa SP-288 §2.1.2):

  ω² = (D/(ρ t a⁴)) (λ²+n²)² + (E/(ρ a²)) λ⁴ / (λ²+n²)² ,

with λ = m π a / L, D = E t³/(12(1−ν²)). Source stated in the V-UNIT test.
"""
function donnell_mushtari_frequency_Hz(m::Int, n::Int, L, a, t, E, ν, ρ)
    λ = m * π * a / L
    β2 = (λ^2 + n^2)^2
    D = E * t^3 / (12 * (1 - ν^2))
    ω2 = (D / (ρ * t * a^4)) * β2 + (E / (ρ * a^2)) * λ^4 / max(β2, 1e-30)
    return sqrt(ω2) / (2π)
end

# ---------------------------------------------------------------------------
# Single-harmonic shell 3×3 from the (D.25) energy (closed cylinder or one n)
# ---------------------------------------------------------------------------
"""
Strain-energy / kinetic 3×3 for one (M,n) Fourier shell harmonic on a *full*
circumference, using the App. D / p. D-10 constitutive rule (no asterisks).

Trial amplitudes (symmetric family; standard SS Donnell / Peterson φ=sin μx):

  u = U cos(μ x) cos(n θ)
  v = V sin(μ x) sin(n θ)
  w = W sin(μ x) cos(n θ)

Love/Donnell strains + (D.23)/(D.25) constitutive (p. D-10 thickness rule).
Returns (K3, M3) with energy = ½ qᵀ K3 q.
"""
function _appd_shell_harmonic_KM(M::Int, n::Int, L, sp; arc_frac::Float64=1.0)
    a = sp.a
    μ = M * π / L
    ν = sp.ν
    kx = sp.k_eq
    kθ = sp.k_eq
    Dx_od = sp.D_eq
    Dxs = sp.D_xs
    DθR = sp.D_θR
    Gt = sp.Gt
    Gt3 = sp.Gt3
    Ix = L / 2
    cfac = arc_frac * (n == 0 ? 2π : π)
    S = Ix * cfac * a

    K = zeros(3, 3)
    K[1, 1] += kx * μ^2 * S
    K[2, 2] += kθ * (n / a)^2 * S
    K[2, 3] += kθ * (n / a^2) * S
    K[3, 2] += kθ * (n / a^2) * S
    K[3, 3] += kθ * (1 / a^2) * S
    K[1, 2] += -ν * kx * μ * (n / a) * S
    K[2, 1] += -ν * kx * μ * (n / a) * S
    K[1, 3] += -ν * kx * μ * (1 / a) * S
    K[3, 1] += -ν * kx * μ * (1 / a) * S
    if n == 0
        K[2, 2] += Gt * μ^2 * S
    else
        K[1, 1] += Gt * (n / a)^2 * S
        K[1, 2] += -Gt * (n / a) * μ * S
        K[2, 1] += -Gt * (n / a) * μ * S
        K[2, 2] += Gt * μ^2 * S
    end
    K[3, 3] += Dxs * μ^4 * S
    K[3, 3] += DθR * (n^2 / a^2)^2 * S
    K[3, 3] += 2 * ν * Dx_od * μ^2 * (n^2 / a^2) * S
    if n > 0
        K[3, 3] += Gt3 * (2 * n * μ / a)^2 * S
    end

    Mass = zeros(3, 3)
    Mass[1, 1] = sp.ms * S
    Mass[2, 2] = sp.ms * S
    Mass[3, 3] = sp.ms * S
    if n == 0
        Mass[2, 2] = max(Mass[2, 2], 1e-18)
        K[2, 2] = max(K[2, 2], 1e-18)
    end
    return K, Mass
end

"""Eigenfrequency (Hz) of one (M,n) from the App. D shell 3×3 (closed cylinder)."""
function appd_shell_harmonic_frequency_Hz(M::Int, n::Int, g::AbstractAppDInput)
    sp = _appd_shell_props(g)
    K, Mass = _appd_shell_harmonic_KM(M, n, g.L, sp; arc_frac=1.0)
    if n == 0
        idx = [1, 3]
        K = K[idx, idx]
        Mass = Mass[idx, idx]
    end
    vals = eigen(Symmetric(0.5 * (K + K')), Symmetric(0.5 * (Mass + Mass'))).values
    ω2 = minimum(v for v in vals if v > 0; init=Inf)
    return sqrt(ω2) / (2π)
end

"""
Donnell–Mushtari frequency from static condensation of the App. D shell 3×3
(in-plane inertia neglected). Must match the Soedel/Leissa closed form within 1 %.
"""
function appd_shell_condensed_frequency_Hz(M::Int, n::Int, g::AbstractAppDInput)
    sp = _appd_shell_props(g)
    K, Mass = _appd_shell_harmonic_KM(M, n, g.L, sp; arc_frac=1.0)
    if n == 0
        Kii = K[[1, 3], [1, 3]]
        Kww = Kii[2, 2] - Kii[1, 2]^2 / max(Kii[1, 1], 1e-30)
        Mww = Mass[3, 3]
    else
        Kuu = K[1:2, 1:2]
        Kuw = K[1:2, 3]
        Kww = K[3, 3] - dot(Kuw, Kuu \ Kuw)
        Mww = Mass[3, 3]
    end
    return sqrt(max(Kww / Mww, 0.0)) / (2π)
end

# ---------------------------------------------------------------------------
# Floor (flat plate) harmonic energy — classical Kirchhoff + membrane
# ---------------------------------------------------------------------------
"""
Floor plate one spanwise harmonic p on width Lp, same axial M.
Coordinates: y ∈ [−Lp/2, Lp/2] from centerline (Eqs. D.28–D.29).
Symmetric: cos(p π y / Lp); antisymmetric: sin(p π y / Lp).
"""
function _appd_floor_harmonic_KM(M::Int, p::Int, L, fp, sym::Bool)
    Lp = fp.Lp
    μ = M * π / L
    kx = fp.k_f
    Gt = fp.Gt
    ν = fp.ν
    Ix = L / 2
    # ∫_{-Lp/2}^{Lp/2} cos²(pπy/Lp) dy = Lp/2 (p>0), Lp (p=0); same for sin (p≥1)
    p < 0 && error("floor p ≥ 0")
    # ∫cos² = Lp (p = 0), Lp/2 (p ≥ 1); antisymmetric p = 0 is the uniform sway v = −1 (u_0, w_0 null, J3/J5)
    Iy = p == 0 ? Lp : Lp / 2
    ky = p * π / Lp   # wave number; p=0 → 0

    K = zeros(3, 3)
    # Membrane: u = U cos(μx) Ψ_u(y), v = V sin(μx) Ψ_v(y) — same amplitude convention as shell
    S = Ix * Iy
    K[1, 1] += kx * μ^2 * S
    if ky > 0
        K[2, 2] += kx * ky^2 * S
        # Phase 78d-4 J6: Poisson and shear coupling, K_uv = −(ν k + G t) μ k_y (the G t term was missing until
        # 2026-10-28). Same for both parities with the antisymmetric v = −cos k_y y.
        K[1, 2] += -(ν * kx + Gt) * μ * ky * S
        K[2, 1] += -(ν * kx + Gt) * μ * ky * S
        K[1, 1] += Gt * ky^2 * S
        K[2, 2] += Gt * μ^2 * S
    else
        K[2, 2] += Gt * μ^2 * S + 1e-18
    end
    # Kirchhoff bending of w, orthotropic (Phase 78d F2): Dx μ⁴ + 2H μ² k_y² + Dy k_y⁴
    K[3, 3] += (fp.Dx * μ^4 + 2 * fp.H * μ^2 * ky^2 + fp.Dy * ky^4) * S

    Mass = zeros(3, 3)
    Mass[1, 1] = fp.mf * S
    Mass[2, 2] = fp.mf * S
    Mass[3, 3] = fp.mf * S
    return K, Mass
end

"""Gauss–Legendre nodes and weights on [lo, hi] (Golub–Welsch)."""
function _gauss_legendre(n::Int, lo::Float64, hi::Float64)
    β = [k / sqrt(4k^2 - 1) for k in 1:n-1]
    F = eigen(SymTridiagonal(zeros(n), β))
    x = F.values
    w = 2 .* F.vectors[1, :] .^ 2
    return (hi - lo) / 2 .* x .+ (hi + lo) / 2, (hi - lo) / 2 .* w
end

"""
Floor spanwise functions of family `sym` at y (from the floor centreline), with first and second derivatives:
symmetric Ψu = Ψw = cos(k y), Ψv = sin(k y); antisymmetric Ψu = Ψw = sin(k y), Ψv = −cos(k y); k = pπ/Lp.
Returns (Ψu, Ψu′, Ψv, Ψv′, Ψw, Ψw′, Ψw″).
"""
function _appd_floor_funcs(p::Int, y::Float64, Lp::Float64, sym::Bool)
    k = p * π / Lp
    c, s = cos(k * y), sin(k * y)
    if sym
        return (c, -k * s, s, k * c, c, -k * s, -k^2 * c)
    else
        return (s, k * c, -c, k * s, s, k * c, -k^2 * s)
    end
end

"""
Floor stiffness and mass over every pair of spanwise functions of one (M, parity) block (3np × 3np, layout of
`_floor_dof` without the shell offset), by Gauss–Legendre quadrature over y ∈ [−Lp/2, Lp/2] (Phase 80a fix).
Same energy as `_appd_floor_harmonic_KM` with u = U cos μx Ψu, v = V sin μx Ψv, w = W sin μx Ψw:
membrane k_f(εx² + εy² + 2ν εx εy) + G t γ², orthotropic bending Dx w_xx² + Dy w_yy² + 2D₁ w_xx w_yy + 4D₆₆ w_xy²
with D₁ = ν D_plate, D₆₆ = (1 − ν) D_plate / 2, so D₁ + 2D₆₆ = H = D_plate (the reading of Phase 78d F2).
"""
function _appd_floor_block_KM(b, L, fp)
    Lp, μ, ν, kf, Gt = fp.Lp, b.M * π / L, fp.ν, fp.k_f, fp.Gt
    D1, D66 = ν * fp.H, (1 - ν) * fp.H / 2
    Ix = L / 2
    ys, ws = _gauss_legendre(64, -Lp / 2, Lp / 2)
    np = b.np
    K = zeros(3np, 3np); M = zeros(3np, 3np)
    d(j, c) = 3 * (j - 1) + c
    for (y, wq) in zip(ys, ws)
        F = [_appd_floor_funcs(p, y, Lp, b.sym) for p in b.p_floor]
        for i in 1:np, j in 1:np
            ui, dui, vi, dvi, wi, dwi, d2wi = F[i]
            uj, duj, vj, dvj, wj, dwj, d2wj = F[j]
            c = Ix * wq
            K[d(i, 1), d(j, 1)] += c * (kf * μ^2 * ui * uj + Gt * dui * duj)
            K[d(i, 2), d(j, 2)] += c * (kf * dvi * dvj + Gt * μ^2 * vi * vj)
            K[d(i, 1), d(j, 2)] += c * (-ν * kf * μ * ui * dvj + Gt * μ * dui * vj)
            K[d(j, 2), d(i, 1)] += c * (-ν * kf * μ * ui * dvj + Gt * μ * dui * vj)
            K[d(i, 3), d(j, 3)] += c * (fp.Dx * μ^4 * wi * wj + fp.Dy * d2wi * d2wj -
                                        D1 * μ^2 * (wi * d2wj + d2wi * wj) + 4D66 * μ^2 * dwi * dwj)
            M[d(i, 1), d(j, 1)] += c * fp.mf * ui * uj
            M[d(i, 2), d(j, 2)] += c * fp.mf * vi * vj
            M[d(i, 3), d(j, 3)] += c * fp.mf * wi * wj
        end
    end
    return K, M
end

# ---------------------------------------------------------------------------
# Coupled shell∪floor eigenproblem with (D.17)–(D.21) constraints
# ---------------------------------------------------------------------------

"""Index map for one (M, parity) block."""
struct _AppDBasis
    M::Int
    sym::Bool
    n_shell::Vector{Int}       # circumferential indices
    p_floor::Vector{Int}       # floor spanwise indices
    # DOF layout: for each shell n: (U,V,W); for each floor p: (U,V,W)
    ns::Int
    np::Int
    ndof::Int
end

function _appd_basis(M::Int, sym::Bool; n_circ::Int=8, n_floor_max::Int=5)
    # PAIN's own limit (User Manual card 8: final np ≤ 8). Beyond it cos(pπy/Lp) of both parities on the half period
    # are numerically dependent: the floor mass matrix reaches cond 1e13 at np = 9 and is singular at 11 (Phase 80b).
    0 ≤ n_floor_max ≤ 8 || error("n_floor_max = $n_floor_max outside 0–8 (PAIN's limit; the floor series is singular beyond)")
    ns_list = collect(0:n_circ)
    ps = collect(0:n_floor_max)          # antisymmetric p = 0: uniform floor sway (Phase 78d-4 J5)
    ns = length(ns_list)
    np = length(ps)
    return _AppDBasis(M, sym, ns_list, ps, ns, np, 3ns + 3np)
end

_shell_dof(b::_AppDBasis, i_n::Int, comp::Int) = 3 * (i_n - 1) + comp          # 1:U 2:V 3:W
_floor_dof(b::_AppDBasis, i_p::Int, comp::Int) = 3 * b.ns + 3 * (i_p - 1) + comp

# `floor_cross_terms`: see `appd_modes`. `floor_block`: a precomputed `_appd_floor_block_KM` result. `shell_kscale` multiplies the shell stiffness only, `floor_mscale` the floor
# mass only (test-only limiting cases of Phase 80a: a near-rigid shell; a floor whose own modes lie far above the
# range); production always uses 1.
function _appd_assemble_KM(b::_AppDBasis, g::AbstractAppDInput; floor_cross_terms::Bool=false,
                           shell_kscale::Float64=1.0, floor_mscale::Float64=1.0, floor_block=nothing)
    sp = _appd_shell_props(g)
    fp = _appd_floor_props(g)
    N = b.ndof
    K = zeros(N, N)
    M = zeros(N, N)
    # Shell over its whole circumference (Phase 78d-4 J2): Fig. D-1 / p. D-1 is a closed cylinder with an interior
    # partition and (D.14) integrates over the whole shell, so the harmonics are orthogonal (diagonal per n).
    # Until 2026-10-28 the shell energy and mass were scaled by the cabin arc fraction (246.8°/360°).
    for (i, n) in enumerate(b.n_shell)
        K3, M3 = _appd_shell_harmonic_KM(b.M, n, g.L, sp; arc_frac=1.0)
        K3 = shell_kscale * K3
        for c1 in 1:3, c2 in 1:3
            K[_shell_dof(b, i, c1), _shell_dof(b, i, c2)] += K3[c1, c2]
            M[_shell_dof(b, i, c1), _shell_dof(b, i, c2)] += M3[c1, c2]
        end
    end
    # Floor (Phase 80, 2026-10-29). cos(pπy/Lp) and sin(pπy/Lp) on [−Lp/2, Lp/2] are not orthogonal when p and q
    # differ in parity (e.g. ∫cos0·cos(πy/Lp) = 2Lp/π). NASA's program keeps only the diagonal of each spanwise term
    # (`floor_cross_terms=false`, the default): with NASA's deck it then reproduces Table D-1's 32 frequencies within
    # 0.012 % (MRP_APPD). With the cross terms the floor is the exact Ritz energy (`floor_cross_terms=true`); NASA's
    # form puts the second and third clamped-plate floor modes of the near-rigid-shell limit 50–78 % low (80a).
    Kf, Mf = floor_block === nothing ? _appd_floor_block_KM(b, g.L, fp) : floor_block
    if !floor_cross_terms
        mask = [div(i - 1, 3) == div(j - 1, 3) for i in 1:3b.np, j in 1:3b.np]
        Kf = Kf .* mask; Mf = Mf .* mask
    end
    fd = [_floor_dof(b, j, c) for j in 1:b.np for c in 1:3]
    K[fd, fd] .+= Kf
    M[fd, fd] .+= floor_mscale .* Mf
    # Symmetrize / floor tiny masses
    K = 0.5 * (K + K')
    M = 0.5 * (M + M')
    for i in 1:N
        M[i, i] = max(M[i, i], 1e-18)
    end
    return K, M, sp, fp
end

"""
Constraint matrix [C] for (D.17): C q = 0, from (D.4) at the +θ0 junction
(parity makes −θ0 redundant).

(D.4) rigid attachment (p. D-4):
  (1) u_s = u_p
  (2) w_s sin θ1 + v_s cos θ1 = v_p
  (3) w_s cos θ1 − v_s sin θ1 = w_p
  (4) v_s/a − (1/a) ∂w_s/∂θ + ∂w_p/∂y = 0

Axial φ factors cancel for a single M. Evaluated on the cos/sin amplitudes.
"""
function _appd_constraint_matrix(b::_AppDBasis, g::AbstractAppDInput; rigid::Bool=true)
    θ0 = deg2rad(g.theta0_deg)
    a = g.a
    Lp = 2 * a * sin(θ0)
    nrows = rigid ? 4 : 3
    C = zeros(nrows, b.ndof)
    # Shell contributions at θ = θ0
    for (i, n) in enumerate(b.n_shell)
        if b.sym
            cu = cos(n * θ0)          # u, w ~ cos
            sv = sin(n * θ0)          # v ~ sin
            dw = -n * sin(n * θ0)     # ∂w/∂θ amp / W
        else
            cu = sin(n * θ0)          # u, w ~ sin (D.3 antisym)
            sv = -cos(n * θ0)         # v ~ −cos
            dw = n * cos(n * θ0)
        end
        # (1) u_s: u amp = U * μ, but u_p also has U_p*μ — cancel μ, constrain U coeffs
        C[1, _shell_dof(b, i, 1)] += cu
        # (2) w sinθ + v cosθ
        C[2, _shell_dof(b, i, 3)] += cu * sin(θ0)
        C[2, _shell_dof(b, i, 2)] += sv * cos(θ0)
        # (3) w cosθ − v sinθ
        C[3, _shell_dof(b, i, 3)] += cu * cos(θ0)
        C[3, _shell_dof(b, i, 2)] -= sv * sin(θ0)
        # (4) v/a − (1/a) ∂w/∂θ
        if rigid
            C[4, _shell_dof(b, i, 2)] += sv / a
            C[4, _shell_dof(b, i, 3)] += -dw / a
        end
    end
    # Floor at y = +Lp/2
    for (j, p) in enumerate(b.p_floor)
        if b.sym
            # Ψ_w = cos(pπ y/Lp), Ψ_v = sin(pπ y/Lp), Ψ_u = cos
            yw = cos(p * π / 2)
            yv = sin(p * π / 2)
            # ∂w/∂y = −(pπ/Lp) sin(pπ y/Lp) → at y=Lp/2: −(pπ/Lp) sin(pπ/2)
            dwy = -(p * π / Lp) * sin(p * π / 2)
            yu = cos(p * π / 2)
        else
            yw = sin(p * π / 2)
            yv = -cos(p * π / 2)      # v = −cos(pπy/Lp), as the shell's −cos nθ (Phase 78d-4 J6; was +cos)
            dwy = (p * π / Lp) * cos(p * π / 2)
            yu = sin(p * π / 2)
        end
        C[1, _floor_dof(b, j, 1)] -= yu
        C[2, _floor_dof(b, j, 2)] -= yv
        C[3, _floor_dof(b, j, 3)] -= yw
        if rigid
            C[4, _floor_dof(b, j, 3)] += dwy
        end
    end
    return C
end

"""
Rows fixing the identically-zero basis functions at n = 0 of the shell (D.3) and the floor (J3, J5): sin 0 = 0, so
the symmetric v_0 and the antisymmetric u_0, w_0 carry stiffness and mass but no displacement and would give
spurious modes.
"""
function _appd_null_rows(b::_AppDBasis)
    comps = b.sym ? (2,) : (1, 3)
    rows = Vector{Float64}[]
    for (list, dof) in ((b.n_shell, _shell_dof), (b.p_floor, _floor_dof))
        i0 = findfirst(==(0), list)
        i0 === nothing && continue
        for c in comps
            r = zeros(b.ndof); r[dof(b, i0, c)] = 1.0; push!(rows, r)
        end
    end
    return isempty(rows) ? zeros(0, b.ndof) : permutedims(reduce(hcat, rows))
end

"""(D.4) junction rows plus the n = 0 null-function rows: the constraint set the eigenproblem is reduced with."""
_appd_all_constraints(b::_AppDBasis, g::AbstractAppDInput; rigid::Bool=true) =
    vcat(_appd_constraint_matrix(b, g; rigid=rigid), _appd_null_rows(b))

"""Reduced eigenproblem via nullspace of C (≡ Eqs. D.18–D.21)."""
function _appd_reduce(K, M, C; rtol=1e-10)
    # SVD nullspace
    F = svd(C; full=true)
    tol = rtol * maximum(F.S)
    r = count(>(tol), F.S)
    V = F.Vt'
    E = V[:, r+1:end]                          # (D.20) columns spanning null(C)
    size(E, 2) == 0 && return nothing
    Kr = E' * K * E
    Mr = E' * M * E
    Kr = 0.5 * (Kr + Kr')
    Mr = 0.5 * (Mr + Mr')
    for i in 1:size(Mr, 1)
        Mr[i, i] = max(Mr[i, i], 1e-18)
    end
    return Kr, Mr, E
end

"""
Evaluate (D.4) residuals at +θ0 for a full DOF vector (per-M amplitudes).
Returns the 4 residuals (or 3 if hinged).
"""
function appd_constraint_residuals(q::AbstractVector, b::_AppDBasis, g::AbstractAppDInput; rigid::Bool=true)
    C = _appd_constraint_matrix(b, g; rigid=rigid)
    return C * q
end

# ---------------------------------------------------------------------------
# Shape extraction → StructuralMode fields (Eqs. D.26–D.29)
# ---------------------------------------------------------------------------
"""
Largest |normal displacement| of a shape in App. D's convention (θ from the top, floor upward): the shell over its whole
circumference and the floor over its width. Coarse grid, then golden-section refinement around each grid maximum, so
the result is the continuous maximum to ~1e-12 (Phase 80d).
"""
function _appd_shape_peak(C_shell, n_shell, C_floor, n_floor, sym::Bool, θ0::Float64, Lp::Float64)
    ws(θ) = abs(sum((sym ? C * (-1)^n * cos(n * θ) : -C * (-1)^n * sin(n * θ) for (C, n) in zip(C_shell, n_shell)); init=0.0))
    wf(x) = abs(sum((sym ? C * cos(n * π * x / Lp) : C * sin(n * π * x / Lp) for (C, n) in zip(C_floor, n_floor)); init=0.0))
    function refine(f, lo, hi)
        φ = (sqrt(5) - 1) / 2
        a, b = lo, hi
        c, d = b - φ * (b - a), a + φ * (b - a)
        for _ in 1:80
            f(c) > f(d) ? (b = d) : (a = c)
            c, d = b - φ * (b - a), a + φ * (b - a)
        end
        return max(f((a + b) / 2), f(lo), f(hi))
    end
    function gridmax(f, lo, hi, n)
        xs = range(lo, hi; length=n)
        vals = f.(xs)
        k = argmax(vals)
        h = step(xs)
        return refine(f, max(lo, xs[k] - h), min(hi, xs[k] + h))
    end
    p = isempty(C_shell) ? 0.0 : gridmax(ws, 0.0, 2π, 721)
    return isempty(C_floor) ? p : max(p, gridmax(wf, -Lp / 2, Lp / 2, 201))
end

function _appd_extract_shapes(q::AbstractVector, b::_AppDBasis, g::AbstractAppDInput, Mr::Float64;
                              n_keep_shell::Int=8, n_keep_floor::Int=5)
    # Phase 78d-4 J1: the solver applies (D.4) at θ0 with the cos nθ / sin nθ basis, i.e. App. D's equations on the
    # structure mirrored top to bottom; its amplitudes c_n are in θ from the bottom with the floor w positive
    # downward. App. D (Fig. D-1, (D.3)) and Table D-1 measure θ from the top (`shell_circumferential` applies
    # (−1)ⁿ cos nθ / −(−1)ⁿ sin nθ from the bottom) with the floor positive upward, so
    # C_n = (−1)ⁿ c_n (symmetric), −(−1)ⁿ c_n (antisymmetric), C_p = −c_p. Until 2026-10-28 c_n was returned as is.
    C_shell = Float64[]
    n_shell = Int[]
    for (i, n) in enumerate(b.n_shell)
        W = q[_shell_dof(b, i, 3)]
        abs(W) < 1e-14 && continue
        push!(C_shell, (b.sym ? 1 : -1) * (-1)^n * W)
        push!(n_shell, n)
    end
    C_floor = Float64[]
    n_floor = Int[]
    for (j, p) in enumerate(b.p_floor)
        W = q[_floor_dof(b, j, 3)]
        abs(W) < 1e-14 && continue
        # (D.28)–(D.29): floor coefficients positive upward (inward); the solver's floor w is positive downward.
        push!(C_floor, -W)
        push!(n_floor, p)
    end
    # Normalize max |normal displacement| = 1 (p. D-10) over the whole shell and the floor. Until 2026-10-29 the shell
    # search covered the cabin arc only; Table D-1 mode 14 peaks below the floor and was then scaled 1.26× too large
    # (Phase 80, NASA's deck). The maximum is continuous (`_appd_shape_peak`); NASA's printed coefficients are up to
    # 2.3 % larger, consistent with a peak taken on its 36-point output grid (deck card MODE SHAPES), not reproduced here.
    peak = _appd_shape_peak(C_shell, n_shell, C_floor, n_floor, b.sym, deg2rad(g.theta0_deg), 2 * g.a * sin(deg2rad(g.theta0_deg)))
    if peak > 0
        C_shell ./= peak
        C_floor ./= peak
        Mr = Mr / peak^2
    end
    # Keep largest coefficients (same budget as Table D-1 print)
    function topk(C, n, k)
        isempty(C) && return C, n
        ord = sortperm(abs.(C); rev=true)
        kk = min(k, length(C))
        return C[ord[1:kk]], n[ord[1:kk]]
    end
    Cs, ns = topk(C_shell, n_shell, n_keep_shell)
    Cf, nf = topk(C_floor, n_floor, n_keep_floor)
    return Cs, ns, Cf, nf, Mr
end

"""
Eigen-solution of one (M, parity) family: frequencies `f_Hz` (ω² ≥ 1 only), full coefficient vectors `Q` (columns),
the assembled `K`, `Mass` (the matrices solved) and `Mass_exact` (with the floor cross terms, for generalized masses),
and the basis `b`; `nothing` when the constraints leave no freedom or the solve fails. `shell_kscale` and
`floor_mscale` are the test-only factors of `_appd_assemble_KM` (Phase 80a).
"""
function _appd_family(g::AbstractAppDInput, M::Int, sym::Bool; n_circ::Int=8, n_floor_max::Int=5,
                      rigid::Bool=true, floor_cross_terms::Bool=false, shell_kscale::Float64=1.0,
                      floor_mscale::Float64=1.0)
    b = _appd_basis(M, sym; n_circ=n_circ, n_floor_max=n_floor_max)
    fb = _appd_floor_block_KM(b, g.L, _appd_floor_props(g))     # the floor quadrature, once per family
    K, Mass, _, _ = _appd_assemble_KM(b, g; floor_cross_terms, shell_kscale, floor_mscale, floor_block=fb)
    Mass_exact = floor_cross_terms ? Mass :
        _appd_assemble_KM(b, g; floor_cross_terms=true, shell_kscale, floor_mscale, floor_block=fb)[2]
    red = _appd_reduce(K, Mass, _appd_all_constraints(b, g; rigid=rigid))
    red === nothing && return nothing
    Kr, Mr, E = red
    F = try
        eigen(Symmetric(Kr), Symmetric(Mr))
    catch
        return nothing
    end
    keep = findall(≥(1.0), F.values)
    return (; b, K, Mass, Mass_exact, ω2=F.values[keep], f_Hz=sqrt.(F.values[keep]) ./ 2π, Q=E * F.vectors[:, keep])
end

"""Shell share of a mode's kinetic (`Mass`) or strain (`K`) energy: shell DOFs over the total (Phase 80)."""
function _appd_shell_share(q::AbstractVector, b::_AppDBasis, A::AbstractMatrix)
    s = 1:3b.ns
    return dot(q[s], A[s, s] * q[s]) / dot(q, A * q)
end

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

"""
    appd_modes(geometry; n_modes=32, n_axial=10, n_circ=12, n_floor_max=5, floor_cross_terms=false, …)

Appendix D Rayleigh–Ritz eigenmodes (Eqs. D.17–D.26). Returns `StructuralModes`
usable as `inp.structural`. No parameter is fitted to Table D-1.

`floor_cross_terms=false` (default) is NASA's program: the floor stiffness and mass keep only the diagonal of each
spanwise term; on NASA's deck (`appd_nasa_deck()`) this reproduces Table D-1. `true` adds the cross terms between floor
terms of different parity (the exact Ritz energy of the same basis). Either way M_r is the generalized mass of the
returned shape with the exact floor integral, as Table D-1's TOTAL MASS is (Phase 80, 2026-10-29).
"""
function appd_modes(geometry::AbstractAppDInput;
                    n_modes::Int=32,
                    n_axial::Int=10,     # series limits NASA ran the test article with (User Manual card 8,
                    n_circ::Int=12,      # pp. 42-43): M 1-10, ns 0-12, np 0-5 (Phase 80, 2026-10-29; was 6, 8, 5)
                    n_floor_max::Int=5,
                    include_antisym::Bool=true,
                    rigid::Bool=true,
                    floor_cross_terms::Bool=false,
                    f_max_Hz::Float64=5000.0)
    cands = NamedTuple[]
    for M in 1:n_axial
        for sym in (true, false)
            sym || include_antisym || continue
            fam = _appd_family(geometry, M, sym; n_circ, n_floor_max, rigid, floor_cross_terms)
            fam === nothing && continue
            b, Mass = fam.b, fam.Mass_exact
            for (ei, f) in enumerate(fam.f_Hz)
                f > f_max_Hz && continue
                q = fam.Q[:, ei]
                # Rayleigh mass with unconstrained M*
                Mr_raw = abs(dot(q, Mass * q))
                Cs, ns, Cf, nf, Mr_n = _appd_extract_shapes(q, b, geometry, Mr_raw)
                (isempty(Cs) && isempty(Cf)) && continue
                push!(cands, (; f, sym, Mr=Mr_n, m=M, C_shell=Cs, n_shell=ns,
                               C_floor=Cf, n_floor=nf, q=q, key=(M, sym)))
            end
        end
    end
    sort!(cands; by=c -> c.f)
    # No frequency dedup (Phase 78d-4 J4): the (M, parity) families are disjoint, so close frequencies are distinct
    # modes (near-degenerate symmetric/antisymmetric pairs). Until 2026-10-28 a 0.5 % dedup dropped one of them.
    uniq = cands
    nkeep = min(n_modes, length(uniq))
    modes = StructuralMode[]
    for (i, c) in enumerate(uniq[1:nkeep])
        push!(modes, StructuralMode(i, c.f, c.sym, max(c.Mr, 1e-9), c.m,
            collect(c.C_shell), collect(c.n_shell),
            collect(c.C_floor), collect(c.n_floor)))
    end
    notes = "App. D Eqs. (D.17)–(D.26) Ritz; rigid=$(rigid); no fitted scale; " *
            "L=$(geometry.L) (text App. E); readings=$(APPD_READINGS.d25_thickness_rule)"
    return StructuralModes(modes, geometry.L, geometry.a, geometry.theta0_deg, notes)
end

appd_modes(fuse::FuselageGeometry; kwargs...) =
    appd_modes(AppDGeometry(fuse); kwargs...)

"""
Build the structural mode set for the pipeline.
`structural_solver = :table_d1` (default) | `:ritz` | `:appd`.

For `:appd`, pass `appd_geometry` (phase 30c) built from the aircraft JSON / fuse;
when omitted, `AppDGeometry(fuse)` uses MRP_* defaults (no hard-coded 0.508/1.83 —
L, a, θ0 come from `fuse`).
"""
function build_structural_modes(fuse::FuselageGeometry;
                                structural_solver::Symbol=:table_d1,
                                n_keep::Int=32,
                                appd_geometry::Union{Nothing,AbstractAppDInput}=nothing)
    if structural_solver === :table_d1 || structural_solver === :d1
        return structural_modes_from_table_d1(; L=fuse.L, a=fuse.a,
                                              theta0_deg=fuse.theta0_deg, n_keep=n_keep)
    elseif structural_solver === :ritz || structural_solver === :surrogate
        return structural_modes(fuse; n_keep=n_keep)
    elseif structural_solver === :appd
        g = appd_geometry === nothing ? AppDGeometry(fuse) : appd_geometry
        sm = appd_modes(g; n_modes=n_keep)
        w = appd_input_warnings(g, sm)
        isempty(w) || @warn join(w, "\n")     # one message: a per-line maxlog would drop all but the first
        return sm
    else
        error("unknown structural_solver=$structural_solver (use :table_d1, :ritz, :appd)")
    end
end

"""
Inputs outside the App. D model's assumptions, as messages (Phase 80e; never alters an input): a / t < 20 (thin
shell), θ0 outside 0°–90° (floor and junction defined for a floor below the axis), and for stiffener sections
(`AppDGeometry`) the smearing assumption: frame spacing above a quarter of a mode's axial wavelength 2L/M, or stringer
spacing above a quarter of its circumferential wavelength 2πa/n (n the mode's largest shell term), counted over `sm`.
"""
function appd_input_warnings(g::AbstractAppDInput, sm::Union{Nothing,StructuralModes}=nothing)
    w = String[]
    t = g isa AppDDeck ? g.t_shell : g.t_skin
    g.a / t < 20 && push!(w, "App. D: a / t = $(round(g.a / t; digits=1)) < 20, outside thin-shell theory")
    0 < g.theta0_deg < 90 || push!(w, "App. D: floor angle θ0 = $(g.theta0_deg)° outside 0°–90°")
    if g isa AppDGeometry && sm !== nothing && !isempty(sm.modes)
        nf = count(m -> g.ell_frame > (2g.L / m.M_axial) / 4, sm.modes)
        ns = count(m -> !isempty(m.n_shell) && (n = m.n_shell[argmax(abs.(m.C_shell))]) > 0 &&
                        g.d_stringer > (2π * g.a / n) / 4, sm.modes)
        nf > 0 && push!(w, "App. D smearing: frame spacing $(g.ell_frame) m exceeds a quarter of the axial wavelength in $nf of $(length(sm.modes)) modes")
        ns > 0 && push!(w, "App. D smearing: stringer spacing $(round(g.d_stringer; digits=4)) m exceeds a quarter of the circumferential wavelength in $ns of $(length(sm.modes)) modes")
    end
    return w
end

# ---------------------------------------------------------------------------
# Helpers used by V-UNIT / MRP_APPD
# ---------------------------------------------------------------------------

"""Generalized mass ∫ ρ φ² dA of the normal displacement from returned shape coefficients, over the cabin shell arc
and the floor (w only; the solver's `M_r` is qᵀMq over u, v, w of the whole circumference, (D.30), Phase 78d-4)."""
function appd_generalized_mass_from_shape(mode::StructuralMode, g::AbstractAppDInput)
    sp = _appd_shell_props(g)
    fp = _appd_floor_props(g)
    θ0 = deg2rad(g.theta0_deg)
    L = g.L
    a = g.a
    Lp = fp.Lp
    M = mode.M_axial
    # ∫_0^L sin²(Mπz/L) dz = L/2
    Iz = L / 2
    Mr = 0.0
    # Shell: ψ = axial * circ; ∫ ρ w² a dθ dz over arc
    nθ = 360
    dθ = (2π - 2θ0) / nθ
    for k in 0:nθ-1
        θ = θ0 + (k + 0.5) * dθ
        w = shell_circumferential(mode, θ)
        Mr += sp.ms * w^2 * a * dθ * Iz
    end
    nx = 80
    dx = Lp / nx
    for i in 0:nx-1
        x = -Lp / 2 + (i + 0.5) * dx
        s = 0.0
        for (C, n) in zip(mode.C_floor, mode.n_floor)
            s += mode.symmetric ? C * cos(n * π * x / Lp) : C * sin(n * π * x / Lp)
        end
        Mr += fp.mf * s^2 * dx * Iz
    end
    return Mr
end

"""
Smeared-stiffener analytic estimate for a closed cylinder (unit test 2).
Donnell–Mushtari with membrane/mass from t_eq and bending rigidity D_xs of (D.24)
(actual-skin D + EI/d), matching the App. D third-diagonal rule on p. D-10.
"""
function appd_smeared_stringer_frequency_Hz(m, n, g::AppDGeometry)
    sp = _appd_shell_props(g)
    a = g.a
    λ = m * π * a / g.L
    β2 = (λ^2 + n^2)^2
    # ms = ρ t_eq; membrane term uses E/(ρ a²) as in Soedel (effective Et / (ρ t))
    ω2 = (sp.D_xs / (sp.ms * a^4)) * β2 + (g.E / (g.ρ * a^2)) * λ^4 / max(β2, 1e-30)
    return sqrt(ω2) / (2π)
end

"""
Max |C q| over the lowest `n_check` modes of each (M, parity) family (Eq. D.17).
Used by V-UNIT; the reduction forces these to numerical nullspace tolerance.
"""
function appd_max_constraint_residual(g::AbstractAppDInput;
                                      n_axial::Int=4, n_circ::Int=8, n_floor_max::Int=5,
                                      n_check::Int=5, rigid::Bool=true)
    worst = 0.0
    for M in 1:n_axial, sym in (true, false)
        b = _appd_basis(M, sym; n_circ=n_circ, n_floor_max=n_floor_max)
        K, Mass, _, _ = _appd_assemble_KM(b, g)
        C = _appd_all_constraints(b, g; rigid=rigid)
        red = _appd_reduce(K, Mass, C)
        red === nothing && continue
        Kr, Mr, E = red
        F = eigen(Symmetric(Kr), Symmetric(Mr))
        n_ok = 0
        for (ei, ω2) in enumerate(F.values)
            ω2 < 1.0 && continue
            q = E * F.vectors[:, ei]
            worst = max(worst, maximum(abs, C * q))
            n_ok += 1
            n_ok ≥ n_check && break
        end
    end
    return worst
end

"""Mass-matrix orthogonality max |q_iᵀ M q_j| / √(Mii Mjj) for i≠j in one family."""
function appd_mode_orthogonality(g::AbstractAppDInput; M::Int=1, sym::Bool=true,
                                 n_circ::Int=8, n_floor_max::Int=5, n_modes::Int=6,
                                 rigid::Bool=true)
    b = _appd_basis(M, sym; n_circ=n_circ, n_floor_max=n_floor_max)
    K, Mass, _, _ = _appd_assemble_KM(b, g)
    C = _appd_all_constraints(b, g; rigid=rigid)
    Kr, Mr, E = _appd_reduce(K, Mass, C)
    F = eigen(Symmetric(Kr), Symmetric(Mr))
    qs = Vector{Float64}[]
    for (ei, ω2) in enumerate(F.values)
        ω2 < 1.0 && continue
        push!(qs, E * F.vectors[:, ei])
        length(qs) ≥ n_modes && break
    end
    worst = 0.0
    for i in 1:length(qs), j in i+1:length(qs)
        mi = abs(dot(qs[i], Mass * qs[i]))
        mj = abs(dot(qs[j], Mass * qs[j]))
        cross = abs(dot(qs[i], Mass * qs[j]))
        worst = max(worst, cross / max(sqrt(mi * mj), 1e-30))
    end
    return worst
end
