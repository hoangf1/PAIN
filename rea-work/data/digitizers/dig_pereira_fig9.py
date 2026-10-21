"""Card C-01: digitize Pereira Fig. 9 (PDF p. 10).
Fixed harmonic centres + color bar-top sampling. SPL axis 50–100 dB (labelled).
"""
from __future__ import annotations
import csv
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "pereira" / "pereira_fig9_harmonics.csv"
QA = ROOT / "pereira" / "qa"
QA.mkdir(parents=True, exist_ok=True)
IMG = ROOT / "_scratch" / "pereira_p10.png"

# Panel geometry (300 dpi). Numerical H1 centre + pitch; series offsets left-to-right.
# Panel (a) H8–H10 x overlaps panel (b) → only H1–H7 sampled for (a)/(b) upper row;
# (c) uses its own origin. Calibrated 2026-10-21 against axis rules + Fig.7 H1.
PANELS = {
    "a": dict(
        phi=0,
        num_h1=528,
        pitch=82.5,
        off={"BEMT": -18, "Numerical": 0, "Experimental": 18},
        h_max=7,  # H8+ collides with panel b
        spl_y=(300, 490, 100.0, 50.0),
        dspl_y=(510, 750, 10.0, -10.0),
        dspl_zero=632,
    ),
    "b": dict(
        phi=20,
        num_h1=1490,  # first tall Numerical bar (not legend)
        pitch=82.5,
        off={"BEMT": -18, "Numerical": 0, "Experimental": 18},
        h_max=7,
        spl_y=(300, 490, 100.0, 50.0),
        dspl_y=(510, 750, 10.0, -10.0),
        dspl_zero=632,
    ),
    "c": dict(
        phi=40,
        num_h1=927,
        pitch=82.0,
        off={"BEMT": -18, "Numerical": 0, "Experimental": 18},
        h_max=7,
        spl_y=(1090, 1274, 100.0, 50.0),
        dspl_y=(1290, 1534, 10.0, -10.0),
        dspl_zero=1363,
    ),
}


def masks(rgb):
    R, G, B = rgb[:, :, 0].astype(int), rgb[:, :, 1].astype(int), rgb[:, :, 2].astype(int)
    return {
        "BEMT": (np.maximum(np.maximum(R, G), B) < 80)
        & ((np.maximum(np.maximum(R, G), B) - np.minimum(np.minimum(R, G), B)) < 40),
        "Numerical": ((R - G) > 60) & (R > 100) & ((R - B) > 20),
        "Experimental": ((B - R) > 60) & (B > 110),
    }


def y_to_val(y, y_top, y_bot, v_top, v_bot):
    return v_top + (y - y_top) / max(y_bot - y_top, 1) * (v_bot - v_top)


def sample_spl(mask, x, y_top, y_bot):
    """Bar top: uppermost mask pixel in a thin column that reaches near baseline."""
    best = None
    for dx in range(-3, 4):
        xx = x + dx
        if xx < 0 or xx >= mask.shape[1]:
            continue
        col = mask[y_top : y_bot + 1, xx]
        if col.sum() < 4:
            continue
        ys = np.where(col)[0] + y_top
        if ys.max() < y_bot - 18:
            continue
        groups = np.split(ys, np.where(np.diff(ys) > 5)[0] + 1)
        bg = [g for g in groups if g.max() >= y_bot - 22]
        if not bg:
            continue
        top = int(max(bg, key=len).min())
        if best is None or top < best:
            best = top
    return best


def sample_dspl(mask, x, y_top, y_bot, zero_y):
    best_tip, best_ext = None, -1
    for dx in range(-3, 4):
        xx = x + dx
        if xx < 0 or xx >= mask.shape[1]:
            continue
        col = mask[y_top : y_bot + 1, xx]
        if col.sum() < 2:
            continue
        ys = np.where(col)[0] + y_top
        if np.min(np.abs(ys.astype(float) - zero_y)) > 30:
            continue
        tip = int(ys[np.argmax(np.abs(ys.astype(float) - zero_y))])
        ext = abs(tip - zero_y)
        if ext > best_ext:
            best_ext, best_tip = ext, tip
    return best_tip


def probe_num_h1(mask_red, y_top, y_bot, x_lo, x_hi):
    """Find first tall red bar mid in range (= Numerical H1)."""
    x = x_lo
    while x < x_hi:
        col = mask_red[y_top : y_bot + 1, x]
        if col.sum() < 20:
            x += 1
            continue
        ys = np.where(col)[0] + y_top
        if ys.max() < y_bot - 20 or ys.min() > y_top + 80:
            x += 1
            continue
        x2 = x
        while x2 < x_hi and mask_red[y_top : y_bot + 1, x2].sum() >= 15:
            x2 += 1
        return (x + x2 - 1) // 2
    return None


