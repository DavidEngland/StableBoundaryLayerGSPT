#!/usr/bin/env julia

using CSV
using DataFrames
using Dates
using JSON3
using YAML
using StableBoundaryLayerGSPT.Dynamics

function parse_args(args::Vector{String})
    dataset = "CASES99"
    outdir = "results/4d_sbl"
    solver = :rodas5p
    t_hours = 14.0
    save_dt = 30.0

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--dataset" && i < length(args)
            dataset = uppercase(strip(args[i + 1]))
            i += 2
        elseif arg == "--outdir" && i < length(args)
            outdir = args[i + 1]
            i += 2
        elseif arg == "--solver" && i < length(args)
            sval = lowercase(args[i + 1])
            if sval == "rodas5p"
                solver = :rodas5p
            elseif sval == "rosenbrock23"
                solver = :rosenbrock23
            else
                error("Unknown solver: $(args[i + 1]). Use rodas5p or rosenbrock23.")
            end
            i += 2
        elseif arg == "--hours" && i < length(args)
            t_hours = parse(Float64, args[i + 1])
            i += 2
        elseif arg == "--save-dt" && i < length(args)
            save_dt = parse(Float64, args[i + 1])
            i += 2
        else
            error("Unknown or incomplete argument: $(arg)")
        end
    end

    if outdir == "results/4d_sbl"
        outdir = joinpath("results", dataset)
    end

    return dataset, outdir, solver, t_hours, save_dt
end

function load_dataset_spec(dataset::String)
    spec_path = joinpath("spec", "datasets", "$(dataset).yaml")
    isfile(spec_path) || error("Missing dataset specification: $(spec_path)")
    return YAML.load_file(spec_path), spec_path
end

function spec_lookup(spec::AbstractDict, key::AbstractString, default)
    if haskey(spec, key)
        return spec[key]
    end
    symbol_key = Symbol(key)
    if haskey(spec, symbol_key)
        return spec[symbol_key]
    end
    return default
end

function apply_parameter_overrides!(params::Dict{String,Float64}, overrides)
    overrides isa AbstractDict || return params
    for (key, value) in overrides
        params[string(key)] = Float64(value)
    end
    return params
end

function parse_solver_symbol(value)
    sval = lowercase(strip(String(value)))
    if sval == "rodas5p"
        return :rodas5p
    elseif sval == "rosenbrock23"
        return :rosenbrock23
    end
    error("Unknown solver: $(value). Use rodas5p or rosenbrock23.")
end

dataset, outdir, solver, t_hours, save_dt = parse_args(ARGS)
spec, spec_path = load_dataset_spec(dataset)
solver_spec = spec_lookup(spec, "four_d_solver", Dict{Any,Any}())

params = default_4d_parameters()
apply_parameter_overrides!(params, spec_lookup(solver_spec, "parameters", Dict{Any,Any}()))

initial_state = spec_lookup(solver_spec, "initial_state", Dict{Any,Any}())
u0 = [
    Float64(spec_lookup(initial_state, "e", 1.0)),
    Float64(spec_lookup(initial_state, "U", 5.0)),
    Float64(spec_lookup(initial_state, "V", 0.0)),
    Float64(spec_lookup(initial_state, "Ts", 285.15)),
]

solver = parse_solver_symbol(spec_lookup(solver_spec, "solver", String(solver)))
t_hours = Float64(spec_lookup(solver_spec, "hours", t_hours))
save_dt = Float64(spec_lookup(solver_spec, "save_dt_seconds", save_dt))
tspan = (0.0, t_hours * 3600.0)

sol = solve_4d_sbl(
    parameters=params,
    u0=u0,
    tspan=tspan,
    solver=solver,
    saveat=save_dt,
)

rows = solution_to_rows(sol, params)
df = DataFrame(rows)

timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
run_dir = joinpath(outdir, "run_$(timestamp)")
mkpath(run_dir)

latest_dir = joinpath(outdir, "latest")
if ispath(latest_dir)
    rm(latest_dir; force=true, recursive=true)
end

csv_path = joinpath(run_dir, "solution.csv")
summary_path = joinpath(run_dir, "summary.json")
CSV.write(csv_path, df)
symlink(abspath(run_dir), latest_dir; dir_target=true)

floors = diagnostic_diffusivity_floors(params)
summary = Dict(
    "dataset" => dataset,
    "spec_path" => spec_path,
    "run_dir" => run_dir,
    "latest_dir" => latest_dir,
    "outdir" => outdir,
    "solver" => String(solver),
    "tspan_seconds" => [tspan[1], tspan[2]],
    "save_dt_seconds" => save_dt,
    "initial_state" => Dict("e" => u0[1], "U" => u0[2], "V" => u0[3], "Ts" => u0[4]),
    "destats" => Dict(
        "accepted_steps" => sol.destats.naccept,
        "rejected_steps" => sol.destats.nreject,
        "function_evals" => sol.destats.nf,
    ),
    "diffusivity_floors" => floors,
    "parameters" => params,
    "artifacts" => Dict("solution_csv" => csv_path),
)

open(summary_path, "w") do io
    JSON3.pretty(io, summary)
end

println("4D solver completed")
println("dataset=$(dataset)")
println("run_dir=$(run_dir)")
println("solution=$(csv_path)")
println("summary=$(summary_path)")