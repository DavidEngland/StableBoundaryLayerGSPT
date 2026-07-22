#!/usr/bin/env julia

using CSV
using Dates
using JSON3
using StableBoundaryLayerGSPT
using YAML

function parse_args(args::Vector{String})
    dataset = "CASES99"
    nsamples = 300
    ngrid = 60
    seed = 42

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--dataset" && i < length(args)
            dataset = args[i + 1]
            i += 2
        elseif arg == "--nsamples" && i < length(args)
            nsamples = parse(Int, args[i + 1])
            i += 2
        elseif arg == "--ngrid" && i < length(args)
            ngrid = parse(Int, args[i + 1])
            i += 2
        elseif arg == "--seed" && i < length(args)
            seed = parse(Int, args[i + 1])
            i += 2
        else
            error("Unknown or incomplete argument: $(arg)")
        end
    end
    return dataset, nsamples, ngrid, seed
end

function load_base_parameters(dataset::String)
    params = StableBoundaryLayerGSPT.DataAdapters.ingest_dataset(dataset)

    # Prefer dataset-level four_d_solver parameters when available.
    dataset_yaml_path = joinpath("spec", "datasets", "$(dataset).yaml")
    if isfile(dataset_yaml_path)
        dataset_raw = YAML.load_file(dataset_yaml_path)
        four_d = get(dataset_raw, "four_d_solver", Dict{Any,Any}())
        four_d_params = get(four_d, "parameters", Dict{Any,Any}())
        for (k, v) in four_d_params
            params[string(k)] = v
        end
    end

    # Merge the latest campaign summary parameters when present.
    summary_path = joinpath("results", dataset, "latest", "summary.json")
    if isfile(summary_path)
        summary = JSON3.read(read(summary_path, String))
        if haskey(summary, :parameters)
            for (k, v) in pairs(summary.parameters)
                params[string(k)] = v
            end
        end
    end

    defaults_path = "spec/parameters/defaults.yaml"
    if isfile(defaults_path)
        defaults_raw = YAML.load_file(defaults_path)
        defaults = get(defaults_raw, "parameters", Dict{Any,Any}())
        for (k, v) in defaults
            params[string(k)] = v
        end
    end

    # Synthetic sweep controls for bifurcation geometry.
    # These are campaign-specific baselines inferred from current run parameters.
    Ug = Float64(get(params, "U_g", 8.0))
    Ta = Float64(get(params, "T_a", 280.0))
    Tdeep = Float64(get(params, "T_deep", Ta - 1.0))
    Rdown = Float64(get(params, "R_down", 250.0))
    shear_eff = Float64(get(params, "shear_production_efficiency", 1.0))
    K_phys = Float64(get(params, "K", 0.32))
    alpha_air = Float64(get(params, "alpha_air", 0.15))

    ug_proxy = (Ug / 8.0)^2 * shear_eff
    polar_boost = 1.0 + max(275.0 - Ta, 0.0) / 8.0
    cooling_contrast = max(Ta - Tdeep, 0.0)
    radiative_deficit = max(280.0 - Rdown, 0.0)

    sigma_syn = ug_proxy * polar_boost
    K_syn = K_phys * (1.0 + 0.25 * cooling_contrast + 0.30 * (radiative_deficit / 40.0))
    alpha_syn = alpha_air * (1.0 + 0.20 * (radiative_deficit / 40.0))

    params["sigma"] = get(params, "sigma_sensitivity_baseline", sigma_syn)
    params["K"] = get(params, "K_sensitivity_baseline", K_syn)
    params["alpha"] = get(params, "alpha_sensitivity_baseline", alpha_syn)
    params["a_fold"] = get(params, "a_fold", 0.6)
    params["b_fold"] = get(params, "b_fold", 0.35)
    params["T0"] = get(params, "T0", 280.0)
    params["S0"] = get(params, "S0", 0.8)

    return params
end

