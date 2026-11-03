#!/usr/bin/env julia
# Phase 73c (rule fixed 2026-10-28 before the run, docs/IMPLEMENTATION_PLAN.md §8q): sensitivity of the Report 996
# loads and scaled-load acoustics to a uniform section c_l shift δ at every blade station (c_d unchanged).
# δ ∈ {+0.026 (mean XFOIL − TN 1546 offset removed), −0.056, +0.056 (± RMS)}; 73c2: c_d × 1.33 (median TN 1546 / XFOIL
# c_d ratio). Bound only: no verdict, nothing adopted.
# Writes docs/validation_reports/phase73_polar_sensitivity.md. Never opens a GUI window.
ENV["QT_QPA_PLATFORM"] = get(ENV, "QT_QPA_PLATFORM", "offscreen")
using PAIN
using Printf

const ROOT = joinpath(@__DIR__, "..", "..", "..")
const POLAR = joinpath(ROOT, "data", "report996", "polars_phase69_ncrit8.json")
const SCALES = joinpath(ROOT, "data", "report996", "scale_factors.csv")
const OUT = joinpath(ROOT, "docs", "validation_reports", "phase73_polar_sensitivity.md")
const DELTAS = (0.0, 0.026, -0.056, 0.056)

"""Station polars of `cfg` with c_l shifted by δ and c_d multiplied by k."""
function shifted_afs(ps, cfg, δ, k=1.0)
    base = station_polars(ps, Float64.(collect(cfg.propeller.station_t_over_c)))
    return [let g = g; (α, Re, M) -> (c = g(α, Re, M); (c[1] + δ, k * c[2])) end for g in base]
end

"""Primary rows of scale_factors.csv: (β₇₅, M_t, T_meas, Q_meas, source)."""
function measured_rows()
    rows = NamedTuple[]
    for raw in eachline(SCALES)
        startswith(raw, "case") && continue
        p = split(strip(raw), ',')
        p[2] == "primary" || continue
        push!(rows, (β=parse(Float64, p[3]), Mt=parse(Float64, p[4]), T=parse(Float64, p[10]),
                     Q=parse(Float64, p[11]), src=String(p[16])))
    end
    return rows
end

pct(x, ref) = isfinite(ref) ? @sprintf("%+.1f", 100 * (x / ref - 1)) : "—"

