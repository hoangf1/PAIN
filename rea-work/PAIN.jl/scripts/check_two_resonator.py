#!/usr/bin/env python3
"""Plan steps 19a and 19b: CR-3813 Eqs. (4)-(8), (83) against an exactly solved two-resonator model.

Run from rea-work/PAIN.jl:   python scripts/check_two_resonator.py
Needs sympy and numpy. Writes ../docs/validation_reports/eq8_two_resonator.md.
Criteria are fixed in IMPLEMENTATION_PLAN.md, phase 19 (2026-10-20), before this script was first run.
Nothing here is fitted; the numerical case uses test-article-like magnitudes only to exercise the algebra.

Model (time factor e^{+i w t}, complex amplitudes, hysteretic loss factors as in the denominators of Eq. 8):
  structure  M_r (w_r^2 (1 + i eta_r) - w^2) Q = F - A f' P                (interior pressure pushes outward)
  cabin      (w_n^2 (1 + i eta_n) - w^2) P = -(rho c^2 eps_n / V) A f' w^2 Q  (inward wall acceleration)
  with Q the structural modal coordinate (w = Q psi_r, positive inward), P the cabin modal amplitude
  (p = P phi_n, int phi_n^2 dV = V/eps_n), A f'(n,r) = int_A phi_n psi_r dA (CR-3813 p. 12),
  F = int p_bl psi_r dA the generalized blocked force, Psi_G = |F|^2/2 (tone cospectrum, Eq. 42).
  <p_n^2>_s,t = |P|^2/(2 eps_n);  wall inflow = (1/2) Re(A f' P conj(i w Q)).
"""
import os
import numpy as np
import sympy as sp

HERE = os.path.dirname(os.path.abspath(__file__))
REPORT = os.path.join(HERE, "..", "..", "docs", "validation_reports", "eq8_two_resonator.md")

out = []
results = {}


def say(s=""):
    out.append(s)


# ---------------------------------------------------------------- 1. symbolic (19a item 1, 19b)
rho, c, A, V, m, w, wn, wr, etan, etar, eps, f, M, Psi = sp.symbols(
    "rho c A V m omega omega_n omega_r eta_n eta_r epsilon_n f M_r Psi_G", positive=True)
tauML = (2 * rho * c / (w * m)) ** 2                       # CR-3813 p. 11
Dn_hat = (1 - w**2 / wn**2) ** 2 + etan**2
Dr_hat = (1 - w**2 / wr**2) ** 2 + etar**2

# Eq. (4) prefactor with S_pbl j_r^2 = Psi_G / A^2 (j_r^2 definition, p. 12)
K4 = rho * c**2 * A**4 / V / A**2
# Eq. (6) prefactor including the explicit omega^2
K6 = 2 * sp.pi / (rho * V) * (m * A / 4) ** 2 * tauML * sp.Rational(2) / sp.pi * w**2
c_eq6 = sp.simplify(K6 - K4) == 0

ident = sp.simplify((m * A / 4) ** 2 * tauML - (rho * c * A / (2 * w)) ** 2) == 0      # 19b
ident_m_free = sp.diff(sp.simplify((m * A / 4) ** 2 * tauML), m) == 0

# Eq. (7): delta(omega - omega_H) collapses the band integral to omega_H^3 / (Dn Dr)
Win7 = K6 * eps * etan / wn**2 * f**2 * Psi / (M**2 * wr**4) * w**3 / (Dn_hat * Dr_hat)
# Eq. (5), n-th term, solved for <p_n^2>
p2 = sp.Symbol("p2", positive=True)
p2_sol = sp.solve(sp.Eq(V / (rho * c**2) * etan * wn**2 / w * p2, Win7), p2)[0]
Eq8 = 4 * c**2 / V**2 * (m * A / 4) ** 2 * tauML * w**6 * eps / wn**4 * f**2 * Psi / (M**2 * wr**4 * Dn_hat * Dr_hat)
c_eq8 = sp.simplify(p2_sol - Eq8) == 0
# code form (pain_core.jl): (c0/V)^2 (rho0 c0 A)^2 w^4 eps f^2 Psi / (M^2 Dn Dr), dimensional denominators
code = (c / V) ** 2 * (rho * c * A) ** 2 * w**4 * eps * f**2 * Psi / (M**2 * wn**4 * Dn_hat * wr**4 * Dr_hat)
c_code = sp.simplify(code - Eq8) == 0

