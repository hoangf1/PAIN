# PAIN recreation flowcharts

The user source is BEMT + F1A, which gives the free-field pressure at the 160 fuselage grid points. NASA's measured data are a validation test of the cabin model only, not a user option. The cabin stages are the same for both.

| Diagram | What it shows |
|---------|---------------|
| [1. Overview](#1-overview) | The user source (BEMT + F1A), the NASA validation test, and the shared cabin model |
| [2. NASA validation (e11)](#2-nasa-validation-e11) | NASA measured data -> grid extension -> cabin model -> tests T1/T2 |
| [3. Aircraft validation](#3-aircraft-validation) | CCBlade + F1A source, XFOIL polars, and the BBN/Wilby, Report 996 and Pereira checks |
| [4. Shared cabin model](#4-shared-cabin-model) | Blocking, structural modes, acoustic modes, PAIN core |
| [5. Validation maps](#5-validation-maps) | Map 1 cabin-chain cases; Map 2 aircraft-source cases (GUI "Validation map" tab) |

Grid extension (GEXT) appears only in diagram 2. It exists because the NASA paper measured one line of the grid.

Status key: green = check exists and passes as stated; orange = planned, not independently checked, or the current code differs from CR-3813; blue = calibrated surrogate. Step numbers refer to `IMPLEMENTATION_PLAN.md`. **2026-10-22:** phases **38d–38e** — `E18_TONES` 2/3 vs NASA E-18 (not met); `E15_STRUCT_LOSS` η_r′ V-EXP info (no_verdict). Phase **38c** printed HF broadband; `T2_EQ19` 0/3. **38h** Manual §5.4.3 printed outputs (`printed_outputs.jl` + GUI tab; no criterion). **38g** printed App. D solver `mrp_appd.jl` / case `MRP_APPD`: **27/32** within 5 % → met (criterion ≥75 % of 32, fixed 2026-10-22; `mrp_appd_vs_d1.md`). Phases 38a–38b remain. Phases 32–35 done. GUI Run tab = aircraft only; **Validation** + **Validation map** + **Printed outputs** tabs. `REPRO_18b` = 18b-r (not met); `MRP_D1` = transcription `no_verdict`. Aircraft path stays X-EXTRAP; 29b–31 deferred (B-4).

**Test tooling (P1, 2026-10-22, no behaviour change).** `Pkg.test` accepts `test_args` substrings to select top-level testsets; list/times in `PAIN.jl/test/README.md`. Optional DaemonMode loop in `PAIN.jl/scripts/devtools/` (separate env; Revise loaded). Does not alter criteria, reports, or `src/`.

**Directory layout (R1, 2026-10-22, moves only).** CR-3813 inputs under `data/cr3813/`; scripts under `PAIN.jl/scripts/{run,checks,digitize,setup,smoke}/` (`run_gui.jl` top-level). Path references updated; no change to criteria or recorded numeric results. See `data/README.md`, `PAIN.jl/scripts/README.md`.

**Grid azimuth (12b, done 2026-10-20).** The 160-point grid lies on the upper quarter of the fuselage with line ℓ = 1 at the propeller azimuth φ_p, θ_ℓ = φ_p + (ℓ−1)π/18 (User Manual p. 34 and Fig. 3), and γ is the angle between the surface→hub direction and the outward normal (γ = 0 at ℓ = 1, k = k_p). Before the fix the code put ℓ = 1 at the bottom centerline, so e11 results computed before 2026-10-20 used the wrong incidence angle and the wrong shell region and are void. Results in diagram 2 now come from the corrected grid but now use the untuned CR-3813 cabin chain (Eq. 8, App. A trim, §3.8 losses; 17a, 2026-10-20), regraded in 18a. Order of work: `IMPLEMENTATION_PLAN.md`, phases numbered in run order (12 grid fix, 13 pre-registration and 14 E-12 check, done; 15–18 cabin chain, 19–27 source checks, 28–30 aircraft cabin, 31 GEXT bound, 32 close-out).

## 1. Overview

```mermaid
flowchart LR
    V["<b>NASA validation test only (e11)</b><br/>not a user option<br/>NASA Fig E-11 measured line<br/>+ grid extension (GEXT)<br/>(diagram 2)"]
    A["<b>User source: BEMT + F1A</b><br/>CCBlade + AcousticAnalogies F1A<br/>at all 160 points<br/>(diagram 3)"]
    G["Free-field grid<br/>160 points<br/>amplitude + phase per harmonic"]
    S["<b>Shared cabin model</b><br/>blocking -> modes -> PAIN core<br/>(diagram 4)"]
    T["Tests T1 / T2<br/>vs NASA interior SPL"]
    M["dB(A), SIL<br/><i>extrapolated</i>"]
    GUI["GUI Validation + map + Printed outputs<br/>case registry / CASE_INFO<br/>§5.4.3 tables (38h)"]

    V --> G
    A --> G
    G --> S
    S --> T
    S --> M
    T --> GUI
    S --> GUI

    style V fill:#e8f4ff
    style A fill:#f3e5f5
    style T fill:#e8ffe8
    style M fill:#f3e5f5
    style GUI fill:#e8ffe8
```

## 2. NASA validation (e11)

Purpose: check the cabin model against NASA's published results. The source is NASA's measured free-field data, so no
CCBlade or F1A is involved.

```mermaid
flowchart LR
    S["PROVIDES the only measured free-field data<br/>Fig E-11, l=1, H=1,2,3<br/>digitization quality: delta_dig <= 1 dB"]

    subgraph EXT["Grid extension (this path only)"]
        direction TB
        E1["FILLS the grid: l=1 -> 160 points<br/>cosine falloff + geometric delay<br/>claim: none — V-ASSUMED,<br/>unfalsifiable by published data"]
        E2["VERIFIES the code<br/>not the physics — V-CODE only"]
        E3["BOUNDS the dependence on E1<br/>variants, cabin fixed; T1 flip test<br/>not a validation; does not measure circularity<br/><i>phase 32, runs after 18a (12b done)</i>"]
    end

    CAB["TRANSMITS grid -> interior SPL<br/>shared cabin (diagram 4)<br/>CR-3813 equations, no tuning (15a-17a done)<br/>grid azimuth fixed (12b)<br/>HF Eq.(19) printed + surrogate selector (38c)"]

    subgraph VAL["Validation: interior SPL"]
        direction TB
        V1["TESTS joint model vs tonal data<br/>E-16/17/18, H=1,2,3<br/>18a-r: 81.0, 75.0, 75.3 dB; no claim;<br/>GEXT bound (32): flips → T1 not claimable;<br/>REPRO_18b = 18b-r 82.73/75.73/77.05 (2 of 3);<br/>E18_TONES η_T=1.0 (38d): 2/3 not met;<br/>19i H3 not found"]
        V2["TESTS joint model vs broadband<br/>E-9, +/-3.5 dB (T2 surrogate + T2_EQ19);<br/>E-21/E-22 NR Eq.(18)/(19) (38a/38c);<br/>E-15 η_r′ (38e, info); HF tones (38b);<br/>printed Eq.(19)–(23) first run 38c"]
        V3["LOCALIZES a failure by band<br/>E-7, G1/G2/G3<br/>result: diagnostic, not validation"]
    end

    S --> E1
    E1 --> CAB
    E1 -.-> E2
    E1 -.-> E3
    CAB --> V1 & V2
    V1 -.->|fail| V3
    V2 -.->|fail| V3

    style S fill:#e8ffe8
    style CAB fill:#fff4e8
    style V1 fill:#fff4e8
    style V2 fill:#fff4e8
    style E2 fill:#fff4e8
    style E3 fill:#fff4e8
    style V3 fill:#fff4e8
```

Note: the Fig E-12 check (blocked pressure on the l=1 line) belongs to blocking; see diagram 4. 14a is done (2026-10-20): Eq. 43 reproduces NASA's predicted E-12 curve at 29 of 31 points within delta_dig + 0.5 dB, FAIL at 2 H3 points aft, recorded (`e12_blocking.md`).

## 3. Aircraft validation

Purpose: compute the free-field source for your own propeller and aircraft (CCBlade + F1A) and check it against
BBN/Wilby, NACA Report 996 and Pereira. No NASA cabin measurement is involved, so the cabin result is an extrapolation.

Order of the checks (decision 2026-10-16): BBN/Wilby first for phase; Report 996 for amplitude; Pereira second as the
forward-flight check. Pass criteria are written before any comparison; no tuning to delta 0. Fuselage scattering and
reflection stay V-ASSUMED.

```mermaid
flowchart LR
    IN["XFOIL polars<br/>Viterna fixed pre-comparison"]

    subgraph FWD["Forward model (no GEXT)"]
        direction TB
        A1["aircraft.json"]
        A2["CCBlade.jl BEMT -> L, D"]
        A3["F1A -> free-field p<br/>all 160 points"]
        A1 --> A2 --> A3
    end

    subgraph CHK["Checks (criteria fixed before comparing)"]
        direction TB
        C1["BBN/Wilby phase<br/>blocked: common time base<br/>+ 23a AUTHOR"]
        C2["Report 996 expanded matrix<br/>+ 25k asymmetry OK;<br/>verdict waits 23c AUTHOR"]
        C3["Pereira 3-polar matrix<br/>ScaledLoads H1 ~−2.3 dB;<br/>verdict waits 23d AUTHOR"]
        C4["Unit / code tests<br/>V-CODE (incl. 25j)"]
    end

    CAB["Shared cabin model"]
    APP["dB(A), SIL<br/>EXTRAPOLATED"]
    ST["Source: EXTRAPOLATED<br/>until C1-C3 pass<br/>longitudinal = X-EXTRAP"]

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

Code status (2026-10-21 phases 33–35): 21–28 and 32–35 done (29b–31 deferred); GUI source = aircraft only; Validation map tab live. GEXT remains e11-only (diagram 2). Open author item: I-17 amplitude convention.

**Blocked for author:** I-17 [AUTHOR] free-field amplitude (rms vs Fourier peak); 29b/29c [CONFIRM].

Design rule: the CCBlade -> F1A -> FFT step is one function, `evaluate_propeller_source`. The 160-point grid,
the Report 996 checks, and the Pereira check all call it with different observer lists; the Table-8 calibration is a separate
post-step and is never applied inside it. Nothing else may reimplement that step.

## 4. Shared cabin model

Both paths feed the same blocks.

```mermaid
flowchart LR
    GRID["Free-field grid<br/>160 points, upper quarter<br/>l=1 at propeller azimuth phi_p<br/>(User Manual Fig 3)<br/><i>code matches (12b done)</i>"]

    subgraph BLK["Blocking - Eq. 43"]
        direction TB
        B_IN["IN: free-field grid<br/>+ incidence angles<br/>+ R1 or R2"]
        B_FUNC["APPLY:<br/>F(gamma) = 10^[0.3 -<br/>0.000224 e^(0.08 gamma)]"]
        B_OUT["OUT: blocked pressures<br/>at 160 grid points"]
        B_VAL["VALIDATE:<br/>CR-172428 p.68<br/>within 0.06 dB"]
        B_VAL2["ON-LINE CHECK (e11 only):<br/>Fig E-12 blocked at l=1<br/><i>tests Eq.43 + R1/R2<br/>14a done 2026-10-20:<br/>29 of 31 points within 3.41 dB,<br/>2 H3 aft points fail (recorded)</i>"]
        B_IN --> B_FUNC --> B_OUT --> B_VAL
        B_OUT --> B_VAL2
    end

    subgraph MRP["Structural Modes<br/>(MRP + MRPMOD merged)"]
        direction TB
        M_IN["IN: E, nu, rho, t_eq<br/>m_s, m_p, EI/d, EI/l<br/>constraints"]
        M_FUNC["REIMPL:<br/>Rayleigh-Ritz with<br/>Fourier shapes<br/>-> sort, truncate, M_r"]
        M_OUT["OUT: f_r, M_r, C_Mn<br/>psi_r by Eqs 46-49"]
        M_VAL["VERIFY (code-to-code):<br/>MRP_D1 transcription no_verdict<br/><i>production copies D-1 (by construction);<br/>raw Ritz MRP_RITZ: live 26/32 within 5%<br/>(report 30/32 stale; calibrated);<br/>App. D MRP_APPD (38g): no fitted scale;<br/>≥75% of 32 within 5% (fixed 2026-10-22);<br/>shape/mass comparison 17d;<br/>Fig. D-2 shape check 19g</i>"]
        M_IN --> M_FUNC --> M_OUT --> M_VAL
    end

    subgraph CYL["CYL2D"]
        direction TB
        C_IN["IN: floor angle theta0<br/>cavity length L_c (card 9), radius"]
        C_FUNC["REIMPL (15a, done):<br/>App C half grid, NY = 10, Eqs C.1-C.6,<br/>node rule r &lt;= 1 + 0.4h,<br/>two tangential-gradient equations"]
        C_OUT["OUT: omega_n (C.7, q and i),<br/>boundary phi_i (Eq 51),<br/>Phi_G (C.10), eps_n (C.11)"]
        C_VAL["VERIFY (code-to-code), ratio form 2026-10-21:<br/>f_i/f_1 within 0.1% (c0-free; post-hoc);<br/>Phi_G / symmetry / Fig C-3 unchanged<br/><i>worst ratio 0.0003%; TABLE_C1_C0=341<br/>was back-solved from the table</i>"]
        C_IN --> C_FUNC --> C_OUT --> C_VAL
    end

    subgraph PAIN["PAIN Main - reimplemented"]
        direction TB
        P_IN["IN: structural modes<br/>acoustic modes<br/>blocked pressures<br/>trim stack (App A), C (Eq 80),<br/>eta_n if bare; ρ_ext/ρ_int, c_ext/c_int (card 2);<br/>L_c, d (card 9); bands ≤26 (cards 3–6);<br/>η_r/η_n per band (cards 11–18); rotation ±1 (card 36); assumptions 13a"]
        subgraph FUNC["internal functions"]
            direction TB
            F2["coupling f'(n,r), Eq 52<br/>(Eqs 46-49, 53-57; axial overlap L_c,d)<br/><i>implemented, tests pass (17f); 38f-1 L≠L_c;<br/>boundary values from 15a (done)</i>"]
            F3["generalized force<br/>Psi_G, Eq 42 (Delta^4/2)<br/><i>Delta^4/2 implemented (17a, done);<br/>analytic limits tested (17e, done)</i>"]
            F4["trim, App A<br/>Eqs A.6-A.22, Fig A-2<br/><i>written (16a, done): trim_loss.jl;<br/>in the pipeline since 17a</i>"]
            F5["loss factors<br/>Eqs 77, 79-83, j_r rev Eqs 63-73<br/><i>written (16b, done); E-14 reproduction 7/18 bands;<br/>in the pipeline since 17a</i>"]
            F6["tone pressure<br/>Eq 8 + HF Eqs 15–16 (38b)<br/><i>Eq. 8 default (tone_model=:eq8); :auto at crossover;<br/>η_r_cap on tone path (38a/38d); 18b-r / E18_TONES not met;<br/>38b :auto H3 72.31 (Δ=+4.31) — I-18 not explained<br/>(phase38b_high_freq_tones.md; e18_tones_eta1.md)</i>"]
            F7["HF broadband<br/>Eqs 19–23 (38c) + surrogate<br/><i>broadband_model=:surrogate default;<br/>:eq19 = printed τ_f, τ_R, ᾱ;<br/>T2_EQ19 first run 0/3 vs E-9<br/>(phase38c_hf_broadband.md)</i>"]
        end
        P_OUT["OUT: interior SPL<br/>per harmonic<br/>+ 1/3-octave spectrum"]
        P_IN --> F2 --> F3 --> F6
        P_IN --> F4 --> F5 --> F6
        F5 --> F7
        F6 --> P_OUT
        F7 --> P_OUT
    end

    GRID --> B_IN
    B_VAL --> P_IN
    C_VAL --> P_IN
    M_VAL --> P_IN

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

**SRC_TA note (I-17, open 2026-10-21):** free-field SPL→Pa for the e11 / Table-8 path may omit the Fourier-peak √2 relative to CR-3813 / User Manual amplitude A. Author decision pending; see `VALIDATION_GUIDELINE.md` §2.1.

## 5. Validation maps

GUI tab **"Validation map"** (`src/validation_map.jl`). Cases are read-only; page images are display-only; numbers come from CSVs or transcribed tables.

### Map 1 — PAIN verification (CR-3813 cabin chain)

Verifies the cabin chain against its own printed equations, tables and NASA PAIN output, then in-sample against measurement. Does **not** cover the aircraft source.

```mermaid
flowchart TB
    P_FF["P_FF Free field SRC_TA<br/>E11_FREEFIELD · input_qa"]
    P_GRID["P_GRID Grid + GEXT<br/>UT_GRID · verification<br/>GEXT_BOUND · calibrated"]
    P_BLK["P_BLK Blocking Eq.43<br/>BLK_P68 · verification<br/>E12_BLOCK · verification"]
    P_MRP["P_MRP Structural modes<br/>MRP_D1 · input_qa no_verdict<br/>MRP_RITZ · calibrated<br/>MRP_APPD · App. D (38g)"]
    P_CYL["P_CYL Cabin modes<br/>CYL2D_C1 · verification"]
    P_TRIM["P_TRIM Trim / loss<br/>UT_TRIM · verification<br/>E14_LOSS · verification<br/>E15_STRUCT_LOSS · experiment info"]
    P_EQ8["P_EQ8 Coupling / Eq.8<br/>UT_EQ8 · verification"]
    P_REPRO["P_REPRO vs NASA PAIN<br/>REPRO_18b · calibrated<br/>E18_TONES · verification (38d)"]
    P_MEAS["P_MEAS vs measurement<br/>T1 · T2 · calibrated<br/>E21_E22_NR · Eq.(18) 38a"]

    P_FF --> P_GRID --> P_BLK --> P_MRP --> P_CYL --> P_TRIM --> P_EQ8 --> P_REPRO --> P_MEAS
```

### Map 2 — Aircraft source (CCBlade BEMT + F1A)

Verifies the aircraft free-field source against experiments it was not tuned to. Report 996 = static near-field amplitude; BBN = phase on a fuselage; Pereira = forward flight far field. Aircraft cabin SPL stays **X-EXTRAP**. Does **not** claim a validated aircraft cabin.

```mermaid
flowchart TB
    A_GEO["A_GEO Geometry / polars<br/>UT_POLAR · verification"]
    A_LOADS["A_LOADS BEMT loads<br/>R996_LOADS · experiment<br/>PER_LOADS · experiment"]
    A_AMP["A_AMP F1A amplitude static NF<br/>F1A_GUTIN · verification<br/>R996_FIG14/12/13A · experiment<br/>R996_FIG6/7/8"]
    A_PHASE["A_PHASE F1A phase<br/>BBN_KIN · verification<br/>BBN_CIRC · experiment<br/>BBN_LONG · extrap<br/>R996_PHASE · experiment"]
    A_FWD["A_FWD Forward flight FF<br/>PER_FIG6–9 · experiment"]
    A_SURF["A_SURF Fuselage surface levels<br/>BBN_LEVELS · extrap"]
    A_CABIN["A_CABIN → Map 1 cabin<br/>aircraft cabin = X-EXTRAP"]

    A_GEO --> A_LOADS --> A_AMP --> A_PHASE --> A_FWD --> A_SURF --> A_CABIN
```
