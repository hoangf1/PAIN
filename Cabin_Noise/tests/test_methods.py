"""The pipeline stages against the published methods they claim to follow (METHOD.md):
CR-132602 (Wilby & Scharton 1975) for sidewall noise reduction, TM-85722 (Mixson, O'Neal &
Grosveld 1984) for treatment insertion loss."""
import copy

import numpy as np
import pytest
from scipy.integrate import quad

from cabin_noise.core import sea
from cabin_noise.core.io import default_project
from cabin_noise.core.pipeline import insertion_loss, reverberant_noise_reduction, run_case

RHO, C = 1.21, 343.0


def test_eq46_is_the_0_to_90_degree_average_of_the_mass_law():
    """CR-132602 eq. (46) equals the random-incidence integral of eq. (45),
    tau_d = int_0^{pi/2} tau(phi) sin(2 phi) dphi with tau = 1 / (1 + (pi f m cos(phi) / rho c)^2)."""
    for f, m in ((125.0, 2.5), (1000.0, 2.5), (4000.0, 5.0)):
        x = np.pi * f * m / (RHO * C)
        num = quad(lambda p: np.sin(2 * p) / (1 + (x * np.cos(p)) ** 2), 0, np.pi / 2)[0]
        assert sea.tau_mass_law_diffuse(f, m, RHO * C) == pytest.approx(num, rel=1e-9)


def test_closed_form_nr_equals_the_sea_power_balance():
    """Solve CR-132602 eq. (47) numerically (energies E3, E5 for a unit exterior energy density, with
    the loss and coupling factors of eqs. 7, 37, 50, 51 and reciprocity) and compare with the closed
    form of eq. (52) generalised to unequal areas."""
    f = np.array([100.0, 400.0, 1600.0, 3000.0])
    S2, S3, S4, S5, V3, V5, L3 = 2.0, 2.6, 1.7, 9.0, 0.2, 30.0, 0.1
    m2, m4, a3, a5 = 4.0, 1.5, 0.6, 0.35
    nr = sea.nr_double_wall(f, m_skin=m2, m_trim=m4, L3=L3, alpha3=a3, alpha5=a5, rho=RHO, c=C,
                            S2=S2, S3=S3, S4=S4, S5=S5)
    for i, fi in enumerate(f):
        t31 = sea.tau_mass_law_diffuse(fi, m2, RHO * C)
        t35 = sea.tau_mass_law_diffuse(fi, m4, RHO * C)
        eps = np.pi if fi < C / (2 * L3) else 4.0
        e31 = C * S2 * t31 / (8 * np.pi * fi * V3)
        e35 = C * S4 * t35 / (8 * np.pi * fi * V3)
        e53 = e35 * V3 / V5                                  # reciprocity, n ~ V (eq. 7)
        e3 = S3 * C * a3 / (2 * eps * np.pi * fi * V3)
        e5 = C * S5 * a5 / (8 * np.pi * fi * V5)
        # unknowns: modal energies u3 = E3/n3, u5 = E5/n5; exterior u1 = 1 (energy per mode ~ <p^2>)
        A = np.array([[e3 + e31 + e35, -e35], [-e53, e5 + e53]])
        u3, u5 = np.linalg.solve(A, np.array([e31 * 1.0, 0.0]))
        assert nr[i] == pytest.approx(10 * np.log10(1.0 / u5), abs=1e-9)


def test_double_wall_nr_limits():
    f = np.array([200.0, 1000.0])
    kw = dict(m_skin=4.0, L3=0.1, alpha3=0.5, alpha5=0.4, rho=RHO, c=C)
    # a transparent trim (m -> 0) leaves the single skin plus a cavity in series that absorbs
    single = sea.nr_single_wall(f, m=4.0, alpha5=0.4, rho=RHO, c=C)
    assert np.all(sea.nr_double_wall(f, m_trim=1e-9, **kw) > single)
    # a heavier trim always increases NR
    assert np.all(sea.nr_double_wall(f, m_trim=3.0, **kw) > sea.nr_double_wall(f, m_trim=1.0, **kw))
    # the equivalent tau reproduces the NR through the single-wall room form
    nr = sea.nr_double_wall(f, m_trim=1.0, **kw)
    t = sea.tau_equivalent(nr, 0.4)
    assert np.allclose(10 * np.log10(1 + 0.4 / t), nr)


