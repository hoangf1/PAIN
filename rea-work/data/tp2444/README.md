# NASA TP-2444 and CR-172428 Fig. 14 spectra (Phase 47)

Sources:
- Willis, C. M.; Mayes, W. H.; Daniels, E. F. *Effects of propeller rotation direction on airplane interior noise levels.* NASA TP-2444 (1985), `references/NASA_TP_2444.pdf`. Its "model 2" is this test article: D = 1016 mm, L = 1803 mm, propeller plane 662 mm from the front, tip clearance 76 mm, fiberglass trim, 4000 rpm, 23.8 m/s inflow.
- NASA CR-172428, `references/Pain Validation.pdf`, Fig. 14.

Digitized 2026-10-23 with `data/digitizers/p47/run_p47a.py <work_dir>`. The script extracts the page images from the PDFs into `<work_dir>`, runs both passes, writes these CSVs, and leaves the QA summary (`qa_p47a.json`) and an overlay (`f14_overlay.png`) in `<work_dir>`.

## Files

| File | Figure | Columns |
|------|--------|---------|
| `tp2444_fig17_exterior_passA.csv`, `_passB.csv` | TP-2444 Fig. 17, PDF p. 32: exterior narrowband spectrum, 0–1500 Hz | `f_Hz`, `L_dB`, `L_top_dB`, `L_bottom_dB` |
| `tp2444_fig17_interior_passA.csv`, `_passB.csv` | TP-2444 Fig. 17: interior narrowband spectrum (same run) | as above |
| `tp2444_fig19_interior_third_octave.csv` | TP-2444 Fig. 19, PDF p. 34: space-averaged interior 1/3-octave spectra, θ_p = 135°, clockwise (solid) and reversed (dashed) | `f_Hz`, `cw_passA_dB`, `rev_passA_dB`, `cw_passB_dB`, `rev_passB_dB` |
| `../cr172428/cr172428_fig14_mic1_5000rpm_passA.csv`, `_passB.csv` | CR-172428 Fig. 14, PDF p. 38: free-field spectrum at microphone 1, run 8113, 5000 rpm, 0–2000 Hz | as Fig. 17 |

## Columns and passes

- **Column traces.** One row per pixel column. `L_dB` is the plotted level: the centre of the ink run in pass A, its top in pass B. `L_top_dB` and `L_bottom_dB` are the ends of the ink run; a near-vertical tone line spans them.
- **Fig. 17 and Fig. 14 passes.** Pass A uses the native page image. Pass B uses a 600 dpi render (Fig. 17) or a 2× upscale (Fig. 14).
- **Fig. 19 passes.** Pass A is read by eye on zoomed crops with 1 dB guide lines. Pass B takes the band-centre ink runs; its curves can swap where they cross.
- **Primary pass.** Pass A is primary everywhere.

## Calibration

| Figure | Calibration |
|--------|-------------|
| Fig. 17 | Tick marks: x 0 Hz at 671 px and 1500 Hz at 1999.5 px; exterior ticks 130…60 dB (0.0599 dB/px); interior ticks 100…20 dB (0.1039 dB/px). |
| Fig. 14 | The page is rotated 90°. Fit to 13 level ticks and 11 frequency ticks (residuals 0.36 dB, 4.5 Hz). The trace ends at 1981 Hz. |
| Fig. 19 | 7 level ticks, and 9 frequency ticks at every third band. |

**Fig. 14 frequency offset.** Its frequency axis is drawn separately and is offset from the trace: every tone peak falls 9–22 Hz below H·250 Hz. The frequencies in the CSV are as calibrated from the ticks.

## Analysis bandwidth

TP-2444 does not state B. Phase 47 assumes B = 5 Hz (V-ASSUMED), because CR-172428 Fig. 17, from the same laboratory, states 5 Hz.

## QA (Phase 47a, criterion fixed 2026-10-23)

| Trace | All points median / p95 (dB) | Broadband points median / p95 (dB) | Result |
|-------|------------------------------|------------------------------------|--------|
| Fig. 17 exterior | 0.63 / 7.62 | 0.60 / 1.73 | not met as written |
| Fig. 17 interior | 0.65 / 4.75 | 0.62 / 2.68 | not met as written |
| Fig. 14 | 0.87 / 4.07 | 0.83 / 3.69 | not met as written |
| Fig. 19 | 0.17 / 2.17 | — | met |

Tone peaks against H·BPF:
- Fig. 17 exterior: within 7 Hz (H1 +6 Hz, H3 +7 Hz).
- Fig. 17 interior: H1–H3 within 4 Hz.
- Fig. 14: 9–22 Hz low.

Details: `docs/validation_reports/t2_measured_exterior.md`.
