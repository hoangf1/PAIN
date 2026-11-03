# Manual §5.4.3 printed outputs (phase 38h).
# Read-only tables from existing computations; no comparison criterion; no tuning.

const _PO_PREF_PA = 20e-6

"""Count structural modes with resonance inside the 1/3-octave about `fc` (list count, not density)."""
function structural_modes_in_band(inp::PainInputs, fc::Real; c_ω::Real=C_OMEGA_THIRD_OCTAVE)
    ω = 2π * fc
    lo = ω * (1 - c_ω / 2)
    hi = ω * (1 + c_ω / 2)
    n = 0
    for st in inp.structural.modes
        ωr = 2π * st.f_Hz
        (lo ≤ ωr ≤ hi) && (n += 1)
    end
    return n
end

"""
Per-(n,r) contributions to ⟨p²⟩_H, collected from `tone_mean_square_pressure` itself (Eq. 8; its `terms`, so every
option of the tone sum applies). Returns a Vector of NamedTuples `(q, i, r, f_n_Hz, f_r_Hz, η_n, η_r_pp, p2, share)`
sorted by `p2` descending, and the total. Does not alter any existing result.
"""
function modal_tone_contributions(inp::PainInputs, H::Int, ωH::Float64;
                                  q_max::Union{Nothing,Int}=nothing,
                                  η_r_cap::Union{Nothing,Float64}=nothing)
    rows = NamedTuple[]
    tone_mean_square_pressure(inp, H, ωH; q_max, η_r_cap, terms=rows)
    filter!(t -> t.p2 != 0, rows)
    sort!(rows; by=x -> x.p2, rev=true)
    total = sum((t.p2 for t in rows); init=0.0)
    denom = total > 0 ? total : 1.0
    return [merge(t, (; share=t.p2 / denom)) for t in rows], total
end

