"""Propeller tones: Gutin's formula (Gutin 1936; as given in Hubbard (ed.), NASA RP-1258 vol. 1,
ch. 1). Loading noise of B blades with thrust T and torque Q concentrated at an effective
radius R_e (0.8 R_t), harmonic m of the blade passage frequency, observer at distance r and
angle theta from the forward axis:
    p_m,rms = (m B Omega / (2 sqrt2 pi c r)) |T cos(theta) - Q c / (Omega R_e^2)| J_mB(m B Omega R_e sin(theta) / c)
The formula is the static far-field result; this tool applies it as is (the low-fidelity
method), at the fuselage point nearest the propeller and with the flight thrust and torque.
"""
from __future__ import annotations

import numpy as np
from scipy.optimize import minimize_scalar
from scipy.special import jv


def gutin_rms(m, *, blades: int, R_e: float, omega: float, c: float, thrust: float,
              torque: float, r: float, theta: float) -> np.ndarray:
    """Rms pressure of harmonics m (array), Pa."""
    m = np.asarray(m, dtype=float)
    B = blades
    k = m * B * omega / c
    return (m * B * omega / (2.0 * np.sqrt(2.0) * np.pi * c * r)
            * np.abs(thrust * np.cos(theta) - torque * c / (omega * R_e ** 2))
            * np.abs(jv(m * B, k * R_e * np.sin(theta))))


def observer(axial: float, lateral: float, vertical: float = 0.0) -> tuple[float, float]:
    """Distance r and angle theta from the forward axis of a point at (axial forward, lateral,
    vertical) offsets from the hub."""
    r = float(np.sqrt(axial ** 2 + lateral ** 2 + vertical ** 2))
    return r, float(np.arccos(np.clip(axial / r, -1.0, 1.0)))


def loudest_axial(m, *, lateral: float, span: float, weights=None, n: int = 801, **gutin) -> float:
    """Axial offset (forward positive) in [-span, span], at the given lateral distance from the
    axis, where sum_m w_m p_m^2 from gutin_rms is largest: a grid of n points, then a bounded
    refinement between the grid neighbours of the best point."""
    m = np.asarray(m, dtype=float)
    w = np.ones_like(m) if weights is None else np.asarray(weights, dtype=float)

    def energy(x):
        r, th = observer(x, lateral)
        return float(np.sum(w * gutin_rms(m, r=r, theta=th, **gutin) ** 2))

    xs = np.linspace(-span, span, n)
    i = int(np.argmax([energy(x) for x in xs]))
    lo, hi = xs[max(i - 1, 0)], xs[min(i + 1, n - 1)]
    best = minimize_scalar(lambda x: -energy(x), bounds=(lo, hi), method="bounded", options={"xatol": 1e-4})
    return float(best.x) if -best.fun >= energy(xs[i]) else float(xs[i])
