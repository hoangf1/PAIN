# Phase 125: Commander 695A cabin tones at the mic seats (2026-11-04)

Case `AC_C695A_SEAT` (block A_CABIN; information, no verdict under the Phase 118 input rule). Author 2026-11-04:
"Yes, add it" (a case comparing PAIN's level at the microphone seats, criterion fixed first).

## Why

CR-178004 Table 7: mics 3 (starboard) and 6 (port) are in the propeller plane, station 117 in, at the ear height of a
seated passenger. AC_C695A_TONES compares PAIN's cabin space average (Eq. 8) with them; the Phase 123 diagnostic found
PAIN's own H1 at the seat 3–7 dB above its space average. The like-for-like quantity is PAIN's level at the seat.

## Form (fixed 2026-11-04, in `validation_case_iso121.jl`, before the first run)

PAIN's Eq. (8) point form (`point_tone_p2`, Phase 42: coherent over cabin modes, mean square over structural modes;
its volume average is Eq. (8)) at the interior node nearest the seat: z = 1.435 m (117 − 60.5 in), |X| = 0.45 m,
1.0 m above PAIN's floor. Each engine's H1–H3 from the AC_C695A_DBA runs against App. B's 108 levels, as
AC_C695A_TONES; recorded against ±4 dB at ≥ 68 %. Disclosure: the seat values were those of the condition-1
diagnostics, chosen before any seat level was seen; condition 1's seat levels were then seen. PAIN's point field is
left–right symmetric, so mics 3 and 6 get the same PAIN level; PAIN's circular cabin is 1.19 m high (the real one
1.45 m), so the ear height is taken from PAIN's floor.

## Result (first run 2026-11-04)

43/108 within ±4 dB (the space average, AC_C695A_TONES after the Phase 123 fix: 32/108). PAIN − measured −10.3 to
+26.4 dB, mean +5.4 dB. Seat − space average: H1 +5.3, H2 +1.1, H3 +3.8 dB.

| PAIN − measured, mean (dB) | H1 | H2 | H3 |
|---|---|---|---|
| All 108 | −0.2 | +9.3 | +7.3 |
| Port engine (rotation +1) | −3.1 | +4.1 | +4.5 |
| Starboard engine (rotation −1) | +2.6 | +14.4 | +10.1 |

At the seat H1 agrees on average. H2 and H3 are high, mostly on the starboard engine.

## The starboard excess (post-hoc diagnostic; open item I-18)

