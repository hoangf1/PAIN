# NASA CR-159124 (BBN, taxi tests): digitized data

Source: `rea-work\NASA Contractor Report 159124.pdf` (146 pages). Transcribed 2026-10-20 by reading the page images (110 dpi) and checked against the text layer. Taxi speeds are in knots; runs as in Table 1 of the report.

| File | Source (PDF page / printed page) | Content | Method | Uncertainty |
|---|---|---|---|---|
| `bbn_runs_table1.csv` | PDF 15 / p. 3, Table 1 | Runs 1-7: taxi speed, rpm, blade-passage frequency, measurement locations | Typed from image | Exact as printed |
| `bbn_microphone_distances_table7.csv` | PDF 60 / p. 48, Table 7 | Hub-to-microphone distance, mics 3, 4, 5, 6 | Typed from image | Exact as printed |
| `bbn_angular_separation_table8.csv` | PDF 60 / p. 48, Table 8 | Angular separation at the hub, pairs 3-4, 4-5, 5-6 | Typed from image | Exact as printed |
| `bbn_levels_table3.csv` | PDF 31 / p. 19, Table 3 | Overall tone levels by location and run (dB) | Typed from image | Exact as printed |
| `bbn_levels_table4_enhanced.csv` | PDF 42 / p. 30, Table 4 | Enhanced (e) and unenhanced (u) overall levels, static, 30 kt, 70 kt | Typed from image | Exact as printed |
| `bbn_trace_velocity_table6.csv` | PDF 59 / p. 47, Table 6 | Circumferential trace velocities (m/s) and ratios, pairs 4-3, 5-3, 5-4, 0-70 kt | Typed from image | Exact as printed |
| `bbn_trace_velocity_table9.csv` | PDF 62 / p. 50, Table 9 | Longitudinal trace velocities (m/s), pairs 5-1, 5-8, 5-9, 8-9 | Typed from image | Exact as printed |
| `bbn_appendixA_A-1_CR159124_static_runs1_4.csv` | PDF 79 / p. A-1, Table A-1 | Harmonic 1-20 magnitude (dB), static, runs 1 and 4, locations 1,3,4,5,8,9, 2 Hz | Typed from image | Exact as printed; '-' = not printed |
| `bbn_appendixA_A-2_CR159124_taxi30_40kt_runs2_3.csv` | PDF 80 / p. A-2, Table A-2 | Harmonic 1-16 magnitude (dB), 30 kt and 40 kt taxi, locations 1,5,8,9, 2 Hz | Typed from image | Exact as printed |
| `bbn_appendixA_A-3_CR159124_taxi40_55_70kt_runs5_6_7.csv` | PDF 81 / p. A-3, Table A-3 (rotated in PDF) | Harmonic 1-19 magnitude (dB), 40, 55, 70 kt taxi, locations 3,4,5,11, 2 Hz | Typed from image (page rotated 90 deg) | Exact as printed |
| `bbn_appendixB_B-1_CR159124_enhanced_static_runs1_4.csv` | PDF 85 / p. B-1, Table B-1 | Enhanced harmonic 1-10 magnitude (dB), static, locations 1,3,4,5,8,9, plus enhanced and unenhanced overall | Typed from image | Exact as printed |
| `bbn_appendixB_B-2_CR159124_enhanced_taxi30_70kt_runs2_7.csv` | PDF 86 / p. B-2, Table B-2 | Enhanced harmonic 1-10 magnitude (dB), 30 kt (locations 1,5,8,9) and 70 kt (locations 3,4,5), plus overall | Typed from image | Exact as printed |
| `bbn_harmonic_phase_table_C1_static.csv` | PDF 89 / p. C-1, Table C-1 | Harmonic 1-20 phase (deg), static, locations 1,3,4,5,8,9 | Typed from image; re-checked against page image 2026-10-20 | Exact as printed |
| `bbn_harmonic_phase_table_C2_loc5_taxi.csv` | PDF 90 / p. C-2, Table C-2 | Harmonic 1-20 phase (deg) at location 5, 0, 30, 40, 70 kt | Typed from image; re-checked against page image 2026-10-20 | Exact as printed. Column 0 kt equals C-1 location 5 (cross-check passed) |
| `bbn_phase_coherence_CR159124_appendixD.csv` | PDF 94-97 / pp. D-2 to D-5 | Coherence and phase (deg) per pair, harmonic and taxi speed, 2600 rpm | Typed from image, every page viewed | Exact as printed |
| `bbn_phase_vs_freq_fig19_longitudinal_APPROX.csv` | PDF 56 / p. 44, Figure 19 | Phase vs frequency, longitudinal pairs 5-1 and 5-8, 0 and 30 kt | **By eye, approximate** (not a pixel trace); +/- 15 Hz, +/- 0.1 pi | Check each point against the PDF before quantitative use |

## Not digitized in this pass
- **Figure 1** (PDF 16): schematic with a scale bar; no coordinates are printed. Locations must be measured from the figure or taken from CR-158919 Figure 1 (same array) if you want numbers.
- **Figure 18** (PDF 55, p. 43): phase vs frequency, circumferential pairs 5-4 and 5-3 at 0 and 70 kt. Digitized with WebPlotDigitizer on 2026-10-21:
  - `fig18b_pair5-3_circumferential_phase_digitized.csv`: 0 kt (9 points) and 70 kt (9 points). Calibration: x = 0 Hz at page px 453, 1000 Hz at px 1279; y = 0 rad at px 841, -5pi at px 1676. Uncertainty about +-10 Hz, +-0.05 rad.
  - `fig18a_pair5-4_circumferential_phase_digitized.csv`: 0 kt and 70 kt (10 points each). The first 70 kt export duplicated 0 kt and was replaced on 2026-10-21. Frequency axis for panel (a) is assumed to match (b); not verified.
- **Figure 19** pair 5-1 and 5-8 readings are approximate (see above). Fitted lines in the figure are not transcribed.
- **Figure 20** (PDF 57, p. 45): phase vs frequency, longitudinal, not digitized.
- **Figures 5-17, 21-25** (magnitude, coherence and time-history plots, PDF 32-73): not digitized.
- **Figures D1-D8** (PDF 98-105): sample coherence and phase spectra; not digitized, the tables cover the same pairs.
- **Table 2** (PDF 29) and **Table 5** (PDF 49): not needed for phase.
- **Appendix E** (PDF 107-140): cabin interior levels, not needed for the phase check.

## Coherence cut (phase 24)
- Coherence **below 0.15**: low confidence (flag in reports).
- Coherence **below 0.05**: drop the row from the 23a/23b comparison.

## Conventions
- Phase is in degrees as printed. Table 6 and Table 9 trace velocities are positive in the upward direction (as printed). Rotation direction is **not printed** (see `../NASA_CR-158919/bbn_geometry.csv`); step 24b runs both signs.
- `**` = no data acquired or suspect; `-` = not printed.
