# Cabin Noise: low-fidelity turboprop cabin noise tool

This is a PySide6 desktop tool that estimates propeller-aircraft cabin SPL, dBA and dBC with a **low-fidelity paper pipeline**. Every block follows a published method exactly and is verified against it:

```
Gutin tones + Goody boundary layer  ->  CR-132602 sidewall noise reduction  ->  interior = exterior - NR
                                        (openings, insertion loss: TM-85722)
```

[METHOD.md](METHOD.md) maps each block to its paper. [VERIFICATION.md](VERIFICATION.md) lists the checks against the papers. The reports are in `references/`.

It is the fast companion to the PAIN recreation in `../PAIN_Program`. PAIN models structural and acoustic modes with airfoil-based sources; this tool does not.

## Install and run

```bash
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt
.venv/Scripts/python app.py                 # opens the generic twin-turboprop example
.venv/Scripts/python app.py my_case.json    # opens a saved project
```

## Tests

```bash
.venv/Scripts/python -m pytest -q                  # 45 tests: paper checks, end-to-end hand check, pipeline
.venv/Scripts/python scripts/smoke_gui.py          # offscreen GUI smoke
```

## Layout

| Path | Contents |
|---|---|
| `cabin_noise/core/` | `source_tonal` (Gutin), `source_tbl` (Goody), `sea` (CR-132602 eqs. 46, 52), `materials` (sidewall, openings, surfaces), `pipeline` (`run_case`), `cabin`, `weighting`, `atmosphere`, `mission`, `io`, `validation`, `flight` (case runners) |
| `cabin_noise/gui/` | Main window, input tabs, plots, Validation tab with a draggable stage map |
| `cabin_noise/data/` | Surface absorption library; `validation/` (cases, map layout, references, inputs) |
| `references/` | NASA CR-132602 and TM-85722 (from NTRS) |
| `tests/` | pytest suite (`independent.py` holds the independent re-implementations) |

## Validation status (paper pipeline, 2026-11-02)

- **Verification:** V0a, V1, V2, V3 all pass (no verdict).
- **Validation:** 1 of 8 met (V5b, the boundary-layer source). V6, the insertion loss, is close at 72 % (75 % needed). The other misses fall where the papers' own stated limits put them:
  - CR-132602's mass-law wall well below half the ring frequency (V7, V4a, V4b);
  - Gutin's far-field formula in the near field (V5c; V5 at 64 %).
- V4 (TM-85722 lab TL) is not run; Fig. 18 is not digitized yet.
- The details are in METHOD.md sec. 4. Retired cases and the earlier pipeline's records are in git (up to commit 1c2c8fe).

**Use:** relative trades (treatments, masses, absorption) at mid and high frequencies. Absolute tone levels at the blade passage frequency are outside the papers' stated range.
