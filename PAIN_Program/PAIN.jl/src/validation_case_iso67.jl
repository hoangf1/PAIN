# Phase 67 — test the attribution of the source-block experimental misses (polars; compact chord).
# Criteria fixed 2026-10-24 (IMPLEMENTATION_PLAN.md §8k) before any number was computed. Nothing here changes an
# input, a load or a criterion of an existing case.

const _P67_REPORT = "phase67_source_attribution.md"

function _p67_result(id, table, series, ok, reason, echo; verdict=nothing)
    v = verdict === nothing ? (ok ? :met : :not_met) : verdict
    return ValidationCaseResult(id, _today_iso(), merge((; date="2026-10-24"), echo), table, series,
        v, (v === :not_met ? "criterion not met — " : "") * reason, v === :no_verdict ? "diagnostic" : "V-EXP (input)",
        joinpath(_VAL_REPORT_DIR, _P67_REPORT))
end

"""TN 1546 test Reynolds number at Mach M: linear between the stated ends 0.85·10⁶ (M = 0.3) and 2·10⁶ (M = 0.8)
(TN 1546 p. 5; 5-in chord). Reading fixed 2026-10-24 before the comparison."""
_p67_tn1546_Re(M) = 0.85e6 + (2.0e6 - 0.85e6) * (M - 0.3) / 0.5

"""XFOIL c_l of `section` at (α_deg, M) and Reynolds `Re`: bilinear in (log Re, M) between the bracketing grid
tables (M interpolation added 2026-10-28, Phase 69: the Phase 69 grid is in 0.1 Mach steps); `nothing` when α is
outside a table or a table is missing (no extrapolation)."""
function _p67_xfoil_cl(tables, Res, section, α_deg, M, Re; Ms=sort!(unique(Float64[k[3] for k in keys(tables) if k[1] == section])))
    lo = maximum(filter(x -> x ≤ Re, Res); init=minimum(Res))
    hi = minimum(filter(x -> x ≥ Re, Res); init=maximum(Res))
    mlo = maximum(filter(x -> x ≤ M + 1e-9, Ms); init=minimum(Ms))
    mhi = minimum(filter(x -> x ≥ M - 1e-9, Ms); init=maximum(Ms))
    (mlo ≤ M + 1e-9 && mhi ≥ M - 1e-9) || return nothing
    cl(R, m) = _xfoil_cl_at_alpha(_polar_pts(tables, section, R, m), α_deg)
    v = [cl(R, m) for R in (lo, hi), m in (mlo, mhi)]
    any(isnothing, v) && return nothing
    t = lo == hi ? 0.0 : (log(Re) - log(lo)) / (log(hi) - log(lo))
    u = mlo == mhi ? 0.0 : (M - mlo) / (mhi - mlo)
    return (1 - t) * (1 - u) * v[1, 1] + t * (1 - u) * v[2, 1] + (1 - t) * u * v[1, 2] + t * u * v[2, 2]
end

# --- 67a POLAR_FIDELITY ----------------------------------------------------------------------
"""Sections whose TN 1546 points chose N_crit (Phase 69b, 2026-10-28): shown, but calibrated, so they carry no verdict."""
const _P69_NCRIT_FIT_SECTIONS = ("n16_506", "n16_509")

"""Equivalent angle-of-attack error (deg) of a lift offset Δc_l at Mach M: Δc_l over the Prandtl–Glauert section
lift slope 2π/√(1 − M²) per radian (Phase 77, display only; the slope is theory, not fitted to the data)."""
_p67_equiv_dalpha_deg(Δcl, M) = rad2deg(Δcl * sqrt(1 - M^2) / 2π)

