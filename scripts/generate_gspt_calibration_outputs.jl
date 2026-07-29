#!/usr/bin/env julia
# scripts/generate_gspt_calibration_outputs.jl
# Generate GSPT calibration outputs for all cases in the `results/` directory.
using Dates
using Printf
using Statistics
using JSON3
using Plots
using Plots.PlotMeasures

include(joinpath(@__DIR__, "..", "src", "Diagnostics", "GSPTBenchmarkV4.jl"))
using .GSPTBenchmarkV4

const DEFAULT_CASES = ["CASES99", "FLOSS", "SHEBA", "GABLS1", "GABLS4"]
const DEFAULT_RESULTS_ROOT = "results"
const DEFAULT_REPORTS_DIAGNOSTICS = "reports/diagnostics"
const DEFAULT_REPORTS_FIGURES = "reports/figures"

function parse_args(args::Vector{String})
    cfg = Dict{String,Any}(
        "cases" => copy(DEFAULT_CASES),
        "results_root" => DEFAULT_RESULTS_ROOT,
        "reports_diagnostics" => DEFAULT_REPORTS_DIAGNOSTICS,
        "reports_figures" => DEFAULT_REPORTS_FIGURES,
        "run_if_missing" => false,
        "q_level" => 0.10,
        "run_bootstrap_ci" => true,
        "e_floor" => 0.001,
    )

    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--cases" && i < length(args)
            cfg["cases"] = split(args[i + 1], ',')
            i += 2
        elseif a == "--results-root" && i < length(args)
            cfg["results_root"] = args[i + 1]
            i += 2
        elseif a == "--reports-diagnostics" && i < length(args)
            cfg["reports_diagnostics"] = args[i + 1]
            i += 2
        elseif a == "--reports-figures" && i < length(args)
            cfg["reports_figures"] = args[i + 1]
            i += 2
        elseif a == "--run-if-missing" && i < length(args)
            v = lowercase(strip(args[i + 1]))
            cfg["run_if_missing"] = v in ("1", "true", "yes", "on")
            i += 2
        elseif a == "--q-level" && i < length(args)
            cfg["q_level"] = parse(Float64, args[i + 1])
            i += 2
        elseif a == "--run-bootstrap-ci" && i < length(args)
            v = lowercase(strip(args[i + 1]))
            cfg["run_bootstrap_ci"] = v in ("1", "true", "yes", "on")
            i += 2
        elseif a == "--e-floor" && i < length(args)
            cfg["e_floor"] = parse(Float64, args[i + 1])
            i += 2
        else
            error("Unknown or incomplete argument: $(a)")
        end
    end

    return cfg
end

function fmt_num(x)
    if !(x isa Real) || !isfinite(Float64(x))
        return "NA"
    end
    return @sprintf("%.4f", Float64(x))
end

function fmt_ci(low, high)
    if !(low isa Real) || !(high isa Real) || !isfinite(Float64(low)) || !isfinite(Float64(high))
        return "NA"
    end
    return "$(fmt_num(low)) to $(fmt_num(high))"
end

function to_metrics_dict(metrics)
    to_json_num(x) = (x isa Real && isfinite(Float64(x))) ? Float64(x) : nothing
    return Dict(
        "Ri_fold_hat" => to_json_num(metrics.Ri_fold_hat),
        "Ri_fold_ci_low" => to_json_num(metrics.Ri_fold_ci_low),
        "Ri_fold_ci_high" => to_json_num(metrics.Ri_fold_ci_high),
        "Ri_critical_proxy" => to_json_num(metrics.Ri_critical_proxy),
        "Delta_Ri_H_hat" => to_json_num(metrics.Delta_Ri_H_hat),
        "gamma_hat" => to_json_num(metrics.gamma_hat),
        "c_hat" => to_json_num(metrics.c_hat),
    )
end

function kernel_envelope_for_plot(data; q_level::Float64=0.10)
    Ri = data.Ri
    e = data.e
    if length(Ri) < 10
        return nothing
    end

    ri_bins = range(minimum(Ri), quantile(Ri, 0.90), length=12)
    ri_c = Float64[]
    e_q = Float64[]
    for i in 1:(length(ri_bins)-1)
        m = (Ri .>= ri_bins[i]) .& (Ri .< ri_bins[i+1])
        if count(m) >= 3
            push!(ri_c, 0.5 * (ri_bins[i] + ri_bins[i+1]))
            push!(e_q, quantile(e[m], q_level))
        end
    end

    if length(ri_c) < 4
        return nothing
    end

    ri_grid = collect(range(minimum(Ri), maximum(Ri), length=250))
    f0_grid, _ = GSPTBenchmarkV4.kernel_smooth_envelope(ri_c, e_q, ri_grid; bandwidth=0.03)
    return (ri_grid=ri_grid, f0_grid=f0_grid)
end

function fit_curve_for_plot(ri_grid, calib; e_floor::Float64=0.001)
    if calib === nothing
        return nothing
    end
    if !isfinite(calib.Ri_fold_hat) || !isfinite(calib.c_hat) || !isfinite(calib.gamma_hat)
        return nothing
    end
    p = [calib.Ri_fold_hat, calib.c_hat, calib.gamma_hat]
    fit_grid = GSPTBenchmarkV4.saddle_node_smooth(ri_grid, p; e_floor=e_floor)
    return (fit_grid=fit_grid, ri_fold_hat=calib.Ri_fold_hat)
end

