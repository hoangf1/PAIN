# Unit tests: src/mode_animation.jl (Phase 64; Phase 63 structural frames). Display only: the tests
# check that frames carry the node values unchanged, are periodic, and that renders are written.
@testset "acoustic mode frames" begin
    @test PAIN.axial_factor(2, 2.0)(0.5) ≈ cos(π / 2) atol = 1e-15
    res = PAIN.cyl2d_c1_for_display()
    @test res.c0 == PAIN.TABLE_C1_C0 && res.NY == 10 && length(res.modes) == 20
    ma = first(m for m in res.modes if !m.symmetric)
    k = first(kk for kk in keys(ma.phi_nodes) if kk[1] > 0)
    @test PAIN._phi_half(ma, k...) == ma.phi_nodes[k] && isnan(PAIN._phi_half(ma, 999, 0))
    @test PAIN._phi_full(ma, -k[1], k[2]) == -ma.phi_nodes[k]
    nodes = PAIN._full_section_nodes(res, ma)
    ix = findfirst(==(k[1]), nodes.ms); iy = findfirst(==(k[2]), nodes.ns)
    @test nodes.φ[ix, iy] == ma.phi_nodes[k] && nodes.mask[ix, iy]                  # node values unchanged
    i0 = findfirst(==(0), nodes.ms)
    @test all(nodes.φ[i0, j] == 0 for j in eachindex(nodes.ns) if nodes.mask[i0, j])  # antisymmetric centreline
    xs, ys, φd = PAIN._interpolate_drawing_field(nodes; grid=21)
    @test length(xs) == 21 && size(φd) == (21, 21)
    @test maximum(abs, filter(!isnan, φd)) ≤ maximum(abs, filter(!isnan, nodes.φ)) + 1e-12   # bilinear: no overshoot
    nm = PAIN._nodal_mask([1.0 0.01; NaN -0.5])
    @test nm == Bool[0 1; 0 0]
    fr = PAIN.mode_animation_frames(res, 3; nframes=8, grid=21)
    v = .!isnan.(fr.φ0)
    @test fr.frames[1][v] ≈ fr.φ0[v]
    @test fr.frames[5][v] ≈ -fr.φ0[v]                                                 # half period: sign flip
    @test fr.fig_c3 == PAIN.FIG_C3_PRINTED_ROWS[4] && PAIN.mode_animation_frames(res, 9; nframes=2, grid=11).fig_c3 === nothing
    @test_throws ErrorException PAIN.mode_animation_frames(res, 20)
    @test_throws ErrorException PAIN.mode_animation_frames(res, 1; nframes=0)
    o = PAIN._cabin_outline(deg2rad(56.6); nθ=5)
    @test o.wall_x[1] ≈ sind(56.6) && o.wall_y[3] ≈ 1 && o.floor_y == fill(-cosd(56.6), 2)
    @test startswith(PAIN._fig_c3_text(PAIN.FIG_C3_PRINTED_ROWS[1]), "Fig. C-3 printed") && occursin("modes 0–5", PAIN._fig_c3_text(nothing))
    d = joinpath(UNIT_OUT, "unit_anim"); mkpath(d)
    ps = PAIN.render_mode_frame_pngs(d, PAIN.mode_animation_frames(res, 2; nframes=2, grid=11))
    @test length(ps) == 2 && all(p -> filesize(p) > 0, ps)
    g = PAIN.render_mode_animation(joinpath(d, "m2.gif"), PAIN.mode_animation_frames(res, 2; nframes=2, grid=11))
    @test all(p -> isfile(p) && filesize(p) > 0, g)
    rm(d; recursive=true)
end
@testset "structural mode display and frames (Phase 63)" begin
    fuse = PAIN.FuselageGeometry(1.83, 0.508, 56.6)
    st = PAIN.structural_modes_from_table_d1().modes[3]
    disp = PAIN.structural_mode_display(st, fuse; nz=5, nθ=7, nx=3)
    @test disp.shell_ψ[4, 3] ≈ PAIN.structural_shell_psi(st, disp.z[3], disp.theta_deg[4], fuse.L)
    @test disp.floor_ψ[2, 3] ≈ PAIN.structural_floor_psi(st, disp.z[3], 0.0, fuse.L, 2 * 0.508 * sind(56.6)) atol = 1e-12
    ac = PAIN.cyl2d_modes(56.6).modes[4]
    cd = PAIN.coupling_display(ac, st, fuse)
    @test cd.f_prime == PAIN.coupling_factor(ac, st, fuse) && cd.structural_index == st.index
    fr = PAIN.structural_mode_frames(st, fuse; nframes=12)
    @test fr.ring[1] != fr.ring[4]                                                    # frames move
    @test all(fr.ring[k][2] ≈ fr.ring[12 - k + 2][2] for k in 2:12)                   # cos(2πk/n) = cos(2π(n−k)/n)
    # quarter period: undeformed cross-section (cos = 0)
    x4, y4, _, yf4 = fr.ring[4]
    θs = range(deg2rad(56.6), 2π - deg2rad(56.6); length=181)
    @test x4 ≈ 0.508 .* sin.(θs) atol = 1e-12
    @test yf4 ≈ fill(-0.508 * cosd(56.6), length(yf4)) atol = 1e-12
    @test maximum(abs, hypot.(fr.ring[1][1], fr.ring[1][2]) .- 0.508) ≤ 0.12 * 0.508 + 1e-12   # amplitude cap
    @test fr.fields[7] ≈ -fr.fields[1]
    @test_throws ErrorException PAIN.structural_mode_frames(st, fuse; nframes=1)
    d = joinpath(UNIT_OUT, "unit_struct"); mkpath(d)
    ps = PAIN.render_structural_frame_pngs(d, PAIN.structural_mode_frames(st, fuse; nframes=2))
    @test length(ps) == 2 && all(p -> filesize(p) > 0, ps) && read(ps[1]) != read(ps[2])
    p1 = PAIN.render_structural_mode_png(joinpath(d, "disp.png"), disp)
    @test filesize(p1) > 0
    rm(d; recursive=true)
    @test isdir(PAIN.mode_animation_cache_dir())
end
