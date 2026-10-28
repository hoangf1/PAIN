# Phase 62 — a proving case with its own figure for every validation-map block that had none.
# Criteria fixed 2026-10-23 (IMPLEMENTATION_PLAN.md §8i Phase 62) before any run.

const _P62_REPORT = "phase62_65_map_blocks_grid.md"
_p62_example(name) = joinpath(@__DIR__, "..", "examples", name)

# A failing case says so in its reason (the reason texts below state the measured quantity, not a claim).
function _p62_result(id, table, series, ok, reason, echo)
    return ValidationCaseResult(id, _today_iso(), merge((; date="2026-10-23"), echo), table, series,
        ok ? :met : :not_met, (ok ? "" : "criterion not met — ") * reason, "V-UNIT", joinpath(_VAL_REPORT_DIR, _P62_REPORT))
end

# X_F1A — F1A source: the H1 maximum of the aircraft example's free field lies on ℓ = 1 within ±1 station of k_p
function _run_f1a_plane_peak()
    json = _p62_example("aircraft_scale_hartzell.json")
    r = run_pain_pipeline(; source=:aircraft, aircraft_json=json, n_harmonics=2, trim=:bare)
    ff = propeller_freefield_grid(json, r.fuse, r.prop, GridSpec(); n_harmonics=2)
    A = ff.amplitudes[:, :, 1]
    idx = argmax(A); kmax, ℓmax = idx[1], idx[2]
    kp = GridSpec().k_p
    ok = ℓmax == 1 && abs(kmax - kp) ≤ 1
    table = [ValidationTableRow("H1 peak at k=$kmax, ℓ=$ℓmax (k_p = $kp)", Float64(kmax), Float64(kp), Float64(kmax),
                                Float64(kmax - kp), ok)]
    series = [PlotSeries("ℓ = $ℓ", :computed, collect(1.0:size(A, 1)), A[:, ℓ]; panel=1) for ℓ in (1, 3, 5, 10)]
    return _p62_result("F1A_PLANE_PEAK", table, series, ok,
        "H1 maximum at (k=$kmax, ℓ=$ℓmax); criterion ℓ = 1 and |k − k_p| ≤ 1", (; criterion="H1 peak on ℓ = 1 within ±1 of k_p", kmax, ℓmax))
end

# X_FF — free-field p: every off-line amplitude ≤ the ℓ = 1 amplitude at the same k (e11 field)
function _run_ff_e11_map()
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    paths = default_e11_paths()
    ff = freefield_from_e11_csv(paths.A, paths.phases, r.fuse, r.prop, GridSpec(); bpf_Hz=200.0, n_harmonics=3,
                                anopp_spl_csv=paths.anopp_spl, broadband_clip_dB=10.0)
    A = ff.amplitudes
    table = ValidationTableRow[]; n_bad = 0
    for H in 1:size(A, 3), k in 1:size(A, 1)
        worst = maximum(A[k, 2:end, H]); line = A[k, 1, H]
        ok = worst ≤ line * (1 + 1e-12)
        n_bad += !ok
        push!(table, ValidationTableRow("H$H k=$k max off-line / ℓ=1", Float64(k), line, worst, worst - line, ok))
    end
    series = [PlotSeries("H1 ℓ = $ℓ", :computed, collect(1.0:size(A, 1)), A[:, ℓ, 1]; panel=1) for ℓ in (1, 2, 4, 7, 10)]
    return _p62_result("FF_E11_MAP", table, series, n_bad == 0,
        "$(length(table) - n_bad)/$(length(table)) (H, k) with every off-line amplitude ≤ the ℓ = 1 amplitude", (; criterion="off-line ≤ line", n_bad))
end

# X_SRC — source select: the selected source's blocked grid reaches PainInputs unchanged
function _run_src_passthrough()
    table = ValidationTableRow[]; series = PlotSeries[]; n_bad = 0
    # :aircraft row added 2026-10-28 (Phase 70 F7, criterion unchanged: difference 0), before its first run.
    for (j, src) in enumerate((:e11, :synthetic, :aircraft))
        r = src === :aircraft ?
            run_pain_pipeline(; aircraft_json=_p62_example("aircraft_scale_hartzell.json"), n_harmonics=2, blocking=R2) :
            run_pain_pipeline(; source=src, use_synthetic=(src === :synthetic), n_harmonics=3, bpf_Hz=200.0, blocking=R2)
        d = maximum(abs, r.inputs.amplitudes .- r.ff.amplitudes) + maximum(abs, r.inputs.phases .- r.ff.phases)
        ok = d == 0.0; n_bad += !ok
        push!(table, ValidationTableRow("$src: max |PainInputs − blocked source|", Float64(j), 0.0, d, d, ok))
        push!(series, PlotSeries("$src H1 ℓ=1 (PainInputs)", :computed, collect(1.0:16), r.inputs.amplitudes[:, 1, 1]; panel=1))
    end
    return _p62_result("SRC_PASSTHROUGH", table, series, n_bad == 0, "selected source reaches the cabin unchanged for :e11, :synthetic and :aircraft (F1A)",
                       (; criterion="difference 0"))
