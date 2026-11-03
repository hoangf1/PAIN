"""CR-132602 non-resonant double-wall noise reduction (Wilby & Scharton 1975, sec. 5).

Statistical energy analysis with three acoustic spaces: exterior (1), sidewall cavity (3) and
cabin (5). Skin (2) and trim (4) transmit non-resonantly (mass law). Power balance, eq. (47):
    w eta3 E3 + w n3 eta31 (E3/n3 - E1/n1) + w n3 eta35 (E3/n3 - E5/n5) = 0
    w eta5 E5 + w n5 eta53 (E5/n5 - E3/n3) = 0
with modal densities n_i ~ V_i (eq. 7), reciprocity n_i eta_ij = n_j eta_ji, coupling
eta_3,1 = c S2 tau_31 / (8 pi f V3), eta_3,5 = c S4 tau_35 / (8 pi f V3) (eq. 50), cabin loss
eta5 = c S5 alpha5 / (8 pi f V5) (eq. 37), cavity loss eta3 = S3 c alpha3 / (2 eps pi f V3),
eps = pi below c / 2 L3 and 4 above (eqs. 51, 52). Solved in closed form this gives
    NR = 10 log10[(1 + (4/eps) (S3/S2) alpha3 / tau31)(1 + (S5/S4) alpha5 / tau35) + (S5/S2) alpha5 / tau31]
which is the printed eq. (52) for S2 = S3 = S4 = S5. (The printed eq. (53) shows 2/eps in the first
term; eqs. (49)-(52) give 4/eps, used here; see METHOD.md.)
Wall transmission is the diffuse-field mass law of eq. (46), integrated over 0-90 degrees:
    tau = (rho c / (pi f m))^2 ln[1 + (pi f m / rho c)^2].
"""
from __future__ import annotations

import numpy as np


def tau_mass_law_diffuse(f, m, rho_c):
    """CR-132602 eq. (46): random-incidence (0-90 deg) mass-law transmission coefficient."""
    x = np.pi * np.asarray(f, dtype=float) * m / rho_c
    return np.log1p(x ** 2) / x ** 2


def eps_factor(f, c, L3):
    """CR-132602 eq. (52): eps = pi below the cavity cross-mode frequency c / 2 L3, 4 above."""
    return np.where(np.asarray(f, dtype=float) < c / (2.0 * L3), np.pi, 4.0)


def nr_double_wall(f, *, m_skin, m_trim, L3, alpha3, alpha5, rho, c, S2=1.0, S3=None, S4=None, S5=None):
    """Non-resonant double-wall noise reduction, CR-132602 eqs. (46), (49)-(52), dB.
    alpha3: cavity absorption coefficient; alpha5: cabin mean absorption coefficient
    (arrays over f or scalars). Areas default to S2 = S3 = S4 = S5."""
    S3 = S2 if S3 is None else S3
    S4 = S2 if S4 is None else S4
    S5 = S2 if S5 is None else S5
    t31 = tau_mass_law_diffuse(f, m_skin, rho * c)
    t35 = tau_mass_law_diffuse(f, m_trim, rho * c)
    e = eps_factor(f, c, L3)
    a3, a5 = np.asarray(alpha3, dtype=float), np.asarray(alpha5, dtype=float)
    return 10 * np.log10((1 + (4 / e) * (S3 / S2) * a3 / t31) * (1 + (S5 / S4) * a5 / t35) + (S5 / S2) * a5 / t31)


def nr_single_wall(f, *, m, alpha5, rho, c, S2=1.0, S5=None):
    """Single wall between a diffuse exterior and the cabin: NR = 10 log10(1 + (S5/S2) alpha5 / tau)."""
    S5 = S2 if S5 is None else S5
    return 10 * np.log10(1 + (S5 / S2) * np.asarray(alpha5, dtype=float) / tau_mass_law_diffuse(f, m, rho * c))


def tau_equivalent(nr_db, alpha5, S2=1.0, S5=None):
    """Transmission coefficient that gives the same NR through the room equation's single-wall form,
    so a CR-132602 sidewall can drive the pipeline: tau = (S5/S2) alpha5 / (10^(NR/10) - 1)."""
    S5 = S2 if S5 is None else S5
    return (S5 / S2) * np.asarray(alpha5, dtype=float) / (10 ** (np.asarray(nr_db) / 10) - 1)
