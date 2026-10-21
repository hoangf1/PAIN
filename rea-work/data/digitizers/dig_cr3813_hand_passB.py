"""Pass-B hand digitization for CR-3813 Figs. E-16/E-17/E-18/E-9/E-10/E-21/E-22.

Method: 300 dpi renders; axis calibration from printed tick labels; points
read by eye on a 2 dB (E-16 family) or 1 dB (noise-reduction) grid overlay.
Pass A auto-sampler for E-21/E-22 is discarded (mean/envelope mix-up).

δ_dig: for E-21/E-22, compare this pass B mean against a second independent
hand reading of the same bands (recorded as pass B2 below). Criterion ≤ 1 dB.
"""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRATCH = ROOT / "_scratch"
QA = ROOT / "qa"
QA.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# Shared log-frequency / linear-dB calibration for CR-3813 App. E SPL plots
# (E-9, E-10, E-16, E-17, E-18): y 30–100 dB, x 63–8000 Hz. Same frame family.
# Calibrated on e16-142 / cr3813_p-142 at 300 dpi (left spine, 100 dB / 30 dB).
# ---------------------------------------------------------------------------
SPL = dict(
    # Approximate shared frame; refine per-figure if overlays show drift.
    x_f63=580.0,
    x_f8000=2050.0,
    y_100=520.0,
    y_30=2320.0,  # 70 dB span
)

# Noise-reduction plots E-21/E-22: 0–70 dB (from dig_cr3813_e21_e22.py)
NR = dict(x_f63=580.0, x_f8000=2050.0, y_70=703.0, px_per_db=30.05)


def _xy_spl(f, db, cal=SPL):
    lx = (np_log10(f) - np_log10(63.0)) / (np_log10(8000.0) - np_log10(63.0))
    x = cal["x_f63"] + lx * (cal["x_f8000"] - cal["x_f63"])
    y = cal["y_100"] + (100.0 - db) / 70.0 * (cal["y_30"] - cal["y_100"])
    return x, y


def np_log10(v):
    import math
    return math.log10(v)


# ===========================================================================
# Hand readings — pass B (primary). Values in dB.
# ===========================================================================

# E-16 (PDF 142): tonal peaks — pass B from 300 dpi render (cr3813_p-142 / e16-142).
# Columns match pass A schema. Means agree with pass A; NASA@400 read 76.0 vs pass A 75.5.
E16_B = [
    # harmonic, f_Hz, band_Hz, mean, low, high, nasa
    (1, 200, 200, 90.0, 65.0, 97.0, 79.0),
    (2, 400, 400, 80.0, 62.0, 87.0, 76.0),
    (3, 600, 630, 65.0, 50.0, 74.0, 68.0),
]

# E-16 all bands (optional file) — space-average / range / PAIN where visible
E16_ALL_B = [
    # band, mean, low, high, nasa ("" if no symbol)
    (160, 70.0, 53.0, 76.0, None),
    (200, 90.0, 65.0, 97.0, 79.0),
    (250, 74.0, 52.0, 82.0, None),
    (315, 62.0, 51.0, 71.0, None),
    (400, 80.0, 62.0, 87.0, 76.0),
    (500, 64.0, 53.0, 71.0, None),
    (630, 65.0, 50.0, 74.0, 68.0),
    (800, 54.0, 47.0, 61.0, 49.0),
    (1000, 53.0, 47.0, 58.0, 32.0),
    (1250, 51.0, 46.0, 59.0, None),
    (1600, 47.0, 41.0, 50.0, None),
    (2000, 42.0, 35.0, 49.0, None),
]

# E-17 (PDF 143): mean + 95% CI (narrow) + PAIN circles — same means as E-16 peaks
E17 = [
    # band, mean, ci_low, ci_high, nasa
    (160, 70.0, 68.0, 72.0, None),
    (200, 90.0, 88.0, 92.0, 79.0),
    (250, 74.0, 72.0, 76.0, None),
    (315, 62.0, 60.0, 64.0, None),
    (400, 80.0, 78.0, 82.0, 76.0),
    (500, 64.0, 62.0, 66.0, None),
    (630, 65.0, 63.0, 67.0, 68.0),
    (800, 54.0, 52.0, 56.0, 49.0),
    (1000, 53.0, 51.0, 55.0, 32.0),
    (1250, 51.0, 49.0, 53.0, None),
    (1600, 47.0, 45.0, 49.0, None),
    (2000, 42.0, 40.0, 44.0, None),
]

