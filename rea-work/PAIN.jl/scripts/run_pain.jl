#!/usr/bin/env julia
# End-to-end PAIN: synthetic smoke + Fig.E-11 SRC_TA (T1/T2) + optional aircraft.
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN

const REPORTS = joinpath(@__DIR__, "..", "..", "docs", "validation_reports")
mkpath(REPORTS)

function _all_pass(records)
    isempty(records) && return false
    all(r -> r.result == "PASS", records)
end

# --- Synthetic smoke ---
result = run_pain_pipeline(; use_synthetic=true, n_harmonics=5, bpf_Hz=150.0)
println("=== PAIN pipeline (synthetic) ===")
println("Acoustic modes: ", length(result.acoustic.modes))
println("Structural modes: ", length(result.structural.modes))
println("BPF: ", result.spectrum.bpf_Hz, " Hz")
println("Interior tonal SPL [dB]:")
for (H, L) in enumerate(result.spectrum.harmonic_SPL_dB)
    println("  H=$H  f=$(H * result.spectrum.bpf_Hz) Hz  SPL=$(round(L; digits=1)) dB")
end
dBA, lo, hi = overall_dBA(result.spectrum)
println("Overall dB(A): $(round(dBA; digits=1))  [$(round(lo; digits=1)), $(round(hi; digits=1))] (±3.5 dB band)")

println("\n=== CYL2D vs Table C-1 (a=1 m) ===")
ref = TABLE_C1_FREQ_HZ
for (i, m) in enumerate(result.acoustic.modes[1:min(6, end)])
    r = i <= length(ref) ? ref[i] : NaN
    err = isnan(r) || r == 0 ? abs(m.f_Hz_unit - r) : 100 * abs(m.f_Hz_unit - r) / r
    println("  mode $(m.index): f=$(round(m.f_Hz_unit; digits=1)) Hz  ref=$r  err%=$(round(err; digits=1))")
end

write_validation_record(joinpath(REPORTS, "pipeline_smoke.md"), [
    ValidationRecord("PAIN", "X-EXTRAP", "synthetic free-field smoke run",
        "pipeline completes", "n/a", "PASS",
        "Synthetic smoke only. Validated cabin path: source=:e11 (Fig.E-11)."),
])

# --- SRC_TA Fig.E-11 ---
println("\n=== PAIN pipeline (Fig.E-11 digitized) ===")
paths = default_e11_paths()
δmax, δH = delta_dig_dB(paths.A, paths.B)
println("δ_dig max = $(round(δmax; digits=2)) dB  (H1=$(round(δH[1];digits=2)) H2=$(round(δH[2];digits=2)) H3=$(round(δH[3];digits=2)))")
write_validation_record(joinpath(REPORTS, "e11_delta_dig.md"), [
    ValidationRecord("SRC_TA", "V-EXP", "Fig.E-11 dual digitization",
        "δ_dig max |A-B|", "≤ 1.0 dB", δmax ≤ 1.0 ? "PASS" : "FAIL",
        "δmax=$(round(δmax; digits=2)) dB; H1=$(round(δH[1]; digits=2)) H2=$(round(δH[2]; digits=2)) H3=$(round(δH[3]; digits=2))"),
])

e11 = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
println(e11.spectrum.notes)
for (H, L) in enumerate(e11.spectrum.harmonic_SPL_dB)
    println("  H=$H  f=$(H * e11.spectrum.bpf_Hz) Hz  SPL=$(round(L; digits=1)) dB")
end
const _I17_HEADER = "Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc."
t1 = evaluate_T1(e11.spectrum)
t1_path = joinpath(REPORTS, "t1_tonal.md")
write_validation_record(t1_path, t1; header=_I17_HEADER)
for r in t1
    println("  T1: $(r.metric) → $(r.result)  $(r.notes)")
end

t2 = evaluate_T2(e11.spectrum)
t2_path = joinpath(REPORTS, "t2_third_octave.md")
write_validation_record(t2_path, t2; header=_I17_HEADER)
for r in t2
    println("  T2: $(r.metric) → $(r.result)  $(r.notes)")
end

# MRP seed self-check
mrp_rec = validate_mrp_table_d1(structural_modes_from_table_d1(; n_keep=32); tol_frac=0.001)
write_validation_record(joinpath(REPORTS, "mrp_table_d1.md"), mrp_rec)
npass = count(r -> r.result == "PASS", mrp_rec)
println("\nMRP Table D-1 seed self-check: $npass/$(length(mrp_rec)) PASS")

# --- Optional aircraft free-field→cabin (X-EXTRAP) ---
json = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
if isfile(json)
    println("\n=== PAIN pipeline (CCBlade+F1A aircraft, X-EXTRAP) ===")
    try
        ac = run_pain_pipeline(; source=:aircraft, aircraft_json=json,
                                n_harmonics=3, blocking=R2, r_p=0.965)
        for (H, L) in enumerate(ac.spectrum.harmonic_SPL_dB)
            println("  H=$H  f=$(round(H * ac.spectrum.bpf_Hz; digits=1)) Hz  SPL=$(round(L; digits=1)) dB")
        end
        dBA_ac, _, _ = overall_dBA(ac.spectrum)
        println("  Overall dB(A)≈$(round(dBA_ac; digits=1))  (not NASA-validated)")
    catch e
        println("  aircraft path error: ", sprint(showerror, e))
    end
end

println("
=== Summary ===")
println("δ_dig≤1: ", δmax ≤ 1.0 ? "PASS" : "FAIL")
println("T1 (result, Eq. 8 chain without tuning; not a gate): ", _all_pass(t1) ? "all PASS" : "$(count(r -> r.result == "PASS", t1)) of $(length(t1)) PASS")
println("T2 (result, not a gate): ", _all_pass(t2) ? "all PASS" : "$(count(r -> r.result == "PASS", t2)) of $(length(t2)) PASS")
println("MRP seed: ", npass == length(mrp_rec) ? "PASS" : "FAIL")
println("Wrote reports under ", REPORTS)
# T1/T2 are recorded, not gated, since phase 17a removed the calibrated surrogate (plan 18a); the code checks gate the run.
(δmax ≤ 1.0 && npass == length(mrp_rec)) || error("run_pain: a code-level gate failed (δ_dig or MRP seed)")
println("Code-level gates PASS; T1/T2 recorded above.")
