#!/usr/bin/env julia
# ISSUE-048 ground-test diagnostic (rule fixed 2026-11-23 in docs/ISSUES.md before any computation; commit 09d58b7).
# NACA Report 1377's ground rows (static) with the inputs of Phase 156b's flight runner (commit f0ae877,
# src/cases_r1377_flight.jl): Fig. 2 blades, NACA 16-series polars, blade angle set to the printed power, microphone at
# y = 0.655 D; forward speed 0 (allow_static). Run once; the result goes to
# docs/validation_reports/issue048_r1377_ground.md. No verdict, not a case; this script is removed after the run.
#   julia --project=. scripts/run/issue048_ground.jl <out.json>
ENV["QT_QPA_PLATFORM"] = get(ENV, "QT_QPA_PLATFORM", "offscreen")
using PAIN
using JSON3, Statistics, Printf
const P = PAIN
const CCB = P.CCBlade

const D = 3.404                 # 11 ft 2 in
const GEAR = 0.479
const Y_OVER_D = 0.655
const HP_W = 745.69987
const P_UNPRINTED_PSF = 2116.2  # Table II prints no ground pressure (rule 2026-11-23)
const DATA = joinpath(@__DIR__, "..", "..", "..", "data", "report1377")

csvrows(path) = let ls = [l for l in eachline(path) if !startswith(l, "#") && !isempty(strip(l))], h = split(ls[1], ',')
    [Dict(zip(h, split(l, ','))) for l in ls[2:end]]
end
num(s) = s in ("-", "a") ? NaN : parse(Float64, s)

function ground_rows()
    out = NamedTuple[]
    for r in csvrows(joinpath(DATA, "tables_I_II_ground.csv"))
        lv = [num(r["H$(h)_dB"]) for h in 1:5]
        all(isnan, lv) && continue
        push!(out, (; blade=String(r["blade"]), row=parse(Int, r["row"]), x_over_D=num(r["x_over_D"]), T_lb=num(r["T_lb"]),
                      p_psf=r["p_psf"] == "-" ? P_UNPRINTED_PSF : num(r["p_psf"]), p_printed=r["p_psf"] != "-",
                      t_F=num(r["t_F"]), P_hp=num(r["P_hp"]), N_rpm=num(r["N_rpm"]), levels=lv))
    end
    length(out) == 28 || error("expected 28 ground rows with a level, got $(length(out))")
    return out
end

function air(p_psf, t_F)
    T = (t_F - 32) * 5 / 9 + 273.15
    return (; ρ=p_psf * 47.880259 / (287.05 * T), c=sqrt(1.4 * 287.05 * T), μ=1.458e-6 * T^1.5 / (T + 110.4))
end

function blade_form(blade)
    ends = JSON3.read(read(joinpath(DATA, "qa", "fig2_pixels.json"), String))[Symbol(blade)].inner_ends
    root = maximum(Float64(ends[k].r_over_R) for k in (:b_over_D, :beta, :h_over_b))
    rows = [r for r in csvrows(joinpath(DATA, "fig2_blade_form.csv")) if r["blade"] == blade && r["b_over_D"] != "-"]
    x = [parse(Float64, r["r_over_R"]) for r in rows]
    all(>(root), x) || error("a station of the $blade blade lies inside its root")
    bD = [parse(Float64, r["b_over_D"]) for r in rows]
    return (; root, r_over_R=x, b_over_D=bD, h_over_b=[parse(Float64, r["h_over_b"]) for r in rows],
              beta_deg=[parse(Float64, r["beta_deg"]) for r in rows], cr75=2 * bD[findfirst(≈(0.75), x)])
end

function polars(g, blade, family)
    name = "polars_$(blade)_$(family)_ground.json"
    ps, _ = P.load_polar_set(joinpath(DATA, name); cr75=g.cr75)
    dir = joinpath(DATA, "xfoil_sections")
    area = P.station_area_over_chord2(ps.t_over_c, [P.airfoil_area_over_chord2(joinpath(dir, "$s.dat")) for s in ps.sections], g.h_over_b)
    return (; ps, area, file=name)
end

function cfg(g, row, pitch, area; p_scale=1.0)
    a = air(p_scale * row.p_psf, row.t_F)
    R = D / 2
    return (propeller=(num_blades=4, tip_radius_m=R, hub_radius_m=g.root * R, rpm=GEAR * row.N_rpm,
                       thickness_over_chord=0.0, pitch_offset_deg=Float64(pitch), radii_m=g.r_over_R .* R,
                       chord_m=g.b_over_D .* D, twist_deg=g.beta_deg, station_t_over_c=g.h_over_b, area_over_chord2=area),
            operating_point=(forward_speed_mps=0.0, rho_kg_m3=a.ρ, c0_mps=a.c, mu_Pa_s=a.μ),
            anopp_table8_calibrate=false)
end

