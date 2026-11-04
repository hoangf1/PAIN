# Phase 122: Commander 695A cabin tones against CR-178004 App. B (2026-11-03)

Case `AC_C695A_TONES` (block A_CABIN; information, no verdict under the Phase 118 input rule). Form fixed 2026-11-03,
written in `validation_case_iso121.jl` before the first run.

## Question

Phase 121 found PAIN's overall cabin dB(A) for the Commander 695A 13–18 dB under the measurement, mostly from broadband
PAIN does not model. Author 2026-11-03: compare only what PAIN models, the propeller tones.

## Data and runs

- Measured: CR-178004 App. B Tables B.7, B.8 (mic 3) and B.16, B.17 (mic 6), flight 3, each engine's cabin harmonics
  1–3, for the conditions where the two propellers turn at different rpm (1–4, 9, 10, 17, 18) or one is off (11, 12):
  108 levels (`data/cr178004/appB_flight3_cabin_harmonics.csv`, copied unchanged from Cabin_Noise's V7 data).
- PAIN: the AC_C695A_DBA runs unchanged (one per engine, pitch for the printed power, inputs in
  `examples/commander695a_cr178004.json`); each run's cabin harmonic levels H1–H3 (space average) against that
  engine's measured component at each microphone.

## Result (first run, 2026-11-03)

Recorded against the form, within ±4 dB (T1's gate width) at ≥ 68 % of the points: **27/108** (no verdict).
PAIN − measured = −18.3 to +12.2 dB, mean −6.7 dB.

| Group | Mean PAIN − measured (dB) | Within ±4 dB |
|---|---|---|
| H1 | −5.7 | — |
| H2 | −7.4 | — |
| H3 | −7.0 | — |
| port engine | −8.8 | 10/54 |
| starboard engine | −4.6 | 17/54 |
| mic 3 | −7.4 | 9/54 |
| mic 6 | −6.0 | 18/54 |

## Post-hoc diagnostic: the rotation signs (2026-11-03; nothing changed in the case)

Both propellers turn counter-clockwise from the rear (printed), so mirrored onto PAIN's one side they turn opposite
ways; which of PAIN's ±1 is port was assumed (port +1). In PAIN the sign also sets which quarter of the fuselage the
160-point grid covers (θ = φ_p ± (ℓ − 1)·10°, `grid_points`). Run once with the signs swapped: 30/108 within ±4 dB,
mean −6.7 dB; the engine given −1 comes out about 4 dB higher in both runs. So the port/starboard split follows the sign,
and the overall shortfall does not.

## Reading

PAIN's propeller tones in this cabin are about 6–7 dB low on average, with a wide spread (−18 to +12 dB) between
conditions and microphones; part of the spread is PAIN's cabin average against single microphones. Of Phase 121's
−15 dB(A), about 6–7 dB is the tones and the rest is broadband PAIN does not model. Inputs that could move the tones,
each to be fixed before any rerun: the blade (assumed; thickness noise off for lack of section data), the cabin section
and stiffeners (assumed; App. D warns the stringer spacing is outside the smeared model), the structural damping
(η_n = 0.05 default).