"""
    printed_outputs(inp; bpf_Hz, n_harmonics=…, …) -> NamedTuple

Manual §5.4.3 tables the program can compute now from existing APIs. Returns a
NamedTuple of tables; does not change any existing result. No comparison criterion.
"""
function printed_outputs(inp::PainInputs;
                         bpf_Hz::Float64,
                         n_harmonics::Int=min(10, size(inp.amplitudes, 3)),
                         broadband::Bool=true,
                         tone_model::Symbol=:eq8,
                         broadband_model::Symbol=:surrogate,
                         η_r_cap::Union{Nothing,Float64}=nothing,
                         q_max::Union{Nothing,Int}=nothing,
                         c_ω::Real=C_OMEGA_THIRD_OCTAVE)
    nH = min(n_harmonics, size(inp.amplitudes, 3))
    bands = resolve_bands(inp)
    xover = acoustic_crossover_band(inp; bands, c_ω)
    modes_per_band = NamedTuple[]
    for (bi, fc) in enumerate(bands)
        n_ac = acoustic_modes_in_band(inp, fc; c_ω)
        n_st = structural_modes_in_band(inp, fc; c_ω)
        is_xover = isfinite(xover.fc_Hz) && bi == xover.band_index
        push!(modes_per_band, (; fc_Hz=float(fc), n_acoustic=n_ac, n_structural=n_st,
                                 crossover=is_xover))
    end

    # Coupling f′(n,r) at BPF (τ_t at ω = 2π·bpf); shell / floor integrals as Manual item 6
    ω_bpf = 2π * bpf_Hz
    τ_t_bpf = sidewall_tau(inp, ω_bpf)
    fuse = inp.fuse
    a = fuse.a
    θ0 = deg2rad(fuse.theta0_deg)
    Lp = 2a * sin(θ0)
    denom_area = Lp + 2a * (π - θ0)
    qtop_coup = something(q_max, inp.q_max, axial_truncation(ω_bpf, inp.L_c, inp.c_int))
    coupling = NamedTuple[]
    for q in 0:qtop_coup, ac in inp.acoustic.modes
        for st in inp.structural.modes
            Is = coupling_shell_integral(ac, st, a)
            Ip = inp.floor_sign * coupling_floor_integral(ac, st, a, Lp)   # Eq. (52) floor sign as the inputs (phase 61)
            ax = axial_coupling(q, st.M_axial; L=fuse.L, L_c=inp.L_c, d=inp.d)
            f_shell = ax * sqrt(τ_t_bpf) * Is / denom_area
            f_floor = ax * Ip / denom_area          # floor term sign as in coupling_factor (44f)
            f = coupling_factor(ac, st, inp; τ_t=τ_t_bpf, q)
            (f == 0 && f_shell == 0 && f_floor == 0) && continue
            push!(coupling, (; q, i=ac.index, r=st.index, M=st.M_axial,
                               f_prime=f, f_shell, f_floor))
        end
    end

    # Ψ_G(r,H) for each harmonic
    psi_G = NamedTuple[]
    for H in 1:nH
        for st in inp.structural.modes
            Ψ = generalized_force(st, H, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA)
            push!(psi_G, (; H, r=st.index, f_r_Hz=st.f_Hz, Ψ_G=Ψ))
        end
    end

    # Five largest modal contributions per tone (Eq. 8 path)
    top5 = NamedTuple[]
    tone_totals = NamedTuple[]
    for H in 1:nH
        ωH = 2π * H * bpf_Hz
        parts, total = modal_tone_contributions(inp, H, ωH; q_max, η_r_cap)
        p2_ref = tone_mean_square_pressure(inp, H, ωH; q_max, η_r_cap)
        pair = tone_mean_square_pressure_pair(inp, H, ωH; tone_model, η_r_cap)
        spl = 10 * log10(max(p2_ref, 0.0) / _PO_PREF_PA^2 + 1e-30)
        push!(tone_totals, (; H, f_Hz=H * bpf_Hz, p2=p2_ref, SPL_dB=spl,
                              p2_eq8=pair.p2_eq8, p2_eq15_16=pair.p2_eq15_16,
                              model=String(pair.model)))
        for (rank, row) in enumerate(Iterators.take(parts, 5))
            push!(top5, (; H, rank, q=row.q, i=row.i, r=row.r,
                           f_n_Hz=row.f_n_Hz, f_r_Hz=row.f_r_Hz,
                           p2=row.p2, share=row.share))
        end
    end

    spec = interior_spl(inp; bpf_Hz, n_harmonics=nH, broadband, tone_model,
                        broadband_model, η_r_cap)
    third_rows = NamedTuple[(; fc_Hz=fc, SPL_dB=spl)
                            for (fc, spl) in sort!(collect(spec.third_octave_SPL_dB); by=first)]
    harmonic_rows = NamedTuple[(; H, f_Hz=H * bpf_Hz, SPL_dB=spec.harmonic_SPL_dB[H])
                               for H in 1:length(spec.harmonic_SPL_dB)]

    # Surface pressures: upper 160-point grid as used; lower quarter not adopted (I-18)
    surface_upper = NamedTuple[]
    for p in inp.pts
        for H in 1:nH
            A = inp.amplitudes[p.k, p.ell, H]
            ϕ = inp.phases[p.k, p.ell, H]
            push!(surface_upper, (; H, k=p.k, ell=p.ell, z=p.z, theta_deg=p.theta_deg,
                                    amplitude_Pa=A, SPL_dB=peak_Pa_to_spl_dB(A),
                                    phase_deg=rad2deg(ϕ)))
        end
    end
    surface_lower_note = "not computed — lower-quarter grid not adopted (I-18)"

    omissions = [
        "§5.4.3 item 1 (band-averaged loss factors η_n, η_struc input, η_rad, η_r′): omitted — not required by the 38h author plan; available via existing loss-factor APIs if needed later.",
        "§5.4.3 item 2 (trim data / τ_t dB / admittances): omitted — trim stacks already echoed in pipeline notes; no separate print table in this step.",
        "§5.4.3 items 4–5 (full structural / acoustic mode dumps: Cin, ns, masses, j²_rev, ε_n, …): omitted — mode lists live in CYL2D/MRP outputs; 38h prints band counts, coupling, Ψ_G, and top-5 tone pairs instead.",
    ]

    return (;
        bpf_Hz,
        n_harmonics=nH,
        crossover_Hz=xover.fc_Hz,
        modes_per_band,
        coupling,
        psi_G,
        top5,
        tone_totals,
        harmonic_SPL=harmonic_rows,
        third_octave_SPL=third_rows,
        spectrum_notes=spec.notes,
        surface_upper,
        surface_lower_note,
        omissions,
    )
end

function _po_md_table(io::IO, headers::Vector{String}, rows)
    println(io, "| ", join(headers, " | "), " |")
    println(io, "| ", join(fill("---", length(headers)), " | "), " |")
    for r in rows
        println(io, "| ", join(string.(r), " | "), " |")
    end
    println(io)
end

