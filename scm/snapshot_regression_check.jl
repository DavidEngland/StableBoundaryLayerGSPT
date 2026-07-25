#!/usr/bin/env julia
# scm/snapshot_regression_check.jl
# Targeted single-snapshot regression check between solver-kernel closure values
# and offline diagnostics outputs.

using Printf
import JLD2

include(joinpath(@__DIR__, "scm.jl"))
include(joinpath(@__DIR__, "scm_diagnostics.jl"))

# Mirror payload structs so JLD2 can deserialize cleanly.
mutable struct SCMWorkspace{T}
    Km::Vector{T}
    Kh::Vector{T}
end

struct SCMParameters{T,W}
    N::Int
    dz::T
    z_centers::Vector{T}
    z_faces::Vector{T}
    f::T
    Ug::T
    Vg::T
    theta_a::T
    T_deep::T
    delta::T
    K_buoy::T
    beta::T
    l_0::T
    eta::T
    xi::T
    C_skin::T
    R_down::T
    lambda_s::T
    d_soil::T
    h::T
    use_nonlocal_h::T
    nonlocal_h_weight::T
    nonlocal_h_min::T
    nonlocal_h_max::T
    nonlocal_velocity_floor::T
    nonlocal_f_floor::T
    z0m::T
    z0h::T
    k_min_surf::T
    pr_t_base::T
    pr_t_slope::T
    use_dynamic_pr_t::Bool
    g_stability_max::T
    k_exchange_min::T
    ell_min_surf::T
    use_ell_floor_surf::Bool
    ts_min::T
    ts_max::T
    theta_top_bc::Symbol
    theta_top::T
    lambda_top::T
    debug_print::Bool
    profile_every::T
    workspace::W
end

function _usage()
    println("Usage: julia scm/snapshot_regression_check.jl --input <payload.jld2> [options]")
    println("Options:")
    println("  --input <path>       Input payload JLD2 (required)")
    println("  --index <i>          1-based snapshot index (default: last)")
    println("  --tol <value>        Absolute tolerance for all checks (default: 1e-12)")
    println("  --help               Show this help message")
end

function parse_args(args::Vector{String})
    cfg = Dict{String,Any}(
        "input" => "",
        "index" => 0,
        "tol" => 1.0e-12,
    )

    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--help"
            _usage()
            exit(0)
        elseif a == "--input" && i < length(args)
            cfg["input"] = args[i + 1]
            i += 2
        elseif a == "--index" && i < length(args)
            cfg["index"] = parse(Int, args[i + 1])
            i += 2
        elseif a == "--tol" && i < length(args)
            cfg["tol"] = parse(Float64, args[i + 1])
            i += 2
        else
            error("Unknown or incomplete argument: $(a). Use --help for options.")
        end
    end

    cfg["input"] == "" && error("--input is required")
    return cfg
end

function compute_solver_delta_faces(X, p)
    T = eltype(X)
    N = p.N
    dz = p.dz
    z_faces = p.z_faces

    U = @view X[2:(N + 1)]
    V = @view X[(N + 2):(2N + 1)]
    theta = @view X[(2N + 2):(3N + 1)]

    theta_a = p.theta_a
    K_buoy = p.K_buoy
    l_0 = p.l_0
    eta = p.eta
    beta_stab = hasproperty(p, :beta_stab) ? convert(T, p.beta_stab) : convert(T, 5.0)
    g_stability_max = hasproperty(p, :g_stability_max) ? convert(T, p.g_stability_max) : one(T)
    ell_min_interior = hasproperty(p, :ell_min_interior) ? convert(T, p.ell_min_interior) : convert(T, 1.0e-2)
    kappa = convert(T, 0.4)

    delta_faces = zeros(T, N - 1)

    @inbounds for i in 1:(N - 1)
        dU_dz = (U[i + 1] - U[i]) / dz
        dV_dz = (V[i + 1] - V[i]) / dz
        dth_dz = (theta[i + 1] - theta[i]) / dz

        z_face = z_faces[i + 1]
        ell_neutral = (kappa * z_face) / (one(T) + (kappa * z_face) / l_0)
        U_face = convert(T, 0.5) * (U[i] + U[i + 1])
        V_face = convert(T, 0.5) * (V[i] + V[i + 1])
        h_eff = _effective_h_scale(p, U_face, V_face)
        ell_raw = ell_neutral * exp(-z_face / h_eff)
        ell_z = sqrt(ell_raw^2 + ell_min_interior^2)

        stability_arg = clamp(beta_stab * dth_dz * ell_z / theta_a, convert(T, -40.0), convert(T, 40.0))
        G_local = _bounded_stability_response(stability_arg, g_stability_max)

        S2_local = dU_dz^2 + dV_dz^2
        delta_faces[i] = eta * S2_local - K_buoy * G_local
    end

    return delta_faces
