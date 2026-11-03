# Low-Fidelity Turboprop Cabin Noise Tool — Implementation Plan

A PySide6 desktop tool that estimates propeller-aircraft cabin SPL / dBA from mission, propeller and fuselage geometry, sidewall layers, insulation, trim and cabin absorption — without airfoil polars, structural/acoustic mode coupling, phase-resolved pressure grids or CFD. A fast companion to the PAIN recreation: low-fi for design sweeps, PAIN for detailed low-frequency checks.

**Design principle: no fitted parameters.** Every quantity is computed from physics, statistics or a stated input. Flight/lab data are used only for *blind* validation, so the reported error band is a real uncertainty that carries to a new aircraft.

---

## 1. Reference basis

Only three references are required. All other equations are written out in Appendix A.

| Role | Document | Link |
|---|---|---|
| Method (sidewall TL → noise reduction → interior level) | Wilby & Scharton, NASA CR-132602 | https://ntrs.nasa.gov/api/citations/19750010899/downloads/19750010899.pdf |
| Real-turboprop validation (lab TL + absorption → in-flight IL) | Mixson, O'Neal & Grosveld, NASA TM-85722 (1984) | https://ntrs.nasa.gov/citations/19840008879 |
| Exterior + cabin flight data (blind source and cabin validation) | Wilby, McDaniel & Wilby, NASA CR-178004 | https://ntrs.nasa.gov/api/citations/19860010618/downloads/19860010618.pdf |

> Before coding Stage 2/4, cross-check symbols against CR-132602 directly.

---

## 2. Calculation pipeline (what goes in, what comes out)

```
Mission + geometry ─► [1] Exterior source   ─► p_inc (tones, per patch), Φ_wall (TBL bands)
Sidewall stack     ─► [2] Sidewall TL       ─► τ(f, θ), TL_d(f)
Cabin surfaces     ─► [3] Cabin absorption  ─► A(f), T60(f)
                      [4] Interior level    ─► L_int(f) average; L(x) per seat; max seat
                      [5] Weighting/totals  ─► OASPL, dBA, dBC (tonal / broadband / total)
                      [6] Insertion loss    ─► IL(f)  (config A vs B)
```

**Two parallel tracks through every stage**

| Stage | Tonal (prop harmonics) | Broadband (TBL) |
|---|---|---|
| Frequencies | discrete `f_m = m·B·RPM/60`, m = 1…N | 1/3-octave centers 50 Hz – 5 kHz |
| Source | rotating point forces → free-field **incident** pressure at patch(es) | Goody wall-pressure spectrum (algebraic, no grid) |
| Transmission | τ(f_m, θᵢ) at each patch's incidence angle | diffuse-field TL, band-averaged |
| Area | prop-plane patch area(s) | full sidewall |
| Interior | transmitted power → room equation | transmitted power → room equation |
| Max seat | statistics above f_s; box-mode shape below f_s | statistics |

Combined per band, then weighted and summed. Both tracks are kept as separate outputs.

### Stage 1 — Exterior source (generated from mission + geometry)
- **Mission inputs (per segment):** altitude, Mach, RPM, shaft power, propeller efficiency η_p (or thrust directly).
- **Geometry inputs:** tip radius R_t, blade count B, tip clearance h_c, prop axial station, engine count, synchrophase angle Δφ.
- **Tones:** each blade = one point force (thrust + torque components) rotating at R_e = 0.8·R_t. Pressure at the fuselage computed in the time domain (retarded time, forward flight included), then FFT → harmonics. Captures near field and flight effects with no fitting. Must reproduce Gutin in the static far field (unit test V0a).
- **Incident vs surface pressure:** the source gives free-field **incident** pressure. No +6 dB is applied — the transfer matrix already contains the skin reflection.
- **Far-side propeller (twins):** shadowing by the fuselage from the rigid-cylinder scattering solution (A.3).
- **Twin combination:** coherent sum with synchrophase angle Δφ; report both energetic average and worst-case coherent level.
- **Boundary-layer refraction (cruise):** no closed form → required visible input K_refr (0–5 dB) with a sensitivity band on plots. Not fitted.
- **Patches:** default **1 patch** (nearest fuselage point in the prop plane) with user area S_p; optional **5-patch** sensitivity check (magnitudes + angles only, no phase). If 1 vs 5 patches differ by < 1 dB in dBA, 1 patch is adequate.
- **TBL:** Goody model from flight condition — one algebraic evaluation per band.
- **Override:** measured exterior levels via CSV (for validation runs only).

