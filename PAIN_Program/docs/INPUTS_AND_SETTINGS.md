# PAIN inputs and settings (Phase 127, 2026-11-04)

Author 2026-11-04: "are all inputs exposed in the PAIN_Program gui i dont like there being any constants hidden inside
pain ... if there are any constants then make it available for change in the gui", and "instead of a json id like the
user inputs in the gui". This file lists every input of the aircraft run and every constant on its path, where it is
set, and what stays fixed and why. PAIN_Program and Cabin_Noise are not connected: no shared code or defaults.

## How the GUI holds them

- **Run tab, Inputs panel.** One tab per group (left list), one field per input. A field shows the value in use, its
  unit, a tooltip with its meaning and source, and "default X" in orange when it differs from the code default.
- **Project file (optional).** Open fills the fields from a file in the aircraft JSON format, Save writes them, Defaults
  returns to the built-in project (`examples/aircraft_generic_twin_turboprop.json`, Phase 128). Run does not need a
  file: it writes the fields to a temporary project and runs it.
- **Built-in project (Phase 128, 2026-11-04).** Author: "much of the current defaults like blade number rpm speed arent
  matched with cabin_noise". The GUI opens on the generic twin turboprop of Cabin_Noise's default project
  (`Cabin_Noise/cabin_noise/data/default_project.json`), its values copied by hand; the programs share no code or file.
  The table below gives each value and where it comes from. The scale Hartzell project
  (`examples/aircraft_scale_hartzell.json`) stays, unchanged, for the tests and the scripts, and opens with Open.
- **Defaults are the code's.** A field is written to the project only when its value differs from what was loaded, and a
  value equal to the code default is not added. A loaded value keeps its provenance tag (measured / assumed /
  nasa_default) until it is edited. So the default project runs exactly as before Phase 127: H1–H5 and every band are
  bit-identical on the default Hartzell run, the e11 test-article run and the Commander 695A run (checked 2026-11-04).
- **Settings in a run.** `PainSettings` (src/pain_settings.jl) holds the run-path constants; `run_pain_pipeline(;
  settings)` or the project's `"settings"` object (only the fields that differ) applies them to one run through a scoped
  value. Validation cases and tests use `PainSettings()`, the old literals.

## Built-in project: Cabin_Noise's generic twin turboprop

