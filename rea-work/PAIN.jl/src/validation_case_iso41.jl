# Phase 41 — isolation of failing experimental cases (V-UNIT / V-CODE).
# Criteria fixed 2026-10-23 in IMPLEMENTATION_PLAN.md §8b; do not change tolerances.
# Pattern matches phase 40: independent reference written here, never the function under test.

# --- shared helpers -----------------------------------------------------------------

"""Digitization A of Fig. E-12 measured blocked SPL (ℓ = 1); same reader as E12_BLOCK."""
function _iso41_e12_measured_curve()
    path = joinpath(@__DIR__, "..", "..", "data", "cr3813", "e12", "e12_measured_A.csv")
    return _e12_readcurve(path)
end

"""Linear interpolate E-12 (x/D → SPL); NaN outside the digitized span (no invented values)."""
_iso41_e12_interp(pts, x) = _e12_interp(pts, x)

"""Hand ln / arctan / D_nr / brace of CR-3813 p. 22 — independent of `nr_*` helpers."""
function _iso41_hand_nr_brace(ω, c_ω, ω_n, η_n, ω_r, η_r)
    b_n = -2 * ω_n^2
    b_r = -2 * ω_r^2
    c_n = ω_n^4 * (1 + η_n^2)
    c_r = ω_r^4 * (1 + η_r^2)
    D = (c_r - c_n)^2 + (b_n - b_r) * (b_n * c_r - b_r * c_n)
    up, dn = 1 + c_ω / 2, 1 - c_ω / 2
    ln_n = log(abs(up^4 * ω^4 + b_n * up^2 * ω^2 + c_n) /
               max(abs(dn^4 * ω^4 + b_n * dn^2 * ω^2 + c_n), floatmin(Float64)))
    ln_r = log(abs(up^4 * ω^4 + b_r * up^2 * ω^2 + c_r) /
               max(abs(dn^4 * ω^4 + b_r * dn^2 * ω^2 + c_r), floatmin(Float64)))
    d_n = 4 * η_n * ω_n^2
    d_r = 4 * η_r * ω_r^2
    at_n = η_n == 0 ? 0.0 :
           atan(((2 + c_ω)^2 * ω^2 - 4 * ω_n^2) / d_n) -
           atan(((2 - c_ω)^2 * ω^2 - 4 * ω_n^2) / d_n)
    at_r = η_r == 0 ? 0.0 :
           atan(((2 + c_ω)^2 * ω^2 - 4 * ω_r^2) / d_r) -
           atan(((2 - c_ω)^2 * ω^2 - 4 * ω_r^2) / d_r)
    brace = ((c_r - c_n) / 4) * ln_n +
            ((2 * c_n * (b_r - b_n) - b_n * (c_r - c_n)) / (4 * η_n * ω_n^2)) * at_n +
            ((c_n - c_r) / 4) * ln_r +
            ((2 * c_r * (b_n - b_r) - b_r * (c_n - c_r)) / (4 * η_r * ω_r^2)) * at_r
    return (; brace, D_nr=D)
end

"""Closed-form App. A 2×2 product for limp septum on one porous layer (independent of `stack_matrix`)."""
function _iso41_closed_two_layer(ω, thick, mat, m_sept, η_sept; allow_extrapolation=false)
    # Insulation Eq. (A.10) — same algebra as element_matrix, written here.
    p = insulation_properties(mat, ω / 2π; allow_extrapolation)
    k = 2π / p.lambda_m
    x = complex(p.alpha_Np_per_m, -k) * thick
    C, S = cosh(x), sinh(x)
    W = p.W_abs * cis(W_PHASE_SIGN * p.phi_rad)
    M_ins = ComplexF64[C im*ω*W*S; -im*S/(ω*W) C]
    # Limp septum Eq. (A.11)
    M_limp = ComplexF64[1 ω^2 * m_sept * (1 + im * η_sept); 0 1]
    # Skin side first: M = M_limp * M_ins  (Eq. A.12 cascade)
    return M_limp * M_ins
end

"""Hand BEM residual/loads matching CCBlade `residual_and_outputs` with tip F = 1, cd = 0, cl = 2π α."""
function _iso41_hand_bem_section(φ, r, chord, θ, Rhub, Rtip, Vx, Vy, ρ, B)
    σ = B * chord / (2π * r)
    sφ, cφ = sin(φ), cos(φ)
    α = θ - φ
    cl = 2π * α
    cd = 0.0
    cn = cl * cφ - cd * sφ
    ct = cl * sφ + cd * cφ
    F = 1.0
    k = cn * σ / (4 * F * sφ * sφ)
    kp = ct * σ / (4 * F * sφ * cφ)
    if abs(Vx) < 1e-6
        u = sign(φ) * kp * cn / ct * Vy
        v = 0.0
        a = 0.0
        ap = 0.0
        R = sign(φ) - k
    elseif abs(Vy) < 1e-6
        u = 0.0
        v = k * ct / cn * abs(Vx)
        a = 0.0
        ap = 0.0
        R = sign(Vx) + kp
    else
        kk = φ < 0 ? -k : k
        if abs(kk - 1) < 1e-6
            return (R=1.0, Np=0.0, Tp=0.0, a=0.0, ap=0.0)
        end
        if kk >= -2 / 3
            a = kk / (1 - kk)
        else
            g1 = 2kk + 1 / 9
            g2 = -2kk - 1 / 3
            g3 = -2kk - 7 / 9
            a = (g1 + sqrt(g2)) / g3
        end
        u = a * Vx
        kkp = Vx < 0 ? -kp : kp
        if abs(kkp + 1) < 1e-6
            return (R=1.0, Np=0.0, Tp=0.0, a=0.0, ap=0.0)
        end
        ap = kkp / (1 + kkp)
        v = ap * Vy
        R = sin(φ) / (1 + a) - Vx / Vy * cos(φ) / (1 - ap)
    end
    W = hypot(Vx + u, Vy - v)
    Np = cn * 0.5 * ρ * W^2 * chord
    Tp = ct * 0.5 * ρ * W^2 * chord
    return (; R, Np, Tp, a, ap)
