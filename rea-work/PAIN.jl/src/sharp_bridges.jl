# Phase 59 — Sharp's double-panel transmission with sound bridges (NASA CR-172490 §2.3, May, Plotkin,
# Selden & Sharp 1985), as an option in Eq. (23). An extension beyond CR-3813. Criteria and mapping fixed
# 2026-10-23 (IMPLEMENTATION_PLAN.md §8g Phase 59) before any run.

"""Mass law of CR-172490 Eq. (5) at normal incidence (cos θ cos φ = 1): TL = 20 log(m f) − 10 log(ρ₁c₁ρ₂c₂) + 10 dB."""
sharp_mass_law_TL(m::Real, f::Real; ρc1::Real=1.21 * 343.0, ρc2::Real=1.21 * 343.0) =
    20 * log10(m * f) - 10 * log10(ρc1 * ρc2) + 10

"""Double-panel resonance f₀ of CR-172490 Eq. (22) at normal incidence [Hz]."""
sharp_f0(m1::Real, m2::Real, d::Real; ρ::Real=1.21, c::Real=343.0) =
    sqrt(ρ * c^2 * (m1 + m2) / (m1 * m2 * d)) / 2π

"""Critical frequency of CR-172490 Eq. (4) for a plate of thickness `h` and longitudinal wave speed `c_L` [Hz]."""
sharp_fc(h::Real, c_L::Real; c::Real=343.0) = c^2 * sqrt(12) / (2π * h * c_L)

"""ΔTL_M of CR-172490: line connections at spacing `b` (Eq. 23) or point connections on a lattice `e` (Eq. 25) [dB]."""
sharp_dTL_line(b::Real, fc::Real) = 10 * log10(b * fc) - 25
sharp_dTL_point(e::Real, fc::Real) = 20 * log10(e * fc) - 51

"""
    sharp_double_panel_TL(m1, m2, d, f; ΔTL_M, ρ=1.21, c=343.0) -> TL [dB]

The CR-172490 Fig. 5 construction: below f₀ the mass law of the combined mass; from f₀ a rise of
18 dB per octave; above the bridging frequency f_b (where that rise meets the mass law + ΔTL_M,
f_b = f₀ 2^(ΔTL_M/(18 − 20 log 2))), the combined-mass mass law plus ΔTL_M.
"""
function sharp_double_panel_TL(m1::Real, m2::Real, d::Real, f::Real; ΔTL_M::Real, ρ::Real=1.21, c::Real=343.0)
    f0 = sharp_f0(m1, m2, d; ρ, c)
    M = m1 + m2
    ρc = ρ * c
    f ≤ f0 && return sharp_mass_law_TL(M, f; ρc1=ρc, ρc2=ρc)
    fb = f0 * 2.0^(ΔTL_M / (18 - 20 * log10(2)))        # where the 18 dB/octave rise meets mass law + ΔTL_M
    f ≤ fb && return sharp_mass_law_TL(M, f0; ρc1=ρc, ρc2=ρc) + 18 * log2(f / f0)
    return sharp_mass_law_TL(M, f; ρc1=ρc, ρc2=ρc) + ΔTL_M
end

"""
    bridge_tau(inp, f) -> NamedTuple

Phase 59b bridge path for the trimmed sidewall: τ_B = τ_ML(m_s + m_t) 10^(−ΔTL_M/10), with
m_s the shell mass, m_t the summed limp masses of the sidewall stack, f_c the higher of the skin
(aluminium, `MRP_T_SKIN`) and trim-panel (G-10, h = 0.79 mm, c = 3200 m/s) critical frequencies, and the
Phase III connections (9 points on the curved trim area → lattice √(A/9); 2 lines → spacing arc/2).
Point and line paths are added (V-ASSUMED mapping, fixed 2026-10-23).
"""
function bridge_tau(inp::PainInputs, f::Real)
    fuse = inp.fuse
    θ0 = deg2rad(fuse.theta0_deg)
    arc = 2 * fuse.a * (π - θ0)
    A_curved = arc * fuse.L
    m_t = sum((el.m for el in inp.sidewall.elements if el isa LimpMass); init=0.0)
    c_L_al = sqrt(MRP_E_2024 / (MRP_RHO_2024 * (1 - MRP_NU_2024^2)))
    fc = max(sharp_fc(MRP_T_SKIN, c_L_al; c=inp.c_int), sharp_fc(0.00079, 3200.0; c=inp.c_int))
    e = sqrt(A_curved / 9)
    b = arc / 2
    ΔTL_pt = sharp_dTL_point(e, fc)
    ΔTL_ln = sharp_dTL_line(b, fc)
    ρc = inp.ρ_int * inp.c_int
    τ_ML = 10^(-sharp_mass_law_TL(inp.m_wall + m_t, f; ρc1=inp.ρ_ext * inp.c_ext, ρc2=ρc) / 10)
    τ_B = τ_ML * (10^(-ΔTL_pt / 10) + 10^(-ΔTL_ln / 10))
    return (; τ_B, τ_ML, ΔTL_pt, ΔTL_ln, fc, e, b, m_t)
end
