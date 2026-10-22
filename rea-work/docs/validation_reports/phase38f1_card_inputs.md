# Phase 38f-1 — Manual cards 2, 9, 36 (air split, cavity L_c/d, rotation)

**Date:** 2026-10-22. **Spec:** `docs/specs/38f1_card_inputs_geometry.md`.  
**Criterion:** none (input plumbing). Defaults must reproduce prior outputs exactly.

## Readings decided

### Card 2 — exterior / interior air

Manual §5.4 card 2 lists exterior density, interior density, exterior sound speed, interior sound speed.  
`PainInputs` keeps `ρ0`,`c0` as the single-air entry points; when `ρ_ext`/`c_ext`/`ρ_int`/`c_int` are omitted they equal `ρ0`,`c0`.

**Term map** (CR-3813: ρ₀/c₀ exterior, ρ/c interior when distinguished):

| Term | Air |
|------|-----|
| Mass-law (mA/4)²τ_ML | exterior |
| η_rad^ext; ρ₀ in τ_R first factor; joint acceptance k=ω/c; exterior radiation in η_r′ | exterior |
| Cabin modes ω_n, axial truncation; V; 4c²/V² (Eq. 8); η_n (Eq. 77) + trim conductance facing cavity; η_r″ (Eq. 83); ᾱ / W_diss; η_rad^int; ρ and c in τ_f and (4ρc/Ā) of τ_R; ρ in Eq. 17 cavity energy factor | interior |

### Card 9 — cavity length L_c and offset d

Manual: L_c = cavity length; d = distance of start of structure from start of cavity.  
Spec/overlap reading: cavity occupies [d, d+L_c], structure [0, L]; integral over the intersection. Defaults L_c = L, d = 0.  
Acoustic shapes cos(qπ(z−d)/L_c); V = (cross-section)×L_c; absorbing sidewall uses L_c. Transmitting area A still uses structure length L.  
When L = L_c and d = 0, axial factor is printed Eq. (57). Otherwise closed-form overlap integral (Methodology §3.5 → Ref. [3] for L ≠ L_c).

### Card 36 — rotation direction ±1

Manual: +1.0 if propeller rotates counter-clockwise in +z (as Fig. 3); −1.0 if clockwise.  
**What it flips:** azimuth sense of the upper-quarter grid, θ_ℓ = φ_p ± (ℓ−1)π/18, and ANOPP x₂ sign; blade-passage phase sign (e11/synthetic helpers). **Not** adopted: lower-quarter grid mirroring (19d / card-36 note already one side only).

## Tests run

```text
Pkg.test("PAIN"; test_args=["Card inputs 38f-1", "Validation case registry"])
```

| Testset | Result |
|---------|--------|
| Card inputs 38f-1 (air split, L_c/d, rotation) | **26/26 Pass** (~2.3 s) |
| Validation case registry (34d) | **1188/1188 Pass** (~84 s) |

Checks covered: defaults / equal split identical to baseline tone SPL, NR, HF path; ρ_ext≠ρ_int moves only mapped terms (mass-law, η_rad^ext/int, τ_f); L_c=L,d=0 identical; L_c<L,d>0 scales V, shrinks mode count, coupling matches numerical overlap to 1e-6; rotation +1 unchanged, −1 mirrors θ/x₂ and phase, −1 twice restores phase array.