end

function _iso41_hand_bem_solve_phi(r, chord, θ, Rhub, Rtip, Vx, Vy, ρ, B)
    # Bracket + bisection on φ ∈ (ε, π−ε), same inflow model as CCBlade (tip off).
    ε = 1e-6
    φ_lo, φ_hi = ε, π - ε
    R_lo = _iso41_hand_bem_section(φ_lo, r, chord, θ, Rhub, Rtip, Vx, Vy, ρ, B).R
    found = false
    φ_a, φ_b = φ_lo, φ_hi
    # coarse scan for a sign change
    Nscan = 80
    prev_φ, prev_R = φ_lo, R_lo
    for i in 1:Nscan
        φ = φ_lo + (φ_hi - φ_lo) * i / Nscan
        Ri = _iso41_hand_bem_section(φ, r, chord, θ, Rhub, Rtip, Vx, Vy, ρ, B).R
        if prev_R * Ri ≤ 0
            φ_a, φ_b = prev_φ, φ
            found = true
            break
        end
        prev_φ, prev_R = φ, Ri
    end
    found || return _iso41_hand_bem_section(atan(Vx, Vy), r, chord, θ, Rhub, Rtip, Vx, Vy, ρ, B)
    φ = φ_a
    for _ in 1:60
        φ = 0.5 * (φ_a + φ_b)
        Ri = _iso41_hand_bem_section(φ, r, chord, θ, Rhub, Rtip, Vx, Vy, ρ, B).R
        Ra = _iso41_hand_bem_section(φ_a, r, chord, θ, Rhub, Rtip, Vx, Vy, ρ, B).R
        if Ra * Ri ≤ 0
            φ_b = φ
        else
            φ_a = φ
        end
    end
    return _iso41_hand_bem_section(φ, r, chord, θ, Rhub, Rtip, Vx, Vy, ρ, B)
end

"""Independent compact Farassat 1A loading-only pressure (thickness off). Plain Julia, not AcousticAnalogies."""
function _iso41_f1a_loading_p(obs_x, y, ydot, yddot, f, fdot, c0)
    # Farassat 1A loading (dipole) at retarded time already applied to (y,f,…).
    rv = obs_x .- y
    r = hypot(rv[1], rv[2], rv[3])
    r < 1e-14 && return 0.0
    rhat = rv ./ r
    rv1 = .-ydot
    r1dot = rhat[1]*rv1[1] + rhat[2]*rv1[2] + rhat[3]*rv1[3]
    rv2 = .-yddot
    r2dot = (rv1[1]^2 + rv1[2]^2 + rv1[3]^2 + rv[1]*rv2[1] + rv[2]*rv2[2] + rv[3]*rv2[3] - r1dot^2) / r
    Mr = -(rv1[1]*rhat[1] + rv1[2]*rhat[2] + rv1[3]*rhat[3]) / c0
    rhat1 = (-r1dot / r^2) .* rv .+ (1 / r) .* rv1
    Mr1 = (rv2[1]*rhat[1] + rv2[2]*rhat[2] + rv2[3]*rhat[3] +
           rv1[1]*rhat1[1] + rv1[2]*rhat1[2] + rv1[3]*rhat1[3]) / (-c0)
    R10 = 1 / r
    R01 = 1 / (1 - Mr)
    R11 = R10 * R01
    R21 = R11 * R10
    R10dot = -R10 * r1dot * R10
    R01dot = R01 * Mr1 * R01
    R11dot = (-R10 * r1dot + R01 * Mr1) * R11
    D1A = R01 * R11 .* rhat
    E1A = R01 .* (R11dot .* rhat .+ R11 .* rhat1) .+ c0 * R21 .* rhat
    return (fdot[1]*D1A[1] + fdot[2]*D1A[2] + fdot[3]*D1A[3] +
            f[1]*E1A[1] + f[2]*E1A[2] + f[3]*E1A[3]) / (4π * c0)
end

