# Phase 110 — FLIGHT_MODES second transcription pass (2026-10-30)

Plan `IMPLEMENTATION_PLAN.md` §8az (now in `COMPLETED_PHASES.md`). Data quality and a diagnostic; FLIGHT_MODES' verdict
(first pass, not met, 197/221) stays on record.

**Second pass.** CR-172428 App. C pp. 213–216 read again by eye from 300 dpi renders, without looking at this code's values,
adding CMNS/CMNP and the printed SHELL W and PLATE W masses: `appC_merlin_structural_modes_checked.csv` (221 modes; Phase
101's file is unchanged). Compared with the first pass on f, type, M, NS and total mass: 4 disagreements, all re-read at
600 dpi. Mode 44 M = 5 and mode 159 total 54.38 (the first pass was right); mode 174 total 73.40 (was 79.40) and mode
230 M = 4 (was 1; one of Phase 101's two frequency misses) (the second pass was right).

**FLIGHT_MODES_P2 (diagnostic, post-hoc):** 199/221 (90.0 %) within 2 % in frequency and 10 % in generalized mass, at the
criterion's threshold; frequencies 220/221 (mode 29, f within 2 % since the M reading is the same in both passes, is the
remaining frequency miss through its mass).

**Where the mass misses come from.** For every printed mode, this code's shell and plate normal-displacement parts of the
generalized mass (`_mode_mass_parts`, from the full shape) against NASA's SHELL W and PLATE W: shell 221/221 within 10 %,
plate 218/221 (within 10 %, or 0.1 kg where NASA prints under 0.5 kg). At all 22 modes that miss the total, the shell part
matches and the plate part matches at 20; e.g. mode 41: shell 19.749 / 19.755 kg, plate 4.557 / 4.562 kg, total 1002.69 /
1800.91 kg. The differences are therefore in the in-plane (u, v) part of the generalized mass, mostly of floor-dominated or
near-degenerate modes; the coupling and Ψ_G use the normal displacements, which match.
