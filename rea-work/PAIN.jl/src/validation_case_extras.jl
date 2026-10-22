# Additional Phase-34 case runners (E11/E12/E14/GEXT/BBN_KIN/R996_PHASE + report replays).
# Heavy source cases that still live mainly in scripts return a plotted summary from
# recorded report numbers plus reference CSVs when present (same fixed criterion; not tuned).

function _e12_readcurve(path)
    rows = [split(strip(l), ',') for l in eachline(path)
            if !isempty(strip(l)) && !startswith(strip(l), '#')]
    isempty(rows) && return Dict{Int,Vector{Tuple{Float64,Float64}}}()
    header = rows[1]
    data = rows[2:end]
    c = Dict{Int,Vector{Tuple{Float64,Float64}}}()
    for r in data
        length(r) < 3 && continue
        H = parse(Int, r[1])
        push!(get!(c, H, Tuple{Float64,Float64}[]), (parse(Float64, r[2]), parse(Float64, r[3])))
    end
    for v in values(c)
        sort!(v; by=first)
    end
    return c
end

function _e12_interp(pts, x)
    isempty(pts) && return NaN
    (x < pts[1][1] || x > pts[end][1]) && return NaN
    for i in 1:length(pts)-1
        x1, y1 = pts[i]; x2, y2 = pts[i+1]
        x1 <= x <= x2 && return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
    end
    return pts[end][2]
end

"""Fig. E-12: Eq. (43) R1 on Table 8 vs digitized predicted/measured."""
function _run_e12_block()
    data = joinpath(@__DIR__, "..", "..", "data", "cr3813", "e12")
    predA = _e12_readcurve(joinpath(data, "e12_predicted_A.csv"))
    predB = _e12_readcurve(joinpath(data, "e12_predicted_B.csv"))
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.90)
    pts = [p for p in grid_points(fuse, prop, GridSpec()) if p.ell == 1]
    D = 0.762
    X3D = Float64[p.x3 / D for p in pts]
    γ = Float64[incidence_angle_deg(fuse, prop, p.theta_deg, p.z) for p in pts]
    ΔL = Float64[delta_L_blocking_dB(g; variant=R1) for g in γ]
    t8path = _data_path("cr3813", "anopp_table8_spl_dB.csv")
    rows = [split(strip(l), ',') for l in eachline(t8path)
            if !isempty(strip(l)) && !startswith(strip(l), '#')][2:end]
    t8 = [parse.(Float64, r[2:4]) for r in rows]
    n = min(length(X3D), length(t8))
    table = ValidationTableRow[]
    series = PlotSeries[]
    n_ok = 0
    n_tot = 0
    # δ_pred + 0.5 from e12 script (δ_pred ≈ 2.91 → tol ≈ 3.41); use 3.41 fixed dated criterion
    tol = 3.41
    for H in 1:3
        ref_pts = haskey(predA, H) ? predA[H] : Tuple{Float64,Float64}[]
        xref = Float64[p[1] for p in ref_pts]
        yref = Float64[p[2] for p in ref_pts]
        ycomp = Float64[]
        xcomp = Float64[]
        for i in 1:n
            ff = t8[i][H]
            got = ff + ΔL[i]
            push!(xcomp, X3D[i])
            push!(ycomp, got)
            r = _e12_interp(ref_pts, X3D[i])
            if isfinite(r)
                ok = abs(got - r) ≤ tol
                n_tot += 1
                n_ok += ok
                push!(table, ValidationTableRow("H$H blocked SPL", X3D[i], r, got, got - r, ok))
            end
        end
        push!(series, PlotSeries("NASA pred A H$H", :reference_points, xref, yref; panel=H))
        if haskey(predB, H)
            push!(series, PlotSeries("NASA pred B H$H", :reference_points,
                                    Float64[p[1] for p in predB[H]],
                                    Float64[p[2] for p in predB[H]]; panel=H))
        end
        push!(series, PlotSeries("Eq.43+Table8 H$H", :computed, xcomp, ycomp; panel=H))
    end
    all_ok = n_ok == n_tot && n_tot > 0
    return ValidationCaseResult(
        "E12_BLOCK", _today_iso(),
        (; blocking=:R1, free_field="ANOPP Table 8", tol_dB=tol,
         csv_pred=joinpath(data, "e12_predicted_A.csv"),
         csv_table8=t8path),
        table, series, all_ok ? :met : :not_met,
        "$n_ok/$n_tot within ±$(tol) dB of digitized NASA predicted E-12",
        "V-CODE", joinpath(_VAL_REPORT_DIR, "e12_blocking.md"),
    )
end

"""Fig. E-11 free-field line: digitization A vs B (δ_dig) and mean used as input."""
function _run_e11_freefield()
    paths = default_e11_paths()
    δmax, δH = delta_dig_dB(paths.A, paths.B)
    A = _read_csv_numeric(paths.A)
    B = _read_csv_numeric(paths.B)
    k = Float64.(A[:k])
    # X3/D from grid k index on ℓ=1 (same geometry as e11 path)
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.90)
    line = [p for p in grid_points(fuse, prop, GridSpec()) if p.ell == 1]
    D = 0.762
    x3d = Dict(Int(round(p.k)) => p.x3 / D for p in line)
    xs = Float64[get(x3d, Int(round(ki)), ki) for ki in k]
    table = ValidationTableRow[]
    series = PlotSeries[]
    tol = 1.0
    n_ok = 0
    n_tot = 0
    for (H, key) in ((1, :SPL_H1_dB), (2, :SPL_H2_dB), (3, :SPL_H3_dB))
        ya = Float64.(A[key]); yb = Float64.(B[key])
        ymean = 0.5 .* (ya .+ yb)
        push!(series, PlotSeries("pass A H$H", :reference_points, xs, ya; panel=H))
        push!(series, PlotSeries("pass B H$H", :reference_points, xs, yb; panel=H))
        push!(series, PlotSeries("mean (input) H$H", :computed, xs, ymean; panel=H))
        for i in eachindex(ya)
            d = abs(ya[i] - yb[i])
            ok = d ≤ tol
            n_tot += 1
            n_ok += ok
            push!(table, ValidationTableRow("δ_dig H$H k=$(Int(round(k[i])))", xs[i], ya[i], yb[i], yb[i] - ya[i], ok))
        end
    end
    ok_gate = δmax ≤ tol
    return ValidationCaseResult(
        "E11_FREEFIELD", _today_iso(),
        (; δmax_dB=δmax, criterion="δ_dig ≤ 1.0 dB", date="2026-10-20",
         csv_A=paths.A, csv_B=paths.B),
        table, series, ok_gate ? :met : :not_met,
        "δ_dig max=$(round(δmax; digits=3)) dB (H1=$(round(δH[1]; digits=3)), H2=$(round(δH[2]; digits=3)), H3=$(round(δH[3]; digits=3))); gate ≤ $(tol) dB",
        "V-ASSUMED", joinpath(_VAL_REPORT_DIR, "e11_delta_dig.md"),
    )
end

"""Fig. E-14 acoustic loss: Eq. (78) via `acoustic_loss_average` vs NASA calculated CSV."""
function _run_e14_loss()
    cols = _read_csv_numeric(_data_path("cr3813", "e14_acoustic_loss_calculated.csv"))
    fc = Float64.(cols[:f_Hz])
    ref05 = Float64.(cols[:eta_calc_trim0p5])
    ref10 = Float64.(cols[:eta_calc_trim1p0])
    a, L, θ0d = 0.508, test_article_length(), 56.6
    θ0 = deg2rad(θ0d)
    fuse = FuselageGeometry(L, a, θ0d)
    V = cabin_volume(fuse)
    S = 2a * (π - θ0) * L
    S_e = V / L
    c0, ρ0 = 340.0, 1.225
    p3 = phase3_trim(; η_lining=0.5)
    got = Float64[]
    for f in fc
        ω = 2π * f
        ξ = trim_conductance(p3.sidewall, ω, p3.m_wall; ρ0, c0)
        ξe = trim_conductance(p3.ends, ω, Inf; ρ0, c0)
        push!(got, acoustic_loss_average(ω; V, S, S_e, ξ, ξ_e=ξe, c0))
    end
    table = ValidationTableRow[]
    n_ok = 0
    for i in eachindex(fc)
        ratio = got[i] / ref05[i]
        ok = abs(ratio - 1) ≤ 0.25
        n_ok += ok
        push!(table, ValidationTableRow("η̄ η_T=0.5 f=$(round(fc[i]; digits=0))", fc[i],
                                        ref05[i], got[i], got[i] - ref05[i], ok))
    end
    series = [
        PlotSeries("NASA η_T=0.5", :reference_points, fc, ref05; panel=1),
        PlotSeries("NASA η_T=1.0", :reference_points, fc, ref10; panel=1),
        PlotSeries("Eq.(78) η_T=0.5", :computed, fc, got; panel=1),
    ]
    return ValidationCaseResult(
        "E14_LOSS", _today_iso(),
        (; criterion="±25 % of NASA calculated Fig. E-14", date="2026-10-20", η_lining=0.5,
         csv=_data_path("cr3813", "e14_acoustic_loss_calculated.csv")),
        table, series, n_ok == length(fc) ? :met : :not_met,
        "$n_ok/$(length(fc)) bands within ±25 % (criterion often not met; not tuned)",
        "V-CODE", joinpath(_VAL_REPORT_DIR, "trim_loss_e13_e14_e15.md"),
    )
end

"""GEXT importance bound: nominal vs flat falloff residual to T1 mean (quick subset)."""
function _run_gext_bound()
    paths = default_e11_paths()
    tg = _read_csv_numeric(joinpath(dirname(paths.A), "t1_interior_targets.csv"))
    means = Float64.(tg[:measured_mean_SPL_dB][1:3])
    function e11_pipe(; falloff_exponent=1.0, delay_scale=1.0)
        L = test_article_length()
        fuse = FuselageGeometry(L, 0.508, 56.6)
        prop = PropellerPlacement(0.965, 90.0, 0.90)
        spec = GridSpec()
        amp = _read_csv_numeric(paths.A)
        ph = _read_csv_numeric(paths.phases)
        anopp = _read_csv_numeric(paths.anopp_spl)
        nH, k_max = 3, spec.k_max
        line_amps = zeros(k_max, nH)
        line_phases = zeros(k_max, nH)
        ks = Int.(round.(amp[:k]))
        for (i, k) in enumerate(ks)
            1 ≤ k ≤ k_max || continue
            for H in 1:nH
                key = H == 1 ? :SPL_H1_dB : H == 2 ? :SPL_H2_dB : :SPL_H3_dB
                spl = amp[key][i]
                jA = findfirst(==(float(k)), anopp[:k])
                if jA !== nothing
                    spl_a = anopp[key][jA]
                    if H >= 3 || spl - spl_a > 10.0
                        spl = spl_a
                    end
                end
                line_amps[k, H] = spl_dB_to_peak_Pa(spl)
                pkey = H == 1 ? :phase_H1_deg : H == 2 ? :phase_H2_deg : :phase_H3_deg
                j = findfirst(==(float(k)), ph[:k])
                line_phases[k, H] = deg2rad(ph[pkey][j])
            end
        end
        pts = grid_points(fuse, prop, spec)
        ωH = [2π * H * 200.0 for H in 1:nH]
        amps, phases = extend_line_to_grid(line_amps, line_phases, pts; omega_H=ωH,
                                           falloff_exponent=falloff_exponent, delay_scale=delay_scale)
        ff = FreeFieldHarmonicGrid(pts, collect(1:nH), amps, phases, :e11_digitized, "gext", 200.0)
        bl = apply_blocking(ff, fuse, prop; variant=R2)
        acoustic = cyl2d_modes(56.6; n_modes=20, NY=10)
        structural = structural_modes_from_table_d1(; n_keep=32)
        ΔA = (π * 0.508 / 18)^2
        p3 = phase3_trim(; a=0.508, L=L, theta0_deg=56.6)
        inp = PainInputs(fuse, prop, structural, acoustic, bl.amplitudes, bl.phases, bl.pts, ΔA;
                         sidewall=p3.sidewall, endplates=p3.ends, mech=p3.mech, m_wall=p3.m_wall)
        return interior_spl(inp; bpf_Hz=200.0, n_harmonics=3)
    end
    variants = [("nominal", 1.0, 1.0), ("flat n=0", 0.0, 1.0), ("delay×2", 1.0, 2.0)]
    table = ValidationTableRow[]
    series = PlotSeries[]
    xs = Float64[]
    for (vi, (name, n, d)) in enumerate(variants)
        push!(xs, Float64(vi))
        spec = e11_pipe(; falloff_exponent=n, delay_scale=d)
        for H in 1:3
            res = spec.harmonic_SPL_dB[H] - means[H]
            # gate edges ±4 dB around mean → residual within ±4 is "pass" for that H
            ok = abs(res) ≤ 4.0
            push!(table, ValidationTableRow("$name H$H residual", Float64(vi), 0.0, res, res, ok))
        end
    end
    for H in 1:3
        y = Float64[row.computed for row in table if endswith(row.quantity, "H$H residual")]
        push!(series, PlotSeries("residual H$H", :computed, xs[1:length(y)], y; panel=H))
        push!(series, PlotSeries("gate ±4 dB", :reference_band, xs, zeros(length(xs));
                                 ylow=fill(-4.0, length(xs)), yhigh=fill(4.0, length(xs)), panel=H))
    end
    # Diagnostic only — no pass/fail criterion (phase 32).
    return ValidationCaseResult(
        "GEXT_BOUND", _today_iso(),
        (; variants=["nominal", "flat n=0", "delay×2"], η_T=0.5,
         csv_targets=joinpath(dirname(paths.A), "t1_interior_targets.csv"),
         csv_e11=paths.A),
        table, series, :no_verdict,
        "diagnostic: shows how far T1 moves under the assumed GEXT variants; no pass criterion (phase 32) (amplitude convention fixed 2026-10-21, post-hoc)",
        "V-ASSUMED (amplitude convention fixed 2026-10-21, post-hoc)",
        joinpath(_VAL_REPORT_DIR, "gext_importance_bound.md"),
    )
end

_wrap180(x::Real) = mod(Float64(x) + 180.0, 360.0) - 180.0

"""
    bbn_printed_pair_phase(φa_deg, φb_deg) -> Float64

Printed BBN pair phase for microphone pair a–b: `wrap180(φb − φa)` in degrees.

CR-158919 §3.4 (printed p. 14, PDF p. 20): coherence and phase between pairs were
measured on the SD360 with Function 6 (transfer function B/A). Table 8 (printed
p. 35): positive U_c is rearward/upward, and for every pair that has both a Table 8
velocity and an App. C phase, sign(U_c) = −sign(printed phase). Hence the printed
App. C phase is φ_b − φ_a in the FFT coefficient convention cos(ωt + φ) (a lag is
a negative φ): it is negative when the second mic lags.
"""
function bbn_printed_pair_phase(φa_deg::Real, φb_deg::Real)
    return _wrap180(Float64(φb_deg) - Float64(φa_deg))
