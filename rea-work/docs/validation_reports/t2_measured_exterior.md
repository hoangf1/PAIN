# Phase 47: T2 with a measured exterior spectrum of the test article

Run 2026-10-23. Criteria fixed 2026-10-23 in `IMPLEMENTATION_PLAN.md` Phase 47, before any digitizing or run (commit 5f55041). The 47b–47d implementation decisions were fixed the same day, after the 47a digitizing and before any band level, noise reduction or interior level was computed (plan, "Implementation decisions for 47b–47d").

Cases:
- `NR_PROP_TP2444` (47c, V-EXP)
- `T2_MEAS_EXT` (47d, V-EXP; 47e reported in its `inputs_echo`)

Code: `src/validation_case_iso47.jl`. Digitizers: `data/digitizers/p47/run_p47a.py`.

## Sources

| Figure | What | Use |
|--------|------|-----|
| NASA TP-2444 Fig. 17, PDF p. 32 | Exterior and interior narrowband spectra of model 2 (this test article: D 1016 mm, L 1803 mm, propeller plane 662 mm), the same 4000 rpm run, 0–1500 Hz | measured exterior and interior |
| NASA TP-2444 Fig. 19, PDF p. 34 | Space-averaged interior 1/3-octave spectra, model 2, θ_p = 135°, 4000 rpm, both rotation directions | digitized; reported, no case |
| NASA CR-172428 (`Pain Validation.pdf`) Fig. 14, PDF p. 38 | Free-field spectrum at microphone 1, run 8113, 5000 rpm, 0–2000 Hz | broadband slope for the 1600/2000 Hz extrapolation |

## 47a Digitizing (criterion: the two passes within 1 dB median and 3 dB p95 of points; tone peaks within one 5 Hz bin of H·BPF)

**Passes:**
- Fig. 17 and Fig. 14: pass A takes the centre of the ink run in each pixel column of the native page image. Pass B takes the top of the ink run, on a 600 dpi render (Fig. 17) or a 2× upscale (Fig. 14).
- Fig. 19: pass A is read by eye on zoomed crops with 1 dB guide lines. Pass B takes the band-centre ink runs.

| Trace | All points median / p95 (dB) | Broadband points (tones ±10 Hz out) | Tone peaks vs H·BPF | Verdict as written |
|-------|------------------------------|--------------------------------------|---------------------|--------------------|
| Fig. 17 exterior | 0.63 / 7.62 | 0.60 / 1.73 | H1 +6, H2 +3, H3 +7, H4 +2, H5 0, H6 −4, H7 +1 Hz | **not met** |
| Fig. 17 interior | 0.65 / 4.75 | 0.62 / 2.68 | H1 0, H2 −4, H3 −3 Hz; H4–H7 not identifiable (at or below the broadband) | **not met** |
| Fig. 14 | 0.87 / 4.07 | 0.83 / 3.69 | all 9–22 Hz below H·250 Hz | **not met** |
| Fig. 19 | 0.17 / 2.17 (max 8.85) | — | — | met |

**Causes.**
- **Tone lines.** The all-points misses are near-vertical tone lines, where the centre and top-of-ink rules differ by up to half the line's height.
- **Fig. 14 frequency axis.** It is drawn apart from the trace and is offset from it: every tone peak sits 9–22 Hz low, and the peak spacing is about 252 Hz. Frequencies are kept as calibrated from the ticks (fit residuals 0.36 dB and 4.5 Hz). 47b removes tone bins around the observed peaks as well as the nominal ones.
- **Fig. 19 maximum.** It comes from pass B reading the 6.3 kHz axis tick and swapping the two curves where they cross.
- **Broadband mask.** The "broadband points" columns leave out only ±10 Hz around the nominal H·BPF. Fig. 14's offset tones therefore stay in its broadband statistics; its 3.69 dB p95 includes tone skirts. This mask is a diagnostic, not the criterion, and the criterion counts all points.

**Primary data.** Pass A is primary for every figure.

## 47b Narrowband to 1/3-octave (criterion: exact on a synthetic flat spectrum) — met

`narrowband_third_octave`:
- **Bins.** 5 Hz bins (B = 5 Hz assumed, V-ASSUMED; TP-2444 does not state B). Each bin is the mean of the columns within ±B/2. A band holds the bins in [f_c·2^(−1/6), f_c·2^(1/6)).
- **Tone bins.** These are filled with the mean of the kept bins.
- **Partial bands.** These are scaled by bins in band / bins covered.

**Checks** (testset "T2 with the measured TP-2444 exterior (phase 47)"), all exact to 1e-9:
- Flat spectrum: L + 10 log10(n_bins).
- Flat spectrum with one tone bin raised 20 dB: total and broadband levels.
- Partial coverage.
- B = 10 Hz.

**Sensitivity to B at the 1250 Hz exterior band.** B = 2.5 Hz gives +4.3 dB and B = 10 Hz gives −3.9 dB. This carries dB for dB into the 47d interior; the 47c noise reduction does not depend on B.

## 47c `NR_PROP_TP2444` (criterion: within ±5 dB in ≥ 75 % of the broadband bands 315–1250 Hz) — not met, 1/7

The measured NR is L_ext − L_int, both broadband with tones removed (Fig. 17, pass A). The model is `noise_reduction_band` on `r172428_inputs(4000)` (CR-172428 App. B trim). It uses Eq. (18) below the card-10 band (f = 4.1 c₀/∛V = 1311 Hz, in the 1260 Hz band) and Eqs. (19)–(23) at and above it.

