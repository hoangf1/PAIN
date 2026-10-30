### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 47a7cbf5-e29e-5063-8870-d1a644fa81af
md"""
# PAIN, step by step

This notebook runs PAIN (Propeller Aircraft Interior Noise, NASA CR-3813) on NASA's fuselage test article, the one CR-3813
App. E and CR-172428 describe, and shows what each stage computes. The source is ANOPP's printed free field (CR-3813
Table 8), as in the validation case REPRO_18b.

**How to use it.** Each cell depends on the cells above it. Change an input in the *Inputs* cell (the blocking variant,
the trim loss η_T, the number of harmonics) and every stage below reruns. Nothing is written to the repository.

The stages, in order: free field on the 160-point grid → blocking, Eq. (43) → structural and cabin modes → the tone
sum, Eq. (8) → interior sound pressure level.
"""

# ╔═╡ 724e2f2a-fefb-5bd3-a7d0-7bb5107ae2e8
begin
    import Pkg
    # Use the PAIN package environment (this turns off Pluto's own package manager for this notebook).
    # PAIN_JL lets the headless check run a copy of this notebook from a temp folder.
    Pkg.activate(get(ENV, "PAIN_JL", joinpath(@__DIR__, "..", "PAIN.jl")); io=devnull)
    using PAIN, CairoMakie, Printf
end

# ╔═╡ 8efb306d-3292-534b-8210-507836e629d2
md"""
## Inputs

`bpf_Hz` is the blade-passage frequency (200 Hz for the test article at 4000 rpm, 3 blades). `blocking` is `R1`, Eq. (43)
as printed (up to 6 dB at normal incidence), or `R2`, CR-172428's revision (0.8 × R1, at least 1). `η_T` is the trim's
loss factor (Phase III trim; 0.5 is NASA's value for E-16).
"""

# ╔═╡ a0846ab9-cc6b-52ad-bbab-cf8151dfcc27
begin
    bpf_Hz = 200.0
    n_harmonics = 3
    blocking = R1
    η_T = 0.5
end

# ╔═╡ 8fa7d85f-31e2-5cc9-8625-9f64cacbe81c
begin
    trim = phase3_trim(; η_lining=η_T)
    res = run_pain_pipeline(; source=:e11, e11_amp_csv=PAIN.default_e11_paths().anopp_spl, n_harmonics, bpf_Hz,
                            blocking, sidewall_trim_stack=trim.sidewall, end_trim_stack=trim.ends, mech=trim.mech)
    inp = res.inputs
    md"Ran the pipeline: $(length(inp.pts)) grid points, $(length(inp.structural.modes)) structural modes, $(length(inp.acoustic.modes)) cabin cross-section modes."
end

# ╔═╡ 64394f5b-afd2-5656-a118-fb269e20527e
md"""
## 1. The grid (User Manual Fig. 3)

PAIN samples the exterior pressure at 160 points on the upper quarter of the fuselage near the propeller: 16 axial
stations k by 10 circumferential lines ℓ. `z` is the axial position, `θ` the angle from the bottom of the fuselage.
"""

# ╔═╡ c913e873-6a90-5292-980c-943fe229baec
let
    fig = Figure(size=(700, 320))
    ax = Axis(fig[1, 1]; xlabel="axial position z (m)", ylabel="θ (deg from the bottom)", title="160-point grid")
    scatter!(ax, [p.z for p in inp.pts], [p.theta_deg for p in inp.pts]; markersize=6)
    vlines!(ax, [res.prop.z_p]; linestyle=:dash, color=:gray)
    fig
end

# ╔═╡ a256955b-2fd7-5e2c-81cb-b905b17319e0
md"""
## 2. Blocking, Eq. (43)

The fuselage reflects the incoming sound, so the pressure on the skin is higher than in free space. PAIN multiplies the
free-field amplitude by F(γ) = 10^(0.3 − 0.000224 e^(0.08γ)), γ the angle between the line from the propeller hub and
the skin normal (CR-3813 p. 31). At normal incidence F = 2 (+6 dB); at grazing incidence F = 1.
"""

# ╔═╡ f48e8713-98b2-5822-92aa-92ef668ecdd5
let
    γs = 0:1:90
    γgrid = [incidence_angle_deg(res.fuse, res.prop, p.theta_deg, p.z) for p in inp.pts]
    fig = Figure(size=(900, 320))
    ax = Axis(fig[1, 1]; xlabel="incidence angle γ (deg)", ylabel="increase over free field (dB)", title="Eq. (43)")
    lines!(ax, γs, delta_L_blocking_dB.(γs; variant=R1); label="R1")
    lines!(ax, γs, delta_L_blocking_dB.(γs; variant=R2); label="R2")
    axislegend(ax; position=:lb)
    ax2 = Axis(fig[1, 2]; xlabel="γ at the grid points (deg)", ylabel="count", title="Where the grid sits on the curve")
    hist!(ax2, γgrid; bins=18)
    fig
end

# ╔═╡ c625abe2-d1d5-59d4-a2af-2904c85498e1
md"""
## 3. Blocked pressure on the grid

The harmonic amplitudes PAIN passes to the cabin chain: the free field times F(γ), in dB re 20 μPa (rms). Each panel is one
harmonic; rows are axial stations, columns circumferential lines.
"""

# ╔═╡ 48e7eb18-dbc9-5cdd-b46b-5515a5f79dc0
let
    A = inp.amplitudes                       # (k, ℓ, harmonic) [Pa]
    fig = Figure(size=(300 * size(A, 3), 300))
    for h in 1:size(A, 3)
        ax = Axis(fig[1, h]; xlabel="line ℓ", ylabel="station k", title="H$h ($(Int(h * bpf_Hz)) Hz)")
        hm = heatmap!(ax, 1:size(A, 2), 1:size(A, 1), permutedims(20 .* log10.(A[:, :, h] ./ (sqrt(2) * 2e-5))))
        h == size(A, 3) && Colorbar(fig[1, h + 1], hm; label="dB")
    end
    fig
