# needs LinearAlgebra, Random (loaded by runtests_unit.jl)
# Unit tests: src/mrp_appd.jl (Phase 64). App. D Rayleigh–Ritz against closed forms and its own constraints.
@testset "geometry and constitutive scalars" begin
    g = PAIN.appd_test_article_geometry()
    @test g.a == 0.508 && g.theta0_deg == 56.6 && g.L == PAIN.test_article_length() && g.t_skin == 0.00081
    f = PAIN.FuselageGeometry(2.0, 0.6, 50.0)
    gf = PAIN.AppDGeometry(f)
    @test gf.L == 2.0 && gf.a == 0.6 && gf.theta0_deg == 50.0
    k, D = PAIN._appd_kD(70e9, 0.3, 0.002)
    @test k ≈ 70e9 * 0.002 / 0.91 && D ≈ 70e9 * 0.002^3 / (12 * 0.91)
    sp = PAIN._appd_shell_props(g)
    @test sp.t_eq ≈ g.t_skin + g.A_stringer / g.d_stringer + g.A_frame / g.ell_frame
    @test sp.ms ≈ g.ρ * sp.t_eq && sp.D_xs > PAIN._appd_kD(g.E, g.ν, g.t_skin)[2]
    fp = PAIN._appd_floor_props(g)
    @test fp.Lp ≈ 2 * 0.508 * sind(56.6) && fp.mf ≈ g.ρ * fp.t_eq_f
end
@testset "shell harmonic: Donnell–Mushtari closed form (Soedel / Leissa SP-288)" begin
    f = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    g = PAIN.AppDGeometry(f; A_stringer=0.0, I_stringer=0.0, A_frame=0.0, I_frame=0.0)   # bare shell
    for (m, n) in ((1, 0), (2, 1), (1, 2), (1, 4), (2, 6), (3, 8))
        dm = PAIN.donnell_mushtari_frequency_Hz(m, n, g.L, g.a, g.t_skin, g.E, g.ν, g.ρ)
        @test PAIN.appd_shell_condensed_frequency_Hz(m, n, g) ≈ dm rtol = 0.01      # in-plane inertia neglected
        @test PAIN.appd_shell_harmonic_frequency_Hz(m, n, g) ≤ dm * (1 + 1e-9)    # in-plane inertia only lowers ω
        @test PAIN.appd_smeared_stringer_frequency_Hz(m, n, g) ≈ dm rtol = 1e-12     # no stiffeners: same formula
    end
    # bending-dominated limit (long shell, large n): ω² → D n⁴/(ρ t a⁴)
    E, ν, ρ, t, a = 70e9, 0.3, 2700.0, 0.001, 0.5
    D = E * t^3 / (12 * (1 - ν^2))
    @test PAIN.donnell_mushtari_frequency_Hz(1, 12, 1e3, a, t, E, ν, ρ) ≈ sqrt(D * 12^4 / (ρ * t * a^4)) / 2π rtol = 1e-6
    sp = PAIN._appd_shell_props(g)
    K, Mm = PAIN._appd_shell_harmonic_KM(2, 3, g.L, sp)
    @test K ≈ K' && all(eigvals(Symmetric(K)) .≥ -1e-6 * maximum(abs, K))
    @test Mm ≈ sp.ms * (g.L / 2) * π * g.a * [1 0 0; 0 1 0; 0 0 1]
    K0, M0 = PAIN._appd_shell_harmonic_KM(2, 0, g.L, sp; arc_frac=0.5)
    @test M0[1, 1] ≈ sp.ms * (g.L / 2) * π * g.a                                # half of 2π
