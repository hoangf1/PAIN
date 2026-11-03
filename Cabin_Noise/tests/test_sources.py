"""Each block checked against something independent of its own code path: a published table,
an independent derivation or a physical identity (VERIFICATION.md)."""
import numpy as np
import pytest

from cabin_noise.core.atmosphere import air, isa
from cabin_noise.core.cabin import STAT_95
from cabin_noise.core.mission import Segment, operating_point, tas_from_ias
from cabin_noise.core.source_tbl import boundary_layer, goody_phi
from cabin_noise.core.source_tonal import gutin_rms
from cabin_noise.core.weighting import a_weight, c_weight, energetic_sum

from independent import moving_force_harmonics

SL = air(293.15, 101325.0)


@pytest.mark.parametrize("h,T,p,rho", [(0, 288.15, 101325.0, 1.2250), (5000, 255.65, 54019.9, 0.73612),
                                       (11000, 216.65, 22632.1, 0.36392), (15000, 216.65, 12044.6, 0.19367)])
def test_isa_against_us_standard_atmosphere(h, T, p, rho):
    a = isa(h)
    assert a.T == pytest.approx(T, abs=0.01) and a.p == pytest.approx(p, rel=1e-3) and a.rho == pytest.approx(rho, rel=1e-3)


def test_sutherland_viscosity_table_value():
    assert isa(0).mu == pytest.approx(1.7894e-5, rel=1e-3)


def test_tas_and_measured_temperature():
    assert tas_from_ias(100.0, 0.0, 288.15) == pytest.approx(51.4444, rel=1e-3)
    a = operating_point(Segment(altitude=3000.0, mach=0.3)).atm
    b = operating_point(Segment(altitude=3000.0, mach=0.3, oat=a.T + 20.0)).atm
    assert b.p == pytest.approx(a.p) and b.c > a.c


@pytest.mark.parametrize("f,A,C", [(31.5, -39.4, -3.0), (63, -26.2, -0.8), (125, -16.1, -0.2), (250, -8.6, 0.0),
                                   (500, -3.2, 0.0), (1000, 0.0, 0.0), (2000, 1.2, -0.2), (4000, 1.0, -0.8),
                                   (8000, -1.1, -3.0)])
def test_weighting_against_iec_61672_table(f, A, C):
    fx = 1000.0 * 10 ** (np.round(10 * np.log10(f / 1000.0)) / 10)
    assert a_weight(fx) == pytest.approx(A, abs=0.1) and c_weight(fx) == pytest.approx(C, abs=0.1)
    assert energetic_sum([90.0, 90.0]) == pytest.approx(93.01, abs=0.01)


def test_sabine_constant():
    assert 24 * np.log(10) / 343.0 == pytest.approx(0.161, abs=5e-4)


def test_waterhouse_wall_factor_and_diffuse_intensity():
    """Diffuse field of random plane waves at a rigid wall: wall mean square = 2 x field mean square
    (Waterhouse 1955; CR-3813 p. 23); intensity onto the wall = <p^2> / 4 rho c (Kuttruff)."""
    rng = np.random.default_rng(1)
    N, k = 4000, 2 * np.pi
    u = rng.uniform(0, 1, N)
    ph, az = rng.uniform(0, 2 * np.pi, N), rng.uniform(0, 2 * np.pi, N)
    s_ = np.sqrt(1 - u ** 2)
    kx, ky, kz = k * s_ * np.cos(az), k * s_ * np.sin(az), -k * u
    amp = np.ones(N) / np.sqrt(N)

    def p(x, y, z):
        return (amp * np.exp(1j * (kx * x + ky * y + kz * z + ph))).sum() + \
            (amp * np.exp(1j * (kx * x + ky * y - kz * z + ph))).sum()

    pts, zs = rng.uniform(0, 50, (400, 2)), rng.uniform(20, 40, 400)
    wall = np.mean([abs(p(x, y, 0.0)) ** 2 for x, y in pts]) / 2
    far = np.mean([abs(p(x, y, z)) ** 2 for (x, y), z in zip(pts, zs)]) / 2
    assert wall / far == pytest.approx(2.0, rel=0.1)
    assert np.sum(amp ** 2 / 2 * u) / SL.rho_c == pytest.approx(far / (4 * SL.rho_c), rel=0.1)


def test_seat_statistic_is_the_exponential_95th_percentile():
    rng = np.random.default_rng(2)
    p2 = np.abs(rng.normal(size=200000) + 1j * rng.normal(size=200000)) ** 2
    assert 10 * np.log10(np.quantile(p2, 0.95) / p2.mean()) == pytest.approx(STAT_95, abs=0.05)


def test_gutin_against_direct_time_domain_moving_force_far_field():
    """Gutin is the static far-field limit of the moving point force (Lowson 1965), solved here
    directly in time (independent code, no Bessel functions)."""
    B, R, c, T, Q, r = 2, 1.0, 340.0, 2000.0, 600.0, 200.0
    om = 0.5 * c / R
    for th in np.radians([60.0, 90.0, 120.0]):
        P = moving_force_harmonics([r * np.cos(th), r * np.sin(th), 0.0], B, R, om, 0.0, c, T, Q, 3)
        G = gutin_rms(np.arange(1, 4), blades=B, R_e=R, omega=om, c=c, thrust=T, torque=Q, r=r, theta=th)
        assert np.allclose(20 * np.log10(P / G), 0.0, atol=0.1)


def test_goody_asymptotic_slopes_and_flat_plate_layer():
    bl = boundary_layer(isa(6000), 140.0, 4.0)

    def slope(w1):
        return np.log(goody_phi(2 * w1, bl) / goody_phi(w1, bl)) / np.log(2)

    U, d = bl.Ue, bl.delta
    assert slope(1e-4 * U / d) == pytest.approx(2.0, abs=0.02)
    assert slope(1e3 * U / d * bl.R_T ** 0.57) == pytest.approx(-5.0, abs=0.05)
    assert -1.0 < slope(30 * U / d) < -0.5
    a = isa(0)
    b2 = boundary_layer(a, 50.0, 2.0)
    Re = 50.0 * 2.0 / a.nu
    assert b2.delta == pytest.approx(0.37 * 2.0 / Re ** 0.2) and b2.Cf == pytest.approx(0.0592 / Re ** 0.2)
