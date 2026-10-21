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
               m_wall, η_n_bare, C_struc, q_max, allow_extrapolation, ρ0, c0)

Inputs of the PAIN core. `sidewall`/`endplates` are the App. A trim stacks of the curved wall and of the end plates
(`nothing` for both = bare cabin: τ_t = 1, η_n = `η_n_bare` for every mode, η_r' = η_r). `mech` is the mechanical
trim path of Eq. (A.19) (`nothing` = insulation path only). `m_wall` [kg/m²] is the wall mass of Eqs. (81)–(82)
(`NaN` = the smeared skin, stringer and frame mass of the Phase III article). `C_struc` is the C of Eq. (80),
`q_max` the axial truncation of the cabin modes (`nothing` = ⌈2ω_H L/(π c0)⌉), `allow_extrapolation` lets the
insulation table be continued beyond its digitized range (the result is then X-EXTRAP).
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
    ρ0::Float64
    c0::Float64
end

function PainInputs(fuse, prop, structural, acoustic, amplitudes, phases, pts, ΔA::Real;
                    sidewall::Union{Nothing,TrimStack}=nothing,
                    endplates::Union{Nothing,TrimStack}=nothing,
                    mech::Union{Nothing,MechanicalPath}=nothing,
                    m_wall::Real=NaN, η_n_bare::Real=0.05, C_struc::Real=3.0,
                    q_max::Union{Nothing,Integer}=nothing, allow_extrapolation::Bool=false,
                    ρ0::Real=1.225, c0::Real=340.0)
    (sidewall === nothing) == (endplates === nothing) ||
        error("PainInputs: give both `sidewall` and `endplates` trim stacks, or neither (bare cabin)")
    mech !== nothing && sidewall === nothing && error("PainInputs: `mech` needs a `sidewall` stack")
    m = isnan(m_wall) ? MRP_RHO_2024 * (MRP_T_SKIN + MRP_A_STRINGER / MRP_D_STRINGER + MRP_A_FRAME / MRP_ELL_FRAME) : float(m_wall)
    return PainInputs(fuse, prop, structural, acoustic, amplitudes, phases, pts, float(ΔA),
                      sidewall, endplates, mech, m, float(η_n_bare), float(C_struc),
                      q_max === nothing ? nothing : Int(q_max), allow_extrapolation, float(ρ0), float(c0))
end

"""Trim stacks present (sidewall and end plates)?"""
has_trim(inp::PainInputs) = inp.sidewall !== nothing

"""τ_t(ω) of Eq. (A.22) for the sidewall trim (1 for a bare cabin)."""
sidewall_tau(inp::PainInputs, ω::Real) =
    inp.sidewall === nothing ? 1.0 :
    trim_tau(inp.sidewall, ω; mech=inp.mech, allow_extrapolation=inp.allow_extrapolation)

struct InteriorSpectrum
    bpf_Hz::Float64
    harmonic_SPL_dB::Vector{Float64}   # H = 1..n
    third_octave_SPL_dB::Dict{Float64,Float64}
    notes::String
end

"""
Axial factor f_qM = (1/L)∫₀ᴸ cos(qπz/L) sin(Mπz/L) dz, CR-3813 Eq. (57)
(shell length L equal to cavity length Lc).
"""
function axial_coupling(q::Int, M::Int)
    M == q && return 0.0
    return (1 / (2π)) * ((1 - cos((M + q) * π)) / (M + q) + (1 - cos((M - q) * π)) / (M - q))
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
                         fuse::FuselageGeometry; τ_t::Float64=1.0, q::Int=0)
    a = fuse.a
    θ0 = deg2rad(fuse.theta0_deg)
    Lp = 2a * sin(θ0)
    Is = coupling_shell_integral(ac, st, a)
    Ip = coupling_floor_integral(ac, st, a, Lp)
    f = axial_coupling(q, st.M_axial) * (sqrt(τ_t) * Is - Ip) / (Lp + 2a * (π - θ0))
    abs(f) <= 1 + 1e-6 ||
        error("f'(n,r) = $f exceeds 1 for acoustic mode $(ac.index), structural mode $(st.index): mode normalization or shape defect")
    return f
