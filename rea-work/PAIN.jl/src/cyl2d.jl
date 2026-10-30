"""
CYL2D — cabin acoustic modes exactly as NASA-CR-3813 Appendix C (phase 15).

Half-cabin finite-difference grid (X ≥ 0), unit radius, θ measured from the bottom
centerline. The floor lies on a grid line and there are NY intervals from floor to
crown, h = (1 + cos θ0)/NY (Fig. C-3 uses NY = 10).

  * a node is in the cabin when r ≤ 1 + 0.4h and above the floor (inferred rule; any
    value in 0.31h–0.47h gives the Fig. C-3 row counts 3,5,6,6,7,7,7,7,7,7,6). NASA's printed grids of
    CR-172428 App. C need 0.43h–0.50h at 50° (NY = 11) and 0.40h–0.55h at 73.7° (NY = 8); the rule
    "0.45h, NY = 10 else the next grid that solves" was tested and not met (Phase 105, 2026-10-30), so the
    default is unchanged;
  * Eq. (C.1) at every cabin node (interior and boundary);
  * Eq. (C.2) at every boundary node with θ_mn of the node, θ_mn set to 0 below θ0;
  * the two missing equations: zero tangential gradient at the boundary points with two
    exterior neighbours closest to θ = π/4 and 3π/4;
  * Eqs. (C.3)–(C.6): P_E = −B_E⁻¹ B_I P_I, then the eigenproblem for P_I, solved
    separately for symmetric and antisymmetric modes; the two sets are merged, ranked
    by frequency and the first 20 kept;
  * Φ_G of Eq. (C.10) with C(j) = 1 on boundary and centerline nodes, 2 inside; ε_n of
    Eq. (C.11); boundary values at the boundary nodes at their own angles (Eq. 51),
    mirrored to X < 0 by symmetry, segment limits halfway between neighbours.

A singular B_E raises an error naming the grid (no pseudo-inverse).
Frequencies for a = 1 m, q = 0; scale with f → f/a. Three-dimensional cabin modes
n = (q, i) follow Eqs. (C.7), (C.9), (C.12) (`cabin_frequency_3d`, `cabin_modes_3d`).

Validation target: Fig. C-3 / Table C-1 for θ0 = 56.6° (V-CODE).
"""

struct AcousticMode
    index::Int
    f_Hz_unit::Float64
    symmetric::Bool
    gen_mass_unit::Float64          # Φ_G(i), Eq. (C.10): h² Σ C(j) φ_i²  (C = 1 boundary/centerline, 2 inside)
    phi_boundary::Vector{Float64}   # φ_i at the wall boundary points, θ from θ0 to 2π−θ0 (X<0 mirrored)
    theta_boundary_deg::Vector{Float64}
    eps_n::Float64                  # ε_n, Eq. (C.11), q = 0
    phi_floor::Vector{Float64}      # φ_i at the floor boundary points
    x_floor_unit::Vector{Float64}   # floor-point x for a = 1, from −sinθ0 to +sinθ0
    theta_lo_rad::Vector{Float64}   # wall segment limits (halfway between neighbours; ends at θ0, 2π−θ0)
    theta_hi_rad::Vector{Float64}
    x_lo_unit::Vector{Float64}      # floor segment limits (a = 1; ends at ±sinθ0)
    x_hi_unit::Vector{Float64}
    lambda_unit::Float64            # k² for a = 1 (= λ/h², Eq. C.1 with λ = k²h²)
    phi_nodes::Dict{Tuple{Int,Int},Float64}   # φ_i at every half-grid node (m, n), m = X/h ≥ 0, n = 0 at the floor (Fig. C-3 values)
end

# Segment limits halfway between adjacent boundary points, clipped at the ends (Eqs. 53–56).
function _segment_limits(v::AbstractVector{<:Real})
    n = length(v)
    lo = Vector{Float64}(undef, n)
    hi = Vector{Float64}(undef, n)
    for j in 1:n
        lo[j] = j == 1 ? v[1] : (v[j-1] + v[j]) / 2
        hi[j] = j == n ? v[n] : (v[j] + v[j+1]) / 2
    end
    return lo, hi
end