function _iso41_independent_f1a(r, Np, Tp, Δr, B, Ω, ρ, c0, observers;
                                n_harmonics=3, num_src_times=64, n_rev_src=2)
    # Steady blade-fixed loads; thickness off. Same kinematics as AA ccblade path (precone=0).
    nsec = length(r)
    bpp = 2π / Ω / B
    period_src = n_rev_src * (2π / Ω)
    n_src = n_rev_src * B * num_src_times
    dt = period_src / n_src
    τs = (0:n_src-1) .* dt
    n_obs = length(observers)
    amp = zeros(n_obs, n_harmonics)
    ph = zeros(n_obs, n_harmonics)
    bpf = B * Ω / (2π)
    for (io, obs) in enumerate(observers)
        # Reception: one bpp starting after all sources can reach the observer.
        t_starts = Float64[]
        prefs = zeros(num_src_times)
        # Estimate common start from max emission delay
        t0_est = 0.0
        for τ in (0.0, period_src)
            for b in 0:B-1, i in 1:nsec
                ψ = Ω * τ + 2π * b / B
                y = (0.0, r[i] * cos(ψ), r[i] * sin(ψ))
                R = hypot(obs.x[1] - y[1], obs.x[2] - y[2], obs.x[3] - y[3])
                t0_est = max(t0_est, τ + R / c0)
            end
        end
        t_rec = t0_est .+ (0:num_src_times-1) .* (bpp / num_src_times)
        p = zeros(num_src_times)
        for (jt, t_obs) in enumerate(t_rec)
            s = 0.0
            for b in 0:B-1, i in 1:nsec
                # Retarded time: t_obs = τ + |x−y(τ)|/c0
                τ = t_obs - hypot(obs.x[1], obs.x[2] - r[i], obs.x[3]) / c0  # initial guess
                for _ in 1:12
                    ψ = Ω * τ + 2π * b / B
                    y1 = r[i] * cos(ψ)
                    y2 = r[i] * sin(ψ)
                    R = hypot(obs.x[1], obs.x[2] - y1, obs.x[3] - y2)
                    τ_new = t_obs - R / c0
                    abs(τ_new - τ) < 1e-14 && (τ = τ_new; break)
                    τ = τ_new
                end
                ψ = Ω * τ + 2π * b / B
                cψ, sψ = cos(ψ), sin(ψ)
                y = (0.0, r[i] * cψ, r[i] * sψ)
                # Velocity / accel of rotating point (Ω about +X)
                ydot = (0.0, -r[i] * Ω * sψ, r[i] * Ω * cψ)
                yddot = (0.0, -r[i] * Ω^2 * cψ, -r[i] * Ω^2 * sψ)
                # Force on fluid: [-Np, −Tp sψ, Tp cψ] (AA precone=0, +X rotation)
                f = (-Np[i], -Tp[i] * sψ, Tp[i] * cψ)
                # Steady in blade frame → inertial rate from rotation only
                fdot = (0.0, -Tp[i] * Ω * cψ, -Tp[i] * Ω * sψ)
                s += _iso41_f1a_loading_p(obs.x, y, ydot, yddot, f, fdot, c0) * Δr[i]
            end
            p[jt] = s
        end
        p .-= sum(p) / length(p)
        P = FFTW.rfft(p)
        n = length(p)
        dt_r = bpp / num_src_times
        df = 1 / max(n * dt_r, eps())
        t0 = first(t_rec)
        for H in 1:n_harmonics
            fH = H * bpf
            bin = clamp(round(Int, fH / df) + 1, 1, length(P))
            c = P[bin]
            amp[io, H] = 2 * abs(c) / n
            ph[io, H] = _wrap_phase(angle(c) - 2π * fH * t0)
        end
    end
    return amp, ph, bpf
end

# --- 41a T1_FROM_E12 ----------------------------------------------------------------

function _run_t1_from_e12()
    L = test_article_length()
    fuse = FuselageGeometry(L, 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    spec = GridSpec()
    paths = default_e11_paths()
    bpf = 200.0
    nH = 3
    D = 0.762
    # T1 blocked field (e11 free field + GEXT + blocking R2) for uncovered stations
    ff = freefield_from_e11_csv(paths.A, paths.phases, fuse, prop, spec;
                                bpf_Hz=bpf, n_harmonics=nH, anopp_spl_csv=paths.anopp_spl,
                                broadband_clip_dB=10.0)
    bl_t1 = apply_blocking(ff, fuse, prop; variant=R2)
    pts = bl_t1.pts
    # ℓ = 1 line from T1 blocked; replace covered stations with E-12 measured blocked
    e12 = _iso41_e12_measured_curve()
    k_max = spec.k_max
    line_amps = zeros(k_max, nH)
    line_phases = zeros(k_max, nH)
    covered = Dict{Int,Vector{Int}}()  # H → list of k
    uncovered = Dict{Int,Vector{Int}}()
    for p in pts
        p.ell == 1 || continue
        xD = p.x3 / D
        for H in 1:nH
            line_phases[p.k, H] = bl_t1.phases[p.k, p.ell, H]  # ANOPP Table-8 phases (via e11 loader)
            ref_pts = get(e12, H, Tuple{Float64,Float64}[])
            spl = _iso41_e12_interp(ref_pts, xD)
            if isfinite(spl)
                line_amps[p.k, H] = spl_dB_to_peak_Pa(spl)
                push!(get!(covered, H, Int[]), p.k)
            else
                line_amps[p.k, H] = bl_t1.amplitudes[p.k, p.ell, H]
                push!(get!(uncovered, H, Int[]), p.k)
            end
        end
    end
    ωH = [2π * H * bpf for H in 1:nH]
    amps, phases = extend_line_to_grid(line_amps, line_phases, pts; omega_H=ωH)
    # Blocking off: E-12 levels are already blocked; uncovered ℓ=1 kept T1-blocked; off-line = GEXT of that line.
    acoustic = cyl2d_modes(56.6; n_modes=20, NY=10)
    structural = structural_modes_from_table_d1(; n_keep=32)
    ΔA = (π * 0.508 / 18)^2
    p3 = phase3_trim(; a=0.508, L=L, theta0_deg=56.6)  # η_T = 0.5 default (same as T1)
    inp = PainInputs(fuse, prop, structural, acoustic, amps, phases, pts, ΔA;
                     sidewall=p3.sidewall, endplates=p3.ends, mech=p3.mech, m_wall=p3.m_wall)
    spec_out = interior_spl(inp; bpf_Hz=bpf, n_harmonics=nH)
    # T1 gate unchanged
    recs = evaluate_T1(spec_out)
    # Also run nominal T1 for side-by-side H1–H3
    r_t1 = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=bpf, blocking=R2)
    t1_spl = r_t1.spectrum.harmonic_SPL_dB
    tg = _read_csv_numeric(joinpath(dirname(paths.A), "t1_interior_targets.csv"))
    means = Float64.(tg[:measured_mean_SPL_dB][1:3])
    table = ValidationTableRow[]
    series = PlotSeries[]
    n_ok = 0
    max_abs = 0.0
    xs = Float64[1, 2, 3]
    y_iso = Float64[]
    y_t1 = Float64[]
    y_mean = Float64[]
    for H in 1:3
        got = spec_out.harmonic_SPL_dB[H]
        push!(y_iso, got)
        push!(y_t1, t1_spl[H])
        push!(y_mean, means[H])
        res = got - means[H]
        ok = abs(res) ≤ 4.0  # gate A; evaluate_T1 also allows gate B
        # Match evaluate_T1 verdict for this H
        rec = recs[H]
        ok = rec.result == "PASS"
        n_ok += ok
        max_abs = max(max_abs, abs(res))
        push!(table, ValidationTableRow("H$H interior SPL vs E-16 mean", Float64(H),
                                        means[H], got, res, ok))
        push!(table, ValidationTableRow("H$H T1 recorded path (info)", Float64(H),
                                        means[H], t1_spl[H], t1_spl[H] - means[H], true))
    end
    # Coverage notes as info rows
    for H in 1:3
        cov = get(covered, H, Int[])
        unc = get(uncovered, H, Int[])
        push!(table, ValidationTableRow(
            "H$H E-12 coverage: k∈$(isempty(cov) ? "∅" : string(extrema(cov))) " *
            "(uncovered k=$(isempty(unc) ? "∅" : join(sort(unique(unc)), ",")); T1-blocked kept) (info)",
            Float64(H), NaN, NaN, NaN, true))
    end
    push!(series, PlotSeries("E-16 measured mean", :reference_points, xs, y_mean; panel=1))
    push!(series, PlotSeries("T1_FROM_E12", :computed, xs, y_iso; panel=1))
    push!(series, PlotSeries("T1 (e11+GEXT+R2)", :computed_points, xs, y_t1; panel=1))
    push!(series, PlotSeries("gate ±4 dB", :reference_band, xs, y_mean;
                             ylow=y_mean .- 4, yhigh=y_mean .+ 4, panel=1))
    all_ok = n_ok == 3
    cov_note = "E-12 digitization A on ℓ=1 where X3/D is inside the digitized span; " *
               "phases = ANOPP Table-8 (same as T1 e11 loader); " *
               "off-line = GEXT of that blocked line (blocking off); " *
               "uncovered ℓ=1 stations keep T1 blocked amplitudes. " *
               "H1 span≈[-0.63,0.68], H2≈[-0.21,0.69], H3≈[-0.21,0.22] X3/D."
    return ValidationCaseResult(
        "T1_FROM_E12", _today_iso(),
        (; criterion="T1 gate unchanged (±4 dB of measured mean, H1–H3)", date="2026-10-23",
         η_T=0.5, blocking="off (E-12 already blocked)", phases="ANOPP Table 8",
         e12="e12_measured_A.csv", coverage=cov_note,
         H1_H3_iso=y_iso, H1_H3_T1=y_t1),
        table, series, all_ok ? :met : :not_met,
        "$n_ok/3 within T1 gate (max |got−mean|=$(round(max_abs; digits=2)) dB); " *
        "H1–H3 = $(round.(y_iso; digits=2)) dB (T1 = $(round.(y_t1; digits=2)) dB)",
        "V-UNIT", "",
    )
