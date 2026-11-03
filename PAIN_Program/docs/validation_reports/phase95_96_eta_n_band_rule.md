# Phases 95–96 — NASA's band-centre η_n rule (2026-10-30)

Plan `IMPLEMENTATION_PLAN.md` §8al (committed 71227a9 before 95b ran) and §8am (committed fae2cb7 before 96b ran);
both sections are now in `COMPLETED_PHASES.md`. Author 2026-10-30: "Yes, run it", then "Yes, apply it".

**95a — trim admittance.** This code's admittance β of the Table 6 trim at the 1/3-octave centres against CR-172428
App. B p. 197:
- Sidewall: within about 3 % from 315 Hz up, and within about 10 % at 100–160 Hz.
- Sidewall at the trim resonance: Re β is 27 % high at 200 Hz (0.072 against 0.0565) and 10 % high at 250 Hz.
- End cap: Re β is up to 4.6× NASA's below 250 Hz; small in absolute terms.

**95b — where Eq. (77) is evaluated** (variants fixed before the run). Modes within 2 % of App. B:

| Variant | ξ, ξ_e | ω in Eq. (77) | within 2 % |
|---|---|---|---|
| V0 | this code's, at the centre holding the mode | ω_n | 5/46 |
| V1 | NASA's printed, at the centre holding the mode | ω_n | 7/46 |
| V2 | NASA's printed, at the centre holding the mode | ω_c | **44/46** |
| V3 | this code's, at the centre holding the mode | ω_c | 0/46 |

The two V2 misses (281.3 and 562.6 Hz) lie on band edges; assigned by the nominal centres (log-nearest of 250, 315, …),
both give a ratio of 1.000. **Reading (post-hoc):** NASA's program evaluates Eq. (77) for each cabin mode at the nominal
1/3-octave centre holding it, for both ω and the trim conductance. With NASA's admittance it reproduces 45/46 modes
within 2 %. The 46th mode (448 Hz) is 0.5 Hz from the 400/500 Hz edge and lands in the other band here.

**Phase 96 — the rule as the default.** It is set by the new `PainInputs` field `η_n_band_omega = true` and the function
`nominal_band_centre`. The Phase 89 and 92 diagnostics keep the Phase 89 reading, so their records stand.

| Case | Kind | Result |
|---|---|---|
| APPB_ETA_N_BAND (96a) | diagnostic, post-hoc | 42/46 within ±10 %, 0/46 within ±2 % with this code's admittance; 45/46 within ±2 % with NASA's |
| APPB_ETA_N_T2_BAND (96b) | P, held out (criterion fixed before the run) | **met** 3/3: 0.0894, 0.0779, 0.0827 against 0.088, 0.077, 0.081 |
| R172428_ETAT2 (96c, re-run) | P, criterion unchanged | **met** 9/9, largest \|Δ\| 2.09 dB (1.69 before) |
| R172428_CODE_DEFAULT (96d) | diagnostic, post-hoc | 8/9 within ±3 dB; 3000 rpm H3 63.03 dB against 59.5 |

Per-pair η_r″ within 10 % of NASA's printed values: 11/19 pairs, up from 10/19 with the Phase 89 reading (information).

**What remains.** With this code's admittance, η_n is up to 29 % high for the modes at 188–218 Hz. This follows Re β at
the 200 Hz trim resonance. A 20 % lower PF-105 attenuation at 200 Hz (11 instead of 13.8 dB/m) gives NASA's β there. That
is inside the reading precision of Fig. A-2 at that level (±6 dB/m on a 0–600 dB/m scale). This is a sensitivity check,
not a fit; Phase 97 below tried to trace the drawn curve.

**Cases whose recorded result changed** (criteria unchanged; re-recorded 2026-10-30):

| Case | Before (Phase 93 form) | Phase 96 default |
|---|---|---|
| REPRO_18b | not met 1/3 (max 11.0) | not met 1/3 (max 10.0) |
| E18_TONES | not met 2/10 (max 10.0) | not met 2/10 (max 9.8) |
| R172428_ETAT2 | met 9/9 (max 1.7) | met 9/9 (max 2.1) |
| R172428_EXP | not met 4/9 (max 17.0) | not met 5/9 (max 17.0) |

## Phases 97–98 — what the remaining damping gaps are not (2026-10-30, diagnostics, no code change)

**97 — tracing Fig. A-2 at 125–250 Hz.** An automated trace of the attenuation α and phase φ curves of CR-3813 Fig. A-2
was set up at the 1/3-octave centres between the marked 100 and 315 Hz. Its rules were fixed before any comparison:
400 dpi, gridlines fitted from pixel darkness, α taken as the lowest curve above the zero line, and QA requiring two
darkness thresholds to agree within 1.5 dB/m. **It failed its QA** (thresholds differ by up to 14.4 dB/m). The open
circle markers, the zero gridline (α ≈ 5–15 dB/m is only 10–30 px above it at 400 dpi), and the "φ" label with its arrow,
which sits between the two curves at 160–200 Hz, break the curves up. No value was adopted. The low-frequency α of PF-105
is not readable from the figure more precisely than the marker table. Fig. A-2's source, Schultz in Beranek's *Noise and
Vibration Control* (1971), is not in hand.

**98 — the structural loss factor η_r′ (R172428_ETA, 17/32).** This code's η_r′ matches App. B where the trim adds little
(plate-dominated modes, ratio 0.95–1.01). It is 0.51–0.82 of NASA's for shell-dominated modes above 470 Hz, and
0.87–0.93 at 300–350 Hz. The NASA-implied trim term |C_w|/(m̄ω²) is 1.1× this code's at 300–350 Hz and 1.4–2.1× at
470–811 Hz, scattered from mode to mode. Ruled out:
- **Modal masses:** total and shell modal masses agree with App. B p. 194 within 1–2 % at all 32 modes.
- **Surface mass:** the skin-only m cancels out of m̄ = m M_r/M_r^X.
- **Band centre:** C_w at the nominal band centre gives 18/32 within 25 % (17 before).
- **Coupling loss included in NASA's printout:** η_r′ + Σ_n η_r″ gives 8/32 within 10 % (13 before) and overshoots
  plate modes by up to 99×.
- **Alternative forms of Eq. (A.8)** (|a12|, |a12 a22|, |a12/(1 + a12 a21)|): none follows the needed factor.

Since the sidewall admittance β matches App. B within 3 % at 315–5000 Hz, while C_w (the trim's reaction on the wall)
depends more strongly on the insulation's properties, the most likely cause is the PF-105 properties between the marked
frequencies of Fig. A-2. That cannot be settled from the documents in hand.
