# Phase 34b — CairoMakie plots for validation cases (no QML plotting logic).

const _ERROR_MARKERS = (:circle, :rect, :diamond, :utriangle, :dtriangle, :cross, :xcross, :star5)
const _COMPUTED_COLORS = (:firebrick, :darkorange, :mediumblue, :seagreen, :purple, :saddlebrown, :teal, :crimson)
const _MAX_DATA_LEGEND = 10
const _MAX_ERROR_GROUP_LEGEND = 8

function _error_ylabel(spec::PlotSpec)
    isempty(spec.error_ylabel) || return spec.error_ylabel
    if spec.error_mode === :relative_pct
        return "error (%)"
    elseif spec.error_mode === :db_ratio
        return "error (dB)"
    else
        return "computed − reference"
    end
end

"""Error-panel x label: optional `error_xlabel`, else main-panel `xlabel`."""
function _error_xlabel(spec::PlotSpec)
    spec.error_xlabel === nothing && return spec.xlabel
    return spec.error_xlabel
end

"""Per-panel axis label; empty/missing entry falls back to `spec.xlabel` / `spec.ylabel`."""
function _panel_xlabel(spec::PlotSpec, p::Int)
    if p <= length(spec.panel_xlabels) && !isempty(spec.panel_xlabels[p])
        return spec.panel_xlabels[p]
    end
    return spec.xlabel
end

function _panel_ylabel(spec::PlotSpec, p::Int)
    if p <= length(spec.panel_ylabels) && !isempty(spec.panel_ylabels[p])
        return spec.panel_ylabels[p]
    end
    return spec.ylabel
end

"""Per-panel axis limits; missing/nothing entry falls back to `spec.xlim` / `spec.ylim`."""
function _panel_xlim(spec::PlotSpec, p::Int)
    if p <= length(spec.panel_xlims) && spec.panel_xlims[p] !== nothing
        return spec.panel_xlims[p]
    end
    return spec.xlim
end

function _panel_ylim(spec::PlotSpec, p::Int)
    if p <= length(spec.panel_ylims) && spec.panel_ylims[p] !== nothing
        return spec.panel_ylims[p]
    end
    return spec.ylim
end

"""Parse `M=0.4` (etc.) from a series name for Mach-matched colours."""
function _mach_from_series_name(name::AbstractString)
    m = match(r"M\s*=\s*([0-9]+(?:\.[0-9]+)?)", String(name))
    m === nothing && return nothing
    return parse(Float64, m.captures[1])
end

"""Parse `α=3.77` / `alpha=3.77` from a series name for α-matched colours (POLAR_R996 panel 4)."""
function _alpha_from_series_name(name::AbstractString)
    m = match(r"(?:α|alpha)\s*=\s*([-+]?[0-9]+(?:\.[0-9]+)?)", String(name))
    m === nothing && return nothing
    return parse(Float64, m.captures[1])
end

"""Assign a stable palette colour for one α; first-seen order."""
function _color_for_alpha!(alpha_colors::Dict{Float64,Symbol}, alpha_order::Vector{Float64}, α::Float64)
    if !haskey(alpha_colors, α)
        push!(alpha_order, α)
        alpha_colors[α] = _COMPUTED_COLORS[mod1(length(alpha_order), length(_COMPUTED_COLORS))]
    end
    return alpha_colors[α]
end

function _row_error(row::ValidationTableRow, mode::Symbol)
    if mode === :absolute
        # Prefer the stored residual (phase cases store a wrapped residual).
        return row.residual
    elseif mode === :relative_pct
        return 100 * (row.computed - row.reference) / row.reference
    elseif mode === :db_ratio
        return 20 * log10(row.computed / row.reference)
    else
        return NaN
    end
end

"""Round log10 tick candidates (R996 Fig. 14 and similar pressure axes)."""
const _LOG_ROUND_TICKS = Float64[
    1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000,
]

