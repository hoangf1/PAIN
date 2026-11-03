"""
Polar loader for Report 996 / Pereira (phase 25i).

`load_polar_set(path; set=:primary|:bracket, cr75=nothing) -> (ps::PolarSet, stats)`; per-station polars via `section_polar` / `station_polars`.
Reads `polars_forced_merged.json` (Report 996) or Pereira `naca4412_xfoil_*.json`.
α in radians at the CCBlade interface.
"""

Base.@kwdef mutable struct PolarStats
    clamped_Re::Int = 0
    clamped_M::Int = 0
    viterna_evals::Int = 0
    nearest_polar::Int = 0
end

"""Directory of digitized airfoil section measurements (display only; not used by BEMT)."""
const _AIRFOIL_MEASURED_DIR = joinpath(@__DIR__, "..", "..", "data", "airfoil_measured")

"""Map polar-section keys to TN 1546 / Report 824 airfoil labels."""
const _MEASURED_AIRFOIL_NAME = Dict{String,String}(
    "n16_312" => "NACA 16-312",
    "n16_506" => "NACA 16-506",
    "n16_509" => "NACA 16-509",
    "naca4412" => "NACA 4412",
)

"""XFOIL Mach values that TN 1546 covers (overlay targets; no extrapolation)."""
const _TN1546_OVERLAY_MS = (0.4, 0.55, 0.65, 0.72)

"""
    interp_no_extrap(xs, ys, x) -> Union{Float64,Nothing}

Linear interpolation along samples `(xs, ys)`. Returns `nothing` when `x` lies
outside the closed sample range (never extrapolates).
"""
function interp_no_extrap(xs::AbstractVector{<:Real}, ys::AbstractVector{<:Real}, x::Real)
    n = length(xs)
    n == 0 && return nothing
    length(ys) == n || error("interp_no_extrap: xs/ys length mismatch")
    xf = Float64(x)
    # Allow unsorted input: order by xs.
    ord = sortperm(collect(Float64, xs))
    xso = Float64[xs[i] for i in ord]
    yso = Float64[ys[i] for i in ord]
    xf < xso[1] - 1e-12 && return nothing
    xf > xso[end] + 1e-12 && return nothing
    n == 1 && return yso[1]
    if xf <= xso[1]
        return yso[1]
    elseif xf >= xso[end]
        return yso[end]
    end
    i = searchsortedlast(xso, xf)
    i < 1 && return nothing
    i >= n && return yso[end]
    x0, x1 = xso[i], xso[i + 1]
    y0, y1 = yso[i], yso[i + 1]
    abs(x1 - x0) < 1e-15 && return y0
    t = (xf - x0) / (x1 - x0)
    return y0 + t * (y1 - y0)
end

"""Parse one TN 1546 CSV into curves keyed by (airfoil, alpha_deg, quantity)."""
function _load_tn1546_curves(path::AbstractString)
    curves = Dict{Tuple{String,Float64,String}, NamedTuple}()
    # Temporary accumulators
    acc = Dict{Tuple{String,Float64,String}, Vector{NTuple{3,Any}}}()
    for line in eachline(path)
        startswith(line, "#") && continue
        startswith(line, "airfoil") && continue
        isempty(strip(line)) && continue
        p = split(line, ',')
        length(p) >= 9 || continue
        airfoil = String(p[1])
        α = parse(Float64, p[4])
        qty = String(p[5])  # "cl" or "cd"
        M = parse(Float64, p[6])
        val = parse(Float64, p[7])
        assignment = String(p[9])
        key = (airfoil, α, qty)
        push!(get!(acc, key, NTuple{3,Any}[]), (M, val, assignment))
    end
    for (key, rows) in acc
        sort!(rows; by=r -> r[1])
        Ms = Float64[r[1] for r in rows]
        vals = Float64[r[2] for r in rows]
        # Assignment is constant along a curve; take the first sample's flag.
        assignment = String(rows[1][3])
        curves[key] = (mach=Ms, value=vals, assignment=assignment)
    end
    return curves
end