| PAIN field | Value | From Cabin_Noise |
|---|---|---|
| Blades | 6 | `propeller.blades` |
| Tip radius, rpm | 1.74994 m (HP_1650), 1183.33 rpm (BPF 118.33 Hz) | Phase 129 (2026-11-04): R from HP_1650; rpm set so the helical tip Mach number √(V² + (ΩR)²)/c = 0.85 (Cabin_Noise: 1.7526 m, 1181 rpm) |
| Flight speed | 149.198 m/s | Mach 0.4818 × c at 7620 m: 290 KTAS at 25000 ft (290 kt = 149.19 m/s; the 0.006 % difference is Cabin_Noise's rounded Mach) |
| Air at the propeller: ρ, c, μ | 0.54895 kg/m³, 309.668 m/s, 1.53981e-5 Pa·s | ISA 7620 m (T 238.62 K), Cabin_Noise's `atmosphere.py` formulas |
| Outside ρ, c (cabin group) | the same | the same |
| Cabin ρ0, c0 | 0.89440 kg/m³, 343.232 m/s | `cabin_air(2438.4 m, 293.15 K)` |
| Structure length L, cavity length L_c | 22.7 m | `cabin.Lx` |
| Radius a | 1.32 m | `cabin.Ly` / 2 (a box there, a cylinder here) |
| r_p | 4.1699 m | a + tip radius + `propeller.clearance` 1.1 m |
| z_p, φ_p | 11.35 m, 90° | L / 2: mid-cabin, hub level with the fuselage axis (Cabin_Noise has no station relative to the cabin; kept by the author 2026-11-04) |
| Structure (Phase 130) | the 8 MRP card values of CR-172428 Table 13, small-body turboprop: shell 1.93 mm equivalent, 5.34 kg/m², D′ stringers 1.892e3 N·m, D′ frames 4.362e4 N·m; floor 1.91 mm, 19.68 kg/m² (with seats), D′ longitudinal beams 1.892e3, transverse supports 4.362e4 N·m; E 7.24e10 Pa, ν 0.33 | Not from Cabin_Noise (it has no stiffeners; its 1.6 mm skin is not used). Table 13 is the printed turboprop nearest in size (D 2.29 m against 2.64 m), used unscaled. Wall mass for the trim and Eqs. 81–82: the card shell mass 5.34 kg/m² (Cabin_Noise: 5.95 kg/m²) |
| Damping | η_n bare 0.05, C = 3 | PAIN's defaults (CR-3813: C between 2 and 4); nothing printed for this cabin |
| 2-D cabin-mode sound speed | 0 = the cabin air's c0, 343.232 m/s (`settings.c_cyl2d_mps`) | follows an edited c0 (PAIN's CYL2D used 341 m/s; kept for the NASA reproductions) |
| Grid | 40 × 19, k_p 20 (`settings.grid_*`) | Phase 131: converged on this cabin (9.2 m, 180°); the code default 16 × 10 spans only 3.7 m and 90° here |
| Broadband | off (`settings.broadband` = false) | Phase 130: not verified for this use; GUI runs are tones only |
| Trim | stack: insulation 0.09 m, limp mass 2.7 kg/m² | `sidewall.cavity_depth`, `trim_mass` (double wall) |
| Harmonics | 5 | PAIN's own (Cabin_Noise's auto takes every harmonic below 5 kHz) |
| ANOPP Table 8 scaling | off | Table 8 is the 0.762 m Hartzell test, not this propeller |
| Insulation-table extrapolation | on (X-EXTRAP) | the 22.7 m cabin has structural modes from about 13 Hz, below the table's 100 Hz |
| Blade stations, chords, twist, hub radius | HP_1650: 39 stations, c/R·R, β(r) of `blade_form.csv`, hub 0.325 m | Phase 129: `propeller_sizing_and_analysis/propellers/hp_1650` (propeller.yaml, blade_form.csv); stations inside the spinner (r/R < 0.1857) dropped; β is the file's chord-line datum at its first design point (β75 34.281°); all editable in the Propeller tab |
| Blade pitch (Phase 133) | pitch offset 15.98° (β75 50.26°) | sets CCBlade's shaft power to the author's 2200 hp (2026-11-05; Cabin_Noise's 1640539.7 W) at 1183.33 rpm, 290 KTAS, 25000 ft: 2199 hp, thrust 9.24 kN, η 0.84. The file's β alone windmills here (inflow 42.5° at 0.75R: −9.9 kN, −1.25 MW). PAIN has no power input: re-set the offset for another flight condition |
| Station area / chord² | naca4_area_over_chord2(t/c) at each station | t/c from `blade_form.csv`; the file's sections are NACA 16-series, the area formula is the NACA 4-digit one (approximation); clear the field for loading-only |

Not carried over, because PAIN has no input for them: shaft power (1.64 MW; since Phase 133 it sets the blade pitch above), engines, windows, cabin surface absorption,
the boundary-layer source, the seat percentile. Every other field keeps PAIN's code default (damping and the Numerics
settings, except the grid, the 2-D mode speed and broadband, listed above). The project is X-EXTRAP and is not a validation case: it is compared with nothing.
A run takes about 5 min (274–332 s measured on the 40 × 19 grid, Phase 131), against seconds for the Hartzell project. Most of it (about 80 %) is the tone
sum, which couples every structural mode with every cabin mode of the 22.7 m cabin at each harmonic.

## Physical inputs (GUI groups → project keys)

| Group | Fields | Project keys |
|---|---|---|
| Run | blocking R2/R1, harmonics, cabin blocks (auto / parametric / surrogate) | `run.blocking`, `run.n_harmonics`, `cabin.cabin_blocks` |
| Propeller | blades, rpm, tip and hub radius, pitch offset, t/c, station radii, chords, twist, area/chord² | `propeller.*` |
| Flight | speed, air density and sound speed at the propeller, viscosity, ANOPP Table 8 scaling on/off and its file | `operating_point.*`, `anopp_table8_calibrate`, `anopp_table8_csv` |
| Placement | r_p, φ_p, z_p, rotation sense | `cabin.r_p_m`, `phi_p_deg`, `z_p_m`, `rotation_direction` |
| Cabin | L, a, θ0 (auto = printed aircraft nearest in radius), L_c, d, ρ0, c0, outside and cabin ρ and c, NY, q_max | `cabin.*` |
| Structure | solver (auto / appd / table_d1 / ritz), wall mass, the 13 App. D section inputs, the 8 MRP card values | `cabin.*` |
| Damping and trim | η_n bare, C (Eq. 80), trim (auto / bare / phase3 / stack), stack: insulation table, sidewall and end-plate elements (one per line), mechanical path (6 values) | `cabin.eta_n_bare`, `C_struc`, `trim`, `trim_stack.*` |
| Bands | extrapolation, band centres, η_r and η_n per band | `cabin.allow_extrapolation`; the band cards at the top level: `bands_Hz`, `eta_r_band`, `eta_n_band` |

**No broadband inputs (Phase 130, 2026-11-04).** The interior broadband path (Eqs. 19–23 or the surrogate, from an f^−α
exterior spectrum anchored to a tone) has no met comparison with data, so the GUI has no broadband field (model, α, j²
scale, anchor harmonic and the 13 broadband settings) and every GUI run is tones only: `gui_run_args` writes
`settings.broadband = false`. A project file's broadband keys are not read by a GUI run. The code path stays for the
validation cases.

