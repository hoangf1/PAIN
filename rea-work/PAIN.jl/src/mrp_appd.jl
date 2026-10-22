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
    # Length: App. E p. E-1 prints 1.83 m (72 in.); `mrp.jl` uses 1.803.
    # Spec: use the text when they differ.
    L_source = "App. E p. E-1: 1.83 m",
    # Material: App. E p. E-3 "2024-T3 aluminum"; E, ν, ρ from Manual §5.2 /
    # existing MRP_* (no separate printed E in App. D).
    material_source = "MRP_E_2024 / MRP_NU_2024 / MRP_RHO_2024 (Manual §5.2)",
    # Constraint reduction: nullspace of [C] (Eq. D.17) ≡ [E] of (D.20) after
    # column partition into independent/dependent sets.
    constraint_reduction = :nullspace_of_C,
)

"""Geometry / material inputs for the App. D solver (any fuselage, not only the test article)."""
struct AppDGeometry
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
Default L = 1.83 m from the text (not the program's 1.803). When the test-article
length override is set (`set_test_article_length!`), L follows that override
(post-hoc sensitivity; no length selected from any error).
"""
function appd_test_article_geometry()
    L = test_article_length_overridden() ? test_article_length() : 1.83
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
    # Smeared transverse supports @ frame pitch + two longitudinal beams (App. E Fig. E-2)
    Df = D_f_skin +
         g.E * g.I_floor_beam / max(g.ell_frame, 1e-12) +
         2 * g.E * g.I_floor_beam / max(Lp, 1e-12)
    G = g.E / (2 * (1 + g.ν))
    mf = g.ρ * t_eq_f
    return (; Lp, t_eq_f, k_f, Df, Gt=G * t_eq_f, Gt3=G * t_eq_f^3 / 12, mf, ν=g.ν)
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
function appd_shell_harmonic_frequency_Hz(M::Int, n::Int, g::AppDGeometry)
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
function appd_shell_condensed_frequency_Hz(M::Int, n::Int, g::AppDGeometry)
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
    Df = fp.Df
    ν = fp.ν
    Ix = L / 2
    # ∫_{-Lp/2}^{Lp/2} cos²(pπy/Lp) dy = Lp/2 (p>0), Lp (p=0); same for sin (p≥1)
    if sym
        p < 0 && error("symmetric floor p ≥ 0")
        Iy = p == 0 ? Lp : Lp / 2
    else
        p < 1 && error("antisymmetric floor p ≥ 1")
        Iy = Lp / 2
    end
    ky = p * π / Lp   # wave number; p=0 → 0

    K = zeros(3, 3)
    # Membrane: u = U cos(μx) Ψ_u(y), v = V sin(μx) Ψ_v(y) — same amplitude convention as shell
    S = Ix * Iy
    K[1, 1] += kx * μ^2 * S
    if ky > 0
        K[2, 2] += kx * ky^2 * S
        K[1, 2] += -ν * kx * μ * ky * S
        K[2, 1] += -ν * kx * μ * ky * S
        K[1, 1] += Gt * ky^2 * S
        K[2, 2] += Gt * μ^2 * S
    else
        K[2, 2] += Gt * μ^2 * S + 1e-18
    end
    # Kirchhoff bending of w
    K[3, 3] += Df * (μ^2 + ky^2)^2 * S

    Mass = zeros(3, 3)
    Mass[1, 1] = fp.mf * S
    Mass[2, 2] = fp.mf * S
    Mass[3, 3] = fp.mf * S
    return K, Mass
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
    ns_list = collect(0:n_circ)
    ps = collect(sym ? (0:n_floor_max) : (1:n_floor_max))
    ns = length(ns_list)
    np = length(ps)
    return _AppDBasis(M, sym, ns_list, ps, ns, np, 3ns + 3np)
end

_shell_dof(b::_AppDBasis, i_n::Int, comp::Int) = 3 * (i_n - 1) + comp          # 1:U 2:V 3:W
_floor_dof(b::_AppDBasis, i_p::Int, comp::Int) = 3 * b.ns + 3 * (i_p - 1) + comp

function _appd_assemble_KM(b::_AppDBasis, g::AppDGeometry)
    sp = _appd_shell_props(g)
    fp = _appd_floor_props(g)
    θ0 = deg2rad(g.theta0_deg)
    Θ_arc = 2π - 2θ0
    arc_frac = Θ_arc / (2π)
    N = b.ndof
    K = zeros(N, N)
    M = zeros(N, N)
    # Shell harmonics on the open arc (scale full-circle energy by arc_frac).
    # Distinct n are orthogonal on a full circle; on an arc they weakly couple
    # through the truncated integral. Reading: keep diagonal (orthogonal) terms
    # only — the leading Peterson diagonal — and enforce junction coupling via
    # (D.17) constraints. Off-diagonal n↔n′ arc coupling omitted (stated below).
    for (i, n) in enumerate(b.n_shell)
        K3, M3 = _appd_shell_harmonic_KM(b.M, n, g.L, sp; arc_frac=arc_frac)
        for c1 in 1:3, c2 in 1:3
            K[_shell_dof(b, i, c1), _shell_dof(b, i, c2)] += K3[c1, c2]
            M[_shell_dof(b, i, c1), _shell_dof(b, i, c2)] += M3[c1, c2]
        end
    end
    for (j, p) in enumerate(b.p_floor)
        K3, M3 = _appd_floor_harmonic_KM(b.M, p, g.L, fp, b.sym)
        for c1 in 1:3, c2 in 1:3
            K[_floor_dof(b, j, c1), _floor_dof(b, j, c2)] += K3[c1, c2]
            M[_floor_dof(b, j, c1), _floor_dof(b, j, c2)] += M3[c1, c2]
        end
    end
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
function _appd_constraint_matrix(b::_AppDBasis, g::AppDGeometry; rigid::Bool=true)
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
            yv = cos(p * π / 2)       # choose cos so edge is generally nonzero
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
function appd_constraint_residuals(q::AbstractVector, b::_AppDBasis, g::AppDGeometry; rigid::Bool=true)
    C = _appd_constraint_matrix(b, g; rigid=rigid)
    return C * q
end

# ---------------------------------------------------------------------------
# Shape extraction → StructuralMode fields (Eqs. D.26–D.29)
# ---------------------------------------------------------------------------
function _appd_extract_shapes(q::AbstractVector, b::_AppDBasis, g::AppDGeometry, Mr::Float64)
    # Paper p. D-10 / (D.26)–(D.27): C_n are the same as the W_Mn of (D.7).
    # Downstream `shell_circumferential` applies Σ C (−1)^n cos/sin as printed.
    C_shell = Float64[]
    n_shell = Int[]
    for (i, n) in enumerate(b.n_shell)
        W = q[_shell_dof(b, i, 3)]
        abs(W) < 1e-14 && continue
        push!(C_shell, W)
        push!(n_shell, n)
    end
    C_floor = Float64[]
    n_floor = Int[]
    for (j, p) in enumerate(b.p_floor)
        W = q[_floor_dof(b, j, 3)]
        abs(W) < 1e-14 && continue
        # (D.28)–(D.29): C_Mn are the floor W amplitudes (positive upward / inward).
        push!(C_floor, W)
        push!(n_floor, p)
    end
    # Normalize max |normal displacement| = 1 (p. D-10)
    θ0 = deg2rad(g.theta0_deg)
    Lp = 2 * g.a * sin(θ0)
    peak = 0.0
    for θ in range(θ0, 2π - θ0; length=181)
        s = 0.0
        for (C, n) in zip(C_shell, n_shell)
            s += b.sym ? C * (-1)^n * cos(n * θ) : -C * (-1)^n * sin(n * θ)
        end
        peak = max(peak, abs(s))
    end
    for x in range(-Lp / 2, Lp / 2; length=81)
        s = 0.0
        for (C, n) in zip(C_floor, n_floor)
            s += b.sym ? C * cos(n * π * x / Lp) : C * sin(n * π * x / Lp)
        end
        peak = max(peak, abs(s))
    end
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
    Cs, ns = topk(C_shell, n_shell, 8)
    Cf, nf = topk(C_floor, n_floor, 5)
    return Cs, ns, Cf, nf, Mr
end

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

"""
    appd_modes(geometry; n_modes=32, n_axial=6, n_circ=8, n_floor_max=5, …)

Appendix D Rayleigh–Ritz eigenmodes (Eqs. D.17–D.26). Returns `StructuralModes`
usable as `inp.structural`. No parameter is fitted to Table D-1.
"""
function appd_modes(geometry::AppDGeometry;
                    n_modes::Int=32,
                    n_axial::Int=6,
                    n_circ::Int=8,
                    n_floor_max::Int=5,
                    include_antisym::Bool=true,
                    rigid::Bool=true,
                    f_max_Hz::Float64=5000.0)
    cands = NamedTuple[]
    basis_by_key = Dict{Tuple{Int,Bool},_AppDBasis}()
    qfull_by_cand = Vector{Float64}[]   # kept only transiently for constraint checks
    for M in 1:n_axial
        for sym in (true, false)
            sym || include_antisym || continue
            b = _appd_basis(M, sym; n_circ=n_circ, n_floor_max=n_floor_max)
            basis_by_key[(M, sym)] = b
            K, Mass, _, _ = _appd_assemble_KM(b, geometry)
            C = _appd_constraint_matrix(b, geometry; rigid=rigid)
            red = _appd_reduce(K, Mass, C)
            red === nothing && continue
            Kr, Mr, E = red
            local F
            try
                F = eigen(Symmetric(Kr), Symmetric(Mr))
            catch
                continue
            end
            for (ei, ω2) in enumerate(F.values)
                ω2 < 1.0 && continue
                f = sqrt(ω2) / (2π)
                f > f_max_Hz && continue
                q1 = F.vectors[:, ei]
                q = E * q1
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
    # Deduplicate near-coincident frequencies from overlapping bases
    uniq = NamedTuple[]
    for c in cands
        if isempty(uniq) || abs(c.f - uniq[end].f) / max(c.f, 1.0) > 0.005
            push!(uniq, c)
        end
    end
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
"""
function build_structural_modes(fuse::FuselageGeometry;
                                structural_solver::Symbol=:table_d1,
                                n_keep::Int=32)
    if structural_solver === :table_d1 || structural_solver === :d1
        return structural_modes_from_table_d1(; L=fuse.L, a=fuse.a,
                                              theta0_deg=fuse.theta0_deg, n_keep=n_keep)
    elseif structural_solver === :ritz || structural_solver === :surrogate
        return structural_modes(fuse; n_keep=n_keep)
    elseif structural_solver === :appd
        # Test-article defaults use App. E length 1.83 m when fuse still carries 1.803
        g = appd_test_article_geometry()
        if abs(fuse.L - g.L) > 1e-9 || abs(fuse.a - g.a) > 1e-9 ||
           abs(fuse.theta0_deg - g.theta0_deg) > 1e-9
            g = AppDGeometry(fuse)
        end
        return appd_modes(g; n_modes=n_keep)
    else
        error("unknown structural_solver=$structural_solver (use :table_d1, :ritz, :appd)")
    end
end

# ---------------------------------------------------------------------------
# Helpers used by V-UNIT / MRP_APPD
# ---------------------------------------------------------------------------

"""Generalized mass ∫ ρ φ² dA from returned shape coefficients (shell arc + floor)."""
function appd_generalized_mass_from_shape(mode::StructuralMode, g::AppDGeometry)
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
function appd_max_constraint_residual(g::AppDGeometry;
                                      n_axial::Int=4, n_circ::Int=8, n_floor_max::Int=5,
                                      n_check::Int=5, rigid::Bool=true)
    worst = 0.0
    for M in 1:n_axial, sym in (true, false)
        b = _appd_basis(M, sym; n_circ=n_circ, n_floor_max=n_floor_max)
        K, Mass, _, _ = _appd_assemble_KM(b, g)
        C = _appd_constraint_matrix(b, g; rigid=rigid)
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
function appd_mode_orthogonality(g::AppDGeometry; M::Int=1, sym::Bool=true,
                                 n_circ::Int=8, n_floor_max::Int=5, n_modes::Int=6,
                                 rigid::Bool=true)
    b = _appd_basis(M, sym; n_circ=n_circ, n_floor_max=n_floor_max)
    K, Mass, _, _ = _appd_assemble_KM(b, g)
    C = _appd_constraint_matrix(b, g; rigid=rigid)
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
