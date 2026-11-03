import copy

import numpy as np
import pytest

from cabin_noise.core.io import default_project, export_results_csv, load_project, save_project
from cabin_noise.core.pipeline import insertion_loss, run_case, run_mission


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
            assert res.totals["max_seat"][track][k] == pytest.approx(res.totals["average"][track][k] + 4.77, abs=0.01)


def test_interior_is_exterior_minus_nr(res):
    assert np.allclose(res.L_tone, res.L_ext_tone - res.NR_tone + 10 * np.log10(2))
    assert np.allclose(res.L_bb, res.L_wall - 10 * np.log10(2) - res.NR_band)


def test_identical_configs_have_zero_il(proj, res):
    il = insertion_loss(res, run_case(copy.deepcopy(proj)))
    assert np.allclose(il["band_total"], 0.0) and il["dBA"] == pytest.approx(0.0)


def test_heavier_trim_and_more_absorption_give_positive_il(proj, res):
    p2 = copy.deepcopy(proj)
    p2.sidewall.trim_mass *= 2
    assert np.all(insertion_loss(res, run_case(p2))["band_broadband"] > 0)
    p3 = copy.deepcopy(proj)
    for s in p3.cabin.surfaces:
        s.alpha = [min(1.0, 1.5 * a) for a in s.alpha]
    assert np.all(insertion_loss(res, run_case(p3))["band_broadband"] > 0)


def test_json_round_trip_reproduces_results(proj, res, tmp_path):
    path = tmp_path / "case.json"
    save_project(proj, path)
    assert np.allclose(run_case(load_project(path)).L_band_total, res.L_band_total)
    export_results_csv(res, tmp_path / "out.csv")
    assert (tmp_path / "out.csv").stat().st_size > 0


def test_measured_exterior_used_verbatim(proj):
    p2 = copy.deepcopy(proj)
    p2.propeller.source_mode = "measured"
    p2.propeller.measured = [[m, 120.0 - 5 * m] for m in range(1, p2.propeller.n_harmonics + 1)]
    assert np.allclose(run_case(p2).L_ext_tone, [120.0 - 5 * m for m in range(1, p2.propeller.n_harmonics + 1)])


def test_two_engines_add_three_db(proj, res):
    p1 = copy.deepcopy(proj)
    p1.propeller.engines = 1
    assert np.allclose(res.L_tone - run_case(p1).L_tone, 10 * np.log10(2))


def test_windows_lower_the_noise_reduction(proj, res):
    p2 = copy.deepcopy(proj)
    p2.openings = []
    assert np.all(run_case(p2).NR_band >= res.NR_band - 1e-9)


def test_mission_and_static_segment(proj):
    assert len(run_mission(proj)) == len(proj.mission.segments)
    p2 = copy.deepcopy(proj)
    seg = p2.mission.segments[0]
    seg.mach, seg.thrust = 0.0, 0.0
    with pytest.raises(ValueError):
        run_case(p2, segment=0)
    seg.thrust = 12000.0
    assert np.all(np.isinf(run_case(p2, segment=0).L_bb))
