#!/usr/bin/env julia
# scripts/run_4d_solver.jl
using CSV
using DataFrames
using Dates
using JSON3
using YAML
using StableBoundaryLayerGSPT.Dynamics

function parse_args(args::Vector{String})
    # Track explicitly supplied CLI flags to enforce CLI > YAML precedence
    cli_supplied = Dict{Symbol,Bool}(
        :dataset => false,
        :outdir => false,
        :solver => false,
        :hours => false,
        :save_dt => false,
    )

    dataset = "CASES99"
    outdir = "results/4d_sbl"
    solver = :rodas5p
    t_hours = 14.0
    save_dt = 30.0

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--dataset" && i < length(args)
            dataset = uppercase(strip(args[i+1]))
            cli_supplied[:dataset] = true
            i += 2
        elseif arg == "--outdir" && i < length(args)
            outdir = args[i+1]
            cli_supplied[:outdir] = true
            i += 2
        elseif arg == "--solver" && i < length(args)
            sval = lowercase(args[i+1])
            if sval == "rodas5p"
                solver = :rodas5p
            elseif sval == "rosenbrock23"
                solver = :rosenbrock23
            else
                error("Unknown solver: $(args[i + 1]). Use rodas5p or rosenbrock23.")
            end
            cli_supplied[:solver] = true
            i += 2
        elseif arg == "--hours" && i < length(args)
            t_hours = parse(Float64, args[i+1])
            cli_supplied[:hours] = true
            i += 2
        elseif arg == "--save-dt" && i < length(args)
            save_dt = parse(Float64, args[i+1])
            cli_supplied[:save_dt] = true
            i += 2
        else
            error("Unknown or incomplete argument: $(arg)")
        end
    end

    return dataset, outdir, solver, t_hours, save_dt, cli_supplied
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

function safe_parse_float(val)
    val isa Real && return Float64(val)
    return parse(Float64, string(val))
end

function apply_parameter_overrides!(params::Dict{String,Float64}, overrides)
    overrides isa AbstractDict || return params
    for (key, value) in overrides
        params[string(key)] = safe_parse_float(value)
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

# 1. Parse CLI Arguments
cli_dataset, cli_outdir, cli_solver, cli_hours, cli_save_dt, cli_supplied = parse_args(ARGS)

# 2. Load Dataset Spec
spec, spec_path = load_dataset_spec(cli_dataset)
solver_spec = spec_lookup(spec, "four_d_solver", Dict{Any,Any}())

# 3. Parameter Construction (Defaults -> Spec -> CLI)
params = default_4d_parameters()
apply_parameter_overrides!(params, spec_lookup(solver_spec, "parameters", Dict{Any,Any}()))

initial_state = spec_lookup(solver_spec, "initial_state", Dict{Any,Any}())
u0 = [
    safe_parse_float(spec_lookup(initial_state, "e", 1.0)),
    safe_parse_float(spec_lookup(initial_state, "U", 5.0)),
    safe_parse_float(spec_lookup(initial_state, "V", 0.0)),
    safe_parse_float(spec_lookup(initial_state, "Ts", 285.15)),
]

# Enforce Precedence: Spec overrides defaults, but explicit CLI overrides Spec
solver = cli_supplied[:solver] ? cli_solver : parse_solver_symbol(spec_lookup(solver_spec, "solver", String(cli_solver)))
t_hours = cli_supplied[:hours] ? cli_hours : safe_parse_float(spec_lookup(solver_spec, "hours", cli_hours))
save_dt = cli_supplied[:save_dt] ? cli_save_dt : safe_parse_float(spec_lookup(solver_spec, "save_dt_seconds", cli_save_dt))

outdir = cli_supplied[:outdir] ? cli_outdir : (cli_outdir == "results/4d_sbl" ? joinpath("results", cli_dataset) : cli_outdir)
tspan = (0.0, t_hours * 3600.0)

# 4. Solve System
sol = solve_4d_sbl(
    parameters=params,
    u0=u0,
    tspan=tspan,
    solver=solver,
    saveat=save_dt,
)

rows = solution_to_rows(sol, params)
df = DataFrame(rows)

# 5. Export Run Artifacts
timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
run_dir = joinpath(outdir, "run_$(timestamp)")
mkpath(run_dir)

latest_dir = joinpath(outdir, "latest")
if ispath(latest_dir) || islink(latest_dir)
    rm(latest_dir; force=true, recursive=true)
end

csv_path = joinpath(run_dir, "solution.csv")
summary_path = joinpath(run_dir, "summary.json")
CSV.write(csv_path, df)

try
    symlink(abspath(run_dir), latest_dir; dir_target=true)
catch e
    @warn "Failed to create symlink for 'latest' target (likely OS permissions): $(e)"
end

# 6. Extract Solver Stats cleanly across SciML versions
stats = hasproperty(sol, :stats) && !isnothing(sol.stats) ? sol.stats :
        (hasproperty(sol, :destats) ? sol.destats : nothing)

accepted_steps = !isnothing(stats) && hasproperty(stats, :naccept) ? stats.naccept : -1
rejected_steps = !isnothing(stats) && hasproperty(stats, :nreject) ? stats.nreject : -1
function_evals = !isnothing(stats) && hasproperty(stats, :nf) ? stats.nf : -1

floors = diagnostic_diffusivity_floors(params)
summary = Dict(
    "dataset" => cli_dataset,
    "spec_path" => spec_path,
    "run_dir" => run_dir,
    "latest_dir" => latest_dir,
    "outdir" => outdir,
    "solver" => String(solver),
    "tspan_seconds" => [tspan[1], tspan[2]],
    "save_dt_seconds" => save_dt,
    "initial_state" => Dict("e" => u0[1], "U" => u0[2], "V" => u0[3], "Ts" => u0[4]),
    "destats" => Dict(
        "accepted_steps" => accepted_steps,
        "rejected_steps" => rejected_steps,
        "function_evals" => function_evals,
    ),
    "diffusivity_floors" => floors,
    "parameters" => params,
    "artifacts" => Dict("solution_csv" => csv_path),
)

open(summary_path, "w") do io
    JSON3.pretty(io, summary)
end

println("4D solver completed")
println("dataset=$(cli_dataset)")
println("run_dir=$(run_dir)")
println("solution=$(csv_path)")
println("summary=$(summary_path)")