end

function compute_solver_surface_h_downward(X, p)
    T = eltype(X)
    N = p.N
    T_s = X[1]
    U = @view X[2:(N + 1)]
    V = @view X[(N + 2):(2N + 1)]
    theta = @view X[(2N + 2):(3N + 1)]

    kappa = convert(T, 0.4)
    rho_cp = convert(T, 1200.0)
    z0m = max(convert(T, p.z0m), eps(T))
    z0h = max(convert(T, p.z0h), eps(T))
    ratio_floor = convert(T, 1.05)
    h_eff_surf = _effective_h_scale(p, U[1], V[1])
    h_ref_surf = max(h_eff_surf, max(z0m, z0h) * ratio_floor)
    log_m = log(max(h_ref_surf / z0m, ratio_floor))
    log_h = log(max(h_ref_surf / z0h, ratio_floor))
    C_H_surf = (kappa * kappa) / max(log_m * log_h, eps(T))
    wind_surf = hypot(U[1], V[1])

    H_upward = rho_cp * C_H_surf * wind_surf * (T_s - theta[1])
    return -H_upward
end

function check_snapshot(payload_path::String, idx::Int, tol::Float64)
    isfile(payload_path) || error("Payload not found: $(payload_path)")
    data = JLD2.load(payload_path)

    states = data["states"]
    times = data["times"]
    p = data["p"]

    ns = length(states)
    ns == length(times) || error("Payload states/times length mismatch")
    ns > 0 || error("Payload contains no states")

    idx_eff = idx <= 0 ? ns : idx
    (1 <= idx_eff <= ns) || error("--index=$(idx_eff) out of range 1:$(ns)")

    X = states[idx_eff]
    t = times[idx_eff]

    dX = zeros(eltype(X), length(X))
    scm_gspt_tendencies!(dX, X, p, t)

    solver_km = copy(p.workspace.Km)
    solver_kh = copy(p.workspace.Kh)
    solver_delta = compute_solver_delta_faces(X, p)
    solver_H = compute_solver_surface_h_downward(X, p)

    diag = compute_snapshot_diagnostics(X, p; t=t)
    diag_km = diag.Km_faces
    diag_kh = diag.Kh_faces
    diag_delta = diag.Delta_faces
    diag_H = diag.sensible_heat_flux

    km_abs = maximum(abs.(solver_km .- diag_km))
    kh_abs = maximum(abs.(solver_kh .- diag_kh))
    delta_abs = maximum(abs.(solver_delta .- diag_delta))
    h_abs = abs(solver_H - diag_H)

    @printf("Snapshot regression check\n")
    @printf("  payload : %s\n", payload_path)
    @printf("  index   : %d / %d\n", idx_eff, ns)
    @printf("  time    : %.6f s\n", Float64(t))
    @printf("  tol     : %.3e\n", tol)
    @printf("\n")
    @printf("Max |solver - diagnostics|\n")
    @printf("  K_m     : %.6e\n", Float64(km_abs))
    @printf("  K_h     : %.6e\n", Float64(kh_abs))
    @printf("  Delta   : %.6e\n", Float64(delta_abs))
    @printf("  H       : %.6e\n", Float64(h_abs))

    pass = km_abs <= tol && kh_abs <= tol && delta_abs <= tol && h_abs <= tol
    if pass
        println("PASS: snapshot regression check is within tolerance.")
        return true
    end

    println("FAIL: one or more metrics exceeded tolerance.")
    return false
end

function main(args::Vector{String}=ARGS)
    cfg = parse_args(args)
    ok = check_snapshot(cfg["input"], cfg["index"], cfg["tol"])
    ok || exit(1)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
