# CR-3813 / User Manual completeness audit (2026-10-21)

Question (author): does PAIN.jl do everything the PAIN Methodology (CR-3813) and the User Manual (CR-172425) describe?
An earlier audit only checked that implemented equations match CR-3813; it could not see missing parts, which is how §3.3 Noise
Reduction was missed. This audit walks the documents and maps each part to the code. Sources read: CR-3813 table of contents and
list of figures, §3.2 pp. 16–20 and §3.3 pp. 21–23 (page images), App. E p. E-30; User Manual §5.4 (PAIN input cards 1–38) and
§5.4.3 (printed output); CR-172428 §3 (program description). Code: `PAIN.jl/src`.

Status: IMPLEMENTED · PARTIAL · SURROGATE (different or fitted form) · MISSING · NOT NEEDED.

## 1. CR-3813 sections and equations

| CR-3813 | Content | Status | Code / note |
|---|---|---|---|
| §3.1 Eqs. (1)–(7) | General solution, power flow | IMPLEMENTED | `pain_core.jl` (Eq. 8 derived and checked in 19a) |
| §3.2 Eqs. (8)–(10) | Tone transmission, modal sum, Ψ_G | IMPLEMENTED | `tone_mean_square_pressure`, `generalized_force` |
| §3.2 "High Frequencies" Eqs. (11)–(16) | **Tone expected value at high modal density**: band-averaged loss factors, E[g_n] = πω_H/(2η̄_nΔω), modal densities n_n, n_r, ⟨ε_n f′²⟩, j²_rev(ω_H) | **MISSING** | Code uses Eq. (8) for every tone; User Manual output 9(2) prints both formulations for all harmonics; card 10 sets the crossover band (program estimates it if 0) |
| §3.3 Eq. (17) | Reverberant-field modal inflow (band-integrated, arctan terms) | **MISSING** | — |
| §3.3 Eq. (18) | **Noise reduction** ⟨p_i²⟩/⟨p_e²⟩ for a reverberant exterior field | **MISSING** | E-19…E-24 untestable |
| §3.3 blocked ↔ diffuse | ⟨p_bl²⟩ related to ⟨p_e²⟩ (reverberant field) | **MISSING** | — |
| §3.3 "High Frequencies" Eq. (19)–(23) | High-frequency inflow with trim (A_t, S, A′), τ_t, resonant transmission, radiation loss factors | **SURROGATE** | `broadband_cabin_p2`: assumed α(f), asymptotic modal density, χ factor, `bb_j2_scale` = 0.5 (fitted earlier), Spbl ∝ f^-α — not Eq. (19) as printed |
| §3.4 Eqs. (24)–(43) | ANOPP input, Ψ_G Eq. (42), reflecting surface Eq. (43) | IMPLEMENTED / **PARTIAL** | Lower-quarter grid: CR-172428 §3 "PAIN then generates data for an identical grid on the lower quarter surface of the fuselage nearest the propeller (using the data input for the upper grid)"; User Manual output 7 "both above and below". Code uses the 160 upper-quarter points only (decision 19d, which did not cite CR-172428). **Reopen** |
| §3.5 Eqs. (44)–(57) | Coupling f′(n, r) | IMPLEMENTED | `coupling_factor` |
| §3.6 Eqs. (58)–(73) | Joint acceptances (incl. reverberant j²_rev per structural mode) | PARTIAL | Ring/axial joint acceptances implemented (16b); **j²_rev per structural mode** (Manual output 1, needed by Eqs. 15–18) only as a band-average surrogate in `pain_core.jl` |
| §3.7 | Resonance frequencies | IMPLEMENTED | CYL2D, Table D-1 |
| §3.8 Eqs. (74)–(83) | Loss factors, trim influence, closely coupled modes, average radiation loss factors | IMPLEMENTED | `trim_loss.jl`; per-band **input** override of structural and bare acoustic loss factors (Manual cards 11–18) **MISSING**; NASA's E-18/E-21 setting "total structural loss factor limited to 0.15" needs an η_r′ cap option — **MISSING** |
| App. A | Trim transmission, transfer matrix, absorption, vibration transmission | IMPLEMENTED | 16a |
| App. B | Propeller noise theory | NOT NEEDED | Replaced by F1A (aircraft) / measured E-11 (test article) |
| App. C | Cabin acoustic modes | IMPLEMENTED | `cyl2d.jl` |
| App. D | Structural model (MRP/MRPMOD): Eqs. (D.17)–(D.26) | **SURROGATE** | Production uses Table D-1 (test article only). The raw solver is a w-only Donnell surrogate with three scales fitted to Table D-1, not Eq. (D.25). **Any geometry other than the test article (the aircraft) has no valid structural modes** |
| App. E | Validation studies | see §3 | — |

## 2. User Manual program capabilities (§5.4 cards, §5.4.3 output)

