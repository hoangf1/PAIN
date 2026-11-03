"""run_case(project) -> Results: the whole calculation of plan section 2 for one segment."""
from __future__ import annotations

from dataclasses import dataclass, field, replace

import numpy as np

from . import cabin as cab
from . import seats as st
from . import tmm
from .atmosphere import Air, cabin_air
from .frequencies import band_edges, band_index, harmonic_frequencies, third_octave_centers
from .materials import AirGap, Opening, Panel, PorousLayer, PorousTable, Surface
from .mission import Mission, Segment, operating_point
from .scattering import surface_factor
from .source_tbl import boundary_layer, wall_band_pressure2
from .source_tonal import rotor_harmonics
from .blade import BladeGeometry, scaled_strip_loads, strip_harmonics
from .weighting import db, energetic_sum, p2_from_db, totals

TWIN_MODES = ("energetic", "coherent", "worst")


@dataclass
class Propeller:
    blades: int = 4
    tip_radius: float = 1.3          # m
    clearance: float = 0.5           # tip-to-fuselage clearance h_c, m
    axial_offset: float = 0.0        # patch centre minus prop plane, aircraft x (forward +), m
    engines: int = 2                 # 1 or 2 (twin: one prop each side)
    rotation: int = 1                # +1 / -1 rotation sense seen from behind
    synchrophase_deg: float = 0.0    # far prop blade phase lead, deg
    twin_combination: str = "energetic"
    n_harmonics: int = 8
    re_fraction: float = 0.8         # R_e / R_t
    k_refr: float = 0.0              # boundary-layer refraction, dB (stated input 0..5)
    patch_mode: int = 1              # 1, 5 or 0 (= grid of grid_nx x grid_nz patches)
    source_mode: str = "generated"   # "generated" | "measured"
    measured: list = field(default_factory=list)   # [[m, L_inc dB], ...]
    source_model: str = "point"      # "point": one radius R_e (Gutin); "blade": BEMT strips (needs blade)
    blade: dict = field(default_factory=dict)     # BladeGeometry fields (r_over_R, c_over_R, beta_deg, ...)
    blade_scale: bool = True         # scale strip loads to the operating point's thrust and torque
    measured_ref: list = field(default_factory=list)  # [x, y, z] hub-relative point the measured levels
                                                       # belong to; then the source model gives the spatial shape


@dataclass
class Fuselage:
    radius: float = 1.0              # m
    nose_to_station: float = 4.0     # nose to prop-plane station (TBL length), m
    sidewall_area: float = 30.0      # total sidewall area incl. openings, m^2
    patch_width: float = 1.5         # prop-plane patch axial extent, m
    patch_height: float = 1.0        # prop-plane patch circumferential extent, m
    patch_x_cabin: float = 3.0       # patch centre, cabin x (from forward cabin wall), m
    patch_z_cabin: float = 1.1       # patch centre, cabin z (from floor), m
    grid_nx: int = 30                # patch grid (patch mode 0): axial count; 30 x 15 is within
    grid_nz: int = 15                # ~1 dB of 48 x 24 on the default case (tau(theta) is sharp)


@dataclass
class CabinConfig:
    Lx: float = 8.0
    Ly: float = 1.9
    Lz: float = 1.8
    cabin_altitude: float = 2438.4   # m (cabin pressure altitude)
    temperature: float = 293.15      # K
    surfaces: list = field(default_factory=list)
    seats: list = field(default_factory=list)       # [[x, y, z], ...]
    volume: float = 0.0              # m^3; 0 = box volume Lx*Ly*Lz
    t60_measured: list = field(default_factory=list)  # [[f, T60], ...]; if set, A = 0.161 V / T60

    def cabin_volume(self) -> float:
        return self.volume if self.volume > 0 else self.Lx * self.Ly * self.Lz

    def absorption(self, f) -> np.ndarray:
        """A(f): from measured T60 (log-log interpolation, end values held) or from the surfaces."""
        f = np.atleast_1d(np.asarray(f, dtype=float))
        if self.t60_measured:
            tf, tt = np.array(sorted(self.t60_measured), dtype=float).T
            T60 = np.exp(np.interp(np.log(f), np.log(tf), np.log(tt)))
            return 0.161 * self.cabin_volume() / T60
        return cab.absorption_area(self.surfaces, f)