function write_report_fragment(dataset::String, run_dir::String, summary::AbstractDict{String,<:Any}, figures::AbstractDict{String,<:Any})
    mkpath("reports/generated/diagnostics")
    out_path = "reports/generated/diagnostics/03_bifurcation_sweep.md"
    nsamples = summary["nsamples"]
    ngrid = summary["ngrid"]
    trans_frac = summary["transcritical_near_fraction"]
    fold_frac = summary["fold_near_fraction"]
    text = "# Bifurcation Sweep\n\n" *
           "Dataset: $(dataset)\n\n" *
           "Run directory: $(run_dir)\n\n" *
           "## Summary\n\n" *
           "- nsamples: $(nsamples)\n" *
           "- ngrid: $(ngrid)\n" *
           "- transcritical near fraction: $(trans_frac)\n" *
           "- fold near fraction: $(fold_frac)\n\n" *
           "## Artifacts\n\n" *
           "- transcritical_map.csv\n" *
           "- fold_map.csv\n" *
           "- transcritical_envelope.csv\n" *
           "- fold_envelope.csv\n" *
           "- parameter_sensitivity_envelope.csv\n" *
            "- bifurcation_summary.json\n\n" *
            "## Figure Bundles\n\n" *
            "- figure_bifurcation_transcritical_map (pdf/tex/md/json)\n" *
            "- figure_bifurcation_fold_map (pdf/tex/md/json)\n" *
            "- figure_bifurcation_transcritical_envelope (pdf/tex/md/json)\n" *
            "- figure_bifurcation_fold_envelope (pdf/tex/md/json)\n" *
            "- figure_bifurcation_transcritical_distance_map (pdf/tex/md/json)\n" *
            "- figure_bifurcation_parameter_sensitivity_envelope (pdf/tex/md/json)\n"
    write(out_path, text)
    return out_path
end

dataset, nsamples, ngrid, seed = parse_args(ARGS)
dataset_upper = uppercase(strip(dataset))
params = load_base_parameters(dataset_upper)

timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
run_dir = joinpath("results", dataset_upper, "bifurcation_$(timestamp)")
mkpath(run_dir)

analysis = StableBoundaryLayerGSPT.Diagnostics.synthetic_bifurcation_analysis(
    parameters=params,
    nsamples=nsamples,
    ngrid=ngrid,
    seed=seed,
)

transcritical_map_path = joinpath(run_dir, "transcritical_map.csv")
fold_map_path = joinpath(run_dir, "fold_map.csv")
transcritical_env_path = joinpath(run_dir, "transcritical_envelope.csv")
fold_env_path = joinpath(run_dir, "fold_envelope.csv")
parameter_sensitivity_env_path = joinpath(run_dir, "parameter_sensitivity_envelope.csv")
summary_path = joinpath(run_dir, "bifurcation_summary.json")

CSV.write(transcritical_map_path, analysis.transcritical_map)
CSV.write(fold_map_path, analysis.fold_map)
CSV.write(transcritical_env_path, analysis.transcritical_envelope)
CSV.write(fold_env_path, analysis.fold_envelope)
CSV.write(parameter_sensitivity_env_path, analysis.parameter_sensitivity_envelope)

git_commit = get(ENV, "GIT_COMMIT", "unknown")
provenance = StableBoundaryLayerGSPT.Provenance.build_provenance_record(
    script="scripts/sweep_bifurcation.jl",
    dataset=dataset_upper,
    git_commit=git_commit,
    julia_version=string(VERSION),
    parameters=params,
)

summary_payload = Dict(
    "schema_version" => "0.1.0",
    "dataset" => dataset_upper,
    "run_dir" => run_dir,
    "summary" => analysis.summary,
    "artifacts" => Dict(
        "transcritical_map" => transcritical_map_path,
        "fold_map" => fold_map_path,
        "transcritical_envelope" => transcritical_env_path,
        "fold_envelope" => fold_env_path,
        "parameter_sensitivity_envelope" => parameter_sensitivity_env_path,
    ),
    "provenance" => provenance,
)

figure_bundles = StableBoundaryLayerGSPT.Visualization.generate_bifurcation_figure_bundles(
    dataset_upper,
    run_dir,
    provenance,
)
summary_payload["figures"] = figure_bundles

StableBoundaryLayerGSPT.Provenance.write_json(summary_path, summary_payload)
report_path = write_report_fragment(dataset_upper, run_dir, analysis.summary, figure_bundles)

println("Bifurcation sweep complete")
println("run_dir=$(run_dir)")
println("summary=$(summary_path)")
println("report_fragment=$(report_path)")