"""
Propeller free-field via CCBlade.jl + AcousticAnalogies.jl (flowchart SRC_AC).

Validity: **X-EXTRAP** for the aircraft application. The source block is checked against
NACA Report 996 and Pereira (docs/IMPLEMENTATION_PLAN.md, phases 25–28; close-out phase 33).

Shared evaluation: `evaluate_propeller_source` is the only place that runs
CCBlade → F1A → FFT. `propeller_freefield_grid` evaluates all 160 grid observers
(no GEXT). GEXT remains on the e11 validation path only (`freefield_digitized.jl`).

Coordinate note: CCBlade/AcousticAnalogies use rotor axis = +X, and the rotor travels
along +X (AcousticAnalogies `_standard_ccblade_transform`), so +X is ahead of the propeller
(upstream) and the thrust points along +X. Fuselage PAIN frame uses cylinder axis = +Z. Observers are mapped
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
            # Axial delay; card 36 sense multiplies the blade-passage-like phase sign.
            phases[p.k, p.ell, H] = prop.rotation_direction * (-H * (p.x3 / 0.2))
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
            joinpath(@__DIR__, "..", "..", "data", "cr3813", "anopp_table8_spl_dB.csv") :
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
        error("JSON3 required to load aircraft.json. Run scripts/setup/add_deps.jl. Cause: $e")
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
(ahead/behind convention stated by every caller). AA +X is ahead of the propeller, so a positive
`x_sign` puts positive `x_over_D` ahead; Report 996 uses `R996_X_SIGN` (positive x/D ahead).
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

"""Report 996 x/D (positive ahead of the propeller plane) to AA X: +1, since AA +X is ahead (Phase 72,
2026-10-28; until then the scripts used −1, which put the behind microphones ahead)."""
const R996_X_SIGN = 1.0

"""
    pereira_observers(φs_deg; r=1.0, V=16.0) -> Vector{Observer}

Pereira et al. microphone arc: radius `r` [m] about the centre of rotation, angle φ from the rotation
plane, **positive downstream** (Pereira Fig. 2b). Downstream is AA −X, so x = −r sin φ (Phase 72;
until 2026-10-28 the script used +r sin φ). The observers move with the rotor at `V` (wind-tunnel frame).
"""
pereira_observers(φs; r::Real=1.0, V::Real=16.0) =
    [Observer([-r * sind(φ), r * cosd(φ), 0.0], [Float64(V), 0.0, 0.0], "φ=$φ") for φ in φs]

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
    _ccblade_setup(cfg; af=nothing, allow_static=false, use_tip_correction=true, warn_static=false) -> NamedTuple

The CCBlade rotor, sections, operating points and solved section loads for a propeller config (shared by
`evaluate_propeller_source`, `ccblade_section_operating_points` and the Phase 66 checks; factored out 2026-10-24,
behaviour unchanged). Vinf < 1 m/s is replaced by 20 m/s unless `allow_static` (plan 25a).
"""
function _ccblade_setup(cfg; af=nothing, allow_static::Bool=false, use_tip_correction::Bool=true,
                        warn_static::Bool=false)
    p = cfg.propeller
    op = cfg.operating_point
    B = Int(p.num_blades)
    Rtip = Float64(p.tip_radius_m)
    Rhub = Float64(p.hub_radius_m)
    rpm = Float64(p.rpm)
    Ω = rpm * 2π / 60
    Vinf = Float64(_get(op, :forward_speed_mps, 20.0))
    vinf_substituted = false
    if Vinf < 1.0 && !allow_static
        warn_static && @warn "Vinf < 1 m/s replaced by 20 m/s (static guard; plan 25a)" maxlog=1
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
    else
        nsec = 12
        r = collect(range(Rhub + 1e-3, Rtip - 1e-3; length=nsec))
        chord = fill(0.08 * Rtip, nsec)
        theta = collect(range(40.0, 10.0; length=nsec)) .* (π / 180) .+ deg2rad(pitch_off)
    end
    afs = _station_afs(af, p, length(r))
    # Default Rotor uses PrandtlTipHub(); use_tip_correction=false → tip=nothing (F=1).
    rotor = use_tip_correction ? CCBlade.Rotor(Rhub, Rtip, B) :
            CCBlade.Rotor(Rhub, Rtip, B; tip=nothing)
    sections = [CCBlade.Section(r[i], chord[i], theta[i], afs[i]) for i in eachindex(r)]
    # μ must be passed: CCBlade's default μ = 1 makes the Re given to the polars ~10⁵ too low (Phase 69 defect 5).
    μ = Float64(_get(op, :mu_Pa_s, AIR_MU_PA_S))
    ops = [CCBlade.OperatingPoint(Vinf, Ω * r[i], ρ; mu=μ, asound=c0) for i in eachindex(r)]
    outs = CCBlade.solve.(Ref(rotor), sections, ops)
    return (; rotor, sections, ops, outs, r, chord, theta, B, Rtip, Rhub, rpm, Ω, Vinf, vinf_substituted,
            ρ, c0, t_over_c, pitch_off, afs, μ)
