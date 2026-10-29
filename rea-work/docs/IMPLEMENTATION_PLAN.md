# PAIN Recreation — Plans & Phased Implementation

Single source of truth for building this project without re-deriving context in chat. Reorganized 2026-10-20 for hand-off to a new executing agent: the content of the earlier version is kept, nothing was re-decided, and execution detail (files, functions, tests, commands, outputs, stop points) was added to every open phase.

**Read first:** §0 of this file · `METHODOLOGY.md` · `VALIDATION_GUIDELINE.md` · `flowchart.md` · `README.md`  
**Code:** `PAIN.jl/` (Julia package; `Manifest.toml` pins CCBlade 1.0.0 and AcousticAnalogies 1.0.0)  
**Source PDFs (in `rea-work\references`, moved there 2026-10-21):** `Pain Methodology.pdf` (CR-3813), `Pain User Manual.pdf` (CR-172425), `Pain Validation.pdf` (CR-172428), `NASA Report 996.pdf`, `Pereira.pdf`. Text extractions: `docs/extracted/`. CR-3813 App. E PDF page = printed page E-n + 116 (E-19 → PDF 135).

## Contents

0. Agent hand-off brief: rules, workflow, stop conditions
1. Goal and validity classes
2. Data register and digitization instructions (status, procedure, one card per figure)
3. Current status and open work queue
4. Architecture
5–8ac, 11. *(in `COMPLETED_PHASES.md`, same section numbers, moved 2026-10-29)* every completed phase, the queue Q0–Q66 and the 2026-10-21 review
9. Reference appendices (BBN evidence, Report 996 figures and data, Pereira polar specification, variables)
10. Optional future work, key formulas, file checklist

---

## 0. Agent hand-off brief

### 0.1 The project in five lines

- Julia recreation of NASA PAIN (Propeller Aircraft Interior Noise, CR-3813) in `PAIN.jl`.
- Pipeline: free-field pressure on a 160-point fuselage grid → blocking Eq. (43) → cabin acoustic modes (CYL2D, App. C) and structural modes (MRP, Table D-1) → PAIN core (coupling Eq. 52, generalized force Eq. 42, trim App. A, loss factors §3.8, tone pressure Eq. 8) → interior SPL → dB(A)/SIL.
- Two free-field sources: `:e11` (NASA's measured Fig. E-11 line plus GEXT; a validation test only, never a user option) and `:aircraft` (CCBlade BEMT → AcousticAnalogies F1A; the only user source; X-EXTRAP).
- All planned phases (0–38) are done as of 2026-10-22: the cabin chain follows CR-3813 without tuning (η_T = 0.5 for the NASA test article); the aircraft source path and its checks against BBN/Wilby, NACA Report 996 and Pereira (21–28) are recorded, most not met against the frozen criteria; aircraft cabin inputs, parametric blocks and the uncertainty band (29–31) are in place, with the 31e coverage check not met. Open items for the author: I-21 (Eqs. 19–23 reading), `:appd` vs the fitted surrogate as default, I-18 mirroring, revised phase 31 ranges (post-hoc). Planned next (2026-10-22): airfoil-polar display cases with measured TN 1546 / Report 824 polars.
- Nothing here is validated unless the validity table (§1) says so.

### 0.2 Standing rules (every step)

| # | Rule |
|---|------|
| R1 | **No change to Julia code under `PAIN.jl/src/` without the author's explicit confirmation in the session.** Steps marked **[CONFIRM]** stop and present the exact proposed diff first. New scripts under `scripts/` and new tests that do not change `src/` behaviour may be written without asking; overrides that live only inside a script's own process are allowed (precedent: 19d, 19f). Comment-only edits in `src/` also wait (33e). |
| R2 | **No tuning, no circularity (CLAUDE.md).** Never fit, scale, select or change a parameter, polar, input, option, sign or data reading to reduce a residual against the data it is compared with, and never compare a calibrated path with the data it was calibrated to. If any value changes after a result is seen, that result is labelled *calibrated* with the parameter named, and the original result stays in the record. |
| R3 | **Pre-register.** Pass criteria (quantity, statistic, tolerance, cases, pass rule, label) are written and dated (YYYY-MM-DD) in this file and in `VALIDATION_GUIDELINE.md` before the first comparison run. A value marked **[AUTHOR]** is set by the author: the agent may propose it with its evidence but does not fix it. A blank criterion blocks the step. |
| R4 | **Labels.** Use the validity classes of §1. Never claim NASA experimental validation for the CCBlade/F1A free field. T1 and T2 are not validation. Fuselage scattering and reflection stay V-ASSUMED. |
| R5 | **Docs in the same session (CLAUDE.md).** Every code or result change updates `README.md`, `docs/flowchart.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/METHODOLOGY.md`, `docs/VALIDATION_GUIDELINE.md`. When a step is done: tick it and date it; when every step of a phase is done, move the phase to the bottom of `COMPLETED_PHASES.md` (moved out of this file 2026-10-29), and its queue row to that file's §3. |
| R6 | **Line endings are preserved.** LF: `IMPLEMENTATION_PLAN.md`, `README.md`, `flowchart.md`. CRLF: `METHODOLOGY.md`, `VALIDATION_GUIDELINE.md`, `src/pain_core.jl`, `test/runtests.jl`. Any other file: check with `file <path>` before editing and keep what is there. |
| R7 | **Commands.** PowerShell, from `C:\Users\FrancisHoang\git\PAIN\rea-work\PAIN.jl`, one command per line, `julia --project=. ...`. If Julia cannot run in the agent's environment, hand the commands to the author and wait for the output. **Never write a number that no run produced.** |
| R8 | **Reports are generated, not typed.** Each run writes its report under `docs/validation_reports/<name>.md` from the script, containing: date, script name, inputs and a settings echo, the criterion quoted with its registration date, the result table, the label, and what the result does not show. |
| R9 | **Reference data are never invented.** If a step needs a value from a figure or table that is not in `data/`, stop and add it to the data register (§2) as a request to the author. Do not estimate it from the plot. A digitization is valid only if a script located every value in the pixels of a render calibrated on labelled gridlines (§2.2), with a QA overlay and a pixel sidecar file; values typed by eye, placed on a round grid, copied from another pass or filled to satisfy a check are void (review I-03, I-05). |
| R10 | **Wording.** Cite NASA figures and equations by number and page. Follow the paper's form, not another normalization. No "expected to fail" wording; never "until compared to ANOPP" (no ANOPP comparison will happen). Be concise. |
| R11 | **Frozen baselines.** `Pkg.test()` compares against `data/baselines/phase17_baselines.csv` at rtol 1e-6. Renewing it is a dated decision of the author, recorded in its header and here. |
| R12 | **Numbering.** Phases are numbered in run order. Do not renumber. A new sub-step takes the next free letter of its phase. |
| R13 | **Cursor writer check (CLAUDE.md, 2026-10-21).** Code changes delegated to Cursor (`scripts\cursor-exec.ps1`, write mode) are checked before they are accepted or built on: (1) diff against a pre-run snapshot and revert edits outside the named files; (2) confirm no criterion, tolerance, reference/digitized data, recorded result or fitted parameter changed unless the task named it (post-hoc labels dated); (3) run the affected checks yourself (`Pkg.test()` from `PAIN.jl`, or GUI smokes) and read the output; (4) spot-check reported numbers against `docs/validation_reports`; (5) confirm the five docs were updated. One Cursor writer at a time; a failed check is fixed before the next task. |

### 0.3 Per-step workflow

1. Read the step, its prerequisites (§3 queue) and the data it needs (§2). If a needed data item is not `present`, stop (R9).
2. If the step changes `src/`, write the proposed diff and wait for confirmation (R1).
3. If the step compares against data, write the criterion (R3) and date it here and in `VALIDATION_GUIDELINE.md`.
4. Write the script or test. Scripts under `scripts/{run,checks,…}/` begin with `using Pkg; Pkg.activate(joinpath(@__DIR__, "..", ".."))` and write their own report (R8).
5. Run, or hand over, in this order: `Pkg.test()`, then the step's scripts. Record wall times where a step asks for cost.
6. Record the result under the step in this file: one paragraph with numbers, criterion met or not met, label, and what is carried forward.
7. Update the other four docs (R5) and list the changed sections in the step's "Docs updated" line.
8. Tick the step. When every step of the phase is ticked, move the phase to the bottom of `COMPLETED_PHASES.md`.

### 0.4 Stop and ask the author when

- a step is marked [CONFIRM] or [AUTHOR];
- `Pkg.test()` fails on a test that is not the subject of the current step;
- the e11 T1/T2 numbers change at a step that should not change them (phase 21: any change above 0.01 dB from `phase20_baseline.md`);
- a printed equation and the code disagree and this file does not already record the decision;
- a data item in §2 is missing, or a digitized value looks inconsistent with the PDF;
- a result would change a claim in `METHODOLOGY.md` (claims change only at 33c, or where a step says so).

### 0.5 Definition of done (every phase)

`Pkg.test()` passes, or its failures are the recorded subject of the step; each step's report exists and was written by its script; the criterion text and its date precede the result; the five docs are updated; the phase is ticked and moved to the bottom of `COMPLETED_PHASES.md`.

---

## 1. Goal and validity classes

Recreate NASA **PAIN** (Propeller Aircraft Interior Noise) in Julia.

| Original | This recreation |
|----------|-----------------|
| ANOPP → free-field grid on fuselage skin | **CCBlade.jl** → **AcousticAnalogies.jl** (F1A) → same grid interface |
| CYL2D + MRP + MRPMOD + PAIN (Fortran) | Merged Julia modules in `PAIN.jl` |
| Cabin tonal + 1/3-octave SPL | Same outputs + dB(A)/SIL helpers |

**Hard rule:** do not claim NASA experimental validation for the uncalibrated CCBlade/F1A free field. Cabin tonal T1 (Fig. E-16) and T2 (1.25–2 kHz, Fig. E-9) are in-sample consistency checks against digitized figures with documented gates, not validation (`METHODOLOGY.md`). Results from before the grid azimuth fix (12b, 2026-10-20) are void. Since 17a the tone path is the untuned CR-3813 chain (Eq. 8, App. A trim, §3.8 losses). With NASA's Phase III trim loss factor η_T = 0.5 (CR-3813 p. E-24; author's decision 2026-10-20), the reproduction of NASA's own PAIN predictions (18b-r) is +3.7, +0.2, +9.1 dB at H1–H3 (4 dB criterion not met, 2 of 3; H3 open, step 19i). T1 (18a-r) is 81.04, 75.00, 75.29 dB: H1 and H2 within 4 dB of NASA's prediction but not of the measured mean, H3 fails, no claim. T2 passes at 1.25 kHz only and still carries `bb_j2_scale` = 0.5 from an earlier fit until 30b.

