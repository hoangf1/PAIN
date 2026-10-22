# Phase 36 — cabin mode animation (display only).
# No criterion, no verdict, no tuning. Interpolation is for drawing only; node values unchanged.

# CR-3813 Fig. C-3 printed one-decimal node values (modes 0–5), same transcription as
# test/fig_c3_values.jl — for the animation overlay only (display, not a check).
const FIG_C3_PRINTED_ROWS = [
    # mode 0
    [[1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 1.0, 1.0], fill(1.0, 6), fill(1.0, 6), fill(1.0, 7), fill(1.0, 7),
     fill(1.0, 7), fill(1.0, 7), fill(1.0, 7), fill(1.0, 7), fill(1.0, 6)],
    # mode 1
    [[-0.0, 0.2, 0.3], [-0.0, 0.2, 0.3, 0.5, 0.6], [0.0, 0.2, 0.4, 0.5, 0.7, 0.8], [0.0, 0.2, 0.4, 0.6, 0.7, 0.8],
     [0.0, 0.2, 0.5, 0.6, 0.8, 0.9, 0.9], [0.0, 0.2, 0.5, 0.7, 0.8, 0.9, 1.0], [-0.0, 0.3, 0.5, 0.7, 0.9, 0.9, 1.0],
     [-0.0, 0.3, 0.5, 0.7, 0.9, 1.0, 1.0], [-0.0, 0.3, 0.5, 0.7, 0.9, 1.0, 1.0], [-0.0, 0.3, 0.5, 0.7, 0.9, 1.0, 1.0],
     [-0.0, 0.3, 0.5, 0.7, 0.9, 0.9]],
    # mode 2
    [[1.0, 1.0, 0.9], [1.0, 0.9, 0.9, 0.8, 0.7], [0.8, 0.8, 0.8, 0.7, 0.6, 0.5], [0.7, 0.6, 0.6, 0.5, 0.4, 0.3],
     [0.4, 0.4, 0.4, 0.3, 0.3, 0.2, 0.1], [0.2, 0.2, 0.1, 0.1, 0.0, -0.0, -0.1],
     [-0.1, -0.1, -0.1, -0.1, -0.2, -0.2, -0.2], [-0.3, -0.3, -0.3, -0.4, -0.4, -0.4, -0.4],
     fill(-0.5, 7), fill(-0.6, 7), fill(-0.7, 6)],
    # mode 3
    [[-0.0, 0.3, 0.6], [-0.0, 0.4, 0.7, 0.9, 1.0], [0.0, 0.4, 0.7, 0.9, 1.0, 1.0], [0.0, 0.3, 0.6, 0.8, 0.9, 0.8],
     [-0.0, 0.2, 0.5, 0.6, 0.7, 0.6, 0.6], [-0.0, 0.1, 0.3, 0.3, 0.4, 0.3, 0.3], [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.0],
     [0.0, -0.1, -0.2, -0.3, -0.3, -0.3, -0.3], [-0.0, -0.2, -0.4, -0.5, -0.6, -0.6, -0.6],
     [0.0, -0.2, -0.5, -0.7, -0.8, -0.8, -0.8], [0.0, -0.3, -0.5, -0.7, -0.8, -0.9]],
    # mode 4
    [[0.6, 0.6, 0.4], [0.6, 0.5, 0.3, 0.1, -0.2], [0.5, 0.4, 0.2, -0.1, -0.4, -0.6], [0.5, 0.4, 0.1, -0.2, -0.5, -0.7],
     [0.4, 0.3, 0.1, -0.3, -0.6, -0.9, -1.0], [0.5, 0.4, 0.1, -0.3, -0.6, -0.9, -1.0],
     [0.6, 0.5, 0.2, -0.2, -0.6, -0.9, -1.0], [0.7, 0.6, 0.3, -0.1, -0.5, -0.7, -0.8],
     [0.8, 0.7, 0.5, 0.1, -0.3, -0.6, -0.7], [1.0, 0.9, 0.6, 0.2, -0.2, -0.4, -0.5], [1.0, 0.9, 0.6, 0.2, -0.1, -0.3]],
    # mode 5
    [[1.0, 0.9, 0.7], [0.9, 0.8, 0.6, 0.3, 0.0], [0.5, 0.5, 0.3, 0.1, -0.1, -0.3], [0.1, 0.1, -0.0, -0.2, -0.3, -0.4],
     [-0.3, -0.3, -0.3, -0.4, -0.4, -0.4, -0.4], [-0.6, -0.5, -0.5, -0.4, -0.4, -0.3, -0.3],
     [-0.6, -0.6, -0.5, -0.3, -0.2, -0.1, -0.0], [-0.5, -0.5, -0.3, -0.1, 0.1, 0.3, 0.3],
     [-0.3, -0.3, -0.1, 0.2, 0.5, 0.6, 0.6], [-0.2, -0.1, 0.1, 0.4, 0.7, 0.8, 0.8], [-0.1, -0.0, 0.2, 0.5, 0.8, 0.9]],
]

