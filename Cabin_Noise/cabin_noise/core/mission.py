"""Mission segments and the operating point of the active segment."""
from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

from .atmosphere import Air, air, isa


@dataclass
class Segment:
    name: str = "Cruise"
    altitude: float = 6096.0      # m
    mach: float = 0.45
    rpm: float = 1700.0
    shaft_power: float = 800e3    # W per engine
    eta_p: float = 0.85
    thrust: float = 0.0           # N per propeller; used if > 0 (required when static)
    oat: float = 0.0              # measured outside air temperature, K; 0 = ISA at this altitude


@dataclass
class Mission:
    segments: list[Segment] = field(default_factory=lambda: [Segment()])
    active: int = 0

    def active_segment(self) -> Segment:
        if not self.segments:
            raise ValueError("mission has no segments")
        return self.segments[min(max(self.active, 0), len(self.segments) - 1)]


@dataclass(frozen=True)
class OperatingPoint:
    atm: Air
    V: float       # flight speed, m/s
    omega: float   # rad/s
    thrust: float  # N per propeller
    torque: float  # N m per propeller


def operating_point(seg: Segment) -> OperatingPoint:
    atm = isa(seg.altitude)
    if seg.oat > 0:                                   # pressure altitude + measured temperature
        atm = air(seg.oat, atm.p)
    V = seg.mach * atm.c
    omega = 2.0 * np.pi * seg.rpm / 60.0
    if omega <= 0:
        raise ValueError(f"segment '{seg.name}': RPM must be positive")
    torque = seg.shaft_power / omega
    if seg.thrust > 0:
        thrust = seg.thrust
    elif V > 0:
        thrust = seg.eta_p * seg.shaft_power / V
    else:
        raise ValueError(f"segment '{seg.name}' is static: enter thrust directly")
    return OperatingPoint(atm=atm, V=V, omega=omega, thrust=thrust, torque=torque)


KT = 0.514444
RHO_SL = 1.225


def tas_from_ias(ias_kt: float, pressure_altitude: float, oat_K: float) -> float:
    """True airspeed (m/s) from indicated airspeed, taking IAS = EAS (low-fi: no
    compressibility or position-error correction), density from pressure altitude and OAT."""
    rho = air(oat_K, isa(pressure_altitude).p).rho
    return ias_kt * KT * np.sqrt(RHO_SL / rho)
