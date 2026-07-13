#!/usr/bin/env julia

using CSV
using DataFrames
using Plots
using StableBoundaryLayerGSPT.Dynamics
using YAML

function parse_args(args::Vector{String})
    dataset = "CASES99"
    out_path = "reports/generated/figures/diagnostic_regularization_comparison.png"
    t_hours = 500.0 / 3600.0
    save_dt = 2.0

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--dataset" && i < length(args)
            dataset = uppercase(strip(args[i + 1]))
            i += 2
        elseif arg == "--out" && i < length(args)
            out_path = args[i + 1]
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

    return dataset, out_path, t_hours, save_dt
end

function load_solver_parameters(dataset::String)
    params = default_4d_parameters()
    spec_path = joinpath("spec", "datasets", "$(dataset).yaml")
    if isfile(spec_path)
        spec = YAML.load_file(spec_path)
        solver_spec = haskey(spec, "four_d_solver") ? spec["four_d_solver"] : Dict{Any,Any}()
        if solver_spec isa AbstractDict && haskey(solver_spec, "parameters")
            for (key, value) in solver_spec["parameters"]
                params[string(key)] = Float64(value)
            end
        end
        params["xi"] = Float64(get(solver_spec, "xi", get(params, "xi", 1.0e-5)))
        default_u0 = [0.05, 6.0, 0.0, 284.0]
        return params, default_u0
    end

    params["xi"] = 1.0e-5
    default_u0 = [0.05, 6.0, 0.0, 284.0]
    return params, default_u0
end

function collapse_index(df::DataFrame)
    e_floor_threshold = max(1.0e-3, 10.0 * minimum(abs, diff(sort(unique(df.e)))))
    for i in 2:nrow(df)
        if df.e[i] <= e_floor_threshold && df.e[i - 1] > e_floor_threshold
            return i
        end
    end
    return argmin(df.e)
end

dataset, out_path, t_hours, save_dt = parse_args(ARGS)
params, u0 = load_solver_parameters(dataset)

sol = solve_4d_sbl(
    parameters=params,
    u0=u0,
    tspan=(0.0, t_hours * 3600.0),
    saveat=save_dt,
)

df = DataFrame(solution_to_rows(sol, params))
df.time_seconds = df.t
df.time_minutes = df.t ./ 60.0

idx_collapse = collapse_index(df)
t_collapse = df.time_seconds[idx_collapse]

p1 = plot(
    df.time_seconds,
    df.e,
    label="State TKE (e)",
    lw=2.5,
    color=:black,
    xlabel="Time (s)",
    ylabel="Energy (m^2 s^-2)",
    title="Fast Transition Boundary",
)
plot!(p1, df.time_seconds, df.e_star_smooth, label="Embedded TKE (e*_xi)", lw=2, ls=:dash, color=:crimson)
vline!(p1, [t_collapse], color=:gray40, ls=:dot, label="Collapse window")

p2 = plot(
    df.time_seconds,
    df.Km,
    label="State-Based Km",
    lw=2.5,
    color=:royalblue,
    xlabel="Time (s)",
    ylabel="Km (m^2 s^-1)",
    title="Momentum Eddy Diffusivity",
)
plot!(p2, df.time_seconds, df.Km_star, label="Embedded Km*", lw=2, ls=:dash, color=:darkorange)
vline!(p2, [t_collapse], color=:gray40, ls=:dot, label="")

p3 = plot(
    df.time_seconds,
    df.Kh,
    label="State-Based Kh",
    lw=2.5,
    color=:seagreen3,
    xlabel="Time (s)",
    ylabel="Kh (m^2 s^-1)",
    title="Heat Eddy Diffusivity",
)
plot!(p3, df.time_seconds, df.Kh_star, label="Embedded Kh*", lw=2, ls=:dash, color=:purple4)
vline!(p3, [t_collapse], color=:gray40, ls=:dot, label="")

comparison = plot(p1, p2, p3; layout=(3, 1), size=(900, 950), dpi=300)

mkpath(dirname(out_path))
savefig(comparison, out_path)

csv_out = replace(out_path, r"\.[^.]+$" => ".csv")
CSV.write(csv_out, df)

println("Generated diagnostic comparison plot")
println("dataset=$(dataset)")
println("collapse_time_seconds=$(round(t_collapse, digits=3))")
println("figure=$(out_path)")
println("diagnostics_csv=$(csv_out)")