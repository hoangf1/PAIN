# Unit tests: src/validation_plots.jl (Phase 64). Labels, error roll-up, snapshot CSV, rendering.
_res(id, rows; verdict=:met, series=PAIN.PlotSeries[]) =
    PAIN.ValidationCaseResult(id, "2026-10-24", (;), rows, series, verdict, "r", "lbl", "")

@testset "labels and limits" begin
    s = PAIN.PlotSpec(; xlabel="f (Hz)", ylabel="SPL (dB)", xlim=(1.0, 2.0), panel_xlabels=["", "k"], panel_ylabels=["A (Pa)"],
                      panel_xlims=Union{Nothing,NTuple{2,Float64}}[nothing, (3.0, 4.0)], error_mode=:relative_pct)
    @test PAIN._panel_xlabel(s, 1) == "f (Hz)" && PAIN._panel_xlabel(s, 2) == "k" && PAIN._panel_xlabel(s, 5) == "f (Hz)"
    @test PAIN._panel_ylabel(s, 1) == "A (Pa)" && PAIN._panel_ylabel(s, 2) == "SPL (dB)"
    @test PAIN._panel_xlim(s, 1) == (1.0, 2.0) && PAIN._panel_xlim(s, 2) == (3.0, 4.0) && PAIN._panel_ylim(s, 1) === nothing
    @test PAIN._error_ylabel(s) == "error (%)" && PAIN._error_ylabel(PAIN.PlotSpec(; error_mode=:db_ratio)) == "error (dB)"
    @test PAIN._error_ylabel(PAIN.PlotSpec(; error_ylabel="Δ (Hz)")) == "Δ (Hz)" && PAIN._error_ylabel(PAIN.PlotSpec()) == "computed − reference"
    @test PAIN._error_xlabel(s) == "f (Hz)" && PAIN._error_xlabel(PAIN.PlotSpec(; error_xlabel="H")) == "H"
    @test PAIN._mach_from_series_name("XFOIL M = 0.55 Re 1e6") == 0.55 && PAIN._mach_from_series_name("none") === nothing
    @test PAIN._alpha_from_series_name("TN1546 α=-2.5") == -2.5 && PAIN._alpha_from_series_name("alpha = 3.77") == 3.77
    cols = Dict{Float64,Symbol}(); ord = Float64[]
    c1 = PAIN._color_for_alpha!(cols, ord, 2.0); c2 = PAIN._color_for_alpha!(cols, ord, 4.0)
    @test c1 != c2 && PAIN._color_for_alpha!(cols, ord, 2.0) == c1 && ord == [2.0, 4.0]
    @test PAIN._unit_in_parens("SPL (dB) re (20 µPa)") == "20 µPa" && PAIN._unit_in_parens("x ()") === nothing && PAIN._unit_in_parens("") === nothing
    @test PAIN._absolute_error_unit(PAIN.PlotSpec(; ylabel="f (Hz)")) == "Hz" && PAIN._absolute_error_unit(PAIN.PlotSpec()) == "abs"
    @test PAIN._legend_kw("") == (;) && PAIN._legend_kw("a") == (; label="a")
    @test PAIN._percentile([1.0, 2.0, 3.0, 4.0], 0.5) ≈ 2.5 && PAIN._percentile([7.0], 0.9) == 7 && isnan(PAIN._percentile(Float64[], 0.5))
    lims, clipped = PAIN._error_ylims([0.1, -0.2, 50.0], 1.0)
    @test lims[2] ≥ 2.0 && lims[1] == -lims[2]
    @test PAIN._error_ylims([NaN], nothing) == (nothing, false)
    @test PAIN._fmt_err_sig(0.012345) == "0.012"
end
@testset "error roll-up (case_error_summary)" begin
    rows = [PAIN.ValidationTableRow("a", 1, 100, 101, 1, true), PAIN.ValidationTableRow("b", 2, 100, 97, -3, false)]
    @test PAIN._row_error(rows[2], :absolute) == -3 && PAIN._row_error(rows[2], :relative_pct) ≈ -3
    @test PAIN._row_error(rows[1], :db_ratio) ≈ 20log10(1.01) && isnan(PAIN._row_error(rows[1], :none))
    s = PAIN.case_error_summary(_res("X", rows; verdict=:not_met), PAIN.PlotSpec(; ylabel="f (Hz)"))
    @test s.n_within == 1 && s.n_rows == 2 && s.max_abs == 3 && s.median_abs == 2 && s.unit == "Hz"
    @test s.text == "1/2 in tol · max |err| 3.0 Hz · med 2.0 Hz" && s.chip_text == "1/2 · 3.0 Hz max"
    @test PAIN.case_error_summary(_res("X", rows; verdict=:no_verdict), PAIN.PlotSpec()).chip_text == "no verdict · 3.0 abs max"
    @test PAIN.case_error_summary(_res("X", PAIN.ValidationTableRow[]), PAIN.PlotSpec()).text == "no criterion"
    n = PAIN.case_error_summary(_res("X", rows), PAIN.PlotSpec(; error_mode=:none))
    @test n.text == "1/2 within criterion" && isnan(n.max_abs)
    @test PAIN._error_chip_text(; text="no criterion", n_within=0, n_rows=0, max_abs=NaN, unit="") == "no criterion"
    @test PAIN._error_chip_text(; text="x", n_within=2, n_rows=3, max_abs=NaN, unit="") == "2/3"
