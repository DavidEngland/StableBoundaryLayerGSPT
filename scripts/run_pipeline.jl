#!/usr/bin/env julia

using StableBoundaryLayerGSPT

function parse_args(args::Vector{String})
    dataset = "CASES99"
    config_path = nothing

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--dataset" && i < length(args)
            dataset = args[i + 1]
            i += 2
        elseif arg == "--config" && i < length(args)
            config_path = args[i + 1]
            i += 2
        else
            error("Unknown or incomplete argument: $(arg)")
        end
    end
    return dataset, config_path
end

dataset, config_path = parse_args(ARGS)
result = run_pipeline(dataset=dataset, config_path=config_path)
run_dir = result["run_dir"]
manifest = result["manifest"]
checksum = result["checksum"]

println("Pipeline complete")
println("run_dir=$(run_dir)")
println("manifest=$(manifest)")
println("checksum=$(checksum)")