"""Fixed CYL2D_C1 display inputs (not editable in the Cabin modes panel)."""
const CYL2D_C1_DISPLAY_INPUTS = (theta0_deg=56.6, NY=10, c0=TABLE_C1_C0)

"""
    axial_factor(q, L) -> Function

Eq. (C.9) axial factor: cos(q π z / L). Display only.
"""
axial_factor(q::Integer, L::Real) = z -> cos(q * π * float(z) / float(L))

"""Half-cabin φ at (m,n); missing keys → NaN (outside cabin / antisymmetric centreline drop)."""
function _phi_half(mode::AcousticMode, m::Int, n::Int)
    haskey(mode.phi_nodes, (m, n)) && return mode.phi_nodes[(m, n)]
    return NaN
end

"""Full-section φ at integer indices (m signed, n ≥ 0); antisymmetric flips sign for m < 0."""
function _phi_full(mode::AcousticMode, m::Int, n::Int)
    s = (m < 0 && !mode.symmetric) ? -1.0 : 1.0
    v = _phi_half(mode, abs(m), n)
    return isnan(v) ? NaN : s * v
end

"""
Build the App. C node field on the full cabin section (mirrored). Returns
(x_nodes, y_nodes, φ_nodes_matrix, mask, m_range, n_range) on the integer grid.
Node values are exactly `mode.phi_nodes` (mirrored); no smoothing.
"""
function _full_section_nodes(res::Cyl2DResult, mode::AcousticMode)
    θ0 = deg2rad(res.theta0_deg)
    g = _build_grid(θ0, res.NY)
    h, yfloor = g.h, g.yfloor
    Mmax = size(g.incab, 1) - 1
    ms = collect(-Mmax:Mmax)
    ns = collect(0:res.NY)
    nx, ny = length(ms), length(ns)
    φ = fill(NaN, nx, ny)
    mask = falses(nx, ny)
    x = [m * h for m in ms]
    y = [yfloor + n * h for n in ns]
    for (ix, m) in enumerate(ms), (iy, n) in enumerate(ns)
        v = _phi_full(mode, m, n)
        if !isnan(v)
            φ[ix, iy] = v
            mask[ix, iy] = true
        elseif abs(m) <= Mmax && g.incab[abs(m)+1, n+1]
            # antisymmetric centreline interior: φ = 0
            if m == 0 && !mode.symmetric
                φ[ix, iy] = 0.0
                mask[ix, iy] = true
            end
        end
    end
    return (; x, y, φ, mask, ms, ns, h, yfloor, θ0, Mmax)
end

"""
Bilinear sample of the node field for drawing only. Outside the cabin → NaN.
`grid` is the number of samples along each axis of the bounding box (default denser than NY).
"""
function _interpolate_drawing_field(nodes; grid::Int=81)
    x0, x1 = extrema(nodes.x)
    y0, y1 = extrema(nodes.y)
    xs = range(x0, x1; length=grid)
    ys = range(y0, y1; length=grid)
    φd = fill(NaN, grid, grid)
    h = nodes.h
    yfloor = nodes.yfloor
    for (ix, xv) in enumerate(xs), (iy, yv) in enumerate(ys)
        # map to fractional (m, n)
        mf = xv / h
        nf = (yv - yfloor) / h
        m0 = floor(Int, mf)
        n0 = floor(Int, nf)
        # sample four corners from full-section node matrix
        function at(m::Int, n::Int)
            (n < 0 || n > nodes.ns[end]) && return NaN
            ixn = findfirst(==(m), nodes.ms)
            iyn = findfirst(==(n), nodes.ns)
            (ixn === nothing || iyn === nothing) && return NaN
            nodes.mask[ixn, iyn] || return NaN
            return nodes.φ[ixn, iyn]
        end
        v00 = at(m0, n0)
        v10 = at(m0 + 1, n0)
        v01 = at(m0, n0 + 1)
        v11 = at(m0 + 1, n0 + 1)
        if any(isnan, (v00, v10, v01, v11))
            # nearest valid node (drawing only)
            best = NaN
            bd = Inf
            for m in m0:(m0+1), n in n0:(n0+1)
                v = at(m, n)
                isnan(v) && continue
                d = (mf - m)^2 + (nf - n)^2
                if d < bd
                    bd = d
                    best = v
                end
            end
            φd[ix, iy] = best
        else
            tx = mf - m0
            ty = nf - n0
            φd[ix, iy] = (1 - tx) * (1 - ty) * v00 + tx * (1 - ty) * v10 +
                         (1 - tx) * ty * v01 + tx * ty * v11
        end
    end
    return collect(xs), collect(ys), φd
