#!/usr/bin/env julia
# Phase 101: write docs/WALKTHROUGH.md and its figures — the guided walk through the program and through a
# validation case that the Pluto notebooks used to give (Phase 91, retired 2026-10-30).
#
# Display only. It runs the pipeline and one registered case with their recorded defaults and prints what they
# produce; it fixes no criterion, changes no case, and writes nothing under src/ or data/.
#
#   julia --project=. scripts/run/write_walkthrough.jl
ENV["QT_QPA_PLATFORM"] = get(ENV, "QT_QPA_PLATFORM", "offscreen")

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))
using PAIN, CairoMakie, Printf, Dates

const DOCS = normpath(joinpath(@__DIR__, "..", "..", "..", "docs"))
const FIGDIR = joinpath(DOCS, "figures", "walkthrough")
mkpath(FIGDIR)

savefig(fig, name) = (p = joinpath(FIGDIR, name); save(p, fig); println("  figure: ", p); name)

# ---- the run the walk-through describes (REPRO_18b's inputs: ANOPP Table 8 free field, Phase III trim) ----
const BPF_HZ = 200.0
const N_HARM = 3
const ETA_T = 0.5

trim = phase3_trim(; η_lining=ETA_T)
res = run_pain_pipeline(; source=:e11, e11_amp_csv=PAIN.default_e11_paths().anopp_spl,
                        n_harmonics=N_HARM, bpf_Hz=BPF_HZ, blocking=R1,
                        sidewall_trim_stack=trim.sidewall, end_trim_stack=trim.ends, mech=trim.mech)
inp = res.inputs

# ---- figures -----------------------------------------------------------------------------------------------
fig1 = Figure(size=(760, 330))
let ax = Axis(fig1[1, 1]; xlabel="axial position z (m)", ylabel="θ (deg from the bottom)",
              title="The 160 skin points (16 stations k × 10 lines ℓ)")
    scatter!(ax, [p.z for p in inp.pts], [p.theta_deg for p in inp.pts]; markersize=7)
    vlines!(ax, [res.prop.z_p]; linestyle=:dash, color=:gray)
end
f_grid = savefig(fig1, "grid_160.png")

γgrid = [incidence_angle_deg(res.fuse, res.prop, p.theta_deg, p.z) for p in inp.pts]
γmax = max(90.0, ceil(maximum(γgrid) / 10) * 10)
γaxis = 0:1:γmax
fig2 = Figure(size=(960, 330))
let ax = Axis(fig2[1, 1]; xlabel="incidence angle γ (deg)", ylabel="increase over free field (dB)",
              title="Eq. (43), both revisions")
    lines!(ax, γaxis, delta_L_blocking_dB.(γaxis; variant=R1); label="R1 (as printed)")
    lines!(ax, γaxis, delta_L_blocking_dB.(γaxis; variant=R2); label="R2 (CR-172428)")
    hlines!(ax, [0.0]; color=:gray, linestyle=:dot)
    axislegend(ax; position=:lb)
    ax2 = Axis(fig2[1, 2]; xlabel="γ at the 160 grid points (deg)", ylabel="count",
               title="Where this grid sits on the curve")
    hist!(ax2, γgrid; bins=18)
end
f_blk = savefig(fig2, "blocking_eq43.png")

A = inp.amplitudes
fig3 = Figure(size=(320 * size(A, 3) + 90, 320))
for h in 1:size(A, 3)
    ax = Axis(fig3[1, h]; xlabel="line ℓ", ylabel="station k", title="H$h ($(Int(round(h * BPF_HZ))) Hz)")
    hm = heatmap!(ax, 1:size(A, 2), 1:size(A, 1),
                  permutedims(20 .* log10.(A[:, :, h] ./ (sqrt(2) * 2e-5))))
    h == size(A, 3) && Colorbar(fig3[1, h + 1], hm; label="dB re 20 μPa")
end
f_blocked = savefig(fig3, "blocked_pressure.png")

fig4 = Figure(size=(860, 300))
let ax = Axis(fig4[1, 1]; xlabel="frequency (Hz)", yticks=([1, 2], ["structural", "cabin (q = 0…3)"]),
              title="Mode frequencies up to 900 Hz; dashed red = the tones")
    fs = [m.f_Hz for m in inp.structural.modes]
    fa = [PAIN.cabin_frequency_3d(m, inp.fuse.a, inp.L_c, q; c0=inp.c_int) for m in inp.acoustic.modes for q in 0:3]
    scatter!(ax, fs, fill(1, length(fs)); marker=:vline, markersize=18)
    scatter!(ax, filter(<(900), fa), fill(2, count(<(900), fa)); marker=:vline, markersize=18)
    vlines!(ax, BPF_HZ .* (1:N_HARM); color=:red, linestyle=:dash)
    xlims!(ax, 0, 900); ylims!(ax, 0.5, 2.5)
end
f_modes = savefig(fig4, "mode_frequencies.png")

