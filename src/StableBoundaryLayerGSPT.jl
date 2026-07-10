module StableBoundaryLayerGSPT

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

export run_pipeline

end