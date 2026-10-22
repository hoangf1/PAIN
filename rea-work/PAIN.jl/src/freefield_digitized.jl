"""
SRC_TA — digitized Fig. E-11 measured free-field line (ℓ = 1).

Amplitudes from dual digitizations under `data/`. Phases from ANOPP Table 8
(no measured phase in Fig. E-11 — CR-3813 App. E). Grid extension → 160 pts
is V-ASSUMED (e11 path only; aircraft path uses F1A at all 160 points, phase 21).
"""

# Amplitude convention (CR-3813 Eqs. (28)–(31); User Manual App. A; CR-172428 p. 41):
# - Published / measured SPL is rms: ⟨p²⟩ = p₀² 10^(SPL/10).
# - PAIN input A_H is the cosine-peak Fourier amplitude (A_H = √(a_H²+b_H²), mean square A²/2).
# - Hence SPL → A: A = √2 · p₀ · 10^(SPL/20); A → SPL: SPL = 20 log10(A / (√2 p₀)).
# `spl_dB_to_Pa` returns rms pressure (unchanged meaning). Use `spl_dB_to_peak_Pa` wherever a
# published SPL becomes PAIN's A; use `peak_Pa_to_spl_dB` when converting F1A A to SPL.

"""SPL dB → rms pressure Pa (re 20 μPa)."""
spl_dB_to_Pa(spl_dB::Real) = 20e-6 * 10^(float(spl_dB) / 20)

"""SPL dB (rms) → cosine-peak Fourier amplitude Pa for PAIN input A_H."""
spl_dB_to_peak_Pa(spl_dB::Real) = sqrt(2) * spl_dB_to_Pa(spl_dB)

"""Cosine-peak Fourier amplitude A (Pa) → rms-referenced SPL dB (re 20 μPa)."""
peak_Pa_to_spl_dB(A::Real) = 20 * log10(float(A) / (sqrt(2) * 20e-6) + 1e-30)

"""Read a simple CSV with header; skip `#` comment lines. Returns Dict{Symbol,Vector}."""
function _read_csv_numeric(path::AbstractString)
    lines = String[]
    for raw in eachline(path)
        s = strip(raw)
        isempty(s) && continue
        startswith(s, '#') && continue
        push!(lines, s)
    end
    isempty(lines) && error("empty CSV: $path")
    headers = Symbol.(split(lines[1], ','))
    cols = Dict{Symbol,Vector{Float64}}()
    # Keep only columns whose first data cell parses as Float64
    first_vals = split(lines[2], ',')
    keep = Int[]
    for (i, h) in enumerate(headers)
        i > length(first_vals) && continue
        try
            parse(Float64, strip(first_vals[i]))
            cols[h] = Float64[]
            push!(keep, i)
        catch
            # skip text columns (e.g. notes)
        end
    end
    for row in lines[2:end]
        vals = split(row, ',')
        for i in keep
            push!(cols[headers[i]], parse(Float64, strip(vals[i])))
        end
    end
    return cols
end

"""
    delta_dig_dB(path_A, path_B) -> (δ_max, δ_by_harmonic)

Max |SPL_A − SPL_B| over k and H=1..3 (flowchart δ_dig check).
"""
function delta_dig_dB(path_A::AbstractString, path_B::AbstractString)
    A = _read_csv_numeric(path_A)
    B = _read_csv_numeric(path_B)
    δH = Dict{Int,Float64}()
    δmax = 0.0
    for (H, key) in ((1, :SPL_H1_dB), (2, :SPL_H2_dB), (3, :SPL_H3_dB))
        d = maximum(abs.(A[key] .- B[key]))
        δH[H] = d
        δmax = max(δmax, d)
    end
    return δmax, δH
end