# exact two-resonator solution, symbolic
F = sp.Symbol("F", positive=True)       # |F|, phase irrelevant for one mode
I = sp.I
Dn_c = wn**2 * (1 + I * etan) - w**2
Dr_c = wr**2 * (1 + I * etar) - w**2
K = rho * c**2 * eps / V * A * f
# weak coupling: no back-reaction on the structure
Q0 = F / (M * Dr_c)
P0 = -K * w**2 * Q0 / Dn_c
p2_weak = sp.simplify(P0 * sp.conjugate(P0) / (2 * eps))
c_weak = sp.simplify(p2_weak - Eq8.subs(Psi, F**2 / 2)) == 0
inflow0 = sp.simplify(sp.re(A * f * P0 * sp.conjugate(I * w * Q0)) / 2)
c_win = sp.simplify(inflow0 - Win7.subs(Psi, F**2 / 2)) == 0
# added structural loss from the back-reaction: M Dr Q - A f K w^2 Q / Dn = F
added = -A * f * K * w**2 / (M * Dn_c)                     # added to w_r^2(1+i eta_r) - w^2
eta_add = sp.simplify(sp.im(sp.expand_complex(added)) / wr**2)
eq83 = rho * c**2 * A**2 * eps * f**2 / (wn**2 * M * V) * etan / ((1 - wr**2 / wn**2) ** 2 + etan**2)
c_83 = sp.simplify(eta_add.subs(w, wr) - eq83) == 0
shift = sp.simplify(sp.re(sp.expand_complex(added)))       # reactive part, not in Eq. (8)

results.update({"eq6": c_eq6, "ident": ident and ident_m_free, "eq8": c_eq8, "code": c_code,
                "weak": c_weak, "win": c_win, "eq83": c_83})

# ---------------------------------------------------------------- 2. numerical (19a items 2-5)
# test-article-like magnitudes (CR-3813 App. C/D geometry; Table D-1 mode 8; phase-17 baseline f'(n3, r8))
a, L, th0 = 0.508, 1.803, np.deg2rad(56.6)
rho0, c0 = 1.225, 341.0
Vn = a**2 * L * (np.pi - th0 + np.cos(th0) * np.sin(th0))
An = L * (2 * a * np.sin(th0) + 2 * a * (np.pi - th0))
case = dict(fn=175.889 / a, fr=318.73, M=5.33569, f=0.188455127, eps=2.0, etan=0.05, etar=0.10, F=1.0)


def solve(w_, fn, fr, M_, f_, eps_, etan_, etar_, F_, back=True):
    wn_, wr_ = 2 * np.pi * fn, 2 * np.pi * fr
    Dn_ = wn_**2 * (1 + 1j * etan_) - w_**2
    Dr_ = wr_**2 * (1 + 1j * etar_) - w_**2
    K_ = rho0 * c0**2 * eps_ / Vn * An * f_
    # [M Dr, A f; K w^2, Dn] [Q; P] = [F; 0]
    Mat = np.array([[M_ * Dr_, An * f_ if back else 0.0], [K_ * w_**2, Dn_]], dtype=complex)
    Q_, P_ = np.linalg.solve(Mat, np.array([F_, 0.0], dtype=complex))
    return Q_, P_, wn_, wr_


def eq8_num(w_, wn_, wr_, M_, f_, eps_, etan_, etar_tot, Psi_):
    Dn_ = (wn_**2 - w_**2) ** 2 + (etan_ * wn_**2) ** 2
    Dr_ = (wr_**2 - w_**2) ** 2 + (etar_tot * wr_**2) ** 2
    return (c0 / Vn) ** 2 * (rho0 * c0 * An) ** 2 * w_**4 * eps_ * f_**2 * Psi_ / (M_**2 * Dn_ * Dr_)


def eq83_num(wn_, wr_, M_, f_, eps_, etan_):
    N_ = etan_ * wn_**2
    return rho0 * c0**2 * An**2 * eps_ * f_**2 / (M_ * Vn) * N_ / ((wn_**2 - wr_**2) ** 2 + N_**2)


ws = 2 * np.pi * case["fn"] * np.linspace(0.2, 5.0, 2001)
err_bal, err_weak, err_win = 0.0, 0.0, 0.0
for w_ in ws:
    for back in (True, False):
        Q_, P_, wn_, wr_ = solve(w_, case["fn"], case["fr"], case["M"], case["f"], case["eps"],
                                 case["etan"], case["etar"], case["F"], back=back)
        inflow = 0.5 * np.real(An * case["f"] * P_ * np.conj(1j * w_ * Q_))
        p2n = abs(P_) ** 2 / (2 * case["eps"])
        wdiss = Vn / (rho0 * c0**2) * case["etan"] * wn_**2 / w_ * p2n          # Eq. (5)
        err_bal = max(err_bal, abs(inflow - wdiss) / abs(wdiss))
        if not back:
            e8 = eq8_num(w_, wn_, wr_, case["M"], case["f"], case["eps"], case["etan"], case["etar"], case["F"]**2 / 2)
            err_weak = max(err_weak, abs(p2n - e8) / e8)
            Dn_h = (1 - w_**2 / wn_**2) ** 2 + case["etan"]**2
            Dr_h = (1 - w_**2 / wr_**2) ** 2 + case["etar"]**2
            w7 = (rho0 * c0**2 * An**2 / Vn) * w_**3 * case["eps"] * case["etan"] / wn_**2 \
                * case["f"]**2 * (case["F"]**2 / 2) / (case["M"]**2 * wr_**4) / (Dn_h * Dr_h)
            err_win = max(err_win, abs(inflow - w7) / w7)