def test_pipeline_single_wall_nr_matches_the_classical_form():
    """Our reverberant NR = 10 log10(A / sum S tau) is CR-132602's single-wall NR without the '1 +'
    (the two agree when A >> S tau); with tau from our field-incidence average, not eq. (46)."""
    p = default_project()
    p.openings = []
    p.sidewall = p.sidewall[:1]
    p.cabin.t60_measured = [[100.0, 0.5], [5000.0, 0.5]]
    r = reverberant_noise_reduction(p)
    A = r["A"]
    tau = 10 ** (-r["tl_composite"] / 10)
    S = p.fuselage.sidewall_area
    assert np.allclose(r["NR"], 10 * np.log10(A / (S * tau)), atol=1e-9)


def test_insertion_loss_is_dTL_plus_dABS_as_in_tm85722():
    """TM-85722 eqs. (1)-(3): IL = dTL + dABS with dABS = 10 log10(alpha_treated / alpha_untreated).
    Changing only the wall gives IL = dTL (broadband bands); changing only the absorption gives
    IL = 10 log10(A_treated / A_untreated) exactly."""
    p = default_project()
    base = run_case(p)
    q = copy.deepcopy(p)
    for s in q.cabin.surfaces:
        s.alpha = [min(1.0, 1.8 * a) for a in s.alpha]
    il = insertion_loss(base, run_case(q))
    dABS = 10 * np.log10(run_case(q).A_band / base.A_band)
    assert np.allclose(il["band_broadband"], dABS, atol=1e-9)
    w = copy.deepcopy(p)
    w.sidewall[-1].h *= 2                                    # heavier trim: wall change only
    rw = run_case(w)
    dTL = rw.tl_band - base.tl_band
    assert np.allclose(insertion_loss(base, rw)["band_broadband"], dTL, atol=1e-9)


def test_pipeline_cr132602_mode_reproduces_the_method():
    """With sidewall_method = 'cr132602' and no openings, the pipeline's reverberant NR must equal
    CR-132602 eq. (52) evaluated by hand from the stack (skin, trim + blanket mass, cavity depth)."""
    p = default_project()
    p.openings = []
    p.sidewall_method.method = "cr132602"
    p.cabin.t60_measured = [[100.0, 0.6], [5000.0, 0.3]]
    r = reverberant_noise_reduction(p)
    f = r["centers"]
    skin, trim = p.sidewall[0], p.sidewall[-1]
    m_bl = sum(l.bulk_density * l.d for l in p.sidewall[1:-1] if hasattr(l, "bulk_density"))
    L3 = sum(l.d for l in p.sidewall[1:-1])
    from cabin_noise.core.atmosphere import cabin_air
    from cabin_noise.core.frequencies import log_subfrequencies
    air = cabin_air(p.cabin.cabin_altitude, p.cabin.temperature)
    S = p.fuselage.sidewall_area
    sub = log_subfrequencies(f, p.options.n_sub)
    octs = [63, 125, 250, 500, 1000, 2000, 4000, 8000]
    taus = []
    for fs in sub:
        A = p.cabin.absorption(fs)
        a3 = np.interp(np.log(fs), np.log(octs), p.sidewall_method.cavity_alpha)
        nr = sea.nr_double_wall(fs, m_skin=skin.mass, m_trim=trim.mass + m_bl, L3=L3, alpha3=a3, alpha5=A / S,
                                rho=air.rho, c=air.c)
        taus.append(np.mean(A / (S * 10 ** (nr / 10))))
    expect = 10 * np.log10(r["A"] / (S * np.array(taus)))
    assert np.allclose(r["NR"], expect, atol=1e-9)
