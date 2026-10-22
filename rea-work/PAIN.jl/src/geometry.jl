# Test-article cylinder length [m]. I-22 decision 2026-10-22: default is 1.83 m (72 in.)
# from App. D body / App. E / validation report. Table D-1 title prints 1.803 m (71 in.)
# — read as a caption typo (see digitized_table_D1.csv header / data README). Override
# `TEST_ARTICLE_L` remains for sensitivity; no length is selected from any error.
const TEST_ARTICLE_L_DEFAULT = 1.83
const TEST_ARTICLE_L = Ref(TEST_ARTICLE_L_DEFAULT)
const _TEST_ARTICLE_L_OVERRIDE = Ref(false)

"""Current test-article length [m] (default 1.83)."""
test_article_length() = TEST_ARTICLE_L[]

"""True when `set_test_article_length!` has been called and not yet reset."""
test_article_length_overridden() = _TEST_ARTICLE_L_OVERRIDE[]

"""Set the test-article length override. Restore with `reset_test_article_length!`."""
function set_test_article_length!(L::Real)
    TEST_ARTICLE_L[] = float(L)
    _TEST_ARTICLE_L_OVERRIDE[] = true
    return TEST_ARTICLE_L[]
end

"""Restore the default test-article length (1.83 m) and clear the override flag."""
function reset_test_article_length!()
    TEST_ARTICLE_L[] = TEST_ARTICLE_L_DEFAULT
    _TEST_ARTICLE_L_OVERRIDE[] = false
    return TEST_ARTICLE_L[]
end

"""Run `f()` with test-article length `L`, restoring the prior value afterwards (even on error)."""
function with_test_article_length(f::Function, L::Real)
    old_L = TEST_ARTICLE_L[]
    old_set = _TEST_ARTICLE_L_OVERRIDE[]
    try
        set_test_article_length!(L)
        return f()
    finally
        TEST_ARTICLE_L[] = old_L
        _TEST_ARTICLE_L_OVERRIDE[] = old_set
    end
end

"""Fuselage cylinder + floor angle (User Manual / CR-3813 Fig. 1)."""
struct FuselageGeometry
    L::Float64          # cylinder length [m]
    a::Float64          # radius [m]
    theta0_deg::Float64 # floor angle θ₀ [deg]
end

"""Propeller hub placement relative to fuselage (User Manual Fig. 2 / card 36)."""
struct PropellerPlacement
    r_p::Float64   # radial distance hub→fuselage axis [m]
    phi_p_deg::Float64  # angular position from bottom [deg]
    z_p::Float64   # axial hub position [m]
    # Manual card 36 cols 51–60: +1 = CCW in +z (Fig. 3, current default);
    # −1 = CW in +z. Flips azimuth sense of the skin grid (θ_ℓ = φ_p ± α) and
    # the blade-passage phase sign; does **not** mirror onto the lower quarter.
    rotation_direction::Int
end

PropellerPlacement(r_p::Real, phi_p_deg::Real, z_p::Real) =
    PropellerPlacement(float(r_p), float(phi_p_deg), float(z_p), 1)

function PropellerPlacement(r_p::Real, phi_p_deg::Real, z_p::Real, rotation_direction::Integer)
    rd = Int(rotation_direction)
    abs(rd) == 1 || error("PropellerPlacement: rotation_direction must be ±1 (Manual card 36), got $rd")
    return PropellerPlacement(float(r_p), float(phi_p_deg), float(z_p), rd)
end

"""
PAIN/ANOPP fuselage-skin grid (User Manual Fig. 3).

Default `k_max = 16`, `ell_max = 10` → 160 points.
`k_p` is the axial index where x₁ pierces the skin (line ℓ = 1).
"""
struct GridSpec
    k_max::Int
    ell_max::Int
    k_p::Int
end

GridSpec() = GridSpec(16, 10, 8)

"""
    grid_points(fuse, prop, spec) -> Vector of NamedTuples

Return fuselage-skin grid points in a right-handed frame with cylinder
axis along z, θ = 0 at bottom centerline (CR-3813).

ANOPP-style coordinates from User Manual §3:
  x₁ = (r_p − a) + a (1 − cos[(ℓ−1)π/18])
  x₂ = −a sin[(ℓ−1)π/18]
  x₃ = (π a / 18) (k_p − k)

Line ℓ = 1 lies at the propeller azimuth. With `rotation_direction = +1` (Manual card 36,
Fig. 3): θ_ℓ = φ_p + (ℓ−1)π/18, ℓ increasing toward the top of the upper quarter.
With `rotation_direction = −1` (CW in +z): θ_ℓ = φ_p − (ℓ−1)π/18 and the ANOPP
circumferential coordinate x₂ flips sign — same upper-quarter grid, opposite azimuth
sense; not a lower-quarter mirror. `alpha_deg = (ℓ−1)·10°` is the unsigned angle from
line ℓ = 1 (falloff / GEXT); signed azimuth uses `rotation_direction`.
"""
function grid_points(fuse::FuselageGeometry, prop::PropellerPlacement, spec::GridSpec=GridSpec())
    a = fuse.a
    rp = prop.r_p
    zp = prop.z_p
    phi_p = deg2rad(prop.phi_p_deg)
    sense = prop.rotation_direction   # ±1
    pts = NamedTuple{(:k, :ell, :x1, :x2, :x3, :theta_deg, :alpha_deg, :z),
                     Tuple{Int,Int,Float64,Float64,Float64,Float64,Float64,Float64}}[]
    for k in 1:spec.k_max
        for ell in 1:spec.ell_max
            alpha = (ell - 1) * π / 18
            x1 = (rp - a) + a * (1 - cos(alpha))
            x2 = -sense * a * sin(alpha)
            x3 = (π * a / 18) * (spec.k_p - k)
            # θ from bottom centerline; ℓ = 1 at φ_p; sense flips azimuth of ℓ > 1
            theta = phi_p + sense * alpha
            z = zp + x3
            push!(pts, (; k, ell, x1, x2, x3, theta_deg=rad2deg(theta),
                        alpha_deg=rad2deg(alpha), z))
        end
    end
    return pts
end

"""
    incidence_angle_deg(fuse, prop, theta_deg, z) -> γ [deg]

Incidence angle γ between the surface→hub direction (the direction the wave arrives
from) and the local outward normal (CR-3813 §3.4 / Fig. 2): γ = 0 for normal incidence.
The hub lies outside the skin (r_p > a).
"""
function incidence_angle_deg(fuse::FuselageGeometry, prop::PropellerPlacement,
                             theta_deg::Float64, z::Float64)
    a = fuse.a
    θ = deg2rad(theta_deg)
    ϕ = deg2rad(prop.phi_p_deg)
    # Hub position in fuselage frame (θ=0 bottom)
    xh = prop.r_p * cos(ϕ)
    yh = prop.r_p * sin(ϕ)
    zh = prop.z_p
    # Surface point
    xs = a * cos(θ)
    ys = a * sin(θ)
    zs = z
    # Outward normal on cylinder
    nx, ny, nz = cos(θ), sin(θ), 0.0
    # Surface → hub (hub is outside the skin, so this points along the outward normal at γ = 0)
    rx, ry, rz = xh - xs, yh - ys, zh - zs
    rnorm = hypot(rx, ry, rz)
    rnorm == 0 && return 0.0
    cosγ = clamp((rx * nx + ry * ny + rz * nz) / rnorm, -1.0, 1.0)
    return rad2deg(acos(cosγ))
end
