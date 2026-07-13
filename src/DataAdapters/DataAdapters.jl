module DataAdapters

export ingest_dataset

function _default_data_root()
    env_root = get(ENV, "SPECTRALBL_ANALYTICS_DATA_ROOT", "")
    if !isempty(strip(env_root))
        return normpath(env_root)
    end
    return normpath(joinpath("..", "SpectralBL-Analytics", "data"))
end

function _dataset_paths(dataset::String; data_root::String=_default_data_root())
    dataset_dir = joinpath(data_root, dataset)
    return Dict(
        "data_root" => data_root,
        "dataset_dir" => dataset_dir,
        "dataset_file" => joinpath(dataset_dir, string(lowercase(dataset), ".csv")),
    )
end

"""Ingest dataset metadata and return default simulation parameters."""
function ingest_dataset(dataset::String; data_root::AbstractString=_default_data_root())
    dataset_upper = uppercase(strip(dataset))
    if dataset_upper == "CASES99"
        params = Dict("dataset" => "CASES99", "nsteps" => 20, "dt" => 60.0, "tke0" => 0.25, "ri0" => 0.07)
        merge!(params, _dataset_paths(dataset_upper; data_root=String(data_root)))
        return params
    elseif dataset_upper == "FLOSS"
        params = Dict("dataset" => "FLOSS", "nsteps" => 24, "dt" => 60.0, "tke0" => 0.18, "ri0" => 0.06)
        merge!(params, _dataset_paths(dataset_upper; data_root=String(data_root)))
        return params
    elseif dataset_upper == "SHEBA"
        params = Dict("dataset" => "SHEBA", "nsteps" => 24, "dt" => 60.0, "tke0" => 0.16, "ri0" => 0.08)
        merge!(params, _dataset_paths(dataset_upper; data_root=String(data_root)))
        return params
    end
    error("Unsupported dataset: $(dataset). Supported: CASES99, FLOSS, SHEBA")
end

end