### Stage 2 — Sidewall TL (transfer matrix)
Layered skin / gap / blanket / gap / trim; Delany–Bazley blanket; plane-wave τ(f, θ); diffuse average; band averaging; composite with windows/doors (A.4).

### Stage 3 — Cabin absorption
`A(f) = Σ Sᵢαᵢ(f)`, `T60 = 0.161·V/A`; surface library (seats, carpet, trim, headliner).

### Stage 4 — Interior level (power bookkeeping, no correction factor)
- Tones: transmitted power from each patch, `p_int² = 4ρ₀c₀W_t/A`.
- TBL: wall pressure treated as blocked pressure of an equivalent diffuse field (−6 dB) → diffuse TL. **Conservative (upper bound)**, labeled in GUI.
- Max seat: above Schroeder frequency f_s → diffuse-field statistics (+4.8 dB for 95th percentile); below f_s → rigid-box cabin-mode spatial shape, energy from room equation (A.5).

### Stage 5 — Totals
A/C weighting, energetic sums, tonal / broadband / total outputs (A.6–A.7).

### Stage 6 — Insertion loss
`IL = L_int,bare − L_int,treated` from two saved configurations.

---

## 3. Software architecture

```
cabin_noise/
├── core/                    # pure NumPy/SciPy, no Qt imports — fully unit-testable
│   ├── frequencies.py       # 1/3-octave grid, harmonic list
│   ├── atmosphere.py        # ISA, viscosity
│   ├── mission.py           # segment dataclasses, active-segment selection
│   ├── materials.py         # dataclasses: Panel, PorousLayer, AirGap, Surface
│   ├── source_tonal.py      # rotating point forces, retarded time, FFT, Gutin check
│   ├── scattering.py        # rigid-cylinder surface factor, shadowing
│   ├── source_tbl.py        # Goody spectrum, BL thickness, wall shear
│   ├── porous.py            # Delany–Bazley
│   ├── tmm.py               # matrices, τ(θ), diffuse average, band average, composite
│   ├── cabin.py             # absorption, T60, room equation, patch power sum
│   ├── seats.py             # Schroeder split, statistics, box-mode spatial shape
│   ├── weighting.py         # A/C weighting, energetic sums
│   ├── pipeline.py          # run_case(config) -> Results
│   ├── validation.py        # blind case runner, metrics, pass/fail status
│   └── io.py                # JSON project files, CSV import/export
├── gui/
│   ├── main_window.py
│   ├── panels/              # input forms (see §4)
│   ├── plots.py             # pyqtgraph or matplotlib canvases
│   ├── validation_tab.py    # validation map, code-vs-reference figures, report export
│   ├── models.py            # Qt table models for layers/surfaces
│   └── worker.py            # QThread/QRunnable for sweeps
├── data/
│   ├── materials.json       # default skins, blankets (σ), trims, α tables
│   └── validation/          # digitized reference curves + cases.yaml
├── tests/
└── app.py
```

**Key design rules**
- `core` never imports Qt; GUI calls `pipeline.run_case()` only.
- One serializable config dataclass tree → JSON project files.
- SI internally; GUI handles unit display.
- Results carry every intermediate (p_inc per patch, Φ_wall, τ, TL, A, T60, L_int, seat map) for plotting/export.

**Dependencies:** Python ≥3.10, PySide6, NumPy, SciPy (`special.jv`, `special.hankel1`, integration), pyqtgraph or matplotlib, pytest. Package with PyInstaller.

---

## 4. GUI layout

**Main window:** left = input tabs, right = plots, bottom = results bar (OASPL / dBA / dBC — average and max seat; tonal vs broadband split).

| Tab | Contents |
|---|---|
| Mission | Segment table (name, altitude, Mach, RPM, shaft power or thrust, η_p); active segment; ISA readout (ρ, c, q, Re) |
| Propeller | B, R_t, h_c, axial station, engine count, rotation, synchrophase Δφ → BPF, Ω, tip Mach; K_refr input; patch mode (1 / 5); source mode (generated / measured override) |
| Fuselage | R, skin (E, ρ, ν, h, η), smeared stiffener mass, nose-to-cabin distance; live f_r, f_c |
| Sidewall Stack | Ordered layer table (panel / gap / blanket); material library; schematic preview |
| Openings | Windows/doors: area + TL or layer stack |
| Cabin | Surface table (area, material, α(f)); cabin box dimensions L_x, L_y, L_z; seat positions; computed A, T60, f_s |

