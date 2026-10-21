# I-15: convert author's WebPlotDigitizer exports to card schema CSVs (values unchanged).
# Run from anywhere: julia data/digitizers/convert_i15_author_exports.jl
# Uses only the Julia standard library.

const ROOT = normpath(joinpath(@__DIR__, ".."))
const PEREIRA = joinpath(ROOT, "pereira")
const BBN = joinpath(ROOT, "NASA_CR-159124")

"""Minimal CSV split that respects double-quoted fields (author WebPlotDigitizer exports)."""
function split_csv_line(line::AbstractString)
    fields = String[]
    i = firstindex(line)
    n = lastindex(line)
    while i <= n
        if line[i] == '"'
            i = nextind(line, i)
            buf = IOBuffer()
            while i <= n
                if line[i] == '"'
                    j = nextind(line, i)
                    if j <= n && line[j] == '"'
                        write(buf, '"'); i = nextind(line, j); continue
                    else
                        i = j
                        break
                    end
                end
                write(buf, line[i])
                i = nextind(line, i)
            end
            push!(fields, String(take!(buf)))
            if i <= n && line[i] == ','
                i = nextind(line, i)
            end
        else
            j = i
            while j <= n && line[j] != ','
                j = nextind(line, j)
            end
            push!(fields, strip(line[i:prevind(line, j)]))
            i = j <= n ? nextind(line, j) : j
        end
    end
    return fields
end

function read_table(path)
    lines = filter(!isempty, strip.(readlines(path)))
    header = split_csv_line(lines[1])
    rows = [split_csv_line(line) for line in lines[2:end]]
    return header, rows
end

function write_csv(path, headers::Vector{String}, colnames::Vector{String}, rows)
    open(path, "w") do io
        for h in headers
            println(io, startswith(h, "#") ? h : "# " * h)
        end
        println(io, join(colnames, ","))
        for r in rows
            println(io, join(r, ","))
        end
    end
    println("wrote ", path)
end

cell(v) = (v === nothing || v == "" || lowercase(String(v)) == "missing") ? "" : String(v)

function at(r, i)
    i > length(r) && return ""
    return cell(r[i])
end

function parse_f(s)
    s = strip(String(s))
    s == "" && return nothing
    return parse(Float64, s)
end

function fmt(v)
    v === nothing && return ""
    return string(v)
end

function convert_e16()
    _, rows = read_table(joinpath(ROOT, "Fig E-16.txt"))
    allrows = []
    for r in rows
        b = Int(parse_f(r[1]))
        push!(allrows, [string(b), at(r, 3), at(r, 4), at(r, 2), at(r, 5)])
    end
    hdr = [
        "# Source: CR-3813 Fig. E-16, PDF p. 142 (printed E-26), Pain Methodology.pdf",
        "# Method: author, WebPlotDigitizer; converted from data/Fig E-16.txt (I-15); values unchanged",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
        "# Conventions: dB re 20 µPa; space-average SPL; NASA PAIN = open circles where present",
        "# I-15 notes: (a)–(c) band alignment fixed in .txt before conversion (B-2)",
    ]
    write_csv(joinpath(ROOT, "e16_interior_all_bands_B.csv"), hdr,
              ["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"], allrows)
    want = Dict(200 => 1, 400 => 2, 630 => 3)
    tonal = []
    for r in allrows
        b = parse(Int, r[1])
        haskey(want, b) || continue
        f_Hz = b == 630 ? 600 : b
        push!(tonal, [string(want[b]), string(f_Hz), string(b), r[2], r[3], r[4], r[5]])
    end
    write_csv(joinpath(ROOT, "t1_interior_targets_B.csv"),
              vcat(hdr, ["# Schema: second pass of T1 targets (D-17); does not replace data/t1_interior_targets.csv"]),
              ["harmonic", "f_Hz", "band_Hz", "measured_mean_SPL_dB", "measured_low_dB", "measured_high_dB", "nasa_pain_pred_dB"],
              tonal)
end

function convert_e17()
    _, rows = read_table(joinpath(ROOT, "Fig E-17.txt"))
    out = [[string(Int(parse_f(r[1]))), at(r, 3), at(r, 2), at(r, 4), at(r, 5)] for r in rows]
    write_csv(joinpath(ROOT, "e17_interior_ci.csv"), [
        "# Source: CR-3813 Fig. E-17, PDF p. 143 (printed E-27), Pain Methodology.pdf",
        "# Method: author, WebPlotDigitizer; converted from data/Fig E-17.txt (I-15); values unchanged",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
        "# I-15: replaces void agent file (I-03)",
    ], ["band_Hz", "measured_mean_dB", "ci_low_dB", "ci_high_dB", "nasa_pred_dB"], out)
end