The band cards are written at the top level, where the code reads them first; a file that carries them as `bands` or
under `cabin` is still read, and a blank field removes them from every place. η per band takes "band: value" pairs
(`1000: 0.02, 1250: 0.03`) or a list with one value per band centre.

The BPF is shown as a readout, B·rpm/60; the old "BPF" field did nothing on the aircraft path and the printed-outputs
tab used it (150 Hz) instead of the run's BPF; it now uses the run's.

Keys some example files carry that the code does not read are named when the file is opened: `grid`, `harmonics`,
`acoustic_analogies`, `fuselage.L_m/a_m/theta0_deg`, `propeller_placement.r_p_m/phi_p_deg/z_p_m`,
`propeller.diameter_m`, `propeller.airfoil_polar_files` (the aircraft path uses the default polar; a measured polar set
is a Validation-tab option), `operating_point.altitude_m/pitch_deg`. Their run-path counterparts are the fields above.

## Settings (GUI groups "Numerics: …", project `"settings"`)

Each was a literal in the code; its default is that literal.

**Checked 2026-11-04 (Phase 130).** Each setting was changed alone on the scale Hartzell project (3 harmonics, then a
trimmed copy, 5 harmonics): every one runs, and every one changes the tones where it applies. Those that changed
nothing apply only elsewhere: the static guard (speed below 1 m/s), the source span (a steady propeller is periodic),
the extra NY grids (only when NY has no solution), the App. D start counts, cap and minimum (the cutoff search doubles
the series until the mode count converges, so it ends at the same set) and the broadband settings (tones). On a
full-size cabin the grid scales with a (axial extent 16·πa/18 = 3.7 m for a = 1.32 m, about one propeller diameter);
it is not converged there, so the built-in project uses 40 × 19 (COMPLETED_PHASES §8bu).

| Group | Settings (default) |
|---|---|
| Grid | k_max 16, ℓ_max 10, k_p 8, step 10° (ΔA = (a·step)²) — User Manual §3 |
| Source | source times 64, source span 2 rev, static guard below 1 m/s → 20 m/s, Prandtl tip/hub loss on, default polar: lift slope 2π, α clamp 0.35 rad, c_d0 0.01, c_d2 0.15 |
| Blocking | Eq. 43 constants 0.3, 0.000224, 0.08; R2 factor 0.8; minimum F 1 |
| Cabin modes | CYL2D modes per parity 20, node tolerance 0.4, extra NY tried 10, 2-D mode speed 341 m/s |
| Structural modes | modes kept 32, App. D cutoff 2 × highest tone rounded up to 100 Hz, series start M 10 / n 12 / floor 5, convergence 1 % or 2 modes, cap 640 terms, terms kept per mode shell 5 / floor 3, floor cross terms off |
| Coupling | q = 0 coupled off, η_n per mode on, η_n at band centre on, lowest η_n band 100 Hz, η_r over trimmed area on, per-band η_r is η_r′ off, floor sign +1, trim at band centre off, crossover band 0 (= Eq. 24), η_r cap 0 (= none), c_ω 0.232 |
| Tones | tone model eq8 |
| Broadband (not GUI fields, Phase 130) | broadband on from 1000 Hz and above 1.15 × the last tone, ⟨j²⟩ with no mode 2.5e-4, ⟨j²⟩ lower limit 1e-6, surrogate: band width 0.2316, density 0.015 aL f/500 Hz, minimum Δf 1 Hz, n_ref 3 modes at 1500 Hz, χ 0.25–4 |

## Fixed, with the reason

| What | Why it is not an input |
|---|---|
| p_ref = 20 µPa, the A-weighting curve, the nominal and exact 1/3-octave centres | Definitions of the scale: changing them relabels the result, not the physics. |
| NASA's printed tables (Table D-1, Table C-1, the PF-105 table of Fig. A-2, ANOPP Table 8) | Data from the reports; they are selected by the solver, trim and Table 8 fields. |
| The Phase III trim description (`phase3_trim`) | The printed CR-3813 test-article treatment, used only with trim = phase3; any other treatment is a stack. |
| The fallback blade (12 sections, chord 0.08 R, twist 40°→10°) | Used only when a project gives no blade arrays; the GUI always gives them. |
| Numerical guards (1e-30 in log10, 1e-12 and 1e-9 divisors, the ±1e-8 eigenvalue snap) | Keep a log or a division finite; they do not set a result. |
| Validation-case inputs and criteria | Fixed and dated before each comparison (CLAUDE.md); the Validation tab is read-only. |

No setting is fitted or selected against a comparison, and none is changed from its literal by Phase 127.
