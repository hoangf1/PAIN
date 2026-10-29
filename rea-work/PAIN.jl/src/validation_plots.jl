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

"""Format |err| for chip / summary text (2 significant figures)."""
_fmt_err_sig(x::Real) = string(round(Float64(x); sigdigits=2))

"""Text inside the last `(...)` of a label, or `nothing` if absent/empty."""
function _unit_in_parens(label::AbstractString)
    isempty(label) && return nothing
    last = nothing
    for m in eachmatch(r"\(([^()]*)\)", String(label))
        last = m
    end
    last === nothing && return nothing
    u = strip(last.captures[1])
    return isempty(u) ? nothing : u
end

"""Unit for `:absolute` error chips: last `(...)` of `error_ylabel`, else of `ylabel`, else `abs`."""
function _absolute_error_unit(spec::PlotSpec)
    u = _unit_in_parens(spec.error_ylabel)
    u !== nothing && return u
    u = _unit_in_parens(spec.ylabel)
    u !== nothing && return u
    return "abs"
end

"""Short chip label from a full error summary (fits ~130 px with a date line below)."""
function _error_chip_text(; text::AbstractString, n_within::Int, n_rows::Int,
                          max_abs::Float64, unit::AbstractString)
    t = String(text)
    (t == "no criterion" || occursin("within criterion", t)) && return t
    if startswith(t, "no verdict")
        isfinite(max_abs) || return "no verdict"
        u = isempty(unit) ? "" : " $(unit)"
        return "no verdict · $(_fmt_err_sig(max_abs))$(u) max"
    end
    isfinite(max_abs) || return "$(n_within)/$(n_rows)"
    u = isempty(unit) ? "" : " $(unit)"
    return "$(n_within)/$(n_rows) · $(_fmt_err_sig(max_abs))$(u) max"
end

"""Information row (no tolerance applies): its label or group carries "(info" (Phase 79a)."""
_is_info_row(r::ValidationTableRow) = occursin("(info", r.quantity) || occursin("(info", r.group)

"""
    case_error_summary(result, spec) -> NamedTuple

Display-only error roll-up for the Validation map. Uses `_row_error` / `_error_ylabel`
exactly as the error panel; does not change criteria or verdicts.
`n_within` / `n_rows` count the criterion rows; max/median use their finite `_row_error` only. Information rows
(label or group marked "(info", `_is_info_row`) stay in the table and figure but leave the roll-up (Phase 79a), so the
chip agrees with the verdict; a table with only information rows is rolled up whole, as before.
"""
function case_error_summary(result::ValidationCaseResult, spec::PlotSpec)
    crit = filter(!_is_info_row, result.table)
    rows = isempty(crit) ? result.table : crit
    # :none with a met/not_met verdict and a non-empty table → coverage-style count only.
    if spec.error_mode === :none
        if !isempty(rows) && (result.verdict === :met || result.verdict === :not_met)
            n_within = count(r -> r.within_tolerance, rows)
            n_rows = length(rows)
            text = "$(n_within)/$(n_rows) within criterion"
            chip_text = text
            return (; n_within, n_rows, max_abs=NaN, median_abs=NaN, unit="", text, chip_text)
        end
        return (; n_within=0, n_rows=0, max_abs=NaN, median_abs=NaN, unit="",
                text="no criterion", chip_text="no criterion")
    end

    n_within = count(r -> r.within_tolerance, rows)
    n_rows = length(rows)
    errs = Float64[]
    for row in rows
        e = _row_error(row, spec.error_mode)
        isfinite(e) && push!(errs, e)
    end
    unit = if spec.error_mode === :relative_pct
        "%"
    elseif spec.error_mode === :db_ratio
        "dB"
    elseif spec.error_mode === :absolute
        _absolute_error_unit(spec)
    else
        ""
    end
    max_abs = isempty(errs) ? NaN : maximum(abs, errs)
    med_abs = isempty(errs) ? NaN : Statistics.median(abs.(errs))
    text = if isempty(result.table)
        "no criterion"
    elseif result.verdict === :no_verdict
        "no verdict · max |err| $(_fmt_err_sig(max_abs)) $(unit) · med $(_fmt_err_sig(med_abs)) $(unit)"
    else
        "$(n_within)/$(n_rows) in tol · max |err| $(_fmt_err_sig(max_abs)) $(unit) · med $(_fmt_err_sig(med_abs)) $(unit)"
    end
    chip_text = _error_chip_text(; text, n_within, n_rows, max_abs, unit)
    return (; n_within, n_rows, max_abs, median_abs=med_abs, unit, text, chip_text)
