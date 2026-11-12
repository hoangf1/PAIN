# Phase 145e (2026-11-10): one cause record per case that carries a verdict and is not met. Written once from the
# record (Phase 135d, `docs/validation_reports/phase135_cause_records.md`); each sentence names the report it rests on.
# Causes in plain words (author 2026-11-09, ISSUE-019): no letter codes.

"""The six causes a not-met case can carry (ISSUE-019, author 2026-11-09)."""
const CAUSE_KINDS = (
    "old program form",
    "PAIN's method misses the measurement",
    "approximation in this recreation",
    "reference data",
    "NASA's printout or the measurement, not explained by the documents",
    "unexplained (no documented cause survived its test)",
)

"""
    CaseCause(kind, why, tested_in, left, source)

Why a case is not met: one of `CAUSE_KINDS`, one sentence, the phases that tested the cause, what is left, and the report.
"""
struct CaseCause
    kind::String
    why::String
    tested_in::String
    left::String
    source::String
end

# Phase 135d (2026-11-10): the causes of R996_LOADS, PER_FIG8, R172428_EXP, NR_TP1964_XOVER, FLIGHT_MODES, R172428_ETA
# and E14_LOSS checked and approved by the author ("yes"); PER_FIG8 moved from "not explained" to the method (author:
# Pereira's CFD misses the same way). CYL2D_PRINTED approved the same day as both: the miss comes from this recreation's
# eigenvalue check, and why NASA's program solves that grid is not explained (ISSUE-033).
const CASE_CAUSES = Dict{String,CaseCause}(
    "R996_LOADS" => CaseCause("approximation in this recreation",
        "XFOIL's section drag is about 25 % below TN 1546's measured drag and accounts for about half the torque gap (VALIDATION_GUIDELINE §2.14); section lift is not the cause (thrust moves at most 7.9 %).",
        "Phases 67, 69, 73, 141d", "on hold: more measured section data or CFD (ISSUE-030)", "phase73_polar_sensitivity.md"),
    "PER_FIG8" => CaseCause("PAIN's method misses the measurement",
        "Pereira's own CFD misses at the same angles by similar amounts (VALIDATION_GUIDELINE §2.14), and the loads are within 1 % of the measured thrust.",
        "Phases 69, 72, 74, 76", "chart label (ISSUE-031)", "pereira_forward_flight.md"),
    "R172428_EXP" => CaseCause("PAIN's method misses the measurement",
        "The code matches NASA's printout (9/9 within 1.19 dB, post-hoc), and NASA's printout misses the measurement the same way (5/9).",
        "Phases 54, 84, 88, 137c", "chart label (ISSUE-031)", "phase106_cabin_freq_printed.md"),
    "NR_TP1964_XOVER" => CaseCause("PAIN's method misses the measurement",
        "The misses are the Eq. (18) bands, where a negative noise reduction is a property of the equation (CR-159363 p. 138); the Eq. (19) bands agree within 2.5 dB.",
        "Phases 53, 138", "chart label (ISSUE-031)", "phase50_58_closeout.md"),
    "CYL2D_PRINTED" => CaseCause("NASA's printout or the measurement, not explained by the documents",
        "The narrow body (61/61) and the Merlin (51/51) are reproduced. At 62.6°, on NASA's own grid (solved on the real parts since 2026-11-12, ISSUE-033), ε(0,0) and all 53 mode types equal NASA's and every frequency is 0.30–0.31 % low: one common factor, which a cabin radius or sound speed that is not printed for this aircraft would give.",
        "Phases 103, 105, 140; ISSUE-033", "the common factor 1.00305 (no printed input gives it; none is chosen from the result)", "issue033_cyl2d_small_diameter.md"),
    # Phase 139d (2026-11-10): the band-centre hypothesis was not supported (15/32), so both are unexplained
    "R172428_ETA" => CaseCause("unexplained (no documented cause survived its test)",
        "Up to 470 Hz every mode is within 12 % of NASA's; above it the modes with almost no shell motion (share under 0.05) agree within 6 % and every other mode is 0.51–0.80 of NASA's. Every cause tested so far was ruled out, the band-centre rule included.",
        "Phases 82c, 118, 139", "look for an error in the loss-factor method (ISSUE-032)", "phase139b_band_centre.md"),
    # E14_LOSS: no verdict since 2026-11-12 (ISSUE-037, inputs incomplete), so no cause record
)

