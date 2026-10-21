"""Probe axis ticks on a CR-3813 figure render for calibration."""
from pathlib import Path
import numpy as np
from PIL import Image

path = Path(__file__).resolve().parents[1] / "_scratch" / "e21_e22-149.png"
im = Image.open(path).convert("L")
a = np.asarray(im)
H, W = a.shape
print("size", W, H)

# Find dark horizontal grid lines (mean darkness across mid-x)
x0, x1 = W // 4, 3 * W // 4
row_dark = (a[:, x0:x1] < 140).mean(axis=1)
# peaks
cands = []
for y in range(50, H - 50):
    if row_dark[y] > 0.15 and row_dark[y] >= row_dark[y - 2 : y + 3].max():
        cands.append((y, float(row_dark[y])))
cands.sort(key=lambda t: -t[1])
print("top horizontal dark rows:", cands[:15])

# vertical spine: dark column near left
col_dark = (a[H // 5 : 4 * H // 5, :] < 140).mean(axis=0)
vcands = []
for x in range(50, W // 3):
    if col_dark[x] > 0.2 and col_dark[x] >= col_dark[max(0, x - 2) : x + 3].max():
        vcands.append((x, float(col_dark[x])))
vcands.sort(key=lambda t: -t[1])
print("left vertical dark cols:", vcands[:10])
