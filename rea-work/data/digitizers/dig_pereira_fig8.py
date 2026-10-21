"""Card C-03: digitize Pereira Fig. 8 polar directivity (PDF p. 9).

Six panels (a–f) = BPF harmonics 1–6. φ: 0° = rotation plane (+x);
+φ = downstream (U∞ up = −image y). Seven markers/series at
φ = −20…40° step 10°.

Method: density-peak marker detection on colour masks; polar origin fitted
so peaks land on the 10° grid; SPL from labelled ring ranges (equal radial
spacing between r_inner and r_outer). Absolute levels are those of Fig. 8
rings — do **not** force-match Fig. 9 (pass-A QA: H1 Exp φ=0 is ~11 dB
below Fig. 9 / Fig. 7 peak; recorded in header and flags).
"""
from __future__ import annotations

import csv
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "pereira" / "pereira_fig8_directivity.csv"
QA = ROOT / "pereira" / "qa"
QA.mkdir(parents=True, exist_ok=True)
IMG = ROOT / "_scratch" / "pereira_p9.png"
FIG9 = ROOT / "pereira" / "pereira_fig9_harmonics.csv"

# Panel boxes (y0,y1,x0,x1) and labelled SPL rings from the printed figure.
PANELS = {
    "a": dict(harmonic=1, box=(420, 920, 280, 920), r_inner_dB=60.0, r_outer_dB=90.0),
    "b": dict(harmonic=2, box=(420, 920, 980, 1620), r_inner_dB=50.0, r_outer_dB=80.0),
    "c": dict(harmonic=3, box=(420, 920, 1680, 2350), r_inner_dB=40.0, r_outer_dB=70.0),
    "d": dict(harmonic=4, box=(1120, 1720, 250, 920), r_inner_dB=20.0, r_outer_dB=50.0),
    "e": dict(harmonic=5, box=(1120, 1720, 980, 1620), r_inner_dB=20.0, r_outer_dB=50.0),
    "f": dict(harmonic=6, box=(1120, 1720, 1680, 2350), r_inner_dB=20.0, r_outer_dB=50.0),
}

PHIS = [-20, -10, 0, 10, 20, 30, 40]
TARGETS = np.array(PHIS, dtype=float)


def masks(rgb):
    R, G, B = rgb[:, :, 0].astype(int), rgb[:, :, 1].astype(int), rgb[:, :, 2].astype(int)
    return {
        "BEMT": (np.maximum(np.maximum(R, G), B) < 85)
        & ((np.maximum(np.maximum(R, G), B) - np.minimum(np.minimum(R, G), B)) < 40),
        "Numerical": ((R - G) > 40) & (R > 95) & ((R - B) > 12),
        "Experimental": ((B - R) > 35) & (B > 90) & ((B - G) > 15),
    }


def box_blur(a, r):
    ii = np.pad(a.cumsum(0).cumsum(1), ((1, 0), (1, 0)))
    H, W = a.shape
    out = np.zeros_like(a)
    for y in range(H):
        y0 = max(0, y - r)
        y1 = min(H, y + r + 1)
        for x in range(W):
            x0 = max(0, x - r)
            x1 = min(W, x + r + 1)
            s = ii[y1, x1] - ii[y0, x1] - ii[y1, x0] + ii[y0, x0]
            out[y, x] = s / ((y1 - y0) * (x1 - x0))
    return out


def density_peaks(mask, y0, y1, x0, x1, thr=0.22, sep=11):
    sub = mask[y0:y1, x0:x1].astype(float)
    blur = box_blur(sub, 4)
    peaks = []
    for i in range(3, sub.shape[0] - 3):
        for j in range(3, sub.shape[1] - 3):
            v = blur[i, j]
            if v < thr:
                continue
            if v >= blur[i - 3 : i + 4, j - 3 : j + 4].max() - 1e-9:
                peaks.append((j + x0, i + y0, float(v)))
    peaks.sort(key=lambda p: -p[2])
    kept = []
    for p in peaks:
        if all(np.hypot(p[0] - q[0], p[1] - q[1]) > sep for q in kept):
            kept.append(p)
    return kept


def fit_origin(peaks, box):
    y0, y1, x0, x1 = box
    strong = [p for p in peaks if p[2] >= 0.55] or peaks[:10]
    best = None
    for cx in range(x0 + 40, x0 + 280, 3):
        for cy in range(y0 + 80, y1 - 80, 3):
            phis, rs = [], []
            for mx, my, v in strong:
                r = np.hypot(mx - cx, my - cy)
                phi = np.rad2deg(np.arctan2(-(my - cy), mx - cx))
                if 60 < r < 320 and -70 < phi < 70:
                    phis.append(phi)
                    rs.append(r)
            if len(phis) < 4:
                continue
            err = 0.0
            for phi in phis:
                err += float(np.min(np.abs(TARGETS - phi)) ** 2)
            err += 0.05 * (7 - min(len(phis), 7)) ** 2
            if best is None or err < best[0]:
                best = (err, cx, cy, max(rs) * 1.05)
    return best


def assign_phis(peaks, cx, cy, r_outer):
    """Nearest target φ for each peak in range; keep strongest per target."""
    best = {int(t): None for t in PHIS}
    for mx, my, v in peaks:
        r = np.hypot(mx - cx, my - cy)
        phi = np.rad2deg(np.arctan2(-(my - cy), mx - cx))
        if not (50 < r < r_outer * 1.15 and -55 <= phi <= 55):
            continue
        t = int(TARGETS[int(np.argmin(np.abs(TARGETS - phi)))])
        if abs(phi - t) > 8:
            continue
        prev = best[t]
        if prev is None or v > prev[2]:
            best[t] = (mx, my, v, r, phi)
    return best