end

# ╔═╡ 8f423059-885a-5485-8f8e-eea1725013a5
md"""
## 4. Modes

**Structural modes** come from NASA's Table D-1 (MRP's output for the test article, CR-3813 App. D): frequency, generalized
mass M_r and the number of axial half-waves M. **Cabin modes** come from CYL2D (App. C): each cross-section mode i
combined with q axial half-waves, f² = f_i² + (q c₀ / 2L_c)².
"""

# ╔═╡ 1cf5bd2c-f55d-54cc-9c68-c75545cc78ab
let
    st = inp.structural.modes
    rows = ["| $(m.index) | $(@sprintf("%.1f", m.f_Hz)) | $(@sprintf("%.3f", m.M_r)) | $(m.M_axial) |" for m in st[1:min(12, end)]]
    Markdown.parse("| structural mode | f (Hz) | M_r (kg) | M |\n|---|---|---|---|\n" * join(rows, "\n"))
end

# ╔═╡ ada3d1ba-5fe6-55f9-bdd9-0dad11feb35d
let
    fig = Figure(size=(800, 300))
    ax = Axis(fig[1, 1]; xlabel="frequency (Hz)", yticks=([1, 2], ["structural", "cabin (q = 0…3)"]), title="Mode frequencies up to 900 Hz")
    fs = [m.f_Hz for m in inp.structural.modes]
    fa = [PAIN.cabin_frequency_3d(m, inp.fuse.a, inp.L_c, q; c0=inp.c_int) for m in inp.acoustic.modes for q in 0:3]
    scatter!(ax, fs, fill(1, length(fs)); marker=:vline, markersize=18)
    scatter!(ax, filter(<(900), fa), fill(2, count(<(900), fa)); marker=:vline, markersize=18)
    vlines!(ax, bpf_Hz .* (1:n_harmonics); color=:red, linestyle=:dash)
    xlims!(ax, 0, 900); ylims!(ax, 0.5, 2.5)
    fig
end

# ╔═╡ 895c80d2-e4d0-5192-964e-37eeff18935c
md"""
The red dashed lines are the tones. A tone near a structural *and* a cabin mode that couple well is transmitted strongly;
that is what Eq. (8) sums.

## 5. Tones inside the cabin, Eq. (8)

Eq. (8) sums, over every structural mode r and cabin mode n, the power the skin's mode r feeds into the cabin's mode n:
the generalized force of the blocked pressure on mode r (Eq. 42), the coupling f′(n, r) between the two shapes (Eq. 52),
and both modes' resonance and damping. The result is the space-averaged mean-square pressure in the cabin.
"""

# ╔═╡ 0063bbd1-c2e3-517d-89d3-3c1d2fb6051c
let
    spl = res.spectrum.harmonic_SPL_dB
    fig = Figure(size=(500, 320))
    ax = Axis(fig[1, 1]; xlabel="harmonic", ylabel="interior SPL (dB re 20 μPa)", xticks=1:n_harmonics,
              title="Space-averaged interior tones")
    barplot!(ax, 1:n_harmonics, spl[1:n_harmonics])
    fig
end

# ╔═╡ 0957aaf3-0e55-578f-9e81-0193b3f58d6e
Markdown.parse("Interior tones: " * join(["H$h $(@sprintf("%.1f", res.spectrum.harmonic_SPL_dB[h])) dB" for h in 1:n_harmonics], ", ") *
    ". NASA's printed prediction for this case (E-16): 79.0, 75.5, 68.0 dB; see the validation notebook for what the differences mean.")

# ╔═╡ 9b4b3813-01a2-5c85-bcc0-d9a6f1a09d11
md"""
## Try it

* Set `blocking = R2` in *Inputs*: the tones drop by 1.3–1.8 dB (R2 is 0.8 × R1, at most −1.9 dB, and never below
  free field).
* Set `η_T = 1.0`: the trim absorbs more and the modes' damping rises; the tones fall by 1.2–2.0 dB (the trim of Fig.
  E-18's case).
"""

# ╔═╡ Cell order:
# ╟═47a7cbf5-e29e-5063-8870-d1a644fa81af
# ╠═724e2f2a-fefb-5bd3-a7d0-7bb5107ae2e8
# ╟═8efb306d-3292-534b-8210-507836e629d2
# ╠═a0846ab9-cc6b-52ad-bbab-cf8151dfcc27
# ╠═8fa7d85f-31e2-5cc9-8625-9f64cacbe81c
# ╟═64394f5b-afd2-5656-a118-fb269e20527e
# ╠═c913e873-6a90-5292-980c-943fe229baec
# ╟═a256955b-2fd7-5e2c-81cb-b905b17319e0
# ╠═f48e8713-98b2-5822-92aa-92ef668ecdd5
# ╟═c625abe2-d1d5-59d4-a2af-2904c85498e1
# ╠═48e7eb18-dbc9-5cdd-b46b-5515a5f79dc0
# ╟═8f423059-885a-5485-8f8e-eea1725013a5
# ╠═1cf5bd2c-f55d-54cc-9c68-c75545cc78ab
# ╠═ada3d1ba-5fe6-55f9-bdd9-0dad11feb35d
# ╟═895c80d2-e4d0-5192-964e-37eeff18935c
# ╠═0063bbd1-c2e3-517d-89d3-3c1d2fb6051c
# ╠═0957aaf3-0e55-578f-9e81-0193b3f58d6e
# ╟═9b4b3813-01a2-5c85-bcc0-d9a6f1a09d11
