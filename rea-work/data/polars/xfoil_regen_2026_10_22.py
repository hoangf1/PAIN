"""Regenerate the missing alpha points of truncated Report 996 polar entries (2026-10-22).

Settings are phase 11's (xfoil_polars.py): XFOIL 6.99, 240 panels, forced x_tr 0.02/0.02, ITER 200, a point is
accepted only if the last viscous rms <= 1e-4, alpha -6..14 step 0.5, sweeps away from 0, 60 s hang limit.
Only the sweep handling differs: XFOIL output is streamed line by line so points printed before a hang are kept,
and after a hang the sweep restarts in a new session at the next alpha (the hung alpha is skipped). Entries still
short after pass 1 get pass 2, stepping alpha in 0.25 deg sub-steps (only grid alphas are recorded).
Merge: existing points are kept unchanged, only absent alphas are added; alphas still absent are listed, not filled.

Run from rea-work (XFOIL_EXE set):
    python data/polars/xfoil_regen_2026_10_22.py pass1 keys.json pass1.json   # keys: entries empty or alpha_max < 8
    python data/polars/xfoil_regen_2026_10_22.py pass2 keys.json pass2.json   # keys: entries still short after pass 1
    python data/polars/xfoil_regen_2026_10_22.py merge pass1.json pass2.json [--dry]
"""
import json, sys, subprocess, threading, time, tempfile, shutil, os, hashlib, datetime
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import numpy as np

SUBSTEP = 0.0

from concurrent.futures import ThreadPoolExecutor

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import xfoil_polars as xp   # regexes, settings, frange

XFOIL = xp.XFOIL
SEC = HERE.parent / "report996" / "xfoil_sections"
HANG_S = xp.TIMEOUT          # same 60 s limit per session


def session(dat, wd, Re, M, alphas):
    """Run one XFOIL session over alphas; return (results {alpha: (cl, cd)}, last alpha reached, hung)."""
    lines = ["PLOP", "G", "", f"LOAD {dat.name}", "PANE", "PPAR", "N 240", "", "", "OPER", "VPAR",
             "XTR 0.020 0.020", "", f"VISC {Re:.0f}", f"MACH {M:.4f}", f"ITER {xp.ITER}"]
    lines += [f"ALFA {a:.3f}" for a in alphas] + ["", "QUIT", ""]
    p = subprocess.Popen([XFOIL], cwd=wd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, text=True)
    out = []
    t = threading.Thread(target=lambda: [out.append(l) for l in p.stdout], daemon=True)
    t.start()
    p.stdin.write("\n".join(lines)); p.stdin.close()
    t0 = time.time(); hung = False
    while p.poll() is None:
        if time.time() - t0 > HANG_S:
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
                res[last] = (float(m.group(2)), float(m2.group(2))); break
    return res, last, hung


def sweep(dat, wd, Re, M, alphas):
    """Sweep in the given order; restart after a hang at the alpha after the last one reached."""
    res, todo, n, hangs = {}, list(alphas), 0, 0
    while todo:
        r, last, hung = session(dat, wd, Re, M, todo); n += 1; res.update(r)
        if not hung:
            break
        hangs += 1
        # the hang happened on the alpha after `last` (or on the first if none was printed)
        k = 0 if last is None else next((i for i, a in enumerate(todo) if abs(a - last) < 1e-6), -1) + 1
        todo = todo[k + 1:]          # skip the alpha that hung
    return res, n, hangs


def one(key):
    """Regenerate all grid alphas of one (section|Re|M) key."""
    s, Re, M = key.split("|"); Re = float(Re); M = float(M)
    alphas = xp.frange(-6, 14, 0.5)
    with tempfile.TemporaryDirectory() as td:
        wd = Path(td); shutil.copy(SEC / f"{s}.dat", wd / f"{s}.dat")
        res, n, h = {}, 0, 0
        sub = SUBSTEP
        def fine(sw):
            if not sub: return sw
            out = [sw[0]]
            for a, b in zip(sw, sw[1:]):
                n = int(round(abs(b - a) / sub))
                out += [round(a + (b - a) * i / n, 4) for i in range(1, n + 1)]
            return out
        for sw in (fine(alphas[12:]), fine(alphas[:13][::-1])):      # up from 0, down from 0 (as phase 11)
            r, nn, hh = sweep(wd / f"{s}.dat", wd, Re, M, sw); res.update(r); n += nn; h += hh
    grid = {round(a, 3) for a in alphas}
    rows = [[a, cl, cd] for a, (cl, cd) in sorted(res.items()) if round(a, 3) in grid]   # record grid alphas only
    print(f"{key}: {len(rows)} pts, sessions {n}, hangs {h}", flush=True)
    return key, dict(rows=rows, sessions=n, hangs=h)




