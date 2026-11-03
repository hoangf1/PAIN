"""Input tabs (plan section 4): Mission, Propeller, Fuselage, Sidewall Stack, Openings, Cabin."""
from __future__ import annotations

import numpy as np
from PySide6.QtCore import Signal
from PySide6.QtWidgets import (QComboBox, QFileDialog, QGroupBox, QHBoxLayout, QLabel, QLineEdit,
                               QPushButton, QVBoxLayout, QWidget)

from ..core import cabin as cab
from ..core.atmosphere import cabin_air, isa
from ..core.io import load_library, load_measured_csv
from ..core.materials import ALPHA_OCTAVES, AirGap, Opening, Panel, PorousLayer, PorousTable, Surface
from ..core.mission import Segment
from ..core.pipeline import TWIN_MODES
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


# ---- Mission ------------------------------------------------------------------------
class MissionTab(Tab):
    def __init__(self):
        super().__init__()
        cols = [F("name", "Name", kind="text"), F("altitude", "Altitude", "m"), F("mach", "Mach"),
                F("rpm", "RPM"), F("shaft_power", "Shaft power", "kW", scale=1e-3), F("eta_p", "eta_p"),
                F("thrust", "Thrust override", "N", tip="> 0 overrides eta_p P / V; required when static")]
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
        V = s.mach * a.c
        q = 0.5 * a.rho * V * V
        Re = V * self.project.fuselage.nose_to_station / a.nu
        self.readout.setText(f"ISA at {s.altitude:.0f} m:  rho = {a.rho:.4f} kg/m3,  c = {a.c:.1f} m/s,  "
                             f"V = {V:.1f} m/s,  q = {q / 1000:.2f} kPa,  Re_x(station) = {Re:.3g}")


# ---- Propeller ----------------------------------------------------------------------
class PropellerTab(Tab):
    def __init__(self):
        super().__init__()
        self.form = DataclassForm([
            F("blades", "Blade count B", kind="int", lo=1, hi=12),
            F("tip_radius", "Tip radius R_t", "m", lo=0.1, hi=5),
            F("clearance", "Tip clearance h_c", "m", lo=0.01, hi=5),
            F("axial_offset", "Patch centre - prop plane (fwd +)", "m", lo=-10, hi=10),
            F("engines", "Engines", kind="choice", choices=[1, 2]),
            F("rotation", "Rotation sense", kind="choice", choices=[1, -1]),
            F("synchrophase_deg", "Synchrophase dphi", "deg", lo=-360, hi=360),
            F("twin_combination", "Twin combination used", kind="choice", choices=list(TWIN_MODES)),
            F("n_harmonics", "Harmonics N", kind="int", lo=1, hi=40),
            F("re_fraction", "R_e / R_t", lo=0.3, hi=1.0),
            F("k_refr", "K_refr (BL refraction)", "dB", lo=0, hi=5,
              tip="Stated input, not predicted; plots show the 0-5 dB band"),
            F("patch_mode", "Patches", kind="choice", choices=[1, 5]),
            F("source_mode", "Source", kind="choice", choices=["generated", "measured"]),
            F("source_model", "Source model", kind="choice", choices=["point", "blade"],
              tip="point: one effective radius (Gutin). blade: BEMT strips from blade geometry (CSV)"),
            F("blade_scale", "Scale blade loads to thrust/torque", kind="bool"),
        ])
        self.form.changed.connect(self.emit)
        self.v.addWidget(self.form)
        h = QHBoxLayout()
        b = QPushButton("Load measured incident levels (CSV: harmonic, dB)...")
        b.clicked.connect(self._load_csv)
        h.addWidget(b)
        bb = QPushButton("Load blade geometry (CSV: r/R, c/R, beta deg, cl_design)...")
        bb.clicked.connect(self._load_blade)
        h.addWidget(bb)
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

    def _load_blade(self):
        import csv
        fn, _ = QFileDialog.getOpenFileName(self, "Blade geometry", "", "CSV (*.csv)")
        if not fn:
            return
        rows = []
        with open(fn, encoding="utf-8") as fh:
            for r in csv.reader(fh):
                try:
                    rows.append([float(v) for v in r[:4]])
                except (ValueError, IndexError):
                    continue
        if len(rows) < 2:
            return
        a = np.array(rows)
        pr = self.project.propeller
        pr.blade = {**pr.blade, "r_over_R": list(a[:, 0]), "c_over_R": list(a[:, 1]), "beta_deg": list(a[:, 2]),
                    "cl_design": list(a[:, 3]), "hub_r_over_R": float(a[0, 0])}
        self.emit()

    def update_readout(self):
        if not self.project:
            return
        pr, s = self.project.propeller, self.project.mission.active_segment()
        n = len(pr.measured)
        nb = len(pr.blade.get("r_over_R", []))
        self.meas.setText((f"{n} measured harmonics loaded" if n else "no measured levels") +
                          (f"; blade geometry: {nb} stations" if nb else "; no blade geometry"))
        try:
            a = isa(s.altitude)
        except ValueError:
            return
        om = 2 * np.pi * s.rpm / 60
        V = s.mach * a.c
        self.readout.setText(
            f"BPF = {pr.blades * s.rpm / 60:.1f} Hz,  Omega = {om:.1f} rad/s,  rotational tip Mach = "
            f"{om * pr.tip_radius / a.c:.3f},  helical tip Mach = {np.hypot(V, om * pr.tip_radius) / a.c:.3f}")


