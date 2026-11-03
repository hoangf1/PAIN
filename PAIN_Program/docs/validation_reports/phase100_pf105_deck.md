# Phase 100 — NASA's per-band PF-105 input table (2026-10-30)

Plan `IMPLEMENTATION_PLAN.md` §8ap, committed 1ddabd9 before the run (now in `COMPLETED_PHASES.md`).

**Source.** PAIN takes the insulation properties as one value per 1/3-octave band (User Manual cards 22–33). CR-172428
App. D (PDF p. 239, printed -229-) prints the PAIN input deck of flight-test run 10. Its cards 22–33 hold NASA's PF-105
table at 21 bands, 50–5000 Hz. Transcribed to `data/cr172428/appD_pf105_deck.csv` and checked against a 200 dpi render
of the page. It agrees with the six marked points of CR-3813 Fig. A-2 and differs between them, e.g. α at 200 Hz is 10.1
dB/m against 13.7 from the markers. It prints λ = 0.01 m at 1600 Hz, where the curve gives about 0.10 m; it is kept as
printed.

A cleaner copy of Fig. A-2 is CR-165869 (Pope & Wilby 1982, Phase II report) Fig. 3, a native 300 dpi scan. A trace of
its drawn α curve gives 5.2, 8.3, 13.5 and 19.5 dB/m at 125–250 Hz. The drawn curve therefore matches the marker
interpolation at 200 Hz; NASA's 10.1 is below its own curve. The deck, not the figure, is what NASA's program ran.

**Predictions (fixed before the run) and results.** Hypothesis H_deck: NASA's App. B scale-model runs used this table as
printed.

| Step | Case | Criterion / prediction | Result |
|---|---|---|---|
| 100a | R172428_TRIM_DECK | sidewall Re β at 200 Hz within 10 % of App. B; end-cap Im β at 1600 Hz within 15 % | +2.7 % and +1.7 %: **both hold**; 84/84 admittance values within ±10 % at 50–5000 Hz (Fig. A-2 markers: 49/72 at 100–5000 Hz) |
| 100b | R172428_ETAT2 (held out) | ±3 dB at ≥ 7 of 9 | **met**, 9/9 (largest \|Δ\| 2.12 dB) |
| 100c | APPB_ETA_N_T2_BAND (held out) | ±10 % at modes 6, 7, 8 | **met**, 3/3: 0.0887, 0.0776, 0.0822 against 0.088, 0.077, 0.081 |

The printed λ = 0.01 m at 1600 Hz reproduces the glitch in App. B's end-cap Im β at 1600 Hz (−0.281 against −0.277;
the Fig. A-2 table gives −0.597). The trim transmission factor of App. B p. 197 is now reproduced within 0.001 dB at all
18 bands 100–5000 Hz, the 200 Hz trim resonance included (−17.316 dB; Fig. A-2 gave −15.67). **H_deck is supported**
and, with 100b and 100c met, `r172428_inputs` takes the deck table by default (`insulation=:deck`; `:fig_a2` keeps the
marker table). CR-3813's own runs keep the Fig. A-2 table.

**Transcription fix.** App. B's end-cap Re β at 1600 Hz had been entered as 0.13507; the page prints `.13507E+01`
(checked on a 400 dpi render). `appB_trim.csv` now holds 1.3507. Only the diagnostic cases read this column.

**Recorded with the deck table (no role in the decision).**
- APPB_ETA_N_BAND: 45/46 within ±10 % with this code's admittance (42/46 before); 45/46 within ±2 % with NASA's.
- APPB_ETA_RPP: 12/19 pairs within 10 % (11/19 before).
- R172428_ETA: 17/32, unchanged. The η_r′ gap above 470 Hz (Phase 98) does not come from the insulation table: the
  deck agrees with the markers there.
- R172428_CODE_DEFAULT: 8/9 within ±3 dB (largest |Δ| 3.64 dB, 3000 rpm H3); R172428_EXP: 5/9, unchanged in count.
- R172428_CODE (CR-3813 tone sum): 4/9, unchanged.

**Not changed (open).** The deck table stops at 5000 Hz (Fig. A-2: 6300 Hz), so a CR-172428 run that needs the trim
above 5000 Hz stops with the table-range error unless extrapolation is set. Between band centres this code still
interpolates the deck values in log f; PAIN reads one value per band, which matters for tones away from a centre (e.g.
the 450 Hz tone of 3000 rpm H3). Testing that would be a separate phase with its own criteria; it was not tried here.
