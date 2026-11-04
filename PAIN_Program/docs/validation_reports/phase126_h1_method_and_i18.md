# Phase 126: is the H1 shortfall PAIN's or the recreation's? I-18 closed against NASA's output (2026-11-04)

Author 2026-11-04: "have you proved that h1 is a pain limitation rather than my code yes you have full control to
close out any open items". Diagnostics and a decision. No code, input, criterion or recorded result changed.

## 1. The H1 chain on the one article where NASA's PAIN output exists

CR-172428's 1.016 m test article: NASA's inputs, NASA's printed PAIN predictions, and the measured 196-microphone space
average (Table 10, App. B). This code as it ships (default form, Phases 93/96):

| H1 | Measured (dB) | NASA PAIN (dB) | This code (dB) | Code − NASA | NASA − measured |
|---|---|---|---|---|---|
| 3000 rpm (150 Hz) | 81.0 | 63.3 | 63.4 | +0.1 | −17.7 |
| 4000 rpm (200 Hz) | 90.3 | 91.7 | 91.8 | +0.1 | +1.4 |
| 5000 rpm (250 Hz) | 100.2 | 86.4 | 86.6 | +0.2 | −13.8 |

The default form's two tone-sum choices were taken from this run's printouts (Phases 92–93), so this table alone is not
independent. The independent check is NASA's second run of the same article (Table 12, trim loss factor η_T = 2.0),
which no choice used (Phase 94, criteria fixed 2026-10-29 before the run): R172428_ETAT2 **met** 9/9, H1 within
+0.24 / +0.34 / +0.27 dB at 3000 / 4000 / 5000 rpm. The structural modes come from Table D-1, which this code's App. D
solver reproduces 32/32 within 0.012 % (MRP_APPD).

**Conclusion (test article): proved within the evidence.** This code reproduces NASA's PAIN at H1 within 0.3 dB on a
held-out NASA run, and NASA's PAIN is 14–18 dB under the measured H1 at 3000 and 5000 rpm. The shortfall is PAIN's
method, reproduced, not added by the recreation. The test article had no wing, so this low H1 is not a structure-borne
path: PAIN's airborne model itself under-predicts H1 there.

## 2. The Commander 695A

NASA never ran PAIN on the 695A (CR-178004 compares only with two simplified procedures), so no printout exists to
prove the same thing directly. What the evidence supports:

- The cabin chain (blocking, CYL2D, coupling, loss factors, Eq. 8) is the one verified above. The 695A run differs only
  in its source (CCBlade/F1A, not NASA's) and its structural modes (App. D from assumed stiffeners, not Table D-1).
- The source is not why H1 is low: PAIN's exterior H1 is 6.5 dB **above** the App. A flush microphone (AC_C695A_EXT).
- The App. D modes carrying H1 (73.7 and 77.3 Hz) are already converged at NASA's own series limits (card 8: M ≤ 10,
  n ≤ 12) and in the first 32 modes, so the Phase 123 cutoff rule does not touch H1 (32 modes: 93.2 dB; cutoff rule:
  93.4–93.7 dB, condition 1 port).
- The deficit is in transmission: PAIN's H1 noise reduction exceeds the measured by 2–12 dB on both engines (Phase 125
  report), the same direction as NASA's own PAIN on the test article.

**Conclusion (695A): consistent with PAIN's method, not proved.** The recreation's chain is proved on the test article,
and the 695A-specific links (source, App. D) either push H1 up or do not affect it. A proof on the 695A would need a
NASA PAIN run of the 695A, which does not exist.

## 3. I-18 (lower-quarter grid) closed against NASA's output

CR-172428 §3 says PAIN "generates data for an identical grid on the lower quarter". Decision 19d (2026-10-20) used the
160 upper-quarter points; I-18's author rule (2026-10-21) adopted mirroring only if Phase 38b explained H3, which it did
not (2026-10-22). Test here: the same mirrored field as the Phase 125 diagnostic (amplitudes mirrored about ℓ = 1,
App. B rows L and 20 − L equal; phases copied, or conjugated about ℓ = 1, the rule not being printed) against both of
NASA's printed runs. This code − NASA PAIN, H1–H3 at 3000 / 4000 / 5000 rpm:

| Grid | Table 12, η_T = 2.0 (held out) | Within ±3 dB | App. B, η_T = 0.13 | Within ±3 dB |
|---|---|---|---|---|
| 10 lines (as shipped) | +0.24 +1.30 +1.49 / +0.34 +0.55 +1.73 / +0.27 +0.72 −0.16 | 9/9 | +0.14 +0.82 +1.19 / +0.11 +0.28 +0.59 / +0.19 +0.30 −0.76 | 9/9 |
| 19 lines, phases copied | +6.07 +6.16 +5.63 / +6.79 +5.56 +4.35 / +7.29 +6.69 +1.12 | 1/9 | +5.74 +5.39 +5.76 / +5.50 +4.96 +2.81 / +5.55 +6.00 +0.72 | 2/9 |
| 19 lines, conjugated | −1.66 +4.92 +2.46 / +3.13 +0.17 +4.67 / +3.20 +4.02 +2.59 | 4/9 | −1.44 +4.40 +1.96 / +2.77 −1.91 +3.53 / +0.78 +3.38 +1.86 | 6/9 |

NASA's printed levels are reproduced only without the lower quarter in Eq. (8). However NASA's program used the lower
grid it generated (output item 7), it did not add it to the tone sum that produced these levels. **I-18 is closed:
the 160-point grid stays** (the existing decision, now supported by NASA's output, including a held-out run). The
Phase 125 starboard/port difference is therefore PAIN's single-quarter form applied to the 695A's two engines, not a
departure from PAIN.

## Open after this phase

- Q22 stays as closed on 2026-10-23: CR-3813's printed tone sum (q = 0 cabin modes coupled) is 13 dB above NASA's
  CR-172428 output at 4000 rpm H1; NASA's later program drops those terms, as the held-out Table 12 run confirms for
  the default form. The documents do not say why.
- The 695A H2 (one floor-coupled shell mode from assumed inputs) and H3 (a left–right difference PAIN's symmetric field
  cannot show): Phase 125 report. They are not recreation defects, and no assumed input is chosen to fit them.
