"""Phase 156b (2026-11-22): sections and XFOIL polars for the NACA Report 1377 blades (case R1377_FLIGHT, ISSUE-046).

Rules fixed in docs/ISSUES.md (ISSUE-046, 2026-11-22) before any polar was run:
  sections   NACA 16-series thickness and a = 1.0 mean line by their published definitions (TR 824; thickness form of
             NASA TM-4741), or, for the airfoil-family check, the NACA four-digit thickness (open trailing edge) with the
             parabolic camber line of maximum at mid-chord, camber = design lift / 4 pi. One section per polar station at
             the station's own h/b and design lift (data/report1377/fig2_blade_form.csv); the rectangular blade's design
             lift inboard of r/R 0.60 is 0.50 (check: the printed slope between 0.60 and 0.70 carried inboard).
  XFOIL      Phase 69 settings and session unchanged (xfoil_polars.py, xfoil_phase69.py): XFOIL 6.99, free transition,
             N_crit 8, 240 panels, ITER 200, last viscous rms <= 1e-4, alpha -6..20 by 0.5 swept away from 0, 60 s hang
             limit, then the fill pass with the 2026-10-22 restart rule for sweeps that hung.
  grid       Re 7e5, 1e6, 1.5e6, 2e6, 3e6, 4e6; M 0.2 .. 0.9. Each section only on the grid points that bracket the
             range it meets on the case's 39 rows (printed V, N, p, t; no induction).

Run from PAIN_Program:
    python data/polars/xfoil_r1377.py sections            # writes data/report1377/xfoil_sections/*.dat and prints the jobs
    python data/polars/xfoil_r1377.py run <set> [workers] # set: tapered_16, rectangular_16, tapered_4d, rectangular_4d,
                                                          #      rectangular_16_clslope (check of the inboard design lift)
Outputs data/report1377/polars_<set>.json in the Phase 69 format (sections, Res, Ms, polars "section|Re|M", header).
"""
import csv, datetime, json, math, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import xfoil_polars as xp      # noqa: E402  session, parser, acceptance rule
import xfoil_phase69 as p69    # noqa: E402  fill session (orig_free) with the 2026-10-22 restart rule

ROOT = HERE.parent.parent
DATA = ROOT / "data" / "report1377"
SEC_DIR = DATA / "xfoil_sections"
N_CRIT = 8
PANELS = 240
GRID_RE = [7e5, 1e6, 1.5e6, 2e6, 3e6, 4e6]
GRID_M = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
GRID_ALPHA = xp.frange(-6, 20, 0.5)
D_M = 3.404
STATIONS = {"tapered": [0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 0.95],
            "rectangular": [0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 0.95]}
CL_HELD = 0.50          # rectangular blade, r/R < 0.60 (ISSUE-046, 2026-11-22)


# ---- section geometry -------------------------------------------------------------------------------------------
def t16(x):
    """NACA 16-series half-thickness / thickness (TM-4741 coefficients; reproduces TR 824's 16-009 table)."""
    if x <= 0.5:
        return 0.989665 * math.sqrt(x) - 0.239250 * x - 0.041000 * x * x - 0.559400 * x ** 3
    u = 1.0 - x
    return 0.01 + 2.325 * u - 3.42 * u * u + 1.46 * u ** 3


def t4(x):
    """NACA four-digit half-thickness / thickness (open trailing edge, the published coefficients)."""
    return 5.0 * (0.2969 * math.sqrt(x) - 0.1260 * x - 0.3516 * x * x + 0.2843 * x ** 3 - 0.1015 * x ** 4)


def mean_a10(x, cl):
    """a = 1.0 mean line: ordinate and slope (TR 824 table at c_l = 1)."""
    k = cl / (4 * math.pi)
    xe = min(max(x, 1e-12), 1 - 1e-12)
    return -k * (xe * math.log(xe) + (1 - xe) * math.log(1 - xe)), -k * (math.log(xe) - math.log(1 - xe))


def mean_parab(x, cl):
    """Parabolic camber line, maximum at mid-chord, camber m = c_l / 4 pi: y = 4 m x (1 - x)."""
    m = cl / (4 * math.pi)
    return 4 * m * x * (1 - x), 4 * m * (1 - 2 * x)


