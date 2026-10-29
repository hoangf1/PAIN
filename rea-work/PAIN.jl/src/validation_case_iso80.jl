# Phase 80 (IMPLEMENTATION_PLAN.md §8x): verify the App. D structural solver with references that get the same, fully
# stated inputs. Criteria fixed and dated 2026-10-29, before any of these checks was run.

# --- references (independent of the coupled solve) -----------------------------------

"""Stiffened shell alone, no floor: every eigenfrequency (Hz, ≥ 1 rad²/s²) of the closed-shell 3×3 of each harmonic
n = 0..n_circ, with the family's n = 0 functions only (symmetric u, w; antisymmetric v), sorted. Phase 80a reference."""
function _p80_shell_alone_Hz(g::AbstractAppDInput, M::Int, sym::Bool; n_circ::Int=8)
    sp = _appd_shell_props(g)
    fs = Float64[]
    for n in 0:n_circ
        K, Mm = _appd_shell_harmonic_KM(M, n, g.L, sp; arc_frac=1.0)
        idx = n > 0 ? (1:3) : (sym ? [1, 3] : [2])
        for ω2 in eigvals(Symmetric(K[idx, idx]), Symmetric(Mm[idx, idx]))
            ω2 ≥ 1.0 && push!(fs, sqrt(ω2) / 2π)
        end
    end
    return sort!(fs)
end

"""
Orthotropic Kirchhoff plate, simply supported at x = 0, L and clamped on both long edges y = ±Lp/2 (Levy solution,
Leissa SS-C-SS-C): the `nmodes` lowest frequencies (Hz) of axial half-wave M, even (`even = true`, symmetric family)
or odd in y. With w = sin(μx) Y(y), Dx μ⁴ Y − 2H μ² Y'' + Dy Y'''' = m ω² Y; Y = A cosh αy + B cos βy (even) or
A sinh αy + B sin βy (odd), α² = 2Hμ²/Dy + β², m ω² = Dy β⁴ + 2H μ² β² + Dx μ⁴. Roots of the clamped-edge
determinant by scan and bisection in β. Phase 80a reference; shares no code with the Ritz solve.
"""
function _p80_clamped_plate_Hz(Dx, Dy, H, m, Lp, L, M::Int, even::Bool; nmodes::Int=3)
    μ = M * π / L
    b = Lp / 2
    det(β) = begin
        α = sqrt(2H * μ^2 / Dy + β^2)
        even ? (-β * sin(β * b) - α * tanh(α * b) * cos(β * b)) : (β * tanh(α * b) * cos(β * b) - α * sin(β * b))
    end
    ω(β) = sqrt((Dy * β^4 + 2H * μ^2 * β^2 + Dx * μ^4) / m)
    roots = Float64[]
    βs = range(1e-9, (nmodes + 3) * π / b; length=20_000)
    for k in 1:length(βs)-1
        lo, hi = βs[k], βs[k+1]
        dlo, dhi = det(lo), det(hi)
        dlo == 0 && (push!(roots, lo); continue)
        sign(dlo) == sign(dhi) && continue
        for _ in 1:200
            mid = (lo + hi) / 2
            sign(det(mid)) == sign(dlo) ? (lo = mid; dlo = det(mid)) : (hi = mid)
        end
        push!(roots, (lo + hi) / 2)
        length(roots) == nmodes && break
    end
    return [ω(β) / 2π for β in roots]
end

# --- 80a MRP_COUPLED_LIMITS ------------------------------------------------------------

const _P80_FLOOR_SCALE = 1e-4      # 80a(1): floor thickness, beam area and inertia scaled (vanishing floor)
const _P80_SHELL_KSCALE = 1e4      # 80a(2): shell stiffness factor (near-rigid shell), mass unchanged
# 80a(1) amendment 2026-10-29, post-hoc (after the first run): the floor's bending stiffness is set by its beams, which
# scale like its mass, so the scaled floor kept its own modes at full frequency and one (antisymmetric M = 3, ~909 Hz)
# sat on a shell mode (896 Hz) and split it, as a light resonator at resonance should. A further test-only floor mass
# factor moves the floor's own modes ×100 in frequency, far above the compared range. Criterion unchanged.
const _P80_FLOOR_MSCALE = 1e-4