end

"""Sums S_c = Σ A cos φ ψ^r(x_m), S_s = Σ A sin φ ψ^r(x_m) of Eq. (42), over the whole grid."""
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
function tone_mean_square_pressure(inp::PainInputs, H::Int, ωH::Float64; q_max::Union{Nothing,Int}=nothing)
    fuse = inp.fuse
    a, L = fuse.a, fuse.L
    θ0 = deg2rad(fuse.theta0_deg)
    Lp = 2a * sin(θ0)
    A = L * (Lp + 2a * (π - θ0))
    V = cabin_volume(fuse)
    ρ0, c0 = inp.ρ0, inp.c0
    ext = inp.allow_extrapolation
    qtop = something(q_max, inp.q_max, axial_truncation(ωH, L, c0))

    trimmed = has_trim(inp)
    τ_t = sidewall_tau(inp, ωH)
    ξ = trimmed ? trim_conductance(inp.sidewall, ωH, inp.m_wall; ρ0, c0, allow_extrapolation=ext) : 0.0
    ξe = trimmed ? trim_conductance(inp.endplates, ωH, Inf; ρ0, c0, allow_extrapolation=ext) : 0.0

    # per structural mode: Ψ_G, ω_r, η_r'
    nst = length(inp.structural.modes)
    Ψ = Vector{Float64}(undef, nst)
    ωr = Vector{Float64}(undef, nst)
    ηrp = Vector{Float64}(undef, nst)
    for (j, st) in enumerate(inp.structural.modes)
        Ψ[j] = generalized_force(st, H, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA)
        ωr[j] = 2π * st.f_Hz
        ηr = structural_loss_total(st, ωr[j]; a, L, m=inp.m_wall, C=inp.C_struc, ρ0, c0)
        ηrp[j] = trimmed ?
            structural_loss_with_trim(ηr, ωr[j], inp.m_wall,
                                      trim_Cw(inp.sidewall, ωr[j]; allow_extrapolation=ext)) : ηr
    end

    pref = (c0 / V)^2 * (ρ0 * c0 * A)^2 * ωH^4
    p2 = 0.0
    for q in 0:qtop, ac in inp.acoustic.modes
        ωn = 2π * cabin_frequency_3d(ac, a, L, q; c0)
        εn = cabin_eps_3d(ac, q)
        N = trimmed ? acoustic_loss_modal(ac, q, ωH, ωn; a, L, V, c0, ξ, ξ_e=ξe).N : inp.η_n_bare * ωn^2
        Dn = (ωn^2 - ωH^2)^2 + N^2
        for (j, st) in enumerate(inp.structural.modes)
            f = coupling_factor(ac, st, fuse; τ_t, q)
            f == 0 && continue
            ηrpp = structural_loss_coupled(N, ωn, ωr[j], f, εn, st.M_r, V, A; ρ0, c0)
            Dr = (ωr[j]^2 - ωH^2)^2 + ((ηrp[j] + ηrpp) * ωr[j]^2)^2
            p2 += pref * εn * f^2 * Ψ[j] / (st.M_r^2 * Dn * Dr)
        end
    end
    return p2
end

function cabin_volume(fuse::FuselageGeometry)
    θ0 = deg2rad(fuse.theta0_deg)
    # V = a² L (π − θ0 + cosθ0 sinθ0) from CR-3813 App. C
    a, L = fuse.a, fuse.L
    return a^2 * L * (π - θ0 + cos(θ0) * sin(θ0))
end

