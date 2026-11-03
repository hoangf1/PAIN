# Phase 109 — run 10 after Phases 104–108; the pair residuals (2026-10-30, diagnostic)

Plan `IMPLEMENTATION_PLAN.md` §8ay (now in `COMPLETED_PHASES.md`). No verdict (FLIGHT_MODES not met; levels seen).

**(a) Re-run** with what Phases 104–108 adopted (θ as printed; NASA's printed Merlin grid; 2-D part at 341 m/s; 5 / 3
terms; run 10's pre-correction floor sign): FLIGHT10_H234 94.60 / 87.44 / 83.89 dB against PAIN's 96.59 / 88.06 / 83.92
(−1.99 / −0.62 / −0.03 dB; Phase 102: +1.71 / +1.70 / −4.73). NASA's 15 printed H2–H4 pairs: 12/15 pair levels within
3 dB (median −2.1 dB); η_r″ within [0.4, 2.5]× NASA's at 14/14 (the 15th is printed 0). The three pairs outside 3 dB are
at H4 (Q2 I13 × 75 −6.0, Q4 I12 × 98 +5.9, Q3 I12 × 109 −7.3 dB). Away from resonance this code's η_r″ sits near 0.6× NASA's.

**(b) The trim area of card 20** (A_t = 28.10 m² in run 10's deck). CR-3813 §3 (high frequencies, Eq. 19) and its list
of symbols use the trim area as "the transmitting area with trim" of the high-frequency model; the modal η_n of
Eq. (77), which every run-10 tone uses (all below the 630 Hz crossover), has no A_t. So A_t does not enter run 10 and is
not the source of the 0.6 factor. Noted, not changed: this code's high-frequency path takes A_t from the geometry
(`hf_trim_areas`), not from the card.

**(c) η_n of the Merlin cabin against App. C p. 212.** CR-172428 §5.3.3 states that App. C was run with L_c = 7.75 m and
a trim panel mass other than run 10's 1.95 kg/m², but neither §4 nor §5 gives that run's trim inputs in the text. Per the
plan, not run.

**Left open.** The H2 shortfall (−2 dB) and the 0.6 factor in η_r″ away from resonance: the documents read here do not
explain them.
