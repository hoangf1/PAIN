"""Phase 90a: digitize NACA Report 996 Fig. 10 (PDF p. 12, printed p. 8, lower plot).

Total rms pressure p̄ (dynes/cm²) against x/D in free space (circles), at a flat wall (squares) and at a circular wall
(diamonds); NACA 4-(5)(08)-03, B = 2, β = 20°, M_t 0.60, d/D = 0.083.

Procedure (IMPLEMENTATION_PLAN.md §2.2): render the page at 400 dpi, locate the gridlines from the pixel darkness of
whole rows and columns, fit pixel→value maps through the labelled gridlines, and find each marker's centre as the
midpoint of the rows where its ink extent is at least half its widest (gridline rows skipped), in a window around its
approximate position. Every marker
is read twice, with two window sizes; the QA check is that both reads agree within 10 dynes/cm².

    python -I data/digitizers/dig_r996_fig10.py <path to NASA Report 996.pdf>
"""
from __future__ import annotations

import csv
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "report996" / "tr996_fig10_reflecting_walls.csv"
DPI = 400
CROP = (215, 3118, 1794, 3915)          # lower plot of p. 12 at 400 dpi (left, top, right, bottom)
X_TICKS = [-1.0 + 0.125 * i for i in range(17)]   # vertical gridlines every 0.125 x/D, −1.00 … 1.00
Y_TICKS = [0.0, 400.0, 800.0, 1200.0, 1600.0]     # labelled horizontal gridlines (every other gridline)

# approximate marker positions (x/D, p̄) read by eye, only to place the search windows
MARKERS = {
    "free_space": [(-1.0, 170), (-0.75, 250), (-0.5, 350), (-0.25, 740), (-0.125, 830), (0.0, 780), (0.125, 650),
                   (0.25, 420), (0.5, 230), (0.75, 100), (1.0, 80)],
    "flat_wall": [(-0.25, 1250), (-0.125, 1670), (0.0, 1540), (0.125, 1340), (0.25, 990)],
    "circular_wall": [(-0.25, 800), (-0.125, 1160), (0.0, 1270), (0.125, 1080), (0.25, 750)],
}


def render(pdf: Path) -> np.ndarray:
    with tempfile.TemporaryDirectory() as d:
        stem = Path(d) / "p"
        subprocess.run(["pdftoppm", "-f", "12", "-l", "12", "-r", str(DPI), "-gray", "-png", str(pdf), str(stem)], check=True)
        png = next(Path(d).glob("p*.png"))
        return np.asarray(Image.open(png).convert("L").crop(CROP), dtype=float)


def gridlines(profile: np.ndarray, n: int, min_gap: int) -> list[int]:
    """The n darkest well-separated positions of a darkness profile, sorted."""
    order = np.argsort(profile)[::-1]
    picked: list[int] = []
    for i in order:
        if all(abs(int(i) - p) >= min_gap for p in picked):
            picked.append(int(i))
        if len(picked) == n:
            break
    return sorted(picked)


def main(pdf: Path) -> None:
    g = render(pdf)
    dark = 255.0 - g
    cols = gridlines(dark.sum(axis=0), len(X_TICKS), 40)
    rows_all = gridlines(dark.sum(axis=1), 10, 40)            # 0 … 1800 every 200 (the 2000 line is cut by the crop)
    rows = sorted(rows_all)[::-1]                             # bottom (0) first
    assert len(cols) == len(X_TICKS) and len(rows_all) == 10, (cols, rows_all)
    xfit = np.polyfit(cols, X_TICKS, 1)
    ylab = rows[0::2][: len(Y_TICKS)]                         # 0, 400, 800, 1200, 1600
    yfit = np.polyfit(ylab, Y_TICKS, 1)
    px_x = lambda v: (v - xfit[1]) / xfit[0]
    px_y = lambda v: (v - yfit[1]) / yfit[0]
    resid_x = np.max(np.abs(np.polyval(xfit, cols) - X_TICKS))
    resid_y = np.max(np.abs(np.polyval(yfit, ylab) - Y_TICKS))
    ink = dark > 60
    grid_rows = set()
    for r in rows_all:
        grid_rows.update(range(r - 3, r + 4))

    def centre(xd: float, p: float, half: int):
        """Marker centre row: midpoint of the rows whose dark extent (leftmost to rightmost ink) is at least half the
        widest; a thin curve through the marker adds a few pixels only, gridline rows are skipped."""
        cx, cy = int(round(px_x(xd))), int(round(px_y(p)))
        ext = []
        for y in range(cy - half, cy + half + 1):
            if y in grid_rows:
                continue
            xs = np.nonzero(ink[y, cx - half: cx + half + 1])[0]
            ext.append((y, xs.max() - xs.min() + 1 if len(xs) else 0))
        wmax = max(e for _, e in ext)
        if wmax < 10:
            return None
        ys = [y for y, e in ext if e >= 0.5 * wmax]
        return float(np.polyval(yfit, (min(ys) + max(ys)) / 2))

    rows_out = []
    worst = 0.0
    for series, pts in MARKERS.items():
        for xd, p in pts:
            a, b = centre(xd, p, 14), centre(xd, p, 18)
            assert a is not None and b is not None, (series, xd)
            worst = max(worst, abs(a - b))
            rows_out.append((series, xd, round((a + b) / 2, 1), round(abs(a - b), 1)))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="") as f:
        f.write("# NACA Report 996 Fig. 10 (PDF p. 12, printed p. 8): total rms pressure vs x/D, NACA 4-(5)(08)-03, B = 2,\n")
        f.write("# beta(0.75R) = 20 deg, M_t 0.60, d/D = 0.083, D = 4 ft. Digitized 2026-10-29 (Phase 90a) by\n")
        f.write(f"# data/digitizers/dig_r996_fig10.py at {DPI} dpi: gridlines from pixel darkness (x fit max residual {resid_x:.4f} x/D,\n")
        f.write(f"# y fit max residual {resid_y:.1f} dynes/cm^2), marker centre = midpoint of the rows at >= half its widest ink extent, read with 14 and 18 px half-windows;\n")
        f.write(f"# p_dyn_cm2 = mean of the two reads, read_diff = their difference (max {worst:.1f}). x/D on the gridlines (0.125 pitch).\n")
        w = csv.writer(f)
        w.writerow(["series", "x_over_D", "p_dyn_cm2", "read_diff"])
        w.writerows(rows_out)
    print(f"wrote {OUT}; x resid {resid_x:.4f}, y resid {resid_y:.1f}, worst two-read difference {worst:.1f} dynes/cm^2")
    assert worst <= 10.0, "QA: two reads differ by more than 10 dynes/cm^2"


if __name__ == "__main__":
    main(Path(sys.argv[1]))