end

"""
    airfoil_area_over_chord2(path) -> Float64

Cross-section area / chord² of a closed airfoil contour in XFOIL `.dat` form (one name line, then x y pairs
around the section): shoelace area divided by (max x − min x)². This is AcousticAnalogies' `area_per_chord2`
(Phase 76).
"""
function airfoil_area_over_chord2(path::AbstractString)
    xy = Tuple{Float64,Float64}[]
    for ln in eachline(path)
        p = split(strip(ln))
        length(p) == 2 || continue
        x, y = tryparse(Float64, p[1]), tryparse(Float64, p[2])
        (x === nothing || y === nothing) && continue
        push!(xy, (x, y))
    end
    length(xy) >= 3 || error("$path: fewer than 3 coordinate pairs")
    a = 0.0
    for i in eachindex(xy)
        (x1, y1), (x2, y2) = xy[i], xy[mod1(i + 1, length(xy))]
        a += x1 * y2 - x2 * y1
    end
    c = maximum(first, xy) - minimum(first, xy)
    return abs(a) / 2 / c^2
end

"""
    naca4_area_over_chord2(t) -> Float64

Area / chord² of a NACA 4-digit section of thickness ratio `t`: twice the integral of the 4-digit thickness
distribution 5t(0.2969√x − 0.1260x − 0.3516x² + 0.2843x³ − 0.1015x⁴) over 0..1, i.e. 0.68505·t. Camber
changes the area only at second order (Phase 76, Pereira NACA 4412).
"""
naca4_area_over_chord2(t::Real) = 10 * t * (0.2969 * 2 / 3 - 0.1260 / 2 - 0.3516 / 3 + 0.2843 / 4 - 0.1015 / 5)

"""
    station_area_over_chord2(section_tc, section_a, station_tc) -> Vector{Float64}

Per-station A/c², linear in t/c between the two sections that bracket each station and clamped at the
thinnest and thickest section, the same blending as the station polars (Phase 76).
"""
function station_area_over_chord2(section_tc::AbstractVector{<:Real}, section_a::AbstractVector{<:Real},
                                  station_tc::AbstractVector{<:Real})
    length(section_tc) == length(section_a) || error("section t/c and area lengths differ")
    isempty(section_tc) && error("no sections")
    o = sortperm(section_tc); tc = Float64.(section_tc[o]); a = Float64.(section_a[o])
    length(tc) == 1 && return fill(a[1], length(station_tc))
    return [begin
                t = clamp(Float64(ts), tc[1], tc[end])
                j = clamp(searchsortedlast(tc, t), 1, length(tc) - 1)
                w = tc[j+1] == tc[j] ? 0.0 : (t - tc[j]) / (tc[j+1] - tc[j])
                (1 - w) * a[j] + w * a[j+1]
            end for ts in station_tc]
end

"""
    report996_area_over_chord2(station_tc; dir) -> Vector{Float64}

Station A/c² for the Report 996 blade from the ten NACA 16 section contours in `dir`
(`data/report996/xfoil_sections`), t/c from the section names (Phase 76).
"""
function report996_area_over_chord2(station_tc::AbstractVector{<:Real};
                                    dir::AbstractString=_data_path("report996", "xfoil_sections"))
    files = sort(filter(f -> endswith(f, ".dat"), readdir(dir)))
    tcs = [_section_t_over_c(splitext(f)[1]) for f in files]
    as = [airfoil_area_over_chord2(joinpath(dir, f)) for f in files]
    return station_area_over_chord2(tcs, as, station_tc)
