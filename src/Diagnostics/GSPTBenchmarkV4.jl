module GSPTBenchmarkV4

using Statistics
using LsqFit
using LinearAlgebra
using Random
using Printf
import CSV
import JLD2

include(joinpath(@__DIR__, "..", "Config", "CaseDefaults.jl"))
using .CaseDefaults: normalize_case_symbol

export BENCHMARK_RESULT_SCHEMA_VERSION
export BENCHMARK_RESULT_FIELDS
export GroundTruthParams
export generate_synthetic_data
export run_bootstrapped_estimator
export calibrate_case_series
export load_case_series
export calibrate_case
export calibrate_cases
export run_benchmark_suite

const BENCHMARK_RESULT_SCHEMA_VERSION = "1.0.0"
const BENCHMARK_RESULT_FIELDS = (
    :Ri_fold_hat,
    :Ri_trans_hat,
    :Delta_Ri_H_hat,
    :gamma_hat,
    :c_hat,
    :fold_ci,
    :gamma_ci,
    :branch_labels,
    :eta_star,
    :valid,
)

const CASE_SERIES_FIELDS = (:t, :Ri, :e)
const CASE_REPORT_METRIC_FIELDS = (
    :Ri_fold_hat,
    :Ri_fold_ci_low,
    :Ri_fold_ci_high,
    :Ri_critical_proxy,
    :Delta_Ri_H_hat,
    :gamma_hat,
    :c_hat,
)

function _nan_case_metrics()
    return (
        Ri_fold_hat=NaN,
        Ri_fold_ci_low=NaN,
        Ri_fold_ci_high=NaN,
        Ri_critical_proxy=NaN,
        Delta_Ri_H_hat=NaN,
        gamma_hat=NaN,
        c_hat=NaN,
    )
end

function _normalize_report_status(status::Symbol)
    if status === :ok
        return :ok
    elseif status === :insufficient_extinction_samples
        return :insufficient_extinction
    elseif status === :calibration_invalid
        return :invalid_fit
    elseif status === :missing_artifacts || status === :missing_artifacts_after_fallback
        return :data_unavailable
    elseif status === :payload_read_error || status === :csv_read_error
        return :artifact_read_error
    elseif status === :scm_fallback_failed
        return :fallback_failed
    elseif status === :calibration_exception
        return :calibration_exception
    end
    return :unknown_failure
end

function _ri_critical_proxy(data, calibration)
    if !isnan(calibration.Ri_trans_hat)
        return max(0.0, calibration.Ri_trans_hat)
    end
    if data === nothing || length(data.Ri) == 0
        return NaN
    end
    # Conservative fallback proxy when burst-based Ri_trans is unavailable.
    return max(0.0, quantile(data.Ri, 0.10))
end

function _build_case_metrics(data, calibration)
    if calibration === nothing
        return _nan_case_metrics()
    end
    return (
        Ri_fold_hat=calibration.Ri_fold_hat,
        Ri_fold_ci_low=calibration.fold_ci[1],
        Ri_fold_ci_high=calibration.fold_ci[2],
        Ri_critical_proxy=_ri_critical_proxy(data, calibration),
        Delta_Ri_H_hat=calibration.Delta_Ri_H_hat,
        gamma_hat=calibration.gamma_hat,
        c_hat=calibration.c_hat,
    )
end

function _normalize_case_token(case_name::Union{String,Symbol})
    return lowercase(strip(String(case_name)))
end

function _candidate_case_dirs(case_name::Union{String,Symbol})
    token = _normalize_case_token(case_name)
    if token == "cases99"
        return ["CASES99", "cases99", "idealized_sbl"]
    elseif token == "floss"
        return ["FLOSS", "floss", "idealized_sbl"]
    elseif token == "sheba"
        return ["SHEBA", "sheba"]
    elseif token == "gabls1"
        return ["GABLS1", "gabls1"]
    end
    return [uppercase(token), token]
end

function _extract_series_from_payload(payload::Dict{String,Any})
    haskey(payload, "time_series") || error("payload missing time_series")
    ts = payload["time_series"]
    length(ts) > 0 || error("payload time_series is empty")

    t = Float64[]
    Ri = Float64[]
    e = Float64[]

    for row in ts
        push!(t, Float64(getproperty(row, :t)))
        push!(Ri, Float64(getproperty(row, :ri_min)))
        push!(e, Float64(getproperty(row, :surface_e_xi)))
    end

    return (t=t, Ri=Ri, e=e)
end

function _extract_series_from_csv(csv_path::AbstractString)
    table = CSV.File(csv_path)
    if !(:t in propertynames(table)) || !(:ri_min in propertynames(table)) || !(:surface_e_xi in propertynames(table))
        error("time_series.csv missing required columns: t, ri_min, surface_e_xi")
    end

    t = Float64[]
    Ri = Float64[]
    e = Float64[]
    for row in table
        push!(t, Float64(row.t))
        push!(Ri, Float64(row.ri_min))
        push!(e, Float64(row.surface_e_xi))
    end

    return (t=t, Ri=Ri, e=e)
