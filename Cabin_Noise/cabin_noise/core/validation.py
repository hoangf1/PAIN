"""Case runner for the Validation tab and pytest.

Verification cases (V0a-V3) are analytic checks: they report "check ok" / "check failed"
and never a verdict. Experimental cases (V4-V7) carry met / not met only when a digitized
reference and an inputs-only project file exist; the criteria are the dated ones in
cases.yaml. Nothing here adjusts a model input to the reference data.
"""
from __future__ import annotations

import datetime as _dt
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import yaml

from . import seats as st
from . import tmm
from .atmosphere import air
from .io import DATA_DIR, load_project, read_reference_csv
from .materials import AirGap, Panel
from .scattering import surface_factor
from .source_tonal import gutin_rms, rotor_harmonics

VAL_DIR = DATA_DIR / "validation"
SEA_LEVEL = air(293.15, 101325.0)       # rho c ~ 413, matching the 20 log(mf) - 47 law


@dataclass
class CaseResult:
    id: str
    meta: dict
    status: str                  # check ok | check failed | met | not met | not run | info
    value: float | None = None
    target: float | None = None
    unit: str = "dB"
    note: str = ""
    x: np.ndarray | None = None          # figure: frequency / abscissa
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


# ---- verification cases -------------------------------------------------------------
def run_V0a(meta):
    B, R, c, T, Q, r = 2, 1.0, 340.0, 2000.0, 600.0, 200.0
    om = 0.5 * c / R
    th = np.radians([45.0, 60.0, 75.0, 90.0, 105.0, 120.0, 135.0])
    m = np.arange(1, 4)
    code, ref = [], []
    for t in th:
        P = rotor_harmonics([r * np.cos(t), r * np.sin(t), 0.0], blades=B, R_e=R, omega=om, V=0.0,
                            c=c, thrust=T, torque=Q, n_harmonics=3)
        code.append(20 * np.log10(np.abs(P) / 20e-6))
        ref.append(20 * np.log10(gutin_rms(m, blades=B, R_e=R, omega=om, c=c, thrust=T, torque=Q,
                                           r=r, theta=t) / 20e-6))
    code, ref = np.array(code), np.array(ref)
    return _ver(meta, np.max(np.abs(code - ref)), meta["target_db"], x=np.degrees(th), code=code[:, 0],
                ref=ref[:, 0], xlabel="Angle from forward axis (deg)", ylabel="BPF1 level (dB)",
                note="B=2, M_tip=0.5, r=200 m; markers = Gutin")


def run_V0b(meta):
    ka = np.geomspace(0.01, 50.0, 40)
    lit = 20 * np.log10(np.abs(surface_factor(ka, 0.0)))
    err = max(abs(lit[0] - 0.0), abs(lit[-1] - 20 * np.log10(2.0)))
    return _ver(meta, err, meta["target_db"], x=ka, code=lit,
                ref=np.where(ka < 0.1, 0.0, np.where(ka > 20, 6.02, np.nan)),
                xlabel="ka", ylabel="Lit-point |S| (dB)",
                series={"shadow": 20 * np.log10(np.abs(surface_factor(ka, np.pi)))})


def run_V0c(meta):
    box = st.Box(8.0, 1.9, 1.8)
    patch = st.SidewallPatch(3.0, 1.5, 1.1, 1.0)
    g = [np.linspace(0, L, n, endpoint=False) + L / (2 * n) for L, n in ((8.0, 80), (1.9, 20), (1.8, 20))]
    pts = np.stack([a.ravel() for a in np.meshgrid(*g, indexing="ij")], axis=1)
    freqs = np.array([40.0, 80.0, 120.0, 160.0])
    dev = []
    for f in freqs:
        rel = st.relative_level(f, pts, box, 343.0, 0.4, patch)
        dev.append(10 * np.log10(np.mean(10 ** (rel / 10))))
    dev = np.array(dev)
    return _ver(meta, np.max(np.abs(dev)), meta["target_db"], x=freqs, code=dev, ref=0 * dev,
                ylabel="10 log10 mean(G/<G>) (dB)", note="midpoint grid 80x20x20")


def run_V1(meta):
    p = Panel(h=1.6e-3)
    f = np.geomspace(50, 2000, 60)
    code = tmm.tl(tmm.tau([p], f, 0.0, SEA_LEVEL))
    ref = 10 * np.log10(1 + (2 * np.pi * f * p.mass / (2 * SEA_LEVEL.rho_c)) ** 2)
    return _ver(meta, np.max(np.abs(code - ref)), meta["target_db"], x=f, code=code, ref=ref,
                ylabel="TL (dB)")


def run_V2(meta):
    p = Panel(h=1.6e-3)
    f = np.geomspace(50, 10000, 80)
    code = tmm.tl(tmm.tau_diffuse([p], f, SEA_LEVEL))
    ref = 20 * np.log10(p.mass * f) - 47.0
    tl0 = 10 * np.log10(1 + (2 * np.pi * f * p.mass / (2 * SEA_LEVEL.rho_c)) ** 2)
    sel = (tl0 > 20.0) & (f < p.coincidence(SEA_LEVEL.c) / 4)
    return _ver(meta, np.max(np.abs(code[sel] - ref[sel])), meta["target_db"], x=f[sel], code=code[sel],
                ref=ref[sel], ylabel="TL (dB)")


