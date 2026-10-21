"""
Propeller free-field via CCBlade.jl + AcousticAnalogies.jl (flowchart SRC_AC).

Validity: **X-EXTRAP** for the aircraft application. The source block is checked against
NACA Report 996 and Pereira (docs/IMPLEMENTATION_PLAN.md, phases 25–28; close-out phase 33).

Shared evaluation: `evaluate_propeller_source` is the only place that runs
CCBlade → F1A → FFT. `propeller_freefield_grid` evaluates all 160 grid observers
(no GEXT). GEXT remains on the e11 validation path only (`freefield_digitized.jl`).

Coordinate note: CCBlade/AcousticAnalogies use rotor axis = +X with freestream
along +X. Fuselage PAIN frame uses cylinder axis = +Z. Observers are mapped
hub-relative as (X,Y,Z)_AA = (z − z_p, x − x_h, y − y_h).
"""

struct FreeFieldHarmonicGrid
    pts
    harmonics::Vector{Int}
    amplitudes::Array{Float64,3}  # (k_max, ell_max, nH) [Pa]
    phases::Array{Float64,3}
    source::Symbol
    notes::String
    bpf_Hz::Float64
end

"""Observer in the AcousticAnalogies frame (rotor axis +X, hub at the origin)."""
struct Observer
    x::Vector{Float64}
    v::Vector{Float64}
    label::String
end

"""Result of `evaluate_propeller_source`: peak amplitude and phase per observer × harmonic."""
struct SourceResult
    amplitude::Matrix{Float64}   # (n_obs, n_harmonics), single-sided peak, Pa
    phase::Matrix{Float64}       # (n_obs, n_harmonics), rad
    harmonics::Vector{Int}
    bpf_Hz::Float64
    T::Float64
    Q::Float64
    CT::Float64
    CQ::Float64
    CP::Float64
    echo::NamedTuple
end

"""Validation-only load scaling: section Np × s_T, Tp × s_Q so integrated T,Q match targets (phase 25h)."""
struct ScaledLoads
    T_target::Float64
    Q_target::Float64
end

function _scale_outputs(outs, s_T::Float64, s_Q::Float64)
    # CCBlade.solve returns a StructVector; thrusttorque/f1a need that layout (outs.Np).
    scaled = deepcopy(outs)
    scaled.Np .*= s_T
    scaled.Tp .*= s_Q
    return scaled
end


"""
Build a simple analytic free-field surrogate for pipeline testing when
CCBlade/AcousticAnalogies are unavailable. Not for validation claims.
"""
function synthetic_freefield_grid(fuse::FuselageGeometry, prop::PropellerPlacement,
                                  spec::GridSpec=GridSpec();
                                  n_harmonics::Int=5,
                                  bpf_Hz::Float64=150.0,
                                  p_ref::Float64=20.0)
    pts = grid_points(fuse, prop, spec)
    amps = zeros(spec.k_max, spec.ell_max, n_harmonics)
    phases = zeros(spec.k_max, spec.ell_max, n_harmonics)
    for p in pts
        R = hypot(p.x1, p.x2, p.x3)
        for H in 1:n_harmonics
            A = p_ref / H * exp(-0.8 * abs(p.k - spec.k_p) / spec.k_max) *
                max(cos(deg2rad(p.alpha_deg)), 0.05)
            amps[p.k, p.ell, H] = A / max(R, 0.05)
            phases[p.k, p.ell, H] = -H * (p.x3 / 0.2)
        end
    end
    return FreeFieldHarmonicGrid(pts, collect(1:n_harmonics), amps, phases,
        :synthetic, "Synthetic free-field for pipeline smoke test (not V-EXP).", bpf_Hz)
end

