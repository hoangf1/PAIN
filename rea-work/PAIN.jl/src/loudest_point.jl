# Phase 42 — interior level at the loudest point (criteria fixed 2026-10-23, IMPLEMENTATION_PLAN.md §8b).
# PAIN reports the space average (Eq. 3). Here the same Eq. (8) terms are summed at interior points:
# for each structural mode r the acoustic modes add coherently, structural modes add in mean square
# (as Eq. (8) does), so the volume average of the point values returns Eq. (8).

"""
    cabin_interior_points(inp; n_axial=21) -> NamedTuple

Interior CYL2D nodes of the full cross-section (wall and floor nodes excluded; the half-grid
nodes are mirrored to X < 0) at `n_axial` equally spaced axial stations z = 0 … L_c (Phase 42).
A node is interior when n ≥ 1 and its four grid neighbours are inside the cabin. Coordinates
are in metres (X across, Y up from the cylinder axis, z from the forward end).
"""
function cabin_interior_points(inp::PainInputs; n_axial::Int=21)
    a = inp.fuse.a
    g = _build_grid(deg2rad(inp.fuse.theta0_deg), _cyl2d_NY(inp))
    inside(m, n) = _in(g, m, n)
    nodes = Tuple{Int,Int}[]
    for m in -(size(g.incab, 1) - 1):(size(g.incab, 1) - 1), n in 1:g.NY
        inside(m, n) || continue
        all(inside(m + dm, n + dn) for (dm, dn) in _NEIGH) || continue
        push!(nodes, (m, n))
    end
    zs = collect(range(0.0, inp.L_c; length=n_axial))
    wz = fill(1.0, n_axial); wz[1] = wz[end] = 0.5           # trapezoid weights along z
    return (; nodes, X=[a * m * g.h for (m, n) in nodes], Y=[a * (g.yfloor + n * g.h) for (m, n) in nodes],
            z=zs, wz=wz ./ sum(wz))
end

"""
    cabin_quadrature_points(inp; n_axial=21) -> NamedTuple

All CYL2D nodes of the full section (wall and floor nodes included) with the weights of
Eq. (C.10) (Φ_G: C = 1 on boundary and centreline nodes, 2 inside, on the half grid; a mirrored
off-centre node carries C/2), at `n_axial` stations with trapezoid weights. With
`point_volume_average`, Σ w φ_i² h² reproduces Φ_G, so this is the quadrature that matches the
ε_n normalization (supplementary Phase 42 check, added 2026-10-23 after the interior-node check).
"""
function cabin_quadrature_points(inp::PainInputs; n_axial::Int=21)
    a = inp.fuse.a
    g = _build_grid(deg2rad(inp.fuse.theta0_deg), _cyl2d_NY(inp))
    inside(m, n) = _in(g, m, n)
    nodes = Tuple{Int,Int}[]; w = Float64[]
    for m in -(size(g.incab, 1) - 1):(size(g.incab, 1) - 1), n in 0:g.NY
        inside(m, n) || continue
        bnd = !all(inside(m + dm, n + dn) for (dm, dn) in _NEIGH)
        C = (bnd || m == 0) ? 1.0 : 2.0
        push!(nodes, (m, n)); push!(w, m == 0 ? C : C / 2)
    end
    A_cab = π - g.θ0 + cos(g.θ0) * sin(g.θ0)
    zs = collect(range(0.0, inp.L_c; length=n_axial))
    wz = fill(1.0, n_axial); wz[1] = wz[end] = 0.5
    return (; nodes, X=[a * m * g.h for (m, n) in nodes], Y=[a * (g.yfloor + n * g.h) for (m, n) in nodes],
            z=zs, wz=wz ./ sum(wz), wnode=w .* g.h^2 ./ A_cab)
end

# NY of the CYL2D grid the modes were built on: the node keys reach n = NY.
_cyl2d_NY(inp::PainInputs) = maximum(n for (m, n) in keys(first(inp.acoustic.modes).phi_nodes))

