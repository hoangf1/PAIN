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
    @test K[3, 3] / Mm[3, 3] ≈ fp.Df / fp.mf * ((2π / g.L)^2 + (3π / fp.Lp)^2)^2   # SS Kirchhoff plate
    @test_throws ErrorException PAIN._appd_floor_harmonic_KM(1, -1, g.L, fp, true)
    @test_throws ErrorException PAIN._appd_floor_harmonic_KM(1, 0, g.L, fp, false)
    b = PAIN._appd_basis(2, true; n_circ=4, n_floor_max=3)
    @test b.p_floor == 0:3 && b.n_shell == 0:4 && b.ndof == 3 * 5 + 3 * 4
    @test PAIN._appd_basis(2, false; n_floor_max=3).p_floor == 1:3
    dofs = vcat([PAIN._shell_dof(b, i, c) for i in 1:b.ns for c in 1:3], [PAIN._floor_dof(b, j, c) for j in 1:b.np for c in 1:3])
    @test sort(dofs) == 1:b.ndof                                                    # one-to-one DOF map
    K, M, _, _ = PAIN._appd_assemble_KM(b, g)
    @test K ≈ K' && M ≈ M'
    @test K[PAIN._shell_dof(b, 1, 3), PAIN._shell_dof(b, 2, 3)] == 0                # harmonics uncoupled before (D.17)
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
end
@testset "appd_modes / build_structural_modes / generalized mass" begin
    fuse = PAIN.FuselageGeometry(PAIN.test_article_length(), 0.508, 56.6)
    sm = PAIN.appd_modes(fuse; n_modes=12)
    @test length(sm.modes) == 12 && issorted([m.f_Hz for m in sm.modes]) && all(m.f_Hz ≤ 5000 for m in sm.modes)
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