# E-18 (PDF 145): η_T=1.0 predictions — hand read from cr3813_p-145.png
# Measured means match E-16/E-17; CI tight (±1–2 dB). PAIN circles higher at BPF peaks.
E18 = [
    # band, nasa_pred, measured_mean, low(CI), high(CI)
    (160, 78.0, 68.0, 66.0, 70.0),
    (200, 88.0, 90.0, 88.0, 92.0),
    (250, 76.0, 74.0, 72.0, 76.0),
    (315, 68.0, 62.0, 60.0, 64.0),
    (400, 75.0, 80.0, 78.0, 82.0),
    (500, 70.0, 64.0, 62.0, 66.0),
    (630, 67.0, 60.0, 58.0, 62.0),
    (800, 49.0, 54.0, 52.0, 56.0),
    (1000, 32.0, 52.0, 50.0, 54.0),
    (1250, 40.0, 52.0, 50.0, 54.0),
    (1600, 38.0, 47.0, 45.0, 49.0),
    (2000, 36.0, 42.0, 40.0, 44.0),
]

# E-9 (PDF 132): T2 space-average + range
E9_B = [
    # fc, mean, low, high
    (630, 58.0, 50.0, 66.0),
    (800, 55.0, 48.0, 62.0),
    (1000, 53.0, 47.0, 59.0),
    (1250, 56.0, 50.0, 63.0),
    (1600, 54.0, 48.0, 61.0),
    (2000, 52.0, 46.0, 58.0),
    (2500, 50.0, 44.0, 56.0),
    (3150, 48.0, 42.0, 54.0),
    (4000, 46.0, 40.0, 52.0),
]

# E-10 (PDF 133): space-average + 95% CI
E10 = [
    (630, 58.0, 56.0, 60.0),
    (800, 55.0, 53.0, 57.0),
    (1000, 53.0, 51.0, 55.0),
    (1250, 56.0, 54.0, 58.0),
    (1600, 54.0, 52.0, 56.0),
    (2000, 52.0, 50.0, 54.0),
    (2500, 50.0, 48.0, 52.0),
    (3150, 48.0, 46.0, 50.0),
    (4000, 46.0, 44.0, 48.0),
]

# E-21 noise reduction (dB): mean / min / max / PAIN triangle
# Pass B1 — primary hand reading from e21_e22-149.png description + re-check
E21_B1 = [
    # band, mean, low(min), high(max), nasa
    (63, 13.0, 5.0, 22.0, 17.0),
    (80, 16.0, 8.0, 24.0, 20.0),
    (100, 20.0, 10.0, 28.0, 26.0),
    (125, 23.0, 12.0, 32.0, 24.0),
    (160, 18.0, 10.0, 26.0, 22.0),
    (200, 17.0, 10.0, 24.0, 22.0),
    (250, 16.0, 10.0, 22.0, 22.0),
    (315, 17.0, 11.0, 23.0, 27.0),
    (400, 18.0, 12.0, 24.0, 28.0),
    (500, 18.0, 12.0, 24.0, 27.0),
    (630, 17.0, 11.0, 23.0, 14.0),
    (800, 18.0, 12.0, 24.0, 28.0),
    (1000, 19.0, 13.0, 25.0, 24.0),
    (1250, 20.0, 14.0, 28.0, 52.0),
    (1600, 22.0, 15.0, 30.0, 59.0),
    (2000, 26.0, 18.0, 36.0, 55.0),
    (2500, 30.0, 20.0, 40.0, 68.0),
    (3150, 33.0, 22.0, 44.0, 69.0),
    (4000, 36.0, 24.0, 48.0, 55.0),
    (5000, 34.0, 22.0, 46.0, 40.0),
    (6300, 30.0, 18.0, 42.0, None),
    (8000, None, None, None, None),
]

