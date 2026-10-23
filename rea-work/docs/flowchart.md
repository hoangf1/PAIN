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

- **2026-10-23:** Phases 50–58 closed (`NR_PROP_TP2444_PF` on P_MEAS; `sparse_guard`, Ritz `include_floor`/`include_stiffeners` options; Q22 closed). Phase 48 (P_FF / P_MEAS): `BPM_RP1218` met; `PROP_BB_FIG14`, `PROP_BB_FIG17`, `T2_PRED_BB` not met. Phase 49 (P_EQ8 / trim): Eq. (20) sums the modes below the band, as printed; no in-theory input correction for T2's high-frequency gap (NASA: the trim model is valid to about 1 kHz). Phase 47 (P_MEAS): `NR_PROP_TP2444` not met 1/7, `T2_MEAS_EXT` not met (21.3 vs 51.0 dB). The measured TP-2444 exterior through T2's cabin path shows that PAIN's high-frequency noise reduction is 15–27 dB too high for the trimmed article; NASA's own E-21/E-22 predictions show the same. Phase 46: isolated checks for the last untested T1/T2 functions (37/37). Phase 45 `NR_TP1964_XOVER` (T2's Eq. 19 path on TP-1964; P_MEAS). Phase 44f: Eq. (52) floor-term sign of NASA's corrected program (P_EQ8 coupling); T1_F1A_FILL met post-hoc. Phase 42 `LOUDEST_PT` (output stage: loudest-point dB(A) next to the space average). Phase 44 CR-172428 reproduction (`R172428_CODE`, `R172428_EXP`, `R172428_ETA`, `R172428_TRIM`, `R172428_PAIRS`): NASA's printed App. B field and Table 6 inputs through the cabin chain; App. A η_r′ option; Eq. (83) now uses the bare f′. Phase 43 T1/T2 root causes (`T1_MEAS_DAMPING`, `H3_ATTRIB`, `NR_TP1964` / `_REF2`, `T1_F1A_FILL`, `T1_F1A_MEAS_DAMP`); card-10 volume crossover default; bare-cylinder module `circular_cavity.jl`. Phase 41 isolation chips (`T1_FROM_E12`, `TRIM_CLOSED`, `NR_BAND_HAND`, `HF_MASSLAW`, `BEMT_HAND`, `F1A_INDEP`); five met, `T1_FROM_E12` not met (cabin chain). Phase 40 `ISO_*` all met except 40f. See `VALIDATION_GUIDELINE.md` §2.13.
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
| Structural modes | D-1 seed; Ritz calibrated; App. D 27/32 | MRP_D1, MRP_RITZ, MRP_APPD |
| CYL2D | Ratios / Φ_G / symmetry | CYL2D_C1 |
| Trim / loss | App. A; E-14 / E-15 | UT_TRIM, E14_LOSS, E15_STRUCT_LOSS |
| Coupling / Ψ_G / Eq. 8 | Default tone path | UT_EQ8; 17a–17f |
| HF broadband | Surrogate default; Eq. 19 | 38b–38c; T2_EQ19 |
| SRC_TA amplitude | I-17 open (√2) | `VALIDATION_GUIDELINE.md` §2.1 |

## 5. Validation maps

GUI tab **Validation map** shows one map `total` (`src/validation_map.jl`), laid out from §2.13 `Position` / `Feeds` / `Group` / `Role`. Stage frames bound each group's own blocks only (positions chosen so frames are pairwise disjoint; aircraft checks above/below the pipeline). Titles only on boxes; case chips keep verdict dots and a short display-only error line plus source date (`case_error_summary`: `k/n · X U max` / `no verdict · X U max`; paren units; `:none` coverage text when met/not_met). Horizontal + vertical scroll; zoom / fit.

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
| UT_GRID figure | Sample-index error panel | `docs/validation_reports/figures/UT_GRID.png` |
| Screenshot | Offscreen smoke, zoom 1, left + right | `VALIDATION_MAP_TOTAL.png`, `VALIDATION_MAP_TOTAL_right.png` |
