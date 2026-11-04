# Unit tests: src/validation_case_iso121.jl (Phase 121, Commander 695A cabin dB(A) vs CR-178004 flight 3).
@testset "iso121: air, conditions and operating point" begin
    @test isfile(PAIN._p121_conditions_csv()) && isfile(PAIN._p121_measured_csv())
    # ISA sea level 288.15 K: ρ = 1.2250 kg/m3, c = 340.29 m/s; 10 000 ft: p = 69.68 kPa (ISA table)
    a0 = PAIN.c695a_air(0, 288.15)
    @test a0.ρ ≈ 1.2250 rtol = 1e-4
    @test a0.c ≈ 340.29 rtol = 1e-4
    a1 = PAIN.c695a_air(10000, 268.34)
    @test a1.ρ * 287.05 * 268.34 ≈ 69682 rtol = 1e-3
    rows = PAIN.c695a_conditions()
    @test length(rows) == 18 && [r.cond for r in rows] == 1:18
    # Table 4 as printed: condition 1, and the two single-engine conditions
    @test (rows[1].alt_ft, rows[1].ias_kt, rows[1].oat_F, rows[1].port_rpm, rows[1].port_kW, rows[1].stbd_kW) == (10000, 233, 53, 1573, 482, 466)
    @test rows[11].port_rpm == 0 && rows[11].stbd_rpm > 0 && rows[12].stbd_rpm == 0 && rows[12].port_rpm > 0
    op = PAIN.c695a_operating_point(rows[1])
    # IAS taken as EAS: dynamic pressure equals sea-level 1/2 ρ0 IAS²; OAT 53 °F = 284.82 K; cabin at 293.15 K
    @test 0.5 * op.ρ * op.V^2 ≈ 0.5 * 1.225 * (233 * 0.514444)^2 rtol = 1e-12
    @test op.c ≈ sqrt(1.4 * 287.05 * 284.8167) rtol = 1e-6
    @test op.c_cab ≈ sqrt(1.4 * 287.05 * 293.15) rtol = 1e-12
    @test op.V > 233 * 0.514444    # true airspeed above IAS at 10 000 ft
    # pressurized condition 3 (cabin 1700 ft) has denser cabin air than unpressurized condition 1 (cabin 10 000 ft)
    @test PAIN.c695a_operating_point(rows[3]).ρ_cab > op.ρ_cab
    d = PAIN._p121_cfg_dict(1500, 12.5, op, -1)
    @test d["propeller"]["rpm"] == 1500 && d["propeller"]["pitch_offset_deg"] == 12.5
    @test d["operating_point"]["forward_speed_mps"] == op.V && d["cabin"]["rotation_direction"]["value"] == -1
    @test d["cabin"]["rho_ext_kg_m3"]["value"] == op.ρ && d["cabin"]["rho_int_kg_m3"]["value"] == op.ρ_cab
    @test PAIN._p121_cfg_dict(1500, 0.0, op, 1)["propeller"]["pitch_offset_deg"] == 0.0   # the base file is not changed
    base = PAIN._p121_base()   # the example file as written: printed diameter, pitch 0, cabin a = 0.725 m
    @test base["propeller"]["tip_radius_m"] == 1.345 && base["propeller"]["pitch_offset_deg"] == 0.0
    @test base["cabin"]["a_m"]["value"] == 0.725
    PAIN._p121_cfg_dict(1500, 7.0, op, 1; base)
    @test base["propeller"]["pitch_offset_deg"] == 0.0   # the passed base is copied, not changed
end

