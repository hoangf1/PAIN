# Phase 121 — Commander 695A cabin dB(A) against CR-178004 flight 3 (IMPLEMENTATION_PLAN / COMPLETED_PHASES §8bk;
# form fixed 2026-11-03 before the first run). PAIN's aircraft path run on the Commander 695A with the inputs CR-178004
# prints (blades, diameter, tip clearance, skin, frame spacing, propeller station, Table 4's flight conditions and
# shaft power) and assumed values for the rest (blade shape, cross-section, stiffener sections: see the JSON). The
# overall dB(A) over 63–5000 Hz is compared with the measured cabin levels at mics 3 and 6 (App. E, flight 3, bare).
# Information under the input-completeness rule (Phase 118): the blade and the cabin section are not printed.

const _P121_JSON = joinpath(@__DIR__, "..", "examples", "commander695a_cr178004.json")
_p121_conditions_csv() = _data_path("cr178004", "table4_flight3_conditions.csv")
_p121_measured_csv() = _data_path("cr178004", "appE_flight3_interior_third_octave.csv")

"""Band range of the comparison (form fixed 2026-11-03): PAIN's centres 1000·2^(k/3), k = −12…7 (63–5000 Hz nominal)."""
const _P121_BAND_K = -12:7
const _P121_SIGMA_DB = 3.5   # PAIN's stated 1σ on overall dB(A) (`overall_dBA`), the band the criterion uses

"""
    c695a_air(alt_ft, T_K) -> (; ρ, c)

ISA pressure at the pressure altitude `alt_ft`, ideal-gas density and sound speed at temperature `T_K`
(R = 287.05 J/(kg K), γ = 1.4).
"""
function c695a_air(alt_ft::Real, T_K::Real)
    h = 0.3048 * alt_ft
    p = 101325.0 * (1 - 2.25577e-5 * h)^5.25588
    return (; ρ=p / (287.05 * T_K), c=sqrt(1.4 * 287.05 * T_K))
end

"""CR-178004 Table 4 (flight 3) rows as NamedTuples, in condition order."""
function c695a_conditions()
    c = _read_csv_numeric(_p121_conditions_csv())
    return [(; cond=Int(c[:cond][i]), alt_ft=c[:alt_ft][i], ias_kt=c[:ias_kt][i], oat_F=c[:oat_F][i],
               port_rpm=c[:port_rpm][i], port_kW=c[:port_kW][i], stbd_rpm=c[:stbd_rpm][i], stbd_kW=c[:stbd_kW][i],
               cabin_alt_ft=c[:cabin_alt_ft][i]) for i in eachindex(c[:cond])]
end

"""
    c695a_operating_point(row) -> (; V, ρ, c, ρ_cab, c_cab)

True airspeed and outside air from Table 4 (pressure altitude, IAS taken as EAS, OAT); cabin air at the printed cabin
pressure altitude and 293.15 K (assumed).
"""
function c695a_operating_point(row)
    T = (row.oat_F - 32) * 5 / 9 + 273.15
    out = c695a_air(row.alt_ft, T)
    cab = c695a_air(row.cabin_alt_ft, 293.15)
    V = row.ias_kt * 0.514444 * sqrt(1.225 / out.ρ)
    return (; V, ρ=out.ρ, c=out.c, ρ_cab=cab.ρ, c_cab=cab.c)
end

_p121_base() = JSON3.read(read(_P121_JSON, String), Dict{String,Any})