"""Mode built from boundary samples only; segment limits are taken halfway between the samples."""
function AcousticMode(index, f_Hz_unit, symmetric, gen_mass_unit, phi_boundary, theta_boundary_deg,
                      eps_n, phi_floor, x_floor_unit)
    tlo, thi = _segment_limits(deg2rad.(theta_boundary_deg))
    xlo, xhi = _segment_limits(x_floor_unit)
    k2 = (2π * f_Hz_unit / 340.0)^2
    return AcousticMode(index, f_Hz_unit, symmetric, gen_mass_unit, phi_boundary, theta_boundary_deg,
                        eps_n, phi_floor, x_floor_unit, tlo, thi, xlo, xhi, k2,
                        Dict{Tuple{Int,Int},Float64}())
end

struct Cyl2DResult
    theta0_deg::Float64
    modes::Vector{AcousticMode}
    notes::String
    NY::Int
    h::Float64
    c0::Float64
end

# CR-3813 Table C-1 (Phase III test article, θ0 = 56.6°). Frequencies in Hz for a = 1 m;
# the table implies c0 = 341 m/s. Modes 3 and 19 corrected 2026-10-20 (OCR: 175.889, 447.887).
const TABLE_C1_FREQ_HZ = (
    0.0, 99.501, 120.374, 175.889, 187.927, 220.381,
    253.162, 259.176, 289.674, 300.184, 324.597, 343.723,
    356.949, 366.051, 381.030, 393.310, 418.374, 424.029,
    434.105, 447.887,
)

# Generalized masses Φ_G(i) of Table C-1 (unit radius). Mode 5 reads 0.49815 on the page scan and mode 6 0.54585 (OCR gave 0.49515 and 0.54535, checked 2026-10-20).
const TABLE_C1_GENMASS = (
    2.59631, 1.03531, 0.72535, 0.68099, 0.72400, 0.49815,
    0.54585, 0.50751, 0.51521, 0.36571, 0.42606, 0.45440,
    0.46005, 0.36319, 0.39841, 0.28994, 0.34805, 0.37055,
    0.40244, 0.45490,
)

# true = symmetric, false = antisymmetric (Table C-1)
const TABLE_C1_SYMMETRIC = (
    true, false, true, false, true, true, false, true, false, true,
    false, true, false, true, true, false, true, false, true, false,
)

"""c0 back-solved from Table C-1 (a fitted scale, used only for display/comparison) [m/s]."""
const TABLE_C1_C0 = 341.0

# --- grid ---------------------------------------------------------------------------

struct _CylGrid
    h::Float64
    NY::Int
    θ0::Float64
    yfloor::Float64
    incab::Matrix{Bool}   # index [m+1, n+1], m = 0..M, n = 0..NY
end

function _build_grid(θ0::Float64, NY::Int; node_tol::Float64=0.4)
    h = (1 + cos(θ0)) / NY
    yfloor = -cos(θ0)
    M = ceil(Int, 1.6 / h)
    incab = falses(M + 1, NY + 1)
    for m in 0:M, n in 0:NY
        x = m * h
        y = yfloor + n * h
        incab[m+1, n+1] = hypot(x, y) <= 1 + node_tol * h
    end
    return _CylGrid(h, NY, θ0, yfloor, incab)
end

_in(g::_CylGrid, m::Int, n::Int) = begin
    m = abs(m)
    (n < 0 || n > g.NY || m >= size(g.incab, 1)) && return false
    g.incab[m+1, n+1]
end

_θnode(g::_CylGrid, m::Int, n::Int) = atan(m * g.h, -(g.yfloor + n * g.h))   # 0 at bottom, π at crown

const _NEIGH = ((1, 0), (-1, 0), (0, 1), (0, -1))

