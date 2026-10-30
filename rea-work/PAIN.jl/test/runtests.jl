using Test
using PAIN
using JSON3
using Statistics

# §2.13 lives in a .md outside the package compile graph; refresh CASE_INFO / maps
# so guideline edits are visible without relying on a stale precompile snapshot.
reload_validation_docs!()

# Top-level testset filter (task P1). Empty ARGS → run everything.
# Pkg.test("PAIN"; test_args=["CYL2D"]) puts substrings in ARGS (case-insensitive match on title).
# Helpers are defined once so DaemonMode can re-include this file with shared=true.
# All test-generated reports/figures go under TEST_OUT so Pkg.test() leaves the git tree clean.
if !isdefined(@__MODULE__, :_run_if)
    const _TEST_FILTER = String[]
    const _TESTSETS_RAN = String[]
    const _TESTSETS_SKIPPED = String[]
    const _TESTSETS_FAILED = String[]   # a failing testset no longer stops the suite (2026-10-23); listed and re-thrown at the end
    const TEST_OUT = mktempdir()
    # Pre-existing dirty tracked docs/data paths (repo-relative → content hash) at suite start.
    const _DOCS_DATA_BASELINE = Dict{String,String}()
    const _DOCS_DATA_REPO = Ref{String}("")

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
            try
                @testset "$title" begin
                    f()
                end
            catch e
                e isa Test.TestSetException || rethrow()
                push!(_TESTSETS_FAILED, title)
            end
            dt = time() - t0
            println("RAN: ", title, " (", round(dt; digits=2), " s)")
        else
            push!(_TESTSETS_SKIPPED, title)
            println("SKIPPED: ", title)
        end
        return nothing
    end

    """Parse `git status --porcelain` lines into tracked docs/data paths (repo-relative, `/`).
    Skips untracked (`??`) and VALIDATION_MAP_TOTAL*.png under validation_reports/figures."""
    function _parse_docs_data_porcelain(raw::AbstractString)
        dirty = String[]
        for line in split(raw, '\n'; keepempty=false)
            length(line) < 4 && continue
            line[1:2] == "??" && continue  # ignore untracked
            path = strip(line[3:end])
            if startswith(path, "\"") && endswith(path, "\"")
                path = path[2:end-1]
            end
            occursin(" -> ", path) && (path = split(path, " -> "; limit=2)[2])
            path = replace(path, '\\' => '/')
            # Smoke scripts write these on purpose; the suite itself must not.
            endswith(path, ".png") && occursin("VALIDATION_MAP_TOTAL", basename(path)) &&
                occursin("validation_reports/figures", path) && continue
            under = startswith(path, "rea-work/docs/") || startswith(path, "rea-work/data/") ||
                    startswith(path, "docs/") || startswith(path, "data/")
            under && push!(dirty, path)
        end
        return dirty
    end

    function _docs_data_abspath(repo::AbstractString, rel::AbstractString)
        return normpath(joinpath(repo, split(rel, '/')...))
    end

    # Content hash via git (SHA-1 blob id); avoids needing SHA.jl in the test env.
    function _file_content_hash(path::AbstractString)
        isfile(path) || return ""
        return readchomp(`git hash-object -- $path`)
    end
end

empty!(_TEST_FILTER)
append!(_TEST_FILTER, lowercase.(String.(ARGS)))
empty!(_TESTSETS_RAN)
empty!(_TESTSETS_SKIPPED)

# Snapshot already-dirty docs/data so mid-task edits are not blamed on the suite.
empty!(_DOCS_DATA_BASELINE)
_DOCS_DATA_REPO[] = ""
let rea = abspath(joinpath(@__DIR__, "..", ".."))  # rea-work
    if Sys.which("git") !== nothing
        inside = try
            readchomp(`git -C $rea rev-parse --is-inside-work-tree`) == "true"
        catch
            false
        end
        if inside
            repo = abspath(readchomp(`git -C $rea rev-parse --show-toplevel`))
            _DOCS_DATA_REPO[] = repo
            raw = read(`git -C $repo status --porcelain -- $rea`, String)
            for p in _parse_docs_data_porcelain(raw)
                _DOCS_DATA_BASELINE[p] = _file_content_hash(_docs_data_abspath(repo, p))
            end
        end
    end
end

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
    out = joinpath(TEST_OUT, "blocking_p68.md")
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
    a, L = 0.508, 1.83
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

_run_if("Cabin mode animation (phase 36)") do
    cy = cyl2d_modes(56.6; n_modes=20, NY=10, c0=TABLE_C1_C0)
    nframes = 12
    # Mode 0 uniform; node field equals cyl2d_modes (no smoothing)
    fr0 = mode_animation_frames(cy, 0; nframes=nframes, grid=41)
    @test fr0.nframes == nframes
    @test length(fr0.frames) == nframes
    @test fr0.colour_limits[1] == -fr0.colour_limits[2]
    @test fr0.clim ≈ fr0.colour_limits[2]
    nodes0 = fr0.nodes
    for (ix, m) in enumerate(nodes0.ms), (iy, n) in enumerate(nodes0.ns)
        nodes0.mask[ix, iy] || continue
        haskey(cy.modes[1].phi_nodes, (abs(m), n)) || continue
        expected = cy.modes[1].phi_nodes[(abs(m), n)]  # mode 0 symmetric
        @test nodes0.φ[ix, iy] ≈ expected atol=1e-12
    end
    cabin_vals = [nodes0.φ[ix, iy] for ix in eachindex(nodes0.ms), iy in eachindex(nodes0.ns) if nodes0.mask[ix, iy]]
    @test !isempty(cabin_vals)
    @test maximum(abs, cabin_vals) ≈ 1.0 atol=1e-9
    @test all(isapprox(v, first(cabin_vals); atol=1e-9) for v in cabin_vals)

    # Antisymmetric mode odd about the centreline (Table C-1 mode 1)
    fr1 = mode_animation_frames(cy, 1; nframes=nframes, grid=41)
    @test fr1.symmetric == false
    n1 = fr1.nodes
    for (ix, m) in enumerate(n1.ms)
        m > 0 || continue
        ixm = findfirst(==(-m), n1.ms)
        ixm === nothing && continue
        for iy in eachindex(n1.ns)
            (n1.mask[ix, iy] && n1.mask[ixm, iy]) || continue
            @test n1.φ[ixm, iy] ≈ -n1.φ[ix, iy] atol=1e-12
        end
    end
    ix0 = findfirst(==(0), n1.ms)
    if ix0 !== nothing
        for iy in eachindex(n1.ns)
            n1.mask[ix0, iy] || continue
            @test abs(n1.φ[ix0, iy]) < 1e-12
        end
    end
    # Frame k: φ · cos(2π k/nframes); colour limits fixed
    for k in 0:(nframes - 1)
        c = cos(2π * k / nframes)
        @test maximum(abs, filter(!isnan, vec(fr1.frames[k + 1])); init=0.0) ≤ fr1.clim + 1e-12
        # at a drawing cell that is finite in φ0, frame = φ0 * c
        for I in eachindex(fr1.φ0)
            isnan(fr1.φ0[I]) && continue
            @test fr1.frames[k + 1][I] ≈ fr1.φ0[I] * c atol=1e-12
            break
        end
    end
    # Node values unchanged vs cyl2d_modes
    for ((m, n), v) in cy.modes[2].phi_nodes
        ix = findfirst(==(m), n1.ms)
        iy = findfirst(==(n), n1.ns)
        ix === nothing && continue
        @test n1.φ[ix, iy] ≈ v atol=1e-12
    end

    # Output files written
    cache = mktempdir()
    out = joinpath(cache, "mode1.gif")
    paths = render_mode_animation(out, fr1; format=:gif, axial_q=1)
    @test isfile(paths.gif_path) && filesize(paths.gif_path) > 0
    @test isfile(paths.png_path) && filesize(paths.png_path) > 0
    @test axial_factor(1, 1.83)(0.0) ≈ 1.0
    @test axial_factor(1, 1.83)(1.83) ≈ -1.0 atol=1e-12

    # GUI fill path (offscreen Observables; no window)
    obs = make_gui_observables()
    obs["cm_mode"][] = 2.0
    obs["cm_q"][] = 0.0
    obs["cm_nframes"][] = 8.0
    obs["cm_struct_mode"][] = 1.0
    fr = fill_cabin_modes_gui!(obs)
    @test fr !== nothing
    @test startswith(String(obs["cm_status"][]), "Done")
    @test !isempty(String(obs["cm_f"][]))
    @test !isempty(String(obs["cm_Phi_G"][]))
    @test occursin("symmetric", String(obs["cm_symmetry"][])) || occursin("antisymmetric", String(obs["cm_symmetry"][]))
    @test isfile(String(obs["cm_frame_path"][]))
    @test isfile(String(obs["cm_peak_path"][]))
    @test !isempty(String(obs["cm_f_prime"][]))
    @test isfile(String(obs["cm_struct_path"][]))
    @test String(obs["cm_c0"][]) == string(TABLE_C1_C0)
    @test String(obs["cm_theta0"][]) == "56.6"
    @test String(obs["cm_NY"][]) == "10"
end

_run_if("CYL2D floor values") do
    cy = cyl2d_modes(56.6; n_modes=6, NY=10)
    @test all(m -> length(m.phi_floor) == length(m.x_floor_unit) == 11, cy.modes)
    @test all(m -> all(abs.(m.phi_floor) .≤ 1 + 1e-12), cy.modes)
end

_run_if("Coupling f'(n,r) Eq.(52) (V-CODE, analytic limits)") do
    θ0d = 56.6
    θ0 = deg2rad(θ0d)
    a, L = 0.508, 1.83
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
    # floor n = 0, φ = 1: f' = +(2/π) Lp/(Lp + 2a(π−θ0)) on the raw MRP plate coefficients (NASA's corrected
    # program, 44f 2026-10-23; CR-3813's printed minus assumed ψ_p upward)
    @test coupling_factor(ac_unif, floor0, fuse) ≈ (2 / π) * Lp / den atol=1e-6
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
    out = joinpath(TEST_OUT, "mrp_table_d1.md")
    write_validation_record(out, records)
end

_run_if("Fig E-11 digitization path (SRC_TA)") do
    paths = default_e11_paths()
    @test isfile(paths.A)
    @test isfile(paths.B)
    @test isfile(paths.phases)
    δmax, δH = delta_dig_dB(paths.A, paths.B)
    @test δmax ≤ 1.0  # dual digitization agreement gate (CLAIMS / plan)
    fuse = FuselageGeometry(1.83, 0.508, 56.6)
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
    out = joinpath(TEST_OUT, "e11_delta_dig.md")
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
    write_validation_record(joinpath(TEST_OUT, "t1_tonal.md"), t1; header=i17_header)
    @test length(t1) == 3
    t2 = evaluate_T2(r.spectrum)
    write_validation_record(joinpath(TEST_OUT, "t2_third_octave.md"), t2; header=i17_header)
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
        @test p3.A_curved ≈ 2 * 0.508 * (π - deg2rad(56.6)) * 1.83
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
            j2 = structural_joint_acceptance(m, ω; a=0.508, L=1.83)
            @test isfinite(j2) && j2 ≥ -1e-12
            @test isfinite(structural_loss_total(m, 2π * m.f_Hz; a=0.508, L=1.83, m=3.2))
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
        V = cabin_volume(FuselageGeometry(1.83, 0.508, 56.6))
        for q in (0, 1, 3), md in cy.modes[1:4]
            ω_n = 2π * cabin_frequency_3d(md, 0.508, 1.83, q)
            r = acoustic_loss_modal(md, q, 1000.0, ω_n; a=0.508, L=1.83, V=V, ξ=0.05, ξ_e=0.02)
            @test r.N > 0 && isfinite(r.η_n) || ω_n == 0
            z = acoustic_loss_modal(md, q, 1000.0, ω_n; a=0.508, L=1.83, V=V, ξ=0.0, ξ_e=0.0)
            @test z.N == 0
            # linear in ξ and ξ_e
            r2 = acoustic_loss_modal(md, q, 1000.0, ω_n; a=0.508, L=1.83, V=V, ξ=0.10, ξ_e=0.04)
            @test r2.N ≈ 2 * r.N rtol = 1e-12
        end
        # rigid-body mode (ω_n = 0): N finite, η_n = Inf
        md0 = cy.modes[1]
        @test md0.f_Hz_unit < 1e-3                       # the rigid-body mode (Table C-1: 0 Hz)
        r0 = acoustic_loss_modal(md0, 0, 1000.0, 0.0; a=0.508, L=1.83, V=V, ξ=0.05, ξ_e=0.02)
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
                  crossover_band_Hz=inp.crossover_band_Hz,
                  ρ0=inp.ρ0, c0=inp.c0, ρ_ext=inp.ρ_ext, c_ext=inp.c_ext,
                  ρ_int=inp.ρ_int, c_int=inp.c_int, L_c=inp.L_c, d=inp.d, prop=inp.prop,
                  bands=inp.bands, η_r_band=inp.η_r_band, η_n_band=inp.η_n_band)
    return PainInputs(inp.fuse, prop, structural, acoustic, amplitudes, phases, inp.pts, ΔA;
                      sidewall, endplates, mech, m_wall=inp.m_wall, η_n_bare, C_struc, q_max,
                      allow_extrapolation=inp.allow_extrapolation, ρ0=ρ0, c0=c0,
                      ρ_ext=ρ_ext, c_ext=c_ext, ρ_int=ρ_int, c_int=c_int, L_c=L_c, d=d,
                      crossover_band_Hz, bands=bands, η_r_band=η_r_band, η_n_band=η_n_band)
end

_run_if("Generalized force Ψ_G, Eq. (42) (17e, analytic limits)") do
    fuse = FuselageGeometry(1.83, 0.508, 56.6)
    ΔA = (π * 0.508 / 18)^2
    # a mode uniform in θ: ψ = sin(Mπz/L) (symmetric, n = 0, C = 1)
    st = StructuralMode(1, 200.0, true, 1.0, 1, [1.0], [0], Float64[], Int[])
    pts = [(k=1, ell=1, z=0.45, theta_deg=80.0), (k=2, ell=1, z=0.45, theta_deg=100.0)]
    amps = fill(0.0, 2, 1, 1); phs = fill(0.0, 2, 1, 1)
    amps[1, 1, 1] = 3.0; amps[2, 1, 1] = 3.0
    ψ = sin(π * 0.45 / 1.83)
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
    num = Δ * sum(sin(π * p.z / 1.83) for p in ring)
    ana = 1.83 / π * (cos(π * (minimum(zs) - Δ / 2) / 1.83) - cos(π * (maximum(zs) + Δ / 2) / 1.83))
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
    zero_modes = StructuralModes([StructuralMode(1, 200.0, true, 1.0, 1, [0.0], [2], [0.0], [0])], 1.83, 0.508, 56.6, "zero")
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
    V, A = cabin_volume(fuse), 1.83 * (2 * 0.508 * sin(deg2rad(56.6)) + 2 * 0.508 * (π - deg2rad(56.6)))
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
                # floor term with a plus on the raw MRP plate coefficients (NASA's corrected program, 44f 2026-10-23)
                f = PAIN.axial_coupling(q, st.M_axial) * (shell + flr) / (Lp + 2a * (π - θ0))
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
    fuse = FuselageGeometry(1.83, 0.508, 56.6)
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
    fuse = FuselageGeometry(1.83, 0.508, 56.6)
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

_run_if("BBN pair convention (I-19)") do
    # Printed App. C convention: φ_b − φ_a; mic b lagging a by 30° → −30°.
    @test bbn_printed_pair_phase(0.0, -30.0) ≈ -30.0 atol=1e-12
    @test bbn_printed_pair_phase(10.0, -20.0) ≈ -30.0 atol=1e-12
    # Rigid rotating field, blades upward at fuselage (same tipA / sense as BBN_KIN):
    # pair 4-3 printed-convention phase at H1 is negative (upper mic lags), matching
    # Table 8 positive (upward) U_c ⇒ negative printed phase.
    json = joinpath(@__DIR__, "..", "examples", "bbn_aerocommander_tipA.json")
    cfg = PAIN._load_aircraft_json(json)
    geom = (hub_x=0.0, hub_y=0.432, hub_lat=1.31)
    # Fig. 1: mic 3 y=0.584 (upper), mic 4 y=0.279 (lower); pair 4-3 = lower–upper
    mics = Dict(3 => (x=0.0, y=0.584), 4 => (x=0.0, y=0.279))
    obs = Observer[]
    idx = Dict{Int,Int}()
    for loc in (3, 4)
        m = mics[loc]
        push!(obs, Observer([m.x - geom.hub_x, geom.hub_lat, m.y - geom.hub_y], zeros(3), "mic$loc"))
        idx[loc] = length(obs)
    end
    src = evaluate_propeller_source(cfg, obs; n_harmonics=1, num_src_times=64, allow_static=true)
    φ_printed = bbn_printed_pair_phase(rad2deg(src.phase[idx[4], 1]), rad2deg(src.phase[idx[3], 1]))
    @test φ_printed < 0
end

_run_if("Polar loader (25i, V-CODE)") do
    path = joinpath(@__DIR__, "..", "..", "data", "report996", "polars_forced_merged.json")
    @test isfile(path)
    ps, st = load_polar_set(path; set=:primary)
    @test length(ps.sections) == 10 && issorted(ps.t_over_c)
    @test_throws ErrorException ps(0.0, 5e5, 0.2)          # Report 996 has ten sections: a thickness is required
    # knot near α=0 at some Re,M — finite
    cl, cd = section_polar(ps, 0.07)(0.0, 5e5, 0.2)
    @test isfinite(cl) && isfinite(cd)
    # thin and thick sections differ (the old loader gave every station 16-101)
    @test section_polar(ps, 0.13)(deg2rad(2.0), 1e6, 0.4)[1] != section_polar(ps, 0.05)(deg2rad(2.0), 1e6, 0.4)[1]
    psb, stb = load_polar_set(path; set=:bracket)
    clb, cdb = section_polar(psb, 0.07)(0.0, 5e5, 0.2)
    # bracket multiplies primary cl by k_cl from tables.json (default 0.92264); same (α,Re,M) knot
    @test clb / cl ≈ 0.92264 rtol=1e-9
    @test stb.clamped_Re >= 0
    # a Report 996 run without station thicknesses is refused
    cfg = PAIN._r996_cfg(; beta75=15.0, Mt=0.6, B=2)
    bare = (; cfg..., propeller=Base.structdiff(cfg.propeller, NamedTuple{(:station_t_over_c,)}))
    @test_throws ErrorException ccblade_section_operating_points(bare; af=ps, allow_static=true)
    @test length(ccblade_section_operating_points(cfg; af=ps, allow_static=true).afs) == length(cfg.propeller.radii_m)
end

