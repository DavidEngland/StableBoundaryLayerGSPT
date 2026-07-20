#!/usr/bin/env julia

using CSV
using DataFrames
using Dates
using JSON3
using Plots
using Statistics

include("../scm/two_layer_gspt_model.jl")
using .TwoLayerGSPTModel

function parse_args(args::Vector{String})
    cfg = Dict{String,Any}(
        "ug_min" => 2.0,
        "ug_max" => 15.0,
        "ug_step" => 1.0,
        "spinup_hours" => 2.0,
        "force_fractional_init" => true,
        "duration_hours" => 6.0,
        "dt_seconds" => 300.0,
        "outdir" => "results/two_layer_gspt",
    )

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--ug-min" && i < length(args)
            cfg["ug_min"] = parse(Float64, args[i + 1])
            i += 2
        elseif arg == "--ug-max" && i < length(args)
            cfg["ug_max"] = parse(Float64, args[i + 1])
            i += 2
        elseif arg == "--ug-step" && i < length(args)
            cfg["ug_step"] = parse(Float64, args[i + 1])
            i += 2
        elseif arg == "--spinup-hours" && i < length(args)
            cfg["spinup_hours"] = parse(Float64, args[i + 1])
            i += 2
        elseif arg == "--force-fractional-init"
            cfg["force_fractional_init"] = true
            i += 1
        elseif arg == "--no-force-fractional-init"
            cfg["force_fractional_init"] = false
            i += 1
        elseif arg == "--duration-hours" && i < length(args)
            cfg["duration_hours"] = parse(Float64, args[i + 1])
            i += 2
        elseif arg == "--dt-seconds" && i < length(args)
            cfg["dt_seconds"] = parse(Float64, args[i + 1])
            i += 2
        elseif arg == "--outdir" && i < length(args)
            cfg["outdir"] = args[i + 1]
            i += 2
        elseif arg == "--help"
            println("Usage: julia scripts/sweep_two_layer_envelope.jl [--ug-min X] [--ug-max X] [--ug-step X] [--spinup-hours H] [--force-fractional-init|--no-force-fractional-init] [--duration-hours H] [--dt-seconds S] [--outdir PATH]")
            exit(0)
        else
            error("Unknown or incomplete argument: $(arg)")
        end
    end

    return cfg
end

function scan_one(Ug::Float64, spinup_hours::Float64, duration_hours::Float64, dt_seconds::Float64; force_fractional_init::Bool=true)
    parameters = default_parameters(; Ug=Ug)
    initial_state = default_initial_state()
    run = simulate_column_with_spinup(
        parameters,
        initial_state,
        spinup_hours,
        duration_hours;
        saveat=dt_seconds,
        force_fractional_init=force_fractional_init,
    )

    spinup_sol = run.spinup
    sol = run.main
    geom = trajectory_geometry_summary(sol, parameters)

    e1_history = [max(u.e1, 0.0) for u in sol.u]
    Ts_history = [u.Ts for u in sol.u]
    collapsed_idx = findfirst(<(0.02), e1_history)

    return Dict(
        "U_g" => Ug,
        "spinup_hours" => spinup_hours,
        "force_fractional_init" => force_fractional_init,
        "spinup_final_e" => max(spinup_sol.u[end].e1, 0.0),
        "spinup_final_Ts" => spinup_sol.u[end].Ts,
        "final_e" => e1_history[end],
        "final_e_eq" => geom.e_eq_history[end],
        "min_e_eq" => minimum(geom.e_eq_history),
        "min_fold_diagnostic" => minimum(geom.fold_history),
        "min_Ts" => minimum(Ts_history),
        "collapse_time_s" => collapsed_idx === nothing ? missing : (spinup_hours * 3600.0 + sol.t[collapsed_idx]),
        "collapsed" => collapsed_idx !== nothing,
        "solver_retcode" => string(sol.retcode),
        "residual_rms" => sqrt(mean(abs2, geom.residual_history)),
        "max_abs_residual" => maximum(abs, geom.residual_history),
        "final_thermal_inversion" => geom.thermal_inversion_history[end],
    )
end

function write_report_fragment(outdir::String, summary_df::DataFrame, figure_path::String, csv_path::String)
    mkpath("reports/generated/diagnostics")
    out_path = joinpath("reports/generated/diagnostics", "04_two_layer_ug_scan.md")
    collapsed_fraction = mean(Bool.(summary_df.collapsed))
    min_fold_idx = argmin(summary_df.min_fold_diagnostic)
    text = "# Two-Layer Ug Sweep\n\n" *
           "Dataset: SCM / GSPT envelope scan\n\n" *
           "Run directory: $(outdir)\n\n" *
           "## Summary\n\n" *
           "- ug_min: $(minimum(summary_df.U_g))\n" *
           "- ug_max: $(maximum(summary_df.U_g))\n" *
           "- ug_step: $(summary_df.U_g[2] - summary_df.U_g[1])\n" *
            "- spinup_hours: $(summary_df.spinup_hours[1])\n" *
            "- force_fractional_init: $(summary_df.force_fractional_init[1])\n" *
           "- collapsed fraction: $(collapsed_fraction)\n" *
           "- Ug at minimum fold diagnostic: $(summary_df.U_g[min_fold_idx])\n\n" *
           "## Artifacts\n\n" *
           "- $(basename(csv_path))\n" *
           "- $(basename(figure_path))\n\n" *
           "## Figure\n\n" *
           "![Two-layer Ug envelope](../figures/$(basename(figure_path)))\n\n" *
           "## Notes\n\n" *
           "This is the first-pass envelope scan. It is intended to lock down branch tracking, fold proximity, and collapse thresholds before polishing final manuscript styling.\n"
    write(out_path, text)
    return out_path