@dataclass
class Options:
    f_min: float = 50.0
    f_max: float = 5000.0
    n_theta: int = 60
    n_sub: int = 10
    n_tau: int = 2048


@dataclass
class Project:
    name: str = "Untitled"
    mission: Mission = field(default_factory=Mission)
    propeller: Propeller = field(default_factory=Propeller)
    fuselage: Fuselage = field(default_factory=Fuselage)
    sidewall: list = field(default_factory=list)
    openings: list = field(default_factory=list)
    cabin: CabinConfig = field(default_factory=CabinConfig)
    options: Options = field(default_factory=Options)


@dataclass
class Patch:
    pos: np.ndarray          # relative to near hub, aircraft axes
    area: float
    theta: float             # incidence angle on the patch, rad
    phi_far: float           # surface angle from the far prop's lit point, rad
    far_pos: np.ndarray      # relative to far hub


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
    helical_mach: float
    f_m: np.ndarray
    patches: list
    L_inc: np.ndarray            # (patches, m) combined incident level used, dB
    L_inc_modes: dict            # twin mode -> (patches, m)
    L_inc_near: np.ndarray
    L_inc_far: np.ndarray
    tl_tone: np.ndarray          # (patches, m) composite TL at the patch angle, dB
    centers: np.ndarray
    L_wall: np.ndarray           # Goody band wall level, dB
    tl_band: np.ndarray          # composite diffuse band TL, dB
    tl_wall_band: np.ndarray     # sidewall stack only
    tl_curve_f: np.ndarray
    tl_curve: np.ndarray
    mass_law: np.ndarray
    markers: dict                # f0, f_r, f_c (Hz)
    A_band: np.ndarray
    T60_band: np.ndarray
    f_s: float
    L_tone: np.ndarray           # interior average per harmonic, dB
    L_bb: np.ndarray             # interior average broadband per band, dB
    L_band_tonal: np.ndarray
    L_band_total: np.ndarray
    seat_tone: np.ndarray        # (seats, m) dB
    seat_band_total: np.ndarray  # (seats, bands) dB
    seat_band_tonal: np.ndarray
    seat_band_bb: np.ndarray
    totals: dict                 # "average"/"max_seat" -> "tonal"/"broadband"/"total" -> metrics
    max_seat: int
    warnings: list


def _patches(pr: Propeller, fu: Fuselage) -> list[Patch]:
    Rt, hc, Rf = pr.tip_radius, pr.clearance, fu.radius
    y_ax = -(Rt + hc + Rf)
    far_hub = np.array([0.0, 2.0 * y_ax, 0.0])
    area = fu.patch_width * fu.patch_height
    if pr.patch_mode == 1:
        offs = [(0.0, 0.0)]
    elif pr.patch_mode == 5:
        a, s = fu.patch_width / 3.0, fu.patch_height / 3.0
        offs = [(0.0, 0.0), (a, 0.0), (-a, 0.0), (0.0, s), (0.0, -s)]
    elif pr.patch_mode == 0:
        ax = (np.arange(fu.grid_nx) + 0.5) / fu.grid_nx * fu.patch_width - fu.patch_width / 2
        arc = (np.arange(fu.grid_nz) + 0.5) / fu.grid_nz * fu.patch_height - fu.patch_height / 2
        offs = [(a, s) for a in ax for s in arc]
    else:
        raise ValueError("patch mode must be 1, 5 or 0 (grid)")
    out = []
    for ax, arc in offs:
        al = arc / Rf
        pos = np.array([pr.axial_offset + ax, y_ax + Rf * np.cos(al), Rf * np.sin(al)])
        n_out = np.array([0.0, np.cos(al), np.sin(al)])
        d = pos / np.linalg.norm(pos)
        theta = float(np.arccos(np.clip(-d @ n_out, -1.0, 1.0)))
        if theta >= np.pi / 2:
            raise ValueError("patch faces away from the propeller")
        out.append(Patch(pos, area / len(offs), theta, np.pi - abs(al), pos - far_hub))
    return out


