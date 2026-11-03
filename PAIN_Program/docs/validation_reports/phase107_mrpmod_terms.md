# Phase 107 — MRPMOD's 5 shell / 3 floor terms on the solver path (2026-10-30)

Plan `IMPLEMENTATION_PLAN.md` §8aw (now in `COMPLETED_PHASES.md`). Code-on-code fix: `appd_modes` keeps the 5 largest
shell and 3 largest floor coefficients per mode (`n_keep_shell`, `n_keep_floor`, defaults 5 and 3; was 8 and 5), as MRPMOD
hands PAIN (User Manual §5.3.1 card 4; Table D-1 has exactly 5 and 3). M_r and the peak normalization are those of the
full shape (unchanged).

**Unit test (verification; seen in Phase 103).** The kept shell and floor index sets equal Table D-1's at 32/32 modes;
with the old budget M_r is identical.

**Effect.** Solver-path cases only (the Table D-1 path already had 5 / 3). FLIGHT10_H234 (diagnostic, post-hoc): 97.34 /
89.22 / 82.28 → 97.33 / 89.00 / 82.86 dB against PAIN's 96.59 / 88.06 / 83.92 (H4 −1.06 dB; −4.73 as of Phase 102).
R172428_CODE_DECK and R172428_EXP_DECK run on NASA's 300-mode file and are not affected by this change; their changes in
the same tree come from Phase 106 (see `phase106_cabin_freq_printed.md`).