@testset "iso121: pitch for the printed power" begin
    row = PAIN.c695a_conditions()[1]
    op = PAIN.c695a_operating_point(row)
    p = PAIN.c695a_pitch_for_power(row.port_rpm, 1000row.port_kW, op)
    Ω = row.port_rpm * 2π / 60
    @test PAIN.c695a_torque(row.port_rpm, p, op) ≈ 1000row.port_kW / Ω rtol = 1e-3
    # more power at the same rpm needs more pitch; a power outside the pitch range is an error
    @test PAIN.c695a_pitch_for_power(row.port_rpm, 1300row.port_kW, op) > p
    @test_throws ErrorException PAIN.c695a_pitch_for_power(row.port_rpm, 1e9, op)
end

@testset "iso121: dB(A) over 63–5000 Hz" begin
    # one band at 1 kHz (A ≈ 0): the level itself; two equal bands: +3.01 dB; 8 kHz and 50 Hz are outside the range
    @test PAIN._p121_dBA(Dict(1000.0 => 80.0)) ≈ 80.0 atol = 0.01
    @test PAIN._p121_dBA(Dict(1000.0 => 80.0, 2000.0 * 2^(-1 / 3) => 80.0 - PAIN.a_weight_dB(2000.0 * 2^(-1 / 3)))) ≈ 80.0 + 10log10(2) atol = 0.01
    @test PAIN._p121_dBA(Dict(1000.0 => 80.0, 8000.0 => 120.0, 50.0 => 120.0)) ≈ 80.0 atol = 0.01
    m = PAIN.c695a_measured_dBA()
    @test length(m) == 36 && all(k -> k[2] in (3, 6) && 1 ≤ k[1] ≤ 18, keys(m))
    # condition 1, mic 3 by hand with the IEC 61672 tabulated A-weights at the nominal centres (App. E Table E.3)
    iec = Dict(63 => -26.2, 80 => -22.5, 100 => -19.1, 125 => -16.1, 160 => -13.4, 200 => -10.9, 250 => -8.6,
               315 => -6.6, 400 => -4.8, 500 => -3.2, 630 => -1.9, 800 => -0.8, 1000 => 0.0, 1250 => 0.6,
               1600 => 1.0, 2000 => 1.2, 2500 => 1.3, 3150 => 1.2, 4000 => 1.0, 5000 => 0.5)
    c = PAIN._read_csv_numeric(PAIN._p121_measured_csv())
    sel = [i for i in eachindex(c[:cond]) if c[:flight][i] == 3 && c[:cond][i] == 1 && c[:mic][i] == 3 && c[:band_Hz][i] ≥ 63]
    @test length(sel) == 20
    hand = 10log10(sum(10^((c[:L_dB][i] + iec[Int(c[:band_Hz][i])]) / 10) for i in sel))
    @test m[(1, 3)] ≈ hand atol = 0.1
end

@testset "iso121: two engines added in energy" begin
    rows = PAIN.c695a_conditions()
    r = PAIN.c695a_condition_spectrum(rows[1]; n_harmonics=3)
    @test [e.side for e in r.engines] == ["port", "stbd"]
    tot = PAIN._p121_dBA(Dict(b => 10log10(p2) for (b, p2) in r.band_p2))
    @test tot ≈ 10log10(sum(10^(e.dBA / 10) for e in r.engines)) atol = 0.01   # engine dB(A) are rounded to 0.01
    r12 = PAIN.c695a_condition_spectrum(rows[12]; n_harmonics=3)
    @test length(r12.engines) == 1 && r12.engines[1].side == "port"
end