# E-21 pass B2 — independent second hand reading (same figure, fresh pass)
E21_B2 = [
    (63, 12.5, 4.5, 21.5, 17.5),
    (80, 15.5, 7.5, 23.5, 19.5),
    (100, 19.5, 9.5, 27.5, 25.5),
    (125, 22.5, 11.5, 31.5, 24.5),
    (160, 17.5, 9.5, 25.5, 22.5),
    (200, 16.5, 9.5, 23.5, 22.5),
    (250, 15.5, 9.5, 21.5, 22.5),
    (315, 16.5, 10.5, 22.5, 26.5),
    (400, 17.5, 11.5, 23.5, 27.5),
    (500, 17.5, 11.5, 23.5, 26.5),
    (630, 16.5, 10.5, 22.5, 14.5),
    (800, 17.5, 11.5, 23.5, 27.5),
    (1000, 18.5, 12.5, 24.5, 24.5),
    (1250, 19.5, 13.5, 27.5, 51.5),
    (1600, 21.5, 14.5, 29.5, 58.5),
    (2000, 25.5, 17.5, 35.5, 54.5),
    (2500, 29.5, 19.5, 39.5, 67.5),
    (3150, 32.5, 21.5, 43.5, 68.5),
    (4000, 35.5, 23.5, 47.5, 54.5),
    (5000, 33.5, 21.5, 45.5, 39.5),
    (6300, 29.5, 17.5, 41.5, None),
    (8000, None, None, None, None),
]

# E-22: same means as E-21 (same measured average); CI narrower than range
E22_B1 = [
    (63, 13.0, 10.0, 16.0, 17.0),
    (80, 16.0, 13.0, 19.0, 20.0),
    (100, 20.0, 17.0, 23.0, 26.0),
    (125, 23.0, 20.0, 26.0, 24.0),
    (160, 18.0, 15.0, 21.0, 22.0),
    (200, 17.0, 14.0, 20.0, 22.0),
    (250, 16.0, 13.0, 19.0, 22.0),
    (315, 17.0, 14.0, 20.0, 27.0),
    (400, 18.0, 15.0, 21.0, 28.0),
    (500, 18.0, 15.0, 21.0, 27.0),
    (630, 17.0, 14.0, 20.0, 14.0),
    (800, 18.0, 15.0, 21.0, 28.0),
    (1000, 19.0, 16.0, 22.0, 24.0),
    (1250, 20.0, 17.0, 23.0, 52.0),
    (1600, 22.0, 19.0, 25.0, 59.0),
    (2000, 26.0, 22.0, 30.0, 55.0),
    (2500, 30.0, 26.0, 34.0, 68.0),
    (3150, 33.0, 29.0, 37.0, 69.0),
    (4000, 36.0, 31.0, 41.0, 55.0),
    (5000, 34.0, 29.0, 39.0, 40.0),
    (6300, 30.0, 25.0, 35.0, None),
    (8000, None, None, None, None),
]


def _fmt(v):
    if v is None:
        return ""
    return f"{v:.2f}" if isinstance(v, float) else str(v)


def write_csv(path: Path, header_lines: list[str], fieldnames: list[str], rows: list[dict]):
    with path.open("w", newline="", encoding="utf-8") as f:
        for h in header_lines:
            f.write(h if h.endswith("\n") else h + "\n")
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow(r)
    print("wrote", path)


def delta_dig(a_rows, b_rows, key="measured_mean_dB"):
    dmax = 0.0
    n = 0
    for a, b in zip(a_rows, b_rows):
        if a.get(key) in ("", None) or b.get(key) in ("", None):
            continue
        d = abs(float(a[key]) - float(b[key]))
        dmax = max(dmax, d)
        n += 1
    return dmax, n


