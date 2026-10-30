# Reference sources added 2026-10-22

Downloaded 2026-10-22 from the NASA Technical Reports Server (public use permitted) for the airfoil-polar display and the high-Mach polar gap (Report 996 sections at tip Mach 0.75–0.90; the XFOIL grid stops at M = 0.72). Independent airfoil data: not the propeller noise or load data the source cases are compared against.

| File | Report | NTRS | SHA-256 |
|------|--------|------|---------|
| `NACA_TN_1546.pdf` | Lindsey, Stevenson, Daley: *Aerodynamic characteristics of 24 NACA 16-series airfoils at Mach numbers between 0.3 and 0.8*, NACA TN 1546, 1948 | https://ntrs.nasa.gov/citations/19930082349 | `7c8439ab42d4ccaa4e744b1bb23dc80a6a539c796dda02b7bc67374493f5ee55` |
| `NACA_TR_824.pdf` | Abbott, von Doenhoff, Stivers: *Summary of airfoil data*, NACA Report 824, 1945 | https://ntrs.nasa.gov/citations/19930090976 | `9f27283b704821192fc9dba4ed625f62002903b5127bc869cd04ac0a5cc54efd` |

**TN 1546 coverage.** Langley 24-inch high-speed tunnel, 5-inch chord, Re about 0.85–2×10⁶, M 0.3 to about 0.8; c_l, c_d, c_m vs M at fixed α (Fig. 3, Table I index); not corrected for wall interference (about 2 % on M at supercritical speeds, p. 6); data near choking omitted. Stated accuracy: c_l ±0.005, c_d ±0.0005, α ±0.1° (p. 5). Report 996 sections with an exact match: 16-312 (Fig. 3j), 16-506 (3n), 16-509 (3o); the others have neighbours in thickness or camber.

**Report 824.** Low-speed section data (Langley two-dimensional tunnel, Re 3–9×10⁶), including NACA 4412 for the Pereira case.

**Tool (not in the repo).** XFOIL 6.99 (Windows build), from https://web.mit.edu/drela/Public/web/xfoil/XFOIL6.99.zip, installed at `C:\Users\francis\tools\XFOIL6.99\xfoil.exe` (SHA-256 `c17342f84ae260c2b11a74cd0e2fb8189a5f8954c6bb7a8467a0f27055c7faea`). `data/polars/xfoil_polars.py` reads it through `XFOIL_EXE`.

## Added 2026-10-23 (block validation, phases 41–43)

| File | Report | NTRS |
|------|--------|------|
| `NASA_TP_1964.pdf` | Willis, Daniels: *Experimental study of noise reduction for an unstiffened cylindrical model of an airplane fuselage*, NASA TP-1964, 1981 (0.508 m bare cylinder; reverberant and propeller noise reduction; reverberation times) | https://ntrs.nasa.gov/citations/19820007006 |
| `NASA_TP_2444.pdf` | Willis, Mayes, Daniels: *Effects of propeller rotation direction on airplane interior noise levels*, NASA TP-2444, 1985 | https://ntrs.nasa.gov/citations/19850022454 |
| `NASA_CR_159363.pdf` | Pope, Rennison, Wilby: *Analytical prediction of the interior noise for cylindrical models of aircraft fuselages for prescribed exterior noise fields, Phase I*, NASA CR-159363, 1980 (CR-3813 Ref. [3]: f_qM for L ≠ L_c, Eq. 25; downloaded 2026-10-23) | https://ntrs.nasa.gov/citations/19810010273 |
| `NASA_CR_172384.pdf` | Wilby, Wilby: *Application of stiffened cylinder analysis to ATP interior noise studies*, NASA CR-172384, 1984 | https://ntrs.nasa.gov/citations/19840025076 |
- `NASA_TP_1964.pdf`: SHA-256 `3aa1e8ec731d0453bb8b7256f0bcd7713b50c198c062b9b4a2a8d97f74a5473e`
- `NASA_TP_2444.pdf`: SHA-256 `f4ad05c839de9a6ff9b80cc9c886e27534f37ef1b21952d286ab6c3d5caef202`
- `NASA_CR_159363.pdf`: SHA-256 `10b21b9ce3ad2ab29182abc7e6f40f34d237bd2b95ec8e31898fc714141f884e`
- `NASA_CR_172384.pdf`: SHA-256 `05681043fe82e2d7e63ebf040c710f71cc05929c415627c9d74df016d8af8764`

## Added 2026-10-23 (Phase 48)

| File | Report | NTRS |
|------|--------|------|
| `NASA_RP_1218.pdf` | Brooks, Pope, Marcolini: *Airfoil self-noise and prediction*, NASA RP-1218, 1989 (BPM model; App. D code listing and Tables D2/D3) | https://ntrs.nasa.gov/citations/19890016302 |
- `NASA_RP_1218.pdf`: SHA-256 `0c22690c6216c4355c0da7e09ce0d1a1dd96a2b88d3d8abda30e293b3db76006`

## Added 2026-10-23 (Phase 59)

| File | Report | NTRS |
|------|--------|------|
| `NASA_CR_172490.pdf` | May, Plotkin, Selden, Sharp: *Lightweight sidewalls for aircraft interior noise control*, NASA CR-172490, 1985 (Sharp double-panel model with sound bridges, §2.3; Panel D prediction Fig. 15) | https://ntrs.nasa.gov/citations/19870002890 |
- `NASA_CR_172490.pdf`: SHA-256 `1c1ea678a0cbd959d4b3864e5f357db53a59653f845e49ce3add5d48d0749d22`

## Added 2026-10-30

| File | Report | NTRS |
|------|--------|------|
| `NASA_CR_178004.pdf` | Wilby, McDaniel, Wilby: *In-flight acoustic measurements on a light twin-engined turboprop airplane*, NASA CR-178004, November 1985 (Gulfstream Commander 695A; exterior and interior levels per propeller harmonic, untreated and fibreglass-treated cabin; 238 pages) | https://ntrs.nasa.gov/citations/19860010618 |
- `NASA_CR_178004.pdf`: SHA-256 `3c7b58b3ff0d7c74adc30a384a0b2cbee3b7e9da8549f8c231dbab1630732a6a`