end
@testset "floor harmonic and basis bookkeeping" begin
    g = PAIN.appd_test_article_geometry()
    fp = PAIN._appd_floor_props(g)
    K, Mm = PAIN._appd_floor_harmonic_KM(2, 3, g.L, fp, true)
    μ, ky = 2π / g.L, 3π / fp.Lp
    # SS orthotropic Kirchhoff plate (Phase 78d F2): ω² = (Dx μ⁴ + 2H μ²k² + Dy k⁴)/m
    @test K[3, 3] / Mm[3, 3] ≈ (fp.Dx * μ^4 + 2 * fp.H * μ^2 * ky^2 + fp.Dy * ky^4) / fp.mf
    E, ν, t = g.E, g.ν, fp.t_eq_f; D = E * t^3 / (12 * (1 - ν^2))
    @test fp.Dx ≈ D + 2E * g.I_floor_beam / fp.Lp && fp.Dy ≈ D + E * g.I_floor_beam / g.ell_frame && fp.H ≈ D
    @test fp.Dy > fp.Dx                                                   # supports every 0.2 m vs two beams on 0.85 m
    @test_throws ErrorException PAIN._appd_floor_harmonic_KM(1, -1, g.L, fp, true)
    @test_throws ErrorException PAIN._appd_floor_harmonic_KM(1, -1, g.L, fp, false)
    b = PAIN._appd_basis(2, true; n_circ=4, n_floor_max=3)
    @test b.p_floor == 0:3 && b.n_shell == 0:4 && b.ndof == 3 * 5 + 3 * 4
    @test PAIN._appd_basis(2, false; n_floor_max=3).p_floor == 0:3                  # p = 0: uniform floor sway (78d-4 J5)
    # J3/J5 null functions: symmetric v_0 (shell and floor), antisymmetric u_0 and w_0 (shell and floor)
    @test size(PAIN._appd_null_rows(b)) == (2, b.ndof) && PAIN._appd_null_rows(b)[1, PAIN._shell_dof(b, 1, 2)] == 1
    ba = PAIN._appd_basis(2, false; n_circ=4, n_floor_max=3)
    Ra = PAIN._appd_null_rows(ba)
    @test size(Ra, 1) == 4 && Ra[2, PAIN._shell_dof(ba, 1, 3)] == 1 && Ra[4, PAIN._floor_dof(ba, 1, 3)] == 1
    dofs = vcat([PAIN._shell_dof(b, i, c) for i in 1:b.ns for c in 1:3], [PAIN._floor_dof(b, j, c) for j in 1:b.np for c in 1:3])
    @test sort(dofs) == 1:b.ndof                                                    # one-to-one DOF map
    K, M, _, _ = PAIN._appd_assemble_KM(b, g)
    @test K ≈ K' && M ≈ M'
    @test K[PAIN._shell_dof(b, 1, 3), PAIN._shell_dof(b, 2, 3)] == 0                # harmonics uncoupled before (D.17)
    # J2: the shell block is the whole circumference (closed cylinder, Fig. D-1), not the cabin arc
    K3, M3 = PAIN._appd_shell_harmonic_KM(2, 2, g.L, PAIN._appd_shell_props(g); arc_frac=1.0)
    @test K[PAIN._shell_dof(b, 3, 3), PAIN._shell_dof(b, 3, 3)] ≈ K3[3, 3] && M[PAIN._shell_dof(b, 3, 1), PAIN._shell_dof(b, 3, 1)] ≈ M3[1, 1]
end
@testset "floor membrane block against the integrated energy (Phase 78d-4 J6)" begin
    g = PAIN.appd_test_article_geometry()
    fp = PAIN._appd_floor_props(g)
    ys = range(-fp.Lp / 2, fp.Lp / 2; length=4001); dy = step(ys)
    trap(f) = dy * (sum(f) - (first(f) + last(f)) / 2)
    for sym in (true, false), (M, p) in ((1, 1), (2, 3), (3, 2))
        μ, k = M * π / g.L, p * π / fp.Lp
        Ψu, dΨu = sym ? (cos.(k .* ys), -k .* sin.(k .* ys)) : (sin.(k .* ys), k .* cos.(k .* ys))
        Ψv, dΨv = sym ? (sin.(k .* ys), k .* cos.(k .* ys)) : (-cos.(k .* ys), k .* sin.(k .* ys))   # antisymmetric v = −cos
        a = (-μ .* Ψu, zero(ys)); bb = (zero(ys), dΨv); c = (dΨu, μ .* Ψv)       # ε_x, ε_y, γ per unit U and V
        Kn = [g.L / 2 * trap(fp.k_f .* (a[i] .* a[j] .+ bb[i] .* bb[j] .+ fp.ν .* (a[i] .* bb[j] .+ a[j] .* bb[i])) .+
                             fp.Gt .* c[i] .* c[j]) for i in 1:2, j in 1:2]
        K, _ = PAIN._appd_floor_harmonic_KM(M, p, g.L, fp, sym)
        @test K[1:2, 1:2] ≈ Kn rtol = 1e-6
    end
    b = PAIN._appd_basis(1, false; n_circ=4, n_floor_max=3)
    @test PAIN._appd_constraint_matrix(b, g)[2, PAIN._floor_dof(b, 3, 2)] ≈ -1       # p = 2 edge v = −cos π = +1
