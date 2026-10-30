# Phase 92 — NASA's printed mode-pair contributions, IMPLEMENTATION_PLAN.md §8ai (diagnostics; no verdict). CR-172428
# App. B prints the five largest acoustic × structural pair terms of Eq. (8) at 4000 rpm H1–H3 and 5000 rpm H1–H2
# (pp. 207, 212). 92a sets this code's pair terms against them; 92b tests, on the 3000 rpm points held out (criterion
# fixed 2026-10-29 before the run), whether the q = 0 cabin modes add nothing in NASA's run; the run with q = 0 off and
# η_n per mode together was formed after 92a and is post-hoc.

const _P92_REPORT = "phase92_appb_pairs.md"

"""This code's Eq. (8) pair terms at `rpm`, harmonic `H` (CR-172428 inputs; Phase 89/92 options as given)."""
function _r172428_pair_terms(rpm::Integer, H::Integer; q0_coupled::Bool=true, η_n_per_mode::Bool=false)
    inp = _with_fields(r172428_inputs(rpm); q0_coupled, η_n_per_mode)
    return modal_tone_contributions(inp, H, 2π * H * 3 * rpm / 60)[1]
end

"""App. B's printed pairs: (rpm, H, Q, I, st, η_r″ as printed, p² [Pa²])."""
function _appb_printed_pairs()
    out = NamedTuple[]
    for rpm in (4000, 5000)
        t = _read_csv_numeric_nan(_r172428_csv("appB_contributors_$(rpm)rpm.csv"))
        for k in eachindex(t[:H])
            push!(out, (; rpm, H=Int(t[:H][k]), Q=Int(t[:Q][k]), I=Int(t[:I][k]), st=Int(t[:st_mode][k]),
                        η_r_hash=t[:eta_r_hash][k], p2=t[:p2_Pa2][k]))
        end
    end
    return out
end

_dB_re20μPa(p2) = 10log10(p2 / 4e-10)

"""92a: the 25 printed pairs against this code's, in dB re 20 μPa; ±2 dB is a reading band, not a criterion."""
function _run_appb_pairs(; q0_coupled::Bool=true, η_n_per_mode::Bool=false)
    pp = _appb_printed_pairs()
    cache = Dict{Tuple{Int,Int},Vector{NamedTuple}}()
    table = ValidationTableRow[]; xs = Float64[]; ref = Float64[]; got = Float64[]; n_ok = 0
    q0_share = String[]
    for (k, r) in enumerate(pp)
        terms = get!(() -> _r172428_pair_terms(r.rpm, r.H; q0_coupled, η_n_per_mode), cache, (r.rpm, r.H))
        j = findfirst(t -> (t.q, t.i, t.r) == (r.Q, r.I, r.st), terms)
        ours = j === nothing ? NaN : _dB_re20μPa(terms[j].p2)
        nasa = _dB_re20μPa(r.p2)
        ok = isfinite(ours) && abs(ours - nasa) ≤ 2.0; n_ok += ok
        ηpp = j === nothing ? NaN : terms[j].η_r_pp
        push!(xs, k); push!(ref, nasa); push!(got, ours)
        push!(table, ValidationTableRow("$(r.rpm) rpm H$(r.H): Q$(r.Q) I$(r.I) × st $(r.st) (η_r″ NASA $(r.η_r_hash), " *
                                        "ours $(round(ηpp; sigdigits=3)))", k, nasa, ours, ours - nasa, ok, "$(r.rpm) rpm H$(r.H)"))
    end
    for ((rpm, H), terms) in sort(collect(cache); by=first)
        tot = sum(t.p2 for t in terms)
        push!(q0_share, "$rpm:H$H $(round(100 * sum((t.p2 for t in terms if t.q == 0); init=0.0) / tot; digits=1)) %")
    end
    opts = (q0_coupled ? "" : ", q = 0 off") * (η_n_per_mode ? ", η_n per mode" : "")
    id = "APPB_PAIRS" * (q0_coupled ? "" : "_Q0") * (η_n_per_mode ? "_ETAN" : "")
    series = [PlotSeries("NASA's printed pair term (App. B pp. 207, 212)", :reference_points, xs, ref; panel=1),
              PlotSeries("this code, same pair$opts", :computed_points, xs, got; panel=1)]
    reason = "diagnostic (no criterion): $n_ok/$(length(pp)) printed pairs within ±2 dB of this code's$opts; " *
             "q = 0 share of this code's tone total: " * join(q0_share, ", ") * "; NASA prints no q = 0 pair"
    return ValidationCaseResult(id, _today_iso(),
        (; criterion="none (diagnostic); ±2 dB reading band", date="2026-10-29", q0_coupled, η_n_per_mode, n_ok, n=length(pp)),
        table, series, :no_verdict, reason, "V-CODE (diagnostic)", joinpath(_VAL_REPORT_DIR, _P92_REPORT))
end

