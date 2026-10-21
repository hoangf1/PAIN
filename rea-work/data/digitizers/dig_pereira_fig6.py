"""Card C-02: Pereira Fig. 6 spectrum peaks at H1–H4 of BPF=266.7 Hz (PDF p. 7)."""
from __future__ import annotations
import csv
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
IMG = ROOT / "_scratch" / "pereira_p7.png"
OUT = ROOT / "pereira" / "pereira_fig6_peaks.csv"
QA = ROOT / "pereira" / "qa"
QA.mkdir(parents=True, exist_ok=True)

BPF = 2 * 8000 / 60  # 266.666… Hz
# Panel plot areas (300 dpi). x: log f 100–10000; y: SPL 0–80.
# Calibrated roughly from page layout; refine if QA fails.
PANELS = {
    "a": dict(phi=0, box=(180, 400, 1200, 1100)),
    "b": dict(phi=20, box=(1280, 400, 2300, 1100)),
    "c": dict(phi=40, box=(700, 1200, 1750, 1900)),
}
SERIES = {
    "BEMT": dict(thr=lambda R, G, B: (np.maximum(np.maximum(R, G), B) < 80)),
    "Numerical": dict(thr=lambda R, G, B: ((R - G) > 60) & (R > 100)),
    "Experimental": dict(thr=lambda R, G, B: ((B - R) > 60) & (B > 110)),
}


def x_of_f(f, x0, x1, f0=100.0, f1=10000.0):
    return x0 + (np.log10(f) - np.log10(f0)) / (np.log10(f1) - np.log10(f0)) * (x1 - x0)


def f_of_x(x, x0, x1, f0=100.0, f1=10000.0):
    t = (x - x0) / max(x1 - x0, 1)
    return 10 ** (np.log10(f0) + t * (np.log10(f1) - np.log10(f0)))


def y_to_spl(y, y0, y1, s0=80.0, s1=0.0):
    return s0 + (y - y0) / max(y1 - y0, 1) * (s1 - s0)


def main():
    rgb = np.asarray(Image.open(IMG).convert("RGB"))
    R, G, B = rgb[:, :, 0].astype(int), rgb[:, :, 1].astype(int), rgb[:, :, 2].astype(int)
    qa = Image.open(IMG).convert("RGB")
    draw = ImageDraw.Draw(qa)
    rows = []
    fig9 = ROOT / "pereira" / "pereira_fig9_harmonics.csv"
    fig9_map = {}
    if fig9.exists():
        import csv as _csv
        with fig9.open(encoding="utf-8") as f:
            for line in f:
                if line.startswith("#") or line.startswith("panel"):
                    continue
                p = line.strip().split(",")
                if len(p) >= 5 and p[4]:
                    fig9_map[(p[0], int(p[2]), p[3])] = float(p[4])

    for pname, meta in PANELS.items():
        x0, y0, x1, y1 = meta["box"]
        for series, spec in SERIES.items():
            mask = spec["thr"](R, G, B)
            for h in range(1, 5):
                f_nom = h * BPF
                # search ±5% in x
                xa = int(x_of_f(f_nom * 0.95, x0, x1))
                xb = int(x_of_f(f_nom * 1.05, x0, x1))
                best_y, best_x = None, None
                for x in range(max(xa, x0), min(xb, x1) + 1):
                    col = mask[y0 : y1 + 1, x]
                    if not col.any():
                        continue
                    ys = np.where(col)[0] + y0
                    # curve: take uppermost dark pixel in band (peak)
                    top = int(ys.min())
                    if best_y is None or top < best_y:
                        best_y, best_x = top, x
                if best_y is None:
                    spl, freq, flag = None, f_nom, "missing"
                else:
                    spl = round(y_to_spl(best_y, y0, y1), 2)
                    freq = round(f_of_x(best_x, x0, x1), 1)
                    flag = ""
                    draw.ellipse([best_x - 3, best_y - 3, best_x + 3, best_y + 3], outline=(255, 0, 0))
                    key = (pname, h, series)
                    if key in fig9_map and abs(spl - fig9_map[key]) > 2.0:
                        flag = "vs_fig9_gt_2dB"
                rows.append(
                    dict(
                        panel=pname,
                        phi_deg=meta["phi"],
                        series=series,
                        harmonic=h,
                        freq_Hz=freq,
                        SPL_dB=spl,
                        flag=flag,
                    )
                )

    with OUT.open("w", newline="", encoding="utf-8") as f:
        f.write(
            "# Source: Pereira et al. Aerosp. Sci. Technol. 177 (2026) 112963, Fig. 6, PDF p. 7 (printed p. 7)\n"
        )
        f.write(
            "# Method: pass A, 300 dpi, color-mask local max within ±5% of m·BPF (266.7 Hz); x log 100–10k, y SPL 0–80\n"
        )
        f.write("# Uncertainty: ~2 dB (spectrum line thickness + log-x); vs Fig.9 flagged if >2 dB\n")
        f.write("# Digitized 2026-10-21 by agent; script data/digitizers/dig_pereira_fig6.py\n")
        f.write("# Conventions: peak SPL of tonal line; panels a/b/c = phi 0/20/40\n")
        w = csv.DictWriter(
            f, fieldnames=["panel", "phi_deg", "series", "harmonic", "freq_Hz", "SPL_dB", "flag"]
        )
        w.writeheader()
        for r in rows:
            w.writerow({k: ("" if r.get(k) is None else r[k]) for k in w.fieldnames})
    qa.save(QA / "pereira_fig6_overlay.png")
    print("wrote", OUT, "n=", len(rows), "missing", sum(1 for r in rows if "missing" in (r.get("flag") or "")))


if __name__ == "__main__":
    main()
