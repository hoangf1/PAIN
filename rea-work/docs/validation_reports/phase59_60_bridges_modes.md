# Phases 59–60: Sharp sound bridges (NASA CR-172490) and the App. D mode extension

Run 2026-10-23 at the author's request ("implement fixes in phases until everything closes any questions"). Criteria and the mapping were fixed 2026-10-23 in `IMPLEMENTATION_PLAN.md` §8g before any run. Testset: "Sharp sound bridges and the App. D mode extension (phases 59, 60)", 20/20.

Source: May, Plotkin, Selden & Sharp, *Lightweight sidewalls for aircraft interior noise control*, NASA CR-172490 (1985), `references/NASA_CR_172490.pdf`, downloaded from NTRS 2026-10-23.
- SHA-256 `1c1ea678…0d49d22`.
- It was found by a wider NTRS search after Phase 51 had been closed for lack of a source.

Code:
- `src/sharp_bridges.jl`.
- Option `bridges` in `hf_pressure_ratio` / `hf_broadband_band_p2` / `noise_reduction_band`, off by default.
- `src/validation_case_iso59.jl`.

## Phase 59

### 59a `SHARP_PANEL_D` (source check): not met, 3/13

CR-172490 Fig. 15 (Panel D, 0 Pa) was digitized into `data/cr172490/`. The construction uses:
- **Below f₀:** Eq. (5) at normal incidence for the combined mass, with Eq. (22) for f₀.
- **f₀ to f_b:** an 18 dB/octave rise.
- **Above f_b:** the mass law + ΔTL_M, with f_b where the two meet.

Inputs:
- **Skins and cavity:** two 1.6 mm aluminium skins and the 82.6 mm cavity (Fig. A-7). The computed f₀ is 140.1 Hz; the stated value is 142 Hz.
- **ΔTL_M:** 12 dB, as stated.

Result: 3 of 13 points within 1 dB, max 1.4 dB. Two things cause the misses:
- **Mass law about 1 dB low.** At 63 Hz the construction gives 12.6 dB against 13.6 dB read from the figure, which corresponds to a slightly higher mass or a lower ρc than the report used.
- **Bridged line about 1.3 dB high.** The figure's high-frequency offset over its own mass law is 10.2 dB, not the "order of 12 dB" of the text. Eq. (25) with the drawn spacer lattice (190 × 476 mm) gives 16.3 dB, so the source does not pin ΔTL_M for its own example.

Post-hoc diagnostic, no criterion: with the figure's 10.2 dB the construction follows every point within 1.08 dB, a near-constant 1 dB offset. Its shape (6 / 18 / 6 dB per octave, kink positions) reproduces the source.

### 59b The bridge option

The bridge path is added in parallel with Eq. (23)'s trim–wall series path τ_t·τ over the trimmed area:

τ_B = τ_ML(m_s + m_t)·[10^(−ΔTL_pt/10) + 10^(−ΔTL_ln/10)]

Inputs, as mapped on 2026-10-23:
- **Critical frequency.** f_c = 25.7 kHz, the higher of the skin and G-10 trim values.
- **Point connections.** Nine on the curved trim area, a lattice e = 0.66 m, giving ΔTL_pt = 33.6 dB.
- **Line connections.** Two lines at spacing b = 1.09 m, giving ΔTL_ln = 19.5 dB.

Checks: off reproduces Eq. (23) exactly, and τ_B and the denominator match the hand values to 1e-12.

### 59c–59e: all not met

| Case | Without bridges | With bridges | Measured / gate |
|------|-----------------|--------------|-----------------|
| `NR_PROP_TP2444_BR`, 1260 Hz NR | 49.0 dB | 42.8 dB | 33.9 dB; 1/7 bands (bridges act only in the Eq. 23 band) |
| `E22_BR`, NR 1250 / 1600 / 2000 / 2500 Hz | 59.7 / 61.6 / 62.5 / 63.4 dB | 52.2 / 53.4 / 53.7 / 54.3 dB | E-22 mean 19.5 / 26.0 / 25.5 / 32.0 dB; 0/4 inside the interval |
| `T2_MEAS_EXT_BR`, interior 1250 / 1600 / 2000 Hz | 21.6 / 19.8 / 19.9 dB | 28.4 / 27.6 / 28.4 dB | E-9 51.0 / 46.0 / 41.5 dB |

