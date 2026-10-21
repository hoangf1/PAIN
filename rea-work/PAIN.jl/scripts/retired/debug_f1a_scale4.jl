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
Vinf = 20.0; ρ = 1.225; c0 = 340.0
r = Float64.(collect(p.radii_m)); chord = Float64.(collect(p.chord_m))
theta = Float64.(collect(p.twist_deg)) .* (π / 180); nsec = length(r)
af(α, Re, M) = (2π * clamp(α, -0.4, 0.4), 0.008 + 0.1 * clamp(α, -0.4, 0.4)^2)
rotor = CCBlade.Rotor(Rhub, Rtip, B)
sections = [CCBlade.Section(r[i], chord[i], theta[i], af) for i in 1:nsec]
ops = [CCBlade.OperatingPoint(Vinf, Ω * r[i], ρ; asound=c0) for i in 1:nsec]
outs = CCBlade.solve.(Ref(rotor), sections, ops)
bpp = 2π / Ω / B
nsrc = 64
x_obs = [0.0, 0.457, 0.0]
obs = AcousticAnalogies.ConstVelocityAcousticObserver(0.0, x_obs, [Vinf, 0.0, 0.0])

function tone_spl(ses, period, n; obs=obs)
    apth = AcousticAnalogies.noise.(ses, Ref(obs))
    tot = AcousticAnalogies.combine(apth, period, n)
    pref = AcousticMetrics.pressure(tot)
    pm = tot.p_m
    pd = tot.p_d
    t = AcousticMetrics.time(tot)
    pac = pref .- sum(pref)/length(pref)
    nn = length(pac)
    P = FFTW.rfft(pac)
    df = 1 / (t[end] - t[1] + eps())
    spls = Float64[]
    for H in 1:3
        bin = clamp(round(Int, H * bpf / df) + 1, 1, length(P))
        A = 2 * abs(P[bin]) / nn
        push!(spls, 20 * log10(max(A, 1e-20) / 20e-6))
    end
    return (; spls,
        rms=sqrt(sum(abs2, pac)/nn),
        rms_m=sqrt(sum(abs2, pm .- sum(pm)/nn)/nn),
        rms_d=sqrt(sum(abs2, pd .- sum(pd)/nn)/nn),
        size_ses=size(ses))
end

for (lab, area) in [("tc=0.12", fill(0.12, nsec)), ("tc=1e-6", fill(1e-6, nsec)), ("tc=0", fill(0.0, nsec))]
    ses = AcousticAnalogies.f1a_source_elements_ccblade(rotor, sections, ops, outs, area, bpp, nsrc, true)
    res = tone_spl(ses, bpp, nsrc)
    println("$lab size=$(res.size_ses) rms=$(round(res.rms;digits=1)) m=$(round(res.rms_m;digits=1)) d=$(round(res.rms_d;digits=1)) SPL=$(round.(res.spls;digits=1))")
end

# Scale loads ×0.1
outs10 = [CCBlade.Outputs(o.Np/10, o.Tp/10, o.a, o.ap, o.u, o.v, o.phi, o.alpha, o.W,
    o.cl, o.cd, o.cn, o.ct, o.F, o.G) for o in outs]
ses = AcousticAnalogies.f1a_source_elements_ccblade(rotor, sections, ops, outs10, fill(1e-6, nsec), bpp, nsrc, true)
res = tone_spl(ses, bpp, nsrc)
println("loads/10 tc~0 size=$(res.size_ses) rms=$(round(res.rms;digits=1)) d=$(round(res.rms_d;digits=1)) SPL=$(round.(res.spls;digits=1))")

# Stationary + no translation: set Vinf≈0 for ops but asound ok — use tiny Vinf
ops_s = [CCBlade.OperatingPoint(1.0, Ω * r[i], ρ; asound=c0) for i in 1:nsec]
outs_s = CCBlade.solve.(Ref(rotor), sections, ops_s)
ses_s = AcousticAnalogies.f1a_source_elements_ccblade(rotor, sections, ops_s, outs_s, fill(1e-6, nsec), bpp, nsrc, true)
obs_s = AcousticAnalogies.StationaryAcousticObserver(x_obs)
res = tone_spl(ses_s, bpp, nsrc; obs=obs_s)
println("V=1 stationary load-only SPL=$(round.(res.spls;digits=1)) rms=$(round(res.rms;digits=1))")

# Check one source element magnitudes
ses1 = AcousticAnalogies.f1a_source_elements_ccblade(rotor, sections, ops, outs, fill(0.12, nsec), bpp, nsrc, true)
se = ses1[1, 1, 1]  # time, radial, blade?
println("ses ndims=$(ndims(ses1)) size=$(size(ses1))")
println("sample se: Λ=$(se.Λ) Δr=$(se.Δr) |f0|=$(sqrt(sum(abs2, se.f0dot))) |y0|=$(sqrt(sum(abs2, se.y0dot))) c0=$(se.c0) ρ=$(se.ρ0)")
ap = AcousticAnalogies.noise(se, obs)
println("single-element p_m=$(ap.p_m) p_d=$(ap.p_d)")

println("ANOPP H1..3 peaks: 125.7 118.6 111.3")
