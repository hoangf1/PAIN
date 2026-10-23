# Phase 48b — propeller broadband self-noise at a field point from blade-segment BPM (RP-1218 §5),
# summed over blade segments, azimuths and blades with the Doppler shift, as in RP-1218 App. C
# (10 radial × 16 azimuthal segments; untripped boundary layers; aerodynamic angle for the boundary
# layer and TBL-TE, geometric angle for LBL-VS; tip noise from the outermost segment; no bluntness).

"""
    propeller_broadband_spectrum(cfg, af, observer; nψ=16, freqs=bpm_frequencies(), lbl=true, tip=true,
                                 trip=:untripped, rounded_tip=true) -> NamedTuple

`cfg` is a CCBlade propeller configuration (as `_r996_cfg`), `af` its polar function, and `observer`
the point (x, y, z) [m] in the propeller frame: z along the axis in the inflow direction, the
propeller plane at z = 0. Returns per-mechanism and total 1/3-octave SPL [dB] at the observer
(energy average over one revolution, all blades).
"""
function propeller_broadband_spectrum(cfg, af, observer::NTuple{3,<:Real}; nψ::Int=16,
                                      freqs=bpm_frequencies(), lbl::Bool=true, tip::Bool=true,
                                      trip::Symbol=:untripped, rounded_tip::Bool=true,
                                      ν::Real=1.4529e-5)
    ops = ccblade_section_operating_points(cfg; af=af)
    Ω = ops.rpm * 2π / 60
    V = ops.Vinf
    c0 = ops.c0
    r = ops.r_m
    dr = [i == 1 ? (r[2] - r[1]) / 2 + (r[1] - cfg.propeller.hub_radius_m) :
          i == length(r) ? (ops.Rtip - r[end]) + (r[end] - r[end-1]) / 2 : (r[i+1] - r[i-1]) / 2 for i in eachindex(r)]
    # aerodynamic angle: α − α_L0 with α_L0 from the section polar (c_l = 0 crossing, linear near α)
    α_aero = similar(r)
    for i in eachindex(r)
        Re, M = ops.Re[i], ops.Mach[i]
        cl0 = af(0.0, Re, M)[1]
        cl1 = af(deg2rad(2.0), Re, M)[1]
        αL0 = -2.0 * cl0 / (cl1 - cl0)             # degrees
        α_aero[i] = ops.alpha_deg[i] - αL0
    end
    O = collect(float.(observer))
    nf = length(freqs)
    Pp = zeros(nf); Ps = zeros(nf); Pa = zeros(nf); Pl = zeros(nf); Pt = zeros(nf)
    for k in 1:nψ
        ψ = 2π * (k - 1) / nψ
        er = [cos(ψ), sin(ψ), 0.0]; et = [-sin(ψ), cos(ψ), 0.0]
        for i in eachindex(r)
            P = r[i] .* er
            w = V .* [0.0, 0.0, 1.0] .- (Ω * r[i]) .* et          # air relative to the blade
            U = sqrt(sum(abs2, w))
            x̂ = w ./ U
            n = O .- P; d = sqrt(sum(abs2, n)); n̂ = n ./ d
            Θ = acosd(clamp(sum(n̂ .* x̂), -1, 1)); Φ = acosd(clamp(sum(n̂ .* er), -1, 1))
            dop = 1 + (U / c0) * sum(n̂ .* x̂)                    # 1 − M_r, source moving with −w through the air
            αa = max(α_aero[i], 0.0)
            for (j, F) in enumerate(freqs)
                fs = F * dop                                       # source frequency heard at F
                t = bpm_tbl_te(fs, ops.chord_m[i], dr[i], d, Θ, Φ, αa, U; c0, ν, trip)
                Pp[j] += 10^(t.p / 10); Ps[j] += 10^(t.s / 10); Pa[j] += 10^(t.α / 10)
                lbl && (Pl[j] += 10^(bpm_lbl_vs(fs, ops.chord_m[i], dr[i], d, Θ, Φ, max(ops.alpha_deg[i], 0.0), U;
                                               c0, ν, trip, α_bl=αa) / 10))
                if tip && i == length(r)
                    Pt[j] += 10^(bpm_tip(fs, ops.chord_m[i], d, Θ, Φ, αa, U; c0, rounded=rounded_tip) / 10)
                end
            end
        end
    end
    B = ops.B
    scale = B / nψ                                                 # revolution average × blades
    dB(x) = _bpm_dB(x * scale)
    tot = Pp .+ Ps .+ Pa .+ Pl .+ Pt
    return (; f=collect(float.(freqs)), p=dB.(Pp), s=dB.(Ps), α=dB.(Pa), lbl=dB.(Pl), tip=dB.(Pt), total=dB.(tot),
            ops, α_aero)
end

"""
CCBlade configuration of the TP-2444 / CR-172428 test propeller with the V-ASSUMED blade: the NACA
4-(5)(08)-03 planform of Report 996 (NACA 16-series sections, as the test propeller's Series 16), scaled
to D = 0.762 m, 3 blades, β(0.75R) = 20° (CR-172428 p. 17), 23.8 m/s inflow (CR-172428 p. 17). The real
blade geometry is proprietary (CR-172428 p. 56; CR-3813 p. E-5).
"""
function p48_propeller_cfg(rpm::Real)
    D = 0.762
    g = blade_form_geometry(_data_path(splitpath(_R996_BLADE_FORM)...); D=D, beta75_target_deg=20.0)
    return (
        propeller=(num_blades=3, tip_radius_m=g.R, hub_radius_m=g.radii_m[1], rpm=Float64(rpm),
                   thickness_over_chord=0.0, pitch_offset_deg=0.0, radii_m=collect(g.radii_m),
                   chord_m=collect(g.chord_m), twist_deg=collect(g.twist_deg)),
        operating_point=(forward_speed_mps=23.8, rho_kg_m3=1.225, c0_mps=340.3),
        anopp_table8_calibrate=false,
    )
end
