# PAIN recreation (CCBlade.jl + AcousticAnalogies.jl)

Julia reimplementation of NASA **Propeller Aircraft Interior Noise (PAIN)**: propeller noise at the
fuselage skin -> blocking by the fuselage -> cabin and structure modes -> interior SPL.

Other docs: [validation guideline](docs/VALIDATION_GUIDELINE.md), [methodology and claims](docs/METHODOLOGY.md),
[plan](docs/IMPLEMENTATION_PLAN.md), [flowcharts](docs/flowchart.md).

## How it fits together

PAIN needs the free-field pressure (amplitude and phase, per harmonic) at 160 points on the fuselage skin.
In use there is one source, BEMT + F1A. NASA's measured data are a validation test only, not a user option:

| Source | Where the 160 points come from | Used for |
|--------|--------------------------------|----------|
| BEMT + F1A (the only user option) | CCBlade computes blade loads, AcousticAnalogies (F1A) computes the pressure at the grid points. | Your own propeller and aircraft |
| NASA measured data, `:e11` (validation test only) | NASA's measured data, **Fig. E-11**, which exists only along one line of the grid (l = 1). The **grid extension (GEXT)** fills in the other points with an assumed cosine falloff and phase delay. | Checking the cabin model against NASA's published results (tests T1, T2) |

GEXT exists only because the NASA paper measured one line. The aircraft source does not use it.
`extend_line_to_grid` has three importance-bound options (`falloff_exponent`, `falloff_floor`, `delay_scale`) for the GEXT sensitivity run ([guideline §2.2.1](docs/VALIDATION_GUIDELINE.md)). The defaults are the nominal GEXT; they are not fitted parameters and must not be tuned to the T1/T2 figures.
**Current state (phases 21–22 done 2026-10-21):** the aircraft path runs F1A at all 160 grid points through `evaluate_propeller_source` (no GEXT). GEXT remains on the e11 validation path only. Report 996 and Pereira checks call the same shared function with different observer lists.

After the source, the cabin stages are identical for the user source and the validation test: blocking (Eq. 43) -> CYL2D acoustic modes + MRP structural modes -> PAIN core -> interior SPL.
The [flowcharts](docs/flowchart.md) show the total program overview (diagram 1), the NASA validation path (diagram 2), the aircraft validation path (diagram 3), the shared cabin model (diagram 4) and the GUI `total` validation map (section 5).

## Status

