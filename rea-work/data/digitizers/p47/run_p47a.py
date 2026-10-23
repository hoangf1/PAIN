"""Phase 47a: digitize TP-2444 Figs. 17 and 19 and CR-172428 Fig. 14 from the PDFs in rea-work/references.
Usage: python run_p47a.py <work_dir>
Page images and QA overlays go to <work_dir> (not committed); CSVs go to rea-work/data/tp2444 and data/cr172428.
Two independent passes per trace:
  Fig. 17 / Fig. 14: pass A = native image, run centre; pass B = 600 dpi render (Fig. 17) or 2x upscale (Fig. 14), top of the ink.
  Fig. 19: pass A = by eye on zoomed crops; pass B = band-centre ink runs (dig_tp2444_fig19.py)."""
import sys, os, json, subprocess
import numpy as np
import fitz
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__))
RW = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
REF = os.path.join(RW, "references")
W = sys.argv[1]; os.makedirs(W, exist_ok=True)
sys.path.insert(0, HERE)
from qa_two_pass import qa

def native(pdf, page, out):
    d = fitz.open(os.path.join(REF, pdf))
    pix = fitz.Pixmap(d, d[page].get_images()[0][0])
    Image.frombytes("L" if pix.n == 1 else "RGB", (pix.width, pix.height), pix.samples).convert("L").save(out)
def render(pdf, page, dpi, out):
    fitz.open(os.path.join(REF, pdf))[page].get_pixmap(dpi=dpi, colorspace=fitz.csGRAY).save(out)
def run(script, *args):
    subprocess.run([sys.executable, os.path.join(HERE, script), *args], check=True, cwd=W)
P = lambda n: os.path.join(W, n)
native("NASA_TP_2444.pdf", 31, P("f17_native.png")); render("NASA_TP_2444.pdf", 31, 600, P("f17_600.png"))
native("Pain Validation.pdf", 37, P("f14_native.png"))
native("NASA_TP_2444.pdf", 33, P("f19_native.png"))
run("dig_tp2444_fig17.py", P("f17_native.png"), "1", "center", P("f17_A"))
run("dig_tp2444_fig17.py", P("f17_600.png"), "2", "top", P("f17_B"))
run("dig_cr172428_fig14.py", P("f14_native.png"), "1", "center", P("f14_A"))
run("dig_cr172428_fig14.py", P("f14_native.png"), "2", "top", P("f14_B"))
run("dig_tp2444_fig19.py", P("f19_native.png"), P("f19.json"))

def write_trace(path, header, tr):
    with open(path, "w", newline="\n") as f:
        f.write("".join("# " + h + "\n" for h in header))
        f.write("f_Hz,L_dB,L_top_dB,L_bottom_dB\n")
        for fr, L, Lt, Lb in tr: f.write(f"{fr:.2f},{L:.2f},{Lt:.2f},{Lb:.2f}\n")
TP = os.path.join(RW, "data", "tp2444"); CR = os.path.join(RW, "data", "cr172428")
os.makedirs(TP, exist_ok=True)
f17 = {p: json.load(open(P(f"f17_{p}.json"))) for p in "AB"}
f14 = {p: json.load(open(P(f"f14_{p}.json"))) for p in "AB"}
how = {"A": "pass A: native page image (300 dpi), centre of the ink run in each pixel column",
       "B": "pass B: 600 dpi page render, top of the ink run in each pixel column"}
for side, name in (("ext", "exterior"), ("int", "interior")):
    for p in "AB":
        write_trace(os.path.join(TP, f"tp2444_fig17_{name}_pass{p}.csv"), [
            f"NASA TP-2444 (Willis, Mayes, Daniels 1985) Fig. 17, PDF p. 32 (printed 28): {name} narrowband spectrum, model 2, 4000 rpm.",
            "Digitized 2026-10-23 (Phase 47a, rea-work/data/digitizers/p47); " + how[p] + ".",
            "Axes calibrated from the tick marks; L_top/L_bottom = ends of the ink run (a near-vertical tone line spans them).",
            "Analysis bandwidth not stated in TP-2444; B = 5 Hz assumed in Phase 47b (V-ASSUMED)."], f17[p][side])
