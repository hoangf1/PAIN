"""Validation tab: case map, code-vs-reference figures, report export."""
from __future__ import annotations

import html

import numpy as np
import pyqtgraph as pg
from PySide6.QtCore import Qt
from PySide6.QtGui import QColor, QPageSize, QPdfWriter, QTextDocument
from PySide6.QtWidgets import (QFileDialog, QHBoxLayout, QHeaderView, QLabel, QPushButton, QSplitter,
                               QTableWidget, QTableWidgetItem, QTabWidget, QVBoxLayout, QWidget)

from ..core.validation import coverage, criterion_range, load_cases, run_all
from .validation_map import MapPanel
from .worker import Task

COLS = ["Case", "Kind", "Stage", "Track", "Reference", "Metric", "Target", "Result", "Status"]
STATUS_COLOR = {"check ok": "#d8f0d8", "met": "#bfe8bf", "check failed": "#f6c6c6", "not met": "#f2b0b0",
                "not run": "#eeeeee", "info": "#e3ecf7"}


class ValidationTab(QWidget):
    def __init__(self):
        super().__init__()
        self.results, self.stamp = [], {}
        v = QVBoxLayout(self)
        top = QHBoxLayout()
        self.header = QLabel("Not run")
        top.addWidget(self.header)
        top.addStretch()
        for text, fn in [("Run all", self.run_all), ("Export HTML...", self.export_html),
                         ("Export PDF...", self.export_pdf)]:
            b = QPushButton(text)
            b.clicked.connect(fn)
            top.addWidget(b)
        v.addLayout(top)
        v.addWidget(QLabel("Verification rows (analytic checks) show 'check ok / failed', never a verdict. "
                           "Validation rows compare with experimental data; criteria were fixed "
                           "before any comparison and nothing is fitted."))
        split = QSplitter()
        self.table = QTableWidget(0, len(COLS))
        self.table.setHorizontalHeaderLabels(COLS)
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeToContents)
        self.table.setSelectionBehavior(QTableWidget.SelectRows)
        self.table.currentCellChanged.connect(lambda r, *_: self.show_case(r))
        cases = load_cases()["cases"]
        self.ids = [c["id"] for c in cases]
        self.map = MapPanel({c["id"]: c["kind"] for c in cases})
        self.map.caseClicked.connect(self.select_case)
        self.views = QTabWidget()
        self.views.addTab(self.map, "Map")
        self.views.addTab(self.table, "Table")
        split.addWidget(self.views)
        right = QWidget()
        rv = QVBoxLayout(right)
        self.overlay = pg.PlotWidget(title="Code (line) vs reference (markers), acceptance band shaded")
        self.error = pg.PlotWidget(title="Error vs abscissa with +-target")
        self.scatter = pg.PlotWidget(title="Predicted vs reference (1:1)")
        for w in (self.overlay, self.error, self.scatter):
            w.showGrid(x=True, y=True, alpha=0.3)
            rv.addWidget(w)
        self.caption = QLabel()
        self.caption.setWordWrap(True)
        rv.addWidget(self.caption)
        split.addWidget(right)
        split.setSizes([700, 600])
        v.addWidget(split, 1)
        self._fill_static()

    def _fill_static(self):
        cases = load_cases()["cases"]
        self.table.setRowCount(len(cases))
        for r, c in enumerate(cases):
            self._row(r, c, None)

    def _row(self, r, meta, res):
        tgt = meta.get("target_db", meta.get("target_oct"))
        unit = "oct" if "target_oct" in meta else "dB"
        if "min_fraction" in meta:
            tgt, unit = 100 * meta["min_fraction"], f"% within +-{meta['tol_db']:g} dB"
        val = "" if res is None or res.value is None else f"{res.value:.3g} {res.unit}"
        status = "not run" if res is None else res.status
        cells = [meta["id"], meta["kind"], meta["stage"], meta["track"], meta["reference"], meta["metric"],
                 "" if tgt is None else f"{tgt:g} {unit}", val, status]
        for c, text in enumerate(cells):
            it = QTableWidgetItem(str(text))
            it.setFlags(Qt.ItemIsEnabled | Qt.ItemIsSelectable)
            it.setBackground(QColor(STATUS_COLOR.get(status, "#ffffff")))
            it.setForeground(QColor("#111111"))
            self.table.setItem(r, c, it)

    def run_all(self):
        """Runs every case on a worker thread (the flight cases take minutes)."""
        if getattr(self, "_task", None) is not None:
            return
        self.header.setText("Running all cases (the CR-178004 cases take a few minutes)...")
        self._task = Task(run_all)
        self._task.setAutoDelete(False)
        self._task.signals.done.connect(lambda out: self._show_all(*out))
        self._task.signals.failed.connect(lambda msg: (setattr(self, "_task", None),
                                                       self.header.setText("Run failed: " + msg.splitlines()[0])))
        from PySide6.QtCore import QThreadPool
        QThreadPool.globalInstance().start(self._task)

    def _show_all(self, results, stamp):
        self._task = None
        self.results, self.stamp = results, stamp
        for r, res in enumerate(self.results):
            self._row(r, res.meta, res)
        self.header.setText(f"{coverage(self.results)}   |   run {self.stamp['date']}, commit "
                            f"{self.stamp['commit']}, criteria fixed {self.stamp['criteria_fixed']}")
        self.map.view.set_statuses(self.results)
        self.show_case(max(self.table.currentRow(), 0))

    def select_case(self, cid):
        """Map chip click: select that case's table row, which shows its figures."""
        if cid in self.ids:
            self.table.setCurrentCell(self.ids.index(cid), 0)
            self.show_case(self.ids.index(cid))

    def show_case(self, r):
        for w in (self.overlay, self.error, self.scatter):
            w.clear()
        if not (0 <= r < len(self.results)):
            return
        res = self.results[r]
        m = res.meta
        cap = f"{m['id']} - {m['check']}. Reference: {m['reference']}. Metric: {m['metric']}. Status: {res.status}."
        if res.note:
            cap += f"  {res.note}"
        self.caption.setText(cap)
        if res.x is None or res.code is None:
            return
        logx = res.xlabel.startswith("Frequency")
        for w in (self.overlay, self.error):
            w.setLogMode(x=logx, y=False)
            w.setLabel("bottom", res.xlabel)
        self.overlay.setLabel("left", res.ylabel)
        self.overlay.plot(res.x, res.code, pen=pg.mkPen((31, 119, 180), width=2))
        if res.ref is not None:
            ok = np.isfinite(res.ref)
            tgt = m.get("tol_db", res.target if res.unit == "dB" else 0.0) or 0.0
            if tgt:
                up = pg.PlotDataItem(res.x[ok], res.ref[ok] + tgt)
                dn = pg.PlotDataItem(res.x[ok], res.ref[ok] - tgt)
                for it in (up, dn):                  # not added to the plot, so set its log mode here
                    it.setLogMode(logx, False)
                self.overlay.addItem(pg.FillBetweenItem(up, dn, brush=pg.mkBrush(150, 150, 150, 60)))
            self.overlay.plot(res.x[ok], res.ref[ok], pen=None, symbol="o", symbolSize=6,
                              symbolBrush=(80, 80, 80))
            curves = {k: v for k, v in res.series.items() if isinstance(v, np.ndarray) and v.shape == res.x.shape}
            self.overlay.addLegend(offset=(-10, 10)).setVisible(bool(curves))   # persists across cases
            if curves:                                       # information curves (no criterion)
                for (k, val), sym in zip(curves.items(), ("t", "s", "d", "+")):
                    self.overlay.plot(res.x, val, pen=pg.mkPen((120, 120, 120), width=1, style=Qt.DashLine),
                                      symbol=sym, symbolSize=6, name=k)
            err = res.code[ok] - res.ref[ok]
            self.error.plot(res.x[ok], err, pen=pg.mkPen((214, 39, 40), width=2), symbol="o", symbolSize=4)
            if tgt:
                for s in (-tgt, tgt):
                    self.error.addItem(pg.InfiniteLine(pos=s, angle=0, pen=pg.mkPen("k", style=Qt.DashLine)))
            self.scatter.plot(res.ref[ok], res.code[ok], pen=None, symbol="o", symbolSize=6)
            lo, hi = float(np.min(res.ref[ok])), float(np.max(res.ref[ok]))
            self.scatter.plot([lo, hi], [lo, hi], pen=pg.mkPen("k", style=Qt.DashLine))
            e = err[criterion_range(m, res.x[ok])]               # the points the verdict counts
            if e.size:
                within = f", {np.mean(np.abs(e) <= tgt) * 100:.0f}% within +-{tgt:g} dB" if tgt else ""
                where = "In the criterion range" if "band_min" in m or "band_max" in m else "Over all"
                self.caption.setText(cap + f"  {where} ({e.size} points): mean {np.mean(e):+.3g} dB, "
                                           f"RMS {np.sqrt(np.mean(e ** 2)):.3g} dB, max |e| "
                                           f"{np.max(np.abs(e)):.3g} dB{within}.")
        else:
            for k, val in res.series.items():
                if isinstance(val, float):
                    self.overlay.addItem(pg.InfiniteLine(pos=np.log10(val) if logx else val, angle=90,
                                                         label=k, pen=pg.mkPen("k", style=Qt.DashLine)))

    def report_html(self) -> str:
        if not self.results:
            self._show_all(*run_all())
        rows = "".join(
            "<tr>" + "".join(f"<td>{html.escape(self.table.item(r, c).text())}</td>" for c in range(len(COLS)))
            + "</tr>" for r in range(self.table.rowCount()))
        return (f"<html><body><h2>Cabin noise low-fi tool: validation report</h2>"
                f"<p>{html.escape(coverage(self.results))}<br>Run {self.stamp.get('date')} - commit "
                f"{self.stamp.get('commit')} - criteria fixed {self.stamp.get('criteria_fixed')}</p>"
                f"<p>Verification rows are analytic checks (no verdict). Validation rows are blind "
                f"comparisons with experimental data.</p>"
                f"<table border=1 cellspacing=0 cellpadding=3><tr>{''.join(f'<th>{c}</th>' for c in COLS)}</tr>"
                f"{rows}</table></body></html>")

    def export_html(self):
        fn, _ = QFileDialog.getSaveFileName(self, "Validation report", "validation_report.html", "HTML (*.html)")
        if fn:
            with open(fn, "w", encoding="utf-8") as fh:
                fh.write(self.report_html())

    def export_pdf(self):
        fn, _ = QFileDialog.getSaveFileName(self, "Validation report", "validation_report.pdf", "PDF (*.pdf)")
        if fn:
            doc = QTextDocument()
            doc.setHtml(self.report_html())
            w = QPdfWriter(fn)
            w.setPageSize(QPageSize(QPageSize.A4))
            doc.print_(w)