"""Half-cabin nodes (m ≥ 0) in cabin; centerline nodes are dropped for antisymmetric modes."""
function _solve_parity(g::_CylGrid, symmetric::Bool, nmax::Int)
    θ0 = g.θ0
    # kept nodes
    nodes = Tuple{Int,Int}[]
    id = Dict{Tuple{Int,Int},Int}()
    for m in 0:size(g.incab, 1)-1, n in 0:g.NY
        g.incab[m+1, n+1] || continue
        (!symmetric && m == 0) && continue
        push!(nodes, (m, n))
        id[(m, n)] = length(nodes)
    end
    nI = length(nodes)

    # reference to a grid point: (:node|:ext, index, sign) or nothing (antisymmetric centerline)
    ext = Dict{Tuple{Int,Int},Int}()
    function ref(m::Int, n::Int; create::Bool)
        s = 1.0
        if m < 0
            m = -m
            s = symmetric ? 1.0 : -1.0
        end
        (m == 0 && !symmetric) && return nothing
        if _in(g, m, n)
            return (:node, id[(m, n)], s)
        end
        if !haskey(ext, (m, n))
            create || return nothing
            ext[(m, n)] = length(ext) + 1
        end
        return (:ext, ext[(m, n)], s)
    end

    isbnd = falses(nI)
    nextnb = zeros(Int, nI)
    for (i, (m, n)) in enumerate(nodes)
        k = 0
        seen = Set{Tuple{Int,Int}}()
        for (dm, dn) in _NEIGH
            mm, nn = m + dm, n + dn
            r = ref(mm, nn; create=true)
            r === nothing && continue
            if r[1] == :ext
                isbnd[i] = true
                key = (abs(mm), nn)
                if !(key in seen)
                    push!(seen, key)
                    k += 1
                end
            end
        end
        nextnb[i] = k
    end
    nE = length(ext)
    nB = count(isbnd)
    if nE - nB != 2
        error("CYL2D: grid θ0=$(rad2deg(θ0))°, NY=$(g.NY) gives $(nE) exterior points for $(nB) boundary points " *
              "($(symmetric ? "symmetric" : "antisymmetric")); App. C needs exactly 2 more exterior points than " *
              "boundary points (the two tangential-gradient equations). Choose another NY.")
    end

    # R_I, R_E of Eq. (C.3): 4 P_j − Σ neighbours = λ P_j
    RI = zeros(nI, nI)
    RE = zeros(nI, nE)
    for (i, (m, n)) in enumerate(nodes)
        RI[i, i] += 4.0
        for (dm, dn) in _NEIGH
            r = ref(m + dm, n + dn; create=false)
            r === nothing && continue
            if r[1] == :node
                RI[i, r[2]] -= r[3]
            else
                RE[i, r[2]] -= r[3]
            end
        end
    end

    # B_I, B_E of Eq. (C.4): one equation per boundary node (C.2) + two tangential equations
    cand = [i for i in 1:nI if isbnd[i] && nextnb[i] == 2]
    function closest(target)
        isempty(cand) && error("CYL2D: no boundary point with two exterior neighbours (θ0=$(rad2deg(θ0))°, NY=$(g.NY))")
        cand[argmin([abs(_θnode(g, nodes[i]...) - target) for i in cand])]
    end
    t1, t2 = closest(π / 4), closest(3π / 4)
    t1 == t2 && error("CYL2D: tangential-gradient points coincide (θ0=$(rad2deg(θ0))°, NY=$(g.NY))")

    BI = zeros(nE, nI)
    BE = zeros(nE, nE)
    row = 0
    function addterm!(row, r, coef)
        r === nothing && return
        if r[1] == :node
            BI[row, r[2]] += coef * r[3]
        else
            BE[row, r[2]] += coef * r[3]
        end
    end
    for i in 1:nI
        isbnd[i] || continue
        m, n = nodes[i]
        θ = _θnode(g, m, n)
        θe = θ < θ0 ? 0.0 : θ                  # θ_mn set to 0 below θ0 (Eq. C.2 text)
        c, s = cos(θe), sin(θe)
        # (P[m,n+1] − P[m,n−1]) cosθ = (P[m+1,n] − P[m−1,n]) sinθ
        row += 1
        addterm!(row, ref(m, n + 1; create=false), c)
        addterm!(row, ref(m, n - 1; create=false), -c)
        addterm!(row, ref(m + 1, n; create=false), -s)
        addterm!(row, ref(m - 1, n; create=false), s)
        if i == t1 || i == t2
            # zero tangential gradient: (P[m+1,n] − P[m−1,n]) cosθ + (P[m,n+1] − P[m,n−1]) sinθ = 0
            row += 1
            addterm!(row, ref(m + 1, n; create=false), c)
            addterm!(row, ref(m - 1, n; create=false), -c)
            addterm!(row, ref(m, n + 1; create=false), s)
            addterm!(row, ref(m, n - 1; create=false), -s)
        end
    end
    row == nE || error("CYL2D: internal equation count $(row) ≠ $(nE)")
    cB = cond(BE)
    (isfinite(cB) && cB < 1e12) ||
        error("CYL2D: B_E is singular (cond=$(cB)) for θ0=$(rad2deg(θ0))°, NY=$(g.NY), " *
              "$(symmetric ? "symmetric" : "antisymmetric") modes; choose another NY (no pseudo-inverse is used)")

    A = RI - RE * (BE \ BI)                     # Eq. (C.6)
    ev = eigen(A)
    λ = real.(ev.values)
    order = sortperm(λ)[1:min(nmax, nI)]
    # Phase 79b (2026-10-28): the curved-wall ghost-point rows make A non-symmetric, and on refined grids some high
    # eigenvalues come in complex pairs; only the kept modes must be real (|Im|/|Re| ≤ 1e-3, rule fixed before the
    # convergence run). Until 2026-10-28 any complex eigenvalue, kept or not, rejected the grid.
    im_rel = maximum(abs(imag(ev.values[k])) / max(abs(real(ev.values[k])), 1e-12) for k in order[2:end]; init=0.0)
    im_rel ≤ 1e-3 ||
        error("CYL2D: complex eigenvalues among the kept modes (max |Im|/|Re| = $(im_rel)) for θ0=$(rad2deg(θ0))°, NY=$(g.NY)")
    return (nodes=nodes, id=id, isbnd=isbnd, λ=λ[order], V=real.(ev.vectors[:, order]))
