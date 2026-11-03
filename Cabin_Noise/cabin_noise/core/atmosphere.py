"""ISA atmosphere and cabin air (plan A.1)."""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

R_AIR = 287.05
GAMMA = 1.4
G0 = 9.80665


@dataclass(frozen=True)
class Air:
    T: float    # K
    p: float    # Pa
    rho: float  # kg/m^3
    c: float    # m/s
    mu: float   # Pa s
    nu: float   # m^2/s

    @property
    def rho_c(self) -> float:
        return self.rho * self.c


def air(T: float, p: float) -> Air:
    rho = p / (R_AIR * T)
    c = np.sqrt(GAMMA * R_AIR * T)
    mu = 1.458e-6 * T ** 1.5 / (T + 110.4)
    return Air(T=T, p=p, rho=rho, c=float(c), mu=mu, nu=mu / rho)


def isa(h: float) -> Air:
    """ISA properties at geometric altitude h (m), 0..20 km."""
    if h < -500 or h > 20000:
        raise ValueError(f"altitude {h} m outside ISA model range (-0.5..20 km)")
    if h <= 11000.0:
        T = 288.15 - 0.0065 * h
        p = 101325.0 * (T / 288.15) ** 5.2559
    else:
        T = 216.65
        p = 22632.0 * np.exp(-G0 * (h - 11000.0) / (R_AIR * 216.65))
    return air(T, float(p))


def cabin_air(cabin_altitude: float = 2438.4, T: float = 293.15) -> Air:
    """Cabin air: pressure of the ISA cabin-pressure altitude, cabin temperature T."""
    return air(T, isa(cabin_altitude).p)
