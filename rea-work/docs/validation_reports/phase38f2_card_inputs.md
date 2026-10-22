# Phase 38f-2 — Manual cards 3–6 / 11–18 (band set, per-band η_r / η_n)

**Date:** 2026-10-22. **Spec:** `docs/specs/38f2_card_inputs_bands.md`.  
**Criterion:** none (input plumbing). Defaults must reproduce prior outputs exactly.

## Readings decided

### Cards 3–6 — user 1/3-octave band set

Manual §5.4: NI = number of 1/3-octave band centre frequencies (maximum 26); cards 4–6 list the centres (8 per card).  
`PainInputs.bands`: `nothing` → production list `third_octave_centers()` (63 Hz…8 kHz, geometric f₀ = 1000 Hz). Non-`nothing` → validated: each entry snaps to a standard geometric centre (≤ 2 % relative), count ≤ 26, strictly ascending; otherwise a clear error.  
Used by `interior_spl` (tone binning + broadband loop), `noise_reduction_spectrum`, and crossover estimation when those call sites take the inputs’ band list.

### Cards 11–18 — per-band structural and acoustic loss factors

Manual: cards 12–14 “STRUCTURAL LOSS FACTORS” (one per band); cards 16–18 “ACOUSTIC LOSS FACTORS” for a bare fuselage, “If the input loss factors are zero, then the cabin trim data is used to calculate them.” Output §5.4.3 distinguishes input structural loss factors from η_rad and from η_r′ with trim.

**η_r_band (cards 11–14):** non-zero entry replaces η_r of Eqs. (79)–(81) (`structural_loss_total`) for every structural mode whose resonance lies in that band; Eq. (82) trim and optional `η_r_cap` still apply afterward. Zero or absent → compute Eqs. 79–81 as before.  
**η_n_band (cards 15–18):** non-zero entry replaces η_n for tones/modes looked up in that band (N = η_n ω_n²). Zero or absent → trim Eq. (77) when trim is present, else scalar `η_n_bare`.  
Storage: `Dict{Float64,Float64}` keyed by snapped band centres, or a vector aligned with `bands`. Exposed on aircraft JSON (`bands_Hz`, `eta_r_band`, `eta_n_band`) and GUI Observables (JSON text; empty = default) without GUI redesign.

### Band lookup (tone / mode frequency ≠ centre)

Manual cards give one loss factor per listed band. For a tone frequency or structural mode frequency that is not a centre: use the band whose 1/3-octave edges contain it. Edges follow CR-3813 c_ω = 0.232:  
`lo = fc·(1 − c_ω/2)`, `hi = fc·(1 + c_ω/2)` (same convention as modal “in band” counts elsewhere).  
If no listed band contains the frequency, no override applies (computed path). Example: 600 Hz → 630 Hz band.

## Tests run

```text
Pkg.test("PAIN"; test_args=["Card inputs 38f-2", "Validation case registry"])
```

| Testset | Result |
|---------|--------|
| Card inputs 38f-2 (bands, η_r/η_n per band) | **49/49 Pass** (~3.0 s) |
| Validation case registry (34d) | **1188/1188 Pass** (~84 s) |

Checks covered: defaults / explicit default band list identical for tone SPL, NR, HF, and REPRO_18b-like e11 harmonics; contiguous custom subset matches default SPLs at those centres; invalid sets (non-standard, > 26, unsorted) raise; η_n equal to `η_n_bare` identical, zero falls back, other value changes only the containing band’s harmonic; η_r equal to computed Eqs. 79–81 for a single-mode band identical, different value changes the result; vector η form accepted.