def _tau_openings(openings, f, theta, air, R) -> list:
    out = []
    for o in openings:
        if o.mode == "layers":
            out.append(tmm.tau(o.layers, f, theta, air, R))
        else:
            out.append(o.tau_table(f) * np.ones_like(np.asarray(f, dtype=float)))
    return out


def _composite_tau(proj: Project, f, theta, air, diffuse=False):
    R = proj.fuselage.radius
    S_open = sum(o.area for o in proj.openings)
    S_wall = proj.fuselage.sidewall_area - S_open
    if S_wall <= 0:
        raise ValueError("openings area exceeds the sidewall area")
    if diffuse:
        o = proj.options
        t_wall = tmm.tau_band(proj.sidewall, f, air, R, o.n_theta, o.n_sub)
        t_open = []
        for op in proj.openings:
            if op.mode == "layers":
                t_open.append(tmm.tau_band(op.layers, f, air, R, o.n_theta, o.n_sub))
            else:
                t_open.append(op.tau_table(f))
    else:
        t_wall = tmm.tau(proj.sidewall, f, theta, air, R)
        t_open = _tau_openings(proj.openings, f, theta, air, R)
    return tmm.composite([t_wall] + t_open, [S_wall] + [o.area for o in proj.openings]), t_wall


def _markers(proj: Project, air: Air) -> dict:
    panels = [l for l in proj.sidewall if isinstance(l, Panel)]
    mk = {"f_c": [p.coincidence(air.c) for p in panels]}
    curved = [p for p in panels if p.curved]
    if curved:
        mk["f_r"] = curved[0].ring_frequency(proj.fuselage.radius)
    bays = [p.bay_frequency() for p in panels if p.bay_frequency() > 0]
    if bays:
        mk["f_11"] = bays[0]
    if len(panels) >= 2:
        i0 = proj.sidewall.index(panels[0])
        i1 = proj.sidewall.index(panels[-1])
        d = sum(l.d for l in proj.sidewall[i0 + 1:i1] if isinstance(l, (AirGap, PorousLayer, PorousTable)))
        if d > 0:
            mk["f0"] = tmm.mass_air_mass_f0(panels[0].mass, panels[-1].mass, d, air)
    return mk


