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
6. Source phases 21–28
7. Aircraft-cabin phases 29–31
8. Phases 32–35 *(done 2026-10-21; records in §11)*; Phase 36 cabin mode animation *(done 2026-10-22)*; Phase 37 root-cause fixes *(done 2026-10-22; §11)*; Phase 38 CR-3813 / User Manual completeness *(38a–38e done 2026-10-22; 38f–38h to plan with the author)*
9. Reference appendices (BBN evidence, Report 996 figures and data, Pereira polar specification, variables)
10. Optional future work, key formulas, file checklist
11. Completed phases 0–22 + digitization/setup close-out + phases 32–35 (2026-10-21)

---

## 0. Agent hand-off brief

### 0.1 The project in five lines

- Julia recreation of NASA PAIN (Propeller Aircraft Interior Noise, CR-3813) in `PAIN.jl`.
- Pipeline: free-field pressure on a 160-point fuselage grid → blocking Eq. (43) → cabin acoustic modes (CYL2D, App. C) and structural modes (MRP, Table D-1) → PAIN core (coupling Eq. 52, generalized force Eq. 42, trim App. A, loss factors §3.8, tone pressure Eq. 8) → interior SPL → dB(A)/SIL.
- Two free-field sources: `:e11` (NASA's measured Fig. E-11 line plus GEXT; a validation test only, never a user option) and `:aircraft` (CCBlade BEMT → AcousticAnalogies F1A; the only user source; X-EXTRAP).
- Phases 0–20 and step 19i are done: the cabin chain follows CR-3813 without tuning, with η_T = 0.5 for the NASA test article; H3 omitted-term probe **not found** (`h3_followup.md`). Remaining: the aircraft-source rework and its checks against BBN/Wilby, NACA Report 996 and Pereira (21–28); aircraft cabin inputs and uncertainty (29–31); the GEXT importance bound (32); close-out (33).
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
| 24 | BBN/Wilby phase check | **24b PASS**; **24c–e re-run 2026-10-21** (`bbn_phase.md`): 23a **FAIL** 26/168 (15%); tip assumed (24f); I-09 sense fixed |
| 25 | NACA Report 996 verification setup | **Done** except **25g** (criteria live in §2.12/23c); I-07 re-ran `report996_setup.md` (behind>ahead **false** after I-01/I-02) |
| 26 | CCBlade check vs Report 996 | **Numbers recorded** (`report996_loads.md`); labelled "criteria registered after the loads were computed" (I-06) |
| 27 | AcousticAnalogies check vs Report 996 | **I-07 + I-08 re-run 2026-10-21** (`report996_acoustics.md`): Fig.13a `scaled_RM_L51C27`; 23c scaled ±2 dB **FAIL** (5/24); page-12 phase **FAIL** (103.8° vs 155°) |
| 28 | Forward-flight check vs Pereira et al. (2026) | **I-07 re-run 2026-10-21** (`pereira_forward_flight.md`): loads OK (xtr005 s_T≈1.34); 23d H1 **FAIL** 0/9 (±1.7 dB); H2 6/9 (±3 dB); I-10 chord note recorded |
| 29 | Aircraft cabin inputs: audit, guard, provenance, required inputs | **29a + 29d done**; 29b/29c deferred (no aircraft predictions, 2026-10-21) |
| 30 | Parametric cabin blocks for the aircraft | **Deferred 2026-10-21: no aircraft predictions** (author); 30d test-article regression optional |
| 31 | Uncertainty plan for the aircraft cabin result | **Deferred 2026-10-21: no aircraft predictions** (author); 31e test-article coverage check optional (E-21/E-22 present) |
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
| **I-17** | **Free-field amplitude convention (rms vs Fourier peak) — open, author decision (theory audit 2026-10-21).** `spl_dB_to_Pa` (`freefield_digitized.jl`) converts E-11 / ANOPP Table 8 SPL to Pa as an rms-equivalent amplitude and that value enters Eq. (42) as A (Δ⁴/2 assumes a cosine peak; User Manual card 38 "amplitude of Fourier component (Pa)"). F1A stores the peak (A = √2 p_rms). Documentary evidence: CR-3813 Eqs. (28)–(31) A_H = √(a_H²+b_H²), mean square A²/2 → cosine peak; CR-172428 p. 41 ⟨p²⟩ = p₀² 10^(SPL/10) → SPL is rms-referenced; CR-172428 §3 predictions are Fourier representations "as required for PAIN input". Hence A = √2 p₀ 10^(SPL/20); the code omits √2 → e11/Table-8 tones ~3.01 dB low (T1, T2 tonal part, REPRO_18b, E12 levels, GEXT_BOUND). F1A path already peak. | Affected e11/Table-8 tone SPLs ~3 dB low; fixing would give REPRO_18b ≈ +6.7, +3.2, +12.1 dB (result known → any change is post-hoc) | **Decided 2026-10-21 (author): fix, on documentary grounds** (author: "not tuning" means not adjusting toward experimental data; a documented convention fix is allowed). The same error was found in three comparisons against rms measurements: NACA Report 996 p. 10 "Pressure amplitudes (rms) of the first four harmonics were measured with a harmonic wave analyzer" (Figs. 12, 13a, 14 compared F1A's peak A with rms data, +3.01 dB bias); Pereira et al. 2026 p. 13 "The root-mean-square of the pressure fluctuations yields a tonal noise emission of 84.6 dB" (= Table 4; `run_pereira.jl` converted the peak A to SPL); `run_f1a_smoke.jl`. Fix in phase 37 step 37b; every affected result is re-recorded and labelled post-hoc |
| **I-18** | **Lower-quarter grid (mirroring) — reopened 2026-10-21 (completeness audit).** Decision 19d (use the 160 upper-quarter points only) read the User Manual and CR-3813 §3.4 and left Manual output item 7 ("both above and below θ = 0") unresolved. It did not cite CR-172428 §3: "PAIN then generates data for an identical grid on the lower quarter surface of the fuselage nearest the propeller (using the data input for the upper grid)". The 19d diagnostic, mirroring about the ℓ = 1 line, moved 18b by +0.73, +3.18, +6.81 dB | Changes Ψ_G at every harmonic; known direction → post-hoc if adopted | **[AUTHOR] decision rule, dated 2026-10-21 before phase 38b runs:** keep the 160 points for now (noted). Adopt mirroring about the ℓ = 1 line **only if** the high-frequency tone formulation (phase 38b) "explains H3", defined now as: with the 38b crossover rule (fixed before the run), the REPRO_18b H3 value is within the 18b criterion (≤ 4 dB of NASA's 68.0 dB) where the Eq. (8) value is not. If adopted, all affected results are re-recorded and labelled post-hoc |
| **I-19** | **BBN circumferential phase sign (23a, 26/168).** F1A's phase difference matches the rigid-rotation value m·B·Δψ in magnitude, and the measured CR-158919 App. C phases have the opposite sign at most rows (`bbn_phase.md` finding). CR-158919 App. C p. C-1 says only that the phase was read from the SD360 analyzer in −π…π; it does not say which microphone of a pair is the reference. Rotation sense and geometry were checked: blades move upward at the fuselage as recorded (I-09) | 23a stays FAIL | Not fixable from the source; choosing the sign that fits would be tuning against experiment. Recorded; a sign-free magnitude comparison may be shown only as a labelled post-hoc diagnostic, never as a pass |
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
| Q0 | **Review issues I-01 to I-16 (§3.0)**, in the order given there | mixed: data quarantine, `src/` fix [CONFIRM], redo digitizations, criteria [AUTHOR], re-runs | none | §3.0 items closed and dated |
| Q1 | Run step 19i (§5) | script run, no `src/` change | none | **Done 2026-10-21** `h3_followup.md`; 19i in §11 |
| Q2 | **Docs sync for the η_T = 0.5 decision** (left over from phase 20): `METHODOLOGY.md` §6 T1/T2 numbers and the 18b text → 18a-r / 18b-r of `phase20_baseline.md`; claim register; `VALIDATION_GUIDELINE.md` §2.7/§2.8/register f; `README.md`; `flowchart.md` | docs only | Q1 | **Done 2026-10-21** (same pass as 19i) |
| Q3 | Phase 21 | `src/` change [CONFIRM] waived by author “keep going”; **done 2026-10-21** | Q2 | shared function, tests, `gext_vs_f1a_grid.md` |
| Q4 | Phase 22 | docs | Q3 | **Done 2026-10-21** |
| Q5 | Phase 23 | pre-registration [AUTHOR] | Q4 (draft may precede) | **§2.12 frozen 2026-10-21** (I-06) |
| Q6 | Phase 24 | scripts + tests | Q5, D-21 (C-06 **done**), phase 21 | `bbn_phase.md` |
| Q7 | Phase 25 | setup, 25h/25i [CONFIRM] | Q5, D-07 | **Done except 25g**; `report996_setup.md` (25k) |
| Q8 | Phase 26 | script | Q7 | **Numbers done**; `report996_loads.md` (no 23c verdict) |
| Q9 | Phase 27 | script | Q8 | **Expanded matrix done**; verdict waits 23c |
| Q10 | Phase 28 | script | Q5, Q7 (polar loader), D-11–D-13 (C-01–C-04 **done**) | **Expanded**; ScaledLoads path; 23d verdict |
| Q11 | Phase 29 (29a any time; 29b, 29c [CONFIRM]) | docs + `src/` | Q3 | register rows, guard, tags |
| Q12 | Phase 30 | `src/` [CONFIRM] | Q11, D-20 | parametric blocks, 30d shift |
| Q13 | Phase 31 | design [AUTHOR], runs | Q12, D-16 | band, report template |
| Q14 | Phase 32 | script runs | Q2 | **Done 2026-10-21** including 32e |
| Q15 | Phase 33 | close-out | all | **Done 2026-10-21** |
| Q16 | Phase 34 | `src/` + GUI [CONFIRM] | Q15 | **Done 2026-10-21** |
| Q17 | Phase 35 | `src/` + GUI + docs | Q16 | **Done 2026-10-21** |
| Q18 | Phase 36 — cabin mode animation in the GUI (§8) | GUI + `src/` [CONFIRM] | Q17 | **Done 2026-10-22** (author: "continue until no more phases are implemented"); steps 36a–36e |
| Q19 | Phase 37 — root-cause fixes from the 2026-10-21 GUI review (§8) | GUI + `src/` + scripts (author asked "find all root causes and fix all of them") | Q17 | 37a done 2026-10-21; 37a–37i done 2026-10-22 |
| Q19b | **R1 directory reorganization** (spec `docs/specs/R1_directory_reorg.md`): CR-3813 data → `data/cr3813/`, scripts → `scripts/{run,checks,digitize,setup,smoke}`, READMEs, every path reference updated | moves + path edits | P1 (done, `ef184d8`) | **Done 2026-10-22** (record in §11); reviewer runs full `Pkg.test()` |
| Q20 | Phase 38 — CR-3813 / User Manual completeness (§8; audit `validation_reports/cr3813_completeness_audit.md`; 38a spec `docs/specs/38a_noise_reduction.md`, equation page images `docs/specs/cr3813_pages/`) | `src/` + cases (author: "the whole PAIN program is supposed to function just like it does in the PAIN Methodology") | Q19 (37b first: amplitude convention) | 38a done (`:not_met`); 38b done (I-18 rule not met); 38c done (T2 not met); 38d done (`:not_met`); 38e done (no verdict); 38f-1, 38f-2, 38h done; 38g done (`:met`, 27/32) in order; 38f–38h planned with the author before starting |

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

## 6. Source phases 21–28 — aircraft source path, BBN/Wilby, NACA Report 996 and Pereira *(planned)*

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

### Phase 23 — Pre-registration of pass criteria *(planned)*

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

### Phase 24 — BBN/Wilby phase check *(planned — first source-validation run)*

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

### Phase 25 — Report 996 verification setup

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
- [ ] **25g. Scope and criteria first.** Test range: tip Mach 0.45 to 0.90. Nothing above 0.90 is tested (Figs. 13b, the 1.00 points of Fig. 14 and Fig. 8, and RM L51C27 rows at 1.00 and above are recorded but out of scope).
  The polar Mach grid stops at 0.72, so unscaled runs at 0.75–0.90 are flagged "polar Mach extrapolated"; scaled runs are the cleaner test there. No quadrupole term is modeled, which matters most near 0.9.
  The criteria themselves: Write the pass criteria for phases 26 and 27 into this file before any comparison (rule 3 in `VALIDATION_GUIDELINE.md` §2.3.1). One piece of reference
  scatter is already visible without running the code: the Fig. 7 legend C_P at M_t = 0.60 (0.0424 at 15°, 0.0818 at 20°) differs from RM L8H25a (0.0449, 0.0739) by −5% and +11%.
  Use that kind of source-to-source spread, not code results, to set the tolerance.

**Further steps of phase 25 (added 2026-10-20).** Needs D-07.

- [ ] **25h [CONFIRM] `ScaledLoads`.** `struct ScaledLoads; T_target::Float64; Q_target::Float64; end`. In `evaluate_propeller_source`, after `CCBlade.solve`: s_T = T_target/T, s_Q = Q_target/Q; scale the section normal force N_p by s_T and tangential force T_p by s_Q; rebuild the CCBlade `Outputs` (confirm the 1.0.0 constructor and that `f1a_source_elements_ccblade` reads N_p, T_p from it); recompute T, Q and check they equal the targets to rtol 1e-9; put s_T, s_Q and `loads = ScaledLoads(...)` into the echo. Test: scaled run reproduces the targets; amplitude scales linearly with a uniform s_T = s_Q (loading-only, thickness off).
- [ ] **25i [CONFIRM] Polar loader.** `load_polar_set(path; set=:primary|:bracket, viterna=nothing) -> (af, stats)`: reads `polars_forced_merged.json` (Report 996, through the `sections.json` fits with k_cl = k_cd = 1 for `:primary`, the `tables.json` calibration for `:bracket`) or `naca4412_xfoil_<setting>.json` (Pereira); linear in α inside the converged range, Viterna record (`viterna_extension.json`) outside it, bilinear in (log Re, M) between grid points, clamped at the grid edges; per-section selection by radius (nearest station or linear between the two nearest; state which). `stats` counts clamped Re, clamped M, Viterna evaluations and nearest-polar substitutions; every run prints them. α in radians at the interface (CCBlade convention). Tests: knot values reproduced to 1e-12; clamp counters increment; c_l continuous at the Viterna junction within 1e-6.
- [x] **25j Conversions (V-UNIT tests).** `total_rms` / `pressure_coefficient_pc` / Pa↔dyne; tests in `runtests.jl` (2026-10-21).
- [x] **25k Report.** `scripts/run/report996_setup.jl` → `docs/validation_reports/report996_setup.md` (2026-10-21): behind>ahead **true**; rms <0.1 dB from harmonic **n=7**; polar coverage + blade-angle shift recorded. Absolute F1A levels still ≫ measured (near field).

### Phase 26 — CCBlade check
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

### Phase 27 — AcousticAnalogies check
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

### Phase 28 — Forward-flight check against Pereira et al. (2026)

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

## 7. Aircraft-cabin phases 29–31

### Phase 29 — Aircraft cabin inputs: audit, guard, provenance, required inputs *(planned)*

Why: the cabin blocks carry NASA test-article constants (1.016 m shell, Phase III trim, curves shaped to that trim). The aircraft has a different diameter, trim and propeller, all supplied by the user (2.64 m is the working example, not a fixed value), and there is no experiment to tune against, so those constants must not reach an aircraft result silently. Step 29a is documentation only and can be done at any time before this point; the code steps wait for confirmation.

| Step | What | Done when |
|------|------|-----------|
| 29a | **Audit.** List every hard-coded NASA-test-article value reachable from the aircraft path. Today: the `V` and `S` defaults in `acoustic_loss_factor` (radius 0.508 m, length 1.803 m), `TrimPanel()` defaults, the η_a, η_s and absorption curves, the Table D-1 hybrid modes, the CYL2D and fuselage geometry defaults, `bb_j2_scale`, the H = 3 anchor. After 15a–17a: the Fig. A-2 insulation table (PF-105), the Phase III sidewall and end trim stacks, the sidewall surface mass from the MRP constants (skin, stringers, frames), the end-plate mass (1.3 cm aluminium), the 13a(f) assumed values, c0 and ρ0, and the absorption curve and `bb_j2_scale` of the high-frequency path (30b) | Table in `VALIDATION_GUIDELINE.md` §2.10 marked "test-article-specific", one row per value |
| 29b | **Guard.** Warn, and mark the result, whenever an aircraft run uses a test-article default; no silent fallback (the same idea as the `Vinf < 1` guard). A code change, **waits for confirmation** | An aircraft run with any NASA default is flagged in the output and the report |
| 29c | **Provenance tags.** Every cabin input is tagged measured, assumed or NASA-default; the tag is carried into the result and the report. An aircraft result that uses any NASA-default is labelled as NASA's article, not as the aircraft | Tags in the input schema and the report template |
| 29d | **Required-input list for the user.** Geometry, skin, stringers, frames, floor, trim stack (layer order, thicknesses, limp masses and loss factors, the insulation table λ_m, α, φ, \|W\| against frequency as in Fig. A-2, mechanical connections), end-plate mass and trim, bare-cabin η_n if untrimmed, C of Eq. (80), cabin volume, from the User Manual PAIN/MRP inputs and CR-3813 App. A | List in `METHODOLOGY.md` |

**Outputs.** 29a: rows in `VALIDATION_GUIDELINE.md` §2.10 tagged "test-article-specific" (file, line, value, source). 29b [CONFIRM]: a `NASADefaultUsed` warning and a `provenance` field in the run result. 29c [CONFIRM]: tag field per input in the aircraft JSON schema (`"value"`, `"tag": "measured" | "assumed" | "nasa_default"`). 29d: the list in `METHODOLOGY.md`, which is also the template for D-20.

### Phase 30 — Parametric cabin blocks *(planned)*

Make the cabin blocks general in the aircraft inputs so that no test-article curve is needed on the aircraft path. Loss factors predicted this way are the quantity NASA found about 10 dB off at H1 on its own article, so this phase reduces arbitrariness, not uncertainty; the uncertainty plan (phase 31) carries that size.

| Step | What | Done when |
|------|------|-----------|
| 30a | **Trim:** the App. A matrices move to 16a. What remains here: aircraft trim stack inputs from the user | Aircraft stack supplied and tagged |
| 30b | **Loss factors:** the tonal loss factors move to 16b. What remains: the high-frequency path of Eqs. (16)–(24) (α̅ from Eq. (24)/(78), the average radiation loss factors Eqs. (84)–(85)) in place of the absorption curve and `bb_j2_scale` | Computed from the user-supplied geometry (any diameter, 2.64 m being the working example); no 0.15 cap or test-article curve on the aircraft path |
| 30c | **Modes:** structural modes from the raw Ritz solver with the aircraft inputs (no Table D-1 hybrid on the aircraft path); CYL2D and the volume and area arguments take the aircraft geometry | Aircraft run uses no D-1 value and no hard-coded V, S |
| 30d | **Test-article regression:** with the test-article inputs, run the parametric blocks and compare with the tuned surrogate and with Figs. E-16, E-9. Record the shift in the loss factors and in H1–H3 | Shift recorded. This is direct evidence of the error from predicting loss factors without tuning, the input to phase 31 |

**Outputs.** 30b, 30c are `src/` changes [CONFIRM]. 30d: script `scripts/parametric_regression.jl` → `docs/validation_reports/parametric_regression.md` (loss factors and H1–H3 against the current chain and Figs. E-16, E-9; the shift is the input to 31a). If 30d changes the frozen baselines, the renewal is a dated author decision (R11).

### Phase 31 — Uncertainty plan for the aircraft cabin result *(planned; design under discussion 2026-10-19)*

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

## 8. Phases 32–35

**Phase 35 — Test audit, validation maps and the "Validation map" GUI tab** *(done 2026-10-21; see §11).*

### Phase 32 — GEXT importance bound (e11 path) *(planned; code options added)*

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

### Phase 33 — Close-out *(planned — last)*

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

### Phase 36 — Cabin mode animation in the GUI *(planned 2026-10-21; not started — do not implement until the author says go)*

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

### Phase 38 — CR-3813 / User Manual completeness *(planned 2026-10-21; order fixed; audit `validation_reports/cr3813_completeness_audit.md`)*

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

**PlotSpec `error_xlabel` (2026-10-22).** Optional error-panel x label (default `nothing` → reuse `xlabel`). Set for `UT_GRID` to `sample index (table row)` so the error panel is not labelled as axial z; audit found no other case where table.x differs from the main-panel x. Label wording only; `figures/UT_GRID.png` regenerated.

**Phase 36 result (2026-10-22, display only; no criterion, verdict or tuning).** Done: `src/mode_animation.jl` (frame generator from `cyl2d_modes`, node values unchanged, interpolation for drawing only; GIF and peak-frame PNG; Eq. C.9 axial factor), GUI "Cabin modes" tab (mode 0–19, q, structural mode r, play/pause/speed, Refresh via the 37i cooperative loop; f, Φ_G, symmetry; Fig. C-3 values for modes 0–5; fixed `CYL2D_C1` inputs c0 = 341, θ₀ = 56.6°, NY = 10), and 36d (Table D-1 ψ shape image and f′). Cache under `gui/cache/mode_anim/` is git-ignored. Tests: 309 new pass, registry 1232 pass, `smoke_gui_model.jl` and `smoke_qml_load.jl` pass offscreen.

**Rules.** No parameter is chosen by looking at a comparison result. Where the text is ambiguous, the reading is decided and
recorded from the text before running. Delegated work follows R13 (snapshot, diff, rules, run the checks, spot-check numbers, docs).

---

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
docs/validation_reports/figures/source/<case>.png            (phase 35: cropped source pages, display-only)
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
| 37e | No explanations (R2, F1A_GUTIN, PER_LOADS "no verdict", R996 loads errors, BBN, R996_PHASE); the Validation map not understandable | Texts were hard-coded in `validation_map.jl` and thin | New `VALIDATION_GUIDELINE.md` §2.13 "Validation case reference (read by the GUI)": one block per case, per map and per block; the GUI parses it, so editing the .md changes the GUI. Both tabs show what it tests, why, what a pass means, what is not covered, recorded outcome, explanation; the map gets "how to read this map". Leftover display items: blank legend entries beyond the cap, dense log ticks on Fig. 14 | Pending |
| 37f | R996_LOADS errors | No code bug: C_T, C_P definitions checked (T/(ρn²D⁴) both sides). CCBlade thrust ≈ 20 % low with these XFOIL polars, as the data folder's own BEM (12–31 % low) | Explanation only; not tuned; post-hoc label kept (criteria registered after the loads were computed) | Pending (text in 37e) |
| 37g | BBN_CIRC fails; R996_PHASE fails | I-19 (sign convention undocumented); page-12 stations not named in Report 996 (candidates ±0.125) | Explanations only; verdicts stay | Pending (text in 37e) |
| 37i | **Run buttons do nothing** (Validation tab Run / Run all, Validation map Run) | The QML handlers start the case with `@async` and return; `main()` ends with the blocking `exec()`, which never yields to Julia's scheduler, so the task never runs. The smoke tests call `run_validation_gui!` directly and never exercised the button path | `main()` uses QML.jl's `exec_async()` (cooperative event loop) and waits until the window closes; new smoke check runs the GUI on Qt's offscreen platform, triggers `run_validation_from_qml` from QML and asserts the case completed (status "Done …", PNG written) — the exact button path, no visible window | **Done 2026-10-22** (`dc0d48a`; offscreen button-path smoke test) |
| 37h | Five docs (R5) | — | README, flowchart, METHODOLOGY, VALIDATION_GUIDELINE, this file | **Done 2026-10-22** (docs synced after 38a–38e; Phase 38 modules added to README, METHODOLOGY, flowchart, VALIDATION_GUIDELINE) |
