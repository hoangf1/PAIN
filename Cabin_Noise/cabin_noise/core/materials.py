"""Material and surface dataclasses for the sidewall stack and the cabin."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Union

import numpy as np

# Octave centres used for absorption tables.
ALPHA_OCTAVES = [63.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0]


@dataclass
class Panel:
    name: str = "Al skin 1.6 mm"
    E: float = 73.1e9       # Pa
    rho: float = 2780.0     # kg/m^3
    nu: float = 0.33
    h: float = 1.6e-3       # m
    eta: float = 0.01       # loss factor
    m_add: float = 0.0      # smeared stiffener / added mass, kg/m^2
    curved: bool = False    # True: ring-frequency (membrane) stiffness of the fuselage
    bay_a: float = 0.0      # stiffened-bay size (frame spacing), m; 0 = infinite panel
    bay_b: float = 0.0      # stiffened-bay size (stringer spacing), m
    kind: str = "panel"

    @property
    def mass(self) -> float:
        return self.rho * self.h + self.m_add

    @property
    def D(self) -> float:
        return self.E * self.h ** 3 / (12.0 * (1.0 - self.nu ** 2))

    def coincidence(self, c0: float) -> float:
        return c0 ** 2 / (2.0 * np.pi) * np.sqrt(self.mass / self.D)

    def bay_frequency(self) -> float:
        """Fundamental of one simply supported bay, f11 = (pi/2) sqrt(D / rho h) (1/a^2 + 1/b^2)
        (Leissa, Vibration of Plates); 0 when no bay is given."""
        if self.bay_a <= 0 or self.bay_b <= 0:
            return 0.0
        return 0.5 * np.pi * np.sqrt(self.D / (self.rho * self.h)) * (1 / self.bay_a ** 2 + 1 / self.bay_b ** 2)

    def ring_frequency(self, radius: float) -> float:
        cL = np.sqrt(self.E / (self.rho * (1.0 - self.nu ** 2)))
        return cL / (2.0 * np.pi * radius)


@dataclass
class PorousLayer:
    name: str = "Fiberglass blanket"
    d: float = 0.05         # thickness, m
    sigma: float = 10000.0  # flow resistivity, Pa s/m^2
    kind: str = "porous"


@dataclass
class AirGap:
    name: str = "Air gap"
    d: float = 0.025
    kind: str = "gap"


@dataclass
class PorousTable:
    """Porous layer from measured acoustical properties: wavelength in the material, attenuation
    (dB/m) and characteristic impedance |W| with phase phi (as CR-3813 Fig. A-2 gives them)."""
    name: str = "Measured blanket"
    d: float = 0.013
    f: list = field(default_factory=list)
    wavelength: list = field(default_factory=list)      # m
    atten_db_per_m: list = field(default_factory=list)
    W: list = field(default_factory=list)               # rayl
    phi_deg: list = field(default_factory=list)
    kind: str = "porous_table"

    def properties(self, f):
        """Zc and kc (e^{+j w t}: Im kc < 0, Im Zc < 0), log-f interpolation, end values held."""
        if len(self.f) < 2:
            raise ValueError(f"porous table '{self.name}' needs at least two frequencies")
        lf = np.log(np.asarray(f, dtype=float))
        g = lambda v: np.interp(lf, np.log(self.f), v)  # noqa: E731
        kc = 2 * np.pi / g(self.wavelength) - 1j * g(self.atten_db_per_m) / (20 * np.log10(np.e))
        Zc = g(self.W) * np.exp(-1j * np.radians(g(self.phi_deg)))
        return Zc, kc


Layer = Union[Panel, PorousLayer, AirGap, PorousTable]


def layer_from_dict(d: dict) -> Layer:
    kind = d.get("kind", "panel")
    cls = {"panel": Panel, "porous": PorousLayer, "gap": AirGap, "porous_table": PorousTable}[kind]
    names = cls.__dataclass_fields__.keys()
    return cls(**{k: v for k, v in d.items() if k in names})


@dataclass
class Surface:
    name: str = "Carpet"
    area: float = 10.0
    alpha: list[float] = field(default_factory=lambda: [0.05] * len(ALPHA_OCTAVES))

    def alpha_at(self, f) -> np.ndarray:
        """Absorption coefficient interpolated in log-frequency, held constant outside."""
        a = np.asarray(self.alpha, dtype=float)
        if a.size != len(ALPHA_OCTAVES):
            raise ValueError(f"surface '{self.name}' needs {len(ALPHA_OCTAVES)} octave alphas")
        return np.clip(np.interp(np.log(np.asarray(f, dtype=float)), np.log(ALPHA_OCTAVES), a), 0.0, 1.0)


@dataclass
class Opening:
    """Window or door: either its own layer stack or a diffuse TL table."""
    name: str = "Windows"
    area: float = 2.0
    mode: str = "layers"                # "layers" | "tl"
    layers: list = field(default_factory=list)
    tl_freqs: list[float] = field(default_factory=list)
    tl_values: list[float] = field(default_factory=list)

    def tau_table(self, f) -> np.ndarray:
        if len(self.tl_freqs) < 1 or len(self.tl_freqs) != len(self.tl_values):
            raise ValueError(f"opening '{self.name}': TL table is empty or ragged")
        tl = np.interp(np.log(np.asarray(f, dtype=float)), np.log(self.tl_freqs), self.tl_values)
        return 10.0 ** (-tl / 10.0)
