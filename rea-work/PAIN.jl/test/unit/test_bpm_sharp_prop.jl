# Unit tests: src/bpm_airfoil_noise.jl, src/sharp_bridges.jl, src/prop_broadband.jl (Phase 64).
@testset "BPM spectral shapes and constants" begin
    f = PAIN.bpm_frequencies()
    @test length(f) == 27 && f[1] == 100 && f[end] == 40000 && issorted(f)
    for g in (PAIN._bpm_amin, PAIN._bpm_amax, PAIN._bpm_bmin, PAIN._bpm_bmax)
        @test g(0.0) ≈ 0 atol = 1e-3                                                         # peak at St = St_peak
    end
    @test PAIN._bpm_amin(0.204 - 1e-9) ≈ PAIN._bpm_amin(0.204 + 1e-9) atol = 0.02              # branches join
    @test PAIN._bpm_amax(0.321 - 1e-9) ≈ PAIN._bpm_amax(0.321 + 1e-9) atol = 0.02
    @test PAIN._bpm_bmin(0.145 - 1e-9) ≈ PAIN._bpm_bmin(0.145 + 1e-9) atol = 0.02
    @test PAIN._bpm_bmax(0.187 - 1e-9) ≈ PAIN._bpm_bmax(0.187 + 1e-9) atol = 0.02
    @test PAIN._bpm_a0(5e4) == 0.57 && PAIN._bpm_a0(1e6) == 1.13
    @test PAIN._bpm_a0(8.57e5) ≈ 1.13 atol = 0.01
    @test PAIN._bpm_b0(5e4) == 0.30 && PAIN._bpm_b0(1e6) == 0.56
    # by construction of AR(a0), A = −20 dB at |log St ratio| = a0 (RP-1218 Eq. 38)
    for Rc in (2e5, 6e5, 1.2e6)
        @test PAIN._bpm_A(10^PAIN._bpm_a0(Rc), Rc) ≈ -20 atol = 1e-9
        @test PAIN._bpm_B(10^PAIN._bpm_b0(Rc), Rc) ≈ -20 atol = 1e-9
        @test PAIN._bpm_A(1.0, Rc) ≈ 0 atol = 1e-3
    end
    @test PAIN._bpm_dB(0.0) == -100.0 && PAIN._bpm_dB(1e6) ≈ 60.0
end
@testset "bpm_boundary_layer / bpm_directivity" begin
    u = PAIN.bpm_boundary_layer(0.3048, 71.3, 0.0)
    t = PAIN.bpm_boundary_layer(0.3048, 71.3, 0.0; trip=:tripped)
    l = PAIN.bpm_boundary_layer(0.3048, 71.3, 0.0; trip=:light)
    @test u.Rc ≈ 71.3 * 0.3048 / 1.4529e-5
    lr = log10(u.Rc)
    @test u.δs_p ≈ 0.3048 * 10^(3.0187 - 1.5397lr + 0.1059lr^2) rtol = 1e-12    # Eq. (6), α = 0
    @test u.δs_s == u.δs_p                                                       # α = 0: both sides equal
    @test l.δs_p ≈ 0.6 * t.δs_p rtol = 1e-12                                     # light trip (code ITRIP = 2)
    a5 = PAIN.bpm_boundary_layer(0.3048, 71.3, 5.0)
    @test a5.δs_s > u.δs_s > a5.δs_p                                             # suction side thickens with α
    Dh, Dl = PAIN.bpm_directivity(90.0, 90.0, 0.2)
    @test Dh ≈ 1.0
    @test Dl ≈ 1.0
    @test PAIN.bpm_directivity(0.0, 90.0, 0.2)[1] ≈ 0 atol = 1e-14
    @test PAIN.bpm_directivity(90.0, 0.0, 0.2) == (0.0, 0.0)                     # no radiation along the span
