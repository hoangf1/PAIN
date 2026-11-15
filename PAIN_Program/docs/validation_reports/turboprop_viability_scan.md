# What the record shows, and lacks, for turboprops (2026-11-14)

Scan by Claude, at the author's request of 2026-11-14 ("do another scan of the validation coverage and check whats needed so i can prove that the tool is viable for turboprops"). Nothing in the code, the criteria or the recorded results changed.

**Open tickets before this scan:** none (ISSUE-001 to 044 closed). The three unticked boxes left in `IMPLEMENTATION_PLAN.md` are 2026-10-16 notes in the BBN reference appendix, not phases.

## What a turboprop prediction runs through

A turboprop puts a large propeller (about 2.5–4 m, 4–6 blades, helical tip Mach 0.7–0.9, flight Mach 0.3–0.6) beside a stiffened, trimmed fuselage of about 1.7–3 m. The tool's chain: blade loads → free field in forward flight → field on the curved fuselage → wall modes and damping with trim → cabin modes → cabin tones and dB(A).

## The record, stage by stage

| Stage | Cases with a verdict | Against | Turboprop-like? | Standing |
|---|---|---|---|---|
| Blade loads | R996_LOADS not met 24/32 | measurement | no: 1.2 m, 2 blades, static | the gap: no forward-flight loads case with a verdict; Report 1012 (forward flight) carries no verdict by the input rule, and its displacement is mostly blade inputs (ISSUE-043) |
| Free field | R996_FIG12, FIG13A, FIG14 met; PER_FIG7 met; PER_FIG8 not met | measurement | partly: Report 996 reaches tip Mach 0.9 but static and on scaled loads; Pereira is a 0.3 m propeller at low speed | the gap: no near field in forward flight at turboprop tip Mach |
| Field on the fuselage | R996_FIG10_FLAT met | measurement | no: a flat wall, static | the gap: the curved fuselage and its boundary layer are assumed; no in-flight fuselage pressure with complete inputs (Commander 695A and OV-10A lack the blade) |
| Wall modes | MRP_APPD met; **FLIGHT_MODES met 200/221** | NASA's printed PAIN | **yes: the Merlin IVC, a twin turboprop** | covered |
| Damping and trim | **FLIGHT_ETA met 218/221**; APPB_ETA_RPP met; APPB_ETA_N_T2_BAND met | NASA's printed PAIN | **yes (Merlin IVC)** | covered |
| Cabin modes | CYL2D_C1, APPB_EPS_N, CABIN_FREQ_PRINTED met; CYL2D_PRINTED not met 63/116 | NASA's printed PAIN | **yes: the Merlin and a narrow body are reproduced**; the small-diameter aircraft is 0.3 % low | covered, one unexplained factor |
| Cabin tones | R172428_ETAT2 met; R172428_EXP not met 5/9 | NASA's printed PAIN; measurement | no: the 1 m test article; FLIGHT10_H234 (Merlin, flight) is a diagnostic against PAIN's printout | **the main gap and the main opportunity** (below) |
| Bands and dB(A) | NR_TP1964_XOVER not met 9/18 | measurement | no: a bare cylinder | the Commander 695A cases carry no verdict (blade and cabin section not printed) |

**What can be claimed today.** On a real turboprop fuselage (Merlin IVC), the cabin half of the chain reproduces what NASA's PAIN printed: structural modes, loss factors, cabin modes, and the cabin tones of flight run 10 from PAIN's field. FLIGHT10_H234 shows the code as shipped 1.3 to 2.4 dB below PAIN's printed H2–H4, but as a diagnostic (corrected 2026-11-15: the scan first said "within about 1 dB", a figure from before ISSUE-032). NASA itself compared PAIN with the Merlin's measured cabin levels in flight (CR-172428 §5.4, Tables 23–24): predictions high by 4.3 dB on average with a standard deviation of 4.1 dB over 15 tones, 2.6 dB and 2.4 dB without the 4th harmonic. This code has not yet been compared with that measurement directly.

**What cannot be claimed.** The propeller half: loads and near field in forward flight at turboprop size and tip Mach, and the field on a curved fuselage in flight. For a turboprop prediction the exterior field must at present come from measurement or a separately validated propeller code; the tool's own propeller path is not validated there.

