#!/usr/bin/env julia

using CSV
using DataFrames
using Dates
using JSON3
using StableBoundaryLayerGSPT.Dynamics

function parse_args(args::Vector{String})
    outdir = "results/4d_sbl"
    solver = :rodas5p
    t_hours = 14.0
    save_dt = 30.0

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--outdir" && i < length(args)
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

    return outdir, solver, t_hours, save_dt
end

outdir, solver, t_hours, save_dt = parse_args(ARGS)
params = default_4d_parameters()

# Requested evening convective-to-stable transition initial state.
u0 = [1.0, 5.0, 0.0, 285.15]
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

csv_path = joinpath(run_dir, "solution.csv")
summary_path = joinpath(run_dir, "summary.json")
CSV.write(csv_path, df)

floors = diagnostic_diffusivity_floors(params)
summary = Dict(
    "run_dir" => run_dir,
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
println("run_dir=$(run_dir)")
println("solution=$(csv_path)")
println("summary=$(summary_path)")