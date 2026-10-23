# Phase 48 — airfoil self-noise (Brooks, Pope & Marcolini, NASA RP-1218, 1989).
# Equations of RP-1218 §5 (boundary-layer thickness Eqs. 2–11; TBL-TE Eqs. 24–49; LBL-VS Eqs. 53–60;
# tip vortex Eqs. 61–67; directivity App. B). Trailing-edge bluntness (Eqs. 70–82) is not implemented:
# the propeller trailing-edge thickness is not documented (V-ASSUMED sharp). Checked against the printed
# outputs of NASA's prediction code, RP-1218 App. D Tables D2 and D3 (criterion fixed 2026-10-23).

"""Standard 1/3-octave centres of the RP-1218 prediction code (Table D2): 100 Hz … 40 kHz."""
bpm_frequencies() = [100.0, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150,
                     4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000, 25000, 31500, 40000]

"""
    bpm_boundary_layer(c, U, α_deg; ν=1.4529e-5, trip=:untripped) -> (; δ_p, δs_p, δs_s, Rc)

Boundary-layer thickness δ and displacement thickness δ* at the trailing edge (RP-1218 Eqs. 2–11).
`trip` = `:tripped` (heavy), `:light` (δ* × 0.6, as the code's ITRIP = 2) or `:untripped`.
"""
function bpm_boundary_layer(c::Real, U::Real, α::Real; ν::Real=1.4529e-5, trip::Symbol=:untripped)
    Rc = U * c / ν
    lr = log10(Rc)
    if trip === :untripped
        δ0 = c * 10^(1.6569 - 0.9045lr + 0.0596lr^2)
        δs0 = c * 10^(3.0187 - 1.5397lr + 0.1059lr^2)
    else
        δ0 = c * 10^(1.892 - 0.9045lr + 0.0596lr^2)
        δs0 = c * (Rc ≤ 0.3e6 ? 0.0601 * Rc^(-0.114) : 10^(3.411 - 1.5397lr + 0.1059lr^2))
        trip === :light && (δs0 *= 0.6)
    end
    δ_p = δ0 * 10^(-0.04175α + 0.00106α^2)
    δs_p = δs0 * 10^(-0.0432α + 0.00113α^2)
    δs_s = if trip === :untripped
        α ≤ 7.5 ? δs0 * 10^(0.0679α) : α ≤ 12.5 ? δs0 * 0.0162 * 10^(0.3066α) : δs0 * 52.42 * 10^(0.0258α)
    else
        α ≤ 5 ? δs0 * 10^(0.0679α) : α ≤ 12.5 ? δs0 * 0.381 * 10^(0.1516α) : δs0 * 14.296 * 10^(0.0258α)
    end
    return (; δ_p, δs_p, δs_s, Rc)
end

"""High- and low-frequency directivity D̄_h, D̄_l (RP-1218 App. B, Eqs. B1, B2); angles in degrees."""
function bpm_directivity(Θ::Real, Φ::Real, M::Real)
    Mc = 0.8M
    Dh = 2 * sind(Θ / 2)^2 * sind(Φ)^2 / ((1 + M * cosd(Θ)) * (1 + (M - Mc) * cosd(Θ))^2)
    Dl = sind(Θ)^2 * sind(Φ)^2 / (1 + M * cosd(Θ))^4
    return Dh, Dl
end

# spectral shape functions A and B (Eqs. 35–46)
_bpm_amin(a) = a < 0.204 ? sqrt(67.552 - 886.788a^2) - 8.219 :
               a ≤ 0.244 ? -32.665a + 3.981 : -142.795a^3 + 103.656a^2 - 57.757a + 6.006
_bpm_amax(a) = a < 0.13 ? sqrt(67.552 - 886.788a^2) - 8.219 :
               a ≤ 0.321 ? -15.901a + 1.098 : -4.669a^3 + 3.491a^2 - 16.699a + 1.149
_bpm_bmin(b) = b < 0.13 ? sqrt(16.888 - 886.788b^2) - 4.109 :
               b ≤ 0.145 ? -83.607b + 8.138 : -817.81b^3 + 355.21b^2 - 135.024b + 10.619
_bpm_bmax(b) = b < 0.10 ? sqrt(16.888 - 886.788b^2) - 4.109 :
               b ≤ 0.187 ? -31.33b + 1.854 : -80.541b^3 + 44.174b^2 - 39.381b + 2.344