| Manual item | Status | Note |
|---|---|---|
| Card 2: separate exterior / interior air density and sound speed | **MISSING** | single ρ0, c0 (same air in the test; matters for altitude/aircraft) |
| Card 3–6: user-chosen 1/3-octave band set (≤ 26 bands) | PARTIAL | fixed band list |
| Card 7: L, a, θ0 | IMPLEMENTED | Poisson ratio for end caps unused — the Manual says end-cap transmission is not in the program either |
| Card 9: **cavity length L_c and offset d** (cavity ≠ structure) | **MISSING** | code assumes L_c = L, d = 0 (true for the test cylinder, not for an aircraft cabin) |
| Card 10: **high-frequency crossover band** (estimated if 0) | **MISSING** | with §3.2/§3.3 high-frequency formulations |
| Cards 11–18: per-band structural and bare acoustic loss factors (acoustic computed from trim if 0) | PARTIAL | formulas implemented; per-band input override missing |
| Cards 19–33: trim (sidewall, end caps, per-band insulation properties) | IMPLEMENTED | App. A, Fig. A-2 table |
| Card 36: propeller location, B, rpm, **rotation direction ±1** | PARTIAL | rotation sense not an input (matters with the lower-quarter grid) |
| Cards 37–38: H_max ≤ 10, k_max ≤ 16, k_p, amplitude/phase per point | IMPLEMENTED | amplitude convention fixed in F4 (I-17) |
| Output 1: band-averaged loss factors, trim τ (dB), admittances, **number of structural and acoustic modes per band**, per-mode tables incl. **j²_rev** | PARTIAL | values exist internally; no output tables; j²_rev missing |
| Output 6: coupling factors per (n, r) | PARTIAL | computed, not reported |
| Output 7: propeller pressures (dB) and phases, **both quarters** | PARTIAL | upper quarter only |
| Output 8: generalized forces Ψ_G(r, H) | PARTIAL | computed, not reported |
| Output 9: tone transmission: (1) low-frequency formulation with the **5 largest modal contributions** and η_r″, (2) **low- and high-frequency formulations** for all harmonics, (3) summary | PARTIAL | (1) only in a diagnostic script; (2) high-frequency formulation missing |

## 3. App. E figures

| Figure | What | Case / status |
|---|---|---|
| E-7, E-8 | measured spectra | data only (no prediction to compare) |
| E-9, E-10 | interior 1/3-octave | T2 (Eq. 19 surrogate) |
| E-11 | free field | E11_FREEFIELD |
| E-12 | blocked levels | E12_BLOCK |
| E-13 | absorption (measured only) | diagnostic, no pass mark |
| E-14 | acoustic loss factors | E14_LOSS |
| E-15 | structural loss factors | **no case** (data `e15_structural_loss_targets.csv` exists) |
| E-16, E-17 | interior tones | T1, REPRO_18b |
| E-18 | tones with η_T = 1.0, η_r′ ≤ 0.15 | **no case** (data `e18_interior_pred_eta1.csv` exists; needs the η_r′ cap) |
| E-19, E-20 | measured NR at two stations | measured only |
| E-21, E-22 | **space-average NR, measured vs predicted** | **MISSING** (needs §3.3) |
| E-23, E-24, E-25 | NR / loss factors with end-plate batts | **MISSING** (needs §3.3; data not digitized; end-plate method of ref. [7] not in the repository) |

## 4. Prioritized list

1. **§3.3 Noise reduction (Eqs. 17–18, blocked↔diffuse, j²_rev per structural mode)** → E-21/E-22 (criteria frozen 2026-10-21), later E-24. NASA settings (p. E-30): η_T = 1.0, η_r′ ≤ 0.15, end-plate allowance per ref. [7] for 80–160 Hz (ref. [7] not available: implement without it, flag those bands V-ASSUMED).
2. **§3.2 high-frequency tone formulation (Eqs. 11–16) and the crossover (card 10)** → reported alongside Eq. (8) as the Manual does. Hypothesis to test (criterion fixed before running): NASA's H3 (630 Hz band) may have used it; this is a candidate for the open H3 miss of REPRO_18b.
3. **Lower-quarter grid (CR-172428 §3)** → reopen 19d with the new citation; author decision. Mirroring about the ℓ = 1 line changed 18b by +0.73, +3.18, +6.81 dB in the 19d diagnostic (result known → post-hoc if adopted).
4. **§3.3 high-frequency model Eq. (19)–(23) as printed** → replaces the surrogate (and the stale `bb_j2_scale`); T2.
5. **η_r′ cap option and per-band loss-factor inputs** (cards 11–18) → E-18 case; E-15 case.
6. **Cavity length L_c, offset d; exterior/interior ρ, c; rotation direction input** → aircraft use.
7. **App. D structural solver (Eqs. D.17–D.26)** → needed for any non-test geometry (the aircraft); large.
8. **Printed outputs** (mode counts per band, coupling and Ψ_G tables, 5 largest contributions, both-quarter pressures) → a report/GUI page.
