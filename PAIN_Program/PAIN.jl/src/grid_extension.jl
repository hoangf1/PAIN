"""
Assumed grid extension from on-line (ℓ = 1) free-field amplitudes
to the full 160-point grid (flowchart GEXT).

**e11 validation path only.** The aircraft source path evaluates F1A at all 160
points and does not call this function (phase 21).

Physics class: **V-ASSUMED** — no off-line measured field in the NASA reports.
Unit tests verify code (falloff at 0/45/90°, phase sign), not physics.

Model (flowchart): cosine amplitude falloff with peripheral angle +
geometric phase delay from hub path-length difference.
"""

"""
    extend_line_to_grid(line_amps, line_phases, pts; hub_xyz, c0=340.0)

`line_amps[k, H]` and `line_phases[k, H]` are free-field data on ℓ = 1.
`pts` from `grid_points`. Returns `(amps, phases)` arrays sized
`(k_max, ell_max, nH)`.

Importance-bound options (`VALIDATION_GUIDELINE.md` §2.2.1). The defaults are the
nominal GEXT and reproduce it exactly (identity control); they are not fitted
parameters and must not be tuned to Fig. E-16 or E-9:

- `falloff_exponent` n: amplitude falloff is `max(max(cos θ, 0)^n, falloff_floor)`.
  n = 1 is nominal; n = 0 is flat.
- `falloff_floor` f in [0, 1]: lower bound on the falloff. 0 is the nominal hard clip.
- `delay_scale`: multiplies the geometric phase delay. 1 nominal, 0 off, −1 sign flip.
"""
function extend_line_to_grid(line_amps::AbstractArray{<:Real,2},
                             line_phases::AbstractArray{<:Real,2},
                             pts;
                             hub_xyz::NTuple{3,Float64}=(0.0, 0.0, 0.0),
                             c0::Float64=340.0,
                             omega_H::AbstractVector{<:Real}=Float64[],
                             falloff_exponent::Float64=1.0,
                             falloff_floor::Float64=0.0,
                             delay_scale::Float64=1.0)
    falloff_exponent >= 0 || throw(ArgumentError("falloff_exponent must be ≥ 0"))
    0.0 <= falloff_floor <= 1.0 || throw(ArgumentError("falloff_floor must be in [0, 1]"))
    k_max = size(line_amps, 1)
    nH = size(line_amps, 2)
    ell_max = maximum(p.ell for p in pts)
    amps = zeros(Float64, k_max, ell_max, nH)
    phases = zeros(Float64, k_max, ell_max, nH)

    # Reference path length on ℓ = 1 for each k (use first matching point)
    ref_R = Dict{Int,Float64}()
    for p in pts
        if p.ell == 1 && !haskey(ref_R, p.k)
            # Reconstruct approximate Cartesian from ANOPP x1,x2,x3 relative to hub
            # Use x1 as radial tip-clearance direction proxy for path length
            ref_R[p.k] = hypot(p.x1, p.x2, p.x3)
        end
    end

    for p in pts
        α = deg2rad(p.alpha_deg)  # angle from line ℓ = 1 (α = θ − φ_p)
        falloff = cos(α)  # 1 at ℓ=1 (α=0), 0 at 90°
        falloff = max(falloff, 0.0)
        # n = 1 keeps the nominal value bit-for-bit; otherwise cos^n, then the floor.
        falloff_exponent == 1.0 || (falloff = falloff^falloff_exponent)
        falloff = max(falloff, falloff_floor)
        R = hypot(p.x1, p.x2, p.x3)
        R0 = get(ref_R, p.k, R)
        for H in 1:nH
            A0 = line_amps[p.k, H]
            ϕ0 = line_phases[p.k, H]
            amps[p.k, p.ell, H] = A0 * falloff
            if isempty(omega_H)
                phases[p.k, p.ell, H] = ϕ0
            else
                # Geometric phase: Δϕ = ω (R − R0) / c0  (sign convention: delay)
                phases[p.k, p.ell, H] = ϕ0 - delay_scale * omega_H[H] * (R - R0) / c0
            end
        end
    end
    return amps, phases
end