function _run_polar_fidelity()
    tab = _polar_tables(_data_path(splitpath(_R996_POLAR_PATH)...))
    secs = ("n16_312", "n16_506", "n16_509")
    table = ValidationTableRow[]; series = PlotSeries[]; n_ok = 0; n = 0
    for (si, sec) in enumerate(secs)
        meas = [x for x in measured_polar_series(sec) if x.kind === :cl_cd_at_M]
        for x in meas
            M = x.Mach
            Re = _p67_tn1546_Re(M)
            αs = Float64[]; dcl = Float64[]
            for (α, clm) in zip(x.alpha_cl, x.cl)
                clx = _p67_xfoil_cl(tab.tables, tab.Res, sec, α, M, Re; Ms=tab.Ms)
                clx === nothing && continue
                d = clx - clm; ok = abs(d) ≤ 0.05
                calibrated = sec in _P69_NCRIT_FIT_SECTIONS
                calibrated || (n += 1; n_ok += ok)
                push!(table, ValidationTableRow("$sec M=$M α=$(round(α; digits=2))° c_l XFOIL − TN 1546" *
                                                (calibrated ? " (N_crit fit point, no verdict)" : ""), 10si + M, clm, clx, d, ok, sec))
                push!(αs, α); push!(dcl, d)
            end
            isempty(αs) && continue
            push!(series, PlotSeries("$sec M=$M", :computed, αs, dcl; panel=si))
            # Phase 77 (display only): the same offset as an equivalent angle of attack, panels 4–6
            push!(series, PlotSeries("$sec M=$M", :computed, αs, _p67_equiv_dalpha_deg.(dcl, M); panel=3 + si))
        end
    end
    frac = n == 0 ? 0.0 : n_ok / n
    return _p67_result("POLAR_FIDELITY", table, series, n > 0 && frac ≥ 0.75,
        "held-out 16-312: $n_ok/$n matched points with |Δc_l| ≤ 0.05 ($(round(100frac; digits=1)) %; criterion ≥ 75 %); " *
        "16-506 and 16-509 chose N_crit (Phase 69b) and are shown without verdict; XFOIL at the TN 1546 Reynolds number",
        (; criterion="|Δc_l| ≤ 0.05 at ≥ 75 % of matched points (held-out 16-312; Phase 69b 2026-10-28)", n, n_ok,
         equivalent_angle="display only (Phase 77): Δα = Δc_l/(2π/√(1−M²)); the 0.05 criterion is 0.42° at M 0.4 and " *
                          "0.32° at M 0.72; no percentage is shown because 13 of the matched c_l lie within ±0.2 of zero lift",
         polar=basename(_R996_POLAR_PATH)))
end

# --- 67b F1A_CHORDWISE -----------------------------------------------------------------------
"""Independent F1A (the F1A_INDEP kinematics) with each section's steady load spread over `nc` chordwise points
along the chord line at pitch θ (leading edge forward and in the rotation direction), weights ∝ √((1−ξ)/ξ) at
ξ_j = (j − ½)/nc; `nc = 1` puts the load at the quarter chord on the pitch axis (the compact source)."""
function _p67_f1a_chordwise(r, chord, θ, Np, Tp, Δr, B, Ω, c0, observers; nc::Int=8, n_harmonics::Int=3,
                            num_src_times::Int=64, n_rev_src::Int=2)
    ξ = nc == 1 ? [0.25] : [(j - 0.5) / nc for j in 1:nc]
    w = nc == 1 ? [1.0] : (v = sqrt.((1 .- ξ) ./ ξ); v ./ sum(v))
    nsec = length(r)
    bpp = 2π / Ω / B
    period_src = n_rev_src * (2π / Ω)
    bpf = B * Ω / (2π)
    amp = zeros(length(observers), n_harmonics); ph = zeros(length(observers), n_harmonics)
    # chordwise offset of point j from the pitch axis (quarter chord): (0.25 − ξ)·c along ĉ = sinθ x̂ + cosθ t̂
    offs = [[((0.25 - ξ[j]) * chord[i]) .* (sin(θ[i]), cos(θ[i])) for j in eachindex(ξ)] for i in 1:nsec]
    function geom(i, j, ψ)
        xo, to = offs[i][j]
        cψ, sψ = cos(ψ), sin(ψ)
        y = (xo, r[i] * cψ - to * sψ, r[i] * sψ + to * cψ)
        return y, (0.0, -Ω * y[3], Ω * y[2]), (0.0, -Ω^2 * y[2], -Ω^2 * y[3])
    end
    for (io, obs) in enumerate(observers)
        t0 = 0.0
        for τ in (0.0, period_src), b in 0:B-1, i in 1:nsec, j in eachindex(ξ)
            y, _, _ = geom(i, j, Ω * τ + 2π * b / B)
            t0 = max(t0, τ + hypot(obs.x[1] - y[1], obs.x[2] - y[2], obs.x[3] - y[3]) / c0)
        end
        t_rec = t0 .+ (0:num_src_times-1) .* (bpp / num_src_times)
        p = zeros(num_src_times)
        for (jt, t_obs) in enumerate(t_rec)
            s = 0.0
            for b in 0:B-1, i in 1:nsec, j in eachindex(ξ)
                y, _, _ = geom(i, j, 0.0)
                τ = t_obs - hypot(obs.x[1] - y[1], obs.x[2] - y[2], obs.x[3] - y[3]) / c0
                for _ in 1:30
                    y, _, _ = geom(i, j, Ω * τ + 2π * b / B)
                    τn = t_obs - hypot(obs.x[1] - y[1], obs.x[2] - y[2], obs.x[3] - y[3]) / c0
                    abs(τn - τ) < 1e-14 && (τ = τn; break)
                    τ = τn
                end
                ψ = Ω * τ + 2π * b / B
                y, yd, ydd = geom(i, j, ψ)
                cψ, sψ = cos(ψ), sin(ψ)
                f = w[j] .* (-Np[i], -Tp[i] * sψ, Tp[i] * cψ)
                fd = w[j] .* (0.0, -Tp[i] * Ω * cψ, -Tp[i] * Ω * sψ)
                s += _iso41_f1a_loading_p(obs.x, y, yd, ydd, f, fd, c0) * Δr[i]
            end
            p[jt] = s
        end
        p .-= sum(p) / length(p)
        P = FFTW.rfft(p)
        nn = length(p)
        df = 1 / (nn * bpp / num_src_times)
        for H in 1:n_harmonics
            c = P[clamp(round(Int, H * bpf / df) + 1, 1, length(P))]
            amp[io, H] = 2 * abs(c) / nn
            ph[io, H] = _wrap_phase(angle(c) - 2π * H * bpf * first(t_rec))
        end
    end
    return amp, ph