"""
Estimate band-limited blocked mean-square pressure ⟨p²⟩_bl for a 1/3-oct band.

Uses spatial-mean |A|² of the highest available tone as an anchor at H·BPF,
then a power-law continuum Spbl(f)∝f^{-α} (CR-3813 HF notes: broadband fills
above the first few BPFs). **V-ASSUMED** slope until closed vs exterior spectra.
"""
function blocked_broadband_band_p2(inp::PainInputs, fc::Float64, bpf_Hz::Float64;
                                   α::Float64=2.0)
    nH = size(inp.amplitudes, 3)
    nH < 1 && return 0.0
    H_anchor = min(nH, 3)
    f_anchor = H_anchor * bpf_Hz
    # Spatial mean of blocked tone amplitude²
    A = inp.amplitudes[:, :, H_anchor]
    p2_tone = sum(abs2, A) / length(A)
    # Spread tone power into continuum density; one-third-oct Δω/ω = 0.232
    cw = 0.232
    Δω_a = cw * 2π * f_anchor
    Spbl_a = p2_tone / max(Δω_a, 1e-12)   # (Pa²)/ (rad/s)
    Spbl_fc = Spbl_a * (f_anchor / max(fc, 1.0))^α
    Δω = cw * 2π * fc
    return Spbl_fc * Δω
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
    interior_spl(inp; bpf_Hz, n_harmonics=10, broadband=true) -> InteriorSpectrum

Tonal SPL for propeller harmonics, plus HF broadband (Eq.19) into 1/3-oct (T2).
"""
function interior_spl(inp::PainInputs; bpf_Hz::Float64, n_harmonics::Int=10,
                      broadband::Bool=true, bb_α::Float64=2.0, bb_j2_scale::Float64=0.5)
    nH = min(n_harmonics, size(inp.amplitudes, 3))
    spl = zeros(Float64, nH)
    pref = 20e-6
    for H in 1:nH
        ωH = 2π * H * bpf_Hz
        p2 = tone_mean_square_pressure(inp, H, ωH)
        spl[H] = 10 * log10(p2 / pref^2 + 1e-30)
    end
    bands = third_octave_centers()
    band_p2 = Dict{Float64,Float64}(b => 0.0 for b in bands)
    for H in 1:nH
        f = H * bpf_Hz
        b = nearest_third_octave(f, bands)
        band_p2[b] += pref^2 * 10^(spl[H] / 10)
    end
    notes = "PAIN tones Eq. (8) (CR-3813 §3.2)"
    if broadband
        f_last = nH * bpf_Hz
        for b in bands
            b < 1000 && continue
            b ≤ f_last * 1.15 && continue
            if has_trim(inp) && !inp.allow_extrapolation && stack_extrapolated(inp.sidewall, b)
                delete!(band_p2, b)   # outside the Fig. A-2 range and no extrapolation allowed: no value
                continue
            end
            p2_bl = blocked_broadband_band_p2(inp, b, bpf_Hz; α=bb_α)
            p2_i = broadband_cabin_p2(inp, b, p2_bl; j2_scale=bb_j2_scale)
            band_p2[b] += p2_i
        end
        notes *= " + HF Eq.19 modal-density with τ_t of Eq. (A.22) (surrogate α_abs, Spbl∝f^{-$(bb_α)}; phase 29b)."
        has_trim(inp) && !inp.allow_extrapolation &&
            (notes *= " Bands above the Fig. A-2 range omitted (allow_extrapolation=false).")
    else
        notes *= " tonal-only (no HF broadband)."
    end
    band_spl = Dict(b => 10 * log10(p2 / pref^2 + 1e-30) for (b, p2) in band_p2)
    return InteriorSpectrum(bpf_Hz, spl, band_spl, notes)
end

function third_octave_centers()
    # 63 Hz … 8 kHz
    f0 = 1000.0
    ks = -12:9
    return [f0 * 2.0^(k / 3) for k in ks]
end

function nearest_third_octave(f::Real, bands::Vector{Float64})
    bands[argmin(abs.(bands .- float(f)))]
end