end

# X_BLK_OUT — blocked pressures: 0 ≤ ΔL ≤ 20 log10 2 everywhere, R1 and R2
function _run_blk_gain_map()
    r = run_pain_pipeline(; source=:e11, n_harmonics=1, bpf_Hz=200.0, blocking=R2)
    lim = 20log10(2)
    table = ValidationTableRow[]; series = PlotSeries[]; n_bad = 0; bad = String[]
    for v in (R1, R2)
        γs = Float64[]; dLs = Float64[]
        for p in r.inputs.pts
            γ = incidence_angle_deg(r.fuse, r.prop, p.theta_deg, p.z)
            dL = delta_L_blocking_dB(γ; variant=v)
            push!(γs, γ); push!(dLs, dL)
        end
        ok = all(0 .≤ dLs .≤ lim + 1e-12); n_bad += !ok
        ok || push!(bad, "$v ΔL ∈ [$(round(minimum(dLs); digits=2)), $(round(maximum(dLs); digits=2))] dB")
        push!(table, ValidationTableRow("$v: ΔL range [$(round(minimum(dLs); digits=3)), $(round(maximum(dLs); digits=3))] dB", Float64(Int(v)),
                                        lim, maximum(dLs), maximum(dLs) - lim, ok))
        o = sortperm(γs)
        push!(series, PlotSeries("ΔL $v", :computed, γs[o], dLs[o]; panel=1))
    end
    return _p62_result("BLK_GAIN_MAP", table, series, n_bad == 0,
                       n_bad == 0 ? "blocked/free gain within 0…6.02 dB for R1 and R2 at every grid point" :
                                    "outside 0…6.02 dB on the grid: " * join(bad, "; "),
                       (; criterion="0 ≤ ΔL ≤ 20 log10 2"))
end

function _p62_printed()
    c = _read_csv_rows(_data_path("cr3813", "appE_article_inputs.csv"))
    hdr, rows = c
    col = Dict(h => i for (i, h) in enumerate(hdr))
    return Dict(r[col["quantity"]] => (parse(Float64, r[col["printed_value"]]), parse(Int, r[col["printed_digits"]]), r[col["page"]])
                for r in rows if length(r) ≥ length(hdr))
end
_p62_round(x, d) = x == 0 ? 0.0 : round(x; sigdigits=d)

function _p62_compare(id, pairs, title)
    P = _p62_printed()
    table = ValidationTableRow[]; n_bad = 0; xs = Float64[]; ys = Float64[]
    for (i, (q, code)) in enumerate(pairs)
        v, d, page = P[q]
        ok = _p62_round(code, d) == _p62_round(v, d); n_bad += !ok
        push!(table, ValidationTableRow("$q ($page)", Float64(i), v, code, code - v, ok))
        push!(xs, Float64(i)); push!(ys, v == 0 ? 0.0 : code / v)
    end
    series = [PlotSeries("code / printed", :computed, xs, ys; panel=1)]
    return _p62_result(id, table, series, n_bad == 0,
        "$(length(table) - n_bad)/$(length(table)) code values equal the CR-3813 App. E printed values to their printed digits ($title)",
        (; criterion="equal to printed digits", n_bad))
end

# X_MRP_IN — structure inputs vs App. E
function _run_mrp_input_qa()
    a = 0.508
    pr = run_pain_pipeline(; source=:e11, n_harmonics=1, bpf_Hz=200.0).prop
    return _p62_compare("MRP_INPUT_QA", [
        ("cylinder_length", test_article_length()), ("diameter", 2a), ("skin_thickness", MRP_T_SKIN),
        ("n_stringers", 2π * a / MRP_D_STRINGER), ("stringer_spacing_deg", rad2deg(MRP_D_STRINGER / a)),
        ("stringer_thickness", MRP_A_STRINGER / (0.00953 + 0.0112)), ("frame_spacing", MRP_ELL_FRAME),
        ("frame_thickness", MRP_A_FRAME / (2 * 0.017 + 0.038)), ("floor_thickness", MRP_T_SKIN),
        ("floor_width", 2a * sind(56.6)), ("floor_angle_deg", 56.6),
        ("prop_r_p", pr.r_p), ("prop_z_p", pr.z_p)], "structure and propeller placement")