"""Load Report 824 NACA 4412 c_l(α) and c_d(c_l) marker CSVs."""
function _load_tr824_naca4412(dir::AbstractString)
    cl_path = joinpath(dir, "tr824_naca4412_cl_alpha.csv")
    cd_path = joinpath(dir, "tr824_naca4412_cd_cl.csv")
    (isfile(cl_path) && isfile(cd_path)) || return nothing
    cl_rows = NamedTuple[]
    for line in eachline(cl_path)
        startswith(line, "#") && continue
        startswith(line, "reynolds") && continue
        isempty(strip(line)) && continue
        p = split(line, ',')
        length(p) >= 3 || continue
        push!(cl_rows, (reynolds=String(p[1]), alpha_deg=parse(Float64, p[2]), cl=parse(Float64, p[3])))
    end
    cd_rows = NamedTuple[]
    for line in eachline(cd_path)
        startswith(line, "#") && continue
        startswith(line, "reynolds") && continue
        isempty(strip(line)) && continue
        p = split(line, ',')
        length(p) >= 3 || continue
        push!(cd_rows, (reynolds=String(p[1]), cl=parse(Float64, p[2]), cd=parse(Float64, p[3])))
    end
    return (cl_alpha=cl_rows, cd_cl=cd_rows)
end

"""
    measured_polar_series(section) -> Vector

Display-only measured airfoil overlays from `rea-work/data/airfoil_measured/`.
Nothing in the BEMT path reads these files.

Returns a vector of named tuples:

- TN 1546 (`n16_312` / `n16_506` / `n16_509`):
  - `kind=:cl_cd_at_M` — points `(alpha, cl)` / `(alpha, cd)` at each XFOIL Mach that
    TN 1546 covers (0.4, 0.55, 0.65, 0.72), interpolated along each measured curve with
    no extrapolation; `cd` rows with `assignment==\"uncertain\"` are omitted.
  - `kind=:cl_vs_M` — full measured `cl(M)` curves at each TN 1546 α (for the Mach-gap panel).
- Report 824 (`naca4412`):
  - `kind=:cl_alpha` — measured `cl(α)` markers (by Reynolds tag).
  - `kind=:cd_cl` — measured `cd` vs `cl` markers (plotted as c_d vs c_l; simpler and
    honest vs remapping through c_l(α) at a mismatched Re).

Empty vector when `section` has no digitized match or the CSVs are missing.
"""
function measured_polar_series(section)
    sec = String(section)
    airfoil = get(_MEASURED_AIRFOIL_NAME, sec, nothing)
    airfoil === nothing && return Any[]
    dir = _AIRFOIL_MEASURED_DIR
    isdir(dir) || return Any[]

    out = Any[]
    if sec == "naca4412"
        tr = _load_tr824_naca4412(dir)
        tr === nothing && return Any[]
        # Group c_l(α) by reynolds tag.
        by_re_cl = Dict{String,Vector{NTuple{2,Float64}}}()
        for r in tr.cl_alpha
            push!(get!(by_re_cl, r.reynolds, NTuple{2,Float64}[]), (r.alpha_deg, r.cl))
        end
        for (re, pts) in sort(collect(by_re_cl); by=first)
            sort!(pts; by=first)
            push!(out, (
                kind=:cl_alpha, source="TR 824", airfoil=airfoil, reynolds=re,
                alpha=Float64[p[1] for p in pts], cl=Float64[p[2] for p in pts],
            ))
        end
        by_re_cd = Dict{String,Vector{NTuple{2,Float64}}}()
        for r in tr.cd_cl
            push!(get!(by_re_cd, r.reynolds, NTuple{2,Float64}[]), (r.cl, r.cd))
        end
        for (re, pts) in sort(collect(by_re_cd); by=first)
            sort!(pts; by=first)
            push!(out, (
                kind=:cd_cl, source="TR 824", airfoil=airfoil, reynolds=re,
                cl=Float64[p[1] for p in pts], cd=Float64[p[2] for p in pts],
            ))
        end
        return out
    end

    # TN 1546 path
    path = joinpath(dir, "tn1546_fig3_cl_cd_vs_mach.csv")
    isfile(path) || return Any[]
    curves = _load_tn1546_curves(path)
    # Unique angles that have a c_l curve for this airfoil.
    alphas = sort(unique(Float64[α for (af, α, qty) in keys(curves) if af == airfoil && qty == "cl"]))
    isempty(alphas) && return Any[]

    for M in _TN1546_OVERLAY_MS
        α_cl = Float64[]; cl_v = Float64[]
        α_cd = Float64[]; cd_v = Float64[]
        for α in alphas
            cl_key = (airfoil, α, "cl")
            haskey(curves, cl_key) || continue
            c = curves[cl_key]
            v = interp_no_extrap(c.mach, c.value, M)
            if v !== nothing
                push!(α_cl, α); push!(cl_v, v)
            end
            cd_key = (airfoil, α, "cd")
            haskey(curves, cd_key) || continue
            cd = curves[cd_key]
            cd.assignment == "uncertain" && continue
            vd = interp_no_extrap(cd.mach, cd.value, M)
            if vd !== nothing
                push!(α_cd, α); push!(cd_v, vd)
            end
        end
        !isempty(α_cl) && push!(out, (
            kind=:cl_cd_at_M, source="TN 1546", airfoil=airfoil, Mach=Float64(M),
            alpha_cl=α_cl, cl=cl_v, alpha_cd=α_cd, cd=cd_v,
            skip_uncertain_cd=true,
        ))
    end

    for α in alphas
        cl_key = (airfoil, α, "cl")
        haskey(curves, cl_key) || continue
        c = curves[cl_key]
        # Display from M = 0.3 to the curve end (when the curve reaches 0.3).
        keep = [i for i in eachindex(c.mach) if c.mach[i] + 1e-12 >= 0.3]
        isempty(keep) && continue
        push!(out, (
            kind=:cl_vs_M, source="TN 1546", airfoil=airfoil, alpha_deg=α,
            mach=c.mach[keep], cl=c.value[keep],
            mach_lo=c.mach[1], mach_hi=c.mach[end],
        ))
    end
    return out
