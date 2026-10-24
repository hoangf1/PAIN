# Phase 31 — epistemic uncertainty budget for the aircraft cabin result (31a–31f).
# Pre-registration fixed 2026-10-22 (spec phase31_uncertainty.md / IMPLEMENTATION_PLAN).
# Band is epistemic, not a confidence interval; not a validation. No range widened here.

using Random
using Statistics

# ---------------------------------------------------------------------------------------------
# Budget table
# ---------------------------------------------------------------------------------------------

"""One row of the phase-31 uncertainty budget (31a)."""
struct UncertaintyBudgetRow
    name::String
    nominal::Float64                 # NaN when discrete-only / excluded
    range_lo::Float64                # NaN when N/A
    range_hi::Float64
    basis::String
    provenance_tag::String           # "assumed" | "measured" | "nasa_default" | "excluded" | …
    type::Symbol                     # :continuous | :discrete | :bounding | :excluded
    alternatives::Vector{Float64}    # discrete values (empty for continuous)
    labels::Vector{String}           # optional labels for discrete alts
end

"""Full budget for one context (`:testarticle` or `:aircraft`)."""
struct UncertaintyBudget
    context::Symbol
    rows::Vector{UncertaintyBudgetRow}
    notes::Vector{String}
end

const UNC_MC_N = 4000
const UNC_MC_SEED = 20261022
const UNC_OAT_KEEP_DB = 3.0
const UNC_FREQ_SCALE_NOM = 1.0
const UNC_FREQ_SCALE_LO = 0.95
const UNC_FREQ_SCALE_HI = 1.05

