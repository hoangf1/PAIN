# NACA 4-(5)(08)-03 static-test and noise figures: digitisation notes

All values were digitised from the NTRS scans (300 dpi renders) with the scripts in `tools/`
(`digitize_static_noise.py` = library; `dsn_l8h25a.py`, `dsn_tr1079.py`, `dsn_tr996.py` = per-report drivers,
each re-creating its CSVs and the QA overlays in `qa/`).  In every overlay the traced curves are drawn in
colour on the scan and detected symbols are boxed; the colour/label at the right-hand end names the curve.

## Figure -> page map and axis scales

| Report | Figure | PDF page (file) | Content | Axes (grid cell) |
|---|---|---|---|---|
| RM L8H25a (19930085493) | 10 | 16 (right plot; page printed rotated 90 deg) | static CT vs Mt, beta 0..40 | Mt 0-1.0 (0.1), CT 0-0.15 (0.01) |
| RM L8H25a | 11 | 17 (left plot) | static CP vs Mt | Mt 0-1.0 (0.1), CP 0-0.26 (0.02) |
| RM L8H25a | 16 | 19 (right plot) | CT vs beta_0.75R at Mt 0.45, 4 propellers | beta -10..50 (5), CT 0-0.18 (0.01) |
| RM L8H25a | 17 | 20 (full page, printed upright) | CP vs beta_0.75R at Mt 0.45 | beta -10..50 (5), CP 0-0.36 (0.02) |
| Report 1079 (19930092124) | 6(a),(b) | 10 | rms (squares, dashed) and peak (circles, solid) sound pressure vs azimuth theta; Mt 0.75 and 1.20; beta 15, s = 30 ft | theta 0-180 (22.5) per panel, log pressure 10-5000 dynes/cm2 |
| Report 1079 | 7 | 11 (left) | over-all SPL vs Mt at constant power loading 30 hp/sq ft, theta 90, 7.5 D (the blade angle was varied with tip speed to hold the power; the `beta_075R_deg = 13` in the csv rows is nominal, copied from Table I's second block, and is not the test condition: `analysis/noise.py` uses the power loading) | Mt 0.70-1.30 (0.05), 110-132 dB (2) |
| Report 1079 | 8 | 11 (right) | SPL vs distance (propeller diameters), Mt 1.20, theta 90, 30 hp/sq ft, beta 15 | 0-16 D (1), 120-160 dB (4) |
| Report 996 (19930092054) | 6 | 11 (upper left) | total rms oscillating pressure vs x/D for d/D 0.042/.083/.167/.333; B=4, beta 10, Mt 0.60 | x/D -1..1 (0.125), 0-600 dynes/cm2 (50) |
| Report 996 | 7 | 11 (lower left) | p_c/CP vs x/D for beta 8/15/20 (CP 0.0195/0.0424/0.0818); B=2, Mt 0.60, d/D 0.083 | x/D -1..1 (0.125), 0-0.40 (0.04) |
| Report 996 | 8 | 11 (right) | p_c vs CP in the plane of rotation (x/D = 0), d/D 0.042; B=2 (solid, circles) and B=4 (dashed, squares) at Mt 0.60 and 1.00; also 4-(3)(06.3)-06 (diamonds) and Clark Y (triangles) points | CP 0-0.10 (0.01), p_c 0-0.040 (0.002) |

Report 1079 figs 4/5 (spectra and wave forms) and Report 996 figs 9/11/12 were not digitised.
p_c = p_rms / (rho n^2 D^2) (Report 996 definition); dB are re 0.0002 dyne/cm2 (Report 1079 convention).
Distances in feet for Report 1079 use D = 47 in. = 3.917 ft (7.5 D = 29.4 ft, the "30 ft" of the captions).

## Method

* Frame = bounding box of the grid (`digitize.find_border`); axes calibrated from the detected regular grid
  lines (`regular_lines` fits the dominant spacing; the division count was checked against the axis labels
  for every panel) or from two anchor lines (log axis of TR 1079 fig. 6: the six labelled lines fit one
  log scale to +-3 px).
* RM L8H25a: the grid is printed as dark as the curves, so grid lines were erased geometrically, keeping
  pixels whose dark run across the line is longer than the line's own thickness (curve crossings).  Curves
  were followed column by column with slope prediction (`follow`); where a curve coincides with a grid row
  (10 deg CT curve on CT = 0.07 up to Mt 0.49, 30 deg CT on 0.12, 15 deg CT on 0.09) the tracer rides the
  grid row, i.e. the value is the grid value (bias <= 3 px = 0.0003 in CT).  Only solid (present-test)
  curves were traced; the dashed earlier-test curves were excluded by per-curve Mt limits.
* Reports 1079 and 996 (light grey grid): `digitize.excess_weight` isolates the ink; hollow symbols were
  located by outline-template matching (r 5-6 px) with a ring-coverage test and an empty-interior test
  (true symbols score >= 0.85, grid crossings <= 0.65), blanked out before tracing, and assigned to the
  curve they sit on.  TR 996 figs 6/7 curves were traced piecewise between consecutive symbols of the same
  curve with the ray tracer (`digitize.trace_w`), the symbol identities at each x/D station being read from
  magnified crops (tables `MAN6`/`MAN7` in `dsn_tr996.py`); symbols that could not be detected (overlapping
  glyphs in the tails) carry `kind = symbol_manual` and are the manual readings.  TR 996 fig. 8 lines all
  pass through the origin and were found by scanning the slope for line support; solid vs dashed by
  continuity.  Circle/square identities in TR 1079 fig. 7 and TR 996 fig. 8 were read by eye from
  magnified crops (the 12-px glyphs are too small for automatic shape classification) and are hard-coded
  in the drivers.

## Files

* `static/rm_l8h25a_static_vs_tip_mach.csv` - CT (fig. 10) and CP (fig. 11) every 0.05 in Mt for beta
  0..40 deg (solid curves only).  Test range starts at Mt ~0.275 (first sample 0.30).  Curve extents:
  0, 5, 15 deg to Mt ~0.92; 10 deg to 0.83; 20 deg to ~0.65-0.70; 25 deg to ~0.55; 30-40 deg to
  ~0.40-0.46 (flutter limit).  The 25 deg CT curve is the short flat segment at CT 0.1145 (Mt 0.39-0.55)
  at the height of its label; the 30, 35 and 40 deg CT curves converge within ~1 px near Mt 0.36-0.45
  (35 and 40 were traced in two pieces either side of the crossing).
* `static/rm_l8h25a_static_vs_blade_angle_Mt045.csv` - the 4-(5)(08)-03 curve of figs. 16/17 every
  2.5 deg (0..40).  Cross-check at Mt 0.45 against figs. 10/11: CT agrees within 0.0015 and CP within
  0.003 at every blade angle (10 deg CP: 0.020 vs 0.023 is the largest difference).
  Note the legend: the long-dash curve that peaks at CT 0.134 is the 4-(10)(08)-03 (it matches fig. 12);
  the 4-(5)(08)-03 is the lower long-dash curve, almost coincident with the solid 4-(3)(08)-03 as the text
  states.
* `noise/tr1079_fig6_directivity_pressures.csv` - rms and peak sound pressure (dynes/cm2, with the dB
  conversion in the last column) vs theta: all 40 plotted points (`kind = symbol`, theta to 0.1 deg) and
  the faired curves every 15 deg.  Panel (a) Mt 0.75 (peak points 60-165 deg, rms 45-165), panel (b)
  Mt 1.20 (0-165 deg).  Note the figure gives pressures, not dB: this is the report's directivity figure.
* `noise/tr1079_fig7_spl_vs_tip_mach.csv` - over-all SPL vs Mt: circles (computed from harmonic analysis)
  and squares (voltmeter), plus the faired curve every 0.05.  At Mt 0.75 the two symbols coincide (the
  data were adjusted to equality there; one row of each kind is written).
* `noise/tr1079_fig8_spl_vs_distance.csv` - the two measured points (1.0 D and 7.5 D) and the estimated
  curve every 1 D (1-15 D; it leaves the frame top at ~0.7 D).
* `noise/tr996_fig6_tip_clearance_pressure_vs_xD.csv`, `noise/tr996_fig7_blade_loading_pc_over_CP_vs_xD.csv` -
  symbols at the 11 x/D stations (-1, -0.75, -0.5, -0.25, -0.125, 0, 0.125, 0.25, 0.5, 0.75, 1) and faired
  curves every 0.0625.
* `noise/tr996_fig8_pc_vs_CP.csv` - the four 4-(5)(08)-03 lines (every 0.01 in CP up to the drawn end,
  plus the end point and the slope p_c/CP: B=2 Mt 1.00 0.750, B=4 Mt 1.00 0.668, B=2 Mt 0.60 0.302,
  B=4 Mt 0.60 0.200) and all 15 plotted 4-(5)(08)-03 points; the two 4-(3)(06.3)-06 points are included
  with `kind = symbol_other_propeller`.  The Clark Y triangle (0.0345, 0.0111) was not detected and is
  omitted.

## Accuracy and known imperfections

* Pixel scale: RM L8H25a 91-123 px per grid cell (1 px = 0.0001 CT / 0.0002 CP / 0.001 Mt); TR 1079
  fig. 6 719 px per decade (1 px = 0.3 %), fig. 7 39 px/dB; TR 996 60 px per cell.  Traced curves are
  within about 1-2 px of the ink; symbol centres within ~1 px.  Calibration checked against labelled lines
  (<= 3 px residual).
* RM L8H25a: the 35 and 40 deg CT curves between Mt 0.345 and 0.37 are interpolated across the crossing
  with the 30 deg curve; the 30/35 deg CT values at Mt 0.40-0.45 are from the merged ink (the curves are
  within 1 px there); the 40 deg CT value at Mt 0.40 lies in the crossing and is uncertain by
  +-0.001.  Label leaders ("30 ---") were excluded by starting all curves at Mt >= 0.265.
  Fig. 16/17 dashed curves: small stair-steps at dash gaps are visible in the overlay (< 1 px effect on
  the 2.5-deg samples).
* TR 1079 fig. 6: faired samples at theta 60 (panel a) and 0/165 are at the curve ends (symbol centres).
* TR 996 figs 6/7: in the tails (|x/D| >= 0.5) the four (three) curves lie within one grid cell of each
  other and partly overlap; faired values there are reliable to ~5-10 dynes/cm2 (0.005 in p_c/CP) and the
  19 (8) `symbol_manual` rows are readings from the magnified scan (+-3 dynes/cm2, +-0.003) rather than
  detected glyph centres.  Fig. 6 d/D = 0.083: one of the ten faired segments (0.5-0.75) could not be
  separated from its neighbours and is linearly interpolated between the two symbols.
* TR 996 fig. 8: line slopes to +-0.003; the dashed-line ends are where the drawn dashes stop (B=4 Mt 1.00
  runs off the frame top at CP ~0.054).