"""φ_i at node (m, n) of the full section: mirrored half-grid value, sign-flipped for antisymmetric modes."""
function _phi_node_full(ac::AcousticMode, m::Int, n::Int)
    v = get(ac.phi_nodes, (abs(m), n), NaN)
    if isnan(v)
        (m == 0 && !ac.symmetric) && return 0.0       # antisymmetric centreline
        error("CYL2D mode $(ac.index) has no value at node ($m, $n)")
    end
    return (m < 0 && !ac.symmetric) ? -v : v
end

"""
    point_tone_p2(inp, H, ωH; pts=cabin_interior_points(inp)) -> Matrix (node × z) of ⟨p²⟩ [Pa²]

Eq. (8) at interior points. With A_nr = ε_n √(pref Ψ_r) f̄′/(M_r (ω_n² − ω_H² + iN_n)(ω_r² − ω_H² +
i(η_r′ + η_r″)ω_r²)) and φ_n = cos(qπz/L_c) φ_i(node), the point value is Σ_r |Σ_n A_nr φ_n|²; since
∫ φ_n φ_m dV = δ_nm V/ε_n, its volume average is Σ_r Σ_n |A_nr|²/ε_n = Eq. (8) term by term.
"""
function point_tone_p2(inp::PainInputs, H::Int, ωH::Float64; pts=cabin_interior_points(inp),
                       q_max::Union{Nothing,Int}=nothing, η_r_cap::Union{Nothing,Float64}=nothing)
    fuse = inp.fuse
    a, L = fuse.a, fuse.L
    L_c = inp.L_c
    θ0 = deg2rad(fuse.theta0_deg)
    Lp = 2a * sin(θ0)
    A = L * (Lp + 2a * (π - θ0))
    V = cabin_volume(inp)
    ρ_int, c_int = inp.ρ_int, inp.c_int
    ext = inp.allow_extrapolation
    qtop = something(q_max, inp.q_max, axial_truncation(ωH, L_c, c_int))
    trimmed = has_trim(inp)
    τ_t = sidewall_tau(inp, ωH)
    ξ = trimmed ? trim_conductance(inp.sidewall, ωH, inp.m_wall; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0
    ξe = trimmed ? trim_conductance(inp.endplates, ωH, Inf; ρ0=ρ_int, c0=c_int, allow_extrapolation=ext) : 0.0
    pref = (c_int / V)^2 * (inp.ρ_ext * inp.c_ext * A)^2 * ωH^4
    fH = ωH / 2π
    nst = length(inp.structural.modes)
    Ψ = [generalized_force(st, H, inp.amplitudes, inp.phases, inp.pts, fuse; ΔA=inp.ΔA) for st in inp.structural.modes]
    ωr = [2π * st.f_Hz for st in inp.structural.modes]
    ηrp = [structural_η_r_prime(inp, st, ωr[j]; η_r_cap) for (j, st) in enumerate(inp.structural.modes)]
    nn, nz = length(pts.nodes), length(pts.z)
    field = [zeros(ComplexF64, nn, nz) for _ in 1:nst]
    φnode = zeros(nn)
    for q in 0:qtop, ac in inp.acoustic.modes
        ωn = 2π * cabin_frequency_3d(ac, a, L_c, q; c0=c_int)
        εn = cabin_eps_3d(ac, q)
        N = acoustic_N(inp, ac, q, fH, ωn; ξ, ξ_e=ξe, V)
        for (i, (m, n)) in enumerate(pts.nodes)
            φnode[i] = _phi_node_full(ac, m, n)
        end
        cz = [cos(q * π * z / L_c) for z in pts.z]
        for (j, st) in enumerate(inp.structural.modes)
            f = coupling_factor(ac, st, inp; τ_t, q)
            f == 0 && continue
            f′ = τ_t == 1 ? f : coupling_factor(ac, st, inp; τ_t=1.0, q)
            ηrpp = structural_loss_coupled(N, ωn, ωr[j], f′, εn, st.M_r, V, A; ρ0=ρ_int, c0=c_int)
            Anr = εn * sqrt(pref * Ψ[j]) * f /
                  (st.M_r * complex(ωn^2 - ωH^2, N) * complex(ωr[j]^2 - ωH^2, (ηrp[j] + ηrpp) * ωr[j]^2))
            field[j] .+= Anr .* (φnode * transpose(cz))
        end
    end
    p2 = zeros(nn, nz)
    for F in field
        p2 .+= abs2.(F)
    end
    return p2
end

"""Volume average of point values: node weights `pts.wnode` when present (Φ_G quadrature), else the
node mean (interior points); trapezoid weights along z."""
point_volume_average(p2::AbstractMatrix, pts) =
    haskey(pts, :wnode) ? sum(pts.wnode .* (p2 * pts.wz)) : sum(p2 * pts.wz) / size(p2, 1)

"""
    loudest_point(inp; bpf_Hz, n_harmonics, spectrum=interior_spl(...)) -> NamedTuple

Overall dB(A) at every interior point: each tone at its point level (Eq. (8) at the point when the
tone used Eq. (8); its space-average value when it used Eqs. (15)–(16)); broadband bands at their
space-average level (diffuse). Returns the space-average dB(A) (`overall_dBA`), the loudest-point
dB(A), its position and the tone levels there.
"""
function loudest_point(inp::PainInputs; bpf_Hz::Float64, n_harmonics::Int=3,
                       spectrum::Union{Nothing,InteriorSpectrum}=nothing, n_axial::Int=21, kw...)
    sp = spectrum === nothing ? interior_spl(inp; bpf_Hz, n_harmonics, kw...) : spectrum
    pts = cabin_interior_points(inp; n_axial)
    pref2 = (20e-6)^2
    nH = length(sp.harmonic_SPL_dB)
    bands = sp.third_octave_SPL_dB
    # broadband (bands minus the tones folded into them), A-weighted, same at every point
    tone_band = Dict{Float64,Float64}()
    bkeys = collect(keys(bands))
    for H in 1:nH
        b = nearest_third_octave(H * bpf_Hz, bkeys)
        tone_band[b] = get(tone_band, b, 0.0) + pref2 * 10^(sp.harmonic_SPL_dB[H] / 10)
    end
    bb_A = 0.0
    for (fc, spl) in bands
        isfinite(spl) || continue
        p2b = max(pref2 * 10^(spl / 10) - get(tone_band, fc, 0.0), 0.0)
        bb_A += p2b * 10^(a_weight_dB(fc) / 10)
    end
    total = fill(bb_A, length(pts.nodes), length(pts.z))
    tone_pts = Matrix{Float64}[]
    xover = sp.crossover_Hz
    for H in 1:nH
        f = H * bpf_Hz
        b = nearest_third_octave(f, bkeys)
        p2avg = pref2 * 10^(sp.harmonic_SPL_dB[H] / 10)
        use_eq8 = sp.tone_model === :eq8 || (sp.tone_model === :auto && !(isfinite(xover) && f ≥ xover))
        p2 = use_eq8 ? point_tone_p2(inp, H, 2π * f; pts) : fill(p2avg, length(pts.nodes), length(pts.z))
        push!(tone_pts, p2)
        total .+= p2 .* 10^(a_weight_dB(b) / 10)
    end
    idx = argmax(total)
    i, k = Tuple(idx)
    dBA_max = 10 * log10(total[idx] / pref2)
    dBA_avg = overall_dBA(sp)[1]
    return (; dBA_avg, dBA_max, X=pts.X[i], Y=pts.Y[i], z=pts.z[k], node=pts.nodes[i],
            tone_SPL_at_max=[10 * log10(tone_pts[H][idx] / pref2) for H in 1:nH],
            tone_SPL_avg=collect(sp.harmonic_SPL_dB), tone_points=tone_pts, pts, total_A=total)
end

"""Copy of `inp` with the named fields replaced (Phase 42 single-mode check)."""
_with_fields(inp::PainInputs; kw...) =
    PainInputs((haskey(kw, f) ? kw[f] : getfield(inp, f) for f in fieldnames(PainInputs))...)

"""
LOUDEST_PT (Phase 42, V-UNIT; criteria fixed 2026-10-23): (a) the interior-node volume average of
the point ⟨p²⟩ equals the space-average Eq. (8) within 1 % for H1–H3; (b) the loudest-point dB(A)
is ≥ the space-average dB(A); (c) one acoustic mode alone (q = 0) gives ⟨p²⟩ ∝ φ_i² at every node.
Supplementary (added 2026-10-23 after (a), labelled post-hoc): the same average with all CYL2D
nodes and the Eq. (C.10) weights. Test article (T1 inputs) and the aircraft example are reported.
"""
function _run_loudest_pt()
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    inp = r.inputs
    table = ValidationTableRow[]
    pts = cabin_interior_points(inp)
    qp = cabin_quadrature_points(inp)
    ok_a = true
    rat_all = Float64[]
    for H in 1:3
        ωH = 2π * 200.0 * H
        ref = tone_mean_square_pressure(inp, H, ωH)
        rat = point_volume_average(point_tone_p2(inp, H, ωH; pts), pts) / ref
        ok = abs(rat - 1) ≤ 0.01
        ok_a &= ok
        push!(table, ValidationTableRow("(a) H$H interior-node average / Eq. (8)", Float64(H), 1.0, rat, rat - 1, ok))
        push!(rat_all, point_volume_average(point_tone_p2(inp, H, ωH; pts=qp), qp) / ref)
    end
    lp = loudest_point(inp; bpf_Hz=200.0, n_harmonics=3, spectrum=r.spectrum)
    ok_b = lp.dBA_max ≥ lp.dBA_avg
    push!(table, ValidationTableRow("(b) loudest-point dB(A) − space-average dB(A)", 0.0, 0.0,
                                    lp.dBA_max - lp.dBA_avg, lp.dBA_max - lp.dBA_avg, ok_b))
    # (c) single acoustic mode, q = 0: point ⟨p²⟩/φ_i² constant over the nodes
    ac1 = inp.acoustic.modes[2]
    one = _with_fields(inp; q_max=0,
                       acoustic=Cyl2DResult(inp.acoustic.theta0_deg, [ac1], "single mode (42c)",
                                            inp.acoustic.NY, inp.acoustic.h, inp.acoustic.c0))
    p1 = point_tone_p2(one, 1, 2π * 200.0; pts)[:, 1]
    φ2 = [_phi_node_full(ac1, m, n)^2 for (m, n) in pts.nodes]
    sel = φ2 .> 1e-6 * maximum(φ2)
    ratios = p1[sel] ./ φ2[sel]
    spread = (maximum(ratios) - minimum(ratios)) / maximum(ratios)
    ok_c = spread ≤ 1e-9
    push!(table, ValidationTableRow("(c) single mode: relative spread of ⟨p²⟩/φ²", 0.0, 0.0, spread, spread, ok_c))
    # supplementary all-node ratios have no criterion: echoed in the inputs and the reason, not table rows
    xs = [200.0, 400.0, 600.0]
    series = [PlotSeries("space average", :reference_points, xs, lp.tone_SPL_avg; panel=1),
              PlotSeries("loudest point (overall dB(A) maximum)", :computed_points, xs, lp.tone_SPL_at_max; panel=1)]
    verdict = (ok_a && ok_b && ok_c) ? :met : :not_met
    return ValidationCaseResult("LOUDEST_PT", _today_iso(),
        (; criterion="(a) interior average within 1 % of Eq. (8); (b) loudest ≥ average; (c) single-mode shape",
           date="2026-10-23", dBA_avg=lp.dBA_avg, dBA_max=lp.dBA_max, X=lp.X, Y=lp.Y, z=lp.z,
           n_points=length(pts.nodes) * length(pts.z), all_node_ratio_posthoc=rat_all),
        table, series, verdict,
        "(a) $(ok_a ? "met" : "not met") (interior/Eq.8 = $(join(round.([t.computed for t in table[1:3]]; digits=3), ", ")); " *
        "all-node Φ_G $(join(round.(rat_all; digits=3), ", ")), post-hoc); (b) $(ok_b ? "met" : "not met"); " *
        "(c) $(ok_c ? "met" : "not met"). Test article: space average $(round(lp.dBA_avg; digits=1)) dB(A), " *
        "loudest point $(round(lp.dBA_max; digits=1)) dB(A) at X=$(round(lp.X; digits=2)) m, Y=$(round(lp.Y; digits=2)) m, " *
        "z=$(round(lp.z; digits=2)) m", "V-UNIT", "")
end

# Phase 81d (criterion fixed 2026-10-29 before the run): the point form of Eq. (8) on the converged CYL2D grid. The
# all-node Eq. (C.10)-weighted volume average must be within 1 % of Eq. (8) for H1–H3 at NY = 40 (at NY = 10 it is
# within 1.1 %, the residual being the discrete orthogonality of the coarse eigenvectors); the interior-node ratio of
# LOUDEST_PT check (a) is shown at NY = 40 as information.
const _P81_LOUDEST_NY = 40

function _run_loudest_pt_grid()
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2, NY=_P81_LOUDEST_NY)
    inp = r.inputs
    qp = cabin_quadrature_points(inp)
    pts = cabin_interior_points(inp)
    table = ValidationTableRow[]; all_r = Float64[]; int_r = Float64[]
    for H in 1:3
        ωH = 2π * 200.0 * H
        ref = tone_mean_square_pressure(inp, H, ωH)
        ra = point_volume_average(point_tone_p2(inp, H, ωH; pts=qp), qp) / ref
        ri = point_volume_average(point_tone_p2(inp, H, ωH; pts), pts) / ref
        push!(table, ValidationTableRow("H$H all-node (C.10) average / Eq. (8), NY = $(_P81_LOUDEST_NY)", H, 1.0, ra, ra - 1,
                                        abs(ra - 1) ≤ 0.01, "all nodes"))
        push!(table, ValidationTableRow("H$H interior-node average / Eq. (8), NY = $(_P81_LOUDEST_NY) (info)", H + 0.3, 1.0, ri, ri - 1,
                                        true, "interior nodes (info)"))
        push!(all_r, ra); push!(int_r, ri)
    end
    n_ok = count(t -> t.group == "all nodes" && t.within_tolerance, table)
    xs = [1.0, 2.0, 3.0]
    series = [PlotSeries("all nodes, Eq. (C.10) weights", :computed_points, xs, all_r; panel=1),
              PlotSeries("interior nodes only (information)", :computed_points, xs .+ 0.1, int_r; panel=1),
              PlotSeries("Eq. (8)", :reference_points, xs, ones(3); panel=1)]
    return ValidationCaseResult("LOUDEST_PT_GRID", _today_iso(),
        (; criterion="all-node (C.10) average within 1 % of Eq. (8), H1-H3, NY = 40", date="2026-10-29", NY=_P81_LOUDEST_NY,
           all_node=round.(all_r; digits=4), interior_info=round.(int_r; digits=4)),
        table, series, n_ok == 3 ? :met : :not_met,
        "$n_ok/3 within 1 % at NY = $(_P81_LOUDEST_NY): all-node $(join(round.(all_r; digits=4), ", ")); interior nodes " *
        "(information) $(join(round.(int_r; digits=4), ", "))", "V-UNIT", "")