end

function _run_scm_fallback(case_name::Union{String,Symbol}, outdir::AbstractString)
    case_arg = _normalize_case_token(case_name)
    run_case_script = normpath(joinpath(@__DIR__, "..", "..", "scm", "run_case.jl"))
    cmd = `$(Base.julia_cmd()) --project=. $run_case_script --case $case_arg --outdir $outdir`
    run(cmd)
    return nothing
end

function _case_failure(case_name::Union{String,Symbol}, case_dir::AbstractString, source::Symbol, code::Symbol, message::String)
    return (
        ok=false,
        case_input=String(case_name),
        case_family=String(normalize_case_symbol(case_name)),
        case_dir=case_dir,
        source=source,
        status=code,
        message=message,
        data=nothing,
        calibration=nothing,
    )
end

"""
    load_case_series(case_name; results_root="results", run_if_missing=true)

Resolve one case using artifact-first strategy:
1) `payload.jld2`
2) `time_series.csv`
3) run `scm/run_case.jl` fallback when enabled and retry
"""
function load_case_series(case_name::Union{String,Symbol}; results_root::AbstractString="results", run_if_missing::Bool=true)
    case_dirs = _candidate_case_dirs(case_name)

    for case_dir in case_dirs
        root = joinpath(results_root, case_dir)
        payload_path = joinpath(root, "payload.jld2")
        csv_path = joinpath(root, "time_series.csv")

        if isfile(payload_path)
            try
                payload = JLD2.load(payload_path)
                series = _extract_series_from_payload(payload)
                return (
                    ok=true,
                    case_input=String(case_name),
                    case_family=String(normalize_case_symbol(case_name)),
                    case_dir=case_dir,
                    source=:payload_jld2,
                    status=:ok,
                    message="loaded from payload.jld2",
                    data=series,
                    calibration=nothing,
                )
            catch err
                return _case_failure(case_name, case_dir, :payload_jld2, :payload_read_error, sprint(showerror, err))
            end
        end

        if isfile(csv_path)
            try
                series = _extract_series_from_csv(csv_path)
                return (
                    ok=true,
                    case_input=String(case_name),
                    case_family=String(normalize_case_symbol(case_name)),
                    case_dir=case_dir,
                    source=:time_series_csv,
                    status=:ok,
                    message="loaded from time_series.csv",
                    data=series,
                    calibration=nothing,
                )
            catch err
                return _case_failure(case_name, case_dir, :time_series_csv, :csv_read_error, sprint(showerror, err))
            end
        end
    end

    primary_dir = first(case_dirs)
    primary_root = joinpath(results_root, primary_dir)
    if run_if_missing
        try
            mkpath(primary_root)
            _run_scm_fallback(case_name, primary_root)
        catch err
            return _case_failure(case_name, primary_dir, :scm_fallback, :scm_fallback_failed, sprint(showerror, err))
        end

        payload_retry = joinpath(primary_root, "payload.jld2")
        csv_retry = joinpath(primary_root, "time_series.csv")
        if isfile(payload_retry)
            try
                payload = JLD2.load(payload_retry)
                series = _extract_series_from_payload(payload)
                return (
                    ok=true,
                    case_input=String(case_name),
                    case_family=String(normalize_case_symbol(case_name)),
                    case_dir=primary_dir,
                    source=:scm_fallback_payload,
                    status=:ok,
                    message="generated via SCM fallback and loaded from payload.jld2",
                    data=series,
                    calibration=nothing,
                )
            catch err
                return _case_failure(case_name, primary_dir, :scm_fallback_payload, :payload_read_error, sprint(showerror, err))
            end
        elseif isfile(csv_retry)
            try
                series = _extract_series_from_csv(csv_retry)
                return (
                    ok=true,
                    case_input=String(case_name),
                    case_family=String(normalize_case_symbol(case_name)),
                    case_dir=primary_dir,
                    source=:scm_fallback_csv,
                    status=:ok,
                    message="generated via SCM fallback and loaded from time_series.csv",
                    data=series,
                    calibration=nothing,
                )
            catch err
                return _case_failure(case_name, primary_dir, :scm_fallback_csv, :csv_read_error, sprint(showerror, err))
            end
        end
        return _case_failure(case_name, primary_dir, :scm_fallback, :missing_artifacts_after_fallback, "SCM fallback completed but no payload.jld2 or time_series.csv found")
    end

    return _case_failure(case_name, primary_dir, :artifact_lookup, :missing_artifacts, "No payload.jld2 or time_series.csv found")
end

