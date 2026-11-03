"""Regenerates the figures linked from VALIDATION.md: runs every case and saves the Validation tab's
plots (code vs reference, error, 1:1) per case and the stage map as PNGs.

    python scripts/make_doc_figures.py [out_dir]       # default docs/figures

Uses the native Qt platform (the offscreen platform has no fonts on Windows), so a window opens
briefly. The CR-178004 cases take a few minutes.
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
if os.environ.get("QT_QPA_PLATFORM") == "offscreen":     # no fonts offscreen on Windows
    del os.environ["QT_QPA_PLATFORM"]

from PySide6.QtGui import QColor, QImage, QPainter  # noqa: E402
from PySide6.QtWidgets import QApplication  # noqa: E402

from cabin_noise.core.validation import run_all  # noqa: E402
from cabin_noise.gui.main_window import apply_light_style  # noqa: E402
from cabin_noise.gui.validation_tab import ValidationTab  # noqa: E402


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "docs" / "figures"
    out.mkdir(parents=True, exist_ok=True)
    app = QApplication(sys.argv)
    apply_light_style(app)
    tab = ValidationTab()
    tab.resize(1500, 1000)
    tab.show()
    results, stamp = run_all()
    tab._show_all(results, stamp)
    app.processEvents()
    scene = tab.map.view.scene()                        # the whole map, not the visible part
    rect = scene.sceneRect()
    img = QImage(int(rect.width() * 1.5), int(rect.height() * 1.5), QImage.Format_ARGB32)
    img.fill(QColor("white"))
    painter = QPainter(img)
    painter.setRenderHint(QPainter.Antialiasing)
    scene.render(painter)
    painter.end()
    img.save(str(out / "map.png"))
    panel = tab.overlay.parentWidget()
    panel.resize(900, 900)
    for r, res in enumerate(results):
        if res.x is None or res.code is None:
            print(f"{res.id}: {res.status} (no curve)")
            continue
        tab.show_case(r)
        app.processEvents()
        panel.grab().save(str(out / f"{res.id}.png"))
        print(f"{res.id}: {res.status}, {res.value} {res.unit}  {res.note}")
    print("run", stamp)
    app.quit()


if __name__ == "__main__":
    main()
