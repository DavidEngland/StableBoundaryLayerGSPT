#!/usr/bin/env julia

using CSV
using DataFrames
using JSON3
using StableBoundaryLayerGSPT.Dynamics

function regime_metrics(df::DataFrame)
    e = df.e
    Ts = df.Ts
    t = df.t

    low_thr = 0.02
    high_thr = 0.20

    collapsed_idx = findfirst(<(low_thr), e)
    reignitions = 0
    if collapsed_idx !== nothing
        for i in (collapsed_idx + 1):length(e)
            if e[i - 1] < high_thr && e[i] >= high_thr
                reignitions += 1
            end
        end
    end

    min_Ts = minimum(Ts)
    final_e = e[end]
    collapse_time = collapsed_idx === nothing ? missing : t[collapsed_idx]

    return Dict(
        "collapsed" => collapsed_idx !== nothing,
        "reignitions" => reignitions,
        "min_Ts" => min_Ts,
        "final_e" => final_e,
        "collapse_time_s" => collapse_time,
    )
end

function run_one(Ug::Float64)
    params = default_4d_parameters()
    params["U_g"] = Ug

    sol = solve_4d_sbl(
        parameters=params,
        u0=[1.0, 5.0, 0.0, 285.15],
        tspan=(0.0, 14.0 * 3600.0),
        solver=:rodas5p,
        saveat=30.0,
    )

    rows = solution_to_rows(sol, params)
    df = DataFrame(rows)
    metrics = regime_metrics(df)

    return Dict(
        "U_g" => Ug,
        "accepted_steps" => sol.destats.naccept,
        "rejected_steps" => sol.destats.nreject,
        "nf" => sol.destats.nf,
        "solver_retcode" => string(sol.retcode),
        "unphysical_cooling" => metrics["min_Ts"] < 250.0,
        "metrics" => metrics,
    ), df
end

mkpath("results/4d_sbl")
out_rows = NamedTuple[]
issues = Dict{String,Any}[]

for Ug in 2.0:1.0:15.0
    result, df = run_one(Ug)

    metrics = result["metrics"]
    low_regime_expected = Ug < 4.0
    high_regime_expected = Ug > 10.0

    low_regime_ok = !low_regime_expected || (metrics["collapsed"] && metrics["reignitions"] == 0)
    high_regime_ok = !high_regime_expected || (metrics["collapsed"] && metrics["reignitions"] >= 1)

    push!(out_rows, (
        U_g=Ug,
        collapsed=metrics["collapsed"],
        reignitions=metrics["reignitions"],
        min_Ts=metrics["min_Ts"],
        final_e=metrics["final_e"],
        accepted_steps=result["accepted_steps"],
        rejected_steps=result["rejected_steps"],
        retcode=result["solver_retcode"],
        unphysical_cooling=result["unphysical_cooling"],
        low_regime_ok=low_regime_ok,
        high_regime_ok=high_regime_ok,
    ))

    if !low_regime_ok || !high_regime_ok || result["unphysical_cooling"] || result["solver_retcode"] != "Success"
        push!(issues, result)
    end
end

summary_df = DataFrame(out_rows)
csv_path = "results/4d_sbl/sweep_regression_summary.csv"
CSV.write(csv_path, summary_df)

report = Dict(
    "description" => "4D GSPT-SBL geostrophic forcing sweep",
    "U_g_range" => [2.0, 15.0],
    "step" => 1.0,
    "low_forcing_rule" => "U_g < 4.0 should remain laminar after collapse (no re-ignition)",
    "high_forcing_rule" => "U_g > 10.0 should show at least one re-ignition",
    "issues" => issues,
    "summary_csv" => csv_path,
)

json_path = "results/4d_sbl/sweep_regression_report.json"
open(json_path, "w") do io
    JSON3.pretty(io, report)
end

println("4D sweep regression complete")
println("summary=$(csv_path)")
println("report=$(json_path)")
println("issue_count=$(length(issues))")

if !isempty(issues)
    error("Sweep regression reported issues. Inspect $(json_path).")
end