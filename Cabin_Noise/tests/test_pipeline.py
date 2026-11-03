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
