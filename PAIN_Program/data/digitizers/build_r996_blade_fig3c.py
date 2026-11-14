"""Phase 154b (2026-11-14): the Report 996 blade input with the blade angle of Report 996 Fig. 3(c).

Run from this folder after dig_r996_fig3c.py:  python build_r996_blade_fig3c.py
Writes data/report996/naca_4-5-08-03/blade_form_r996_fig3c.csv. Stations, chord, thickness and design lift are the
CR-196702 table's (blade_form.csv, unchanged). The blade angle is the table's plus the difference Fig. 3(c) minus table,
taken at the figure's gridlines (r/R 0.30 to 1.00 every 0.05) and interpolated linearly between them, so the figure's
values hold at the gridlines and the table's fine shape between them. Below r/R 0.30, which the figure does not print,
the difference at 0.30 is held (the table's beta joined continuously)."""
import csv, os
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
TABLE = os.path.join(ROOT, 'data', 'report996', 'naca_4-5-08-03', 'blade_form.csv')
FIG = os.path.join(ROOT, 'data', 'report996', 'naca_4-5-08-03', 'measured', 'geometry', 'tr996_fig3c_blade_form.csv')
OUT = os.path.join(ROOT, 'data', 'report996', 'naca_4-5-08-03', 'blade_form_r996_fig3c.csv')

tab = list(csv.DictReader(open(TABLE, encoding='utf-8')))
fig = [l.split(',') for l in open(FIG, encoding='utf-8') if l[0].isdigit()]
rf = np.array([float(w[0]) for w in fig]); bf = np.array([float(w[1]) for w in fig])
rt = np.array([float(q['r_over_R']) for q in tab]); bt = np.array([float(q['beta_deg']) for q in tab])
delta = bf - np.interp(rf, rt, bt)                      # figure minus table at the gridlines
with open(OUT, 'w', newline='\n', encoding='utf-8') as f:
    f.write('# Report 996 blade input, Phase 154b (2026-11-14; ISSUE-044). Written by data/digitizers/build_r996_blade_fig3c.py; do not edit by hand\n')
    f.write('# r_over_R, c_over_R, t_over_c, cl_design: NASA CR-196702 App. B-1 (blade_form.csv, unchanged)\n')
    f.write('# beta_deg: blade_form.csv plus (Report 996 Fig. 3(c) minus blade_form.csv) at the gridlines r/R 0.30..1.00, linear between them; below r/R 0.30 the difference at 0.30 is held\n')
    f.write('r_over_R,c_over_R,t_over_c,beta_deg,cl_design\n')
    for q in tab:
        r = float(q['r_over_R'])
        d = float(np.interp(r, rf, delta))                  # np.interp holds the end values outside the gridlines
        f.write('%s,%s,%s,%.3f,%s\n' % (q['r_over_R'], q['c_over_R'], q['t_over_c'], float(q['beta_deg']) + d, q['cl_design']))
b75 = float(np.interp(0.75, rt, bt + np.interp(rt, rf, delta)))
print('written', OUT, '| beta at 0.75 R %.3f deg; difference to the table relative to 0.75 R:' % b75)
for r in (0.30, 0.50, 0.65, 0.80, 0.90, 0.95, 0.99):
    d = np.interp(r, rf, delta); d75 = np.interp(0.75, rf, delta); print('   r/R %.2f  %+.2f deg' % (r, d - d75))