function main()
    ps, _ = load_polar_set(POLAR; set=:primary, cr75=PAIN._R996_CR75)
    L = String["# Phase 73c: Report 996 sensitivity to the section c_l (bound, no verdict)", "",
        "Generated $(PAIN._today_iso()) by `scripts/run/r996_polar_sensitivity.jl`. Rule fixed 2026-10-28 before the run " *
        "(`IMPLEMENTATION_PLAN.md` §8q 73c). Every station's c_l is shifted by δ (c_d unchanged); δ = +0.026 removes the mean " *
        "XFOIL (N_crit 8) − TN 1546 offset, ±0.056 is its RMS over the 60 matched points. Primary polar set. No δ is adopted " *
        "and no case record changes.", "",
        "## Loads (static, CCBlade): thrust and torque against the measured values", "",
        "| β₇₅ | M_t | source | T meas [N] | T δ=0 % | T δ=+0.026 % | T δ=−0.056 % | T δ=+0.056 % | Q meas [N·m] | Q δ=0 % | Q δ=+0.026 % | Q δ=−0.056 % | Q δ=+0.056 % |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    obs0 = [Observer([0.0, 1.0, 0.0], zeros(3), "dummy")]
    maxdT = 0.0
    for r in measured_rows()
        cfg = PAIN._r996_cfg(; beta75=r.β, Mt=r.Mt, B=2)
        TQ = [let s = evaluate_propeller_source(cfg, obs0; n_harmonics=1, num_src_times=16,
                                               af=shifted_afs(ps, cfg, δ), allow_static=true); (s.T, s.Q) end
              for δ in DELTAS]
        maxdT = max(maxdT, maximum(abs(TQ[k][1] / TQ[1][1] - 1) for k in 2:4))
        push!(L, "| $(r.β) | $(r.Mt) | $(r.src) | $(isfinite(r.T) ? round(r.T; digits=1) : "—") | " *
                 join((pct(t[1], r.T) for t in TQ), " | ") * " | $(isfinite(r.Q) ? round(r.Q; digits=2) : "—") | " *
                 join((pct(t[2], r.Q) for t in TQ), " | ") * " |")
    end
    push!(L, "", @sprintf("Largest change of T against δ = 0 over the shifts: %.1f %%.", 100maxdT), "",
          "## Scaled-load acoustics (β₇₅ 10°, B 2, d/D 0.083; loads scaled to the Fig. 14 table T and Q for every δ)", "",
          "Change of harmonic level against δ = 0, dB. Fig. 14 microphone x/D = −0.125; Fig. 12 points x/D = −0.25 … 0.25 at M_t 0.75 and 0.90.", "",
          "| M_t | x/D | mB | level δ=0 [dB] | Δ δ=+0.026 | Δ δ=−0.056 | Δ δ=+0.056 |", "|---|---|---|---|---|---|---|")
    maxdB = 0.0
    for r in measured_rows()
        r.src == "Fig14_table" || continue
        cfg = PAIN._r996_cfg(; beta75=10.0, Mt=r.Mt, B=2)
        R = cfg.propeller.tip_radius_m
        xs = r.Mt in (0.75, 0.9) ? [-0.25, -0.125, 0.0, 0.125, 0.25] : [-0.125]
        obs = hub_observers(R, 2R; x_over_D=xs, d_over_D=0.083, x_sign=R996_X_SIGN)
        A = [evaluate_propeller_source(cfg, obs; n_harmonics=4, num_src_times=64, af=shifted_afs(ps, cfg, δ),
                                       allow_static=true, loads=ScaledLoads(r.T, r.Q)).amplitude for δ in DELTAS]
        for (i, x) in enumerate(xs), H in 1:4
            d = [20log10(A[k][i, H] / A[1][i, H]) for k in 2:4]
            maxdB = max(maxdB, maximum(abs, d))
            push!(L, @sprintf("| %.2f | %+.3f | %d | %.1f | %+.2f | %+.2f | %+.2f |", r.Mt, x, 2H,
                              20log10(A[1][i, H] / sqrt(2) / 2e-5), d...))
        end
    end
    push!(L, "", @sprintf("Largest level change over the shifts: %.2f dB.", maxdB), "",
          "## 73c2: c_d × k (rule registered 2026-10-28 after 73c, before this run)", "",
          "k = 1.33 removes the median XFOIL / TN 1546 c_d ratio (0.75, 55 matched points); c_l unchanged.", "",
          "| β₇₅ | M_t | source | T k=1 % | T k=1.33 % | Q k=1 % | Q k=1.33 % |", "|---|---|---|---|---|---|---|")
    for r in measured_rows()
        cfg = PAIN._r996_cfg(; beta75=r.β, Mt=r.Mt, B=2)
        TQ = [let s = evaluate_propeller_source(cfg, obs0; n_harmonics=1, num_src_times=16,
                                               af=shifted_afs(ps, cfg, 0.0, k), allow_static=true); (s.T, s.Q) end
              for k in (1.0, 1 / 0.75)]
        push!(L, "| $(r.β) | $(r.Mt) | $(r.src) | $(pct(TQ[1][1], r.T)) | $(pct(TQ[2][1], r.T)) | $(pct(TQ[1][2], r.Q)) | $(pct(TQ[2][2], r.Q)) |")
    end
    push!(L, "")
    write(OUT, join(L, "\n"))
    println("wrote ", OUT, "; max |ΔT| ", round(100maxdT; digits=1), " %, max |ΔdB| ", round(maxdB; digits=2))
end

main()
