"""Phase 74a (rule fixed 2026-10-28 before any value was read; IMPLEMENTATION_PLAN.md §8r): Pereira et al. Fig. 9
(PDF p. 10) read from the PDF vector graphics. Every bar is a filled rectangle; series by fill colour; panel by
position; harmonic by bar order within the panel; SPL from the bar top against the drawn tick marks; ΔSPL from the
zero line. Check: ΔSPL(series − BEMT) read from the lower panel equals the SPL difference from the upper panel within
0.5 dB wherever the ΔSPL bar is not clipped at ±10 dB.

Run from rea-work: python -I data/digitizers/dig_pereira_fig9_vector.py references/Pereira.pdf data/pereira/pereira_fig9_harmonics.csv
"""
import csv, sys
import pymupdf

SERIES = {(0.0, 0.0, 0.0): "BEMT", (0.64, 0.08, 0.18): "Numerical", (0.0, 0.45, 0.74): "Experimental"}
# Panel frames in PDF points (x0, x1; SPL frame top, 50 dB tick, bottom; ΔSPL top (+10), zero, bottom (−10)),
# from the drawn frame lines and tick marks.
PANELS = {
    "a": dict(phi=0, x=(97.2, 295.1), spl=(60.7, 96.3, 117.7), dspl=(151.9, 180.1, 208.4)),
    "b": dict(phi=20, x=(328.1, 526.0), spl=(60.7, 96.3, 117.7), dspl=(151.9, 180.1, 208.4)),
    "c": dict(phi=40, x=(212.7, 410.6), spl=(248.9, 284.5, 305.9), dspl=(340.1, 368.4, 396.6)),
}


def series_of(fill):
    key = tuple(round(c, 2) for c in fill)
    return SERIES.get(key)


def main(pdf, out):
    page = pymupdf.open(pdf)[9]
    bars = []
    for g in page.get_drawings():
        f = g.get("fill")
        if f is None or series_of(f) is None:
            continue
        for it in g["items"]:
            r = it[1] if it[0] == "re" else (it[1].rect if it[0] == "qu" else None)
            if r is not None:
                bars.append((series_of(f), r))
    rows, issues = [], []
    for name, P in PANELS.items():
        x0, x1 = P["x"]
        top, t50, bot = P["spl"]
        k_spl = (t50 - top) / 50.0                       # pt per dB
        dtop, zero, dbot = P["dspl"]
        k_d = (zero - dtop) / 10.0
        spl, dspl = {}, {}
        for s, r in bars:
            cx = (r.x0 + r.x1) / 2
            if not (x0 < cx < x1):
                continue
            if abs(r.y1 - bot) < 0.6 and r.y0 > top - 0.6:           # SPL bar standing on the frame bottom
                spl.setdefault(s, []).append((cx, 100.0 - (r.y0 - top) / k_spl))
            elif dtop - 0.6 <= r.y0 and r.y1 <= dbot + 0.6 and (abs(r.y1 - zero) < 0.6 or abs(r.y0 - zero) < 0.6):
                v = (zero - r.y0) / k_d if abs(r.y1 - zero) < 0.6 else -(r.y1 - zero) / k_d
                dspl.setdefault(s, []).append((cx, v))
        for s in SERIES.values():
            v = sorted(spl.get(s, []))
            if len(v) != 10:
                issues.append(f"panel {name} {s}: {len(v)} SPL bars (expected 10)")
            spl[s] = [y for _, y in v]
            dspl[s] = sorted(dspl.get(s, []))
        for s in ("Numerical", "Experimental"):
            if len(dspl[s]) != 10:
                issues.append(f"panel {name} {s}: {len(dspl[s])} ΔSPL bars (expected 10; a zero-height bar is not drawn)")
        for h in range(10):
            for s in ("BEMT", "Numerical", "Experimental"):
                if h >= len(spl[s]):
                    continue
                d = 0.0
                flag = ""
                if s != "BEMT":
                    # match the ΔSPL bar of this harmonic by x order; fall back to the SPL difference if missing
                    cand = [v for cx, v in dspl[s]]
                    d = cand[h] if len(cand) == 10 else spl[s][h] - spl["BEMT"][h]
                    diff = spl[s][h] - spl["BEMT"][h]
                    if abs(abs(d) - 10.0) < 0.05:
                        flag = "Delta_SPL clipped at the frame (+/-10)"
                    elif abs(d - diff) > 0.5:
                        issues.append(f"panel {name} H{h+1} {s}: ΔSPL {d:.2f} vs SPL difference {diff:.2f}")
                rows.append(dict(panel=name, phi_deg=P["phi"], harmonic=h + 1, series=s,
                                 SPL_dB=round(spl[s][h], 2), dSPL_vs_BEMT_dB=round(d, 2), flag=flag))
    with open(out, "w", newline="", encoding="utf-8") as f:
        f.write("# Source: Pereira et al., Aerosp. Sci. Technol. 177 (2026) 112963, Fig. 9, PDF p. 10\n")
        f.write("# Method: PDF vector graphics (bar rectangles), data/digitizers/dig_pereira_fig9_vector.py; Phase 74a, 2026-10-28.\n")
        f.write("# Axis from the drawn ticks: SPL 100 dB at the top tick, 50 dB at the second (frame bottom 20 dB); ΔSPL ±10 dB frame, 5 dB ticks.\n")
        f.write("# Replaces the 2026-10-21 WebPlotDigitizer reading (pereira_fig9_harmonics_pre74.csv), whose H1 = 80 dB was a misreading.\n")
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)
    print(f"wrote {out}: {len(rows)} rows; check issues: {len(issues)}")
    for i in issues:
        print("  ", i)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
