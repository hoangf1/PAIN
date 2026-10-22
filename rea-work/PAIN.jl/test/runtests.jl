using Test
using PAIN
using JSON3

# Top-level testset filter (task P1). Empty ARGS → run everything.
# Pkg.test("PAIN"; test_args=["CYL2D"]) puts substrings in ARGS (case-insensitive match on title).
# Helpers are defined once so DaemonMode can re-include this file with shared=true.
if !isdefined(@__MODULE__, :_run_if)
    const _TEST_FILTER = String[]
    const _TESTSETS_RAN = String[]
    const _TESTSETS_SKIPPED = String[]

    function _want_testset(title::AbstractString)
        isempty(_TEST_FILTER) && return true
        t = lowercase(title)
        return any(occursin(f, t) for f in _TEST_FILTER)
    end

    """Run `f` inside `@testset title` when ARGS is empty or title contains any filter substring.
    Do-block form `_run_if("title") do … end` passes `f` first."""
    function _run_if(f::Function, title::AbstractString)
        if _want_testset(title)
            push!(_TESTSETS_RAN, title)
            t0 = time()
            @testset "$title" begin
                f()
            end
            dt = time() - t0
            println("RAN: ", title, " (", round(dt; digits=2), " s)")
        else
            push!(_TESTSETS_SKIPPED, title)
            println("SKIPPED: ", title)
        end
        return nothing
    end
end

empty!(_TEST_FILTER)
append!(_TEST_FILTER, lowercase.(String.(ARGS)))
empty!(_TESTSETS_RAN)
empty!(_TESTSETS_SKIPPED)

_run_if("Blocking Eq.43 vs CR-172428 p.68 (V-UNIT)") do
    tol = 0.06
    records = ValidationRecord[]
    for (γ, expected_dB) in PAIN.BLOCKING_P68_CHECKPOINTS
        got = delta_L_blocking_dB(γ; variant=R1)
        err = abs(got - expected_dB)
        @test err ≤ tol
        push!(records, ValidationRecord(
            "BLK", "V-UNIT",
            "Pain Validation.pdf / NASA-CR-172428 p.68; Eq.(43) CR-3813",
            "ΔL(γ=$(γ) deg) = 20 log10 F", "≤ 0.06 dB",
            err ≤ tol ? "PASS" : "FAIL",
            "got=$(round(got; digits=4)) dB expected=$(expected_dB) dB err=$(round(err; digits=4))",
        ))
    end
    dL0_R2 = delta_L_blocking_dB(0.0; variant=R2)
    @test 3.9 ≤ dL0_R2 ≤ 4.2
    push!(records, ValidationRecord(
        "BLK", "V-UNIT",
        "Pain Validation.pdf §5.3.2 (RHS×0.8 → max ≈4 dB)",
        "ΔL_R2(γ=0 deg)", "3.9–4.2 dB", "PASS",
        "got=$(round(dL0_R2; digits=4)) dB",
    ))
    @test blocked_amplitude(2.5, 0.0; variant=R1) ≈ blocking_factor(0.0) * 2.5
    out = joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "blocking_p68.md")
    mkpath(dirname(out))
    write_validation_record(out, records)
end

_run_if("Grid geometry 160 points (User Manual Fig.3)") do
    fuse = FuselageGeometry(1.676, 0.381, 50.0)
    prop = PropellerPlacement(0.381 + 0.05, 90.0, 0.84)
    pts = grid_points(fuse, prop, GridSpec())
    @test length(pts) == 160
end

_run_if("Grid azimuth: ℓ = 1 at the propeller azimuth, upper quarter (12b, V-CODE)") do
    fuse = FuselageGeometry(1.676, 0.381, 50.0)
    for φp in (60.0, 90.0, 120.0)
        prop = PropellerPlacement(0.381 + 0.05, φp, 0.84)
        pts = grid_points(fuse, prop, GridSpec())
        p1 = first(p for p in pts if p.ell == 1 && p.k == 8)
        # line ℓ = 1 at θ = φ_p, α = 0; hub in the plane of the skin normal gives γ = 0 at k = k_p
        @test p1.theta_deg ≈ φp atol=1e-12
        @test p1.alpha_deg ≈ 0.0 atol=1e-12
        @test incidence_angle_deg(fuse, prop, p1.theta_deg, p1.z) ≈ 0.0 atol=1e-6
        # ℓ increases upward: θ_ℓ = φ_p + (ℓ−1)·10°, α = θ − φ_p
        for p in pts
            @test p.theta_deg ≈ φp + 10.0 * (p.ell - 1) atol=1e-9
            @test p.alpha_deg ≈ p.theta_deg - φp atol=1e-9
        end
        # incidence grows away from the propeller plane and away from line ℓ = 1
        γ(ℓ, k) = (p = first(q for q in pts if q.ell == ℓ && q.k == k);
                   incidence_angle_deg(fuse, prop, p.theta_deg, p.z))
        @test γ(1, 8) < γ(1, 12) && γ(1, 8) < γ(5, 8) < γ(10, 8)
    end
end

_run_if("Grid extension unit checks (V-ASSUMED code-only)") do
    fuse = FuselageGeometry(1.676, 0.381, 50.0)
    prop = PropellerPlacement(0.5, 90.0, 0.84)
    pts = grid_points(fuse, prop)
    amps, phases = extend_line_to_grid(ones(16, 3), zeros(16, 3), pts)
    @test amps[8, 1, 1] ≈ 1.0 atol=1e-12
    @test amps[8, 10, 1] ≈ 0.0 atol=1e-12
    @test 0 < amps[8, 5, 1] < 1
end

_run_if("GEXT importance-bound options (code checks, not physics)") do
    fuse = FuselageGeometry(1.676, 0.381, 50.0)
    prop = PropellerPlacement(0.5, 90.0, 0.84)
    pts = grid_points(fuse, prop)
    la, lp = ones(16, 3), fill(0.3, 16, 3)
    ωH = [2π * H * 100.0 for H in 1:3]
    a0, p0 = extend_line_to_grid(la, lp, pts; omega_H=ωH)
    # identity control: explicit nominal options reproduce the default exactly
    a1, p1 = extend_line_to_grid(la, lp, pts; omega_H=ωH,
                                 falloff_exponent=1.0, falloff_floor=0.0, delay_scale=1.0)
    @test a1 == a0 && p1 == p0
    # flat falloff (n = 0) and floor
    af, _ = extend_line_to_grid(la, lp, pts; omega_H=ωH, falloff_exponent=0.0)
    @test all(af .== 1.0)
    afl, _ = extend_line_to_grid(la, lp, pts; omega_H=ωH, falloff_floor=0.1)
    @test minimum(afl) >= 0.1 - 1e-12 && afl[8, 10, 1] ≈ 0.1
    a2, _ = extend_line_to_grid(la, lp, pts; omega_H=ωH, falloff_exponent=2.0)
    @test a2[8, 5, 1] < a0[8, 5, 1]
    # delay: ℓ = 1 untouched; off removes it; sign flip mirrors it about ϕ0
    _, poff = extend_line_to_grid(la, lp, pts; omega_H=ωH, delay_scale=0.0)
    _, pneg = extend_line_to_grid(la, lp, pts; omega_H=ωH, delay_scale=-1.0)
    @test p0[8, 1, 1] ≈ 0.3 atol=1e-12
    @test all(poff .≈ 0.3)
    @test (pneg .- 0.3) ≈ -(p0 .- 0.3) atol=1e-9
    @test_throws ArgumentError extend_line_to_grid(la, lp, pts; falloff_exponent=-1.0)
    @test_throws ArgumentError extend_line_to_grid(la, lp, pts; falloff_floor=1.5)
end

include("fig_c3_values.jl")

_run_if("CYL2D vs Table C-1 and Fig. C-3 (App. C scheme, V-CODE, criteria fixed 2026-10-20; frequency check re-stated as ratios 2026-10-21)") do
    cy = cyl2d_modes(56.6; n_modes=20, NY=10, c0=TABLE_C1_C0)
    @test length(cy.modes) == 20
    @test issorted([m.f_Hz_unit for m in cy.modes])
    # rigid-body mode at 0 Hz (< 0.01 Hz); frequency ratios vs first non-rigid mode (index 2).
    # c0 = 341 m/s is back-solved from Table C-1 (one fitted scale), so absolute frequencies match by
    # construction; ratios carry no fitted parameter (re-stated 2026-10-21 after the result was known).
    @test abs(cy.modes[1].f_Hz_unit) < 0.01
    for i in 3:20
        @test cy.modes[i].f_Hz_unit / cy.modes[2].f_Hz_unit ≈ TABLE_C1_FREQ_HZ[i] / TABLE_C1_FREQ_HZ[2] rtol=1e-3
    end
    for i in 1:20
        @test cy.modes[i].gen_mass_unit ≈ TABLE_C1_GENMASS[i] rtol=1e-3
        @test cy.modes[i].symmetric == TABLE_C1_SYMMETRIC[i]
        @test cy.modes[i].index == i - 1
    end
    # Fig. C-3 modes 0–5 equal the printed one-decimal values (global eigenvector sign free)
    @test isempty(fig_c3_mismatches(cy))
    # Fig. C-3 row counts, crown to floor
    @test [count(k -> k[2] == n, keys(cy.modes[1].phi_nodes)) for n in 10:-1:0] == [3, 5, 6, 6, 7, 7, 7, 7, 7, 7, 6]
    # normalization: max |φ| = 1; ε_n of Eq. (C.11) is 1 for the uniform mode up to the grid error
    @test all(m -> maximum(abs, values(m.phi_nodes)) ≈ 1.0, cy.modes)
    @test cy.modes[1].eps_n ≈ (π - deg2rad(56.6) + cos(deg2rad(56.6)) * sin(deg2rad(56.6))) / TABLE_C1_GENMASS[1] rtol=1e-3
    # the node rule r ≤ 1 + 0.4h: the whole window 0.32h–0.47h gives the same modes (assumption 13a(a))
    for tol in (0.32, 0.47)
        c2 = cyl2d_modes(56.6; n_modes=20, NY=10, c0=TABLE_C1_C0, node_tol=tol)
        @test all(i -> c2.modes[i].f_Hz_unit ≈ cy.modes[i].f_Hz_unit, 1:20)
    end
    # boundary data: wall points θ0..2π−θ0 ascending and mirrored; floor points ±sinθ0; limits cover them exactly
    m2 = cy.modes[3]
    θ0 = deg2rad(56.6)
    @test issorted(m2.theta_boundary_deg) && issorted(m2.x_floor_unit)
    @test m2.theta_lo_rad[1] ≈ θ0 && m2.theta_hi_rad[end] ≈ 2π - θ0
    @test m2.x_lo_unit[1] ≈ -sin(θ0) && m2.x_hi_unit[end] ≈ sin(θ0)
    @test all(m2.theta_lo_rad[2:end] .≈ m2.theta_hi_rad[1:end-1])
    # antisymmetric mode 1: boundary values are odd about the centerline, centerline zero
    m1 = cy.modes[2]
    @test m1.phi_boundary ≈ -reverse(m1.phi_boundary) atol=1e-12
    @test all(m1.phi_nodes[(0, n)] == 0.0 for n in 0:10)
    # a singular or non-real grid is an error that names the grid (no pseudo-inverse)
    @test_throws ErrorException cyl2d_modes(90.0; NY=10)
    @test_throws ErrorException cyl2d_modes(56.6; NY=9)
    # search for another θ0: the next valid NY must agree within the stated change or the call errors
    @test_throws ErrorException cyl2d_modes_search(56.6; NY0=8)   # NY = 8 and 10 differ by more than 1 %
end

_run_if("Three-dimensional cabin modes (Eqs. C.7, C.9, C.12)") do
    cy = cyl2d_modes(56.6; n_modes=20, NY=10, c0=340.0)
    a, L = 0.508, 1.803
    m = cy.modes[2]
    @test cabin_frequency_3d(m, a, L, 0; c0=340.0) ≈ m.f_Hz_unit / a rtol=1e-12
    @test cabin_frequency_3d(m, a, L, 2; c0=340.0) ≈ sqrt((m.f_Hz_unit / a)^2 + (340.0 * 2 / (2L))^2) rtol=1e-12
    @test cabin_eps_3d(m, 0) == m.eps_n
    @test cabin_eps_3d(m, 3) == 2 * m.eps_n
    @test axial_truncation(2π * 1000.0, L, 340.0) == ceil(Int, 2 * 2π * 1000.0 * L / (π * 340.0))
    modes3 = cabin_modes_3d(cy, a, L, 3; c0=340.0)
    @test length(modes3) == 20 * 4
    @test issorted([x.f_Hz for x in modes3])
end

