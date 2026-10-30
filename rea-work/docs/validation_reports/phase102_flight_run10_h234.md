# Phase 102 — CR-172428 flight run 10, H2–H4 (diagnostic, 2026-10-30)

Plan `IMPLEMENTATION_PLAN.md` §8ar, committed f00c03f before the run (now in `COMPLETED_PHASES.md`). No verdict:
FLIGHT_MODES (Phase 101a) is not met. The default does not change, whatever the result.

**Inputs.** All from CR-172428:
- Field: App. D pp. 231–233 (PDF 241–243), H2–H4, 16 × 19 points, `data/cr172428/appD_run10_H{2,3,4}.csv`.
- PAIN deck: App. D p. 229.
- Structure: the solver on NASA's Merlin deck (`merlin_mrp_deck()`).

Read as `r172428_flight10_inputs()`. Assumptions, all fixed before any level was computed:
- θ from the bottom centreline is 180° − the printed θ (printed from the vertical; the propeller line, 75°, carries
  the peak level).
- The printed field is used as the blocked field, as for App. B in Phase 44.
- The lowest 400 solver modes are used. NASA kept 20 per axial order and symmetry, which differs only near the top of
  the list.
- CYL2D uses NY = 11, because NY = 10 (Fig. C-3) gives complex eigenvalues at θ₀ = 50°. NY = 11 is the nearest grid
  that solves (9, 11, 16 and 20 solve; 8, 10, 12 and 14 do not).
- The insulation table is extended below 50 Hz for structural mode 1 (39.6 Hz; X-EXTRAP).
- There is no end-cap trim (deck zeros).

**Transcription.** Pass 1 was RapidOCR, both whole page and per cell. Pass 2 was by eye from deskewed full-table crops.
The plan's pass 2 was by eye for every cell, and that was kept; the OCR served as the comparison. 102 cells where both
OCR readings agreed with each other but not with the eye reading were re-read zoomed:
- 100 kept the eye reading (the print's 8 looks like 0 to the OCR).
- One was corrected to the OCR (H3 phase L19 k4, 169.3).
- One eye reading taken from smoothness was reverted to the printed glyph (H4 phase L3 k2, 90.5).

H4 phase L6 k3 sits on the ruled line (5 or 9); −99.3 follows the row and is flagged in the file. The amplitude rows
1–9 print the mirror of rows 19–11; the OCR of rows 1–9 agrees except H4 L8 k2, printed 90.9 against 90.8 in row 12.
Row 12's value is used.

**Result (FLIGHT10_H234).**

| Tone | PAIN printed (dB) | As shipped (dB) | Δ | Trim per band (dB) | Δ |
|---|---|---|---|---|---|
| H2, 209.1 Hz | 96.59 | 98.30 | +1.71 | 98.68 | +2.09 |
| H3, 313.6 Hz | 88.06 | 89.76 | +1.70 | 89.77 | +1.71 |
| H4, 418.1 Hz | 83.92 | 79.19 | −4.73 | 79.17 | −4.75 |

**H_bandtrim is not supported** (closer at 0/3). Taking τ_t and C_w at the band centre moves run 10 by at most 0.4 dB.
The trim per band is not what separates this code from PAIN here. The option stays, off by default, as
`trim_band_centre`. As shipped, the code is within 1.7 dB of PAIN at H2 and H3 on a second fuselage built from PAIN's
own deck, and 4.7 dB low at H4. This is information only: FLIGHT_MODES is not met, and the H4 shortfall is not
diagnosed.