end

"""BBN 24b kinematic Δφ = m·B·Δψ (V-UNIT)."""
function _run_bbn_kin()
    json = joinpath(@__DIR__, "..", "examples", "bbn_aerocommander_tipA.json")
    cfg = _load_aircraft_json(json)
    R = 1.18
    seps = [13.3, 11.8, 10.4]
    ψ = cumsum([0.0; seps])
    r_obs = R + 0.15
    B = Int(cfg.propeller.num_blades)
    obs = [Observer([0.0, r_obs * cosd(a), r_obs * sind(a)], zeros(3), "ψ=$a") for a in ψ]
    src = evaluate_propeller_source(cfg, obs; n_harmonics=3, num_src_times=64, allow_static=true)
    table = ValidationTableRow[]
    series = PlotSeries[]
    n_ok = 0
    n_tot = 0
    dφ11 = rad2deg(mod(src.phase[2, 1] - src.phase[1, 1] + π, 2π) - π)
    sense_sign = sign(dφ11) == 0 ? 1.0 : sign(dφ11)
    for (i, Δψ) in enumerate(seps)
        Hs = Float64[]
        dφs = Float64[]
        expect_line = Float64[]
        for H in 1:3
            dφ = rad2deg(mod(src.phase[i + 1, H] - src.phase[i, H] + π, 2π) - π)
            expect = sense_sign * H * B * Δψ
            expect = mod(expect + 180, 360) - 180
            ok = abs(dφ - expect) ≤ 0.5
            n_tot += 1
            n_ok += ok
            push!(table, ValidationTableRow("pair$(i) H$H", Float64(H), expect, dφ, dφ - expect, ok, "pair$i"))
            push!(Hs, Float64(H)); push!(dφs, dφ); push!(expect_line, expect)
        end
        push!(series, PlotSeries("m·B·Δψ pair$i", :reference_points, Hs, expect_line; panel=i))
        push!(series, PlotSeries("F1A Δφ pair$i", :computed_points, Hs, dφs; panel=i))
    end
    return ValidationCaseResult(
        "BBN_KIN", _today_iso(),
        (; B=B, seps_deg=seps, tol_deg=0.5, criterion_date="2026-10-21",
         data_source="live_kinematic_VUNIT"),
        table, series, n_ok == n_tot ? :met : :not_met,
        "$n_ok/$n_tot within ±0.5° of m·B·Δψ (24b)",
        "V-UNIT", joinpath(_VAL_REPORT_DIR, "bbn_phase.md"),
    )
end

"""Report 996 page-12 phase: measured/Eq.2 from CSV; F1A from f1a_results.csv (script rule)."""
function _run_r996_phase()
    phase_csv = _data_path("report996", "tr996_phase_values.csv")
    f1a_csv = _data_path("report996", "f1a_results.csv")
    measured = NaN; eq2 = NaN
    for l in eachline(phase_csv)
        startswith(strip(l), "#") && continue
        startswith(l, "quantity") && continue
        p = split(strip(l), ',')
        length(p) >= 5 || continue
        p[1] == "phase_difference_ahead_vs_behind" || continue
        val = parse(Float64, p[3])
        if p[5] == "measured"
            measured = val
        elseif p[4] == "Eq. (2)" && p[5] == "calculated"
            eq2 = val
        end
    end
    (isfinite(measured) && isfinite(eq2)) || error("tr996_phase_values.csv missing measured/Eq.(2)")
    # Script rule (run_report996_acoustics.jl Page-12): principal |Δφ| between
    # fig13a primary scaled_RM_L51C27 at x/D = −0.125 and +0.125, harmonic 2.
    ph_m = NaN; ph_p = NaN
    hdr, rows = _read_csv_rows(f1a_csv)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    for r in rows
        length(r) < length(hdr) && continue
        r[col["figure"]] == "fig13a" || continue
        r[col["polar_set"]] == "primary" || continue
        r[col["loads"]] == "scaled_RM_L51C27" || continue
        parse(Int, r[col["harmonic"]]) == 2 || continue
        xd = parse(Float64, r[col["x_over_D"]])
        ph = parse(Float64, r[col["phase_rad"]])
        abs(xd + 0.125) < 1e-9 && (ph_m = ph)
        abs(xd - 0.125) < 1e-9 && (ph_p = ph)
    end
    (isfinite(ph_m) && isfinite(ph_p)) || error("f1a_results.csv missing fig13a ±0.125 phases")
    dφ = abs(ph_m - ph_p)
    dφ = min(dφ, 2π - dφ)
    f1a = dφ * 180 / π
    tol = 15.0  # 23c page-12; FAIL recorded
    ok = abs(f1a - measured) ≤ tol
    table = [ValidationTableRow("phase difference (deg)", 1.0, measured, f1a, f1a - measured, ok, "phase")]
    series = [
        PlotSeries("measured $(measured)°", :reference_points, [1.0], [measured]; panel=1),
        PlotSeries("Eq.2 $(eq2)°", :reference_points, [1.0], [eq2]; panel=1),
        PlotSeries("F1A", :computed_points, [1.0], [f1a]; panel=1),
    ]
    return ValidationCaseResult(
        "R996_PHASE", _today_iso(),
        (; measured_deg=measured, eq2_deg=eq2, f1a_deg=round(f1a; digits=1),
         csv_phase=phase_csv, csv_f1a=f1a_csv,
         criterion="23c page-12 |Δφ − 155°| ≤ 15°", date="2026-10-21"),
        table, series, :not_met,
        "F1A $(round(f1a; digits=1))° vs measured $(measured)° (FAIL recorded; not re-tuned)",
        "X-EXTRAP", joinpath(_VAL_REPORT_DIR, "report996_acoustics.md"),
    )
end

"""Runnable but points at the long script report (full F1A matrix not inlined yet)."""
function _run_see_report(id, reason, label, report)
    r = _run_unavailable(id, reason, label, report)
    # empty series → plot_case draws the reason text; case is not greyed (unavailable_reason="")
    return r
end

"""CR-172428 p.68 checkpoints for Eq. (43) R1 (V-UNIT)."""
function _run_blk_p68()
    γs = collect(0.0:1.0:90.0)
    r1 = Float64[delta_L_blocking_dB(g; variant=R1) for g in γs]
    r2 = Float64[delta_L_blocking_dB(g; variant=R2) for g in γs]
    table = ValidationTableRow[]
    n_ok = 0
    n_tot = 0
    tol = 0.06
    xref = Float64[]
    yref = Float64[]
    for (γ, expected) in BLOCKING_P68_CHECKPOINTS
        got = delta_L_blocking_dB(γ; variant=R1)
        ok = abs(got - expected) ≤ tol
        n_tot += 1
        n_ok += ok
        push!(table, ValidationTableRow("R1 ΔL γ=$(γ)", Float64(γ), expected, got, got - expected, ok))
        push!(xref, Float64(γ)); push!(yref, expected)
    end
    series = [
        PlotSeries("p.68 checkpoints", :reference_points, xref, yref; panel=1),
        PlotSeries("R1 Eq.(43)", :computed, γs, r1; panel=1),
        PlotSeries("R2", :reference_curve, γs, r2; panel=1),
    ]
    return ValidationCaseResult(
        "BLK_P68", _today_iso(),
        (; tol_dB=tol, criterion="R1 ΔL within 0.06 dB of CR-172428 p.68", date="2026-10-19",
         reference_tables=["BLOCKING_P68_CHECKPOINTS"]),
        table, series, n_ok == n_tot ? :met : :not_met,
        "$n_ok/$n_tot checkpoints within ±$(tol) dB",
        "V-UNIT", joinpath(_VAL_REPORT_DIR, "blocking_p68.md"),
    )
end

"""Raw Ritz vs Table D-1 — calibrated fit quality only; verdict always :no_verdict."""
function _run_mrp_ritz()
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    ritz = structural_modes(fuse; hybrid=false, n_keep=48)
    npass, pairs = match_ritz_to_table_d1(ritz; tol_frac=0.05)
    table = ValidationTableRow[]
    idxs = Float64[]
    ref_f = Float64[]
    got_f = Float64[]
    for p in pairs
        push!(table, ValidationTableRow("f_Hz mode $(p.d1)", Float64(p.d1),
                                        p.ref, p.got, p.got - p.ref, p.ok))
        push!(idxs, Float64(p.d1)); push!(ref_f, p.ref); push!(got_f, p.got)
    end
    series = [
        PlotSeries("Table D-1", :reference_points, idxs, ref_f; panel=1),
        PlotSeries("raw Ritz (fitted scales)", :computed, idxs, got_f; panel=1),
    ]
    return ValidationCaseResult(
        "MRP_RITZ", _today_iso(),
        (; hybrid=false, n_keep=48, tol_frac=0.05, npass=npass, n_modes=length(pairs),
         reference_tables=["TABLE_D1_FULL"]),
        table, series, :no_verdict,
        "fit quality of a calibrated solver — not evidence (CLAUDE.md); $npass/$(length(pairs)) within 5 %",
        "calibrated (k_scale, edge_factor, floor_scale fitted to Table D-1)",
        joinpath(_VAL_REPORT_DIR, "mrp_ritz_vs_d1.md"),
    )
end

"""
App. D solver vs Table D-1 (38g). Criterion fixed 2026-10-22 before any run:
≥ 75 % of 32 modes within 5 %, no calibration input. Fig. D-2 reported without a pass mark.
"""
function _run_mrp_appd()
    g = appd_test_article_geometry()
    modes = appd_modes(g; n_modes=48, n_axial=7, n_circ=8, n_floor_max=5)
    npass, pairs = match_ritz_to_table_d1(modes; tol_frac=0.05)
    n_ref = length(TABLE_D1_FULL)
    frac = npass / n_ref
    # Count rule fixed 2026-10-22: ≥ 75 % of 32 within 5 %, no calibration.
    met = (npass >= ceil(Int, 0.75 * n_ref))
    table = ValidationTableRow[]
    idxs = Float64[]; ref_f = Float64[]; got_f = Float64[]
    for p in pairs
        push!(table, ValidationTableRow("f_Hz mode $(p.d1)", Float64(p.d1),
                                        p.ref, p.got, p.got - p.ref, p.ok))
        push!(idxs, Float64(p.d1)); push!(ref_f, p.ref); push!(got_f, p.got)
    end
    # Fig. D-2 mode-1 shape at digitized points — report only, no pass mark
    # CSV columns: part,index,position,value (floor index i → x=i·Lp/20; shell row k → θ=5k°)
    d2_path = _data_path("cr3813", "fig_d2_mode1_digitized.csv")
    d2_notes = "Fig. D-2 not compared (digitized CSV missing)"
    if isfile(d2_path) && !isempty(modes.modes)
        m1 = modes.modes[1]
        for p in pairs
            if p.d1 == 1
                m1 = modes.modes[p.ritz]
                break
            end
        end
        Lp = 2 * g.a * sin(deg2rad(g.theta0_deg))
        hdr, rows = _read_csv_rows(d2_path)
        col = Dict(h => i for (i, h) in enumerate(hdr))
        peak_diff = 0.0
        n_pts = 0
        for r in rows
            length(r) < length(hdr) && continue
            part = r[col["part"]]
            idx = tryparse(Int, r[col["index"]])
            ref = tryparse(Float64, r[col["value"]])
            (idx === nothing || ref === nothing) && continue
            got = if part == "floor"
                x = idx * Lp / 20
                s = 0.0
                for (C, n) in zip(m1.C_floor, m1.n_floor)
                    s += m1.symmetric ? C * cos(n * π * x / Lp) : C * sin(n * π * x / Lp)
                end
                s
            else
                θ_deg = 5.0 * idx
                shell_circumferential(m1, deg2rad(θ_deg))
            end
            peak_diff = max(peak_diff, abs(got - ref))
            n_pts += 1
        end
        d2_notes = "Fig. D-2 mode-1: max |Δw| = $(round(peak_diff; digits=4)) over $n_pts digitized points (no pass mark)"
        push!(table, ValidationTableRow("Fig. D-2 max |Δw| (info)", 0.0, 0.0, peak_diff, peak_diff, true))
    end
    series = [
        PlotSeries("Table D-1", :reference_points, idxs, ref_f; panel=1),
        PlotSeries("App. D solver", :computed, idxs, got_f; panel=1),
    ]
    verdict = met ? :met : :not_met
    reason = "$npass/$n_ref within 5 % ($(round(100 * frac; digits=1)) %); " *
             "criterion ≥ 75 % of 32 within 5 %, no calibration (fixed 2026-10-22). $d2_notes"
    return ValidationCaseResult(
        "MRP_APPD", _today_iso(),
        (; n_modes=n_ref, npass, tol_frac=0.05, count_rule="≥75% of 32 within 5%",
         count_rule_date="2026-10-22", calibration=false,
         L=g.L, readings=APPD_READINGS,
         reference_tables=["TABLE_D1_FULL", "fig_d2_mode1_digitized.csv"]),
        table, series, verdict, reason,
        "V-CODE (vs NASA's solver outputs), first run of the printed App. D formulation 2026-10-22",
        joinpath(_VAL_REPORT_DIR, "mrp_appd_vs_d1.md"),
    )
end

"""F1A vs Gutin far-field H1 (I-01 c); shared with Pkg.test."""
function _run_f1a_gutin()
    cmp = f1a_gutin_h1_comparison()
    table = [ValidationTableRow("SPL H1 (dB)", 1.0, cmp.spl_gutin, cmp.spl_f1a,
                                cmp.delta_dB, cmp.ok)]
    series = [
        PlotSeries("Gutin", :reference_points, [1.0], [cmp.spl_gutin]; panel=1),
        PlotSeries("F1A", :computed, [1.0], [cmp.spl_f1a]; panel=1),
    ]
    return ValidationCaseResult(
        "F1A_GUTIN", _today_iso(),
        (; r_over_Rtip=100.0, thickness=:off, static=true, Mt=cmp.Mt, B=cmp.B,
         criterion="|SPL_F1A − SPL_Gutin| ≤ 1 dB", date="2026-10-21",
         data_source="live_F1A_vs_Gutin"),
        table, series, cmp.ok ? :met : :not_met,
        "Δ = $(round(cmp.delta_dB; digits=3)) dB (F1A=$(round(cmp.spl_f1a; digits=2)), Gutin=$(round(cmp.spl_gutin; digits=2)))",
        "V-CODE (cross-implementation)",
        joinpath(_VAL_REPORT_DIR, "README.md"),
    )
end

function _read_csv_rows(path::AbstractString)
    lines = [strip(l) for l in eachline(path) if !isempty(strip(l)) && !startswith(strip(l), '#')]
    isempty(lines) && return String[], Vector{String}[]
    hdr = split(lines[1], ',')
    rows = [split(l, ',') for l in lines[2:end]]
    return hdr, rows
