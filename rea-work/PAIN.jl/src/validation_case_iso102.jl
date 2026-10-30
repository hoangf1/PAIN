# Phase 102 — CR-172428 flight-test run 10 (Merlin IVC), harmonics 2–4, from PAIN's printed deck and field
# (IMPLEMENTATION_PLAN.md §8ar; what is compared fixed 2026-10-30 before the run). Diagnostic: FLIGHT_MODES (Phase 101a)
# is not met, so this run carries no verdict. It sets the code as it ships and the trim per band against PAIN's
# printed levels.

const _P102_REPORT = "phase102_flight_run10_h234.md"

"""PAIN's printed run 10 levels, App. D p. 237 (dB re 20 μPa), H1–H5."""
const FLIGHT10_PAIN_dB = [99.90, 96.59, 88.06, 83.92, 71.02]

const FLIGHT10_BPF_Hz = 1568.0 * 4 / 60

"""
    r172428_flight10_field() -> (; amps, phases, pts)

Run 10's field on the 16 × 19 grid (App. D pp. 231–233; H2–H4 only, H1 and H5 are cut off in the scan and left at
zero). θ as printed, from the bottom centreline: −15° + 10°(L − 1), propeller line 75° at L = 10 (Phase 104: the deck's
ℓ = 1…10 are grid lines L = 10…19, CR-172428 App. A item 5, the "upper quarter" of User Manual card 37; Phase 102 used
180° − θ, which put the propeller 15° above the horizontal instead of 15° below).
"""
function r172428_flight10_field()
    amps = zeros(16, 19, 4); phases = zeros(16, 19, 4); zs = zeros(16)
    for H in 2:4
        c = _read_csv_numeric_nan(_r172428_csv("appD_run10_H$(H).csv"))
        for i in eachindex(c[:L])
            L, k = Int(c[:L][i]), Int(c[:k][i])
            zs[k] = c[:z_m][i]
            amps[k, L, H] = spl_dB_to_peak_Pa(c[:amp_dB][i])
            phases[k, L, H] = deg2rad(c[:phase_deg][i])
        end
    end
    pts = [(; k, ell=L, x1=NaN, x2=NaN, x3=1.12 - zs[k], theta_deg=-15.0 + 10.0 * (L - 1),
             alpha_deg=abs(-15.0 + 10.0 * (L - 1) - 75.0), z=zs[k]) for k in 1:16 for L in 1:19]
    return (; amps, phases, pts)
end

"""
    r172428_flight10_inputs(; trim_band_centre=false) -> PainInputs

Run 10 from PAIN's printed deck (App. D p. 229): ρ, c outside 1.1012, 334.08 and inside 1.204, 343.0; L = 9.27 m,
a = 0.84 m, L_c = 7.89 m, θ₀ = 50°; bare η_r = 2/f per band; acoustic loss factors from the trim; sidewall trim
0.055 m PF-105 (App. D table) + 1.95 kg/m², η_T = 2.0; no end-cap trim. Structural modes: the App. D solver on NASA's
Merlin deck (lowest 400; NASA kept 20 per axial order and symmetry, which differs only near the top of the list).
Acoustic modes: CYL2D at θ₀ = 50°, 20 two-dimensional modes, NY = 11 (assumption: NY = 10 of Fig. C-3 has complex
eigenvalues at 50°; the nearest grid that solves, chosen before any level was computed). Shell mass 4.54 kg/m² (the deck).
"""
function r172428_flight10_inputs(; trim_band_centre::Bool=false)
    fuse = FuselageGeometry(9.27, 0.84, 50.0)
    prop = PropellerPlacement(2.35, 75.0, 1.12)        # card 36: 75° from the bottom vertical (Phase 104)
    f = r172428_flight10_field()
    side = TrimStack(TrimElement[InsulationLayer(0.055, pf105_deck_table()), LimpMass(1.95, 2.0)], "Merlin IVC sidewall trim")
    ends = TrimStack(TrimElement[InsulationLayer(0.0, pf105_deck_table()), LimpMass(0.0, 1.0)], "no end-cap trim")
    structural = appd_modes(merlin_mrp_deck(); n_modes=400, n_axial=10, n_circ=14, n_floor_max=5)
    acoustic = cyl2d_modes(fuse.theta0_deg; n_modes=20, NY=11, c0=343.0)   # NY = 10 (Fig. C-3) gives complex eigenvalues at 50°
    η_r_band = Dict(fc => 2 / fc for fc in third_octave_centers())
    return PainInputs(fuse, prop, structural, acoustic, f.amps, f.phases, f.pts, (π * fuse.a / 18)^2;
                      sidewall=side, endplates=ends, mech=nothing, m_wall=4.54, L_c=7.89,
                      ρ_ext=1.1012, c_ext=334.08, ρ_int=1.204, c_int=343.0, η_r_band, trim_band_centre,
                      allow_extrapolation=true)   # mode 1 (39.6 Hz) is below the 50 Hz table start (X-EXTRAP)
