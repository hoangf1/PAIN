# Unit tests: src/printed_outputs.jl (Phase 64). Manual §5.4.3 tables: decompositions add up.
@testset "printed outputs (Manual §5.4.3)" begin
    rp = run_pain_pipeline(; source=:e11, n_harmonics=2, bpf_Hz=200.0, blocking=R2)
    inp = PAIN._with_fields(rp.inputs; q_max=2, q0_coupled=true)   # q = 0 coupled so its f̄′ parts are non-zero (default false since Phase 93)
    fc = 400.0
    lo, hi = fc * (1 - 0.116), fc * (1 + 0.116)
    @test PAIN.structural_modes_in_band(inp, fc) == count(m -> lo ≤ m.f_Hz ≤ hi, inp.structural.modes)
    parts, total = PAIN.modal_tone_contributions(inp, 1, 2π * 200.0)
    @test total ≈ PAIN.tone_mean_square_pressure(inp, 1, 2π * 200.0) rtol = 1e-12   # same Eq. (8) terms
    @test sum(p.share for p in parts) ≈ 1 && issorted([p.p2 for p in parts]; rev=true)
    out = PAIN.printed_outputs(inp; bpf_Hz=200.0, n_harmonics=2, broadband=false)
    @test all(r.f_prime ≈ r.f_shell + r.f_floor for r in out.coupling)              # f̄′ = shell + floor parts
    @test length(out.psi_G) == 2 * length(inp.structural.modes)
    @test count(r -> r.crossover, out.modes_per_band) ≤ 1
    @test out.tone_totals[1].p2 ≈ total && out.tone_totals[1].SPL_dB ≈ 10log10(total / 4e-10 + 1e-30)
    @test out.top5[1].p2 == parts[1].p2 && length(out.top5) ≤ 10
    @test length(out.surface_upper) == 160 * 2
    @test out.surface_upper[1].SPL_dB ≈ PAIN.peak_Pa_to_spl_dB(out.surface_upper[1].amplitude_Pa)
    io = IOBuffer(); PAIN._po_md_table(io, ["a", "b"], [(1, 2)])
    @test String(take!(io)) == "| a | b |\n| --- | --- |\n| 1 | 2 |\n\n"
    d = UNIT_OUT
    p = PAIN.write_printed_outputs_md(joinpath(d, "unit_printed_outputs.md"), out)
    md = read(p, String); rm(p)
    @test occursin("## Five largest modal contributions (Eq. 8)", md) && occursin("bpf_Hz** = 200.0", md)
    txt = PAIN.format_printed_outputs_text(out)
    @test occursin("--- Top-5 modal contributions ---", txt) && occursin("H1 #1", txt)
    j = PAIN.JSON3.read(PAIN.printed_outputs_gui_json(out))
    @test j.n_psi_G == length(out.psi_G) && j.n_surface_upper == 320 && length(j.tone_totals) == 2
end