# Phase 122: the App. B tones and the per-engine harmonic levels
@testset "iso122: App. B cabin tones" begin
    @test isfile(PAIN._p122_measured_csv())
    t = PAIN.c695a_measured_tones()
    @test length(t) == 108
    # conditions where the two engines' tones are separate: different rpm, or one engine (11 starboard, 12 port)
    @test sort(unique(k[1] for k in keys(t))) == [1, 2, 3, 4, 9, 10, 11, 12, 17, 18]
    @test all(k -> k[3] == "stbd", (k for k in keys(t) if k[1] == 11)) && all(k -> k[3] == "port", (k for k in keys(t) if k[1] == 12))
    # every condition named has a different rpm on the two engines, or one engine off (Table 4)
    rows = Dict(r.cond => r for r in PAIN.c695a_conditions())
    @test all(c -> rows[c].port_rpm != rows[c].stbd_rpm, unique(k[1] for k in keys(t)))
    # hand value from App. B Table B.7 (flight 3, condition 1, mic 3, port engine): H1 = 106.6 dB, H2 = 92.3 dB
    @test t[(1, 3, "port", 1)] == 106.6 && t[(1, 3, "port", 2)] == 92.3
    # the condition runs carry each engine's H1–H3 from the same run as its bands
    r = PAIN.c695a_condition_spectrum(rows[12]; n_harmonics=3)
    @test length(r.engines[1].harmonics_dB) == 3 && all(isfinite, r.engines[1].harmonics_dB)
    bpf = 3 * rows[12].port_rpm / 60
    # H1 lies in the band nearest its frequency, alone (no broadband below 1 kHz): the band level equals H1
    b = argmin(b -> abs(log(b / bpf)), collect(keys(r.band_p2)))
    @test 10log10(r.band_p2[b]) ≈ r.engines[1].harmonics_dB[1] atol = 1e-9
end

# Phase 123: App. A exterior tones and the flush-microphone interpolation
@testset "iso123: App. A exterior tones and the flush microphone" begin
    @test isfile(PAIN._p123_measured_csv())
    e = PAIN.c695a_measured_exterior()
    # 18 conditions × 2 near propellers × 3 harmonics, less port 11 and starboard 12 (shut down) and port 15 H1 (illegible)
    @test length(e) == 108 - 6 - 1
    @test !haskey(e, (11, "port", 1)) && !haskey(e, (12, "stbd", 1)) && !haskey(e, (15, "port", 1)) && haskey(e, (15, "port", 2))
    @test e[(1, "port", 1)] == 130.0 && e[(1, "port", 3)] == 127.0          # side 0 = port (first rows of Table A.1)
    # interpolation in dB along ℓ = 1 between k_p (propeller plane) and k_p − 1 (πa/18 forward)
    kp = PAIN.GridSpec().k_p
    A = zeros(kp + 1, 2, 4)
    A[kp, 1, :] .= [2.0, 1.0, 0.5, 9.0]
    A[kp - 1, 1, :] .= [0.2, 0.1, 0.05, 9.0]
    A[kp + 1, 1, :] .= 1e3; A[kp, 2, :] .= 1e3                               # other points must not enter
    a = 0.725; dx = π * a / 18
    db(p) = PAIN.peak_Pa_to_spl_dB(p)
    @test PAIN.c695a_flush_mic_dB((; amplitudes=A), a; x_fwd=0.0) ≈ db.([2.0, 1.0, 0.5])
    @test PAIN.c695a_flush_mic_dB((; amplitudes=A), a; x_fwd=dx) ≈ db.([0.2, 0.1, 0.05])
    @test PAIN.c695a_flush_mic_dB((; amplitudes=A), a; x_fwd=dx / 2) ≈ db.([2.0, 1.0, 0.5]) .- 10    # halfway: −20 dB / 2
    @test length(PAIN.c695a_flush_mic_dB((; amplitudes=A), a; nH=4)) == 4
    @test_throws ErrorException PAIN.c695a_flush_mic_dB((; amplitudes=A), a; x_fwd=1.5dx)
end

