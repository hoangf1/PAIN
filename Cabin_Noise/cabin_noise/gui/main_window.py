"""Main window: input tabs (left), plot views (right), results bar (bottom), Validation tab."""
from __future__ import annotations

import copy
from pathlib import Path

import numpy as np
import pyqtgraph as pg
import pyqtgraph.exporters  # noqa: F401  (registers exporters)
from PySide6.QtCore import QSettings, QThreadPool, QTimer
from PySide6.QtGui import QAction, QKeySequence
from PySide6.QtWidgets import (QComboBox, QDialog, QDialogButtonBox, QDoubleSpinBox, QFileDialog,
                               QFormLayout, QLabel, QMainWindow, QMessageBox, QScrollArea, QSpinBox,
                               QSplitter, QTabWidget, QWidget)

from ..core.io import default_project, export_results_csv, load_project, save_project
from ..core.materials import Panel, PorousLayer
from ..core.pipeline import insertion_loss, patch_sensitivity, run_case, run_mission
from . import panels, plots
from .validation_tab import ValidationTab
from .worker import Task

ASSUMPTIONS = """<b>Low-fidelity turboprop cabin noise tool</b><br><br>
Stated assumptions and limitations (projectPlan.md section 7):<ul>
<li>Plane-wave, infinite-layer TL; curvature via ring-frequency stiffness only.</li>
<li>Point forces at a single effective radius; thickness noise not modelled.</li>
<li>TBL treated as an equivalent diffuse field: conservative upper bound.</li>
<li>Boundary-layer refraction K_refr is a stated input with a 0-5 dB band, not predicted.</li>
<li>Cabin approximated as a rigid-wall box for the low-frequency seat shape.</li>
<li>Structure-borne paths (engine / wing) and flanking are not modelled.</li>
<li>No experimental validation has been run yet (V4-V7 need digitized NASA data);
the analytic verification checks V0a-V3 pass.</li></ul>
Nothing in the model is fitted to measured data."""


def _sweep_setters():
    def porous(p, v):
        for l in p.sidewall:
            if isinstance(l, PorousLayer):
                l.d = v / 1000

    def skin(p, v):
        next(l for l in p.sidewall if isinstance(l, Panel)).h = v / 1000

    def seg(attr, scale=1.0):
        return lambda p, v: setattr(p.mission.active_segment(), attr, v * scale)

    return {
        "Blanket thickness, all porous layers (mm)": (porous, 10, 150),
        "Skin thickness, first panel (mm)": (skin, 0.8, 3.0),
        "Tip clearance h_c (m)": (lambda p, v: setattr(p.propeller, "clearance", v), 0.2, 1.5),
        "Synchrophase (deg)": (lambda p, v: setattr(p.propeller, "synchrophase_deg", v), 0, 90),
        "RPM, active segment": (seg("rpm"), 1200, 2000),
        "Shaft power, active segment (kW)": (seg("shaft_power", 1e3), 300, 1200),
        "K_refr (dB)": (lambda p, v: setattr(p.propeller, "k_refr", v), 0, 5),
    }


def run_sweep(proj, setter, values, progress=None):
    rows = []
    for i, v in enumerate(values):
        p = copy.deepcopy(proj)
        setter(p, float(v))
        r = run_case(p)
        t = r.totals
        rows.append([t["average"]["total"]["dBA"], t["max_seat"]["total"]["dBA"],
                     t["average"]["tonal"]["dBA"], t["average"]["broadband"]["dBA"]])
        if progress:
            progress(int(100 * (i + 1) / len(values)))
    return rows


