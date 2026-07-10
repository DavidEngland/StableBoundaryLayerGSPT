module Provenance

using Dates
using JSON3

export build_provenance_record, write_json

"""Build provenance metadata dictionary for generated artifacts."""
function build_provenance_record(; script::String, dataset::String, git_commit::String, julia_version::String, parameters::AbstractDict{String,<:Any})
    return Dict(
        "script" => script,
        "dataset" => dataset,
        "git_commit" => git_commit,
        "julia" => julia_version,
        "generated" => string(Dates.now()),
        "parameters" => parameters,
    )
end

function write_json(path::String, payload::AbstractDict{String,<:Any})
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, payload)
    end
    return path
end

end
