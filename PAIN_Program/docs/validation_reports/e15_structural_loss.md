Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)

# E15_STRUCT_LOSS — re-recorded at L = 1.83 m

Label: **V-EXP; Fig. E-15 η_r′ with η_T=1.0 and η_r_cap=0.15; no pass mark; first run 2026-10-22**

## Verdict

**`no_verdict`** — V-EXP info: 4/8 within CSV tol_frac (no pass mark); quantity = η_r′ (Eq. 82 with trim), not bare η_r; η_T=1.0, η_r_cap=0.15 (E-18/E-21)

## Table

| quantity | x | reference | computed | residual | ok |
|---|---:|---:|---:|---:|:--:|
| η_r′ f=150.0 | 150.0 | 0.06 | 0.15 | 0.09 | false |
| η_r′ f=300.0 | 300.0 | 0.07 | 0.15 | 0.07999999999999999 | false |
| η_r′ f=500.0 | 500.0 | 0.1 | 0.12692881214702634 | 0.026928812147026332 | true |
| η_r′ f=800.0 | 800.0 | 0.06 | 0.10748128770133485 | 0.04748128770133485 | false |
| η_r′ f=1200.0 | 1200.0 | 0.05 | 0.053484464893930626 | 0.0034844648939306236 | true |
| η_r′ f=1500.0 | 1500.0 | 0.04 | 0.038563872612713344 | -0.0014361273872866565 | true |
| η_r′ f=2500.0 | 2500.0 | 0.025 | 0.014730726333265923 | -0.010269273666734078 | true |
| η_r′ f=4000.0 | 4000.0 | 0.03 | 0.007845419828096034 | -0.022154580171903963 | false |

inputs: (η_T = 1.0, η_r_cap = 0.15, quantity = "η_r′ (Eq. 82 with Phase III trim)", figure = "CR-3813 Fig. E-15 (total structural loss factor; trim curves + 0.15 upper limit)", n_within = 4, n_bands = 8, criterion = "none (V-EXP info; 16b)", date = "2026-10-21", csv = "D:\\code\\PAIN\\rea-work\\data\\cr3813\\e15_structural_loss_targets.csv")