**Plot views**
1. Exterior: incident tone levels per patch + Goody wall spectrum
2. TL vs frequency with f₀, f_r, f_c markers and mass-law line
3. Interior: average level (line), tones (stems), max-seat envelope, K_refr sensitivity band
4. A-weighted contribution per band, stacked tonal vs broadband
5. Seat map: level at each seat for selected harmonic
6. Compare: two configs + IL
7. Mission summary: dBA / OASPL per segment; 1-vs-5 patch sensitivity

### Validation tab
**Left — Validation map:** rows = cases (§5); columns = stage, track, reference, metric, target, result, status (pass / marginal / fail / not run). Header shows coverage. "Run all" stamps date + git commit. All validation is **blind** (no parameters tuned to the data).

**Right — Figure viewer per case:**
- Overlay: code (line) vs reference (markers) with shaded acceptance band
- Error vs frequency with ±target lines
- Predicted-vs-measured scatter with 1:1 line; mean, RMS, max |error|, % within target
- Caption: report number, figure/table, inputs, criteria

**Heatmap:** cases × frequency band colored by |error|/target — shows where in frequency the model is trustworthy.

**Export:** PDF/HTML validation report.

**Extras:** parameter sweeps in a worker thread; CSV/PNG/SVG/PDF export; recent-files menu.

---

## 5. Validation plan (blind — nothing fitted)

| Case | Stage | Track | Check | Reference | Pass target |
|---|---|---|---|---|---|
| V0a | Source | tonal | Rotating-force model, static far field → Gutin | analytic (A.2) | < 0.5 dB per harmonic |
| V0b | Source | — | Cylinder scattering limits: ka→0 → 0 dB; large ka front → +6 dB | analytic (A.3) | < 0.5 dB |
| V0c | Seats | — | Box-mode spatial mean of G(x)/⟨G⟩ = 1 | analytic | < 0.1 dB |
| V1 | TL | — | Single panel θ=0 → normal mass law | analytic | < 0.1 dB |
| V2 | TL | — | Field incidence ≈ 20log(mf) − 47 below f_c | analytic | < 1 dB |
| V3 | TL | — | Double-wall f₀ dip location | analytic | within 1/3 octave |
| V4 | TL | broadband | Lab sidewall-panel TL (bare and treated) | TM-85722 | ±3 dB mid-freq |
| V5 | Source | tonal | Predicted surface harmonics (incident × scattering factor) vs measured, all altitudes/RPMs/single- and twin-engine runs | CR-178004 | ±3 dB at BPF1–3 |
| V5b | Source | broadband | Goody spectrum vs measured exterior fluctuating pressure | CR-178004 | ±3 dB per band |
| V6 | Cabin | both | Treatment IL vs flight | TM-85722 | ±3 dB broadband; report harmonic error |
| V7 | Total | tonal | Cabin harmonic levels at each measured location (average + max-seat method) | CR-178004 | report error band |
| V8 | Total | both | Cross-check vs PAIN recreation | same cases | document divergence |

**Data format:** digitized curves in `data/validation/<case>.csv` with YAML header (report, figure/table, aircraft, condition, units, digitization uncertainty). Case definitions in `cases.yaml`, shared by GUI and `pytest`. V0–V3 run in CI.

---

## 6. Milestones

| # | Deliverable | Scope |
|---|---|---|
| M1 | Core TL engine | materials, porous, tmm; V1–V3 passing (CLI) |
| M2 | Source models | rotating-force tones, Goody TBL, cylinder scattering; V0a, V0b passing |
| M3 | Full pipeline | cabin, seats, weighting, run_case(), JSON, CSV export; V0c passing |
| M4 | GUI v1 | main window, input tabs, plots, results bar |
| M5 | Compare & sweep | two-config overlay, IL, sweeps, patch sensitivity |
| M6 | Validation | digitized NASA data, V4–V8 blind, Validation tab + report export |
| M7 | Polish & package | unit toggles, material editor, PDF report, PyInstaller |

