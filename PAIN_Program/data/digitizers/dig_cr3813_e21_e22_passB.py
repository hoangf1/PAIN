"""C-05 pass B: digitize CR-3813 E-21/E-22 with solid-vs-dashed separation.

Grid-calibrated (300 dpi): y=703 → 70 dB, 300.5 px / 10 dB; x log 63→8000.
Pass B1 = improved column sampler (solid = densest cluster; range = outer ink).
Pass B2 = independent hand readings from the same render (listed below).
δ_dig = max |mean_B1 − mean_B2| over bands with both values; criterion ≤ 1 dB.
"""
from __future__ import annotations

import csv
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
CR3813 = ROOT / "cr3813"
SCRATCH = ROOT / "_scratch"
QA = CR3813 / "qa"
QA.mkdir(parents=True, exist_ok=True)

BANDS = [
    63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800,
    1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000,
]

X_LEFT = 521.0
Y_70 = 703.0
PX_PER_DB = 30.05
X_F63 = 580.0
X_F8000 = 2050.0
_GRID_Y = [703, 1004, 1304, 1605, 1906, 2206, 2507]


def freq_to_x(f):
    return X_F63 + (np.log10(f) - np.log10(63.0)) / (np.log10(8000.0) - np.log10(63.0)) * (
        X_F8000 - X_F63
    )


def y_to_db(y):
    return 70.0 - (y - Y_70) / PX_PER_DB


def db_to_y(db):
    return Y_70 + (70.0 - db) * PX_PER_DB


def _on_grid(y, tol=5):
    return any(abs(y - gy) <= tol for gy in _GRID_Y)


def sample_column(gray, x, thr=150):
    """Return (mean_db, min_db, max_db) separating solid mean from envelope ink."""
    xi = int(round(x))
    y_lo = int(Y_70) + 15
    y_hi = int(db_to_y(0)) - 15
    # min across a 5-px wide strip
    strip = gray[y_lo:y_hi, max(0, xi - 2) : xi + 3].min(axis=1)
    ys = []
    dens = []  # local darkness score
    for i, v in enumerate(strip):
        y = y_lo + i
        if _on_grid(y):
            continue
        if v < thr:
            # local density in ±3 px vertically in strip
            i0, i1 = max(0, i - 3), min(len(strip), i + 4)
            dens_score = float(np.mean(strip[i0:i1] < thr))
            ys.append(y)
            dens.append(dens_score)
    if len(ys) < 3:
        return None, None, None
    ys = np.asarray(ys)
    dens = np.asarray(dens)
    # Solid mean: y with highest density among dark pixels (continuous stroke)
    best = int(ys[int(np.argmax(dens))])
    # Prefer a denser cluster: majority vote in a sliding window of 5 px
    best_n, best_y = 0, best
    for y0 in range(int(ys.min()), int(ys.max()) + 1):
        n = int(np.sum(np.abs(ys - y0) <= 2))
        # weight by density of members
        w = float(np.sum(dens[np.abs(ys - y0) <= 2]))
        score = n + 2 * w
        if score > best_n:
            best_n, best_y = score, y0
    # Envelope: extreme ink, but ignore isolated speckles (require neighbour)
    kept = []
    for y in ys:
        if np.sum(np.abs(ys - y) <= 4) >= 2:
            kept.append(int(y))
    if not kept:
        kept = list(map(int, ys))
    y_min, y_max = min(kept), max(kept)
    # y_min = highest NR (top of plot), y_max = lowest NR
    return y_to_db(best_y), y_to_db(y_max), y_to_db(y_min)


def find_triangles(gray):
    dark = gray < 125
    H, W = dark.shape
    y0 = int(Y_70) + 8
    y1 = min(H - 1, int(db_to_y(2)))
    x0 = max(0, int(X_F63) - 30)
    x1 = min(W - 1, int(X_F8000) + 30)
    vis = np.zeros_like(dark)
    comps = []
    for y in range(y0, y1):
        for x in np.where(dark[y, x0:x1])[0] + x0:
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
            if 10 <= len(cells) <= 90:
                ys = [c[0] for c in cells]
                xs = [c[1] for c in cells]
                h = max(ys) - min(ys)
                w = max(xs) - min(xs)
                if h < 6 or w < 6 or w > 28 or h > 28:
                    continue
                # skip long horizontal dashes
                if w > 2.5 * h and h < 8:
                    continue
                comps.append((float(np.mean(xs)), float(np.mean(ys)), len(cells)))
    return comps


# Pass B2 — independent hand readings (image description + eye on grid)
# mean / min / max / nasa_triangle
HAND_B2 = {
    63: (13.0, 8.0, 43.0, 16.5),
    80: (15.0, 9.0, 35.0, 19.0),
    100: (18.0, 10.0, 30.0, 24.0),
    125: (23.0, 12.0, 32.0, 24.0),
    160: (17.0, 9.0, 26.0, 22.0),
    200: (15.0, 7.0, 24.0, 22.0),
    250: (14.0, 9.0, 22.0, 27.5),
    315: (16.0, 10.0, 23.0, 27.0),
    400: (18.0, 11.0, 24.0, 20.0),
    500: (19.5, 12.0, 25.0, 16.5),
    630: (17.0, 11.0, 23.0, 14.0),
    800: (18.0, 12.0, 24.0, 26.0),
    1000: (20.5, 13.0, 26.0, 25.0),
    1250: (20.0, 14.0, 28.0, 52.0),
    1600: (22.0, 15.0, 30.0, 60.0),
    2000: (25.5, 17.0, 35.0, 69.0),
    2500: (29.0, 19.0, 38.0, 69.0),
    3150: (32.0, 21.0, 41.0, 55.0),
    4000: (36.0, 24.0, 45.0, 48.0),
    5000: (34.0, 22.0, 44.0, 38.0),
    6300: (28.0, 18.0, 40.0, None),
    8000: (None, None, None, None),
}


