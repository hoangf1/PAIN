# Phase 66 — further code checks of the BEMT (CCBlade wrapper) and F1A source blocks.
# Criteria fixed 2026-10-24 (IMPLEMENTATION_PLAN.md §8j) before any run; readings in the same section, also
# before any run. No measured data is used: every reference is a closed form or an identity.

const _P66_REPORT = "phase66_bemt_f1a.md"

function _p66_result(id, table, series, ok, reason, echo)
    return ValidationCaseResult(id, _today_iso(), merge((; date="2026-10-24"), echo), table, series,
        ok ? :met : :not_met, (ok ? "" : "criterion not met — ") * reason, "V-UNIT", joinpath(_VAL_REPORT_DIR, _P66_REPORT))
end

"""Hartzell-example propeller config as a NamedTuple with `V`, `rpm`, `tc`, blade count `B` and `nsec`
stations (linear resampling of chord and twist over the listed span) set by the caller."""
function _p66_hartzell(; V::Real=20.0, rpm::Real=4000.0, tc::Real=0.0, B::Union{Nothing,Int}=nothing,
                       nsec::Union{Nothing,Int}=nothing)
    p = _load_aircraft_json(_p62_example("aircraft_scale_hartzell.json")).propeller
    r = Float64.(collect(p.radii_m)); c = Float64.(collect(p.chord_m)); tw = Float64.(collect(p.twist_deg))
    if nsec !== nothing
        rs = collect(range(first(r), last(r); length=nsec))
        lin(y) = [interp_no_extrap(r, y, x) for x in rs]
        c, tw, r = lin(c), lin(tw), rs
    end
    return (; propeller=(; num_blades=B === nothing ? Int(p.num_blades) : B, tip_radius_m=Float64(p.tip_radius_m),
                         hub_radius_m=Float64(p.hub_radius_m), rpm=Float64(rpm), radii_m=r, chord_m=c, twist_deg=tw,
                         pitch_offset_deg=Float64(p.pitch_offset_deg), thickness_over_chord=Float64(tc)),
            operating_point=(; forward_speed_mps=Float64(V), rho_kg_m3=1.225, c0_mps=340.0))
end

"""Report 996 blade (β₇₅ = 15°, M_t = 0.6, B = 2) at forward speed `V` (static in Report 996; V > 0 here)."""
function _p66_r996(; V::Real=20.0)
    c = _r996_cfg(; beta75=15.0, Mt=0.6, B=2)
    return (; propeller=c.propeller, operating_point=(; c.operating_point..., forward_speed_mps=Float64(V)))
end

"""Span weights AcousticAnalogies gives the sections (`get_dradii`): interfaces midway, ends at R_hub, R_tip."""
function _p66_dr(r, Rhub, Rtip)
    ri = vcat(Rhub, 0.5 .* (r[1:end-1] .+ r[2:end]), Rtip)
    return ri[2:end] .- ri[1:end-1]
end

"""Raw momentum induction from the section outputs (CCBlade momentum region, k ≥ −2/3)."""
function _p66_raw_induction(o, r, chord, B)
    σ = B * chord / (2π * r)
    s, c = sin(o.phi), cos(o.phi)
    k = o.cn * σ / (4 * o.F * s^2)
    kp = o.ct * σ / (4 * o.F * s * c)
    return (; a=k / (1 - k), ap=kp / (1 + kp), k)
end

