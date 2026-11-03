# Cabin_Noise code audit (2026-11-02)

**Scope:** every module of `cabin_noise/core`, the case runners, the GUI and the docs. The question was whether the code is a faithful low-fidelity interior-noise estimate built from the referenced papers (METHOD.md), with nothing beyond them.

**Method:**
- `pyflakes` over the code and tests;
- a grep for leftovers of the retired pipeline;
- a line-by-line read of each block against its paper;
- tests for every fix;
- a re-run of all cases and the GUI smoke test.

## Verdict

**The pipeline is the papers' method.**

| Block | Status |
|---|---|
| Gutin | matches RP-1258 ch. 1 |
| Goody | matches Goody 2004 |
| CR-132602 eqs. (46) and (52) | match the report, with eq. (53)'s misprint resolved by eq. (47) |
| TM-85722 eq. (1), IL decomposition | match |
| Sabine, Schroeder statistic, IEC weighting | match |

Each block has a test against an independent evaluation; see VERIFICATION.md.

The audit found **no error in any paper equation**. It found and fixed two wiring issues and some housekeeping.

## Findings and decisions

| # | Finding | Severity | Decision |
|---|---|---|---|
| F1 | Window and door area was applied once, whatever the exposed area. The boundary-layer path, which exposes both sides, therefore had half the window share of the tone path. | wiring error | **Fixed.** Openings are defined per side and scale with the exposure S / side_area. Test: `test_openings_scale_with_the_exposed_area`. The end-to-end hand check caught the change and was updated to the documented rule. |
| F2 | The V6 runner runs each engine separately (the pipeline holds one rpm per run) and added the runs' total levels, so the boundary layer was counted twice. | runner error | **Fixed.** Tones are added across engines and the boundary layer is counted once. Test: `test_v6_runner_counts_the_boundary_layer_once`. Re-run: V6 is unchanged (372/519, not met), because the doubling appeared in both bare and treated runs and cancelled in the IL. |
| F3 | `log10(0)` runtime warnings for a static segment with no boundary layer. | cosmetic | Fixed in `energetic_sum` (an empty spectrum sums to -inf). |
| F4 | Dead code and stale labels: `log_subfrequencies`, an unused variable, unused GUI imports, the sweep label "first panel", and a V4 quantity naming a runner that does not exist. | housekeeping | Removed or relabelled. |
| F5 | ρc convention: tau uses cabin rho c although the exterior is at altitude. | checked, correct | No change. For a mass-controlled wall the transmitted power depends on the blocked pressure and the receiving side's rho c only, so cabin rho c is right. This also reproduces TM-85722 App. A's 1-2 dB cabin-pressure effect. |
| F6 | Gutin is a static formula but is used with the flight thrust and torque. | method limit | No change. It is the paper's method; documented in METHOD.md and the Propeller tab. |
| F7 | The 95th-percentile seat (+4.8 dB) is applied in all bands, but the statistic holds only above the Schroeder frequency. | method limit | No change to the method. The Interior plot legend now says where it holds. |
| F8 | Both walls' tau use the same rho c, as CR-132602 assumes one medium. | checked | Consistent with F5. |

## Not changed (by design)

- The validation misses (V4a, V4b, V5, V5c, V6, V7) are where the papers' stated limits put them; METHOD.md sec. 4 explains each. Fixing them would mean moving past these papers to higher fidelity, which is out of scope by the author's decision of 2026-11-02.
- PAIN_Program is not touched. The Goody-in-PAIN idea is parked at the author's request.

## State after the audit

- **Tests:** 47 pass (`pytest`); `pyflakes` is clean; the GUI smoke test passes.
- **Verification:** 4/4 checks ok.
- **Validation:** 1 of 8 met (V5b); V6 at 72 % (75 % needed); the others as recorded in cases.yaml.
- **Default cruise case:** 98.2 dBA room average, 103.0 dBA at the 95th-percentile seat.