"""Plain tick labels for log10 axes; prefer a few round ticks when the span is wide."""
function _apply_log_ticks!(ax, vals; dim::Symbol=:x)
    finite = filter(isfinite, Float64.(vals))
    isempty(finite) && return
    lo, hi = extrema(finite)
    round_ticks = filter(t -> t >= lo / 1.2 && t <= hi * 1.2, _LOG_ROUND_TICKS)
    nums = if length(round_ticks) >= 3
        round_ticks
    else
        nums = sort(unique(finite))
        if length(nums) > 12
            step = ceil(Int, length(nums) / 12)
            nums = nums[1:step:end]
        end
        nums
    end
    labels = string.(round.(nums; sigdigits=4))
    if all(v -> isfinite(v) && abs(v - round(v)) < 1e-9 * max(1.0, abs(v)), nums)
        labels = string.(round.(Int, nums))
    end
    if dim === :x
        ax.xticks = (nums, labels)
    else
        ax.yticks = (nums, labels)
    end
end

"""Plot kwargs: omit `label` entirely when empty so Makie does not add a blank legend entry."""
_legend_kw(label::AbstractString) = isempty(label) ? (;) : (; label=String(label))

function _percentile(v::Vector{Float64}, p::Float64)
    isempty(v) && return NaN
    s = sort(v)
    n = length(s)
    n == 1 && return s[1]
    t = clamp(p, 0.0, 1.0) * (n - 1) + 1
    i = floor(Int, t)
    f = t - i
    i >= n && return s[n]
    return s[i] * (1 - f) + s[i + 1] * f
end

function _error_ylims(errs::Vector{Float64}, tol::Union{Nothing,Float64})
    finite = filter(isfinite, errs)
    isempty(finite) && return nothing, false
    abs_e = abs.(finite)
    p99 = _percentile(abs_e, 0.99)
    floor_half = tol === nothing ? 0.0 : 2 * tol
    half = max(floor_half, p99, 1e-12)
    # "clipped" when at least one point lies outside the p99-based window.
    clipped = maximum(abs_e) > half + 1e-12
    return (-half, half), clipped
end