end

"""Replay Report 996 F1A acoustics from recorded `f1a_results.csv` (23c counting)."""
function _run_r996_f1a_replay(id::AbstractString, figure_pred, load_pred;
                              xlabel="x/D", yscale=:identity, panel_titles=String["replay"])
    path = _data_path("report996", "f1a_results.csv")
    hdr, rows = _read_csv_rows(path)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    table = ValidationTableRow[]
    # series key → (xs, ys)
    computed_series = Dict{String,Tuple{Vector{Float64},Vector{Float64}}}()
    xref = Float64[]; yref = Float64[]
    n_ok = 0; n_in = 0
    for r in rows
        length(r) < length(hdr) && continue
        fig = r[col["figure"]]
        figure_pred(fig) || continue
        loads = r[col["loads"]]
        load_pred(loads) || continue
        meas = tryparse(Float64, r[col["meas_dyne_cm2"]])
        (meas === nothing || !isfinite(meas)) && continue
        A_rms = if haskey(col, "A_rms_Pa")
            parse(Float64, r[col["A_rms_Pa"]])
        else
            parse(Float64, r[col["A_Pa"]]) / sqrt(2)
        end
        comp = pa_to_dyne_cm2(A_rms)  # rms vs Report 996 measured rms (p.10)
        # Fig.14 uses M_t from case tag; others use x/D
        x = if fig == "fig14"
            # case like beta10_B2_Mt0.45
            m = match(r"Mt([0-9.]+)", r[col["case"]])
            m === nothing ? parse(Float64, r[col["x_over_D"]]) : parse(Float64, m.captures[1])
        else
            parse(Float64, r[col["x_over_D"]])
        end
        rdb = 20 * log10(comp / meas)
        ok = abs(rdb) ≤ 2.0
        n_in += 1
        n_ok += ok
        H = r[col["harmonic"]]
        polar = r[col["polar_set"]]
        push!(table, ValidationTableRow(
            "$polar/$loads H=$H", x, meas, comp, comp - meas, ok, "H$H"))
        push!(xref, x); push!(yref, meas)
        # One computed series per harmonic × loads/polar set (do not join harmonics).
        key = "$polar / $loads H=$H"
        xs, ys = get!(computed_series, key, (Float64[], Float64[]))
        push!(xs, x); push!(ys, comp)
    end
    series = PlotSeries[PlotSeries("measured", :reference_points, xref, yref; panel=1)]
    for (name, (xs, ys)) in sort(collect(computed_series); by=first)
        # Sort by x so lines (when drawn) do not zigzag across M_t / x/D.
        ord = sortperm(xs)
        push!(series, PlotSeries(name, :computed, xs[ord], ys[ord]; panel=1))
    end
    frac = n_in == 0 ? 0.0 : n_ok / n_in
    met = n_in > 0 && frac ≥ 0.75
    reason = "$n_ok/$n_in within ±2 dB ($(round(100 * frac; digits=0))%; need ≥75%); replay of data/report996/f1a_results.csv generated by scripts/run/run_report996_acoustics.jl (amplitude convention fixed 2026-10-21, post-hoc)"
    return ValidationCaseResult(
        String(id), _today_iso(),
        (; csv=path, criterion="23c ±2 dB at ≥75% scaled points", date="2026-10-21"),
        table, series, met ? :met : :not_met, reason,
        "V-EXP, calibrated loads (replay of recorded run; amplitude convention fixed 2026-10-21, post-hoc)",
        joinpath(_VAL_REPORT_DIR, "report996_acoustics.md"),
    )
end

_run_r996_fig14() = _run_r996_f1a_replay("R996_FIG14", ==("fig14"), ==("scaled");
    xlabel="M_t", yscale=:log10, panel_titles=["Fig. 14(a)"])
_run_r996_fig12() = _run_r996_f1a_replay("R996_FIG12", f -> startswith(f, "fig12"),
    l -> l == "scaled" || startswith(l, "scaled");
    xlabel="x/D", panel_titles=["Fig. 12(a)(b)"])
_run_r996_fig13a() = _run_r996_f1a_replay("R996_FIG13A", ==("fig13a"),
    l -> startswith(l, "scaled");
    xlabel="x/D", panel_titles=["Fig. 13(a)"])

"""Replay Report 996 CCBlade loads from `scale_factors.csv` (±15 % on C_T, C_P)."""
function _run_r996_loads()
    path = _data_path("report996", "scale_factors.csv")
    hdr, rows = _read_csv_rows(path)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    table = ValidationTableRow[]
    n_ok = 0; n_in = 0
    # series key (panel, name) → (xs, ys); one series per polar × β
    series_data = Dict{Tuple{Int,String,Symbol},Tuple{Vector{Float64},Vector{Float64}}}()
    for r in rows
        length(r) < length(hdr) && continue
        Mt = parse(Float64, r[col["M_t"]])
        polar = r[col["polar_set"]]
        β = r[col["beta75_deg"]]
        tag = "$polar β=$β"
        for (qty, ccb_key, meas_key, panel) in (("C_T", "CT_ccb", "CT_meas", 1),
                                                 ("C_P", "CP_ccb", "CP_meas", 2))
            meas = tryparse(Float64, r[col[meas_key]])
            (meas === nothing || !isfinite(meas) || meas == 0) && continue
            ccb = parse(Float64, r[col[ccb_key]])
            ok = abs(ccb / meas - 1) ≤ 0.15
            n_in += 1
            n_ok += ok
            push!(table, ValidationTableRow("$qty $tag Mt=$Mt", Mt,
                                            meas, ccb, ccb - meas, ok, qty))
            km = (panel, "$qty meas $tag", :reference_points)
            xs, ys = get!(series_data, km, (Float64[], Float64[]))
            push!(xs, Mt); push!(ys, meas)
            kc = (panel, "$qty $tag", :computed)
            xs2, ys2 = get!(series_data, kc, (Float64[], Float64[]))
            push!(xs2, Mt); push!(ys2, ccb)
        end
    end
    series = PlotSeries[]
    for ((panel, name, kind), (xs, ys)) in sort(collect(series_data); by=first)
        ord = sortperm(xs)
        push!(series, PlotSeries(name, kind, xs[ord], ys[ord]; panel=panel))
    end
    return ValidationCaseResult(
        "R996_LOADS", _today_iso(),
        (; csv=path, criterion="|CCBlade/meas − 1| ≤ 0.15", date="2026-10-21"),
        table, series, n_ok == n_in && n_in > 0 ? :met : :not_met,
        "$n_ok/$n_in within ±15 %; replay of data/report996/scale_factors.csv generated by scripts/run/run_report996_loads.jl",
        "post-hoc (criteria registered after the loads were computed)",
        joinpath(_VAL_REPORT_DIR, "report996_loads.md"),
    )
end

"""Report 996 Fig. 6 tip-clearance: reference curves + unscaled max (informational; no B=4 loads)."""
function _run_r996_fig6()
    f1a_csv = _data_path("report996", "f1a_results.csv")
    ref_csv = _data_path("report996", "tr996_fig6_tip_clearance_pressure_vs_xD.csv")
    hdr, rows = _read_csv_rows(f1a_csv)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    # d/D → (p_rms_Pa, ratio)
    computed = Dict{Float64,Tuple{Float64,Float64}}()
    for r in rows
        length(r) < length(hdr) && continue
        r[col["figure"]] == "fig6" || continue
        dD = parse(Float64, r[col["d_over_D"]])
        computed[dD] = (parse(Float64, r[col["p_rms_total_Pa"]]),
                        parse(Float64, r[col["p_c"]]))
    end
    dDs = sort(collect(keys(computed)))
    ref_sym = Dict{Float64,Vector{Tuple{Float64,Float64}}}()
    ref_fair = Dict{Float64,Vector{Tuple{Float64,Float64}}}()
    for l in eachline(ref_csv)
        startswith(strip(l), "#") && continue
        startswith(l, "report") && continue
        p = split(strip(l), ',')
        length(p) >= 12 || continue
        dD = parse(Float64, p[7]); xd = parse(Float64, p[8])
        kind = p[11]; val = parse(Float64, p[12])
        if kind == "symbol"
            push!(get!(ref_sym, dD, Tuple{Float64,Float64}[]), (xd, val))
        elseif kind == "faired"
            push!(get!(ref_fair, dD, Tuple{Float64,Float64}[]), (xd, val))
        end
    end
    table = ValidationTableRow[]
    series = PlotSeries[]
    panel_titles = String[]
    for (pi, dD) in enumerate(dDs)
        push!(panel_titles, "d/D=$(dD)")
        pts = get(ref_sym, dD, Tuple{Float64,Float64}[])
        isempty(pts) && (pts = get(ref_fair, dD, Tuple{Float64,Float64}[]))
        sort!(pts; by=first)
        xref = Float64[p[1] for p in pts]; yref = Float64[p[2] for p in pts]
        push!(series, PlotSeries("digitized", :reference_points, xref, yref; panel=pi))
        prms, ratio = computed[dD]
        comp_dyne = pa_to_dyne_cm2(prms)
        # F1A was computed only at x/D = 0 per d/D — single marker, not a line across x/D.
        push!(series, PlotSeries("F1A max (unscaled)", :computed_points, [0.0], [comp_dyne]; panel=pi))
        ref_max = isempty(yref) ? NaN : maximum(yref)
        push!(table, ValidationTableRow("max p_rms d/D=$dD", dD, ref_max, comp_dyne,
                                        comp_dyne - ref_max, false, "max p_rms"))
        push!(table, ValidationTableRow("ratio to 0.083 d/D=$dD", dD, NaN, ratio, NaN, false, "ratio"))
    end
    return ValidationCaseResult(
        "R996_FIG6", _today_iso(),
        (; csv_f1a=f1a_csv, csv_ref=ref_csv,
         criterion="informational (no B = 4 loads); shape and clearance ratios only",
         date="2026-10-21"),
        table, series, :no_verdict,
        "informational (no B = 4 loads); replay of data/report996/f1a_results.csv generated by scripts/run/run_report996_acoustics.jl",
        "X-EXTRAP", joinpath(_VAL_REPORT_DIR, "report996_acoustics.md"),
    )
end

"""Report 996 Fig. 7 p_c/C_P vs x/D — script does not apply 23c → :no_verdict."""
function _run_r996_fig7()
    f1a_csv = _data_path("report996", "f1a_results.csv")
    ref_csv = _data_path("report996", "tr996_fig7_blade_loading_pc_over_CP_vs_xD.csv")
    hdr, rows = _read_csv_rows(f1a_csv)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    computed = Dict{String,Vector{Tuple{Float64,Float64}}}()  # polar → [(x, pc)]
    for r in rows
        length(r) < length(hdr) && continue
        r[col["figure"]] == "fig7" || continue
        startswith(r[col["loads"]], "scaled") || continue
        key = r[col["polar_set"]]
        xd = parse(Float64, r[col["x_over_D"]])
        pc = parse(Float64, r[col["p_c"]])
        push!(get!(computed, key, Tuple{Float64,Float64}[]), (xd, pc))
    end
    xref = Float64[]; yref = Float64[]
    xfair = Float64[]; yfair = Float64[]
    for l in eachline(ref_csv)
        startswith(strip(l), "#") && continue
        startswith(l, "report") && continue
        p = split(strip(l), ',')
        length(p) >= 12 || continue
        xd = parse(Float64, p[8]); val = parse(Float64, p[12])
        if p[11] == "symbol"
            push!(xref, xd); push!(yref, val)
        elseif p[11] == "faired"
            push!(xfair, xd); push!(yfair, val)
        end
    end
    table = ValidationTableRow[]
    series = PlotSeries[]
    # Digitized symbols + faired curve so the reference shape is not hidden.
    if !isempty(xfair)
        ord = sortperm(xfair)
        push!(series, PlotSeries("digitized faired", :reference_curve, xfair[ord], yfair[ord]; panel=1))
    end
    if !isempty(xref)
        push!(series, PlotSeries("digitized", :reference_points, xref, yref; panel=1))
    end
    for (name, pts) in sort(collect(computed); by=first)
        sort!(pts; by=first)
        xs = Float64[p[1] for p in pts]; ys = Float64[p[2] for p in pts]
        push!(series, PlotSeries(name, :computed, xs, ys; panel=1))
        for (x, y) in pts
            # nearest ref for residual display only (no pass rule)
            ref = if isempty(xref)
                isempty(xfair) ? NaN : yfair[argmin(abs.(xfair .- x))]
            else
                yref[argmin(abs.(xref .- x))]
            end
            push!(table, ValidationTableRow("$name p_c/C_P", x, ref, y, y - ref, false, name))
        end
    end
    # Guard: reference + both polar computed series must be present.
    isempty(xref) && isempty(xfair) && error("R996_FIG7: no digitized reference points")
    length(computed) < 2 && error("R996_FIG7: expected both primary and bracket computed series")
    return ValidationCaseResult(
        "R996_FIG7", _today_iso(),
        (; csv_f1a=f1a_csv, csv_ref=ref_csv,
         criterion="no 23c pressure rule applied by script (informational shape)", date="2026-10-21"),
        table, series, :no_verdict,
        "informational; replay of data/report996/f1a_results.csv generated by scripts/run/run_report996_acoustics.jl",
        "X-EXTRAP", joinpath(_VAL_REPORT_DIR, "report996_acoustics.md"),
    )
end

function _pereira_csv_path()
    return _data_path("pereira", "pereira_results.csv")
end

"""Pereira Table 3 loads (informational — §2.12 has no load tolerance)."""
function _run_per_loads()
    path = _pereira_csv_path()
    ref_csv = _data_path("pereira", "pereira_tables3_4.csv")
    hdr, rows = _read_csv_rows(path)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    table = ValidationTableRow[]
    xs_t = Float64[]; yt = Float64[]; yc_t = Float64[]
    xs_q = Float64[]; yq = Float64[]; yc_q = Float64[]
    i = 0
    for r in rows
        length(r) < length(hdr) && continue
        r[col["loads"]] == "ccblade" || continue  # unscaled CCBlade vs Table 3 Exp
        qty = r[col["quantity"]]
        qty in ("T", "Q") || continue
        i += 1
        comp = parse(Float64, r[col["computed"]])
        ref = parse(Float64, r[col["reference"]])
        push!(table, ValidationTableRow("$(qty) $(r[col["polar_set"]])", Float64(i),
                                        ref, comp, comp - ref, false))
        if qty == "T"
            push!(xs_t, Float64(i)); push!(yt, ref); push!(yc_t, comp)
        else
            push!(xs_q, Float64(i)); push!(yq, ref); push!(yc_q, comp)
        end
    end
    series = [
        PlotSeries("Table 3 Exp T", :reference_points, xs_t, yt; panel=1),
        PlotSeries("CCBlade T", :computed, xs_t, yc_t; panel=1),
        PlotSeries("Table 3 Exp Q", :reference_points, xs_q, yq; panel=2),
        PlotSeries("CCBlade Q", :computed, xs_q, yc_q; panel=2),
    ]
    return ValidationCaseResult(
        "PER_LOADS", _today_iso(),
        (; csv=path, csv_ref=ref_csv, criterion="informational (no load tolerance in 23d)",
         date="2026-10-21"),
        table, series, :no_verdict,
        "informational; replay of data/pereira/pereira_results.csv generated by scripts/run/run_pereira.jl",
        "X-EXTRAP", joinpath(_VAL_REPORT_DIR, "pereira_forward_flight.md"),
    )