"""
    propeller_freefield_grid(aircraft_json_path, fuse, prop, spec; kwargs...)

CCBlade BEMT → AcousticAnalogies F1A at **all 160** grid observers → FFT tones.
Optional Table-8 peak calibration (option a: scale from ℓ = 1 peak, applied to all points).
No GEXT on this path (e11 path only).
"""
function propeller_freefield_grid(aircraft_json_path::AbstractString,
                                  fuse::FuselageGeometry,
                                  prop::PropellerPlacement,
                                  spec::GridSpec=GridSpec();
                                  n_harmonics::Int=10,
                                  num_src_times::Int=64)
    cfg = _load_aircraft_json(aircraft_json_path)
    # Observer velocity matches the static-guard substitution inside evaluate_propeller_source
    Vinf_use = Float64(_get(cfg.operating_point, :forward_speed_mps, 20.0))
    Vinf_use < 1.0 && (Vinf_use = 20.0)
    observers, pts = grid_observers(fuse, prop, spec; Vinf=Vinf_use)
    src = evaluate_propeller_source(cfg, observers; n_harmonics, num_src_times, loads=:ccblade)
    amps = zeros(spec.k_max, spec.ell_max, n_harmonics)
    phases = zeros(spec.k_max, spec.ell_max, n_harmonics)
    for (i, pnt) in enumerate(pts)
        for H in 1:n_harmonics
            amps[pnt.k, pnt.ell, H] = src.amplitude[i, H]
            phases[pnt.k, pnt.ell, H] = src.phase[i, H]
        end
    end
    grid = FreeFieldHarmonicGrid(pts, collect(1:n_harmonics), amps, phases, :ccblade_f1a, "", src.bpf_Hz)
    cal = _get(cfg, :anopp_table8_calibrate, true)
    cal_note = ""
    if cal === true || cal === "true"
        tab = _get(cfg, :anopp_table8_csv, nothing)
        csv = tab === nothing ?
            joinpath(@__DIR__, "..", "..", "data", "anopp_table8_spl_dB.csv") :
            String(tab)
        grid, scales = apply_table8_calibration(grid, csv)
        !isempty(scales) && (cal_note = " Table8 peak-cal scales=$(round.(scales; digits=3));")
    end
    echo = src.echo
    notes = "CCBlade+F1A all 160 points, no GEXT (X-EXTRAP). Vinf=$(echo.Vinf)" *
            (echo.vinf_substituted ? " (static guard)" : "") *
            "; c0=$(echo.c0); t/c=$(echo.t_over_c); pitch_off=$(echo.pitch_offset_deg)°; " *
            "AA (x3,x1,x2); DC-removed FFT; asound fixed." * cal_note * " Tables 7–9."
    return FreeFieldHarmonicGrid(grid.pts, grid.harmonics, grid.amplitudes, grid.phases,
                                 grid.source, notes, grid.bpf_Hz)
end

function _load_aircraft_json(path::AbstractString)
    txt = read(path, String)
    try
        return JSON3.read(txt)
    catch e
        error("JSON3 required to load aircraft.json. Run scripts/add_deps.jl. Cause: $e")
    end
end

function _get(obj, key::Symbol, default)
    try
        v = getproperty(obj, key)
        return v === nothing ? default : v
    catch
        return default
    end
end

"""
Map ANOPP hub-relative skin point (x1,x2,x3) to AcousticAnalogies observer coords.

ANOPP: x1 tip-clearance (rotation plane), x2 circumferential, x3 along prop axis.
AA/CCBlade: +X = prop/freestream axis, YZ = rotation plane.
"""
function _observer_aa(_fuse::FuselageGeometry, _prop::PropellerPlacement, pnt)
    return [pnt.x3, pnt.x1, pnt.x2]
end

"""
    grid_observers(fuse, prop, spec; Vinf) -> (observers, pts)

Observers in `grid_points` order. `v = [Vinf, 0, 0]`, label `"k=…,ell=…"`.
"""
function grid_observers(fuse::FuselageGeometry, prop::PropellerPlacement, spec::GridSpec;
                        Vinf::Float64)
    pts = grid_points(fuse, prop, spec)
    v = [Vinf, 0.0, 0.0]
    observers = [Observer(_observer_aa(fuse, prop, pnt), copy(v), "k=$(pnt.k),ell=$(pnt.ell)")
                 for pnt in pts]
    return observers, pts
end

"""
    hub_observers(R, D; x_over_D, d_over_D, x_sign, azimuth_deg=0.0, v=zeros(3))

Hub-centred observers for Report 996 / Pereira. `x_sign` has **no default**
(ahead/behind convention stated by every caller; Report 996: positive x/D ahead).
"""
function hub_observers(R::Float64, D::Float64;
                       x_over_D::AbstractVector{<:Real},
                       d_over_D::Float64,
                       x_sign::Real,
                       azimuth_deg::Float64=0.0,
                       v::AbstractVector{<:Real}=zeros(3))
    r = R + d_over_D * D
    c, s = cosd(azimuth_deg), sind(azimuth_deg)
    vv = Float64.(collect(v))
    length(vv) == 3 || error("v must have length 3")
    observers = Observer[]
    for xd in x_over_D
        x = [Float64(x_sign) * Float64(xd) * D, r * c, r * s]
        push!(observers, Observer(x, copy(vv), "x/D=$(xd),d/D=$(d_over_D)"))
    end
    return observers
end

