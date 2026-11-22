# Phase 156b (2026-11-22): R1377_FLIGHT, the blade-passage harmonics of two 3.40 m four-blade propellers in flight at a
# boom microphone, this code against NACA Report 1377 Tables I and II (ISSUE-046). Criterion and rows fixed 2026-11-15
# (commit 1fd5eda); inputs, root, tip, sections, polar grid, air and observer fixed 2026-11-22 (commit dbe77df), both
# before any load or sound level was computed. One run; the result is recorded whatever it is.

const _R1377_D = 3.404                 # 11 ft 2 in
const _R1377_GEAR = 0.479              # propeller speed / engine speed (Report 1377)
const _R1377_Y_OVER_D = 0.655          # microphone distance from the propeller axis
const _R1377_HP_W = 745.69987          # W per horsepower
const _R1377_TOL_DB = 3.0
const _R1377_PASS_FRAC = 0.75
const _R1377_CHECK_DB = 1.0            # a check that moves any compared level by more than this removes the verdict
const _R1377_BLADES = ("tapered", "rectangular")

_r1377_path(parts...) = _data_path("report1377", parts...)

function _r1377_csv(path)
    lines = [l for l in eachline(path) if !startswith(l, "#") && !isempty(strip(l))]
    head = split(lines[1], ',')
    return [Dict(zip(head, split(l, ','))) for l in lines[2:end]]
end

"""
    r1377_rows() -> Vector{NamedTuple}

The case's rows of Report 1377 Tables I and II: flight rows with printed helical tip Mach ≤ 0.90 and printed power
≥ 500 hp (rule of 2026-11-15). Levels of harmonics 1–5 in dB re 20 μPa, `NaN` where the print is blank.
"""
function r1377_rows()
    num(s) = s == "-" ? NaN : parse(Float64, s)
    out = NamedTuple[]
    for r in _r1377_csv(_r1377_path("tables_I_II_flight.csv"))
        Mt, P = num(r["M_t"]), num(r["P_hp"])
        (Mt ≤ 0.90 && P ≥ 500) || continue
        push!(out, (; blade=String(r["blade"]), row=parse(Int, r["row"]), x_over_D=num(r["x_over_D"]), T_lb=num(r["T_lb"]),
                      V_fps=num(r["V_fps"]), p_psf=num(r["p_psf"]), t_F=num(r["t_F"]), P_hp=P, N_rpm=num(r["N_rpm"]),
                      M_inf=num(r["M_inf"]), M_t=Mt, BPF=num(r["BPF_cps"]), levels=[num(r["H$(h)_dB"]) for h in 1:5]))
    end
    length(out) == 39 || error("R1377_FLIGHT: expected 39 rows by the row rule, got $(length(out))")
    return out
end

"""Air at the printed static pressure (lb/sq ft) and temperature (°F): ρ, speed of sound, Sutherland viscosity."""
function r1377_air(p_psf::Real, t_F::Real)
    T = (t_F - 32) * 5 / 9 + 273.15
    p = p_psf * 47.880259
    return (; ρ=p / (287.05 * T), c=sqrt(1.4 * 287.05 * T), μ=1.458e-6 * T^1.5 / (T + 110.4), T)
end

"""
    r1377_blade(blade) -> NamedTuple

Fig. 2 stations of `blade` from the first digitized station inside the root (root = innermost radius at which Fig. 2
prints width, angle and thickness, read by script into `qa/fig2_pixels.json`), to r/R 0.95.
"""
function r1377_blade(blade::AbstractString)
    ends = JSON3.read(read(_r1377_path("qa", "fig2_pixels.json"), String))[Symbol(blade)].inner_ends
    root = maximum(Float64(ends[k].r_over_R) for k in (:b_over_D, :beta, :h_over_b))
    rows = [r for r in _r1377_csv(_r1377_path("fig2_blade_form.csv")) if r["blade"] == blade && r["b_over_D"] != "-"]
    x = [parse(Float64, r["r_over_R"]) for r in rows]
    all(>(root), x) || error("R1377_FLIGHT: a station of the $blade blade lies inside its root $root")
    bD = [parse(Float64, r["b_over_D"]) for r in rows]
    i75 = findfirst(≈(0.75), x)
    return (; blade=String(blade), root, r_over_R=x, b_over_D=bD, h_over_b=[parse(Float64, r["h_over_b"]) for r in rows],
              beta_deg=[parse(Float64, r["beta_deg"]) for r in rows], cr75=2 * bD[i75])
end