end

"""Pereira Fig. 9 harmonics — 23d H1 ±1.7 dB, H2 ±3 dB (recorded H1 0/9, H2 6/9)."""
function _run_per_fig9()
    path = _pereira_csv_path()
    ref_csv = _data_path("pereira", "pereira_fig9_harmonics.csv")
    hdr, rows = _read_csv_rows(path)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    table = ValidationTableRow[]
    n1 = 0; n1ok = 0; n2 = 0; n2ok = 0
    # panel: φ → 1,2,3 for 0,20,40
    φ_panel = Dict(0.0 => 1, 20.0 => 2, 40.0 => 3)
    series_data = Dict{Tuple{Int,String},Tuple{Vector{Float64},Vector{Float64}}}()
    for r in rows
        length(r) < length(hdr) && continue
        r[col["quantity"]] == "SPL_fig9" || continue
        r[col["loads"]] == "scaled" || continue
        ref = tryparse(Float64, r[col["reference"]])
        (ref === nothing || !isfinite(ref)) && continue  # excluded cells
        φ = parse(Float64, r[col["phi_deg"]])
        H = parse(Int, r[col["harmonic"]])
        comp = parse(Float64, r[col["computed"]])
        Δ = comp - ref
        tol = H == 1 ? 1.7 : (H == 2 ? 3.0 : Inf)
        ok = H <= 2 && abs(Δ) ≤ tol
        if H == 1
            n1 += 1; n1ok += ok
        elseif H == 2
            n2 += 1; n2ok += ok
        end
        push!(table, ValidationTableRow("$(r[col["polar_set"]]) φ=$φ H$H", Float64(H),
                                        ref, comp, Δ, ok, "H$H"))
        pan = get(φ_panel, φ, 0)
        pan == 0 && continue
        key = (pan, "ref"); xs, ys = get!(series_data, key, (Float64[], Float64[]))
        push!(xs, Float64(H)); push!(ys, ref)
        # One computed series per polar (do not join polars).
        keyc = (pan, r[col["polar_set"]]); xs2, ys2 = get!(series_data, keyc, (Float64[], Float64[]))
        push!(xs2, Float64(H)); push!(ys2, comp)
    end
    series = PlotSeries[]
    for ((pan, name), (xs, ys)) in sort(collect(series_data); by=first)
        kind = name == "ref" ? :reference_points : :computed
        ord = sortperm(xs)
        push!(series, PlotSeries(name == "ref" ? "Fig.9 Exp" : name, kind, xs[ord], ys[ord]; panel=pan))
    end
    met = n1 > 0 && n1ok == n1 && n2ok == n2  # 23d both harmonics
    reason = "H1 $n1ok/$n1 within ±1.7 dB; H2 $n2ok/$n2 within ±3 dB; replay of data/pereira/pereira_results.csv generated by scripts/run/run_pereira.jl"
    return ValidationCaseResult(
        "PER_FIG9", _today_iso(),
        (; csv=path, csv_ref=ref_csv, criterion="23d H1 ±1.7 dB, H2 ±3 dB", date="2026-10-21",
         n1ok=n1ok, n1=n1, n2ok=n2ok, n2=n2),
        table, series, met ? :met : :not_met,
        reason * " (amplitude convention fixed 2026-10-21, post-hoc)",
        "X-EXTRAP (amplitude convention fixed 2026-10-21, post-hoc)",
        joinpath(_VAL_REPORT_DIR, "pereira_forward_flight.md"),
    )
end

"""Pereira Fig. 8 directivity — 23d on H1/H2; H3+ informational."""
function _run_per_fig8()
    path = _pereira_csv_path()
    ref_csv = _data_path("pereira", "pereira_fig8_directivity.csv")
    hdr, rows = _read_csv_rows(path)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    table = ValidationTableRow[]
    n1 = 0; n1ok = 0; n2 = 0; n2ok = 0
    series_data = Dict{Tuple{Int,String},Tuple{Vector{Float64},Vector{Float64}}}()
    for r in rows
        length(r) < length(hdr) && continue
        r[col["quantity"]] == "SPL_fig8" || continue
        r[col["loads"]] == "scaled" || continue
        r[col["polar_set"]] == "ncrit9" || continue  # one polar for plot clarity
        ref = tryparse(Float64, r[col["reference"]])
        (ref === nothing || !isfinite(ref)) && continue
        φ = parse(Float64, r[col["phi_deg"]])
        H = parse(Int, r[col["harmonic"]])
        comp = parse(Float64, r[col["computed"]])
        Δ = comp - ref
        if H == 1
            ok = abs(Δ) ≤ 1.7; n1 += 1; n1ok += ok
        elseif H == 2
            ok = abs(Δ) ≤ 3.0; n2 += 1; n2ok += ok
        else
            ok = false  # informational
        end
        push!(table, ValidationTableRow("φ=$φ H$H", φ, ref, comp, Δ, H <= 2 ? ok : false, "H$H"))
        # One panel per harmonic; do not join harmonics on one line.
        keyr = (H, "ref"); xs, ys = get!(series_data, keyr, (Float64[], Float64[]))
        push!(xs, φ); push!(ys, ref)
        keyc = (H, "F1A"); xs2, ys2 = get!(series_data, keyc, (Float64[], Float64[]))
        push!(xs2, φ); push!(ys2, comp)
    end
    series = PlotSeries[]
    for ((H, name), (xs, ys)) in sort(collect(series_data); by=first)
        kind = name == "ref" ? :reference_points : :computed
        ord = sortperm(xs)
        push!(series, PlotSeries(name == "ref" ? "Fig.8 Exp" : name, kind, xs[ord], ys[ord]; panel=H))
    end
    return ValidationCaseResult(
        "PER_FIG8", _today_iso(),
        (; csv=path, csv_ref=ref_csv, criterion="23d H1 ±1.7 dB, H2 ±3 dB; H3+ informational",
         date="2026-10-21"),
        table, series, :not_met,
        "H1 $n1ok/$n1; H2 $n2ok/$n2 (H3+ excluded from verdict); replay of data/pereira/pereira_results.csv generated by scripts/run/run_pereira.jl (amplitude convention fixed 2026-10-21, post-hoc)",
        "X-EXTRAP (amplitude convention fixed 2026-10-21, post-hoc)",
        joinpath(_VAL_REPORT_DIR, "pereira_forward_flight.md"),
    )
end

"""Pereira Fig. 7 Δψ₁ — 23d ±5°."""
function _run_per_fig7()
    path = _pereira_csv_path()
    ref_csv = _data_path("pereira", "pereira_fig7_harmonics.csv")
    hdr, rows = _read_csv_rows(path)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    table = ValidationTableRow[]
    n = 0; nok = 0
    xref = Float64[]; yref = Float64[]; yc = Float64[]
    for r in rows
        length(r) < length(hdr) && continue
        r[col["quantity"]] == "dpsi1_fig7" || continue
        r[col["loads"]] == "scaled" || continue
        r[col["polar_set"]] == "ncrit9" || continue
        ref = tryparse(Float64, r[col["reference"]])
        (ref === nothing || !isfinite(ref)) && continue
        φ = parse(Float64, r[col["phi_deg"]])
        comp = parse(Float64, r[col["computed"]])
        # wrap residual
        resid = _wrap180(comp - ref)
        ok = abs(resid) ≤ 5.0
        n += 1; nok += ok
        push!(table, ValidationTableRow("Δψ₁ φ=$φ", φ, ref, comp, resid, ok, "Δψ₁"))
        push!(xref, φ); push!(yref, ref); push!(yc, comp)
    end
    series = [
        PlotSeries("Fig.7 Exp Δψ₁", :reference_points, xref, yref; panel=1),
        PlotSeries("F1A Δψ₁", :computed_points, xref, yc; panel=1),
    ]
    return ValidationCaseResult(
        "PER_FIG7", _today_iso(),
        (; csv=path, csv_ref=ref_csv, criterion="23d |Δψ₁| ≤ 5°", date="2026-10-21"),
        table, series, n > 0 && nok == n ? :met : :not_met,
        "$nok/$n within ±5°; replay of data/pereira/pereira_results.csv generated by scripts/run/run_pereira.jl",
        "X-EXTRAP", joinpath(_VAL_REPORT_DIR, "pereira_forward_flight.md"),
    )
end

"""Pereira Fig. 6 tones vs digitized peaks — informational (23d does not cover)."""
function _run_per_fig6()
    path = _pereira_csv_path()
    ref_csv = _data_path("pereira", "pereira_fig6_peaks.csv")
    hdr, rows = _read_csv_rows(path)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    φ_panel = Dict(0.0 => 1, 20.0 => 2, 40.0 => 3)
    table = ValidationTableRow[]
    series_data = Dict{Tuple{Int,String},Tuple{Vector{Float64},Vector{Float64}}}()
    for r in rows
        length(r) < length(hdr) && continue
        r[col["quantity"]] == "tone_fig6" || continue
        r[col["loads"]] == "scaled" || continue
        r[col["polar_set"]] == "ncrit9" || continue
        ref = tryparse(Float64, r[col["reference"]])
        (ref === nothing || !isfinite(ref)) && continue
        φ = parse(Float64, r[col["phi_deg"]])
        H = parse(Int, r[col["harmonic"]])
        comp = parse(Float64, r[col["computed"]])
        push!(table, ValidationTableRow("φ=$φ H$H", Float64(H), ref, comp, comp - ref, false))
        pan = get(φ_panel, φ, 0); pan == 0 && continue
        # use harmonic number as x (tone stems)
        keyr = (pan, "ref"); xs, ys = get!(series_data, keyr, (Float64[], Float64[]))
        push!(xs, Float64(H)); push!(ys, ref)
        keyc = (pan, "F1A"); xs2, ys2 = get!(series_data, keyc, (Float64[], Float64[]))
        push!(xs2, Float64(H)); push!(ys2, comp)
    end
    series = PlotSeries[]
    for ((pan, name), (xs, ys)) in sort(collect(series_data); by=first)
        kind = name == "ref" ? :reference_points : :computed
        push!(series, PlotSeries(name == "ref" ? "Fig.6 Exp peaks" : name, kind, xs, ys; panel=pan))
    end
    return ValidationCaseResult(
        "PER_FIG6", _today_iso(),
        (; csv=path, csv_ref=ref_csv, criterion="informational (23d covers H1–H2 levels / Δψ₁ only)",
         date="2026-10-21"),
        table, series, :no_verdict,
        "informational tones vs digitized peaks; replay of data/pereira/pereira_results.csv generated by scripts/run/run_pereira.jl (amplitude convention fixed 2026-10-21, post-hoc)",
        "X-EXTRAP (amplitude convention fixed 2026-10-21, post-hoc)",
        joinpath(_VAL_REPORT_DIR, "pereira_forward_flight.md"),
    )
end

function _bbn_csv_path()
    return _data_path("NASA_CR-158919", "bbn_results.csv")
end

"""BBN circumferential phase — 23a: coh ≥ 0.15, ≥80% within 15°/35° (recorded 26/168)."""
function _run_bbn_circ()
    path = _bbn_csv_path()
    hdr, rows = _read_csv_rows(path)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    table = ValidationTableRow[]
    n = 0; nok = 0
    # series: one panel per verdict pair; x=harmonic
    pair_panel = Dict("4-3" => 1, "5-3" => 2, "4-5" => 3)
    series_data = Dict{Tuple{Int,String},Tuple{Vector{Float64},Vector{Float64}}}()
    for r in rows
        length(r) < length(hdr) && continue
        r[col["kind"]] == "circ" || continue
        r[col["flagged"]] == "Y" && continue
        coh = parse(Float64, r[col["coherence"]])
        coh >= 0.15 || continue
        H = parse(Int, r[col["harmonic"]])
        meas = parse(Float64, r[col["measured"]])
        f1a = parse(Float64, r[col["f1a"]])
        # Frozen 23a residual: wrap(Δφ_meas − Δφ_F1A) to ±180° (CSV residual already this).
        resid = _wrap180(meas - f1a)
        within = r[col["within"]] == "Y"  # do not recompute / change within flags
        n += 1; nok += within
        pair = r[col["pair"]]
        push!(table, ValidationTableRow("$(r[col["tip"]]) $pair H$H",
                                        Float64(H), meas, f1a, resid, within, pair))
        pan = get(pair_panel, pair, 0)
        pan == 0 && continue
        # tipA run4 only on plot for readability
        (r[col["tip"]] == "tipA" && r[col["run"]] == "4") || continue
        keyr = (pan, "meas"); xs, ys = get!(series_data, keyr, (Float64[], Float64[]))
        push!(xs, Float64(H)); push!(ys, meas)
        keyc = (pan, "F1A"); xs2, ys2 = get!(series_data, keyc, (Float64[], Float64[]))
        push!(xs2, Float64(H)); push!(ys2, f1a)
    end
    series = PlotSeries[]
    for ((pan, name), (xs, ys)) in sort(collect(series_data); by=first)
        # Markers only — no lines across ±180° wraps.
        kind = name == "meas" ? :reference_points : :computed_points
        push!(series, PlotSeries(name == "meas" ? "measured" : "F1A", kind, xs, ys; panel=pan))
    end
    frac = n == 0 ? 0.0 : nok / n
    met = frac >= 0.80
    return ValidationCaseResult(
        "BBN_CIRC", _today_iso(),
        (; csv=path, criterion="23a: coh≥0.15 rows, ≥80% within 15°/35°", date="2026-10-21",
         n_ok=nok, n_tot=n),
        table, series, met ? :met : :not_met,
        "$nok/$n within tolerance ($(round(100*frac; digits=1))%; need ≥80%); replay of data/NASA_CR-158919/bbn_results.csv generated by scripts/run/run_bbn_phase.jl",
        "X-EXTRAP", joinpath(_VAL_REPORT_DIR, "bbn_phase.md"),
    )
end

