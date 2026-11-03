"""Each equation checked against something independent of its own code path: a published
number, an independent derivation, or a physical identity. VERIFICATION.md lists the source
behind every check."""
import numpy as np
import pytest
from scipy.special import hankel1, jv

from cabin_noise.core import seats as st
from cabin_noise.core import tmm
from cabin_noise.core.atmosphere import air, isa
from cabin_noise.core.blade import BladeGeometry, strip_loads
from cabin_noise.core.materials import AirGap, Panel
from cabin_noise.core.scattering import surface_factor
from cabin_noise.core.source_tbl import boundary_layer, goody_phi
from cabin_noise.core.source_tonal import rotor_harmonics
from cabin_noise.core.weighting import a_weight, c_weight

SL = air(293.15, 101325.0)


# ---- atmosphere: ISA tables (US Standard Atmosphere 1976) ----------------------------------
@pytest.mark.parametrize("h,T,p,rho", [(0, 288.15, 101325.0, 1.2250), (5000, 255.65, 54019.9, 0.73612),
                                       (11000, 216.65, 22632.1, 0.36392), (15000, 216.65, 12044.6, 0.19367)])
def test_isa_against_tables(h, T, p, rho):
    a = isa(h)
    assert a.T == pytest.approx(T, abs=0.01)
    assert a.p == pytest.approx(p, rel=1e-3)
    assert a.rho == pytest.approx(rho, rel=1e-3)


def test_sutherland_viscosity_table_value():
    # US Standard Atmosphere 1976: mu = 1.7894e-5 Pa s at 288.15 K
    assert isa(0).mu == pytest.approx(1.7894e-5, rel=1e-3)


# ---- weighting: IEC 61672-1 Table 3 (nominal frequencies, 0.1 dB) ---------------------------
@pytest.mark.parametrize("f,A,C", [(31.5, -39.4, -3.0), (63, -26.2, -0.8), (125, -16.1, -0.2), (250, -8.6, 0.0),
                                   (500, -3.2, 0.0), (1000, 0.0, 0.0), (2000, 1.2, -0.2), (4000, 1.0, -0.8),
                                   (8000, -1.1, -3.0)])
def test_weighting_against_iec_table(f, A, C):
    fx = 1000.0 * 10 ** (np.round(10 * np.log10(f / 1000.0)) / 10)   # IEC tabulates at exact base-10 frequencies
    assert a_weight(fx) == pytest.approx(A, abs=0.1)
    assert c_weight(fx) == pytest.approx(C, abs=0.1)


# ---- room acoustics ---------------------------------------------------------------------------
def test_sabine_constant_from_first_principles():
    # T60 = 24 ln(10) V / (c A) (Sabine; Kuttruff, Room Acoustics); 0.161 is its value at c = 343 m/s
    assert 24 * np.log(10) / 343.0 == pytest.approx(0.161, abs=5e-4)


def test_waterhouse_wall_factor_and_diffuse_intensity():
    """Random plane waves from all directions (a diffuse field) at a rigid wall z = 0: the wall mean
    square is twice the field mean square away from the wall (Waterhouse 1955; CR-3813 p. 23), and
    the intensity onto the wall is <p^2> / (4 rho c) (Kuttruff, Room Acoustics)."""
    rng = np.random.default_rng(1)
    N, k = 4000, 2 * np.pi
    u = rng.uniform(0, 1, N)                         # cos(theta) uniform = uniform on the half sphere
    ph = rng.uniform(0, 2 * np.pi, N)
    az = rng.uniform(0, 2 * np.pi, N)
    s_, c_ = np.sqrt(1 - u ** 2), u
    kx, ky, kz = k * s_ * np.cos(az), k * s_ * np.sin(az), -k * c_
    amp = np.ones(N) / np.sqrt(N)

    def p(x, y, z):          # incident wave plus its rigid-wall mirror image
        inc = amp * np.exp(1j * (kx * x + ky * y + kz * z + ph))
        ref = amp * np.exp(1j * (kx * x + ky * y - kz * z + ph))
        return inc.sum() + ref.sum()

    pts = rng.uniform(0, 50, (400, 2))
    zs = rng.uniform(20, 40, 400)
    wall = np.mean([abs(p(x, y, 0.0)) ** 2 for x, y in pts]) / 2           # mean square of a phasor
    far = np.mean([abs(p(x, y, z)) ** 2 for (x, y), z in zip(pts, zs)]) / 2
    assert wall / far == pytest.approx(2.0, rel=0.1)
    I_wall = np.sum(amp ** 2 / 2 * c_) / SL.rho_c                          # incident power per unit area
    assert I_wall == pytest.approx(far / (4 * SL.rho_c), rel=0.1)


