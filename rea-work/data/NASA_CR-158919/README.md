# NASA CR-158919 (BBN, static Aero Commander tests): digitized data

Source: `rea-work\NASA Contractor Report 158919.pdf` (103 pages). Transcribed 2026-10-20 by reading the page images (rendered at 110 dpi) and checked against the text layer.
Run numbers are the BBN numbers of Table 1 (run 4 has no BBN number; it is the port-engine-only run).

| File | Source (PDF page / printed page) | Content | Method | Uncertainty |
|---|---|---|---|---|
| `bbn_runs_table1.csv` | PDF 8 / p. 2, Table 1 | Runs, engines, rpm, blade-passage frequency (nominal and measured) | Typed from image | Exact as printed |
| `bbn_microphones_fig1.csv` | PDF 9 / p. 3, Figure 1 table | Microphone x, y (m) and distance from the tip for mics 3-6 | Typed from text layer and image | Exact as printed |
| `bbn_levels_table3.csv` | PDF 23 / p. 17, Table 3 | Overall tone levels (dB), 4 Hz resolution, all runs | Typed from image | Exact as printed |
| `bbn_levels_table4_2Hz.csv` | PDF 28 / p. 22, Table 4 | Overall tone levels, 4 Hz and 2 Hz, runs 7, 5, 2, 4 | Typed from image | Exact as printed |
| `bbn_trace_velocity_table8.csv` | PDF 41 / p. 35, Table 8 | Trace velocities (m/s), circumferential and longitudinal, averages | Typed from image | Exact as printed |
| `bbn_trace_velocity_table9.csv` | PDF 42 / p. 36, Table 9 | Ratio of measured to rigid-body circumferential trace velocity | Typed from image | Exact as printed |
| `bbn_appendixA_A-1_location1.csv` to `bbn_appendixA_A-11_location11.csv` | PDF 61-71 / pp. A-1 to A-11 | Harmonic spectral values (dB), per location, runs 1-8, 4 Hz | Read from page image (200 dpi, rotated) | Exact as printed; A-9 flags harmonics 3*, 4*, 7*; A-10 flags run 2 as suspect |
| `bbn_appendixA_A-12_port_engine_only.csv` | PDF 72 / p. A-12 | Port-engine-only run, harmonics x locations 1-11, 4 Hz | Read from page image | Exact as printed |
| `bbn_appendixA_A-13_run7_1700rpm_2Hz.csv` | PDF 73 / p. A-13 | Run 7 (1700 rpm), harmonics x locations 1-10, 2 Hz | Read from page image | Exact as printed |
| `bbn_appendixA_A-14_run5_2100rpm_2Hz.csv` | PDF 74 / p. A-14 | Run 5 (2100 rpm), harmonics x locations 1-10, 2 Hz | Read from page image | Exact as printed |
| `bbn_appendixA_A-15_run2_2400rpm_2Hz.csv` | PDF 75 / p. A-15 | Run 2 (2400 rpm), harmonics x locations 1-9, 2 Hz | Read from page image | Exact as printed |
| `bbn_appendixA_A-16_run4_2600rpm_2Hz.csv` | PDF 76 / p. A-16 | Run 4 (2600 rpm), harmonics x locations 1-10, 2 Hz | Read from page image | Exact as printed |
| `bbn_appendixB_B-1_calibration_sine_wave_pdf.csv` to `bbn_appendixB_B-6_fifth_harmonic_pdf.csv` | PDF 78-83 / pp. B-1 to B-6 | Probability density vs amplitude (sigma), Test Run 4, Location 6: calibration sine, harmonics 1-5 | Pixel trace of page image (110 dpi), calibrated to printed sigma ticks | Amplitude about +-0.02 sigma; density is relative (no density scale printed), normalized to peak. B-1 and B-2 outer step segments partly missed |
| `bbn_phase_coherence_CR158919_appendixC.csv` | PDF 86-95 / pp. C-2 to C-11 | Coherence and phase (deg) per pair, harmonic order and run (2600, 2400, 2100, 1700 rpm) | Typed from image, every page viewed | Exact as printed; pair 5-11 printed for run 4 only |

## Not digitized in this pass
- **Table 7** (PDF 38, p. 32): sample phase-angle analysis, mics 9-10, run 2. Used only to confirm the phase convention.
- **Table 5** (PDF 32) and **Table 6** (PDF 34): probability-density and enhancement results; not needed for phase.
- **Figs. 2-25** (plots: magnitude, coherence and phase spectra, time histories): not digitized. The sample coherence and phase spectra in Appendix C (Figs. C1-C8, PDF 85-105) are not digitized; the tables above cover the same pairs.

| `bbn_geometry.csv` | Fig. 1 + CR-159124 Tables 7–8 | Hub at rotation plane (`hub_x_m=0`), lateral offset 1.310 m (I-09); rotation `clockwise_from_rear` / blades upward at fuselage (author 2026-10-21) | Fit + I-09 relabel | Residual RMS 0.015 m |

## Coherence cut (phase 24)
- Coherence **below 0.15**: low confidence (flag in reports).
- Coherence **below 0.05**: drop the row from the 23a/23b comparison.

## Conventions
- Phase is in degrees as printed, range -180 to 180. Rotation sense for 24c is fixed by I-09 (opposite sense not run for the verdict).
- `-` in the phase/coherence CSV means not printed for that run and pair.

## Spot-check (I-14, 2026-10-21)
Five values checked against PDF page images (typed CSVs; exact as printed):
1. App. C pair 5-2 H1 run4: coh 0.99, phase 47° (PDF p. 86 / C-2).
2. App. C pair 4-3 H1 run4: coh 0.98, phase −46° (used in 24c).
3. Table 3 location 4 run4: 133.1 dB (PDF p. 17).
4. Table 8 pair 4-3 run4: 217 m/s (PDF p. 41).
5. Fig. 1 mic 5: x=0, y=0, tip distance 0.178 m (PDF p. 9).
Long reshape: `PAIN.jl/scripts/run/bbn_data.jl` → 748 rows (CR-158919 + CR-159124).
