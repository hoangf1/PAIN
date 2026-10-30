# Phase 108 — the floor term's sign in flight run 10 (2026-10-30, diagnostic)

Plan `IMPLEMENTATION_PLAN.md` §8ax (now in `COMPLETED_PHASES.md`); test fixed 2026-10-30 (commit 25f7acb) before any H1 or
H5 pair was computed. Case FLIGHT10_FLOOR_SIGN (diagnostic, `validation_case_iso108.jl`). η_r″ (Eq. 83) does not use the
field, so the cut H1/H5 field rows do not matter (a zero H5 field is appended only so the tone sum runs).

**Result: H_pre supported.** Of NASA's 10 printed H1/H5 pairs, η_r″ is within [0.4, 2.5]× NASA's at 8 with the floor term
subtracted and 5 with it added (H1: subtracted 0.35, 0.78, 0.65, 0.74, 0.19; added 1.21, 1.27, 3.01, 2.65, 0.65. H5:
subtracted 0.61, 0.61, 1.53, 0.67, 0.62; added 1.45, 0.22, 0.73, 0.39, 0.08). With Phase 103's H2–H4 pairs (14/14 within
[0.4, 2.5] subtracted), NASA's run 10 shows the pre-correction Eq. (52) sign: it was computed before CR-172428 App. A
item 2, while its printed field already carries item 3's 4 dB limit.

**Decision (the plan's rule).** `r172428_flight10_inputs(; floor_sign = −1)` by default, as a documented input of that NASA
run; no other default changes (App. B and every user path keep the corrected sign). FLIGHT10_H234 (diagnostic,
post-hoc): 94.60 / 87.44 / 83.89 dB against PAIN's 96.59 / 88.06 / 83.92 (−1.99 / −0.62 / −0.03); the trim per band
94.99 / 87.47 / 83.91 dB, now closer at 3/3 (by ≤ 0.4 dB; post-hoc, Phase 102's 0/3 stays on record).
