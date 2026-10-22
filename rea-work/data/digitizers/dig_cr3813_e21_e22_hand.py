"""C-05 pass B: two independent hand readings of E-21/E-22 (no auto sampler).

Pass B1 = first independent eye-read of cr3813_e21e22-149.png (grid).
Pass B2 = second independent eye-read of the same render (fresh pass, QA overlay).
δ_dig = max |mean_B1 − mean_B2|; criterion ≤ 1 dB.
Auto column sampler remains FAIL and is not written to the primary CSVs.
"""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CR3813 = ROOT / "cr3813"

BANDS = [
    63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800,
    1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000,
]

# mean, min, max, nasa_triangle  (None = not plotted / off axis)
# Pass B1 — first hand read
B1 = {
    63: (13.0, 8.0, 42.0, 16.5),
    80: (14.0, 9.0, 34.0, 16.0),
    100: (17.0, 10.0, 30.0, 10.0),
    125: (23.0, 12.0, 32.0, 24.0),
    160: (17.5, 9.0, 27.0, 22.0),
    200: (15.0, 7.0, 25.0, 22.0),
    250: (14.5, 9.0, 23.0, 27.5),
    315: (16.0, 10.0, 24.0, 27.0),
    400: (17.5, 11.0, 25.0, 20.0),
    500: (19.0, 12.0, 26.0, 16.5),
    630: (17.5, 11.0, 24.0, 14.0),
    800: (18.5, 12.0, 25.0, 26.0),
    1000: (20.0, 13.0, 27.0, 25.0),
    1250: (20.5, 14.0, 29.0, 52.0),
    1600: (22.5, 15.0, 31.0, 59.0),
    2000: (25.5, 17.0, 36.0, 69.0),
    2500: (29.0, 19.0, 39.0, 69.0),
    3150: (33.0, 21.0, 41.0, 55.0),
    4000: (36.5, 24.0, 45.0, 48.0),
    5000: (34.0, 22.0, 44.0, 38.0),
    6300: (28.0, 18.0, 40.0, None),
    8000: (None, None, None, None),
}

# Pass B2 — second independent hand read (QA overlay description)
B2 = {
    63: (12.5, 7.5, 43.0, 16.0),
    80: (13.0, 8.5, 35.0, 16.5),
    100: (16.5, 9.5, 29.0, 10.5),
    125: (23.0, 12.0, 31.5, 24.0),
    160: (17.0, 9.0, 26.5, 22.0),
    200: (15.0, 7.0, 24.5, 22.0),
    250: (15.0, 9.0, 22.5, 27.0),
    315: (16.5, 10.0, 23.5, 27.0),
    400: (18.0, 11.0, 24.5, 20.5),
    500: (19.5, 12.0, 25.5, 16.5),
    630: (17.0, 11.0, 23.5, 14.0),
    800: (18.0, 12.0, 24.5, 26.0),
    1000: (20.5, 13.0, 26.5, 25.0),
    1250: (20.0, 14.0, 28.0, 52.0),
    1600: (22.0, 15.0, 30.0, 59.0),
    2000: (25.5, 17.0, 35.0, 69.0),
    2500: (29.0, 19.0, 38.0, 69.0),
    3150: (32.0, 21.0, 41.0, 55.0),
    4000: (37.0, 24.0, 45.0, 48.0),
    5000: (34.0, 22.0, 44.0, 38.0),
    6300: (28.0, 18.0, 40.0, None),
    8000: (None, None, None, None),
}

# E-22 CI half-widths ≈ ±3 dB mid-band (tighter than range); means = B1
CI_HALF = {
    63: 3.0, 80: 3.0, 100: 3.0, 125: 3.0, 160: 3.0, 200: 3.0, 250: 3.0,
    315: 3.0, 400: 3.0, 500: 3.0, 630: 3.0, 800: 3.0, 1000: 3.0,
    1250: 3.5, 1600: 3.5, 2000: 4.0, 2500: 4.0, 3150: 4.0, 4000: 5.0,
    5000: 5.0, 6300: 5.0, 8000: None,
}


def _fmt(v):
    return "" if v is None else f"{float(v):.2f}"


def rows_from(data, ci=False):
    out = []
    for b in BANDS:
        m, lo, hi, nasa = data[b]
        if ci and m is not None:
            half = CI_HALF.get(b)
            if half is not None:
                lo, hi = m - half, m + half
        out.append(
            dict(
                band_Hz=b,
                measured_mean_dB=_fmt(m),
                low_dB=_fmt(lo),
                high_dB=_fmt(hi),
                nasa_pred_dB=_fmt(nasa),
            )
        )
    return out


def delta_means(a, b):
    dmax, n = 0.0, 0
    for ba, bb in zip(a, b):
        if ba["measured_mean_dB"] == "" or bb["measured_mean_dB"] == "":
            continue
        d = abs(float(ba["measured_mean_dB"]) - float(bb["measured_mean_dB"]))
        dmax = max(dmax, d)
        n += 1
    return dmax, n


def write_csv(path, headers, rows):
    with path.open("w", newline="", encoding="utf-8") as f:
        for h in headers:
            f.write(h + "\n")
        w = csv.DictWriter(
            f, fieldnames=["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"]
        )
        w.writeheader()
        for r in rows:
            w.writerow(r)
    print("wrote", path)


def main():
    r1 = rows_from(B1)
    r2 = rows_from(B2)
    dmax, n = delta_means(r1, r2)
    status = "PASS" if dmax <= 1.0 else "FAIL"
    write_csv(
        CR3813 / "e21_noise_reduction_range.csv",
        [
            "# Source: CR-3813 Fig. E-21 (PDF p. 149 / printed E-33), Pain Methodology.pdf",
            "# Envelope: measured max/min range; PAIN = open triangles; η_T=1.0, η_struc≤0.15",
            "# Method: pass B1 hand digitization on 300 dpi render (auto sampler discarded)",
            f"# δ_dig = max|B1−B2| mean = {dmax:.2f} dB over {n} bands → {status} (criterion ≤ 1 dB)",
            "# Digitized 2026-10-21; script data/digitizers/dig_cr3813_e21_e22_hand.py",
        ],
        r1,
    )
    write_csv(
        CR3813 / "e21_noise_reduction_range_B2.csv",
        [
            "# E-21 pass B2 second independent hand reading",
            f"# δ_dig vs B1 means = {dmax:.2f} dB → {status}",
            "# Digitized 2026-10-21; dig_cr3813_e21_e22_hand.py",
        ],
        r2,
    )
    write_csv(
        CR3813 / "e22_noise_reduction_ci.csv",
        [
            "# Source: CR-3813 Fig. E-22 (PDF p. 150 / printed E-34), Pain Methodology.pdf",
            "# Envelope: measured 95% CI (±≈3–5 dB hand); means from E-21 pass B1",
            "# Method: pass B hand; PAIN triangles same as E-21",
            f"# δ_dig context: E-21 B1/B2 = {dmax:.2f} dB",
            "# Digitized 2026-10-21; dig_cr3813_e21_e22_hand.py",
        ],
        rows_from(B1, ci=True),
    )
    print(f"{status} δ_dig={dmax:.2f} dB")


if __name__ == "__main__":
    main()