"""BBN relative levels — 23b ±3 dB, label X-EXTRAP."""
function _run_bbn_levels()
    path = _bbn_csv_path()
    ref_csv = _data_path("NASA_CR-158919", "bbn_levels_table3.csv")
    hdr, rows = _read_csv_rows(path)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    table = ValidationTableRow[]
    n = 0; nok = 0
    # One series per tip × run (do not join tips/runs on one line).
    series_data = Dict{Tuple{String,Symbol},Tuple{Vector{Float64},Vector{Float64}}}()
    for r in rows
        length(r) < length(hdr) && continue
        r[col["kind"]] == "levels" || continue
        mic = parse(Float64, r[col["mic"]])
        meas = parse(Float64, r[col["measured"]])
        f1a = parse(Float64, r[col["f1a"]])
        resid = parse(Float64, r[col["residual"]])
        within = r[col["within"]] == "Y"
        n += 1; nok += within
        tip = r[col["tip"]]
        run = r[col["run"]]
        push!(table, ValidationTableRow("$tip run$run mic$(Int(mic))",
                                        mic, meas, f1a, resid, within, tip))
        tag = "$tip run$run"
        km = (tag * " meas", :reference_points)
        xs, ys = get!(series_data, km, (Float64[], Float64[]))
        push!(xs, mic); push!(ys, meas)
        kc = (tag, :computed)
        xs2, ys2 = get!(series_data, kc, (Float64[], Float64[]))
        push!(xs2, mic); push!(ys2, f1a)
    end
    series = PlotSeries[]
    for ((name, kind), (xs, ys)) in sort(collect(series_data); by=first)
        ord = sortperm(xs)
        push!(series, PlotSeries(name, kind, xs[ord], ys[ord]; panel=1))
    end
    return ValidationCaseResult(
        "BBN_LEVELS", _today_iso(),
        (; csv=path, csv_ref=ref_csv, criterion="23b ±3 dB on SPL_i − SPL_4", date="2026-10-21"),
        table, series, :no_verdict,  # reported X-EXTRAP — no pass claim
        "$nok/$n within ±3 dB (X-EXTRAP); replay of data/NASA_CR-158919/bbn_results.csv generated by scripts/run/run_bbn_phase.jl",
        "X-EXTRAP", joinpath(_VAL_REPORT_DIR, "bbn_phase.md"),
    )
end

"""BBN longitudinal phase — X-EXTRAP plot only."""
function _run_bbn_long()
    path = _bbn_csv_path()
    ref_csv = _data_path("NASA_CR-159124", "bbn_phase_vs_freq_fig19_longitudinal.csv")
    hdr, rows = _read_csv_rows(path)
    col = Dict(h => i for (i, h) in enumerate(hdr))
    table = ValidationTableRow[]
    # measured stored in rad (unwrapped along frequency in the generating script);
    # F1A is wrapped. For display, wrap both to ±180°.
    # Series are built per pair so Fig. 19 / Fig. 20 panels do not share one array.
    by_pair = Dict{String,Tuple{Vector{Float64},Vector{Float64},Vector{Float64}}}()
    for r in rows
        length(r) < length(hdr) && continue
        r[col["kind"]] == "long" || continue
        pair = r[col["pair"]]
        # frequency not in CSV — use harmonic as x proxy
        H = parse(Float64, r[col["harmonic"]])
        meas_rad = parse(Float64, r[col["measured"]])
        f1a_deg = _wrap180(parse(Float64, r[col["f1a"]]))
        meas_deg = _wrap180(meas_rad * 180 / π)
        resid = _wrap180(meas_deg - f1a_deg)
        push!(table, ValidationTableRow("$pair H=$(Int(H))", H, meas_deg, f1a_deg, resid, false, pair))
        xs, ym, yf = get!(by_pair, pair, (Float64[], Float64[], Float64[]))
        push!(xs, H); push!(ym, meas_deg); push!(yf, f1a_deg)
    end
    series = PlotSeries[]
    pairs = sort(collect(keys(by_pair)))
    for (pi, pair) in enumerate(pairs[1:min(end, 2)])
        xs, ym, yf = by_pair[pair]
        # Markers only — no connecting lines across ±180° wraps.
        push!(series, PlotSeries("measured $pair", :reference_points, xs, ym; panel=pi))
        push!(series, PlotSeries("F1A $pair", :computed_points, xs, yf; panel=pi))
    end
    isempty(series) && push!(series, PlotSeries("(no rows)", :computed_points, [0.0], [0.0]; panel=1))
    return ValidationCaseResult(
        "BBN_LONG", _today_iso(),
        (; csv=path, csv_ref=ref_csv, criterion="X-EXTRAP plot only (no pass rule)", date="2026-10-21"),
        table, series, :no_verdict,
        "X-EXTRAP; replay of data/NASA_CR-158919/bbn_results.csv generated by scripts/run/run_bbn_phase.jl",
        "X-EXTRAP", joinpath(_VAL_REPORT_DIR, "bbn_phase.md"),
    )
end

"""Read a numeric CSV allowing empty cells → NaN (E-21/E-22 nasa_pred gaps)."""
function _read_csv_numeric_nan(path::AbstractString)
    lines = String[]
    for raw in eachline(path)
        s = strip(raw)
        isempty(s) && continue
        startswith(s, '#') && continue
        push!(lines, s)
    end
    isempty(lines) && error("empty CSV: $path")
    headers = Symbol.(split(lines[1], ','))
    cols = Dict{Symbol,Vector{Float64}}(h => Float64[] for h in headers)
    for row in lines[2:end]
        vals = split(row, ',')
        for (i, h) in enumerate(headers)
            cell = i ≤ length(vals) ? strip(vals[i]) : ""
            push!(cols[h], isempty(cell) ? NaN : parse(Float64, cell))
        end
    end
    return cols
end

"""
Figs. E-21 / E-22 noise reduction (38a). Inputs as NASA p. E-30: Phase III trim η_T = 1.0,
η_r' ≤ 0.15. End-plate allowance not applied: 80–160 Hz reported but excluded from both counts
(V-ASSUMED). Counts only over bands **below** the crossover (38b rule). Criterion dated 2026-10-21.
"""
function _run_e21_e22_nr()
    e21 = _read_csv_numeric_nan(_data_path("cr3813", "e21_noise_reduction_range.csv"))
    e22 = _read_csv_numeric_nan(_data_path("cr3813", "e22_noise_reduction_ci.csv"))
    bands = Float64.(e21[:band_Hz])
    mean21 = Float64.(e21[:measured_mean_dB])
    lo21 = Float64.(e21[:low_dB])
    hi21 = Float64.(e21[:high_dB])
    nasa = Float64.(e21[:nasa_pred_dB])
    # E-22 95 % limits by band (match on band_Hz)
    b22 = Float64.(e22[:band_Hz])
    lo22 = Float64.(e22[:low_dB])
    hi22 = Float64.(e22[:high_dB])
    lo22_of = Dict(b22[i] => lo22[i] for i in eachindex(b22))
    hi22_of = Dict(b22[i] => hi22[i] for i in eachindex(b22))

    excluded = Set([80.0, 100.0, 125.0, 160.0])
    inp = noise_reduction_test_article_inputs(; η_lining=1.0)
    η_cap = 0.15
    spec = noise_reduction_spectrum(inp; bands, η_r_cap=η_cap)
    xover = spec.crossover.fc_Hz
    got = Float64[r.NR_dB for r in spec.rows]
    above = Bool[r.above_crossover for r in spec.rows]

    table = ValidationTableRow[]
    n_nasa_ok = 0
    n_nasa = 0
    n_e22_ok = 0
    n_e22 = 0
    n_range_ok = 0
    n_range = 0
    for i in eachindex(bands)
        fc = bands[i]
        g = got[i]
        # Always report the band
        if isfinite(nasa[i])
            d = g - nasa[i]
            ok_nasa = abs(d) ≤ 3.0
            push!(table, ValidationTableRow("vs NASA prediction", fc, nasa[i], g, d, ok_nasa,
                                           "vs NASA prediction"))
        end
        if haskey(lo22_of, fc) && isfinite(lo22_of[fc]) && isfinite(hi22_of[fc])
            inside = lo22_of[fc] ≤ g ≤ hi22_of[fc]
            mid = (lo22_of[fc] + hi22_of[fc]) / 2
            push!(table, ValidationTableRow("vs E-22 95 % limits", fc, mid, g, g - mid, inside,
                                           "vs E-22 95 % limits"))
        end
        # Counts: exclude 80–160 Hz; only bands below crossover; require NASA value for V-CODE
        in_count = !(fc in excluded) && !above[i]
        if in_count
            if isfinite(nasa[i])
                n_nasa += 1
                n_nasa_ok += abs(g - nasa[i]) ≤ 3.0
            end
            if haskey(lo22_of, fc) && isfinite(lo22_of[fc]) && isfinite(hi22_of[fc])
                n_e22 += 1
                n_e22_ok += lo22_of[fc] ≤ g ≤ hi22_of[fc]
            end
            if isfinite(lo21[i]) && isfinite(hi21[i]) && isfinite(mean21[i])
                n_range += 1
                n_range_ok += lo21[i] ≤ g ≤ hi21[i]
            end
        end
    end
    frac_nasa = n_nasa == 0 ? 0.0 : n_nasa_ok / n_nasa
    frac_e22 = n_e22 == 0 ? 0.0 : n_e22_ok / n_e22
    met = frac_nasa ≥ 0.75 && frac_e22 ≥ 0.75
    reason = "V-CODE $n_nasa_ok/$n_nasa (|Δ|≤3 dB vs NASA); V-EXP $n_e22_ok/$n_e22 (inside E-22 95%); " *
             "E-21 range (secondary) $n_range_ok/$n_range; crossover=$(round(xover; digits=1)) Hz; " *
             "excluded 80,100,125,160 Hz (end-plate V-ASSUMED); counts below crossover only"
    series = [
        PlotSeries("E-21 measured mean", :reference_points, bands, mean21; panel=1),
        PlotSeries("E-21 range", :reference_band, bands, mean21; ylow=lo21, yhigh=hi21, panel=1),
        PlotSeries("E-22 95 %", :reference_band, b22, (lo22 .+ hi22) ./ 2; ylow=lo22, yhigh=hi22, panel=1),
        PlotSeries("NASA prediction", :reference_points,
                   bands[isfinite.(nasa)], nasa[isfinite.(nasa)]; panel=1),
        PlotSeries("Eq.(18) NR", :computed, bands, got; panel=1),
    ]
    return ValidationCaseResult(
        "E21_E22_NR", _today_iso(),
        (; η_lining=1.0, η_r_cap=η_cap, crossover_Hz=xover, crossover_n_modes=spec.crossover.n_modes,
         n_nasa_ok, n_nasa, n_e22_ok, n_e22, n_range_ok, n_range,
         excluded_Hz=(80, 100, 125, 160),
         criterion="|Δ|≤3 dB vs NASA ≥75%; inside E-22 ≥75%; below crossover; 80–160 excluded",
         date="2026-10-21",
         csv_e21=_data_path("cr3813", "e21_noise_reduction_range.csv"),
         csv_e22=_data_path("cr3813", "e22_noise_reduction_ci.csv")),
        table, series, met ? :met : :not_met, reason,
        "V-CODE (vs NASA) / V-EXP held out (vs E-22); first run 2026-10-21",
        joinpath(_VAL_REPORT_DIR, "e21_e22_noise_reduction.md"),
    )
end

"""
T2 with printed Eqs. (19)–(23) (`broadband_model=:eq19`). Same Fig. E-9 targets and
±3.5 dB tolerance as T2 (criterion dated before this run; unchanged). Label: first run
of the printed model 2026-10-22. Also records full-band E-21/E-22 counts with Eq. (18)
below crossover and Eq. (19) at/above (38a thresholds; report only).
"""
function _run_t2_eq19()
    targets = _data_path("cr3813", "t2_third_octave_targets.csv")
    isfile(targets) || (targets = _data_path("cr3813", "t2_third_octave_targets_B.csv"))
    r = run_pain_pipeline(; source=:e11, n_harmonics=5, bpf_Hz=200.0, blocking=R2)
    # Recompute spectrum with printed HF model (pipeline default remains :surrogate)
    spec = interior_spl(r.inputs; bpf_Hz=200.0, n_harmonics=min(5, size(r.inputs.amplitudes, 3)),
                        broadband=true, broadband_model=:eq19)
    cols = _read_csv_numeric(targets)
    fcs = Float64[cols[:fc_Hz][i] for i in eachindex(cols[:fc_Hz])]
    mean_v = Float64[cols[:measured_mean_SPL_dB][i] for i in eachindex(cols[:fc_Hz])]
    tols = Float64[cols[:tol_dB][i] for i in eachindex(cols[:fc_Hz])]
    got = Float64[]
    table = ValidationTableRow[]
    n_ok = 0
    third = spec.third_octave_SPL_dB
    for i in eachindex(fcs)
        b = nearest_third_octave(fcs[i], collect(keys(third)))
        g = get(third, b, NaN)
        push!(got, g)
        ok = isfinite(g) && abs(g - mean_v[i]) ≤ tols[i]
        n_ok += ok
        push!(table, ValidationTableRow("1/3-oct fc=$(round(fcs[i]; digits=0))", fcs[i],
                                        mean_v[i], g, g - mean_v[i], ok))
    end
    all_ok = n_ok == length(fcs) && !isempty(fcs)

    # Full-band E-21/E-22 with Eq. 18 below crossover + Eq. 19 at/above (report only)
    e21 = _read_csv_numeric_nan(_data_path("cr3813", "e21_noise_reduction_range.csv"))
    e22 = _read_csv_numeric_nan(_data_path("cr3813", "e22_noise_reduction_ci.csv"))
    bands_nr = Float64.(e21[:band_Hz])
    nasa = Float64.(e21[:nasa_pred_dB])
    b22 = Float64.(e22[:band_Hz])
    lo22 = Float64.(e22[:low_dB])
    hi22 = Float64.(e22[:high_dB])
    lo22_of = Dict(b22[i] => lo22[i] for i in eachindex(b22))
    hi22_of = Dict(b22[i] => hi22[i] for i in eachindex(b22))
    excluded = Set([80.0, 100.0, 125.0, 160.0])
    inp_nr = noise_reduction_test_article_inputs(; η_lining=1.0)
    η_cap = 0.15
    spec_nr = noise_reduction_spectrum(inp_nr; bands=bands_nr, η_r_cap=η_cap, hf_model=:eq19)
    xover = spec_nr.crossover.fc_Hz
    n_nasa = n_nasa_ok = n_e22 = n_e22_ok = 0
    for i in eachindex(bands_nr)
        fc = bands_nr[i]
        g = spec_nr.rows[i].NR_dB
        fc in excluded && continue
        if isfinite(nasa[i])
            n_nasa += 1
            n_nasa_ok += abs(g - nasa[i]) ≤ 3.0
        end
        if haskey(lo22_of, fc) && isfinite(lo22_of[fc]) && isfinite(hi22_of[fc])
            n_e22 += 1
            n_e22_ok += lo22_of[fc] ≤ g ≤ hi22_of[fc]
        end
        push!(table, ValidationTableRow("E-21/E-22 NR fc=$(round(fc; digits=0))", fc,
                                        isfinite(nasa[i]) ? nasa[i] : NaN, g,
                                        isfinite(nasa[i]) ? g - nasa[i] : NaN,
                                        isfinite(nasa[i]) && abs(g - nasa[i]) ≤ 3.0,
                                        "full-band NR (Eq.18/<xover, Eq.19/≥xover)"))
    end
    frac_nasa = n_nasa == 0 ? 0.0 : n_nasa_ok / n_nasa
    frac_e22 = n_e22 == 0 ? 0.0 : n_e22_ok / n_e22
    e21_met = frac_nasa ≥ 0.75 && frac_e22 ≥ 0.75

    series = [
        PlotSeries("measured mean", :reference_points, fcs, mean_v; panel=1),
        PlotSeries("±tol", :reference_band, fcs, mean_v;
                   ylow=mean_v .- tols, yhigh=mean_v .+ tols, panel=1),
        PlotSeries("PAIN Eq.(19) 1/3-oct", :computed, fcs, got; panel=1),
    ]
    reason = "$n_ok/$(length(fcs)) PASS vs Fig. E-9 (±3.5 dB); " *
             "full-band E-21/E-22: V-CODE $n_nasa_ok/$n_nasa, V-EXP $n_e22_ok/$n_e22 " *
             "(crossover=$(round(xover; digits=1)) Hz; 80–160 excluded; Eq.18 below / Eq.19 at+above)"
    return ValidationCaseResult(
        "T2_EQ19", _today_iso(),
        (; source=:e11, bpf_Hz=200.0, bands="1.25–2 kHz (targets CSV)", broadband_model=:eq19,
         n_ok, n_bands=length(fcs),
         e21_n_nasa_ok=n_nasa_ok, e21_n_nasa=n_nasa, e21_n_e22_ok=n_e22_ok, e21_n_e22=n_e22,
         e21_fullband_met=e21_met, crossover_Hz=xover,
         csv=targets),
        table, series, all_ok ? :met : :not_met, reason,
        "V-EXP; printed Eq. (19)–(23), first run 2026-10-22; T2 criterion unchanged",
        joinpath(_VAL_REPORT_DIR, "phase38c_hf_broadband.md"),
    )