function save_case_plot(result, out_path; q_level::Float64=0.10, e_floor::Float64=0.001)
    mkpath(dirname(out_path))

    if result.data === nothing
        p = plot(title="$(result.case_input): no data", legend=false, axis=false, grid=false)
        annotate!(p, 0.5, 0.5, text("status=$(result.report_status)", 10))
        savefig(p, out_path)
        return
    end

    data = result.data
    Ri = data.Ri
    e = data.e

    calib = result.calibration
    branch = calib === nothing ? fill(:unknown, length(Ri)) : calib.branch_labels
    ext_mask = branch .== :extinction
    ign_mask = branch .== :ignition

    p1 = plot(
        xlabel="Ri",
        ylabel="e",
        title="$(result.case_input): Branch-classified trajectory",
        legend=:topright,
        grid=true,
        frame=:box,
    )
    if any(ext_mask)
        scatter!(p1, Ri[ext_mask], e[ext_mask], ms=2.5, alpha=0.8, color=:crimson, label="extinction")
    end
    if any(ign_mask)
        scatter!(p1, Ri[ign_mask], e[ign_mask], ms=2.5, alpha=0.8, color=:royalblue, label="ignition")
    end
    if !any(ext_mask) && !any(ign_mask)
        scatter!(p1, Ri, e, ms=2.0, alpha=0.7, color=:gray40, label="data")
    end

    p2 = plot(
        xlabel="Ri",
        ylabel="e",
        title="$(result.case_input): Envelope and fit",
        legend=:topright,
        grid=true,
        frame=:box,
    )
    scatter!(p2, Ri, e, ms=2.0, alpha=0.25, color=:gray40, label="trajectory")

    env = kernel_envelope_for_plot(data; q_level=q_level)
    if env !== nothing
        plot!(p2, env.ri_grid, env.f0_grid, color=:darkorange, lw=2.2, label="kernel envelope F^(0)")

        fit = fit_curve_for_plot(env.ri_grid, calib; e_floor=e_floor)
        if fit !== nothing
            plot!(p2, env.ri_grid, fit.fit_grid, color=:seagreen4, lw=2.0, linestyle=:dash, label="saddle-node fit")
            vline!(p2, [fit.ri_fold_hat], color=:black, lw=1.6, linestyle=:dot, label="Ri_fold_hat")
        end
    end

    final_plot = plot(p1, p2, layout=(1, 2), size=(1200, 450), margin=5mm)
    savefig(final_plot, out_path)
end

function write_case_json(result, out_path)
    mkpath(dirname(out_path))
    payload = Dict(
        "schema_version" => BENCHMARK_RESULT_SCHEMA_VERSION,
        "case_input" => result.case_input,
        "case_family" => result.case_family,
        "case_dir" => result.case_dir,
        "source" => String(result.source),
        "report_status" => String(result.report_status),
        "status" => String(result.status),
        "timestamp" => Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SSZ"),
        "metric_fields" => [String(f) for f in result.metric_fields],
        "metrics" => to_metrics_dict(result.metrics),
        "message" => result.message,
    )

    open(out_path, "w") do io
        JSON3.pretty(io, payload)
    end
end

function write_aggregate_markdown(results, out_path)
    mkpath(dirname(out_path))
    io = IOBuffer()
    generated_utc = string(Dates.format(now(UTC), dateformat"yyyy-mm-dd HH:MM:SS"), " UTC")

    println(io, "# GSPT Calibration Summary")
    println(io)
    println(io, "Generated: ", generated_utc)
    println(io)
    println(io, "| Case | Status | \$\\hat{Ri}_{\\text{fold}}\$ (95% CI) | \$\\hat{Ri}_{\\text{critical}}\$ | \$\\Delta Ri_H\$ | \$\\hat{\\gamma}\$ | \$\\hat{c}\$ |")
    println(io, "|---|---|---|---|---|---|---|")

    for r in results
        m = r.metrics
        fold_ci = fmt_ci(m.Ri_fold_ci_low, m.Ri_fold_ci_high)
        fold_cell = isfinite(m.Ri_fold_hat) ? "$(fmt_num(m.Ri_fold_hat)) ($(fold_ci))" : "NA"
        println(
            io,
            "| ", r.case_input,
            " | ", String(r.report_status),
            " | ", fold_cell,
            " | ", fmt_num(m.Ri_critical_proxy),
            " | ", fmt_num(m.Delta_Ri_H_hat),
            " | ", fmt_num(m.gamma_hat),
            " | ", fmt_num(m.c_hat),
            " |",
        )
    end

    open(out_path, "w") do f
        write(f, String(take!(io)))
    end
end

function main()
    cfg = parse_args(ARGS)
    cases = Vector{String}(cfg["cases"])

    results = calibrate_cases(
        cases;
        results_root=cfg["results_root"],
        run_if_missing=cfg["run_if_missing"],
        q_level=cfg["q_level"],
        run_bootstrap_ci=cfg["run_bootstrap_ci"],
        e_floor=cfg["e_floor"],
    )

    for r in results
        json_path = joinpath(cfg["results_root"], r.case_input, "calibration_summary.json")
        write_case_json(r, json_path)

        plot_path = joinpath(cfg["reports_figures"], "qa_gspt_fit_$(r.case_input).png")
        save_case_plot(r, plot_path; q_level=cfg["q_level"], e_floor=cfg["e_floor"])

        @printf("[phase4] %s -> status=%s, json=%s, plot=%s\n", r.case_input, String(r.report_status), json_path, plot_path)
    end

    md_path = joinpath(cfg["reports_diagnostics"], "gspt_calibration_summary.md")
    write_aggregate_markdown(results, md_path)
    @printf("[phase4] aggregate markdown -> %s\n", md_path)
end

main()