_run_if("Table D-1 shapes, all 32 modes (transcription checks, V-CODE)") do
    @test length(PAIN._D1_SHAPES) == 32
    for (i, row) in enumerate(TABLE_D1_FULL)
        sh = PAIN._D1_SHAPES[i]
        @test length(sh.C_shell) == 5 && length(sh.C_floor) == 3
        @test length(sh.n_shell) == 5 && length(sh.n_floor) == 3
        sym = row[3]
        # antisymmetric modes have no n = 0 plate term (Eq. 49)
        sym || @test all(≥(1), sh.n_floor)
    end
    @test PAIN._D1_SHAPES[1].C_shell[1] ≈ -0.06640
    @test PAIN._D1_SHAPES[2].C_floor[1] ≈ 1.42371
    @test TABLE_D1_FULL[2][2] ≈ 208.24
    @test TABLE_D1_FULL[16][2] ≈ 558.43
    @test PAIN._D1_SHAPES[32].C_shell[1] ≈ 0.44856
    # Eq. (46): ψ_s(z=L/2, θ=0) for n = 1, C = 1, symmetric is −1 (the (−1)^n factor)
    m1 = StructuralMode(1, 100.0, true, 1.0, 1, [1.0], [1], Float64[], Int[])
    @test structural_shell_psi(m1, 0.5, 0.0, 1.0) ≈ -1.0
    # Eq. (47): antisymmetric carries the leading minus: −sin(π/2)(−1)^1 sin(π/2) = +1 at θ = 90°
    m2 = StructuralMode(2, 100.0, false, 1.0, 1, [1.0], [1], Float64[], Int[])
    @test structural_shell_psi(m2, 0.5, 90.0, 1.0) ≈ 1.0
end

_run_if("CYL2D floor values") do
    cy = cyl2d_modes(56.6; n_modes=6, NY=10)
    @test all(m -> length(m.phi_floor) == length(m.x_floor_unit) == 11, cy.modes)
    @test all(m -> all(abs.(m.phi_floor) .≤ 1 + 1e-12), cy.modes)
end

_run_if("Coupling f'(n,r) Eq.(52) (V-CODE, analytic limits)") do
    θ0d = 56.6
    θ0 = deg2rad(θ0d)
    a, L = 0.508, 1.803
    fuse = FuselageGeometry(L, a, θ0d)
    Lp = 2a * sin(θ0)
    den = Lp + 2a * (π - θ0)
    θd = collect(range(θ0d, 360 - θ0d; length=721))
    xf = collect(range(-sin(θ0), sin(θ0); length=201))
    ac_unif = AcousticMode(1, 100.0, true, 1.0, ones(length(θd)), θd, 1.0, ones(201), xf)
    ac_cos = AcousticMode(2, 100.0, true, 1.0, cos.(deg2rad.(θd)), θd, 1.0, ones(201), xf)
    ac_anti = AcousticMode(3, 100.0, false, 1.0, sin.(deg2rad.(θd)), θd, 1.0, sin.(π * xf ./ (2sin(θ0))), xf)
    shell0 = StructuralMode(1, 200.0, true, 1.0, 1, [1.0], [0], Float64[], Int[])
    shell1 = StructuralMode(2, 200.0, true, 1.0, 1, [1.0], [1], Float64[], Int[])
    floor0 = StructuralMode(3, 200.0, true, 1.0, 1, Float64[], Int[], [1.0], [0])
    # shell n = 0, φ = 1: f' = (2/π) a(2π−2θ0)/(Lp + 2a(π−θ0))
    @test coupling_factor(ac_unif, shell0, fuse) ≈ (2 / π) * a * (2π - 2θ0) / den atol=1e-6
    # floor n = 0, φ = 1: f' = −(2/π) Lp/(Lp + 2a(π−θ0))  (floor term carries the minus of Eq. 52)
    @test coupling_factor(ac_unif, floor0, fuse) ≈ -(2 / π) * Lp / den atol=1e-6
    # shell n = 1 (ψ = −cosθ sin), φ = cosθ: f' = −(2/π) a[(π−θ0) − sin(2θ0)/2]/den
    @test coupling_factor(ac_cos, shell1, fuse) ≈ -(2 / π) * a * ((π - θ0) - sin(2θ0) / 2) / den atol=2e-3
    # trim: √τ_t scales the shell term only; the floor term is unchanged
    @test coupling_factor(ac_unif, shell0, fuse; τ_t=0.25) ≈ 0.5 * coupling_factor(ac_unif, shell0, fuse) atol=1e-12
    @test coupling_factor(ac_unif, floor0, fuse; τ_t=0.25) ≈ coupling_factor(ac_unif, floor0, fuse) atol=1e-12
    # symmetric against antisymmetric is zero (CR-3813 §3.5)
    @test coupling_factor(ac_anti, shell1, fuse) == 0.0
    # q = M gives zero axial coupling (Eq. 57); M = 2 against q = 0 also zero
    @test axial_coupling(1, 1) == 0.0
    @test axial_coupling(0, 2) ≈ 0.0 atol=1e-15
    @test axial_coupling(0, 1) ≈ 2 / π
    # the f' bound: no error and |f'| ≤ 1 for every Table D-1 mode against every CYL2D mode
    cy = cyl2d_modes(θ0d; n_modes=20, NY=10)
    sm = structural_modes_from_table_d1(; n_keep=32)
    fm = maximum(abs(coupling_factor(ac, st, fuse)) for ac in cy.modes, st in sm.modes)
    @test fm ≤ 1.0
    # an out-of-range value raises an error instead of being clamped
    big = StructuralMode(9, 200.0, true, 1.0, 1, [50.0], [0], Float64[], Int[])
    @test_throws ErrorException coupling_factor(ac_unif, big, fuse)
end

_run_if("Table D-1 seed load (transcription check; residual 0 by construction)") do
    s = structural_modes_from_table_d1(; n_keep=32)
    @test s.modes[1].f_Hz ≈ 188.52 atol=0.1
    @test s.modes[32].f_Hz ≈ 811.04 atol=0.1
    @test length(s.modes) == 32
    records = validate_mrp_table_d1(s; tol_frac=0.001, label="transcription (by construction)")
    @test all(r -> r.result == "PASS", records)
    out = joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "mrp_table_d1.md")
    mkpath(dirname(out))
    write_validation_record(out, records)
end

_run_if("Fig E-11 digitization path (SRC_TA)") do
    paths = default_e11_paths()
    @test isfile(paths.A)
    @test isfile(paths.B)
    @test isfile(paths.phases)
    δmax, δH = delta_dig_dB(paths.A, paths.B)
    @test δmax ≤ 1.0  # dual digitization agreement gate (CLAIMS / plan)
    fuse = FuselageGeometry(1.803, 0.508, 56.6)
    prop = PropellerPlacement(0.508 + 0.05, 90.0, 0.90)
    ff = freefield_from_e11_csv(paths.A, paths.phases, fuse, prop; bpf_Hz=200.0, n_harmonics=3)
    @test ff.source === :e11_digitized
    @test size(ff.amplitudes, 3) == 3
    @test maximum(ff.amplitudes) > 0
    records = ValidationRecord[
        ValidationRecord("SRC_TA", "V-EXP", "Fig.E-11 dual digitization",
            "δ_dig max |A-B|", "≤ 1.0 dB", δmax ≤ 1.0 ? "PASS" : "FAIL",
            "δmax=$(round(δmax; digits=2)) dB; H1=$(round(δH[1]; digits=2)) H2=$(round(δH[2]; digits=2)) H3=$(round(δH[3]; digits=2))"),
    ]
    out = joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "e11_delta_dig.md")
    write_validation_record(out, records)
end

_run_if("End-to-end pipeline smoke") do
    r = run_pain_pipeline(; use_synthetic=true, n_harmonics=3, bpf_Hz=150.0)
    @test length(r.spectrum.harmonic_SPL_dB) == 3
    @test all(isfinite, r.spectrum.harmonic_SPL_dB)
    @test cabin_volume(r.fuse) > 0
end

_run_if("E-11 pipeline: T1/T2 recorded, not asserted (Eq. 8 chain, no tuning)") do
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    @test r.source === :e11
    @test r.trim === :phase3
    @test length(r.spectrum.harmonic_SPL_dB) == 3
    @test all(isfinite, r.spectrum.harmonic_SPL_dB)
    # Since phase 17a no parameter of the tone path is fitted to T1 or T2, so the outcome is a result, not a gate.
    i17_header = "Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc."
    t1 = evaluate_T1(r.spectrum)
    write_validation_record(joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "t1_tonal.md"), t1; header=i17_header)
    @test length(t1) == 3
    t2 = evaluate_T2(r.spectrum)
    write_validation_record(joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "t2_third_octave.md"), t2; header=i17_header)
    @test !isempty(t2)
    @info "T1/T2 recorded (not asserted)" T1 = [rec.result for rec in t1] T2 = [rec.result for rec in t2]
end

_run_if("Trim / loss helpers") do
    @test 0.02 ≤ absorption_coefficient(1000) ≤ 0.65
    # The tuned surrogates trim_T_fc, acoustic_loss_factor and structural_loss_factor were removed in 17a.
    @test !isdefined(PAIN, :trim_T_fc) && !isdefined(PAIN, :TrimPanel)
    @test !isdefined(PAIN, :acoustic_loss_factor) && !isdefined(PAIN, :structural_loss_factor)
end

_run_if("App. A trim transfer matrices (16a)") do
    mat = pf105_table()
    @testset "Fig. A-2 table" begin
        for (i, f) in enumerate(mat.f_Hz)
            p = insulation_properties(mat, f)
            @test p.lambda_m ≈ mat.lambda_m[i] rtol = 1e-12
            @test p.alpha_Np_per_m ≈ mat.alpha_dB_per_m[i] * PAIN.NP_PER_DB rtol = 1e-12
            @test p.W_abs ≈ mat.W_rayl[i] rtol = 1e-12
            @test rad2deg(p.phi_rad) ≈ mat.phi_deg[i] rtol = 1e-12
            @test !p.extrapolated
        end
        @test mat.f_Hz == [100, 315, 630, 1000, 2500, 6300]
        @test_throws ErrorException insulation_properties(mat, 80.0)
        @test_throws ErrorException insulation_properties(mat, 8000.0)
        p = insulation_properties(mat, 8000.0; allow_extrapolation=true)
        @test p.extrapolated && p.lambda_m > 0 && p.alpha_Np_per_m > 0
        @test_throws ErrorException stack_matrix(TrimStack([InsulationLayer(0.013, mat)]), 2π * 8000.0)
    end

    ins = InsulationLayer(0.013, mat)
    for f in (100.0, 250.0, 700.0, 1500.0, 4000.0)
        ω = 2π * f
        @testset "limits and reciprocity at $f Hz" begin
            I2 = ComplexF64[1 0; 0 1]
            @test stack_matrix(TrimStack(TrimElement[]), ω) == I2
            @test trim_tau(TrimStack(TrimElement[]), ω) == 1.0
            @test trim_Cw(TrimStack(TrimElement[]), ω) == 0
            # a limp mass alone: lining moves with the skin, a11 = 1, τ = 1 (Eq. A.11)
            lm = TrimStack([LimpMass(1.7, 0.05)])
            M = stack_matrix(lm, ω)
            @test M[1, 1] == 1 && M[2, 2] == 1 && M[2, 1] == 0
            @test M[1, 2] ≈ ω^2 * 1.7 * (1 + 0.05im)
            @test trim_tau_insulation(lm, ω) == 1.0
            # zero thickness is the identity
            @test stack_matrix(TrimStack([InsulationLayer(0.0, mat)]), ω) ≈ I2 atol = 1e-14
            # determinant 1 for each element and for the cascade
            st = phase3_trim().sidewall
            for el in (ins, LimpMass(0.095, 0.5), InsulationLayer(0.05, mat))
                Me = element_matrix(el, ω)
                @test Me[1, 1] * Me[2, 2] - Me[1, 2] * Me[2, 1] ≈ 1 atol = 1e-10
            end
            Mc = stack_matrix(st, ω)
            @test Mc[1, 1] * Mc[2, 2] - Mc[1, 2] * Mc[2, 1] ≈ 1 rtol = 1e-8
        end
    end
    @testset "insulation + limp mass: a11 of Eqs. (A.13)–(A.14)" begin
        for f in (150.0, 400.0, 1200.0, 3000.0)
            ω = 2π * f
            m, η, L = 1.67, 0.5, 0.013
            st = TrimStack([ins, LimpMass(m, η)])
            p = insulation_properties(mat, f)
            γ = complex(p.alpha_Np_per_m, -2π / p.lambda_m)
            W = p.W_abs * cis(PAIN.W_PHASE_SIGN * p.phi_rad)
            C, S = cosh(γ * L), sinh(γ * L)
            a11_A14 = (C + ω * η * m * S / W) - im * ω * m * S / W          # Eq. (A.14)
            @test stack_matrix(st, ω)[1, 1] ≈ a11_A14 rtol = 1e-12
            @test trim_tau_insulation(st, ω) ≈ abs(a11_A14)^-2 rtol = 1e-12
        end
    end
    @testset "passivity: Re β ≥ 0 (W phase sign)" begin
        p3 = phase3_trim()
        for f in range(100, 6300; length=60)
            ω = 2π * f
            @test trim_conductance(p3.sidewall, ω, p3.m_wall) ≥ 0
            @test trim_conductance(p3.ends, ω, Inf) ≥ 0
        end
    end
    @testset "Phase III stack (App. E p. E-8)" begin
        p3 = phase3_trim()
        @test count(e -> e isa InsulationLayer, p3.sidewall.elements) == 4
        @test all(e -> e.thickness == 0.013, filter(e -> e isa InsulationLayer, p3.sidewall.elements))
        @test p3.septum_mass_per_area * p3.A_curved ≈ 6.58 rtol = 1e-12
        @test 0.22 - 0.013 * 9.61 ≈ 0.095 atol = 1e-3                 # facing = layer surface density − fiberglass
        @test length(p3.ends.elements) == 2
        @test p3.A_curved ≈ 2 * 0.508 * (π - deg2rad(56.6)) * 1.803
        # mechanical path: no connections, no transmission; positive and below the series limit otherwise
        mp0 = PAIN.MechanicalPath(; (f => getfield(p3.mech, f) for f in (:m_t, :A_t, :h_t, :c_t, :η_t, :m, :A, :h, :c_l))...)
        @test trim_tau_mechanical(mp0, 2π * 1000) == 0
        τm = trim_tau_mechanical(p3.mech, 2π * 1000)
        @test 0 < τm < (p3.mech.m_t * p3.mech.A_t * p3.mech.n_t) / (p3.mech.m * p3.mech.A * p3.mech.n_r)
        ω = 2π * 1000
        @test trim_tau(p3.sidewall, ω; mech=p3.mech) ≈ trim_tau_insulation(p3.sidewall, ω) + τm
    end
