"""Input tabs for the paper pipeline: Mission, Propeller, Fuselage, Sidewall, Openings, Cabin, Analysis."""
from __future__ import annotations

import numpy as np
from PySide6.QtCore import Signal
from PySide6.QtWidgets import (QComboBox, QFileDialog, QHBoxLayout, QLabel, QLineEdit, QPushButton, QVBoxLayout,
                               QWidget)

from ..core import cabin as cab
from ..core.atmosphere import air, cabin_air, isa
from ..core.io import load_library, load_measured_csv
from ..core.materials import ALPHA_OCTAVES, Opening, Surface
from ..core.mission import KT, Segment, flight_mach
from ..core.sea import tau_mass_law_diffuse
from .widgets import DataclassForm, F, ListTable


class Tab(QWidget):
    changed = Signal()

    def __init__(self):
        super().__init__()
        self.project = None
        self.v = QVBoxLayout(self)

    def emit(self):
        self.update_readout()
        self.changed.emit()

    def update_readout(self):
        pass


def _ref(text: str) -> QLabel:
    lab = QLabel(text)
    lab.setWordWrap(True)
    lab.setStyleSheet("color: #4a5763")
    return lab


# ---- Mission ------------------------------------------------------------------------
class MissionTab(Tab):
    def __init__(self):
        super().__init__()
        cols = [F("name", "Name", kind="text"), F("altitude", "Altitude", "m"), F("mach", "Mach"),
                F("kcas", "CAS override", "kt", tip="calibrated airspeed; > 0 sets the Mach (compressible, ISA)"),
                F("rpm", "RPM"), F("shaft_power", "Shaft power", "kW", scale=1e-3), F("eta_p", "eta_p", tip="propeller efficiency, thrust = eta_p P / V; typical cruise value 0.80 (Raymer, Aircraft Design; Anderson, Aircraft Performance and Design). Thrust enters the tones only off the propeller plane (axial offset)"),
                F("thrust", "Thrust override", "N", tip="> 0 overrides eta_p P / V; required when static"),
                F("oat", "OAT override", "K", tip="measured outside air temperature; 0 = ISA")]
        self.table = ListTable(cols, Segment)
        self.table.changed.connect(self._segments_changed)
        self.v.addWidget(QLabel("Mission segments (power per engine)"))
        self.v.addWidget(self.table)
        h = QHBoxLayout()
        h.addWidget(QLabel("Active segment"))
        self.active = QComboBox()
        self.active.currentIndexChanged.connect(self._active)
        h.addWidget(self.active)
        h.addStretch()
        self.v.addLayout(h)
        self.readout = QLabel()
        self.readout.setWordWrap(True)
        self.v.addWidget(self.readout)
        self.v.addStretch()

    def load(self, p):
        self.project = p
        self.table.set_items(p.mission.segments)
        self._fill_active()
        self.update_readout()

    def _fill_active(self):
        m = self.project.mission
        self.active.blockSignals(True)
        self.active.clear()
        self.active.addItems([s.name for s in m.segments])
        self.active.setCurrentIndex(min(m.active, len(m.segments) - 1))
        self.active.blockSignals(False)

    def _segments_changed(self):
        self._fill_active()
        self.emit()

    def _active(self, i):
        if self.project and i >= 0:
            self.project.mission.active = i
            self.emit()

    def update_readout(self):
        if not self.project or not self.project.mission.segments:
            return
        s = self.project.mission.active_segment()
        try:
            a = isa(s.altitude)
        except ValueError as e:
            self.readout.setText(str(e))
            return
        if s.oat > 0:                                   # same atmosphere as operating_point
            a = air(s.oat, a.p)
        M = flight_mach(s, a)
        V = M * a.c
        self.readout.setText(f"At {s.altitude:.0f} m ({s.altitude / 0.3048:.0f} ft): rho = {a.rho:.4f} kg/m3, "
                             f"c = {a.c:.1f} m/s, Mach {M:.3f}" + (f" (from {s.kcas:g} KCAS)" if s.kcas > 0 else "")
                             + f", V = {V:.1f} m/s ({V / KT:.0f} KTAS), q = {0.5 * a.rho * V * V / 1000:.2f} kPa")