"""Pre-registered budget rows (2026-10-22). `context=:testarticle` | `:aircraft`."""
function uncertainty_budget(context::Symbol=:testarticle;
                            trimmed::Bool=(context === :testarticle))
    context in (:testarticle, :aircraft) || error("context must be :testarticle or :aircraft")
    notes = String[
        "Pre-registered 2026-10-22 before any phase-31 run (spec phase31_uncertainty.md).",
        "Ranges from VALIDATION_GUIDELINE §2.11 / IMPLEMENTATION_PLAN phase 31 loss-factor table.",
        "Source-side residuals of phases 24–28 apply to the aircraft run only; coverage check uses NASA free field.",
    ]
    rows = UncertaintyBudgetRow[]

    # η_t lining/facing (13a f / plan table). Nominal 0.05, 0.01–0.10.
    # On a bare cabin the lining is absent → excluded for that path.
    if trimmed
        push!(rows, UncertaintyBudgetRow(
            "eta_t", 0.05, 0.01, 0.10,
            "13a f / plan phase-31 table: lining/facing flexural loss factor (Eq. A.11); aircraft register default 0.05, range 0.01–0.10",
            "assumed", :continuous, Float64[], String[]))
    else
        push!(rows, UncertaintyBudgetRow(
            "eta_t", 0.05, 0.01, 0.10,
            "13a f: lining/facing loss factor — cabin is bare on this path → not applicable",
            "excluded", :excluded, Float64[], String[]))
        push!(notes, "eta_t excluded: cabin untrimmed (bare); lining loss factor does not enter.")
    end

    # C of Eq. (80)
    push!(rows, UncertaintyBudgetRow(
        "C_struc", 3.0, 2.0, 4.0,
        "13a g / CR-3813 §3.8.2: C of Eq. (80), η_r^struc = C/f_r; range 2–4",
        "assumed", :continuous, Float64[], String[]))

    # Bare-cabin η_n — only when untrimmed
    if !trimmed
        push!(rows, UncertaintyBudgetRow(
            "eta_n_bare", 0.05, 0.02, 0.10,
            "13a g: bare-cabin η_n (measured in CR-3813; assumed here); only when untrimmed",
            "assumed", :continuous, Float64[], String[]))
    else
        push!(rows, UncertaintyBudgetRow(
            "eta_n_bare", 0.05, 0.02, 0.10,
            "13a g: bare η_n — trimmed path → not applicable",
            "excluded", :excluded, Float64[], String[]))
        push!(notes, "eta_n_bare excluded: cabin is trimmed (Phase III / user trim).")
    end

    # Common structural-frequency scale (flowchart 5 % frequency tolerance)
    push!(rows, UncertaintyBudgetRow(
        "freq_scale", UNC_FREQ_SCALE_NOM, UNC_FREQ_SCALE_LO, UNC_FREQ_SCALE_HI,
        "flowchart 5 % structural-frequency tolerance: one common scale factor on all mode frequencies",
        "assumed", :continuous, Float64[], String[]))

    # CYL2D node rule (13a a): discrete alternatives in the window that keeps the paper grid
    push!(rows, UncertaintyBudgetRow(
        "cyl2d_node_tol", 0.4, 0.32, 0.47,
        "13a a: CYL2D node rule r ≤ 1 + α·h; 0.32h–0.47h gives the same paper grid (15a)",
        "assumed", :discrete, [0.32, 0.40, 0.47], ["0.32h", "0.40h", "0.47h"]))

    # Axial truncation (13a d): default rule vs default+2
    push!(rows, UncertaintyBudgetRow(
        "q_max_delta", 0.0, 0.0, 2.0,
        "13a d: axial truncation q ≤ ⌈2ω_H L/(π c0)⌉; alternatives default and default+2 (convergence check)",
        "assumed", :discrete, [0.0, 2.0], ["q_default", "q_default+2"]))

    # Blocking R1 vs R2
    push!(rows, UncertaintyBudgetRow(
        "blocking", 2.0, 1.0, 2.0,
        "Blocking revision R1 vs R2 (Eq. 43); discrete equiprobable",
        "assumed", :discrete, [1.0, 2.0], ["R1", "R2"]))

    # Trim-stack alternatives (13a f) — discrete; only when trimmed
    if trimmed
        push!(rows, UncertaintyBudgetRow(
            "facing_side", 0.0, 0.0, 1.0,
            "13a f: facing side of each layer — cabin side (0) or skin side (1)",
            "assumed", :discrete, [0.0, 1.0], ["cabin", "skin"]))
        push!(rows, UncertaintyBudgetRow(
            "mech_conn", 0.0, 0.0, 2.0,
            "13a f: mechanical connections — 9 points + 2 lines (0), points only (1), lines only (2)",
            "assumed", :discrete, [0.0, 1.0, 2.0], ["points+lines", "points", "lines"]))
        push!(rows, UncertaintyBudgetRow(
            "G10_wavespeed", 3200.0, 2800.0, 3600.0,
            "13a f: G-10 wavespeed 2800–3600 m/s (discrete ends + nominal for sampling)",
            "assumed", :discrete, [2800.0, 3200.0, 3600.0], ["2800", "3200", "3600"]))
        push!(rows, UncertaintyBudgetRow(
            "allow_extrapolation", 0.0, 0.0, 1.0,
            "13a e: insulation-table extension X-EXTRAP only if the table does not cover a harmonic (flag)",
            "assumed", :discrete, [0.0, 1.0], ["no_ext", "X-EXTRAP"]))
    else
        push!(rows, UncertaintyBudgetRow(
            "facing_side", NaN, NaN, NaN,
            "13a f trim alternatives — not applicable on bare cabin",
            "excluded", :excluded, Float64[], String[]))
        push!(rows, UncertaintyBudgetRow(
            "mech_conn", NaN, NaN, NaN,
            "13a f trim alternatives — not applicable on bare cabin",
            "excluded", :excluded, Float64[], String[]))
        push!(rows, UncertaintyBudgetRow(
            "G10_wavespeed", NaN, NaN, NaN,
            "13a f G-10 wavespeed — not applicable on bare cabin",
            "excluded", :excluded, Float64[], String[]))
        push!(rows, UncertaintyBudgetRow(
            "allow_extrapolation", NaN, NaN, NaN,
            "13a e insulation extension — not applicable on bare cabin (no insulation table)",
            "excluded", :excluded, Float64[], String[]))
        push!(notes, "Trim-stack / insulation rows excluded: cabin is bare.")
    end

    # Source-side residuals (aircraft only): ranges not stated in §2.11 → excluded
    if context === :aircraft
        push!(rows, UncertaintyBudgetRow(
            "source_amp_residual", NaN, NaN, NaN,
            "phases 24–28 amplitude residual — not registered: excluded (no range in §2.11)",
            "excluded", :excluded, Float64[], String[]))
        push!(rows, UncertaintyBudgetRow(
            "source_polar_bracket", NaN, NaN, NaN,
            "Pereira polar bracket — not registered: excluded (no continuous range in §2.11 for the aircraft budget)",
            "excluded", :excluded, Float64[], String[]))
        push!(rows, UncertaintyBudgetRow(
            "pereira_1p7_dB", NaN, NaN, NaN,
            "Pereira ±1.7 dB measurement uncertainty — not registered as a sampled range: excluded from MC; stated as evidence only",
            "excluded", :excluded, Float64[], String[]))
        push!(rows, UncertaintyBudgetRow(
            "phase_bbn_residual", NaN, NaN, NaN,
            "BBN H1 residual gradient ratio — bounding case only (31c), not Monte-Carlo sampled",
            "assumed", :bounding, Float64[], String[]))
        push!(notes, "Source residuals: amplitude/polar/Pereira ±1.7 dB marked not registered: excluded; phase via 31c bounding cases.")
    else
        push!(notes, "Source-side residuals of phases 24–28 do not apply to the test-article coverage check.")
        push!(notes, "NASA's Phase III value η_T = 0.5 (CR-3813 p. E-24, `phase3_trim` default) lies outside the registered 0.01–0.10 range; the pre-registered range is used unchanged.")
    end

    # Scattering / refraction: V-ASSUMED, no range
    push!(rows, UncertaintyBudgetRow(
        "scattering_refraction", NaN, NaN, NaN,
        "Scattering and refraction: V-ASSUMED condition; no range invented (31c)",
        "excluded", :excluded, Float64[], String[]))
    push!(notes, "Scattering/refraction: V-ASSUMED; no range invented.")

    return UncertaintyBudget(context, rows, notes)
