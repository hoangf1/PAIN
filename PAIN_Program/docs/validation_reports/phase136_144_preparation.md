# Phases 136 to 144: the steps that need no code change and no author value (2026-11-10)

Documents and arithmetic only. No `src/` file, criterion, reference file or recorded result changed.

## 136d The (0,1) × mode 8 pair (statement, no criterion)
From `phase92_appb_pairs.md` (existing output, not re-run): at 4000 rpm H1 the largest term of this code's Eq. (8) sum is the cabin mode (Q = 0, I = 1) with structural mode 8, 5.55 Pa²; NASA's whole tone is 0.59 Pa² (91.69 dB). The share of the q = 0 terms in this code's tone is 92.4 % with q = 0 coupled. With q = 0 uncoupled the tone is 91.26 dB (post-hoc run of Phase 92b), i.e. about 0.53 Pa²; so the q = 0 terms carry about 90 % of the coupled tone's pressure squared. The exact share of the single pair needs the term list of a fresh run, which this step does not make.

## 140a′ The printed grid rule against `_build_grid` (arithmetic, 2026-11-10)
My reading of CR-165869 pp. 60–61: NK = int(7(1 + cos θ₀)), h = (1 + cos θ₀)/NK, boundary point = the nearer of the last inside and first outside point on each grid line. Counting the half-cabin nodes (m ≥ 0) with that reading against the code's rule (NY = 10, point kept if r ≤ 1 + 0.4h):

| θ₀ | NK | nodes, code | nodes, printed rule |
|---|---|---|---|
| 50° | 11 | 67 | 72 |
| 56.6° | 10 | 68 | 65 |
| 62.6° | 10 | 74 | 67 |
| 73.7° | 8 | 81 | 50 |

At 56.6° (the validated angle) the grids have the same h; the code keeps three nodes the printed rule does not: (m, n) = (1, 10), (2, 10), (4, 9), all just outside the wall. So the change could move CYL2D_C1 and APPB_EPS_N; it is not free. The reading of "nearer point" for a line that meets the wall at the crown and floor is mine and has not been checked against the page again; the User Manual §5.1 check of 140a′ is not done. Both are needed before 140a″ ([CONFIRM], `src/`).

## 141b Unscaled results already seen
- `data/report996/f1a_results.csv`: four `ccblade_unscaled` rows, all Fig. 6 (tip-clearance ratios, no measured level), none for Figs. 12, 13a or 14.
- `docs/validation_reports/report996_setup.md` lines 15–23: Fig. 13a H1 at x/D = ±0.125 with unscaled CCBlade loads (113 and 129 Pa against the measured 1009 and 1328 dyne/cm², "far above"). This is a seen unscaled Fig. 13a result.
- `data/pereira/pereira_results.csv`: unscaled loads appear only as thrust and torque rows (`ccblade`), no sound rows.

So an unscaled Fig. 13a was seen; unscaled Fig. 12, Fig. 14 and Pereira sound levels were not. If the author keeps the "add" form, the Fig. 13a replay is post-hoc and carries no verdict (the plan's rule); the other four would be first runs. This adds a reason to the author's open choice in 141c.

## 144e
The note on CR-159668 is in METHODOLOGY §3 (the figure of Eq. (43) against the fit is not drawn).

## Not started, and why
| Step | Waits for |
|---|---|
| 136a–c, f; 137a, c; 141a, c; 143; 144a–d | `src/` change [CONFIRM], or an author criterion |
| 136e, 139c, 141e, 141f | author criterion |
| 137a′, 137b, 138a, 139b′, 142b | reading a PDF page by page (done by hand, long); 142b also a blind transcription |
| 139a, 139b | a new script and runs; 139b first needs 139b′ |