"""
    calibrate_case_series(time, Ri, e; q_level=0.10, run_bootstrap_ci=true, e_floor=0.001)

Public, import-safe calibration entry point for downstream scripts and report builders.
This function performs light validation, clips energy to the laminar floor, computes a
representative `dt` from strictly increasing timestamps, and returns the benchmark estimate
in the stable schema defined by `BENCHMARK_RESULT_FIELDS`.
"""
function calibrate_case_series(
    time::AbstractVector{<:Real},
    Ri::AbstractVector{<:Real},
    e::AbstractVector{<:Real};
    q_level::Float64=0.10,
    run_bootstrap_ci::Bool=true,
    e_floor::Float64=0.001,
)
    n = length(time)
    if length(Ri) != n || length(e) != n
        throw(ArgumentError("time, Ri, and e must have equal lengths"))
    end
    if n < 8
        throw(ArgumentError("at least 8 samples are required for calibration"))
    end

    t = Float64.(time)
    Ri_vec = Float64.(Ri)
    e_vec = max.(e_floor, Float64.(e))

    if !all(isfinite, t) || !all(isfinite, Ri_vec) || !all(isfinite, e_vec)
        throw(ArgumentError("time, Ri, and e must be finite"))
    end

    dt_vec = diff(t)
    if any(<=(0.0), dt_vec)
        throw(ArgumentError("time must be strictly monotonically increasing"))
    end

    data = (
        time=t,
        Ri=Ri_vec,
        e=e_vec,
        dt=median(dt_vec),
    )

    result = run_bootstrapped_estimator(data; q_level=q_level, run_bootstrap_ci=run_bootstrap_ci, e_floor=e_floor)
    return result
end

"""
    calibrate_case(case_name; results_root="results", run_if_missing=true, q_level=0.10, run_bootstrap_ci=true, e_floor=0.001)

Phase-2 case adapter that resolves artifacts (or runs fallback SCM) and returns a
structured status tuple. Failures are encoded in `status/message` and do not throw.
"""
function calibrate_case(
    case_name::Union{String,Symbol};
    results_root::AbstractString="results",
    run_if_missing::Bool=true,
    q_level::Float64=0.10,
    run_bootstrap_ci::Bool=true,
    e_floor::Float64=0.001,
)
    loaded = load_case_series(case_name; results_root=results_root, run_if_missing=run_if_missing)
    if !loaded.ok
        return (
            ok=false,
            case_input=loaded.case_input,
            case_family=loaded.case_family,
            case_dir=loaded.case_dir,
            source=loaded.source,
            status=loaded.status,
            report_status=_normalize_report_status(loaded.status),
            message=loaded.message,
            data=nothing,
            calibration=nothing,
            metrics=_nan_case_metrics(),
            metric_fields=CASE_REPORT_METRIC_FIELDS,
        )
    end

    d = loaded.data
    try
        result = calibrate_case_series(d.t, d.Ri, d.e; q_level=q_level, run_bootstrap_ci=run_bootstrap_ci, e_floor=e_floor)
        n_ext = count(result.branch_labels .== :extinction)
        if !result.valid && n_ext < 20
            return (
                ok=false,
                case_input=loaded.case_input,
                case_family=loaded.case_family,
                case_dir=loaded.case_dir,
                source=loaded.source,
                status=:insufficient_extinction_samples,
                report_status=:insufficient_extinction,
                message="insufficient extinction samples for fit (n_extinction=$(n_ext), required>=20)",
                data=loaded.data,
                calibration=result,
                metrics=_build_case_metrics(loaded.data, result),
                metric_fields=CASE_REPORT_METRIC_FIELDS,
            )
        end
        if !result.valid
            return (
                ok=false,
                case_input=loaded.case_input,
                case_family=loaded.case_family,
                case_dir=loaded.case_dir,
                source=loaded.source,
                status=:calibration_invalid,
                report_status=:invalid_fit,
                message="calibration returned invalid fit",
                data=loaded.data,
                calibration=result,
                metrics=_build_case_metrics(loaded.data, result),
                metric_fields=CASE_REPORT_METRIC_FIELDS,
            )
        end

        return (
            ok=true,
            case_input=loaded.case_input,
            case_family=loaded.case_family,
            case_dir=loaded.case_dir,
            source=loaded.source,
            status=:ok,
            report_status=:ok,
            message="case calibration completed",
            data=loaded.data,
            calibration=result,
            metrics=_build_case_metrics(loaded.data, result),
            metric_fields=CASE_REPORT_METRIC_FIELDS,
        )
    catch err
        return (
            ok=false,
            case_input=loaded.case_input,
            case_family=loaded.case_family,
            case_dir=loaded.case_dir,
            source=loaded.source,
            status=:calibration_exception,
            report_status=:calibration_exception,
            message=sprint(showerror, err),
            data=loaded.data,
            calibration=nothing,
            metrics=_nan_case_metrics(),
            metric_fields=CASE_REPORT_METRIC_FIELDS,
        )
    end
