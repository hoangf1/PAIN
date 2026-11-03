"""run_case(project) -> Results: the low-fidelity paper pipeline (METHOD.md).

    exterior level  ->  noise reduction of the sidewall  ->  interior level
    L_int = L_ext - NR                                  (CR-132602 sec. 7)

- Tones: Gutin's formula at the fuselage point nearest each propeller (source_tonal), one
  propeller per side, sides added in energy.
- Boundary layer: Goody wall spectrum (source_tbl), converted to the equivalent diffuse field
  <p_e^2> = <p_wall^2> / 2 (Waterhouse 1955; CR-3813 p. 23).
- NR: CR-132602 non-resonant model, eqs. (46), (49)-(52) (sea), with the cabin absorption
  A = sum S alpha (Sabine); openings combined by area-weighted transmission (TM-85722 eq. 1)
  through the single-wall form NR = 10 log10(1 + A / (S tau)).
- Insertion loss between two configurations = L_bare - L_treated (TM-85722).
- Seat spread: the 95th-percentile seat, 10 log10(ln 20) above the room average (Schroeder).
"""
from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

from . import cabin as cab
from . import sea
from .atmosphere import Air, cabin_air
from .frequencies import band_index, harmonic_frequencies, harmonics_in_range, third_octave_centers
from .materials import Opening, Sidewall, Surface, octave_interp
from .mission import Mission, Segment, operating_point
from .source_tbl import boundary_layer, wall_band_pressure2
from .source_tonal import gutin_rms, observer
from .weighting import db, p2_from_db, totals

WATERHOUSE_DB = 10.0 * np.log10(2.0)


@dataclass
class Propeller:
    blades: int = 4
    tip_radius: float = 1.3          # m
    clearance: float = 0.5           # tip to fuselage, m
    axial_offset: float = 0.0        # observer (fuselage point) ahead of the propeller plane, m
    engines: int = 2                 # 1 or 2 (one propeller per side)
    n_harmonics: int = 0             # 0 = every harmonic up to the top analysis band (auto)
    re_fraction: float = 0.8         # Gutin effective radius / tip radius
    source_mode: str = "generated"   # "generated" (Gutin) | "measured" (exterior levels given)
    measured: list = field(default_factory=list)   # [[m, L_ext dB (free-field incident)], ...]


@dataclass
class Fuselage:
    nose_to_station: float = 4.0     # nose to the propeller-plane station (boundary layer), m
    side_area: float = 15.0          # sidewall area on one side (exposed to that side's propeller), m^2
    tbl_area: float = 30.0           # sidewall area exposed to the boundary layer, m^2


@dataclass
class CabinConfig:
    # Box of the cabin air above the floor (the underfloor bay is not part of the cabin).
    Lx: float = 22.7                 # cabin length, m
    Ly: float = 2.64                 # cabin width, m
    Lz: float = 1.9                  # floor to ceiling, m (assumed, typical regional turboprop)
    cabin_altitude: float = 2438.4   # m (cabin pressure altitude)
    temperature: float = 293.15      # K
    surfaces: list = field(default_factory=list)
    volume: float = 0.0              # m^3; 0 = box volume
    t60_measured: list = field(default_factory=list)  # [[f, T60], ...]; if set, A = 0.161 V / T60

    def cabin_volume(self) -> float:
        return self.volume if self.volume > 0 else self.Lx * self.Ly * self.Lz

    def absorption(self, f) -> np.ndarray:
        """A(f): from measured T60 (log-log interpolation, end values held) or from the surfaces."""
        f = np.atleast_1d(np.asarray(f, dtype=float))
        if self.t60_measured:
            tf, tt = np.array(sorted(self.t60_measured), dtype=float).T
            return 0.161 * self.cabin_volume() / np.exp(np.interp(np.log(f), np.log(tf), np.log(tt)))
        return cab.absorption_area(self.surfaces, f)


@dataclass
class Options:
    f_min: float = 50.0              # analysis range (1/3-octave bands), Hz
    f_max: float = 5000.0
    seat_percentile: float = 95.0    # "max seat" = this percentile of the seats (Schroeder statistic)


@dataclass
class Project:
    name: str = "Untitled"
    mission: Mission = field(default_factory=Mission)
    propeller: Propeller = field(default_factory=Propeller)
    fuselage: Fuselage = field(default_factory=Fuselage)
    sidewall: Sidewall = field(default_factory=Sidewall)
    openings: list = field(default_factory=list)
    cabin: CabinConfig = field(default_factory=CabinConfig)
    options: Options = field(default_factory=Options)