With the propeller at φ_p = 90°, rotation +1 lays the 10-line grid on the upper quarter (θ 90°→180° from the bottom)
and rotation −1 on the lower quarter (90°→0°, across the floor junction at 50°). The two engines therefore load
different parts of the shell. NASA's PAIN generates both quarters (CR-172428 §3: "PAIN then generates data for an
identical grid on the lower quarter surface of the fuselage nearest the propeller (using the data input for the upper
grid)"; App. B prints the 19-line field, amplitudes of rows L and 20 − L equal). The code uses the 160 stated points
(decision 19d; I-18's dated rule of 2026-10-21 keeps them unless 38b explains H3). Whether to adopt the lower quarter
is the author's decision; the diagnostic below bounds its effect and changes nothing.

Condition 1, H1 / H2 / H3 (dB). Amplitudes mirrored to the opposite quarter (θ = φ_p − sense·α); the lower-quarter
phase rule is not printed (App. B's lower-quarter phases are not a copy: L = 1 32.1°, L = 19 −134.5° at 4000 rpm H1),
so two bounds: phases copied, and conjugated about ℓ = 1.

| Engine | Measured mic 3 | Measured mic 6 | Seat, 10 lines (as shipped) | Seat, 19 lines, phases copied | Seat, 19 lines, conjugated |
|---|---|---|---|---|---|
| Port (+1) | 106.6 / 92.3 / 94.3 | 108.3 / 97.6 / 87.6 | 100.4 / 103.8 / 98.2 | 100.7 / 112.4 / 101.4 | 101.6 / 111.4 / 102.6 |
| Starboard (−1) | 91.7 / 97.7 / 99.5 | 100.3 / 88.3 / 85.7 | 103.1 / 108.7 / 94.3 | 100.2 / 111.0 / 94.5 | 100.0 / 110.6 / 95.5 |

The lower quarter brings the two engines together (seat H2 111–112 dB on both), but it raises the port H2 by about
8 dB, so the H2 excess grows. I-18 is not the cause of the high H2 and is left as decided. The H2/H3 excess stays with
the assumed structure and cabin damping (Phase 123 report: a dense set of resonant pairs near 157 Hz, damping at PAIN's
defaults).

## Noise reduction: source and transmission apart (post-hoc diagnostic, 2026-11-04)

NR = exterior flush-mic level (App. A) − cabin level (App. B), per engine, harmonic and mic, means over the 9 conditions
each; PAIN's NR is its AC_C695A_EXT level − its seat level. The source error is AC_C695A_EXT's (PAIN − measured).

| Engine, H | NR measured mic 3 / mic 6 (dB) | NR PAIN at the seat | PAIN − measured NR, mic 3 / mic 6 | Source error |
|---|---|---|---|---|
| Port H1 | 29.3 / 23.9 | 35.8 | +6.5 / +11.9 | +6.2 |
| Port H2 | 32.3 / 32.4 | 31.0 | −1.3 / −1.4 | +2.7 |
| Port H3 | 31.6 / 40.5 | 32.1 | +0.6 / −8.4 | +0.6 |
| Starboard H1 | 31.6 / 27.4 | 33.1 | +1.5 / +5.7 | +6.2 |
| Starboard H2 | 31.5 / 31.3 | 20.5 | −11.0 / −10.8 | +3.6 |
| Starboard H3 | 29.9 / 38.8 | 27.4 | −2.5 / −11.3 | +3.2 |

- On the port engine (upper-quarter grid) PAIN's H2 transmission is within 1.4 dB of the measured; its seat H2 excess
  (+4.1 dB) is mostly the source's (+2.7 dB).
- The measured H2 NR is the same for both engines (31.5 vs 32.3 dB at mic 3), as the mirror-symmetric aircraft
  requires; PAIN's differs by 10.5 dB between them. The H2 excess is the starboard run's (rotation −1, lower-quarter
  grid), which transmits 11 dB too much.
- H1 is transmitted 2–12 dB too weakly on both engines, while the source is 6 dB high: the airborne path alone does not
  carry the measured H1 (the whole-fuselage response noted in the Phase 123 report).

Where on the starboard grid the excess enters (cond 1; grid θ 0–90° from the bottom, floor junction θ0 = 50°;
amplitudes of the other points zeroed):

| Starboard loading | Space average H1 / H2 / H3 (dB) | Seat H1 / H2 / H3 (dB) |
|---|---|---|
| All 10 lines | 99.7 / 106.5 / 90.3 | 103.1 / 108.7 / 94.3 |
| Above the floor junction only (θ 50–90°) | 101.4 / 105.4 / 90.3 | 104.0 / 107.4 / 93.7 |
| Below it only (θ 0–40°) | 93.8 / 95.8 / 81.5 | 91.0 / 96.3 / 85.6 |

Loading below the floor adds at most 1.3 dB. The excess enters through the sidewall strip just above the floor
junction, which only the rotation −1 grid loads. With NASA's two-quarter grid (I-18 table above) both engines load
that strip, and both seat H2 values rise to 111–112 dB. So the lower-sidewall transmission at H2 is about 10 dB too
strong, and the shipped single-quarter grid hides it on the port engine. Its inputs are assumed (the stiffener
sections, a circular section with a floor at 50°, the floor's own structure), and none is chosen here.

Which structural mode (cond 1, H2 space average, Eq. (8) summed over cabin modes per structural mode r):

| r | f_r (Hz) | M, n, symmetric | Port (H2 157.3 Hz) | Starboard (H2 152.0 Hz) |
|---|---|---|---|---|
| 74 | 155.4 | 2, 2, yes | 99.9 dB (63 %) | 105.7 dB (82 %) |
| 68 | 144.2 | 2, 6, no | 91.2 dB (8 %) | 91.8 dB (3 %) |
| 61 | 138.5 | 2, 6, yes | 92.4 dB (11 %) | 85.9 dB (1 %) |
| Total | | | 102.0 dB | 106.5 dB |

One shell mode (n = 2, coupled to the floor) carries the H2 of both engines. The lower-quarter loading drives it 5.8 dB
harder, although the starboard tone lies farther from it (2.2 % against 1.2 %). The 18 conditions run at 1515–1573 rpm,
so every H2 (151.5–157.3 Hz) falls within 2.5 % of this mode, and its half-power band at PAIN's default
η_r′ = C_struc/f ≈ 0.019 is ±1 %. The H2 comparison is therefore set by one mode's frequency, shape and damping, all
from assumed inputs (the stiffener sections, the circular section with a floor at 50°, C_struc = 3). This is the
"dense set of resonant pairs" of the Phase 123 report, resolved: it is mainly one mode.

H3 (cond 1) has no single carrier: port 93.0 dB, of which 32 % is mode r = 123 (235.7 Hz, M = 5, n = 4) against a
236.0 Hz tone; starboard 90.3 dB, spread over r = 128, 125, 122 and 118 (228.8–241.2 Hz). The measured H3 NR is
9 dB larger at mic 6 than at mic 3 for both engines, a left–right difference that PAIN's symmetric point field
cannot show; at mic 3 PAIN's port H3 NR is within 0.6 dB.

## Does PAIN predict a loud speed near 1550 rpm? (post-hoc diagnostic, 2026-11-04)

The H2 of 1554 rpm (155.4 Hz) sits on the shell mode above. Condition 1's power and flight state, rpm 1500–1600 (pitch
set for the power), H2 in dB:

| rpm (H2 Hz) | Port space avg | Port seat | Starboard space avg | Starboard seat |
|---|---|---|---|---|
| 1500 (150) | 102.1 | 98.4 | 104.5 | 106.0 |
| 1520 (152) | 101.4 | 99.2 | 106.5 | 108.7 |
| 1550 (155) | 101.2 | 102.3 | 110.4 | 113.4 |
| 1570 (157) | 101.8 | 103.7 | 112.2 | 115.2 |
| 1600 (160) | 102.8 | 104.2 | 113.8 | 115.7 |

There is no peak at 1550. The H2 rises steadily with rpm: by +0.4 dB (port, space average) to +5.7 dB (starboard) from
1520 to 1570 rpm. The 155.4 Hz mode acts together with the cabin mode at 160.8 Hz, and a mode with η_r′ ≈ 0.02 has a
±1 % half-power band. The measured H2 (App. B, mics 3 and 6) does not follow this: the mean at 1515–1525 rpm is 94.1 dB
(20 values) and at 1570–1573 rpm 94.6 dB (16 values), with a ±4 dB spread between conditions at the same rpm. The
flight data have no engine between 1533 and 1570 rpm. PAIN's rpm trend at H2 comes from one mode built on assumed inputs
and is not supported by the data; it is not a prediction to quote.

## Not changed

No input, criterion or production default changed after the run.
