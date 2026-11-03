# retired in phase 21: reimplemented the source sequence
#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using CCBlade, AcousticAnalogies, AcousticMetrics, FFTW, JSON3

json = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
cfg = JSON3.read(read(json, String))
p = cfg.propeller
B = Int(p.num_blades); Rtip = Float64(p.tip_radius_m); Rhub = Float64(p.hub_radius_m)
rpm = Float64(p.rpm); Ω = rpm * 2π / 60; bpf = B * rpm / 60
ρ = 1.225; c0 = 340.0
r = Float64.(collect(p.radii_m)); chord = Float64.(collect(p.chord_m))
theta = Float64.(collect(p.twist_deg)) .* (π / 180); nsec = length(r)
bpp = 2π / Ω / B
nsrc = 64
x_obs = [0.0, 0.457, 0.0]

function run(Vinf, cl_fac, tc; stationary=false)
    af(α, Re, M) = begin
        αc = clamp(α, -0.4, 0.4)
        (cl_fac * 2π * αc, 0.008 + 0.1 * αc^2)
    end
    rotor = CCBlade.Rotor(Rhub, Rtip, B)
    sections = [CCBlade.Section(r[i], chord[i], theta[i], af) for i in 1:nsec]
    ops = [CCBlade.OperatingPoint(Vinf, Ω * r[i], ρ; asound=c0) for i in 1:nsec]
    outs = CCBlade.solve.(Ref(rotor), sections, ops)
    # thrust / torque approx
    dr = diff([Rhub; 0.5 .* (r[1:end-1] .+ r[2:end]); Rtip])
    # simpler: trapezoid on Np
    T = B * sum(outs[i].Np * (i==1 ? (r[2]-r[1]) : i==nsec ? (r[end]-r[end-1]) : (r[i+1]-r[i-1])/2) for i in 1:nsec)
    Q = B * sum(outs[i].Tp * r[i] * (i==1 ? (r[2]-r[1]) : i==nsec ? (r[end]-r[end-1]) : (r[i+1]-r[i-1])/2) for i in 1:nsec)
    ses = AcousticAnalogies.f1a_source_elements_ccblade(
        rotor, sections, ops, outs, fill(tc, nsec), bpp, nsrc, true)
    obs = stationary ?
        AcousticAnalogies.StationaryAcousticObserver(x_obs) :
        AcousticAnalogies.ConstVelocityAcousticObserver(0.0, x_obs, [Vinf, 0.0, 0.0])
    apth = AcousticAnalogies.noise.(ses, Ref(obs))
    tot = AcousticAnalogies.combine(apth, bpp, nsrc)
    pref = AcousticMetrics.pressure(tot)
    t = AcousticMetrics.time(tot)
    pac = pref .- sum(pref)/length(pref)
    nn = length(pac)
    P = FFTW.rfft(pac)
    # Correct DFT frequency spacing
    dt = t[2] - t[1]
    df = 1 / (nn * dt)
    spls = Float64[]
    for H in 1:3
        bin = clamp(round(Int, H * bpf / df) + 1, 1, length(P))
        A = 2 * abs(P[bin]) / nn
        push!(spls, 20 * log10(max(A, 1e-20) / 20e-6))
    end
    return (; T, Q, Np_tip=outs[end].Np, spls, df)
end

anopp = [125.7, 118.6, 111.3]
println("ANOPP ", anopp)
for V in (10.0, 20.0, 40.0, 60.0)
    for (cf, tc) in ((1.0, 0.0), (0.5, 0.0), (0.3, 0.0), (1.0, 0.04), (0.5, 0.04))
        res = run(V, cf, tc)
        d = res.spls .- anopp
        println("V=$V cl*$cf tc=$tc T=$(round(res.T;digits=1))N SPL=$(round.(res.spls;digits=1)) d=$(round.(d;digits=1))")
    end
end
