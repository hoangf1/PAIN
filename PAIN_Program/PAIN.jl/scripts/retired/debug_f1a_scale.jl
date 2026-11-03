# retired in phase 21: reimplemented the source sequence
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN
using CCBlade
using AcousticAnalogies
using AcousticMetrics
using FFTW
using JSON3

json = joinpath(@__DIR__, "..", "examples", "aircraft_scale_hartzell.json")
cfg = JSON3.read(read(json, String))
p = cfg.propeller
op = cfg.operating_point
B = Int(p.num_blades)
Rtip = Float64(p.tip_radius_m)
Rhub = Float64(p.hub_radius_m)
rpm = Float64(p.rpm)
Ω = rpm * 2π / 60
bpf = B * rpm / 60
Vinf = 0.0
ρ = 1.225
r = Float64.(collect(p.radii_m))
chord = Float64.(collect(p.chord_m))
theta = Float64.(collect(p.twist_deg)) .* (π / 180)
nsec = length(r)

af(α, Re, M) = (2π * α, 0.01 + 0.5 * α^2)
rotor = CCBlade.Rotor(Rhub, Rtip, B)
sections = [CCBlade.Section(r[i], chord[i], theta[i], af) for i in 1:nsec]
ops = [CCBlade.OperatingPoint(Vinf, Ω * r[i], ρ) for i in 1:nsec]
outs = CCBlade.solve.(Ref(rotor), sections, ops)
println("CCBlade tip: Np=$(outs[end].Np) Tp=$(outs[end].Tp) a=$(outs[end].a) phi=$(rad2deg(outs[end].phi))")
println("CCBlade hub: Np=$(outs[1].Np) Tp=$(outs[1].Tp)")

# Try different area_over_chord2
for area_fac in (0.1, 0.01, 0.001, 12*0.12)  # last = typical thickness/chord * something wrong
    println("\n=== area_over_chord2 sentinel / thickness surrogate = $area_fac ===")
end

# Correct: thickness/chord as area/chord^2 for compact thickness source ≈ t/c
# AcousticAnalogies docs: area_over_chord2 is (cross-section area)/chord^2 ≈ thickness/chord for rectangle
area_over_chord2 = fill(0.12, nsec)  # t/c ≈ 0.12 typical
num_src_times = 64
bpp = 2π / Ω / B
period = 1 * bpp   # ONE blade-pass period
ses = AcousticAnalogies.f1a_source_elements_ccblade(
    rotor, sections, ops, outs, area_over_chord2, period, num_src_times, true)
println("num source elements = ", length(ses))
println("typeof ses[1] = ", typeof(ses[1]))

# Observer at prop plane, tip clearance ~0.05 m, ℓ=1 k=8
# Hub relative: surface at (a - rp? wait rp > a)
# From geometry: x_obs = [a*cosθ - rp, a*sinθ, z - zp]
a = 0.508
rp = 0.558
x_obs = [a - rp, 0.0, 0.0]  # pierce point relative to hub ≈ tip clearance
println("observer |x| = ", hypot(x_obs...))
obs = AcousticAnalogies.ConstVelocityAcousticObserver(0.0, x_obs, [0.0, 0.0, 0.0])
apth = AcousticAnalogies.noise.(ses, Ref(obs))
apth_total = AcousticAnalogies.combine(apth, bpp, num_src_times)
t = AcousticMetrics.time(apth_total)
pref = AcousticMetrics.pressure(apth_total)
println("n=$(length(pref)) t0=$(t[1]) t1=$(t[end]) dt=$(t[2]-t[1])")
println("p: min=$(minimum(pref)) max=$(maximum(pref)) rms=$(sqrt(sum(abs2, pref)/length(pref)))")
println("p units typeof = ", typeof(pref))

# Also try with positive Vinf (static prop can be singular)
println("\n--- with Vinf=10 m/s ---")
ops2 = [CCBlade.OperatingPoint(10.0, Ω * r[i], ρ) for i in 1:nsec]
outs2 = CCBlade.solve.(Ref(rotor), sections, ops2)
println("CCBlade tip V=10: Np=$(outs2[end].Np) a=$(outs2[end].a)")
ses2 = AcousticAnalogies.f1a_source_elements_ccblade(
    rotor, sections, ops2, outs2, area_over_chord2, bpp, num_src_times, true)
apth2 = AcousticAnalogies.noise.(ses2, Ref(obs))
apth_total2 = AcousticAnalogies.combine(apth2, bpp, num_src_times)
pref2 = AcousticMetrics.pressure(apth_total2)
println("p V=10: min=$(minimum(pref2)) max=$(maximum(pref2)) rms=$(sqrt(sum(abs2,pref2)/length(pref2)))")

# FFT amplitude
n = length(pref2)
P = FFTW.rfft(pref2)
df = 1 / (AcousticMetrics.time(apth_total2)[end] - AcousticMetrics.time(apth_total2)[1] + eps())
for H in 1:3
    fH = H * bpf
    bin = clamp(round(Int, fH / df) + 1, 1, length(P))
    A = 2 * abs(P[bin]) / n
    spl = 20 * log10(A / 20e-6)
    println("H=$H f=$fH bin=$bin A=$A Pa SPL=$spl dB")
end
