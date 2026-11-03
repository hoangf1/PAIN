"""Blade-geometry source: verification against independent closed forms (no verdict)."""
import numpy as np
import pytest
from scipy.special import jv

from cabin_noise.core.blade import BladeGeometry, scaled_strip_loads, strip_harmonics, strip_loads
from cabin_noise.core.source_tonal import rotor_harmonics

GEOM = BladeGeometry(r_over_R=[0.25, 0.5, 0.75, 1.0], c_over_R=[0.18, 0.16, 0.13, 0.08],
                     beta_deg=[20.0, 12.0, 8.0, 6.0], cl_design=[0.3, 0.4, 0.4, 0.3], hub_r_over_R=0.25,
                     n_strips=12)
KW = dict(blades=2, R=1.0, omega=170.0, V=0.0, rho=1.225, c=340.0)


def test_strip_sum_matches_radially_integrated_gutin():
    """Far field, static: sum over strips equals Gutin's formula integrated strip by strip
    (all strips share the far-field phase, so their signed terms add)."""
    r, dT, dQ = strip_loads(GEOM, **KW)
    th, dist, B, om, c = np.radians(110.0), 300.0, 2, 170.0, 340.0
    P = strip_harmonics([dist * np.cos(th), dist * np.sin(th), 0.0], r, dT, dQ, blades=B, omega=om, V=0.0,
                        c=c, n_harmonics=3)
    m = np.arange(1, 4)
    k = m * B * om / c
    terms = [(Ti * np.cos(th) - Qi * c / (om * ri ** 2)) * jv(m * B, k * ri * np.sin(th))
             for ri, Ti, Qi in zip(r, dT, dQ)]
    gut = m * B * om / (2 * np.sqrt(2) * np.pi * c * dist) * np.abs(np.sum(terms, axis=0))
    assert np.allclose(20 * np.log10(np.abs(P) / gut), 0.0, atol=0.2)


def test_single_strip_equals_point_source():
    P1 = strip_harmonics([0.1, -1.5, 0.0], [0.8], [3000.0], [900.0], blades=3, omega=160.0, V=90.0, c=320.0,
                         n_harmonics=4)
    P0 = rotor_harmonics([0.1, -1.5, 0.0], blades=3, R_e=0.8, omega=160.0, V=90.0, c=320.0, thrust=3000.0,
                         torque=900.0, n_harmonics=4)
    assert np.allclose(P1, P0)


def test_scaling_reproduces_targets_and_keeps_shape():
    r, dT, dQ = strip_loads(GEOM, **KW)
    r2, sT, sQ = scaled_strip_loads(GEOM, thrust=1000.0, torque=300.0, **KW)
    assert sT.sum() == pytest.approx(1000.0) and sQ.sum() == pytest.approx(300.0)
    assert np.allclose(sT / sT.sum(), dT / dT.sum())


def test_hover_figure_of_merit_is_physical():
    r, dT, dQ = strip_loads(GEOM, **KW)
    T, P = dT.sum(), dQ.sum() * KW["omega"]
    FM = T ** 1.5 / (np.sqrt(2 * KW["rho"] * np.pi * KW["R"] ** 2) * P)
    assert 0.3 < FM < 0.95


def test_more_pitch_more_thrust_and_tip_loss_unloads_tip():
    lo = strip_loads(GEOM, **KW)[1].sum()
    g2 = BladeGeometry(**{**GEOM.__dict__, "beta_deg": [b + 3 for b in GEOM.beta_deg]})
    r, dT, _ = strip_loads(g2, **KW)
    assert dT.sum() > lo
    assert dT[-1] / (r[-1] - r[-2]) < np.max(dT / np.gradient(r))      # tip strip below the peak loading
