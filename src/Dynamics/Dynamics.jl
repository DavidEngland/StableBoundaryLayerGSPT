module Dynamics

using OrdinaryDiffEq: ODEProblem, solve, Rodas5P, Rosenbrock23

export integrate_system
export default_4d_parameters
export closure_coefficients
export stratification_function
export fast_vector_field_F
export solve_4d_sbl
export solution_to_rows
export diagnostic_diffusivity_floors

const _DEFAULT_SMOOTH_EPS = 1.0e-8

"""Return baseline parameters for the 4D GSPT-SBL system."""
function default_4d_parameters()
    return Dict{String,Float64}(
        # Environmental controls and geostrophic forcing.
        "U_g" => 10.0,
        "V_g" => 0.0,
        "T_a" => 285.15,
        "T_deep" => 283.15,
        "R_down" => 260.0,
        "f_coriolis" => 1.0e-4,
        # Fast-slow and turbulence controls.
        "epsilon" => 0.01,
        "delta" => 1.0e-4,
        "K" => 0.32,
        "beta" => 15.0,
        "h" => 50.0,
        # Roughness and dissipation controls.
        "kappa" => 0.40,
        "z0m" => 0.05,
        "z0h" => 0.01,
        "l0" => 15.0,
        "gamma_efficiency" => 2.0,
        "shear_production_efficiency" => 15.0,
        # Thermal properties.
        "sigma_sb" => 5.67e-8,
        "lambda_soil" => 1.2,
        "d_soil" => 0.5,
        "rho_cp" => 1200.0,
        "C_skin" => 2.0e4,
        # Smooth positivity helper for e + delta.
        "smooth_eps" => _DEFAULT_SMOOTH_EPS,
    )
end

"""Compute drag and heat-exchange coefficients from roughness lengths."""
function closure_coefficients(p::AbstractDict{String,<:Real})
    kappa = Float64(p["kappa"])
    h = Float64(p["h"])
    z0m = Float64(p["z0m"])
    z0h = Float64(p["z0h"])
    gamma_efficiency = Float64(get(p, "gamma_efficiency", 1.0))

    log_m = log(h / z0m)
    log_h = log(h / z0h)
    C_H = kappa^2 / (log_m * log_h)
    gamma = gamma_efficiency * (kappa^2 / (log_m^2)) / h
    return gamma, C_H
end

"""Smooth C-infinity stratification closure G(Ts)."""
function stratification_function(Ts::Real, Ta::Real, beta::Real)
    return exp(beta * (Ta - Ts) / Ta) - 1.0
end

function _regularized_positive(x::Real, eps_pos::Real)
    # Numerical floor keeps turbulent closures strictly positive near laminar branch.
    return max(x, eps_pos)
end

"""
Energy-conserving fast vector field F(e, U, V, Ts) with drag-coupled production.

F = sqrt(e + delta) * [gamma * (U^2 + V^2) - K * G(Ts)] - (e + delta)^(3/2) / l0
"""
function fast_vector_field_F(e::Real, U::Real, V::Real, Ts::Real, p::AbstractDict{String,<:Real})
    delta = Float64(p["delta"])
    K = Float64(p["K"])
    l0 = Float64(p["l0"])
    Ta = Float64(p["T_a"])
    beta = Float64(p["beta"])
    eps_pos = Float64(get(p, "smooth_eps", _DEFAULT_SMOOTH_EPS))
    shear_eff = Float64(get(p, "shear_production_efficiency", 1.0))

    gamma, _ = closure_coefficients(p)
    G = stratification_function(Ts, Ta, beta)
    e_plus = _regularized_positive(e + delta, eps_pos)
    sqrt_e = sqrt(e_plus)

    production_minus_buoyancy = shear_eff * gamma * (U * U + V * V) - K * G
    dissipation = (e_plus^(1.5)) / l0
    return sqrt_e * production_minus_buoyancy - dissipation
end

