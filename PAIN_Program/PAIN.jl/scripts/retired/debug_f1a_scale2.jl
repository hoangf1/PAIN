# retired in phase 21: reimplemented the source sequence
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using CCBlade, AcousticAnalogies, AcousticMetrics, FFTW, JSON3

json = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
cfg = JSON3.read(read(json, String))
p = cfg.propeller
B = Int(p.num_blades); Rtip = Float64(p.tip_radius_m); Rhub = Float64(p.hub_radius_m)
rpm = Float64(p.rpm); Ω = rpm * 2π / 60; bpf = B * rpm / 60; ρ = 1.225
r = Float64.(collect(p.radii_m)); chord = Float64.(collect(p.chord_m))
theta = Float64.(collect(p.twist_deg)) .* (π / 180); nsec = length(r)
af(α, Re, M) = (2π * α, 0.008 + 0.1 * α^2)
rotor = CCBlade.Rotor(Rhub, Rtip, B)
sections = [CCBlade.Section(r[i], chord[i], theta[i], af) for i in 1:nsec]

function run_case(Vinf; area_tc=0.12, nrev=1, num_src_times=64, x_obs=[0.508-0.558, 0.0, 0.0])
    ops = [CCBlade.OperatingPoint(Vinf, Ω * r[i], ρ) for i in 1:nsec]
    outs = CCBlade.solve.(Ref(rotor), sections, ops)
    bpp = 2π / Ω / B
    period = nrev * bpp
    area = fill(area_tc, nsec)
    ses = AcousticAnalogies.f1a_source_elements_ccblade(
        rotor, sections, ops, outs, area, period, num_src_times, true)
    obs = AcousticAnalogies.ConstVelocityAcousticObserver(0.0, collect(Float64, x_obs), [Vinf, 0.0, 0.0])
    apth = AcousticAnalogies.noise.(ses, Ref(obs))
    apth_total = AcousticAnalogies.combine(apth, bpp, num_src_times)  # one bpp window
    pref = AcousticMetrics.pressure(apth_total)
    t = AcousticMetrics.time(apth_total)
    # remove DC
    p = pref .- sum(pref)/length(pref)
    n = length(p)
    P = FFTW.rfft(p)
    df = 1 / (t[end] - t[1] + eps())
    spls = Float64[]
    for H in 1:3
        fH = H * bpf
        bin = clamp(round(Int, fH / df) + 1, 1, length(P))
        A = 2 * abs(P[bin]) / n
        push!(spls, 20 * log10(max(A, 1e-20) / 20e-6))
    end
    return (; rms=sqrt(sum(abs2, p)/n), peak=maximum(abs, p), spls, Np_tip=outs[end].Np)
end

# ANOPP Table 8 peaks H1..3 ≈ 125.7, 118.6, 111.3
anopp = [125.7, 118.6, 111.3]
println("ANOPP peaks: ", anopp)

for V in (5.0, 10.0, 20.0, 30.0, 40.0)
    res = run_case(V)
    d = res.spls .- anopp
    println("V=$V Np=$(round(res.Np_tip;digits=1)) rms=$(round(res.rms;digits=1)) SPL=$(round.(res.spls;digits=1)) dANOPP=$(round.(d;digits=1))")
end

println("\n--- vary t/c at V=20 ---")
for tc in (0.08, 0.12, 0.16, 0.20)
    res = run_case(20.0; area_tc=tc)
    println("tc=$tc SPL=$(round.(res.spls;digits=1)) d=$(round.(res.spls .- anopp;digits=1))")
end

println("\n--- observer distance ---")
for dgap in (0.05, 0.08, 0.10, 0.15)
    res = run_case(20.0; x_obs=[-dgap, 0.0, 0.0])
    println("gap=$dgap SPL=$(round.(res.spls;digits=1))")
end