| Block | Status |
|-------|--------|
| Blocking Eq. (43) R1/R2 | **Done** <= 0.06 dB |
| Grid + assumed extension | **Done** (e11 path). Grid azimuth fixed 2026-10-20 (12b): line l = 1 at the propeller azimuth phi_p, upper quarter, theta_l = phi_p + (l-1)·10°; incidence gamma measured from the surface-to-hub direction (0 at l = 1, k = k_p). Results from before this date used the bottom of the fuselage and are void |
| Cabin pre-registration (phase 13) | **Done 2026-10-20** (documentation only, no code change). Assumption register for 15a-17a and the loss/trim pass criteria are dated in [`VALIDATION_GUIDELINE.md` §2.11](docs/VALIDATION_GUIDELINE.md). Cabin phase 17 is partly done (2026-10-20); phase 18 is next |
| Fig. E-12 blocking check (phase 14a) | **Done 2026-10-20** (no `src/` change). Eq. (43) on ANOPP Table 8 reproduces NASA's predicted E-12 curve at 29 of 31 points within delta_dig + 0.5 = 3.41 dB; FAIL at H3 aft (+4.3, +3.8 dB), recorded. delta_dig = 2.91 dB (E-11 gate of 1 dB not met). Prediction is 1-7 dB above the measured circles. Report `docs/validation_reports/e12_blocking.md`; script `PAIN.jl/scripts/run/e12_blocking.jl` |
| CYL2D (phase 15, App. C) | **Done 2026-10-20; criterion re-stated 2026-10-21 (post-hoc).** App. C as written. `TABLE_C1_C0 = 341 m/s` is back-solved from Table C-1 (absolute-f check was partly by construction). **Ratio form:** f_i/f_1 (modes 2–19) within 0.1 % (c0-free; worst 0.0003 %); Φ_G, symmetry, Fig. C-3 unchanged. Three-dimensional modes (q, i) and q-convergence as before (`q_convergence.md`) |
| MRP | **Done**; Fig. D-2 mode 1: shell within print quantization, floor 0.057 vs 0.05 (19g); production/`MRP_D1` = Table D-1 transcription (`no_verdict`); raw Ritz/`MRP_RITZ` calibrated guard — live **29/32** within 5 % at L = 1.83 m (I-22 re-record); **38g** printed App. D / `MRP_APPD`: **27/32** within 5 % → met (criterion ≥75 % of 32 fixed 2026-10-22; `mrp_appd_vs_d1.md`) |
| Coupling f'(n,r) | Implements CR-3813 Eq. (52) (shell and floor terms, no clamp; an out-of-range value raises an error); Table D-1 shapes for all 32 modes; its tests pass. No |f'| > 1 error occurred in the phase 17 runs |
| PAIN core, Eq. (8) (phase 17) | **Phase 17 done 2026-10-20**; phase 19 diagnostics done; **η_T = 0.5 adopted for Phase III** (author 2026-10-20, phase 20); **19i done 2026-10-21**: H3 modal breakdown at η_T = 0.5 (modes 15/25/17/21); omitted D-1 terms \|δ\| ≤ 0.057 **not found** as the H3 cause (`docs/validation_reports/h3_followup.md`). 18b-r: +3.7, +0.2, +9.1 dB (2 of 3 within 4 dB). Eq. (8) derivation and conservation closed in 19a–19b (`eq8_two_resonator.md`); other candidates ruled out in 19c–19h. `tone_mean_square_pressure` is Eq. (8) summed by Eq. (3); broadband HF: printed Eqs. (19)–(23) via `broadband_model=:eq19` (38c); default still surrogate. Baselines: `data/baselines/phase17_baselines.csv`. Trace: `docs/validation_reports/pain_core_eq8_phase17.md` |
| Phase 38 modules (2026-10-22) | `src/noise_reduction.jl` (Eqs. 17–18, E21_E22_NR: below-crossover 1/4 and 0/4, not met), `src/high_freq_tones.jl` (Eqs. 11–16, `tone_model`; I-18 rule not met, H3 +4.31 dB), `src/hf_broadband.jl` (Eqs. 19–23, T2_EQ19 0/3), E18_TONES (2/3, not met), E15_STRUCT_LOSS (info). **38f-1:** Manual cards 2/9/36 — `ρ_ext,c_ext,ρ_int,c_int`, cavity `L_c`/`d`, `rotation_direction` ±1; defaults bit-identical (`phase38f1_card_inputs.md`). **38f-2:** cards 3–6 user band set; cards 11–18 per-band `η_r_band` / `η_n_band` (`phase38f2_card_inputs.md`). **38h:** Manual §5.4.3 printed outputs — `src/printed_outputs.jl` + GUI tab + example `printed_outputs_REPRO_18b.md` (no comparison criterion). |
| Phase 29b/29c (2026-10-22) | Aircraft NASA-default guard + provenance tags: `src/aircraft_provenance.jl`; `cabin` JSON keys (plain or `{value,tag}`); `result.provenance.nasa_defaults` / `.inputs`; printed-outputs header + GUI status labels. Example `examples/aircraft_scale_hartzell_cabin_full.json`. Validation / `:e11` / `:synthetic` bit-identical. |
| L = 1.83 m default (I-22, 2026-10-22, post-hoc) | `TEST_ARTICLE_L` / `test_article_length()` default **1.83 m** (App. D body / App. E; Table D-1 title 1.803 m = caption typo). Affected reports/baselines re-recorded; before/after: `docs/validation_reports/length_rerecord_before_after.md` (from `length_sensitivity.md`). **No verdict flips.** Criteria/reference unchanged; no length selected from any error. |
| Fig. E-11 SRC_TA | **Done** delta_dig <= 1 dB (repeatability of reading only) |
| **T1 tonal vs E-16** | At L = 1.83 m (I-22): 84.21, 77.66, 78.06 dB — H1 fail, H2 pass, H3 fail; **no claim**. GEXT importance bound: flat falloff and delay ×2 flip the T1 gate → **T1 depends on GEXT, not claimable** (`gext_importance_bound.md`) |
| **T2 1/3-oct vs E-9** | **Surrogate (default)** at L = 1.83 m: 55.92, 53.56, 51.59 dB (0/3); `bb_j2_scale` = 0.5 stale. **Printed Eq. (19) (`T2_EQ19`):** 38.56, 35.81, 34.87 dB — **0/3** within ±3.5 dB (`phase38c_hf_broadband.md`). **No claim** |
| **PAIN reproduction vs NASA (18b-r)** | **Not met, 1 of 3** at L = 1.83 m (I-22): 85.90, 78.35, 79.82 dB = +6.9, +2.8, +11.8 vs 79.0, 75.5, 68.0. Report `pain_reproduction_e16.md`; before/after `length_rerecord_before_after.md` |
| Trim / loss (phase 16, App. A + section 3.8) | **Done 2026-10-20.** Written from the printed equations, no fitted parameter: App. A transfer matrices (A.10)-(A.12), tau_t (A.22), C_w, beta (A.16), mechanical path (A.19)-(A.21), Phase III stacks; Si/Cin, joint acceptances (63)-(73), eta_n (77), eta_r (79)-(81), eta_r' (82), eta_r'' (83). Fig. A-2 digitized in `data/cr3813/fig_a2_pf105.csv`. Eq. (78) against NASA's calculated Fig. E-14 curves: **7 of 18 bands within +-25 %** at trim loss 0.5 and at 1.0 (criterion not met, recorded, not tuned); Fig. E-13 has no calculated curve. Printed-equation findings (factor 2 in Eqs. 69-70, the Eq. 82 limp-mass limit) in the [plan](docs/IMPLEMENTATION_PLAN.md). In the pipeline since 17a (2026-10-20). Report: `docs/validation_reports/trim_loss_e13_e14_e15.md` (`julia --project=. scripts/run/run_trim_loss_check.jl`) |
| CCBlade -> F1A | **Done** (phase 21 + **I-01/I-02 fix 2026-10-21**): all 160 points via `evaluate_propeller_source`, no GEXT; source span = 2 revolutions; phase referenced to absolute observer time. Table-8 peak calibration optional post-step (never compared to Table 8 when on — I-12/B-5). Class **X-EXTRAP** |
| Report 996 / Pereira / BBN | **I-07 re-runs done 2026-10-21** against §2.12 freeze. Smoke raw Table-8 peaks −4.2/−5.3/−5.8 dB. BBN 24b **PASS**; 24c 23a **FAIL** (26/168). Report 996: I-08 L51C27 scale on Fig.13a; 23c scaled pressure 5/24 within ±2 dB, page-12 phase **FAIL**. Pereira 23d H1 0/9 within ±1.7 dB (Fig.9 H1=80 dB accepted as read). Loads still valid (phase 26 post-hoc label) |
| dB(A) / SIL | **Done**; `overall_dBA` energy-sums A-weighted 1/3-octave bands (**fixed C5, 2026-10-21**; was tones-only) |