end

# X_TRIM_IN — Phase III stack vs App. E p. E-9
function _run_trim_input_qa()
    p3 = phase3_trim(; η_lining=0.5)
    ins = [el for el in p3.sidewall.elements if el isa InsulationLayer]
    lm = [el for el in p3.sidewall.elements if el isa LimpMass]
    facing = lm[1].m
    endins = [el for el in p3.ends.elements if el isa InsulationLayer]
    P = _p62_printed()
    return _p62_compare("TRIM_INPUT_QA", [
        ("blanket_layer_thickness", ins[1].thickness), ("n_layers_curved", length(ins)), ("n_layers_end", length(endins)),
        ("layer_plus_facing_surface_density", facing + ins[1].thickness * P["blanket_density"][1]),
        ("septum_total_mass", p3.septum_mass_per_area * p3.A_curved), ("septum_thickness", p3.mech.h_t),
        ("n_trim_screws", p3.mech.N_points)], "Phase III trim")
end

# X_MRP_OUT — Table D-1 shapes are max-normalized: max |ψ| ≤ 1 + 1e-6
function _run_mrp_shape_norm()
    L = test_article_length(); a = 0.508; θ0 = 56.6
    sm = structural_modes_from_table_d1(; L, a, theta0_deg=θ0)
    Lp = 2a * sind(θ0)
    table = ValidationTableRow[]; n_bad = 0; series = PlotSeries[]
    θs = collect(θ0:2.0:(360 - θ0)); zs = collect(range(0, L; length=40)); xs = collect(range(-Lp / 2, Lp / 2; length=41))
    for st in sm.modes
        mx = max(maximum(abs(structural_shell_psi(st, z, θ, L)) for θ in θs, z in zs),
                 maximum(abs(structural_floor_psi(st, z, x, L, Lp)) for x in xs, z in zs; init=0.0))
        ok = mx ≤ 1 + 1e-6; n_bad += !ok
        push!(table, ValidationTableRow("mode $(st.index) max|ψ|", Float64(st.index), 1.0, mx, mx - 1, ok))
    end
    for st in sm.modes[1:6]
        push!(series, PlotSeries("mode $(st.index) ψ(θ) at z = L/2", :computed, θs, [structural_shell_psi(st, L / 2, θ, L) for θ in θs]; panel=1))
    end
    return _p62_result("MRP_SHAPE_NORM", table, series, n_bad == 0, "$(32 - n_bad)/32 Table D-1 shapes with max |ψ| ≤ 1 + 1e-6",
                       (; criterion="max|ψ| ≤ 1 + 1e-6", n_bad))
end

# X_CYL_IN — cabin geometry by hand
function _run_cabin_geom_hand()
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    a, L, θ0 = fuse.a, fuse.L, deg2rad(fuse.theta0_deg)
    # circle minus the segment below the floor chord at half-angle θ0 from the bottom
    V_hand = L * (π * a^2 - a^2 * (θ0 - sin(θ0) * cos(θ0)))
    A_hand = L * (2a * sin(θ0) + 2a * (π - θ0))
    Lp_hand = 2a * sin(θ0)
    ar = hf_absorbing_areas(fuse)
    S_hand = 2a * (π - θ0) * L + 2 * V_hand / L
    Lp_code = _appd_floor_props(AppDGeometry(fuse)).Lp      # the floor width the App. D floor plate uses
    rows = [("V", V_hand, cabin_volume(fuse)), ("coupling area A", A_hand, coupling_area(fuse)),
            ("absorbing area S", S_hand, ar.S), ("floor width", Lp_hand, Lp_code)]
    table = [ValidationTableRow(q, Float64(i), h, c, c - h, abs(c / h - 1) ≤ 1e-12) for (i, (q, h, c)) in enumerate(rows)]
    θr = range(θ0, 2π - θ0; length=181)
    series = [PlotSeries("wall", :computed, collect(a .* sin.(θr)), collect(-a .* cos.(θr)); panel=1),
              PlotSeries("floor", :computed, [-a * sin(θ0), a * sin(θ0)], fill(-a * cos(θ0), 2); panel=1)]
    ok = all(t.within_tolerance for t in table)
    return _p62_result("CABIN_GEOM_HAND", table, series, ok, "V, A, S and floor width within 1e-12 of the hand formulas",
                       (; criterion="1e-12 relative", V=V_hand))
