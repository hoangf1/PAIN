"""End-to-end hand check of the default cruise case with the papers' formulas written out
independently (Gutin, Goody, CR-132602 eqs. 46 and 52, TM-85722 eq. 1, IEC 61672). Reads
only inputs and results from the tool, never its physics functions."""
import numpy as np
import pytest
from scipy.integrate import quad
from scipy.special import jv

from cabin_noise.core.io import default_project
from cabin_noise.core.pipeline import run_case

from independent import isa

P_REF = 20e-6


@pytest.fixture(scope="module")
def case():
    proj = default_project()
    return proj, run_case(proj)


def _cabin_air(proj):
    T = proj.cabin.temperature
    p = isa(proj.cabin.cabin_altitude)[1]
    return p / (287.05 * T), np.sqrt(1.4 * 287.05 * T)


def _speed(seg):
    """Flight speed: from KCAS by the subsonic pitot formula (ISA sea-level reference) when given, else Mach."""
    T, p, _, c = isa(seg.altitude)
    if seg.kcas <= 0:
        return seg.mach * c
    p0, c0 = isa(0.0)[1], isa(0.0)[3]
    qc = p0 * ((1 + (1.4 - 1) / 2 * (seg.kcas * 1852 / 3600 / c0) ** 2) ** (1.4 / 0.4) - 1)
    return c * np.sqrt(2 / 0.4 * ((qc / p + 1) ** (0.4 / 1.4) - 1))


def _alpha(values, f):
    octs = [63, 125, 250, 500, 1000, 2000, 4000, 8000]
    return np.clip(np.interp(np.log(f), np.log(octs), values), 0, 1)


def _nr(proj, f, S):
    rho, c = _cabin_air(proj)
    A = sum(s.area * _alpha(s.alpha, f) for s in proj.cabin.surfaces)
    sw = proj.sidewall
    tau = lambda m: (rho * c / (np.pi * f * m)) ** 2 * np.log(1 + (np.pi * f * m / (rho * c)) ** 2)  # noqa: E731
    m2 = sw.skin_density * sw.skin_thickness + sw.skin_added_mass
    m4 = sw.trim_mass + sw.blanket_mass
    eps = np.pi if f < c / (2 * sw.cavity_depth) else 4.0
    a3, a5 = _alpha(sw.cavity_alpha, f), A / S
    nr = 10 * np.log10((1 + 4 / eps * a3 / tau(m2)) * (1 + a5 / tau(m4)) + a5 / tau(m2))     # eq. (52)
    t_wall = a5 / (10 ** (nr / 10) - 1)
    k = S / proj.fuselage.side_area                                       # openings are given per side
    So = k * sum(o.area for o in proj.openings)
    t = ((S - So) * t_wall + k * sum(o.area * tau(o.mass) for o in proj.openings)) / S          # TM-85722 eq. (1)
    return 10 * np.log10(1 + A / (S * t))


def test_tone_bpf1(case):
    proj, res = case
    seg, pr, fu = proj.mission.active_segment(), proj.propeller, proj.fuselage
    _, _, _, c_e = isa(seg.altitude)
    V = _speed(seg)
    om = 2 * np.pi * seg.rpm / 60
    T, Q = seg.eta_p * seg.shaft_power / V, seg.shaft_power / om
    Re = pr.re_fraction * pr.tip_radius
    d = pr.tip_radius + pr.clearance
    r = np.hypot(pr.axial_offset, d)
    th = np.arccos(pr.axial_offset / r)
    B = pr.blades
    p = B * om / (2 * np.sqrt(2) * np.pi * c_e * r) * abs(T * np.cos(th) - Q * c_e / (om * Re ** 2)) \
        * abs(jv(B, B * om * Re * np.sin(th) / c_e))
    L_ext = 20 * np.log10(p / P_REF)
    assert res.L_ext_tone[0] == pytest.approx(L_ext, abs=0.01)
    f1 = B * seg.rpm / 60
    assert res.L_tone[0] == pytest.approx(L_ext - _nr(proj, f1, fu.side_area) + 10 * np.log10(pr.engines), abs=0.01)


def test_broadband_1khz_band(case):
    proj, res = case
    seg, fu = proj.mission.active_segment(), proj.fuselage
    T_e, p_e, rho_e, c_e = isa(seg.altitude)
    nu = 1.458e-6 * T_e ** 1.5 / (T_e + 110.4) / rho_e
    V = _speed(seg)
    x = fu.nose_to_station
    Re = V * x / nu
    delta, Cf = 0.37 * x * Re ** -0.2, 0.0592 * Re ** -0.2
    tau_w = Cf * 0.5 * rho_e * V ** 2
    RT = (delta / V) / (nu / (tau_w / rho_e))

    def phi(w):
        wt = w * delta / V
        return 3 * wt ** 2 / ((wt ** 0.75 + 0.5) ** 3.7 + (1.1 * RT ** -0.57 * wt) ** 7) * tau_w ** 2 * delta / V

    i = int(np.argmin(np.abs(res.centers - 1000)))
    fc = res.centers[i]
    p_wall2 = quad(lambda f: phi(2 * np.pi * f) * 2 * np.pi, fc * 2 ** (-1 / 6), fc * 2 ** (1 / 6))[0]
    L_wall = 10 * np.log10(p_wall2 / P_REF ** 2)
    assert res.L_wall[i] == pytest.approx(L_wall, abs=0.05)
    assert res.L_bb[i] == pytest.approx(L_wall - 10 * np.log10(2) - _nr(proj, fc, fu.tbl_area), abs=0.05)


def test_totals_assembly(case):
    _, res = case
    p2 = 10 ** (res.L_bb / 10)
    lo, hi = res.centers * 2 ** (-1 / 6), res.centers * 2 ** (1 / 6)
    for f, L in zip(res.f_m, res.L_tone):
        j = np.where((f >= lo) & (f < hi))[0]
        if j.size:
            p2[j[0]] += 10 ** (L / 10)
    f2 = res.centers ** 2
    ra = 12194 ** 2 * f2 ** 2 / ((f2 + 20.6 ** 2) * np.sqrt((f2 + 107.7 ** 2) * (f2 + 737.9 ** 2)) * (f2 + 12194 ** 2))
    A = 20 * np.log10(ra) + 2.0
    assert np.allclose(10 * np.log10(p2), res.L_band_total, atol=1e-6)
    assert res.totals["average"]["total"]["dBA"] == pytest.approx(10 * np.log10(np.sum(p2 * 10 ** (A / 10))), abs=1e-6)
