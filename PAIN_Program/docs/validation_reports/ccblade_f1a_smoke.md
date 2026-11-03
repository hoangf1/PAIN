Re-recorded 2026-10-21 after the amplitude-convention fix (I-17; sources cited); result known in advance in direction, therefore post-hoc.

# PAIN validation report

block: SRC_AC
class: X-EXTRAP
reference: CCBlade+F1A vs ANOPP Table 8 ℓ=1 (rms SPL via peak_Pa_to_spl_dB); re-run after plan I-01/I-02 (2026-10-21); raw F1A, pitch_offset_deg=0, anopp_table8_calibrate=false (I-12/B-5)
metric: H=1 free-field SPL rms (raw, untuned; amplitude convention fixed 2026-10-21, post-hoc)
tolerance: informational X-EXTRAP; not a pass criterion (I-12: no calibrate-to-Table-8)
result: REPORTED
notes: F1A_rms=118.5 dB ANOPP_rms=125.7 dB delta=-7.2

block: SRC_AC
class: X-EXTRAP
reference: CCBlade+F1A vs ANOPP Table 8 ℓ=1 (rms SPL via peak_Pa_to_spl_dB); re-run after plan I-01/I-02 (2026-10-21); raw F1A, pitch_offset_deg=0, anopp_table8_calibrate=false (I-12/B-5)
metric: H=2 free-field SPL rms (raw, untuned; amplitude convention fixed 2026-10-21, post-hoc)
tolerance: informational X-EXTRAP; not a pass criterion (I-12: no calibrate-to-Table-8)
result: REPORTED
notes: F1A_rms=110.3 dB ANOPP_rms=118.6 dB delta=-8.3

block: SRC_AC
class: X-EXTRAP
reference: CCBlade+F1A vs ANOPP Table 8 ℓ=1 (rms SPL via peak_Pa_to_spl_dB); re-run after plan I-01/I-02 (2026-10-21); raw F1A, pitch_offset_deg=0, anopp_table8_calibrate=false (I-12/B-5)
metric: H=3 free-field SPL rms (raw, untuned; amplitude convention fixed 2026-10-21, post-hoc)
tolerance: informational X-EXTRAP; not a pass criterion (I-12: no calibrate-to-Table-8)
result: REPORTED
notes: F1A_rms=102.5 dB ANOPP_rms=111.3 dB delta=-8.8

block: SRC_AC
class: X-EXTRAP
reference: CCBlade+F1A smoke; re-run after plan I-01/I-02 (2026-10-21); raw F1A, pitch_offset_deg=0, anopp_table8_calibrate=false (I-12/B-5)
metric: pipeline freefield grid
tolerance: informational X-EXTRAP (I-12)
result: REPORTED
notes: source=ccblade_f1a bpf=200.0 maxA=23.90517259122554 wall_s=13.0 deltas=[-7.2, -8.3, -8.8] dB; CCBlade+F1A all 160 points, no GEXT (X-EXTRAP). Vinf=20.0; c0=340.0; t/c=0.0; pitch_off=0.0°; AA (x3,x1,x2); DC-removed FFT; asound fixed. Tables 7–9.