"""
    write_printed_outputs_md(path, out; title=…, provenance=nothing)

Write the §5.4.3 tables from `printed_outputs` to a markdown report file.
Optional `provenance` (phase 29b/29c) adds NASA-default header labels and an
input/value/tag table; omitted for :e11/:synthetic so existing reports stay unchanged.
"""
function write_printed_outputs_md(path::AbstractString, out;
                                  title::AbstractString="Printed outputs (Manual §5.4.3)",
                                  provenance=nothing)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# $title")
        println(io)
        if provenance !== nothing
            labels = provenance_header_labels(provenance)
            if !isempty(labels.uses_defaults)
                println(io, "**$(labels.uses_defaults)**")
                println(io)
            end
            if !isempty(labels.nasa_article)
                println(io, "**$(labels.nasa_article)**")
                println(io)
            end
        end
        println(io, "**bpf_Hz** = $(out.bpf_Hz); **n_harmonics** = $(out.n_harmonics); ",
                "**crossover_Hz** = $(out.crossover_Hz).")
        println(io)
        println(io, "Read-only tables from existing computations (phase 38h). No comparison criterion.")
        println(io)
        if provenance !== nothing && !isempty(provenance.inputs)
            println(io, "## Input provenance (phase 29c)")
            println(io)
            _po_md_table(io, ["input", "value", "tag"],
                         [(r.name, r.value, r.tag) for r in provenance.inputs])
        end

        println(io, "## Modes per 1/3-octave band")
        println(io)
        _po_md_table(io, ["fc_Hz", "n_acoustic", "n_structural", "crossover"],
                     [(round(r.fc_Hz; digits=1), r.n_acoustic, r.n_structural,
                       r.crossover ? "yes" : "") for r in out.modes_per_band])

        println(io, "## Acoustic/structural coupling f′(n,r)")
        println(io)
        println(io, "τ_t evaluated at BPF. Shell / floor parts as Manual item 6.")
        println(io)
        _po_md_table(io, ["q", "i", "r", "M", "f_prime", "f_shell", "f_floor"],
                     [(r.q, r.i, r.r, r.M,
                       round(r.f_prime; sigdigits=6),
                       round(r.f_shell; sigdigits=6),
                       round(r.f_floor; sigdigits=6)) for r in out.coupling])

        println(io, "## Propeller generalized forces Ψ_G(r,H)")
        println(io)
        _po_md_table(io, ["H", "r", "f_r_Hz", "Ψ_G"],
                     [(r.H, r.r, round(r.f_r_Hz; digits=2),
                       round(r.Ψ_G; sigdigits=6)) for r in out.psi_G])

        println(io, "## Five largest modal contributions (Eq. 8)")
        println(io)
        _po_md_table(io, ["H", "rank", "q", "i", "r", "f_n_Hz", "f_r_Hz", "p2", "share"],
                     [(r.H, r.rank, r.q, r.i, r.r,
                       round(r.f_n_Hz; digits=2), round(r.f_r_Hz; digits=2),
                       round(r.p2; sigdigits=6), round(r.share; digits=6)) for r in out.top5])

        println(io, "## Tone transmission (interior space-averaged MSP)")
        println(io)
        _po_md_table(io, ["H", "f_Hz", "SPL_dB", "p2", "p2_eq8", "p2_eq15_16", "model"],
                     [(r.H, round(r.f_Hz; digits=1), round(r.SPL_dB; digits=2),
                       round(r.p2; sigdigits=6), round(r.p2_eq8; sigdigits=6),
                       round(r.p2_eq15_16; sigdigits=6), r.model) for r in out.tone_totals])

        println(io, "## Interior harmonic SPL")
        println(io)
        _po_md_table(io, ["H", "f_Hz", "SPL_dB"],
                     [(r.H, round(r.f_Hz; digits=1), round(r.SPL_dB; digits=2))
                      for r in out.harmonic_SPL])

        println(io, "## Interior 1/3-octave SPL")
        println(io)
        if isempty(out.third_octave_SPL)
            println(io, "(no broadband bands)")
            println(io)
        else
            _po_md_table(io, ["fc_Hz", "SPL_dB"],
                         [(round(r.fc_Hz; digits=1), round(r.SPL_dB; digits=2))
                          for r in out.third_octave_SPL])
        end

        println(io, "## Propeller pressure amplitude and phase (upper quarter)")
        println(io)
        println(io, "Upper 160-point grid as used. Lower quarter: **$(out.surface_lower_note)**.")
        println(io)
        _po_md_table(io, ["H", "k", "ell", "z_m", "theta_deg", "SPL_dB", "phase_deg"],
                     [(r.H, r.k, r.ell, round(r.z; digits=4), round(r.theta_deg; digits=2),
                       round(r.SPL_dB; digits=2), round(r.phase_deg; digits=2))
                      for r in out.surface_upper])

        println(io, "## Manual outputs omitted")
        println(io)
        for line in out.omissions
            println(io, "- $line")
        end
        println(io)
        if !isempty(out.spectrum_notes)
            println(io, "## Spectrum notes")
            println(io)
            println(io, out.spectrum_notes)
            println(io)
        end
    end
    return path