_bpm_a0(Rc) = Rc < 9.52e4 ? 0.57 : Rc ≤ 8.57e5 ? -9.57e-13 * (Rc - 8.57e5)^2 + 1.13 : 1.13
_bpm_b0(Rc) = Rc < 9.52e4 ? 0.30 : Rc ≤ 8.57e5 ? -4.48e-13 * (Rc - 8.57e5)^2 + 0.56 : 0.56
function _bpm_A(St_ratio, Rc)
    a = abs(log10(St_ratio)); a0 = _bpm_a0(Rc)
    AR = (-20 - _bpm_amin(a0)) / (_bpm_amax(a0) - _bpm_amin(a0))
    return _bpm_amin(a) + AR * (_bpm_amax(a) - _bpm_amin(a))
end
function _bpm_B(St_ratio, Rc)
    b = abs(log10(St_ratio)); b0 = _bpm_b0(Rc)
    BR = (-20 - _bpm_bmin(b0)) / (_bpm_bmax(b0) - _bpm_bmin(b0))
    return _bpm_bmin(b) + BR * (_bpm_bmax(b) - _bpm_bmin(b))
end

const _BPM_FLOOR = -100.0
_bpm_dB(x) = x > 0 ? max(10log10(x), _BPM_FLOOR) : _BPM_FLOOR

"""
    bpm_tbl_te(f, c, L, r, Θ, Φ, α, U; c0=340.46, ν=1.4529e-5, trip=:untripped) -> (; p, s, α)

Turbulent-boundary-layer trailing-edge noise, pressure side, suction side and separation (RP-1218
Eqs. 25–49), 1/3-octave SPL [dB] at frequency `f` for a segment of chord `c`, span `L`, at distance `r`.
"""
function bpm_tbl_te(f::Real, c, L, r, Θ, Φ, α, U; c0=340.46, ν=1.4529e-5, trip::Symbol=:untripped)
    M = U / c0
    bl = bpm_boundary_layer(c, U, α; ν, trip)
    Rc = bl.Rc
    Dh, Dl = bpm_directivity(Θ, Φ, M)
    St1 = 0.02 * M^(-0.6)
    St2 = St1 * (α < 1.33 ? 1.0 : α ≤ 12.5 ? 10^(0.0054 * (α - 1.33)^2) : 4.72)
    St1p = (St1 + St2) / 2
    Stp = f * bl.δs_p / U
    Sts = f * bl.δs_s / U
    lr = log10(Rc)
    K1 = Rc < 2.47e5 ? -4.31lr + 156.3 : Rc ≤ 8.0e5 ? -9.0lr + 181.6 : 128.5
    Rδp = U * bl.δs_p / ν
    ΔK1 = Rδp ≤ 5000 ? α * (1.43 * log10(Rδp) - 5.29) : 0.0
    γ = 27.094M + 3.31; γ0 = 23.43M + 4.651; β = 72.65M + 10.74; β0 = -34.19M - 13.82
    K2 = K1 + (α < γ0 - γ ? -1000.0 : α ≤ γ0 + γ ? sqrt(max(β^2 - (β / γ)^2 * (α - γ0)^2, 0.0)) + β0 : -12.0)
    α0 = min(γ0, 12.5)
    if α > α0
        # stalled: only the separation term, with A' (A at 3 Rc) and the low-frequency directivity
        Sa = 10log10(bl.δs_s * M^5 * L * Dl / r^2) + _bpm_A(Sts / St2, 3Rc) + K2
        return (; p=_BPM_FLOOR, s=_BPM_FLOOR, α=max(Sa, _BPM_FLOOR))
    end
    Sp = 10log10(bl.δs_p * M^5 * L * Dh / r^2) + _bpm_A(Stp / St1, Rc) + (K1 - 3) + ΔK1
    Ss = 10log10(bl.δs_s * M^5 * L * Dh / r^2) + _bpm_A(Sts / St1p, Rc) + (K1 - 3)
    Sa = 10log10(bl.δs_s * M^5 * L * Dh / r^2) + _bpm_B(Sts / St2, Rc) + K2
    return (; p=max(Sp, _BPM_FLOOR), s=max(Ss, _BPM_FLOOR), α=max(Sa, _BPM_FLOOR))
end

