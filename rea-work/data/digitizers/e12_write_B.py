"""Pass B of Fig. E-12: values read from the grid overlay (e12_grid.py) panels, not from the pass A table."""
Bp = {1: [(0.815, 102.7), (0.229, 128.7), (0.140, 130.9), (0.02, 125.8), (-0.104, 129.8), (-0.236, 126.4), (-0.642, 108.5), (-0.893, 99.2)],
      2: [(0.597, 89.0), (0.140, 123.6), (0.02, 119.6), (-0.09, 121.4), (-0.208, 115.3), (-0.53, 89.3)],
      3: [(0.50, 79.0), (0.364, 93.7), (0.138, 116.1), (0.02, 113.6), (-0.096, 112.8), (-0.234, 98.3), (-0.408, 79.6)]}
Bm = {1: [(0.683, 101.4), (0.153, 125.7), (0.005, 124.2), (-0.109, 125.5), (-0.634, 105.3)],
      2: [(0.153, 118.2), (0.02, 118.0), (-0.122, 114.8)],
      3: [(0.148, 110.6), (0.02, 113.8), (-0.12, 106.5)]}
Be = {2: [(-0.213, 109.3)], 3: [(0.22, 103.7), (-0.208, 98.7)]}


def w(kind, data, ends=None):
    with open(f'data/e12/e12_{kind}_B.csv', 'w') as f:
        f.write(f"# Digitization B of Fig. E-12 {kind} blocked SPL (CR-3813 App. E, p. E-20, PDF page 136), line l=1, dB re 20 uPa.\n")
        f.write("# Second pass: read from a 0.1 X3/D x 2 dB grid overlay (data/digitizers/e12_grid.py) without the A table in view; same reader, different method from A (pixel calibration).\n")
        f.write("# Not read in pass B: the H2 measured marker at X3/D = 0.69 (outside the grid crops). Dashed-curve end points without a circle: point_type=end.\n")
        f.write("harmonic,X3_over_D,SPL_dB,point_type\n")
        for h in (1, 2, 3):
            for X, v in data[h]:
                f.write(f"{h},{X},{v},{'vertex' if kind == 'predicted' else 'marker'}\n")
            if ends:
                for X, v in ends.get(h, []):
                    f.write(f"{h},{X},{v},end\n")


w('predicted', Bp)
w('measured', Bm, Be)
