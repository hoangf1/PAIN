# PAIN Recreation — Plans & Phased Implementation

Single source of truth for building this project without re-deriving context in chat. Reorganized 2026-10-20 for hand-off to a new executing agent: the content of the earlier version is kept, nothing was re-decided, and execution detail (files, functions, tests, commands, outputs, stop points) was added to every open phase.

**Read first:** §0 of this file · `METHODOLOGY.md` · `VALIDATION_GUIDELINE.md` · `flowchart.md` · `README.md`  
**Code:** `PAIN.jl/` (Julia package; `Manifest.toml` pins CCBlade 1.0.0 and AcousticAnalogies 1.0.0)  
**Source PDFs (in `rea-work\references`, moved there 2026-10-21):** `Pain Methodology.pdf` (CR-3813), `Pain User Manual.pdf` (CR-172425), `Pain Validation.pdf` (CR-172428), `NASA Report 996.pdf`, `Pereira.pdf`. Text extractions: `docs/extracted/`. CR-3813 App. E PDF page = printed page E-n + 116 (E-19 → PDF 135).

## Contents

0. Agent hand-off brief: rules, workflow, stop conditions
1. Goal and validity classes
2. Data register and digitization instructions (status, procedure, one card per figure)
3. Current status and work queue (§3.0: review of the 2026-10-21 run, issues I-01–I-17, read first)
4. Architecture
5. *(moved to §11)* Step 19i done 2026-10-21
6. *(moved to the bottom)* Source phases 21–28, done
7. *(moved to the bottom)* Aircraft-cabin phases 29–31, done 2026-10-22
8. *(moved to the bottom)* Phases 32–38 (36, 37, 38 done 2026-10-22), with the dated result paragraphs and pre-registrations
9. Reference appendices (BBN evidence, Report 996 figures and data, Pereira polar specification, variables)
10. Optional future work, key formulas, file checklist
11. Completed phases 0–22 + digitization/setup close-out + phases 32–37 records; then §6–§8 (phases 21–38, moved 2026-10-22)

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
| R5 | **Docs in the same session (CLAUDE.md).** Every code or result change updates `README.md`, `docs/flowchart.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/METHODOLOGY.md`, `docs/VALIDATION_GUIDELINE.md`. When a step is done: tick it and date it; when every step of a phase is done, move the phase to §11 (completed phases, in number order). |
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
8. Tick the step. When every step of the phase is ticked, move the phase to §11.

### 0.4 Stop and ask the author when

- a step is marked [CONFIRM] or [AUTHOR];
- `Pkg.test()` fails on a test that is not the subject of the current step;
- the e11 T1/T2 numbers change at a step that should not change them (phase 21: any change above 0.01 dB from `phase20_baseline.md`);
- a printed equation and the code disagree and this file does not already record the decision;
- a data item in §2 is missing, or a digitized value looks inconsistent with the PDF;
- a result would change a claim in `METHODOLOGY.md` (claims change only at 33c, or where a step says so).

### 0.5 Definition of done (every phase)

`Pkg.test()` passes, or its failures are the recorded subject of the step; each step's report exists and was written by its script; the criterion text and its date precede the result; the five docs are updated; the phase is ticked and moved to §11.

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

**Phases 0–20 are done (§11).** Status of the rest:

| Phase | Name | Status |
|-------|------|--------|
| 19i | H3 follow-up after the η_T correction | **Done 2026-10-21**; omitted-term cause **not found**; moved to §11 |
| 21 | One shared source-evaluation function; F1A at all 160 points, no GEXT on the aircraft path | **Done 2026-10-21**; moved to §11 |
| 22 | Documentation update for phase 21 | **Done 2026-10-21**; moved to §11 |
| 23 | Pre-registration of source pass criteria | **Frozen 2026-10-21** — values in `VALIDATION_GUIDELINE.md` §2.12 (I-06 / 23f done) |
| 24 | BBN/Wilby phase check | **24b PASS**; 23a pre-registered **FAIL** 26/168 on record; I-19 pair convention fixed 2026-10-22, post-hoc re-run 134/168 (79.8 %), still **FAIL**; tip assumed (24f); I-09 sense fixed |
| 25 | NACA Report 996 verification setup | **Done 2026-10-22** (25g: scope 2026-10-16 and criteria 23c frozen 2026-10-21); I-07 re-ran `report996_setup.md` (behind>ahead **false** after I-01/I-02) |
| 26 | CCBlade check vs Report 996 | **Numbers recorded** (`report996_loads.md`); labelled "criteria registered after the loads were computed" (I-06) |
| 27 | AcousticAnalogies check vs Report 996 | **I-07 + I-08 re-run 2026-10-21** (`report996_acoustics.md`): Fig.13a `scaled_RM_L51C27`; 23c scaled ±2 dB **FAIL** (5/24); page-12 phase **FAIL** (103.8° vs 155°) |
| 28 | Forward-flight check vs Pereira et al. (2026) | **I-07 re-run 2026-10-21** (`pereira_forward_flight.md`): loads OK (xtr005 s_T≈1.34); 23d H1 **FAIL** 0/9 (±1.7 dB); H2 6/9 (±3 dB); I-10 chord note recorded |
| 29 | Aircraft cabin inputs: audit, guard, provenance, required inputs | **Done 2026-10-22** (29a, 29d earlier; 29b guard and 29c provenance tags 2026-10-22) |
| 30 | Parametric cabin blocks for the aircraft | **Done 2026-10-22** (30a–30d; `cabin_blocks`, `parametric_regression.md`) |
| 31 | Uncertainty plan for the aircraft cabin result | **Done 2026-10-22** (31a–31f): 31e `UNC_COVER` **not met** (H1 inside; H2, H3 outside); aircraft band recorded; phase case re-run after I-19 (k = +0.094; phase does not dominate) |
| 32 | GEXT importance bound (e11 path) | **Done 2026-10-21** (`gext_importance_bound.md`): 32a–32f including **32e** OAT; flips → T1 not claimable |
| 33 | Close-out | **Done 2026-10-21**: 33a–33c/33e–33g (33d earlier); Table-8 cal kept optional (33b); GUI aircraft-only (33g) |
| 34 | Validation cases in the GUI: read-only Validation tab, reference-figure vs program-output plots, case registry | **Done 2026-10-21**; moved to §11 |
| 35 | Test audit, validation maps, "Validation map" GUI tab; plot error panels; report-pointer CSV replays; dB(A) band sum; directory cleanup; Cursor check rule | **Done 2026-10-21**; moved to §11 |

### Agent overnight close-out (2026-10-21, continued)

*Superseded by the review in §3.0 (several items below were voided).*

**Agent session 2026-10-21 (this pass), Q0 progress — closed except I-14:**
- **I-16 / I-15 / I-03 / I-04:** void files gone; author exports → schema CSVs; Fig. 8 pixel CSV (I-15 e).
- **I-01/I-02:** `n_rev_src=2`, absolute phase; `Pkg.test()` includes BBN 24b V-UNIT and Gutin ≤1 dB.
- **I-06/23f:** §2.12 frozen 2026-10-21.
- **I-09:** geometry + rotation sense written before 24c.
- **I-07 (done 2026-10-21):** `Pkg.test()`; smoke raw Table-8 −4.2/−5.3/−5.8 dB; e11 T1/T2 unchanged 81.04/75.00/75.29; `gext_vs_f1a_grid.md`; `report996_setup.md`; `report996_acoustics.md` (I-08); `pereira_forward_flight.md`; `bbn_phase.md` (24c–e).
- **I-08:** Fig.13a scaled with RM L51C27 Table I coefficients (47-in → 4-ft); tag `scaled_RM_L51C27`.
- **I-10:** Pereira 0.75R chord = paper “mean chord”; not rescaled.
- **I-11:** panel (c) confirmed NACA 4-(5)(08)-03; max |Δ(b/D)|≈0.026, |Δ(h/b)|≈0.041, |Δβ|≈1.5°; author `Fig 3.txt` (B-3) wrong panel; `blade_form.csv` stays 25b input (`tr996_fig3_blade_form.csv`).
- **I-12 / B-5:** smoke uses untuned geometry + `anopp_table8_calibrate=false`.
- **I-14 (done 2026-10-21):** 24a spot-check list in `data/NASA_CR-158919/README.md`; `bbn_data.jl` wide→long (748 rows, no CSV.jl dep).
- **32e + phase 33 (done 2026-10-21):** GEXT OAT comparator; claims/calibration/GUI source close-out. C-13 still optional.
- **Phase 34 done 2026-10-21:** Validation tab + registry + CairoMakie plots; 34d/34f tests. **GUI fix 2026-10-21:** Run binds to `val_selected` (not ListView.currentItem); only E21_E22_NR and R996_FIG8 greyed; E11/E12/E14/GEXT/BBN_KIN/R996_PHASE runnable in-process. Remaining: optional C-13; deferred 29b/29c/30/31 (B-4); inline remaining F1A script cores.
- **Phase 35 done 2026-10-21:** test audit (CYL2D ratios; MRP_D1 `no_verdict`; REPRO_18b 18b-r inputs); CASE_INFO + two validation maps + map GUI tab; plot error panels; CSV replays; `overall_dBA` band sum fixed; Cursor check rule (R13 / CLAUDE.md). Open: free-field amplitude convention (I-17).

### 3.0 Review of the 2026-10-21 agent run: issues and how to resolve them *(read before anything else; review dated 2026-10-21)*

The overnight run stopped on several blockers, and the review found two code bugs and several data files that were not read from the source. **Work through I-01 to I-16 in the order given before resuming the queue in §3.1.** Results that depend on a voided item are void; they stay in the record, labelled "void (I-nn)", and are regenerated, never edited by hand.

**Approvals and remaining blockers: §3.0a.** **All §3.0a blockers closed 2026-10-21.** **Order:** I-16, I-15 (a)–(c) already fixed (B-2) (author's new digitizations: answer the checks, then convert) → I-03, I-04 (quarantine data; superseded where I-15 replaces the files) → I-01, I-02 (F1A fix, [CONFIRM]) → I-05 (only cards not covered by I-15) → I-06 (freeze criteria, [AUTHOR]) → I-07–I-11 (re-run phases 21 check, 24, 26–28) → I-12–I-14.

| ID | Issue (evidence) | Consequence | Resolution (who) |
|----|------------------|-------------|------------------|
| **I-01** | **F1A source sampled over one blade pass only (bug).** `evaluate_propeller_source` passes `period = bpp` to `f1a_source_elements_ccblade`, so each blade element has source time only over 2π/(ΩB). `combine(apth, bpp, n)` starts its window at the latest first arrival (`common_obs_time`, `ksmax`) and runs one bpp, so it extends past the last reception time of the earliest elements and Akima *extrapolates*. Kinematic check (Report 996 geometry, 64 samples, 20 stations, B = 2): the window overruns element data by 12–18 samples at M_t 0.45, 21–30 at 0.75, 25–36 at 0.90, worst at x/D = 0. With a two-revolution source span it stays ≥ 155 samples inside. AcousticAnalogies' own guided example uses a source span of two revolutions and a reception window of 2·bpp. | Matches what was seen: Report 996 F1A amplitudes 24× (M_t 0.45) to 250× (0.90) the measured values near the rotation plane, close to them at x/D = ±0.5 (`report996_acoustics.md`); uncalibrated ℓ = 1 residuals against Table 8 of +5/+9/+14 dB growing with harmonic (Phase 6). **Void:** every F1A amplitude and phase computed so far: `ccblade_f1a_smoke.md` (uncalibrated values), `gext_vs_f1a_grid.md`, the aircraft example in `phase20_baseline.md` and `pipeline_smoke.md`, `report996_setup.md` (asymmetry and convergence), `report996_acoustics.md`, `f1a_results.csv`, `pereira_forward_flight.md` (levels and phases), `bbn_phase.md` probe. CCBlade loads (`report996_loads.md`, Pereira loads table) are **not** affected. | **[CONFIRM] `src/` change** in `src/propeller_ccblade.jl`, `evaluate_propeller_source`: (1) source span `period_src = 2·(2π/Ω)` with `n_src = 2·B·num_src_times` (same time step as before); (2) reception window `combine(apth, bpp, num_src_times)` unchanged (exactly one bpp, so bin H + 1 is harmonic H); (3) **guard:** before the FFT compute, for every element, the last reception time `t_last_e` (`mapview(:t, apth)[end, ...]`) and the first `t_first_e`; error if `t_common[end] > minimum(t_last_e)` or `t_common[1] < maximum(t_first_e)`, naming the observer; (4) echo `period_src`, `n_src`. Tests: (a) source span 2 rev vs 3 rev gives amplitudes equal to rtol 1e-3 and phases to 0.1° at a near-field Report 996 observer (M_t 0.9, x/D = 0, d/D = 0.083); (b) the guard fires when `period_src = bpp` is forced through a test-only keyword; (c) far-field check: at 100 R on the axis-normal plane, H1 amplitude within 1 dB of the Gutin closed form on the same integrated T and Q (V-UNIT; write the Gutin function in `test/` only). Then re-run everything in the void list (I-07). |
| **I-02** | **No common time origin for phase (bug).** `common_obs_time` starts each observer's window at a different absolute time t₀ (latest first arrival for that observer), and the code stores `angle(c)` of that window. 24b probe: Δφ = −12.5°, −13.9°, −4.7° against m·B·Δψ = 39.9°, 79.8°, 119.7° (`bbn_phase.md`). | Relative phase between observers is wrong everywhere it is used: Ψ_G of the aircraft path (sums A·cos φ, A·sin φ over 160 points), the 24b/24c BBN check, Report 996 p. 12 phase (177.5° recorded, void), Pereira ψ₁(φ) differences. | Same [CONFIRM] change as I-01: phase referenced to absolute observer time, `phase[i, H] = angle(c) − ω_H·t₀` with `t₀ = first(AcousticMetrics.time(apth_total))`, ω_H = 2π·H·bpf, wrapped to (−π, π]. Derivation: for p(t) = A cos(ω_H t + φ) sampled at t = t₀ + jΔt, the rfft bin has angle φ + ω_H t₀. Tests: (a) 24b relation Δφ = m·B·Δψ on a hub-centred ring (static) to 0.5°, both rotation senses (sign flips); turn the `@test_broken` into `@test`; (b) moving the same observer's window by an integer number of bpp leaves the phase unchanged; (c) the coincidence test of 21g still holds. |
| **I-03** | **Digitizations that were not read from the source (R9 breach).** Values sit on exact round grids or are copied: `e17_interior_ci.csv` (every CI = mean ± 2.00), `e10_interior_ci.csv` (mean ± 2.0), `e22_noise_reduction_ci.csv` (mean ± 3.00), `t2_third_octave_targets_B.csv` (1250/1600/2000 Hz = 56/54/52 dB vs pass A 51.0/46.0/41.5, a 5–10 dB gap, means equal to E-10), `t1_interior_targets_B.csv` ("did not consult pass A" but identical to it, δ = 0.00), `e18_interior_pred_eta1.csv` (measured columns = E-17 ± 2), `e21_noise_reduction_range*.csv` (δ_dig exactly at the 1.00 dB limit), CR-159124 Figs. 18–20 agent files (`bbn_phase_vs_freq_fig18_circumferential.csv`, `_fig19_longitudinal.csv`, `_fig20_longitudinal.csv`: every point on a 0.25π or 0.1π grid at round frequencies, linear in f) | None of them may be used as a reference. 31e (E-21/E-22) and 23e (E-17, E-10) are blocked again | **Quarantine (agent):** add a first header line `# VOID 2026-10-21 (plan I-03): not read from the source; do not use` to each file listed; do not delete (the author deletes). Set their §2.1 status to **To do (redo)**. Keep the author's WebPlotDigitizer files `fig18a_pair5-4_...` and `fig18b_pair5-3_...` (valid). Redo per I-05 |
| **I-04** | **Pereira digitizations wrong.** `pereira_fig9_harmonics.csv`: BEMT H4–H7 at 56–58 dB where the bars are about 20–30 dB (axis calibration wrong; H8–H10 marked "out_of_panel" although all ten harmonics are plotted); H2 Exp 83.7 dB at φ = 0°. `pereira_fig6_peaks.csv`: BEMT H1 26.5 dB where the spectrum peak is about 78 dB, several values at the 80 dB frame. `pereira_fig8_directivity.csv`: plausible magnitudes but panels (c), (e) and several φ missing | Phase 28 comparisons are void | Quarantine as in I-03 (all three files). Redo C-01, C-02, C-03 per I-05 |
| **I-05** | **Redo the digitizations, properly.** | Unblocks 23e, 28, 31e | The agent may redo them only with a script that calibrates from pixel positions of labelled gridlines and locates markers or bar tops in the pixels (§2.2 steps 1–8), with a QA overlay, and with the per-point pixel coordinates written to a sidecar CSV `<name>_pixels.csv`. **Typed or estimated values are not allowed.** Second passes (C-05, C-07, C-09, C-10) must use a different method (for example a 0.5 dB grid overlay read point by point) and must not open pass A. Cross-checks are recorded, never used to adjust a reading. If the agent cannot locate markers reliably in the pixels, it stops and lists the card for the author (WebPlotDigitizer). Order: C-01, C-03, C-02 (Pereira, phase 28), C-05 (E-21/E-22), C-07, C-09, C-10, C-08, C-11 (Figs. 19, 20 only) |
| **I-06** | **Criteria not frozen; numbers already computed (R3).** Phase 23 tolerances are [AUTHOR]; phases 26–28 were run before the freeze. | Any tolerance set after seeing 26's numbers makes 26 post-hoc. 27 and 28 are void (I-01, I-04), so their re-runs can still be pre-registered | **[AUTHOR]** fill §2.12 and date it (23f) **before** I-07 re-runs 24, 27 and 28. Proposed values derived only from evidence written before 2026-10-21 (the author may change them before the freeze, not after): **23a** BBN circumferential: \|residual\| ≤ 15° at H1–2, ≤ 35° at H3–7; pass if ≥ 80 % of rows with coherence ≥ 0.15 (pairs 4-3, 5-3, 4-5; 5-6 reported only) are within tolerance; trace-velocity ratio within ±0.10 of the measured ratio. **23a′** V-UNIT kinematics: 0.5°. **23b** in-plane levels: ±3 dB on (SPL_i − SPL_4), reported X-EXTRAP (assumed blade). **23c** Report 996: loads C_T, C_P within ±15 % (largest source-to-source spread, Fig. 14 table vs RM L8H25a); scaled-load pressure per harmonic and total rms within ±2 dB at ≥ 75 % of in-scope points, unscaled runs informational; page-12 phase within ±15°. **23d** Pereira: H1 within ±1.7 dB, H2 within ±3 dB, ψ₁(φ) − ψ₁(0°) within ±5°; a clipped or missing reference cell is excluded, not filled. **23e** held out of any calibration: E-17, E-10, E-21, E-22 (all). **Label for 26:** "criteria registered after the loads were computed" whatever the outcome |
| **I-07** | **Re-run after I-01/I-02 and I-06.** | Regenerates every voided report | Agent, in order: `Pkg.test()`; `run_f1a_smoke.jl` **with `anopp_table8_calibrate = false`** (report the raw F1A against Table 8; see I-12); `compare_gext_vs_f1a_grid.jl`; `run_pain.jl` (e11 T1/T2 must be unchanged from `phase20_baseline.md`, the e11 path does not use F1A); aircraft example; `report996_setup.jl`, `run_report996_acoustics.jl`; `run_pereira.jl` (after I-05); 24b, 24c, 24d, 24e. Each report header gets "re-run after plan I-01/I-02 (date)" |
| **I-08** | **Fig. 13(a) run used the wrong loads.** `report996_acoustics.md` scales Fig. 13(a) (β₇₅ = 15°, M_t 0.75) with "fig14proxy" loads (the β₇₅ = 10° Fig. 14 table). Phase 26 specifies RM L51C27 (15°, M_t 0.75) | Fig. 13(a) residuals void | Agent: scale to RM L51C27 Table I (`data\report996\naca_4-5-08-03\measured\noise\naca_rm_l51c27_table1_thrust_torque.csv`) in coefficient form (C_T = T/(ρn²D⁴), C_Q = Q/(ρn²D⁵) with the 47-in. diameter), applied to the 4-ft model at the same M_t; say so in the report |
| **I-09** | **BBN geometry mislabelled; rotation sense.** `bbn_geometry.csv` puts the hub at x = −1.31 m along the fuselage, which would take the rotation-plane microphones (x = 0) out of the plane; the 1.31 m is the **lateral** offset of the hub from the skin plane. Rotation sense is printed in neither report | Observers built from that file would be wrong; choosing the sign that fits would be calibration | Agent: rewrite the rows as `hub_x_m = 0` (rotation plane), `hub_lateral_offset_m = 1.310`, `hub_y_m = 0.432`, keep the residual, note "relabelled (I-09)". **Rotation sense resolved from documents (author, 2026-10-21), before any 24c run:** the Aero Commander 680E is a conventional twin, both Lycoming GSO-480 engines turn the same way and the left engine is critical, i.e. both propellers turn **clockwise seen from behind**; the microphones are on the **starboard** side of the fuselage (CR-158919 PDF p. 7, printed p. 1; CR-159124 PDF p. 13) and the starboard propeller is the source, so the blades pass the fuselage **moving upward** (the fuselage is inboard, to the left of the starboard hub seen from behind). Write `rotation_direction = clockwise_from_rear`, `view = from behind, looking forward`, `blade_motion_at_fuselage = upward`, source "author 2026-10-21; CR-158919 p. 1 starboard microphones". 24b/24c use this one sense; the opposite sense is not run for the verdict |
| **I-10** | **Pereira mean chord 25.9 mm vs 22.85 mm in the paper (resolved 2026-10-21).** Two independent digitizations of Fig. 1(b) agree (c/R = 0.216 at 0.3R, 0.17 at 0.7R, 0.135 at 0.8R). The chord at 0.75R is c/R ≈ 0.152, i.e. 22.9 mm at R = 0.15 m, equal to the paper's 22.85 mm, so the paper's "mean chord" is most likely the 0.75R chord, not an area mean | No digitization error; the geometry is used as digitized | Agent: record this in `data\pereira\README.md` and in `pereira_forward_flight.md` when it is regenerated; do not rescale the chord |
| **I-11** | **Report 996 Fig. 3 comparison.** `tr996_fig3_blade_form.csv` b/D differs from `blade_form.csv` by up to 0.026 (about 39 % at 0.75R) and h/b by up to 0.041, while β agrees within 1.5° | Either the wrong panel or curve was read, or the two sources differ | Agent: confirm panel (c) is the NACA 4-(5)(08)-03 from its caption, and that the curve read as b/D is the b/D curve (not h/b or b/R). Record the finding; `blade_form.csv` stays the geometry input (25b) |
| **I-12** | **Table-8 peak calibration is circular for the smoke check.** The aircraft path scales F1A to ANOPP Table 8 and the smoke test then compares with Table 8 (Δ = 0 by construction). It also hid I-01 | No information in the smoke check | After I-01: report raw F1A against Table 8 (X-EXTRAP); open decision 1 of phase 21 and 33b settle whether the calibration is dropped. A calibrated path is never compared with the data it was scaled to (CLAUDE.md) |
| **I-13** | **Remaining [CONFIRM] items.** 29b (NASA-default guard) and 29c (provenance tags) | Phase 30 waits | **[CONFIRM]** by the author; agent presents the diffs (as 21a did) |
| **I-14** | **Agent tasks left unfinished.** 24a spot-check list and the wide→long `scripts/run/bbn_data.jl` reshape; 32e (parameter-sensitivity comparator, no blocker); C-13 (optional) | — | Agent, any time after I-07 |
| **I-15** | **Author's digitizations of 2026-10-21 (raw exports) need converting and checking.** Files: `data\cr3813\raw_exports\Fig E-9.txt`, `Fig E-10.txt`, `Fig E-16.txt`, `Fig E-17.txt`, `Fig E-18.txt`, `Fig E-21.txt`, `Fig E-22.txt`; `data\pereira\Fig 1b.txt`, `Fig 6a/b/c.txt`, `Fig 8a–8f *.csv`, `Pereira Fig. 9 Deg=0/20/40.txt`; `data\NASA_CR-159124\Fig 19.txt`, `Fig 20.txt`; `data\report996\Fig 3.txt`. Consistency findings from a read-through on 2026-10-21 (the author decides; nothing is changed by the agent): **(a)** Fig. E-9 starts at 125 Hz with 69.5/90.0 dB at 125/160 Hz, where E-16 has them at 160/200 Hz (BPF H1 is 200 Hz): band column looks shifted by one band from 125 to about 315 Hz. **(b)** Fig. E-18: 90.0 dB at 160 Hz and 54.0 dB at 630 Hz, against E-16/E-17 at 200 and 800 Hz: same kind of shift. **(c)** Fig. E-10 has 62.5 dB at 250 Hz and 71.0 at 315 Hz; E-16 and E-17 have 71.0/70.5 at 250 and 62.5 at 315: possibly swapped. **(d)** Pereira Fig. 9: H1 = 80 dB for all three series at all three angles while the ΔSPL column is non-zero (for example +1 at φ = 0°), and Fig. 6a peaks near 79 dB; check whether the H1 bars were read at the frame. **(e) Resolved 2026-10-21:** Pereira Fig. 8 re-digitized from the pixels of the embedded image at the author's request (`data\pereira\pereira_fig8_directivity.csv`, script `data\digitizers\dig_pereira_fig8_pixels.py`, overlay `data\pereira\qa\pereira_fig8_pixels_overlay.png`); it replaces the author's `Fig 8a`–`Fig 8f` files (to be deleted by the author). At φ = 0° it agrees with the Fig. 9 bars within about 1 dB for H1–H3; Fig. 9 H1 (all 80 dB) remains item (d). **(f)** Report 996 `Fig 3.txt`: h/b = 0.123 at r/R = 0.7, where the designation 4-(5)(08)-03 means h/b = 0.08 at 0.7R (`blade_form.csv` 0.0806), h/b = 0.28 at the root is above the 0.20 axis, β₇₅ = 16.8° against the design 42.64°, b/D about half of `blade_form.csv`: probably a different panel or curve (I-11). **(g)** E-21 at 100 Hz: minimum equals the average (16 dB). **Agent:** after the author has answered (a)–(g), convert each file to the schema CSV of its card (§2.3) with the §2.2 header (source, PDF page, method "author, WebPlotDigitizer", date) **without changing any value**, keep the raw `.txt` beside it, and record the answers in the header | Each reference file has a schema CSV; (a)–(g) answered and recorded |
| **I-16** | **Leftover void agent files still in `data\`.** `data\cr3813\e10_interior_ci.csv`, `t1_interior_targets_B.csv`, `t2_third_octave_targets_B.csv`; `data\NASA_CR-159124\bbn_phase_vs_freq_fig18_circumferential.csv`, `bbn_phase_vs_freq_fig19_longitudinal.csv`, `bbn_phase_vs_freq_fig20_longitudinal.csv` | Could be picked up as references | Author deletes them (the agent may not). The I-15 conversion writes the new `e10_interior_ci.csv` etc. only after they are gone |
| **I-17** | **Free-field amplitude convention (rms vs Fourier peak) — closed by Phase 37b, 2026-10-21 (theory audit 2026-10-21; status corrected 2026-10-28).** `spl_dB_to_Pa` (`freefield_digitized.jl`) converts E-11 / ANOPP Table 8 SPL to Pa as an rms-equivalent amplitude and that value enters Eq. (42) as A (Δ⁴/2 assumes a cosine peak; User Manual card 38 "amplitude of Fourier component (Pa)"). F1A stores the peak (A = √2 p_rms). Documentary evidence: CR-3813 Eqs. (28)–(31) A_H = √(a_H²+b_H²), mean square A²/2 → cosine peak; CR-172428 p. 41 ⟨p²⟩ = p₀² 10^(SPL/10) → SPL is rms-referenced; CR-172428 §3 predictions are Fourier representations "as required for PAIN input". Hence A = √2 p₀ 10^(SPL/20); the code omits √2 → e11/Table-8 tones ~3.01 dB low (T1, T2 tonal part, REPRO_18b, E12 levels, GEXT_BOUND). F1A path already peak. | Affected e11/Table-8 tone SPLs ~3 dB low; fixing would give REPRO_18b ≈ +6.7, +3.2, +12.1 dB (result known → any change is post-hoc) | **Decided 2026-10-21 (author): fix, on documentary grounds** (author: "not tuning" means not adjusting toward experimental data; a documented convention fix is allowed). The same error was found in three comparisons against rms measurements: NACA Report 996 p. 10 "Pressure amplitudes (rms) of the first four harmonics were measured with a harmonic wave analyzer" (Figs. 12, 13a, 14 compared F1A's peak A with rms data, +3.01 dB bias); Pereira et al. 2026 p. 13 "The root-mean-square of the pressure fluctuations yields a tonal noise emission of 84.6 dB" (= Table 4; `run_pereira.jl` converted the peak A to SPL); `run_f1a_smoke.jl`. Fix in phase 37 step 37b; every affected result is re-recorded and labelled post-hoc |
| **I-18** | **Lower-quarter grid (mirroring) — reopened 2026-10-21 (completeness audit).** Decision 19d (use the 160 upper-quarter points only) read the User Manual and CR-3813 §3.4 and left Manual output item 7 ("both above and below θ = 0") unresolved. It did not cite CR-172428 §3: "PAIN then generates data for an identical grid on the lower quarter surface of the fuselage nearest the propeller (using the data input for the upper grid)". The 19d diagnostic, mirroring about the ℓ = 1 line, moved 18b by +0.73, +3.18, +6.81 dB | Changes Ψ_G at every harmonic; known direction → post-hoc if adopted | **[AUTHOR] decision rule, dated 2026-10-21 before phase 38b runs:** keep the 160 points for now (noted). Adopt mirroring about the ℓ = 1 line **only if** the high-frequency tone formulation (phase 38b) "explains H3", defined now as: with the 38b crossover rule (fixed before the run), the REPRO_18b H3 value is within the 18b criterion (≤ 4 dB of NASA's 68.0 dB) where the Eq. (8) value is not. If adopted, all affected results are re-recorded and labelled post-hoc |
| **I-19** | **BBN circumferential phase sign (23a, 26/168).** F1A's phase difference matches the rigid-rotation value m·B·Δψ in magnitude, and the measured CR-158919 App. C phases have the opposite sign at most rows (`bbn_phase.md` finding). CR-158919 App. C p. C-1 says only that the phase was read from the SD360 analyzer in −π…π; it does not say which microphone of a pair is the reference. Rotation sense and geometry were checked: blades move upward at the fuselage as recorded (I-09) | 23a stays FAIL | Not fixable from the source; choosing the sign that fits would be tuning against experiment. Recorded; a sign-free magnitude comparison may be shown only as a labelled post-hoc diagnostic, never as a pass **Root cause found 2026-10-22 (§8 "I-19 resolved"):** CR-158919 §3.4 measured pair phase as the SD360 transfer function B/A and Table 8 signs give printed phase = φ_b − φ_a; the comparison read φ_a − φ_b. Post-hoc re-run 134/168 (79.8 %), still FAIL. |
| **I-20** | **R996_FIG8 out of scope.** Report 996 Fig. 8 is at tip Mach 1.0; the 2026-10-16 scope decision tests M_t 0.45–0.90 only, and the author confirmed 2026-10-21 that transonic effects are not studied | — | **Removed 2026-10-21** (author): case deleted from the registry, the aircraft map and the docs, not deferred |

### 3.0a Author approvals and remaining blockers *(recorded 2026-10-21)*

**Approvals (author, 2026-10-21: "approve everything").** The agent applies these without stopping; under R1 it still writes the diff of each `src/` change into the step's report and runs the step's tests before any re-run that depends on it. If a listed test fails, it stops (§0.4).

| Item | Approved | Condition |
|------|----------|-----------|
| I-01, I-02 F1A source-span and phase-origin fix | Yes | Tests (a)–(c) of I-01 and (a)–(c) of I-02 pass before I-07 |
| I-06 criteria freeze | Yes: **23a, 23a′, 23b, 23c, 23d, 23e frozen 2026-10-21 at the values proposed in the I-06 row**; 23f done | Agent copies the values into `VALIDATION_GUIDELINE.md` §2.12 with the date, removes "[AUTHOR]" there, before any I-07 re-run. 26 is labelled "criteria registered after the loads were computed" |
| I-13 29b guard, 29c provenance tags | Yes | Tests pass; existing outputs unchanged apart from the new fields |
| 30b, 30c (parametric loss factors, raw-Ritz modes on the aircraft path) | Yes | 30d regression recorded; baseline renewal (R11) still a separate dated decision |
| 34a, 34b (CairoMakie dependency), 34e (GUI) | Yes | 34d, 34f pass |
| I-15 (d), (e) Pereira Figs. 8, 9 | Accepted as digitized by the author: Fig. 8 = `pereira_fig8_directivity.csv` (pixel digitization, 2026-10-21); Fig. 9 "mostly fine" | The H1 bars at 80 dB are taken as read; the Fig. 8 vs Fig. 9 difference at H1 is recorded in the 28 report as reference scatter, not corrected |
| Phase 31 design | Yes, as written in phase 31, with these 31d choices fixed now (before any run): uniform distributions over the registered ranges, N = 2000, seed 20261021; repeat with triangular distributions (mode = nominal) | Dated in phase 31 before 31d runs |

**Remaining blockers (none is a code decision).**

| # | Blocker | Blocks | Needs |
|---|---------|--------|-------|
| B-1 | ~~`t1_interior_targets.csv` deleted~~ **Closed 2026-10-21:** restored by the author with `git restore`; the void `t1_interior_targets_B.csv` is gone | — | — |
| B-2 | ~~I-15 (a), (b), (c) band alignment of Figs. E-9, E-18, E-10~~ **Fixed 2026-10-21** (by Claude at the author's request, frequency column only, no values re-read): **E-9** rows relabelled 125→160, 160→200, 200→250, 250→315 Hz and the extra row read at "315 Hz" (80/70/53 dB, a point on the 315→400 Hz rise, not a band) removed; **E-18** measured columns moved one band up for 160–250 Hz and 630–1000 Hz, two mid-slope points (63.0 dB, 50.0 dB) removed, measured values at 160 and 630 Hz left blank (not read), PAIN column unchanged except 88.0 dB moved 160→200 Hz; **E-10** 250 and 315 Hz values swapped. Checked against the curve shapes on PDF pp. 132, 133, 145 and against E-16/E-17. Originals: the author's exports before this edit (not kept in `data\`) | — | — |
| B-3 | **I-15 (f):** `report996\Fig 3.txt` does not look like the NACA 4-(5)(08)-03 panel (h/b 0.123 at 0.7R vs 0.08 by designation; β₇₅ 16.8° vs 42.64°) | I-11 check only (`blade_form.csv` stays the geometry input) | Author: confirm the panel; not blocking any run |
| B-4 | ~~Aircraft inputs (D-20)~~ **Closed 2026-10-21: no aircraft predictions will be run** (author). The aircraft propeller is information only. Phases 29b/29c, 30 and 31 are **deferred, not run**; their test-article parts (30d regression, 31e coverage check on E-21/E-22) are optional | — | — |
| B-5 | **`examples\aircraft_scale_hartzell.json` is tuned to Table 8** (`pitch_offset_deg = −5` and `thickness_over_chord` "tuned so ℓ = 1 peak SPLs are within ~15 dB of ANOPP Table 8"; chord/twist are estimates) | The raw F1A vs Table 8 check of I-12 would be circular (CLAUDE.md) | Agent: after I-01, run the smoke check with `pitch_offset_deg = 0` and t/c from the section, labelled X-EXTRAP; the tuned case is kept only as "calibrated (Table 8)" and is never compared with Table 8 as a check |
| B-6 | ~~Julia on the agent's machine~~ **Closed 2026-10-21:** the author confirms the agent can run `julia --project=.` from `rea-work\PAIN.jl` | — | — |

Not blockers (recorded so nobody stops on them): BBN tip geometry beyond 40 in. (two assumed tips, X-EXTRAP); Report 996 Fig. 6 has no B = 4 loads (judged on shape); 32e and C-13 (optional); 33b Table-8 calibration decision (settled at close-out, but no calibrated path is compared with Table 8 meanwhile, B-5).

### 3.1 Work queue (run in this order)

| Q | Item | Kind | Prerequisite | Output |
|---|------|------|--------------|--------|
| Q0 | **Review issues I-01 to I-16 (§3.0)**, in the order given there | mixed: data quarantine, `src/` fix [CONFIRM], redo digitizations, criteria [AUTHOR], re-runs | none | **done 2026-10-21/22** (§3.0a: all blockers closed; I-17–I-20 decided) |
| Q1 | Run step 19i (§5) | script run, no `src/` change | none | **Done 2026-10-21** `h3_followup.md`; 19i in §11 |
| Q2 | **Docs sync for the η_T = 0.5 decision** (left over from phase 20): `METHODOLOGY.md` §6 T1/T2 numbers and the 18b text → 18a-r / 18b-r of `phase20_baseline.md`; claim register; `VALIDATION_GUIDELINE.md` §2.7/§2.8/register f; `README.md`; `flowchart.md` | docs only | Q1 | **Done 2026-10-21** (same pass as 19i) |
| Q3 | Phase 21 | `src/` change [CONFIRM] waived by author “keep going”; **done 2026-10-21** | Q2 | shared function, tests, `gext_vs_f1a_grid.md` |
| Q4 | Phase 22 | docs | Q3 | **Done 2026-10-21** |
| Q5 | Phase 23 | pre-registration [AUTHOR] | Q4 (draft may precede) | **§2.12 frozen 2026-10-21** (I-06) |
| Q6 | Phase 24 | scripts + tests | Q5, D-21 (C-06 **done**), phase 21 | `bbn_phase.md` |
| Q7 | Phase 25 | setup, 25h/25i [CONFIRM] | Q5, D-07 | **Done 2026-10-22** (25g recorded); `report996_setup.md` (25k) |
| Q8 | Phase 26 | script | Q7 | **done**; `report996_loads.md`; verdict R996_LOADS 6/32 not met (post-hoc label) |
| Q9 | Phase 27 | script | Q8 | **done**; 23c verdicts recorded (R996_FIG14 5/24, FIG12 21/40, FIG13A 8/14, not met) |
| Q10 | Phase 28 | script | Q5, Q7 (polar loader), D-11–D-13 (C-01–C-04 **done**) | **Expanded**; ScaledLoads path; 23d verdict |
| Q11 | Phase 29 (29a any time; 29b, 29c [CONFIRM]) | docs + `src/` | Q3 | **Done 2026-10-22**: register rows, guard, tags |
| Q12 | Phase 30 | `src/` [CONFIRM] | Q11, D-20 | **Done 2026-10-22**: parametric blocks, 30d shift |
| Q13 | Phase 31 | design [AUTHOR], runs | Q12, D-16 | **Done 2026-10-22**: band, report template; 31e not met |
| Q14 | Phase 32 | script runs | Q2 | **Done 2026-10-21** including 32e |
| Q15 | Phase 33 | close-out | all | **Done 2026-10-21** |
| Q16 | Phase 34 | `src/` + GUI [CONFIRM] | Q15 | **Done 2026-10-21** |
| Q17 | Phase 35 | `src/` + GUI + docs | Q16 | **Done 2026-10-21** |
| Q18 | Phase 36 — cabin mode animation in the GUI (§8) | GUI + `src/` [CONFIRM] | Q17 | **Done 2026-10-22** (author: "continue until no more phases are implemented"); steps 36a–36e |
| Q19 | Phase 37 — root-cause fixes from the 2026-10-21 GUI review (§8) | GUI + `src/` + scripts (author asked "find all root causes and fix all of them") | Q17 | 37a done 2026-10-21; 37a–37i done 2026-10-22 |
| Q19b | **R1 directory reorganization** (spec `docs/specs/R1_directory_reorg.md`): CR-3813 data → `data/cr3813/`, scripts → `scripts/{run,checks,digitize,setup,smoke}`, READMEs, every path reference updated | moves + path edits | P1 (done, `ef184d8`) | **Done 2026-10-22** (record in §11); reviewer runs full `Pkg.test()` |
| Q20 | Phase 38 — CR-3813 / User Manual completeness (§8; audit `validation_reports/cr3813_completeness_audit.md`; 38a spec `docs/specs/38a_noise_reduction.md`, equation page images `docs/specs/cr3813_pages/`) | `src/` + cases (author: "the whole PAIN program is supposed to function just like it does in the PAIN Methodology") | Q19 (37b first: amplitude convention) | 38a done (`:not_met`); 38b done (I-18 rule not met); 38c done (T2 not met); 38d done (`:not_met`); 38e done (no verdict); 38f-1, 38f-2, 38h done; 38g done (`:met`, 27/32) in order; 38f–38h planned with the author before starting |
| Q21 | **Phases 39–44 — block validation program** (§8b, at the bottom; audit `validation_reports/block_validation_audit.md`) | `src/` + tests + cases + GUI map | Q20 | **done 2026-10-23** (39–44); results in §8b |
| Q24 | **Phase 46 — isolated checks for the five untested T1/T2 functions** (§8d) | tests in `runtests.jl` | Q21 | **done 2026-10-23**: 37/37 met |
| Q25 | **Phase 47 — T2 with a measured exterior spectrum** (TP-2444 Fig. 17 = this article at 4000 rpm; §8d) | `data/tp2444/`, new cases | Q24 | **done 2026-10-23**: not met (47a not met as written, 47b met, 47c 1/7, 47d 21.3 vs 51.0 dB); the cabin's high-frequency NR is the gap, also in NASA's own E-21/E-22 predictions |
| Q26 | **Phase 48 — exterior broadband from physics (NASA RP-1218)** (§8d) | new source module, cases | Q25 | **done 2026-10-23**: 48a met 270/270; 48c not met (3/9, 2/7); 48d not met (cabin path) |
| Q27 | **Phase 49 — check the trim and high-frequency inputs inside PAIN's own theory** (§8e) | tests, report | Q25 | **done 2026-10-23**: no in-theory correction; Eq. (20) reading defect fixed (≤ 0.3 dB); NASA documents that the trim model is valid to about 1 kHz |
| Q28 | **Phase 50 — propeller-field coupling for Eq. (18) broadband** (§8e) | option + cases | Q27 | **done 2026-10-23**: 50a not met (Eq. 66 separable approximation, 0.4–2 dB), 50b not met 2/7 (315–800 Hz within −3…+7 dB) |
| Q29 | **Phase 51 — sound-bridge path in Eq. (23)** (§8e) | option + cases | Q26, Q28 | **closed 2026-10-23**: not run (no verifiable official-source model); PAIN's own bridge path is A.19–A.21 |
| Q30 | **Phase 52 — T1 H3 miss** (§8f) | diagnostics | Q21 | **done 2026-10-23**: the cabin matches NASA at H3; the excess is the e11 off-line field; no documented correction |
| Q31 | **Phase 53 — negative and runaway NR** (§8f) | guard, tests | Q21 | **done 2026-10-23**: equation property (CR-159363 p. 138); 400 Hz runaway fixed by the Eq. (20) reading; `sparse_guard` option |
| Q32 | **Phase 54 — Q22: NASA's program listing** (§8f) | document check | Q22 | **done 2026-10-23**: not explained by the documents; Q22 closed |
| Q33 | **Phase 55 — T2's calibrated surrogate** (§8f) | decision, docs | Q25 | **done 2026-10-23**: stays the default, labelled calibrated |
| Q34 | **Phase 56 — 40f Ritz isolation** (§8f) | `src/` option, test | Q21 | **done 2026-10-23**: 56a met, 56b not met (the solver is not Donnell–Mushtari) |
| Q35 | **Phase 57 — tests for never-executed functions** (§8f) | tests | Q24 | **done 2026-10-23** |
| Q36 | **Phase 58 — leftovers** (§8f) | QA, docs | Q25 | **done 2026-10-23** |
| Q37 | **Phase 59 — Phase 51 run: Sharp sound bridges from NASA CR-172490** (§8g) | option + cases | Q29 | **done 2026-10-23**: 59a not met (3/13), 59b met, 59c–e not met; the bridges close about 7 dB of about 30 |
| Q38 | **Phase 60 — structural modes above Table D-1 from the App. D solver** (§8g) | input extension + re-runs | Q34 | **closed 2026-10-23**: 60a not met (mode count inconsistent), not adopted |
| Q39 | **Phase 61 — reproduce NASA's CR-3813 printed outputs with NASA's pre-correction program form** (§8h) | option + cases | Q37 | **closed 2026-10-23**: the floor sign does not reproduce CR-3813's runs (1/3, 1/4, 1/4); the differences are not explained by the documents |
| Q40 | **Phase 62 — a proving case with its own figure for every validation-map block** (§8i) | cases + §2.13 | Q39 | **done 2026-10-23/24**: 12 cases, 9 met; `BLK_GAIN_MAP`, `MRP_SHAPE_NORM`, `CYL2D_WEYL` not met (reasons recorded); every block has a case with a figure (unit test) |
| Q41 | **Phase 63 — the structural-modes animation in the GUI works** (§8i) | GUI check | Q40 | **done 2026-10-24**: structural frames step with the acoustic frames; offscreen smokes pass |
| Q42 | **Phase 64 — a unit test for every function, in `test/unit/`** (§8i) | tests | Q41 | **done 2026-10-24**: `test/unit/` 25 files, completeness test passes; 8 code defects found and fixed (incl. the F1A_GUTIN reference) |
| Q43 | **Phase 65 — grid axial direction and z_p against the User Manual and App. E** (§8i; found by Phase 62 input QA) | `src/` fix + re-records | Q40 | **done 2026-10-23/24**: z_k = z_p − x₃, z_p = 0.662 m; 12 cases' numbers re-recorded, no verdict changed |
| Q44 | **Phase 66 — further code checks of BEMT and F1A** (§8j) | cases + tests | Q42 | **done 2026-10-24** (author: "Yes, run Phase 66"): 7/8 met; `F1A_GUTIN_ANGLES` not met (near-null phase at θ = 60°) |
| Q46 | **Phase 67 — test the attribution of the source-block experimental misses** (§8k) | cases | Q44 | **done 2026-10-24**: polars are the cause (POLAR_FIDELITY not met 9/60; thrust 25–32 % low, consistent); compact chord ruled out (≤ 0.27 dB). Limitation of the section-data approximation |
| Q47 | **Closure register** (`VALIDATION_GUIDELINE.md` §2.14) | docs | Q46 | **done 2026-10-24**: every not-met case classed (M/A/I/N/D); no open code defect. **Reopened 2026-10-28** by Q48 (polar loader defect). **Closed again 2026-10-28** after the Phase 69 rerun: every reopened case re-classed, no open code defect |
| Q45 | **Aircraft working example cabin length** (`aircraft_scale_hartzell_cabin_full.json`: a = 1.32 m, assumed L = 1.83 m, z_p = 0.90 m) | note | Q43 | **closed 2026-10-24, not needed** (author: validation uses the experimental articles, not user input). The demonstration example's assumed 1.83 m cabin is shorter than the Manual grid for a = 1.32 m (80 of 160 points off the cabin); `grid_points` warns on any such input. No validation or experimental case uses this example |
| Q23 | **Phase 45 — T2's high-frequency path on the TP-1964 bare cylinder** (pre-registered 2026-10-23 before any run; §8c) | `hf_broadband.jl` via `PainInputs`, new case | Q21 | **done 2026-10-23**: not met 9/18; Eq. (19) bands 4/4 within ±2.5 dB |
| Q22 | **q = 0 cabin modes against CR-172428 App. B** (closed 2026-10-23, Phase 54: not explained by the documents) (after 44f). On NASA's printed pairs at 5000 rpm we agree within 0–6 dB, most within 1 dB. But our largest contributors have axially uniform (q = 0) cabin modes, e.g. (0,1) × mode 8 (5.6 Pa² against NASA's 4000 rpm H1 total of 0.59), and none of NASA's 25 printed top pairs has q = 0. Diagnostic only, not adopted: with q = 0 excluded, R172428_CODE would give 8/9 within ±3 dB. CR-3813 Eq. (57) and its Ref. [3] (CR-159363 Eq. 25, downloaded 2026-10-23) both give f₀M = 2/(Mπ) ≠ 0, so the documents do not explain NASA's output; no change without a documentary basis | `pain_core.jl` coupling, Ψ_G of antisymmetric modes | Q21 | open |
| Q48 | **Phase 69 — polar audit, loader fix and XFOIL rerun** (§8m; audit 2026-10-28) | `src/polars.jl` fix + XFOIL rerun + re-records | Q47 | **done 2026-10-28**: loader uses one section (16-101) for every Report 996 station, no Re/M interpolation, no Viterna; CCBlade gets μ = 1 (Re about 10⁵ too low); N_crit for Report 996 calibrated to TN 1546 (16-506, 16-509), 16-312 held out (rule fixed 2026-10-28). Fixed and rerun: R996_LOADS 24/32 (was 6/32), FIG12 28/40; no verdict changed |
| Q49 | **Phase 70 — free-field block audit** (§8n; 2026-10-28) | case records, map placement, tests | Q48 for F4 | **done 2026-10-28**: FF_E11_MAP passes by construction and is on the wrong block; ISO_TABLE8 identity only; PROP_BB_* on the e11 block and hit by the Phase 69 polar defects; stale z_p fixed |
| Q59 | **Phase 80 — MRP validation** (§8x; 2026-10-29) | `mrp_appd.jl`, `AppDDeck`, cases, guards | Q57 | **done 2026-10-29**: NASA's MRP input deck found in the User Manual (pp. 42–43); on it the App. D solver reproduces Table D-1 (MRP_APPD met 32/32, frequencies within 0.012 %); NASA's floor form (no floor cross terms) kept as PAIN's function, its near-rigid-shell limit not met (MRP_COUPLED_LIMITS 66/78, class M); MRP_TRUNC met; input warnings and PAIN card input for new fuselages |
| Q61 | **Phase 81 — PAIN main block** (§8y; 2026-10-29) | case fixes, two new cases | Q59 | **done 2026-10-29** (ISO_MODAL_DENSITY 12/12 above the floor; SHARP_PANEL_D_SHAPE and LOUDEST_PT_GRID met; SHARP_PANEL_D class N; LOUDEST_PT (a) class D): ISO_MODAL_DENSITY passes 2 rows by construction; HF_MASSLAW info row counted in the chip; SHARP_PANEL_D source inconsistent with its own inputs; LOUDEST_PT test design; solutions 81a-81d |
| Q60 | **CYL2D for other floor angles** (found by Phase 80f, 2026-10-29) | `cyl2d.jl`, production NY | Q59 | **done 2026-10-29**: production uses the next solvable grid when NY = 10 has no App. C solution for the floor angle (`cyl2d_modes_solvable`, Q60, 2026-10-29): NY = 10 is unchanged for θ0 = 56.6°; for θ0 = 45.3° (the 2.64 m example × 0.8) NY 10 and 11 give complex eigenvalues among the 20 kept modes and NY = 12 is used, with a warning. Over θ0 = 30°–80° the first solvable grid from NY 10 is within 3.3–6.6 % of NY = 60 (θ0 = 56.6°, NY 10: 4.9 %), so the fallback grid has the same discretization error class as the paper's; information, no criterion (probe 2026-10-29). `run_pain_pipeline` and the uncertainty chain call it; Phase 80f's θ0 × 0.8 row now has numbers (`phase80_mrp_sensitivity.md`) |
| Q62 | **Validation status at a glance** (author 2026-10-29: the map as a flowchart at the top of the validation document, and per block the cases with the points they pass, to see what to work on next) | `validation_plots.jl`, `VALIDATION_GUIDELINE.md` §0 | — | **done 2026-10-29**: `write_validation_scoreboard` writes §0 from §2.13 and `case_error_summary.csv` (Mermaid map coloured by verdicts, group totals, not-met cases with the fewest points first, one table per group); `write_case_error_summary.jl` regenerates it with the CSV. Display only |
| Q63 | **Phase 82 — meaningfulness audit of the not-met cases** (§8z; 2026-10-29) | `validation_cases.jl`, §2.15 | Q62 | **done 2026-10-29**: 26 E, 10 P kept; 7 X now information; R172428_ETA re-classed N (82c). **Open follow-up:** audit the met cases with the same rule (a met case that compares with neither measurement nor PAIN's printed output is not a validation pass) |
| Q64 | **Phase 83 — the not-met cases with the fewest points: audit, solutions, runs** (§8aa; 2026-10-29) | `hf_broadband.jl`, `noise_reduction.jl`, `validation_case_iso83.jl` | Q63 | **done 2026-10-29**: the mode-set cause refuted (E22_HF_DECK 0/4, T2_EQ19_DECK 0/3, REPRO_18b_DECK 0/3); T2 information; UNC_COVER re-stated; criteria in §8aa dated before the runs. The met-case audit of Q63 is paused for this (author 2026-10-29: "i wanted the not met fewest criterions auditted and planned phases first"); its work in progress is kept outside the tree and resumes after Phase 83 |
| Q58 | **Phase 79 — CYL2D** (§8w; 2026-10-28) | `case_error_summary`, `cyl2d.jl`, CYL2D_WEYL | Q57 | **done 2026-10-28**: information rows leave the pass count; refinement fixed (79b); CYL2D_GRID_CONV (NY 10 within 4.9 % of NY 60); Weyl + surface term 4/5; production NY = 10 kept (decided 2026-10-28) |
| Q57 | **Phase 78 — structural modes** (§8v; 2026-10-28) | `mrp_appd.jl`, MRP_APPD criterion, map | Q53 | **done 2026-10-28**: App. D solver fixes J1–J6; MRP_APPD not met 2/32 (class I, floor stiffener model undocumented); MRP_D1/MRP_RITZ off the map |
| Q56 | **Phase 77 — POLAR_FIDELITY as an equivalent angle** (§8u; 2026-10-28) | `src/validation_case_iso67.jl`, figure | Q52 | **done 2026-10-28**: Δα shown next to Δc_l, display only |
| Q55 | **Phase 76 — thickness noise in the experimental source comparisons** (§8t; 2026-10-28) | `src/propeller_ccblade.jl`, scripts, re-records | Q51 | **done 2026-10-28**: R996_FIG12, R996_FIG14 and PER_FIG7 now met; totals 44 met, 42 not met |
| Q54 | **Phase 75 — stale validation figures** (§8s; 2026-10-28) | script, `src/gui_main.jl`, figures | Q51 | **done 2026-10-28**: `regenerate_case_figures.jl`; GUI flags a figure older than its record |
| Q53 | **Phase 74 — Pereira PER_FIG8 / PER_FIG9** (§8r; 2026-10-28) | Fig. 9 re-digitization from the PDF vectors, shear-layer bound | Q51 | **done 2026-10-28**: Fig. 9 re-read from the PDF vectors (H1 = 80 dB was a misreading); PER_FIG9 H1 9/9; remaining H2 misses class N |
| Q52 | **Phase 73 — Report 996 section-polar fidelity** (§8q; 2026-10-28) | polars, re-records | Q51 | **done 2026-10-28**: section c_l is not the cause (≤ 7.9 % thrust, ≤ 0.19 dB); XFOIL c_d about 25 % below TN 1546, about half the torque gap; 73e decided 2026-10-28: TN 1546 c_d level not adopted |
| Q51 | **Phase 72 — observer fore/aft convention** (§8p; 2026-10-28) | scripts, `src/propeller_ccblade.jl`, re-records | Q48 | **done 2026-10-28**: Report 996 `x_sign = −1` and Pereira x = +sin φ put behind/downstream microphones ahead; Pereira Fig. 7 phase sign |
| Q50 | **Phase 71 — audit of the remaining map blocks** (§8o; 2026-10-28) | scripts, reports, records | Q49 | **done 2026-10-28** (A3b: no missing Eq. (43) term): z_p fixed in four report scripts (reports regenerated 2026-10-28); CYL2D_WEYL reclassed; which cases the polar defects reach is traced |

If a queue item is blocked on data, skip to the next unblocked item and say which data item blocks it.

**Run** (PowerShell, from `rea-work\PAIN.jl`, one command at a time; Julia must be on PATH, see `README.md` Step 0):
```powershell
cd C:\Users\FrancisHoang\git\PAIN\rea-work\PAIN.jl
julia --project=. -e "using Pkg; Pkg.test()"
julia --project=. scripts/run/run_pain.jl
julia --project=. scripts/run/run_f1a_smoke.jl
julia --project=. scripts/run/mrp_ritz_vs_d1.jl
```

### 3.2 Notes kept from earlier sessions

**Renumbering (2026-10-20).** The planned phases were renumbered into run order. Old → new: 21 step 0 → 12a, 21u → 12b; 21w → 13a, 21x → 13b; 21v → 14a; 21n, 21o → 15a, 15b; 21p, 21q → 16a, 16b; 21r, 21s → 17a, 17b; 21e–21m → 17c–17k; 21t → 18a; 12 → 19; 13 → 20; 14 → 21; 15 → 22; 16 → 23; 17 → 24; 18 → 25; 19 → 26; 20 → 27; 21a–21d → 28a–28d; 22 → 29; 23 → 30; 24 → 31; 25 → 32. Step letters keep their order within each phase.

**Renumbering (2026-10-20, second).** Step 32h became phase 19, placed right after phase 18 because every later cabin result inherits the 18b miss; the planned phases 19–32 moved up by one (19 → 20, …, 32 → 33), step letters unchanged. Code comments under `src/` that name the old numbers (for example "phase 29b" in `pain_core.jl` and `trim_loss.jl`) are left until the comment edit of step 33e.

**Educated closures this session**
- **Phase 4:** Coupled Donnell shell + Kirchhoff floor + junction springs + D-1 shape Rayleigh seeds. Production = hybrid (D-1 eigenvalues + Ritz shapes). Raw spectral match **30/32** within 5% (`k_scale=0.61`, `edge=2.2`, `floor=2.4`, `k_j=1e7`); D-1 #2 and #9 still need full Peterson.
- **Phase 6:** Optional ANOPP Table-8 ℓ=1 peak calibration on F1A line amplitudes (X-EXTRAP). Disable via `anopp_table8_calibrate: false`.
- **Phase 7:** Eq.(19)→(23) HF with absorption α, modal density n(ω), band ⟨j²⟩; `j2_scale=0.5` for Spbl-anchor overcount. Figs E-9/E-10 provide no >2 kHz means. The trim factor became τ_t of Eq. (A.22) in 17b (done); the rest is replaced in 30b.
- **Phase 8:** App.E fiberglass+septum masses; η_a / η_s follow digitized E-14/E-15 shapes (measured, not calc η=0.15 cap). Superseded by the App. A chain (16a) and Eqs. (77), (79)–(83) (16b).

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

## 5. Step 19i — H3 follow-up *(done 2026-10-21; full record in §11 with phase 19)*

Moved to §11. Summary: base H1–H3 = 82.73, 75.73, 77.05 dB (= 18b-r); H3 top modes 15, 25, 17, 21; omitted D-1 terms with |δ| ≤ 0.057 **not found** as the cause of the H3 miss (`docs/validation_reports/h3_followup.md`). Phase 33 carries H3 as a stated limitation.

---

## 6–8. Source phases 21–28, aircraft-cabin phases 29–31, phases 32–38 *(all done; moved to the bottom of this file, after §11, on 2026-10-22; section numbers kept)*

---

## 8b. Block validation program: phases 39–44 *(done 2026-10-23; 44f done 2026-10-23; moved to the bottom of this file on 2026-10-23; section number kept)*

## 8c. Phase 45 *(done 2026-10-23; moved to the bottom of this file on 2026-10-23; section number kept)*

## 8d–8h. Phases 46–61 *(all done or closed 2026-10-23; moved to the bottom of this file on 2026-10-23; section numbers kept)*

## 8i. Phases 62–65 *(done 2026-10-23/24; moved to the bottom of this file on 2026-10-24; section number kept)*

## 8j. Phase 66 *(done 2026-10-24; moved to the bottom of this file on 2026-10-24; section number kept)*

## 8k. Phase 67 *(done 2026-10-24; moved to the bottom of this file on 2026-10-24; section number kept)*

## 8m–8p. Phases 69–72 *(done 2026-10-28; moved to the bottom of this file on 2026-10-28; section numbers kept)*

## 8q. Phase 73 *(done 2026-10-28; moved to the bottom of this file on 2026-10-28; section number kept)*

## 8x. Phase 80 *(done 2026-10-29; moved to the bottom of this file on 2026-10-29; section number kept)*

## 8y. Phase 81 *(done 2026-10-29; moved to the bottom of this file on 2026-10-29; section number kept)*

## 8z. Phase 82 *(done 2026-10-29; moved to the bottom of this file on 2026-10-29; section number kept)*

## 8aa. Phase 83 *(done 2026-10-29; moved to the bottom of this file on 2026-10-29; section number kept)*

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
7. ~~Faster test cycle (testset filter + DaemonMode)~~ → **P1 done 2026-10-22** (§11)

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

## 11. Completed phases 0–22 + 2026-10-21 close-out + phases 32–35 + task P1 (reference)

No action needed for closed phases. Kept for the record; the planned work is in §§5–8.

## Phase 0–3 — Done

CYL2D report: `docs/validation_reports/cyl2d_table_c1.md` (12/12 PASS ≤5%). Superseded by 15a: the reference values for modes 3 and 19 were mistyped, and only frequencies were checked.

---

## Phase 4 — MRP / MRPMOD *(done)*

**Done**
- [x] Full Table D-1 seed (32 modes) — still available via `structural_modes_from_table_d1`
- [x] Coupled App.D Ritz: Donnell shell + Kirchhoff floor + junction springs + D-1 shape Rayleigh seeds
- [x] Hybrid production `structural_modes(; hybrid=true)` — D-1 freqs/Mr + Ritz shapes → **32/32 ≤5%** (a self-match on the D-1 frequencies, not a test of the solver)
- [x] 2026-10-20: all 32 Table D-1 shapes transcribed from the page scans; modes 2 (208.24 Hz) and 16 (558.43 Hz) corrected; shape and mass comparison is 17d
- [x] Raw Ritz spectral coverage (greedy match) **30/32** ≤5% — `mrp_ritz_vs_d1.md`
- [x] `fit_mrp_to_table_d1` / `match_ritz_to_table_d1` helpers

**Honest limit:** Full Peterson off-diagonal Fourier matrices from App. D OCR remain research-sized; hybrid 32/32 + raw 30/32 spectral coverage is the educated V-CODE closure (remaining raw misses: D-1 #2 ≈208 Hz, #9 ≈347 Hz).

---

## Phase 5 — PAIN core *(done)*

- [x] Ψ_G, f', resonance factor (surrogate of Eqs. 8/16; f' now Eq. 52, 2026-10-20; the rest superseded by 17a)
- [x] Per-harmonic T(ω_H) and η_a(f), η_s(f) (superseded by 16a, 16b)
- [x] Eq.(19)→(23) HF broadband with α, n(ω), ⟨j²⟩_rev (τ_t in 17b; the rest 30b)
- [x] T1/T2 PASS on E-11 path (void: grid azimuth was wrong until 12b; on the corrected grid T1 H2/H3 fail, T2 passes; re-run 18a)

---

## Phase 6 — CCBlade → F1A *(done — X-EXTRAP)*

- [x] Hartzell JSON; `r_p=0.965`; `asound=c0`; AA `(x3,x1,x2)`; DC FFT
- [x] Loading-only default (`thickness_over_chord=0`)
- [x] Optional Table-8 peak calibration → smoke Δ≈0 dB
- [x] Uncalibrated residual historically ~+5/+9/+14 dB (documented)

---

## Phase 7 — E-11 + T1/T2 *(done)*

- [x] Dual E-11 digitization δ_dig ≤ 1 dB
- [x] T1 PASS H=1..3 vs E-16 (void, misplaced grid; corrected grid 2026-10-20: H1 pass, H2/H3 fail, stale calibration; re-run 18a)
- [x] T2 PASS 1.25–2 kHz vs E-9 (void, misplaced grid; corrected grid: still passes, stale calibration; re-run 18a)
- [x] Figs E-9/E-10 end ~2 kHz — no V-EXP gate above 2 kHz (documented)

---

## Phase 8 — Trim & loss *(done)*

- [x] App.E Phase-III stack masses (fiberglass 9.61 kg/m³, 5.1 cm, septum)
- [x] η_a from E-14 architecture (measured-level peaks, not calc 0.25@300 Hz) (superseded by Eq. 77, 16b)
- [x] η_s from E-15 measured trend (not 0.15 upper-limit cap) (superseded by Eqs. 79–83, 16b)
- [x] `absorption_coefficient` for Eq.19 α
- [x] Digitized target CSVs `data/cr3813/e14_*.csv`, `e15_*.csv` + tests

---

## Phase 9 — Metrics *(done)*

- [x] `overall_dBA` ±3.5 dB; SIL from 1/3-oct

---

## Phase 10 — Packaging *(done)*

- [x] CLAIMS (now `METHODOLOGY.md`) + README + this plan
- [x] Validation reports + drivers (`run_pain`, `run_f1a_smoke`, `mrp_ritz_vs_d1`)
- [x] `Pkg.test()` green including T1/T2/MRP/trim gates (as of 2026-10-19; re-run in 12a after the 2026-10-20 coupling change: no longer green, see Phase 12)

---

## Phase 11 — XFOIL polars and Viterna extension: specification *(done 2026-10-20)*

All steps 11a–11e are done; results and deviations are in the completed section at the end of this file ("Phase 11 — Done"). Why first: phases 25c, 26, 27 and 28 call `af(α, Re, M)` and need real polars (the present default is a clamped linear polar), and every later numerical phase depends on them. This phase generates and records the polars; it does not change Julia code (phase 25c wires them in).

| Step | What | Done when |
|------|------|-----------|
| 11a | Report 996 gap fill: run XFOIL at Re = 3×10⁵ and M = 0.1 for the 10 NACA 16-series stations (forced transition x_tr = 0.02) and merge into the `polars_forced.json` grid | New entries in the existing format; non-converged points listed |
| 11b | Pereira NACA 4412 sets: Re 2×10⁴–2×10⁵ (3×10⁵ edge), M 0–0.4, α −10° to +20°; primary N_crit = 9, brackets N_crit = 5 and forced x_tr = 0.05 | One file per transition setting, each with a provenance header |
| 11c | Viterna-type post-stall extension to ±180° (CCBlade helper; confirm in the pinned 1.0.0 docs) for both propellers; Re and M clamp rule | α_stall, the c_d,max rule, interpolated points and clamp counts recorded |
| 11d | Save files: Pereira `data\pereira\naca4412_xfoil_<transition>.json`; Report 996 merged grid next to `polars_forced.json`. Header: XFOIL version, panels, N_crit or x_tr, Re/M/α grids, non-converged list, extension parameters, date, script | Files present with complete headers |
| 11e | Enter every setting in the `VALIDATION_GUIDELINE.md` §2.10 register **before any comparison** (N_crit, x_tr, α, Re/M grids, α_stall, c_d,max, Viterna parameters) | Register rows written; any later change makes the result calibrated with the parameter named |

Details of the Pereira specification: [Pereira NACA 4412 polar specification](#pereira-naca-4412-polar-specification); how the Report 996 polars are used: phase 25c.

### XFOIL settings and session

Only two propellers need polars. BBN/Wilby needs none (kinematic check: D, B, rpm, microphone positions). All settings below are chosen **before** any comparison and entered in the §2.10 parameter register of `VALIDATION_GUIDELINE.md`; change one afterwards and the result is reported as calibrated with the parameter named. Recompute the Re and M ranges from the chord table and W before running; the values here are the plan's estimates.

| | Pereira (NACA 4412) | Report 996 (NACA 16-series, 10 stations) |
|---|---|---|
| Status | Not generated yet | Forced-transition set exists (`polars_forced.json`); fill the gaps only |
| Section | NACA 4412, re-paneled to about 160–200 points | Stations in `plots\section_coordinates.csv` |
| Reynolds | 2×10⁴, 3×10⁴, 5×10⁴, 7.5×10⁴, 1×10⁵, 1.5×10⁵, 2×10⁵; 3×10⁵ as a sensitivity edge | Existing 0.5, 1, 2, 4 ×10⁶; **add 3×10⁵** (inboard stations need about 3×10⁵) |
| Mach | 0, 0.1, 0.2, 0.3, 0.4 | Existing 0.2, 0.4, 0.55, 0.65, 0.72; **add 0.1** (blade needs M down to about 0.12) |
| Angle of attack | −10° to +20°, 0.5° steps (0.25° near stall), run up and down from 0° and merge | Existing −6° to +14°; do not extend with XFOIL beyond where it converges. Use Viterna beyond the last converged point |
| Transition | Primary N_crit = 9 (free). Brackets: N_crit = 5; forced x_tr = 0.05 upper and lower | Forced x_tr = 0.02 (matches the primary set); free transition only for the optional third set |
| Iterations | `ITER 200`; log every non-converged point | Same |
| Output | c_l, c_d (c_m optional) vs α for each (Re, M), one file per transition setting | Merge into the existing grid, same format as `polars_forced.json` |

Per (Re, M) point, the XFOIL session looks like this (confirm the command names against the installed XFOIL version before scripting; the sweep is run in two directions because XFOIL converges best marching away from α = 0):

```
NACA 4412
PANE
OPER
VISC 5e4
MACH 0.2
VPAR
N 9

ITER 200
PACC
pol_Re5e4_M0.2_up.txt

ASEQ 0 20 0.5
PACC
INIT
ALFA 0
PACC
pol_Re5e4_M0.2_down.txt

ASEQ 0 -10 0.5
PACC

QUIT
```

For the forced-transition runs, replace the `N 9` line with `XTR 0.05 0.05` (Pereira) or `XTR 0.02 0.02` (Report 996) inside the `VPAR` menu. Drive it from PowerShell with one input file per case, for example `Get-Content .\xfoil_case.inp | xfoil.exe`, from `rea-work\PAIN.jl`; a loop over Re and M writes the files.

---

## Phase 11 — XFOIL polars and Viterna extension: results *(done 2026-10-20)*

- [x] **11a** Report 996 gap fill. Sibling-repo `polars_forced.json` (`naca_4-5-08-03`, copied to `data/report996/polars_forced_sibling.json`) plus Re = 3×10⁵ and M = 0.1: 100 new (section, Re, M) polars, forced x_tr = 0.02, 240 panels, α −6° to 14° in 0.5° steps. Merged grid: `data/report996/polars_forced_merged.json` (6 Re × 6 M × 10 sections = 300 polars; format of `polars_forced.json` plus a `header`). Section coordinates regenerated with the sibling repo's own code (`data/report996/xfoil_sections/*.dat`; keys match the old set).
- [x] **11b** Pereira NACA 4412: Re 2×10⁴–3×10⁵ (8 values), M 0–0.4 (5 values), α −10° to 20° (0.5° steps, 0.25° from 10°), 180 panels. Three files: `data/pereira/naca4412_xfoil_ncrit9.json` (primary), `_ncrit5.json`, `_xtr005.json` (forced x_tr = 0.05).
- [x] **11c** Viterna extension recorded in `data/polars/viterna_extension.json` (`PAIN.jl/scripts/run/viterna_extension.jl`, CCBlade 1.0.0 `viterna`, 50 points per side, c_d,max = max(max converged c_d, 1.11 + 0.018/cr75); cr75 = 0.1251 Report 996, 0.1558 Pereira). Clamp rule: evaluation (Re, M) clamped to the set's grid range, bilinear in (log Re, M) inside.
- [x] **11d** Files present with provenance headers (XFOIL version, panels, N_crit or x_tr, grids, non-converged list, date, script). Generator: `data/polars/xfoil_polars.py`; run logs `data/polars/run_*.log`.
- [x] **11e** Register rows written in `VALIDATION_GUIDELINE.md` §2.10 before any comparison.

**Results.**

| Set | Polars | Extended | Not extended | c_l still rising at last converged α | Polars with missing α points |
|-----|-------:|---------:|--------------|------------------:|-----------------:|
| Report 996 merged | 300 | 235 | 19 with < 3 points, 46 non-finite from `viterna` (converged range stops at α ≤ 0°) | 143 | 65 of the 100 new entries; 6 inherited entries still empty |
| Pereira N_crit 9 | 40 | 40 | none | 12 (Re 2–3×10⁴, some at 5×10⁴) | 35 |
| Pereira N_crit 5 | 40 | 40 | none | 7 | 22 |
| Pereira x_tr 0.05 | 40 | 40 | none | 10 | 15 |

α_stall (α at max c_l of the converged points): Report 996 median 7.5° (range 0.5–14°), Pereira N_crit 9 median 15.0° (8.5–20°). c_l,max medians 0.94 (Report 996) and 1.37 (Pereira N_crit 9). Full lists of non-converged points are in each file's header.

**Deviations and cautions.**
- XFOIL is the stock Windows 6.99 build (single precision); the sibling set came from a Linux double-precision build. Overlapping points were not re-run, so the merged grid mixes the two builds. Stall onset and post-stall XFOIL values depend on the build; entered in §2.10.
- XFOIL hangs past stall on thin sections; those sweeps were stopped at 60 s and the points printed before the stop were kept. The converged α range therefore ends before stall on many polars (the "still rising" column). For those, α_stall in the Viterna rule is the last converged point, not a true stall, and the Viterna blend starts earlier than the physical stall.
- Pereira Re = 2×10⁴–3×10⁴ polars do not stall within α ≤ 20°. Phase 25c/27 must decide how those are used (nearest usable polar, counted).
- Polars that `viterna` cannot extend (46 plus 19 under-populated) are replaced by the nearest usable (Re, M) polar of the same section; count them with each run. The tip section n16_101 has no usable polar at Re ≥ 10⁶ for most M.
- The Report 996 sections come from the sibling repo's `normal_section` and NACA 16-series generator, not from Report 996 coordinates.

---

## Phase 12 — Test run and grid azimuth fix *(done 2026-10-20)*

- [x] **12a** `Pkg.test()` run on the code as it stood before the fix (a copy with the original geometry; the full file was run inside an outer testset so a first failure does not hide later tests): **169 pass, 2 fail**. Failures recorded, not tuned away: (1) `CYL2D normalization Eq.(C.10)/(C.11)`, rigid-body ε_n = 1.0614 against 1 ± 0.05 on the 31×31 Cartesian grid (closed by the App. C solver, 15a); (2) the `E-11 pipeline + T1 gate`, all three harmonics FAIL on the misplaced grid (H1 70.4, H2 50.2, H3 45.1 dB). The Eq. (52) coupling tests, the Table D-1 shape tests and the Ritz convention tests pass.
- [x] **12b** Grid azimuth fix. `grid_points` (`src/geometry.jl`) now places line ℓ = 1 at the propeller azimuth, θ_ℓ = φ_p + (ℓ−1)π/18 (upper quarter, ℓ increasing upward), and returns `alpha_deg` = (ℓ−1)·10° in each point. `extend_line_to_grid` (`src/grid_extension.jl`) and the synthetic grid (`src/propeller_ccblade.jl`) use `alpha_deg` (= θ − φ_p) for the cosine falloff. `incidence_angle_deg` now measures γ from the surface→hub direction against the outward normal: with the hub outside the skin and ℓ = 1 at φ_p, the old hub→surface vector would have given 180° instead of 0°. New test `Grid azimuth` (φ_p = 60°, 90°, 120°): θ_ℓ = φ_p + 10°(ℓ−1), α = θ − φ_p, γ = 0 at ℓ = 1, k = k_p, γ increasing with ℓ and with |k − k_p|.
- [x] **Result after the fix** (`Pkg.test()` 1141 pass, 2 fail; the same two failures as 12a). T1 on the corrected grid: H1 78.0 dB (PASS, within NASA ± 4 dB), H2 54.4 dB (FAIL), H3 52.5 dB (FAIL). T2 passes at 1.25, 1.6 and 2 kHz (51.0, 47.7, 44.5 dB). The trim and loss surrogate was fitted under the old coupling and grid, so T1 H2/H3 are not retuned; they are re-graded in 18a. Reports regenerated (`t1_tonal.md`, `t2_third_octave.md`, `pipeline_smoke.md`, `blocking_p68.md`, `mrp_table_d1.md`).
- [x] Docs updated (CLAUDE.md): `README.md` status rows, `flowchart.md` blocker note and diagram labels, `METHODOLOGY.md` T1 claim and claim register, `VALIDATION_GUIDELINE.md` §2.2.1 geometry gate and §2.7/§2.8 rows.

---

## Phase 13 — Cabin pre-registration: assumption register and pass criteria *(done 2026-10-20)*

- [x] **13a** Assumption register for 15a–17a (a–k: CYL2D node rule, NY rule for singular B_E, c0, axial truncation, insulation range and extrapolation, Phase III values CR-3813 does not give, bare η_n and C, areas, η_r'' application, plate modal density, Table D-1 transcription), each with default, range, source and bounding check. Copied to `VALIDATION_GUIDELINE.md` §2.11.1; sensitivity runs are recorded as 14–18 run and feed phase 31.
- [x] **13b** Pass criteria for loss and trim comparisons, dated before any run (§2.11.2): V-CODE η_n vs Fig. E-14 calculated within ±25 % per one-third octave, ᾱ vs Fig. E-13 calculated within ±0.05; V-EXP against measured E-13/E-14/E-15 recorded with no pass mark. The surrogate E-14/E-15 tests are removed when 16a–16b land.
- No code changed. The E-12 (14a) and CYL2D (15a) criteria stay in their own plan rows, dated with this phase.

---

## Phase 14 — Fig. E-12 blocking check *(done 2026-10-20)*

- [x] **14a** Fig. E-12 (CR-3813 p. E-20, PDF page 136; H = 1–3, predicted and measured, line ℓ = 1) digitized twice: pass A by pixel calibration, pass B from a 0.1 X3/D × 2 dB grid overlay (files `data/cr3813/e12/e12_{predicted,measured}_{A,B}.csv`, helpers `data/digitizers/e12_*.py`, overlay `data/cr3813/e12/qa_overlay_A.png`). Both passes are by eye by the same reader, so δ_dig is a lower bound on the reading error. Check script `PAIN.jl/scripts/run/e12_blocking.jl` writes `docs/validation_reports/e12_blocking.md`.
- Result 2026-10-20 (`e12_blocking.md`): digitization δ_dig 2.91 dB on the predicted curves (the 1.0 dB gate is not met; largest at the merged start of the H2 predicted curve), so the tolerance is 3.41 dB; Eq. (43) on ANOPP Table 8 (R1) reproduces the predicted E-12 curve at 29 of 31 points, **FAIL** at H3 aft of the plane (X3/D = −0.233 and −0.349, +4.3 and +3.8 dB, where the H3 predicted curve has few vertices); recorded, not tuned. Against the measured circles the prediction is 1–7 dB high (mean about +5 dB; NASA reports 0–5 dB near the plane).
- Input choice: the free-field input is ANOPP Table 8 (NASA's predicted free field), not the measured E-11 line; the measured E-11 line is used only for the V-EXP row. R1 (full Eq. 43) is the variant NASA's predicted curve used.
- Not done: no `Pkg.test()` test was added (the check is a script and a report); the H2 measured marker at X3/D = 0.69 was read in pass A only.
- No Julia source under `src/` changed.

---

## Phase 15 — CYL2D exactly as App. C, and three-dimensional cabin modes *(done 2026-10-20)*

Approved by the author's request to run the next phase (2026-10-20); rule 13a(b) applied as written. Code: `src/cyl2d.jl` (rewritten), `src/pain_core.jl` (coupling reads the stored segment limits), `src/PAIN.jl` (call and exports), `scripts/run/write_cyl2d_report.jl`, `scripts/checks/probe_q_convergence.jl` (new), `test/runtests.jl`, `test/fig_c3_values.jl` (new).

- [x] **15a** CYL2D exactly as App. C. Half-cabin grid (X ≥ 0), floor on a grid line, NY = 10 intervals, h = (1 + cosθ0)/NY; node in the cabin when r ≤ 1 + 0.4h; Eq. (C.1) at every cabin node; Eq. (C.2) at every boundary node with θ_mn set to 0 below θ0; the two missing equations from a zero tangential gradient at the two-exterior-neighbour boundary points closest to π/4 and 3π/4 (the floor-edge corner and the point near 135°); Eqs. (C.3)–(C.6); symmetric and antisymmetric modes solved separately (antisymmetric centerline nodes eliminated, their boundary points kept with φ = 0), merged, ranked, first 20 kept; Φ_G Eq. (C.10); ε_n Eq. (C.11); boundary values at the boundary nodes at their own angles, mirrored to X < 0, segment limits halfway between neighbours with the ends at θ0, 2π − θ0 and ±sinθ0. A singular B_E (cond > 1e12), a boundary/exterior count other than 2, or complex eigenvalues (|Im| ≥ 1e-3) raises an error naming the grid. The eigenvector sign convention is "largest |φ| positive".
  - **Result** (criteria fixed before the run): all 20 frequencies within 0.001 % (largest 0.0002 %) and Φ_G within 0.002 % of Table C-1 at c0 = 341 m/s; all 20 symmetry types equal; Fig. C-3 modes 0–5 equal to the printed one-decimal values at every node (global sign free) and the row counts 3, 5, 6, 6, 7, 7, 7, 7, 7, 7, 6 reproduced. `cyl2d_table_c1.md`: 61/61 PASS.
  - **Reference corrections:** Table C-1 mode 3 is 175.889 Hz and mode 19 447.887 Hz; mode 5's generalized mass is 0.49815 on the page scan (OCR had 0.49515), mode 6 0.54585.
  - **Register results (13a):** (a) the node window that reproduces the Fig. C-3 row counts and the modes is 0.32h–0.47h (the plan's 0.31h gives a 4-node second row; 0.48h a 7-node fourth row, and both fail the real-spectrum check); (b) for θ0 = 56.6° the valid NY among 8–14 are 8, 10, 11, so NY = 10 is the paper's grid and the rest have complex eigenvalues; θ0 = 90° has a singular B_E at every NY tried, θ0 = 40° and 70° had at most one valid NY in 8–14, so the 1 % next-valid-NY rule (`cyl2d_modes_search`) can fail and then names the grid; NY = 8 against 10 differs by more than 1 % (tested).
  - **Tests:** 97 checks for Table C-1 and Fig. C-3, singular/non-real grids, the node window and boundary data; the rigid-body ε_n 1.0065 equals A_cab/Φ_G. The old Cartesian normalization failure of 12a is closed. Whole file run inside an outer testset (as in 12a): **1242 pass, 1 fail**, the T1 gate (H2, H3), as before; `Pkg.test()` itself stops at that failure.
  - **Effect on T1/T2:** with 20 App. C modes the stale surrogate gives T1 H1 80.3 dB (PASS), H2 54.5 dB, H3 51.5 dB (FAIL; 78.0, 54.4, 52.5 dB before); T2 still passes (51.0, 47.7, 44.5 dB). Not retuned; re-graded in 18a.
- [x] **15b** Three-dimensional cabin modes. `cabin_frequency_3d` (Eq. C.7/C.12), `cabin_eps_3d`, `axial_truncation` (q_max = ⌈2ω_H L/(π c0)⌉, V-ASSUMED), `cabin_modes_3d`; f_qM of Eq. (57) was already in `coupling_factor(...; q)`. ε_n for q > 0 is twice the q = 0 value (∫cos² dz = L/2); CR-3813's "ε_q = 2 for q = 0, 1 for q > 0" is not legible with Eq. (C.11) in the scan, so this is an interpretation (V-ASSUMED) to be settled in 17a. Convergence in q (`scripts/checks/probe_q_convergence.jl`, `q_convergence.md`): on the present surrogate sum q_max = 5, 9, 13 at H1–H3, q_max + 2 changes the level by ≤ 0.001 dB (rule met); the q > 0 modes add 1.2, 3.3 and 2.6 dB over q = 0 at H1–H3. The surrogate is replaced by Eq. (8) in 17a, where the probe is re-run.
- [x] Docs updated (CLAUDE.md): `README.md` status rows, `flowchart.md` CYL2D and coupling nodes, `METHODOLOGY.md` §4 and claim register, `VALIDATION_GUIDELINE.md` §2.6, the validation table and register rows a and d.

---

## Phase 16 — App. A trim and §3.8 loss factors *(done 2026-10-20)*

Approved by the author's request to run the next phase (2026-10-20). Code: `src/trim_loss.jl` (new section below the earlier surrogates, which stay until 17a), `src/PAIN.jl` (exports), `test/runtests.jl`, `scripts/run/run_trim_loss_check.jl` (new). Data: `data/cr3813/fig_a2_pf105.csv`, `data/cr3813/e14_acoustic_loss_calculated.csv`, `data/cr3813/e13_absorption_targets.csv` (new, digitized 2026-10-20, provenance in the file headers). Report: `docs/validation_reports/trim_loss_e13_e14_e15.md`. The statistic and pass rule of the comparison were written down in `VALIDATION_GUIDELINE.md` §2.11.3 before the script was first run. Nothing was tuned.

- [x] **16a** App. A trim. Insulation matrix Eq. (A.10), limp mass Eq. (A.11), cascade skin side first Eq. (A.12); τ_t = |a11|⁻² + τ_t^m (A.22); C_w (A.8); β and ξ = Re β (A.16, A.17), with `m_wall = Inf` for a rigid backing; mechanical path (A.19)–(A.21) from point connections and lines. Fig. A-2 (PF-105) digitized at its six marked frequencies (100, 315, 630, 1000, 2500, 6300 Hz); interpolation linear in log f of log λ, log α, log |W| and φ; outside 100–6300 Hz an error unless `allow_extrapolation = true`, then flagged. Phase III stacks (`phase3_trim`): four 1.3 cm layers each with a 0.095 kg/m² facing (0.22 − 0.013 × 9.61) plus the septum (6.58 kg over 2a(π − θ0)L = 3.945 m², 1.668 kg/m²); end plates one layer plus facing. The wave impedance is taken as W = |W|e^{+iφ} with time factor e^{−iωt}; Re β ≥ 0 over 100–6300 Hz for the sidewall and end stacks (tested). V-ASSUMED values (register f): facing/septum loss factor 0.05 (0.5 and 1.0 for the NASA reproduction), facing on the cabin side, G-10 wavespeed 3200 m/s, 9 point connections plus 2 floor-edge lines, plate modal densities (j), end plates on a rigid backing.
  - **Tests (227):** empty stack gives identity, τ = 1, C_w = 0; limp mass alone gives a11 = 1 and τ = 1; zero thickness gives the identity; det = 1 for each element and the cascade; the insulation-plus-mass a11 equals Eq. (A.14) written out; Fig. A-2 knots reproduced to 1e-12; out-of-range error and flagged extrapolation; Phase III masses; τ_t^m vanishes with no connections.
  - **Result for the Phase III stack:** the insulation path |a11|⁻² exceeds 1 at 100–200 Hz (trim resonance; τ_t including the mechanical path 2.05, 3.19, 5.33, 2.58 at 100, 125, 160, 200 Hz at trim loss 0.5) and falls to 0.69 at 250 Hz; above about 800 Hz τ_t is set by the mechanical path (0.011 at 1 kHz, 0.0028 at 5 kHz), so the high-frequency trim transmission rests on V-ASSUMED inputs.
- [x] **16b** Loss factors. Si and Cin by power series below 4 and the Lentz continued fraction above, to machine precision (Si(1), Si(10), Si(π), Cin(1), Cin(10) match reference values to 1e-13 or better); joint acceptances Eqs. (63)–(73), with I₃ in the form (n − ka) sinc²(n − ka)/(2(n + ka)) (identical, finite at ka = n) and the axial factor as the ring formulas with n = M/2, ka → kL/2π; η_n Eq. (77) in the form N = η_nω_n² that stays finite at ω_n = 0 (η_n = Inf there); Eq. (78); ᾱ from Eq. (24); η_r = C/f_r + η_r^rad (79)–(81); η_r' Eq. (82), an error if the radicand is not positive; η_r'' Eq. (83) in the finite form N/[(ω_n² − ω_r²)² + N²].
  - **Tests (110):** reference values; joint acceptances against direct quadrature (ring n = 0–4, axial M = 1–3); I₃ form; η_n linear in ξ, ξ_e and zero without them; finite at the rigid-body mode; Eq. (83) printed form, resonance peak and ω_n = 0; Eq. (82) limits; Eqs. (78) and (24) closed forms. The earlier E-14/E-15 surrogate tests were removed (13b).
  - **Findings on the printed equations (recorded, not changed):** (1) For n > 0 the printed Eqs. (69)–(70) are half the joint acceptance normalized by the mode's mean square (quadrature: j²ψ = 2(I₂+I₃−I₁), j²φ = 2(I₁+I₂+I₃)), while Eq. (65) for n = 0 is the full value, so the printed set is not continuous in n; the axial Eq. (63) is half in the same way. The code defaults to the printed text and has `mode_normalized = true`. (2) I₁ is printed as 1/(4πnk(2πa)); the value 1/(8π² n ka) is the one the quadrature confirms. (3) The Eq. (82) radicand equals (Re C_w/(mω_r²))² + (Im C_w/(mω_r²) − η_r)², so a limp mass alone (μ = m_t/m, loss η_t) gives η_r'² = μ² + (η_r + μη_t)², not the loaded-mass result (η_r + μη_t)/(1 + μ); a decision for the author in 17a. (4) The text under Eq. (A.20) calls h_t a mass per unit area; the code uses h_t as a thickness (Z = m h c). (5) Fig. E-13 holds measured points only, so the ᾱ criterion of 13b (±0.05 against a calculated curve) has no target; recorded in §2.11.3. (6) ᾱ from Eq. (24) is above 1 at some bands (1.26 at 250 Hz, 1.57 at 1.25 kHz at trim loss 0.5) because Eq. (78) is 8ξ-based.
  - **E-14 reproduction (V-CODE, ±25 % per band, 18 bands 100–5000 Hz):** **7 of 18 bands pass at trim loss 0.5 and at 1.0; the criterion is not met.** Pass at 0.5: 125, 160, 250, 315, 400, 500, 630 Hz; at 1.0: 125, 160, 250, 315, 400, 500, 1250 Hz. Fail: 100 and 200 Hz (computed 1.7 to 2.3 times NASA), 800–1250 Hz at 0.5 and 630–1000 Hz at 1.0 (1.4 to 1.9 times) and 1600–5000 Hz (0.4 to 0.7 times). The curve shape (peak at 250 Hz for 0.5, a second hump near 1.25 kHz, fall-off above) is reproduced; the 800–1250 Hz excess and the high-frequency deficit follow the end-plate conductance ξ_e, which depends on the unstated end-plate backing (rigid assumed) and on the unstated detail of the 1.3 cm layer. The mean of Eq. (77) over the cabin modes in a band agrees with Eq. (78) within 6 % from 800 Hz up (diagnostic). Against the measured E-14 and E-13 points: recorded, no pass mark.
  - **E-15:** η_r' of Eq. (82) for the 32 Table D-1 modes is 0.2 to 1.4 below 350 Hz and 0.07 to 0.12 above 430 Hz at trim loss 0.5 (0.2 to 0.9 and 0.09 to 0.13 at 1.0); the measured E-15 mid-envelope is 0.06 to 0.10. NASA also reports predictions an order of magnitude above the single measurement below 400 Hz (CR-3813 p. E-24). Recorded, no pass mark.
  - **Effect on the pipeline:** none yet. `run_pain_pipeline` and `pain_core.jl` still call the earlier surrogates until 17a; T1 H2 and H3 are unchanged and still fail (their regrade is 18a). `Pkg.test()` stops at the T1 gate, so the new testsets were run on their own (all pass).
- [x] Docs updated (CLAUDE.md): `README.md`, `flowchart.md`, `METHODOLOGY.md`, `VALIDATION_GUIDELINE.md` §2.11.3, the validation table and register rows e, f, g, j.

---

## Phase 17 — Tone pressure Eq. (8) and PAIN-core verification *(done 2026-10-20)*

Approved by the author's request to run the next phase (2026-10-20). Code: `src/pain_core.jl`, `src/PAIN.jl`, `src/trim_loss.jl`, `src/gui_model.jl`, `gui/main.qml`; tests, scripts and the report `docs/validation_reports/pain_core_eq8_phase17.md` (trace table, results, sensitivity). `Pkg.test()` passes.

- [x] **17a** Tone pressure, Eqs. (8) and (3). `tone_mean_square_pressure` sums ⟨p²⟩_H over n = (q, i), q = 0…q_max, and over the 32 structural modes: (c0/V)²(ρ0c0A)²ω_H⁴ ε_n f̄'²Ψ_G/(M_r² D_n D_r), D_n = (ω_n² − ω_H²)² + N², D_r = (ω_r² − ω_H²)² + ((η_r' + η_r'')ω_r²)², so the rigid-body cabin mode is the finite ω_n → 0 limit. Ψ_G is Eq. (42) with Δ⁴/2 (`generalized_force`; the old amplitude is `generalized_force_amplitude`). τ_t of Eq. (A.22) at ω_H enters only inside f̄' (the T⁴ double count found on 2026-10-20 is gone). η_n from Eq. (77) with ξ, ξ_e at ω_H (bare: `η_n_bare` ω_n²), η_r' from Eqs. (79)–(82) at ω_r, η_r'' from Eq. (83) for every pair. `TrimPanel`, `trim_T_fc`, `acoustic_loss_factor`, `structural_loss_factor` and `resonance_factor` are removed. `PainInputs`: trim stacks, `m_wall`, `η_n_bare`, `C_struc`, `q_max`, `allow_extrapolation`. `run_pain_pipeline`: `trim` (`:auto` = Phase III stacks for e11, bare otherwise), custom stacks, `NY`.
- [x] **17b** Broadband uses τ_t of Eq. (A.22) in place of T²; α(f), χ, `bb_j2_scale` and the H = 3 anchor stay surrogates (30b). Bands above the 6.3 kHz limit of Fig. A-2 are left out unless `allow_extrapolation=true` (X-EXTRAP).
- [x] **17e** Ψ_G analytic limits (11 checks): uniform closed form, cancellation of two points π apart, global phase invariance, Eq. (42) = double sum (41), amplitude ×2 gives Ψ_G ×4 (the plan's "doubling A doubles Ψ_G" holds for the force amplitude √(2Ψ_G)), antisymmetric against symmetric gives 0, Δ = πa/18 on the grid, axial sum against its integral.
- [x] **17f** Coupling (tests passed earlier); |f'| > 1 errors in the runs of this phase: **0**.
- [x] **17g** Resonance form: peak value, half-power width η·ω0, finite ω_n → 0 limit; a cabin of the rigid-body mode alone gives a finite p².
- [x] **17h (independent re-implementation)** Direct form of Eq. (8) with f̄' by quadrature and Ψ_G by the double sum agrees with the code to 2e-3 on a bare cabin. **Not done:** the W_in = W_diss conservation check with coupled resonators (the relation between Eqs. (7) and (8) was not derived); carried to phase 19a (was 32h).
- [x] **17i** Scaling laws: p² ∝ amplitude², zero amplitude and f̄' = 0 give 0, phase shift invariance, cabin shape scaling invariant (with and without trim), structural shape scaling invariant for f̄'²Ψ_G/M_r² and η_r''. **Finding:** η_r of Eqs. (79)–(81) uses C_Mn² unnormalized, so the full p² is not invariant under a shape scaling.
- [x] **17j** No reference output exists in CR-172425 (§5.4.3 lists printed quantities only; §6 is control cards and input) or in the extracted text of CR-172428 beyond Table 8 (ℓ = 1) and Table D-1; 18b is conditional on GEXT on Table 8.
- **Result, recorded not tuned** (e11, R2, Phase III trim): T1 H1 90.24 dB, H2 79.30 dB (both within 4 dB of the measured mean), H3 83.15 dB (FAIL, +18.2 dB); T2 62.25, 60.34, 58.48 dB at 1.25, 1.6, 2 kHz (FAIL, +11 to +17 dB; the surrogate broadband path with the stale `bb_j2_scale` = 0.5). The q convergence rule (13a d) is met (0.000 dB). Sensitivity over the register ranges: H3 stays at least 13 dB above the mean in every run (the lowest is the bare cabin with η_n = 0.10, 78.7 dB) (report §5). H1 is sensitive to the trim resonance (τ_t = 15.6 at 200 Hz).
- [x] **17c** Equation trace table written (`validation_reports/pain_core_eq8_phase17.md` §1), equation numbers confirmed in the PDF page images (Eqs. 7, 8, 41, 42). After 18 the open questions are unchanged and carried to phase 19 (was 32h): whether NASA mirrors the field to grid points "above and below θ = 0" (CR-172425 §5.4.3 item 7), the (mA/4)²τ_ML identification, ε_n for q > 0. 18b's miss makes them the first places to look.
- [x] **17d** Mode shapes against NASA numbers, using the independent digitization `data/cr3813/digitized_table_D1.csv` (`scripts/checks/check_table_d1_shapes.jl`, criteria fixed before the run: frequency, total mass, C_Mn, M, N equal to 1e-5; shell + plate ≤ total). **Result: all 32 modes equal** (frequency, symmetry, total mass, every C_Mn, M and N, term counts) between the transcription in `mrp.jl` and the digitization. The shell and plate mass columns sum to less than the total (deficit 0.00001–2.78 kg, the total also carries stiffener mass). Exploratory: m_s·∫ψ_s² and m_p·∫ψ_p² do not give a constant area density (shell 3.1–11.9, plate 1.8–4.0 kg/m²; plate median 3.47), consistent with discrete stiffener mass in the shell column; not a criterion. Not done: Fig. D-2 shape of mode 1 and Eqs. (D.22)–(D.26) (the figure and appendix pages were not compared).
- [x] **17k** Baselines frozen in `data/baselines/phase17_baselines.csv` (`scripts/run/freeze_baselines.jl`; 158 values: tone SPL bare and Phase III, Ψ_G of all 32 modes at H1–H3, f' of 6 × 8 mode pairs and its maximum, τ_t at H1–H3, the 1.25–2 kHz bands); `Pkg.test()` compares against them at rtol 1e-6. Renewing the file is a dated decision, for phase 30d.
- [x] Docs updated (CLAUDE.md): `README.md` status rows, `flowchart.md` PAIN-core nodes and diagram labels, `METHODOLOGY.md` §6 sub-functions, T1/T2 text and claim register, `VALIDATION_GUIDELINE.md` §2.7, §2.8, §2.10 parameter register and test list, §2.11 register results.

---

## Phase 18 — Re-run T1 and T2 without tuning, PAIN reproduction check, and regrade *(done 2026-10-20)*

- [x] **18a** T1 and T2 re-run with the 15a–17a chain, criteria unchanged; the tests record instead of assert (done with 17a). Reports regenerated (`t1_tonal.md`, `t2_third_octave.md`, `mrp_table_d1.md`; the T2 records are labelled "V-EXP, calibrated (bb_j2_scale, stale)"). Result: T1 90.24, 79.30, 83.15 dB (means 90.0, 80.0, 65.0; H1, H2 within 4 dB, H3 fails); T2 62.25, 60.34, 58.48 dB (fails). The "V-EXP, calibrated (in-sample)" T1 grade is withdrawn; T1 has no claim; T2 keeps one stale fitted parameter. Hard rule at the top reworded; grades updated in `METHODOLOGY.md`, `VALIDATION_GUIDELINE.md` §2.7/§2.8 and `flowchart.md`.
- [x] **18b** PAIN reproduction check (`scripts/run/run_pain_reproduction.jl`, `validation_reports/pain_reproduction_e16.md`). Criterion dated in `VALIDATION_GUIDELINE.md` §2.11.4 before the run: within 4 dB of NASA's PAIN predictions (79.0, 75.5, 68.0 dB) at each harmonic. Inputs: ANOPP Table 8 free field, R1 blocking, Phase III stacks, GEXT off the ℓ = 1 line (conditional on GEXT, V-ASSUMED). **Result: criterion not met, 0 of 3:** 91.92 (+12.9), 80.01 (+4.5), 84.87 (+16.9) dB. Diagnostics: R2 blocking 90.06 (+11.1), 78.20 (PASS), 83.15 (+15.2); bare cabin R1 92.22, 83.65, 83.58. **Localization** (`scripts/checks/probe_modal_contributions.jl`): at H1 two shell-dominated modes carry 91 % of the sum, mode 8 (318.7 Hz, antisymmetric, 56 %) and mode 6 (301.9 Hz, 35 %), both well above 200 Hz, with τ_t = 15.6 amplifying the shell term; at H2 mode 8 carries 59 %; at H3 the sum is spread over modes 25, 21, 15, 17 (626–649 Hz and 555–561 Hz). Candidate causes, not tested: the τ_t > 1 trim resonance at 200 Hz, the (mA/4)²τ_ML identification, ε_n for q > 0, the grid mirroring question (17c). Not tuned. Because NASA's own predictions are not reproduced, the T1 passes of 18a at H1 and H2 are not evidence for the chain.
- [x] Docs updated (CLAUDE.md): `README.md`, `flowchart.md`, `METHODOLOGY.md`, `VALIDATION_GUIDELINE.md` (§2.7, §2.8, §2.10, new §2.11.4), this file.

---

## Phase 19 — Cabin-chain diagnostics: Eq. (8) derivation and the 18b miss *(done 2026-10-20)*

Why this phase ran here: 18b showed that the chain does not compute what NASA's PAIN computed (+12.9, +4.5, +16.9 dB at H1–H3), and every later cabin result inherits that miss. Criteria as fixed in the phase 19 table before each run (rows reproduced below). Script `scripts/checks/check_two_resonator.py` (Python, sympy + numpy; a new script, no Julia source changed), report `docs/validation_reports/eq8_two_resonator.md`. Source pages read from the PDF images: CR-3813 pp. 9–15 (PDF 19–25), p. 43 (Eq. 83).

| Step | What | Criterion (fixed 2026-10-20, before the run) | Done when |
|------|------|------------------------------------------------|-----------|
| 19a | **Eqs. (5)–(7) → (8) and the power balance.** Derive Eq. (6) from Eq. (4) with the j_r² definition (CR-3813 p. 12), Eq. (7) from Eq. (6) with the tone cospectrum C_pbl(x\|x′)δ(ω − ω_H) (p. 14), and Eq. (8) by equating the n-th terms of Eqs. (5) and (7) (p. 14). Then solve a two-resonator model (one cabin mode n, one structural mode r, harmonic tone, hysteretic loss factors, modal coupling A f′(n,r) both ways) exactly, and compare its wall inflow, its dissipation and its ⟨p_n²⟩_s,t with Eqs. (5), (7), (8) and the η_r'' of Eq. (83). Script `scripts/checks/check_two_resonator.py` (sympy + numpy), report `validation_reports/eq8_two_resonator.md` | (1) Symbolic: Eq. (8) follows from Eqs. (4), (5), j_r², δ(ω − ω_H) with no extra factor. (2) Exact inflow ½Re(A f′ P_n conj(iωQ_r)) = Eq. (5) W_diss to rtol 1e-9 at every frequency of a sweep 0.2–5 ω_n. (3) Weak-coupling limit (back-reaction removed): model ⟨p_n²⟩_s,t = Eq. (8) and inflow = Eq. (7), rtol 1e-9. (4) Full coupling: the added structural loss of the exact solution at ω = ω_r equals Eq. (83), rtol 1e-9; the dB difference between the exact coupled ⟨p_n²⟩ and Eq. (8) with Eq. (83) is recorded against coupling strength, no pass mark. (5) Two structural modes driven by the same tone: the coherent sum against Eq. (8)'s sum over r is recorded, no pass mark | Report written; findings recorded in `METHODOLOGY.md` and `VALIDATION_GUIDELINE.md` §2.7 |
| 19b | **(mA/4)²τ_ML.** Confirm or correct the identification (mA/4)²τ_ML = (ρ0c0A/(2ω_H))² from the 19a derivation, with τ_ML = (2ρc0/(ωm))² as defined on CR-3813 p. 11 | Symbolic identity exact and independent of m; the prefactor of Eq. (6) times ω² reduces to Eq. (4)'s ρc0²A⁴/V after j_r²; the code prefactor (c0/V)²(ρ0c0A)²ω_H⁴ equals (4c0²/V²)(mA/4)²τ_ML ω_H⁶ to rtol 1e-12 | Trace-table row of `pain_core_eq8_phase17.md` updated |
| 19c | **ε_n for q > 0.** Quadrature of the CYL2D mode shapes times cos²(qπx/L) over the cabin volume; compare V/∫φ_n²dV with `cabin_eps_3d`; read Eq. (C.11) and the "ε_q" text in the page image | Quadrature equals `cabin_eps_3d` within 0.5 % for q = 0–3 and the first 10 cross-section modes; the printed text read and quoted. The 18b effect of the alternative reading (ε_q = 1 for q > 0) recorded in dB, not adopted | Result in the report; register row d updated |
| 19d | **Mirroring "above and below θ = 0".** Read User Manual Fig. 2-3, the card-36 note, CR-172425 §5.4.3 item 7 and CR-3813 §3.4; decide whether NASA's Ψ_G uses the 160 stated points or the points mirrored about θ = 0 | Decision quoted from the text; if mirrored, the 18b numbers with a mirrored field are recorded as a diagnostic (a `src/` change for production waits for confirmation) | Decision recorded |
| 19e | **τ_t at 200 Hz.** Recompute τ_t of the Phase III sidewall stack at 100–400 Hz with: `W_PHASE_SIGN` flipped, the Re β ≥ 0 check, facing on the skin side against the cabin side, septum removed; compare with any NASA-printed trim transmission for Phase III | Each variant's τ_t recorded; a variant that makes τ_t ≤ 1 at 200 Hz is a finding, not adopted; if NASA prints a curve, within 3 dB of it | Table in the report |
| 19f | **Bisect the 18b chain.** Rerun 18b, then swap one block at a time for NASA's own quantity: Table C-1 modes (already equal, 15a), Table D-1 modes (equal, 17d), the E-14 calculated η_n (`data/cr3813/e14_acoustic_loss_calculated.csv`), the E-15 η_r, the 19c and 19d alternatives, τ_t = 1 | 18b criterion unchanged (4 dB). A block is implicated when its swap moves a harmonic ≥ 3 dB toward NASA; the shifts are recorded per harmonic | Bisection table; candidate cause named or "not found" recorded |
| 19g | **Fig. D-2 and Eqs. (D.22)–(D.26).** Digitize the Fig. D-2 mode-1 shape and compare with `mrp.jl`; check (D.22)–(D.26) against the code term by term | Shape within 5 % of its peak at the digitized points; each equation matches or the difference is recorded | Result in `mrp_table_d1.md` |
| 19h | **η_r of Eqs. (79)–(81) and C_Mn² normalization (17i).** Decide from Eq. (66) whether j_r^rev uses the mode normalized by M_r | Text quoted; the 18b shift of the normalized form recorded in dB, not adopted without confirmation | Recorded |

- [x] **19a** Result: **all criteria met (11 of 11)**. Derivation: S_pbl j_r² = Ψ_G/A² turns Eq. (4) into Eq. (6), whose prefactor (2π/ρV)(mA/4)²τ_ML(2/π)ω² is exactly ρc0²A²/V; δ(ω − ω_H) gives Eq. (7); the n-th terms of Eqs. (5) and (7) give printed Eq. (8) with no extra factor, and the code's (c0/V)²(ρ0c0A)²ω_H⁴ form equals it. Two-resonator model (hysteretic losses, coupling A f′ both ways, Ψ_G = \|F\|²/2): wall inflow = Eq. (5) W_diss (1.6e-15), weak-coupling ⟨p_n²⟩ = Eq. (8) (1.4e-15) and inflow = Eq. (7) (2.4e-15) over 0.2–5 ω_n; the back-reaction's added loss at ω_r = Eq. (83) (7e-16). This closes the 17h conservation check. **Recorded, no pass mark:** (i) Eq. (8) with Eq. (83) omits the reactive part of the back-reaction; at the test-article coupling (Table D-1 mode 8, f′ = 0.19, cabin mode at 346 Hz) the exact coupled level is +0.13 dB at 200 Hz, −0.9 dB at ω_r, −4.9 dB at ω_n relative to Eq. (8); (ii) Eq. (8) sums the structural modes incoherently; for a tone two modes driven through one cabin mode differ from the incoherent sum by −5.4 to +2.3 dB in the illustrative case. Both are properties of the method that NASA's PAIN shares, so neither explains the 18b miss. (iii) The code passes f̄′ (with τ_t) to Eq. (83), which is printed with f′; carried to 19f.
- [x] **19b** Result: **confirmed.** (mA/4)²τ_ML = (ρ0c0A/(2ω_H))² exactly, with τ_ML = (2ρc0/(ωm))² as defined on p. 11; m cancels, so the identification depends on no mass input. Trace-table row of `pain_core_eq8_phase17.md` updated. With 19a, the Eq. (8) algebra and this factor are ruled out as causes of the 18b miss.
- [x] **19c** Script `scripts/checks/check_eps_n_quadrature.jl` (a new script, no Julia source changed), report `validation_reports/eps_n_quadrature.md`. Printed text read from the page images (CR-3813 pp. C-6, C-7): ∫φ_qi²dv = (L/2) ε_q Σφ_i²(j)h²C(j); "Also ε_q = 2 for q = 0; 1 for q > 0"; Eq. (C.11) ε_n = 2[π − θ0 + cosθ0 sinθ0]/(Φ_G(i) ε_q). So `cabin_eps_3d` (q > 0 = 2 × q = 0) **is Eq. (C.11) as printed**; the V-ASSUMED tag is withdrawn. Result: **criterion not met.** The factor 2 is confirmed by quadrature to 1e-15, but the quadrature (Voronoi cells of the true cabin, r ≤ 1, floor at −cosθ0) differs from `cabin_eps_3d` by 0.65 % (mode 0) to 5.4 % (mode 1) over modes 0–9, identically for every q, against the 0.5 % criterion. The difference is in the q = 0 normalization (the Eq. (C.10) node sum with C(j) weights on a staircase boundary), which is what NASA printed; it is recorded, not corrected, and the quadrature is itself a piecewise-constant estimate, so it does not show which value is closer to the truth. About 0.03–0.2 dB in p² at most per mode, small against the 18b miss. **Alternative reading** ε_n(q > 0) = ε_n(q = 0), applied to every use of `cabin_eps_3d` in the 18b run: H1 91.82 (−0.10), H2 77.98 (−2.02), H3 84.05 (−0.82) dB against NASA 79.0, 75.5, 68.0; 1 of 3 within 4 dB (H2 was already within 4 dB at 80.01); it contradicts the printed ε_q and does not close the miss; not adopted. With 19a and 19b, ε_n for q > 0 is ruled out as the cause of the 18b miss. The docstring of `cabin_eps_3d` (`src/cyl2d.jl`) and the comment in `src/trim_loss.jl` still call the ratio an interpretation; they are corrected in the comment edit of step 33e (no `src/` change before the author confirms).
- [x] **19d** Script `scripts/checks/check_grid_mirroring.jl` (no Julia source changed; the mirrored sum is an override inside the script's process), report `validation_reports/grid_mirroring.md`. Texts read from the page images: User Manual p. 8 ("the grid is defined over one-quarter of the periphery", ℓ = 1, 10, ℓ = 1 at the point of penetration), Fig. 3 (10 × 16 points on one side), card-36 note ("upper quarter of the fuselage skin"), §5.4.3 item 7 (printed output "for all grid points, both above and below θ = 0"), CR-3813 §3.4 p. 27 ("the grid is confined to the side of the fuselage where the propeller is located"). **Decision: the 160 stated points, no mirroring**; the item 7 wording is an output listing, unresolved, and no text reads it as an instruction to mirror the input. Diagnostics (18b inputs, same amplitude and phase at the mirrored point; not adopted): mirrored about θ = 0 → 93.47, 77.88, 88.14 dB (+1.54, −2.12, +3.27); about the ℓ = 1 line → 92.65, 83.19, 91.68 dB (+0.73, +3.18, +6.81); against the unmirrored 91.92, 80.01, 84.87 and NASA 79.0, 75.5, 68.0. Neither closes the miss; mirroring is ruled out as its cause.
- [x] **19e** Script `scripts/checks/check_tau_t_variants.jl` (matrices rebuilt locally, base row equal to `trim_tau` exactly), report `validation_reports/tau_t_variants.md`. τ_t at 200 Hz: base 15.6; `W_PHASE_SIGN` flipped 6.42; facing on the skin side 23.8; septum removed 1.94; **η_lining = 0.5: 2.58; η_lining = 1.0: 0.79 (≤ 1, a finding, not adopted)**. All variants passive (Re β ≥ 0 over 100–6300 Hz). NASA prints no τ_t curve (figure captions of Apps. A and E checked), so the 3 dB comparison has no target. Also found: CR-3813 p. E-24 states that the Phase III predictions used the trim loss factor η_T = 0.5 (and 0.5 and 1.0 for the two E-14/E-15 curves); the registered 18b run used 0.05 (register f).
- [x] **19f** Script `scripts/checks/bisect_18b_chain.jl` (local copy of the tone sum with switches, equal to PAIN's at the base setting to 0 dB; no `src/` change), report `validation_reports/bisect_18b.md`. Criterion as fixed: 18b unchanged (4 dB), a block implicated when its swap moves a harmonic ≥ 3 dB toward NASA. **Implicated: the trim loss factor η_T** (swap 1a, η_T = 0.5 with the whole trim rebuilt: 82.73, 75.73, 77.05 dB = +3.7, +0.2, +9.1 dB, shifts −9.19, −4.28, −7.82; swap 1b, η_T = 1.0: +0.3, −0.7, +6.7 dB). Not implicated: η_n from the E-14 calculated curve (+2.46, −2.81, −4.85; H3 only), η_r' from the E-15 measured points (+1.64, +0.73, −0.56), the 19c alternative (−0.18, −2.21, −2.30), mirroring (+1.54, −2.12, +3.27), the unbarred f′ in Eq. (83) (+0.15, −0.03, −0.33); τ_t = 1 moves H1 by −12.9 dB but H2 and H3 by +5.6 and +5.0 dB away from NASA. Already equal to NASA's and not swapped: Table C-1 (15a), Table D-1 (17d). **Candidate cause named: the η_T input of the registered run. H3 stays open at +9.1 dB (η_T = 1.0: +6.7).** The registered 18b result stays "not met" (a re-run with η_T = 0.5 needs the author's confirmation and a pre-registration).
- [x] **19g** Script `scripts/checks/check_fig_d2.py` (pure Python, PyMuPDF), data `data/cr3813/fig_d2_mode1_digitized.csv`, report `validation_reports/fig_d2_check.md` (not `mrp_table_d1.md`, which `Pkg.test()` regenerates). Digitized from the 300 dpi page image; the figure's scale is common to plate and shell (p. D-10: maximum normal displacement 1.0). **Floor: largest difference 0.057 of the peak against the 0.05 criterion: not met** (digitization ±0.005; the figure is below the model at i = 7–10; omitted Table D-1 terms are a possible cause, untested). **Shell: 0.026 against 0.05: met**, and limited by the print-column quantization (about ±0.026); the `mrp.jl` convention Σ C (−1)^n cos nθ matches, the plain Σ C cos nθ does not (0.107). The *F label sits at θ = 54.7° (θ0 = 56.6°), checking the row calibration. **Eqs. (D.22)–(D.26) against `mrp.jl`:** (D.22) same eigenproblem form; (D.17)–(D.21) constraints replaced by soft springs (differs); (D.23), (D.25) u–v–w operator not implemented (w-only Donnell-type diagonal with three fitted scales, k_scale 0.61, floor_scale 2.4, edge_factor 2.2); (D.24) smearing present in spirit (t_eq, D_s). The production path uses Table D-1, not the Ritz solver, so none of this is on the 18b path.
- [x] **19h** Script `scripts/checks/check_eta_r_normalization.jl`, report `validation_reports/eta_r_normalization.md`. Text quoted (pp. 38, 39, 43, D-10): Eqs. (66)–(68) build j_r^rev from the shell coefficients C_Mn^sr with no division by M_r or by the mode's mean square; the definition on p. 38 has no normalization. **Decision: used as printed, as the code does.** Diagnostics (not adopted): doubled n > 0 and axial forms −0.48, −0.57, −1.56 dB; shell shape normalized by its own mean square −1.17, −1.41, −5.62 dB; with M_shell/M_r −0.48, −0.61, −2.89 dB (η_T = 0.05); with NASA's η_T = 0.5 the shell-shape normalization gives +2.4, −1.3, +3.9 dB against NASA, a pointer for the author's decision since that normalization is not printed.
- [x] **Phase 19 outcome.** The largest cause of the 18b miss is an input, not an equation: the registered run used η_T = 0.05 where NASA used 0.5 (p. E-24). With 0.5, H1 and H2 are within 4 dB of NASA's PAIN predictions and H3 is +9.1 dB. The Eq. (8) algebra, the (mA/4)²τ_ML factor, ε_n, the mirroring, the trim phase sign and stack order, the E-14/E-15 losses, the Table D-1 shapes and the η_r normalization are ruled out or recorded. Not tuned. **Carried to phase 20 (needs the author's confirmation; `src/` and registered results):** (i) whether the Phase III default of `phase3_trim` becomes η_lining = 0.5 for the e11 path (the 0.05 default stays for the aircraft case, register f); (ii) a pre-registered re-run of 18b with η_T = 0.5 (criterion unchanged, 4 dB) and the T1/T2 grades of 18a that were computed with 0.05; (iii) the open H3 miss, with the shell-shape normalization of 19h and the omitted D-1 terms of 19g as untested pointers.
- [x] Docs updated (CLAUDE.md, 19e–19h): `README.md`, `flowchart.md`, `METHODOLOGY.md` (reproduction text, MRP section, claim register), `VALIDATION_GUIDELINE.md` (register f, §2.11.4 result, Table D-1 row), this file.
- [x] Docs updated (CLAUDE.md, 19d): `README.md`, `flowchart.md`, `METHODOLOGY.md` Ψ_G row, `VALIDATION_GUIDELINE.md` Ψ_G row, `pain_core_eq8_phase17.md` Ψ_G row, this file. Also in 19c: the `cabin_eps_3d` docstring in `src/cyl2d.jl` corrected (comment only, the author asked to continue).
- [x] Docs updated (CLAUDE.md, 19c): `README.md` PAIN-core row, `flowchart.md` tone-pressure node, `METHODOLOGY.md` CYL2D 3-D modes paragraph and reproduction text, `VALIDATION_GUIDELINE.md` power-balance row, `pain_core_eq8_phase17.md` trace row, this file.
- [x] Docs updated (CLAUDE.md, 19a–19b): `README.md` PAIN-core row, `flowchart.md` tone-pressure node, `METHODOLOGY.md` power-balance row, reproduction text and claim register, `VALIDATION_GUIDELINE.md` §2.7 Ψ_G and power-balance rows and §2.11.4 result row, this file.

---

## Phase 20 — Baseline before the aircraft-source change *(done 2026-10-20)*

- [x] **Decision (from phase 19; author, 2026-10-20):** Phase III trim loss factor η_T = 0.5 for the test article (`phase3_trim` default η_lining 0.05 → 0.5, `src/trim_loss.jl` docstring and default; the aircraft register default 0.05 unchanged, its 0.01–0.10 range revisited in phase 31 before any aircraft run). 0.5, not 1.0 (1.0 would be tuning). 18b-r is labelled an input correction with the result known from 19f.
- [x] Frozen baselines renewed (`data/baselines/phase17_baselines.csv`, header dated; old file kept as `phase17_baselines_etaT0p05_archive.csv`); `Pkg.test()` 1758 of 1758.
- [x] 18b-r and 18a-r criteria written before the runs (`VALIDATION_GUIDELINE.md` §2.11.5). 18b-r: 82.73, 75.73, 77.05 dB = +3.7 (within the criterion, margin 0.3 dB), +0.2, +9.1 dB: not met, 2 of 3 (original 18b kept as "not met, wrong η_T"; `pain_reproduction_e16.md`, script prints both). 18a-r: T1 81.04, 75.00, 75.29 dB (H1, H2 pass by the NASA route only, H3 fails); T2 52.96 (pass), 50.62, 48.66 dB (fail); `t1_tonal.md`, `t2_third_octave.md` regenerated.
- [x] Baseline recorded in `docs/validation_reports/phase20_baseline.md`: `Pkg.test()`, e11 T1/T2, F1A smoke (ℓ = 1 peaks 125.7, 118.6, 111.3 dB, Δ 0 by calibration; wall time 17.9 s for the ℓ = 1-only run), aircraft example 85.0, 77.9, 76.7 dB, 78.7 dB(A).
- Author decisions kept as written: H1 is reported as within the criterion with a 0.3 dB margin, not a clean reproduction; T1 at H3 stays "no claim" with +9.1 dB an open finding; the 19h shell-shape normalization is not adopted (not printed in CR-3813); H3 does not block phase 21 onward, and phase 33 carries it as a stated limitation if unresolved.
- [x] **19i (done 2026-10-21).** `scripts/checks/h3_followup.jl` → `docs/validation_reports/h3_followup.md`. Base H1–H3 = 82.73, 75.73, 77.05 dB (= 18b-r to 0.01 dB). **Part A:** H1 modes 6 (55.7 %), 8 (28.3 %), 17 (9.8 %), 1 (1.9 %); H2 modes 8 (60.2 %), 6 (13.6 %), 17 (7.4 %), 9 (5.9 %); H3 modes 15 (29.8 %), 25 (22.6 %), 17 (21.4 %), 21 (8.1 %). **Part B:** every plate/shell ±0.057 perturbation on the four H3 modes shifts H3 by at most 0.16 dB; **not found** (implicated if ≥ 3 dB toward NASA 68.0). Not adopted. H3 remains an open finding for phase 33.
- [x] Docs sync Q1+Q2 (2026-10-21): `METHODOLOGY.md`, `VALIDATION_GUIDELINE.md` (§2.8, register f, §2.11.5), `README.md`, `flowchart.md`, this file.

---

## Phase 21 — Shared source function; F1A at all 160 points *(done 2026-10-21)*

- [x] **21a** Author instruction “keep going… no need to ask for permission” treated as CONFIRM waiver for this `src/` change (2026-10-21).
- [x] **21b** `f1a_line_reference.csv` (uncalibrated + calibrated ℓ = 1).
- [x] **21c–21f** `Observer`, `SourceResult`, `evaluate_propeller_source`, `grid_observers`, `hub_observers`, `apply_table8_calibration`, static `@warn`, notes “all 160 points, no GEXT”.
- [x] **21g** Tests: equivalence, coincidence, all-160 ≠ GEXT, echo, static guard — **225** pass in shared set (incl. later 25h ScaledLoads).
- [x] **21h** `run_f1a_smoke.jl` on ℓ = 1 subset; `debug_f1a_scale*.jl` → `scripts/retired/`.
- [x] **21i** `Pkg.test()` pass; e11 T1/T2 = phase20_baseline within 0.01 dB (81.04, 75.00, 75.29; 52.96, 50.62, 48.66); F1A smoke Δ 0 by calibration, wall ~7 s (nH=3, nsrc=32) vs prior 17.9 s ℓ=1-only; `gext_vs_f1a_grid.md` (off-line ΔSPL large near ℓ=10 — cosine falloff vs full F1A); aircraft example interior 75.9, 63.1, 66.5 dB, ~68.2 dB(A) (X-EXTRAP diagnostic).
- Also in same pass: `ScaledLoads` (25h) and `allow_static` keyword (25a) landed in `evaluate_propeller_source`.

## Phase 22 — Documentation update for phase 21 *(done 2026-10-21)*

- [x] `flowchart.md`: removed “code still runs l=1 + GEXT” note; design rule confirmed.
- [x] `README.md`: current state = F1A all 160, GEXT e11-only; CCBlade→F1A status row updated.
- [x] `METHODOLOGY.md` §2.2 / claim register: full-grid F1A; GEXT e11-only.
- [x] `VALIDATION_GUIDELINE.md` §2.2: scope e11-only; importance bound run noted.
- [x] Smoke reports regenerated (`ccblade_f1a_smoke.md` notes string; `run_pain.jl` pipeline).
- [x] This file: phases 21–22 ticked and moved here.

## Digitization + Report 996 / Pereira expansion *(2026-10-21; partly voided by the review, §3.0 I-01–I-04, I-08: C-01–C-03, C-05, C-07–C-10, C-11 Figs. 18–20, 25k asymmetry, 27, 28 levels and phases)*

- [x] **C-05** E-21/E-22 pass B dual hand; δ_dig = 1.00 dB PASS (`dig_cr3813_e21_e22_hand.py`).
- [x] **C-07–C-12** E-17, E-18, E-16-B, E-9-B, E-10, BBN Figs. 18–20, Report 996 Fig. 3(c).
- [x] **25k** `report996_setup.jl`: behind>ahead true; rms convergence n=7.
- [x] **27** Expanded acoustics: Figs. 14, 13a, 12a/b, 7 → `report996_acoustics.md` / `f1a_results.csv` (verdict still 23c).
- [x] **28** Expanded Pereira: 3 polars × thickness; ScaledLoads H1 φ=0 ≈−2.3 dB (verdict still 23d).
- [x] Docs sync: `README.md`, `flowchart.md`, `METHODOLOGY.md`, `VALIDATION_GUIDELINE.md`, this file.

## Phase 32 — GEXT importance bound *(done 2026-10-21)*

- [x] 32a–32d, 32f: flips (n=0 flat; delay ×2) → **T1 not claimable**; GEXT stays V-ASSUMED.
- [x] **32e** OAT ±20 % on η_t, C, trim-mass, `bb_j2_scale`: ΔH1 up to ~1.5 dB (referent only). Report `gext_importance_bound.md`.

## Phase 33 — Close-out *(done 2026-10-21)*

- [x] 33a: Gutin/Hanson optional cross-check **not run**; no "better than" claim.
- [x] 33b: keep optional Table-8 peak calibration (raw F1A does not match within tol); never compare calibrated path to Table 8.
- [x] 33c: claim register — aircraft free field **X-EXTRAP**; BBN/996/Pereira verdicts recorded; T1 not claimable (GEXT).
- [x] 33d: earlier (18a).
- [x] 33e: `propeller_ccblade.jl` header updated.
- [x] 33f: five docs synced.
- [x] 33g: GUI source = `aircraft` only; e11/synthetic remain for tests/scripts.

## Phase 34 — Validation cases in the GUI *(done 2026-10-21)*

- [x] **34a** `src/validation_cases.jl` + `validation_case_extras.jl`: registry; runnable cabin/source short cases + E11/E12/E14/GEXT/BBN_KIN/R996_PHASE; long F1A IDs Run→report pointer (not greyed); greyed only E21_E22_NR, R996_FIG8.
- [x] **34b** CairoMakie 0.15.16; `src/validation_plots.jl` → `docs/validation_reports/figures/<id>.png` (+ PDF).
- [x] **34c** `plot_spec` on every registry entry (axes per published figure table).
- [x] **34d** testset "Validation case registry (34d)": CYL2D/MRP rtol 1e-9; Table C-1 reference series exact; unavailable → `:no_verdict`.
- [x] **34e** GUI **Validation** tab (`main.qml` + `gui_model.jl` / `gui_main.jl`); async run; open report.
- [x] **34f** `smoke_gui_model.jl` / `smoke_qml_load.jl` extended (CYL2D_C1 through `run_validation_gui!`).
- [x] **34g** five docs updated (README, flowchart, METHODOLOGY, VALIDATION_GUIDELINE, this file).

## Phase 35 — Test audit, validation maps and the "Validation map" GUI tab *(done 2026-10-21)*

- [x] **35a Test audit (A1–A7).** CYL2D: `TABLE_C1_C0 = 341 m/s` back-solved from Table C-1 → absolute-frequency check partly by construction; **re-stated 2026-10-21 post-hoc** as frequency *ratios* f_i/f_1 (modes 2–19) within 0.1 % (c0-free; worst 0.0003 %); Φ_G, symmetry, Fig. C-3 unchanged; criterion date "2026-10-20 (ratio form 2026-10-21, post-hoc)". MRP: hybrid asserts the Table D-1 copy; `MRP_D1` verdict `no_verdict` (transcription); raw Ritz kept as regression guard of a calibrated fit — live **26/32** within 5 % (`mrp_ritz_vs_d1.md` still records 30/32, stale; `mrp.jl` not changed). Can't-fail tests replaced: dBA → IEC 61672 table + hand-built-spectrum checks; polar → `clb/cl = k_cl = 0.92264` exactly. `REPRO_18b` registry case was running e11/R2 (= T1); now runs 18b-r inputs → **82.73, 75.73, 77.05 dB**, not met (2/3, H3 +9.1); label **"post-hoc (η_T = 0.5 input correction; result known from 19f)"**. T1 case table shows both gates A and B. Free gauges kept (Fig. C-3 eigenvector sign; BBN kinematic rotation-sense from H1). Valid checks unchanged: blocking p.68, coupling limits, joint acceptance, App. A, Ψ_G, Eq. (8) re-impl, Gutin, E-14, E-11 δ_dig, E-12.
- [x] **35b Plots.** Every case plot has an error panel (computed − reference; green/red vs criterion; ±tolerance dashed); legend outside; plain-number ticks on log axes; one tolerance band around the first reference series; T2 x-axis 1000–2600 Hz; "Source figure page" shows digitized page images via `VALIDATION_SOURCE_FIGURE_FALLBACKS` for T1, REPRO_18b, T2, E11, E12, E14, R996 Figs 12/13a/14, Pereira Figs 6–9.
- [x] **35c CASE_INFO + two maps + new cases + replays.** `src/validation_map.jl`: Map 1 "PAIN verification — CR-3813 cabin chain"; Map 2 "Aircraft source validation — CCBlade BEMT + F1A". New registry: `BLK_P68` (met 6/6), `MRP_RITZ` (calibrated, always `no_verdict`; 26/32 live), `F1A_GUTIN` (met, Δ = 0.3 dB; Gutin in `f1a_gutin_h1_comparison`). Replays from CSV: `R996_FIG14` not met 5/24, `R996_FIG13A` not met 6/14, `R996_FIG12` not met 19/40 (first verdict under frozen 23c), `R996_LOADS` 6/32 not met (post-hoc label). C4: `pereira_results.csv` / `bbn_results.csv`; PER_* and BBN_* replays; only `E21_E22_NR` and `R996_FIG8` remain placeholders. All case numbers from CSVs or transcribed tables; page images display-only. C5: `overall_dBA` energy-sums all 1/3-octave bands A-weighted at centres (aircraft example 83.22 → 83.74; synthetic smoke 71.38 → 91.36). **I-17 open:** free-field amplitude convention (rms vs Fourier peak).
- [x] **35d GUI.** Third tab **"Validation map"**: map switch, intro, legend, flowchart of blocks with clickable case chips; detail panel (source, verifies, why, meaning, not covered, recorded, criterion + date, Run, Open report, code-vs-figure plot with error panel, source figure page). Validation-tab list ordered by map and block. GUI shows "Press Run to draw the comparison plot" until run.
- [x] **35e Tests/smokes.** `Pkg.test()` passes; smoke scripts cover map JSON and a replay run.
- [x] **35f Five docs** updated (this phase).
- [x] **35g Cursor check rule** in `CLAUDE.md` / plan R13.
- [x] **C3 Directory cleanup.** `git mv` one-off scripts → `PAIN.jl/scripts/retired/`; `SESSION_PROMPT.txt`, `T1_fix_instructions.txt` → `docs/archive/`; cropped source figures under `docs/validation_reports/figures/source/`.

## Task P1 — Faster test cycle *(done 2026-10-22)*

Developer tooling only; **no** change to assertions, criteria, reference data or `src/`.

- [x] **Testset filter.** Top-level `@testset`s wrapped in `_run_if` in `test/runtests.jl`. `Pkg.test("PAIN"; test_args=[…])` runs only titles containing any substring (case-insensitive); empty args = full suite. Prints ran/skipped summary. Titles + typical times: `PAIN.jl/test/README.md`.
- [x] **DaemonMode.** `PAIN.jl/scripts/devtools/` own env (`Project.toml` / `Manifest.toml`: DaemonMode + Revise — **not** a PAIN dependency). `start_daemon.ps1` / `start_daemon.jl` (Revise + `using PAIN` + `serve(shared=true)`), `run_in_daemon.ps1`, `run_tests_in_daemon.jl`, `stop_daemon.ps1`. README notes Revise is loaded; restart after structural `src/` / project changes if revise fails.
- [x] **Measured wall times (2026-10-22, Julia 1.13.2):** full `Pkg.test()` **224 s**; filtered `Grid geometry` via `Pkg.test` **88 s**, via daemon **33 s**; `smoke_gui_model.jl` normal **577 s**, via daemon **54 s**.
- [x] Docs: README, flowchart, METHODOLOGY, VALIDATION_GUIDELINE §3.1, this file.

## Task R1 — Directory reorganization *(done 2026-10-22)*

Moves only (no change to data values, criteria, computations or recorded numeric results). Spec: `docs/specs/R1_directory_reorg.md`.

- [x] CR-3813 CSVs, `e12/`, raw WebPlotDigitizer exports, page images and QA overlays → `data/cr3813/` (`pages/`, `qa/`, `raw_exports/`); Pereira/Russell overlays → `data/pereira/qa/`, `data/russell/qa/`.
- [x] Scripts → `scripts/{run,checks,digitize,setup,smoke}/`; `run_gui.jl` stays top-level; `fit_mrp*.jl` in `checks/` (calibration provenance); `write_tr996_fig3_i11.jl` in `digitize/`.
- [x] `data/README.md` and `scripts/README.md`; every code/doc/CSV path reference updated (`@__DIR__` depth, `_data_path`, figure fallbacks, digitizers, CLAUDE.md smoke paths).
- [x] Review 2026-10-22: full `Pkg.test()` PASS, GUI smoke PASS (offscreen); regenerated `run_pain_reproduction`, `mrp_ritz_vs_d1` reports identical to HEAD-code output except printed script path. `check_grid_mirroring.jl` output at `ef184d8` code (also reproduced in a clean worktree at `ef184d8`) is 85.74/78.74/80.06 dB (decision row), not the older 91.92/80.01/84.87 in `grid_mirroring.md`: that report was stale since the 37b amplitude-convention fix; refreshed now. The mirroring shifts are +3.80, −1.31, +3.58 dB (about θ = 0) and +1.69, +3.22, +6.07 dB (about the ℓ = 1 line); the 18b-r values in `pain_reproduction_e16.md` were already current. Not a result of R1.
- [x] Empty `data/figures/` and `data/qa/` left in place (author handles deletions). No commit in this task.
- [x] Targeted checks: filtered testsets that read moved files; `scripts/smoke/smoke_gui_model.jl` (offscreen); three report scripts regenerating with new printed script path only.

## Phase 37 — Root-cause fixes from the 2026-10-21 GUI review *(done 2026-10-22)*

**Why.** The author ran every case in the GUI and listed failures and display problems ("find all the root causes and fix all of
them; ensure you are not tuning anything"). Tuning, as the author defined it on 2026-10-21, means adjusting anything toward
**experimental** data; for code-on-code checks a demonstrated bug is fixed. Each item below has a root cause from the code or the
source documents, not from the size of the gap. Code changes are delegated to Cursor and checked per R13.

| Step | Item (author's report) | Root cause | Fix | Status |
|------|------------------------|------------|-----|--------|
| 37a | Selected row loses its highlight; figure page swamps the plot; pages not scrollable; plots unreadable (BBN levels/circ/long, R996 Figs. 6/12/13a/14, loads, Pereira) | QML list model rebuilt as a new array on every observable change (reset `currentIndex`); plot and page side by side at fixed size; error-panel legend one entry per row; series joining different harmonics/runs/polar sets/β; phase drawn as lines across ±180°; BBN residual not wrapped (23a says wrap); R996 Fig. 6 single point drawn as a line | Selection keyed by case id; scrollable result pane, plot ≥ 560 px first, source page below behind a toggle, click opens full size; explicit row groups; one series per harmonic/run/polar set; markers for phase; wrapped residual; Fig. 6 marker at x/D = 0 | **Done 2026-10-21** — all verdicts and counts unchanged except 37a′ |
| 37a′ | GEXT_BOUND "did not pass" | Verdict hard-coded `:not_met` for a diagnostic with no pass criterion | `:no_verdict`, reason states it is a diagnostic (phase 32) | **Done 2026-10-21** |
| 37b | Errors in R996 Figs. 12/13a/14, Pereira; e11/Table-8 tones (I-17) | **Amplitude convention**: rms data compared with or converted as Fourier peaks (I-17 sources) | One convention in code: `spl_dB_to_peak_Pa`, `peak_Pa_to_spl_dB`; comparisons in rms; scripts re-run; baselines re-frozen with a dated note; affected results labelled post-hoc. Check: every e11/Table-8 tone moves by exactly +3.0103 dB | **Done 2026-10-21.** Check met (T1 +3.010/+3.009/+3.014, REPRO_18b +3.010/+3.010/+3.015, baselines +3.0103 exact, Ψ_G ×2, τ_t unchanged). Re-recorded (post-hoc): **REPRO_18b 85.74, 78.74, 80.06 dB = +6.7, +3.2, +12.1 vs NASA, 1 of 3 (was 2 of 3)**; T1 84.05, 78.01, 78.30 (H1 fail, H2 pass, H3 fail); T2 55.97, 53.63, 51.67; **R996 Fig. 14 20/24 within ±2 dB → met (was 5/24)**, Fig. 13a 8/14, Fig. 12 22/40 (counts recomputed independently from `f1a_results.csv`); Pereira Fig. 9 H1 3/9 (was 0/9), H2 6/9; F1A smoke vs Table 8 −7.2, −8.3, −8.8 dB (rms). Page-12 phase unchanged (103.8°). Old baselines kept as `phase17_baselines_rmsA_archive.csv` |
| 37c | R996_FIG8 "fix sweep defer" | Out of scope (M_t = 1.0; I-20) | Case removed from registry, map, tests and docs | **Done 2026-10-21** (code); docs in 37h; digitized `tr996_fig8_pc_vs_CP.csv` kept |
| 37d | MRP_RITZ "failing" | The raw solver is a fitted surrogate (not Eq. D.25); the 30/32 record predates the 2026-10-20 Table D-1 re-transcription whose shapes seed it (today 26/32: D-1 modes 2, 3, 4, 7, 8, 9 miss) | Re-run `scripts/run/mrp_ritz_vs_d1.jl` to re-record 26/32; no refit (refitting the scales to the table would be calibration); explanation in §2.13 | **Done 2026-10-21** — `mrp_ritz_vs_d1.md` 26/32, dated header |
| 37e | No explanations (R2, F1A_GUTIN, PER_LOADS "no verdict", R996 loads errors, BBN, R996_PHASE); the Validation map not understandable | Texts were hard-coded in `validation_map.jl` and thin | New `VALIDATION_GUIDELINE.md` §2.13 "Validation case reference (read by the GUI)": one block per case, per map and per block; the GUI parses it, so editing the .md changes the GUI. Both tabs show what it tests, why, what a pass means, what is not covered, recorded outcome, explanation; the map gets "how to read this map". Leftover display items: blank legend entries beyond the cap, dense log ticks on Fig. 14 | **Done** (verified 2026-10-23, Phase 58d) |
| 37f | R996_LOADS errors | No code bug: C_T, C_P definitions checked (T/(ρn²D⁴) both sides). CCBlade thrust ≈ 20 % low with these XFOIL polars, as the data folder's own BEM (12–31 % low) | Explanation only; not tuned; post-hoc label kept (criteria registered after the loads were computed) | Pending (text in 37e) |
| 37g | BBN_CIRC fails; R996_PHASE fails | I-19 (sign convention undocumented); page-12 stations not named in Report 996 (candidates ±0.125) | Explanations only; verdicts stay | **Done** (texts in §2.13; verified 2026-10-23, Phase 58d) |
| 37i | **Run buttons do nothing** (Validation tab Run / Run all, Validation map Run) | The QML handlers start the case with `@async` and return; `main()` ends with the blocking `exec()`, which never yields to Julia's scheduler, so the task never runs. The smoke tests call `run_validation_gui!` directly and never exercised the button path | `main()` uses QML.jl's `exec_async()` (cooperative event loop) and waits until the window closes; new smoke check runs the GUI on Qt's offscreen platform, triggers `run_validation_from_qml` from QML and asserts the case completed (status "Done …", PNG written) — the exact button path, no visible window | **Done 2026-10-22** (`dc0d48a`; offscreen button-path smoke test) |
| 37h | Five docs (R5) | — | README, flowchart, METHODOLOGY, VALIDATION_GUIDELINE, this file | **Done 2026-10-22** (docs synced after 38a–38e; Phase 38 modules added to README, METHODOLOGY, flowchart, VALIDATION_GUIDELINE) |

---

## 6. Source phases 21–28 — aircraft source path, BBN/Wilby, NACA Report 996 and Pereira *(done 2026-10-21/22; moved to the bottom 2026-10-22)*

Phase 21 changes the aircraft source path: F1A at all 160 grid points through one shared source function, and no grid extension (GEXT) on that path. GEXT stays on the e11 validation path only, because NASA measured one line (ℓ = 1). Phase 22 brings the docs in line. Phase 23 fixes every source pass criterion before any comparison. Phases 24 (BBN/Wilby, phase), 25–27 (NACA Report 996, amplitude, static) and 28 (Pereira, forward flight) check the CCBlade → AcousticAnalogies free-field block, i.e. the inputs to `apply_blocking` / `PainInputs`. Blocking, CYL2D, MRP and the PAIN core are out of scope for these checks. Order of checks: decision 2026-10-16.

| Phase | Goal | Done when |
|-------|------|-----------|
| 21 | One shared source-evaluation function; aircraft path runs F1A at all 160 points; GEXT stays e11-only | Code-change table under phase 21 applied; e11 T1/T2 unchanged; all-160 test and shared-function coincidence test pass |
| 22 | Docs and flowchart match the code | Documentation-change table under phase 22 applied; code-differs notes removed from `flowchart.md` and `README.md`; smoke reports regenerated |
| 23 | Pass criteria fixed before any comparison | BBN, Report 996 and Pereira criteria with values written down and dated; held-out reservation decided (phase 23 table) |
| 24 | BBN/Wilby phase check | `data\NASA_CR-158919\` and `data\NASA_CR-159124\` present; kinematic tests pass; circumferential and in-plane results recorded against the 23a/23b criteria; longitudinal pairs reported as X-EXTRAP |
| 25 | Inputs and tooling to reproduce Report 996 cases, all through the shared function | Static probe done; geometry, polars, observers, and unit conversion in place; targets copied into `data/`; pass criteria written down before any comparison |
| 26 | CCBlade loads vs measured static data | C_T and C_P reported against the static data (RM L8H25a, Report 996 Fig. 7 legend) for both polar sets; load-scaling factors recorded |
| 27 | F1A pressures vs Report 996 measured pressures, plus Gutin / Hanson cross-checks | Total rms pressure vs Figs. 6, 7, 8 for both polar sets with loads scaled to measured T/Q; Fig. 13/14 added if digitized; phase check done |
| 28 | Forward-flight check vs Pereira et al. (2026) | Harmonics 1–2 at 1 m against the 23d criteria with the polar sets from phase 11 |

### Phase 21 — Code change: one shared source function; F1A at all 160 grid points (no grid extension) *(done 2026-10-21; see §11)*

> **Completed.** Checklist below is the historical plan; ticks and the §11 write-up are authoritative.

### Phase 21 (plan text retained)

**Design: a single shared source-evaluation function.** Production and validation must run the same code. Today the
CCBlade → F1A → FFT sequence lives inside `_ccblade_f1a_grid` and is tied to the fuselage grid; a Report 996 check would need either
a copy of it or a reach into its internals, and a copy can drift from what production runs. Phase 21 splits it into three pieces:

| Piece | Role | Notes |
|-------|------|-------|
| `evaluate_propeller_source(cfg, observers; n_harmonics, num_src_times, loads=:ccblade)` | **The only place** that builds the CCBlade rotor, solves the sections, builds the F1A source elements, runs `noise` + `combine` per observer, and takes the FFT. Returns a `SourceResult`: single-sided peak amplitude (Pa) and phase per observer × harmonic, plus T, Q, C_T, C_Q, C_P, `bpf_Hz`, and an echo of every setting used (Vinf, c0, ρ, polar source, thickness, `loads` mode). | No calibration, no GEXT, no grid knowledge inside. |
| `Observer(x_aa, v_obs)` and two builders: `grid_observers(fuse, prop, spec)` and `hub_observers(R, D; x_over_D, d_over_D)` | The grid builder turns `grid_points` into observers through `_observer_aa`. The hub builder gives the Report 996 / Pereira positions. | Both feed the same function. |
| `propeller_freefield_grid(...)` | Thin wrapper: `grid_observers` → `evaluate_propeller_source` → reshape into `FreeFieldHarmonicGrid` → optional `apply_table8_calibration` as a **separate** post-step. | Calibration stays outside the shared function so validation runs are never calibrated by accident. |

Rules that follow from this design:
- No script, test, or validation driver may reimplement the CCBlade → F1A → FFT sequence. `debug_f1a_scale*.jl` either call the shared function or are retired.
- The polar `af(α, Re, M)` is an input to `evaluate_propeller_source` (`cfg` names a polar source). The present clamped linear polar remains the default, and Report 996 / Pereira runs pass their own.
- `loads=:ccblade` is the production mode. A validation-only mode `loads=ScaledLoads(T_target, Q_target)` scales the CCBlade section loads (Np, Tp) so the integrated thrust and torque equal measured values, to isolate F1A from the BEMT error. It must be recorded in the result echo. Not checked: that `f1a_source_elements_ccblade` accepts modified `Np`/`Tp` (the CCBlade `Outputs` struct would have to be rebuilt); confirm in phase 25.
- The static guard (`Vinf < 1` → 20 m/s) must not remain silent. In phase 21 the function emits a warning whenever it substitutes the speed (no behavior change); phase 25 decides the final handling from the probe result.
- Coincidence test: evaluate one of the 160 grid points through `grid_observers` and the same coordinates through `hub_observers`/a hand-built `Observer`; the amplitudes and phases must be identical to machine precision.

**Why.** The aircraft source path (`source = :aircraft`) currently runs CCBlade → AcousticAnalogies F1A at the l = 1 line
observers only, then fills the other grid points with `extend_line_to_grid` (GEXT: cosine falloff + geometric phase delay).
This does not match `flowchart.md`, which shows F1A at all 160 points feeding blocking directly.
- F1A already produces directivity and phase at each observer (retarded-time calculation). A cosine falloff and phase delay on
  top of an l = 1-only evaluation approximates what F1A gives directly.
- GEXT is classed **V-ASSUMED** (`METHODOLOGY.md`): its unit tests verify code (falloff at 0/45/90°, phase sign, axis mapping), not
  physics. The Fig. E-12 on-line check tests Eq. 43 blocking (R1/R2), not the extension.
- An aircraft study should not depend on an assumption that exists only to fill in missing measured data.

**Current behavior** (`PAIN.jl/src/propeller_ccblade.jl`, `_ccblade_f1a_grid`):
- Lines 145-146: `for pnt in pts; pnt.ell == 1 || continue` — F1A runs only for l = 1 points.
- Lines 141-142: `line_amps` / `line_phases` are sized `spec.k_max × n_harmonics` and indexed by `pnt.k`.
- Lines 168-195: optional Table-8 peak calibration scales the l = 1 line (`anopp_table8_calibrate`).
- Line 198: `extend_line_to_grid(line_amps, line_phases, pts; omega_H=...)` fills the 160-point grid.
- Line 202: result note reads "CCBlade+F1A l=1 + GEXT (X-EXTRAP)".

**Code changes**

- [ ] Apply the table below.

| File | Change |
|------|--------|
| `PAIN.jl/src/propeller_ccblade.jl` | Extract the body of `_ccblade_f1a_grid` into `evaluate_propeller_source` (see the design table above): observers become an argument, results come back as a `SourceResult`. Remove the `pnt.ell == 1 \|\| continue` filter by making the grid wrapper pass all `pts` through `grid_observers`; fill `amps`/`phases` from the result in the order `FreeFieldHarmonicGrid` expects. Delete the `extend_line_to_grid` call. Move the Table-8 block (lines 168-195) into `apply_table8_calibration`, called by the wrapper only. Add the `@warn` on the `Vinf < 1` substitution. Update the docstring (line 49) and the notes string (line 202). Decide how the Table-8 calibration is applied (open decision 1). |
| `PAIN.jl/src/PAIN.jl` | Line 99 calls `propeller_freefield_grid` — check nothing assumes the line-only path. Keep the `extend_line_to_grid` export (still used by e11). `grid_observers` builds observers from `grid_points` as corrected in 12b (θ_ℓ = φ_p + (ℓ−1)π/18). |
| `PAIN.jl/src/freefield_digitized.jl` | No logic change. e11 path still calls `extend_line_to_grid` (line 124). Update header comment (line 6) only if wording implies the aircraft path uses it. |
| `PAIN.jl/src/grid_extension.jl` | No logic change. Update the header (line 3) to say "e11 validation path only". |
| `PAIN.jl/test/runtests.jl` | Existing GEXT unit test (line 44) stays. Add a test that the aircraft path returns amplitudes for all 160 points without calling GEXT (for example, non-l = 1 points differ from a cosine-extended line). Add the shared-function coincidence test (grid point vs hand-built observer at the same coordinates). |
| `PAIN.jl/scripts/run/run_f1a_smoke.jl` | Compares l = 1 peaks to Table 8 (lines 2, 31). Still valid, but confirm it indexes the l = 1 subset of the new full-grid output. |
| `PAIN.jl/scripts/debug_f1a_scale.jl` and `debug_f1a_scale2..5.jl` | Written for l = 1 observers (line 51 of `debug_f1a_scale.jl`). Check they still run; they may be retired. |
| `PAIN.jl/scripts/run/run_pain.jl` | Confirm any aircraft case it runs works with the new grid output. |
| `PAIN.jl/src/gui_model.jl`, `PAIN.jl/gui/main.qml` | Each references the aircraft/X-EXTRAP source label. Check text only. |
| `PAIN.jl/src/validation_report.jl`, `PAIN.jl/src/metrics.jl` | Matched the search terms. Not inspected; check whether they refer to the l = 1 + GEXT aircraft path. |
| `PAIN.jl/examples/aircraft_scale_hartzell.json` | Description mentions l = 1 peak SPLs vs Table 8 (still true for the l = 1 subset). Re-tune `pitch_offset_deg` / `thickness_over_chord` only if results change. |

**Open decisions**
1. **Table-8 peak calibration.** Table 8 only has l = 1 data. Options: (a) compute the per-harmonic scale from the l = 1 subset and
   apply it to all points; (b) drop the calibration for the aircraft path and report the raw F1A vs Table 8 difference as the
   X-EXTRAP result. Option (b) avoids hiding a possible loading-model offset; option (a) keeps the current Δ ≈ 0 smoke result.
   Keep the calibration as it is for now; this is settled in phase 33.
2. **Cost.** F1A at 160 observers is roughly 10× or more the l = 1-only work (k_max observers per ring). Measure runtime with
   `run_f1a_smoke.jl` before and after; reduce `num_src_times` if needed.
3. **Validation class.** The aircraft path stays **X-EXTRAP**. Removing GEXT removes one assumption; it does not add a validation
   against measured data.

**Verification steps**
1. Run `Pkg.test()` — the existing e11 / GEXT tests must still pass.
2. Run the e11 path (`run_pain_pipeline(; source=:e11, ...)`) and confirm T1/T2 results are unchanged from `phase20_baseline.md` (within 0.01 dB).
3. Run `scripts/run/run_f1a_smoke.jl` and compare the l = 1 subset to Table 8 before and after.
4. Compare the new full-grid F1A result against the old extended grid at a few off-line points; record the difference to show how
   much the assumed cosine falloff was contributing.

**Execution detail (Q3).** Every sub-step that edits `src/` is covered by one confirmation at 21a; any deviation from the diff shown at 21a needs a new confirmation.

- [ ] **21a [CONFIRM].** Show the author the planned diff for `src/propeller_ccblade.jl`, `src/PAIN.jl` (exports) and `test/runtests.jl`, and the open-decision defaults: (1) Table-8 calibration kept, option (a): scale computed on the ℓ = 1 subset, applied to all 160 points; (2) cost measured; (3) class stays X-EXTRAP. Record the approval date here.
- [ ] **21b. Equivalence reference first (script only, no `src/` change).** New `scripts/run/f1a_line_reference.jl`: run the current `propeller_freefield_grid` on `examples/aircraft_scale_hartzell.json`, once as is and once from a temporary copy of the JSON with `"anopp_table8_calibrate": false`; write the ℓ = 1 values to `data/baselines/f1a_line_reference.csv` (`calibrated, k, H, amp_Pa, phase_rad`; header: date, script, JSON, `n_harmonics`, `num_src_times`). This is what the refactored code must reproduce at ℓ = 1.
- [ ] **21c. Types and the shared function** in `src/propeller_ccblade.jl`:

  ```julia
  struct Observer
      x::Vector{Float64}   # AcousticAnalogies frame, m (rotor axis +X, hub at the origin)
      v::Vector{Float64}   # observer velocity, m/s
      label::String
  end
  struct SourceResult
      amplitude::Matrix{Float64}   # (n_obs, n_harmonics), single-sided peak, Pa (2|c|/n)
      phase::Matrix{Float64}       # (n_obs, n_harmonics), rad, angle(c) of the rfft bin
      harmonics::Vector{Int}
      bpf_Hz::Float64
      T::Float64; Q::Float64; CT::Float64; CQ::Float64; CP::Float64
      echo::NamedTuple             # Vinf, vinf_substituted, c0, rho, polar, t_over_c, pitch_offset_deg, loads, num_src_times, B, Rhub, Rtip, rpm
  end
  evaluate_propeller_source(cfg, observers::Vector{Observer};
                            n_harmonics::Int=10, num_src_times::Int=64,
                            loads=:ccblade, af=nothing) -> SourceResult
  ```

  Body = present lines 91–166 of `_ccblade_f1a_grid` moved unchanged, in this order: parse `cfg` (B, R_tip, R_hub, rpm, Ω, BPF, V_inf, ρ, c0, t/c, pitch offset, sections); polar `af` (argument, else the present clamped linear polar; default behaviour unchanged); `CCBlade.solve`; integrated loads T, Q from the section outputs (use `CCBlade.thrusttorque`; confirm it exists in the pinned 1.0.0, otherwise integrate N_p, T_p over r with B), with n = rpm/60, D = 2R_tip: C_T = T/(ρn²D⁴), C_Q = Q/(ρn²D⁵), C_P = 2πC_Q; F1A source elements; for each observer: `noise`, `combine`, mean removal, `rfft`, bin `round(Int, f_H/df) + 1`, amplitude `2abs(c)/n`, phase `angle(c)`. No calibration, no GEXT, no grid knowledge inside. `loads` accepts only `:ccblade` in phase 21 (`ScaledLoads` is 25h); any other value is an error.
- [ ] **21d. Observer builders.** `grid_observers(fuse, prop, spec; Vinf)` returns `(observers, pts)` in `grid_points` order, `x = _observer_aa(fuse, prop, pnt)`, `v = [Vinf, 0, 0]`, `label = "k=$(k),ell=$(ell)"`. `hub_observers(R, D; x_over_D, d_over_D, x_sign, azimuth_deg=0.0, v=zeros(3))` returns one observer per x/D at `x = [x_sign*x_over_D*D, (R + d_over_D*D)*cosd(azimuth_deg), (R + d_over_D*D)*sind(azimuth_deg)]`. `x_sign` has **no default**, so every caller states the ahead/behind convention (25d decides it).
- [ ] **21e. Grid wrapper.** `propeller_freefield_grid` = `grid_observers` → `evaluate_propeller_source` → fill `amps[k, ell, H]`, `phases[k, ell, H]` → if `cfg.anopp_table8_calibrate` is true, `apply_table8_calibration(grid, csv)` (moved from lines 168–195: per-harmonic scale from the ℓ = 1 peak against the Table 8 peak, clamped to ±20 dB, applied to all 160 points; returns the grid and the scales). Delete the `extend_line_to_grid` call and the `pnt.ell == 1 || continue` filter. Notes string: `"CCBlade+F1A all 160 points, no GEXT (X-EXTRAP). ..."` plus the scales. Docstring of line 49 updated. `_ccblade_f1a_grid` is removed (or kept as a one-line call to the wrapper if anything else uses it; grep first).
- [ ] **21f. Static guard.** Keep the `Vinf < 1 → 20 m/s` substitution (behaviour unchanged until 25a), add `@warn "Vinf < 1 m/s replaced by 20 m/s (static guard; plan 25a)" maxlog=1`, and set `echo.vinf_substituted = true`.
- [ ] **21g. Tests** (`test/runtests.jl`, CRLF), new testset `"Shared source function (21, V-CODE)"`, with `n_harmonics=3`, `num_src_times=32` to bound runtime (state that in a comment):
  1. *Equivalence:* ℓ = 1 observers through `evaluate_propeller_source` reproduce the uncalibrated rows of `f1a_line_reference.csv` (amplitude rtol 1e-10, phase difference wrapped to ±π within 1e-10 rad); the calibrated grid at ℓ = 1 reproduces the calibrated rows. Generate the reference with the same `n_harmonics`/`num_src_times` as the test.
  2. *Coincidence:* grid point (k = 5, ℓ = 4) through `grid_observers` and a hand-built `Observer` with the same `x`, `v`: amplitudes and phases identical (`==`).
  3. *All 160:* every amplitude finite and > 0; at least one ℓ ≥ 2 point differs from `extend_line_to_grid` of the ℓ = 1 line by more than 1e-6 relative (shows GEXT is not applied).
  4. *Calibration separate:* `evaluate_propeller_source` output does not change with `anopp_table8_calibrate`.
  5. *Echo:* every echo field present; `loads == :ccblade`.
  6. *Static guard:* a config with `forward_speed_mps = 0` gives `@test_logs (:warn, r"Vinf")` and `echo.vinf_substituted == true`.
  The existing GEXT tests (line 62 onward) stay.
- [ ] **21h. Scripts.** `run_f1a_smoke.jl`: compare `amps[:, 1, H]` (ℓ = 1 subset) with Table 8 and print the wall time. `debug_f1a_scale*.jl`: move to `scripts/retired/` with a first-line comment "retired in phase 21: reimplemented the source sequence" (they may not reimplement it any more). Check `run_pain.jl`, `gui_model.jl`, `gui/main.qml`, `validation_report.jl`, `metrics.jl` for "ℓ=1 + GEXT" text (text only).
- [ ] **21i. Runs and records.**
  1. `Pkg.test()`: all pass.
  2. `scripts/run/run_pain.jl`: e11 T1/T2 equal to `phase20_baseline.md` within 0.01 dB (81.04, 75.00, 75.29; 52.96, 50.62, 48.66 dB). Any difference: stop.
  3. `scripts/run/run_f1a_smoke.jl`: ℓ = 1 subset against Table 8 (Δ 0 by calibration) and wall time against 17.9 s; record the ratio.
  4. New `scripts/run/compare_gext_vs_f1a_grid.jl` → `docs/validation_reports/gext_vs_f1a_grid.md`: the new 160-point grid against `extend_line_to_grid` applied to the new ℓ = 1 line (same calibration, so only the extension differs); per H over the 144 off-line points: max |ΔSPL|, RMS ΔSPL, max |Δphase| wrapped, and the k × ℓ table of ΔSPL at H1. Diagnostic, no pass mark; it shows how much the assumed cosine falloff contributed.
  5. Aircraft example through `run_pain.jl`: new interior SPL and dB(A) against 85.0, 77.9, 76.7 dB and 78.7 dB(A) (diagnostic, X-EXTRAP).
- [ ] **Docs:** phase 22.

### Phase 22 — Documentation update for phase 21

- [ ] Apply the table below, then regenerate the validation reports.

| File | Change |
|------|--------|
| `docs/flowchart.md` | Diagram 3 (aircraft validation) already shows F1A at all 160 points, and diagram 2 (NASA validation) shows GEXT. Remove the "code still runs l = 1 + GEXT" note when phase 21 lands. |
| `README.md` | Remove the "Current state" sentence about the aircraft path still using GEXT; update the status row "CCBlade → F1A". |
| `docs/METHODOLOGY.md` (replaced `CLAIMS.md` on 2026-10-19) | §2.2 and the claim register: GEXT claim applies to the e11 path only. Reword "CCBlade+F1A l=1 peak SPL after Table-8 peak calibration" to full-grid F1A, with the l = 1 comparison as the check. Update the calibration wording in §2.3 and §10 per open decision 1. |
| `docs/IMPLEMENTATION_PLAN.md` | Mark phases 21–22 done; update the Phase 6 section and the architecture note (remove "until phase 21 lands"). |
| `docs/VALIDATION_GUIDELINE.md` | Section 2.2 ("Grid extension (assumed)") — state it applies to the e11 path only. Lines 60-61, 148, and 164 describe the CCBlade → F1A → grid adapter; remove the grid-extension wording. |
| `docs/validation_reports/ccblade_f1a_smoke.md` | Regenerate after the code change (its notes string says "l=1 + GEXT"). |
| `docs/validation_reports/pipeline_smoke.md` | Regenerate if it exercises the aircraft path. |

- [ ] Regenerate: `scripts/run/run_f1a_smoke.jl` (`ccblade_f1a_smoke.md`), `scripts/run/run_pain.jl` (`pipeline_smoke.md`, and the aircraft line). Then tick 21 and 22 here and move both to §11.

### Phase 23 — Pre-registration of pass criteria *(frozen 2026-10-21; §2.12)*

Rule 3 (`VALIDATION_GUIDELINE.md` §2.3.1): pass criteria are written before any comparison. This phase fixes them for every source check, so that phases 24–28 and 32 cannot adjust them after seeing a result. A criterion left blank here blocks the phase that needs it. Values marked "to be set" are for the author to fix; the evidence listed next to each is a constraint, not a choice.

| Step | What | Done when |
|------|------|-----------|
| 23a | **BBN circumferential phase criteria** (phase 24c). Pairs 4-3, 5-3, 4-5 (5-6 reported but flagged), harmonics 1–7, static runs and taxi at 40, 55, 70 kt. Statistic: measured minus computed phase difference per pair and harmonic, wrapped to ±180°, plus the trace-velocity ratio. State the sign convention and the coherence cut (below 0.15 low confidence, below 0.05 dropped). Evidence from the hand pre-check: a tolerance tighter than about ±15° is not supported at harmonics 1–2, and harmonics 3 and above need a wider one. Tolerance per harmonic: **to be set** | Tolerance, statistic, convention and pass rule written down |
| 23b | **BBN in-plane level criteria** (phase 24d). Relative levels of microphones 3–6 against microphone 4 from the CR-158919 tables (loads cancel in the ratios). Statistic and tolerance **to be set**; state that reflections and the assumed blade apply | Statistic and tolerance written down |
| 23c | **Report 996 criteria** (phases 26, 27). Collect the criteria of item 25g (cases, harmonics, tolerance, polar-set bracket, M_t 0.45–0.90 only) and the page-12 phase value | One consolidated list, criteria values filled |
| 23d | **Pereira criteria** (phase 28). Harmonics 1–2 at 1 m within the paper's ±1.7 dB measurement uncertainty; define the waveform-timing criterion at φ = 0° | Criteria written down |
| 23e | **Held-out reservation.** Before any further calibration, decide which subset of the E-16, E-17, E-18 and E-9 data is held out of fitting. If none, T1 and T2 stay "calibrated (in-sample)" | Decision recorded in `VALIDATION_GUIDELINE.md` §2.10 |
| 23f | **Freeze and date.** Record the date next to the criteria; any change after the first run makes that result calibrated with the changed parameter named | Dated, in this file and in §2.10 |

**Execution detail (Q5).** Output: a new section `VALIDATION_GUIDELINE.md` §2.12 "Source pre-registration (phase 23)", one table per check with the columns **ID · data (§2 ID) · cases · quantity · statistic · tolerance · pass rule · label if met · label if not met · date**. The agent drafts each row with the evidence listed below and marks the tolerance and pass rule [AUTHOR]; the author fills them in; then 23f dates them.

| Check | Evidence the draft must cite (constraints, not choices) | Decisions for the author |
|-------|--------------------------------------------------------|--------------------------|
| 23a BBN circumferential | Hand pre-check (§9 BBN appendix): differences from B·m·Δψ of 2–11° for pair 4-3 up to harmonic 7, 6–13° at harmonics 1–2 for pair 4-5 with coherence 0.97–1.00, 11–31° at harmonics 3–5 | Tolerance per harmonic (≥ ±15° at H1–2); pass rule (all pairs × harmonics, or a fraction); whether pair 5-6 counts; trace-velocity-ratio tolerance |
| 23a′ V-UNIT kinematic test (24b) | Exact relation Δφ = m·B·Δψ for a hub-centred ring in the rotation plane, static | Numerical tolerance (proposed 0.1°, from F1A time sampling with `num_src_times` ≥ 128) |
| 23b BBN in-plane levels | Loads cancel in ratios to mic 4; reflections present | Statistic (dB difference of ratios), tolerance |
| 23c Report 996 | Source-to-source spread: Fig. 7 legend C_P vs RM L8H25a −5 %/+11 %; Fig. 14 table C_P vs RM L8H25a +5 %/+15 %; Fig. 12 vs Fig. 14 overlap ≤ 6 %; digitization ≈ 0.5 % (log axes) | Tolerance on C_T, C_P (26) and on pressure per harmonic and total rms (27); whether a pass requires both polar sets or the bracket to straddle the measurement; the page-12 phase tolerance |
| 23d Pereira | ±1.7 dB (paper App. A) at harmonic 1; Fig. 7 phase reading ±2° | Harmonic-2 tolerance; phase-difference tolerance for ψ₁(φ) − ψ₁(0°) |
| 23e Held-out reservation | E-16 (D-17), E-17 (D-14), E-18 (D-15), E-9/E-10 (D-18) | Which subset is held out; if none, T1/T2 stay "calibrated (in-sample)" |

### Phase 24 — BBN/Wilby phase check *(done 2026-10-21; I-19 pair convention 2026-10-22, post-hoc)*

Decision 2026-10-16: the BBN/Wilby data (NASA CR-158919 static, CR-159124 taxi) are run first for phase. They already have measured phase between points on an aircraft fuselage, and the circumferential check needs only D, B, rpm and microphone positions. Needs phase 21 (shared function, which takes any observer list, so the observers are built from the microphone coordinates directly and `hub_observers` is not required) and the criteria of 23a–23b. Polars are not needed for the kinematic part; the run uses an assumed blade and reports the sensitivity to two assumed tip geometries.

| Step | What | Done when |
|------|------|-----------|
| 24a | **Data.** Transcribe the phase and coherence appendices, the trace-velocity tables and the Table 3/4 levels into `data\NASA_CR-158919\` and `data\NASA_CR-159124\` (**done by the author 2026-10-20/21**) with a README stating the uncertainties | CSVs and README present; spot-checked against the PDFs |
| 24b | **Exact kinematic tests (V-UNIT).** The B × m × Δψ relation for a hub-centred ring of observers, and the sign-convention test (measured angle positive upward against the rotation direction) | Tests pass before any comparison with data |
| 24c | **Circumferential run** through `evaluate_propeller_source` at the CR-158919 Fig. 1 microphone positions, static and taxi (`v_obs`), pairs and harmonics per 23a | Residuals and trace-velocity ratios recorded against the 23a criteria |
| 24d | **In-plane relative levels** of microphones 3–6 (23b) | Residuals recorded against the 23b criteria |
| 24e | **Longitudinal pairs** (rotation-plane microphones against X/D = 0.26 and 0.78) with an assumed blade; labelled X-EXTRAP | Run and reported as X-EXTRAP, never as validation |
| 24f | **9333C geometry beyond 40 in.** The Hartzell data below stop at 40 in (R = 46.5 in); get the outer 14% of the span (tip chord, tip thickness, section) from the manual, a data sheet or the manufacturer. Until found, 24e uses two assumed tip tapers | Source recorded, or "assumed" stated in every 24e result |

**What a pass supports.** "F1A phase between points in the rotation plane agrees with measurement, static and at taxi speed" (V-EXP, no fitted parameters), within the 23a tolerance. It does not show the phase output is correct in general. The exact kinematic tests, the sign-convention check and the independent-implementation comparison (phase 27) remain required. The microphones are on a reflecting surface and fuselage scattering stays V-ASSUMED, so the check includes reflections it does not model.

**Execution detail (Q6).** Data D-01–D-06 present in `data\NASA_CR-158919\` and `data\NASA_CR-159124\`; D-21 (rotation direction, hub position; card C-06) needed for 24b/24c; D-08, D-09 for 24e/24f only.

- [x] **24a (partial 2026-10-21).** Coherence cut in READMEs; `bbn_geometry.csv` (D-21 / I-09); loader `scripts/run/bbn_data.jl` (wide→long still I-14). Spot-check list still I-14.
- [x] **24b (2026-10-21).** `"BBN kinematics (24b, V-UNIT)"` in `Pkg.test()`: Δφ = m·B·Δψ within 0.5° (23a′); reverse sense flips sign.
- [x] **24c (2026-10-21).** `scripts/run/run_bbn_phase.jl` → `bbn_phase.md`; tipA/tipB × runs 4/2/5/7; 23a **FAIL** 26/168 (15%). F1A |Δφ| ≈ m·B·Δψ; measured signs often opposite (finding, not tuned).
- [x] **24d (2026-10-21).** Same script; in-plane vs mic 4 (23b, X-EXTRAP).
- [x] **24e (2026-10-21).** Fig.19 longitudinal sample (X-EXTRAP).
- [x] **24f.** Tip beyond 40 in not found; assumed tipA/tipB stated in every result.
- [x] Docs: README / flowchart / METHODOLOGY / VALIDATION_GUIDELINE / this file updated with 24 verdicts (33c claim wording still waits).

### Phase 25 — Report 996 verification setup *(done 2026-10-22 with 25g)*

Every Report 996 case calls `evaluate_propeller_source` (phase 21). No separate validation implementation of CCBlade → F1A → FFT is
allowed. Inputs come from the propeller data folder `propeller_sizing_and_analysis\propellers\naca_4-5-08-03`; what it contains and
what is missing is in [Report 996 data sources](#report-996-data-sources-inventory-and-gaps).

- [ ] **25a. Static probe (first).** `_ccblade_f1a_grid` silently replaces any `Vinf < 1` m/s with 20 m/s (lines 99-101); the code comment says
  a static propeller makes BEMT + F1A "ill-conditioned (near-DC pressure)". This is a guard in the PAIN code, not a documented
  requirement of CCBlade or AcousticAnalogies, and the failure has not been reproduced or tested. Reading the packages' current
  source (GitHub `main`; the pinned versions in `Manifest.toml` are 1.0.0 for both, not read) shows no obstacle: CCBlade has an
  explicit `Vx = 0` branch in `solve` and lists hover among supported inflows; the AcousticAnalogies CCBlade helper sets the source
  translation velocity to `Vx/cos(precone)`, so `Vx = 0` gives zero translation and nothing divides by `Vx`. Report 996 is static (V = 0),
  and a 20 m/s override would change the loads, so no Report 996 result may be produced with the override active.
  Write `scripts/checks/probe_static.jl` (it calls the shared function, with the guard bypassed by an explicit keyword) and check:
  (1) CCBlade alone at `Vx = 0`, M_t = 0.60, blade angle 10°, 15°, 20°: converges, finite T and Q, correct signs;
  (2) F1A with `v_obs = [0,0,0]`: finite harmonics, and the fundamental sits exactly on an FFT bin (the source period is exactly one blade-pass period);
  (3) continuity: the fundamental at `Vinf = 0, 1, 5, 20` m/s changes smoothly.
  If static works, remove the override and make any `Vinf < 1` request legal. If it fails, record where, use the smallest speed that
  works, and state it with every Report 996 result. Either way, never substitute silently.
- [x] **25b. Geometry.** `blade_form_geometry` + example JSONs (`scripts/run/build_report996_cfg.jl`). β(r) = β₇₅,target + (β_design(r) − 42.64°); truncate at r/R = 0.995; D = 1.2192 m; B = 2 or 4.
- [ ] **25c. Airfoil polars.** *(The polars are generated and recorded in phase 11; this item wires them in.)* `af(α, Re, M)` in `_ccblade_f1a_grid` is a clamped linear polar (`cl = 2π·α`). Use XFOIL-derived polars from the data folder:
  - **Primary:** the section fits in `analytical\sections.json`, built from `polars_forced.json` (forced transition, x_tr = 0.02), 10 NACA 16-series stations
    covering the full blade (t/c 0.01–0.13, c_l,design 0.1–0.5), with the calibration factors set to **1** (k_cl = k_cd = 1).
  - **Bracket:** the same fits with the data folder's calibration (k_cl = 0.92264, k_cd = 1.81815). These two factors were fitted to the forward-flight wind-tunnel data
    (RM L9G06a), not to Report 996, but they are fitted values and go in the register (`VALIDATION_GUIDELINE.md` §2.10).
  - **Optional third set:** `polars.json` (free transition). It is patchy (6 of 200 entries empty; XFOIL did not converge above 5–7° at many Re/M), so it needs the
    same fitting step before use. That fitting code is outside the data folder and was not read.
  - **Not used as polar sets:** `polars_cfd2d.json` (2 sections, one Re, M = 0.3, 3–4 angles; a spot check of the XFOIL values only) and `polars_thick.json`
    (thick root sections, t/c 0.20–0.30; this blade's root is t/c 0.134, which the thin set covers).
  - **Coverage gaps to fill by a stated rule, not by fitting:** the polars span α = −6° to +14°, M = 0.2–0.72, Re = 5×10⁵–4×10⁶. Report 996 needs M ≈ 0.12–1.0 and
    Re ≈ 3×10⁵–1.4×10⁶ along the blade (computed from `blade_form.csv`, standard sea-level air); inboard stations at blade angles of 10°–20° sit far above 14°
    (section pitch at r/R = 0.3 is 33°–43°; with a static inflow angle of roughly 14° there, α is about 20° at 10° blade angle and 30° at 20°; the inflow angle is my estimate from momentum theory, not a computed value). Extend each polar beyond its last XFOIL point to ±180° with a Viterna-type
    extrapolation (CCBlade ships a helper; confirm in the pinned 1.0.0 docs), clamp M and Re to the grid edges, and record every rule. Tip Mach above 0.72
    (M_t ≥ 0.75) is outside the grid: scaled runs are the test there and unscaled runs are flagged "polar Mach extrapolated". Nothing above M_t = 0.90 is tested.
- [x] **25d. Observers.** `hub_observers` in place (no default `x_sign`). Report 996 scripts use `x_sign=-1` (report “behind” → AA +X). Asymmetry confirmation vs Fig. 13(a) remains a 25k/27 item.
- [x] **25e. Conversions.** `total_rms`, `pressure_coefficient_pc`, `pa_to_dyne_cm2` / `dyne_cm2_to_pa` in `propeller_ccblade.jl` (25j tests).
- [x] **25f. Targets.** Copied `measured\noise\` and `measured\static\` into `data\report996\` with `MEASURED_NOTES.md` and `MEASURED_CHECKSUMS.txt`. Contents: Figs. 6, 7, 8
  (pressures), RM L8H25a static C_T and C_P, RM L51C27 thrust and torque. Figs. 12(a), 12(b), 13(a) and 14(a) were digitized from `rea-work\references\NASA Report 996.pdf` (300 dpi pages, axes fitted to the printed grid, hollow markers located by ring-template matching and refined to sub-pixel) into
  `data\report996\tr996_fig12_13a_14_digitized.csv`, with the script in `data\report996\tools\digitize_tr996.py` and overlays in `data\report996\qa\`. The Fig. 14 C_T/C_Q table is in `tr996_fig14_CT_CQ_table.csv` (read by eye from the printed table). Uncertainty: axis fit residual about 1.3 px (about 0.5% on the log-scale Fig. 14, about 1 dyne/cm² on the linear figures), marker centers ±1–2 px; one automated pass with checked overlays, not an independent second digitization. Within the report, Fig. 12 and Fig. 14 agree at x/D = −0.125 to 6% or better (M_t 0.75: mB 2 622 vs 661, mB 4 400 vs 400, mB 6 234 vs 229; M_t 0.90: 1301 vs 1298, 852 vs 841, 554 vs 547 dynes/cm²), so no pass tolerance can be tighter than that. Digitization is one automated pass with QA overlays (about 60 px per grid cell; the tails of Figs. 6/7
  are good to about 5–10 dyne/cm² or 0.005 in p_c/CP; 27 rows are manual readings), not two independent passes. Spot-check at least three points per figure against the PDF at high
  resolution. **Not in the data folder:** Report 996 Figs. 12, 13 and 14 (now digitized, see above). Fig. 11 (per-harmonic pressure vs C_P in the plane of rotation, M_t 0.75/0.90/1.00) and Fig. 13(b) are not digitized (13(b) is M_t = 1.00, out of scope). The page-12 phase values are in the report text (checked in `NASA Report 996.pdf`):
  165° from Eq. (2) and 155° measured at M_t = 0.75, and 125° from Eq. (2) at a larger blade angle (no measurement for the 125° case).
- [x] **25g (done 2026-10-22; see §8 "Step 25g done").** Scope and criteria first.** Test range: tip Mach 0.45 to 0.90. Nothing above 0.90 is tested (Figs. 13b, the 1.00 points of Fig. 14 and Fig. 8, and RM L51C27 rows at 1.00 and above are recorded but out of scope).
  The polar Mach grid stops at 0.72, so unscaled runs at 0.75–0.90 are flagged "polar Mach extrapolated"; scaled runs are the cleaner test there. No quadrupole term is modeled, which matters most near 0.9.
  The criteria themselves: Write the pass criteria for phases 26 and 27 into this file before any comparison (rule 3 in `VALIDATION_GUIDELINE.md` §2.3.1). One piece of reference
  scatter is already visible without running the code: the Fig. 7 legend C_P at M_t = 0.60 (0.0424 at 15°, 0.0818 at 20°) differs from RM L8H25a (0.0449, 0.0739) by −5% and +11%.
  Use that kind of source-to-source spread, not code results, to set the tolerance.

**Further steps of phase 25 (added 2026-10-20).** Needs D-07.

- [x] **25h [CONFIRM] `ScaledLoads`.** `struct ScaledLoads; T_target::Float64; Q_target::Float64; end`. In `evaluate_propeller_source`, after `CCBlade.solve`: s_T = T_target/T, s_Q = Q_target/Q; scale the section normal force N_p by s_T and tangential force T_p by s_Q; rebuild the CCBlade `Outputs` (confirm the 1.0.0 constructor and that `f1a_source_elements_ccblade` reads N_p, T_p from it); recompute T, Q and check they equal the targets to rtol 1e-9; put s_T, s_Q and `loads = ScaledLoads(...)` into the echo. Test: scaled run reproduces the targets; amplitude scales linearly with a uniform s_T = s_Q (loading-only, thickness off).
- [x] **25i [CONFIRM] Polar loader.** `load_polar_set(path; set=:primary|:bracket, viterna=nothing) -> (af, stats)`: reads `polars_forced_merged.json` (Report 996, through the `sections.json` fits with k_cl = k_cd = 1 for `:primary`, the `tables.json` calibration for `:bracket`) or `naca4412_xfoil_<setting>.json` (Pereira); linear in α inside the converged range, Viterna record (`viterna_extension.json`) outside it, bilinear in (log Re, M) between grid points, clamped at the grid edges; per-section selection by radius (nearest station or linear between the two nearest; state which). `stats` counts clamped Re, clamped M, Viterna evaluations and nearest-polar substitutions; every run prints them. α in radians at the interface (CCBlade convention). Tests: knot values reproduced to 1e-12; clamp counters increment; c_l continuous at the Viterna junction within 1e-6.
- [x] **25j Conversions (V-UNIT tests).** `total_rms` / `pressure_coefficient_pc` / Pa↔dyne; tests in `runtests.jl` (2026-10-21).
- [x] **25k Report.** `scripts/run/report996_setup.jl` → `docs/validation_reports/report996_setup.md` (2026-10-21): behind>ahead **true**; rms <0.1 dB from harmonic **n=7**; polar coverage + blade-angle shift recorded. Absolute F1A levels still ≫ measured (near field).

### Phase 26 — CCBlade check *(done 2026-10-21; criteria registered after the loads)*
Compare CCBlade thrust and power coefficients with measured static data at the same blade angle and tip Mach, for each polar set (primary, bracket).
- [ ] **Static C_T and C_P:** RM L8H25a Figs. 10/11 (blade angles 0°–40°; M_t 0.3–0.9, but 20° only to ~0.65 and 10° to ~0.83), target blade angles 10°, 15°, 20° at M_t = 0.45 and 0.60.
  A blade angle of 8° has no measured curve (5° and 10° only); interpolating is allowed but flagged.
- [ ] **Fig. 7 legend:** C_P = 0.0195, 0.0424, 0.0818 at 8°, 15°, 20° (B = 2, M_t = 0.60).
- [ ] **RM L51C27:** static thrust and torque of the 47-in. propeller at 15° for M_t 0.75 and 0.90 (and torque at 13°); rows above 0.90 are out of scope. Thrust and torque at 15°, M_t 0.75 are the scaling inputs for Fig. 13a.
- **Fig. 14 table (the report's own loads):** β₇₅ = 10°, B = 2: C_T = 0.070, 0.072, 0.075, 0.080 and C_Q = 0.0037, 0.0042, 0.0044, 0.0051 at M_t = 0.45, 0.60, 0.75, 0.90 (1.00 is out of scope). The report says its Eq. (2) points used these; whether they are measured
  or computed is not stated. C_T agrees with RM L8H25a (0.0706 at 0.45, 0.0718 at 0.60); C_P = 2π C_Q gives 0.0232 and 0.0264 against RM L8H25a 0.0221 and 0.0230 (+5% and +15%), which shows the spread between sources.
- Coefficient definitions: C_T = T/(ρ n² D⁴), C_Q = Q/(ρ n² D⁵), C_P = P/(ρ n³ D⁵) = 2π C_Q.
- **Expected outcome, from the data folder's own BEM (not from this code):** its static table at 20°, M_t = 0.60 gives C_T = 0.0719 vs measured 0.1048 (−31%) and C_P = 0.0700 vs
  0.0739 (−5%), and for Report 1079 at 15°, M_t = 0.75 thrust −12% and torque −35%. So scaling to measured loads in phase 27 is not optional, and a C_T / C_P mismatch is a
  statement about the polars and the stalled inboard sections, not about CCBlade or F1A. Do not retune the polars to close it (rule 1).
- **Output of this phase:** the scale factors T_meas/T_CCBlade and Q_meas/Q_CCBlade for each case. Phase 27 uses them.

**Execution detail (Q8).** Script `scripts/run/run_report996_loads.jl` → `docs/validation_reports/report996_loads.md` and `data/report996/scale_factors.csv` (`case, polar_set, beta75_deg, M_t, B, T_ccb_N, Q_ccb_Nm, CT_ccb, CP_ccb, T_meas_N, Q_meas_Nm, CT_meas, CP_meas, s_T, s_Q, source_of_measured`). Cases: β₇₅ = 10°, 15°, 20° at M_t = 0.45, 0.60 (RM L8H25a); 8°, 15°, 20° at 0.60 (Fig. 7 legend C_P); 15° at 0.75, 0.90 (RM L51C27); 10° at 0.45–0.90 (Fig. 14 table). Static (V = 0) per 25a. Every row reported for both polar sets with the polar `stats`; verdict against 23c; no polar change after the run (R2).

### Phase 27 — AcousticAnalogies check *(done 2026-10-21)*
Run `evaluate_propeller_source` at the report's observer positions and compare with the measured **total rms** pressure. Each case is run four ways:
{primary, bracket} polar set × {`loads=:ccblade`, `loads=ScaledLoads(T_meas, Q_meas)`}. The unscaled runs show the end-to-end CCBlade + F1A result; the scaled runs isolate F1A.
Report them side by side; do not pick the best.
- [x] **Fig. 7 (blade loading), B = 2, M_t = 0.60, d/D = 0.083, β=15° smoke:** p_c/C_P vs x/D recorded in `report996_acoustics.md` (8°/20° still optional). Verdict waits 23c.
- [x] **Fig. 6 (tip clearance), B = 4, 10°, M_t = 0.60:** clearance ratios of max total-rms recorded (unscaled; no B=4 T/Q). Absolute level informational.
- [ ] **Fig. 8 (p_c vs C_P at x/D = 0, d/D = 0.042), B = 2 and 4, M_t = 0.60 only:** optional loading-sensitivity; deferred (needs multi-C_P sweep).
- [x] **Fig. 14 (per-harmonic vs tip Mach):** recorded 2026-10-21 (scaled to table C_T/C_Q); residuals huge near field — verdict waits 23c.
- [x] **Fig. 12(a), (b) (per-harmonic vs x/D):** recorded 2026-10-21 (`f1a_results.csv`); Fig. 12(c) out of scope; verdict waits 23c.
- [x] **Fig. 13(a):** first harmonic vs x/D recorded (scaled with Fig.14 proxy for β=10° loads — RM L51C27 15° scale preferred if added); behind>ahead confirmed; Eq. (2) curve still not digitized (C-13 optional).
- [x] **Phase (page 12):** recorded at |x/D|=0.125 candidates (stations not uniquely stated in the report): F1A Δφ vs measured 155° / Eq.(2) 165° in `report996_acoustics.md`. Verdict waits 23c.
- [ ] **Optional cross-checks with other methods (not required for the stated claim).** The decision is that these papers validate BEMT (CCBlade) and F1A only, so no alternative method is needed. If wanted later, compute the report's Eq. (2) (Gutin with loads at an effective radius R_e, which is
  fitted) and a Hanson near-field frequency-domain prediction as separate functions, and compare them with F1A. They are comparators, not part of the shared source function.
  `VALIDATION_GUIDELINE.md` §2.3.3 says what this does and does not show. The data folder's `noise_vs_measured.json` already holds far-field Gutin and Hanson results for the
  Report 1079 cases (subsonic rms error about 0.7–0.8 dB against Fig. 7); those are far-field (9 m) and say nothing about the near field.

Pass criteria: set in 25g, not here. The earlier placeholders (fundamental within 3 dB, harmonics 2–3 within 6 dB) are withdrawn. Keep thickness off
(`thickness_over_chord = 0`) for the first pass, since the report's theory is loading-only, then run one thickness-on case per figure as a sensitivity (not a thickness validation; see `VALIDATION_GUIDELINE.md` §2.3.3). Scope is M_t ≤ 0.90; treat the 20° blade angle (stalled) as informational.

**Execution detail (Q9).** Script `scripts/run/run_report996_acoustics.jl` → `docs/validation_reports/report996_acoustics.md`, CSV `data/report996/f1a_results.csv` (`figure, case, polar_set, loads, x_over_D, d_over_D, harmonic, A_Pa, phase_rad, p_rms_total_Pa, p_c`). For each figure item above: the four-way table, the measured value, the residual in dB and in %, and the 23c verdict, side by side; thickness-off first, then one thickness-on case per figure (sensitivity). Observers from `hub_observers` with the `x_sign` fixed in 25a. The page-12 phase: Δφ between the two x/D points fixed before the run (read from the report and Fig. 13(a); write them into 23c).

### Phase 28 — Forward-flight check against Pereira et al. (2026) *(done 2026-10-21)*

Report 996 is static, but the aircraft path runs with forward speed. Pereira et al. (paper read in full on 2026-10-16) (*Aerospace Science and Technology* 177, 112963)
measured an isolated 0.3 m, 2-blade propeller at 8,000 RPM and 16 m/s (J = 0.4, tip Mach 0.37). Validity limits and rules are in
`VALIDATION_GUIDELINE.md` §2.3.2. This is a far-field check (microphones at 1 m); it does not replace the Report 996 near-field check.
It uses the same `evaluate_propeller_source` as production and Report 996 (phase 21), with `hub_observers`-style placement on the 1 m arc.

- [ ] **Geometry.** APC 9×6 scaled to D = 0.30 m with a NACA 4412 section, 2 blades; chord and twist are plotted in Fig. 1 and tabulated in Grande et al. (2022, AIAA J. 60(9), ref. [17] of the paper). Mean chord 22.85 mm; tip chord about 10.5 mm (derived: the paper gives BPF-10 as 12 tip chords at 0.127 m). Digitize or obtain the table, record the source.
- [ ] **Airfoil polars (NACA 4412, generated here; the paper gives none).** Specification and recording location are in
  [Pereira NACA 4412 polar specification](#pereira-naca-4412-polar-specification) below.
- [ ] **Loads (Table 3).** CCBlade thrust and torque vs the measured 14.55 ± 0.01 N and 0.4133 ± 0.0002 N·m (C_T = 0.0825). The
  paper's own BEMT gives 14.56 N and 0.4338 N·m. Run unscaled and with loads scaled to the measured T and Q, for both polar sets (same
  4-way table as phase 27).
- [ ] **Phase check (digitized, see the phase-validation figure list below).** Fig. 7 of the paper has **three panels, φ = 0°, 20° and 40°** (not only φ = 0° as I first read), each showing the phase-lock-averaged pressure over one rotation for experiment (4,000 rotations), CFD (50 rotations) and the BEMT-based prediction, all against the propeller phase angle from one encoder. That gives the first-harmonic phase at three microphones in forward flight, so the phase *between* microphones (0° to 40°) can be compared with F1A. From the digitized curves (`data/pereira/pereira_fig7_harmonics.csv`, harmonic phase ψ₁ in degrees of the first-harmonic cycle, p' = A cos(2θ − ψ₁)):

  | φ | Experiment ψ₁ (A, Pa) | CFD ψ₁ | BEMT-based ψ₁ |
  |---|-----------------------|---------|---------------|
  | 0° | 167.3° (0.458) | 173.7° | 175.1° |
  | 20° | 179.2° (0.470) | 176.0° | 182.7° |
  | 40° | 186.6° (0.381) | 192.1° | 197.5° |

  The experimental phase advances by about 19° of the first-harmonic cycle (about 10° of propeller rotation) from φ = 0° to 40°; the paper's BEMT-based prediction advances by about 22° and the CFD by about 18°. Estimated reading uncertainty is about ±2° (2 pixels), so these are consistent within the reading uncertainty, but one digitization pass does not show accuracy. The BEMT-based first-harmonic amplitude at φ = 0° is 0.39 Pa against 0.46 Pa measured (about 1.4 dB, inside the paper's ±1.7 dB). Limits: the encoder zero relative to a blade is not stated, so compare phase *differences between microphones* (and treat absolute offsets as informational: the paper's own prediction sits 3° to 11° of harmonic phase from the experiment); the second-harmonic phases are low confidence (amplitudes 0.03–0.08 Pa, comparable to the fit residual); the BEMT-based φ = 20° curve fits less well than the others. Use: run F1A (thickness on and off) with the Pereira geometry and polars at the three microphone positions with `v_obs` stated, fit the same harmonics, and compare ψ₁(φ) − ψ₁(0°).
- [ ] **Thickness.** The paper's BEMT-based method uses compact dipoles for loading and monopoles for thickness, and the CFD FW-H surface includes thickness, so a thickness-on F1A run (t/c from the NACA 4412 section, 12%) is consistent with both. The measurement cannot separate thickness from loading, so this is still not a thickness validation.
- [ ] **dB(A) cross-check.** Table 4 gives OSPL 84.6 dB (experiment), 83.4 (BEMT-based) and 84.7 (CFD) and dBA 77.3, 76.2, 76.8 at φ = 0°. The A-weighting step in `metrics.jl` can be checked on the F1A tones at φ = 0° (tones only; the paper's dBA includes broadband, so the experimental dBA is an upper bound for a tones-only value, and the BEMT-based dBA is tonal only).
- [ ] **Observers.** Seven microphones on a 1 m arc from the hub at φ = −20° to 40° in 10° steps (Mic 1 to Mic 7). Fig. 2b fixes the convention: φ = 0° is the rotation plane (Table 4), **positive φ is downstream** (toward the flow direction, the +x side of the sketch), negative φ is upstream; the paper's text agrees (BEMT levels lower "towards the upstream direction"). The propeller sits 0.3 m from a 0.6 m nozzle.
- [ ] **Compare.** Overall level at φ = 0° (Table 4: experiment 84.6 dB, CFD 84.7 dB, BEMT-based 83.4 dB), harmonic SPL for harmonics 1–2
  (Figs. 6, 9), phase-averaged pressure history (Fig. 7), directivity (Fig. 8).
- [ ] **Alternative-method comparators.** The paper's own BEMT-based compact-source prediction is already one comparator; add Gutin / Hanson far-field
  on identical loads if the §2.3.3 comparison is wanted for forward flight (far-field forms suffice at 1 m ≈ 3.3 D).
- [ ] **Pass criteria.** Set from the reference's scatter after digitizing, before running: the paper quotes about ±1.7 dB for the first harmonic (Appendix A). The second harmonic is 2.7 dB above the paper's BEMT-based prediction;
  harmonics 3 and above are informational (motor noise at the 3rd, 6th, 7th; more than 5 dB disagreement above the 4th, and the paper notes the measured tonal levels above the 4th are around 40 dB, possibly contaminated by broadband or motor noise).
- [ ] **Observer velocity.** State how the observer motion is set (`v_obs`) and that the microphones are outside the tunnel jet.

**Execution detail (Q10).** Needs D-11, D-12, D-13 (cards C-01, C-03, C-04; C-02 is a cross-check) and the 25i loader.

- [ ] Config `examples/pereira_apc9x6_scaled.json` built by a script from `pereira_fig1b_chord_twist.csv` (R = 0.15 m, chord = c/R × R, twist as digitized, hub at the first digitized station 0.30R, tip at 0.99R), B = 2, 8,000 rpm, V = 16 m/s, ρ and c0 from the paper if stated (else standard sea level, stated).
- [ ] Script `scripts/run/run_pereira.jl` → `docs/validation_reports/pereira_forward_flight.md`. Observers: seven on the 1 m arc, φ = −20° to 40° in 10° steps, `x = [x_sign·sinφ, cosφ, 0]` m with positive φ downstream (Fig. 2b); state how the observer motion relative to the medium is set (`v_obs`). Runs: three polar sets × {unscaled, `ScaledLoads(14.55 N, 0.4133 N·m)`} × {thickness off, on}.
- [ ] Outputs: loads table against Table 3; harmonics 1–2 SPL at each φ against D-10/D-12 (23d); ψ₁(φ) − ψ₁(0°) from a fit p' = mean + Σ A_k cos(2kθ − ψ_k) of the F1A time history, the same form as `pereira_fig7_harmonics.csv`, against the experimental differences; tones-only dB(A) at φ = 0° through `metrics.jl` against Table 4 (experimental dBA is an upper bound).

---

## 7. Aircraft-cabin phases 29–31 *(done 2026-10-22; moved to the bottom 2026-10-22)*

### Phase 29 — Aircraft cabin inputs: audit, guard, provenance, required inputs *(done 2026-10-22)*

Why: the cabin blocks carry NASA test-article constants (1.016 m shell, Phase III trim, curves shaped to that trim). The aircraft has a different diameter, trim and propeller, all supplied by the user (2.64 m is the working example, not a fixed value), and there is no experiment to tune against, so those constants must not reach an aircraft result silently. Step 29a is documentation only and can be done at any time before this point; the code steps wait for confirmation.

| Step | What | Done when |
|------|------|-----------|
| 29a | **Audit.** List every hard-coded NASA-test-article value reachable from the aircraft path. Today: the `V` and `S` defaults in `acoustic_loss_factor` (radius 0.508 m, length 1.803 m), `TrimPanel()` defaults, the η_a, η_s and absorption curves, the Table D-1 hybrid modes, the CYL2D and fuselage geometry defaults, `bb_j2_scale`, the H = 3 anchor. After 15a–17a: the Fig. A-2 insulation table (PF-105), the Phase III sidewall and end trim stacks, the sidewall surface mass from the MRP constants (skin, stringers, frames), the end-plate mass (1.3 cm aluminium), the 13a(f) assumed values, c0 and ρ0, and the absorption curve and `bb_j2_scale` of the high-frequency path (30b) | Table in `VALIDATION_GUIDELINE.md` §2.10 marked "test-article-specific", one row per value |
| 29b | **Guard.** Warn, and mark the result, whenever an aircraft run uses a test-article default; no silent fallback (the same idea as the `Vinf < 1` guard). A code change, **waits for confirmation** | An aircraft run with any NASA default is flagged in the output and the report |
| 29c | **Provenance tags.** Every cabin input is tagged measured, assumed or NASA-default; the tag is carried into the result and the report. An aircraft result that uses any NASA-default is labelled as NASA's article, not as the aircraft | Tags in the input schema and the report template |
| 29d | **Required-input list for the user.** Geometry, skin, stringers, frames, floor, trim stack (layer order, thicknesses, limp masses and loss factors, the insulation table λ_m, α, φ, \|W\| against frequency as in Fig. A-2, mechanical connections), end-plate mass and trim, bare-cabin η_n if untrimmed, C of Eq. (80), cabin volume, from the User Manual PAIN/MRP inputs and CR-3813 App. A | List in `METHODOLOGY.md` |

**Outputs.** 29a: rows in `VALIDATION_GUIDELINE.md` §2.10 tagged "test-article-specific" (file, line, value, source). 29b [CONFIRM]: a `NASADefaultUsed` warning and a `provenance` field in the run result. 29c [CONFIRM]: tag field per input in the aircraft JSON schema (`"value"`, `"tag": "measured" | "assumed" | "nasa_default"`). 29d: the list in `METHODOLOGY.md`, which is also the template for D-20.

### Phase 30 — Parametric cabin blocks *(done 2026-10-22)*

Make the cabin blocks general in the aircraft inputs so that no test-article curve is needed on the aircraft path. Loss factors predicted this way are the quantity NASA found about 10 dB off at H1 on its own article, so this phase reduces arbitrariness, not uncertainty; the uncertainty plan (phase 31) carries that size.

| Step | What | Done when |
|------|------|-----------|
| 30a | **Trim:** the App. A matrices move to 16a. What remains here: aircraft trim stack inputs from the user | Aircraft stack supplied and tagged |
| 30b | **Loss factors:** the tonal loss factors move to 16b. What remains: the high-frequency path of Eqs. (16)–(24) (α̅ from Eq. (24)/(78), the average radiation loss factors Eqs. (84)–(85)) in place of the absorption curve and `bb_j2_scale` | Computed from the user-supplied geometry (any diameter, 2.64 m being the working example); no 0.15 cap or test-article curve on the aircraft path |
| 30c | **Modes:** structural modes from the raw Ritz solver with the aircraft inputs (no Table D-1 hybrid on the aircraft path); CYL2D and the volume and area arguments take the aircraft geometry | Aircraft run uses no D-1 value and no hard-coded V, S |
| 30d | **Test-article regression:** with the test-article inputs, run the parametric blocks and compare with the tuned surrogate and with Figs. E-16, E-9. Record the shift in the loss factors and in H1–H3 | Shift recorded. This is direct evidence of the error from predicting loss factors without tuning, the input to phase 31 |

**Outputs.** 30b, 30c are `src/` changes [CONFIRM]. 30d: script `scripts/parametric_regression.jl` → `docs/validation_reports/parametric_regression.md` (loss factors and H1–H3 against the current chain and Figs. E-16, E-9; the shift is the input to 31a). If 30d changes the frozen baselines, the renewal is a dated author decision (R11).

### Phase 31 — Uncertainty plan for the aircraft cabin result *(done 2026-10-22; result in §8 "Phase 31 done")*

Grade of the aircraft result: X-EXTRAP with an epistemic band. Not a validation and not a statistical confidence interval. The steps below are provisional until the design is agreed; criteria are fixed in writing before any aircraft run, and a change after seeing results makes the result post-hoc.

Design rules agreed so far:
- The budget uses the inputs of the CR-3813 chain (trim stack, η_t, C, η_n when bare, mode frequencies, blocking, and `bb_j2_scale` until 30b replaces it), each tagged by provenance (phase 29c). Test-article tuned values are not inputs.
- The source side uses the residuals from phases 24, 26, 27, 28 (amplitude, phase, polar bracket, Pereira's ±1.7 dB). GEXT is not in the aircraft-path budget.
- The size of the loss-factor effect comes from phase 30d and from NASA's own pre-tuning discrepancy at H1 (about 10 dB on the test article). That discrepancy is evidence of magnitude, not a bound.
- Phase and scattering/refraction are handled by bounding cases and stated conditions, not invented ranges. The phase bounding case uses the BBN residual; fully random phase is the extreme case only.
- The reported band is not widened by the measured scatter of Fig. E-16 (that scatter is test-condition variability, not model uncertainty).

**Decisions recorded 2026-10-19**
- **Aircraft inputs are user inputs.** Diameter and every other cabin input (skin, stringers, frames, floor, trim stack, damping) are supplied by the user and can be changed; 2.64 m is the working example. An input the user marks measured is tagged **measured** and drops out of the budget; any input left at a default or marked assumed is tagged **assumed** and enters the budget, and the result carries those tags. For the working example only the 2.64 m diameter is given, so every other cabin input is assumed.
- **The ranges below are registered for the working example (diameter ratio 2.60 to the 1.016 m test article).** They are a function of the inputs, not constants of the plan: if the user supplies a materially different diameter or trim, the author confirms the ranges or re-registers them before the run (post-hoc if after seeing results). The budget, the coverage check and the report are all generated from the user's inputs and their provenance tags.
- **Loss-factor ranges are set a priori, not fitted.** The documented values are not measured; the ranges are a transferability allowance for an unknown trim installation and construction on a larger fuselage.

  The rows are the inputs of the CR-3813 chain of 16a–17a (the surrogate parameters `η_trim` and the E-15 trend are removed there). They are the 13a ranges; a change in one place is made in both.

  | Parameter | Nominal | Range | Basis (stated by the author; ranges are assumptions) |
  |-----------|---------|-------|------------------------------------------------------|
  | Lining and facing flexural loss factor η_t (Eq. A.11) | 0.05 | 0.01 to 0.10 | Not given in CR-3813 (13a f); limp vinyl and G-10 septum, soft-mounted |
  | C of Eq. (80), η_r^struc = C/f_r | 3 | 2 to 4 | CR-3813 §3.8.2 range |
  | Bare-cabin acoustic loss factor η_n (only when no trim, §3.8.1) | 0.05 | 0.02 to 0.10 | A measured quantity in CR-3813; assumed here (13a g) |
  | Trim stack alternatives (facing side, mechanical connections, lining wavespeed) | 13a f | 13a f | Run as discrete alternatives, not sampled |
  | Insulation table outside its measured range | none | X-EXTRAP extension (13a e) | Only when the aircraft table does not cover the harmonic |

  **Why 31e runs after 17a and phase 30, not on the old surrogate.** In the old surrogate the trim transmission went as 1/(1 + 0.5·η_trim) and the structural loss entered as 1/η, so the ranges could move the interior SPL by only about 3 to 4 dB each. That was a property of the surrogate, not of the physics: NASA's roughly 10 dB discrepancy at H1 on its own article cannot come from that lever. The ranges above are therefore ranges on the inputs of the CR-3813 chain (16a–17a: App. A transfer matrices, Eqs. 77–83, Eq. 8), whose sensitivity is physical, and the coverage check is run on that chain. Phase 30d shows which terms actually move H1; if the two loss-factor ranges are not enough to reach the observed discrepancy there, the budget gains the transmission-model and modal terms 30d identifies, before the check is run. A band that cannot reach a discrepancy already seen on the test article is a budget error to fix in 31a, not a result to expect in 31e.
- **Thresholds:** the decision-grade thresholds (±6 dB at H1 and ±8 dB on dB(A)) are dropped. The band, its drivers and the stated conditions are the output. Kept: the statement that phase is the dominant uncertainty when its bounding-case spread exceeds the Monte Carlo band (stated first). If 31e fails, the aircraft band is reported only with the revised ranges, labelled post-hoc.

| Step | What | Done when |
|------|------|-----------|
| 31a | Define the budget rows: nominal, range, basis, provenance, type, starting from the rows above and adding mode frequencies, CYL2D grid choice (13a b), axial truncation (13a d) and blocking with stated assumed ranges, and the source-block residuals from phases 24–28 | Table written and dated |
| 31b | One-at-a-time sensitivity ranking at the aircraft geometry | Ranked table, parameters above 3 dB kept |
| 31c | Bounding cases for phase and the stated condition on scattering/refraction | Spread recorded as its own line |
| 31d | Monte Carlo over the kept parameters; distributions, N and seed fixed before running; repeat once with a different distribution family | Percentiles, rank correlations, sensitivity to the distribution |
| 31e | **Untuned coverage check on the test article, after phase 30d.** Run the untuned parametric chain (phase 30) on the NASA test article with the a-priori ranges above and build the band from them; the band must cover the measured Fig. E-16 means at H1–H3 (and Figs. E-21/E-22 once digitized). No tuned value and no E-16 envelope floor enter the band, so the check can fail | Coverage recorded per harmonic. A failure means the budget is missing a contributor or the ranges are too narrow: fix and re-register as post-hoc |
| 31f | Reporting template fixed before any aircraft run. Required statements: the band is epistemic and not a confidence interval; it excludes scattering and refraction (V-ASSUMED); it is conditional on the transferability allowance above; every cabin input except the 2.64 m diameter is assumed; the result is not validated and is not NASA's accuracy (do not quote the +2.6 to +4.3 dB flight bias or "10 dB" as an error bar for this aircraft). Report median and percentiles, never the mean, and no single dB value without the band | Template and the phase-dominance rule written down |

---

## 8. Phases 32–38 *(done; moved to the bottom 2026-10-22)*

**Phase 35 — Test audit, validation maps and the "Validation map" GUI tab** *(done 2026-10-21; see §11).*

### Phase 32 — GEXT importance bound (e11 path) *(done 2026-10-21; §11)*

Pre-registered 2026-10-19, before any run. Full specification: `VALIDATION_GUIDELINE.md` §2.2.1 (variants, statistic, flip predicate, claim-status table).

**Runs after 18a.** 12b moves the grid and changes the falloff to cos(θ − φ_p); 18a replaces the calibrated cabin with the untuned CR-3813 chain. The cabin inputs are those of 18a, held fixed; "the existing T1 gate" means the T1 criteria of `VALIDATION_GUIDELINE.md` applied to the 18a result. The variants, statistic and flip predicate are unchanged; re-date them in §2.2.1 before the first run.

**Why.** GEXT is the one assumption the e11 cabin test cannot validate: on ℓ = 1, θ − φ_p = 0 and R = R0, so the falloff and delay are constant on the only measured line and cannot be fitted to or checked against it. GEXT stays V-ASSUMED, unfalsifiable by published data. T1 and T2 are compared with the data they are tested on, so this phase measures **importance** (how far the T1 verdict moves when GEXT moves), not circularity and not correctness.

**Steps**

| Step | What | Done when |
|------|------|-----------|
| 32a | Add `falloff_exponent`, `falloff_floor`, `delay_scale` to `extend_line_to_grid`; defaults are the nominal GEXT and reproduce it exactly | **Added 2026-10-19** with a code-only test in `test\runtests.jl`. **Not yet run**: run `Pkg.test()` first |
| 32b | Identity control: n = 1, f = 0, delay ×1 reproduces the nominal T1/T2 exactly | Identical numbers recorded under `docs\validation_reports\` |
| 32c | Falloff grid: n ∈ {0.5, 1, 2} × f ∈ {0, 0.1, 0.3} plus n = 0 (10 runs including nominal), 18a cabin inputs held fixed | Per-H T1 residuals (max, RMS, pooled RMS), margins to the T1 gate edges, and flip yes/no recorded; T2 offset recorded against 10·log₁₀(mean f²_variant / mean f²_nominal) |
| 32d | Delay variants (falloff nominal): off, sign flip, ×0.5, ×2. Add the n = 0.5 + delay ×2 corner only if delay is non-null on T1 | Same statistics recorded. If sign flip and ×2 are both exactly null on T1, delay moves to the sanity bucket and the null is logged as a code/data finding |
| 32e | Parameter-sensitivity comparator: one-at-a-time over the 13a ranges of η_t, C and the trim-mass scale (±20 %), `bb_j2_scale` (T2 only) | **Done 2026-10-21** in `gext_importance_bound.md` (ΔH1 up to ~1.5 dB vs GEXT flips) |
| 32f | Write the T1 claim status into `METHODOLOGY.md` from the consequence table; record the GEXT register entry (no fitted parameters, form attested a priori) | **Done 2026-10-21** — T1 not claimable |

**Rules.** Primary criterion: does any variant flip the existing per-H T1 gate (mean ± 4.0 dB OR NASA ±4.0 dB within the envelope), any-H rule. All variants and the statistic are fixed before the run. A variant that improves the residual is reported as a finding and is not adopted unless relabeled calibrated; an exploratory cross-fit is the follow-up. T2 sees GEXT only through the grid-mean H = 3 amplitude² anchor that `bb_j2_scale` absorbs, so it is reported as a computed offset, not a test. Refraction and scattering stay out of the test and stay V-ASSUMED.

**Claim status after the run** (beside GEXT's grade, which stays V-ASSUMED either way)

| Result | T1 claim status |
|--------|-----------------|
| No variant flips | calibrated (in-sample against E-16/E-17); the in-sample fit is robust to GEXT over the stated bracket; conditional on refraction and scattering being V-ASSUMED |
| Any variant flips | T1 verdict depends on GEXT; not claimable even under the V-ASSUMED refraction and scattering assumptions |
| A variant improves the residual | finding; not adopted unless relabeled calibrated; exploratory cross-fit |

**Execution detail (Q14).** Re-date the variants in `VALIDATION_GUIDELINE.md` §2.2.1 before the first run (cabin inputs = 18a-r, η_T = 0.5). Run `Pkg.test()` first (32a test never run). Script `scripts/run/run_gext_bound.jl` → `docs/validation_reports/gext_importance_bound.md`: one table per step 32b–32e with, per variant and H, the T1 value, residual to the mean and to NASA, margin to the gate edges and flip yes/no; T2 offset against 10·log₁₀(mean f²_variant / mean f²_nominal). 32b must reproduce `phase20_baseline.md` exactly.

### Phase 33 — Close-out *(done 2026-10-21; §11)*

Runs after every source check (phases 24, 26, 27, 28) and the GEXT importance bound (phase 32) so the calibration decision and the claims see all the results.

| Step | What | Done when |
|------|------|-----------|
| 33a | **Summarize the cross-checks from phase 27** (Gutin Eq. 2 and Hanson near-field against F1A on identical loads). Fig. 17 (Gutin simplified vs Eq. 2) is the far-field limit check. Eq. (2) needs an effective radius R_e (0.7R–0.9R, Fig. 15), which is fitted, not independent physics. Write the claim wording from `VALIDATION_GUIDELINE.md` §2.3.3: accuracy at the listed cases, not "better than" the other methods | **Done 2026-10-21:** optional Gutin/Hanson comparators **not run**; claim wording = accuracy at listed cases only (no "better than"); recorded in `METHODOLOGY.md` §9 |
| 33b | **Calibration decision.** If F1A matches the report without the Table-8 peak calibration, drop it (option b in open decision 1 under phase 21) | **Done 2026-10-21:** raw F1A does **not** match (23c FAIL; smoke −4.2/−5.3/−5.8 dB) → **keep** optional Table-8 peak calibration as X-EXTRAP post-step; never compare calibrated path to Table 8 (I-12/B-5) |
| 33c | **Claims.** Update `METHODOLOGY.md` and `VALIDATION_GUIDELINE.md` from the results of phases 19, 24, 26, 27, 28 and 32: the phase 19 findings on the cabin chain, BBN circumferential phase (phase 24), static loading-only case at the listed harmonics (class V-EXP, limited scope), forward flight only by phase 28 (far field, harmonics 1–2), GEXT claim status from the phase 32 table; the aircraft path stays X-EXTRAP | **Done 2026-10-21** — aircraft path **X-EXTRAP**; no V-EXP claim for CCBlade/F1A free field |
| 33d | **Regrade the cabin sub-function rows** in `VALIDATION_GUIDELINE.md` §2.7 (trim transfer matrix, loss factors, power balance) from "V-EXP, calibrated" to "calibrated (in-sample)", the same grade as T1/T2 | [x] Done 2026-10-19. Superseded by 18a, which grades these rows from the untuned chain (V-CODE where checked against NASA calculated curves, 13b) |
| 33e | **Stale phase numbers in a code comment.** `propeller_ccblade.jl` header should name Report 996 / Pereira / phase 33. Comment edit; author “approve everything” 2026-10-21 | **Done 2026-10-21** |
| 33f | **Docs sync.** `README.md`, `docs\flowchart.md` and the guideline match the code; code-differs notes removed | **Done 2026-10-21** |
| 33g | **Make the NASA measured source test-only.** The only user option is BEMT + F1A. Remove `e11` and `synthetic` from the GUI source choices; keep them reachable for T1/T2, smoke and `Pkg.test()`. Author approved | **Done 2026-10-21** — GUI model `["aircraft"]`; default `source=:aircraft`; e11/synthetic still callable from scripts/tests |


### Phase 34 — Validation cases in the GUI, with figure comparisons *(done 2026-10-21; see §11)*

> **Completed.** Historical plan retained below for the plot-spec table; ticks and the §11 write-up are authoritative.

**Why.** The author wants every validation case runnable from the GUI, and each one shown as a **graph of the published figure's data against the program's output**, on the same axes as the NASA or paper figure. 33g removes `e11` and `synthetic` from the user's *source* choice; this phase does not undo that. The cases live in a separate, read-only **Validation** tab that runs exactly the registered case (fixed inputs, fixed criterion), so the GUI cannot be used to tune a case (CLAUDE.md).

**Rules.**
- One implementation per case: the GUI, the validation script and `Pkg.test()` call the same case function. No case logic in QML or `gui_model.jl`; no plotting logic in QML.
- No editable inputs for a case; inputs are shown as an echo. Changing a case input after a result exists makes it post-hoc (R2, R3).
- Each case shows its criterion text and date, the verdict (`met`, `not met`, or `no verdict` when the criterion is not frozen or a §3.0 issue voids it) and its validity label. "V-EXP" only where §1 allows it.
- A case whose reference data is void or missing is listed greyed, with the reason (D-ID or I-ID).
- **Plots show the reference exactly as digitized** (points, envelopes, ranges as read; no smoothing, no interpolation of the reference, no fitting) and the program output as computed. The reference series is labelled with its source (document, figure, PDF page) and digitization (author/WebPlotDigitizer, date, uncertainty). Axis scales, units and ranges follow the published figure.

| Step | What | Done when |
|------|------|-----------|
| 34a | **Case registry (code; [CONFIRM]).** New `src/validation_cases.jl`: `struct ValidationCase` (`id`, `title`, `phase`, `reference_files`, `figure_ref` (document, figure, PDF page), `criterion_text`, `criterion_date`, `label`, `run::Function`, `plot_spec`) and `struct ValidationCaseResult` (`id`, `date`, `inputs_echo::NamedTuple`, `table` (quantity, x, reference, computed, residual, within tolerance), `series::Vector{PlotSeries}`, `verdict::Symbol`, `reason`, `label`, `report_path`). `struct PlotSeries` (`name`, `kind` ∈ {`:reference_points`, `:reference_band`, `:reference_curve`, `:computed`}, `x`, `y`, `ylow`, `yhigh`, `panel`). `VALIDATION_CASES` and `run_validation_case(id)`. Move each script's computational core into its case function; the script calls it and still writes its report | **Done 2026-10-21** — registry + runnable cores for `CYL2D_C1`, `MRP_D1`, `T1`, `T2`, `REPRO_18b`; other IDs registered greyed; `write_cyl2d_report.jl` calls the case |
| 34b | **Plotting backend (code; [CONFIRM], new dependency).** Add `CairoMakie` to `Project.toml` (one `Pkg.add`, versions pinned in `Manifest.toml`). New `src/validation_plots.jl`: `plot_case(result, spec; path)` renders a PNG (and PDF) from `result.series` using the axis definitions in `plot_spec`: reference points as hollow markers, reference envelopes or ranges as shaded bands or error bars, computed output as a solid line with filled markers, the tolerance band of the frozen criterion as a light band around the reference, panel titles as in the paper. Output goes to `docs/validation_reports/figures/<case_id>.png`; the report embeds it | **Done 2026-10-21** — CairoMakie 0.15.16; `plot_case` writes PNG/PDF |
| 34c | **Plot specification per case** (the axes mirror the cited figure; see the table below) | **Done 2026-10-21** — every registry entry has a `plot_spec` |
| 34d | **Equivalence test.** `run_validation_case(id)` reproduces its report's numbers (rtol 1e-9), and every `:reference_*` series equals the CSV it was read from exactly | **Done 2026-10-21** — testset "Validation case registry (34d)" |
| 34e | **GUI tab (code; [CONFIRM]).** `gui/main.qml`: tab "Validation" with a case list (id, title, phase, label, verdict colour, criterion date), **Run** per case and **Run all**; a results pane with (1) the comparison plot (QML `Image` bound to the PNG path; reloaded after each run), (2) optionally, side by side, the original figure page rendered from the PDF (`docs/validation_reports/figures/source/<case_id>.png`, rendered once by a script from the §2.3 PDF page, so the user can compare against the printed figure), (3) the result table, inputs echo, criterion text and date, verdict and reason, (4) a button to open the report. `src/gui_model.jl`: observables `val_cases`, `val_selected`, `val_plot_path`, `val_source_path`, `val_result_text`, `val_status`; `run_validation_gui!(obs, id)` calls `run_validation_case` then `plot_case`. Long cases (Report 996, Pereira, BBN) run asynchronously with a status line | **Done 2026-10-21** |
| 34f | **Tests.** Extend `scripts/smoke/smoke_gui_model.jl` and `scripts/smoke/smoke_qml_load.jl`: the tab loads; the list holds every registry entry; a short case (CYL2D Table C-1) runs through `run_validation_gui!`, writes a non-empty PNG, and its table equals `run_validation_case`. No test needs a display | **Done 2026-10-21** |
| 34g | **Docs (R5).** `README.md` (GUI section: running a case, reading the plot, cases are read-only), `flowchart.md` (GUI → case registry → plots), `METHODOLOGY.md` (the GUI shows registered cases; not a calibration tool), `VALIDATION_GUIDELINE.md` (§2.10 test list points to registry IDs and plots), this file | **Done 2026-10-21** |

**Plot specification (34c).** Reference = digitized published data; computed = program output. A case appears once its reference data exist and are not void.

| Case ID | Published figure (PDF page) | Plot (axes as in the figure) | Reference series | Computed series |
|---------|-----------------------------|------------------------------|------------------|-----------------|
| `T1` | CR-3813 Fig. E-16 (p. 142), with E-17 (p. 143) | Interior SPL (dB) vs 1/3-octave band (log x, 160–2000 Hz) | Measured space-average (points), min–max range (bars), E-17 95 % limits (second band), NASA PAIN prediction (open circles) | PAIN tone levels at H1–H3 (200, 400, 630 Hz bands), filled markers |
| `T2` | Fig. E-9 (p. 132), E-10 (p. 133) | SPL vs band (log x, to 2000 Hz) | Average, range, 95 % limits | 1.25–2 kHz band levels (line) |
| `REPRO_18b` | Fig. E-16 NASA predictions (p. 142) | SPL vs harmonic band | NASA PAIN prediction (open circles) with ±4 dB criterion band | Reproduction run (**18b-r inputs**, fixed 2026-10-21: was wrongly `source=:e11, blocking=R2` = T1; now ANOPP Table 8 + GEXT, R1, η_T = 0.5 → 82.73, 75.73, 77.05 dB) |
| `E12_BLOCK` | Fig. E-12 (p. 136) | Blocked SPL (dB) vs X3/D, panels H1–H3 | Predicted and measured, passes A and B | Eq. (43) on Table 8, R1 |
| `E11_FREEFIELD` | Fig. E-11 (p. 135) | Free-field SPL vs X3/D, H1–H3 | Measured passes A and B | e11 input line as used (after the ANOPP clip, flagged) |
| `CYL2D_C1` | CR-3813 Table C-1 and Fig. C-3 | Mode frequency (Hz) vs mode number; second panel Φ_G | Table C-1 values (points) | CYL2D frequencies and Φ_G (line) |
| `MRP_D1` | Table D-1, Fig. D-2 (p. 113) | Panel 1: frequency vs mode; panel 2: mode-1 floor and shell shapes vs position | Table D-1; Fig. D-2 digitized points | `mrp.jl` values and shapes |
| `E14_LOSS` | Fig. E-14 (p. 139) | Loss factor vs band (log–log, 10–10 000 Hz, 0.001–1) | NASA calculated curves (η_T 0.5, 1.0), measured points | Eq. (77) band averages |
| `E21_E22_NR` (31e) | Figs. E-21, E-22 (pp. 149, 150) | Noise reduction (dB) vs band (log x, 63–4000 Hz) | Average, range (E-21), 95 % limits (E-22), PAIN prediction (triangles) | Band from phase 31 (median and percentile band) |
| `GEXT_BOUND` | — (no figure; derived) | T1 residual per H vs variant | T1 gate edges (bands) | Residual per variant |
| `BBN_KIN` (24b) | — (V-UNIT) | Δφ (deg) vs harmonic | m·B·Δψ line | F1A Δφ points |
| `BBN_CIRC` (24c) | CR-158919 App. C (pp. 86–95), CR-159124 App. D (pp. 94–97), Fig. 18 (CR-159124 p. 55) | Panel per pair: phase (deg) vs harmonic; second figure: phase (π rad) vs frequency as in Fig. 18 | Measured phase (markers sized by coherence; low-coherence hollow); Fig. 18 digitized points | F1A Δφ per harmonic |
| `BBN_LEVELS` (24d) | CR-158919 Tables 3, 4 | Relative level (dB) vs microphone | Measured relative levels | F1A relative levels (both assumed tips) |
| `BBN_LONG` (24e, X-EXTRAP) | CR-159124 Figs. 19, 20 (pp. 56, 57) | Phase (π rad) vs frequency (Hz), panels as in the figures | Digitized points | F1A phase, both tips |
| `R996_LOADS` (26) | RM L8H25a Figs. 10, 11; Report 996 Fig. 7 legend, Fig. 14 table | C_T and C_P vs M_t, one curve per β₇₅ | Measured (points) | CCBlade, both polar sets |
| `R996_FIG6` | Report 996 Fig. 6 (p. 11) | Total rms pressure (dyne/cm²) vs x/D, one panel per d/D | Digitized points | F1A unscaled (absolute informational), shape |
| `R996_FIG7` | Fig. 7 (p. 11) | p_c/C_P vs x/D, per β₇₅ | Digitized | F1A, four ways (polar set × loads) |
| `R996_FIG8` | Fig. 8 (p. 11) | p_c vs C_P | Digitized | F1A |
| `R996_FIG12` | Fig. 12(a), (b) (pp. 13, 14) | Harmonic pressure vs x/D, mB = 2, 4, 6, 8, per M_t | Digitized | F1A scaled loads (and unscaled, dashed) |
| `R996_FIG13A` | Fig. 13(a) (p. 15) | First-harmonic pressure vs x/D | Digitized | F1A, RM L51C27-scaled |
| `R996_FIG14` | Fig. 14(a) (p. 16) | Harmonic pressure vs M_t (log y) | Digitized | F1A scaled to the Fig. 14 table |
| `R996_PHASE` | Report 996 p. 12 text | Bar: phase difference (deg) | 155° measured (165° Eq. 2 shown as a reference line) | F1A |
| `PER_LOADS` (28) | Pereira Table 3 (p. 5) | Bars: T, Q | Measured with uncertainty, paper BEMT and CFD | CCBlade, three polar sets |
| `PER_FIG6` | Pereira Fig. 6 (p. 7) | SPL (dB) vs frequency (log x), panels φ = 0°, 20°, 40° | Digitized spectra | F1A tones as stems at m·BPF |
| `PER_FIG7` | Pereira Fig. 7 (p. 8) | p′ (Pa) vs propeller phase angle (deg), three panels | Experimental, CFD, BEMT curves (digitized) | F1A time history over one revolution (encoder zero not stated: phase differences between panels are the compared quantity; absolute offset noted on the plot) |
| `PER_FIG8` | Pereira Fig. 8 (p. 9) | Polar: SPL vs φ, panels H1–H6 | Experimental, CFD, BEMT points | F1A at the seven microphones |
| `PER_FIG9` | Pereira Fig. 9 (p. 10) | Grouped bars: SPL vs BPF harmonic, panels φ = 0°, 20°, 40° | Experimental, CFD, BEMT bars | F1A bars (fourth colour) |

Runs after 33g and after the case verdicts exist; 34a–34d may start any time after §3.0 I-07, adding cases as their phases close.

### Phase 36 — Cabin mode animation in the GUI *(done 2026-10-22)*

**Why.** The author wants to see the cabin acoustic modes move. Table C-1 and Fig. C-3 give numbers; an animation of each mode shape
oscillating in time shows which modes are symmetric, where the nodal lines are, and which modes the propeller tone excites, which is
easier to check by eye than a table. Display only: it adds no check and no criterion (CLAUDE.md), and nothing in it can be tuned.

**What it shows.**
- 2-D cross-section modes from `cyl2d_modes` (App. C, NY = 10, θ0 = 56.6°): the pressure shape φ_n(x, y)·cos(ω_n t) on the half-cabin
  grid mirrored to the full section (antisymmetric modes change sign across the centreline), colour map with a fixed symmetric scale,
  nodal lines drawn, the floor and wall outline, mode index, f (Hz) at the selected c0, Φ_G and symmetry in the caption.
- For modes 0–5, an overlay or side panel of the printed Fig. C-3 one-decimal node values (`test/fig_c3_values.jl`), so the animation
  can be compared with the paper.
- 3-D modes (q, i): the axial factor cos(qπz/L) (Eq. C.9) as a side view along the cabin, or a cut through the cabin length.
- Optional, later: the Table D-1 structural mode shapes ψ (Eqs. 46–49) on the shell and floor, and the coupling f′ between a selected
  structural and acoustic mode, so the user can see why a pair couples.

**Steps (each needs the author's go-ahead; `src/` and GUI changes are [CONFIRM]).**

| Step | What | Done when |
|------|------|-----------|
| 36a | Frame generator in `src/` (display only): from a `Cyl2DResult` mode, build the full-section field on the App. C grid (interpolated for drawing only, the node values unchanged) and render N frames over one period with CairoMakie (`record` → GIF/MP4, or PNG frames). No new physics; reads `cyl2d_modes` output | Frames for modes 0–19 render; mode 0 is uniform; an antisymmetric mode is odd about the centreline |
| 36b | GUI: a "Cabin modes" panel (in the Validation map detail for `CYL2D_C1`, or its own tab): mode selector 0–19, q selector, play/pause, speed; shows the mode's f, Φ_G, symmetry and, for 0–5, the Fig. C-3 values | Runs offscreen in the smoke test without opening a window |
| 36c | Tests: the frame data equal the `cyl2d_modes` node values at the nodes (no smoothing of the data), symmetry checks, frame count and file written | `Pkg.test()` and smoke pass |
| 36d | Optional structural shapes and f′ view (Table D-1 path) | Author decides after 36a–36c |
| 36e | Five docs (README GUI section, flowchart, METHODOLOGY §4, VALIDATION_GUIDELINE §2.6 "display only, no claim", this file) | Done per CLAUDE.md |

**Rules.** Display only: no criterion, no verdict, no editable physics inputs (c0, θ0, NY shown as the fixed `CYL2D_C1` inputs). The
colour scale and interpolation are for drawing only and are stated on the figure. Delegated work follows the Cursor check rule (R13).

### Phase 38 — CR-3813 / User Manual completeness *(38a–38h done 2026-10-22; audit `validation_reports/cr3813_completeness_audit.md`)*

**Why.** The author requires the program to function as the PAIN Methodology (CR-3813) and the User Manual (CR-172425) describe.
The 2026-10-21 audit walked both documents and found missing or surrogate parts (the earlier theory audit only checked implemented
equations, which is how §3.3 was missed). Each step implements the text as printed (equations read from the page images), adds
tests against analytic limits first (V-UNIT), then the NASA comparison with criteria written and dated **before** the first run.

| Step | What | Source | Comparison and criterion (dated 2026-10-21, before any run) |
|------|------|--------|---------------------------------------------------------------|
| 38a | **Noise reduction for a reverberant exterior field**: Eq. (17) modal inflow, Eq. (18) ⟨p_i²⟩/⟨p_e²⟩, the blocked ↔ diffuse relation, reverberant joint acceptance j²_rev(ω) per structural mode (§3.6; Manual output 1), η_r′ cap option. New case `E21_E22_NR` | CR-3813 §3.3 pp. 21–23, §3.6; App. E p. E-30 | **Inputs as NASA's (p. E-30):** Phase III trim with η_T = 1.0, η_r′ ≤ 0.15, test-article geometry, CYL2D + Table D-1 modes. The end-plate allowance of ref. [7] (80–160 Hz) is not available: not applied, and the 80, 100, 125, 160 Hz bands are reported but excluded from both pass counts (V-ASSUMED). **Code-on-code (V-CODE):** \|NR − NASA prediction (E-21)\| ≤ 3 dB at ≥ 75 % of the remaining bands with a NASA value. **Experiment (V-EXP, held out, 23e):** NR inside the E-22 95 % limits at ≥ 75 % of the remaining bands; the E-21 min–max range is reported as a secondary count. No tuning; a miss is recorded. **Scope note (added 2026-10-21, before any run):** Eq. (18) is a modal sum and the 20 CYL2D cross-section modes reach ≈ 880 Hz at a = 0.508 m; above the crossover band (38b rule: ≥ 10 three-dimensional acoustic modes in the band) NASA's model is the high-frequency Eq. (19). 38a therefore issues the two counts over the bands **below** the crossover only; the full-band E-21/E-22 verdict, same thresholds, is issued after 38c. NR = 10 log10(⟨p_e²⟩/⟨p_i²⟩) with ⟨p_e²⟩ = ⟨p_bl²⟩/2 (p. 23) and c_ω = 0.232 (p. 10) |
| 38b | **High-frequency tone formulation** Eqs. (11)–(16) (expected value with n_n, n_r, η̄_n, η̄_r, ⟨ε_n f′²⟩ and j²_rev) and the crossover band (Manual card 10) | CR-3813 §3.2 pp. 16–20; Manual §5.4 card 10, §5.4.3 item 9 | **Crossover rule (fixed now):** the lowest 1/3-octave band whose count of 3-D acoustic modes (q, i) with resonance inside the band is ≥ 10 (CR-3813 §3.3 "ten or more modes in a third octave band"); an input override as card 10. **Production value:** Eq. (8) below the crossover band, the Eq. (15)–(16) expected value at and above it (Manual output 9(3)); both always reported. **"Explains H3" (I-18 rule):** REPRO_18b H3 within 4 dB of NASA's 68.0 dB with 38b where Eq. (8) is not; if so, I-18 mirroring is adopted and all affected results are re-recorded post-hoc |
| 38c | **High-frequency broadband model Eq. (19)–(23) as printed** (trim areas A_t, S, A′; τ_t; resonant transmission; average radiation loss factors), replacing the surrogate and the stale `bb_j2_scale` | CR-3813 §3.3 pp. 23–25 | T2 against Fig. E-9 with the unchanged T2 criterion (±3.5 dB, 1.25–2 kHz); the result is labelled as the first run of the printed model |
| 38d | **E-18 case**: tones with η_T = 1.0 and η_r′ ≤ 0.15 (uses the 38a cap) against `data/cr3813/e18_interior_pred_eta1.csv` | App. E p. E-29 | Code-on-code: \|computed − NASA E-18 prediction\| ≤ 4 dB per harmonic (the 18b criterion) |
| 38e | **E-15 case**: total structural loss factor η_r′ vs `data/cr3813/e15_structural_loss_targets.csv` | App. E p. E-25 | V-EXP, reported per band with no pass mark (as recorded in 16b) unless the author freezes a criterion first |
| 38f | Card inputs: separate exterior/interior ρ and c; cavity length L_c and offset d; per-band structural and bare acoustic loss-factor input; rotation direction; user band set | Manual cards 2, 3–6, 9, 11–18, 36 | Unit tests (limits: L_c = L, d = 0 reproduces current results exactly) — **plan with the author before starting** |
| 38g | **Structural solver App. D** (Eqs. D.17–D.26) for any geometry other than the test article | CR-3813 App. D | Table D-1 frequencies within the flowchart's 5 % with **no fitted scale**, Fig. D-2 shapes — **plan with the author before starting** (large) |
| 38h | **Printed outputs** of the Manual (§5.4.3): modes per band, coupling and Ψ_G tables, 5 largest modal contributions, pressures on both quarters | Manual §5.4.3 | Report/GUI page — **plan with the author before starting** |

**38a result (2026-10-22, first run; criteria and exclusions as dated 2026-10-21, nothing changed after the run).** Done: `src/noise_reduction.jl` (Eq. 17/18, helpers, `η_r_cap`, crossover rule), case `E21_E22_NR`, report `validation_reports/e21_e22_noise_reduction.md`. Crossover band 400 Hz (12 three-dimensional acoustic modes). Over the four counted bands below it (63, 200, 250, 315 Hz): **V-CODE 1 of 4** within 3 dB of NASA (200 Hz, Δ = −1.5 dB; 63 Hz +42.6, 250 Hz −6.2, 315 Hz −9.4), **V-EXP 0 of 4** inside the E-22 95 % limits. **Verdict: `:not_met`** (recorded, not tuned). Observations, not tested and not acted on: the 63 Hz band uses the Fig. A-2 table outside its 100–6300 Hz range (X-EXTRAP) and gives 58.6 dB vs NASA 16.0; Eq. 18 above 800 Hz rises far above NASA, as expected without the high-frequency model (38c). The printed Eq. 17 omits the free η_n/ω_n² of tone Eq. 7; Eq. 18 follows the printed form (V-UNIT 1e-9). Full-band verdict after 38c.

**38b result (2026-10-22, one run, criteria as dated 2026-10-21).** Done: `src/high_freq_tones.jl` (Eqs. 11–16, `tone_model` selector `:eq8` default / `:eq15_16` / `:auto`, card-10 `crossover_band_Hz` override), report `validation_reports/phase38b_high_freq_tones.md`. Crossover band 396.85 Hz (10 acoustic modes). REPRO_18b with `:auto` (NASA 79.0, 75.5, 68.0 dB): H1 85.74 (Eq. 8, below crossover), H2 16.89 (Eq. 16; Eq. 8 gives 78.74), H3 72.31 (Eq. 16; Eq. 8 gives 80.06, Δ = +4.31 dB). **I-18 rule: H3 not within 4 dB (4.31 dB), so "explains H3" is not met; the 160-point grid is kept and mirroring is not adopted.** Observations, not acted on: Eq. (16) at H2 rests on N_r = 2 structural modes in the band (H1 N_n = N_r = 3, H3 N_n = 26, N_r = 12), so the statistical average is not meaningful there; the default stays `:eq8` and no existing result changed.

**38c result (2026-10-22, first run of the printed model; T2 criterion unchanged).** Done: `src/hf_broadband.jl` (Eqs. 19–23), `interior_spl(...; broadband_model=:surrogate|:eq19)` (default `:surrogate`, outputs bit-identical), `noise_reduction_band(...; hf_model=:eq19)`, case `T2_EQ19`, report `validation_reports/phase38c_hf_broadband.md`. No scale on j², τ, A_t, S or A′. **T2 vs Fig. E-9: 0 of 3 within ±3.5 dB** (1250 Hz −12.4, 1600 Hz −10.1, 2000 Hz −6.6 dB) → `:not_met`. Full-band E-21/E-22 with Eq. 18 below and Eq. 19 at/above 400 Hz (report only): V-CODE 1 of 13, V-EXP 0 of 15 → not met. Readings decided: A_t = coupling area, A′ = 0, S = S_side + 2 S_e; ᾱ from Eq. 24 via Eq. 78; η̄_r = η_rad + mean η_r′ (η_r″ omitted, as in 38b); above Table D-1 (about 811 Hz) asymptotic n_r. **Open observation I-21 (reviewed 2026-10-22, see the I-21 review below):** at the 400 Hz crossover band Eq. 19 gives NR about 101 dB (very small τ) and T2 is 6–12 dB low, so the printed-model reading of one of the A_t / S / A′ / τ definitions may be wrong; a code-on-code review of the reading against pp. 23–25 is the next step if the author wants it. The surrogate is kept.

**38d result (2026-10-22, first run; criterion as dated 2026-10-21).** Case `E18_TONES`, report `validation_reports/e18_tones_eta1.md`: Phase III trim η_T = 1.0, η_r′ cap 0.15 on the tone path, `tone_model=:eq8`, BPF 200 Hz; mapping H1→200, H2→400, H3 (600 Hz)→630 Hz band. **2 of 3 within 4 dB: H1 89.02 vs 88.0 (+1.02), H2 78.14 vs 75.0 (+3.14), H3 77.70 vs 67.0 (+10.70) → `:not_met`.** Secondary (not in the verdict): `:auto` gives 89.02 / 13.24 / 67.44 dB (H2 again rests on a two-mode band, see 38b); measured means 90.0 / 80.0 / —.

**38e result (2026-10-22).** Case `E15_STRUCT_LOSS`, report `validation_reports/e15_structural_loss.md`: quantity η_r′ (Eq. 82, Phase III trim η_T = 1.0, cap 0.15; Fig. E-15 legend shows the trim curves and the 0.15 limit). No pass mark (V-EXP information, no verdict): 4 of 8 frequencies inside the CSV `tol_frac` (150 Hz ratio 2.50 and 300 Hz 2.14, both capped at 0.15; 500 Hz 1.27; 800 Hz 1.79; 1200 Hz 1.07; 1500 Hz 0.96; 2500 Hz 0.59; 4000 Hz 0.26).

**I-21 review (2026-10-22, post-hoc code-on-code check requested by the author; no code changed, no result re-recorded).** Eqs. (19)–(23) were re-read on pp. 23–25 against `src/hf_broadband.jl`. **Transcription:** Eq. (19)/(21)/(23), τ_R (p. 24), τ_f (Eq. 20), η_rad^ext/int and the η̄_n = ᾱc₀S/(4ωV) step match the printed forms term by term. **Cause of the 101 dB at 400 Hz:** a sparse-mode artifact of the in-band reading. Only two structural modes lie in the 400 Hz band and their mean j² at the band ω is 4.9e-7 (630 Hz: 4.8e-4, 11 modes); τ_R scales as ⟨j²⟩² (η_rad^ext η_rad^int), giving τ_R = 5.4e-10 and τ_f = 7.0e-12 against 2.6e-3 and 4.6e-5 at 630 Hz. **Open reading 1:** p. 24 says the sum r < Δω is over "all structural modes that are resonant below the frequency band"; the code sums over modes resonant in the band (reading §1 of the file). Under the text's wording τ_f gets all modes below the band; it changes τ_f only, and τ_f is 1–2 % of τ_R from 630 Hz up (630 Hz: 4.6e-5 vs 2.6e-3), so it can matter at 400 Hz but not at the T2 bands. **Open reading 2:** A_t is taken as the Eq. (8) coupling area (5.47 m²) although a reverberant field acts on the whole transmitting skin (Ā = 5.75 m²); a 5 % effect. **Diagnostic, not fed back and not a pass test:** computed NR is 25–30 dB above NASA's E-21 curve from 630 Hz (37.6 vs 13.0, 55.1 vs 24.5 at 1 kHz). The τ that would reproduce NASA's NR with the code's ᾱS, A_t and τ_t is 0.6–0.9, which is not a transmission coefficient; with τ_t set to 1 it is 0.003–0.013, the size of a mass-law τ for m = 3.23 kg/m² (1.7e-3–4e-3). So the gap sits in the factor τ_t (Eq. A.22, trim transmission, 0.0045 at 1 kHz) or in the way E-21 applies it, not in τ_R/τ_f. **Not decided, author's call:** (a) read p. A / Eq. (A.22) and the Eq. (23) text on whether τ_t multiplies the τ A_t term in the E-21 reverberant case (p. 25 gives ᾱS/(τ_t τ A_t) for fully trimmed); (b) whether to add the below-band sum (reading 1) as an option; either is a code-on-code change labelled post-hoc, with the T2 and E-21/E-22 criteria unchanged. The 38c first-run numbers stay as recorded.

**Plan for 38f–38h (agreed with the author 2026-10-22, before any of these steps runs).** **Order:** 38f, 38h, then 38g (38g is large and its criterion may fail, so it goes last). **38f splits in two.** 38f-1: separate exterior/interior ρ and c, cavity length L_c and offset d, rotation direction (Manual cards 2, 3–6, 36). 38f-2: per-band structural and bare acoustic loss-factor input, user band set (cards 9, 11–18). Each step: unit tests first; with L_c = L, d = 0 and equal inside/outside ρ, c the current results reproduce **exactly** (no output change); defaults unchanged; no comparison criterion (inputs only). **38h:** a generated markdown report per run plus a read-only GUI page with the same tables (modes per band, coupling and Ψ_G tables, the five largest modal contributions, pressures on both quarters; Manual §5.4.3); the offscreen smoke test checks the page loads; no comparison criterion. **38g criterion (fixed now, 2026-10-22, before any run):** Table D-1 frequencies within 5 % (the flowchart's tolerance) with **no fitted scale and no calibration against Table D-1**; Fig. D-2 shapes reported without a pass mark; a miss is recorded; the current fitted MRP surrogate stays the default and is replaced only by a later author decision. Each step follows the usual rules (spec file, Cursor, checks, full suite in a worktree, push to main).

**38f-1 result (2026-10-22).** Done: Manual card 2 (`ρ_ext, c_ext, ρ_int, c_int`, defaults ρ0, c0), card 9 (cavity length L_c and offset d; coupling integral over [d, d+L_c] ∩ [0, L]; V ∝ L_c; defaults L_c = L, d = 0), card 36 (rotation direction ±1, default +1 flips the grid azimuth, ANOPP x₂ sign and blade-passage phase sign; no lower-quarter mirroring). Report `validation_reports/phase38f1_card_inputs.md` (term map). Tests: defaults reproduce all previous outputs; 26 new V-UNIT tests pass. No comparison criterion.

**38f-2 result (2026-10-22).** Done: Manual cards 3–6 (`bands`: ≤ 26 standard 1/3-octave centres, ascending; default the fixed list) and cards 11–18 (`η_r_band`, `η_n_band`: a non-zero entry replaces the computed value in its band, 0 or absent computes as before; the containing band is found from the edges fc(1 ± c_ω/2)). Wired through `PainInputs`, the calculation paths, JSON and the GUI input echo. Report `validation_reports/phase38f2_card_inputs.md`. Tests: defaults reproduce all previous outputs; 49 new V-UNIT tests pass. No comparison criterion.

**38h result (2026-10-22).** Done: `src/printed_outputs.jl` (`printed_outputs`, `write_printed_outputs_md`), read-only GUI "Printed outputs" page, example report `validation_reports/printed_outputs_REPRO_18b.md` (script `scripts/run/write_printed_outputs_report.jl`). Included from Manual §5.4.3: modes per band (crossover flagged), coupling f′(n,r) and Ψ_G(r,H) tables, five largest modal contributions per tone, tone and 1/3-octave interior spectrum (Eq. 8 and Eq. 15–16 totals), pressures on the upper 160-point grid (lower quarter: "not computed — lower-quarter grid not adopted (I-18)"). Omitted: band-averaged loss-factor and trim-data listings, full mode dumps (live in CYL2D/MRP). Tests: 162 V-UNIT pass, registry 1188 pass, offscreen `smoke_gui_model.jl` and `smoke_qml_load.jl` pass. No comparison criterion.

**38g criterion addendum (2026-10-22, before any 38g run):** the plan row's "Table D-1 frequencies within 5 %" is counted as **at least 75 % of the 32 modes within 5 %** with no calibration input; spec `docs/specs/38g_appd_structural_solver.md`. Fig. D-2 shapes reported without a pass mark; a miss is recorded; the fitted MRP surrogate stays the default.

**38g result (2026-10-22, first run of the printed App. D formulation; criterion as dated 2026-10-22 before the run).** Done: `src/mrp_appd.jl` (`appd_modes`, selector `structural_solver=:appd`; `mrp.jl` and every default untouched), case `MRP_APPD`, report `validation_reports/mrp_appd_vs_d1.md`. Readings decided before the Table D-1 comparison: rigid attachment, asterisk terms omitted, p. D-10 thickness rule, θ from the bottom, nullspace reduction of (D.17), material from Manual §5.2 / `MRP_*`, and length L = 1.83 m as App. E p. E-1 prints it (the program uses 1.803 m). V-UNIT before the comparison: Donnell–Mushtari ≤ 1 %, stiffener and large-radius directions, constraints and orthogonality ≤ 1e-8, default path unchanged. **Result: 27 of 32 modes within 5 % (84.4 %; threshold 24) → `:met`.** Misses: mode 8 (+7.1 %) and modes 29–32 (greedy nearest-frequency match, same helper as `MRP_RITZ`). Fig. D-2 mode 1 compared at the digitized points, max |Δw| = 1.45, reported without a pass mark. No parameter fitted to Table D-1 or Fig. D-2; nothing changed after the comparison. **Open item I-22 (author to decide):** the test-article length is 1.83 m in this solver (App. E text) but 1.803 m in `mrp.jl`, the geometry defaults and the cabin calculations; the two are not reconciled, and the fitted surrogate remains the default. Replacing it with `:appd` is a separate author decision.

**I-22 check (2026-10-22, author asked to verify the test-article length).** Source text of `Pain Methodology.pdf`: Table D-1 title and the Appendix D example-output list give **1.803 m (71 in.)**; the Appendix D body ("the 1.83m (72 in.) long cylinder used in the present validation study") and App. E (p. E-1 "1.83m (72 in.) long and 1.02m (40 in.) in diameter", Fig. E-2 floor "1.83 m (72.0 in.)") give **1.83 m (72 in.)**; the validation report (`Pain Validation.pdf`) also says 1.83 m (72 in.) / 1.82 m on one figure; the User Manual gives no value. The radius 0.508 m (20 in.) agrees everywhere. **There is no factor-of-10 difference anywhere: the two values differ by 1 inch (1.4 %).** The only 18.3 m in the references is the orbiter example in the validation report, a different object. The audit and the code were not off by 10; the source text is internally inconsistent by 1 in. Sensitivity of 38g (post-hoc, one probe, not a re-recorded result): L = 1.83 m gives 27 of 32 modes within 5 %, L = 1.803 m gives 24 of 32, exactly the threshold of 24, so `:met` holds at both with no margin at 1.803. The 38g first-run record (L = 1.83 m, decided before the run) stands; the rest of the program keeps 1.803 m (Table D-1 header). Which length is the test article's is the author's call; no code changed.

**I-22 length sensitivity (2026-10-22, post-hoc, report only; author asked to run both lengths separately).** `TEST_ARTICLE_L` / `test_article_length()` / `with_test_article_length` (`geometry.jl`) override the test-article length; default stays 1.803 m and every existing output is bit-identical (registry 1210 pass, 21 new tests). `scripts/run/length_sensitivity.jl` ran the 11 length-dependent cases at 1.803 m and 1.83 m: `validation_reports/length_sensitivity.md`. **No verdict changes.** Largest moves: REPRO_18b tones up to 0.39 dB (H1 85.74 → 85.90 dB; distance to NASA H2 3.24 → 2.85 dB, H3 12.06 → 11.82 dB, as the 1.803 m run prints them), T1 0.35 dB, T2_EQ19 0.30 dB, E21_E22_NR 0.95 dB, E18_TONES 0.36 dB (still 2 of 3), E15 and E14 negligible. MRP_APPD 24 of 32 (1.803 m) vs 27 of 32 (1.83 m), `:met` at both; the fitted surrogate MRP_RITZ 26 vs 29 (no evidence value). The error comparison is a sensitivity record only: no length is selected from it. The choice of the test-article length stays an author decision decided on the source text (1.83 m appears in App. D body, App. E and the validation report; 1.803 m only in the Table D-1 title and contents entry).

**I-22 decision (2026-10-22, author: "choose an educated choice for the length"): the test-article length is 1.83 m (72 in.), from the source text, not from any error.** Grounds: (1) 1.83 m (72 in.) is printed in the App. D body text, App. E p. E-1, Fig. E-2 (floor 1.83 m) and the validation report (`Pain Validation.pdf`), whereas 1.803 m (71 in.) appears only in the Table D-1 title and the App. D contents entry (one caption and its copy); (2) the hardware description is consistent with 72 in.: the floor beam is 1.79 m (70.75 in.) inside a shell of 1.83 m, a 20 mm clearance at each end, whereas a 1.803 m shell would leave 6.5 mm; (3) the frames and floor supports sit on 0.2 m (8 in.) spacing (8 frames, 9 bays of 0.2 m plus end allowances) which fits 1.83 m (72 in. = 9 × 8 in.) exactly, whereas 71 in. is not a multiple of 8 in.; (4) the radius and diameter agree in every source. The 1.803 m of Table D-1's title is read as a caption typo. The sensitivity run (no verdict flips) is recorded above and is not part of the grounds. `TEST_ARTICLE_L` default becomes 1.83 m, all affected results are re-recorded labelled post-hoc, and the 1.803 m values stay in `length_sensitivity.md` for comparison.

**I-22 applied (2026-10-22).** `TEST_ARTICLE_L_DEFAULT = 1.83` (`geometry.jl`); the App. D solver, Table D-1 seeds, `phase3_trim`, cabin volume, pipeline, NR inputs and GUI follow `test_article_length()`; the Hartzell aircraft example keeps 1.803 m (not the test article). `phase17_baselines.csv` re-frozen at 1.83 m; affected reports carry the header "Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc)"; before/after table `validation_reports/length_rerecord_before_after.md`. **No verdict flips** (11 cases). Headline: REPRO_18b 85.74 / 78.74 / 80.06 → 85.90 / 78.35 / 79.82 dB; T1 84.05 / 78.01 / 78.30 → 84.21 / 77.66 / 78.06 dB; MRP_APPD 24 → 27 of 32 (`:met`); MRP_RITZ 26 → 29 of 32. The Table D-1 title's 1.803 m is noted as a caption typo in `digitized_table_D1.csv` and `data/README.md`; no data value changed. I-18 H3 value under the I-18 rule at 1.83 m is not re-judged: the rule was evaluated at 1.803 m (4.31 dB) and is recorded as it stood.

**Case explanations (2026-10-22, author request).** All 37 cases of `VALIDATION_GUIDELINE.md` §2.13 were rewritten in plain language: the Explanation starts with the kind of check (Unit test, Code-on-code, Experiment comparison, Input QA, Diagnostic, Replay) and ends with `Inputs:`, `Equations:`, `Outputs:` lines; map and block introductions expanded. Both GUI tabs read §2.13 (Validation tab `valInfo.explanation`, Validation map tab `mapDetail.explanation`, block and map texts); the Julia-side titles and criterion sentences were reworded for clarity only (no value, tolerance, date, label or verdict logic changed). `UT_GRID` is now a runnable case with a figure (160 grid points coloured by incidence angle, coordinate error panel vs Manual Fig. 3, 1e-9 criterion; `figures/UT_GRID.png`). Points the sources do not support are marked in the texts (GEXT form assumed; BBN reference-mic sign, Report 996 p. 12 stations, BBN blade data not stated).

**Total map layout (2026-10-22).** GUI `total` map stage frames use each group's own blocks only; §2.13 `(col,row)` keeps frames pairwise disjoint (aircraft checks above/below the pipeline; Free field shifted right). Smoke asserts disjoint rects from model data; offscreen shots at zoom 1: `VALIDATION_MAP_TOTAL.png` + `VALIDATION_MAP_TOTAL_right.png`. No case/verdict/criterion change.

**PlotSpec `error_xlabel` (2026-10-22).** Optional error-panel x label (default `nothing` → reuse `xlabel`). Set for `UT_GRID` to `sample index (table row)` so the error panel is not labelled as axial z; audit found no other case where table.x differs from the main-panel x. Label wording only; `figures/UT_GRID.png` regenerated.

**Phase 36 result (2026-10-22, display only; no criterion, verdict or tuning).** Done: `src/mode_animation.jl` (frame generator from `cyl2d_modes`, node values unchanged, interpolation for drawing only; GIF and peak-frame PNG; Eq. C.9 axial factor), GUI "Cabin modes" tab (mode 0–19, q, structural mode r, play/pause/speed, Refresh via the 37i cooperative loop; f, Φ_G, symmetry; Fig. C-3 values for modes 0–5; fixed `CYL2D_C1` inputs c0 = 341, θ₀ = 56.6°, NY = 10), and 36d (Table D-1 ψ shape image and f′). Cache under `gui/cache/mode_anim/` is git-ignored. Tests: 309 new pass, registry 1232 pass, `smoke_gui_model.jl` and `smoke_qml_load.jl` pass offscreen.

**Total flowchart (2026-10-22, author request; no case, verdict, criterion or number changed).** The GUI Validation map tab is now one horizontal `total` map: 28 blocks and all 37 cases in stage groups (Aircraft BEMT+F1A, Free field, Grid and blocking, Structural modes, CYL2D, Trim and loss, PAIN main, Validation comparisons), each stage an input, function and output block, with the checks branching off the outputs; titles only on blocks; scrolls in both directions (drag, Shift+wheel, scroll bars), Ctrl+wheel zoom and Fit. Positions, groups and edges are fields of `VALIDATION_GUIDELINE.md` §2.13 (`Position`, `Feeds`, `Group`, `Role`). `docs/flowchart.md` was shortened the same way (short node text, status moved to tables and a short Status section; overview = total flowchart). Smoke checks that the eight group rectangles are pairwise disjoint; screenshots `figures/VALIDATION_MAP_TOTAL.png` and `VALIDATION_MAP_TOTAL_right.png` (offscreen, 1842×751).

**Phases 29b and 29c done (2026-10-22).** Guard: an aircraft run that uses a test-article default without an `assumed` or `measured` tag lists it in one `@warn`, in `result.provenance.nasa_defaults`, in the printed-outputs header and in the GUI status (guarded: cabin geometry L, a, θ₀, r_p, φ_p, z_p, rotation, η_n_bare, C, NY, c0, ρ0, d, L_c, wall mass, `structural_solver=table_d1`, H = 3 anchor, `bb_alpha`, `bb_j2_scale`, absorption curve, Phase III trim, PF-105 table, end-plate mass, η_lining). Provenance: aircraft JSON `cabin.*` entries take a plain number or `{"value": v, "tag": "measured"|"assumed"|"nasa_default"}`; tags go to `result.provenance.inputs`, the report table and the GUI echo; an unknown tag is an error; a result that uses any NASA default is labelled "NASA test article inputs used for: …, not the aircraft". New `src/aircraft_provenance.jl`, example `examples/aircraft_scale_hartzell_cabin_full.json`. Validation, e11 and synthetic paths bit-identical. Tests: 33 new pass, registry 1461 and printed outputs 162 pass, both smoke scripts pass offscreen.

**Phase 30 done (2026-10-22; 30a–30d).** `cabin_blocks` selector on the aircraft path (`:parametric` default for `source=:aircraft`, `:surrogate` = the old behaviour; validation, e11 and synthetic paths bit-identical). 30a: user `cabin.trim` stack and insulation table from the aircraft JSON. 30b: `:parametric` uses printed Eqs. 19–23 (ᾱ from Eq. 24/78) instead of the absorption curve and `bb_j2_scale`; no η_r cap (I-21 reading issues stand: X-EXTRAP). 30c: structural modes from the App. D solver with the aircraft geometry and skin/stringer/frame/floor JSON keys (no Table D-1 hybrid), CYL2D `c0` from the inputs, V, S, A, L_c, d from the geometry. 30d, `scripts/run/parametric_regression.jl` → `validation_reports/parametric_regression.md` (first run, record of the shift, no criterion; baselines not renewed): test article, measured / surrogate / parametric: H1 90.0 / 84.21 / 86.56 dB, H2 80.0 / 77.66 / 88.27 dB, H3 65.0 / 78.06 / 68.82 dB; T2 1250, 1600, 2000 Hz 51.0 / 46.0 / 41.5 measured, surrogate 55.92 / 53.56 / 51.59, parametric 39.71 / 36.97 / 36.03 dB. The parametric chain moves H2 by +10.6 dB and the T2 bands by about −16 dB relative to the surrogate; this is the input to phase 31 (the size of the effect of predicting loss factors and modes without tuning).

**Phase 31 pre-registration (fixed 2026-10-22, before any phase 31 run; spec `docs/specs/phase31_uncertainty.md`).** Budget parameters and ranges: η_t 0.01–0.10 (nominal 0.05), C 2–4 (3), bare η_n 0.02–0.10 (0.05, untrimmed only), common structural-frequency scale 0.95–1.05, CYL2D node constant 0.32h–0.47h, axial truncation, R1/R2 blocking and trim-stack alternatives (discrete), insulation-table extension flag; source-side residuals of phases 24–28 for the aircraft run only. Monte Carlo N = 4000, seed 20261022, uniform primary and triangular repeat, P5/P50/P95 and Spearman ranks, never the mean. OAT: parameters whose swing exceeds 3 dB in H1–H3 are kept. **31e criterion:** the P5–P95 band of the primary Monte Carlo on the untuned `:parametric` chain with NASA's free field contains the measured E-16 mean at each of H1, H2 and H3; `:met` only if all three; a miss is recorded and nothing widened in that run (later changes are post-hoc). Bounding cases for phase (BBN residual; random phase as the extreme) and the V-ASSUMED scattering/refraction condition; reporting template 31f with the required statements.

**Phase 31 done (2026-10-22; 31a–31f; pre-registration of 2026-10-22 unchanged).** `src/uncertainty.jl` (budget table, `oat_sweep`, `monte_carlo_band`, `coverage_check`, `phase_bounding_cases`, 31f template `uncertainty_report_md`), scripts `scripts/run/uncertainty_testarticle.jl` and `uncertainty_aircraft_band.jl`, case `UNC_COVER`, reports `uncertainty_budget_testarticle.md` and `uncertainty_aircraft_band.md`. Reviewer fixes before the recorded runs: an unused generalized-force cache removed; phase case (i) added one common phase to every observer, which leaves ⟨p²⟩ unchanged, and is now a per-observer offset k·H·B·Δψ from the BBN H1 residual ratio; the test-article report no longer prints the aircraft diameter line. The nominal evaluator equals `run_pain_pipeline(source=:e11, cabin_blocks=:parametric)` to 1e-6 dB at η_t = 0.5 (test). **31e (test article): not met.** OAT kept the frequency scale (5.6 dB swing) and η_t (4.9 dB); the others are below 3 dB. Primary Monte Carlo P5/P50/P95: H1 88.95/89.87/91.06 dB (measured mean 90.0, inside, 1.05 dB from the edge); H2 85.46/91.30/92.86 (80.0, outside by 5.46 dB); H3 73.09/74.78/77.59 (65.0, outside by 8.09 dB). Nothing was widened. The triangular repeat moves the edges by at most 1.35 dB. NASA's Phase III η_T = 0.5 lies outside the registered 0.01–0.10 range (noted; range unchanged). **Aircraft band (working example; X-EXTRAP; epistemic, not a confidence interval):** OAT kept bare η_n (5.5 dB); H1 99.31/101.41/104.21, H2 58.47/59.07/59.94, H3 35.45/35.65/36.26 dB. Phase case (i), k = −2.09, B = 3: spread 2.45/3.70/2.08 dB (dominates H2 and H3); random-phase extreme 4.17/2.53/1.22 dB. **Conditions:** (1) k is computed from `bbn_results.csv`, whose comparison was found on 2026-10-22, after this run, to read BBN's App. C phase with the reversed pair convention (I-19 root cause); phase case (i) is re-run after that fix. (2) By the phase 31 rule, a failed 31e means the aircraft band may only be reported with revised ranges, labelled post-hoc; revising the ranges is an author decision (open). Runtimes 784 s (test article) and 727 s (aircraft). Checks: phase 31 testset 57/57, registry 1484/1484, both smoke scripts pass.

**Step 25g done (2026-10-22; docs only, no run).** The scope and the criteria 25g asks for were already written before the phase 27 comparisons they govern: scope tip Mach 0.45–0.90, nothing above 0.90 tested (decision 2026-10-16, `VALIDATION_GUIDELINE.md` §2.3 x/D note; Fig. 8 at M_t 1.0 removed under I-20); criteria in §2.12 23c, frozen 2026-10-21 (C_T, C_P within ±15 % from the largest source-to-source spread, Fig. 14 table vs RM L8H25a; scaled-load pressure per harmonic and total rms within ±2 dB at ≥ 75 % of in-scope points, the bound set by the Fig. 12 vs Fig. 14 agreement of ≤ 6 %; unscaled runs informational, so no polar-bracket tolerance is needed; page-12 phase within ±15°). No new criterion is written now: any value set after the phase 26–27 results would be post-hoc. Phase 26 keeps its label "criteria registered after the loads were computed". 25h (`ScaledLoads`) and 25i (`load_polar_set`) were implemented in the phase 21 pass and are ticked.

**I-19 resolved (2026-10-22; root cause from the source document; result post-hoc).** CR-158919 §3.4 (printed p. 14) measured pair phase on the SD360 with Function 6, transfer function B/A. Table 8 (p. 35) gives signed trace velocities (positive upward or rearward); for all nine pairs with both a Table 8 velocity and an App. C phase, sign(U_c) = −sign(printed phase), and Fig. 11 (mics 4 and 5, slope about 206 m/s) agrees with Table 8 (209 m/s). So the printed phase of pair a-b is φ_b − φ_a in our convention (negative when the second mic lags), and Table 8 says the circumferential field moves upward, as the documented rotation (I-09) predicts. `run_bbn_phase.jl` compared it with φ_a − φ_b. Fix: `bbn_printed_pair_phase` (φ_b − φ_a) for CR-158919 App. C rows; measured data unchanged; criterion 23a unchanged. The pre-registered verdict FAIL 26/168 (2026-10-21) stays on record; the re-run, **134/168 (79.8 %), still FAIL** (4-3 52/56, 5-3 44/56, 4-5 38/56), is post-hoc because the convention was found after that result. H1 residuals at run 4 tip A are now −6°, −12°, +5° (were −86° to −154°). CR-159124 states the same B/A measurement (PDF p. 27) and its circumferential Table 6 agrees at H1, but longitudinal pair 8-9 disagrees with its Table 9, so the Fig. 19 longitudinal rows keep the old reading, marked `convention_unresolved` (BBN_LONG is X-EXTRAP, no verdict). Knock-on, phase 31: k = median(residual/f1a) changes from −2.09 to +0.094; aircraft phase case (i) spread 0.36/0.46/0.22 dB, so phase no longer dominates H1–H3; the Monte Carlo band is unchanged. Display: percentages printed to one decimal so 79.8 % is not shown as 80 %.

**Polar display cases POLAR_R996 and POLAR_PER (2026-10-22; author request "would help if there was a visual"; display only: no criterion, no verdict, nothing tuned).** Panels: c_l and c_d against α for the XFOIL polars as the code reads them (`load_polar_set`), with the Viterna extension dashed; coverage of every blade-section operating point (α against local Mach, from the same CCBlade setup as `evaluate_propeller_source`, new helper `ccblade_section_operating_points`) against the polar data box, points outside in red; for Report 996 a fourth panel of c_l against Mach. Measured overlays from `data/airfoil_measured/` (digitized 2026-10-22 from NACA TN 1546 Figs. 3j/3n/3o and NACA Report 824; display only, never read by the BEMT path): POLAR_R996 shows section n16_506 (exact TN 1546 match, 0.87 R) at Re 1×10⁶; POLAR_PER shows NACA 4412 with Report 824 (Re 3–9×10⁶ against Pereira's 1.4×10⁵, stated in the title). **What the figures show:** Report 996 runs put 312 of 972 section points outside the polar α range (inboard sections at 15°–30°) and 46 outside the Mach grid (tips at 0.75–0.90); up to 459 Viterna evaluations per run. XFOIL c_l is below TN 1546 by about 0.09–0.11 at M 0.4–0.55 and up to 0.29 at M 0.72 (forced transition at 2 % chord; observation, not changed). TN 1546 reaches about M 0.8; XFOIL stops at 0.72 and is non-physical above about 0.76 (negative pressure drag, checked by the forked session), so it cannot fill the gap. Pereira: all points inside its polar data. **Found with it (forked session, 2026-10-22):** 109 of 300 entries of `data/report996/polars_forced_merged.json` are empty (6) or stop below α = 8° (103), from XFOIL up-sweep timeouts; regeneration with the phase 11 settings and post-hoc re-runs of the Report 996 cases follow (separate entry). Checks: "Polar display cases" 185/185, registry 1531/1531, both smoke scripts pass.

**Report 996 polar regeneration and re-runs (2026-10-22; input-data repair; results post-hoc; criteria 23c unchanged).** 109 of 300 entries of `data/report996/polars_forced_merged.json` were empty (6) or stopped below α = 8° (103) because XFOIL up-sweeps had timed out in phase 11; propeller sections run at positive α, so those loads came from clamping or the Viterna extension. Regenerated by the forked session with the phase 11 settings (forced x_tr 0.02, same grids, iteration limit and convergence rule; only the sweep handling changed: streamed sweeps restarted after a hang, 0.25° sub-steps), script `data/polars/xfoil_regen_2026_10_22.py`. 1,420 points added; every existing point unchanged (checked by the reviewer: 0 of the old points differ or are missing); 59 of the 109 entries now reach α ≥ 8°; 50 thin-section entries (16-101, 16-405, 16-506/507/508) are still short and listed in `header.regeneration_2026_10_22.still_missing`, not filled; the header keeps the previous SHA-256 and each entry's old α range. Stale machine paths fixed in `viterna_extension.jl` and `xfoil_polars.py`. Re-run in order: Viterna extension (Report 996 set: extended 235→286, unusable 19→6, non-finite 46→8; Pereira sets unchanged), `report996_setup`, loads, acoustics; each report carries a dated post-hoc label with the first recorded result kept below it. **Results:** R996_LOADS 6/32 (unchanged); Fig. 14 table s_T at M_t 0.75/0.90 1.364/1.521 → 1.275/1.316 (closer to 1); R996_FIG14 20/24 (unchanged); R996_FIG13A 8/14 (unchanged); R996_FIG12 22/40 → 21/40, not met; R996_PHASE 103.8° → 109.0°, still FAIL; behind/ahead still false. Viterna evaluations over the 18 POLAR_R996 runs 5170 → 4498. So the truncated polars were not the main cause of the Report 996 misses; the remaining candidates are the out-of-grid tip Mach (no XFOIL above 0.72; TN 1546 measured data to about M 0.8 now in the repo), the forced-transition XFOIL c_l offset against TN 1546, and the near field (author decisions; nothing changed here).

**Validation map: per-case error on the chips (2026-10-23; author request "include in the validation map the error"; display only: no criterion, tolerance, verdict or recorded result changed).** Each case chip in the GUI Validation map now carries a short error line and its date; the case detail panel shows the full text. The numbers use the same definition as each case's error panel (`_row_error` with the case's own `error_mode`; unit from its PlotSpec labels: %, dB, or the axis unit such as deg or Hz). Texts: "n/m · X U max" on the chip and "n/m in tol · max |err| X U · med Y U" in the detail panel, where n/m counts every table row of the case (same count as the case's verdict); "n/m within criterion" for a case with a verdict but no error panel (UNC_COVER 1/3); "no verdict · max |err| …" for informational cases with an error panel (GEXT_BOUND, MRP_RITZ, E15_STRUCT_LOSS, BBN_LEVELS, MRP_D1); "no criterion" for display cases and cases without a table. Running a case or the test suite writes nothing: errors from runs in the GUI session are kept in memory; otherwise the chip shows the dated snapshot `docs/validation_reports/case_error_summary.csv`, written only by `scripts/run/write_case_error_summary.jl` (columns include the case result's own date and the snapshot date, so a stale value shows as such). Code: `case_error_summary` and the snapshot writer/loader (`src/validation_plots.jl`; a malformed snapshot row is skipped, not fatal; loaded once and re-read on file change), `validation_map_json` / `case_info_json` take the session errors explicitly, chip row height defined once in Julia and passed to QML; one quoted-field CSV splitter shared with `_read_csv_rows` (old and new parses identical on all 5 registry files, 941 rows). Code review (10 findings) fixed before commit. Checks: "Validation map errors (V-UNIT)" 223/223, registry 1531/1531, both smoke scripts pass offscreen; full suite in a worktree before the push.

**Test suite leaves the tree clean (2026-10-23; test-only change, flagged by the fork 2 session).** A full `Pkg.test()` used to rewrite tracked files: `blocking_p68.md`, `mrp_table_d1.md`, `e11_delta_dig.md`, `t1_tonal.md`, `t2_third_octave.md` and case figures through `plot_case` with the default path. All test writes now go to `TEST_OUT = mktempdir()`; the committed reports stay as their scripts record them. New final testset "Suite leaves tree clean": a snapshot of already-modified tracked files under rea-work/docs and rea-work/data (with `git hash-object` hashes) is taken at the start, and the check fails only for files the suite newly modified or changed; the `VALIDATION_MAP_TOTAL*.png` files the smoke scripts write on purpose are exempt; skipped without git. The GUI mode-animation cache (`gui/cache/mode_anim`) is gitignored and unchanged. Checked: full suite with the tree unchanged before and after; the check passes with an unrelated docs edit in place.

**Rules.** No parameter is chosen by looking at a comparison result. Where the text is ambiguous, the reading is decided and
recorded from the text before running. Delegated work follows R13 (snapshot, diff, rules, run the checks, spot-check numbers, docs).

## 8b. Block validation program: phases 39–44 *(done 2026-10-23 except open item 44f; moved to the bottom 2026-10-23; criteria dated 2026-10-23, before any of these tests was run)*

**Why.** The final level passes through about fifteen blocks; several are tested only through the end-to-end chain or only against tables from CR-3813 itself, so a miss of 5–13 dB at the end (T1, T2, E-21) cannot be attributed. Each block gets its own case that feeds it the test's own inputs and compares its output with an analytic result or an independent source. Audit: `validation_reports/block_validation_audit.md`.

**Rules for these phases.** Nothing is fitted, scaled or selected to make a test pass. An isolated test against an analytic result that fails means a code error: it is fixed as a documented code-on-code bug fix and every affected recorded result is re-run and labelled. An experimental case that still misses after its blocks pass isolation is recorded as **model fidelity** (the method, not the code), with the isolation case named next to it. Author decisions stay open and are not settled here: TN 1546 polars above M 0.72, forced-transition XFOIL, revised Phase 31 ranges, I-21, `:appd` as default, I-18 mirroring. Tests write only to `TEST_OUT` (the suite must leave the tree clean). Every new case appears on the Validation map in the block it tests.

### Phase 39 — Audit record *(done 2026-10-23)*
`validation_reports/block_validation_audit.md`: every physics function, its tests and cases, isolated or not, status (VERIFIED / PASS-EXP / FAIL / INCONCLUSIVE / NONE), and the isolation test that attributes each failing case.

### Phase 40 — Isolated analytic checks for blocks without one *(done 2026-10-23; V-UNIT / V-CODE; criteria fixed 2026-10-23)*

| Step | Block / function | Isolated check | Pass criterion |
|------|------------------|----------------|----------------|
| 40a | `apply_blocking` (full grid) | synthetic free-field amplitudes and phases on all 160 points; compare with F(γ)·A from `blocking_factor` and the geometry's γ, phases unchanged | max relative difference ≤ 1e-12 |
| 40b | free-field conversions, `freefield_from_e11_csv` | SPL → Pa and back for the convention recorded after I-17; the ℓ = 1 line of the loaded grid against a hand conversion of the CSV | ≤ 1e-12 relative |
| 40c | `extend_line_to_grid` | on the ℓ = 1 line the extension returns its input (falloff 1, delay 0) for every harmonic and option | ≤ 1e-12; off-line values stay V-ASSUMED (no reference exists) |
| 40d | `apply_table8_calibration` | identity when the Table-8 peaks equal the current ℓ = 1 peaks | ≤ 1e-12 |
| 40e | `cyl2d_modes` (App. C) | floorless circular section against the exact rigid-walled circular cross-modes f = c·j′ₘₖ/(2πa) (zeros of J′ₘ); if the code cannot remove the floor, the smallest floor the geometry allows, stated | first 10 modes within 2 % at NY = 20, and the error at NY = 20 smaller than at NY = 10 |
| 40f | `structural_modes` (Ritz, unstiffened) | stringers, frames and floor removed: Ritz frequencies against the closed-form Donnell–Mushtari frequencies already used for App. D | within 1 % for the first 10 shell modes |
| 40g | `structural_joint_acceptance` | against direct numerical quadrature of the joint-acceptance integral for three modes | ≤ 1e-4 relative |
| 40h | `structural_modal_density`, `band_joint_acceptance` | modal density against the count of modes in each 1/3-octave band; band average against quadrature | count exact; ≤ 1e-6 relative |
| 40i | `blocked_broadband_band_p2` | band integral of S ∝ f^(−α) over 1/3-octave limits against the closed form | ≤ 1e-9 relative |
| 40j | `acoustic_boundary_value`, `cabin_modes_3d` | boundary values reconstructed from the node values; (q, i) list complete and sorted | ≤ 1e-9; exact |
| 40k | `sil_dB`, `sil_from_third_octave` | hand-computed SIL from a known band spectrum | ≤ 1e-9 dB |
| 40l | `absorption_coefficient` (surrogate) | none possible: a fitted surrogate used only by `:surrogate`; recorded as such on the map | — |

**Phase 40 result (2026-10-23).** Ten of the eleven checks are cases on the Validation map and all ten are met against their pre-registered criteria: ISO_BLOCKING (0 vs ≤1e-12), ISO_FF_CONV (7e-15), ISO_GEXT_LINE (0), ISO_TABLE8 (0), ISO_CYL2D_EXACT (floorless circle θ₀ = 0 against exact J′ zeros from an independent root finder: largest error 0.97 % at NY = 20, 6.7 % at NY = 10), ISO_JOINT_ACC (2.7e-5 against independent 2-D quadrature, mode-normalized and printed forms), ISO_MODAL_DENSITY (exact count), ISO_BB_BAND, ISO_CYL2D_BOUNDARY (0), ISO_SIL (0 dB). **40f not built:** `structural_modes` (Ritz) always includes the stringer and frame bending stiffness (constants, not options) and always assembles the floor, so the unstiffened shell cannot be isolated without changing solver physics; recorded as a gap (App. D's unstiffened limit is already verified against Donnell). **40l:** `absorption_coefficient` is a fitted surrogate used only by `:surrogate`; recorded as such. **Code error found and fixed (code-on-code, 40i):** `blocked_broadband_band_p2` integrated the band as a band-centre rectangle with a rounded width 0.232 instead of the exact integral of S ∝ f^(−α) between 2^(∓1/6)·f_c; the first version of ISO_BB_BAND compared the function with its own formula (caught in review, check 6). Fixed to the closed-form integral (anchor unchanged); the T2/T2_EQ19 broadband bands move by −0.008 dB (below their recorded precision in the reports; the three frozen Phase 17 regression baselines for these bands were re-recorded 2026-10-23 with the old values kept in the file header). Review: a printed-form joint-acceptance reference assumed all shell terms n > 0; now applies the printed halving term by term. Checks: "Isolated block checks (phase 40, V-UNIT)" 41/41, registry 1751/1751, "Suite leaves tree clean" pass, both smoke scripts pass offscreen; full suite in a worktree before the push.

### Phase 41 — Isolation tests for the failing cases *(done 2026-10-23; criteria fixed 2026-10-23)*

| Step | Failing case(s) | Isolation case | Reference | Pass criterion |
|------|-----------------|----------------|-----------|----------------|
| 41a | T1, REPRO_18b | `T1_FROM_E12`: interior tones from the **measured** blocked pressures of Fig. E-12 instead of the predicted source and blocking (GEXT as in T1 where E-12 does not cover a point, stated) | measured E-16 means | T1's gate unchanged (±4 dB of the measured mean, H1–H3); a pass with T1 failing attributes T1 to source/blocking, a fail to the cabin chain |
| 41b | E14_LOSS, E15 | `TRIM_CLOSED`: `trim_conductance` / `trim_tau` of a two-layer stack (limp septum on a porous layer, App. A form) against the closed-form transfer-matrix product written in the test | analytic | ≤ 1e-9 relative at the Fig. A-2 frequencies |
| 41c | E21_E22_NR | `NR_BAND_HAND`: one band of `noise_reduction_band` with stated inputs against a hand evaluation of Eqs. (17)–(18) in the test | analytic | ≤ 1e-9 dB |
| 41d | T2, T2_EQ19 | `HF_MASSLAW`: `hf_transmission_coeffs` for a single limp layer against the normal-incidence mass law τ = 1/(1 + (ωm/2ρc)²) | analytic | ≤ 1e-9 relative |
| 41e | R996_LOADS | `BEMT_HAND`: CCBlade thrust and torque for a constant-chord blade with a linear lift curve and zero drag against a hand blade-element/momentum solution written in the test | analytic | within 1 % |
| 41f | R996_FIG12/13A, R996_PHASE, BBN_CIRC, PER_FIG7/8/9 | `F1A_INDEP`: the same loads through an independent time-domain compact-source implementation written in the test, at the Fig. 12 / page-12 observers | code-on-code | amplitude within 0.5 dB, phase within 2° |

A case that passes its isolation test while its experimental case still fails is labelled "model fidelity" on the map and in VALIDATION_GUIDELINE, with the isolation case named.

**Phase 41 result (2026-10-23).** Five of six isolation cases are met: TRIM_CLOSED (the App. A element and cascade algebra re-typed independently in the case, 0 difference: a re-implementation check of the stack order, product and conductance; element limits are in the phase 16 tests), NR_BAND_HAND (independent hand arithmetic of Eq. 18, 0.0 dB), HF_MASSLAW (the function is the field-incidence Eq. 20, checked against it; normal-incidence mass law shown for information only), BEMT_HAND (independent hand blade-element/momentum solution, tip loss off through a new `use_tip_correction` option whose default keeps every existing result unchanged; difference below 1e-4 %), F1A_INDEP (an independent time-domain Farassat 1A written in the case against AcousticAnalogies with identical loads: 0.005 dB, 0.02°). **T1_FROM_E12 is not met:** with the **measured** E-12 blocked pressures on the stations E-12 covers (other points as in T1), H1–H3 = 81.66 / 75.29 / 77.89 dB (T1: 84.21 / 77.66 / 78.06); H1 and H2 pass T1's gate, **H3 stays 12.9 dB above the measured 65 dB**. **Attribution:** the BEMT, F1A, trim-stack, noise-reduction and high-frequency transmission blocks work as intended in isolation, so the Report 996 load, Fig. 12/13a and phase misses, BBN_CIRC and Pereira misses are model fidelity (polars, near field, phase reference), not code errors; and the T1 H3 excess is **not** in the source or blocking (it survives measured blocked pressures): it is inside the cabin chain (modes, coupling, Eq. 8 inputs), which phase 43 attacks. Cursor runs of this phase dropped twice; the partial edits were reviewed (check 8) and the cases were run and checked by the reviewer.

### Phase 42 — Interior level at the loudest point *(done 2026-10-23; criteria fixed 2026-10-23)*

PAIN reports the space-average level (Eq. 3). Added: the tone pressure at interior points from the coherent modal sum of the same Eq. (8) terms (mode shapes from CYL2D node values × the axial factor of Eq. C.9), and the overall dB(A) at the loudest point. **Points (fixed now):** every interior CYL2D node of the cross-section (wall and floor nodes excluded) at 21 equally spaced axial stations from 0 to L. Broadband bands are diffuse and enter every point at their space-average level. Output: space-average dB(A) (unchanged) and loudest-point dB(A) with its position, for the test article and the aircraft examples. **Checks (V-UNIT):** the volume average of the point mean-square pressures equals the space-average ⟨p²⟩ within 1 % (quadrature over the points); the loudest point is ≥ the space average; one mode alone reproduces |φ| shape. No experimental criterion (E-16 means are space averages); the loudest-point level is a derived output, X-EXTRAP for the aircraft.

**Result (2026-10-23; criteria unchanged).** `LOUDEST_PT` **not met**: check (a) fails as written (interior-node average / Eq. (8) = 0.938, 0.877, 0.834). The pre-registered point set leaves out the wall and floor nodes, where rigid-wall modes have their antinodes, so a 1 % match was not reachable with these points; the ε_n normalization itself is exact over all nodes. Supplementary, labelled post-hoc: all nodes with the Eq. (C.10) weights give 1.027, 1.004, 0.986. (b) met, (c) met. Test article: 79.1 dB(A) space average, **83.7 dB(A) at the loudest point** (X = −0.39 m, Y = −0.20 m, z = 0.92 m; H1–H3 there 85.9 / 85.8 / 80.7 dB against 84.2 / 77.6 / 77.8 dB on average). Aircraft example (X-EXTRAP): 93.8 / 98.4 dB(A). After 44f (post-hoc): test article 80.4 dB(A) average, 85.5 dB(A) at the loudest point; check (a) 0.936 / 0.886 / 0.901 (all-node 1.011 / 0.995 / 0.978). The loudest point lies on the side away from the propeller; that depends on the antisymmetric-mode sign convention, which is open item 44f, so the position is not claimed.

### Phase 43 — T1/T2 root causes and an independent bare-cylinder validation *(done 2026-10-23; planned 2026-10-23; author: "keep going until T1 and T2 are right", tuning only as a code check, decide open items from documents; criteria below dated 2026-10-23 before any of these runs)*

**What the documents say (read 2026-10-23).** (1) NASA's own first PAIN run for the test article (CR-3813 Fig. E-17, η_T = 0.5, no cap on the structural loss factor) gave 79.0 / 75.5 / 68.0 dB at H1–H3 against 90 / 80 / 65 measured: about 11 dB low at H1. NASA then set η_T = 1.0 and "arbitrarily" capped η_r′ at 0.15 below 400 Hz (p. E-24), giving about 88 / 75 / 67 (Fig. E-18). (2) The computed structural loss factor (Fig. E-15) is near 1.0 below 300 Hz, while the measured decay values of the same cylinder are about 0.06 (125 Hz) and 0.1 (500 Hz): NASA calls the low-frequency prediction an order of magnitude off. (3) With NASA's E-18 settings our Eq. (8) gives 88.7 / 77.8 / 77.6 dB: H1 and H2 reproduce NASA, H3 is 10.6 dB above NASA's 67. (4) User Manual card 10 (p. 17–18): the default low/high-frequency changeover is the 1/3-octave band containing f = 4.1 c₀/∛V (about 1.25 kHz for this cabin); the "ten or more modes" sentence used in 38b is from §3.3 (noise reduction), not the tone model. So NASA's default run used Eq. (8) for H1–H3. (5) CR-3813 gives no exterior broadband spectrum (Fig. E-8/E-9 are interior), so T2's exterior input is an assumption. (6) NASA's later validation (CR-172428 p. 60) set the trim loss factor from the measured average; NASA TP-1964 supplied measured reverberation times to the PAIN authors as damping input. Using measured damping is the documented PAIN practice.

| Step | What | Basis | Pass criterion (fixed 2026-10-23) |
|------|------|-------|-----------------------------------|
| 43a | Low/high-frequency changeover: default to User Manual option a, the band containing f = 4.1 c₀/∛V; the 38b ten-acoustic-mode count stays available as an option | User Manual card 10 (decision from the document, 2026-10-23) | none (input correction); E18_TONES, REPRO_18b and T1 re-run with this default, labelled post-hoc |
| 43b | `T1_MEAS_DAMPING`: the test article with **measured** damping: η_n per band from the measured absorption of Fig. E-13 by η_n = c₀Sα/(4ωV) (CR-3813 p. E-21), η_r′ from the measured decay values of Fig. E-15 (re-digitized, all points; log-interpolated in frequency, end values held), everything else as T1 | measured damping of the same article (independent of the E-16 interior levels) | T1's gate unchanged: within ±4 dB of the measured E-16 mean at each of H1–H3 |
| 43c | H3 attribution on REPRO_18b (E-17 conditions): one block at a time replaced by NASA's own value: η_n by the E-14 calculated curve; η_r′ by the E-15 calculated curve; both; ℓ = 1 levels by the measured E-12 blocked levels | NASA's printed intermediate values | none (diagnostic; shift of H3 recorded per swap) |
| 43d | Bare-cylinder validation from NASA TP-1964 (unstiffened aluminium cylinder, 0.508 m diameter, 1.245 m long, 1.63 mm wall, closed ends, no trim, no floor): digitize the measured reverberant-field noise reduction (1/3-octave), NASA's predicted curve on the same figure, and the measured reverberation times; compute the noise reduction with Eqs. (17)–(18) using Donnell shell modes, the exact circular-cavity acoustic modes, and damping from the measured reverberation times (η = 2.2/(f T₆₀)) | independent NASA experiment | `NR_TP1964` against measured: within ±5 dB in at least 75 % of the 1/3-octave bands from 100 to 5000 Hz; against NASA's predicted curve (V-CODE): within ±3 dB in at least 75 % of those bands |
| 43e | T2 input: search for a measured exterior broadband spectrum of the test article (CR-3813, CR-172428, NASA reports of the Langley test); if found, `T2_MEAS_EXTERIOR` feeds it through Eqs. (19)–(23); if not, T2 is recorded as "exterior broadband not measured: input assumed", and the high-frequency transmission path is validated by 43d instead | data availability | T2's criterion unchanged (±3.5 dB, 1.25–2 kHz) |
| 43f | `T1_F1A_FILL`: T1 exactly, except the off-line free field: the ℓ = 1 line keeps the ANOPP Table-8 levels and phases T1 uses, and every other grid point takes the **relative** pattern of the full-grid F1A computation of the same propeller (amplitude ratio A_F1A(k,ℓ)/A_F1A(k,1) and phase difference φ_F1A(k,ℓ) − φ_F1A(k,1), per harmonic), as in `scripts/run/compare_gext_vs_f1a_grid.jl`, instead of GEXT's assumed cos α falloff and delay | physics model of the off-line field (F1A of the same propeller), independent of E-16; `gext_vs_f1a_grid.md` shows the two fills differ by up to ±9 dB around the fuselage | T1's gate unchanged; result labelled V-EXP with an F1A-shaped off-line field (no fit) |

Anything decided after seeing a result of these runs is post-hoc and labelled. If 43b passes, T1 is reported as passing **with measured damping** (the damping model of App. A / §3.8 is then the identified weak block, with E-14/E-15 as its evidence); if it fails, the miss is attributed with 43c.

**Result (2026-10-23; criteria unchanged).** 43a: the card-10 changeover is f = 4.1·c₀/∛V = 1299.6 Hz → 1260 Hz band, so H1–H3 all use Eq. (8); the ten-mode rule stays as `rule=:ten_modes` and remains the NR-path default (fixed for 38a). The `:auto` re-runs are labelled post-hoc (old ten-mode values kept): T1 84.21/77.66/78.06, REPRO_18b 85.90/78.35/79.82, E18_TONES 88.67/77.78/77.55. 43b `T1_MEAS_DAMPING` **not met** 2/3 (93.78/80.06/79.41 dB vs 90/80/65; H3 +14.4 dB). 43c (`h3_attribution.md`): swapping η_n, η_r′ or the ℓ = 1 levels for NASA's printed values moves H3 by at most 1.7 dB, so the H3 excess is not in the loss factors or the source line. 43d `NR_TP1964` **not met** 6/18 vs measured and `NR_TP1964_REF2` **not met** 6/18 vs NASA's curve. The first run (5/18, 4/18) had NR = +∞ at 100–160 Hz because a 4×-band-centre mode window dropped every coupled pair. That is a code defect, fixed the same day: every computed mode now enters each band sum. Computed NR is negative at 1–3.15 kHz, where the modal formula runs above the card-10 changeover (≈ 2.3 kHz for this cylinder). 43e: there is no measured exterior broadband spectrum of the test article in CR-3813, CR-172428, TP-1964, TP-2444 or CR-172384, so T2's input stays V-ASSUMED. 43f `T1_F1A_FILL` **not met** 2/3 (79.61/71.19/71.30 dB). The diagnostic F1A fill plus measured damping gives 90.00/73.46/72.60. **Reading:** no documented input change brings H3 within ±4 dB. Phase 44 checks next whether NASA's own program gives the same H3 excess with NASA's own blocked field (CR-172428 Table 10 prints 71.3 dB for H3 at 4000 rpm against 65.2 dB measured).

### Phase 44 — Reproduce NASA's fundamental validation of this test article (CR-172428 §3, App. A, App. B) *(done 2026-10-23 with open item 44f; planned 2026-10-23; criteria below dated 2026-10-23 before any transcription or run)*

**What CR-172428 (Pope 1984, "the fundamental validation of the model"; CR-3813 App. E is called "preliminary") documents for the same 1.016 m test article.** (1) Measured space-average interior levels from 196 microphone positions at 3000, 4000 and 5000 rpm, H1–H3 (Table 5; 4000 rpm: 90.3 / 80.3 / 65.2 dB, the E-16 means). (2) All measured loss factors (Table I: cabin acoustic, trim panel, fuselage structural). (3) NASA's input set (Table 6): trim loss factor η_T = 0.13 (the measured average), trim mass 1.82 kg/m², shell length 1.803 m, cavity length 1.829 m, bare structural loss factor 2/f_r, propeller r_p = 0.9652 m, z_p = 0.662 m, rotation +1, 300 structural and 400 acoustic modes. (4) Three corrections to the CR-3813 program by its authors (App. A): the structural loss factor of Eq. (82) recomputed with the modal mass over the trimmed area, (η_r′)² = |C_w|²/(m̄_r²ω_r⁴) − 2C_w^I η_r/(m̄_r ω_r²) + η_r², m̄_r = m M_r/M_r^X ("removes the need to limit η_r′ at low frequencies"); the shell/floor sign in f′(n,r) (our Eq. (52) already has the corrected sign); the blocked-pressure increase limited to about 4 dB (our R2 is this change). (5) App. B: the full blocked pressure field PAIN used (amplitude and phase on the 16 × 19 grid including the mirrored lower quarter, H1–H3, three speeds), the structural and acoustic mode lists with loss factors, the trim properties, and NASA's interior predictions with the dominant modal contributors. (6) NASA's predictions against measurement (Table 10, η_T = 0.13): 4000 rpm 91.7 / 78.2 / 71.3 dB; the model is described as unbiased with a standard deviation of about 4–8 dB, with an H2/H3 bias. **Consequences:** CR-3813's E-17/E-18 predictions came from the program before these corrections, so they are not a clean code target; the full-grid ANOPP field (said not to exist in 17j) is printed in App. B; PAIN mirrors the upper-quarter data to the lower quarter (I-18 is settled by the documents: adopted for this reproduction, dated 2026-10-23).

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 44a | Transcribe App. B blocked-pressure fields (pp. 198–200, 203–205, 208–210: amplitude and phase, 16 × 19, H1–H3, three speeds) by OCR on 300 dpi renders, a second independent pass (different resolution and crop), and checks: amplitude rows L and 20 − L must be equal (mirroring), the L = 10 row must equal the printed ANOPP Tables 7–9 free field + the R2 increase within 0.15 dB, smoothness along k; every disagreement resolved by eye on the image and listed | all checks pass; unresolved cells listed, not filled |
| 44b | Transcribe App. B printed intermediate outputs: structural modes (frequency, loss factor), acoustic modes, modes per band, trim properties, NASA's predicted space-average levels and top contributors | recorded with page references |
| 44c | Implement the App. A η_r′ correction (trimmed-area modal mass) as a documented model correction (default for the reproduction; CR-3813 printed form kept as an option) | V-UNIT: reduces to the printed form when the trim covers the whole surface (M_r^X = M_r) to 1e-12 |
| 44d | `R172428_CODE`: our chain with the App. B blocked field as input (no GEXT, no blocking model), Table 6 inputs, η_T = 0.13, against NASA's printed predictions at 3000/4000/5000 rpm, H1–H3 (9 points); our structural and acoustic mode counts raised toward NASA's (App. D solver for structural modes; CYL2D modes to the band NASA lists), stated | V-CODE: within ±3 dB of NASA's printed prediction at ≥ 7 of 9 points; structural loss factors of the listed modes within ±25 % of App. B |
| 44e | `R172428_EXP`: the same predictions against the measured Table 5 levels (T1 is the 4000 rpm row) | V-EXP: within ±4 dB of the measured space average at each point (T1's ±4 dB), reported per point; plus CR-172428's own bias/standard-deviation statistics |

Nothing is fitted: η_T = 0.13 and all other inputs are NASA's documented values, measured independently of the interior levels; the blocked field is NASA's printed input.

**Result (2026-10-23; criteria unchanged).**

- **44a, transcription (`data/cr172428/appB_<rpm>rpm_H<H>.csv`, 9 pages).** The pages were read visually from 300 dpi crops. On pp. 203–205 and 209–210, per-cell OCR (RapidOCR, five variants) served as the second pass, and every disagreement was re-read at 600 dpi; all resolved to the visual reading. On pp. 198–200 and 208 the OCR grid misregistered rows and columns, so the second pass there is: mirror rows L = 1–9 read and compared with rows 20 − L, plus every row crossed by a ruled line re-read at 600 dpi.
- **44a, check results.**
  - Mirror check: met, with four listed exceptions where one of the two mirrored cells is on a ruled line and prints a 6-like 8: p. 204 L17 k2 and L9 k3, p. 210 L17 k2 and L4 k12. The mirrored value is recorded and the cell listed. p. 208 amp L13 k1 prints 106.9 on a ruled line; recorded as 108.9, listed.
  - Unresolved cells, left empty: phases at the scanned page edge (p. 198 L1–L2 and L3 k16; p. 200 L1; p. 204 L1; p. 208 L1).
  - **L = 10 against Table 8 + R2 within 0.15 dB: not met as written.** The increase is 3.6–4.1 dB with the same axial pattern at H1, H2 and H3 (ends lower), so R2 is position-dependent in NASA's run, not a flat 4 dB. The identical pattern across three independent pages supports the transcription. Tables 7 and 9 (3000 and 5000 rpm) were not transcribed, so this check covers 4000 rpm only.
- **44b.** App. B structural modes (p. 194), acoustic modes (p. 195), trim (p. 197), 4000 rpm predictions (p. 206), contributors (p. 207) and Table 10 are recorded in `data/cr172428/`.
- **44c.** `η_r_trimmed_area` / `app_a_modal_mass_per_area` (V-UNIT met to 1e-12). M_r^X follows NASA's program change (GMASS(IR,2) = shell bending mass over the whole shell); it reproduces App. B "SHELL W" (median 0.19 %, at most 3.8 % over the 21 modes above 0.05 kg (Table D-1 prints five shell terms per mode)).
- **Code fix found by the comparison.** Eq. (83) uses the bare f′(n,r) (CR-3813 p. 43; App. A distinguishes f′ from the trim-weighted f̄′; TONE line 107 vs 111). We passed f̄′. The fix is code-on-code and applies to production. T1 moves to 84.24 / 77.63 / 77.80 dB; Phase 17 baselines, REPRO_18b and the Phase 43 values are re-recorded with dated notes, and no verdict changes. NASA's printed η_r″ for (2,0) × mode 2 is 0.0071; ours is 0.0063 with f′ and 0.0018 with f̄′.
- **44d R172428_CODE: not met**, 3/9 within ±3 dB.
  - Ours − NASA: 3000 rpm +5.0 / +2.8 / +1.1; 4000 rpm +8.6 / −3.5 / +2.6; 5000 rpm +3.1 / +7.6 / +3.5 dB.
  - **R172428_ETA: not met**, 17/32 within ±25 %. Modes 1–12 agree within 13 %; modes 13–32 are 30–50 % low.
  - Mode counts were not raised: 32 Table D-1 modes, which are NASA's first 32, and 20 CYL2D modes. Stated in the case.
  - Blocks verified against NASA's printout on the way:
    - Trim factor and admittances: R172428_TRIM, within 0.15 dB at 250–1000 Hz.
    - Acoustic mode frequencies and ε: exact ε, frequencies within 0.9 % (c₀ = 343 m/s from the printed axial mode).
    - η_n: mostly within ±30 %, except next to the sharp trim resonance.
    - Shell generalized masses: median 0.19 %, at most 3.8 %.
    - η_r′ of the low modes: within 13 %.
  - **Where the difference sits (R172428_PAIRS, 4000 rpm).** Pairs with shell-dominated modes agree within 0.4–2.5 dB. Pairs with the floor-dominated modes 1 and 2 are 10–12 dB low. Our largest H1 pair, acoustic (0,1) × antisymmetric mode 8 (3.6 Pa², six times NASA's H1 total), is absent from NASA's top five. A trial with the trim weight removed from f̄′ reproduces NASA's ranking of pairs, but CR-3813 Eq. (52) and the App. A program change both print √τ·FINS − FINP, as we have. So that trial is a diagnostic only; nothing was changed to match.
- **44e R172428_EXP: not met**, 1/9 within ±4 dB. NASA's own printed predictions meet the same gate at 5/9 and miss 3000 rpm H1 by −17.7 dB and 5000 rpm H1 by −13.8 dB.

**Reading for T1.** With NASA's own blocked field, our H3 at 4000 rpm is 73.9 dB (71.7 dB after 44f) against NASA's 71.3 and the measured 65.2. The 6 dB H3 excess over measurement is therefore in PAIN itself, not only in our GEXT field (T1 GEXT H3 77.8). NASA's PAIN fails T1's ±4 dB at H3 (+6.1 dB) with its own inputs. T1 cannot be passed by a correct implementation of PAIN, and claiming it would require tuning, which is not allowed.

**44f (done 2026-10-23; code-on-code fix, results after it labelled post-hoc).** NASA's printed η_r″ ("ETA R#", App. B p. 207) together with NASA's own ε_n, η_n and M_r gives the bare |f′| NASA's corrected program used for each printed pair. For 8 of the 9 pairs it equals |I_s + I_p| of our shell and floor integrals within 2.5 %, symmetric and antisymmetric alike; the ninth has I_p ≈ 0. Our I_s − I_p is 15–80 % off. CR-172428 App. A item 2 records that the original program misread MRP's sign convention in exactly this term, and our minus sign reproduced NASA's pre-correction CR-3813 runs (E-17/E-18). The floor term now enters f̄′ with a plus on the raw Table D-1 coefficients. The |f′| ≤ 1 guard moves to the bare f′, since √τ_t > 1 at a trim resonance. Knock-on, labelled post-hoc because T1-family results had been seen:
- R172428_PAIRS: 12 of 15 printed pairs within ±3.7 dB (was 4 within ±3 dB).
- R172428_CODE 4/9; R172428_EXP 3/9. The 4000 rpm H2/H3 agree with NASA (80.05 vs 78.19, 71.69 vs 71.30 dB).
- T1: 87.36 / 81.02 / 75.23 dB (H1, H2 within ±4 dB of measured; H3 +10.2 dB).
- **T1_F1A_FILL met 3/3** (82.12 / 74.59 / 66.95 dB). It is post-hoc, not a pre-registered pass, and the F1A off-line field it uses is V-ASSUMED.
- REPRO_18b, E18_TONES and E21_E22_NR lose sub-points, since they compare with NASA's pre-correction runs.
- Phase 17 baselines re-recorded (29 values, dated).
**Out-of-sample confirmation (2026-10-23):** ten further pairs from the 5000 rpm page (App. B p. 212), which were not used to choose the sign, give NASA's implied |f′| = |I_s + I_p| within 1.1 % for nine. One of them is antisymmetric mode 8 with (2,1): 0.0741 against 0.0747, where the old sign gives 0.0151. The tenth has η_r″ printed as 0.00001, too coarse to compare. Data: `appB_contributors_5000rpm.csv`; regression test over the 19 pairs printed to two or more digits (within 5 %, recorded post-hoc). The remaining large difference is the single pair (0,1) × mode 8 at H1, open as Q22.

## 8c. Phase 45 — T2's high-frequency path on an independent experiment *(done 2026-10-23; pre-registered 2026-10-23, before any run of it; moved to the bottom 2026-10-23)*

T2 (CR-3813 Fig. E-9, 1.25–2 kHz) cannot be validated end to end: no measured exterior broadband spectrum of the test article exists (43e), so its input is V-ASSUMED. The cabin part of T2 is the high-frequency transmission of Eqs. (19)–(23), which 43d did not test: it applied the modal Eq. (18) up to 5 kHz.

| Step | What | Pass criterion (fixed 2026-10-23, before the run) |
|------|------|---------------------------------------------------|
| 45a | `NR_TP1964_XOVER`: TP-1964 bare cylinder (inputs as 43d: R = 0.252 m, L = 1.193 m, t = 1.63 mm aluminium, closed ends, no trim, no floor; Donnell shell modes; η_n and η_r′ from the measured reverberation times, η = 2.2/(f T₆₀)). PAIN's own switch: Eq. (18) below the card-10 changeover band (the band containing f = 4.1 c₀/∛V), Eqs. (19)–(23) at and above it. The cylinder is taken as θ₀ → 0 (no floor; absorbing area S = 2πRL + 2πR²); the Eq. (19) inputs are the Donnell modes with the measured η | V-EXP: within ±5 dB of the measured NR in ≥ 75 % of the 1/3-octave bands 100–5000 Hz (as 43d); reported separately for the bands at and above the changeover |
| 45b | The same against NASA's predicted curve on the figure (ref. 2) | V-CODE: within ±3 dB in ≥ 75 % of those bands |

No parameter is chosen from Fig. 8: all inputs are the 43d inputs, and the changeover follows the card-10 rule of 43a.

**Result (2026-10-23; criteria unchanged).** 45a `NR_TP1964_XOVER` **not met**, 9/18 within ±5 dB; 45b **not met**, 8/18. The four bands on Eqs. (19)–(23) (2.5–5 kHz) agree with the measurement within ±2.5 dB. The misses are all modal Eq. (18) bands: negative NR at 1–2 kHz and 100–315 Hz. The first run the same day (8/18 and 7/18) put the 2500 Hz band on Eq. (18) because the code compared exact against nominal band centres (2520 vs 2500 Hz); that was fixed to the written rule, the band containing f. **Reading for T2:** the high-frequency transmission block T2 uses (Eqs. 19–23) is supported by an independent experiment above the changeover. *Qualified by Phase 47 (2026-10-23): that holds for the bare cylinder. For the trimmed test article, the same equations overpredict noise reduction by 15–27 dB at 1250 Hz.* T2's input, the exterior broadband spectrum, remains unmeasured (V-ASSUMED), so T2 itself cannot be validated.

## 8d (done part). Phases 46–47 *(done 2026-10-23; moved to the bottom 2026-10-23; Phase 48 stays in §8d)*

### Phase 46 — Isolated checks for the five untested T1/T2 functions *(done 2026-10-23; V-UNIT; criteria fixed 2026-10-23)*

Each check computes the printed equation by hand in the test, for stated inputs. The hand path is written from the equation in CR-3813, not by calling the function's helpers, so the check fails if the function departs from the equation (CLAUDE.md check 6).

| Step | Function | Check | Pass criterion (fixed 2026-10-23) |
|------|----------|-------|-----------------------------------|
| 46a | `broadband_cabin_p2` | Two bands of the T1/T2 test-article inputs: its documented formula by hand (τ_t, ⟨j²⟩_rev, χ = n/n_ref, absorption, `j2_scale`); linearity in `p2_bl` and in `j2_scale`; zero for `p2_bl` ≤ 0 | relative difference ≤ 1e-9; linearity exact to 1e-12 |
| 46b | `tone_expected_value` | Synthetic cabin with one acoustic and one structural mode in the band: Eqs. (14)–(16) by hand (mode counts, η̄_n, η̄_r, E[g]). N-mode scaling: doubling every in-band mode, with identical properties, doubles the Eq. (16) mode sums | ≤ 1e-9 relative; scaling exact to 1e-12 |
| 46c | `hf_structural_band`, `hf_band_loss_factors` | Synthetic `StructuralModes` with three modes inside the band and two outside, with known joint acceptances: n_r, ⟨j²⟩, Σ(j²)², and the asymptotic branch when no mode is in the band; η̄_n, ᾱ (Eq. 24) and η_rad (Eq. 81) by hand | ≤ 1e-12 relative; branch selected as specified |
| 46d | `coupling_loss_factor_21` | Eqs. (A.20)–(A.21) by hand for stated m, h, c_l, m_t, h_t, c_t, N and line length; zero when N = 0 and the line length is 0; point and line parts additive | ≤ 1e-12 relative |
| 46e | whole suite | Line coverage of the full suite (`Pkg.test(coverage=true)`, run started 2026-10-23): every physics function with a never-executed branch either gets a test or is listed with the reason | list recorded; no criterion beyond completeness |

**Result (2026-10-23; criteria unchanged).** Phase 46 is **met**: 37/37 checks in testset "Isolated checks for T1/T2 functions (phase 46)".
- 46a `broadband_cabin_p2`: matches its formula assembled by hand at 1250 and 2000 Hz within 1e-9; linear in `p2_bl` and `j2_scale`; zero for `p2_bl` ≤ 0.
- 46b `tone_expected_value`:
  - Eq. (16) by hand at 600 Hz within 1e-9.
  - η̄_n and η̄_r band averages exact.
  - The closed-form E[g] path reduces to the π-limit Eq. (15) when E[g] = πω_H/(2η̄Δω).
  - Doubling every in-band structural mode doubles Eq. (16).
  - An empty band (125 Hz) gives zero.
- 46c `hf_structural_band` / `hf_band_loss_factors` (synthetic set, 3 modes in band, 2 outside): n_r, ⟨j²⟩, Σ(j²)², the asymptotic branch, η̄_n, ᾱ (Eq. 24), η_rad (Eq. 81) and η̄_r′ all exact to 1e-12.
- 46d `coupling_loss_factor_21`: Eqs. (A.20)–(A.21) by hand within 1e-12; zero with no connections; the point part alone equals Eq. (A.20).
- 46e, from the full-suite coverage run of 2026-10-23: the functions on the T1/T2 paths that the suite never executed now have checks:
  - `tone_Q_H`: Q_H of p. 17 by hand.
  - The α = 1 branch of `blocked_broadband_band_p2`: it is the limit of the power-law branch within 1e-5.
  - `w_in_reverberant`: linear in p_bl², and the total equals the sum of its contributions.
  - Never-executed functions off the T1/T2 paths are listed in `block_validation_audit.md`.

### Phase 47 — T2 with a measured exterior spectrum of the test article *(done 2026-10-23; criteria fixed 2026-10-23)*

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 47a | Digitize into `data/tp2444/` and `data/cr172428/`: TP-2444 Fig. 17 (exterior and interior traces, 0–1500 Hz), CR-172428 Fig. 14 (0–2000 Hz) and TP-2444 Fig. 19 (1/3-octave, both rotation directions). Two independent digitizations of each trace, QA overlays, tone peaks marked; figure and page references in the headers | the two digitizations agree within 1 dB median and 3 dB at the 95th percentile of points; tone frequencies at H·200 Hz within one analysis bin |
| 47b | Narrowband → 1/3-octave: energy sum of the trace over each band, with the tone peaks (H·BPF ± 2 bins) removed for the broadband level. TP-2444 does not state the analysis bandwidth B. **B = 5 Hz is assumed** (V-ASSUMED), because the same laboratory's CR-172428 Fig. 17 states 5 Hz; the sensitivity for B = 2.5–10 Hz (±3 dB) is reported. Band ratios (47c) do not depend on B | conversion code checked on a synthetic flat spectrum (exact band level) |
| 47c | `NR_PROP_TP2444`: measured broadband noise reduction of the article under propeller excitation, NR = L_ext − L_int per 1/3-octave band, against the model's noise reduction for the same article. Primary inputs: the CR-172428 App. B trim (the documented trim of this article closest in date to TP-2444; the TP-2444 fiberglass trim has no printed properties) and the card-10 changeover (Eq. 18 below, Eqs. 19–23 at and above). The CR-3813 Phase III trim is reported alongside, with no criterion | V-EXP: within ±5 dB in ≥ 75 % of the broadband 1/3-octave bands 315–1250 Hz (tone bands excluded) |
| 47d | `T2_MEAS_EXT`: T2 with the measured exterior. The 1250 Hz exterior band level from 47b is taken as the blocked surface pressure (V-ASSUMED: it is the microphone recording the "exterior noise applied to the model", position not stated). It goes through T2's production cabin path (Eqs. 19–23, T2 inputs) and is compared with CR-3813 Fig. E-9. The 1600 and 2000 Hz exterior levels are extrapolated with the slope of CR-172428 Fig. 14 between its 1250 and 2000 Hz bands (shape V-ASSUMED) and reported separately | V-EXP: the 1250 Hz band within ±3.5 dB of E-9 (51.0 dB), T2's gate. 1600/2000 Hz: same gate, labelled "extrapolated exterior". Secondary: the 1250 Hz interior against TP-2444 Fig. 17's own interior trace (same run), ±3.5 dB |
| 47e | Consistency loop (data only): E-9 interior + model NR (47c inputs) against the measured exterior floor of 47b | reported (no criterion) |

**Implementation decisions for 47b–47d (fixed 2026-10-23, after 47a and before any band level, NR or interior level was computed).** The plan text above leaves these open:
- **Bins.** Each trace is sampled at 5 Hz bin centres (k·B), at the mean of the digitized columns within ±B/2. A band holds the bins with centres in [f_c·2^(−1/6), f_c·2^(1/6)), where f_c is the exact centre 1000·2^(k/3).
- **Tone bins.** A bin is a tone bin if it lies within ±2 bins (±10 Hz) of H·BPF **or** of the observed tone peak, whichever is further out. The observed peak is the maximum of the top of the ink within H·BPF ± 0.15 BPF, as in the 47a QA. The union is used because the CR-172428 Fig. 14 peaks sit 9–22 Hz below H·250 Hz (47a: the frequency axis is offset from the trace). Peak positions are a property of the figure's registration, not of any data a case is compared with.
- **Filling the tone bins.** For the broadband level, removed tone bins are filled with the mean mean-square of the kept bins in the same band. A flat spectrum therefore gives the exact band level with or without tones.
- **Partial bands.** A band that the trace covers only in part is scaled by (number of bins in the band)/(number of bins covered), which assumes a flat density over the uncovered part. This applies to Fig. 14's 2000 Hz band, whose trace ends at 1981 Hz. The coverage is reported, and a band less than 40 % covered gets no value.
- **47c bands.** "Tone bands excluded" is read as: use the broadband level (tones removed as above) in all seven bands 315–1250 Hz. The strict reading, bands that contain no H·200 Hz (315 and 500 Hz only), is reported alongside with no criterion.
- **47c model.** `noise_reduction_band` on `r172428_inputs(4000)`: Eq. (18) below the card-10 band (`volume_crossover_band`), Eqs. (19)–(23) at and above it, no η_r′ cap. The Phase III alternative swaps in the sidewall, end and mechanical trim of `phase3_trim(η_lining = 1.0)` and keeps the article's shell.
- **47d path.** p_bl² = p_ref²·10^(L_ext/10) into `hf_broadband_band_p2(T2 inputs, b, p_bl²)`. That is T2's production broadband path with `broadband_model = :eq19` and the T2 pipeline inputs (`:e11`, R2, 5 harmonics, BPF 200 Hz). The extrapolation is L(1600) = L(1250) + S/2 and L(2000) = L(1250) + S, with S = L_bb,2000 − L_bb,1250 from Fig. 14 pass A.
- **Pass A is primary** for every figure. Pass B is reported as the digitizing sensitivity.
- **47d exterior level.** The broadband (tone-removed) 1250 Hz band level is used. T2's 1250–2000 Hz bands carry only broadband energy, because its tones stop at H5 = 1000 Hz. The total band level (tones included) is reported alongside.

**Result (2026-10-23; criteria and the implementation decisions above unchanged).** Report: `validation_reports/t2_measured_exterior.md`.

- **47a: not met as written** (Fig. 19 met). Two-pass agreement, median / p95 of all points:

  | Trace | Median (dB) | p95 (dB) |
  |-------|-------------|----------|
  | Fig. 17 exterior | 0.63 | 7.62 |
  | Fig. 17 interior | 0.65 | 4.75 |
  | Fig. 14 | 0.87 | 4.07 |
  | Fig. 19 | 0.17 | 2.17 |

  - The all-points misses are near-vertical tone lines, where the centre and top-of-ink rules differ.
  - Broadband points alone give 0.60/1.73 (Fig. 17 exterior), 0.62/2.68 (interior) and 0.83/3.69 dB (Fig. 14).
  - Tone peaks:
    - Fig. 17 exterior: 5 of 7 within one 5 Hz bin (H1 +6 Hz, H3 +7 Hz).
    - Fig. 17 interior: H1–H3 within one bin; H4–H7 not identifiable.
    - Fig. 14: all 9–22 Hz below H·250 Hz. Its frequency axis is offset from the trace.
- **47b: met.** The conversion is exact on synthetic spectra: flat, with a tone, partly covered, and B = 10 Hz. Changing B moves the 1250 Hz exterior level by +4.3 dB (B = 2.5 Hz) and −3.9 dB (B = 10 Hz).
- **47c `NR_PROP_TP2444`: not met, 1/7** (only 1000 Hz). The strict reading gives 0/2.
  - The measured broadband NR is 30.0–36.0 dB in every band from 315 to 1250 Hz.
  - The model (App. B trim) gives 16.6, 13.5, 7.5, 5.0 and 8.7 dB at 315–800 Hz (Eq. 18: 18–26 dB too little), 34.0 dB at 1000 Hz, and 49.1 dB at 1260 Hz (Eqs. 19–23: 15 dB too much).
  - Phase III trim (no criterion): 10.9–19.0 dB below 1000 Hz, 41.9 dB at 1000 Hz, 55.7 dB at 1260 Hz.
- **47d `T2_MEAS_EXT`: not met.**
  - The measured exterior at 1250 Hz, 85.4 dB broadband, gives an interior of 21.3 dB against E-9's 51.0 dB.
  - With the extrapolated exterior (Fig. 14 slope +0.3 dB): 19.7 and 19.9 dB at 1600 and 2000 Hz, against 46.0 and 41.5 dB.
  - Secondary, the Fig. 17 interior (51.5 dB): not met.
  - Post-hoc information: the production surrogate gives 38.6 dB with the same exterior. T2's own modelled blocked broadband is 102.7 dB, 17 dB above the measured exterior.
- **47e (no criterion).** E-9 plus the model NR exceeds the measured exterior by 14.6, 18.9 and 25.5 dB at 1250, 1600 and 2000 Hz.

**Reading.** The measurements agree with each other: exterior 85.4 dB less measured NR 33.9 dB gives 51.5 dB, and E-9 is 51.0 dB. What fails is PAIN's predicted noise reduction of the trimmed article.
- Above about 1 kHz the printed Eqs. (19)–(23) give 15–27 dB too much.
- NASA's own printed predictions show the same excess: CR-3813 Figs. E-21/E-22 give 52–69 dB at 1250–2500 Hz, against 19.5–32 dB measured. This code gives 60–62 dB with the E-21 inputs.
- Below the changeover, Eq. (18) gives too little.

**What this means for T2.** T2 cannot be shown right with the printed method. Its production result near E-9 rests on a modelled exterior 17 dB above the measurement and on the calibrated `bb_j2_scale`. Phase 45's support for Eqs. (19)–(23) holds for the bare cylinder only.

**Candidate cause, not tested.** In Eq. (23) the trim and the wall transmit in series (τ_t·τ), with no path that bypasses the trim.

## 8d. Phases 46–48: isolated checks for the last T1/T2 functions, and T2 with a measured exterior spectrum *(all done 2026-10-23; moved to the bottom 2026-10-23; Phases 46–47 are in "8d (done part)" above; planned 2026-10-23; author request "yes make the plan"; criteria below dated 2026-10-23, before any of these checks is written or run)*

**Why.**

- *Function coverage.* On 2026-10-23 I traced which functions run for T1 and T2 (`--code-coverage` on the T1, T2 and T2_EQ19 cases): 125 functions are on those paths.
  - 100 are called directly by a test or validation case.
  - 25 are reached only through the chain. About 20 of those are internals of blocks that have their own isolated check (CYL2D solver pieces, the `nr_*` terms inside `nr_brace`, table loaders, band-card plumbing).
  - Five carry physics and have no isolated check:
    - `broadband_cabin_p2`: T2's broadband transmission.
    - `tone_expected_value`: Eqs. 14–16.
    - `hf_structural_band` and `hf_band_loss_factors`: the band averages of Eqs. 19–20.
    - `coupling_loss_factor_21`: the trim mechanical path, Eqs. A.20–A.21, part of T1's Phase III trim.
- *A measured exterior spectrum.* T2 has been blocked because no measured exterior broadband spectrum of the test article was known (43e). A search on 2026-10-23 found one:
  - **NASA TP-2444 Fig. 17** (Willis, Mayes & Daniels 1985). TP-2444's "model 2" is this test article: D = 1016 mm, L = 1803 mm, propeller plane 662 mm from the front, tip clearance 76 mm, fiberglass trim, 23.8 m/s inflow. Fig. 17 shows the exterior and interior narrowband spectra of the same 4000 rpm run, 0–1.5 kHz.
  - CR-172428 Fig. 14: free-field exterior spectrum, 5000 rpm, 0–2 kHz, no fuselage.
  - TP-2444 Fig. 19: model 2 space-averaged interior 1/3-octave spectrum, 4000 rpm, propeller at θ_p = 135°, to 6.3 kHz.

### Phase 48 — Predict the exterior broadband from physics *(done 2026-10-23; criteria fixed 2026-10-23)*

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 48a | Download NASA RP-1218 (Brooks, Pope & Marcolini 1989, airfoil self-noise) from NTRS into `references/` with a checksum. Implement the turbulent-boundary-layer trailing-edge, separation and tip-vortex terms; V-UNIT against the printed RP-1218 example spectra | within 1 dB of the printed example spectra at ≥ 90 % of the plotted points |
| 48b | Propeller broadband at a field point from 48a: the BEMT section loads (CCBlade, as R996_LOADS) of the 0.76 m propeller, strip sum and Doppler factor | — (model) |
| 48c | `PROP_BB_FIG14` / `PROP_BB_FIG17`: 48b against the broadband floors of CR-172428 Fig. 14 (5000 rpm, free field) and TP-2444 Fig. 17 (4000 rpm), after 47b | V-EXP: within ±5 dB in ≥ 75 % of the 1/3-octave bands 315–2000 Hz (Fig. 17: to 1250 Hz) |
| 48d | T2 fully predictive: 48b exterior → T2 cabin path → E-9 | V-EXP: T2's gate (±3.5 dB, 1250–2000 Hz) |

**48a result (2026-10-23).** Met. The Julia port of RP-1218 §5 (`src/bpm_airfoil_noise.jl`) reproduces NASA's printed code output, App. D Tables D2 and D3 (`data/rp1218/`), within 0.04 dB for TBL-TE pressure/suction, separation and LBL-VS, and within 0.19 dB for tip noise. That is 100 % of the points, against the 1 dB / 90 % criterion. Bluntness is not ported: neither table uses it, and the test blade's trailing-edge thickness is unknown.

**48b–48d implementation decisions (fixed 2026-10-23, before any comparison with Fig. 14, Fig. 17 or E-9):**
- **Blade (V-ASSUMED).** The real blade geometry is proprietary (CR-172428 p. 56; CR-3813 p. E-5). The stand-in is the NACA 4-(5)(08)-03 planform of Report 996, which uses NACA 16-series sections like the test propeller's Series 16. It is scaled to D = 0.762 m, with 3 blades and β(0.75R) = 20° (CR-172428 p. 17), and uses the Report 996 primary polar set. Inflow is 23.8 m/s.
- **Noise procedure** (RP-1218 App. C). Untripped boundary layers; TBL-TE plus separation, LBL-VS and tip noise (rounded tip); no bluntness. The aerodynamic angle (α − α_L0, from the polar) is used for the boundary layer and TBL-TE, and the geometric angle for LBL-VS. Each blade section is one segment, with 16 azimuths, a Doppler shift and B blades. The chordwise axis is along the relative wind, induction is ignored, and directivity uses RP-1218 App. B.
- **Observers.** Fig. 14 microphone 1 is at r = 0.457 m from the axis and 0.254 m upstream of the propeller plane (CR-172428 Fig. 9), free field, 5000 rpm. Fig. 17's exterior microphone (position not stated) is taken at the fuselage surface in the propeller plane, r = 0.457 m, free field, 4000 rpm; the CR-172428 4 dB blocking limit is reported alongside with no criterion. Both points are within about 0.3 m of the tip, nearer than BPM's far-field basis, so the label is X-EXTRAP.
- **Measured side.** The 47b broadband band levels (pass A, tones removed, B = 5 Hz).
- **48d.** The 48b level at the Fig. 17 point, treated as blocked pressure, is fed through T2's production Eq. (19)–(23) path (as 47d), and the result is compared with E-9.

**Result 48b–48d (2026-10-23; criteria and decisions unchanged).** Report: `validation_reports/phase48_exterior_broadband.md`.
- **48c `PROP_BB_FIG14`: not met, 3/9.** BPM is 3–10 dB low.
- **48c `PROP_BB_FIG17`: not met, 2/7.** 1000 and 1250 Hz are within 3.6 and 3.1 dB; 315–800 Hz are 7–15 dB low.
- **48d `T2_PRED_BB`: not met.** Interior 18.4/17.4/17.9 dB against 51.0/46.0/41.5 dB. The miss comes from the cabin path (Phases 47 and 49). The BPM exterior is within about 3 dB of the measured one at 1250 Hz.
- **Limits.** Self-noise only (no inflow-turbulence ingestion), an assumed blade, and a near-field observer (X-EXTRAP).

**Note after Phase 47 (2026-10-23; criteria unchanged).** 47 shows that the T2 gap is in the cabin path, not only the exterior. 48d cannot pass with the printed Eqs. (19)–(23), which overpredict this article's noise reduction by 15–27 dB at 1250 Hz. 48a–48c, the exterior broadband, stay meaningful on their own.

**Rules.** No parameter is chosen from E-9, from the Fig. 17 interior trace or from Fig. 19. The analysis bandwidth, trim, microphone treatment and extrapolation shape are fixed above, before any digitization. Anything decided after a result is post-hoc and labelled.

## 8e. Phases 49–51: closing the T2 gap that Phase 47 found *(planned 2026-10-23 at the author's request; executed 2026-10-23 after the author's "keep implementing the phases until they are all closed out"; all closed; moved to the bottom 2026-10-23; criteria below dated 2026-10-23, before any of these is written or run)*

**Why.** Phase 47 left three gaps:
- PAIN's high-frequency noise reduction (Eqs. 19–23) of the trimmed article is 15–27 dB too high at 1250 Hz.
- Eq. (18) gives too little noise reduction below 1 kHz: 5–17 dB against 30–36 dB measured under propeller excitation.
- T2's modelled exterior broadband is 17 dB above the measurement.

**Order.** Fixes inside PAIN's printed theory come first: Phase 49, then Phase 48 (exterior, §8d), then Phase 50. Phase 51 adds physics that PAIN does not have, so it is a last resort, run only if the gap remains after 49, 48 and 50.

**Rules for every phase here.**
- No parameter is chosen from E-9, from TP-2444 Fig. 17 or Fig. 19, or from E-21/E-22. Inputs are printed geometry, trim and material data.
- Every change is an option that is off by default. The printed path stays the reference, and the existing cases keep their recorded results.
- Anything decided after a result is labelled post-hoc.

### Phase 49 — Check the trim and high-frequency inputs inside PAIN's theory *(done 2026-10-23; author: "keep implementing the phases until they are all closed out")*

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 49a | τ_t of Eq. (A.22) for the Phase III and App. B trims against an independent mass-law / double-wall calculation by hand (limp septum on a porous layer, Beranek–Work form), 250–4000 Hz | V-CODE: within 3 dB at every band; any larger difference is traced to a term |
| 49b | Look for measured transmission loss of the PF105 blanket or the Phase III trim (CR-3813, CR-172428, CR-159124, TP-2444, NTRS); download any find with a checksum | V-EXP if found: τ_t within ±5 dB in ≥ 75 % of bands; otherwise "none found" is recorded |
| 49c | Term budget of Eq. (23) at 1250–2000 Hz (ᾱS, τ_f, τ_R, τ_t, A_t, A′, η̄_r) for T2 and 47c inputs, against NASA's printed E-21 prediction | reported; states which term carries the 15–27 dB |
| 49d | A′, the untrimmed area of Eq. (23): check its value against the article drawings (windows, end caps, joints not covered by trim) | reported; any change is a documented input correction with its source page, not a fit |

**Result (2026-10-23; criteria unchanged).** Report: `validation_reports/phase49_trim_hf_inputs.md`; testset 10/10.
- **49a met.** τ_t (|a11|⁻²), rebuilt by hand element by element, equals the code within 1e-12 for the Phase III and App. B trims at 250, 1000 and 2000 Hz. The limits hold.
- **49b: no measured trim transmission loss in any report.** NASA's own statements:
  - The model "over-estimates the influence of the sidewall treatment" (CR-3813 p. E-35).
  - "Improvements to the sidewall treatment model are required" (p. E-39).
  - The trim model is valid "from about 50 to perhaps 1000 Hz" (CR-172428 p. 152).
- **49c.** The trim factor τ_t carries 22–27 dB of the predicted NR at 1260 Hz. The measured NR lies between the bare-wall and the trimmed prediction. η_T (0.13–2) does not close the gap.
- **49c, reading defect fixed.** The Eq. (20) sum ran over the in-band modes; the printed text (p. 24) says the modes resonant below the band. Effect ≤ 0.3 dB; T2_MEAS_EXT moves from 21.25 to 21.55 dB. No verdict changes, and `HF_MASSLAW` was updated (still met).
- **49d.** A′ = 0 follows the documents (septum "from floor to floor", p. E-9; ends outside Eq. 23, p. E-35). No change.

**Reading.** No in-theory input correction exists. The T2 high-frequency gap is a documented limitation of PAIN's trim model above about 1 kHz, so Phase 51's condition holds once 48 and 50 are done.

### Phase 50 — Propeller-field coupling for Eq. (18) broadband *(done 2026-10-23)*

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 50a | Option `bb_acceptance = :propeller`: the broadband structural joint acceptance comes from the propeller grid field (Ψ_G, as on the tone path, at the band centre) instead of the diffuse j_r²; off by default | V-UNIT: with a diffuse grid field it reproduces the diffuse j_r² within 1 dB |
| 50b | `NR_PROP_TP2444_PF`: 47c re-run with the option | V-EXP: same 47c criterion (±5 dB in ≥ 75 % of bands 315–1250 Hz) |

**Result (2026-10-23; criteria and decisions unchanged).** Report: `validation_reports/phase50_58_closeout.md`.
- **50a: not met as written, 2/5 within 1 dB.** The Monte Carlo sits 0.4–2.1 dB below Eq. (66), a stable offset; CR-3813 Eq. (66) is a separable approximation to the 2-D diffuse correlation.
- **50b `NR_PROP_TP2444_PF`: not met, 2/7.** At 315–800 Hz the model is within −3.4…+6.8 dB, where the diffuse model of 47c was 18–26 dB low. At 1000 and 1260 Hz (above the 32-mode set's top, 811 Hz) the model is 64 and 83 dB, which does not test the method.

**50 implementation decisions (fixed 2026-10-23, before any comparison with the TP-2444 noise reduction).**
- **Interior.** The interior band level comes from the tone path's own propeller-field machinery: Eq. (8) (`tone_mean_square_pressure`) on `r172428_inputs(4000)`. The App. B blocked field of harmonic H = clamp(round(f_c/200), 1, 3) is applied at 11 log-spaced frequencies across the band [f_c·2^(−1/6), f_c·2^(1/6)], and the results are energy-averaged. Shape assumption (V-ASSUMED): the broadband field has the spatial shape of the nearest printed harmonic, which is H3 above 600 Hz.
- **Exterior.** The exterior reference is the blocked mean square A²/2 at the grid point in the propeller plane on line ℓ = 1 (k = k_p = 8), next to the propeller. That is the same "microphone taken as blocked pressure" reading as 47d.
- **NR_PF** = 10 log10(p_ref² / ⟨p_i²⟩_band).
- **Bands, measured NR and criterion** as 47c. Eq. (8) is used in every band 315–1250 Hz, the low-frequency path; the high-frequency path is outside this option.
- **50a.** The Ψ_G machinery (`generalized_force`), fed an ensemble of 3000 random-incidence plane waves on a full-cylinder grid, is compared with the mode-normalised diffuse j_r² (Eq. 66, the Phase 16b quadrature form). Five modes, criterion within 1 dB. CR-3813 Eq. (66) multiplies the axial and circumferential acceptances, which is a separable approximation to the 2-D diffuse correlation sin(kr)/(kr), so a difference shows that approximation.

### Phase 51 — Sound-bridge path in Eq. (23) *(closed 2026-10-23: not run, no verifiable source; an extension beyond PAIN)*

Run only if the T2 gap remains above 10 dB after 49, 48 and 50.

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 51a | Option `hf_bridges = true`: a transmission term for trim attachment points and lines (Sharp 1978 / Fahy point- and line-connection form), using only the printed Phase III mechanical-path data (N = 9 points, 2 frame lines, G10 panel); off by default. Source papers downloaded with checksums | V-UNIT: reproduces the source paper's worked example within 1 dB |
| 51b | `NR_PROP_TP2444_BR`: 47c with the bridges | V-EXP: same 47c criterion |
| 51c | `E22_BR`: E-22 measured reverberant noise reduction with the bridges, 1250–2500 Hz | V-EXP: inside the E-22 confidence interval in ≥ 75 % of bands |
| 51d | `T2_MEAS_EXT_BR`: 47d with the bridges | V-EXP: T2's gate (±3.5 dB of E-9 at 1250 Hz; 1600/2000 labelled extrapolated) |

**Result (2026-10-23).** Not run.
- **Condition met.** The T2 gap is still about 30 dB.
- **Why.** 51a needs a source with a worked example from an official source, and none was found (NTRS searches 2026-10-23). An unverified model would not meet the phase's own first step.
- **What PAIN already has.** A bridge-type path: the trim mechanical path, Eqs. A.19–A.21, inside τ_t. It is the larger part of τ_t at 1260 Hz for the T2 inputs.

The label is "extension beyond CR-3813". A pass here supports PAIN-plus-bridges, not PAIN as printed.

## 8f. Phases 52–58: open items that had no phase *(written 2026-10-23 at the author's request; executed 2026-10-23 on the author's go-ahead; all closed; moved to the bottom 2026-10-23; criteria dated 2026-10-23, before any of these is run)*

The same rules as §8e apply. No parameter is chosen from the data a case is compared with. Every physics change is an option that is off by default. Anything decided after a result is labelled post-hoc.

### Phase 52 — T1 H3 miss *(done 2026-10-23)*

T1 after 44f: H1 and H2 are within ±4 dB of the E-16 measured mean, H3 is +10.2 dB. The case is not claimable while GEXT holds (phase 32).

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 52a | H3 contributor budget (acoustic mode × structural mode × q) at 600 Hz, against NASA's printed App. B top pairs at 4000 rpm (the 44f method) | reported: which pairs carry the excess and whether NASA lists them |
| 52b | H3 with each documented input alternative separately (blocking R1/R2, Phase III η_T 0.5/1.0, η_r′ cap 0.15, F1A off-line fill), no combination chosen after the result | reported table; any input that is a documented correction is adopted only with its source page |
| 52c | Re-run T1 with the documented corrections of 52b, if any | T1 gate as registered 2026-10-20 (±4 dB of the measured mean at H1–H3) |

**Result (2026-10-23).**
- With NASA's printed field, our H3 equals NASA's (71.69 vs 71.3 dB), and NASA's is 6 dB above the measurement. T1's excess over NASA's E-16 H3 comes from the e11 off-line field (the grid extension, Phase 32).
- **52b:** no documented input alternative brings H3 within ±4 dB (best 73.4 dB).
- **52c:** no correction exists, so T1 is unchanged.

### Phase 53 — Negative and runaway noise reduction *(done 2026-10-23)*

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 53a | TP-1964 Eq. (18) bands at 1–2 kHz with NR < 0: term budget of Eq. (18) (prefactor, brace, D_nr, mode sums). Hand check of one band with two modes | V-UNIT: the hand value equals the code within 1e-9; the source of NR < 0 is named (an equation property or a defect) |
| 53b | Eqs. (19)–(23) at 400 Hz (E-21 inputs) give NR = 100 dB: two in-band modes with j² ≈ 1e-7. Check against the printed band average and the asymptotic branch | reported; a defect is fixed, while an equation property gets a documented guard (for example, the asymptotic n_r when the in-band ⟨j²⟩ is below the asymptotic one), off by default |

**Result (2026-10-23).**
- **53a met.** Negative Eq. (18) NR is a property of the equation (NASA's own prediction is negative at 1000 and 1250 Hz, CR-159363 p. 138). The code matches the hand value to 1e-9 (`NR_BAND_HAND`).
- **53b.** The Phase 49 Eq. (20) fix took the 400 Hz runaway from 100.4 to 41.3 dB. The `sparse_guard` option (off by default) gives 32.9 dB.

### Phase 54 — Q22: q = 0 coupling in NASA's program *(done 2026-10-23; Q22 closed)*

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 54a | Read CR-172428's program listing (the pages used for 44f, TONE/NRED) for how f₀M or the q = 0 axial integral is formed | the listing either explains NASA's q = 0 outputs (then 54b) or it does not (Q22 is closed as "not explained by the documents") |
| 54b | If explained: implement the listing's form as an option, then re-run R172428_CODE and T1 | R172428_CODE criterion as registered (±3 dB at ≥ 7 of 9) |

**Result (2026-10-23).** The CR-172428 listing (pp. 177–181) prints only NASA's changes; `FQM` is used but its formation is not printed. **Q22 is closed** as not explained by the documents.

### Phase 55 — T2's calibrated surrogate *(done 2026-10-23; decided: surrogate stays, labelled calibrated)*

The production `T2` case uses `broadband_cabin_p2` with `bb_j2_scale = 0.5`, which was fitted to E-9 (stale, no claim). Phase 47 showed that its pass rests on a modelled exterior 17 dB above the measured one.

| Step | What | Pass criterion |
|------|------|----------------|
| 55a | [AUTHOR] decide: keep the surrogate as the production default, labelled calibrated, or switch the default to `:eq19` (printed) and keep the surrogate as an option | decision recorded with its date |
| 55b | Apply the decision; update the T2 case texts, the GUI labels and the five documents | no verdict or recorded number changes except the label |

**Result (2026-10-23, decided under the author's authority).** The surrogate stays the production default, labelled calibrated. Neither cabin path is validated above 1 kHz, T2 is 0/3 either way, and switching would change the frozen baselines. The T2 case text now records that its closeness to E-9 rests on compensating errors.

### Phase 56 — 40f: Ritz solver isolation *(done 2026-10-23)*

| Step | What | Pass criterion (fixed 2026-10-23, the 40f criterion) |
|------|------|-------------------------------------------------------|
| 56a | Options in `structural_modes` to turn off the stringer and frame stiffness and the floor (defaults unchanged) | existing outputs identical with the defaults (1e-12) |
| 56b | 40f: unstiffened Ritz against closed-form Donnell–Mushtari | within 1 % for the first 10 shell modes |

**Result (2026-10-23).**
- **56a met.** The `include_floor` and `include_stiffeners` switches leave the defaults unchanged.
- **56b not met.** The bare-shell Ritz frequencies are 29–479 % above Donnell–Mushtari. The solver's shell term has an empirical ring term and a fitted `k_scale`, so it is not a Donnell–Mushtari shell; production uses Table D-1.

### Phase 57 — Tests for the never-executed functions off the T1/T2 paths *(done 2026-10-23)*

These are the functions listed in `block_validation_audit.md` (Phase 46): `parse_aircraft_trim_json` and its helpers, `build_aircraft_cache`, `_rand_triangular`, `fit_mrp_to_table_d1`, `appd_constraint_residuals`, `scale_acoustic_freq` and `hf_broadband_spectrum`.

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 57a | One test per function, checked against a hand value or a known input/output (a test that would fail if the function were wrong) | every listed function executed by the suite |

**Result (2026-10-23).** Met for six functions, each tested against a hand value. `build_aircraft_cache` is exercised through the aircraft pipeline and phase-31 runs, with no separate test.

### Phase 58 — Leftovers *(done 2026-10-23)*

| Step | What | Pass criterion |
|------|------|----------------|
| 58a | 47a QA: re-state the broadband-point mask with nominal ∪ observed tone windows, labelled post-hoc next to the recorded value | reported; the 47a verdict as written is unchanged |
| 58b | Fig. 14 frequency-axis offset (9–22 Hz): look for a second calibration source (the run log, other figures of run 8113) | reported; the data are shifted only with a documentary basis |
| 58c | 47c Phase III alternative: mechanical-path wall mass from the article's shell | reported column only |
| 58d | 37e/37g pending items: GUI legend cap, dense log ticks on Fig. 14, and the BBN_CIRC / R996_PHASE explanation texts | smoke tests pass; the texts are in §2.13 |

**Result (2026-10-23).**
- **58a (post-hoc):** with the union tone mask, Fig. 14's broadband p95 is 2.83 dB.
- **58b:** Fig. 16 (the same run) confirms the axis offset of Fig. 14. A +15 Hz shift changes no Phase 47 verdict; the data stay as calibrated.
- **58c:** ≤ 0.2 dB.
- **58d:** already done in Phase 37; the stale status is corrected.

## 8g. Phases 59–60: the two fixes the documents still support *(done/closed 2026-10-23; moved to the bottom 2026-10-23; planned 2026-10-23; author: "so implement fixes in phases until everything closes any questions"; criteria and decisions dated 2026-10-23, before any run)*

**Why.**
- *Phase 51 was closed* because no official source with a verifiable sound-bridge model had been found. A wider NTRS search on 2026-10-23 found one: **NASA CR-172490** (May, Plotkin, Selden & B. H. Sharp, *Lightweight sidewalls for aircraft interior noise control*, 1985, `references/NASA_CR_172490.pdf`). It gives Sharp's double-panel model with sound bridges:
  - TL above the bridging frequency = the combined-mass mass law + ΔTL_M;
  - ΔTL_M = 10 log(b f_c) − 25 dB for line connections at spacing b (Eq. 23);
  - ΔTL_M = 20 log(e f_c) − 51 dB for point connections on a square lattice e (Eq. 25);
  - the mass law is Eq. (5).

  It also prints a worked prediction: Fig. 15, Panel D (two 1.6 mm aluminium skins on point spacers; f₀ = 142 Hz at normal incidence; ΔTL_M "on the order of 12 dB").
- *The mode set stops at 811 Hz* (32 Table D-1 modes), while NASA used 300 modes from the App. D method. The App. D solver reproduces Table D-1 (`MRP_APPD` met, 27/32 within 5 %). Above 811 Hz the τ_f sum and the propeller-field NR of Phase 50 have no modes.

### Phase 59 — Sharp sound bridges in Eq. (23) (Phase 51 run with a verifiable source) *(done 2026-10-23)*

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 59a | `sharp_double_panel_TL` (CR-172490 §2.3): below f₀ (Eq. 22), the mass law of the combined mass (Eq. 5); from f₀ to f_b, the double-wall rise; above f_b, the combined-mass mass law + ΔTL_M. Reproduce Fig. 15's predicted curve for Panel D at the outside-pressure condition (no cavity depressurization), using the panel data printed in the report (two 1.6 mm aluminium skins, f₀ = 142 Hz, ΔTL_M = 12 dB as stated). Mass-law convention (normal or field incidence, Eq. 5 angle term) taken from what reproduces the report's own curve: a code check against the source, made before any comparison with measurement | V-UNIT: within 1 dB of the digitized Fig. 15 curve at ≥ 90 % of the 1/3-octave points 50–2000 Hz |
| 59b | Option `hf_bridges` in Eq. (23), off by default: a parallel bridge path τ_B = τ_ML(m_s + m_t)·10^(−ΔTL_M/10) over the trimmed area, added to τ_t·τ. Mapping, fixed now: m_s = shell mass; m_t = the summed limp masses of the sidewall stack; f_c from Eq. (4) for the skin (aluminium, MRP_T_SKIN) and the trim panel (G-10: h = 0.79 mm, c = 3200 m/s, as phase3_trim; the App. B panel of 1.456 kg/m² is G-10 at 1843 kg/m³), using the higher of the two in the identical-panel forms; connections from the Phase III mechanical path (9 points on the curved area A → lattice e = √(A/9); 2 lines → spacing b = (curved arc)/2); point and line paths added. The same connections are used for the 47c article (not documented; V-ASSUMED) | V-UNIT: off reproduces every recorded value; on, τ_B by hand within 1e-12 |
| 59c | `NR_PROP_TP2444_BR`: 47c with the bridges | V-EXP: the 47c criterion (±5 dB in ≥ 75 % of bands 315–1250 Hz) |
| 59d | `E22_BR`: the E-22 measured reverberant NR (CR-3813 article, E-21 inputs), 1250–2500 Hz, with the bridges | V-EXP: inside the E-22 95 % interval in ≥ 75 % of those bands (as 51c) |
| 59e | `T2_MEAS_EXT_BR`: 47d with the bridges | V-EXP: T2's gate (±3.5 dB of E-9 at 1250 Hz; 1600 and 2000 Hz labelled extrapolated) |

**Result (2026-10-23; criteria and mapping unchanged).** Report: `validation_reports/phase59_60_bridges_modes.md`.
- **59a `SHARP_PANEL_D`: not met, 3/13.** The mass law is about 1 dB under the figure, and with ΔTL_M = 12 dB as stated the bridged line is about 1.3 dB over it (the figure implies 10.2 dB). The construction's shape reproduces the source.
- **59b met.** The option is off by default and the hand checks match to 1e-12.
- **59c, 59d, 59e: not met.**
  - TP-2444 NR at 1260 Hz: 49.0 → 42.8 dB, against 33.9 dB measured.
  - E-22 NR: about 61 → 53 dB, against 19.5–32 dB measured.
  - T2 interior at 1250 Hz: 21.6 → 28.4 dB, against 51.0 dB.
- **Reading.** The documented connections close about 7 dB of the roughly 30 dB gap.

The label is "extension beyond CR-3813 (Sharp, CR-172490)". A pass supports PAIN plus bridges, not PAIN as printed.

### Phase 60 — Structural modes above Table D-1 from the App. D solver *(closed 2026-10-23 at 60a)*

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 60a | Extended set = Table D-1 (32 modes, to 811 Hz) + `appd_modes` (n_axial = 7, n_circ = 8, n_floor_max = 5, as `MRP_APPD`) above 811 Hz to 3 kHz. Check the App. D mode count per 1/3-octave band 1000–2000 Hz against the asymptotic structural modal density used in production (`structural_modal_density`) | consistency: count within a factor of 2 of the asymptotic value in every band 1000–2000 Hz; if not, Phase 60 stops here |
| 60b | `NR_PROP_TP2444_PF_X`: 50b with the extended set | V-EXP: the 47c criterion |
| 60c | `T2_MEAS_EXT_X`: 47d with the extended set (no bridges) | V-EXP: T2's gate |

**T2 attribution (2026-10-23, author: state it as a limitation of the method once the outputs are shown to match PAIN; reworded after Phase 61).** The code reproduces NASA's corrected program (CR-172428: H3 within 0.4 dB, pairs within 1.1 %). Against CR-3813's printed runs, 2–8 dB remain at high frequency (Phase 61, not explained by the documents), while NASA's own prediction is 32–44 dB above the measurement. T2's high-frequency gap is recorded as a limitation of the PAIN methodology within that stated code-to-NASA difference, not a code defect. Table: `validation_reports/phase59_60_bridges_modes.md`.

**Result (2026-10-23).** **60a: not met.** App. D/asymptotic mode count is 2.32 at 1000 Hz and 0.19 at 2000 Hz, so the extension is not adopted and 60b/60c were not run (as pre-registered).

## 8h. Phase 61: is the code the same as PAIN as NASA ran it for CR-3813? *(closed 2026-10-23; moved to the bottom 2026-10-23; planned 2026-10-23; author: "if something isnt closed out add to implementations and close it out"; criteria dated 2026-10-23, before any run)*

**Why.** The T2 high-frequency gap is recorded as a limitation of the method on the grounds that the code reproduces PAIN. That holds against CR-172428, which ran NASA's corrected program (H3 within 0.4 dB; 9/10 pairs within 1.1 %). It does not yet hold against CR-3813's own printed outputs:
- `REPRO_18b` 0/3, about 10 dB above E-16's NASA prediction;
- `E21_E22_NR` V-CODE 0/4;
- the high-frequency NR 2–8 dB from E-22's NASA prediction.

44f recorded that CR-3813's runs predate NASA's correction of the Eq. (52) floor-term sign (CR-172428 p. 178: "misinterpretation of sign convention"), but never ran the pre-correction form to see whether it reproduces them.

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 61a | Input `floor_sign` in `PainInputs` (default +1, the corrected form; −1 = the pre-correction program, which flips the floor integral in Eq. 52 for f′ and f̄′). The default leaves every recorded value unchanged | V-UNIT: default identical; with −1, f′ by hand within 1e-12 |
| 61b | `REPRO_18b_PRE`: the REPRO_18b inputs (ANOPP Table 8, R1, Phase III η_T = 0.5) with `floor_sign = −1` against E-16's NASA prediction | V-CODE: \|Δ\| ≤ 4 dB at H1–H3 (the REPRO_18b criterion) |
| 61c | `E21_PRE`: the E21_E22_NR V-CODE count (bands below the changeover; 80–160 Hz excluded, as 38a) with `floor_sign = −1` | V-CODE: \|Δ\| ≤ 3 dB of NASA's prediction in ≥ 75 % of the bands (the 38a criterion) |
| 61d | `E22_HF_CODE`: Eqs. (19)–(23) (no floor term, so 61a does not change them) against E-22's NASA prediction at 1250–2500 Hz | V-CODE: \|Δ\| ≤ 3 dB in ≥ 75 % of the bands; the result fixes how the limitation statement is worded (reproduced, or reproduced to within the stated difference) |

**Result (2026-10-23; criteria unchanged).** Report: `validation_reports/phase61_cr3813_reproduction.md`.
- **61a met.** `floor_sign` defaults to +1 and leaves outputs unchanged; −1 checked by hand on 80 pairs.
- **61b `REPRO_18b_PRE`: not met, 1/3.** 85.9/78.3/79.6 dB against NASA's 79.0/75.5/68.0 dB.
- **61c `E21_PRE`: not met, 1/4.**
- **61d `E22_HF_CODE`: not met, 1/4.** Code − NASA is +7.7/+2.1/−6.5/−5.6 dB; NASA − measured is +32.5…+43.5 dB.
- **Closed** as differences not explained by the documents. The T2 limitation statement is reworded to "within the stated code-to-NASA difference".

## 8i. Phases 62–65: map coverage, the mode animation, unit tests for every function, grid axial direction *(done 2026-10-23/24; moved to the bottom 2026-10-24; planned 2026-10-23; author: "go back to validation map and ensure each block shows a test with its own figure or display showing what its proving and then for the structural modes tab the animation is working do a full review and create unit tests for each function in a new directory"; criteria dated 2026-10-23, before any run)*

### Phase 65 — Grid axial direction and z_p (found 2026-10-23 by the Phase 62 input QA; executed first)

The code builds the grid with z_k = z_p + (πa/18)(k_p − k) and uses z_p = 0.90 m for the CR-3813 article. The documents say otherwise:
- **User Manual pp. 8–9:** x₃ = (πa/18)(k_p − k), and "(πa/18)·[k_p − 1] cannot exceed z_p". So z₁ = z_p − x₃ ≥ 0 and z_k = z_p − x₃.
- **CR-3813 App. E p. E-8:** z_k = z_p − x₃ᵏ and z_p = 0.662 m.
- **CR-172428 Table 6:** z_p = 0.662 m for the same article.

The code's grid is therefore mirrored about the propeller plane. Its z_p has no recorded source; it dates from the initial commit. With z = z_p + x₃ and 0.662 m the grid would leave the cylinder, which may be why 0.90 m was used.

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 65a | `grid_points`: z = z_p − x₃. Test-article z_p = 0.662 m in `run_pain_pipeline`, the GUI default, the aircraft NASA-default table and the E-11 / E-12 / NR / F1A test-article cases | V-UNIT: grid z by hand from the Manual relation within 1e-12; every grid point inside 0 ≤ z ≤ L for the test article |
| 65b | Re-run the full suite. Every recorded value that changes is re-recorded with the label "grid axial correction 2026-10-23 (code vs User Manual p. 9 / App. E p. E-8; not a fit)", and its old and new values are listed in the report | each changed verdict and number listed; no criterion changes |

### Phase 62 — A proving case for each map block that has none

On 2026-10-23, 12 of the 30 blocks of the `total` map had no case. Each gets one, with its own figure and a criterion fixed now:

| Block | Case | What it proves (figure) | Pass criterion (fixed 2026-10-23) |
|-------|------|--------------------------|-----------------------------------|
| X_F1A (F1A source) | `F1A_PLANE_PEAK` | Aircraft example (`examples/aircraft_scale_hartzell.json`), F1A free field on the 16×10 grid; H1 amplitude map over (k, ℓ) | the H1 maximum lies on ℓ = 1 within ±1 station of the propeller plane k_p |
| X_FF (free-field p) | `FF_E11_MAP` | The e11 free-field grid, H1–H3 maps | every off-line amplitude ≤ the ℓ = 1 amplitude at the same k (the field decays away from the propeller line) |
| X_SRC (source select) | `SRC_PASSTHROUGH` | For `:e11` and `:synthetic`, the selected source's blocked grid against the `PainInputs` the cabin receives; ℓ = 1 profiles | identical (difference 0) for every point and harmonic |
| X_BLK_OUT (blocked pressures) | `BLK_GAIN_MAP` | Blocked/free gain ΔL over the grid against the incidence angle γ, for R1 and R2 | 0 ≤ ΔL ≤ 20 log₁₀ 2 (pressure doubling) everywhere for both variants |
| X_MRP_IN (structure inputs) | `MRP_INPUT_QA` | Code constants of the test article against CR-3813 App. E printed values (new transcription with page numbers) | every value equal to the printed value (to its printed digits) |
| X_MRP_OUT (modes f_r, ψ_r) | `MRP_SHAPE_NORM` | The 32 Table D-1 shapes on a 2° × 40-station grid; first six circumferential shapes | max \|ψ\| ≤ 1 + 1e-6 for every mode (max-normalized, the basis of \|f′\| ≤ 1) |
| X_CYL_IN (cabin geometry) | `CABIN_GEOM_HAND` | Cross-section outline; V, S, coupling area and floor width by hand | each within 1e-12 relative of the code |
| X_CYL_OUT (modes Φ_G) | `CYL2D_WEYL` | Cumulative 3-D cabin mode count N(f) against Weyl's law N ≈ 4πVf³/(3c³) | within 25 % for 500–1500 Hz |
| X_TRIM_IN (trim stack) | `TRIM_INPUT_QA` | The Phase III stack against CR-3813 p. E-8 (layers, thicknesses, facing and septum masses) | every value equal to the printed value |
| X_TRIM_OUT (τ, η) | `TRIM_PASSIVITY` | τ_t, ξ and η_n of the Phase III trim, 100–6300 Hz | passive: ξ ≥ 0 and η_n ≥ 0 at every band, 0 < τ_t |
| X_PAIN_IN (cabin inputs) | `PAIN_INPUT_ECHO` | The resolved T1 inputs against their documented formulas (ΔA = (πa/18)², m_wall = ρ t_eq, L_c, c₀) | each within 1e-12 relative |
| A_CABIN (aircraft cabin) | `AC_CABIN_DEMO` | Aircraft cabin example (`examples/aircraft_scale_hartzell_cabin_full.json`); interior spectrum | the overall dB(A) equals the energy sum of the A-weighted bands within 1e-9 dB |

### Phase 63 — The structural-modes animation works

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 63a | The GUI's cabin/structural mode animation: frames from `mode_animation_frames` and the structural display for every mode the tab offers | every frame finite; consecutive frames differ (the animation moves); the period returns to the first frame |
| 63b | Offscreen GUI run (QT_QPA_PLATFORM=offscreen): open the tab and step the animation | no QML error; at least two distinct frame images captured |

### Phase 64 — A unit test for every function

| Step | What | Pass criterion (fixed 2026-10-23) |
|------|------|-----------------------------------|
| 64a | New directory `test/unit/`, one file per source module, included by `runtests.jl`. Each function gets a test against a hand value, a limit or an independent route (CLAUDE.md check 6: no test of a function against itself) | all pass |
| 64b | A completeness test: every `function` / one-line method defined in the physics, numerics and GUI-model modules is named in `test/unit/`. Validation-case runners (`_run_*`, `_iso*_validation_cases`) are covered through `run_validation_case` and listed as such | the test fails if any function is neither tested nor listed |

**Results (2026-10-23/24; report `docs/validation_reports/phase62_65_map_blocks_grid.md`).**
- **65 done.** Grid z_k = z_p − x₃, z_p = 0.662 m. Full case snapshot regenerated and diffed: 12 cases changed numbers, no verdict changed (T1 86.59, 80.02, 76.39 dB; REPRO_18b 88.20, 80.43, 78.21 dB). Open item Q45 (aircraft example cabin length).
- **62 done.** 12 cases; 9 met. Not met: `BLK_GAIN_MAP` (R1 negative at γ > 90°; R2 default within the bound), `MRP_SHAPE_NORM` 19/32 (truncated Table D-1 shapes peak up to 1.245), `CYL2D_WEYL` 0/5 (post-hoc diagnosis: App. C grid dispersion at NY = 10). Code review 2026-10-24: two rows that passed by construction replaced (floor width; m_wall), AC_CABIN_DEMO info rows removed from the count, residual units fixed.
- **63 done.** Structural frames animate with the acoustic frames; unit tests and both offscreen smokes pass.
- **64 done.** `test/unit/` (25 files), every `src/` function named; 8 code defects found and fixed: F1A_GUTIN reference (low by √2·M; re-run Δ = 0.03 dB), `PropellerPlacement` ±1, string η card keys, Dict cabins dropping symbol/bool fields, `tone_expected_value` empty-band fields, NR dummy grid axes, `_iso_simpson` Float32 literal, Phase 62 failing-case reasons. GUI Run tab now aircraft only (author: E-11 is for PAIN verification).

## 8j. Phase 66: further code checks of BEMT and F1A *(done 2026-10-24; moved to the bottom 2026-10-24; proposed 2026-10-24; author: "can you figure out other ways to verify bemt and f1a"; criteria dated 2026-10-24, before any of these checks is written or run; none uses measured data)*

Existing checks: `BEMT_HAND` (linear lift, c_d = 0, tip loss off), `F1A_GUTIN` (rotor-plane H1), `F1A_INDEP` (own F1A vs AcousticAnalogies on the same loads). Done in Phase 64 as unit tests (not repeated here): steady loading gives no harmonic on the rotor axis (≤ 1e-3 of the in-plane level); in the rotor plane only the torque radiates (½ torque → ½ amplitude, 2× thrust → no change, within 2 %); the independent F1A of a single-radius source equals Gutin's closed form within 0.03 % — this found that the old F1A_GUTIN reference was low by √2·M (fixed 2026-10-24, F1A_GUTIN re-run Δ = 0.03 dB).

| Step | What | Pass criterion (fixed 2026-10-24) |
|------|------|-----------------------------------|
| 66a | BEMT section residual: at every station, momentum thrust/torque 4πrρV²(1+a)aF dr and 4πr³ρVΩ(1+a)a′F dr against the blade-element values from the converged φ | relative difference ≤ 1e-8 at every station, three operating points |
| 66b | Hand BEM with tip loss on, c_d ≠ 0 and a nonlinear c_l(α) (bisection on φ, no CCBlade code) | T and Q within 1 % of the wrapper |
| 66c | Integrals and bounds: B∫N′dr = T, P = ΩQ; efficiency below the Froude ideal η_i(C_T); halving the station spacing changes T by < 0.5 % | all three hold on the Hartzell and Report 996 blades |
| 66d | Similarity: with a Re- and M-independent polar, C_T and C_P at fixed J unchanged when rpm and V scale together | within 1e-6 relative |
| 66e | Lowson rotating point force: one compact rotating dipole against the analytic near- and far-field harmonic at five observer angles | within 0.5 dB and 5° |
| 66f | Garrick–Watkins forward-flight tone (Gutin extended to flight Mach M_x) against F1A at M_x = 0.1, 0.2 and three angles | within 1 dB |
| 66g | Hanson frequency-domain far field (loading and thickness) on the same blade | within 1 dB for H1–H3 in the far field; thickness term separately |
| 66h | Exact properties: only multiples of BΩ present; amplitude ∝ B for identical blades (fixed T per blade); 1/r far field; convergence in source time step and blade sections | each within 1 % (convergence: < 0.1 dB between successive halvings) |

Each step becomes a V-UNIT case on the `A_LOADS` / `A_AMP` blocks with its own figure, or a unit test where no figure helps.

**Readings fixed 2026-10-24, after the author's go-ahead and before any of these checks ran** (from the CCBlade and AcousticAnalogies sources, not from results):
- **66a:** CCBlade applies the tip/hub loss F to the loads; its reported u, v are rescaled by an effective G (CT = 4a(1+a)F = 4aG(1+aG)). The momentum balance is therefore checked with the raw induction a = k/(1 − k), a′ = k′/(1 + k′), k = c_nσ/(4F sin²φ), k′ = c_tσ/(4F sinφ cosφ) recomputed from the section outputs, and separately in CCBlade's own G form B N′ = 4πrρ(V + u)u, B T′ = 4πrρ(V + u)v. Momentum region only (k ≥ −2/3).
- **66e:** a compact rotating point force in the far field is Gutin's form, so 66e is F1A (production path) against Gutin summed annulus by annulus, thrust and torque, at θ = 30°, 60°, 90°, 120°, 150° from the flight direction, 100 R_tip, static. Frame (AcousticAnalogies `ccblade_helpers.jl`): the rotor translates along +X, so +X is the flight direction and the force on the fluid is −T x̂; Gutin's p_rms = (mBΩ/(2√2πc₀r))|−dT cosθ + dQ c₀/(ΩR²)|J_mB(mBΩR sinθ/c₀). Phase: relative to θ = 90°, 0° or 180° by the sign of the bracket (equal distance, so equal retarded time). The near field is covered by the exact static and moving-dipole unit tests of the independent F1A.
- **66f:** Garrick–Watkins with the observer moving with the propeller at M_x (x positive forward): p_rms = (mBΩ/(2√2πc₀S₀))|−dT (M_x + x/S₀)/β² + dQ c₀/(ΩR²)|J_mB(mBΩR y/(c₀S₀)), S₀ = √(x² + β²y²), β² = 1 − M_x²; it reduces to the 66e form at M_x = 0. Observers at 100 R_tip, θ = 60°, 90°, 120°; loads from the same BEMT at the flight speed.
- **66g:** Hanson's far field in the compact-chord limit; the thickness term alone (loads scaled to zero, A = (t/c)·c² as AcousticAnalogies' `area_over_chord2`): peak amplitude ρ₀(mBΩ)²B ΣA_i dr_i J_mB(mBΩr_i sinθ/c₀)/(2πr), from the far-field monopole ρ₀/(4πr) ∂²/∂t²[V/(1−M_r)]. The loading term is 66e/66f. t/c = 0.12, static, θ = 60°, 90°, 120°.
- **66h:** the blade-count property uses F1A on prescribed (identical) section loads through `_f1a_harmonics` (the production F1A step), not BEMT loads, which change with B.
- **Span weights (all F1A references):** AcousticAnalogies gives each section the midpoint span (`get_dradii`: interfaces halfway between sections, ends at R_hub and R_tip), while `CCBlade.thrusttorque` integrates by the trapezoid rule with zero loads at R_hub and R_tip. The 66e–66g references use the AcousticAnalogies spans, so each compares the same discrete source; 66c reports the difference between the two thrust integrals as information (found in the code before any run, 2026-10-24).

**Results (2026-10-24; report `docs/validation_reports/phase66_bemt_f1a.md`).** 66a met 72/72 (1.1e-11); 66b met 4/4 after a fix of the hand reference (first run 0/4: it bisected across the k = 1 pole near the tip); 66c met 7/7 (η ≤ η_i; ΔT −0.07 %; F1A/BEMT span-weight ratio 0.997 and 1.0004 as information); 66d met 6/6; 66e **not met** 4/5 (levels within 0.26 dB; θ = 60° phase 14.6° off at a near-null, 3.7° at 400 R_tip post-hoc); 66f met 6/6 (0.07 dB); 66g met 9/9 (0.002 dB); 66h met 5/5. CCBlade and AcousticAnalogies unchanged (author 2026-10-24: they are correct; checks are on our use of them). Shared set-up `_ccblade_setup` and F1A step `_f1a_harmonics` factored out, behaviour unchanged.

## 8k. Phase 67: are the source-block experimental misses the polars and the compact-chord approximation? *(done 2026-10-24; moved to the bottom 2026-10-24; planned 2026-10-24; criteria dated 2026-10-24, before any of these numbers was computed)*

The code checks of BEMT and F1A pass (Phases 41, 64, 66), yet R996_LOADS (6/32), R996_FIG12/13A/14 and PER_FIG9 miss the measurements. The record attributes this to model fidelity. Phase 67 tests the two candidate causes directly, without changing any input of those cases.

| Step | What | Pass criterion / rule (fixed 2026-10-24) |
|------|------|-------------------------------------------|
| 67a `POLAR_FIDELITY` | The XFOIL polars the Report 996 cases use (`polars_forced_merged.json`) against NACA TN 1546 measured c_l for the three exactly matching sections (16-312, 16-506, 16-509), at TN 1546's α curves and the XFOIL Mach grid points it covers (0.4, 0.55, 0.65, 0.72), XFOIL at the Reynolds number nearest TN 1546's (about 1–2·10⁶, table 1·10⁶ and 2·10⁶ interpolated in log Re); no extrapolation | V-EXP of the input: \|Δc_l\| ≤ 0.05 at ≥ 75 % of the matched points. Not met ⇒ the section polars are a documented error source of the Report 996 cases |
| 67b `F1A_CHORDWISE` | At the Report 996 Fig. 14 microphone geometry (d/D = 0.083, x/D = −0.125 … 0.5, B = 2, β₇₅ = 10°, M_t 0.45–0.90, static), the independent F1A of F1A_INDEP with each section's load spread over the chord (thin-airfoil loading ∝ √((1−ξ)/ξ), 8 chordwise points along the chord line at the section pitch) against the same total load at the quarter chord (compact) | Diagnostic, rule fixed now: a harmonic where \|compact − chordwise\| > 2 dB (the Report 996 tolerance) is outside what the compact-chord F1A can claim; the Report 996 near-field misses at those points are then a limitation of the compact approximation, not a code defect |

No result of 67a or 67b changes a polar, a load or a criterion of any existing case.

**Results (2026-10-24; report `docs/validation_reports/phase67_source_attribution.md`).** 67a `POLAR_FIDELITY` **not met** 9/60: XFOIL c_l is 0.15–0.35 below TN 1546 at low α on all three sections and Mach numbers. Post-hoc consistency: Report 996 BEMT thrust 25–32 % below measured (s_T 1.25–1.32). 67b `F1A_CHORDWISE`: ≤ 0.27 dB, 0/60 beyond 2 dB. The source-block experimental misses are a limitation of the section polars (XFOIL with forced transition), not of the BEMT/F1A code or the compact chord. Pereira has no measured section data at its Reynolds number (TR 824 is 3–9·10⁶), so its attribution cannot be tested from the documents.


## 8l. Phase 68: figure folders by map block and chunk-structured methodology *(done 2026-10-27; author: "separate them by functions like how its separated in the validation map" and "done for stage 1 thru stage 6")*

- [x] **68a** Validation figures moved from one flat `docs/validation_reports/figures/` into one folder per validation-map block (`F1A_amplitude/`, `CCBlade_BEMT/`, `Forward_flight/`, `vs_measurement/`, …; source pages in `<folder>/source/`). `VALIDATION_FIGURE_DIRS` (block id → folder) and `validation_figure_dir` in `validation_plots.jl`; `validation_figure_path` / `validation_source_figure_path` / `plot_case` use them. `VALIDATION_MAP_TOTAL*.png` stay at the root. Files moved only; no case, criterion, verdict or number changed. Unit test: every map block has a folder, folders are distinct.
- [x] **68b** `METHODOLOGY.md` stages 1–6 rewritten to the layout of `METHODOLOGY_STRUCTURE.md` (chunk name, function, chain, inputs/outputs per block, sources, cases with criteria, claim). Wording only; every grade, criterion and recorded result is carried over from the existing text and the case records.

## 8m. Phase 69 — polar audit, loader fix and XFOIL rerun *(done 2026-10-28)*

**Why.** The 2026-10-28 audit (`METHODOLOGY.md` §2.4) found four defects behind the polar-fed cases:
1. `load_polar_set` drops the section name, so every Report 996 blade station uses NACA 16-101 (1.3 % thick, design c_l 0.1). This is a code defect, so the Phase 67 attribution "input fidelity, not code" is withdrawn and the Q47 closure register entry "no open code defect" is reopened.
2. No interpolation in Re or M: the loader uses the nearest table. Re and M outside the grid are clamped, so tip stations at M_t 0.75 and 0.9 are read from M = 0.72.
3. Past the last angle of a table the end value is held. The registered Viterna extension (§2.10) is not applied by this loader. The static Report 996 runs reach α = 20°–30°.
5. **Reynolds number passed to the polars is wrong by about 10⁵.** `_ccblade_setup` builds `CCBlade.OperatingPoint(V, Ωr, ρ; asound)` without `mu`, and CCBlade's default is μ = 1. Measured 2026-10-28: CCBlade passes Re ≈ 5–14 (Report 996) and 2–3 (Pereira) against 2.6–8·10⁵ and 0.9–1.6·10⁵, so every BEMT lookup so far used the lowest grid table (Report 996: 3·10⁵; Pereira: 2·10⁴). Affects every BEMT result, including Pereira and PROP_BB_*.
6. PROP_BB_FIG14/17 (`_p48_af`) read the Report 996 file, so defect 1 also applies there.
4. Forced transition x_tr = 0.02 for Report 996 has no basis in the documents: neither Report 996 nor TN 1546 mentions tripping. Pereira states natural transition and tunnel turbulence below 0.1 %, so its N_crit 9 set already matches its text.

**Cases affected:** POLAR_R996, POLAR_PER, POLAR_FIDELITY, R996_LOADS, R996_FIG12, R996_FIG13A, R996_FIG14, R996_PHASE, F1A_CHORDWISE and the PER_* cases. Pereira is affected through defects 2 and 3 only, since it has one section.

**Steps.**
- [x] **69a Loader fix** (`src/polars.jl` and its tests). Tables kept per section. Each blade station uses its own section, linear in t/c between the two nearest sections. Interpolation linear in log Re and in M inside the grid, and Re and M outside the grid flagged rather than silently clamped. The registered Viterna extension applied past the last converged angle. Each new test must fail on the old loader: one section for all stations, nearest table, end value held. **Done 2026-10-28:** `PolarSet`, `section_polar`, `station_polars`, `_station_afs`; a multi-section set without `station_t_over_c` is an error, and every Report 996 / TP-2444 configuration now carries the blade-form t/c. Tests in `test/unit/test_polars.jl` (each fails on the old loader: one section for all stations, nearest table, end value held) and `runtests.jl` "Polar loader".
- [x] **69a2 Viscosity fix.** Pass μ = 1.78·10⁻⁵ Pa·s (the value already used for the displayed Re; equal to ρν with ν = 1.4529·10⁻⁵ m²/s in `prop_broadband.jl`) to every `CCBlade.OperatingPoint`. Test: the Re received by the polar equals ρWc/μ at each station. **Done 2026-10-28:** `AIR_MU_PA_S` passed to every `CCBlade.OperatingPoint` (override `operating_point.mu_Pa_s`). Test: the Re received by the polar is > 10⁴ and within a factor 2 of ρWc/μ (it was 5–14).
- [x] **69a3 Thickness input.** F1A takes one t/c for the whole blade (`fill(t_over_c, nsec)`) and uses it as A/c²; a real section's area is about 0.68·t·c. Check AcousticAnalogies' definition of `area_over_chord2`, then pass the per-station value. The Report 996 and Pereira runs stay loading-only as registered. One thickness-on run per figure is reported as a sensitivity (planned in Phase 23, not found in the records), not a verdict. **Done 2026-10-28:** AcousticAnalogies' `area_per_chord2` is the cross-section area / chord². Measured on the ten Report 996 sections, A/(t·c) = 0.72–0.84 (16-101 0.84, the rest 0.72–0.78), so the existing key `thickness_over_chord` is an A/c² input, not t/c. Its meaning is kept, because the demonstration example's value was set against Table 8 (B-5) and F1A_THICKNESS uses the same A. A per-station `propeller.area_over_chord2` vector now overrides it (`_station_area_over_chord2`). The registered Report 996 and Pereira runs stay loading-only, so no verdict changes. The thickness-on sensitivity runs are not done (not found in the records; deferred).
- [x] **69b Pre-registration (fixed 2026-10-28, before any XFOIL run or comparison).** Free transition for every set. **N_crit for Report 996 is calibrated to NACA TN 1546 section data** (author 2026-10-28: "calibrating here would be fine ... since were not testing xfoil"; neither Report 996 nor TN 1546 states a turbulence level). Rule: one N_crit for all ten sections, chosen from {1, 2, ..., 12} as the value with the smallest RMS (XFOIL c_l − TN 1546 c_l) over the matched points of sections 16-506 and 16-509. XFOIL is run at the TN 1546 Re(M) and M of each point. A tie goes to the higher N_crit. **Held-out check:** section 16-312 is not used in the fit and is scored with the POLAR_FIDELITY criterion (|Δc_l| ≤ 0.05 at ≥ 75 % of matched points), dated 2026-10-28. If the best value is 1 or 12, the result is recorded as "N_crit cannot close the gap" and the range is not widened. **Consequences:** POLAR_FIDELITY on 16-506/16-509 becomes *calibrated, no verdict* (a calibrated path is never compared with the data it was calibrated to). The Report 996 cases stay tests against the Report 996 measurements, which the fit never sees. N_crit is never chosen from the Report 996 thrust, loads or noise. Pereira stays at N_crit 9 (natural transition and turbulence below 0.1 % per its text; TR 824 is at Re 3–9·10⁶, far from Pereira's, so it is not used for a fit). TN 1546 data are uncorrected for wall interference (about 2 % in Mach), noted, not corrected. Existing criteria and tolerances unchanged. Every rerun result is labelled post-hoc, because the first results are known. **Result (2026-10-28, `data/polars/phase69_ncrit_fit.md`; XFOIL runs `data/polars/phase69_tn1546_ncrit.json`, script `data/polars/xfoil_phase69.py tn1546`, points `phase69_tn1546_points.csv`, 68 matched points):** **N_crit = 8** (RMS c_l difference 0.039 on 16-506/16-509, mean −0.021, 34 of 41 points converged). For comparison, N_crit 1: 0.090; N_crit 12: 0.054. Not at the edge of the range. With free transition the section c_l gap falls from 0.15–0.35 (forced x_tr 0.02, Phase 67) to about 0.02 on average, so forced transition was most of the section-level miss. **Held-out 16-312: not met**, 13/26 converged points within 0.05 (50 %; criterion ≥ 75 %). The fit does not fully carry to the 12 %-thick section. Limitation of the rule as registered: each N_crit is scored over the points that converged at that N_crit (28–41 of 41), so the RMS values are not over identical point sets. **Repeat fixed 2026-10-28 ~02:10, before any repeat result:** the sweep ran while a Julia test suite loaded the CPU, and XFOIL's 60 s hang limit is wall-clock, so some missing points may be load artifacts. The `tn1546` sweep is repeated once on an otherwise idle machine, with the same rule. **The repeat is final**, whatever N_crit it gives. If it differs from 8, the Report 996 grid is rerun at the new value before any case is rerun. **Repeat result (2026-10-28 05:10, idle machine, after the grid fill):** the `phase69_ncrit_fit.md` table is identical to the first run at every N_crit. N_crit 8 is final, and the held-out 16-312 is still not met (13/26). The first-run misses were not load artifacts. No grid rerun.
- [x] **69c XFOIL rerun.** Section comparisons at the exact TN 1546 Re(M) and M: done in 69b. **BEMT polars, changed 2026-10-28 before the run:** the plan said each station's own converged Re and M. But the stations have no section geometry of their own (only the 10 `xfoil_sections/*.dat` exist; a station is a t/c blend of two of them). So the Report 996 set is rerun on a dense grid instead: 10 sections × Re {1.5, 2, 3, 5, 7, 10, 15, 20}·10⁵ × M {0.1, …, 0.9} × α −6° to 20° in 0.5° steps, free transition, N_crit 8, 240 panels (`xfoil_phase69.py grid 8` → `data/report996/polars_phase69_ncrit8.json`). It covers every station's converged Re (1.9·10⁵–1.2·10⁶) and M (0.12–0.90), read bilinearly in (log Re, M) with the §2.10 Viterna extension past the converged angles. **Pereira: no rerun.** Its N_crit 9 set already covers the stations' Re (0.9–1.6·10⁵, grid 2·10⁴–3·10⁵), M (≤ 0.37, grid 0–0.4) and α (−10° to 20°); its misses came from defects 2, 3 and 5, which 69a fixes. Points that do not converge are listed in the file header, not filled. The old files are kept. **Done 2026-10-28.** Grid pass: 720 polars, 49 with fewer than 3 converged points. **Fill pass** (`fill 8`, 2026-10-22 restart rule, existing points kept): 443 polars re-swept, 1,977 points added, 24,706 of 38,160 grid points converged (65 %). By Mach: 0.52 converged at M 0.1, 0.70 at 0.5, 0.85 at 0.7, 0.47 at 0.9. 23 tables still have fewer than 3 points and are skipped by the loader, which falls back to the nearest table and counts it: 16 on 16-101 (the 1 %-thick tip section), 11 at M 0.9. The low-Re, low-M gaps are mostly XFOIL hangs at large positive α, so the Viterna extension starts earlier there.
- [x] **69d Rerun the affected cases.** Each new result is recorded beside the old one with the reason for the change. No criterion is changed, and nothing is selected, scaled or tuned against the data the case is compared with (CLAUDE.md). **Pereira, rerun 2026-10-28** (`scripts/run/run_pereira.jl`, loader and μ fixes only, polars unchanged; old results kept in `data/pereira/pereira_results_pre69.csv`): CCBlade thrust and torque against the measured 14.55 N, 0.4133 N·m (Table 3): N_crit 9 (primary, from Pereira's text) **14.65 N (+0.7 %), 0.428 N·m (+3.5 %)**, was 5.73 N, 0.271 N·m; N_crit 5: 14.45 N, 0.418 N·m (was 9.59, 0.361); x_tr 0.05: 13.46 N, 0.399 N·m (was 10.82, 0.362). Post-hoc (the first results were known), but nothing was chosen from them: the change is the two code defects. Pereira's own BEMT is about 5 % above the measured torque (p. 4), the same direction. **Report 996 and the rest, rerun 2026-10-28 05:10** (`run_report996_loads`, `run_report996_acoustics` on `polars_phase69_ncrit8.json` after the fill; old CSVs kept as `data/report996/*_pre69.csv`), then the case snapshot `case_error_summary.csv` diffed against the 2026-10-28 pre-change snapshot. All post-hoc. R996_LOADS **24/32** (was 6/32), R996_FIG12 **28/40** (was 21/40), R996_FIG13A 8/14 (same), R996_FIG14 20/24 met (same count, max 4.4 dB, was 3.1), R996_PHASE 113.6° (was 109.0°; 155° measured), POLAR_FIDELITY held-out 16-312 13/26, PER_FIG7 2/3, PER_FIG8 H1/H2 3/7 each, PER_FIG9 3/9 and 6/9, PROP_BB_FIG14 3/9 (median 7.5 dB, was 9.2), PROP_BB_FIG17 2/7, T2_PRED_BB 0/3, SRC_PASSTHROUGH 3/3 met (new aircraft row). **No verdict changed** (41 met, 45 not met, 17 no verdict, before and after). The defects were real and the loads improved most, but the remaining misses are not code defects. Each case record in §2.13 and the §2.14 register carry the rerun result.
- [x] **69e Docs, full suite, /code-review, commit.** Update the five documents and the §2.14 closure register. **Done 2026-10-28:** full suite 10,091 pass, 0 fail; GUI smoke scripts pass; committed 94987fa and pushed.

**Known causes this phase does not fix (recorded, not changed):** tip Mach 0.75–0.9 is above the sections' critical Mach, where XFOIL is not reliable (tip stations flagged); static BEMT (momentum theory at J = 0, a method limitation); BBN_CIRC uses no section data (default c_l = 2πα, clamped at ±20°, with assumed blade geometry; the documents give no section polars, so it stays X-EXTRAP); Pereira motor noise above H2 and the digitizations; F1A_GUTIN_ANGLES is a reference at a near-null (test design). The Report 996 runs with thrust and torque scaled to the measured values also missed (23c). The rerun therefore reads the radial load shape, which defects 1 and 5 distort, against those scaled results as well.

**Done when** the loader fix and its tests pass in the full suite; the XFOIL inputs and outputs of the rerun are listed in `METHODOLOGY.md` §2.4; every affected case has a post-hoc-labelled rerun result next to its first result; and the five documents are updated.

## 8n. Phase 70 — free-field block audit *(done 2026-10-28)*

Scope: map blocks `X_FF` (aircraft free field), `P_FF` (e11 free field) and `X_SRC` (source select), and their cases FF_E11_MAP, E11_FREEFIELD, ISO_FF_CONV, ISO_TABLE8, BPM_RP1218, PROP_BB_FIG14, PROP_BB_FIG17, SRC_PASSTHROUGH. Recorded results (2026-10-24): six met; PROP_BB_FIG14 not met 3/9, PROP_BB_FIG17 not met 2/7.

| # | Finding | Evidence | Action |
|---|---------|----------|--------|
| F1 | **FF_E11_MAP passes by construction.** "Every off-line amplitude ≤ the ℓ = 1 amplitude at the same k" cannot fail, because GEXT sets each off-line amplitude to the ℓ = 1 amplitude × max(cos α, floor) with floor ≤ 1 (`grid_extension.jl` lines 59–70) | CLAUDE.md check 6 | Relabel the record: a plumbing and figure check, not evidence about GEXT. Keep the figure. GEXT itself stays covered by GEXT_BOUND and ISO_GEXT_LINE **Done 2026-10-28:** record relabelled ("holds by construction"). |
| F2 | **FF_E11_MAP is on the wrong block.** It tests the e11 field after GEXT but sits on `X_FF`, the aircraft free-field output in `G_AIR`. So `X_FF` has no case about the aircraft free field | §2.13 Chunk 1 | Move it to `P_GRID` (GEXT). Give `X_FF` an aircraft case, e.g. move F1A_PLANE_PEAK, which tests the F1A field on the 160 points. The Phase 62 test "every block has a case with its own figure" must still pass **Done 2026-10-28:** FF_E11_MAP → `P_GRID`, F1A_PLANE_PEAK → `X_FF`, F1A_INDEP (independent F1A implementation) → `X_F1A`; figures moved with them. |
| F3 | **ISO_TABLE8 tests only the identity.** The unit test in `test/unit/test_propeller_ccblade.jl` already checks a non-unit scale; the ±20 dB clamp was untested. ISO_TABLE8 also sat on `P_FF`, while the calibration acts on the aircraft F1A grid (`propeller_ccblade.jl` line 123) | case record "Not covered" | **Done 2026-10-28:** clamp unit test added (a grid 10⁴ too loud is scaled by 0.1); case moved to `X_FF` |
| F4 | **BPM_RP1218 and PROP_BB_FIG14/17 sit on `P_FF` (NASA measured input) but are a computed propeller source** (CCBlade BEMT + BPM self-noise) | `prop_broadband.jl` | Move them to a source block of their own or to `A_SURF`. The closure-register cause (BPM only, assumed blade) is incomplete: they read the Report 996 polar file, so Phase 69 defects 1 (one section, 16-101) and 5 (μ = 1, lowest Re table) apply. Within one run, the BEMT and the α_L0 step (`prop_broadband.jl` line 30, display Re) also read different tables. The Fig. 14 microphone is about 0.52 m from the hub of a 0.381 m-radius propeller, in the near field of a far-field BPM directivity. Rerun after Phase 69 with a post-hoc label **Placement done 2026-10-28:** BPM_RP1218, PROP_BB_FIG14/17 → `A_SURF`; the α_L0 step now uses the station's own polar (`ops.afs`). **Rerun 2026-10-28 (post-hoc):** FIG14 3/9 (max 9.8 dB, was 12; median 7.5, was 9.2), FIG17 2/7; counts unchanged, not met. The remaining miss is the BPM-only source model and the near-field observer, as classed in §2.14 |
| F5 | **E11_FREEFIELD passes exactly at its limit** (δ_dig max 1.0 dB against ≤ 1.0 dB; H1 0.5, H2 1.0, H3 1.0). Both passes read at 0.5 dB steps, so δ comes in 0.5 dB steps | `e11_delta_dig.md` | Note only. The criterion is unchanged |
| F6 | Stale input text: E11_FREEFIELD and E12_BLOCK said z_p = 0.90 m, while the code uses 0.662 m since Phase 65 | `validation_case_extras.jl` lines 39, 104 | **Fixed 2026-10-28** in §2.13 |
| F7 | SRC_PASSTHROUGH checks `:e11` and `:synthetic` only, not the aircraft F1A field into `PainInputs` | case record | Add an `:aircraft` row as a new dated criterion, before the run **Done 2026-10-28:** `:aircraft` row added (criterion unchanged: difference 0). First run 2026-10-28: met, 3/3, 0.0 Pa |

**Done when** F1–F4 and F7 are applied, the map tests and the full suite pass, and §2.13 and §2.14 are updated.

## 8o. Phase 71 — audit of the remaining map blocks *(done 2026-10-28)*

Method: for each chunk, read the case records and the code each case calls, and check three things: does a test pass by construction; are the recorded inputs and the report files current with the code; does a code path silently use something other than what the record says. Phases 69 (polars) and 70 (free field) hold the aircraft-source and free-field findings.

**Which cases the polar defects reach** (traced in code, 2026-10-28). The μ = 1 defect only matters where the polar depends on Re. Affected: every case that reads an XFOIL file. Report 996 (R996_LOADS, R996_FIG6, R996_FIG7, R996_FIG12, R996_FIG13A, R996_FIG14, R996_PHASE, through `scale_factors.csv` and `f1a_results.csv`), Pereira (PER_LOADS, PER_FIG6–9, through `pereira_results.csv`), POLAR_R996, POLAR_PER, POLAR_FIDELITY, PROP_BB_FIG14/17 and T2_PRED_BB. **Not affected** (they use the default linear polar or a hand polar, with no Re dependence): F1A_CHORDWISE, the BEMT_* and F1A_* code checks, BBN_*, T1_F1A_FILL, T1_F1A_MEAS_DAMP, F1A_PLANE_PEAK and AC_CABIN_DEMO.

| # | Chunk | Finding | Action |
|---|-------|---------|--------|
| A1 | 3 Grid and blocking | Four report scripts still used z_p = 0.90 m after Phase 65 (`e12_blocking.jl`, `run_gext_bound.jl`, `run_f1a_smoke.jl`, `compare_gext_vs_f1a_grid.jl`). The GUI's "Open report" for E12_BLOCK showed the old geometry, and a maximum of 4.3 dB where the current case gives 4.0 dB. | **Fixed 2026-10-28** (scripts now use 0.662 m). Regenerate `e12_blocking.md` and the GEXT bound report; the recorded verdicts come from the `src/` cases and do not change. **Done 2026-10-28:** both regenerated. The GEXT report's nominal T1 moved from 84.21/77.66/78.06 dB to 86.59/80.02/76.39 dB, now identical to the T1 case (which already used 0.662 m), so the old report was stale and not the case. The any-flip result is unchanged (T1 not claimable) |
| A2 | 3 | UT_GRID input text said z_p = 0.90 m | **Fixed 2026-10-28** |
| A3 | 3 | E12_BLOCK: Table 8 + ΔL against NASA's predicted E-12 curve (e12_blocking.md, pre-Phase-65 geometry) differs by direction and grows with harmonic: aft (k ≥ 9) +1.0 to +1.3 dB at H1, +1.8 to +2.1 at H2, +3.3 to +4.3 at H3; forward (k ≤ 6) within ±0.5 dB at H1 and H2, −1.5 to −2.9 dB at H3. Our ΔL (Eq. 43 R1) is 5.77–6.00 dB at every harmonic and symmetric fore and aft, so NASA's prediction contains a term that depends on both frequency and direction that this implementation does not | Lead (not tested): a frequency- or Mach-dependent term in NASA's Eq. (43) or its free-field input (for example convection or a ka term) that the as-printed R1 omits. Next: compare the CR-172428 Eq. (43) page with `blocking.jl` term by term, and regenerate the report with the 0.662 m geometry. The class stays I until then. **2026-10-28 update:** the report regenerated with 0.662 m shows the same pattern (29/31; aft H3 +3.3 to +4.3 dB, forward H3 −1.5 to −2.9 dB), as expected, because ΔL depends only on the incidence angle. CR-3813 p. E-18 says the E-12 prediction is Eq. (43) applied "to the output of ANOPP", and Fig. E-11 plots that ANOPP free field as its solid line. So the test that separates the two leads is E-12 predicted − E-11 predicted at each X₃/D against our ΔL: if the difference is a symmetric ~6 dB, Eq. (43) is reproduced and the asymmetry is in Table 8 versus NASA's ANOPP line; if not, Eq. (43) has a term we omit. **Next step A3b (registered 2026-10-28, before any reading):** digitize the E-11 *predicted* (solid) line, two passes as for E-11 measured, and record the comparison as a diagnostic with no verdict. E12_BLOCK's criterion is unchanged. **Done 2026-10-28** (`data/digitizers/e11_e12_linefit.py` → `docs/validation_reports/e12_a3b_linefit.md`, `data/cr3813/e11_pred/`). Both figures were calibrated from detected tick marks (the E-12 scan is sheared by about 12 px top to bottom, which the 2026-10-20 by-eye calibration did not correct), and each predicted line was fitted segment by segment to its pixels. Results: (1) the E-11 predicted line equals ANOPP Table 8 within 0.0–1.2 dB at every station, so Table 8 is the free field NASA plotted; δ_dig of the E-11 line (pixels vs a by-eye pass) 1.6 dB. (2) NASA's step E-12 − E-11 is 4.5–7.5 dB at H1 and H2 (mean 5.5 and 6.0 dB) with no fore/aft trend, against Eq. (43) R1's 5.7–6.0 dB. (3) Table 8 + ΔL against the pixel-read E-12 line is within ±1.7 dB at 27 of 28 stations. The "aft excess grows with harmonic" pattern came mostly from the by-eye E-12 digitization on steep slopes (H2 aft +1.8 to +2.1 by eye, +0.3 to +1.0 from pixels). The E-12 corners sit 0.01–0.02 X₃/D forward of the E-11 corners at H1 and H2 (a drafting offset), which explains the remaining +0.5 to +1 dB aft. (4) One point stays: H3 k10, +4.9 dB. There NASA's drawn H3 aft line is one straight segment from the k9 corner to the frame and implies a 2.3 dB step, which Eq. (43) as printed (ΔL ≥ 5.67 dB) cannot give; the documents do not explain it. **Conclusion:** no missing term in our Eq. (43). E12_BLOCK stays FAIL as recorded (criterion and digitization unchanged; re-reading E-12 by pixels after seeing the result would be post-hoc). §2.14 class: I (the by-eye digitization of steep curves, now shown) plus N for H3 k10. |
| A4 | 5 CYL2D | CYL2D_WEYL compares the mode count with the Weyl leading term only. For a rigid-walled (Neumann) cavity the surface term is positive and large at low kh, so N/W > 1 is expected even for exact modes. With the surface term (post-hoc) the ratio is 0.99–1.21 up to the fourth frequency and 1.51 at the fifth | Class D (test design) for the first four frequencies, M only at the fifth. Closure register amended. Criterion unchanged |
| A5 | 7 PAIN main | LOUDEST_PT (a) is class D as recorded (the point set leaves out wall nodes). No new finding | none |
| A6 | 4, 6, 7 | The input-QA, isolation and closed-form cases (MRP_INPUT_QA, CABIN_GEOM_HAND, TRIM_INPUT_QA, TRIM_PASSIVITY, PAIN_INPUT_ECHO, ISO_*) compare code with printed or independently derived values. None compares a function with itself (ISO_BB_BAND's earlier self-comparison was already fixed 2026-10-23) | none |
| A7 | all | Report files can predate their case's last re-record. Checked: `e12_blocking.md` and `phase62_65_map_blocks_grid.md` still show z_p = 0.90 m. The case snapshot `case_error_summary.csv` (2026-10-24) is current. Not checked file by file | Regenerate the reports whose script still exists, in the Phase 69 rerun batch. **Done 2026-10-28:** `report996_loads.md`, `report996_acoustics.md`, `pereira_forward_flight.md`, `e12_blocking.md`, `gext_importance_bound.md` and `case_error_summary.csv` regenerated. `phase62_65_map_blocks_grid.md` names 0.90 m only as the old value in its finding text, which is correct as a record |

**Done when** A1's reports are regenerated, A4's closure-register row is amended, and the full suite passes.

## 8p. Phase 72 — observer fore/aft convention (Report 996, Pereira) *(done 2026-10-28)*

**Finding (2026-10-28).** Found while auditing why the Pereira tones still miss after Phase 69 brought thrust to +0.7 %: our H1 directivity is the mirror image of Pereira's own BEMT curve (ours falls from 84.7 dB at φ = −20° to 74.0 dB at +40°; theirs rises from 78.7 to 83.9 dB at +20°). The basis for the fix is in the documents and the code, not in the measured data:
1. AcousticAnalogies `_standard_ccblade_transform` (ccblade_helpers.jl): "the rotor is traveling in the positive x direction", so AA +X is **ahead** (upstream). Our own F1A_GUTIN_ANGLES case confirms it independently: F1A matches the Garrick–Watkins/Gutin form with x forward at 4/5 angles, the near-null (thrust and torque cancelling) being ahead at θ = 60°.
2. Pereira: φ is positive downstream (Fig. 2b; the digitization header), microphones on a 1 m arc around the centre of rotation, and the text says the BEMT gives "slightly lower levels towards the upstream direction". `run_pereira.jl` places φ at x = +sin φ, i.e. positive φ upstream. **Fix:** x = −sin φ.
3. Report 996: negative x/D is behind (`hub_observers` docstring, 25d). The 25d decision mapped "behind" to AA +X (`x_sign = −1`), reading the module docstring "freestream along +X" as the flow direction, which puts the behind microphones ahead. **Fix:** `x_sign = +1` in every Report 996 script; the module and `hub_observers` docstrings corrected. The existing physics check already flagged it ("behind>ahead=false" in `run_report996_acoustics.jl`; measured behind 1328 vs ahead 1009 dyne/cm²).
4. Pereira Fig. 7 phase: the digitized fit is p = A cos(kBθ − ψ) (`harm_per7.py`) and our FFT phase is p = A cos(ωt + φ), so Δψ = −Δφ. `run_pereira.jl` compared them with the same sign. **Fix:** negate.

**Not affected:** the aircraft path (`_observer_aa` maps x₃, forward positive, to AA +X: ahead); the code-on-code cases (F1A_INDEP, F1A_CHORDWISE: both sides use the same observers); the BPM broadband path (its own frame).

**Rules.** No criterion, tolerance, digitized value or polar is changed. Every rerun result is post-hoc (the first results are known) and recorded beside the old one. Tests: a static Report 996 check that the H1 amplitude behind the plane exceeds the one ahead at x/D = ∓0.125 with the Report 996 convention (Gutin; fails with `x_sign = −1`), and the Pereira observer builder's sign.

**Steps.**
- [x] 72a Code: `R996_X_SIGN` and `pereira_observers` in `src/` (scripts use them), docstrings, tests. **Done 2026-10-28:** `src/propeller_ccblade.jl` (constants, builder, docstrings), `run_report996_*.jl`, `report996_setup.jl`, `probe_static.jl` (now at x/D = −0.125, behind, as its comment intended), `run_pereira.jl` (builder; Δψ = −Δφ), F1A_INDEP observers. Test `observer fore/aft convention (Phase 72)`: builder signs, and a static Report 996 propeller at x/D = ∓0.5 is louder behind than ahead (ratio ≈ 1.5; ≈ 0.66 with the old sign). A first threshold of 1.05 at x/D = ∓0.125, d/D = 0.083 failed (ratio 1.046 there); the test point was moved to x/D = ∓0.5, d/D = 0.5 after seeing that (test design, no criterion).
- [x] 72b Rerun `run_report996_acoustics.jl`, `run_report996_loads.jl`, `run_pereira.jl`; snapshot; records. **Done 2026-10-28 (post-hoc):** Report 996 p. 6 was then read and confirms the sign ("positive values denote positions ahead of the propeller plane"); it also says the maxima usually occur at x/D = −0.125. R996_FIG13A **met 14/14** (was 8/14; behind/ahead 1193/1032 vs measured 1328/1009 dyne/cm²); R996_FIG12 **13/40** (was 28/40; too loud behind and too quiet ahead at mB ≥ 4 for β = 10°); R996_FIG14 **not met 14/24** (was met 20/24; Fig. 14 is behind the plane and H4/H6 are now too loud); PER_FIG8 H1 **5/7** (was 3/7; H1 directivity within 0.8 dB of Pereira's own BEMT at all angles), PER_FIG9 H1 0/9 (Fig. 9's measured H1 is about 4 dB below Fig. 8's, I-04), PER_FIG7 1/3 (was 2/3); `scale_factors.csv` unchanged (x/D = 0); F1A_INDEP met 3/3. Totals unchanged (41 met, 45 not met, 17 no verdict). The earlier FIG12 and FIG14 agreement depended on the mirrored observers.
- [x] 72c Docs, full suite, review, commit. **Done 2026-10-28:** full suite 10,095 pass, 0 fail; the recorded-result pins for R996_FIG14 (20 → 14, met → not met) and PER_FIG9 H1 (3 → 0) were updated with dated comments, since this phase changes those recorded results.

## 8r. Phase 74 — Pereira PER_FIG8 / PER_FIG9 *(done 2026-10-28; moved to the bottom 2026-10-28)*

**Findings (2026-10-28, after Phases 72 and 76; PER_FIG7 is met).**
1. **PER_FIG9 H1 0/9 is a digitization error.** `pereira_fig9_harmonics.csv` holds H1 = 80.0 dB for all three series at all three angles (author's WebPlotDigitizer export, I-15(d), "accepted as read"). The figure (PDF p. 10) has a 20–100 dB axis with ticks at 50 and 100; the H1 bars end well below 100 and visibly above 80, in line with Fig. 8 (82.5–85.1 dB measured) and Table 4 (OSPL 84.6 dB measured at φ = 0°). Fig. 9 is vector graphics: every bar is a filled rectangle in the PDF, so it can be read exactly.
2. **PER_FIG8: H1 6/7, H2 4/7.** The misses are H1 at φ = −20° (−2.0 dB) and H2 at −20° (−3.2), +20° (+3.7), +30° (+3.0). Pereira's own BEMT misses more at −20° (H1 −4.9, H2 −10.1); Pereira's CFD, with the full geometry, misses H2 by 3.9, 3.1, 1.2, 0.2, 2.6, 1.9 and 2.4 dB at the seven angles. Our H2 misses are the size of the CFD's, at the same angles, and the measured H2 is not monotonic (65.7 at 20°, 64.3 at 30°, 65.1 at 40°). The −20° microphone sits about 0.34 m upstream of the rotor plane, 0.04 m upstream of the 0.6 m nozzle exit, where nozzle reflection is plausible (not quantified in the paper). Open-jet shear layer: at M 0.047 and a 0.3 m jet radius, Amiet's correction is about 2° in angle and well under 1 dB, so it cannot explain 3 dB.

**Steps.**
- [x] 74a **Fig. 9 re-digitization from the PDF vectors (rule fixed 2026-10-28 before any value is read).** `data/digitizers/dig_pereira_fig9_vector.py`: read every filled rectangle on PDF p. 10; series by fill colour (BEMT black, numerical red (0.64, 0.08, 0.18), experimental blue (0, 0.45, 0.74)); panel by position; harmonic by bar-group order (10 groups per panel); SPL from the bar top with the axis from the drawn tick marks (100 dB at the top tick, 50 dB at the second, 0.712 pt/dB; the frame bottom is then 20 dB); ΔSPL bars from the zero line with 2.82 pt/dB. Consistency check, fixed now: ΔSPL(exp − BEMT) read from the lower panel must equal SPL(exp) − SPL(BEMT) from the upper panel within 0.5 dB wherever neither bar is clipped at ±10 dB. The old file is kept as `pereira_fig9_harmonics_pre74.csv`. The new values replace it whatever they are; no criterion changes; the PER_FIG9 rerun is post-hoc. **Done 2026-10-28:** 90 bars read, 0 check failures. Measured H1 84.22 / 84.45 / 82.57 dB and H2 70.35 / 65.69 / 65.07 dB at φ = 0° / 20° / 40°, equal to Fig. 8 within 0.1 dB, so Pereira's two figures agree. PER_FIG9 **H1 9/9** (was 0/9), H2 6/9 (miss only at φ = 20°, +3.7 dB); 15/18 rows within tolerance, median 0.35 dB (was 3.2). Still not met (H2). Totals unchanged: 44 met, 42 not met.
- [x] 74b **Not run (2026-10-28):** at M 0.047 the correction is about 2° and well under 1 dB, too small for the 3 dB H2 misses; the author also asked why a nozzle correction applies (it belongs to the open-jet tunnel, used only to compare with this experiment, never in the aircraft path). Kept for the record: shear-layer bound (no verdict): Amiet's cylindrical shear-layer correction for the 0.6 m jet at 16 m/s, applied to the seven microphones; report the change in level against φ.
- [x] 74c Record the PER_FIG8 H2 misses against Pereira's CFD spread (class N: installation/measurement, the documents do not allow a test); criterion unchanged. **Done 2026-10-28** (§2.14 register row).
- [x] 74d Rerun the cases, regenerate figures, five documents, targeted testsets, commit. **Done 2026-10-28:** `run_pereira.jl` rerun; PER_FIG6–9 and PER_LOADS figures regenerated; Validation case registry 3024/3024 (PER_FIG9 pin updated to H1 9/9); digitizer output reproducible byte for byte.

## 8s. Phase 75 — stale validation figures in the GUI *(done 2026-10-28; moved to the bottom 2026-10-28)*

**Problem (author, 2026-10-28: the updated figure only shows after pressing Run).** Selecting a case (`select_validation_case_from_qml`, `src/gui_main.jl`) shows the PNG already saved under `docs/validation_reports/figures/<block>/`; only `run_validation_gui!` (`src/gui_model.jl`) recomputes the case and rewrites it. When a phase reruns a generator script and re-records results, the saved PNGs are not redrawn. In Phases 69–72 they were also deliberately restored to their committed versions before each commit (CLAUDE.md "no regenerated figures", read too broadly), so figures such as R996_FIG12, R996_FIG13A, R996_FIG14, PER_FIG7–9 and POLAR_FIDELITY still show pre-change results, while the map chips (from `case_error_summary.csv`) are current.

**Steps.**
- [x] 75a Script `scripts/run/regenerate_case_figures.jl`: run every registered case (or a given list) offscreen and save its PNG to its block folder through the same `plot_case` path the GUI uses. Run it for every case whose recorded result changed in Phases 69–73, and commit those figures as intended regenerations (named in the commit), not stray ones. **Done 2026-10-28:** the script runs the given cases (or `--all`) offscreen, saves each figure through `plot_case` and rewrites only those cases' rows of `case_error_summary.csv`; the Phase 69–76 cases were regenerated in 76c, and the Phase 77–79a cases with it (MRP_APPD, UNC_COVER, AC_CABIN_DEMO, ISO_CYL2D_EXACT (first saved figure), T1_FROM_E12, E15_STRUCT_LOSS, POLAR_FIDELITY).
- [x] 75b Staleness flag: on selection, compare the saved PNG's modification date with the case's run date in `case_error_summary.csv` (and with the mtime of its replay data file, if any); when the figure is older, show "figure older than the recorded result — press Run" over it. Test: a temp PNG older than its snapshot row raises the flag; a newer one does not. **Done 2026-10-28:** `validation_figure_stale` (`src/validation_plots.jl`, day resolution against the row's `run_date`); `select_validation_case_from_qml` says "the saved figure is older than the recorded result (date); press Run to redraw it" in the status line (no QML change); testset `figure staleness flag (Phase 75b)`.
- [x] 75c **Not done (optional, 2026-10-28):** the flag and the script cover the problem; redraw-on-select would add a second figure path to maintain. Kept for the record: replay cases (about 1 s each) redraw on selection; the Run button stays for slow cases.
- [x] 75d Procedure (adopted 2026-10-28): each phase's rerun step regenerates the figures of the cases it re-records (added to the plan's rerun template); CLAUDE.md's "no regenerated figures" is read as "no unintended ones".
- [x] 75e Five documents, GUI smoke scripts, commit. **Done 2026-10-28:** full suite not run (author 2026-10-28: no long tests); unit testsets `validation_plots` and `gui_model` pass; both GUI smoke scripts SMOKE_RESULT.

## 8t. Phase 76 — thickness noise in the experimental source comparisons *(done 2026-10-28; moved to the bottom 2026-10-28)*

**Decision (author, 2026-10-28).** The Report 996 and Pereira cases compare F1A with measured pressures, which physically contain thickness noise as well as loading noise. The runs were registered loading-only, following Report 996's loading-only theory (Eq. 2), not the physics of the measurement. Pereira's own BEMT-based prediction uses monopoles for thickness. So every experimental source comparison is run with the thickness term on. This is not calibration: the only new input is each station's cross-section area, measured from the airfoil coordinates; nothing is fitted or chosen from a residual. The results are post-hoc (the loading-only results are known) and are recorded whichever way they move.

**Rule (fixed before the run).**
1. A/c² per section: Report 996 NACA 16 sections from `data/report996/xfoil_sections/*.dat` (shoelace area of the closed contour / chord²); Pereira NACA 4412 from the NACA 4-digit thickness distribution (A/c² = 0.68505·t, camber does not change the area to first order), t = 0.12.
2. Per station: linear in t/c between the two sections that bracket the station (clamped at the ends), as the polars are blended (`station_t_over_c`). Passed as `propeller.area_over_chord2`.
3. Report 996: `run_report996_acoustics.jl` runs with thickness on for every figure (FIG6, FIG7, FIG12, FIG13A, FIG14, PHASE). Pereira: the thickness-on rows become the recorded comparison (`loads = "scaled"`); the loading-only rows are kept as `scaled_toff`. The old `ton` row used t/c = 0.12 directly as A/c² (about 1.5× too large) and is replaced.
4. Unchanged: criteria, tolerances, digitized data, polars, loads scaling, observers. The code-check cases (F1A_INDEP, F1A_GUTIN*, F1A_GW_FLIGHT, BEMT_*) stay loading-only, because their references are loading-only closed forms; F1A_THICKNESS already checks the thickness term.
5. Check before the rerun: the computed A/(t·c) of the ten Report 996 sections must fall in the 0.72–0.84 measured in 69a3.

**Steps.**
- [x] 76a `src`: section A/c² from coordinates, the NACA 4-digit value, station blending; tests (shoelace on a known polygon; NACA value against numeric integration; blending at and between sections). **Done 2026-10-28:** `airfoil_area_over_chord2`, `naca4_area_over_chord2`, `station_area_over_chord2`, `report996_area_over_chord2` (`src/propeller_ccblade.jl`); testset `section area / chord² for the thickness term (Phase 76)`. Rule 5 met: A/(t·c) 0.723–0.836 for the ten sections; NACA 4412 A/c² = 0.0822.
- [x] 76b Scripts: Report 996 acoustics and Pereira switched as in rule 3. **Done 2026-10-28.**
- [x] 76c Rerun, snapshot (diff against the pre-76 snapshot), regenerate the changed cases' figures (Phase 75 procedure), records post-hoc beside the loading-only results. **Done 2026-10-28 (post-hoc):** R996_FIG14 **met 24/24** (was 14/24), R996_FIG12 **met 32/40** (was 13/40), R996_FIG13A met 14/14, PER_FIG7 **met 3/3** (was 1/3), PER_FIG8 H1 6/7 and H2 4/7 (was 5/7, 3/7), PER_FIG9 unchanged (I-04), R996_PHASE still FAIL (42°). Totals 44 met, 42 not met, 17 no verdict (was 41, 45, 17). The 25k check: behind 1130 vs ahead 1107 dyne/cm² (measured 1328 vs 1009). Figures regenerated for the 21 cases re-recorded in Phases 69–76 (part of Phase 75a).
- [x] 76d Five documents, full suite, GUI smoke scripts (figures), /code-review, commit, push. **Done 2026-10-28:** full suite not run (author 2026-10-28: "i dont want to run the full suite"); targeted testsets passed: Unit tests propeller_ccblade 64/64, zz_completeness, Validation map errors 421/421, Validation case registry 3024/3024; both GUI smoke scripts pass. Review fix: `station_area_over_chord2` with one section (test added).

## 8u. Phase 77 — POLAR_FIDELITY: show the error as an equivalent angle of attack *(done 2026-10-28; moved to the bottom 2026-10-28)*

**Why (author, 2026-10-28).** POLAR_FIDELITY reports Δc_l = c_l(XFOIL) − c_l(TN 1546), which is hard to read: what does Δc_l 0.2 mean? A percentage error does not work on this data. 13 of the 60 matched points have |c_l| < 0.2 (zero lift sits near α = −4.23° on the cambered sections), so the same small offset reads as −3933 % at a measured c_l of 0.002 (inside TN 1546's ±0.005 accuracy) and as −20 % at c_l 0.51. The percentage also ranks errors backwards against their effect on blade thrust. Expressed as an angle, the offset is readable: XFOIL's lift curve shifted by about 0.5° (the criterion) or 2° (a 0.2 miss).

**Solution (display only; the dated Δc_l criterion, the verdict and the table rows do not change).**
- Equivalent angle-of-attack error Δα = Δc_l / a(M), with the Prandtl–Glauert section lift slope a(M) = 2π/√(1 − M²) per radian (0.120/deg at M 0.4, 0.158/deg at M 0.72). The slope comes from theory, not from the data, and the Mach dependence matters over the TN 1546 range M 0.4–0.72. A fixed 0.11/deg would understate the angle by 10–30 % at the higher Mach numbers.
- Not chosen: the local XFOIL lift slope (it goes to zero near stall, so Δα would blow up there); a percentage (above).

**Steps.**
- [x] 77a `_p67_equiv_dalpha_deg(Δc_l, M)` in `src/validation_case_iso67.jl`; unit tests: 1° of lift slope at M = 0 gives 1.0°; at M = 0.6 the factor is √(1 − 0.36) = 0.8.
- [x] 77b POLAR_FIDELITY figure: three more panels (one per section), equivalent Δα against α, titled "equivalent Δα (display only)", y label "Δα = Δc_l / (2π/√(1−M²)) (deg)". The error panel stays Δc_l with the 0.05 band. Optionally, the 0.05 band also drawn on the Δα panels at the matching angle per Mach. **Done 2026-10-28** (panels 4–6; the optional band not drawn: one band per Mach would crowd the panels, the case info states the conversion).
- [x] 77c Case-info text: one line explaining that Δc_l 0.05 ≈ 0.4–0.3° at M 0.4–0.72 and why no percentage is shown. **Done 2026-10-28:** 0.42° at M 0.4, 0.32° at M 0.72 (inputs echo `equivalent_angle` and the case record).
- [x] 77d Regenerate the POLAR_FIDELITY figure (Phase 75 procedure), five documents, targeted testsets (case_helpers_iso67, zz_completeness, Validation map errors if the plot spec is checked there), GUI smoke scripts, commit. **Done 2026-10-28:** case_helpers_iso67 12/12 (tests: 1° at M 0, factor 0.8 at M 0.6); Validation map errors not run (author: no long tests); verdict unchanged (not met, 13/26 held-out). Label fix found in the figure check: the error panel's x axis said "α (deg)" but plots the row code 10 × section + Mach; it now says so.

## 8v. Phase 78 — structural modes: MRP_APPD, MRP_SHAPE_NORM and the no-verdict cases *(done 2026-10-28; moved to the bottom 2026-10-28; MRP_APPD recorded not met: floor stiffener model undocumented)*

**Findings (2026-10-28, diagnostic runs only; nothing changed).**
1. **MRP_APPD passes by construction of its matching.** `match_ritz_to_table_d1` pairs each Table D-1 frequency with the nearest unused solver mode by frequency alone. The App. D solver (`appd_modes`) has 61 modes below 820 Hz against Table D-1's 32 up to 811 Hz, about 13 Hz apart, so a ±5 % window finds a neighbour for almost any reference: the recorded 27/32 says little about the modes. Matched by identity (symmetry, axial m, dominant shell n, dominant floor n, the Table D-1 columns), the solver gives **2/32 within 5 %**: 19 identities have no solver mode, and the 13 matched are 20–70 % low (median −32 %). The (m = 1, n = 2, floor 0) mode is 135.6 Hz against 188.5 Hz; the solver's lowest mode is 115 Hz (n = 4). The solver is far too soft. The four greedy misses (modes 29–32 at 453–525 Hz) were the leftover modes.
2. **MRP_SHAPE_NORM, 19/32:** six shapes exceed unit maximum by 0.2–1 % (rounding of the printed coefficients), seven by 4–25 % (modes 4, 7, 11, 16, 21, 24, 27).
3. **No verdict:** MRP_D1 checks that Table D-1 is loaded (residual 0 by construction, cannot fail); MRP_RITZ is the surrogate whose three scales were fitted to Table D-1 (a calibrated path cannot be a pass against its own fit data).

**Author decisions (2026-10-28).**
- MRP_APPD: **identity matching** replaces frequency-only matching (new dated criterion, fixed before its first run; the 2026-10-22 pass is recorded as a test-design artifact). Expected to read not met (about 2/32) until the solver is fixed.
- Solver: **isolate the cause, then write a fix plan from the findings, then fix** (78b → 78c → 78d).
- MRP_SHAPE_NORM: if the seven large excesses are transcribed correctly, **record them as a data limitation** of the truncated printed table (criterion unchanged, no rescaling).
- MRP_D1 and MRP_RITZ: **removed from the Validation map**; kept as unit tests.

**Steps.**
- [x] 78a MRP_APPD criterion: a mode passes when a solver mode of the same symmetry, axial m, dominant shell n and dominant floor n (largest |C| in its shell and floor coefficients) lies within 5 % of the Table D-1 frequency; each solver mode used once; count rule unchanged (≥ 75 % of 32). Dated before the first run; the old greedy count shown as information. Test: a synthetic spectrum with the right frequencies but wrong identities must fail. **Done 2026-10-28:** `match_modes_by_identity` (`src/mrp.jl`); test `identity matching of modes to Table D-1 (Phase 78a)`: Table D-1 against itself 32/32; the symmetry-flipped spectrum 0/32 (the old matcher scores it 32/32); 10 % off 0/32. The largest-|C| definition reproduces the Table D-1 identity columns for all 32 modes. MRP_APPD now runs 80 solver modes and reads **not met, 2/32** (19 identities with no solver mode); the frequency-only count, shown for information, is 31/32.
- [x] 78b Isolation checks of `mrp_appd.jl`, each against an independent closed form or hand value, none against Table D-1: (1) bare unstiffened cylinder (no floor, no stiffeners) against Donnell / Arnold–Warburton frequencies for simply supported ends; (2) floor plate alone against the simply supported plate formula; (3) smeared stringer and frame stiffness (D.23–D.24) against hand-computed values from the App. E section properties; (4) total and modal mass budget against the App. E areal masses; (5) units of every App. E input (in/psi vs SI); (6) each reading in `APPD_READINGS` against the printed equation. Report which check fails and by how much. **Done 2026-10-28** (`scripts/checks/appd_isolation.jl` → `docs/validation_reports/phase78_appd_isolation.md`): (1) bare cylinder equals an independent Donnell 3×3 (in-plane inertia kept) at all 8 (m, n), ratio 1.0000: the shell operator is right. (2) the floor block equals the simply supported plate closed form with its own Df, mf: the assembly is right. (3) **inputs wrong:** `MRP_I_FRAME` and `MRP_I_FLOOR_BEAM` are the web alone (0.038³·t/12) and drop the two 0.017 m flanges of the App. E channel: 3.704·10⁻⁹ against 1.365·10⁻⁸ m⁴ (3.7×), so D_θR is 1,357 against 4,991 N·m; the floor stiffness is one isotropic sum (2,000 N·m) of the longitudinal beams (x) and the per-frame supports (y). `MRP_I_STRINGER` (0.0112³·t/3, one leg about its base) is also not the angle's centroidal value. (4) mass: model 5 % above the App. E parts sum. (5) units SI throughout. (6) generalized masses of identity-matched modes differ widely from Table D-1 (mode 11: 64 kg against 1.03), pointing at shape normalization. App. D (D.24) gives D_θR = D_θ + E I_ring/ℓ and D_xs = D_x + E I_stringer/d with the eccentricity (asterisk) terms dropped, so I is the stiffener's own centroidal moment of inertia; App. D treats the floor by classical plate theory and does not say how its beams and supports enter.
- [x] 78c Fix plan (carried out in 78d, 2026-10-28) **(registered 2026-10-28 from 78b, before any fix; primary readings fixed now from the documents, never chosen by agreement with Table D-1; alternatives reported without verdict):**
  - **F1 Stiffener inertias (D.24).** Centroidal moment of inertia of each App. E section about the axis parallel to the skin: ring frame and floor beams = channel 0.017 × 0.038 × 0.00081 m (web plus two flanges); stringer = angle 0.00953 × 0.0112 × 0.00051 m (both legs, centroid found from the section). Test: each I against a hand parallel-axis computation, and a rectangle and a channel of known I.
  - **F2 Floor orthotropy.** Floor bending Dx = D_plate + 2·E·I_beam/Lp (the two longitudinal beams, App. E text) and Dy = D_plate + E·I_support/ℓ (the per-frame floor supports, primary reading: transverse members under the floor at each frame, App. E Fig. E-3), with the twisting term from the plate alone; the floor block's bending energy becomes Dx μ⁴ + 2(ν D_plate + 2 D_xy) μ² k_y² + Dy k_y⁴. Alternative reading, reported only: supports as rigid line supports at the frames. Test: the orthotropic floor block against the orthotropic simply supported plate closed form.
  - **F3 Shape normalization and M_r.** Check that returned shapes are normalized to unit maximum displacement over shell and floor (p. D-10) and that M_r is the generalized mass of that shape; fix if not. Test: a returned shape's max |ψ| = 1 and M_r equals ∫ρψ² dA of that shape.
  - **F4 Rerun** MRP_APPD (identity criterion, post-hoc) after F1–F3, primary readings; then the alternative floor reading as information. If the identity count is still below 75 %, record the remaining modes per (m, n) against Table D-1 and return to 78b with what F1–F3 did not explain.
- [x] 78d Implement F1–F4, rerun MRP_APPD with the identity criterion (post-hoc), regenerate its figure. **Done 2026-10-28:** **F1** `channel_centroidal_I`, `angle_centroidal_I` (`src/mrp.jl`; tests against strip integration): frame and floor-beam I 1.365·10⁻⁸ m⁴ (was 3.704·10⁻⁹, web only), stringer I 1.422·10⁻¹⁰ m⁴ (was 2.388·10⁻¹⁰, one leg about its base), floor-beam area with both flanges (was one). The legacy Ritz surrogate keeps its fitted-era inputs (`_RITZ_LEGACY_*`) so its calibrated fit is unchanged. **F2** orthotropic floor (`_appd_floor_props`: Dx = D + 2EI/Lp, Dy = D + EI/ℓ, H = D; test against the orthotropic plate closed form). **F3** shapes are max-normalized (0.95–1.09 on a sampled grid), but M_r is qᵀMq of the full eigenvector (in-plane inertia and all coefficients) while ∫ρψ² dA counts the truncated normal displacement only (mode 3: 58.3 against 3.1 kg): not changed; which one PAIN's modal equation needs depends on App. D's definition of generalized mass (open, 78d-2). **F4** MRP_APPD (identity): **still 2/32**; the spectrum moved toward Table D-1 (lowest mode 170.8 Hz, was 115; Table D-1 188.5; 39 modes below 820 Hz, was 61; Table D-1 32). Knock-on (post-hoc): UNC_COVER (parametric cabin, App. D modes) 1/3 within criterion (H1 margin +0.19 dB, was −0.81; H2 −2.09; H3 −18.47), still not met; the aircraft demonstration path uses the corrected defaults. Fig. D-2 comparison skipped while Table D-1 mode 1 has no same-identity solver mode.
- [x] 78d-2 **Back to isolation (F4 rule), leads registered 2026-10-28:** (L1) axial stiffness: the solver puts m = 5–7 modes below 700 Hz (382, 510, 669 Hz) where Table D-1 has none above m = 5 below 811 Hz; the stringer contribution with the eccentricity (asterisk) terms dropped is the first suspect; check D_xs and the membrane kx against the printed (D.23)–(D.25) terms. (L2) circumferential order: several Table D-1 families sit one order below the solver's similar-frequency modes (Table D-1 (m2, n4, f0) 217.9 Hz against the solver's (m2, n5, f0) 207 Hz); check the (D.26) (−1)ⁿ cos nθ convention and the n numbering of the basis against Table D-1's printed coefficients for one mode. (L3) M_r definition (F3). **Done 2026-10-28 (diagnostics only, no code change):**
  - **L2, no convention defect; the 78a criterion is fragile.** Comparing whole normal-displacement shapes (MAC, Table D-1 shapes rebuilt from its printed coefficients), same-shape pairs match almost exactly (MAC 0.96–1.00 for Table D-1 modes 3, 4, 5, 7, 10, 11, 23, 24) even where the dominant-order labels differ (Table D-1 "n4" against the solver's "n5"): the label flips because neighbouring coefficients are close. Identity by largest |C| is therefore not a robust criterion.
  - **L1, the shell is right; the floor coupling is soft at high m.** Pages D-8–D-9 read from the scan: (D.25) matches the code term by term (including 4G·t³/12 twisting and kθ/r²); (D.24) gives D_xs = D_x + EI/d and D_θR = D_θ + EI/ℓ without defining I, and the text sets the stiffener offsets z̄s, z̄r to zero, so for the shell stiffeners centroidal I (F1) is the documented reading. Shape-matched shell modes fall short by a factor growing with m (0.95 at m 2 to 0.60 at m 5), but the closed stiffened cylinder alone is above Table D-1 at high m (m 5, n 4: 776 against 636 Hz): the floor coupling pulls the coupled modes down (to 382 Hz). App. D says only "classical plate theory" for the floor, so how its beams and supports act is not documented. Diagnostic variants (disclosed: run after seeing the numbers, so any adoption is post-hoc): V0 centroidal (current): lowest mode 170.8 Hz, 39 modes below 820 Hz, median |Δf| of the MAC ≥ 0.9 pairs 25.5 %; **V1** floor beams and supports about the floor mid-plane (composite action of channels riveted under the plate): 207.1 Hz, 34 modes, 7.2 %; V2 = V1 + shell stiffeners about the skin mid-plane (contradicts D-8's z̄ = 0): 242.2 Hz, 24 modes, 4.9 %. Table D-1: 188.5 Hz, 32 modes.
  - **L3, no defect.** (D.30) defines M_r over u, v and w of shell and floor, which is what the solver computes (qᵀMq); the ∫ρψ² comparison counted w only.
  - **Remaining under every reading:** about two thirds of the Table D-1 modes, mostly antisymmetric and mixed shell–floor modes, have no solver mode with MAC ≥ 0.9. Next isolation target: the shell–floor junction constraints (D.17)–(D.21) (rigid "bolt to skin" reading, `APPD_READINGS.attachment`) and the antisymmetric basis.
- [x] 78d-3 **Author decisions (answered 2026-10-28):** (a) MRP_APPD pairing by shape (MAC ≥ 0.9 against Table D-1 shapes rebuilt from the printed coefficients, then frequency within 5 %) instead of dominant-order identity, as a new dated criterion; (b) floor-stiffener reading V0 (centroidal, no documentary basis either way) or V1 (composite floor beams, physical but chosen after seeing results, so MRP_APPD stays post-hoc under V1); (c) then isolate the junction constraints and the antisymmetric family. **Author 2026-10-28: (a) pair by shape (MAC); (b) V1 composite.** Rules fixed now, before the run: a Table D-1 mode pairs with the unused solver mode of the same symmetry and axial index with the highest MAC, provided MAC ≥ 0.9 (normal displacement on the shell arc θ0…2π−θ0 and across the floor, length-weighted, Table D-1 shapes rebuilt from the printed coefficients); it passes when that partner is within 5 % in frequency; count rule unchanged (≥ 75 % of 32). V1: floor beams and supports bend about the floor mid-plane, I = I_c + A·(h/2 + t_floor/2)² with the App. E channel (h = 0.038 m). MRP_APPD under V1 is labelled post-hoc (the reading was chosen after the diagnostic). **(a) and (b) done 2026-10-28:** `match_modes_by_shape`, `mode_shape_field`, `modal_assurance` (`src/mrp.jl`; tests: Table D-1 against itself 32/32 with MAC > 0.999; shapes shuffled within each (symmetry, m) family < 16; 10 % off 0); `MRP_I_FLOOR_BEAM` about the floor mid-plane (test: strip integration about that plane). MRP_APPD **not met, 2/32** (7 Table D-1 modes have a shape partner with MAC ≥ 0.9, 25 have none; identity 4/32, frequency-only 15/32, information). Knock-on: UNC_COVER margins +0.52, −0.11, −18.36 dB (1/3, not met); MRP_RITZ unchanged (29/32). (c) **done 2026-10-28 (78d-4 below):** isolated from Fig. D-1 and pp. D-1–D-4; six code-consistency defects found and fixed (J1–J6); the remaining gap is the undocumented floor stiffness.
- [x] 78d-4 **78d-3 (c) findings and fix rules (registered 2026-10-28 from App. D pp. D-1–D-4 and Fig. D-1, before any rerun; code-consistency defects, nothing chosen from a Table D-1 comparison):**
  - **J1 Shape output convention.** Fig. D-1 measures θ from the top (θ1 from the top to the junction, w_s outward, w_p upward, y toward the junction); (D.4) holds at θ1 = π − θ0. The solver evaluates (D.4) at θ0 with the cos nθ / sin nθ basis, which is the same structure mirrored top to bottom: its amplitudes c_n are in θ from the bottom with the floor w positive downward (derived from (D.4) lines 2–4, all three consistent). `_appd_extract_shapes` returns them unconverted, while `shell_circumferential` and Table D-1 use App. D's basis (θ from the top: (−1)ⁿ cos nθ / −(−1)ⁿ sin nθ from the bottom) and the floor positive upward. Fix: C_n = (−1)ⁿ c_n (symmetric), −(−1)ⁿ c_n (antisymmetric), floor C_p = −c_p; the unit-maximum normalization and M_r follow the converted shape. Test: the returned shape reproduces the solver's own displacement at the junction (shell w·cos-projection equals the floor edge displacement through (D.4)), i.e. the converted field satisfies (D.4) evaluated in App. D's frame.
  - **J2 Shell domain.** Fig. D-1 and p. D-1 (Peterson and Boyd: a closed circular cylinder with a longitudinal interior plate) and (D.14) integrate the shell over its whole surface; the floor is an interior partition, the skin below it is part of the structure. The solver scales the shell energy and mass by the cabin arc fraction (246.8°/360°). Fix: full circumference (harmonics orthogonal, diagonal per n, as in Peterson). The acoustic coupling still uses the cabin arc only (unchanged).
  - **J3 Null basis functions.** In (D.3) sin nθ vanishes for n = 0: the symmetric v_0 and the antisymmetric u_0, w_0 are identically zero but carry stiffness and mass, giving spurious modes (zero normal shape). Fix: leave them out of the basis. Test: no returned mode has an all-zero shape.
  - **J4 Cross-family dedup.** `appd_modes` drops any mode within 0.5 % of the previous one "from overlapping bases", but the (M, parity) families are disjoint, so near-degenerate symmetric/antisymmetric pairs (expected for a full cylinder where the floor barely moves) lose one member. Fix: no dedup.
  - **J5 Antisymmetric floor sway (registered after the J1–J4 diagnostic run, before J5–J6 were run).** p. D-3: the plate set is "similar" to (D.3), whose sums start at n = 0; for antisymmetric motion that includes the uniform lateral floor displacement v_p = −cos 0 (u_0, w_0 vanish). The solver starts the antisymmetric floor at p = 1, so the floor edge cannot move sideways without large membrane strain. Fix: antisymmetric floor p from 0 (v only; u_0, w_0 and the symmetric v_0 fixed as null functions, J3).
  - **J6 Floor membrane energy.** With u = U cos μx cos k_y y, v = V sin μx sin k_y y (symmetric) the membrane energy gives K_uv = −(ν k + G t) μ k_y; the solver omits the G t term (the shell block has it). For the antisymmetric floor "similar" to (D.3) means v = −cos k_y y (as the shell's −cos nθ), for which the same K holds; the solver uses +cos in the constraint. Fix: add the shear coupling; antisymmetric floor v = −cos k_y y in (D.4). Test: the floor block against the membrane energy integrated numerically for both parities.
  - **Rerun rule.** MRP_APPD with the 78d-3 (a) shape criterion and V1, post-hoc (V1 was chosen after a diagnostic; the J fixes are not tuning). Recorded whichever way it moves; knock-on cases (UNC_COVER, aircraft App. D path) rerun.
  - **Done 2026-10-28.** J1–J6 in `src/mrp_appd.jl` (`_appd_extract_shapes` conversion, full-circumference shell, `_appd_null_rows` / `_appd_all_constraints`, no dedup, antisymmetric floor from p = 0, floor K_uv with G t and v = −cos); unit tests for each (84 checks), each failing on the pre-fix solver (11 failures). Rerun (post-hoc): MRP_APPD **not met, 2/32** (median |Δf| 9.5 %, max 51 %); Table D-1 modes with a shape partner (MAC ≥ 0.9) 10 of 32 (was 7); hinged attachment 12 (information). Diagnostics (no verdict): basis convergence n ≤ 8 → 24, p ≤ 5 → 14 moves the low modes by about 1 % (truncation ruled out). Family breakdown: the symmetric floor-dominated pairs of every axial order (Table D-1 modes 3, 4, 5, 7, 10, 11, 23, 24) match in shape (MAC 0.98–1.00) but not in frequency or order (m = 2: 329.8 and 274.5 Hz against 217.9 and 231.0; m = 5: 617 and 600 against 636 and 641), while 22 Table D-1 modes have no partner: 14 of its 16 antisymmetric modes, the m = 1 floor modes (188.5, 208.2 Hz) and six shell-dominated symmetric modes (6, 13, 15, 19, 25, 30). The floor frequencies are set by the floor bending stiffness and the edge support, i.e. by how the floor beams and supports act, which App. D leaves at "classical plate theory": no further reading is fixed by the documents. **Remaining, recorded:** MRP_APPD stays not met; the gap is attributed to the undocumented floor stiffener model (§2.14 class I, input); no further solver change without a documentary basis. Knock-on: UNC_COVER 0/3 (margins H1 −4.06, H2 −5.41, H3 −13.23 dB; was +0.52, −0.11, −18.36; the band medians 95.3, 87.7, 80.2 dB now lie above the measured 90, 80, 65; not met); AC_CABIN_DEMO unchanged (1/1, code check); 60a App. D modal density 4.0× (1000 Hz) and 0.46× (2000 Hz) the Table D-1 asymptote (was 2.3×, 0.19×; the recorded not-met holds).
- [x] 78e MRP_SHAPE_NORM: re-check the Table D-1 coefficients of modes 4, 7, 11, 16, 21, 24, 27 against the page scans (CR-3813 pp. D-13–D-16), two independent readings. A transcription error is corrected (and the coupling cases rerun, post-hoc); otherwise the record classes the excess as the truncated printed table (§2.14 class I) and the criterion stays. **Done 2026-10-28:** both readings (page scans at 130–400 dpi; the PDF's OCR layer) agree with `_D1_SHAPES` for all seven modes, except that the OCR layer reads mode 21's .20494 as .20194 (the scan, zoomed, is .20494). No transcription error: recorded as the truncated printed table (class I), criterion unchanged.
- [x] 78f (done 2026-10-28 after the author asked for the long testsets): remove MRP_D1 and MRP_RITZ from the Validation map (§2.13 map placement); keep their unit tests; the map tests still require every block to have a case with its own figure. **Done 2026-10-28:** §2.13 accepts "Map / block: none / <block>" (registered, not on the map; the block names the figure folder); MRP_D1 and MRP_RITZ use "none / P_MRP"; the registry test allows exactly these two off-map cases; the GUI unit test that used MRP_D1 as a map chip uses CABIN_GEOM_HAND. P_MRP keeps MRP_APPD.
- [x] 78g Five documents, targeted testsets (mrp, mrp_appd, Validation map errors, Validation case registry), GUI smoke scripts, commit. **Done 2026-10-28 for 78d-4/78e:** mrp_appd 84/84; the pinned App. D checks of the full suite (shape-mass band, constraint residual, orthogonality, 60a density ratios) run by script and hold; Validation map errors and Validation case registry not run (author 2026-10-28: no long tests); UNC_COVER pin updated to 0/3 with a dated comment.

## 8w. Phase 79 — CYL2D: information rows, grid refinement, Weyl count *(done 2026-10-28; moved to the bottom 2026-10-28; production NY = 10 kept, decided 2026-10-28)*

**Findings (2026-10-28, diagnostic runs only).**
1. **ISO_CYL2D_EXACT is met (11/11) but the map shows 12/21.** Its table holds 10 NY = 20 rows and one refinement row (the criterion) plus 10 NY = 10 rows marked "(info)", which carry a pass/fail flag although no tolerance applies to them. `case_error_summary` counts every row's flag, so 9 information rows show as failures (mode 0, the 0 Hz mode, is exact on any grid). The same counting affects any case with information rows (MRP_APPD's Fig. D-2 row).
2. **The floored cross-section cannot be refined.** `cyl2d_modes(56.6; NY)` errors with complex eigenvalues for every NY tried other than 10 (NY 12: max |Im| 0.017; 14: 0.019; 16: 0.0099; 20: 0.0063). A Neumann Laplacian has real eigenvalues, so the App. C boundary stencil (curved wall or floor-wall corner) gives a non-symmetric matrix that happens to stay real at NY = 10. The production grid (NY = 10, App. C Fig. C-3) therefore cannot be checked for convergence on the real cabin section. On the floorless circle (ISO_CYL2D_EXACT) NY = 10 is 2–19 % low on the first nine modes, NY = 20 within 2.4 %.
3. **CYL2D_WEYL, 0/5:** N/W = 1.71–1.87 against Weyl's leading term; with the surface term (post-hoc) 0.99, 1.07, 1.10, 1.21, 1.51. The leading-term criterion is the wrong reference for a rigid-walled cavity (test design); the 1.51 at 1500 Hz is attributed to the NY = 10 grid, which finding 2 prevents from being confirmed.

**Steps.**
- [x] 79a Information rows: rows whose group is marked "(info)" stay in the table and the figure (labelled "(info, production grid)" for the NY = 10 rows) but leave the pass count of `case_error_summary`, so the map chip agrees with the verdict (ISO_CYL2D_EXACT 11/11). Author 2026-10-28: the NY = 10 rows are kept, not removed. Test: a case with one information row that fails and two criterion rows that pass reads 2/2. **Done 2026-10-28:** `_is_info_row` / `case_error_summary` (`src/validation_plots.jl`: rows labelled "(info" leave the count and max/median; a table of information rows only is rolled up whole); NY = 10 rows labelled "(info, production grid)"; T1_FROM_E12's three E-12 coverage notes labelled "(info)". Chips: ISO_CYL2D_EXACT 11/11 (was 12/21), T1_FROM_E12 1/3 (was 7/9). Test in `error roll-up (case_error_summary)`.
- [x] 79b Refinement defect: locate where the App. C stencil loses symmetry (curved-wall irregular star or floor-wall corner) by checking the assembled matrix's asymmetry per node class at NY 10–20. Options, to be decided from that diagnosis: (A) keep the App. C stencil and accept eigenvalues with |Im| below a fixed tolerance relative to |Re|, taking the real part (reported); (B) a symmetric reference discretization (finite-volume / cut-cell) used only for convergence studies, production staying App. C at NY = 10. Tests: eigenvalues real; the circle (θ0 = 0) converges to the exact J′ zeros from NY 10 to 40; the floored section's frequencies converge monotonically. **Diagnosis 2026-10-28** (assembled matrix weighted by the reflected-edge trapezoid weights, per node class, NY 10–40): the floor rows are exactly symmetric; the asymmetry comes from the curved-wall ghost-point rows (Eq. C.2 one-sided normal condition), present on the floorless circle as well (which also turns complex at NY 30–40). The complex pairs sit high in the spectrum: the lowest 20 eigenvalues of each parity are real at every NY from 10 to 40 on both sections, except one pair at NY 20 (antisymmetric, rank 10, |Im|/Re = 3.9·10⁻⁴). The code rejected a grid when **any** eigenvalue, including the unused high ones, had |Im| ≥ 10⁻³. **Option A chosen (rule fixed 2026-10-28 before the convergence run):** the check applies to the kept modes only (lowest n_modes + 2 per parity by real part), relative |Im|/|Re| ≤ 10⁻³; their real parts and real eigenvector parts are used; the grid is still rejected otherwise. The App. C stencil is unchanged (NY = 10 results identical). Option B (a symmetric reference discretization) not needed for the modes used. **Done 2026-10-28:** `_solve_parity` (`src/cyl2d.jl`); tests: NY = 12 floored solves (errored before), the circle at NY = 40 within 1 % of the J′ zeros (rejected before). Convergence (diagnostic): circle max error 6.7 % (NY 10), 2.4 % (12), 1.0 % (20), 0.5 % (30, 40); floored ka of modes 2–10 converge with a ±1 % wobble from the boundary cut, NY 40 and 60 within 0.3 %; NY = 10 against NY 60: +4.1 % (mode 2), +3.0 % (mode 5), within 1.5 % for the others. The claim "converge monotonically" does not hold (alignment wobble); recorded, not a criterion. Production (NY = 10) unchanged.
- [x] 79c Converged floored reference (NY 40–80 with 79b): the production (NY = 10) error per mode at θ0 = 56.6°, as **a new validation case with its own figure** (author 2026-10-28; e.g. `CYL2D_GRID_CONV` on `X_CYL_OUT`: each floored-section mode at NY = 10 against the converged reference, per-mode error panel), not a report only. **Author decision afterwards:** keep NY = 10 (faithful to App. C as printed; CYL2D_C1 reproduces NASA's tables 59/59 there) or run production on a finer grid. **Done 2026-10-28:** `CYL2D_GRID_CONV` (`src/validation_case_iso40.jl`, block X_CYL_OUT, no verdict): 19 modes, NY = 10 at most 4.94 % from NY = 60; NY 40 vs 60 at most 0.21 %. **Decided 2026-10-28 (author's full authority, from the documents): keep NY = 10.** CR-3813 App. C prints NY = 10 and CYL2D_C1 reproduces NASA's tables 59/59 there; the PAIN reproduction cases compare against NASA's outputs computed on that grid; a finer production grid chosen after seeing the T1/T2 misses would make every cabin re-record post-hoc. The NY = 10 discretization error (≤ 4.9 % on the first 19 floored-section modes) is a stated limitation, quantified by CYL2D_GRID_CONV.
- [x] 79d CYL2D_WEYL: new criterion against Weyl with the rigid-wall surface term (dated, post-hoc since the counts are known), the count taken from the converged reference and from production, to show whether the 1500 Hz excess is the NY = 10 grid. **Done 2026-10-28:** criterion ±25 % of Weyl + surface term on the production count (dated, post-hoc): **not met 4/5** (NY 10: 0.99, 1.07, 1.10, 1.21, 1.51); NY 40 (information): 0.99, 1.06, 1.03, 1.02, 1.02, so the 1500 Hz excess is the NY = 10 grid.
- [x] 79e Five documents, targeted testsets (cyl2d, Validation map errors, Validation case registry), GUI smoke scripts, commit. **Done 2026-10-28** (results in the commit and the README).
- [x] 79f Follow-up (2026-10-28): no-verdict figures drew a tolerance band although they have no criterion; `plot_case` now draws the band (both panels) only for a case with a criterion. Redrawn: GEXT_BOUND, MRP_D1, MRP_RITZ, E15_STRUCT_LOSS, F1A_CHORDWISE, BBN_LEVELS, CYL2D_GRID_CONV (records unchanged).

## 8q. Phase 73 — Report 996 section-polar fidelity *(done 2026-10-28; 73e decided: not adopted; moved to the bottom 2026-10-28)*

**Why.** After Phases 69 and 72 the Report 996 misses (R996_LOADS 24/32, FIG12 13/40, FIG14 14/24, PHASE) are classed A, XFOIL section fidelity: the free-transition N_crit 8 fit misses the held-out 16-312 (13/26 within 0.05), and XFOIL is unreliable above the sections' critical Mach (tip M_t 0.75–0.9).

**Steps (criteria to be fixed and dated before any comparison).**
- [x] 73a Inventory: which Report 996 stations (section, Re, M, α) the converged BEMT actually uses, and how many fall where TN 1546 has measured c_l (16-312, 16-506, 16-509 at M 0.4–0.72) or where XFOIL is above the critical Mach. **Done 2026-10-28** (primary set, nine (β₇₅, M_t) configurations, thrust per station Np·dr as the weight): about 31 % of the thrust sits on the three measured sections (by t/c blend weight), but only 0–24 % of the total lies inside TN 1546's measured range (α −4.23° to 7.77°, 11.77° for 16-312; M 0.3–0.75). The static stations run at α up to 17.5° (β 8°) to 29.8° (β 20°), past every TN 1546 curve, and β 20° has none of its thrust in range. XFOIL (N_crit 8) minus TN 1546 at the 60 matched points: mean −0.026, RMS 0.056 (16-312 −0.032 / 0.073, 16-506 −0.011 / 0.031, 16-509 −0.027 / 0.043).
- [ ] 73b **Not run (decided 2026-10-28 from 73a, before any rerun):** the measured data would replace at most a quarter of the thrust-weighted polar input, so this option cannot settle the question. Kept for the record: Option A, measured section data: build a polar from the digitized TN 1546 c_l (and c_d where printed) for the matched sections, interpolated in M, and use it at those stations; XFOIL elsewhere. This uses the TN 1546 data as an input, so POLAR_FIDELITY on those sections becomes no-verdict, and the Report 996 cases stay tests against Report 996 (never fitted to it).
- [x] 73c Option B, sensitivity only. **Rule fixed 2026-10-28 before the run:** every station's c_l is shifted by δ ∈ {+0.026 (the mean measured offset removed), −0.056, +0.056 (± the RMS)}, c_d unchanged, for (1) the nine primary loads configurations: C_T and C_P against the measured values next to δ = 0; (2) the scaled-load acoustics at the Fig. 14 microphone (x/D = −0.125, d/D = 0.083, β₇₅ 10°, M_t 0.45–0.90) and the Fig. 13(a) / Fig. 12 points: change in harmonic level (dB) against δ = 0. Bound only: no verdict, no case record changes, no δ is adopted. Reading: if |ΔC_T| at δ = ±0.056 is small against the R996_LOADS misses (up to 39 %), or the level change is small against the 2–5 dB acoustic misses, section-polar fidelity at the measured level is not the cause. Script `scripts/run/r996_polar_sensitivity.jl`, report `docs/validation_reports/phase73_polar_sensitivity.md`. **Result 2026-10-28** (`docs/validation_reports/phase73_polar_sensitivity.md`): removing the mean c_l offset (+0.026) moves thrust by about +3 %; ±0.056 moves it by at most 7.9 %. The scaled-load levels at the Fig. 14 and Fig. 12 microphones move by at most 0.19 dB. The large misses (β₇₅ 20°: T −30 %, Q −39 %; torque −8 to −22 % at β₇₅ 10°) and the 2–5 dB acoustic misses are therefore not from the section c_l at the measured level.
- [x] 73c2 **c_d bound (registered 2026-10-28 after 73c's result and before this run).** 73c showed c_l at the measured level moves thrust by ≤ 7.9 % and the scaled-load levels by ≤ 0.19 dB, while the loads miss most in torque. Input diagnostic first: XFOIL (N_crit 8) c_d against TN 1546 measured c_d at the matched points (TN c_d interpolated in M at the same α): median ratio 0.75 (55 points; 16-312 0.74, 16-506 0.75, 16-509 0.79), so XFOIL's drag is about 25 % low. Rule: every station's c_d multiplied by k ∈ {1/0.75 = 1.33 (median measured ratio removed), 1.0}; c_l unchanged; the loads table of 73c only (torque and thrust against measured). Bound only: no k adopted, no record changes. **Result 2026-10-28:** with c_d × 1.33 the torque misses roughly halve: Fig. 14 table β₇₅ 10° Q −7.8/−15.4/−15.5/−21.7 % → −0.6/−8.4/−7.7/−14.0 % (M_t 0.45–0.90), Fig. 7 legend β₇₅ 15° −19.0 → −8.1 %, β₇₅ 8° −7.5 → −1.0 %, RM L8H25a β₇₅ 10° −3.0 → +4.5/+5.1 %; thrust changes by < 0.6 %. β₇₅ 20° stays at T −31 %, Q −27 % (stations at α up to 30°, stalled; static momentum theory) and M_t 0.9 at Q −14 % (tips above the critical Mach). **Conclusion:** XFOIL's low drag (about 25 % below TN 1546 at TN 1546's Reynolds numbers) is a real part of the Report 996 torque gap; the section c_l is not the cause. Not adopted in this phase: using TN 1546's c_d level as an input is an author decision (it would be calibrating an input to independent section data, not to Report 996), recorded as open item 73e.
- [x] 73e **Decision (2026-10-28, under the author's full authority, decided from the documents):** whether to use TN 1546's measured c_d level (k = 1.33 on the XFOIL c_d, or the measured c_d directly where it exists) as the Report 996 polar input. If adopted, the rule must be fixed before the rerun and every Report 996 result re-recorded post-hoc. **Decided 2026-10-28: not adopted.** The factor k = 1.33 was considered only after 73c2 showed its effect on the Report 996 torque, so any improvement it gives there would be post-hoc and could not count as a pass (CLAUDE.md rule); production keeps XFOIL N_crit 8 c_d. The Report 996 torque misses stay class A (section drag), with the 73c2 bound as the quantified share. A later phase may adopt measured section drag only with a rule fixed before any Report 996 comparison is rerun, all results labelled post-hoc.
- [x] 73d Records and five documents (no case record changes: 73c and 73c2 are bounds). **Done 2026-10-28.**

## 8x. Phase 80 — MRP validation plan: verify the structural solver with inputs that are known *(done 2026-10-29 except optional 80g; moved to the bottom 2026-10-29; author: "we need to make a new validation plan for mrp"; criteria below dated 2026-10-29, before any of these checks is written or run)*

**Why.** The structural block's two solver-facing cases compare with NASA's printed output, whose inputs are not all documented:
- `MRP_APPD` compares `mrp_appd.jl` with Table D-1. App. D says only "classical plate theory" for the floor, so NASA's floor-beam and floor-support model is unknown (§2.14 class I). A miss cannot separate a code defect from different inputs, so this case cannot show that the solver works. CR-172428 App. B (`appB_structural_modes.csv`) is the same NASA run (identical frequencies), not a second reference.
- `MRP_SHAPE_NORM` checks the printed Table D-1 shapes (the production input for the test article), not the solver; its 19/32 is the print's truncation (5 shell + 3 plate terms).
- What is verified today (`test_mrp_appd.jl`) is each part alone: the bare shell (Donnell–Mushtari), the floor plate alone, the floor membrane block, stiffener section inertias, the junction rows, orthogonality. **The coupled shell + floor + junction solve has no independent check.**
- For any fuselage other than the test article, the parametric path uses this solver (`structural_solver = "appd"`, inputs `cabin.*` in the aircraft JSON, `build_appd_geometry`), so it is production for new aircraft.

**Principle.** Every new check gives the solver and its reference the **same, fully stated inputs**: a closed form, a limiting case, or an independent implementation of the same model. Agreement then verifies the code; disagreement is a code defect. No input is chosen from Table D-1 or any measured result. Whether the App. D *model* (smeared stiffeners, simply supported ends, flat floor, one material) fits a real fuselage is a separate question, answered only by measured modes (80g).

**Role of the existing cases (decided 2026-10-29).** `MRP_APPD` stays registered with its criterion and verdict, relabelled as a **reproduction of NASA's printed run** (inputs partly undocumented), not as the solver's verification. `MRP_SHAPE_NORM` stays as the **input check of the printed table**. The solver's verification moves to the new cases below, on the `P_MRP` and `X_MRP_OUT` blocks, each with its own figure.

**Steps (criteria fixed 2026-10-29, before any run; V-CODE unless stated).**
- [x] 80a **Coupled limiting cases** (new case `MRP_COUPLED_LIMITS`, `P_MRP`). (1) *Vanishing floor:* t_floor, A_floor_beam and I_floor_beam scaled by 1e-4 (test article otherwise). Shell-dominated modes (shell share of qᵀMq ≥ 0.99) against the stiffened shell alone with no floor (same smeared properties, same basis): **each of the 10 lowest shell-dominated modes per (M, parity), M = 1–3, within 1 %**. (2) *Rigid shell:* a test-only stiffness factor on the shell (×1e4, mass unchanged). Floor-dominated modes against the closed form of a plate simply supported at x = 0, L and clamped on both long edges (the rigid junction (D.4) with a fixed shell), orthotropic Dx, Dy, H from `_appd_floor_props`, solved by an independent transcendental root finder (Leissa SS-C-SS-C): **the 6 lowest floor modes per M, M = 1–3, within 2 %**. A test-only factor is the only code change; production values are untouched. **Done 2026-10-29 (`MRP_COUPLED_LIMITS`, `src/validation_case_iso80.jl`).** The first run found a defect: the floor stiffness and mass were assembled diagonal per spanwise term although cos(pπy/Lp) and sin(pπy/Lp) of different parity are not orthogonal on the floor width (cross term ∫cos0·cos(πy/Lp) = 2Lp/π); in the near-rigid-shell limit the second and third floor modes came out 50–78 % below the exact plate. The cross terms were added (`_appd_floor_block_KM`, Gauss–Legendre). Then 80c's deck finding (below) showed that NASA's program has the same diagonal form, and that Table D-1 is reproduced only with it, so production keeps NASA's form (`floor_cross_terms=false`, author 2026-10-29: the same function as PAIN) and the cross terms are an option. **Recorded: not met, 66/78** on NASA's deck and NASA's form: vanishing floor 60/60 (max 0.07 %), near-rigid shell 6/18 (class M, PAIN's method); with the cross terms (information) within 2 % except the third antisymmetric floor mode, +3.3 % (5-term floor series). Post-hoc amendment 2026-10-29: a test-only floor-mass factor in the vanishing-floor limit, added after the first run (the scaled floor's own mode at 909 Hz split a shell mode at 896 Hz).
- [x] 80b **Consistency of the coupled solve** (unit tests, `test_mrp_appd.jl`). (1) For every returned mode, the Rayleigh quotient qᵀKq / qᵀMq of its own coefficient vector equals (2πf)² within 1e-8 relative. (2) Ritz convergence: frequencies never rise when n_circ goes 8 → 12 → 16 or n_floor_max 5 → 8 → 11 (tolerance 1e-9 relative), and the 32 lowest change by ≤ 0.5 % from the middle to the largest basis. (3) Kinetic and strain energy of each mode split into shell and floor parts sum to the totals within 1e-10. **Done 2026-10-29** (`test_mrp_appd.jl`): Rayleigh quotient within 1e-8, frequencies never rise on nested bases, energy split sums to 1, all pass. The ≤ 0.5 % criterion is **not met** for the shell series: the floor joint puts a kink in the shell, which a Fourier series resolves slowly; against ns 0–64 the 32 lowest are up to 5.0 % off at ns 8, 3.1 % at 12 (NASA's deck), 0.7 % at 32, 0.23 % at 48. The floor series is converged by np 8 and numerically singular beyond (floor mass matrix cond 1.3e13 at np 9, 3e16 at 11): `_appd_basis` now refuses np > 8, which is also PAIN's own limit (User Manual card 8). Production keeps NASA's deck limits (M 1–10, ns 0–12, np 0–5; were 6, 8, 5), so its shell truncation (≤ 3.1 %) is PAIN's, by the author's target.
- [x] 80c **Independent solver of the same model** (new `src/mrp_fsm.jl` + case `MRP_FSM`, `P_MRP`). A finite-strip model: for each axial half-wave M, the circumference is meshed with curved Donnell shell strips and the floor with Kirchhoff plate strips (u, v, w, ∂w/∂s per node; cubic w, linear u and v), joined rigidly at the junction nodes by the (D.4) transformation, with the same smeared constitutive scalars (`_appd_shell_props`, `_appd_floor_props`, verified separately) and simply supported ends. It shares no basis, assembly or constraint code with `mrp_appd.jl`. Mesh convergence first: **the 32 lowest frequencies change by ≤ 0.3 % from the middle to the finest mesh**. Then, on the test article and on the 2.64 m working example (`aircraft_scale_hartzell_cabin_full.json`): modes paired by shape (MAC ≥ 0.9 on w over shell and floor); **criterion: every one of the 32 lowest App. D modes has an FSM partner and each pair is within 2 %**. Not met → defect hunt in whichever code the closed forms of 80a/80b implicate; no input changes. **Not built (decided 2026-10-29).** While checking which series limits PAIN uses, the User Manual turned out to print NASA's MRP input deck for this test article (pp. 42–43: smeared shell and floor properties, stiffener D′, L = 1.8034 m, series limits). On it, the solver reproduces Table D-1: 32/32 frequencies within 0.012 %, shapes in Table D-1's own order, generalized masses median 0.11 % (`MRP_APPD` met). That is a direct code-on-code check of the coupled solve against NASA's program on NASA's inputs, stronger for the author's target (the same function as PAIN) than an independent solver of the exact Ritz energy, which production does not use. Two solver readings were fixed by it: M_r is the full integral of the shape (Table D-1's TOTAL MASS), and the shape is normalized over the whole shell and the floor (mode 14 peaks below the floor). New input type `AppDDeck` / `appd_nasa_deck()`, data `data/cr3813/um_mrp_input_deck.csv`.
- [x] 80d **Shape normalization of the solver's own shapes** (new case `MRP_TRUNC`, `X_MRP_OUT`). (1) The solver's full shapes have unit maximum normal displacement over shell and floor: **all 32 within 1e-6**. (2) Diagnostic of the printed table, no verdict: truncate each solver shape to its 5 largest shell and 3 largest plate terms (as Table D-1 prints) and record the peak. The class I reading of `MRP_SHAPE_NORM` is **supported** if the truncated peaks exceed 1 in at least a third of the modes and the largest lies between 1.05 and 1.5 (range fixed now, before the run). **Done 2026-10-29 (`MRP_TRUNC`): met, 32/32** full shapes at unit maximum (largest deviation 1.9e-8, dense-grid check independent of the solver). Diagnostic: cut to 5 + 3 terms, 16/32 exceed 1, largest 1.228 (printed 1.254): the truncation reading of `MRP_SHAPE_NORM` is **supported**; the cut shapes match the printed peaks mode by mode within about 0.02.
- [x] 80e **Input guards for a new fuselage** (unit tests, `aircraft_provenance.jl` / `mrp_appd.jl`). Warn (never alter the input) when: a / t_skin < 20 (thin shell); a frame or stringer spacing exceeds a quarter of the shortest wavelength of a returned mode (smearing assumption; reported per mode); θ0 outside 0°–90°, where the floor and junction are defined; any App. D input missing and filled from the test article (already in provenance; keep). Tests: each guard fires at its threshold and stays silent just inside it. **Done 2026-10-29.** `appd_input_warnings` (a / t < 20; θ0 outside 0°–90°; for stiffener sections, frame or stringer spacing above a quarter of a mode's wavelength, counted over the modes), issued by `build_structural_modes` for the App. D solver; inputs never altered. A new fuselage may also give PAIN's own card values (`APPD_DECK_SPECS`: `t_shell_card_m`, `m_shell_kg_m2`, `Dp_stringers_Nm`, `Dp_frames_Nm`, `t_floor_card_m`, `m_floor_kg_m2`, `Dp_floor_beams_Nm`, `Dp_floor_supports_Nm`, with `E_Pa`, `nu`): all eight select `AppDDeck` (NASA's series limits), a partial set is an error. On the test article the stiffener-section inputs warn for the frames (0.2 m against M ≥ 5 wavelengths). Tests in `test_mrp_appd.jl`.
- [x] 80f **Sensitivity for a new fuselage** (report only, no verdict; `docs/validation_reports/phase80_mrp_sensitivity.md`). Each of the 16 App. D inputs varied ±20 % one at a time on the 2.64 m example: change of the 32 lowest frequencies and of the H1–H3 interior levels of the parametric path. Lists which inputs a user must supply carefully. **Done 2026-10-29** (`scripts/run/phase80_mrp_sensitivity.jl`, `docs/validation_reports/phase80_mrp_sensitivity.md`; report only). On the 2.64 m example, ±20 % moves the structural frequencies most through floor thickness, frame spacing, floor-beam inertia, E and density (7–12 %), and the interior H1–H3 by about ±1–3 dB for the structural inputs (more for a, L, θ0, which also move the acoustic modes and the grid). **Finding:** θ0 × 0.8 (45.3°) stops in CYL2D: at NY = 10 the App. C grid gives complex eigenvalues among the kept modes (79b guard). The NY = 10 production grid kept on 2026-10-28 therefore does not serve every floor angle a new fuselage may have; recorded as an open item (Q60), no change made here.
- [ ] 80g **Optional, not required (author 2026-10-29: "as long as its the same functionaly as pain since its a low fidelity solver then its fine").** The target is functional equivalence with PAIN's App. D method (80a–80d), not fidelity to a real fuselage; NASA did not validate Table D-1 against a modal survey either. Kept for the record: **Model validation against measured modes** (V-EXP; source search). Search NTRS and the literature for a measured modal survey of a stiffened cylinder with an interior floor whose structure is fully documented (candidates to check: Peterson and Boyd's journal paper on cylinders with longitudinal interior partitions, J. Sound Vib., about 1978; NASA Langley fuselage-model modal tests). Downloads only with the author's approval. If found: digitize, then fix the criterion before any run (§2.12). If none: the claim for new fuselages stays V-CODE (the code solves the App. D model) plus X-EXTRAP (the model itself is not validated), stated in METHODOLOGY.
- [x] 80h Records and the five documents: relabel `MRP_APPD` and `MRP_SHAPE_NORM` as above; new case records in §2.13; claim text for the structural block in METHODOLOGY; targeted testsets (mrp_appd, validation map, registry), GUI smoke scripts; commit. **Done 2026-10-29**: records (`MRP_APPD` met 32/32 on NASA's deck; `MRP_COUPLED_LIMITS`, `MRP_TRUNC` new; `MRP_SHAPE_NORM` explanation quantified; §2.14 rows), the five documents, figures redrawn (`regenerate_case_figures.jl`), solver-dependent cases re-recorded post-hoc (`UNC_COVER`, `AC_CABIN_DEMO`: verdicts unchanged), unit tests (mrp_appd 251, provenance 51, completeness) and the named main testsets.

**Order and stop points.** 80b → 80a → 80c → 80d → 80e → 80f → 80h; 80g optional (not required, author 2026-10-29). Stop and report if 80a or 80b finds a defect, before 80c is built on it. A defect fixed here is a code-on-code fix; `MRP_APPD` is rerun afterwards and any change to it is labelled post-hoc.

## 8y. Phase 81 — PAIN main block (P_EQ8, X_OUT): the cases that do not show what they claim *(done 2026-10-29; moved to the bottom 2026-10-29; planned 2026-10-29; author: "find solutions for iso modal density, sharp panel d, loudest pt, pretty much the pain main validation block … create a solution then put them into phases then execute"; criteria below dated 2026-10-29, before any of these checks is written or run)*

**Audit (2026-10-29, live runs of every case on P_EQ8 and X_OUT).**
- `ISO_MODAL_DENSITY` met 12/12, but in the 250 Hz and 397 Hz bands the true band joint acceptance is below the code's 1e-6 floor and the reference applies the same floor: 2 of the 12 rows pass by construction (CLAUDE.md rule).
- `HF_MASSLAW` met 3/3, but its "info:" row (the normal-incidence mass law, which the function deliberately does not use, 250 % apart) is not recognised as information, so the map chip shows "max |err| 250 %" beside the pass.
- `SHARP_PANEL_D` not met 3/13: the construction is about 1 dB under CR-172490 Fig. 15 below 250 Hz and about 1.2 dB over it above. The text gives ΔTL_M "on the order of 12 dB"; Eq. (25) with Panel D's point-connector lattice (Fig. A-7: spacers on support blocks at the longeron/frame crossings, longeron pitch 190 mm) gives 20 log(0.19 · 7949) − 51 = 12.6 dB, consistent with the text, while the figure's curve sits 10.2 dB over its own mass line. No documented input reproduces the figure; taking 10.2 dB from it would be calibration.
- `LOUDEST_PT` not met 2/5: check (a) averages over interior nodes only, while the rigid-wall modes have antinodes on the wall and floor nodes; the all-node Eq. (C.10)-weighted average is within 1.1 % (post-hoc, NY = 10), the residual being the discrete orthogonality of the NY = 10 eigenvectors.
- `PAIN_INPUT_ECHO`, `ISO_BB_BAND`, `NR_BAND_HAND`, `ISO_SIL` met and sound; `UT_EQ8` is a Pkg.test entry (no figure).

**Steps (criteria fixed 2026-10-29, before any run).**
- [x] 81a `HF_MASSLAW`: label the normal-incidence row "(info)" so `case_error_summary` leaves it out of the chip; criterion and verdict unchanged (display fix). **Done 2026-10-29.**
- [x] 81b `ISO_MODAL_DENSITY`: in each band the test pressure is the sum of the shapes of the Table D-1 modes in that band (unit weights), so every band's ⟨j²⟩ lies above the 1e-6 floor; the criterion (≤ 1e-6 relative against the independent discrete average) is unchanged and a row whose raw value is below the floor counts as **not met** (no comparison of two clamped values). Re-recorded post-hoc (the earlier result was known). Unit test: `band_joint_acceptance` returns the 1e-6 floor when the raw mean is below it. **Done 2026-10-29:** as pre-registered, 10/12 (the 250 and 397 Hz bands hold floor-dominated modes with shell coefficients ~0.01, so 1 + ψ barely projects on them and the raw value stays under the floor; those rows now count as not met). Amended the same day, post-hoc: a pressure matched to the band (amplitude |Σψ|, phase 0 or π): **met, 12/12**, every band ⟨j²⟩ 2.9e-5–0.07, max residual 1e-15. Unit test of the floor in `test_pain_core.jl`.
- [x] 81c `SHARP_PANEL_D`: (1) closure class **N** (the source's figure and its stated inputs disagree; evidence above), criterion and verdict unchanged. (2) New case `SHARP_PANEL_D_SHAPE` (block P_EQ8): what the construction itself fixes, independent of the rounded ΔTL_M and of the mass offset: the slope of the digitized Fig. 15 curve within ±1.5 dB/octave of the construction's 6 dB/octave below f₀ (63–125 Hz), 18 dB/octave on the rise (160–250 Hz) and 6 dB/octave above f_b (500–1000 Hz), each slope a least-squares fit over the band-centre points of its range. V-UNIT against the source figure. **Done 2026-10-29:** SHARP_PANEL_D reclassed N (evidence in §2.13 and §2.14); `SHARP_PANEL_D_SHAPE` **met, 3/3** (figure 5.9, 17.9, 5.8; construction 6.0, 18.0, 6.0 dB/octave).
- [x] 81d `LOUDEST_PT`: check (a) keeps its recorded verdict (class D, test design). New case `LOUDEST_PT_GRID` (block X_OUT): the same test article on the converged CYL2D grid NY = 40 (79b); **criterion: the all-node Eq. (C.10)-weighted volume average within 1 % of Eq. (8) for H1–H3**; the interior-node ratio at NY = 40 is information. **Done 2026-10-29:** `LOUDEST_PT_GRID` **met, 3/3** (all-node 1.0004, 1.0001, 0.9993; interior nodes, information, 0.982, 0.976, 0.965). LOUDEST_PT (a) stays not met, class D.
- [x] 81e Five documents, figures, CSV rows, targeted tests (unit, validation map, registry), commit. **Done 2026-10-29.** Found on the way: information rows were drawn green ("within criterion") in error panels although they have no tolerance (LOUDEST_PT_GRID's interior-node rows lay outside the band in green); now grey (`_error_point_color`) and the figures with information rows redrawn. `regenerate_case_figures.jl` now re-reads the case records (`reload_validation_docs!`), since the precompiled copy put new cases' figures in the figures root.

## 8z. Phase 82 — Meaningfulness audit of the not-met cases *(done 2026-10-29; moved to the bottom 2026-10-29; planned 2026-10-29; author: "audit over the not met test cases ... to see if the case is meaningful"; rule and criteria below dated 2026-10-29, before any rerun)*

**Rule (author 2026-10-29; also in `CLAUDE.md`).** A validation case is meaningful, and may carry a met / not-met verdict, only if it
(E) compares with experimental data, or (P) checks that the code works exactly like PAIN: given PAIN's own inputs (from PAIN's
sources: CR-3813, the User Manual, CR-172428 and the reports they cite for their data) or experimental inputs, it reproduces what
PAIN printed. A check against anything else (an analytic limit, a law such as Weyl's, a different method or report, or a property
of a printed table) is verification: it stays as an information case (no verdict) or a unit test, never a map verdict.

**Audit (2026-10-29, the 43 not-met cases of the §0 snapshot).** E: compares with measurement. P: reproduces PAIN's printed output.
X: neither (not meaningful under the rule).

| Class | Cases |
|---|---|
| E (26) | E22_BR, R996_PHASE, T2, T2_EQ19, T2_MEAS_EXT, T2_MEAS_EXT_BR, T2_PRED_BB, UNC_COVER, E21_E22_NR, NR_PROP_TP2444, NR_PROP_TP2444_BR, NR_PROP_TP2444_PF, T1_MEAS_DAMPING, PROP_BB_FIG17, PROP_BB_FIG14, NR_TP1964, R172428_EXP, T1, T1_FROM_E12, NR_TP1964_XOVER, POLAR_FIDELITY, PER_FIG8, PER_FIG9, R996_LOADS, BBN_CIRC, E12_BLOCK |
| P (10) | REPRO_18b, E21_PRE, E22_HF_CODE, E18_TONES, REPRO_18b_PRE, R172428_CODE, R172428_ETA, E14_LOSS (NASA's calculated Eq. (78) curve), NR_TP1964_REF2, NR_TP1964_XOVER_REF2 (NASA's prediction with the CR-159363 equations PAIN adopts) |
| X (7) | LOUDEST_PT (point form vs Eq. (8): internal consistency), BLK_GAIN_MAP (a gain-range property), MRP_SHAPE_NORM (a property of NASA's printed table), CYL2D_WEYL (Weyl's law), MRP_COUPLED_LIMITS (analytic limits; it misses because PAIN's floor form is not the exact Ritz energy), F1A_GUTIN_ANGLES (Gutin's formula), SHARP_PANEL_D (CR-172490's design figure, not PAIN and not measured) |

Every E and P case keeps its verdict and its §2.14 closure class; the one with an untested input fix is 82c.

- [x] 82a Rule into `CLAUDE.md`; this audit as `VALIDATION_GUIDELINE.md` §2.15; §2.14 rows point to it.
- [x] 82b The 7 X cases carry no verdict (information), with the dated label "not a validation case under the 2026-10-29 rule; result unchanged, not a pass". Tables, figures (redrawn without a criterion band) and records kept; `case_error_summary.csv` and §0 regenerated. No criterion changes, and no case becomes met.
- [x] 82c **NASA's full structural modes in the CR-172428 reproduction (P).** R172428_ETA's cause is classed I (probable): modes 13–32 use Table D-1 shapes, which NASA printed truncated to five shell terms; NASA's program used its full MRP modes. Since Phase 80 the App. D solver on NASA's MRP deck reproduces Table D-1 (32/32) with the full series, so it supplies the modes NASA used. New cases `R172428_ETA_DECK`, `R172428_CODE_DECK`, `R172428_EXP_DECK`: identical to R172428_ETA / _CODE / _EXP except the structural modes come from `appd_modes(appd_nasa_deck())` (NASA's deck, the deck's series, no other change). **Criteria (fixed 2026-10-29, before the run, copied unchanged):** ETA_DECK: η_r′ of each of the 32 modes within ±25 % of App. B p. 194, met if 32/32; CODE_DECK: ±3 dB of NASA's printed prediction at ≥ 7 of 9 points; EXP_DECK: ±4 dB of the measured space average at each of 9 points. The originals stay as recorded. Whatever the outcome, it is reported as is; no input is changed after the run.
- [x] 82d Five documents, §0, targeted tests, review, commit.

**Result (2026-10-29).** 82a: rule in `CLAUDE.md`, audit in `VALIDATION_GUIDELINE.md` §2.15. 82b: the 7 X cases are information cases (`INFORMATION_ONLY_CASES` in `validation_cases.jl`; `run_validation_case` returns no verdict and keeps `original_verdict`); their records say so, figures redrawn without a criterion band, snapshot and §0 regenerated. 82c: run once as pre-registered: R172428_ETA with the deck modes 17/32 (same as Table D-1), CODE 4/9, EXP 3/9, levels within 1 dB of the Table D-1 run, so the truncated shapes are not the cause. Follow-up diagnostics (after the result, information only): the generalized masses (total, shell) match App. B within 1 %, the trim admittance App. B p. 197 within 2 % to 1 kHz, ETASTR lines 47/50 (App. A p. 178) are what the code does, and adding Σ η_r″ overshoots modes 1–12 by up to 100×; NASA's printed loss factor of the trim-damped modes above 500 Hz stays 1.3–2× this code's, so R172428_ETA is re-classed N. The three _DECK variants were not registered as map cases (they duplicate the originals within 1 dB); `r172428_inputs(rpm; structural=:deck)` keeps the option, with a unit test.

## 8aa. Phase 83 — the not-met cases with the fewest points: audit, solutions, runs *(done 2026-10-29; moved to the bottom 2026-10-29; planned 2026-10-29; author: "i wanted the not met fewest criterions auditted and planned phases first and solutions to those"; criteria below dated 2026-10-29, before any of these runs)*

**Scope.** The nine cases at 0 points in `VALIDATION_GUIDELINE.md` §0 ("Not met, fewest points first"), audited for a cause the
documents still allow testing. Each untested cause gets a phase item with its criterion fixed here; a case with none is
re-stated with its evidence, and no verdict changes without a run.

**83a Audit (2026-10-29, from the recorded runs; no new comparison).**

| Case | Class | Untested cause the documents allow? | Solution |
|---|---|---|---|
| T2_EQ19, T2_MEAS_EXT, T2_MEAS_EXT_BR, T2_PRED_BB, E22_BR | E (M) | **Yes.** Eqs. (19)–(23) run on Table D-1's 32 modes, the highest at 811 Hz, so every band 1250–2500 Hz has no resonant mode and takes the asymptotic branch, and τ_f sums the 31 modes below 811 Hz only. NASA ran PAIN with MRP's mode set: 300 structural modes for this article (CR-172428 Table 6). The App. D solver reproduces Table D-1 32/32 on NASA's MRP deck (Phase 80) and gives 300 modes to 3.7 kHz (71 below 1250 Hz, 230 below 2500 Hz) | 83b, 83c |
| T2 | not meaningful | its broadband path uses `bb_j2_scale`, fitted to Fig. E-9 (METHODOLOGY T2 row: "in-sample: `bb_j2_scale` was fitted"), and is compared with Fig. E-9: a calibrated path against its own data (`CLAUDE.md`) | 83d: information; T2_EQ19 is the printed-method T2 |
| REPRO_18b | P (N) | No for the program form: REPRO_18b_PRE already reverts all three CR-172428 App. A changes (floor sign −1, R1 blocking, η_r′ of Eq. (82) on the untrimmed mass) and gets 1/3. The mode set is the one input left | 83e (secondary) |
| UNC_COVER | E (re-stated) | The GEXT attribution (§2.14) is superseded in part: with NASA's printed App. B field and no GEXT, R172428_EXP at 4000 rpm gives H3 71.7 dB against NASA's own 71.3 dB (Table 10) and the measured 65.2 dB. The code reproduces NASA at H3 within 0.4 dB; the H3 excess over the measurement is PAIN's (class M), not the extension | none; re-stated |
| R996_PHASE | E (A) | No. F1A 112.8° against the measured 155°; Report 996's own Eq. (2) gives 165°. F1A_INDEP rules out the wiring (0.02°) and Phase 73 the section polars; no documented input is left | none |

| Item | What | Criterion (fixed 2026-10-29, before any run) |
|---|---|---|
| 83a | Audit above, written into `VALIDATION_GUIDELINE.md` §2.16 | — |
| 83b | `E22_HF_DECK` (P): `E22_HF_CODE`'s inputs and options (Phase III trim η_T = 1.0, η_r′ ≤ 0.15) with the structural modes from the App. D solver on NASA's MRP deck, 300 modes (CR-172428 Table 6; the count is NASA's, not chosen from a result) | as E22_HF_CODE: \|code − NASA E-22 prediction\| ≤ 3 dB in ≥ 75 % of the bands 1250–2500 Hz |
| 83c | `T2_EQ19_DECK` (E): T2_EQ19 with the same 300 deck modes, everything else as T2_EQ19 | as T2_EQ19 (its recorded criterion, unchanged) |
| 83d | T2 becomes an information case (`INFORMATION_ONLY_CASES`; reason: calibrated to the data it is compared with) | — |
| 83e | `REPRO_18b_DECK` (P, secondary): REPRO_18b with the 300 deck modes | as REPRO_18b: \|Δ\| ≤ 4 dB at H1–H3 against E-16's NASA prediction |
| 83f | Five documents, §0 regenerated, targeted tests, review, commit | — |

**Outcomes fixed before the runs.** If 83b is met, the T2-family class M statement (code within 2–8 dB of NASA) is replaced by
"the code reproduces NASA's high-frequency prediction with NASA's mode set", and the 300-mode set becomes the input of the
high-frequency cases (the Table D-1 runs kept as recorded). If 83b is not met, the 32-mode cause is refuted and recorded; no
other mode count is tried. 83c and 83e are recorded whatever they give; no input is changed after seeing them.

**Result (2026-10-29, first runs, criteria as fixed above).** 83b `E22_HF_DECK` **not met, 0/4**: NR 46.3, 45.8, 50.8, 50.5 dB against NASA's 52.0, 59.5, 69.0, 69.0 (Table D-1: 59.7, 61.6, 62.5, 63.4); 42, 68, 39, 40 modes resonant per band. The 32-mode cause is refuted; Table D-1 stays the input of the high-frequency cases and no other count was tried. 83c `T2_EQ19_DECK` **not met, 0/3**: 54.9, 54.2, 49.0 dB against E-9's 51.0, 46.0, 41.5 (Table D-1: 38.9, 35.9, 34.9). 83d: T2 is an information case. 83e `REPRO_18b_DECK` **not met, 0/3**: 88.15, 80.58, 78.33 dB (Table D-1: 88.20, 80.43, 78.21). New: `nasa_deck_modes`, `NASA_MRP_N_MODES`, `noise_reduction_test_article_inputs(; structural_set=:deck)`, `validation_case_iso83.jl`; report `validation_reports/phase83_deck_modes.md`; audit `VALIDATION_GUIDELINE.md` §2.16.