### Validity classes

| Tag | Meaning |
|-----|---------|
| **V-EXP** | vs experiment (App. E / CR-172428), data the parameters were not fitted to |
| **calibrated (in-sample)** | parameters were fitted against the same figures it is compared to, no held-out subset documented; a goodness-of-fit, not a validation (T1 against E-16/E-17, T2 against E-9). "V-EXP, calibrated" is kept only where inputs are scaled but the compared quantity is held out (Report 996 scaled-load runs) |
| **V-CODE** | vs NASA tables (C-1, D-1) |
| **V-UNIT** | vs written equation |
| **V-ASSUMED** | physics not in papers (off-line grid extension; Spbl slope) |
| **X-EXTRAP** | aircraft / CCBlade path (optional Table-8 peak cal) |

---

## 2. Data register and digitization instructions

Every reference value a remaining step compares against, where it is, and what is still to be digitized. Checked against the folder on 2026-10-21. **Rule R9 applies:** a step that needs an item marked *to do* waits until the item is done; no value is estimated from a plot inside an analysis script.

All PDFs are in `C:\Users\FrancisHoang\git\PAIN\rea-work\` (bash path `rea-work/`). "PDF p." is the 1-based page index of the PDF file (what a viewer's page box and `pymupdf` `doc[p-1]` use); "printed p." is the number printed on the page. Page indices below were checked on 2026-10-21 by text search and page renders.

### 2.1 Status of every data item (D-IDs are used throughout this file)

| ID | Item | Status 2026-10-21 | Where it is / goes | Needed by |
|----|------|-------------------|--------------------|-----------|
| D-01 | BBN report PDFs | **Present** | `rea-work\references\NASA Contractor Report 158919.pdf` (103 p.), `rea-work\references\NASA Contractor Report 159124.pdf` (146 p.) | 24 |
| D-02 | BBN phase and coherence per pair, harmonic, run | **Present** (typed, exact as printed) | `data\NASA_CR-158919\bbn_phase_coherence_CR158919_appendixC.csv` (PDF p. 86–95); `data\NASA_CR-159124\bbn_phase_coherence_CR159124_appendixD.csv` (PDF p. 94–97); harmonic phase tables C-1, C-2 of CR-159124 | 24c |
| D-03 | BBN trace velocities | **Present** | CR-158919 Tables 8, 9 (`bbn_trace_velocity_table8.csv`, `_table9.csv`); CR-159124 Tables 6, 9 | 24c |
| D-04 | BBN microphone geometry | **Present, one gap** | CR-158919 Fig. 1 table (`bbn_microphones_fig1.csv`), CR-159124 Tables 7 (hub distances) and 8 (hub angles). **Gap: propeller rotation direction and hub position in the Fig. 1 frame → D-21** | 24b, 24c |
| D-05 | BBN levels | **Present** | CR-158919 Tables 3, 4 and App. A; CR-159124 Tables 3, 4 and Apps. A, B | 24d |
| D-06 | BBN run conditions | **Present** | `bbn_runs_table1.csv` in both folders | 24c |
| D-07 | Report 996 files from the sibling repository | **Present (copied 2026-10-21)**; checksums written 2026-10-21 | `data\report996\naca_4-5-08-03\` (same tree as the source: `blade_form.csv`, `propeller.yaml`, `analytical\`, `measured\`, `plots\`). Every plan reference to "`data\report996\<file>` from the data folder" means this subfolder. `CHECKSUMS.txt` SHA-256 of every file (14 files) | 25–27 |
| D-08 | BBN longitudinal phase vs frequency | Author's Fig. 18 files valid; **Figs. 19, 20 author digitized 2026-10-21** (`Fig 19.txt`, `Fig 20.txt`; convert per I-15); agent's Fig. 18–20 files void (I-16) | `data\NASA_CR-159124\bbn_phase_vs_freq_fig{18,19,20}_*.csv` | 24e (X-EXTRAP, not blocking) |
| D-09 | Hartzell 9333C-3 blade table | **Present 2026-10-21** (C-14): PDF downloaded, Table III typed and checked; tip beyond 40 in **not found** | `rea-work\references\Hartzell_114-8.pdf`, `data\NASA_CR-158919\hartzell_9333C_table3.csv` | 24c (blade), 24e |
| D-10 | Pereira Fig. 6 (acoustic spectra) | **Author digitized 2026-10-21** (raw export; convert and check per I-15; replaces C-02) | `data\pereira\pereira_fig6_peaks.csv` | 28 |
| D-11 | Pereira Fig. 8 (tonal directivity, harmonics 1–6) | **Present 2026-10-21** (pixel digitization, `pereira_fig8_directivity.csv`, I-15 e) | `data\pereira\pereira_fig8_directivity.csv` | 28 |
| D-12 | Pereira Fig. 9 (tonal levels, harmonics 1–10, three angles) | **Author digitized 2026-10-21** (raw export; convert and check per I-15; replaces C-01) | `data\pereira\pereira_fig9_harmonics.csv` | 28 |
| D-13 | Pereira Tables 3, 4 | **Present 2026-10-21** (typed from PDF text + page check) → card C-04 | `data\pereira\pereira_tables3_4.csv` | 28 |
| D-14 | CR-3813 Fig. E-17 | **Author digitized 2026-10-21** (raw export; convert and check per I-15; replaces C-07) | `data\cr3813\e17_interior_ci.csv` | 23e, 31e |
| D-15 | CR-3813 Fig. E-18 | **Author digitized 2026-10-21** (raw export; convert and check per I-15; replaces C-08) | `data\cr3813\e18_interior_pred_eta1.csv` | 23e (reference) |
| D-16 | CR-3813 Figs. E-21, E-22 | **Author digitized 2026-10-21** (raw export; convert and check per I-15; replaces C-05) | `data\cr3813\e21_noise_reduction_range.csv`, `_B2.csv`, `e22_noise_reduction_ci.csv`; `dig_cr3813_e21_e22_hand.py` | 31e |
| D-17 | CR-3813 Fig. E-16, second pass | **Author digitized 2026-10-21** (raw export; convert and check per I-15; replaces C-09) | `data\cr3813\t1_interior_targets_B.csv`, `e16_interior_all_bands_B.csv` | 23e, 33c |
| D-18 | CR-3813 Fig. E-9 second pass, Fig. E-10 | **Author digitized 2026-10-21** (raw export; convert and check per I-15; replaces C-10) | `data\cr3813\t2_third_octave_targets_B.csv`, `data\cr3813\e10_interior_ci.csv` | 23e, 30d |
| D-19 | Report 996 Fig. 3 (blade form) | **Present 2026-10-21** (C-12); agent file deleted; **author's `Fig 3.txt` 2026-10-21** disagrees with the designation and `blade_form.csv` (I-15 f, I-11) | `data\report996\tr996_fig3_blade_form.csv` | 25b |
| D-20 | Aircraft cabin inputs | **Author input** (not a digitization) | `PAIN.jl\examples\aircraft_cabin_<name>.json`, `data\aircraft\` | 29d, 30a |
| D-21 | BBN propeller rotation direction and hub position | **Present, relabel per I-09** (hub offset is lateral, not along x); rotation sense from documents per I-09 | `data\NASA_CR-158919\bbn_geometry.csv` | 24b, 24c |
| D-22 | Report 996 optional figures (Figs. 10, 11, 15, 17, 18; Eq. (2) curves of Figs. 13(a), 14) | Optional → card C-13 | `data\report996\tr996_fig<NN>_*.csv` | 27 (cross-checks), future work 6 |

**Order of work:** C-01 → C-03 → C-04 → C-06 (all block a phase); then C-05 (blocks 31e); then C-07 to C-12 (recommended); C-13, C-14 optional. C-02 may be done with C-01.

### 2.2 Digitization procedure (every card)

Tools available: Python 3 with `pymupdf`, `numpy`, `Pillow` (`pip install pymupdf --break-system-packages` in the sandbox); existing helpers `data\digitizers\*.py` and `data\report996\tools\digitize_tr996.py` (ring-template marker finder; needs `pdftoppm` and `opencv-python`); WebPlotDigitizer is acceptable for a pass done by the author. Keep each digitizer script in `data\digitizers\` (name `dig_<source>_<fig>.py`) so the CSV can be regenerated.

1. **Render.** `python -c "import pymupdf; d=pymupdf.open(r'<PDF>'); d[<PDF p.>-1].get_pixmap(dpi=300).save(r'<scratch>\<name>.png')"`. Rotated pages: rotate the image, not the axes. Keep renders in the scratch folder, not in `data\`.
2. **Identify.** Confirm the figure number, panel letter and caption on the render before reading anything. If the caption does not match the card, stop and report.
3. **Calibrate.** For each axis pick two labelled gridlines far apart; record their pixel positions and values in the script. Log axes are calibrated in log10 of the value. Polar plots: centre pixel, two labelled radius rings, and the 0° direction. Check the calibration on a third labelled gridline; the error must be below 1 px, otherwise recalibrate.
4. **Read.** Markers: centroid of each marker (template or by eye at 4× zoom). Curves: vertices or a trace by colour, then values at the abscissae the card names (band centres, harmonics). Bars: top edge of each bar. Record values clipped by the plot frame as `clipped` in a `flag` column, not as numbers.
5. **Write the CSV.** Header comment lines, in this order: `# Source: <document>, <figure/table, panel>, PDF p. <n> (printed p. <m>)`, `# Method: <pass A/B>, <render dpi>, <calibration gridlines>`, `# Uncertainty: <estimate, how obtained>`, `# Digitized <YYYY-MM-DD> by <who>; script <path>`, `# Conventions: <units, sign, reference>`. Then one header row and one row per point, columns as in the card. Units as printed unless the card says otherwise. No blank cells: use `-` for not printed.
6. **QA overlay.** Draw the read points on the render and save it as `<folder>\qa\<name>_overlay.png`. Look at it: every point on its marker or curve.
7. **Second pass** (cards marked "2 passes"): a different method (pixel calibration vs grid overlay, or a different reader) without looking at pass A. δ_dig = max |A − B| per series; write it in both headers. If δ_dig exceeds the card's limit, re-read the points concerned and say so in the header.
8. **Spot check.** Compare three points per series against a 600 dpi render; list them in the folder README.
9. **README.** Add a row to the folder's `README.md` table (file, source PDF p./printed p., content, method, uncertainty) in the format of `data\NASA_CR-158919\README.md`.
10. **Record** the item as done in §2.1 (status, date) and, if a phase's blocker is cleared, in §3.

