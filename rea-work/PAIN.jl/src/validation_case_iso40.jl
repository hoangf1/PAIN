# Phase 40 — isolated analytic checks (V-UNIT). Criteria fixed 2026-10-23 in
# IMPLEMENTATION_PLAN.md §8b; do not change tolerances. References are independent
# closed forms / quadrature written here — never the function under test.

# --- helpers (independent of the code under test) ---------------------------------

"""Series Bessel J_n(x) for integer n ≥ 0 (independent of any PAIN Bessel helper)."""
function _iso_besselj(n::Int, x::Float64)
    n < 0 && return _iso_besselj(-n, x) * (isodd(-n) ? -1 : 1)
    x = abs(x)
    # series (x/2)^n / n! * Σ (-1)^k (x/2)^{2k} / (k! (n+k)!)
    term = (x / 2)^n
    for i in 1:n
        term /= i
    end
    s = term
    for k in 1:80
        term *= -(x / 2)^2 / (k * (n + k))
        s += term
        abs(term) < 1e-18 * (1 + abs(s)) && break
    end
    return s
end

"""J'_n(x) = n/x J_n − J_{n+1} (n≥0; at x=0: 0.5 for n=1, 0 for n≠1)."""
function _iso_besselj_prime(n::Int, x::Float64)
    n = abs(n)
    if abs(x) < 1e-14
        return n == 1 ? 0.5 : 0.0
    end
    return (n / x) * _iso_besselj(n, x) - _iso_besselj(n + 1, x)
end

"""First `nzeros` positive zeros of J'_m by scan + bisection (Abramowitz & Stegun §9.5; independent of PAIN)."""
function _iso_jprime_zeros(m::Int, nzeros::Int)
    m ≥ 0 || error("m ≥ 0")
    out = Float64[]
    # J'_m(0)=0 is the trivial Neumann root (m=0 rigid body); skip x ≲ 0.5
    x = 0.5
    dx = 0.02
    while length(out) < nzeros && x < 200.0
        x1 = x + dx
        f0 = _iso_besselj_prime(m, x)
        f1 = _iso_besselj_prime(m, x1)
        if f0 * f1 ≤ 0
            a, b = x, x1
            fa = f0
            for _ in 1:80
                mid = 0.5 * (a + b)
                fm = _iso_besselj_prime(m, mid)
                if fa * fm ≤ 0
                    b = mid
                else
                    a = mid
                    fa = fm
                end
            end
            z = 0.5 * (a + b)
            if z > 0.5 && (isempty(out) || z > out[end] + 0.05)
                # polish with Newton
                for _ in 1:20
                    jp = _iso_besselj_prime(m, z)
                    j = _iso_besselj(m, z)
                    jpp = -jp / z - (1 - (m / z)^2) * j
                    abs(jpp) < 1e-30 && break
                    znew = z - jp / jpp
                    abs(znew - z) < 1e-14 * z && (z = znew; break)
                    z = znew
                end
                push!(out, z)
            end
        end
        x = x1
    end
    length(out) >= nzeros || error("J′_$m: only $(length(out)) positive zeros found, need $nzeros")
    return out[1:nzeros]
end

"""Exact rigid-wall circular cross-mode frequencies f = c·j'_{m,s}/(2πa) for a=1, ordered with m≥1 multiplicity 2."""
function _iso_circle_mode_freqs(c0::Float64, n_modes::Int)
    # First ~10 modes only need m ≲ 6 and s ≲ 3 (j′ ≲ 6); keep the search small.
    max_m = 8
    max_s = 4
    cands = Tuple{Float64,Int,Int}[]  # f, m, s
    for m in 0:max_m
        zs = _iso_jprime_zeros(m, max_s)
        for s in 1:max_s
            push!(cands, (c0 * zs[s] / (2π), m, s))
        end
    end
    sort!(cands; by=c -> c[1])
    freqs = Float64[0.0]   # rigid body (j'=0 at origin)
    for (f, m, s) in cands
        length(freqs) ≥ n_modes && break
        push!(freqs, f)
        m ≥ 1 && length(freqs) < n_modes && push!(freqs, f)  # cos/sin pair
    end
    return freqs[1:n_modes]
end

"""Adaptive Simpson on [a,b] (independent quadrature; no QuadGK dependency)."""
function _iso_simpson(f, a::Float64, b::Float64; tol::Float64=1e-10, max_depth::Int=20)
    function helper(fa, fb, fm, a, b, tol, depth)
        h = b - a
        m = 0.5 * (a + b)
        f1 = f(0.5 * (a + m))
        f2 = f(0.5 * (m + b))
        i1 = (h / 6) * (fa + 4 * fm + fb)
        i2 = (h / 12) * (fa + 4 * f1 + 2 * fm + 4 * f2 + fb)   # not `4f1`: that is the Float32 literal 40
        if depth <= 0 || abs(i2 - i1) < 15 * tol
            return i2 + (i2 - i1) / 15
        end
        return helper(fa, fm, f1, a, m, tol / 2, depth - 1) +
               helper(fm, fb, f2, m, b, tol / 2, depth - 1)
    end
    fa, fb = f(a), f(b)
    fm = f(0.5 * (a + b))
    return helper(fa, fb, fm, a, b, tol, max_depth)
end

"""Direct 2-D quadrature of ring joint acceptance (ζ = a|θ1−θ2| form behind Eqs. 65–73)."""
function _iso_ring_quad(n::Int, ka::Float64, kind::Symbol; N::Int=400)
    h = 2π / N
    th = h .* ((1:N) .- 0.5)
    ff = kind === :psi ? cos.(n .* th) : sin.(n .* th)
    s = 0.0
    for i in 1:N, j in 1:N
        x = ka * abs(th[i] - th[j])
        s += ff[i] * ff[j] * (x == 0 ? 1.0 : sin(x) / x)
    end
    return s * h * h / (2π * (n == 0 ? 2π : π))
end

function _iso_axial_quad(M::Int, kL::Float64; N::Int=800)
    h = 1 / N
    z = h .* ((1:N) .- 0.5)
    ff = sin.(M * π .* z)
    s = 0.0
    for i in 1:N, j in 1:N
        x = kL * abs(z[i] - z[j])
        s += ff[i] * ff[j] * (x == 0 ? 1.0 : sin(x) / x)
    end
    return s * h * h / 0.5
end