"""Phase 80a: coupled limiting cases of `mrp_appd.jl` (criteria fixed 2026-10-29). (1) Vanishing floor: the 10 lowest
shell-dominated modes (shell kinetic share ≥ 0.99) per (M, parity), M = 1–3, against the stiffened shell alone, each
within 1 %. (2) Near-rigid shell: the 3 lowest floor-bending modes (floor kinetic share ≥ 0.99, w share ≥ 0.9) per
(M, parity), M = 1–3, against the clamped orthotropic plate (Levy), each within 2 %. Production input and basis: NASA's
deck and its series limits, NASA's floor form (`floor_cross_terms=false`); the same limit with the floor cross terms is
shown as information rows."""
function _run_mrp_coupled_limits()
    g = appd_nasa_deck()
    n_circ, n_floor_max = g.n_circ, g.n_floor_max
    fs = _P80_FLOOR_SCALE
    gsoft = AppDDeck(g.L, g.a, g.theta0_deg, g.E_shell, g.ν_shell, g.t_shell, g.m_shell, g.Dp_stringers, g.Dp_frames,
                     g.E_floor, g.ν_floor, fs * g.t_floor, fs * g.m_floor, fs * g.Dp_floor_beams, fs * g.Dp_floor_supports,
                     g.n_axial, g.n_circ, g.n_floor_max)
    fp = _appd_floor_props(g)
    table = ValidationTableRow[]; series = PlotSeries[]
    for (si, sym) in enumerate((true, false))
        lab = sym ? "symmetric" : "antisymmetric"
        xs1 = Float64[]; r1 = Float64[]; c1 = Float64[]
        xs2 = Float64[]; r2 = Float64[]; c2 = Float64[]
        xs3 = Float64[]; c3 = Float64[]
        for M in 1:3
            # (1) vanishing floor
            fam = _appd_family(gsoft, M, sym; n_circ, n_floor_max, floor_mscale=_P80_FLOOR_MSCALE)
            got = sort!([fam.f_Hz[k] for k in eachindex(fam.f_Hz) if _appd_shell_share(fam.Q[:, k], fam.b, fam.Mass) ≥ 0.99])
            ref = _p80_shell_alone_Hz(g, M, sym; n_circ)
            for k in 1:10
                x = 100M + k + (sym ? 0 : 50)
                if k > length(got)
                    push!(table, ValidationTableRow("soft floor $lab M=$M mode $k (missing)", x, ref[k], NaN, NaN, false, "vanishing floor"))
                    continue
                end
                ok = abs(got[k] / ref[k] - 1) ≤ 0.01
                push!(table, ValidationTableRow("soft floor $lab M=$M mode $k", x, ref[k], got[k], got[k] - ref[k], ok, "vanishing floor"))
                push!(xs1, x); push!(r1, ref[k]); push!(c1, got[k])
            end
            # (2) near-rigid shell: production floor form (criterion), then with the floor cross terms (information)
            reff = _p80_clamped_plate_Hz(fp.Dx, fp.Dy, fp.H, fp.mf, fp.Lp, g.L, M, sym; nmodes=3)
            for cross in (false, true)
                famr = _appd_family(g, M, sym; n_circ, n_floor_max, floor_cross_terms=cross, shell_kscale=_P80_SHELL_KSCALE)
                wdofs = [_floor_dof(famr.b, j, 3) for j in 1:famr.b.np]
                Me = famr.Mass_exact
                isbend(q) = (1 - _appd_shell_share(q, famr.b, Me)) ≥ 0.99 &&
                            dot(q[wdofs], Me[wdofs, wdofs] * q[wdofs]) / dot(q, Me * q) ≥ 0.9
                gotf = sort!([famr.f_Hz[k] for k in eachindex(famr.f_Hz) if isbend(famr.Q[:, k])])
                tag = cross ? " (info, floor cross terms)" : ""
                grp = cross ? "near-rigid shell, cross terms (info)" : "near-rigid shell"
                for k in 1:3
                    x = 100M + k + (sym ? 0 : 50) + (cross ? 0.3 : 0.0)
                    if k > length(gotf)
                        push!(table, ValidationTableRow("rigid shell $lab M=$M floor mode $k$tag (missing)", x, reff[k], NaN, NaN, cross, grp))
                        continue
                    end
                    ok = cross || abs(gotf[k] / reff[k] - 1) ≤ 0.02
                    push!(table, ValidationTableRow("rigid shell $lab M=$M floor mode $k$tag", x, reff[k], gotf[k], gotf[k] - reff[k], ok, grp))
                    cross || (push!(xs2, x); push!(r2, reff[k]); push!(c2, gotf[k]))
                    cross && (push!(xs3, x); push!(c3, gotf[k]))
                end
            end
        end
        push!(series, PlotSeries("shell alone (reference)", :reference_points, xs1, r1; panel=si))
        push!(series, PlotSeries("coupled, floor × 1e-4", :computed_points, xs1, c1; panel=si))
        push!(series, PlotSeries("clamped plate, Levy (reference)", :reference_points, xs2, r2; panel=si + 2))
        push!(series, PlotSeries("coupled, shell stiffness × 1e4 (NASA floor form)", :computed_points, xs2, c2; panel=si + 2))
        push!(series, PlotSeries("same, with floor cross terms (info)", :computed_points, xs3, c3; panel=si + 2))
    end
    crit = [r for r in table if !occursin("(info", r.group)]
    n_ok = count(r -> r.within_tolerance, crit)
    verdict = n_ok == length(crit) ? :met : :not_met
    soft = [r for r in table if r.group == "vanishing floor"]
    rig = [r for r in table if r.group == "near-rigid shell"]
    rigx = [r for r in table if r.group == "near-rigid shell, cross terms (info)"]
    maxe(rs) = maximum((abs(r.residual / r.reference) for r in rs if isfinite(r.residual)); init=0.0)
    return ValidationCaseResult(
        "MRP_COUPLED_LIMITS", _today_iso(),
        (; criterion="vanishing floor: 10 lowest shell modes per (M, parity), M 1-3, within 1 %; near-rigid shell: 3 lowest floor-bending modes per (M, parity) within 2 % of the clamped plate",
         date="2026-10-29", input="NASA MRP deck", floor_cross_terms=false, floor_scale=_P80_FLOOR_SCALE,
         floor_mscale_posthoc=_P80_FLOOR_MSCALE, shell_kscale=_P80_SHELL_KSCALE, n_circ, n_floor_max,
         max_rel_soft=maxe(soft), max_rel_rigid=maxe(rig), max_rel_rigid_cross_info=maxe(rigx)),
        table, series, verdict,
        "$n_ok/$(length(crit)) within tolerance; vanishing floor max $(round(100maxe(soft); digits=2)) % " *
        "($(count(r -> r.within_tolerance, soft))/$(length(soft))), near-rigid shell (NASA floor form) max " *
        "$(round(100maxe(rig); digits=2)) % ($(count(r -> r.within_tolerance, rig))/$(length(rig))); with the floor cross " *
        "terms (information) max $(round(100maxe(rigx); digits=2)) %",
        "V-CODE", "")