def test_exponential_seat_statistic():
    # reverberant p^2 is exponentially distributed (Schroeder 1962): P95 / mean = ln 20
    rng = np.random.default_rng(2)
    p2 = np.abs(rng.normal(size=200000) + 1j * rng.normal(size=200000)) ** 2
    assert 10 * np.log10(np.quantile(p2, 0.95) / p2.mean()) == pytest.approx(st.STAT_95, abs=0.05)


# ---- transmission: closed forms and identities -----------------------------------------------
def test_tmm_reciprocity():
    stack = [Panel(h=1.6e-3, eta=0.02), AirGap(d=0.03), Panel(h=1.0e-3, E=20e9, rho=1800, eta=0.05)]
    f = np.geomspace(50, 5000, 30)
    for th in (0.0, 0.6, 1.2):
        assert np.allclose(tmm.tau(stack, f, th, SL), tmm.tau(stack[::-1], f, th, SL), rtol=1e-9)


def test_tmm_double_wall_matches_closed_form():
    """Two limp masses and an air gap at normal incidence, solved by hand (wave in the gap):
    t = 1 / [(1 + j a1)(1 + j a2) e^{jkd} + a1 a2 e^{-jkd}],  a_i = w m_i / (2 rho c)
    (London 1950; Fahy & Gardonio, Sound and Structural Vibration, double-wall section)."""
    m1, m2, d = 4.0, 2.0, 0.05
    f = np.geomspace(30, 3000, 40)
    w = 2 * np.pi * f
    k, z = w / SL.c, SL.rho_c
    a1, a2 = w * m1 / (2 * z), w * m2 / (2 * z)
    t = 1.0 / ((1 + 1j * a1) * (1 + 1j * a2) * np.exp(1j * k * d) + a1 * a2 * np.exp(-1j * k * d))
    lay = [Panel(h=m1 / 1000.0, rho=1000.0, E=1.0, eta=0.0), AirGap(d=d),
           Panel(h=m2 / 1000.0, rho=1000.0, E=1.0, eta=0.0)]
    assert np.allclose(tmm.tau(lay, f, 0.0, SL), np.abs(t) ** 2, rtol=1e-6)


def test_coincidence_at_oblique_incidence():
    """At sin^2(theta) = f_c / f the bending and mass reactances cancel and Z = w m eta (Cremer, Heckl
    & Petersson, Structure-Borne Sound): tau = 1 / (1 + w m eta cos(theta) / (2 rho c))^2."""
    p = Panel(h=1.6e-3, eta=0.01)
    fc = p.coincidence(SL.c)
    f = 2 * fc
    th = np.arcsin(np.sqrt(fc / f))
    w = 2 * np.pi * f
    expect = 1 / (1 + w * p.mass * p.eta * np.cos(th) / (2 * SL.rho_c)) ** 2
    assert tmm.tau([p], np.array([f]), th, SL)[0] == pytest.approx(expect, rel=1e-9)


def test_navier_plate_against_timoshenko():
    """Timoshenko & Woinowsky-Krieger, Theory of Plates, Table 8: square simply supported plate under
    uniform load, w_max = 0.00406 q a^4 / D. Same Navier series as Panel.bay_stiffness, centre weights."""
    n = np.arange(1, 60, 2)
    m, nn = n[:, None], n[None, :]
    w = (16 / (np.pi ** 6 * m * nn * (m ** 2 + nn ** 2) ** 2) * np.sin(m * np.pi / 2) * np.sin(nn * np.pi / 2)).sum()
    assert w == pytest.approx(0.00406, abs=0.00001)
    p = Panel(h=1e-3, bay_a=1.0, bay_b=1.0)
    s11 = np.pi ** 4 / 64 * p.rho * p.h * (2 * np.pi * p.bay_frequency()) ** 2     # (1,1) term alone
    assert p.bay_stiffness() < s11 and p.bay_stiffness() == pytest.approx(s11, rel=0.02)


