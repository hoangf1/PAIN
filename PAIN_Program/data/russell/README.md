# Russell & Sekula (2017) SUI Endurance (T-Motor 15x5) blade geometry

Source: AHS Paper 73-2017-0096, "Comprehensive Analysis Modeling of Small-Scale UAS Rotors" (`Foil Geom for Wu (Russell).pdf` in `rea-work\references`), used for the Wu et al. (2022) propeller.

| File | Content |
|------|---------|
| `russell_table1.csv` | Table 1, 22 stations (typed from the PDF text): r (in), r/R, θ (deg), chord (in), t/c (%), Re at 3,500 rpm |
| `sections/section_NN_rR*.csv` | Fig. 4 airfoil outlines, x/c and y/c, from the PDF's vector paths (exact, not traced from pixels), ordered upper surface trailing edge → leading edge → lower surface trailing edge, chord normalized to 1 by the x-span |
| `russell_fig4_sections_all.csv` | The same, all 22 sections in one file |
| `russell_fig4_check.csv` | Outline-derived thickness vs Table 1 |

Check: the outline-derived maximum vertical thickness is 0.2–1.2 percentage points of chord larger than Table 1's t/c (for example 8.27% vs 7.04% at r/R 0.62, the largest gap; 20.99% vs 20.80% at the root). The two likely use different thickness definitions (for cambered sections the vertical gap exceeds the thickness normal to the camber line) but I have not confirmed that, so decide which to trust before building the blade. The sections have blunt trailing edges. The panel r/R labels in Fig. 4 (0.1237 to 0.9899) differ slightly from Table 1's rounded values and are used here. Table 1's θ is taken as the pitch angle from the rotation plane (my reading; not stated explicitly in what I read).
