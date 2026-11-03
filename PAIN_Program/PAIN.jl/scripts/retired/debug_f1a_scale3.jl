# retired in phase 21: reimplemented the source sequence
#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using CCBlade, AcousticAnalogies, AcousticMetrics, FFTW, JSON3

json = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
cfg = JSON3.read(read(json, String))
p = cfg.propeller
op = cfg.operating_point
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
println("tip Np=$(outs[end].Np) Tp=$(outs[end].Tp) phi=$(rad2deg(outs[end].phi)) a=$(outs[end].a)")
println("hub Np=$(outs[1].Np) Tp=$(outs[1].Tp)")

bpp = 2π / Ω / B
area = fill(0.12, nsec)
num_src_times = 64
ses = AcousticAnalogies.f1a_source_elements_ccblade(
    rotor, sections, ops, outs, area, bpp, num_src_times, true)

# Pierce observer: x1=0.457, x2=0, x3=0 → AA [0, 0.457, 0]
x_obs = [0.0, 0.457, 0.0]
obs = AcousticAnalogies.ConstVelocityAcousticObserver(0.0, x_obs, [Vinf, 0.0, 0.0])
apth = AcousticAnalogies.noise.(ses, Ref(obs))
apth_total = AcousticAnalogies.combine(apth, bpp, num_src_times)
pref = AcousticMetrics.pressure(apth_total)
t = AcousticMetrics.time(apth_total)
p_ac = pref .- sum(pref) / length(pref)
n = length(p_ac)
rms = sqrt(sum(abs2, p_ac) / n)
println("n=$n Tspan=$(t[end]-t[1]) p_dc=$(sum(pref)/n) rms=$rms peak=$(maximum(abs, p_ac))")
println("SPL_rms=$(20*log10(max(rms,1e-20)/20e-6)) SPL_peak=$(20*log10(max(maximum(abs,p_ac),1e-20)/20e-6))")

P = FFTW.rfft(p_ac)
df = 1 / (t[end] - t[1] + eps())
println("df=$df bpf=$bpf")
for H in 1:5
    fH = H * bpf
    bin = clamp(round(Int, fH / df) + 1, 1, length(P))
    A2 = 2 * abs(P[bin]) / n          # peak amp
    Arms = abs(P[bin]) / n * sqrt(2)  # rms of tone
    # also try without *2 (two-sided style)
    A1 = abs(P[bin]) / n
    println("H=$H bin=$bin |P|=$(abs(P[bin])) A_peak=$A2 SPL=$(20*log10(max(A2,1e-20)/20e-6)) A_rms=$Arms SPL_rms=$(20*log10(max(Arms,1e-20)/20e-6)) A_n=$A1")
end

# Stationary observer (freestream frame) — sources already advect at Vinf
println("\n--- stationary observer ---")
obs2 = AcousticAnalogies.StationaryAcousticObserver(x_obs)
apth2 = AcousticAnalogies.noise.(ses, Ref(obs2))
apth_total2 = AcousticAnalogies.combine(apth2, bpp, num_src_times)
p2 = AcousticMetrics.pressure(apth_total2)
p2a = p2 .- sum(p2)/length(p2)
rms2 = sqrt(sum(abs2, p2a)/length(p2a))
println("rms=$rms2 SPL_rms=$(20*log10(max(rms2,1e-20)/20e-6))")

# Try period = 2*bpp and longer FFT
println("\n--- period=2*bpp, combine 2*bpp ---")
ses3 = AcousticAnalogies.f1a_source_elements_ccblade(
    rotor, sections, ops, outs, area, 2*bpp, num_src_times, true)
apth3 = AcousticAnalogies.noise.(ses3, Ref(obs))
apth_total3 = AcousticAnalogies.combine(apth3, 2*bpp, 2*num_src_times)
p3 = AcousticMetrics.pressure(apth_total3)
t3 = AcousticMetrics.time(apth_total3)
p3a = p3 .- sum(p3)/length(p3)
n3 = length(p3a)
P3 = FFTW.rfft(p3a)
df3 = 1 / (t3[end] - t3[1] + eps())
for H in 1:3
    bin = clamp(round(Int, H*bpf / df3) + 1, 1, length(P3))
    A = 2 * abs(P3[bin]) / n3
    println("H=$H SPL=$(20*log10(max(A,1e-20)/20e-6))")
end

anopp = [125.7, 118.6, 111.3]
println("ANOPP peaks: $anopp")