def run_V3(meta):
    p1, p2 = Panel(h=1.0e-3), Panel(h=2.0e-3)
    d = 0.05
    f0 = tmm.mass_air_mass_f0(p1.mass, p2.mass, d, SEA_LEVEL)
    f = np.geomspace(f0 / 4, f0 * 4, 2000)
    t = tmm.tl(tmm.tau([p1, AirGap(d=d), p2], f, 0.0, SEA_LEVEL))
    f_dip = f[np.argmin(t)]
    return _ver(meta, abs(np.log2(f_dip / f0)), meta["target_oct"], unit="oct", x=f, code=t,
                ref=None, ylabel="TL normal incidence (dB)",
                note=f"f0 = {f0:.1f} Hz, dip at {f_dip:.1f} Hz", series={"f0": f0, "f_dip": f_dip})


VERIFIERS = {"V0a": run_V0a, "V0b": run_V0b, "V0c": run_V0c, "V1": run_V1, "V2": run_V2, "V3": run_V3}


# ---- experimental cases ---------------------------------------------------------------
def run_experimental(meta) -> CaseResult:
    cid = meta["id"]
    ref_path, inp_path = VAL_DIR / f"{cid}.csv", VAL_DIR / f"{cid}_inputs.json"
    if not (ref_path.exists() and inp_path.exists()):
        return CaseResult(cid, meta, "not run", target=meta.get("target_db"),
                          note="no reference data: digitize the report curve and its stated inputs")
    from .pipeline import run_case

    ref_meta, data = read_reference_csv(ref_path)
    q = meta.get("quantity")
    res = None if q == "reverberant_nr" else run_case(load_project(inp_path))
    x, y = data[:, 0], data[:, 1]
    if q == "tl_band":
        code = np.interp(np.log(x), np.log(res.centers), res.tl_band)
    elif q == "L_wall":
        code = np.interp(np.log(x), np.log(res.centers), res.L_wall)
    elif q == "reverberant_nr":
        from .pipeline import reverberant_noise_reduction
        nr = reverberant_noise_reduction(load_project(inp_path))
        code = np.interp(np.log(x), np.log(nr["centers"]), nr["NR"])
    elif q == "L_tone":
        code = res.L_tone[x.astype(int) - 1]
    elif q == "surface_tones":
        ka = 2 * np.pi * res.f_m / res.atm.c * load_project(inp_path).fuselage.radius
        surf = res.L_inc[0] + 20 * np.log10(np.abs(surface_factor(ka, 0.0)))
        code = surf[x.astype(int) - 1]
    else:
        return CaseResult(cid, meta, "not run", note=f"quantity '{q}' needs a two-configuration runner")
    ok = np.isfinite(y)
    x, y, code = x[ok], y[ok], code[ok]
    err = np.abs(code - y)
    lo, hi = meta.get("band_min", -np.inf), meta.get("band_max", np.inf)
    sel = (x >= lo / 2 ** (1 / 12)) & (x <= hi * 2 ** (1 / 12))
    if not np.any(sel):
        return CaseResult(cid, meta, "not run", note="no reference points inside the criterion range")
    worst = float(np.max(err[sel]))
    stats = (f"max |e| {worst:.1f} dB, RMS {np.sqrt(np.mean(err[sel] ** 2)):.1f} dB, "
             f"mean {np.mean((code - y)[sel]):+.1f} dB")
    head = f"{ref_meta.get('report', '')} {ref_meta.get('figure', '')}".strip()
    if "min_fraction" in meta:                     # low-fi policy: fraction within +-tol
        tol, need = meta["tol_db"], meta["min_fraction"]
        frac = float(np.mean(err[sel] <= tol))
        status = "met" if frac >= need else "not met"
        note = (f"{head}; {int(np.sum(err[sel] <= tol))}/{int(sel.sum())} points within +-{tol:g} dB "
                f"(need {need:.0%}); {stats}")
        return CaseResult(cid, meta, status, 100 * frac, 100 * need, unit="% within", x=x, code=code,
                          ref=y, note=note)
    tgt = meta.get("target_db")
    status = "info" if tgt is None else ("met" if worst <= tgt else "not met")
    within_all = float(np.mean(err <= tgt) * 100) if tgt else float("nan")
    note = (f"{head}; verdict on {int(sel.sum())} points in {lo:g}-{hi:g}; all {len(x)} points: "
            + f"{within_all:.0f}% within target (information); {stats}")
    return CaseResult(cid, meta, status, worst, tgt, x=x, code=code, ref=y, note=note)


def run_case_id(meta) -> CaseResult:
    if meta["kind"] == "verification":
        return VERIFIERS[meta["id"]](meta)
    if meta["kind"] == "information":
        return CaseResult(meta["id"], meta, "info", note="run both tools on the same JSON case")
    return run_experimental(meta)


def run_all() -> tuple[list[CaseResult], dict]:
    cfg = load_cases()
    out = [run_case_id(m) for m in cfg["cases"]]
    try:
        commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True,
                                cwd=Path(__file__).parent, timeout=5).stdout.strip() or "unknown"
    except (OSError, subprocess.SubprocessError):
        commit = "unknown"
    stamp = {"date": _dt.datetime.now().isoformat(timespec="seconds"), "commit": commit,
             "criteria_fixed": str(cfg.get("criteria_fixed", ""))}
    return out, stamp


def coverage(results: list[CaseResult]) -> str:
    ver = [r for r in results if r.meta["kind"] == "verification"]
    val = [r for r in results if r.meta["kind"] == "validation"]
    ran = [r for r in val if r.status in ("met", "not met")]
    met = [r for r in ran if r.status == "met"]
    ok = [r for r in ver if r.status == "check ok"]
    return (f"Verification {len(ok)}/{len(ver)} checks ok  |  Validation {len(ran)}/{len(val)} run, "
            f"{len(met)} met")
