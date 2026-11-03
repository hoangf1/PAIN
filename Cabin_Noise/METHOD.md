# Cabin_Noise: which published method each stage follows

**Date:** 2026-11-02. **Sources (in `references/`, from NASA NTRS):**
- NASA CR-132602 (Wilby & Scharton 1975), the sidewall method the plan names. SHA-256 `153677205699f2a6…`.
- NASA TM-85722 (Mixson, O'Neal & Grosveld 1984), the treatment insertion-loss method and its flight validation. SHA-256 `d4d6ac13ec6db822…`.

VERIFICATION.md shows every *equation* is the published one. This file answers a different question: is the *assembled chain* a published method, and where does it differ?

## 1. The chain, stage by stage

| Stage | Cabin_Noise | Published method | Status |
|---|---|---|---|
| Exterior tones | rotating point forces (Gutin / Lowson; Farassat compact strips in blade mode) | Gutin 1936; Lowson 1965; Farassat 1A. CR-132602 assumes the source field as a *diffuse* field (sec. 2.5) | Published source model. The per-patch plane wave is the plan's refinement of CR-132602's diffuse assumption |
| Exterior broadband | Goody wall spectrum, wall -> diffuse field / 2 | Goody 2004; Waterhouse 1955 / CR-3813 p. 23 | Published |
| Sidewall, `tmm` (default) | plane-wave transfer matrix through the whole stack, 0-78 deg field average | Allard & Atalla (TMM); Beranek field incidence; TM-85722 uses field-incidence mass law for the bare wall | Published TL method, **but not the method CR-132602 recommends for the double wall** |
| Sidewall, `cr132602` (option) | non-resonant SEA double wall: skin and trim as mass-law walls (eq. 46, 0-90 deg), absorbing cavity (eqs. 27/51-52), blanket mass on the trim (sec. 6.2) | **CR-132602 sec. 5, eqs. 46-52**, the version its authors found to agree with measured fuselage NR (sec. 6.2, Fig. 14) | **Same as published** (closed form proven against the report's own power balance, `test_methods.py`) |
| Openings | area-weighted composite tau | TM-85722 eq. (1) | Same |
| Cabin level | p^2 = 4 rho c W / A; NR = 10 log10(A / S tau) | CR-132602 eqs. 37, 49 (single-wall form); Sabine | Same (CR-132602 writes 1 + alpha/tau; equal when A >> S tau) |
| Insertion loss | IL = L_bare - L_treated | TM-85722 eqs. (1)-(3): IL = dTL + dABS, dABS = 10 log(alpha_e,t / alpha_e,u) | **Same: proven** (`test_insertion_loss_is_dTL_plus_dABS_as_in_tm85722`) |
| Seats, weighting | room average plus statistics / box modes; IEC A/C | Schroeder; IEC 61672 | Plan additions on top of the published chain |

**Summary.**
- With `sidewall_method = "cr132602"`, the exterior field -> sidewall -> cabin -> insertion-loss chain is the published CR-132602 / TM-85722 procedure.
- With the default `tmm`, every block is published, but the double-wall block is the plan's choice rather than CR-132602's.
- Both are low fidelity. The CR-132602 version needs fewer inputs (masses, cavity depth and absorption), not more.

## 2. Things found in the sources

1. **CR-132602 eq. (53) misprint.** Its first term shows 2/eps, while eq. (52) and the report's own power balance (eqs. 47, 49-51) give 4/eps. A numeric solution of eq. (47) matches 4/eps to 1e-9 (`test_closed_form_nr_equals_the_sea_power_balance`), so 4/eps is used.
2. **Two diffuse conventions.**
   - CR-132602 eq. (46) is the 0-90 deg random-incidence mass law (proven to equal that integral).
   - TM-85722 and the `tmm` default use the 0-78 deg field-incidence average.
   - At a given mass, random incidence transmits more; at TL0 = 30 dB the difference is about 3 dB.
3. **CR-132602's own validation** (sec. 6.2, Fig. 14) is an order-of-magnitude comparison against an empirical NR band. The authors say so explicitly (p. 37).

## 3. CR-132602 Fig. 14 worked example (information only)

**Inputs fixed before computing:**
- rho c = 1.21 x 343;
- skin 0.18 cm aluminium (skin + doubler, spread as the report does for f_c);
- trim 0.04 cm aluminium with **no** blanket mass (the report adds it but never gives it);
- cavity 11.45 cm with the printed cavity absorption;
- cabin alpha = mid-line of the Fig. 4 band read by eye (0.40, 0.53, 0.63, 0.55, 0.43, 0.37 at 125 Hz-4 kHz).

| Band (Hz) | 125 | 250 | 500 | 1000 | 2000 | 4000 |
|---|---|---|---|---|---|---|
| Single wall, ours - Fig. 14 (dB) | -2.5 | -3.1 | -2.7 | -3.4 | -3.6 | -3.2 |
| Double wall, ours - Fig. 14 (dB) | -2.5 | -2.8 | -4.9 | -6.3 | -7.0 | -6.8 |

- **Single wall:** a nearly constant 3 dB below the printed curve, which points to an unprinted convention rather than a frequency-dependent error.
- **Double wall:** the extra shortfall grows with frequency, as the missing blanket mass on the trim would cause.

Neither input is printed, so this is **not** a reproduction verdict. Choosing them to match the figure would be calibration. The implementation itself is verified against the report's equations, not against this figure.

## 4. Effect on the validation record (post-hoc, information only, verdicts unchanged)

The default example gives 86.2 dBA with `tmm` and 97.1 dBA with `cr132602`. The `cr132602` sidewall transmits much more, which is the direction of the `tmm` overpredictions of noise reduction in V4b and V7. A held-out case with printed double-wall inputs (for example TM-85722's lab panels once digitized) is needed before it can carry a verdict.
