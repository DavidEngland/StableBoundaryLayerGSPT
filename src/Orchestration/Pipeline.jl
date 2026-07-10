module Orchestration

using Dates
using SHA
using YAML

using ..DataAdapters
using ..Dynamics
using ..Diagnostics
using ..Validation
using ..Reports
using ..Visualization
using ..Provenance

export run_pipeline

"""Run scaffolded stage pipeline with explicit validation gate and manifest emission."""
function run_pipeline(; dataset::String, config_path::Union{Nothing,String}=nothing)
    dataset_upper = uppercase(strip(dataset))

    params = DataAdapters.ingest_dataset(dataset_upper)
    if config_path !== nothing && isfile(config_path)
        overrides = YAML.load_file(config_path)
        for (k, v) in overrides
            params[string(k)] = v
        end
    end

    timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
    run_dir = joinpath("results", dataset_upper, "run_$(timestamp)")
    mkpath(run_dir)

    states = Dynamics.integrate_system(params)
    diagnostics = Diagnostics.compute_diagnostics(states)

    passed, reason = Validation.run_validation_gate(diagnostics)
    passed || error("Validation gate failed: $(reason)")

    git_commit = get(ENV, "GIT_COMMIT", "unknown")
    prov = Provenance.build_provenance_record(
        script="scripts/run_pipeline.jl",
        dataset=dataset_upper,
        git_commit=git_commit,
        julia_version=string(VERSION),
        parameters=params,
    )

    figure_paths = Visualization.generate_figure_bundle(dataset_upper, diagnostics, prov)
    report_paths = Reports.generate_report_fragments(dataset_upper, diagnostics)

    manifest = Dict(
        "schema_version" => "0.1.0",
        "dataset" => dataset_upper,
        "timestamp" => timestamp,
        "validation" => Dict("passed" => passed, "reason" => reason),
        "diagnostics" => diagnostics,
        "figures" => figure_paths,
        "reports" => report_paths,
        "provenance" => prov,
    )

    manifest_path = joinpath(run_dir, "run_manifest.json")
    Provenance.write_json(manifest_path, manifest)

    checksum = bytes2hex(sha256(read(manifest_path)))
    checksum_path = joinpath(run_dir, "run_manifest.sha256")
    write(checksum_path, string(checksum, "  run_manifest.json\n"))

    return Dict("run_dir" => run_dir, "manifest" => manifest_path, "checksum" => checksum_path)
end

end