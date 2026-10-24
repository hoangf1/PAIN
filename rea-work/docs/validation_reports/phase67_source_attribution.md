# Phase 67: why the source-block experimental cases miss

Criteria and rules fixed 2026-10-24 in `IMPLEMENTATION_PLAN.md` §8k before any number was computed. No input, load or
criterion of an existing case was changed.

**Question.** BEMT and F1A pass their code checks (Phases 41, 64, 66), yet R996_LOADS (6/32), R996_FIG12/13A/14 and the
Pereira cases miss the measurements. Two candidate causes were tested.

| Step | Case | Result |
|------|------|--------|
| 67a | POLAR_FIDELITY | **not met** 9/60 (15 %): XFOIL c_l is 0.15–0.35 below NACA TN 1546's measured c_l at low α for all three exactly matching sections (16-312, 16-506, 16-509) and every Mach number 0.4–0.72; the gap closes toward high α |
| 67b | F1A_CHORDWISE | diagnostic: spreading each section's load over the chord changes H1–H3 by at most 0.27 dB at the Report 996 Fig. 14 geometry (0/60 points beyond the 2 dB rule) |

**Consistency (post-hoc, 2026-10-24, after 67a).** The recorded Report 996 scale factors give BEMT thrust 25–32 % below
the measured thrust (s_T = T_meas/T_BEMT = 1.25–1.32, 7 of 10 primary cases with finite values), the direction and size
that a c_l 0.15–0.35 low at the blade's working angles produces.

**Conclusion.** The Report 996 source misses come from the section polars (XFOIL with forced transition), not from the BEMT
or F1A implementation and not from the compact-chord approximation of F1A. This is a limitation of the section-data
approximation; measured polars exist for only three of the blade's sections, so the cases are not re-run with them.

Readings fixed before the comparison: TN 1546 Re(M) linear between its stated 0.85·10⁶ (M = 0.3) and 2·10⁶ (M = 0.8);
XFOIL at 1·10⁶ and 2·10⁶ interpolated in log Re; no α extrapolation; TN 1546 is not corrected for wall interference
(about 2 % on M at supercritical speeds, p. 6). The chordwise check uses thin-airfoil loading ∝ √((1−ξ)/ξ) at 8 points;
with one point it reproduces the F1A_INDEP routine to 7.5e-5.