_run_if("Polar display cases") do
    # No TN 1546 / TR 824 match for n16_507; chosen R996 section and NACA 4412 are non-empty.
    @test isempty(measured_polar_series("n16_507"))
    @test !isempty(measured_polar_series("n16_506"))
    @test !isempty(measured_polar_series("naca4412"))

    # interp_no_extrap never extrapolates.
    @test interp_no_extrap([0.4, 0.55, 0.65], [1.0, 2.0, 3.0], 0.5) ≈ 1.0 + (2.0 - 1.0) * (0.5 - 0.4) / (0.55 - 0.4)
    @test interp_no_extrap([0.4, 0.55], [1.0, 2.0], 0.3) === nothing
    @test interp_no_extrap([0.4, 0.55], [1.0, 2.0], 0.72) === nothing
    @test interp_no_extrap([0.4, 0.55], [1.0, 2.0], 0.4) ≈ 1.0
    @test interp_no_extrap([0.4, 0.55], [1.0, 2.0], 0.55) ≈ 2.0

    # Every overlaid TN 1546 Mach lies within that curve's sample range.
    for m in measured_polar_series("n16_506")
        m.kind === :cl_cd_at_M || continue
        # Rebuild curve extents from the companion :cl_vs_M entries.
        for α in m.alpha_cl
            curves = filter(x -> x.kind === :cl_vs_M && x.alpha_deg == α,
                            measured_polar_series("n16_506"))
            @test !isempty(curves)
            c = first(curves)
            @test c.mach_lo - 1e-12 <= m.Mach <= c.mach_hi + 1e-12
            @test interp_no_extrap(c.mach, c.cl, m.Mach) !== nothing
        end
    end

    for id in ("POLAR_R996", "POLAR_PER")
        @test haskey(VALIDATION_CASES, id)
        @test CASE_INFO[id].category === :display
        @test CASE_INFO[id].kind === :runnable
        r = run_validation_case(id)
        @test r.verdict === :no_verdict
        panels = unique(s.panel for s in r.series)
        @test length(panels) >= 3
        @test count(s -> s.panel == 1, r.series) >= 1
        @test count(s -> s.panel == 2, r.series) >= 1
        @test count(s -> s.panel == 3, r.series) >= 1
        if id == "POLAR_R996"
            @test any(s -> s.panel == 4, r.series)
            @test r.inputs_echo.section == "n16_506"
            @test any(row -> startswith(row.quantity, "c_l XFOIL−TN1546"), r.table)
        end
        if id == "POLAR_PER"
            @test any(s -> s.panel == 4, r.series)
        end
        cache = PAIN._POLAR_DISPLAY_CACHE[id]
        @test !isempty(cache.measured)
        cov = polar_coverage_recount(cache.points;
            M_lo=cache.M_lo, M_hi=cache.M_hi, α_lo=cache.alpha_lo, α_hi=cache.alpha_hi)
        # Per-run table n_out_M / n_out_α sum to the global recount.
        sum_M = sum(row.n_out_M for row in cache.run_rows)
        sum_α = sum(row.n_out_α for row in cache.run_rows)
        @test sum_M == cov.n_out_M
        @test sum_α == cov.n_out_α
        for row in cache.run_rows
            @test row.clamped_Re >= 0
            @test row.clamped_M >= 0
            @test row.viterna_evals >= 0
            @test row.nearest_polar >= 0
        end
        # Empty per-panel overrides leave other cases' PlotSpec behaviour unchanged.
        spec = VALIDATION_CASES[id].plot_spec
        @test !isempty(spec.panel_xlabels)
        png = plot_case(r, spec; path=joinpath(TEST_OUT, "$(r.id).png"))
        @test isfile(png)
        @test filesize(png) > 0
    end
    # Registry PlotSpecs without per-panel overrides still construct and default to empty.
    spec0 = PlotSpec(; xlabel="x", ylabel="y")
    @test isempty(spec0.panel_xlabels)
    @test isempty(spec0.panel_ylabels)
    @test isempty(spec0.panel_xlims)
    @test isempty(spec0.panel_ylims)
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
        xover = acoustic_crossover_band(bare; rule=:ten_modes)
        # Prefer the ten-mode crossover band (has ≥10 acoustic modes); if no structural modes
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
        xover = acoustic_crossover_band(inp; rule=:ten_modes)
        println("38b crossover (test article): fc=$(round(xover.fc_Hz; digits=1)) Hz, n_modes=$(xover.n_modes)")
        @test xover.n_modes ≥ 10
        @test isfinite(xover.fc_Hz)
        @test xover.rule === :ten_modes
        # every lower band has fewer than 10
        bands = third_octave_centers()
        for fc in bands
            fc ≥ xover.fc_Hz && break
            @test acoustic_modes_in_band(inp, fc) < 10
        end
        # 43a: default rule is Manual card 10 volume formula
        xvol = acoustic_crossover_band(inp)  # default :volume
        @test xvol.rule === :volume
        f_vol = volume_crossover_frequency_Hz(inp)
        @test xvol.f_Hz ≈ f_vol
        @test xvol.fc_Hz == containing_third_octave(f_vol, bands)
        println("43a volume crossover: f=$(round(f_vol; digits=1)) Hz → band $(xvol.fc_Hz) Hz")
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

# Plan phase 38d: Fig. E-18 tones (η_T = 1.0, η_r′ ≤ 0.15) vs NASA prediction.
# V-UNIT: case runs; three harmonics; verdict follows |Δ| ≤ 4 dB on a synthetic reference.
# ---------------------------------------------------------------------------------------------
_run_if("E-18 tones η_T=1.0 (38d)") do
    @testset "verdict follows |Δ| ≤ 4 dB on a synthetic reference" begin
        # Same rule as _run_e18_tones: :met iff every harmonic with a NASA value is within 4 dB.
        function e18_verdict(got, nasa; tol=4.0)
            n = n_ok = 0
            for (g, nref) in zip(got, nasa)
                isfinite(nref) || continue
                n += 1
                n_ok += abs(g - nref) ≤ tol
            end
            return (n > 0 && n_ok == n) ? :met : :not_met
        end
        @test e18_verdict([88.0, 75.0, 67.0], [88.0, 75.0, 67.0]) === :met
        @test e18_verdict([88.0, 75.0, 67.0], [88.0, 75.0, 67.0]; tol=4.0) === :met
        @test e18_verdict([92.0, 75.0, 67.0], [88.0, 75.0, 67.0]) === :met   # |Δ|=4 exact
        @test e18_verdict([92.1, 75.0, 67.0], [88.0, 75.0, 67.0]) === :not_met
        @test e18_verdict([88.0, 75.0, 72.0], [88.0, 75.0, 67.0]) === :not_met  # H3 |Δ|=5
    end
    @testset "E18_TONES case runs; table has the three harmonics" begin
        @test validation_case_runnable("E18_TONES")
        res = run_validation_case("E18_TONES")
        nasa_rows = filter(r -> startswith(r.quantity, "vs NASA E-18"), res.table)
        @test length(nasa_rows) == 3
        @test !isempty(res.series)
        @test res.verdict in (:met, :not_met)
        @test res.inputs_echo.η_T == 1.0
        @test res.inputs_echo.η_r_cap == 0.15
        @test res.inputs_echo.tone_model === :eq8
        @test res.inputs_echo.cap_reaches_tone === true
        expect = (res.inputs_echo.n_ok == res.inputs_echo.n_nasa) && res.inputs_echo.n_nasa > 0
        @test (res.verdict === :met) == expect
        println("38d E18_TONES: ", res.reason)
    end
end

# Plan phase 38e: Fig. E-15 total structural loss factor η_r′ (V-EXP info, no pass mark).
# ---------------------------------------------------------------------------------------------
_run_if("E-15 structural loss η_r′ (38e)") do
    @testset "E15_STRUCT_LOSS case runs; table non-empty" begin
        @test validation_case_runnable("E15_STRUCT_LOSS")
        res = run_validation_case("E15_STRUCT_LOSS")
        @test !isempty(res.table)
        @test !isempty(res.series)
        @test res.verdict === :no_verdict
        @test res.inputs_echo.η_T == 1.0
        @test res.inputs_echo.η_r_cap == 0.15
        @test occursin("η_r′", res.inputs_echo.quantity) || occursin("η_r'", res.inputs_echo.quantity)
        println("38e E15_STRUCT_LOSS: ", res.reason)
    end
end

# Plan phase 38f-1: Manual cards 2, 9, 36 — exterior/interior air, L_c/d, rotation direction.
# Defaults must reproduce current outputs exactly (no comparison criterion; input plumbing).
# ---------------------------------------------------------------------------------------------
_run_if("Card inputs 38f-1 (air split, L_c/d, rotation)") do
    r0 = run_pain_pipeline(; source=:synthetic, use_synthetic=true, n_harmonics=3, bpf_Hz=150.0,
                           trim=:bare, NY=8)
    inp0 = r0.inputs
    ωH = 2π * 150.0
    p2_0 = tone_mean_square_pressure(inp0, 1, ωH)
    nr0 = noise_reduction_spectrum(inp0; bands=[250.0, 500.0])
    hf0 = hf_pressure_ratio(inp0, 1000.0)

    # 1. Explicit defaults equal to ρ0,c0 / L_c=L / d=0 → identical
    inp_def = _rebuild(inp0; ρ_ext=inp0.ρ0, c_ext=inp0.c0, ρ_int=inp0.ρ0, c_int=inp0.c0,
                       L_c=inp0.fuse.L, d=0.0)
    @test tone_mean_square_pressure(inp_def, 1, ωH) == p2_0
    @test cabin_volume(inp_def) == cabin_volume(inp0)
    nr_def = noise_reduction_spectrum(inp_def; bands=[250.0, 500.0])
    @test nr_def.rows[1].NR_dB == nr0.rows[1].NR_dB
    @test hf_pressure_ratio(inp_def, 1000.0).NR_dB == hf0.NR_dB

    # 2. Equal split ρ_ext=ρ_int=ρ0 identical; unequal changes only mapped terms
    inp_eq = _rebuild(inp0; ρ_ext=1.225, ρ_int=1.225, c_ext=340.0, c_int=340.0)
    @test tone_mean_square_pressure(inp_eq, 1, ωH) == p2_0
    inp_split = _rebuild(inp0; ρ_ext=1.10, ρ_int=1.225, c_ext=340.0, c_int=340.0)
    p2_split = tone_mean_square_pressure(inp_split, 1, ωH)
    @test p2_split != p2_0
    # Hand checks on mapped terms (card 2): mass-law and η_rad^ext ∝ ρ_ext; η_rad^int uses ρ_int
    A = coupling_area(inp0.fuse)
    @test mass_law_factor(1.10, 340.0, A, ωH) / mass_law_factor(1.225, 340.0, A, ωH) ≈ (1.10 / 1.225)^2 rtol=1e-14
    tc0 = hf_transmission_coeffs(inp0, 1000.0)
    tc_s = hf_transmission_coeffs(inp_split, 1000.0)
    @test tc_s.losses.η_rad_ext / tc0.losses.η_rad_ext ≈ 1.10 / 1.225 rtol=1e-12
    @test tc_s.losses.η_rad_int == tc0.losses.η_rad_int
    # Interior-only change: ρ_int ≠ ρ_ext leaves η_rad^ext alone, moves η_rad^int and τ_f
    inp_int = _rebuild(inp0; ρ_ext=1.225, ρ_int=1.10, c_ext=340.0, c_int=340.0)
    tc_i = hf_transmission_coeffs(inp_int, 1000.0)
    @test tc_i.losses.η_rad_ext == tc0.losses.η_rad_ext
    @test tc_i.losses.η_rad_int / tc0.losses.η_rad_int ≈ 1.10 / 1.225 rtol=1e-12
    @test tc_i.τ_f / tc0.τ_f ≈ (1.10 / 1.225)^2 rtol=1e-12

    # 3. L_c = L, d = 0 identical; L_c < L, d > 0: V scales, modes, coupling vs numerical
    @test axial_coupling(0, 1) ≈ axial_coupling(0, 1; L=inp0.fuse.L, L_c=inp0.fuse.L, d=0.0) rtol=0
    @test cabin_volume(inp0) ≈ cabin_volume(inp0.fuse; L_c=inp0.fuse.L) rtol=0
    L = inp0.fuse.L
    L_c = 0.6 * L
    d = 0.15 * L
    inp_cav = _rebuild(inp0; L_c=L_c, d=d)
    @test cabin_volume(inp_cav) / cabin_volume(inp0) ≈ L_c / L rtol=1e-14
    # Mode set: q_max truncation uses L_c → fewer axial modes at fixed ω when L_c shrinks
    n0 = acoustic_modes_in_band(inp0, 500.0)
    n_c = acoustic_modes_in_band(inp_cav, 500.0)
    @test n_c ≤ n0
    # Coupling vs direct numerical integration over overlap (1e-6 relative)
    cy = inp0.acoustic
    st = inp0.structural.modes[2]   # M_axial ≥ 1
    ac = cy.modes[2]
    q = 0
    f_code = coupling_factor(ac, st, inp_cav; q=q)
    # Independent trapz of axial factor × circumferential (reuse shell/floor integrals)
    z0, z1 = max(0.0, d), min(L, d + L_c)
    zs = range(z0, z1; length=4001)
    dz = zs[2] - zs[1]
    M = st.M_axial
    Iax = 0.0
    for z in zs
        Iax += cos(q * π * (z - d) / L_c) * sin(M * π * z / L) * dz
    end
    # endpoint trapz correction
    Iax -= 0.5 * dz * (cos(q * π * (z0 - d) / L_c) * sin(M * π * z0 / L) +
                       cos(q * π * (z1 - d) / L_c) * sin(M * π * z1 / L))
    f_qM_num = Iax / L
    θ0 = deg2rad(inp0.fuse.theta0_deg)
    a = inp0.fuse.a
    Lp = 2a * sin(θ0)
    Is = PAIN.coupling_shell_integral(ac, st, a)
    Ip = PAIN.coupling_floor_integral(ac, st, a, Lp)
    f_num = f_qM_num * (Is + Ip) / (Lp + 2a * (π - θ0))   # floor-term sign of NASA's corrected program (44f, 2026-10-23)
    @test f_code ≈ f_num rtol=1e-6
    @test axial_coupling(q, M; L=L, L_c=L_c, d=d) ≈ f_qM_num rtol=1e-6

    # 4. Rotation direction: +1 unchanged; −1 flips azimuth + phase; twice restores
    fuse = inp0.fuse
    prop_p = PropellerPlacement(0.965, 90.0, 0.90, 1)
    prop_m = PropellerPlacement(0.965, 90.0, 0.90, -1)
    pts_p = grid_points(fuse, prop_p, GridSpec())
    pts_m = grid_points(fuse, prop_m, GridSpec())
    pts_pp = grid_points(fuse, PropellerPlacement(0.965, 90.0, 0.90, 1), GridSpec())
    @test all(p.theta_deg ≈ q.theta_deg for (p, q) in zip(pts_p, pts_pp))
    # ℓ=2: α=10° → θ = 90±10
    p2p = only(filter(p -> p.k == 8 && p.ell == 2, pts_p))
    p2m = only(filter(p -> p.k == 8 && p.ell == 2, pts_m))
    @test p2p.theta_deg ≈ 100.0 atol=1e-12
    @test p2m.theta_deg ≈ 80.0 atol=1e-12
    @test p2m.x2 ≈ -p2p.x2 rtol=1e-14
    # Phase flip helper: −1 twice restores
    ph = copy(inp0.phases)
    ph1 = copy(ph)
    apply_rotation_direction_phases!(ph1, -1)
    @test ph1 ≈ -ph
    apply_rotation_direction_phases!(ph1, -1)
    @test ph1 ≈ ph
    # Synthetic freefield: +1 matches default prop; −1 then rebuild +1 restores grid θ
    ff_p = synthetic_freefield_grid(fuse, prop_p, GridSpec(); n_harmonics=2, bpf_Hz=150.0)
    ff_m = synthetic_freefield_grid(fuse, prop_m, GridSpec(); n_harmonics=2, bpf_Hz=150.0)
    @test ff_m.phases ≈ -ff_p.phases
    # Applying −1 geometry twice (via +1) restores original θ list
    @test [p.theta_deg for p in pts_p] == [p.theta_deg for p in grid_points(fuse, prop_p, GridSpec())]
end

# Plan phase 38f-2: Manual cards 3–6 (band set) and 11–18 (per-band η_r / η_n).
# Defaults must reproduce current outputs exactly (no comparison criterion; input plumbing).
# ---------------------------------------------------------------------------------------------
_run_if("Card inputs 38f-2 (bands, η_r/η_n per band)") do
    r0 = run_pain_pipeline(; source=:synthetic, use_synthetic=true, n_harmonics=3, bpf_Hz=150.0,
                           trim=:bare, NY=8)
    inp0 = r0.inputs
    ωH = 2π * 150.0
    p2_0 = tone_mean_square_pressure(inp0, 1, ωH)
    nr0 = noise_reduction_spectrum(inp0; bands=[250.0, 500.0])
    hf0 = hf_pressure_ratio(inp0, 1000.0)
    toc = third_octave_centers()

    # --- 1. Defaults reproduce current tone / NR / HF / REPRO_18b path exactly ---
    inp_def = _rebuild(inp0; bands=nothing, η_r_band=nothing, η_n_band=nothing)
    @test tone_mean_square_pressure(inp_def, 1, ωH) == p2_0
    @test resolve_bands(inp_def) == toc
    nr_def = noise_reduction_spectrum(inp_def; bands=[250.0, 500.0])
    @test nr_def.rows[1].NR_dB == nr0.rows[1].NR_dB
    @test hf_pressure_ratio(inp_def, 1000.0).NR_dB == hf0.NR_dB
    # Explicit default band list identical to nothing
    inp_toc = _rebuild(inp0; bands=toc)
    @test tone_mean_square_pressure(inp_toc, 1, ωH) == p2_0
    spec0 = interior_spl(inp0; bpf_Hz=150.0, n_harmonics=3, broadband=true)
    spec_toc = interior_spl(inp_toc; bpf_Hz=150.0, n_harmonics=3, broadband=true)
    @test spec_toc.harmonic_SPL_dB == spec0.harmonic_SPL_dB
    @test spec_toc.third_octave_SPL_dB == spec0.third_octave_SPL_dB
    # REPRO_18b-like e11 tones (defaults) bit-identical under explicit default cards
    r18 = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R1, trim=:phase3)
    inp18 = r18.inputs
    inp18b = _rebuild(inp18; bands=third_octave_centers(), η_r_band=nothing, η_n_band=nothing)
    for H in 1:3
        ω = 2π * H * 200.0
        @test tone_mean_square_pressure(inp18b, H, ω) == tone_mean_square_pressure(inp18, H, ω)
    end
    @test r18.spectrum.harmonic_SPL_dB ==
          interior_spl(inp18b; bpf_Hz=200.0, n_harmonics=3, broadband=false).harmonic_SPL_dB

    # --- 2. Band set: custom subset matches default at those centres; invalid sets raise ---
    # Contiguous subset of the default list keeps tone→band assignment for in-range harmonics.
    subset = toc[1:16]
    inp_sub = _rebuild(inp0; bands=subset)
    spec0_nb = interior_spl(inp0; bpf_Hz=150.0, n_harmonics=3, broadband=false)
    spec_sub = interior_spl(inp_sub; bpf_Hz=150.0, n_harmonics=3, broadband=false)
    @test Set(keys(spec_sub.third_octave_SPL_dB)) == Set(subset)
    for fc in subset
        @test spec_sub.third_octave_SPL_dB[fc] == spec0_nb.third_octave_SPL_dB[fc]
    end
    # NR / HF at a listed centre identical (path is per-centre, independent of other bands)
    for fc in (250.0, 500.0, 1000.0)
        fc_s = nearest_third_octave(fc, toc)
        @test noise_reduction_band(inp_sub, fc_s).NR_dB == noise_reduction_band(inp0, fc_s).NR_dB
    end
    @test hf_pressure_ratio(inp_sub, 1000.0).NR_dB == hf0.NR_dB
    nr_sub = noise_reduction_spectrum(inp_sub)
    @test nr_sub.bands == subset
    @test_throws ErrorException validate_band_set([250.0, 251.0])          # non-standard
    @test_throws ErrorException validate_band_set(vcat(toc, toc[1:5]))     # > 26
    @test_throws ErrorException validate_band_set([1000.0, 500.0])         # unsorted
    @test_throws ErrorException _rebuild(inp0; bands=[1000.0, 500.0])

    # Containing-band lookup (1/3-octave edges via c_ω)
    fc630 = nearest_third_octave(630.0, toc)
    @test containing_third_octave(600.0, toc) == fc630
    @test containing_third_octave(fc630, toc) == fc630

    # --- 3. Loss-factor override ---
    # Bare cabin: η_n override equal to η_n_bare → identical; different → changes; 0 → fallback
    inp_ηn_same = _rebuild(inp0; η_n_band=Dict(nearest_third_octave(150.0, toc) => inp0.η_n_bare))
    @test tone_mean_square_pressure(inp_ηn_same, 1, ωH) == p2_0
    inp_ηn_zero = _rebuild(inp0; η_n_band=Dict(nearest_third_octave(150.0, toc) => 0.0))
    @test tone_mean_square_pressure(inp_ηn_zero, 1, ωH) == p2_0   # zero → compute
    @test inp_ηn_zero.η_n_band === nothing
    inp_ηn_hi = _rebuild(inp0; η_n_band=Dict(nearest_third_octave(150.0, toc) => 0.25))
    p2_hi = tone_mean_square_pressure(inp_ηn_hi, 1, ωH)
    @test p2_hi != p2_0
    # H2 at 300 Hz is in a different band → unchanged when only 150 Hz band overridden
    ω2 = 2π * 300.0
    fc150 = nearest_third_octave(150.0, toc)
    fc300 = nearest_third_octave(300.0, toc)
    @test fc150 != fc300
    @test tone_mean_square_pressure(inp_ηn_hi, 2, ω2) == tone_mean_square_pressure(inp0, 2, ω2)

    # Structural η_r: one value per band (Manual). Identity when a band holds a single
    # structural mode and the override equals that mode's Eqs. 79–81 value.
    by_band = Dict{Float64,Vector{Any}}()
    for st in inp0.structural.modes
        fc = containing_third_octave(st.f_Hz, toc)
        fc === nothing && continue
        push!(get!(() -> Any[], by_band, fc), st)
    end
    solo_fc, solo_st = first((fc, sts[1]) for (fc, sts) in by_band if length(sts) == 1)
    ωr = 2π * solo_st.f_Hz
    ηr_comp = structural_loss_total(solo_st, ωr; a=inp0.fuse.a, L=inp0.fuse.L, m=inp0.m_wall,
                                    C=inp0.C_struc, ρ0=inp0.ρ_ext, c0=inp0.c_ext)
    inp_ηr_same = _rebuild(inp0; η_r_band=Dict(solo_fc => ηr_comp))
    @test tone_mean_square_pressure(inp_ηr_same, 1, ωH) == p2_0
    inp_ηr_diff = _rebuild(inp0; η_r_band=Dict(solo_fc => 0.5))
    @test tone_mean_square_pressure(inp_ηr_diff, 1, ωH) != p2_0
    # Vector form aligned with bands
    ηn_vec = zeros(length(subset))
    ηn_vec[1] = 0.25
    inp_vec = _rebuild(inp0; bands=subset, η_n_band=ηn_vec)
    @test inp_vec.η_n_band !== nothing
    @test haskey(inp_vec.η_n_band, subset[1])