end

"""
E-18 tones with η_T = 1.0 and η_r′ ≤ 0.15 (38d). Same free-field / blocking / grid as 18b-r
(ANOPP Table 8, R1, GEXT off ℓ = 1), Phase III trim at η_lining = 1.0, production
`tone_model=:eq8`. Harmonics H1–H3 map to 1/3-octave bands 200, 400, 630 Hz (H3 at
3·BPF = 600 Hz falls in the 630 Hz band — NASA's E-18 H3 near 600 Hz). Criterion dated
2026-10-21: |computed − NASA E-18 prediction| ≤ 4 dB for each harmonic with a NASA value.
`:auto` and measured mean/low/high are secondary (V-EXP, held out).
"""
function _run_e18_tones()
    targets = _data_path("cr3813", "e18_interior_pred_eta1.csv")
    cols = _read_csv_numeric_nan(targets)
    bands_csv = Float64.(cols[:band_Hz])
    nasa_csv = Float64.(cols[:nasa_pred_dB])
    mean_csv = Float64.(cols[:measured_mean_dB])
    lo_csv = Float64.(cols[:low_dB])
    hi_csv = Float64.(cols[:high_dB])
    nasa_of = Dict(bands_csv[i] => nasa_csv[i] for i in eachindex(bands_csv))
    mean_of = Dict(bands_csv[i] => mean_csv[i] for i in eachindex(bands_csv))
    lo_of = Dict(bands_csv[i] => lo_csv[i] for i in eachindex(bands_csv))
    hi_of = Dict(bands_csv[i] => hi_csv[i] for i in eachindex(bands_csv))

    # H → CSV / ISO nominal 1/3-octave band (e18_interior_pred_eta1.csv):
    # H1 = BPF = 200 Hz → 200; H2 = 400 Hz → 400; H3 = 3·BPF = 600 Hz → 630
    # (NASA's H3 near 600 Hz sits in the 630 Hz band; nearest_third_octave(600) confirms).
    bpf = 200.0
    toc = third_octave_centers()
    @assert nearest_third_octave(600.0, toc) ≈ nearest_third_octave(630.0, toc)
    harm_bands = [(1, 200.0), (2, 400.0), (3, 630.0)]

    paths = default_e11_paths()
    p3 = phase3_trim(; η_lining=1.0)
    r = run_pain_pipeline(; source=:e11, e11_amp_csv=paths.anopp_spl, n_harmonics=3, bpf_Hz=bpf,
                          blocking=R1, sidewall_trim_stack=p3.sidewall, end_trim_stack=p3.ends,
                          mech=p3.mech)
    η_cap = 0.15
    # Production path (:eq8) with η_r_cap on the tone sum (interior_spl forwards to pair)
    spec = interior_spl(r.inputs; bpf_Hz=bpf, n_harmonics=3, broadband=false,
                        tone_model=:eq8, η_r_cap=η_cap)
    # Confirm the cap reaches the tone path (pressure differs unless every η_r' already ≤ cap)
    p0 = tone_mean_square_pressure(r.inputs, 1, 2π * bpf)
    p_cap = tone_mean_square_pressure(r.inputs, 1, 2π * bpf; η_r_cap=η_cap)
    cap_reaches_tone = (p_cap != p0) || all(st -> begin
        ωr = 2π * st.f_Hz
        ηr = structural_loss_total(st, ωr; a=r.inputs.fuse.a, L=r.inputs.fuse.L,
                                   m=r.inputs.m_wall, C=r.inputs.C_struc)
        η′ = structural_loss_with_trim(ηr, ωr, r.inputs.m_wall, trim_Cw(r.inputs.sidewall, ωr))
        η′ ≤ η_cap + 1e-15
    end, r.inputs.structural.modes)
    spec_auto = interior_spl(r.inputs; bpf_Hz=bpf, n_harmonics=3, broadband=false,
                             tone_model=:auto, η_r_cap=η_cap)

    tol = 4.0
    table = ValidationTableRow[]
    got = Float64[]
    nasa_vals = Float64[]
    bands_h = Float64[]
    n_ok = 0
    n_nasa = 0
    auto_vals = Float64[]
    for (H, band) in harm_bands
        g = spec.harmonic_SPL_dB[H]
        g_auto = spec_auto.harmonic_SPL_dB[H]
        push!(got, g)
        push!(auto_vals, g_auto)
        push!(bands_h, band)
        nasa = get(nasa_of, band, NaN)
        push!(nasa_vals, nasa)
        if isfinite(nasa)
            n_nasa += 1
            d = g - nasa
            ok = abs(d) ≤ tol
            n_ok += ok
            push!(table, ValidationTableRow("vs NASA E-18 H=$H band=$(round(band; digits=0))",
                                            band, nasa, g, d, ok, "vs NASA E-18 prediction"))
        end
        # Secondary: :auto (38b) — not part of the verdict
        push!(table, ValidationTableRow(":auto H=$H band=$(round(band; digits=0))",
                                        band, isfinite(nasa) ? nasa : NaN, g_auto,
                                        isfinite(nasa) ? g_auto - nasa : NaN, false,
                                        ":auto (secondary, not in verdict)"))
        # Secondary: measured mean/low/high where present (V-EXP, held out)
        m = get(mean_of, band, NaN)
        lo = get(lo_of, band, NaN)
        hi = get(hi_of, band, NaN)
        if isfinite(m)
            push!(table, ValidationTableRow("measured mean H=$H (V-EXP held out)",
                                            band, m, g, g - m, false,
                                            "V-EXP measured (held out)"))
        end
        if isfinite(lo) && isfinite(hi)
            mid = (lo + hi) / 2
            push!(table, ValidationTableRow("measured range H=$H (V-EXP held out)",
                                            band, mid, g, g - mid, lo ≤ g ≤ hi,
                                            "V-EXP measured range (held out)"))
        end
    end
    all_ok = n_ok == n_nasa && n_nasa > 0
    series = [
        PlotSeries("NASA E-18 pred", :reference_points, bands_h, nasa_vals; panel=1),
        PlotSeries("PAIN :eq8", :computed, bands_h, got; panel=1),
        PlotSeries("PAIN :auto (secondary)", :computed, bands_h, auto_vals; panel=1),
    ]
    reason = "$n_ok/$n_nasa within ±4 dB of NASA E-18 prediction (H1–H3 → 200/400/630 Hz); " *
             "η_T=1.0, η_r_cap=$η_cap reaches tone=$(cap_reaches_tone); " *
             ":auto secondary $(join(round.(auto_vals; digits=2), ", ")) dB"
    return ValidationCaseResult(
        "E18_TONES", _today_iso(),
        (; free_field="ANOPP Table 8 (GEXT)", blocking=:R1, η_T=1.0, η_r_cap=η_cap,
         tone_model=:eq8, bpf_Hz=bpf,
         harm_bands=(200.0, 400.0, 630.0),
         n_ok, n_nasa, cap_reaches_tone,
         auto_dB=auto_vals, eq8_dB=got,
         criterion="|Δ|≤4 dB vs NASA E-18 pred per harmonic", date="2026-10-21",
         csv=targets),
        table, series, all_ok ? :met : :not_met, reason,
        "V-CODE vs NASA E-18 prediction; V-EXP shown, held out; first run 2026-10-22",
        joinpath(_VAL_REPORT_DIR, "e18_tones_eta1.md"),
    )
end

"""
E-15 total structural loss factor η_r′ (with trim) vs measured targets (38e). Fig. E-15
caption: "MEASURED AND PREDICTED TOTAL STRUCTURAL LOSS FACTORS" with calculated curves at
trim loss 0.5 and 1.0 and an upper-limit line at 0.15 — that is η_r′ of Eq. (82), not bare
η_r. Inputs: Phase III trim η_T = 1.0, η_r_cap = 0.15 (E-18/E-21 setting, CR-3813 p. E-30).
V-EXP info only; no pass mark (as recorded in 16b). Verdict `:no_verdict`.
"""
function _run_e15_struct_loss()
    targets = _data_path("cr3813", "e15_structural_loss_targets.csv")
    cols = _read_csv_numeric(targets)
    fs = Float64.(cols[:f_Hz])
    meas = Float64.(cols[:eta_meas])
    tols = Float64.(cols[:tol_frac])
    a, L, θ0d = 0.508, test_article_length(), 56.6
    p3 = phase3_trim(; a=a, L=L, theta0_deg=θ0d, η_lining=1.0)
    sm = structural_modes_from_table_d1(; L=L, a=a, theta0_deg=θ0d, n_keep=32)
    ρ0, c0 = 1.225, 340.0
    Abar = 2π * a * L
    η_cap = 0.15  # E-18/E-21 upper limit on η_r′ (Fig. E-15 long-dashed line; p. E-30)
    ext = false
    # At each target frequency: nearest Table D-1 mode supplies the joint-acceptance shape;
    # structural_loss_total / structural_loss_with_trim evaluated at the target ω (continuous
    # curve vs frequency, matching Fig. E-15's calculated spectra).
    got = Float64[]
    table = ValidationTableRow[]
    for i in eachindex(fs)
        f = fs[i]
        ω = 2π * f
        # nearest mode by |f_r − f|; loss factors evaluated at the target frequency
        dists = [abs(m.f_Hz - f) for m in sm.modes]
        st = sm.modes[argmin(dists)]
        ηr = structural_loss_total(st, ω; a, L, m=p3.m_wall, C=3.0, ρ0, c0, Abar)
        Cw = trim_Cw(p3.sidewall, ω; allow_extrapolation=ext)
        ηrp = structural_loss_with_trim(ηr, ω, p3.m_wall, Cw; η_r_cap=η_cap)
        push!(got, ηrp)
        ratio = ηrp / meas[i]
        within = abs(ratio - 1) ≤ tols[i]   # info only; does not drive the verdict
        push!(table, ValidationTableRow("η_r′ f=$(round(f; digits=0))", f, meas[i], ηrp,
                                        ηrp - meas[i], within, "V-EXP η_r′ (info)"))
    end
    series = [
        PlotSeries("measured", :reference_points, fs, meas; panel=1),
        PlotSeries("η_r′ (η_T=1, cap 0.15)", :computed, fs, got; panel=1),
    ]
    n_within = count(r -> r.within_tolerance, table)
    reason = "V-EXP info: $n_within/$(length(fs)) within CSV tol_frac (no pass mark); " *
             "quantity = η_r′ (Eq. 82 with trim), not bare η_r; η_T=1.0, η_r_cap=$η_cap (E-18/E-21)"
    return ValidationCaseResult(
        "E15_STRUCT_LOSS", _today_iso(),
        (; η_T=1.0, η_r_cap=η_cap, quantity="η_r′ (Eq. 82 with Phase III trim)",
         figure="CR-3813 Fig. E-15 (total structural loss factor; trim curves + 0.15 upper limit)",
         n_within, n_bands=length(fs),
         criterion="none (V-EXP info; 16b)", date="2026-10-21", csv=targets),
        table, series, :no_verdict, reason,
        "V-EXP; Fig. E-15 η_r′ with η_T=1.0 and η_r_cap=0.15; no pass mark; first run 2026-10-22",
        joinpath(_VAL_REPORT_DIR, "e15_structural_loss.md"),
    )
end