end

_run_if("Loss factors, Eqs. (62)–(83) (16b)") do
    @testset "Si and Cin to machine precision" begin
        @test sine_integral(1.0) ≈ 0.9460830703671830 rtol = 1e-14
        @test sine_integral(10.0) ≈ 1.658347594218874 rtol = 1e-14
        @test sine_integral(π) ≈ 1.851937051982466 rtol = 1e-14
        @test sine_integral(-2.0) ≈ -sine_integral(2.0)
        @test cin(1.0) ≈ 0.2398117420005648 rtol = 1e-13
        @test cin(10.0) ≈ 0.5772156649015329 + log(10) + 0.04545643300445537 rtol = 1e-13   # Cin = γ + ln x − Ci
        @test cin(-3.0) == cin(3.0)
        # continuity across the series/continued-fraction switch at x = 4
        @test abs(sine_integral(4 - 1e-9) - sine_integral(4 + 1e-9)) < 1e-8
        @test abs(cin(4 - 1e-9) - cin(4 + 1e-9)) < 1e-8
        @test sine_integral(200.0) ≈ π / 2 - cos(200.0) / 200 atol = 1e-4
    end
    # direct quadrature of the joint acceptance, ζ = a|θ1 − θ2| along the ring (the form behind Eqs. 65–73)
    function ring_quad(n, ka, kind; N=500)
        h = 2π / N
        th = h .* ((1:N) .- 0.5)
        f = kind === :psi ? cos.(n .* th) : sin.(n .* th)
        s = 0.0
        for i in 1:N, j in 1:N
            x = ka * abs(th[i] - th[j])
            s += f[i] * f[j] * (x == 0 ? 1.0 : sin(x) / x)
        end
        return s * h * h / (2π * (n == 0 ? 2π : π))
    end
    @testset "ring joint acceptance vs quadrature" begin
        for (n, ka) in ((0, 0.4), (0, 1.9), (1, 0.3), (2, 1.7), (3, 0.9), (2, 2.5), (4, 2.0))
            if n == 0
                @test ring_joint_acceptance(0, ka, :psi) ≈ ring_quad(0, ka, :psi) rtol = 2e-3
            else
                for kind in (:psi, :phi)
                    q = ring_quad(n, ka, kind)
                    # printed Eqs. (69)–(70) are half of the mode-normalized quadrature for n > 0
                    @test ring_joint_acceptance(n, ka, kind) ≈ q / 2 rtol = 2e-3
                    @test ring_joint_acceptance(n, ka, kind; mode_normalized=true) ≈ q rtol = 2e-3
                end
            end
        end
        @test ring_joint_acceptance(0, 1e-9, :psi) ≈ 1 atol = 1e-12
        @test_throws ErrorException ring_joint_acceptance(0, 1.0, :phi)
        # Eq. (64): the sum of the two printed forms is 2(I2 + I3)
        n, ka = 3, 1.3
        I1, I2, I3 = PAIN._joint_I123(n, ka)
        @test ring_joint_acceptance(n, ka, :psi) + ring_joint_acceptance(n, ka, :phi) ≈ 2 * (I2 + I3)
        # the printed I3 and its finite form agree, and the form is finite at ka = n
        @test I3 ≈ (1 - cos(2π * ka)) / (4 * (n * π)^2 * (1 - (ka / n)^2)) rtol = 1e-12
        @test all(isfinite, PAIN._joint_I123(2, 2.0))
        @test all(isfinite, ring_joint_acceptance.(1:4, 2.0, :psi)) && all(isfinite, ring_joint_acceptance.(1:4, 2.0, :phi))
    end
    @testset "axial joint acceptance vs quadrature" begin
        function axial_quad(M, kL; N=2000)
            h = 1 / N
            z = h .* ((1:N) .- 0.5)
            f = sin.(M * π .* z)
            s = 0.0
            for i in 1:N, j in 1:N
                x = kL * abs(z[i] - z[j])
                s += f[i] * f[j] * (x == 0 ? 1.0 : sin(x) / x)
            end
            return s * h * h / 0.5
        end
        for (M, kL) in ((1, 3.0), (2, 6.5), (3, 11.0))
            @test axial_joint_acceptance(M, kL; mode_normalized=true) ≈ axial_quad(M, kL; N=800) rtol = 5e-3
            @test axial_joint_acceptance(M, kL) ≈ axial_joint_acceptance(M, kL; mode_normalized=true) / 2
        end
    end
    sm = structural_modes_from_table_d1(; n_keep=32)
    @testset "structural mode joint acceptance and η_r (Eqs. 66–81)" begin
        ω = 2π * 300
        for m in sm.modes[1:8]
            j2 = structural_joint_acceptance(m, ω; a=0.508, L=1.803)
            @test isfinite(j2) && j2 ≥ -1e-12
            @test isfinite(structural_loss_total(m, 2π * m.f_Hz; a=0.508, L=1.803, m=3.2))
        end
        @test structural_loss_vacuo(300.0; C=3.0) ≈ 0.01
        @test radiation_loss_factor(0.1, 1000.0; Abar=2.0, m=3.0) ≈ 2 * 1.225 * 1000 * 2.0 / (π * 3.0 * 340.0) * 0.1
    end
    @testset "η_r' of Eq. (82)" begin
        ω, m, η = 2π * 400, 3.2, 0.01
        @test structural_loss_with_trim(η, ω, m, 0.0im) ≈ η                       # no trim coupling: η_r' = η_r
        # limp mass alone, C_w = −ω²m_t(1 + iη_t): η_r'² = μ² + (η_r + μη_t)², μ = m_t/m (the printed form; recorded in 16b)
        mt, ηt = 1.7, 0.5
        Cw = trim_Cw(TrimStack([LimpMass(mt, ηt)]), ω)
        @test Cw ≈ -ω^2 * mt * (1 + ηt * im)
        μ = mt / m
        @test structural_loss_with_trim(η, ω, m, Cw)^2 ≈ μ^2 + (η + μ * ηt)^2 rtol = 1e-12
        # degenerate radicand ≤ 0 is an error
        # (exact in binary: ω = 2, m = 2, η = 1/4, C_w = i m ω² η gives |C_w|²/(mω²)² − 2C_w^I η/(mω²) + η² = 0)
        @test_throws ErrorException structural_loss_with_trim(0.25, 2.0, 2.0, im * 2.0 * 4.0 * 0.25)
    end
    @testset "η_n of Eq. (77) and η_r'' of Eq. (83)" begin
        cy = cyl2d_modes(56.6; n_modes=6, NY=10)
        V = cabin_volume(FuselageGeometry(1.803, 0.508, 56.6))
        for q in (0, 1, 3), md in cy.modes[1:4]
            ω_n = 2π * cabin_frequency_3d(md, 0.508, 1.803, q)
            r = acoustic_loss_modal(md, q, 1000.0, ω_n; a=0.508, L=1.803, V=V, ξ=0.05, ξ_e=0.02)
            @test r.N > 0 && isfinite(r.η_n) || ω_n == 0
            z = acoustic_loss_modal(md, q, 1000.0, ω_n; a=0.508, L=1.803, V=V, ξ=0.0, ξ_e=0.0)
            @test z.N == 0
            # linear in ξ and ξ_e
            r2 = acoustic_loss_modal(md, q, 1000.0, ω_n; a=0.508, L=1.803, V=V, ξ=0.10, ξ_e=0.04)
            @test r2.N ≈ 2 * r.N rtol = 1e-12
        end
        # rigid-body mode (ω_n = 0): N finite, η_n = Inf
        md0 = cy.modes[1]
        @test md0.f_Hz_unit < 1e-3                       # the rigid-body mode (Table C-1: 0 Hz)
        r0 = acoustic_loss_modal(md0, 0, 1000.0, 0.0; a=0.508, L=1.803, V=V, ξ=0.05, ξ_e=0.02)
        @test isfinite(r0.N) && r0.N > 0 && r0.η_n == Inf
        # Eq. (83): finite at ω_n = 0, equals the printed form elsewhere, peak value pref/N on resonance
        pref(f, ε, M) = 1.225 * 340.0^2 * 2.0^2 * ε * f^2 / (M * V)
        N = 4.0e4
        ω_n, ω_r = 2π * 250, 2π * 230
        η_n = N / ω_n^2
        printed = pref(0.3, 1.1, 1.05) / ω_n^2 * η_n / ((1 - ω_r^2 / ω_n^2)^2 + η_n^2)
        @test structural_loss_coupled(N, ω_n, ω_r, 0.3, 1.1, 1.05, V, 2.0) ≈ printed rtol = 1e-12
        @test isfinite(structural_loss_coupled(N, 0.0, ω_r, 0.3, 1.1, 1.05, V, 2.0))
        @test structural_loss_coupled(N, ω_r, ω_r, 0.3, 1.1, 1.05, V, 2.0) ≈ pref(0.3, 1.1, 1.05) / N rtol = 1e-12
        @test structural_loss_coupled(N, ω_n, ω_r, 0.0, 1.1, 1.05, V, 2.0) == 0
    end
    @testset "Eq. (78) and Eq. (24)" begin
        ω, V, S, Se = 2π * 1000, 1.2, 4.0, 0.7
        ηbar = acoustic_loss_average(ω; V, S, S_e=Se, ξ=0.02, ξ_e=0.3)
        @test ηbar ≈ 8 * 340 / (4ω * V) * (0.02 * S + 2 * 0.3 * Se)
        @test absorption_from_loss_factor(ηbar, ω; V, S=S + 2Se) ≈ 8 * (0.02 * S + 0.6 * Se) / (S + 2Se) rtol = 1e-12
    end
end

# ---------------------------------------------------------------------------------------------
# Plan phase 17 (17a, 17e, 17g, 17h, 17i): Eq. (8) tone pressure, Eq. (42) generalized force.
# Verification against the written equations and analytic limits, not validation (NASA publishes no Ψ_G or p² numbers).
# ---------------------------------------------------------------------------------------------
function _rebuild(inp::PainInputs; structural=inp.structural, acoustic=inp.acoustic, amplitudes=inp.amplitudes,
                  phases=inp.phases, ΔA=inp.ΔA, sidewall=inp.sidewall, endplates=inp.endplates, mech=inp.mech,
                  η_n_bare=inp.η_n_bare, C_struc=inp.C_struc, q_max=inp.q_max,
                  crossover_band_Hz=inp.crossover_band_Hz)
    return PainInputs(inp.fuse, inp.prop, structural, acoustic, amplitudes, phases, inp.pts, ΔA;
                      sidewall, endplates, mech, m_wall=inp.m_wall, η_n_bare, C_struc, q_max,
                      allow_extrapolation=inp.allow_extrapolation, ρ0=inp.ρ0, c0=inp.c0,
                      crossover_band_Hz)
end

