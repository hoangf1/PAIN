"""Tonal source: rotating point forces in forward flight (plan A.2).

Each blade is a point force on the fluid at radius R_e. The exact moving-dipole pressure
    p(x, t) = -d/dx_i [ F_i / (4 pi r |1 - M_r|) ]_ret
is evaluated in the frequency domain at observers fixed to the aircraft. For an observer
x moving with the aircraft and a source y(tau) = y_rel(tau) + V tau e_x, the reception
delay s = t - tau solves |x - y_rel + V s e_x| = c s in closed form. The Fourier
coefficient of the potential at harmonic n (time convention p = sum p_n e^{-j w_n t})
    phi_n(x) = (1/T) int phi(tau) e^{j w_n t(tau)} (dt/dtau) dtau
needs no re-gridding; d/dx_i is a central difference with the observer shifted by +-delta.

Force signs (force ON the fluid): axial -T/B (fluid pushed aft, flight along +x),
tangential +Q/(B R_e) along the blade motion. These reproduce Gutin's
|T cos(theta) - Q c/(Omega R_e^2)| (unit test V0a).
"""
from __future__ import annotations

import numpy as np
from scipy.special import jv


def rotor_harmonics(obs, *, blades: int, R_e: float, omega: float, V: float, c: float,
                    thrust: float, torque: float, n_harmonics: int, rotation: int = 1,
                    n_tau: int = 2048) -> np.ndarray:
    """Complex rms phasors P_m (m = 1..N) of the blade-passage harmonics at `obs`.

    obs: observer position relative to the hub (m), aircraft axes, x = flight direction,
    disk in the y-z plane. |P_m| is the rms free-field incident pressure, Pa.
    """
    obs = np.asarray(obs, dtype=float)
    hel = np.hypot(V, omega * R_e) / c
    if hel >= 1.0:
        raise ValueError(f"helical Mach at R_e is {hel:.3f}; the point-force model needs < 1")
    if V >= c:
        raise ValueError("flight Mach must be < 1")
    B = int(blades)
    T_rev = 2.0 * np.pi / omega
    n = np.arange(1, n_harmonics + 1) * B          # single-blade harmonic orders needed
    w_n = n * omega
    lam_min = 2.0 * np.pi * c / w_n.max()
    delta = lam_min / 100.0

    tau = np.arange(n_tau) * (T_rev / n_tau)
    psi = rotation * omega * tau
    cps, sps = np.cos(psi), np.sin(psi)
    y_rel = np.stack([np.zeros_like(psi), R_e * cps, R_e * sps], axis=1)
    u_rot = rotation * omega * R_e * np.stack([np.zeros_like(psi), -sps, cps], axis=1)
    v_src = u_rot + np.array([V, 0.0, 0.0])
    Tb, Db = thrust / B, torque / (B * R_e)
    F = np.stack([np.full_like(psi, -Tb), np.zeros_like(psi), np.zeros_like(psi)], axis=1)
    F = F + Db * u_rot / (omega * R_e)              # unit vector along the blade motion

    def phi_hat(x):
        R0 = x[None, :] - y_rel
        a = c * c - V * V
        b = V * R0[:, 0]
        R0sq = np.einsum("ij,ij->i", R0, R0)
        s = (b + np.sqrt(b * b + a * R0sq)) / a
        rvec = R0.copy()
        rvec[:, 0] += V * s
        r = c * s
        Mr = np.einsum("ij,ij->i", v_src, rvec) / (c * r)
        dR0 = -u_rot                                   # d(R0)/dtau
        ds = np.einsum("ij,ij->i", R0, dR0) / (a * s - b)
        t = tau + s
        dt = 1.0 + ds
        kern = np.exp(1j * np.outer(w_n, t)) * (dt / (4.0 * np.pi * r * np.abs(1.0 - Mr)))[None, :]
        return kern @ F / n_tau                         # (harmonics, 3)

    p_hat = np.zeros(n_harmonics, dtype=complex)
    for i in range(3):
        e = np.zeros(3)
        e[i] = delta
        p_hat -= (phi_hat(obs + e)[:, i] - phi_hat(obs - e)[:, i]) / (2.0 * delta)
    # B blades add coherently at multiples of B; rms of a real signal is sqrt(2)|p_n|.
    return np.sqrt(2.0) * B * p_hat


def gutin_rms(m, *, blades: int, R_e: float, omega: float, c: float, thrust: float,
              torque: float, r: float, theta: float) -> np.ndarray:
    """Gutin static far-field rms harmonic pressure; theta from the forward axis."""
    m = np.asarray(m, dtype=float)
    B = blades
    k = m * B * omega / c
    return (m * B * omega / (2.0 * np.sqrt(2.0) * np.pi * c * r)
            * np.abs(thrust * np.cos(theta) - torque * c / (omega * R_e ** 2))
            * np.abs(jv(m * B, k * R_e * np.sin(theta))))
