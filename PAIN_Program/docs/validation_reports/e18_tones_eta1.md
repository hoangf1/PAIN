Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)

# E18_TONES — re-recorded at L = 1.83 m

Label: **V-CODE vs NASA E-18 prediction; V-EXP shown, held out; first run 2026-10-22**

## Verdict

**`not_met`** — 2/3 within ±4 dB of NASA E-18 prediction (H1–H3 → 200/400/630 Hz); η_T=1.0, η_r_cap=0.15 reaches tone=true; :auto secondary 88.67, 13.18, 67.39 dB

## Table

| quantity | x | reference | computed | residual | ok |
|---|---:|---:|---:|---:|:--:|
| vs NASA E-18 H=1 band=200.0 | 200.0 | 88.0 | 88.67433353350292 | 0.6743335335029172 | true |
| :auto H=1 band=200.0 | 200.0 | 88.0 | 88.67433353350292 | 0.6743335335029172 | false |
| measured mean H=1 (V-EXP held out) | 200.0 | 90.0 | 88.67433353350292 | -1.3256664664970828 | false |
| measured range H=1 (V-EXP held out) | 200.0 | 90.0 | 88.67433353350292 | -1.3256664664970828 | false |
| vs NASA E-18 H=2 band=400.0 | 400.0 | 75.0 | 77.78008173215471 | 2.780081732154713 | true |
| :auto H=2 band=400.0 | 400.0 | 75.0 | 13.176912419541516 | -61.823087580458484 | false |
| measured mean H=2 (V-EXP held out) | 400.0 | 80.0 | 77.78008173215471 | -2.219918267845287 | false |
| measured range H=2 (V-EXP held out) | 400.0 | 80.0 | 77.78008173215471 | -2.219918267845287 | false |
| vs NASA E-18 H=3 band=630.0 | 630.0 | 67.0 | 77.55296958644254 | 10.552969586442543 | false |
| :auto H=3 band=630.0 | 630.0 | 67.0 | 67.38515753427504 | 0.38515753427503796 | false |

inputs: (free_field = "ANOPP Table 8 (GEXT)", blocking = :R1, η_T = 1.0, η_r_cap = 0.15, tone_model = :eq8, bpf_Hz = 200.0, harm_bands = (200.0, 400.0, 630.0), n_ok = 2, n_nasa = 3, cap_reaches_tone = true, auto_dB = [88.67433353350292, 13.176912419541516, 67.38515753427504], eq8_dB = [88.67433353350292, 77.78008173215471, 77.55296958644254], criterion = "|Δ|≤4 dB vs NASA E-18 pred per harmonic", date = "2026-10-21", csv = "D:\\code\\PAIN\\rea-work\\data\\cr3813\\e18_interior_pred_eta1.csv")