# --- 66a BEMT_MOMENTUM -----------------------------------------------------------------------
function _run_bemt_momentum()
    cases = [("Hartzell V=20 m/s, 4000 rpm", _p66_hartzell(; V=20.0, rpm=4000.0)),
             ("Hartzell V=40 m/s, 3000 rpm", _p66_hartzell(; V=40.0, rpm=3000.0)),
             ("Report 996 β75=15°, M_t=0.6, V=20 m/s", _p66_r996(; V=20.0))]
    table = ValidationTableRow[]; series = PlotSeries[]; worst = 0.0; n_bad = 0
    for (ci, (name, cfg)) in enumerate(cases)
        su = _ccblade_setup(cfg)
        ρ, V, B = su.ρ, su.Vinf, su.B
        eT = Float64[]; eQ = Float64[]; rk = Float64[]
        for (i, o) in enumerate(su.outs)
            r = su.r[i]
            ind = _p66_raw_induction(o, r, su.chord[i], B)
            ind.k ≥ -2 / 3 || continue
            Vy = su.ops[i].Vy
            # raw-induction momentum (F on the annulus) and CCBlade's G form
            mT = 4π * r * ρ * V^2 * o.F * ind.a * (1 + ind.a)
            mQ = 4π * r * ρ * V * (1 + ind.a) * Vy * o.F * ind.ap
            gT = 4π * r * ρ * (V + o.u) * o.u
            gQ = 4π * r * ρ * (V + o.u) * o.v
            bT, bQ = B * o.Np, B * o.Tp
            e = maximum(abs, (bT / mT - 1, bQ / mQ - 1, bT / gT - 1, bQ / gQ - 1))
            push!(eT, abs(bT / mT - 1)); push!(eQ, abs(bQ / mQ - 1)); push!(rk, r / su.Rtip)
            ok = e ≤ 1e-8; n_bad += !ok; worst = max(worst, e)
            push!(table, ValidationTableRow("$(name): r/R=$(round(r / su.Rtip; digits=3)) max rel. diff", Float64(ci) + r / su.Rtip,
                                            0.0, e, e, ok))
        end
        push!(series, PlotSeries("thrust: $name", :computed, rk, log10.(max.(eT, 1e-17)); panel=1))
        push!(series, PlotSeries("torque: $name", :computed, rk, log10.(max.(eQ, 1e-17)); panel=1))
    end
    return _p66_result("BEMT_MOMENTUM", table, series, n_bad == 0,
        "momentum and blade-element thrust/torque per station agree to $(round(worst; sigdigits=2)) relative (criterion 1e-8), $(length(table)) stations",
        (; criterion="≤ 1e-8 relative at every station", worst))
end

# --- 66b BEMT_HAND_TIP -----------------------------------------------------------------------
"""Nonlinear section polar for 66b (independent of any table): c_l = 2πα − 4α³ (stall bend), c_d = 0.008 + 0.6α²."""
_p66_af(α, Re, M) = (2π * α - 4 * α^3, 0.008 + 0.6 * α^2)

"""Hand BEM with Prandtl tip and hub loss (textbook form), drag and the nonlinear polar; bisection on φ."""
function _p66_hand_section(r, chord, θ, Rhub, Rtip, B, V, Vy, ρ)
    σ = B * chord / (2π * r)
    function state(φ)
        s, c = sin(φ), cos(φ)
        cl, cd = _p66_af(θ - φ, 0.0, 0.0)
        cn, ct = cl * c - cd * s, cl * s + cd * c
        ftip = B / 2 * (Rtip - r) / (r * abs(s)); fhub = B / 2 * (r - Rhub) / (Rhub * abs(s))
        F = (2 / π) * acos(exp(-ftip)) * (2 / π) * acos(exp(-fhub))
        k = cn * σ / (4F * s^2); kp = ct * σ / (4F * s * c)
        a = k / (1 - k); ap = kp / (1 + kp)
        R = s / (1 + a) - V / Vy * c / (1 - ap)
        W2 = (V * (1 + a))^2 + (Vy * (1 - ap))^2
        return (; R, Np=cn * 0.5 * ρ * W2 * chord, Tp=ct * 0.5 * ρ * W2 * chord)
    end
    lo, hi = 1e-6, π / 2 - 1e-6
    φs = range(lo, hi; length=400)
    Rs = [state(φ).R for φ in φs]
    # bisect every sign change; a sign change across the pole k = 1 (a = k/(1 − k) → ±∞) is not a root, so keep
    # only brackets whose residual goes to zero (code-on-code fix of this reference 2026-10-24: the first run took the pole)
    roots = Float64[]
    for j in 1:length(Rs)-1
        Rs[j] * Rs[j+1] ≤ 0 || continue
        a, b = φs[j], φs[j+1]
        for _ in 1:200
            m = (a + b) / 2
            state(a).R * state(m).R ≤ 0 ? (b = m) : (a = m)
            b - a < 1e-14 && break
        end
        φr = (a + b) / 2
        abs(state(φr).R) < 1e-8 && push!(roots, φr)
    end
    isempty(roots) && error("hand BEM: no root at r = $r")
    n_roots = length(roots)
    return merge(state(first(roots)), (; n_roots, residual=φ -> state(φ).R))