# ---- Fuselage -----------------------------------------------------------------------
class FuselageTab(Tab):
    def __init__(self):
        super().__init__()
        self.form = DataclassForm([
            F("radius", "Fuselage radius R", "m", lo=0.2, hi=5),
            F("nose_to_station", "Nose to prop-plane station", "m", lo=0.1, hi=50),
            F("sidewall_area", "Sidewall area S_w (incl. openings)", "m2", lo=0.1, hi=1000),
            F("patch_width", "Prop-plane patch width (axial)", "m", lo=0.05, hi=10),
            F("patch_height", "Prop-plane patch height (arc)", "m", lo=0.05, hi=5),
            F("patch_x_cabin", "Patch centre, cabin x", "m", lo=0, hi=100),
            F("patch_z_cabin", "Patch centre, cabin z", "m", lo=0, hi=10),
        ])
        self.form.changed.connect(self.emit)
        self.v.addWidget(self.form)
        self.v.addWidget(QLabel("The skin is the first panel of the Sidewall Stack (edit E, rho, nu, h, eta, "
                                "stiffener mass there; tick 'curved')."))
        self.readout = QLabel()
        self.v.addWidget(self.readout)
        self.v.addStretch()

    def load(self, p):
        self.project = p
        self.form.set_object(p.fuselage)
        self.update_readout()

    def update_readout(self):
        p = self.project
        if not p:
            return
        panels = [l for l in p.sidewall if isinstance(l, Panel)]
        if not panels:
            self.readout.setText("No skin panel in the stack")
            return
        c0 = cabin_air(p.cabin.cabin_altitude, p.cabin.temperature).c
        s = panels[0]
        self.readout.setText(f"Skin '{s.name}':  m = {s.mass:.2f} kg/m2,  ring f_r = "
                             f"{s.ring_frequency(p.fuselage.radius):.0f} Hz,  coincidence f_c = "
                             f"{s.coincidence(c0):.0f} Hz,  patch area S_p = "
                             f"{p.fuselage.patch_width * p.fuselage.patch_height:.2f} m2")


