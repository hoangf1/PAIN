# Phase 123: Commander 695A exterior tones, and the App. D mode-truncation fix (2026-11-03/04)

Case `AC_C695A_EXT` (block A_CABIN; information, no verdict under the Phase 118 input rule). Form fixed 2026-11-03,
written in `validation_case_iso121.jl` before the first run. Author 2026-11-03: "why is it so far off", then "yes find
the cause and fix it".

## Question

AC_C695A_DBA (Phase 121) put PAIN 13–18 dB(A) under the measured 695A cabin, and AC_C695A_TONES (Phase 122) put the
tones 6.7 dB low on average. Is the source low, or the transmission into the cabin?

## The source alone (AC_C695A_EXT)

CR-178004 App. A prints each near propeller's H1–H3 at a flush microphone on the fuselage, 7.5 cm forward of the
propeller plane at the tip clearance (Table 8): a blocked surface pressure, the quantity PAIN feeds its cabin. PAIN's
blocked field on grid line ℓ = 1 (the propeller azimuth), interpolated in dB between k_p and k_p − 1 to 7.5 cm forward,
is compared with it. 101 points (18 conditions × 2 near propellers × 3 harmonics, less port 11 and starboard 12, whose
near propeller was shut down, and port 15 H1, illegible). Data: `data/cr178004/appA_flight3_exterior_harmonics.csv`,
copied unchanged from Cabin_Noise's V5 file.

**Result (first run 2026-11-03).** 53/101 within ±4 dB; PAIN − measured −2.0 to +8.8 dB, mean **+4.0 dB** (H1 +6.5,
H2 +3.3, H3 +2.2 dB). The source is high, not low. Example, condition 1 port H1: measured exterior 130.0 dB, cabin
106.6 dB (noise reduction 23.4 dB); PAIN's cabin H1 was 41.6 dB under its exterior. The shortfall was in transmission.

## Cause: the structural mode set was truncated

`run_pain_pipeline` kept the 32 lowest App. D modes (`n_keep = 32`), sized for the 1.8 m test article, whose 32 modes
reach 811 Hz. On the 695A (L = 5.33 m, a = 0.725 m) the 32 lowest end at **105 Hz**, below H2 (157 Hz). Every tone above
the 32nd mode was carried only by off-resonance modes. NASA's own series limits (User Manual card 8: M ≤ 10, n ≤ 12)
also miss modes on a long cabin: with 10 axial terms there are 239 modes under 472 Hz, with 40 there are 359.

**Fix (rule fixed 2026-11-03, before it was used; Phase 123).** `appd_modes_to_cutoff`:

- every App. D mode up to the cutoff 2 × the highest tone of the run, rounded up to the next 100 Hz (so runs at nearby
  rpm share one cached set), with at least 32;
- the axial and circumferential series limits are doubled from NASA's 10 / 12 until a doubling adds at most 1 % (at
  least 2) to the count below the cutoff. Ritz frequencies settle from above, so an exact count never settles: at
  1600 Hz, 24 → 48 circumferential terms moved the count 529 → 531.

Table D-1, Ritz and the uncertainty caches are unchanged. On the 695A: 396 modes under 500 Hz (n_harmonics = 3),
3270 under 1600 Hz (n_harmonics = 10), built in 5 and 21 s and cached.

Convergence (condition 1 port, H1–H3 space average): 32 modes 93.2 / 87.4 / 83.5 dB; with the cutoff rule at
n_harmonics 3 / 5 / 10: 93.4 / 102.1 / 92.7, 93.7 / 102.0 / 93.0, 93.6 / 102.0 / 93.1 dB, so it is converged within
0.5 dB.

## Reruns with the fix (post-hoc; the fix was found from this data, not fitted to it)