"""
Independent joint acceptance for one structural mode (Eq. 66 form) by direct quadrature.
`printed=false`: mode-normalized. `printed=true`: the printed Eqs. (63), (69)–(70), which are half of the
mode-normalized value for the axial factor and for ring terms with n > 0 (Eq. 65, n = 0, is full), applied term by term.
"""
function _iso_joint_acceptance_quad(mode::StructuralMode, ω::Real; a::Real, L::Real, c0::Real=340.0,
                                    printed::Bool=false)
    k = ω / c0
    jM = _iso_axial_quad(mode.M_axial, k * L) * (printed ? 0.5 : 1.0)
    jN = 0.0
    for (C, n) in zip(mode.C_shell, mode.n_shell)
        half = printed && n > 0 ? 0.5 : 1.0
        if mode.symmetric
            jN += C^2 * half * _iso_ring_quad(n, k * a, :psi)
        elseif n ≥ 1
            jN += C^2 * half * _iso_ring_quad(n, k * a, :phi)
        end
    end
    return jM * jN
end

# --- 40a ISO_BLOCKING ----------------------------------------------------------------

function _run_iso_blocking()
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    pts = grid_points(fuse, prop, GridSpec())
    nH = 3
    amps0 = Array{Float64}(undef, 16, 10, nH)
    phases0 = Array{Float64}(undef, 16, 10, nH)
    for p in pts
        for H in 1:nH
            amps0[p.k, p.ell, H] = 0.5 + 0.01 * p.k + 0.02 * p.ell + 0.03 * H
            phases0[p.k, p.ell, H] = 0.1 * p.k - 0.05 * p.ell + 0.02 * H
        end
    end
    ff = FreeFieldHarmonicGrid(pts, collect(1:nH), copy(amps0), copy(phases0),
                               :synthetic, "ISO_BLOCKING", 200.0)
    got = apply_blocking(ff, fuse, prop; variant=R1)
    table = ValidationTableRow[]
    xs = Float64[]; yref = Float64[]; ygot = Float64[]
    n_ok = 0
    n_tot = 0
    max_rel = 0.0
    tol = 1e-12
    for p in pts
        γ = incidence_angle_deg(fuse, prop, p.theta_deg, p.z)
        F = blocking_factor(γ; variant=R1)
        for H in 1:nH
            ref_A = F * amps0[p.k, p.ell, H]
            comp_A = got.amplitudes[p.k, p.ell, H]
            rel = abs(comp_A - ref_A) / max(abs(ref_A), 1e-30)
            ok = rel ≤ tol
            # phases unchanged
            ref_ϕ = phases0[p.k, p.ell, H]
            comp_ϕ = got.phases[p.k, p.ell, H]
            rel_ϕ = abs(comp_ϕ - ref_ϕ) / max(abs(ref_ϕ), 1e-30)
            ok_ϕ = abs(comp_ϕ - ref_ϕ) ≤ tol * max(1.0, abs(ref_ϕ))  # absolute for near-zero
            n_tot += 2
            n_ok += ok
            n_ok += ok_ϕ
            max_rel = max(max_rel, rel, abs(comp_ϕ - ref_ϕ))
            idx = Float64((p.k - 1) * 10 + p.ell) + 0.1 * H
            push!(table, ValidationTableRow("A k=$(p.k) ℓ=$(p.ell) H$H", idx, ref_A, comp_A, comp_A - ref_A, ok))
            push!(table, ValidationTableRow("φ k=$(p.k) ℓ=$(p.ell) H$H", idx, ref_ϕ, comp_ϕ, comp_ϕ - ref_ϕ, ok_ϕ))
            push!(xs, idx); push!(yref, ref_A); push!(ygot, comp_A)
        end
    end
    series = [
        PlotSeries("F(γ)·A (independent)", :reference_points, xs, yref; panel=1),
        PlotSeries("apply_blocking", :computed, xs, ygot; panel=1),
    ]
    return ValidationCaseResult(
        "ISO_BLOCKING", _today_iso(),
        (; criterion="max relative difference ≤ 1e-12", date="2026-10-23",
         n_points=length(pts), nH, max_rel=max_rel, variant=:R1),
        table, series, n_ok == n_tot ? :met : :not_met,
        "$n_ok/$n_tot within ≤1e-12 rel (max residual=$(max_rel))",
        "V-UNIT", "",
    )
end

# --- 40b ISO_FF_CONV -----------------------------------------------------------------

function _run_iso_ff_conv()
    table = ValidationTableRow[]
    xs = Float64[]; yref = Float64[]; ygot = Float64[]
    n_ok = 0
    n_tot = 0
    max_rel = 0.0
    tol = 1e-12
    # SPL ↔ Pa ↔ SPL (I-17 peak convention)
    for (i, spl) in enumerate((40.0, 80.0, 100.0, 120.0, 140.0))
        # independent: p_rms = 20e-6 * 10^(SPL/20); A = √2 p_rms; SPL back from A
        p_rms_ref = 20e-6 * 10^(spl / 20)
        A_ref = sqrt(2) * p_rms_ref
        A_got = spl_dB_to_peak_Pa(spl)
        spl_back_ref = 20 * log10(A_ref / (sqrt(2) * 20e-6))
        spl_back = peak_Pa_to_spl_dB(A_got)
        p_rms_got = spl_dB_to_Pa(spl)
        for (qty, ref, got, x) in (
            ("A_peak from SPL", A_ref, A_got, Float64(i)),
            ("p_rms from SPL", p_rms_ref, p_rms_got, Float64(i) + 0.2),
            ("SPL from A_peak", spl_back_ref, spl_back, Float64(i) + 0.4),
        )
            rel = abs(got - ref) / max(abs(ref), 1e-30)
            ok = rel ≤ tol
            n_tot += 1
            n_ok += ok
            max_rel = max(max_rel, rel)
            push!(table, ValidationTableRow("$qty SPL=$spl", x, ref, got, got - ref, ok))
            push!(xs, x); push!(yref, ref); push!(ygot, got)
        end
    end
    # ℓ = 1 line of freefield_from_e11_csv vs hand conversion of the CSV (no GEXT off-line)
    paths = default_e11_paths()
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    # Load without ANOPP clip so the CSV hand conversion matches the loader's ℓ=1 values
    # Use mean of A (same file the loader reads). Match freefield_from_e11_csv with anopp for H≥3.
    grid = freefield_from_e11_csv(paths.A, paths.phases, fuse, prop, GridSpec();
                                  bpf_Hz=200.0, n_harmonics=3, anopp_spl_csv=paths.anopp_spl)
    amp = _read_csv_numeric(paths.A)
    ph = _read_csv_numeric(paths.phases)
    anopp = _read_csv_numeric(paths.anopp_spl)
    ks = Int.(round.(amp[:k]))
    for (i, k) in enumerate(ks)
        1 ≤ k ≤ 16 || continue
        for H in 1:3
            key = H == 1 ? :SPL_H1_dB : H == 2 ? :SPL_H2_dB : :SPL_H3_dB
            spl = amp[key][i]
            jA = findfirst(==(float(k)), anopp[:k])
            if jA !== nothing
                spl_a = anopp[key][jA]
                if H >= 3
                    spl = spl_a
                elseif spl - spl_a > 10.0
                    spl = spl_a
                end
            end
            A_ref = sqrt(2) * 20e-6 * 10^(spl / 20)   # hand peak conversion
            A_got = grid.amplitudes[k, 1, H]
            pkey = H == 1 ? :phase_H1_deg : H == 2 ? :phase_H2_deg : :phase_H3_deg
            j = findfirst(==(float(k)), ph[:k])
            ϕ_ref = deg2rad(ph[pkey][j])
            # rotation_direction=+1 leaves phase as stored
            ϕ_got = grid.phases[k, 1, H]
            for (qty, ref, got) in (("A ℓ=1 k=$k H$H", A_ref, A_got),
                                    ("φ ℓ=1 k=$k H$H", ϕ_ref, ϕ_got))
                rel = abs(got - ref) / max(abs(ref), 1e-30)
                ok = (qty[1] == 'φ') ? abs(got - ref) ≤ tol * max(1.0, abs(ref)) : rel ≤ tol
                n_tot += 1
                n_ok += ok
                max_rel = max(max_rel, rel, abs(got - ref))
                x = Float64(10 + k) + 0.1 * H
                push!(table, ValidationTableRow(qty, x, ref, got, got - ref, ok))
                push!(xs, x); push!(yref, ref); push!(ygot, got)
            end
        end
    end
    series = [
        PlotSeries("hand / closed form", :reference_points, xs, yref; panel=1),
        PlotSeries("conversions / loader", :computed, xs, ygot; panel=1),
    ]
    return ValidationCaseResult(
        "ISO_FF_CONV", _today_iso(),
        (; criterion="≤ 1e-12 relative", date="2026-10-23", max_rel=max_rel,
         csv_amp=paths.A, csv_phase=paths.phases),
        table, series, n_ok == n_tot ? :met : :not_met,
        "$n_ok/$n_tot within ≤1e-12 rel (max residual=$(max_rel))",
        "V-UNIT", "",
    )