# ---- Propeller ----------------------------------------------------------------------
class PropellerTab(Tab):
    def __init__(self):
        super().__init__()
        self.v.addWidget(_ref("Gutin's formula (Gutin 1936; NASA RP-1258 vol. 1 ch. 1): loading noise of B blades with "
                              "the thrust and torque at an effective radius, evaluated at the fuselage point nearest "
                              "the propeller. One propeller per side; two engines add 3 dB."))
        self.form = DataclassForm([
            F("blades", "Blade count B", kind="int", lo=1, hi=12),
            F("tip_radius", "Tip radius R_t", "m", lo=0.1, hi=5),
            F("clearance", "Tip clearance h_c", "m", lo=0.01, hi=5),
            F("axial_offset", "Fuselage point ahead of the prop plane", "m", lo=-10, hi=10),
            F("engines", "Engines", kind="choice", choices=[1, 2]),
            F("n_harmonics", "Harmonics N", kind="int", lo=0, hi=200,
              tip="0 = auto: every harmonic up to the top analysis band (Analysis tab)"),
            F("re_fraction", "Effective radius R_e / R_t", lo=0.3, hi=1.0),
            F("source_mode", "Exterior level", kind="choice", choices=["generated", "measured"],
              tip="generated: Gutin; measured: free-field exterior levels from a CSV"),
        ])
        self.form.changed.connect(self.emit)
        self.v.addWidget(self.form)
        h = QHBoxLayout()
        b = QPushButton("Load measured exterior levels (CSV: harmonic, dB)...")
        b.clicked.connect(self._load_csv)
        h.addWidget(b)
        self.meas = QLabel()
        h.addWidget(self.meas)
        h.addStretch()
        self.v.addLayout(h)
        self.readout = QLabel()
        self.v.addWidget(self.readout)
        self.v.addStretch()

    def load(self, p):
        self.project = p
        self.form.set_object(p.propeller)
        self.update_readout()

    def _load_csv(self):
        fn, _ = QFileDialog.getOpenFileName(self, "Measured exterior levels", "", "CSV (*.csv)")
        if fn:
            self.project.propeller.measured = load_measured_csv(fn)
            self.emit()

    def update_readout(self):
        if not self.project:
            return
        pr, s = self.project.propeller, self.project.mission.active_segment()
        n = len(pr.measured)
        self.meas.setText(f"{n} measured harmonics loaded" if n else "none loaded")
        try:
            a = isa(s.altitude)
        except ValueError:
            return
        if s.oat > 0:
            a = air(s.oat, a.p)
        om = 2 * np.pi * s.rpm / 60
        self.readout.setText(f"BPF = {pr.blades * s.rpm / 60:.1f} Hz, rotational tip Mach = {om * pr.tip_radius / a.c:.3f}, "
                             f"observer distance = {np.hypot(pr.axial_offset, pr.tip_radius + pr.clearance):.2f} m")


# ---- Fuselage -----------------------------------------------------------------------
class FuselageTab(Tab):
    def __init__(self):
        super().__init__()
        self.form = DataclassForm([
            F("nose_to_station", "Nose to prop-plane station (boundary layer)", "m", lo=0.1, hi=50),
            F("side_area", "Sidewall area, one side (tones)", "m2", lo=0.1, hi=1000),
            F("tbl_area", "Sidewall area exposed to the boundary layer", "m2", lo=0.1, hi=2000),
        ])
        self.form.changed.connect(self.emit)
        self.v.addWidget(self.form)
        self.v.addWidget(_ref("Boundary layer: Goody (2004) wall spectrum, 1/7-power flat-plate layer; the wall "
                              "pressure is converted to the equivalent diffuse field, <p^2> = <p_wall^2> / 2 "
                              "(Waterhouse 1955; CR-3813 p. 23)."))
        self.v.addStretch()

    def load(self, p):
        self.project = p
        self.form.set_object(p.fuselage)


