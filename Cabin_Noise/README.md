# Cabin Noise: low-fidelity turboprop cabin noise tool

This is a PySide6 desktop tool that estimates propeller-aircraft cabin SPL, dBA and dBC with a **low-fidelity paper pipeline**. Every block follows a published method exactly and is verified against it:

```
Gutin tones + Goody boundary layer  ->  CR-132602 sidewall noise reduction  ->  interior = exterior - NR
                                        (openings, insertion loss: TM-85722)
```

[METHOD.md](METHOD.md) maps each block to its paper. [AUDIT.md](AUDIT.md) records the code audit. [VERIFICATION.md](VERIFICATION.md) lists the checks against the papers. [VALIDATION.md](VALIDATION.md) explains each verification and validation case, why its data were chosen, and links its figure. The reports are in `references/`.

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
.venv/Scripts/python -m pytest -q                  # paper checks, end-to-end hand check, pipeline
.venv/Scripts/python scripts/smoke_gui.py          # offscreen GUI smoke
```

## Layout

| Path | Contents |
|---|---|
| `cabin_noise/core/` | `source_tonal` (Gutin), `source_tbl` (Goody), `sea` (CR-132602 eqs. 46, 52), `materials` (sidewall, openings, surfaces), `pipeline` (`run_case`), `cabin`, `weighting`, `atmosphere`, `mission`, `io`, `validation`, `flight` (case runners) |
| `cabin_noise/gui/` | Main window, input tabs, plots, Validation tab with a draggable stage map |
| `cabin_noise/data/` | Surface absorption library; `validation/` (cases, map layout, references, inputs) |
| `references/` | NASA CR-132602 and TM-85722 (from NTRS) |
| `docs/figures/` | Per-case figures and the stage map linked from VALIDATION.md (`scripts/make_doc_figures.py`) |
| `tests/` | pytest suite (`independent.py` holds the independent re-implementations) |

**Default example:** a generic twin turboprop with a 22.7 x 2.64 x 1.9 m cabin; cruise 97.6 dBA room average, 102.3 dBA at the 95th-percentile seat. Cabin air (8000 ft, 20 C) and the cavity absorption (CR-132602 sec. 6.2's table) are set to these defaults and can be changed in the Cabin and Sidewall tabs.

## Validation status (paper pipeline, 2026-11-02)

- **Verification:** V0a, V1, V2, V3 pass (no verdict).
- **V2p, a reproduction of the paper's own printed prediction (CR-132602 Fig. 14):** check failed.
  - From the report's stated inputs, the single-wall NR is 2.1-3.3 dB below Fig. 14, a near-constant offset. The curve's shape matches.
  - The report computed Fig. 14 with eq. (53), which keeps the cabin-to-wall area ratio S5/S2, but it does not state the ratio. A post-hoc S5/S2 = 2 reproduces the curve within 0.3 dB.
  - The double wall needs the blanket mass, which the report does not state. Fig. 14 therefore cannot show whether the authors used 2/eps or 4/eps.
  - Details are in `cases.yaml`.
- **Validation:** 1 of 8 met (V5b, the boundary-layer source). V6, the insertion loss, is close at 72 % (75 % needed). The other misses fall where the papers' own stated limits put them:
  - CR-132602's mass-law wall well below half the ring frequency (V7, V4a, V4b);
  - Gutin's far-field formula in the near field (V5c; V5 at 64 %).
- **V4 (TM-85722 Fig. 18, lab TL of the prop-plane treated panel), run 2026-11-03:** not met, 5 of 11 bands within ±6 dB.
  - The mass-law wall (skin plus treatment mass) tracks the lab TL within 3 dB up to 250 Hz.
  - Above 315 Hz it is 6–13 dB low: the septa and barrier on fiberglass act as a second wall, which a single limp wall cannot show.
- The details are in METHOD.md sec. 4. Retired cases and the earlier pipeline's records are in git (up to commit 1c2c8fe).

**Use:** relative trades (treatments, masses, absorption) at mid and high frequencies. Absolute tone levels at the blade passage frequency are outside the papers' stated range.
