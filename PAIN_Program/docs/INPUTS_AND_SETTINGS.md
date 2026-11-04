# PAIN inputs and settings (Phase 127, 2026-11-04)

Author 2026-11-04: "are all inputs exposed in the PAIN_Program gui i dont like there being any constants hidden inside
pain ... if there are any constants then make it available for change in the gui", and "instead of a json id like the
user inputs in the gui". This file lists every input of the aircraft run and every constant on its path, where it is
set, and what stays fixed and why. PAIN_Program and Cabin_Noise are not connected: no shared code or defaults.

## How the GUI holds them

- **Run tab, Inputs panel.** One tab per group (left list), one field per input. A field shows the value in use, its
  unit, a tooltip with its meaning and source, and "default X" in orange when it differs from the code default.
- **Project file (optional).** Open fills the fields from a file in the aircraft JSON format, Save writes them, Defaults
  returns to the built-in project (`examples/aircraft_scale_hartzell.json`). Run does not need a file: it writes the
  fields to a temporary project and runs it.
- **Defaults are the code's.** A field is written to the project only when its value differs from what was loaded, and a
  value equal to the code default is not added. A loaded value keeps its provenance tag (measured / assumed /
  nasa_default) until it is edited. So the default project runs exactly as before Phase 127: H1–H5 and every band are
  bit-identical on the default Hartzell run, the e11 test-article run and the Commander 695A run (checked 2026-11-04).
- **Settings in a run.** `PainSettings` (src/pain_settings.jl) holds the run-path constants; `run_pain_pipeline(;
  settings)` or the project's `"settings"` object (only the fields that differ) applies them to one run through a scoped
  value. Validation cases and tests use `PainSettings()`, the old literals.

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
| Broadband and bands | broadband model, slope α, surrogate j² scale, anchor harmonic, extrapolation, band centres, η_r and η_n per band | `cabin.*`; the band cards at the top level: `bands_Hz`, `eta_r_band`, `eta_n_band` |

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

| Group | Settings (default) |
|---|---|
| Grid | k_max 16, ℓ_max 10, k_p 8, step 10° (ΔA = (a·step)²) — User Manual §3 |
| Source | source times 64, source span 2 rev, static guard below 1 m/s → 20 m/s, Prandtl tip/hub loss on, default polar: lift slope 2π, α clamp 0.35 rad, c_d0 0.01, c_d2 0.15 |
| Blocking | Eq. 43 constants 0.3, 0.000224, 0.08; R2 factor 0.8; minimum F 1 |
| Cabin modes | CYL2D modes per parity 20, node tolerance 0.4, extra NY tried 10, 2-D mode speed 341 m/s |
| Structural modes | modes kept 32, App. D cutoff 2 × highest tone rounded up to 100 Hz, series start M 10 / n 12 / floor 5, convergence 1 % or 2 modes, cap 640 terms, terms kept per mode shell 5 / floor 3, floor cross terms off |
| Coupling | q = 0 coupled off, η_n per mode on, η_n at band centre on, lowest η_n band 100 Hz, η_r over trimmed area on, per-band η_r is η_r′ off, floor sign +1, trim at band centre off, crossover band 0 (= Eq. 24), η_r cap 0 (= none), c_ω 0.232 |
| Tones and broadband | tone model eq8, broadband on from 1000 Hz and above 1.15 × the last tone, ⟨j²⟩ with no mode 2.5e-4, ⟨j²⟩ lower limit 1e-6, surrogate: band width 0.2316, density 0.015 aL f/500 Hz, minimum Δf 1 Hz, n_ref 3 modes at 1500 Hz, χ 0.25–4 |

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