# ---- Sidewall -----------------------------------------------------------------------
class SidewallTab(Tab):
    def __init__(self):
        super().__init__()
        self.v.addWidget(_ref("NASA CR-132602 (Wilby & Scharton 1975) sec. 5, non-resonant model: skin and trim are "
                              "mass-law walls (eq. 46), the cavity between them absorbs (eqs. 51-52), the blanket mass "
                              "is added to the trim (sec. 6.2). NR by eq. (52); a single wall uses 10 log(1 + A / S tau). "
                              "The report states the model is not valid well below half the ring frequency."))
        self.form = DataclassForm([
            F("skin_thickness", "Skin thickness", "mm", scale=1e3, lo=0.1, hi=20),
            F("skin_density", "Skin density", "kg/m3", lo=100, hi=20000),
            F("skin_added_mass", "Smeared stiffeners / doublers", "kg/m2", lo=0, hi=100),
            F("double_wall", "Double wall (trim present)", kind="bool"),
            F("trim_mass", "Trim surface mass", "kg/m2", lo=0, hi=100),
            F("blanket_mass", "Blanket surface mass", "kg/m2", lo=0, hi=100),
            F("cavity_depth", "Cavity depth (skin to trim)", "mm", scale=1e3, lo=1, hi=1000),
        ] + [F(f"cavity_alpha.{i}", f"Cavity alpha {int(f)} Hz", lo=0, hi=1,
               tip="default: CR-132602 sec. 6.2 table (fiberglass-filled cavity)")
             for i, f in enumerate(ALPHA_OCTAVES)])
        self.form.changed.connect(self.emit)
        self.v.addWidget(self.form)
        self.readout = QLabel()
        self.v.addWidget(self.readout)
        self.v.addStretch()

    def load(self, p):
        self.project = p
        self.form.set_object(p.sidewall)
        self.update_readout()

    def update_readout(self):
        p = self.project
        if not p:
            return
        sw = p.sidewall
        air = cabin_air(p.cabin.cabin_altitude, p.cabin.temperature)
        tl = lambda m: -10 * np.log10(tau_mass_law_diffuse(np.array([125.0, 500.0, 2000.0]), m, air.rho_c))  # noqa: E731
        txt = f"Skin {sw.m_skin:.2f} kg/m2, TL(eq. 46) 125/500/2k = " + " / ".join(f"{x:.1f}" for x in tl(sw.m_skin))
        if sw.double_wall:
            txt += (f"   |   trim + blanket {sw.m_trim:.2f} kg/m2, TL = " + " / ".join(f"{x:.1f}" for x in tl(sw.m_trim))
                    + f"   |   cavity cross-mode c/2L = {air.c / (2 * sw.cavity_depth):.0f} Hz")
        self.readout.setText(txt + " dB")


# ---- Openings -----------------------------------------------------------------------
class OpeningsTab(Tab):
    def __init__(self):
        super().__init__()
        self.v.addWidget(_ref("Windows / doors inside the exposed sidewall, combined by area-weighted transmission "
                              "(TM-85722 eq. 1). Mode 'mass': one pane of the summed surface mass (TM-85722 p. 17), "
                              "mass law eq. (46); mode 'tl': a TL table."))
        cols = [F("name", "Name", kind="text"), F("area", "Area", "m2"),
                F("mode", "TL from", kind="choice", choices=["mass", "tl"]), F("mass", "Pane mass", "kg/m2")]
        self.table = ListTable(cols, Opening)
        self.table.changed.connect(self.emit)
        self.table.selection.connect(self._select)
        self.v.addWidget(self.table)
        th = QHBoxLayout()
        th.addWidget(QLabel("TL table of the selected opening (mode 'tl'): f:TL; f:TL; ..."))
        self.tl_edit = QLineEdit()
        self.tl_edit.editingFinished.connect(self._tl_edit)
        th.addWidget(self.tl_edit)
        self.v.addLayout(th)
        self.v.addStretch()
        self.sel = -1

    def load(self, p):
        self.project = p
        self.table.set_items(p.openings)
        self._select(0 if p.openings else -1)

    def _select(self, r):
        self.sel = r
        if 0 <= r < len(self.project.openings):
            o = self.project.openings[r]
            self.tl_edit.setText("; ".join(f"{f:g}:{t:g}" for f, t in zip(o.tl_freqs, o.tl_values)))

    def _tl_edit(self):
        if not (0 <= self.sel < len(self.project.openings)):
            return
        try:
            pairs = [x.split(":") for x in self.tl_edit.text().split(";") if x.strip()]
            fr, tl = zip(*[(float(a), float(b)) for a, b in pairs]) if pairs else ((), ())
        except ValueError:
            return
        o = self.project.openings[self.sel]
        o.tl_freqs, o.tl_values = list(fr), list(tl)
        self.emit()