---

## 7. Stated assumptions and limitations (shown in Help/About)
- Plane-wave, infinite-layer TL; curvature via ring-frequency correction only.
- Point forces at a single effective radius; thickness noise not modeled (error quantified by V5).
- TBL treated as equivalent diffuse field → conservative upper bound.
- Boundary-layer refraction is a user input with sensitivity band, not predicted.
- Cabin approximated as a rigid-wall box for the low-frequency seat shape.
- Structure-borne paths (engine/wing) and flanking not modeled.
- Error bands come from blind validation on one turboprop (CR-178004 / TM-85722); stated as such.

## 8. Relationship to PAIN

| Need | Use |
|---|---|
| Design sweeps, treatment trades, IL, mission-segment dBA | Low-fi tool |
| Coupled structural–acoustic detail, stiffener/frame effects, detailed low-frequency tones | PAIN recreation |
| Confidence check | Run both on the same case (V8) |

- Shared JSON case format feeds both tools; "Export to PAIN" / "Import PAIN results".
- The low-fi rotating-force source can also supply PAIN's exterior input as a cheap stand-in.
- Workflow: sweep with low-fi → shortlist → verify in PAIN.

---

## Appendix A — Equations

All SI. `p_ref = 20 µPa`. `j = √−1`. Time convention `e^{−jωt}` for A.3; check signs against the stated limits.

### A.1 Atmosphere (ISA)
```
Troposphere (h ≤ 11 000 m):   T = 288.15 − 0.0065·h ;  p = 101325·(T/288.15)^5.2559
Stratosphere (11–20 km):      T = 216.65 ;             p = 22632·exp(−9.80665·(h−11000)/(287.05·216.65))
ρ = p/(287.05·T)    c = √(1.4·287.05·T)    V = M·c
μ = 1.458e-6·T^1.5/(T + 110.4)            ν = μ/ρ
```
Ambient properties for the source and TBL; cabin air for gaps and cabin.

### A.2 Tonal source — rotating point forces
**Forces** (per blade, applied at R_e = 0.8·R_t):
```
Ω   = 2π·RPM/60
Q   = P_shaft/Ω                    T = η_p·P_shaft/V  (V>0; static: user T)
F_ax  = −T/B   (axial, force on fluid)
F_tan = −Q/(B·R_e)  (tangential, opposing rotation, force on fluid)
```
**Blade source trajectory** (ground frame, flight along +x at speed V; blade k):
```
ψ_k(τ) = Ω·τ + 2πk/B
y(τ)   = [x_p + V·τ,  R_e·cos ψ_k,  R_e·sin ψ_k]
Observer (fuselage patch, moves with aircraft): x_o(t) = x_o0 + [V·t, 0, 0]
```
**Pressure of a moving point force** (exact dipole form):
```
p_k(x, t) = −∂/∂x_i [ F_i(τ*) / (4π · r · |1 − M_r|) ]
  r   = |x − y(τ*)|,   M_r = (dy/dτ · (x − y)) / (c·r)
  τ*  = emission time solving  t − τ* = r(τ*)/c
```
**Numerical recipe** (subsonic tip helical Mach):
1. March emission time τ uniformly over several revolutions; compute reception time t = τ + r/c and the bracketed potential at x_o ± δ·ê_i (δ ≈ λ/100).
2. Interpolate each onto a uniform t grid; take central differences for ∂/∂x_i; sum blades.
3. FFT over an integer number of BPF periods → p_inc,m per harmonic.

**Gutin check (V0a)** — static (V = 0), far field, observer at distance r and angle θ from forward axis:
```
p_m,rms = [m·B·Ω / (2√2·π·c·r)] · | T·cosθ − Q·c/(Ω·R_e²) | · J_mB(m·B·Ω·R_e·sinθ / c)
```
The time-domain model must match this within 0.5 dB; this also verifies force sign conventions.

**Twin propellers** (per harmonic, per patch):
```
p_near : direct from near-side prop
p_far  : far-side prop × shadow factor |S(φ_far)|/2  (A.3, blocked→incident equivalence)
Coherent:   p_inc,m = | p_near + p_far · e^{j·m·Δφ} |
Energetic:  p_inc,m² = p_near² + p_far²
Worst case: p_inc,m = |p_near| + |p_far|
L_inc,m = 20·log10(p_inc,m / p_ref) + K_refr
```

