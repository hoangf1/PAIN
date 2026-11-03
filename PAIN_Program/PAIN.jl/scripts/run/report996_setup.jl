#!/usr/bin/env julia
# Phase 25k: Report 996 setup report (asymmetry + rms harmonic convergence).
using PAIN
using Dates

const ROOT = joinpath(@__DIR__, "..", "..", "..")
const DATA = joinpath(ROOT, "data", "report996")
const BF = joinpath(DATA, "naca_4-5-08-03", "blade_form.csv")
const POLAR = joinpath(DATA, "polars_phase69_ncrit8.json")  # Phase 69: free transition, N_crit 8
const OUT = joinpath(ROOT, "docs", "validation_reports", "report996_setup.md")
const PROBE = joinpath(ROOT, "docs", "validation_reports", "report996_setup_probe.md")

function rpm_from_Mt(Mt; D=1.2192, a=340.3)
    return Mt * a * 60 / (π * D)
end

function main()
    af, st = load_polar_set(POLAR; set=:primary, cr75=0.1251)
    g = blade_form_geometry(BF; D=1.2192, beta75_target_deg=15.0)
    Mt = 0.75
    cfg = (
        propeller = (
            num_blades = 2,
            tip_radius_m = g.R,
            hub_radius_m = g.radii_m[1],
            rpm = rpm_from_Mt(Mt),
            thickness_over_chord = 0.0,
            pitch_offset_deg = 0.0,
            radii_m = collect(g.radii_m),
            chord_m = collect(g.chord_m),
            twist_deg = collect(g.twist_deg),
            station_t_over_c = collect(g.t_over_c),
        ),
        operating_point = (forward_speed_mps = 0.0, rho_kg_m3 = 1.225, c0_mps = 340.3),
        anopp_table8_calibrate = false,
    )
    R = cfg.propeller.tip_radius_m
    D = 2R
    # Fig. 13(a) asymmetry: behind vs ahead at |x/D|=0.125
    obs = hub_observers(R, D; x_over_D=[-0.125, 0.125], d_over_D=0.083, x_sign=R996_X_SIGN)
    src = evaluate_propeller_source(cfg, obs; n_harmonics=12, num_src_times=64,
                                    af=af, allow_static=true)
    A_behind = src.amplitude[1, 1]
    A_ahead = src.amplitude[2, 1]
    asym_ok = A_behind > A_ahead

    # RMS convergence at behind point: how many harmonics until Δ < 0.1 dB
    As = src.amplitude[1, :]
    n_conv = length(As)
    for n in 2:length(As)
        r0 = total_rms(As[1:n-1])
        r1 = total_rms(As[1:n])
        dB0 = 20 * log10(r0 / 20e-6 + 1e-30)
        dB1 = 20 * log10(r1 / 20e-6 + 1e-30)
        if abs(dB1 - dB0) < 0.1
            n_conv = n
            break
        end
    end

    # Blade-angle shift rule reminder
    beta75_design = 42.64

    open(OUT, "w") do io
        println(io, "# Report 996 setup (phase 25k)")
        println(io)
        println(io, "Generated $(Dates.today()) by `scripts/run/report996_setup.jl`.")
        println(io)
        println(io, "## 25a static probe")
        println(io)
        println(io, "See prior `report996_setup.md` / `probe_static.jl` results (finite at V=0 with `allow_static=true`; continuity |A(0)−A(1)|/A(1)≈0.23).")
        println(io)
        println(io, "## x-sign / Fig. 13(a) asymmetry")
        println(io)
        println(io, "Convention: `x_sign=R996_X_SIGN` (+1): report x/D positive ahead, AA +X ahead (the rotor travels along +X); Phase 72.")
        println(io, "Case: β₇₅=15°, M_t=0.75, d/D=0.083, H1, CCBlade loads (unscaled).")
        println(io)
        println(io, "| side | x/D | A_H1 Pa | A_H1 dyne/cm² |")
        println(io, "|---|---:|---:|---:|")
        println(io, "| behind | -0.125 | $(round(A_behind; digits=2)) | $(round(pa_to_dyne_cm2(A_behind); digits=1)) |")
        println(io, "| ahead | +0.125 | $(round(A_ahead; digits=2)) | $(round(pa_to_dyne_cm2(A_ahead); digits=1)) |")
        println(io)
        println(io, "behind > ahead: **$(asym_ok)** (Fig. 13(a) measured ~1328 vs ~1009 dyne/cm²).")
        println(io, "Absolute levels remain far above measured (near-field F1A at d/D=0.083); pass/fail waits on 23c [AUTHOR].")
        println(io)
        println(io, "## Blade-angle shift (25b)")
        println(io)
        println(io, "β(r) = β₇₅,target + (β_design(r) − $(beta75_design)°); design β₇₅ from `blade_form.csv`.")
        println(io)
        println(io, "## Polar coverage (25c)")
        println(io)
        println(io, "Phase 69 polar (`polars_phase69_ncrit8.json`, free transition, N_crit 8): clamped_Re=$(st.clamped_Re), clamped_M=$(st.clamped_M), viterna_evals=$(st.viterna_evals), nearest_polar=$(st.nearest_polar).")
        println(io)
        println(io, "## Harmonic count for total-rms convergence (25k)")
        println(io)
        println(io, "At behind x/D=−0.125: adding harmonic n changes total SPL by < 0.1 dB starting at **n = $(n_conv)** (of $(length(As)) computed).")
        println(io)
        println(io, "## Related")
        println(io)
        println(io, "- Acoustics matrix: `report996_acoustics.md` / `f1a_results.csv`")
        println(io, "- Loads: `report996_loads.md`")
        println(io, "- Fig. 3 digitization (C-12): `data/report996/tr996_fig3_blade_form.csv`")
    end
    println("wrote ", OUT)
    println("asym behind>ahead=", asym_ok, " n_conv=", n_conv)
end

main()
