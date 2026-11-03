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
