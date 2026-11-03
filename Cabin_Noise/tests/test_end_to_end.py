"""End-to-end hand check of the default cruise case. One tone (BPF1) and one 1/3-octave band
(1 kHz) are recomputed from the project's inputs with independent code (tests/independent.py and
the formulas written out below); run_case must agree. The test reads only inputs and results
from the tool, never its physics functions."""
import numpy as np
import pytest
from scipy.integrate import quad

from cabin_noise.core.io import default_project
from cabin_noise.core.pipeline import run_case

from independent import cylinder_surface_factor, isa, moving_force_harmonics

P_REF = 20e-6


@pytest.fixture(scope="module")
def case():
    proj = default_project()
    return proj, run_case(proj)


# ---- hand-written transfer matrix (Allard & Atalla ch. 11; Cremer; Panneton 2007) ---------------
def _panel_Z(L, f, th, R_fus, c0):
    w = 2 * np.pi * f
    m = L.rho * L.h + L.m_add
    D = L.E * L.h ** 3 / (12 * (1 - L.nu ** 2))
    fc = c0 ** 2 / (2 * np.pi) * np.sqrt(m / D)
    br = 1 - (f / fc) ** 2 * np.sin(th) ** 4 * (1 + 1j * L.eta)
    if L.curved:
        cL = np.sqrt(L.E / (L.rho * (1 - L.nu ** 2)))
        br -= (cL / (2 * np.pi * R_fus) / f) ** 2
    Z = 1j * w * m * br
    if abs(Z) < w * m * L.eta:
        Z = Z / abs(Z) * w * m * L.eta
    return Z


def _fluid(L, f, th, rho0, c0):
    w = 2 * np.pi * f
    k0 = w / c0
    if L.kind == "gap":
        Zc, kc = rho0 * c0, k0
    else:
        X = rho0 * f / L.sigma
        Zc = rho0 * c0 * (1 + 0.0571 * X ** -0.754 - 1j * 0.087 * X ** -0.732)
        kc = k0 * (1 + 0.0978 * X ** -0.700 - 1j * 0.189 * X ** -0.595)
        if L.frame == "limp":
            rq, K = Zc * kc / w, w * Zc / kc
            rt = L.bulk_density + rho0
            rl = (rt * rq - rho0 ** 2) / (rt + rq - 2 * rho0)
            kc = w * np.sqrt(rl / K)
            kc = -kc if kc.real < 0 else kc
            Zc = w * rl / kc
    kz = np.sqrt(kc ** 2 - (k0 * np.sin(th)) ** 2 + 0j)
    z = Zc * kc / kz
    return np.array([[np.cos(kz * L.d), 1j * z * np.sin(kz * L.d)], [1j * np.sin(kz * L.d) / z, np.cos(kz * L.d)]])


def _tau(layers, f, th, rho0, c0, R_fus):
    T = np.eye(2, dtype=complex)
    for L in layers:
        M = np.array([[1, _panel_Z(L, f, th, R_fus, c0)], [0, 1]]) if L.kind == "panel" else _fluid(L, f, th, rho0, c0)
        T = T @ M
    Z0 = rho0 * c0
    return abs(2 / (T[0, 0] + T[0, 1] * np.cos(th) / Z0 + T[1, 0] * Z0 / np.cos(th) + T[1, 1])) ** 2


def _tau_composite(proj, f, th, rho0, c0, diffuse=False):
    R = proj.fuselage.radius

    def t(layers):
        if not diffuse:
            return _tau(layers, f, th, rho0, c0, R)
        tm = np.radians(78)
        num = quad(lambda a: _tau(layers, f, a, rho0, c0, R) * np.sin(a) * np.cos(a), 0, tm, limit=200)[0]
        return num / (np.sin(tm) ** 2 / 2)

    S_o = sum(o.area for o in proj.openings)
    S_w = proj.fuselage.sidewall_area - S_o
    return (S_w * t(proj.sidewall) + sum(o.area * t(o.layers) for o in proj.openings)) / proj.fuselage.sidewall_area


def _absorption(proj, f):
    octs = [63, 125, 250, 500, 1000, 2000, 4000, 8000]
    return sum(s.area * np.clip(np.interp(np.log(f), np.log(octs), s.alpha), 0, 1) for s in proj.cabin.surfaces)


def _cabin_air(proj):
    T = proj.cabin.temperature
    p = isa(proj.cabin.cabin_altitude)[1]
    return p / (287.05 * T), np.sqrt(1.4 * 287.05 * T)


