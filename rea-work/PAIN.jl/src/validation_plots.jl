# Phase 34b — CairoMakie plots for validation cases (no QML plotting logic).

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
    if isempty(spec.panel_titles)
        titles = ["panel $i" for i in 1:n_panels]
    else
        titles = copy(spec.panel_titles)
        while length(titles) < n_panels
            push!(titles, "panel $(length(titles)+1)")
        end
    end

    fig = Figure(size=(900, 360 * n_panels), fontsize=12)
    if isempty(result.series)
        ax = Axis(fig[1, 1]; title="$(result.id): $(result.verdict)",
                  xlabel=spec.xlabel, ylabel=spec.ylabel)
        text!(ax, 0.5, 0.5; text=isempty(result.reason) ? String(result.verdict) : result.reason,
              align=(:center, :center), space=:relative)
    else
        for p in 1:n_panels
            ax = Axis(fig[p, 1]; title=titles[p],
                      xlabel=spec.xlabel, ylabel=spec.ylabel,
                      xscale=spec.xscale === :log10 ? log10 : identity,
                      yscale=spec.yscale === :log10 ? log10 : identity)
            if spec.xlim !== nothing
                xlims!(ax, spec.xlim...)
            end
            if spec.ylim !== nothing
                ylims!(ax, spec.ylim...)
            end
            for s in result.series
                s.panel == p || continue
                if s.kind === :reference_band && !isempty(s.ylow) && !isempty(s.yhigh)
                    band!(ax, s.x, s.ylow, s.yhigh; color=(:gray, 0.25), label=s.name)
                elseif s.kind === :reference_points
                    scatter!(ax, s.x, s.y; marker=:circle, markersize=10,
                             color=:transparent, strokewidth=1.5, strokecolor=:black, label=s.name)
                    if spec.tolerance_band !== nothing && !isempty(s.y)
                        tol = spec.tolerance_band
                        band!(ax, s.x, s.y .- tol, s.y .+ tol; color=(:steelblue, 0.12), label="tol ±$tol")
                    end
                elseif s.kind === :reference_curve
                    lines!(ax, s.x, s.y; color=:black, linestyle=:dash, label=s.name)
                elseif s.kind === :computed
                    lines!(ax, s.x, s.y; color=:firebrick, linewidth=2, label=s.name)
                    scatter!(ax, s.x, s.y; marker=:circle, markersize=8, color=:firebrick)
                else
                    scatter!(ax, s.x, s.y; label=s.name)
                end
            end
            axislegend(ax; position=:rt, framevisible=false, labelsize=10)
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

"""Default figure path for a case id."""
validation_figure_path(id::AbstractString) =
    abspath(joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "figures", "$(id).png"))

validation_source_figure_path(id::AbstractString) =
    abspath(joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "figures", "source", "$(id).png"))
