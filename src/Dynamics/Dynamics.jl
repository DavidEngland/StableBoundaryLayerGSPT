module Dynamics

include(joinpath(@__DIR__, "..", "Config", "CaseDefaults.jl"))

using OrdinaryDiffEq: ODEProblem, solve, Rodas5P, Rosenbrock23
using .CaseDefaults: get_case_ts_min

export integrate_system
export default_4d_parameters
export closure_coefficients
export effective_h_scale
export stratification_function
export hyperbolic_embedding_e
export fast_vector_field_F
export solve_4d_sbl
export solution_to_rows
export diagnostic_diffusivity_floors

const _DEFAULT_SMOOTH_EPS = 1.0e-8

function _require_kelvin_temperature(value::Real, label::AbstractString; floor::Float64=100.0)
    temp = Float64(value)
    isfinite(temp) || error("$(label) must be finite Kelvin, got $(value)")
    temp >= floor || error("$(label)=$(temp) K looks like a missing Kelvin offset or sign error")
    return temp
end

"""Return baseline parameters for the 4D GSPT-SBL system."""
function default_4d_parameters(; case_name::Union{Symbol,AbstractString}=:midlat)
    ts_min_default = get_case_ts_min(case_name)
    return Dict{String,Float64}(
        # Environmental controls and geostrophic forcing.
        "U_g" => 10.0,
        "V_g" => 0.0,
        "T_a" => 285.15,
        "theta_top" => 285.15,
        "alpha_air" => 0.85,
        "T_deep" => 283.15,
        "R_down" => 260.0,
        "f_coriolis" => 1.0e-4,
        # Fast-slow and turbulence controls.
        "epsilon" => 0.01,
        "delta" => 1.0e-4,
        "K" => 0.32,
        "beta" => 15.0,
        "h" => 50.0,
        # Optional non-local scaling controls for h (disabled by default).
        "use_nonlocal_h" => 0.0,
        "nonlocal_h_weight" => 0.5,
        "nonlocal_h_min" => 20.0,
        "nonlocal_h_max" => 400.0,
        "nonlocal_velocity_floor" => 0.1,
        "nonlocal_f_floor" => 1.0e-5,
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
        # Saturation cap for bounded stability response.
        "g_stability_max" => 1.0,
        # Physical safeguards for surface temperature and smooth floor handling.
        "ts_min" => ts_min_default,
        "ts_max" => 350.0,
        "ts_floor_transition" => 1.0e-3,
        # C-infinity embedding width for reduced-branch diagnostics.
        "xi" => 1.0e-5,
        # Width for smoothly transitioning to the e floor limiter.
        "e_floor_transition" => 1.0e-5,
        # Smoothness for approximating min(de_dt, 0) near the floor.
        "de_floor_smooth_eps" => 1.0e-10,
    )
end

"""Return effective h for local or optional non-local scaling."""
function effective_h_scale(
    p::AbstractDict{String,<:Real};
    U::Union{Nothing,Real}=nothing,
    V::Union{Nothing,Real}=nothing,
)
    h_local = Float64(p["h"])
    use_nonlocal = Float64(get(p, "use_nonlocal_h", 0.0)) > 0.5
    if !use_nonlocal || isnothing(U) || isnothing(V)
        return h_local
    end

    weight = clamp(Float64(get(p, "nonlocal_h_weight", 0.5)), 0.0, 1.0)
    h_min = Float64(get(p, "nonlocal_h_min", 20.0))
    h_max = Float64(get(p, "nonlocal_h_max", 400.0))
    u_floor = Float64(get(p, "nonlocal_velocity_floor", 0.1))
    f_floor = Float64(get(p, "nonlocal_f_floor", 1.0e-5))

    speed = max(hypot(Float64(U), Float64(V)), u_floor)
    f_eff = max(abs(Float64(p["f_coriolis"])), f_floor)
    h_nonlocal = clamp(speed / f_eff, h_min, h_max)
    return (1.0 - weight) * h_local + weight * h_nonlocal
end

"""Compute drag and heat-exchange coefficients from roughness lengths."""
function closure_coefficients(
    p::AbstractDict{String,<:Real};
    U::Union{Nothing,Real}=nothing,
    V::Union{Nothing,Real}=nothing,
)
    kappa = Float64(p["kappa"])
    h = effective_h_scale(p; U=U, V=V)
    z0m = Float64(p["z0m"])
    z0h = Float64(p["z0h"])
    gamma_efficiency = Float64(get(p, "gamma_efficiency", 1.0))

    log_m = log(h / z0m)
    log_h = log(h / z0h)
    C_H = kappa^2 / (log_m * log_h)
    gamma = gamma_efficiency * (kappa^2 / (log_m^2)) / h
    return gamma, C_H