end
@testset "constraints (D.4/D.17) and reduction" begin
    g = PAIN.appd_test_article_geometry()
    θ0 = deg2rad(g.theta0_deg)
    b = PAIN._appd_basis(1, true; n_circ=6, n_floor_max=4)
    C = PAIN._appd_constraint_matrix(b, g)
    @test size(C) == (4, b.ndof) && size(PAIN._appd_constraint_matrix(b, g; rigid=false), 1) == 3
    @test C[1, PAIN._shell_dof(b, 3, 1)] ≈ cos(2θ0)                                   # u_s = u_p row, n = 2
    @test C[3, PAIN._floor_dof(b, 1, 3)] ≈ -1                                         # w_p, p = 0 at the edge
    K, M, _, _ = PAIN._appd_assemble_KM(b, g)
    Kr, Mr, E = PAIN._appd_reduce(K, M, C)
    @test maximum(abs, C * E) ≤ 1e-10 && E' * E ≈ I(size(E, 2))
    @test size(E, 2) == b.ndof - 4
    q = E * randn(MersenneTwister(7), size(E, 2))
    @test maximum(abs, PAIN.appd_constraint_residuals(q, b, g)) ≤ 1e-10
    @test PAIN.appd_max_constraint_residual(g) ≤ 1e-10
    @test PAIN.appd_mode_orthogonality(g) ≤ 1e-10
    # shape extraction normalizes the peak normal displacement to 1 and scales M_r by 1/peak²
    Cs, ns, Cf, nf, Mr2 = PAIN._appd_extract_shapes(2 .* q, b, g, 8.0)
    Cs1, _, _, _, Mr1 = PAIN._appd_extract_shapes(q, b, g, 2.0)
    @test Cs ≈ Cs1 && Mr2 ≈ Mr1
    # J1: the returned shape (App. D convention, θ from the top, floor upward) reproduces the solver's own junction
    # kinematics: shell outward w = v_p sin θ0 − w_p,up cos θ0 at the junction (θ0 from the bottom, y = +Lp/2)
    for sym in (true, false)
        b2 = PAIN._appd_basis(1, sym; n_circ=6, n_floor_max=4)
        C2 = PAIN._appd_all_constraints(b2, g)
        K2, M2, _, fp2 = PAIN._appd_assemble_KM(b2, g)
        _, _, E2 = PAIN._appd_reduce(K2, M2, C2)
        q2 = E2 * randn(MersenneTwister(11), size(E2, 2))
        Cs2, ns2, Cf2, nf2, _ = PAIN._appd_extract_shapes(q2, b2, g, 1.0)
        md = PAIN.StructuralMode(1, 100.0, sym, 1.0, 1, Cs2, ns2, Cf2, nf2)
        raw = (sym ? 1 : -1) * (-1)^b2.n_shell[findfirst(==(ns2[1]), b2.n_shell)] * q2[PAIN._shell_dof(b2, findfirst(==(ns2[1]), b2.n_shell), 3)]
        scale = raw / Cs2[1]
        vp = sum(q2[PAIN._floor_dof(b2, j, 2)] * (sym ? sin(p * π / 2) : -cos(p * π / 2)) for (j, p) in enumerate(b2.p_floor)) / scale
        wup = sum((sym ? cos(p * π / 2) : sin(p * π / 2)) * C for (C, p) in zip(Cf2, nf2); init=0.0)
        @test PAIN.shell_circumferential(md, θ0) ≈ vp * sin(θ0) - wup * cos(θ0) atol = 1e-8
    end
