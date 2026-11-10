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

const CASE_CAUSES = Dict{String,CaseCause}(
    "R996_LOADS" => CaseCause("approximation in this recreation",
        "Thrust and power fall short of the measured values by the error of the XFOIL section data; the compact-chord sound model is not the cause (at most 0.27 dB).",
        "Phases 67, 69", "measured section data (Phase 141)", "report996_loads.md"),
    "PER_FIG8" => CaseCause("NASA's printout or the measurement, not explained by the documents",
        "Thrust is within 1 % of the measured value, yet the second harmonic misses at 20°; no measured section data exist at Pereira's Reynolds number.",
        "Phases 69, 72, 74, 76", "measured section data (Phase 141)", "pereira_forward_flight.md"),
    "R172428_EXP" => CaseCause("PAIN's method misses the measurement",
        "NASA's own printout misses the first harmonic at 3000 and 5000 rpm by the same amount as this code.",
        "Phases 54, 84, 88", "share of the largest mode pair (Phase 136d)", "phase92_appb_pairs.md"),
    "NR_TP1964_XOVER" => CaseCause("PAIN's method misses the measurement",
        "The misses are the Eq. (18) bands, where a negative noise reduction is a property of the equation (CR-159363 p. 138); the Eq. (19) bands agree within 2.5 dB.",
        "Phase 53", "none in the documents", "tp1964_hf.md"),
    "CYL2D_PRINTED" => CaseCause("approximation in this recreation",
        "On NASA's printed grid rule the narrow body (61/61) and the Merlin (51/51) are reproduced; at 62.6° this code's eigenproblem fails its own real-eigenvalue check on NASA's grid (|Im|/|Re| 0.0012 against 0.001, an assumption of Q60), so a finer grid is used and misses.",
        "Phases 103, 105, 140", "why the 62.6° grid gives complex eigenvalues here and not in NASA's program", "phase105_cyl2d_printed.md"),
    "FLIGHT_MODES" => CaseCause("reference data",
        "The reference file is a partial transcription of App. C, and the in-plane mass of about 20 modes differs.",
        "Phase 110", "blind second transcription (Phase 142)", "phase110_flight_modes_pass2.md"),
    # Phase 139d (2026-11-10): the band-centre hypothesis was not supported (15/32), so both are unexplained
    "R172428_ETA" => CaseCause("unexplained (no documented cause survived its test)",
        "The floor modes agree within 5 %; the shell modes are 0.5–0.8 of NASA's, in the trim term. Shapes, masses, trim admittance and the band-centre rule were each tested.",
        "Phases 82c, 139", "none in the documents", "phase139b_band_centre.md"),
    "E14_LOSS" => CaseCause("unexplained (no documented cause survived its test)",
        "1.1–1.7 times NASA's loss factor at 630–1250 Hz and 0.5–0.7 above 1600 Hz, a pattern unlike R172428_ETA's; NASA's per-band PF-105 table was refuted (6/18 against 7/18).",
        "Phases 100, 139", "none in the documents", "phase139b_band_centre.md"),
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

"""True when NASA's own printout also misses case `id`'s gate (Phase 137c "method limit")."""
function method_limit(id::AbstractString)
    g = nasa_printout_on_gate(id)
    return g !== nothing && !g.met
end

_nasa_gate_cell(id) = (g = nasa_printout_on_gate(id); g === nothing ? "not printed" :
                       "$(g.n_ok)/$(g.n)" * (g.met ? " (meets the gate)" : " (misses too: method limit)"))

"""Markdown table: why each not-met case on the chart is not met, generated from `CASE_CAUSES` and the snapshot."""
function why_not_met_markdown(; rec::AbstractDict=recorded_case_errors())
    io = IOBuffer()
    println(io, "### Why each case is not met\n")
    println(io, "| Case | Points | NASA's own printout on the same gate | Cause | Why | Tested in | What is left |\n",
            "|---|---|---|---|---|---|---|")
    for id in sort([k for (k, r) in rec if r.verdict == "not_met" && !no_verdict_by_rule(k)])
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
    println(io, "\nNASA's own printout: NASA's printed prediction put on the case's own measured points, tolerance and ",
            "rule (Phase 136f); information about NASA's program, not a verdict. \"Method limit\": NASA's program misses ",
            "the same gate, so the miss is in PAIN's method as NASA ran it (Phase 137c); the case's verdict stays.")
    println(io)
    return String(take!(io))
end