end

"""Format printed-outputs tables as plain text for the GUI page."""
function format_printed_outputs_text(out)
    io = IOBuffer()
    println(io, "bpf=$(out.bpf_Hz) Hz  nH=$(out.n_harmonics)  crossover=$(out.crossover_Hz) Hz")
    println(io)
    println(io, "--- Modes per band ---")
    for r in out.modes_per_band
        flag = r.crossover ? "  [crossover]" : ""
        println(io, "fc=$(round(r.fc_Hz; digits=1))  nac=$(r.n_acoustic)  nst=$(r.n_structural)$flag")
    end
    println(io)
    println(io, "--- Top-5 modal contributions ---")
    for r in out.top5
        println(io, "H$(r.H) #$(r.rank)  n=(q=$(r.q),i=$(r.i)) r=$(r.r)  ",
                "fn=$(round(r.f_n_Hz; digits=1)) fr=$(round(r.f_r_Hz; digits=1))  ",
                "share=$(round(100 * r.share; digits=2))%")
    end
    println(io)
    println(io, "--- Tone SPL ---")
    for r in out.tone_totals
        println(io, "H$(r.H)  $(round(r.f_Hz; digits=1)) Hz  $(round(r.SPL_dB; digits=2)) dB  model=$(r.model)")
    end
    println(io)
    println(io, "--- 1/3-octave SPL (first 12) ---")
    for r in Iterators.take(out.third_octave_SPL, 12)
        println(io, "fc=$(round(r.fc_Hz; digits=1))  $(round(r.SPL_dB; digits=2)) dB")
    end
    length(out.third_octave_SPL) > 12 && println(io, "… ($(length(out.third_octave_SPL)) bands)")
    println(io)
    println(io, "--- Coupling (first 20 non-zero) ---")
    for r in Iterators.take(out.coupling, 20)
        println(io, "q=$(r.q) i=$(r.i) r=$(r.r)  f'=$(round(r.f_prime; sigdigits=4))")
    end
    length(out.coupling) > 20 && println(io, "… ($(length(out.coupling)) pairs)")
    println(io)
    println(io, "--- Ψ_G (first 16) ---")
    for r in Iterators.take(out.psi_G, 16)
        println(io, "H$(r.H) r=$(r.r)  Ψ_G=$(round(r.Ψ_G; sigdigits=4))")
    end
    length(out.psi_G) > 16 && println(io, "… ($(length(out.psi_G)) rows)")
    println(io)
    println(io, "--- Surface pressures ---")
    println(io, "upper grid points×harmonics = $(length(out.surface_upper))")
    println(io, "lower quarter: $(out.surface_lower_note)")
    println(io)
    println(io, "--- Omissions ---")
    for line in out.omissions
        println(io, "• $line")
    end
    return String(take!(io))
end

"""Compact JSON for GUI Observables / smoke checks (no huge surface table)."""
function printed_outputs_gui_json(out)
    top5 = [Dict(
        "H" => r.H, "rank" => r.rank, "q" => r.q, "i" => r.i, "r" => r.r,
        "f_n_Hz" => r.f_n_Hz, "f_r_Hz" => r.f_r_Hz, "p2" => r.p2, "share" => r.share,
    ) for r in out.top5]
    modes = [Dict(
        "fc_Hz" => r.fc_Hz, "n_acoustic" => r.n_acoustic,
        "n_structural" => r.n_structural, "crossover" => r.crossover,
    ) for r in out.modes_per_band]
    tones = [Dict(
        "H" => r.H, "f_Hz" => r.f_Hz, "SPL_dB" => r.SPL_dB, "p2" => r.p2, "model" => r.model,
    ) for r in out.tone_totals]
    return JSON3.write(Dict(
        "bpf_Hz" => out.bpf_Hz,
        "n_harmonics" => out.n_harmonics,
        "crossover_Hz" => out.crossover_Hz,
        "modes_per_band" => modes,
        "top5" => top5,
        "tone_totals" => tones,
        "n_coupling" => length(out.coupling),
        "n_psi_G" => length(out.psi_G),
        "n_surface_upper" => length(out.surface_upper),
        "surface_lower_note" => out.surface_lower_note,
        "n_third_octave" => length(out.third_octave_SPL),
    ))
end