**Status after phase 38d–38e / 38f-1–38f-2 / 38h / 38g (2026-10-22):** Cases `E18_TONES` (η_T = 1.0, η_r′ ≤ 0.15 vs NASA E-18 pred): **2/3** within ±4 dB (89.02, 78.14, 77.70 dB) — **not met** (`e18_tones_eta1.md`); `E15_STRUCT_LOSS` (Fig. E-15 η_r′, V-EXP info): 4/8 within CSV tol_frac, **no_verdict** (`e15_structural_loss.md`). **38f-1** / **38f-2** card inputs landed with defaults unchanged. **38h** Manual §5.4.3 printed outputs (modes per band, f′/Ψ_G, top-5 contributions, spectrum, upper-quarter pressures; lower quarter noted I-18) — report `printed_outputs_REPRO_18b.md`, GUI **Printed outputs** tab; no criterion. **38g** App. D structural solver (`mrp_appd.jl`, `structural_solver=:appd`; default stays Table D-1): case `MRP_APPD` **27/32** within 5 % → **met** (`mrp_appd_vs_d1.md`). Phase 38c remains: `T2_EQ19` 0/3; 38a–38b remain. `REPRO_18b` default path still Eq. (8) **not met**; `MRP_D1` `no_verdict`. Run tab source = **aircraft only**. **29b/29c done 2026-10-22:** aircraft NASA-default guard + provenance tags (`aircraft_provenance.jl`, `cabin` JSON keys, `result.provenance`); phases 30–31 still deferred (B-4).