end
@testset "snapshot CSV round trip and lookups" begin
    p = joinpath(UNIT_OUT, "unit_case_errors.csv")
    write(p, "# c\nid,run_date,source_date,verdict,n_within,n_rows,max_abs,median_abs,unit,text\n" *
             "A,2026-10-24,2026-10-23,met,2,2,0.5,0.1,\"dB\",\"2/2 in tol, fine\"\nBAD,1,2\n")
    d = @test_logs (:warn, r"skipped malformed") PAIN._load_recorded_case_errors(p)
    @test collect(keys(d)) == ["A"] && d["A"].text == "2/2 in tol, fine" && d["A"].source_date == "2026-10-23"
    r1 = PAIN.recorded_case_errors(p)
    @test PAIN.recorded_case_errors(p) === r1                                       # cached by path + mtime
    hdr = ["id", "run_date", "verdict", "n_within", "n_rows", "max_abs", "median_abs", "unit", "text"]
    id, row = PAIN._parse_recorded_error_row(["B", "2026-10-24", "met", "1", "1", "", "", "%", "t"], Dict(h => i for (i, h) in enumerate(hdr)))
    @test id == "B" && isnan(row.max_abs) && row.source_date == "2026-10-24"
    @test isempty(PAIN._load_recorded_case_errors(joinpath(UNIT_OUT, "absent.csv")))
    rm(p)
    f = PAIN._case_error_json_fields("A"; session=Dict("A" => (; text="t", chip_text="c")))
    @test f.error_source == "run" && f.error_chip == "c"
    g = PAIN._case_error_json_fields("A"; recorded=d)
    @test g.error_source == "recorded 2026-10-23" && g.error_snapshot == "snapshot 2026-10-24"
    @test PAIN._case_error_json_fields("Z").error == ""
    @test endswith(replace(PAIN.case_error_summary_path(), '\\' => '/'), "docs/validation_reports/case_error_summary.csv")
    @test endswith(replace(PAIN.validation_figure_path("T1"), '\\' => '/'), "figures/vs_measurement/T1.png")
    @test endswith(replace(PAIN.validation_figure_path("R996_FIG14"), '\\' => '/'), "figures/F1A_amplitude/R996_FIG14.png")
    @test endswith(replace(PAIN.validation_figure_path("NO_SUCH_CASE"), '\\' => '/'), "figures/NO_SUCH_CASE.png")
    froot = PAIN._validation_figures_root()
    @test isabspath(froot) && isdir(froot) && endswith(replace(froot, '\\' => '/'), "docs/validation_reports/figures")
    @test PAIN.validation_figure_dir("NO_SUCH_CASE") == froot                     # unregistered id: the root
    @test PAIN.validation_figure_dir("T1") == joinpath(froot, "vs_measurement")    # registered id: its block's folder
    @test isdir(PAIN.validation_figure_dir("R996_FIG14"))
    # every map block has a figure folder, and no two blocks share one
    block_ids = [b.id for m in PAIN.VALIDATION_MAPS for b in m.blocks]
    @test all(b -> haskey(PAIN.VALIDATION_FIGURE_DIRS, b), block_ids)
    @test length(unique(values(PAIN.VALIDATION_FIGURE_DIRS))) == length(PAIN.VALIDATION_FIGURE_DIRS)
    @test isfile(PAIN.validation_source_figure_path("R996_FIG14"))                  # QA overlay fallback
    # writer on a one-case registry order (the real order is restored afterwards)
    saved = copy(PAIN.VALIDATION_CASE_ORDER)
    try
        empty!(PAIN.VALIDATION_CASE_ORDER); push!(PAIN.VALIDATION_CASE_ORDER, "MRP_D1")
        q = PAIN.write_case_error_summary(joinpath(UNIT_OUT, "unit_summary.csv"); run_date="2026-10-24")
        L = readlines(q); rm(q)
        @test startswith(L[1], "# generated 2026-10-24") && startswith(L[3], "MRP_D1,2026-10-24,")
    finally
        empty!(PAIN.VALIDATION_CASE_ORDER); append!(PAIN.VALIDATION_CASE_ORDER, saved)
    end
end
@testset "plot_case and log ticks" begin
    fig = PAIN.Figure(); ax = PAIN.Axis(fig[1, 1])
    PAIN._apply_log_ticks!(ax, [150.0, 900.0, 4000.0])
    @test ax.xticks[] == ([200.0, 500.0, 1000.0, 2000.0], ["200", "500", "1000", "2000"])   # round ticks inside the span ×/÷ 1.2
    PAIN._apply_log_ticks!(ax, [3.0, 3.5]; dim=:y)
    @test ax.yticks[][2] == ["3.0", "3.5"]                                        # not all integers: decimal labels
    rows = [PAIN.ValidationTableRow("a", 1, 100, 101, 1, true)]
    ser = [PAIN.PlotSeries("ref", :reference_points, [1.0, 2.0], [100.0, 99.0]), PAIN.PlotSeries("comp", :computed, [1.0, 2.0], [101.0, 98.0])]
    png = PAIN.plot_case(_res("UNIT", rows; series=ser), PAIN.PlotSpec(; xlabel="x", ylabel="y"); path=joinpath(UNIT_OUT, "unit_case.png"))
    @test filesize(png) > 0 && isfile(replace(png, ".png" => ".pdf"))
    e = PAIN.plot_case(_res("UNIT0", PAIN.ValidationTableRow[]), PAIN.PlotSpec(); path=joinpath(UNIT_OUT, "unit_empty.png"))
    @test filesize(e) > 0                                                           # placeholder image
end
