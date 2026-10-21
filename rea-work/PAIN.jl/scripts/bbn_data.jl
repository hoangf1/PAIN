#!/usr/bin/env julia
# Plan step 24a: merged loader for BBN phase/coherence CSVs (no CSV edits).
# Usage: include("bbn_data.jl"); tbl = load_bbn_phase_coherence()
using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using CSV, DataFrames

const BBN_158919 = joinpath(@__DIR__, "..", "..", "data", "NASA_CR-158919")
const BBN_159124 = joinpath(@__DIR__, "..", "..", "data", "NASA_CR-159124")

"""
    load_bbn_phase_coherence() -> DataFrame

Columns: report, run, rpm, taxi_speed_kt, mic_a, mic_b, harmonic, coherence, phase_deg.
Reads both CR-158919 appendix C and CR-159124 appendix D without editing the source CSVs.
Coherence cut (documented in folder READMEs): < 0.15 low confidence; < 0.05 drop for 23a/23b.
"""
function load_bbn_phase_coherence(;
        path_158919::AbstractString=joinpath(BBN_158919, "bbn_phase_coherence_CR158919_appendixC.csv"),
        path_159124::AbstractString=joinpath(BBN_159124, "bbn_phase_coherence_CR159124_appendixD.csv"),
        runs_158919::AbstractString=joinpath(BBN_158919, "bbn_runs_table1.csv"),
        runs_159124::AbstractString=joinpath(BBN_159124, "bbn_runs_table1.csv"))
    function read_phase(path, report)
        # Skip comment lines starting with #
        rows = CSV.File(path; comment="#") |> DataFrame
        rows.report .= report
        return rows
    end
    a = read_phase(path_158919, "CR-158919")
    b = read_phase(path_159124, "CR-159124")
    # Normalize column names if the two appendices differ slightly
    rename!(a, Dict(n => lowercase(String(n)) for n in names(a)); makeunique=true)
    rename!(b, Dict(n => lowercase(String(n)) for n in names(b)); makeunique=true)
    return vcat(a, b; cols=:union)
end

if abspath(PROGRAM_FILE) == @__FILE__
    tbl = load_bbn_phase_coherence()
    println("bbn_data: $(nrow(tbl)) rows, columns=$(names(tbl))")
    println(first(tbl, min(5, nrow(tbl))))
end
