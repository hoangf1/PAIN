# Phase 66: further code checks of the BEMT and F1A source blocks

Criteria and readings fixed 2026-10-24 in `IMPLEMENTATION_PLAN.md` §8j, after the author's go-ahead and before any run.
No measured data is used. CCBlade.jl and AcousticAnalogies.jl are taken as correct; every check targets how this project
sets them up and combines them (stations, inflow, frames, span weights, reception window, FFT) and the hand references
written for the checks. Neither package was changed.

| Step | Case | Block | Result | Numbers |
|------|------|-------|--------|---------|
| 66a | BEMT_MOMENTUM | A_LOADS | **met** 72/72 | worst relative difference 1.1e-11 (criterion 1e-8) |
| 66b | BEMT_HAND_TIP | A_LOADS | **met** 4/4 (re-run after a fix of the hand reference) | wrapper = hand to 5 digits; CCBlade's φ zeroes the hand residual (≤ 6e-13) |
| 66c | BEMT_INTEGRALS | A_LOADS | **met** 7/7 | η 0.593 ≤ η_i 0.919 (Hartzell), 0.626 ≤ 0.774 (Report 996); ΔT −0.07 % on halving the spacing |
| 66d | BEMT_SIMILARITY | A_LOADS | **met** 6/6 | C_T, C_P equal to 1e-16 at fixed J |
| 66e | F1A_GUTIN_ANGLES | A_AMP | **not met** 4/5 | levels within 0.26 dB at θ = 30°–150°; phase at 60° off by 14.6° |
| 66f | F1A_GW_FLIGHT | A_AMP | **met** 6/6 | within 0.07 dB of Garrick–Watkins at M_x = 0.1, 0.2 |
| 66g | F1A_THICKNESS | A_AMP | **met** 9/9 | within 0.002 dB of the compact far-field thickness form, H1–H3 |
| 66h | F1A_PROPERTIES | A_AMP | **met** 5/5 | B scaling 2.000; 1/r 2.0002; 64→128 source times −4e-6 dB; 20→39 stations 0.025 dB |

## Readings found in the code before the runs

- **CCBlade's reported induction.** CCBlade applies the tip/hub loss to the loads and rescales the reported u, v by an
  effective G (CT = 4a(1+a)F = 4aG(1+aG)). A momentum check written with the reported u and the loss factor F differs by
  exactly 1/F; the check therefore uses the raw induction a = k/(1−k), a′ = k′/(1+k′) recomputed from the outputs, and
  CCBlade's G form separately. Both hold to 1e-11.
- **Frame.** AcousticAnalogies translates the rotor along +X (`ccblade_helpers.jl`), so +X is the flight direction, the
  force on the fluid is −T x̂, and observers moving with the propeller have v = [V, 0, 0]. Gutin's and Garrick–Watkins'
  signs follow from this, not from a comparison.
- **Span weights.** AcousticAnalogies gives each section its midpoint span (`get_dradii`), CCBlade's `thrusttorque` uses the
  trapezoid with zero hub/tip loads. F1A therefore radiates 0.997 (Hartzell) and 1.0004 (Report 996) of the BEMT thrust,
  a 0.03 dB effect; the 66e–66g references use AcousticAnalogies' spans.

## The two first-run misses

**66b (hand reference defect, fixed).** The first run gave 0/4: the hand solver took the first sign change of the
residual from small φ, and near the tip (r/R = 0.97) that sign change is the pole k = 1, where a = k/(1−k) → ±∞, not a
root (loads of 1284 N/m against CCBlade's −37 N/m). CCBlade's φ zeroes the hand residual there (6e-13), so CCBlade's
answer is a root of the same equations. With brackets that do not go to zero rejected, the hand BEM equals the wrapper to
five digits. This was a defect of the check, not of the code under test; the result is labelled as a re-run after the fix.

**66e (near-null phase, not met, unchanged criterion).** At θ = 60° the thrust and torque terms of Gutin's bracket cancel
to 5.7 % of their sum, so the tone is 22 dB below the in-plane level and its phase is set by small remainders. At 100 R_tip
the F1A phase relative to 90° is 165.4° against 180°; at 400 R_tip (post-hoc) it is 176.3°, consistent with an O(1/r²)
near-field term that the far-field Gutin form omits. Levels agree within 0.26 dB at all five angles.

## Code changes

- `propeller_ccblade.jl`: the CCBlade set-up shared by `evaluate_propeller_source`, `ccblade_section_operating_points`
  and the Phase 66 checks is `_ccblade_setup`; the F1A → reception → FFT step is `_f1a_harmonics`. Behaviour unchanged
  (F1A_GUTIN Δ = 0.0288 dB and the propeller unit tests before and after).
- `validation_case_iso66.jl`: the eight cases; unit tests `test/unit/test_case_helpers_iso66.jl`.

## What this does and does not show

The BEMT and F1A blocks as this project uses them now pass every closed-form and identity check proposed for them except
one near-null phase at 100 R_tip. This is code verification. It says nothing about how well the predicted loads or noise
match a real propeller: the experimental cases (Report 996, Pereira, BBN) remain not met, attributed to the section polars
and the inputs, and the aircraft source stays X-EXTRAP.