"""
    plot_case(result, spec; path=nothing) -> String

Render `result.series` to PNG (and PDF) under `docs/validation_reports/figures/<id>.png`
unless `path` is given. Returns the PNG path. Empty series writes a placeholder image.
"""
function plot_case(result::ValidationCaseResult, spec::PlotSpec; path::Union{Nothing,AbstractString}=nothing)
    out_dir = joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "figures")
    mkpath(out_dir)
    png = path === nothing ? joinpath(out_dir, "$(result.id).png") : String(path)
    pdf = replace(png, r"\.png$"i => ".pdf")

    n_panels = max(1, maximum(s.panel for s in result.series; init=1))
    # Display cases may stash per-run titles on inputs_echo.panel_titles (e.g. Re / section).
    echo_titles = (:panel_titles in propertynames(result.inputs_echo)) ?
        collect(String, result.inputs_echo.panel_titles) : String[]
    if !isempty(echo_titles)
        titles = echo_titles
    elseif isempty(spec.panel_titles)
        titles = ["panel $i" for i in 1:n_panels]
    else
        titles = copy(spec.panel_titles)
    end
    while length(titles) < n_panels
        push!(titles, "panel $(length(titles)+1)")
    end

    show_error = spec.error_mode !== :none && !isempty(result.table)
    fig_h = 320 * n_panels + (show_error ? 240 : 0)
    if isempty(result.series) && !show_error
        fig_h = max(fig_h, 360)
    end
    fig = Figure(size=(900, max(fig_h, 240)), fontsize=12)

    if isempty(result.series)
        ax = Axis(fig[1, 1]; title="$(result.id): $(result.verdict)",
                  xlabel=spec.xlabel, ylabel=spec.ylabel)
        text!(ax, 0.5, 0.5; text=isempty(result.reason) ? String(result.verdict) : result.reason,
              align=(:center, :center), space=:relative)
    else
        for p in 1:n_panels
            ax = Axis(fig[p, 1]; title=titles[p],
                      xlabel=_panel_xlabel(spec, p), ylabel=_panel_ylabel(spec, p),
                      xscale=spec.xscale === :log10 ? log10 : identity,
                      yscale=spec.yscale === :log10 ? log10 : identity)
            xlim_p = _panel_xlim(spec, p)
            ylim_p = _panel_ylim(spec, p)
            if xlim_p !== nothing
                xlims!(ax, xlim_p...)
            end
            if ylim_p !== nothing
                ylims!(ax, ylim_p...)
            end
            panel_xs = Float64[]
            panel_ys = Float64[]
            tol_drawn = false
            legend_n = 0
            computed_i = 0
            mach_colors = Dict{Float64,Symbol}()
            # POLAR_R996 panel 4: one colour per α shared by TN 1546 curve + XFOIL markers.
            alpha_colors = Dict{Float64,Symbol}()
            alpha_order = Float64[]
            use_alpha_legend = any(s -> s.panel == p && _alpha_from_series_name(s.name) !== nothing,
                                   result.series)
            alpha_legend_elems = Any[]
            alpha_legend_labs = String[]
            for s in result.series
                s.panel == p || continue
                append!(panel_xs, s.x)
                append!(panel_ys, s.y)
                Akey = _alpha_from_series_name(s.name)
                # α-matched series use a compact legend; suppress per-series labels.
                suppress_label = use_alpha_legend && (Akey !== nothing || s.kind === :reference_band)
                label = (suppress_label || legend_n >= _MAX_DATA_LEGEND) ? "" : s.name
                labeled = !isempty(label)
                lkw = _legend_kw(label)
                if s.kind === :reference_band && !isempty(s.ylow) && !isempty(s.yhigh)
                    band!(ax, s.x, s.ylow, s.yhigh; color=(:gray, 0.25), lkw...)
                    if use_alpha_legend
                        push!(alpha_legend_elems, PolyElement(color=(:gray, 0.25)))
                        push!(alpha_legend_labs, s.name)
                    else
                        labeled && (legend_n += 1)
                    end
                elseif s.kind === :reference_points
                    scatter!(ax, s.x, s.y; marker=:circle, markersize=10,
                             color=:transparent, strokewidth=1.5, strokecolor=:black, lkw...)
                    labeled && (legend_n += 1)
                    if !tol_drawn && spec.tolerance_band !== nothing && !isempty(s.y)
                        tol = spec.tolerance_band
                        tol_label = legend_n < _MAX_DATA_LEGEND ? "±tol (criterion)" : ""
                        band!(ax, s.x, s.y .- tol, s.y .+ tol;
                              color=(:steelblue, 0.12), _legend_kw(tol_label)...)
                        tol_drawn = true
                        !isempty(tol_label) && (legend_n += 1)
                    end
                elseif s.kind === :reference_curve
                    if Akey !== nothing
                        col = _color_for_alpha!(alpha_colors, alpha_order, Akey)
                        lines!(ax, s.x, s.y; color=col, linestyle=:dash, linewidth=2)
                    else
                        lines!(ax, s.x, s.y; color=:black, linestyle=:dash, lkw...)
                        labeled && (legend_n += 1)
                    end
                elseif s.kind === :computed
                    computed_i += 1
                    col = _COMPUTED_COLORS[mod1(computed_i, length(_COMPUTED_COLORS))]
                    Mkey = _mach_from_series_name(s.name)
                    Mkey !== nothing && (mach_colors[Mkey] = col)
                    lines!(ax, s.x, s.y; color=col, linewidth=2, lkw...)
                    scatter!(ax, s.x, s.y; marker=:circle, markersize=8, color=col)
                    labeled && (legend_n += 1)
                elseif s.kind === :computed_points
                    # Markers only (phase / single-station) — no connecting lines across wraps.
                    if Akey !== nothing
                        col = _color_for_alpha!(alpha_colors, alpha_order, Akey)
                        scatter!(ax, s.x, s.y; marker=:circle, markersize=10, color=col)
                    else
                        computed_i += 1
                        col = _COMPUTED_COLORS[mod1(computed_i, length(_COMPUTED_COLORS))]
                        scatter!(ax, s.x, s.y; marker=:circle, markersize=10, color=col, lkw...)
                        labeled && (legend_n += 1)
                    end
                elseif s.kind === :inside_points
                    # Coverage / in-grid markers (display cases) — neutral steel blue.
                    scatter!(ax, s.x, s.y; marker=:circle, markersize=10, color=:steelblue, lkw...)
                    labeled && (legend_n += 1)
                elseif s.kind === :outside_points
                    # Coverage / out-of-grid markers (display cases) — always red.
                    scatter!(ax, s.x, s.y; marker=:circle, markersize=10, color=:red, lkw...)
                    labeled && (legend_n += 1)
                elseif s.kind === :measured_points
                    # Digitized airfoil overlay; colour matches XFOIL series of the same Mach when present.
                    Mkey = _mach_from_series_name(s.name)
                    col = (Mkey !== nothing && haskey(mach_colors, Mkey)) ?
                        mach_colors[Mkey] : :gray40
                    scatter!(ax, s.x, s.y; marker=:diamond, markersize=12, color=col,
                             strokewidth=1, strokecolor=:black, lkw...)
                    labeled && (legend_n += 1)
                elseif s.kind === :colored_scatter
                    # x,y = plane coordinates; ylow = scalar colour (e.g. incidence γ).
                    cvals = isempty(s.ylow) ? fill(0.0, length(s.x)) : s.ylow
                    sc = scatter!(ax, s.x, s.y; marker=:circle, markersize=10,
                                  color=cvals, colormap=:viridis, lkw...)
                    labeled && (legend_n += 1)
                    Colorbar(fig[p, 3], sc; label=isempty(s.name) ? "value" : s.name, labelsize=10)
                else
                    scatter!(ax, s.x, s.y; lkw...)
                    labeled && (legend_n += 1)
                end
            end
            if use_alpha_legend && !isempty(alpha_order)
                for α in alpha_order
                    length(alpha_legend_labs) >= _MAX_DATA_LEGEND && break
                    col = alpha_colors[α]
                    push!(alpha_legend_elems, [
                        LineElement(color=col, linestyle=:dash, linewidth=2),
                        MarkerElement(marker=:circle, color=col, markersize=10),
                    ])
                    push!(alpha_legend_labs, "α=$(α)°: line=TN 1546, dots=XFOIL")
                end
            end
            if spec.xscale === :log10
                _apply_log_ticks!(ax, panel_xs; dim=:x)
            end
            if spec.yscale === :log10
                _apply_log_ticks!(ax, panel_ys; dim=:y)
            end
            if !isempty(alpha_legend_labs)
                Legend(fig[p, 2], alpha_legend_elems, alpha_legend_labs;
                       framevisible=false, labelsize=10)
            elseif legend_n > 0
                Legend(fig[p, 2], ax; framevisible=false, labelsize=10)
            end
        end
    end

    if show_error
        err_row = isempty(result.series) ? 1 : n_panels + 1
        errs = Float64[]
        for row in result.table
            e = _row_error(row, spec.error_mode)
            isfinite(e) && isfinite(row.x) && push!(errs, e)
        end
        ylim_e, clipped = _error_ylims(errs, spec.error_tol)
        title_e = "error per point (green = within criterion)"
        clipped && (title_e *= " — clipped")
        # When error_xlabel is set, error-panel x is not the main-panel coordinate:
        # keep linear scale and do not inherit main xlim / log ticks.
        err_same_x = spec.error_xlabel === nothing
        ax_e = Axis(fig[err_row, 1];
                    title=title_e,
                    xlabel=_error_xlabel(spec), ylabel=_error_ylabel(spec),
                    xscale=(err_same_x && spec.xscale === :log10) ? log10 : identity)
        if err_same_x && spec.xlim !== nothing
            xlims!(ax_e, spec.xlim...)
        end
        if ylim_e !== nothing
            ylims!(ax_e, ylim_e...)
        end

        err_xs = Float64[]
        for row in result.table
            e = _row_error(row, spec.error_mode)
            isfinite(e) && isfinite(row.x) || continue
            push!(err_xs, row.x)
        end

        hlines!(ax_e, [0.0]; color=:gray, linestyle=:dash, linewidth=1)
        if spec.error_tol !== nothing && !isempty(err_xs)
            tol = spec.error_tol
            xlo, xhi = (err_same_x && spec.xlim !== nothing) ? spec.xlim : extrema(err_xs)
            band!(ax_e, [xlo, xhi], [-tol, -tol], [tol, tol]; color=(:steelblue, 0.12))
            hlines!(ax_e, [-tol, tol]; color=:steelblue, linestyle=:dash, linewidth=1)
        end

        groups = String[]
        for row in result.table
            e = _row_error(row, spec.error_mode)
            isfinite(e) && isfinite(row.x) || continue
            g = isempty(row.group) ? _error_quantity_group(row.quantity) : row.group
            gi = findfirst(==(g), groups)
            if gi === nothing
                push!(groups, g)
                gi = length(groups)
            end
            mk = _ERROR_MARKERS[mod1(gi, length(_ERROR_MARKERS))]
            col = row.within_tolerance ? :green : :red
            scatter!(ax_e, [row.x], [e]; marker=mk, markersize=10, color=col)
        end
        if err_same_x && spec.xscale === :log10
            _apply_log_ticks!(ax_e, err_xs; dim=:x)
        end
        if !isempty(groups)
            # Cap quantity-group legend entries; always keep within/outside.
            elems = Any[]
            labs = String[]
            for (i, g) in enumerate(groups)
                i > _MAX_ERROR_GROUP_LEGEND && break
                mk = _ERROR_MARKERS[mod1(i, length(_ERROR_MARKERS))]
                push!(elems, MarkerElement(marker=mk, color=:gray40, markersize=10))
                push!(labs, g)
            end
            push!(elems, MarkerElement(marker=:circle, color=:green, markersize=10))
            push!(labs, "within criterion")
            push!(elems, MarkerElement(marker=:circle, color=:red, markersize=10))
            push!(labs, "outside")
            Legend(fig[err_row, 2], elems, labs; framevisible=false, labelsize=10)
        end
    end

    save(png, fig)
    try
        save(pdf, fig)
    catch
        # PDF optional if backend rejects a path
    end
    return abspath(png)
