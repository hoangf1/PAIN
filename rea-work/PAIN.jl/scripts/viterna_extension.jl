# Phase 11c: record the Viterna post-stall extension (CCBlade.viterna, pinned 1.0.0) for the XFOIL polar sets.
# Run from rea-work\PAIN.jl:  julia --project=. scripts/viterna_extension.jl
# Writes data/polars/viterna_extension.json. No Julia source under src/ is changed (wiring is phase 17c).
#
# Rule recorded (decided before any comparison, VALIDATION_GUIDELINE.md section 2.10):
#   * per (section, Re, M) XFOIL polar: alpha_stall = alpha at max c_l of the converged points; c_d,max =
#     max(max converged c_d, 1.11 + 0.018 / cr75) (CCBlade rule, cr75 = c/R at 0.75 R); extension from the last
#     converged alpha to +180 deg and from -180 deg to the first converged alpha, 50 points per side.
#   * a polar with fewer than 3 converged points is not extended (`unusable`); one for which viterna returns non-finite values
#     (converged range stops at alpha <= 0) is not extended either (`viterna_nonfinite`); the evaluation uses the nearest
#     usable (Re, M) polar of the same section and the count is reported with each run.
#   * Re and M clamp: the evaluation (Re, M) is clamped to the grid range of the polar set (no extrapolation in Re or M);
#     inside the grid, bilinear in (log Re, M) between the grid polars. Clamp counts are filled in per run (phase 17c/20).
using CCBlade, JSON3, Dates

const ROOT = normpath(joinpath(@__DIR__, "..", ".."))

function cr75_from_csv(path, rcol, ccol)
    lines = readlines(path)[2:end]
    r = Float64[]; c = Float64[]
    for l in lines
        isempty(strip(l)) && continue
        f = split(l, ',')
        push!(r, parse(Float64, f[rcol])); push!(c, parse(Float64, f[ccol]))
    end
    p = sortperm(r); r = r[p]; c = c[p]
    i = findlast(<=(0.75), r)
    return c[i] + (c[i+1] - c[i]) * (0.75 - r[i]) / (r[i+1] - r[i])
end

function process(path, cr75)
    d = JSON3.read(read(path, String))
    stalls = Float64[]; clmaxs = Float64[]; cdmaxs = Float64[]
    unusable = String[]; nonfinite = String[]; n_ext = 0; not_stalled = String[]
    for (k, rows) in pairs(d.polars)
        length(rows) < 3 && (push!(unusable, String(k)); continue)
        a = deg2rad.([Float64(r[1]) for r in rows])
        cl = [Float64(r[2]) for r in rows]; cd = [Float64(r[3]) for r in rows]
        ia = argmax(cl)
        ia == length(a) && push!(not_stalled, String(k))     # c_l still rising at the last converged point
        ae, cle, cde = viterna(a, cl, cd, cr75)
        if !(minimum(ae) >= -pi - 1e-9 && maximum(ae) <= pi + 1e-9 && all(isfinite, cle) && all(isfinite, cde))
            push!(nonfinite, String(k)); continue          # degenerate polar (converged range does not reach positive alpha)
        end
        push!(stalls, rad2deg(a[ia])); push!(clmaxs, cl[ia]); push!(cdmaxs, max(maximum(cd), 1.11 + 0.018 / cr75))
        n_ext += 1
    end
    q(v) = isempty(v) ? nothing : (min = minimum(v), median = sort(v)[cld(length(v), 2)], max = maximum(v))
    return (file = relpath(path, ROOT), cr75 = cr75, polars_total = length(d.polars), polars_extended = n_ext,
            unusable = unusable, viterna_nonfinite = nonfinite, c_l_still_rising_at_last_point = not_stalled,
            alpha_stall_deg = q(stalls), cl_max = q(clmaxs), cd_max = q(cdmaxs))
end

cr75_996 = cr75_from_csv("C:/Users/FrancisHoang/git/propeller_sizing_and_analysis/propeller_sizing_and_analysis/propellers/naca_4-5-08-03/blade_form.csv", 1, 2)
cr75_per = cr75_from_csv(joinpath(ROOT, "data", "pereira", "pereira_fig1b_chord_twist.csv"), 1, 2)

sets = Any[("report996_forced_merged", joinpath(ROOT, "data", "report996", "polars_forced_merged.json"), cr75_996)]
for s in ("ncrit9", "ncrit5", "xtr005")
    push!(sets, ("pereira_$s", joinpath(ROOT, "data", "pereira", "naca4412_xfoil_$s.json"), cr75_per))
end
out = Dict{String,Any}("generated" => string(today()), "script" => "PAIN.jl/scripts/viterna_extension.jl",
    "ccblade" => "1.0.0 viterna(alpha, cl, cd, cr75, nalpha=50)", "nalpha_per_side" => 50,
    "cd_max_rule" => "max(max converged cd, 1.11 + 0.018/cr75)",
    "re_m_clamp_rule" => "clamp evaluation Re, M to the grid range of the set; bilinear in (log Re, M) inside; no extrapolation",
    "sets" => Dict{String,Any}())
for (name, path, cr) in sets
    isfile(path) || (println("missing ", path); continue)
    out["sets"][name] = process(path, cr)
    println(name, ": ", out["sets"][name])
end
open(joinpath(ROOT, "data", "polars", "viterna_extension.json"), "w") do io
    JSON3.pretty(io, out)
end
