# Phase 101 — CR-172428 flight run 10 from its printed deck; the trim per band (2026-10-30)

Plan `IMPLEMENTATION_PLAN.md` §8aq, committed b404020 before any run (now in `COMPLETED_PHASES.md`).

**Sources found.** CR-172428 prints PAIN's complete flight-test run 10 (Merlin IVC, 4-blade Dowty Rotol, 1568 rpm):
- MRP input deck of the business aircraft, App. C pp. 204–205 (PDF 214–215), symmetric and antisymmetric decks
  identical and equal to Table 13 (`data/cr172428/appC_merlin_mrp_deck.csv`).
- PAIN's structural-mode list for it, App. C pp. 213–216 (PDF 223–226).
- PAIN input deck, App. D p. 229 (PDF 239); propeller field, pp. 230–234 (PDF 240–244); tone results with the top five
  pairs per tone, pp. 235–237 (PDF 245–247). PAIN's run 10 levels: H1–H5 = 99.90, 96.59, 88.06, 83.92, 71.02 dB
  (104.5, 209.1, 313.6, 418.1, 522.7 Hz).

**101a — FLIGHT_MODES (P): not met, 197/221 (89.1 %; criterion ≥ 90 %).** This code's MRP solver on NASA's deck,
with the deck's series limits (M 1–10, ns 0–14, np 0–5), each printed mode paired with the solver mode of the same
symmetry and M nearest in frequency (rule fixed before the comparison). Frequencies: 219/221 within 2 %, median 0.0 %
(most within 0.01 Hz). The two frequency misses (modes 29 and 230) look like misreadings of M on the scan. About 20
generalized masses differ by 10–80 %, mostly floor-heavy or near-degenerate modes (e.g. mode 41: 1002.69 kg printed,
1800.91 here). MRP_APPD found NASA normalizing on its printed output grid (up to 3.9 % there); whether that explains
these larger differences is open.

The list was transcribed once by eye from 300 dpi renders (221 modes up to 1 kHz). The bottom rows of each scanned
page are cut off, so modes 47–52, 111–121, 182–185 and 243–250 are not legible and are omitted. The plan asked for
two passes. A second pass was not done because the outcome would not change: correcting the two probable misreads
gives exactly 90 %, and correcting only the rows that fail against the code would bias the check. The verdict is the
first-pass count.

**101b–101d — not run.** Under the decision fixed in the plan, 101b–101d could only be diagnostics once 101a was not
met. The printed field is also incomplete: the scan cuts the bottom phase row(s) of H1 (p. 230, θ = −15°) and H5
(p. 234, θ = −15° and −5°). The amplitudes are mirror-symmetric about θ = 75° and could be recovered; the phases are
not. A reproduction would need assumed phases for the dominant harmonic, so the per-band trim question stays open.
The fields for H2–H4 (pp. 231–233) are complete; a diagnostic on those three tones remains possible.

**No default changed.** FLIGHT_MODES is added as a P case on the Structural modes block.
