#!/usr/bin/env julia

using CSV
using Dates
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

    defaults_path = "spec/parameters/defaults.yaml"
    if isfile(defaults_path)
        defaults_raw = YAML.load_file(defaults_path)
        defaults = get(defaults_raw, "parameters", Dict{Any,Any}())
        for (k, v) in defaults
            params[string(k)] = v
        end
    end

    # Synthetic sweep controls for bifurcation geometry.
    params["sigma"] = get(params, "sigma", 1.0)
    params["K"] = get(params, "K", 0.8)
    params["alpha"] = get(params, "alpha", 0.6)
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