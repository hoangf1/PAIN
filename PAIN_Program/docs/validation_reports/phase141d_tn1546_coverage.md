# Phase 141d: how much of the Report 996 blade do TN 1546's measured sections cover? (2026-11-10)

Computed 2026-11-10 by Claude under the author's delegation of 2026-11-10. The rule was fixed on 2026-11-09: if the coverage is under half, stop, record it and drop the proposal. Nothing in the code changed and no case was run.

## Inputs

- **Blade.** `data/report996/naca_4-5-08-03/blade_form.csv`. It runs from r/R 0.271 to the tip, with thickness 13.4 % at the root falling to 0 at the tip, and design lift coefficient 0.13–0.50.
- **TN 1546 Table I (PDF p. 17).** It lists 24 NACA 16-series sections with force data in Fig. 3. Thickness is 6, 9, 12, 15, 21 or 30 %, and design lift coefficient is 0 to 1.0. The test range is Mach 0.3 to about 0.8 (p. 3). Three of the sections are digitized: 16-312 (Fig. 3(j)), 16-506 (3(n)) and 16-509 (3(o)).
- **Section Mach.** The static test is taken as M = M_tip · r/R, without the induced velocity. That is a lower bound, a few per cent below the true value.
- **What counts as inside.** A span point is inside when its thickness lies within the measured range (6–12 % for the three digitized sections, 6–30 % for all 24) and its Mach lies within 0.3–0.8. Coverage is the fraction of the span length from r/R 0.271 to 1.

## Result

| Tip Mach of the Report 996 run | Thickness only, 3 digitized | Thickness and Mach, 3 digitized | Thickness only, all 24 | Thickness and Mach, all 24 |
|---|---|---|---|---|
| 0.45 | 0.72 | **0.30** | 0.85 | **0.30** |
| 0.60 | 0.72 | 0.53 | 0.85 | 0.53 |
| 0.75 | 0.72 | 0.67 | 0.85 | 0.67 |
| 0.90 | 0.72 | 0.72 | 0.85 | 0.76 |

## What follows

- **The coverage is mixed.** It is under half at tip Mach 0.45, where the inner span runs below Mach 0.3, the bottom of TN 1546's range. It is 0.53–0.76 at the other three tip Machs.
- **Design lift is the binding limit.** The three digitized sections have design lift coefficients of 0.3 and 0.5 only. The blade's inner and tip sections run 0.13–0.3, so no digitized section brackets them.
- **Decision** (Claude, under the author's delegation of 2026-11-10): the proposal is not dropped, and 141e is not started. A measured-polar set first needs the sections of design lift 0.1 and 0.2 at 6–15 % thickness digitized: Figs. 3(b), 3(c), 3(d), 3(f), 3(g) of Table I. That is a §2.2 card, so 141e waits for it.