end

"""Published / digitized source pages for the GUI “source figure” panel (paths relative to `rea-work/`)."""
const VALIDATION_SOURCE_FIGURE_FALLBACKS = Dict{String,String}(
    "T1" => "data/cr3813/pages/e16-142.png",
    "REPRO_18b" => "data/cr3813/pages/e16-142.png",
    "T2" => "data/cr3813/pages/e9-132.png",
    "E11_FREEFIELD" => "data/cr3813/pages/e11-135.png",
    "E12_BLOCK" => "data/cr3813/pages/e11_next-136.png",
    "E14_LOSS" => "data/cr3813/pages/e14-139.png",
    "E15_STRUCT_LOSS" => "data/cr3813/pages/e15-141.png",
    "R996_FIG12" => "data/report996/qa/fig12a_overlay.png",
    "R996_FIG13A" => "data/report996/qa/fig13a_overlay.png",
    "R996_FIG14" => "data/report996/qa/fig14a_overlay.png",
    "PER_FIG6" => "data/pereira/qa/pereira_fig6_overlay.png",
    "PER_FIG7" => "data/pereira/qa/pereira_fig7_overlay.png",
    "PER_FIG8" => "data/pereira/qa/pereira_fig8_overlay.png",
    "PER_FIG9" => "data/pereira/qa/pereira_fig9_overlay.png",
)

"""Default figure path for a case id."""
validation_figure_path(id::AbstractString) =
    abspath(joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "figures", "$(id).png"))

function validation_source_figure_path(id::AbstractString)
    preferred = abspath(joinpath(@__DIR__, "..", "..", "docs", "validation_reports",
                                 "figures", "source", "$(id).png"))
    isfile(preferred) && return preferred
    rel = get(VALIDATION_SOURCE_FIGURE_FALLBACKS, String(id), nothing)
    if rel !== nothing
        fallback = abspath(joinpath(@__DIR__, "..", "..", rel))
        isfile(fallback) && return fallback
    end
    return preferred
end