end

"""Default path for the case-error snapshot CSV (not written by run / Pkg.test)."""
case_error_summary_path() =
    joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "case_error_summary.csv")

"""Cache: (abspath, mtime, dict). Re-read only when the file mtime changes."""
const _RECORDED_ERRORS_CACHE =
    Ref{Union{Nothing,Tuple{String,Float64,Dict{String,NamedTuple}}}}(nothing)

"""
    write_case_error_summary(path; run_date) -> String

Run every registered case and write the display-only error snapshot CSV.
Comment line records generation date and script. Does not change criteria.
`run_date` is the snapshot date; `source_date` is each result's own `date` field.
"""
function write_case_error_summary(path::AbstractString=case_error_summary_path();
                                  run_date::AbstractString=string(Dates.today()))
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# generated ", run_date, " by scripts/run/write_case_error_summary.jl")
        println(io, "id,run_date,source_date,verdict,n_within,n_rows,max_abs,median_abs,unit,text")
        for id in VALIDATION_CASE_ORDER
            case = VALIDATION_CASES[id]
            result = run_validation_case(id)
            s = case_error_summary(result, case.plot_spec)
            max_s = isfinite(s.max_abs) ? _fmt_err_sig(s.max_abs) : ""
            med_s = isfinite(s.median_abs) ? _fmt_err_sig(s.median_abs) : ""
            text_q = "\"" * replace(s.text, "\"" => "\"\"") * "\""
            unit_q = "\"" * replace(s.unit, "\"" => "\"\"") * "\""
            println(io, id, ",", run_date, ",", result.date, ",", String(result.verdict), ",",
                    s.n_within, ",", s.n_rows, ",", max_s, ",", med_s, ",",
                    unit_q, ",", text_q)
        end
    end
    # Invalidate cache so the next load sees the new file.
    _RECORDED_ERRORS_CACHE[] = nothing
    return String(path)
end

"""Parse one snapshot data row; throws on malformed fields."""
function _parse_recorded_error_row(fields::Vector{String}, col::Dict{String,Int})
    id = String(fields[col["id"]])
    isempty(id) && error("empty id")
    max_s = strip(fields[col["max_abs"]])
    med_s = strip(fields[col["median_abs"]])
    max_abs = isempty(max_s) ? NaN : parse(Float64, max_s)
    median_abs = isempty(med_s) ? NaN : parse(Float64, med_s)
    n_within = parse(Int, fields[col["n_within"]])
    n_rows = parse(Int, fields[col["n_rows"]])
    unit = String(fields[col["unit"]])
    text = String(fields[col["text"]])
    run_date = String(fields[col["run_date"]])
    # Old CSVs omit source_date → fall back to run_date (snapshot date).
    source_date = haskey(col, "source_date") ? String(fields[col["source_date"]]) : run_date
    chip_text = _error_chip_text(; text, n_within, n_rows, max_abs, unit)
    return id, (;
        run_date=run_date,
        source_date=source_date,
        verdict=String(fields[col["verdict"]]),
        n_within=n_within,
        n_rows=n_rows,
        max_abs=max_abs,
        median_abs=median_abs,
        unit=unit,
        text=text,
        chip_text=chip_text,
    )
end