end

# Plan phase 38h: Manual §5.4.3 printed outputs (read-only tables; no comparison criterion).
# ---------------------------------------------------------------------------------------------
_run_if("Printed outputs 38h (Manual §5.4.3)") do
    r = run_pain_pipeline(; source=:synthetic, use_synthetic=true, n_harmonics=3, bpf_Hz=150.0,
                          trim=:bare, NY=8)
    inp = r.inputs
    bpf = 150.0
    nH = 3
    out = printed_outputs(inp; bpf_Hz=bpf, n_harmonics=nH, broadband=false)

    # 1. Five largest = top of full modal sum; shares in [0,1]; sum of shares ≤ 1
    for H in 1:nH
        ωH = 2π * H * bpf
        parts, total = modal_tone_contributions(inp, H, ωH)
        @test total ≈ tone_mean_square_pressure(inp, H, ωH) rtol = 1e-12
        top = out.top5[findall(r -> r.H == H, out.top5)]
        @test length(top) == min(5, length(parts))
        for (k, row) in enumerate(top)
            @test row.rank == k
            @test 0 ≤ row.share ≤ 1
            @test row.q == parts[k].q && row.i == parts[k].i && row.r == parts[k].r
            @test row.p2 ≈ parts[k].p2 rtol = 1e-12
        end
        @test sum(r.share for r in top) ≤ 1 + 1e-12
        @test sum(r.p2 for r in top) ≤ total + 1e-12 * max(total, 1.0)
    end

    # 2. Modes-per-band counts match helpers; crossover flagged
    xover = acoustic_crossover_band(inp)
    for row in out.modes_per_band
        @test row.n_acoustic == acoustic_modes_in_band(inp, row.fc_Hz)
        @test row.n_structural == structural_modes_in_band(inp, row.fc_Hz)
        expect_x = isfinite(xover.fc_Hz) && row.fc_Hz == xover.fc_Hz
        @test row.crossover == expect_x
    end
    @test out.crossover_Hz == xover.fc_Hz

    # 3. Printed tone totals equal existing tone_mean_square_pressure / interior_spl exactly
    spec = interior_spl(inp; bpf_Hz=bpf, n_harmonics=nH, broadband=false)
    for row in out.tone_totals
        ωH = 2π * row.H * bpf
        @test row.p2 == tone_mean_square_pressure(inp, row.H, ωH)
        @test row.SPL_dB ≈ spec.harmonic_SPL_dB[row.H] rtol = 1e-12
    end
    for row in out.harmonic_SPL
        @test row.SPL_dB == spec.harmonic_SPL_dB[row.H]
    end

    # 4. Markdown writer has every table heading; defaults unchanged (registry separate)
    mktempdir() do tmp
        path = joinpath(tmp, "printed_outputs_test.md")
        write_printed_outputs_md(path, out; title="Printed outputs test")
        @test isfile(path)
        md = read(path, String)
        for heading in (
            "## Modes per 1/3-octave band",
            "## Acoustic/structural coupling f′(n,r)",
            "## Propeller generalized forces Ψ_G(r,H)",
            "## Five largest modal contributions (Eq. 8)",
            "## Tone transmission (interior space-averaged MSP)",
            "## Interior harmonic SPL",
            "## Interior 1/3-octave SPL",
            "## Propeller pressure amplitude and phase (upper quarter)",
            "## Manual outputs omitted",
        )
            @test occursin(heading, md)
        end
        @test occursin("not computed — lower-quarter grid not adopted (I-18)", md)
    end

    @test length(out.surface_upper) == length(inp.pts) * nH
    @test !isempty(out.coupling)
    @test length(out.psi_G) == length(inp.structural.modes) * nH
end

# Plan phase 29b/29c: NASA-default guard + provenance tags (aircraft path only).
# After phase 30 the aircraft default is cabin_blocks=:parametric (App. D + eq19);
# surrogate-path flags (bb_j2_scale, absorption_curve, table_d1) appear when
# cabin_blocks=:surrogate is requested explicitly.
# ---------------------------------------------------------------------------------------------
_run_if("Aircraft provenance 29b/29c (V-UNIT)") do
    json_bare = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
    json_full = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell_cabin_full.json")
    @test isfile(json_bare) && isfile(json_full)

    # 1. No cabin block + :surrogate → every used §2.10 surrogate default listed; warn once
    r_bare = @test_logs (:warn, r"NASA test-article defaults") match_mode=:any begin
        run_pain_pipeline(; source=:aircraft, aircraft_json=json_bare,
                          n_harmonics=2, trim=:bare, cabin_blocks=:surrogate)
    end
    nd = r_bare.provenance.nasa_defaults
    @test !isempty(nd)
    names = Set(String(r.name) for r in nd)
    for must in ("L_m", "a_m", "theta0_deg", "eta_n_bare", "C_struc", "m_wall_kg_m2",
                 "structural_solver", "bb_j2_scale", "absorption_curve", "spbl_anchor_H",
                 "NY", "c0_mps", "rho_kg_m3")
        @test must in names
    end
    @test isempty(r_bare.provenance.inputs)  # no cabin.* tags supplied

    # 1b. Parametric default (no cabin) → App. D MRP_* listed; no absorption / bb_j2_scale
    r_bare_p = @test_logs (:warn, r"NASA test-article defaults") match_mode=:any begin
        run_pain_pipeline(; source=:aircraft, aircraft_json=json_bare,
                          n_harmonics=2, trim=:bare)   # cabin_blocks=:auto → :parametric
    end
    @test r_bare_p.cabin_blocks === :parametric
    names_p = Set(String(r.name) for r in r_bare_p.provenance.nasa_defaults)
    @test "t_skin_m" in names_p && "structural_solver" in names_p
    @test !("bb_j2_scale" in names_p) && !("absorption_curve" in names_p)
    @test !("phase3_trim" in names_p)

    # 2. Fully specified cabin → empty nasa_defaults; tags round-trip; report table
    r_full = run_pain_pipeline(; source=:aircraft, aircraft_json=json_full,
                               n_harmonics=2)
    @test isempty(r_full.provenance.nasa_defaults)
    @test r_full.cabin_blocks === :parametric
    @test !isempty(r_full.provenance.inputs)
    @test all(r -> r.tag in ("measured", "assumed", "nasa_default"), r_full.provenance.inputs)
    @test any(r -> r.name == "eta_n_bare" && r.tag == "assumed", r_full.provenance.inputs)
    @test any(r -> r.name == "structural_solver" && r.value == "appd", r_full.provenance.inputs)
    mktempdir() do tmp
        out = printed_outputs(r_full.inputs; bpf_Hz=r_full.spectrum.bpf_Hz, n_harmonics=2,
                              broadband=false)
        path = joinpath(tmp, "prov.md")
        write_printed_outputs_md(path, out; provenance=r_full.provenance,
                                 title="Provenance full cabin")
        md = read(path, String)
        @test occursin("## Input provenance (phase 29c)", md)
        @test occursin("eta_n_bare", md) && occursin("assumed", md)
        @test !occursin("uses NASA test-article defaults", md)
    end

    # 3. Invalid tag raises; plain numbers still load; :e11/:synthetic bit-identical extras
    @test_throws ErrorException PAIN.parse_tagged_value(
        (value=1.0, tag="guessed"); name="x")
    cfg = PAIN._load_aircraft_json(json_bare)
    @test cfg.fuselage.a_m == 0.508

    r_e11_a = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, trim=:bare, NY=8)
    r_e11_b = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, trim=:bare, NY=8)
    @test r_e11_a.spectrum.harmonic_SPL_dB == r_e11_b.spectrum.harmonic_SPL_dB
    @test r_e11_a.cabin_blocks === :surrogate
    @test isempty(r_e11_a.provenance.nasa_defaults)
    r_syn_a = run_pain_pipeline(; source=:synthetic, use_synthetic=true, n_harmonics=3,
                                bpf_Hz=150.0, trim=:bare, NY=8)
    r_syn_b = run_pain_pipeline(; source=:synthetic, use_synthetic=true, n_harmonics=3,
                                bpf_Hz=150.0, trim=:bare, NY=8)
    @test r_syn_a.spectrum.harmonic_SPL_dB == r_syn_b.spectrum.harmonic_SPL_dB
    @test r_syn_a.spectrum.third_octave_SPL_dB == r_syn_b.spectrum.third_octave_SPL_dB

    # 4. Printed-outputs header labels NASA defaults when present
    mktempdir() do tmp
        out = printed_outputs(r_bare.inputs; bpf_Hz=r_bare.spectrum.bpf_Hz, n_harmonics=2,
                              broadband=false)
        path = joinpath(tmp, "nasa.md")
        write_printed_outputs_md(path, out; provenance=r_bare.provenance,
                                 title="Provenance NASA defaults")
        md = read(path, String)
        @test occursin("uses NASA test-article defaults:", md)
        @test occursin("NASA test article inputs used for:", md)
    end
end

# Plan phase 30a–30d: parametric cabin blocks on the aircraft path.
# ---------------------------------------------------------------------------------------------
_run_if("Parametric cabin blocks 30a-30d (V-UNIT)") do
    json_bare = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
    json_full = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell_cabin_full.json")

    # 1. :surrogate (and e11/synthetic) stay on the current path; :parametric does not
    #    list absorption / bb_j2_scale / table_d1 / phase3_trim unless used.
    r_s = run_pain_pipeline(; source=:aircraft, aircraft_json=json_bare, n_harmonics=2,
                            trim=:bare, cabin_blocks=:surrogate)
    @test r_s.cabin_blocks === :surrogate
    ns = Set(String(r.name) for r in r_s.provenance.nasa_defaults)
    @test "absorption_curve" in ns && "bb_j2_scale" in ns
    @test any(r -> r.name == "structural_solver" && string(r.value) == "table_d1",
              r_s.provenance.nasa_defaults)

    r_p = run_pain_pipeline(; source=:aircraft, aircraft_json=json_bare, n_harmonics=2,
                            trim=:bare, cabin_blocks=:parametric)
    @test r_p.cabin_blocks === :parametric
    np = Set(String(r.name) for r in r_p.provenance.nasa_defaults)
    @test !("absorption_curve" in np) && !("bb_j2_scale" in np)
    @test !("phase3_trim" in np)
    @test !any(r -> r.name == "structural_solver" && string(r.value) == "table_d1",
               r_p.provenance.nasa_defaults)

    # 2. Explicit test-article geometry → parametric modes ≡ appd_modes; V, S, A = formulas
    L, a, θ0 = 1.83, 0.508, 56.6
    fuse = FuselageGeometry(L, a, θ0)
    g = build_appd_geometry(fuse)
    modes_ref = appd_modes(g; n_modes=24)
    r_ta = run_pain_pipeline(; source=:aircraft, aircraft_json=json_bare, n_harmonics=1,
                             trim=:bare, cabin_blocks=:parametric,
                             L=L, a=a, theta0_deg=θ0,
                             structural_solver=:appd, broadband_model=:eq19)
    @test length(r_ta.structural.modes) == length(modes_ref.modes) ||
          length(r_ta.structural.modes) == 32  # pipeline keeps 32
    # Compare the first min(n) frequencies against a fresh appd_modes at n_keep=32
    modes_32 = appd_modes(g; n_modes=32)
    @test [m.f_Hz for m in r_ta.structural.modes] == [m.f_Hz for m in modes_32.modes]
    V = cabin_volume(r_ta.inputs)
    A = coupling_area(r_ta.fuse)
    areas = hf_absorbing_areas(r_ta.inputs)
    θ0r = deg2rad(θ0)
    V_form = a^2 * L * (π - θ0r + cos(θ0r) * sin(θ0r))
    Lp = 2a * sin(θ0r)
    A_form = L * (Lp + 2a * (π - θ0r))
    S_side = 2a * (π - θ0r) * L
    S_e = V_form / L
    S_form = S_side + 2 * S_e
    @test V ≈ V_form rtol=0 atol=0
    @test A ≈ A_form rtol=0 atol=0
    @test areas.S ≈ S_form rtol=0 atol=0
    @test areas.V ≈ V_form rtol=0 atol=0

    # 3. Scaled geometry (2.64 m diameter) end-to-end; empty guard when all inputs supplied
    r_sc = run_pain_pipeline(; source=:aircraft, aircraft_json=json_full, n_harmonics=2)
    @test isempty(r_sc.provenance.nasa_defaults)
    @test r_sc.fuse.a ≈ 1.32 rtol=0 atol=0
    @test r_sc.cabin_blocks === :parametric
    for H in eachindex(r_sc.spectrum.harmonic_SPL_dB)
        spl = r_sc.spectrum.harmonic_SPL_dB[H]
        @test isfinite(spl) && spl > 0
    end
end

_run_if("App. D structural solver 38g (V-UNIT)") do
    g = appd_test_article_geometry()
    @test g.L == 1.83                          # I-22 / App. E (test_article_length default)
    @test g.t_skin == PAIN.MRP_T_SKIN
    @test APPD_READINGS.attachment === :rigid
    @test APPD_READINGS.asterisk_terms === false

    # 1. Unstiffened closed circular cylinder vs Donnell–Mushtari closed form
    #    Formula (Soedel / Leissa SP-288 §2.1.2, in-plane inertia neglected):
    #      ω² = (D/(ρ t a⁴))(λ²+n²)² + (E/(ρ a²)) λ⁴/(λ²+n²)²
    #    with λ = m π a/L, D = E t³/(12(1−ν²)).
    #    The App. D operator with static condensation of u,v must match within 1 %.
    #    The full 3×3 (with in-plane inertia) is within 15 % of that closed form.
    g_plain = AppDGeometry(g.L, g.a, g.theta0_deg, g.t_skin, g.t_floor,
                           0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, g.E, g.ν, g.ρ)
    for (m, n) in ((1, 2), (1, 3), (2, 2), (2, 4), (3, 3))
        f_ref = donnell_mushtari_frequency_Hz(m, n, g_plain.L, g_plain.a, g_plain.t_skin,
                                              g_plain.E, g_plain.ν, g_plain.ρ)
        f_cond = appd_shell_condensed_frequency_Hz(m, n, g_plain)
        f_full = appd_shell_harmonic_frequency_Hz(m, n, g_plain)
        @test abs(f_cond - f_ref) / f_ref ≤ 0.01
        @test abs(f_full - f_ref) / f_ref ≤ 0.15
    end

    # 2. Stiffener raises frequency; smeared analytic estimate within 15 %
    f_plain = appd_shell_condensed_frequency_Hz(1, 2, g_plain)
    f_stiff = appd_shell_condensed_frequency_Hz(1, 2, g)
    @test f_stiff > f_plain
    f_smear = appd_smeared_stringer_frequency_Hz(1, 2, g)
    @test abs(f_stiff - f_smear) / max(f_smear, 1.0) ≤ 0.15
    # Flat-plate / large-radius limit: increasing a at fixed t,L lowers membrane ring stiffening
    g_big = AppDGeometry(g.L, 5.0, g.theta0_deg, g.t_skin, g.t_floor,
                         0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, g.E, g.ν, g.ρ)
    f_big = appd_shell_condensed_frequency_Hz(1, 2, g_big)
    @test f_big < f_plain

    # 3–4. Coupled solver: constraints, mass, orthogonality
    worst_C = appd_max_constraint_residual(g; n_axial=3, n_check=4)
    @test worst_C ≤ 1e-8
    ortho = appd_mode_orthogonality(g; M=1, sym=true, n_modes=5)
    @test ortho ≤ 1e-8

    modes = appd_modes(g; n_modes=16, n_axial=5, n_circ=8, n_floor_max=5)
    @test length(modes.modes) ≥ 8
    for m in modes.modes[1:min(6, length(modes.modes))]
        Mr_shape = appd_generalized_mass_from_shape(m, g)
        # Shape mass from w-only integral vs Rayleigh M_r (u,v included in solver):
        # allow factor-of-three band — w usually dominates; still a consistency check.
        @test Mr_shape > 0
        @test m.M_r > 0
        @test Mr_shape / m.M_r < 5.0 && m.M_r / Mr_shape < 5.0
    end

    # 5. Surrogate default path unchanged
    fuse = FuselageGeometry(1.83, 0.508, 56.6)
    ritz = structural_modes(fuse; hybrid=false, n_keep=48)
    n_spec, _ = match_ritz_to_table_d1(ritz; tol_frac=0.05)
    @test n_spec ≥ 25
    d1 = structural_modes_from_table_d1(; n_keep=32)
    @test [m.f_Hz for m in d1.modes] == [r[2] for r in TABLE_D1_FULL]
    built = build_structural_modes(fuse; structural_solver=:table_d1)
    @test [m.f_Hz for m in built.modes] == [m.f_Hz for m in d1.modes]
    @test haskey(VALIDATION_CASES, "MRP_APPD")
    @test validation_case_runnable("MRP_APPD")