end

"""Bounded C-infinity stratification closure G(Ts)."""
function stratification_function(Ts::Real, Ta::Real, beta::Real)
    arg = beta * (Ta - Ts) / Ta
    return tanh(arg)
end

function _bounded_stability_response(Ts::Real, Ta::Real, beta::Real, g_stability_max::Real)
    g_cap = max(Float64(g_stability_max), 1.0e-12)
    arg = beta * (Ta - Ts) / Ta
    return g_cap * tanh(arg)
end

function _smooth_max(a::Real, b::Real, eps_smooth::Real)
    T = promote_type(typeof(a), typeof(b), typeof(eps_smooth))
    aT = convert(T, a)
    bT = convert(T, b)
    eps_local = max(convert(T, eps_smooth), eps(T))
    d = aT - bT
    return convert(T, 0.5) * (aT + bT + sqrt(d * d + eps_local * eps_local))
end

function _smooth_min(a::Real, b::Real, eps_smooth::Real)
    T = promote_type(typeof(a), typeof(b), typeof(eps_smooth))
    aT = convert(T, a)
    bT = convert(T, b)
    eps_local = max(convert(T, eps_smooth), eps(T))
    d = aT - bT
    return convert(T, 0.5) * (aT + bT - sqrt(d * d + eps_local * eps_local))
end

function _production_minus_buoyancy(
    U::Real,
    V::Real,
    Ts::Real,
    p::AbstractDict{String,<:Real};
    gamma_override::Union{Nothing,Real}=nothing,
)
    K = Float64(p["K"])
    Ta = Float64(p["T_a"])
    beta = Float64(p["beta"])
    g_stability_max = Float64(get(p, "g_stability_max", 1.0))
    shear_eff = Float64(get(p, "shear_production_efficiency", 1.0))

    gamma = isnothing(gamma_override) ? closure_coefficients(p)[1] : Float64(gamma_override)
    G = _bounded_stability_response(Ts, Ta, beta, g_stability_max)
    return shear_eff * gamma * (U * U + V * V) - K * G
end

"""
    hyperbolic_embedding_e(Delta, p)

Return the C-infinity embedded reduced-branch equilibrium

    e*_xi = 0.5 * (e_raw + sqrt(e_raw^2 + xi^2))

where `e_raw = l0 * Delta - delta`.
"""
function hyperbolic_embedding_e(Delta::Real, p::AbstractDict{String,<:Real})
    l0 = Float64(p["l0"])
    delta = Float64(p["delta"])
    xi = Float64(get(p, "xi", 1.0e-5))
    e_raw = l0 * Float64(Delta) - delta
    return 0.5 * (e_raw + sqrt(e_raw * e_raw + xi * xi))
end

function _regularized_positive(x::Real, eps_pos::Real)
    # Numerical floor keeps turbulent closures strictly positive near laminar branch.
    return max(x, eps_pos)
end

function _smooth_min_zero(x::Real, eps_smooth::Real)
    eps_local = max(Float64(eps_smooth), eps(Float64))
    return 0.5 * (x - sqrt(x * x + eps_local * eps_local))
end

function _smooth_floor_gate(e::Real, e_floor::Real, transition::Real)
    width = max(Float64(transition), eps(Float64))
    return 0.5 * (1.0 + tanh((e - e_floor) / width))
end

