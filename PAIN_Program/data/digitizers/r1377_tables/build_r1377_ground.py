"""ISSUE-048 (2026-11-23): compare the two reads of NACA Report 1377 Tables I and II (ground tests), check the
conditions against the table's own arithmetic, and write data/report1377/tables_I_II_ground.csv.

Run from this folder:  python build_r1377_ground.py
Same checks as build_r1377_tables.py (BPF, M_inf, M_R, M_t; printed values kept, a disagreement is flagged).
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_r1377_tables import COLS, D_FT, GEAR, rows
from r1377_ground_read import PASS_A, PASS_B_C1, PASS_B_C2, PASS_B_L


def pass_a(blade):
    out = []
    for ln in PASS_A[blade].strip().splitlines():
        cond, lev = ln.split("|")
        out.append(cond.split() + lev.split())
    return out


def pass_b(blade):
    c1, c2, lv = rows(PASS_B_C1[blade]), rows(PASS_B_C2[blade]), rows(PASS_B_L[blade])
    assert len(c1) == len(c2) == len(lv), (blade, len(c1), len(c2), len(lv))
    return [a + b + c for a, b, c in zip(c1, c2, lv)]


def num(s):
    return None if s in ("-", "a") else float(s)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    out_csv = os.path.normpath(os.path.join(here, "..", "..", "report1377", "tables_I_II_ground.csv"))
    lines, n_diff, flags = [], 0, []
    for blade, table in (("tapered", "I"), ("rectangular", "II")):
        A, B = pass_a(blade), pass_b(blade)
        assert len(A) == len(B), (blade, len(A), len(B))
        for i, (ra, rb) in enumerate(zip(A, B), 1):
            assert len(ra) == len(rb) == len(COLS), (blade, i, len(ra), len(rb))
            for c, va, vb in zip(COLS, ra, rb):
                if va != vb:
                    n_diff += 1
                    print(f"pass disagreement: {blade} row {i} {c}: A {va}, B {vb}")
            v = dict(zip(COLS, (num(s) for s in ra)))
            a = math.sqrt(1.4 * 1716.5 * (v["t_F"] + 459.67))
            n_p = GEAR * v["N_rpm"] / 60
            checks = {
                "BPF": (4 * n_p, v["BPF_cps"], 0.2),
                "M_inf": (v["V_fps"] / a, v["M_inf"], 0.015),
                "M_R": (math.pi * D_FT * n_p / a, v["M_R"], 0.015),
                "M_t": (math.hypot(v["M_inf"], v["M_R"]), v["M_t"], 0.015),
            }
            bad = [f"{k} printed {p:g}, computed {c:.3f}" for k, (c, p, tol) in checks.items() if abs(c - p) > tol]
            if bad:
                flags.append(f"{blade} row {i}: " + "; ".join(bad))
            lines.append(",".join([blade, table, str(i)] + ra + ["; ".join(bad) if bad else "ok"]))
    print(f"{n_diff} pass disagreements")
    for f in flags:
        print("arithmetic:", f)
    head = [
        "# NACA Report 1377 (Kurbjun, Vogeley 1958), Tables I (tapered blades, PDF p. 8) and II (rectangular blades, top of PDF p. 10):",
        "# ground tests (static), boom microphone at y = 0.655 D from the propeller axis, x positive forward of the disk.",
        "# Transcribed 2026-11-23 (ISSUE-048) by eye in two passes (250 dpi by block, 300 dpi by column group);",
        f"# {n_diff} disagreements between the passes. Harmonics 1-5 only (6-10 printed, not read). '-' = blank in the print;",
        "# 'a' = footnote a, 'Lost due to infiltration of extraneous noise at receiving station'. Table II prints no p_inf ('-').",
        "# Units as printed: T thrust lb, V ft/s, p_inf lb/sq ft, t_inf deg F, P engine power hp, N engine rpm (propeller 0.479 N),",
        "# M_R rotational and M_t helical tip Mach number, BPF blade-passage frequency cps; levels dB re 0.0002 dyne/cm^2 (20 uPa).",
        "# arithmetic_check as in tables_I_II_flight.csv. Script build_r1377_ground.py.",
        "blade,table,row," + ",".join(COLS) + ",arithmetic_check",
    ]
    with open(out_csv, "w", newline="\n") as fh:
        fh.write("\n".join(head + lines) + "\n")
    print(f"wrote {out_csv}: {len(lines)} rows")


if __name__ == "__main__":
    main()
