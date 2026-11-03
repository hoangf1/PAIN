"""JSON project files, CSV import/export, the default project and the surface library."""
from __future__ import annotations

import csv
import dataclasses
import json
from pathlib import Path

import numpy as np

from .frequencies import nominal_label
from .materials import Opening, Sidewall, Surface
from .mission import Mission, Segment
from .pipeline import CabinConfig, Fuselage, Options, Project, Propeller, Results

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
FORMAT_VERSION = 2


def load_library() -> dict:
    with open(DATA_DIR / "materials.json", encoding="utf-8") as fh:
        return json.load(fh)


def _lib_surface(lib, name, area) -> Surface:
    d = next(s for s in lib["surfaces"] if s["name"] == name)
    return Surface(name=name, area=area, alpha=list(d["alpha"]))


def default_project() -> Project:
    """Generic twin-turboprop example (stated inputs, not any particular aircraft)."""
    lib = load_library()
    cab = CabinConfig()
    floor = cab.Lx * cab.Ly
    walls = 2 * cab.Lx * cab.Lz * 0.75
    cab.surfaces = [
        _lib_surface(lib, "Carpet on floor", floor * 0.4),
        _lib_surface(lib, "Upholstered seats (per m2 floor)", floor * 0.6),
        _lib_surface(lib, "Trim panels", walls),
        _lib_surface(lib, "Perforated headliner", cab.Lx * cab.Ly),
        _lib_surface(lib, "Windows", 2 * 12 * 0.08),
        _lib_surface(lib, "Bulkhead (hard)", 2 * cab.Ly * cab.Lz),
    ]
    sidewall = Sidewall(skin_thickness=1.6e-3, skin_density=2780.0, skin_added_mass=1.5, double_wall=True,
                        trim_mass=2.7, blanket_mass=9.6 * 0.05, cavity_depth=0.09)
    windows = Opening(name="Windows (6 per side, 6 + 4 mm acrylic as one pane)", area=6 * 0.08, mode="mass",
                      mass=1190.0 * 0.010)
    mission = Mission(segments=[
        Segment(name="Climb", altitude=3000.0, mach=0.30, rpm=1700.0, shaft_power=900e3, eta_p=0.80),
        Segment(name="Cruise", altitude=6096.0, mach=0.45, rpm=1600.0, shaft_power=750e3, eta_p=0.85),
        Segment(name="Descent", altitude=3000.0, mach=0.40, rpm=1500.0, shaft_power=300e3, eta_p=0.80),
    ], active=1)
    return Project(name="Generic twin turboprop", mission=mission, propeller=Propeller(),
                   fuselage=Fuselage(side_area=cab.Lx * cab.Lz, tbl_area=2 * cab.Lx * cab.Lz),
                   sidewall=sidewall, openings=[windows], cabin=cab, options=Options())


# ---- JSON -------------------------------------------------------------------------
def project_to_dict(p: Project) -> dict:
    d = dataclasses.asdict(p)
    d["format_version"] = FORMAT_VERSION
    return d


def _build(cls, d: dict):
    names = {f.name for f in dataclasses.fields(cls)}
    return cls(**{k: v for k, v in d.items() if k in names})


def project_from_dict(d: dict) -> Project:
    if d.get("format_version", 1) < 2:
        raise ValueError("project file is from the retired pipeline (format 1); re-enter it in this version")
    m = d.get("mission", {})
    mission = Mission(segments=[_build(Segment, s) for s in m.get("segments", [])] or [Segment()],
                      active=int(m.get("active", 0)))
    cabd = dict(d.get("cabin", {}))
    cabd["surfaces"] = [_build(Surface, s) for s in cabd.get("surfaces", [])]
    return Project(
        name=d.get("name", "Untitled"), mission=mission,
        propeller=_build(Propeller, d.get("propeller", {})),
        fuselage=_build(Fuselage, d.get("fuselage", {})),
        sidewall=_build(Sidewall, d.get("sidewall", {})),
        openings=[_build(Opening, o) for o in d.get("openings", [])],
        cabin=_build(CabinConfig, cabd), options=_build(Options, d.get("options", {})))


def save_project(p: Project, path) -> None:
    Path(path).write_text(json.dumps(project_to_dict(p), indent=2), encoding="utf-8")


def load_project(path) -> Project:
    return project_from_dict(json.loads(Path(path).read_text(encoding="utf-8")))


# ---- CSV --------------------------------------------------------------------------
def load_measured_csv(path) -> list:
    """Measured exterior (free-field incident) harmonic levels: columns harmonic, level_dB."""
    rows = []
    with open(path, newline="", encoding="utf-8") as fh:
        for r in csv.reader(fh):
            if not r or r[0].strip().startswith("#"):
                continue
            try:
                rows.append([int(float(r[0])), float(r[1])])
            except ValueError:
                continue
    if not rows:
        raise ValueError(f"no harmonic rows in {path}")
    return rows


def export_results_csv(res: Results, path) -> None:
    with open(path, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["# segment", res.segment])
        w.writerow(["band_Hz", "nominal", "L_wall_dB", "L_ext_bb_dB", "NR_dB", "A_m2", "T60_s",
                    "L_int_broadband_dB", "L_int_tonal_dB", "L_int_total_dB"])
        for i, f in enumerate(res.centers):
            w.writerow([f"{f:.1f}", nominal_label(f), f"{res.L_wall[i]:.2f}", f"{res.L_ext_bb[i]:.2f}",
                        f"{res.NR_band[i]:.2f}", f"{res.A_band[i]:.3f}", f"{res.T60_band[i]:.3f}",
                        f"{res.L_bb[i]:.2f}", f"{res.L_band_tonal[i]:.2f}", f"{res.L_band_total[i]:.2f}"])
        w.writerow([])
        w.writerow(["harmonic", "f_Hz", "L_ext_dB", "NR_dB", "L_int_avg_dB"])
        for i, f in enumerate(res.f_m):
            w.writerow([i + 1, f"{f:.2f}", f"{res.L_ext_tone[i]:.2f}", f"{res.NR_tone[i]:.2f}",
                        f"{res.L_tone[i]:.2f}"])
        w.writerow([])
        w.writerow(["metric", "track", "average", "max_seat_95"])
        for track in ("tonal", "broadband", "total"):
            for k in ("OASPL", "dBA", "dBC"):
                w.writerow([k, track, f"{res.totals['average'][track][k]:.2f}",
                            f"{res.totals['max_seat'][track][k]:.2f}"])


def read_reference_csv(path) -> tuple[dict, np.ndarray]:
    """Digitized reference: '# key: value' header lines, then x,y[,...] rows."""
    meta, rows = {}, []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s:
            continue
        if s.startswith("#"):
            if ":" in s:
                k, v = s[1:].split(":", 1)
                meta[k.strip()] = v.strip()
            continue
        try:
            rows.append([float(x) for x in s.split(",")])
        except ValueError:
            continue
    return meta, np.array(rows)