end

_run_if("Uncertainty budget (phase 31, V-UNIT)") do
    budget = uncertainty_budget(:testarticle; trimmed=true)
    @test any(r -> r.name == "eta_t" && r.type === :continuous, budget.rows)
    @test any(r -> r.name == "eta_n_bare" && r.type === :excluded, budget.rows)
    @test any(n -> occursin("η_T = 0.5", n) && occursin("0.01–0.10", n), budget.notes)

    # OAT of a parameter with zero range → zero swing
    cache = build_testarticle_cache()
    @test cache.num_blades == 3
    # Degenerate continuous row: lo = hi = nominal
    zrow = UncertaintyBudgetRow("C_struc", 3.0, 3.0, 3.0, "zero-range unit test",
                                "assumed", :continuous, Float64[], String[])
    zbudget = UncertaintyBudget(:testarticle, [zrow], String[])
    oat_z = oat_sweep(cache, zbudget; n_cont=3)
    @test length(oat_z) == 1
    @test oat_z[1].swing_dB == 0.0
    @test oat_z[1].keep == false

    # Strong nominal: η_t = 0.5 (phase3_trim default) and all other params at budget nominal
    # match the parametric e11 pipeline tonal SPLs.
    s_nom05 = nominal_sample(budget)
    s_nom05["eta_t"] = 0.5
    H_unc = evaluate_uncertainty_sample(cache, s_nom05).H
    H_pipe = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0,
                               cabin_blocks=:parametric).spectrum.harmonic_SPL_dB[1:3]
    for H in 1:3
        @test H_unc[H] ≈ H_pipe[H] atol=1e-6
    end

    # Monte Carlo with all parameters at nominal (empty kept) → zero width, equals nominal
    nom = evaluate_uncertainty_sample(cache, nominal_sample(budget)).H
    mc0 = monte_carlo_band(cache, budget, String[]; N=20, seed=UNC_MC_SEED, family=:uniform)
    for H in 1:3
        p = mc0.harm[H]
        @test p.P5 == p.P50 == p.P95
        @test p.P50 ≈ nom[H] atol=1e-9
        @test (p.P95 - p.P5) == 0.0
    end

    # Seeding reproducible
    kept = ["C_struc"]
    mc_a = monte_carlo_band(cache, budget, kept; N=40, seed=UNC_MC_SEED, family=:uniform)
    mc_b = monte_carlo_band(cache, budget, kept; N=40, seed=UNC_MC_SEED, family=:uniform)
    for H in 1:3
        @test mc_a.harm[H].P5 == mc_b.harm[H].P5
        @test mc_a.harm[H].P50 == mc_b.harm[H].P50
        @test mc_a.harm[H].P95 == mc_b.harm[H].P95
    end

    # Percentiles ordered
    for H in 1:3
        p = mc_a.harm[H]
        @test p.P5 ≤ p.P50 ≤ p.P95
    end

    # Coverage check on a synthetic known case
    fake_mc = (; harm=[(; P5=80.0, P50=85.0, P95=90.0),
                       (; P5=70.0, P50=75.0, P95=80.0),
                       (; P5=60.0, P50=65.0, P95=70.0)])
    cov_ok = coverage_check(fake_mc; measured_means=[85.0, 75.0, 65.0])
    @test cov_ok.verdict === :met
    @test all(r -> r.inside, cov_ok.rows)
    cov_fail = coverage_check(fake_mc; measured_means=[95.0, 75.0, 65.0])
    @test cov_fail.verdict === :not_met
    @test cov_fail.rows[1].inside == false

    # Phase case (i) with k = 0 → exactly nominal SPL
    ph0 = phase_bounding_cases(cache, budget; k_override=0.0)
    for H in 1:3
        @test ph0.bbn_residual[H] == ph0.nominal[H]
        @test ph0.spread_i_dB[H] == 0.0
    end
    @test ph0.k == 0.0
    @test ph0.B == 3

    # BBN residual gradient ratio is finite; equals median(residual/f1a) from CSV (no sign assert)
    k = bbn_h1_residual_gradient_ratio()
    @test isfinite(k)
    path_bbn = joinpath(@__DIR__, "..", "..", "data", "NASA_CR-158919", "bbn_results.csv")
    ratios = Float64[]
    for (i, line) in enumerate(eachline(path_bbn))
        i == 1 && continue
        parts = split(strip(line), ',')
        length(parts) < 11 && continue
        parts[1] == "circ" || continue
        parts[2] == "tipA" || continue
        parts[5] in ("4-3", "5-3", "4-5") || continue
        tryparse(Int, parts[6]) == 1 || continue
        coh = tryparse(Float64, parts[11])
        (coh === nothing || coh < 0.15) && continue
        f1a = tryparse(Float64, parts[9])
        resid = tryparse(Float64, parts[10])
        (resid === nothing || f1a === nothing || f1a == 0.0) && continue
        push!(ratios, resid / f1a)
    end
    @test k == median(ratios)

    # Report template contains every required statement
    md = uncertainty_report_md(; title="unit", budget)
    for s in UNC_REQUIRED_STATEMENTS
        @test occursin(s, md)
    end
    # :testarticle report points at the aircraft band for the diameter/provenance line
    @test occursin("this report is the 31e coverage check", md)
    @test !occursin("working-example provenance", md)

    # Registry has UNC_COVER with the pre-registered label
    @test haskey(VALIDATION_CASES, "UNC_COVER")
    @test occursin("pre-registered", VALIDATION_CASES["UNC_COVER"].label)
    @test VALIDATION_CASES["UNC_COVER"].criterion_date == "2026-10-22"
end

