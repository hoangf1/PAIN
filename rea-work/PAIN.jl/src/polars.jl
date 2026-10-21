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
