#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using CCBlade, AcousticAnalogies, AcousticMetrics, FFTW, JSON3

json = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
cfg = JSON3.read(read(json, String))
p = cfg.propeller
B = Int(p.num_blades); Rtip = Float64(p.tip_radius_m); Rhub = Float64(p.hub_radius_m)
rpm = Float64(p.rpm); Ω = rpm * 2π / 60; bpf = B * rpm / 60
Vinf = 20.0; ρ = 1.225; c0 = 340.0
r = Float64.(collect(p.radii_m)); chord = Float64.(collect(p.chord_m))
theta0 = Float64.(collect(p.twist_deg)) .* (π / 180); nsec = length(r)
bpp = 2π / Ω / B; nsrc = 64
x_obs = [0.0, 0.457, 0.0]
anopp = [125.7, 118.6, 111.3]
af(α, Re, M) = (2π * clamp(α, -0.35, 0.35), 0.01 + 0.15 * clamp(α, -0.35, 0.35)^2)
ddeg = -5.0
theta = theta0 .+ deg2rad(ddeg)
rotor = CCBlade.Rotor(Rhub, Rtip, B)
sections = [CCBlade.Section(r[i], chord[i], theta[i], af) for i in 1:nsec]
ops = [CCBlade.OperatingPoint(Vinf, Ω * r[i], ρ; asound=c0) for i in 1:nsec]
outs = CCBlade.solve.(Ref(rotor), sections, ops)
obs = AcousticAnalogies.ConstVelocityAcousticObserver(0.0, x_obs, [Vinf, 0.0, 0.0])
for tc in (0.0, 0.01, 0.02, 0.04, 0.08)
    ses = AcousticAnalogies.f1a_source_elements_ccblade(
        rotor, sections, ops, outs, fill(tc, nsec), bpp, nsrc, true)
    tot = AcousticAnalogies.combine(AcousticAnalogies.noise.(ses, Ref(obs)), bpp, nsrc)
    pref = AcousticMetrics.pressure(tot)
    t = AcousticMetrics.time(tot)
    pac = pref .- sum(pref)/length(pref)
    nn = length(pac); P = FFTW.rfft(pac)
    df = 1 / (nn * (t[2]-t[1]))
    spls = [begin
        bin = clamp(round(Int, H*bpf/df)+1, 1, length(P))
        20*log10(max(2*abs(P[bin])/nn, 1e-20)/20e-6)
    end for H in 1:3]
    println("tc=$tc SPL=$(round.(spls;digits=1)) d=$(round.(spls.-anopp;digits=1))")
end