end

"""Raw polar tables keyed by (section, Re, M) → Vector of (α_deg, cl, cd)."""
function _polar_tables(path::AbstractString)
    raw = JSON3.read(read(path, String))
    Res = Float64.(collect(raw.Res))
    Ms = Float64.(collect(raw.Ms))
    tables = Dict{Tuple{String,Float64,Float64}, Vector{NTuple{3,Float64}}}()
    for (k, v) in pairs(raw.polars)
        parts = split(String(k), '|')
        length(parts) >= 3 || continue
        sec = String(parts[1])
        Re = parse(Float64, parts[2])
        M = parse(Float64, parts[3])
        pts = [(Float64(row[1]), Float64(row[2]), Float64(row[3])) for row in v]
        sort!(pts; by=first)
        tables[(sec, Re, M)] = pts
    end
    sections = String.(collect(get(raw, :sections, String[])))
    if isempty(sections)
        sections = sort!(unique(String[s for (s, _, _) in keys(tables)]))
    end
    return (; Res, Ms, sections, tables, path=String(path))
end

"""Nearest grid value in `grid` to `x` (absolute distance)."""
function _nearest_grid(x::Real, grid::AbstractVector{<:Real})
    isempty(grid) && error("empty grid")
    best = Float64(grid[1])
    best_d = abs(x - best)
    for g in grid
        d = abs(Float64(x) - Float64(g))
        if d < best_d
            best_d = d
            best = Float64(g)
        end
    end
    return best
end

"""
Viterna extension beyond the converged α of one (section, Re, M) polar.
Returns (α_deg, cl, cd) for points strictly outside the XFOIL α span, or empty if unusable.
`cr75` = c/R at 0.75 R (CCBlade.viterna argument).
"""
function _viterna_extension_curve(pts::Vector{NTuple{3,Float64}}, cr75::Float64)
    length(pts) < 3 && return (Float64[], Float64[], Float64[])
    a = deg2rad.([p[1] for p in pts])
    cl = [p[2] for p in pts]
    cd = [p[3] for p in pts]
    α_lo, α_hi = pts[1][1], pts[end][1]
    ae, cle, cde = CCBlade.viterna(a, cl, cd, cr75)
    all(isfinite, cle) && all(isfinite, cde) || return (Float64[], Float64[], Float64[])
    αe = rad2deg.(ae)
    keep = [i for i in eachindex(αe) if αe[i] < α_lo - 1e-9 || αe[i] > α_hi + 1e-9]
    return (αe[keep], cle[keep], cde[keep])
end

"""NACA 16-series section key `n16_<c><tt>` → thickness ratio `tt/100`; `nothing` for any other key."""
function _section_t_over_c(name::AbstractString)
    m = match(r"^n16_(\d)(\d\d)$", name)
    m === nothing && return nothing
    return parse(Int, m.captures[2]) / 100
end

"""Index `i` and weight `w` so that `x ≈ (1 − w)·grid[i] + w·grid[i + 1]` on a sorted grid (`x` clamped to it)."""
function _bracket(grid::AbstractVector{<:Real}, x::Real)
    n = length(grid)
    n == 1 && return (1, 0.0)
    i = clamp(searchsortedlast(grid, x), 1, n - 1)
    w = (x - grid[i]) / (grid[i + 1] - grid[i])
    return (i, clamp(w, 0.0, 1.0))
