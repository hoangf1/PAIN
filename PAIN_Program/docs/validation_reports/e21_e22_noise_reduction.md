Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)

# E21_E22_NR — re-recorded at L = 1.83 m

Label: **V-CODE (vs NASA) / V-EXP held out (vs E-22); first run 2026-10-21**

## Verdict

**`not_met`** — V-CODE 1/4 (|Δ|≤3 dB vs NASA); V-EXP 0/4 (inside E-22 95%); E-21 range (secondary) 2/4; crossover=400.0 Hz; excluded 80,100,125,160 Hz (end-plate V-ASSUMED); counts below crossover only

## Table

| quantity | x | reference | computed | residual | ok |
|---|---:|---:|---:|---:|:--:|
| vs NASA prediction | 63.0 | 16.0 | 58.43568459496915 | 42.43568459496915 | false |
| vs E-22 95 % limits | 63.0 | 12.5 | 58.43568459496915 | 45.93568459496915 | false |
| vs NASA prediction | 80.0 | 10.5 | 54.18294153307702 | 43.68294153307702 | false |
| vs E-22 95 % limits | 80.0 | 13.5 | 54.18294153307702 | 40.68294153307702 | false |
| vs E-22 95 % limits | 100.0 | 14.0 | 49.759027918631844 | 35.759027918631844 | false |
| vs NASA prediction | 125.0 | 23.5 | 44.88931090564207 | 21.38931090564207 | false |
| vs E-22 95 % limits | 125.0 | 23.5 | 44.88931090564207 | 21.38931090564207 | false |
| vs NASA prediction | 160.0 | 27.5 | 33.546785595492665 | 6.046785595492665 | false |
| vs E-22 95 % limits | 160.0 | 15.5 | 33.546785595492665 | 18.046785595492665 | false |
| vs NASA prediction | 200.0 | 24.5 | 23.07328233351985 | -1.426717666480151 | true |
| vs E-22 95 % limits | 200.0 | 14.75 | 23.07328233351985 | 8.323282333519849 | false |
| vs NASA prediction | 250.0 | 27.0 | 20.793526231508572 | -6.206473768491428 | false |
| vs E-22 95 % limits | 250.0 | 14.0 | 20.793526231508572 | 6.793526231508572 | false |
| vs NASA prediction | 315.0 | 23.5 | 14.056475222040607 | -9.443524777959393 | false |
| vs E-22 95 % limits | 315.0 | 17.5 | 14.056475222040607 | -3.443524777959393 | false |
| vs NASA prediction | 400.0 | 21.5 | 19.548297496636433 | -1.9517025033635669 | true |
| vs E-22 95 % limits | 400.0 | 18.0 | 19.548297496636433 | 1.5482974966364331 | false |
| vs NASA prediction | 500.0 | 16.0 | 14.990495092660105 | -1.0095049073398954 | true |
| vs E-22 95 % limits | 500.0 | 19.5 | 14.990495092660105 | -4.509504907339895 | false |
| vs NASA prediction | 630.0 | 13.0 | 14.566187995369752 | 1.5661879953697522 | true |
| vs E-22 95 % limits | 630.0 | 19.25 | 14.566187995369752 | -4.683812004630248 | false |
| vs NASA prediction | 800.0 | 17.0 | 23.157318223065076 | 6.157318223065076 | false |
| vs E-22 95 % limits | 800.0 | 20.25 | 23.157318223065076 | 2.907318223065076 | false |
| vs NASA prediction | 1000.0 | 24.5 | 42.21278714108767 | 17.712787141087666 | false |
| vs E-22 95 % limits | 1000.0 | 20.5 | 42.21278714108767 | 21.712787141087666 | false |
| vs E-22 95 % limits | 1250.0 | 19.75 | 58.397034282647695 | 38.647034282647695 | false |
| vs NASA prediction | 1600.0 | 51.5 | 67.88493152443644 | 16.38493152443644 | false |
| vs E-22 95 % limits | 1600.0 | 25.75 | 67.88493152443644 | 42.13493152443644 | false |
| vs NASA prediction | 2000.0 | 59.0 | 75.0055747575974 | 16.0055747575974 | false |
| vs E-22 95 % limits | 2000.0 | 26.5 | 75.0055747575974 | 48.5055747575974 | false |
| vs NASA prediction | 2500.0 | 68.5 | 81.57520079607706 | 13.075200796077056 | false |
| vs E-22 95 % limits | 2500.0 | 32.25 | 81.57520079607706 | 49.325200796077056 | false |
| vs NASA prediction | 3150.0 | 68.5 | 88.0757152778152 | 19.575715277815206 | false |
| vs E-22 95 % limits | 3150.0 | 32.5 | 88.0757152778152 | 55.575715277815206 | false |
| vs E-22 95 % limits | 4000.0 | 36.0 | 94.6071934511464 | 58.6071934511464 | false |

inputs: (η_lining = 1.0, η_r_cap = 0.15, crossover_Hz = 400.0, crossover_n_modes = 12, n_nasa_ok = 1, n_nasa = 4, n_e22_ok = 0, n_e22 = 4, n_range_ok = 2, n_range = 4, excluded_Hz = (80, 100, 125, 160), criterion = "|Δ|≤3 dB vs NASA ≥75%; inside E-22 ≥75%; below crossover; 80–160 excluded", date = "2026-10-21", csv_e21 = "D:\\code\\PAIN\\rea-work\\data\\cr3813\\e21_noise_reduction_range.csv", csv_e22 = "D:\\code\\PAIN\\rea-work\\data\\cr3813\\e22_noise_reduction_ci.csv")