end

active_budget_rows(b::UncertaintyBudget) =
    [r for r in b.rows if r.type === :continuous || r.type === :discrete]

# ---------------------------------------------------------------------------------------------
# Cached evaluator (modes cached; perturb loss / scale / discrete cheaply)
# ---------------------------------------------------------------------------------------------

"""Cached free-field + modes for repeated OAT / Monte Carlo samples."""
mutable struct UncertaintyChainCache
    fuse::FuselageGeometry
    prop::PropellerPlacement
    ff::FreeFieldHarmonicGrid
    bpf_Hz::Float64
    n_harmonics::Int
    structural0::StructuralModes
    acoustic_by_tol::Dict{Float64,Cyl2DResult}
    trimmed::Bool
    context::Symbol
    ΔA::Float64
    num_blades::Int   # B: aircraft JSON; test article = 3 (CR-3813 / Table 8 Hartzell)
end

function _blocking_of(code::Real)
    Int(round(code)) == 1 ? R1 : R2
end

function _scale_structural(st::StructuralModes, s::Float64)
    s == 1.0 && return st
    modes = [StructuralMode(m.index, s * m.f_Hz, m.symmetric, m.M_r, m.M_axial,
                            m.C_shell, m.n_shell, m.C_floor, m.n_floor) for m in st.modes]
    return StructuralModes(modes, st.L, st.a, st.theta0_deg, st.notes * " | freq_scale=$(s)")
end

"""Build the test-article parametric chain cache (NASA free field, App. D, Phase III trim path)."""
function build_testarticle_cache(; n_harmonics::Int=3, bpf_Hz::Float64=200.0,
                                  node_tols=(0.32, 0.40, 0.47))
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    paths = default_e11_paths()
    nH = min(n_harmonics, 3)
    ff = freefield_from_e11_csv(paths.A, paths.phases, fuse, prop, GridSpec();
                                bpf_Hz=bpf_Hz, n_harmonics=nH,
                                anopp_spl_csv=paths.anopp_spl, broadband_clip_dB=10.0)
    structural0 = build_structural_modes(fuse; structural_solver=:appd, n_keep=32)
    acoustic_by_tol = Dict{Float64,Cyl2DResult}()
    for t in node_tols
        acoustic_by_tol[Float64(t)] = cyl2d_modes(56.6; n_modes=20, NY=10, c0=340.0, node_tol=Float64(t))
    end
    ΔA = (π * fuse.a / 18)^2
    # Blade count for the e11 / CR-3813 path: 3-bladed Hartzell (data/cr3813/e11_freefield_measured_A.csv
    # header "3-blade @ 4000 rpm"; anopp_table8_phases_deg.csv "3-bladed Hartzell @ 4000 rpm").
    B = 3
    return UncertaintyChainCache(fuse, prop, ff, bpf_Hz, nH, structural0, acoustic_by_tol,
                                 true, :testarticle, ΔA, B)
end

"""Build the aircraft working-example cache (F1A free field, bare cabin, parametric)."""
function build_aircraft_cache(aircraft_json::AbstractString;
                              n_harmonics::Int=3,
                              node_tols=(0.32, 0.40, 0.47))
    cfg = _load_aircraft_json(String(aircraft_json))
    hasproperty(cfg, :propeller) || error("aircraft JSON missing propeller")
    hasproperty(cfg.propeller, :num_blades) || error("aircraft JSON missing propeller.num_blades")
    B = Int(cfg.propeller.num_blades)
    B > 0 || error("aircraft propeller.num_blades must be positive (got $B)")
    r0 = run_pain_pipeline(; source=:aircraft, aircraft_json=String(aircraft_json),
                           n_harmonics=n_harmonics, cabin_blocks=:parametric)
    fuse, prop, ff = r0.fuse, r0.prop, r0.ff
    # ff from pipeline is already blocked; recover free field by re-running propeller
    ff_free = propeller_freefield_grid(String(aircraft_json), fuse, prop, GridSpec();
                                       n_harmonics=n_harmonics)
    structural0 = r0.structural
    acoustic_by_tol = Dict{Float64,Cyl2DResult}()
    for t in node_tols
        acoustic_by_tol[Float64(t)] = cyl2d_modes(fuse.theta0_deg; n_modes=20, NY=10,
                                                   c0=340.0, node_tol=Float64(t))
    end
    ΔA = (π * fuse.a / 18)^2
    return UncertaintyChainCache(fuse, prop, ff_free, ff_free.bpf_Hz, n_harmonics, structural0,
                                 acoustic_by_tol, false, :aircraft, ΔA, B)
end

"""Sample dictionary: name → value (continuous or discrete code)."""
function nominal_sample(budget::UncertaintyBudget)
    d = Dict{String,Float64}()
    for r in active_budget_rows(budget)
        d[r.name] = r.nominal
    end
    return d
end