end

"""
    cyl2d_modes(theta0_deg; n_modes=20, NY=10, c0=340.0) -> Cyl2DResult

Cabin acoustic modes of CR-3813 Appendix C for a = 1 m, q = 0. `NY` is the number of grid
intervals from floor to crown (Fig. C-3 uses 10). `c0` converts eigenvalues to Hz
(use `TABLE_C1_C0` = 341 m/s to compare with Table C-1).
"""
function cyl2d_modes(theta0_deg::Real; n_modes::Int=20, NY::Int=10, c0::Float64=340.0,
                     node_tol::Float64=0.4)
    θ0 = deg2rad(float(theta0_deg))
    g = _build_grid(θ0, NY; node_tol=node_tol)
    h = g.h
    A_cab = π - θ0 + cos(θ0) * sin(θ0)         # V/(a²L), Eq. (C.11)

    entries = NamedTuple[]
    for sym in (true, false)
        sol = _solve_parity(g, sym, n_modes + 2)
        nodes, isbnd = sol.nodes, sol.isbnd
        for k in eachindex(sol.λ)
            λ = sol.λ[k] < 0 && sol.λ[k] > -1e-8 ? 0.0 : sol.λ[k]
            λ < 0 && continue                    # spurious negative eigenvalue
            φn = sol.V[:, k]
            mx = maximum(abs, φn)
            φn = φn ./ mx
            # sign convention: the largest-magnitude value is positive (the eigenvector sign is arbitrary)
            φn[argmax(abs.(φn))] < 0 && (φn = -φn)
                    # Eq. (C.10): C = 1 on boundary and centerline nodes, 2 inside
            gm = 0.0
            for (i, (m, n)) in enumerate(nodes)
                C = (isbnd[i] || m == 0) ? 1.0 : 2.0
                gm += C * φn[i]^2
            end
            gm *= h^2
            # wall boundary points (not on the floor row), θ ascending on the X>0 side
            wall = [(_θnode(g, m, n), φn[i]) for (i, (m, n)) in enumerate(nodes) if isbnd[i] && n > 0]
            # antisymmetric: the centerline crown point stays in the list with φ = 0
            !sym && g.incab[1, g.NY+1] && push!(wall, (π, 0.0))
            sort!(wall; by=first)
            θr = [max(w[1], θ0) for w in wall]
            φr = [w[2] for w in wall]
            # mirror to X<0 (θ → 2π−θ); the centerline crown point is not repeated
            keep = [!(abs(t - π) < 1e-9) for t in θr]
            θl = reverse(2π .- θr[keep])
            φl = reverse((sym ? 1.0 : -1.0) .* φr[keep])
            θall = vcat(θr, θl)
            φall = vcat(φr, φl)
            tlo, thi = _segment_limits(θall)
            tlo[1] = θ0
            thi[end] = 2π - θ0
            # floor boundary points (floor row)
            fl = [(m, φn[i]) for (i, (m, n)) in enumerate(nodes) if n == 0]
            !sym && push!(fl, (0, 0.0))        # antisymmetric: floor centerline point, φ = 0
            sort!(fl; by=first)
            xr = [f[1] * h for f in fl]
            fr = [f[2] for f in fl]
            keepf = [x > 1e-12 for x in xr]
            xl = reverse(-xr[keepf])
            fL = reverse((sym ? 1.0 : -1.0) .* fr[keepf])
            xall = vcat(xl, xr[.!keepf], xr[keepf])
            fall = vcat(fL, fr[.!keepf], fr[keepf])
            xlo, xhi = _segment_limits(xall)
            xlo[1] = -sin(θ0)
            xhi[end] = sin(θ0)
            nodal = Dict{Tuple{Int,Int},Float64}(nodes[i] => φn[i] for i in eachindex(nodes))
            if !sym
                for n in 0:g.NY
                    g.incab[1, n+1] && (nodal[(0, n)] = 0.0)
                end
            end
            push!(entries, (nodal=nodal, λ=λ, sym=sym, gm=gm, θ=θall, φ=φall, tlo=tlo, thi=thi,
                            x=xall, f=fall, xlo=xlo, xhi=xhi))
        end
    end
    sort!(entries; by=e -> e.λ)
    length(entries) >= n_modes || error("CYL2D: only $(length(entries)) modes available for NY=$NY, need $n_modes")
    modes = AcousticMode[]
    for (kk, e) in enumerate(entries[1:n_modes])
        k2 = e.λ / h^2
        f = (c0 / (2π)) * sqrt(k2)
        push!(modes, AcousticMode(kk - 1, f, e.sym, e.gm, e.φ, rad2deg.(e.θ), A_cab / e.gm,
                                  e.f, e.x, e.tlo, e.thi, e.xlo, e.xhi, k2, e.nodal))
    end
    return Cyl2DResult(float(theta0_deg), modes,
        "App. C half-cabin finite differences, NY=$NY, h=$(round(h; digits=5)); compare to Table C-1 / Fig. C-3 (V-CODE).",
        NY, h, c0)