## What would close the main gap: the Merlin IVC in flight against measurement (Phase 155, ISSUE-045)

CR-172428 Table 23 prints, for flight runs 10, 11 and 12 and harmonics 1–5, PAIN's predicted space-average cabin levels (downsweep, upsweep, both) and the **measured** space average. For run 10:

| Harmonic | PAIN downsweep | PAIN both | Measured | Both − measured |
|---|---|---|---|---|
| H1 104.5 Hz | 99.9 | 102.9 | 101.2 | +1.7 |
| H2 209.1 Hz | 96.6 | 99.1 | 93.2 | +5.9 |
| H3 313.6 Hz | 88.1 | 91.8 | 89.9 | +1.9 |
| H4 418.1 Hz | 83.9 | 86.7 | 77.2 | +9.5 |
| H5 522.7 Hz | 71.0 | 73.2 | 72.2 | +1.0 |

*Values as printed (Table 23, PDF p. 166); read by eye for this scan only, to be transcribed by the §2.2 procedure in the phase.*

What it needs:

1. **The upsweep side.** The two propellers turn the same way, so the cabin level is the power sum of a downsweep and an upsweep run (CR-172428 p. 164). App. D prints only the downsweep run, but App. A (p. 189) prints the program change by which PAIN builds the upsweep field from the downsweep input. This code has no blade-sweep switch. Implementing that change, and checking it against Table 23's printed upsweep and both levels (PAIN's own output), is a code-on-code step with held-out data.
2. **H1 and H5 of run 10.** The scan cuts phase rows of their field pages. PAIN's input is the upper quarter (L = 10–19); the printed rows L = 1–9 are the mirror PAIN generates. If only those rows are cut, the input is complete and H1 and H5 can be run. That is also new held-out data for the run 10 reproduction.
3. **Runs 11 and 12** are not printed ("in the interest of brevity", p. 165), so only run 10 can be run: five tones at most.
4. **A criterion fixed before the run**, in R172428_EXP's form (±4 dB of the measured space average per tone). It is checked against the measurement's own scatter: the report gives 95 % and 99 % confidence limits (Figs. 55–57), which must be clearly inside the tolerance (rule of 2026-11-10).

Also: FLIGHT10_H234's record still says "no verdict (FLIGHT_MODES not met)", but FLIGHT_MODES has been met since Phase 142. Whether its reproduction of PAIN's run 10 carries a verdict is decided in Phase 155, with any H1 and H5 as held-out data.

## What would close the propeller half (Phase 156, ISSUE-046)

This needs data the repository does not hold: a forward-flight propeller of turboprop size, with the blade geometry printed and measured loads or near-field or fuselage pressures. Leads:

- NASA TM-102285 (OV-10A in-flight fuselage pressures). Whether its blade geometry is printed or citable is not known.
- Companion analyses of the Commander 695A flights (CR-178004). Its Hartzell blade is not printed.
- The loaded part of Report 1012 Fig. 5 read by hand (ISSUE-043's remainder) gives forward-flight loads, at 1.2 m only.

If none prints the blade, the propeller half stays unvalidated for turboprops, and that is stated as a limit of the tool.

Sources found by web search for this scan: [NASA TM-102285 record](https://ntrs.nasa.gov/citations/19890016304), [twin-turboprop flight tests, NASA 1986](https://ntrs.nasa.gov/api/citations/19860010618/downloads/19860010618.pdf), [their 1988 analysis](https://ntrs.nasa.gov/citations/19880009836).

## Update 2026-11-15: Phase 155 done

- **FLIGHT10_REPRO met, 15/15** (`phase155_merlin_flight.md`): run 10 H1–H5, both propellers, within 3 dB of PAIN's printed levels in every form. Twelve of the rows are held out. The code is 0.9–2.8 dB below PAIN.
- **Against the measured flight levels, information only** (the measurement's own 95 % limit at H2 is at least 5.9 dB above its mean): the code is within 1.3 dB at H1, H3 and H5, 3.5 dB high at H2 and 8.4 dB high at H4. PAIN was +1.7, +5.9, +1.9, +9.5 and +1.0 dB.
- The cabin half of the chain on a turboprop in flight is now reproduced with a verdict; the propeller half stays open (Phase 156).