end

# --- 80d MRP_TRUNC ----------------------------------------------------------------------

"""Dense-grid maximum of |w| of a `StructuralMode` over the whole shell (via `shell_circumferential`, θ from the top) and
the floor (Eqs. D.28–D.29). Independent of `_appd_shape_peak` (Phase 80d check)."""
function _p80_dense_peak(m::StructuralMode, θ0_deg::Float64, a::Float64)
    Lp = 2a * sind(θ0_deg)
    ps = isempty(m.C_shell) ? 0.0 : maximum(abs(shell_circumferential(m, θ)) for θ in range(0.0, 2π; length=200_001))
    wf(x) = sum((m.symmetric ? C * cos(n * π * x / Lp) : C * sin(n * π * x / Lp) for (C, n) in zip(m.C_floor, m.n_floor)); init=0.0)
    pf = isempty(m.C_floor) ? 0.0 : maximum(abs(wf(x)) for x in range(-Lp / 2, Lp / 2; length=20_001))
    return max(ps, pf)
end

"""Keep the `ks` largest shell and `kf` largest floor coefficients of a mode (Table D-1 prints 5 and 3)."""
function _p80_truncate(m::StructuralMode, ks::Int, kf::Int)
    os = sortperm(abs.(m.C_shell); rev=true)[1:min(ks, end)]
    of = sortperm(abs.(m.C_floor); rev=true)[1:min(kf, end)]
    return StructuralMode(m.index, m.f_Hz, m.symmetric, m.M_r, m.M_axial, m.C_shell[os], m.n_shell[os],
                          m.C_floor[of], m.n_floor[of])