"""Load snapshot CSV from disk (no cache). Missing / bad header → empty Dict."""
function _load_recorded_case_errors(path::AbstractString)
    out = Dict{String,NamedTuple}()
    isfile(path) || return out
    lines = readlines(path)
    header_i = findfirst(l -> !startswith(strip(l), "#") && !isempty(strip(l)), lines)
    header_i === nothing && return out
    headers = _csv_split_row(strip(lines[header_i]))
    col = Dict(String(h) => i for (i, h) in enumerate(headers))
    required = ("id", "run_date", "verdict", "n_within", "n_rows", "max_abs", "median_abs", "unit", "text")
    all(h -> haskey(col, h), required) || return out
    skipped = 0
    for line in lines[(header_i + 1):end]
        strip(line) == "" && continue
        startswith(strip(line), "#") && continue
        try
            fields = _csv_split_row(line)
            length(fields) < length(headers) && error("too few fields")
            id, row = _parse_recorded_error_row(fields, col)
            out[id] = row
        catch
            skipped += 1
        end
    end
    if skipped > 0
        @warn "recorded_case_errors: skipped malformed rows" path=String(path) skipped
    end
    return out
end

"""
    recorded_case_errors(path=case_error_summary_path()) -> Dict{String,NamedTuple}

Load the snapshot CSV (cached by path + mtime). Missing or bad header → empty Dict.
Malformed data rows are skipped (warned); other rows still load.
"""
function recorded_case_errors(path::AbstractString=case_error_summary_path())
    ap = abspath(path)
    mt = isfile(ap) ? mtime(ap) : 0.0
    c = _RECORDED_ERRORS_CACHE[]
    if c !== nothing && c[1] == ap && c[2] == mt
        return c[3]
    end
    out = try
        _load_recorded_case_errors(ap)
    catch
        Dict{String,NamedTuple}()
    end
    _RECORDED_ERRORS_CACHE[] = (ap, mt, out)
    return out
end

"""Resolve display error text + source for map / case JSON (session first, then snapshot)."""
function _case_error_json_fields(id::AbstractString;
                                 session::AbstractDict=Dict{String,NamedTuple}(),
                                 recorded::AbstractDict=Dict{String,NamedTuple}())
    sid = String(id)
    if haskey(session, sid)
        s = session[sid]
        chip = hasproperty(s, :chip_text) ? String(s.chip_text) : String(s.text)
        return (error=String(s.text), error_chip=chip, error_source="run", error_snapshot="")
    elseif haskey(recorded, sid)
        r = recorded[sid]
        src_date = hasproperty(r, :source_date) ? String(r.source_date) : String(r.run_date)
        chip = hasproperty(r, :chip_text) ? String(r.chip_text) :
               _error_chip_text(; text=String(r.text), n_within=Int(r.n_within),
                                n_rows=Int(r.n_rows), max_abs=Float64(r.max_abs),
                                unit=String(r.unit))
        return (error=String(r.text), error_chip=chip,
                error_source="recorded $(src_date)",
                error_snapshot="snapshot $(r.run_date)")
    else
        return (error="", error_chip="", error_source="", error_snapshot="")
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

# True when the case is judged against a criterion; a no-verdict figure draws no tolerance band or within/outside colours.
_has_criterion(result) = result.verdict !== :no_verdict

"""
    plot_case(result, spec; path=nothing) -> String

Render `result.series` to PNG (and PDF) at `validation_figure_path(id)`
(`docs/validation_reports/figures/<block folder>/<id>.png`) unless `path` is given. Returns the PNG path. Empty series writes a placeholder image.
"""
function plot_case(result::ValidationCaseResult, spec::PlotSpec; path::Union{Nothing,AbstractString}=nothing)
    png = path === nothing ? validation_figure_path(result.id) : String(path)
    mkpath(dirname(png))
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
    # A no-verdict case has no criterion: draw no tolerance band (2026-10-28 label fix)
    has_crit = _has_criterion(result)
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
                    if has_crit && !tol_drawn && spec.tolerance_band !== nothing && !isempty(s.y)
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
        # no criterion (no_verdict): grey points, no within/outside legend (2026-10-28 label fix)
        crit_e = has_crit
        title_e = crit_e ? "error per point (green = within criterion)" : "error per point (no criterion)"
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
        if crit_e && spec.error_tol !== nothing && !isempty(err_xs)
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
            col = !crit_e ? :gray40 : row.within_tolerance ? :green : :red
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
            if crit_e
                push!(elems, MarkerElement(marker=:circle, color=:green, markersize=10))
                push!(labs, "within criterion")
                push!(elems, MarkerElement(marker=:circle, color=:red, markersize=10))
                push!(labs, "outside")
            end
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

