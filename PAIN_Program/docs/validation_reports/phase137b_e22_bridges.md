# Phase 137b: are the sound-bridge connections of the CR-3813 test article printed? (2026-11-10)

Read 2026-11-10 by Claude under the author's delegation of 2026-11-10. Nothing was run; no criterion or number changed.

## What the documents print

| Input of `bridge_tau` (`src/sharp_bridges.jl`) | Printed? | Where |
|---|---|---|
| Number of point connections | yes: "attached to the frames by nine soft-mounted screws" | CR-3813 App. E, PDF p. 125 |
| Line connections | yes, in words: "the trim was hard-mounted to the floor" | same page |
| Where the nine screws are (the lattice) | no | — |
| How stiff a connection is | no: CR-3813 says soft-mounted, and CR-172490's ΔTL_M (Eqs. 23 and 25, coded as `sharp_dTL_line` / `sharp_dTL_point`) has no term for it | CR-172490 PDF pp. 25–30 |
| Line connection spacing | no | — |

CR-172490 is a design study of other sidewall panels (Panels A–H); a text search of it for "3813", "test cylinder", "Phase III" and "PAIN" finds nothing about the CR-3813 cylinder.

## What follows

The code maps the nine screws to a uniform lattice √(A/9) over the curved trim area and the floor mounting to two lines at spacing arc/2 (a V-ASSUMED mapping fixed 2026-10-23), and treats the soft mounts as rigid. Those inputs are assumed, so the input rule of Phase 118a applies: `E22_BR` carries no verdict (already so since Phase 135f, `INFORMATION_ONLY_CASES`, "inputs incomplete"). Its recorded 0/4 stays on record and is not a pass.
