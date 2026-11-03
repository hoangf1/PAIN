# Task 38c — CR-3813 §3.3 high-frequency broadband model, Eqs. (19)–(23) as printed

Repo `D:\code\PAIN\rea-work\PAIN.jl`. Read `D:\code\PAIN\CLAUDE.md` and `rea-work/docs/IMPLEMENTATION_PLAN.md` §8 Phase 38 row 38c and the
T2 criterion in `VALIDATION_GUIDELINE.md` (unchanged: ±3.5 dB, 1.25–2 kHz, against Fig. E-9; **dated before this run; do not change**).
No tuning: **no** parameter (including any scale on j², τ, A_t, S, A′) is chosen by looking at Fig. E-9, E-21 or E-22. No commit.
Never open a GUI window. Do not write IMPLEMENTATION_PLAN entries (the reviewer does); update README / flowchart / METHODOLOGY /
VALIDATION_GUIDELINE for what you add. Do not edit reference/digitized CSVs or existing validation reports (new ones only).

## Equations
Read pages `rea-work\docs\specs\cr3813_pages\cr3813_pdf033.png` (p. 23), `pdf034` (p. 24), `pdf035` (p. 25), `pdf036` (p. 26) yourself:
Eq. (19) (high-frequency interior mean-square pressure from the broadband blocked pressure through resonant transmission),
Eqs. (20)–(23): trim areas A_t, S, A′, τ_t, resonant transmission coefficient, average radiation loss factors. Transcribe each into the
code comments as printed; list every reading you had to decide and why (units, which band width, which average loss factors, where
the existing trim/insulation tables enter). Reuse existing pieces where the text says the same thing (Phase III trim, `τ_t`,
`structural_joint_acceptance`, radiation loss factors from Eqs. 79–81); do not re-derive differently.

## Code
- New `src/hf_broadband.jl` (include in `PAIN.jl`, export): `hf_broadband_band_p2(inp, fc, p2_bl; ...)` implementing Eq. (19)–(23), and a
  third-octave spectrum function mirroring `interior_spl`'s broadband path with a selector keyword `broadband_model` with values
  `:surrogate` (default = existing `broadband_cabin_p2` with `bb_j2_scale`, outputs unchanged) and `:eq19` (the new printed model).
- Do not change the default behaviour of any existing function or case. Do not delete the surrogate (the reviewer decides later).
- New case `T2_EQ19` (or extend the registry in the repo's usual way): same Fig. E-9 targets and tolerance as T2, label
  "V-EXP; printed Eq. (19)–(23), first run 2026-10-22; T2 criterion unchanged". Report counts and per-band deltas. Also compute
  Eq. (19) NR over the E-21 bands ≥ crossover (400 Hz and up) using the 38a `noise_reduction_band` interface where Eq. (18) is above
  crossover, and record the full-band E-21/E-22 verdict with the 38a thresholds (≥ 75 % of non-excluded bands: |Δ| ≤ 3 dB vs NASA;
  inside E-22), where bands below crossover use Eq. (18) and bands at/above use Eq. (19). Report only; the criterion is already dated.

## Tests (V-UNIT before any comparison)
1. Limits of Eqs. (20)–(23): areas/factors that are given in closed form reproduce hand-computed values for a simple stack
   (state the values).
2. Energy/reciprocity: Eq. (19) with η large and τ → known simple limit (state it); result positive and finite across 1/3-octaves
   1 kHz–4 kHz.
3. Default (`:surrogate`) reproduces current T2 results exactly.
4. Case runs; table/series non-empty.
Run only the new testset and "Validation case registry" via `Pkg.test("PAIN"; test_args=[...])`. Do not run the full suite. Do not change
anything after seeing the comparison. Report: equations as implemented, readings decided, tests run, T2 per-band table and count,
full-band E-21/E-22 counts and verdict.