### A.3 Rigid-cylinder scattering (surface factor)
Plane wave of amplitude p_inc incident on an infinite rigid cylinder of radius a, surface angle φ from the incidence direction:
```
S(φ) = p_surface/p_inc = (2j/(π·k·a)) · Σ_{n=0}^{N} ε_n · jⁿ · cos(nφ) / H_n^(1)'(k·a)
ε₀ = 1, ε_n = 2 (n ≥ 1);   N ≈ k·a + 10
H_n^(1)' (z) = ½·[H_{n−1}^(1)(z) − H_{n+1}^(1)(z)]
```
Checks (V0b): |S| → 1 as ka → 0; |S| → 2 at φ = 0 (facing side) as ka → ∞. Used for (i) far-side prop shadowing and (ii) converting predicted incident to surface pressure for comparison with CR-178004 flush-mounted data.

### A.4 Broadband source — Goody wall-pressure model
```
q    = ½·ρ·V²
Re_x = V·x_n/ν                         (x_n = nose-to-station distance)
δ    = 0.37·x_n·Re_x^(−0.2)
C_f  = 0.0592·Re_x^(−0.2)
τ_w  = C_f·q          u_τ = √(τ_w/ρ)       U_e ≈ V
R_T  = (δ/U_e) / (ν/u_τ²)

Φ(ω)·U_e/(τ_w²·δ) = 3·ω̃² / [ (ω̃^0.75 + 0.5)^3.7 + (1.1·R_T^(−0.57)·ω̃)^7 ],   ω̃ = ω·δ/U_e

Band:  p_band² = ∫_{f_l}^{f_u} Φ(ω)·2π df   (Φ per unit ω, one-sided)
L_wall,band = 10·log10(p_band² / p_ref²)
```

### A.5 Sidewall transmission loss — transfer matrix
**Panel properties:**
```
m   = ρ_s·h (+ m_stiff)          D = E·h³/(12·(1−ν_p²))
f_c = (c₀²/(2π))·√(m/D)          c_L = √(E/(ρ_s·(1−ν_p²)))      f_r = c_L/(2π·R)
```
**Panel impedance** (ω = 2πf):
```
Z_p = j·ω·m·[1 − (f/f_c)²·sin⁴θ·(1 + j·η)]·K_curv
K_curv = 1 − (f_r/f)² (skin), 1 (trim);  clip |Z_p| ≥ ω·m·η near f_r
```
**Delany–Bazley blanket** (X = ρ₀f/σ, valid ≈ 0.01–1):
```
Z_c = ρ₀c₀·[1 + 0.0571·X^(−0.754) − j·0.087·X^(−0.732)]
k_c = (ω/c₀)·[1 + 0.0978·X^(−0.700) − j·0.189·X^(−0.595)]
Air gap: Z_c = ρ₀c₀, k_c = ω/c₀
```
**Transfer matrices:**
```
Panel:  T_p = [[1, Z_p], [0, 1]]
Layer:  k_z = √(k_c² − k₀²·sin²θ)
        T_f = [[cos(k_z·d),                     j·(Z_c·k_c/k_z)·sin(k_z·d)],
               [j·(k_z/(Z_c·k_c))·sin(k_z·d),   cos(k_z·d)               ]]
Total:  T = T_skin · T_gap · T_blanket · T_gap · T_trim
```
**Transmission:**
```
τ(f,θ) = | 2 / (T₁₁ + T₁₂·cosθ/Z₀ + T₂₁·Z₀/cosθ + T₂₂) |²
τ_d    = ∫₀^78° τ·sinθ·cosθ dθ / ∫₀^78° sinθ·cosθ dθ      (Gauss–Legendre ~60 pts)
TL_d   = −10·log10(τ_d)
Band:  average τ_d over ~10 log-spaced frequencies in the band, then TL
Composite: τ_comp = Σ Sᵢ·τᵢ / Σ Sᵢ
```
**Unit checks:**
```
TL₀ = 10·log10(1 + (ω·m/(2ρ₀c₀))²)              normal incidence single panel
TL ≈ 20·log10(m·f) − 47                         field incidence, f ≪ f_c
f₀ = (1/2π)·√(ρ₀c₀²·(m₁+m₂)/(d·m₁·m₂))          double-wall resonance
```

