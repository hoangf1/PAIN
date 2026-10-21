#!/usr/bin/env julia
# I-11: regenerate tr996_fig3_blade_form.csv from dig_tr996_fig3.py hand readings;
# confirm panel (c) is NACA 4-(5)(08)-03; blade_form.csv unchanged.
const BF = joinpath(@__DIR__, "..", "..", "data", "report996", "naca_4-5-08-03", "blade_form.csv")
const OUT = joinpath(@__DIR__, "..", "..", "data", "report996", "tr996_fig3_blade_form.csv")

# Hand readings from Fig. 3(c) at r/R (b/D, h/b, beta_deg) — dig_tr996_fig3.py
const FIG3C = Dict(
    0.30 => (0.093, 0.170, 65.5),
    0.35 => (0.092, 0.155, 62.5),
    0.40 => (0.091, 0.140, 59.5),
    0.45 => (0.090, 0.128, 56.5),
    0.50 => (0.090, 0.118, 53.5),
    0.55 => (0.089, 0.108, 50.5),
    0.60 => (0.089, 0.100, 48.0),
    0.65 => (0.088, 0.092, 45.5),
    0.70 => (0.088, 0.085, 43.5),
    0.75 => (0.087, 0.078, 42.0),
    0.80 => (0.085, 0.070, 40.0),
    0.85 => (0.080, 0.060, 38.0),
    0.90 => (0.065, 0.052, 36.5),
    0.95 => (0.040, 0.045, 35.0),
    1.00 => (0.000, 0.040, 34.0),
)

function main()
    bfrows = Dict{Float64,NTuple{3,Float64}}()
    for raw in eachline(BF)
        startswith(raw, "r_over") && continue
        startswith(raw, "#") && continue
        p = split(strip(raw), ',')
        length(p) >= 4 || continue
        rR = parse(Float64, p[1])
        cR = parse(Float64, p[2])
        tc = parse(Float64, p[3])
        beta = parse(Float64, p[4])
        bfrows[round(rR; digits=3)] = (cR / 2, tc, beta)
    end
    keys_bf = collect(keys(bfrows))
    max_bd = 0.0; max_hb = 0.0; max_beta = 0.0
    open(OUT, "w") do io
        println(io, "# Source: NACA Report 996 Fig. 3(c) NACA 4-(5)(08)-03, PDF p. 9")
        println(io, "# Method: hand reading of panel (c); b/D curve confirmed (not h/b); compare blade_form.csv (I-11)")
        println(io, "# Digitized 2026-10-21; regenerated I-11 2026-10-21; script data/digitizers/dig_tr996_fig3.py")
        println(io, "# Finding I-11: panel (c) caption is NACA 4-(5)(08)-03; curve read as b/D. Author Fig 3.txt (B-3) disagrees — wrong panel/curve; blade_form.csv stays geometry input (25b).")
        println(io, "# Conventions: b/D = c/(2R); h/b = t/c; beta_deg section pitch")
        println(io, "r_over_R,b_over_D,h_over_b,beta_deg,b_over_D_blade_form,h_over_b_blade_form,beta_deg_blade_form,blade_form_r_over_R")
        for rR in sort(collect(keys(FIG3C)))
            bd, hb, beta = FIG3C[rR]
            rk = keys_bf[argmin(abs.(keys_bf .- rR))]
            bd_ref, hb_ref, beta_ref = bfrows[rk]
            max_bd = max(max_bd, abs(bd - bd_ref))
            max_hb = max(max_hb, abs(hb - hb_ref))
            max_beta = max(max_beta, abs(beta - beta_ref))
            println(io, join([rR, bd, hb, beta, bd_ref, hb_ref, beta_ref, rk], ','))
        end
    end
    println("wrote $OUT")
    println("I-11 max |d(b/D)|=$(round(max_bd; digits=4)) |d(h/b)|=$(round(max_hb; digits=4)) |d beta|=$(round(max_beta; digits=2)) deg")
    println("panel (c) confirmed NACA 4-(5)(08)-03; blade_form.csv unchanged as 25b input")
end

main()