# ---- Layer table (sidewall and openings) -------------------------------------------
LAYER_KINDS = ["panel", "porous", "gap", "porous_table"]
LAYER_COLS = [
    F("kind", "Kind", kind="choice", choices=LAYER_KINDS), F("name", "Name", kind="text"),
    F("h", "h", "mm", scale=1e3), F("d", "d", "mm", scale=1e3), F("E", "E", "GPa", scale=1e-9),
    F("rho", "rho", "kg/m3"), F("nu", "nu"), F("eta", "eta"), F("m_add", "Added mass", "kg/m2"),
    F("curved", "Curved", kind="bool"), F("bay_a", "Bay a", "mm", scale=1e3), F("bay_b", "Bay b", "mm", scale=1e3),
    F("sigma", "sigma", "Pa s/m2"), F("frame", "Frame", kind="choice", choices=["rigid", "limp"]),
    F("bulk_density", "Bulk density", "kg/m3"),
]


class LayerTable(ListTable):
    def __init__(self, parent=None):
        super().__init__(LAYER_COLS, AirGap, parent,
                         applicable=lambda item, f: f.attr == "kind" or hasattr(item, f.attr),
                         extra_buttons=[])
        self.lib = load_library()
        h = self.layout().itemAt(1).layout()
        self.libbox = QComboBox()
        self.libbox.addItems([f"panel: {x['name']}" for x in self.lib["panels"]]
                             + [f"porous: {x['name']}" for x in self.lib["porous"]] + ["gap: Air gap 20 mm"])
        b = QPushButton("Insert from library")
        b.clicked.connect(self._insert_lib)
        h.insertWidget(h.count() - 1, self.libbox)
        h.insertWidget(h.count() - 1, b)

    def _insert_lib(self):
        kind, name = self.libbox.currentText().split(": ", 1)
        if kind == "panel":
            item = Panel(**next(x for x in self.lib["panels"] if x["name"] == name))
        elif kind == "porous":
            item = PorousLayer(**next(x for x in self.lib["porous"] if x["name"] == name))
        else:
            item = AirGap(name="Air gap", d=0.02)
        r = self.table.currentRow()
        self.items.insert(r + 1 if r >= 0 else len(self.items), item)
        self.refresh()
        self.changed.emit()

    def on_choice(self, r, f):
        if f.attr != "kind":
            return
        old = self.items[r]
        cls = {"panel": Panel, "porous": PorousLayer, "gap": AirGap, "porous_table": PorousTable}[old.kind]
        if not isinstance(old, cls):
            new = cls()
            new.name = old.name
            self.items[r] = new
        self.refresh()


class SidewallTab(Tab):
    def __init__(self):
        super().__init__()
        self.v.addWidget(QLabel("Layers from exterior (skin) to cabin (trim). Panel: h, E, rho, nu, eta; "
                                "porous: d, sigma (Delany-Bazley); gap: d."))
        self.table = LayerTable()
        self.table.changed.connect(self.emit)
        self.v.addWidget(self.table)
        self.schematic = QLabel()
        self.schematic.setStyleSheet("font-family: monospace")
        self.v.addWidget(self.schematic)

    def load(self, p):
        self.project = p
        self.table.set_items(p.sidewall)
        self.update_readout()

    def update_readout(self):
        if not self.project:
            return
        sym = {"panel": "#", "porous": ":", "gap": " ", "porous_table": ":"}
        parts = []
        for l in self.project.sidewall:
            t = l.h if l.kind == "panel" else l.d
            parts.append(sym[l.kind] * max(1, min(30, int(round(t * 1000 / 4)))))
        total = sum((l.h if l.kind == "panel" else l.d) for l in self.project.sidewall)
        mass = sum(l.mass for l in self.project.sidewall if isinstance(l, Panel))
        self.schematic.setText("exterior |" + "|".join(parts) + "| cabin" +
                               f"     depth {total * 1000:.1f} mm, panel mass {mass:.2f} kg/m2")


