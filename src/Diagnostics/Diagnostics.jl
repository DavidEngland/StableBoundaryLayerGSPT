module Diagnostics

using DataFrames
using Random
using Statistics

export compute_diagnostics, synthetic_bifurcation_analysis

"""Compute paper-facing diagnostics from integrated state trajectories."""
function compute_diagnostics(states::Vector{<:NamedTuple})
    ris = [s.ri for s in states]
    tkes = [s.tke for s in states]

    return Dict(
        "n_samples" => length(states),
        "ri_mean" => mean(ris),
        "ri_max" => maximum(ris),
        "tke_mean" => mean(tkes),
        "tke_min" => minimum(tkes),
        "critical_slowing_index" => abs(mean(diff(tkes))),
    )
end

"""Run synthetic parameter-sweep bifurcation analysis and uncertainty envelopes."""
function synthetic_bifurcation_analysis(
    ;
    parameters::AbstractDict{String,<:Any},
    nsamples::Int=300,
    ngrid::Int=60,
    seed::Int=42,
)
    rng = MersenneTwister(seed)

    sigma0 = Float64(get(parameters, "sigma", 1.0))
    k0 = Float64(get(parameters, "K", 0.8))
    alpha0 = Float64(get(parameters, "alpha", 0.6))

    a_fold0 = Float64(get(parameters, "a_fold", 0.6))
    b_fold0 = Float64(get(parameters, "b_fold", 0.35))
    t0 = Float64(get(parameters, "T0", 280.0))
    s0 = Float64(get(parameters, "S0", 0.8))

    s_grid = collect(range(0.05, 2.0; length=ngrid))
    gamma_grid = collect(range(0.0, 1.2; length=ngrid))
    ts_grid = collect(range(274.0, 288.0; length=ngrid))

    # Transcritical map in (S, Gamma) space.
    trans_rows = NamedTuple[]
    trans_tol = 0.02
    for s in s_grid
        for gamma in gamma_grid
            delta = sigma0 * s^2 - k0 * gamma
            e_star = max(0.0, delta / alpha0)
            regime = delta > 0 ? "turbulent" : "laminar"
            push!(
                trans_rows,
                (
                    S=s,
                    Gamma=gamma,
                    Delta=delta,
                    distance_to_transcritical=abs(delta),
                    e_star=e_star,
                    regime=regime,
                    near_transcritical=abs(delta) <= trans_tol,
                ),
            )
        end
    end
    transcritical_map = DataFrame(trans_rows)

    # Fold map in (Ts, S) space from synthetic reduced manifold relation.
    fold_rows = NamedTuple[]
    h_tol = 0.03
    dh_tol = 0.03
    for ts in ts_grid
        d_h = 3 * (ts - t0)^2 - a_fold0
        for s in s_grid
            h = (ts - t0)^3 - a_fold0 * (ts - t0) + b_fold0 * (s - s0)
            push!(
                fold_rows,
                (
                    Ts=ts,
                    S=s,
                    H=h,
                    dH_dTs=d_h,
                    fold_distance=hypot(h, d_h),
                    near_fold=(abs(h) <= h_tol) && (abs(d_h) <= dh_tol),
                ),
            )
        end
    end
    fold_map = DataFrame(fold_rows)

    # Monte Carlo uncertainty envelopes for transcritical threshold Gamma_c(S).
    gamma_c_samples = Matrix{Float64}(undef, nsamples, length(s_grid))
    fold_plus_samples = Vector{Float64}(undef, nsamples)
    fold_minus_samples = Vector{Float64}(undef, nsamples)
    ts_plus_samples = Vector{Float64}(undef, nsamples)
    ts_minus_samples = Vector{Float64}(undef, nsamples)

    for i in 1:nsamples
        sigma_i = max(1e-6, sigma0 * (1 + 0.2 * randn(rng)))
        k_i = max(1e-6, k0 * (1 + 0.2 * randn(rng)))
        a_fold_i = max(1e-6, a_fold0 * (1 + 0.2 * randn(rng)))
        b_fold_i = max(1e-6, b_fold0 * (1 + 0.2 * randn(rng)))

        gamma_c_samples[i, :] = (sigma_i / k_i) .* (s_grid .^ 2)

        ts_offset = sqrt(a_fold_i / 3)
        ts_plus = t0 + ts_offset
        ts_minus = t0 - ts_offset

        s_fold_plus = s0 - ((ts_plus - t0)^3 - a_fold_i * (ts_plus - t0)) / b_fold_i
        s_fold_minus = s0 - ((ts_minus - t0)^3 - a_fold_i * (ts_minus - t0)) / b_fold_i

        fold_plus_samples[i] = s_fold_plus
        fold_minus_samples[i] = s_fold_minus
        ts_plus_samples[i] = ts_plus
        ts_minus_samples[i] = ts_minus
    end

    envelope_rows = NamedTuple[]
    for (j, s) in enumerate(s_grid)
        sample_col = view(gamma_c_samples, :, j)
        push!(
            envelope_rows,
            (
                S=s,
                gamma_c_p05=quantile(sample_col, 0.05),
                gamma_c_p50=quantile(sample_col, 0.50),
                gamma_c_p95=quantile(sample_col, 0.95),
            ),
        )
    end
    transcritical_envelope = DataFrame(envelope_rows)

    # Parameter-sensitivity envelope for critical transcritical threshold.
    sensitivity_scale = collect(range(0.7, 1.3; length=max(ngrid, 15)))
    sensitivity_rows = NamedTuple[]
    for scale in sensitivity_scale
        sigma_i = max(1e-6, sigma0 * scale)
        k_i = max(1e-6, k0 * scale)
        alpha_i = max(1e-6, alpha0 * scale)

        gamma_curve = (sigma_i / k_i) .* (s_grid .^ 2)
        push!(
            sensitivity_rows,
            (
                scale=scale,
                sigma=sigma_i,
                K=k_i,
                alpha=alpha_i,
                gamma_c_min=minimum(gamma_curve),
                gamma_c_p50=quantile(gamma_curve, 0.50),
                gamma_c_max=maximum(gamma_curve),
            ),
        )
    end
    parameter_sensitivity_envelope = DataFrame(sensitivity_rows)

    fold_envelope = DataFrame(
        branch=["plus", "minus"],
        Ts_p05=[quantile(ts_plus_samples, 0.05), quantile(ts_minus_samples, 0.05)],
        Ts_p50=[quantile(ts_plus_samples, 0.50), quantile(ts_minus_samples, 0.50)],
        Ts_p95=[quantile(ts_plus_samples, 0.95), quantile(ts_minus_samples, 0.95)],
        S_fold_p05=[quantile(fold_plus_samples, 0.05), quantile(fold_minus_samples, 0.05)],
        S_fold_p50=[quantile(fold_plus_samples, 0.50), quantile(fold_minus_samples, 0.50)],
        S_fold_p95=[quantile(fold_plus_samples, 0.95), quantile(fold_minus_samples, 0.95)],
    )

    transcritical_frac = mean(transcritical_map.near_transcritical)
    fold_frac = mean(fold_map.near_fold)

    summary = Dict(
        "nsamples" => nsamples,
        "ngrid" => ngrid,
        "transcritical_near_fraction" => transcritical_frac,
        "fold_near_fraction" => fold_frac,
        "sigma" => sigma0,
        "K" => k0,
        "alpha" => alpha0,
    )

    return (
        transcritical_map=transcritical_map,
        fold_map=fold_map,
        transcritical_envelope=transcritical_envelope,
        fold_envelope=fold_envelope,
        parameter_sensitivity_envelope=parameter_sensitivity_envelope,
        summary=summary,
    )
end

end