Re-recorded 2026-10-22 at L = 1.83 m (I-22, post-hoc; earlier 1.803 m values: see length_sensitivity.md)

# PAIN validation report

block: T1
class: V-EXP
reference: Fig.E-16 re-digitized (D:\code\PAIN\rea-work\data\cr3813\t1_interior_targets.csv)
metric: interior SPL H=1 @ 200 Hz band
tolerance: mean ± 4.0 dB or NASA±4.0 in env 65.0-97.0
result: FAIL
notes: got=84.21 dB; d_mean=-5.79; d_nasa=5.21; gate=FAIL

block: T1
class: V-EXP
reference: Fig.E-16 re-digitized (D:\code\PAIN\rea-work\data\cr3813\t1_interior_targets.csv)
metric: interior SPL H=2 @ 400 Hz band
tolerance: mean ± 4.0 dB or NASA±4.0 in env 62.0-87.0
result: PASS
notes: got=77.66 dB; d_mean=-2.34; d_nasa=2.16; gate=mean±4.0

block: T1
class: V-EXP
reference: Fig.E-16 re-digitized (D:\code\PAIN\rea-work\data\cr3813\t1_interior_targets.csv)
metric: interior SPL H=3 @ 630 Hz band
tolerance: mean ± 4.0 dB or NASA±4.0 in env 50.0-74.0
result: FAIL
notes: got=78.06 dB; d_mean=13.06; d_nasa=10.06; gate=FAIL

