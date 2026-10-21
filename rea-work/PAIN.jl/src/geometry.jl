"""Fuselage cylinder + floor angle (User Manual / CR-3813 Fig. 1)."""
struct FuselageGeometry
    L::Float64          # cylinder length [m]
    a::Float64          # radius [m]
    theta0_deg::Float64 # floor angle θ₀ [deg]
end

"""Propeller hub placement relative to fuselage (User Manual Fig. 2)."""
struct PropellerPlacement
    r_p::Float64   # radial distance hub→fuselage axis [m]
    phi_p_deg::Float64  # angular position from bottom [deg]
    z_p::Float64   # axial hub position [m]
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

Line ℓ = 1 lies at the propeller azimuth, θ_ℓ = φ_p + (ℓ−1)π/18, with ℓ increasing
upward (User Manual p. 34 card-36 note and Figs. 2–3: the grid covers the upper quarter
of the skin). `alpha_deg = (ℓ−1)·10°` is the angle from line ℓ = 1 and is what the
free-field grid extension and the synthetic surrogate use for the falloff.
"""
function grid_points(fuse::FuselageGeometry, prop::PropellerPlacement, spec::GridSpec=GridSpec())
    a = fuse.a
    rp = prop.r_p
    zp = prop.z_p
    phi_p = deg2rad(prop.phi_p_deg)
    pts = NamedTuple{(:k, :ell, :x1, :x2, :x3, :theta_deg, :alpha_deg, :z),
                     Tuple{Int,Int,Float64,Float64,Float64,Float64,Float64,Float64}}[]
    for k in 1:spec.k_max
        for ell in 1:spec.ell_max
            alpha = (ell - 1) * π / 18
            x1 = (rp - a) + a * (1 - cos(alpha))
            x2 = -a * sin(alpha)
            x3 = (π * a / 18) * (spec.k_p - k)
            # θ measured from the bottom centerline; ℓ = 1 at the propeller azimuth φ_p
            theta = phi_p + alpha
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
