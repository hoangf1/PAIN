import numpy as np
import pytest

from cabin_noise.core import seats as st
from cabin_noise.core import tmm
from cabin_noise.core.atmosphere import air, isa
from cabin_noise.core.frequencies import band_index, nominal_label, third_octave_centers
from cabin_noise.core.materials import AirGap, Panel, PorousLayer, Surface
from cabin_noise.core.porous import delany_bazley
from cabin_noise.core.source_tbl import boundary_layer, wall_band_pressure2
from cabin_noise.core.source_tonal import rotor_harmonics
from cabin_noise.core.weighting import a_weight, c_weight, energetic_sum

SL = air(293.15, 101325.0)


def test_isa_layer_boundaries():
    assert isa(0).T == pytest.approx(288.15)
    assert isa(0).p == pytest.approx(101325.0)
    assert isa(11000).T == pytest.approx(216.65)
    assert isa(11000).p == pytest.approx(22632, rel=2e-3)
    assert isa(0).rho == pytest.approx(1.225, rel=1e-3)


def test_third_octave_grid():
    fc = third_octave_centers(50, 5000)
    assert len(fc) == 21
    assert nominal_label(fc[0]) == "50" and nominal_label(fc[-1]) == "5k"
    assert band_index([1000.0], fc)[0] == list(fc).index(min(fc, key=lambda f: abs(f - 1000)))


def test_weighting_table_values():
    # IEC 61672 tabulated values
    assert a_weight(1000.0) == pytest.approx(0.0, abs=0.05)
    assert a_weight(100.0) == pytest.approx(-19.1, abs=0.1)
    assert a_weight(63.0) == pytest.approx(-26.2, abs=0.1)
    assert c_weight(1000.0) == pytest.approx(0.0, abs=0.05)
    assert c_weight(31.5) == pytest.approx(-3.0, abs=0.1)
    assert energetic_sum([90.0, 90.0]) == pytest.approx(93.01, abs=0.01)


def test_delany_bazley_tends_to_air_at_high_X():
    Zc, kc, X = delany_bazley(np.array([1e6]), 1.0, SL.rho, SL.c)
    assert abs(Zc[0] / SL.rho_c - 1) < 1e-3


def test_blanket_raises_high_frequency_tl():
    skin, trim = Panel(h=1.6e-3), Panel(name="trim", E=20e9, rho=1800, h=1.5e-3, eta=0.03)
    f = np.array([1000.0, 2000.0, 4000.0])
    bare = tmm.tl(tmm.tau_diffuse([skin, AirGap(d=0.09), trim], f, SL))
    treated = tmm.tl(tmm.tau_diffuse([skin, AirGap(d=0.02), PorousLayer(d=0.05, sigma=10000.0),
                                      AirGap(d=0.02), trim], f, SL))
    assert np.all(treated - bare > 3.0)


def test_coincidence_dip_in_diffuse_tl():
    p = Panel(h=1.6e-3)
    fc = p.coincidence(SL.c)
    f = np.geomspace(fc / 8, fc * 2, 200)
    t = tmm.tl(tmm.tau_diffuse([p], f, SL))
    mass_law = 20 * np.log10(p.mass * f) - 47
    i = np.argmin(np.abs(f - fc))
    assert mass_law[i] - t[i] > 3.0           # TL falls below mass law at coincidence


def test_curvature_stiffens_skin_below_ring_frequency():
    flat, curved = Panel(h=1.6e-3), Panel(h=1.6e-3, curved=True)
    fr = curved.ring_frequency(1.0)
    f = np.array([fr / 4])
    assert tmm.tl(tmm.tau([curved], f, 0.0, SL, 1.0))[0] > tmm.tl(tmm.tau([flat], f, 0.0, SL, 1.0))[0] + 6


def test_source_inverse_distance_far_field():
    kw = dict(blades=4, R_e=1.0, omega=170.0, V=0.0, c=340.0, thrust=5000.0, torque=3000.0, n_harmonics=2)
    th = np.radians(100)
    p1 = rotor_harmonics([200 * np.cos(th), 200 * np.sin(th), 0], **kw)
    p2 = rotor_harmonics([400 * np.cos(th), 400 * np.sin(th), 0], **kw)
    assert 20 * np.log10(np.abs(p1[0]) / np.abs(p2[0])) == pytest.approx(6.02, abs=0.05)


def test_source_rejects_supersonic_helical_mach():
    with pytest.raises(ValueError):
        rotor_harmonics([0, -2, 0], blades=4, R_e=1.0, omega=400.0, V=100.0, c=340.0,
                        thrust=1.0, torque=1.0, n_harmonics=1)