"""Polar set of `blade` for `family` ("16" or "4d"; `clslope=true`: the rectangular inboard design-lift check) and the
per-station A/c² from the same sections' contours."""
function r1377_polars(blade::AbstractString, family::AbstractString; clslope::Bool=false)
    g = r1377_blade(blade)
    name = "polars_$(blade)_$(family == "16" ? "16" : "4d")$(clslope ? "_clslope" : "").json"
    ps, _ = load_polar_set(_r1377_path(name); cr75=g.cr75)
    dir = _r1377_path("xfoil_sections")
    area = station_area_over_chord2(ps.t_over_c, [airfoil_area_over_chord2(joinpath(dir, "$s.dat")) for s in ps.sections], g.h_over_b)
    return (; ps, area, file=name)
end

function _r1377_cfg(g, row, pitch_deg, area)
    air = r1377_air(row.p_psf, row.t_F)
    R = _R1377_D / 2
    return (propeller=(num_blades=4, tip_radius_m=R, hub_radius_m=g.root * R, rpm=_R1377_GEAR * row.N_rpm,
                       thickness_over_chord=0.0, pitch_offset_deg=Float64(pitch_deg), radii_m=g.r_over_R .* R,
                       chord_m=g.b_over_D .* _R1377_D, twist_deg=g.beta_deg, station_t_over_c=g.h_over_b,
                       area_over_chord2=area),
            operating_point=(forward_speed_mps=row.V_fps * 0.3048, rho_kg_m3=air.ρ, c0_mps=air.c, mu_Pa_s=air.μ),
            anopp_table8_calibrate=false)
end

"""Blade-angle offset (deg, from Fig. 2's drawn angles) at which the CCBlade shaft power equals `P_W`, on the propeller
branch: the first crossing above the torque minimum of a 2.5° scan of [lo, hi], where torque rises with pitch (below
about −20° the torque rises again on the braking branch, which is not a propeller state). Bisection to 1e-4°; errors
when that branch does not reach the power inside [lo, hi]. Range set 2026-11-22 before any level was computed: the
first range, ±25°, missed the rectangular blade's 520 ft/s row (about +25.3°)."""
function r1377_pitch_for_power(g, row, pol, P_W; lo::Float64=-25.0, hi::Float64=45.0)
    Qt = P_W / (_R1377_GEAR * row.N_rpm * 2π / 60)
    q(x) = (s = _ccblade_setup(_r1377_cfg(g, row, x, pol.area); af=pol.ps); CCBlade.thrusttorque(s.rotor, s.sections, s.outs)[2])
    f(x) = q(x) - Qt
    xs = collect(lo:2.5:hi)
    fs = f.(xs)
    i0 = argmin(fs)
    i = findfirst(j -> fs[j] < 0 && fs[j+1] ≥ 0, i0:length(xs)-1)
    i === nothing && error("R1377_FLIGHT: torque $(round(Qt; digits=1)) N m not reached on the propeller branch of pitch [$lo, $hi]")
    lo, hi = xs[i0+i-1], xs[i0+i]
    flo = fs[i0+i-1]
    for _ in 1:60
        m = (lo + hi) / 2
        fm = f(m)
        (fm < 0) == (flo < 0) ? (lo = m; flo = fm) : (hi = m)
        hi - lo < 1e-4 && break
    end
    return (lo + hi) / 2
end

"""Levels (dB re 20 μPa) of harmonics 1–5 at the row's microphone, the pitch offset and the computed thrust (lb)."""
function r1377_levels(g, row, pol; power_scale::Real=1.0)
    pitch = r1377_pitch_for_power(g, row, pol, power_scale * row.P_hp * _R1377_HP_W)
    cfg = _r1377_cfg(g, row, pitch, pol.area)
    V = row.V_fps * 0.3048
    obs = [Observer([row.x_over_D * _R1377_D, _R1377_Y_OVER_D * _R1377_D, 0.0], [V, 0.0, 0.0], "mic")]   # AA +X ahead
    src = evaluate_propeller_source(cfg, obs; n_harmonics=5, af=pol.ps)
    return (; dB=[20log10(src.amplitude[1, h] / sqrt(2) / 20e-6) for h in 1:5], pitch_deg=pitch, T_lb=src.T / 4.448222)
end

const _R1377_RUN = Ref{Any}(nothing)

"""
    r1377_flight_run(; recompute=false)

Every row on the shipped inputs (NACA 16-series polars, printed power) and on the three checks of the input rule:
four-digit sections, power × 0.95 and × 1.05, and (rectangular blade) the inboard design lift on the printed slope.
"""
function r1377_flight_run(; recompute::Bool=false)
    (_R1377_RUN[] === nothing || recompute) || return _R1377_RUN[]
    rows = r1377_rows()
    out = NamedTuple[]
    for blade in _R1377_BLADES
        g = r1377_blade(blade)
        p16 = r1377_polars(blade, "16"); p4 = r1377_polars(blade, "4d")
        pcl = blade == "rectangular" ? r1377_polars(blade, "16"; clslope=true) : nothing
        for row in rows
            row.blade == blade || continue
            base = r1377_levels(g, row, p16)
            checks = Dict("four-digit sections" => r1377_levels(g, row, p4).dB,
                          "power −5 %" => r1377_levels(g, row, p16; power_scale=0.95).dB,
                          "power +5 %" => r1377_levels(g, row, p16; power_scale=1.05).dB)
            pcl === nothing || (checks["inboard design lift on the printed slope"] = r1377_levels(g, row, pcl).dB)
            push!(out, (; row, base, checks))
        end
    end
    _R1377_RUN[] = out
    return out