end
@testset "bpm_tbl_te / bpm_lbl_vs / bpm_tip / bpm_spectrum against RP-1218 Tables D2, D3" begin
    d2 = PAIN._read_csv_numeric_nan(PAIN._data_path("rp1218", "rp1218_tableD2.csv"))
    seg = (; c=0.3048, L=0.4572, r=1.22, Θ=90.0, Φ=90.0, α=1.516, U=71.3, trip=:untripped)
    for i in (1, 10, 20)
        f = d2[:f_Hz][i]
        t = PAIN.bpm_tbl_te(f, seg.c, seg.L, seg.r, seg.Θ, seg.Φ, seg.α, seg.U)
        @test t.p ≈ d2[:tbl_pressure_dB][i] atol = 0.05
        @test t.s ≈ d2[:tbl_suction_dB][i] atol = 0.05
        @test PAIN.bpm_lbl_vs(f, seg.c, seg.L, seg.r, seg.Θ, seg.Φ, seg.α, seg.U) ≈ d2[:laminar_dB][i] atol = 0.05
    end
    s = PAIN.bpm_spectrum([seg]; lbl=true)
    @test maximum(abs.(s.total .- d2[:total_dB])) ≤ 0.05
    d3 = PAIN._read_csv_numeric_nan(PAIN._data_path("rp1218", "rp1218_tableD3.csv"))
    @test PAIN.bpm_tip(1000.0, 0.1524, 1.22, 90.0, 90.0, 7.7, 71.3) ≈ d3[:tip_dB][findfirst(==(1000.0), d3[:f_Hz])] atol = 0.25
    # span scaling: one segment of span 2L equals two segments of span L
    s2 = PAIN.bpm_spectrum([merge(seg, (; L=2seg.L))]); s11 = PAIN.bpm_spectrum([seg, seg])
    @test maximum(abs.(s2.total .- s11.total)) ≤ 1e-9
end
@testset "Sharp double panel (CR-172490)" begin
    @test PAIN.sharp_mass_law_TL(10.0, 1000.0; ρc1=415.0, ρc2=415.0) ≈ 80 - 10log10(415^2) + 10 atol = 1e-12
    @test PAIN.sharp_f0(4.448, 4.448, 0.0826) ≈ 140.1 atol = 0.1            # Panel D, stated 142 Hz
    @test PAIN.sharp_fc(0.0016, 5350.0) ≈ 343^2 * sqrt(12) / (2π * 0.0016 * 5350) rtol = 1e-12
    @test PAIN.sharp_dTL_line(0.2, 10000.0) ≈ 10log10(2000) - 25
    @test PAIN.sharp_dTL_point(0.5, 10000.0) ≈ 20log10(5000) - 51
    m, d = 4.448, 0.0826
    f0 = PAIN.sharp_f0(m, m, d)
    @test PAIN.sharp_double_panel_TL(m, m, d, f0 / 2; ΔTL_M=12.0) ≈ PAIN.sharp_mass_law_TL(2m, f0 / 2; ρc1=1.21 * 343, ρc2=1.21 * 343)
    @test PAIN.sharp_double_panel_TL(m, m, d, 2 * f0; ΔTL_M=40.0) - PAIN.sharp_double_panel_TL(m, m, d, f0 * (1 + 1e-12); ΔTL_M=40.0) ≈ 18 atol = 1e-6
    inp = PAIN.r172428_inputs(4000)
    b = PAIN.bridge_tau(inp, 1000.0)
    @test b.m_t ≈ 1.456 && b.τ_B > 0 && b.ΔTL_pt > b.ΔTL_ln
end
@testset "propeller broadband (48b)" begin
    cfg = PAIN.p48_propeller_cfg(5000)
    @test cfg.propeller.num_blades == 3 && cfg.propeller.tip_radius_m ≈ 0.381 && cfg.propeller.rpm == 5000
    @test cfg.operating_point.forward_speed_mps == 23.8
    af = PAIN._p48_af()
    s16 = PAIN.propeller_broadband_spectrum(cfg, af, (0.457, 0.0, -0.254); freqs=[1000.0])
    s32 = PAIN.propeller_broadband_spectrum(cfg, af, (0.457, 0.0, -0.254); freqs=[1000.0], nψ=32)
    @test isfinite(s16.total[1]) && abs(s16.total[1] - s32.total[1]) ≤ 0.5     # azimuth sampling converged
    far = PAIN.propeller_broadband_spectrum(cfg, af, (20.0, 0.0, 0.0); freqs=[1000.0])
    far2 = PAIN.propeller_broadband_spectrum(cfg, af, (40.0, 0.0, 0.0); freqs=[1000.0])
    @test far.total[1] - far2.total[1] ≈ 20log10(2) atol = 0.1                   # spherical spreading in the far field
end