function convert_e18()
    _, rows = read_table(joinpath(ROOT, "Fig E-18.txt"))
    out = [[string(Int(parse_f(r[1]))), at(r, 5), at(r, 3), at(r, 2), at(r, 4)] for r in rows]
    write_csv(joinpath(ROOT, "e18_interior_pred_eta1.csv"), [
        "# Source: CR-3813 Fig. E-18, PDF p. 145 (printed E-29), Pain Methodology.pdf",
        "# Method: author, WebPlotDigitizer; converted from data/Fig E-18.txt (I-15); values unchanged",
        "# NOTE: η_T=1.0 predictions — NOT the reproduction target of 18b",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
        "# I-15 (b): band alignment fixed in .txt before conversion (B-2)",
    ], ["band_Hz", "nasa_pred_dB", "measured_mean_dB", "low_dB", "high_dB"], out)
end

function convert_e9_e10()
    _, rows = read_table(joinpath(ROOT, "Fig E-9.txt"))
    out9 = [[string(Int(parse_f(r[1]))), at(r, 3), at(r, 4), at(r, 2)] for r in rows]
    write_csv(joinpath(ROOT, "t2_third_octave_targets_B.csv"), [
        "# Source: CR-3813 Fig. E-9, PDF p. 132 (printed E-16), Pain Methodology.pdf",
        "# Method: author, WebPlotDigitizer; converted from data/Fig E-9.txt (I-15); values unchanged",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
        "# I-15 (a): band column fixed in .txt before conversion (B-2)",
    ], ["fc_Hz", "measured_mean_SPL_dB", "low_dB", "high_dB"], out9)
    _, rows10 = read_table(joinpath(ROOT, "Fig E-10.txt"))
    out10 = [[string(Int(parse_f(r[1]))), at(r, 3), at(r, 2), at(r, 4)] for r in rows10]
    write_csv(joinpath(ROOT, "e10_interior_ci.csv"), [
        "# Source: CR-3813 Fig. E-10, PDF p. 133 (printed E-17), Pain Methodology.pdf",
        "# Method: author, WebPlotDigitizer; converted from data/Fig E-10.txt (I-15); values unchanged",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
        "# I-15 (c): 250/315 Hz values swapped in .txt before conversion (B-2)",
    ], ["fc_Hz", "measured_mean_dB", "ci_low_dB", "ci_high_dB"], out10)
end

function convert_e21_e22()
    _, rows = read_table(joinpath(ROOT, "Fig E-21.txt"))
    out21 = [[string(Int(parse_f(r[1]))), at(r, 2), at(r, 4), at(r, 3), at(r, 5)] for r in rows]
    write_csv(joinpath(ROOT, "e21_noise_reduction_range.csv"), [
        "# Source: CR-3813 Fig. E-21, PDF p. 149 (printed E-33), Pain Methodology.pdf",
        "# Method: author, WebPlotDigitizer; converted from data/Fig E-21.txt (I-15); values unchanged",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
        "# I-15 (g): at 100 Hz minimum equals average (16 dB) as read; single author pass",
    ], ["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"], out21)
    _, rows22 = read_table(joinpath(ROOT, "Fig E-22.txt"))
    out22 = [[string(Int(parse_f(r[1]))), at(r, 2), at(r, 3), at(r, 4), at(r, 5)] for r in rows22]
    write_csv(joinpath(ROOT, "e22_noise_reduction_ci.csv"), [
        "# Source: CR-3813 Fig. E-22, PDF p. 150 (printed E-34), Pain Methodology.pdf",
        "# Method: author, WebPlotDigitizer; converted from data/Fig E-22.txt (I-15); values unchanged",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
    ], ["band_Hz", "measured_mean_dB", "low_dB", "high_dB", "nasa_pred_dB"], out22)
end

function convert_pereira_fig9()
    files = [(0, "a", "Pereira Fig. 9 Deg=0.txt"),
             (20, "b", "Pereira Fig. 9 Deg=20.txt"),
             (40, "c", "Pereira Fig. 9 Deg=40.txt")]
    out = []
    for (phi, panel, name) in files
        _, rows = read_table(joinpath(PEREIRA, name))
        for r in rows
            h = Int(parse_f(r[1]))
            bemt, num, expv = parse_f(r[2]), parse_f(r[3]), parse_f(r[4])
            d_num, d_exp = parse_f(r[5]), parse_f(r[6])
            flag = ""
            if h == 1 && bemt == 80 && num == 80 && expv == 80
                flag = "I-15(d): H1 bars read 80 dB all series; accepted by author 2026-10-21"
            end
            if abs(d_num) >= 10 || abs(d_exp) >= 10
                flag = isempty(flag) ? "Delta_SPL at frame limit (+/-10)" : flag * "; Delta_SPL at frame limit (+/-10)"
            end
            push!(out, [panel, string(phi), string(h), "BEMT", fmt(bemt), "0.0", flag])
            push!(out, [panel, string(phi), string(h), "Numerical", fmt(num), fmt(d_num), flag])
            push!(out, [panel, string(phi), string(h), "Experimental", fmt(expv), fmt(d_exp), flag])
        end
    end
    write_csv(joinpath(PEREIRA, "pereira_fig9_harmonics.csv"), [
        "# Source: Pereira et al., Aerosp. Sci. Technol. 177 (2026) 112963, Fig. 9, PDF p. 10",
        "# Method: author, WebPlotDigitizer; converted from Pereira Fig. 9 Deg=0/20/40.txt (I-15); values unchanged",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
        "# I-15 (d)/(e): H1=80 dB accepted as read; Fig. 8 = pereira_fig8_directivity.csv (pixel)",
    ], ["panel", "phi_deg", "harmonic", "series", "SPL_dB", "dSPL_vs_BEMT_dB", "flag"], out)