### A.6 Cabin level — power bookkeeping
```
A(f) = Σ Sᵢ·αᵢ(f)          T60 = 0.161·V_cab/A          f_s = 2000·√(T60/V_cab)

Tones (patch i, area S_i, incidence angle θ_i from prop–patch geometry):
  W_t,m = Σ_i S_i · τ(f_m, θ_i) · p_inc,m,i² · cosθ_i / (ρ₀c₀)
  p_int,m² = 4·ρ₀c₀·W_t,m / A(f_m)

TBL (full sidewall S_w, wall pressure → equivalent diffuse incident, −6 dB):
  p_inc,band² = p_wall,band² / 4
  W_t,band    = S_w · τ_d,band · p_inc,band² / (4·ρ₀c₀)
  p_int,band² = 4·ρ₀c₀·W_t,band / A            [conservative upper bound]

L_int = 10·log10(p_int² / p_ref²)
```
1-patch default: θ₁ from the nearest point, S₁ = user prop-plane area (e.g. frame bays × window-belt height). 5-patch option: patches spaced axially/circumferentially across that area, each with own p_inc and θ.

### A.7 Max seat
**Above f_s** (diffuse statistics; p² exponentially distributed):
```
L_95 = L_int + 10·log10(ln 20)  = L_int + 4.8 dB
L_99 = L_int + 10·log10(ln 100) = L_int + 6.6 dB
```
**Below f_s** (rigid-box modes give spatial shape; energy from A.6):
```
f_n    = (c₀/2)·√((n_x/L_x)² + (n_y/L_y)² + (n_z/L_z)²)
ψ_n(x) = cos(n_xπx/L_x)·cos(n_yπy/L_y)·cos(n_zπz/L_z)
η(f)   = 2.2/(f·T60)
ψ̄_n    = mean of ψ_n over the prop-plane sidewall patch
G(x)   = | Σ_n ψ_n(x)·ψ̄_n / (f_n² − f² + j·η·f·f_n) |²       modes up to ~2·f
L(x)   = L_int + 10·log10( G(x) / ⟨G⟩_cabin )                ⟨G⟩ = volume average (V0c)
Max seat = max over seat positions of L(x)
```

### A.8 Weighting and totals
```
R_A = 12194²·f⁴ / [(f²+20.6²)·√((f²+107.7²)(f²+737.9²))·(f²+12194²)]    A = 20·log10(R_A) + 2.00
R_C = 12194²·f² / [(f²+20.6²)·(f²+12194²)]                              C = 20·log10(R_C) + 0.06

Band b (f_l = f_c·2^(−1/6), f_u = f_c·2^(1/6)):
  L_b = 10·log10( 10^(L_bb,b/10) + Σ_{f_m∈b} 10^(L_m/10) )
OASPL = 10·log10 Σ_b 10^(L_b/10)
dBA   = 10·log10 Σ_b 10^((L_b + A(f_b))/10)
dBC   = 10·log10 Σ_b 10^((L_b + C(f_b))/10)
```
Report tonal-only, broadband-only and total, for both average and max seat.

### A.9 Inputs that are stated, not fitted
| Input | Why it is an input | How handled |
|---|---|---|
| K_refr (0–5 dB) | no closed form for BL refraction | sensitivity band on plots |
| Δφ synchrophase | operating setting | energetic / coherent / worst-case reported |
| Patch area S₁ | geometry definition | 1-vs-5 patch sensitivity check |
| Cabin box L_x, L_y, L_z | geometry simplification | stated assumption |

---

## Implementation notes (2026-11-02)

### Milestone status
| # | Status |
|---|---|
| M1 Core TL engine | Done. V1, V2 and V3 pass. |
| M2 Source models | Done. V0a and V0b pass. Time-domain and Gutin results agree within 0.04 dB. |
| M3 Full pipeline | Done. `run_case`, JSON and CSV export work. V0c passes. |
| M4 GUI v1 | Done. Six input tabs, eight plot views and the results bar. |
| M5 Compare & sweep | Done. A/B overlay, IL, background sweeps, mission summary, 1-vs-5 patch check. |
| M6 Validation | Framework done: Validation tab, figures, heatmap, HTML/PDF export. **V4a and V5 run 2026-11-02: both not met** (see below). V4 and V6 need TM-85722, which is not in the repo. V5b and V7 can be built from CR-178004 (App. D, B), which is already in the repo. |
| M7 Polish & package | Partly done: material library and PDF report. Still open: unit toggles, a separate material editor, PyInstaller build. |

