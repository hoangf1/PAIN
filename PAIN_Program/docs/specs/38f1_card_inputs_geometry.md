# Task 38f-1 — Manual cards: separate exterior/interior air (ρ, c), cavity length L_c and offset d, rotation direction

Repo `D:\code\PAIN\rea-work\PAIN.jl`. Read `D:\code\PAIN\CLAUDE.md`, `rea-work/docs/IMPLEMENTATION_PLAN.md` §8 Phase 38 (rows 38f and the "Plan for 38f–38h"
paragraph, agreed 2026-10-22) and `rea-work/docs/validation_reports/cr3813_completeness_audit.md` (the card table). Source text: `rea-work/references/Pain User Manual.pdf`
§5.4 (input cards 2, 9, 36 and the paragraphs around them) and CR-3813 `rea-work/references/Pain Methodology.pdf` (§3.4–3.5 for how the cavity length, the
acoustic mode shapes cos(qπx/L_c) and the coupling Eq. (52) enter; Eq. (8) uses V, c0, ρ0). Read the pages yourself (render with the repo's Poppler helper if needed,
page images for CR-3813 are also in `docs/specs/cr3813_pages/` and `data/cr3813/pages/`). Implement the text as printed; state every reading you decided and why.
No comparison criterion: this is input plumbing. Defaults must reproduce **all current outputs exactly** (bitwise or to 1e-12 relative).
No commit. Never open a GUI window. Do not write IMPLEMENTATION_PLAN entries (the reviewer does); update README / flowchart / METHODOLOGY /
VALIDATION_GUIDELINE for what you add. Do not edit reference/digitized CSVs or existing validation reports (new ones only). Do not touch regenerated figure PDFs.

## What to add
1. **Card 2:** separate exterior and interior air density and sound speed: new `PainInputs` keywords `ρ_ext, c_ext, ρ_int, c_int` (default = `ρ0`, `c0`, so
   the single-air case is unchanged). Use the interior values where the Manual/Methodology use them for the cavity (modes, V c0² terms, η_n, Eq. 7/8 pressure, ᾱ)
   and the exterior values for the blocked/radiation side (blocked pressure, η_rad^ext, ρ0 in τ_R, Eq. 19–23 as printed with ρ0 exterior and ρ interior). State the map
   term-by-term in the code comment. Keep `ρ0`, `c0` fields as the single-air entry points (they set both when the new ones are not given).
2. **Card 9:** cavity length L_c and offset d (cavity ≠ structure). Acoustic mode shapes and V = (cross-section) × L_c use L_c; the coupling integral between the acoustic
   mode and a structural mode over the overlap of [d, d+L_c] with the structure [0, L] as the text defines (read it). Defaults L_c = L, d = 0.
3. **Card 36:** rotation direction ±1 (default +1 = current behaviour). Define from the Manual text exactly what it flips (blade passage phase / azimuth sense of the
   grid and of the phase φ_p), implement it where the grid angles and phases enter, and state the convention in METHODOLOGY. Do not adopt any lower-quarter grid mirroring.
Expose the new inputs through the same paths existing inputs use (JSON case files if a loader exists, GUI model input echo if there is a generic list; do not redesign the GUI).

## Tests (V-UNIT)
1. Defaults reproduce current results exactly: tone SPL (Eq. 8), `noise_reduction_spectrum`, `hf_broadband` path, REPRO_18b numbers (compare against computed values from the unchanged path).
2. `ρ_ext = ρ_int`, `c_ext = c_int` equal to `ρ0`, `c0` → identical. A case with ρ_int ≠ ρ_ext changes only the terms listed in your map (check at least two by hand).
3. L_c = L, d = 0 identical; L_c < L with d > 0: V scales as L_c, mode set changes as expected, coupling factor for a mode pair equals direct numerical integration over the overlap (1e-6 relative).
4. Rotation direction −1 mirrors the right quantity (state it) and +1 is unchanged; applying −1 twice (via two flips) restores the original.
Run only the new testset and "Validation case registry" via `Pkg.test("PAIN"; test_args=[...])`; do not run the full suite. Report: the term map for card 2, how L_c/d enter,
what rotation direction flips, tests run and their results.