end

"""Per-station A/c² for the F1A thickness term: `propeller.area_over_chord2` if given, else `thickness_over_chord` at every station."""
function _station_area_over_chord2(p, t_over_c::Real, n::Int)
    v = _get(p, :area_over_chord2, nothing)
    v === nothing && return fill(Float64(t_over_c), n)
    length(v) == n || error("area_over_chord2 has $(length(v)) entries for $n blade stations")
    return Float64.(collect(v))
end

"""
One polar function per blade station. `af` may be `nothing` (the default clamped linear polar), one
function used at every station, a vector with one function per station, or a `PolarSet`. A multi-section
`PolarSet` needs `propeller.station_t_over_c` (one t/c per station) and gives each station its own
section blend (Phase 69 defect 1); it is an error to omit it.
"""
function _station_afs(af, p, n::Int)
    af === nothing && return fill(_default_af, n)
    if af isa AbstractVector
        length(af) == n || error("af vector has $(length(af)) entries for $n blade stations")
        return collect(af)
    end
    if af isa PolarSet && length(af.sections) > 1
        tc = _get(p, :station_t_over_c, nothing)
        tc === nothing && error("multi-section polar set needs propeller.station_t_over_c (one t/c per blade station)")
        length(tc) == n || error("station_t_over_c has $(length(tc)) entries for $n blade stations")
        return station_polars(af, Float64.(collect(tc)))
    end
    # CCBlade evaluates a polar only through a `Function`, so a one-section PolarSet is wrapped.
    af isa PolarSet && return fill(section_polar(af, 0.0), n)
    return fill(af, n)
end

"""
    evaluate_propeller_source(cfg, observers; n_harmonics, num_src_times, loads, af, allow_static,
                              n_rev_src, force_short_source)

**The only source path**: CCBlade rotor and section solve (`_ccblade_setup`), F1A source elements and the FFT per
observer (`_f1a_harmonics`). No calibration, no GEXT, no grid knowledge.
`loads` is `:ccblade` or `ScaledLoads(T_target, Q_target)` (phase 25h).
`allow_static=true` keeps Vinf as given when Vinf < 1 (phase 25a probe); default still substitutes 20 m/s with a warning.
Source span is `n_rev_src` revolutions (default 2, plan I-01); reception window is one bpp.
Phase is referenced to absolute observer time (I-02). `force_short_source` is test-only.
"""
function evaluate_propeller_source(cfg, observers::Vector{Observer};
                                   n_harmonics::Int=10, num_src_times::Int=64,
                                   loads=:ccblade, af=nothing, allow_static::Bool=false,
                                   n_rev_src::Int=2, force_short_source::Bool=false,
                                   use_tip_correction::Bool=true)
    loads === :ccblade || loads isa ScaledLoads ||
        error("loads=$loads not supported; use :ccblade or ScaledLoads(T,Q)")
    n_rev_src >= 1 || error("n_rev_src must be ≥ 1")
    su = _ccblade_setup(cfg; af, allow_static, use_tip_correction, warn_static=true)
    (; rotor, sections, ops, outs, B, Rtip, Rhub, rpm, Ω, Vinf, vinf_substituted, ρ, c0, t_over_c, pitch_off) = su
    nsec = length(sections)
    bpf = B * rpm / 60
    polar_tag = af === nothing ? :clamped_linear : :user

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

    # AcousticAnalogies needs cross-section area / chord² per element. `thickness_over_chord` is passed as that
    # value (it is A/c², not t/c: a section of thickness t has A ≈ 0.69–0.78·t·c). A per-station
    # `propeller.area_over_chord2` vector, when given, is used instead (Phase 69a3, 2026-10-28).
    area_over_chord2 = _station_area_over_chord2(cfg.propeller, t_over_c, nsec)
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
    amplitude, phase = _f1a_harmonics(rotor, sections, ops, outs, area_over_chord2, observers;
                                      period_src, n_src, num_src_times, n_harmonics, bpf)

    echo = (
        Vinf=Vinf, vinf_substituted=vinf_substituted, c0=c0, rho=ρ,
        polar=polar_tag, t_over_c=t_over_c, pitch_offset_deg=pitch_off,
        loads=loads, s_T=s_T, s_Q=s_Q, num_src_times=num_src_times,
        B=B, Rhub=Rhub, Rtip=Rtip, rpm=rpm, allow_static=allow_static,
        period_src=period_src, n_src=n_src, n_rev_src=n_rev_src,
        force_short_source=force_short_source,
        use_tip_correction=use_tip_correction,
    )
    return SourceResult(amplitude, phase, collect(1:n_harmonics), bpf, T, Q, CT, CQ, CP, echo)