end

"""H2–H4 levels of run 10: (a) as shipped, (b) with the trim per band."""
function _run_flight10_h234()
    spl(inp) = interior_spl(inp; bpf_Hz=FLIGHT10_BPF_Hz, n_harmonics=4, broadband=false).harmonic_SPL_dB[2:4]
    a = spl(r172428_flight10_inputs()); b = spl(r172428_flight10_inputs(; trim_band_centre=true))
    nasa = FLIGHT10_PAIN_dB[2:4]; fz = FLIGHT10_BPF_Hz .* (2:4)
    table = ValidationTableRow[]
    for i in 1:3
        push!(table, ValidationTableRow("H$(i + 1) as shipped (dB re 20 μPa)", fz[i], nasa[i], a[i], a[i] - nasa[i], abs(a[i] - nasa[i]) ≤ 3.0, "as shipped"))
        push!(table, ValidationTableRow("H$(i + 1) trim per band (dB re 20 μPa)", fz[i], nasa[i], b[i], b[i] - nasa[i], abs(b[i] - nasa[i]) ≤ 3.0, "trim per band"))
    end
    closer = count(i -> abs(b[i] - nasa[i]) < abs(a[i] - nasa[i]), 1:3)
    series = [PlotSeries("PAIN, App. D p. 237", :reference_points, collect(fz), nasa; panel=1),
              PlotSeries("this code as it ships", :computed_points, collect(fz), a; panel=1),
              PlotSeries("trim per band (option)", :computed_points, collect(fz), b; panel=1)]
    r2 = x -> round.(x; digits=2)
    return ValidationCaseResult("FLIGHT10_H234", _today_iso(),
        (; criterion="none (diagnostic; FLIGHT_MODES not met)", date="2026-10-30", as_shipped=r2(a), band=r2(b), nasa, closer),
        table, series, :no_verdict,
        "diagnostic (no verdict): H2–H4 as shipped $(r2(a)) dB, trim per band $(r2(b)) dB, PAIN $(nasa) dB; the trim per band " *
        "is closer at $closer/3 (H_bandtrim $(closer ≥ 2 ? "supported" : "not supported") in the diagnostic)",
        "V-CODE (diagnostic)", joinpath(_VAL_REPORT_DIR, _P102_REPORT))
end

function _iso102_validation_cases()
    return [ValidationCase("FLIGHT10_H234", "CR-172428 flight run 10, H2–H4: as shipped and trim per band vs PAIN (102)", "102",
        [_r172428_csv("appD_run10_H$(H).csv") for H in 2:4], FigureRef("NASA CR-172428", "App. D pp. 229–237", 237),
        "None (diagnostic; fixed 2026-10-30 before the run: per tone, which form is closer to PAIN's printed level).",
        "2026-10-30", "V-CODE", _run_flight10_h234,
        PlotSpec(; xlabel="tone frequency (Hz)", ylabel="interior SPL (dB)", panel_titles=["FLIGHT10_H234"],
                 error_mode=:absolute, error_tol=3.0), "")]
end