### 2.3 Cards: what to digitize, where, and how

**C-01 · Pereira Fig. 9 · D-12 · blocks phase 28 · 1 pass + consistency check · REDO (I-04, I-05)** (`pereira_fig9_harmonics.csv`; H1 Exp φ=0 = 88.95 dB ≈ Fig.7 peak 87.2)
- File `rea-work\Pereira.pdf`, **PDF p. 10** (printed p. 10). Caption: "Comparison of experimental, numerical, and BEMT-based phase-lock averaged tonal components at different harmonics of the blade passing frequency (BPF)".
- Panels: (a) φ = 0° (top left), (b) φ = 20° (top right), (c) φ = 40° (bottom). Each panel has an upper bar chart, SPL (dB), y axis labelled 50 and 100, and a lower bar chart ΔSPL (dB) relative to BEMT, y −10 to 10. x: BPF harmonic number 1–10. Three bars per harmonic: BEMT (black), Numerical (red), Experimental (blue).
- Read: top of every bar in both charts. ΔSPL bars at ±10 are clipped by the frame: flag them.
- Target `data\pereira\pereira_fig9_harmonics.csv`, columns `panel, phi_deg, harmonic, series, SPL_dB, dSPL_vs_BEMT_dB, flag`.
- Check: SPL(series) − SPL(BEMT) agrees with the printed ΔSPL within 1 dB for unclipped bars; harmonic 1 at φ = 0° against the Fig. 7 fit (`pereira_fig7_harmonics.csv`: experimental first-harmonic amplitude 0.458 Pa = 87.2 dB re 20 µPa as a peak, 84.2 dB as rms) and record which reference (peak or rms) reproduces the bar.

**C-02 · Pereira Fig. 6 · D-10 · cross-check of C-01 · 1 pass · REDO (I-04, I-05)** (`pereira_fig6_peaks.csv`)
- `Pereira.pdf`, **PDF p. 7** (printed p. 7). Caption: "Comparison of the experimental, numerical, and BEMT-based acoustic spectrum of the propeller at different azimuthal angles (φ). BEMT-based predictions only include the tonal components."
- Panels (a) φ = 0°, (b) φ = 20°, (c) φ = 40°. x: frequency, log, ticks 10², 10³, 10⁴ Hz. y: SPL (dB), 0–80, linear, gridlines every 20 dB.
- Read: the peak of each series at harmonics 1–4 of BPF = B·rpm/60 = 2 × 8000/60 = 266.7 Hz (find the local maximum within ±5 % of m·BPF).
- Target `data\pereira\pereira_fig6_peaks.csv`, columns `panel, phi_deg, series, harmonic, freq_Hz, SPL_dB`. Check against C-01 within 2 dB; differences are recorded, not corrected.

**C-03 · Pereira Fig. 8 · D-11 · blocks phase 28 · 1 pass · done 2026-10-21 by pixel digitization** (`pereira_fig8_directivity.csv`; script `dig_pereira_fig8_pixels.py`; I-15 e)
- Pass A: density-peak polar sampling; H1 Exp φ=0 = 85.57 vs Fig.9 88.95 (−3.4 dB, card ±2 dB **marginal**); φ=20 within 2 dB; φ=40 flagged (assignment/reading). Absolute from Fig.8 rings; do not blend with Fig.9.

**C-04 · Pereira Tables 3 and 4 · D-13 · blocks phase 28 · typing · done 2026-10-21** (`pereira_tables3_4.csv`)
- `Pereira.pdf`: **Table 3 on PDF p. 5** (thrust, torque, power, C_T, C_P for each method; the text layer is readable, so the agent may type it); **Table 4 on PDF p. 7** (OSPL and OSPL(A) at φ = 0°: BEMT 83.4 / 76.2, numerical 84.7 / 76.8, experimental 84.6 / 77.3 dB, with deviations).
- Target `data\pereira\pereira_tables3_4.csv`, columns `table, quantity, method, value, uncertainty, unit`. Check every number against the page image, not only the text layer.

**C-05 · CR-3813 Figs. E-21 and E-22 · D-16 · blocks step 31e · 2 passes (δ_dig ≤ 1 dB) · REDO (I-03, I-05)**
- Dual independent hand readings on 300 dpi renders (`dig_cr3813_e21_e22_hand.py`); δ_dig = 1.00 dB on means (**PASS**). Auto pass A discarded. Files: `e21_noise_reduction_range.csv`, `e21_noise_reduction_range_B2.csv`, `e22_noise_reduction_ci.csv`.

**C-06 · BBN rotation direction and hub position · D-21 · blocks 24b/24c sign · reading · relabel and finish per I-09**
- `rea-work\references\NASA Contractor Report 158919.pdf` **PDF p. 9 (printed p. 3), Figure 1**, and `NASA Contractor Report 159124.pdf` **PDF p. 16, Figure 1**; search both texts for "rotation" first.
- Read: (1) the direction of propeller rotation as drawn or stated (seen from the front or from the side the microphones are on; say which view); (2) the hub position in the Fig. 1 frame (x along the fuselage, y as printed). If the hub position is not printed, compute it from the Fig. 1 coordinates of mics 3–6 (all at x = 0; y = 0.584, 0.279, 0, −0.305 m) and the CR-159124 Table 7 hub distances (1.33, 1.31, 1.36, 1.52 m), least squares, and report the residual; check the result against Table 8 (13.3°, 11.8°, 10.4°).
- Target `data\NASA_CR-158919\bbn_geometry.csv`, rows `quantity, value, unit, source`: `rotation_direction`, `view`, `hub_x_m`, `hub_y_m`, `hub_offset_from_skin_m`, `fit_residual_m`. If the direction is not printed anywhere, write `not printed`; 24b then runs both signs and 24c reports both.

**C-07 · CR-3813 Fig. E-17 · D-14 · recommended · REDO (I-03, I-05)** (`e17_interior_ci.csv`; `dig_cr3813_hand_passB.py`)
- Means at 200/400/630 Hz match E-16 pass A within 2 dB.

**C-08 · CR-3813 Fig. E-18 · D-15 · recommended · REDO (I-03, I-05)** (`e18_interior_pred_eta1.csv`; η_T=1.0 noted in header)

**C-09 · CR-3813 Fig. E-16, second pass · D-17 · recommended · REDO (I-03, I-05)** (`t1_interior_targets_B.csv`, `e16_interior_all_bands_B.csv`; pass A frozen)

**C-10 · CR-3813 Fig. E-9 second pass and Fig. E-10 · D-18 · recommended · REDO (I-03, I-05)** (`t2_third_octave_targets_B.csv`, `e10_interior_ci.csv`)

**C-11 · CR-159124 Figs. 18–20 (BBN phase vs frequency) · D-08 · Figs. 19, 20 REDO (I-03, I-05); Fig. 18 = author's files** (`dig_bbn_phase_c11.py`)
- Fig. 18 panel (a)/(b) frequency axes both 0–1000 Hz **verified**; Fig. 19 re-digitized; Fig. 20 new; `_APPROX` kept.