end

"""
    _f1a_harmonics(rotor, sections, ops, outs, area_over_chord2, observers; period_src, n_src,
                   num_src_times, n_harmonics, bpf) -> (amplitude, phase)

The F1A → one-blade-pass reception → DC-removed FFT step of `evaluate_propeller_source`, on given
CCBlade loads `outs` (factored out 2026-10-24 so Phase 66h can feed prescribed loads; behaviour unchanged).
"""
function _f1a_harmonics(rotor, sections, ops, outs, area_over_chord2, observers::Vector{Observer};
                        period_src::Real, n_src::Int, num_src_times::Int, n_harmonics::Int, bpf::Real)
    bpp = 1 / bpf
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
            phase[i, H] = _wrap_phase(angle(c) - 2π * fH * t0)
        end
    end
    return amplitude, phase
end

"""Dynamic viscosity of air (Pa·s) passed to every CCBlade `OperatingPoint` (= ρν with ν = 1.4529e-5 m²/s,
ρ = 1.225 kg/m³). Override per run with `operating_point.mu_Pa_s`."""
const AIR_MU_PA_S = 1.78e-5

"""
    ccblade_section_operating_points(cfg; af=nothing, allow_static=false)
        -> NamedTuple

Same CCBlade BEMT setup as `evaluate_propeller_source` (rotor, sections, ops, solve)
without F1A. Returns per-section `r_m`, `r_over_R`, `alpha_deg`, `Mach`, `Re`
(Re = ρ W₀ c / μ, the same μ CCBlade uses; Mach = W₀/c₀ as in CCBlade), the section loads `Np`, `Tp` [N/m]
and the station polars `afs`.
"""
function ccblade_section_operating_points(cfg; af=nothing, allow_static::Bool=false,
                                          use_tip_correction::Bool=true)
    su = _ccblade_setup(cfg; af, allow_static, use_tip_correction)
    (; rotor, sections, ops, outs, B, Rtip, Rhub, rpm, Vinf, ρ, c0, μ) = su
    r, chord = su.r, su.chord
    nsec = length(sections)

    alpha_deg = Float64[rad2deg(outs[i].alpha) for i in 1:nsec]
    Mach = Float64[]
    Re = Float64[]
    for i in 1:nsec
        W0 = hypot(ops[i].Vx, ops[i].Vy)
        push!(Mach, W0 / c0)
        push!(Re, ρ * W0 * chord[i] / μ)
    end
    return (
        r_m=r, r_over_R=r ./ Rtip, chord_m=chord, alpha_deg=alpha_deg, Mach=Mach, Re=Re,
        Rtip=Rtip, Rhub=Rhub, Vinf=Vinf, rho=ρ, c0=c0, B=B, rpm=rpm,
        Np=Float64[outs[i].Np for i in 1:nsec], Tp=Float64[outs[i].Tp for i in 1:nsec], afs=su.afs,
    )
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
        peak_an = maximum(spl_dB_to_peak_Pa.(anopp[key]))
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

"""Integer-order Bessel J_n(x) series (loading-noise Gutin closed form)."""
function _besselj_int(n::Int, x::Float64)
    n = abs(n)
    term = (x / 2)^n
    for i in 1:n
        term /= i
    end
    s = term
    for k in 1:60
        term *= -(x / 2)^2 / (k * (n + k))
        s += term
        abs(term) < 1e-16 * (1 + abs(s)) && break
    end
    return s
end

