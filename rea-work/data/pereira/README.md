# Pereira et al. (2026) digitized data

Source: Pereira, Ragni, Romani, Casalino, *Aerosp. Sci. Technol.* 177 (2026) 112963 (`Pereira.pdf` in `rea-work\references`).
Raster figures extracted from the PDF at 300 ppi and traced by colour; QA overlays are in `data/cr3813/pages/`.
Scripts: `data/digitizers/dig_per7.py`, `harm_per7.py`, `dig_per1b.py` (they expect the extracted page images in the working folder; paths inside are from the session that produced them).

| File | Figure | Content |
|------|--------|---------|
| `pereira_fig7_digitized.csv` | Fig. 7 (a) φ = 0°, (b) 20°, (c) 40° | Raw traced points: p' (Pa) vs propeller phase angle (deg) for BEMT-based, numerical (CFD) and experimental curves |
| `pereira_fig7_digitized_clean_1deg.csv` | same | Outliers removed, interpolated to 1° steps |
| `pereira_fig7_harmonics.csv` | same | Least-squares fit p' = mean + Σ A_k cos(2k·θ − ψ_k), k = 1, 2 (B = 2, so harmonic k of the blade-passing frequency has 2k cycles per revolution). ψ_k is in degrees of that harmonic's own cycle (divide by 2k for degrees of propeller rotation) |
| `pereira_fig8_directivity.csv` | Fig. 8 (a)–(f), PDF p. 9 | Tonal SPL vs microphone angle φ = −20° to 40°, BPF harmonics 1–6, BEMT / numerical / experimental; flags for hidden markers and values outside the plotted range | Pixel digitization of the embedded image (`data/digitizers/dig_pereira_fig8_pixels.py`, 2026-10-21); QA overlay `qa/pereira_fig8_pixels_overlay.png`; ±0.3 dB visible markers, ±1 dB hidden |
| `pereira_fig1b_chord_twist.csv` | Fig. 1(b) | c/R and twist (deg) vs r/R, 0.30 to 0.99 |
| `pereira_tables3_4.csv` | Tables 3 and 4 (PDF p. 5, 7) | Thrust/torque/power/C_T/C_P and OSPL / OSPL(A) at φ = 0° for BEMT, numerical, experimental (typed 2026-10-21, card C-04) |
| `pereira_fig9_harmonics.csv` | Fig. 9 (PDF p. 10) | Author WebPlotDigitizer → schema (I-15, 2026-10-21); H1=80 dB all series accepted (I-15 d); Fig. 8 vs Fig. 9 H1 scatter for phase 28 |
| `pereira_fig6_peaks.csv` | Fig. 6 (PDF p. 7) | Author curve exports Fig 6a/b/c.txt; peaks = max in ±5% of m·BPF (I-15); cross-check vs Fig.9 recorded at phase 28, not corrected |

**I-10 (chord, 2026-10-21):** two digitizations of Fig. 1(b) agree (c/R ≈ 0.216 at 0.3R, 0.17 at 0.7R, 0.135 at 0.8R). Chord at 0.75R is c/R ≈ 0.152 → 22.9 mm at R = 0.15 m ≈ paper's 22.85 mm "mean chord" (likely the 0.75R chord, not an area mean). Geometry used as digitized; do not rescale.

Uncertainty (my estimate, not independent): 2 pixels in x is 1° of propeller rotation, which is 2° in the first-harmonic phase; 2 pixels in y is about 0.004 Pa. Only one digitization pass was made, so this shows repeatability of the method at most. Coverage of the BEMT-based curve is 80–85% of the 1° bins (the rest interpolated); at φ = 20° its fit residual (0.033 Pa) is larger than at the other angles, so treat that curve with less confidence. The second-harmonic amplitudes (0.03–0.08 Pa) are comparable to the fit residuals, so second-harmonic phases are low confidence. The experimental curve is the phase-locked average of 4,000 rotations; the shaded bands in the figure (broadband deviation) were not digitized.