**C-12 · NACA Report 996 Fig. 3 · D-19 · recommended (25b) · done 2026-10-21, check per I-11** (`tr996_fig3_blade_form.csv`; `dig_tr996_fig3.py`)
- Panel (c) NACA 4-(5)(08)-03 vs `blade_form.csv`: max |Δ(b/D)|≈0.026, |Δ(h/b)|≈0.041, |Δβ|≈1.5°; nothing changed in `blade_form.csv`.

**C-13 · NACA Report 996 optional figures · D-22 · optional**

| Figure | PDF p. (printed) | Content | Use |
|--------|------------------|---------|-----|
| Fig. 10 | 12 (8), lower plot | Total pressure vs x/D in free space, at a flat wall and at a circular wall; B = 2, β = 20°, M_t 0.60, d/D 0.083 | Future work 6 (R1/R2 blocking) |
| Fig. 11 (a)–(c) | 13 (9), left column | Per-harmonic pressure vs C_P in the rotation plane, M_t 0.75, 0.90, 1.00 | 27 loading sensitivity (1.00 out of scope) |
| Fig. 13(a) Eq. (2) curve | 15 | Theory curve only (experiment is done) | 33a cross-check |
| Fig. 14 Eq. (2) curves | 16 | Theory curves only | 33a cross-check |
| Fig. 15 | 16 (12) | Effect of R_e on the first harmonic | 33a (R_e sensitivity) |
| Fig. 17 | 17 (13), lower right | Gutin simplified vs Eq. (2) | 33a far-field limit |
| Fig. 18 | 18 (14) | Oscilloscope wave forms, five tip Mach numbers (photographs) | Qualitative only; not digitized |

Target names `data\report996\tr996_fig<NN><panel>_<content>.csv`, columns `x, y, series, units` with the axis names in the header. The page indices of Figs. 12–14 are those used by `data\report996\tools\digitize_tr996.py` (Fig. 12(a) p. 13, 12(b) p. 14, 13(a) p. 15, 14(a) p. 16).

**C-14 · Hartzell 9333C-3 blade data · D-09 · obtain, then type · done 2026-10-21**
- Downloaded `rea-work\references\Hartzell_114-8.pdf`; Table III typed and checked → `data\NASA_CR-158919\hartzell_9333C_table3.csv`. Tip beyond 40 in: **not found** (24f).

### 2.4 Present and complete (no action)

| Data | File(s) | Passes | Used by |
|------|---------|--------|---------|
| Fig. E-11 measured free field, ℓ = 1, H1–H3 | `data\cr3813\e11_freefield_measured_{A,B}.csv` | 2 (δ_dig 1.0 dB) | e11 path, T1/T2, 32 |
| ANOPP Table 8 SPL and phase, ℓ = 1 | `data\cr3813\anopp_table8_{spl_dB,phases_deg}.csv` | typed | 18b, F1A smoke |
| Fig. E-12 blocked SPL | `data\cr3813\e12\*.csv` | 2 | 14a (done) |
| Fig. E-16 T1 targets (pass A) | `data\cr3813\t1_interior_targets.csv` | 1 | T1, 19i, 32 |
| Fig. E-9 T2 targets (pass A) | `data\cr3813\t2_third_octave_targets.csv` | 1 | T2 |
| Figs. E-13, E-14 (measured and calculated), E-15; Fig. A-2; Fig. D-2; Table D-1 | `data\cr3813\{e13_*,e14_*,e15_*,fig_a2_pf105,fig_d2_mode1_digitized,digitized_table_D1}.csv` | 1 each | done phases |
| Report 996 Figs. 12(a), 12(b), 13(a), 14(a); Fig. 14 C_T/C_Q table; p. 12 phase values | `data\report996\tr996_*.csv` | 1 automated pass + QA overlays | 26, 27 |
| Report 996 Figs. 6, 7, 8; RM L8H25a; RM L51C27; blade form; section fits | `data\report996\naca_4-5-08-03\` (D-07) | as in its `measured\NOTES.md` | 25–27 |
| Report 996 polars (merged forced-transition grid, Viterna record) | `data\report996\polars_forced_merged.json`, `data\polars\viterna_extension.json` | generated | 25c |
| Pereira Fig. 7 (phase-locked pressure, panels φ = 0°, 20°, 40°, PDF p. 8), Fig. 1(b) chord/twist (PDF p. 2), NACA 4412 polars (three transition sets) | `data\pereira\*` | 1 | 28 |
| BBN static and taxi data (D-01–D-06) | `data\NASA_CR-158919\`, `data\NASA_CR-159124\` (each with a README giving PDF pages) | typed, exact as printed | 24 |

---

## 3. Current status and work queue

**Status of the validation cases:** `VALIDATION_GUIDELINE.md` §0 (the map: cases with a verdict) and `NO_VERDICT_CASES.md`
(the cases without one). **Completed phases** (§§5–8ac and §11, with the work queue Q0–Q66 and the 2026-10-21 review I-01–I-20)
are in `COMPLETED_PHASES.md` under the same section numbers; a reference such as "IMPLEMENTATION_PLAN.md §8b" in the code
or the other documents points there. When a phase is done, mark it done and move its section to the bottom of
`COMPLETED_PHASES.md` (`CLAUDE.md`).

### 3.1 Work queue (open items; done rows move to `COMPLETED_PHASES.md` §3)

| Q | Item | Kind | Prerequisite | Output |
|---|------|------|--------------|--------|
| Q70 | **Phase 89 — η_n per cabin mode, trim per 1/3-octave band** (§8af; 2026-10-29) | option + diagnostic run | Q69 | planned 2026-10-29 (follow-up of Phase 87, run on "Run them"); criteria in §8af dated before any run |

If a queue item is blocked on data, skip to the next unblocked item and say which data item blocks it.

**Run** (PowerShell, from `rea-work\PAIN.jl`, one command at a time; Julia must be on PATH, see `README.md` Step 0):
```powershell
cd C:\Users\FrancisHoang\git\PAIN\rea-work\PAIN.jl
julia --project=. -e "using Pkg; Pkg.test()"
julia --project=. scripts/run/run_pain.jl
julia --project=. scripts/run/run_f1a_smoke.jl
julia --project=. scripts/run/mrp_ritz_vs_d1.jl
```

---

## 4. Architecture

```
SRC_TA (digitized E-11) → GEXT (assumed, e11 path only) ─┐
                                                         ├→ BLK Eq.43 → PAIN core → SPL / 1/3-oct
SRC_AC (CCBlade+F1A at all 160 points) ──────────────────┤         ↑
                                                         │         │
                                          CYL2D ─────────┤         │
                                          MRP/MRPMOD ────┘         │
                                                          trim/loss (App A / §3.8)