end

"""Phase 80d (criteria fixed 2026-10-29): (1) the solver's full shapes (NASA's deck, production form, the 32 lowest
modes) have unit maximum normal displacement over shell and floor, all 32 within 1e-6 (dense-grid check independent of
the solver's peak search); (2) diagnostic, no verdict: the same shapes cut to the 5 largest shell and 3 largest floor
terms, as Table D-1 prints them. The class I reading of MRP_SHAPE_NORM is supported if the cut peaks exceed 1 in at least
a third of the modes and the largest lies between 1.05 and 1.5. The printed Table D-1 peak of each mode is shown
alongside (information)."""
function _run_mrp_trunc()
    g = appd_nasa_deck()
    cands = StructuralMode[]
    for M in 1:g.n_axial, sym in (true, false)
        fam = _appd_family(g, M, sym; n_circ=g.n_circ, n_floor_max=g.n_floor_max)
        fam === nothing && continue
        for k in eachindex(fam.f_Hz)
            q = fam.Q[:, k]
            Cs, ns, Cf, nf, Mr = _appd_extract_shapes(q, fam.b, g, abs(dot(q, fam.Mass_exact * q));
                                                      n_keep_shell=typemax(Int), n_keep_floor=typemax(Int))
            push!(cands, StructuralMode(0, fam.f_Hz[k], sym, Mr, M, Cs, ns, Cf, nf))
        end
    end
    sort!(cands; by=m -> m.f_Hz)
    modes = cands[1:32]
    d1 = structural_modes_from_table_d1(; n_keep=32)
    table = ValidationTableRow[]
    xs = Float64[]; full = Float64[]; cut = Float64[]; printed = Float64[]
    for (i, m) in enumerate(modes)
        pk = _p80_dense_peak(m, g.theta0_deg, g.a)
        push!(table, ValidationTableRow("mode $i full shape max |w|", i, 1.0, pk, pk - 1, abs(pk - 1) ≤ 1e-6, "full shape"))
        pc = _p80_dense_peak(_p80_truncate(m, 5, 3), g.theta0_deg, g.a)
        push!(table, ValidationTableRow("mode $i cut to 5 + 3 terms max |w| (info)", i + 0.3, 1.0, pc, pc - 1, true, "cut 5 + 3 (info)"))
        pp = _p80_dense_peak(d1.modes[i], g.theta0_deg, g.a)
        push!(table, ValidationTableRow("mode $i printed Table D-1 max |w| (info)", i + 0.6, 1.0, pp, pp - 1, true, "printed (info)"))
        push!(xs, i); push!(full, pk); push!(cut, pc); push!(printed, pp)
    end
    n_ok = count(r -> r.group == "full shape" && r.within_tolerance, table)
    n_over = count(>(1.0 + 1e-6), cut)
    supported = n_over ≥ 32 / 3 && 1.05 ≤ maximum(cut) ≤ 1.5
    series = [PlotSeries("printed Table D-1 (5 + 3 terms)", :reference_points, xs, printed; panel=1),
              PlotSeries("solver, full shape", :computed_points, xs, full; panel=1),
              PlotSeries("solver, cut to 5 + 3 terms", :computed_points, xs, cut; panel=1)]
    return ValidationCaseResult(
        "MRP_TRUNC", _today_iso(),
        (; criterion="full shapes: max |w| = 1 within 1e-6 for all 32 (NASA's deck, production form)", date="2026-10-29",
         diagnostic="cut to 5 + 3 terms: >1 in ≥ 1/3 of the modes and max in [1.05, 1.5] supports the class I reading",
         n_cut_over_1=n_over, max_cut=maximum(cut), max_printed=maximum(printed), truncation_reading_supported=supported),
        table, series, n_ok == 32 ? :met : :not_met,
        "$n_ok/32 full shapes at unit maximum within 1e-6. Diagnostic: cut to 5 + 3 terms, $n_over/32 exceed 1, largest " *
        "$(round(maximum(cut); digits=3)) (printed Table D-1 largest $(round(maximum(printed); digits=3))): the truncation " *
        "reading of MRP_SHAPE_NORM is $(supported ? "supported" : "not supported") by the pre-set rule",
        "V-CODE", "")