"""
92b (`η_n_per_mode = false`): R172428_CODE's nine points with q = 0 off; criterion on the held-out 3000 rpm points only
(±3 dB at all three, fixed 2026-10-29); the 4000/5000 rpm points were seen in 92a (post-hoc). With `η_n_per_mode = true`:
the combination formed after 92a, post-hoc at every point, no criterion.
"""
function _run_r172428_code_q0(; η_n_per_mode::Bool=false)
    lv = _r172428_levels(; q0_coupled=false, η_n_per_mode)
    table = ValidationTableRow[]; n_ok = 0; n_held = 0
    for r in lv
        held = r.rpm == 3000 && !η_n_per_mode
        d = r.ours - r.nasa; ok = abs(d) ≤ 3.0
        held && (n_held += 1; n_ok += ok)
        push!(table, ValidationTableRow("$(r.rpm) rpm H$(r.H)", r.f_Hz, r.nasa, r.ours, d, ok,
                                        held ? "held out (92b)" : "post-hoc"))
    end
    xs = [r.f_Hz for r in lv]
    series = [PlotSeries("NASA PAIN (CR-172428 App. B / Table 10)", :reference_points, xs, [r.nasa for r in lv]; panel=1),
              PlotSeries("this code, q = 0 off" * (η_n_per_mode ? ", η_n per mode" : ""), :computed_points, xs,
                         [r.ours for r in lv]; panel=1)]
    r2 = x -> round(x; digits=2)
    n3 = count(r -> abs(r.ours - r.nasa) ≤ 3.0, lv)
    levels = join(["$(r.rpm):H$(r.H) $(r2(r.ours))" for r in lv], ", ")
    if η_n_per_mode
        return ValidationCaseResult("R172428_CODE_Q0_ETAN", _today_iso(),
            (; criterion="none (post-hoc: formed after 92a)", date="2026-10-29", ours=[r.ours for r in lv], nasa=[r.nasa for r in lv]),
            table, series, :no_verdict,
            "diagnostic, post-hoc (no criterion): $n3/9 within ±3 dB, largest |Δ| $(r2(maximum(abs(r.ours - r.nasa) for r in lv))) dB; $levels",
            "V-CODE (diagnostic)", joinpath(_VAL_REPORT_DIR, _P92_REPORT))
    end
    verdict = n_held == 3 && n_ok == 3 ? :met : :not_met
    return ValidationCaseResult("R172428_CODE_Q0", _today_iso(),
        (; criterion="±3 dB of NASA's printed prediction at each held-out 3000 rpm point (fixed 2026-10-29, before the run)",
           date="2026-10-29", ours=[r.ours for r in lv], nasa=[r.nasa for r in lv], n_ok, n_held),
        table, series, verdict,
        "$n_ok/$n_held held-out 3000 rpm points within ±3 dB; all nine (post-hoc for 4000/5000): $n3/9; $levels",
        "V-CODE", joinpath(_VAL_REPORT_DIR, _P92_REPORT))
end

function _iso92_validation_cases()
    pairs = [_r172428_csv("appB_contributors_4000rpm.csv"), _r172428_csv("appB_contributors_5000rpm.csv")]
    pred = _r172428_csv("appB_predictions.csv")
    figp = FigureRef("NASA CR-172428", "App. B pp. 207, 212", 207)
    figl = FigureRef("NASA CR-172428", "App. B pp. 196–212 / Table 10", 206)
    mk(id, title, files, fig, crit, run, xlab, ylab, tol, xscale) = ValidationCase(id, title, "92", files, fig, crit, "2026-10-29",
        "V-CODE", run, PlotSpec(; xlabel=xlab, ylabel=ylab, panel_titles=[id], error_mode=:absolute, error_tol=tol, xscale), "")
    return [
        mk("APPB_PAIRS", "This code's Eq. (8) pair terms vs NASA's printed largest contributors (92a)", pairs, figp,
           "None (diagnostic); ±2 dB is a reading band.", () -> _run_appb_pairs(), "printed pair (4000 rpm H1–H3, then 5000 rpm H1–H2)",
           "pair term (dB re 20 μPa)", 2.0, :identity),
        mk("APPB_PAIRS_Q0_ETAN", "Pair terms with q = 0 off and η_n per mode vs NASA's printed contributors (92c, post-hoc)", pairs, figp,
           "None (diagnostic, post-hoc).", () -> _run_appb_pairs(; q0_coupled=false, η_n_per_mode=true),
           "printed pair (4000 rpm H1–H3, then 5000 rpm H1–H2)", "pair term (dB re 20 μPa)", 2.0, :identity),
        mk("R172428_CODE_Q0", "CR-172428 reproduction with q = 0 off; 3000 rpm held out (92b)", [pred; pairs], figl,
           "±3 dB of NASA's printed prediction at each of the held-out 3000 rpm H1–H3 points (fixed 2026-10-29, before the run).",
           () -> _run_r172428_code_q0(), "tone frequency (Hz)", "SPL (dB)", 3.0, :log10),
        mk("R172428_CODE_Q0_ETAN", "CR-172428 reproduction with q = 0 off and η_n per mode (92c, post-hoc)", [pred; pairs], figl,
           "None (diagnostic, post-hoc).", () -> _run_r172428_code_q0(; η_n_per_mode=true), "tone frequency (Hz)", "SPL (dB)", 3.0, :log10),
    ]
end
