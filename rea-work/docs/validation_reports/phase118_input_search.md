# Phase 118b — search for the inputs NASA did not print (2026-11-02)

Criterion fixed in `IMPLEMENTATION_PLAN.md` §8bh before the search: an input counts as found only if it is printed (table
or plot) for the same article, propeller, rpm and harmonic or band. Searched: the 18 PDFs in `rea-work/references`
(text layer; the BBN reports CR-158919 and CR-159124 are scans with a poor text layer, so their prior reading in
`IMPLEMENTATION_PLAN.md` §9 is used). Nothing was re-run here; a found input is used in a new dated phase with the
case's criterion unchanged.

| Input (cases it blocks) | Where looked | Result |
|---|---|---|
| Off-line free or blocked field of the CR-3813 test article, 4000 rpm, H1–H3 (T1, T1_MEAS_DAMPING, UNC_COVER, T1_FROM_E12, T1_F1A_FILL) | CR-3813 App. E; CR-172428 App. B; TP-2444 | **Found.** CR-172428 App. B (printed pp. 193–195) prints the blocked field PAIN used for the same article and propeller (0.762 m, 3 blades, 4000 rpm) at all 16 × 19 points, H1–H3 (`data/cr172428/appB_4000rpm_H*.csv`, transcribed in Phase 44a). It is ANOPP's prediction blocked by CR-172428's program, not a measurement. The E cases can be re-run on it against E-16's measured mean in a new phase |
| The field PAIN used for CR-3813's E-16/E-18 runs (REPRO_18b, E18_TONES) | CR-3813 pp. E-5, E-17, E-24; CR-172428 Table 8, App. B | **Not printed.** CR-3813 states the predictions applied Eq. (43) to ANOPP's output on the 160-point grid (p. E-17) and prints only the ℓ = 1 line (Fig. E-11; Table 8 in CR-172428). App. B's field is CR-172428's run, whose program and blocking differ (the 0.8 factor of p. 150), so it is not CR-3813's input |
| Test-propeller blade geometry (T1_F1A_FILL, T2_PRED_BB, PROP_BB_FIG14, PROP_BB_FIG17) | CR-3813 p. E-5; CR-172428 p. 56; TP-2444 | **Not printed.** CR-3813: "proprietary and thus are not included here"; TP-2444 names it only as a model of a de Havilland Twin Otter blade |
| Aero Commander blade geometry (BBN_CIRC) | CR-158919, CR-159124, Hartzell Manual 114-8; prior search in `IMPLEMENTATION_PLAN.md` §9 | **Not printed in full.** §9 records chord and twist inboard of 40 in only (none over the outer 14 % of the span) and no section shapes; the Hartzell Manual 114-8 is an overhaul manual (pitch-setting blade angles only; no chord, twist or section data) |
| Test-article exterior broadband spectrum above 1250 Hz (T2_EQ19, T2_MEAS_EXT, T2_MEAS_EXT_BR) | CR-3813 Figs. E-7–E-10; TP-2444 Fig. 17; CR-172428 Fig. 14 | **Not printed.** E-7 to E-10 are interior spectra; TP-2444 Fig. 17's exterior trace ends at 1.5 kHz, too little of the 1600 Hz band for a band level; CR-172428 Fig. 14 is the free field at 5000 rpm, another operating point |

**Follow-up.** The one input found is a printed field for the T1 family. Re-running those cases on it is a new phase:
its criterion is E-16's (±4 dB of the measured mean at H1–H3), its inputs App. B's field with CR-3813's cabin, and it is
not the same as R172428_EXP (that case uses CR-172428's whole input set against CR-172428's Table 5 measurements).