how14 = {"A": "pass A: native page image, centre of the ink run in each pixel column",
         "B": "pass B: native page image upscaled 2x, top of the ink run in each pixel column"}
for p in "AB":
    write_trace(os.path.join(CR, f"cr172428_fig14_mic1_5000rpm_pass{p}.csv"), [
        "NASA CR-172428 (Pain Validation.pdf) Fig. 14, PDF p. 38 (printed -28-): free-field propeller noise at microphone 1, run 8113, 5000 rpm.",
        "Digitized 2026-10-23 (Phase 47a, rea-work/data/digitizers/p47); " + how14[p] + ".",
        "Axes calibrated from the tick marks (page rotated 90 deg). The tone peaks fall 9-22 Hz below H x 250 Hz: the separately drawn",
        "frequency axis is offset from the plotted trace (Phase 47a QA). Frequencies here are as calibrated from the ticks, not shifted."], f14[p]["trace"])
f19 = json.load(open(P("f19.json")))
with open(os.path.join(TP, "tp2444_fig19_interior_third_octave.csv"), "w", newline="\n") as f:
    f.write("# NASA TP-2444 Fig. 19, PDF p. 34 (printed 30): space-averaged interior 1/3-octave spectra, model 2, theta_p = 135 deg, 4000 rpm.\n"
            "# cw = clockwise rotation (sweep down, solid); rev = reversed (dashed). Digitized 2026-10-23 (Phase 47a).\n"
            "# passA = by eye on zoomed crops with 1 dB guide lines (primary); passB = band-centre ink runs (curves can swap where they cross).\n"
            "f_Hz,cw_passA_dB,rev_passA_dB,cw_passB_dB,rev_passB_dB\n")
    for fc, a, b in zip(f19["bands"], f19["A"], f19["B"]): f.write(f"{fc:g},{a[0]:.1f},{a[1]:.1f},{b[0]:.1f},{b[1]:.1f}\n")

# QA (criterion fixed 2026-10-23: two passes within 1 dB median and 3 dB p95 of points; tone peaks within one 5 Hz bin of H*BPF)
res = dict(fig17_exterior=qa(P("f17_A.json"), P("f17_B.json"), "ext", 200.0, 7),
           fig17_interior=qa(P("f17_A.json"), P("f17_B.json"), "int", 200.0, 7),
           fig14=qa(P("f14_A.json"), P("f14_B.json"), "trace", 250.0, 8))
d19 = np.abs(np.array(f19["A"]) - np.array(f19["B"])).ravel()
res["fig19"] = dict(all=dict(n=int(d19.size), median=round(float(np.median(d19)), 3), p95=round(float(np.percentile(d19, 95)), 3),
                    max=round(float(d19.max()), 3)))
json.dump(res, open(P("qa_p47a.json"), "w"), indent=1)
print(json.dumps(res, indent=1))

# Fig. 14 overlay (pass A red, pass B blue) for a visual check
c = f14["A"]["calib"]
pl = np.polyfit(np.arange(130, 69, -5), c["level_ticks"], 1); pf = np.polyfit(np.arange(0, 2001, 200), c["freq_ticks"], 1)
cB = f14["B"]["calib"]
plB = np.polyfit(np.arange(130, 69, -5), cB["level_ticks"], 1); pfB = np.polyfit(np.arange(0, 2001, 200), cB["freq_ticks"], 1)
im = Image.open(P("f14_native.png")).convert("L").rotate(-90, expand=True).convert("RGB"); d = ImageDraw.Draw(im)
d.line([(np.polyval(pf, f), np.polyval(pl, L)) for f, L, *_ in f14["A"]["trace"]], fill=(255, 0, 0), width=2)
d.line([(np.polyval(pfB, f) / 2, np.polyval(plB, L) / 2) for f, L, *_ in f14["B"]["trace"]], fill=(0, 140, 255), width=1)
im.save(P("f14_overlay.png"))
print("overlays and page images in", W)