@dataclass
class Results:
    segment: str
    atm: Air
    cabin_air: Air
    V: float
    thrust: float
    torque: float
    bpf: float
    tip_mach: float
    f_m: np.ndarray
    L_ext_tone: np.ndarray       # free-field level at the fuselage, one side, per harmonic
    centers: np.ndarray
    L_wall: np.ndarray           # Goody wall (blocked) level per band
    L_ext_bb: np.ndarray         # equivalent diffuse exterior level per band
    NR_band: np.ndarray          # NR for the boundary-layer exposure
    NR_tone: np.ndarray          # NR for one side, at the harmonics
    tl_skin: np.ndarray          # CR-132602 eq. (46) TL of the skin per band (plot)
    tl_trim: np.ndarray
    A_band: np.ndarray
    T60_band: np.ndarray
    f_s: float
    L_tone: np.ndarray           # interior room average per harmonic
    L_bb: np.ndarray             # interior room average broadband per band
    L_band_tonal: np.ndarray
    L_band_total: np.ndarray
    totals: dict                 # "average" / "max_seat" -> "tonal" / "broadband" / "total"
    warnings: list
    seat_percentile: float = 95.0  # options.seat_percentile used for "max_seat"
    seat_db: float = 0.0         # max seat above the room average, dB


# ---- noise reduction --------------------------------------------------------------------
def noise_reduction(proj: Project, f, S: float, air: Air) -> np.ndarray:
    """NR of the sidewall (exposed area S) into the cabin, dB.

    Wall: CR-132602 eq. (52) (double wall) or the single-wall form 10 log10(1 + A / (S tau)).
    Openings: areas are given per side (inside fuselage.side_area) and scale with the exposure,
    S / side_area; area-weighted transmission with the wall's equivalent tau (TM-85722 eq. 1)."""
    sw = proj.sidewall
    f = np.atleast_1d(np.asarray(f, dtype=float))
    A = proj.cabin.absorption(f)
    if np.any(A <= 0):
        raise ValueError("cabin absorption must be > 0 at every frequency (room equation)")
    if sw.m_skin <= 0 or (sw.double_wall and sw.m_trim <= 0):
        raise ValueError("skin and trim (+ blanket) surface masses must be > 0 (mass law, CR-132602 eq. 46)")
    if any(o.mode == "mass" and o.mass <= 0 for o in proj.openings):
        raise ValueError("opening pane masses must be > 0 (mass law)")
    k_open = S / proj.fuselage.side_area
    S_open = k_open * sum(o.area for o in proj.openings)
    if S_open >= S:
        raise ValueError("openings area exceeds the exposed sidewall area")
    if sw.double_wall:
        nr_wall = sea.nr_double_wall(f, m_skin=sw.m_skin, m_trim=sw.m_trim, L3=sw.cavity_depth,
                                     alpha3=octave_interp(sw.cavity_alpha, f), alpha5=A / S, rho=air.rho, c=air.c)
    else:
        nr_wall = sea.nr_single_wall(f, m=sw.m_skin, alpha5=A / S, rho=air.rho, c=air.c)
    if not proj.openings:
        return nr_wall
    t_wall = sea.tau_equivalent(nr_wall, A / S)
    t = ((S - S_open) * t_wall + k_open * sum(o.area * o.tau(f, air.rho_c) for o in proj.openings)) / S
    return 10.0 * np.log10(1.0 + A / (S * t))


def reverberant_noise_reduction(proj: Project) -> dict:
    """NR in a diffuse exterior field over the whole exposed area (lab reverberant test)."""
    cb, opt = proj.cabin, proj.options
    air = cabin_air(cb.cabin_altitude, cb.temperature)
    centers = third_octave_centers(opt.f_min, opt.f_max)
    nr = noise_reduction(proj, centers, proj.fuselage.side_area, air)
    return {"centers": centers, "NR": nr, "A": cb.absorption(centers)}