end

"""Nodal-line mask on a drawing field: |φ| ≤ tol × peak (display contour seed)."""
function _nodal_mask(φ::AbstractMatrix; tol::Float64=0.05)
    peak = maximum(abs, filter(!isnan, vec(φ)); init=0.0)
    peak == 0 && return isnan.(φ) .| falses(size(φ)...)
    return .!isnan.(φ) .& (abs.(φ) .≤ tol * peak)
end

"""
    mode_animation_frames(res, mode; nframes=24, grid=81) -> NamedTuple

Display-only frames: full cabin section φ_n(x,y)·cos(2π k/nframes).
Half-cabin App. C nodes are mirrored (antisymmetric modes change sign across the
centreline). `grid` is the drawing interpolation density; node values are unchanged.
Modes 0–19.
"""
function mode_animation_frames(res::Cyl2DResult, mode::Integer; nframes::Int=24, grid::Int=81)
    (0 ≤ mode ≤ 19) || error("mode must be 0–19, got $mode")
    length(res.modes) > mode || error("Cyl2DResult has $(length(res.modes)) modes; need mode $mode")
    nframes ≥ 1 || error("nframes must be ≥ 1")
    m = res.modes[mode + 1]
    nodes = _full_section_nodes(res, m)
    x, y, φ0 = _interpolate_drawing_field(nodes; grid=grid)
    peak = maximum(abs, filter(!isnan, vec(φ0)); init=0.0)
    clim = peak > 0 ? peak : 1.0
    nodal = _nodal_mask(φ0)
    frames = Vector{Matrix{Float64}}(undef, nframes)
    for k in 0:(nframes - 1)
        c = cos(2π * k / nframes)
        frames[k + 1] = φ0 .* c
    end
    fig_c3 = (0 ≤ mode ≤ 5) ? FIG_C3_PRINTED_ROWS[mode + 1] : nothing
    return (
        x=x, y=y,
        frames=frames,
        φ0=φ0,
        clim=clim,
        colour_limits=(-clim, clim),
        nodal_mask=nodal,
        mode=mode,
        f_Hz=m.f_Hz_unit,
        Φ_G=m.gen_mass_unit,
        symmetric=m.symmetric,
        c0=res.c0,
        theta0_deg=res.theta0_deg,
        NY=res.NY,
        h=res.h,
        nframes=nframes,
        nodes=nodes,
        fig_c3=fig_c3,
        note="display only — interpolated for drawing; node values unchanged",
    )
end

"""Floor and wall outline polylines for the unit-radius cabin (a = 1)."""
function _cabin_outline(θ0::Float64; nθ::Int=180)
    # θ from bottom centreline (cyl2d): wall (sin θ, −cos θ) for θ ∈ [θ0, 2π−θ0].
    θw = range(θ0, 2π - θ0; length=nθ)
    xw = [sin(θ) for θ in θw]
    yw = [-cos(θ) for θ in θw]
    xf = [-sin(θ0), sin(θ0)]
    yf = [-cos(θ0), -cos(θ0)]
    return (; wall_x=xw, wall_y=yw, floor_x=xf, floor_y=yf)
end

function _fig_c3_text(rows)
    rows === nothing && return "(Fig. C-3 overlay only for modes 0–5)"
    lines = String["Fig. C-3 printed (one decimal; crown→floor):"]
    for (r, row) in enumerate(rows)
        n = 11 - r
        push!(lines, "n=$n: " * join(string.(row), " "))
    end
    return join(lines, "\n")
end