end

# X_CYL_OUT — cumulative 3-D cabin mode count vs Weyl's law
function _run_cyl2d_weyl()
    fuse = FuselageGeometry(test_article_length(), 0.508, 56.6)
    c0 = 340.0
    cy = cyl2d_modes(56.6; n_modes=120, NY=10, c0)     # production NY = 10 (a first try with NY = 14 errored: complex eigenvalues; NY = 10 has 125 modes)
    V = cabin_volume(fuse)
    fs = [500.0, 750.0, 1000.0, 1250.0, 1500.0]
    m3 = cabin_modes_3d(cy, fuse.a, fuse.L, axial_truncation(2π * 1600.0, fuse.L, c0); c0)
    table = ValidationTableRow[]; Ns = Float64[]; Ws = Float64[]
    for f in fs
        N = count(m -> m.f_Hz ≤ f, m3)
        W = 4π * V * f^3 / (3 * c0^3)
        push!(table, ValidationTableRow("N(f ≤ $(Int(f)) Hz)", f, W, Float64(N), N - W, abs(N / W - 1) ≤ 0.25))
        push!(Ns, N); push!(Ws, W)
    end
    # post-hoc diagnostic (no criterion, added after the first run): Weyl's law with the rigid-wall surface term
    # πS f²/(4c³)·c = πS f²/(4c²), S = curved wall + floor + two ends
    a, L, θ0 = fuse.a, fuse.L, deg2rad(fuse.theta0_deg)
    S = 2a * (π - θ0) * L + 2a * sin(θ0) * L + 2 * V / L
    W2 = [4π * V * f^3 / (3 * c0^3) + π * S * f^2 / (4 * c0^2) for f in fs]
    series = [PlotSeries("Weyl 4πVf³/(3c³)", :reference_points, fs, Ws; panel=1),
              PlotSeries("Weyl + surface term (post-hoc)", :reference_points, fs, W2; panel=1),
              PlotSeries("cabin modes (CYL2D × axial)", :computed, fs, Ns; panel=1)]
    ok = all(t.within_tolerance for t in table)
    return _p62_result("CYL2D_WEYL", table, series, ok, "mode count N / Weyl leading term W at 500–1500 Hz (criterion ±25 %): " *
        join(["$(Int(f)): $(Int(n))/$(round(w; digits=1))" for (f, n, w) in zip(fs, Ns, Ws)], ", ") *
        ". Post-hoc: with the surface term N/W = " * join(string.(round.(Ns ./ W2; digits=2)), ", "),
        (; criterion="±25 %", ratio_two_term_posthoc=round.(Ns ./ W2; digits=3)))
end

# X_TRIM_OUT — passivity of the Phase III trim
function _run_trim_passivity()
    r = run_pain_pipeline(; source=:e11, n_harmonics=1, bpf_Hz=200.0, blocking=R2)
    inp = r.inputs
    fs = third_octave_centers(); fs = fs[100 .≤ fs .≤ 6300]
    table = ValidationTableRow[]; τs = Float64[]; ξs = Float64[]; n_bad = 0
    for f in fs
        ω = 2π * f
        τ = sidewall_tau(inp, ω)
        ξ = trim_conductance(inp.sidewall, ω, inp.m_wall; ρ0=inp.ρ_int, c0=inp.c_int)
        ηn = acoustic_loss_average(ω; V=cabin_volume(inp), S=hf_absorbing_areas(inp).S_side, S_e=hf_absorbing_areas(inp).S_e,
                                   ξ, ξ_e=trim_conductance(inp.endplates, ω, Inf; ρ0=inp.ρ_int, c0=inp.c_int), c0=inp.c_int)
        ok = ξ ≥ 0 && ηn ≥ 0 && τ > 0; n_bad += !ok
        push!(table, ValidationTableRow("f=$(round(Int, f)): ξ, η_n, τ_t", f, 0.0, ξ, ξ, ok))
        push!(τs, 10log10(τ)); push!(ξs, ξ)
    end
    series = [PlotSeries("τ_t (dB)", :computed, fs, τs; panel=1), PlotSeries("ξ = Re β", :computed, fs, ξs; panel=2)]
    return _p62_result("TRIM_PASSIVITY", table, series, n_bad == 0, "$(length(fs) - n_bad)/$(length(fs)) bands passive (ξ ≥ 0, η_n ≥ 0, τ_t > 0)",
                       (; criterion="passive", n_bad))
