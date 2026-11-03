"""Cards C-05: digitize CR-3813 Figs. E-21 and E-22 (PDF pp. 149–150).

Noise reduction (dB) vs 1/3-octave centre frequency. Measured mean + envelope
(E-21 range / E-22 95% CI) and PAIN prediction (open triangles).
"""
from __future__ import annotations

import csv
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
CR3813 = ROOT / "cr3813"
SCRATCH = ROOT / "_scratch"
QA = CR3813 / "qa"
QA.mkdir(parents=True, exist_ok=True)

# Standard 1/3-octave centres in the figure range
BANDS = [
    63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800,
    1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000,
]

# Axis calibration 300 dpi (2026-10-21): left spine x=521; NR=70 at y=703, 10 dB / 300.5 px down.
# Log-x: 63 Hz at x≈580, 8000 Hz at x≈2050 (tuned to printed tick labels).
X_LEFT = 521.0
Y_70 = 703.0
PX_PER_DB = 30.05  # grid pitch ≈ 300.5 px per 10 dB
X_F63 = 580.0
X_F8000 = 2050.0


def freq_to_x(f):
    return X_F63 + (np.log10(f) - np.log10(63.0)) / (np.log10(8000.0) - np.log10(63.0)) * (X_F8000 - X_F63)


def y_to_db(y):
    return 70.0 - (y - Y_70) / PX_PER_DB


def db_to_y(db):
    return Y_70 + (70.0 - db) * PX_PER_DB


# Horizontal grid / frame rows to ignore when sampling the curve
_GRID_Y = [703, 1004, 1304, 1605, 1906, 2206, 2507]


def _on_grid(y, tol=6):
    return any(abs(y - gy) <= tol for gy in _GRID_Y)


def sample_column_dark(gray, x, y_lo, y_hi, thr=145):
    """Return y positions of dark pixels in a thin column, excluding grid lines."""
    xi = int(round(x))
    col = gray[y_lo:y_hi, max(0, xi - 2) : xi + 3].min(axis=1)
    ys = np.where(col < thr)[0] + y_lo
    return np.array([int(y) for y in ys if not _on_grid(int(y))], dtype=int)


def sample_mean_and_range(gray, x):
    """Solid mean = densest non-grid dark cluster; range = min/max of those ys."""
    y_lo = int(Y_70) + 12
    y_hi = int(db_to_y(0)) - 12
    ys = sample_column_dark(gray, x, y_lo, y_hi)
    if len(ys) < 2:
        return None, None, None
    y_min, y_max = int(ys.min()), int(ys.max())
    # Densest local window = solid average line
    best_y, best_n = int(np.median(ys)), 0
    for y0 in range(y_min, y_max + 1):
        n = int(np.sum(np.abs(ys - y0) <= 2))
        if n > best_n:
            best_n, best_y = n, y0
    return y_to_db(best_y), y_to_db(y_max), y_to_db(y_min)


def find_triangles(rgb, gray):
    """Open triangles ≈ hollow light interior with dark ink edges; approximate as small dark ∧ shapes.
    Simpler: find local dark peaks that are isolated (markers), not on the continuous measured curve.
    """
    # Use ink mask; look for small connected components away from dense horizontal runs
    dark = gray < 130
    H, W = dark.shape
    # Restrict to plot interior
    y0 = int(Y_70) + 10
    y1 = min(H - 1, max(y0 + 1, int(db_to_y(5))))
    x0 = max(0, int(X_F63) - 20)
    x1 = min(W - 1, int(X_F8000) + 20)
    vis = np.zeros_like(dark)
    comps = []
    from collections import deque

    for y in range(y0, y1):
        xs_row = np.where(dark[y, x0:x1])[0] + x0
        for x in xs_row:
            if vis[y, x]:
                continue
            q = deque([(y, x)])
            vis[y, x] = True
            cells = []
            while q:
                yy, xx = q.popleft()
                cells.append((yy, xx))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = yy + dy, xx + dx
                        if y0 <= ny < y1 and x0 <= nx < x1 and dark[ny, nx] and not vis[ny, nx]:
                            vis[ny, nx] = True
                            q.append((ny, nx))
            if 8 <= len(cells) <= 120:
                ys = [c[0] for c in cells]
                xs = [c[1] for c in cells]
                if max(xs) - min(xs) > 25 and max(ys) - min(ys) < 8:
                    continue
                comps.append((float(np.mean(xs)), float(np.mean(ys)), len(cells)))
    return comps