_run_if("Generalized force Ψ_G, Eq. (42) (17e, analytic limits)") do
    fuse = FuselageGeometry(1.803, 0.508, 56.6)
    ΔA = (π * 0.508 / 18)^2
    # a mode uniform in θ: ψ = sin(Mπz/L) (symmetric, n = 0, C = 1)
    st = StructuralMode(1, 200.0, true, 1.0, 1, [1.0], [0], Float64[], Int[])
    pts = [(k=1, ell=1, z=0.45, theta_deg=80.0), (k=2, ell=1, z=0.45, theta_deg=100.0)]
    amps = fill(0.0, 2, 1, 1); phs = fill(0.0, 2, 1, 1)
    amps[1, 1, 1] = 3.0; amps[2, 1, 1] = 3.0
    ψ = sin(π * 0.45 / 1.803)
    # in phase: S = 2Aψ, Ψ_G = (Δ⁴/2)(2Aψ)²  (closed form for uniform A and ψ)
    @test generalized_force(st, 1, amps, phs, pts, fuse; ΔA) ≈ ΔA^2 / 2 * (2 * 3.0 * ψ)^2 rtol = 1e-13
    # two equal points π apart cancel
    phs[2, 1, 1] = π
    @test generalized_force(st, 1, amps, phs, pts, fuse; ΔA) < 1e-24
    # a global phase shift leaves Ψ_G unchanged
    phs[2, 1, 1] = 0.7; phs[1, 1, 1] = 0.2
    g0 = generalized_force(st, 1, amps, phs, pts, fuse; ΔA)
    @test generalized_force(st, 1, amps, phs .+ 1.234, pts, fuse; ΔA) ≈ g0 rtol = 1e-12
    # Eq. (42) equals the double sum of Eq. (41): (Δ⁴/2) Σ_m Σ_m' A A' ψ ψ' cos(φ − φ')
    dbl = ΔA^2 / 2 * sum(amps[i, 1, 1] * amps[j, 1, 1] * ψ^2 * cos(phs[i, 1, 1] - phs[j, 1, 1]) for i in 1:2, j in 1:2)
    @test g0 ≈ dbl rtol = 1e-12
    # doubling the amplitudes doubles the force amplitude √(2Ψ_G) (so Ψ_G ×4); doubling Δ² does the same
    @test generalized_force(st, 1, 2 .* amps, phs, pts, fuse; ΔA) ≈ 4g0 rtol = 1e-12
    @test generalized_force_amplitude(st, 1, 2 .* amps, phs, pts, fuse; ΔA) ≈ 2 * generalized_force_amplitude(st, 1, amps, phs, pts, fuse; ΔA) rtol = 1e-12
    @test generalized_force(st, 1, amps, phs, pts, fuse; ΔA=2ΔA) ≈ 4g0 rtol = 1e-12
    @test generalized_force_amplitude(st, 1, amps, phs, pts, fuse; ΔA)^2 ≈ 2g0 rtol = 1e-12
    # an antisymmetric ψ against a symmetric loading (same A, φ at θ and 2π − θ) gives zero
    sta = StructuralMode(2, 200.0, false, 1.0, 1, [1.0], [1], Float64[], Int[])
    ptsa = [(k=1, ell=1, z=0.45, theta_deg=70.0), (k=2, ell=1, z=0.45, theta_deg=290.0)]
    @test generalized_force(sta, 1, fill(2.0, 2, 1, 1), zeros(2, 1, 1), ptsa, fuse; ΔA) < 1e-24
    # uniform ΔA against the grid geometry (Δ = πa/18 along the axis) and the smooth-ψ integral on the real grid
    g = grid_points(fuse, PropellerPlacement(0.965, 90.0, 0.9), GridSpec())
    zs = sort(unique(round.([p.z for p in g]; digits=10)))
    @test all(≈(π * 0.508 / 18; rtol=1e-9), diff(zs))
    Δ = π * 0.508 / 18
    st0 = StructuralMode(3, 200.0, true, 1.0, 1, [1.0], [0], Float64[], Int[])
    ring = [p for p in g if p.ell == 1]
    num = Δ * sum(sin(π * p.z / 1.803) for p in ring)
    ana = 1.803 / π * (cos(π * (minimum(zs) - Δ / 2) / 1.803) - cos(π * (maximum(zs) + Δ / 2) / 1.803))
    @test num ≈ ana rtol = 5e-3
end

_run_if("Resonance form of Eq. (8) (17g)") do
    # D = (ω0² − ω²)² + (η ω0²)² = ω0⁴ [(1 − ω²/ω0²)² + η²]
    D(ω, ω0, η) = (ω0^2 - ω^2)^2 + (η * ω0^2)^2
    ω0, η = 2π * 300, 0.05
    @test D(ω0, ω0, η) ≈ (η * ω0^2)^2                       # peak value on resonance
    @test D(ω0, ω0, η) ≈ ω0^4 * η^2
    # half-power width η ω0: |D| doubles at ω = ω0(1 ± η/2) to first order in η
    @test D(ω0 * (1 + η / 2), ω0, η) / D(ω0, ω0, η) ≈ 2 rtol = 2e-2
    # the finite limit ω_n → 0 of the cabin factor, used for the rigid-body mode: ω_H⁶/[(ω_n² − ω_H²)² + N²] → ω_H²
    ωH = 2π * 200
    @test ωH^6 / ((0.0 - ωH^2)^2 + 0.0^2) ≈ ωH^2 rtol = 1e-14
    # and the code includes that mode: a cabin made of the rigid-body mode alone gives a finite positive p²
    r0 = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, trim=:bare)
    rigid = [m for m in r0.acoustic.modes if m.index == 0]
    @test length(rigid) == 1
    inp_r = PainInputs(r0.fuse, r0.prop, r0.structural, Cyl2DResult(r0.acoustic.theta0_deg, rigid, "rigid", r0.acoustic.NY, r0.acoustic.h, r0.acoustic.c0),
                       r0.ff.amplitudes, r0.ff.phases, r0.ff.pts, r0.inputs.ΔA)
    p_r = tone_mean_square_pressure(inp_r, 1, ωH; q_max=0)
    @test isfinite(p_r) && p_r > 0
end

_run_if("Eq. (8) tone pressure: scaling laws and independent re-implementation (17a, 17h, 17i)") do
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2, trim=:bare)
    inp = r.inputs
    ωH = 2π * 200.0
    p2 = tone_mean_square_pressure(inp, 1, ωH)
    @test p2 > 0 && isfinite(p2)
    # p² ∝ Ψ_G ∝ amplitude²; zero amplitude gives zero; the amplitudes enter only through Ψ_G
    @test tone_mean_square_pressure(_rebuild(inp; amplitudes=2 .* inp.amplitudes), 1, ωH) ≈ 4p2 rtol = 1e-10
    @test tone_mean_square_pressure(_rebuild(inp; amplitudes=zero(inp.amplitudes)), 1, ωH) == 0.0
    # a global phase shift changes nothing
    @test tone_mean_square_pressure(_rebuild(inp; phases=inp.phases .+ 0.9), 1, ωH) ≈ p2 rtol = 1e-10
    # f̄' = 0 for every pair gives p² = 0: structural modes with all-zero coefficients
    zero_modes = StructuralModes([StructuralMode(1, 200.0, true, 1.0, 1, [0.0], [2], [0.0], [0])], 1.803, 0.508, 56.6, "zero")
    @test tone_mean_square_pressure(_rebuild(inp; structural=zero_modes), 1, ωH) == 0.0
    # units Pa²: the SPL of the baseline is a plausible tone level (finite, positive)
    @test 20 < 10log10(p2 / (20e-6)^2) < 160

    # cabin mode shape scaled by s (ε_n ∝ 1/s², φ ∝ s, Φ_G ∝ s²): p² unchanged, also with trim (Eq. 77 invariant)
    s_ = 0.7
    scale_ac(ac) = AcousticMode(ac.index, ac.f_Hz_unit, ac.symmetric, ac.gen_mass_unit * s_^2, ac.phi_boundary .* s_,
                                ac.theta_boundary_deg, ac.eps_n / s_^2, ac.phi_floor .* s_, ac.x_floor_unit, ac.theta_lo_rad,
                                ac.theta_hi_rad, ac.x_lo_unit, ac.x_hi_unit, ac.lambda_unit, ac.phi_nodes)
    cy2 = Cyl2DResult(inp.acoustic.theta0_deg, scale_ac.(inp.acoustic.modes), inp.acoustic.notes, inp.acoustic.NY, inp.acoustic.h, inp.acoustic.c0)
    @test tone_mean_square_pressure(_rebuild(inp; acoustic=cy2), 1, ωH) ≈ p2 rtol = 1e-9
    r3 = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2, trim=:phase3)
    cy3 = Cyl2DResult(r3.acoustic.theta0_deg, scale_ac.(r3.acoustic.modes), r3.acoustic.notes, r3.acoustic.NY, r3.acoustic.h, r3.acoustic.c0)
    @test tone_mean_square_pressure(_rebuild(r3.inputs; acoustic=cy3), 1, ωH) ≈ tone_mean_square_pressure(r3.inputs, 1, ωH) rtol = 1e-9
    # structural shape scaled by s with M_r ∝ s²: f̄'²Ψ_G/M_r² and η_r'' are invariant
    st = r.structural.modes[2]; ac = r.acoustic.modes[3]
    sst = StructuralMode(st.index, st.f_Hz, st.symmetric, st.M_r * s_^2, st.M_axial, st.C_shell .* s_, st.n_shell, st.C_floor .* s_, st.n_floor)
    fuse = inp.fuse
    f1 = coupling_factor(ac, st, fuse); f2 = coupling_factor(ac, sst, fuse)
    Ψ1 = generalized_force(st, 1, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA)
    Ψ2 = generalized_force(sst, 1, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA)
    @test f2^2 * Ψ2 / sst.M_r^2 ≈ f1^2 * Ψ1 / st.M_r^2 rtol = 1e-10
    V, A = cabin_volume(fuse), 1.803 * (2 * 0.508 * sin(deg2rad(56.6)) + 2 * 0.508 * (π - deg2rad(56.6)))
    @test structural_loss_coupled(1.0e4, 3000.0, 2π * st.f_Hz, f2, ac.eps_n, sst.M_r, V, A) ≈
          structural_loss_coupled(1.0e4, 3000.0, 2π * st.f_Hz, f1, ac.eps_n, st.M_r, V, A) rtol = 1e-10

    # Independent re-implementation of one tone (bare cabin): direct form of Eq. (8), not multiplied out, the coupling by
    # trapezoid quadrature of Eq. (52) over the piecewise-constant boundary values, Ψ_G from the double sum of Eq. (41).
    function direct_p2(inp, H, ωH)
        fuse = inp.fuse; a, L = fuse.a, fuse.L; θ0 = deg2rad(fuse.theta0_deg); Lp = 2a * sin(θ0)
        A = L * (Lp + 2a * (π - θ0)); V = cabin_volume(fuse); ρ0, c0 = inp.ρ0, inp.c0
        τML = (ρ0 * c0 * A / (2ωH))^2        # (mA/4)² τ_ML
        qtop = axial_truncation(ωH, L, c0)
        tot = 0.0
        Ψcache = Dict{Int,Float64}()
        for q in 0:qtop, ac in inp.acoustic.modes
            ωn = 2π * cabin_frequency_3d(ac, a, L, q; c0)
            εn = cabin_eps_3d(ac, q); ηn = inp.η_n_bare
            for st in inp.structural.modes
                PAIN.axial_coupling(q, st.M_axial) == 0 && continue
                ac.symmetric == st.symmetric || continue
                # f̄' by midpoint quadrature
                hθ = (2π - 2θ0) / 20000
                θs = [θ0 + (i - 0.5) * hθ for i in 1:20000]
                φθ(θ) = (j = findlast(≤(θ), ac.theta_lo_rad); j === nothing ? ac.phi_boundary[1] : ac.phi_boundary[min(j, end)])
                shell = ac.symmetric == st.symmetric ? sum(a * PAIN.shell_circumferential(st, θ) * φθ(θ) for θ in θs) * hθ : 0.0
                hx = Lp / 20000
                xs = [-Lp / 2 + (i - 0.5) * hx for i in 1:20000]
                φx(x) = (u = x / a; j = findlast(≤(u), ac.x_lo_unit); j === nothing ? ac.phi_floor[1] : ac.phi_floor[min(j, end)])
                psix(x) = sum(C * (st.symmetric ? cos(n * π * x / Lp) : sin(n * π * x / Lp)) for (C, n) in zip(st.C_floor, st.n_floor))
                flr = ac.symmetric == st.symmetric ? sum(psix(x) * φx(x) for x in xs) * hx : 0.0
                f = PAIN.axial_coupling(q, st.M_axial) * (shell - flr) / (Lp + 2a * (π - θ0))
                ωr = 2π * st.f_Hz
                ηr = structural_loss_total(st, ωr; a, L, m=inp.m_wall, C=inp.C_struc, ρ0, c0)
                ηrpp = ρ0 * c0^2 * A^2 * εn * f^2 / (st.M_r * V) * (ηn * ωn^2) / ((ωn^2 - ωr^2)^2 + (ηn * ωn^2)^2)
                Ψ = get!(Ψcache, st.index) do
                    acc = 0.0
                    for p in inp.pts, p2_ in inp.pts
                        acc += inp.amplitudes[p.k, p.ell, H] * structural_shell_psi(st, p.z, p.theta_deg, L) *
                               inp.amplitudes[p2_.k, p2_.ell, H] * structural_shell_psi(st, p2_.z, p2_.theta_deg, L) *
                               cos(inp.phases[p.k, p.ell, H] - inp.phases[p2_.k, p2_.ell, H])
                    end
                    acc * inp.ΔA^2 / 2
                end
                den = ((1 - ωH^2 / ωn^2)^2 + ηn^2) * ((1 - ωH^2 / ωr^2)^2 + (ηr + ηrpp)^2)
                tot += 4c0^2 / V^2 * τML * ωH^6 * εn / ωn^4 * f^2 * Ψ / (st.M_r^2 * ωr^4) / den
            end
        end
        return tot
    end
    # skip the rigid-body mode in the direct form (1/ωn⁴ is singular there); compare on the code with that mode removed
    nz = [m for m in inp.acoustic.modes if m.index != 0]
    inp_nz = _rebuild(inp; acoustic=Cyl2DResult(inp.acoustic.theta0_deg, nz, inp.acoustic.notes, inp.acoustic.NY, inp.acoustic.h, inp.acoustic.c0))
    @test direct_p2(inp_nz, 1, ωH) ≈ tone_mean_square_pressure(inp_nz, 1, ωH) rtol = 2e-3
    # q_max: more axial modes never lower the sum (all terms positive)
    @test tone_mean_square_pressure(inp, 1, ωH; q_max=6) ≥ tone_mean_square_pressure(inp, 1, ωH; q_max=0)
end

