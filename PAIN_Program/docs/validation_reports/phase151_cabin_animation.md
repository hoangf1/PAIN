# Phase 151: the cabin-mode animation plays (2026-11-11)

Display only: no case, criterion or verdict is involved. Done by Claude under the author's authority of 2026-11-10 and 2026-11-11. The second window was the author's own request during the phase ("instead of an html why cant you just open it in a new window").

## 151a What failed

The frames were built when the tab opened, and each was loaded once and shown by index (done on 2026-11-10). Even so, the smoke run of 2026-11-11 grabbed frame 0 twice. Pressing Play had no effect.

A trace showed the cause. The Play button and the smoke both wrote `pain.cm_playing = true` from QML, and the play timer's `running` binding read `pain.cm_playing`. The binding was not re-evaluated after QML wrote that property into the Julia property map, so the timer never started. This was the play flag, the second of the three points 151a listed.

## 151b, 151c The fix

- **In the window.** The play flag is now a QML property (`root.cmPlaying`), and the timer runs on it. Julia receives a copy for its log. With this change the smoke's two grabs are frames 0 and 2, so the mode is seen moving. No GIF plugin is needed, because the frames are PNGs shown by index.
- **In a window of its own (author's request).** An "Open in new window" button starts `scripts/run/cabin_mode_window.jl` in a separate Julia process. The script uses GLMakie, Makie's on-screen back end, which sits beside the CairoMakie used for every figure here. Its window has Play / Pause, a frame slider and a speed slider. Because it runs in its own process, the GUI does not wait on it. The frames are `mode_animation_frames`, unchanged.
- GLMakie 0.13.16 was added to `Project.toml`. The manifest only gained packages; no version that was already there moved.
- A Plotly page in the browser was tried first and dropped: Plotly draws only inside a browser, and the author asked for a window.

## 151d Checks

| Check | Result |
|---|---|
| `smoke_qml_load.jl`, cabin-animation child | PASS: 24 frames; the two grabs show frames 0 and 2 |
| `cabin_mode_window.jl 3 0` with `PAIN_MODE_WINDOW_SMOKE` | the window opened, played to frame 6 of 48 and saved a picture |
| `test_mode_animation.jl` | 35 pass; the window command names the script, the mode and the axial order |
| `test_gui_model.jl` | 84 pass |

The GLMakie window needs a screen with OpenGL, so it is not part of `Pkg.test()`. It was checked by the one run above.