end

function _run_r1377_flight()
    runs = r1377_flight_run()
    # 1. the input rule, on computed levels only: the largest move of a compared level under each check
    moves = Dict{String,Float64}()
    for r in runs, (name, dB) in r.checks, h in 1:5
        isnan(r.row.levels[h]) && continue
        moves[name] = max(get(moves, name, 0.0), abs(dB[h] - r.base.dB[h]))
    end
    eligible = all(≤(_R1377_CHECK_DB), values(moves))
    # 2. the comparison
    table = ValidationTableRow[]
    series = PlotSeries[]
    for (p, blade) in enumerate(_R1377_BLADES)
        xs = Float64[]; ys = Float64[]
        for r in runs, h in 1:5
            r.row.blade == blade && !isnan(r.row.levels[h]) || continue
            m, c = r.row.levels[h], r.base.dB[h]
            q = "$(blade) row $(r.row.row) H$h (x = $(r.row.x_over_D) D, M∞ $(r.row.M_inf), $(Int(r.row.P_hp)) hp, dB re 20 μPa)"
            push!(table, ValidationTableRow(q, m, m, c, c - m, abs(c - m) ≤ _R1377_TOL_DB, blade))
            push!(xs, m); push!(ys, c)
        end
        lo, hi = extrema(xs)
        push!(series, PlotSeries("measured = computed", :reference_curve, [lo - 3, hi + 3], [lo - 3, hi + 3]; panel=p))
        push!(series, PlotSeries("this code, $(blade) blades", :computed_points, xs, ys; panel=p))
    end
    n_in = count(t -> t.within_tolerance, table); n = length(table)
    met = n_in ≥ _R1377_PASS_FRAC * n
    verdict = eligible ? (met ? :met : :not_met) : :no_verdict
    r2 = x -> round(x; digits=2)
    mv = join(["$k $(r2(v)) dB" for (k, v) in sort(collect(moves))], ", ")
    reason = eligible ?
        "$n_in/$n levels within ±$(_R1377_TOL_DB) dB of the measured (criterion: ≥ 75 %); checks of the input rule moved a compared level by at most: $mv" :
        "no verdict (input rule): a check moved a compared level by more than $(_R1377_CHECK_DB) dB ($mv); $n_in/$n levels within ±$(_R1377_TOL_DB) dB, not a pass or a fail"
    return ValidationCaseResult("R1377_FLIGHT", _today_iso(),
        (; criterion="±3 dB per level; met if ≥ 75 % of the levels of harmonics 1–5 on the 39 rows, both propellers",
         date="2026-11-15", n_rows=length(runs), n_levels=n, n_within=n_in, check_moves_dB=Dict(k => r2(v) for (k, v) in moves),
         eligible, pitch_deg=[r2(r.base.pitch_deg) for r in runs], thrust_lb=[round(r.base.T_lb) for r in runs]),
        table, series, verdict, reason, "V-EXP", joinpath(_VAL_REPORT_DIR, "phase156_r1377_flight.md"))
end

function _r1377_validation_cases()
    return [ValidationCase("R1377_FLIGHT",
        "NACA Report 1377: blade-passage harmonics 1–5 of two 3.40 m four-blade propellers in flight at a boom microphone, against the measured levels (156b)",
        "156", [_r1377_path("tables_I_II_flight.csv"), _r1377_path("fig2_blade_form.csv")],
        FigureRef("NACA Report 1377", "Tables I and II; Fig. 2", 9),
        "±3 dB of the measured rms level of each blade-passage harmonic 1–5 at the boom microphone; met if at least 75 % of the levels are within it, both propellers together. Rows: flight, printed helical tip Mach ≤ 0.90, printed power ≥ 500 hp. No verdict if a check of an unprinted input (airfoil family, power ±5 %, the rectangular blade's inboard design lift) moves any compared level by more than 1 dB. Fixed 2026-11-15 (rows, tolerance) and 2026-11-22 (inputs) before any computation.",
        "2026-11-15", "V-EXP", _run_r1377_flight,
        PlotSpec(; xlabel="measured level (dB re 20 μPa)", ylabel="computed level (dB re 20 μPa)",
                 panel_titles=["tapered blades (Table I)", "rectangular blades (Table II)"],
                 error_mode=:absolute, error_tol=_R1377_TOL_DB, error_xlabel="measured level (dB re 20 μPa)"), "")]
end
