"""Offscreen GUI smoke test: builds the window, runs the default case, compare, mission
summary, a sweep and the validation map, and checks each produced output.

    QT_QPA_PLATFORM=offscreen python scripts/smoke_gui.py [screenshot_dir]
"""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

import numpy as np  # noqa: E402
from PySide6.QtCore import QThreadPool, QTimer  # noqa: E402
from PySide6.QtWidgets import QApplication  # noqa: E402

from cabin_noise.gui.main_window import MainWindow, _sweep_setters, apply_light_style, run_sweep  # noqa: E402


def settle(app):
    for _ in range(50):
        QThreadPool.globalInstance().waitForDone(30000)
        app.processEvents()
        if not QThreadPool.globalInstance().activeThreadCount():
            break


def main():
    shots = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    app = QApplication(sys.argv)
    apply_light_style(app)
    w = MainWindow()
    w.show()
    failures = []

    def check():
        settle(app)
        if w.result is None or "dBA" not in w.bar.text():
            failures.append("default run produced no result bar")
        w.store_a()
        w.project.sidewall[2].d = 0.10
        w.run()
        settle(app)
        if "IL (overall dBA" not in w.views["Compare"].label.text():
            failures.append("compare view not filled")
        w.mission_summary()
        settle(app)
        if "1-vs-5 patch" not in w.views["Mission"].label.text():
            failures.append("mission summary not filled")
        setter = _sweep_setters()["Tip clearance h_c (m)"][0]
        xs = np.linspace(0.3, 0.9, 3)
        rows = run_sweep(w.project, setter, xs)
        w.views["Sweep"].show(xs, rows, "Tip clearance h_c (m)")
        if not (rows[0][2] > rows[-1][2]):
            failures.append("tonal dBA did not fall with tip clearance")
        w.validation.run_all()                     # threaded; wait for it
        settle(app)
        if "Verification 6/6" not in w.validation.header.text():
            failures.append("verification checks not all ok: " + w.validation.header.text())
        if shots:
            shots.mkdir(parents=True, exist_ok=True)
            for i in range(w.plot_tabs.count()):
                w.plot_tabs.setCurrentIndex(i)
                app.processEvents()
                w.grab().save(str(shots / f"view{i}_{w.plot_tabs.tabText(i)}.png"))
            for i in range(w.inputs.count()):
                w.inputs.setCurrentIndex(i)
                app.processEvents()
                w.grab().save(str(shots / f"input{i}_{w.inputs.tabText(i)}.png"))
            w.top.setCurrentIndex(1)
            w.validation.table.setCurrentCell(0, 0)
            app.processEvents()
            w.grab().save(str(shots / "validation.png"))
        print("bar:", w.bar.text()[:160].replace("&nbsp;", " "))
        print("mission:", w.views["Mission"].label.text().splitlines()[-1])
        print("validation:", w.validation.header.text())
        app.quit()

    QTimer.singleShot(300, check)
    app.exec()
    if failures:
        print("FAILED:\n  " + "\n  ".join(failures))
        sys.exit(1)
    print("GUI smoke OK")


if __name__ == "__main__":
    main()