end

function _run_bemt_hand_tip()
    table = ValidationTableRow[]; series = PlotSeries[]; n_bad = 0; diag = NamedTuple[]
    for (j, (V, rpm)) in enumerate(((20.0, 4000.0), (40.0, 4000.0)))
        cfg = _p66_hartzell(; V, rpm)
        su = _ccblade_setup(cfg; af=_p66_af)
        Ω = su.Ω
        hs = [_p66_hand_section(su.r[i], su.chord[i], su.theta[i], su.Rhub, su.Rtip, su.B, su.Vinf, Ω * su.r[i], su.ρ) for i in eachindex(su.r)]
        # trapezoid with zero load at R_hub and R_tip (written here)
        rr = vcat(su.Rhub, su.r, su.Rtip)
        trap(y) = sum((rr[k+1] - rr[k]) * (y[k] + y[k+1]) / 2 for k in 1:length(rr)-1)
        Th = su.B * trap(vcat(0.0, [h.Np for h in hs], 0.0))
        Qh = su.B * trap(vcat(0.0, [h.Tp for h in hs], 0.0) .* rr)
        src = evaluate_propeller_source(cfg, [Observer([0.0, 50.0, 0.0], [su.Vinf, 0.0, 0.0], "o")]; n_harmonics=1,
                                        num_src_times=16, af=_p66_af)
        for (q, h, w) in (("T (N)", Th, src.T), ("Q (N m)", Qh, src.Q))
            ok = abs(w / h - 1) ≤ 0.01; n_bad += !ok
            push!(table, ValidationTableRow("V=$(Int(V)) m/s: $q wrapper vs hand", Float64(j), h, w, w - h, ok))
        end
        # post-hoc diagnostics (2026-10-24, after the first run; no criterion): stations with more than one BEM root,
        # and the hand residual evaluated at CCBlade's φ (zero when CCBlade's root is also a root of the hand equations)
        multi = [round(su.r[i] / su.Rtip; digits=3) for (i, h) in enumerate(hs) if h.n_roots > 1]
        Rccb = maximum(abs(hs[i].residual(su.outs[i].phi)) for i in eachindex(hs))
        push!(diag, (; V, multi_root_r_over_R=multi, max_hand_residual_at_ccblade_phi=Rccb))
        push!(series, PlotSeries("hand N′, V=$(Int(V))", :reference_points, su.r ./ su.Rtip, [h.Np for h in hs]; panel=1))
        push!(series, PlotSeries("CCBlade N′, V=$(Int(V))", :computed, su.r ./ su.Rtip, [o.Np for o in su.outs]; panel=1))
    end
    return _p66_result("BEMT_HAND_TIP", table, series, n_bad == 0,
        "$(count(t -> t.within_tolerance, table))/$(length(table)) of T, Q within 1 % of the hand BEM with tip/hub loss, drag and a nonlinear polar. " *
        "CCBlade's φ zeroes the hand residual at every station (max |R| = " *
        join([string(round(d.max_hand_residual_at_ccblade_phi; sigdigits=2)) for d in diag], ", ") * "). " *
        "Re-run 2026-10-24 after a fix of this hand reference (its first run bisected across the k = 1 pole near the tip; 0/4)",
        (; criterion="T and Q within 1 %", diagnostics=diag, first_run="0/4 (hand reference took the k = 1 pole, fixed)"))
end

