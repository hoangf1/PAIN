# Phase 90 — Eq. (43) blocking against NACA Report 996 Fig. 10 (measured), IMPLEMENTATION_PLAN.md §8ag; criteria fixed
# 2026-10-29 before Fig. 10 was digitized. Total rms pressure along a line parallel to the propeller axis at the
# blade-tip clearance d/D = 0.083, in free space and at a flat and a circular wall. Eq. (43) predicts the wall/free
# ratio F(γ), γ the angle between the hub-to-point line and the wall normal: γ = atan(|x/D| / (0.5 + d/D)). On the
# generator line of a cylinder nearest the hub the normal points at the hub axis too, so γ, and F, are the same for the
# circular wall whatever its radius.

const _P90_REPORT = "phase90_r996_fig10_blocking.md"
const _R996_FIG10_D_OVER_D = 0.083

"""Measured Fig. 10 values: Dict(series => (x/D, p̄)) from `tr996_fig10_reflecting_walls.csv`."""
function _r996_fig10()
    rows = Dict{String,Vector{Tuple{Float64,Float64}}}()
    for line in eachline(_data_path("report996", "tr996_fig10_reflecting_walls.csv"))
        (startswith(line, "#") || startswith(line, "series")) && continue
        f = split(line, ",")
        push!(get!(rows, String(f[1]), Tuple{Float64,Float64}[]), (parse(Float64, f[2]), parse(Float64, f[3])))
    end
    return rows
end

"""Eq. (43) incidence angle on the wall line at axial offset x/D, hub at R + d from the wall."""
_r996_fig10_gamma_deg(xd::Real) = rad2deg(atan(abs(xd) / (0.5 + _R996_FIG10_D_OVER_D)))

"""90b (wall = "flat_wall", verdict) and 90c (wall = "circular_wall", information): Eq. (43) against p_wall/p_free."""
function _run_r996_fig10(wall::String)
    d = _r996_fig10()
    free = Dict(d["free_space"])
    table = ValidationTableRow[]; xs = Float64[]; meas = Float64[]; r1 = Float64[]; r2 = Float64[]; n_ok = 0
    for (xd, p) in d[wall]
        haskey(free, xd) || continue
        m = 20log10(p / free[xd]); γ = _r996_fig10_gamma_deg(xd)
        g1 = delta_L_blocking_dB(γ; variant=R1); g2 = delta_L_blocking_dB(γ; variant=R2)
        ok = abs(g1 - m) ≤ 1.5; n_ok += ok
        push!(xs, xd); push!(meas, m); push!(r1, g1); push!(r2, g2)
        push!(table, ValidationTableRow("x/D = $xd (γ = $(round(γ; digits=1))°)", xd, m, g1, g1 - m, ok))
    end
    n = length(xs)
    flat = wall == "flat_wall"
    name = flat ? "flat wall" : "circular wall"
    series = [PlotSeries("measured 20 log₁₀(p_wall/p_free), $name (Report 996 Fig. 10)", :measured_points, xs, meas; panel=1),
              PlotSeries("Eq. (43) R1", :computed_points, xs, r1; panel=1),
              PlotSeries("Eq. (43) R2 (information)", :computed_points, xs, r2; panel=1)]
    r2d = x -> round.(x; digits=2)
    id = flat ? "R996_FIG10_FLAT" : "R996_FIG10_CIRC"
    verdict = !flat ? :no_verdict : (n_ok ≥ 4 ? :met : :not_met)
    reason = (flat ? "" : "information (no criterion: the circular wall's radius is not stated; Eq. (43) gives the same F as for the flat wall); ") *
             "$n_ok/$n points with Eq. (43) R1 within ±1.5 dB of the measured $name increase; measured $(r2d(meas)) dB, " *
             "R1 $(r2d(r1)) dB, R2 $(r2d(r2)) dB"
    return ValidationCaseResult(id, _today_iso(),
        (; criterion="|20 log10 F_R1 − 20 log10(p_wall/p_free)| ≤ 1.5 dB at ≥ 4 of 5 points", date="2026-10-29",
           x_over_D=xs, measured_dB=r2d(meas), R1_dB=r2d(r1), R2_dB=r2d(r2), n_ok, n),
        table, series, verdict, reason, flat ? "V-EXP" : "V-EXP (information)", joinpath(_VAL_REPORT_DIR, _P90_REPORT))
end

_run_r996_fig10_flat() = _run_r996_fig10("flat_wall")
_run_r996_fig10_circ() = _run_r996_fig10("circular_wall")

function _iso90_validation_cases()
    csv = _data_path("report996", "tr996_fig10_reflecting_walls.csv")
    fig = FigureRef("NACA Report 996", "Fig. 10", 12)
    spec(tol) = PlotSpec(; xlabel="x/D (distance from the plane of rotation, + ahead)", ylabel="wall increase over free space (dB)",
                         panel_titles=["Report 996 Fig. 10"], error_mode=:absolute, error_tol=tol, error_ylabel="Eq. (43) − measured (dB)")
    return [
        ValidationCase("R996_FIG10_FLAT", "Eq. (43) blocking vs Report 996 Fig. 10 flat wall (90b)", "90", [csv], fig,
            "|Eq. (43) R1 − measured flat-wall increase| ≤ 1.5 dB at ≥ 4 of the 5 points (fixed 2026-10-29, before digitizing).",
            "2026-10-29", "V-EXP", _run_r996_fig10_flat, spec(1.5), ""),
        ValidationCase("R996_FIG10_CIRC", "Eq. (43) blocking vs Report 996 Fig. 10 circular wall, information (90c)", "90", [csv], fig,
            "No criterion (the circular wall's radius is not stated).", "2026-10-29", "V-EXP", _run_r996_fig10_circ, spec(nothing), ""),
    ]
end
