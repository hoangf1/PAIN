"""Verification cases from cases.yaml (each block against its paper, no verdict)."""
import pytest

from cabin_noise.core.validation import VERIFIERS, load_cases, run_case_id

CASES = [c for c in load_cases()["cases"] if c["kind"] == "verification"]
# Recorded failures (cases.yaml recorded_status), kept visible: strict, so a change that makes one
# pass is noticed.
PARAMS = [pytest.param(c, id=c["id"], marks=pytest.mark.xfail(strict=True, raises=AssertionError,
                                                         reason=c.get("recorded", "recorded failure")))
          if c.get("recorded_status") == "check failed" else pytest.param(c, id=c["id"]) for c in CASES]


@pytest.mark.parametrize("meta", PARAMS)
def test_verification_case(meta):
    r = run_case_id(meta)
    assert r.status == "check ok", f"{r.id}: {r.value} >= {r.target} {r.unit} ({r.note})"


def test_every_verification_case_has_a_runner():
    assert {c["id"] for c in CASES} == set(VERIFIERS)


def test_experimental_cases_without_data_are_not_run():
    from cabin_noise.core.validation import VAL_DIR
    for c in load_cases()["cases"]:
        has = (VAL_DIR / c.get("ref_file", f"{c['id']}.csv")).exists() and (VAL_DIR / f"{c['id']}_inputs.json").exists()
        if c["kind"] == "validation" and not has:        # data-backed cases run in the Validation tab
            assert run_case_id(c).status == "not run"


def test_v4_runner_is_the_mass_law_of_skin_plus_treatment():
    """V4's code curve is eq. (46) for (0.95 + 2.174) lb/ft2, written out as the 0-90 deg integral
    of the plane-wave mass law, with 20 C sea-level air: an independent check of the runner."""
    import numpy as np
    from scipy.integrate import quad

    meta = next(c for c in load_cases()["cases"] if c["id"] == "V4")
    r = run_case_id(meta)
    m = (0.95 + 2.174) * 4.882428
    rho_c = (101325 / (287.05 * 293.15)) * np.sqrt(1.4 * 287.05 * 293.15)
    for f, tl in zip(r.x, r.code):
        x = np.pi * f * m / rho_c
        tau = quad(lambda p: np.sin(2 * p) / (1 + (x * np.cos(p)) ** 2), 0, np.pi / 2)[0]
        assert abs(tl + 10 * np.log10(tau)) < 0.02
    assert r.status == "not met"                     # recorded 2026-11-03 (cases.yaml)
