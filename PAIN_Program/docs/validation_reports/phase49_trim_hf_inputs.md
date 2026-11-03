# Phase 49: trim and high-frequency inputs inside PAIN's theory

Run 2026-10-23. Criteria fixed 2026-10-23 in `IMPLEMENTATION_PLAN.md` §8e, before any check was written or run. Testset: "Trim and high-frequency inputs (phase 49)", 10/10.

## 49a τ_t of Eq. (A.22): met

The insulation-path |a11|⁻² was rebuilt by hand, element by element (skin side first), from the material table and the limp-mass law. It does not use `element_matrix` or `stack_matrix`. It equals `trim_tau_insulation` within 1e-12 for:
- the Phase III sidewall and the CR-172428 App. B sidewall;
- 250, 1000 and 2000 Hz.

Limits:
- One layer alone gives |cosh γd|⁻².
- A limp mass alone on the blocked face gives τ = 1. That is the property of the A.14 definition, a pressure ratio onto a blocked face.

The plan asked for an "independent mass-law / double-wall calculation". The hand recursion is the same physics written independently of the code, so it checks the code, not the model. A different trim model would be an extension, not a check of A.22.

## 49b Measured trim transmission loss: none found

I searched every report in `references/`. None contains a measured transmission loss of the PF105 blanket, the Phase III trim or the App. B trim. The documents do state, in NASA's own words, what the trim model does at high frequency:
- **CR-3813 p. E-35** (Phase III, reverberant test): "Two possible explanations for the discrepancy are (a) other flanking paths are present, and (b) the analytical model over-estimates the influence of the sidewall treatment." The same page says the program "assumes that no noise is transmitted through the ends of the cylinder". Its note on the end plates: "The contribution becomes significant only for reverberant field excitation."
- **CR-3813 p. E-39:** "some improvements to the sidewall treatment model are required".
- **CR-172428 p. 152:** with η_T = 2, which NASA recommends, the trim model is "valid in the frequency range from about 50 to perhaps 1000 Hz". The same page notes that "trim effects are not simply describable in terms of a transmission coefficient".

T2's bands, 1250–2000 Hz, lie above the range NASA states for the trim model.

## 49c Term budget of Eq. (23) at 1260 Hz

| | T2 inputs (Phase III trim, η_T = 0.5) | 47c inputs (App. B trim) |
|-|----------------------------------------|---------------------------|
| τ_t insulation path | −29.5 dB | −26.7 dB |
| τ_t mechanical path (A.19) | −22.4 dB | none (no mechanical path given) |
| τ_R (resonant) | −37.9 dB | −30.5 dB |
| τ_f (Eq. 20), as first coded (in-band modes) | −52.4 dB | −51.8 dB |
| τ_f (Eq. 20), corrected (modes below the band, 32 Table D-1 modes) | −47.4 dB | −46.9 dB |
| ᾱS (m²) | 8.43 | 0.85 |
| A_t (m²) | 5.56 | 5.56 |
| NR, Eq. (23) | 61.2 dB | 49.0 dB |
| NR with τ_t = 1 (no trim) | 39.5 dB | 22.4 dB |
| measured NR | 19.5 dB (E-22, reverberant) | 33.9 dB (TP-2444, propeller) |

**Where the excess comes from.** The trim factor τ_t carries 22–27 dB of predicted noise reduction. The measured noise reduction lies between the bare-wall and the trimmed prediction. The wall transmission τ is dominated by the resonant term.

**η_T sensitivity (App. B trim).** At 1260 Hz the noise reduction moves by less than 0.5 dB for η_T from 0.13 to 2, and at 2000 Hz it rises from 69.7 to 75.6 dB. A larger η_T moves it in the wrong direction. No documented trim input closes the gap.

**Eq. (20) reading corrected.**
- **The printed text.** CR-3813 p. 24 says the Eq. (19)/(20) sum "implies a sum over all structural modes ω_r that are resonant below the frequency band of concern". CR-159363 Eq. (16) is the same.
- **The defect.** The code summed the in-band modes. That is a reading defect, corrected because the printed text requires it; no result was used to choose the change. The correction was found 2026-10-23, after the Phase 47 result, while auditing that result.
- **Effect.** τ_f rises by about 5 dB, but τ_R dominates τ. Interior and NR values change by at most 0.3 dB: T2_MEAS_EXT moves from 21.25 to 21.55 dB, and NR_PROP_TP2444 at 1260 Hz from 49.08 to 49.01 dB. No verdict changes.
- **`HF_MASSLAW` (41d).** It now uses one mode in the band and one below it; it is met.
- **Mode set.** The production mode set has 32 Table D-1 modes, up to 811 Hz; NASA used 300. Above 811 Hz the below-band sum therefore misses every mode between 811 Hz and the band edge; nothing estimates them. This is a known truncation, kept as is.
  - Sensitivity, no criterion: the App. D Ritz set (`appd_modes`, 228 modes to 3 kHz) gives τ_f = −39.8 dB at 1260 Hz, still below τ_R.
  - For the bare TP-1964 cylinder, a complete Donnell set (7398 modes) gives a below-band τ_f 10–15 dB under the flat-panel mass law below the ring frequency. That is expected for a curved shell, which is stiffer than a flat panel there.

## 49d Untrimmed area A′: no change

- **Phase III trim.** The septum covers the curved walls "from floor to floor" (CR-3813 p. E-9). The end plates are treated separately and are outside Eq. (23) by the program's stated assumption (p. E-35). A′ = 0 follows the documents.
- **TP-2444 fiberglass trim.** The report gives no coverage, so A′ stays 0 for 47c (V-ASSUMED).

## Reading

Inside PAIN's printed theory and its documented inputs, nothing closes the high-frequency gap:
- the code checks are met;
- one reading defect was fixed (small effect);
- no input correction has a documentary basis.

NASA's own reports say the trim model over-estimates the sidewall treatment and is valid only to about 1000 Hz. The remaining T2 gap is therefore a documented limitation of PAIN's trim model above 1 kHz. It is a candidate for Phase 51, an extension, once Phases 48 and 50 are done.
