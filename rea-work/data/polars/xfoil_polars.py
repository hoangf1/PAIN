"""Phase 11a/11b/11d: generate XFOIL polars for PAIN (Report 996 gap fill, Pereira NACA 4412 sets).

Run from rea-work (Python 3, standard library only; XFOIL 6.99 on PATH or XFOIL_EXE):
    python data/polars/xfoil_polars.py report996                 # 11a: Re 3e5 / M 0.1 gap fill, merged grid
    python data/polars/xfoil_polars.py pereira ncrit9|ncrit5|xtr005   # 11b: one file per transition setting

Settings were fixed in IMPLEMENTATION_PLAN.md phase 11 and VALIDATION_GUIDELINE.md section 2.10 before any comparison.
Each (Re, M) polar is two monotonic sweeps away from alpha = 0, one XFOIL session each (the plan's session), parsed from
stdout (PACC is avoided; the external repo's driver found it unreliable when piped). A point counts only if the last
viscous iteration before it had rms <= 1e-4.
"""
import json, os, re, subprocess, sys, tempfile, datetime, itertools, shutil
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent                      # rea-work
XFOIL = os.environ.get("XFOIL_EXE") or shutil.which("xfoil") or r"C:\Users\FrancisHoang\Downloads\XFOIL6.99\xfoil.exe"
XFOIL_VERSION = "6.99 (stock Windows build, single precision; the sibling-repo set used a Linux double-precision build)"
ITER = 200
RMS_OK = 1e-4
TIMEOUT = 60
ALPHA_RE = re.compile(r"^\s*a\s*=\s*(-?\d+\.\d+)\s+CL\s*=\s*(-?\d+\.\d+)")
CD_RE = re.compile(r"^\s*Cm\s*=\s*(-?\d+\.\d+)\s+CD\s*=\s*(-?\d+\.\d+)")
ITER_RE = re.compile(r"^\s*(\d+)\s+rms:\s*([-\d.E+]+)")


def sweep(dat, workdir, Re, M, alphas, n_panels, transition):
    """One XFOIL session over alphas (in order). transition = ('ncrit', N) or ('xtr', xu, xl).
    dat is None -> use XFOIL's built-in 'NACA 4412' generator."""
    lines = ["PLOP", "G", ""]
    lines += [f"LOAD {dat.name}"] if dat else ["NACA 4412"]
    lines += ["PANE", "PPAR", f"N {n_panels}", "", ""]
    lines += ["OPER", "VPAR"]
    lines += [f"N {transition[1]}"] if transition[0] == "ncrit" else [f"XTR {transition[1]:.3f} {transition[2]:.3f}"]
    lines += ["", f"VISC {Re:.0f}", f"MACH {M:.4f}", f"ITER {ITER}"]
    lines += [f"ALFA {a:.3f}" for a in alphas] + ["", "QUIT", ""]
    try:
        p = subprocess.run([XFOIL], input="\n".join(lines), cwd=workdir, capture_output=True, text=True, timeout=TIMEOUT)
        stdout, hung = p.stdout, False
    except subprocess.TimeoutExpired as e:      # XFOIL hangs on some hard thin-section cases: keep what it printed before
        stdout, hung = e.stdout or "", True
        if isinstance(stdout, bytes): stdout = stdout.decode("utf-8", "replace")
    out, res, rms = stdout.splitlines(), {}, None
    for i, ln in enumerate(out):
        m = ITER_RE.match(ln)
        if m:
            try: rms = abs(float(m.group(2)))
            except ValueError: rms = None
            continue
        m = ALPHA_RE.match(ln)
        if not m or rms is None or rms > RMS_OK:
            continue
        for j in range(i + 1, min(i + 3, len(out))):
            m2 = CD_RE.match(out[j])
            if m2:
                res[float(m.group(1))] = (float(m.group(2)), float(m2.group(2)))
                break
    return res, hung


def polar(dat, Re, M, alphas, n_panels, transition):
    """Merged up/down polar. Returns (sorted [alpha, cl, cd] rows, requested-but-missing alphas, timeouts)."""
    alphas = sorted(set(alphas))
    z = min(range(len(alphas)), key=lambda i: abs(alphas[i]))
    with tempfile.TemporaryDirectory() as td:
        wd = Path(td)
        if dat: shutil.copy(dat, wd / dat.name)
        res, to = {}, []
        for name, sw in (("up", alphas[z:]), ("down", alphas[: z + 1][::-1])):
            if len(sw) < 2: continue
            r, hung = sweep(dat, wd, Re, M, sw, n_panels, transition)
            res.update(r)
            if hung: to.append(name)
    rows = [[a, cl, cd] for a, (cl, cd) in sorted(res.items())]
    got = {round(a, 3) for a in res}
    return rows, [a for a in alphas if round(a, 3) not in got], to


def frange(a, b, s):
    n = int(round((b - a) / s))
    return [round(a + i * s, 4) for i in range(n + 1)]


