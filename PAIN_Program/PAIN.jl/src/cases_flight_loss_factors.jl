# ISSUE-041 (2026-11-12): held-out test of the ISSUE-032 fix (a card structural loss factor is η_r^struc; Eq. (81)'s
# radiation loss is added). Flight run 10's inputs as printed (App. D deck: η_r = 2/f per band, PF-105 0.055 m trim with
# 1.95 kg/m² and η = 2.0), the Merlin IVC modes of NASA's MRP deck (App. C pp. 204–205), against the LOSS FACTOR column of
# PAIN's printed mode list (App. C pp. 213–216). Criterion fixed and committed (d0f6a07) before the column was read.

"""η_r′ of each listed Merlin mode against PAIN's printed loss factor (ISSUE-041)."""
function _run_flight_eta()
    rows = [split(l, ",") for l in eachline(_r172428_csv("appC_merlin_loss_factors.csv")) if !startswith(l, "#")][2:end]
    inp = r172428_flight10_inputs()
    ms = inp.structural.modes
    table = ValidationTableRow[]; n_ok = 0
    xs = Float64[]; ref = Float64[]; got = Float64[]
    M = _appc_mode_rows("appC_merlin_structural_modes_checked.csv")   # axial order M of each printed mode
    for r in rows
        mode = parse(Int, r[1]); f = parse(Float64, r[2]); sym = r[3] == "S"; η = parse(Float64, r[4])
        i = findfirst(==(mode), M.mode)
        cand = [x for x in ms if x.symmetric == sym && x.M_axial == M.M[i]]
        x = cand[argmin([abs(y.f_Hz - f) for y in cand])]               # FLIGHT_MODES' pairing rule
        ours = structural_η_r_prime(inp, x, 2π * x.f_Hz)
        rel = ours / η - 1; ok = abs(rel) ≤ 0.25
        n_ok += ok
        push!(table, ValidationTableRow("mode $mode ($(r[3]), M = $(M.M[i])) at $f Hz: η_r′ (residual = relative difference)",
                                        f, η, ours, rel, ok, sym ? "symmetric modes" : "antisymmetric modes"))
        push!(xs, f); push!(ref, η); push!(got, ours)
    end
    n = length(table)
    series = [PlotSeries("PAIN, App. C (printed loss factor)", :reference_points, xs, ref; panel=1),
              PlotSeries("this code, run 10's deck", :computed_points, xs, got; panel=1)]
    return ValidationCaseResult("FLIGHT_ETA", _today_iso(),
        (; criterion="η_r′ within ±25 % of PAIN's printed loss factor for ≥ 75 % of the listed modes", date="2026-11-12", n_ok, n),
        table, series, n_ok ≥ 0.75n ? :met : :not_met,
        "$n_ok/$n listed modes within ±25 % of PAIN's printed loss factor (criterion ≥ 75 %)", "V-CODE",
        joinpath(_VAL_REPORT_DIR, "issue041_merlin_loss_factors.md"))
end

function _merlin_loss_validation_cases()
    return [ValidationCase("FLIGHT_ETA", "Structural-mode loss factors of the flight aircraft against PAIN's printout (CR-172428, App. C)",
        "ISSUE-041", [_r172428_csv("appC_merlin_loss_factors.csv"), _r172428_csv("appC_merlin_structural_modes_checked.csv")],
        FigureRef("NASA CR-172428", "App. C pp. 213–216", 223),
        "η_r′ within ±25 % of PAIN's printed loss factor for ≥ 75 % of the listed modes (fixed 2026-11-12, commit d0f6a07, before the column was read).",
        "2026-11-12", "V-CODE", _run_flight_eta,
        PlotSpec(; xlabel="mode frequency (Hz)", ylabel="η_r′ (loss factor)", xscale=:log10, yscale=:log10, panel_titles=["FLIGHT_ETA"],
                 error_mode=:relative_pct, error_tol=25.0), "")]
end