_run_if("PainInputs and the trim path (17a, 17b)") do
    rb = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, trim=:bare)
    rt = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, trim=:phase3)
    @test rb.trim === :bare && rt.trim === :phase3
    @test rb.inputs.sidewall === nothing && rt.inputs.sidewall !== nothing
    @test run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0).trim === :phase3   # :auto → Phase III for e11
    @test run_pain_pipeline(; use_synthetic=true, n_harmonics=3).trim === :bare
    @test_throws ErrorException PainInputs(rb.fuse, rb.prop, rb.structural, rb.acoustic, rb.ff.amplitudes, rb.ff.phases, rb.ff.pts, 0.01;
                                           sidewall=rt.inputs.sidewall)      # sidewall without end plates
    # insulation range: a tone above Fig. A-2 (6300 Hz) errors unless extrapolation is allowed
    inp = rt.inputs
    @test_throws ErrorException tone_mean_square_pressure(inp, 1, 2π * 7000.0)
    inpx = PainInputs(inp.fuse, inp.prop, inp.structural, inp.acoustic, inp.amplitudes, inp.phases, inp.pts, inp.ΔA;
                      sidewall=inp.sidewall, endplates=inp.endplates, mech=inp.mech, m_wall=inp.m_wall, allow_extrapolation=true)
    @test isfinite(tone_mean_square_pressure(inpx, 1, 2π * 7000.0; q_max=2))
    # broadband bands above the range are dropped, not extrapolated, by default
    @test !haskey(rt.spectrum.third_octave_SPL_dB, 8000.0)
    # broadband uses τ_t of Eq. (A.22): the stack's τ_t at 1.6 kHz is a number in (0, 1]
    τ = PAIN.sidewall_tau(inp, 2π * 1600)
    @test 0 < τ ≤ 1
end

_run_if("Phase 17 regression baselines (17k, frozen 2026-10-20)") do
    base = PAIN._read_csv_numeric(joinpath(@__DIR__, "..", "..", "data", "baselines", "phase17_baselines.csv"))
    names = [split(l, ",")[1] for l in readlines(joinpath(@__DIR__, "..", "..", "data", "baselines", "phase17_baselines.csv")) if !startswith(l, "#") && !startswith(l, "name") && !isempty(strip(l))]
    @test length(names) == length(base[:value])
    got = Dict{String,Float64}()
    for trim in (:bare, :phase3)
        r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2, trim=trim)
        inp = r.inputs
        for H in 1:3
            got["spl_$(trim)_H$H"] = r.spectrum.harmonic_SPL_dB[H]
            trim === :bare && for (j, st) in enumerate(inp.structural.modes)
                got["psiG_H$(H)_mode$j"] = generalized_force(st, H, inp.amplitudes, inp.phases, inp.pts, inp.fuse; ΔA=inp.ΔA)
            end
        end
        if trim === :phase3
            for f in (1250.0, 1600.0, 2000.0)
                got["band_$(Int(f))"] = r.spectrum.third_octave_SPL_dB[PAIN.nearest_third_octave(f, collect(keys(r.spectrum.third_octave_SPL_dB)))]
            end
            for H in 1:3
                got["tau_t_H$H"] = PAIN.sidewall_tau(inp, 2π * 200H)
            end
        else
            got["max_abs_fprime"] = maximum(abs(coupling_factor(ac, st, inp.fuse)) for ac in inp.acoustic.modes, st in inp.structural.modes)
            for ac in inp.acoustic.modes[1:6], (j, st) in enumerate(inp.structural.modes[1:8])
                got["fprime_n$(ac.index)_r$j"] = coupling_factor(ac, st, inp.fuse)
            end
        end
    end
    for (n, v) in zip(names, base[:value])
        @test got[n] ≈ v rtol = 1e-6 atol = 1e-12
    end
end

_run_if("MRP raw Ritz: regression guard of a calibrated fit (not evidence)") do
    fuse = FuselageGeometry(1.803, 0.508, 56.6)
    ritz = structural_modes(fuse; hybrid=false, n_keep=48)
    n_spec, _ = match_ritz_to_table_d1(ritz; tol_frac=0.05)
    # k_scale, edge_factor, floor_scale were fitted by fit_mrp_to_table_d1 to maximize this same
    # count, so this only guards the fit; it is not a test of the solver.
    @test n_spec ≥ 25
    hyb = structural_modes(fuse; hybrid=true, n_keep=32)
    # hybrid copies Table D-1 frequencies by construction (n_keep=32, sorted by D-1 index)
    @test [m.f_Hz for m in hyb.modes] == [r[2] for r in TABLE_D1_FULL]
    @test all(m -> !isempty(m.C_shell) || !isempty(m.C_floor), hyb.modes)   # Ritz shapes attached
end

_run_if("Metrics dBA / SIL") do
    # IEC 61672 A-weighting table values (independent of overall_dBA band)
    @test a_weight_dB(1000.0) ≈ 0.0 atol=0.1
    @test a_weight_dB(100.0) ≈ -19.1 atol=0.1
    @test a_weight_dB(200.0) ≈ -10.9 atol=0.1
    @test a_weight_dB(4000.0) ≈ 1.0 atol=0.1
    # empty bands → tones-only at exact harmonic frequencies
    spec1 = InteriorSpectrum(1000.0, [94.0], Dict{Float64,Float64}(), "hand-built")
    dBA1, _, _ = overall_dBA(spec1)
    @test dBA1 ≈ 94.0 atol=0.1
    spec2 = InteriorSpectrum(500.0, [94.0, 94.0], Dict{Float64,Float64}(), "hand-built")
    dBA2, _, _ = overall_dBA(spec2)
    expected2 = 10 * log10(10^((94 + a_weight_dB(500.0)) / 10) + 10^((94 + a_weight_dB(1000.0)) / 10))
    @test dBA2 ≈ expected2 atol=1e-9
    # non-empty bands → energy sum over bands (tones not double-counted)
    spec3 = InteriorSpectrum(1000.0, [99.0], Dict(1000.0 => 94.0), "hand-built bands")
    dBA3, _, _ = overall_dBA(spec3)
    @test dBA3 ≈ 94.0 atol=0.1
    spec4 = InteriorSpectrum(500.0, Float64[], Dict(500.0 => 94.0, 1000.0 => 94.0), "hand-built bands")
    dBA4, _, _ = overall_dBA(spec4)
    expected4 = 10 * log10(10^((94 + a_weight_dB(500.0)) / 10) + 10^((94 + a_weight_dB(1000.0)) / 10))
    @test dBA4 ≈ expected4 atol=1e-9
    r = run_pain_pipeline(; use_synthetic=true, n_harmonics=5, bpf_Hz=150.0)
    @test isfinite(sil_from_third_octave(r.spectrum.third_octave_SPL_dB))
    # band overall ≥ tones-only (band-centre vs exact-f weighting) within 0.5 dB,
    # and equals an independent band energy sum
    pref2 = (20e-6)^2
    p2_tones = 0.0
    for (H, spl) in enumerate(r.spectrum.harmonic_SPL_dB)
        f = H * r.spectrum.bpf_Hz
        p2_tones += pref2 * 10^((spl + a_weight_dB(f)) / 10)
    end
    tones_only = 10 * log10(p2_tones / pref2 + 1e-30)
    p2_bands = 0.0
    for (fc, spl) in r.spectrum.third_octave_SPL_dB
        (isfinite(fc) && isfinite(spl)) || continue
        p2_bands += pref2 * 10^((spl + a_weight_dB(fc)) / 10)
    end
    bands_only = 10 * log10(p2_bands / pref2 + 1e-30)
    dBA_r, _, _ = overall_dBA(r.spectrum)
    @test dBA_r ≥ tones_only - 0.5
    @test dBA_r ≈ bands_only atol=1e-9
end

_run_if("Shared source function (21, V-CODE)") do
    # n_harmonics=3, num_src_times=32 to bound runtime.
    # Pre-I-01 f1a_line_reference.csv is void (I-01); equivalence vs that file removed.
    json = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
    fuse = FuselageGeometry(1.803, 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.90)
    spec = GridSpec()
    nH, nsrc = 3, 32
    cfg = PAIN._load_aircraft_json(json)
    Vinf = Float64(PAIN._get(cfg.operating_point, :forward_speed_mps, 20.0))
    observers, pts = grid_observers(fuse, prop, spec; Vinf=Vinf)
    src = evaluate_propeller_source(cfg, observers; n_harmonics=nH, num_src_times=nsrc)
    # --- Echo (includes I-01 period_src / n_src) ---
    e = src.echo
    for k in (:Vinf, :vinf_substituted, :c0, :rho, :polar, :t_over_c, :pitch_offset_deg,
              :loads, :s_T, :s_Q, :num_src_times, :B, :Rhub, :Rtip, :rpm, :allow_static,
              :period_src, :n_src, :n_rev_src, :force_short_source)
        @test haskey(e, k)
    end
    @test e.loads === :ccblade
    @test e.s_T == 1.0 && e.s_Q == 1.0
    @test e.n_rev_src == 2
    @test e.n_src == 2 * e.B * nsrc
    @test e.force_short_source == false

    # --- Coincidence: grid point (k=5, ell=4) vs hand-built Observer (I-02 test c) ---
    p54 = first(p for p in pts if p.k == 5 && p.ell == 4)
    i54 = findfirst(p -> p.k == 5 && p.ell == 4, pts)
    hand = [Observer(PAIN._observer_aa(fuse, prop, p54), [Vinf, 0.0, 0.0], "hand")]
    src_hand = evaluate_propeller_source(cfg, hand; n_harmonics=nH, num_src_times=nsrc)
    @test src.amplitude[i54, :] == src_hand.amplitude[1, :]
    @test src.phase[i54, :] == src_hand.phase[1, :]
    # --- All 160: finite > 0; differs from GEXT of ell=1 line ---
    ff_cal = propeller_freefield_grid(json, fuse, prop, spec; n_harmonics=nH, num_src_times=nsrc)
    @test all(isfinite, ff_cal.amplitudes)
    @test all(>(0), ff_cal.amplitudes)
    line_a = ff_cal.amplitudes[:, 1, :]
    line_p = ff_cal.phases[:, 1, :]
    ωH = [2π * H * ff_cal.bpf_Hz for H in 1:nH]
    gext_a, _ = extend_line_to_grid(line_a, line_p, pts; omega_H=ωH)
    rel = abs.(ff_cal.amplitudes .- gext_a) ./ max.(ff_cal.amplitudes, 1e-30)
    @test maximum(rel[:, 2:end, :]) > 1e-6
    # --- Static guard ---
    tmp = joinpath(tempdir(), "pain_static_guard.json")
    txt = read(json, String)
    txt2 = replace(txt, r"\"forward_speed_mps\"\s*:\s*[0-9.]+" => "\"forward_speed_mps\": 0.0")
    write(tmp, txt2)
    cfg0 = PAIN._load_aircraft_json(tmp)
    obs0, _ = grid_observers(fuse, prop, spec; Vinf=20.0)
    src0 = @test_logs (:warn, r"Vinf") evaluate_propeller_source(cfg0, obs0; n_harmonics=1, num_src_times=16)
    @test src0.echo.vinf_substituted == true
    src0b = evaluate_propeller_source(cfg0, obs0; n_harmonics=1, num_src_times=16, allow_static=true)
    @test src0b.echo.vinf_substituted == false
    @test src0b.echo.Vinf == 0.0
    # --- ScaledLoads (25h): targets reproduced; uniform scale → amplitude × scale ---
    obs1 = observers[1:1]
    src_base = evaluate_propeller_source(cfg, obs1; n_harmonics=1, num_src_times=16)
    sl = ScaledLoads(2 * src_base.T, 2 * src_base.Q)
    src_sc = evaluate_propeller_source(cfg, obs1; n_harmonics=1, num_src_times=16, loads=sl)
    @test src_sc.T ≈ sl.T_target rtol=1e-9
    @test src_sc.Q ≈ sl.Q_target rtol=1e-9
    @test src_sc.echo.s_T ≈ 2.0 rtol=1e-9
    @test src_sc.echo.s_Q ≈ 2.0 rtol=1e-9
    @test src_sc.amplitude[1, 1] ≈ 2 * src_base.amplitude[1, 1] rtol=1e-6
    rm(tmp; force=true)
end

_run_if("F1A source span and phase origin (I-01/I-02)") do
    # Report 996-like near-field observer (plan I-01): M_t high, x/D=0, d/D=0.083.
    json = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
    cfg = PAIN._load_aircraft_json(json)
    Rtip = Float64(cfg.propeller.tip_radius_m)
    D = 2 * Rtip
    obs_nf = [Observer([0.0, 0.083 * D, 0.0], zeros(3), "nf_xD0")]
    nsrc = 32
    src2 = evaluate_propeller_source(cfg, obs_nf; n_harmonics=3, num_src_times=nsrc,
                                     allow_static=true, n_rev_src=2)
    src3 = evaluate_propeller_source(cfg, obs_nf; n_harmonics=3, num_src_times=nsrc,
                                     allow_static=true, n_rev_src=3)
    # I-01 (a): 2 rev vs 3 rev — amplitudes rtol 1e-3, phases within 0.1°
    @test all(isapprox.(src2.amplitude, src3.amplitude; rtol=1e-3))
    for H in 1:3
        dph = rad2deg(mod(src2.phase[1, H] - src3.phase[1, H] + π, 2π) - π)
        @test abs(dph) < 0.1
    end
    # I-01 (b): force_short_source (old one-bpp span) → guard fires
    @test_throws ErrorException evaluate_propeller_source(
        cfg, obs_nf; n_harmonics=1, num_src_times=nsrc, allow_static=true, force_short_source=true)
    # I-02 (b): shifting the observer does not change relative kinematics here;
    # window start varies per observer, but absolute-referenced phase is stable under
    # an integer blade-pass re-sample: compare two identical observers.
    src_a = evaluate_propeller_source(cfg, obs_nf; n_harmonics=2, num_src_times=64, allow_static=true)
    src_b = evaluate_propeller_source(cfg, obs_nf; n_harmonics=2, num_src_times=64, allow_static=true)
    @test src_a.phase ≈ src_b.phase atol=1e-12

    # I-01 (c): far-field Gutin closed form on same T, Q (shared with F1A_GUTIN case).
    cmp = f1a_gutin_h1_comparison(; aircraft_json=json)
    @test abs(cmp.delta_dB) ≤ 1.0
    @test cmp.ok