function _p121_cfg_dict(rpm, pitch_deg, op, rot; base::AbstractDict=_p121_base())
    d = deepcopy(base)
    d["propeller"]["rpm"] = Float64(rpm)
    d["propeller"]["pitch_offset_deg"] = Float64(pitch_deg)
    d["operating_point"] = Dict("forward_speed_mps" => op.V, "rho_kg_m3" => op.ρ, "c0_mps" => op.c)
    cab = d["cabin"]
    cab["rho_kg_m3"] = Dict("value" => op.ρ_cab, "tag" => "assumed")
    cab["c0_mps"] = Dict("value" => op.c_cab, "tag" => "assumed")
    cab["rho_ext_kg_m3"] = Dict("value" => op.ρ, "tag" => "measured")
    cab["c_ext_mps"] = Dict("value" => op.c, "tag" => "measured")
    cab["rho_int_kg_m3"] = Dict("value" => op.ρ_cab, "tag" => "assumed")
    cab["c_int_mps"] = Dict("value" => op.c_cab, "tag" => "assumed")
    cab["rotation_direction"] = Dict("value" => rot, "tag" => "assumed")
    return d
end

"""CCBlade shaft torque (N m) of the 695A blade at `rpm`, `pitch_deg` and the operating point."""
function c695a_torque(rpm, pitch_deg, op; base::AbstractDict=_p121_base())
    cfg = JSON3.read(JSON3.write(_p121_cfg_dict(rpm, pitch_deg, op, 1; base)))
    s = _ccblade_setup(cfg)
    return CCBlade.thrusttorque(s.rotor, s.sections, s.outs)[2]
end

"""
    c695a_pitch_for_power(rpm, P_W, op; lo=-30, hi=30) -> pitch offset (deg)

Pitch offset at which the CCBlade torque equals the printed shaft power / Ω (bisection to 1e-4 deg; errors when the
power is outside the torque range of [lo, hi]).
"""
function c695a_pitch_for_power(rpm, P_W, op; lo::Float64=-30.0, hi::Float64=30.0)
    Qt = P_W / (rpm * 2π / 60)
    base = _p121_base()   # read the file once, not at every bisection step
    f(x) = c695a_torque(rpm, x, op; base) - Qt
    flo, fhi = f(lo), f(hi)
    flo * fhi < 0 || error("c695a_pitch_for_power: torque $(round(Qt; digits=1)) N m outside the range of pitch [$lo, $hi]")
    for _ in 1:60
        m = (lo + hi) / 2
        fm = f(m)
        (fm < 0) == (flo < 0) ? (lo = m; flo = fm) : (hi = m)
        hi - lo < 1e-4 && break
    end
    return (lo + hi) / 2
end

"""
    c695a_condition_spectrum(row; n_harmonics=10) -> (; band_p2, engines, op)

One PAIN aircraft run per engine that is on (port rotation +1, starboard −1: both turn the same way, so mirrored onto
PAIN's one side they turn opposite ways), pitch set for the printed power; band mean-square pressures added in energy.
"""
function c695a_condition_spectrum(row; n_harmonics::Int=10)
    op = c695a_operating_point(row)
    band_p2 = Dict{Float64,Float64}()
    engines = NamedTuple[]
    for (side, rpm, kW, rot) in (("port", row.port_rpm, row.port_kW, 1), ("stbd", row.stbd_rpm, row.stbd_kW, -1))
        rpm > 0 && kW > 0 || continue
        pitch = c695a_pitch_for_power(rpm, 1000kW, op)
        path, io = mktemp()
        write(io, JSON3.write(_p121_cfg_dict(rpm, pitch, op, rot)))
        close(io)
        sp = try
            run_pain_pipeline(; source=:aircraft, aircraft_json=path, n_harmonics).spectrum
        finally
            rm(path; force=true)
        end
        for (b, l) in sp.third_octave_SPL_dB
            isfinite(l) || continue
            band_p2[b] = get(band_p2, b, 0.0) + 10^(l / 10)
        end
        push!(engines, (; side, rpm, kW, pitch_deg=round(pitch; digits=3), dBA=round(_p121_dBA(sp.third_octave_SPL_dB); digits=2),
                         harmonics_dB=sp.harmonic_SPL_dB[1:min(3, end)]))
    end
    return (; band_p2, engines, op)
end

