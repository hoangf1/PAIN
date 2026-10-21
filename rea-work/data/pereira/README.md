# Pereira et al. (2026) digitized data

Source: Pereira, Ragni, Romani, Casalino, *Aerosp. Sci. Technol.* 177 (2026) 112963 (`Pereira.pdf` in `rea-work`).
Raster figures extracted from the PDF at 300 ppi and traced by colour; QA overlays are in `data/figures/`.
Scripts: `data/digitizers/dig_per7.py`, `harm_per7.py`, `dig_per1b.py` (they expect the extracted page images in the working folder; paths inside are from the session that produced them).

| File | Figure | Content |
|------|--------|---------|
| `pereira_fig7_digitized.csv` | Fig. 7 (a) φ = 0°, (b) 20°, (c) 40° | Raw traced points: p' (Pa) vs propeller phase angle (deg) for BEMT-based, numerical (CFD) and experimental curves |
| `pereira_fig7_digitized_clean_1deg.csv` | same | Outliers removed, interpolated to 1° steps |
| `pereira_fig7_harmonics.csv` | same | Least-squares fit p' = mean + Σ A_k cos(2k·θ − ψ_k), k = 1, 2 (B = 2, so harmonic k of the blade-passing frequency has 2k cycles per revolution). ψ_k is in degrees of that harmonic's own cycle (divide by 2k for degrees of propeller rotation) |
| `pereira_fig1b_chord_twist.csv` | Fig. 1(b) | c/R and twist (deg) vs r/R, 0.30 to 0.99 |
| `pereira_tables3_4.csv` | Tables 3 and 4 (PDF p. 5, 7) | Thrust/torque/power/C_T/C_P and OSPL / OSPL(A) at φ = 0° for BEMT, numerical, experimental (typed 2026-10-21, card C-04) |
| `pereira_fig9_harmonics.csv` | Fig. 9 (PDF p. 10) | SPL and ΔSPL vs BEMT for BEMT/Numerical/Experimental, H1–H7 (H8–10 flagged out_of_panel on a/b); pass A, ~1 dB; H1 Exp φ=0 = 88.95 dB matches Fig.7 peak (87.2); script `digitizers/dig_pereira_fig9.py`; QA `qa/pereira_fig9_overlay.png` |
| `pereira_fig6_peaks.csv` | Fig. 6 (PDF p. 7) | Spectrum peaks at H1–H4 of BPF=266.7 Hz, panels φ=0/20/40; pass A; script `digitizers/dig_pereira_fig6.py`; QA `qa/pereira_fig6_overlay.png` |

Uncertainty (my estimate, not independent): 2 pixels in x is 1° of propeller rotation, which is 2° in the first-harmonic phase; 2 pixels in y is about 0.004 Pa. Only one digitization pass was made, so this shows repeatability of the method at most. Coverage of the BEMT-based curve is 80–85% of the 1° bins (the rest interpolated); at φ = 20° its fit residual (0.033 Pa) is larger than at the other angles, so treat that curve with less confidence. The second-harmonic amplitudes (0.03–0.08 Pa) are comparable to the fit residuals, so second-harmonic phases are low confidence. The experimental curve is the phase-locked average of 4,000 rotations; the shaded bands in the figure (broadband deviation) were not digitized.