"""
Laminar-boundary-layer vortex-shedding noise (RP-1218 Eqs. 53–60), 1/3-octave SPL [dB].
`α_bl` is the angle for the boundary-layer thickness (default `α`); RP-1218 App. C uses the aerodynamic
angle there and the geometric angle `α` in Eqs. (53)–(60) for cambered rotor sections.
"""
function bpm_lbl_vs(f::Real, c, L, r, Θ, Φ, α, U; c0=340.46, ν=1.4529e-5, trip::Symbol=:untripped, α_bl::Real=α)
    M = U / c0
    bl = bpm_boundary_layer(c, U, α_bl; ν, trip)
    Rc = bl.Rc
    Dh, _ = bpm_directivity(Θ, Φ, M)
    St1 = Rc ≤ 1.3e5 ? 0.18 : Rc ≤ 4.0e5 ? 0.001756 * Rc^0.3931 : 0.28
    Stpk = St1 * 10^(-0.04α)
    e = f * bl.δ_p / U / Stpk
    le = log10(e)
    G1 = e ≤ 0.5974 ? 39.8le - 11.12 : e ≤ 0.8545 ? 98.409le + 2.0 :
         e ≤ 1.17 ? -5.076 + sqrt(2.484 - 506.25le^2) : e ≤ 1.674 ? -98.409le + 2.0 : -39.8le - 11.12
    Rc0 = α ≤ 3 ? 10^(0.215α + 4.978) : 10^(0.120α + 5.263)
    d = Rc / Rc0; ld = log10(d)
    G2 = d ≤ 0.3237 ? 77.852ld + 15.328 : d ≤ 0.5689 ? 65.188ld + 9.125 :
         d ≤ 1.7579 ? -114.052ld^2 : d ≤ 3.0889 ? -65.188ld + 9.125 : -77.852ld + 15.328
    G3 = 171.04 - 3.03α
    return max(10log10(bl.δ_p * M^5 * L * Dh / r^2) + G1 + G2 + G3, _BPM_FLOOR)
end

"""Tip-vortex formation noise (RP-1218 Eqs. 61–67), 1/3-octave SPL [dB]; `α_tip` in degrees."""
function bpm_tip(f::Real, c, r, Θ, Φ, α_tip, U; c0=340.46, rounded::Bool=true)
    M = U / c0
    Dh, _ = bpm_directivity(Θ, Φ, M)
    ℓ = rounded ? 0.008 * α_tip * c : c * (α_tip ≤ 2 ? 0.0230 + 0.0169α_tip : 0.0378 + 0.0095α_tip)
    Mmax = M * (1 + 0.036α_tip)
    Umax = c0 * Mmax
    St = f * ℓ / Umax
    return max(10log10(M^2 * Mmax^3 * ℓ^2 * Dh / r^2) - 30.5 * (log10(St) + 0.3)^2 + 126, _BPM_FLOOR)
end

"""
    bpm_spectrum(segments; freqs=bpm_frequencies(), c0=340.46, ν=1.4529e-5, lbl=false, tbl=true, tip=false)

Sum over segments (energy) of each mechanism, as the RP-1218 prediction code (App. D). Each segment is a
NamedTuple (c, L, r, Θ, Φ, α, U, trip[, α_tip, rounded]). Returns per-mechanism and total 1/3-octave SPL [dB].
"""
function bpm_spectrum(segs; freqs=bpm_frequencies(), c0=340.46, ν=1.4529e-5, lbl::Bool=false, tbl::Bool=true,
                      tip::Bool=false)
    n = length(freqs)
    P = zeros(n); S = zeros(n); A = zeros(n); LB = zeros(n); T = zeros(n)
    for (k, f) in enumerate(freqs), sg in segs
        if tbl
            t = bpm_tbl_te(f, sg.c, sg.L, sg.r, sg.Θ, sg.Φ, sg.α, sg.U; c0, ν, trip=sg.trip)
            P[k] += 10^(t.p / 10); S[k] += 10^(t.s / 10); A[k] += 10^(t.α / 10)
        end
        lbl && (LB[k] += 10^(bpm_lbl_vs(f, sg.c, sg.L, sg.r, sg.Θ, sg.Φ, sg.α, sg.U; c0, ν, trip=sg.trip) / 10))
    end
    if tip
        # the code applies tip noise once, from the last segment (the tip)
        sg = segs[end]
        for (k, f) in enumerate(freqs)
            T[k] = 10^(bpm_tip(f, sg.c, sg.r, sg.Θ, sg.Φ, sg.α_tip, sg.U; c0, rounded=sg.rounded) / 10)
        end
    end
    tot = P .+ S .+ A .+ LB .+ T
    return (; f=collect(float.(freqs)), p=_bpm_dB.(P), s=_bpm_dB.(S), α=_bpm_dB.(A), lbl=_bpm_dB.(LB),
            tip=_bpm_dB.(T), total=_bpm_dB.(tot))
end
