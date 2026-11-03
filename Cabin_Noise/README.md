# Cabin Noise: low-fidelity turboprop cabin noise tool

This is a PySide6 desktop tool that estimates propeller-aircraft cabin SPL, dBA and dBC. It works from mission, propeller and fuselage geometry, the sidewall layer stack, openings and cabin absorption. It does not use airfoil polars, structural-acoustic coupling or CFD. Use it as a fast companion to the PAIN recreation in `../PAIN_Program`: run design sweeps here, then check detailed low-frequency behaviour in PAIN.

The method, the equations and the validation plan are in [projectPlan.md](projectPlan.md). Read its "Implementation notes" section to see what is built and where the code differs from the plan.

**Nothing is fitted.** Every quantity comes from physics, from statistics or from an input you state. Experimental data is used only for blind comparison.

## Install and run

```bash
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt
.venv/Scripts/python app.py                 # opens the generic twin-turboprop example
.venv/Scripts/python app.py my_case.json    # opens a saved project
```

## Tests

[VERIFICATION.md](VERIFICATION.md) maps every equation to its published source and to the independent test that checks it.

```bash
.venv/Scripts/python -m pytest -q                  # 79 tests: source checks, end-to-end hand check (VERIFICATION.md), core, V0a-V3
.venv/Scripts/python scripts/smoke_gui.py          # offscreen GUI smoke (run, compare, mission, sweep, validation)
```

## Layout

| Path | Contents |
|---|---|
| `cabin_noise/core/` | Pure NumPy/SciPy code with no Qt. `pipeline.run_case(project)` computes everything for one segment. |
| `frequencies`, `atmosphere`, `mission` | 1/3-octave grid, ISA, segments and the operating point |
| `source_tonal` | Rotating point forces in forward flight, solved in the frequency domain. Includes Gutin's formula. |
| `blade` | Optional blade-geometry source: BEMT strip loads (thin-airfoil sections, Prandtl tip loss), each strip a compact rotating force |
| `flight` | Flight and lab runners for the source cases (flush microphones, static near field) |
| `materials` (bay, table) | `Panel.bay_a/bay_b`: optional stiffened-bay stiffness (verified, not validated); `PorousTable`: blanket from measured properties |
| `scattering` | Rigid-cylinder surface factor, used for far-side propeller shadowing |
| `source_tbl` | Goody TBL wall-pressure spectrum |
| `porous`, `tmm`, `materials` | Delany-Bazley model, transfer matrices, diffuse and band averaging, composites |
| `cabin`, `seats`, `weighting` | Room equation, T60, Schroeder split, box-mode seat shape, A/C weighting |
| `io`, `validation` | JSON projects, CSV export, default example, case runner |
| `cabin_noise/gui/` | Main window, input tabs (`panels.py`), plots, Validation tab, worker thread |
| `cabin_noise/data/` | `materials.json` (generic library values) and `validation/cases.yaml` |
| `tests/` | pytest suite |

## Validation status (2026-11-02)

- **Verification V0a, V0b, V0c, V1, V2, V3** (analytic checks): all pass. These checks never carry a validation verdict.
- **Validation V4a** (TP-1964 bare-cylinder reverberant NR, data reused from PAIN_Program): **run 2026-11-02, not met**. The worst error is 16 dB in 250 Hz-2 kHz: the plane-wave TL misses resonant cylinder transmission and treats the thick end caps as mass-law panels. See projectPlan.md, "V4a result".
- **Validation V5** (CR-178004 flight exterior harmonics, flight 3, 101 points): **run 2026-11-02, not met**. 43 % of points are within +-6 dB and the model overpredicts by +6 dB on average. The cause is the single-radius point force in the near field; see projectPlan.md, "V5 result".
- **Validation V5c / V5d** (NACA Report 996 static near-field harmonics, 52 points, data reused from PAIN_Program): **both met**. The default point source has 94 % within +-6 dB (mean +2.2 dB); the optional blade-geometry source has 98 % (mean -0.1 dB).
- **Validation V5b** (CR-178004 exterior boundary-layer bands): **met**, 82 % within +-6 dB.
- **Validation V6** (fiberglass insertion loss, CR-178004 App. J): **not met**, 48 %. Mid frequencies (400 Hz-1.6 kHz) agree; low and high bands do not.
- **Validation V7** (untreated cabin tones from the measured exterior, CR-178004 App. B): **not met**, 11 %, +12.8 dB on average. The infinite-panel skin transmits too much at the blade passage frequency.
- **Validation V4b / V4c** (CR-3813 stiffened, trimmed test cylinder, reverberant NR; inputs all printed): **not met**, 21 %, +13 dB. The trimmed curved wall is far too good above 160 Hz; PAIN over-predicted this case too. V4c (optional bay-stiffness skin) equals V4b, because curvature dominates on this cylinder.
- **Validation V4d** (V4b with limp-frame blankets): **not met**, unchanged from V4b; the trim model is not that case's error. The limp option cuts V6's low-frequency overprediction (post-hoc re-run 282/519, information only).
- **Validation V4** (TM-85722 lab TL): **not run**. The report is not in the repo.
- Experimental cases are judged with the low-fi policy: met when at least 75 % of the points are within +-6 dB. V4a keeps its original +-3 dB criterion. Each case needs two files in `cabin_noise/data/validation/`: the digitized curve (`<id>.csv`) and a project file built only from the report's stated inputs (`<id>_inputs.json`). The pass targets are fixed and dated in `cases.yaml`.
- **V8** (cross-check against PAIN): information only.

Of ten experimental comparisons, three are met: V5b (boundary-layer pressure) and V5c / V5d (propeller near field, lab). Most misses trace to one plan assumption: sidewall transmission is plane-wave and infinite-panel, which cannot represent a finite fuselage's modal response (V4a, V4b/c, V7, part of V6). The others are the single-radius source (V5) and the rigid-frame blanket at low frequency (V6). Use the tool for relative trades at mid frequencies, where V6 agrees; treat absolute cabin levels as unvalidated (13 dB off at BPF on the one aircraft tested, and +13 dB in NR on the trimmed lab cylinder). Treat absolute levels as **unvalidated**, especially for thin, lightly damped walls below the ring frequency. The repo's reusable data is inventoried in projectPlan.md.
