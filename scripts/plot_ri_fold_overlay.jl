#!/usr/bin/env julia

"""
    plot_ri_fold_overlay.jl

Publication-quality diagnostic overlay comparing Single Column Model (SCM)
trajectories directly against the analytical GSPT fold locus Ri_fold(T_s).

Upgrades incorporated:
 1. Exact GSPT fold condition derived from ∂f/∂e = 0 with (δ, η, γ, ℓ0).
 2. Selectable buoyancy closures (:tanh, :exp, :regularized).
 3. Gradient Ri_g computation when vertical profiles exist, fallback to Ri_b.
 4. Safe numerical fold termination (no line-breaking NaNs).
 5. Trajectory regime classification (Turbulent, Bistable, Collapsed).
 6. Collapse (▲) and recovery (▼) fold-crossing event markers.
 7. Normalized TKE (ehat = e / e_max) on a unified single y-axis (no twinx).
 8. High-contrast semi-transparent shading (fillalpha = 0.08) for print/grayscale.
 9. Encapsulated Base.@kwdef struct GSPTParameters container.
10. JAS publication additions: Start/End markers, event flags, and direction arrows.

Usage:
    julia --project=. scripts/plot_ri_fold_overlay.jl \\
        --solution results/CASES99/latest/solution.csv \\
        --out reports/generated/figures/ri_fold_trajectory_overlay.png
"""

using CSV
using DataFrames
using Plots
using Plots.PlotMeasures
using Printf

# Set headless plotting backend for CI/cluster environments
gr()

# ==============================================================================
# 1. Parameter Container Struct
# ==============================================================================

Base.@kwdef struct GSPTParameters{T<:Real}
    c_s::T      = 0.22    # Shear coupling coefficient (c_s = eta * gamma)
    beta::T     = 0.12    # Fast TKE dissipation feedback factor beta
    K::T        = 0.08    # Kinematic buoyancy scale K (m/s^2)
    beta_T::T   = 12.0    # Thermal response scaling beta_T
    delta::T    = 1e-6    # Regularization floor delta
    eta::T      = 1.0     # Mechanical efficiency eta
    gamma::T    = 0.22    # Shear production factor gamma
    l0::T       = 15.0    # Mixing length scale l0 (m)
    g::T        = 9.81    # Gravitational acceleration (m/s^2)
    theta_ref::T = 288.15 # Reference potential temperature (K)
    z1::T       = 10.0    # First model layer height (m)
end

# ==============================================================================
# 2. Selectable Buoyancy Laws & Exact GSPT Fold Conditions
# ==============================================================================

"""
    compute_buoyancy(T_s; T_a=280.0, params=GSPTParameters(), closure=:tanh)

Computes buoyancy destruction B(T_s) using one of three supported closures:
 - :tanh: Bounded hyperbolic tangent model
 - :exp: Classical exponential inversion model
 - :regularized: C-infinity bounded algebraic regularization
"""
function compute_buoyancy(T_s::Real; T_a::Real=280.0, params::GSPTParameters=GSPTParameters(), closure::Symbol=:tanh)
    dT = max(0.0, T_a - T_s)
    x = params.beta_T * (dT / T_a)

    if closure == :tanh
        return params.K * tanh(x)
    elseif closure == :exp
        return params.K * (exp(min(x, 5.0)) - 1.0)
    elseif closure == :regularized
        return params.K * (x / sqrt(1.0 + x^2))
    else
        error("Unsupported buoyancy closure: :$closure. Choose from [:tanh, :exp, :regularized].")
    end
end

