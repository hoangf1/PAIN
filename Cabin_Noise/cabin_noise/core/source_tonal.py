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
