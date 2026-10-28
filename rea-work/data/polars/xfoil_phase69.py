"""Phase 69 XFOIL runs (plan IMPLEMENTATION_PLAN.md section 8m; settings fixed 2026-10-28 before any run).

Same XFOIL session and acceptance rule as xfoil_polars.py (XFOIL 6.99, ITER 200, last viscous rms <= 1e-4,
sweeps away from alpha = 0, 60 s hang limit, 240 panels for the NACA 16 sections). Free transition everywhere.

Run from rea-work (XFOIL_EXE set or xfoil on PATH):
    python data/polars/xfoil_phase69.py tn1546 <points.csv> <out.json>
        69b: every TN 1546 matched point (section, M, alpha) at the TN 1546 Re(M), for N_crit = 1..12.
    python data/polars/xfoil_phase69.py grid <N_crit> <out.json>
        69c: Report 996 sections on the Phase 69 grid (Re 1.5e5..2e6, M 0.1..0.9, alpha -6..20 step 0.5).
    python data/polars/xfoil_phase69.py fill <N_crit> <grid.json>
        69c fill: every polar whose up or down sweep hung is re-swept with the 2026-10-22 restart rule
        (xfoil_regen_2026_10_22.py: after a 60 s hang the sweep restarts at the next alpha, the hung alpha is
        skipped). Settings unchanged; existing points are kept; only absent alphas are added; still-absent
        alphas stay listed in the header.
"""
import csv, datetime, itertools, json, os, sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import xfoil_polars as xp  # noqa: E402  (same session, parser and acceptance rule)

ROOT = HERE.parent.parent
SEC_DIR = ROOT / "data" / "report996" / "xfoil_sections"
SECTIONS = ["n16_213", "n16_312", "n16_411", "n16_410", "n16_509", "n16_508", "n16_507", "n16_506", "n16_405", "n16_101"]
NCRIT_CANDIDATES = list(range(1, 13))
GRID_RE = [1.5e5, 2e5, 3e5, 5e5, 7e5, 1e6, 1.5e6, 2e6]
GRID_M = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
GRID_ALPHA = xp.frange(-6, 20, 0.5)
PANELS = 240
WORKERS = max(2, (os.cpu_count() or 8) - 2)


def tn1546(points_csv, out):
    pts = list(csv.DictReader(open(points_csv)))
    groups = defaultdict(list)
    for p in pts:
        groups[(p["section"], float(p["mach"]), float(p["re"]))].append(float(p["alpha_deg"]))
    jobs = []
    for N in NCRIT_CANDIDATES:
        for (s, M, Re), al in groups.items():
            jobs.append((f"{N}|{s}|{M:.2f}", SEC_DIR / f"{s}.dat", Re, M, sorted(set(al)), PANELS, ("ncrit", N)))
    res = xp.run_grid(jobs)
    db = {k: dict(rows=rows, missing=miss, timeouts=to) for k, rows, miss, to in res}
    json.dump(dict(header=dict(purpose="Phase 69b: N_crit fit to NACA TN 1546 (16-506, 16-509; 16-312 held out)",
                               xfoil_version=xp.XFOIL_VERSION, panels=PANELS, transition="free, N_crit 1..12",
                               re_rule="TN 1546 Re(M) = 0.85e6 + 1.15e6 (M - 0.3)/0.5 (Phase 67 reading)",
                               alphas="the TN 1546 matched alphas of each (section, M)",
                               iter=xp.ITER, convergence_rule="last viscous rms <= 1e-4",
                               generated=datetime.date.today().isoformat(),
                               script="data/polars/xfoil_phase69.py tn1546"),
                   points=pts, runs=db), open(out, "w"))
    print("wrote", out)


def grid(N, out):
    jobs = [(f"{s}|{Re:.0f}|{M:.2f}", SEC_DIR / f"{s}.dat", Re, M, GRID_ALPHA, PANELS, ("ncrit", N))
            for s, Re, M in itertools.product(SECTIONS, GRID_RE, GRID_M)]
    res = xp.run_grid(jobs, workers=WORKERS)
    db, nonconv = {}, {}
    for k, rows, miss, to in res:
        db[k] = rows
        if miss or to:
            nonconv[k] = dict(missing_alpha=miss, timeouts=to)
    json.dump(dict(sections=SECTIONS, Res=GRID_RE, Ms=GRID_M, polars=db, transition=f"free N_crit {N}",
                   header=dict(purpose="Report 996 section polars, Phase 69 (free transition, N_crit fitted to TN 1546)",
                               xfoil_version=XFOIL_NOTE, panels=PANELS, N_crit=N, Re_grid=GRID_RE, M_grid=GRID_M,
                               alpha_grid_deg="-6 to 20, 0.5 step (up and down sweeps from 0)",
                               iter=xp.ITER, convergence_rule="last viscous rms <= 1e-4",
                               non_converged=nonconv, generated=datetime.date.today().isoformat(),
                               script=f"data/polars/xfoil_phase69.py grid {N}")), open(out, "w"))
    print("wrote", out, "entries with missing points:", len(nonconv))


