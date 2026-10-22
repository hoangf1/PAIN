"""
Polar loader for Report 996 / Pereira (phase 25i).

`load_polar_set(path; set=:primary|:bracket, viterna=nothing) -> (af, stats)`
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

"""
    load_polar_set(path; set=:primary, viterna=nothing) -> (af, stats)

`af(α_rad, Re, M) -> (cl, cd)`. Linear in α inside the table; clamps Re/M to grid edges;
optional Viterna record outside α range (`viterna` path or `nothing` → clamp α to table).
`:primary` uses k_cl=k_cd=1 on merged forced polars; `:bracket` applies tables.json
calibration factors when present in the same folder (else same as primary with a note).
"""
function load_polar_set(path::AbstractString; set::Symbol=:primary, viterna=nothing)
    raw = JSON3.read(read(path, String))
    stats = PolarStats()
    Res = Float64.(collect(raw.Res))
    Ms = Float64.(collect(raw.Ms))
    # Flatten polars: key "section|Re|M" -> Vector of (α_deg, cl, cd)
    tables = Dict{Tuple{Float64,Float64}, Vector{NTuple{3,Float64}}}()
    for (k, v) in pairs(raw.polars)
        parts = split(String(k), '|')
        length(parts) >= 3 || continue
        Re = parse(Float64, parts[2])
        M = parse(Float64, parts[3])
        pts = [(Float64(row[1]), Float64(row[2]), Float64(row[3])) for row in v]
        sort!(pts; by=first)
        tables[(Re, M)] = pts
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

    function nearest_table(Re, M)
        Re_c = clamp(Re, minimum(Res), maximum(Res))
        M_c = clamp(M, minimum(Ms), maximum(Ms))
        Re_c != Re && (stats.clamped_Re += 1)
        M_c != M && (stats.clamped_M += 1)
        # nearest (Re,M) key present
        best = nothing
        best_d = Inf
        for (Re_k, M_k) in keys(tables)
            d = (log(Re_k) - log(Re_c))^2 + (M_k - M_c)^2
            if d < best_d
                best_d = d
                best = (Re_k, M_k)
            end
        end
        best === nothing && error("empty polar set")
        best_d > 0 && (stats.nearest_polar += 1)
        return tables[best]
    end

    function af(α::Real, Re::Real, M::Real)
        pts = nearest_table(Float64(Re), Float64(M))
        α_deg = rad2deg(Float64(α))
        αs = first.(pts)
        α_lo, α_hi = αs[1], αs[end]
        if α_deg < α_lo || α_deg > α_hi
            stats.viterna_evals += 1
            # Without a Viterna record: clamp to edge (phase 25i full Viterna is optional path)
            α_deg = clamp(α_deg, α_lo, α_hi)
        end
        # linear interpolate
        if α_deg <= αs[1]
            _, cl, cd = pts[1]
        elseif α_deg >= αs[end]
            _, cl, cd = pts[end]
        else
            i = searchsortedlast(αs, α_deg)
            a0, cl0, cd0 = pts[i]
            a1, cl1, cd1 = pts[i + 1]
            t = (α_deg - a0) / (a1 - a0)
            cl = cl0 + t * (cl1 - cl0)
            cd = cd0 + t * (cd1 - cd0)
        end
        return k_cl * cl, k_cd * cd
    end
    return af, stats
end
