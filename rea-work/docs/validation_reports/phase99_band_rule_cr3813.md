# Phase 99 — did CR-3813's program already use the band-centre η_n? (2026-10-30)

Plan `IMPLEMENTATION_PLAN.md` §8ao, committed 8f02a4a before the run (now in `COMPLETED_PHASES.md`). Hypothesis
H_band: the program behind CR-3813's printed runs already evaluated η_n at the nominal band centre (Phase 95). It is
tested with the q = 0 modes coupled, the floor sign −1 and the printed Eq. (82). The decision was fixed before the run:
H_band is supported only if both cases are met.

| Case | Criterion | Band-centre η_n (dB) | η_n at the tone (dB) | NASA (dB) | Result |
|---|---|---|---|---|---|
| BAND_REPRO_18b (99a) | ±4 dB at H1–H3 vs E-16 | 84.56, 77.60, 81.58 | 85.11, 77.61, 81.85 | 79.0, 75.5, 68.0 | 1/3 |
| BAND_E18 (99b) | ±4 dB per harmonic vs E-18 | 87.63, 77.05, 78.96 | 87.88, 77.06, 79.31 | 88.0, 75.0, 67.0 | 2/3 |

**H_band is refuted.** The rule moves CR-3813's runs by at most 0.6 dB. H3 stays 11–14 dB above NASA's E-16 and E-18
predictions with or without it, so that gap does not come from the damping rule. The runs use the digitized E-11
exterior field with the assumed grid extension. CR-3813 does not print the full field PAIN used, so its input stays
the leading candidate (H3_ATTRIB). `_pre_correction_form` is unchanged.

**Also checked (2026-10-30, diagnostic, not kept as a case).** For CR-172428's nine levels with the code as it ships, NASA's
printed admittance (App. B p. 197) was substituted for this code's in the band-centre η_n. The levels moved by at most
0.2 dB. So the remaining level differences (within 2 dB at eight points; 3000 rpm H3 at +3.5 dB, a 450 Hz tone 3 Hz above
the 400/500 Hz band edge) do not come from the trim admittance in η_n.