"""Overall dB(A) of a band dict (centre Hz => dB) over the comparison bands (A-weight at PAIN's band centre)."""
function _p121_dBA(bands::AbstractDict)
    s = 0.0
    for (fc, l) in bands
        k = round(Int, 3 * log2(fc / 1000))
        (k in _P121_BAND_K && isapprox(fc, 1000.0 * 2.0^(k / 3); rtol=1e-6) && isfinite(l)) || continue
        s += 10^((l + a_weight_dB(fc)) / 10)
    end
    return 10log10(s)
end

"""
    c695a_measured_dBA() -> Dict{(cond, mic) => dB(A)}

Measured cabin dB(A) of CR-178004 App. E (flight 3, mics 3 and 6) over 63–5000 Hz: each printed nominal band put at
PAIN's centre 1000·2^(k/3) (k from the nominal band) and A-weighted there, then energy-summed, as for PAIN.
"""
function c695a_measured_dBA()
    c = _read_csv_numeric(_p121_measured_csv())
    out = Dict{Tuple{Int,Int},Float64}()
    acc = Dict{Tuple{Int,Int},Dict{Float64,Float64}}()
    for i in eachindex(c[:cond])
        Int(c[:flight][i]) == 3 || continue
        k = round(Int, 3 * log2(c[:band_Hz][i] / 1000))
        k in _P121_BAND_K || continue
        key = (Int(c[:cond][i]), Int(c[:mic][i]))
        bands = get!(acc, key, Dict{Float64,Float64}())
        fc = 1000.0 * 2.0^(k / 3)
        haskey(bands, fc) && error("measured cond $(key[1]) mic $(key[2]): band $(c[:band_Hz][i]) Hz given twice")
        bands[fc] = c[:L_dB][i]
    end
    for (key, bands) in acc
        length(bands) == length(_P121_BAND_K) || error("measured cond $(key[1]) mic $(key[2]): $(length(bands)) bands")
        out[key] = _p121_dBA(bands)
    end
    return out
end

function _run_ac_c695a_dba()
    meas = c695a_measured_dBA()
    rows = c695a_conditions()
    table = ValidationTableRow[]
    pain = Float64[]
    per_cond = NamedTuple[]
    for row in rows
        r = c695a_condition_spectrum(row)
        bands = Dict(b => 10log10(p2) for (b, p2) in r.band_p2)
        L = _p121_dBA(bands)
        push!(pain, L)
        push!(per_cond, (; cond=row.cond, PAIN_dBA=round(L; digits=2), engines=r.engines,
                          V_mps=round(r.op.V; digits=1)))
        for mic in (3, 6)
            m = meas[(row.cond, mic)]
            push!(table, ValidationTableRow("cond $(row.cond) mic $mic dB(A)", Float64(row.cond), m, L, L - m,
                                            abs(L - m) ≤ _P121_SIGMA_DB, "mic $mic"))
        end
    end
    n_ok = count(r -> r.within_tolerance, table)
    n = length(table)
    res = [r.residual for r in table]
    xs = Float64[r.cond for r in rows]
    m3 = [meas[(c, 3)] for c in Int.(xs)]
    m6 = [meas[(c, 6)] for c in Int.(xs)]
    series = [PlotSeries("measured mic 3 (App. E)", :reference_points, xs, m3; panel=1),
              PlotSeries("measured mic 6 (App. E)", :measured_points, xs, m6; panel=1),
              PlotSeries("PAIN ±3.5 dB (1σ)", :reference_band, xs, pain;
                         ylow=pain .- _P121_SIGMA_DB, yhigh=pain .+ _P121_SIGMA_DB, panel=1),
              PlotSeries("PAIN, Commander 695A inputs", :computed, xs, pain; panel=1)]
    met = n_ok ≥ ceil(Int, 0.68n)
    return ValidationCaseResult("AC_C695A_DBA", _today_iso(),
        (; criterion="measured dB(A) within PAIN's ±3.5 dB (1σ) at ≥ 68 % of the 36 points (form fixed 2026-11-03)",
           bands="63–5000 Hz (PAIN centres 1000·2^(k/3), k = −12…7)", n_ok, n,
           mean_residual_dB=round(sum(res) / n; digits=2), min_residual_dB=round(minimum(res); digits=2),
           max_residual_dB=round(maximum(res); digits=2), conditions=per_cond),
        table, series, met ? :met : :not_met,
        "$n_ok/$n points within ±3.5 dB; PAIN − measured = $(round(minimum(res); digits=1)) to $(round(maximum(res); digits=1)) dB (mean $(round(sum(res) / n; digits=1)) dB)",
        "X-EXTRAP (assumed blade and cabin section; CR-178004 flight 3)",
        joinpath(_VAL_REPORT_DIR, "phase121_c695a_dba.md"))
