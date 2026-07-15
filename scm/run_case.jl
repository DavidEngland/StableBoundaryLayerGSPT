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
    k_min_surf::T
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
    println("Usage: julia scm/run_case.jl [options]")
    println("Options:")
    println("  --case <gabls1|idealized_sbl>      Case name (default: gabls1)")
    println("  --duration <hours>                 Simulation duration in hours (default: 9.0)")
    println("  --dt <seconds>                     Output/sample interval in seconds (default: 30.0)")
    println("  --grid-size <N>                    Vertical levels (default: 80)")
    println("  --dz <meters>                      Vertical spacing (default: 2.0)")
    println("  --outdir <path>                    Output directory (default: results/<case>)")
    println("  --profile-every <seconds>          Profile snapshot spacing (default: 1800)")
    println("  --theta-top-bc <neumann|dirichlet|relaxation>  Upper thermal BC")
    println("  --theta-top <K>                    Upper boundary reference theta")
    println("  --lambda-top <1/s>                 Relaxation coefficient for top BC")
    println("  --k-min-surf <m2/s>                Background surface diffusivity floor")
    println("  --ts-min <K>                       Lower anomaly-guard surface temperature")
    println("  --ts-max <K>                       Upper anomaly-guard surface temperature")
    println("  --debug-print <true|false>         Emit periodic SEB diagnostics")
    println("  --save-jld2 <true|false>           Save payload.jld2 (default: true)")
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
        "k_min_surf" => 1.0e-3,
        "ts_min" => 180.0,
        "ts_max" => 350.0,
        "debug_print" => false,
        "save_jld2" => true,
    )

    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--help"
            _usage()
            exit(0)
        elseif a == "--case" && i < length(args)
            cfg["case"] = lowercase(args[i + 1])
            i += 2
        elseif a == "--duration" && i < length(args)
            cfg["duration_hours"] = parse(Float64, args[i + 1])
            i += 2
        elseif a == "--dt" && i < length(args)
            cfg["dt"] = parse(Float64, args[i + 1])
            i += 2
        elseif a == "--grid-size" && i < length(args)
            cfg["N"] = parse(Int, args[i + 1])
            i += 2
        elseif a == "--dz" && i < length(args)
            cfg["dz"] = parse(Float64, args[i + 1])
            i += 2
        elseif a == "--outdir" && i < length(args)
            cfg["outdir"] = args[i + 1]
            i += 2
        elseif a == "--profile-every" && i < length(args)
            cfg["profile_every_seconds"] = parse(Float64, args[i + 1])
            i += 2
        elseif a == "--theta-top-bc" && i < length(args)
            cfg["theta_top_bc"] = lowercase(args[i + 1])
            i += 2
        elseif a == "--theta-top" && i < length(args)
            cfg["theta_top"] = parse(Float64, args[i + 1])
            i += 2
        elseif a == "--lambda-top" && i < length(args)
            cfg["lambda_top"] = parse(Float64, args[i + 1])
            i += 2
        elseif a == "--k-min-surf" && i < length(args)
            cfg["k_min_surf"] = parse(Float64, args[i + 1])
            i += 2
        elseif a == "--ts-min" && i < length(args)
            cfg["ts_min"] = parse(Float64, args[i + 1])
            i += 2
        elseif a == "--ts-max" && i < length(args)
            cfg["ts_max"] = parse(Float64, args[i + 1])
            i += 2
        elseif a == "--debug-print" && i < length(args)
            cfg["debug_print"] = _parse_bool(args[i + 1])
            i += 2
        elseif a == "--save-jld2" && i < length(args)
            cfg["save_jld2"] = _parse_bool(args[i + 1])
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
        "l_0" => 120.0,
        "eta" => 0.12,
        "xi" => 1.0e-2,
        "C_skin" => 2.0e4,
        "R_down" => 240.0,
        "lambda_s" => 1.2,
        "d_soil" => 0.10,
        "k_min_surf" => 1.0e-3,
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

function build_case(case_name::String, N::Int, dz::Float64)
    d = _base_case_params(N, dz)
    z = d["z_centers"]

    if case_name == "gabls1"
        d["Ug"] = 8.0
        d["theta_a"] = 265.0
        d["T_deep"] = 262.0
        d["R_down"] = 245.0
        d["theta_top_bc"] = :dirichlet
        d["theta_top"] = 265.0

        U0 = 0.7 .* d["Ug"] .* (1 .- exp.(-z ./ 120.0))
        V0 = zeros(Float64, N)
        theta0 = d["theta_a"] .+ 0.01 .* z
        Ts0 = d["theta_a"] - 1.0
    elseif case_name == "idealized_sbl"
        d["Ug"] = 10.0
        d["theta_a"] = 280.0
        d["T_deep"] = 276.0
        d["R_down"] = 300.0
        d["beta"] = 1.2
        d["theta_top_bc"] = :neumann

        U0 = 0.8 .* d["Ug"] .* (1 .- exp.(-z ./ 100.0))
        V0 = zeros(Float64, N)
        theta0 = d["theta_a"] .+ 0.006 .* z
        Ts0 = d["theta_a"] - 2.0
    else
        error("Unknown case: $(case_name). Supported: gabls1, idealized_sbl")
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
        d["k_min_surf"],
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
    X0[2:(N + 1)] .= U0
    X0[(N + 2):(2N + 1)] .= V0
    X0[(2N + 2):(3N + 1)] .= theta0

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
        p.k_min_surf,
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
        Float64(cfg["k_min_surf"]),
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

function _write_outputs(outdir::String, payload, case_name::String, args_cfg)
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

function _write_failure_summary(outdir::String, case_name::String, args_cfg, e::SurfaceAnomalyException)
    mkpath(outdir)
    summary = Dict(
        "status" => "failed",
        "case" => case_name,
        "outdir" => outdir,
        "arguments" => args_cfg,
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

    X0, p0 = build_case(case_name, N, dz)
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
        )
    catch e
        if e isa SurfaceAnomalyException
            println(repeat("=", 80))
            println("SIMULATION ABORTED VIA ANOMALY GUARD")
            println(repeat("=", 80))
            showerror(stdout, e)
            println()
            println(repeat("=", 80))
            summary_path = _write_failure_summary(outdir, case_name, cfg, e)
            @printf("Failure summary written to: %s\n", summary_path)
            exit(1)
        end
        rethrow(e)
    end

    paths = _write_outputs(outdir, payload, case_name, cfg)

    println("Run complete")
    @printf("  case       : %s\n", case_name)
    @printf("  outdir     : %s\n", outdir)
    @printf("  timeseries : %s\n", paths.time_series_csv)
    @printf("  summary    : %s\n", paths.summary_json)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
