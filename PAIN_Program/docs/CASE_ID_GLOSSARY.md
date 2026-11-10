# Case ID glossary

What the parts of a validation case's ID mean (Phase 146d, 2026-11-10). A case's full record is in [`VALIDATION_GUIDELINE.md` §2.13](VALIDATION_GUIDELINE.md); the cases with a verdict are on the coverage chart in §0.

## First part: where the comparison comes from

| Prefix | Meaning |
|---|---|
| `R172428` | NASA CR-172428, the PAIN validation report (1984): measured and printed PAIN results |
| `APPB` | CR-172428 Appendix B: values NASA's program printed for one run |
| `FLIGHT`, `FLIGHT10` | CR-172428's flight test aircraft; flight run 10 |
| `REPRO` | A reproduction of a run NASA printed in CR-3813 |
| `E11` … `E22` | CR-3813 Appendix E, Figure E-11 … E-22 |
| `T1` | Tone levels in the cabin against CR-3813 App. E |
| `T2` | 1/3-octave levels in the cabin against CR-3813 App. E |
| `NR` | Noise reduction (outside level minus cabin level) |
| `R996` | NACA Report 996 (propeller near field, static) |
| `PER` | Pereira's forward-flight propeller measurements |
| `BBN` | Bolt Beranek and Newman reports CR-158919 and CR-159124 (fuselage pressure phase) |
| `POLAR` | Blade section lift and drag tables |
| `BEMT` | Blade element momentum theory (blade loads) |
| `F1A` | Farassat formulation 1A (the blade noise source) |
| `BPM`, `PROP` | Airfoil self-noise (Brooks, Pope and Marcolini); propeller broadband noise |
| `FF`, `SRC` | Free field; the source chosen for the cabin |
| `GEXT` | Grid extension from one measured line to the 160 skin points |
| `BLK` | Blocking, Eq. (43): the skin pressure above the free field |
| `MRP` | Structural modes (NASA's MRP program) |
| `CYL2D`, `CABIN` | Cabin acoustic modes (NASA's CYL2D program); cabin geometry |
| `TRIM`, `HF` | Trim and loss; high-frequency transmission |
| `SHARP` | Sharp's sound-bridge method |
| `Q0`, `BAND`, `H3` | Diagnostics: the q = 0 cabin modes, the band-centre loss factor, the third harmonic |
| `PAIN`, `LOUDEST`, `UNC` | The cabin input check, the loudest point, the uncertainty band |
| `AC` | The aircraft path (a generic aircraft, not a NASA test article) |
| `ISO` | An isolated check of one block |
| `UT` | A unit test shown in the GUI |

## Last part: what kind of comparison

| Suffix | Meaning |
|---|---|
| `EXP` | Against measurement |
| `CODE` | Against what NASA's program printed |
| `PRINTED` | Against values NASA printed |
| `HAND` | Against a hand calculation |
| `QA` | An input check |
| `DECK` | Uses NASA's printed 300-mode structural deck |
| `PRE` | Uses the program form before CR-172428's corrections (the floor sign) |
| `DB`, `DBA` | Overall level in dB; A-weighted |
| `ETAN`, `ETA_N` | The cabin-mode loss factor η_n |
| `EPS_N` | The cabin-mode normalization ε_n |
| `T2` (after `ETA_N`) | NASA's run with trim loss η_T = 2.0 |
| `BR` | With sound bridges |
| `PF` | With the propeller-field coupling (Eq. 8 band average) |
| `REF2` | Against TP-1964's reference 2 (CR-159363) |
| `XOVER` | The crossover frequency |
| `PAIRS` | Pair-by-pair contributions to a tone |
| `CONV` | A grid convergence check |
| `EXT` | With an extrapolated exterior spectrum |
| `18b` | Phase 18b's run (CR-3813 Fig. E-16) |
| `FIGn` | Figure n of the source report |
