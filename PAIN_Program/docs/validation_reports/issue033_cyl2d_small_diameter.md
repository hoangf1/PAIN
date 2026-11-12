# ISSUE-033: the cabin modes of the small-diameter aircraft (62.6°) on NASA's grid (2026-11-12)

Decided and done by Claude under the author's authority of 2026-11-11 ("fix all the issues"; "make decisions logically like i do"). `CYL2D_PRINTED` stays **not met**; its criterion, tolerance and reference lists are unchanged. The re-run is post-hoc: both lists had been seen.

## The diagnostic (one run, the ticket's question 3)

NASA's grid for 62.6° has 10 intervals (CR-165869 p. 60). On it this code's check "the kept eigenvalues must be real" (Phase 79b, |Im|/|Re| ≤ 0.001) failed at 0.0012, so the code fell back to 12 intervals. With the check looked past and the real parts taken:

| Against NASA's printed list (53 modes) | Fallback grid (12), as shipped before | NASA's grid (10), real parts |
|---|---|---|
| ε(0,0), printed 0.96858 | 0.99986 | **0.96858** |
| mode types equal | 37/53 | **53/53** |
| frequencies within 0.1 % | 0/53 | 0/53 |
| frequency difference | 0.67 % median, 3.0 % largest, scattered | **−0.30 % to −0.31 % at every mode** |

So the scheme is NASA's: the first-mode factor and every mode type are reproduced. What is left is one common factor of 1.00305 on every frequency.

## What changed in the code

- **On NASA's printed grid the check no longer rejects; the real parts are used, with a warning.** The check is this recreation's own. NASA's program used the IMSL routine EIGRF for a real general matrix (User Manual §5.1), the manual describes no rejection, and NASA printed modes for this very grid. The threshold (0.001) is not changed, and the check still applies to every grid that is not NASA's for its floor angle.
- Scanned 2026-11-12 for floor angles 30° to 85° in half-degree steps: on NASA's grid the kept eigenvalues are never more than 1 % from real, and the grid always solves. So every floor angle now runs on NASA's grid; before, 42 of the 111 angles fell back to another grid.
- The GUI's automatic floor angle of 62.6° (fuselages of 2.5–2.7 m) therefore runs on NASA's grid now.

This cannot make the case pass: 0.30 % is three times its 0.1 % tolerance, before and after.

## What is not explained

The common factor 1.00305. A cabin radius of 1.1415 m in place of the 1.145 m of the structural deck (App. C p. 210, read again at 130 dpi on 2026-11-12: 1.145), or a sound speed of 342.0 m/s in place of 341, would give it. Neither is printed for this aircraft, so neither is used: choosing one from this result would be tuning. The narrow body and the Merlin are reproduced with their deck radius and 341 m/s.

`CYL2D_PRINTED` after the re-run: small diameter ε exact, types 53/53, frequencies 0/53; narrow body 61/61; summary 63/116 (was 62/116). Cause on record: NASA's printout, not explained by the documents.

The two diagnostic scripts were run once and not kept (rule of 2026-11-10).
