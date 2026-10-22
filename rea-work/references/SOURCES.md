# Reference sources added 2026-10-22

Downloaded 2026-10-22 from the NASA Technical Reports Server (public use permitted) for the airfoil-polar display and the high-Mach polar gap (Report 996 sections at tip Mach 0.75–0.90; the XFOIL grid stops at M = 0.72). Independent airfoil data: not the propeller noise or load data the source cases are compared against.

| File | Report | NTRS | SHA-256 |
|------|--------|------|---------|
| `NACA_TN_1546.pdf` | Lindsey, Stevenson, Daley: *Aerodynamic characteristics of 24 NACA 16-series airfoils at Mach numbers between 0.3 and 0.8*, NACA TN 1546, 1948 | https://ntrs.nasa.gov/citations/19930082349 | `7c8439ab42d4ccaa4e744b1bb23dc80a6a539c796dda02b7bc67374493f5ee55` |
| `NACA_TR_824.pdf` | Abbott, von Doenhoff, Stivers: *Summary of airfoil data*, NACA Report 824, 1945 | https://ntrs.nasa.gov/citations/19930090976 | `9f27283b704821192fc9dba4ed625f62002903b5127bc869cd04ac0a5cc54efd` |

**TN 1546 coverage.** Langley 24-inch high-speed tunnel, 5-inch chord, Re about 0.85–2×10⁶, M 0.3 to about 0.8; c_l, c_d, c_m vs M at fixed α (Fig. 3, Table I index); not corrected for wall interference (about 2 % on M at supercritical speeds, p. 6); data near choking omitted. Stated accuracy: c_l ±0.005, c_d ±0.0005, α ±0.1° (p. 5). Report 996 sections with an exact match: 16-312 (Fig. 3j), 16-506 (3n), 16-509 (3o); the others have neighbours in thickness or camber.

**Report 824.** Low-speed section data (Langley two-dimensional tunnel, Re 3–9×10⁶), including NACA 4412 for the Pereira case.

**Tool (not in the repo).** XFOIL 6.99 (Windows build), from https://web.mit.edu/drela/Public/web/xfoil/XFOIL6.99.zip, installed at `C:\Users\francis\tools\XFOIL6.99\xfoil.exe` (SHA-256 `c17342f84ae260c2b11a74cd0e2fb8189a5f8954c6bb7a8467a0f27055c7faea`). `data/polars/xfoil_polars.py` reads it through `XFOIL_EXE`.
