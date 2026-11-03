"""Background execution of runs and sweeps (QThreadPool)."""
from __future__ import annotations

import traceback

from PySide6.QtCore import QObject, QRunnable, Signal


class _Signals(QObject):
    done = Signal(object)
    failed = Signal(str)
    progress = Signal(int)


class Task(QRunnable):
    """Runs fn(*args, progress=emit) or fn(*args) off the GUI thread."""

    def __init__(self, fn, *args, with_progress: bool = False):
        super().__init__()
        self.fn, self.args, self.with_progress = fn, args, with_progress
        self.signals = _Signals()

    def run(self):
        try:
            if self.with_progress:
                out = self.fn(*self.args, progress=self.signals.progress.emit)
            else:
                out = self.fn(*self.args)
        except Exception as exc:  # reported in the GUI status bar
            self.signals.failed.emit(f"{type(exc).__name__}: {exc}\n{traceback.format_exc(limit=3)}")
            return
        self.signals.done.emit(out)
