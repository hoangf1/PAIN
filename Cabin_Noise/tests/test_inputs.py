"""Every model input is visible: set in the default project file (not by a code default) and
editable in the GUI."""
import dataclasses
import json
import re
from pathlib import Path

import numpy as np
import pytest

from cabin_noise.core.cabin import seat_stat_db
from cabin_noise.core.io import DATA_DIR, default_project
from cabin_noise.core.materials import Opening, Sidewall, Surface
from cabin_noise.core.mission import Mission, Segment
from cabin_noise.core.pipeline import CabinConfig, Fuselage, Options, Project, Propeller, run_case

INPUTS = [Project, Mission, Segment, Propeller, Fuselage, Sidewall, Opening, CabinConfig, Surface, Options]
# fields edited by a table or a list editor instead of a form field (gui/panels.py)
TABLE_EDITORS = {"Project.mission", "Project.propeller", "Project.fuselage", "Project.sidewall",
                 "Project.openings", "Project.cabin", "Project.options", "Mission.segments", "Mission.active",
                 "Propeller.measured", "CabinConfig.surfaces", "CabinConfig.t60_measured",
                 "Opening.tl_freqs", "Opening.tl_values"}
GUI_SRC = (Path(__file__).resolve().parent.parent / "cabin_noise" / "gui").glob("*.py")


def _missing(cls, d, path):
    out = [f"{path}.{f.name}" for f in dataclasses.fields(cls) if f.name not in d]
    return out


def test_default_project_file_sets_every_input():
    d = json.loads((DATA_DIR / "default_project.json").read_text(encoding="utf-8"))
    miss = _missing(Project, d, "project")
    for k, cls in [("propeller", Propeller), ("fuselage", Fuselage), ("sidewall", Sidewall),
                   ("cabin", CabinConfig), ("options", Options), ("mission", Mission)]:
        miss += _missing(cls, d[k], k)
    miss += [m for s in d["mission"]["segments"] for m in _missing(Segment, s, "segment")]
    miss += [m for o in d["openings"] for m in _missing(Opening, o, "opening")]
    miss += [m for s in d["cabin"]["surfaces"] for m in _missing(Surface, s, "surface")]
    assert not miss, f"inputs falling back to a code default: {miss}"


def test_every_input_has_a_gui_field():
    src = "".join(p.read_text(encoding="utf-8") for p in GUI_SRC)
    missing = [f"{c.__name__}.{f.name}" for c in INPUTS for f in dataclasses.fields(c)
               if f"{c.__name__}.{f.name}" not in TABLE_EDITORS
               and not re.search(r'F\(f?"%s[".]' % re.escape(f.name), src)]
    assert not missing, f"inputs with no GUI field: {missing}"


@pytest.mark.parametrize("pct", [80.0, 90.0, 95.0, 99.0])
def test_seat_percentile_is_the_exponential_quantile(pct):
    p2 = np.random.default_rng(1).exponential(1.0, 400_000)
    assert seat_stat_db(pct) == pytest.approx(10 * np.log10(np.quantile(p2, pct / 100) / p2.mean()), abs=0.05)


def test_pipeline_uses_the_seat_percentile():
    p = default_project()
    p.options.seat_percentile = 90.0
    r = run_case(p)
    t = r.totals
    assert t["max_seat"]["total"]["OASPL"] - t["average"]["total"]["OASPL"] == pytest.approx(
        10 * np.log10(np.log(10.0)), abs=1e-9)
