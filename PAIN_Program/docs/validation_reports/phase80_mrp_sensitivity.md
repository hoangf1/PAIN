# Phase 80f: App. D input sensitivity for a new fuselage (report only, no verdict)

Generated 2026-10-29 by `scripts/run/phase80_mrp_sensitivity.jl`. Fuselage: the 2.64 m working example (`aircraft_scale_hartzell_cabin_full.json`, parametric path, App. D solver with NASA's floor form and series limits). Each input ×0.8 and ×1.2, one at a time. Nothing is chosen from these numbers.

Baseline: lowest structural mode 16.6 Hz; interior H1, H2, H3 = 81.38, 56.37, 30.41 dB.

| Input | Factor | Δf mode 1 (%) | mean \|Δf\| of 32 modes (%) | ΔH1 (dB) | ΔH2 (dB) | ΔH3 (dB) |
|---|---|---|---|---|---|---|
| `t_skin_m` | ×0.8 | -0.01 | +0.61 | +1.31 | -0.27 | -0.47 |
| `t_skin_m` | ×1.2 | +0.01 | +0.52 | -2.01 | -1.46 | -1.38 |
| `t_floor_m` | ×0.8 | +8.67 | +7.01 | -0.11 | -0.12 | -0.65 |
| `t_floor_m` | ×1.2 | -6.75 | +5.58 | +1.02 | -1.38 | -1.68 |
| `A_stringer_m2` | ×0.8 | -0.00 | +0.02 | +0.08 | +0.05 | +0.05 |
| `A_stringer_m2` | ×1.2 | +0.00 | +0.02 | -0.08 | -0.05 | -0.05 |
| `d_stringer_m` | ×0.8 | +0.00 | +0.02 | -0.10 | -0.06 | -0.06 |
| `d_stringer_m` | ×1.2 | -0.00 | +0.01 | +0.06 | +0.04 | +0.04 |
| `I_stringer_m4` | ×0.8 | -0.00 | +0.00 | -0.00 | -0.00 | -0.00 |
| `I_stringer_m4` | ×1.2 | +0.00 | +0.00 | +0.00 | +0.00 | +0.00 |
| `A_frame_m2` | ×0.8 | -0.00 | +0.22 | +1.27 | +0.74 | +0.64 |
| `A_frame_m2` | ×1.2 | +0.00 | +0.20 | -0.90 | -0.47 | -0.46 |
| `ell_frame_m` | ×0.8 | +8.11 | +4.32 | -0.18 | -0.24 | -0.82 |
| `ell_frame_m` | ×1.2 | -6.35 | +3.49 | +1.99 | +0.14 | +0.52 |
| `I_frame_m4` | ×0.8 | -0.02 | +1.09 | -0.88 | -1.15 | -1.12 |
| `I_frame_m4` | ×1.2 | +0.01 | +0.87 | -0.74 | -2.20 | -2.52 |
| `A_floor_beam_m2` | ×0.8 | +2.16 | +1.76 | -0.53 | -0.09 | -0.25 |
| `A_floor_beam_m2` | ×1.2 | -2.02 | +1.64 | +1.11 | +0.06 | +0.12 |
| `I_floor_beam_m4` | ×0.8 | -10.41 | +8.65 | -2.01 | -1.56 | -2.51 |
| `I_floor_beam_m4` | ×1.2 | +9.41 | +7.41 | -0.16 | -0.34 | -0.98 |
| `E_Pa` | ×0.8 | -10.56 | +10.56 | -0.69 | -0.14 | -0.06 |
| `E_Pa` | ×1.2 | +9.54 | +9.54 | +0.78 | +0.15 | +0.06 |
| `nu` | ×0.8 | -0.02 | +0.04 | -0.01 | -0.01 | -0.00 |
| `nu` | ×1.2 | +0.03 | +0.05 | +0.01 | +0.01 | +0.00 |
| `rho_struc_kg_m3` | ×0.8 | +11.80 | +11.80 | +2.93 | +2.12 | +2.01 |
| `rho_struc_kg_m3` | ×1.2 | -8.71 | +8.71 | -2.17 | -1.70 | -1.63 |
| `L_m` | ×0.8 | +5.06 | +21.41 | +1.63 | +0.73 | -0.37 |
| `L_m` | ×1.2 | -1.94 | +13.33 | +1.88 | -1.66 | -1.81 |
| `a_m` | ×0.8 | +53.19 | +32.56 | -2.42 | +2.33 | -12.31 |
| `a_m` | ×1.2 | -28.70 | +19.56 | -4.15 | -6.23 | +5.32 |
| `theta0_deg` | ×0.8 | +35.91 | +20.19 | +4.95 | -1.18 | +1.50 |
| `theta0_deg` | ×1.2 | -17.72 | +11.05 | +0.57 | -0.15 | -0.96 |

`L_m`, `a_m` and `theta0_deg` also move the acoustic modes, the grid and the propeller clearance, so their level changes are not structural alone.
