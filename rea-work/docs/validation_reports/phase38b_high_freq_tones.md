# Phase 38b — CR-3813 §3.2 high-frequency tone formulation (Eqs. 11–16)

First run 2026-10-22. Criteria fixed in `IMPLEMENTATION_PLAN.md` §8 row 38b and issue I-18
(**dated 2026-10-21, before any run; not changed**). No parameter chosen from REPRO_18b / T1 / E-16.
No mirroring adopted after seeing the result.

## Equations as implemented

Transcribed from page images `docs/specs/cr3813_pages/cr3813_pdf027.png`–`pdf031.png` (pp. 17–21).
Code: `PAIN.jl/src/high_freq_tones.jl`.

| Eq. | Form in code |
|-----|----------------|
| (11)–(13) | Rearrangement of the tone sum with \(g_n\), \(g_r\), \(Q_H\); resonances restricted to Δω about \(\omega_H\) |
| (14) | \(E[\langle p_i^2\rangle]\) with \(\omega_n,\omega_r\) independent uniform on Δω → factors \(E[g_n]\,E[g_r]\) |
| E[\(g\)] | Closed arctan form (p. 19); π-limit \(E[g]=\pi\omega_H/(2\bar\eta\Delta\omega)\) when \(\bar\eta\omega_H\ll\Delta\omega\) |
| (15) | Modal-density form with \(\langle\varepsilon_n f'^2\rangle_{\Delta\omega}\) (diagnostic path `p2_eq15`) |
| (16) | Production expected value: \((\omega_H^2/(c_0 V))\,(n_r\tau_{ML}\tau_t)/(\bar\eta_r\bar\eta_n)\,(mA/4)^2\,[(1/N_r)\sum_r\Psi_G j_r^{\mathrm{rev}}/M_r^2]\) |

### Readings decided

1. **Δω / \(c_\omega\)**: \(\Delta\omega=c_\omega\omega_H\) with \(c_\omega=0.232\) (1/3-octaves, CR-3813 p. 10; same as 38a). Band centred on the harmonic, \([\omega_H(1-c_\omega/2),\omega_H(1+c_\omega/2)]\).
2. **\(\bar\eta_n\)**: arithmetic mean of \(\eta_n\) (Eq. 77 or \(\eta_{n,\mathrm{bare}}\)) over acoustic modes in the band. **\(\bar\eta_r\)**: arithmetic mean of \(\eta_r'\) (Eqs. 79–82) over structural modes in the band. Pair-dependent \(\eta_r''\) (Eq. 83) is not folded into \(\bar\eta_r\).
3. **\(f'\)**: barred \(\bar f'\) of Eq. (52) with \(\sqrt{\tau_t}\) on the shell term — same choice as Eq. (8) / 38a. For the Eq. (15) path that still has \(\langle\varepsilon_n f'^2\rangle\), the printed extra \(\tau_t^H\) in \(Q_H\) is omitted to avoid double-counting. Printed Eq. (16) keeps \(\tau_t^H\) after replacing \(\langle\varepsilon_n f'^2\rangle\) by \(j_r^{\mathrm{rev}}\) (as printed; τ_t applies to Eqs. 16, 18, 23).
4. **E[\(g\)] numerical check**: integrates the resonance-local integrand that yields the printed arctan (not the exact \(g(\omega_H/\omega)\) integral, which is not the arctan).
5. **Crossover (Manual card 10)**: reuse `acoustic_crossover_band` (38a); override via `PainInputs.crossover_band_Hz`.
6. **Production selector**: `tone_model=:eq8` (default, unchanged outputs), `:eq15_16`, or `:auto` (Eq. 8 below crossover centre, Eq. 16 at/above). Both formulations always stored on `InteriorSpectrum`.

## Crossover band (test article)

| Quantity | Value |
|----------|-------|
| Centre frequency | **396.85 Hz** (ISO 1/3-oct centre ≈ 400 Hz) |
| Acoustic modes in band | **10** |
| Rule | Lowest 1/3-oct with ≥ 10 three-dimensional acoustic modes |

## REPRO_18b with `tone_model=:auto` (18b-r inputs; one run)

Inputs: ANOPP Table 8 + GEXT, R1, Phase III trim \(\eta_T=0.5\), BPF = 200 Hz. NASA (Fig. E-16): 79.0, 75.5, 68.0 dB. Criterion: \|Δ\| ≤ 4 dB.

| H | f (Hz) | Eq. (8) dB | Eq. (15)–(16) dB | Production (`:auto`) | Model used | Δ vs NASA | \|Δ\| ≤ 4 |
|---|--------|------------|------------------|----------------------|------------|-----------|----------|
| 1 | 200 | 85.74 | 68.03 | **85.74** | `:eq8` | +6.74 | no |
| 2 | 400 | 78.74 | 16.89 | **16.89** | `:eq15_16` | −58.61 | no |
| 3 | 600 | 80.06 | 72.31 | **72.31** | `:eq15_16` | +4.31 | no |

Per-harmonic band counts / averages at the harmonic centre: H1 \(N_n=3\), \(N_r=3\); H2 \(N_n=12\), \(N_r=2\); H3 \(N_n=26\), \(N_r=12\).

### I-18 “explains H3” rule (dated 2026-10-21)

Defined as: with the 38b crossover rule, REPRO_18b H3 within 4 dB of NASA’s 68.0 dB where the Eq. (8) value is not.

| Check | Value |
|-------|-------|
| Eq. (8) H3 | 80.06 dB → \|Δ\| = 12.06 dB (not within 4) |
| `:auto` H3 (Eq. 16) | 72.31 dB → \|Δ\| = **4.31 dB** (not within 4) |
| **Explains H3?** | **No** |

Mirroring (I-18) is **not** adopted. Numbers reported only; nothing changed after the run.

## Tests run

```text
Pkg.test("PAIN"; test_args=["High-frequency tones", "Validation case registry"])
```

- **High-frequency tones Eqs. (11)–(16) (38b)** — PASS (V-UNIT: E[\(g\)] closed = quad 1e-8; Eq. 13 MC vs expected value with stated sampling tolerance; default `:eq8` matches baselines; crossover ≥10 + synthetic + card-10 override).
- **Validation case registry (34d)** — PASS (includes REPRO_18b Eq. (8) baselines 85.74, 78.74, 80.06).

## Default behaviour

Unchanged. `tone_mean_square_pressure` and `interior_spl(...; tone_model=:eq8)` reproduce prior Eq. (8) results exactly.
