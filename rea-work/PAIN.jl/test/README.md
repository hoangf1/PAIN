# PAIN.jl tests

`runtests.jl` is the `Pkg.test()` entry point. Top-level testsets can be filtered; nested testsets always run with their parent.

## Filter

```powershell
# all testsets (default)
julia --project=. -e "using Pkg; Pkg.test()"

# only top-level titles containing any substring (case-insensitive)
julia --project=. -e "using Pkg; Pkg.test(`"PAIN`"; test_args=[`"CYL2D`", `"Validation case registry`"])"
```

Empty `test_args` / `ARGS` → unchanged full suite. The runner prints which testsets ran and which were skipped.

Persistent Julia (optional): see `scripts/devtools/README.md`.

## Top-level testsets and typical times

Measured once on 2026-10-22 (Windows, Julia 1.13.2, full `Pkg.test()` wall **224 s** including package load). Times are per-testset body only (`RAN:` lines), not cold-start.

| Typical s | Title |
|----------:|-------|
| 0.94 | Blocking Eq.43 vs CR-172428 p.68 (V-UNIT) |
| 0.00 | Grid geometry 160 points (User Manual Fig.3) |
| 0.08 | Grid azimuth: ℓ = 1 at the propeller azimuth, upper quarter (12b, V-CODE) |
| 0.00 | Grid extension unit checks (V-ASSUMED code-only) |
| 0.37 | GEXT importance-bound options (code checks, not physics) |
| 2.62 | CYL2D vs Table C-1 and Fig. C-3 (App. C scheme, V-CODE, criteria fixed 2026-10-20; frequency check re-stated as ratios 2026-10-21) |
| 0.01 | Three-dimensional cabin modes (Eqs. C.7, C.9, C.12) |
| 0.03 | Table D-1 shapes, all 32 modes (transcription checks, V-CODE) |
| 0.13 | CYL2D floor values |
| 0.01 | Coupling f'(n,r) Eq.(52) (V-CODE, analytic limits) |
| 0.03 | Table D-1 seed load (transcription check; residual 0 by construction) |
| 0.01 | Fig E-11 digitization path (SRC_TA) |
| 0.18 | End-to-end pipeline smoke |
| 1.52 | E-11 pipeline: T1/T2 recorded, not asserted (Eq. 8 chain, no tuning) |
| 0.00 | Trim / loss helpers |
| 0.34 | App. A trim transfer matrices (16a) |
| 0.12 | Loss factors, Eqs. (62)–(83) (16b) |
| ~3 | Noise reduction Eqs. (17)–(18) (38a) |
| 0.01 | Generalized force Ψ_G, Eq. (42) (17e, analytic limits) |
| 0.07 | Resonance form of Eq. (8) (17g) |
| 8.69 | Eq. (8) tone pressure: scaling laws and independent re-implementation (17a, 17h, 17i) |
| 0.22 | PainInputs and the trim path (17a, 17b) |
| 0.31 | Phase 17 regression baselines (17k, frozen 2026-10-20) |
| 0.29 | MRP raw Ritz: regression guard of a calibrated fit (not evidence) |
| 0.10 | Metrics dBA / SIL |
| 12.02 | Shared source function (21, V-CODE) |
| 0.30 | F1A source span and phase origin (I-01/I-02) |
| 0.11 | BBN kinematics (24b, V-UNIT) |
| 1.49 | Polar loader (25i, V-CODE) |
| 0.32 | Report 996 conversions + blade form (25b/25j, V-UNIT) |
| 98.9 | Validation case registry (34d) |

Fast filters for a smoke check: `Grid geometry`, `CYL2D floor`, `Trim / loss helpers`. The registry testset dominates wall time.
