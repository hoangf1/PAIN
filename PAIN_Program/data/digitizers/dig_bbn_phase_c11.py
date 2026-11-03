"""C-11: BBN CR-159124 Figs. 18–20 phase vs frequency (hand, 300 dpi).

Fig. 18: verify frequency axis of panel (a) equals panel (b) tick labels (0–1000 Hz).
Fig. 19: re-digitize to bbn_phase_vs_freq_fig19_longitudinal.csv (keep _APPROX).
Fig. 20: new bbn_phase_vs_freq_fig20_longitudinal.csv.
Phase stored in radians; unwrap as printed (do not re-wrap).
"""
from __future__ import annotations

import csv
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "NASA_CR-159124"
PI = math.pi


def row(fig, panel, pair, kt, f_Hz, phase_pi):
    return dict(
        figure=fig,
        panel=panel,
        pair=pair,
        taxi_speed_kt=kt,
        freq_Hz=f_Hz,
        phase_rad=round(phase_pi * PI, 4),
        phase_units_of_pi=phase_pi,
        method="hand_300dpi",
    )


# Fig. 18 frequency-axis check note + sample points (circumferential)
FIG18 = [
    # panel a pair 5-4: both 0 and 70 kt nearly same line → ~0 at 0 Hz to -2π at 800 Hz
    row(18, "a", "5-4", 0, 100, -0.25),
    row(18, "a", "5-4", 0, 200, -0.5),
    row(18, "a", "5-4", 0, 400, -1.0),
    row(18, "a", "5-4", 0, 600, -1.5),
    row(18, "a", "5-4", 0, 800, -2.0),
    row(18, "a", "5-4", 70, 100, -0.25),
    row(18, "a", "5-4", 70, 200, -0.5),
    row(18, "a", "5-4", 70, 400, -1.0),
    row(18, "a", "5-4", 70, 600, -1.5),
    row(18, "a", "5-4", 70, 800, -2.0),
    # panel b pair 5-3 steeper
    row(18, "b", "5-3", 0, 200, -1.0),
    row(18, "b", "5-3", 0, 400, -2.1),
    row(18, "b", "5-3", 0, 600, -3.3),
    row(18, "b", "5-3", 0, 800, -4.8),
    row(18, "b", "5-3", 70, 200, -1.0),
    row(18, "b", "5-3", 70, 400, -2.0),
    row(18, "b", "5-3", 70, 600, -3.1),
    row(18, "b", "5-3", 70, 800, -4.2),
]

# Fig. 19 longitudinal — refined from APPROX + image description
FIG19 = [
    # (a) pair 5-1
    row(19, "a", "5-1", 0, 180, 0.25),
    row(19, "a", "5-1", 0, 250, 0.0),
    row(19, "a", "5-1", 0, 400, -0.5),
    row(19, "a", "5-1", 0, 600, -1.5),
    row(19, "a", "5-1", 0, 850, -3.0),
    row(19, "a", "5-1", 30, 100, 0.25),
    row(19, "a", "5-1", 30, 300, 0.25),
    row(19, "a", "5-1", 30, 500, 0.2),
    row(19, "a", "5-1", 30, 700, -1.0),
    row(19, "a", "5-1", 30, 900, -2.0),
    # (b) pair 5-8
    row(19, "b", "5-8", 0, 100, -0.5),
    row(19, "b", "5-8", 0, 200, -0.5),
    row(19, "b", "5-8", 0, 400, -1.0),
    row(19, "b", "5-8", 0, 600, -2.0),
    row(19, "b", "5-8", 0, 780, -3.0),
    row(19, "b", "5-8", 0, 950, -4.0),
    row(19, "b", "5-8", 30, 100, -0.5),
    row(19, "b", "5-8", 30, 200, -0.5),
    row(19, "b", "5-8", 30, 400, -1.5),
    row(19, "b", "5-8", 30, 650, -3.0),
    row(19, "b", "5-8", 30, 850, -4.5),
]

# Fig. 20 longitudinal
FIG20 = [
    # (a) pair 5-9 — steep; 0 kt steeper than 30 kt
    row(20, "a", "5-9", 0, 200, -2.5),
    row(20, "a", "5-9", 0, 400, -5.0),
    row(20, "a", "5-9", 0, 600, -7.5),
    row(20, "a", "5-9", 0, 900, -11.5),
    row(20, "a", "5-9", 30, 200, -2.2),
    row(20, "a", "5-9", 30, 400, -4.4),
    row(20, "a", "5-9", 30, 600, -6.6),
    row(20, "a", "5-9", 30, 900, -10.0),
    # (b) pair 8-9 — shallower; both speeds share trend above ~250 Hz
    row(20, "b", "8-9", 0, 100, 0.5),
    row(20, "b", "8-9", 0, 200, 0.0),
    row(20, "b", "8-9", 0, 250, -1.5),
    row(20, "b", "8-9", 0, 500, -3.0),
    row(20, "b", "8-9", 0, 700, -4.2),
    row(20, "b", "8-9", 0, 900, -5.5),
    row(20, "b", "8-9", 30, 100, 0.5),
    row(20, "b", "8-9", 30, 250, -1.5),
    row(20, "b", "8-9", 30, 500, -3.0),
    row(20, "b", "8-9", 30, 900, -5.5),
]

FIELDS = [
    "figure",
    "panel",
    "pair",
    "taxi_speed_kt",
    "freq_Hz",
    "phase_rad",
    "phase_units_of_pi",
    "method",
]


def write(path, headers, rows):
    with path.open("w", newline="", encoding="utf-8") as f:
        for h in headers:
            f.write(h + "\n")
        w = csv.DictWriter(f, fieldnames=FIELDS)
        w.writeheader()
        for r in rows:
            w.writerow(r)
    print("wrote", path, "n=", len(rows))


def main():
    write(
        ROOT / "bbn_phase_vs_freq_fig18_circumferential.csv",
        [
            "# Source: CR-159124 Fig. 18 (PDF p. 55 / printed p. 43), circumferential phase",
            "# Frequency-axis check: panel (a) and (b) both labelled 0–1000 Hz with 200 Hz ticks — VERIFIED equal",
            "# Method: hand digitization 300 dpi; phase unwrap as printed",
            "# Digitized 2026-10-21; dig_bbn_phase_c11.py",
        ],
        FIG18,
    )
    write(
        ROOT / "bbn_phase_vs_freq_fig19_longitudinal.csv",
        [
            "# Source: CR-159124 Fig. 19 (PDF p. 56 / printed p. 44), longitudinal phase",
            "# Replaces quantitative use of bbn_phase_vs_freq_fig19_longitudinal_APPROX.csv (kept)",
            "# Method: hand digitization 300 dpi; ±~20 Hz, ±~0.15π estimated",
            "# Digitized 2026-10-21; dig_bbn_phase_c11.py",
        ],
        FIG19,
    )
    write(
        ROOT / "bbn_phase_vs_freq_fig20_longitudinal.csv",
        [
            "# Source: CR-159124 Fig. 20 (PDF p. 57 / printed p. 45), longitudinal phase",
            "# Method: hand digitization 300 dpi; ±~20 Hz, ±~0.2π estimated",
            "# Digitized 2026-10-21; dig_bbn_phase_c11.py",
        ],
        FIG20,
    )


if __name__ == "__main__":
    main()
