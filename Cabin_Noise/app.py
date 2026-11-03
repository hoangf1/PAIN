"""Launch the low-fidelity cabin noise GUI:  python app.py [project.json]"""
import sys

from PySide6.QtWidgets import QApplication

from cabin_noise.gui.main_window import MainWindow, apply_light_style


def main():
    app = QApplication(sys.argv)
    apply_light_style(app)
    w = MainWindow(sys.argv[1] if len(sys.argv) > 1 else None)
    w.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
