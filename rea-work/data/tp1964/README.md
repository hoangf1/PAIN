# NASA TP-1964 bare-cylinder noise-reduction data

Source: Willis, C. M.; Daniels, E. F. *Noise-reduction measurements of an unstiffened cylinder in a reverberant and propeller-noise environment.* NASA TP-1964 (1981).

## Geometry (TP-1964 symbols / text)

- Unstiffened aluminium cylinder, closed ends, no floor, no trim
- Exterior: diameter 0.508 m, length 1.245 m
- Interior: radius R = 0.252 m, length L = 1.193 m
- Wall thickness t = 0.00163 m; E = 6.89×10¹⁰ Pa; ν = 0.3; ρ = 2710 kg/m³
- Acoustic speed used in the report: c = 343 m/s

## Files

### `tp1964_fig8_noise_reduction.csv`

- **Figure:** Fig. 8, PDF p. 22 — space-averaged noise reduction of the cylinder in a pink-noise reverberant field
- **Columns:** `f_Hz`, `nr_meas_dB` (measured, solid), `nr_pred_ref2_dB` (predicted, ref. 2 = NASA CR-159363 Phase I model, dashed)
- **Digitization:** 2026-10-23 by eye on a 200 dpi render at the 1/3-octave band centres (axis ≈ 17.95 px/dB; uncertainty about ±0.5 dB)
- **Note:** Below 50 Hz the exterior field is not diffuse (TP-1964 p. 5); first measured point is the 50 Hz band

### `tp1964_fig17_reverberation.csv`

- **Figure:** Fig. 17, PDF p. 31 — measured decay (reverberation) times
- **Columns:** `kind` (`structural` or `acoustic`), `f_Hz`, `T60_s`, `eta` with η = 2.2/(f·T₆₀)
- **Digitization:** 2026-10-23 by eye on a 200 dpi render (axis ≈ 89.6 px/s; marker centres ±3 px, about ±0.04 s and ±1.5 % in f)
- **Use:** structural → η_r; acoustic → η_n (log-log interpolation in f, end values held)
