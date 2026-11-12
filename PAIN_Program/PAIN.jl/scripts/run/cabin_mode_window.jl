#!/usr/bin/env julia
# Phase 151 (2026-11-11): one cabin acoustic mode, animated in a window of its own (GLMakie), with Play / Pause, a frame
# slider and a speed slider. Display only: the frames are `mode_animation_frames` unchanged (CYL2D_C1's fixed inputs);
# no criterion, no verdict. Started by the GUI's "Open in new window" button, or by hand:
#   julia --project=. scripts/run/cabin_mode_window.jl MODE [Q]
# `PAIN_MODE_WINDOW_SMOKE=path.png` saves one frame after a few steps and closes (used by the smoke test).
using GLMakie, PAIN

mode = length(ARGS) ≥ 1 ? parse(Int, ARGS[1]) : 1
q = length(ARGS) ≥ 2 ? parse(Int, ARGS[2]) : 0
res = PAIN.cyl2d_c1_for_display()
fr = PAIN.mode_animation_frames(res, mode; nframes=48)
o = PAIN._cabin_outline(deg2rad(fr.theta0_deg))

k = Observable(1)
z = lift(i -> fr.frames[i], k)
fig = Figure(size=(720, 760))
ax = Axis(fig[1, 1]; aspect=DataAspect(), xlabel="y / a", ylabel="z / a",
          title="Cabin mode $(mode), f = $(round(fr.f_Hz; digits=2)) Hz (unit radius, c0 = $(fr.c0) m/s), axial order q = $(q)")
hm = heatmap!(ax, fr.x, fr.y, z; colormap=:balance, colorrange=(-fr.clim, fr.clim), nan_color=:transparent)
contour!(ax, fr.x, fr.y, fr.φ0; levels=[0.0], color=:black, linewidth=1.0)
lines!(ax, o.wall_x, o.wall_y; color=:black, linewidth=2)
lines!(ax, o.floor_x, o.floor_y; color=:black, linewidth=2)
Colorbar(fig[1, 2], hm; label="pressure (relative)")
controls = fig[2, 1:2] = GridLayout(tellwidth=false)
play = Button(controls[1, 1]; label="Pause")
sl = Slider(controls[1, 2]; range=1:fr.nframes, startvalue=1, width=320)
Label(controls[1, 3], lift(i -> "frame $i / $(fr.nframes)", sl.value))
speed = Slider(controls[2, 2]; range=0.25:0.25:4.0, startvalue=1.0, width=320)
Label(controls[2, 1], "speed")
Label(controls[2, 3], lift(s -> "$(s)×", speed.value))
Label(fig[3, 1:2], fr.note; fontsize=11, color=:gray40)
on(i -> (k[] = i), sl.value)
playing = Ref(true)
on(play.clicks) do _
    playing[] = !playing[]
    play.label = playing[] ? "Pause" : "Play"
end

screen = display(fig)
smoke = get(ENV, "PAIN_MODE_WINDOW_SMOKE", "")
steps = 0
while isopen(screen)
    if playing[]
        set_close_to!(sl, mod1(sl.value[] + 1, fr.nframes))
        global steps += 1
    end
    if !isempty(smoke) && steps ≥ 5
        save(smoke, fig)
        println("MODE_WINDOW saved ", smoke, " at frame ", k[])
        close(screen)
        break
    end
    sleep(0.06 / speed.value[])
end