end

# --- 41b TRIM_CLOSED ----------------------------------------------------------------

function _run_trim_closed()
    mat = pf105_table()
    thick = 0.051          # 5.1 cm porous (Phase III wall thickness scale)
    m_sept = 0.5           # limp septum kg/m² (stated)
    η_sept = 0.05
    m_wall = 5.0           # backing mass for conductance
    ρ0, c0 = 1.225, 340.0
    st = TrimStack([InsulationLayer(thick, mat), LimpMass(m_sept, η_sept, "septum")])
    table = ValidationTableRow[]
    xs = Float64[]; yref = Float64[]; ygot = Float64[]
    n_ok = 0
    n_tot = 0
    max_rel = 0.0
    tol = 1e-9
    for f in mat.f_Hz
        ω = 2π * f
        Mref = _iso41_closed_two_layer(ω, thick, mat, m_sept, η_sept)
        τ_ref = 1 / abs2(Mref[1, 1])
        a11, a12, a21, a22 = Mref[1, 1], Mref[1, 2], Mref[2, 1], Mref[2, 2]
        Z1 = ρ0 * c0 - im * ω * m_wall
        β_ref = ρ0 * c0 * (-ω^2 * a21 * Z1 + im * ω * a22) / (im * ω * a11 * Z1 + a12)
        ξ_ref = real(β_ref)
        τ_got = trim_tau(st, ω)
        ξ_got = trim_conductance(st, ω, m_wall; ρ0, c0)
        for (name, ref, got) in (("τ", τ_ref, τ_got), ("ξ", ξ_ref, ξ_got))
            rel = abs(got - ref) / max(abs(ref), 1e-30)
            ok = rel ≤ tol
            n_tot += 1
            n_ok += ok
            max_rel = max(max_rel, rel)
            push!(table, ValidationTableRow("$name f=$(f) Hz", f, ref, got, got - ref, ok))
            push!(xs, f); push!(yref, ref); push!(ygot, got)
        end
    end
    series = [
        PlotSeries("closed-form M product", :reference_points, xs, yref; panel=1),
        PlotSeries("trim_tau / trim_conductance", :computed, xs, ygot; panel=1),
    ]
    return ValidationCaseResult(
        "TRIM_CLOSED", _today_iso(),
        (; criterion="≤ 1e-9 relative at Fig. A-2 frequencies", date="2026-10-23",
         stack="InsulationLayer($(thick) m PF-105) + LimpMass(m=$(m_sept), η=$(η_sept))",
         m_wall, note="closed-form M_limp·M_ins written in case; independent of stack_matrix"),
        table, series, n_ok == n_tot ? :met : :not_met,
        "$n_ok/$n_tot within ≤1e-9 relative (max rel=$(max_rel))",
        "V-UNIT", "",
    )
end

# --- 41c NR_BAND_HAND ---------------------------------------------------------------