# --- 66c BEMT_INTEGRALS ----------------------------------------------------------------------
function _run_bemt_integrals()
    table = ValidationTableRow[]; series = PlotSeries[]; n_bad = 0; span_ratio = Dict{String,Float64}()
    obs = [Observer([0.0, 50.0, 0.0], [20.0, 0.0, 0.0], "o")]
    for (j, (name, mk)) in enumerate((("Hartzell", n -> _p66_hartzell(; V=20.0, rpm=4000.0, nsec=n)),
                                      ("Report 996", n -> _p66_r996(; V=20.0))))
        cfg = mk(20)
        su = _ccblade_setup(cfg)
        src = evaluate_propeller_source(cfg, obs; n_harmonics=1, num_src_times=16)
        rr = vcat(su.Rhub, su.r, su.Rtip)
        trap(y) = sum((rr[k+1] - rr[k]) * (y[k] + y[k+1]) / 2 for k in 1:length(rr)-1)
        T_int = su.B * trap(vcat(0.0, [o.Np for o in su.outs], 0.0))
        Q_int = su.B * trap(vcat(0.0, [o.Tp for o in su.outs], 0.0) .* rr)
        n = su.rpm / 60; D = 2su.Rtip
        P_rep = src.CP * su.ρ * n^3 * D^5
        A = π * su.Rtip^2
        η = src.T * su.Vinf / (su.Ω * src.Q)
        η_i = 2 / (1 + sqrt(1 + src.T / (0.5 * su.ρ * su.Vinf^2 * A)))
        rows = [("$name: B∫N′dr vs T", T_int, src.T, abs(src.T / T_int - 1) ≤ 1e-10),
                ("$name: ΩQ vs C_P ρn³D⁵", su.Ω * Q_int, P_rep, abs(P_rep / (su.Ω * Q_int) - 1) ≤ 1e-10),
                ("$name: η vs Froude ideal η_i", η_i, η, η ≤ η_i)]
        if name == "Hartzell"
            T1 = evaluate_propeller_source(mk(20), obs; n_harmonics=1, num_src_times=16).T
            T2 = evaluate_propeller_source(mk(39), obs; n_harmonics=1, num_src_times=16).T
            push!(rows, ("Hartzell: T, 20 → 39 stations (half spacing)", T1, T2, abs(T2 / T1 - 1) < 0.005))
        end
        for (q, ref, got, ok) in rows
            n_bad += !ok
            push!(table, ValidationTableRow(q, Float64(j), ref, got, got - ref, ok))
        end
        # information (no criterion): the thrust F1A radiates (AcousticAnalogies midpoint spans) vs CCBlade's trapezoid
        dr = _p66_dr(su.r, su.Rhub, su.Rtip)
        span_ratio[name] = su.B * sum(o.Np * d for (o, d) in zip(su.outs, dr)) / src.T
        push!(series, PlotSeries("$name N′", :computed, su.r ./ su.Rtip, [o.Np for o in su.outs]; panel=1))
    end
    return _p66_result("BEMT_INTEGRALS", table, series, n_bad == 0,
        "$(count(t -> t.within_tolerance, table))/$(length(table)) integral, power, Froude-bound and spacing checks hold. " *
        "Information: the thrust F1A radiates with AcousticAnalogies' midpoint spans / CCBlade's trapezoid T = " *
        join(["$(k) $(round(v; digits=4))" for (k, v) in sort(collect(span_ratio))], ", "),
        (; criterion="B∫N′=T, P=ΩQ (1e-10); η ≤ η_i; ΔT < 0.5 % on halving the spacing", span_ratio))
end

# --- 66d BEMT_SIMILARITY ---------------------------------------------------------------------
function _run_bemt_similarity()
    obs = [Observer([0.0, 50.0, 0.0], [20.0, 0.0, 0.0], "o")]
    base = evaluate_propeller_source(_p66_hartzell(; V=20.0, rpm=4000.0), obs; n_harmonics=1, num_src_times=16)
    table = ValidationTableRow[]; xs = Float64[]; yT = Float64[]; yP = Float64[]
    for s in (0.5, 2.0, 3.0)
        r = evaluate_propeller_source(_p66_hartzell(; V=20.0s, rpm=4000.0s), [Observer(obs[1].x, [20.0s, 0, 0], "o")];
                                      n_harmonics=1, num_src_times=16)
        for (q, b, g) in (("C_T", base.CT, r.CT), ("C_P", base.CP, r.CP))
            push!(table, ValidationTableRow("$q at J fixed, V and rpm × $s", s, b, g, g - b, abs(g / b - 1) ≤ 1e-6))
        end
        push!(xs, s); push!(yT, r.CT / base.CT - 1); push!(yP, r.CP / base.CP - 1)
    end
    series = [PlotSeries("C_T/C_T,ref − 1", :computed, xs, yT; panel=1), PlotSeries("C_P/C_P,ref − 1", :computed, xs, yP; panel=1)]
    ok = all(t.within_tolerance for t in table)
    return _p66_result("BEMT_SIMILARITY", table, series, ok,
        "C_T and C_P at fixed J with a Re- and M-independent polar: $(count(t -> t.within_tolerance, table))/$(length(table)) within 1e-6",
        (; criterion="1e-6 relative", J=20.0 / (4000 / 60 * 0.762)))