end
@testset "appd_modes / build_structural_modes / generalized mass" begin
    fuse = PAIN.FuselageGeometry(PAIN.test_article_length(), 0.508, 56.6)
    sm = PAIN.appd_modes(fuse; n_modes=12)
    @test length(sm.modes) == 12 && issorted([m.f_Hz for m in sm.modes]) && all(m.f_Hz ≤ 5000 for m in sm.modes)
    # J3: no spurious mode with a zero shape; J4: no mode dropped by a frequency dedup (count against the families)
    g0 = PAIN.appd_test_article_geometry()
    sm2 = PAIN.appd_modes(g0; n_modes=1000, n_axial=3, f_max_Hz=900.0)
    θa = range(deg2rad(g0.theta0_deg), 2π - deg2rad(g0.theta0_deg); length=181); Lp0 = 2g0.a * sind(g0.theta0_deg)
    peak(m) = max(maximum(θ -> abs(PAIN.shell_circumferential(m, θ)), θa),
                  maximum(y -> abs(sum((m.symmetric ? cos(n * π * y / Lp0) : sin(n * π * y / Lp0)) * C for (C, n) in zip(m.C_floor, m.n_floor); init=0.0)), range(-Lp0 / 2, Lp0 / 2; length=81)))
    @test all(m -> peak(m) > 0.9, sm2.modes)                                       # unit-maximum shapes, none zero
    nfam = 0
    for Mx in 1:3, sym in (true, false)
        bx = PAIN._appd_basis(Mx, sym)
        Kx, Mmx, _, _ = PAIN._appd_assemble_KM(bx, g0)
        Krx, Mrx, _ = PAIN._appd_reduce(Kx, Mmx, PAIN._appd_all_constraints(bx, g0))
        nfam += count(w2 -> 1.0 ≤ w2 && sqrt(w2) / 2π ≤ 900.0, eigvals(Symmetric(Krx), Symmetric(Mrx)))
    end
    @test length(sm2.modes) == nfam
    @test PAIN.build_structural_modes(fuse; structural_solver=:appd, n_keep=12).modes[1].f_Hz == sm.modes[1].f_Hz
    @test PAIN.build_structural_modes(fuse).modes[1].f_Hz == 188.52
    @test length(PAIN.build_structural_modes(fuse; structural_solver=:ritz, n_keep=10).modes) == 10
    @test_throws ErrorException PAIN.build_structural_modes(fuse; structural_solver=:bad)
    g = PAIN.appd_test_article_geometry()
    sp = PAIN._appd_shell_props(g)
    one = PAIN.StructuralMode(1, 100.0, true, 1.0, 1, [1.0], [0], Float64[], Int[])
    θ0 = deg2rad(g.theta0_deg)
    @test PAIN.appd_generalized_mass_from_shape(one, g) ≈ sp.ms * g.a * (2π - 2θ0) * g.L / 2 rtol = 1e-9
    fl = PAIN.StructuralMode(1, 100.0, true, 1.0, 1, Float64[], Int[], [1.0], [0])
    fp = PAIN._appd_floor_props(g)
    @test PAIN.appd_generalized_mass_from_shape(fl, g) ≈ fp.mf * fp.Lp * g.L / 2 rtol = 1e-9
end
@testset "identity matching of modes to Table D-1 (Phase 78a)" begin
    d1 = structural_modes_from_table_d1()
    n, pairs = match_modes_by_identity(d1)
    @test n == 32 && all(p -> p.found && p.err < 1e-12, pairs)          # positive control: Table D-1 against itself
    # right frequencies, wrong identities (symmetry flipped): must fail, unlike frequency-only matching
    flip = StructuralModes([StructuralMode(x.index, x.f_Hz, !x.symmetric, x.M_r, x.M_axial, x.C_shell, x.n_shell,
                                           x.C_floor, x.n_floor) for x in d1.modes], d1.L, d1.a, d1.theta0_deg, "flipped")
    @test match_modes_by_identity(flip)[1] == 0
    @test match_ritz_to_table_d1(flip; tol_frac=0.05)[1] == 32           # the old matcher passes it: the defect
    # a frequency 10 % off with the right identity is found but not within 5 %
    off = StructuralModes([StructuralMode(x.index, 1.1x.f_Hz, x.symmetric, x.M_r, x.M_axial, x.C_shell, x.n_shell,
                                          x.C_floor, x.n_floor) for x in d1.modes], d1.L, d1.a, d1.theta0_deg, "off")
    n2, p2 = match_modes_by_identity(off)
    @test n2 == 0 && all(p -> p.found && p.err ≈ 0.1, p2)
    @test PAIN._dominant_order([0.1, -0.5, 0.2], [1, 3, 2]) == 3 && PAIN._dominant_order(Float64[], Int[]) == -1
