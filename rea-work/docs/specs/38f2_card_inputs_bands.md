# Task 38f-2 — Manual cards: user 1/3-octave band set, per-band structural and bare acoustic loss-factor input

Repo `D:\code\PAIN\rea-work\PAIN.jl`. Read `D:\code\PAIN\CLAUDE.md`, `rea-work/docs/IMPLEMENTATION_PLAN.md` §8 Phase 38 ("Plan for 38f–38h", agreed 2026-10-22; the
38f-1 result paragraph) and `rea-work/docs/validation_reports/cr3813_completeness_audit.md` (card table: cards 3–6 band set, cards 11–18 per-band loss factors).
Source text: `rea-work/references/Pain User Manual.pdf` §5.4 (read the pages for those cards yourself; render with the repo's Poppler helper if needed) and CR-3813 §3.8
(Eqs. 74–83) in `rea-work/references/Pain Methodology.pdf`. Implement as printed; state every reading you decided. Inputs only, no comparison criterion. Defaults must reproduce
**all current outputs exactly**. No commit. Never open a GUI window. Do not write IMPLEMENTATION_PLAN entries (the reviewer does); update README / flowchart / METHODOLOGY /
VALIDATION_GUIDELINE. Do not edit reference/digitized CSVs or existing validation reports (new ones only). Do not touch regenerated figure PDFs. Do not leave helper scripts in the repo.

## What to add
1. **Cards 3–6:** user-chosen 1/3-octave band set (≤ 26 bands per the Manual): a `bands` input (vector of band centres, validated: standard 1/3-octave centres, count ≤ 26, ascending)
   used by `interior_spl` broadband/third-octave path, `noise_reduction_spectrum`, `hf_broadband_spectrum`; default = the current fixed list. Reject invalid sets with a clear error.
2. **Cards 11–18:** per-band structural loss factor η_r (input per band, Manual meaning; if 0 or absent the program computes it as now from Eqs. 74–83) and per-band bare acoustic loss
   factor η_n,bare (if 0 or absent computed from the trim as now). Interpolation/lookup rule for a tone frequency or mode frequency that is not a band centre: use the band that contains it
   (1/3-octave edges), as the Manual says (read it). New `PainInputs` keywords (e.g. `η_r_band`, `η_n_band` as band-keyed vectors/dicts); defaults `nothing` → unchanged.
3. Expose through the same loaders/echo paths as 38f-1 (JSON case files, GUI model input list) without GUI redesign.

## Tests (V-UNIT)
1. Defaults reproduce current tone SPL, NR spectrum, hf broadband, REPRO_18b values exactly.
2. Band set: custom subset gives identical values at those bands as the default list; invalid sets (non-standard centre, > 26, unsorted) raise.
3. Loss-factor override: setting a band's η to exactly the value the program computes there reproduces the result exactly; setting a different value changes only quantities in that band (and the
   tone of any harmonic inside it); a zero entry falls back to the computed value.
Run only the new testset and "Validation case registry" via `Pkg.test("PAIN"; test_args=[...])`; do not run the full suite. Report: reading decisions, how the band lookup works, tests run.
