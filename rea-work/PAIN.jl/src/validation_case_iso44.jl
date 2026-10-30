# Phase 44 — reproduce NASA's fundamental validation of the 1.016 m test article (CR-172428 §3, App. A, App. B).
# Criteria dated 2026-10-23 before any transcription or run (IMPLEMENTATION_PLAN.md §8b Phase 44).
# Inputs are NASA's own: the App. B blocked field (16 × 19 grid, as PAIN used it), Table 6 and the App. B trim page.

_r172428_csv(name) = _data_path("cr172428", name)

"""
    r172428_appb_field(rpm; n_harmonics=3) -> (; amps, phases, pts, n_missing)

App. B blocked pressure field on the 16 × 19 grid PAIN used (k = 1..16 axial, L = 1..19 with
θ = 10(L − 1)° from the bottom centreline; L = 10..19 are the grid lines ℓ = 1..10, L = 1..9
the mirrored lower quarter, CR-172428 p. 82). `z` is the printed axial location from the
forward end. Amplitudes [Pa peak] from the printed dB; a cell with no printed phase (page
edge) is left at zero amplitude and counted in `n_missing`.
"""
function r172428_appb_field(rpm::Integer; n_harmonics::Int=3, z_p::Real=0.662)
    amps = zeros(16, 19, n_harmonics)
    phases = zeros(16, 19, n_harmonics)
    zs = zeros(16)
    n_missing = 0
    for H in 1:n_harmonics
        c = _read_csv_numeric_nan(_r172428_csv("appB_$(rpm)rpm_H$(H).csv"))
        for i in eachindex(c[:L])
            L, k = Int(c[:L][i]), Int(c[:k][i])
            zs[k] = c[:z_m][i]
            if isnan(c[:phase_deg][i])
                n_missing += 1
                continue
            end
            amps[k, L, H] = spl_dB_to_peak_Pa(c[:amp_dB][i])
            phases[k, L, H] = deg2rad(c[:phase_deg][i])
        end
    end
    pts = [(; k, ell=L, x1=NaN, x2=NaN, x3=z_p - zs[k], theta_deg=10.0 * (L - 1),
             alpha_deg=abs(10.0 * (L - 1) - 90.0), z=zs[k]) for k in 1:16 for L in 1:19]
    return (; amps, phases, pts, n_missing)
end