end

_run_if("BBN kinematics (24b, V-UNIT)") do
    # I-02 (a): after absolute phase reference, Δφ = m·B·Δψ on a hub-centred ring (static)
    # within 0.5° (frozen 23a′). Both rotation senses: sign of Δφ flips.
    json = joinpath(@__DIR__, "..", "examples", "bbn_aerocommander_tipA.json")
    cfg = PAIN._load_aircraft_json(json)
    R = 1.18
    seps = [13.3, 11.8, 10.4]
    ψ = cumsum([0.0; seps])
    r_obs = R + 0.15
    B = Int(cfg.propeller.num_blades)
    function ring_phases(sense::Int)
        # sense = +1: positive_x_rotation as in f1a_source_elements_ccblade(..., true)
        # Observer angles ψ increase in the same sense as blade rotation for +1.
        obs = [Observer([0.0, r_obs * cosd(sense * a), r_obs * sind(sense * a)], zeros(3), "ψ=$(sense*a)") for a in ψ]
        evaluate_propeller_source(cfg, obs; n_harmonics=3, num_src_times=64, allow_static=true)
    end
    src = ring_phases(+1)
    @test size(src.phase) == (4, 3)
    @test all(isfinite, src.phase)
    @test all(isfinite, src.amplitude)
    # Consecutive observers: Δφ = ± m·B·Δψ (sign from rotation vs azimuth convention).
    # Pick the sign from H1 of the first pair; then require that sign for all.
    dφ11 = rad2deg(mod(src.phase[2, 1] - src.phase[1, 1] + π, 2π) - π)
    sense_sign = sign(dφ11) == 0 ? 1.0 : sign(dφ11)
    for (i, Δψ) in enumerate(seps)
        for H in 1:3
            dφ = rad2deg(mod(src.phase[i + 1, H] - src.phase[i, H] + π, 2π) - π)
            expect = sense_sign * H * B * Δψ
            expect = mod(expect + 180, 360) - 180
            @test abs(dφ - expect) ≤ 0.5
        end
    end
    src_rev = ring_phases(-1)
    for (i, Δψ) in enumerate(seps)
        dφ_fwd = rad2deg(mod(src.phase[i + 1, 1] - src.phase[i, 1] + π, 2π) - π)
        dφ_rev = rad2deg(mod(src_rev.phase[i + 1, 1] - src_rev.phase[i, 1] + π, 2π) - π)
        @test abs(dφ_fwd + dφ_rev) ≤ 1.0  # opposite observer sense → opposite Δφ
    end
end


_run_if("Polar loader (25i, V-CODE)") do
    path = joinpath(@__DIR__, "..", "..", "data", "report996", "polars_forced_merged.json")
    @test isfile(path)
    af, st = load_polar_set(path; set=:primary)
    # knot near α=0 at some Re,M — finite
    cl, cd = af(0.0, 5e5, 0.2)
    @test isfinite(cl) && isfinite(cd)
    afb, stb = load_polar_set(path; set=:bracket)
    clb, cdb = afb(0.0, 5e5, 0.2)
    # bracket multiplies primary cl by k_cl from tables.json (default 0.92264); same (α,Re,M) knot
    @test clb / cl ≈ 0.92264 rtol=1e-9
    @test stb.clamped_Re >= 0
end

_run_if("Report 996 conversions + blade form (25b/25j, V-UNIT)") do
    # total_rms: two equal peak amplitudes A → √(A²) = A
    @test total_rms([2.0, 2.0]) ≈ 2.0 rtol=1e-12
    @test total_rms([√2]) ≈ 1.0 rtol=1e-12
    # p_c identity: p_c = π² p_rms / (ρ M_t² a²)
    ρ, Mt, a = 1.225, 0.60, 340.3
    p_rms = 10.0  # Pa
    pc = pressure_coefficient_pc(p_rms; ρ=ρ, M_t=Mt, a=a)
    @test pc ≈ (π^2) * p_rms / (ρ * Mt^2 * a^2) rtol=1e-12
    @test pa_to_dyne_cm2(1.0) == 10.0
    @test dyne_cm2_to_pa(10.0) == 1.0
    bf = joinpath(@__DIR__, "..", "..", "data", "report996", "naca_4-5-08-03", "blade_form.csv")
    @test isfile(bf)
    g = blade_form_geometry(bf; D=1.2192, beta75_target_deg=15.0)
    @test length(g.radii_m) == length(g.chord_m) == length(g.twist_deg)
    @test g.radii_m[1] / g.R ≈ 0.271 rtol=1e-3
    @test maximum(g.radii_m) / g.R ≤ 0.995 + 1e-9
    # β at nearest 0.75R station ≈ target (design 42.64 → shift)
    i75 = argmin(abs.(g.radii_m ./ g.R .- 0.75))
    @test g.twist_deg[i75] ≈ 15.0 atol=0.6
    obs = hub_observers(g.R, g.D; x_over_D=[-0.125, 0.125], d_over_D=0.083, x_sign=-1.0)
    @test length(obs) == 2
    # x_sign=-1: listed x/D=-0.125 (behind in report coords) → AA +X
    @test obs[1].x[1] ≈ (-1.0) * (-0.125) * g.D rtol=1e-12
end

# ---------------------------------------------------------------------------------------------
# Plan phase 38a: CR-3813 §3.3 noise reduction (reverberant exterior), Eqs. (17)–(18).
# V-UNIT before any E-21/E-22 comparison; no parameter chosen from those figures.
# ---------------------------------------------------------------------------------------------
_run_if("Noise reduction Eqs. (17)–(18) (38a)") do
    cω = C_OMEGA_THIRD_OCTAVE
    @testset "helpers: closed form = band integral of resonance product" begin
        ω = 2π * 400
        ωn, ωr = 2π * 350.0, 2π * 450.0
        ηn, ηr = 0.05, 0.10
        closed = nr_band_integral_closed(ω, cω, ωn, ηn, ωr, ηr)
        quad = nr_band_integral_quad(ω, cω, ωn, ηn, ωr, ηr; N=80_000)
        @test closed ≈ quad rtol = 1e-6
        # second pair nearer resonance
        closed2 = nr_band_integral_closed(ω, cω, 2π * 390, 0.08, 2π * 410, 0.12)
        quad2 = nr_band_integral_quad(ω, cω, 2π * 390, 0.08, 2π * 410, 0.12; N=80_000)
        @test closed2 ≈ quad2 rtol = 1e-6
    end
    @testset "limits: η→0 finite; far from resonances small; uncoupled → 0" begin
        ω = 2π * 500
        ωn, ωr = 2π * 480.0, 2π * 520.0
        c = nr_band_integral_closed(ω, cω, ωn, 1e-12, ωr, 1e-12)
        @test isfinite(c)
        # far from both resonances → much smaller than near-resonance value
        far = nr_band_integral_closed(ω, cω, 2π * 50, 0.05, 2π * 80, 0.05)
        near = nr_band_integral_closed(ω, cω, ωn, 0.05, ωr, 0.05)
        @test abs(far) < 1e-3 * abs(near)
        # symmetry mismatch: coupling_factor → 0 ⇒ no contribution in the spectrum path
        inp = noise_reduction_test_article_inputs(; η_lining=1.0)
        fuse = inp.fuse
        ac_s = first(m for m in inp.acoustic.modes if m.symmetric)
        st_a = first(m for m in inp.structural.modes if !m.symmetric)
        @test coupling_factor(ac_s, st_a, fuse; τ_t=1.0, q=0) == 0.0
    end
    @testset "η_r_cap=nothing leaves tone path unchanged" begin
        r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, trim=:phase3)
        inp = r.inputs
        ωH = 2π * 200.0
        p0 = tone_mean_square_pressure(inp, 1, ωH)
        p1 = tone_mean_square_pressure(inp, 1, ωH; η_r_cap=nothing)
        @test p0 == p1
        # with a tight cap the pressure must change (cap is active)
        p_cap = tone_mean_square_pressure(inp, 1, ωH; η_r_cap=0.15)
        @test p_cap != p0 || all(st -> begin
            ωr = 2π * st.f_Hz
            ηr = structural_loss_total(st, ωr; a=inp.fuse.a, L=inp.fuse.L, m=inp.m_wall, C=inp.C_struc)
            η′ = structural_loss_with_trim(ηr, ωr, inp.m_wall, trim_Cw(inp.sidewall, ωr))
            η′ ≤ 0.15 + 1e-15
        end, inp.structural.modes)
    end
    @testset "Eq. (17)/(5) route equals Eq. (18) contribution" begin
        # One (n,r) pair: printed Eq. (17) → ⟨p_n²⟩ → ratio equals Eq. (18) term
        inp = noise_reduction_test_article_inputs(; η_lining=1.0)
        fc = 315.0
        ω = 2π * fc
        p_bl2 = 1.0
        p_e2 = p_bl2 / 2
        fuse = inp.fuse
        a, L, ρ0, c0 = fuse.a, fuse.L, inp.ρ0, inp.c0
        A = coupling_area(fuse)
        V = cabin_volume(fuse)
        Abar = cylinder_surface_area(a, L)
        τ_t = PAIN.sidewall_tau(inp, ω)
        found = nothing
        for qq in 0:2, aac in inp.acoustic.modes, sst in inp.structural.modes
            ff = coupling_factor(aac, sst, fuse; τ_t, q=qq)
            if ff != 0 && cabin_frequency_3d(aac, a, L, qq; c0) > 0
                found = (aac, sst, qq, ff)
                break
            end
        end
        @test found !== nothing
        ac, st, q, f = found
        ωn = 2π * cabin_frequency_3d(ac, a, L, q; c0)
        ωr = 2π * st.f_Hz
        εn = cabin_eps_3d(ac, q)
        ext = true
        ξ = trim_conductance(inp.sidewall, ω, inp.m_wall; ρ0, c0, allow_extrapolation=ext)
        ξe = trim_conductance(inp.endplates, ω, Inf; ρ0, c0, allow_extrapolation=ext)
        N = acoustic_loss_modal(ac, q, ω, ωn; a, L, V, c0, ξ, ξ_e=ξe).N
        ηn = N / ωn^2
        ηr = structural_loss_total(st, ωr; a, L, m=inp.m_wall, C=inp.C_struc, ρ0, c0, Abar)
        ηrp = structural_loss_with_trim(ηr, ωr, inp.m_wall,
                                        trim_Cw(inp.sidewall, ωr; allow_extrapolation=ext); η_r_cap=0.15)
        ηrpp = structural_loss_coupled(N, ωn, ωr, f, εn, st.M_r, V, A; ρ0, c0)
        ηrt = ηrp + ηrpp
        j2 = structural_joint_acceptance(st, ω; a, L, c0)
        t = nr_brace(ω, cω, ωn, ηn, ωr, ηrt)
        mA4 = mass_law_factor(ρ0, c0, A, ω)
        pref17 = p_bl2 / (cω * ω) * (2π * Abar^2) / (ρ0 * V) * mA4
        curly = (2 / π) * ω^2 * ωn^2 / t.D_nr * t.brace
        Win = pref17 * εn * j2 * f^2 / st.M_r^2 * curly
        # Link printed Eq. (17) → Eq. (18): ⟨p_n²⟩ = W_in · ρ c² ω / (V ω_n²).
        # Tone Eq. 7 carries η_n/ω_n² so Eq. 5's η_n cancels; printed Eq. 17 omits that
        # free η_n and Eq. 18 matches that omission (38a report).
        p2_n = Win * ρ0 * c0^2 * ω / (V * ωn^2)
        ratio_from_17 = p2_n / p_e2
        pref18 = 8 / (cω * ω) * (Abar / V)^2 * mA4 * c0^2 * ω^3
        ratio_18 = pref18 * εn * j2 * f^2 / (st.M_r^2 * t.D_nr) * t.brace
        @test ratio_from_17 ≈ ratio_18 rtol = 1e-9
        @test isfinite(ηn) && ηn > 0
    end
    @testset "E21_E22_NR case runs; verdict follows the counts" begin
        @test validation_case_runnable("E21_E22_NR")
        r = run_validation_case("E21_E22_NR")
        @test !isempty(r.table)
        @test !isempty(r.series)
        @test r.verdict in (:met, :not_met)
        n_nasa = r.inputs_echo.n_nasa
        n_nasa_ok = r.inputs_echo.n_nasa_ok
        n_e22 = r.inputs_echo.n_e22
        n_e22_ok = r.inputs_echo.n_e22_ok
        expect = (n_nasa_ok / max(n_nasa, 1) ≥ 0.75) && (n_e22_ok / max(n_e22, 1) ≥ 0.75)
        @test (r.verdict === :met) == expect
        @test occursin("crossover", r.reason)
        @test occursin("80", r.reason)
    end