"""Cause record of `id`, or `nothing`."""
case_cause(id::AbstractString) = get(CASE_CAUSES, String(id), nothing)

# Phase 136f (2026-11-10): NASA's own printed prediction put on the gate of each measurement case for which NASA printed
# one, from the files the case reads. Information about NASA's program: not a case, not a verdict. Phase 137c: a case
# whose gate NASA's printout also misses carries a "method limit" mark on the chart and in §0; its verdict stays.
const NASA_GATE_CASES = ("R172428_EXP", "R172428_DB_EXP", "R172428_DBA_EXP", "NR_TP1964", "NR_TP1964_XOVER")

"""
    nasa_printout_on_gate(id) -> (; n_ok, n, met, rule) or `nothing`

NASA's printed prediction against the same measured points, tolerance and rule as case `id` (Phase 136f). `nothing`
for a case NASA printed no prediction for. R172428: App. B p. 206 / Table 10 (`appB_predictions.csv`), ±4 dB at every
point (the tones, or the H1–H3 sums per rpm for the dB and dB(A) cases); TP-1964: Fig. 8's ref. 2 curve, ±5 dB in at
least 75 % of the bands 100–5000 Hz.
"""
function nasa_printout_on_gate(id::AbstractString)
    id in NASA_GATE_CASES || return nothing
    if startswith(id, "R172428_")
        c = _read_csv_numeric_nan(_r172428_csv("appB_predictions.csv"))
        keep = [i for i in eachindex(c[:rpm]) if c[:H][i] ≤ 3 && isfinite(c[:measured_dB][i]) && isfinite(c[:nasa_pred_dB][i])]
        if id == "R172428_EXP"
            d = [c[:nasa_pred_dB][i] - c[:measured_dB][i] for i in keep]
        else
            w = id == "R172428_DBA_EXP"
            d = Float64[]
            for rpm in sort(unique(c[:rpm][keep]))
                t = sort([i for i in keep if c[:rpm][i] == rpm]; by=i -> c[:H][i])
                f = c[:f_Hz][t]
                push!(d, tonal_dBA(c[:nasa_pred_dB][t], f; weighted=w) - tonal_dBA(c[:measured_dB][t], f; weighted=w))
            end
        end
        n_ok = count(x -> abs(x) ≤ 4.0, d)
        return (; n_ok, n=length(d), met=n_ok == length(d), rule="±4 dB at every point")
    end
    c = _read_csv_numeric_nan(_iso43_data("tp1964", "tp1964_fig8_noise_reduction.csv"))
    d = [c[:nr_pred_ref2_dB][i] - c[:nr_meas_dB][i] for i in eachindex(c[:f_Hz])
         if 100.0 - 1e-9 ≤ c[:f_Hz][i] ≤ 5000.0 + 1e-9 && isfinite(c[:nr_meas_dB][i]) && isfinite(c[:nr_pred_ref2_dB][i])]
    n_ok = count(x -> abs(x) ≤ 5.0, d)
    return (; n_ok, n=length(d), met=n_ok / length(d) ≥ 0.75 - 1e-12, rule="±5 dB in at least 75 % of the bands")
end

# ISSUE-031 (rule written 2026-11-12, before Pereira's CFD was put on the gate; decided by Claude under the author's
# authority of 2026-11-11, from the author's words of 2026-11-10): a not-met case is marked "a published prediction
# misses too" when a published prediction of the same quantity at the same points, put on the case's own tolerance and
# rule, also misses, and that prediction is either PAIN's own printed output or a method of higher fidelity. An earlier
# NASA model that is not PAIN (TP-1964's ref. 2 curve, CR-159363; this code does not reproduce it) is shown in the table
# but gives no mark. The verdict stays not met.
"""Cases whose published prediction is not PAIN's printout or a higher-fidelity method: shown, no mark (ISSUE-031)."""
const NO_MARK_PREDICTIONS = Dict("NR_TP1964" => "NASA's earlier model (CR-159363), not PAIN",
                                 "NR_TP1964_XOVER" => "NASA's earlier model (CR-159363), not PAIN")