| Case | First run (32 modes) | Rerun 2026-11-04 |
|---|---|---|
| AC_C695A_DBA (36 points, ±3.5 dB) | 0/36, mean −15.4 dB(A) | 35/36, PAIN − measured −1.6 to +3.8, mean +0.7 dB(A) |
| AC_C695A_TONES (108 points, ±4 dB) | 27/108, mean −6.7 dB | 32/108, mean +2.0 dB (H1 −5.5, H2 +8.2, H3 +3.4) |
| AC_C695A_EXT (101 points, ±4 dB) | 53/101, mean +4.0 dB | unchanged (the fix does not touch the source) |

The dB(A) agreement is partly compensation: H2 is about 8 dB high while H1 is 5.5 dB low and PAIN leaves out the
250 Hz–2 kHz broadband the measurement carries. No verdict either way (Phase 118).

## Why H1 is low and H2 high (post-hoc diagnostics, condition 1; nothing changed)

| Check | Port H1 | Starboard H1 |
|---|---|---|
| Measured, mic 3 / mic 6 | 106.6 / 108.3 | 91.7 / 100.3 |
| PAIN space average | 93.5 | 99.7 |
| PAIN at the propeller-plane seat (point form) | 100.4 | 103.1 |

- The mics are in the propeller plane (CR-178004 Table 7); PAIN's H1 there is 3.4–6.9 dB above its own space average
  (H2 +1.8, H3 +3.5 on the port run). Case AC_C695A_SEAT (Phase 125) compares the seat level.
- Cabin length ±10 %: H1 ±1.6 dB. q = 0 cabin modes coupled (CR-3813 tone sum): H1 +1.5 dB. Port rotation sign
  flipped: H1 +4.2 dB but H2 +10.6 dB (worse overall). 20 → 40 CYL2D 2-D modes: H1–H8 within 0.5 dB, dB(A) −0.08.
- The measured port H1 is nearly the same on the far mic (106.6) as on the near one (108.3); for the starboard
  propeller the far mic is the louder. An airborne sidewall field should be louder on the near side; this looks like a
  whole-fuselage response such as the structure-borne path of a wing-mounted engine, which PAIN does not model. NASA's
  own PAIN is 14–18 dB under the measured H1 of its test article at 3000 and 5000 rpm (CR-172428 Table 10).
- H1 is carried by structural modes at 73.7 and 77.3 Hz; H2 (157 Hz) 55 % by one pair, structural mode 74 (155.4 Hz,
  M = 2, n = 2) with cabin mode (q = 1, i = 2) at 160.8 Hz. Scaling all structural frequencies by 0.94–1.06 moves the
  port H2 by −1.5 to +1.2 dB (100.5–103.2 dB) and H1 within 92.1–97.3 dB: the H2 excess is not one coincidence.
- Loss factors in those pairs are PAIN's defaults: η_r′ = C_struc/f (C_struc = 3; 0.024–0.042) and η_n = 0.05 for a
  bare cabin. The flight-3 cabin had four seats, four people and instrumentation; its acoustic damping is not printed
  and is not chosen here (that would be tuning).
- App. D warns on every run that the 0.686 m stringer spacing exceeds a quarter of the circumferential wavelength in
  every mode: the smeared-stiffener structure is outside its range on this aircraft, with assumed sections.

So the remaining per-tone scatter traces to assumed inputs (stiffener sections, circular cabin, cabin damping) and to
the airborne-only path, not to a code defect found here.

## Other runs the fix touches

`run_pain_pipeline` with `:appd` (parametric aircraft path): AC_CABIN_DEMO (an identity check; its dB(A) value
changes, the check does not), the aircraft uncertainty cache and the GUI's aircraft runs. The test-article path uses
Table D-1 and is unchanged; `build_testarticle_cache` keeps its own 32 App. D modes.

## Also fixed

Three App. D unit tests had failed since Phase 107 (MRPMOD's 5 shell / 3 floor terms by default) because they
checked full-series properties: the J1 junction test and the unit-peak test now ask for the full series, and the
deck test checks the 5-term budget.