"""Evaluate H1–H3 (and optional third-octave bands) for one sample. Returns NamedTuple."""
function evaluate_uncertainty_sample(cache::UncertaintyChainCache, sample::Dict{String,Float64};
                                     phases_override=nothing,
                                     want_bands::Bool=false)
    η_t = get(sample, "eta_t", 0.05)
    C = get(sample, "C_struc", 3.0)
    η_n = get(sample, "eta_n_bare", 0.05)
    s_f = get(sample, "freq_scale", 1.0)
    node_tol = get(sample, "cyl2d_node_tol", 0.40)
    q_delta = get(sample, "q_max_delta", 0.0)
    blk_code = get(sample, "blocking", 2.0)
    facing = get(sample, "facing_side", 0.0)
    mech_c = get(sample, "mech_conn", 0.0)
    G10 = get(sample, "G10_wavespeed", 3200.0)
    allow_ext = get(sample, "allow_extrapolation", 0.0) ≥ 0.5

    # Snap node_tol to a cached key (nearest)
    tols = collect(keys(cache.acoustic_by_tol))
    node_tol = tols[argmin(abs.(tols .- node_tol))]
    acoustic = cache.acoustic_by_tol[node_tol]
    structural = _scale_structural(cache.structural0, s_f)

    variant = _blocking_of(blk_code)
    bl = apply_blocking(cache.ff, cache.fuse, cache.prop; variant=variant)
    amps = bl.amplitudes
    phases = phases_override === nothing ? bl.phases : phases_override

    sidewall = endplates = mech = nothing
    m_wall = NaN
    if cache.trimmed
        facing_side = Int(round(facing)) == 0 ? :cabin : :skin
        N_points = 9
        n_lines = 2
        mc = Int(round(mech_c))
        if mc == 1
            N_points, n_lines = 9, 0
        elseif mc == 2
            N_points, n_lines = 0, 2
        end
        p3 = phase3_trim(; a=cache.fuse.a, L=cache.fuse.L, theta0_deg=cache.fuse.theta0_deg,
                         η_lining=η_t, facing_side=facing_side, G10_wavespeed=G10,
                         N_points=N_points, n_lines=n_lines)
        sidewall, endplates, mech = p3.sidewall, p3.ends, p3.mech
        m_wall = p3.m_wall
    end

    inp = PainInputs(cache.fuse, cache.prop, structural, acoustic, amps, phases, bl.pts, cache.ΔA;
                     sidewall=sidewall, endplates=endplates, mech=mech, m_wall=m_wall,
                     η_n_bare=η_n, C_struc=C, allow_extrapolation=allow_ext)

    pref = 20e-6
    spl = zeros(Float64, cache.n_harmonics)
    for H in 1:cache.n_harmonics
        ωH = 2π * H * cache.bpf_Hz
        q0 = axial_truncation(ωH, inp.L_c, inp.c_int)
        q_max = q0 + Int(round(q_delta))
        p2 = tone_mean_square_pressure(inp, H, ωH; q_max=q_max, η_r_cap=nothing)
        spl[H] = 10 * log10(p2 / pref^2 + 1e-30)
    end

    bands = Dict{Float64,Float64}()
    if want_bands
        spec = interior_spl(inp; bpf_Hz=cache.bpf_Hz, n_harmonics=cache.n_harmonics,
                            broadband=true, broadband_model=:eq19, η_r_cap=nothing)
        bands = Dict(spec.third_octave_SPL_dB)
        # Prefer tonal SPLs from the explicit q_max path above
    end
    return (; H=spl, bands, inp)
end

# ---------------------------------------------------------------------------------------------
# OAT (31b)
# ---------------------------------------------------------------------------------------------

"""One-at-a-time sweep. Returns ranked table: (name, swing_dB, keep, per-H swings)."""
function oat_sweep(cache::UncertaintyChainCache, budget::UncertaintyBudget;
                   keep_dB::Float64=UNC_OAT_KEEP_DB, n_cont::Int=5)
    nom = nominal_sample(budget)
    base = evaluate_uncertainty_sample(cache, nom).H
    ranked = NamedTuple[]
    for r in active_budget_rows(budget)
        swings = zeros(Float64, cache.n_harmonics)
        nH = cache.n_harmonics
        if r.type === :continuous
            vals = collect(range(r.range_lo, r.range_hi; length=n_cont))
            mats = Matrix{Float64}(undef, length(vals), nH)
            for (i, v) in enumerate(vals)
                s = copy(nom); s[r.name] = Float64(v)
                mats[i, :] .= evaluate_uncertainty_sample(cache, s).H
            end
            for H in 1:nH
                swings[H] = maximum(mats[:, H]) - minimum(mats[:, H])
            end
        else
            mats = Matrix{Float64}(undef, length(r.alternatives), nH)
            for (i, v) in enumerate(r.alternatives)
                s = copy(nom); s[r.name] = v
                mats[i, :] .= evaluate_uncertainty_sample(cache, s).H
            end
            for H in 1:nH
                swings[H] = maximum(mats[:, H]) - minimum(mats[:, H])
            end
        end
        swing = maximum(swings)
        push!(ranked, (; name=r.name, swing_dB=swing, keep=(swing > keep_dB),
                         H1=swings[1],
                         H2=(nH ≥ 2 ? swings[2] : NaN),
                         H3=(nH ≥ 3 ? swings[3] : NaN)))
    end
    sort!(ranked; by=x -> -x.swing_dB)
    return ranked
