"""
Blocking factor F(γ) — NASA-CR-3813 Eq. (43), Magliozzi empirical curve.

Flowchart / CR-3813:
  F(γ) = 10^[0.3 − 0.000224 · e^(0.08 γ)]   (γ in degrees)

Blocked amplitude: A_bl = F · A_ff. Free-field phase is unchanged.

Variants (`BlockingVariant`):
- **R1** — full Eq. (43); max ≈ 6 dB (original programmed PAIN).
- **R2** — CR-172428 §5.3.2: multiply Eq. (43) amplitude ratio by 0.8
  (max increase ≈ 4 dB). Floor at 1 so grazing angles do not go below free-field:
  F_R2 = max(1, 0.8 · F_R1).

Validation gate: R1 ΔL = 20 log₁₀ F within **0.06 dB** of CR-172428 p.68
narrative values (see `BLOCKING_P68_CHECKPOINTS`).
"""

@enum BlockingVariant R1 R2

"""Amplitude ratio F(γ). γ in degrees."""
function blocking_factor(γ_deg::Real; variant::BlockingVariant=R1)
    γ = float(γ_deg)
    F = 10.0^(0.3 - 0.000224 * exp(0.08 * γ))
    variant === R1 && return F
    return max(1.0, 0.8 * F)
end

"""SPL increase ΔL = 20 log₁₀ F [dB]."""
delta_L_blocking_dB(γ_deg::Real; variant::BlockingVariant=R1) =
    20.0 * log10(blocking_factor(γ_deg; variant))

"""Apply blocking to free-field amplitude; phase unchanged."""
blocked_amplitude(A_ff::Real, γ_deg::Real; variant::BlockingVariant=R1) =
    blocking_factor(γ_deg; variant) * float(A_ff)

"""CR-172428 p.68 narrative checkpoints for R1: (γ_deg, ΔL_dB)."""
const BLOCKING_P68_CHECKPOINTS = (
    (0.0, 6.0),
    (50.0, 5.75),
    (60.0, 5.4),
    (70.0, 4.75),
    (80.0, 3.3),
    (90.0, 0.0),
)