"""
Default clamped linear polar (CCBlade interface: α in radians).
"""
function _default_af(α, Re, M)
    αc = clamp(α, -0.35, 0.35)
    cl = 2π * αc
    cd = 0.01 + 0.15 * αc^2
    return cl, cd
end

# Wrap phase to (−π, π] after removing the FFT window start time from angle(c) (I-02).
_wrap_phase(φ::Real) = mod(φ + π, 2π) - π

# Guard (I-01): one-bpp reception window must lie inside every element's reception span.
function _assert_reception_inside_elements(apth, t_common, observer_label::AbstractString)
    nd = ndims(apth)
    nd >= 1 || error("empty F1A pressure array for observer $observer_label")
    n_t = size(apth, 1)
    n_t >= 2 || error("F1A element time history too short for observer $observer_label")
    t_firsts = Float64[]
    t_lasts = Float64[]
    if nd == 1
        push!(t_firsts, apth[1].t)
        push!(t_lasts, apth[end].t)
    else
        other = CartesianIndices(size(apth)[2:end])
        for I in other
            push!(t_firsts, apth[1, I].t)
            push!(t_lasts, apth[n_t, I].t)
        end
    end
    t0 = first(t_common)
    t1 = last(t_common)
    if t1 > minimum(t_lasts) || t0 < maximum(t_firsts)
        error("F1A reception window outside element data for observer $(observer_label): " *
              "t_common=[$(t0), $(t1)], element t_first max=$(maximum(t_firsts)), " *
              "t_last min=$(minimum(t_lasts)) (plan I-01 guard)")
    end
    return nothing
end