end

# --- 40c ISO_GEXT_LINE ---------------------------------------------------------------

function _run_iso_gext_line()
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    pts = grid_points(fuse, prop, GridSpec())
    nH = 3
    line_amps = [0.5 + 0.03 * k + 0.1 * H for k in 1:16, H in 1:nH]
    line_phases = [0.2 * k - 0.05 * H for k in 1:16, H in 1:nH]
    ωH = [2π * H * 200.0 for H in 1:nH]
    table = ValidationTableRow[]
    xs = Float64[]; yref = Float64[]; ygot = Float64[]
    n_ok = 0
    n_tot = 0
    max_rel = 0.0
    tol = 1e-12
    # Every option: on ℓ=1, falloff=1 and delay=0 → identity
    option_sets = [
        (; falloff_exponent=1.0, falloff_floor=0.0, delay_scale=1.0),
        (; falloff_exponent=0.0, falloff_floor=0.0, delay_scale=1.0),
        (; falloff_exponent=2.0, falloff_floor=0.1, delay_scale=0.0),
        (; falloff_exponent=1.0, falloff_floor=0.0, delay_scale=-1.0),
        (; falloff_exponent=1.0, falloff_floor=0.5, delay_scale=1.0),
    ]
    for (oi, opt) in enumerate(option_sets)
        amps, phases = extend_line_to_grid(line_amps, line_phases, pts; omega_H=ωH,
                                           falloff_exponent=opt.falloff_exponent,
                                           falloff_floor=opt.falloff_floor,
                                           delay_scale=opt.delay_scale)
        for p in pts
            p.ell == 1 || continue
            for H in 1:nH
                ref_A = line_amps[p.k, H]
                ref_ϕ = line_phases[p.k, H]
                got_A = amps[p.k, p.ell, H]
                got_ϕ = phases[p.k, p.ell, H]
                rel_A = abs(got_A - ref_A) / max(abs(ref_A), 1e-30)
                ok_A = rel_A ≤ tol
                ok_ϕ = abs(got_ϕ - ref_ϕ) ≤ tol * max(1.0, abs(ref_ϕ))
                n_tot += 2
                n_ok += ok_A
                n_ok += ok_ϕ
                max_rel = max(max_rel, rel_A, abs(got_ϕ - ref_ϕ))
                x = Float64(oi * 100 + p.k) + 0.1 * H
                push!(table, ValidationTableRow("A ℓ=1 opt$oi k=$(p.k) H$H", x, ref_A, got_A, got_A - ref_A, ok_A))
                push!(table, ValidationTableRow("φ ℓ=1 opt$oi k=$(p.k) H$H", x, ref_ϕ, got_ϕ, got_ϕ - ref_ϕ, ok_ϕ))
                push!(xs, x); push!(yref, ref_A); push!(ygot, got_A)
            end
        end
    end
    series = [
        PlotSeries("line input (ℓ=1)", :reference_points, xs, yref; panel=1),
        PlotSeries("extend_line_to_grid ℓ=1", :computed, xs, ygot; panel=1),
    ]
    return ValidationCaseResult(
        "ISO_GEXT_LINE", _today_iso(),
        (; criterion="≤ 1e-12 on ℓ=1; off-line V-ASSUMED", date="2026-10-23",
         max_rel=max_rel, n_option_sets=length(option_sets)),
        table, series, n_ok == n_tot ? :met : :not_met,
        "$n_ok/$n_tot within ≤1e-12 on ℓ=1 (max residual=$(max_rel)); off-line not checked",
        "V-UNIT", "",
    )
end

# --- 40d ISO_TABLE8 ------------------------------------------------------------------

