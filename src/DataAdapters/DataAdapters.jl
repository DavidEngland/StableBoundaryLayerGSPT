module DataAdapters

export ingest_dataset

"""Ingest dataset metadata and return default simulation parameters."""
function ingest_dataset(dataset::String)
    dataset_upper = uppercase(strip(dataset))
    if dataset_upper == "CASES99"
        return Dict("dataset" => "CASES99", "nsteps" => 20, "dt" => 60.0, "tke0" => 0.25, "ri0" => 0.07)
    elseif dataset_upper == "FLOSS"
        return Dict("dataset" => "FLOSS", "nsteps" => 24, "dt" => 60.0, "tke0" => 0.18, "ri0" => 0.06)
    end
    error("Unsupported dataset: $(dataset). Supported: CASES99, FLOSS")
end

end