"""Inputs of the paper pipeline: the CR-132602 sidewall, openings (TM-85722 eq. 1) and the
cabin's absorbing surfaces."""
from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

# Octave centres used for absorption tables.
ALPHA_OCTAVES = [63.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0]

# CR-132602 sec. 6.2: mean absorption of a cavity filled with glass-fibre blankets in thin bags
# (125-4000 Hz as printed; 63 and 8000 Hz hold the end values).
CR132602_CAVITY_ALPHA = [0.22, 0.22, 0.37, 0.82, 0.99, 0.88, 0.63, 0.63]


def octave_interp(values, f) -> np.ndarray:
    """Interpolate an 8-octave table in log-frequency, end values held, clipped to 0..1."""
    v = np.asarray(values, dtype=float)
    if v.size != len(ALPHA_OCTAVES):
        raise ValueError(f"octave table needs {len(ALPHA_OCTAVES)} values")
    return np.clip(np.interp(np.log(np.asarray(f, dtype=float)), np.log(ALPHA_OCTAVES), v), 0.0, 1.0)


@dataclass
class Sidewall:
    """CR-132602 non-resonant sidewall (sec. 5): skin and trim are mass-law walls, the cavity
    between them absorbs, and the insulation blanket's mass is added to the trim (sec. 6.2).
    double_wall = False is the skin alone (bare fuselage); the blanket mass then goes on the skin."""
    skin_thickness: float = 1.6e-3      # m
    skin_density: float = 2780.0        # kg/m^3
    skin_added_mass: float = 0.0        # smeared stiffeners / doublers, kg/m^2
    double_wall: bool = True
    trim_mass: float = 2.7              # kg/m^2
    blanket_mass: float = 0.48          # kg/m^2
    cavity_depth: float = 0.09          # m, skin to trim
    cavity_alpha: list = field(default_factory=lambda: list(CR132602_CAVITY_ALPHA))

    @property
    def m_skin(self) -> float:
        base = self.skin_density * self.skin_thickness + self.skin_added_mass
        return base if self.double_wall else base + self.blanket_mass

    @property
    def m_trim(self) -> float:
        return self.trim_mass + self.blanket_mass


@dataclass
class Surface:
    name: str = "Carpet"
    area: float = 10.0
    alpha: list[float] = field(default_factory=lambda: [0.05] * len(ALPHA_OCTAVES))

    def alpha_at(self, f) -> np.ndarray:
        return octave_interp(self.alpha, f)


@dataclass
class Opening:
    """Window or door. mode 'mass': one pane of the given surface mass (TM-85722 p. 17: a double
    window approximated as one pane of the summed thickness), CR-132602 eq. (46) mass law;
    mode 'tl': a diffuse TL table."""
    name: str = "Windows"
    area: float = 1.0
    mode: str = "mass"
    mass: float = 11.9                  # kg/m^2
    tl_freqs: list[float] = field(default_factory=list)
    tl_values: list[float] = field(default_factory=list)

    def tau(self, f, rho_c: float) -> np.ndarray:
        from .sea import tau_mass_law_diffuse
        f = np.asarray(f, dtype=float)
        if self.mode == "mass":
            return tau_mass_law_diffuse(f, self.mass, rho_c)
        if self.mode != "tl":
            raise ValueError(f"opening '{self.name}': mode must be 'mass' or 'tl'")
        if len(self.tl_freqs) < 1 or len(self.tl_freqs) != len(self.tl_values):
            raise ValueError(f"opening '{self.name}': TL table is empty or ragged")
        return 10.0 ** (-np.interp(np.log(f), np.log(self.tl_freqs), self.tl_values) / 10.0)
