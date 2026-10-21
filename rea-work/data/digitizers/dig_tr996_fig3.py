"""C-12: digitize NACA Report 996 Fig. 3(c) NACA 4-(5)(08)-03 blade form.

Compares hand reading of Fig. 3(c) (PDF p. 9) with blade_form.csv
(NASA CR-196702 App. B-1). Nothing in blade_form.csv is changed.
"""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BF = ROOT / "report996" / "naca_4-5-08-03" / "blade_form.csv"
OUT = ROOT / "report996" / "tr996_fig3_blade_form.csv"

# Hand readings from Fig. 3(c) at r/R stations (b/D, h/b, beta_deg)
# Axes: b/D & h/b 0–0.20; β right axis ~32–72° (read from panel labels).
FIG3C = {
    0.30: (0.093, 0.170, 65.5),
    0.35: (0.092, 0.155, 62.5),
    0.40: (0.091, 0.140, 59.5),
    0.45: (0.090, 0.128, 56.5),
    0.50: (0.090, 0.118, 53.5),
    0.55: (0.089, 0.108, 50.5),
    0.60: (0.089, 0.100, 48.0),
    0.65: (0.088, 0.092, 45.5),
    0.70: (0.088, 0.085, 43.5),
    0.75: (0.087, 0.078, 42.0),
    0.80: (0.085, 0.070, 40.0),
    0.85: (0.080, 0.060, 38.0),
    0.90: (0.065, 0.052, 36.5),
    0.95: (0.040, 0.045, 35.0),
    1.00: (0.000, 0.040, 34.0),
}


def load_blade_form():
    rows = {}
    with BF.open(encoding="utf-8") as f:
        rdr = csv.DictReader(f)
        for row in rdr:
            rR = float(row["r_over_R"])
            cR = float(row["c_over_R"])
            tc = float(row["t_over_c"])
            beta = float(row["beta_deg"])
            # c/R = 2·b/D  ⇒  b/D = c/R / 2;  h/b = t/c
            rows[round(rR, 3)] = (cR / 2.0, tc, beta)
    return rows


def nearest(bf, rR):
    keys = list(bf.keys())
    k = min(keys, key=lambda x: abs(x - rR))
    return k, bf[k]


def main():
    bf = load_blade_form()
    diffs = []
    out_rows = []
    for rR, (bd, hb, beta) in FIG3C.items():
        k, (bd_ref, hb_ref, beta_ref) = nearest(bf, rR)
        d_bd = abs(bd - bd_ref)
        d_hb = abs(hb - hb_ref)
        d_beta = abs(beta - beta_ref)
        diffs.append((rR, d_bd, d_hb, d_beta, k))
        out_rows.append(
            dict(
                r_over_R=f"{rR:.2f}",
                b_over_D=f"{bd:.4f}",
                h_over_b=f"{hb:.4f}",
                beta_deg=f"{beta:.1f}",
                b_over_D_blade_form=f"{bd_ref:.4f}",
                h_over_b_blade_form=f"{hb_ref:.4f}",
                beta_deg_blade_form=f"{beta_ref:.3f}",
                blade_form_r_over_R=f"{k:.3f}",
            )
        )

    max_bd = max(d[1] for d in diffs)
    max_hb = max(d[2] for d in diffs)
    max_beta = max(d[3] for d in diffs)

    with OUT.open("w", newline="", encoding="utf-8") as f:
        f.write("# Source: NACA Report 996 Fig. 3(c) NACA 4-(5)(08)-03 (PDF p. 9 / printed p. 5)\n")
        f.write("# Method: hand digitization of Fig. 3(c); compared to blade_form.csv (App. B-1)\n")
        f.write(
            f"# max |Δ(b/D)|={max_bd:.4f}, max |Δ(h/b)|={max_hb:.4f}, max |Δβ|={max_beta:.2f}°\n"
        )
        f.write("# Digitized 2026-10-21; script data/digitizers/dig_tr996_fig3.py\n")
        f.write("# Note: nothing in blade_form.csv is changed by this comparison\n")
        w = csv.DictWriter(
            f,
            fieldnames=[
                "r_over_R",
                "b_over_D",
                "h_over_b",
                "beta_deg",
                "b_over_D_blade_form",
                "h_over_b_blade_form",
                "beta_deg_blade_form",
                "blade_form_r_over_R",
            ],
        )
        w.writeheader()
        for r in out_rows:
            w.writerow(r)
    print("wrote", OUT)
    print(f"max |Δ(b/D)|={max_bd:.4f}, max |Δ(h/b)|={max_hb:.4f}, max |Δβ|={max_beta:.2f}°")


if __name__ == "__main__":
    main()