class SweepDialog(QDialog):
    def __init__(self, parent):
        super().__init__(parent)
        self.setWindowTitle("Parameter sweep")
        self.setters = _sweep_setters()
        f = QFormLayout(self)
        self.param = QComboBox()
        self.param.addItems(list(self.setters))
        self.lo, self.hi, self.n = QDoubleSpinBox(), QDoubleSpinBox(), QSpinBox()
        for w in (self.lo, self.hi):
            w.setRange(-1e6, 1e6)
            w.setDecimals(3)
        self.n.setRange(2, 100)
        self.n.setValue(9)
        self.param.currentTextChanged.connect(self._defaults)
        self._defaults(self.param.currentText())
        f.addRow("Parameter", self.param)
        f.addRow("From", self.lo)
        f.addRow("To", self.hi)
        f.addRow("Steps", self.n)
        bb = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        bb.accepted.connect(self.accept)
        bb.rejected.connect(self.reject)
        f.addRow(bb)

    def _defaults(self, name):
        _, lo, hi = self.setters[name]
        self.lo.setValue(lo)
        self.hi.setValue(hi)


def apply_light_style(app):
    """Fusion with a light palette, so tables and the results bar match the white plots."""
    from PySide6.QtGui import QColor, QPalette
    app.setStyle("Fusion")
    pal = QPalette()
    for role, col in [(QPalette.Window, "#f0f0f0"), (QPalette.WindowText, "#111111"), (QPalette.Base, "#ffffff"),
                      (QPalette.AlternateBase, "#f5f5f5"), (QPalette.Text, "#111111"), (QPalette.Button, "#e8e8e8"),
                      (QPalette.ButtonText, "#111111"), (QPalette.Highlight, "#3874d8"),
                      (QPalette.HighlightedText, "#ffffff"), (QPalette.ToolTipBase, "#ffffe0"),
                      (QPalette.ToolTipText, "#111111")]:
        pal.setColor(role, QColor(col))
    app.setPalette(pal)


