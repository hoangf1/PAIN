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
The [flowcharts](docs/flowchart.md) show the NASA validation path (diagram 2), the aircraft validation path (diagram 3) and the shared cabin model (diagram 4).

## Status

| Block | Status |
|-------|--------|
| Blocking Eq. (43) R1/R2 | **Done** <= 0.06 dB |
| Grid + assumed extension | **Done** (e11 path). Grid azimuth fixed 2026-10-20 (12b): line l = 1 at the propeller azimuth phi_p, upper quarter, theta_l = phi_p + (l-1)·10°; incidence gamma measured from the surface-to-hub direction (0 at l = 1, k = k_p). Results from before this date used the bottom of the fuselage and are void |
| Cabin pre-registration (phase 13) | **Done 2026-10-20** (documentation only, no code change). Assumption register for 15a-17a and the loss/trim pass criteria are dated in [`VALIDATION_GUIDELINE.md` §2.11](docs/VALIDATION_GUIDELINE.md). Cabin phase 17 is partly done (2026-10-20); phase 18 is next |
| Fig. E-12 blocking check (phase 14a) | **Done 2026-10-20** (no `src/` change). Eq. (43) on ANOPP Table 8 reproduces NASA's predicted E-12 curve at 29 of 31 points within delta_dig + 0.5 = 3.41 dB; FAIL at H3 aft (+4.3, +3.8 dB), recorded. delta_dig = 2.91 dB (E-11 gate of 1 dB not met). Prediction is 1-7 dB above the measured circles. Report `docs/validation_reports/e12_blocking.md`; script `PAIN.jl/scripts/e12_blocking.jl` |
| CYL2D (phase 15, App. C) | **Done 2026-10-20.** Exactly as CR-3813 App. C: half-cabin grid with NY = 10 intervals floor to crown, Eqs. (C.1)-(C.6), symmetric and antisymmetric modes solved separately, first 20 kept, Phi_G (C.10), eps_n (C.11), boundary values at the boundary nodes with segment limits halfway between neighbours. Against Table C-1 (c0 = 341 m/s, the speed the table implies): all 20 frequencies within 0.001 % and generalized masses within 0.002 % (criterion 0.1 %, fixed before the run), symmetry types equal, Fig. C-3 modes 0-5 equal to the printed one-decimal values at every node (V-CODE, 61/61 in `cyl2d_table_c1.md`). A singular B_E or a grid whose eigenvalues are not real raises an error (no pseudo-inverse); `cyl2d_modes_search` handles other floor angles. Three-dimensional modes (q, i): `cabin_frequency_3d`, `cabin_eps_3d`, `axial_truncation`, `cabin_modes_3d`; the q convergence rule 13a(d) is met under Eq. (8) (0.000 dB, `q_convergence.md`) |
| MRP | **Done**; Fig. D-2 mode 1: shell shape matches within print quantization, floor 0.057 vs 0.05 criterion (19g); production modes reuse Table D-1 frequencies (not a test of the solver); raw Ritz solver matches 30/32 within 5% after 3 scales were fitted to D-1 |
| Coupling f'(n,r) | Implements CR-3813 Eq. (52) (shell and floor terms, no clamp; an out-of-range value raises an error); Table D-1 shapes for all 32 modes; its tests pass. No |f'| > 1 error occurred in the phase 17 runs |
| PAIN core, Eq. (8) (phase 17) | **Phase 17 done 2026-10-20**; phase 19 diagnostics done; **η_T = 0.5 adopted for Phase III** (author 2026-10-20, phase 20); **19i done 2026-10-21**: H3 modal breakdown at η_T = 0.5 (modes 15/25/17/21); omitted D-1 terms \|δ\| ≤ 0.057 **not found** as the H3 cause (`docs/validation_reports/h3_followup.md`). 18b-r: +3.7, +0.2, +9.1 dB (2 of 3 within 4 dB). Eq. (8) derivation and conservation closed in 19a–19b (`eq8_two_resonator.md`); other candidates ruled out in 19c–19h. `tone_mean_square_pressure` is Eq. (8) summed by Eq. (3); broadband HF path still a surrogate (30b). Baselines: `data/baselines/phase17_baselines.csv`. Trace: `docs/validation_reports/pain_core_eq8_phase17.md` |
| Fig. E-11 SRC_TA | **Done** delta_dig <= 1 dB (repeatability of reading only) |
| **T1 tonal vs E-16** | **18a-r (η_T = 0.5):** 81.04, 75.00, 75.29 dB — H1/H2 pass by NASA route only, H3 fails; **no claim**. GEXT importance bound **run 2026-10-21**: flat falloff and delay ×2 flip the T1 gate → **T1 depends on GEXT, not claimable** (`gext_importance_bound.md`) |
| **T2 1/3-oct vs E-9** | **18a-r:** 52.96 (pass), 50.62, 48.66 dB (fail) against 51.0, 46.0, 41.5; `bb_j2_scale` = 0.5 stale; replaced in 30b. Original 18a 62.3/60.3/58.5 kept as wrong η_T. **No claim** |
| **PAIN reproduction vs NASA (18b-r)** | **Not met, 2 of 3** (η_T = 0.5): 82.73, 75.73, 77.05 dB = +3.7, +0.2, +9.1 dB vs 79.0, 75.5, 68.0. Original 18b at 0.05 (91.9, 80.0, 84.9, 0 of 3) kept. **19i:** omitted D-1 terms not found as H3 cause (`h3_followup.md`). Report `pain_reproduction_e16.md` |
| Trim / loss (phase 16, App. A + section 3.8) | **Done 2026-10-20.** Written from the printed equations, no fitted parameter: App. A transfer matrices (A.10)-(A.12), tau_t (A.22), C_w, beta (A.16), mechanical path (A.19)-(A.21), Phase III stacks; Si/Cin, joint acceptances (63)-(73), eta_n (77), eta_r (79)-(81), eta_r' (82), eta_r'' (83). Fig. A-2 digitized in `data/fig_a2_pf105.csv`. Eq. (78) against NASA's calculated Fig. E-14 curves: **7 of 18 bands within +-25 %** at trim loss 0.5 and at 1.0 (criterion not met, recorded, not tuned); Fig. E-13 has no calculated curve. Printed-equation findings (factor 2 in Eqs. 69-70, the Eq. 82 limp-mass limit) in the [plan](docs/IMPLEMENTATION_PLAN.md). In the pipeline since 17a (2026-10-20). Report: `docs/validation_reports/trim_loss_e13_e14_e15.md` (`julia --project=. scripts/run_trim_loss_check.jl`) |
| CCBlade -> F1A | **Done** (phase 21): all 160 points via `evaluate_propeller_source`, no GEXT; Table-8 peak calibration optional post-step. `ScaledLoads` + `allow_static` + `load_polar_set` + `blade_form_geometry` + rms/`p_c` helpers (25). Class **X-EXTRAP** until source checks close |
| Report 996 / Pereira checks | **Expanded 2026-10-21** (`report996_loads.md`, `report996_acoustics.md` Figs. 14/13a/7, `report996_setup.md` 25k, `pereira_forward_flight.md` 3-polar matrix; C-01–C-12 digitized). **No pass/fail** until §2.12 freeze **[AUTHOR]** |
| dB(A) / SIL | **Done** |