# ---- sources -------------------------------------------------------------------------------
def test_cylinder_scattering_series_satisfies_rigid_boundary():
    """Total field p = sum eps_n j^n [J_n(kr) - J_n'(ka)/H_n'(ka) H_n(kr)] cos(n phi) (Morse & Ingard,
    Theoretical Acoustics sec. 8.1): zero radial derivative at r = a, and its value there equals S."""
    for ka in (0.5, 2.0, 8.0):
        n = np.arange(int(np.ceil(ka)) + 21)   # same truncation as surface_factor
        eps = np.where(n == 0, 1, 2)
        dJ = 0.5 * (jv(n - 1, ka) - jv(n + 1, ka))
        dH = 0.5 * (hankel1(n - 1, ka) - hankel1(n + 1, ka))
        coef = eps * 1j ** n
        for phi_lit in (0.0, 1.0, np.pi):
            cosn = np.cos(n * (np.pi - phi_lit))
            p_a = np.sum(coef * (jv(n, ka) - dJ / dH * hankel1(n, ka)) * cosn)
            dp = np.sum(coef * (dJ - dJ / dH * dH) * cosn)
            assert abs(dp) < 1e-10
            assert p_a == pytest.approx(complex(surface_factor(ka, phi_lit)[0]), rel=1e-9, abs=1e-12)


def test_moving_force_against_direct_time_domain_solution():
    """Independent evaluation of p = -d/dx_i [F_i / (4 pi r |1 - M_r|)]_ret (Lowson 1965, Proc. R. Soc.
    A 286): emission time by Newton iteration at uniform reception times, space derivative at fixed t,
    FFT over one blade period. Uses neither the closed-form delay nor the Jacobian of rotor_harmonics."""
    B, R, om, V, c, T, Q = 2, 0.9, 200.0, 90.0, 330.0, 3000.0, 800.0
    obs = np.array([0.2, -1.4, 0.3])
    P = rotor_harmonics(obs, blades=B, R_e=R, omega=om, V=V, c=c, thrust=T, torque=Q, n_harmonics=3, n_tau=4096)
    Tb = 2 * np.pi / om / B
    nt = 512
    t = np.arange(nt) * Tb / nt
    Tb1, Db = T / B, Q / (B * R)

    def potential(x):
        out = np.zeros((nt, 3))
        X = x[None, :] + np.stack([V * t, 0 * t, 0 * t], 1)       # observer moves with the aircraft
        for k in range(B):
            tau = t - np.linalg.norm(x) / c
            for _ in range(60):
                ps = om * tau + 2 * np.pi * k / B
                y = np.stack([V * tau, R * np.cos(ps), R * np.sin(ps)], 1)
                Rv = X - y
                r = np.linalg.norm(Rv, axis=1)
                dy = np.stack([np.full_like(tau, V), -R * om * np.sin(ps), R * om * np.cos(ps)], 1)
                g = t - tau - r / c
                dg = -1 + np.einsum("ij,ij->i", Rv, dy) / (r * c)
                tau = tau - g / dg
            Mr = np.einsum("ij,ij->i", dy, Rv) / (c * r)
            F = np.stack([np.full_like(tau, -Tb1), -Db * np.sin(ps), Db * np.cos(ps)], 1)
            out += F / (4 * np.pi * r * np.abs(1 - Mr))[:, None]
        return out

    d = 1e-3
    p = np.zeros(nt)
    for i in range(3):
        e = np.zeros(3)
        e[i] = d
        p -= (potential(obs + e)[:, i] - potential(obs - e)[:, i]) / (2 * d)
    rms = np.sqrt(2) * np.abs((np.fft.fft(p) / nt)[1:4])
    assert np.allclose(20 * np.log10(np.abs(P) / rms), 0.0, atol=0.05)