end

"""
    calibrate_cases(case_names; kwargs...)

Run case calibration for a list of datasets and return a vector of report-facing
status tuples, each including normalized status semantics and the agreed metric set.
"""
function calibrate_cases(case_names::AbstractVector{<:Union{String,Symbol}}; kwargs...)
    return [calibrate_case(case_name; kwargs...) for case_name in case_names]
end

# ==============================================================================
# 1. HELPER FUNCTIONS: SAVITZKY-GOLAY & GAUSSIAN KERNEL ENVELOPE (C^∞)
# ==============================================================================

"""
5-point Savitzky-Golay 1st derivative filter (2nd-order polynomial kernel).
"""
function savitzky_golay_derivative(x::Vector{Float64}, dt::Float64)
    n = length(x)
    dx = zeros(Float64, n)
    for i in 3:(n-2)
        dx[i] = (-2.0*x[i-2] - x[i-1] + x[i+1] + 2.0*x[i+2]) / (10.0 * dt)
    end
    dx[1] = (x[2] - x[1]) / dt
    dx[2] = (x[3] - x[1]) / (2.0 * dt)
    dx[end-1] = (x[end] - x[end-2]) / (2.0 * dt)
    dx[end] = (x[end] - x[end-1]) / dt
    return dx
end

"""
Gaussian Kernel Quantile Smoothing for C^∞ Envelope F^(0)(Ri) and exact derivative dF^(0)/dRi.
Replaces piecewise linear interpolation with a smooth manifold projection.
"""
function kernel_smooth_envelope(ri_nodes::Vector{Float64}, e_nodes::Vector{Float64}, ri_eval::Vector{Float64}; bandwidth::Float64=0.03)
    N = length(ri_eval)
    F0 = zeros(Float64, N)
    dF0_dRi = zeros(Float64, N)

    for i in 1:N
        r = ri_eval[i]
        diffs = (r .- ri_nodes) ./ bandwidth
        weights = exp.(-0.5 .* diffs.^2)
        dweights_dr = (-diffs ./ bandwidth) .* weights

        W_sum = sum(weights)
        if W_sum > 1e-12
            F0[i] = sum(weights .* e_nodes) / W_sum
            dW_sum = sum(dweights_dr)
            # Analytical quotient rule derivative
            dF0_dRi[i] = (sum(dweights_dr .* e_nodes) * W_sum - sum(weights .* e_nodes) * dW_sum) / (W_sum^2)
        else
            F0[i] = e_nodes[1]
            dF0_dRi[i] = 0.0
        end
    end
    return F0, dF0_dRi
end

# ==============================================================================
# 2. SYNTHETIC GENERATOR WITH RANDOMIZED STRUCTURAL MODEL MISMATCH
# ==============================================================================

struct GroundTruthParams
    Ri_fold_star::Float64   # Prescribed fold point
    Ri_trans_star::Float64  # Prescribed ignition burst point
    gamma_star::Float64     # Prescribed saddle-node exponent
    c_star::Float64         # Normal form amplitude constant
    sigma_e::Float64        # Observational TKE noise
    sigma_Ri::Float64       # Observational Richardson noise
    e_floor::Float64        # Physical laminar floor
    inject_mismatch::Bool   # Turn on stochastic higher-order perturbation
end

function GroundTruthParams(;
    Ri_fold=0.35, Ri_trans=0.15, gamma=0.50, c=0.45,
    sigma_e=0.008, sigma_Ri=0.015, e_floor=0.001, inject_mismatch=true
)
    return GroundTruthParams(Ri_fold, Ri_trans, gamma, c, sigma_e, sigma_Ri, e_floor, inject_mismatch)
end

