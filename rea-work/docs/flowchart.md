# PAIN recreation flowcharts

| Diagram | What it shows |
|---------|---------------|
| [1. Overview](#1-overview) | Total flowchart: aircraft + e11 → grid → cabin → checks |
| [2. NASA validation (e11)](#2-nasa-validation-e11) | Measured free-field → GEXT → cabin → T1/T2 |
| [3. Aircraft validation](#3-aircraft-validation) | BEMT+F1A source and experiment checks |
| [4. Shared cabin model](#4-shared-cabin-model) | Blocking, modes, trim, PAIN main |
| [5. Validation maps](#5-validation-maps) | GUI `total` map (titles only) |

Colour key in diagrams: green = check exists and passes as stated; orange = planned / differs / calibrated; blue = calibrated surrogate; red = blocked / fail. **Status and evidence live in the tables under each diagram**, not inside nodes. Detail: `IMPLEMENTATION_PLAN.md`.

## Status

- **2026-10-24:** Closure register (`VALIDATION_GUIDELINE.md` §2.14): every not-met case mapped to its cause class; no open code defect.
- **2026-10-24:** Phase 67: `POLAR_FIDELITY` on A_GEO (XFOIL vs TN 1546 measured c_l, not met 9/60), `F1A_CHORDWISE` on A_AMP (compact vs chordwise loading ≤ 0.27 dB): the Report 996 source misses come from the section polars.
- **2026-10-24:** Phase 66 (A_LOADS / A_AMP): `BEMT_MOMENTUM`, `BEMT_HAND_TIP`, `BEMT_INTEGRALS`, `BEMT_SIMILARITY` on A_LOADS; `F1A_GUTIN_ANGLES` (not met 4/5, near-null phase), `F1A_GW_FLIGHT`, `F1A_THICKNESS`, `F1A_PROPERTIES` on A_AMP; the shared CCBlade set-up is `_ccblade_setup`, the F1A step `_f1a_harmonics`.
- **2026-10-24:** Phase 65: the 160-point grid runs z_k = z_p − x₃ from the propeller plane (User Manual pp. 8–9, App. E p. E-8), z_p = 0.662 m for the test article (was mirrored, z_p = 0.90 m). Phase 62: each map block has a proving case with its own figure (12 new: `F1A_PLANE_PEAK` on X_F1A, `FF_E11_MAP` on X_FF, `SRC_PASSTHROUGH` on X_SRC, `BLK_GAIN_MAP` on X_BLK_OUT, `MRP_INPUT_QA` on X_MRP_IN, `MRP_SHAPE_NORM` on X_MRP_OUT, `CABIN_GEOM_HAND` on X_CYL_IN, `CYL2D_WEYL` on X_CYL_OUT, `TRIM_INPUT_QA` on X_TRIM_IN, `TRIM_PASSIVITY` on X_TRIM_OUT, `PAIN_INPUT_ECHO` on X_PAIN_IN, `AC_CABIN_DEMO` on A_CABIN). Phase 63: the structural mode animates in the Cabin modes tab. Phase 64: unit tests for every function (`test/unit/`); the F1A_GUTIN reference is now the exact Gutin sum over the BEMT annuli (Δ = 0.03 dB). The GUI Run tab is the aircraft pipeline only; E-11 / synthetic inputs are PAIN verification (Validation tab).
- **2026-10-23:** Phase 61 (P_REPRO): NASA's pre-correction floor sign does not reproduce CR-3813's runs (`REPRO_18b_PRE` 1/3, `E21_PRE` 1/4, `E22_HF_CODE` 1/4); not explained by the documents. T2's high-frequency gap is recorded as a limitation of PAIN's method (NASA's own E-22 output is 32–44 dB above measured; the code is within 2–8 dB of NASA). Phases 59–60 closed (Sharp bridges option on P_EQ8/P_MEAS: `SHARP_PANEL_D`, `NR_PROP_TP2444_BR`, `E22_BR`, `T2_MEAS_EXT_BR`; App. D mode extension not adopted). Phases 50–58 closed (`NR_PROP_TP2444_PF` on P_MEAS; `sparse_guard`, Ritz `include_floor`/`include_stiffeners` options; Q22 closed). Phase 48 (P_FF / P_MEAS): `BPM_RP1218` met; `PROP_BB_FIG14`, `PROP_BB_FIG17`, `T2_PRED_BB` not met. Phase 49 (P_EQ8 / trim): Eq. (20) sums the modes below the band, as printed; no in-theory input correction for T2's high-frequency gap (NASA: the trim model is valid to about 1 kHz). Phase 47 (P_MEAS): `NR_PROP_TP2444` not met 1/7, `T2_MEAS_EXT` not met (21.3 vs 51.0 dB). The measured TP-2444 exterior through T2's cabin path shows that PAIN's high-frequency noise reduction is 15–27 dB too high for the trimmed article; NASA's own E-21/E-22 predictions show the same. Phase 46: isolated checks for the last untested T1/T2 functions (37/37). Phase 45 `NR_TP1964_XOVER` (T2's Eq. 19 path on TP-1964; P_MEAS). Phase 44f: Eq. (52) floor-term sign of NASA's corrected program (P_EQ8 coupling); T1_F1A_FILL met post-hoc. Phase 42 `LOUDEST_PT` (output stage: loudest-point dB(A) next to the space average). Phase 44 CR-172428 reproduction (`R172428_CODE`, `R172428_EXP`, `R172428_ETA`, `R172428_TRIM`, `R172428_PAIRS`): NASA's printed App. B field and Table 6 inputs through the cabin chain; App. A η_r′ option; Eq. (83) now uses the bare f′. Phase 43 T1/T2 root causes (`T1_MEAS_DAMPING`, `H3_ATTRIB`, `NR_TP1964` / `_REF2`, `T1_F1A_FILL`, `T1_F1A_MEAS_DAMP`); card-10 volume crossover default; bare-cylinder module `circular_cavity.jl`. Phase 41 isolation chips (`T1_FROM_E12`, `TRIM_CLOSED`, `NR_BAND_HAND`, `HF_MASSLAW`, `BEMT_HAND`, `F1A_INDEP`); five met, `T1_FROM_E12` not met (cabin chain). Phase 40 `ISO_*` all met except 40f. See `VALIDATION_GUIDELINE.md` §2.13.
- **2026-10-29 (Phase 82):** no flowchart change. Seven cases that compare with neither measurement nor PAIN's printed output carry no verdict on the map (`INFORMATION_ONLY_CASES`): LOUDEST_PT (`X_OUT`), BLK_GAIN_MAP (`X_BLK_OUT`), MRP_SHAPE_NORM and MRP_COUPLED_LIMITS (`X_MRP_OUT`, `P_MRP`), CYL2D_WEYL (`X_CYL_OUT`), F1A_GUTIN_ANGLES (`A_AMP`), SHARP_PANEL_D (`P_EQ8`).
- **2026-10-29 (Q60, Q62):** no flowchart change. `P_CYL` runs on the next solvable App. C grid when NY = 10 has no solution for the floor angle (`cyl2d_modes_solvable`). `VALIDATION_GUIDELINE.md` §0 draws the §5 map as a Mermaid chart coloured by case verdicts, with per-block case tables.
- **2026-10-29:** no flowchart change. Phase 81: new cases `SHARP_PANEL_D_SHAPE` (`P_EQ8`) and `LOUDEST_PT_GRID` (`X_OUT`); ISO_MODAL_DENSITY and HF_MASSLAW case fixes; information rows grey in error panels.
- **2026-10-29 (later):** no flowchart change. Phase 80 done: the structural block (`P_MRP`) can read NASA's MRP input deck (`AppDDeck`) as well as stiffener sections (`AppDGeometry`); new cases `MRP_COUPLED_LIMITS` (`P_MRP`) and `MRP_TRUNC` (`X_MRP_OUT`); MRP_APPD met 32/32 on the deck.
- **2026-10-29:** no flowchart change. Phase 80 planned (MRP validation with inputs known on both sides); new structural cases will sit on the existing `P_MRP` and `X_MRP_OUT` blocks.
- **2026-10-28 (last):** no flowchart change. Decisions: production CYL2D stays NY = 10 (79c); the TN 1546 c_d level is not adopted (73e). No-verdict figures draw no tolerance band (they have no criterion); seven no-verdict figures redrawn.
- **2026-10-28 (later):** Phase 78d-4: App. D solver consistency fixes (shape convention, full-circumference shell, null n = 0 functions, no dedup, floor sway and membrane coupling); MRP_APPD still 2/32 (floor stiffener model undocumented); UNC_COVER 0/3. 78e: MRP_SHAPE_NORM excess is in the printed table. Phase 79a: information rows leave the map chip counts. Phase 77: POLAR_FIDELITY shows the offset also as an equivalent angle. Phase 75: `regenerate_case_figures.jl` and a stale-figure note on case selection. Phase 79b: CYL2D grids refine (only the kept App. C modes must be real); NY = 10 production unchanged. Phase 79c/79d: CYL2D_GRID_CONV on X_CYL_OUT (NY 10 within 4.9 % of NY 60); CYL2D_WEYL against Weyl + surface term (4/5; converged grid within 6 %). Phase 78f: MRP_D1, MRP_RITZ off the map.
- **2026-10-28:** audit: polar path defects (plan Phase 69: one section at every Report 996 station, μ = 1 in CCBlade, no Re/M interpolation, no stall) and free-field block findings (Phase 70); map rows no longer overlap; `VALIDATION_GUIDELINE.md` §2.13 case records grouped by map chunk. Phase 69 fixes in the BEMT polar path (`load_polar_set` → `PolarSet` with per-station `section_polar`; `_ccblade_setup` passes μ = `AIR_MU_PA_S`) and the Report 996 polar input is now `polars_phase69_ncrit8.json` (free transition, N_crit 8); the affected cases are rerun (post-hoc, no verdict changed). Blocking (Eq. 43) unchanged: the A3b diagnostic found no missing term. Phase 72: AcousticAnalogies +X is ahead of the propeller; the Report 996 and Pereira observer builders (`R996_X_SIGN`, `pereira_observers`) now follow their documents. Phase 73: sensitivity script `scripts/run/r996_polar_sensitivity.jl` (no pipeline change). Phase 75 (planned): Validation tab figure regeneration and a stale-figure flag. Phase 76: F1A thickness term on for the Report 996 and Pereira comparisons (`area_over_chord2` from the section coordinates). Phase 74: Pereira Fig. 9 reference re-read from the PDF vectors (data only). Phase 78: MRP_APPD identity matching (`match_modes_by_identity`); App. D stiffener inputs corrected (78d); MRP_APPD pairs by shape (MAC, 78d-3), 2/32; junction constraints next.
- **2026-10-22:** GUI Validation map is one horizontal `total` flowchart (aircraft + e11 + cabin + checks); titles only on blocks; stage frames pairwise disjoint (aircraft checks above/below pipeline). See §5 and `VALIDATION_GUIDELINE.md` §2.13.
- **Phases 38d–38e / 38c / 38h / 38g / 36:** E18_TONES, E15_STRUCT_LOSS, HF broadband, printed outputs, MRP_APPD, cabin mode animation — see `IMPLEMENTATION_PLAN.md`.
- **L = 1.83 m (I-22, post-hoc):** `test_article_length()` default; re-records in `length_rerecord_before_after.md`; no verdict flips.
- **Grid azimuth (12b):** ℓ = 1 at propeller azimuth; pre-2026-10-20 e11 results void.
- **Test tooling (P1):** `Pkg.test` `test_args` substrings; DaemonMode optional under `scripts/devtools/`. Tests write only to a temp dir; a final check fails if the suite modifies tracked docs/data (2026-10-23).
- **Layout (R1):** CR-3813 data under `data/cr3813/`; scripts under `PAIN.jl/scripts/{run,checks,digitize,setup,smoke}/`.

## 1. Overview

Whole program (titles only). Same structure as the GUI `total` map.

```mermaid
flowchart LR
  subgraph G_AIR["Aircraft BEMT+F1A"]
    direction LR
    A_GEO["Aircraft inputs"] --> A_LOADS["CCBlade BEMT"]
    A_LOADS -->|L, D| X_F1A["F1A source"]
    X_F1A -->|p| X_FF["Free field p"]
  end

  subgraph G_FF["Free field"]
    direction LR
    P_FF["e11 free field"] --> X_SRC["Source select"]
    X_FF --> X_SRC
  end

  subgraph G_GRID["Grid and blocking"]
    direction LR
    P_GRID["160-point grid"] --> P_BLK["Blocking Eq. 43"]
    P_BLK --> X_BLK_OUT["Blocked pressures"]
  end

  subgraph G_MRP["Structural modes"]
    direction LR
    X_MRP_IN["Structure inputs"] --> P_MRP["Structural modes"]
    P_MRP --> X_MRP_OUT["Modes f_r, ψ_r"]
  end

  subgraph G_CYL["CYL2D"]
    direction LR
    X_CYL_IN["Cabin geometry"] --> P_CYL["CYL2D"]
    P_CYL --> X_CYL_OUT["Modes Φ_G"]
  end

  subgraph G_TRIM["Trim and loss"]
    direction LR
    X_TRIM_IN["Trim stack"] --> P_TRIM["Trim and loss"]
    P_TRIM --> X_TRIM_OUT["τ, η"]
  end

  subgraph G_PAIN["PAIN main"]
    direction LR
    X_PAIN_IN["Cabin inputs"] --> P_EQ8["Coupling / Eq. 8"]
    P_EQ8 --> X_OUT["Interior SPL"]
  end

  subgraph G_VAL["Validation comparisons"]
    direction TB
    P_REPRO["vs NASA PAIN"]
    P_MEAS["vs measurement"]
    A_CABIN["Aircraft cabin"]
  end

  X_SRC --> P_GRID
  X_BLK_OUT --> X_PAIN_IN
  X_MRP_OUT --> X_PAIN_IN
  X_CYL_OUT --> X_PAIN_IN
  X_TRIM_OUT --> X_PAIN_IN
  X_FF -.-> A_AMP["F1A amplitude"] & A_PHASE["F1A phase"] & A_FWD["Forward flight"] & A_SURF["Surface levels"]
  X_OUT -.-> P_REPRO & P_MEAS & A_CABIN

  style A_AMP fill:#fff4e8
  style A_PHASE fill:#fff4e8
  style A_FWD fill:#fff4e8
  style A_SURF fill:#fff4e8
  style P_REPRO fill:#fff4e8
  style P_MEAS fill:#fff4e8
  style A_CABIN fill:#f3e5f5
```

| Block | Status / evidence | Where |
|-------|-------------------|-------|
| Aircraft BEMT+F1A | Source path; X-EXTRAP for cabin | Diagram 3; map `G_AIR` |
| e11 free field | Digitization QA; ANOPP H3/phases | E11_FREEFIELD |
| Grid + blocking | Unit + Eq. 43 checks | UT_GRID, BLK_P68, E12_BLOCK |
| Structural / CYL2D / trim | Table D-1 / C-1 / App. A | MRP_*, CYL2D_C1, UT_TRIM, E14/E15 |
| PAIN main | Eq. 8 + HF | UT_EQ8; 38b–38c |
| vs NASA PAIN / measurement | Code-on-code / in-sample | REPRO_18b, E18_TONES, T1, T2, E21_E22_NR |
| Aircraft cabin | X-EXTRAP | A_CABIN |

## 2. NASA validation (e11)

Purpose: cabin model vs NASA published results. No CCBlade/F1A.

```mermaid
flowchart LR
  S["e11 free field"]

  subgraph EXT["Grid extension"]
    direction TB
    E1["Fill 160 points"]
    E2["Code check"]
    E3["GEXT bound"]
  end

  CAB["Shared cabin"]

  subgraph VAL["Interior SPL"]
    direction TB
    V1["Tonal T1"]
    V2["Broadband T2"]
    V3["Band diagnostic"]
  end

  S --> E1
  E1 --> CAB
  E1 -.-> E2
  E1 -.-> E3
  CAB --> V1 & V2
  V1 -.-> V3
  V2 -.-> V3

  style S fill:#e8ffe8
  style CAB fill:#fff4e8
  style V1 fill:#fff4e8
  style V2 fill:#fff4e8
  style E2 fill:#fff4e8
  style E3 fill:#fff4e8
  style V3 fill:#fff4e8
```

| Block | Status / evidence | Where |
|-------|-------------------|-------|
| e11 free field | δ_dig ≤ 1 dB | E11_FREEFIELD; `e11_delta_dig.md` |
| Fill 160 points | V-ASSUMED GEXT | `grid_extension.jl` |
| Code check | Grid formulas | UT_GRID |
| GEXT bound | Variants flip T1 → not claimable | GEXT_BOUND; phase 32 |
| Shared cabin | Untuned CR-3813 chain | Diagram 4 |
| Tonal T1 | Calibrated / GEXT-bound | T1; REPRO_18b; E18_TONES |
| Broadband T2 | Surrogate + Eq. 19 | T2; T2_EQ19; E21_E22_NR; E15 |
| Band diagnostic | E-7 bands | (diagnostic) |
| Fig E-12 | 29/31 within 3.41 dB | E12_BLOCK; `e12_blocking.md` |

## 3. Aircraft validation

Purpose: free-field source vs BBN, Report 996, Pereira. Cabin result is extrapolation.

```mermaid
flowchart LR
  IN["XFOIL polars"]

  subgraph FWD["Aircraft BEMT+F1A"]
    direction TB
    A1["aircraft.json"]
    A2["CCBlade BEMT"]
    A3["F1A free-field p"]
    A1 -->|geo| A2
    A2 -->|L, D| A3
  end

  subgraph CHK["Checks"]
    direction TB
    C1["BBN phase"]
    C2["Report 996"]
    C3["Pereira"]
    C4["Unit tests"]
  end

  CAB["Shared cabin"]
  APP["dB(A), SIL"]
  ST["Source status"]

  IN -.-> A1
  A3 --> CAB
  A3 -.-> C1 & C2 & C3 & C4
  CAB --> APP
  C1 & C2 & C3 -.-> ST
  ST -.-> APP

  style C1 fill:#ffe8e8
  style C2 fill:#fff4e8
  style C3 fill:#fff4e8
  style C4 fill:#e8ffe8
  style ST fill:#ffe8e8
  style APP fill:#f3e5f5
```

| Block | Status / evidence | Where |
|-------|-------------------|-------|
| Polars | Viterna fixed pre-comparison; truncated entries regenerated 2026-10-22; display of curves + measured overlay + coverage (`POLAR_R996` panel 4: one colour per α) | UT_POLAR, POLAR_R996, POLAR_PER |
| CCBlade BEMT | T, Q / C_T, C_P | R996_LOADS, PER_LOADS |
| F1A free-field p | Shared `evaluate_propeller_source` | `propeller_ccblade.jl` |
| BBN phase | Common time base; I-19 pair φ_b−φ_a (post-hoc) | BBN_KIN, BBN_CIRC, BBN_LONG |
| Report 996 | Amplitude matrix; A_rms convention | R996_FIG*; F1A_GUTIN |
| Pereira | Forward flight | PER_FIG6–9 |
| Unit tests | V-CODE | F1A_GUTIN, BBN_KIN |
| Shared cabin / dB(A) | X-EXTRAP | A_CABIN; Run tab |
| Open author | I-17 amplitude | `VALIDATION_GUIDELINE.md` |
| Aircraft cabin guard / tags | 29b/29c done 2026-10-22 | `aircraft_provenance.jl`; §2.10 guard column |
| Parametric cabin blocks | 30a–30d done 2026-10-22 | `cabin_blocks=:parametric` (aircraft default); App. D + Eq.19; `parametric_regression.md` |
| Uncertainty (epistemic band) | 31a–31f done 2026-10-22 | `UNC_COVER` `:not_met` (H2/H3); aircraft H1–H3 band; after I-19 k≈0.09, phase (i) does not dominate; not a CI |

## 4. Shared cabin model

Both paths feed the same blocks (IN → FUNC → OUT → VERIFY).

```mermaid
flowchart LR
  GRID["Free-field grid"]

  subgraph BLK["Blocking Eq. 43"]
    direction TB
    B_IN["Free-field + γ"]
    B_FUNC["F(γ)"]
    B_OUT["Blocked pressures"]
    B_VAL["p.68 check"]
    B_VAL2["Fig E-12"]
    B_IN --> B_FUNC --> B_OUT
    B_OUT -.-> B_VAL
    B_OUT -.-> B_VAL2
  end

  subgraph MRP["Structural modes"]
    direction TB
    M_IN["Geometry, materials"]
    M_FUNC["Ritz / App. D"]
    M_OUT["f_r, ψ_r"]
    M_VAL["Table D-1"]
    M_IN --> M_FUNC --> M_OUT
    M_OUT -.-> M_VAL
  end

  subgraph CYL["CYL2D"]
    direction TB
    C_IN["θ0, L_c, a"]
    C_FUNC["App. C"]
    C_OUT["ω_n, Φ_G"]
    C_VAL["Table C-1"]
    C_IN --> C_FUNC --> C_OUT
    C_OUT -.-> C_VAL
  end

  subgraph PAIN["PAIN main"]
    direction TB
    P_IN["Modes + blocked + trim"]
    F2["Coupling f′"]
    F3["Ψ_G"]
    F4["Trim"]
    F5["Loss factors"]
    F6["Tone pressure Eq. 8"]
    F7["HF broadband"]
    P_OUT["Interior SPL"]
    P_IN --> F2 --> F3 --> F6
    P_IN --> F4 --> F5 --> F6
    F5 --> F7
    F6 --> P_OUT
    F7 --> P_OUT
  end

  GRID --> B_IN
  B_OUT --> P_IN
  M_OUT --> P_IN
  C_OUT --> P_IN

  style F2 fill:#fff4e8
  style F3 fill:#fff4e8
  style F4 fill:#dbe9ff
  style F5 fill:#dbe9ff
  style F6 fill:#fff4e8
  style F7 fill:#fff4e8
  style B_VAL fill:#e8ffe8
  style B_VAL2 fill:#fff4e8
  style C_VAL fill:#fff4e8
  style M_VAL fill:#fff4e8
  style GRID fill:#ffe8e8
```

| Block | Status / evidence | Where |
|-------|-------------------|-------|
| Free-field grid | Upper quarter; ℓ = 1 at φ_p | UT_GRID; 12b |
| Blocking F(γ) | ≤ 0.06 dB on p.68 | BLK_P68 |
| Fig E-12 | 29/31; 2 H3 aft fail | E12_BLOCK |
| Structural modes | App. D 2/32 by shape (floor stiffener model undocumented); D-1 seed and calibrated Ritz off the map | MRP_APPD |
| CYL2D | Ratios / Φ_G / symmetry | CYL2D_C1 |
| Trim / loss | App. A; E-14 / E-15 | UT_TRIM, E14_LOSS, E15_STRUCT_LOSS |
| Coupling / Ψ_G / Eq. 8 | Default tone path | UT_EQ8; 17a–17f |
| HF broadband | Surrogate default; Eq. 19 | 38b–38c; T2_EQ19 |
| SRC_TA amplitude | I-17 open (√2) | `VALIDATION_GUIDELINE.md` §2.1 |

## 5. Validation maps

GUI tab **Validation map** shows one map `total` (`src/validation_map.jl`), laid out from §2.13 `Position` / `Feeds` / `Group` / `Role`. Stage frames bound each group's own blocks only (positions chosen so frames are pairwise disjoint; aircraft checks above/below the pipeline). Row heights follow the tallest block in each row, so chips never cover the block below (2026-10-28). Titles only on boxes; case chips keep verdict dots and a short display-only error line plus source date (`case_error_summary`: `k/n · X U max` / `no verdict · X U max`; paren units; `:none` coverage text when met/not_met). Horizontal + vertical scroll; zoom / fit.

```mermaid
flowchart LR
  subgraph G_AIR["Aircraft BEMT+F1A"]
    direction LR
    A_GEO["Aircraft inputs"] --> A_LOADS["CCBlade BEMT"] --> X_F1A["F1A source"] --> X_FF["Free field p"]
  end
  subgraph G_FF["Free field"]
    P_FF["e11 free field"] --> X_SRC["Source select"]
    X_FF --> X_SRC
  end
  subgraph G_GRID["Grid and blocking"]
    X_SRC --> P_GRID["160-point grid"] --> P_BLK["Blocking Eq. 43"] --> X_BLK_OUT["Blocked pressures"]
  end
  subgraph G_MRP["Structural modes"]
    X_MRP_IN["Structure inputs"] --> P_MRP["Structural modes"] --> X_MRP_OUT["Modes f_r, ψ_r"]
  end
  subgraph G_CYL["CYL2D"]
    X_CYL_IN["Cabin geometry"] --> P_CYL["CYL2D"] --> X_CYL_OUT["Modes Φ_G"]
  end
  subgraph G_TRIM["Trim and loss"]
    X_TRIM_IN["Trim stack"] --> P_TRIM["Trim and loss"] --> X_TRIM_OUT["τ, η"]
  end
  subgraph G_PAIN["PAIN main"]
    X_PAIN_IN["Cabin inputs"] --> P_EQ8["Coupling / Eq. 8"] --> X_OUT["Interior SPL"]
  end
  subgraph G_VAL["Validation comparisons"]
    P_REPRO["vs NASA PAIN"]
    P_MEAS["vs measurement"]
    A_CABIN["Aircraft cabin"]
  end
  X_BLK_OUT --> X_PAIN_IN
  X_MRP_OUT --> X_PAIN_IN
  X_CYL_OUT --> X_PAIN_IN
  X_TRIM_OUT --> X_PAIN_IN
  X_FF -.-> A_AMP & A_PHASE & A_FWD & A_SURF
  X_OUT -.-> P_REPRO & P_MEAS & A_CABIN
```

| Block | Status / evidence | Where |
|-------|-------------------|-------|
| All P_* / A_* cases | Unchanged ids, verdicts, criteria | `VALIDATION_GUIDELINE.md` §2.13 |
| New X_* connectors | Layout only; no cases | Map `total` |
| UT_GRID figure | Sample-index error panel | `docs/validation_reports/figures/Grid_160_point/UT_GRID.png` |
| Screenshot | Offscreen smoke, zoom 1, left + right | `VALIDATION_MAP_TOTAL.png`, `VALIDATION_MAP_TOTAL_right.png` |