```

The diagram matches the code (phases 21–22 done 2026-10-21): `propeller_ccblade.jl` runs F1A at all 160 points; GEXT is e11-only. Both the 160-point grid and every validation case call **one** source-evaluation function (`evaluate_propeller_source`); there is no separate validation implementation. See `flowchart.md`: diagram 2 (NASA validation), diagram 3 (aircraft validation) and diagram 4 (shared cabin model).

| Flowchart | File(s) |
|-----------|---------|
| Geometry / 160-pt grid | `src/geometry.jl` |
| Blocking Eq. (43) | `src/blocking.jl` |
| Grid extension | `src/grid_extension.jl` |
| CYL2D | `src/cyl2d.jl` |
| MRP | `src/mrp.jl` |
| CCBlade + F1A | `src/propeller_ccblade.jl` |
| SRC_TA E-11 | `src/freefield_digitized.jl` + `data/cr3813/e11_*.csv` |
| PAIN main | `src/pain_core.jl` |
| Trim / loss | `src/trim_loss.jl` |
| Metrics | `src/metrics.jl` |
| Driver | `scripts/run/run_pain.jl` |

---

## 8af. Phase 89 — η_n per cabin mode with the trim per 1/3-octave band *(planned 2026-10-29 from the Phase 87 tables; criteria below dated 2026-10-29, before the option is written or any level is computed with it)*

**Reading H1 (formed from APPB_ETA_N and APPB_ETA_RPP, so neither tests it).** NASA's program gave each cabin mode one
loss factor, a property of the mode: Eq. (77) with the sidewall and end-plate trim conductance taken at the centre of the
1/3-octave band holding the mode frequency (App. B p. 195 steps at the band edges), used for N in Eq. (8) and Eq. (83) at
every tone (App. B prints the same η_r″ for a pair at 250 and 400 Hz). This code takes the trim and N at the tone
frequency. H1 reproduces 87b only to 0.86–1.39 (post-hoc), so it is at most part of NASA's form.

| Step | What | Criterion (fixed 2026-10-29, before any run) |
|------|------|----------------------------------------------|
| 89a | `PainInputs(...; η_n_per_mode=true)` (default false): in `tone_mean_square_pressure`, N of mode (q, i) = Eq. (77) at the mode frequency with ξ, ξ_e at the band centre holding it (100 Hz for modes below 89 Hz) | unit test: N of a mode is the same at two tones and equals `acoustic_N` with the band-centre ξ; default runs unchanged bitwise |
| 89b | `R172428_CODE_ETAN` (diagnostic): R172428_CODE with H1 | **decision**: R172428_CODE's criterion, ±3 dB of NASA's printed prediction at ≥ 7 of 9 points |
| 89c | Information, post-hoc (formation data): APPB_ETA_N and APPB_ETA_RPP with H1 | no criterion |

**Decision fixed before the runs.** If 89b is met, H1 becomes the default tone path (PAIN as App. B shows it), every
affected case is rerun against its registered criterion, and the change is recorded as a documented correction (source:
App. B pp. 195, 197, 202). If 89b is not met, H1 stays an option, not adopted, and is recorded as not reproducing NASA's
levels. No other form of H1 (other band edges, other frequencies for ξ) is tried after seeing 89b.

## 9. Reference appendices

### BBN/Wilby data and evidence (phase 24)

- [ ] **Order of the checks (decision 2026-10-16): BBN/Wilby first for phase; Report 996 for amplitude; Pereira second as the forward-flight source check.** The BBN/Wilby data already have measured phase between points with the aircraft geometry the PAIN case resembles, and the circumferential check needs only D, B, rpm and microphone positions. Report 996 supplies what the BBN data cannot: amplitude with measured loads (Figs. 6/7/8, 12, 13(a), 14; M_t 0.45–0.90 only) and the near-field amplitude pattern across tip Mach and harmonics. Pereira (forward flight, phase-locked waveform at φ = 0°) follows as the second source check. Axial phase rests on the BBN longitudinal pairs (assumed blade, X-EXTRAP) and the Report 996 page-12 value.
- [ ] **Data-only pre-check (done by hand 2026-10-16, no model run):** for the circumferential pairs the measured phase advances by a nearly constant step per harmonic, about 40° per harmonic for mics 4-3 (hub angular separation 13.3° in the taxi report's Table 8), which is B × 13.3° = 40° for B = 3. Run 4 (2600 rpm), pair 4-3, harmonics 1–7: measured −46°, −69°, −118°, −152°, 168° (= −192°), 121° (= −239°), 80° (= −280°) against B·m·13.3° = 40°, 80°, 120°, 160°, 200°, 240°, 279°; pair 4-5 (11.8°): 36°, 84°, 117°, 163°, −152° (= 208°), −104° (= 256°) against 35°, 71°, 106°, 142°, 177°, 212°, 248°. The phase is nearly independent of rpm at the first two harmonics (pair 4-3: the four runs agree within 7°), as a purely geometric relation requires, and the step supports B = 3 for this propeller. Differences from B·m·Δψ are 2–11° for pair 4-3 up to harmonic 7, but 11–31° for pair 4-5 at harmonics 3–5, and 6–13° at harmonics 1–2 even with coherence 0.97–1.00, so a tolerance tighter than about ±15° is not supported at the first two harmonics and the higher harmonics need a wider one. Angular separations are from the taxi report's Table 8; the measured angle convention (positive upward) must be matched to the rotation direction before the sign is compared.
- [ ] **Inter-point phase on a fuselage, static and taxi (BBN for NASA Langley: CR-158919 static, from NTRS 19790004686, and CR-159124 taxi, NTRS 19790023880; both read 2026-10-16; restored after the airfoil-geometry question).** Aero Commander ground tests with 10 flush-mounted microphones on one side of the fuselage; propeller D = 2.36 m, rated 320 hp per engine, propeller speed about 1,628–1,744 rpm (from the 10th harmonic), blade count not stated (B = 3 inferred from the blade-passing frequency and tip Mach). They report phase and coherence between microphone pairs for each blade-passage harmonic (appendices of each report) and convert them to trace velocities.
  - *Circumferential pairs (mics 3–5 in the rotation plane, 1.31–1.52 m from the hub, i.e. about 0.13–0.34 m from the tip; angular separations 13.3°, 11.8°, 10.4° at the hub):* the measured trace velocity divided by the rigid-rotation value ranges 0.89–1.07 for pairs 4-3, 5-3 and 4-5 across the static runs of CR-158919 Table 9 and CR-159124 Table 6 (pair 5-6, farther from the plane, reaches 1.2–1.3 in CR-158919), and 0.97–1.02 at taxi speeds of 40, 55 and 70 knots (average 0.94 static, 1.00 taxi). This is the mBψ relation seen with a little forward speed. It depends on kinematics only (D, rpm, B, geometry), not on loads or polars.
  - *Longitudinal pairs:* microphones in the rotation plane against microphones at X/D = 0.26 and 0.78; the phase is nearly constant at low frequency and then roughly linear in frequency (CR-159124 Figs. 19–20). Axial phase depends on the load distribution and needs a blade model.
  - *Forward speed:* the taxi report states that the aerodynamic pressure field in the plane of the propeller does not diminish significantly with forward velocity through the 15th harmonic. Taxi speeds up to 70 kt (about 36 m/s) are far below flight speeds, so this is a small step toward forward-flight phase, not flight data.
  - *Geometry from Hartzell's public overhaul manual (found 2026-10-16, not yet verified against the PDF).* The aircraft is a Model 680E with Hartzell HC-83X20-2 hub and 9333C blades (user information, not stated in the BBN reports). Hartzell Manual 114-8 (hartzellprop.com/MANUALS/114B-0000-A.pdf, reprinted 1991, covers HC-83( ) models; HC-83X20-2C appears in its applicability list), Table III "Blade Repair Tolerances", lists the **9333C-3 blade** at stations in inches from the hub centerline. The values below were read from an OCR text extraction and need checking against the PDF; the width and thickness are repair **minimums**, so the design chord and thickness are somewhat larger by an unknown amount:

    | Station (in) | Blade angle (°) | Face alignment (in) | Min. width (in) | Min. thickness (in) | t/c (my calculation) |
    |---:|---:|---:|---:|---:|---:|
    | 9.5 | not given | not given | 4.704 | 1.980 | 0.42 (shank) |
    | 13 | not given | not given | 5.720 | 1.095 | 0.19 |
    | 20 | 41–42 | −0.122 to −0.058 | 6.307 | 0.693 | 0.11 |
    | 28 | 36.5–37.1 | −0.472 to −0.408 | 6.070 | 0.472 | 0.078 |
    | 34 | 33.2 (set-up station) | −0.682 to −0.618 | 5.450 | 0.376 | 0.069 |
    | 40 | 29.8–30.2 | −0.832 to −0.768 | 4.200 | 0.286 | 0.068 |

    What this does not give: chord, twist or thickness inboard of 9.5 in or **outboard of 40 in** (with R = 46.5 in from D = 2.36 m, the outer 14% of the span, where the tip contributes most to the noise), the airfoil section shapes, and the blade angle used in the test runs (a constant-speed propeller; the table gives the angle distribution, not the setting). The face-alignment column is a gauge offset whose meaning (a rake or stacking offset, relevant to phase) must be read from the manual before use. Tip chord, tip thickness and section shape would be assumed (for example a rounded taper from the 40 in values and a Clark Y or NACA 16-series section scaled to the t/c above), and the result is X-EXTRAP. Other public sources to check before contacting Hartzell: the FAA propeller type certificate data sheet for the HC-83X20 (diameter limits, blade angle and rpm limits) and the Aero Commander 680E type certificate data sheet (propeller diameter and rpm); neither lists chord or airfoil.
  - *Leads checked in the reference list of Mixson & Wilby's "Interior Noise" chapter (NTRS 19920005567, which the user supplied as the citations of SAE 770445; its reference 54 is SAE 770445 itself):* none of the noise papers is likely to hold chord/twist/airfoil. Candidates that describe the Aero Commander or its propeller and could be searched: Barton & Mixson, *J. Aircraft* 18(3), 1981 (ref. 20, propeller noise on a fuselage); Piersol, Wilby & Wilby, "Evaluation of Aero Commander Sidewall Vibration and Interior Acoustic Data: Static Operations" (ref. 117, cited as NASA CR-159290; the web search could not confirm that number); Barton, PhD thesis, North Carolina State University, 1979 (ref. 151); Hayden, Murray & Theobald, NASA CR-172152 (ref. 110); Geisler, NASA CR-165750 (ref. 56, structure only). The BBN comparison with predicted levels in CR-159124 uses tip helical Mach number (SAE AIR 1407 and one other method), not blade geometry, so it holds no geometry either. Also worth reading for the method: Farassat & Succi 1980 (ref. 13, F1A), Hanson & Magliozzi AIAA-84-0248 (ref. 14, propagation through a fuselage boundary layer), Zorumski NASA TM-85636 (ref. 16, propeller noise prediction).
  - *Geometry otherwise:* **neither BBN report gives propeller chord, twist or airfoil**, only D and rpm. The companion paper, Mixson, Barton and Vaicaitis, *J. Aircraft* 15(4), 1978 (NTRS 19780045732, Accession 78A29641), has no downloadable text on NTRS (abstract only), and its content on the propeller is unknown to me. SAE 770445 (same authors) may also describe the aircraft; it is behind a paywall. An Aero Commander propeller drawing, a Hartzell data sheet or the aircraft maintenance manual might supply a blade angle and activity factor but not airfoil sections. Until a geometry source is found, only the kinematic (circumferential) comparison is possible with these reports, and the axial comparison needs an assumed blade (class X-EXTRAP).
  - *Limits:* the microphones are on a fuselage surface with wing and ground reflections (the reports flag interference and levels that are too high at some microphones); coherence is low at many harmonics (data below coherence 0.15 treated as low confidence, below 0.05 dropped); no shaft marker, so no absolute phase (the taxi report reconstructs the blade position from the blade-passage tone for the stability study only); reciprocating-engine noise contaminates some tones; there is no thrust or torque measurement.

### Pereira NACA 4412 polar specification

The paper publishes no polars (its solver was a potential-flow plus boundary-layer method), so they must be generated. Use XFOIL (or MSES/another viscous
panel code). Ranges are computed from the blade conditions (8,000 RPM = 133.3 rev/s, R = 0.15 m, V = 16 m/s) and must be recomputed from the
Fig. 1 chord table before running.

| Item | Requirement |
|------|-------------|
| Section | NACA 4412 coordinates; re-panel to about 160–200 points |
| Reynolds number | Local W·c/ν along the blade. The tip is about 8.9×10⁴ (paper); the hub region is lower, about 2×10⁴–5×10⁴. Run Re = 2×10⁴, 3×10⁴, 5×10⁴, 7.5×10⁴, 1×10⁵, 1.5×10⁵, 2×10⁵ and add 3×10⁵ as a sensitivity edge. Recompute the actual min/max from chord and W before fixing the list |
| Mach | Local M = W/a from about 0.09 (hub) to 0.37 (tip). Run M = 0, 0.1, 0.2, 0.3, 0.4. XFOIL's compressibility correction is adequate below 0.5 |
| Angle of attack | −10° to +20° in 0.5° steps (finer, 0.25°, near stall), run upward and downward from α = 0 and merge. Low-Re laminar bubbles make convergence patchy, so log every non-converged point |
| Transition | The experiment did **not** trip the blades and the paper's own BEMT used natural (e^n) transition, so the **primary** set is free transition. The paper gives tunnel turbulence below 0.1% but no N threshold; Mack's relation gives N_crit about 8 for 0.1% turbulence (my calculation, not from the paper), so use N_crit = 9 (XFOIL default) as primary. Brackets: N_crit = 5, and forced transition (x_tr = 0.05 upper and lower). The paper attributes its BEMT torque being about 5% above the measured torque to the transition prediction, which is the sensitivity this bracket measures |
| Output | c_l, c_d (and c_m, optional) vs α for every (Re, M), as a table the CCBlade `AlphaReMachAF`-style interpolator can read |
| Extrapolation | Fill gaps and extend to ±180° with a Viterna-type method (CCBlade provides a helper; confirm in the pinned 1.0.0 docs) using the blade's aspect ratio and the chord at 0.75R; or Montgomerie as a cross-check. State α_stall used, the c_d,max rule, and which points were interpolated rather than computed |
| Clamping | Clamp Re and M to the grid edges when CCBlade queries outside them, and record how often that happened at J = 0.4 |
| Sensitivity | Run the Pereira case with all three transition sets; the spread is the polar uncertainty carried into every result |

**Where it is recorded.**
1. Polar files: `data\pereira\naca4412_xfoil_<transition>.json` (or CSV), each with a provenance header: XFOIL version, panels, N_crit or x_tr, Re/M/α grids, list of non-converged points, extrapolation method and its parameters, generation date, generating script.
2. This plan: phase 28 (above) names the files and the settings used for the reported result.
3. `VALIDATION_GUIDELINE.md` §2.3.2 (geometry and polars limit) and the §2.10 parameter register: the chosen N_crit, x_tr, α_stall, c_d,max, and Viterna parameters are values chosen in advance, entered **before** the comparison. If any is changed after seeing a result, that result is reported as calibrated with the parameter named.

### Figures needed from NACA Report 996

"In folder" means digitized in the data folder (`measured\noise\`); see the data-sources section below.

| Figure | What it gives | Used for | Needed? | In folder? |
|--------|---------------|----------|---------|-----------|
| Fig. 3 | Blade width and thickness vs r/R for the test blades (NACA 4-(5)(08)-03 panel) | Geometry input | Yes | Replaced by `blade_form.csv` (NASA CR-196702 App. B-1, Harris 1996); not the report's own Fig. 3, so confirm they agree |
| Fig. 14 (+ table) | Harmonic pressure vs tip Mach (experiment and theory); table of C_T, C_Q vs M_t | Per-harmonic F1A check; loads for scaling | Yes | Experiment digitized (`data\report996\tr996_fig12_13a_14_digitized.csv`); table in `tr996_fig14_CT_CQ_table.csv`; theory curves not digitized |
| Fig. 12 (a), (b), (c) | Harmonic pressures mB = 2, 4, 6, 8 vs x/D (±0.25) at M_t 0.75, 0.90, 1.00; B = 2, 10°, d/D 0.083 | Per-harmonic spatial pattern (main test) | Yes for (a), (b); (c) out of scope | (a), (b) digitized |
| Fig. 13 (a) | Fundamental pressure vs x/D at M_t 0.75, 15°, experiment vs theory | F1A near-field spatial pattern | Yes | Experiment digitized; theory curve not |
| Fig. 11 | Per-harmonic pressure vs C_P in the plane of rotation, M_t 0.75/0.90/1.00 | Loading sensitivity per harmonic | Optional | No |
| Fig. 13 (b) | Same at M_t 1.00, 10° | Out of scope (M_t > 0.90) | No | Recorded only |
| Fig. 6 | Total rms pressure vs x/D at four tip clearances (B = 4) | F1A distance scaling | Yes | Yes (`tr996_fig6_...csv`) |
| Fig. 7 | p_c/C_P vs x/D at three blade angles, with C_P in the legend | F1A loading sensitivity; C_P check | Yes | Yes (`tr996_fig7_...csv`) |
| p. 12 text | Phase difference ahead vs behind: 155° measured, 165° Eq. (2) (M_t 0.75); 125° Eq. (2) only | Phase check | Yes | In `rea-work\references\NASA Report 996.pdf` (checked) |
| Fig. 8 | p_c vs C_P in the rotation plane (B = 2, 4; M_t 0.60, 1.00) | Loading sensitivity; cross-propeller consistency | Yes (was optional) | Yes (`tr996_fig8_...csv`) |
| Fig. 15 | Effect of effective radius R_e on first harmonic | Eq. (2) cross-check | Optional | No |
| Fig. 17 | Gutin simplified vs Eq. (2) | Far-field limit check | Optional | No |
| Fig. 18 | Oscilloscope pressure waveforms, five tip Mach numbers | Qualitative time-history comparison | Optional | No |
| Fig. 10 (with Fig. 5) | Total pressure vs x/D in free space, at a flat vertical wall and at a circular (fuselage-like) wall; B = 2, 20° blade angle, M_t 0.60, d/D 0.083 | Scattering/reflection check for blocking (Eq. 43 R1/R2), amplitude only | Optional (blocking, not the source) | No; the text says the flat wall is about 2× free space and the circular wall less (1.5× in the wall-response calculations) |
| p. 8 table | Full-scale static check points: 12.92-ft three-blade propeller on a test airplane, M_t 0.49–0.80, d/D 0.083–0.167, measured 350/240/1500/1150 dynes/cm² vs 420/280/1440/975 extrapolated from model data | Only larger-propeller data in the report; whether they are free-space or on-airplane pressures is to be confirmed from the text | Optional | In the PDF only |
| Figs. 9, 11, 12, 19–22 | Tip shape, pressure vs C_P in the rotation plane, harmonics vs location, wall vibration response | Not source or scattering validation (Figs. 19–22 are structural response) | No | No |

Report conditions for the main cases (read at low resolution, confirm): NACA 4-(5)(08)-03, B = 2, blade angle 10° at 0.75R,
x/D = −0.125, tip clearance d/D = 0.083. Second reference for forward speed: Pereira et al. (2026), Table 3 (thrust, torque),
Table 4 (OSPL), Figs. 6, 7, 8, 9 (harmonic SPL, time history, directivity). It is free-field with microphones at 1 m, so it does not
test the near field.

The validity assessment of Report 996 as a reference (limits, rules against tuning, and how results are classified) is in
`VALIDATION_GUIDELINE.md` §2.3.1; what the checks can and cannot claim is in §2.3.3. Follow them for phases 25–27.

### Report 996 data sources: inventory and gaps

Folder: `C:\Users\FrancisHoang\git\propeller_sizing_and_analysis\propeller_sizing_and_analysis\propellers\naca_4-5-08-03` (a separate repository;
the files below were read in full unless noted). It holds a NACA 4-(5)(08)-03 two-blade propeller (D = 4 ft = 1.2192 m, NACA 16-series, design c_l 0.5, t/c 0.08 at 0.7R).

| File(s) | Contents | Adequate for | Gap or caution |
|---------|----------|--------------|----------------|
| `blade_form.csv`, `measured\geometry\...appB1_..._blade_geometry.csv`, `propeller.yaml` | 54 stations r/R 0.271–1.0: c/R, t/c, chord-line β, design c_l; β₇₅ design 42.64°; root 0.27R; B = 2 (4 also tested); mid-chord stacking assumed | Chord, twist, thickness for CCBlade and the F1A thickness term | From NASA CR-196702 App. B-1 (an OCR of Harris 1996, from RM L9G06a), not from Report 996 itself. The report's text indicates a 4-ft (1.2192 m) propeller (OCR garbled); p_c is D-independent at fixed M_t. Chord goes to 0 at the tip |
| `plots\section_coordinates.csv`, `analytical\sections.json` | NACA 16-series section coordinates at stations; per-section parametric polar fits (c_lα, α₀, c_l,max, c_l,min, c_d0, Re exponent, c_d2) | XFOIL input; the polar model | `sections.json` is derived from `polars_forced.json` and fitted, not measured. Post-stall behaviour is not described |
| `analytical\polars_forced.json` | XFOIL, forced transition (x_tr 0.02), 10 thin sections × Re {0.5, 1, 2, 4}×10⁶ × M {0.2, 0.4, 0.55, 0.65, 0.72}, α −6° to +14° (0.5° step) | **Primary polar set** (through `sections.json`, k_cl = k_cd = 1) | 6 of 200 entries empty. α stops at 14°; M stops at 0.72; Re starts at 5×10⁵ (blade needs about 3×10⁵ inboard and M down to about 0.12). Needs Viterna-type extension |
| `analytical\tables.json` (calibration block) | Same fits with k_cl = 0.92264, k_cd = 1.81815 (fitted to forward-flight wind-tunnel data) | **Bracket polar set** | Calibration was fitted to RM L9G06a, not to Report 996, but is still a fitted value and goes in the register. k_cd = 1.82 changes torque a lot |
| `analytical\polars.json` | Raw XFOIL, free transition, same grid | Optional third set | Patchy (XFOIL fails above about 5–7° at many Re/M); needs fitting code outside the folder |
| `analytical\polars_cfd2d.json` | SU2 2-D RANS, 2 sections, Re 10⁶, M 0.3, 3–4 angles | Spot check of XFOIL values | Too small to be a polar set; 5 cases rejected |
| `analytical\polars_thick.json` | XFOIL thick root sections (t/c 0.20–0.30) | Not needed here | Blade root is t/c 0.134; covered by the thin set |
| `measured\static\rm_l8h25a_static_vs_tip_mach.csv` | Static C_T and C_P vs M_t, blade angle 0–40° (RM L8H25a Figs. 10/11) | C_T and C_P targets (phase 26) | M_t 0.3 up to 0.9 (5°, 15°), 0.83 (10°), 0.65–0.70 (20°); curves for 25°–40° end near M_t 0.4–0.55 (flutter). No 8° curve. Digitized from scans (1 px ≈ 0.0001 C_T) |
| `measured\static\rm_l8h25a_static_vs_blade_angle_Mt045.csv` | C_T and C_P vs blade angle at M_t 0.45 (Figs. 16/17) | Cross-check of the above (agree within 0.0015 C_T, 0.003 C_P per the notes) | Single M_t |
| `measured\noise\naca_rm_l51c27_table1_thrust_torque.csv` | Static thrust, torque, power of the 47-in. propeller, 15° and 13°, M_t 0.75–1.30 (RM L51C27 Table I) | Measured T and Q for load scaling (15°) | 47-in. diameter, not the report's propeller size; 13° rows have no thrust; M_t 1.30 not obtained. Printed table, not digitized |
| `data\report996\tr996_fig12_13a_14_digitized.csv`, `tr996_fig14_CT_CQ_table.csv` (this repository; not in the data folder) | Per-harmonic experiment: Fig. 12(a),(b) mB 2/4/6/8 vs x/D, Fig. 13(a), Fig. 14(a) mB 2/4/6 vs M_t (62 rows), Fig. 14 C_T/C_Q | Per-harmonic and spatial checks, loads for scaling | Eye-read table; theory curves not digitized; markers only |
| `measured\noise\tr996_fig6_...csv` | Total rms pressure vs x/D, d/D 0.042/0.083/0.167/0.333, B = 4, 10°, M_t 0.60; 25 symbols + 19 manual + faired curve | Distance-scaling check | No B = 4 thrust or torque in the folder. Tails reliable to about 5–10 dyne/cm² |
| `measured\noise\tr996_fig7_...csv` | p_c/C_P vs x/D, 8°/15°/20°, B = 2, M_t 0.60, d/D 0.083; C_P 0.0195/0.0424/0.0818 | Loading-sensitivity check; C_P target | 8 manual rows; tails reliable to about 0.005 |
| `measured\noise\tr996_fig8_...csv` | p_c vs C_P at x/D = 0, d/D 0.042, B = 2 and 4, M_t 0.60 and 1.00; line slopes | Loading sensitivity | Clark Y point not detected; M_t 1.00 outside the polar Mach grid |
| `measured\noise\tr1079_fig6/7/8_...csv`, `naca_tn3202_table1_...csv` | Report 1079 far-field directivity, SPL vs M_t and distance (9 m, 30 ft); TN 3202 harmonic amplitudes of a different pusher propeller | Far-field cross-checks of Gutin/Hanson/F1A at 7.5 D | Not Report 996 and not near-field. TN 3202 conditions differ (use only for spectrum shape) |
| `analytical\noise_vs_measured.json`, `bem_vs_measured.json`, `bem_vs_cfd.json`, `records\*.json` | The folder's own BEM, Gutin and Hanson (far-field) predictions and a CFD case at M = 0.23, J = 1.18 | Reference numbers for comparison and cross-checks | Their polars carry the k_cl/k_cd calibration. BEM static C_T is 31% low at 20°, M_t 0.60; Report 1079 thrust −12%, torque −35% at 15°, M_t 0.75 |
| `measured\wind_tunnel\...` (RM L9G06a, forward flight) | C_T, C_P, efficiency vs J, M | Not Report 996. Useful later as a forward-flight load check of CCBlade, since the folder's calibration came from it | Not read in detail |

**Is it enough?** For CCBlade loads and for an F1A check on **total rms pressure** (Figs. 6, 7, 8), mostly yes, with these gaps:
1. **Figs. 12, 13(a), 14 were not in the data folder; they are now digitized from the report PDF** (`data\report996\`). The Fig. 14 table gives the report's own C_T and C_Q for β₇₅ = 10°, which are the loads for Figs. 12 and 14. RM L8H25a and RM L51C27 supply loads for the other cases.
2. **Polars end at α = 14°, M = 0.72, Re ≥ 5×10⁵**, while inboard stations are at α ≈ 20°–30° and the 20° blade angle is stalled (per the report). A post-stall extension is required (phase 25c).
3. **No B = 4 load data**, so Fig. 6 can only be judged on shape and clearance ratios.
4. **Geometry is from the Harris table**, not the report's Fig. 3; the report's propeller diameter and the air density/sound speed are not stated.
5. **The folder's own BEM underpredicts static thrust and torque** by 12–35% with these polars. That is a polar/stall problem; use scaled loads to isolate F1A and do not retune polars to the target.
6. **Page-12 phase:** one measured value (155°), no stated x/D pair or blade angle for the 125° case; the PDF is in `rea-work`.

### Phase-validation figure list (exact figures, status)

These are the specific figures and tables used to test phase, and where each stands. "Digitized" means the data are in `data\` with a QA overlay in `data\cr3813\pages\` and a README stating the uncertainty.

| # | Source | Figure / table | What it provides | Used for | Status |
|---|--------|----------------|------------------|----------|--------|
| 1 | Pereira et al. 2026 | Fig. 7 (a) φ = 0°, (b) 20°, (c) 40° (PDF p. 8) | Phase-locked p'(propeller phase angle), experiment / CFD / BEMT-based | Phase of harmonics 1–2 at three microphones, forward flight, 1 m | **Digitized** → `data\pereira\pereira_fig7_*.csv` |
| 2 | Pereira et al. 2026 | Fig. 1(b) (PDF p. 2) | Chord c/R and twist vs r/R | Blade geometry for CCBlade/F1A | **Digitized** → `data\pereira\pereira_fig1b_chord_twist.csv` (section shape and XFOIL polars still needed) |
| 3 | NACA Report 996 | p. 12 text | 155° measured, 165° Eq. (2), 125° Eq. (2) at a larger angle | Axial phase anchor | **Recorded** → `data\report996\tr996_phase_values.csv` (no figure; x/D pair not stated) |
| 4 | NACA Report 996 | Figs. 12(a),(b), 13(a), 14(a) | Amplitudes, not phase | Per-harmonic amplitude | **Digitized by pixel tracing** (`data\report996\tr996_fig12_13a_14_digitized.csv`, overlays in `data\report996\qa\`); the eye-reading file is superseded |

Not phase data: Report 996 Figs. 6, 7, 8 (digitized earlier, total rms amplitude), Fig. 10 (scattering amplitude), Pereira Fig. 9 (levels).

Digitization method: raster figures were extracted from the PDFs at 300 ppi, the plot frame and axes were located from the frame lines, curves were separated by colour, and points were converted to data units. Every result has a QA overlay. No second independent pass was made, so the stated uncertainties are my estimates from pixel size.

### Variables under test and where they go

**Inputs (report quantity → PAIN input → function that consumes it)**

| Variable | Source in report | Goes into | Code |
|----------|------------------|-----------|------|
| Number of blades B | 2 (4 for Fig. 6) | CCBlade rotor, F1A source elements, BPF | `CCBlade.Rotor(Rhub, Rtip, B)`; `bpf = B*rpm/60` |
| Diameter D / tip radius R | Report models | CCBlade rotor; observer radial position | `Rtip`; observer `x1 = R + d` |
| Hub radius | `blade_form.csv` (root 0.271R) | CCBlade rotor | `Rhub` |
| Chord, thickness, twist vs r/R | `blade_form.csv` (Fig. 3 itself is not in the data folder) | CCBlade sections; F1A thickness term | `CCBlade.Section(r, chord, theta, af)`; `area_over_chord2` |
| Blade angle at 0.75R (8°, 10°, 15°, 20°) | Figs. 6-7, 13-14 | Section pitch angle | `twist_deg` shifted by β₇₅,target − 42.64° (set through `pitch_offset_deg`) → `theta` |
| Tip Mach M_t | 0.45–1.00 | Rotation speed | `Omega = M_t*c0/R`; `rpm`; `OperatingPoint(Vinf, Omega*r, rho; asound=c0)` |
| Forward speed | 0 (static) | CCBlade operating point; observer velocity | `Vinf` (values below 1 m/s are replaced by 20 m/s today; phase 25a decides); `v_obs = [Vinf,0,0]` |
| Air density, sound speed | Not found in text read | CCBlade and F1A | `rho`, `c0` (use standard atmosphere and state it) |
| Airfoil polar | Not in the report; XFOIL fits in the data folder (`sections.json` from `polars_forced.json`; primary k = 1, bracket calibrated), Viterna extension beyond α = 14° | Section loads | `af(alpha, Re, M)` (currently linear) |
| Axial position x/D | Figs. 6, 7, 13, 14 | F1A observer | `_observer_aa` → `[x3, x1, x2]`, `x3 = x` |
| Tip clearance d/D | 0.042–0.333 | F1A observer | `x1 = R + d`, `x2 = 0` |
| Source time steps, period | Numerical choice | F1A time sampling | `num_src_times`, `bpp` in `f1a_source_elements_ccblade` / `combine` |

**Outputs compared with the report**

| Output | Produced by | Compared with |
|--------|-------------|---------------|
| Thrust T, torque Q → C_T, C_Q, C_P | `evaluate_propeller_source` (CCBlade integrated section loads) | RM L8H25a static C_T, C_P; RM L51C27 T, Q; Fig. 7 legend; Fig. 14 table only if digitized |
| Pressure time history p'(t) at each observer | `AcousticAnalogies.noise` + `combine` | (intermediate) |
| Harmonic amplitude, harmonics m·B | FFT of p'(t) in `evaluate_propeller_source` (`2*abs(c)/n`) | Total rms (Figs. 6, 7, 8): sqrt(Σ A_m²/2), converted to p_c; per harmonic only if Fig. 14(a) is digitized |
| Pressure vs x/D | `evaluate_propeller_source` at a row of `hub_observers` | Figs. 6, 7, 8 (Fig. 13 if digitized) |
| Phase difference between two x/D points | `angle(c)` from the FFT | Page 12 text (155°) |

Known risks to check along the way: relative phase between observers depends on each observer's time origin (not verified in
AcousticAnalogies); the report's x sign convention (ahead vs behind the plane) must be read from its Fig. 1; the report's theory
has no thickness noise.

---

## 10. Optional future work, key formulas, file checklist

### Optional future work *(not blockers)*

1. Full App. D Peterson off-diagonal matrices from cleaner source  
2. OEM Hartzell geometry / thickness-noise F1A without Table-8 cal  
3. Exterior Spbl measurement to remove `j2_scale` Spbl-anchor correction  
4. Lab coupon closure of App. A transfer matrix  
5. Notebooks  
6. Check R1/R2 blocking against NACA Report 996 Fig. 10 (pressure at a flat wall about twice the free-space value; one condition, wall-plane pressure, no phase; needs digitizing)
7. ~~Faster test cycle (testset filter + DaemonMode)~~ → **P1 done 2026-10-22** (`COMPLETED_PHASES.md` §11)

---

### Key formulas

**Grid (User Manual Fig. 3)** `θ_ℓ = φ_p + (ℓ−1)π/18`, `z_k = z_p + (πa/18)(k_p − k)`, `ΔA = Δ² = (πa/18)²` (12b)  
**Blocking (Eq. 43)** `F(γ) = 10^(0.3 - 0.000224*exp(0.08*γ))` · R2: `max(1, 0.8*F)`  
**Cabin volume** `V = a² L (π − θ₀ + cosθ₀ sinθ₀)`  
**BPF** `B * rpm / 60`  
**Ψ_G (Eq. 42)** `Ψ_G(r,H) = (Δ⁴/2)[(Σ A ψ cosφ)² + (Σ A ψ sinφ)²]`  
**f̄' (Eq. 52)** `f_qM/(Lp + 2a(π−θ₀)) · [√τ_t ∫ a ψ_s φ dθ − ∫ ψ_p φ dx]`, `f_qM` Eq. (57)  
**Tone (Eq. 8, summed by Eq. 3)** `⟨p_n²⟩ = (4c₀²/V²)(ρ₀c₀A/2ω_H)² ω_H⁶ ε_n Σ_r f̄'² Ψ_G / (M_r² D_n D_r)`, `D_n = (ω_n² − ω_H²)² + (η_n ω_n²)²`, `D_r = (ω_r² − ω_H²)² + ((η_r' + η_r'') ω_r²)²`, `A = L(Lp + 2a(π−θ₀))`  
**Trim (Eq. A.22)** `τ_t = |a₁₁|⁻² + τ_t^m`  
**HF (Eq. 23 arch., surrogate until 30b)** `⟨p²⟩ ≈ 4 τ_t A_fc ⟨p²⟩_bl ⟨j²⟩ χ(nω) / (α S)` (τ_t from 17b; was T²)

---

### File checklist

```
docs/IMPLEMENTATION_PLAN.md
docs/flowchart.md
docs/VALIDATION_GUIDELINE.md
docs/METHODOLOGY.md
docs/validation_reports/{blocking_p68,cyl2d_table_c1,mrp_table_d1,mrp_ritz_vs_d1,
  e11_delta_dig,t1_tonal,t2_third_octave,ccblade_f1a_smoke,pipeline_smoke}.md
