"""Shared calibration for Fig. E-11 (CR-3813 App. E p. E-19, PDF page 135), from tick marks detected in a
300 dpi grey render (dark < 110). x ticks 1, 0.5, 0, -0.5, -1 at px 630.5, 924.5, 1211, 1499.5, 1782.5 (fit
x = 1209.6 - 575.8 X). y ticks (px): H1 130/120/110/100 at 528/721.5/913/1102.5; H2 120/110/100/90 at
1296.5/1491.5/1680.5/1867.5; H3 110/100/90 at 2063/2256/2447. Linear fits per panel."""
import numpy as np
import fitz
PAGE = 134                                   # 0-based index of PDF page 135
XFIT = np.polyfit([1, 0.5, 0, -0.5, -1], [630.5, 924.5, 1211, 1499.5, 1782.5], 1)
_P = {1: ([130, 120, 110, 100], [528, 721.5, 913, 1102.5]),
      2: ([120, 110, 100, 90], [1296.5, 1491.5, 1680.5, 1867.5]),
      3: ([110, 100, 90], [2063, 2256, 2447])}
YFIT = {h: np.polyfit(v, y, 1) for h, (v, y) in _P.items()}     # dB -> px
STATIONS = [round(np.pi * 0.508 / 18 * n / 0.762, 3) for n in range(-8, 8)]  # X3/D = (pi a/18)(k_p - k)/D
def to_px(h, X, dB):
    """300 dpi pixel position of (X3/D, SPL) in panel h."""
    return float(np.polyval(XFIT, X)), float(np.polyval(YFIT[h], dB))
def page(pdf='references/Pain Methodology.pdf'):
    d = fitz.open(pdf)
    return d, d[PAGE]