def run_grid(jobs, workers=6):
    def one(j):
        key, dat, Re, M, alphas, npan, tr = j
        rows, miss, to = polar(dat, Re, M, alphas, npan, tr)
        print(f"{key}: {len(rows)} pts, {len(miss)} missing{' TIMEOUT ' + '+'.join(to) if to else ''}", flush=True)
        return key, rows, miss, to
    with ThreadPoolExecutor(workers) as ex:
        return list(ex.map(one, jobs))


def report996():
    src = ROOT / "data" / "report996" / "polars_forced_sibling.json"       # copy of the sibling repo's polars_forced.json
    sec_dir = ROOT / "data" / "report996" / "xfoil_sections"
    old = json.load(open(src))
    secs = old["sections"]
    new_re, new_m = [3e5], [0.1]
    Res = sorted(set(old["Res"]) | set(new_re)); Ms = sorted(set(old["Ms"]) | set(new_m))
    alphas = frange(-6, 14, 0.5)
    tr = ("xtr", 0.02, 0.02)
    jobs = []
    for s in secs:
        for Re, M in itertools.product(Res, Ms):
            k = f"{s}|{Re:.0f}|{M:.2f}"
            if k in old["polars"]: continue
            jobs.append((k, sec_dir / f"{s}.dat", Re, M, alphas, 240, tr))
    print(f"{len(jobs)} new (section, Re, M) polars", flush=True)
    out = run_grid(jobs)
    db = dict(old["polars"]); nonconv = {}
    for k, rows, miss, to in out:
        db[k] = rows
        if miss or to: nonconv[k] = dict(missing_alpha=miss, timeouts=to)
    res = dict(sections=secs, Res=Res, Ms=Ms, polars=db, transition="forced (0.02, 0.02)",
               header=dict(purpose="Report 996 gap fill (phase 11a): sibling polars_forced.json grid + Re 3e5 and M 0.1 entries",
                           xfoil_version=XFOIL_VERSION, panels_new_entries=240, transition="forced x_tr = 0.02 upper and lower",
                           Re_grid=Res, M_grid=Ms, alpha_grid_deg="-6 to 14, 0.5 step (up and down sweeps from 0)",
                           iter=ITER, convergence_rule="last viscous rms <= 1e-4",
                           inherited_entries=len(old["polars"]), new_entries=len(out),
                           new_entries_with_missing_points={k: v for k, v in nonconv.items()},
                           inherited_empty_entries=[k for k, v in old["polars"].items() if len(v) == 0],
                           generated=datetime.date.today().isoformat(), script="data/polars/xfoil_polars.py report996"))
    dst = ROOT / "data" / "report996" / "polars_forced_merged.json"
    json.dump(res, open(dst, "w"))
    print("wrote", dst, "non-converged entries:", len(nonconv))


SETTINGS = {"ncrit9": ("ncrit", 9), "ncrit5": ("ncrit", 5), "xtr005": ("xtr", 0.05, 0.05)}


def pereira(name):
    tr = SETTINGS[name]
    Res = [2e4, 3e4, 5e4, 7.5e4, 1e5, 1.5e5, 2e5, 3e5]
    Ms = [0.0, 0.1, 0.2, 0.3, 0.4]
    alphas = sorted(set(frange(-10, 10, 0.5) + frange(10, 20, 0.25)))
    jobs = [(f"naca4412|{Re:.0f}|{M:.2f}", None, Re, M, alphas, 180, tr) for Re, M in itertools.product(Res, Ms)]
    out = run_grid(jobs)
    db, nonconv = {}, {}
    for k, rows, miss, to in out:
        db[k] = rows
        if miss or to: nonconv[k] = dict(missing_alpha=miss, timeouts=to)
    res = dict(sections=["naca4412"], Res=Res, Ms=Ms, polars=db,
               transition=("free N_crit %s" % tr[1]) if tr[0] == "ncrit" else "forced x_tr %s" % tr[1],
               header=dict(purpose="Pereira NACA 4412 section polars (phase 11b)", setting=name,
                           xfoil_version=XFOIL_VERSION, panels=180, geometry="XFOIL built-in NACA 4412, PANE then PPAR N 180",
                           N_crit=tr[1] if tr[0] == "ncrit" else None, x_tr=list(tr[1:]) if tr[0] == "xtr" else None,
                           Re_grid=Res, M_grid=Ms, alpha_grid_deg="-10 to 10 step 0.5, 10 to 20 step 0.25 (up and down sweeps from 0)",
                           iter=ITER, convergence_rule="last viscous rms <= 1e-4",
                           non_converged=nonconv, extension="none here; Viterna extension is recorded in data/polars/viterna_extension.json",
                           generated=datetime.date.today().isoformat(), script=f"data/polars/xfoil_polars.py pereira {name}"))
    dst = ROOT / "data" / "pereira" / f"naca4412_xfoil_{name}.json"
    json.dump(res, open(dst, "w"))
    print("wrote", dst, "entries with non-converged points:", len(nonconv))


if __name__ == "__main__":
    if sys.argv[1] == "report996": report996()
    elif sys.argv[1] == "pereira": pereira(sys.argv[2])
    else: sys.exit(__doc__)