def run_case(proj: Project, segment: int | None = None, patch_mode: int | None = None) -> Results:
    warn: list[str] = []
    seg: Segment = proj.mission.segments[segment] if segment is not None else proj.mission.active_segment()
    pr = proj.propeller if patch_mode is None else replace(proj.propeller, patch_mode=patch_mode)
    fu, cb, opt = proj.fuselage, proj.cabin, proj.options
    op = operating_point(seg)
    ext = op.atm
    air = cabin_air(cb.cabin_altitude, cb.temperature)
    R_e = pr.re_fraction * pr.tip_radius
    f_m = harmonic_frequencies(pr.blades, seg.rpm, pr.n_harmonics)
    m_idx = np.arange(1, pr.n_harmonics + 1)
    centers = third_octave_centers(opt.f_min, opt.f_max)
    patches = _patches(pr, fu)

    # ---- [1] exterior tonal source ------------------------------------------------
    nP = len(patches)
    if pr.source_mode == "measured" and not pr.measured_ref:
        meas = {int(r[0]): float(r[1]) for r in pr.measured}
        missing = [m for m in m_idx if m not in meas]
        if missing:
            raise ValueError(f"measured source levels missing for harmonics {missing}")
        L = np.array([meas[m] for m in m_idx])
        L_used = np.tile(L, (nP, 1))
        modes = {k: L_used for k in TWIN_MODES}
        L_near, L_far = L_used, np.full_like(L_used, -np.inf)
    else:
        if pr.source_model == "blade":
            if not pr.blade:
                raise ValueError("blade source model selected but no blade geometry is loaded")
            lk = dict(blades=pr.blades, R=pr.tip_radius, omega=op.omega, V=op.V, rho=ext.rho, c=ext.c)
            if pr.blade_scale:
                strips = scaled_strip_loads(BladeGeometry(**pr.blade), thrust=op.thrust, torque=op.torque, **lk)
            else:
                strips = scaled_strip_loads(BladeGeometry(**pr.blade), **lk)
            hk = dict(blades=pr.blades, omega=op.omega, V=op.V, c=ext.c, n_harmonics=pr.n_harmonics,
                      rotation=pr.rotation, n_tau=opt.n_tau)
            source = lambda obs: strip_harmonics(obs, *strips, **hk)  # noqa: E731
        elif pr.source_model == "point":
            kw = dict(blades=pr.blades, R_e=R_e, omega=op.omega, V=op.V, c=ext.c, thrust=op.thrust,
                      torque=op.torque, n_harmonics=pr.n_harmonics, rotation=pr.rotation, n_tau=opt.n_tau)
            source = lambda obs: rotor_harmonics(obs, **kw)  # noqa: E731
        else:
            raise ValueError("source model must be 'point' or 'blade'")
        gain = 10.0 ** (pr.k_refr / 20.0)
        if pr.source_mode == "measured":
            # measured incident levels at measured_ref; the source model only supplies the shape
            meas = {int(r[0]): float(r[1]) for r in pr.measured}
            missing = [m for m in m_idx if m not in meas]
            if missing:
                raise ValueError(f"measured source levels missing for harmonics {missing}")
            L_ref = db(np.abs(source(np.asarray(pr.measured_ref, dtype=float))) ** 2)
            gain = 10.0 ** ((np.array([meas[m] for m in m_idx]) - L_ref) / 20.0)
        P_near = np.array([source(p.pos) for p in patches]) * gain
        if pr.engines == 2:
            ka = 2.0 * np.pi * f_m / ext.c * fu.radius
            P_far = np.array([source(p.far_pos) * surface_factor(ka, p.phi_far) / 2.0
                              for p in patches]) * gain
        elif pr.engines == 1:
            P_far = np.zeros_like(P_near)
        else:
            raise ValueError("engine count must be 1 or 2")
        ph = np.exp(1j * m_idx * np.radians(pr.synchrophase_deg))
        p2 = {
            "energetic": np.abs(P_near) ** 2 + np.abs(P_far) ** 2,
            "coherent": np.abs(P_near + P_far * ph[None, :]) ** 2,
            "worst": (np.abs(P_near) + np.abs(P_far)) ** 2,
        }
        if pr.twin_combination not in p2:
            raise ValueError(f"twin combination must be one of {TWIN_MODES}")
        modes = {k: db(v) for k, v in p2.items()}
        L_used = modes[pr.twin_combination]
        L_near, L_far = db(np.abs(P_near) ** 2), db(np.abs(P_far) ** 2)

    # ---- [2] sidewall TL ----------------------------------------------------------
    tau_tone = np.array([_composite_tau(proj, f_m, p.theta, air)[0] for p in patches])
    tau_bb, tau_wall_bb = _composite_tau(proj, centers, None, air, diffuse=True)
    f_curve = np.geomspace(20.0, 10000.0, 240)
    tl_curve = tmm.tl(tmm.tau_diffuse(proj.sidewall, f_curve, air, fu.radius, opt.n_theta))
    m_tot = sum(l.mass for l in proj.sidewall if isinstance(l, Panel))
    mass_law = 20.0 * np.log10(m_tot * f_curve) - 47.0

    # ---- [3] cabin absorption -----------------------------------------------------
    box = st.Box(cb.Lx, cb.Ly, cb.Lz)
    vol = cb.cabin_volume()
    A_band = cb.absorption(centers)
    A_tone = cb.absorption(f_m)
    T60_band = cab.t60(vol, A_band)
    T60_mid = float(np.mean(cab.t60(vol, cb.absorption([500.0, 1000.0]))))
    f_s = cab.schroeder_frequency(T60_mid, vol)

    # ---- [4] interior level -------------------------------------------------------
    p_inc2 = p2_from_db(L_used)                                     # (patches, m)
    areas = np.array([p.area for p in patches])[:, None]
    cosv = np.cos([p.theta for p in patches])[:, None]
    W_tone = np.sum(areas * tau_tone * p_inc2 * cosv, axis=0) / air.rho_c
    L_tone = db(cab.interior_p2(W_tone, A_tone, air))

    bl = boundary_layer(ext, op.V, fu.nose_to_station) if op.V > 0 else None
    if bl is None:
        warn.append("static segment: no TBL source")
        p_wall2 = np.zeros_like(centers)
    else:
        p_wall2 = wall_band_pressure2(centers, bl)
    # Wall (blocked) mean square of a diffuse field is twice the field mean square (Waterhouse 1955;
    # CR-3813 p. 23: <p_e^2> = <p_bl^2>/2); incident intensity of that field is <p_e^2>/(4 rho c).
    W_bb = fu.sidewall_area * tau_bb * (p_wall2 / 2.0) / (4.0 * air.rho_c)
    p_bb2 = cab.interior_p2(W_bb, A_band, air)
    L_bb = db(p_bb2)

    for lay in list(proj.sidewall) + [l for o in proj.openings for l in o.layers]:
        if isinstance(lay, PorousLayer):
            X = air.rho * np.array([centers[0], centers[-1]]) / lay.sigma
            if X[0] < 0.01 or X[1] > 1.0:
                warn.append(f"Delany-Bazley layer '{lay.name}' used outside 0.01 <= rho f / sigma <= 1 "
                            f"({X[0]:.3g}-{X[1]:.3g})")
    bi = band_index(f_m, centers)
    if np.any(bi < 0):
        warn.append(f"harmonics outside {opt.f_min:g}-{opt.f_max:g} Hz are left out of the band totals: "
                    + ", ".join(f"{f:.0f} Hz" for f in f_m[bi < 0]))
    p_tone_band = np.zeros_like(centers)
    for i, b in enumerate(bi):
        if b >= 0:
            p_tone_band[b] += p2_from_db(L_tone[i])
    L_band_tonal = db(p_tone_band)
    L_band_total = db(p_tone_band + p_bb2)

    # ---- seats ------------------------------------------------------------------
    seats = np.atleast_2d(np.asarray(cb.seats if cb.seats else [[cb.Lx / 2, cb.Ly / 2, 1.1]], dtype=float))
    patch = st.SidewallPatch(fu.patch_x_cabin, fu.patch_width, fu.patch_z_cabin, fu.patch_height)
    T60f = lambda f: cab.t60(vol, cb.absorption([f]))[0]  # noqa: E731
    off_tone = st.seat_offsets(f_m, f_s, seats, box, air.c, T60f, patch)
    lo, hi = band_edges(centers)
    off_band = st.seat_offsets(centers, f_s, seats, box, air.c, T60f, patch, n_band=5, band_lo=lo, band_hi=hi)
    seat_tone = L_tone[None, :] + off_tone
    p_seat_tone_band = np.zeros((seats.shape[0], centers.size))
    for i, b in enumerate(bi):
        if b >= 0:
            p_seat_tone_band[:, b] += p2_from_db(seat_tone[:, i])
    seat_band_tonal = db(p_seat_tone_band)
    seat_band_bb = L_bb[None, :] + off_band
    seat_band_total = db(p_seat_tone_band + p2_from_db(seat_band_bb))

    tot_avg = {"tonal": totals(L_band_tonal, centers), "broadband": totals(L_bb, centers),
               "total": totals(L_band_total, centers)}
    seat_dBA = np.array([totals(s, centers)["dBA"] for s in seat_band_total])
    k = int(np.argmax(seat_dBA))
    tot_max = {"tonal": totals(seat_band_tonal[k], centers), "broadband": totals(seat_band_bb[k], centers),
               "total": totals(seat_band_total[k], centers)}

    return Results(
        segment=seg.name, atm=ext, cabin_air=air, V=op.V, thrust=op.thrust, torque=op.torque,
        bpf=float(f_m[0]), tip_mach=op.omega * pr.tip_radius / ext.c,
        helical_mach=float(np.hypot(op.V, op.omega * pr.tip_radius) / ext.c),
        f_m=f_m, patches=patches, L_inc=L_used, L_inc_modes=modes, L_inc_near=L_near, L_inc_far=L_far,
        tl_tone=tmm.tl(tau_tone), centers=centers, L_wall=db(p_wall2), tl_band=tmm.tl(tau_bb),
        tl_wall_band=tmm.tl(tau_wall_bb), tl_curve_f=f_curve, tl_curve=tl_curve, mass_law=mass_law,
        markers=_markers(proj, air), A_band=A_band, T60_band=T60_band, f_s=f_s, L_tone=L_tone, L_bb=L_bb,
        L_band_tonal=L_band_tonal, L_band_total=L_band_total, seat_tone=seat_tone,
        seat_band_total=seat_band_total, seat_band_tonal=seat_band_tonal, seat_band_bb=seat_band_bb,
        totals={"average": tot_avg, "max_seat": tot_max}, max_seat=k, warnings=warn)