"""
UT_GRID — 160-point fuselage-skin grid vs User Manual Fig. 3 formulas, with a γ-coloured figure.
Verdict :met if every compared coordinate / azimuth agrees to 1e-9. Label: Unit test with visualization.
Existing Pkg.test suites \"Grid geometry\" / \"Grid azimuth\" remain.
"""
function _run_ut_grid()
    # Same geometry family as the e11 cabin path (App. E / Manual §5.2 numbers used elsewhere).
    L = test_article_length()
    a = 0.508
    fuse = FuselageGeometry(L, a, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.90)  # r_p [m], φ_p [deg], z_p [m]
    spec = GridSpec()
    pts = grid_points(fuse, prop, spec)
    rp, zp, phi_p = prop.r_p, prop.z_p, deg2rad(prop.phi_p_deg)
    kp = spec.k_p
    # Handful of (k, ℓ) stations spanning axial and azimuth indices.
    sample = [(1, 1), (8, 1), (8, 5), (16, 1), (16, 10), (4, 3), (12, 7)]
    table = ValidationTableRow[]
    n_ok = 0
    n_tot = 0
    tol = 1e-9
    for (k, ell) in sample
        p = first(q for q in pts if q.k == k && q.ell == ell)
        alpha = (ell - 1) * π / 18
        x1_ref = (rp - a) + a * (1 - cos(alpha))
        x2_ref = -a * sin(alpha)   # rotation_direction = +1 (Manual Fig. 3)
        x3_ref = (π * a / 18) * (kp - k)
        theta_ref = rad2deg(phi_p + alpha)
        for (qty, ref, got, xplot) in (
            ("x1 k=$k ℓ=$ell", x1_ref, p.x1, Float64(k)),
            ("x2 k=$k ℓ=$ell", x2_ref, p.x2, Float64(k)),
            ("x3 k=$k ℓ=$ell", x3_ref, p.x3, Float64(k)),
            ("theta_deg k=$k ℓ=$ell", theta_ref, p.theta_deg, Float64(ell)),
        )
            ok = abs(got - ref) ≤ tol
            n_tot += 1
            n_ok += ok
            push!(table, ValidationTableRow(qty, xplot, ref, got, got - ref, ok))
        end
    end
    # Unrolled cylinder: axial z vs azimuth α from ℓ = 1; colour = incidence γ.
    xs = Float64[p.z for p in pts]
    ys = Float64[p.alpha_deg for p in pts]
    γs = Float64[incidence_angle_deg(fuse, prop, p.theta_deg, p.z) for p in pts]
    z_plane = zp
    # Propeller plane (vertical line at z = z_p) and ℓ = 1 (α = 0 horizontal).
    α_span = Float64[0.0, 90.0]
    z_span = Float64[minimum(xs), maximum(xs)]
    series = [
        PlotSeries("γ (deg)", :colored_scatter, xs, ys; ylow=γs, panel=1),
        PlotSeries("propeller plane z=z_p", :reference_curve,
                   fill(z_plane, 2), α_span; panel=1),
        PlotSeries("ℓ = 1 (α = 0)", :reference_curve, z_span, [0.0, 0.0]; panel=1),
    ]
    all_ok = n_ok == n_tot && n_tot > 0
    return ValidationCaseResult(
        "UT_GRID", _today_iso(),
        (; L_m=L, a_m=a, theta0_deg=56.6, r_p=rp, phi_p_deg=prop.phi_p_deg, z_p=zp,
         k_max=spec.k_max, ell_max=spec.ell_max, k_p=kp, n_points=length(pts),
         tol=tol, sample_points=length(sample),
         criterion="Manual Fig. 3 x1,x2,x3,θ at sample points within 1e-9"),
        table, series, all_ok ? :met : :not_met,
        all_ok ? "$n_ok/$n_tot Manual Fig. 3 coordinates within $tol" :
                 "$n_ok/$n_tot Manual Fig. 3 coordinates within $tol",
        "Unit test with visualization",
        joinpath(_VAL_REPORT_DIR, "ut_grid.md"),
    )
end

"""31e UNC_COVER: parametric test-article Monte Carlo P5–P95 vs measured E-16 means."""
function _run_unc_cover()
    means = e16_measured_means()
    bands = Float64[200.0, 400.0, 630.0]
    budget = uncertainty_budget(:testarticle; trimmed=true)
    cache = build_testarticle_cache()
    oat = oat_sweep(cache, budget)
    kept = [r.name for r in oat if r.keep]
    mc = monte_carlo_band(cache, budget, kept; N=UNC_MC_N, seed=UNC_MC_SEED, family=:uniform)
    cov = coverage_check(mc; measured_means=means)
    table = ValidationTableRow[]
    for row in cov.rows
        push!(table, ValidationTableRow(
            "H$(row.H) measured mean inside P5–P95", bands[row.H], row.measured,
            row.P50, row.measured - row.P50, row.inside))
    end
    p5 = Float64[mc.harm[H].P5 for H in 1:3]
    p50 = Float64[mc.harm[H].P50 for H in 1:3]
    p95 = Float64[mc.harm[H].P95 for H in 1:3]
    series = [
        PlotSeries("measured E-16 mean", :reference_points, bands, means[1:3]; panel=1),
        PlotSeries("MC P5–P95", :reference_band, bands, p50; ylow=p5, yhigh=p95, panel=1),
        PlotSeries("MC P50", :computed, bands, p50; panel=1),
    ]
    return ValidationCaseResult(
        "UNC_COVER", _today_iso(),
        (; source=:e11, cabin_blocks=:parametric, N=UNC_MC_N, seed=UNC_MC_SEED,
         family=:uniform, kept=join(kept, ","), criterion_date="2026-10-22"),
        table, series, cov.verdict,
        "31e coverage $(cov.verdict); margins dB: " *
            join(["H$(r.H)=$(round(r.margin_dB; digits=2))" for r in cov.rows], ", "),
        "V-EXP vs measured E-16 means; first run 2026-10-22; pre-registered",
        joinpath(_VAL_REPORT_DIR, "uncertainty_budget_testarticle.md"),
    )
end