"""
Generates trajectories with stochastic structural mismatch (randomized quadratic amplitude, ripple frequency, and phase).
"""
function generate_synthetic_data(gt::GroundTruthParams; N_cycles=8, points_per_cycle=100, seed=42)
    Random.seed!(seed)
    N = N_cycles * points_per_cycle
    t = collect(range(0.0, stop=12.0 * 3600.0, length=N))
    dt = t[2] - t[1]

    # Draw stochastic mismatch coefficients per realization
    quad_amp    = gt.inject_mismatch ? (0.02 + 0.02 * rand()) : 0.0
    ripple_amp  = gt.inject_mismatch ? (0.03 + 0.03 * rand()) : 0.0
    ripple_freq = gt.inject_mismatch ? (4.0 + 4.0 * rand())   : 0.0
    ripple_phase= gt.inject_mismatch ? (2.0 * pi * rand())    : 0.0

    Ri_true = zeros(N)
    e_true = zeros(N)
    true_branch = Vector{Symbol}(undef, N)

    state = :active
    ri_val = 0.10

    for i in 1:N
        if state == :active
            ri_val += 0.003 + 0.001 * randn()

            if ri_val < gt.Ri_fold_star
                e_base = gt.c_star * (gt.Ri_fold_star - ri_val)^gt.gamma_star

                if gt.inject_mismatch
                    quad_pert   = quad_amp * (gt.Ri_fold_star - ri_val)^2
                    ripple_pert = ripple_amp * e_base * sin(ripple_freq * ri_val + ripple_phase)
                    e_val = max(gt.e_floor, e_base + quad_pert + ripple_pert)
                else
                    e_val = max(gt.e_floor, e_base)
                end
                true_branch[i] = :extinction
            else
                state = :quiescent
                e_val = gt.e_floor
                true_branch[i] = :extinction
            end
        else
            ri_val -= 0.004 + 0.001 * randn()
            e_val = gt.e_floor
            true_branch[i] = :ignition

            if ri_val <= gt.Ri_trans_star
                state = :active
            end
        end

        Ri_true[i] = ri_val
        e_true[i] = e_val
    end

    Ri_obs = max.(0.01, Ri_true .+ gt.sigma_Ri .* randn(N))
    e_obs  = max.(gt.e_floor, e_true .+ gt.sigma_e .* abs.(randn(N)))

    return (time=t, Ri=Ri_obs, e=e_obs, Ri_true=Ri_true, e_true=e_true, true_branch=true_branch, dt=dt)
end

# ==============================================================================
# 3. SMOOTH REGULARIZED SADDLE-NODE MODEL
# ==============================================================================

function saddle_node_smooth(ri_vec::Vector{Float64}, p::Vector{Float64}; delta::Float64=1e-3, e_floor::Float64=0.001)
    Ri_fold, c, gamma = p[1], p[2], p[3]
    return [c * ((max(0.0, Ri_fold - ri))^2 + delta^2)^(gamma / 2.0) + e_floor for ri in ri_vec]
end

# ==============================================================================
# 4. MOVING BLOCK BOOTSTRAP (MBB) CONFIDENCE INTERVAL ESTIMATOR
# ==============================================================================

function moving_block_bootstrap_ci(Ri_ext::Vector{Float64}, e_ext::Vector{Float64}, q_level::Float64;
                                   block_len::Int=25, n_boot::Int=100, e_floor::Float64=0.001)
    n = length(Ri_ext)
    if n < 30
        return (fold_ci=(NaN, NaN), gamma_ci=(NaN, NaN), c_ci=(NaN, NaN))
    end

    num_overlapping_blocks = n - block_len + 1
    n_blocks_needed = div(n, block_len) + 1

    boot_folds = Float64[]
    boot_gammas = Float64[]
    boot_cs = Float64[]

    for b in 1:n_boot
        # Sample overlapping block start indices with replacement
        block_starts = rand(1:num_overlapping_blocks, n_blocks_needed)
        indices = Int[]
        for s in block_starts
            append!(indices, s:(s + block_len - 1))
        end
        indices = indices[1:n] # Truncate to original length

        Ri_b = Ri_ext[indices]
        e_b  = e_ext[indices]

        ri_edges = range(minimum(Ri_b), quantile(Ri_b, 0.95), length=10)
        ri_c = Float64[]
        e_q  = Float64[]
        for i in 1:(length(ri_edges)-1)
            m = (Ri_b .>= ri_edges[i]) .& (Ri_b .< ri_edges[i+1])
            if count(m) >= 3
                push!(ri_c, 0.5 * (ri_edges[i] + ri_edges[i+1]))
                push!(e_q, quantile(e_b[m], q_level))
            end
        end

        if length(ri_c) >= 4
            model(ri, p) = saddle_node_smooth(ri, p; e_floor=e_floor)
            p0 = [0.35, 0.40, 0.50]
            try
                fit = curve_fit(model, ri_c, e_q, p0; lower=[0.10, 0.01, 0.10], upper=[1.50, 3.00, 1.50])
                push!(boot_folds, fit.param[1])
                push!(boot_cs, fit.param[2])
                push!(boot_gammas, fit.param[3])
            catch
                # Ignore non-convergent resamples
            end
        end
    end

    if length(boot_folds) >= 15
        fold_ci  = (quantile(boot_folds, 0.025), quantile(boot_folds, 0.975))
        gamma_ci = (quantile(boot_gammas, 0.025), quantile(boot_gammas, 0.975))
        c_ci     = (quantile(boot_cs, 0.025), quantile(boot_cs, 0.975))
    else
        fold_ci, gamma_ci, c_ci = (NaN, NaN), (NaN, NaN), (NaN, NaN)
    end

    return (fold_ci=fold_ci, gamma_ci=gamma_ci, c_ci=c_ci)