end

"""
    cyl2d_modes_search(theta0_deg; NY0=10, NY_max=40, max_change=0.01, kw...) -> (result, next_change, NY_next)

Assumption 13a(b) for grids other than the paper's: starting at `NY0`, increase NY by 1 until
B_E is non-singular and every eigenvalue is real to 1e-3 (those are the only grids where
App. C is solvable); accept the first valid grid only if the next valid NY changes the first
`n_modes` non-zero frequencies by at most `max_change` (1 %); otherwise raise an error giving the
change. Returns the accepted result, the largest relative change and the next valid NY.
"""
function cyl2d_modes_search(theta0_deg::Real; NY0::Int=10, NY_max::Int=40, max_change::Float64=0.01, kw...)
    valid = Tuple{Int,Cyl2DResult}[]
    for NY in NY0:NY_max
        try
            push!(valid, (NY, cyl2d_modes(theta0_deg; NY=NY, kw...)))
        catch e
            e isa ErrorException && startswith(e.msg, "CYL2D") || rethrow()
        end
        length(valid) == 2 && break
    end
    length(valid) == 2 || error("CYL2D: fewer than two valid grids for θ0=$(theta0_deg)° with NY in $NY0:$NY_max")
    (NY1, r1), (NY2, r2) = valid
    ch = maximum(abs(a.f_Hz_unit - b.f_Hz_unit) / b.f_Hz_unit for (a, b) in zip(r1.modes, r2.modes) if b.f_Hz_unit > 0)
    ch <= max_change ||
        error("CYL2D: first valid grid NY=$NY1 and next valid NY=$NY2 differ by $(round(100ch; digits=2)) % (> $(100max_change) %); not accepted")
    return r1, ch, NY2
end