### Where the code differs from the text above
1. **Sign of the tangential force (A.2).** The force *on the fluid* points **along** the blade motion, not against it. Only that sign reproduces Gutin's `T cosθ − Q c/(ΩR_e²)`, so V0a confirms it. The plan's "opposing rotation" is the force on the blade.
2. **Time domain → frequency domain (A.2).** The model, the retarded time and the ±δ finite difference are the same. The harmonics are computed as a Fourier integral over emission time, `φ_n = (1/T)∫φ e^{jω t(τ)} (dt/dτ) dτ`, instead of interpolating onto a t grid and taking an FFT. This form is exact and needs no re-gridding. The delay `s = t − τ` has a closed form because the observer moves with the aircraft.
3. **Curvature term (A.5).** The ring-frequency stiffness is *added* to the bracket: `Z_p = jωm[1 − (f_r/f)² − (f/f_c)² sin⁴θ (1+jη)]`. Multiplying the whole bracket by `K_curv` would flip the sign of the bending term below f_r.
4. **ρ₀c₀ in the TMM and in A.6.** Both use cabin air. For a mass-controlled wall, the transmitted power depends on the blocked pressure: τ(ρc_cab) × p_inc²/(ρc)_cab gives the right W_t.
5. **Schroeder frequency** uses the mean of T60 at 500 Hz and 1 kHz. Below f_s, broadband seat shapes average G over 5 frequencies inside each band.
6. **Max seat.** Each seat gets its own band spectrum: the box-mode shape below f_s and +4.8 dB above. The reported "max seat" is the seat with the highest total dBA, not a per-band envelope. The envelope appears only in the Interior plot.
7. **Far-side shadow angle** for the 5-patch option is `π − |α|`, where α is the patch's circumferential angle.
8. **Verdict rule.** V0-V3 compare against analytic limits, so under the repo rule (2026-10-29) they are *verification*: they show "check ok / failed" and never a met / not-met verdict. Only V4-V7 can carry a verdict. V8 is information only.
9. `gui/panels.py` is one module instead of a `panels/` package.

### Defaults and library
- The default project is a *generic* twin turboprop with stated inputs; it represents no specific aircraft.
- `materials.json` holds handbook-typical values. None of them is fitted to validation data.
- The default project gives: cruise 84.9 dBA room average, 89.7 dBA max seat. The 1-vs-5 patch difference is 0.02 dB, so 1 patch is adequate for this case.
### Experimental data already in the repo (inventory 2026-11-02)
Everything below is digitized under `PAIN_Program/data` and can be copied without digitizing again. Record provenance in each reference CSV.

| Data | What it measures | Cabin_Noise use | Status |
|---|---|---|---|
| TP-1964 Fig. 8 (`tp1964/`) | Bare unstiffened cylinder, reverberant-field NR, 50 Hz-5 kHz | **V4a** (sidewall TL / NR, lab) | Run: not met |
| TP-1964 Fig. 17 (`tp1964/`) | Measured interior T60 and structural decay | V4a inputs (absorption, eta) | Used |
| CR-3813 Figs. E-21/E-22 (`cr3813/`) | Stiffened, trimmed 1.83 m cylinder, reverberant NR (range and 95 % limits) | Candidate V4b | Blocked: blanket flow resistivity and septum material are not printed (input-completeness) |
| CR-3813 Fig. E-13 (`cr3813/e13_absorption_targets.csv`) | Measured interior absorption of that cylinder | V4b / V7b inputs | Available |
| CR-3813 Fig. E-16, T1/T2 targets (`cr3813/`) | Propeller-driven interior 1/3-octave levels, same cylinder | Candidate V7b (tonal interior) | Needs the measured exterior field (E-11) as a measured-source override; same trim inputs gap as V4b |
| CR-3813 Fig. E-11 (`cr3813/e11_freefield_measured_*.csv`) | Measured free-field propeller levels | V5-style source check / V7b input | Available, not yet mapped |
| TP-2444 Figs. 17, 19 (`tp2444/`) | Same 1.83 m model 2: exterior and interior spectra, rotation direction | Candidate V7c | Analysis bandwidth not stated (5 Hz assumed in PAIN); trim gap as above |
| CR-172428 App. B (`cr172428/`) | Blocked pressure field and PAIN's predictions | V8 (vs PAIN) only, not experimental | Available |
| CR-172490 Fig. 15 (`cr172490/`) | Sharp's double-panel *prediction* | Verification only (another method) | Not a validation reference |
| `references/NASA_CR_178004.pdf` | Commander 695A flight: exterior and interior harmonics, untreated and treated | **V5** (run), V5b, V7 | The appendices are printed tables with a text layer, so they can be transcribed (not digitized from plots). App. A drives V5; App. D (1/3-octave exterior) drives V5b; App. B and E (untreated cabin) and App. C, F, J (treated cabin, insertion loss) drive V7 and a V6-like case. Inputs are in sec. 2 and Tables 1-8 |
| NASA TM-85722 | Lab TL and in-flight IL | V4, V6 as planned | Not in the repo |

