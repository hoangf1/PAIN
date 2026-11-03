"""Plot views (plan section 4): exterior, TL, interior, A-weighted contribution, seat map,
compare / IL, mission summary, sweep."""
from __future__ import annotations

import numpy as np
import pyqtgraph as pg
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QLabel, QVBoxLayout, QWidget

from ..core.weighting import a_weight

pg.setConfigOptions(antialias=True, background="w", foreground="k")

C_TOTAL = (31, 119, 180)
C_BB = (255, 127, 14)
C_TONE = (44, 160, 44)
C_SEAT = (214, 39, 40)
C_REF = (110, 110, 110)


def _plot(title, xlabel="Frequency (Hz)", ylabel="Level (dB re 20 uPa)", logx=True):
    w = pg.PlotWidget(title=title)
    w.setLabel("bottom", xlabel)
    w.setLabel("left", ylabel)
    w.showGrid(x=True, y=True, alpha=0.3)
    if logx:
        w.setLogMode(x=True, y=False)
    w.addLegend(offset=(10, 10))
    return w


def _stems(plot, f, L, color, name, base=None):
    f, L = np.asarray(f), np.asarray(L)
    fin = L[np.isfinite(L)]
    lo = np.nanmin(fin) - 10 if base is None else min(base, np.nanmin(fin) - 3)
    x = np.repeat(f, 2)
    y = np.column_stack([np.full_like(L, lo), L]).ravel()
    plot.plot(x, y, connect="pairs", pen=pg.mkPen(color, width=2))
    plot.plot(f, L, pen=None, symbol="o", symbolSize=7, symbolBrush=color, name=name)


def _vline(plot, f, label, color=C_REF):
    if f and f > 0:
        ln = pg.InfiniteLine(pos=np.log10(f), angle=90, pen=pg.mkPen(color, style=Qt.DashLine),
                             label=label, labelOpts={"position": 0.92, "color": color})
        plot.addItem(ln)


class ExteriorView(QWidget):
    def __init__(self):
        super().__init__()
        v = QVBoxLayout(self)
        self.p = _plot("Exterior: Gutin tones at the fuselage + Goody boundary layer")
        v.addWidget(self.p)

    def show(self, r):
        self.p.clear()
        fin = r.L_wall[np.isfinite(r.L_wall)]
        self.p.plot(r.centers, r.L_wall, pen=pg.mkPen(C_BB, width=2), symbol="s", symbolSize=5,
                    symbolBrush=C_BB, name="boundary layer, wall (Goody)")
        self.p.plot(r.centers, r.L_ext_bb, pen=pg.mkPen(C_BB, width=1.5, style=Qt.DashLine),
                    name="boundary layer, diffuse equivalent (wall - 3 dB)")
        _stems(self.p, r.f_m, r.L_ext_tone, C_TONE, "tones, free field at the fuselage (Gutin)",
               base=(np.min(fin) - 10) if fin.size else None)


class NRView(QWidget):
    def __init__(self):
        super().__init__()
        v = QVBoxLayout(self)
        self.p = _plot("Sidewall noise reduction (CR-132602) and wall mass-law TL (eq. 46)", ylabel="dB")
        v.addWidget(self.p)

    def show(self, r):
        self.p.clear()
        self.p.plot(r.centers, r.NR_band, pen=pg.mkPen(C_TOTAL, width=2.5), symbol="o", symbolSize=5,
                    symbolBrush=C_TOTAL, name="NR, boundary-layer exposure")
        _stems(self.p, r.f_m, r.NR_tone, C_TONE, "NR at the tones (one side)", base=0)
        self.p.plot(r.centers, r.tl_skin, pen=pg.mkPen(C_REF, style=Qt.DashLine), name="skin TL (eq. 46)")
        if np.all(np.isfinite(r.tl_trim)):
            self.p.plot(r.centers, r.tl_trim, pen=pg.mkPen(C_BB, style=Qt.DashLine), name="trim + blanket TL (eq. 46)")


class InteriorView(QWidget):
    def __init__(self):
        super().__init__()
        v = QVBoxLayout(self)
        self.p = _plot("Interior = exterior - NR: room average, tones, 95th-percentile seat")
        v.addWidget(self.p)

    def show(self, r):
        self.p.clear()
        self.p.plot(r.centers, r.L_band_total, pen=pg.mkPen(C_TOTAL, width=2.5), name="total, average")
        self.p.plot(r.centers, r.L_bb, pen=pg.mkPen(C_BB, width=2), name="boundary layer")
        self.p.plot(r.centers, r.L_band_total + 4.77, pen=pg.mkPen(C_SEAT, width=1.5, style=Qt.DashLine),
                    name="95th-percentile seat (+4.8 dB; statistic holds above f_s)")
        fin = r.L_bb[np.isfinite(r.L_bb)]
        _stems(self.p, r.f_m, r.L_tone, C_TONE, "tones, average", base=(np.min(fin) - 10) if fin.size else None)
        _vline(self.p, r.f_s, "f_s")