end

function _iso80_validation_cases()
    return [
        ValidationCase("MRP_COUPLED_LIMITS", "App. D coupled solve: vanishing floor and near-rigid shell limits (80a)", "80",
            String[], FigureRef("—", "analytic (shell alone; Levy clamped plate)", nothing),
            "Vanishing floor (×1e-4): the 10 lowest shell-dominated modes per (M, parity), M = 1–3, within 1 % of the stiffened shell alone. Near-rigid shell (stiffness ×1e4): the 3 lowest floor-bending modes per (M, parity), M = 1–3, within 2 % of the SS-C-SS-C orthotropic plate. Production input and series (NASA's deck), NASA's floor form.",
            "2026-10-29", "V-CODE", _run_mrp_coupled_limits,
            PlotSpec(; xlabel="100 × M + mode order (+50: antisymmetric)", ylabel="frequency (Hz)",
                     panel_titles=["vanishing floor, symmetric", "vanishing floor, antisymmetric",
                                   "near-rigid shell, symmetric", "near-rigid shell, antisymmetric"],
                     error_mode=:relative_pct, error_ylabel="error vs reference (%; criteria 1 % and 2 %)"), ""),
        ValidationCase("MRP_TRUNC", "App. D solver shapes: unit maximum, and the Table D-1 print truncation (80d)", "80",
            [_data_path("cr3813", "um_mrp_input_deck.csv")], FigureRef("CR-3813", "Table D-1 (5 shell + 3 plate terms printed)", 113),
            "The solver's full shapes (NASA's deck, 32 lowest modes) have max |w| = 1 within 1e-6 over shell and floor. Diagnostic, no verdict: the shapes cut to 5 shell + 3 floor terms; the truncation reading of MRP_SHAPE_NORM is supported if > 1 in at least a third of the modes and the largest lies in [1.05, 1.5].",
            "2026-10-29", "V-CODE", _run_mrp_trunc,
            PlotSpec(; xlabel="mode number", ylabel="max |w| of the normalized shape (dimensionless)",
                     panel_titles=["peak normal displacement"],
                     error_mode=:absolute, error_ylabel="max |w| − 1"), ""),
    ]
end