end

# ---------------------------------------------------------------------------------------------
# Sampling helpers
# ---------------------------------------------------------------------------------------------

function _rand_uniform(rng, lo, hi)
    lo + (hi - lo) * rand(rng)
end

"""Triangular on [lo, hi] with mode at `mode` (must lie in [lo, hi])."""
function _rand_triangular(rng, lo, hi, mode)
    lo == hi && return lo
    @assert lo ≤ mode ≤ hi
    Fc = (mode - lo) / (hi - lo)
    u = rand(rng)
    if u < Fc
        return lo + sqrt(u * (hi - lo) * (mode - lo))
    else
        return hi - sqrt((1 - u) * (hi - lo) * (hi - mode))
    end
end

function _sample_row!(rng, r::UncertaintyBudgetRow, family::Symbol)
    if r.type === :discrete
        return rand(rng, r.alternatives)
    elseif r.type === :continuous
        if family === :uniform
            return _rand_uniform(rng, r.range_lo, r.range_hi)
        elseif family === :triangular
            return _rand_triangular(rng, r.range_lo, r.range_hi, r.nominal)
        else
            error("unknown family $family")
        end
    else
        return r.nominal
    end
end

function _draw_sample(rng, budget::UncertaintyBudget, kept::Vector{String}, family::Symbol)
    nom = nominal_sample(budget)
    byname = Dict(r.name => r for r in active_budget_rows(budget))
    s = copy(nom)
    for name in kept
        haskey(byname, name) || continue
        s[name] = _sample_row!(rng, byname[name], family)
    end
    return s
end

# ---------------------------------------------------------------------------------------------
# Monte Carlo (31d)
# ---------------------------------------------------------------------------------------------

"""
Monte Carlo band over `kept` parameter names.
`family` = `:uniform` (primary) or `:triangular` (mode = nominal).
Returns percentiles P5/P50/P95 per harmonic, optional bands, Spearman ranks, samples matrix.
"""
function monte_carlo_band(cache::UncertaintyChainCache, budget::UncertaintyBudget,
                          kept::Vector{String};
                          N::Int=UNC_MC_N, seed::Int=UNC_MC_SEED,
                          family::Symbol=:uniform, want_bands::Bool=false)
    rng = MersenneTwister(seed)
    nH = cache.n_harmonics
    Hmat = Matrix{Float64}(undef, N, nH)
    param_mat = Dict{String,Vector{Float64}}(name => Vector{Float64}(undef, N) for name in kept)
    band_keys = Float64[]
    band_mats = Dict{Float64,Vector{Float64}}()
    for i in 1:N
        s = _draw_sample(rng, budget, kept, family)
        for name in kept
            param_mat[name][i] = s[name]
        end
        ev = evaluate_uncertainty_sample(cache, s; want_bands=want_bands)
        Hmat[i, :] .= ev.H
        if want_bands
            if isempty(band_keys)
                band_keys = sort(collect(keys(ev.bands)))
                for b in band_keys
                    band_mats[b] = Vector{Float64}(undef, N)
                end
            end
            for b in band_keys
                band_mats[b][i] = get(ev.bands, b, NaN)
            end
        end
    end
    function _pcts(col)
        q = quantile(col, (0.05, 0.50, 0.95))
        return (; P5=q[1], P50=q[2], P95=q[3])
    end
    harm = [_pcts(Hmat[:, H]) for H in 1:nH]
    bands = Dict{Float64,NamedTuple}(b => _pcts(band_mats[b]) for b in band_keys)
    # Spearman rank correlations of each kept parameter with each harmonic
    spearman = Dict{String,Vector{Float64}}()
    for name in kept
        spearman[name] = [_spearman(param_mat[name], Hmat[:, H]) for H in 1:nH]
    end
    return (; family, N, seed, kept, harm, bands, spearman, Hmat, param_mat)
end

function _spearman(x::AbstractVector, y::AbstractVector)
    n = length(x)
    n == 0 && return NaN
    rx = invperm(sortperm(x))
    ry = invperm(sortperm(y))
    return cor(Float64.(rx), Float64.(ry))
end

# ---------------------------------------------------------------------------------------------
# Coverage check (31e)
# ---------------------------------------------------------------------------------------------

"""
31e: P5–P95 of the primary (uniform) Monte Carlo must contain the measured E-16 mean
at each of H1, H2, H3. Verdict `:met` only if all three are inside.
"""
function coverage_check(mc_primary; measured_means::AbstractVector{<:Real})
    nH = min(length(mc_primary.harm), length(measured_means))
    rows = NamedTuple[]
    all_in = true
    for H in 1:nH
        p = mc_primary.harm[H]
        m = Float64(measured_means[H])
        inside = p.P5 ≤ m ≤ p.P95
        # margin to nearest band edge (positive = inside)
        margin = inside ? min(m - p.P5, p.P95 - m) : -min(abs(m - p.P5), abs(m - p.P95))
        all_in &= inside
        push!(rows, (; H, measured=m, P5=p.P5, P50=p.P50, P95=p.P95,
                       inside, margin_dB=margin))
    end
    return (; verdict=(all_in ? :met : :not_met), rows, label="V-EXP vs measured E-16 means; first run 2026-10-22; pre-registered")