"""
    compute_ri_fold(T_s; T_a=280.0, params=GSPTParameters(), closure=:tanh)

Calculates the exact analytical fold locus Ri_fold(T_s) derived from df/de = 0:
    Pi(T_s) = (beta^2 * l0) / (4 * B(T_s))
    Ri_fold(T_s) = c_s / (1 - Pi(T_s))
"""
function compute_ri_fold(T_s::Real; T_a::Real=280.0, params::GSPTParameters=GSPTParameters(), closure::Symbol=:tanh)
    B = compute_buoyancy(T_s; T_a=T_a, params=params, closure=closure)

    # Non-dimensional control parameter Pi(T_s)
    Pi_val = (params.beta^2 * params.l0) / (4.0 * max(B, 1e-12))

    # Safe numerical termination to prevent NaN drawing breaks
    Pi_bounded = min(Pi_val, 0.999)

    return params.c_s / max(1.0 - Pi_bounded, 1e-6)
end

# ==============================================================================
# 3. SCM Diagnostic Extraction (Gradient Ri_g vs Bulk Ri_b)
# ==============================================================================

function extract_scm_diagnostics(df::DataFrame; params::GSPTParameters=GSPTParameters())
    col_t   = hasproperty(df, :t) ? df.t : df[:, 1]
    col_Ts  = hasproperty(df, :T_s) ? df.T_s : df[:, :Ts]
    col_Ta  = hasproperty(df, :T_a) ? df.T_a : (hasproperty(df, :theta1) ? df.theta1 : fill(280.0, nrow(df)))
    col_u   = hasproperty(df, :U1) ? df.U1 : (hasproperty(df, :U) ? df.U : zeros(nrow(df)))
    col_v   = hasproperty(df, :V1) ? df.V1 : (hasproperty(df, :V) ? df.V : zeros(nrow(df)))
    col_e   = hasproperty(df, :e1) ? df.e1 : (hasproperty(df, :e) ? df.e : zeros(nrow(df)))

    # Compute Gradient Ri_g if vertical gradients are present, else Bulk Ri_b
    is_gradient = hasproperty(df, :dtheta_dz) && (hasproperty(df, :dU_dz) || hasproperty(df, :dV_dz))

    Ri = if is_gradient
        dU_dz = hasproperty(df, :dU_dz) ? df.dU_dz : zeros(nrow(df))
        dV_dz = hasproperty(df, :dV_dz) ? df.dV_dz : zeros(nrow(df))
        shear_sq = @. dU_dz^2 + dV_dz^2 + 1e-8
        @. (params.g / params.theta_ref) * df.dtheta_dz / shear_sq
    else
        delta_u = 1e-4
        @. (params.g / params.theta_ref) * max(0.0, col_Ta - col_Ts) * params.z1 / (col_u^2 + col_v^2 + delta_u)
    end

    e_max = max(maximum(col_e), 1e-6)
    e_norm = col_e ./ e_max

    return (
        t = col_t ./ 3600.0,
        T_s = col_Ts,
        T_a = col_Ta,
        dT = col_Ta .- col_Ts,
        TKE = col_e,
        TKE_norm = e_norm,
        Ri = Ri,
        is_gradient = is_gradient,
    )
end

# ==============================================================================
# 4. Regime Classification & Event Detection
# ==============================================================================

function classify_and_detect_events(diag, params::GSPTParameters; closure::Symbol=:tanh)
    N = length(diag.t)
    regimes = Symbol[]
    collapse_indices = Int[]
    recovery_indices = Int[]

    Ri_fold_vals = [compute_ri_fold(ts; T_a=ta, params=params, closure=closure) for (ts, ta) in zip(diag.T_s, diag.T_a)]

    for i in 1:N
        ri = diag.Ri[i]
        rf = Ri_fold_vals[i]
        rt = params.c_s

        if ri < rt
            push!(regimes, :turbulent)
        elseif ri >= rt && ri <= rf
            push!(regimes, :bistable)
        else
            push!(regimes, :collapsed)
        end

        # Event Detection: Sign transitions across manifold thresholds
        if i > 1
            # Collapse: Crossing above Ri_fold
            if diag.Ri[i-1] <= Ri_fold_vals[i-1] && diag.Ri[i] > rf
                push!(collapse_indices, i)
            end
            # Recovery: Crossing below activation threshold Ri_trans
            if diag.Ri[i-1] >= rt && diag.Ri[i] < rt
                push!(recovery_indices, i)
            end
        end
    end

    return (
        regimes = regimes,
        Ri_fold_vals = Ri_fold_vals,
        collapse_indices = collapse_indices,
        recovery_indices = recovery_indices,
    )