"""
    cyl2d_modes_solvable(theta0_deg; NY=10, NY_max=NY+10, kw...) -> Cyl2DResult

Production grid for any floor angle (Q60, 2026-10-29): App. C on the requested `NY` (the paper's 10) when that grid
is solvable, otherwise on the next larger NY that is (B_E non-singular, kept modes real), with a warning. The grid
used is `result.NY`. For θ0 = 56.6° this is NY = 10 unchanged; NY = 10 has no solution at e.g. θ0 = 40° or 45.3°.
"""
function cyl2d_modes_solvable(theta0_deg::Real; NY::Int=10, NY_max::Int=NY + 10, kw...)
    for ny in NY:NY_max
        try
            r = cyl2d_modes(theta0_deg; NY=ny, kw...)
            ny == NY || @warn "CYL2D: NY = $NY has no App. C solution for θ0 = $(theta0_deg)°; using NY = $ny (next solvable grid)"
            return r
        catch e
            e isa ErrorException && startswith(e.msg, "CYL2D") || rethrow()
        end
    end
    error("CYL2D: no solvable App. C grid for θ0 = $(theta0_deg)° with NY in $NY:$NY_max")
end

scale_acoustic_freq(f_unit::Real, a::Real) = float(f_unit) / float(a)

function acoustic_boundary_value(mode::AcousticMode, θ_deg::Real)
    θs = mode.theta_boundary_deg
    φs = mode.phi_boundary
    θ = clamp(float(θ_deg), first(θs), last(θs))
    for i in 1:length(θs)-1
        if θs[i] ≤ θ ≤ θs[i+1]
            t = (θ - θs[i]) / (θs[i+1] - θs[i] + eps())
            return (1 - t) * φs[i] + t * φs[i+1]
        end
    end
    return φs[end]
end

# --- three-dimensional cabin modes (phase 15b) ------------------------------------------

"""
CYL2D's own sound speed [m/s]: CYL2D computes its frequencies for a = 1 m at this speed and PAIN keeps them (Table C-1;
CR-172428 App. B p. 185 and App. C p. 212 print the 2-D part at 341 m/s whatever the deck's c; Phase 103 D3, Phase 106).
"""
const CYL2D_C0 = TABLE_C1_C0

"""
    cabin_frequency_3d(mode, a, L, q; c0, c2d=CYL2D_C0) -> Hz

Eq. (C.7)/(C.12): f_n = √[(f_i/a)² + (q c0/(2L))²] for the 3-D mode n = (q, i), with the 2-D frequency f_i from CYL2D at
its own speed `c2d` (341 m/s, as PAIN does since Phase 106) and the axial term at the cabin's `c0` (card 2).
`c2d = c0` gives the form used before Phase 106 (both parts at `c0`).
"""
cabin_frequency_3d(mode::AcousticMode, a::Real, L::Real, q::Int; c0::Real=340.0, c2d::Real=CYL2D_C0) =
    sqrt((c2d / (2π))^2 * mode.lambda_unit / a^2 + (q * c0 / (2L))^2)

"""
    cabin_eps_3d(mode, q) -> ε_n

Normalization ε_n = V/∫φ_n² dV with φ_n = φ_i(j) cos(qπz/L) (Eq. C.9): the q = 0 value of
Eq. (C.11) for q = 0, twice that for q > 0 (∫cos² dz = L/2). This is Eq. (C.11) as printed
(CR-3813 pp. C-6, C-7: ε_q = 2 for q = 0, 1 for q > 0; checked in plan step 19c).
"""
cabin_eps_3d(mode::AcousticMode, q::Int) = q == 0 ? mode.eps_n : 2 * mode.eps_n

"""Axial truncation q_max = ⌈2 ω_H L/(π c0)⌉ (V-ASSUMED; CR-3813 does not state it)."""
axial_truncation(ωH::Real, L::Real, c0::Real) = ceil(Int, 2 * ωH * L / (π * c0))

"""All 3-D cabin modes n = (q, i), q = 0..q_max, as (q, i, f_Hz, eps_n) tuples sorted by frequency."""
function cabin_modes_3d(cy::Cyl2DResult, a::Real, L::Real, q_max::Int; c0::Real=340.0, c2d::Real=CYL2D_C0)
    out = NamedTuple{(:q, :i, :f_Hz, :eps_n),Tuple{Int,Int,Float64,Float64}}[]
    for q in 0:q_max, m in cy.modes
        f = cabin_frequency_3d(m, a, L, q; c0=c0, c2d=c2d)
        push!(out, (q=q, i=m.index, f_Hz=f, eps_n=cabin_eps_3d(m, q)))
    end
    sort!(out; by=x -> x.f_Hz)
    return out
end