end

function convert_pereira_fig6()
    bpf = 2 * 8000 / 60
    files = [(0, "a", "Fig 6a.txt"), (20, "b", "Fig 6b.txt"), (40, "c", "Fig 6c.txt")]
    out = []
    for (phi, panel, name) in files
        _, rows = read_table(joinpath(PEREIRA, name))
        pts = [(parse_f(r[1]), parse_f(r[2]), parse_f(r[3]), parse_f(r[4])) for r in rows]
        for H in 1:4
            f0 = H * bpf
            for (series, idx) in [("BEMT", 2), ("Numerical", 3), ("Experimental", 4)]
                cands = [(p[1], p[idx]) for p in pts if abs(p[1] - f0) / f0 <= 0.05]
                if isempty(cands)
                    push!(out, [panel, string(phi), series, string(H), "", "", "no_point_within_5pct_of_mBPF"])
                else
                    f, v = cands[argmax(last.(cands))]
                    push!(out, [panel, string(phi), series, string(H), string(round(f; digits=3)), string(v), ""])
                end
            end
        end
    end
    write_csv(joinpath(PEREIRA, "pereira_fig6_peaks.csv"), [
        "# Source: Pereira et al., Aerosp. Sci. Technol. 177 (2026) 112963, Fig. 6, PDF p. 7",
        "# Method: author curve export; peaks = max in +/-5% of m*BPF (BPF=266.667 Hz); curve values unchanged",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
    ], ["panel", "phi_deg", "series", "harmonic", "freq_Hz", "SPL_dB", "flag"], out)
end

function convert_bbn_fig19_20()
    _, rows = read_table(joinpath(BBN, "Fig 19.txt"))
    out19 = []
    for r in rows
        panel = strip(r[1])
        pair = panel == "a" ? "5-1" : "5-8"
        kt = Int(parse_f(r[2]))
        f_Hz = parse_f(r[4])
        phase_pi = parse_f(r[5])
        push!(out19, ["19", panel, pair, string(kt), string(f_Hz), string(phase_pi * π), string(phase_pi), strip(r[3]), "author_WebPlotDigitizer"])
    end
    write_csv(joinpath(BBN, "bbn_phase_vs_freq_fig19_longitudinal.csv"), [
        "# Source: NASA CR-159124 Fig. 19, longitudinal phase vs frequency",
        "# Method: author, WebPlotDigitizer; converted from Fig 19.txt (I-15); values unchanged",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
        "# Conventions: phase_rad = phase_units_of_pi * pi; pair a->5-1, b->5-8",
    ], ["figure", "panel", "pair", "taxi_speed_kt", "freq_Hz", "phase_rad", "phase_units_of_pi", "point_or_line", "method"], out19)

    _, rows20 = read_table(joinpath(BBN, "Fig 20.txt"))
    out20 = []
    for r in rows20
        pair = replace(strip(r[1]), "Microphone Pair " => "")
        kt = Int(parse_f(replace(strip(r[2]), " Knots" => "")))
        f_Hz = parse_f(r[3])
        phase_pi = parse_f(r[4])
        push!(out20, ["20", "-", pair, string(kt), string(f_Hz), string(phase_pi * π), string(phase_pi), "Point", "author_WebPlotDigitizer"])
    end
    write_csv(joinpath(BBN, "bbn_phase_vs_freq_fig20_longitudinal.csv"), [
        "# Source: NASA CR-159124 Fig. 20, longitudinal phase vs frequency",
        "# Method: author, WebPlotDigitizer; converted from Fig 20.txt (I-15); values unchanged",
        "# Digitized 2026-10-21 by author; converted 2026-10-21; script data/digitizers/convert_i15_author_exports.jl",
    ], ["figure", "panel", "pair", "taxi_speed_kt", "freq_Hz", "phase_rad", "phase_units_of_pi", "point_or_line", "method"], out20)
end

convert_e16(); convert_e17(); convert_e18(); convert_e9_e10()
convert_e21_e22(); convert_pereira_fig9(); convert_pereira_fig6()
convert_bbn_fig19_20()
println("I-15 conversion complete")