end

# --- Gutin / Garrick–Watkins references ------------------------------------------------------
"""Far-field loading harmonic (peak, Pa) of the BEMT loads `su`, Garrick–Watkins form (M_x = 0: Gutin),
observer at (x forward, y) from the hub moving with the propeller; sections weighted by the F1A spans."""
function _p66_gw_peak(su, m::Int, x::Real, y::Real; Mx::Real=0.0)
    B, Ω, c0 = su.B, su.Ω, su.c0
    β2 = 1 - Mx^2
    S0 = sqrt(x^2 + β2 * y^2)
    dr = _p66_dr(su.r, su.Rhub, su.Rtip)
    s = 0.0
    for (i, o) in enumerate(su.outs)
        R = su.r[i]
        dT = B * o.Np * dr[i]; dQ = B * o.Tp * R * dr[i]
        s += (m * B * Ω / (2sqrt(2) * π * c0 * S0)) * (-dT * (Mx + x / S0) / β2 + dQ * c0 / (Ω * R^2)) *
             _besselj_int(m * B, m * B * Ω * R * y / (c0 * S0))
    end
    return sqrt(2) * abs(s), sign(s)
end

# --- 66e F1A_GUTIN_ANGLES --------------------------------------------------------------------
function _run_f1a_gutin_angles()
    cfg = _p66_hartzell(; V=0.0, rpm=4000.0)
    su = _ccblade_setup(cfg; allow_static=true)
    rob = 100 * su.Rtip
    θs = [30.0, 60.0, 90.0, 120.0, 150.0]
    obs = [Observer([rob * cosd(θ), rob * sind(θ), 0.0], zeros(3), "θ=$θ") for θ in θs]
    src = evaluate_propeller_source(cfg, obs; n_harmonics=2, num_src_times=128, allow_static=true)
    refs = [_p66_gw_peak(su, 1, rob * cosd(θ), rob * sind(θ)) for θ in θs]
    i90 = findfirst(==(90.0), θs)
    table = ValidationTableRow[]; n_bad = 0
    for (i, θ) in enumerate(θs)
        g, sg = refs[i]
        dB = 20log10(src.amplitude[i, 1] / g)
        dφ = rad2deg(_wrap_phase(src.phase[i, 1] - src.phase[i90, 1]))
        φref = sg == refs[i90][2] ? 0.0 : 180.0
        eφ = abs(rad2deg(_wrap_phase(deg2rad(dφ - φref))))
        okA = abs(dB) ≤ 0.5; okP = eφ ≤ 5.0; n_bad += !(okA && okP)
        push!(table, ValidationTableRow("H1 level θ=$(Int(θ))° (dB re Gutin)", θ, 20log10(g / 2e-5), 20log10(src.amplitude[i, 1] / 2e-5), dB, okA))
        push!(table, ValidationTableRow("H1 phase re θ=90°, θ=$(Int(θ))° (deg)", θ, φref, dφ, eφ, okP, "phase"))
    end
    # post-hoc diagnostics (2026-10-24, after the first run; no criterion): how far the thrust and torque terms cancel,
    # and the θ = 60° phase at 400 R_tip
    dr = _p66_dr(su.r, su.Rhub, su.Rtip)
    canc = Dict(θ => begin
        tT = sum(-su.B * o.Np * dr[i] * cosd(θ) * _besselj_int(su.B, su.B * su.Ω * su.r[i] * sind(θ) / su.c0) for (i, o) in enumerate(su.outs))
        tQ = sum(su.B * o.Tp * su.r[i] * dr[i] * su.c0 / (su.Ω * su.r[i]^2) * _besselj_int(su.B, su.B * su.Ω * su.r[i] * sind(θ) / su.c0) for (i, o) in enumerate(su.outs))
        abs(tT + tQ) / (abs(tT) + abs(tQ)) end for θ in θs)
    far = evaluate_propeller_source(cfg, [Observer([400su.Rtip * cosd(θ), 400su.Rtip * sind(θ), 0.0], zeros(3), "far") for θ in (60.0, 90.0)];
                                    n_harmonics=1, num_src_times=128, allow_static=true)
    φ60_far = rad2deg(_wrap_phase(far.phase[1, 1] - far.phase[2, 1]))
    series = [PlotSeries("Gutin (annuli, thrust + torque)", :reference_points, θs, [20log10(r[1] / 2e-5) for r in refs]; panel=1),
              PlotSeries("F1A", :computed, θs, [20log10(a / 2e-5) for a in src.amplitude[:, 1]]; panel=1)]
    return _p66_result("F1A_GUTIN_ANGLES", table, series, n_bad == 0,
        "$(length(θs) - n_bad)/$(length(θs)) angles with H1 within 0.5 dB and 5° of Gutin (static, 100 R_tip). " *
        "Post-hoc: at θ = 60° the thrust and torque terms cancel to $(round(canc[60.0]; digits=3)) of their sum; the 60° phase re 90° is " *
        "$(round(φ60_far; digits=1))° at 400 R_tip",
        (; criterion="0.5 dB and 5° at five angles", θs, posthoc_cancellation=canc, posthoc_phase60_400R=φ60_far))