function _finish_validation_registry!()
    empty!(VALIDATION_CASES)
    empty!(VALIDATION_CASE_ORDER)
    cases = _make_registry()  # core cases CYL2D…REPRO
    # Runnable extras (not greyed)
    extras = [
        ValidationCase("UT_GRID", "Skin grid vs User Manual Fig. 3 (with figure)", "12", String[],
            FigureRef("PAIN User Manual", "Fig. 3", nothing),
            "Computed x1, x2, x3 and θ at sample (k, ℓ) points match User Manual Fig. 3 formulas within 1e-9; figure colours the 160 points by incidence angle γ.",
            "2026-10-22", "Unit test with visualization", _run_ut_grid,
            PlotSpec(; xlabel="axial position z (m)", ylabel="azimuth from ℓ = 1, α (deg)",
                     panel_titles=["160-point skin grid (unrolled)"],
                     error_mode=:absolute, error_tol=1e-9, error_ylabel="computed − Manual Fig. 3",
                     error_xlabel="sample index (table row)"), ""),
        ValidationCase("E12_BLOCK", "Fig. E-12 blocked sound-pressure level on the skin", "14",
            [_data_path("cr3813", "e12", "e12_predicted_A.csv")],
            FigureRef("CR-3813", "Fig. E-12", 136),
            "Blocking revision R1 of Eq. (43) applied to ANOPP Table 8 free-field levels, compared with digitized NASA predicted Fig. E-12; |Δ| ≤ digitization scatter δ_pred + 0.5 = 3.41 dB (phase 14a).",
            "2026-10-20", "V-CODE", _run_e12_block,
            PlotSpec(; xlabel="X3/D", ylabel="blocked SPL (dB)", panel_titles=["H1", "H2", "H3"],
                     error_tol=3.41), ""),
        ValidationCase("E11_FREEFIELD", "Fig. E-11 free-field sound-pressure level line", "12",
            [_data_path("cr3813", "e11_freefield_measured_A.csv"), _data_path("cr3813", "e11_freefield_measured_B.csv")],
            FigureRef("CR-3813", "Fig. E-11", 135),
            "Two independent digitizations of Fig. E-11 must agree within digitization scatter δ_dig ≤ 1.0 dB (repeatability of reading only).",
            "2026-10-20", "V-ASSUMED", _run_e11_freefield,
            PlotSpec(; xlabel="X3/D", ylabel="free-field SPL (dB)", panel_titles=["H1", "H2", "H3"],
                     error_tol=1.0), ""),
        ValidationCase("E14_LOSS", "Fig. E-14 band-average acoustic loss factor", "16",
            [_data_path("cr3813", "e14_acoustic_loss_calculated.csv")],
            FigureRef("CR-3813", "Fig. E-14", 139),
            "Eq. (78) band-average loss factor η̄ within ±25 % of NASA's calculated curves on Fig. E-14.",
            "2026-10-20", "V-CODE", _run_e14_loss,
            PlotSpec(; xlabel="band (Hz)", ylabel="loss factor", xscale=:log10, yscale=:log10,
                     xlim=(10.0, 10000.0), ylim=(0.001, 1.0), panel_titles=["η"],
                     error_mode=:relative_pct, error_tol=25.0), ""),
        ValidationCase("GEXT_BOUND", "Grid-extension (GEXT) importance bound on tonal interior check T1", "32", String[],
            FigureRef("—", "derived (no figure)", nothing),
            "Diagnostic only: shows how far the tonal interior check T1 moves when assumed grid-extension (GEXT) falloff/delay variants change; no pass criterion (phase 32) (amplitude convention fixed 2026-10-21, post-hoc).",
            "2026-10-21", "V-ASSUMED (amplitude convention fixed 2026-10-21, post-hoc)", _run_gext_bound,
            PlotSpec(; xlabel="variant", ylabel="T1 residual (dB)", panel_titles=["H1", "H2", "H3"],
                     error_tol=4.0), ""),
        ValidationCase("BBN_KIN", "BBN kinematic phase difference on a hub ring (24b)", "24", String[],
            FigureRef("—", "V-UNIT", nothing),
            "Absolute phase difference |Δφ − m·B·Δψ| ≤ 0.5° on a hub ring (frozen rule 23a′); reverse rotation flips the sign.",
            "2026-10-21", "V-UNIT", _run_bbn_kin,
            PlotSpec(; xlabel="harmonic", ylabel="Δφ (deg)", panel_titles=["pair1", "pair2", "pair3"],
                     error_tol=0.5, error_ylabel="deg"), ""),
        ValidationCase("R996_PHASE", "Report 996 page-12 phase difference", "27",
            [_data_path("report996", "tr996_phase_values.csv"),
             _data_path("report996", "f1a_results.csv")],
            FigureRef("NACA Report 996", "p. 12 text", 12),
            "F1A phase difference vs the one measured value 155° on Report 996 p. 12; within ±15° (23c). Recorded FAIL.",
            "2026-10-21", "X-EXTRAP", _run_r996_phase,
            PlotSpec(; xlabel="case", ylabel="phase difference (deg)", panel_titles=["page 12"],
                     error_tol=15.0, error_ylabel="deg"), ""),
        ValidationCase("BLK_P68", "Blocking Eq. (43) vs printed CR-172428 p.68 values", "14", String[],
            FigureRef("NASA-CR-172428", "p. 68 / Eq. (43)", 68),
            "Blocking revision R1 sound-level increase ΔL = 20 log10 F(γ) within 0.06 dB of the CR-172428 p.68 printed checkpoints at γ = 0–90°.",
            "2026-10-19", "V-UNIT", _run_blk_p68,
            PlotSpec(; xlabel="γ (deg)", ylabel="ΔL (dB)", panel_titles=["blocking"],
                     error_mode=:absolute, error_tol=0.06, error_ylabel="dB"), ""),
        ValidationCase("MRP_RITZ", "Raw structural Ritz solver vs Table D-1 (calibrated)", "15", String[],
            FigureRef("CR-3813", "Table D-1", 113),
            "Fit quality only (k_scale, edge_factor, floor_scale fitted to Table D-1); no pass mark.",
            "2026-10-21", "calibrated (k_scale, edge_factor, floor_scale fitted to Table D-1)",
            _run_mrp_ritz,
            PlotSpec(; xlabel="mode number", ylabel="frequency (Hz)", panel_titles=["Ritz vs D-1"],
                     error_mode=:relative_pct, error_tol=5.0), ""),
        ValidationCase("MRP_APPD", "Printed App. D structural solver vs Table D-1", "38g", String[],
            FigureRef("CR-3813", "Table D-1 / Fig. D-2", 113),
            "≥ 75 % of 32 modes within 5 % (count rule fixed 2026-10-22); no calibration; Fig. D-2 reported without pass mark.",
            "2026-10-22",
            "V-CODE (vs NASA's solver outputs), first run of the printed App. D formulation 2026-10-22",
            _run_mrp_appd,
            PlotSpec(; xlabel="mode number", ylabel="frequency (Hz)", panel_titles=["App. D vs D-1"],
                     error_mode=:relative_pct, error_tol=5.0), ""),
        ValidationCase("F1A_GUTIN", "Farassat F1A vs Gutin far-field first harmonic", "27", String[],
            FigureRef("Gutin / Hubbard", "far-field closed form", nothing),
            "|SPL_F1A − SPL_Gutin| ≤ 1 dB at first harmonic H1, static, thickness off, 100 tip radii in the rotor plane (Pkg.test I-01 c).",
            "2026-10-21", "V-CODE (cross-implementation)", _run_f1a_gutin,
            PlotSpec(; xlabel="harmonic", ylabel="SPL (dB)", panel_titles=["H1"],
                     error_mode=:absolute, error_tol=1.0, error_ylabel="dB"), ""),
        ValidationCase("R996_FIG14", "Report 996 Fig. 14(a) harmonic amplitude vs tip Mach (replay)", "27",
            [_data_path("report996", "f1a_results.csv")],
            FigureRef("NACA Report 996", "Fig. 14(a)", 16),
            "With loads scaled to measured thrust and torque: |20 log10(A_rms/measured)| ≤ 2 dB at ≥ 75 % of points (23c). (amplitude convention fixed 2026-10-21, post-hoc)",
            "2026-10-21", "V-EXP, calibrated loads (replay of recorded run; amplitude convention fixed 2026-10-21, post-hoc)", _run_r996_fig14,
            PlotSpec(; xlabel="M_t", ylabel="dyne/cm²", yscale=:log10, panel_titles=["Fig. 14(a)"],
                     error_mode=:db_ratio, error_tol=2.0), ""),
        ValidationCase("R996_FIG12", "Report 996 Fig. 12(a)(b) harmonic amplitude vs x/D (replay)", "27",
            [_data_path("report996", "f1a_results.csv")],
            FigureRef("NACA Report 996", "Fig. 12", 13),
            "With loads scaled to measured thrust and torque: |20 log10(A_rms/measured)| ≤ 2 dB at ≥ 75 % of points (23c). (amplitude convention fixed 2026-10-21, post-hoc)",
            "2026-10-21", "V-EXP, calibrated loads (replay of recorded run; amplitude convention fixed 2026-10-21, post-hoc)", _run_r996_fig12,
            PlotSpec(; xlabel="x/D", ylabel="dyne/cm²", panel_titles=["Fig. 12(a)(b)"],
                     error_mode=:db_ratio, error_tol=2.0), ""),
        ValidationCase("R996_FIG13A", "Report 996 Fig. 13(a) first harmonic vs x/D (replay)", "27",
            [_data_path("report996", "f1a_results.csv")],
            FigureRef("NACA Report 996", "Fig. 13(a)", 15),
            "With loads scaled to RM L51C27 thrust and torque: |20 log10(A_rms/measured)| ≤ 2 dB at ≥ 75 % of points (23c). (amplitude convention fixed 2026-10-21, post-hoc)",
            "2026-10-21", "V-EXP, calibrated loads (replay of recorded run; amplitude convention fixed 2026-10-21, post-hoc)", _run_r996_fig13a,
            PlotSpec(; xlabel="x/D", ylabel="dyne/cm²", panel_titles=["Fig. 13(a)"],
                     error_mode=:db_ratio, error_tol=2.0), ""),
        ValidationCase("R996_LOADS", "Report 996 CCBlade thrust and torque coefficients (replay)", "26",
            [_data_path("report996", "scale_factors.csv")],
            FigureRef("RM L8H25a / Report 996", "Figs. 10, 11 / scale_factors", nothing),
            "|C_T, C_P (CCBlade/measured) − 1| ≤ 0.15 (23c).",
            "2026-10-21", "post-hoc (criteria registered after the loads were computed)",
            _run_r996_loads,
            PlotSpec(; xlabel="M_t", ylabel="C_T / C_P", panel_titles=["C_T", "C_P"],
                     error_mode=:relative_pct, error_tol=15.0), ""),
        ValidationCase("R996_FIG6", "Report 996 Fig. 6 total rms vs x/D, four blades (replay)", "27",
            [_data_path("report996", "f1a_results.csv"),
             _data_path("report996", "tr996_fig6_tip_clearance_pressure_vs_xD.csv")],
            FigureRef("NACA Report 996", "Fig. 6", 11),
            "Informational (no measured thrust/torque for B = 4 blades); shape and tip-clearance ratios only (§2.3.1).",
            "2026-10-21", "X-EXTRAP", _run_r996_fig6,
            PlotSpec(; xlabel="x/D", ylabel="total rms (dyne/cm²)",
                     panel_titles=["d/D=0.042", "d/D=0.083", "d/D=0.167", "d/D=0.333"],
                     error_mode=:none), ""),
        ValidationCase("R996_FIG7", "Report 996 Fig. 7 blade-loading trend p_c/C_P (replay)", "27",
            [_data_path("report996", "f1a_results.csv"),
             _data_path("report996", "tr996_fig7_blade_loading_pc_over_CP_vs_xD.csv")],
            FigureRef("NACA Report 996", "Fig. 7", 11),
            "Informational shape only (the acoustics script does not apply the frozen 23c pressure rule to Fig. 7).",
            "2026-10-21", "X-EXTRAP", _run_r996_fig7,
            PlotSpec(; xlabel="x/D", ylabel="p_c/C_P", panel_titles=["β₇₅=15°"],
                     error_mode=:none), ""),
        ValidationCase("PER_LOADS", "Pereira Table 3 forward-flight thrust and torque (replay)", "28",
            [_data_path("pereira", "pereira_results.csv"),
             _data_path("pereira", "pereira_tables3_4.csv")],
            FigureRef("Pereira et al. (2026)", "Table 3", 5),
            "Informational (frozen Pereira criterion 23d has no thrust/torque tolerance).",
            "2026-10-21", "X-EXTRAP", _run_per_loads,
            PlotSpec(; xlabel="case index", ylabel="T / Q", panel_titles=["T (N)", "Q (N·m)"],
                     error_mode=:none), ""),
        ValidationCase("PER_FIG9", "Pereira Fig. 9 forward-flight harmonics at 1 m (replay)", "28",
            [_data_path("pereira", "pereira_results.csv"),
             _data_path("pereira", "pereira_fig9_harmonics.csv")],
            FigureRef("Pereira et al. (2026)", "Fig. 9", 10),
            "Frozen 23d: first harmonic H1 within ±1.7 dB, second harmonic H2 within ±3 dB; excluded cells excluded. (amplitude convention fixed 2026-10-21, post-hoc)",
            "2026-10-21", "X-EXTRAP (amplitude convention fixed 2026-10-21, post-hoc)", _run_per_fig9,
            PlotSpec(; xlabel="BPF harmonic", ylabel="SPL (dB)",
                     panel_titles=["φ=0°", "φ=20°", "φ=40°"],
                     error_mode=:absolute, error_tol=1.7, error_ylabel="dB"), ""),
        ValidationCase("PER_FIG8", "Pereira Fig. 8 forward-flight directivity at 1 m (replay)", "28",
            [_data_path("pereira", "pereira_results.csv"),
             _data_path("pereira", "pereira_fig8_directivity.csv")],
            FigureRef("Pereira et al. (2026)", "Fig. 8", 9),
            "Frozen 23d: H1 within ±1.7 dB, H2 within ±3 dB; H3 and higher informational; excluded cells excluded. (amplitude convention fixed 2026-10-21, post-hoc)",
            "2026-10-21", "X-EXTRAP (amplitude convention fixed 2026-10-21, post-hoc)", _run_per_fig8,
            PlotSpec(; xlabel="φ (deg)", ylabel="SPL (dB)",
                     panel_titles=["H1", "H2", "H3", "H4", "H5", "H6"],
                     error_mode=:absolute, error_tol=1.7, error_ylabel="dB"), ""),
        ValidationCase("PER_FIG7", "Pereira Fig. 7 first-harmonic phase shift Δψ₁ (replay)", "28",
            [_data_path("pereira", "pereira_results.csv"),
             _data_path("pereira", "pereira_fig7_harmonics.csv")],
            FigureRef("Pereira et al. (2026)", "Fig. 7", 8),
            "Frozen 23d: first-harmonic phase shift ψ₁(φ) − ψ₁(0°) within ±5°.",
            "2026-10-21", "X-EXTRAP", _run_per_fig7,
            PlotSpec(; xlabel="φ (deg)", ylabel="Δψ₁ (deg)", panel_titles=["Δψ₁"],
                     error_mode=:absolute, error_tol=5.0, error_ylabel="deg"), ""),
        ValidationCase("PER_FIG6", "Pereira Fig. 6 forward-flight spectra (replay)", "28",
            [_data_path("pereira", "pereira_results.csv"),
             _data_path("pereira", "pereira_fig6_peaks.csv")],
            FigureRef("Pereira et al. (2026)", "Fig. 6", 7),
            "Informational tones vs digitized peaks (frozen 23d does not cover Fig. 6). (amplitude convention fixed 2026-10-21, post-hoc)",
            "2026-10-21", "X-EXTRAP (amplitude convention fixed 2026-10-21, post-hoc)", _run_per_fig6,
            PlotSpec(; xlabel="BPF harmonic", ylabel="SPL (dB)",
                     panel_titles=["φ=0°", "φ=20°", "φ=40°"],
                     error_mode=:none), ""),
        ValidationCase("BBN_CIRC", "BBN circumferential phase between fuselage microphones (replay)", "24",
            [_data_path("NASA_CR-158919", "bbn_results.csv")],
            FigureRef("CR-158919 / CR-159124", "App. C/D", 86),
            "Frozen 23a: among rows with coherence ≥ 0.15, ≥ 80 % within 15° or 35° (pair-dependent).",
            "2026-10-21",
            "X-EXTRAP; post-hoc: pair convention from CR-158919 §3.4/Table 8 found 2026-10-22 after the pre-registered 23a FAIL 26/168 (on record)",
            _run_bbn_circ,
            PlotSpec(; xlabel="harmonic", ylabel="phase (deg)",
                     panel_titles=["pair 4-3", "pair 5-3", "pair 4-5"],
                     error_mode=:absolute, error_tol=15.0, error_ylabel="deg"), ""),
        ValidationCase("BBN_LEVELS", "BBN relative in-plane levels vs microphone 4 (replay)", "24",
            [_data_path("NASA_CR-158919", "bbn_results.csv"),
             _data_path("NASA_CR-158919", "bbn_levels_table3.csv")],
            FigureRef("CR-158919", "Tables 3, 4", nothing),
            "Frozen 23b: ±3 dB on relative level SPL_i − SPL_4; reported X-EXTRAP (assumed blade).",
            "2026-10-21", "X-EXTRAP", _run_bbn_levels,
            PlotSpec(; xlabel="microphone", ylabel="relative level (dB)", panel_titles=["levels"],
                     error_mode=:absolute, error_tol=3.0, error_ylabel="dB"), ""),
        ValidationCase("BBN_LONG", "BBN longitudinal (axial) phase (replay)", "24",
            [_data_path("NASA_CR-158919", "bbn_results.csv")],
            FigureRef("CR-159124", "Figs. 19, 20", 56),
            "X-EXTRAP plot only (no pass rule); blade chord/twist/airfoil not published.",
            "2026-10-21", "X-EXTRAP", _run_bbn_long,
            PlotSpec(; xlabel="harmonic", ylabel="phase (deg)",
                     panel_titles=["Fig. 19 (wrapped ±180°)", "Fig. 20 (wrapped ±180°)"],
                     error_mode=:none), ""),
    ]
    append!(cases, extras)

    # E21_E22_NR (38a), T2_EQ19 (38c), E18_TONES (38d), E15_STRUCT_LOSS (38e); no greyed placeholders.
    push!(cases, ValidationCase(
        "E21_E22_NR", "Figs. E-21 / E-22 cabin noise reduction", "38a",
        [_data_path("cr3813", "e21_noise_reduction_range.csv"),
         _data_path("cr3813", "e22_noise_reduction_ci.csv")],
        FigureRef("CR-3813", "Figs. E-21, E-22", 149),
        "38a (dated 2026-10-21): |noise reduction NR − NASA| ≤ 3 dB at ≥ 75 % of bands below crossover with a NASA value " *
        "(80–160 Hz excluded, V-ASSUMED end-plate); NR inside E-22 95 % confidence at ≥ 75 % of the same; both required for :met.",
        "2026-10-21",
        "V-CODE (vs NASA) / V-EXP held out (vs E-22); first run 2026-10-21",
        _run_e21_e22_nr,
        PlotSpec(; xlabel="band (Hz)", ylabel="NR (dB)", xscale=:log10, xlim=(63.0, 4000.0),
                 panel_titles=["E-21 / E-22"], error_mode=:absolute, error_tol=3.0, error_ylabel="dB vs NASA"),
        "",
    ))
    push!(cases, ValidationCase(
        "T2_EQ19", "1/3-octave vs Fig. E-9 (printed high-frequency Eqs. 19–23)", "38c",
        filter(isfile, [_data_path("cr3813", "t2_third_octave_targets.csv"),
                        _data_path("cr3813", "t2_third_octave_targets_B.csv")]),
        FigureRef("CR-3813", "Fig. E-9 / E-10", 132),
        "Same T2 criterion (±3.5 dB at 1.25, 1.6, 2 kHz vs Fig. E-9 measured mean); printed Eqs. (19)–(23); " *
        "no j²/τ/area scale. First run 2026-10-22.",
        "2026-10-20 (T2 criterion; Eq.19 path first run 2026-10-22)",
        "V-EXP; printed Eq. (19)–(23), first run 2026-10-22; T2 criterion unchanged",
        _run_t2_eq19,
        PlotSpec(; xlabel="1/3-octave band (Hz)", ylabel="SPL (dB)",
                 xscale=:log10, xlim=(1000.0, 2600.0),
                 panel_titles=["Fig. E-9 (Eq. 19)"],
                 error_mode=:absolute, error_tol=3.5),
        "",
    ))
    push!(cases, ValidationCase(
        "E18_TONES", "Fig. E-18 interior tones (trim loss η_T = 1.0, structural loss capped)", "38d",
        [_data_path("cr3813", "e18_interior_pred_eta1.csv")],
        FigureRef("CR-3813", "Fig. E-18", 145),
        "38d (dated 2026-10-21): |computed − NASA E-18 prediction| ≤ 4 dB per harmonic H1–H3 " *
        "(bands 200, 400, 630 Hz). Production tone_model=:eq8; η_r_cap=0.15 on the tone path.",
        "2026-10-21",
        "V-CODE vs NASA E-18 prediction; V-EXP shown, held out; first run 2026-10-22",
        _run_e18_tones,
        PlotSpec(; xlabel="band (Hz)", ylabel="interior SPL (dB)",
                 panel_titles=["Fig. E-18"], error_mode=:absolute, error_tol=4.0, error_ylabel="dB vs NASA"),
        "",
    ))
    push!(cases, ValidationCase(
        "E15_STRUCT_LOSS", "Fig. E-15 total structural loss factor η_r′", "38e",
        [_data_path("cr3813", "e15_structural_loss_targets.csv")],
        FigureRef("CR-3813", "Fig. E-15", 141),
        "38e: total structural loss factor η_r′ (Eq. 82 with Phase III trim loss η_T = 1.0 and η_r_cap = 0.15 = E-18/E-21 setting) " *
        "vs measured targets; experiment comparison reported as info only, no pass mark (as 16b).",
        "2026-10-21",
        "V-EXP; Fig. E-15 η_r′ with η_T=1.0 and η_r_cap=0.15; no pass mark; first run 2026-10-22",
        _run_e15_struct_loss,
        PlotSpec(; xlabel="frequency (Hz)", ylabel="structural loss factor",
                 xscale=:log10, yscale=:log10, xlim=(100.0, 5000.0), ylim=(0.001, 1.0),
                 panel_titles=["Fig. E-15"], error_mode=:relative_pct, error_tol=50.0),
        "",
    ))
    push!(cases, ValidationCase(
        "UNC_COVER", "Uncertainty coverage vs Fig. E-16 means (31e)", "31e",
        [_data_path("cr3813", "t1_interior_targets.csv")],
        FigureRef("CR-3813", "Fig. E-16", 142),
        "31e (pre-registered 2026-10-22): P5–P95 band of the primary-distribution Monte Carlo " *
        "(untuned parametric cabin, NASA free field, no tuned value, no E-16 envelope floor) " *
        "contains the measured E-16 mean at each of H1, H2, H3; :met only if all three.",
        "2026-10-22",
        "V-EXP vs measured E-16 means; first run 2026-10-22; pre-registered",
        _run_unc_cover,
        PlotSpec(; xlabel="1/3-octave band (Hz)", ylabel="SPL (dB)",
                 xscale=:log10, xlim=(160.0, 2000.0),
                 panel_titles=["Fig. E-16 P5–P95 band vs measured means"],
                 error_mode=:none),
        "",
    ))

    for c in cases
        VALIDATION_CASES[c.id] = c
    end
    # Map order for list/GUI; every registry id must appear in exactly one map block.
    order = [
        "E11_FREEFIELD", "UT_GRID", "GEXT_BOUND", "BLK_P68", "E12_BLOCK", "MRP_D1", "MRP_RITZ", "MRP_APPD",
        "CYL2D_C1", "E14_LOSS", "E15_STRUCT_LOSS", "REPRO_18b", "E18_TONES",
        "T1", "T2", "T2_EQ19", "E21_E22_NR", "UNC_COVER",
        "R996_LOADS", "PER_LOADS", "F1A_GUTIN", "R996_FIG14", "R996_FIG12", "R996_FIG13A",
        "R996_FIG6", "R996_FIG7", "BBN_KIN", "BBN_CIRC", "BBN_LONG", "R996_PHASE",
        "PER_FIG6", "PER_FIG7", "PER_FIG8", "PER_FIG9", "BBN_LEVELS",
    ]
    append!(VALIDATION_CASE_ORDER, order)
    return nothing
end

_finish_validation_registry!()
