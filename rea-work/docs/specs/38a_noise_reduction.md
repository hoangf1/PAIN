# Task 38a â€” CR-3813 Â§3.3 noise reduction (reverberant exterior field) + E21_E22_NR case

Repo `D:\code\PAIN\rea-work\PAIN.jl`. Read `D:\code\PAIN\CLAUDE.md` and `rea-work/docs/IMPLEMENTATION_PLAN.md` Â§8 Phase 38 (row
38a with its criteria and scope note â€” **dated before this run; do not change them**). Implement the text as printed. No tuning:
no parameter is chosen by looking at E-21/E-22. No docs except as listed. No commit. Never open a GUI window.

## Equations (transcribed from the page images in
`rea-work\docs\specs\cr3813_pages\`
â€” `cr3813_pdf031.png` (p. 21), `pdf032` (p. 22), `pdf033` (p. 23); read them yourself and check this transcription)

Band: centre Ï‰, width Î”Ï‰ = c_Ï‰ Ï‰, **c_Ï‰ = 0.232** for 1/3-octaves (CR-3813 p. 10).

For j âˆˆ {n (acoustic), r (structural)}:
- b_n = âˆ’2Ï‰_nÂ², b_r = âˆ’2Ï‰_rÂ²
- c_n = Ï‰_nâ´(1 + Î·_nÂ²), c_r = Ï‰_râ´[1 + (Î·_râ€² + Î·_râ€³)Â²]
- ln_j = ln{ |(1+c_Ï‰/2)â´Ï‰â´ + b_j(1+c_Ï‰/2)Â²Ï‰Â² + c_j| / |(1âˆ’c_Ï‰/2)â´Ï‰â´ + b_j(1âˆ’c_Ï‰/2)Â²Ï‰Â² + c_j| }
- arctan_j = tanâ»Â¹[((2+c_Ï‰)Â²Ï‰Â² âˆ’ 4Ï‰_jÂ²)/(4Î·_jÏ‰_jÂ²)] âˆ’ tanâ»Â¹[((2âˆ’c_Ï‰)Â²Ï‰Â² âˆ’ 4Ï‰_jÂ²)/(4Î·_jÏ‰_jÂ²)],
  with Î·_j = Î·_râ€² + Î·_râ€³ for j = r and Î·_j = Î·_n for j = n
- D_nr = (c_r âˆ’ c_n)Â² + (b_n âˆ’ b_r)(b_n c_r âˆ’ b_r c_n)
- {â€¦}_nr = ((c_râˆ’c_n)/4) ln_n + ((2c_n(b_râˆ’b_n) âˆ’ b_n(c_râˆ’c_n))/(4Î·_nÏ‰_nÂ²)) arctan_n
          + ((c_nâˆ’c_r)/4) ln_r + ((2c_r(b_nâˆ’b_r) âˆ’ b_r(c_nâˆ’c_r))/(4(Î·_râ€²+Î·_râ€³)Ï‰_rÂ²)) arctan_r

**Eq. (18):** âŸ¨p_iÂ²âŸ©_s,t / âŸ¨p_eÂ²âŸ©_s,t = (8/(c_Ï‰ Ï‰)) (Ä€Â²/VÂ²) (mA/4)Â² Ï„_ML câ‚€Â² Ï‰Â³ Î£_n Îµ_n Î£_r [ j_rÂ²(Ï‰)^rev fÌ„â€²Â²(n,r) / (M_rÂ² D_nr) ] {â€¦}_nr
(Eq. 17 is the corresponding W_in with âŸ¨p_blÂ²âŸ©, the factor (2/Ï€) Ï‰Â²Ï‰_nÂ²/D_nr and Îµ_n n_n â€” implement it too as a function and
check Eq. 18 = W_in/W_diss route numerically, see tests.)
- Ä€ = surface area of the complete cylinder; A = coupling area; V = cavity volume; M_r generalized mass; Îµ_n normalization;
  (mA/4)Â²Ï„_ML: use the identity already verified in phase 19b (`(mA/4)Â²Ï„_ML = (Ïâ‚€câ‚€A/(2Ï‰))Â²`) â€” read `pain_core.jl` and reuse,
  do not re-derive differently. fÌ„â€²(n,r): the barred coupling factor (CR-3813 Â§3.5; check the code's `coupling_factor` and the 19g
  note on the barred/unbarred fâ€² in Eq. 83 â€” use the barred form as printed; state which function you use and why).
- j_rÂ²(Ï‰)^rev: reverberant joint acceptance of structural mode r (CR-3813 Â§3.6, diffuse correlation sin(kÎ¾)/(kÎ¾), Eq. (60) ff.);
  the code has it as `structural_joint_acceptance` (checked against quadrature in 16b) â€” confirm it is the reverberant form and
  reuse it.
- Sums over **all** acoustic modes n = (q, i) (CYL2D 20 cross-section modes Ã— q â‰¤ q_max for the band's upper edge) and all
  structural modes r (Table D-1, 32), with symmetry selection as in `coupling_factor`.
- Exterior: âŸ¨p_eÂ²âŸ©_s,t = âŸ¨p_blÂ²âŸ©/2 (p. 23). **NR(band) = 10 log10(âŸ¨p_eÂ²âŸ©/âŸ¨p_iÂ²âŸ©)** = âˆ’10 log10(Eq. 18).
- Loss factors: Î·_n from Eq. (77) with the trim (as in the tone path), Î·_râ€² from Eq. (82), Î·_râ€³ from Eq. (83); **NASA's E-21/E-22
  settings (CR-3813 p. E-30): Phase III trim with Î·_T = 1.0 (`phase3_trim(; Î·_lining=1.0)`), and Î·_râ€² capped at 0.15**. Add a
  keyword `Î·_r_cap::Union{Nothing,Float64}=nothing` where Î·_râ€² is formed (default nothing = no cap; documented as the NASA E-18/E-21
  run setting). The end-plate allowance of ref. [7] is not available: not applied (flag 80â€“160 Hz as V-ASSUMED in the output).
- Crossover band (38b rule, fixed): the lowest 1/3-octave band whose count of 3-D acoustic modes (q, i) with resonance inside
  [Ï‰(1âˆ’c_Ï‰/2), Ï‰(1+c_Ï‰/2)] is â‰¥ 10. Compute it and report it; Eq. (18) values at and above it are reported but marked
  "above crossover â€” high-frequency model needed (38c)".

## Code
- New `src/noise_reduction.jl`: `noise_reduction_band(inp, fc; Î·_r_cap=nothing)` â†’ NamedTuple (ratio, NR_dB, n_modes_in_band,
  above_crossover, â€¦), `noise_reduction_spectrum(inp; bands, Î·_r_cap)`, `acoustic_crossover_band(inp; bands)`, the ln/arctan/D_nr
  helpers, and Eq. (17) `w_in_reverberant(...)`. Include in `PAIN.jl`, export.
- `E21_E22_NR` case (replace the greyed placeholder; `validation_case_extras.jl`): inputs per p. E-30; reference CSVs
  `data/cr3813/e21_noise_reduction_range.csv` (mean, low, high, nasa_pred_dB) and `data/cr3813/e22_noise_reduction_ci.csv` (95 % limits);
  table rows per band with group "vs NASA prediction" (|Î”| â‰¤ 3 dB) and "vs E-22 95 % limits" (inside); verdict **exactly** per the
  plan row 38a criteria and scope note: bands 80, 100, 125, 160 Hz excluded from both counts (end-plate allowance), only bands
  below the crossover counted in 38a, both counts â‰¥ 75 % for `:met`; reason lists both counts, the crossover band and the excluded
  bands. Label "V-CODE (vs NASA) / V-EXP held out (vs E-22); first run 2026-10-21". Plot as Figs. E-21/E-22: NR vs band (log x),
  measured mean + range band + 95 % band, NASA prediction, computed; error panel vs NASA (tol 3). Map: keep it on the PAIN map
  in block P_MEAS, kind runnable; update CASE_INFO/Â§2.13 later (not this task).

## Tests (V-UNIT before any comparison)
1. Helpers: for a single (n, r) pair, the closed form {â€¦}_nr / D_nr equals direct numerical integration over the band of the
   product of the two resonance responses that Eq. (17) integrates (derive the integrand from Eqs. 5â€“7/17; tolerance 1e-6 relative).
2. Limits: Î·â†’0 behaviour finite; Ï‰ far from both resonances â†’ small; symmetric/antisymmetric pairs that do not couple give 0.
3. Î·_r_cap = nothing reproduces the current tone results exactly (no change to existing outputs).
4. Eq. (17)/(5) route: W_in from Eq. (17) divided by the dissipated power for one mode equals the Eq. (18) contribution (1e-9).
5. Case runs, table/series non-empty, verdict follows the counts.
Run only the new noise-reduction testset and "Validation case registry" via the P1 filter (`Pkg.test("PAIN"; test_args=[...])`),
not the full suite (the reviewer runs it once). Report: equations as implemented (with any reading you had to decide and
why), the crossover band, the per-band NR table vs NASA and E-22, both counts and the verdict. Do not change anything after
seeing the comparison.

