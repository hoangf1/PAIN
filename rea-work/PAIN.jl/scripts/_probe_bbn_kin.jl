using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
using PAIN, Printf
json = joinpath(@__DIR__, "..", "examples", "bbn_aerocommander_tipA.json")
cfg = PAIN._load_aircraft_json(json)
B = 3
R = 1.18
r_obs = R + 0.15
seps = [13.3, 11.8, 10.4]
ψ = cumsum([0.0; seps])
obs = [Observer([0.0, r_obs * cosd(a), r_obs * sind(a)], zeros(3), "ψ=$a") for a in ψ]
src = evaluate_propeller_source(cfg, obs; n_harmonics=3, num_src_times=128, allow_static=true)
for i in 1:3
    for m in 1:3
        dφ = mod(src.phase[i + 1, m] - src.phase[1, m] + π, 2π) - π
        expect = mod(deg2rad(m * B * seps[i]) + π, 2π) - π
        @printf("sep=%.1f H=%d dφ=%.2f expect=%.2f err=%.2f\n",
                seps[i], m, rad2deg(dφ), rad2deg(expect), rad2deg(dφ - expect))
    end
end