docs/validation_reports/e12_blocking.md                      (14a, done)
docs/validation_reports/trim_loss_e13_e14_e15.md             (16, done)
docs/validation_reports/eq8_two_resonator.md                (19a, 19b, done; scripts/checks/check_two_resonator.py)
docs/validation_reports/eps_n_quadrature.md                  (19c, done; scripts/checks/check_eps_n_quadrature.jl)
docs/validation_reports/grid_mirroring.md                    (19d, done; scripts/checks/check_grid_mirroring.jl)
docs/validation_reports/{tau_t_variants,bisect_18b,fig_d2_check,eta_r_normalization}.md  (19e–19h, done)
docs/validation_reports/figures/                             (phase 34–35 CairoMakie plots)
docs/validation_reports/figures/<block folder>/<case>.png     (one folder per map block, e.g. F1A_amplitude/; moved 2026-10-27)
docs/validation_reports/figures/<block folder>/source/<case>.png  (phase 35: cropped source pages, display-only)
data/cr3813/e11_freefield_measured_{A,B}.csv
data/cr3813/e12/e12_blocked_{measured,predicted}_{A,B}.csv              (planned, 14a)
data/cr3813/fig_a2_pf105.csv                                        (16a, done)
data/cr3813/e13_absorption_targets.csv                              (16b, done)
data/cr3813/e14_acoustic_loss_calculated.csv                        (16b, done)
data/cr3813/anopp_table8_{spl_dB,phases_deg}.csv
data/cr3813/t1_interior_targets.csv
data/cr3813/t2_third_octave_targets.csv
data/cr3813/e14_acoustic_loss_targets.csv
data/cr3813/e15_structural_loss_targets.csv
data/cr3813/pages/e{9,11,14,15,16}*.png
data/cr3813/pages/e{12,13}*.png                                   (planned, 14a, 13b)
data/pereira/pereira_results.csv                             (phase 35 C4; written by run_pereira.jl)
data/NASA_CR-158919/bbn_results.csv                          (phase 35 C4; written by run_bbn_phase.jl)
PAIN.jl/
PAIN.jl/src/validation_map.jl                                (phase 35: CASE_INFO + two maps)
PAIN.jl/scripts/retired/                                     (phase 35 C3: one-off probes, git mv)
docs/archive/                                                (phase 35 C3: SESSION_PROMPT.txt, T1_fix_instructions.txt)

