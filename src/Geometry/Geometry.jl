module Geometry

using ForwardDiff

export critical_manifold, compute_manifold_equilibrium, fast_manifold_residual

"""Return the legacy critical-manifold estimate from diagnostic state variables."""
function critical_manifold(state::NamedTuple)
    ri = Float64(get(state, :ri, 0.0))
    tke = Float64(get(state, :tke, 0.0))
    z = Float64(get(state, :z, 10.0))
    manifold_value = tke / (1 + abs(ri))
    return (; z, manifold_value)
end

"""Evaluate the scalar fast-equation residual for a fixed slow state."""
function fast_manifold_residual(slow_state, p, e1)
    U1 = Float64(getproperty(slow_state, :U1))
    V1 = Float64(getproperty(slow_state, :V1))
    θ1 = Float64(getproperty(slow_state, :θ1))
    Ts = Float64(getproperty(slow_state, :Ts))

    e_star = 0.5 * (e1 + sqrt(e1^2 + p.σ^2))
    vel_scale = sqrt(e_star + p.δ)

    K_m = p.l_0 * vel_scale
    K_h = p.l_0 * vel_scale

    S_sq = ((p.Ug - U1) / p.Δz)^2 + ((p.Vg - V1) / p.Δz)^2
    N_sq = p.g_over_θ0 * (θ1 - Ts) / p.Δz

    P = K_m * S_sq
    B = K_h * N_sq
    D = (e_star + p.δ)^(1.5) / p.l_0

    return P - B - D
end

"""
    compute_manifold_equilibrium(slow_state, p; e_guess=0.4, max_iter=20, tol=1e-8)

Solve the scalar fast equilibrium on the critical manifold for a fixed slow state.
Returns `(e_eq, fold_diagnostic, residual, converged, iterations)`.
"""
function compute_manifold_equilibrium(slow_state, p; e_guess=0.4, max_iter=20, tol=1e-8)
    U1 = Float64(getproperty(slow_state, :U1))
    V1 = Float64(getproperty(slow_state, :V1))
    θ1 = Float64(getproperty(slow_state, :θ1))
    Ts = Float64(getproperty(slow_state, :Ts))

    S_sq = ((p.Ug - U1) / p.Δz)^2 + ((p.Vg - V1) / p.Δz)^2
    N_sq = p.g_over_θ0 * (θ1 - Ts) / p.Δz
    physics_guess = max(p.l_0^2 * max(S_sq - N_sq, 0.0) - p.δ, 0.0)

    e_eq = max(Float64(e_guess), physics_guess)
    converged = false
    iteration_count = 0

    for iteration in 1:max_iter
        residual = fast_manifold_residual(slow_state, p, e_eq)
        derivative = ForwardDiff.derivative(e -> fast_manifold_residual(slow_state, p, e), e_eq)

        if abs(derivative) < 1e-12
            iteration_count = iteration
            break
        end

        step = residual / derivative
        damping = 1.0
        candidate = e_eq

        while damping >= 1.0 / 1024.0
            candidate = max(e_eq - damping * step, 0.0)
            candidate_residual = abs(fast_manifold_residual(slow_state, p, candidate))

            if candidate_residual <= abs(residual)
                break
            end

            damping *= 0.5
        end

        e_eq = candidate
        iteration_count = iteration

        if abs(step) < tol
            converged = true
            break
        end
    end

    residual = fast_manifold_residual(slow_state, p, e_eq)
    fold_diagnostic = ForwardDiff.derivative(e -> fast_manifold_residual(slow_state, p, e), e_eq)
    thermal_inversion = θ1 - Ts

    return (; e_eq, fold_diagnostic, residual, converged, iterations = iteration_count, S_sq, N_sq, thermal_inversion, physics_guess)
end

end