"""
    evaluate_propeller_source(cfg, observers; n_harmonics, num_src_times, loads, af, allow_static,
                              n_rev_src, force_short_source)

**The only place** that builds the CCBlade rotor, solves sections, builds F1A
source elements, and takes the FFT per observer. No calibration, no GEXT, no grid knowledge.
`loads` is `:ccblade` or `ScaledLoads(T_target, Q_target)` (phase 25h).
`allow_static=true` keeps Vinf as given when Vinf < 1 (phase 25a probe); default still substitutes 20 m/s with a warning.
Source span is `n_rev_src` revolutions (default 2, plan I-01); reception window is one bpp.
Phase is referenced to absolute observer time (I-02). `force_short_source` is test-only.
"""
function evaluate_propeller_source(cfg, observers::Vector{Observer};
                                   n_harmonics::Int=10, num_src_times::Int=64,
                                   loads=:ccblade, af=nothing, allow_static::Bool=false,
                                   n_rev_src::Int=2, force_short_source::Bool=false)
    loads === :ccblade || loads isa ScaledLoads ||
        error("loads=$loads not supported; use :ccblade or ScaledLoads(T,Q)")
    n_rev_src >= 1 || error("n_rev_src must be ≥ 1")
    p = cfg.propeller
    op = cfg.operating_point
    B = Int(p.num_blades)
    Rtip = Float64(p.tip_radius_m)
    Rhub = Float64(p.hub_radius_m)
    rpm = Float64(p.rpm)
    Ω = rpm * 2π / 60
    bpf = B * rpm / 60
    Vinf = Float64(_get(op, :forward_speed_mps, 20.0))
    vinf_substituted = false
    if Vinf < 1.0 && !allow_static
        @warn "Vinf < 1 m/s replaced by 20 m/s (static guard; plan 25a)" maxlog=1
        Vinf = 20.0
        vinf_substituted = true
    end
    ρ = Float64(_get(op, :rho_kg_m3, 1.225))
    c0 = Float64(_get(op, :c0_mps, 340.0))
    t_over_c = Float64(_get(p, :thickness_over_chord, 0.0))
    pitch_off = Float64(_get(p, :pitch_offset_deg, 0.0))

    if _get(p, :radii_m, nothing) !== nothing
        r = Float64.(collect(p.radii_m))
        chord = Float64.(collect(p.chord_m))
        theta = Float64.(collect(p.twist_deg)) .* (π / 180) .+ deg2rad(pitch_off)
        nsec = length(r)
    else
        nsec = 12
        r = collect(range(Rhub + 1e-3, Rtip - 1e-3; length=nsec))
        chord = fill(0.08 * Rtip, nsec)
        theta = collect(range(40.0, 10.0; length=nsec)) .* (π / 180) .+ deg2rad(pitch_off)
    end

    af_fn = af === nothing ? _default_af : af
    polar_tag = af === nothing ? :clamped_linear : :user

    rotor = CCBlade.Rotor(Rhub, Rtip, B)
    sections = [CCBlade.Section(r[i], chord[i], theta[i], af_fn) for i in 1:nsec]
    ops = [CCBlade.OperatingPoint(Vinf, Ω * r[i], ρ; asound=c0) for i in 1:nsec]
    outs = CCBlade.solve.(Ref(rotor), sections, ops)

    T, Q = CCBlade.thrusttorque(rotor, sections, outs)
    s_T = 1.0
    s_Q = 1.0
    if loads isa ScaledLoads
        s_T = loads.T_target / T
        s_Q = loads.Q_target / Q
        outs = _scale_outputs(outs, s_T, s_Q)
        T, Q = CCBlade.thrusttorque(rotor, sections, outs)
        abs(T - loads.T_target) / max(abs(loads.T_target), eps()) < 1e-9 ||
            error("ScaledLoads thrust mismatch after scale")
        abs(Q - loads.Q_target) / max(abs(loads.Q_target), eps()) < 1e-9 ||
            error("ScaledLoads torque mismatch after scale")
    end
    n_rps = rpm / 60
    D = 2 * Rtip
    CT = T / (ρ * n_rps^2 * D^4)
    CQ = Q / (ρ * n_rps^2 * D^5)
    CP = 2π * CQ

    area_over_chord2 = fill(t_over_c, nsec)
    bpp = 2π / Ω / B
    # I-01: source span = n_rev_src revolutions at the same Δt as before; reception = one bpp.
    # force_short_source: test-only path that reproduces the old one-bpp source (guard must fire).
    if force_short_source
        period_src = bpp
        n_src = num_src_times
    else
        period_src = n_rev_src * (2π / Ω)
        n_src = n_rev_src * B * num_src_times
    end
    ses = AcousticAnalogies.f1a_source_elements_ccblade(
        rotor, sections, ops, outs, area_over_chord2, period_src, n_src, true)

    n_obs = length(observers)
    amplitude = zeros(n_obs, n_harmonics)
    phase = zeros(n_obs, n_harmonics)
    for (i, obs) in enumerate(observers)
        aa_obs = AcousticAnalogies.ConstVelocityAcousticObserver(0.0, obs.x, obs.v)
        apth = AcousticAnalogies.noise.(ses, Ref(aa_obs))
        # Reception window: exactly one blade-pass period (bin H+1 = harmonic H).
        apth_total = AcousticAnalogies.combine(apth, bpp, num_src_times)
        t = AcousticMetrics.time(apth_total)
        _assert_reception_inside_elements(apth, t, obs.label)
        pref = AcousticMetrics.pressure(apth_total)
        p_ac = pref .- sum(pref) / length(pref)
        n = length(p_ac)
        P = FFTW.rfft(p_ac)
        dt = n > 1 ? (t[2] - t[1]) : bpp / num_src_times
        df = 1 / max(n * dt, eps())
        # I-02: rfft phase is φ + ω_H·t₀ for p(t)=A cos(ω_H t + φ) on t=t₀+jΔt.
        t0 = first(t)
        for H in 1:n_harmonics
            fH = H * bpf
            bin = clamp(round(Int, fH / df) + 1, 1, length(P))
            c = P[bin]
            amplitude[i, H] = 2 * abs(c) / n
            ω_H = 2π * fH
            phase[i, H] = _wrap_phase(angle(c) - ω_H * t0)
        end
    end

    echo = (
        Vinf=Vinf, vinf_substituted=vinf_substituted, c0=c0, rho=ρ,
        polar=polar_tag, t_over_c=t_over_c, pitch_offset_deg=pitch_off,
        loads=loads, s_T=s_T, s_Q=s_Q, num_src_times=num_src_times,
        B=B, Rhub=Rhub, Rtip=Rtip, rpm=rpm, allow_static=allow_static,
        period_src=period_src, n_src=n_src, n_rev_src=n_rev_src,
        force_short_source=force_short_source,
    )
    return SourceResult(amplitude, phase, collect(1:n_harmonics), bpf, T, Q, CT, CQ, CP, echo)
end