"""
    freefield_from_e11_csv(amp_csv, phase_csv, fuse, prop, spec;
                          bpf_Hz=200.0, n_harmonics=3,
                          anopp_spl_csv=nothing, broadband_clip_dB=10) -> FreeFieldHarmonicGrid

Load ℓ=1 measured SPL + phase surrogate → Pa amplitudes → extend to 160-pt grid.

If `anopp_spl_csv` is given, replace measured SPL where it exceeds ANOPP by more
than `broadband_clip_dB` (CR-3813 notes broadband contamination off prop plane
on Fig. E-11). Marked V-ASSUMED cleanup in notes.
"""
function freefield_from_e11_csv(amp_csv::AbstractString,
                                phase_csv::AbstractString,
                                fuse::FuselageGeometry,
                                prop::PropellerPlacement,
                                spec::GridSpec=GridSpec();
                                bpf_Hz::Float64=200.0,
                                n_harmonics::Int=3,
                                anopp_spl_csv::Union{Nothing,String}=nothing,
                                broadband_clip_dB::Float64=10.0)
    amp = _read_csv_numeric(amp_csv)
    ph = _read_csv_numeric(phase_csv)
    anopp = anopp_spl_csv === nothing ? nothing : _read_csv_numeric(anopp_spl_csv)
    nH = min(n_harmonics, 3)
    k_max = spec.k_max
    line_amps = zeros(k_max, nH)
    line_phases = zeros(k_max, nH)
    n_clip = 0
    ks = Int.(round.(amp[:k]))
    for (i, k) in enumerate(ks)
        1 ≤ k ≤ k_max || continue
        for H in 1:nH
            key = H == 1 ? :SPL_H1_dB : H == 2 ? :SPL_H2_dB : :SPL_H3_dB
            spl = amp[key][i]
            if anopp !== nothing
                akey = key
                jA = findfirst(==(float(k)), anopp[:k])
                if jA !== nothing
                    spl_a = anopp[akey][jA]
                    # H≥3: use ANOPP Table 8 free-field (NASA E-16 path). Fig.E-11
                    # measured H3 floor is broadband-dominated off prop plane
                    # (CR-3813 App.E). H=1,2: clip only when measured−ANOPP > clip.
                    if H >= 3
                        spl = spl_a
                        n_clip += 1
                    elseif spl - spl_a > broadband_clip_dB
                        spl = spl_a
                        n_clip += 1
                    end
                end
            end
            line_amps[k, H] = spl_dB_to_peak_Pa(spl)
            pkey = H == 1 ? :phase_H1_deg : H == 2 ? :phase_H2_deg : :phase_H3_deg
            j = findfirst(==(float(k)), ph[:k])
            j === nothing && error("phase CSV missing k=$k")
            line_phases[k, H] = deg2rad(ph[pkey][j])
        end
    end
    pts = grid_points(fuse, prop, spec)
    ωH = [2π * H * bpf_Hz for H in 1:nH]
    amps, phases = extend_line_to_grid(line_amps, line_phases, pts; omega_H=ωH)
    notes = "SRC_TA: digitized Fig.E-11 measured SPL + ANOPP Table 8 phases; " *
            "grid extension V-ASSUMED. Digitization file: $(basename(amp_csv))."
    if anopp !== nothing
        notes *= " Broadband floor clip vs ANOPP where measured−ANOPP > $(broadband_clip_dB) dB (n_clip=$n_clip; V-ASSUMED)."
    end
    return FreeFieldHarmonicGrid(pts, collect(1:nH), amps, phases, :e11_digitized, notes, bpf_Hz)
end

"""Default data-dir paths relative to repo root (parent of PAIN.jl)."""
function default_e11_paths()
    root = normpath(joinpath(@__DIR__, "..", ".."))
    data = joinpath(root, "data", "cr3813")
    return (
        A = joinpath(data, "e11_freefield_measured_A.csv"),
        B = joinpath(data, "e11_freefield_measured_B.csv"),
        phases = joinpath(data, "anopp_table8_phases_deg.csv"),
        anopp_spl = joinpath(data, "anopp_table8_spl_dB.csv"),
    )
end