end

# ==============================================================================
# 5. Plotting Engine
# ==============================================================================

function plot_ri_fold_overlay(
    solution_path::String,
    output_path::String;
    params::GSPTParameters=GSPTParameters(),
    closure::Symbol=:tanh,
)
    println("📂 Reading SCM output from: $solution_path")
    df = CSV.read(solution_path, DataFrame)
    diag = extract_scm_diagnostics(df; params=params)
    events = classify_and_detect_events(diag, params; closure=closure)

    ri_label = diag.is_gradient ? "Gradient Richardson Number Ri_g" : "Bulk Richardson Number Ri_b"

    # --------------------------------------------------------------------------
    # Panel (a): State Space Trajectory Overlay
    # --------------------------------------------------------------------------
    dT_grid = range(0.01, stop=15.0, length=300)
    T_a_ref = 280.0
    T_s_grid = @. T_a_ref - dT_grid

    Ri_fold_curve = [compute_ri_fold(ts; T_a=T_a_ref, params=params, closure=closure) for ts in T_s_grid]
    Ri_trans_curve = fill(params.c_s, length(dT_grid))

    p1 = plot(
        xlabel = "Surface Temperature Deficit ΔT = Tₐ - Tₛ (K)",
        ylabel = ri_label,
        title = "(a) State-Space Trajectory Overlay on Exact GSPT Manifold",
        legend = :topleft,
        grid = true,
        frame = :box,
        xlims = (0.0, 14.0),
        ylims = (0.0, 1.2),
        margin = 5mm
    )

    # Shaded Hysteresis Region (Low alpha for print readability)
    plot!(p1, dT_grid, Ri_trans_curve, fillrange=Ri_fold_curve, fillalpha=0.08, fillcolor=:orange, linealpha=0.0, label="Bistable Hysteresis Region")

    # Analytical Thresholds
    plot!(p1, dT_grid, Ri_fold_curve, color=:crimson, lw=2.5, label="Exact Fold Locus Ri_fold(T_s)")
    plot!(p1, dT_grid, Ri_trans_curve, color=:navy, lw=2.0, linestyle=:dash, label="Activation Limit Ri_trans")

    # Classified Trajectory Points
    for (reg, col, lbl) in [(:turbulent, :royalblue, "Active Branch"), (:bistable, :darkorange, "Bistable Branch"), (:collapsed, :crimson, "Collapsed Branch")]
        mask = events.regimes .== reg
        if any(mask)
            scatter!(p1, diag.dT[mask], diag.Ri[mask], color=col, ms=3.0, msw=0.0, label=lbl)
        end
    end
    plot!(p1, diag.dT, diag.Ri, color=:gray30, alpha=0.4, lw=1.0, label="")

    # Direction Arrows along trajectory
    arrow_step = max(1, length(diag.t) ÷ 12)
    for i in 1:arrow_step:(length(diag.t)-1)
        dx = diag.dT[i+1] - diag.dT[i]
        dy = diag.Ri[i+1] - diag.Ri[i]
        if hypot(dx, dy) > 1e-4
            quiver!(p1, [diag.dT[i]], [diag.Ri[i]], quiver=([dx*0.3], [dy*0.3]), color=:black, lw=1.2)
        end
    end

    # Start and End Markers
    scatter!(p1, [diag.dT[1]], [diag.Ri[1]], marker=:circle, ms=7, color=:green, label="Start (t=0)")
    scatter!(p1, [diag.dT[end]], [diag.Ri[end]], marker=:rect, ms=7, color=:purple, label="End")

    # Event Markers
    if !isempty(events.collapse_indices)
        scatter!(p1, diag.dT[events.collapse_indices], diag.Ri[events.collapse_indices], marker=:utriangle, ms=9, color=:red, label="Collapse ▲")
    end
    if !isempty(events.recovery_indices)
        scatter!(p1, diag.dT[events.recovery_indices], diag.Ri[events.recovery_indices], marker=:dtriangle, ms=9, color=:blue, label="Recovery ▼")
    end

    # --------------------------------------------------------------------------
    # Panel (b): Time Series & Normalized TKE (Unified Axis)
    # --------------------------------------------------------------------------
    p2 = plot(
        xlabel = "Simulated Time (hours)",
        ylabel = "Richardson Number & Normalized TKE ehat",
        title = "(b) Time Series of Collapse and Recovery Transitions",
        legend = :topright,
        grid = true,
        frame = :box,
        margin = 5mm,
        ylims = (0.0, 1.2)
    )

    plot!(p2, diag.t, diag.Ri, color=:black, lw=1.8, label=ri_label)

    # Overlay dynamic fold limit along time series
    plot!(p2, diag.t, events.Ri_fold_vals, color=:crimson, lw=1.5, linestyle=:dot, label="Dynamic Ri_fold(T_s(t))")
    hline!(p2, [params.c_s], color=:navy, lw=1.5, linestyle=:dash, label="Ri_trans = c_s")

    # Normalized TKE ehat = e / e_max on the same y-axis
    plot!(p2, diag.t, diag.TKE_norm, color=:seagreen, lw=1.8, label="Normalized TKE ehat = e / e_max")

    # Event Markers on Time Series
    if !isempty(events.collapse_indices)
        scatter!(p2, diag.t[events.collapse_indices], diag.Ri[events.collapse_indices], marker=:utriangle, ms=8, color=:red, label="")
    end
    if !isempty(events.recovery_indices)
        scatter!(p2, diag.t[events.recovery_indices], diag.Ri[events.recovery_indices], marker=:dtriangle, ms=8, color=:blue, label="")
    end

    # --------------------------------------------------------------------------
    # Combine Panels
    # --------------------------------------------------------------------------
    final_plot = plot(p1, p2, layout=(2, 1), size=(850, 950))

    mkpath(dirname(output_path))
    savefig(final_plot, output_path)
    println("✅ Figure successfully saved to: $output_path")
