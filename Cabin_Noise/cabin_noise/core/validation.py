"""Case runner for the Validation tab and pytest.

Verification cases check that each block works exactly as its paper's equations say (no
verdict). Experimental cases carry met / not met against the dated criteria in cases.yaml.
Nothing here adjusts a model input to the reference data.
"""
from __future__ import annotations

import datetime as _dt
import json
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import yaml
from scipy.integrate import quad

from . import sea
from .io import DATA_DIR, load_project, read_reference_csv
from .pipeline import noise_reduction
from .source_tonal import gutin_rms

VAL_DIR = DATA_DIR / "validation"
RHO, C = 1.21, 343.0


@dataclass
class CaseResult:
    id: str
    meta: dict
    status: str                  # check ok | check failed | met | not met | not run | info
    value: float | None = None
    target: float | None = None
    unit: str = "dB"
    note: str = ""
    x: np.ndarray | None = None
    code: np.ndarray | None = None
    ref: np.ndarray | None = None
    xlabel: str = "Frequency (Hz)"
    ylabel: str = "Level (dB)"
    series: dict = field(default_factory=dict)


def load_cases() -> dict:
    with open(VAL_DIR / "cases.yaml", encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def _ver(meta, err, target, unit="dB", **kw) -> CaseResult:
    return CaseResult(meta["id"], meta, "check ok" if err < target else "check failed",
                      float(err), float(target), unit, **kw)


# ---- verification: each block against its paper ------------------------------------------
def run_V0a(meta):
    """Gutin's closed form vs a direct quadrature of the rotating-dipole far-field integral it
    comes from (p_n = (w / 4 pi c r) |(1/2pi) int x.F(psi) e^{j n (psi - z cos psi)} dpsi|, B blades)."""
    B, R, c, T, Q, r = 2, 1.0, 340.0, 2000.0, 600.0, 200.0
    om = 0.5 * c / R
    th = np.radians([45.0, 60.0, 75.0, 90.0, 105.0, 120.0, 135.0])
    psi = np.linspace(0, 2 * np.pi, 4096, endpoint=False)
    code, ref = [], []
    for t in th:
        g = gutin_rms(np.arange(1, 4), blades=B, R_e=R, omega=om, c=c, thrust=T, torque=Q, r=r, theta=t)
        q = []
        for m in (1, 2, 3):
            n = m * B
            z = n * om * R * np.sin(t) / c
            xF = -(T / B) * np.cos(t) - (Q / (B * R)) * np.sin(t) * np.sin(psi)
            I = np.mean(xF * np.exp(1j * n * psi - 1j * z * np.cos(psi)))
            q.append(np.sqrt(2) * B * n * om / (4 * np.pi * c * r) * abs(I))
        code.append(20 * np.log10(g / 20e-6))
        ref.append(20 * np.log10(np.array(q) / 20e-6))
    code, ref = np.array(code), np.array(ref)
    return _ver(meta, np.max(np.abs(code - ref)), meta["target_db"], x=np.degrees(th), code=code[:, 0],
                ref=ref[:, 0], xlabel="Angle from forward axis (deg)", ylabel="BPF1 level (dB)",
                note="markers = direct quadrature of the dipole integral")


def run_V1(meta):
    """CR-132602 eq. (46) vs the 0-90 deg random-incidence integral of eq. (45)."""
    f = np.geomspace(63, 5000, 30)
    m = 4.0
    code = -10 * np.log10(sea.tau_mass_law_diffuse(f, m, RHO * C))
    ref = []
    for fi in f:
        x = np.pi * fi * m / (RHO * C)
        ref.append(-10 * np.log10(quad(lambda p: np.sin(2 * p) / (1 + (x * np.cos(p)) ** 2), 0, np.pi / 2)[0]))
    ref = np.array(ref)
    return _ver(meta, np.max(np.abs(code - ref)), meta["target_db"], x=f, code=code, ref=ref, ylabel="TL (dB)")


def run_V2(meta):
    """CR-132602 eq. (52) vs a numeric solution of the report's power balance, eq. (47)."""
    f = np.geomspace(63, 5000, 25)
    S2, S3, S4, S5, V3, V5, L3, m2, m4, a3, a5 = 2.0, 2.6, 1.7, 9.0, 0.2, 30.0, 0.1, 4.0, 1.5, 0.6, 0.35
    code = sea.nr_double_wall(f, m_skin=m2, m_trim=m4, L3=L3, alpha3=a3, alpha5=a5, rho=RHO, c=C,
                              S2=S2, S3=S3, S4=S4, S5=S5)
    ref = []
    for fi in f:
        t31, t35 = sea.tau_mass_law_diffuse(fi, m2, RHO * C), sea.tau_mass_law_diffuse(fi, m4, RHO * C)
        eps = np.pi if fi < C / (2 * L3) else 4.0
        e31, e35 = C * S2 * t31 / (8 * np.pi * fi * V3), C * S4 * t35 / (8 * np.pi * fi * V3)
        e53, e3 = e35 * V3 / V5, S3 * C * a3 / (2 * eps * np.pi * fi * V3)
        e5 = C * S5 * a5 / (8 * np.pi * fi * V5)
        _, u5 = np.linalg.solve([[e3 + e31 + e35, -e35], [-e53, e5 + e53]], [e31, 0.0])
        ref.append(10 * np.log10(1 / u5))
    ref = np.array(ref)
    return _ver(meta, np.max(np.abs(code - ref)), meta["target_db"], x=f, code=code, ref=ref, ylabel="NR (dB)",
                note="markers = numeric solution of eq. (47)")


def run_V3(meta):
    """TM-85722 eqs. (1)-(3): IL = dTL + dABS. A treatment that raises the wall mass and the cabin
    absorption; the pipeline IL vs dTL (eq. 46) + 10 log10(alpha_treated / alpha_bare)."""
    import copy

    from .atmosphere import cabin_air
    from .io import default_project

    p = default_project()
    p.openings, p.sidewall.double_wall = [], False
    q = copy.deepcopy(p)
    q.sidewall.skin_added_mass += 3.0
    for s in q.cabin.surfaces:
        s.alpha = [min(1.0, 1.5 * a) for a in s.alpha]
    air = cabin_air(p.cabin.cabin_altitude, p.cabin.temperature)
    f = np.geomspace(100, 4000, 20)
    S = p.fuselage.side_area
    il = noise_reduction(q, f, S, air) - noise_reduction(p, f, S, air)
    dTL = 10 * np.log10(sea.tau_mass_law_diffuse(f, p.sidewall.m_skin, air.rho_c)
                        / sea.tau_mass_law_diffuse(f, q.sidewall.m_skin, air.rho_c))
    dABS = 10 * np.log10(q.cabin.absorption(f) / p.cabin.absorption(f))
    return _ver(meta, np.max(np.abs(il - (dTL + dABS))), meta["target_db"], x=f, code=il, ref=dTL + dABS,
                ylabel="IL (dB)", note="markers = dTL + dABS (TM-85722); equal when A >> S tau")


def run_V2p(meta):
    """CR-132602 Fig. 14 from the report's stated inputs, through the pipeline's noise_reduction:
    no openings, cabin alpha5 = mid-range of Fig. 4 on an area equal to the wall (S5/S2 = 1, the
    case's assumption: the report used eq. 53, whose S5/S2 it does not state), sea-level air. Single wall carries the check; the double wall is shown
    with blanket 0 (the report does not state the blanket mass), information only."""
    import copy

    from .atmosphere import isa
    from .io import default_project
    from .materials import ALPHA_OCTAVES, Surface

    inp = meta["inputs"]
    _, ref = read_reference_csv(VAL_DIR / "V2p.csv")
    _, fig4 = read_reference_csv(VAL_DIR / "CR132602_fig4_alpha.csv")
    f = ref[:, 0]

    def octaves(table):                             # report values at 125-4 kHz, end values held
        return [float(np.interp(np.log(o), np.log(table[:, 0]), table[:, 1])) for o in ALPHA_OCTAVES]

    p = default_project()
    p.openings = []
    S = p.fuselage.side_area
    p.cabin.t60_measured = None
    p.cabin.surfaces = [Surface("Fig. 4 mid-range", S, octaves(fig4[:, [0, 3]]))]
    sw = p.sidewall
    sw.skin_thickness = (inp["skin_mm"] + inp["doubler_mm"]) * 1e-3
    sw.skin_density, sw.skin_added_mass = inp["aluminium_density"], 0.0
    sw.trim_mass, sw.blanket_mass = inp["trim_mm"] * 1e-3 * inp["aluminium_density"], 0.0
    sw.cavity_depth = inp["cavity_depth"]
    cav = np.array(sorted(inp["cavity_alpha"].items()), dtype=float)
    sw.cavity_alpha = octaves(cav)
    air = isa(0.0)
    sw.double_wall = False
    single = noise_reduction(p, f, S, air)
    q = copy.deepcopy(p)
    q.sidewall.double_wall = True
    double = noise_reduction(q, f, S, air)
    err = single - ref[:, 1]
    note = ("markers = CR-132602 Fig. 14 single wall (the report's own prediction); code - report = "
            + ", ".join(f"{e:+.1f}" for e in err) + " dB at 125-4000 Hz. Double wall, information only "
            "(blanket mass not stated; code with blanket 0): code - report = "
            + ", ".join(f"{e:+.1f}" for e in double - ref[:, 2]) + " dB")
    return _ver(meta, np.max(np.abs(err)), meta["target_db"], x=f, code=single, ref=ref[:, 1], ylabel="NR (dB)",
                note=note, series={"double wall, code (blanket 0)": double, "double wall, Fig. 14": ref[:, 2]})


VERIFIERS = {"V0a": run_V0a, "V1": run_V1, "V2": run_V2, "V3": run_V3, "V2p": run_V2p}


# ---- experimental cases ------------------------------------------------------------------
def run_experimental(meta) -> CaseResult:
    cid = meta["id"]
    ref_path = VAL_DIR / meta.get("ref_file", f"{cid}.csv")
    inp_path = VAL_DIR / f"{cid}_inputs.json"
    if not (ref_path.exists() and inp_path.exists()):
        return CaseResult(cid, meta, "not run", target=meta.get("target_db"),
                          note="no reference data: digitize the report curve and its stated inputs")
    from . import flight

    ref_meta, data = read_reference_csv(ref_path)
    q = meta.get("quantity")
    if q == "reverberant_nr":
        from .pipeline import reverberant_noise_reduction
        nr = reverberant_noise_reduction(load_project(inp_path))
        x, y = data[:, 0], data[:, 1]
        res = _verdict(meta, ref_meta, x, np.interp(np.log(x), np.log(nr["centers"]), nr["NR"]), y,
                       "Frequency (Hz)")
        res.ylabel = "NR (dB)"
        return res
    inp = json.loads(inp_path.read_text(encoding="utf-8"))
    if q == "wall_tl":                           # rows: f, TL (first TL column is the compared layup)
        from .atmosphere import air, isa
        from .materials import Sidewall
        lb_ft2 = 4.882428                        # kg/m2 per lb/ft2
        sw = Sidewall(skin_thickness=1.0, skin_density=inp["skin_lb_ft2"] * lb_ft2,   # 1 m: density = areal mass
                      skin_added_mass=inp["treatment_lb_ft2"] * lb_ft2, double_wall=False, blanket_mass=0.0)
        a = air(inp["lab_temperature_K"], isa(inp["lab_altitude_m"]).p)
        x, y = data[:, 0], data[:, 1]
        res = _verdict(meta, ref_meta, x, -10 * np.log10(sea.tau_mass_law_diffuse(x, sw.m_skin, a.rho_c)), y,
                       "Frequency (Hz)")
        res.ylabel = "TL (dB)"
        return res
    if q == "surface_tones":                     # rows: cond, side (0 port / 1 stbd), harmonic, L
        pred = flight.surface_tones(inp)
        sides = ("port", "starboard")
        code = np.array([pred[(int(c), sides[int(s)], int(h))] for c, s, h, _ in data])
        y, xl = data[:, 3], "point (condition, side, harmonic)"
    elif q == "static_nearfield":                # rows: M_t, x/D, m, L
        pred = flight.static_nearfield_harmonics(inp)
        code = np.array([pred[(mt, round(xd, 3), int(m))] for mt, xd, m, _ in data])
        y, xl = data[:, 3], "point (M_t, x/D, harmonic)"
    elif q == "tbl_bands":                       # rows: cond, side, band, L
        pred = flight.tbl_bands(inp, sorted({int(c) for c in data[:, 0]}), sorted({float(f) for f in data[:, 2]}))
        code = np.array([np.interp(np.log(f), np.log(pred[int(c)][0]), pred[int(c)][1]) for c, _, f, _ in data])
        y, xl = data[:, 3], "point (condition, side, band)"
    elif q == "cabin_tones":                     # rows: cond, mic, engine, harmonic, L
        pred = flight.cabin_tones(inp)
        eng = ("port", "starboard")
        code = np.array([pred[(int(c), eng[int(e)], int(h))] for c, _, e, h, _ in data])
        y, xl = data[:, 4], "point (condition, mic, engine, harmonic)"
    elif q == "il_bands":                        # rows: cond, mic, band, IL
        pred = flight.insertion_loss_bands(inp, sorted({int(c) for c in data[:, 0]}))
        code = np.array([np.interp(np.log(f), np.log(pred[int(c)][0]), pred[int(c)][1]) for c, _, f, _ in data])
        y, xl = data[:, 3], "point (condition, mic, band)"
    else:
        return CaseResult(cid, meta, "not run", note=f"unknown quantity '{q}'")
    return _verdict(meta, ref_meta, np.arange(1, len(y) + 1, dtype=float), code, y, xl)


def criterion_range(meta, x) -> np.ndarray:
    """Points inside the case's criterion range (band_min / band_max, with 1/12-octave slack)."""
    lo, hi = meta.get("band_min", -np.inf), meta.get("band_max", np.inf)
    return (x >= lo / 2 ** (1 / 12)) & (x <= hi * 2 ** (1 / 12))


def _verdict(meta, ref_meta, x, code, y, xlabel) -> CaseResult:
    cid = meta["id"]
    ok = np.isfinite(y)
    x, y, code = x[ok], y[ok], code[ok]
    err = np.abs(code - y)
    sel = criterion_range(meta, x)
    if not np.any(sel):
        return CaseResult(cid, meta, "not run", note="no reference points inside the criterion range")
    worst = float(np.max(err[sel]))
    stats = (f"max |e| {worst:.1f} dB, RMS {np.sqrt(np.mean(err[sel] ** 2)):.1f} dB, "
             f"mean {np.mean((code - y)[sel]):+.1f} dB")
    head = f"{ref_meta.get('report', '')} {ref_meta.get('figure', '')}".strip()
    if "min_fraction" in meta:
        tol, need = meta["tol_db"], meta["min_fraction"]
        frac = float(np.mean(err[sel] <= tol))
        note = (f"{head}; {int(np.sum(err[sel] <= tol))}/{int(sel.sum())} points within +-{tol:g} dB "
                f"(need {need:.0%}); {stats}")
        return CaseResult(cid, meta, "met" if frac >= need else "not met", 100 * frac, 100 * need,
                          unit="% within", x=x, code=code, ref=y, note=note, xlabel=xlabel)
    tgt = meta.get("target_db")
    status = "info" if tgt is None else ("met" if worst <= tgt else "not met")
    return CaseResult(cid, meta, status, worst, tgt, x=x, code=code, ref=y, note=f"{head}; {stats}", xlabel=xlabel)


def run_case_id(meta) -> CaseResult:
    if meta["kind"] == "verification":
        return VERIFIERS[meta["id"]](meta)
    if meta["kind"] == "information":
        return CaseResult(meta["id"], meta, "info", note="run both tools on the same case")
    return run_experimental(meta)


def run_all() -> tuple[list[CaseResult], dict]:
    cfg = load_cases()
    out = [run_case_id(m) for m in cfg["cases"]]
    try:
        commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True,
                                cwd=Path(__file__).parent, timeout=5).stdout.strip() or "unknown"
    except (OSError, subprocess.SubprocessError):
        commit = "unknown"
    return out, {"date": _dt.datetime.now().isoformat(timespec="seconds"), "commit": commit,
                 "criteria_fixed": str(cfg.get("criteria_fixed", ""))}


def coverage(results: list[CaseResult]) -> str:
    ver = [r for r in results if r.meta["kind"] == "verification"]
    val = [r for r in results if r.meta["kind"] == "validation"]
    ran = [r for r in val if r.status in ("met", "not met")]
    ok = [r for r in ver if r.status == "check ok"]
    return (f"Verification {len(ok)}/{len(ver)} checks ok  |  Validation {len(ran)}/{len(val)} run, "
            f"{sum(r.status == 'met' for r in ran)} met")