end

# X_PAIN_IN — resolved T1 inputs vs their documented formulas
function _run_pain_input_echo()
    r = run_pain_pipeline(; source=:e11, n_harmonics=3, bpf_Hz=200.0, blocking=R2)
    inp = r.inputs; a = inp.fuse.a
    p3 = phase3_trim(; a, L=inp.fuse.L, theta0_deg=inp.fuse.theta0_deg)
    P = _p62_printed()
    pv(q) = P[q][1]
    # smeared wall thickness from the printed App. E dimensions (skin + stringers over their arc pitch + frames over their spacing)
    t_eq = pv("skin_thickness") + (pv("stringer_leg1") + pv("stringer_leg2")) * pv("stringer_thickness") / (a * deg2rad(pv("stringer_spacing_deg"))) +
           (2 * pv("frame_flange") + pv("frame_web")) * pv("frame_thickness") / pv("frame_spacing")
    rows = [("ΔA = (πa/18)²", (π * a / 18)^2, inp.ΔA),
            ("m_wall = ρ t_eq (App. E dimensions, ρ = 2780 kg/m³)", 2780.0 * t_eq, inp.m_wall),
            ("L_c = L", inp.fuse.L, inp.L_c), ("c0", 340.0, inp.c_int), ("ρ0", 1.225, inp.ρ_int)]
    table = [ValidationTableRow(q, Float64(i), h, c, c - h, abs(c / h - 1) ≤ 1e-12) for (i, (q, h, c)) in enumerate(rows)]
    series = [PlotSeries("code / documented", :computed, collect(1.0:length(rows)), [c / h for (_, h, c) in rows]; panel=1)]
    return _p62_result("PAIN_INPUT_ECHO", table, series, all(t.within_tolerance for t in table),
                       "resolved T1 inputs equal their documented formulas within 1e-12", (; criterion="1e-12 relative", m_wall_phase3=p3.m_wall))
end

# A_CABIN — aircraft cabin example: overall dB(A) = energy sum of the A-weighted bands
function _run_ac_cabin_demo()
    json = _p62_example("aircraft_scale_hartzell_cabin_full.json")
    r = run_pain_pipeline(; source=:aircraft, aircraft_json=json, n_harmonics=3)
    sp = r.spectrum
    dBA = overall_dBA(sp)[1]
    bands = sort(collect(keys(sp.third_octave_SPL_dB)))
    lv = [sp.third_octave_SPL_dB[b] for b in bands]
    # IEC 61672 A-weighting at the nominal band centres, as tabulated (independent of `a_weight_dB`)
    iec = Dict(63.0 => -26.2, 125.0 => -16.1, 250.0 => -8.6, 500.0 => -3.2, 1000.0 => 0.0, 2000.0 => 1.2, 4000.0 => 1.0, 8000.0 => -1.1)
    hand = 10log10(sum(10^((l + a_weight_dB(b)) / 10) for (b, l) in zip(bands, lv) if isfinite(l)))
    table = [ValidationTableRow("overall dB(A) vs energy sum", 1.0, hand, dBA, dBA - hand, abs(dBA - hand) ≤ 1e-9)]
    # information, no criterion: the code's A-weights against the IEC table (kept out of the n/n count)
    iec_check = [(f=k, iec=v, code=round(a_weight_dB(k); digits=2)) for (k, v) in sort(collect(iec))]
    series = [PlotSeries("interior band SPL", :computed, bands, lv; panel=1),
              PlotSeries("A-weighted", :computed, bands, lv .+ a_weight_dB.(bands); panel=1)]
    return _p62_result("AC_CABIN_DEMO", table, series, table[1].within_tolerance,
                       "aircraft cabin example: overall $(round(dBA; digits=2)) dB(A) = energy sum of the A-weighted bands",
                       (; criterion="1e-9 dB", dBA, iec_check))
end

