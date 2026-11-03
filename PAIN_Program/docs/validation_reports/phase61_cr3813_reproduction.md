# Phase 61: is the code the same as PAIN as NASA ran it for CR-3813?

Run 2026-10-23 at the author's request ("if something isnt closed out add to implementations and close it out"). Criteria were fixed 2026-10-23 in `IMPLEMENTATION_PLAN.md` §8h, before any run. Testset: "CR-3813 reproduction with NASA's pre-correction form (phase 61)", 172/172.

## Why

The T2 high-frequency gap is recorded as a limitation of the method. That rests on the code reproducing PAIN.

- **Against CR-172428**, which used NASA's corrected program, it does: H3 is within 0.4 dB (App. B field), and NASA's printed mode pairs agree within 1.1 % (9/10, 44f).
- **Against CR-3813's own printed outputs** it did not: REPRO_18b was 0/3 and E21_E22_NR V-CODE was 0/4.

CR-3813's runs predate NASA's correction of the sign of the Eq. (52) floor term (CR-172428 p. 178). Phase 61 runs that pre-correction form to see whether it reproduces them.

## Results (first run; criteria unchanged)

**61a: met.**
- The new input `floor_sign` defaults to +1, the corrected form; the default leaves every recorded value unchanged.
- With −1, f′ equals ax·(I_s − I_p)/den by hand for 80 mode pairs (1e-12).
- Values other than ±1 are rejected.

**61b `REPRO_18b_PRE`: not met, 1/3.**

| Harmonic | Pre-correction form | Corrected form | NASA E-16 prediction |
|----------|---------------------|----------------|----------------------|
| H1 | 85.93 dB | 89.03 dB | 79.0 dB |
| H2 | 78.32 dB | 81.24 dB | 75.5 dB |
| H3 | 79.57 dB | 77.06 dB | 68.0 dB |

The pre-correction sign moves H1 and H2 about 3 dB toward NASA and H3 2.5 dB away.

**61c `E21_PRE`: not met, 1/4 counted bands** (63, 200, 250, 315 Hz; the ten-mode crossover is at 400 Hz, as in 38a).
- 400–630 Hz (not counted): within 0.6–1.9 dB of NASA.
- 63 Hz: 58.4 against 16 dB.
- 800–1000 Hz: 6–18 dB above NASA.

**61d `E22_HF_CODE`: not met, 1/4.**
- Code − NASA at 1250, 1600, 2000 and 2500 Hz: +7.7, +2.1, −6.5, −5.6 dB.
- NASA − measured at the same bands: +32.5, +33.5, +43.5, +37.0 dB.

## Closed as

**Differences not explained by the documents.**

- The floor-sign correction does not reproduce CR-3813's printed runs.
- CR-3813 does not print the program state of those runs: its field input, blocking factor, mode file and any other differences from the CR-172428 program.
- No further documented candidate exists. Phases 19, 43c and 44 tried the input alternatives.

## What this means for the limitation statement

- **Against NASA's corrected program (CR-172428)** the code reproduces PAIN closely: H3 within 0.4 dB, pairs within 1.1 %.
- **Against CR-3813's printed runs** differences remain: 3–11 dB on the tones, 2–8 dB on the high-frequency NR, up to 18 dB at 1000 Hz in Eq. (18). The documents do not explain them.
- **The T2 high-frequency gap** is still attributed to the method, not the code. NASA's own printed high-frequency NR misses the measurement by 32–44 dB, which is 4–20 times the code-to-NASA difference. The attribution is to the method within the stated code-to-NASA difference, not to an exact reproduction.

## Code review of the 2026-10-23 changes (9d8129b..f5f6cdf)

Fixed:
- The printed-outputs coupling table now applies `floor_sign` to its floor column, so the shell and floor parts add up to f.
- `coupling_factor` rejects a `floor_sign` other than ±1. `_with_fields` bypasses the constructor check, so the check sits where the value is used.
- `propeller_field_band_nr` refuses a field that is not the 16 × 19 App. B layout, because its reference index assumes that layout.
- `structural_modes(include_floor = false)` uses the whole circle for the shell modal mass.
- The Phase 48 polar set is loaded once.
- `qa_two_pass.qa_csv` closes its files.

Kept, as documented decisions or small effects:
- BPM ignores the induced velocity (48b decision).
- E22_BR uses nominal band centres (< 1 % in band edge).
- The O(N·bins) scan in `narrowband_third_octave`.
- Hard-coded numbers in the T2 reason text.

No recorded value changed.