# ---- the case ---------------------------------------------------------------------------
def run_case(proj: Project, segment: int | None = None) -> Results:
    warn: list[str] = []
    seg: Segment = proj.mission.segments[segment] if segment is not None else proj.mission.active_segment()
    pr, fu, cb, opt, sw = proj.propeller, proj.fuselage, proj.cabin, proj.options, proj.sidewall
    op = operating_point(seg)
    ext = op.atm
    air = cabin_air(cb.cabin_altitude, cb.temperature)
    centers = third_octave_centers(opt.f_min, opt.f_max)
    if pr.n_harmonics > 0:
        n_harm = pr.n_harmonics
    elif pr.source_mode == "measured" and pr.measured:          # auto, measured: the harmonics given
        n_harm = int(max(r[0] for r in pr.measured))
    else:                                                       # auto: up to the top analysis band
        n_harm = harmonics_in_range(pr.blades, seg.rpm, centers)
    f_m = harmonic_frequencies(pr.blades, seg.rpm, n_harm)
    m_idx = np.arange(1, n_harm + 1)
    if pr.engines not in (1, 2):
        raise ValueError("engine count must be 1 or 2")

    # [1] exterior tones at the fuselage, one side
    if pr.source_mode == "measured":
        meas = {int(r[0]): float(r[1]) for r in pr.measured}
        missing = [m for m in m_idx if m not in meas]
        if missing:
            raise ValueError(f"measured exterior levels missing for harmonics {missing}")
        L_ext_tone = np.array([meas[m] for m in m_idx])
    elif pr.source_mode == "generated":
        M_h = np.hypot(op.omega * pr.tip_radius, op.V) / ext.c
        if M_h >= 1.0:
            warn.append(f"helical tip Mach {M_h:.2f} >= 1: supersonic tips; Gutin's loading-noise formula "
                        "does not cover the thickness and shock noise that then dominate")
        r, theta = observer(pr.axial_offset, pr.tip_radius + pr.clearance)
        p = gutin_rms(m_idx, blades=pr.blades, R_e=pr.re_fraction * pr.tip_radius, omega=op.omega, c=ext.c,
                      thrust=op.thrust, torque=op.torque, r=r, theta=theta)
        L_ext_tone = db(p ** 2)
    else:
        raise ValueError("source mode must be 'generated' or 'measured'")

    # [2] exterior boundary layer (diffuse equivalent)
    if op.V > 0:
        L_wall = db(wall_band_pressure2(centers, boundary_layer(ext, op.V, fu.nose_to_station)))
    else:
        warn.append("static segment: no boundary-layer source")
        L_wall = np.full_like(centers, -np.inf)
    L_ext_bb = L_wall - WATERHOUSE_DB

    # [3] noise reduction and interior levels
    NR_tone = noise_reduction(proj, f_m, fu.side_area, air)
    NR_band = noise_reduction(proj, centers, fu.tbl_area, air)
    L_tone = L_ext_tone - NR_tone + 10.0 * np.log10(pr.engines)          # one propeller per side
    L_bb = L_ext_bb - NR_band
    A_band = cb.absorption(centers)
    vol = cb.cabin_volume()
    T60_band = cab.t60(vol, A_band)
    f_s = cab.schroeder_frequency(float(np.mean(cab.t60(vol, cb.absorption([500.0, 1000.0])))), vol)

    bi = band_index(f_m, centers)
    if np.any(bi < 0):
        warn.append(f"harmonics outside {opt.f_min:g}-{opt.f_max:g} Hz are left out of the band totals: "
                    + ", ".join(f"{f:.0f} Hz" for f in f_m[bi < 0]))
    p_tone_band = np.zeros_like(centers)
    for i, b in enumerate(bi):
        if b >= 0:
            p_tone_band[b] += p2_from_db(L_tone[i])
    L_band_tonal = db(p_tone_band)
    L_band_total = db(p_tone_band + p2_from_db(L_bb))
    avg = {"tonal": totals(L_band_tonal, centers), "broadband": totals(L_bb, centers),
           "total": totals(L_band_total, centers)}
    seat_db = cab.seat_stat_db(opt.seat_percentile)
    mx = {k: totals(v + seat_db, centers) for k, v in
          (("tonal", L_band_tonal), ("broadband", L_bb), ("total", L_band_total))}

    return Results(
        segment=seg.name, atm=ext, cabin_air=air, V=op.V, thrust=op.thrust, torque=op.torque,
        bpf=float(f_m[0]), tip_mach=op.omega * pr.tip_radius / ext.c, f_m=f_m, L_ext_tone=L_ext_tone,
        centers=centers, L_wall=L_wall, L_ext_bb=L_ext_bb, NR_band=NR_band, NR_tone=NR_tone,
        tl_skin=-10 * np.log10(sea.tau_mass_law_diffuse(centers, sw.m_skin, air.rho_c)),
        tl_trim=(-10 * np.log10(sea.tau_mass_law_diffuse(centers, sw.m_trim, air.rho_c)) if sw.double_wall
                 else np.full_like(centers, np.nan)),
        A_band=A_band, T60_band=T60_band, f_s=f_s, L_tone=L_tone, L_bb=L_bb, L_band_tonal=L_band_tonal,
        L_band_total=L_band_total, totals={"average": avg, "max_seat": mx}, seat_percentile=opt.seat_percentile, seat_db=seat_db, warnings=warn)


def run_mission(proj: Project) -> list[Results]:
    return [run_case(proj, segment=i) for i in range(len(proj.mission.segments))]


def insertion_loss(bare: Results, treated: Results) -> dict:
    """IL = L_bare - L_treated per band (total, broadband) and per harmonic (TM-85722)."""
    if not np.allclose(bare.centers, treated.centers):
        raise ValueError("configurations use different band grids")
    out = {"centers": bare.centers, "band_total": bare.L_band_total - treated.L_band_total,
           "band_broadband": bare.L_bb - treated.L_bb,
           "dBA": bare.totals["average"]["total"]["dBA"] - treated.totals["average"]["total"]["dBA"]}
    if bare.f_m.shape == treated.f_m.shape and np.allclose(bare.f_m, treated.f_m):
        out["f_m"], out["tone"] = bare.f_m, bare.L_tone - treated.L_tone
    return out


__all__ = ["Project", "Propeller", "Fuselage", "CabinConfig", "Options", "Results", "Sidewall", "Opening",
           "Surface", "Mission", "Segment", "run_case", "run_mission", "insertion_loss", "noise_reduction",
           "reverberant_noise_reduction"]