# ---- Openings -----------------------------------------------------------------------
class OpeningsTab(Tab):
    def __init__(self):
        super().__init__()
        cols = [F("name", "Name", kind="text"), F("area", "Area", "m2"),
                F("mode", "TL from", kind="choice", choices=["layers", "tl"])]
        self.table = ListTable(cols, Opening)
        self.table.changed.connect(self.emit)
        self.table.selection.connect(self._select)
        self.v.addWidget(QLabel("Windows / doors (area-weighted composite with the sidewall)"))
        self.v.addWidget(self.table)
        self.layers_box = QGroupBox("Layer stack of the selected opening")
        lv = QVBoxLayout(self.layers_box)
        self.layers = LayerTable()
        self.layers.changed.connect(self.emit)
        lv.addWidget(self.layers)
        self.v.addWidget(self.layers_box)
        tb = QGroupBox("Diffuse TL table of the selected opening (mode 'tl'):  f:TL; f:TL; ...")
        th = QHBoxLayout(tb)
        self.tl_edit = QLineEdit()
        self.tl_edit.editingFinished.connect(self._tl_edit)
        th.addWidget(self.tl_edit)
        self.v.addWidget(tb)
        self.sel = -1

    def load(self, p):
        self.project = p
        self.table.set_items(p.openings)
        self._select(0 if p.openings else -1)

    def _select(self, r):
        self.sel = r
        ok = 0 <= r < len(self.project.openings)
        self.layers.set_items(self.project.openings[r].layers if ok else [])
        self.layers_box.setEnabled(ok)
        if ok:
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
            F("Lx", "Cabin box L_x (length)", "m", lo=0.5, hi=60), F("Ly", "L_y (width)", "m", lo=0.5, hi=10),
            F("Lz", "L_z (height)", "m", lo=0.5, hi=5),
            F("cabin_altitude", "Cabin pressure altitude", "m", lo=0, hi=5000),
            F("temperature", "Cabin temperature", "K", lo=250, hi=320),
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
        lib = load_library()
        self.lib = lib
        scols = [F("name", "Surface", kind="text"), F("area", "Area", "m2")] + \
                [F(f"alpha.{i}", f"a {int(f)}" if f < 1000 else f"a {int(f / 1000)}k") for i, f in enumerate(ALPHA_OCTAVES)]
        self.surfaces = ListTable(scols, Surface)
        self.surfaces.changed.connect(self.emit)
        self.v.addWidget(QLabel("Absorbing surfaces (octave alpha, interpolated)"))
        self.v.addWidget(self.surfaces)
        h = QHBoxLayout()
        self.libbox = QComboBox()
        self.libbox.addItems([s["name"] for s in lib["surfaces"]])
        b = QPushButton("Add from library")
        b.clicked.connect(self._add_lib)
        h.addWidget(self.libbox)
        h.addWidget(b)
        h.addStretch()
        self.v.addLayout(h)
        self.seats = ListTable([F(0, "x", "m"), F(1, "y", "m"), F(2, "z", "m")], lambda: [1.0, 0.5, 1.1])
        self.seats.changed.connect(self.emit)
        self.v.addWidget(QLabel("Seat (head) positions: x from forward wall, y from prop-side wall, z from floor"))
        self.v.addWidget(self.seats)
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
        self.seats.set_items(p.cabin.seats)
        self.update_readout()

    def update_readout(self):
        c = self.project.cabin if self.project else None
        if not c or not (c.surfaces or c.t60_measured):
            return
        V = c.cabin_volume()
        A = c.absorption([125.0, 500.0, 1000.0, 2000.0])
        T = cab.t60(V, A)
        fs = cab.schroeder_frequency(float(np.mean(T[1:3])), V)
        self.readout.setText(f"V = {V:.1f} m3;  A(125/500/1k/2k) = " + " / ".join(f"{a:.1f}" for a in A)
                             + " m2;  T60 = " + " / ".join(f"{t:.2f}" for t in T)
                             + f" s;  Schroeder f_s = {fs:.0f} Hz")