end

function _iso121_validation_cases()
    crit = "Information (input-completeness rule, Phase 118). Form fixed 2026-11-03 before the first run: PAIN's overall " *
           "dB(A) over 63–5000 Hz for each of CR-178004 Table 4's 18 flight-3 conditions against the measured dB(A) at " *
           "mics 3 and 6 (App. E, same bands, same A-weighting); recorded as within PAIN's stated ±3.5 dB (1σ) at ≥ 68 % of the 36 points."
    spec = PlotSpec(; xlabel="flight 3 condition (CR-178004 Table 4)", ylabel="cabin overall level (dB(A))",
                    panel_titles=["AC_C695A_DBA"], error_mode=:absolute, error_tol=_P121_SIGMA_DB,
                    error_ylabel="PAIN − measured dB(A) (dB)")
    return [ValidationCase("AC_C695A_DBA", "Commander 695A cabin dB(A) vs CR-178004 flight 3 (121)", "121",
                           [_p121_conditions_csv(), _p121_measured_csv()],
                           FigureRef("CR-178004", "App. E Tables E.3, E.6; Table 4", nothing), crit,
                           "2026-11-03", "V-EXP", _run_ac_c695a_dba, spec, "")]
end

# ---------------------------------------------------------------------------------------------------------------------
# Phase 122 — the tones alone (form fixed 2026-11-03 before the first run). CR-178004 App. B prints each engine's cabin
# harmonics 1–3 at mics 3 and 6 for the flight-3 conditions where the two propellers turn at different rpm or one is off,
# so each engine's tones are separate. PAIN's per-engine run (as AC_C695A_DBA) gives its cabin harmonic levels H1–H3;
# they are compared engine by engine, without the broadband PAIN does not model. Information (Phase 118 input rule).

_p122_measured_csv() = _data_path("cr178004", "appB_flight3_cabin_harmonics.csv")
const _P122_TOL_DB = 4.0   # T1's gate width (fixed 2026-10-20), the band the record uses

"""
    c695a_measured_tones() -> Dict{(cond, mic, side, H) => dB}

CR-178004 App. B flight-3 cabin harmonic levels, each engine's component (engine 0 = port, 1 = starboard).
"""
function c695a_measured_tones()
    c = _read_csv_numeric(_p122_measured_csv())
    out = Dict{Tuple{Int,Int,String,Int},Float64}()
    for i in eachindex(c[:cond])
        key = (Int(c[:cond][i]), Int(c[:mic][i]), Int(c[:engine][i]) == 0 ? "port" : "stbd", Int(c[:harmonic][i]))
        haskey(out, key) && error("App. B tones: $key given twice")
        out[key] = c[:L_dB][i]
    end
    return out
end

