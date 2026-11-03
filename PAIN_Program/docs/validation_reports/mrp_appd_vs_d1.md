Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)

# MRP_APPD — re-recorded at L = 1.83 m

Label: **V-CODE (vs NASA's solver outputs), first run of the printed App. D formulation 2026-10-22**

## Verdict

**`met`** — 27/32 within 5 % (84.4 %); criterion ≥ 75 % of 32 within 5 %, no calibration (fixed 2026-10-22). Fig. D-2 mode-1: max |Δw| = 1.4534 over 49 digitized points (no pass mark)

## Table

| quantity | x | reference | computed | residual | ok |
|---|---:|---:|---:|---:|:--:|
| f_Hz mode 1 | 1.0 | 188.52 | 197.10784747283356 | 8.587847472833545 | true |
| f_Hz mode 2 | 2.0 | 208.24 | 207.04733078748768 | -1.1926692125123282 | true |
| f_Hz mode 3 | 3.0 | 217.88 | 214.3815465128721 | -3.498453487127904 | true |
| f_Hz mode 4 | 4.0 | 231.01 | 225.2382328537797 | -5.771767146220299 | true |
| f_Hz mode 5 | 5.0 | 293.25 | 292.4301050746561 | -0.8198949253438741 | true |
| f_Hz mode 6 | 6.0 | 301.93 | 287.33240128940145 | -14.597598710598561 | true |
| f_Hz mode 7 | 7.0 | 303.67 | 316.7522017108257 | 13.0822017108257 | true |
| f_Hz mode 8 | 8.0 | 318.73 | 341.2489332071612 | 22.518933207161183 | false |
| f_Hz mode 9 | 9.0 | 346.71 | 344.48138927367796 | -2.2286107263220174 | true |
| f_Hz mode 10 | 10.0 | 434.31 | 437.8141304764896 | 3.5041304764895926 | true |
| f_Hz mode 11 | 11.0 | 441.78 | 441.71774811967606 | -0.062251880323913156 | true |
| f_Hz mode 12 | 12.0 | 470.53 | 480.1325949358116 | 9.602594935811624 | true |
| f_Hz mode 13 | 13.0 | 502.23 | 493.7626164212585 | -8.467383578741533 | true |
| f_Hz mode 14 | 14.0 | 528.78 | 528.1575956288592 | -0.6224043711407603 | true |
| f_Hz mode 15 | 15.0 | 555.05 | 567.3457941143436 | 12.295794114343607 | true |
| f_Hz mode 16 | 16.0 | 558.43 | 570.817339058709 | 12.387339058709017 | true |
| f_Hz mode 17 | 17.0 | 560.65 | 576.6189200897179 | 15.968920089717926 | true |
| f_Hz mode 18 | 18.0 | 572.86 | 586.1395066984171 | 13.279506698417094 | true |
| f_Hz mode 19 | 19.0 | 591.88 | 602.2187475372963 | 10.338747537296285 | true |
| f_Hz mode 20 | 20.0 | 607.5 | 610.0322648796464 | 2.532264879646391 | true |
| f_Hz mode 21 | 21.0 | 626.01 | 621.9725453796051 | -4.037454620394897 | true |
| f_Hz mode 22 | 22.0 | 632.02 | 631.7779982365852 | -0.24200176341480528 | true |
| f_Hz mode 23 | 23.0 | 636.15 | 652.2160452184031 | 16.066045218403133 | true |
| f_Hz mode 24 | 24.0 | 641.2 | 663.4065458632494 | 22.206545863249403 | true |
| f_Hz mode 25 | 25.0 | 648.7 | 675.4896133649632 | 26.789613364963202 | true |
| f_Hz mode 26 | 26.0 | 663.3 | 681.9610903757723 | 18.661090375772346 | true |
| f_Hz mode 27 | 27.0 | 716.23 | 696.7987707052224 | -19.43122929477761 | true |
| f_Hz mode 28 | 28.0 | 717.33 | 686.4732027906698 | -30.85679720933024 | true |
| f_Hz mode 29 | 29.0 | 738.44 | 524.985616001152 | -213.45438399884802 | false |
| f_Hz mode 30 | 30.0 | 761.91 | 519.3108673764187 | -242.59913262358123 | false |
| f_Hz mode 31 | 31.0 | 779.76 | 487.83277713662744 | -291.92722286337255 | false |
| f_Hz mode 32 | 32.0 | 811.04 | 452.90008430722884 | -358.1399156927711 | false |
| Fig. D-2 max |Δw| (info) | 0.0 | 0.0 | 1.4534464541325456 | 1.4534464541325456 | true |

inputs: (n_modes = 32, npass = 27, tol_frac = 0.05, count_rule = "≥75% of 32 within 5%", count_rule_date = "2026-10-22", calibration = false, L = 1.83, readings = (attachment = :rigid, asterisk_terms = false, d25_thickness_rule = :page_D10, theta_origin = :bottom_centerline, L_source = "App. E p. E-1 / I-22: 1.83 m (test_article_length)", material_source = "MRP_E_2024 / MRP_NU_2024 / MRP_RHO_2024 (Manual §5.2)", constraint_reduction = :nullspace_of_C), reference_tables = ["TABLE_D1_FULL", "fig_d2_mode1_digitized.csv"])