"""
    r172428_inputs(rpm; app_a=true, structural=:table_d1, η_T=0.13, insulation=:deck) -> PainInputs

CR-172428 Table 6 and App. B inputs: L = 1.803 m, a = 0.508 m, θ₀ = 56.6°, L_c = 1.829 m,
shell mass 3.113 kg/m², propeller r_p = 0.9652 m, z_p = 0.662 m, rotation +1; bare structural
loss factor 2/f per 1/3-octave band (as the App. B list shows: e.g. mode 5, 2/315 = 0.00635);
trim of App. B p. 197 (sidewall: PF105 0.0508 m + 1.456 kg/m² panel, η = 0.13; end caps:
PF105 0.0127 m, no panel, η = 1.0; no mechanical path). c₀ = 343 m/s from the printed axial
mode (93.78 Hz = c₀/2L_c). Structural modes: Table D-1 (the first 32 of NASA's 300, same
numbers and frequencies as App. B); acoustic modes: CYL2D, 20 two-dimensional modes.
`app_a=true` applies the App. A η_r′ correction (`η_r_trimmed_area`). `structural=:deck` (Phase 82c) takes the 32
structural modes from the App. D solver on NASA's MRP deck (`appd_nasa_deck()`, full series) instead of Table D-1's
printed (truncated) shapes; everything else is unchanged (82c: R172428_ETA stays 17/32, levels move < 1 dB).
`structural=:nasa300` (Phase 84b) takes NASA's 300 modes from the same solve (`nasa_deck_modes()`; CR-172428 Table 6).
`insulation=:deck` (default since Phase 100) takes NASA's per-band PF-105 table from the App. D input deck
(`pf105_deck_table()`, 50–5000 Hz, as printed); `:fig_a2` interpolates the six markers of CR-3813 Fig. A-2 (before 2026-10-30).
"""
function r172428_inputs(rpm::Integer; app_a::Bool=true, structural::Symbol=:table_d1, η_T::Real=0.13,
                        insulation::Symbol=:deck)
    fuse = FuselageGeometry(1.803, 0.508, 56.6)
    prop = PropellerPlacement(0.9652, 90.0, 0.662)
    f = r172428_appb_field(rpm; z_p=prop.z_p)
    c0 = 343.0
    mat = insulation === :deck ? pf105_deck_table() : insulation === :fig_a2 ? pf105_table() :
          error("r172428_inputs: insulation must be :deck or :fig_a2 (got $insulation)")
    side = TrimStack(TrimElement[InsulationLayer(0.0508, mat), LimpMass(1.456, η_T)],
                     "CR-172428 sidewall trim")
    ends = TrimStack(TrimElement[InsulationLayer(0.0127, mat), LimpMass(0.0, 1.0)],
                     "CR-172428 end cap")
    acoustic = cyl2d_modes(fuse.theta0_deg; n_modes=20, NY=10, c0=c0)
    structural_modes = structural === :deck ? appd_modes(appd_nasa_deck(); n_modes=32) :
                       structural === :nasa300 ? nasa_deck_modes() :
                       structural === :table_d1 ? structural_modes_from_table_d1(; n_keep=32) :
                       error("r172428_inputs: structural must be :table_d1, :deck or :nasa300 (got $structural)")
    η_r_band = Dict(fc => 2 / fc for fc in third_octave_centers())
    return PainInputs(fuse, prop, structural_modes, acoustic, f.amps, f.phases, f.pts, (π * fuse.a / 18)^2;
                      sidewall=side, endplates=ends, mech=nothing, m_wall=3.113,
                      L_c=1.829, c0=c0, η_r_band, η_r_trimmed_area=app_a)
end

"""rpm values whose App. B field has been transcribed (files present)."""
_r172428_rpms() = [rpm for rpm in (3000, 4000, 5000) if isfile(_r172428_csv("appB_$(rpm)rpm_H1.csv"))]

function _r172428_levels(; structural::Symbol=:table_d1, η_n_per_mode::Bool=false, q0_coupled::Bool=true,
                         η_n_band_omega::Bool=true)
    # defaults: the tone sum as CR-3813 prints it (R172428_CODE; Phase 93 keeps it, the default form was inferred from
    # these points)
    pred = _read_csv_numeric_nan(_r172428_csv("appB_predictions.csv"))
    out = NamedTuple[]
    for rpm in _r172428_rpms()
        inp = r172428_inputs(rpm; structural)
        inp = _with_fields(inp; η_n_per_mode, q0_coupled, η_n_band_omega)   # Phases 89, 92, 93, 96
        bpf = 3 * rpm / 60
        spl = interior_spl(inp; bpf_Hz=bpf, n_harmonics=3).harmonic_SPL_dB
        for H in 1:3
            i = findfirst(j -> pred[:rpm][j] == rpm && pred[:H][j] == H, eachindex(pred[:rpm]))
            push!(out, (; rpm, H, f_Hz=H * bpf, ours=Float64(spl[H]),
                        nasa=pred[:nasa_pred_dB][i], measured=pred[:measured_dB][i]))
        end
    end
    return out
end