Source-block data: Report 996 in `data/report996/`; Pereira in `data/pereira/`; CR-3813 test-article CSVs and pages in `data/cr3813/` (see `data/README.md`); BBN phase Figs. 18–20 in `data/NASA_CR-159124/`. Scripts live under `PAIN.jl/scripts/{run,checks,digitize,setup,smoke}/` (`scripts/README.md`). Details in the [plan](docs/IMPLEMENTATION_PLAN.md).

The cabin path checked against NASA data is: digitized Fig. E-11 -> GEXT -> blocking R2 -> hybrid Table D-1 MRP + CYL2D -> PAIN core.
T1 and T2 are recorded results of the untuned CR-3813 chain (T2 keeps one stale fitted parameter, `bb_j2_scale`), not independent validation; which test proves what, and which parameters were fitted,
is in [`docs/VALIDATION_GUIDELINE.md`](docs/VALIDATION_GUIDELINE.md) section 2.10. The aircraft path is not validated against measurements.

## Running it (Windows PowerShell)

Open **PowerShell** (not the Julia prompt). Run the commands **one block at a time**, and wait for each to finish
before pasting the next. Lines starting with `#` are comments, not commands.

### Step 0 - Check that Julia is installed

```powershell
Get-Command julia
```

- If it prints a table with `julia.exe` and a path, Julia is installed. Go to Step 1. (A Microsoft Store / winget install puts
  it at `C:\Users\<you>\AppData\Local\Microsoft\WindowsApps\julia.exe`, which is on PATH; that is the expected result.)
- If it says `The term 'julia' is not recognized`, Julia is not installed (or not on your PATH). Install it:

  ```powershell
  winget install julia -s msstore
  ```

  Then **close PowerShell and open a new one**, and run `Get-Command julia` again. The old README pointed at
  `%LOCALAPPDATA%\Programs\Julia-1.13.1\bin\julia.exe`; that path only exists if you installed that exact version there.
- If Julia is installed but `Get-Command julia` still fails, find it with this and note the path it prints:

  ```powershell
  Get-ChildItem "$env:LOCALAPPDATA", "$env:ProgramFiles" -Recurse -Filter julia.exe -ErrorAction SilentlyContinue | Select-Object -First 5 FullName
  ```

  Then tell PowerShell where it is, using your path in place of `C:\path\to\julia.exe`. This lasts until you close
  that PowerShell window, and lets every command below work unchanged:

  ```powershell
  function julia { & "C:\path\to\julia.exe" @args }
  ```

Check that it works (this should print a version number):

```powershell
julia --version
```

The lock file was made with Julia 1.13.1. Another version still works but may re-resolve packages.

### Step 1 - Go to the project folder

```powershell
cd C:\Users\FrancisHoang\git\PAIN\rea-work\PAIN.jl
```

Do not run these from `git\PAIN` or `rea-work`; there is a separate `Project.toml` in `git\PAIN` that is not this project.

### Step 2 - Install the Julia packages (first time only)

```powershell
julia --project=. -e "using Pkg; Pkg.instantiate()"
```

This downloads and compiles many packages (including Qt for the GUI), so it can take several minutes and needs internet.
It is done when the PowerShell prompt returns without an `ERROR`.

### Step 3 - Run the tests

```powershell
julia --project=. -e "using Pkg; Pkg.test()"
```

Expected: a test summary ending with all tests passed.

To run only some top-level testsets (substring match on the title, case-insensitive):