def combine(p1, p2):
    """Pass 1 first; pass 2 adds only alphas pass 1 did not converge."""
    out = {k: dict(v, **{"pass": "1"}) for k, v in p1.items()}
    for k, v in p2.items():
        have = {round(r[0], 3) for r in out[k]["rows"]}
        add = [r for r in v["rows"] if round(r[0], 3) not in have]
        out[k]["rows"] = sorted(out[k]["rows"] + add)
        out[k]["sessions"] += v["sessions"]; out[k]["hangs"] += v["hangs"]
        out[k]["pass"] = f"1+2 ({len(add)} pts from 0.25 deg sub-step pass)"
    return out



def merge(regen, path, dry):
    raw = open(path, "rb").read(); old_sha = hashlib.sha256(raw).hexdigest()
    d = json.loads(raw); P = d["polars"]
    grid = [round(-6 + 0.5 * i, 4) for i in range(41)]
    audit, still_missing, dcl, dcd = {}, {}, [], []
    for k, r in regen.items():
        old = P.get(k, [])
        have = {round(a, 3): (cl, cd) for a, cl, cd in old}
        new = {round(a, 3): (cl, cd) for a, cl, cd in r["rows"]}
        shared = sorted(set(have) & set(new))
        ov = [(abs(have[a][0] - new[a][0]), abs(have[a][1] - new[a][1])) for a in shared]
        dcl += [o[0] for o in ov]; dcd += [o[1] for o in ov]
        added = sorted(set(new) - set(have))
        merged = dict(have); merged.update({a: new[a] for a in added})
        P[k] = [[a, cl, cd] for a, (cl, cd) in sorted(merged.items())]
        miss = [a for a in grid if round(a, 3) not in merged]
        if miss: still_missing[k] = miss
        audit[k] = dict(old_points=len(old), old_alpha_range=[min(have), max(have)] if have else None,
                        added_points=len(added), new_alpha_range=[min(merged), max(merged)] if merged else None,
                        overlap_points=len(shared),
                        overlap_max_abs_dcl=round(max((o[0] for o in ov), default=0), 4),
                        overlap_max_abs_dcd=round(max((o[1] for o in ov), default=0), 5),
                        sessions=r["sessions"], hangs=r["hangs"], passes=r.get("pass", "1"))
    d["header"]["regeneration_2026_10_22"] = dict(
        reason="109 entries were empty or stopped below alpha = 8 deg (83 inherited from the sibling set, 26 from phase 11a with up-sweep timeouts)",
        settings="phase 11 unchanged: XFOIL 6.99 Windows, 240 panels, forced x_tr 0.02/0.02, ITER 200, last viscous rms <= 1e-4, alpha -6..14 step 0.5, sweeps away from 0",
        change="sweep handling only: output streamed so points before a hang are kept; after a 60 s hang the sweep restarts at the next alpha; the hung alpha is skipped; entries still short after pass 1 got a second pass stepping alpha in 0.25 deg sub-steps (only the 0.5 deg grid alphas are recorded; pass-1 values kept where both exist)",
        rule="existing points kept unchanged; only absent alphas added; alphas still absent are listed, not filled",
        previous_file_sha256=old_sha, entries=audit, still_missing=still_missing,
        overlap_summary=dict(points=len(dcl), max_abs_dcl=round(max(dcl, default=0), 4), median_abs_dcl=round(float(np.median(dcl)) if dcl else 0, 4),
                             max_abs_dcd=round(max(dcd, default=0), 5), median_abs_dcd=round(float(np.median(dcd)) if dcd else 0, 5)),
        script="data/polars/xfoil_regen_2026_10_22.py", generated=datetime.date.today().isoformat())
    amax_old = [a["old_alpha_range"][1] if a["old_alpha_range"] else None for a in audit.values()]
    amax_new = [a["new_alpha_range"][1] if a["new_alpha_range"] else None for a in audit.values()]
    print("entries", len(audit), "added points", sum(a["added_points"] for a in audit.values()))
    print("alpha_max >= 8 before:", sum(1 for x in amax_old if x is not None and x >= 8), "after:", sum(1 for x in amax_new if x is not None and x >= 8))
    print("still missing entries:", len(still_missing), "empty after:", sum(1 for k in audit if not P[k]))
    print("overlap:", d["header"]["regeneration_2026_10_22"]["overlap_summary"])
    if not dry:
        json.dump(d, open(path, "w")); print("wrote", path)

def run(keys, workers=6):
    with ThreadPoolExecutor(workers) as ex:
        return dict(ex.map(one, keys))


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd in ("pass1", "pass2"):
        SUBSTEP = 0.25 if cmd == "pass2" else 0.0
        json.dump(run(json.load(open(sys.argv[2]))), open(sys.argv[3], "w"))
    elif cmd == "merge":
        regen = combine(json.load(open(sys.argv[2])), json.load(open(sys.argv[3])))
        merge(regen, str(HERE.parent / "report996" / "polars_forced_merged.json"), "--dry" in sys.argv)
    else:
        sys.exit(__doc__)