def reverberant_noise_reduction(proj: Project) -> dict:
    """Space-average NR of the cabin in a diffuse exterior field (no propeller, no TBL).

    Exterior incident intensity p_e^2/(4 rho c) on every transmitting surface, room equation
    inside: p_i^2 = 4 rho c W / A with W = sum S_i tau_i p_e^2 / (4 rho c), so
    NR = 10 log10(A / sum S_i tau_i). The exterior is the same air as the cabin.
    """
    cb, opt = proj.cabin, proj.options
    air = cabin_air(cb.cabin_altitude, cb.temperature)
    centers = third_octave_centers(opt.f_min, opt.f_max)
    tau_c, tau_wall = _composite_tau(proj, centers, None, air, diffuse=True)
    S = proj.fuselage.sidewall_area
    A = cb.absorption(centers)
    return {"centers": centers, "NR": 10.0 * np.log10(A / (S * tau_c)), "A": A,
            "tl_composite": tmm.tl(tau_c), "tl_wall": tmm.tl(tau_wall)}


def run_mission(proj: Project) -> list[Results]:
    return [run_case(proj, segment=i) for i in range(len(proj.mission.segments))]


def patch_sensitivity(proj: Project, segment: int | None = None) -> dict:
    """1- vs 5-patch dBA (plan: 1 patch is adequate if they differ by < 1 dB)."""
    r1 = run_case(proj, segment, patch_mode=1)
    r5 = run_case(proj, segment, patch_mode=5)
    a1, a5 = r1.totals["average"]["total"]["dBA"], r5.totals["average"]["total"]["dBA"]
    return {"dBA_1": a1, "dBA_5": a5, "delta": a5 - a1, "adequate": abs(a5 - a1) < 1.0}


