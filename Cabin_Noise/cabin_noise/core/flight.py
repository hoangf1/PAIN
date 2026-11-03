"""Runners for the experimental cases (paper pipeline): flush-microphone tones (V5), static
near-field tones (V5c), boundary-layer bands (V5b), cabin tones from the measured exterior (V7),
treatment insertion loss (V6)."""
from __future__ import annotations

import copy

import numpy as np

from .atmosphere import air, isa
from .mission import Segment, operating_point, tas_from_ias
from .source_tonal import gutin_rms, observer
from .weighting import db


def f_to_K(f: float) -> float:
    return (f - 32.0) * 5.0 / 9.0 + 273.15


def _atm(alt: float, T: float):
    """Air at a pressure altitude with a measured temperature."""
    return air(T, isa(alt).p)


def _t4(inp, cond):
    alt_ft, ias, oat, prpm, pkw, srpm, skw, cab_ft = inp["T4"][str(cond)]
    alt, T = alt_ft * 0.3048, f_to_K(oat)
    return alt, T, tas_from_ias(ias, alt, T), {"port": (prpm, pkw), "starboard": (srpm, skw)}, cab_ft * 0.3048


def surface_tones(inp: dict) -> dict:
    """V5: Gutin at the flush microphone plus the rigid-wall pressure doubling (CR-132602 p. 36:
    flush microphones include the reflection, up to 6 dB). {(cond, side, harmonic): L}."""
    r, theta = observer(*inp["mic"])
    out = {}
    for run in inp["runs"]:
        alt = run["alt_ft"] * 0.3048
        T = f_to_K(run["oat_F"])
        V = tas_from_ias(run["ias_kt"], alt, T)
        c = _atm(alt, T).c
        op = operating_point(Segment(altitude=alt, mach=V / c, rpm=run["rpm"], shaft_power=run["power_kW"] * 1e3,
                                     eta_p=inp["eta_p"], oat=T))
        m = np.arange(1, max(run["harmonics"]) + 1)
        p = gutin_rms(m, blades=inp["blades"], R_e=inp["re_fraction"] * inp["tip_radius"], omega=op.omega,
                      c=op.atm.c, thrust=op.thrust, torque=op.torque, r=r, theta=theta)
        L = db(p ** 2) + inp["surface_db"]
        for h in run["harmonics"]:
            out[(run["cond"], run["side"], h)] = float(L[h - 1])
    return out


def static_nearfield_harmonics(inp: dict) -> dict:
    """V5c: Gutin with the printed C_T, C_Q at the Report 996 microphones. {(M_t, x/D, m): L}."""
    from .atmosphere import air

    D, B = inp["diameter"], inp["blades"]
    R = D / 2
    atm = air(inp["T"], inp["p"])
    out = {}
    for cond in inp["conditions"]:
        omega = cond["M_t"] * atm.c / R
        n = omega / (2 * np.pi)
        T = cond["C_T"] * atm.rho * n ** 2 * D ** 4
        Q = cond["C_Q"] * atm.rho * n ** 2 * D ** 5
        m = np.arange(1, max(cond["harmonics"]) + 1)
        for xd in cond["x_over_D"]:
            r, theta = observer(xd * D, R + inp["d_over_D"] * D)
            L = db(gutin_rms(m, blades=B, R_e=inp["re_fraction"] * R, omega=omega, c=atm.c, thrust=T, torque=Q,
                             r=r, theta=theta) ** 2)
            for h in cond["harmonics"]:
                out[(cond["M_t"], round(xd, 3), h)] = float(L[h - 1])
    return out


def tbl_bands(inp: dict, conds, bands) -> dict:
    """V5b: Goody 1/3-octave wall level per condition."""
    from .frequencies import third_octave_centers
    from .source_tbl import boundary_layer, wall_band_pressure2

    fc = third_octave_centers(min(bands), max(bands))
    out = {}
    for cond in conds:
        alt, T, V, _, _ = _t4(inp, cond)
        atm = _atm(alt, T)
        out[cond] = (fc, db(wall_band_pressure2(fc, boundary_layer(atm, V, inp["nose_to_station"]))))
    return out


def _project(inp, cond, side=None, base_key="base"):
    from .io import project_from_dict
    from .mission import Mission

    alt, T, V, eng, cab_alt = _t4(inp, cond)
    d = copy.deepcopy(inp[base_key])
    d["cabin"]["cabin_altitude"] = cab_alt
    p = project_from_dict(d)
    c = _atm(alt, T).c
    segs = []
    for s in ([side] if side else ["port", "starboard"]):
        rpm, kw = eng[s]
        if rpm > 0:
            segs.append(Segment(name=f"c{cond} {s}", altitude=alt, mach=V / c, rpm=rpm, shaft_power=kw * 1e3,
                                eta_p=inp.get("eta_p", 0.8), oat=T))
    p.mission = Mission(segments=segs, active=0)
    return p


def cabin_tones(inp: dict) -> dict:
    """V7: interior level = exterior - NR (CR-132602 sec. 7), exterior from the measured flush
    level minus the wall doubling, one side. {(cond, side, harmonic): L}."""
    from .atmosphere import cabin_air
    from .pipeline import noise_reduction

    out = {}
    for side, tab in inp["exterior_surface_levels"].items():
        for cond, levels in tab.items():
            p = _project(inp, int(cond), side)
            seg = p.mission.segments[0]
            f = np.arange(1, len(levels) + 1) * p.propeller.blades * seg.rpm / 60.0
            air = cabin_air(p.cabin.cabin_altitude, p.cabin.temperature)
            L = np.array(levels) - inp["surface_db"] - noise_reduction(p, f, p.fuselage.side_area, air)
            for h in range(1, len(levels) + 1):
                out[(int(cond), side, h)] = float(L[h - 1])
    return out


def insertion_loss_bands(inp: dict, conds) -> dict:
    """V6: band IL = total level untreated - treated (TM-85722). Each engine is run on its own
    (one rpm per run); their tones are added in energy and the boundary layer, which every run
    contains, is counted once. {cond: (centers, IL)}."""
    from .pipeline import run_case

    out = {}
    for cond in conds:
        tot = {}
        for key in ("base", "treated"):
            p = _project(inp, cond, base_key=key)
            runs = [run_case(p, segment=i) for i in range(len(p.mission.segments))]
            tones = sum(10 ** (r.L_band_tonal / 10) for r in runs)
            tot[key] = 10 * np.log10(tones + 10 ** (runs[0].L_bb / 10))
            centers = runs[0].centers
        out[cond] = (centers, tot["base"] - tot["treated"])
    return out