# ---- Cabin --------------------------------------------------------------------------
class CabinTab(Tab):
    def __init__(self):
        super().__init__()
        self.form = DataclassForm([
            F("Lx", "Cabin length L_x", "m", lo=0.5, hi=60), F("Ly", "Width L_y", "m", lo=0.5, hi=10),
            F("Lz", "Height L_z", "m", lo=0.5, hi=5),
            F("cabin_altitude", "Cabin pressure altitude", "m", lo=0, hi=5000,
              tip="default 2438 m (8000 ft), the usual cruise cabin altitude"),
            F("temperature", "Cabin temperature", "K", lo=250, hi=320, tip="default 293.15 K (20 C)"),
            F("volume", "Volume override (0 = box)", "m3", lo=0, hi=1000),
        ])
        self.form.changed.connect(self.emit)
        self.v.addWidget(self.form)
        th = QHBoxLayout()
        th.addWidget(QLabel("Measured T60 (replaces the surfaces), f:T60; ..."))
        self.t60_edit = QLineEdit()
        self.t60_edit.editingFinished.connect(self._t60_edit)
        th.addWidget(self.t60_edit)
        self.v.addLayout(th)
        self.lib = load_library()
        scols = [F("name", "Surface", kind="text"), F("area", "Area", "m2")] + \
                [F(f"alpha.{i}", f"a {int(f)}" if f < 1000 else f"a {int(f / 1000)}k") for i, f in enumerate(ALPHA_OCTAVES)]
        self.surfaces = ListTable(scols, Surface)
        self.surfaces.changed.connect(self.emit)
        self.v.addWidget(QLabel("Absorbing surfaces (Sabine A = sum S alpha; octave alpha, interpolated)"))
        self.v.addWidget(self.surfaces)
        h = QHBoxLayout()
        self.libbox = QComboBox()
        self.libbox.addItems([s["name"] for s in self.lib["surfaces"]])
        b = QPushButton("Add from library")
        b.clicked.connect(self._add_lib)
        h.addWidget(self.libbox)
        h.addWidget(b)
        h.addStretch()
        self.v.addLayout(h)
        self.readout = QLabel()
        self.v.addWidget(self.readout)

    def _add_lib(self):
        d = next(s for s in self.lib["surfaces"] if s["name"] == self.libbox.currentText())
        self.project.cabin.surfaces.append(Surface(name=d["name"], area=1.0, alpha=list(d["alpha"])))
        self.surfaces.refresh()
        self.emit()

    def _t60_edit(self):
        try:
            pairs = [x.split(":") for x in self.t60_edit.text().split(";") if x.strip()]
            rows = [[float(a), float(b)] for a, b in pairs]
        except ValueError:
            return
        self.project.cabin.t60_measured = rows
        self.emit()

    def load(self, p):
        self.project = p
        self.form.set_object(p.cabin)
        self.t60_edit.setText("; ".join(f"{f:g}:{t:g}" for f, t in p.cabin.t60_measured))
        self.surfaces.set_items(p.cabin.surfaces)
        self.update_readout()

    def update_readout(self):
        c = self.project.cabin if self.project else None
        if not c or not (c.surfaces or c.t60_measured):
            return
        V = c.cabin_volume()
        A = c.absorption([125.0, 500.0, 1000.0, 2000.0])
        T = cab.t60(V, A)
        fs = cab.schroeder_frequency(float(np.mean(T[1:3])), V)
        self.readout.setText(f"V = {V:.1f} m3; A(125/500/1k/2k) = " + " / ".join(f"{a:.1f}" for a in A)
                             + " m2; T60 = " + " / ".join(f"{t:.2f}" for t in T) + f" s; Schroeder f_s = {fs:.0f} Hz")


# ---- Analysis -----------------------------------------------------------------------
class AnalysisTab(Tab):
    def __init__(self):
        super().__init__()
        self.form = DataclassForm([
            F("f_min", "Lowest band centre", "Hz", lo=10, hi=20000, tip="1/3-octave analysis range"),
            F("f_max", "Highest band centre", "Hz", lo=20, hi=20000),
            F("seat_percentile", "Max-seat percentile", "%", lo=50, hi=99.9, decimals=1,
              tip="'max seat' = this percentile of the seats (Schroeder statistic); default 95"),
        ])
        self.form.changed.connect(self.emit)
        self.v.addWidget(self.form)
        self.v.addWidget(_ref("The equations' own constants (Goody's coefficients, the 1/7-power boundary layer, "
                              "the Waterhouse factor 2, Sabine's 0.161, ISA, IEC A / C weighting) are fixed by the "
                              "papers and listed in METHOD.md sec. 5; they are not inputs."))
        self.readout = QLabel()
        self.v.addWidget(self.readout)
        self.v.addStretch()

    def load(self, p):
        self.project = p
        self.form.set_object(p.options)
        self.update_readout()

    def update_readout(self):
        if self.project:
            o = self.project.options
            try:
                self.readout.setText(f"Max seat = room average + {cab.seat_stat_db(o.seat_percentile):.2f} dB")
            except ValueError as e:
                self.readout.setText(str(e))
