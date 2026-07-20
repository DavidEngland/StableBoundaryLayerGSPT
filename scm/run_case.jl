#!/usr/bin/env julia

using Dates
using Printf
import CSV
import DataFrames
import JSON3

include(joinpath(@__DIR__, "scm_run.jl"))

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
    z0m::T          # Added: Momentum roughness length
    z0h::T          # Added: Thermal roughness length
    k_min_surf::T
    pr_t_base::T
    pr_t_slope::T
    use_dynamic_pr_t::Bool
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

# Usage helper
function _usage()
    println("Usage: julia scm/run_case.jl [options]")
    println("Options:")
    println("  --case <gabls1|idealized_sbl|sheba>  Case name (default: gabls1)")
    println("  --duration <hours>                 Simulation duration in hours (default: 9.0)")
    println("  --dt <seconds>                     Output/sample interval in seconds (default: 30.0)")
    println("  --grid-size <N>                    Vertical levels (default: 80)")
    println("  --dz <meters>                      Vertical spacing (default: 2.0)")
    println("  --outdir <path>                    Output directory (default: results/<case>)")
    println("  --profile-every <seconds>          Profile snapshot spacing (default: 1800)")
    println("  --theta-top-bc <neumann|dirichlet|relaxation>  Upper thermal BC")
    println("  --theta-top <K>                    Upper boundary reference theta")
    println("  --lambda-top <1/s>                 Relaxation coefficient for top BC")
    println("  --theta-lapse-rate <K/m>           Initial background dtheta/dz")
    println("  --z0m <meters>                     Momentum roughness length")
    println("  --z0h <meters>                     Thermal roughness length")
    println("  --h <meters>                       Local coupling bulk scale height")
    println("  --use-nonlocal-h <true|false>      Enable non-local effective h scaling")
    println("  --nonlocal-h-weight <0..1>         Blend weight from local h to non-local h")
    println("  --nonlocal-h-min <meters>          Lower clamp for non-local h")
    println("  --nonlocal-h-max <meters>          Upper clamp for non-local h")
    println("  --k-min-surf <m2/s>                Background surface diffusivity floor")
    println("  --pr-t-base <value>                Baseline turbulent Prandtl number")
    println("  --pr-t-slope <value>               Stability response for dynamic Prandtl")
    println("  --use-dynamic-pr-t <true|false>    Enable stability-aware turbulent Prandtl")
    println("  --ell-min-surf <meters>            Surface mixing-length floor")
    println("  --use-ell-floor-surf <true|false>  Enable surface mixing-length floor")
    println("  --ts-min <K>                       Lower anomaly-guard surface temperature")
    println("  --ts-max <K>                       Upper anomaly-guard surface temperature")
    println("  --debug-print <true|false>         Emit periodic SEB diagnostics")
    println("  --save-jld2 <true|false>           Save payload.jld2 (default: true)")
    println("  --solver-jacobian <autodiff|finite>  Jacobian mode for Rodas5P (default: autodiff)")
    println("  --jacobian-sparsity <dense|banded> Jacobian sparsity hint (default: dense)")
    println("  --help                             Show this help message")
end

function _parse_bool(s::AbstractString)
    v = lowercase(strip(s))
    if v in ("1", "true", "yes", "y", "on")
        return true
    elseif v in ("0", "false", "no", "n", "off")
        return false
    else
        error("Invalid boolean value: $(s)")
    end
end