"""
    render_mode_animation(path, frames; format=:gif, axial_q=0, L=test_article_length())

Write a GIF (CairoMakie `record`) and a PNG of the peak frame (cos = 1).
Caption: mode index, f, Φ_G, symmetry, display-only note. Modes 0–5 include Fig. C-3 panel.
Optional axial side view: cos(q π z / L) (Eq. C.9).
Returns `(gif_path, png_path)`.
"""
function render_mode_animation(path::AbstractString, frames;
                               format::Symbol=:gif,
                               axial_q::Integer=0,
                               L::Real=test_article_length(),
                               framerate::Int=12)
    format === :gif || error("only format=:gif is supported (got $format)")
    out = abspath(path)
    dir = dirname(out)
    isdir(dir) || mkpath(dir)
    base, _ = splitext(out)
    gif_path = endswith(lowercase(out), ".gif") ? out : base * ".gif"
    png_path = base * "_peak.png"

    outline = _cabin_outline(deg2rad(frames.theta0_deg))
    clim = frames.clim
    sym = frames.symmetric ? "symmetric" : "antisymmetric"
    caption = "mode $(frames.mode)  f=$(round(frames.f_Hz; digits=3)) Hz  Φ_G=$(round(frames.Φ_G; digits=5))  $sym\n" *
              "$(frames.note)"

    # Peak frame PNG (k=0 → cos=1)
    ncol = frames.fig_c3 === nothing ? 1 : 2
    fig_png = Figure(size=(ncol == 1 ? (720, 640) : (980, 640)); fontsize=12)
    ax = Axis(fig_png[1, 1]; aspect=DataAspect(),
              xlabel="x (a = 1)", ylabel="y (a = 1)",
              title="Cabin mode $(frames.mode) — peak frame")
    heatmap!(ax, frames.x, frames.y, frames.frames[1];
             colormap=:balance, colorrange=(-clim, clim), nan_color=:transparent)
    contour!(ax, frames.x, frames.y, frames.φ0; levels=[0.0], color=:black, linewidth=1.2)
    lines!(ax, outline.wall_x, outline.wall_y; color=:black, linewidth=2)
    lines!(ax, outline.floor_x, outline.floor_y; color=:black, linewidth=2)
    if frames.fig_c3 !== nothing
        Label(fig_png[1, 2], _fig_c3_text(frames.fig_c3);
              tellwidth=false, fontsize=10, halign=:left, valign=:top,
              justification=:left, padding=(8, 8, 8, 8))
    end
    zs = range(0, float(L); length=200)
    af = axial_factor(Int(axial_q), L).(zs)
    axa = Axis(fig_png[2, 1:ncol]; xlabel="z (m)", ylabel="cos(qπz/L)",
               title="Eq. (C.9) axial factor q=$(Int(axial_q)), L=$(round(float(L); digits=3)) m",
               height=120)
    lines!(axa, collect(zs), collect(af); color=:steelblue, linewidth=2)
    Label(fig_png[3, 1:ncol], caption; tellwidth=false, fontsize=11)
    save(png_path, fig_png)

    # GIF via record (Observable so each frame updates the heatmap)
    fig = Figure(size=(640, 520); fontsize=12)
    axg = Axis(fig[1, 1]; aspect=DataAspect(),
               xlabel="x (a = 1)", ylabel="y (a = 1)",
               title="Cabin mode $(frames.mode) (display only)")
    φ_obs = Observable(frames.frames[1])
    heatmap!(axg, frames.x, frames.y, φ_obs;
             colormap=:balance, colorrange=(-clim, clim), nan_color=:transparent)
    contour!(axg, frames.x, frames.y, frames.φ0; levels=[0.0], color=:black, linewidth=1.0)
    lines!(axg, outline.wall_x, outline.wall_y; color=:black, linewidth=2)
    lines!(axg, outline.floor_x, outline.floor_y; color=:black, linewidth=2)
    Label(fig[2, 1], caption; tellwidth=false, fontsize=10)
    record(fig, gif_path, 1:frames.nframes; framerate=framerate) do i
        φ_obs[] = frames.frames[i]
    end
    return (gif_path=gif_path, png_path=png_path)
end