end

# --- 66f F1A_GW_FLIGHT -----------------------------------------------------------------------
function _run_f1a_gw_flight()
    table = ValidationTableRow[]; series = PlotSeries[]; n_bad = 0
    θs = [60.0, 90.0, 120.0]
    for Mx in (0.1, 0.2)
        V = Mx * 340.0
        cfg = _p66_hartzell(; V, rpm=4000.0)
        su = _ccblade_setup(cfg)
        rob = 100 * su.Rtip
        obs = [Observer([rob * cosd(θ), rob * sind(θ), 0.0], [V, 0.0, 0.0], "θ=$θ") for θ in θs]
        src = evaluate_propeller_source(cfg, obs; n_harmonics=1, num_src_times=128)
        gw = [_p66_gw_peak(su, 1, rob * cosd(θ), rob * sind(θ); Mx)[1] for θ in θs]
        for (i, θ) in enumerate(θs)
            dB = 20log10(src.amplitude[i, 1] / gw[i]); ok = abs(dB) ≤ 1.0; n_bad += !ok
            push!(table, ValidationTableRow("M_x=$Mx θ=$(Int(θ))° H1 (dB re Garrick–Watkins)", θ + 1000Mx, 20log10(gw[i] / 2e-5),
                                            20log10(src.amplitude[i, 1] / 2e-5), dB, ok))
        end
        push!(series, PlotSeries("Garrick–Watkins M_x=$Mx", :reference_points, θs, 20log10.(gw ./ 2e-5); panel=1))
        push!(series, PlotSeries("F1A M_x=$Mx", :computed, θs, 20log10.(src.amplitude[:, 1] ./ 2e-5); panel=1))
    end
    return _p66_result("F1A_GW_FLIGHT", table, series, n_bad == 0,
        "$(length(table) - n_bad)/$(length(table)) flight points with H1 within 1 dB of Garrick–Watkins (observers moving with the propeller, 100 R_tip)",
        (; criterion="1 dB at M_x = 0.1, 0.2 and three angles"))
end

# --- 66g F1A_THICKNESS -----------------------------------------------------------------------
function _run_f1a_thickness()
    tc = 0.12
    cfg = _p66_hartzell(; V=0.0, rpm=4000.0, tc)
    su = _ccblade_setup(cfg; allow_static=true)
    rob = 100 * su.Rtip
    θs = [60.0, 90.0, 120.0]
    obs = [Observer([rob * cosd(θ), rob * sind(θ), 0.0], zeros(3), "θ=$θ") for θ in θs]
    src = evaluate_propeller_source(cfg, obs; n_harmonics=3, num_src_times=128, allow_static=true,
                                    loads=ScaledLoads(0.0, 0.0))
    dr = _p66_dr(su.r, su.Rhub, su.Rtip)
    A = tc .* su.chord .^ 2
    ref(m, θ) = su.ρ * (m * su.B * su.Ω)^2 * su.B *
                abs(sum(A[i] * dr[i] * _besselj_int(m * su.B, m * su.B * su.Ω * su.r[i] * sind(θ) / su.c0) for i in eachindex(A))) / (2π * rob)
    table = ValidationTableRow[]; n_bad = 0; series = PlotSeries[]
    for m in 1:3
        for (i, θ) in enumerate(θs)
            g = ref(m, θ); dB = 20log10(src.amplitude[i, m] / g); ok = abs(dB) ≤ 1.0; n_bad += !ok
            push!(table, ValidationTableRow("H$m θ=$(Int(θ))° thickness (dB re compact far field)", θ + 1000m, 20log10(g / 2e-5),
                                            20log10(src.amplitude[i, m] / 2e-5), dB, ok))
        end
        push!(series, PlotSeries("compact far field H$m", :reference_points, θs, [20log10(ref(m, θ) / 2e-5) for θ in θs]; panel=1))
        push!(series, PlotSeries("F1A thickness H$m", :computed, θs, 20log10.(src.amplitude[:, m] ./ 2e-5); panel=1))
    end
    return _p66_result("F1A_THICKNESS", table, series, n_bad == 0,
        "$(length(table) - n_bad)/$(length(table)) thickness-noise harmonics within 1 dB of the compact far-field form (t/c = $tc, static)",
        (; criterion="1 dB, H1–H3, three angles", tc))