function _run_nr_band_hand()
    # Stated inputs: one structural mode, one acoustic mode, stated losses / areas / volume.
    L = test_article_length()
    a = 0.508
    fuse = FuselageGeometry(L, a, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    fc = 400.0
    c_ω = C_OMEGA_THIRD_OCTAVE
    ρ_ext = ρ_int = 1.225
    c_ext = c_int = 340.0
    # One structural mode (Table D-1 mode 8-like scalars stated here)
    st = StructuralMode(1, 318.7, false, 1.2, 1, [1.0], [2], Float64[], Int[])
    structural = StructuralModes([st], L, a, 56.6, "NR_BAND_HAND single mode")
    # One CYL2D acoustic mode — take mode index 1 from a real solve, keep only that
    ac_full = cyl2d_modes(56.6; n_modes=5, NY=10, c0=c_int)
    ac1 = ac_full.modes[2]   # skip rigid-body-ish first if present; use second
    acoustic = Cyl2DResult(ac_full.theta0_deg, [ac1], "NR_BAND_HAND single acoustic mode",
                           ac_full.NY, ac_full.h, ac_full.c0)
    pts = grid_points(fuse, prop, GridSpec())
    amps = ones(Float64, 16, 10, 1)
    phases = zeros(Float64, 16, 10, 1)
    ΔA = (π * a / 18)^2
    # Bare cabin so τ_t = 1, ξ = 0; stated η via η_n_bare and η_r_band
    η_n_stated = 0.05
    η_r_stated = 0.08
    inp = PainInputs(fuse, prop, structural, acoustic, amps, phases, pts, ΔA;
                     η_n_bare=η_n_stated, q_max=0, q0_coupled=true,   # one q = 0 mode: it must be driven (Phase 93)
                     ρ0=ρ_ext, c0=c_ext, ρ_ext=ρ_ext, c_ext=c_ext, ρ_int=ρ_int, c_int=c_int,
                     η_r_band=Dict(fc => η_r_stated), η_n_band=Dict(fc => η_n_stated))
    got = noise_reduction_band(inp, fc; c_ω)
    # Hand Eq. (18) with independent brace arithmetic (not nr_*)
    ω = 2π * fc
    A = coupling_area(fuse)
    Abar = cylinder_surface_area(a, L)
    V = cabin_volume(inp)
    mA4_τ = (ρ_ext * c_ext * A / (2 * ω))^2
    pref = 8 / (c_ω * ω) * (Abar / V)^2 * mA4_τ * c_int^2 * ω^3
    q = 0
    ωn = 2π * cabin_frequency_3d(ac1, a, inp.L_c, q; c0=c_int)
    εn = cabin_eps_3d(ac1, q)
    ωr = 2π * st.f_Hz
    j2 = structural_joint_acceptance(st, ω; a, L, c0=c_ext)
    τ_t = 1.0
    f̄ = coupling_factor(ac1, st, inp; τ_t, q)
    # Same η path as noise_reduction_band (stated η_n_band / η_r_band + η_r''), then hand brace.
    N = acoustic_N(inp, ac1, q, fc, ωn; ξ=0.0, ξ_e=0.0, V)
    ηn = N / ωn^2
    ηrp = structural_η_r_prime(inp, st, ωr; η_r_cap=nothing, Abar)
    ηrpp = structural_loss_coupled(N, ωn, ωr, f̄, εn, st.M_r, V, A; ρ0=ρ_int, c0=c_int)
    ηrt = ηrp + ηrpp
    hand = _iso41_hand_nr_brace(ω, c_ω, ωn, ηn, ωr, ηrt)
    ratio_ref = pref * εn * j2 * f̄^2 / (st.M_r^2 * hand.D_nr) * hand.brace
    NR_ref = ratio_ref > 0 ? -10 * log10(ratio_ref) : Inf
    # Compare NR_dB (criterion ≤ 1e-9 dB)
    dNR = abs(got.NR_dB - NR_ref)
    ok = dNR ≤ 1e-9
    table = [
        ValidationTableRow("NR_dB", fc, NR_ref, got.NR_dB, got.NR_dB - NR_ref, ok),
        ValidationTableRow("ratio ⟨p_i²⟩/⟨p_e²⟩", fc, ratio_ref, got.ratio, got.ratio - ratio_ref,
                           abs(got.ratio - ratio_ref) / max(abs(ratio_ref), 1e-30) ≤ 1e-9),
    ]
    series = [
        PlotSeries("hand Eq.(18)", :reference_points, [fc], [NR_ref]; panel=1),
        PlotSeries("noise_reduction_band", :computed, [fc], [got.NR_dB]; panel=1),
    ]
    return ValidationCaseResult(
        "NR_BAND_HAND", _today_iso(),
        (; criterion="≤ 1e-9 dB", date="2026-10-23",
         fc_Hz=fc, η_n_band=η_n_stated, η_r_band=η_r_stated, η_n_used=ηn, η_r_total=ηrt,
         q_max=0, bare=true,
         note="brace/ln/arctan/D written in case; not nr_* helpers"),
        table, series, ok ? :met : :not_met,
        "NR residual=$(dNR) dB (≤1e-9)",
        "V-UNIT", "",
    )
end

# --- 41d HF_MASSLAW -----------------------------------------------------------------

function _run_hf_masslaw()
    # hf_transmission_coeffs documents field-incidence τ_f via Eq. (20), not the
    # normal-incidence τ = 1/(1+(ωm/2ρc)²). Isolation uses the documented Eq. (20).
    L = test_article_length()
    a = 0.508
    fuse = FuselageGeometry(L, a, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    m = 8.0   # limp wall surface mass [kg/m²]
    fc = 1000.0
    c_ω = C_OMEGA_THIRD_OCTAVE
    ρ_ext = ρ_int = 1.225
    c_ext = c_int = 340.0
    # One structural mode resonant in the band about fc (τ_R) and one resonant below it (τ_f): Eq. (20)
    # sums the modes resonant below the band (CR-3813 p. 24; reading corrected 2026-10-23, Phase 49)
    f_mode = fc
    st = StructuralMode(1, f_mode, true, 2.0, 1, [1.0], [2], Float64[], Int[])
    st_lo = StructuralMode(2, 0.7fc, true, 2.0, 1, [1.0], [1], Float64[], Int[])
    structural = StructuralModes([st_lo, st], L, a, 56.6, "HF_MASSLAW one in-band and one below-band limp mode")
    acoustic = cyl2d_modes(56.6; n_modes=3, NY=10, c0=c_int)
    pts = grid_points(fuse, prop, GridSpec())
    amps = ones(Float64, 16, 10, 1)
    phases = zeros(Float64, 16, 10, 1)
    ΔA = (π * a / 18)^2
    inp = PainInputs(fuse, prop, structural, acoustic, amps, phases, pts, ΔA;
                     m_wall=m, η_n_bare=0.05,
                     ρ0=ρ_ext, c0=c_ext, ρ_ext=ρ_ext, c_ext=c_ext, ρ_int=ρ_int, c_int=c_int)
    tc = hf_transmission_coeffs(inp, fc; c_ω)
    # Hand Eq. (20): τ_f = (32/π) ρ_int² (Ā/m²) Σ_{r<Δω} [j_r²]², the below-band mode only
    ω = 2π * fc
    Abar = cylinder_surface_area(a, L)
    j2 = structural_joint_acceptance(st_lo, ω; a, L, c0=c_ext)
    τ_f_ref = (32 / π) * ρ_int^2 * (Abar / m^2) * j2^2
    # Hand τ_R (printed p. 24) with the same band averages the function uses
    band = tc.band
    losses = tc.losses
    η̄_r = max(losses.η̄_r, floatmin(Float64))
    τ_R_ref = (2 * band.n_r * π^2 * c_ext * losses.η_rad_ext * losses.η_rad_int) /
              (ρ_ext * ω * η̄_r) * (4 * ρ_int * c_int / Abar)
    τ_ref = τ_f_ref + τ_R_ref
    table = ValidationTableRow[]
    n_ok = 0
    max_rel = 0.0
    tol = 1e-9
    for (name, ref, got) in (("τ_f Eq.(20)", τ_f_ref, tc.τ_f),
                              ("τ_R printed", τ_R_ref, tc.τ_R),
                              ("τ=τ_f+τ_R", τ_ref, tc.τ))
        rel = abs(got - ref) / max(abs(ref), 1e-30)
        ok = rel ≤ tol
        n_ok += ok
        max_rel = max(max_rel, rel)
        push!(table, ValidationTableRow(name, fc, ref, got, got - ref, ok))
    end
    # Document that normal-incidence mass law is NOT the function's claim (info only)
    τ_ni = 1 / (1 + (ω * m / (2 * ρ_ext * c_ext))^2)
    push!(table, ValidationTableRow(
        "normal-incidence τ=1/(1+(ωm/2ρc)²), not used: the function is Eq. (20) field incidence (info)",
        fc, τ_ni, tc.τ, tc.τ - τ_ni, true, "normal incidence (info)"))   # Phase 81a: out of the chip
    series = [
        PlotSeries("hand Eq.(20) τ", :reference_points, [1.0, 2.0, 3.0],
                   [τ_f_ref, τ_R_ref, τ_ref]; panel=1),
        PlotSeries("hf_transmission_coeffs", :computed, [1.0, 2.0, 3.0],
                   [tc.τ_f, tc.τ_R, tc.τ]; panel=1),
    ]
    return ValidationCaseResult(
        "HF_MASSLAW", _today_iso(),
        (; criterion="≤ 1e-9 relative", date="2026-10-23",
         formula="field-incidence Eq. (20) τ_f + printed τ_R (not normal-incidence mass law)",
         m_wall=m, fc_Hz=fc, single_mode_Hz=f_mode, below_mode_Hz=0.7fc),
        table, series, n_ok == 3 ? :met : :not_met,
        "$n_ok/3 within ≤1e-9 relative (max rel=$(max_rel))",
        "V-UNIT", "",
    )
end

# --- 41e BEMT_HAND ------------------------------------------------------------------

function _run_bemt_hand()
    # Constant-chord, constant-twist blade; cl = 2π α, cd = 0; forward flight; tip loss off.
    Rtip = 1.0
    Rhub = 0.2
    B = 2
    nsec = 8
    chord0 = 0.1
    twist_deg = 15.0
    rpm = 1200.0
    Ω = rpm * 2π / 60
    Vinf = 20.0   # forward flight (stated)
    ρ = 1.225
    c0 = 340.0
    r = collect(range(Rhub + 0.02, Rtip - 0.02; length=nsec))
    chord = fill(chord0, nsec)
    twist = fill(twist_deg, nsec)
    af = (α, Re, M) -> (2π * α, 0.0)
    cfg = (
        propeller = (
            num_blades = B,
            tip_radius_m = Rtip,
            hub_radius_m = Rhub,
            rpm = rpm,
            thickness_over_chord = 0.0,
            pitch_offset_deg = 0.0,
            radii_m = r,
            chord_m = chord,
            twist_deg = twist,
        ),
        operating_point = (forward_speed_mps = Vinf, rho_kg_m3 = ρ, c0_mps = c0),
        anopp_table8_calibrate = false,
    )
    obs = [Observer([10.0, 0.0, 0.0], [Vinf, 0.0, 0.0], "far")]
    src = evaluate_propeller_source(cfg, obs; n_harmonics=1, num_src_times=16,
                                    af=af, allow_static=true, use_tip_correction=false)
    # Hand BEM (same residual as CCBlade, F=1). Integrate like CCBlade.thrusttorque:
    # pad Np/Tp = 0 at Rhub/Rtip, then trapezoidal in r (precone = 0).
    Np = Float64[]; Tp = Float64[]
    for i in 1:nsec
        Vy = Ω * r[i]
        out = _iso41_hand_bem_solve_phi(r[i], chord[i], deg2rad(twist[i]), Rhub, Rtip,
                                        Vinf, Vy, ρ, B)
        push!(Np, out.Np)
        push!(Tp, out.Tp)
    end
    rfull = [Rhub; r; Rtip]
    Npfull = [0.0; Np; 0.0]
    Tpfull = [0.0; Tp; 0.0]
    function _trapz(x, y)
        s = 0.0
        for i in 1:length(x)-1
            s += 0.5 * (y[i] + y[i+1]) * (x[i+1] - x[i])
        end
        return s
    end
    T_hand = B * _trapz(rfull, Npfull)
    Q_hand = B * _trapz(rfull, Tpfull .* rfull)
    table = ValidationTableRow[]
    n_ok = 0
    max_rel = 0.0
    for (name, ref, got) in (("thrust T", T_hand, src.T), ("torque Q", Q_hand, src.Q))
        rel = abs(got - ref) / max(abs(ref), 1e-30)
        ok = rel ≤ 0.01
        n_ok += ok
        max_rel = max(max_rel, rel)
        push!(table, ValidationTableRow(name, 1.0, ref, got, got - ref, ok))
    end
    series = [
        PlotSeries("hand BEM", :reference_points, [1.0, 2.0], [T_hand, Q_hand]; panel=1),
        PlotSeries("CCBlade wrapper (tip off)", :computed, [1.0, 2.0], [src.T, src.Q]; panel=1),
    ]
    return ValidationCaseResult(
        "BEMT_HAND", _today_iso(),
        (; criterion="within 1 %", date="2026-10-23",
         Vinf_mps=Vinf, rpm, B, chord_m=chord0, twist_deg, tip="off (use_tip_correction=false)",
         cl="2π α", cd=0.0, note="hand residual matches CCBlade residual_and_outputs with F=1"),
        table, series, n_ok == 2 ? :met : :not_met,
        "$n_ok/2 within 1 % (max rel=$(round(100*max_rel; digits=4)) %)",
        "V-UNIT", "",
    )
end

# --- 41f F1A_INDEP ------------------------------------------------------------------

function _run_f1a_indep()
    # Same loads as evaluate_propeller_source for R996 Fig.12-like: β=10°, M_t=0.75, B=2;
    # observer x/D=−0.125 and page-12 pair ±0.125; thickness off; linear polar for isolation.
    D = 1.2192
    Mt = 0.75
    a_sound = 340.3
    ρ = 1.225
    beta75 = 10.0
    B = 2
    bf = _data_path("report996", "naca_4-5-08-03", "blade_form.csv")
    g = blade_form_geometry(bf; D=D, beta75_target_deg=beta75)
    rpm = Mt * a_sound * 60 / (π * D)
    cfg = (
        propeller = (
            num_blades = B,
            tip_radius_m = g.R,
            hub_radius_m = g.radii_m[1],
            rpm = rpm,
            thickness_over_chord = 0.0,
            pitch_offset_deg = 0.0,
            radii_m = collect(g.radii_m),
            chord_m = collect(g.chord_m),
            twist_deg = collect(g.twist_deg),
        ),
        operating_point = (forward_speed_mps = 0.0, rho_kg_m3 = ρ, c0_mps = a_sound),
        anopp_table8_calibrate = false,
    )
    # Linear polar (isolation of F1A, not polars): cl=2πα, cd=0
    af = (α, Re, M) -> (2π * clamp(α, -0.35, 0.35), 0.0)
    R = g.R
    xDs = [-0.125, 0.125]
    obs = hub_observers(R, D; x_over_D=xDs, d_over_D=0.083, x_sign=R996_X_SIGN)
    nH = 2
    nsrc = 64
    src = evaluate_propeller_source(cfg, obs; n_harmonics=nH, num_src_times=nsrc,
                                    af=af, allow_static=true, use_tip_correction=true)
    # Identical section loads: re-solve CCBlade the same way
    Ω = rpm * 2π / 60
    r = collect(g.radii_m)
    nsec = length(r)
    chord = collect(g.chord_m)
    theta = collect(g.twist_deg) .* (π / 180)
    rotor = CCBlade.Rotor(g.radii_m[1], R, B)
    sections = [CCBlade.Section(r[i], chord[i], theta[i], af) for i in 1:nsec]
    ops = [CCBlade.OperatingPoint(0.0, Ω * r[i], ρ; asound=a_sound) for i in 1:nsec]
    outs = CCBlade.solve.(Ref(rotor), sections, ops)
    Np = Float64[outs[i].Np for i in 1:nsec]
    Tp = Float64[outs[i].Tp for i in 1:nsec]
    # Element widths
    edges = zeros(nsec + 1)
    edges[1] = g.radii_m[1]
    edges[end] = R
    for i in 1:nsec-1
        edges[i+1] = 0.5 * (r[i] + r[i+1])
    end
    Δr = [edges[i+1] - edges[i] for i in 1:nsec]
    amp_i, ph_i, bpf = _iso41_independent_f1a(r, Np, Tp, Δr, B, Ω, ρ, a_sound, obs;
                                              n_harmonics=nH, num_src_times=nsrc, n_rev_src=2)
    table = ValidationTableRow[]
    n_ok = 0
    max_dB = 0.0
    max_dφ = 0.0
    # Amplitude at x/D=−0.125 (observer 1), H1 and H2
    for H in 1:nH
        A_aa = src.amplitude[1, H]
        A_ind = amp_i[1, H]
        dB = 20 * log10(max(A_ind, 1e-30) / max(A_aa, 1e-30))
        ok = abs(dB) ≤ 0.5
        n_ok += ok
        max_dB = max(max_dB, abs(dB))
        push!(table, ValidationTableRow("H$H amp x/D=-0.125 (dB vs AA)", Float64(H),
                                        0.0, dB, dB, ok))
    end
    # Page-12 phase difference |Δφ| between ±0.125 at H2 (same rule as R996_PHASE)
    dφ_aa = abs(src.phase[1, 2] - src.phase[2, 2])
    dφ_aa = min(dφ_aa, 2π - dφ_aa) * 180 / π
    dφ_i = abs(ph_i[1, 2] - ph_i[2, 2])
    dφ_i = min(dφ_i, 2π - dφ_i) * 180 / π
    dφ_err = abs(dφ_i - dφ_aa)
    ok_φ = dφ_err ≤ 2.0
    n_ok += ok_φ
    max_dφ = dφ_err
    push!(table, ValidationTableRow("H2 phase |Δφ| ±0.125 (deg)", 2.0, dφ_aa, dφ_i, dφ_i - dφ_aa, ok_φ))
    series = [
        PlotSeries("AcousticAnalogies F1A", :reference_points, [1.0, 2.0],
                   [20*log10(max(src.amplitude[1, 1], 1e-30)),
                    20*log10(max(src.amplitude[1, 2], 1e-30))]; panel=1),
        PlotSeries("independent F1A", :computed, [1.0, 2.0],
                   [20*log10(max(amp_i[1, 1], 1e-30)),
                    20*log10(max(amp_i[1, 2], 1e-30))]; panel=1),
    ]
    return ValidationCaseResult(
        "F1A_INDEP", _today_iso(),
        (; criterion="amplitude within 0.5 dB, phase within 2°", date="2026-10-23",
         config="R996 Fig.12-like β=10° Mt=0.75 B=2; linear cl=2πα cd=0; thickness off",
         observers="x/D=±0.125, d/D=0.083, x_sign=R996_X_SIGN (+1, Phase 72)",
         note="independent retarded-time Farassat 1A loading; same CCBlade Np,Tp"),
        table, series, n_ok == 3 ? :met : :not_met,
        "$n_ok/3 (max |ΔdB|=$(round(max_dB; digits=3)), |Δφ err|=$(round(max_dφ; digits=2))°)",
        "V-CODE", "",
    )
end

"""Phase-41 isolation cases for failing experimental checks."""
function _iso41_validation_cases()
    return [
        ValidationCase("T1_FROM_E12", "T1 cabin tones from measured E-12 blocked pressures (41a)", "41",
            [_data_path("cr3813", "e12", "e12_measured_A.csv"),
             _data_path("cr3813", "t1_interior_targets.csv")],
            FigureRef("CR-3813", "Fig. E-12 / E-16", 136),
            "T1 gate unchanged (±4 dB of measured E-16 mean, H1–H3).",
            "2026-10-23", "V-UNIT", _run_t1_from_e12,
            PlotSpec(; xlabel="harmonic", ylabel="interior SPL (dB)",
                     panel_titles=["T1_FROM_E12 vs E-16"],
                     error_mode=:absolute, error_tol=4.0, error_ylabel="dB vs mean"), ""),
        ValidationCase("TRIM_CLOSED", "Two-layer trim vs closed-form transfer-matrix product (41b)", "41",
            [_data_path("cr3813", "fig_a2_pf105.csv")],
            FigureRef("CR-3813", "App. A / Fig. A-2", nothing),
            "≤ 1e-9 relative on trim_tau and trim_conductance at Fig. A-2 frequencies.",
            "2026-10-23", "V-UNIT", _run_trim_closed,
            PlotSpec(; xlabel="f (Hz)", ylabel="τ or ξ", xscale=:log10,
                     panel_titles=["TRIM_CLOSED"],
                     error_mode=:relative_pct, error_tol=1e-7, error_ylabel="%"), ""),
        ValidationCase("NR_BAND_HAND", "One-band noise_reduction_band vs hand Eqs. (17)–(18) (41c)", "41",
            String[], FigureRef("CR-3813", "Eqs. (17)–(18)", nothing),
            "≤ 1e-9 dB against hand evaluation of Eq. (18) (brace written in case).",
            "2026-10-23", "V-UNIT", _run_nr_band_hand,
            PlotSpec(; xlabel="band Hz", ylabel="NR (dB)",
                     panel_titles=["NR_BAND_HAND"],
                     error_mode=:absolute, error_tol=1e-9, error_ylabel="dB"), ""),
        ValidationCase("HF_MASSLAW", "hf_transmission_coeffs vs hand Eq. (20) field-incidence (41d)", "41",
            String[], FigureRef("CR-3813", "Eq. (20)", nothing),
            "≤ 1e-9 relative against hand Eq. (20) τ_f + printed τ_R (field-incidence; not normal-incidence mass law).",
            "2026-10-23", "V-UNIT", _run_hf_masslaw,
            PlotSpec(; xlabel="term", ylabel="τ",
                     panel_titles=["HF_MASSLAW"],
                     error_mode=:relative_pct, error_tol=1e-7, error_ylabel="%"), ""),
        ValidationCase("BEMT_HAND", "CCBlade wrapper vs hand BEM (cl=2πα, cd=0, tip off) (41e)", "41",
            String[], FigureRef("—", "analytic BEM", nothing),
            "thrust and torque within 1 % of hand blade-element/momentum solution (tip loss off).",
            "2026-10-23", "V-UNIT", _run_bemt_hand,
            PlotSpec(; xlabel="quantity", ylabel="T [N] or Q [N·m]",
                     panel_titles=["BEMT_HAND"],
                     error_mode=:relative_pct, error_tol=1.0, error_ylabel="%"), ""),
        ValidationCase("F1A_INDEP", "Independent Farassat 1A vs AcousticAnalogies (same loads) (41f)", "41",
            [_data_path("report996", "naca_4-5-08-03", "blade_form.csv")],
            FigureRef("NACA Report 996", "Fig. 12 / page 12", nothing),
            "amplitude within 0.5 dB, phase within 2° (code-on-code).",
            "2026-10-23", "V-CODE", _run_f1a_indep,
            PlotSpec(; xlabel="harmonic", ylabel="20 log10 A (dB)",
                     panel_titles=["F1A_INDEP x/D=-0.125"],
                     error_mode=:absolute, error_tol=0.5, error_ylabel="dB"), ""),
    ]
end
