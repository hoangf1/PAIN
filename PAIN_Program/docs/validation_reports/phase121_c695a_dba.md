# Phase 121: Commander 695A cabin dB(A) against CR-178004 flight 3 (2026-11-03)

Case `AC_C695A_DBA` (block A_CABIN; information, no verdict under the Phase 118 input rule). Form fixed 2026-11-03,
written in `validation_case_iso121.jl` before the first run.

## Question

Author (2026-11-03): "you really only need the inputs and then checking the final dba outputs if this is possible".
Run PAIN's aircraft path from the inputs CR-178004 gives for the Commander 695A and compare its overall cabin dB(A) with
the measured cabin dB(A).

## Inputs

| Input | Value | Source |
|---|---|---|
| Blades, diameter | 3, 2.69 m | CR-178004 (printed) |
| Tip clearance | 0.36 m | printed |
| Skin, frame spacing | 1.6 mm, 0.474 m (18.66 in) | printed |
| Propeller plane from cabin front | 56.5 in = 1.435 m (station 117 − 60.5) | printed |
| Rotation | both counter-clockwise from the rear; port +1, starboard −1 on PAIN's one side | printed; sign assignment assumed |
| Altitude, IAS, OAT, cabin altitude, rpm and shaft power per engine | Table 4, 18 conditions | printed |
| Blade | Aero Commander tip-A (`bbn_aerocommander_tipA.json`) scaled by 1.345/1.18 in radius and chord | assumed |
| Pitch | set per engine so the CCBlade torque = printed power / Ω (bisection) | from printed power |
| Cross-section | circular, a = 0.725 m (half the 1.45 m cabin height) | assumed |
| θ₀, L | 50° (auto, a = 0.725 m), 5.33 m | assumed |
| Stiffener sections, floor | CR-3813 test-article values | assumed |
| m_wall | 4.83 kg/m² (skin + smeared stringers and frames) | derived from assumed sections |
| η_n | 0.05 | PAIN default |
| Air | outside: ISA pressure at the pressure altitude, OAT; IAS = EAS. Cabin: the printed cabin altitude at 293.15 K | assumed temperature |
| Harmonics | 10 (H10 ≈ 790 Hz) | the aircraft grid's default |

dB(A): energy sum of the A-weighted 1/3-octave bands 63–5000 Hz, the same bands and A-weights (at PAIN's centres
1000·2^(k/3)) for PAIN and for the measurement. The measured bands are App. E Tables E.3 (mic 3) and E.6 (mic 6), read
2026-11-03 (`data/cr178004/appE_flight3_interior_third_octave.csv`).

## Result (first run, 2026-11-03)

Recorded against the form: measured dB(A) inside PAIN's ±3.5 dB (1σ) band at ≥ 68 % of the 36 points: **0/36**
(no verdict). PAIN − measured = −18.2 to −12.9 dB, mean −15.4 dB.

| Cond | PAIN dB(A) | Mic 3 | Mic 6 | PAIN − mic 3 | PAIN − mic 6 |
|---|---|---|---|---|---|
| 1 | 84.0 | 98.7 | 98.5 | −14.7 | −14.6 |
| 2 | 84.1 | 97.5 | 98.2 | −13.4 | −14.1 |
| 3 | 84.4 | 98.7 | 99.3 | −14.3 | −14.9 |
| 4 | 84.7 | 99.8 | 100.4 | −15.0 | −15.7 |
| 5 | 84.0 | 98.4 | 99.1 | −14.4 | −15.1 |
| 6 | 84.4 | 99.7 | 99.2 | −15.4 | −14.9 |
| 7 | 84.4 | 99.3 | 99.6 | −14.9 | −15.1 |
| 8 | 84.4 | 99.5 | 99.6 | −15.1 | −15.2 |
| 9 | 84.6 | 99.2 | 100.1 | −14.7 | −15.5 |
| 10 | 84.6 | 99.2 | 99.4 | −14.6 | −14.8 |
| 11 (stbd only) | 80.3 | 93.3 | 93.4 | −12.9 | −13.1 |
| 12 (port only) | 78.8 | 92.4 | 92.2 | −13.6 | −13.4 |
| 13 | 78.5 | 96.3 | 95.0 | −17.8 | −16.4 |
| 14 | 78.8 | 96.5 | 95.1 | −17.7 | −16.3 |
| 15 | 78.7 | 96.9 | 95.4 | −18.2 | −16.7 |
| 16 | 78.7 | 95.9 | 94.6 | −17.2 | −15.9 |
| 17 | 79.2 | 96.6 | 95.4 | −17.4 | −16.2 |
| 18 | 79.1 | 97.0 | 95.9 | −17.9 | −16.8 |

Pitch offsets 16.2–20.6° over the tip-A twist (tip blade angle about 42–47° at 114–153 m/s TAS).

## Where the gap is (post-hoc, condition 1, mic 3; nothing changed)

| Band (Hz) | Measured dB | Measured dB(A) | PAIN dB | PAIN dB(A) |
|---|---|---|---|---|
| 79 (BPF) | 106.5 | 83.9 | 100.5 | 77.9 |
| 157 (2×BPF) | 98.5 | 85.1 | 92.1 | 78.7 |
| 250 (3×BPF) | 100.3 | 91.6 | 85.5 | 76.8 |
| 315 | 90.8 | 84.2 | 73.8 | 67.1 |
| 400 | 89.8 | 85.0 | 65.3 | 60.5 |
| 500 | 89.0 | 85.8 | 55.1 | 51.8 |
| 630 | 92.8 | 90.9 | 28.5 | 26.6 |
| 800 | 90.3 | 89.5 | −1.2 | −2.0 |
| 1000 | 88.5 | 88.5 | 75.1 | 75.1 |
| 1250 | 86.5 | 87.1 | 71.2 | 71.8 |
| 1600 | 85.0 | 86.0 | 67.2 | 68.2 |
| 2000 | 82.3 | 83.5 | 63.2 | 64.4 |
| 4000 | 73.5 | 74.5 | 51.2 | 52.2 |

- The first two tones are about 6 dB under the measured bands (those bands also hold any broadband, so the tone gap may be smaller).
- PAIN's harmonics fall fast above H3 (H8 at 28.5 dB, H10 below 0 dB): F1A runs loading-only on this blade (no section
  data, t/c = 0), and loading noise at high harmonics is small.
- The measured dB(A) is set by 250 Hz–2 kHz (85–91 dB(A) per band). Below 1 kHz PAIN has only the tones; from 1 kHz its
  broadband is the propeller-driven Eq. (19) path (anchored to H3), 13–24 dB under the measurement. The measured
  broadband there will include the turbulent boundary layer, engine and structure-borne paths and cabin systems, which
  PAIN does not model.

- App. D warns on every run that the 0.686 m stringer spacing exceeds a quarter of the circumferential wavelength in
  all 32 modes (and the 0.474 m frame spacing in 10 of 32 axial ones): the smeared-stiffener structure is outside its
  range on this aircraft.

So on this aircraft PAIN's overall dB(A) is the propeller part only and comes out 13–18 dB under the measured cabin.
None of the inputs above was changed after the run.