def insertion_loss(bare: Results, treated: Results) -> dict:
    """IL = L_int,bare - L_int,treated per band (total and broadband) and per harmonic."""
    if not np.allclose(bare.centers, treated.centers):
        raise ValueError("configurations use different band grids")
    out = {"centers": bare.centers, "band_total": bare.L_band_total - treated.L_band_total,
           "band_broadband": bare.L_bb - treated.L_bb}
    if bare.f_m.shape == treated.f_m.shape and np.allclose(bare.f_m, treated.f_m):
        out["f_m"] = bare.f_m
        out["tone"] = bare.L_tone - treated.L_tone
    out["dBA"] = bare.totals["average"]["total"]["dBA"] - treated.totals["average"]["total"]["dBA"]
    return out


def tonal_refraction_band(res: Results, k_lo: float = 0.0, k_hi: float = 5.0, k_used: float = 0.0):
    """Interior tone levels for K_refr = k_lo and k_hi (levels scale 1:1 with K_refr)."""
    return res.L_tone - k_used + k_lo, res.L_tone - k_used + k_hi


__all__ = ["Project", "Propeller", "Fuselage", "CabinConfig", "Options", "Results", "run_case",
           "reverberant_noise_reduction",
           "run_mission", "patch_sensitivity", "insertion_loss", "tonal_refraction_band",
           "Panel", "PorousLayer", "AirGap", "Surface", "Opening", "Mission", "Segment", "energetic_sum"]