"""
Energy-conserving fast vector field F(e, U, V, Ts) with drag-coupled production.

F = sqrt(e + delta) * [gamma * (U^2 + V^2) - K * G(Ts)] - (e + delta)^(3/2) / l0
"""
function fast_vector_field_F(
    e::Real,
    U::Real,
    V::Real,
    Ts::Real,
    p::AbstractDict{String,<:Real};
    gamma_override::Union{Nothing,Real}=nothing,
)
    delta = Float64(p["delta"])
    l0 = Float64(p["l0"])
    eps_pos = Float64(get(p, "smooth_eps", _DEFAULT_SMOOTH_EPS))

    gamma = isnothing(gamma_override) ? closure_coefficients(p)[1] : Float64(gamma_override)
    e_plus = _regularized_positive(e + delta, eps_pos)
    sqrt_e = sqrt(e_plus)

    production_minus_buoyancy = _production_minus_buoyancy(U, V, Ts, p; gamma_override=gamma)
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
    theta_top = Float64(get(p, "theta_top", Ta))
    alpha_air = clamp(Float64(get(p, "alpha_air", 0.85)), 0.0, 1.0)
    Tdeep = Float64(p["T_deep"])
    Rdown = Float64(p["R_down"])
    sigma_sb = Float64(p["sigma_sb"])
    lambda_soil = Float64(p["lambda_soil"])
    d_soil = Float64(p["d_soil"])
    rho_cp = Float64(p["rho_cp"])
    C_skin = Float64(p["C_skin"])
    Ts_min = Float64(get(p, "ts_min", 220.0))
    Ts_max = Float64(get(p, "ts_max", 350.0))
    ts_floor_transition = Float64(get(p, "ts_floor_transition", 1.0e-3))
    eps_pos = Float64(get(p, "smooth_eps", _DEFAULT_SMOOTH_EPS))
    e_floor_transition = Float64(get(p, "e_floor_transition", 1.0e-5))
    de_floor_smooth_eps = Float64(get(p, "de_floor_smooth_eps", 1.0e-10))

    Ts_floor = _smooth_max(Ts, Ts_min, ts_floor_transition)
    Ts_eff = _smooth_min(Ts_floor, Ts_max, ts_floor_transition)

    gamma, C_H = closure_coefficients(p; U=U, V=V)
    e_plus = _regularized_positive(e + delta, eps_pos)
    sqrt_e = sqrt(e_plus)

    F = fast_vector_field_F(e, U, V, Ts_eff, p; gamma_override=gamma)

    de_dt_raw = F / epsilon
    e_floor = -delta + eps_pos
    gate = _smooth_floor_gate(e, e_floor, e_floor_transition)
    negative_part = _smooth_min_zero(de_dt_raw, de_floor_smooth_eps)
    de_dt = de_dt_raw - (1.0 - gate) * negative_part

    du[1] = de_dt
    du[2] = f_coriolis * (V - Vg) - gamma * sqrt_e * U
    du[3] = -f_coriolis * (U - Ug) - gamma * sqrt_e * V
    theta_air_eff = muladd(alpha_air, Ts_eff, (1.0 - alpha_air) * theta_top)
    Rn = Rdown - sigma_sb * Ts_eff^4
    Gflux = lambda_soil * (Ts_eff - Tdeep) / d_soil
    H = rho_cp * C_H * sqrt_e * (Ts_eff - theta_air_eff)
    du[4] = (Rn - H - Gflux) / C_skin

    return nothing
end

"""Solve the 4D GSPT-SBL ODE with stiff integration."""
function solve_4d_sbl(
    ;
    parameters::Union{Nothing,AbstractDict{String,<:Real}}=nothing,
    u0::AbstractVector{<:Real}=[1.0, 5.0, 0.0, 285.15],
    tspan::Tuple{<:Real,<:Real}=(0.0, 14.0 * 3600.0),
    solver::Symbol=:rodas5p,
    saveat::Real=30.0,
    abstol::Real=1.0e-8,
    reltol::Real=1.0e-6,
    case_name::Union{Symbol,AbstractString}=:midlat,
)
    params_source = isnothing(parameters) ? default_4d_parameters(case_name=case_name) : parameters
    params = Dict{String,Float64}(k => Float64(v) for (k, v) in params_source)

    _require_kelvin_temperature(get(params, "T_a", 0.0), "T_a")
    _require_kelvin_temperature(get(params, "T_deep", 0.0), "T_deep")
    _require_kelvin_temperature(get(params, "theta_top", get(params, "T_a", 0.0)), "theta_top")
    _require_kelvin_temperature(u0[4], "Ts0")

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

        gamma, C_H = closure_coefficients(p; U=U, V=V)

        e_plus = _regularized_positive(e + delta, eps_pos)
        sqrt_e = sqrt(e_plus)
        Delta = _production_minus_buoyancy(U, V, Ts, p; gamma_override=gamma)
        e_star_smooth = hyperbolic_embedding_e(Delta, p)
        sqrt_e_star = sqrt(_regularized_positive(e_star_smooth + delta, eps_pos))

        Km = gamma * sqrt_e
        Kh = C_H * sqrt_e
        Km_star = gamma * sqrt_e_star
        Kh_star = C_H * sqrt_e_star

        push!(rows, (; t, e, U, V, Ts, Delta, e_star_smooth, Km, Kh, Km_star, Kh_star))
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