**Reading.** With the documented connection set, Sharp's bridges remove about 7 dB of predicted noise reduction above 1 kHz. That is a quarter of the roughly 30 dB excess.

To close the rest, ΔTL_M would have to be about 0 dB, meaning the trim is rigidly connected everywhere. Equivalently, about 40 times more connections would be needed than the 9 points and 2 lines in the Phase III description. Neither is documented.

E-22's reverberant noise reduction also includes end-plate transmission (CR-3813 p. E-35), which this sidewall model leaves out.

## Phase 60

### 60a: not met, so Phase 60 stops

App. D modes per 1/3-octave band (n_axial = 7, n_circ = 8, as `MRP_APPD`), against the production asymptotic density:

| Band (Hz) | App. D / asymptotic |
|-----------|---------------------|
| 1000 | 15 / 6.5 (2.32×) |
| 1260 | 15 / 10.3 (1.46×) |
| 1587 | 19 / 16.3 (1.17×) |
| 2000 | 5 / 25.9 (0.19×) |

The pre-registered factor-of-2 consistency fails at 1000 and 2000 Hz. Below 820 Hz the App. D solver also gives 61 modes where Table D-1 lists 32, and at 2 kHz its basis runs out.

Neither set gives a trustworthy mode count above 811 Hz. The extension was not adopted, and 60b and 60c were not run.

## Code against NASA's printed PAIN output at high frequency (2026-10-23, author: "if it proves that the outputs are the same as pain in that aspect then its fine stating" it is a limitation of the method)

CR-3813 article, E-22 settings (trim loss factor 1.0, η_r′ ≤ 0.15). This code uses Eqs. (19)–(23) as printed, without bridges.

| Band (Hz) | This code | NASA's printed PAIN (E-22) | Code − NASA | Measured (E-22 mean) | NASA − measured |
|-----------|-----------|----------------------------|-------------|----------------------|-----------------|
| 1250 | 59.7 | 52.0 | +7.7 | 19.5 | +32.5 |
| 1600 | 61.6 | 59.5 | +2.1 | 26.0 | +33.5 |
| 2000 | 62.5 | 69.0 | −6.5 | 25.5 | +43.5 |
| 2500 | 63.4 | 69.0 | −5.6 | 32.0 | +37.0 |

**Reading.**
- **Code against NASA.** The code is within 2–8 dB of NASA's own output. That is not a band-by-band reproduction: NASA's curve rises more steeply with frequency, and the exact high-frequency path of the 1983 program is not printed.
- **NASA against the measurement.** NASA's output itself exceeds the measured noise reduction by 32–44 dB, four to twenty times the code-to-NASA difference.

**Conclusion.** The 30–40 dB high-frequency excess is therefore a **limitation of the PAIN methodology** as NASA ran it: the trim model is valid to about 1 kHz (CR-172428 p. 152) and over-estimates the sidewall treatment (CR-3813 p. E-35). It is not an artefact of this implementation.

At low frequency the code reproduces NASA within 0.4 dB (H3, App. B field) and pair by pair within 1.1 % (44f).

## Status after Phases 59–60

The documents support no further fix for T2's high-frequency gap:
- **Inside PAIN:** Phase 49.
- **NASA's own statements:** the trim model over-estimates the sidewall treatment and is valid to about 1 kHz.
- **Sharp's bridge extension:** closes about 7 dB with the documented connections.
- **A larger mode set:** not consistent (Phase 60).

What remains open is a property of the method and its inputs, as documented by NASA. It is not a defect in this code.
