#!/usr/bin/env julia
# Plan phase 32: GEXT importance bound (e11 path). Criteria pre-registered 2026-10-19;
# re-dated 2026-10-21 for cabin inputs = 18a-r (η_T = 0.5). No src/ change: GEXT kwargs
# are applied inside this script (override of freefield_from_e11_csv's extend_line_to_grid call).
using Pkg; Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN, Printf, Dates

paths = default_e11_paths()
tg = PAIN._read_csv_numeric(joinpath(dirname(paths.A), "t1_interior_targets.csv"))
means = tg[:measured_mean_SPL_dB][1:3]
nasa = tg[:nasa_pain_pred_dB][1:3]
lows = tg[:measured_low_dB][1:3]
highs = tg[:measured_high_dB][1:3]
t2tg = PAIN._read_csv_numeric(joinpath(dirname(paths.A), "t2_third_octave_targets.csv"))

"""Build e11 FreeFieldHarmonicGrid with explicit GEXT options (script-local override)."""
function e11_with_gext(; falloff_exponent=1.0, falloff_floor=0.0, delay_scale=1.0,
                        n_harmonics=3, bpf_Hz=200.0)
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    prop = PropellerPlacement(0.965, 90.0, 0.90)
    spec = GridSpec()
    amp = PAIN._read_csv_numeric(paths.A)
    ph = PAIN._read_csv_numeric(paths.phases)
    anopp = PAIN._read_csv_numeric(paths.anopp_spl)
    nH = n_harmonics
    k_max = spec.k_max
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
    ωH = [2π * H * bpf_Hz for H in 1:nH]
    amps, phases = extend_line_to_grid(line_amps, line_phases, pts; omega_H=ωH,
                                       falloff_exponent, falloff_floor, delay_scale)
    ff = FreeFieldHarmonicGrid(pts, collect(1:nH), amps, phases, :e11_digitized,
                               "e11 GEXT n=$falloff_exponent f=$falloff_floor d=$delay_scale", bpf_Hz)
    return fuse, prop, ff, line_amps
end

function pipeline_from_ff(fuse, prop, ff; blocking=R2,
                          C_struc=3.0, η_lining=0.5, mass_scale=1.0, bb_j2_scale=0.5)
    bl = apply_blocking(ff, fuse, prop; variant=blocking)
    acoustic = cyl2d_modes(56.6; n_modes=20, NY=10)
    structural = structural_modes_from_table_d1(; L=test_article_length(), a=0.508, theta0_deg=56.6, n_keep=32)
    ΔA = (π * 0.508 / 18)^2
    p3 = phase3_trim(; a=0.508, L=test_article_length(), theta0_deg=56.6, η_lining=η_lining)
    m_wall = p3.m_wall * mass_scale
    mech = p3.mech
    # Scale trim-path masses with mass_scale (32e trim-mass ±20 %)
    if mass_scale != 1.0
        mech = MechanicalPath(m_t=mech.m_t * mass_scale, A_t=mech.A_t, h_t=mech.h_t, c_t=mech.c_t,
                              η_t=mech.η_t, m=m_wall, A=mech.A, h=mech.h, c_l=mech.c_l,
                              N_points=mech.N_points, line_length=mech.line_length)
    end
    inp = PainInputs(fuse, prop, structural, acoustic, bl.amplitudes, bl.phases, bl.pts, ΔA;
                     sidewall=p3.sidewall, endplates=p3.ends, mech=mech, m_wall=m_wall,
                     C_struc=C_struc)
    spec_out = interior_spl(inp; bpf_Hz=bl.bpf_Hz, n_harmonics=3, bb_j2_scale=bb_j2_scale)
    return spec_out, inp, bl
end

function t1_gate(spl, H)
    d_mean = spl - means[H]
    d_nasa = spl - nasa[H]
    in_env = lows[H] <= spl <= highs[H]
    pass_mean = abs(d_mean) <= 4.0
    pass_nasa = in_env && abs(d_nasa) <= 4.0
    pass = pass_mean || pass_nasa
    # margin to nearest gate edge (positive = inside)
    m_mean = 4.0 - abs(d_mean)
    m_nasa = pass_nasa ? (4.0 - abs(d_nasa)) : -abs(d_nasa)
    margin = pass_mean ? m_mean : (pass_nasa ? m_nasa : max(m_mean, m_nasa))
    return (; pass, d_mean, d_nasa, margin)