"""
    published_prediction_on_gate(id) -> (; n_ok, n, met, rule, source) or `nothing`

A published prediction of case `id`'s quantity on the case's own points, tolerance and rule (ISSUE-031): NASA's printout
(`nasa_printout_on_gate`), or for `PER_FIG8` Pereira's CFD ("Numerical" in Fig. 8, `pereira_fig8_directivity.csv`)
against the measured points, H1 within ±1.7 dB and H2 within ±3 dB at every microphone.
"""
function published_prediction_on_gate(id::AbstractString)
    g = nasa_printout_on_gate(id)
    g !== nothing && return (; g..., source=get(NO_MARK_PREDICTIONS, String(id), "NASA's PAIN printout"))
    id == "PER_FIG8" || return nothing
    hdr, rows = _read_csv_rows(_data_path("pereira", "pereira_fig8_directivity.csv"))
    col = Dict(h => i for (i, h) in enumerate(hdr))
    n = n_ok = 0
    for r in rows
        H = tryparse(Int, r[col["BPF"]]); (H === nothing || H > 2) && continue
        num = tryparse(Float64, r[col["Numerical_dB"]]); ex = tryparse(Float64, r[col["Experimental_dB"]])
        (num === nothing || ex === nothing) && continue
        n += 1; n_ok += abs(num - ex) ≤ (H == 1 ? 1.7 : 3.0)
    end
    return (; n_ok, n, met=n > 0 && n_ok == n, rule="H1 within ±1.7 dB and H2 within ±3 dB at every microphone",
            source="Pereira's CFD (Fig. 8, Numerical)")
end

"""True when a published prediction (PAIN's printout or a higher-fidelity method) also misses case `id`'s gate
(Phase 137c "method limit"; widened by ISSUE-031, 2026-11-12)."""
function method_limit(id::AbstractString)
    haskey(NO_MARK_PREDICTIONS, id) && return false
    g = published_prediction_on_gate(id)
    return g !== nothing && !g.met
end

function _nasa_gate_cell(id)
    g = published_prediction_on_gate(id)
    g === nothing && return "not printed"
    return "$(g.n_ok)/$(g.n), $(g.source)" * (g.met ? " (meets the gate)" :
           haskey(NO_MARK_PREDICTIONS, id) ? " (misses; no mark)" : " (misses too: method limit)")
end

"""Markdown table: why each not-met case on the chart is not met, generated from `CASE_CAUSES` and the snapshot."""
function why_not_met_markdown(; rec::AbstractDict=recorded_case_errors())
    io = IOBuffer()
    println(io, "### Why each case is not met\n")
    println(io, "| Case | Points | A published prediction on the same gate | Cause | Why | Tested in | What is left |\n",
            "|---|---|---|---|---|---|---|")
    for id in sort([k for (k, r) in rec if r.verdict == "not_met" && !no_verdict_by_rule(k) &&
                     haskey(VALIDATION_CASES, k)])   # a retired case keeps its row in the file until it is rewritten (Phase 137a)
        c = case_cause(id)
        r = rec[id]
        pts = "$(r.n_within)/$(r.n_rows)"
        g = _nasa_gate_cell(id)
        if c === nothing
            println(io, "| `", id, "` | ", pts, " | ", g, " | no cause recorded | | | |")
        else
            println(io, "| `", id, "` | ", pts, " | ", g, " | ", c.kind, " | ", c.why, " (`", c.source, "`) | ",
                    c.tested_in, " | ", c.left, " |")
        end
    end
    println(io, "\nA published prediction on the same gate: NASA's printed prediction, or Pereira's CFD for `PER_FIG8`, put on ",
            "the case's own measured points, tolerance and rule (Phase 136f; ISSUE-031, 2026-11-12); information, not a ",
            "verdict. \"Method limit\": PAIN's own printout or a method of higher fidelity misses the same gate, so the miss ",
            "is not this code's alone; the case's verdict stays not met. An earlier NASA model that is not PAIN gives no mark.")
    println(io)
    return String(take!(io))
end
