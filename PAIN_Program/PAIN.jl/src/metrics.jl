"""A-weighting and SIL post-processing (flowchart APP — X-EXTRAP for aircraft)."""

function a_weight_dB(f_Hz::Real)
    f = float(f_Hz)
    f2 = f^2
    num = 12194.0^2 * f2^2
    den = (f2 + 20.6^2) * sqrt((f2 + 107.7^2) * (f2 + 737.9^2)) * (f2 + 12194.0^2)
    Ra = num / den
    return 20 * log10(Ra) + 2.0
end

"""Speech Interference Level: arithmetic mean of 500, 1000, 2000, 4000 Hz octave bands."""
function sil_dB(octave_band_SPL::AbstractDict)
    bands = (500.0, 1000.0, 2000.0, 4000.0)
    return sum(get(octave_band_SPL, b, -100.0) for b in bands) / 4
end

"""
    overall_dBA(spectrum; uncertainty_1sigma_dB=3.5)

A-weighted overall level L_A = 10 log10 Σ 10^((L + A(f))/10).

When `spectrum.third_octave_SPL_dB` is non-empty, sum over all finite 1/3-octave
bands with A-weighting at each band centre frequency. Tones are not added again
(they are already folded into the bands in `interior_spl`). When the band dict is
empty (hand-built spectra), sum tonal harmonics at exact harmonic frequencies.

Uncertainty band ~3.5 dB 1σ per CR-172428 §6.1 when marked X-EXTRAP.
Returns (dBA, dBA−σ, dBA+σ).
"""
function overall_dBA(spectrum::InteriorSpectrum; uncertainty_1sigma_dB::Float64=3.5)
    pref2 = (20e-6)^2
    p2 = 0.0
    bands = spectrum.third_octave_SPL_dB
    if !isempty(bands)
        for (fc, spl) in bands
            (isfinite(fc) && isfinite(spl)) || continue
            p2 += pref2 * 10^((spl + a_weight_dB(fc)) / 10)
        end
    else
        for (H, spl) in enumerate(spectrum.harmonic_SPL_dB)
            f = H * spectrum.bpf_Hz
            p2 += pref2 * 10^((spl + a_weight_dB(f)) / 10)
        end
    end
    dBA = 10 * log10(p2 / pref2 + 1e-30)
    return dBA, dBA - uncertainty_1sigma_dB, dBA + uncertainty_1sigma_dB
end

"""SIL from 1/3-octave dict by folding nearest bands into octave centers."""
function sil_from_third_octave(third::AbstractDict{Float64,Float64})
    oct = Dict{Float64,Float64}()
    for oc in (500.0, 1000.0, 2000.0, 4000.0)
        # Energy sum of 1/3-oct bands whose center is within √2 of octave
        p2 = 0.0
        for (fc, spl) in third
            if abs(log(fc / oc) / log(2)) ≤ 0.5 / 3 + 0.2
                p2 += 10^(spl / 10)
            end
        end
        oct[oc] = 10 * log10(p2 + 1e-30)
    end
    return sil_dB(oct)
end