```powershell
julia --project=. -e "using Pkg; Pkg.test(`"PAIN`"; test_args=[`"CYL2D`", `"Validation case registry`"])"
```

Titles and typical times: [`PAIN.jl/test/README.md`](PAIN.jl/test/README.md). Optional persistent Julia (DaemonMode, own env under `PAIN.jl/scripts/devtools/`): [`PAIN.jl/scripts/devtools/README.md`](PAIN.jl/scripts/devtools/README.md). No change to assertions or `src/` (task P1, 2026-10-22).

### Step 4 - Run the full pipeline and validation checks

```powershell
julia --project=. scripts/run/run_pain.jl
```

Prints the interior tone levels, the T1/T2 checks, and a summary of PASS/FAIL lines. It writes reports to
`docs\validation_reports\`. It ends with an error message if any check fails; read the summary above it.

### Step 5 - Run the CCBlade + F1A smoke test (aircraft source)

```powershell
julia --project=. scripts/run/run_f1a_smoke.jl
```

Compares the propeller noise on the l = 1 line with ANOPP Table 8 and writes `docs\validation_reports\ccblade_f1a_smoke.md`.

### Step 6 - Open the GUI (optional)

```powershell
julia --project=. scripts/run_gui.jl
```

Tabs (phases 34–36, 38h). Cases are read-only: fixed inputs and criteria; not a calibration tool (CLAUDE.md).

**Run tab:** source = `aircraft` only (BEMT + F1A; needs an aircraft JSON, e.g. `examples\aircraft_scale_hartzell.json`). `e11` / `synthetic` stay for scripts and `Pkg.test()`, not the GUI.

**Validation tab:** list ordered by validation map and block. Pick a case → **Run** (or **Run all**). Selection updates Julia `val_selected` / `val_runnable`. Inputs are an echo; criterion text/date and verdict are fixed. Comparison plot (with error panel; optional `error_xlabel` when that panel's x differs from the main panel, e.g. `UT_GRID`) → `docs/validation_reports/figures/<case_id>.png`. Until Run: "Press Run to draw the comparison plot". **E21_E22_NR** (38a), **E18_TONES** (38d), **E15_STRUCT_LOSS** (38e) runnable; long source cases replay recorded CSVs.

**Validation map tab:** one horizontal `total` flowchart (aircraft BEMT+F1A + e11 free field + grid/blocking + modes + PAIN main + checks). Stage group frames bound each stage's own blocks only (aircraft checks above/below the BEMT→F1A chain; Free field in the next columns so frames do not overlap). Solid **Feeds** arrows and dotted branches to case chips. Scroll horizontally and vertically (Shift+wheel sideways; Ctrl+wheel zoom; Fit). Click a block for what_it_does / code; click a chip for case detail → **Run** / **Open report**. Layout and copy from [`VALIDATION_GUIDELINE.md` §2.13](docs/VALIDATION_GUIDELINE.md) (`Position` / `Feeds` / `Group` / `Role`). Offscreen smoke shots: `VALIDATION_MAP_TOTAL.png` (left, zoom 1) and `VALIDATION_MAP_TOTAL_right.png`. `UT_GRID` is a runnable unit test with a γ-coloured 160-point grid figure.

**Cabin modes tab (phase 36):** own tab (cheaper than embedding in the Validation map `CYL2D_C1` detail). Mode 0–19, axial q, play/pause/speed, Refresh. Shows f, Φ_G, symmetry; for modes 0–5 the printed Fig. C-3 one-decimal values; optional Table D-1 structural ψ and f′. Fixed `CYL2D_C1` inputs (c0, θ0, NY) — not editable. **Display only — no criterion, no verdict, no tuning**; frames are interpolated for drawing (node values unchanged). PNGs/GIFs under `PAIN.jl/gui/cache/mode_anim/` (not validation figures).

## Using PAIN from the Julia prompt (optional)

This is a different place from PowerShell. In PowerShell, type this to open the Julia prompt (it shows `julia>`):

```powershell
julia --project=.
```

Then paste the lines below at the `julia>` prompt. They are Julia code and will fail in PowerShell. Type `exit()` to leave.

```julia
using PAIN
r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
evaluate_T1(r.spectrum)   # expect PASS
evaluate_T2(r.spectrum)   # expect PASS (1.25-2 kHz)
```

## If something fails

| What you see | What to do |
|--------------|------------|
| `The term 'julia' is not recognized` | Go back to Step 0. |
| `Project.toml` not found, or a package is missing | You are in the wrong folder. Run Step 1 again. |
| Error while installing `QML` / Qt | Copy the first `ERROR` line and report it. The GUI is optional, but the install must finish for the other commands. |
| `run_pain.jl` ends with "one or more validation gates failed" | The pipeline ran, but a check did not pass. Read the PASS/FAIL summary just above that line. |
