# Phase 48: the exterior broadband from physics (NASA RP-1218)

Run 2026-10-23. Criteria fixed 2026-10-23 in `IMPLEMENTATION_PLAN.md` §8d (commit 5f55041). The 48b–48d implementation decisions were fixed the same day, before any comparison with Fig. 14, Fig. 17 or E-9.

Source: Brooks, Pope & Marcolini, *Airfoil Self-Noise and Prediction*, NASA RP-1218 (1989), `references/NASA_RP_1218.pdf`, downloaded from NTRS 2026-10-23.
- SHA-256 `0c22690c6216c4355c0da7e09ce0d1a1dd96a2b88d3d8abda30e293b3db76006`.

Code:
- `src/bpm_airfoil_noise.jl`: RP-1218 §5.
- `src/prop_broadband.jl`: blade-segment sum, as in RP-1218 App. C.
- `src/validation_case_iso48.jl`.

## 48a `BPM_RP1218`: met, 270/270

The port reproduces NASA's printed code output, App. D Tables D2 and D3 (`data/rp1218/`):
- **Table D2:** one untripped NACA 0012 segment (Fig. 45a case).
- **Table D3:** ten tripped segments with a rounded tip (Fig. 91 case).

| Mechanisms | Max deviation |
|------------|---------------|
| TBL-TE pressure and suction, separation, LBL-VS | 0.04 dB |
| Tip | 0.19 dB |

All 270 points are within the 1 dB criterion.

Not ported: trailing-edge bluntness (neither table uses it, and the test blade's trailing-edge thickness is unknown).

## 48b Propeller broadband at a field point (model)

**Blade (V-ASSUMED).** The real blade geometry is proprietary (CR-172428 p. 56). The stand-in is the NACA 4-(5)(08)-03 planform of Report 996 (NACA 16-series sections):
- scaled to D = 0.762 m;
- 3 blades;
- β(0.75R) = 20° and 23.8 m/s inflow (CR-172428 p. 17);
- the Report 996 primary polars.

**Procedure** (as RP-1218 App. C):
- untripped boundary layers;
- the aerodynamic angle for the boundary layer and TBL-TE, the geometric angle for LBL-VS;
- 16 azimuths with a Doppler shift, times B.
- Sections with a negative aerodynamic angle are computed at α = 0. This detail of the code was not in the dated decision list; it was found in the code review (2026-10-23), concerns only the innermost section, and no result was used to choose it.

**Operating point.** The sections run at α_aero ≈ 3–14°.

**Dominant mechanism.** Separation noise dominates at both rpm. Suction-side TBL-TE comes next, about 10 dB lower, and tip noise is negligible.

## 48c Against the measured broadband floors (criterion ±5 dB in ≥ 75 % of bands): both not met

The measured side is the 47b broadband levels (pass A, tones removed, B = 5 Hz).

| Band (Hz) | Fig. 14 meas. (5000 rpm) | BPM | Fig. 17 ext. meas. (4000 rpm) | BPM |
|-----------|--------------------------|-----|-------------------------------|-----|
| 315 | 94.6 | 89.6 | 90.1 | 74.8 |
| 400 | 94.0 | 91.3 | 90.7 | 76.5 |
| 500 | 104.2 | 92.6 | 87.6 | 78.0 |
| 630 | 96.0 | 93.8 | 87.1 | 79.4 |
| 800 | 104.8 | 94.8 | 86.9 | 80.5 |
| 1000 | 104.7 | 95.5 | 84.9 | 81.3 |
| 1250 | 104.2 | 95.8 | 85.4 | 82.3 |
| 1600 | 105.5 | 95.5 | — | — |
| 2000 | 104.5 | 94.9 | — | — |

Results:
- **`PROP_BB_FIG14`:** 3/9 bands.
- **`PROP_BB_FIG17`:** 2/7 bands (1000 and 1250 Hz within 3.6 and 3.1 dB).

BPM is low everywhere: by 3–10 dB against Fig. 14 and by 3–15 dB against Fig. 17, more at low frequencies.

Two limits apply:
- **Near field.** Both microphones are within about 0.3 m of the tip, nearer than BPM's far-field basis (X-EXTRAP).
- **Sources BPM leaves out.** BPM covers airfoil self-noise only. Propeller broadband also includes inflow-turbulence ingestion (the test ran in a tunnel jet), which BPM does not model.

## 48d `T2_PRED_BB` (T2's gate): not met

The BPM exterior at the Fig. 17 point is 82.3, 83.2 and 83.8 dB at 1250, 1600 and 2000 Hz. Taken as the blocked pressure through T2's Eqs. (19)–(23), it gives 18.4, 17.4 and 17.9 dB, against E-9's 51.0, 46.0 and 41.5 dB. The miss is set by the cabin path's high-frequency noise reduction (Phase 47, Phase 49), not by the exterior. The BPM exterior is within about 3 dB of the measured one at 1250 Hz.

## Reading

- **The self-noise code is verified exactly** against NASA's printed outputs.
- **The exterior broadband sits below the measurement.** With an assumed blade and a near-field observer, BPM self-noise is 3–15 dB below the measured floors. Self-noise alone does not explain the measured broadband at these points.
- **What stops T2 is the cabin.** Even a correct exterior would leave T2 about 30 dB low, because PAIN's trimmed-wall noise reduction above 1 kHz is too high (Phase 47; NASA's own statements, Phase 49).
