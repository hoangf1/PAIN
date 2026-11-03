#!/usr/bin/env julia
# Phase 30d — parametric vs surrogate cabin-block regression on the test article.
# Record of the shift only: no criterion, no verdict, no baseline renewal.
# First run 2026-10-22.
using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN

const REPORT = normpath(joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports",
                                 "parametric_regression.md"))
const T1_CSV = joinpath(dirname(default_e11_paths().A), "t1_interior_targets.csv")
const T2_CSV = joinpath(dirname(default_e11_paths().A), "t2_third_octave_targets.csv")

"""Loss factors η̄_n and η̄_r′ at tone bands (and T2 centres) for one chain."""
function _loss_rows(inp::PainInputs; bpf_Hz::Float64, bands_Hz)
    rows = NamedTuple[]
    for fc in bands_Hz
        band = hf_structural_band(inp, fc)
        losses = hf_band_loss_factors(inp, fc, band; η_r_cap=nothing)
        push!(rows, (; fc_Hz=fc, η_n=losses.η̄_n, η_r′=losses.η̄_r′))
    end
    return rows
end

function _run_chain(; cabin_blocks::Symbol, broadband_model::Symbol, structural_solver::Symbol)
    # Same free field / geometry as T1–T2 (e11, Phase III trim). cabin_blocks selects
    # the cabin chain only; free-field path is unchanged.
    r = run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200.0, blocking=R2,
                          trim=:phase3, cabin_blocks=cabin_blocks,
                          broadband_model=broadband_model,
                          structural_solver=structural_solver,
                          use_table_d1=(structural_solver === :table_d1))
    return r
end

function main()
    println("30d parametric regression: surrogate (Table D-1) vs parametric (App. D + Eq.19)…")
    r_s = _run_chain(; cabin_blocks=:surrogate, broadband_model=:surrogate,
                     structural_solver=:table_d1)
    r_p = _run_chain(; cabin_blocks=:parametric, broadband_model=:eq19,
                     structural_solver=:appd)

    bpf = 200.0
    tone_bands = [200.0, 400.0, 630.0]          # H1–H3 1/3-oct centres
    t2_bands = [1250.0, 1600.0, 2000.0]
    all_bands = vcat(tone_bands, t2_bands)

    loss_s = _loss_rows(r_s.inputs; bpf_Hz=bpf, bands_Hz=all_bands)
    loss_p = _loss_rows(r_p.inputs; bpf_Hz=bpf, bands_Hz=all_bands)

    t1 = _read_csv_numeric(T1_CSV)
    t2 = _read_csv_numeric(T2_CSV)

    io = IOBuffer()
    println(io, "# Parametric cabin blocks — test-article regression (phase 30d)")
    println(io)
    println(io, "**First run 2026-10-22. Record of the shift, no criterion.**")
    println(io)
    println(io, "Compares the current cabin chain (`cabin_blocks=:surrogate`, Table D-1 hybrid,")
    println(io, "`broadband_model=:surrogate` with `bb_j2_scale` and the absorption curve) with")
    println(io, "the parametric chain (`:parametric`, App. D modes, Eqs. 19–23 / I-21 open readings)")
    println(io, "on the NASA test-article geometry and Phase III trim, e11 free field, blocking R2.")
    println(io, "No parameter was chosen from Fig. E-16 / E-9 / Table D-1. Frozen baselines were")
    println(io, "**not** renewed.")
    println(io)
    println(io, "## Loss factors (η̄_n, η̄_r′ per band)")
    println(io)
    println(io, "| fc [Hz] | η̄_n surrogate | η̄_n parametric | Δη̄_n | η̄_r′ surrogate | η̄_r′ parametric | Δη̄_r′ |")
    println(io, "|--------:|--------------:|---------------:|-----:|---------------:|----------------:|------:|")
    for (a, b) in zip(loss_s, loss_p)
        @assert a.fc_Hz == b.fc_Hz
        dηn = b.η_n - a.η_n
        dηr = b.η_r′ - a.η_r′
        println(io, "| ", Int(round(a.fc_Hz)), " | ",
                round(a.η_n; sigdigits=4), " | ", round(b.η_n; sigdigits=4), " | ",
                round(dηn; sigdigits=4), " | ",
                round(a.η_r′; sigdigits=4), " | ", round(b.η_r′; sigdigits=4), " | ",
                round(dηr; sigdigits=4), " |")
    end
    println(io)
    println(io, "## Interior SPL H1–H3 (Fig. E-16) and T2 bands (Fig. E-9)")
    println(io)
    println(io, "| Quantity | Measured mean [dB] | Surrogate [dB] | Parametric [dB] | Δ (par − sur) [dB] |")
    println(io, "|----------|-------------------:|---------------:|----------------:|-------------------:|")
    for i in 1:3
        H = Int(round(t1[:harmonic][i]))
        mean = t1[:measured_mean_SPL_dB][i]
        gs = r_s.spectrum.harmonic_SPL_dB[H]
        gp = r_p.spectrum.harmonic_SPL_dB[H]
        println(io, "| H$H @ ", Int(round(t1[:band_Hz][i])), " Hz | ", mean, " | ",
                round(gs; digits=2), " | ", round(gp; digits=2), " | ",
                round(gp - gs; digits=2), " |")
    end
    for i in eachindex(t2[:fc_Hz])
        fc = t2[:fc_Hz][i]
        mean = t2[:measured_mean_SPL_dB][i]
        bs = nearest_third_octave(fc, collect(keys(r_s.spectrum.third_octave_SPL_dB)))
        bp = nearest_third_octave(fc, collect(keys(r_p.spectrum.third_octave_SPL_dB)))
        gs = get(r_s.spectrum.third_octave_SPL_dB, bs, NaN)
        gp = get(r_p.spectrum.third_octave_SPL_dB, bp, NaN)
        println(io, "| T2 fc=", Int(round(fc)), " Hz | ", mean, " | ",
                round(gs; digits=2), " | ", round(gp; digits=2), " | ",
                round(gp - gs; digits=2), " |")
    end
    println(io)
    println(io, "## Geometry check (parametric path)")
    println(io)
    fuse = r_p.fuse
    V = cabin_volume(r_p.inputs)
    A = coupling_area(fuse)
    areas = hf_absorbing_areas(r_p.inputs)
    println(io, "- L = $(fuse.L) m, a = $(fuse.a) m, θ0 = $(fuse.theta0_deg)°")
    println(io, "- V = $(round(V; sigdigits=6)) m³ (`cabin_volume`)")
    println(io, "- A = $(round(A; sigdigits=6)) m² (`coupling_area`)")
    println(io, "- S = $(round(areas.S; sigdigits=6)) m² (absorbing, HF path)")
    println(io, "- structural notes: $(r_p.structural.notes)")
    println(io, "- spectrum notes: $(r_p.spectrum.notes)")
    println(io)
    println(io, "## Baselines")
    println(io)
    println(io, "No `data/baselines/*` file was rewritten. If a later full-suite diff appears,")
    println(io, "renewal remains a dated author decision (R11).")
    println(io)

    mkpath(dirname(REPORT))
    write(REPORT, String(take!(io)))
    println("wrote $REPORT")
    println("H1–H3 surrogate: ", round.(r_s.spectrum.harmonic_SPL_dB[1:3]; digits=2))
    println("H1–H3 parametric: ", round.(r_p.spectrum.harmonic_SPL_dB[1:3]; digits=2))
end

# Private CSV helper already in the package
_read_csv_numeric(path) = PAIN._read_csv_numeric(path)

main()