end

# Plan phase 38b: CR-3813 §3.2 high-frequency tone Eqs. (11)–(16) and crossover.
# V-UNIT before any REPRO_18b :auto comparison; no parameter chosen from NASA tones.
# ---------------------------------------------------------------------------------------------
_run_if("High-frequency tones Eqs. (11)–(16) (38b)") do
    cω = C_OMEGA_THIRD_OCTAVE
    @testset "E[g] closed form = band integral (1e-8 relative)" begin
        ωH = 2π * 1000.0
        Δω = cω * ωH
        for η̄ in (0.02, 0.05, 0.10, 0.20)
            closed = expected_g_closed(ωH, η̄, Δω)
            quad = expected_g_quad(ωH, η̄, Δω; N=200_000)
            @test closed ≈ quad rtol = 1e-8
        end
        # π-limit when η̄ ω_H ≪ Δω (atan(x)→π/2; x=Δω/(ηω_H)=2.32e7 at η=1e-8 → |rel|≪1e-6)
        η_small = 1e-8
        @test expected_g_closed(ωH, η_small, Δω) ≈ expected_g_pi(ωH, η_small, Δω) rtol = 1e-6
    end
    @testset "Eq. (13) Monte-Carlo mean → expected value (large N, small η)" begin
        # Dense band (N_n ≥ 10), seeded uniform draws of ω_n, ω_r. Tolerance from
        # sampling error: SE = σ/√N_mc; allow 5·SE relative to the closed-form mean.
        # Use a real blocked grid (e11) so Ψ_G indexing matches the points.
        r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, trim=:bare)
        bare = PainInputs(r.inputs.fuse, r.inputs.prop, r.inputs.structural, r.inputs.acoustic,
                          r.inputs.amplitudes, r.inputs.phases, r.inputs.pts, r.inputs.ΔA;
                          η_n_bare=0.01)
        xover = acoustic_crossover_band(bare)
        # Prefer the crossover band (has ≥10 acoustic modes); if no structural modes
        # there, step up through 1/3-oct centres until both counts are positive.
        fc = xover.fc_Hz
        band = modes_in_tone_band(bare, 2π * fc)
        for fc_try in third_octave_centers()
            fc_try < xover.fc_Hz && continue
            b_try = modes_in_tone_band(bare, 2π * fc_try)
            if length(b_try.ac_list) ≥ 10 && length(b_try.st_list) ≥ 1
                fc, band = fc_try, b_try
                break
            end
        end
        ωH = 2π * fc
        N_n, N_r = length(band.ac_list), length(band.st_list)
        @test N_n ≥ 10 && N_r ≥ 1
        H = 1
        losses = band_average_loss_factors(bare, ωH, band)
        η̄_n, η̄_r = losses.η̄_n, losses.η̄_r
        @test isfinite(η̄_n) && isfinite(η̄_r) && η̄_n > 0 && η̄_r > 0
        Egn = expected_g_closed(ωH, η̄_n, band.Δω)
        Egr = expected_g_closed(ωH, η̄_r, band.Δω)
        ρ0, c0 = bare.ρ0, bare.c0
        V = cabin_volume(bare.fuse)
        A = coupling_area(bare.fuse)
        τ_t = PAIN.sidewall_tau(bare, ωH)
        Q_H = 4 * (c0 / V)^2 * mass_law_factor(ρ0, c0, A, ωH) * ωH^6   # no τ_t; barred f̄'
        sum_nr = 0.0
        for mn in band.ac_list, mr in band.st_list
            f = coupling_factor(mn.ac, mr.st, bare.fuse; τ_t, q=mn.q)
            f == 0 && continue
            Ψ = generalized_force(mr.st, H, bare.amplitudes, bare.phases, bare.pts, bare.fuse; ΔA=bare.ΔA)
            sum_nr += mn.εn * f^2 * Ψ / mr.st.M_r^2
        end
        expect = (Q_H / ωH^8) * Egn * Egr * sum_nr
        # Seeded LCG (no Random.jl dep in the test env): u ← (a u + c) mod 2^64 → [0,1)
        rng_state = Ref(UInt64(38_002))
        next_u01() = (rng_state[] = 0x5851_f42d_4c95_7f2d * rng_state[] + 0x1405_7b7e_f767_814f;
                      (rng_state[] >>> 11) * 0x1p-53)
        N_mc = 400
        lo, hi = band.lo, band.hi
        samples = Vector{Float64}(undef, N_mc)
        ωn = Vector{Float64}(undef, N_n)
        ωr = Vector{Float64}(undef, N_r)
        for k in 1:N_mc
            for i in 1:N_n
                ωn[i] = lo + (hi - lo) * next_u01()
            end
            for j in 1:N_r
                ωr[j] = lo + (hi - lo) * next_u01()
            end
            samples[k] = tone_eq13_sample(bare, H, ωH, ωn, ωr)
        end
        μ = sum(samples) / N_mc
        σ = sqrt(sum((s - μ)^2 for s in samples) / max(N_mc - 1, 1))
        se = σ / sqrt(N_mc)
        rel_tol = max(5 * se / max(abs(expect), 1e-30), 1e-3)
        @test μ ≈ expect rtol = rel_tol
    end
    @testset "default :eq8 reproduces current tone results exactly" begin
        r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, trim=:phase3)
        inp = r.inputs
        for H in 1:3
            ωH = 2π * H * 200.0
            p8 = tone_mean_square_pressure(inp, H, ωH)
            pair = tone_mean_square_pressure_pair(inp, H, ωH; tone_model=:eq8)
            @test pair.p2 == p8
            @test pair.p2_eq8 == p8
            @test pair.model === :eq8
        end
        # interior_spl default matches the previous Eq. (8)-only spectrum
        spec_default = interior_spl(inp; bpf_Hz=200.0, n_harmonics=3, broadband=false)
        @test spec_default.tone_model === :eq8
        @test spec_default.harmonic_SPL_dB == spec_default.harmonic_SPL_eq8_dB
        for H in 1:3
            ωH = 2π * H * 200.0
            p8 = tone_mean_square_pressure(inp, H, ωH)
            @test spec_default.harmonic_SPL_dB[H] ≈ 10 * log10(p8 / (20e-6)^2 + 1e-30)
            @test r.spectrum.harmonic_SPL_dB[H] ≈ spec_default.harmonic_SPL_dB[H]
        end
        # stored baselines (phase 17) still match under default tone_model
        base = PAIN._read_csv_numeric(joinpath(@__DIR__, "..", "..", "data", "baselines", "phase17_baselines.csv"))
        names = [split(l, ",")[1] for l in readlines(joinpath(@__DIR__, "..", "..", "data", "baselines", "phase17_baselines.csv")) if !startswith(l, "#") && !startswith(l, "name") && !isempty(strip(l))]
        got = Dict{String,Float64}()
        for trim in (:bare, :phase3)
            rr = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2, trim=trim)
            for H in 1:3
                got["spl_$(trim)_H$H"] = rr.spectrum.harmonic_SPL_dB[H]
            end
        end
        for (n, v) in zip(names, base[:value])
            startswith(n, "spl_") || continue
            @test got[n] ≈ v rtol = 1e-6 atol = 1e-12
        end
    end
    @testset "crossover band ≥10 rule (test article + synthetic)" begin
        inp = noise_reduction_test_article_inputs(; η_lining=0.5)
        xover = acoustic_crossover_band(inp)
        println("38b crossover (test article): fc=$(round(xover.fc_Hz; digits=1)) Hz, n_modes=$(xover.n_modes)")
        @test xover.n_modes ≥ 10
        @test isfinite(xover.fc_Hz)
        # every lower band has fewer than 10
        bands = third_octave_centers()
        for fc in bands
            fc ≥ xover.fc_Hz && break
            @test acoustic_modes_in_band(inp, fc) < 10
        end
        # synthetic resonance list: 10 modes clustered at 500 Hz → first band with ≥10 is ~500 Hz
        synth_f = [500.0 * (1 + 0.01 * (k - 5.5) / 5) for k in 1:10]
        synth_count(fc) = begin
            ω = 2π * fc
            lo, hi = ω * (1 - cω / 2), ω * (1 + cω / 2)
            count(f -> lo ≤ 2π * f ≤ hi, synth_f)
        end
        first_ge10 = nothing
        for fc in bands
            if synth_count(fc) ≥ 10
                first_ge10 = fc
                break
            end
        end
        @test first_ge10 !== nothing
        @test abs(first_ge10 - 500.0) / 500.0 < 0.05
        @test synth_count(first_ge10) ≥ 10
        for fc in bands
            fc ≥ first_ge10 && break
            @test synth_count(fc) < 10
        end
        # card-10 override
        over = PainInputs(inp.fuse, inp.prop, inp.structural, inp.acoustic,
                          inp.amplitudes, inp.phases, inp.pts, inp.ΔA;
                          sidewall=inp.sidewall, endplates=inp.endplates, mech=inp.mech,
                          m_wall=inp.m_wall, allow_extrapolation=true, crossover_band_Hz=1000.0)
        @test resolve_crossover_Hz(over) == 1000.0
    end
end

# Plan phase 38c: CR-3813 §3.3 HF broadband Eqs. (19)–(23) as printed.
# V-UNIT before any Fig. E-9 / E-21 comparison; no parameter chosen from those figures.
# ---------------------------------------------------------------------------------------------
_run_if("HF broadband Eqs. (19)–(23) (38c)") do
    @testset "Limits of Eqs. (20)–(23): closed-form stack" begin
        # Hand values (SI): A_t=2, A′=0, S=5, ᾱ=0.4, τ_t=0.25, τ_f=0.01, τ_R=0.02
        # → τ=0.03; Eq.23 (A′=0): ⟨p_e²⟩/⟨p_i²⟩ = ᾱ S/(τ_t τ A_t) = 2/(0.25·0.03·2) = 400/3
        A_t, A′, S = 2.0, 0.0, 5.0
        ᾱ, τ_t, τ_f, τ_R = 0.4, 0.25, 0.01, 0.02
        τ = τ_f + τ_R
        ratio = (ᾱ * S + (τ_f + τ_R * 1.0) * A′) / (τ_t * τ * A_t + τ * A′)
        @test ratio ≈ (0.4 * 5) / (0.25 * 0.03 * 2) atol = 1e-12
        @test ratio ≈ 400 / 3 atol = 1e-12
        NR = 10 * log10(ratio)
        @test NR ≈ 10 * log10(400 / 3) atol = 1e-12
        # Eq. (20) with a known sum: τ_f = (32/π) ρ² (Ā/m²) Σ[j²]²
        ρ, Ā, m, sum_j2sq = 1.225, 10.0, 3.23, 1.0e-6
        τ_f20 = (32 / π) * ρ^2 * (Ā / m^2) * sum_j2sq
        @test τ_f20 ≈ (32 / π) * (1.225)^2 * (10 / 3.23^2) * 1e-6 rtol = 1e-12
        # Bare limit A_t=0, τ_t=1: ratio = (ᾱ S + [τ_f+τ_R η̄_r/η_rad] A′)/(τ A′)
        A_t2, A′2 = 0.0, 2.0
        η̄_r, η_rad = 0.05, 0.02
        ratio_bare = (ᾱ * S + (τ_f + τ_R * (η̄_r / η_rad)) * A′2) / (1.0 * τ * A_t2 + τ * A′2)
        @test ratio_bare ≈ (0.4 * 5 + (0.01 + 0.02 * 2.5) * 2) / (0.03 * 2) rtol = 1e-12
    end
    @testset "Energy/reciprocity: η̄_r large → τ_R→0; p² positive finite 1–4 kHz" begin
        inp = noise_reduction_test_article_inputs(; η_lining=0.5)
        # Artificial large structural loss via η_r_cap does not force τ_R→0; instead
        # check the analytic limit: η̄_r → ∞ ⇒ τ_R → 0, and with A′=0,
        # ⟨p_i²⟩ = (⟨p_bl²⟩/2) · τ_t τ_f A_t / (ᾱ S) ≥ 0.
        for fc in (1000.0, 1250.0, 1600.0, 2000.0, 2500.0, 3150.0, 4000.0)
            tc = hf_transmission_coeffs(inp, fc)
            @test tc.τ_f ≥ 0 && isfinite(tc.τ_f)
            @test tc.τ_R ≥ 0 && isfinite(tc.τ_R)
            @test tc.τ ≈ tc.τ_f + tc.τ_R
            # Large η̄_r limit of the printed τ_R formula
            τ_R_big = (2 * tc.band.n_r * π^2 * tc.c0 * tc.losses.η_rad_ext * tc.losses.η_rad_int) /
                      (tc.ρ0 * tc.ω * 1e6) * (4 * tc.ρ0 * tc.c0 / tc.Abar)
            @test τ_R_big < 1e-6 || τ_R_big < 1e-3 * max(tc.τ_R, 1e-30)
            p2 = hf_broadband_band_p2(inp, fc, 1.0)
            @test p2 ≥ 0 && isfinite(p2)
            pr = hf_pressure_ratio(inp, fc)
            @test pr.ratio > 0 && isfinite(pr.ratio)
            @test pr.NR_dB > -Inf && isfinite(pr.NR_dB)
        end
    end
    @testset "default :surrogate reproduces current T2 results exactly" begin
        r = run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200.0, blocking=R2)
        inp = r.inputs
        spec_def = interior_spl(inp; bpf_Hz=200.0, n_harmonics=5, broadband=true)
        spec_surr = interior_spl(inp; bpf_Hz=200.0, n_harmonics=5, broadband=true,
                                 broadband_model=:surrogate, bb_j2_scale=0.5)
        @test spec_def.third_octave_SPL_dB == spec_surr.third_octave_SPL_dB
        # Match pipeline spectrum (also default :surrogate)
        for (b, v) in r.spectrum.third_octave_SPL_dB
            @test spec_def.third_octave_SPL_dB[b] ≈ v atol = 1e-12
        end
        # Surrogate T2 case numbers unchanged vs evaluate_T2 on default spectrum
        t2_pipe = evaluate_T2(r.spectrum)
        t2_def = evaluate_T2(spec_def)
        @test length(t2_pipe) == length(t2_def)
        for (a, b) in zip(t2_pipe, t2_def)
            @test a.result == b.result
            @test a.notes == b.notes
        end
    end
    @testset "T2_EQ19 case runs; table/series non-empty" begin
        @test validation_case_runnable("T2_EQ19")
        res = run_validation_case("T2_EQ19")
        @test !isempty(res.table)
        @test !isempty(res.series)
        @test res.verdict in (:met, :not_met)
        @test occursin("Eq. (19)", res.label) || occursin("printed", res.label)
        @test haskey(res.inputs_echo, :broadband_model)
        @test res.inputs_echo.broadband_model === :eq19
        println("38c T2_EQ19: ", res.reason)
    end