end

function _run_f1a_chordwise()
    xs = [-0.125, 0.0, 0.125, 0.25, 0.5]
    table = ValidationTableRow[]; series = PlotSeries[]; n_out = 0; worst = 0.0
    for Mt in (0.45, 0.60, 0.75, 0.90)
        cfg = _r996_cfg(; beta75=10.0, Mt, B=2)
        su = _ccblade_setup(cfg; allow_static=true)
        D = 2su.Rtip
        obs = hub_observers(su.Rtip, D; x_over_D=xs, d_over_D=0.083, x_sign=1)
        dr = _p66_dr(su.r, su.Rhub, su.Rtip)
        Np = [o.Np for o in su.outs]; Tp = [o.Tp for o in su.outs]
        a1, _ = _p67_f1a_chordwise(su.r, su.chord, su.theta, Np, Tp, dr, su.B, su.Ω, su.c0, obs; nc=1)
        a8, _ = _p67_f1a_chordwise(su.r, su.chord, su.theta, Np, Tp, dr, su.B, su.Ω, su.c0, obs; nc=8)
        for H in 1:3
            d = 20log10.(a8[:, H] ./ a1[:, H])
            for (k, xd) in enumerate(xs)
                out = abs(d[k]) > 2.0; n_out += out; worst = max(worst, abs(d[k]))
                push!(table, ValidationTableRow("M_t=$Mt H$H x/D=$xd chordwise − compact (dB)", xd + 10Mt + 100H,
                                                20log10(a1[k, H] / 2e-5), 20log10(a8[k, H] / 2e-5), d[k], !out, "H$H"))
            end
            push!(series, PlotSeries("M_t=$Mt H$H", :computed, xs, d; panel=H))
        end
    end
    return _p67_result("F1A_CHORDWISE", table, series, true,
        "diagnostic (rule fixed 2026-10-24): $n_out/$(length(table)) Report 996 Fig. 14-geometry points where spreading the load over the chord " *
        "changes the tone by more than 2 dB; largest $(round(worst; digits=2)) dB",
        (; rule="|chordwise − compact| > 2 dB ⇒ outside the compact-chord claim", n_out, worst); verdict=:no_verdict)
end

function _iso67_validation_cases()
    return [
        ValidationCase("POLAR_FIDELITY", "Section polars: XFOIL vs NACA TN 1546 measured c_l (67a)", "67",
            [_data_path(splitpath(_R996_POLAR_PATH)...), _data_path("airfoil_measured", "tn1546_fig3_cl_cd_vs_mach.csv")],
            FigureRef("NACA TN 1546", "Fig. 3(j), 3(n), 3(o)", 30),
            "|Δc_l| ≤ 0.05 at ≥ 75 % of the matched (section, M, α) points; XFOIL at the TN 1546 Reynolds number, no extrapolation.",
            "2026-10-24", "V-EXP (input)", _run_polar_fidelity,
            PlotSpec(; xlabel="α (deg)", ylabel="Δc_l = XFOIL − TN 1546",
                     panel_titles=["NACA 16-312", "NACA 16-506", "NACA 16-509", "NACA 16-312: equivalent Δα (display only)",
                                   "NACA 16-506: equivalent Δα (display only)", "NACA 16-509: equivalent Δα (display only)"],
                     panel_ylabels=["", "", "", "Δα = Δc_l / (2π/√(1−M²)) (deg)", "Δα = Δc_l / (2π/√(1−M²)) (deg)",
                                    "Δα = Δc_l / (2π/√(1−M²)) (deg)"],
                     error_mode=:absolute, error_tol=0.05, error_ylabel="Δc_l (dimensionless)",
                     error_xlabel="10 × section + Mach (section 1: 16-312, 2: 16-506, 3: 16-509)"), ""),
        ValidationCase("F1A_CHORDWISE", "F1A near field: compact vs chordwise loading at Report 996 geometry (67b)", "67",
            String[], FigureRef("NACA Report 996", "Fig. 14 geometry", nothing),
            "Diagnostic: a harmonic where |compact − chordwise| > 2 dB is outside what the compact-chord F1A can claim.",
            "2026-10-24", "diagnostic", _run_f1a_chordwise,
            PlotSpec(; xlabel="x/D", ylabel="chordwise − compact (dB)", panel_titles=["H1", "H2", "H3"],
                     error_mode=:absolute, error_tol=2.0, error_ylabel="chordwise − compact (dB)"), ""),
    ]
end