function _run_iso_table8()
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    pts = grid_points(fuse, prop, GridSpec())
    t8path = _data_path("cr3813", "anopp_table8_spl_dB.csv")
    anopp = _read_csv_numeric(t8path)
    nH = 3
    amps = zeros(16, 10, nH)
    phases = zeros(16, 10, nH)
    # Set ℓ=1 peaks equal to Table-8 peaks (hand-converted); fill all points with same harmonic amplitude
    for H in 1:nH
        key = H == 1 ? :SPL_H1_dB : H == 2 ? :SPL_H2_dB : :SPL_H3_dB
        peak = maximum(spl_dB_to_peak_Pa.(anopp[key]))
        amps[:, :, H] .= peak
    end
    grid = FreeFieldHarmonicGrid(pts, collect(1:nH), copy(amps), copy(phases),
                                 :synthetic, "ISO_TABLE8 identity", 200.0)
    calibrated, scales = apply_table8_calibration(grid, t8path)
    table = ValidationTableRow[]
    xs = Float64[]; yref = Float64[]; ygot = Float64[]
    n_ok = 0
    n_tot = 0
    max_rel = 0.0
    tol = 1e-12
    for p in pts
        for H in 1:nH
            ref = amps[p.k, p.ell, H]
            got = calibrated.amplitudes[p.k, p.ell, H]
            rel = abs(got - ref) / max(abs(ref), 1e-30)
            ok = rel ≤ tol
            n_tot += 1
            n_ok += ok
            max_rel = max(max_rel, rel)
            x = Float64((p.k - 1) * 10 + p.ell) + 0.1 * H
            push!(table, ValidationTableRow("A k=$(p.k) ℓ=$(p.ell) H$H", x, ref, got, got - ref, ok))
            push!(xs, x); push!(yref, ref); push!(ygot, got)
        end
    end
    for (i, s) in enumerate(scales)
        # identity → scale = 1
        ok = abs(s - 1.0) ≤ tol
        n_tot += 1
        n_ok += ok
        max_rel = max(max_rel, abs(s - 1.0))
        push!(table, ValidationTableRow("scale H$i", Float64(1000 + i), 1.0, s, s - 1.0, ok))
    end
    series = [
        PlotSeries("pre-cal amplitudes", :reference_points, xs, yref; panel=1),
        PlotSeries("after Table-8 cal", :computed, xs, ygot; panel=1),
    ]
    return ValidationCaseResult(
        "ISO_TABLE8", _today_iso(),
        (; criterion="≤ 1e-12 (identity when peaks equal)", date="2026-10-23",
         max_rel=max_rel, scales=scales, csv=t8path),
        table, series, n_ok == n_tot ? :met : :not_met,
        "$n_ok/$n_tot within ≤1e-12 (max residual=$(max_rel))",
        "V-UNIT", "",
    )
end

# --- 40e ISO_CYL2D_EXACT -------------------------------------------------------------

function _run_iso_cyl2d_exact()
    c0 = 340.0
    θ0 = 0.0   # floor at y=−1 coincides with the wall; floor width 0 (floorless circle)
    n_modes = 10
    ref = _iso_circle_mode_freqs(c0, n_modes)
    r10 = cyl2d_modes(θ0; n_modes=n_modes, NY=10, c0=c0)
    r20 = cyl2d_modes(θ0; n_modes=n_modes, NY=20, c0=c0)
    table = ValidationTableRow[]
    xs = Float64[]; yref = Float64[]; y10 = Float64[]; y20 = Float64[]
    n_ok = 0
    n_tot = 0
    max_rel_20 = 0.0
    max_rel_10 = 0.0
    tol = 0.02
    improve_ok = true
    for i in 1:n_modes
        fref = ref[i]
        f10 = r10.modes[i].f_Hz_unit
        f20 = r20.modes[i].f_Hz_unit
        e10 = fref == 0 ? abs(f10) : abs(f10 - fref) / fref
        e20 = fref == 0 ? abs(f20) : abs(f20 - fref) / fref
        max_rel_10 = max(max_rel_10, e10)
        max_rel_20 = max(max_rel_20, e20)
        ok20 = e20 ≤ tol
        n_tot += 1
        n_ok += ok20
        push!(table, ValidationTableRow("f mode $(i-1) NY20", Float64(i - 1), fref, f20, f20 - fref, ok20))
        push!(table, ValidationTableRow("f mode $(i-1) NY10 (info, production grid)", Float64(i - 1) + 0.5, fref, f10, f10 - fref, e10 ≤ tol))
        push!(xs, Float64(i - 1)); push!(yref, fref); push!(y20, f20); push!(y10, f10)
    end
    improve_ok = max_rel_20 < max_rel_10
    n_tot += 1
    n_ok += improve_ok
    push!(table, ValidationTableRow("max_rel NY20 < NY10", -1.0, max_rel_10, max_rel_20,
                                    max_rel_20 - max_rel_10, improve_ok))
    series = [
        PlotSeries("exact J′ zeros", :reference_points, xs, yref; panel=1),
        PlotSeries("CYL2D NY=20", :computed, xs, y20; panel=1),
        PlotSeries("CYL2D NY=10", :reference_curve, xs, y10; panel=1),
    ]
    met = (n_ok == n_tot)
    return ValidationCaseResult(
        "ISO_CYL2D_EXACT", _today_iso(),
        (; criterion="first 10 modes within 2 % at NY=20; error NY20 < NY10", date="2026-10-23",
         theta0_deg=θ0, floor="θ0=0° → floor width 0 (floor at y=−1, wall-tangent); expected: approach exact circle",
         max_rel_NY10=max_rel_10, max_rel_NY20=max_rel_20, c0=c0),
        table, series, met ? :met : :not_met,
        "$(n_ok)/$(n_tot) (max |e| NY20=$(round(100*max_rel_20;digits=3)) %, NY10=$(round(100*max_rel_10;digits=3)) %)",
        "V-UNIT", "",
    )
end

# --- 79c CYL2D_GRID_CONV -------------------------------------------------------------
"""Phase 79c: the production App. C grid (NY = 10, Fig. C-3) against a converged grid (NY = 60, possible since 79b) on
the real floored section θ0 = 56.6°, modes paired by parity and order. No criterion: the error is the documented
discretization error of the paper's grid (NY 40 against NY 60 shows the reference has converged)."""
function _run_cyl2d_grid_conv()
    c0 = 340.0; θ0 = 56.6; n_modes = 20
    r10, r40, r60 = (cyl2d_modes(θ0; n_modes, NY, c0) for NY in (10, 40, 60))
    par(r, s) = [m.f_Hz_unit for m in r.modes if m.symmetric == s]
    table = ValidationTableRow[]; series = PlotSeries[]
    for (si, s) in enumerate((true, false))
        f10, f40, f60 = par(r10, s), par(r40, s), par(r60, s)
        n = min(length(f10), length(f40), length(f60))
        lab = s ? "symmetric" : "antisymmetric"
        ks = Float64[]
        for k in 1:n
            f60[k] < 1.0 && continue                                  # the 0 Hz rigid mode
            push!(table, ValidationTableRow("$lab mode $k NY10 vs NY60", 100si + k, f60[k], f10[k], f10[k] - f60[k], true, "NY10 $lab"))
            push!(table, ValidationTableRow("$lab mode $k NY40 vs NY60 (info)", 100si + k + 0.5, f60[k], f40[k], f40[k] - f60[k], true, "NY40 $lab (info)"))
            push!(ks, k)
        end
        idx = Int.(ks)
        push!(series, PlotSeries("NY = 60 (reference)", :reference_points, ks, f60[idx]; panel=si))
        push!(series, PlotSeries("NY = 40", :reference_curve, ks, f40[idx]; panel=si))
        push!(series, PlotSeries("NY = 10 (App. C, production)", :computed, ks, f10[idx]; panel=si))
    end
    e10 = [abs(t.residual / t.reference) for t in table if !occursin("(info", t.quantity)]
    e40 = [abs(t.residual / t.reference) for t in table if occursin("(info", t.quantity)]
    return ValidationCaseResult(
        "CYL2D_GRID_CONV", _today_iso(),
        (; criterion="none (information: discretization error of the production grid)", date="2026-10-28",
         theta0_deg=θ0, c0, max_rel_NY10=maximum(e10), max_rel_NY40=maximum(e40)),
        table, series, :no_verdict,
        "production NY = 10 against converged NY = 60 (θ0 = 56.6°, $(length(e10)) modes): max |e| " *
        "$(round(100maximum(e10); digits=2)) %; reference converged: NY 40 vs 60 max $(round(100maximum(e40); digits=2)) %",
        "diagnostic", "")
