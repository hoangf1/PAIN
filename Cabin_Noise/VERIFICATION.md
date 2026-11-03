# Cabin_Noise: verification of the underlying math

**Date:** 2026-11-02. **Tests:** `tests/test_sources.py`, `tests/test_core.py`, `tests/test_blade.py`, `tests/test_verification_cases.py`, all run by `pytest`.

This file asks one question: is every equation the published one, implemented correctly? It does not ask whether the low-fidelity model matches measurements; that is validation, recorded in `projectPlan.md` and the Validation tab.

Each check compares the code with something *outside its own code path*:
- **Published number:** a value printed in a standard or textbook.
- **Independent derivation:** the same physics computed another way.
- **Identity:** a physical law the result must obey.

A test that only re-evaluates the formula it checks does not count.

## 1. Verification matrix

| # | Module | Equation (as implemented) | Source | Independent check | Kind | Status |
|---|---|---|---|---|---|---|
| 1 | atmosphere | ISA troposphere / lower stratosphere T(h), p(h); rho = p / RT; c = sqrt(gamma R T) | US Standard Atmosphere 1976 | T, p, rho at 0, 5, 11, 15 km vs the table (`test_isa_against_tables`) | published number | pass |
| 2 | atmosphere | Sutherland mu = 1.458e-6 T^1.5 / (T + 110.4) | US Std Atm 1976 | mu(288.15 K) = 1.7894e-5 Pa s | published number | pass |
| 3 | mission | TAS = IAS sqrt(rho0 / rho) (IAS taken as EAS) | standard EAS relation | sea level TAS = IAS; altitude TAS > IAS | identity | pass |
| 4 | source_tonal | p = -d/dx_i [F_i / (4 pi r abs(1 - M_r))]_ret for each blade force; harmonics as a Fourier integral over emission time; closed-form delay s | Lowson 1965 (Proc. R. Soc. A 286); Ffowcs Williams-Hawkings compact loading (Farassat 1A, compact) | (a) static far field vs Gutin within 0.04 dB (V0a). (b) **Forward flight, near field:** a direct time-domain solution (Newton iteration for the emission time at uniform reception times, finite differences at fixed t, FFT) agrees within 0.05 dB (`test_moving_force_against_direct_time_domain_solution`). (c) 1/r far-field decay | independent derivation | pass |
| 5 | source_tonal | Gutin: p_m,rms = (mB Omega / 2 sqrt2 pi c r) abs(T cos(theta) - Q c / (Omega R_e^2)) J_mB(mB Omega R_e sin(theta) / c) | Gutin 1936; Hubbard (ed.), NASA RP-1258 vol. 1 ch. 1 | Derived independently from the moving-dipole integral (Jacobi-Anger); force signs fixed by this derivation (see projectPlan "Implementation notes" 1) | independent derivation | pass |
| 6 | blade | Strip sum of compact forces | Farassat 1A, compact, radial strips (as PAIN_Program's AcousticAnalogies chain) | Far field equals Gutin integrated strip by strip within 0.2 dB; one strip equals the point source exactly | independent derivation | pass |
| 7 | blade | Glauert blade-element momentum: B 1/2 rho W^2 c (cl cos(phi) - cd sin(phi)) = 4 pi rho r F (V + v) v | Glauert; Leishman, *Principles of Helicopter Aerodynamics* ch. 3 | Many blades, cd = 0, ideal twist: P = T^1.5 / sqrt(2 rho A) of actuator-disk momentum theory within 3 % (`test_bemt_reduces_to_momentum_theory`); hover figure of merit < 1 | independent derivation | pass |
| 8 | blade | Prandtl tip loss F = (2/pi) acos(exp(-B (R - r) / (2 r sin(phi)))) | Glauert; Leishman ch. 3 | Loading falls monotonically over the outer blade and the tip strip is well below the peak | identity | pass |
| 9 | blade | Thin-airfoil section: cl = 2 pi (alpha - alpha0) / sqrt(1 - M^2), alpha0 = -cl_design / 2 pi (NACA a = 1.0 mean line) | Abbott & von Doenhoff, *Theory of Wing Sections* sec. 4; Prandtl-Glauert | More pitch gives more thrust; BEMT C_T on the Report 996 blade is within 7-12 % of the printed value (information) | identity | pass |
| 10 | scattering | Rigid cylinder surface factor S = (2j / pi ka) sum eps_n j^n cos(n phi) / H_n'(ka) | Morse & Ingard, *Theoretical Acoustics* sec. 8.1 | The full incident + scattered series has zero radial velocity at r = a and equals S there (to 1e-9) for ka = 0.5, 2, 8; limits 0 dB as ka -> 0 and +6 dB at the lit point for large ka (V0b) | independent derivation | pass |
| 11 | source_tbl | Goody spectrum Phi U_e / (tau_w^2 delta) = 3 w~^2 / [(w~^0.75 + 0.5)^3.7 + (1.1 R_T^-0.57 w~)^7], R_T = (delta/U_e) / (nu/u_tau^2) | Goody 2004, AIAA J. 42(9) | Asymptotic slopes w^2 (low), about w^-0.7 (overlap), w^-5 (high) as stated in the source | identity | pass |
| 12 | source_tbl | delta = 0.37 x Re_x^-0.2, C_f = 0.0592 Re_x^-0.2 | Schlichting, *Boundary-Layer Theory* ch. 21 (1/7-power law) | Formula check | published formula | pass |
| 13 | porous | Delany-Bazley Z_c, k_c (e^{+jwt}), valid 0.01 <= rho f / sigma <= 1 | Delany & Bazley 1970; Allard & Atalla, *Propagation of Sound in Porous Media* sec. 2.5 | Passive and causal in range (Re Z_c > 0, Im Z_c < 0, Im k_c < 0, slower than air); tends to air as X -> infinity. **Use outside the range now raises a result warning** | identity | pass |
| 14 | materials | Measured-table porous layer: k_c = 2 pi / lambda - j alpha_dB / 8.686, Z_c = abs(W) e^{-j phi} | CR-3813 Fig. A-2 quantities | Fed Delany-Bazley's own values, it reproduces the Delany-Bazley layer exactly | independent derivation | pass |
| 15 | tmm | Layer matrices (panel [[1, Z_p], [0, 1]]; fluid [[cos kd, j Z sin kd], [j sin kd / Z, cos kd]]); tau = abs(2 / (T11 + T12 cos(theta)/Z0 + T21 Z0/cos(theta) + T22))^2 | Allard & Atalla ch. 11 (transfer matrix method) | (a) Normal-incidence single panel = mass law exactly (V1). (b) **Mass-air-mass double wall equals the hand-derived closed form** (London 1950) to 1e-6 (`test_tmm_double_wall_matches_closed_form`). (c) Reciprocity: tau(stack) = tau(reversed stack) to 1e-9 | published / derivation / identity | pass |
| 16 | tmm | Panel Z_p = jwm [1 - (f/f_c)^2 sin^4(theta) (1 + j eta)] | Cremer, Heckl & Petersson, *Structure-Borne Sound* | At the coincidence angle sin^2(theta) = f_c/f, tau = 1 / (1 + wm eta cos(theta) / 2 rho c)^2 exactly (`test_coincidence_at_oblique_incidence`); diffuse TL dips below the mass law at f_c | independent derivation | pass |
| 17 | tmm | Field-incidence average over 0-78 deg with sin(theta) cos(theta) weighting | Beranek (field-incidence convention) | 20 log(mf) - 47 within 0.8 dB below f_c (V2); f0 dip location (V3) | published formula | pass |
| 18 | tmm | Curved skin: -j m w_r^2 / w, f_r = c_L / 2 pi R | Fahy & Gardonio, *Sound and Structural Vibration* (ring frequency) | Breathing-mode stiffness E h / ((1 - nu^2) R^2) equals m w_r^2 (algebraic); more TL below f_r in a test | identity | pass (approximation; see sec. 3) |
| 19 | tmm / materials | Stiffened bay: -j s / w, s = 1 / sum_{m,n odd} 64 / (pi^8 D m^2 n^2 (m^2/a^2 + n^2/b^2)^2) (static Navier stiffness, simply supported) | Timoshenko & Woinowsky-Krieger, *Theory of Plates* sec. 30; Leissa (f11) | The same Navier series gives the **tabulated centre deflection 0.00406 q a^4 / D** of a square plate (Table 8); f11 equals Leissa's formula; TL = spring law at f11/8 and mass law at 6 f11 | published number | **corrected**, now pass |
| 20 | cabin | p^2 = 4 rho c W / A; T60 = 0.161 V / A; diffuse incident intensity = p^2 / (4 rho c) | Sabine; Kuttruff, *Room Acoustics* | 0.161 = 24 ln10 / 343; **plane-wave Monte Carlo of a diffuse field:** the intensity onto a wall equals p^2 / (4 rho c) within 10 % (`test_waterhouse_wall_factor_and_diffuse_intensity`) | identity / derivation | pass |
| 21 | pipeline | Boundary-layer wall pressure to an equivalent diffuse field: <p_e^2> = <p_wall^2> / 2 | Waterhouse 1955 (JASA 27); CR-3813 p. 23 (as PAIN_Program `noise_reduction.jl:261`) | Same Monte Carlo: wall mean square = 2 x field mean square within 10 % | independent derivation | **corrected** (was / 4), now pass |
| 22 | pipeline | Reverberant NR = 10 log10(A / sum S_i tau_i) | follows from 20 (Beranek) | Algebra from rows 20 and 15; doubling T60 changes NR by exactly -3.01 dB (test) | identity | pass |
| 23 | seats | Box modes f_n = (c/2) sqrt((n_x/L_x)^2 + ...); eta = 2.2 / (f T60); L95 = L + 10 log10(ln 20) | Kuttruff; Schroeder 1962 | Volume mean of G / <G> = 1 (V0c); 2.2 = 6 ln10 / 2 pi; the P95 of an exponential sample equals 10 log10(ln 20) within 0.05 dB | identity / derivation | pass |
| 24 | weighting | A and C weightings (IEC 61672 analog filter forms, +2.00 / +0.06 dB) | IEC 61672-1 | 9 octave values vs the IEC table within 0.1 dB, at exact base-10 frequencies | published number | pass |
| 25 | frequencies | 1/3-octave centres 1000 x 10^(n/10); edges f_c x 2^(+-1/6) (plan A.8) | IEC 61260 (centres) | Labels; band index | published | pass (note: edges use base 2, centres base 10; the difference is 0.05 %) |
| 26 | pipeline | Twin combination (energetic, coherent with m Delta phi, worst case); measured anchoring; K_refr | definitions (plan A.2) | Worst >= energetic; anchored level reproduced exactly; K_refr shifts tones 1:1 | identity | pass |
| 27 | pipeline | Patch grid quadrature | numerical integration of plan A.6 | 30 x 15 within about 1 dB of 48 x 24 | convergence | pass |

## 2. Corrections made by this review (2026-11-02)

1. **Boundary-layer to diffuse conversion (row 21).**
   - Plan A.6 used p_inc^2 = p_wall^2 / 4 ("-6 dB"). That is the *single plane wave* pressure doubling.
   - For a diffuse field the wall mean square is twice the field mean square (Waterhouse), and CR-3813 uses the same factor. Now / 2.
   - Effect: the boundary-layer (broadband) cabin level rises 3 dB. The default cruise case goes from 85.1 to 86.1 dBA.
   - Recorded validation verdicts are unchanged. A post-hoc re-run (information only): V6 goes from 251 to 249 of 519 points within +-6 dB, still not met; V5b is unaffected (it compares wall pressure).
2. **Stiffened-bay stiffness (row 19).**
   - The first version used rho h w11^2. A simply supported plate under uniform pressure has a volume-velocity stiffness of (pi^4/64) rho h w11^2 for the (1,1) term; the exact Navier series is about 1.5 % softer than that.
   - It now uses the exact static Navier stiffness. V4c is unchanged (the term had no effect there).
3. **Scattering series truncation:** N = ceil(ka) + 10 left a 2e-6 truncation error. N is now ceil(ka) + 20 (row 10).
4. **Delany-Bazley validity:** use outside 0.01 <= rho f / sigma <= 1 now adds a result warning. The default blanket triggers it below about 100 Hz.

## 3. Correct as implemented, but approximations (low fidelity by design)

These are not errors in the math. They are the plan's stated simplifications, and the validation cases measure their cost:
- **Infinite-panel, plane-wave transmission.** Finite-structure modes are absent. The ring-frequency term models only the breathing (n = 0) stiffness, applied at every angle. This is the main cause of the V4a, V4b/c and V7 misses.
- **Rigid-frame blanket.** A real limp blanket moves with the air at low frequency. V6 overpredicts insertion loss below 250 Hz.
- **Single effective radius** for the default source. The blade-geometry mode removes the bias (V5c vs V5d).
- **Boundary layer as an equivalent diffuse field.** This overstates the coupling of a convected boundary layer, so the level is an upper bound, as the plan states.
- **Sabine room equation for tones below the Schroeder frequency.** The seat model supplies only the spatial shape.
- **One rpm per run.** Twins at different rpm are run per engine and added in energy (V6, V7 runners).

## 4. How to re-run

```bash
.venv/Scripts/python -m pytest -q          # 74 tests, about 15 s
```