# Phase 93: R172428_CODE (and its _DECK, _ETAN re-runs) keep the tone sum as CR-3813 prints it; R172428_EXP runs the
# default form (q = 0 off, η_n per mode), taken from NASA's printouts, not from the measurements.
function _run_r172428_vs(which::Symbol; structural::Symbol=:table_d1, η_n_per_mode::Bool=which !== :code)
    # R172428_CODE_ETAN keeps the Phase 89 reading of η_n per mode (η_n_band_omega = false), as recorded
    lv = _r172428_levels(; structural, η_n_per_mode, q0_coupled=which === :code, η_n_band_omega=which !== :code)
    deck = structural === :nasa300   # Phase 84b: NASA's 300 modes, criteria fixed 2026-10-29
    tol = which === :code ? 3.0 : 4.0
    table = ValidationTableRow[]
    n_ok = 0
    for r in lv
        ref = which === :code ? r.nasa : r.measured
        d = r.ours - ref
        ok = abs(d) ≤ tol
        n_ok += ok
        push!(table, ValidationTableRow("$(r.rpm) rpm H$(r.H)", r.f_Hz, ref, r.ours, d, ok))
    end
    n = length(lv)
    complete = n == 9
    verdict = !complete ? :no_verdict :
              which === :code ? (n_ok ≥ 7 ? :met : :not_met) : (n_ok == 9 ? :met : :not_met)
    xs = [r.f_Hz for r in lv]
    series = [
        PlotSeries("NASA PAIN (CR-172428 App. B / Table 10)", :reference_points, xs, [r.nasa for r in lv]; panel=1),
        PlotSeries("measured (Table 5)", :measured_points, xs, [r.measured for r in lv]; panel=1),
        PlotSeries(deck ? "this code, NASA inputs, NASA's 300 modes" :
                   which !== :code ? "this code (default form), NASA inputs" :
                   η_n_per_mode ? "this code, NASA inputs, η_n per mode (H1)" : "this code, NASA inputs, CR-3813 tone sum",
                   :computed_points, xs, [r.ours for r in lv]; panel=1),
    ]
    crit = which === :code ? "±3 dB of NASA's printed prediction at ≥ 7 of 9 points (3000/4000/5000 rpm, H1–H3)" :
                             "±4 dB of the measured space average at each of the 9 points"
    reason = "$n_ok/$n within ±$(tol) dB" * (complete ? "" : "; criterion needs 9 points, $n transcribed " *
             "(rpm $(join(_r172428_rpms(), ", ")))") *
             "; H1–H3 = " * join(["$(r.rpm):H$(r.H) $(round(r.ours; digits=2))" for r in lv], ", ")
    id = (which === :code ? "R172428_CODE" : "R172428_EXP") * (deck ? "_DECK" : "") * (which === :code && η_n_per_mode ? "_ETAN" : "")
    return ValidationCaseResult(id, _today_iso(),
        (; criterion=crit, date=deck || (which === :code && η_n_per_mode) ? "2026-10-29" : "2026-10-23", rpms=_r172428_rpms(), structural, η_n_per_mode,
           ours=[r.ours for r in lv], nasa=[r.nasa for r in lv], measured=[r.measured for r in lv]),
        table, series, verdict, reason, which === :code ? "V-CODE" : "V-EXP", "")
end

_run_r172428_code() = _run_r172428_vs(:code)
_run_r172428_exp() = _run_r172428_vs(:exp)

"""44d sub-criterion: η_r′ of the 32 listed structural modes within ±25 % of App. B p. 194."""
function _run_r172428_eta()
    c = _read_csv_numeric_nan(_r172428_csv("appB_structural_modes.csv"))
    inp = r172428_inputs(4000)
    table = ValidationTableRow[]
    n_ok = 0
    xs = Float64[]; ours = Float64[]; nasa = Float64[]
    for st in inp.structural.modes
        i = findfirst(==(st.index), Int.(c[:mode]))
        i === nothing && continue
        η = structural_η_r_prime(inp, st, 2π * st.f_Hz)
        ref = c[:loss_factor][i]
        rel = η / ref - 1
        ok = abs(rel) ≤ 0.25
        n_ok += ok
        push!(table, ValidationTableRow("mode $(st.index) ($(st.f_Hz) Hz) η_r′ rel. diff", st.f_Hz, ref, η, rel, ok))
        push!(xs, st.f_Hz); push!(ours, η); push!(nasa, ref)
    end
    n = length(table)
    series = [PlotSeries("NASA App. B", :reference_points, xs, nasa; panel=1),
              PlotSeries("this code (App. A, Table 6)", :computed_points, xs, ours; panel=1)]
    return ValidationCaseResult("R172428_ETA", _today_iso(),
        (; criterion="η_r′ of each listed structural mode within ±25 % of App. B", date="2026-10-23", n_ok, n),
        table, series, n_ok == n ? :met : :not_met,
        "$n_ok/$n modes within ±25 % of App. B (residual column = relative difference)", "V-CODE", "")
