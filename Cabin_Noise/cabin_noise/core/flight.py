"""Flight-test helpers: exterior surface harmonic levels at a flush microphone (case V5).

The flush microphone measures surface pressure. The near propeller's free-field incident
harmonics (rotating point forces, plan A.2) are converted to surface pressure with the
rigid-cylinder factor at the lit point, |S(ka, 0)| (plan A.3).
"""
from __future__ import annotations

import numpy as np

from .mission import Segment, operating_point, tas_from_ias
from .scattering import surface_factor
from .source_tonal import rotor_harmonics
from .weighting import db


def f_to_K(f: float) -> float:
    return (f - 32.0) * 5.0 / 9.0 + 273.15


def surface_tones(inp: dict) -> list[dict]:
    """Predicted surface levels for every run in a V5 inputs file.

    inp keys: blades, tip_radius, re_fraction, eta_p, fuselage_radius, mic (aircraft axes
    relative to the near hub: x forward, y away from the fuselage negative, z down), and
    runs: [{cond, side, alt_ft, ias_kt, oat_F, rpm, power_kW, harmonics}].
    side "starboard" uses rotation_starboard; "port" is the mirror image (rotation flipped).
    """
    out = []
    for run in inp["runs"]:
        alt = run["alt_ft"] * 0.3048
        T = f_to_K(run["oat_F"])
        V = tas_from_ias(run["ias_kt"], alt, T)
        seg = Segment(name=f"c{run['cond']} {run['side']}", altitude=alt, rpm=run["rpm"],
                      shaft_power=run["power_kW"] * 1e3, eta_p=inp["eta_p"], oat=T)
        seg.mach = V / operating_point(Segment(altitude=alt, oat=T, rpm=1.0, thrust=1.0)).atm.c
        op = operating_point(seg)
        rot = inp["rotation_starboard"] * (1 if run["side"] == "starboard" else -1)
        n = max(run["harmonics"])
        P = rotor_harmonics(inp["mic"], blades=inp["blades"], R_e=inp["re_fraction"] * inp["tip_radius"],
                            omega=op.omega, V=op.V, c=op.atm.c, thrust=op.thrust, torque=op.torque,
                            n_harmonics=n, rotation=rot)
        m = np.arange(1, n + 1)
        ka = 2 * np.pi * m * inp["blades"] * run["rpm"] / 60.0 / op.atm.c * inp["fuselage_radius"]
        L_inc = db(np.abs(P) ** 2)
        L_surf = L_inc + 20 * np.log10(np.abs(surface_factor(ka, 0.0)))
        for h in run["harmonics"]:
            out.append({"cond": run["cond"], "side": run["side"], "harmonic": h, "L_inc": float(L_inc[h - 1]),
                        "L_surf": float(L_surf[h - 1]), "L_flat": float(L_inc[h - 1] + 20 * np.log10(2.0)),
                        "V": op.V, "M_hel": float(np.hypot(op.V, op.omega * inp["tip_radius"]) / op.atm.c)})
    return out


def static_nearfield_harmonics(inp: dict) -> dict:
    """Predicted rms harmonic SPL at static near-field microphones (NACA Report 996 layout):
    observer at radius R + d from the axis, x/D positive ahead of the propeller plane.
    Thrust and torque from the given C_T, C_Q (rho n^2 D^4, rho n^2 D^5). Returns
    {(M_t, x_over_D, m): L_dB}."""
    from .atmosphere import air
    from .blade import BladeGeometry, scaled_strip_loads, strip_harmonics

    D, B = inp["diameter"], inp["blades"]
    R = D / 2
    atm = air(inp["T"], inp["p"])
    out = {}
    for cond in inp["conditions"]:
        omega = cond["M_t"] * atm.c / R
        n = omega / (2 * np.pi)
        T = cond["C_T"] * atm.rho * n ** 2 * D ** 4
        Q = cond["C_Q"] * atm.rho * n ** 2 * D ** 5
        nh = max(cond["harmonics"])
        if inp["source_model"] == "blade":
            strips = scaled_strip_loads(BladeGeometry(**inp["blade"]), thrust=T, torque=Q, blades=B, R=R,
                                        omega=omega, V=0.0, rho=atm.rho, c=atm.c)
        for xd in cond["x_over_D"]:
            obs = [xd * D, -(R + inp["d_over_D"] * D), 0.0]
            if inp["source_model"] == "blade":
                P = strip_harmonics(obs, *strips, blades=B, omega=omega, V=0.0, c=atm.c, n_harmonics=nh)
            else:
                P = rotor_harmonics(obs, blades=B, R_e=inp["re_fraction"] * R, omega=omega, V=0.0, c=atm.c,
                                    thrust=T, torque=Q, n_harmonics=nh)
            for m in cond["harmonics"]:
                out[(cond["M_t"], round(xd, 3), m)] = float(db(np.abs(P[m - 1]) ** 2))
    return out