def contour(family, tc, cl, n=100):
    thick, mean = (t16, mean_a10) if family == "16" else (t4, mean_parab)
    xs = [0.5 * (1 - math.cos(math.pi * i / n)) for i in range(n + 1)]
    up, lo = [], []
    for i, x in enumerate(xs):
        yt = tc * thick(x)
        yc, dy = mean(x, cl)
        th = 0.0 if i in (0, n) else math.atan(dy)   # ends: thickness laid off vertically (the a = 1.0 slope is infinite there)
        up.append((x - yt * math.sin(th), yc + yt * math.cos(th)))
        lo.append((x + yt * math.sin(th), yc - yt * math.cos(th)))
    return up[::-1] + lo[1:]                     # TE -> upper -> LE -> lower -> TE (XFOIL order)


def section_name(family, tc, cl):
    return f"n{family if family == '16' else '4d'}_c{round(cl * 1000):04d}_t{round(tc * 10000):04d}"


# ---- blade stations and the flight rows ------------------------------------------------------------------------
def _rows(path):
    with open(path) as fh:
        return list(csv.DictReader(l for l in fh if not l.startswith("#")))


def station_inputs(blade, variant="primary"):
    """[(r/R, b/D, h/b, c_l)] at the polar stations; variant 'clslope' changes the rectangular c_l inboard of 0.60."""
    bf = {round(float(r["r_over_R"]), 2): r for r in _rows(DATA / "fig2_blade_form.csv") if r["blade"] == blade}
    out = []
    for x in STATIONS[blade]:
        r = bf[round(x, 2)]
        cl = r["cl_design"]
        if cl == "-":
            assert blade == "rectangular" and x < 0.60
            if variant == "clslope":
                c60, c70 = float(bf[0.60]["cl_design"]), float(bf[0.70]["cl_design"])
                cl = c60 + (c60 - c70) / 0.10 * (0.60 - x)
            else:
                cl = CL_HELD
        out.append((x, float(r["b_over_D"]), float(r["h_over_b"]), float(cl)))
    return out


def case_rows():
    sel = []
    for r in _rows(DATA / "tables_I_II_flight.csv"):
        if float(r["M_t"]) <= 0.90 and float(r["P_hp"]) >= 500:
            sel.append(r)
    assert len(sel) == 39, len(sel)
    return sel


def kinematic_range(blade, x, bd):
    """(M_min, M_max, Re_min, Re_max) of station x over the case rows: printed V, N, p, t, no induction."""
    Ms, Res = [], []
    for r in case_rows():
        if r["blade"] != blade:
            continue
        T = (float(r["t_F"]) - 32) * 5 / 9 + 273.15
        p = float(r["p_psf"]) * 47.880259
        rho, a, mu = p / (287.05 * T), math.sqrt(1.4 * 287.05 * T), 1.458e-6 * T ** 1.5 / (T + 110.4)
        V = float(r["V_fps"]) * 0.3048
        W = math.hypot(V, 2 * math.pi * 0.479 * float(r["N_rpm"]) / 60 * x * D_M / 2)
        Ms.append(W / a)
        Res.append(rho * W * bd * D_M / mu)
    return min(Ms), max(Ms), min(Res), max(Res)


def bracket(grid, lo, hi):
    i0 = max([i for i, g in enumerate(grid) if g <= lo] or [0])
    i1 = min([i for i, g in enumerate(grid) if g >= hi] or [len(grid) - 1])
    return grid[i0:i1 + 1]


SETS = {"tapered_16": ("tapered", "16", "primary"), "rectangular_16": ("rectangular", "16", "primary"),
        "tapered_4d": ("tapered", "4", "primary"), "rectangular_4d": ("rectangular", "4", "primary"),
        "rectangular_16_clslope": ("rectangular", "16", "clslope")}


def set_jobs(name):
    blade, fam, variant = SETS[name]
    jobs, secs = [], []
    for x, bd, hb, cl in station_inputs(blade, variant):
        s = section_name(fam, hb, cl)
        secs.append(s)
        if variant == "clslope" and x >= 0.60:
            continue                             # same section as the primary set: its polars are copied, not re-run
        m0, m1, r0, r1 = kinematic_range(blade, x, bd)
        for Re in bracket(GRID_RE, r0, r1):
            for M in bracket(GRID_M, m0, m1):
                jobs.append((f"{s}|{Re:.0f}|{M:.2f}", SEC_DIR / f"{s}.dat", Re, M, GRID_ALPHA, PANELS, ("ncrit", N_CRIT)))
    return blade, fam, variant, secs, jobs