spl = res.spectrum.harmonic_SPL_dB
fig5 = Figure(size=(520, 330))
let ax = Axis(fig5[1, 1]; xlabel="harmonic", ylabel="interior SPL (dB re 20 μPa)", xticks=1:N_HARM,
              title="Space-averaged interior tones")
    barplot!(ax, 1:N_HARM, spl[1:N_HARM])
end
f_tones = savefig(fig5, "interior_tones.png")

# ---- the validation case the walk-through reads --------------------------------------------------------------
const CASE_ID = "R172428_CODE"
case = PAIN.VALIDATION_CASES[CASE_ID]
result = run_validation_case(CASE_ID)
rec = recorded_case_errors()
on_map = [id for id in PAIN.VALIDATION_CASE_ORDER if on_validation_map(id; rec)]
n_met = count(id -> rec[id].verdict == "met", on_map)

f3(x) = @sprintf("%.1f", x)
mode_rows = join(["| $(m.index) | $(@sprintf("%.1f", m.f_Hz)) | $(@sprintf("%.3f", m.M_r)) | $(m.M_axial) |"
                  for m in inp.structural.modes[1:min(12, end)]], "\n")
case_rows = join(["| $(r.quantity) | $(@sprintf("%.4g", r.reference)) | $(@sprintf("%.4g", r.computed)) | " *
                  "$(@sprintf("%+.3g", r.residual)) | $(r.within_tolerance ? "yes" : "no") |"
                  for r in result.table], "\n")
tone_line = join(["H$h $(f3(spl[h])) dB" for h in 1:N_HARM], ", ")

