# Unit tests: Phase 66 helpers (src/validation_case_iso66.jl) and the shared CCBlade / F1A steps
# (`_ccblade_setup`, `_f1a_harmonics` in src/propeller_ccblade.jl).
@testset "configs, spans, induction" begin
    c = PAIN._p66_hartzell(; V=30.0, rpm=3000.0, tc=0.1, B=4, nsec=7)
    @test c.propeller.num_blades == 4 && c.propeller.rpm == 3000 && c.operating_point.forward_speed_mps == 30
    @test length(c.propeller.radii_m) == 7 && issorted(c.propeller.radii_m) && c.propeller.thickness_over_chord == 0.1
    h0 = PAIN._p66_hartzell()
    @test c.propeller.chord_m[1] ≈ h0.propeller.chord_m[1] && c.propeller.chord_m[end] ≈ h0.propeller.chord_m[end]   # resampled span ends kept
    r9 = PAIN._p66_r996(; V=25.0)
    @test r9.operating_point.forward_speed_mps == 25 && r9.propeller.num_blades == 2
    dr = PAIN._p66_dr([0.2, 0.4, 0.8], 0.1, 1.0)
    @test dr ≈ [0.2, 0.3, 0.4] && sum(dr) ≈ 0.9                                     # midpoint interfaces, ends at R_hub/R_tip
    su = PAIN._ccblade_setup(h0)
    @test su.B == 3 && su.Vinf == 20 && length(su.outs) == length(su.r) && su.Ω ≈ 4000 * 2π / 60
    @test PAIN._ccblade_setup(PAIN._p66_hartzell(; V=0.0)).Vinf == 20.0                # static guard
    @test PAIN._ccblade_setup(PAIN._p66_hartzell(; V=0.0); allow_static=true).Vinf == 0.0
    o = su.outs[4]
    ind = PAIN._p66_raw_induction(o, su.r[4], su.chord[4], su.B)
    @test ind.a ≈ ind.k / (1 - ind.k)
    # momentum identity at a converged section (the 66a check, one station)
    @test su.B * o.Np ≈ 4π * su.r[4] * su.ρ * su.Vinf^2 * o.F * ind.a * (1 + ind.a) rtol = 1e-8
    @test PAIN._p66_af(0.0, 0, 0) == (0.0, 0.008) && PAIN._p66_af(0.1, 0, 0)[1] ≈ 2π * 0.1 - 4e-3
end
@testset "hand BEM section, Gutin / Garrick–Watkins reference" begin
    su = PAIN._ccblade_setup(PAIN._p66_hartzell(); af=PAIN._p66_af)
    for i in (2, 6, 10)
        h = PAIN._p66_hand_section(su.r[i], su.chord[i], su.theta[i], su.Rhub, su.Rtip, su.B, su.Vinf, su.Ω * su.r[i], su.ρ)
        @test h.Np ≈ su.outs[i].Np rtol = 1e-6
        @test abs(h.residual(su.outs[i].phi)) < 1e-10                                   # CCBlade's φ is a root of the hand equations
    end
    sst = PAIN._ccblade_setup(PAIN._p66_hartzell(; V=0.0); allow_static=true)
    # M_x = 0 is Gutin; in the rotor plane only torque radiates (thrust term × x/S₀ = 0)
    g90, _ = PAIN._p66_gw_peak(sst, 1, 0.0, 38.1)
    dr = PAIN._p66_dr(sst.r, sst.Rhub, sst.Rtip)
    hand = sqrt(2) * abs(sum((3 * sst.Ω / (2sqrt(2) * π * sst.c0 * 38.1)) * 3 * o.Tp * sst.r[i] * dr[i] * sst.c0 / (sst.Ω * sst.r[i]^2) *
                             PAIN._besselj_int(3, 3 * sst.Ω * sst.r[i] / sst.c0) for (i, o) in enumerate(sst.outs)))
    @test g90 ≈ hand rtol = 1e-12
    @test PAIN._p66_gw_peak(sst, 1, 20.0, 20.0)[1] != PAIN._p66_gw_peak(sst, 1, -20.0, 20.0)[1]   # thrust term: fore/aft differ
    @test PAIN._p66_gw_peak(sst, 1, 0.0, 38.1; Mx=0.0)[1] == g90
    r = PAIN._p66_result("UNIT", PAIN.ValidationTableRow[], PAIN.PlotSeries[], false, "x", (;))
    @test r.verdict == :not_met && startswith(r.reason, "criterion not met") && r.inputs_echo.date == "2026-10-24"
end
@testset "_f1a_harmonics equals the source path" begin
    cfg = PAIN._p66_hartzell(; V=0.0)
    su = PAIN._ccblade_setup(cfg; allow_static=true)
    obs = [PAIN.Observer([0.0, 38.1, 0.0], zeros(3), "o")]
    bpf = su.B * su.rpm / 60
    A, ph = PAIN._f1a_harmonics(su.rotor, su.sections, su.ops, su.outs, zeros(length(su.r)), obs;
                                period_src=2 * 2π / su.Ω, n_src=2 * su.B * 64, num_src_times=64, n_harmonics=2, bpf)
    s = PAIN.evaluate_propeller_source(cfg, obs; n_harmonics=2, num_src_times=64, allow_static=true)
    @test A ≈ s.amplitude rtol = 1e-12
    @test ph ≈ s.phase atol = 1e-12
end