function parse_args(args::Vector{String})
    cfg = Dict{String,Any}(
        "case" => "gabls1",
        "duration_hours" => 9.0,
        "dt" => 30.0,
        "N" => 80,
        "dz" => 2.0,
        "outdir" => "",
        "profile_every_seconds" => 1800.0,
        "theta_top_bc" => "neumann",
        "theta_top" => nothing,
        "lambda_top" => nothing,
        "theta_lapse_rate" => nothing,
        "z0m" => nothing, # Custom override
        "z0h" => nothing, # Custom override
        "h" => nothing,
        "use_nonlocal_h" => false,
        "nonlocal_h_weight" => nothing,
        "nonlocal_h_min" => nothing,
        "nonlocal_h_max" => nothing,
        "k_min_surf" => 1.0e-3,
        "pr_t_base" => 1.0,
        "pr_t_slope" => 2.0,
        "use_dynamic_pr_t" => false,
        "ell_min_surf" => 0.10,
        "use_ell_floor_surf" => false,
        "ts_min" => 180.0,
        "ts_max" => 350.0,
        "debug_print" => false,
        "save_jld2" => true,
        "solver_jacobian" => "autodiff",
        "jacobian_sparsity" => "dense",
    )

    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--help"
            _usage()
            exit(0)
        elseif a == "--case" && i < length(args)
            cfg["case"] = lowercase(args[i+1])
            i += 2
        elseif a == "--duration" && i < length(args)
            cfg["duration_hours"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--dt" && i < length(args)
            cfg["dt"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--grid-size" && i < length(args)
            cfg["N"] = parse(Int, args[i+1])
            i += 2
        elseif a == "--dz" && i < length(args)
            cfg["dz"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--outdir" && i < length(args)
            cfg["outdir"] = args[i+1]
            i += 2
        elseif a == "--profile-every" && i < length(args)
            cfg["profile_every_seconds"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--theta-top-bc" && i < length(args)
            cfg["theta_top_bc"] = lowercase(args[i+1])
            i += 2
        elseif a == "--theta-top" && i < length(args)
            cfg["theta_top"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--lambda-top" && i < length(args)
            cfg["lambda_top"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--theta-lapse-rate" && i < length(args)
            cfg["theta_lapse_rate"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--z0m" && i < length(args)
            cfg["z0m"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--z0h" && i < length(args)
            cfg["z0h"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--h" && i < length(args)
            cfg["h"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--use-nonlocal-h" && i < length(args)
            cfg["use_nonlocal_h"] = _parse_bool(args[i+1])
            i += 2
        elseif a == "--nonlocal-h-weight" && i < length(args)
            cfg["nonlocal_h_weight"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--nonlocal-h-min" && i < length(args)
            cfg["nonlocal_h_min"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--nonlocal-h-max" && i < length(args)
            cfg["nonlocal_h_max"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--k-min-surf" && i < length(args)
            cfg["k_min_surf"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--pr-t-base" && i < length(args)
            cfg["pr_t_base"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--pr-t-slope" && i < length(args)
            cfg["pr_t_slope"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--use-dynamic-pr-t" && i < length(args)
            cfg["use_dynamic_pr_t"] = _parse_bool(args[i+1])
            i += 2
        elseif a == "--ell-min-surf" && i < length(args)
            cfg["ell_min_surf"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--use-ell-floor-surf" && i < length(args)
            cfg["use_ell_floor_surf"] = _parse_bool(args[i+1])
            i += 2
        elseif a == "--ts-min" && i < length(args)
            cfg["ts_min"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--ts-max" && i < length(args)
            cfg["ts_max"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--debug-print" && i < length(args)
            cfg["debug_print"] = _parse_bool(args[i+1])
            i += 2
        elseif a == "--save-jld2" && i < length(args)
            cfg["save_jld2"] = _parse_bool(args[i+1])
            i += 2
        elseif a == "--solver-jacobian" && i < length(args)
            mode = lowercase(args[i+1])
            mode in ("autodiff", "finite") || error("--solver-jacobian must be autodiff or finite")
            cfg["solver_jacobian"] = mode
            i += 2
        elseif a == "--jacobian-sparsity" && i < length(args)
            mode = lowercase(args[i+1])
            mode in ("dense", "banded") || error("--jacobian-sparsity must be dense or banded")
            cfg["jacobian_sparsity"] = mode
            i += 2
        else
            error("Unknown or incomplete argument: $(a). Use --help for options.")
        end
    end

    return cfg
end

function _build_grid(N::Int, dz::Float64)
    z_centers = collect(range(dz / 2.0, step=dz, length=N))
    z_faces = collect(range(0.0, step=dz, length=N + 1))
    return z_centers, z_faces
end

function _base_case_params(N::Int, dz::Float64)
    z_centers, z_faces = _build_grid(N, dz)
    ws = SCMWorkspace(zeros(N - 1), zeros(N - 1))
    return Dict{String,Any}(
        "N" => N,
        "dz" => dz,
        "z_centers" => z_centers,
        "z_faces" => z_faces,
        "f" => 1.0e-4,
        "Ug" => 8.0,
        "Vg" => 0.0,
        "theta_a" => 265.0,
        "T_deep" => 262.0,
        "delta" => 1.0e-4,
        "K_buoy" => 1.0,
        "beta" => 1.0,
        "l_0" => 15.0,        # Corrected: Physical SBL mixing limit (not 120.0 m)
        "eta" => 1.5,         # Corrected: Scaled MOST shear efficiency (not 0.12)
        "xi" => 1.0e-3,
        "C_skin" => 2.0e4,
        "R_down" => 240.0,
        "lambda_s" => 1.2,
        "d_soil" => 0.10,
        "h" => 100.0,
        "use_nonlocal_h" => 0.0,
        "nonlocal_h_weight" => 0.5,
        "nonlocal_h_min" => 20.0,
        "nonlocal_h_max" => 400.0,
        "nonlocal_velocity_floor" => 0.1,
        "nonlocal_f_floor" => 1.0e-5,
        "z0m" => 0.1,         # Default momentum roughness length
        "z0h" => 0.01,        # Default thermal roughness length
        "k_min_surf" => 1.0e-3,
        "pr_t_base" => 1.0,
        "pr_t_slope" => 2.0,
        "use_dynamic_pr_t" => false,
        "ell_min_surf" => 0.10,
        "use_ell_floor_surf" => false,
        "ts_min" => 180.0,
        "ts_max" => 350.0,
        "theta_top_bc" => :neumann,
        "theta_top" => 265.0,
        "lambda_top" => 0.0,
        "debug_print" => false,
        "profile_every" => 1800.0,
        "workspace" => ws,
    )
end

function build_case(case_name::String, N::Int, dz::Float64; theta_lapse_rate_override=nothing)
    d = _base_case_params(N, dz)
    z = d["z_centers"]

    if case_name == "gabls1"
        d["Ug"] = 8.0
        d["theta_a"] = 265.0
        d["T_deep"] = 262.0
        d["R_down"] = 245.0
        d["z0m"] = 0.1
        d["z0h"] = 0.01
        d["theta_top_bc"] = :dirichlet
        d["theta_top"] = 265.0
        d["theta_lapse_rate"] = 0.01

        U0 = 0.7 .* d["Ug"] .* (1 .- exp.(-z ./ 120.0))
        V0 = zeros(Float64, N)
        theta_lapse_rate = isnothing(theta_lapse_rate_override) ? d["theta_lapse_rate"] : Float64(theta_lapse_rate_override)
        theta0 = d["theta_a"] .+ theta_lapse_rate .* z
        Ts0 = d["theta_a"] - 1.0
    elseif case_name == "idealized_sbl"
        # Setup matches CASES99 prairie grass site configuration
        d["Ug"] = 10.0
        d["theta_a"] = 280.0
        d["T_deep"] = 276.0
        d["R_down"] = 300.0
        d["beta"] = 1.2
        d["z0m"] = 0.02
        d["z0h"] = 0.005
        d["theta_top_bc"] = :neumann
        d["theta_lapse_rate"] = 0.006

        U0 = 0.8 .* d["Ug"] .* (1 .- exp.(-z ./ 100.0))
        V0 = zeros(Float64, N)
        theta_lapse_rate = isnothing(theta_lapse_rate_override) ? d["theta_lapse_rate"] : Float64(theta_lapse_rate_override)
        theta0 = d["theta_a"] .+ theta_lapse_rate .* z
        Ts0 = d["theta_a"] - 2.0
    elseif case_name == "sheba"
        # Arctic sea-ice benchmark with weak roughness and strong stability.
        d["Ug"] = 7.0
        d["theta_a"] = 257.0
        d["T_deep"] = 255.5
        d["R_down"] = 190.0
        d["beta"] = 1.15
        d["h"] = 300.0
        d["nonlocal_h_max"] = 400.0
        d["z0m"] = 1.0e-4
        d["z0h"] = 1.0e-5
        d["ts_min"] = 220.0
        d["theta_top_bc"] = :dirichlet
        d["theta_top"] = 257.0
        d["theta_lapse_rate"] = 0.004

        U0 = 0.6 .* d["Ug"] .* (1 .- exp.(-z ./ 90.0))
        V0 = zeros(Float64, N)
        theta_lapse_rate = isnothing(theta_lapse_rate_override) ? d["theta_lapse_rate"] : Float64(theta_lapse_rate_override)
        theta0 = d["theta_a"] .+ theta_lapse_rate .* z
        Ts0 = d["theta_a"] - 3.0
    else
        error("Unknown case: $(case_name). Supported: gabls1, idealized_sbl, sheba")
    end

    p = SCMParameters(
        d["N"],
        d["dz"],
        d["z_centers"],
        d["z_faces"],
        d["f"],
        d["Ug"],
        d["Vg"],
        d["theta_a"],
        d["T_deep"],
        d["delta"],
        d["K_buoy"],
        d["beta"],
        d["l_0"],
        d["eta"],
        d["xi"],
        d["C_skin"],
        d["R_down"],
        d["lambda_s"],
        d["d_soil"],
        d["h"],
        d["use_nonlocal_h"],
        d["nonlocal_h_weight"],
        d["nonlocal_h_min"],
        d["nonlocal_h_max"],
        d["nonlocal_velocity_floor"],
        d["nonlocal_f_floor"],
        d["z0m"],
        d["z0h"],
        d["k_min_surf"],
        d["pr_t_base"],
        d["pr_t_slope"],
        d["use_dynamic_pr_t"],
        d["ell_min_surf"],
        d["use_ell_floor_surf"],
        d["ts_min"],
        d["ts_max"],
        d["theta_top_bc"],
        d["theta_top"],
        d["lambda_top"],
        d["debug_print"],
        d["profile_every"],
        d["workspace"],
    )

    X0 = zeros(Float64, 3N + 1)
    X0[1] = Ts0
    X0[2:(N+1)] .= U0
    X0[(N+2):(2N+1)] .= V0
    X0[(2N+2):(3N+1)] .= theta0

    return X0, p
end

function _apply_top_bc_overrides!(p::SCMParameters, theta_top_bc::String, theta_top_override, lambda_top_override)
    bc = Symbol(theta_top_bc)
    bc in (:neumann, :dirichlet, :relaxation) || error("Invalid --theta-top-bc value: $(theta_top_bc)")

    theta_top = isnothing(theta_top_override) ? p.theta_top : Float64(theta_top_override)
    lambda_top = isnothing(lambda_top_override) ? p.lambda_top : Float64(lambda_top_override)

    return SCMParameters(
        p.N,
        p.dz,
        p.z_centers,
        p.z_faces,
        p.f,
        p.Ug,
        p.Vg,
        p.theta_a,
        p.T_deep,
        p.delta,
        p.K_buoy,
        p.beta,
        p.l_0,
        p.eta,
        p.xi,
        p.C_skin,
        p.R_down,
        p.lambda_s,
        p.d_soil,
        p.h,
        p.use_nonlocal_h,
        p.nonlocal_h_weight,
        p.nonlocal_h_min,
        p.nonlocal_h_max,
        p.nonlocal_velocity_floor,
        p.nonlocal_f_floor,
        p.z0m,
        p.z0h,
        p.k_min_surf,
        p.pr_t_base,
        p.pr_t_slope,
        p.use_dynamic_pr_t,
        p.ell_min_surf,
        p.use_ell_floor_surf,
        p.ts_min,
        p.ts_max,
        bc,
        theta_top,
        lambda_top,
        p.debug_print,
        p.profile_every,
        p.workspace,
    )
end

function _apply_runtime_overrides!(p::SCMParameters, cfg)
    z0m_val = isnothing(cfg["z0m"]) ? p.z0m : Float64(cfg["z0m"])
    z0h_val = isnothing(cfg["z0h"]) ? p.z0h : Float64(cfg["z0h"])
    h_val = isnothing(cfg["h"]) ? p.h : Float64(cfg["h"])
    h_weight = isnothing(cfg["nonlocal_h_weight"]) ? p.nonlocal_h_weight : Float64(cfg["nonlocal_h_weight"])
    h_min = isnothing(cfg["nonlocal_h_min"]) ? p.nonlocal_h_min : Float64(cfg["nonlocal_h_min"])
    h_max = isnothing(cfg["nonlocal_h_max"]) ? p.nonlocal_h_max : Float64(cfg["nonlocal_h_max"])
    use_nonlocal_h_val = Bool(cfg["use_nonlocal_h"]) ? 1.0 : 0.0

    return SCMParameters(
        p.N,
        p.dz,
        p.z_centers,
        p.z_faces,
        p.f,
        p.Ug,
        p.Vg,
        p.theta_a,
        p.T_deep,
        p.delta,
        p.K_buoy,
        p.beta,
        p.l_0,
        p.eta,
        p.xi,
        p.C_skin,
        p.R_down,
        p.lambda_s,
        p.d_soil,
        h_val,
        use_nonlocal_h_val,
        h_weight,
        h_min,
        h_max,
        p.nonlocal_velocity_floor,
        p.nonlocal_f_floor,
        z0m_val,
        z0h_val,
        Float64(cfg["k_min_surf"]),
        Float64(cfg["pr_t_base"]),
        Float64(cfg["pr_t_slope"]),
        Bool(cfg["use_dynamic_pr_t"]),
        Float64(cfg["ell_min_surf"]),
        Bool(cfg["use_ell_floor_surf"]),
        Float64(cfg["ts_min"]),
        Float64(cfg["ts_max"]),
        p.theta_top_bc,
        p.theta_top,
        p.lambda_top,
        Bool(cfg["debug_print"]),
        Float64(cfg["profile_every_seconds"]),
        p.workspace,
    )
end

function _scalar_timeseries_columns(time_series)
    isempty(time_series) && return Dict{String,Vector{Float64}}()

    keys_all = propertynames(time_series[1])
    scalar_keys = Symbol[]
    for k in keys_all
        v = getproperty(time_series[1], k)
        if v isa Number || v isa Bool
            push!(scalar_keys, k)
        end
    end

    cols = Dict{String,Any}()
    for k in scalar_keys
        cols[string(k)] = [getproperty(row, k) for row in time_series]
    end
    return cols
end

# Enhanced Parameter Snapshot for Reporting/Paper
function _parameter_snapshot(p::SCMParameters)
    return Dict(
        "Ug" => p.Ug,
        "Vg" => p.Vg,
        "f" => p.f,
        "theta_a" => p.theta_a,
        "T_deep" => p.T_deep,
        "R_down" => p.R_down,
        "lambda_s" => p.lambda_s,
        "d_soil" => p.d_soil,
        "h" => p.h,
        "use_nonlocal_h" => p.use_nonlocal_h,
        "nonlocal_h_weight" => p.nonlocal_h_weight,
        "nonlocal_h_min" => p.nonlocal_h_min,
        "nonlocal_h_max" => p.nonlocal_h_max,
        "z0m" => p.z0m,                 # Exported to paper/JSON
        "z0h" => p.z0h,                 # Exported to paper/JSON
        "l_0" => p.l_0,                 # Exported to paper/JSON
        "eta" => p.eta,                 # Exported to paper/JSON
        "delta" => p.delta,
        "xi" => p.xi,
        "k_min_surf" => p.k_min_surf,
        "pr_t_base" => p.pr_t_base,
        "pr_t_slope" => p.pr_t_slope,
        "use_dynamic_pr_t" => p.use_dynamic_pr_t,
        "ell_min_surf" => p.ell_min_surf,
        "use_ell_floor_surf" => p.use_ell_floor_surf,
        "ts_min" => p.ts_min,
        "ts_max" => p.ts_max,
        "theta_top_bc" => string(p.theta_top_bc),
        "theta_top" => p.theta_top,
        "lambda_top" => p.lambda_top,
        "N" => p.N,
        "dz" => p.dz,
    )
end

function _write_outputs(outdir::String, payload, case_name::String, args_cfg, p::SCMParameters)
    mkpath(outdir)

    ts_cols = _scalar_timeseries_columns(payload.time_series)
    ts_df = DataFrames.DataFrame(ts_cols)
    ts_csv = joinpath(outdir, "time_series.csv")
    CSV.write(ts_csv, ts_df)

    summary = Dict(
        "case" => case_name,
        "outdir" => outdir,
        "n_times" => length(payload.times),
        "n_profiles" => length(payload.profiles),
        "solver_summary" => payload.solver_summary,
        "verification" => payload.verification,
        "figure_manifest" => payload.figure_manifest,
        "arguments" => args_cfg,
        "parameters" => _parameter_snapshot(p),
        "artifacts" => Dict("time_series_csv" => ts_csv),
    )

    if args_cfg["save_jld2"]
        payload_path = joinpath(outdir, "payload.jld2")
        save_scm_results(payload_path, payload)
        summary["artifacts"]["payload_jld2"] = payload_path
    end

    summary_path = joinpath(outdir, "summary.json")
    open(summary_path, "w") do io
        JSON3.pretty(io, summary)
    end

    return (time_series_csv=ts_csv, summary_json=summary_path)
end

function _write_failure_summary(outdir::String, case_name::String, args_cfg, p::SCMParameters, e::SurfaceAnomalyException)
    mkpath(outdir)
    summary = Dict(
        "status" => "failed",
        "case" => case_name,
        "outdir" => outdir,
        "arguments" => args_cfg,
        "parameters" => _parameter_snapshot(p),
        "failure" => Dict(
            "type" => "SurfaceAnomalyException",
            "failure_time_hours" => e.t / 3600.0,
            "failure_Ts" => e.Ts,
            "reason" => e.reason,
            "state_snapshot" => e.state_summary,
        ),
    )
    summary_path = joinpath(outdir, "summary.json")
    open(summary_path, "w") do io
        JSON3.pretty(io, summary)
    end
    return summary_path
end

function main(args)
    cfg = parse_args(args)

    case_name = cfg["case"]
    N = cfg["N"]
    dz = cfg["dz"]
    duration_hours = cfg["duration_hours"]
    dt = cfg["dt"]
    outdir = cfg["outdir"] == "" ? joinpath("results", case_name) : cfg["outdir"]

    X0, p0 = build_case(case_name, N, dz; theta_lapse_rate_override=cfg["theta_lapse_rate"])
    if isnothing(cfg["theta_lapse_rate"]) && N > 1
        cfg["theta_lapse_rate"] = (X0[2N + 3] - X0[2N + 2]) / dz
    end
    p1 = _apply_top_bc_overrides!(p0, cfg["theta_top_bc"], cfg["theta_top"], cfg["lambda_top"])
    p = _apply_runtime_overrides!(p1, cfg)

    t_span = (0.0, duration_hours * 3600.0)
    payload = try
        run_and_diagnose_scm(
            X0,
            p,
            t_span,
            dt;
            profile_every_seconds=cfg["profile_every_seconds"],
            jacobian_mode=Symbol(cfg["solver_jacobian"]),
            jacobian_sparsity=Symbol(cfg["jacobian_sparsity"]),
        )
    catch e
        if e isa SurfaceAnomalyException
            println(repeat("=", 80))
            println("SIMULATION ABORTED VIA ANOMALY GUARD")
            println(repeat("=", 80))
            showerror(stdout, e)
            println()
            println(repeat("=", 80))
            summary_path = _write_failure_summary(outdir, case_name, cfg, p, e)
            @printf("Failure summary written to: %s\n", summary_path)
            exit(1)
        end
        rethrow(e)
    end

    paths = _write_outputs(outdir, payload, case_name, cfg, p)

    println("Run complete")
    @printf("  case       : %s\n", case_name)
    @printf("  outdir     : %s\n", outdir)
    @printf("  timeseries : %s\n", paths.time_series_csv)
    @printf("  summary    : %s\n", paths.summary_json)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end