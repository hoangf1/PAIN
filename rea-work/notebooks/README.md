# Notebooks

Pluto notebooks that walk through the program (Phase 91). Each is a plain Julia file: open it in Pluto to change inputs and
watch every stage update, or run it as a script.

| Notebook | What it shows |
|---|---|
| `01_pain_step_by_step.jl` | PAIN on NASA's test article: the 160-point grid, Eq. (43) blocking, the blocked pressure, structural and cabin modes, the Eq. (8) tone sum, the interior SPL. Change the blocking variant, the trim loss η_T or the number of harmonics in the *Inputs* cell. |
| `02_validation_cases.jl` | How a validation case works: run one, read its criterion, verdict, table and figure; what carries a verdict (the 2026-10-29 rule); a diagnostic and `underlying_verdict`. Change `case_id` to look at any case. |

## Open them

From the repository root, once (installs Pluto in this folder's own environment; the package's dependencies do not change):

```
julia --project=rea-work/notebooks -e "import Pkg; Pkg.instantiate()"
```

Then start Pluto and open a notebook file from its start page:

```
julia --project=rea-work/notebooks -e "using Pluto; Pluto.run()"
```

Each notebook activates the `rea-work/PAIN.jl` environment in its first cell, so the program must be instantiated as for
any other run (`README.md`, Step 0). The first run of a notebook takes a few minutes (compilation).

## Check them

`check_notebooks.jl` runs every notebook through Pluto without a browser and fails if any cell errors; it works on temp
copies, so nothing in the repository changes:

```
julia --project=rea-work/notebooks rea-work/notebooks/check_notebooks.jl
```

The notebooks write no files. Run the check after changing any function a notebook calls.
