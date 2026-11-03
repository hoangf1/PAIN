"""The sidewall and insertion-loss blocks against their papers: CR-132602 (Wilby & Scharton
1975) and TM-85722 (Mixson, O'Neal & Grosveld 1984)."""
import copy

import numpy as np
import pytest
from scipy.integrate import quad

from cabin_noise.core import sea
from cabin_noise.core.atmosphere import cabin_air
from cabin_noise.core.io import default_project
from cabin_noise.core.materials import octave_interp
from cabin_noise.core.pipeline import noise_reduction

RHO, C = 1.21, 343.0


def test_eq46_is_the_random_incidence_average_of_eq45():
    for f, m in ((125.0, 2.5), (1000.0, 2.5), (4000.0, 5.0)):
        x = np.pi * f * m / (RHO * C)
        num = quad(lambda p: np.sin(2 * p) / (1 + (x * np.cos(p)) ** 2), 0, np.pi / 2)[0]
        assert sea.tau_mass_law_diffuse(f, m, RHO * C) == pytest.approx(num, rel=1e-9)


def test_eq52_equals_the_power_balance_eq47():
    f = np.array([100.0, 400.0, 1600.0, 3000.0])
    S2, S3, S4, S5, V3, V5, L3, m2, m4, a3, a5 = 2.0, 2.6, 1.7, 9.0, 0.2, 30.0, 0.1, 4.0, 1.5, 0.6, 0.35
    nr = sea.nr_double_wall(f, m_skin=m2, m_trim=m4, L3=L3, alpha3=a3, alpha5=a5, rho=RHO, c=C,
                            S2=S2, S3=S3, S4=S4, S5=S5)
    for i, fi in enumerate(f):
        t31, t35 = sea.tau_mass_law_diffuse(fi, m2, RHO * C), sea.tau_mass_law_diffuse(fi, m4, RHO * C)
        eps = np.pi if fi < C / (2 * L3) else 4.0
        e31, e35 = C * S2 * t31 / (8 * np.pi * fi * V3), C * S4 * t35 / (8 * np.pi * fi * V3)
        e53, e3 = e35 * V3 / V5, S3 * C * a3 / (2 * eps * np.pi * fi * V3)
        e5 = C * S5 * a5 / (8 * np.pi * fi * V5)
        _, u5 = np.linalg.solve([[e3 + e31 + e35, -e35], [-e53, e5 + e53]], [e31, 0.0])
        assert nr[i] == pytest.approx(10 * np.log10(1 / u5), abs=1e-9)


def test_pipeline_noise_reduction_is_eq52_and_the_single_wall_form():
    """With no openings the pipeline NR is exactly CR-132602 eq. (52) (double wall) or
    10 log10(1 + A / (S tau)) with eq. (46) (single wall), alpha5 = A / S."""
    p = default_project()
    p.openings = []
    air = cabin_air(p.cabin.cabin_altitude, p.cabin.temperature)
    f = np.geomspace(63, 5000, 15)
    S = p.fuselage.side_area
    A = p.cabin.absorption(f)
    sw = p.sidewall
    expect = sea.nr_double_wall(f, m_skin=sw.m_skin, m_trim=sw.m_trim, L3=sw.cavity_depth,
                                alpha3=octave_interp(sw.cavity_alpha, f), alpha5=A / S, rho=air.rho, c=air.c)
    assert np.allclose(noise_reduction(p, f, S, air), expect, atol=1e-12)
    p.sidewall.double_wall = False
    tau = sea.tau_mass_law_diffuse(f, p.sidewall.m_skin, air.rho_c)
    assert np.allclose(noise_reduction(p, f, S, air), 10 * np.log10(1 + A / (S * tau)), atol=1e-12)


def test_openings_combine_by_area_as_tm85722_eq1():
    p = default_project()
    air = cabin_air(p.cabin.cabin_altitude, p.cabin.temperature)
    f = np.array([250.0, 1000.0])
    S = p.fuselage.side_area
    A = p.cabin.absorption(f)
    q = copy.deepcopy(p)
    q.openings = []
    t_wall = sea.tau_equivalent(noise_reduction(q, f, S, air), A / S)
    o = p.openings[0]
    t = ((S - o.area) * t_wall + o.area * o.tau(f, air.rho_c)) / S
    assert np.allclose(noise_reduction(p, f, S, air), 10 * np.log10(1 + A / (S * t)), atol=1e-12)


def test_double_wall_limits():
    f = np.array([200.0, 1000.0])
    kw = dict(m_skin=4.0, L3=0.1, alpha3=0.5, alpha5=0.4, rho=RHO, c=C)
    assert np.all(sea.nr_double_wall(f, m_trim=1e-9, **kw) > sea.nr_single_wall(f, m=4.0, alpha5=0.4, rho=RHO, c=C))
    assert np.all(sea.nr_double_wall(f, m_trim=3.0, **kw) > sea.nr_double_wall(f, m_trim=1.0, **kw))
    nr = sea.nr_double_wall(f, m_trim=1.0, **kw)
    assert np.allclose(10 * np.log10(1 + 0.4 / sea.tau_equivalent(nr, 0.4)), nr)