end

# --- variants ---
falloff_vars = [(n, f) for n in (0.5, 1.0, 2.0) for f in (0.0, 0.1, 0.3)]
push!(falloff_vars, (0.0, 0.0))  # flat
delay_vars = [(1.0, 0.0, 0.0), (1.0, 0.0, -1.0), (1.0, 0.0, 0.5), (1.0, 0.0, 2.0)]  # off, flip, ×0.5, ×2

io = IOBuffer()
println(io, "# GEXT importance bound (phase 32)\n")
println(io, "Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)\n")
println(io, "Generated $(Dates.today()) by `scripts/run/run_gext_bound.jl`. Criteria: `VALIDATION_GUIDELINE.md` §2.2.1, re-dated 2026-10-21 for cabin inputs = 18a-r (η_T = 0.5). Flip = any H changing pass↔fail vs nominal (any-H rule).\n")

# Identity / nominal
println("Running nominal (identity)...")
fuse, prop, ff0, line0 = e11_with_gext()
spec0, _, bl0 = pipeline_from_ff(fuse, prop, ff0)
t1_0 = [spec0.harmonic_SPL_dB[H] for H in 1:3]
gate0 = [t1_gate(t1_0[H], H) for H in 1:3]
println(io, "## 32b Identity control\n")
println(io, "Nominal T1 H1–H3: $(join([@sprintf("%.2f", x) for x in t1_0], ", ")) dB (amplitude convention fixed 2026-10-21, post-hoc).\n")
println(io, "| H | SPL dB | d_mean | d_nasa | pass | margin |\n|---:|---:|---:|---:|---|---:|")
for H in 1:3
    g = gate0[H]
    @printf(io, "| %d | %.2f | %+.2f | %+.2f | %s | %+.2f |\n", H, t1_0[H], g.d_mean, g.d_nasa, g.pass ? "PASS" : "FAIL", g.margin)
end
println(io)

# mean f² of H=3 free-field amplitudes on grid (for T2 analytic offset)
function mean_f2(bl)
    a = bl.amplitudes[:, :, 3]
    return sum(a .^ 2) / length(a)
end
f2_0 = mean_f2(bl0)

results = []
function record!(name, n, f, d; delay_only=false)
    println("  variant $name ...")
    fuse, prop, ff, _ = e11_with_gext(; falloff_exponent=n, falloff_floor=f, delay_scale=d)
    spec, _, bl = pipeline_from_ff(fuse, prop, ff)
    t1 = [spec.harmonic_SPL_dB[H] for H in 1:3]
    gates = [t1_gate(t1[H], H) for H in 1:3]
    flip = any(gates[H].pass != gate0[H].pass for H in 1:3)
    f2 = mean_f2(bl)
    t2_off = 10 * log10(f2 / f2_0)
    push!(results, (; name, n, f, d, t1, gates, flip, t2_off))
    return flip
end

println(io, "## 32c Falloff grid\n")
println(io, "| variant | n | f | H1 | H2 | H3 | d_mean H1–3 | flip |\n|---|---:|---:|---:|---:|---:|---|---|")
for (n, f) in falloff_vars
    name = @sprintf("n=%.1f,f=%.1f", n, f)
    fl = record!(name, n, f, 1.0)
    r = results[end]
    @printf(io, "| %s | %.1f | %.1f | %.2f | %.2f | %.2f | %+.2f,%+.2f,%+.2f | %s |\n",
            name, n, f, r.t1..., (r.gates[H].d_mean for H in 1:3)..., fl ? "**yes**" : "no")
end
println(io)

println(io, "## 32d Delay variants (falloff nominal)\n")
println(io, "| variant | delay_scale | H1 | H2 | H3 | flip | T2 offset dB |\n|---|---:|---:|---:|---:|---|---:|")
for (n, f, d) in delay_vars
    name = d == 0 ? "delay off" : d == -1 ? "sign flip" : @sprintf("delay ×%.1f", d)
    fl = record!(name, n, f, d; delay_only=true)
    r = results[end]
    @printf(io, "| %s | %g | %.2f | %.2f | %.2f | %s | %+.3f |\n",
            name, d, r.t1..., fl ? "**yes**" : "no", r.t2_off)