function _run_ac_c695a_tones()
    meas = c695a_measured_tones()
    conds = sort(unique(k[1] for k in keys(meas)))
    rows = Dict(r.cond => r for r in c695a_conditions())
    table = ValidationTableRow[]
    per_cond = NamedTuple[]
    pain = Dict{Tuple{Int,String,Int},Float64}()
    for c in conds
        r = c695a_condition_spectrum(rows[c])
        push!(per_cond, (; cond=c, engines=[(; e.side, e.rpm, e.pitch_deg, H1_H3=round.(e.harmonics_dB; digits=2)) for e in r.engines]))
        for e in r.engines, H in 1:3
            length(e.harmonics_dB) ≥ 3 || error("AC_C695A_TONES: the runs need n_harmonics ≥ 3")
            pain[(c, e.side, H)] = e.harmonics_dB[H]
        end
    end
    for k in sort(collect(keys(meas)))
        (c, mic, side, H) = k
        haskey(pain, (c, side, H)) || error("App. B tones: no PAIN run for cond $c $side")
        L = pain[(c, side, H)]
        m = meas[k]
        push!(table, ValidationTableRow("cond $c mic $mic $side H$H", Float64(H), m, L, L - m, abs(L - m) ≤ _P122_TOL_DB, "H$H"))
    end
    n = length(table)
    n_ok = count(r -> r.within_tolerance, table)
    res = [r.residual for r in table]
    byH = [(; H, mean=round(sum(r.residual for r in table if r.x == H) / count(r -> r.x == H, table); digits=2)) for H in 1:3]
    series = PlotSeries[]
    for (mic, kind) in ((3, :reference_points), (6, :measured_points))
        sel = [r for r in table if occursin("mic $mic ", r.quantity)]
        push!(series, PlotSeries("measured mic $mic (App. B)", kind, [r.x + (mic == 3 ? -0.08 : 0.08) for r in sel], [r.reference for r in sel]; panel=1))
    end
    sel = [r for r in table if occursin("mic 3 ", r.quantity)]
    push!(series, PlotSeries("PAIN, Commander 695A inputs (per engine)", :computed_points, [r.x for r in sel], [r.computed for r in sel]; panel=1))
    met = n_ok ≥ ceil(Int, 0.68n)
    return ValidationCaseResult("AC_C695A_TONES", _today_iso(),
        (; criterion="each engine's cabin H1–H3 within ±4 dB of App. B at ≥ 68 % of the points (form fixed 2026-11-03)",
           n_ok, n, mean_residual_dB=round(sum(res) / n; digits=2), min_residual_dB=round(minimum(res); digits=2),
           max_residual_dB=round(maximum(res); digits=2), mean_by_harmonic=byH, conditions=per_cond),
        table, series, met ? :met : :not_met,
        "$n_ok/$n tones within ±4 dB; PAIN − measured = $(round(minimum(res); digits=1)) to $(round(maximum(res); digits=1)) dB (mean $(round(sum(res) / n; digits=1)) dB; by harmonic $(join([string(b.mean) for b in byH], ", ")) dB)",
        "X-EXTRAP (assumed blade and cabin section; CR-178004 flight 3)",
        joinpath(_VAL_REPORT_DIR, "phase122_c695a_tones.md"))
end

function _iso122_validation_cases()
    crit = "Information (input-completeness rule, Phase 118). Form fixed 2026-11-03 before the first run: PAIN's cabin " *
           "harmonic levels H1–H3 for each engine (the AC_C695A_DBA runs, one per engine) against CR-178004 App. B's " *
           "flight-3 levels of that engine's component at mics 3 and 6 (conditions 1–4, 9–12, 17, 18); recorded as within " *
           "±4 dB (T1's gate width) at ≥ 68 % of the points."
    spec = PlotSpec(; xlabel="harmonic of the blade-passage frequency", ylabel="cabin tone level (dB)",
                    panel_titles=["AC_C695A_TONES"], error_mode=:absolute, error_tol=_P122_TOL_DB,
                    error_ylabel="PAIN − measured (dB)")
    return [ValidationCase("AC_C695A_TONES", "Commander 695A cabin tones vs CR-178004 App. B (122)", "122",
                           [_p121_conditions_csv(), _p122_measured_csv()],
                           FigureRef("CR-178004", "App. B Tables B.7, B.8, B.16, B.17; Table 4", nothing), crit,
                           "2026-11-03", "V-EXP", _run_ac_c695a_tones, spec, "")]
end