def load_fig9():
    rows = {}
    if not FIG9.exists():
        return rows
    with FIG9.open(encoding="utf-8") as f:
        for line in f:
            if line.startswith("#") or line.startswith("panel"):
                continue
            p = line.strip().split(",")
            if len(p) < 5 or not p[4]:
                continue
            rows[(int(p[1]), int(p[2]), p[3])] = float(p[4])
    return rows


def main():
    rgb_im = Image.open(IMG).convert("RGB")
    rgb = np.asarray(rgb_im)
    m = masks(rgb)
    draw = ImageDraw.Draw(rgb_im)
    fig9 = load_fig9()
    # Inner-ring fraction of outer radius (equal 10 dB rings: 4 labels → inner at ~0.4 of outer
    # after leaving a dead zone at the hub). Tuned so panel-a Exp φ≈0 reads ~76–78 (visual).
    frac = 0.42

    rows = []
    origins = {}
    for pname, meta in PANELS.items():
        box = meta["box"]
        # Fit origin on Experimental peaks (usually densest); fall back to Numerical/BEMT
        fit = None
        for series_try in ("Experimental", "Numerical", "BEMT"):
            thr = 0.12 if series_try == "BEMT" else 0.18
            pk = density_peaks(m[series_try], *box, thr=thr)
            fit = fit_origin(pk, box)
            if fit is not None:
                break
        if fit is None and pname == "f" and "e" in origins:
            # panel f: reuse e's cy/r with x shifted into this box
            _ecx, ecy, er = origins["e"]
            cx = (box[2] + box[3]) // 2 - 80
            fit = (0.0, cx, ecy, er)
            print("panel", pname, "origin from neighbour e")
        if fit is None:
            print("FAIL fit", pname)
            continue
        _, cx, cy, r_outer = fit
        origins[pname] = (cx, cy, r_outer)
        r_inner_px = r_outer * frac
        draw.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], outline=(0, 180, 0))
        draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(255, 0, 0))

        for series, color in (("BEMT", (0, 0, 0)), ("Numerical", (220, 0, 0)), ("Experimental", (0, 0, 220))):
            peaks = density_peaks(m[series], *box, thr=0.18 if series != "BEMT" else 0.12)
            assigned = assign_phis(peaks, cx, cy, r_outer)
            for phi in PHIS:
                hit = assigned[phi]
                flag = ""
                spl = None
                if hit is None:
                    flag = "missing"
                else:
                    mx, my, v, r, phi_raw = hit
                    t = (r - r_inner_px) / max(r_outer - r_inner_px, 1.0)
                    spl = round(meta["r_inner_dB"] + t * (meta["r_outer_dB"] - meta["r_inner_dB"]), 2)
                    draw.ellipse([mx - 4, my - 4, mx + 4, my + 4], outline=color, width=2)
                    if abs(phi_raw - phi) > 4:
                        flag = f"phi_raw={round(phi_raw, 1)}"
                key9 = (phi, meta["harmonic"], series)
                if spl is not None and key9 in fig9:
                    d = round(spl - fig9[key9], 2)
                    if abs(d) > 2:
                        flag = (flag + f";vs_fig9_d={d}").strip(";")
                rows.append(
                    dict(
                        panel=pname,
                        harmonic=meta["harmonic"],
                        series=series,
                        phi_deg=phi,
                        SPL_dB=spl,
                        r_inner_dB=meta["r_inner_dB"],
                        r_outer_dB=meta["r_outer_dB"],
                        flag=flag,
                    )
                )

    qa = QA / "pereira_fig8_overlay.png"
    rgb_im.save(qa)
    h1 = next(
        (
            r
            for r in rows
            if r["panel"] == "a" and r["phi_deg"] == 0 and r["series"] == "Experimental"
        ),
        None,
    )
    with OUT.open("w", newline="", encoding="utf-8") as f:
        f.write(
            "# Source: Pereira et al. Aerosp. Sci. Technol. 177 (2026) 112963, Fig. 8, PDF p. 9\n"
        )
        f.write(
            "# Method: pass A, 300 dpi, colour density peaks → polar; φ=0=+x, +φ downstream\n"
        )
        f.write(
            f"# Rings: labelled ranges per panel; inner_frac={frac}; origins={ {k: (round(v[0]), round(v[1]), round(v[2])) for k, v in origins.items()} }\n"
        )
        f.write(
            f"# QA vs Fig.9: H1 Exp φ=0 Fig.8={None if h1 is None else h1['SPL_dB']} vs Fig.9=88.95 "
            f"(~11 dB low on Fig.8 ring scale; Fig.9 matches Fig.7 peak 87.2). Card check ±2 dB FAILS — do not blend.\n"
        )
        f.write("# Digitized 2026-10-21 by agent; script data/digitizers/dig_pereira_fig8.py\n")
        w = csv.DictWriter(
            f,
            fieldnames=["panel", "harmonic", "series", "phi_deg", "SPL_dB", "r_inner_dB", "r_outer_dB", "flag"],
        )
        w.writeheader()
        for r in rows:
            w.writerow({k: ("" if r.get(k) is None else r[k]) for k in w.fieldnames})

    n_ok = sum(1 for r in rows if r["SPL_dB"] is not None)
    n_bad = sum(1 for r in rows if "vs_fig9" in (r.get("flag") or ""))
    print("origins", origins)
    print("wrote", OUT, "ok", n_ok, "/", len(rows), "vs_fig9_flags", n_bad, "H1exp0", h1)
    for r in rows:
        if r["panel"] == "a" and r["series"] == "Experimental":
            print(r)


if __name__ == "__main__":
    main()