end

"""Diagnostic (no criterion): trim factor and admittances against App. B p. 197."""
function _run_r172428_trim()
    c = _read_csv_numeric_nan(_r172428_csv("appB_trim.csv"))
    inp = r172428_inputs(4000)
    table = ValidationTableRow[]
    fs = Float64[]; tf_o = Float64[]; tf_n = Float64[]
    for i in eachindex(c[:f_Hz])
        f = c[:f_Hz][i]
        f < first(inp.sidewall.elements[1].material.f_Hz) && continue   # deck table from 50 Hz; Fig. A-2 from 100 Hz
        ω = 2π * f
        tf = -10 * log10(trim_tau(inp.sidewall, ω))
        β = trim_admittance(inp.sidewall, ω, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int)
        βe = trim_admittance(inp.endplates, ω, Inf; ρ0=inp.ρ_int, c0=inp.c_int)
        push!(table, ValidationTableRow("trim factor dB at $(Int(f)) Hz", f, c[:trim_factor_dB][i], tf,
                                        tf - c[:trim_factor_dB][i], true))
        push!(table, ValidationTableRow("sidewall admittance Re at $(Int(f)) Hz", f, c[:side_adm_re][i], real(β),
                                        real(β) - c[:side_adm_re][i], true))
        push!(table, ValidationTableRow("sidewall admittance Im at $(Int(f)) Hz", f, c[:side_adm_im][i], imag(β),
                                        imag(β) - c[:side_adm_im][i], true))
        push!(table, ValidationTableRow("end-cap admittance Im at $(Int(f)) Hz", f, c[:end_adm_im][i], imag(βe),
                                        imag(βe) - c[:end_adm_im][i], true))
        push!(fs, f); push!(tf_o, tf); push!(tf_n, c[:trim_factor_dB][i])
    end
    series = [PlotSeries("NASA App. B trim factor", :reference_points, fs, tf_n; panel=1),
              PlotSeries("this code", :computed, fs, tf_o; panel=1)]
    dmax = maximum(abs(r.residual) for r in table if startswith(r.quantity, "trim factor") && r.x ≥ 250)
    d200 = only(r.residual for r in table if startswith(r.quantity, "trim factor") && r.x == 200)
    return ValidationCaseResult("R172428_TRIM", _today_iso(),
        (; criterion="none (diagnostic; no criterion was fixed before the comparison)", date="2026-10-23"),
        table, series, :no_verdict,
        "no criterion; trim factor max |Δ| = $(round(dmax; digits=2)) dB for 250–5000 Hz " *
        "(200 Hz, at the trim resonance: $(round(d200; digits=2)) dB)", "diagnostic", "")
end

"""Diagnostic (no criterion): NASA's printed top-5 modal contributions at 4000 rpm against ours."""
function _run_r172428_pairs()
    c = _read_csv_numeric_nan(_r172428_csv("appB_contributors_4000rpm.csv"))
    inp = r172428_inputs(4000)
    table = ValidationTableRow[]
    parts = Dict(H => modal_tone_contributions(inp, H, 2π * 200.0 * H)[1] for H in 1:3)
    for i in eachindex(c[:H])
        H, q, I, r = Int(c[:H][i]), Int(c[:Q][i]), Int(c[:I][i]), Int(c[:st_mode][i])
        j = findfirst(p -> (p.q, p.i, p.r) == (q, I, r), parts[H])
        ours = j === nothing ? 0.0 : parts[H][j].p2
        ref = c[:p2_Pa2][i]
        d = ours > 0 ? 10 * log10(ours / ref) : -Inf
        push!(table, ValidationTableRow("H$H (q=$q, I=$I) × mode $r: ours/NASA [dB]", Float64(H), ref, ours, d, true))
    end
    for H in 1:3
        p = parts[H][1]
        push!(table, ValidationTableRow("H$H our largest pair (q=$(p.q), I=$(p.i)) × mode $(p.r) [Pa²]",
                                        Float64(H), NaN, p.p2, NaN, true))
    end
    pr = [r for r in table if isfinite(r.residual)]
    series = [PlotSeries("ours / NASA per printed pair (dB)", :computed_points,
                         collect(1.0:length(pr)), [r.residual for r in pr]; panel=1)]
    return ValidationCaseResult("R172428_PAIRS", _today_iso(),
        (; criterion="none (diagnostic)", date="2026-10-23"), table, series, :no_verdict,
        "no criterion; per-pair ratio ours/NASA in dB (residual column); this code in its default form (Phase 93: q = 0 " *
        "uncoupled, η_n per mode; before 2026-10-29 the CR-3813 tone sum)", "diagnostic", "")
