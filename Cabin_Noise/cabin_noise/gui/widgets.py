"""Generic editors: a dataclass form and list tables (SI inside, display scale per field)."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Callable

from PySide6.QtCore import Qt, Signal
from PySide6.QtWidgets import (QCheckBox, QComboBox, QDoubleSpinBox, QFormLayout, QHBoxLayout,
                               QHeaderView, QLineEdit, QPushButton, QSpinBox, QTableWidget,
                               QTableWidgetItem, QVBoxLayout, QWidget)


@dataclass
class F:
    """One editable field. scale: display = SI * scale."""
    attr: Any
    label: str
    unit: str = ""
    kind: str = "float"              # float | int | choice | bool | text
    scale: float = 1.0
    lo: float = -1e12
    hi: float = 1e12
    decimals: int = 3
    choices: list = field(default_factory=list)
    tip: str = ""


def _get(obj, attr):
    if isinstance(attr, int):
        return obj[attr]
    if isinstance(attr, str) and "." in attr:
        a, i = attr.split(".")
        return getattr(obj, a)[int(i)]
    return getattr(obj, attr)


def _set(obj, attr, value):
    if isinstance(attr, int):
        obj[attr] = value
    elif isinstance(attr, str) and "." in attr:
        a, i = attr.split(".")
        getattr(obj, a)[int(i)] = value
    else:
        setattr(obj, attr, value)


def _fmt(v, f: F) -> str:
    if f.kind == "float":
        return f"{v * f.scale:.6g}"
    return str(v)


class DataclassForm(QWidget):
    changed = Signal()

    def __init__(self, fields: list[F], parent=None):
        super().__init__(parent)
        self.fields, self.obj, self.editors = fields, None, {}
        lay = QFormLayout(self)
        for f in fields:
            if f.kind == "float":
                w = QDoubleSpinBox()
                w.setRange(f.lo, f.hi)
                w.setDecimals(f.decimals)
                w.setKeyboardTracking(False)
                w.valueChanged.connect(lambda v, f=f: self._edit(f, v / f.scale))
            elif f.kind == "int":
                w = QSpinBox()
                w.setRange(int(f.lo), int(min(f.hi, 2 ** 31 - 1)))
                w.setKeyboardTracking(False)
                w.valueChanged.connect(lambda v, f=f: self._edit(f, int(v)))
            elif f.kind == "choice":
                w = QComboBox()
                w.addItems([str(c) for c in f.choices])
                w.currentIndexChanged.connect(lambda i, f=f: self._edit(f, f.choices[i]))
            elif f.kind == "bool":
                w = QCheckBox()
                w.toggled.connect(lambda b, f=f: self._edit(f, bool(b)))
            else:
                w = QLineEdit()
                w.editingFinished.connect(lambda f=f, w=w: self._edit(f, w.text()))
            if f.tip:
                w.setToolTip(f.tip)
            self.editors[f.attr] = w
            lay.addRow(f"{f.label}" + (f" ({f.unit})" if f.unit else ""), w)

    def set_object(self, obj):
        self.obj = None
        for f in self.fields:
            w, v = self.editors[f.attr], _get(obj, f.attr)
            w.blockSignals(True)
            if f.kind == "float":
                w.setValue(v * f.scale)
            elif f.kind == "int":
                w.setValue(int(v))
            elif f.kind == "choice":
                w.setCurrentIndex(f.choices.index(v) if v in f.choices else 0)
            elif f.kind == "bool":
                w.setChecked(bool(v))
            else:
                w.setText(str(v))
            w.blockSignals(False)
        self.obj = obj

    def _edit(self, f: F, value):
        if self.obj is None:
            return
        _set(self.obj, f.attr, value)
        self.changed.emit()


class ListTable(QWidget):
    """Edits a Python list of records in place. Columns are F specs; cells parse to SI."""
    changed = Signal()
    selection = Signal(int)

    def __init__(self, columns: list[F], factory: Callable[[], Any], parent=None,
                 applicable: Callable[[Any, F], bool] | None = None, extra_buttons=()):
        super().__init__(parent)
        self.columns, self.factory, self.items = columns, factory, []
        self.applicable = applicable or (lambda item, f: True)
        v = QVBoxLayout(self)
        v.setContentsMargins(0, 0, 0, 0)
        self.table = QTableWidget(0, len(columns))
        self.table.setHorizontalHeaderLabels([c.label + (f"\n({c.unit})" if c.unit else "") for c in columns])
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeToContents)
        self.table.itemChanged.connect(self._cell)
        self.table.currentCellChanged.connect(lambda r, *_: self.selection.emit(r))
        v.addWidget(self.table)
        h = QHBoxLayout()
        for text, fn in [("Add", self.add), ("Remove", self.remove), ("Up", lambda: self.move(-1)),
                         ("Down", lambda: self.move(1))] + list(extra_buttons):
            b = QPushButton(text)
            b.clicked.connect(fn)
            h.addWidget(b)
        h.addStretch()
        v.addLayout(h)

    def set_items(self, items: list):
        self.items = items
        self.refresh()

    def refresh(self):
        t = self.table
        t.blockSignals(True)
        t.setRowCount(len(self.items))
        for r, item in enumerate(self.items):
            for c, f in enumerate(self.columns):
                t.removeCellWidget(r, c)
                if not self.applicable(item, f):
                    it = QTableWidgetItem("")
                    it.setFlags(Qt.ItemIsEnabled)
                    t.setItem(r, c, it)
                    continue
                val = _get(item, f.attr)
                if f.kind == "choice":
                    cb = QComboBox()
                    cb.addItems([str(x) for x in f.choices])
                    cb.setCurrentIndex(f.choices.index(val) if val in f.choices else 0)
                    cb.currentIndexChanged.connect(lambda i, r=r, f=f: self._choice(r, f, f.choices[i]))
                    t.setCellWidget(r, c, cb)
                    t.setItem(r, c, QTableWidgetItem(""))
                elif f.kind == "bool":
                    it = QTableWidgetItem("")
                    it.setFlags(Qt.ItemIsEnabled | Qt.ItemIsUserCheckable)
                    it.setCheckState(Qt.Checked if val else Qt.Unchecked)
                    t.setItem(r, c, it)
                else:
                    t.setItem(r, c, QTableWidgetItem(_fmt(val, f)))
        t.blockSignals(False)

    def _choice(self, r, f, value):
        _set(self.items[r], f.attr, value)
        self.on_choice(r, f)
        self.changed.emit()

    def on_choice(self, r, f):
        """Hook for subclasses (e.g. layer kind change)."""

    def _cell(self, it: QTableWidgetItem):
        r, c = it.row(), it.column()
        f = self.columns[c]
        item = self.items[r]
        try:
            if f.kind == "bool":
                _set(item, f.attr, it.checkState() == Qt.Checked)
            elif f.kind == "float":
                _set(item, f.attr, float(it.text()) / f.scale)
            elif f.kind == "int":
                _set(item, f.attr, int(float(it.text())))
            elif f.kind == "text":
                _set(item, f.attr, it.text())
        except ValueError:
            pass
        self.refresh()
        self.changed.emit()

    def add(self):
        self.items.append(self.factory())
        self.refresh()
        self.changed.emit()

    def remove(self):
        r = self.table.currentRow()
        if 0 <= r < len(self.items):
            self.items.pop(r)
            self.refresh()
            self.changed.emit()

    def move(self, d):
        r = self.table.currentRow()
        j = r + d
        if 0 <= r < len(self.items) and 0 <= j < len(self.items):
            self.items[r], self.items[j] = self.items[j], self.items[r]
            self.refresh()
            self.table.setCurrentCell(j, 0)
            self.changed.emit()