end
@testset "stiffener section inertias (Phase 78d F1)" begin
    # independent check: I = ∫ (y − ȳ)² dA over thin strips of the mid-line section
    function strips_I(rects)                        # rects: (x0, x1, y0, y1) filled rectangles
        A = 0.0; Sy = 0.0; pts = Tuple{Float64,Float64}[]
        for (x0, x1, y0, y1) in rects, y in range(y0, y1; length=2001)[1:end-1] .+ (y1 - y0) / 4000
            dA = (x1 - x0) * (y1 - y0) / 2000; push!(pts, (y, dA)); A += dA; Sy += y * dA
        end
        ȳ = Sy / A
        return sum(dA * (y - ȳ)^2 for (y, dA) in pts)
    end
    h, b, t = 0.038, 0.017, 0.00081
    ch = [(0.0, t, -h / 2, h / 2), (0.0, b, h / 2 - t / 2, h / 2 + t / 2), (0.0, b, -h / 2 - t / 2, -h / 2 + t / 2)]
    @test channel_centroidal_I(h, b, t) ≈ strips_I(ch) rtol = 1e-3
    @test channel_centroidal_I(h, 0.0, t) ≈ t * h^3 / 12                      # no flanges: a plain web
    ha, ba, ta = 0.0112, 0.00953, 0.00051
    an = [(0.0, ta, 0.0, ha), (0.0, ba, -ta / 2, ta / 2)]
    @test angle_centroidal_I(ha, ba, ta) ≈ strips_I(an) rtol = 2e-2
    @test angle_centroidal_I(ha, 0.0, ta) ≈ ta * ha^3 / 12                     # no base leg: a plain leg
    @test PAIN.MRP_I_FRAME ≈ channel_centroidal_I(0.038, 0.017, 0.00081)
    # V1 (Phase 78d-3): floor beam about the floor mid-plane, which lies h/2 + t_floor/2 above the channel centroid
    about(rects, y0) = sum(((x1 - x0) * (y1 - y0r) / 2000) * (y - y0)^2 for (x0, x1, y0r, y1) in rects
                           for y in range(y0r, y1; length=2001)[1:end-1] .+ (y1 - y0r) / 4000)
    @test PAIN.MRP_I_FLOOR_BEAM ≈ about(ch, h / 2 + 0.00081 / 2) rtol = 1e-3
    @test PAIN.MRP_I_FLOOR_BEAM > 2 * PAIN.MRP_I_FRAME
    @test PAIN.MRP_I_FRAME / (0.038^3 * 0.00081 / 12) > 3.5                   # the flanges were missing before Phase 78d
end
@testset "shape (MAC) pairing of modes to Table D-1 (Phase 78d-3)" begin
    d1 = structural_modes_from_table_d1()
    n, pairs = match_modes_by_shape(d1)
    @test n == 32 && all(p -> p.found && p.mac > 0.999 && p.err < 1e-12, pairs)      # Table D-1 against itself
    # right frequencies and identities, wrong shapes: give each mode the shape of the next mode of its (sym, m) family
    fam = Dict{Tuple{Bool,Int},Vector{Int}}()
    for (i, x) in enumerate(d1.modes); push!(get!(fam, (x.symmetric, x.M_axial), Int[]), i); end
    shuffled = copy(d1.modes)
    for idx in values(fam), (k, i) in enumerate(idx)
        j = idx[mod1(k + 1, length(idx))]; y = d1.modes[j]; x = d1.modes[i]
        shuffled[i] = StructuralMode(x.index, x.f_Hz, x.symmetric, x.M_r, x.M_axial, y.C_shell, y.n_shell, y.C_floor, y.n_floor)
    end
    ns, ps = match_modes_by_shape(StructuralModes(shuffled, d1.L, d1.a, d1.theta0_deg, "shuffled"))
    @test ns < 16                                                 # most modes now pair with a wrong frequency
    off = StructuralModes([StructuralMode(x.index, 1.1x.f_Hz, x.symmetric, x.M_r, x.M_axial, x.C_shell, x.n_shell,
                                          x.C_floor, x.n_floor) for x in d1.modes], d1.L, d1.a, d1.theta0_deg, "off")
    @test match_modes_by_shape(off)[1] == 0
    @test modal_assurance([1.0, 2.0], [2.0, 4.0]) ≈ 1.0 && modal_assurance([1.0, 0.0], [0.0, 1.0]) == 0.0
    f = mode_shape_field(d1.modes[1], d1.a, d1.theta0_deg)
    @test length(f) == 181 + 61 && maximum(abs, f) > 0
end