def test_source_scales_with_force():
    kw = dict(blades=4, R_e=1.0, omega=170.0, V=100.0, c=320.0, n_harmonics=3)
    a = rotor_harmonics([0, -1.5, 0], thrust=4000.0, torque=3000.0, **kw)
    b = rotor_harmonics([0, -1.5, 0], thrust=8000.0, torque=6000.0, **kw)
    assert np.allclose(np.abs(b), 2 * np.abs(a), rtol=1e-9)


def test_goody_level_rises_with_dynamic_pressure():
    centers = third_octave_centers(50, 5000)
    lo = wall_band_pressure2(centers, boundary_layer(isa(6000), 100.0, 4.0)).sum()
    hi = wall_band_pressure2(centers, boundary_layer(isa(6000), 150.0, 4.0)).sum()
    assert hi > lo * 1.5


def test_seat_statistic_above_schroeder():
    box = st.Box(8, 1.9, 1.8)
    patch = st.SidewallPatch(3, 1.5, 1.1, 1.0)
    off = st.seat_offsets([1000.0], 200.0, [[1, 1, 1]], box, 343.0, lambda f: 0.4, patch)
    assert off[0, 0] == pytest.approx(10 * np.log10(np.log(20)))
    assert off[0, 0] == pytest.approx(4.77, abs=0.01)


def test_surface_alpha_interpolation():
    s = Surface(alpha=[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8])
    assert s.alpha_at(500.0) == pytest.approx(0.4)
    assert s.alpha_at(20.0) == pytest.approx(0.1)


def test_tas_from_ias():
    from cabin_noise.core.mission import tas_from_ias
    assert tas_from_ias(100.0, 0.0, 288.15) == pytest.approx(51.4444, rel=1e-3)
    assert tas_from_ias(200.0, 4267.0, 276.5) > 1.2 * 200 * 0.514444    # thinner air -> TAS > IAS


def test_oat_override_changes_sound_speed():
    from cabin_noise.core.mission import Segment, operating_point
    a = operating_point(Segment(altitude=3000.0, mach=0.3)).atm
    b = operating_point(Segment(altitude=3000.0, mach=0.3, oat=a.T + 20.0)).atm
    assert b.p == pytest.approx(a.p) and b.c > a.c


def test_bay_fundamental_matches_simply_supported_plate():
    # Leissa: w11 = pi^2 sqrt(D / rho h) (1/a^2 + 1/b^2)
    p = Panel(h=1.0e-3, bay_a=0.3, bay_b=0.2)
    w11 = np.pi ** 2 * np.sqrt(p.D / (p.rho * p.h)) * (1 / 0.3 ** 2 + 1 / 0.2 ** 2)
    assert p.bay_frequency() == pytest.approx(w11 / (2 * np.pi))
    assert Panel(h=1.0e-3).bay_frequency() == 0.0


def test_bay_panel_is_stiffness_controlled_below_f11_and_mass_law_above():
    p = Panel(h=1.0e-3, bay_a=0.15, bay_b=0.12)
    f11, s_bay = p.bay_frequency(), p.bay_stiffness()
    f = np.array([f11 / 8])
    stiff = 20 * np.log10(s_bay / (2 * np.pi * f * 2 * SL.rho_c))       # TL of a spring, s >> w m
    assert tmm.tl(tmm.tau([p], f, 0.0, SL))[0] == pytest.approx(stiff[0], abs=0.5)
    hi = np.array([6 * f11])
    flat = tmm.tl(tmm.tau([Panel(h=1.0e-3)], hi, 0.0, SL))[0]
    assert tmm.tl(tmm.tau([p], hi, 0.0, SL))[0] == pytest.approx(flat, abs=0.5)


def test_porous_table_reproduces_delany_bazley_input():
    from cabin_noise.core.materials import PorousTable
    from cabin_noise.core.porous import delany_bazley
    f = np.array([200.0, 500.0, 1000.0, 2000.0, 4000.0])
    Zc, kc, _ = delany_bazley(f, 15000.0, SL.rho, SL.c)
    t = PorousTable(d=0.05, f=list(f), wavelength=list(2 * np.pi / kc.real), atten_db_per_m=list(-kc.imag * 20 * np.log10(np.e)),
                    W=list(np.abs(Zc)), phi_deg=list(-np.degrees(np.angle(Zc))))
    a = tmm.tl(tmm.tau([Panel(h=1e-3), t, Panel(h=1e-3)], f, 0.0, SL))
    b = tmm.tl(tmm.tau([Panel(h=1e-3), PorousLayer(d=0.05, sigma=15000.0), Panel(h=1e-3)], f, 0.0, SL))
    assert np.allclose(a, b, atol=1e-6)