XFOIL_NOTE = xp.XFOIL_VERSION.split(";")[0]


def _fill_one(job):
    import shutil, tempfile
    key, N = job
    s, Re, M = key.split("|"); Re = float(Re); M = float(M)
    dat = SEC_DIR / f"{s}.dat"
    with tempfile.TemporaryDirectory() as td:
        wd = Path(td); shutil.copy(dat, wd / dat.name)
        res, n, h = {}, 0, 0
        z = min(range(len(GRID_ALPHA)), key=lambda i: abs(GRID_ALPHA[i]))
        for sw in (GRID_ALPHA[z:], GRID_ALPHA[: z + 1][::-1]):
            todo = list(sw)
            while todo:
                r, last, hung = orig_free(wd / dat.name, wd, Re, M, todo, N); n += 1; res.update(r)
                if not hung:
                    break
                h += 1
                k = 0 if last is None else next((i for i, a in enumerate(todo) if abs(a - last) < 1e-6), -1) + 1
                todo = todo[k + 1:]
    print(f"{key}: fill {len(res)} pts, sessions {n}, hangs {h}", flush=True)
    return key, res, n, h


def orig_free(dat, wd, Re, M, alphas, N):
    """xfoil_regen_2026_10_22.session with `N <N_crit>` (free transition) in place of the forced XTR line."""
    import subprocess, threading, time
    lines = ["PLOP", "G", "", f"LOAD {dat.name}", "PANE", "PPAR", f"N {PANELS}", "", "", "OPER", "VPAR",
             f"N {N}", "", f"VISC {Re:.0f}", f"MACH {M:.4f}", f"ITER {xp.ITER}"]
    lines += [f"ALFA {a:.3f}" for a in alphas] + ["", "QUIT", ""]
    p = subprocess.Popen([xp.XFOIL], cwd=wd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, text=True)
    out = []
    t = threading.Thread(target=lambda: [out.append(l) for l in p.stdout], daemon=True)
    t.start()
    p.stdin.write("\n".join(lines)); p.stdin.close()
    t0 = time.time(); hung = False
    while p.poll() is None:
        if time.time() - t0 > xp.TIMEOUT:
            p.kill(); hung = True; break
        time.sleep(0.2)
    t.join(timeout=5)
    res, rms, last = {}, None, None
    for i, ln in enumerate(out):
        m = xp.ITER_RE.match(ln)
        if m:
            try: rms = abs(float(m.group(2)))
            except ValueError: rms = None
            continue
        m = xp.ALPHA_RE.match(ln)
        if not m:
            continue
        last = float(m.group(1))
        if rms is None or rms > xp.RMS_OK:
            continue
        for j in range(i + 1, min(i + 3, len(out))):
            m2 = xp.CD_RE.match(out[j])
            if m2:
                res[round(last, 3)] = (float(m.group(2)), float(m2.group(2))); break
    return res, last, hung


def fill(N, path):
    from concurrent.futures import ThreadPoolExecutor
    d = json.load(open(path))
    nc = d["header"]["non_converged"]
    keys = [k for k, v in nc.items() if v["timeouts"]]
    with ThreadPoolExecutor(WORKERS) as ex:
        out = list(ex.map(_fill_one, [(k, N) for k in keys]))
    grid = {round(a, 3) for a in GRID_ALPHA}
    added_total = 0
    audit = {}
    for key, res, n, h in out:
        have = {round(r[0], 3): (r[1], r[2]) for r in d["polars"][key]}
        add = {a: v for a, v in res.items() if a in grid and a not in have}
        have.update(add); added_total += len(add)
        d["polars"][key] = [[a, cl, cd] for a, (cl, cd) in sorted(have.items())]
        miss = [a for a in GRID_ALPHA if round(a, 3) not in have]
        nc[key] = dict(missing_alpha=miss, timeouts=nc[key]["timeouts"], fill_sessions=n, fill_hangs=h, fill_added=len(add))
        audit[key] = len(add)
    d["header"]["fill_pass"] = dict(date=datetime.date.today().isoformat(), polars_refilled=len(keys), points_added=added_total,
                                    rule="2026-10-22 restart rule (xfoil_regen_2026_10_22.py), free transition N_crit %d; existing points kept" % N,
                                    script=f"data/polars/xfoil_phase69.py fill {N}")
    json.dump(d, open(path, "w"))
    print("refilled", len(keys), "added points", added_total)

if __name__ == "__main__":
    if sys.argv[1] == "tn1546":
        tn1546(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "grid":
        grid(int(sys.argv[2]), sys.argv[3])
    elif sys.argv[1] == "fill":
        fill(int(sys.argv[2]), sys.argv[3])
    else:
        sys.exit(__doc__)
