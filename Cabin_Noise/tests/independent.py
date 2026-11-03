"""Independent re-implementations used by the verification tests. Nothing here imports the
tool's physics: only NumPy/SciPy and the published formulas cited in VERIFICATION.md."""
import numpy as np
from scipy.special import hankel1


def isa(h):
    """US Standard Atmosphere 1976, troposphere: T, p, rho, c."""
    T = 288.15 - 0.0065 * h
    p = 101325.0 * (T / 288.15) ** 5.2559
    return T, p, p / (287.05 * T), np.sqrt(1.4 * 287.05 * T)


def moving_force_harmonics(obs, B, R, om, V, c, T, Q, n_harm, rot=1, nt=512):
    """Rms harmonics of B rotating point forces (Lowson 1965: p = -d/dx_i [F_i / 4 pi r |1 - M_r|]_ret),
    solved directly in time: emission time by Newton iteration at uniform reception times, space
    derivative by finite differences at fixed t, FFT over one blade period. Observer moves with the
    aircraft (flight along +x); force on the fluid -T/B axial and Q/(B R) along the blade motion."""
    obs = np.asarray(obs, dtype=float)
    Tb = 2 * np.pi / om / B
    t = np.arange(nt) * Tb / nt
    Tb1, Db = T / B, Q / (B * R)

    def potential(x):
        out = np.zeros((nt, 3))
        X = x[None, :] + np.stack([V * t, 0 * t, 0 * t], 1)
        for k in range(B):
            tau = t - np.linalg.norm(x) / c
            for _ in range(60):
                ps = rot * om * tau + 2 * np.pi * k / B
                y = np.stack([V * tau, R * np.cos(ps), R * np.sin(ps)], 1)
                Rv = X - y
                r = np.linalg.norm(Rv, axis=1)
                u = rot * om * R * np.stack([0 * tau, -np.sin(ps), np.cos(ps)], 1)
                dy = u + np.array([V, 0.0, 0.0])
                g = t - tau - r / c
                dg = -1 + np.einsum("ij,ij->i", Rv, dy) / (r * c)
                tau = tau - g / dg
            Mr = np.einsum("ij,ij->i", dy, Rv) / (c * r)
            F = np.stack([np.full_like(tau, -Tb1), 0 * tau, 0 * tau], 1) + Db * u / (om * R)
            out += F / (4 * np.pi * r * np.abs(1 - Mr))[:, None]
        return out

    d = 1e-3
    p = np.zeros(nt)
    for i in range(3):
        e = np.zeros(3)
        e[i] = d
        p -= (potential(obs + e)[:, i] - potential(obs - e)[:, i]) / (2 * d)
    return np.sqrt(2) * np.abs((np.fft.fft(p) / nt)[1:n_harm + 1])


def cylinder_surface_factor(ka, phi_from_lit):
    """Total surface pressure / incident on a rigid cylinder (Morse & Ingard sec. 8.1), e^{-jwt}."""
    n = np.arange(int(np.ceil(ka)) + 30)
    eps = np.where(n == 0, 1, 2)
    dH = 0.5 * (hankel1(n - 1, ka) - hankel1(n + 1, ka))
    return 2j / (np.pi * ka) * np.sum(eps * 1j ** n * np.cos(n * (np.pi - phi_from_lit)) / dH)
