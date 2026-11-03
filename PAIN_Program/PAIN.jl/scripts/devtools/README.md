# PAIN.jl developer tools (DaemonMode)

Faster edit–check loop without changing test behaviour or adding DaemonMode to the PAIN package.

## Setup (once)

```powershell
cd <PAIN.jl root>
julia scripts\devtools\instantiate.jl
```

This creates `Manifest.toml` in this folder only. **Do not** add DaemonMode or Revise to `PAIN.jl/Project.toml`.

## Persistent Julia daemon

```powershell
.\scripts\devtools\start_daemon.ps1
# wait until scripts\devtools\daemon.out.log mentions DaemonMode.serve
.\scripts\devtools\run_in_daemon.ps1 scripts\smoke\smoke_gui_model.jl
.\scripts\devtools\run_in_daemon.ps1 scripts\devtools\run_tests_in_daemon.jl CYL2D
.\scripts\devtools\stop_daemon.ps1
```

| Script | Role |
|--------|------|
| `start_daemon.ps1` / `start_daemon.jl` | `julia --project=scripts/devtools`, load Revise + DaemonMode, activate PAIN, `using PAIN`, then `serve(shared=true)` |
| `run_in_daemon.ps1 <script.jl> [args…]` | Client: `DaemonMode.runargs()` |
| `run_tests_in_daemon.jl` | `include(test/runtests.jl)` with filter ARGS |
| `stop_daemon.ps1` | `sendExitCode()` (+ kill PID file if needed) |

`QT_QPA_PLATFORM=offscreen` is set so nothing opens a GUI window.

## Revise and `src/` edits

Revise **is** loaded in the daemon (`using Revise` before `using PAIN`). DaemonMode calls `Revise.revise()` before each client run when Revise is present.

- **Tracked:** changes under `PAIN.jl/src/` that Revise can revise (typical method/function body edits).
- **Restart the daemon** after adding/removing exported names, changing `Project.toml` / `Manifest.toml`, or if Revise reports it could not revise a file.
- If a change does not appear to take effect, stop and start the daemon.

## Testset filter (also works without the daemon)

```powershell
julia --project=. -e "using Pkg; Pkg.test(`"PAIN`"; test_args=[`"CYL2D`", `"Validation case registry`"])"
.\scripts\devtools\run_in_daemon.ps1 scripts\devtools\run_tests_in_daemon.jl CYL2D "Validation case registry"
```

Empty `test_args` / ARGS → all top-level testsets (unchanged). Substrings match titles case-insensitively. See `test/README.md` for titles and typical times.

`run_in_daemon.ps1` escapes spaces in test filters as `<|>` before DaemonMode’s space-joined wire format; `run_tests_in_daemon.jl` decodes them.