"""Phase 156b's solver unchanged: first crossing above the torque minimum of a 2.5° scan of [−25°, 45°], bisection."""
function pitch_for_power(g, row, pol, P_W; p_scale=1.0, lo=-25.0, hi=45.0)
    Qt = P_W / (GEAR * row.N_rpm * 2π / 60)
    q(x) = (s = P._ccblade_setup(cfg(g, row, x, pol.area; p_scale); af=pol.ps, allow_static=true);
            CCB.thrusttorque(s.rotor, s.sections, s.outs)[2])
    f(x) = q(x) - Qt
    xs = collect(lo:2.5:hi)
    fs = f.(xs)
    i0 = argmin(fs)
    i = findfirst(j -> fs[j] < 0 && fs[j+1] ≥ 0, i0:length(xs)-1)
    i === nothing && error("torque $(round(Qt; digits=1)) N m not reached on the propeller branch, $(row.blade) row $(row.row)")
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

function levels(g, row, pol; power_scale=1.0, p_scale=1.0)
    pitch = pitch_for_power(g, row, pol, power_scale * row.P_hp * HP_W; p_scale)
    c = cfg(g, row, pitch, pol.area; p_scale)
    obs = [P.Observer([row.x_over_D * D, Y_OVER_D * D, 0.0], [0.0, 0.0, 0.0], "mic")]   # x positive ahead of the disk
    src = P.evaluate_propeller_source(c, obs; n_harmonics=5, af=pol.ps, allow_static=true)
    return (; dB=[20log10(src.amplitude[1, h] / sqrt(2) / 20e-6) for h in 1:5], pitch_deg=pitch, T_lb=src.T / 4.448222)
end

function main(out)
    rows = ground_rows()
    res = []
    for blade in ("tapered", "rectangular")
        g = blade_form(blade)
        p16 = polars(g, blade, "16"); p4 = polars(g, blade, "4d")
        for row in rows
            row.blade == blade || continue
            base = levels(g, row, p16)
            checks = Dict("four-digit sections" => levels(g, row, p4).dB,
                          "power −5 %" => levels(g, row, p16; power_scale=0.95).dB,
                          "power +5 %" => levels(g, row, p16; power_scale=1.05).dB)
            if !row.p_printed
                checks["pressure −3 %"] = levels(g, row, p16; p_scale=0.97).dB
                checks["pressure +3 %"] = levels(g, row, p16; p_scale=1.03).dB
            end
            @printf("%-11s row %2d x %+.3f %4d hp: pitch %+6.2f  T %5.0f / %5.0f lb  code %s  meas %s\n", blade, row.row,
                    row.x_over_D, row.P_hp, base.pitch_deg, base.T_lb, row.T_lb, round.(base.dB; digits=1), row.levels)
            push!(res, (; row, base, checks))
        end
    end
    # the answer rule (ISSUES.md ISSUE-048, 2026-11-23)
    diffs(blade, f) = [f(r)[h] - r.row.levels[h] for r in res if r.row.blade == blade for h in 1:5 if !isnan(r.row.levels[h])]
    band(d) = d ≥ 4.0 ? "shared" : (-2.0 ≤ d ≤ 2.0 ? "flight-only" : "not settled")
    Dt = median(diffs("tapered", r -> r.base.dB))
    Dchk = Dict(k => median(diffs("tapered", r -> r.checks[k])) for k in ("four-digit sections", "power −5 %", "power +5 %"))
    answer = all(band(v) == band(Dt) for v in values(Dchk)) ? band(Dt) : "not settled"
    within10 = [r.base.dB[h] - r.row.levels[h] for r in res if r.row.blade == "tapered" && abs(r.base.T_lb / r.row.T_lb - 1) ≤ 0.10
                for h in 1:5 if !isnan(r.row.levels[h])]
    Dr = median(diffs("rectangular", r -> r.base.dB))
    Drchk = Dict(k => median(diffs("rectangular", r -> r.checks[k])) for k in keys(res[end].checks))
    moves = Dict{String,Float64}()
    for r in res, (k, v) in r.checks, h in 1:5
        isnan(r.row.levels[h]) || (moves[k] = max(get(moves, k, 0.0), abs(v[h] - r.base.dB[h])))
    end
    @printf("\nTapered D = %+.2f dB over %d levels -> %s; answer (checks agree?): %s\n", Dt, length(diffs("tapered", r -> r.base.dB)), band(Dt), answer)
    for (k, v) in sort(collect(Dchk)); @printf("  check %-20s D = %+.2f dB (%s)\n", k, v, band(v)); end
    @printf("Tapered, thrust within 10 %%: D = %+.2f dB over %d levels\n", isempty(within10) ? NaN : median(within10), length(within10))
    @printf("Rectangular D = %+.2f dB; checks %s\n", Dr, Dict(k => round(v; digits=2) for (k, v) in Drchk))
    println("largest move of a level by check: ", Dict(k => round(v; digits=2) for (k, v) in moves))
    open(out, "w") do io
        JSON3.write(io, (; Dt, band=band(Dt), answer, Dchk, Dr, Drchk, D_within10=isempty(within10) ? nothing : median(within10),
                          n_within10=length(within10), moves,
                          rows=[(; r.row.blade, r.row.row, r.row.x_over_D, r.row.P_hp, r.row.N_rpm, T_printed=r.row.T_lb,
                                 T_code=r.base.T_lb, pitch=r.base.pitch_deg, measured=[isnan(x) ? nothing : x for x in r.row.levels], code=r.base.dB,
                                 checks=r.checks) for r in res]))
    end
end

main(ARGS[1])