function _rhs_4d!(du, u, p, t)
    e, U, V, Ts = u

    epsilon = Float64(p["epsilon"])
    Ug = Float64(p["U_g"])
    Vg = Float64(p["V_g"])
    f_coriolis = Float64(p["f_coriolis"])
    delta = Float64(p["delta"])
    Ta = Float64(p["T_a"])
    Tdeep = Float64(p["T_deep"])
    Rdown = Float64(p["R_down"])
    sigma_sb = Float64(p["sigma_sb"])
    lambda_soil = Float64(p["lambda_soil"])
    d_soil = Float64(p["d_soil"])
    rho_cp = Float64(p["rho_cp"])
    C_skin = Float64(p["C_skin"])
    eps_pos = Float64(get(p, "smooth_eps", _DEFAULT_SMOOTH_EPS))

    gamma, C_H = closure_coefficients(p)
    e_plus = _regularized_positive(e + delta, eps_pos)
    sqrt_e = sqrt(e_plus)

    F = fast_vector_field_F(e, U, V, Ts, p)

    de_dt = F / epsilon
    e_floor = -delta + eps_pos
    if (e <= e_floor) && (de_dt < 0.0)
        de_dt = 0.0
    end

    du[1] = de_dt
    du[2] = f_coriolis * (V - Vg) - gamma * sqrt_e * U
    du[3] = -f_coriolis * (U - Ug) - gamma * sqrt_e * V
    du[4] = (
        Rdown - sigma_sb * Ts^4 - lambda_soil * (Ts - Tdeep) / d_soil +
        rho_cp * C_H * sqrt_e * (Ta - Ts)
    ) / C_skin

    return nothing
end

"""Solve the 4D GSPT-SBL ODE with stiff integration."""
function solve_4d_sbl(
    ;
    parameters::AbstractDict{String,<:Real}=default_4d_parameters(),
    u0::AbstractVector{<:Real}=[1.0, 5.0, 0.0, 285.15],
    tspan::Tuple{<:Real,<:Real}=(0.0, 14.0 * 3600.0),
    solver::Symbol=:rodas5p,
    saveat::Real=30.0,
    abstol::Real=1.0e-8,
    reltol::Real=1.0e-6,
)
    params = Dict{String,Float64}(k => Float64(v) for (k, v) in parameters)
    prob = ODEProblem(_rhs_4d!, collect(Float64, u0), (Float64(tspan[1]), Float64(tspan[2])), params)

    alg = if solver == :rosenbrock23
        Rosenbrock23()
    else
        Rodas5P()
    end

    return solve(prob, alg; saveat=Float64(saveat), abstol=Float64(abstol), reltol=Float64(reltol))
end

"""Convert ODE solution into NamedTuple rows with derived diagnostics."""
function solution_to_rows(sol, parameters::AbstractDict{String,<:Real})
    p = Dict{String,Float64}(k => Float64(v) for (k, v) in parameters)
    gamma, C_H = closure_coefficients(p)
    delta = p["delta"]
    Ta = p["T_a"]
    beta = p["beta"]
    eps_pos = Float64(get(p, "smooth_eps", _DEFAULT_SMOOTH_EPS))

    rows = NamedTuple[]
    for i in eachindex(sol.t)
        t = sol.t[i]
        e = sol.u[i][1]
        U = sol.u[i][2]
        V = sol.u[i][3]
        Ts = sol.u[i][4]

        e_plus = _regularized_positive(e + delta, eps_pos)
        sqrt_e = sqrt(e_plus)
        G = stratification_function(Ts, Ta, beta)
        Delta = gamma * (U * U + V * V) - p["K"] * G

        Km = gamma * sqrt_e
        Kh = C_H * sqrt_e

        push!(rows, (; t, e, U, V, Ts, Delta, Km, Kh))
    end
    return rows
end

"""Return lower-bound diffusivity floors implied by delta regularization."""
function diagnostic_diffusivity_floors(parameters::AbstractDict{String,<:Real})
    p = Dict{String,Float64}(k => Float64(v) for (k, v) in parameters)
    gamma, C_H = closure_coefficients(p)
    floor_scale = sqrt(p["delta"])
    return Dict(
        "Km_floor" => gamma * floor_scale,
        "Kh_floor" => C_H * floor_scale,
        "gamma" => gamma,
        "C_H" => C_H,
    )
end

"""Integrate a placeholder fast-slow system for pipeline scaffolding."""
function integrate_system(parameters::AbstractDict{String,<:Any})
    nsteps = Int(get(parameters, "nsteps", 10))
    dt = Float64(get(parameters, "dt", 60.0))
    base_tke = Float64(get(parameters, "tke0", 0.2))
    base_ri = Float64(get(parameters, "ri0", 0.05))

    states = NamedTuple[]
    for k in 0:nsteps
        t = k * dt
        ri = base_ri + 0.01 * sin(0.2 * k)
        tke = max(1e-6, base_tke * exp(-0.01 * k) + 0.02 * cos(0.3 * k))
        push!(states, (; t, ri, tke, z=10.0))
    end
    return states
end

end