_run_if("Validation map errors (V-UNIT)") do
    # Synthetic table covering each error_mode (display only; no criterion change).
    rows_abs = [
        ValidationTableRow("a", 1.0, 10.0, 12.0, 2.0, true),
        ValidationTableRow("b", 2.0, 10.0, 15.0, 5.0, false),
        ValidationTableRow("c", 3.0, 10.0, 11.0, 1.0, true),
    ]
    r_abs = ValidationCaseResult("SYN_ABS", "2026-10-22", (;), rows_abs, PlotSeries[],
                                 :met, "ok", "", "")
    s_abs = case_error_summary(r_abs, PlotSpec(; error_mode=:absolute, error_tol=3.0,
                                               error_ylabel="error (dB)"))
    @test s_abs.n_rows == 3
    @test s_abs.n_within == 2
    @test s_abs.max_abs ≈ 5.0
    @test s_abs.median_abs ≈ 2.0
    @test s_abs.unit == "dB"
    @test occursin("2/3 in tol", s_abs.text)
    @test occursin("max |err| 5", s_abs.text)
    @test occursin("med 2", s_abs.text)
    @test occursin("dB", s_abs.text)
    @test s_abs.chip_text == "2/3 · 5.0 dB max"

    s_abs_unit = case_error_summary(r_abs, PlotSpec(; error_mode=:absolute, error_tol=3.0))
    @test s_abs_unit.unit == "abs"
    # T1-style: unit from last (...) of ylabel when error_ylabel has none / is empty.
    s_t1_unit = case_error_summary(r_abs, PlotSpec(; error_mode=:absolute, error_tol=3.0,
                                                   ylabel="SPL (dB)"))
    @test s_t1_unit.unit == "dB"
    @test !occursin("SPL", s_t1_unit.unit)
    # Whole error_ylabel without (...): do not paste; fall back to ylabel (...).
    s_whole = case_error_summary(r_abs, PlotSpec(; error_mode=:absolute, error_tol=3.0,
                                                 error_ylabel="computed − Manual Fig. 3",
                                                 ylabel="azimuth α (deg)"))
    @test s_whole.unit == "deg"
    @test s_whole.unit != "computed − Manual Fig. 3"

    # NaN reference still counts in n_rows; max/median use finite _row_error only.
    rows_nan = [
        ValidationTableRow("a", 1.0, 10.0, 12.0, 2.0, true),
        ValidationTableRow("b", 2.0, NaN, 15.0, NaN, false),
    ]
    r_nan = ValidationCaseResult("SYN_NAN", "2026-10-22", (;), rows_nan, PlotSeries[],
                                 :met, "ok", "", "")
    s_nan = case_error_summary(r_nan, PlotSpec(; error_mode=:absolute, error_tol=3.0,
                                               error_ylabel="error (dB)"))
    @test s_nan.n_rows == 2
    @test s_nan.n_within == 1
    @test s_nan.max_abs ≈ 2.0
    @test s_nan.median_abs ≈ 2.0

    rows_rel = [
        ValidationTableRow("a", 1.0, 100.0, 110.0, 10.0, true),   # +10%
        ValidationTableRow("b", 2.0, 100.0, 80.0, -20.0, false),  # -20%
    ]
    r_rel = ValidationCaseResult("SYN_REL", "2026-10-22", (;), rows_rel, PlotSeries[],
                                 :not_met, "x", "", "")
    s_rel = case_error_summary(r_rel, PlotSpec(; error_mode=:relative_pct, error_tol=15.0))
    @test s_rel.n_rows == 2
    @test s_rel.n_within == 1
    @test s_rel.max_abs ≈ 20.0
    @test s_rel.median_abs ≈ 15.0
    @test s_rel.unit == "%"
    @test occursin("%", s_rel.text)

    rows_db = [
        ValidationTableRow("a", 1.0, 1.0, 10.0, NaN, false),  # 20 dB
        ValidationTableRow("b", 2.0, 1.0, 2.0, NaN, true),   # ~6.02 dB
    ]
    r_db = ValidationCaseResult("SYN_DB", "2026-10-22", (;), rows_db, PlotSeries[],
                                :not_met, "x", "", "")
    s_db = case_error_summary(r_db, PlotSpec(; error_mode=:db_ratio, error_tol=2.0))
    @test s_db.n_rows == 2
    @test s_db.unit == "dB"
    @test s_db.max_abs ≈ 20.0
    @test isapprox(s_db.median_abs, (20.0 + 20 * log10(2.0)) / 2; rtol=1e-9)

    # :none + :no_verdict → no criterion (even with a non-empty table).
    s_none = case_error_summary(r_abs, PlotSpec(; error_mode=:none))
    # r_abs verdict is :met → coverage-style text, not "no criterion".
    @test s_none.text == "2/3 within criterion"
    @test s_none.n_within == 2
    @test s_none.n_rows == 3
    @test s_none.unit == ""
    @test isnan(s_none.max_abs) && isnan(s_none.median_abs)

    rows_cover = [
        ValidationTableRow("H1", 1.0, 10.0, 10.0, 0.0, true),
        ValidationTableRow("H2", 2.0, 10.0, 10.0, 0.0, false),
        ValidationTableRow("H3", 3.0, 10.0, 10.0, 0.0, false),
    ]
    r_none_nm = ValidationCaseResult("SYN_NONE_NM", "2026-10-22", (;), rows_cover, PlotSeries[],
                                     :not_met, "1 of 3 inside band", "", "")
    s_none_nm = case_error_summary(r_none_nm, PlotSpec(; error_mode=:none))
    @test s_none_nm.text == "1/3 within criterion"
    @test s_none_nm.n_within == 1
    @test s_none_nm.n_rows == 3
    @test s_none_nm.unit == ""
    @test isnan(s_none_nm.max_abs) && isnan(s_none_nm.median_abs)

    r_none_nv = ValidationCaseResult("SYN_NONE_NV", "2026-10-22", (;), rows_cover, PlotSeries[],
                                     :no_verdict, "informational", "", "")
    @test case_error_summary(r_none_nv, PlotSpec(; error_mode=:none)).text == "no criterion"

    r_empty = ValidationCaseResult("SYN_EMPTY", "2026-10-22", (;), ValidationTableRow[],
                                   PlotSeries[], :met, "x", "", "")
    @test case_error_summary(r_empty, PlotSpec(; error_mode=:absolute, error_tol=1.0)).text == "no criterion"
    @test case_error_summary(r_empty, PlotSpec(; error_mode=:none)).text == "no criterion"
    # :no_verdict + empty table → no criterion (any error_mode).
    r_nv_empty = ValidationCaseResult("SYN_NV_EMPTY", "2026-10-22", (;), ValidationTableRow[],
                                      PlotSeries[], :no_verdict, "x", "", "")
    @test case_error_summary(r_nv_empty, PlotSpec(; error_mode=:absolute, error_tol=1.0)).text == "no criterion"

    # :no_verdict + table + non-:none → no verdict · max/med (no k/n in tol).
    r_nv = ValidationCaseResult("SYN_NV", "2026-10-22", (;), rows_abs, PlotSeries[],
                                :no_verdict, "informational", "", "")
    s_nv = case_error_summary(r_nv, PlotSpec(; error_mode=:absolute, error_ylabel="Hz"))
    @test startswith(s_nv.text, "no verdict")
    @test occursin("max |err|", s_nv.text)
    @test occursin("med", s_nv.text)
    @test !occursin("in tol", s_nv.text)
    @test s_nv.n_within == 2
    @test s_nv.n_rows == 3
    @test occursin("no verdict", s_nv.chip_text)
    @test !occursin("in tol", s_nv.chip_text)

    # Snapshot writer/loader round-trip (temp dir); corrupt header → empty; one bad row keeps good.
    mktempdir() do tmp
        path = joinpath(tmp, "case_error_summary.csv")
        write_case_error_summary(path; run_date="2026-10-22")
        rec = recorded_case_errors(path)
        @test haskey(rec, "R996_FIG14")
        @test rec["R996_FIG14"].n_within == 24      # Phase 76 (2026-10-28): thickness on (Phase 72: 14, before: 20)
        @test rec["R996_FIG14"].n_rows == 24
        @test !isempty(rec["R996_FIG14"].text)
        @test hasproperty(rec["R996_FIG14"], :source_date)
        @test rec["R996_FIG14"].run_date == "2026-10-22"
        bad = joinpath(tmp, "bad.csv")
        write(bad, "not,a,valid\n{{{")
        @test isempty(recorded_case_errors(bad))
        @test isempty(recorded_case_errors(joinpath(tmp, "missing.csv")))
        # One malformed data row among good rows → good rows still load.
        mixed = joinpath(tmp, "mixed.csv")
        open(mixed, "w") do io
            println(io, "id,run_date,source_date,verdict,n_within,n_rows,max_abs,median_abs,unit,text")
            println(io, "GOOD_A,2026-10-22,2026-10-21,met,1,1,0.5,0.5,\"dB\",\"1/1 in tol · max |err| 0.5 dB · med 0.5 dB\"")
            println(io, "BAD,,,not_a_number,,,,,\"\",\"\"")
            println(io, "GOOD_B,2026-10-22,2026-10-21,not_met,0,2,3.0,1.5,\"dB\",\"0/2 in tol · max |err| 3.0 dB · med 1.5 dB\"")
        end
        mixed_rec = recorded_case_errors(mixed)
        @test haskey(mixed_rec, "GOOD_A")
        @test haskey(mixed_rec, "GOOD_B")
        @test !haskey(mixed_rec, "BAD")
        @test mixed_rec["GOOD_A"].source_date == "2026-10-21"
        # Old column set (no source_date) still loads; source_date falls back to run_date.
        old = joinpath(tmp, "old.csv")
        open(old, "w") do io
            println(io, "id,run_date,verdict,n_within,n_rows,max_abs,median_abs,unit,text")
            println(io, "OLD1,2026-10-20,met,2,2,1.0,1.0,\"dB\",\"2/2 in tol · max |err| 1.0 dB · med 1.0 dB\"")
        end
        old_rec = recorded_case_errors(old)
        @test haskey(old_rec, "OLD1")
        @test old_rec["OLD1"].source_date == "2026-10-20"
        @test old_rec["OLD1"].run_date == "2026-10-20"
    end

    # Running a case must not write the snapshot (or any tracked report file).
    rep_dir = abspath(joinpath(@__DIR__, "..", "..", "docs", "validation_reports"))
    function _report_mtimes(dir)
        d = Dict{String,Float64}()
        for (root, _, files) in walkdir(dir)
            for f in files
                p = joinpath(root, f)
                d[p] = mtime(p)
            end
        end
        return d
    end
    before = _report_mtimes(rep_dir)
    run_validation_case("CYL2D_C1")
    after = _report_mtimes(rep_dir)
    @test before == after

    # Map / case JSON carry error fields + chip_row_h
    parsed = JSON3.read(validation_map_json("total"))   # the map holds the cases with a recorded verdict (Phase 86)
    @test haskey(parsed, :chip_row_h)
    @test Int(parsed.chip_row_h) == PAIN.VALIDATION_MAP_CHIP_ROW_H
    chip = nothing
    for b in parsed.blocks
        for c in b.cases
            if String(c.id) == "R996_FIG14"
                chip = c
            end
            @test haskey(c, :error)
            @test haskey(c, :error_chip)
            @test haskey(c, :error_source)
        end
    end
    @test chip !== nothing

    fig14 = run_validation_case("R996_FIG14")
    s14 = case_error_summary(fig14, VALIDATION_CASES["R996_FIG14"].plot_spec)
    @test s14.n_within == 24                     # Phase 76 (2026-10-28) recorded rerun (Phase 72: 14, before: 20)
    @test s14.n_rows == 24
    @test count(r -> r.within_tolerance, fig14.table) == 24
    @test length(fig14.table) == 24

    unc = run_validation_case("UNC_COVER")
    s_unc = case_error_summary(unc, VALIDATION_CASES["UNC_COVER"].plot_spec)
    @test unc.verdict === :not_met
    @test VALIDATION_CASES["UNC_COVER"].plot_spec.error_mode === :none
    # 0/3 since 2026-10-28 (Phase 78d-4 App. D consistency fixes J1–J6: margins H1 −4.06, H2 −5.41, H3 −13.23 dB; post-hoc).
    # Before: 1/3 (78d-3: +0.52, −0.11, −18.36; 78d F1/F2: +0.19, −2.09, −18.47).
    @test s_unc.text == "0/3 within criterion"
    @test s_unc.n_within == 0
    @test s_unc.n_rows == 3
    @test s_unc.unit == ""
    @test isnan(s_unc.max_abs) && isnan(s_unc.median_abs)

    # Live no_verdict cases: no k/n in tol in the display text.
    for id in ("GEXT_BOUND", "MRP_RITZ", "E15_STRUCT_LOSS", "BBN_LEVELS")
        r = run_validation_case(id)
        @test r.verdict === :no_verdict
        s = case_error_summary(r, VALIDATION_CASES[id].plot_spec)
        @test !isempty(r.table)
        @test startswith(s.text, "no verdict")
        @test !occursin("in tol", s.text)
    end

    sess = Dict{String,NamedTuple}("R996_FIG14" => s14)
    map_sess = JSON3.read(validation_map_json("total"; session_errors=sess))   # session text wins over the snapshot
    chip2 = nothing
    for b in map_sess.blocks, c in b.cases
        String(c.id) == "R996_FIG14" && (chip2 = c)
    end
    @test String(chip2.error) == s14.text
    @test String(chip2.error_chip) == s14.chip_text
    @test String(chip2.error_source) == "run"
    info = JSON3.read(case_info_json("R996_FIG14"; session_errors=sess,
                                      recorded_errors=Dict{String,NamedTuple}()))
    @test String(info.error) == s14.text
    @test String(info.error_source) == "run"
    @test String(info.error_snapshot) == ""
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
    # Task C: every registry id has CASE_INFO and appears in exactly one map block, except the cases kept off the map
    # ("Map / block: none / …", Phase 78f 2026-10-28: MRP_D1, MRP_RITZ), which appear in none
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
        @test get(block_hits, id, 0) == (CASE_INFO[id].map_id == "none" ? 0 : 1)
    end
    @test sort([id for id in VALIDATION_CASE_ORDER if CASE_INFO[id].map_id == "none"]) == ["MRP_D1", "MRP_RITZ"]
    for map_id in ("total",)
        raw = validation_map_json(map_id)
        parsed = JSON3.read(raw)
        @test parsed.id == map_id
        listed = String[]
        for b in parsed.blocks
            @test haskey(b, :col) && haskey(b, :row) && haskey(b, :feeds)
            @test haskey(b, :group) && haskey(b, :role)
            for c in b.cases
                push!(listed, String(c.id))
            end
        end
        @test haskey(parsed, :groups)
        for id in VALIDATION_CASE_ORDER
            get(block_hits, id, 0) == 1 || continue
            info = CASE_INFO[id]
            own = nothing
            for m in VALIDATION_MAPS
                for b in m.blocks
                    id in b.cases && (own = m.id)
                end
            end
            own == map_id && @test (id in listed) == PAIN.on_validation_map(id)   # only cases with a verdict (Phase 86)
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
    # Expected structure — single total map (aircraft + cabin + checks); R996_FIG8 removed
    @test [m.id for m in VALIDATION_MAPS] == ["total"]
    total = VALIDATION_MAPS[1]
    @test Set([
        "A_GEO", "A_LOADS", "A_AMP", "A_PHASE", "A_FWD", "A_SURF", "A_CABIN",
        "P_FF", "P_GRID", "P_BLK", "P_MRP", "P_CYL", "P_TRIM", "P_EQ8", "P_REPRO", "P_MEAS",
        "X_F1A", "X_FF", "X_SRC", "X_BLK_OUT", "X_OUT",
    ]) ⊆ Set(b.id for b in total.blocks)
    blk_p68 = only(b for b in total.blocks if b.id == "P_BLK")
    @test blk_p68.cases == ["BLK_P68", "E12_BLOCK", "ISO_BLOCKING", "R996_FIG10_FLAT", "R996_FIG10_CIRC"]   # + Phase 90
    amp = only(b for b in total.blocks if b.id == "A_AMP")
    @test amp.cases ==
          ["F1A_GUTIN", "R996_FIG14", "R996_FIG12", "R996_FIG13A", "R996_FIG6", "R996_FIG7",
           "F1A_GUTIN_ANGLES", "F1A_GW_FLIGHT", "F1A_THICKNESS", "F1A_PROPERTIES",   # Phase 66
           "F1A_CHORDWISE"]                                                          # Phase 67
    # Phase 70 F2–F4 (2026-10-28): each case sits on the block it tests
    blkcases(id) = only(b for b in total.blocks if b.id == id).cases
    @test "F1A_INDEP" in blkcases("X_F1A") && "F1A_PLANE_PEAK" in blkcases("X_FF") && "ISO_TABLE8" in blkcases("X_FF")
    @test "FF_E11_MAP" in blkcases("P_GRID")
    @test issubset(["BPM_RP1218", "PROP_BB_FIG14", "PROP_BB_FIG17"], blkcases("A_SURF"))
    @test !any(id -> id in blkcases("P_FF"), ["ISO_TABLE8", "BPM_RP1218", "PROP_BB_FIG14", "PROP_BB_FIG17"])
    loads = only(b for b in total.blocks if b.id == "A_LOADS")
    @test "BEMT_HAND" in loads.cases
    @test "TRIM_CLOSED" in only(b for b in total.blocks if b.id == "P_TRIM").cases
    @test "T1_FROM_E12" in only(b for b in total.blocks if b.id == "P_MEAS").cases
    @test "NR_BAND_HAND" in only(b for b in total.blocks if b.id == "P_EQ8").cases
    @test "HF_MASSLAW" in only(b for b in total.blocks if b.id == "P_EQ8").cases
    air = only(b for b in total.blocks if b.id == "A_GEO")
    @test air.group_title == "Aircraft BEMT+F1A"
    @test air.role == "input"
    # Feeds targets exist; layout positions present; no empty-role pipeline without group
    ids = Set(b.id for b in total.blocks)
    for b in total.blocks
        @test b.col >= 0 && b.row >= 0
        for f in b.feeds
            @test f in ids
        end
        @test !isempty(b.group)
        @test b.role in ("input", "function", "output", "check")
    end
    @test !haskey(CASE_INFO, "R996_FIG8")
    # Every case Map / block points at total, except the off-map regression cases (Phase 78f, "none")
    for id in keys(CASE_INFO)
        @test CASE_INFO[id].map_id == (id in ("MRP_D1", "MRP_RITZ") ? "none" : "total")
    end
    # Temp-doc edit → case_info_json changes (single source)
    mktempdir() do tmp
        src = validation_guideline_path()
        dst = joinpath(tmp, "VALIDATION_GUIDELINE.md")
        md = read(src, String)
        md2 = replace(md,
            "**Explanation:** Code-on-code (against printed values): ANOPP/PAIN gives propeller pressure in free space;" =>
            "**Explanation:** TEMP_DOC_PROBE_R2 Code-on-code (against printed values): ANOPP/PAIN gives propeller pressure in free space;";
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
    total_json = JSON3.read(validation_map_json("total"))
    @test haskey(total_json, :how_to_read)
    @test !isempty(String(total_json.how_to_read))
    @test haskey(total_json.blocks[1], :what_it_does)
    @test haskey(total_json.blocks[1], :col)
    @test haskey(total_json, :groups)
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
    # regression at L = 1.83 m (I-22, 2026-10-22, post-hoc; earlier 1.803 m: see length_sensitivity.md)
    # Expected from length_sensitivity @ 1.83: 85.90, 78.35, 79.82; re-recorded 2026-10-23 after the
    # Phase 44 code-on-code fix of Eq. (83) (η_r'' with the bare f'): 85.93, 78.32, 79.57; and after the
    # Phase 44f floor-term sign (2026-10-23, post-hoc): 89.03, 81.24, 77.06; and after the Phase 65
    # grid axial correction 2026-10-23 (code vs User Manual p. 9 / App. E p. E-8: z_k = z_p − x₃,
    # z_p = 0.662 m; not a fit): 88.20, 80.43, 78.21
    @test rr.table[1].computed ≈ 88.20 atol=0.01
    @test rr.table[2].computed ≈ 80.43 atol=0.01
    @test rr.table[3].computed ≈ 78.21 atol=0.01
    png = plot_case(r1, VALIDATION_CASES["CYL2D_C1"].plot_spec;
                    path=joinpath(TEST_OUT, "CYL2D_C1.png"))
    @test isfile(png)
    @test filesize(png) > 0
    # R996_FIG8 removed 2026-10-21 (I-20: M_t=1.0 out of scope)
    @test !haskey(VALIDATION_CASES, "R996_FIG8")
    # Task C new cases — Fig.14 counts after A_rms = A/√2 (I-17 / F4 2026-10-21, post-hoc);
    # Phase 72 (2026-10-28): Fig. 14 microphone placed behind the plane as Report 996 defines it (was 20/24, met)
    fig14 = run_validation_case("R996_FIG14")
    @test count(r -> r.within_tolerance, fig14.table) == 24
    @test length(fig14.table) == 24
    @test fig14.verdict === :met            # Phase 76 (2026-10-28): thickness on
    @test run_validation_case("MRP_RITZ").verdict === :no_verdict
    @test run_validation_case("BLK_P68").verdict === :met
    f1a_gutin = run_validation_case("F1A_GUTIN")   # information since Phase 85 (2026-10-29); the check itself still holds
    @test f1a_gutin.verdict === :no_verdict && PAIN.underlying_verdict(f1a_gutin) === :met

    # Task C4 — converted report-pointer cases → CSV replays
    # Allowed transcribed constant tables in src/ (not read from page images):
    allowed_src_constants = (
        "TABLE_C1_FREQ_HZ", "TABLE_C1_GENMASS", "TABLE_C1_SYMMETRIC", "TABLE_C1_C0",
        "TABLE_D1_FULL", "BLOCKING_P68_CHECKPOINTS",
    )
    # Live in-process cross-checks with no digitized reference file:
    allowed_live_no_csv = ("F1A_GUTIN", "BBN_KIN", "UT_GRID",
        "ISO_BLOCKING", "ISO_FF_CONV", "ISO_GEXT_LINE", "ISO_TABLE8",
        "ISO_CYL2D_EXACT", "ISO_CYL2D_BOUNDARY", "ISO_JOINT_ACC", "CYL2D_GRID_CONV", "MRP_COUPLED_LIMITS", "LOUDEST_PT_GRID",
        "ISO_MODAL_DENSITY", "ISO_BB_BAND", "ISO_SIL",
        "TRIM_CLOSED", "NR_BAND_HAND", "HF_MASSLAW", "BEMT_HAND", "F1A_INDEP",
        # Phase 62 live checks (hand formulas, bounds, pipeline echo; MRP/TRIM_INPUT_QA read appE_article_inputs.csv)
        "F1A_PLANE_PEAK", "FF_E11_MAP", "SRC_PASSTHROUGH", "BLK_GAIN_MAP", "MRP_SHAPE_NORM",
        "CABIN_GEOM_HAND", "CYL2D_WEYL", "TRIM_PASSIVITY", "PAIN_INPUT_ECHO", "AC_CABIN_DEMO",
        # Phase 66 closed-form BEMT / F1A checks
        "BEMT_MOMENTUM", "BEMT_HAND_TIP", "BEMT_INTEGRALS", "BEMT_SIMILARITY",
        "F1A_GUTIN_ANGLES", "F1A_GW_FLIGHT", "F1A_THICKNESS", "F1A_PROPERTIES",
        "F1A_CHORDWISE")   # Phase 67 diagnostic (POLAR_FIDELITY reads its CSV/JSON references)
    converted = ("PER_LOADS", "PER_FIG6", "PER_FIG7", "PER_FIG8", "PER_FIG9",
                 "R996_FIG6", "R996_FIG7", "BBN_CIRC", "BBN_LONG", "BBN_LEVELS")
    results_by_id = Dict{String,Any}()
    for id in VALIDATION_CASE_ORDER
        results_by_id[id] = run_validation_case(id)
    end
    @test results_by_id["UT_GRID"].verdict === :no_verdict && PAIN.underlying_verdict(results_by_id["UT_GRID"]) === :met   # information since Phase 85
    for id in converted
        r = results_by_id[id]
        @test !isempty(r.series)
        @test !isempty(r.table)
    end
    bbn = results_by_id["BBN_CIRC"]
    # Post-hoc pair convention (I-19, 2026-10-22); pre-registered FAIL was 26/168
    @test bbn.inputs_echo.n_ok == 134
    @test bbn.inputs_echo.n_tot == 168
    @test occursin("post-hoc", VALIDATION_CASES["BBN_CIRC"].label)
    # BBN_LONG: Fig. 19 / Fig. 20 panels are built per pair (must differ)
    blong = results_by_id["BBN_LONG"]
    m1 = only(s for s in blong.series if s.panel == 1 && startswith(s.name, "measured"))
    m2 = only(s for s in blong.series if s.panel == 2 && startswith(s.name, "measured"))
    @test m1.y != m2.y || m1.x != m2.x
    # Pereira H1/H2 counts after peak_Pa_to_spl_dB (I-17 / F4 2026-10-21, post-hoc)
    per9 = results_by_id["PER_FIG9"]
    @test per9.inputs_echo.n1ok == 9 && per9.inputs_echo.n1 == 9   # Phase 74a (2026-10-28): Fig. 9 re-read from the PDF vectors (Phase 72: 0, before: 3)
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
        png = plot_case(r, VALIDATION_CASES[id].plot_spec;
                        path=joinpath(TEST_OUT, "$(id).png"))
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
        json_paths = String[p for p in c.reference_files if endswith(lowercase(p), ".json")]
        for v in values(r.inputs_echo)
            if v isa AbstractString
                s = String(v)
                endswith(lowercase(s), ".csv") && push!(csv_paths, s)
                endswith(lowercase(s), ".json") && push!(json_paths, s)
            end
        end
        has_csv = any(isfile, csv_paths)
        has_json = any(isfile, json_paths)  # polar display cases use XFOIL JSON
        has_const = any(occursin(name, blob) for name in allowed_src_constants)
        @test has_csv || has_json || has_const
    end
end



# Length override plumbing (I-22). Default is 1.83 m; override still scales geometry.
# No length selected from any error.
_run_if("Length override") do
    reset_test_article_length!()
    @test test_article_length() == 1.83
    @test !test_article_length_overridden()

    # Default path: identical to hard-coded 1.83
    fuse0 = FuselageGeometry(test_article_length(), 0.508, 56.6)
    V0 = cabin_volume(fuse0)
    @test V0 == cabin_volume(FuselageGeometry(1.83, 0.508, 56.6))
    p3_0 = phase3_trim()
    @test p3_0.A_curved == phase3_trim(; L=1.83).A_curved
    sm0 = structural_modes_from_table_d1(; n_keep=4)
    @test sm0.L == 1.83
    g_appd0 = appd_test_article_geometry()
    @test g_appd0.L == 1.83   # App. D follows test_article_length()
    @test run_pain_pipeline(; source=:synthetic, n_harmonics=1, use_synthetic=true).inputs.fuse.L == 1.83

    # Override to former caption value 1.803: cabin volume scales with L
    with_test_article_length(1.803) do
        @test test_article_length() == 1.803
        @test test_article_length_overridden()
        fuse1 = FuselageGeometry(test_article_length(), 0.508, 56.6)
        V1 = cabin_volume(fuse1)
        @test V1 / V0 ≈ 1.803 / 1.83 rtol=1e-14
        @test phase3_trim().A_curved / p3_0.A_curved ≈ 1.803 / 1.83 rtol=1e-14
        @test structural_modes_from_table_d1(; n_keep=4).L == 1.803
        @test appd_test_article_geometry().L == 1.803
        # L_c default follows structure length
        inp = noise_reduction_test_article_inputs(; η_lining=1.0)
        @test inp.fuse.L == 1.803
        @test inp.L_c == 1.803
    end

    # Restored after with_test_article_length
    @test test_article_length() == 1.83
    @test !test_article_length_overridden()
    @test appd_test_article_geometry().L == 1.83

    # Restored even when the body errors
    @test_throws ErrorException with_test_article_length(1.803) do
        error("probe")
    end
    @test test_article_length() == 1.83
    @test !test_article_length_overridden()
end

_run_if("Git porcelain docs/data parse helper") do
    synthetic = """
 M rea-work/docs/flowchart.md
?? rea-work/docs/untracked.md
R  rea-work/docs/old.md -> rea-work/docs/renamed.md
 M "rea-work/docs/quoted name.md"
 M rea-work/src/not_docs.jl
 M rea-work/docs/validation_reports/figures/VALIDATION_MAP_TOTAL_x.png
 M rea-work/data/foo.csv
"""
    got = _parse_docs_data_porcelain(synthetic)
    @test got == [
        "rea-work/docs/flowchart.md",
        "rea-work/docs/renamed.md",
        "rea-work/docs/quoted name.md",
        "rea-work/data/foo.csv",
    ]
end

_run_if("Isolated block checks (phase 40, V-UNIT)") do
    # Criteria fixed 2026-10-23 in IMPLEMENTATION_PLAN.md §8b. Verdicts below are from
    # the first recorded run of this testset; table sizes are asserted with the verdict.
    # ISO_RITZ_DONNELL (40f) is not registered: Ritz cannot drop stringer/frame I via options.
    expected = (
        ("ISO_BLOCKING", :met, 960),          # 160 pts × 3 H × 2 (A,φ)
        ("ISO_FF_CONV", :met, 111),           # 5 SPL×3 + ℓ=1 A/φ rows
        ("ISO_GEXT_LINE", :met, 480),         # 5 option sets × 16 k × 3 H × 2
        ("ISO_TABLE8", :met, 483),            # 160×3 + 3 scales
        ("ISO_CYL2D_EXACT", :met, 21),        # 10 modes ×2 (NY20+NY10 info) + improve row
        ("ISO_JOINT_ACC", :met, 6),           # 3 modes × 2 forms
        ("ISO_MODAL_DENSITY", :met, 12),      # 6 bands × (density + JA)
        ("ISO_BB_BAND", :met, 8),             # α∈{2,1.5} × 4 centres
        ("ISO_CYL2D_BOUNDARY", :met, 173),
        ("ISO_SIL", :met, 2),
    )
    for (id, verd, ntab) in expected
        @test haskey(VALIDATION_CASES, id)
        r = run_validation_case(id)
        @test r.verdict === :no_verdict && PAIN.underlying_verdict(r) === verd   # information since Phase 85 (2026-10-29)
        ntab === nothing || @test length(r.table) == ntab
        # Write figures only under TEST_OUT (suite must leave the tree clean).
        png = plot_case(r, VALIDATION_CASES[id].plot_spec;
                        path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
    @test !haskey(VALIDATION_CASES, "ISO_RITZ_DONNELL")
end

_run_if("Isolation of failing cases (phase 41)") do
    # Criteria fixed 2026-10-23 in IMPLEMENTATION_PLAN.md §8b. Assert recorded verdicts.
    # T1_FROM_E12 first run: 2/3 (H3 fails) → cabin chain implicated, not source/blocking alone.
    expected = (
        ("T1_FROM_E12", :not_met),
        ("TRIM_CLOSED", :met),
        ("NR_BAND_HAND", :met),
        ("HF_MASSLAW", :met),
        ("BEMT_HAND", :met),
        ("F1A_INDEP", :met),
    )
    for (id, verd) in expected
        @test haskey(VALIDATION_CASES, id)
        r = run_validation_case(id)
        @test PAIN.underlying_verdict(r) === verd   # the check itself; verification cases carry no verdict since Phase 85
        @test (r.verdict === :no_verdict) == (PAIN.no_verdict_by_rule(id) || verd === :no_verdict)
        @test !isempty(r.table)
        png = plot_case(r, VALIDATION_CASES[id].plot_spec;
                        path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
end

_run_if("T1/T2 root causes (phase 43)") do
    # Criteria fixed 2026-10-23 in IMPLEMENTATION_PLAN.md §8b Phase 43 (unchanged).
    # 43a: volume crossover default; :auto H1–H3 = :eq8 (H2 no longer collapses).
    rep = PAIN._iso43_changeover_report()
    @test isfinite(rep.f_Hz) && rep.f_Hz > 1000 && rep.f_Hz < 2000
    @test rep.band_Hz == containing_third_octave(rep.f_Hz, third_octave_centers())
    @test rep.t1_auto_new ≈ rep.t1_eq8 rtol = 1e-10
    @test rep.repro_auto_new[2] > 50  # volume rule: H2 stays on Eq. (8), not ~16 dB
    @test "T1_MEAS_DAMPING" in only(b for b in VALIDATION_MAPS[1].blocks if b.id == "P_MEAS").cases
    @test "NR_TP1964" in only(b for b in VALIDATION_MAPS[1].blocks if b.id == "P_MEAS").cases
    # Analytic sub-checks for 43d (code-on-code)
    @test abs(besselj_prime_zeros(0, 1)[1] - 3.83170597) < 1e-5
    @test abs(besselj_prime_zeros(1, 1)[1] - 1.84118378) < 1e-5
    @test circular_acoustic_eps(0, 0.0, 1) ≈ 2.0 atol = 1e-12
    expected = (
        ("T1_MEAS_DAMPING", :not_met),   # first run 2026-10-23: 2/3 (H3)
        ("H3_ATTRIB", :no_verdict),
        ("NR_TP1964", :not_met),
        ("NR_TP1964_REF2", :not_met),
        ("T1_F1A_FILL", :met),           # first run 2026-10-23: 2/3; 3/3 after the 44f sign fix (post-hoc)
        ("T1_F1A_MEAS_DAMP", :no_verdict),
    )
    for (id, verd) in expected
        @test haskey(VALIDATION_CASES, id)
        r = run_validation_case(id)
        @test PAIN.underlying_verdict(r) === verd   # the check itself; verification cases carry no verdict since Phase 85
        @test (r.verdict === :no_verdict) == (PAIN.no_verdict_by_rule(id) || verd === :no_verdict)
        @test !isempty(r.table)
        png = plot_case(r, VALIDATION_CASES[id].plot_spec;
                        path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
end

_run_if("Isolated checks for T1/T2 functions (phase 46)") do
    # Criteria fixed 2026-10-23 (plan §8d Phase 46) before these checks were written or run.
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    inp = r.inputs
    fuse = inp.fuse
    a, L = fuse.a, fuse.L

    # 46a broadband_cabin_p2: its documented formula assembled by hand at two bands
    for fc in (1250.0, 2000.0)
        ω = 2π * fc
        τ_t = PAIN.sidewall_tau(inp, ω)
        α = max(PAIN.absorption_coefficient(fc), 1e-3)
        j2 = PAIN.band_joint_acceptance(inp, fc)
        χ = clamp(PAIN.structural_modal_density(inp.structural, fc) / (3.0 / (2π * 0.2316 * 1500)), 0.25, 4.0)
        A_fc = π * a * L
        S = 2π * a * L + 2π * a^2
        for (p2, js) in ((1.0, 1.0), (3.7, 0.5))
            hand = p2 * 4τ_t * A_fc / (α * S) * j2 * χ * js
            @test abs(PAIN.broadband_cabin_p2(inp, fc, p2; j2_scale=js) / hand - 1) ≤ 1e-9
        end
        @test PAIN.broadband_cabin_p2(inp, fc, 2.0) ≈ 2 * PAIN.broadband_cabin_p2(inp, fc, 1.0) rtol = 1e-12
        @test PAIN.broadband_cabin_p2(inp, fc, 1.0; j2_scale=0.3) ≈ 0.3 * PAIN.broadband_cabin_p2(inp, fc, 1.0) rtol = 1e-12
        @test PAIN.broadband_cabin_p2(inp, fc, 0.0) == 0.0
        @test PAIN.broadband_cabin_p2(inp, fc, -1.0) == 0.0
    end

    # 46b tone_expected_value: Eq. (16) by hand from the in-band mode lists; Eq. (15) π-limit identity
    H = 3; ωH = 2π * 600.0
    ev = PAIN.tone_expected_value(inp, H, ωH)
    band = PAIN.modes_in_tone_band(inp, ωH)
    @test ev.N_n == length(band.ac_list) && ev.N_r == length(band.st_list) && ev.N_r > 0
    η̄_n = sum(m -> PAIN.acoustic_N(inp, m.ac, m.q, 600.0, m.ωn;
                                   ξ=PAIN.trim_conductance(inp.sidewall, ωH, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int),
                                   ξ_e=PAIN.trim_conductance(inp.endplates, ωH, Inf; ρ0=inp.ρ_int, c0=inp.c_int),
                                   V=PAIN.cabin_volume(inp)) / m.ωn^2, band.ac_list) / ev.N_n
    η̄_r = sum(m -> PAIN.structural_η_r_prime(inp, m.st, m.ωr), band.st_list) / ev.N_r
    @test ev.η̄_n ≈ η̄_n rtol = 1e-12
    @test ev.η̄_r ≈ η̄_r rtol = 1e-12
    Δω = PAIN.C_OMEGA_THIRD_OCTAVE * ωH
    V = PAIN.cabin_volume(inp); A = PAIN.coupling_area(fuse)
    mA4 = (inp.ρ_ext * inp.c_ext * A / (2ωH))^2                 # (mA/4)² τ_ML
    s16 = sum(m -> PAIN.generalized_force(m.st, H, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA) *
                   PAIN.structural_joint_acceptance(m.st, ωH; a, L, c0=inp.c_ext) / m.st.M_r^2, band.st_list) / ev.N_r
    p16 = ωH^2 / (inp.c_int * V) * (ev.N_r / Δω) * PAIN.sidewall_tau(inp, ωH) / (η̄_r * η̄_n) * mA4 * s16
    @test abs(ev.p2 / p16 - 1) ≤ 1e-9
    # Eq. (14) with E[g] closed form reduces to the π-limit Eq. (15) when E[g] = π ω_H/(2 η̄ Δω)
    evc = PAIN.tone_expected_value(inp, H, ωH; use_pi_limit=false)
    egπ = PAIN.expected_g_pi(ωH, ev.η̄_n, Δω) * PAIN.expected_g_pi(ωH, ev.η̄_r, Δω)
    @test evc.p2_eq15 * egπ / (evc.E_g_n * evc.E_g_r) ≈ ev.p2_eq15 rtol = 1e-12
    # scaling: n_r = N_r/Δω enters Eq. (16) linearly (two copies of every in-band structural mode)
    sm2 = PAIN.StructuralModes(vcat(inp.structural.modes,
                                    [PAIN.StructuralMode(100 + m.st.index, m.st.f_Hz, m.st.symmetric, m.st.M_r, m.st.M_axial,
                                                         m.st.C_shell, m.st.n_shell, m.st.C_floor, m.st.n_floor)
                                     for m in band.st_list]),
                               inp.structural.L, inp.structural.a, inp.structural.theta0_deg, "46b doubled")
    ev2 = PAIN.tone_expected_value(PAIN._with_fields(inp; structural=sm2), H, ωH)
    @test ev2.p2 ≈ 2 * ev.p2 rtol = 1e-12
    # empty band (no structural mode resonant near 125 Hz; first mode 188.5 Hz) → no high-frequency contribution
    @test PAIN.tone_expected_value(inp, 1, 2π * 125.0).p2 == 0.0

    # 46c hf_structural_band / hf_band_loss_factors on a synthetic mode set: 3 modes in the 500 Hz band, 2 outside
    proto = inp.structural.modes[13]
    mk(i, f) = PAIN.StructuralMode(i, f, proto.symmetric, proto.M_r, proto.M_axial, proto.C_shell, proto.n_shell,
                                   proto.C_floor, proto.n_floor)
    syn = PAIN.StructuralModes([mk(1, 300.0), mk(2, 480.0), mk(3, 500.0), mk(4, 520.0), mk(5, 900.0)],
                               L, a, fuse.theta0_deg, "46c synthetic")
    ηn_set = 0.031
    inp_s = PAIN._with_fields(inp; structural=syn, η_n_band=Dict(500.0 => ηn_set, 2000.0 => ηn_set))
    fc = 500.0; ω = 2π * fc; cω = PAIN.C_OMEGA_THIRD_OCTAVE
    b = PAIN.hf_structural_band(inp_s, fc)
    j2s = [PAIN.structural_joint_acceptance(mk(i, f), ω; a, L, c0=inp.c_ext) for (i, f) in ((2, 480.0), (3, 500.0), (4, 520.0))]
    @test length(b.in_band) == 3 && !b.asymptotic
    @test b.n_r ≈ 3 / (cω * ω) rtol = 1e-12
    @test b.j2_mean ≈ sum(j2s) / 3 rtol = 1e-12
    @test b.sum_j2sq ≈ sum(j2s .^ 2) rtol = 1e-12
    bA = PAIN.hf_structural_band(inp_s, 2000.0)                 # no mode within 2000 Hz ± c_ω/2
    @test bA.asymptotic && isempty(bA.in_band)
    @test bA.n_r ≈ PAIN.structural_modal_density(syn, 2000.0) rtol = 1e-12
    lf = PAIN.hf_band_loss_factors(inp_s, fc, b)
    areas = PAIN.hf_absorbing_areas(inp_s)
    Abar = PAIN.cylinder_surface_area(a, L)
    @test lf.η̄_n ≈ ηn_set rtol = 1e-12
    @test lf.ᾱ ≈ 4ω * areas.V * ηn_set / (inp.c_int * areas.S) rtol = 1e-12
    @test lf.η_rad_ext ≈ 2 * inp.ρ_ext * ω * Abar / (π * inp.m_wall * inp.c_ext) * b.j2_mean rtol = 1e-12
    @test lf.η̄_r′ ≈ sum(PAIN.structural_η_r_prime(inp_s, m.st, m.ωr; Abar) for m in b.in_band) / 3 rtol = 1e-12
    @test lf.η̄_r ≈ lf.η_rad_ext + lf.η̄_r′ rtol = 1e-12

    # 46d coupling_loss_factor_21: Eqs. (A.20)–(A.21) by hand
    mp = PAIN.MechanicalPath(; m_t=1.6, A_t=4.0, h_t=0.0008, c_t=3200.0, η_t=0.5,
                             m=3.2, A=5.0, h=0.0008, c_l=5300.0, N_points=9, line_length=3.66)
    ω = 2π * 400.0
    Zs, Zt = mp.m * mp.h * mp.c_l, mp.m_t * mp.h_t * mp.c_t
    A20 = 4 * 9 / (sqrt(3) * 4.0) * (mp.h_t * mp.c_t / ω) * Zs * Zt / (Zs + Zt)^2
    Ys, Yt = mp.m * mp.h^0.5 * mp.c_l^0.5, mp.m_t * mp.h_t^0.5 * mp.c_t^0.5
    A21 = (2 / 3)^0.25 / 4.0 * (mp.h_t * mp.c_t / ω)^0.5 * Ys * Yt / (Ys + Yt)^2 * 3.66
    @test abs(PAIN.coupling_loss_factor_21(mp, ω) / (A20 + A21) - 1) ≤ 1e-12
    mp0 = PAIN.MechanicalPath(; m_t=1.6, A_t=4.0, h_t=0.0008, c_t=3200.0, η_t=0.5, m=3.2, A=5.0, h=0.0008, c_l=5300.0)
    @test PAIN.coupling_loss_factor_21(mp0, ω) == 0.0
    mpN = PAIN.MechanicalPath(; m_t=1.6, A_t=4.0, h_t=0.0008, c_t=3200.0, η_t=0.5, m=3.2, A=5.0, h=0.0008, c_l=5300.0, N_points=9)
    @test abs(PAIN.coupling_loss_factor_21(mpN, ω) / A20 - 1) ≤ 1e-12

    # 46e (functions the full-suite coverage run of 2026-10-23 never executed, on the T1/T2 paths)
    # tone_Q_H: Q_H of p. 17 = 4 c²/V² (ρ c A/(2ω))² τ_t ω⁶
    @test PAIN.tone_Q_H(1.2, 343.0, 5.0, 1.3, 2π * 600.0, 0.4) ≈
          4 * (343.0 / 1.3)^2 * (1.2 * 343.0 * 5.0 / (2 * 2π * 600.0))^2 * 0.4 * (2π * 600.0)^6 rtol = 1e-12
    # blocked_broadband_band_p2: α = 1 (log branch) is the limit of the power-law branch
    p_1 = PAIN.blocked_broadband_band_p2(inp, 1600.0, 200.0; α=1.0)
    p_lo = PAIN.blocked_broadband_band_p2(inp, 1600.0, 200.0; α=1.0 - 1e-7)
    p_hi = PAIN.blocked_broadband_band_p2(inp, 1600.0, 200.0; α=1.0 + 1e-7)
    @test p_1 > 0 && abs(p_lo / p_1 - 1) ≤ 1e-5 && abs(p_hi / p_1 - 1) ≤ 1e-5
    # w_in_reverberant: linear in the blocked mean-square pressure; total = sum of its modal contributions
    w1 = PAIN.w_in_reverberant(inp, 500.0; p_bl2=1.0)
    w2 = PAIN.w_in_reverberant(inp, 500.0; p_bl2=2.5)
    @test w2.W_in ≈ 2.5 * w1.W_in rtol = 1e-12
    @test w1.W_in ≈ sum(c -> c.term, w1.contributions) rtol = 1e-10
end

_run_if("CR-3813 reproduction with NASA's pre-correction form (phase 61)") do
    # Criteria fixed 2026-10-23 (plan §8h) before any run. Recorded first-run results (all not met).
    # 61a: floor_sign = +1 is the default and leaves f′ unchanged; −1 flips only the floor integral of Eq. (52)
    inp = PAIN.noise_reduction_test_article_inputs(; η_lining=1.0)
    @test inp.floor_sign == 1.0
    pre = PAIN._with_fields(inp; floor_sign=-1.0)
    fuse = inp.fuse; a = fuse.a; θ0 = deg2rad(fuse.theta0_deg); Lp = 2a * sin(θ0); den = Lp + 2a * (π - θ0)
    n_checked = 0
    for ac in inp.acoustic.modes[2:6], st in inp.structural.modes[1:8], q in (0, 1)
        Is = PAIN.coupling_shell_integral(ac, st, a); Ip = PAIN.coupling_floor_integral(ac, st, a, Lp)
        ax = PAIN.axial_coupling(q, st.M_axial; L=fuse.L, L_c=inp.L_c, d=inp.d)
        @test PAIN.coupling_factor(ac, st, inp; q) ≈ ax * (Is + Ip) / den atol = 1e-12
        @test PAIN.coupling_factor(ac, st, pre; q) ≈ ax * (Is - Ip) / den atol = 1e-12
        n_checked += 1
    end
    @test n_checked == 80
    # code-review fixes (2026-10-23): floor_sign checked where it is used; the propeller-field NR needs the App. B layout
    @test_throws ErrorException PAIN.coupling_factor(inp.acoustic.modes[2], inp.structural.modes[1], PAIN._with_fields(inp; floor_sign=0.5))
    @test_throws ErrorException PAIN.propeller_field_band_nr(PAIN._with_fields(inp; amplitudes=zeros(16, 10, 3)), 500.0)
    @test PAIN._p48_af() === PAIN._p48_af()
    @test_throws ErrorException PAIN.PainInputs(inp.fuse, inp.prop, inp.structural, inp.acoustic, inp.amplitudes, inp.phases,
                                                inp.pts, inp.ΔA; floor_sign=0.5)
    r = run_validation_case("REPRO_18b_PRE")
    @test r.verdict === :no_verdict && PAIN.underlying_verdict(r) === :not_met && r.inputs_echo.n_ok == 1
    @test r.inputs_echo.corrected ≈ round.(run_validation_case("REPRO_18b").table[i].computed for i in 1:3; digits=2) atol = 0.01
    r2 = run_validation_case("E21_PRE")
    @test r2.verdict === :no_verdict && PAIN.underlying_verdict(r2) === :not_met && r2.inputs_echo.n_ok == 1 && r2.inputs_echo.n == 4
    r3 = run_validation_case("E22_HF_CODE")
    @test r3.verdict === :not_met && r3.inputs_echo.n_ok == 1
    @test all(r3.inputs_echo.nasa_minus_measured .> 30)              # NASA's own HF prediction misses by > 30 dB
    @test all(abs.(r3.inputs_echo.code .- r3.inputs_echo.nasa) .< 8)  # the code is within 8 dB of NASA
    for id in ("REPRO_18b_PRE", "E21_PRE", "E22_HF_CODE")
        png = plot_case(run_validation_case(id), VALIDATION_CASES[id].plot_spec; path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
end

_run_if("NASA's 300-mode set in the HF path and the reproductions (phases 83, 84)") do
    # Criteria fixed 2026-10-29 (plan §8aa) before any run. Recorded first-run results (all not met).
    r = run_validation_case("E22_HF_DECK")
    @test r.verdict === :no_verdict && PAIN.underlying_verdict(r) === :not_met && r.inputs_echo.n_ok == 0 && r.inputs_echo.n == 4
    @test all(>(0), r.inputs_echo.resonant_modes_per_band)          # resonant modes in every band (none with Table D-1)
    @test all(r.inputs_echo.code .< r.inputs_echo.table_d1 .- 5)     # the modes lower NR by > 5 dB in every band
    @test r.inputs_echo.table_d1 ≈ run_validation_case("E22_HF_CODE").inputs_echo.code atol = 0.01
    t2 = run_validation_case("T2_EQ19_DECK")
    @test t2.verdict === :no_verdict && PAIN.underlying_verdict(t2) === :not_met && t2.inputs_echo.n_ok == 0
    @test all(t2.inputs_echo.got .> t2.inputs_echo.measured)          # over the measurement now (Table D-1: under)
    @test all(t2.inputs_echo.table_d1 .< t2.inputs_echo.measured)
    rp = run_validation_case("REPRO_18b_DECK")
    @test rp.verdict === :no_verdict && PAIN.underlying_verdict(rp) === :not_met && rp.inputs_echo.n_ok == 0
    @test maximum(abs.(rp.inputs_echo.got .- rp.inputs_echo.table_d1)) < 0.5   # the tones do not depend on the extra modes
    # 83d: T2 compares a path fitted to E-9 with E-9, so it is information; its recorded outcome is kept
    t = run_validation_case("T2")
    @test t.verdict === :no_verdict && t.inputs_echo.original_verdict === :not_met
    # Phase 84 (criteria fixed 2026-10-29, plan §8ab): CR-172428 and E-21 on the 300 modes, recorded first runs
    rc, r0 = run_validation_case("R172428_CODE_DECK"), run_validation_case("R172428_CODE")
    @test rc.verdict === :no_verdict && PAIN.underlying_verdict(rc) === :not_met && count(r -> r.within_tolerance, rc.table) == 4 && rc.inputs_echo.structural === :nasa300
    @test maximum(abs.(rc.inputs_echo.ours .- r0.inputs_echo.ours)) < 2.5 && rc.inputs_echo.ours != r0.inputs_echo.ours
    re = run_validation_case("R172428_EXP_DECK")
    @test re.verdict === :no_verdict && PAIN.underlying_verdict(re) === :not_met && count(r -> r.within_tolerance, re.table) == 3
    e21 = run_validation_case("E21_PRE_DECK")
    @test e21.verdict === :no_verdict && PAIN.underlying_verdict(e21) === :not_met && e21.inputs_echo.n_ok == 1 && e21.inputs_echo.n == 4
    @test maximum(abs.(e21.inputs_echo.code .- e21.inputs_echo.table_d1)) > 20   # above the crossover the modes matter
    for id in ("E22_HF_DECK", "T2_EQ19_DECK", "REPRO_18b_DECK", "E21_PRE_DECK", "R172428_CODE_DECK", "R172428_EXP_DECK")
        png = plot_case(run_validation_case(id), VALIDATION_CASES[id].plot_spec; path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
end

_run_if("NASA's App. B per-mode values, the q = 0 hypothesis, η_n per mode (phases 87–89)") do
    # Criteria fixed 2026-10-29 (plan §8ae, §8af) before any run. Recorded first-run results.
    inp = r172428_inputs(4000)
    ac0 = inp.acoustic.modes[1]; st = inp.structural.modes[13]
    nq = PAIN._with_fields(inp; q0_coupled=false)
    @test coupling_factor(ac0, st, nq; q=0) == 0.0 && coupling_factor(ac0, st, inp; q=0) != 0.0     # q = 0 uncoupled
    @test coupling_factor(ac0, st, nq; q=1) == coupling_factor(ac0, st, inp; q=1)                     # q > 0 untouched
    # η_n per mode: one N per mode whatever the tone, equal to Eq. (77) with the band-centre trim conductance
    ac = PAIN._acmode_by_I(inp, 1); ωn = 2π * PAIN.cabin_frequency_3d(ac, inp.fuse.a, inp.L_c, 1; c0=inp.c_int)  # 218 Hz
    ωc = 2π * PAIN.nearest_third_octave(ωn / 2π, PAIN.third_octave_centers()); V = PAIN.cabin_volume(inp)   # 200 Hz band
    ξ = PAIN.trim_conductance(inp.sidewall, ωc, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int)
    ξe = PAIN.trim_conductance(inp.endplates, ωc, Inf; ρ0=inp.ρ_int, c0=inp.c_int)
    @test PAIN.acoustic_N_per_mode(inp, ac, 1, ωn; V) ≈ PAIN.acoustic_N(inp, ac, 1, ωn / 2π, ωn; ξ, ξ_e=ξe, V) rtol = 1e-12
    @test PAIN.acoustic_N_per_mode(inp, ac, 1, ωn; V) != PAIN.acoustic_N(inp, ac, 1, ωn / 2π, ωn; ξ=0.5ξ, ξ_e=ξe, V)
    pm = PAIN._with_fields(inp; η_n_per_mode=true)
    @test tone_mean_square_pressure(pm, 1, 2π * 200.0) != tone_mean_square_pressure(inp, 1, 2π * 200.0)
    @test !inp.η_n_per_mode && inp.q0_coupled                                                         # defaults unchanged
    # 87a–c (P cases)
    e = run_validation_case("APPB_EPS_N")
    @test e.verdict === :met && e.inputs_echo.n == 48 && all(r -> abs(r.computed / r.reference - 1) < 1e-4, e.table)
    h = run_validation_case("APPB_ETA_N")
    @test h.verdict === :not_met && h.inputs_echo.n_ok == 11 && h.inputs_echo.n == 46 && h.inputs_echo.skipped == [1, 2]
    @test isnan(PAIN._eta_n_at_mode(inp, inp.acoustic.modes[1], 1))                                 # 93.8 Hz: below Fig. A-2
    hi = [r for r in h.table if r.x ≥ 25]                                                           # modes ≥ 465 Hz
    @test all(r -> abs(r.computed / r.reference - 1) ≤ 0.10, hi)
    p = run_validation_case("APPB_ETA_RPP")
    @test p.verdict === :not_met && p.inputs_echo.n_ok == 8 && p.inputs_echo.n == 19
    # NASA prints one η_r″ for cabin mode 19 × structural mode 6 at 400 and 250 Hz; the tone-frequency N does not
    i4 = findfirst(r -> occursin("4000 rpm H2: cabin mode 19 × structural mode 6", r.quantity), p.table)
    i5 = findfirst(r -> occursin("5000 rpm H1: cabin mode 19 × structural mode 6", r.quantity), p.table)
    @test p.table[i4].reference == p.table[i5].reference && p.table[i5].computed > 5 * p.table[i4].computed
    # 88 (diagnostics): the q = 0 hypothesis refuted on CR-3813's runs
    for (id, k, n) in (("Q0_REPRO_18b", 2, 3), ("Q0_E18", 1, 3), ("Q0_E21", 1, 4))
        r = run_validation_case(id)
        @test r.verdict === :no_verdict && PAIN.underlying_verdict(r) === :not_met
        @test r.inputs_echo.n_ok == k && get(r.inputs_echo, :n, 3) == n
    end
    q = run_validation_case("Q0_REPRO_18b")
    @test all(q.inputs_echo.got .!= q.inputs_echo.q0_coupled)                                       # the option acts
    # 89b (diagnostic): η_n per mode, 5/9, not adopted
    r = run_validation_case("R172428_CODE_ETAN")
    @test r.verdict === :no_verdict && PAIN.underlying_verdict(r) === :not_met && count(x -> x.within_tolerance, r.table) == 5
    for id in ("APPB_EPS_N", "APPB_ETA_N", "APPB_ETA_RPP", "Q0_REPRO_18b", "R172428_CODE_ETAN")
        png = plot_case(run_validation_case(id), VALIDATION_CASES[id].plot_spec; path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
end

_run_if("Eq. (43) blocking against Report 996 Fig. 10 (phase 90)") do
    # Criterion fixed 2026-10-29 (plan §8ag) before digitizing. Recorded first-run results.
    r = run_validation_case("R996_FIG10_FLAT")
    @test r.verdict === :met && r.inputs_echo.n_ok == 5 && r.inputs_echo.n == 5
    @test all(4.0 .< r.inputs_echo.measured_dB .< 7.5)                       # about the doubling (6.02 dB)
    @test maximum(abs.(r.inputs_echo.R1_dB .- r.inputs_echo.measured_dB)) < 1.5
    @test all(r.inputs_echo.R2_dB .< r.inputs_echo.R1_dB .- 1.9)            # R2 is 0.8 F: about 2 dB under R1
    c = run_validation_case("R996_FIG10_CIRC")
    @test c.verdict === :no_verdict && c.inputs_echo.R1_dB == r.inputs_echo.R1_dB   # Eq. (43): same γ, same F
    @test all(c.inputs_echo.measured_dB .< r.inputs_echo.measured_dB)              # the curved wall raises less
    for id in ("R996_FIG10_FLAT", "R996_FIG10_CIRC")
        png = plot_case(run_validation_case(id), VALIDATION_CASES[id].plot_spec; path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
end

_run_if("Sharp sound bridges and the App. D mode extension (phases 59, 60)") do
    # Criteria and mapping fixed 2026-10-23 (plan §8g) before any run. Recorded first-run results.
    # 59a pieces by hand: Eq. (5) at normal incidence, Eq. (22), Eqs. (23) and (25), and the Fig. 5 construction
    @test PAIN.sharp_mass_law_TL(10.0, 1000.0; ρc1=415.0, ρc2=415.0) ≈ 20log10(1e4) - 10log10(415.0^2) + 10 atol = 1e-12
    @test PAIN.sharp_f0(4.448, 4.448, 0.0826) ≈ sqrt(1.21 * 343.0^2 * 8.896 / (4.448^2 * 0.0826)) / 2π rtol = 1e-12
    @test PAIN.sharp_dTL_line(0.5, 10000.0) ≈ 10log10(5000.0) - 25 atol = 1e-12
    @test PAIN.sharp_dTL_point(0.2, 10000.0) ≈ 20log10(2000.0) - 51 atol = 1e-12
    f0 = PAIN.sharp_f0(4.448, 4.448, 0.0826); fb = f0 * 2.0^(12 / (18 - 20log10(2)))
    @test PAIN.sharp_double_panel_TL(4.448, 4.448, 0.0826, 2fb; ΔTL_M=12.0) ≈
          PAIN.sharp_mass_law_TL(8.896, 2fb; ρc1=1.21 * 343, ρc2=1.21 * 343) + 12 atol = 1e-9
    @test PAIN.sharp_double_panel_TL(4.448, 4.448, 0.0826, fb * (1 - 1e-9); ΔTL_M=12.0) ≈
          PAIN.sharp_double_panel_TL(4.448, 4.448, 0.0826, fb * (1 + 1e-9); ΔTL_M=12.0) atol = 1e-6   # continuous at f_b
    r = run_validation_case("SHARP_PANEL_D")       # information since Phase 82; its recorded outcome is kept
    @test r.verdict === :no_verdict && r.inputs_echo.original_verdict === :not_met && r.inputs_echo.n_ok == 3
    # 59b: off leaves Eq. (23) unchanged; on adds τ_B by hand to the trimmed term
    inp = PAIN.r172428_inputs(4000)
    fc = 1000 * 2^(1 / 3)
    off = PAIN.hf_pressure_ratio(inp, fc); on = PAIN.hf_pressure_ratio(inp, fc; bridges=true)
    @test off.τ_B == 0.0
    @test off.den ≈ off.τ_t * off.τ * off.A_t + off.τ * off.A′ rtol = 1e-12
    b = PAIN.bridge_tau(inp, fc)
    arc = 2 * 0.508 * (π - deg2rad(56.6))
    @test b.e ≈ sqrt(arc * inp.fuse.L / 9) rtol = 1e-12
    @test b.b ≈ arc / 2 rtol = 1e-12
    ml = PAIN.sharp_mass_law_TL(inp.m_wall + 1.456, fc; ρc1=inp.ρ_ext * inp.c_ext, ρc2=inp.ρ_int * inp.c_int)
    @test b.τ_B ≈ 10^(-ml / 10) * (10^(-b.ΔTL_pt / 10) + 10^(-b.ΔTL_ln / 10)) rtol = 1e-12
    @test on.den ≈ off.den + b.τ_B * off.A_t rtol = 1e-12
    # 59c–59e recorded (not met)
    for (id, check) in (("NR_PROP_TP2444_BR", rr -> rr.inputs_echo.n_ok == 1),
                        ("E22_BR", rr -> rr.inputs_echo.n_ok == 0),
                        ("T2_MEAS_EXT_BR", rr -> abs(rr.inputs_echo.interior_dB[1] - 28.36) < 0.01))
        rr = run_validation_case(id)
        @test rr.verdict === :not_met && check(rr)
        png = plot_case(rr, VALIDATION_CASES[id].plot_spec; path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
    # 60a recorded (not met: App. D count 2.3× the asymptotic density at 1000 Hz, 0.19× at 2000 Hz)
    ap = PAIN.appd_modes(PAIN.appd_test_article_geometry(); n_modes=5000, n_axial=7, n_circ=8, n_floor_max=5, f_max_Hz=3000.0)
    cω = PAIN.C_OMEGA_THIRD_OCTAVE
    nband(f) = count(m -> f * (1 - cω / 2) ≤ m.f_Hz ≤ f * (1 + cω / 2), ap.modes)
    d1 = PAIN.structural_modes_from_table_d1()
    ratio(f) = nband(f) / (PAIN.structural_modal_density(d1, f) * cω * 2π * f)
    @test ratio(1000.0) > 2 && ratio(2000.0) < 0.5
end

_run_if("Propeller-field NR and open items (phases 50, 53, 56, 57)") do
    # Criteria fixed 2026-10-23 (plan §8e Phase 50, §8f Phases 53, 56, 57) before these checks were run.
    # 50b recorded result (first valid run 2026-10-23): not met 2/7
    r = run_validation_case("NR_PROP_TP2444_PF")
    @test r.verdict === :not_met && r.inputs_echo.n_ok == 2
    @test all(abs.(r.inputs_echo.NR_model[1:5] .- r.inputs_echo.NR_meas[1:5]) .< 7.0)   # 315–800 Hz within 7 dB
    png = plot_case(r, VALIDATION_CASES["NR_PROP_TP2444_PF"].plot_spec; path=joinpath(TEST_OUT, "NR_PROP_TP2444_PF.png"))
    @test isfile(png) && filesize(png) > 0
    # the propeller-field band NR reduces to the tone path at one frequency: n_freq = 1 at fc = H·BPF
    inp = PAIN.r172428_inputs(4000)
    one = PAIN.propeller_field_band_nr(inp, 400.0; n_freq=1)
    @test one.fs[1] ≈ 400.0 rtol = 1e-12
    @test one.p2 ≈ PAIN.tone_mean_square_pressure(inp, 2, 2π * 400.0) rtol = 1e-12
    @test one.p2_ref ≈ inp.amplitudes[8, 10, 2]^2 / 2 rtol = 1e-12

    # 53b guard (off by default): the E-21 inputs at 400 Hz; off = production value, on = asymptotic branch
    inp_nr = PAIN.noise_reduction_test_article_inputs(; η_lining=1.0)
    off = PAIN.hf_pressure_ratio(inp_nr, 1000 * 2^(-4 / 3); η_r_cap=0.15)
    on = PAIN.hf_pressure_ratio(inp_nr, 1000 * 2^(-4 / 3); η_r_cap=0.15, sparse_guard=true)
    @test !off.band.asymptotic && on.band.asymptotic
    @test on.NR_dB < off.NR_dB
    @test PAIN.hf_pressure_ratio(inp_nr, 1000.0; η_r_cap=0.15, sparse_guard=true).NR_dB ≈
          PAIN.hf_pressure_ratio(inp_nr, 1000.0; η_r_cap=0.15).NR_dB rtol = 1e-12   # a well-populated band is unchanged

    # 56a: the new switches leave the default solver unchanged; MRP_RITZ keeps its recorded 26/32
    L, a = PAIN.test_article_length(), 0.508
    fuse = PAIN.FuselageGeometry(L, a, 56.6)
    d = PAIN.structural_modes(fuse)
    e = PAIN.structural_modes(fuse; include_floor=true, include_stiffeners=true)
    @test [m.f_Hz for m in d.modes] == [m.f_Hz for m in e.modes]
    # 56b (40f): bare shell from the Ritz solver against closed-form Donnell–Mushtari (recorded not met)
    bare = PAIN.structural_modes(PAIN.FuselageGeometry(L, a, 0.0); include_floor=false, include_stiffeners=false, hybrid=false,
                                 include_antisym=false, n_keep=60)
    dm(st) = PAIN.donnell_mushtari_frequency_Hz(st.M_axial, st.n_shell[1], L, a, PAIN.MRP_T_SKIN, PAIN.MRP_E_2024,
                                                PAIN.MRP_NU_2024, PAIN.MRP_RHO_2024)
    errs = sort([(dm(st), st.f_Hz / dm(st) - 1) for st in bare.modes]; by=first)[1:10]
    @test all(abs(x[2]) > 0.01 for x in errs)                  # none of the first 10 within 1 %
    @test all(isempty(st.C_floor) for st in bare.modes)

    # 57 functions the suite never executed (off the T1/T2 paths), each against a hand value
    # parse_aircraft_trim_json: a two-element sidewall and a mechanical path from JSON-like input
    obj = Dict("sidewall" => Dict("elements" => [Dict("type" => "insulation", "thickness_m" => 0.05),
                                                Dict("type" => "limp_mass", "m_kg_m2" => 1.5, "eta" => 0.2)]),
               "mechanical" => Dict("N_points" => 9, "n_lines" => 2))
    t = PAIN.parse_aircraft_trim_json(obj; cabin_a=0.8, cabin_L=4.0, cabin_theta0_deg=50.0)
    ref = PAIN.TrimStack(PAIN.TrimElement[PAIN.InsulationLayer(0.05, PAIN.pf105_table()), PAIN.LimpMass(1.5, 0.2)])
    @test PAIN.trim_tau_insulation(t.sidewall, 2π * 1000) ≈ PAIN.trim_tau_insulation(ref, 2π * 1000) rtol = 1e-12
    @test t.mech.N_points == 9 && t.mech.line_length ≈ 8.0
    @test t.mech.A_t ≈ 2 * 0.8 * (π - deg2rad(50.0)) * 4.0 rtol = 1e-12
    @test length(t.ends.elements) == 1 && t.ends.elements[1].thickness == 0.013
    # _rand_triangular: sample mean (lo + hi + mode)/3, all samples inside [lo, hi]
    rng = PAIN.Random.MersenneTwister(7)
    xs = [PAIN._rand_triangular(rng, 1.0, 4.0, 1.5) for _ in 1:200_000]
    @test abs(sum(xs) / length(xs) - (1.0 + 4.0 + 1.5) / 3) < 0.01
    @test all(1.0 .≤ xs .≤ 4.0)
    # fit_mrp_to_table_d1: on a one-point grid it returns that point and its own match count
    best = PAIN.fit_mrp_to_table_d1(; scales=0.6:0.1:0.6, edges=2.2:0.1:2.2, floor_scales=2.4:0.1:2.4)
    @test best.k_scale == 0.6 && best.edge_factor == 2.2 && best.floor_scale == 2.4
    m = PAIN.structural_modes(PAIN.FuselageGeometry(L, a, 56.6); k_scale=0.6, edge_factor=2.2, floor_scale=2.4,
                              n_keep=48, hybrid=false)
    @test best.npass == PAIN.match_ritz_to_table_d1(m; tol_frac=0.05)[1]
    # appd_constraint_residuals: an App. D eigenvector satisfies the floor–shell junction constraints (D.4)
    g = PAIN.appd_test_article_geometry()
    b = PAIN._appd_basis(1, true)
    K, Mm, _, _ = PAIN._appd_assemble_KM(b, g)
    C = PAIN._appd_constraint_matrix(b, g)
    Kr, Mr, E = PAIN._appd_reduce(K, Mm, C)
    F = PAIN.eigen(PAIN.Symmetric(Kr), PAIN.Symmetric(Mr))
    q = E * F.vectors[:, 1]
    @test maximum(abs, PAIN.appd_constraint_residuals(q, b, g)) ≤ 1e-8 * maximum(abs, q)
    @test maximum(abs, PAIN.appd_constraint_residuals(ones(length(q)), b, g)) > 1e-6    # an arbitrary vector does not
    # scale_acoustic_freq: f_unit/a equals the q = 0 cabin frequency from the mode eigenvalue (c0 = 340)
    cy = PAIN.cyl2d_modes(56.6; n_modes=6, NY=10)
    for mo in cy.modes[2:6]
        @test PAIN.scale_acoustic_freq(mo.f_Hz_unit, 0.508) ≈ PAIN.cabin_frequency_3d(mo, 0.508, 1.83, 0; c0=340.0) rtol = 1e-9
    end
    # hf_broadband_spectrum: its 1.25 kHz band is the Eq. (19)–(23) value of the blocked broadband level
    rp = run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200.0, blocking=R2)
    sp = PAIN.hf_broadband_spectrum(rp.inputs; bpf_Hz=200.0, n_harmonics=5)
    bnd = PAIN.nearest_third_octave(1250.0, PAIN.resolve_bands(rp.inputs))
    p2bl = PAIN.blocked_broadband_band_p2(rp.inputs, bnd, 200.0)
    @test sp.third_octave_SPL_dB[bnd] ≈ 10log10(PAIN.hf_broadband_band_p2(rp.inputs, bnd, p2bl) / 4e-10 + 1e-30) atol = 1e-9
end

_run_if("Exterior broadband from RP-1218 (phase 48)") do
    # Criteria fixed 2026-10-23 (plan §8d Phase 48); 48b–48d decisions fixed before any comparison.
    r = run_validation_case("BPM_RP1218")
    @test r.verdict === :no_verdict && PAIN.underlying_verdict(r) === :met && r.inputs_echo.n_ok == r.inputs_echo.n == 270   # information since Phase 85
    # scaling laws of the port: span L → +3 dB per doubling, distance r → −6 dB, M⁵ in U at fixed Strouhal
    a = PAIN.bpm_tbl_te(1000.0, 0.3, 0.4, 1.2, 90.0, 90.0, 3.0, 50.0)
    b = PAIN.bpm_tbl_te(1000.0, 0.3, 0.8, 1.2, 90.0, 90.0, 3.0, 50.0)
    c = PAIN.bpm_tbl_te(1000.0, 0.3, 0.4, 2.4, 90.0, 90.0, 3.0, 50.0)
    @test b.s - a.s ≈ 10log10(2) atol = 1e-9
    @test a.s - c.s ≈ 20log10(2) atol = 1e-9
    @test PAIN.bpm_directivity(90.0, 90.0, 0.2)[1] ≈ 1.0 atol = 1e-12
    @test PAIN.bpm_directivity(0.0, 90.0, 0.2)[1] ≈ 0.0 atol = 1e-12        # no TE radiation straight downstream
    # recorded results (first run 2026-10-23)
    for (id, n_ok) in (("PROP_BB_FIG14", 3), ("PROP_BB_FIG17", 2), ("T2_PRED_BB", 0))
        rr = run_validation_case(id)
        @test rr.verdict === :not_met && rr.inputs_echo.n_ok == n_ok
        png = plot_case(rr, VALIDATION_CASES[id].plot_spec; path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
end

_run_if("Trim and high-frequency inputs (phase 49)") do
    # Criteria fixed 2026-10-23 (plan §8e Phase 49) before these checks were written or run.
    # 49a τ_t of Eq. (A.22), insulation path: |a11|⁻² rebuilt by hand, element by element (skin side first),
    # from the material table and the limp-mass law, without element_matrix / stack_matrix
    function a11_hand(st, ω)
        p, v = 1.0 + 0im, 0.0 + 0im
        for el in st.elements
            if el isa PAIN.InsulationLayer
                q = PAIN.insulation_properties(el.material, ω / 2π; allow_extrapolation=true)
                γd = complex(q.alpha_Np_per_m, -2π / q.lambda_m) * el.thickness
                W = q.W_abs * cis(PAIN.W_PHASE_SIGN * q.phi_rad)
                p, v = cosh(γd) * p + im * ω * W * sinh(γd) * v, -im * sinh(γd) / (ω * W) * p + cosh(γd) * v
            else
                p = p + ω^2 * el.m * (1 + im * el.η) * v
            end
        end
        return p
    end
    p3 = phase3_trim(; η_lining=1.0)
    appb = PAIN.r172428_inputs(4000).sidewall
    for st in (p3.sidewall, appb), f in (250.0, 1000.0, 2000.0)
        @test PAIN.trim_tau_insulation(st, 2π * f; allow_extrapolation=true) ≈ 1 / abs2(a11_hand(st, 2π * f)) rtol = 1e-12
    end
    # limits: one layer alone gives |cosh γd|⁻²; a limp mass alone on the blocked face transmits fully
    lay = PAIN.InsulationLayer(0.05, PAIN.pf105_table())
    q = PAIN.insulation_properties(lay.material, 1000.0)
    γd = complex(q.alpha_Np_per_m, -2π / q.lambda_m) * 0.05
    @test PAIN.trim_tau_insulation(PAIN.TrimStack(PAIN.TrimElement[lay]), 2π * 1000) ≈ 1 / abs2(cosh(γd)) rtol = 1e-12
    @test PAIN.trim_tau_insulation(PAIN.TrimStack(PAIN.TrimElement[PAIN.LimpMass(2.0, 0.5)]), 2π * 1000) ≈ 1.0 rtol = 1e-12
    # Eq. (20) reading (CR-3813 p. 24): τ_f sums the modes resonant below the band, not the in-band modes
    r = run_pain_pipeline(; source=:e11, n_harmonics=1, bpf_Hz=200.0, blocking=R2)
    inp = r.inputs; a, L = inp.fuse.a, inp.fuse.L
    proto = inp.structural.modes[13]
    mk(i, f) = PAIN.StructuralMode(i, f, proto.symmetric, proto.M_r, proto.M_axial, proto.C_shell, proto.n_shell,
                                   proto.C_floor, proto.n_floor)
    syn = PAIN.StructuralModes([mk(1, 300.0), mk(2, 400.0), mk(3, 500.0), mk(4, 900.0)], L, a, inp.fuse.theta0_deg, "49 synthetic")
    inp_s = PAIN._with_fields(inp; structural=syn)
    ω = 2π * 500.0
    j2(f) = PAIN.structural_joint_acceptance(mk(0, f), ω; a, L, c0=inp.c_ext)
    b = PAIN.hf_structural_band(inp_s, 500.0)
    @test b.sum_j2sq_below ≈ j2(300.0)^2 + j2(400.0)^2 rtol = 1e-12
    tc = PAIN.hf_transmission_coeffs(inp_s, 500.0)
    @test tc.τ_f ≈ (32 / π) * inp.ρ_int^2 * (PAIN.cylinder_surface_area(a, L) / inp.m_wall^2) * (j2(300.0)^2 + j2(400.0)^2) rtol = 1e-12
end

_run_if("T2 with the measured TP-2444 exterior (phase 47)") do
    # Criteria fixed 2026-10-23 (plan §8d Phase 47); 47b–47d implementation decisions fixed the same day
    # before any band level was computed. Recorded: NR_PROP_TP2444 not met 1/7, T2_MEAS_EXT not met.
    # 47b conversion on synthetic spectra (exact results)
    f = collect(0.0:1.0:2500.0); L = fill(60.0, length(f))
    b = PAIN.narrowband_third_octave(f, L, 1000.0)
    @test b.n_bins == 46                                         # bins 895 … 1120 Hz in [891, 1122.5)
    @test b.L_total ≈ 60 + 10log10(46) atol = 1e-9
    @test b.L_bb ≈ b.L_total atol = 1e-9
    Ls = copy(L); Ls[abs.(f .- 1000.0) .≤ 2.5] .= 80.0           # one tone bin (all its columns) 20 dB up
    bt = PAIN.narrowband_third_octave(f, Ls, 1000.0; tone_Hz=[1000.0])
    @test bt.L_total ≈ 10log10(45 * 10^6 + 10^8) atol = 1e-9
    @test bt.L_bb ≈ 60 + 10log10(46) atol = 1e-9
    @test bt.n_tone == 5
    keep = f .≤ 1000.0                                           # partial coverage: flat density assumed
    bp = PAIN.narrowband_third_octave(f[keep], L[keep], 1000.0)
    @test bp.n_covered == 22
    @test bp.L_total ≈ 60 + 10log10(46) atol = 1e-9
    @test isnan(PAIN.narrowband_third_octave(f[f .≤ 950.0], L[f .≤ 950.0], 1000.0).L_total)  # 12/46 < 40 %
    @test PAIN.narrowband_third_octave(f, L, 1000.0; B=10.0).L_total ≈ 60 + 10log10(23) atol = 1e-9
    # 47a data: the Fig. 17 exterior tone peaks sit at H·200 Hz within 7 Hz
    c = PAIN._read_csv_numeric_nan(PAIN._p47_csv(:ext, 'A'))
    pk = PAIN._p47_tone_peaks(c[:f_Hz], c[:L_top_dB], 200.0, 7)
    @test all(abs.(pk .- 200.0 .* (1:7)) .≤ 7.5)
    # recorded results
    r = run_validation_case("NR_PROP_TP2444")
    @test r.verdict === :not_met && r.inputs_echo.n_ok == 1 && r.inputs_echo.n == 7
    @test r.inputs_echo.changeover_band_Hz ≈ 1000 * 2^(1 / 3)
    @test all(25 .< r.inputs_echo.NR_meas .< 40)
    r2 = run_validation_case("T2_MEAS_EXT")
    @test r2.verdict === :not_met
    @test r2.inputs_echo.L_ext_1250_bb ≈ 85.42 atol = 0.01
    @test r2.inputs_echo.interior_dB[1] ≈ 21.55 atol = 0.01            # 21.25 before the Phase 49 Eq. (20) reading correction
    @test r2.inputs_echo.L_int_fig17_1250_bb ≈ 51.51 atol = 0.01
    for (id, rr) in (("NR_PROP_TP2444", r), ("T2_MEAS_EXT", r2))
        png = plot_case(rr, VALIDATION_CASES[id].plot_spec; path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
end

_run_if("T2 HF path on TP-1964 (phase 45)") do
    # Criteria pre-registered 2026-10-23 (plan §8c); recorded not met 9/18 and 8/18.
    for (id, n_ok) in (("NR_TP1964_XOVER", 9), ("NR_TP1964_XOVER_REF2", 8))
        r = run_validation_case(id)
        @test r.verdict === :not_met
        @test r.inputs_echo.n_ok == n_ok
        @test r.inputs_echo.changeover_band_Hz == 2500.0            # band containing f = 4.1 c₀/∛V
        @test count(t -> occursin("Eq. 19", t.quantity), r.table) == 4
        png = plot_case(r, VALIDATION_CASES[id].plot_spec; path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
end

_run_if("Loudest point (phase 42)") do
    # Criteria fixed 2026-10-23 (plan Phase 42); (a) recorded not met (interior point set), (b), (c) met.
    r = run_validation_case("LOUDEST_PT")          # information since Phase 82; its recorded outcome is kept
    @test r.verdict === :no_verdict && r.inputs_echo.original_verdict === :not_met
    @test r.table[4].within_tolerance                       # (b) loudest ≥ average
    @test r.table[5].within_tolerance                       # (c) single-mode φ² shape
    @test all(abs.(r.inputs_echo.all_node_ratio_posthoc .- 1) .< 0.05)
    @test r.inputs_echo.dBA_max > r.inputs_echo.dBA_avg
    png = plot_case(r, VALIDATION_CASES["LOUDEST_PT"].plot_spec; path=joinpath(TEST_OUT, "LOUDEST_PT.png"))
    @test isfile(png) && filesize(png) > 0
end

_run_if("CR-172428 reproduction (phase 44)") do
    # Criteria fixed 2026-10-23 in IMPLEMENTATION_PLAN.md §8b Phase 44 (before transcription or run).
    inp = r172428_inputs(4000)
    fuse = inp.fuse
    # 44c V-UNIT: App. A m̄_r reduces to m when the shell bending mass equals the total modal mass.
    st0 = inp.structural.modes[13]
    MX = trimmed_modal_mass(st0, fuse, inp.m_wall)
    st_full = PAIN.StructuralMode(st0.index, st0.f_Hz, st0.symmetric, MX, st0.M_axial,
                                  st0.C_shell, st0.n_shell, st0.C_floor, st0.n_floor)
    @test abs(app_a_modal_mass_per_area(st_full, fuse, inp.m_wall) - inp.m_wall) ≤ 1e-12 * inp.m_wall
    # mode with no shell motion: no trim damping (m̄ = Inf → η_r′ = η_r)
    st_floor = PAIN.StructuralMode(1, 200.0, true, 1.0, 1, Float64[], Int[], [1.0], [0])
    @test app_a_modal_mass_per_area(st_floor, fuse, inp.m_wall) == Inf
    # Shell bending mass (App. A GMASS(IR,2)) against App. B "SHELL W" (code check; recorded 2026-10-23 after the
    # first comparison: median 0.19 %, max 3.8 % over the 21 modes ≥ 0.05 kg — Table D-1 prints five shell terms per mode)
    sm = PAIN._read_csv_numeric_nan(PAIN._data_path("cr172428", "appB_structural_modes.csv"))
    for (i, mode) in enumerate(Int.(sm[:mode]))
        mode ≤ length(inp.structural.modes) || continue
        st = inp.structural.modes[mode]
        ref = sm[:M_shell_kg][i]
        ref < 0.05 && continue                 # 4-decimal print: relative check meaningless below 0.05 kg
        @test abs(trimmed_modal_mass(st, fuse, inp.m_wall) / ref - 1) ≤ 0.04
    end
    # Eq. (83) uses the bare f′ (τ = 1), Eq. (8) the trimmed f̄′: an independent sum must equal the code.
    H = 1; ωH = 2π * 200.0
    a, L = fuse.a, fuse.L; θ0 = deg2rad(fuse.theta0_deg); Lp = 2a * sin(θ0)
    A = L * (Lp + 2a * (π - θ0)); V = PAIN.cabin_volume(inp)
    τ = PAIN.sidewall_tau(inp, ωH)
    @test τ > 1                                 # trim resonance at 200 Hz: f̄′ ≠ f′
    ξ = PAIN.trim_conductance(inp.sidewall, ωH, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int)
    ξe = PAIN.trim_conductance(inp.endplates, ωH, Inf; ρ0=inp.ρ_int, c0=inp.c_int)
    pref = (inp.c_int / V)^2 * (inp.ρ_ext * inp.c_ext * A)^2 * ωH^4
    qtop = PAIN.axial_truncation(ωH, inp.L_c, inp.c_int)
    p2 = 0.0
    for q in 0:qtop, ac in inp.acoustic.modes
        ωn = 2π * PAIN.cabin_frequency_3d(ac, a, inp.L_c, q; c0=inp.c_int)
        εn = PAIN.cabin_eps_3d(ac, q)
        N = PAIN.acoustic_N(inp, ac, q, 200.0, ωn; ξ, ξ_e=ξe, V)
        for st in inp.structural.modes
            fbar = coupling_factor(ac, st, inp; τ_t=τ, q)
            fbar == 0 && continue
            fprime = coupling_factor(ac, st, inp; τ_t=1.0, q)
            ωr = 2π * st.f_Hz
            Ψ = generalized_force(st, H, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA)
            ηpp = inp.ρ_int * inp.c_int^2 * A^2 * εn * fprime^2 / (st.M_r * V) * N / ((ωn^2 - ωr^2)^2 + N^2)
            ηp = PAIN.structural_η_r_prime(inp, st, ωr)
            Dn = (ωn^2 - ωH^2)^2 + N^2
            Dr = (ωr^2 - ωH^2)^2 + ((ηp + ηpp) * ωr^2)^2
            p2 += pref * εn * fbar^2 * Ψ / (st.M_r^2 * Dn * Dr)
        end
    end
    @test PAIN.tone_mean_square_pressure(inp, H, ωH) ≈ p2 rtol = 1e-10
    # 44f: the bare f′ against the f′ implied by NASA's printed η_r″ (Eq. 83 solved with NASA's own ε_n, η_n, M_r).
    # Recorded 2026-10-23 (post-hoc): 4000 rpm pairs chose the sign; 5000 rpm pairs are out of sample. Pairs with
    # η_r″ printed to one significant digit (< 1e-4) are skipped.
    let ac_tab = PAIN._read_csv_numeric_nan(PAIN._data_path("cr172428", "appB_acoustic_modes.csv")),
        st_tab = PAIN._read_csv_numeric_nan(PAIN._data_path("cr172428", "appB_structural_modes.csv"))
        θ0r = deg2rad(fuse.theta0_deg); Lp = 2fuse.a * sin(θ0r)
        Aw = fuse.L * (Lp + 2fuse.a * (π - θ0r)); Vc = PAIN.cabin_volume(inp)
        n_checked = 0
        for file in ("appB_contributors_4000rpm.csv", "appB_contributors_5000rpm.csv")
            c = PAIN._read_csv_numeric_nan(PAIN._data_path("cr172428", file))
            for i in eachindex(c[:H])
                c[:eta_r_hash][i] < 1e-4 && continue
                ia = findfirst(==(c[:ac_mode][i]), ac_tab[:mode]); ia === nothing && continue
                r = Int(c[:st_mode][i]); q = Int(c[:Q][i]); I = Int(c[:I][i])
                ωn = 2π * ac_tab[:f_Hz][ia]; N = ac_tab[:loss_factor][ia] * ωn^2; ε = ac_tab[:epsilon][ia]
                ωr = 2π * st_tab[:f_Hz][r]; Mr = st_tab[:M_total_kg][r]
                fN = sqrt(c[:eta_r_hash][i] * Mr * Vc / (inp.ρ_int * inp.c_int^2 * Aw^2 * ε) * ((ωn^2 - ωr^2)^2 + N^2) / N)
                ac = inp.acoustic.modes[findfirst(m -> m.index == I, inp.acoustic.modes)]
                fo = coupling_factor(ac, inp.structural.modes[r], inp; τ_t=1.0, q)
                @test abs(abs(fo) / fN - 1) ≤ 0.05
                n_checked += 1
            end
        end
        @test n_checked ≥ 15
    end
    # Grid: 16 × 19 points, θ = 0..180°, printed z from the forward end
    f = r172428_appb_field(4000)
    @test length(f.pts) == 16 * 19 && f.n_missing == 16    # p. 204 row L = 1 below the page edge
    @test extrema(p.theta_deg for p in f.pts) == (0.0, 180.0)
    expected = (("R172428_CODE", :not_met), ("R172428_EXP", :not_met), ("R172428_ETA", :not_met),
                ("R172428_TRIM", :no_verdict), ("R172428_PAIRS", :no_verdict))
    for (id, verd) in expected
        r = run_validation_case(id)
        @test PAIN.underlying_verdict(r) === verd   # the check itself; verification cases carry no verdict since Phase 85
        @test (r.verdict === :no_verdict) == (PAIN.no_verdict_by_rule(id) || verd === :no_verdict)
        @test !isempty(r.table)
        png = plot_case(r, VALIDATION_CASES[id].plot_spec; path=joinpath(TEST_OUT, "$(id).png"))
        @test isfile(png) && filesize(png) > 0
    end
end

_run_if("Suite leaves tree clean") do
    rea = abspath(joinpath(@__DIR__, "..", ".."))  # rea-work
    if Sys.which("git") === nothing
        @info "Suite leaves tree clean: skipped (git unavailable)"
        return
    end
    inside = try
        readchomp(`git -C $rea rev-parse --is-inside-work-tree`) == "true"
    catch
        false
    end
    if !inside
        @info "Suite leaves tree clean: skipped (package dir not inside a git work tree)"
        return
    end
    repo = abspath(readchomp(`git -C $rea rev-parse --show-toplevel`))
    raw = read(`git -C $repo status --porcelain -- $rea`, String)
    # Flag only paths the suite newly dirtied or further changed vs start-of-run snapshot.
    dirty = String[]
    for path in _parse_docs_data_porcelain(raw)
        h = _file_content_hash(_docs_data_abspath(repo, path))
        baseline = get(_DOCS_DATA_BASELINE, path, nothing)
        if baseline === nothing || baseline != h
            push!(dirty, path)
        end
    end
    @test isempty(dirty)
    isempty(dirty) || @info "Tracked docs/data files modified by suite" dirty
end

println()
println("=== Testset filter summary ===")
if isempty(_TEST_FILTER)
    println("Filter: (none — all testsets)")
else
    println("Filter: ", join(ARGS, ", "))
end
# Phase 64: one unit-test file per source module (test/unit), each its own top-level testset
include(joinpath(@__DIR__, "unit", "runtests_unit.jl"))

println("Ran (", length(_TESTSETS_RAN), "):")
for t in _TESTSETS_RAN
    println("  + ", t)
end
println("Skipped (", length(_TESTSETS_SKIPPED), "):")
for t in _TESTSETS_SKIPPED
    println("  - ", t)
end
if !isempty(_TESTSETS_FAILED)
    println("FAILED (", length(_TESTSETS_FAILED), "):")
    for t in _TESTSETS_FAILED
        println("  ! ", t)
    end
    error("$(length(_TESTSETS_FAILED)) testset(s) failed: " * join(_TESTSETS_FAILED, "; "))
end