def test_goody_asymptotic_slopes():
    # Goody (2004, AIAA J. 42): Phi ~ w^2 at low frequency, ~ w^-0.7 in the overlap, ~ w^-5 at high frequency
    bl = boundary_layer(isa(6000), 140.0, 4.0)

    def slope(w1):
        return np.log(goody_phi(2 * w1, bl) / goody_phi(w1, bl)) / np.log(2)

    U, d = bl.Ue, bl.delta
    assert slope(1e-4 * U / d) == pytest.approx(2.0, abs=0.02)
    assert slope(1e3 * U / d * bl.R_T ** 0.57) == pytest.approx(-5.0, abs=0.05)
    assert -1.0 < slope(30 * U / d) < -0.5


def test_flat_plate_boundary_layer_formulas():
    # 1/7-power-law turbulent flat plate (Schlichting, Boundary-Layer Theory, ch. 21)
    a = isa(0)
    bl = boundary_layer(a, 50.0, 2.0)
    Re = 50.0 * 2.0 / a.nu
    assert bl.delta == pytest.approx(0.37 * 2.0 / Re ** 0.2) and bl.Cf == pytest.approx(0.0592 / Re ** 0.2)


def test_bemt_reduces_to_momentum_theory():
    """Many blades, no drag and an ideally twisted blade give uniform inflow; the blade-element
    momentum result must then equal actuator-disk momentum theory, P = T^1.5 / sqrt(2 rho A)
    (Leishman, Principles of Helicopter Aerodynamics, ch. 2), with A the annulus outside the hub."""
    R = 1.0
    x = np.linspace(0.2, 1.0, 9)
    g = BladeGeometry(r_over_R=list(x), c_over_R=[0.004] * 9, beta_deg=list(np.degrees(0.05 / x)),
                      cl_design=[0.0] * 9, hub_r_over_R=0.2, clmax=5.0, cd0=0.0, n_strips=40)
    r, dT, dQ = strip_loads(g, blades=40, R=R, omega=100.0, V=0.0, rho=1.225, c=1e6)
    T, P = dT.sum(), dQ.sum() * 100.0
    A = np.pi * R ** 2 * (1 - 0.2 ** 2)
    assert P == pytest.approx(T ** 1.5 / np.sqrt(2 * 1.225 * A), rel=0.03)


def test_delany_bazley_is_passive_and_causal_in_range():
    """A passive porous layer (e^{+jwt}) has Re Zc > 0, Im Zc < 0 and Im kc < 0 (decay), with
    Re kc > w/c (slower than air) over the fit range 0.01 <= X <= 1 (Allard & Atalla, Propagation of
    Sound in Porous Media, sec. 2.5)."""
    from cabin_noise.core.porous import delany_bazley
    f = np.geomspace(100, 5000, 30)
    Zc, kc, X = delany_bazley(f, 10000.0, SL.rho, SL.c)
    ok = (X >= 0.01) & (X <= 1.0)
    assert ok.sum() > 10
    assert np.all(Zc.real[ok] > 0) and np.all(Zc.imag[ok] < 0) and np.all(kc.imag[ok] < 0)
    assert np.all(kc.real[ok] > 2 * np.pi * f[ok] / SL.c)


def test_loss_factor_reverberation_identity():
    # energy decays as exp(-eta w t), w = 2 pi f: 60 dB in T60 gives eta = 6 ln(10) / (2 pi f T60) = 2.2 / (f T60)
    assert 6 * np.log(10) / (2 * np.pi) == pytest.approx(2.2, abs=0.01)


def test_prandtl_tip_loss_limits():
    """Prandtl's factor F = (2/pi) acos(exp(-B (R - r) / (2 r sin phi))) is 0 at the tip and tends to 1
    inboard (Glauert; Leishman ch. 3): the loading per unit span falls monotonically over the outer
    blade, and the tip strip carries well below the peak."""
    x = np.linspace(0.25, 1.0, 4)
    g = BladeGeometry(r_over_R=list(x), c_over_R=[0.1] * 4, beta_deg=[20, 12, 9, 7], cl_design=[0.3] * 4,
                      hub_r_over_R=0.25, n_strips=200)
    r, dT, _ = strip_loads(g, blades=3, R=1.0, omega=150.0, V=0.0, rho=1.225, c=340.0)
    dr = r[1] - r[0]
    loading = dT / dr
    assert np.all(np.diff(loading[-10:]) < 0) and loading[-1] < 0.5 * loading.max()