class MainWindow(QMainWindow):
    def __init__(self, path: str | None = None):
        super().__init__()
        self.resize(1500, 920)
        self.pool = QThreadPool.globalInstance()
        self._tasks = set()   # keep Task/signal objects alive until they report
        self.settings = QSettings("CabinNoise", "LowFi")
        self.path: Path | None = None
        self.result = None
        self.compare_a = None
        self.run_id = 0
        self.timer = QTimer(self, singleShot=True, interval=400)
        self.timer.timeout.connect(self.run)

        self.inputs = QTabWidget()
        self.tabs = [panels.MissionTab(), panels.PropellerTab(), panels.FuselageTab(), panels.SidewallTab(),
                     panels.OpeningsTab(), panels.CabinTab()]
        for t, name in zip(self.tabs, ["Mission", "Propeller", "Fuselage", "Sidewall Stack", "Openings", "Cabin"]):
            sc = QScrollArea()
            sc.setWidgetResizable(True)
            sc.setWidget(t)
            self.inputs.addTab(sc, name)
            t.changed.connect(self.schedule)

        self.views = {"Exterior": plots.ExteriorView(), "TL": plots.TLView(), "Interior": plots.InteriorView(),
                      "A-weighted": plots.AWeightView(), "Seat map": plots.SeatMapView(),
                      "Compare": plots.CompareView(), "Mission": plots.MissionView(), "Sweep": plots.SweepView()}
        self.plot_tabs = QTabWidget()
        for k, w in self.views.items():
            self.plot_tabs.addTab(w, k)

        split = QSplitter()
        split.addWidget(self.inputs)
        split.addWidget(self.plot_tabs)
        split.setSizes([620, 880])
        model = QWidget()
        from PySide6.QtWidgets import QVBoxLayout
        mv = QVBoxLayout(model)
        mv.addWidget(split, 1)
        self.bar = QLabel()
        self.bar.setStyleSheet("font-size: 13px; padding: 4px; color: #111; background: #f2f4f7; border-top: 1px solid #ccd;")
        mv.addWidget(self.bar)
        self.validation = ValidationTab()
        self.top = QTabWidget()
        self.top.addTab(model, "Model")
        self.top.addTab(self.validation, "Validation")
        self.setCentralWidget(self.top)
        self._menus()
        if path:
            self.open_path(path)
        else:
            self.set_project(default_project())

    # ---- menus ------------------------------------------------------------------------
    def _act(self, menu, text, fn, key=None):
        a = QAction(text, self)
        a.triggered.connect(fn)
        if key:
            a.setShortcut(QKeySequence(key))
        menu.addAction(a)
        return a

    def _menus(self):
        mb = self.menuBar()
        f = mb.addMenu("&File")
        self._act(f, "New (default example)", lambda: self.set_project(default_project()), "Ctrl+N")
        self._act(f, "Open...", self.open, "Ctrl+O")
        self._act(f, "Save", self.save, "Ctrl+S")
        self._act(f, "Save as...", self.save_as, "Ctrl+Shift+S")
        self.recent_menu = f.addMenu("Recent files")
        f.addSeparator()
        self._act(f, "Export results CSV...", self.export_csv)
        self._act(f, "Export current plot (PNG/SVG)...", self.export_plot)
        f.addSeparator()
        self._act(f, "Quit", self.close, "Ctrl+Q")
        r = mb.addMenu("&Run")
        self._act(r, "Run now", self.run, "F5")
        self._act(r, "Mission summary + patch sensitivity", self.mission_summary, "F6")
        self._act(r, "Parameter sweep...", self.sweep, "F7")
        c = mb.addMenu("&Compare")
        self._act(c, "Store current as A", self.store_a)
        self._act(c, "Load A from project file...", self.load_a)
        self._act(c, "Clear A", lambda: setattr(self, "compare_a", None))
        h = mb.addMenu("&Help")
        self._act(h, "Assumptions and limitations", lambda: QMessageBox.information(self, "About", ASSUMPTIONS))
        self._refresh_recent()

    def _refresh_recent(self):
        self.recent_menu.clear()
        for p in self.settings.value("recent", [], type=list) or []:
            self._act(self.recent_menu, p, lambda checked=False, p=p: self.open_path(p))

    def _push_recent(self, p):
        lst = [x for x in (self.settings.value("recent", [], type=list) or []) if x != str(p)]
        self.settings.setValue("recent", [str(p)] + lst[:7])
        self._refresh_recent()

    # ---- project ----------------------------------------------------------------------
    def set_project(self, p):
        self.project = p
        for t in self.tabs:
            t.load(p)
        self.setWindowTitle(f"Cabin Noise (low-fi) - {p.name}" + (f" - {self.path}" if self.path else ""))
        self.run()

    def open(self):
        fn, _ = QFileDialog.getOpenFileName(self, "Open project", "", "Project (*.json)")
        if fn:
            self.open_path(fn)

    def open_path(self, fn):
        try:
            p = load_project(fn)
        except Exception as e:  # shown to the user
            QMessageBox.warning(self, "Open", f"Could not open {fn}:\n{e}")
            return
        self.path = Path(fn)
        self._push_recent(fn)
        self.set_project(p)

    def save(self):
        if not self.path:
            return self.save_as()
        save_project(self.project, self.path)
        self.statusBar().showMessage(f"Saved {self.path}", 4000)

    def save_as(self):
        fn, _ = QFileDialog.getSaveFileName(self, "Save project", f"{self.project.name}.json", "Project (*.json)")
        if fn:
            self.path = Path(fn)
            self._push_recent(fn)
            self.save()

    # ---- runs -------------------------------------------------------------------------
    def _start(self, task):
        self._tasks.add(task)
        task.signals.done.connect(lambda *_: self._tasks.discard(task))
        task.signals.failed.connect(lambda *_: self._tasks.discard(task))
        task.setAutoDelete(False)
        self.pool.start(task)

    def schedule(self):
        self.timer.start()

    def run(self):
        self.run_id += 1
        rid = self.run_id
        self.statusBar().showMessage("Running...")
        task = Task(run_case, copy.deepcopy(self.project))
        task.signals.done.connect(lambda r, rid=rid: self._done(r, rid))
        task.signals.failed.connect(self._failed)
        self._start(task)

    def _failed(self, msg):
        self.statusBar().showMessage(msg.splitlines()[0], 10000)
        self.bar.setText(f"<span style='color:#b00'>Input error: {msg.splitlines()[0]}</span>")

    def _done(self, r, rid):
        if rid != self.run_id:
            return
        self.result = r
        t = r.totals
        def fmt(k):
            a, m = t["average"][k], t["max_seat"][k]
            return (f"<b>{k}</b> {a['OASPL']:.1f} dB / {a['dBA']:.1f} dBA / {a['dBC']:.1f} dBC "
                    f"(max seat {m['dBA']:.1f} dBA)")
        self.bar.setText(f"<b>{r.segment}</b> &nbsp; BPF {r.bpf:.1f} Hz &nbsp; | &nbsp; " + " &nbsp;|&nbsp; ".join(
            fmt(k) for k in ("total", "tonal", "broadband")) + f" &nbsp;| f_s {r.f_s:.0f} Hz"
            + ("" if not r.warnings else f" &nbsp;| <span style='color:#a60'>{'; '.join(r.warnings)}</span>"))
        self.statusBar().showMessage("Done", 2000)
        v = self.views
        v["Exterior"].show(r)
        v["TL"].show(r)
        v["Interior"].show(r, self.project.propeller.k_refr)
        v["A-weighted"].show(r)
        cb = self.project.cabin
        v["Seat map"].set_geometry(cb.seats or [[cb.Lx / 2, cb.Ly / 2, 1.1]], (cb.Lx, cb.Ly))
        v["Seat map"].show(r)
        if self.compare_a is not None:
            try:
                v["Compare"].show(self.compare_a, r, insertion_loss(self.compare_a, r))
            except ValueError as e:
                self.statusBar().showMessage(f"Compare: {e}", 6000)

    def mission_summary(self):
        proj = copy.deepcopy(self.project)
        task = Task(lambda p: (run_mission(p), patch_sensitivity(p)), proj)
        task.signals.done.connect(lambda out: (self.views["Mission"].show(*out),
                                               self.plot_tabs.setCurrentWidget(self.views["Mission"]),
                                               self.statusBar().showMessage("Mission summary done", 3000)))
        task.signals.failed.connect(self._failed)
        self.statusBar().showMessage("Running all segments + 5-patch check...")
        self._start(task)

    def sweep(self):
        d = SweepDialog(self)
        if d.exec() != QDialog.Accepted:
            return
        name = d.param.currentText()
        setter = d.setters[name][0]
        xs = np.linspace(d.lo.value(), d.hi.value(), d.n.value())
        task = Task(run_sweep, copy.deepcopy(self.project), setter, xs, with_progress=True)
        task.signals.progress.connect(lambda p: self.statusBar().showMessage(f"Sweep {p}%"))
        task.signals.done.connect(lambda rows: (self.views["Sweep"].show(xs, rows, name),
                                                self.plot_tabs.setCurrentWidget(self.views["Sweep"]),
                                                self.statusBar().showMessage("Sweep done", 3000)))
        task.signals.failed.connect(self._failed)
        self._start(task)

    def store_a(self):
        if self.result is not None:
            self.compare_a = self.result
            self.statusBar().showMessage("Stored current result as A; edit inputs to compare (current = B)", 5000)

    def load_a(self):
        fn, _ = QFileDialog.getOpenFileName(self, "Configuration A", "", "Project (*.json)")
        if fn:
            task = Task(lambda f: run_case(load_project(f)), fn)
            task.signals.done.connect(lambda r: (setattr(self, "compare_a", r), self.run()))
            task.signals.failed.connect(self._failed)
            self._start(task)

    # ---- export -----------------------------------------------------------------------
    def export_csv(self):
        if self.result is None:
            return
        fn, _ = QFileDialog.getSaveFileName(self, "Export results", "results.csv", "CSV (*.csv)")
        if fn:
            export_results_csv(self.result, fn)

    def export_plot(self):
        w = self.plot_tabs.currentWidget()
        pw = w.findChildren(pg.PlotWidget)
        if not pw:
            return
        fn, flt = QFileDialog.getSaveFileName(self, "Export plot", "plot.png", "PNG (*.png);;SVG (*.svg)")
        if not fn:
            return
        item = pw[0].getPlotItem()
        exp = pg.exporters.SVGExporter(item) if fn.lower().endswith(".svg") else pg.exporters.ImageExporter(item)
        exp.export(fn)
