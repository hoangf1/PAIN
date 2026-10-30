# Phase 108 — the floor term's sign in flight run 10, tested on the H1 and H5 pairs PAIN printed (IMPLEMENTATION_PLAN.md
# §8ax; test fixed 2026-10-30 before any H1/H5 pair was computed). η_r″ (Eq. 83) does not depend on the field, so the cut
# H1/H5 field rows do not matter. Diagnostic (no verdict): H_pre = "run 10 was computed before CR-172428 App. A item 2".

const _P108_REPORT = "phase108_run10_floor_sign.md"

"""η_r″ of NASA's printed (Q, I) × structural-mode pair at tone H of run 10, with the floor term's sign `fs`."""
function _run10_pair_eta(inp::PainInputs, H::Int, q::Int, I::Int, r::Int)
    rows = NamedTuple[]
    tone_mean_square_pressure(inp, H, 2π * FLIGHT10_BPF_Hz * H; terms=rows)
    t = findfirst(x -> x.q == q && x.i == I && x.r == r, rows)
    return t === nothing ? NaN : rows[t].η_r_pp
end

function _run_flight10_floor_sign()
    base = r172428_flight10_inputs()
    z = zeros(size(base.amplitudes, 1), size(base.amplitudes, 2), 1)                   # H5: η_r″ does not use the field
    base = _with_fields(base; amplitudes=cat(base.amplitudes, z; dims=3), phases=cat(base.phases, z; dims=3))
    inps = Dict(fs => _with_fields(base; floor_sign=fs) for fs in (1.0, -1.0))
    pairs = [split(l, ",") for l in eachline(_r172428_csv("appD_run10_pairs.csv")) if !startswith(l, "#")][2:end]
    table = ValidationTableRow[]; cnt = Dict(1.0 => 0, -1.0 => 0); n = 0; xs = Float64[]; rp = Float64[]; rm = Float64[]
    inband(x) = 0.4 ≤ x ≤ 2.5
    for p in pairs
        H = parse(Int, p[1]); H in (1, 5) || continue
        nasa = parse(Float64, p[12]); nasa > 0 || continue
        q, I, r = parse(Int, p[6]), parse(Int, p[7]), parse(Int, p[8])
        ratios = Dict(fs => _run10_pair_eta(inps[fs], H, q, I, r) / nasa for fs in (1.0, -1.0))
        n += 1
        for fs in (1.0, -1.0); cnt[fs] += inband(ratios[fs]); end
        push!(xs, n); push!(rp, ratios[1.0]); push!(rm, ratios[-1.0])
        lab = "H$H Q$q I$I × mode $r"
        push!(table, ValidationTableRow("$lab: η_r″ ours/NASA, floor term added", n, 1.0, ratios[1.0], ratios[1.0] - 1, inband(ratios[1.0]), "floor term added (+)"))
        push!(table, ValidationTableRow("$lab: η_r″ ours/NASA, floor term subtracted", n, 1.0, ratios[-1.0], ratios[-1.0] - 1, inband(ratios[-1.0]), "floor term subtracted (−)"))
    end
    cp, cm = cnt[1.0], cnt[-1.0]
    outcome = cm ≥ 7 && cm > cp ? "supported" : cp ≥ 7 && cp > cm ? "refuted" : "undecided"
    series = [PlotSeries("floor term added (+)", :computed_points, xs, rp; panel=1),
              PlotSeries("floor term subtracted (−)", :computed_points, xs, rm; panel=1),
              PlotSeries("NASA (ratio 1)", :reference_points, xs, ones(length(xs)); panel=1)]
    return ValidationCaseResult("FLIGHT10_FLOOR_SIGN", _today_iso(),
        (; criterion="H_pre supported if ≥ 7/10 within [0.4, 2.5] with − and more than with +; refuted in the mirror case",
           date="2026-10-30", n, count_plus=cp, count_minus=cm, outcome),
        table, series, :no_verdict,
        "diagnostic (no verdict): $n printed H1/H5 pairs; η_r″ within [0.4, 2.5]× NASA's: $cp with the floor term added, " *
        "$cm subtracted; H_pre $outcome",
        "V-CODE (diagnostic)", joinpath(_VAL_REPORT_DIR, _P108_REPORT))
end

function _iso108_validation_cases()
    return [ValidationCase("FLIGHT10_FLOOR_SIGN", "Run 10's floor-term sign on the printed H1/H5 pairs (108)", "108",
        [_r172428_csv("appD_run10_pairs.csv")], FigureRef("NASA CR-172428", "App. D pp. 235–236", 235),
        "None (diagnostic); H_pre supported if ≥ 7/10 H1/H5 pairs within [0.4, 2.5]× NASA's η_r″ with the floor term " *
        "subtracted and more than with it added (fixed 2026-10-30 before the run).",
        "2026-10-30", "V-CODE", _run_flight10_floor_sign,
        PlotSpec(; xlabel="printed pair", ylabel="η_r″ ours / NASA", panel_titles=["FLIGHT10_FLOOR_SIGN"], yscale=:log10,
                 error_mode=:absolute, error_tol=1.5), "")]
end