end

function _iso42_validation_cases()
    return [ValidationCase("LOUDEST_PT", "Interior level at the loudest point (42)", "42",
        [_data_path("cr3813", "t1_interior_targets.csv")], FigureRef("CR-3813", "Eq. (8), App. C (C.9–C.11)", 30),
        "(a) interior-node volume average within 1 % of Eq. (8) (H1–H3); (b) loudest-point dB(A) ≥ space average; (c) one mode alone reproduces φ² (relative spread ≤ 1e-9).",
        "2026-10-23", "V-UNIT", _run_loudest_pt,
        PlotSpec(; xlabel="tone frequency (Hz)", ylabel="tone SPL (dB)", panel_titles=["LOUDEST_PT"],
                 error_mode=:none), ""),
        ValidationCase("LOUDEST_PT_GRID", "Point form of Eq. (8) on the converged CYL2D grid, NY = 40 (81d)", "81",
            String[], FigureRef("CR-3813", "Eq. (8), App. C (C.9–C.11)", 30),
            "The all-node Eq. (C.10)-weighted volume average of the point values within 1 % of Eq. (8) for H1–H3 at NY = 40; interior-node ratio as information.",
            "2026-10-29", "V-UNIT", _run_loudest_pt_grid,
            PlotSpec(; xlabel="harmonic", ylabel="volume average / Eq. (8)", panel_titles=["LOUDEST_PT_GRID"],
                     error_mode=:relative_pct, error_tol=1.0, error_ylabel="error vs Eq. (8) (%)"), "")]
end