# ---- the checks ---------------------------------------------------------------------------------
def test_tone_bpf1_end_to_end(case):
    proj, res = case
    seg, pr, fu = proj.mission.active_segment(), proj.propeller, proj.fuselage
    _, _, rho_e, c_e = isa(seg.altitude)
    V = seg.mach * c_e
    om = 2 * np.pi * seg.rpm / 60
    T, Q = seg.eta_p * seg.shaft_power / V, seg.shaft_power / om
    R_e = pr.re_fraction * pr.tip_radius
    near = np.array([0.0, -(pr.tip_radius + pr.clearance), 0.0])           # patch centre (1 patch)
    far = near - np.array([0.0, -2 * (pr.tip_radius + pr.clearance + fu.radius), 0.0])
    p_near = moving_force_harmonics(near, pr.blades, R_e, om, V, c_e, T, Q, 1, pr.rotation)[0]
    p_far = moving_force_harmonics(far, pr.blades, R_e, om, V, c_e, T, Q, 1, pr.rotation)[0]
    f1 = pr.blades * seg.rpm / 60
    S = cylinder_surface_factor(2 * np.pi * f1 / c_e * fu.radius, np.pi)
    p_inc2 = p_near ** 2 + (p_far * abs(S) / 2) ** 2                       # energetic twin sum
    L_inc = 10 * np.log10(p_inc2 / P_REF ** 2)
    assert res.L_inc[0, 0] == pytest.approx(L_inc, abs=0.1)

    rho0, c0 = _cabin_air(proj)
    tau = _tau_composite(proj, f1, 0.0, rho0, c0)                          # patch faces the hub: theta = 0
    W = fu.patch_width * fu.patch_height * tau * p_inc2 / (rho0 * c0)
    p_int2 = 4 * rho0 * c0 * W / _absorption(proj, f1)
    assert res.L_tone[0] == pytest.approx(10 * np.log10(p_int2 / P_REF ** 2), abs=0.1)


def test_broadband_1khz_band_end_to_end(case):
    proj, res = case
    seg, fu = proj.mission.active_segment(), proj.fuselage
    T_e, p_e, rho_e, c_e = isa(seg.altitude)
    mu = 1.458e-6 * T_e ** 1.5 / (T_e + 110.4)
    nu = mu / rho_e
    V = seg.mach * c_e
    x = fu.nose_to_station
    Re = V * x / nu
    delta, Cf = 0.37 * x * Re ** -0.2, 0.0592 * Re ** -0.2                # Schlichting
    tau_w = Cf * 0.5 * rho_e * V ** 2
    u_t = np.sqrt(tau_w / rho_e)
    RT = (delta / V) / (nu / u_t ** 2)

    def phi(w):                                                             # Goody 2004
        wt = w * delta / V
        return 3 * wt ** 2 / ((wt ** 0.75 + 0.5) ** 3.7 + (1.1 * RT ** -0.57 * wt) ** 7) * tau_w ** 2 * delta / V

    i = int(np.argmin(np.abs(res.centers - 1000)))
    fc = res.centers[i]
    lo, hi = fc * 2 ** (-1 / 6), fc * 2 ** (1 / 6)
    p_wall2 = quad(lambda f: phi(2 * np.pi * f) * 2 * np.pi, lo, hi)[0]
    assert res.L_wall[i] == pytest.approx(10 * np.log10(p_wall2 / P_REF ** 2), abs=0.05)

    rho0, c0 = _cabin_air(proj)
    sub = lo * (hi / lo) ** ((np.arange(10) + 0.5) / 10)                   # the model's band average (10 points)
    tau_b = np.mean([_tau_composite(proj, f, None, rho0, c0, diffuse=True) for f in sub])
    W = fu.sidewall_area * tau_b * (p_wall2 / 2) / (4 * rho0 * c0)          # Waterhouse; diffuse intensity
    p_int2 = 4 * rho0 * c0 * W / _absorption(proj, fc)
    assert res.L_bb[i] == pytest.approx(10 * np.log10(p_int2 / P_REF ** 2), abs=0.2)


def test_totals_assembly(case):
    """Band totals and dBA rebuilt from the tool's tone and band levels with an independent band
    assignment (IEC 61260 edges) and the IEC 61672 A-weighting formula."""
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
    assert res.totals["average"]["total"]["OASPL"] == pytest.approx(10 * np.log10(p2.sum()), abs=1e-6)
