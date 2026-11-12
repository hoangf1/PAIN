# ISSUE-041: the Merlin IVC loss factors, a held-out test of the ISSUE-032 fix (2026-11-12)

Done by Claude under the author's authority of 2026-11-11. New case `FLIGHT_ETA`. Its criterion was written into ISSUE-041 and committed (d0f6a07) before any value of the column was read:

> η_r′ of this code within ±25 % of the printed loss factor for at least 75 % of the listed modes.

## The data

CR-172428 App. C pp. 213–216 print a LOSS FACTOR beside each of the Merlin IVC's structural modes (flight run 10's modal file). The 221 that are not cut off in the scan were transcribed without this code's values in view, into `data/cr172428/appC_merlin_loss_factors.csv`:

- **Pass A:** read by eye from 300 dpi tiles of the first four columns.
- **Pass B:** in this print, 8 and 0 differ only by shape (a filled middle against an open slit). So every glyph pass A read as 0 or 8 was measured at 600 dpi (slit and middle-bar fractions) against the known 0s and 8s of the mode-number column on the same pages. That rule recovers all 80 reference glyphs.
- **Disagreements:** two cells. Mode 13 is .54897 (a fourth digit; a clear shape call). Mode 188 is .03076 (settled by eye at 600 dpi, where a rule line touches the glyph and skews the measure).
- **Leading-digit check:** twelve further cells have 8 or 0 in a leading significant digit. All were checked by eye at 600 dpi and agree.

## The run (one run, 2026-11-12)

Inputs are flight run 10's printed deck: η_r = 2/f per band; PF-105 0.055 m trim with 1.95 kg/m² and η = 2.0; wall mass 4.54 kg/m²; exterior and interior air as printed. The modes come from NASA's MRP deck (App. C pp. 204–205). Each printed mode is paired with the solver mode of the same symmetry and axial order nearest in frequency, as in FLIGHT_MODES.

| | Within ±25 % | Median \|difference\| | Largest |
|---|---|---|---|
| **This code (since ISSUE-032)** | **218/221: met** | 8.3 % | 29.7 % |
| The form before ISSUE-032 (card replaces the radiation loss), same modes | 64/221 | | |

Below 470 Hz the count is 103/104; above it, 115/117. At the median this code is 0.92 of PAIN's value, a small systematic difference well inside the tolerance.

So the fix, found on the test article's App. B, reproduces PAIN's printed loss factors on a second aircraft and a second deck. The form before it does not.

## Not covered

Modes 47–52, 111–121, 182–185 and 243–250 are cut off in the scan. Mode 1 (39.6 Hz) lies below the trim table's 50 Hz start and uses its end-segment extrapolation; it is one of the 221 and within the tolerance either way.

The glyph-measuring and comparison scripts were run once and not kept (rule of 2026-11-10). The measure is described above and in the data file's header.
