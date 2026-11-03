"""Draggable validation map: pipeline stages as blocks with case chips coloured by status
(after PAIN_Program's map). Drag to pan, Ctrl + wheel to zoom, Fit to reset; a chip click
emits caseClicked(id)."""
from __future__ import annotations

import yaml
from PySide6.QtCore import QPointF, QRectF, Qt, Signal
from PySide6.QtGui import QBrush, QColor, QFont, QPainter, QPainterPath, QPen
from PySide6.QtWidgets import (QGraphicsItem, QGraphicsPathItem, QGraphicsRectItem, QGraphicsScene,
                               QGraphicsSimpleTextItem, QGraphicsView, QHBoxLayout, QLabel, QPushButton,
                               QVBoxLayout, QWidget)

from ..core.validation import VAL_DIR

COL_W, ROW_H = 250.0, 210.0
BLOCK_W, BLOCK_H = 200.0, 58.0
CHIP_W, CHIP_H, CHIP_GAP = 52.0, 22.0, 6.0
STATUS_FILL = {"check ok": "#cfe9cf", "met": "#a9dca9", "check failed": "#f3bcbc", "not met": "#ee9e9e",
               "not run": "#e6e6e6", "info": "#d6e3f3"}
KIND_BORDER = {"verification": "#4f7a4f", "validation": "#2b5c9e", "information": "#7a7a7a"}


def load_map() -> dict:
    with open(VAL_DIR / "map.yaml", encoding="utf-8") as fh:
        return yaml.safe_load(fh)


class _Chip(QGraphicsRectItem):
    def __init__(self, case_id, kind, view, x, y):
        super().__init__(0, 0, CHIP_W, CHIP_H)
        self.case_id, self.view = case_id, view
        self.setPos(x, y)
        self.setPen(QPen(QColor(KIND_BORDER.get(kind, "#555")), 1.5))
        self.setBrush(QBrush(QColor(STATUS_FILL["not run"])))
        self.setCursor(Qt.PointingHandCursor)
        self.setAcceptHoverEvents(True)
        t = QGraphicsSimpleTextItem(case_id, self)
        t.setFont(QFont("Segoe UI", 8, QFont.Bold))
        r = t.boundingRect()
        t.setPos((CHIP_W - r.width()) / 2, (CHIP_H - r.height()) / 2)
        self.setToolTip(case_id)

    def mousePressEvent(self, ev):
        self.view.chip_clicked(self.case_id)
        ev.accept()

    def set_status(self, status, tip):
        self.setBrush(QBrush(QColor(STATUS_FILL.get(status, "#ffffff"))))
        self.setToolTip(tip)

    def set_selected(self, on):
        pen = self.pen()
        pen.setWidthF(3.0 if on else 1.5)
        self.setPen(pen)


