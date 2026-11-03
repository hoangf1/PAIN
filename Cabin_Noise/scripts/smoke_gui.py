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

from cabin_noise.core.validation import load_cases  # noqa: E402
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
        if w.run_id != 0 or w.result is not None or "Not run yet" not in w.bar.text():
            failures.append("the model ran without Run being pressed, or the bar does not say so")
        w.tabs[0].changed.emit()                    # an input edit must not start a run
        settle(app)
        if w.run_id != 0:
            failures.append("an input edit started a run")
        before = w.run_id
        w.run_button.click()                        # the green toolbar Run button starts a run
        settle(app)
        if w.run_id != before + 1 or "dBA" not in w.bar.text():
            failures.append("Run toolbar button did not run the model")
        w.tabs[0].changed.emit()
        if "Not up to date" not in w.bar.text() or w.run_id != before + 1:
            failures.append("edit after a run did not mark the plots out of date, or started a run")
        w.store_a()
        w.project.sidewall.trim_mass *= 2
        w.run()
        settle(app)
        if "IL (overall dBA" not in w.views["Compare"].label.text():
            failures.append("compare view not filled")
        w.mission_summary()
        settle(app)
        if "dBA" not in w.views["Mission"].label.text():
            failures.append("mission summary not filled")
        setter = _sweep_setters()["Tip clearance h_c (m)"][0]
        xs = np.linspace(0.3, 0.9, 3)
        rows = run_sweep(w.project, setter, xs)
        w.views["Sweep"].show(xs, rows, "Tip clearance h_c (m)")
        if not (rows[0][2] > rows[-1][2]):
            failures.append("tonal dBA did not fall with tip clearance")
        seg = w.project.mission.segments[0]            # static segment: no boundary layer, views must cope
        old = (seg.mach, seg.thrust)
        seg.mach, seg.thrust = 0.0, 12000.0
        w.project.mission.active = 0
        w.run()
        settle(app)
        if "dBA" not in w.bar.text():
            failures.append("static segment did not produce a result bar")
        seg.mach, seg.thrust = old
        w.project.mission.active = 1
        w.validation.run_all()                     # threaded; wait for it
        settle(app)
        ver = [c for c in load_cases()["cases"] if c["kind"] == "verification"]
        n_ok = sum(c.get("recorded_status") != "check failed" for c in ver)     # recorded failures (cases.yaml)
        if f"Verification {n_ok}/{len(ver)}" not in w.validation.header.text():
            failures.append("verification checks not as recorded: " + w.validation.header.text())
        for r, res in enumerate(w.validation.results):     # caption counts the same points as the verdict
            if "min_fraction" in res.meta and res.status in ("met", "not met"):
                w.validation.show_case(r)
                if f"{res.value:.0f}% within" not in w.validation.caption.text():
                    failures.append(f"{res.id} caption disagrees with its verdict ({res.value:.0f}%)")
        for r, res in enumerate(w.validation.results):     # every chart with a reference has a legend
            if res.ref is not None and res.code is not None:
                w.validation.show_case(r)
                names = [lab.text for _, lab in w.validation.legends[w.validation.overlay].items]
                if "code" not in names or not any(n.startswith("reference:") for n in names):
                    failures.append(f"{res.id} chart legend missing code / reference: {names}")
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
        print("mission:", w.views["Mission"].label.text().splitlines()[0][:120])
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