end

function _iso44_validation_cases()
    files = [_r172428_csv("appB_4000rpm_H1.csv"), _r172428_csv("appB_predictions.csv")]
    return [
        ValidationCase("R172428_CODE", "CR-172428 reproduction: NASA's inputs vs NASA's printed predictions (44d)", "44",
            files, FigureRef("NASA CR-172428", "App. B pp. 196–212 / Table 10", 206),
            "Within ±3 dB of NASA's printed prediction at ≥ 7 of 9 points (3000/4000/5000 rpm, H1–H3).",
            "2026-10-23", "V-CODE", _run_r172428_code,
            PlotSpec(; xlabel="tone frequency (Hz)", ylabel="interior SPL (dB)",
                     panel_titles=["R172428_CODE"], error_mode=:absolute, error_tol=3.0), ""),
        ValidationCase("R172428_EXP", "CR-172428 reproduction vs measured space averages (44e)", "44",
            files, FigureRef("NASA CR-172428", "Table 5 / Table 10", 89),
            "Within ±4 dB of the measured space average at each of the 9 points.",
            "2026-10-23", "V-EXP", _run_r172428_exp,
            PlotSpec(; xlabel="tone frequency (Hz)", ylabel="interior SPL (dB)",
                     panel_titles=["R172428_EXP"], error_mode=:absolute, error_tol=4.0), ""),
        ValidationCase("R172428_ETA", "CR-172428 structural loss factors η_r′ vs App. B (44c/44d)", "44",
            [_r172428_csv("appB_structural_modes.csv")], FigureRef("NASA CR-172428", "App. B p. 194", 194),
            "η_r′ of each listed structural mode within ±25 % of App. B.",
            "2026-10-23", "V-CODE", _run_r172428_eta,
            PlotSpec(; xlabel="mode frequency (Hz)", ylabel="η_r′", yscale=:log10,
                     panel_titles=["R172428_ETA"], error_mode=:none), ""),
        ValidationCase("R172428_TRIM", "CR-172428 trim factor / admittance vs App. B (diagnostic)", "44",
            [_r172428_csv("appB_trim.csv")], FigureRef("NASA CR-172428", "App. B p. 197", 197),
            "No criterion (diagnostic; compared after the fact).",
            "2026-10-23", "diagnostic", _run_r172428_trim,
            PlotSpec(; xlabel="frequency (Hz)", ylabel="trim factor (dB)", xscale=:log10,
                     panel_titles=["R172428_TRIM"], error_mode=:none), ""),
        ValidationCase("R172428_PAIRS", "CR-172428 top modal contributions vs App. B (diagnostic)", "44",
            [_r172428_csv("appB_contributors_4000rpm.csv")], FigureRef("NASA CR-172428", "App. B p. 207", 207),
            "No criterion (diagnostic).",
            "2026-10-23", "diagnostic", _run_r172428_pairs,
            PlotSpec(; xlabel="harmonic", ylabel="p² (Pa²)", panel_titles=["R172428_PAIRS"], error_mode=:none), ""),
    ]
end