| Band (Hz) | L_ext | L_int | NR measured | NR pass B | NR model (App. B trim) | Δ | NR Phase III trim (no criterion) |
|-----------|-------|-------|-------------|-----------|------------------------|---|-----------------------------------|
| 315 | 90.07 | 54.05 | 36.02 | 36.43 | 16.55 (Eq. 18) | −19.5 | 16.80 |
| 400 | 90.65 | 58.85 | 31.80 | 29.34 | 13.51 (Eq. 18) | −18.3 | 16.83 |
| 500 | 87.64 | 54.66 | 32.98 | 32.97 | 7.53 (Eq. 18) | −25.5 | 11.89 |
| 630 | 87.06 | 57.03 | 30.04 | 29.46 | 4.96 (Eq. 18) | −25.1 | 10.85 |
| 800 | 86.87 | 54.58 | 32.29 | 31.91 | 8.71 (Eq. 18) | −23.6 | 18.96 |
| 1000 | 84.91 | 52.89 | 32.01 | 32.12 | 33.99 (Eq. 18) | +2.0 | 41.85 |
| 1260 | 85.42 | 51.51 | 33.91 | 33.96 | 49.08 (Eqs. 19–23) | +15.2 | 55.69 |

The Phase III column takes the sidewall, end and mechanical-path trim of `phase3_trim(η_lining = 1.0)` on this article's shell (m_wall = 3.113 kg/m²). The mechanical path's own wall mass (Eqs. A.20–A.21) is still the CR-3813 Phase III shell's.

The strict reading, which counts only the bands with no tone (315 and 500 Hz), gives 0/2.

## 47d `T2_MEAS_EXT` (criterion: 1250 Hz interior within ±3.5 dB of Fig. E-9, 51.0 dB) — not met

- **Exterior.** The 1250 Hz band level is 85.42 dB broadband (93.92 dB with tones; pass B 86.12 dB). Taken as the blocked pressure, it goes through T2's production broadband path with Eqs. (19)–(23) (`hf_broadband_band_p2`, T2 pipeline inputs).
- **Interior at 1250 Hz:** 21.25 dB, against 51.0 dB measured (E-9).
- **1600 and 2000 Hz, extrapolated exterior:** Fig. 14 slope +0.32 dB (pass B −0.04 dB; the 2000 Hz band is 43 % covered). The interiors are 19.66 and 19.89 dB, against 46.0 and 41.5 dB.
- **Secondary:** the Fig. 17 interior at 1250 Hz is 51.51 dB (not met, −30.3 dB).
- **Information, added after the first run (post-hoc):**
  - The same exterior through the production T2 surrogate (`broadband_cabin_p2`, calibrated bb_j2_scale = 0.5) gives 38.61 dB.
  - T2's own modelled blocked broadband level at 1250 Hz is 102.7 dB, 17 dB above the measured exterior.

## 47e Consistency loop (no criterion)

E-9 interior plus model NR (47c inputs) exceeds the measured or extrapolated exterior:

| Band (Hz) | Exceedance (dB) |
|-----------|-----------------|
| 1250 | 14.6 |
| 1600 | 18.9 |
| 2000 | 25.5 |

## Knock-on of Phase 49 (2026-10-23)

Eq. (20) now sums the modes below the band, as printed. Changes: T2_MEAS_EXT 1250 Hz interior 21.25 → 21.55 dB (1600/2000 Hz: 19.80, 19.92 dB); NR_PROP_TP2444 at 1260 Hz 49.08 → 49.01 dB. No verdict changes.

## Reading

**The measurements agree with each other.** TP-2444's exterior at 1250 Hz (85.4 dB) less its measured noise reduction (33.9 dB) gives 51.5 dB inside. E-9's mean for the CR-3813 test article at 4000 rpm is 51.0 dB.

**The gap is the noise reduction PAIN predicts.**
- **At 1250 Hz.** The printed Eqs. (19)–(23) give 49 dB with the App. B trim and 61 dB with the T2 inputs (Phase III trim), against 34 dB measured.
- **NASA's own predictions agree with ours.** NASA's printed PAIN predictions for the same article (CR-3813 Figs. E-21 and E-22, `nasa_pred_dB`) are 52–69 dB at 1250–2500 Hz, against 19.5–32 dB measured in the reverberant test. This code's 60–62 dB at 1250–2000 Hz (E-21 inputs) is close to them. So the overprediction belongs to the method as printed, not to this implementation.
- **Below the changeover.** Eq. (18) predicts too little noise reduction under propeller excitation: 5–17 dB against 30–36 dB.

**What this means for T2.** T2's production result near E-9 rests on two things: a modelled exterior 17 dB above the measured one, and the calibrated broadband scale. T2 cannot be shown right with the printed high-frequency method.

**Phase 45 qualified.** Phase 45 found Eqs. (19)–(23) right for a bare cylinder above 2.5 kHz. With trim they overpredict noise reduction by 15–27 dB at 1250 Hz.

**Candidate causes (not tested).** In Eq. (23), the trim and the wall transmit in series (τ_t·τ), with no path that bypasses the trim (frames, end caps, leaks). A double wall coupled through its frames transmits more than that product.
