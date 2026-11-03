"""Shared calibration for Fig. E-12 (CR-3813 p. E-20, PDF page 136). Pixels are at 300 dpi (2400x3284).
x: tick labels 1, 0.5, 0, -0.5, -1 at display px 365, 548, 727, 905, 1082 (display = original/1.64).
y: panel ticks (display px): H1 130/120/110/100 at 340/458/576/691; H2 120/110/100/90 at 808/928/1044/1157;
   H3 110/100/90 at 1277/1395/1511."""
import fitz
S = 1.64
X0, XS = 727.0, 355.0          # display px of X3/D = 0, px per unit X3/D
PANEL = {1: (130, 340.0, 11.7), 2: (120, 808.0, 11.65), 3: (110, 1277.0, 11.7)}  # (dB ref, y px ref, px/dB)
def to_px(h, X, dB):
    ref, y0, k = PANEL[h]
    return (X0 - X * XS) * S, (y0 - (dB - ref) * k) * S
def render(pdf, out, dpi=300):
    d = fitz.open(pdf); p = d[135]
    return d, p