md = """
# Walk-through: the program, and how to read a validation case

*Generated $(Dates.today()) by `PAIN.jl/scripts/run/write_walkthrough.jl`. Display only: every number below is what the
code produces on the inputs named here, with no criterion attached. The checks that do carry a criterion are the
registered cases of [`VALIDATION_GUIDELINE.md`](VALIDATION_GUIDELINE.md) §2.13.*

This page replaces the two Pluto notebooks of Phase 91 (retired 2026-10-30). It walks the pipeline stage by stage on
NASA's fuselage test article — the article CR-3813 App. E and CR-172428 describe — and then reads one registered case
end to end. To change an input and watch the stages move, use the GUI (`scripts/run_gui.jl`), which runs the same
functions; to change them in a script, copy the call in part 1 below.

## Part 1 — the program, stage by stage

The source here is ANOPP's printed free field (CR-3813 Table 8), the input of validation case `REPRO_18b`; the user
source is BEMT + F1A ([`METHODOLOGY.md`](METHODOLOGY.md) §2.3). The run:

```julia
trim = phase3_trim(; η_lining = $(ETA_T))
res  = run_pain_pipeline(; source = :e11, e11_amp_csv = PAIN.default_e11_paths().anopp_spl,
                           n_harmonics = $(N_HARM), bpf_Hz = $(BPF_HZ), blocking = R1,
                           sidewall_trim_stack = trim.sidewall, end_trim_stack = trim.ends, mech = trim.mech)
```

`bpf_Hz` is the blade-passage frequency ($(Int(BPF_HZ)) Hz for the test article at 4000 rpm with 3 blades). `blocking`
is `R1`, Eq. (43) as printed, or `R2`, CR-172428's revision (0.8 × R1, never below free field). `η_T` is the trim's
loss factor (Phase III trim; $(ETA_T) is NASA's value for E-16). This run gives
$(length(inp.pts)) grid points, $(length(inp.structural.modes)) structural modes and
$(length(inp.acoustic.modes)) cabin cross-section modes.

### 1.1 The grid (User Manual Fig. 3)

PAIN samples the exterior pressure at 160 points on the upper quarter of the fuselage near the propeller: 16 axial
stations k by 10 circumferential lines ℓ. `z` is the axial position, θ the angle from the bottom of the fuselage; the
dashed line is the propeller plane.

![The 160-point grid](figures/walkthrough/$(f_grid))

### 1.2 Blocking, Eq. (43)

The fuselage reflects the incoming sound, so the pressure on the skin is higher than in free space. PAIN multiplies the
free-field amplitude by F(γ) = 10^(0.3 − 0.000224 e^(0.08γ)), with γ the angle between the line from the propeller hub
and the skin normal (CR-3813 p. 31). At normal incidence F = 2 (+6 dB); at γ = 90° F = 1. The right panel shows where
this grid's 160 points fall on that curve: γ runs from $(f3(minimum(γgrid)))° to $(f3(maximum(γgrid)))° here, and
$(count(>(90.0), γgrid)) of the 160 points sit past 90°, where the printed Eq. (43) keeps falling and so attenuates
rather than reflects. The code applies the equation as printed, with no clamp at 90°; R2 alone is floored at F = 1.

![Eq. (43) and the grid's incidence angles](figures/walkthrough/$(f_blk))

### 1.3 Blocked pressure on the grid

What PAIN hands to the cabin chain: the free field times F(γ), in dB re 20 μPa (rms). One panel per harmonic; rows are
axial stations, columns circumferential lines.

![Blocked pressure per harmonic](figures/walkthrough/$(f_blocked))

### 1.4 Modes

**Structural modes** come from NASA's Table D-1 (MRP's output for the test article, CR-3813 App. D): frequency,
generalized mass M_r, and the number of axial half-waves M. **Cabin modes** come from CYL2D (App. C): each
cross-section mode i combined with q axial half-waves, f² = f_i² + (q c₀ / 2L_c)². The first twelve structural modes:

| structural mode | f (Hz) | M_r (kg) | M |
|---|---|---|---|
$(mode_rows)

![Structural and cabin mode frequencies](figures/walkthrough/$(f_modes))

A tone that lands near a structural *and* a cabin mode that couple well is transmitted strongly; that is what Eq. (8)
sums.

### 1.5 Tones inside the cabin, Eq. (8)

Eq. (8) sums, over every structural mode r and cabin mode n, the power the skin's mode r feeds into the cabin's mode n:
the generalized force of the blocked pressure on mode r (Eq. 42), the coupling f′(n, r) between the two shapes
(Eq. 52), and both modes' resonance and damping. The result is the space-averaged mean-square pressure in the cabin.

![Interior tones](figures/walkthrough/$(f_tones))

Interior tones from this run: $(tone_line). NASA's printed prediction for the same case (Fig. E-16) is 79.0, 75.5,
68.0 dB. The difference is not a verdict — `REPRO_18b` is the registered case that compares the two against a criterion
fixed on 2026-10-20, and `VALIDATION_GUIDELINE.md` §2.14 says where the remaining gap is attributed.

### 1.6 Things to try

* `blocking = R2` instead of `R1`: R2 is 0.8 × R1 and never below free field, so every blocked level drops and the
  tones follow.
* `η_lining = 1.0` (the trim of Fig. E-18's case): the trim absorbs more, so the higher harmonics fall while H1,
  controlled by a different mode pair, can rise.
* A different `n_harmonics` or `bpf_Hz`: the tone lines in §1.4 move across the mode set, which is what makes a tone
  loud or quiet.

## Part 2 — reading a validation case

Every check of this recreation is a registered *case*: fixed inputs, a reference, and a criterion written down, with
its date, before the case was first run.

**What carries a verdict.** A case may be *met* or *not met* only if it compares with an experiment (E), or checks
that the code does exactly what PAIN did on PAIN's own inputs (P) (rule of 2026-10-29, `CLAUDE.md`). Everything else —
hand checks, identities, other methods, diagnostics — runs and is recorded but carries no verdict. The validation map
shows only the cases with a verdict; the rest are in [`NO_VERDICT_CASES.md`](NO_VERDICT_CASES.md).

From the recorded snapshot: **$(length(PAIN.VALIDATION_CASE_ORDER))** registered cases;
**$(length(on_map))** on the map ($(n_met) met, $(length(on_map) - n_met) not met);
$(length(PAIN.VALIDATION_CASE_ORDER) - length(on_map)) without a verdict.

### 2.1 Run one

`$(CASE_ID)` runs NASA's own inputs for the test article (CR-172428 App. B) and compares with what NASA's program
printed — a P case.

```julia
case   = VALIDATION_CASES["$(CASE_ID)"]
result = run_validation_case("$(CASE_ID)")
```

**$(case.title)**

*Criterion ($(case.criterion_date)):* $(case.criterion_text)

*Verdict:* **$(replace(String(result.verdict), "_" => " "))** — $(result.reason)

### 2.2 Its table

One row per compared point: the reference value, this code's value, the difference, and whether it is within the
criterion.

| point | reference | this code | difference | within |
|---|---|---|---|---|
$(case_rows)

The same case's recorded figure, and every other case's, is in the **Validation cases** section of the website
(`site/build_site.jl`), and on disk under `docs/validation_reports/figures/`.

### 2.3 A diagnostic

A diagnostic re-runs a case with one thing changed, to test a possible cause of its miss. It carries no verdict, but
its outcome is kept: `underlying_verdict` returns it. `R172428_CODE_ETAN` re-runs `$(CASE_ID)` with each cabin mode's
loss factor taken per mode (Phase 89). Diagnostics are listed, with what each one refuted, in
[`NO_VERDICT_CASES.md`](NO_VERDICT_CASES.md).

### 2.4 Where to read more

* [`VALIDATION_GUIDELINE.md`](VALIDATION_GUIDELINE.md) §2.13 — the record of every case: what it tests, why, and its
  recorded outcome.
* [`VALIDATION_GUIDELINE.md`](VALIDATION_GUIDELINE.md) §2.14 — why each not-met case misses (classes M, A, I, N, D).
* [`COMPLETED_PHASES.md`](COMPLETED_PHASES.md) — how each check was planned, with its criteria dated before the run.
"""

out = joinpath(DOCS, "WALKTHROUGH.md")
write(out, md)
println("wrote ", out, " (", length(md), " chars)")