def digitize_page(img_path, out_csv, title, envelope_name):
    im = Image.open(img_path).convert("RGB")
    rgb = np.asarray(im)
    gray = rgb.mean(axis=2)
    draw = ImageDraw.Draw(im)

    tris = find_triangles(rgb, gray)
    # Map each triangle to nearest band
    tri_by_band = {}
    for mx, my, n in tris:
        f = 63.0 * 10 ** ((mx - X_F63) / (X_F8000 - X_F63) * (np.log10(8000) - np.log10(63)))
        # nearest band
        b = min(BANDS, key=lambda bb: abs(np.log10(bb) - np.log10(max(f, 1))))
        if abs(np.log10(b) - np.log10(max(f, 1))) > 0.06:
            continue
        db = y_to_db(my)
        prev = tri_by_band.get(b)
        if prev is None or abs(prev[0] - db) > 0:  # keep first / replace
            # Prefer marker closer to expected triangle size
            if prev is None or n < prev[1]:
                tri_by_band[b] = (db, n, mx, my)

    rows = []
    for b in BANDS:
        x = freq_to_x(b)
        mean_db, low_db, high_db = sample_mean_and_range(gray, x)
        nasa = tri_by_band[b][0] if b in tri_by_band else None
        if b in tri_by_band:
            _, _, mx, my = tri_by_band[b]
            draw.ellipse([mx - 5, my - 5, mx + 5, my + 5], outline=(255, 0, 0))
        if mean_db is not None:
            draw.ellipse([x - 3, db_to_y(mean_db) - 3, x + 3, db_to_y(mean_db) + 3], outline=(0, 180, 0))
        rows.append(
            dict(
                band_Hz=b,
                measured_mean_dB="" if mean_db is None else round(mean_db, 2),
                low_dB="" if low_db is None else round(low_db, 2),
                high_dB="" if high_db is None else round(high_db, 2),
                nasa_pred_dB="" if nasa is None else round(nasa, 2),
            )
        )

    qa = QA / (out_csv.stem + "_overlay.png")
    im.save(qa)
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        f.write(f"# Source: CR-3813 {title}, Pain Methodology.pdf\n")
        f.write(f"# Envelope: {envelope_name}; PAIN = open triangles; η_T=1.0, η_struc≤0.15 (caption)\n")
        f.write("# Method: pass A, 300 dpi, axis-calibrated column sampling + triangle components\n")
        f.write("# Digitized 2026-10-21; script data/digitizers/dig_cr3813_e21_e22.py\n")
        w = csv.DictWriter(f, fieldnames=["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"])
        w.writeheader()
        for r in rows:
            w.writerow(r)
    print("wrote", out_csv, "tris", len(tri_by_band), "qa", qa)
    return rows


def main():
    e21 = SCRATCH / "e21_e22-149.png"
    e22 = SCRATCH / "e21_e22-150.png"
    r21 = digitize_page(
        e21,
        CR3813 / "e21_noise_reduction_range.csv",
        "Fig. E-21 (PDF p. 149 / printed E-33)",
        "measured max/min range",
    )
    r22 = digitize_page(
        e22,
        CR3813 / "e22_noise_reduction_ci.csv",
        "Fig. E-22 (PDF p. 150 / printed E-34)",
        "measured 95% confidence limits",
    )
    # Compare means where both present
    dmax = 0.0
    for a, b in zip(r21, r22):
        if a["measured_mean_dB"] == "" or b["measured_mean_dB"] == "":
            continue
        d = abs(float(a["measured_mean_dB"]) - float(b["measured_mean_dB"]))
        dmax = max(dmax, d)
    print("max |mean_E21 - mean_E22| =", round(dmax, 2), "dB (δ_dig check)")


if __name__ == "__main__":
    main()