function _iso62_validation_cases()
    # `errlab`: the error panel / chip unit is the last (…) of it (the residual's own unit, not the plot's y unit)
    mk(id, title, files, fig, crit, run; ylab="value", xlab="x", errlab="") = ValidationCase(id, title, "62", files, fig, crit, "2026-10-23", "V-UNIT", run,
        PlotSpec(; xlabel=xlab, ylabel=ylab, panel_titles=[id], error_mode=:absolute, error_tol=0.0, error_ylabel=errlab), "")
    appE = [_data_path("cr3813", "appE_article_inputs.csv")]
    return [
        mk("F1A_PLANE_PEAK", "F1A free field: H1 peak on the propeller line (62)", String[], FigureRef("User Manual", "Fig. 3 grid", nothing),
           "H1 maximum on ℓ = 1 within ±1 station of k_p.", _run_f1a_plane_peak; xlab="k", ylab="H1 amplitude (Pa)", errlab="k_peak − k_p (stations)"),
        mk("FF_E11_MAP", "e11 free field: decay away from the measured line (62)", String[], FigureRef("CR-3813", "Fig. E-11", nothing),
           "Every off-line amplitude ≤ the ℓ = 1 amplitude at the same k.", _run_ff_e11_map; xlab="k", ylab="amplitude (Pa)"),
        mk("SRC_PASSTHROUGH", "Source select: the chosen field reaches the cabin unchanged (62)", String[], FigureRef("PAIN.jl", "run_pain_pipeline", nothing),
           "PainInputs amplitudes and phases identical to the blocked source grid.", _run_src_passthrough; xlab="k", ylab="H1 amplitude (Pa)"),
        mk("BLK_GAIN_MAP", "Blocked pressures: gain within 0–6.02 dB (62)", String[], FigureRef("CR-172428", "Eq. (43)", 68),
           "0 ≤ ΔL ≤ 20 log10 2 at every grid point for R1 and R2.", _run_blk_gain_map; xlab="γ (deg)", ylab="ΔL (dB)", errlab="max ΔL − 20 log10 2 (dB)"),
        mk("MRP_INPUT_QA", "Structure inputs vs CR-3813 App. E (62)", appE, FigureRef("CR-3813", "App. E pp. E-1–E-8", 117),
           "Every code value equal to the printed value to its printed digits.", _run_mrp_input_qa; xlab="quantity", ylab="code / printed"),
        mk("MRP_SHAPE_NORM", "Table D-1 shapes: max-normalized (62)", String[], FigureRef("CR-3813", "Table D-1", 113),
           "max |ψ| ≤ 1 + 1e-6 for every mode.", _run_mrp_shape_norm; xlab="θ (deg)", ylab="ψ"),
        mk("CABIN_GEOM_HAND", "Cabin geometry by hand (62)", String[], FigureRef("CR-3813", "Fig. D-1", nothing),
           "V, coupling area, absorbing area and floor width within 1e-12 of the hand formulas.", _run_cabin_geom_hand; xlab="x (m)", ylab="y (m)", errlab="code − hand (m³ | m² | m)"),
        mk("CYL2D_WEYL", "Cabin mode count vs Weyl's law (62)", String[], FigureRef("CR-3813", "App. C", nothing),
           "Cumulative 3-D mode count within 25 % of 4πVf³/(3c³) at 500–1500 Hz.", _run_cyl2d_weyl; xlab="f (Hz)", ylab="N(f) (modes)", errlab="N − W (modes)"),
        mk("TRIM_INPUT_QA", "Phase III trim vs CR-3813 p. E-9 (62)", appE, FigureRef("CR-3813", "p. E-9", 125),
           "Every code value equal to the printed value to its printed digits.", _run_trim_input_qa; xlab="quantity", ylab="code / printed"),
        mk("TRIM_PASSIVITY", "Phase III trim is passive: ξ ≥ 0, η_n ≥ 0 (62)", String[], FigureRef("CR-3813", "App. A", nothing),
           "ξ ≥ 0 and η_n ≥ 0 at every band 100–6300 Hz, τ_t > 0.", _run_trim_passivity; xlab="f (Hz)", ylab="τ_t (dB) / ξ", errlab="ξ = Re β (dimensionless)"),
        mk("PAIN_INPUT_ECHO", "Resolved cabin inputs vs their documented formulas (62)", String[], FigureRef("User Manual", "cards", nothing),
           "Each within 1e-12 relative.", _run_pain_input_echo; xlab="quantity", ylab="code / documented"),
        mk("AC_CABIN_DEMO", "Aircraft cabin example: overall dB(A) (62)", String[], FigureRef("PAIN.jl", "examples", nothing),
           "Overall dB(A) equals the energy sum of the A-weighted bands within 1e-9 dB.", _run_ac_cabin_demo; xlab="band (Hz)", ylab="SPL (dB)"),
    ]
end