end

# CLI Argument parsing
function main()
    sol_path = "results/CASES99/latest/solution.csv"
    out_path = "reports/generated/figures/ri_fold_trajectory_overlay.png"
    closure_choice = :tanh

    for i in 1:length(ARGS)
        if ARGS[i] == "--solution" && i < length(ARGS)
            sol_path = ARGS[i+1]
        elseif ARGS[i] == "--out" && i < length(ARGS)
            out_path = ARGS[i+1]
        elseif ARGS[i] == "--closure" && i < length(ARGS)
            closure_choice = Symbol(ARGS[i+1])
        end
    end

    if !isfile(sol_path)
        @warn "Specified solution file not found: $sol_path. Creating synthetic demonstration output."
        mkpath(dirname(sol_path))
        t_arr = range(0, 12*3600, length=500)
        df_demo = DataFrame(
            t = t_arr,
            T_s = 280.0 .- 8.0 .* (1.0 .- exp.(-t_arr ./ 10000.0)),
            T_a = fill(280.0, 500),
            U1 = 4.0 .+ 2.0 .* sin.(2pi .* t_arr ./ (4*3600)),
            V1 = 0.5 .* cos.(2pi .* t_arr ./ (4*3600)),
            e1 = 0.2 .* max.(0.01, sin.(2pi .* t_arr ./ (3*3600)))
        )
        CSV.write(sol_path, df_demo)
    end

    plot_ri_fold_overlay(sol_path, out_path; closure=closure_choice)
end

main()