Planned files (phases 19i–33):
docs/validation_reports/h3_followup.md                       (19i)
data/baselines/f1a_line_reference.csv                        (21b)
docs/validation_reports/gext_vs_f1a_grid.md                  (21i)
data/NASA_CR-158919/, data/NASA_CR-159124/                   (D-01–D-08, D-21, present except C-06, C-11)
docs/validation_reports/bbn_phase.md                         (24)
data/report996/naca_4-5-08-03/CHECKSUMS.txt                  (D-07)
data/report996/{scale_factors.csv,f1a_results.csv}          (26, 27)
data/report996/tr996_fig3_blade_form.csv                     (D-19, C-12)
docs/validation_reports/report996_{setup,loads,acoustics}.md (25–27)
data/pereira/pereira_{fig6_peaks,fig8_directivity,fig9_harmonics,tables3_4}.csv  (D-10–D-13, C-01–C-04)
docs/validation_reports/pereira_forward_flight.md            (28)
docs/validation_reports/parametric_regression.md             (30d)
docs/validation_reports/gext_importance_bound.md             (32)
data/{e17_interior_ci,e18_interior_pred_eta1,e21_noise_reduction_range,e22_noise_reduction_ci,e10_interior_ci}.csv  (D-14–D-16, D-18)
data/{t1_interior_targets_B,t2_third_octave_targets_B}.csv  (D-17, D-18; second passes)
data/digitizers/dig_<source>_<fig>.py                        (every new digitization, §2.2)

Retired / archived (phase 35 C3, 2026-10-21, git mv):
PAIN.jl/scripts/retired/{_probe_bbn_kin,check_t1,check_mrp_spectral,debug_f1a_pitch,
  find_fig_e11,find_fig_e9,map_k_x3d}.jl
docs/archive/{SESSION_PROMPT.txt,T1_fix_instructions.txt}
```

---
