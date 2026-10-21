#!/usr/bin/env julia
# Plan step 24a / I-14: BBN phase/coherence loaders (no edits to source CSVs).
# Wide appendix tables → long rows: (report, mic_a, mic_b, harmonic, run, coherence, phase_deg).
# Usage: include("bbn_data.jl"); rows = load_bbn_phase_coherence_long()
using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))

const BBN_158919 = joinpath(@__DIR__, "..", "..", "data", "NASA_CR-158919")
const BBN_159124 = joinpath(@__DIR__, "..", "..", "data", "NASA_CR-159124")

"""
    load_bbn_phase_coherence_long() -> Vector{NamedTuple}

Long-form rows from CR-158919 App. C and CR-159124 App. D.
Coherence cut (folder READMEs): < 0.15 low confidence; < 0.05 drop for 23a/23b.
"""
function load_bbn_phase_coherence_long(;
        path_158919::AbstractString=joinpath(BBN_158919, "bbn_phase_coherence_CR158919_appendixC.csv"),
        path_159124::AbstractString=joinpath(BBN_159124, "bbn_phase_coherence_CR159124_appendixD.csv"))
    out = NamedTuple[]
    for (path, report) in ((path_158919, "CR-158919"), (path_159124, "CR-159124"))
        isfile(path) || continue
        run_cols = nothing
        for raw in eachline(path)
            startswith(raw, "#") && continue
            if run_cols === nothing && (startswith(lowercase(raw), "source") || startswith(lowercase(raw), "mic"))
                hdr = split(lowercase(raw), ',')
                run_cols = Tuple{Int,Int,Int}[]
                for (i, h) in enumerate(hdr)
                    m = match(r"coh_run(\d+)", h)
                    m === nothing && continue
                    push!(run_cols, (parse(Int, m.captures[1]), i, i + 1))
                end
                continue
            end
            run_cols === nothing && continue
            p = split(strip(raw), ',')
            # Columns: source_pdf_page, printed_page, mic_a, mic_b, harmonic, then coh/phase pairs
            length(p) < 5 && continue
            a = tryparse(Int, p[3]); b = tryparse(Int, p[4]); H = tryparse(Int, p[5])
            (a === nothing || b === nothing || H === nothing) && continue
            for (rn, ic, ip) in run_cols
                ic > length(p) && continue
                cs = strip(p[ic]); ps = ip <= length(p) ? strip(p[ip]) : "-"
                (cs == "-" || ps == "-" || isempty(cs) || isempty(ps)) && continue
                coh = tryparse(Float64, cs); ph = tryparse(Float64, ps)
                (coh === nothing || ph === nothing) && continue
                push!(out, (report=report, mic_a=a, mic_b=b, harmonic=H, run=rn,
                             coherence=coh, phase_deg=ph))
            end
        end
    end
    return out
end

# Back-compat name
load_bbn_phase_coherence() = load_bbn_phase_coherence_long()

if abspath(PROGRAM_FILE) == @__FILE__
    rows = load_bbn_phase_coherence_long()
    println("bbn_data long: $(length(rows)) rows")
    for r in rows[1:min(5, length(rows))]
        println(r)
    end
end