"""Figure folder of each validation-map block (one folder per block, as on the map)."""
const VALIDATION_FIGURE_DIRS = Dict{String,String}(
    "A_GEO" => "Aircraft_inputs", "A_LOADS" => "CCBlade_BEMT", "X_F1A" => "F1A_source",
    "X_FF" => "Free_field_p", "A_AMP" => "F1A_amplitude", "A_PHASE" => "F1A_phase",
    "A_FWD" => "Forward_flight", "A_SURF" => "Surface_levels", "A_CABIN" => "Aircraft_cabin",
    "P_FF" => "e11_free_field", "X_SRC" => "Source_select", "P_GRID" => "Grid_160_point",
    "P_BLK" => "Blocking_Eq43", "X_BLK_OUT" => "Blocked_pressures",
    "X_MRP_IN" => "Structure_inputs", "P_MRP" => "Structural_modes", "X_MRP_OUT" => "Modes_fr_psir",
    "X_CYL_IN" => "Cabin_geometry", "P_CYL" => "CYL2D", "X_CYL_OUT" => "Modes_PhiG",
    "X_TRIM_IN" => "Trim_stack", "P_TRIM" => "Trim_and_loss", "X_TRIM_OUT" => "Trim_tau_eta",
    "X_PAIN_IN" => "Cabin_inputs", "P_EQ8" => "Coupling_Eq8", "X_OUT" => "Interior_SPL",
    "P_REPRO" => "vs_NASA_PAIN", "P_MEAS" => "vs_measurement",
)

_validation_figures_root() = abspath(joinpath(@__DIR__, "..", "..", "docs", "validation_reports", "figures"))

"""Folder of a case's figures: the folder of its map block; the figures root for an unregistered id."""
function validation_figure_dir(id::AbstractString)
    root = _validation_figures_root()
    info = get(CASE_INFO, String(id), nothing)
    info === nothing && return root
    sub = get(VALIDATION_FIGURE_DIRS, info.block_id, nothing)
    return sub === nothing ? root : joinpath(root, sub)
end

"""Default figure path for a case id: `figures/<block folder>/<id>.png`."""
validation_figure_path(id::AbstractString) = joinpath(validation_figure_dir(id), "$(id).png")

"""
    validation_figure_stale(id; png, recorded) -> Bool

Phase 75b: true when the case's saved figure was written before the day its row in the error snapshot
(`case_error_summary.csv`, `run_date`) was recorded, i.e. the map chip is newer than the picture the GUI shows on
selection. Day resolution; false when either is missing.
"""
function validation_figure_stale(id::AbstractString; png::AbstractString=validation_figure_path(id),
                                 recorded::AbstractDict=recorded_case_errors())
    isfile(png) || return false
    r = get(recorded, String(id), nothing)
    r === nothing && return false
    d = tryparse(Date, String(r.run_date))
    d === nothing && return false
    return Date(unix2datetime(mtime(png))) < d
end

function validation_source_figure_path(id::AbstractString)
    preferred = joinpath(validation_figure_dir(id), "source", "$(id).png")
    isfile(preferred) && return preferred
    rel = get(VALIDATION_SOURCE_FIGURE_FALLBACKS, String(id), nothing)
    if rel !== nothing
        fallback = abspath(joinpath(@__DIR__, "..", "..", rel))
        isfile(fallback) && return fallback
    end
    return preferred
end
