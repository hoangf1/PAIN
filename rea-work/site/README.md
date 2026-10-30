# The methodology website

A **read-through** of the recreation: one page that walks the pipeline stage by stage, pairing what each stage does
with the validation cases that carry a verdict on it. It is not a copy of the documents.

## Build it and open it

From the repository root:

```
julia --project=rea-work/PAIN.jl rea-work/site/build_site.jl
```

That writes `rea-work/site/out/index.html` and opens it in your browser. No server and no network: open the file
again whenever you like, or hand the `out/` folder to someone else.

| Flag | What it does |
|---|---|
| *(none)* | Build, then open `index.html` in the default browser |
| `--no-open` | Build only |
| `--out DIR` | Build somewhere other than `rea-work/site/out` |

## What is on the page

1. **What counts as proof** — the grade table and the 2026-10-29 verdict rule, both from `METHODOLOGY.md`.
2. **The pipeline at a glance** — the whole-program flowchart and the stage table.
3. **One section per stage** — stages 1 to 8, each opening with its own flowchart, then what the stage does, its
   chain and its claim, then every validation case on that stage that carries a verdict, with its criterion, the
   date that criterion was fixed, its recorded result and its figure.
4. **What this does not claim**, and where the full detail lives.

### What is deliberately left out

**Only cases with a met / not-met verdict appear.** Under the rule of 2026-10-29 a case can carry one only if it
compares with experimental data, or checks that the code does what PAIN did on PAIN's own inputs. The rest of the
register — identities, hand and closed forms, independent re-implementations, diagnostics, displays and
`Pkg.test`-only checks, about two thirds of it — verifies that the code does what it says, which is not the same as
showing the method matches reality. Those stay in `docs/VALIDATION_GUIDELINE.md` §2.13 and
`docs/NO_VERDICT_CASES.md`.

**The documents are not copied onto the page.** The README, the plan, the completed phases, the full case register
and the chunk-layout rules are linked at the foot of the page, not inlined. The prose that *is* shown is lifted
from `METHODOLOGY.md` — the *Validation chunk*, *What it does*, *Chain* and *Claim* parts of each stage's section —
so it cannot drift from the document; the implementation notes and the long miss analyses stay there.

### Reading it

**Equations** are LaTeX, rendered by MathJax (SVG output, so no font files and no network). They live in
`METHODOLOGY.md` as `$...$` and `$$...$$`, which GitHub renders too, so the page and the document cannot disagree.
Julia's Markdown turns `$`, `{` and `}` into HTML entities, so the generator lifts the maths out before parsing and
puts it back as MathJax delimiters.

**Claims** are shown as callouts: the `Claim: ...` grade line becomes the heading and the body is broken at the bold
run-ins the author already wrote. No words are changed — only where the paragraph breaks. A claim longer than about
ten lines collapses behind *Show the whole claim*.

**Any figure or diagram fills the window when clicked** (Esc or a click closes it). Diagrams are cloned as SVG, so
they scale instead of pixelating.

### The stage flowcharts

Each stage's diagram is generated from `docs/VALIDATION_GUIDELINE.md` §2.13 — the same `Position` / `Feeds` /
`Group` / `Role` fields the GUI's validation map reads — so the picture cannot drift from the map. Chain blocks run
left to right, check blocks hang off them dashed and carry their met / not-met count, and the faint box on the
right is the stage this one feeds. The whole-program diagram at the top is `flowchart.md` §1.

## What the build does and does not do

It **renders** the documents and the **recorded** case snapshot as they stand on disk. It runs no validation case,
computes no result and fixes no criterion, so building the site can never change a verdict. The verdicts shown are
the ones in `docs/validation_reports/case_error_summary.csv`, each with its own run date.

To refresh what the page shows:

| To update | Run (in `rea-work/PAIN.jl`) |
|---|---|
| A case's verdict, error line and figure | `julia --project=. scripts/run/regenerate_case_figures.jl CASE_ID` |
| The whole case snapshot | `julia --project=. scripts/run/write_case_error_summary.jl` |
| The walk-through's numbers and figures | `julia --project=. scripts/run/write_walkthrough.jl` |

Then rebuild the site. To run a case live instead, use the GUI (`scripts/run_gui.jl`): its Validation tab and the
chips on the Validation map run the same functions, and their run-status boxes say whether what you are looking at
is a fresh run or the recorded snapshot.

## Adding or moving a stage

`STAGES` in `build_site.jl` is the whole structure: each entry names the map groups it covers and the
`METHODOLOGY.md` headings its prose comes from. A new map group, or a renamed methodology heading, needs its entry
updated — the build warns (`METHODOLOGY section not found`) when a heading no longer resolves.

## Layout

```
site/
  build_site.jl        the generator (stdlib Markdown; no extra packages)
  vendor/
    mermaid.min.js         vendored so the diagrams render offline
    mathjax-tex-svg.js     vendored so the equations render offline
  out/                 generated; not in git
    index.html         the page: all text, CSS and JS inline
    assets/
      mermaid.min.js
      mathjax-tex-svg.js
      img/             the case figures the page shows
```

`index.html` carries all its text itself; the figures and the diagram renderer sit in `assets/` beside it. Keep the
folder together when you move or share it.