"""Write each animation frame as a PNG; returns vector of paths (for GUI play)."""
function render_mode_frame_pngs(dir::AbstractString, frames; prefix::AbstractString="frame")
    isdir(dir) || mkpath(dir)
    outline = _cabin_outline(deg2rad(frames.theta0_deg))
    clim = frames.clim
    paths = String[]
    for i in 1:frames.nframes
        p = joinpath(dir, "$(prefix)_$(lpad(i, 3, '0')).png")
        fig = Figure(size=(560, 480); fontsize=11)
        ax = Axis(fig[1, 1]; aspect=DataAspect(),
                  title="mode $(frames.mode)  frame $i/$(frames.nframes)")
        heatmap!(ax, frames.x, frames.y, frames.frames[i];
                 colormap=:balance, colorrange=(-clim, clim), nan_color=:transparent)
        contour!(ax, frames.x, frames.y, frames.φ0; levels=[0.0], color=:black, linewidth=1.0)
        lines!(ax, outline.wall_x, outline.wall_y; color=:black, linewidth=2)
        lines!(ax, outline.floor_x, outline.floor_y; color=:black, linewidth=2)
        save(p, fig)
        push!(paths, abspath(p))
    end
    return paths
end

# --- optional 36d: structural shape + f′ (display only) --------------------------------

"""
    structural_mode_display(st, fuse; nz=40, nθ=72) -> NamedTuple

Table D-1 / Eqs. (46–49) ψ on shell and floor for display. No criterion.
"""
function structural_mode_display(st::StructuralMode, fuse::FuselageGeometry;
                                 nz::Int=40, nθ::Int=72, nx::Int=41)
    L, a = fuse.L, fuse.a
    θ0 = deg2rad(fuse.theta0_deg)
    Lp = 2a * sin(θ0)
    zs = range(0, L; length=nz)
    θs = range(rad2deg(θ0), rad2deg(2π - θ0); length=nθ)
    shell = [structural_shell_psi(st, z, θ, L) for θ in θs, z in zs]
    xs = range(-Lp / 2, Lp / 2; length=nx)
    floor = [structural_floor_psi(st, z, x, L, Lp) for x in xs, z in zs]
    return (; z=collect(zs), theta_deg=collect(θs), x_floor=collect(xs),
            shell_ψ=shell, floor_ψ=floor,
            index=st.index, f_Hz=st.f_Hz, symmetric=st.symmetric)
end

"""
    coupling_display(ac, st, fuse; q=0, τ_t=1.0) -> NamedTuple

f′ between a selected structural and acoustic mode (Eq. 52 path). Display only.
"""
function coupling_display(ac::AcousticMode, st::StructuralMode, fuse::FuselageGeometry;
                          q::Integer=0, τ_t::Float64=1.0)
    f = coupling_factor(ac, st, fuse; τ_t=τ_t, q=Int(q))
    return (; f_prime=f, q=Int(q), acoustic_index=ac.index, structural_index=st.index,
            acoustic_f_Hz=ac.f_Hz_unit, structural_f_Hz=st.f_Hz)
end

"""Render structural shell/floor ψ to a PNG (display only)."""
function render_structural_mode_png(path::AbstractString, disp)
    fig = Figure(size=(720, 420); fontsize=12)
    ax1 = Axis(fig[1, 1]; xlabel="z (m)", ylabel="θ (deg)", title="shell ψ (Eqs. 46–47) mode $(disp.index)")
    heatmap!(ax1, disp.z, disp.theta_deg, disp.shell_ψ'; colormap=:balance)
    ax2 = Axis(fig[1, 2]; xlabel="z (m)", ylabel="x floor (m)", title="floor ψ (Eqs. 48–49)")
    heatmap!(ax2, disp.z, disp.x_floor, disp.floor_ψ'; colormap=:balance)
    Label(fig[2, :], "display only — Table D-1 shapes; f=$(round(disp.f_Hz; digits=2)) Hz";
          tellwidth=false, fontsize=11)
    dir = dirname(abspath(path))
    isdir(dir) || mkpath(dir)
    save(path, fig)
    return abspath(path)
end

"""Cache directory for Cabin modes panel PNGs/GIFs (not under validation figure paths)."""
function mode_animation_cache_dir()
    d = joinpath(@__DIR__, "..", "gui", "cache", "mode_anim")
    isdir(d) || mkpath(d)
    return abspath(d)
end

"""
CYL2D result for the Cabin modes panel: fixed CYL2D_C1 inputs (θ0, NY, c0).
"""
function cyl2d_c1_for_display(; n_modes::Int=20)
    inp = CYL2D_C1_DISPLAY_INPUTS
    return cyl2d_modes(inp.theta0_deg; n_modes=n_modes, NY=inp.NY, c0=inp.c0)
end