# item 4: added loss at w = w_r from the exact solution (numerical) against Eq. (83)
wn_, wr_ = 2 * np.pi * case["fn"], 2 * np.pi * case["fr"]
Q_, P_, _, _ = solve(wr_, case["fn"], case["fr"], case["M"], case["f"], case["eps"], case["etan"], case["etar"], case["F"])
Deff = case["F"] / (case["M"] * Q_)                                # = w_r^2(1 + i eta_r) - w^2 + added
eta_add_num = (np.imag(Deff) - case["etar"] * wr_**2) / wr_**2
e83 = eq83_num(wn_, wr_, case["M"], case["f"], case["eps"], case["etan"])
err_83 = abs(eta_add_num - e83) / e83

# coupling-strength sweep: exact coupled p^2 against Eq. (8) with eta_r'' of Eq. (83), at H1 = 200 Hz and at w = w_r, w = w_n
sweep = []
for scale in (1e-3, 0.1, 0.3, 1.0, 2.0, 3.0):
    fs = case["f"] * scale
    row = [scale]
    for w_ in (2 * np.pi * 200.0, wr_, wn_):
        Q_, P_, _, _ = solve(w_, case["fn"], case["fr"], case["M"], fs, case["eps"], case["etan"], case["etar"], case["F"])
        p2x = abs(P_) ** 2 / (2 * case["eps"])
        eta2 = eq83_num(wn_, wr_, case["M"], fs, case["eps"], case["etan"])
        e8 = eq8_num(w_, wn_, wr_, case["M"], fs, case["eps"], case["etan"], case["etar"] + eta2, case["F"]**2 / 2)
        row.append(10 * np.log10(p2x / e8))
    row.append(eq83_num(wn_, wr_, case["M"], fs, case["eps"], case["etan"]))
    sweep.append(row)

# item 5: two structural modes driven by the same tone, one cabin mode (n2 with r1 and r6 of the phase-17 baseline)
two = dict(fn=None, eps=2.0, etan=0.05)
r1 = dict(fr=188.52, M=1.13889, f=0.06017331467, etar=0.10)
r6 = dict(fr=301.93, M=3.35573, f=0.09564100493, etar=0.10)
fn2 = 300.0       # a cabin mode between the two structural modes (illustrative)
coh = []
for w_hz in (200.0, 250.0, 300.0):
    w_ = 2 * np.pi * w_hz
    wn2 = 2 * np.pi * fn2
    Dn_ = wn2**2 * (1 + 1j * two["etan"]) - w_**2
    pieces = []
    for r in (r1, r6):
        wr2 = 2 * np.pi * r["fr"]
        Dr_ = wr2**2 * (1 + 1j * r["etar"]) - w_**2
        Qr = 1.0 / (r["M"] * Dr_)                         # |F_r| = 1 Pa m^2, weak coupling
        pieces.append(-(rho0 * c0**2 * two["eps"] / Vn) * An * r["f"] * w_**2 * Qr / Dn_)
    inc = sum(abs(x) ** 2 for x in pieces) / (2 * two["eps"])           # Eq. (8): sum over r of |.|^2
    rowc = [w_hz]
    for dphi in (0.0, np.pi / 2, np.pi):
        cohp = abs(pieces[0] + pieces[1] * np.exp(1j * dphi)) ** 2 / (2 * two["eps"])
        rowc.append(10 * np.log10(cohp / inc))
    coh.append(rowc)

TOL = 1e-9
results.update({"bal": err_bal <= TOL, "weak_num": err_weak <= TOL, "win_num": err_win <= TOL, "eq83_num": err_83 <= TOL})

# ---------------------------------------------------------------- report
P = lambda b: "PASS" if b else "FAIL"
say("# Eq. (8) against a two-resonator model (plan 19a, 19b; V-UNIT)")
say()
say("Generated by `scripts/check_two_resonator.py`. Criteria fixed 2026-10-20 in `IMPLEMENTATION_PLAN.md` phase 19, before the first run. "
    "Source: CR-3813 pp. 9–15 (PDF pages 19–25) and p. 43 (Eq. 83), read from the page images.")
