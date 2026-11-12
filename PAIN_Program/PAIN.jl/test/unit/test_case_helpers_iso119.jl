# Unit tests: src/cases_t1_appb.jl (Phase 119, the T1 family on CR-172428 App. B's printed field).
@testset "iso119: App. B field swapped into T1's inputs" begin
    r = PAIN.run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=PAIN.R2)
    inp = PAIN.t1_appb_inputs(r.inputs)
    f = PAIN.r172428_appb_field(4000; z_p=r.inputs.prop.z_p)
    # the field is App. B's as printed (both quarters, 19 lines), not T1's 10-line upper quarter
    @test size(inp.amplitudes) == (16, 19, 3) && size(r.inputs.amplitudes, 2) == 10
    @test inp.amplitudes == f.amps && inp.phases == f.phases && length(inp.pts) == 16 * 19
    # hand values from the printed table (appB_4000rpm_H1.csv: L = 1, k = 1 prints 94.6 dB, 13.0°; k = 2 prints 95.9 dB)
    @test inp.amplitudes[1, 1, 1] ≈ 20e-6 * sqrt(2) * 10^(94.6 / 20) rtol = 1e-9
    @test inp.phases[1, 1, 1] ≈ deg2rad(13.0)
    @test inp.amplitudes[2, 1, 1] ≈ 20e-6 * sqrt(2) * 10^(95.9 / 20) rtol = 1e-9
    @test inp.ΔA ≈ (π * 0.508 / 18)^2 rtol = 1e-12
    # everything but the field is T1's
    @test inp.structural === r.inputs.structural && inp.acoustic === r.inputs.acoustic && inp.fuse === r.inputs.fuse
    @test inp.sidewall === r.inputs.sidewall && inp.L_c == r.inputs.L_c && inp.c0 == r.inputs.c0
    # with its own inputs interior_spl reproduces the pipeline's T1 levels, so the swap is the only change
    @test PAIN.interior_spl(r.inputs; bpf_Hz=200.0, n_harmonics=3).harmonic_SPL_dB[1:3] ≈ r.spectrum.harmonic_SPL_dB[1:3] rtol = 1e-12
    # and the swap moves the levels (H3 by more than 5 dB)
    got = PAIN.interior_spl(inp; bpf_Hz=200.0, n_harmonics=3).harmonic_SPL_dB[1:3]
    @test abs(got[3] - r.spectrum.harmonic_SPL_dB[3]) > 5
    # _p119_result applies T1's gate to those levels
    res = PAIN._p119_result("X", r.inputs, "lab")
    @test res.inputs_echo.H1_H3 ≈ round.(got; digits=2) && length(res.table) == 6
    @test res.verdict === (res.inputs_echo.n_ok == 3 ? :met : :not_met) && res.label == "lab"
end