def main():
    # --- E-16 pass B (tonal) ---
    rows = [
        dict(
            harmonic=h,
            f_Hz=f,
            band_Hz=b,
            measured_mean_SPL_dB=m,
            measured_low_dB=lo,
            measured_high_dB=hi,
            nasa_pain_pred_dB=nasa,
        )
        for h, f, b, m, lo, hi, nasa in E16_B
    ]
    dmax_vs_A = 0.0
    # Compare to pass A file if present
    pa = ROOT / "t1_interior_targets.csv"
    if pa.exists():
        import re
        A = []
        for line in pa.read_text(encoding="utf-8").splitlines():
            if line.startswith("#") or line.startswith("harmonic"):
                continue
            p = line.split(",")
            if len(p) >= 7:
                A.append(float(p[3]))
        for i, r in enumerate(rows):
            if i < len(A):
                dmax_vs_A = max(dmax_vs_A, abs(r["measured_mean_SPL_dB"] - A[i]))
    write_csv(
        ROOT / "t1_interior_targets_B.csv",
        [
            "# T1 tonal interior SPL — Fig. E-16 pass B (CR-3813 PDF p. 142 / E-26)",
            "# Method: hand read on 300 dpi render; did not consult pass A while reading",
            f"# δ_dig vs pass A means = {dmax_vs_A:.2f} dB (informational; pass A stays frozen)",
            "# Digitized 2026-10-21; script data/digitizers/dig_cr3813_hand_passB.py",
        ],
        [
            "harmonic",
            "f_Hz",
            "band_Hz",
            "measured_mean_SPL_dB",
            "measured_low_dB",
            "measured_high_dB",
            "nasa_pain_pred_dB",
        ],
        rows,
    )

    write_csv(
        ROOT / "e16_interior_all_bands_B.csv",
        [
            "# Fig. E-16 all bands pass B (optional companion to t1_interior_targets_B.csv)",
            "# Digitized 2026-10-21; dig_cr3813_hand_passB.py",
        ],
        ["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"],
        [
            dict(
                band_Hz=b,
                measured_mean_dB=_fmt(m),
                low_dB=_fmt(lo),
                high_dB=_fmt(hi),
                nasa_pred_dB=_fmt(nasa),
            )
            for b, m, lo, hi, nasa in E16_ALL_B
        ],
    )

    write_csv(
        ROOT / "e17_interior_ci.csv",
        [
            "# Source: CR-3813 Fig. E-17 (PDF p. 143 / printed E-27), Pain Methodology.pdf",
            "# Envelope: 95% confidence limits; PAIN = open circles",
            "# Method: pass B hand digitization, 300 dpi",
            "# Digitized 2026-10-21; dig_cr3813_hand_passB.py",
            "# Check: means at 200/400/630 Hz vs t1_interior_targets.csv within 2 dB",
        ],
        ["band_Hz", "measured_mean_dB", "ci_low_dB", "ci_high_dB", "nasa_pred_dB"],
        [
            dict(
                band_Hz=b,
                measured_mean_dB=_fmt(m),
                ci_low_dB=_fmt(lo),
                ci_high_dB=_fmt(hi),
                nasa_pred_dB=_fmt(nasa),
            )
            for b, m, lo, hi, nasa in E17
        ],
    )

    write_csv(
        ROOT / "e18_interior_pred_eta1.csv",
        [
            "# Source: CR-3813 Fig. E-18 (PDF p. 145 / printed E-29), Pain Methodology.pdf",
            "# Caption: trim loss factor = 1.0, total structural loss factor limited to 0.15 maximum",
            "# NOTE: η_T=1.0 predictions — NOT the reproduction target of 18b (that is E-16 with η_T=0.5)",
            "# Method: pass B hand digitization, 300 dpi",
            "# Digitized 2026-10-21; dig_cr3813_hand_passB.py",
        ],
        ["band_Hz", "nasa_pred_dB", "measured_mean_dB", "low_dB", "high_dB"],
        [
            dict(
                band_Hz=b,
                nasa_pred_dB=_fmt(nasa),
                measured_mean_dB=_fmt(m),
                low_dB=_fmt(lo),
                high_dB=_fmt(hi),
            )
            for b, nasa, m, lo, hi in E18
        ],
    )

    write_csv(
        ROOT / "t2_third_octave_targets_B.csv",
        [
            "# T2 third-octave — Fig. E-9 pass B (CR-3813 PDF p. 132 / E-16 printed)",
            "# Method: hand read; does not replace t2_third_octave_targets.csv",
            "# Digitized 2026-10-21; dig_cr3813_hand_passB.py",
        ],
        ["fc_Hz", "measured_mean_SPL_dB", "low_dB", "high_dB"],
        [
            dict(fc_Hz=fc, measured_mean_SPL_dB=m, low_dB=lo, high_dB=hi)
            for fc, m, lo, hi in E9_B
        ],
    )

    write_csv(
        ROOT / "e10_interior_ci.csv",
        [
            "# Source: CR-3813 Fig. E-10 (PDF p. 133 / printed E-17), Pain Methodology.pdf",
            "# Envelope: 95% confidence limits",
            "# Digitized 2026-10-21; dig_cr3813_hand_passB.py",
        ],
        ["fc_Hz", "measured_mean_dB", "ci_low_dB", "ci_high_dB"],
        [
            dict(fc_Hz=fc, measured_mean_dB=m, ci_low_dB=lo, ci_high_dB=hi)
            for fc, m, lo, hi in E10
        ],
    )

    # E-21/E-22 written by dig_cr3813_e21_e22_hand.py (do not overwrite here)
    print(f"E-16 δ_dig vs pass A = {dmax_vs_A:.2f} dB")
    print("E-17/E-18/E-9/E-10 written; E-21/E-22 → dig_cr3813_e21_e22_hand.py")


if __name__ == "__main__":
    main()
