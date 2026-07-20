module TwoLayerGSPTModel

using ComponentArrays
using OrdinaryDiffEq
using StableBoundaryLayerGSPT.Geometry: compute_manifold_equilibrium

export default_parameters, default_initial_state, sbl_5d_system!, simulate_column, trajectory_geometry_summary, neutral_spinup_parameters, spinup_initial_state, simulate_column_with_spinup

function default_parameters(; Ug::Float64=8.0)
    return (
        ε = 0.01,
        σ = 1.0e-6,
        Δz = 50.0,
        f_cor = 1.0e-4,
        Ug = Ug,
        Vg = 0.0,
        g_over_θ0 = 9.81 / 273.15,
        γ_θ = 0.01,
        C_skin = 10000.0,
        R_down = 200.0,
        σ_SB = 5.67e-8,
        ρ_air = 1.2,
        cp = 1004.0,
        λ_s = 0.3,
        d_soil = 0.1,
        T_deep = 270.0,
        CD = 1.5e-3,
        CH = 1.5e-3,
        l_0 = 15.0,
        δ = 1.0e-4,
    )
end

function default_initial_state(; U1::Float64=4.0, V1::Float64=1.0, θ1::Float64=275.0, Ts::Float64=272.0, e1::Float64=0.5)
    return ComponentArray(U1=U1, V1=V1, θ1=θ1, Ts=Ts, e1=e1)
end

function sbl_5d_system!(dX, X, p, t)
    U1, V1, θ1, Ts, e1 = X.U1, X.V1, X.θ1, X.Ts, X.e1

    e_star = 0.5 * (e1 + sqrt(e1^2 + p.σ^2))
    vel_scale = sqrt(e_star + p.δ)
    K_m = p.l_0 * vel_scale
    K_h = p.l_0 * vel_scale

    τ_x_top = -K_m * (p.Ug - U1) / p.Δz
    τ_y_top = -K_m * (p.Vg - V1) / p.Δz
    τ_x_sfc = -p.CD * vel_scale * U1
    τ_y_sfc = -p.CD * vel_scale * V1

    H_top = -K_h * p.γ_θ
    H_sfc = -p.CH * vel_scale * (θ1 - Ts)

    dX.U1 = p.f_cor * (V1 - p.Vg) - (τ_x_top - τ_x_sfc) / p.Δz
    dX.V1 = -p.f_cor * (U1 - p.Ug) - (τ_y_top - τ_y_sfc) / p.Δz
    dX.θ1 = - (H_top - H_sfc) / p.Δz

    sensible_heat_flux = p.ρ_air * p.cp * H_sfc
    ground_heat_flux = p.λ_s * (Ts - p.T_deep) / p.d_soil
    dX.Ts = (1.0 / p.C_skin) * (p.R_down - p.σ_SB * Ts^4 - sensible_heat_flux - ground_heat_flux)

    S_sq = ((p.Ug - U1) / p.Δz)^2 + ((p.Vg - V1) / p.Δz)^2
    N_sq = p.g_over_θ0 * (θ1 - Ts) / p.Δz
    P = K_m * S_sq
    B = K_h * N_sq
    D = (e_star + p.δ)^(1.5) / p.l_0

    dX.e1 = (1.0 / p.ε) * (P - B - D)

    return nothing
end

function _nonnegative_tke_callback()
    condition(u, t, integrator) = u.e1
    affect!(integrator) = (integrator.u.e1 = 0.0)
    return ContinuousCallback(condition, affect!; rootfind=true, save_positions=(true, true))
end

function neutral_spinup_parameters(parameters)
    return merge(parameters, (
        γ_θ = 0.0,
        R_down = 0.0,
        λ_s = 0.0,
        CH = 0.0,
        C_skin = Inf,
    ))
end

function spinup_initial_state(initial_state, parameters; force_fractional_init::Bool=false)
    state0 = copy(initial_state)
    state0.e1 = max(state0.e1, 0.0)
    state0.Ts = state0.θ1

    if force_fractional_init
        state0.U1 = 0.7 * parameters.Ug
    end

    return state0
end

function simulate_column(parameters, initial_state, tspan; saveat=300.0, reltol=1e-6, abstol=1e-8)
    state0 = copy(initial_state)
    if state0.e1 < 0.0
        state0.e1 = 0.0
    end

    prob = ODEProblem(sbl_5d_system!, state0, tspan, parameters)
    callback = _nonnegative_tke_callback()
    return solve(prob, Rosenbrock23(), reltol=reltol, abstol=abstol, saveat=saveat, callback=callback)
end

function simulate_column_with_spinup(
    parameters,
    initial_state,
    spinup_hours::Real,
    final_hours::Real;
    saveat=300.0,
    reltol=1e-6,
    abstol=1e-8,
    force_fractional_init::Bool=false,
)
    spinup_duration = max(Float64(spinup_hours), 0.0)
    final_duration = max(Float64(final_hours), 0.0)

    spinup_state = spinup_initial_state(initial_state, parameters; force_fractional_init=force_fractional_init)
    spinup_parameters = neutral_spinup_parameters(parameters)

    spinup_solution = simulate_column(
        spinup_parameters,
        spinup_state,
        (0.0, spinup_duration * 3600.0);
        saveat=saveat,
        reltol=reltol,
        abstol=abstol,
    )

    post_spinup_state = copy(spinup_solution.u[end])
    post_spinup_state.e1 = max(post_spinup_state.e1, 0.0)

    main_solution = simulate_column(
        parameters,
        post_spinup_state,
        (0.0, final_duration * 3600.0);
        saveat=saveat,
        reltol=reltol,
        abstol=abstol,
    )

    return (
        spinup=spinup_solution,
        main=main_solution,
        spinup_state=spinup_state,
        post_spinup_state=post_spinup_state,
    )
end

function trajectory_geometry_summary(sol, parameters)
    e_eq_history = Float64[]
    fold_history = Float64[]
    residual_history = Float64[]
    thermal_inversion_history = Float64[]

    sizehint!(e_eq_history, length(sol.u))
    sizehint!(fold_history, length(sol.u))
    sizehint!(residual_history, length(sol.u))
    sizehint!(thermal_inversion_history, length(sol.u))

    for u in sol.u
        slow_state = (U1=u.U1, V1=u.V1, θ1=u.θ1, Ts=u.Ts)
        geom = compute_manifold_equilibrium(slow_state, parameters; e_guess=max(u.e1, 0.0))
        push!(e_eq_history, geom.e_eq)
        push!(fold_history, geom.fold_diagnostic)
        push!(residual_history, geom.residual)
        push!(thermal_inversion_history, geom.thermal_inversion)
    end

    return (
        e_eq_history=e_eq_history,
        fold_history=fold_history,
        residual_history=residual_history,
        thermal_inversion_history=thermal_inversion_history,
    )
end

end