class MapView(QGraphicsView):
    caseClicked = Signal(str)

    def __init__(self, layout: dict, kinds: dict, parent=None):
        super().__init__(parent)
        self.setScene(QGraphicsScene(self))
        self.setRenderHint(QPainter.Antialiasing)
        self.setDragMode(QGraphicsView.ScrollHandDrag)          # drag to pan
        self.setTransformationAnchor(QGraphicsView.AnchorUnderMouse)
        self.setBackgroundBrush(QBrush(QColor("#fbfcfd")))
        self.chips: dict[str, _Chip] = {}
        self._build(layout, kinds)

    # geometry ------------------------------------------------------------------------------
    @staticmethod
    def _block_pos(b):
        return QPointF(30 + b["col"] * COL_W, 60 + b["row"] * ROW_H)

    def _build(self, layout, kinds):
        sc = self.scene()
        blocks = {b["id"]: b for b in layout["blocks"]}
        heights = {}
        for b in layout["blocks"]:
            n = len(b.get("cases", []))
            rows = max(1, -(-n // 3))
            heights[b["id"]] = BLOCK_H + (rows * (CHIP_H + CHIP_GAP) + CHIP_GAP if n else 0)
        for g in layout.get("groups", []):                      # group frames
            mem = [b for b in layout["blocks"] if b.get("group") == g["id"]]
            if not mem:
                continue
            xs = [self._block_pos(b).x() for b in mem]
            ys = [self._block_pos(b).y() for b in mem]
            y1 = max(self._block_pos(b).y() + heights[b["id"]] for b in mem)
            r = QRectF(min(xs) - 14, min(ys) - 34, max(xs) - min(xs) + BLOCK_W + 28, y1 - min(ys) + 48)
            frame = sc.addRect(r, QPen(QColor("#c5ced8"), 1, Qt.DashLine), QBrush(QColor("#f3f6f9")))
            frame.setZValue(-2)
            t = sc.addSimpleText(g["title"], QFont("Segoe UI", 9))
            t.setBrush(QBrush(QColor("#5b6773")))
            t.setPos(r.left() + 8, r.top() + 6)
        for a, b in layout.get("edges", []):                    # arrows (orthogonal elbows)
            pa, pb = self._block_pos(blocks[a]), self._block_pos(blocks[b])
            s = QPointF(pa.x() + BLOCK_W, pa.y() + BLOCK_H / 2)
            e = QPointF(pb.x(), pb.y() + BLOCK_H / 2)
            if e.x() <= s.x():                                  # same column: drop down
                s = QPointF(pa.x() + BLOCK_W / 2, pa.y() + heights[a])
                e = QPointF(pb.x() + BLOCK_W / 2, pb.y())
                path = QPainterPath(s)
                path.lineTo(e)
                head_dir = QPointF(0, 1)
            else:
                mx = (s.x() + e.x()) / 2
                path = QPainterPath(s)
                path.lineTo(mx, s.y())
                path.lineTo(mx, e.y())
                path.lineTo(e)
                head_dir = QPointF(1, 0)
            item = QGraphicsPathItem(path)
            item.setPen(QPen(QColor("#8a96a3"), 1.6))
            item.setZValue(-1)
            sc.addItem(item)
            hx, hy = head_dir.x(), head_dir.y()
            tip = QPainterPath(e)
            tip.lineTo(e.x() - 9 * hx + 5 * hy, e.y() - 9 * hy + 5 * hx)
            tip.lineTo(e.x() - 9 * hx - 5 * hy, e.y() - 9 * hy - 5 * hx)
            tip.closeSubpath()
            sc.addPath(tip, QPen(QColor("#8a96a3")), QBrush(QColor("#8a96a3"))).setZValue(-1)
        for b in layout["blocks"]:                              # blocks and chips
            p = self._block_pos(b)
            n = len(b.get("cases", []))
            box = sc.addRect(QRectF(p.x(), p.y(), BLOCK_W, heights[b["id"]]), QPen(QColor("#3f5a78"), 1.2),
                             QBrush(QColor("#ffffff")))
            box.setFlag(QGraphicsItem.ItemIsSelectable, False)
            title = sc.addSimpleText(b["title"], QFont("Segoe UI", 10, QFont.Bold))
            title.setBrush(QBrush(QColor("#1d2733")))
            title.setPos(p.x() + 10, p.y() + 8)
            note = sc.addSimpleText(b.get("note", ""), QFont("Segoe UI", 8))
            note.setBrush(QBrush(QColor("#5b6773")))
            note.setPos(p.x() + 10, p.y() + 30)
            for i, cid in enumerate(b.get("cases", [])):
                cx = p.x() + 10 + (i % 3) * (CHIP_W + CHIP_GAP)
                cy = p.y() + BLOCK_H + (i // 3) * (CHIP_H + CHIP_GAP)
                chip = _Chip(cid, kinds.get(cid, ""), self, cx, cy)
                sc.addItem(chip)
                self.chips[cid] = chip
            if n == 0:
                hint = sc.addSimpleText("verified by unit tests", QFont("Segoe UI", 8, -1, True))
                hint.setBrush(QBrush(QColor("#8a96a3")))
                hint.setPos(p.x() + 10, p.y() + 44)
        sc.setSceneRect(sc.itemsBoundingRect().adjusted(-40, -40, 40, 40))

    # interaction ---------------------------------------------------------------------------
    def showEvent(self, ev):
        super().showEvent(ev)
        if not getattr(self, "_fitted", False):           # fit once, when first shown at its real size
            self._fitted = True
            self.fit()

    def chip_clicked(self, cid):
        for k, c in self.chips.items():
            c.set_selected(k == cid)
        self.caseClicked.emit(cid)

    def wheelEvent(self, ev):
        if ev.modifiers() & Qt.ControlModifier:                 # Ctrl + wheel: zoom
            f = 1.15 if ev.angleDelta().y() > 0 else 1 / 1.15
            z = self.transform().m11() * f
            if 0.3 <= z <= 3.0:
                self.scale(f, f)
            ev.accept()
            return
        super().wheelEvent(ev)

    def fit(self):
        self.fitInView(self.scene().sceneRect(), Qt.KeepAspectRatio)

    def zoom(self, f):
        z = self.transform().m11() * f
        if 0.3 <= z <= 3.0:
            self.scale(f, f)

    def set_statuses(self, results):
        for r in results:
            if r.id in self.chips:
                val = "" if r.value is None else f"{r.value:.3g} {r.unit}"
                self.chips[r.id].set_status(r.status, f"{r.id}: {r.status} {val}\n{r.meta.get('check', '')}")

    def zoom_level(self):
        return self.transform().m11()


class MapPanel(QWidget):
    """Map with its toolbar (Fit, zoom, legend)."""
    caseClicked = Signal(str)

    def __init__(self, kinds: dict, parent=None):
        super().__init__(parent)
        layout = load_map()
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        bar = QHBoxLayout()
        t = QLabel(f"<b>{layout.get('title', '')}</b> &nbsp; drag to pan, Ctrl + wheel to zoom, click a case")
        bar.addWidget(t)
        bar.addStretch()
        self.view = MapView(layout, kinds)
        self.view.caseClicked.connect(self.caseClicked)
        for text, fn in [("-", lambda: self.view.zoom(1 / 1.2)), ("+", lambda: self.view.zoom(1.2)),
                         ("Fit", self.view.fit)]:
            b = QPushButton(text)
            b.setFixedWidth(44 if text != "Fit" else 54)
            b.clicked.connect(fn)
            bar.addWidget(b)
        v.addLayout(bar)
        legend = QLabel("  ".join(f"<span style='background:{c}'>&nbsp;{s}&nbsp;</span>" for s, c in STATUS_FILL.items())
                        + "  &nbsp; border: <span style='color:#4f7a4f'>verification</span> / "
                          "<span style='color:#2b5c9e'>validation</span> / <span style='color:#7a7a7a'>information</span>")
        v.addWidget(legend)
        v.addWidget(self.view, 1)