end

"""One usable (section, Re, M) table: α (deg) ascending, c_l, c_d, and the converged XFOIL α span."""
struct _PolarTable
    α::Vector{Float64}
    cl::Vector{Float64}
    cd::Vector{Float64}
    α_lo::Float64
    α_hi::Float64
end

"""
Polar set read from an XFOIL JSON file (`polars_forced_merged.json`, `naca4412_xfoil_*.json`).

Call `ps(α_rad, Re, M) -> (cl, cd)` on a one-section set. A multi-section set needs a thickness:
`section_polar(ps, t_over_c)` or `station_polars(ps, t_over_c_vector)`, so a blade station never
silently takes another section's polar (Phase 69 defect 1).
"""
struct PolarSet
    sections::Vector{String}           # sorted by thickness when multi-section
    t_over_c::Vector{Float64}          # per section (NaN for a one-section set)
    Res::Vector{Float64}
    logRes::Vector{Float64}            # log.(Res), precomputed for the hot BEMT path
    Ms::Vector{Float64}
    tables::Dict{Tuple{String,Float64,Float64},_PolarTable}
    nearest::Dict{Tuple{String,Float64,Float64},_PolarTable}   # cached replacements for missing tables
    k_cl::Float64
    k_cd::Float64
    stats::PolarStats
    path::String
end

function (ps::PolarSet)(α::Real, Re::Real, M::Real)
    length(ps.sections) == 1 ||
        error("polar set $(basename(ps.path)) has $(length(ps.sections)) sections: use section_polar(ps, t_over_c) or station_polars")
    return _eval_section(ps, ps.sections[1], α, Re, M)
end

"""Table for (s, Re, M), or the nearest usable (log Re, M) table of the same section (§2.10 rule)."""
function _table_or_nearest(ps::PolarSet, s::String, Re::Float64, M::Float64)
    t = get(ps.tables, (s, Re, M), nothing)
    t === nothing || return t
    ps.stats.nearest_polar += 1
    c = get(ps.nearest, (s, Re, M), nothing)
    c === nothing || return c
    best = nothing
    best_d = Inf
    for ((s_k, Re_k, M_k), tk) in ps.tables
        s_k == s || continue
        d = (log(Re_k) - log(Re))^2 + (M_k - M)^2
        if d < best_d
            best_d = d
            best = tk
        end
    end
    best === nothing && error("no usable polar for section $s in $(ps.path)")
    ps.nearest[(s, Re, M)] = best
    return best
end

function _eval_table(t::_PolarTable, α_deg::Float64, stats::PolarStats)
    (α_deg < t.α_lo || α_deg > t.α_hi) && (stats.viterna_evals += 1)
    a = clamp(α_deg, t.α[1], t.α[end])
    i, w = _bracket(t.α, a)
    j = min(i + 1, length(t.α))
    return ((1 - w) * t.cl[i] + w * t.cl[j], (1 - w) * t.cd[i] + w * t.cd[j])
end

"""c_l, c_d of one section: bilinear in (log Re, M) between the grid tables (§2.10), Re and M clamped to the grid."""
function _eval_section(ps::PolarSet, s::String, α::Real, Re::Real, M::Real)
    st = ps.stats
    Re_c = clamp(Float64(Re), first(ps.Res), last(ps.Res))
    M_c = clamp(Float64(M), first(ps.Ms), last(ps.Ms))
    Re_c != Re && (st.clamped_Re += 1)
    M_c != M && (st.clamped_M += 1)
    i, wr = _bracket(ps.logRes, log(Re_c))
    j, wm = _bracket(ps.Ms, M_c)
    α_deg = rad2deg(Float64(α))
    cl = 0.0
    cd = 0.0
    for (di, fr) in ((0, 1 - wr), (1, wr)), (dj, fm) in ((0, 1 - wm), (1, wm))
        f = fr * fm
        f == 0 && continue
        t = _table_or_nearest(ps, s, ps.Res[min(i + di, end)], ps.Ms[min(j + dj, end)])
        c, d = _eval_table(t, α_deg, st)
        cl += f * c
        cd += f * d
    end
    return ps.k_cl * cl, ps.k_cd * cd
end

