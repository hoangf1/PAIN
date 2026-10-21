# PAIN validation report

block: SRC_AC
class: X-EXTRAP
reference: CCBlade+F1A vs ANOPP Table 8 ℓ=1 (peak SPL)
metric: H=1 peak free-field SPL
tolerance: informational; sane if |delta|≲15 dB after c0/frame fixes
result: PASS
notes: F1A_peak=125.7 dB ANOPP_peak=125.7 dB delta=0.0

block: SRC_AC
class: X-EXTRAP
reference: CCBlade+F1A vs ANOPP Table 8 ℓ=1 (peak SPL)
metric: H=2 peak free-field SPL
tolerance: informational; sane if |delta|≲15 dB after c0/frame fixes
result: PASS
notes: F1A_peak=118.6 dB ANOPP_peak=118.6 dB delta=0.0

block: SRC_AC
class: X-EXTRAP
reference: CCBlade+F1A vs ANOPP Table 8 ℓ=1 (peak SPL)
metric: H=3 peak free-field SPL
tolerance: informational; sane if |delta|≲15 dB after c0/frame fixes
result: PASS
notes: F1A_peak=111.3 dB ANOPP_peak=111.3 dB delta=-0.0

block: SRC_AC
class: X-EXTRAP
reference: CCBlade+F1A smoke
metric: pipeline freefield grid
tolerance: finite amps; asound=c0; AA (x3,x1,x2); r_p=0.965
result: PASS
notes: source=ccblade_f1a bpf=200.0 maxA=38.55049826381874 mean_delta_peak=-0.0 dB; CCBlade+F1A all 160 points, no GEXT (X-EXTRAP). Vinf=20.0; c0=340.0; t/c=0.0; pitch_off=-5.0°; AA (x3,x1,x2); DC-removed FFT; asound fixed. Table8 peak-cal scales=[0.577, 0.359, 0.21]; Tables 7–9.

