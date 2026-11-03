"""V0a-V3 from cases.yaml (analytic verification, plan section 5)."""
import pytest

from cabin_noise.core.validation import VERIFIERS, load_cases, run_case_id

CASES = [c for c in load_cases()["cases"] if c["kind"] == "verification"]


@pytest.mark.parametrize("meta", CASES, ids=[c["id"] for c in CASES])
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