end

# --- 40g ISO_JOINT_ACC ---------------------------------------------------------------

function _run_iso_joint_acc()
    sm = structural_modes_from_table_d1(; n_keep=32)
    # Three modes: pick low/mid indices with non-trivial shell content
    picks = (sm.modes[1], sm.modes[4], sm.modes[8])
    a, L, c0 = 0.508, test_article_length(), 340.0
    table = ValidationTableRow[]
    xs = Float64[]; yref = Float64[]; ygot = Float64[]
    n_ok = 0
    n_tot = 0
    max_rel = 0.0
    tol = 1e-4
    for (i, m) in enumerate(picks)
        ω = 2π * m.f_Hz
        # Code under test uses mode_normalized=false by default (= half of mode-normalized for n>0 axial/ring).
        # Independent quad returns mode-normalized; match the code's default by dividing by 4 when both
        # axial and ring use the printed (half) form — see unit tests: axial printed = mode_norm/2,
        # ring printed = mode_norm/2 for n>0, so product printed = mode_norm_product / 4.
        j_quad_mn = _iso_joint_acceptance_quad(m, ω; a, L, c0)
        j_code = structural_joint_acceptance(m, ω; a, L, c0, mode_normalized=true)
        rel = abs(j_code - j_quad_mn) / max(abs(j_quad_mn), 1e-30)
        ok = rel ≤ tol
        n_tot += 1
        n_ok += ok
        max_rel = max(max_rel, rel)
        push!(table, ValidationTableRow("j² mode $(m.index) (mode_norm)", Float64(m.index),
                                        j_quad_mn, j_code, j_code - j_quad_mn, ok))
        push!(xs, Float64(m.index)); push!(yref, j_quad_mn); push!(ygot, j_code)
        # also default (printed) form vs the printed-rule quadrature (term by term)
        j_code_p = structural_joint_acceptance(m, ω; a, L, c0, mode_normalized=false)
        j_quad_p = _iso_joint_acceptance_quad(m, ω; a, L, c0, printed=true)
        rel_p = abs(j_code_p - j_quad_p) / max(abs(j_quad_p), 1e-30)
        ok_p = rel_p ≤ tol
        n_tot += 1
        n_ok += ok_p
        max_rel = max(max_rel, rel_p)
        push!(table, ValidationTableRow("j² mode $(m.index) (printed)", Float64(m.index) + 0.5,
                                        j_quad_p, j_code_p, j_code_p - j_quad_p, ok_p))
    end
    series = [
        PlotSeries("quadrature", :reference_points, xs, yref; panel=1),
        PlotSeries("structural_joint_acceptance", :computed, xs, ygot; panel=1),
    ]
    return ValidationCaseResult(
        "ISO_JOINT_ACC", _today_iso(),
        (; criterion="≤ 1e-4 relative", date="2026-10-23", max_rel=max_rel,
         modes=[m.index for m in picks]),
        table, series, n_ok == n_tot ? :met : :not_met,
        "$n_ok/$n_tot within ≤1e-4 rel (max residual=$(max_rel))",
        "V-UNIT", "",
    )
end

# --- 40h ISO_MODAL_DENSITY -----------------------------------------------------------

function _run_iso_modal_density()
    sm = structural_modes_from_table_d1(; n_keep=32)
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    cy = cyl2d_modes(56.6; n_modes=5, NY=10, c0=340.0)
    pts = grid_points(fuse, prop, GridSpec())
    # Pressure shaped like the first structural mode so ⟨j²⟩ sits above the 1e-6 clamp floor
    # in `joint_acceptance` / `band_joint_acceptance` (uniform A yields Ψ≈0 → clamp).
    amps = ones(16, 10, 3)
    phases = zeros(16, 10, 3)
    st0 = sm.modes[1]
    for p in pts
        ψ = structural_shell_psi(st0, p.z, p.theta_deg, fuse.L)
        for H in 1:3
            amps[p.k, p.ell, H] = 1.0 + ψ
        end
    end
    ΔA = (π * fuse.a / 18)^2
    inp = PainInputs(fuse, prop, sm, cy, amps, phases, pts, ΔA)
    table = ValidationTableRow[]
    xs = Float64[]; yref = Float64[]; ygot = Float64[]
    n_ok = 0
    n_tot = 0
    max_rel = 0.0
    # Pick standard 1/3-octave centres that contain at least one Table D-1 mode
    bands = Float64[]
    for m in sm.modes
        fc = containing_third_octave(m.f_Hz, third_octave_centers())
        fc === nothing && continue
        fc in bands || push!(bands, Float64(fc))
        length(bands) ≥ 6 && break
    end
    for fc in bands
        df = 0.2316 * fc
        lo, hi = fc - df / 2, fc + df / 2
        n_count = count(m -> lo ≤ m.f_Hz ≤ hi, sm.modes)
        n_count ≥ 1 || continue
        Δω = 2π * max(df, 1.0)
        dens_ref = n_count / Δω
        dens_got = structural_modal_density(sm, fc)
        # count exact (criterion): density must equal n_count/Δω bit-for-bit on this path
        ok = dens_got == dens_ref
        n_tot += 1
        n_ok += ok
        max_rel = max(max_rel, abs(dens_got - dens_ref) / max(dens_ref, 1e-30))
        push!(table, ValidationTableRow("n(ω) fc=$fc (count=$n_count)", fc, dens_ref, dens_got,
                                        dens_got - dens_ref, ok))
        # band_joint_acceptance vs independent average of discrete joint_acceptance
        # (Ψ from the same Eq. 42 sums written out; j² formula written here — not band_joint_acceptance)
        js_ref = Float64[]
        H = 3
        p2_mean = sum(abs2, view(amps, :, :, H)) / (size(amps, 1) * size(amps, 2))
        area = size(amps, 1) * size(amps, 2) * ΔA
        for st in sm.modes
            (lo ≤ st.f_Hz ≤ hi) || continue
            sc, ss = 0.0, 0.0
            for p in pts
                A = amps[p.k, p.ell, H]
                ϕ = phases[p.k, p.ell, H]
                ψ = structural_shell_psi(st, p.z, p.theta_deg, fuse.L)
                sc += A * cos(ϕ) * ψ
                ss += A * sin(ϕ) * ψ
            end
            Ψ = ΔA * hypot(sc, ss)
            j2 = clamp((Ψ^2) / (max(p2_mean, 1e-30) * max(area, 1e-12)^2), 0.0, 1.0)
            push!(js_ref, j2)
        end
        # Match the function's clamp floor (1e-6) / ceiling (1.0) — the unclamped mean is
        # recorded in the residual via the pre-clamp value when diagnosing.
        ja_raw = sum(js_ref) / length(js_ref)
        ja_ref = clamp(ja_raw, 1e-6, 1.0)
        ja_got = band_joint_acceptance(inp, fc; H_anchor=3)
        rel = abs(ja_got - ja_ref) / max(abs(ja_ref), 1e-30)
        okj = rel ≤ 1e-6
        n_tot += 1
        n_ok += okj
        max_rel = max(max_rel, rel)
        push!(table, ValidationTableRow("⟨j²⟩_band fc=$fc", fc + 0.1, ja_ref, ja_got, ja_got - ja_ref, okj))
        push!(xs, fc); push!(yref, dens_ref); push!(ygot, dens_got)
    end
    series = [
        PlotSeries("count / Δω", :reference_points, xs, yref; panel=1),
        PlotSeries("structural_modal_density", :computed, xs, ygot; panel=1),
    ]
    return ValidationCaseResult(
        "ISO_MODAL_DENSITY", _today_iso(),
        (; criterion="count exact; band JA ≤ 1e-6 relative", date="2026-10-23",
         max_rel=max_rel, bands=bands),
        table, series, n_ok == n_tot && n_tot > 0 ? :met : :not_met,
        "$n_ok/$n_tot (max residual=$(max_rel))",
        "V-UNIT", "",
    )