end

function e16_measured_means()
    targets = joinpath(dirname(default_e11_paths().A), "t1_interior_targets.csv")
    cols = _read_csv_numeric(targets)
    return Float64[cols[:measured_mean_SPL_dB][i] for i in eachindex(cols[:harmonic])]
end

# ---------------------------------------------------------------------------------------------
# Phase bounding cases (31c)
# ---------------------------------------------------------------------------------------------

"""
Median over qualifying BBN H1 rows of residual/f1a (dimensionless): measured-minus-predicted
circumferential phase difference relative to the predicted one.
Rows: kind=circ, tip=tipA, pair ∈ {4-3,5-3,4-5}, harmonic=1, coherence ≥ 0.15
from `data/NASA_CR-158919/bbn_results.csv`. No fallback — errors if file or rows missing.
"""
function bbn_h1_residual_gradient_ratio()
    path = joinpath(@__DIR__, "..", "..", "data", "NASA_CR-158919", "bbn_results.csv")
    isfile(path) || error("missing BBN results CSV: $path")
    ratios = Float64[]
    for (i, line) in enumerate(eachline(path))
        i == 1 && continue
        parts = split(strip(line), ',')
        length(parts) < 11 && continue
        kind = parts[1]
        tip = parts[2]
        pair = parts[5]
        harm = tryparse(Int, parts[6])
        f1a = tryparse(Float64, parts[9])
        resid = tryparse(Float64, parts[10])
        coh = tryparse(Float64, parts[11])
        kind == "circ" || continue
        tip == "tipA" || continue
        pair in ("4-3", "5-3", "4-5") || continue
        harm == 1 || continue
        (coh === nothing || coh < 0.15) && continue
        (resid === nothing || f1a === nothing || f1a == 0.0) && continue
        push!(ratios, resid / f1a)
    end
    isempty(ratios) && error("no qualifying BBN H1 circ rows (tipA, coh≥0.15) in $path")
    return median(ratios)
end

"""
Phase bounding cases on a cache:
  (i) BBN H1 residual gradient ratio applied per observer as k·H·B·Δψ (bounding case);
  (ii) fully random phase (extreme only; seed UNC_MC_SEED).
`k_override` replaces the CSV-derived k (unit test: k=0 → nominal SPL).
`bl.phases` is (k, ℓ, H); offsets are written at (p.k, p.ell, H) for each observer p.
"""
function phase_bounding_cases(cache::UncertaintyChainCache, budget::UncertaintyBudget;
                              seed::Int=UNC_MC_SEED,
                              k_override::Union{Nothing,Real}=nothing)
    nom = nominal_sample(budget)
    base = evaluate_uncertainty_sample(cache, nom).H

    k = k_override === nothing ? bbn_h1_residual_gradient_ratio() : Float64(k_override)
    B = cache.num_blades
    φp = cache.prop.phi_p_deg
    bl = apply_blocking(cache.ff, cache.fuse, cache.prop; variant=R2)
    # phases layout: Array{Float64,3} indexed [k, ell, H] (same as PainInputs / FreeFieldHarmonicGrid)
    phases_bbn = copy(bl.phases)
    nH_ph = size(phases_bbn, 3)
    for p in cache.ff.pts
        Δψ = deg2rad(p.theta_deg - φp)
        for H in 1:nH_ph
            phases_bbn[p.k, p.ell, H] += k * H * B * Δψ
        end
    end
    H_bbn = evaluate_uncertainty_sample(cache, nom; phases_override=phases_bbn).H

    # (ii) fully random phase (extreme)
    rng = MersenneTwister(seed)
    phases_rand = 2π .* rand(rng, size(bl.phases)...) .- π
    H_rand = evaluate_uncertainty_sample(cache, nom; phases_override=phases_rand).H

    nH = cache.n_harmonics
    spread_i = zeros(Float64, nH)
    spread_ii = zeros(Float64, nH)
    for H in 1:nH
        spread_i[H] = abs(H_bbn[H] - base[H])
        spread_ii[H] = abs(H_rand[H] - base[H])
    end
    return (; nominal=base, bbn_residual=H_bbn, random=H_rand,
              spread_i_dB=spread_i, spread_ii_dB=spread_ii,
              k, B, scattering_refraction="V-ASSUMED; no range invented",
              phase_i_note="(i) BBN H1 residual expressed as a ratio to the predicted circumferential phase difference, applied per observer as k·H·B·Δψ; defined 2026-10-22 before the aircraft band run.")
end

# ---------------------------------------------------------------------------------------------
# Reporting template (31f)
# ---------------------------------------------------------------------------------------------