end

# ==============================================================================
# 5. MANIFOLD RECONSTRUCTION ESTIMATOR (WITH η* PROJECTION & DEFENSIVE GUARDS)
# ==============================================================================

function run_bootstrapped_estimator(data; q_level::Float64=0.10, run_bootstrap_ci::Bool=true, e_floor::Float64=0.001)
    Ri = data.Ri
    e  = data.e
    dt = data.dt
    N  = length(Ri)

    # STEP 1: Compute smoothed trajectory derivatives
    dRi_dt = savitzky_golay_derivative(Ri, dt)
    de_dt  = savitzky_golay_derivative(e, dt)

    # STEP 2: First-Pass Kernel Smooth Envelope F^(0)(Ri) Reconstruction
    ri_bins_0 = range(minimum(Ri), quantile(Ri, 0.90), length=12)
    ri_c0 = Float64[]
    e_q0  = Float64[]
    for i in 1:(length(ri_bins_0)-1)
        mask = (Ri .>= ri_bins_0[i]) .& (Ri .< ri_bins_0[i+1])
        if count(mask) >= 3
            push!(ri_c0, 0.5 * (ri_bins_0[i] + ri_bins_0[i+1]))
            push!(e_q0, quantile(e[mask], q_level))
        end
    end

    if length(ri_c0) < 4
        # Defensive fallback if trajectory cloud is degenerately sparse
        return (
            Ri_fold_hat=NaN, Ri_trans_hat=NaN, Delta_Ri_H_hat=NaN, gamma_hat=NaN, c_hat=NaN,
            fold_ci=(NaN,NaN), gamma_ci=(NaN,NaN), branch_labels=fill(:ignition, N),
            eta_star=zeros(N), valid=false
        )
    end

    # Evaluate C^∞ kernel envelope & derivative ∂F^(0)/∂Ri at observed points
    F0_at_Ri, dF0_dRi_at_Ri = kernel_smooth_envelope(ri_c0, e_q0, Ri; bandwidth=0.03)

    # STEP 3: Nondimensionalized Scale-Independent Normal Velocity Projection η*
    # η* = [ de/dt - (∂F^(0)/∂Ri)*dRi/dt ] / sqrt( (de/dt)^2 + (dRi/dt)^2 + ε0 )
    eps0 = 1e-8
    v_mag = sqrt.(de_dt.^2 .+ dRi_dt.^2 .+ eps0)
    eta_unnorm = de_dt .- dF0_dRi_at_Ri .* dRi_dt
    eta_star = eta_unnorm ./ v_mag

    classified_branch = Vector{Symbol}(undef, N)
    for i in 1:N
        # Non-dimensional criterion: η* <= 0 indicates motion parallel or returning to envelope
        if eta_star[i] <= 0.0 && e[i] > (e_floor + 0.001)
            classified_branch[i] = :extinction
        else
            classified_branch[i] = :ignition
        end
    end

    # STEP 4: Quantile Binning on Extinction Branch with Defensive Sample Guard
    ext_mask = classified_branch .== :extinction
    if count(ext_mask) < 20
        return (
            Ri_fold_hat=NaN, Ri_trans_hat=NaN, Delta_Ri_H_hat=NaN, gamma_hat=NaN, c_hat=NaN,
            fold_ci=(NaN,NaN), gamma_ci=(NaN,NaN), branch_labels=classified_branch,
            eta_star=eta_star, valid=false
        )
    end

    Ri_ext = Ri[ext_mask]
    e_ext  = e[ext_mask]

    ri_edges = range(minimum(Ri_ext), quantile(Ri_ext, 0.95), length=12)
    ri_centers = Float64[]
    e_quantile = Float64[]

    for i in 1:(length(ri_edges)-1)
        b_mask = (Ri_ext .>= ri_edges[i]) .& (Ri_ext .< ri_edges[i+1])
        if count(b_mask) >= 4
            push!(ri_centers, 0.5 * (ri_edges[i] + ri_edges[i+1]))
            push!(e_quantile, quantile(e_ext[b_mask], q_level))
        end
    end

    if length(ri_centers) < 4
        return (
            Ri_fold_hat=NaN, Ri_trans_hat=NaN, Delta_Ri_H_hat=NaN, gamma_hat=NaN, c_hat=NaN,
            fold_ci=(NaN,NaN), gamma_ci=(NaN,NaN), branch_labels=classified_branch,
            eta_star=eta_star, valid=false
        )
    end

    # STEP 5: Fit Smooth Saddle-Node Normal Form
    model(ri, p) = saddle_node_smooth(ri, p; e_floor=e_floor)
    p0 = [0.30, 0.40, 0.50]

    Ri_fold_hat, c_hat, gamma_hat = NaN, NaN, NaN
    try
        fit = curve_fit(model, ri_centers, e_quantile, p0; lower=[0.10, 0.01, 0.10], upper=[1.50, 3.00, 1.50])
        Ri_fold_hat = fit.param[1]
        c_hat       = fit.param[2]
        gamma_hat   = fit.param[3]
    catch
        return (
            Ri_fold_hat=NaN, Ri_trans_hat=NaN, Delta_Ri_H_hat=NaN, gamma_hat=NaN, c_hat=NaN,
            fold_ci=(NaN,NaN), gamma_ci=(NaN,NaN), branch_labels=classified_branch,
            eta_star=eta_star, valid=false
        )
    end

    # STEP 6: Moving Block Bootstrapping for Non-Parametric CIs
    ci_res = run_bootstrap_ci ? moving_block_bootstrap_ci(Ri_ext, e_ext, q_level; e_floor=e_floor) :
                                (fold_ci=(NaN,NaN), gamma_ci=(NaN,NaN), c_ci=(NaN,NaN))

    # STEP 7: Ignition Threshold & Hysteresis
    ign_mask = classified_branch .== :ignition
    burst_events = (de_dt .> 0.0005) .& (e .< 0.04) .& ign_mask
    Ri_trans_hat = any(burst_events) ? median(Ri[burst_events]) : NaN
    Delta_Ri_H_hat = isnan(Ri_trans_hat) ? NaN : (Ri_fold_hat - Ri_trans_hat)

    return (
        Ri_fold_hat    = Ri_fold_hat,
        Ri_trans_hat   = Ri_trans_hat,
        Delta_Ri_H_hat = Delta_Ri_H_hat,
        gamma_hat      = gamma_hat,
        c_hat          = c_hat,
        fold_ci        = ci_res.fold_ci,
        gamma_ci       = ci_res.gamma_ci,
        branch_labels  = classified_branch,
        eta_star       = eta_star,
        valid          = true
    )
