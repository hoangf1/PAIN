# Task 38b — CR-3813 §3.2 high-frequency tone formulation (Eqs. 11–16) and the crossover band

Repo `D:\code\PAIN\rea-work\PAIN.jl`. Read `D:\code\PAIN\CLAUDE.md` and `rea-work/docs/IMPLEMENTATION_PLAN.md` §8 Phase 38 row 38b and
issue I-18 (criteria **dated 2026-10-21, before any run; do not change them**). Implement the text as printed. No tuning: no parameter
is chosen by looking at REPRO_18b / T1 / E-16. No commit. Never open a GUI window. Do not write IMPLEMENTATION_PLAN entries (the
reviewer does); update README / flowchart / METHODOLOGY / VALIDATION_GUIDELINE for what you add.

## Equations
Read pages `rea-work\docs\specs\cr3813_pages\cr3813_pdf027.png` (p. 17, Eq. 11 and the g_n, g_r, Q_H definitions), `pdf028` (p. 18,
Eqs. 12–14), `pdf029` (p. 19), `pdf030` (p. 20) yourself — Eqs. (14)–(16): expected value of Eq. (13) with ω_n, ω_r independent and
uniform over Δω, the closed forms E[g_n], E[g_r] in terms of the band edges and average loss factors η̄_n, η̄_r, the mode counts
N_n, N_r (or densities n_n, n_r), and ⟨ε_n f′²⟩. Transcribe them into the code comments as printed; state every reading you had to
decide (e.g. which Δω, c_ω = 0.232 for 1/3 octaves, how η̄_n / η̄_r are averaged over the modes in the band, which f′ — barred or
unbarred; use the same choice as 38a/Eq. 8 and say so) and why.

## Code (new file `src/high_freq_tones.jl`, include in `PAIN.jl`, export)
- `tone_expected_value(inp, H; ...)` → NamedTuple: ⟨p_i²⟩ expected value, N_n, N_r, η̄_n, η̄_r, E[g_n], E[g_r], mode counts in band.
- `acoustic_crossover_band(inp; bands)` if 38a already added it, reuse it; otherwise implement the fixed rule: the lowest 1/3-octave band
  whose count of 3-D acoustic modes (q, i) with resonance inside [ω(1−c_ω/2), ω(1+c_ω/2)] is ≥ 10; input override `crossover_band`
  (Manual card 10).
- Production tone value: Eq. (8) below the crossover band, the Eq. (15)–(16) expected value at and above it (Manual output 9(3));
  **both always reported** in the result. Keep the existing Eq. (8) entry points unchanged; add a new selector keyword with default that
  reproduces current results exactly **until the reviewer decides** (default `tone_model = :eq8`; `:auto` = crossover switch).
- Do not change the default behaviour of any existing function or case.

## Tests (V-UNIT before any comparison)
1. When N_n, N_r are large and loss factors small, the expected value (Eq. 14–16) tends to the Monte-Carlo mean of Eq. (13) with
   ω_n, ω_r drawn uniformly in the band (seeded, tolerance chosen from the sampling error, stated in the test).
2. Closed form of E[g] equals direct numerical integration over the band (1e-8 relative).
3. Default (`:eq8`) reproduces current tone results exactly (no change to existing outputs; use stored baselines).
4. Crossover band for the test article is computed and printed; counts ≥ 10 rule checked on a synthetic mode set.
Run only the new testset and "Validation case registry" via `Pkg.test("PAIN"; test_args=[...])`.

## Comparison (criteria fixed in the plan, 2026-10-21)
Run REPRO_18b inputs once with `:auto`, record per harmonic: Eq. (8) value, Eq. (15)–(16) value, production value, and the distance to
NASA (79.0, 75.5, 68.0 dB). Report whether H3 is within 4 dB of 68.0 dB with 38b where Eq. (8) is not (the I-18 rule). Do **not** adopt
mirroring or change anything after seeing the result; report numbers only. Report: equations as implemented, readings decided, crossover
band, table, tests run.