end

function write_figure_sidecar(dataset::String, figure_path::String, csv_path::String)
    mkpath("reports/generated/figures")
    md_path = replace(figure_path, ".png" => ".md")
    sidecar = "# two_layer_ug_envelope\n\nDataset: $(dataset)\n\nCaption: Geostrophic-wind sweep showing equilibrium TKE tracking and fold-diagnostic collapse proximity.\n\nDescription: Two-panel envelope scan generated from the two-layer SCM prototype. The left panel shows the equilibrium branch versus geostrophic forcing, while the right panel shows the minimum fold diagnostic along each trajectory.\n\nSource CSV: $(csv_path)\n"
    write(md_path, sidecar)
    cp(md_path, joinpath("reports/generated/figures", basename(md_path)); force=true)
    return md_path
end

cfg = parse_args(ARGS)
ug_values = collect(cfg["ug_min"]:cfg["ug_step"]:cfg["ug_max"])
timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
run_dir = joinpath(cfg["outdir"], "ug_scan_$(timestamp)")
mkpath(run_dir)

rows = NamedTuple[]
for Ug in ug_values
    result = scan_one(Ug, cfg["spinup_hours"], cfg["duration_hours"], cfg["dt_seconds"]; force_fractional_init=cfg["force_fractional_init"])
    push!(rows, (
        U_g=result["U_g"],
        spinup_hours=result["spinup_hours"],
        force_fractional_init=result["force_fractional_init"],
        spinup_final_e=result["spinup_final_e"],
        spinup_final_Ts=result["spinup_final_Ts"],
        final_e=result["final_e"],
        final_e_eq=result["final_e_eq"],
        min_e_eq=result["min_e_eq"],
        min_fold_diagnostic=result["min_fold_diagnostic"],
        min_Ts=result["min_Ts"],
        collapse_time_s=result["collapse_time_s"],
        collapsed=result["collapsed"],
        solver_retcode=result["solver_retcode"],
        residual_rms=result["residual_rms"],
        max_abs_residual=result["max_abs_residual"],
        final_thermal_inversion=result["final_thermal_inversion"],
    ))
end

summary_df = DataFrame(rows)
csv_path = joinpath(run_dir, "ug_scan_summary.csv")
json_path = joinpath(run_dir, "ug_scan_summary.json")
CSV.write(csv_path, summary_df)

summary_payload = Dict(
    "schema_version" => "0.1.0",
    "dataset" => "TWO_LAYER_UG_SCAN",
    "run_dir" => run_dir,
    "summary" => Dict(
        "ug_min" => minimum(summary_df.U_g),
        "ug_max" => maximum(summary_df.U_g),
        "collapsed_fraction" => mean(Bool.(summary_df.collapsed)),
        "min_fold_diagnostic" => minimum(summary_df.min_fold_diagnostic),
        "min_fold_ug" => summary_df.U_g[argmin(summary_df.min_fold_diagnostic)],
        "mean_residual_rms" => mean(summary_df.residual_rms),
    ),
    "artifacts" => Dict("summary_csv" => csv_path),
)
open(json_path, "w") do io
    JSON3.pretty(io, summary_payload)
end

collapsed_mask = Bool.(summary_df.collapsed)
stable_mask = .!collapsed_mask

figure_path = joinpath(run_dir, "two_layer_ug_envelope.png")
 p1 = plot(
    summary_df.U_g,
    summary_df.final_e_eq;
    linewidth=2,
    marker=:circle,
    markersize=5,
    label="e_eq(end)",
    xlabel="Geostrophic wind U_g (m/s)",
    ylabel="Equilibrium TKE",
    title="Equilibrium Branch Envelope",
    grid=true,
)
plot!(p1, summary_df.U_g, summary_df.final_e; linewidth=2, marker=:diamond, markersize=5, label="e_1(end)")
if any(collapsed_mask)
    scatter!(p1, summary_df.U_g[collapsed_mask], summary_df.final_e_eq[collapsed_mask]; marker=:xcross, markersize=7, label="collapsed")
end

p2 = plot(
    summary_df.U_g,
    summary_df.min_fold_diagnostic;
    linewidth=2,
    marker=:square,
    markersize=5,
    color=:black,
    label="min ∂g/∂e₁",
    xlabel="Geostrophic wind U_g (m/s)",
    ylabel="Fold diagnostic",
    title="Fold Proximity Across Sweep",
    grid=true,
)
hline!(p2, [0.0]; linestyle=:dash, color=:red, label="fold threshold")
if any(stable_mask)
    scatter!(p2, summary_df.U_g[stable_mask], summary_df.min_fold_diagnostic[stable_mask]; marker=:circle, markersize=4, label="attracting")
end

plt = plot(p1, p2; layout=(1, 2), size=(1200, 450))
savefig(plt, figure_path)
cp(figure_path, joinpath("reports/generated/figures", basename(figure_path)); force=true)
write_figure_sidecar("TWO_LAYER_UG_SCAN", figure_path, csv_path)
report_path = write_report_fragment(run_dir, summary_df, figure_path, csv_path)

println("Ug sweep complete")
println("run_dir=$(run_dir)")
println("summary=$(json_path)")
println("report_fragment=$(report_path)")