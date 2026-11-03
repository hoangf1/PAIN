"""Render the digitized pages at 300 dpi into tools/work/ (run from tools/).

TN 1546 pages are stored rotated; they are turned upright (90 deg clockwise) so the
figure reads normally. Usage: python render_pages.py
"""
import os
import pymupdf
from PIL import Image

REF = os.path.join("..", "..", "..", "references")
os.makedirs("work", exist_ok=True)


def render(pdf, page, out, rotate):
    pix = pymupdf.open(os.path.join(REF, pdf))[page - 1].get_pixmap(dpi=300)
    im = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
    if rotate:
        im = im.rotate(-90, expand=True)
    im.save(os.path.join("work", out))


for p in (30, 34, 35):                       # Figs. 3(j), 3(n), 3(o)
    render("NACA_TN_1546.pdf", p, f"p{p}_300.png", rotate=True)
render("NACA_TR_824.pdf", 143, "tr824_p143.png", rotate=False)   # report p. 141, NACA 4412
