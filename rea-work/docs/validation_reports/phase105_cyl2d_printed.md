# Phase 105 — CYL2D's grid rule against PAIN's printed cabin modes (2026-10-30)

Plan `IMPLEMENTATION_PLAN.md` §8au (now in `COMPLETED_PHASES.md`); criterion fixed 2026-10-30 (commit 25f7acb) before the
two held-out lists were transcribed. Case CYL2D_PRINTED (P, CYL2D block), `validation_case_iso105.jl`.

**Data (CR-172428 App. C).** Decks p. 210 (PDF 220), read at 300 dpi: small diameter θ₀ = 62.6°, a = 1.145 m; narrow
body θ₀ = 73.7°, a = 1.875 m. Acoustic-mode lists p. 221 (PDF 231, modes 1–48 and 383–400) and p. 225 (PDF 235, modes
2–50 and 376–400): `appC_smalldia_acoustic_modes.csv`, `appC_narrowbody_acoustic_modes.csv`. Pass A by eye at 300 dpi.
The planned OCR pass failed on this print (ruled lines defeat detection and row finding, whole page and per cell), so pass
B was the print's own consistency (one axial spacing per list, largest deviation 0.005 Hz; one 2-D frequency per I across
every row and Q, no outlier beyond 0.03 Hz) plus a second eye read of the uncertain cells. Deviation from the plan,
stated here. The narrow body's row 1 prints mode 400's values, so its ε(0,0) is not printed; ε(1,0)/2 (Eq. C.11) stands
in, also a deviation.

**Rule tested.** Node rule r ≤ 1 + 0.45h; NY = 10, else the next grid that solves (`cyl2d_modes_solvable`); 2-D
frequencies at CYL2D's 341 m/s divided by a.

**Result: not met.**

| Aircraft | Grid the rule gives | ε(0,0) here / printed | 2-D frequencies within 0.1 % | Types equal |
|---|---|---|---|---|
| small diameter, 62.6° | NY = 12 | 0.99387 / 0.96858 | 0/53 | 37/53 |
| narrow body, 73.7° | NY = 12 | 0.99756 / 0.97540 (ε(1,0)/2) | 5/61 | 61/61 |
| Merlin IVC, 50° (seen, post-hoc) | NY = 11 | 0.96723 / 0.96723 | 51/51 | 51/51 |

**Diagnostic, after the verdict.** Grids NY = 6–20 with node rules 0.10h–0.80h were solved at both angles. Narrow body:
NY = 8 with 0.40h–0.55h reproduces the print (ε 0.97539, every 2-D frequency within 0.009 %, types 10/10). Small
diameter: no grid in that range does; the closest is NY = 9 with 0.38h–0.45h (ε 0.97252, 2.0 % off, types 9/9). So NASA
used NY = 10, 11 and 8 at 56.6°, 50° and 73.7°, a node rule of 0.43h–0.47h is common to the three, the NY rule is not
"10, else the next that solves", and this App. C scheme does not reproduce the small-diameter list at 62.6°, a = 1.145 m.

**Decision (the plan's rule).** Not adopted: the default node rule stays 0.4h and the uncertainty band is unchanged.
Run 10, a diagnostic, uses NASA's printed Merlin grid (NY = 11, 0.45h) as an input chosen from that print (post-hoc):
FLIGHT10_H234 97.13 / 89.37 / 81.34 dB (trim per band 97.47 / 89.40 / 81.31; 0/3) against PAIN's 96.59 / 88.06 / 83.92.
NASA's grid rule is planned as Phase 111.