"""
    f1a_gutin_h1_comparison(; aircraft_json, r_over_Rtip=100) -> NamedTuple

I-01 (c) / F1A_GUTIN: static, thickness-off F1A H1 SPL vs Gutin's closed form on the same BEMT
loads at an in-plane observer `r_over_Rtip * Rtip` from the hub.

Gutin (Goldstein, *Aeroacoustics*; Hubbard, NASA RP-1258 vol. 1 ch. 1), harmonic m, far field:
p_rms = (mBΩ/(2√2 π c₀ r)) |−T cos θ + Q c₀/(Ω R²)| J_mB(mBΩR sin θ/c₀) for loads at radius R.
In the rotor plane (θ = π/2) only the torque radiates. The blade is summed annulus by annulus
(each at its own radius; the sections of an unswept blade radiate in phase), with the trapezoid
weights and hub/tip zero padding that `CCBlade.thrusttorque` uses, so Σ dQ = Q.
Code-on-code fix 2026-10-24: the earlier form (mBΩ/(2π c₀ r))(Q/R_tip) J_mB(mB M_tip) was low by
√2·M (a single-radius source shows it: the independent F1A of case F1A_INDEP equals the form above
within 0.03 %, test/unit/test_case_helpers_iso.jl); its near-agreement with F1A came from
evaluating J_mB at the tip.
"""
function f1a_gutin_h1_comparison(;
        aircraft_json::AbstractString=joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json"),
        r_over_Rtip::Float64=100.0,
        num_src_times::Int=128)
    txt = read(aircraft_json, String)
    txt = replace(txt, r"\"forward_speed_mps\"\s*:\s*[0-9.eE+-]+" => "\"forward_speed_mps\": 0.0")
    txt = replace(txt, r"\"thickness_over_chord\"\s*:\s*[0-9.eE+-]+" => "\"thickness_over_chord\": 0.0")
    tmp = joinpath(tempdir(), "pain_gutin_static_$(hash(aircraft_json)).json")
    write(tmp, txt)
    try
        cfg = _load_aircraft_json(tmp)
        Rtip = Float64(cfg.propeller.tip_radius_m)
        r_ff = r_over_Rtip * Rtip
        obs = [Observer([0.0, r_ff, 0.0], zeros(3), "ff_plane")]
        src = evaluate_propeller_source(cfg, obs; n_harmonics=1, num_src_times=num_src_times,
                                        allow_static=true)
        sec = ccblade_section_operating_points(cfg; allow_static=true)
        Ω = Float64(cfg.propeller.rpm) * 2π / 60
        B = Int(cfg.propeller.num_blades)
        c0 = src.echo.c0
        m = 1
        Mt = Ω * Rtip / c0
        # trapezoid over [Rhub, r..., Rtip] with zero load at both ends (as CCBlade.thrusttorque)
        rr = vcat(sec.Rhub, sec.r_m, Rtip)
        Tp = vcat(0.0, sec.Tp, 0.0)
        w = zeros(length(rr))
        for k in 1:length(rr)-1
            h = rr[k+1] - rr[k]
            w[k] += h / 2; w[k+1] += h / 2
        end
        Q_sum = B * sum(w .* Tp .* rr)
        # in-plane: Σ (mBΩ/(2√2π c₀ r)) · dQ c₀/(Ω R²) · J_mB(mBΩR/c₀), dQ = B Tp R dR
        p_rms = sum(w[k] * (m * B / (2 * sqrt(2) * π * r_ff)) * B * Tp[k] / rr[k] *
                    _besselj_int(m * B, m * B * Ω * rr[k] / c0) for k in eachindex(rr))
        p_peak = sqrt(2) * abs(p_rms)
        spl_f1a = 20 * log10(max(src.amplitude[1, 1], 1e-30) / 2e-5)   # SPL of the peak
        spl_gutin = 20 * log10(max(p_peak, 1e-30) / 2e-5)              # SPL of the peak
        Δ = spl_f1a - spl_gutin
        return (;
            spl_f1a, spl_gutin, delta_dB=Δ, ok=abs(Δ) ≤ 1.0,
            T=src.T, Q=src.Q, Q_sum, Mt, B, Rtip, r_ff, c0, Ω,
            aircraft_json=abspath(aircraft_json),
        )
    finally
        rm(tmp; force=true)
    end
end

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