**Severe blockers for the author (nothing else left without approval):**
1. **§2.12 / 23f** — fill **[AUTHOR]** tolerances and date the freeze (blocks official 24–28 verdicts).
2. **BBN common time base (24b)** — per-observer F1A FFT phases are not comparable (`bbn_phase.md`); needs a shared reception clock or cross-spectrum path.
3. **29b/29c [CONFIRM]** — NASA-default guard and provenance tags on the aircraft path.

C-05 pass B is done (δ_dig = 1.00 dB). Remaining planned work after those: phases 30–31–33 (+ optional C-13). Near-field F1A amplitudes at Report 996 d/D=0.083 remain ≫ measured (documented, not a pass).

Source-block data: Report 996 in `data/report996/`; Pereira in `data/pereira/`; CR-3813 E-16…E-22 / E-9/E-10 pass-B CSVs in `data/`; BBN phase Figs. 18–20 in `data/NASA_CR-159124/`. Details in the [plan](docs/IMPLEMENTATION_PLAN.md).

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

### Step 4 - Run the full pipeline and validation checks

```powershell
julia --project=. scripts/run_pain.jl
```

Prints the interior tone levels, the T1/T2 checks, and a summary of PASS/FAIL lines. It writes reports to
`docs\validation_reports\`. It ends with an error message if any check fails; read the summary above it.

### Step 5 - Run the CCBlade + F1A smoke test (aircraft source)

```powershell
julia --project=. scripts/run_f1a_smoke.jl
```

Compares the propeller noise on the l = 1 line with ANOPP Table 8 and writes `docs\validation_reports\ccblade_f1a_smoke.md`.

### Step 6 - Open the GUI (optional)

```powershell
julia --project=. scripts/run_gui.jl
```

GUI source modes today: `e11` (validation test), `synthetic` (smoke test), `aircraft` (BEMT + F1A; needs an aircraft JSON file, for example
`examples\aircraft_scale_hartzell.json`).

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
