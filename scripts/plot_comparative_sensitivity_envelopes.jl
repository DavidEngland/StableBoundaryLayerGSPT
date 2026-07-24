#!/usr/bin/env julia
# scripts/plot_comparative_sensitivity_envelopes.jl
# Build a unified 3-panel comparative sensitivity envelope figure
# from latest bifurcation runs for CASES99, FLOSS, and SHEBA.

using CSV
using DataFrames
using Plots

function usage()
    println("Usage: julia scripts/plot_comparative_sensitivity_envelopes.jl [options]")
    println("Options:")
    println("  --out <path>   Output path (default: reports/generated/figures/comparative_parameter_sensitivity_envelope.png)")
    println("  --help         Show this help message")
end

function parse_args(args::Vector{String})
    out = joinpath("reports", "generated", "figures", "comparative_parameter_sensitivity_envelope.png")

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--out" && i < length(args)
            out = args[i+1]
            i += 2
        elseif arg == "--help"
            usage()
            exit(0)
        else
            error("Unknown or incomplete argument: $(arg)")
        end
    end

    return out
end

function latest_bifurcation_dir(dataset::String)
    base = joinpath("results", dataset)
    isdir(base) || return nothing
    runs = filter(p -> startswith(basename(p), "bifurcation_"), readdir(base; join=true))
    if isempty(runs)
        return nothing
    end
    sort!(runs; by=p -> stat(p).mtime, rev=true)
    return runs[1]
end

function load_env_csv(dataset::String)
    run_dir = latest_bifurcation_dir(dataset)
    isnothing(run_dir) && return nothing, nothing
    csv_path = joinpath(run_dir, "parameter_sensitivity_envelope.csv")
    isfile(csv_path) || return run_dir, nothing

    df = CSV.read(csv_path, DataFrame)
    required = ["scale", "gamma_c_min", "gamma_c_p50", "gamma_c_max"]
    present = Set(string.(names(df)))
    for col in required
        col in present || return run_dir, nothing
    end

    return run_dir, df
end

function build_panel(dataset::String, df::DataFrame; show_ylabel::Bool)
    x = Float64.(df.scale)
    y_min = Float64.(df.gamma_c_min)
    y_med = Float64.(df.gamma_c_p50)
    y_max = Float64.(df.gamma_c_max)

    # 1. Draw shaded envelope fill first (background layer)
    p = plot(
        x,
        y_max;
        fillrange=y_min,
        fillalpha=0.22,
        fillcolor=:crimson,
        linealpha=0.0,
        color=:crimson,
        label="min-max envelope",
        xlabel="Scale multiplier",
        ylabel=show_ylabel ? "Critical threshold γ_c" : "",
        title=dataset,
        grid=true,
        gridalpha=0.28,
        legend=:topright,
    )

    # 2. Draw dashed envelope boundary lines
    plot!(
        x,
        y_min;
        linewidth=1.0,
        linestyle=:dash,
        color=:crimson,
        alpha=0.65,
        label="",
    )
    plot!(
        x,
        y_max;
        linewidth=1.0,
        linestyle=:dash,
        color=:crimson,
        alpha=0.65,
        label="",
    )

    # 3. Overlay sharp median line on top
    plot!(
        x,
        y_med;
        linewidth=2.4,
        color=:black,
        label="median",
    )

    return p
end

function build_missing_panel(dataset::String; show_ylabel::Bool)
    p = plot(
        [0.0, 1.0],
        [0.0, 1.0];
        alpha=0.0,
        linealpha=0.0,
        xlabel="Scale multiplier",
        ylabel=show_ylabel ? "Critical threshold γ_c" : "",
        title=dataset,
        grid=true,
        gridalpha=0.28,
        legend=false,
        xlims=(0.0, 1.0),
        ylims=(0.0, 1.0),
    )
    annotate!(
        p,
        0.5,
        0.5,
        text(
            "No bifurcation envelope data\n(run make bifurcation-$(lowercase(dataset)))",
            :center,
            9,
            :darkred,
        ),
    )
    return p
end

function main(args::Vector{String})
    out_path = parse_args(args)

    datasets = ["CASES99", "FLOSS", "SHEBA"]
    run_dirs = Dict{String,String}()
    dfs = Dict{String,DataFrame}()
    missing = String[]

    for ds in datasets
        run_dir, df = load_env_csv(ds)
        if !isnothing(run_dir)
            run_dirs[ds] = run_dir
        end
        if isnothing(df)
            push!(missing, ds)
        else
            dfs[ds] = df
        end
    end

    p_cases = haskey(dfs, "CASES99") ? build_panel("CASES99", dfs["CASES99"]; show_ylabel=true) : build_missing_panel("CASES99"; show_ylabel=true)
    p_floss = haskey(dfs, "FLOSS") ? build_panel("FLOSS", dfs["FLOSS"]; show_ylabel=false) : build_missing_panel("FLOSS"; show_ylabel=false)
    p_sheba = haskey(dfs, "SHEBA") ? build_panel("SHEBA", dfs["SHEBA"]; show_ylabel=false) : build_missing_panel("SHEBA"; show_ylabel=false)

    fig = plot(
        p_cases,
        p_floss,
        p_sheba;
        layout=(1, 3),
        size=(1900, 560),
        margin=6Plots.mm,
        bottom_margin=10Plots.mm,
        plot_title="Comparative OAT Parameter Sensitivity Envelope",
        plot_titlefontsize=14,
    )

    mkpath(dirname(out_path))
    savefig(fig, out_path)

    println("saved: $(out_path)")
    for ds in sort(collect(keys(run_dirs)))
        println("$(ds)_run_dir=$(run_dirs[ds])")
    end
    if !isempty(missing)
        @warn "Missing bifurcation envelope inputs for $(join(missing, ", ")). Rendered placeholder panel(s) instead of failing."
    end
end

main(ARGS)