"""
    apply_table8_calibration(grid, csv) -> (grid, scales)

Per-harmonic scale from the ℓ = 1 peak against the Table 8 peak, clamped to ±20 dB,
applied to **all** 160 points (phase 21 open decision 1, option a).
"""
function apply_table8_calibration(grid::FreeFieldHarmonicGrid, csv::AbstractString)
    n_harmonics = size(grid.amplitudes, 3)
    scales = Float64[]
    amps = copy(grid.amplitudes)
    if !isfile(csv)
        return grid, scales
    end
    anopp = _read_csv_numeric(csv)
    for H in 1:min(n_harmonics, 5)
        key = H == 1 ? :SPL_H1_dB : H == 2 ? :SPL_H2_dB :
              H == 3 ? :SPL_H3_dB : H == 4 ? :SPL_H4_dB : :SPL_H5_dB
        haskey(anopp, key) || continue
        peak_f1a = maximum(amps[:, 1, H])   # ℓ = 1 subset
        peak_an = maximum(spl_dB_to_Pa.(anopp[key]))
        s = peak_f1a > 0 ? peak_an / peak_f1a : 1.0
        s = clamp(s, 10^(-1.0), 10^(1.0))
        amps[:, :, H] .*= s
        push!(scales, s)
    end
    return FreeFieldHarmonicGrid(grid.pts, grid.harmonics, amps, copy(grid.phases),
                                 grid.source, grid.notes, grid.bpf_Hz), scales
end

"""
    total_rms(A) -> Float64

Total rms pressure from single-sided **peak** harmonic amplitudes `A` (phase 25e/25j).
`p_rms = √(Σ A_m²/2)`.
"""
function total_rms(A::AbstractVector{<:Real})
    s = 0.0
    for a in A
        s += Float64(a)^2 / 2
    end
    return sqrt(s)
end

"""
    pressure_coefficient_pc(p_rms; ρ, M_t, a) -> Float64

Report 996 nondimensional pressure `p_c = π² p_rms / (ρ M_t² a²)` (phase 25e).
Independent of D because n·D = M_t·a/π.
"""
function pressure_coefficient_pc(p_rms::Real; ρ::Real, M_t::Real, a::Real)
    return (π^2) * Float64(p_rms) / (Float64(ρ) * Float64(M_t)^2 * Float64(a)^2)
end

"""Pa → dyne/cm² (Report 996 figures). 1 Pa = 10 dyne/cm²."""
pa_to_dyne_cm2(p_Pa::Real) = 10.0 * Float64(p_Pa)
dyne_cm2_to_pa(p::Real) = Float64(p) / 10.0

"""
    blade_form_geometry(csv_path; D, beta75_target_deg, r_tip_frac=0.995) -> NamedTuple

Report 996 / phase 25b: read `blade_form.csv` (r/R, c/R, t/c, β_design, …),
shift twist so β(0.75R) = `beta75_target_deg` using design β₇₅ = 42.64°,
truncate at `r_tip_frac` (chord → 0 at tip). Returns radii_m, chord_m, twist_deg, t_over_c.
"""
function blade_form_geometry(csv_path::AbstractString;
                             D::Float64=1.2192,
                             beta75_target_deg::Float64=15.0,
                             r_tip_frac::Float64=0.995,
                             beta75_design_deg::Float64=42.64)
    R = D / 2
    rows = NamedTuple[]
    for raw in eachline(csv_path)
        s = strip(raw)
        (isempty(s) || startswith(s, "#") || startswith(s, "r_over_R")) && continue
        parts = split(s, ',')
        length(parts) >= 4 || continue
        rR = parse(Float64, parts[1])
        rR > r_tip_frac && continue
        push!(rows, (
            r_over_R=rR,
            c_over_R=parse(Float64, parts[2]),
            t_over_c=parse(Float64, parts[3]),
            beta_deg=parse(Float64, parts[4]),
        ))
    end
    isempty(rows) && error("no blade_form rows in $csv_path")
    # β(r) = β75_target + (β_design(r) − β75_design)
    twist = [r.beta_deg - beta75_design_deg + beta75_target_deg for r in rows]
    return (
        radii_m = [r.r_over_R * R for r in rows],
        chord_m = [r.c_over_R * R for r in rows],
        twist_deg = twist,
        t_over_c = [r.t_over_c for r in rows],
        D=D, R=R, beta75_target_deg=beta75_target_deg,
        beta75_design_deg=beta75_design_deg, r_tip_frac=r_tip_frac,
    )
end

"""Apply Eq. (43) blocking to a free-field grid."""
function apply_blocking(ff::FreeFieldHarmonicGrid, fuse::FuselageGeometry,
                        prop::PropellerPlacement; variant::BlockingVariant=R1)
    amps = copy(ff.amplitudes)
    for p in ff.pts
        γ = incidence_angle_deg(fuse, prop, p.theta_deg, p.z)
        for H in 1:size(amps, 3)
            amps[p.k, p.ell, H] = blocked_amplitude(amps[p.k, p.ell, H], γ; variant)
        end
    end
    return FreeFieldHarmonicGrid(ff.pts, ff.harmonics, amps, copy(ff.phases),
        ff.source, ff.notes * " + blocking $(variant)", ff.bpf_Hz)
end
