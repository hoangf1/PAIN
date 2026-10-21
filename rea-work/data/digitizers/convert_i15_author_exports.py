"""I-15: convert author's 2026-10-21 WebPlotDigitizer exports to card schema CSVs.

Does not change any digitized value. Records I-15 (a)–(g) answers in headers.
B-2 band fixes already applied in the .txt files before this conversion.
"""
from __future__ import annotations

import csv
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PEREIRA = ROOT / "pereira"
BBN = ROOT / "NASA_CR-159124"
PI = math.pi


def write_csv(path: Path, headers: list[str], fieldnames: list[str], rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        for h in headers:
            f.write(h if h.endswith("\n") else h + "\n")
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow({k: ("" if r.get(k) is None else r[k]) for k in fieldnames})
    print("wrote", path)


def blank(v: str) -> bool:
    return v is None or str(v).strip() == ""


def num_or_blank(v: str):
    if blank(v):
        return ""
    return float(v)


def convert_e16() -> None:
    src = ROOT / "Fig E-16.txt"
    rows_all = []
    with src.open(encoding="utf-8") as f:
        r = csv.DictReader(f)
        for row in r:
            b = float(row["ONE-THIRD OCTAVE BAND CENTER FREQUENCY, HZ"])
            rows_all.append(
                dict(
                    band_Hz=int(b) if b == int(b) else b,
                    measured_mean_dB=num_or_blank(row["SPACE-AVERAGE SPL"]),
                    low_dB=num_or_blank(row["MIN. MEASURED VALUES"]),
                    high_dB=num_or_blank(row["MAX. MEASURED VALUES"]),
                    nasa_pred_dB=num_or_blank(row["PAIN PREDICTION"]),
                )
            )
    hdr = [
        "# Source: CR-3813 Fig. E-16, PDF p. 142 (printed E-26), Pain Methodology.pdf",
        "# Method: author, WebPlotDigitizer; converted from data/Fig E-16.txt (I-15); values unchanged",
        "# Uncertainty: author digitization; see raw export beside this file",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
        "# Conventions: dB re 20 µPa; space-average SPL; NASA PAIN = open circles where present",
        "# I-15 notes: (a)–(c) band alignment fixed in .txt before conversion (B-2); pass A t1_interior_targets.csv stays frozen",
    ]
    write_csv(
        ROOT / "e16_interior_all_bands_B.csv",
        hdr,
        ["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"],
        rows_all,
    )
    # Tonal H1/H2/H3 bands (200/400/630)
    want = {200: 1, 400: 2, 630: 3}
    tonal = []
    for row in rows_all:
        b = int(float(row["band_Hz"]))
        if b in want:
            tonal.append(
                dict(
                    harmonic=want[b],
                    f_Hz=b if b != 630 else 600,
                    band_Hz=b,
                    measured_mean_SPL_dB=row["measured_mean_dB"],
                    measured_low_dB=row["low_dB"],
                    measured_high_dB=row["high_dB"],
                    nasa_pain_pred_dB=row["nasa_pred_dB"],
                )
            )
    write_csv(
        ROOT / "t1_interior_targets_B.csv",
        hdr
        + [
            "# Schema: second pass of T1 targets (D-17); does not replace data/t1_interior_targets.csv",
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
        tonal,
    )


def convert_e17() -> None:
    src = ROOT / "Fig E-17.txt"
    rows = []
    with src.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            b = float(row["Frequency (Hz)"])
            rows.append(
                dict(
                    band_Hz=int(b) if b == int(b) else b,
                    measured_mean_dB=num_or_blank(row["Space-Average SPL (dB)"]),
                    ci_low_dB=num_or_blank(row["Lower 95% Confidence Limit (dB)"]),
                    ci_high_dB=num_or_blank(row["Upper 95% Confidence Limit (dB)"]),
                    nasa_pred_dB=num_or_blank(row["Pain Prediction (dB)"]),
                )
            )
    write_csv(
        ROOT / "e17_interior_ci.csv",
        [
            "# Source: CR-3813 Fig. E-17, PDF p. 143 (printed E-27), Pain Methodology.pdf",
            "# Method: author, WebPlotDigitizer; converted from data/Fig E-17.txt (I-15); values unchanged",
            "# Uncertainty: author digitization",
            "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
            "# Conventions: 95% CI envelope; PAIN = open circles",
            "# I-15: replaces void agent file (I-03)",
        ],
        ["band_Hz", "measured_mean_dB", "ci_low_dB", "ci_high_dB", "nasa_pred_dB"],
        rows,
    )


def convert_e18() -> None:
    src = ROOT / "Fig E-18.txt"
    rows = []
    with src.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            b = float(row["Frequency (Hz)"])
            rows.append(
                dict(
                    band_Hz=int(b) if b == int(b) else b,
                    nasa_pred_dB=num_or_blank(row["Pain Prediction (dB)"]),
                    measured_mean_dB=num_or_blank(row["Space-Average SPL (dB)"]),
                    low_dB=num_or_blank(row["Lower 95% CL (dB)"]),
                    high_dB=num_or_blank(row["Upper 95% CL (dB)"]),
                )
            )
    write_csv(
        ROOT / "e18_interior_pred_eta1.csv",
        [
            "# Source: CR-3813 Fig. E-18, PDF p. 145 (printed E-29), Pain Methodology.pdf",
            "# Method: author, WebPlotDigitizer; converted from data/Fig E-18.txt (I-15); values unchanged",
            "# NOTE: η_T=1.0 predictions — NOT the reproduction target of 18b (that is E-16 with η_T=0.5)",
            "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
            "# I-15 (b): band alignment fixed in .txt before conversion (B-2); blanks at 160 and 630 Hz measured = not read",
            "# Conventions: blank cells left empty (not invented)",
        ],
        ["band_Hz", "nasa_pred_dB", "measured_mean_dB", "low_dB", "high_dB"],
        rows,
    )


def convert_e9_e10() -> None:
    src9 = ROOT / "Fig E-9.txt"
    rows9 = []
    with src9.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            fc = float(row["Frequency (Hz)"])
            rows9.append(
                dict(
                    fc_Hz=int(fc) if fc == int(fc) else fc,
                    measured_mean_SPL_dB=num_or_blank(row["Space-Average SPL (dB)"]),
                    low_dB=num_or_blank(row["Min Measured Values (dB)"]),
                    high_dB=num_or_blank(row["Max Measured Values (dB)"]),
                )
            )
    write_csv(
        ROOT / "t2_third_octave_targets_B.csv",
        [
            "# Source: CR-3813 Fig. E-9, PDF p. 132 (printed E-16), Pain Methodology.pdf",
            "# Method: author, WebPlotDigitizer; converted from data/Fig E-9.txt (I-15); values unchanged",
            "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
            "# I-15 (a): band column fixed in .txt before conversion (B-2); does not replace t2_third_octave_targets.csv",
            "# Conventions: second pass of T2 envelope; pass A stays frozen",
        ],
        ["fc_Hz", "measured_mean_SPL_dB", "low_dB", "high_dB"],
        rows9,
    )
    src10 = ROOT / "Fig E-10.txt"
    rows10 = []
    with src10.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            fc = float(row["Frequency (Hz)"])
            rows10.append(
                dict(
                    fc_Hz=int(fc) if fc == int(fc) else fc,
                    measured_mean_dB=num_or_blank(row["Space-Average SPL (dB)"]),
                    ci_low_dB=num_or_blank(row["Lower 95% Confidence Limit (dB)"]),
                    ci_high_dB=num_or_blank(row["Upper 95% Confidence Limit (dB)"]),
                )
            )
    write_csv(
        ROOT / "e10_interior_ci.csv",
        [
            "# Source: CR-3813 Fig. E-10, PDF p. 133 (printed E-17), Pain Methodology.pdf",
            "# Method: author, WebPlotDigitizer; converted from data/Fig E-10.txt (I-15); values unchanged",
            "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
            "# I-15 (c): 250/315 Hz values swapped in .txt before conversion (B-2)",
            "# Conventions: 95% CI envelope",
        ],
        ["fc_Hz", "measured_mean_dB", "ci_low_dB", "ci_high_dB"],
        rows10,
    )


def convert_e21_e22() -> None:
    src21 = ROOT / "Fig E-21.txt"
    rows21 = []
    with src21.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            b = float(row["Frequency (Hz)"])
            rows21.append(
                dict(
                    band_Hz=int(b) if b == int(b) else b,
                    measured_mean_dB=num_or_blank(row["Space-Average Noise Reduction (dB)"]),
                    low_dB=num_or_blank(row["Min Measured Values (dB)"]),
                    high_dB=num_or_blank(row["Max Measured Values (dB)"]),
                    nasa_pred_dB=num_or_blank(row["Pain Noise Reduction (dB)"]),
                )
            )
    write_csv(
        ROOT / "e21_noise_reduction_range.csv",
        [
            "# Source: CR-3813 Fig. E-21, PDF p. 149 (printed E-33), Pain Methodology.pdf",
            "# Method: author, WebPlotDigitizer; converted from data/Fig E-21.txt (I-15); values unchanged",
            "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
            "# I-15 (g): at 100 Hz minimum equals average (16 dB) as read; single author pass (no independent B2 in export)",
            "# Conventions: envelope = measured max/min; PAIN = open triangles",
        ],
        ["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"],
        rows21,
    )
    src22 = ROOT / "Fig E-22.txt"
    rows22 = []
    with src22.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            b = float(row["Frequency_Hz"])
            rows22.append(
                dict(
                    band_Hz=int(b) if b == int(b) else b,
                    measured_mean_dB=num_or_blank(row["Space_Average_Noise_Reduction_dB"]),
                    low_dB=num_or_blank(row["95_Confidence_Lower_dB"]),
                    high_dB=num_or_blank(row["95_Confidence_Upper_dB"]),
                    nasa_pred_dB=num_or_blank(row["Pain_Noise_Reduction_dB"]),
                )
            )
    write_csv(
        ROOT / "e22_noise_reduction_ci.csv",
        [
            "# Source: CR-3813 Fig. E-22, PDF p. 150 (printed E-34), Pain Methodology.pdf",
            "# Method: author, WebPlotDigitizer; converted from data/Fig E-22.txt (I-15); values unchanged",
            "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
            "# Conventions: 95% CI envelope; PAIN triangles",
        ],
        ["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"],
        rows22,
    )


def convert_pereira_fig9() -> None:
    files = {
        0: ("a", PEREIRA / "Pereira Fig. 9 Deg=0.txt"),
        20: ("b", PEREIRA / "Pereira Fig. 9 Deg=20.txt"),
        40: ("c", PEREIRA / "Pereira Fig. 9 Deg=40.txt"),
    }
    rows = []
    for phi, (panel, path) in files.items():
        with path.open(encoding="utf-8") as f:
            for row in csv.DictReader(f):
                h = int(float(row["BPF_Harmonic_Number"]))
                bemt = float(row["SPL_BEMT_dB"])
                num = float(row["SPL_Numerical_dB"])
                exp = float(row["SPL_Experimental_dB"])
                d_num = float(row["Delta_SPL_Numerical_dB"])
                d_exp = float(row["Delta_SPL_Experimental_dB"])
                flag = ""
                if h == 1 and bemt == 80 and num == 80 and exp == 80:
                    flag = "I-15(d): H1 bars read 80 dB all series; accepted by author 2026-10-21; Fig.8 vs Fig.9 H1 scatter recorded at phase 28"
                if abs(d_num) >= 10 or abs(d_exp) >= 10:
                    flag = (flag + "; " if flag else "") + "Delta_SPL at frame limit (±10)"
                rows.append(
                    dict(
                        panel=panel,
                        phi_deg=phi,
                        harmonic=h,
                        series="BEMT",
                        SPL_dB=bemt,
                        dSPL_vs_BEMT_dB=0.0,
                        flag=flag,
                    )
                )
                rows.append(
                    dict(
                        panel=panel,
                        phi_deg=phi,
                        harmonic=h,
                        series="Numerical",
                        SPL_dB=num,
                        dSPL_vs_BEMT_dB=d_num,
                        flag=flag,
                    )
                )
                rows.append(
                    dict(
                        panel=panel,
                        phi_deg=phi,
                        harmonic=h,
                        series="Experimental",
                        SPL_dB=exp,
                        dSPL_vs_BEMT_dB=d_exp,
                        flag=flag,
                    )
                )
    write_csv(
        PEREIRA / "pereira_fig9_harmonics.csv",
        [
            "# Source: Pereira et al., Aerosp. Sci. Technol. 177 (2026) 112963, Fig. 9, PDF p. 10 (printed p. 10)",
            "# Method: author, WebPlotDigitizer; converted from Pereira Fig. 9 Deg=0/20/40.txt (I-15); values unchanged",
            "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
            "# I-15 (d)/(e): H1=80 dB accepted as read; Fig. 8 = pereira_fig8_directivity.csv (pixel); H1 Fig.8 vs Fig.9 scatter for phase 28",
            "# Conventions: SPL dB as plotted; dSPL_vs_BEMT from author Delta columns (Numerical/Experimental); BEMT dSPL=0",
        ],
        ["panel", "phi_deg", "harmonic", "series", "SPL_dB", "dSPL_vs_BEMT_dB", "flag"],
        rows,
    )


def convert_pereira_fig6() -> None:
    bpf = 2 * 8000 / 60.0  # 266.666... Hz
    files = {
        0: ("a", PEREIRA / "Fig 6a.txt"),
        20: ("b", PEREIRA / "Fig 6b.txt"),
        40: ("c", PEREIRA / "Fig 6c.txt"),
    }
    series_cols = [
        ("BEMT", "BEMT_SPL_dB"),
        ("Numerical", "Numerical_SPL_dB"),
        ("Experimental", "Experimental_SPL_dB"),
    ]
    rows = []
    for phi, (panel, path) in files.items():
        pts = []
        with path.open(encoding="utf-8") as f:
            for row in csv.DictReader(f):
                pts.append(
                    {
                        "f": float(row["Frequency_Hz"]),
                        "BEMT": float(row["BEMT_SPL_dB"]),
                        "Numerical": float(row["Numerical_SPL_dB"]),
                        "Experimental": float(row["Experimental_SPL_dB"]),
                    }
                )
        for H in range(1, 5):
            f0 = H * bpf
            for series, _ in series_cols:
                cands = [p for p in pts if abs(p["f"] - f0) / f0 <= 0.05]
                if not cands:
                    rows.append(
                        dict(
                            panel=panel,
                            phi_deg=phi,
                            series=series,
                            harmonic=H,
                            freq_Hz="",
                            SPL_dB="",
                            flag="no_point_within_5pct_of_mBPF",
                        )
                    )
                    continue
                best = max(cands, key=lambda p: p[series])
                rows.append(
                    dict(
                        panel=panel,
                        phi_deg=phi,
                        series=series,
                        harmonic=H,
                        freq_Hz=round(best["f"], 3),
                        SPL_dB=best[series],
                        flag="",
                    )
                )
    write_csv(
        PEREIRA / "pereira_fig6_peaks.csv",
        [
            "# Source: Pereira et al., Aerosp. Sci. Technol. 177 (2026) 112963, Fig. 6, PDF p. 7 (printed p. 7)",
            "# Method: author curve export Fig 6a/b/c.txt; peaks = max in ±5% of m·BPF (BPF=266.667 Hz); curve values unchanged",
            "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
            "# Conventions: local maximum of each series near harmonic; cross-check vs Fig.9 recorded at phase 28, not corrected",
        ],
        ["panel", "phi_deg", "series", "harmonic", "freq_Hz", "SPL_dB", "flag"],
        rows,
    )


def convert_bbn_fig19_20() -> None:
    # Fig 19: Plot,Speed,Type,Frequency,Phase (pi rad)
    rows19 = []
    with (BBN / "Fig 19.txt").open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            panel = str(row["Plot"]).strip()
            pair = "5-1" if panel == "a" else "5-8"
            kt = float(row["Speed (Knots)"])
            f_Hz = float(row["Frequency (Hz)"])
            phase_pi = float(row["Phase (pi rad)"])
            rows19.append(
                dict(
                    figure=19,
                    panel=panel,
                    pair=pair,
                    taxi_speed_kt=int(kt) if kt == int(kt) else kt,
                    freq_Hz=f_Hz,
                    phase_rad=round(phase_pi * PI, 6),
                    phase_units_of_pi=phase_pi,
                    point_or_line=row["Type"],
                    method="author_WebPlotDigitizer",
                )
            )
    write_csv(
        BBN / "bbn_phase_vs_freq_fig19_longitudinal.csv",
        [
            "# Source: NASA CR-159124 Fig. 19, longitudinal phase vs frequency",
            "# Method: author, WebPlotDigitizer; converted from Fig 19.txt (I-15); values unchanged",
            "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
            "# Conventions: phase_rad = phase_units_of_pi × π; Point and Line series both kept; pair a→5-1, b→5-8",
            "# Note: agent _APPROX and void circumferential files remain unused (I-03/I-16)",
        ],
        [
            "figure",
            "panel",
            "pair",
            "taxi_speed_kt",
            "freq_Hz",
            "phase_rad",
            "phase_units_of_pi",
            "point_or_line",
            "method",
        ],
        rows19,
    )
    rows20 = []
    with (BBN / "Fig 20.txt").open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            pair_raw = row["Microphone Pair"].replace("Microphone Pair ", "").strip()
            speed = row["Wind Speed"].replace(" Knots", "").strip()
            kt = float(speed)
            f_Hz = float(row["Frequency (Hz)"])
            phase_pi = float(row["Phase Angle (pi Radians)"])
            rows20.append(
                dict(
                    figure=20,
                    panel="-",
                    pair=pair_raw,
                    taxi_speed_kt=int(kt) if kt == int(kt) else kt,
                    freq_Hz=f_Hz,
                    phase_rad=round(phase_pi * PI, 6),
                    phase_units_of_pi=phase_pi,
                    point_or_line="Point",
                    method="author_WebPlotDigitizer",
                )
            )
    write_csv(
        BBN / "bbn_phase_vs_freq_fig20_longitudinal.csv",
        [
            "# Source: NASA CR-159124 Fig. 20, longitudinal phase vs frequency",
            "# Method: author, WebPlotDigitizer; converted from Fig 20.txt (I-15); values unchanged",
            "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.py",
            "# Conventions: phase_rad = phase_units_of_pi × π",
        ],
        [
            "figure",
            "panel",
            "pair",
            "taxi_speed_kt",
            "freq_Hz",
            "phase_rad",
            "phase_units_of_pi",
            "point_or_line",
            "method",
        ],
        rows20,
    )


def main() -> None:
    convert_e16()
    convert_e17()
    convert_e18()
    convert_e9_e10()
    convert_e21_e22()
    convert_pereira_fig9()
    convert_pereira_fig6()
    convert_bbn_fig19_20()
    print("I-15 conversion complete")


if __name__ == "__main__":
    main()