end

# --- 40i ISO_BB_BAND -----------------------------------------------------------------

"""Closed-form ∫_{f1}^{f2} Spbl_a·(f_anchor/f)^α · 2π df over exact 1/3-oct edges.
f1 = fc·2^(-1/6), f2 = fc·2^(1/6). α = 1 uses the log form.
Spbl_a must match `blocked_broadband_band_p2`: tone spatial-mean |A|² at H_anchor
spread by Δω_a = 0.232·2π·f_anchor (pain_core.jl)."""
function _iso_bb_band_integral(Spbl_a::Float64, f_anchor::Float64, fc::Float64, α::Float64)
    f1 = fc * 2.0^(-1 / 6)
    f2 = fc * 2.0^(1 / 6)
    if abs(α - 1.0) < 1e-14
        return Spbl_a * f_anchor * 2π * log(f2 / f1)
    end
    return Spbl_a * f_anchor^α * 2π * (f2^(1 - α) - f1^(1 - α)) / (1 - α)
end

function _run_iso_bb_band()
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.662)
    sm = structural_modes_from_table_d1(; n_keep=8)
    cy = cyl2d_modes(56.6; n_modes=3, NY=10, c0=340.0)
    pts = grid_points(fuse, prop, GridSpec())
    bpf = 200.0
    # Synthetic blocked amplitudes with known H=3 peak power
    amps = zeros(16, 10, 3)
    amps[:, :, 1] .= 1.0
    amps[:, :, 2] .= 0.5
    amps[:, :, 3] .= 2.0
    phases = zeros(16, 10, 3)
    ΔA = (π * fuse.a / 18)^2
    inp = PainInputs(fuse, prop, sm, cy, amps, phases, pts, ΔA)
    table = ValidationTableRow[]
    xs = Float64[]; yref = Float64[]; ygot = Float64[]
    n_ok = 0
    n_tot = 0
    max_rel = 0.0
    tol = 1e-9
    # Anchor as blocked_broadband_band_p2: cw=0.232 at f_anchor = H·BPF (pain_core.jl)
    cw_anchor = 0.232
    H_anchor = 3
    f_anchor = H_anchor * bpf
    p2_tone = sum(abs2, amps[:, :, H_anchor]) / length(amps[:, :, H_anchor])
    Δω_a = cw_anchor * 2π * f_anchor
    Spbl_a = p2_tone / max(Δω_a, 1e-12)
    alphas = (2.0, 1.5)
    for α in alphas
        for fc in (1000.0, 1250.0, 1600.0, 2000.0)
            ref = _iso_bb_band_integral(Spbl_a, f_anchor, fc, α)
            got = blocked_broadband_band_p2(inp, fc, bpf; α=α, spbl_anchor_H=H_anchor)
            rel = abs(got - ref) / max(abs(ref), 1e-30)
            ok = rel ≤ tol
            n_tot += 1
            n_ok += ok
            max_rel = max(max_rel, rel)
            push!(table, ValidationTableRow("⟨p²⟩_bl α=$α fc=$fc", fc, ref, got, got - ref, ok))
            push!(xs, fc); push!(yref, ref); push!(ygot, got)
        end
    end
    series = [
        PlotSeries("closed-form ∫ Spbl·2π df", :reference_points, xs, yref; panel=1),
        PlotSeries("blocked_broadband_band_p2", :computed, xs, ygot; panel=1),
    ]
    return ValidationCaseResult(
        "ISO_BB_BAND", _today_iso(),
        (; criterion="≤ 1e-9 relative", date="2026-10-23", max_rel=max_rel,
         αs=collect(alphas), bpf_Hz=bpf),
        table, series, n_ok == n_tot ? :met : :not_met,
        "$n_ok/$n_tot within ≤1e-9 rel (max residual=$(max_rel))",
        "V-UNIT", "",
    )
end

# --- 40j ISO_CYL2D_BOUNDARY ----------------------------------------------------------

