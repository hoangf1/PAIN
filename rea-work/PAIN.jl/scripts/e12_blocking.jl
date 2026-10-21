# Plan phase 14a: Fig. E-12 on-line blocking check (CR-3813 App. E, p. E-20).
# Run from rea-work\PAIN.jl:  julia --project=. scripts/e12_blocking.jl
using PAIN, Printf

root = normpath(joinpath(@__DIR__, "..", ".."))
data = joinpath(root, "data")
REPORT = joinpath(root, "docs", "validation_reports", "e12_blocking.md")

function readcurve(path)
    rows = [split(strip(l), ',') for l in eachline(path) if !isempty(strip(l)) && !startswith(l, '#')][2:end]
    c = Dict{Int,Vector{Tuple{Float64,Float64,String}}}()
    for r in rows
        push!(get!(c, parse(Int, r[1]), Tuple{Float64,Float64,String}[]), (parse(Float64, r[2]), parse(Float64, r[3]), r[4]))
    end
    for v in values(c); sort!(v; by = t -> t[1]); end
    return c
end

# linear interpolation along a polyline sorted by increasing X; NaN outside its range
function interp(pts, x)
    (x < pts[1][1] || x > pts[end][1]) && return NaN
    for i in 1:length(pts)-1
        x1, y1 = pts[i][1], pts[i][2]; x2, y2 = pts[i+1][1], pts[i+1][2]
        x1 <= x <= x2 && return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
    end
    return pts[end][2]
end

# δ_dig: max |A - B| at the X of every A and B point inside the common range
function delta_dig(A, B)
    δ = Dict{Int,Float64}()
    for H in 1:3
        d = 0.0
        for (P, Q) in ((A[H], B[H]), (B[H], A[H]))
            for p in P
                q = interp(Q, p[1]); isnan(q) && continue
                d = max(d, abs(p[2] - q))
            end
        end
        δ[H] = d
    end
    return δ
end

predA, predB = readcurve(joinpath(data, "e12", "e12_predicted_A.csv")), readcurve(joinpath(data, "e12", "e12_predicted_B.csv"))
measA, measB = readcurve(joinpath(data, "e12", "e12_measured_A.csv")), readcurve(joinpath(data, "e12", "e12_measured_B.csv"))
δpred, δmeas = delta_dig(predA, predB), delta_dig(measA, measB)
δ_dig = maximum(vcat(collect(values(δpred)), collect(values(δmeas))))
δ_pred = maximum(values(δpred))

# mean of the two passes on the union of their X values, inside both ranges
function meancurve(A, B)
    M = Dict{Int,Vector{Tuple{Float64,Float64,String}}}()
    for H in 1:3
        xs = sort(unique(vcat([p[1] for p in A[H]], [p[1] for p in B[H]])))
        M[H] = [(x, (interp(A[H], x) + interp(B[H], x)) / 2, "mean") for x in xs if !isnan(interp(A[H], x)) && !isnan(interp(B[H], x))]
    end
    return M
end
predM, measM = meancurve(predA, predB), meancurve(measA, measB)

# Eq. (43) on the l = 1 line: F(γ) from the test-cylinder geometry of the e11 path (run_pain_pipeline defaults)
fuse = FuselageGeometry(1.803, 0.508, 56.6)
prop = PropellerPlacement(0.965, 90.0, 0.90)
pts = [p for p in grid_points(fuse, prop, GridSpec()) if p.ell == 1]
D = 0.762
X3D = [p.x3 / D for p in pts]
γ = [incidence_angle_deg(fuse, prop, p.theta_deg, p.z) for p in pts]
ΔL = [delta_L_blocking_dB(g; variant = R1) for g in γ]

# free-field input on the line: ANOPP Table 8 (NASA's predicted free field, the input of its predicted E-12 curve)
rows = [split(strip(l), ',') for l in eachline(joinpath(data, "anopp_table8_spl_dB.csv")) if !isempty(strip(l)) && !startswith(l, '#')][2:end]
t8 = [parse.(Float64, r[2:4]) for r in rows]
# secondary input: digitized Fig. E-11 measured line (mean of A and B)
e11 = PAIN.default_e11_paths()
eA, eB = PAIN._read_csv_numeric(e11.A), PAIN._read_csv_numeric(e11.B)