# ---- CR-178004 cabin and boundary-layer cases (V5b, V6, V7) ---------------------------------
def _t4(inp, cond):
    alt_ft, ias, oat, prpm, pkw, srpm, skw, cab_ft = inp["T4"][str(cond)]
    alt, T = alt_ft * 0.3048, f_to_K(oat)
    return alt, T, tas_from_ias(ias, alt, T), {"port": (prpm, pkw), "starboard": (srpm, skw)}, cab_ft * 0.3048


def _engine_project(inp, cond, side, sidewall=None, surfaces=None, grid=None):
    import copy

    from .io import project_from_dict
    from .mission import Mission

    alt, T, V, eng, cab_alt = _t4(inp, cond)
    rpm, kw = eng[side]
    d = copy.deepcopy(inp["base"])
    if sidewall is not None:
        d["sidewall"] = sidewall
    if surfaces is not None:
        d["cabin"]["surfaces"] = surfaces
    if grid is not None:
        d["fuselage"]["grid_nx"], d["fuselage"]["grid_nz"] = grid
    d["cabin"]["cabin_altitude"] = cab_alt
    L, x_front = d["fuselage"]["patch_width"], d["fuselage"]["patch_x_cabin"]
    d["propeller"]["axial_offset"] = x_front - L / 2.0
    d["propeller"]["rotation"] = inp["rotation_starboard"] * (1 if side == "starboard" else -1)
    p = project_from_dict(d)
    c = operating_point(Segment(altitude=alt, oat=T, rpm=1.0, thrust=1.0)).atm.c
    p.mission = Mission(segments=[Segment(name=f"c{cond} {side}", altitude=alt, mach=V / c, rpm=rpm,
                                          shaft_power=kw * 1e3, eta_p=0.80, oat=T)], active=0)
    return p


def cabin_tones(inp: dict) -> dict:
    """V7: room-average cabin level per (cond, engine, harmonic) from the measured exterior."""
    from .pipeline import run_case

    out = {}
    for side, tab in inp["exterior_surface_levels"].items():
        for cond, levels in tab.items():
            p = _engine_project(inp, int(cond), side)
            pr = p.propeller
            pr.n_harmonics = len(levels)
            seg = p.mission.segments[0]
            atm_c = operating_point(seg).atm.c
            m = np.arange(1, len(levels) + 1)
            ka = 2 * np.pi * m * pr.blades * seg.rpm / 60.0 / atm_c * p.fuselage.radius
            inc = np.array(levels) - 20 * np.log10(np.abs(surface_factor(ka, 0.0)))
            pr.source_mode, pr.measured_ref = "measured", list(inp["mic"])
            pr.measured = [[int(k), float(v)] for k, v in zip(m, inc)]
            r = run_case(p)
            for h in m:
                out[(int(cond), side, int(h))] = float(r.L_tone[h - 1])
    return out


def insertion_loss_bands(inp: dict, conds) -> dict:
    """V6: room-average 1/3-octave IL (untreated - treated) per condition, both engines in energy."""
    from .pipeline import run_case

    out = {}
    for cond in conds:
        tot = {}
        for cfg, sw, sf in (("bare", None, None), ("treated", inp["treated_sidewall"], inp["treated_surfaces"])):
            p2 = None
            for side in ("port", "starboard"):
                if _t4(inp, cond)[3][side][0] <= 0:
                    continue
                r = run_case(_engine_project(inp, cond, side, sw, sf, tuple(inp["grid"])))
                p2 = 10 ** (r.L_band_total / 10) if p2 is None else p2 + 10 ** (r.L_band_total / 10)
            tot[cfg] = (r.centers, 10 * np.log10(p2))
        f, Lb = tot["bare"]
        out[cond] = (f, Lb - tot["treated"][1])
    return out


def tbl_bands(inp: dict, conds, bands) -> dict:
    """V5b: Goody 1/3-octave wall-pressure level per condition at the given band centres."""
    from .frequencies import third_octave_centers
    from .source_tbl import boundary_layer, wall_band_pressure2

    fc = third_octave_centers(min(bands), max(bands))
    out = {}
    for cond in conds:
        alt, T, V, _, _ = _t4(inp, cond)
        atm = operating_point(Segment(altitude=alt, oat=T, rpm=1.0, thrust=1.0)).atm
        L = db(wall_band_pressure2(fc, boundary_layer(atm, V, inp["nose_to_station"])))
        out[cond] = (fc, L)
    return out
