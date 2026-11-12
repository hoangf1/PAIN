# ISSUE-036 (2026-11-12): unit tests for the functions the completeness check found without one. Each asserts a hand
# value, a limit or an error path.
@testset "CYL2D printed grid size" begin
    @test PAIN.cyl2d_printed_NK(50.0) == 11 && PAIN.cyl2d_printed_NK(56.6) == 10      # floor(7 (1 + cos θ0)): 11.50, 10.85
    @test PAIN.cyl2d_printed_NK(73.7) == 8 && PAIN.cyl2d_printed_NK(90.0) == 7 && PAIN.cyl2d_printed_NK(0.0) == 14
    @test PAIN._cyl2d_default_NY(50.0, :printed) == 11 && PAIN._cyl2d_default_NY(50.0, :threshold) == 10
end
@testset "GUI default project file" begin
    p = PAIN.gui_default_project_path()
    @test isfile(p) && endswith(p, ".json") && isabspath(p)
end
@testset "E-12 mean of two digitization passes" begin
    A = Dict(1 => [(0.0, 0.0), (2.0, 2.0)], 2 => [(0.0, 5.0), (1.0, 5.0)])
    B = Dict(1 => [(0.0, 2.0), (1.0, 2.0), (2.0, 2.0), (3.0, 9.0)])
    M = PAIN._e12_mean_curve(A, B)
    @test collect(keys(M)) == [1]                                   # only harmonics both passes hold
    @test M[1] == [(0.0, 1.0), (1.0, 1.5), (2.0, 2.0)]              # mean at every vertex of either pass; x = 3 is outside A
    @test PAIN._e12_mean_curve(A, A)[2] == A[2]                     # the mean of a pass with itself is the pass
end
@testset "Report 996 unscaled-load second line" begin
    none = PAIN._r996_unscaled_line(_ -> false)
    @test none.n == 0 && none.n_ok == 0 && isempty(none.series)
    all_ = PAIN._r996_unscaled_line(_ -> true)
    @test all_.n > 0 && 0 ≤ all_.n_ok ≤ all_.n && !isempty(all_.series)
    @test all(s -> occursin("not scaled", s.name), all_.series)
end
@testset "NASA's printout on the gate: table cell" begin
    @test PAIN._nasa_gate_cell("MRP_APPD") == "not printed"
    g = PAIN.nasa_printout_on_gate("R172428_EXP")
    @test PAIN._nasa_gate_cell("R172428_EXP") == "$(g.n_ok)/$(g.n) (misses too: method limit)" && !g.met
end
@testset "chain span and reference parsing" begin
    @test PAIN._parse_chain_span("Skin field → Interior tones") == (4, 8)
    @test PAIN._parse_chain_span("skin field -> Skin field") == (4, 4)          # ASCII arrow, any case
    @test_throws ErrorException PAIN._parse_chain_span("Interior tones → Skin field")   # backwards
    @test_throws ErrorException PAIN._parse_chain_span("Skin field → Nowhere")
    @test_throws ErrorException PAIN._parse_chain_span("Skin field")
    @test PAIN._parse_reference("measurement") === :measurement && PAIN._parse_reference(" verification ") === :verification
    @test_throws ErrorException PAIN._parse_reference("a guess")
    @test PAIN.reference_label(:nasa) == "NASA's printed prediction" && PAIN.reference_label(:measurement) == "measurement"
end
@testset "coverage chart file" begin
    @test isdir(PAIN.coverage_figure_dir()) && basename(PAIN.coverage_figure_dir()) == "coverage"
    p = PAIN.plot_coverage_chart(joinpath(UNIT_OUT, "unit_cov.png"); verdict_only=true)
    q = PAIN.plot_coverage_chart(joinpath(UNIT_OUT, "unit_cov_all.png"); verdict_only=false)
    @test filesize(p) > 0 && filesize(q) > filesize(p)              # every case draws more rows than the verdict cases
end
@testset "shading above the trim model's range" begin
    mk(xmax) = PAIN.ValidationCaseResult("X", "2026-11-12", (;), PAIN.ValidationTableRow[],
        [PAIN.PlotSeries("s", :computed, [100.0, xmax], [1.0, 2.0]; panel=1)], :no_verdict, "", "", "")
    nr = PAIN.PlotSpec(; xlabel="band (Hz)", ylabel="NR (dB)")
    nplots(spec, xmax) = (fig = PAIN.CairoMakie.Figure(); ax = PAIN.CairoMakie.Axis(fig[1, 1]);
                          PAIN._shade_trim_range!(ax, spec, mk(xmax), 1); length(ax.scene.plots))
    base = nplots(nr, 800.0)
    @test nplots(nr, 5000.0) == base + 1                             # a band above 1 kHz is shaded
    @test nplots(nr, PAIN.TRIM_RANGE_TOP_HZ) == base                 # nothing above the limit: no shading
    @test nplots(PAIN.PlotSpec(; xlabel="band (Hz)", ylabel="SPL (dB)"), 5000.0) == base   # only noise-reduction panels
end