end

# --- 66h F1A_PROPERTIES ----------------------------------------------------------------------
function _run_f1a_properties()
    table = ValidationTableRow[]; series = PlotSeries[]
    push_row!(q, x, ref, got, ok) = push!(table, ValidationTableRow(q, x, ref, got, got - ref, ok))
    # (i) blade count: identical prescribed section loads on B = 2 and B = 4 rotors; at the same frequency 4Ω the
    #     4-blade H1 is twice the 2-blade H2 (coherent sum of identical blades), observers static
    cfg2 = _p66_hartzell(; V=0.0, rpm=4000.0, B=2)
    su2 = _ccblade_setup(cfg2; allow_static=true)
    rotor4 = CCBlade.Rotor(su2.Rhub, su2.Rtip, 4)
    rob = 100 * su2.Rtip
    obs = [Observer([rob * cosd(θ), rob * sind(θ), 0.0], zeros(3), "θ=$θ") for θ in (60.0, 90.0)]
    ac = zeros(length(su2.r))
    bpf2 = 2 * su2.rpm / 60
    A2, _ = _f1a_harmonics(su2.rotor, su2.sections, su2.ops, su2.outs, ac, obs; period_src=2 * 2π / su2.Ω,
                           n_src=2 * 2 * 64, num_src_times=64, n_harmonics=2, bpf=bpf2)
    A4, _ = _f1a_harmonics(rotor4, su2.sections, su2.ops, su2.outs, ac, obs; period_src=2 * 2π / su2.Ω,
                           n_src=2 * 4 * 64, num_src_times=64, n_harmonics=1, bpf=2bpf2)
    for (i, θ) in enumerate((60.0, 90.0))
        r = A4[i, 1] / A2[i, 2]
        push_row!("B=4 H1 / B=2 H2 at 4Ω, θ=$(Int(θ))° (expected 2)", θ, 2.0, r, abs(r / 2 - 1) ≤ 0.01)
    end
    # (ii) 1/r in the far field (static, θ = 90°)
    cfg = _p66_hartzell(; V=0.0, rpm=4000.0)
    R = 0.381
    s12 = evaluate_propeller_source(cfg, [Observer([0.0, 100R, 0.0], zeros(3), "a"), Observer([0.0, 200R, 0.0], zeros(3), "b")];
                                    n_harmonics=1, num_src_times=64, allow_static=true)
    push_row!("H1 at 100 R / at 200 R (expected 2)", 1.0, 2.0, s12.amplitude[1, 1] / s12.amplitude[2, 1],
              abs(s12.amplitude[1, 1] / s12.amplitude[2, 1] / 2 - 1) ≤ 0.01)
    # (iii) convergence in source time step (successive halvings < 0.1 dB)
    o90 = [Observer([0.0, 100R, 0.0], zeros(3), "c")]
    L(n) = 20log10(evaluate_propeller_source(cfg, o90; n_harmonics=1, num_src_times=n, allow_static=true).amplitude[1, 1] / 2e-5)
    Ls = [L(n) for n in (32, 64, 128)]
    push_row!("H1 change, 64 → 128 source times (dB)", 2.0, 0.0, Ls[3] - Ls[2], abs(Ls[3] - Ls[2]) < 0.1)
    # (iv) convergence in blade sections (20 → 39 stations)
    Ln(n) = 20log10(evaluate_propeller_source(_p66_hartzell(; V=0.0, rpm=4000.0, nsec=n), o90; n_harmonics=1, num_src_times=64,
                                              allow_static=true).amplitude[1, 1] / 2e-5)
    l20, l39 = Ln(20), Ln(39)
    push_row!("H1 change, 20 → 39 blade stations (dB)", 3.0, 0.0, l39 - l20, abs(l39 - l20) < 0.1)
    series = [PlotSeries("H1 vs source times", :computed, [32.0, 64.0, 128.0], Ls; panel=1)]
    ok = all(t.within_tolerance for t in table)
    return _p66_result("F1A_PROPERTIES", table, series, ok,
        "$(count(t -> t.within_tolerance, table))/$(length(table)) exact-property and convergence checks hold",
        (; criterion="B scaling and 1/r within 1 %; < 0.1 dB between successive halvings"))