tol = δ_pred + 0.5
lines = String[]
push!(lines, "# Fig. E-12 on-line blocking check (plan phase 14a)", "",
    "Class: **V-CODE** for Eq. (43) against NASA's predicted curve (same equation, same free-field input); **V-EXP** for the measured curve (recorded, no pass mark). Tests Eq. (43) and the incidence angle only, not GEXT.", "",
    "Criterion fixed 2026-10-20 (plan 14a, before comparison): Eq. (43) applied to the l = 1 free field reproduces the digitized predicted E-12 curve within δ_dig + 0.5 dB at every point.", "",
    "Geometry: test cylinder a = 0.508 m, hub r_p = 0.965 m, z_p = 0.90 m, φ_p = 90°, D = 0.762 m, variant R1 (full Eq. 43, as in NASA's PAIN). Free-field input: ANOPP Table 8 (l = 1), the predicted free field NASA fed to Eq. (43). Digitized curves are the mean of two passes; pass A used pixel calibration, pass B a grid overlay, both by eye by the same reader.", "",
    "## δ_dig (max |A − B| on the E-12 curves)", "",
    "| Curve | H1 | H2 | H3 |", "|---|---|---|---|",
    @sprintf("| predicted | %.2f | %.2f | %.2f |", δpred[1], δpred[2], δpred[3]),
    @sprintf("| measured | %.2f | %.2f | %.2f |", δmeas[1], δmeas[2], δmeas[3]), "",
    @sprintf("δ_dig (all) = %.2f dB; δ_dig (predicted) = %.2f dB; tolerance for the predicted comparison = δ_dig(predicted) + 0.5 = %.2f dB.", δ_dig, δ_pred, tol),
    δ_dig <= 1.0 ? "The E-11 digitization gate (≤ 1.0 dB) is met." : "The E-11 digitization gate (≤ 1.0 dB) is NOT met; the criterion is kept as written (δ_dig + 0.5) and the larger δ_dig is reported.", "")
npass = 0; ntot = 0; worst = 0.0
push!(lines, "## Eq. (43) on Table 8 against predicted E-12", "",
    "| k | X3/D | γ [deg] | ΔL [dB] | H | Table 8 + ΔL | E-12 predicted | diff | within tol |", "|---|---|---|---|---|---|---|---|---|")
for (i, p) in enumerate(pts), H in 1:3
    pr = interp(predM[H], X3D[i]); isnan(pr) && continue
    c = t8[i][H] + ΔL[i]; d = c - pr; global ntot += 1; ok = abs(d) <= tol; global npass += ok; global worst = max(worst, abs(d))
    push!(lines, @sprintf("| %d | %.3f | %.1f | %.2f | %d | %.1f | %.1f | %+.1f | %s |", p.k, X3D[i], γ[i], ΔL[i], H, c, pr, d, ok ? "yes" : "NO"))
end
push!(lines, "", @sprintf("**Result: %d of %d points within %.2f dB; largest |difference| %.1f dB.** %s", npass, ntot, tol, worst, npass == ntot ? "PASS" : "FAIL (recorded, not tuned)"), "")
push!(lines, "## Eq. (43) on the digitized E-11 measured line against measured E-12 (V-EXP, no pass mark)", "",
    "| k | X3/D | H | E-11 measured + ΔL | E-12 measured | diff |", "|---|---|---|---|---|---|")
keys_ = (:SPL_H1_dB, :SPL_H2_dB, :SPL_H3_dB)
for (i, p) in enumerate(pts), H in 1:3
    me = interp(measM[H], X3D[i]); isnan(me) && continue
    e = (eA[keys_[H]][i] + eB[keys_[H]][i]) / 2 + ΔL[i]
    push!(lines, @sprintf("| %d | %.3f | %d | %.1f | %.1f | %+.1f |", p.k, X3D[i], H, e, me, e - me))
end
push!(lines, "", "Measured E-12 values are linear interpolations between the circles (the dashed curve), inside the range of the circles only. NASA reports predicted minus measured of 0–5 dB near the plane of rotation (CR-3813 App. E).", "",
    "## Digitization notes", "", "- The H2 measured marker at X3/D = 0.69 was read in pass A only; pass B did not cover it (outside the grid crops), so it is not in δ_dig.",
    "- Dashed measured segments without a circle (point_type = end) are used for δ_dig but are not measurements.",
    "- The predicted H2 curve starts where it merges with the dashed curve (X3/D ≈ 0.57–0.60); its start is the least certain point.")
write(REPORT, join(lines, "\n") * "\n")
println(join(lines, "\n"))
println("\nwrote ", REPORT)