"""
    section_polar(ps, t_over_c) -> af(α_rad, Re, M)

Polar of a blade station of thickness ratio `t_over_c`: linear in t/c between the two sections of the
set that bracket it (clamped to the thinnest and thickest section). A one-section set ignores `t_over_c`.
"""
function section_polar(ps::PolarSet, t_over_c::Real)
    length(ps.sections) == 1 && return (α, Re, M) -> _eval_section(ps, ps.sections[1], α, Re, M)
    i, w = _bracket(ps.t_over_c, clamp(Float64(t_over_c), first(ps.t_over_c), last(ps.t_over_c)))
    sa, sb = ps.sections[i], ps.sections[i + 1]
    return function (α, Re, M)
        cla, cda = _eval_section(ps, sa, α, Re, M)
        w == 0 && return (cla, cda)
        clb, cdb = _eval_section(ps, sb, α, Re, M)
        return ((1 - w) * cla + w * clb, (1 - w) * cda + w * cdb)
    end
end

"""One polar per blade station (`section_polar` at each station thickness)."""
station_polars(ps::PolarSet, t_over_c::AbstractVector{<:Real}) = [section_polar(ps, t) for t in t_over_c]

"""
    load_polar_set(path; set=:primary, cr75=nothing) -> (ps::PolarSet, stats)

Reads every (section, Re, M) table of an XFOIL JSON file. Tables keep their section (Phase 69 defect 1);
lookup is bilinear in (log Re, M) with Re and M clamped to the grid range, as registered in
`VALIDATION_GUIDELINE.md` §2.10 (defect 2). With `cr75` (c/R at 0.75 R) every table is extended past
its converged α span by the registered Viterna rule (`_viterna_extension_curve`, CCBlade `viterna`);
tables with fewer than 3 points, or whose extension is not finite, are not used and the nearest usable
(Re, M) table of the same section takes their place (defect 3). Without `cr75` the end value is held.
`:primary` uses k_cl = k_cd = 1; `:bracket` applies the `tables.json` factors (default 0.92264, 1.81815).
"""
function load_polar_set(path::AbstractString; set::Symbol=:primary, cr75::Union{Nothing,Real}=nothing)
    raw = JSON3.read(read(path, String))
    stats = PolarStats()
    Res = sort!(Float64.(collect(raw.Res)))
    Ms = sort!(Float64.(collect(raw.Ms)))
    tables = Dict{Tuple{String,Float64,Float64},_PolarTable}()
    secs = Set{String}()
    for (k, v) in pairs(raw.polars)
        parts = split(String(k), '|')
        length(parts) >= 3 || continue
        s = String(parts[1])
        push!(secs, s)
        pts = sort!([(Float64(row[1]), Float64(row[2]), Float64(row[3])) for row in v]; by=first)
        length(pts) >= 3 || continue
        rows = pts
        if cr75 !== nothing
            αe, cle, cde = _viterna_extension_curve(pts, Float64(cr75))
            isempty(αe) && continue
            rows = sort!(vcat(pts, collect(zip(αe, cle, cde))); by=first)
        end
        tables[(s, parse(Float64, parts[2]), parse(Float64, parts[3]))] =
            _PolarTable(first.(rows), [r[2] for r in rows], [r[3] for r in rows], pts[1][1], pts[end][1])
    end
    isempty(tables) && error("empty polar set: $path")
    names = sort!(collect(secs))
    if length(names) == 1
        tcs = [NaN]
    else
        tcs = Float64[]
        for s in names
            t = _section_t_over_c(s)
            t === nothing && error("multi-section polar set $path: cannot read the thickness of section $s")
            push!(tcs, t)
        end
        p = sortperm(tcs)
        names, tcs = names[p], tcs[p]
        allunique(tcs) || error("multi-section polar set $path: two sections share a thickness")
    end
    k_cl = 1.0
    k_cd = 1.0
    if set === :bracket
        cal = joinpath(dirname(path), "tables.json")
        if isfile(cal)
            cj = JSON3.read(read(cal, String))
            k_cl = Float64(get(cj, :k_cl, get(cj, :kCl, 0.92264)))
            k_cd = Float64(get(cj, :k_cd, get(cj, :kCd, 1.81815)))
        else
            k_cl, k_cd = 0.92264, 1.81815
        end
    elseif set !== :primary
        error("set must be :primary or :bracket")
    end
    return PolarSet(names, tcs, Res, log.(Res), Ms, tables, Dict{Tuple{String,Float64,Float64},_PolarTable}(),
                    k_cl, k_cd, stats, String(path)), stats
end
