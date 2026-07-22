module StableBoundaryLayerGSPT

include("Config/CaseDefaults.jl")
include("Geometry/Geometry.jl")
include("Dynamics/Dynamics.jl")
include("Physics/Physics.jl")
include("Diagnostics/Diagnostics.jl")
include("Validation/Validation.jl")
include("Visualization/Visualization.jl")
include("Reports/Reports.jl")
include("DataAdapters/DataAdapters.jl")
include("Provenance/Provenance.jl")
include("Orchestration/Pipeline.jl")

using .Orchestration: run_pipeline
using .CaseDefaults: get_case_ts_min

export run_pipeline
export get_case_ts_min

end