end

function _iso66_validation_cases()
    mk(id, title, crit, run; ylab="value", xlab="x", errlab="") = ValidationCase(id, title, "66", String[],
        FigureRef("Phase 66", "closed forms (§8j)", nothing), crit, "2026-10-24", "V-UNIT", run,
        PlotSpec(; xlabel=xlab, ylabel=ylab, panel_titles=[id], error_mode=:absolute, error_tol=0.0, error_ylabel=errlab), "")
    return [
        mk("BEMT_MOMENTUM", "BEMT: momentum = blade element at every station (66a)",
           "Momentum and blade-element thrust/torque per station within 1e-8 relative, three operating points.", _run_bemt_momentum;
           xlab="r/R", ylab="log10 |relative difference|", errlab="relative difference (dimensionless)"),
        mk("BEMT_HAND_TIP", "BEMT: hand BEM with tip loss, drag, nonlinear polar (66b)",
           "T and Q within 1 % of the wrapper.", _run_bemt_hand_tip; xlab="r/R", ylab="N′ (N/m)", errlab="wrapper − hand (N | N m)"),
        mk("BEMT_INTEGRALS", "BEMT: integrals, Froude bound, station spacing (66c)",
           "B∫N′dr = T and P = ΩQ (1e-10); η ≤ η_i; halving the spacing changes T by < 0.5 %.", _run_bemt_integrals;
           xlab="r/R", ylab="N′ (N/m)", errlab="got − ref (N | W | -)"),
        mk("BEMT_SIMILARITY", "BEMT: C_T, C_P unchanged at fixed J (66d)",
           "C_T and C_P within 1e-6 relative when rpm and V scale together (Re/M-free polar).", _run_bemt_similarity;
           xlab="scale of V and rpm", ylab="relative change", errlab="change (dimensionless)"),
        mk("F1A_GUTIN_ANGLES", "F1A vs Gutin off the rotor plane, thrust and torque (66e)",
           "H1 within 0.5 dB and 5° of Gutin at θ = 30°–150°, static, far field.", _run_f1a_gutin_angles;
           xlab="θ from flight direction (deg)", ylab="H1 SPL (dB)", errlab="F1A − Gutin (dB | deg)"),
        mk("F1A_GW_FLIGHT", "F1A vs Garrick–Watkins in flight (66f)",
           "H1 within 1 dB at M_x = 0.1, 0.2 and θ = 60°, 90°, 120°.", _run_f1a_gw_flight;
           xlab="θ from flight direction (deg)", ylab="H1 SPL (dB)", errlab="F1A − Garrick–Watkins (dB)"),
        mk("F1A_THICKNESS", "F1A thickness noise vs the compact far field (66g)",
           "H1–H3 within 1 dB at three angles.", _run_f1a_thickness;
           xlab="θ from flight direction (deg)", ylab="SPL (dB)", errlab="F1A − compact (dB)"),
        mk("F1A_PROPERTIES", "F1A exact properties and convergence (66h)",
           "B scaling and 1/r within 1 %; < 0.1 dB between successive halvings of time step and station spacing.", _run_f1a_properties;
           xlab="check", ylab="H1 SPL (dB)", errlab="got − expected (ratio | dB)"),
    ]
end