function _run_iso_cyl2d_boundary()
    cy = cyl2d_modes(56.6; n_modes=10, NY=10, c0=340.0)
    a, L, c0 = 0.508, test_article_length(), 340.0
    q_max = 3
    table = ValidationTableRow[]
    xs = Float64[]; yref = Float64[]; ygot = Float64[]
    n_ok = 0
    n_tot = 0
    max_rel = 0.0
    tol = 1e-9
    # Boundary values reconstructed from node samples at the stored wall angles
    for m in cy.modes[1:min(6, end)]
        for (i, θ) in enumerate(m.theta_boundary_deg)
            ref = m.phi_boundary[i]
            got = acoustic_boundary_value(m, θ)
            rel = abs(got - ref) / max(abs(ref), 1e-30)
            ok = (abs(ref) < 1e-14 ? abs(got) ≤ tol : rel ≤ tol)
            n_tot += 1
            n_ok += ok
            max_rel = max(max_rel, abs(got - ref), rel)
            x = Float64(m.index) * 1000 + i
            push!(table, ValidationTableRow("φ wall mode $(m.index) pt $i", x, ref, got, got - ref, ok))
            push!(xs, x); push!(yref, ref); push!(ygot, got)
        end
    end
    # (q, i) list complete and sorted
    list = cabin_modes_3d(cy, a, L, q_max; c0=c0)
    expected_n = (q_max + 1) * length(cy.modes)
    ok_len = length(list) == expected_n
    n_tot += 1
    n_ok += ok_len
    push!(table, ValidationTableRow("cabin_modes_3d length", 0.0, Float64(expected_n),
                                    Float64(length(list)), Float64(length(list) - expected_n), ok_len))
    ok_sorted = issorted(list; by=x -> x.f_Hz)
    n_tot += 1
    n_ok += ok_sorted
    push!(table, ValidationTableRow("cabin_modes_3d sorted", 1.0, 1.0, ok_sorted ? 1.0 : 0.0,
                                    ok_sorted ? 0.0 : 1.0, ok_sorted))
    # every (q,i) present exactly once
    seen = Set{Tuple{Int,Int}}()
    complete = true
    for q in 0:q_max, m in cy.modes
        key = (q, m.index)
        key in seen && (complete = false)
        push!(seen, key)
    end
    for row in list
        (row.q, row.i) in seen || (complete = false)
    end
    complete &= length(seen) == expected_n
    n_tot += 1
    n_ok += complete
    push!(table, ValidationTableRow("cabin_modes_3d complete", 2.0, 1.0, complete ? 1.0 : 0.0,
                                    complete ? 0.0 : 1.0, complete))
    # frequency formula check (independent)
    for row in list[1:min(20, end)]
        m = cy.modes[findfirst(x -> x.index == row.i, cy.modes)]
        f_ref = (c0 / (2π)) * sqrt(m.lambda_unit / a^2 + (row.q * π / L)^2)
        rel = abs(row.f_Hz - f_ref) / max(abs(f_ref), 1e-30)
        ok = rel ≤ tol
        n_tot += 1
        n_ok += ok
        max_rel = max(max_rel, rel)
        push!(table, ValidationTableRow("f (q=$(row.q),i=$(row.i))", Float64(row.q * 100 + row.i),
                                        f_ref, row.f_Hz, row.f_Hz - f_ref, ok))
    end
    series = [
        PlotSeries("stored φ", :reference_points, xs, yref; panel=1),
        PlotSeries("acoustic_boundary_value", :computed, xs, ygot; panel=1),
    ]
    return ValidationCaseResult(
        "ISO_CYL2D_BOUNDARY", _today_iso(),
        (; criterion="≤ 1e-9; (q,i) list exact", date="2026-10-23", max_rel=max_rel,
         q_max=q_max, n_list=length(list)),
        table, series, n_ok == n_tot ? :met : :not_met,
        "$n_ok/$n_tot (max residual=$(max_rel))",
        "V-UNIT", "",
    )
end

# --- 40k ISO_SIL ---------------------------------------------------------------------

function _run_iso_sil()
    # Hand spectrum: octave bands with known SIL = mean of 500/1k/2k/4k
    oct = Dict(125.0 => 60.0, 250.0 => 65.0, 500.0 => 70.0, 1000.0 => 72.0,
               2000.0 => 68.0, 4000.0 => 66.0, 8000.0 => 55.0)
    sil_ref = (70.0 + 72.0 + 68.0 + 66.0) / 4
    sil_got = sil_dB(oct)
    # 1/3-octave → SIL: three bands per octave, equal SPL → octave = that SPL
    third = Dict{Float64,Float64}()
    # Centres within the sil_from_third_octave window of each octave
    for (oc, spl) in ((500.0, 70.0), (1000.0, 72.0), (2000.0, 68.0), (4000.0, 66.0))
        for r in (-1, 0, 1)
            fc = oc * 2^(r / 3)
            third[fc] = spl
        end
    end
    # Independent: energy-sum of matching 1/3-oct bands then mean of the four octaves
    function hand_sil_from_third(third)
        oct_h = Dict{Float64,Float64}()
        for oc in (500.0, 1000.0, 2000.0, 4000.0)
            p2 = 0.0
            for (fc, spl) in third
                if abs(log(fc / oc) / log(2)) ≤ 0.5 / 3 + 0.2
                    p2 += 10^(spl / 10)
                end
            end
            oct_h[oc] = 10 * log10(p2 + 1e-30)
        end
        return sum(oct_h[b] for b in (500.0, 1000.0, 2000.0, 4000.0)) / 4
    end
    sil3_ref = hand_sil_from_third(third)
    sil3_got = sil_from_third_octave(third)
    table = ValidationTableRow[]
    tol = 1e-9
    ok1 = abs(sil_got - sil_ref) ≤ tol
    ok2 = abs(sil3_got - sil3_ref) ≤ tol
    push!(table, ValidationTableRow("SIL from octave", 1.0, sil_ref, sil_got, sil_got - sil_ref, ok1))
    push!(table, ValidationTableRow("SIL from 1/3-octave", 2.0, sil3_ref, sil3_got, sil3_got - sil3_ref, ok2))
    series = [
        PlotSeries("hand SIL", :reference_points, [1.0, 2.0], [sil_ref, sil3_ref]; panel=1),
        PlotSeries("sil_dB / sil_from_third_octave", :computed, [1.0, 2.0], [sil_got, sil3_got]; panel=1),
    ]
    max_res = max(abs(sil_got - sil_ref), abs(sil3_got - sil3_ref))
    return ValidationCaseResult(
        "ISO_SIL", _today_iso(),
        (; criterion="≤ 1e-9 dB", date="2026-10-23", max_residual_dB=max_res),
        table, series, (ok1 && ok2) ? :met : :not_met,
        "$(ok1+ok2)/2 within ≤1e-9 dB (max residual=$(max_res) dB)",
        "V-UNIT", "",
    )
end