def digitize(img_path: Path, out_csv: Path, title: str, envelope: str, hand=None):
    im = Image.open(img_path).convert("RGB")
    rgb = np.asarray(im)
    gray = rgb.mean(axis=2)
    draw = ImageDraw.Draw(im)
    tris = find_triangles(gray)
    tri_by_band = {}
    for mx, my, n in tris:
        f = 63.0 * 10 ** ((mx - X_F63) / (X_F8000 - X_F63) * (np.log10(8000) - np.log10(63)))
        b = min(BANDS, key=lambda bb: abs(np.log10(bb) - np.log10(max(f, 1))))
        if abs(np.log10(b) - np.log10(max(f, 1))) > 0.05:
            continue
        db = y_to_db(my)
        prev = tri_by_band.get(b)
        if prev is None or n < prev[1]:
            tri_by_band[b] = (db, n, mx, my)

    rows = []
    for b in BANDS:
        x = freq_to_x(b)
        mean_db, low_db, high_db = sample_column(gray, x)
        nasa = tri_by_band[b][0] if b in tri_by_band else None
        if b in tri_by_band:
            _, _, mx, my = tri_by_band[b]
            draw.ellipse([mx - 6, my - 6, mx + 6, my + 6], outline=(255, 0, 0))
        if mean_db is not None:
            draw.ellipse(
                [x - 4, db_to_y(mean_db) - 4, x + 4, db_to_y(mean_db) + 4], outline=(0, 180, 0)
            )
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
    # δ_dig vs hand if provided
    dmax = None
    if hand is not None:
        dmax = 0.0
        n = 0
        for r in rows:
            h = hand.get(r["band_Hz"])
            if not h or h[0] is None or r["measured_mean_dB"] == "":
                continue
            d = abs(float(r["measured_mean_dB"]) - float(h[0]))
            dmax = max(dmax, d)
            n += 1
        dmax_note = f"{dmax:.2f} dB over {n} bands"
    else:
        dmax_note = "n/a"

    with out_csv.open("w", newline="", encoding="utf-8") as f:
        f.write(f"# Source: CR-3813 {title}, Pain Methodology.pdf\n")
        f.write(f"# Envelope: {envelope}; PAIN = open triangles; η_T=1.0, η_struc≤0.15\n")
        f.write("# Method: pass B1 improved column sampler (solid densest / envelope outer ink)\n")
        f.write(f"# δ_dig vs hand pass B2 (means) = {dmax_note}\n")
        f.write("# Digitized 2026-10-21; script data/digitizers/dig_cr3813_e21_e22_passB.py\n")
        w = csv.DictWriter(
            f, fieldnames=["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"]
        )
        w.writeheader()
        for r in rows:
            w.writerow(r)
    print("wrote", out_csv, "δ_dig", dmax_note, "qa", qa)
    return rows, dmax


def write_hand(path: Path):
    rows = []
    for b in BANDS:
        h = HAND_B2.get(b, (None, None, None, None))
        m, lo, hi, nasa = h
        rows.append(
            dict(
                band_Hz=b,
                measured_mean_dB="" if m is None else f"{m:.2f}",
                low_dB="" if lo is None else f"{lo:.2f}",
                high_dB="" if hi is None else f"{hi:.2f}",
                nasa_pred_dB="" if nasa is None else f"{nasa:.2f}",
            )
        )
    with path.open("w", newline="", encoding="utf-8") as f:
        f.write("# E-21 pass B2 independent hand reading (grid eye)\n")
        f.write("# Digitized 2026-10-21; dig_cr3813_e21_e22_passB.py\n")
        w = csv.DictWriter(
            f, fieldnames=["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"]
        )
        w.writeheader()
        for r in rows:
            w.writerow(r)
    print("wrote", path)


def main():
    e21 = SCRATCH / "cr3813_e21e22-149.png"
    e22 = SCRATCH / "cr3813_e21e22-150.png"
    if not e21.exists():
        e21 = SCRATCH / "e21_e22-149.png"
        e22 = SCRATCH / "e21_e22-150.png"
    write_hand(CR3813 / "e21_noise_reduction_range_B2.csv")
    r21, d21 = digitize(
        e21,
        CR3813 / "e21_noise_reduction_range.csv",
        "Fig. E-21 (PDF p. 149 / printed E-33)",
        "measured max/min range",
        hand=HAND_B2,
    )
    # E-22: same sampler; CI envelope is tighter — still use outer ink as CI proxy
    r22, _ = digitize(
        e22,
        CR3813 / "e22_noise_reduction_ci.csv",
        "Fig. E-22 (PDF p. 150 / printed E-34)",
        "measured 95% confidence limits",
        hand=HAND_B2,
    )
    # Cross-check E-21 vs E-22 means
    dmax = 0.0
    for a, b in zip(r21, r22):
        if a["measured_mean_dB"] == "" or b["measured_mean_dB"] == "":
            continue
        dmax = max(dmax, abs(float(a["measured_mean_dB"]) - float(b["measured_mean_dB"])))
    print("max |mean_E21 - mean_E22| =", round(dmax, 2), "dB")
    if d21 is not None:
        print("PASS" if d21 <= 1.0 else "FAIL", f"δ_dig={d21:.2f} dB (criterion ≤ 1)")


if __name__ == "__main__":
    main()