say()
say("## 1. Derivation (symbolic, sympy)")
say()
say("| Check | Result |")
say("|---|---|")
say(f"| Eq. (6) prefactor (2π/ρV)(mA/4)²τ_ML(2/π)ω² equals Eq. (4)'s ρc0²A⁴/V after S_pbl j_r² = Ψ_G/A² | {P(c_eq6)} |")
say(f"| 19b: (mA/4)²τ_ML = (ρc0A/(2ω))² with τ_ML = (2ρc0/(ωm))², independent of m | {P(ident and ident_m_free)} |")
say(f"| Eq. (7) from Eq. (6) with C_pbl(x\\|x′)δ(ω − ω_H): band integral → ω_H³/(D̂_n D̂_r) | by construction |")
say(f"| n-th term of Eq. (5) = n-th term of Eq. (7), solved for ⟨p_n²⟩_s,t, equals printed Eq. (8) | {P(c_eq8)} |")
say(f"| Code prefactor (c0/V)²(ρ0c0A)²ω_H⁴ with dimensional D_n, D_r equals Eq. (8) | {P(c_code)} |")
say(f"| Two-resonator model, back-reaction removed: ⟨p_n²⟩_s,t = Eq. (8) with Ψ_G = \\|F\\|²/2 | {P(c_weak)} |")
say(f"| Same: wall inflow ½Re(A f′ P conj(iωQ)) = Eq. (7) | {P(c_win)} |")
say(f"| Back-reaction: added structural loss factor at ω = ω_r equals printed Eq. (83) | {P(c_83)} |")
say()
say(f"Added structural loss at a general ω (exact model): η_add(ω) = `{sp.simplify(eta_add)}`; at ω = ω_r it is Eq. (83). "
    f"The back-reaction also adds a reactive term Re = `{shift}` (a frequency shift of mode r), which Eq. (8) does not carry.")
say()
say("## 2. Numerical checks")
say()
say(f"Case: a = {a} m, L = {L} m, θ0 = 56.6°, V = {Vn:.4f} m³, A = {An:.4f} m², ρ0 = {rho0}, c0 = {c0}; cabin mode f_n = {case['fn']:.2f} Hz "
    f"(Table C-1 mode 3 scaled to a), structural mode f_r = {case['fr']} Hz, M_r = {case['M']} kg (Table D-1 mode 8), f′ = {case['f']:.4f} "
    f"(phase-17 baseline f′(n3, r8)), ε_n = 2, η_n = {case['etan']}, η_r = {case['etar']}. Sweep 0.2–5 ω_n, 2001 points.")
say()
say("| Criterion (19a) | max rel. error | tol | Result |")
say("|---|---:|---:|---|")
say(f"| (2) exact inflow = Eq. (5) W_diss, coupled and uncoupled | {err_bal:.2e} | 1e-9 | {P(err_bal <= TOL)} |")
say(f"| (3) weak coupling: ⟨p_n²⟩_s,t = Eq. (8) | {err_weak:.2e} | 1e-9 | {P(err_weak <= TOL)} |")
say(f"| (3) weak coupling: inflow = Eq. (7) | {err_win:.2e} | 1e-9 | {P(err_win <= TOL)} |")
say(f"| (4) added loss of the exact solution at ω_r = Eq. (83) | {err_83:.2e} | 1e-9 | {P(err_83 <= TOL)} |")
say()
say("(4) recorded, no pass mark: exact coupled ⟨p_n²⟩ minus Eq. (8) with η_r'' of Eq. (83), in dB, with f′ scaled:")
say()
say("| f′ scale | at 200 Hz (H1) | at ω_r | at ω_n | η_r'' (Eq. 83) |")
say("|---:|---:|---:|---:|---:|")
for r in sweep:
    say(f"| {r[0]:g} | {r[1]:+.3f} | {r[2]:+.3f} | {r[3]:+.3f} | {r[4]:.4f} |")
say()
say(f"(5) recorded, no pass mark: two structural modes (Table D-1 modes 1 and 6, f′ of the phase-17 baseline with cabin mode n2) driven by the same tone "
    f"through one cabin mode at {fn2:.0f} Hz (illustrative), weak coupling, equal |F_r|. Coherent sum minus Eq. (8)'s sum over r, in dB, for relative phase Δφ of the two generalized forces:")
say()
say("| f [Hz] | Δφ = 0 | Δφ = π/2 | Δφ = π |")
say("|---:|---:|---:|---:|")
for r in coh:
    say(f"| {r[0]:g} | {r[1]:+.2f} | {r[2]:+.2f} | {r[3]:+.2f} |")
say()
say("## 3. Summary")
say()
allpass = all(results.values())
say(f"All fixed criteria: **{'met' if allpass else 'NOT met'}** ({sum(results.values())} of {len(results)}).")
say()
os.makedirs(os.path.dirname(REPORT), exist_ok=True)
with open(REPORT, "w", encoding="utf-8", newline="\n") as fh:
    fh.write("\n".join(out) + "\n")
print("\n".join(out))