const UNC_REQUIRED_STATEMENTS = (
    "The band is epistemic and not a confidence interval.",
    "The band excludes scattering and refraction (V-ASSUMED).",
    "The band is conditional on the transferability allowance.",
    "Every cabin input except the 2.64 m diameter is assumed.",
    "The result is not validated and is not NASA's accuracy.",
    "Report median and percentiles, never the mean; no single dB value without the band.",
    "Phase is the dominant uncertainty when its bounding-case spread exceeds the Monte Carlo P5–P95 width.",
)

"""
31f reporting template. Always prints the required statements. `provenance_tags` lists
cabin inputs tagged assumed (generated from provenance); diameter note is fixed for the
working example.
"""
function uncertainty_report_md(; title::AbstractString,
                                budget::UncertaintyBudget,
                                oat=nothing,
                                mc_uniform=nothing,
                                mc_triangular=nothing,
                                coverage=nothing,
                                phase=nothing,
                                provenance_tags::AbstractVector{<:AbstractString}=String[],
                                runtime_s::Union{Nothing,Real}=nothing,
                                extra_sections::AbstractVector{<:AbstractString}=String[])
    io = IOBuffer()
    println(io, "# ", title)
    println(io)
    println(io, "**Phase 31. Pre-registration fixed 2026-10-22 (before this run).**")
    println(io)
    println(io, "## Required statements (31f)")
    println(io)
    if budget.context === :testarticle
        println(io, "These statements apply to the aircraft band (`uncertainty_aircraft_band.md`); this report is the 31e coverage check on the NASA test article (diameter 1.016 m, NASA free field).")
        println(io)
    end
    for s in UNC_REQUIRED_STATEMENTS
        println(io, "- ", s)
    end
    println(io)
    println(io, "Do not quote the +2.6 to +4.3 dB flight bias or \"10 dB\" as an error bar for this aircraft.")
    println(io)
    if budget.context === :aircraft
        if !isempty(provenance_tags)
            println(io, "Cabin inputs tagged assumed (working example; only the 2.64 m diameter is given as measured geometry): ",
                    join(provenance_tags, ", "), ".")
        else
            println(io, "Every cabin input except the 2.64 m diameter is assumed (working-example provenance).")
        end
        println(io)
    end

    println(io, "## Budget table (31a)")
    println(io)
    println(io, "| Parameter | Nominal | Range / alternatives | Type | Provenance | Basis |")
    println(io, "|-----------|--------:|----------------------|------|------------|-------|")
    for r in budget.rows
        rng = if r.type === :excluded
            "not registered: excluded"
        elseif r.type === :bounding
            "bounding case only"
        elseif r.type === :discrete
            join(string.(isempty(r.labels) ? r.alternatives : r.labels), ", ")
        else
            "$(r.range_lo)–$(r.range_hi)"
        end
        nom = isnan(r.nominal) ? "—" : string(r.nominal)
        println(io, "| ", r.name, " | ", nom, " | ", rng, " | ", r.type, " | ",
                r.provenance_tag, " | ", r.basis, " |")
    end
    println(io)
    for n in budget.notes
        println(io, "- ", n)
    end
    println(io)

    if oat !== nothing
        println(io, "## OAT ranking (31b)")
        println(io)
        println(io, "Keep if swing in any of H1–H3 exceeds $(UNC_OAT_KEEP_DB) dB; others fixed at nominal in 31d.")
        println(io)
        println(io, "| Parameter | Swing H1 [dB] | Swing H2 [dB] | Swing H3 [dB] | Max | Keep? |")
        println(io, "|-----------|--------------:|--------------:|--------------:|----:|:-----:|")
        for row in oat
            println(io, "| ", row.name, " | ", round(row.H1; digits=2), " | ",
                    round(row.H2; digits=2), " | ", round(row.H3; digits=2), " | ",
                    round(row.swing_dB; digits=2), " | ", (row.keep ? "yes" : "no"), " |")
        end
        println(io)
    end

    function _write_mc(label, mc)
        mc === nothing && return
        println(io, "## Monte Carlo — ", label, " (N=$(mc.N), seed=$(mc.seed))")
        println(io)
        println(io, "Kept parameters: ", join(mc.kept, ", "), ".")
        println(io)
        println(io, "| Harmonic | P5 [dB] | P50 [dB] | P95 [dB] | width P95−P5 |")
        println(io, "|----------|--------:|---------:|---------:|-------------:|")
        for (H, p) in enumerate(mc.harm)
            println(io, "| H$H | ", round(p.P5; digits=2), " | ", round(p.P50; digits=2),
                    " | ", round(p.P95; digits=2), " | ", round(p.P95 - p.P5; digits=2), " |")
        end
        if !isempty(mc.bands)
            println(io)
            println(io, "### 1/3-octave bands (P5 / P50 / P95)")
            println(io)
            println(io, "| fc [Hz] | P5 | P50 | P95 |")
            println(io, "|--------:|---:|----:|----:|")
            function _band_cell(v)
                (isfinite(v) && v < -200.0) ? "—" : string(round(v; digits=2))
            end
            for b in sort(collect(keys(mc.bands)))
                p = mc.bands[b]
                println(io, "| ", Int(round(b)), " | ", _band_cell(p.P5), " | ",
                        _band_cell(p.P50), " | ", _band_cell(p.P95), " |")
            end
            println(io)
            println(io, "Values below −200 dB (no energy in that band) are shown as —.")
        end
        println(io)
        println(io, "### Spearman rank correlations (parameter vs H1–H3)")
        println(io)
        println(io, "| Parameter | ρ(H1) | ρ(H2) | ρ(H3) |")
        println(io, "|-----------|------:|------:|------:|")
        for name in mc.kept
            ρ = mc.spearman[name]
            println(io, "| ", name, " | ", round(ρ[1]; digits=3), " | ",
                    round(get(ρ, 2, NaN); digits=3), " | ", round(get(ρ, 3, NaN); digits=3), " |")
        end
        println(io)
    end
    _write_mc("uniform (primary)", mc_uniform)
    _write_mc("triangular (mode = nominal)", mc_triangular)

    if mc_uniform !== nothing && mc_triangular !== nothing
        println(io, "## Distribution-family sensitivity")
        println(io)
        println(io, "| Harmonic | ΔP5 (tri−uni) | ΔP50 | ΔP95 |")
        println(io, "|----------|-------------:|-----:|-----:|")
        for H in 1:length(mc_uniform.harm)
            u, t = mc_uniform.harm[H], mc_triangular.harm[H]
            println(io, "| H$H | ", round(t.P5 - u.P5; digits=2), " | ",
                    round(t.P50 - u.P50; digits=2), " | ", round(t.P95 - u.P95; digits=2), " |")
        end
        println(io)
    end

    if coverage !== nothing
        println(io, "## 31e coverage check (test article, untuned parametric, NASA free field)")
        println(io)
        println(io, "Criterion (pre-registered 2026-10-22): P5–P95 of the primary Monte Carlo contains the measured E-16 mean at each of H1, H2, H3. Verdict `:met` only if all three. No E-16 envelope floor; no tuned value; nothing widened on failure.")
        println(io)
        println(io, "**Verdict: `", coverage.verdict, "`** — ", coverage.label)
        println(io)
        println(io, "| Harmonic | Measured mean [dB] | P5 | P50 | P95 | Inside? | Margin to nearest edge [dB] |")
        println(io, "|----------|-------------------:|---:|----:|----:|:-------:|----------------------------:|")
        for row in coverage.rows
            println(io, "| H$(row.H) | ", row.measured, " | ", round(row.P5; digits=2), " | ",
                    round(row.P50; digits=2), " | ", round(row.P95; digits=2), " | ",
                    (row.inside ? "yes" : "no"), " | ", round(row.margin_dB; digits=2), " |")
        end
        println(io)
        if coverage.verdict !== :met
            println(io, "Failure recorded: the budget is missing a contributor or the ranges are too narrow. Nothing was widened in this run; any later revised ranges are post-hoc and must be labelled so.")
            println(io)
        end
    end

    if phase !== nothing
        println(io, "## Phase bounding cases (31c)")
        println(io)
        println(io, "Scattering/refraction: ", phase.scattering_refraction, ".")
        println(io)
        if hasproperty(phase, :phase_i_note)
            println(io, phase.phase_i_note)
            println(io)
        end
        println(io, "k (BBN H1 residual/f1a median) = ", round(phase.k; digits=4),
                "; B (blade count) = ", phase.B, ".")
        println(io)
        println(io, "Case (ii) fully random phase is the extreme only (seed UNC_MC_SEED); phase-dominance uses case (i).")
        println(io)
        println(io, "| Harmonic | Nominal [dB] | (i) BBN residual [dB] | (ii) Random [dB] | Spread (i) vs nom [dB] | Spread (ii) vs nom [dB] |")
        println(io, "|----------|-------------:|---------------------:|----------------:|-----------------------:|------------------------:|")
        for H in 1:length(phase.spread_i_dB)
            println(io, "| H$H | ", round(phase.nominal[H]; digits=2), " | ",
                    round(phase.bbn_residual[H]; digits=2), " | ",
                    round(phase.random[H]; digits=2), " | ",
                    round(phase.spread_i_dB[H]; digits=2), " | ",
                    round(phase.spread_ii_dB[H]; digits=2), " |")
        end
        println(io)
        if mc_uniform !== nothing
            println(io, "### Phase-dominance rule (case (i) bounding)")
            println(io)
            for H in 1:length(phase.spread_i_dB)
                width = mc_uniform.harm[H].P95 - mc_uniform.harm[H].P5
                dom = phase.spread_i_dB[H] > width
                println(io, "- H$H: case (i) spread $(round(phase.spread_i_dB[H]; digits=2)) dB ",
                        (dom ? ">" : "≤"), " MC width $(round(width; digits=2)) dB → ",
                        (dom ? "phase dominates" : "phase does not dominate"), ".")
            end
            println(io)
        end
    end

    for sec in extra_sections
        println(io, sec)
        println(io)
    end

    if runtime_s !== nothing
        println(io, "## Runtime")
        println(io)
        println(io, "Wall time: ", round(Float64(runtime_s); digits=1), " s.")
        println(io)
    end
    return String(take!(io))
end
