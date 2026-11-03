import copy

import numpy as np
import pytest

from cabin_noise.core.io import default_project, export_results_csv, load_project, save_project
from cabin_noise.core.materials import PorousLayer
from cabin_noise.core.pipeline import insertion_loss, patch_sensitivity, run_case, run_mission


@pytest.fixture(scope="module")
def proj():
    return default_project()


@pytest.fixture(scope="module")
def res(proj):
    return run_case(proj)


def test_default_case_is_finite(res):
    for track in ("tonal", "broadband", "total"):
        for k in ("OASPL", "dBA", "dBC"):
            assert np.isfinite(res.totals["average"][track][k])
            assert res.totals["max_seat"][track][k] >= res.totals["average"][track][k] - 1e-9
    assert res.totals["average"]["total"]["OASPL"] >= res.totals["average"]["tonal"]["OASPL"]


def test_identical_configs_have_zero_il(proj, res):
    il = insertion_loss(res, run_case(copy.deepcopy(proj)))
    assert np.allclose(il["band_total"], 0.0) and il["dBA"] == pytest.approx(0.0)


def test_thicker_blanket_gives_positive_high_frequency_il(proj, res):
    p2 = copy.deepcopy(proj)
    for lay in p2.sidewall:
        if isinstance(lay, PorousLayer):
            lay.d *= 2
    il = insertion_loss(res, run_case(p2))
    hf = res.centers >= 1000
    assert np.all(il["band_broadband"][hf] > 0)


def test_json_round_trip_reproduces_results(proj, res, tmp_path):
    path = tmp_path / "case.json"
    save_project(proj, path)
    r2 = run_case(load_project(path))
    assert np.allclose(r2.L_band_total, res.L_band_total)
    export_results_csv(r2, tmp_path / "out.csv")
    assert (tmp_path / "out.csv").stat().st_size > 0


def test_k_refr_shifts_tones_one_to_one(proj, res):
    p2 = copy.deepcopy(proj)
    p2.propeller.k_refr = 3.0
    assert np.allclose(run_case(p2).L_tone - res.L_tone, 3.0)


def test_far_prop_adds_energy(proj, res):
    p1 = copy.deepcopy(proj)
    p1.propeller.engines = 1
    single = run_case(p1)
    assert np.all(res.L_tone >= single.L_tone - 1e-9)
    assert np.all(res.L_inc_modes["worst"] >= res.L_inc_modes["energetic"] - 1e-9)


def test_measured_override_used_verbatim(proj):
    p2 = copy.deepcopy(proj)
    p2.propeller.source_mode = "measured"
    p2.propeller.measured = [[m, 120.0 - 5 * m] for m in range(1, p2.propeller.n_harmonics + 1)]
    r = run_case(p2)
    assert np.allclose(r.L_inc[0], [120.0 - 5 * m for m in range(1, p2.propeller.n_harmonics + 1)])


def test_mission_and_patch_sensitivity(proj):
    rs = run_mission(proj)
    assert len(rs) == len(proj.mission.segments)
    s = patch_sensitivity(proj)
    assert set(s) == {"dBA_1", "dBA_5", "delta", "adequate"}


def test_static_segment_needs_thrust(proj):
    p2 = copy.deepcopy(proj)
    seg = p2.mission.segments[0]
    seg.mach, seg.thrust = 0.0, 0.0
    with pytest.raises(ValueError):
        run_case(p2, segment=0)
    seg.thrust = 12000.0
    r = run_case(p2, segment=0)
    assert np.all(np.isinf(r.L_bb) | (r.L_bb < 0))   # no TBL when static


def test_measured_t60_sets_absorption(proj):
    p2 = copy.deepcopy(proj)
    p2.cabin.t60_measured = [[500.0, 0.5], [2000.0, 0.25]]
    V = p2.cabin.cabin_volume()
    A = p2.cabin.absorption([250.0, 500.0, 1000.0, 2000.0, 4000.0])
    assert A == pytest.approx(0.161 * V / np.array([0.5, 0.5, np.sqrt(0.5 * 0.25), 0.25, 0.25]))


def test_reverberant_nr_tracks_absorption_and_wall_mass(proj):
    from cabin_noise.core.materials import Panel
    from cabin_noise.core.pipeline import reverberant_noise_reduction

    p2 = copy.deepcopy(proj)
    p2.cabin.t60_measured = [[100.0, 1.0], [5000.0, 0.5]]
    base = reverberant_noise_reduction(p2)
    p3 = copy.deepcopy(p2)
    p3.cabin.t60_measured = [[f, 2 * t] for f, t in p2.cabin.t60_measured]
    assert np.allclose(base["NR"] - reverberant_noise_reduction(p3)["NR"], 10 * np.log10(2))
    p4 = copy.deepcopy(p2)
    p4.openings = []
    p4.sidewall = [Panel(h=1.6e-3)]
    p5 = copy.deepcopy(p4)
    p5.sidewall = [Panel(h=3.2e-3)]
    mid = (base["centers"] > 300) & (base["centers"] < 1800)   # well below f_c of the 3.2 mm panel (~3.7 kHz)
    gain = reverberant_noise_reduction(p5)["NR"] - reverberant_noise_reduction(p4)["NR"]
    assert np.all(gain[mid] > 4.0)     # mass law: ~6 dB per doubling of mass


def test_blade_source_model_runs_and_differs_from_point(proj, res):
    p2 = copy.deepcopy(proj)
    p2.propeller.source_model = "blade"
    p2.propeller.blade = dict(r_over_R=[0.25, 0.5, 0.75, 1.0], c_over_R=[0.15, 0.14, 0.11, 0.06],
                              beta_deg=[68.0, 56.0, 48.0, 43.0], cl_design=[0.3, 0.4, 0.4, 0.3],
                              hub_r_over_R=0.25, n_strips=10)
    r2 = run_case(p2)
    assert np.all(np.isfinite(r2.L_tone))
    assert np.max(np.abs(r2.L_inc[0] - res.L_inc[0])) > 0.5    # radial spread changes the near field
    p2.propeller.blade = {}
    with pytest.raises(ValueError):
        run_case(p2)