### V4a result (TP-1964 Fig. 8, run 2026-11-02, criterion fixed before the run)
- **Not met.** max |dNR| = 16.1 dB over 250 Hz-2 kHz (target 3 dB); 1 of 21 bands lies within 3 dB over 50 Hz-5 kHz.
- Post-hoc attribution, information only (wall-only re-run, no verdict):
  1. The end caps, modelled as infinite mass-law panels with coincidence at 970 Hz, control the composite below 2 kHz. Without them, NR at 50-160 Hz is 44-54 dB against 40-46 dB measured. Small clamped thick plates are stiffness-controlled, which the plane-wave panel cannot represent.
  2. With the wall alone, the model still predicts 12-24 dB too much NR at 250 Hz-2 kHz. A lightly damped (eta = 0.0018) thin cylinder transmits through resonant modes below the ring frequency (3.3 kHz). The plane-wave TL with an added ring-stiffness term has no resonant path. This is the plan's stated assumption 1, and V4a measures what it costs.
  3. Near f_r the model's NR falls to about 0 dB; measured is 4.5-7 dB.
- A fix (for example a statistical resonant-transmission term below f_r, or a finite-plate end-cap model) is a model change. It must be judged on a case it was not developed against; V4a's result stays recorded as is.

### Low-fidelity criterion policy (decided 2026-11-02, before any comparison of V4, V5, V5b, V6, V7)
- The plan's +-3 dB at every point is a high-fidelity target. A low-fi tool is meant for design trades and overall levels, so the unrun experimental cases are now judged **met when at least 75 % of the points in range lie within +-6 dB**. Max |e|, RMS and mean error are reported with every result. V7 now carries a verdict instead of "report only".
- **V4a keeps its original verdict** (max-error <= 3 dB: not met), because it was defined and run under that criterion. Re-stated under the new policy (**post-hoc, information only, 2026-11-02**): 3 of 10 bands lie within +-6 dB, which would still be not met.
- Misses are an expected outcome for a low-fi tool. They are recorded with an attribution and listed as known limits, and are never tuned away.

### V5 result (CR-178004 App. A, flight 3, run 2026-11-02; definition committed first in 4eadb02)
- **Not met:** 43 of 101 surface harmonic levels lie within +-6 dB (75 % needed). Mean error +6.1 dB, RMS 6.4 dB, max |e| 10.1 dB. The model overpredicts systematically, most at BPF1 (+7.7 dB average) and least at BPF3 (+4.7 dB). The error is similar at all three altitudes (+5.1, +6.4 and +6.5 dB). For context, the report's own simplified methods overpredicted the same data by 7 dB and 11 dB on average (CR-178004 Table 9).
- Sensitivity, post-hoc, information only (no input was changed for the verdict): eta_p 0.7 / 0.9 moves the mean error by about +-0.4 dB; fuselage radius 0.6 / 0.9 m by 0.2 dB or less. **The effective loading radius dominates:** R_e = 0.7 / 0.9 R_t gives mean +2.8 / +8.7 dB. Collapsing the blade loading onto one radius 0.36 m from the tips is the main near-field error (plan assumption 2).
- Possible model change: spread the forces over several radial stations with a stated (not fitted) loading shape. Flights 1, 2 and 4 of App. A are repeat flights of the same conditions, so they are *not* an independent check for a change motivated by flight 3. Such a change would need a different aircraft or test to earn a verdict.
