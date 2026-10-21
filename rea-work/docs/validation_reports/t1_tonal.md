# PAIN validation report

block: T1
class: V-EXP
reference: Fig.E-16 re-digitized (D:\code\PAIN\rea-work\data\t1_interior_targets.csv)
metric: interior SPL H=1 @ 200 Hz band
tolerance: mean ± 4.0 dB or NASA±4.0 in env 65.0-97.0
result: PASS
notes: got=81.04 dB; d_mean=-8.96; d_nasa=2.04; gate=NASA±4.0+env

block: T1
class: V-EXP
reference: Fig.E-16 re-digitized (D:\code\PAIN\rea-work\data\t1_interior_targets.csv)
metric: interior SPL H=2 @ 400 Hz band
tolerance: mean ± 4.0 dB or NASA±4.0 in env 62.0-87.0
result: PASS
notes: got=75.0 dB; d_mean=-5.0; d_nasa=-0.5; gate=NASA±4.0+env

block: T1
class: V-EXP
reference: Fig.E-16 re-digitized (D:\code\PAIN\rea-work\data\t1_interior_targets.csv)
metric: interior SPL H=3 @ 630 Hz band
tolerance: mean ± 4.0 dB or NASA±4.0 in env 50.0-74.0
result: FAIL
notes: got=75.29 dB; d_mean=10.29; d_nasa=7.29; gate=FAIL

