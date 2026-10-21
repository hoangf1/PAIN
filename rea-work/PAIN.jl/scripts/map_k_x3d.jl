a = 0.508
D = 0.762
kp = 8
dx = π * a / 18
for k in 1:16
    x3 = dx * (kp - k)
    println("k=$k  x3=$(round(x3; digits=4))  X3D=$(round(x3 / D; digits=3))")
end