end

# ==============================================================================
# 6. BENCHMARK SUITE (EXPANDED MC MATRIX, RECOMPUTED METRICS, RECOVERY HEATMAP)
# ==============================================================================

function compute_classification_metrics(true_b::Vector{Symbol}, pred_b::Vector{Symbol})
    tp = count((true_b .== :extinction) .& (pred_b .== :extinction))
    fp = count((true_b .== :ignition)   .& (pred_b .== :extinction))
    tn = count((true_b .== :ignition)   .& (pred_b .== :ignition))
    fn = count((true_b .== :extinction) .& (pred_b .== :ignition))

    denom = sqrt(Float64(tp + fp) * (tp + fn) * (tn + fp) * (tn + fn))
    mcc   = denom > 0.0 ? (tp * tn - fp * fn) / denom : 0.0
    f1    = (2.0 * tp + fp + fn) > 0 ? (2.0 * tp) / (2.0 * tp + fp + fn) : 0.0
    bal_acc = 0.5 * ((tp / max(1, tp + fn)) + (tn / max(1, tn + fp)))

    return (tp=tp, fp=fp, tn=tn, fn=fn, mcc=mcc, f1=f1, bal_acc=bal_acc)
end

function run_benchmark_suite()
    println("=================================================================")
    println("      GSPT-SBL PUBLICATION BENCHMARK SUITE (V4 REFACTORED)       ")
    println("=================================================================\n")

    gt_default = GroundTruthParams(Ri_fold=0.35, Ri_trans=0.15, gamma=0.50, c=0.45, inject_mismatch=true)
    println("Ground Truth System (WITH Stochastic Model Mismatch Injected):")
    @printf("  e_true = c*(Ri_fold - Ri)^γ + stochastic[ quadratic + sinusoidal ripple ]\n")
    @printf("  Ri_fold* = %.3f | Ri_trans* = %.3f | γ* = %.3f\n\n",
            gt_default.Ri_fold_star, gt_default.Ri_trans_star, gt_default.gamma_star)

    # TEST 1: Fold Localization & Coverage (Monte Carlo over Randomized Mismatch)
    N_mc = 40
    E_fold_list = Float64[]
    gamma_list  = Float64[]
    ci_coverage_count = 0

    for seed in 1:N_mc
        gt = GroundTruthParams(Ri_fold=0.35, gamma=0.50, inject_mismatch=true)
        data = generate_synthetic_data(gt; seed=seed)
        res  = run_bootstrapped_estimator(data; run_bootstrap_ci=true)

        if res.valid && !isnan(res.Ri_fold_hat)
            E_fold = abs(res.Ri_fold_hat - gt.Ri_fold_star)
            push!(E_fold_list, E_fold)
            push!(gamma_list, res.gamma_hat)

            if !isnan(res.fold_ci[1]) && (res.fold_ci[1] <= gt.Ri_fold_star <= res.fold_ci[2])
                ci_coverage_count += 1
            end
        end
    end

    println("--- TEST 1: Fold Localization under Stochastic Structural Mismatch ---")
    @printf("  E_fold Mean      : %.4f\n", mean(E_fold_list))
    @printf("  E_fold 95%% Quant : %.4f\n", quantile(E_fold_list, 0.95))
    @printf("  E_fold Max       : %.4f\n", maximum(E_fold_list))
    @printf("  γ Mean Estimate  : %.4f (Std: %.4f)\n", mean(gamma_list), std(gamma_list))
    @printf("  95%% MBB Coverage : %.1f%%\n\n", (ci_coverage_count / length(E_fold_list)) * 100.0)

    # TEST 2: Nondimensional Velocity Normal η* Classification
    single_data = generate_synthetic_data(gt_default; seed=101)
    single_res  = run_bootstrapped_estimator(single_data; run_bootstrap_ci=false)
    m_single    = compute_classification_metrics(single_data.true_branch, single_res.branch_labels)

    println("--- TEST 2: Scale-Independent η* Velocity Normal Classification ---")
    @printf("  True Extinction  | TP = %4d | FN = %4d |\n", m_single.tp, m_single.fn)
    @printf("  True Ignition    | FP = %4d | TN = %4d |\n", m_single.fp, m_single.tn)
    @printf("  Balanced Acc : %.2f%%\n", m_single.bal_acc * 100.0)
    @printf("  F1 Score     : %.4f\n", m_single.f1)
    @printf("  MCC Metric   : %.4f\n\n", m_single.mcc)

    # TEST 3: Multi-Parameter Stress Matrix with Dynamic Recomputed Metrics
    println("--- TEST 3: Multi-Parameter Monte Carlo Stress Matrix ---")
    println("  σ_Ri   |  σ_e   | γ_true | Ri_fold* | Mean E_fold | Mean γ_hat | Mean MCC ")
    println("  -------|--------|--------|----------|-------------|------------|----------")

    sig_Ri_vals = [0.01, 0.03]
    sig_e_vals  = [0.005, 0.015]
    Ri_fold_vals = [0.25, 0.35]

    # Matrix store for recovery heatmap table: E_fold_matrix[i_sigma_Ri, j_sigma_e]
    heatmap_matrix = zeros(length(sig_Ri_vals), length(sig_e_vals))

    for (i_r, σ_Ri) in enumerate(sig_Ri_vals)
        for (j_e, σ_e) in enumerate(sig_e_vals)
            cell_E_folds = Float64[]

            for Ri_f in Ri_fold_vals
                for γ_val in [0.45, 0.55]
                    local_E_fold = Float64[]
                    local_gammas = Float64[]
                    local_mccs   = Float64[]

                    for s in 1:8
                        gt_s = GroundTruthParams(Ri_fold=Ri_f, gamma=γ_val, sigma_Ri=σ_Ri, sigma_e=σ_e, inject_mismatch=true)
                        d_s  = generate_synthetic_data(gt_s; seed=s)
                        r_s  = run_bootstrapped_estimator(d_s; run_bootstrap_ci=false)

                        if r_s.valid && !isnan(r_s.Ri_fold_hat)
                            push!(local_E_fold, abs(r_s.Ri_fold_hat - gt_s.Ri_fold_star))
                            push!(local_gammas, r_s.gamma_hat)

                            m_s = compute_classification_metrics(d_s.true_branch, r_s.branch_labels)
                            push!(local_mccs, m_s.mcc)
                        end
                    end

                    if !isempty(local_E_fold)
                        @printf("  %.3f  | %.3f  | %.2f   |   %.3f  |   %.4f    |   %.4f   |  %.4f\n",
                                σ_Ri, σ_e, γ_val, Ri_f, mean(local_E_fold), mean(local_gammas), mean(local_mccs))
                        append!(cell_E_folds, local_E_fold)
                    end
                end
            end
            heatmap_matrix[i_r, j_e] = mean(cell_E_folds)
        end
    end

    # TEST 4: Textual Recovery Surface Heatmap E_fold(σ_Ri, σ_e)
    println("\n--- TEST 4: Fold Localization Error Surface E_fold(σ_Ri, σ_e) ---")
    println("          |  σ_e = 0.005  |  σ_e = 0.015  |")
    println("  --------|---------------|---------------|")
    @printf("  σ_Ri=0.01 |    %.4f     |    %.4f     |\n", heatmap_matrix[1, 1], heatmap_matrix[1, 2])
    @printf("  σ_Ri=0.03 |    %.4f     |    %.4f     |\n", heatmap_matrix[2, 1], heatmap_matrix[2, 2])

    println("\n=================================================================")
    println("               BENCHMARK COMPLETED SUCCESSFULLY                  ")
    println("=================================================================")
end

end # module
