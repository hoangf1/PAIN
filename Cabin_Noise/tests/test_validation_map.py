"""The validation map layout must match the case list: every case under exactly one block,
no unknown cases, edges between existing blocks, no two blocks on the same grid cell."""
from collections import Counter

from cabin_noise.core.validation import load_cases
from cabin_noise.gui.validation_map import load_map


def test_every_case_on_the_map_exactly_once():
    ids = [c["id"] for c in load_cases()["cases"]]
    on_map = [cid for b in load_map()["blocks"] for cid in b.get("cases", [])]
    counts = Counter(on_map)
    assert set(on_map) == set(ids), f"missing {set(ids) - set(on_map)}, unknown {set(on_map) - set(ids)}"
    assert all(n == 1 for n in counts.values()), [k for k, n in counts.items() if n > 1]


def test_edges_and_grid_are_consistent():
    m = load_map()
    blocks = {b["id"] for b in m["blocks"]}
    groups = {g["id"] for g in m["groups"]}
    assert all(a in blocks and b in blocks for a, b in m["edges"])
    assert all(b["group"] in groups for b in m["blocks"])
    cells = Counter((b["col"], b["row"]) for b in m["blocks"])
    assert all(n == 1 for n in cells.values())