class AWeightView(QWidget):
    def __init__(self):
        super().__init__()
        v = QVBoxLayout(self)
        self.p = _plot("A-weighted contribution per band (average)", xlabel="1/3-octave band (Hz)",
                       ylabel="dB(A)", logx=False)
        v.addWidget(self.p)

    def show(self, r):
        self.p.clear()
        x = np.arange(len(r.centers))
        A = a_weight(r.centers)
        tot = r.L_band_total + A
        bb = r.L_bb + A
        base = max(0.0, np.floor(np.nanmin(bb[np.isfinite(bb)]) / 10) * 10 - 10)
        self.p.addItem(pg.BarGraphItem(x=x, height=np.maximum(tot - base, 0), y0=base, width=0.8,
                                       brush=pg.mkBrush(*C_TONE, 200), name="total (tones on top)"))
        self.p.addItem(pg.BarGraphItem(x=x, height=np.maximum(bb - base, 0), y0=base, width=0.8,
                                       brush=pg.mkBrush(*C_BB, 230), name="broadband"))
        self.p.plot([], [], pen=None, symbol="s", symbolBrush=C_TONE, name="tonal share (total)")
        self.p.plot([], [], pen=None, symbol="s", symbolBrush=C_BB, name="broadband")
        from ..core.frequencies import nominal_label
        ax = self.p.getAxis("bottom")
        ax.setTicks([[(i, nominal_label(f)) for i, f in enumerate(r.centers) if i % 2 == 0]])


class CompareView(QWidget):
    def __init__(self):
        super().__init__()
        v = QVBoxLayout(self)
        self.label = QLabel("Store a configuration as A (Compare menu), then edit: current = B")
        v.addWidget(self.label)
        self.p = _plot("Compare: A vs B (room average, total)")
        self.il = _plot("Insertion loss IL = L_A - L_B", ylabel="IL (dB)")
        v.addWidget(self.p)
        v.addWidget(self.il)

    def show(self, a, b, il, name_a="A", name_b="B"):
        self.p.clear()
        self.il.clear()
        self.p.plot(a.centers, a.L_band_total, pen=pg.mkPen(C_REF, width=2), name=f"{name_a}")
        self.p.plot(b.centers, b.L_band_total, pen=pg.mkPen(C_TOTAL, width=2), name=f"{name_b}")
        self.il.plot(il["centers"], il["band_total"], pen=pg.mkPen(C_TOTAL, width=2), name="IL total")
        self.il.plot(il["centers"], il["band_broadband"], pen=pg.mkPen(C_BB, width=2), name="IL broadband")
        if "tone" in il:
            _stems(self.il, il["f_m"], il["tone"], C_TONE, "IL tones", base=0)
        self.label.setText(f"IL (overall dBA, average) = {il['dBA']:.2f} dB")


class MissionView(QWidget):
    def __init__(self):
        super().__init__()
        v = QVBoxLayout(self)
        self.p = _plot("Mission summary (room average)", xlabel="segment", ylabel="dB", logx=False)
        v.addWidget(self.p)
        self.label = QLabel("Run > Mission summary")
        v.addWidget(self.label)

    def show(self, results, sens=None):
        self.p.clear()
        x = np.arange(len(results))
        dba = [r.totals["average"]["total"]["dBA"] for r in results]
        oa = [r.totals["average"]["total"]["OASPL"] for r in results]
        mx = [r.totals["max_seat"]["total"]["dBA"] for r in results]
        self.p.addItem(pg.BarGraphItem(x=x - 0.2, height=oa, width=0.35, brush=pg.mkBrush(*C_REF, 180), name="OASPL"))
        self.p.addItem(pg.BarGraphItem(x=x + 0.2, height=dba, width=0.35, brush=pg.mkBrush(*C_TOTAL, 220), name="dBA"))
        self.p.plot(x + 0.2, mx, pen=None, symbol="t", symbolBrush=C_SEAT, name="dBA max seat")
        self.p.getAxis("bottom").setTicks([[(i, r.segment) for i, r in enumerate(results)]])
        lo = min(dba) - 15
        self.p.setYRange(lo, max(oa) + 5)
        txt = "  |  ".join(f"{r.segment}: {d:.1f} dBA / {o:.1f} dB" for r, d, o in zip(results, dba, oa))
        if sens:
            txt += (f"\n1-vs-5 patch (active segment): {sens['dBA_1']:.2f} vs {sens['dBA_5']:.2f} dBA, "
                    f"delta {sens['delta']:+.2f} dB -> " + ("1 patch adequate (< 1 dB)" if sens["adequate"]
                                                             else "use 5 patches (>= 1 dB)"))
        self.label.setText(txt)


class SweepView(QWidget):
    def __init__(self):
        super().__init__()
        v = QVBoxLayout(self)
        self.p = _plot("Parameter sweep", xlabel="parameter", ylabel="dB", logx=False)
        v.addWidget(self.p)

    def show(self, xs, rows, label):
        self.p.clear()
        self.p.setLabel("bottom", label)
        rows = np.array(rows)
        self.p.plot(xs, rows[:, 0], pen=pg.mkPen(C_TOTAL, width=2), symbol="o", name="dBA average")
        self.p.plot(xs, rows[:, 1], pen=pg.mkPen(C_SEAT, width=2), symbol="t", name="dBA max seat")
        self.p.plot(xs, rows[:, 2], pen=pg.mkPen(C_TONE, width=2), symbol="s", name="dBA tonal")
        self.p.plot(xs, rows[:, 3], pen=pg.mkPen(C_BB, width=2), symbol="d", name="dBA broadband")