def main():
    rgb_im = Image.open(IMG).convert("RGB")
    rgb = np.asarray(rgb_im)
    m = masks(rgb)
    draw = ImageDraw.Draw(rgb_im)

    rows = []
    print("centres", {p: PANELS[p]["num_h1"] for p in PANELS})

    for pname, meta in PANELS.items():
        yt, yb, vt, vb = meta["spl_y"]
        dyt, dyb, dvt, dvb = meta["dspl_y"]
        zero = meta["dspl_zero"]
        for h in range(1, 11):
            for series in ("BEMT", "Numerical", "Experimental"):
                flag = ""
                spl = dspl = None
                if h <= meta["h_max"]:
                    x = int(round(meta["num_h1"] + (h - 1) * meta["pitch"] + meta["off"][series]))
                    top = sample_spl(m[series], x, yt, yb)
                    if top is not None:
                        spl = round(y_to_val(top, yt, yb, vt, vb), 2)
                        draw.ellipse([x - 3, top - 3, x + 3, top + 3], outline=(255, 0, 0))
                    else:
                        flag = "missing"
                    if series != "BEMT":
                        tip = sample_dspl(m[series], x, dyt, dyb, zero)
                        if tip is not None:
                            dspl = round(y_to_val(tip, dyt, dyb, dvt, dvb), 2)
                            if abs(dspl - 10) < 0.5 or abs(dspl + 10) < 0.5:
                                flag = (flag + ";clipped").strip(";")
                            draw.ellipse([x - 3, tip - 3, x + 3, tip + 3], outline=(0, 180, 0))
                        else:
                            flag = (flag + ";missing_dspl").strip(";")
                else:
                    flag = "out_of_panel"
                rows.append(
                    dict(
                        panel=pname,
                        phi_deg=meta["phi"],
                        harmonic=h,
                        series=series,
                        SPL_dB=spl,
                        dSPL_vs_BEMT_dB=dspl,
                        flag=flag,
                    )
                )

    # Fill / correct dSPL from SPL−BEMT when lower chart unread or tip sign wrong
    for r in rows:
        if r["series"] == "BEMT":
            continue
        bemt = next(
            x
            for x in rows
            if x["panel"] == r["panel"] and x["harmonic"] == r["harmonic"] and x["series"] == "BEMT"
        )
        if r["SPL_dB"] is None or bemt["SPL_dB"] is None:
            continue
        from_spl = round(r["SPL_dB"] - bemt["SPL_dB"], 2)
        if r["dSPL_vs_BEMT_dB"] is None:
            r["dSPL_vs_BEMT_dB"] = from_spl
            r["flag"] = ((r.get("flag") or "") + ";dspl_from_spl").strip(";")
        elif abs(from_spl) >= 8 and r["dSPL_vs_BEMT_dB"] * from_spl < 0:
            # tip sampler picked the wrong end; prefer SPL difference and keep clipped if |from_spl|≥9.5
            r["dSPL_vs_BEMT_dB"] = 10.0 if from_spl > 0 else -10.0
            r["flag"] = ((r.get("flag") or "") + ";clipped;dspl_sign_fixed").strip(";")


    for r in rows:
        if r["series"] == "BEMT" or "clipped" in (r.get("flag") or "") or "dspl_from_spl" in (r.get("flag") or ""):
            continue
        bemt = next(
            x
            for x in rows
            if x["panel"] == r["panel"] and x["harmonic"] == r["harmonic"] and x["series"] == "BEMT"
        )
        if None in (r["SPL_dB"], bemt["SPL_dB"], r["dSPL_vs_BEMT_dB"]):
            continue
        if abs((r["SPL_dB"] - bemt["SPL_dB"]) - r["dSPL_vs_BEMT_dB"]) > 1.0:
            r["flag"] = ((r.get("flag") or "") + ";consistency_gt_1dB").strip(";")

    fig7_peak = 20 * np.log10(0.458 / 20e-6)
    fig7_rms = fig7_peak - 3.01
    h1 = next(r for r in rows if r["panel"] == "a" and r["harmonic"] == 1 and r["series"] == "Experimental")
    ref = "peak" if abs((h1["SPL_dB"] or 99) - fig7_peak) <= abs((h1["SPL_dB"] or 99) - fig7_rms) else "rms"
    qa = QA / "pereira_fig9_overlay.png"
    rgb_im.save(qa)
    with OUT.open("w", newline="", encoding="utf-8") as f:
        f.write(
            "# Source: Pereira et al. Aerosp. Sci. Technol. 177 (2026) 112963, Fig. 9, PDF p. 10 (printed p. 10)\n"
        )
        f.write(
            "# Method: pass A, 300 dpi, fixed harmonic centres + color bar-top; SPL 50-100 dB; panels a/b H1-H7 only (H8-10 out_of_panel)\n"
        )
        f.write(
            "# Uncertainty: ~1 dB; clipped DeltaSPL flagged; dspl_from_spl = SPL-BEMT when lower chart unread\n"
        )
        f.write("# Digitized 2026-10-21 by agent; script data/digitizers/dig_pereira_fig9.py\n")
        f.write(
            f"# Conventions: SPL peak; Fig.7 H1 phi=0 Exp 0.458 Pa = {fig7_peak:.2f} peak / {fig7_rms:.2f} rms; "
            f"bar H1 Exp={h1['SPL_dB']} matches {ref}\n"
        )
        w = csv.DictWriter(
            f, fieldnames=["panel", "phi_deg", "harmonic", "series", "SPL_dB", "dSPL_vs_BEMT_dB", "flag"]
        )
        w.writeheader()
        for r in rows:
            w.writerow({k: ("" if r.get(k) is None else r[k]) for k in w.fieldnames})
    n_ok = sum(1 for r in rows if r["SPL_dB"] is not None)
    print("wrote", OUT, "H1exp", h1["SPL_dB"], "ref", ref, "SPL_ok", n_ok)
    for r in rows:
        if r["panel"] == "a" and r["harmonic"] <= 3:
            print(r)


if __name__ == "__main__":
    main()