end
# conditional corner if delay non-null on T1
delay_rows = filter(r -> occursin("delay", r.name) || occursin("sign", r.name), results)
delay_null = all(all(abs(r.t1[H] - t1_0[H]) < 1e-9 for H in 1:3) for r in delay_rows)
if !delay_null
    println(io, "\nConditional corner n=0.5, delay ×2:\n")
    fl = record!("n=0.5 + delay×2", 0.5, 0.0, 2.0)
    r = results[end]
    @printf(io, "H1–H3 = %.2f, %.2f, %.2f; flip=%s\n", r.t1..., fl ? "yes" : "no")
else
    println(io, "\nDelay variants exactly null on T1 → sanity bucket (code/data finding).\n")
end
println(io)

println(io, "## 32e Parameter-sensitivity comparator (±20 %)\n")
println(io, "One-at-a-time over the 13a ranges of η_t (facing/septum via `η_lining`), C of Eq. (80), trim-mass scale, and `bb_j2_scale` (T2 bands only). Order-of-magnitude referent vs GEXT flips — **not** a second bound; no parameter adopted from these runs.\n")
println(io, "| parameter | value | H1 | H2 | H3 | ΔH1 dB | T2 1.25 kHz Δ dB |\n|---|---:|---:|---:|---:|---:|---:|")
# Nominal T2 band level at 1250 Hz for offset
function t2_1250(spec)
    third = spec.third_octave_SPL_dB
    isempty(third) && return NaN
    bands = sort(collect(keys(third)))
    k = bands[argmin(abs.(bands .- 1250.0))]
    return third[k]
end
t2_0 = t2_1250(spec0)
oat = [
    ("η_t", :η_lining, 0.4), ("η_t", :η_lining, 0.6),  # ±20 % of 0.5
    ("C", :C_struc, 2.4), ("C", :C_struc, 3.6),          # ±20 % of 3
    ("trim-mass", :mass_scale, 0.8), ("trim-mass", :mass_scale, 1.2),
    ("bb_j2_scale", :bb_j2_scale, 0.4), ("bb_j2_scale", :bb_j2_scale, 0.6),
]
for (pname, key, val) in oat
    println("  32e $pname=$val …")
    kw = Dict{Symbol,Any}(:C_struc => 3.0, :η_lining => 0.5, :mass_scale => 1.0, :bb_j2_scale => 0.5)
    kw[key] = val
    spec_p, _, _ = pipeline_from_ff(fuse, prop, ff0; C_struc=kw[:C_struc], η_lining=kw[:η_lining],
                                    mass_scale=kw[:mass_scale], bb_j2_scale=kw[:bb_j2_scale])
    t1p = [spec_p.harmonic_SPL_dB[H] for H in 1:3]
    t2p = t2_1250(spec_p)
    @printf(io, "| %s | %g | %.2f | %.2f | %.2f | %+.2f | %+.2f |\n",
            pname, val, t1p..., t1p[1] - t1_0[1], t2p - t2_0)
end
println(io)
println(io, "Compare ΔH1 magnitudes to GEXT flip sizes in 32c–32d (order-of-magnitude only).\n")

flipped = any(r.flip for r in results)
println(io, "## Claim status\n")
if flipped
    println(io, "**Any variant flips** → T1 verdict depends on GEXT; not claimable even under V-ASSUMED refraction/scattering.\n")
else
    println(io, "**No variant flips** → T1 stays calibrated (in-sample); robust to GEXT over the stated bracket; conditional on refraction/scattering V-ASSUMED.\n")
end
println(io, "GEXT grade stays **V-ASSUMED** either way. What this does not show: correctness of GEXT; circularity of the in-sample fit.\n")

out = joinpath(@__DIR__, "..", "..", "..", "docs", "validation_reports", "gext_importance_bound.md")
write(out, String(take!(io)))
println("wrote $out")
println("any_flip=$flipped; nominal T1=$(t1_0)")