# Phase 124: tonal dB(A) of the CR-172428 test article (this code, NASA's printout, the measurement)
@testset "iso124: tonal dB(A) against NASA PAIN and the measurement" begin
    # IEC 61672 A-weights at nominal centres (tabulated, independent of a_weight_dB): 500 Hz −3.2, 1 kHz 0.0, 2 kHz +1.2
    @test PAIN.tonal_dBA([80.0], [1000.0]) ≈ 80.0 atol = 0.05
    @test PAIN.tonal_dBA([80.0, 80.0], [1000.0, 1000.0]) ≈ 80.0 + 10log10(2) atol = 0.05
    @test PAIN.tonal_dBA([80.0, 70.0], [500.0, 2000.0]) ≈ 10log10(10^(76.8 / 10) + 10^(71.2 / 10)) atol = 0.1
    r = PAIN._run_r172428_dba(:exp)
    @test r.id == "R172428_DBA_EXP" && length(r.table) == 3 && [row.x for row in r.table] == [3000.0, 4000.0, 5000.0]
    # the reference column is the measured sum, read back from the printed table (4000 rpm: 90.3, 80.3, 65.2 dB at 200/400/600 Hz)
    c = PAIN._read_csv_numeric_nan(PAIN._r172428_csv("appB_predictions.csv"))
    i4 = [findfirst(j -> c[:rpm][j] == 4000 && c[:H][j] == H, eachindex(c[:rpm])) for H in 1:3]
    @test c[:measured_dB][i4] == [90.3, 80.3, 65.2]
    @test r.table[2].reference ≈ PAIN.tonal_dBA(c[:measured_dB][i4], [200.0, 400.0, 600.0])
    @test all(row -> row.residual ≈ row.computed - row.reference, r.table)
    @test r.verdict === (all(row -> abs(row.residual) ≤ 4.0, r.table) ? :met : :not_met)
    # the code form follows its parent: R172428_DBA_CODE's 4000 rpm sum is that of R172428_CODE's H1–H3
    rc = PAIN._run_r172428_dba(:code)
    lv = [l for l in PAIN._r172428_levels(; η_n_per_mode=false, q0_coupled=true, η_n_band_omega=false) if l.rpm == 4000]
    @test rc.table[2].computed ≈ PAIN.tonal_dBA([l.ours for l in lv], [l.f_Hz for l in lv])
    @test rc.table[2].reference ≈ PAIN.tonal_dBA([l.nasa for l in lv], [l.f_Hz for l in lv])
end

# Phase 125: the Eq. (8) point form at the mic seat
@testset "iso125: tone level at the mic seat" begin
    inp = PAIN.r172428_inputs(4000)                      # any PainInputs: the test article (fast, Table D-1 modes)
    s = PAIN.c695a_seat_dB(inp, 200.0; seat=(; z=0.9, x=0.2, h_ear=0.5))
    @test length(s) == 3 && all(isfinite, s)
    # the seat value is the point_tone_p2 value at the nearest interior node, in dB re 20 µPa
    p0 = PAIN.cabin_interior_points(inp)
    yfl = -inp.fuse.a * cosd(inp.fuse.theta0_deg)
    i = argmin(j -> (p0.X[j] - 0.2)^2 + (p0.Y[j] - (yfl + 0.5))^2, eachindex(p0.X))
    p2 = PAIN.point_tone_p2(inp, 2, 2π * 400.0; pts=(; nodes=p0.nodes, X=p0.X, Y=p0.Y, z=[0.9], wz=[1.0]))
    @test s[2] ≈ 10log10(p2[i, 1] / 4e-10)
    # left–right symmetric point field (stated in the case): the mirrored seat gives the same level
    @test PAIN.c695a_seat_dB(inp, 200.0; seat=(; z=0.9, x=-0.2, h_ear=0.5)) ≈ s
    # a different seat gives a different level (the function reads the seat)
    @test PAIN.c695a_seat_dB(inp, 200.0; seat=(; z=0.2, x=0.2, h_ear=0.5)) != s
    @test_throws ErrorException PAIN.c695a_seat_dB(inp, 200.0; seat=(; z=-1.0, x=0.2, h_ear=0.5))
    @test PAIN._P125_SEAT == (; z=1.435, x=0.45, h_ear=1.0)
    @test PAIN._run_ac_c695a_seat isa Function
end