"""Phase-40 isolated cases (no ISO_RITZ_DONNELL: Ritz cannot drop stringer/frame I via options)."""
function _iso40_validation_cases()
    return [
        ValidationCase("ISO_BLOCKING", "apply_blocking vs F(γ)·A on full 160-point grid (40a)", "40",
            String[], FigureRef("—", "analytic (Eq. 43)", nothing),
            "max relative difference ≤ 1e-12 (amplitudes vs F(γ)·A; phases unchanged).",
            "2026-10-23", "V-UNIT", _run_iso_blocking,
            PlotSpec(; xlabel="grid sample", ylabel="amplitude (Pa)",
                     panel_titles=["apply_blocking"],
                     error_mode=:relative_pct, error_tol=1e-10,
                     error_ylabel="relative residual"), ""),
        ValidationCase("ISO_FF_CONV", "Free-field SPL↔Pa and e11 ℓ=1 loader (40b)", "40",
            String[], FigureRef("—", "analytic (I-17 convention)", nothing),
            "≤ 1e-12 relative (SPL↔peak Pa round-trip; ℓ=1 line vs hand CSV conversion).",
            "2026-10-23", "V-UNIT", _run_iso_ff_conv,
            PlotSpec(; xlabel="sample", ylabel="Pa or dB",
                     panel_titles=["conversions / ℓ=1"],
                     error_mode=:relative_pct, error_tol=1e-10,
                     error_ylabel="relative residual"), ""),
        ValidationCase("ISO_GEXT_LINE", "extend_line_to_grid identity on ℓ=1 (40c)", "40",
            String[], FigureRef("—", "analytic (on-line identity)", nothing),
            "≤ 1e-12 on ℓ=1 for every harmonic and option; off-line stays V-ASSUMED.",
            "2026-10-23", "V-UNIT", _run_iso_gext_line,
            PlotSpec(; xlabel="sample", ylabel="amplitude (Pa)",
                     panel_titles=["ℓ=1 identity"],
                     error_mode=:relative_pct, error_tol=1e-10,
                     error_ylabel="relative residual"), ""),
        ValidationCase("ISO_TABLE8", "apply_table8_calibration identity (40d)", "40",
            String[], FigureRef("—", "analytic (identity)", nothing),
            "≤ 1e-12 when Table-8 peaks equal the current ℓ=1 peaks.",
            "2026-10-23", "V-UNIT", _run_iso_table8,
            PlotSpec(; xlabel="grid sample", ylabel="amplitude (Pa)",
                     panel_titles=["Table-8 cal identity"],
                     error_mode=:relative_pct, error_tol=1e-10,
                     error_ylabel="relative residual"), ""),
        ValidationCase("ISO_CYL2D_EXACT", "cyl2d_modes vs exact circle J′ zeros (40e)", "40",
            String[], FigureRef("—", "analytic (Neumann circle)", nothing),
            "first 10 modes within 2 % at NY=20; error at NY=20 smaller than at NY=10 (θ0=0° floorless).",
            "2026-10-23", "V-UNIT", _run_iso_cyl2d_exact,
            PlotSpec(; xlabel="mode index", ylabel="frequency (Hz)",
                     panel_titles=["circle modes"],
                     error_mode=:relative_pct, error_tol=2.0,
                     error_ylabel="% vs J′ zero"), ""),
        ValidationCase("CYL2D_GRID_CONV", "CYL2D production grid (NY 10) vs converged grid (79c)", "79",
            String[], FigureRef("CR-3813", "App. C Fig. C-3 grid", nothing),
            "No criterion (information): per-mode error of the App. C NY = 10 grid against NY = 60 on the floored section.",
            "2026-10-28", "diagnostic", _run_cyl2d_grid_conv,
            PlotSpec(; xlabel="mode order within parity", ylabel="frequency (Hz, a = 1 m, c = 340 m/s)",
                     panel_titles=["symmetric modes", "antisymmetric modes"],
                     error_mode=:relative_pct, error_ylabel="error vs NY 60 (%)",
                     error_xlabel="100 × parity + mode order (1: symmetric, 2: antisymmetric)"), ""),
        ValidationCase("ISO_JOINT_ACC", "structural_joint_acceptance vs quadrature (40g)", "40",
            String[], FigureRef("—", "analytic (quadrature)", nothing),
            "≤ 1e-4 relative against direct numerical quadrature for three modes.",
            "2026-10-23", "V-UNIT", _run_iso_joint_acc,
            PlotSpec(; xlabel="mode index", ylabel="j²",
                     panel_titles=["joint acceptance"],
                     error_mode=:relative_pct, error_tol=0.01,
                     error_ylabel="% vs quadrature"), ""),
        ValidationCase("ISO_MODAL_DENSITY", "modal density and band joint acceptance (40h)", "40",
            String[], FigureRef("—", "analytic (count / discrete average)", nothing),
            "modal density count exact; band joint acceptance ≤ 1e-6 relative.",
            "2026-10-23", "V-UNIT", _run_iso_modal_density,
            PlotSpec(; xlabel="band centre (Hz)", ylabel="n(ω) [1/(rad/s)]",
                     panel_titles=["modal density"],
                     error_mode=:relative_pct, error_tol=1e-4,
                     error_ylabel="%"), ""),
        ValidationCase("ISO_BB_BAND", "blocked_broadband_band_p2 vs closed-form band integral (40i)", "40",
            String[], FigureRef("—", "analytic (∫ S∝f^(−α) over 1/3-oct)", nothing),
            "≤ 1e-9 relative against ∫_{f1}^{f2} Spbl_a (f_a/f)^α 2π df (exact 1/3-oct edges).",
            "2026-10-23", "V-UNIT", _run_iso_bb_band,
            PlotSpec(; xlabel="band centre (Hz)", ylabel="⟨p²⟩_bl (Pa²)",
                     panel_titles=["broadband band"],
                     error_mode=:relative_pct, error_tol=1e-7,
                     error_ylabel="%"), ""),
        ValidationCase("ISO_CYL2D_BOUNDARY", "boundary values and cabin_modes_3d list (40j)", "40",
            String[], FigureRef("—", "analytic (node reconstruct / sort)", nothing),
            "≤ 1e-9 on boundary reconstruction; (q,i) list complete and sorted (exact).",
            "2026-10-23", "V-UNIT", _run_iso_cyl2d_boundary,
            PlotSpec(; xlabel="sample", ylabel="φ",
                     panel_titles=["boundary φ"],
                     error_mode=:absolute, error_tol=1e-9,
                     error_ylabel="φ residual"), ""),
        ValidationCase("ISO_SIL", "sil_dB / sil_from_third_octave hand spectrum (40k)", "40",
            String[], FigureRef("—", "analytic (hand SIL)", nothing),
            "≤ 1e-9 dB against hand-computed SIL from a known band spectrum.",
            "2026-10-23", "V-UNIT", _run_iso_sil,
            PlotSpec(; xlabel="case", ylabel="SIL (dB)",
                     panel_titles=["SIL"],
                     error_mode=:absolute, error_tol=1e-9,
                     error_ylabel="dB"), ""),
    ]
end