def sections():
    SEC_DIR.mkdir(parents=True, exist_ok=True)
    for name in SETS:
        blade, fam, variant, secs, jobs = set_jobs(name)
        for (x, bd, hb, cl), s in zip(station_inputs(blade, variant), secs):
            with open(SEC_DIR / f"{s}.dat", "w", newline="\n") as fh:
                fh.write(s + "\n" + "".join(f"{px:.6f} {py:.6f}\n" for px, py in contour(fam, hb, cl)))
        print(f"{name}: {len(secs)} sections, {len(jobs)} polars to run")


def _fill(key):
    """Re-sweep the absent alphas of one polar with the 2026-10-22 restart rule (xfoil_phase69.orig_free)."""
    import shutil, tempfile
    s, Re, M = key.split("|")
    dat = SEC_DIR / f"{s}.dat"
    with tempfile.TemporaryDirectory() as td:
        wd = Path(td); shutil.copy(dat, wd / dat.name)
        res = {}
        z = min(range(len(GRID_ALPHA)), key=lambda i: abs(GRID_ALPHA[i]))
        for sw in (GRID_ALPHA[z:], GRID_ALPHA[: z + 1][::-1]):
            todo = list(sw)
            while todo:
                r, last, hung = p69.orig_free(wd / dat.name, wd, float(Re), float(M), todo, N_CRIT)
                res.update(r)
                if not hung:
                    break
                k = 0 if last is None else next((i for i, a in enumerate(todo) if abs(a - last) < 1e-6), -1) + 1
                todo = todo[k + 1:]
    return key, res


def run(name, workers=4):
    from concurrent.futures import ThreadPoolExecutor
    blade, fam, variant, secs, jobs = set_jobs(name)
    res = xp.run_grid(jobs, workers=workers)
    db, hung = {}, []
    for k, rows, miss, to in res:
        db[k] = rows
        if to:
            hung.append(k)
    with ThreadPoolExecutor(workers) as ex:           # fill pass: only polars whose sweep hung
        for k, extra in ex.map(_fill, hung):
            have = {round(r[0], 3) for r in db[k]}
            db[k] = sorted(db[k] + [[a, cl, cd] for a, (cl, cd) in extra.items() if round(a, 3) not in have])
            print(f"{k}: fill -> {len(db[k])} pts", flush=True)
    if variant == "clslope":                          # stations at and outboard of 0.60: the primary set's polars
        prim = json.load(open(DATA / "polars_rectangular_16.json"))
        for k, v in prim["polars"].items():
            if k.split("|")[0] in secs:
                db[k] = v
    missing = {k: [a for a in GRID_ALPHA if round(a, 3) not in {round(r[0], 3) for r in v}] for k, v in db.items()}
    out = DATA / f"polars_{name}.json"
    json.dump(dict(sections=secs, Res=GRID_RE, Ms=GRID_M, polars=db, transition=f"free N_crit {N_CRIT}",
                   header=dict(purpose=f"NACA Report 1377 {blade} blade, {'NACA 16-series' if fam == '16' else 'NACA four-digit'}"
                                       f" sections ({variant}); Phase 156b, case R1377_FLIGHT",
                               xfoil_version=p69.XFOIL_NOTE, panels=PANELS, N_crit=N_CRIT, Re_grid=GRID_RE, M_grid=GRID_M,
                               grid_rule="each section on the grid points bracketing its kinematic range on the 39 rows",
                               alpha_grid_deg="-6 to 20, 0.5 step (up and down sweeps from 0); fill pass for hung sweeps",
                               iter=xp.ITER, convergence_rule="last viscous rms <= 1e-4", workers=workers,
                               absent_alphas={k: v for k, v in missing.items() if v},
                               generated=datetime.date.today().isoformat(),
                               script=f"data/polars/xfoil_r1377.py run {name}")), open(out, "w"))
    print("wrote", out, len(db), "polars")


if __name__ == "__main__":
    if sys.argv[1] == "sections":
        sections()
    elif sys.argv[1] == "run":
        run(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 4)
    else:
        sys.exit(__doc__)