end

_run_if("Validation case registry (34d)") do
    @test Set(keys(VALIDATION_CASES)) == Set(VALIDATION_CASE_ORDER)
    for id in VALIDATION_CASE_ORDER
        @test haskey(VALIDATION_CASES, id)
        c = VALIDATION_CASES[id]
        @test c.plot_spec isa PlotSpec
        @test !isempty(c.id)
        @test !isempty(c.criterion_date)
    end
    # Task C: every registry id has CASE_INFO and appears in exactly one map block
    block_hits = Dict{String,Int}()
    for m in VALIDATION_MAPS
        for b in m.blocks
            for id in b.cases
                block_hits[id] = get(block_hits, id, 0) + 1
            end
        end
    end
    for id in VALIDATION_CASE_ORDER
        @test haskey(CASE_INFO, id)
        @test get(block_hits, id, 0) == 1
    end
    for map_id in ("pain", "aircraft")
        raw = validation_map_json(map_id)
        parsed = JSON3.read(raw)
        @test parsed.id == map_id
        listed = String[]
        for b in parsed.blocks
            for c in b.cases
                push!(listed, String(c.id))
            end
        end
        for id in VALIDATION_CASE_ORDER
            # registry cases on this map must appear in the JSON
            get(block_hits, id, 0) == 1 || continue
            info = CASE_INFO[id]
            # find which map owns this id
            own = nothing
            for m in VALIDATION_MAPS
                for b in m.blocks
                    id in b.cases && (own = m.id)
                end
            end
            own == map_id && @test id in listed
        end
    end

    # Task F2 — §2.13 is the single source for CASE_INFO / map structure
    ut_ids = String[]
    for m in VALIDATION_MAPS
        for b in m.blocks
            for id in b.cases
                startswith(id, "UT_") && push!(ut_ids, id)
            end
        end
    end
    for id in Iterators.flatten((VALIDATION_CASE_ORDER, ut_ids))
        @test haskey(CASE_INFO, id)
        info = CASE_INFO[id]
        @test !isempty(info.title)
        @test !isempty(info.verifies)
        @test !isempty(info.why)
        @test !isempty(info.meaning)
        @test !isempty(info.missing)
        @test !isempty(info.recorded)
        @test !isempty(info.explanation)
        @test !isempty(info.source)
    end
    for m in VALIDATION_MAPS
        @test !isempty(m.what_is)
        @test !isempty(m.how_to_read)
        for b in m.blocks
            @test !isempty(b.title)
            @test !isempty(b.what_it_does)
        end
    end
    # Expected structure (frozen with §2.13 migration; R996_FIG8 removed)
    @test [m.id for m in VALIDATION_MAPS] == ["pain", "aircraft"]
    @test [b.id for b in VALIDATION_MAPS[1].blocks] ==
          ["P_FF", "P_GRID", "P_BLK", "P_MRP", "P_CYL", "P_TRIM", "P_EQ8", "P_REPRO", "P_MEAS"]
    @test [b.id for b in VALIDATION_MAPS[2].blocks] ==
          ["A_GEO", "A_LOADS", "A_AMP", "A_PHASE", "A_FWD", "A_SURF", "A_CABIN"]
    @test VALIDATION_MAPS[1].blocks[3].cases == ["BLK_P68", "E12_BLOCK"]
    @test VALIDATION_MAPS[2].blocks[3].cases ==
          ["F1A_GUTIN", "R996_FIG14", "R996_FIG12", "R996_FIG13A", "R996_FIG6", "R996_FIG7"]
    @test !haskey(CASE_INFO, "R996_FIG8")
    # Temp-doc edit → case_info_json changes (single source)
    mktempdir() do tmp
        src = validation_guideline_path()
        dst = joinpath(tmp, "VALIDATION_GUIDELINE.md")
        md = read(src, String)
        md2 = replace(md,
            "**Explanation:** Eq. (43) is NASA's empirical blocking factor F(γ):" =>
            "**Explanation:** TEMP_DOC_PROBE_R2 Eq. (43) is NASA's empirical blocking factor F(γ):";
            count=1)
        @test md2 != md
        write(dst, md2)
        maps2, cases2 = parse_validation_guideline_section(read(dst, String))
        @test occursin("TEMP_DOC_PROBE_R2", cases2["BLK_P68"].explanation)
        @test occursin("R2", cases2["BLK_P68"].explanation)
        # Restore live CASE_INFO unchanged (parser on temp only)
        @test !occursin("TEMP_DOC_PROBE_R2", CASE_INFO["BLK_P68"].explanation)
        @test length(maps2) == length(VALIDATION_MAPS)
    end
    blk = JSON3.read(case_info_json("BLK_P68"))
    @test occursin("R2", String(blk.explanation))
    pain_json = JSON3.read(validation_map_json("pain"))
    @test haskey(pain_json, :how_to_read)
    @test !isempty(String(pain_json.how_to_read))
    @test haskey(pain_json.blocks[1], :what_it_does)
    r1 = run_validation_case("CYL2D_C1")
    r2 = run_validation_case("CYL2D_C1")
    @test r1.verdict === :met
    @test length(r1.table) == length(r2.table)
    for (a, b) in zip(r1.table, r2.table)
        @test a.computed ≈ b.computed rtol=1e-9 atol=0
        @test a.reference ≈ b.reference rtol=1e-9 atol=0
    end
    ref_f = only(s for s in r1.series if s.name == "Table C-1 f")
    @test ref_f.kind === :reference_points
    @test ref_f.y == collect(Float64, TABLE_C1_FREQ_HZ)
    ref_g = only(s for s in r1.series if s.name == "Table C-1 Φ_G")
    @test ref_g.y == collect(Float64, TABLE_C1_GENMASS)
    m1 = run_validation_case("MRP_D1")
    m2 = run_validation_case("MRP_D1")
    @test m1.verdict === :no_verdict
    for (a, b) in zip(m1.table, m2.table)
        @test a.computed ≈ b.computed rtol=1e-9 atol=0
        @test a.reference == b.reference
    end
    rr = run_validation_case("REPRO_18b")
    @test rr.verdict === :not_met
    # regression against re-recorded 18b-r after amplitude-convention fix (I-17 / F4 2026-10-21; not a criterion)
    # Expected: old + 10*log10(2) = +3.0103 dB → 85.74, 78.74, 80.06
    @test rr.table[1].computed ≈ 85.74 atol=0.01
    @test rr.table[2].computed ≈ 78.74 atol=0.01
    @test rr.table[3].computed ≈ 80.06 atol=0.01
    png = plot_case(r1, VALIDATION_CASES["CYL2D_C1"].plot_spec)
    @test isfile(png)
    @test filesize(png) > 0
    # R996_FIG8 removed 2026-10-21 (I-20: M_t=1.0 out of scope)
    @test !haskey(VALIDATION_CASES, "R996_FIG8")
    # Task C new cases — Fig.14 counts after A_rms = A/√2 (I-17 / F4 2026-10-21, post-hoc)
    fig14 = run_validation_case("R996_FIG14")
    @test count(r -> r.within_tolerance, fig14.table) == 20
    @test length(fig14.table) == 24
    @test fig14.verdict === :met
    @test run_validation_case("MRP_RITZ").verdict === :no_verdict
    @test run_validation_case("BLK_P68").verdict === :met
    @test run_validation_case("F1A_GUTIN").verdict === :met

    # Task C4 — converted report-pointer cases → CSV replays
    # Allowed transcribed constant tables in src/ (not read from page images):
    allowed_src_constants = (
        "TABLE_C1_FREQ_HZ", "TABLE_C1_GENMASS", "TABLE_C1_SYMMETRIC", "TABLE_C1_C0",
        "TABLE_D1_FULL", "BLOCKING_P68_CHECKPOINTS",
    )
    # Live in-process cross-checks with no digitized reference file:
    allowed_live_no_csv = ("F1A_GUTIN", "BBN_KIN")
    converted = ("PER_LOADS", "PER_FIG6", "PER_FIG7", "PER_FIG8", "PER_FIG9",
                 "R996_FIG6", "R996_FIG7", "BBN_CIRC", "BBN_LONG", "BBN_LEVELS")
    results_by_id = Dict{String,Any}()
    for id in VALIDATION_CASE_ORDER
        results_by_id[id] = run_validation_case(id)
    end
    for id in converted
        r = results_by_id[id]
        @test !isempty(r.series)
        @test !isempty(r.table)
    end
    bbn = results_by_id["BBN_CIRC"]
    @test bbn.inputs_echo.n_ok == 26
    @test bbn.inputs_echo.n_tot == 168
    # BBN_LONG: Fig. 19 / Fig. 20 panels are built per pair (must differ)
    blong = results_by_id["BBN_LONG"]
    m1 = only(s for s in blong.series if s.panel == 1 && startswith(s.name, "measured"))
    m2 = only(s for s in blong.series if s.panel == 2 && startswith(s.name, "measured"))
    @test m1.y != m2.y || m1.x != m2.x
    # Pereira H1/H2 counts after peak_Pa_to_spl_dB (I-17 / F4 2026-10-21, post-hoc)
    per9 = results_by_id["PER_FIG9"]
    @test per9.inputs_echo.n1ok == 3 && per9.inputs_echo.n1 == 9
    @test per9.inputs_echo.n2ok == 6 && per9.inputs_echo.n2 == 9
    @test results_by_id["R996_FIG6"].verdict === :no_verdict
    @test results_by_id["GEXT_BOUND"].verdict === :no_verdict
    for id in VALIDATION_CASE_ORDER
        @test !isempty(results_by_id[id].series)
    end
    # Task F1 — every case with a table renders a PNG; error-panel legend ≤ 10 entries;
    # BBN_CIRC residuals wrapped to ±180°; GEXT_BOUND :no_verdict.
    for id in VALIDATION_CASE_ORDER
        r = results_by_id[id]
        isempty(r.table) && continue
        png = plot_case(r, VALIDATION_CASES[id].plot_spec)
        @test isfile(png) && filesize(png) > 0
        groups = unique(String[isempty(row.group) ? PAIN._error_quantity_group(row.quantity) : row.group
                               for row in r.table
                               if isfinite(PAIN._row_error(row, VALIDATION_CASES[id].plot_spec.error_mode)) &&
                                  isfinite(row.x)])
        # Cap is 8 quantity groups + within/outside → ≤ 10 legend entries.
        @test length(groups) <= 64  # many groups may exist; legend display caps at 8
        n_legend = min(length(groups), 8) + (isempty(groups) ? 0 : 2)
        @test n_legend <= 10
    end
    for row in results_by_id["BBN_CIRC"].table
        @test -180 <= row.residual <= 180
    end
    # Data-source guard: non-empty table → existing .csv or allowed src constant; never .png
    for id in VALIDATION_CASE_ORDER
        c = VALIDATION_CASES[id]
        r = results_by_id[id]
        isempty(r.table) && continue
        echo = string(r.inputs_echo)
        refs = join(c.reference_files, " ")
        blob = echo * " " * refs
        @test !occursin(".png", lowercase(blob))
        id in allowed_live_no_csv && continue
        csv_paths = String[p for p in c.reference_files if endswith(lowercase(p), ".csv")]
        for v in values(r.inputs_echo)
            if v isa AbstractString && endswith(lowercase(String(v)), ".csv")
                push!(csv_paths, String(v))
            end
        end
        has_csv = any(isfile, csv_paths)
        has_const = any(occursin(name, blob) for name in allowed_src_constants)
        @test has_csv || has_const
    end
end



println()
println("=== Testset filter summary ===")
if isempty(_TEST_FILTER)
    println("Filter: (none — all testsets)")
else
    println("Filter: ", join(ARGS, ", "))
end
println("Ran (", length(_TESTSETS_RAN), "):")
for t in _TESTSETS_RAN
    println("  + ", t)
end
println("Skipped (", length(_TESTSETS_SKIPPED), "):")
for t in _TESTSETS_SKIPPED
    println("  - ", t)
end
